# Lösungsblatt 11a – Grafana Setup mit Prometheus

Dieses Lösungsblatt ergänzt das Anlegen der Prometheus-Datenquelle und die Erstellung eines kleinen Server-Monitoring-Dashboards.

## 1. Ziel
- Datenquelle „Prometheus“ ist in Grafana angelegt und getestet
- Dashboard „Server Monitoring“ mit CPU-, Speicher-, Disk- und Load-Panel vorhanden

## 2. Datenquelle hinzufügen
- Grafana → Connections → Data sources → Add data source → Prometheus
- URL: `http://localhost:9090`
- Scrape interval: z. B. `10s` (optional)
- Save & Test → „Successfully queried the Prometheus API.“

## 3. Panel-Beispiele
- CPU Usage (%), Titel: „CPU Usage“, Min/Max 0–100, Thresholds: Grün 0–60, Gelb 60–85, Rot 85–100
  ```promql
  100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[1m])) * 100)
  ```
- Speichernutzung (%)
  ```promql
  100 * (1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)
  ```
- Festplattennutzung „/“ (%)
  ```promql
  100 - ((node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100)
  ```
- Systemlast (1m)
  ```promql
  node_load1
  ```

## 4. Validierung
- Alle Panels zeigen Daten ohne Fehler
- Zeitbereich variieren (1h/6h/24h)

## 5. Troubleshooting
- `up{job="node"}` in Prometheus prüfen
- Stimmt der Job-Name? (ggf. `job="node"` anpassen)
- In Grafana richtige Datenquelle ausgewählt
