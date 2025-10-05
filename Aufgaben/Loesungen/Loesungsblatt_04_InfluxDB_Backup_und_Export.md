# Lösungsblatt 04 – InfluxDB Backup und Export

Dieses Lösungsblatt beschreibt die Erstellung von Backups, das Wiederherstellen und den Export von Daten.

## 1. Ziel
- Vollständiges Backup erstellt und validiert
- Wiederherstellung auf Testinstanz möglich
- CSV/Parquet-Export exemplarisch durchgeführt

## 2. Backup erstellen (CLI)
- Online-Backup (OSS 2.x):
  ```bash
  influx backup /var/backups/influxdb/$(date +%F)
  ```
- Erwartung: Ordner mit Manifest- und Shard-Dateien vorhanden

## 3. Backup validieren
- Größe/Dateien prüfen: `ls -lah /var/backups/influxdb/<datum>`
- Optional Hash/Checksum prüfen (je nach Umgebung)

## 4. Restore durchführen (auf Testsystem)
- Dienst stoppen: `systemctl stop influxdb`
- Restore:
  ```bash
  influx restore /var/backups/influxdb/<datum>
  ```
- Dienst starten: `systemctl start influxdb`
- Prüfung via UI/CLI: Buckets/Daten vorhanden?

## 5. Export Beispiel (CSV)
- Query-Export:
  ```bash
  influx query 'from(bucket: "training") |> range(start: -1h)'
    --raw --csv > export.csv
  ```
- Erwartung: export.csv enthält Zeitreihenwerte

## 6. Troubleshooting
- Ausreichende Rechte/Platz für Backup-Pfad?
- Restore-Reihenfolge und Versionen kompatibel halten
- Dienste sauber stoppen/gestartet
