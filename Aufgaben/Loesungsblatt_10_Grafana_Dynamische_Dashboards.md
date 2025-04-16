# Lösungsblatt: Grafana - Erstellung dynamischer Dashboards mit Variablen (Templating)

Dieses Lösungsblatt enthält die Lösungen für die Aufgaben aus dem Aufgabenfeld 10: Erstellung dynamischer Dashboards mit Variablen (Templating) in Grafana.

## Aufgabe 1: Neues Dashboard anlegen

### Lösung:

1. Melden Sie sich bei Grafana an (http://localhost:3000)

2. Klicken Sie im linken Menü auf "Dashboards"

3. Klicken Sie auf "New" > "New Dashboard"

4. Klicken Sie auf "Add visualization" (oder "Add panel"), um ein neues Panel hinzuzufügen

5. Wählen Sie "InfluxDB Local" als Datenquelle

6. Klicken Sie auf das Disketten-Symbol in der oberen rechten Ecke, um das Dashboard zu speichern

7. Geben Sie als Namen "AirSensors" ein und klicken Sie auf "Save"

## Aufgabe 2: Variable definieren

### Lösung:

1. Klicken Sie im Dashboard auf das Zahnrad-Symbol in der oberen rechten Ecke, um die Dashboard-Einstellungen zu öffnen

2. Wählen Sie den Reiter "Variables"

3. Klicken Sie auf "Add variable"

4. Füllen Sie das Formular mit folgenden Werten aus:
   - Name: sensor_id
   - Label: Sensor ID
   - Type: Query
   - Data source: InfluxDB Local
   - Query type: Flux
   - Query:
     ```flux
     import "influxdata/influxdb/schema"
     schema.tagValues(bucket: "testdata-web", tag: "sensor_id")
     ```
   - Refresh: On Dashboard Load
   - Multi-value: aktivieren (optional)
   - Include All option: aktivieren
   - Custom all value: All

5. Klicken Sie auf "Update"

## Aufgabe 3: Dashboard-Panel konfigurieren

### Lösung:

1. Kehren Sie zum Dashboard zurück und bearbeiten Sie das vorhandene Panel (oder erstellen Sie ein neues)

2. Wählen Sie "InfluxDB Local" als Datenquelle

3. Fügen Sie folgende Flux-Abfrage in den Query-Editor ein:
   ```flux
   from(bucket: "testdata-web")
     |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
     |> filter(fn: (r) => if "${sensor_id}" == "All" then r["sensor_id"] != "" else r["sensor_id"] == "${sensor_id}")
     |> filter(fn: (r) => r["_measurement"] == "airSensors")
     |> filter(fn: (r) => r["_field"] == "temperature")
   ```

4. Konfigurieren Sie das Panel:
   - Titel: "Temperatur für ${sensor_id}"
   - Visualisierungstyp: Time series (Zeitreihe)
   - Einheit: Temperature > Celsius (°C)

5. Klicken Sie auf "Apply"

## Aufgabe 4: Testen

### Lösung:

1. Kehren Sie zum Dashboard zurück

2. Oben im Dashboard sollte nun ein Dropdown-Menü mit der Bezeichnung "Sensor ID" erscheinen

3. Wählen Sie verschiedene Sensor-IDs aus dem Dropdown-Menü aus:
   - Wählen Sie "All", um Daten von allen Sensoren anzuzeigen
   - Wählen Sie einzelne Sensor-IDs (z.B. "TLM0100", "TLM0101", etc.), um nur Daten von einem bestimmten Sensor anzuzeigen

4. Beobachten Sie, wie sich die Daten im Diagramm entsprechend der ausgewählten Sensor-ID ändern

## Aufgabe 5: Weiteres Diagramm einfügen

### Lösung:

### Diagramm für Luftfeuchtigkeit:

1. Klicken Sie auf "Add panel" > "Add visualization"

2. Wählen Sie "InfluxDB Local" als Datenquelle

3. Fügen Sie folgende Flux-Abfrage in den Query-Editor ein:
   ```flux
   from(bucket: "testdata-web")
     |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
     |> filter(fn: (r) => if "${sensor_id}" == "All" then r["sensor_id"] != "" else r["sensor_id"] == "${sensor_id}")
     |> filter(fn: (r) => r["_measurement"] == "airSensors")
     |> filter(fn: (r) => r["_field"] == "humidity")
   ```

4. Konfigurieren Sie das Panel:
   - Titel: "Luftfeuchtigkeit für ${sensor_id}"
   - Visualisierungstyp: Time series (Zeitreihe)
   - Einheit: Misc > percent (0-100)

5. Klicken Sie auf "Apply"

### Diagramm für CO-Wert:

1. Klicken Sie auf "Add panel" > "Add visualization"

2. Wählen Sie "InfluxDB Local" als Datenquelle

3. Fügen Sie folgende Flux-Abfrage in den Query-Editor ein:
   ```flux
   from(bucket: "testdata-web")
     |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
     |> filter(fn: (r) => if "${sensor_id}" == "All" then r["sensor_id"] != "" else r["sensor_id"] == "${sensor_id}")
     |> filter(fn: (r) => r["_measurement"] == "airSensors")
     |> filter(fn: (r) => r["_field"] == "co")
   ```

4. Konfigurieren Sie das Panel:
   - Titel: "CO-Wert für ${sensor_id}"
   - Visualisierungstyp: Time series (Zeitreihe)
   - Einheit: Concentration > ppm (parts per million)

5. Klicken Sie auf "Apply"

## Aufgabe 6: Annotations

### Lösung:

1. Klicken Sie im Dashboard auf das Zahnrad-Symbol in der oberen rechten Ecke, um die Dashboard-Einstellungen zu öffnen

2. Wählen Sie den Reiter "Annotations"

3. Klicken Sie auf "Add annotation query"

4. Füllen Sie das Formular mit folgenden Werten aus:
   - Name: Temperatur über 75°C
   - Data source: InfluxDB Local
   - Query type: Flux
   - Query:
     ```flux
     from(bucket: "testdata-web")
     |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
     |> filter(fn: (r) => r._measurement == "airSensors" and r._field == "temperature")
     |> filter(fn: (r) => if "${sensor_id}" == "All" then r["sensor_id"] != "" else r["sensor_id"] == "${sensor_id}")
     |> map(fn: (r) => ({
       _time: r._time,
       _value: r._value,
       sensor_id: r.sensor_id,
       over75: if r._value > 75.0 then 1 else 0
     }))
     |> difference(nonNegative: false, columns: ["over75"])
     |> filter(fn: (r) => r.over75 == 1)
     |> map(fn: (r) => ({
       _time: r._time,
       title: "Temperaturalarm",
       text: "Temperatur hat 75°C am Sensor ${string(v: r.sensor_id)} überschritten: ${string(v: r._value)}°C",
     }))
     |> keep(columns: ["_time", "title", "text", "tags"])
     ```

5. Klicken Sie auf "Update"

6. Kehren Sie zum Dashboard zurück

7. Um zu prüfen, bei welchem Sensor ein Temperaturanstieg über 75°C eingetreten ist:
   - Wählen Sie "All" im Sensor-ID-Dropdown
   - Stellen Sie den Zeitbereich auf einen größeren Wert ein (z.B. "Last 7 days")
   - Suchen Sie nach roten Annotationslinien im Dashboard
   - Klicken Sie auf eine Annotationslinie, um Details anzuzeigen
   - Die Detailinformationen zeigen, welcher Sensor den Schwellenwert überschritten hat und den genauen Temperaturwert

## Zusätzliche Hinweise

- Variablen in Grafana sind ein mächtiges Werkzeug, um Dashboards dynamisch und interaktiv zu gestalten
- Sie können mehrere Variablen definieren und diese miteinander verknüpfen (z.B. eine Variable für den Standort und eine für den Sensor)
- Variablen können auch in Panel-Titeln, Beschreibungen und Annotationen verwendet werden
- Die Syntax `${variable_name}` wird verwendet, um auf Variablenwerte in Abfragen und Texten zu verweisen
- Für komplexere Bedingungen in Flux-Abfragen können Sie if-else-Konstrukte verwenden, wie im Beispiel gezeigt
- Annotationen sind nützlich, um wichtige Ereignisse hervorzuheben und zusätzlichen Kontext zu Ihren Dashboards hinzuzufügen
- Für Produktionsumgebungen sollten Sie Schwellenwerte sorgfältig wählen und möglicherweise mit Alerting-Regeln kombinieren
