# Lösungsblatt: InfluxDB - Backups und Datenexport

Dieses Lösungsblatt enthält die Lösungen für die Aufgaben aus dem Aufgabenfeld 4: Backups und Datenexport.

## Aufgabe 1: Erstellen eines kompletten Backups der InfluxDB-Datenbank

### Lösung:

1. Stellen Sie sicher, dass der Operator-Token aus der ersten Übung im System hinterlegt ist:
   ```bash
   export INFLUX_TOKEN=Ihr_Operator_Token_Hier
   ```

2. Erstellen Sie ein Verzeichnis für das Backup:
   ```bash
   mkdir -p ~/influxdb_backup
   ```

3. Führen Sie den Backup-Befehl aus:
   ```bash
   influx backup ~/influxdb_backup/influxdb_backup.gz
   ```

4. Überprüfen Sie, ob das Backup erstellt wurde:
   ```bash
   ls -la ~/influxdb_backup/
   ```

## Aufgabe 2: Löschen eines Buckets und Verifizierung

### Lösung:

1. Listen Sie die vorhandenen Buckets auf, um eines zum Löschen auszuwählen:
   ```bash
   influx bucket list
   ```

2. Notieren Sie die ID des zu löschenden Buckets (z.B. "testdata-cli")

3. Löschen Sie das ausgewählte Bucket:
   ```bash
   influx bucket delete --id Bucket_ID
   ```
   
   Alternativ können Sie auch den Namen verwenden:
   ```bash
   influx bucket delete --name testdata-cli --org "Test-Organisation"
   ```

4. Verifizieren Sie, dass das Bucket nicht mehr vorhanden ist:
   ```bash
   influx bucket list
   ```

## Aufgabe 3: Wiederherstellen des gelöschten Buckets aus dem Backup

### Lösung:

1. Stellen Sie das gelöschte Bucket aus dem Backup wieder her:
   ```bash
   influx restore --bucket testdata-cli ~/influxdb_backup/influxdb_backup.gz
   ```

2. Überprüfen Sie, ob das Bucket wiederhergestellt wurde:
   ```bash
   influx bucket list
   ```

3. Verifizieren Sie, dass die Daten im wiederhergestellten Bucket vorhanden sind:
   ```bash
   influx query 'from(bucket: "testdata-cli") |> range(start: -30d) |> limit(n: 5)'
   ```

## Aufgabe 4: CSV-Export der Temperatur-Werte des Sensors TLM0102

### Lösung:

1. Erstellen Sie eine Flux-Abfrage für die Temperatur-Werte des Sensors TLM0102:
   ```bash
   influx query --raw 'from(bucket: "testdata-cli")
     |> range(start: -30d)
     |> filter(fn: (r) => r._measurement == "airSensors")
     |> filter(fn: (r) => r._field == "temperature")
     |> filter(fn: (r) => r.sensor_id == "TLM0102")' > temperature_export.csv
   ```

2. Überprüfen Sie den Inhalt der exportierten CSV-Datei:
   ```bash
   head temperature_export.csv
   ```

3. Alternativ können Sie die Abfrage zuerst im Data Explorer testen:
   - Navigieren Sie zum Data Explorer im Webinterface
   - Wählen Sie das Bucket "testdata-cli"
   - Erstellen Sie folgende Abfrage:
     ```flux
     from(bucket: "testdata-cli")
       |> range(start: -30d)
       |> filter(fn: (r) => r._measurement == "airSensors")
       |> filter(fn: (r) => r._field == "temperature")
       |> filter(fn: (r) => r.sensor_id == "TLM0102")
     ```
   - Kopieren Sie die Abfrage und passen Sie sie für die Kommandozeile an

## Zusätzliche Hinweise

- Backups sollten regelmäßig erstellt und an einem sicheren Ort gespeichert werden
- Die Backup-Datei enthält alle Daten, Metadaten, Benutzer und Berechtigungen der InfluxDB-Instanz
- Mit dem Parameter `--org` können Sie das Backup auf eine bestimmte Organisation beschränken
- Mit dem Parameter `--bucket` können Sie das Backup auf bestimmte Buckets beschränken
- Bei der Wiederherstellung können Sie mit `--full` die gesamte Instanz wiederherstellen
- Für große Datenmengen kann der CSV-Export lange dauern, daher ist es sinnvoll, den Zeitraum einzuschränken
- Die exportierten CSV-Dateien können mit anderen Tools wie Excel oder Python weiterverarbeitet werden
- Für automatisierte Backups können Sie Cron-Jobs verwenden
