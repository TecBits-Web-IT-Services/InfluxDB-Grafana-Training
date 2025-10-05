# Lösungsblatt 10a – Grafana Dynamische Dashboards (Prometheus + Node Exporter)

Dieses Lösungsblatt liefert Musterlösungen für Variablen und PromQL-Queries mit dem Node Exporter.

## 1. Ziel
- Variable `instance` (optional `job`) korrekt eingerichtet
- Panels filtern mit `instance=~"$instance"`

## 2. Variable(n)
- Dashboard → Settings → Variables → Add variable
- Name: `instance`, Type: Query, Data source: Prometheus
- Query:
  ```promql
  label_values(up{job="node"}, instance)
  ```
- Multi-value: on; Include All: on; Custom all value: `.*`
- Optional `job`:
  ```promql
  label_values(up, job)
  ```
  und `instance`-Query zu `label_values(up{job="$job"}, instance)` anpassen

## 3. Panels (Beispiele)
- CPU-Auslastung (%)
  ```promql
  100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle", instance=~"$instance"}[5m])) * 100)
  ```
- RAM-Auslastung (%)
  ```promql
  (1 - node_memory_MemAvailable_bytes{instance=~"$instance"} / node_memory_MemTotal_bytes{instance=~"$instance"}) * 100
  ```
- Filesystem-Nutzung (%)
  ```promql
  100 * (node_filesystem_size_bytes{fstype!~"tmpfs|overlay|squashfs", instance=~"$instance"}
        - node_filesystem_free_bytes{fstype!~"tmpfs|overlay|squashfs", instance=~"$instance"})
        / node_filesystem_size_bytes{fstype!~"tmpfs|overlay|squashfs", instance=~"$instance"}
  ```
- Netzwerk RX/TX (Bytes/s)
  ```promql
  sum by (instance) (irate(node_network_receive_bytes_total{device!~"lo", instance=~"$instance"}[5m]))
  sum by (instance) (irate(node_network_transmit_bytes_total{device!~"lo", instance=~"$instance"}[5m]))
  ```
- Load1 (optional normiert)
  ```promql
  node_load1{instance=~"$instance"}
  ```
  bzw. normiert:
  ```promql
  node_load1{instance=~"$instance"}
  /
  count without (cpu, mode) (node_cpu_seconds_total{mode="idle", instance=~"$instance"})
  ```

## 4. Annotation „CPU > 90 % für 5m“
```promql
max_over_time(
  ((100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle", instance=~"$instance"}[1m])) * 100)) > bool 90)[5m:]
)
```

## 5. Validierung
- Instanzen wechseln (Einzel-/Mehrfachauswahl, All)
- Zeiträume variieren

## 6. Troubleshooting
- `up{job="node"}` liefert Instanzen?
- Job-Name ggf. anpassen
