# Lösungsblatt 02 – InfluxDB Buckets und Daten

Dieses Lösungsblatt liefert Ihnen Musterlösungen für das Anlegen von Buckets, Schreiben von Daten und Abfragen mit Flux.

## 1. Ziel
- Neuer Bucket (z. B. „training“) ist erstellt
- Daten wurden erfolgreich geschrieben und via Flux gelesen

## 2. Bucket anlegen (UI oder CLI)
- UI: Load Data → Buckets → Create Bucket (Name: „training“, Retention nach Vorgabe)
- CLI: `influx bucket create --name training --retention 7d`

## 3. Daten schreiben
- Line Protocol (CLI):  
  `influx write --bucket training "airSensors,sensor_id=TLM010 temperature=21.5,humidity=47.2,co=378i"`
- CSV (Beispiel):  
  `influx write --bucket training --format csv --file ./daten.csv`

## 4. Basis-Abfragen (Flux)
- Letzte Werte eines Sensors:
  ```flux
  from(bucket: "training")
    |> range(start: -1h)
    |> filter(fn: (r) => r._measurement == "airSensors")
    |> filter(fn: (r) => r.sensor_id == "TLM010")
    |> last()
  ```
- Temperaturverlauf aller Sensoren:
  ```flux
  from(bucket: "training")
    |> range(start: -24h)
    |> filter(fn: (r) => r._measurement == "airSensors" and r._field == "temperature")
  ```
- Aggregation (Durchschnitt pro 5m):
  ```flux
  from(bucket: "training")
    |> range(start: -6h)
    |> filter(fn: (r) => r._measurement == "airSensors" and r._field == "humidity")
    |> aggregateWindow(every: 5m, fn: mean, createEmpty: false)
  ```

## 5. Prüfung
- Es erscheinen Messwerte im UI (Data Explorer) und in Grafana (falls verbunden)
- `influx query` liefert Fehlerfrei Ergebnisse

## 6. Troubleshooting
- Schreibfehler: Token/Bucket/Org prüfen
- Zeitbereich in Abfragen korrekt?
- Line Protocol korrekt (Measurement, Tags, Fields)?
