# Lösungsblatt 08 – Grafana Setup mit InfluxDB

Dieses Lösungsblatt beschreibt das Anlegen der InfluxDB-Datenquelle in Grafana und die Validierung über ein Beispiel-Panel.

## 1. Ziel
- Datenquelle „InfluxDB“ ist angelegt und erfolgreich getestet
- Ein Beispiel-Dashboard zeigt Daten aus dem Bucket

## 2. Datenquelle hinzufügen
- Grafana → Connections → Data sources → Add data source → InfluxDB
- URL: `http://localhost:8086`
- Authentifizierung: Token (Organization/Bucket passend zur Aufgabe)
- Query Language: Flux
- Save & Test → „Data source is working“ erwartet

## 3. Beispiel-Panel (Temperatur)
- Neues Dashboard → Add panel → Data source: InfluxDB
- Abfrage (Flux):
  ```flux
  from(bucket: "training")
    |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
    |> filter(fn: (r) => r._measurement == "airSensors" and r._field == "temperature")
  ```
- Visualisation: Time series, Einheit °C (optional)

## 4. Validierung
- Zeitbereich variieren (Last 1h/24h)
- Serie sichtbar ohne Fehler

## 5. Troubleshooting
- Token/Org/Bucket korrekt?
- InfluxDB erreichbar (Port 8086)?
- In Flux-Query Measurement/Field/Tags exakt geschrieben
