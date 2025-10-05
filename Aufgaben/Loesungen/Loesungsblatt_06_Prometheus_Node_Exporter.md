# Lösungsblatt 06 – Prometheus Node Exporter

Dieses Lösungsblatt beschreibt Installation, Dienstbetrieb und Validierung des Node Exporters sowie die Einbindung in Prometheus.

## 1. Ziel
- Node Exporter läuft als Dienst (Standard-Port 9100)
- Prometheus scrapt den Node Exporter (Target UP)

## 2. Installation (laut Aufgabenblatt)
- Binary entpacken und `node_exporter` nach `/usr/local/bin` kopieren
- Service-Datei erstellen, Dienst starten:  
  `systemctl enable --now node_exporter`
- Status prüfen: `systemctl status node_exporter`

## 3. Prometheus Scrape-Konfiguration
- In `/etc/prometheus/prometheus.yml` ergänzen:
  ```yaml
  scrape_configs:
    - job_name: 'node'
      static_configs:
        - targets: ['<host>:9100']
  ```
- Prometheus neu laden: `systemctl reload prometheus` (oder Restart)

## 4. Validierung
- Node Exporter Metriken im Browser: `http://<host>:9100/metrics`
- Prometheus Targets: `Status → Targets` → Job `node` sollte UP sein
- Beispiel-Queries:
  - CPU idle Anteil: `rate(node_cpu_seconds_total{mode="idle"}[5m])`
  - RAM genutzt (%): `100 * (1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)`

## 5. Troubleshooting
- Port 9100 erreichbar? Firewall prüfen
- Service-Logs: `journalctl -u node_exporter -e`
- Mehrere Netz-Interfaces: ggf. `--web.listen-address` setzen
