# Prometheus - Aufgabenfeld 9: Recording Rules und Performance-Optimierung

## Verwendung von Recording Rules zur Performance-Verbesserung

### Was sind Recording Rules?

Recording Rules sind vordefinierte PromQL-Abfragen, die Prometheus regelmäßig ausführt und deren Ergebnisse als neue Time Series speichert. Dies bietet mehrere Vorteile:

1. **Performance**: Komplexe Abfragen werden vorberechnet
2. **Konsistenz**: Dieselbe Berechnung wird überall gleich verwendet
3. **Effizienz**: Dashboards und Alerts greifen auf vorberechnete Metriken zu
4. **Langzeit-Speicherung**: Aggregierte Daten können länger aufbewahrt werden

### 1. Erstellen der Recording Rules Konfiguration

```bash
# Erstellen des Verzeichnisses für Recording Rules (falls noch nicht vorhanden)
mkdir -p /etc/prometheus/rules

# Erstellen einer Datei für Recording Rules
cat > /etc/prometheus/rules/node_recording_rules.yml << 'EOF'
groups:
  - name: node_recording_rules
    interval: 30s  # Wie oft die Rules evaluiert werden (optional, default: global.evaluation_interval)
    rules:

    # CPU-Auslastung pro Instance (vorberechnet)
    - record: instance:node_cpu_utilization:rate5m
      expr: 100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

    # Speicherauslastung in Prozent
    - record: instance:node_memory_utilization:ratio
      expr: 100 * (1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)

    # Freier Speicher in GB
    - record: instance:node_memory_available:bytes
      expr: node_memory_MemAvailable_bytes / 1024 / 1024 / 1024

    # Festplattenbelegung in Prozent (nur echte Filesysteme)
    - record: instance:node_filesystem_utilization:ratio
      expr: |
        100 - (
          node_filesystem_avail_bytes{fstype!~"tmpfs|fuse.*|overlay"}
          / node_filesystem_size_bytes{fstype!~"tmpfs|fuse.*|overlay"}
          * 100
        )

    # Netzwerk-Empfangsrate in MB/s
    - record: instance:node_network_receive:rate5m
      expr: sum by (instance) (rate(node_network_receive_bytes_total{device!~"lo|veth.*"}[5m])) / 1024 / 1024

    # Netzwerk-Senderate in MB/s
    - record: instance:node_network_transmit:rate5m
      expr: sum by (instance) (rate(node_network_transmit_bytes_total{device!~"lo|veth.*"}[5m])) / 1024 / 1024

    # System Load normalisiert auf CPU-Anzahl
    - record: instance:node_load1_per_cpu:ratio
      expr: |
        node_load1
        / count without (cpu, mode) (node_cpu_seconds_total{mode="idle"})

    # Festplatten I/O - Operationen pro Sekunde
    - record: instance:node_disk_io_ops:rate5m
      expr: |
        sum by (instance) (
          rate(node_disk_reads_completed_total[5m]) +
          rate(node_disk_writes_completed_total[5m])
        )

  # Aggregierte Recording Rules (für gesamte Infrastructure)
  - name: cluster_recording_rules
    interval: 1m
    rules:

    # Durchschnittliche CPU-Auslastung über alle Instances
    - record: cluster:node_cpu_utilization:avg
      expr: avg(instance:node_cpu_utilization:rate5m)

    # Gesamter verwendeter Speicher im Cluster (in GB)
    - record: cluster:node_memory_used:sum
      expr: sum(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / 1024 / 1024 / 1024

    # Anzahl der überwachten Nodes
    - record: cluster:node_count:sum
      expr: count(up{job="node"} == 1)

    # Gesamter Netzwerk-Traffic (Ein- und Ausgang in MB/s)
    - record: cluster:node_network_total:rate5m
      expr: |
        sum(instance:node_network_receive:rate5m) +
        sum(instance:node_network_transmit:rate5m)
EOF

# Setzen der Berechtigungen
chown prometheus:prometheus /etc/prometheus/rules/node_recording_rules.yml

# Validieren der Recording Rules
promtool check rules /etc/prometheus/rules/node_recording_rules.yml
```

