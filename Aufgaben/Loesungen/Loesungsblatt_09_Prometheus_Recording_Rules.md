# Lösungsblatt 9– Prometheus Recording Rules

Dieses Lösungsblatt enthält die Lösungen zu den Übungsaufgaben aus Aufgabenfeld 6a sowie weitere Beispiele.

## Übungsaufgaben - Lösungen

### Aufgabe 1: Recording Rule für durchschnittliche Disk I/O Latenz

**Ziel**: Erstellen einer Recording Rule für die durchschnittliche Disk I/O Latenz.

**Lösung**:
```yaml
groups:
  - name: disk_io_recording_rules
    interval: 30s
    rules:

    # Durchschnittliche Read-Latenz in Millisekunden
    - record: instance:node_disk_read_latency:avg_ms
      expr: |
        rate(node_disk_read_time_seconds_total[5m])
        / rate(node_disk_reads_completed_total[5m])
        * 1000

    # Durchschnittliche Write-Latenz in Millisekunden
    - record: instance:node_disk_write_latency:avg_ms
      expr: |
        rate(node_disk_write_time_seconds_total[5m])
        / rate(node_disk_writes_completed_total[5m])
        * 1000

    # Gesamte I/O-Latenz (Read + Write)
    - record: instance:node_disk_io_latency:avg_ms
      expr: |
        (
          rate(node_disk_read_time_seconds_total[5m]) +
          rate(node_disk_write_time_seconds_total[5m])
        )
        /
        (
          rate(node_disk_reads_completed_total[5m]) +
          rate(node_disk_writes_completed_total[5m])
        )
        * 1000
```

**Erklärung**:
- `rate(node_disk_read_time_seconds_total[5m])` gibt die Zeit für Read-Operationen
- Geteilt durch `rate(node_disk_reads_completed_total[5m])` = durchschnittliche Zeit pro Read
- Multipliziert mit 1000 = Umrechnung in Millisekunden
- Aggregation über alle Disks mit `sum by (instance, device)`

**Erweiterte Version mit Aggregation nach Device**:
```yaml
    # Pro Device und Instance
    - record: instance_device:node_disk_read_latency:avg_ms
      expr: |
        rate(node_disk_read_time_seconds_total[5m])
        / rate(node_disk_reads_completed_total[5m])
        * 1000

    # Aggregiert über alle Devices pro Instance
    - record: instance:node_disk_read_latency:avg_ms
      expr: |
        avg by (instance) (
          instance_device:node_disk_read_latency:avg_ms
        )
```

---

### Aufgabe 2: Cluster-wide Netzwerk-Traffic in GB/Tag

**Ziel**: Recording Rule für den gesamten Netzwerk-Traffic des Clusters in GB/Tag.

**Lösung**:
```yaml
groups:
  - name: network_traffic_recording_rules
    interval: 1m
    rules:

    # Empfangener Traffic pro Instance (GB/Tag)
    - record: instance:node_network_receive_gb_per_day:predicted
      expr: |
        sum by (instance) (
          rate(node_network_receive_bytes_total{device!~"lo|veth.*|docker.*"}[5m])
        ) * 86400 / 1024 / 1024 / 1024

    # Gesendeter Traffic pro Instance (GB/Tag)
    - record: instance:node_network_transmit_gb_per_day:predicted
      expr: |
        sum by (instance) (
          rate(node_network_transmit_bytes_total{device!~"lo|veth.*|docker.*"}[5m])
        ) * 86400 / 1024 / 1024 / 1024

    # Gesamter Traffic des Clusters (Empfang + Senden) in GB/Tag
    - record: cluster:node_network_total_gb_per_day:predicted
      expr: |
        sum(instance:node_network_receive_gb_per_day:predicted) +
        sum(instance:node_network_transmit_gb_per_day:predicted)

    # Nur Empfang cluster-wide
    - record: cluster:node_network_receive_gb_per_day:predicted
      expr: sum(instance:node_network_receive_gb_per_day:predicted)

    # Nur Senden cluster-wide
    - record: cluster:node_network_transmit_gb_per_day:predicted
      expr: sum(instance:node_network_transmit_gb_per_day:predicted)
```

**Erklärung**:
- `rate(...[5m])` gibt Bytes pro Sekunde
- `* 86400` multipliziert mit Sekunden pro Tag (24h * 3600s)
- `/ 1024 / 1024 / 1024` konvertiert zu Gigabytes
- `sum by (instance)` aggregiert über alle Netzwerk-Interfaces pro Instance
- Final `sum()` ohne Labels aggregiert über alle Instances

