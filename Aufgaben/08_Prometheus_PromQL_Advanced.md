# Prometheus - Aufgabenfeld 8: Erweiterte PromQL-Abfragen

## Vertiefung in die Prometheus Query Language (PromQL)

### Voraussetzungen
- Abgeschlossene Aufgabenfelder 5, 6 (Prometheus Setup und Node Exporter)
- Node Exporter sollte Metriken sammeln

### 1. Grundlegende PromQL-Operatoren

#### Instant Vectors vs Range Vectors

**Instant Vector** - Ein Zeitpunkt:
```promql
# Aktueller Wert der CPU-Zeit im idle mode
node_cpu_seconds_total{mode="idle"}
```

**Range Vector** - Ein Zeitbereich:
```promql
# CPU-Zeit im idle mode über die letzten 5 Minuten
node_cpu_seconds_total{mode="idle"}[5m]
```

### 2. Rate vs iRate

#### rate() - Durchschnittliche Rate über einen Zeitraum
```promql
# Durchschnittliche CPU-Rate über 5 Minuten (glatter)
rate(node_cpu_seconds_total{mode="idle"}[5m])

# Netzwerk-Empfangsrate über 1 Minute
rate(node_network_receive_bytes_total[1m])
```

#### irate() - Momentane Rate zwischen letzten zwei Datenpunkten
```promql
# Momentane CPU-Rate (reagiert schneller auf Änderungen)
irate(node_cpu_seconds_total{mode="idle"}[5m])

# Netzwerk-Empfangsrate (reaktiver)
irate(node_network_receive_bytes_total[1m])
```

> **Wann welche Funktion?**
> - `rate()`: Für Alerts und langfristige Trends (stabiler, weniger anfällig für Spikes)
> - `irate()`: Für Dashboards und kurzfristige Änderungen (zeigt aktuelle Werte genauer)

### 3. Aggregation Operators

#### sum, avg, min, max, count

```promql
# Gesamte CPU-Zeit über alle Cores
sum(rate(node_cpu_seconds_total[5m]))

# Durchschnittliche CPU-Auslastung über alle Instances
avg(100 - (rate(node_cpu_seconds_total{mode="idle"}[5m]) * 100))

# Minimale verfügbare Speicher über alle Instances
min(node_memory_MemAvailable_bytes)

# Maximale CPU-Auslastung über alle Instances
max(100 - (rate(node_cpu_seconds_total{mode="idle"}[5m]) * 100))
```

#### Aggregation mit by und without

```promql
# CPU-Auslastung pro Instance
sum by (instance) (rate(node_cpu_seconds_total{mode!="idle"}[5m]))

# Gesamte CPU-Auslastung ohne CPU-Core-Unterscheidung
sum without (cpu) (rate(node_cpu_seconds_total{mode="idle"}[5m]))
```

### 4. Binary Operators - Arithmetische Operationen

```promql
# Freier Speicher in Prozent
(node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100

# Benutzter Speicher in GB
(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / 1024 / 1024 / 1024

# Festplattenbelegung in Prozent
(node_filesystem_size_bytes{mountpoint="/"} - node_filesystem_avail_bytes{mountpoint="/"})
/ node_filesystem_size_bytes{mountpoint="/"} * 100

# Netzwerk-Durchsatz in Mbit/s
rate(node_network_receive_bytes_total[1m]) * 8 / 1000000
```

### 5. Comparison Operators und Filtering

```promql
# Nur Instances mit hoher CPU-Auslastung (>50%)
(100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)) > 50

# Instances mit wenig freiem Speicher (<20%)
((node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100) < 20

# Festplatten mit mehr als 80% Belegung
(100 - ((node_filesystem_avail_bytes / node_filesystem_size_bytes) * 100)) > 80
```

### 6. Nützliche Funktionen

#### increase() - Gesamter Anstieg über einen Zeitraum
```promql
# Gesamte empfangene Bytes in den letzten 5 Minuten
increase(node_network_receive_bytes_total[5m])

# Gesamte gesendete Bytes in der letzten Stunde
increase(node_network_transmit_bytes_total[1h])
```

#### delta() und idelta() - Differenz zwischen erstem und letztem Wert
```promql
# Änderung des freien Speichers in den letzten 10 Minuten
delta(node_memory_MemAvailable_bytes[10m])

# Momentane Änderung des freien Speichers
idelta(node_memory_MemAvailable_bytes[5m])
```

#### predict_linear() - Lineare Vorhersage
```promql
# Vorhergesagte Festplattenbelegung in 4 Stunden (14400 Sekunden)
predict_linear(node_filesystem_avail_bytes{mountpoint="/"}[1h], 4*3600)

# Wann wird die Festplatte voll sein? (negative Vorhersage)
predict_linear(node_filesystem_avail_bytes{mountpoint="/"}[2h], 24*3600) < 0
```

### 7. Time Functions

