# InfluxDB v3 - Aufgabenfeld 2a : Databases und Daten Import

> **Hinweis:** In InfluxDB v3 werden "Databases" anstelle von "Buckets" verwendet. Die Konzepte sind ähnlich, aber die Implementierung ist unterschiedlich.

### 1. Erstellen Sie eine Database **"airSensorData"** über die CLI mit Standardeinstellungen

> Hinweise:
>
> - Verwenden Sie den Befehl `influxdb3 create`
> - Bei Bedarf verwenden Sie die Hilfe (`--help`), um die benötigten Parameter zu bestimmen
> - In v3 gibt es keine explizite Retention-Policy mehr beim Erstellen; dies wird über separate Policies konfiguriert

```bash
# Database erstellen
influxdb3 create databases "airSensorData"

# Databases auflisten
influxdb3 show database
```

### 2. Importieren Sie Testdaten in die airSensorData Database mit Line Protocol

> Hinweise:
>
> - Line Protocol ist weiterhin das bevorzugte Format für den Import
> - Verwenden Sie den Befehl `influxdb3 write`

```bash
# Beispiel: Schreiben von Sensor-Daten
influxdb3 write \
  --database "airSensorData" \
  "air_sensors,sensor_id=TLM0200 temperature=73.61338409992003,humidity=35.829379977198485,co=0.5713235999022015 1771760343748000000"

# Schreiben mehrerer Datenpunkte
cat << EOF | influxdb3 write --database "airSensorData"
air_sensors,sensor_id=TLM0101 temperature=71.72621302502489,humidity=34.94330822732546,co=0.5143906471208857 1771760363748000000
air_sensors,sensor_id=TLM0102 temperature=71.89152901695674,humidity=35.02850521472139,co=0.5172139015270336 1771760363748000000
air_sensors,sensor_id=TLM0103 temperature=71.39281161277043,humidity=35.22458033756966,co=0.416955300882246 1771760363748000000
air_sensors,sensor_id=TLM0200 temperature=73.58280750071515,humidity=35.891365249988596,co=0.5544757979325563 1771760363748000000
air_sensors,sensor_id=TLM0201 temperature=74.00542446984389,humidity=35.18768642571245,co=0.5234849974305352 1771760363748000000
air_sensors,sensor_id=TLM0202 temperature=75.33683407140636,humidity=35.690230929704526,co=0.5086515548001997 1771760363748000000
air_sensors,sensor_id=TLM0203 temperature=74.79374303918978,humidity=35.93156127951677,co=0.37218416799310905 1771760363748000000
EOF

# Schreiben einer Line Protokoll-Datei
influxdb3 write --database "airSensorData" --file influxdb3 write --database "airSensorData" --file /home/student/Schreibstisch/Workspace/InfluxDB-Grafana-Training/Testdaten/air-sensor-data.lp
```

### 3. Verwenden Sie SQL-Abfragen, um die importierten Daten anzuzeigen

> **Wichtig:** InfluxDB v3 verwendet primär SQL statt Flux!

```bash
# Alle Daten aus der Measurement anzeigen
influxdb3 query \
  --database "airSensorData" \
  "SELECT * FROM air_sensors LIMIT 10"

# Felder und Tags auflisten
influxdb3 query \
  --database "airSensorData" \
  "SHOW FIELDS FROM air_sensors"

# Nur bestimmte Felder abfragen
influxdb3 query \
  --database "airSensorData" \
  "SELECT time, sensor_id, temperature FROM air_sensors"
```

### 4. Verwenden Sie InfluxQL-Abfragen zur Datenanalyse

> Hinweis: InfluxDB v3 unterstützt nativ InfluxQL (nicht nur als Kompatibilitätsschicht wie v2)

```bash
# Alle Daten für einen bestimmten Sensor
influxdb3 query \
  --database "airSensorData" \
  --language influxql \
  "SELECT * FROM air_sensors WHERE sensor_id = 'TLM0102'"

# Durchschnittswerte berechnen
influxdb3 query \
  --database "airSensorData" \
  --language influxql \
  "SELECT MEAN(temperature) FROM air_sensors WHERE sensor_id = 'TLM0102'"

# Daten gruppiert nach Zeit
influxdb3 query \
  --database "airSensorData" \
  --language influxql \
  "SELECT MEAN(temperature) FROM air_sensors GROUP BY time(1h), sensor_id"
```

### 5. Verwenden Sie SQL für erweiterte Abfragen

> SQL ist in v3 die primäre Abfragesprache und bietet alle Standard-SQL-Funktionen

```bash
# Durchschnittstemperatur pro Sensor
influxdb3 query \
  --database "airSensorData" \
  "SELECT sensor_id, AVG(temperature) as avg_temp
   FROM air_sensors
   GROUP BY sensor_id
   ORDER BY avg_temp DESC"

# Temperaturen über einem Schwellwert
influxdb3 query \
  --database "airSensorData" \
  "SELECT time, sensor_id, temperature
   FROM air_sensors
   WHERE temperature > 22.0
   ORDER BY time DESC"

# Joins und komplexe Abfragen (SQL-Funktionen)
influxdb3 query \
  --database "airSensorData" \
  "SELECT
     sensor_id,
     COUNT(*) as measurement_count,
     MIN(temperature) as min_temp,
     MAX(temperature) as max_temp,
     AVG(temperature) as avg_temp,
     STDDEV(temperature) as stddev_temp
   FROM air_sensors
   GROUP BY sensor_id"
```

### 6. Erstellen Sie eine zweite Database und konfigurieren Sie eine Retention-Policy

> Hinweis:
>
> Die Data Retention Policy legt fest, wie lange Daten in der Datenbank gespeichert werden sollen. InfluxDB3 verwendet eine andere Konfiguration als InfluxDB2. Hier wird die Retention Policy direkt beim erstellen der Datenbank konfiguriert.
> In der Core Version kann diese NICHT mehr geändert werden. 

```bash
# Neue Database erstellen mit 30 Tag-Datenaufbewahrung
influxdb3 create database --retention-period 30d "airSensorData-retention"

# Neue Database erstellen ohne befristung der Datenaufbewahrung
influxdb3 create database --retention-period none "airSensorData-retention-none"
```

### 7. Nutzen Sie die HTTP API, um Daten zu schreiben

```bash
# Prüfen ob Server Erreichbar ist
curl "http://localhost:8181/health" \
   --header "Authorization: Bearer $INFLUXDB3_AUTH_TOKEN"

# Schreiben über die v3 HTTP API
curl -X POST "http://localhost:8181/api/v3/write?db=airSensorData" \
  -H "Authorization: Bearer $INFLUXDB3_AUTH_TOKEN" \
  -H "Content-Type: text/plain" \
  --data-binary "air_sensors,sensor_id=TLM0102 temperature=71.89152901695674,humidity=35.02850521472139,co=0.5172139015270336 1771760363748000000"

# Abfragen über die HTTP API
curl -G "http://localhost:8181/api/v3/query_sql" \
  -H "Authorization: Bearer $INFLUXDB3_AUTH_TOKEN" \
  --data-urlencode "db=airSensorData" \
  --data-urlencode "q=SELECT * FROM 'air_sensors' LIMIT 5" \
  --data-urlencode "format=jsonl"
```
