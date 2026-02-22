# Grafana - Aufgabenfeld 12a: Erstellung dynamischer Dashboards mit Variablen (Templating)

## 1. Neues Dashboard anlegen
- Legen Sie in Grafana ein neues Dashboard an, z.B. mit dem Namen `Server Monitoring Dynamic`.

## 2. Variable(n) definieren
- Öffnen Sie die Dashboard-Einstellungen und den Reiter `Variables`.
- Variable `instance` anlegen:
  - Type: `Query`
  - Data source: `Prometheus`
    - Query Type: `Classic Query`
    - Classic Query: `label_values({job=~".*node_exporter.*"},instance)`
  - Multi-value: aktivieren
  - Include All option: aktivieren
  - Custom all value: `.*` (Regex, damit Panels später `instance=~"$instance"` verwenden können)

## 3. Variablen in Panels und PromQL-Queries (verwenden `instance=~"$instance"`)

- CPU-Auslastung (%)
  ```promql
  100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle", instance=~"$instance"}[5m])) * 100)
  ```
  Tipps:
  - Y-Achse: 0–100 %
  - Legende: `CPU Util % ($Instance)`

- RAM-Auslastung (%)
  ```promql
  (1 - node_memory_MemAvailable_bytes{instance=~"$instance"} / node_memory_MemTotal_bytes{instance=~"$instance"}) * 100
  ```
  Alternative (Used in GiB):
  ```promql
  (node_memory_MemTotal_bytes{instance=~"$instance"} - node_memory_MemAvailable_bytes{instance=~"$instance"}) / 1024^3
  ```

- Filesystem-Nutzung (%)
  ```promql
  100 * (node_filesystem_size_bytes{fstype!~"tmpfs|overlay|squashfs", instance=~"$instance"}
        - node_filesystem_free_bytes{fstype!~"tmpfs|overlay|squashfs", instance=~"$instance"})
        / node_filesystem_size_bytes{fstype!~"tmpfs|overlay|squashfs", instance=~"$instance"}
  ```
  Panel-Hinweise: nach `mountpoint` facetieren (Series/Legend), problematische Mounts ausschließen falls nötig.

- Netzwerk-Durchsatz (Empfang + Versand in Bytes/s)
  - RX:
    ```promql
    sum by (instance) (irate(node_network_receive_bytes_total{device!~"lo", instance=~"$instance"}[5m]))
    ```
  - TX:
    ```promql
    sum by (instance) (irate(node_network_transmit_bytes_total{device!~"lo", instance=~"$instance"}[5m]))
    ```
  Tipp: Zwei Serien im gleichen Panel oder zwei separete Panels (RX/TX getrennt). Einheit: bytes/s oder bits/s (mit 8 multiplizieren).

- System-Load (1m, 5m, 15m) – optional normiert auf CPU-Anzahl
  - Nicht normiert:
    ```promql
    node_load1{instance=~"$instance"}
    ```
    Analog: `node_load5`, `node_load15`
  - Normiert (z.B. Load1 pro CPU):
    ```promql
    node_load1{instance=~"$instance"}
    /
    count without (cpu, mode) (node_cpu_seconds_total{mode="idle", instance=~"$instance"})
    ```

- Disk I/O – Operationen/s (optional)
  ```promql
  sum by (instance) (irate(node_disk_reads_completed_total{instance=~"$instance"}[5m])
                   + irate(node_disk_writes_completed_total{instance=~"$instance"}[5m]))
  ```

## 4. Annotation für hohe CPU-Last
Markieren Sie Zeitpunkte, an denen eine Instanz für mindestens 5 Minuten > 90 % CPU-Auslastung hat.

- Annotation-Quelle: `Prometheus`
- Query (liefert Werte, wenn Bedingung erfüllt ist):
  ```promql
  max_over_time(
    ((100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle", instance=~"$instance"}[1m])) * 100))
      > bool 90)[5m:]
  )
  ```
- Erläuterung:
  - `> bool 90` erzeugt 1/0 pro Zeitpunkt; `max_over_time(...[5m:])` wird 1, sobald die Bedingung in den letzten 5 Min durchgehend (oder zumindest anhaltend) wahr war.
- In Grafana im Annotation-Dialog optional eine Legende/Text setzen, z. B.: `High CPU on {{instance}}`.

Alternativ (vereinfachte, „sofortige“ Markierung ohne 5m-Sustain):
```promql
(100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle", instance=~"$instance"}[5m])) * 100)) > bool 90
```

## 5. Testen
- Wählen Sie in der `instance`-Variable verschiedene Hosts (Einzel- oder Mehrfachauswahl, `All`) und prüfen Sie ob alle Panels entsprechend gefiltert werden.
- Zeitbereich variieren (z.B. letzte 1h, 6h, 24h) und Datenverhalten beobachten.