```promql
# Aktuelle Unix-Timestamp
time()

# Zeit seit letztem Neustart in Stunden
(time() - node_boot_time_seconds) / 3600

# Uptime in Tagen
(time() - node_boot_time_seconds) / 86400
```

### 8. Histogram und Summary Metriken (Beispiel mit Prometheus-eigenen Metriken)

```promql
# 95. Perzentil der HTTP-Request-Dauer
histogram_quantile(0.95,
  rate(prometheus_http_request_duration_seconds_bucket[5m])
)

# 50. Perzentil (Median)
histogram_quantile(0.5,
  rate(prometheus_http_request_duration_seconds_bucket[5m])
)

# 99. Perzentil
histogram_quantile(0.99,
  rate(prometheus_http_request_duration_seconds_bucket[5m])
)
```

### 9. Label Replacement und Regex

```promql
# Alle Netzwerk-Interfaces außer Loopback und Virtual
rate(node_network_receive_bytes_total{device!~"lo|veth.*|docker.*"}[5m])

# Nur bestimmte Filesysteme
node_filesystem_avail_bytes{fstype=~"ext4|xfs"}

# Ausschluss von temporären Dateisystemen
node_filesystem_avail_bytes{fstype!~"tmpfs|fuse.*"}
```

### 10. Komplexe Abfragen - Praxisbeispiele

#### Top 5 Prozesse nach CPU-Auslastung (wenn process-exporter installiert ist)
```promql
topk(5,
  rate(namedprocess_namegroup_cpu_seconds_total[5m])
)
```

#### Gesamter Netzwerk-Traffic (Ein- und Ausgang)
```promql
sum(
  rate(node_network_receive_bytes_total{device!~"lo|veth.*"}[5m]) +
  rate(node_network_transmit_bytes_total{device!~"lo|veth.*"}[5m])
) / 1024 / 1024
```

#### Speicherauslastung nach Typ
```promql
# Verwendeter Speicher (ohne Cache/Buffer)
node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes

# Cache-Speicher
node_memory_Cached_bytes

# Buffer-Speicher
node_memory_Buffers_bytes
```

#### Festplatten I/O Operationen pro Sekunde
```promql
# Lese-Operationen
sum(rate(node_disk_reads_completed_total[5m]))

# Schreib-Operationen
sum(rate(node_disk_writes_completed_total[5m]))

# Gesamte I/O-Operationen
sum(
  rate(node_disk_reads_completed_total[5m]) +
  rate(node_disk_writes_completed_total[5m])
)
```

### 11. Übungsaufgaben

Erstellen Sie PromQL-Abfragen für folgende Szenarien:

#### Aufgabe 1: System Load pro CPU
Berechnen Sie die System Load normalisiert auf die Anzahl der CPUs (Load1 / CPU-Anzahl).

> **Hinweis**
> - Verwenden Sie `node_load1` und zählen Sie die CPUs mit `count()`.

#### Aufgabe 2: Durchschnittliche Festplattenbelegung
Berechnen Sie die durchschnittliche Festplattenbelegung über alle Mountpoints (außer tmpfs).

> **Hinweis**
> - Filtern Sie mit `fstype!~"tmpfs|..."` und verwenden Sie `avg()`.

#### Aufgabe 3: Netzwerk-Traffic Top 3
Zeigen Sie die Top 3 Netzwerk-Interfaces nach Empfangs-Traffic an.

> **Hinweis**
> -Verwenden Sie `topk(3, ...)` mit `rate(node_network_receive_bytes_total[5m])`.


#### Aufgabe 4: Speicherdruck-Indikator
Erstellen Sie einen Indikator, der "1" zurückgibt, wenn der verfügbare Speicher unter 10% liegt.

>**Hinweis anzeigen**
> - Verwenden Sie Comparison Operators und `bool`.

### 12. Best Practices für PromQL

1. **Verwenden Sie rate() für Alerts**: Stabiler als irate()
2. **Wählen Sie das richtige Range-Window**:
   - Mindestens 4x das Scrape-Interval
   - Zu groß = träge, zu klein = ungenau
3. **Aggregieren Sie früh**: `sum() by (instance)` ist effizienter als spätere Aggregation
4. **Vermeiden Sie zu viele Labels in Dashboards**: Kann Performance-Probleme verursachen
5. **Testen Sie Queries**: Verwenden Sie das Prometheus-Webinterface zum Testen

### 13. Weitere Ressourcen

- [Offizielle PromQL-Dokumentation](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [PromQL-Cheat-Sheet](https://promlabs.com/promql-cheat-sheet/)
- [Query Examples](https://prometheus.io/docs/prometheus/latest/querying/examples/)

> **Hinweise**:
> - Experimentieren Sie mit verschiedenen Queries im Prometheus-Webinterface
> - Achten Sie auf die Query-Performance (Execution time wird angezeigt)
> - Verwenden Sie "Explain" für komplexe Queries
