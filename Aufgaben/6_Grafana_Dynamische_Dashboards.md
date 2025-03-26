# Grafana - Aufgabenfeld 6: Erstellung dynamischer Dashboards mit Variablen (Templating)

## Aufgabenbeschreibung

1. **Neues Dashboard anlegen:**
   Erstellen Sie ein neues Dashboard in Grafana und fügen Sie mindestens ein Diagramm-Panel hinzu.

2. **Variable definieren:**
   - Gehen Sie in den Dashboard-Einstellungen auf den Reiter „Variables“ (Variablen).
   - Fügen Sie eine neue Variable hinzu, z. B. `host`.
   - Definieren Sie die Abfrage zum Abrufen der Hostnamen.
     - **FLUX-Abfrage:**
       ```flux
       import "influxdata/influxdb/schema"
       schema.tagValues(bucket: "computer-monitoring", tag: "host")
       ```
     - **InfluxQL-Abfrage:**
       ```influxql
       SHOW TAG VALUES FROM "cpu" WITH KEY = "host"
       ```
   - Legen Sie ggf. einen Standardwert fest.

3. **Dashboard-Panel konfigurieren:**
   Ändern Sie die Abfrage des Panels, um die Variable zu nutzen. Beispiel:
   ```flux
   from(bucket: "computer-monitoring")
     |> range(start: -30d)
     |> filter(fn: (r) => r["host"] == "${host}")
     |> filter(fn: (r) => r["_measurement"] == "cpu")
     |> filter(fn: (r) => r["_field"] == "usage_system")

4. **Testen und Dokumentieren:**
   Wählen Sie unterschiedliche Hostnamen aus der Variable und beobachten Sie die Änderungen im Dashboard.