**Alternative mit tatsächlichen Werten (statt Hochrechnung)**:
```yaml
    # Tatsächlicher Traffic der letzten 24 Stunden
    - record: cluster:node_network_total_gb_last_24h:actual
      expr: |
        (
          sum(increase(node_network_receive_bytes_total{device!~"lo|veth.*"}[24h])) +
          sum(increase(node_network_transmit_bytes_total{device!~"lo|veth.*"}[24h]))
        ) / 1024 / 1024 / 1024
```

---

### Aufgabe 3: Predictive Recording Rule für Speicher unter 5%

**Ziel**: Vorhersage, wann der Speicher unter 5% fällt.

**Lösung**:
```yaml
groups:
  - name: memory_prediction_recording_rules
    interval: 1m
    rules:

    # Vorhergesagter verfügbarer Speicher in 1 Stunde
    - record: instance:node_memory_available_bytes:predict_1h
      expr: |
        predict_linear(node_memory_MemAvailable_bytes[30m], 3600)

    # Vorhergesagter verfügbarer Speicher in 4 Stunden
    - record: instance:node_memory_available_bytes:predict_4h
      expr: |
        predict_linear(node_memory_MemAvailable_bytes[1h], 14400)

    # Boolescher Indikator: Wird Speicher in 1h unter 5% fallen?
    - record: instance:node_memory_will_be_critical_1h:bool
      expr: |
        (
          instance:node_memory_available_bytes:predict_1h
          / node_memory_MemTotal_bytes
        ) < 0.05

    # Boolescher Indikator: Wird Speicher in 4h unter 5% fallen?
    - record: instance:node_memory_will_be_critical_4h:bool
      expr: |
        (
          instance:node_memory_available_bytes:predict_4h
          / node_memory_MemTotal_bytes
        ) < 0.05

    # Zeit in Sekunden bis Speicher unter 5% fällt (wenn Trend anhält)
    - record: instance:node_memory_seconds_until_critical:predicted
      expr: |
        (node_memory_MemAvailable_bytes - (node_memory_MemTotal_bytes * 0.05))
        / - deriv(node_memory_MemAvailable_bytes[30m])

    # Zeit in Stunden bis Speicher kritisch wird
    - record: instance:node_memory_hours_until_critical:predicted
      expr: |
        instance:node_memory_seconds_until_critical:predicted / 3600
```

**Erklärung**:
- `predict_linear(...[30m], 3600)` verwendet die letzten 30 Minuten um 1 Stunde vorherzusagen
- `deriv()` berechnet die Ableitung (Änderungsrate) des Speichers
- Division zeigt, wie lange es dauert bis kritische Grenze erreicht wird
- `< 0.05` prüft ob unter 5% (0.05 = 5%)

**Alert-Regel basierend auf dieser Recording Rule**:
```yaml
groups:
  - name: memory_prediction_alerts
    rules:
    - alert: MemoryWillBeCriticalSoon
      expr: instance:node_memory_will_be_critical_4h:bool == 1
      for: 10m
      labels:
        severity: warning
      annotations:
        summary: "Speicher wird in 4 Stunden kritisch (instance {{ $labels.instance }})"
        description: |
          Basierend auf dem aktuellen Trend wird der Speicher in ca.
          {{ $value | humanize }} Stunden unter 5% fallen.
```

---

## Erweiterte Recording Rules Beispiele

### Performance Monitoring

```yaml
groups:
  - name: advanced_performance_recording_rules
    interval: 30s
    rules:

    # System Saturation Score (0-1, höher = schlechter)
    - record: instance:system_saturation:score
      expr: |
        (
          # CPU-Komponente (Load pro CPU)
          (node_load1 / count without (cpu, mode) (node_cpu_seconds_total{mode="idle"}))
          +
          # Speicher-Komponente
          (1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)
          +
          # Disk I/O Wait
          (avg by (instance) (rate(node_cpu_seconds_total{mode="iowait"}[5m])))
        ) / 3

    # Netzwerk-Auslastung als Prozentsatz der Link-Geschwindigkeit
    # (benötigt Speed-Information, hier Beispiel für 1 Gbit)
    - record: instance_device:network_utilization:percent
      expr: |
        (
          rate(node_network_receive_bytes_total[5m]) +
          rate(node_network_transmit_bytes_total[5m])
        ) * 8 / 1000000000 * 100

    # Context Switches pro CPU Core
    - record: instance:context_switches_per_cpu:rate5m
      expr: |
        rate(node_context_switches_total[5m])
        / count without (cpu, mode) (node_cpu_seconds_total{mode="idle"})
```

### Capacity Planning

