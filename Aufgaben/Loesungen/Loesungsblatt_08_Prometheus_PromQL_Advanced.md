# Lösungsblatt 8 – Prometheus PromQL Advanced

Dieses Lösungsblatt enthält die Lösungen zu den Übungsaufgaben aus Aufgabenfeld 5a.

## Übungsaufgaben - Lösungen

### Aufgabe 1: System Load pro CPU

**Ziel**: Berechnen der System Load normalisiert auf die Anzahl der CPUs.

**Lösung**:
```promql
node_load1 / count without (cpu, mode) (node_cpu_seconds_total{mode="idle"})
```

**Erklärung**:
- `node_load1` gibt die 1-Minuten System Load
- `count without (cpu, mode)` zählt die Anzahl der CPU-Cores (jeder Core hat eine eigene `node_cpu_seconds_total` Serie)
- Division normalisiert die Load auf die CPU-Anzahl
- Werte > 1.0 bedeuten Überlastung

**Alternative mit allen Load-Werten**:
```promql
# Load 1 Minute
node_load1 / count without (cpu, mode) (node_cpu_seconds_total{mode="idle"})

# Load 5 Minuten
node_load5 / count without (cpu, mode) (node_cpu_seconds_total{mode="idle"})

# Load 15 Minuten
node_load15 / count without (cpu, mode) (node_cpu_seconds_total{mode="idle"})
```

---

### Aufgabe 2: Durchschnittliche Festplattenbelegung

**Ziel**: Berechnen der durchschnittlichen Festplattenbelegung über alle Mountpoints (außer tmpfs).

**Lösung**:
```promql
avg(
  100 - (
    node_filesystem_avail_bytes{fstype!~"tmpfs|fuse.*|overlay|squashfs"}
    / node_filesystem_size_bytes{fstype!~"tmpfs|fuse.*|overlay|squashfs"}
    * 100
  )
)
```

**Erklärung**:
- Filter `fstype!~"..."` schließt temporäre und virtuelle Filesysteme aus
- Berechnung: (verfügbar / gesamt * 100), dann von 100 subtrahiert = Belegung in %
- `avg()` bildet den Durchschnitt über alle gefilterten Mountpoints

**Alternative - Durchschnitt pro Instance**:
```promql
avg by (instance) (
  100 - (
    node_filesystem_avail_bytes{fstype!~"tmpfs|fuse.*|overlay|squashfs"}
    / node_filesystem_size_bytes{fstype!~"tmpfs|fuse.*|overlay|squashfs"}
    * 100
  )
)
```

---

### Aufgabe 3: Netzwerk-Traffic Top 3

**Ziel**: Zeigen der Top 3 Netzwerk-Interfaces nach Empfangs-Traffic.

**Lösung**:
```promql
topk(3,
  rate(node_network_receive_bytes_total{device!~"lo|veth.*|docker.*"}[5m])
)
```

**Erklärung**:
- `rate(...[5m])` berechnet die Empfangsrate über 5 Minuten
- `device!~"lo|veth.*|docker.*"` filtert Loopback und virtuelle Interfaces aus
- `topk(3, ...)` gibt die 3 höchsten Werte zurück

**Alternative mit Umrechnung in MB/s**:
```promql
topk(3,
  rate(node_network_receive_bytes_total{device!~"lo|veth.*|docker.*"}[5m]) / 1024 / 1024
)
```

**Bonus - Top 3 für Sende- und Empfangs-Traffic kombiniert**:
```promql
topk(3,
  (
    rate(node_network_receive_bytes_total{device!~"lo|veth.*|docker.*"}[5m]) +
    rate(node_network_transmit_bytes_total{device!~"lo|veth.*|docker.*"}[5m])
  ) / 1024 / 1024
)
```

---

### Aufgabe 4: Speicherdruck-Indikator

**Ziel**: Erstellen eines Indikators, der "1" zurückgibt, wenn der verfügbare Speicher unter 10% liegt.

**Lösung**:
```promql
((node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100) < bool 10
```

**Erklärung**:
- Berechnet verfügbaren Speicher in Prozent
- `< bool 10` gibt 1 zurück wenn Bedingung wahr (< 10%), sonst 0
- Kann direkt in Alerts verwendet werden

**Alternative Ansätze**:

**Mit Labels versehen**:
```promql
label_replace(
  ((node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100) < bool 10,
  "status", "pressure", "", ""
)
```

**Kritischer Speicherdruck (< 5%)**:
```promql
((node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100) < bool 5
```

**Mehrere Schwellwerte**:
```promql
# Warnung: < 20%
((node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100) < bool 20

# Kritisch: < 10%
((node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100) < bool 10

# Notfall: < 5%
((node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100) < bool 5
```

---

## Zusätzliche Beispiele und Tipps

### Komplexe Aggregationen

**CPU-Auslastung nach Mode**:
```promql
sum by (mode) (rate(node_cpu_seconds_total[5m]))
```

**Prozentuale Verteilung der CPU-Modi**:
```promql
100 * sum by (mode) (rate(node_cpu_seconds_total[5m]))
/ ignoring(mode) group_left sum(rate(node_cpu_seconds_total[5m]))
```

### Predictive Queries

**Wann wird die Festplatte voll?**:
```promql
# Gibt die Unix-Timestamp zurück, wann die Festplatte voll sein wird
(
  node_filesystem_avail_bytes{mountpoint="/",fstype!~"tmpfs|fuse.*"}
  / - deriv(node_filesystem_avail_bytes{mountpoint="/",fstype!~"tmpfs|fuse.*"}[1h])
)
```

**Speicher-Trend**:
```promql
# Vorhergesagter verfügbarer Speicher in 1 Stunde
predict_linear(node_memory_MemAvailable_bytes[30m], 3600)
```

### Performance-Metriken

**Kontext-Switches pro Sekunde**:
```promql
rate(node_context_switches_total[5m])
```

**Interrupts pro Sekunde**:
```promql
rate(node_intr_total[5m])
```

**Prozesse**:
```promql
# Anzahl der laufenden Prozesse
node_procs_running

# Anzahl der blockierten Prozesse
node_procs_blocked
```

### Troubleshooting

**Hohe Query-Ausführungszeit**:
1. Reduzieren Sie das Range-Window wenn möglich
2. Verwenden Sie Recording Rules für komplexe Queries
3. Filtern Sie früh (Labels vor Aggregation)
4. Vermeiden Sie `rate()` über sehr lange Zeiträume

**Fehlende Daten**:
1. Prüfen Sie, ob Node Exporter läuft: `up{job="node"}`
2. Überprüfen Sie die Scrape-Konfiguration
3. Prüfen Sie Prometheus-Logs: `journalctl -u prometheus -n 50`

---