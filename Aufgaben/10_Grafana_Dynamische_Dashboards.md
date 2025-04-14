# Grafana - Aufgabenfeld 10: Erstellung dynamischer Dashboards mit Variablen (Templating)

### 1. **Neues Dashboard anlegen**
   Erstellen Sie ein neues Dashboard in Grafana mit dem Namen "AirSensors" und fügen Sie mindestens ein Diagramm-Panel hinzu.

### 2. **Variable definieren**
   - Gehen Sie in den Dashboard-Einstellungen auf den Reiter „Variables" (Variablen).
   - Fügen Sie eine neue Variable mit dem Namen "sensor_id".
   - Definieren Sie die Abfrage zum Abrufen der Hostnamen.
     - **FLUX-Abfrage:**
       ```flux
       import "influxdata/influxdb/schema"
       schema.tagValues(bucket: "testdata-web", tag: "sensor_id")
       ```
   - Legen Sie ggf. einen Standardwert fest.
   - Aktivieren Sie die Option "Include All Value" mit dem Custom all Value "All"

### 3. **Dashboard-Panel konfigurieren**
   Ändern Sie die Abfrage des Panels, um die Variable zu nutzen. Beispiel:
   ```flux
    from(bucket: "testdata-web")
    |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
    |> filter(fn: (r) => if "${sensor_id}" == "All" then r["sensor_id"] != "" else  r["sensor_id"] == "${sensor_id}")
    |> filter(fn: (r) => r["_measurement"] == "airSensors")
    |> filter(fn: (r) => r["_field"] == "temperature")
   ```

### 4. **Testen**
   Wählen Sie unterschiedliche Sensor-IDs aus der Variable und beobachten Sie die Änderungen im Dashboard.

### 5. **Weiteres Diagramm einfügen**
   Fügen Sie dem Air Sensor Dashboard weitere Diagramme hinzu, um die Luftfeuchtigkeit und den CO-Wert anzuzeigen.

### 6. **Annotations**
   Fügen Sie dem Air Sensor Dashboard in seinen Einstellungen eine Annotation für die Temperatur hinzu, um einen Anstieg des
   Wertes über 75 °C über alle Diagramme des Sensors angezeigt zu bekommen.

   Prüfen Sie im Anschluss, bei welchem Sensor ein solches Ereignis eingetreten ist.

   ```flux
  from(bucket: "testdata-web")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r._measurement == "airSensors" and r._field == "temperature")
  |> filter(fn: (r) => if "${sensor_id}" == "All" then r["sensor_id"] != "" else  r["sensor_id"] == "${sensor_id}")
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
