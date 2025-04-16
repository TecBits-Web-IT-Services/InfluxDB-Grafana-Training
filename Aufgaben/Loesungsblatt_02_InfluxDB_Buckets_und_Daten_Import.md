# Lösungsblatt: InfluxDB - Buckets und Daten Import

Dieses Lösungsblatt enthält die Lösungen für die Aufgaben aus dem Aufgabenfeld 2: Buckets und Daten Import.

## Aufgabe 1: Bucket über das Webinterface erstellen

### Lösung:
1. Öffnen Sie das InfluxDB Webinterface unter http://localhost:8087
2. Navigieren Sie zum Reiter "Load Data" > "Buckets"
3. Klicken Sie auf den Button "Create Bucket"
4. Geben Sie folgende Informationen ein:
   - Name: `testdata-web`
   - Delete Data: Wählen Sie "Never"
5. Klicken Sie auf "Create"

## Aufgabe 2: Testdaten importieren

### Lösung:
1. Navigieren Sie im Webinterface zu "Load Data" > "Buckets"
2. Klicken Sie auf den Namen des Buckets "testdata-web"
3. Klicken Sie auf "Add Data" > "Upload File"
4. Wählen Sie die Datei "air-sensor-data.lp" aus
5. Klicken Sie auf "Upload"

Alternativ können Sie die Daten auch über die Kommandozeile importieren:
```bash
influx write --bucket testdata-web --format line-protocol --file air-sensor-data.lp
```

## Aufgabe 3: Bucket über die CLI erstellen

### Lösung:
1. Öffnen Sie ein Terminal
2. Führen Sie den folgenden Befehl aus, um die Organisation zu ermitteln:
   ```bash
   influx org list
   ```
3. Notieren Sie sich die ID oder den Namen Ihrer Organisation (z.B. "Test-Organisation")
4. Erstellen Sie das Bucket mit dem folgenden Befehl:
   ```bash
   influx bucket create --name testdata-cli --org "Test-Organisation" --retention 0
   ```
5. Überprüfen Sie, ob das Bucket erstellt wurde:
   ```bash
   influx bucket list
   ```

## Aufgabe 4: Testdaten in das CLI-Bucket importieren

### Lösung:
```bash
influx write --bucket testdata-cli --format csv --file air-sensor-data-annotated.csv
```

## Aufgabe 5: V1 CLI verwenden

### Lösung:
1. Starten Sie die InfluxDB v1 Shell:
   ```bash
   influx v1 shell
   ```
2. Verwenden Sie das CLI-Bucket:
   ```
   use testdata-cli
   ```
3. Zeigen Sie die Messreihen an:
   ```
   show measurements
   ```
4. Zeigen Sie die Felder einer Messreihe an:
   ```
   show field keys from airSensors
   ```
5. Zeigen Sie die Tags einer Messreihe an:
   ```
   show tag keys from airSensors
   ```
6. Zeigen Sie die Tag-Werte für einen bestimmten Tag an:
   ```
   show tag values from airSensors with key = "sensor_id"
   ```
7. Zeigen Sie die Serien an:
   ```
   show series from airSensors
   ```

## Aufgabe 6: Data-Explorer verwenden

### Lösung:
1. Navigieren Sie im Webinterface zu "Data Explorer"
2. Wählen Sie das Bucket "testdata-web" aus
3. Wählen Sie die Messreihe "airSensors"
4. Wählen Sie ein Feld aus (z.B. "temperature")
5. Passen Sie den Zeitraum an, um die Daten zu sehen (z.B. "Past 30d")
6. Experimentieren Sie mit verschiedenen Visualisierungsoptionen:
   - Ändern Sie den Diagrammtyp (z.B. von "Line Graph" zu "Bar Graph")
   - Ändern Sie die Aggregationsfunktion (z.B. von "mean" zu "max")
   - Ändern Sie die Window-Periode (z.B. von "auto" zu "1h")

## Aufgabe 7: InfluxQL verwenden

### Lösung:
1. Starten Sie die InfluxDB v1 Shell:
   ```bash
   influx v1 shell
   ```
2. Verwenden Sie das CLI-Bucket:
   ```
   use testdata-cli
   ```
3. Zeigen Sie alle Werte aus der airSensors Messreihe an:
   ```
   SELECT * FROM airSensors LIMIT 10
   ```
4. Verfeinern Sie die Abfrage, um nur Daten für den Sensor TLM0102 anzuzeigen:
   ```
   SELECT * FROM airSensors WHERE sensor_id = 'TLM0102' LIMIT 10
   ```
5. Optimieren Sie die Abfrage, um nur Temperatur-Werte anzuzeigen:
   ```
   SELECT time, temperature FROM airSensors WHERE sensor_id = 'TLM0102' LIMIT 10
   ```
6. Berechnen Sie den Durchschnittswert der Temperatur:
   ```
   SELECT MEAN(temperature) FROM airSensors WHERE sensor_id = 'TLM0102'
   ```

Der Durchschnittswert der Temperatur für den Sensor TLM0102 beträgt etwa 71.5°C (der genaue Wert kann je nach Datensatz variieren).

## Zusätzliche Tipps

- Wenn Sie Probleme mit der Authentifizierung haben, stellen Sie sicher, dass Ihr Token korrekt gesetzt ist:
  ```bash
  export INFLUX_TOKEN=Ihr_Token_Hier
  ```
- Verwenden Sie `influx --help` oder `influx bucket --help`, um weitere Informationen zu den verfügbaren Befehlen und Optionen zu erhalten.
- Die InfluxDB v1 Shell unterstützt sowohl InfluxQL als auch Flux. Verwenden Sie `token INFLUX_TOKEN` in der v1 Shell, wenn Sie Authentifizierungsprobleme haben.
- Beim Import von CSV-Dateien ist es wichtig, dass die Datei im richtigen Format vorliegt. Die Datei "air-sensor-data-annotated.csv" ist bereits im korrekten Format für InfluxDB.