```yaml
groups:
  - name: capacity_planning_recording_rules
    interval: 5m
    rules:

    # Durchschnittliche CPU-Auslastung (7 Tage)
    - record: instance:node_cpu_utilization:avg_7d
      expr: |
        avg_over_time(
          instance:node_cpu_utilization:rate5m[7d]
        )

    # 95. Perzentil der CPU-Auslastung (7 Tage)
    - record: instance:node_cpu_utilization:quantile95_7d
      expr: |
        quantile_over_time(0.95,
          instance:node_cpu_utilization:rate5m[7d]
        )

    # Wachstumsrate der Festplattenbelegung (GB pro Woche)
    - record: instance:filesystem_growth_rate:gb_per_week
      expr: |
        - (
          deriv(node_filesystem_avail_bytes{fstype!~"tmpfs|fuse.*"}[7d])
          * 604800
        ) / 1024 / 1024 / 1024

    # Voraussichtliche Wochen bis Festplatte voll
    - record: instance:filesystem_weeks_until_full:predicted
      expr: |
        node_filesystem_avail_bytes{fstype!~"tmpfs|fuse.*"}
        / - deriv(node_filesystem_avail_bytes{fstype!~"tmpfs|fuse.*"}[7d])
        / 604800
```

### Fehler-Tracking

```yaml
groups:
  - name: error_tracking_recording_rules
    interval: 30s
    rules:

    # Netzwerk-Fehlerrate
    - record: instance:network_errors:rate5m
      expr: |
        sum by (instance) (
          rate(node_network_receive_errs_total[5m]) +
          rate(node_network_transmit_errs_total[5m])
        )

    # Disk-Fehler
    - record: instance:disk_errors:rate5m
      expr: |
        sum by (instance, device) (
          rate(node_disk_io_now[5m])
        )

    # Dropped Packets
    - record: instance:network_dropped_packets:rate5m
      expr: |
        sum by (instance) (
          rate(node_network_receive_drop_total[5m]) +
          rate(node_network_transmit_drop_total[5m])
        )
```

---

## Best Practices und Validierung

### Validierung der Recording Rules

```bash
# Alle Rules validieren
promtool check rules /etc/prometheus/rules/*.yml

# Spezifische Datei testen
promtool check rules /etc/prometheus/rules/node_recording_rules.yml

# Query testen (Syntax-Check)
promtool query instant http://localhost:9090 \
  'instance:node_cpu_utilization:rate5m'
```

### Performance-Überprüfung

**Query zur Überprüfung der Evaluation-Zeit**:
```promql
# Zeigt wie lange die Evaluation der Rules dauert
prometheus_rule_group_last_duration_seconds
```

**Anzahl der Recording Rules**:
```promql
count(prometheus_rule_group_rules)
```

**Anzahl der Time Series pro Recording Rule**:
```promql
count by (__name__) ({__name__=~"instance:.*|cluster:.*"})
```

### Storage Impact

Recording Rules erhöhen die Anzahl der Time Series. Überwachen Sie:

```promql
# Gesamtanzahl der Time Series
prometheus_tsdb_symbol_table_size_bytes

# Speichernutzung
process_resident_memory_bytes{job="prometheus"}

# Anzahl Time Series pro Job
count by (job) ({__name__!=""})
```

---

## Troubleshooting

### Recording Rule wird nicht evaluiert

**Prüfschritte**:
1. Logs prüfen: `journalctl -u prometheus -n 100`
2. Syntax validieren: `promtool check rules /etc/prometheus/rules/*.yml`
3. Prometheus-Config prüfen: `promtool check config /etc/prometheus/prometheus.yml`
4. Status im UI prüfen: http://localhost:9090/rules

### Recording Rule gibt keine Daten zurück

**Häufige Ursachen**:
- Basis-Metriken sind nicht verfügbar (z.B. Node Exporter down)
- Label-Mismatch in der Expression
- Query ist syntaktisch korrekt aber logisch falsch

**Debug-Queries**:
```promql
# Prüfen ob Basis-Metrik existiert
node_cpu_seconds_total

# Prüfen ob Recording Rule Daten hat
instance:node_cpu_utilization:rate5m

# Letzte Aktualisierung der Rule prüfen
timestamp(instance:node_cpu_utilization:rate5m)
```

---

## Zusammenfassung

Recording Rules sind essentiell für:
1. **Performance**: Komplexe Queries vorberechnen
2. **Konsistenz**: Eine Definition für alle Dashboards/Alerts
3. **Aggregation**: Daten über Zeit aggregieren
4. **Capacity Planning**: Historische Daten für Trend-Analysen

Achten Sie auf:
- Namenskonventionen (`level:metric:operations`)
- Angemessene Evaluation-Intervalle
- Storage-Impact (mehr Time Series)
- Dokumentation der Rules
