# Lösungsblatt 10 – Grafana Dynamische Dashboards (InfluxDB)

Dieses Lösungsblatt zeigt Musterlösungen für Variablen (Templating) und die Verwendung in Flux-Queries, inkl. Annotation-Beispiel.

## 1. Ziel
- Dashboard „AirSensors“ mit Variable `sensor_id`
- Panels filtern dynamisch anhand der Variable
- Annotation bei Temperatur > 75°C

## 2. Variable `sensor_id` (Query/InfluxDB)
- Dashboard → Settings → Variables → Add variable
- Name: `sensor_id`
- Type: Query
- Data source: InfluxDB
- Query (Flux):
  ```flux
  import "influxdata/influxdb/schema"
  schema.tagValues(bucket: "testdata-web", tag: "sensor_id")
  ```
- Include All option: aktiviert, Custom all value: `All`

## 3. Panel-Query (Temperatur)
- Nutzen Sie die Variable im Filter (Flux):
  ```flux
  from(bucket: "testdata-web")
    |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
    |> filter(fn: (r) => if "${sensor_id}" == "All" then r["sensor_id"] != "" else  r["sensor_id"] == "${sensor_id}")
    |> filter(fn: (r) => r["_measurement"] == "airSensors")
    |> filter(fn: (r) => r["_field"] == "temperature")
  ```
- Erwartung: Bei Wechsel von `sensor_id` passt sich die Zeitreihe an.

## 4. Weitere Panels
- Luftfeuchtigkeit (analog, `_field == "humidity"`)
- CO-Wert (analog, `_field == "co"`)

## 5. Annotation „Temperatur > 75°C“
- Dashboard → Settings → Annotations → New
- Data source: InfluxDB
- Query (Flux):
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

## 6. Validierung
- Variable durchprobieren (inkl. All)
- Annotationen erscheinen nur bei Überschreitungen

## 7. Troubleshooting
- Variable: exakte Schreibweise „sensor_id“
- Bucket-Name korrekt? (testdata-web)
- Feldnamen/Measurement exakt