### 2. Prometheus-Konfiguration aktualisieren

Die `rule_files` Sektion sollte bereits in Aufgabenfeld 7 konfiguriert worden sein. Überprüfen Sie:

```bash
# Anzeigen der relevanten Konfiguration
grep -A 2 "rule_files:" /etc/prometheus/prometheus.yml
```

Falls nicht vorhanden, fügen Sie hinzu:

```bash
# Bearbeiten der Prometheus-Konfigurationsdatei
nano /etc/prometheus/prometheus.yml
```

Stellen Sie sicher, dass diese Zeilen vorhanden sind:

```yaml
rule_files:
  - "/etc/prometheus/rules/*.yml"
```

### 3. Prometheus neu starten

```bash
# Konfiguration validieren
promtool check config /etc/prometheus/prometheus.yml

# Prometheus neu laden (sanfter)
systemctl reload prometheus

# Oder Neustart (falls reload nicht funktioniert)
systemctl restart prometheus

# Status prüfen
systemctl status prometheus
```

### 4. Recording Rules überprüfen

- Öffnen Sie das Prometheus-Webinterface unter [http://localhost:9090](http://localhost:9090)
- Navigieren Sie zu **Status > Rules**
- Sie sollten die Gruppen `node_recording_rules` und `cluster_recording_rules` sehen
- Überprüfen Sie, ob alle Rules den Status "OK" haben

### 5. Verwendung der Recording Rules

Testen Sie die neuen Metriken im Graph-Interface:

```promql
# CPU-Auslastung (vorberechnet)
instance:node_cpu_utilization:rate5m

# Speicherauslastung
instance:node_memory_utilization:ratio

# Cluster-weite durchschnittliche CPU-Auslastung
cluster:node_cpu_utilization:avg

# Anzahl der überwachten Nodes
cluster:node_count:sum
```

### 6. Namenskonventionen für Recording Rules

Prometheus empfiehlt folgende Namenskonvention:

```
level:metric:operations
```

**Beispiele**:
- `instance:node_cpu_utilization:rate5m`
  - **level**: `instance` (Aggregationslevel)
  - **metric**: `node_cpu_utilization` (Was wird gemessen)
  - **operations**: `rate5m` (Welche Operation, über welchen Zeitraum)

- `cluster:node_memory_used:sum`
  - **level**: `cluster` (über alle Instances)
  - **metric**: `node_memory_used`
  - **operations**: `sum` (Summierung)

### 7. Alerts mit Recording Rules optimieren

Aktualisieren Sie Ihre Alert-Regeln, um die Recording Rules zu verwenden:

```bash
# Bearbeiten der Alert-Regeln
nano /etc/prometheus/rules/node_alerts.yml
```

Ersetzen Sie komplexe Expressions durch Recording Rules:

```yaml
groups:
- name: node_alerts_optimized
  rules:
  # Vorher: Komplexe Expression
  # expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80

  # Nachher: Verwendung der Recording Rule
  - alert: HighCPULoad
    expr: instance:node_cpu_utilization:rate5m > 80
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "Hohe CPU-Auslastung (instance {{ $labels.instance }})"
      description: "CPU-Auslastung ist über 80%\n  WERT = {{ $value | humanize }}%"

  - alert: HighMemoryLoad
    expr: instance:node_memory_utilization:ratio > 85
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "Hohe Speicherauslastung (instance {{ $labels.instance }})"
      description: "Speicherauslastung ist über 85%\n  WERT = {{ $value | humanize }}%"

  - alert: ClusterAverageCPUHigh
    expr: cluster:node_cpu_utilization:avg > 70
    for: 10m
    labels:
      severity: warning
    annotations:
      summary: "Hohe durchschnittliche Cluster CPU-Auslastung"
      description: "Durchschnittliche CPU-Auslastung über alle Nodes ist über 70%\n  WERT = {{ $value | humanize }}%"
```

### 8. Performance-Vergleich

Sie können die Performance-Verbesserung messen:

#### Vor Recording Rules (komplexe Query):
```promql
100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

#### Nach Recording Rules (einfache Query):
```promql
instance:node_cpu_utilization:rate5m
```

Die Recording Rule wird **vorab berechnet**, daher sind Dashboards und Alerts deutlich schneller.

### 9. Erweiterte Recording Rules - Praktische Beispiele

```yaml
groups:
  - name: advanced_recording_rules
    interval: 1m
    rules:

    # Uptime in Stunden
    - record: instance:node_uptime:hours
      expr: (time() - node_boot_time_seconds) / 3600

    # Festplatten-Füllrate (GB pro Stunde)
    - record: instance:node_filesystem_fill_rate:gbph
      expr: |
        - (
          predict_linear(
            node_filesystem_avail_bytes{fstype!~"tmpfs|fuse.*"}[1h],
            3600
          ) - node_filesystem_avail_bytes{fstype!~"tmpfs|fuse.*"}
        ) / 1024 / 1024 / 1024

    # Vorhergesagte Zeit bis Festplatte voll (in Stunden)
    - record: instance:node_filesystem_hours_until_full:predicted
      expr: |
        (
          node_filesystem_avail_bytes{fstype!~"tmpfs|fuse.*"}
          / - deriv(node_filesystem_avail_bytes{fstype!~"tmpfs|fuse.*"}[1h])
        ) / 3600

    # Speicher-Pressure (wenn < 10% frei)
    - record: instance:node_memory_pressure:bool
      expr: (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) < 0.1

    # Context Switches pro Sekunde
    - record: instance:node_context_switches:rate5m
      expr: rate(node_context_switches_total[5m])
```

### 10. Best Practices für Recording Rules

1. **Benennung**: Folgen Sie der Namenskonvention `level:metric:operations`
2. **Interval**: Wählen Sie ein angemessenes Evaluation-Interval (nicht zu häufig)
3. **Komplexität**: Recording Rules für komplexe, häufig verwendete Queries
4. **Storage**: Bedenken Sie, dass jede Recording Rule zusätzliche Time Series erstellt
5. **Testing**: Testen Sie Recording Rules vor dem Produktiveinsatz
6. **Documentation**: Kommentieren Sie komplexe Recording Rules

### 11. Troubleshooting

#### Recording Rules werden nicht evaluiert
```bash
# Logs prüfen
journalctl -u prometheus -n 100 --no-pager

# Prometheus-Status prüfen
systemctl status prometheus

# Syntax prüfen
promtool check rules /etc/prometheus/rules/*.yml
```

#### Recording Rules sind langsam
- Interval erhöhen (z.B. von 30s auf 1m)
- Komplexität der Expressions reduzieren
- Anzahl der Labels reduzieren

### 12. Übungsaufgaben

#### Aufgabe 1: Eigene Recording Rule erstellen
Erstellen Sie eine Recording Rule für die durchschnittliche Disk I/O Latenz.

#### Aufgabe 2: Cluster-wide Recording Rule
Erstellen Sie eine Recording Rule, die den gesamten Netzwerk-Traffic des Clusters in GB/Tag berechnet.

#### Aufgabe 3: Predictive Recording Rule
Erstellen Sie eine Recording Rule, die vorhersagt, wann der Speicher unter 5% fällt.

### 13. Weitere Ressourcen

- [Offizielle Recording Rules Dokumentation](https://prometheus.io/docs/prometheus/latest/configuration/recording_rules/)
- [Best Practices für Recording Rules](https://prometheus.io/docs/practices/rules/)

> **Wichtige Hinweise**:
> - Recording Rules erhöhen die Anzahl der Time Series (und damit Storage-Bedarf)
> - Nicht jede Query braucht eine Recording Rule - nur häufig verwendete, komplexe Queries
> - Testen Sie die Performance-Verbesserung nach der Implementierung
> - Überwachen Sie die Evaluation-Zeit der Rules unter Status > Rules
