# InfluxDB v3 - Aufgabenfeld 4: Backups und Datenexport

> **Wichtige Hinweise:**
> - InfluxDB v3 Core verwendet einen dateibasierten Backup-Ansatz und hat bisher kein eigenes Tool um Konsistente Backups zu erzeugen
> - Die strikte Reihenfolge beim Kopieren der Daten ist unbedingt einzuhalten
> - Der Standard-Datenpfad ist `/var/lib/influxdb3`
> - Backups müssen bei gestopptem Service erstellt werden, um Konsistenz zu gewährleisten

## Vorbereitung

### Schritt 1: InfluxDB v3 Status prüfen

Prüfen Sie zunächst den Status von InfluxDB v3:

```bash
sudo systemctl status influxdb3-core
```

### Schritt 2: Datenpfad identifizieren

Der Standard-Datenpfad für InfluxDB v3 Core ist:
```
/var/lib/influxdb3/
```

Prüfen Sie den Inhalt:
```bash
sudo ls -lah /var/lib/influxdb3/
```

## Teil 1: Filesystem-basiertes Backup erstellen

### Aufgabe 1.1: InfluxDB v3 stoppen

Um ein konsistentes Backup zu erstellen, muss der Service gestoppt werden:

```bash
sudo systemctl stop influxdb3-core
```

Prüfen Sie, ob der Service wirklich gestoppt ist:
```bash
sudo systemctl is-active influxdb3-core
```

**Erwartete Ausgabe:** `inactive`

### Aufgabe 1.2: Backup-Verzeichnis vorbereiten

Erstellen Sie ein Verzeichnis für Ihre Backups:

```bash
sudo mkdir -p /backup/influxdb3
sudo mkdir -p /backup/influxdb3/$(date +%Y-%m-%d_%H)
```
### Aufgabe 1.3: Daten sichern

Kopieren Sie alle Daten aus dem InfluxDB-Verzeichnis:

```bash
BACKUP_DIR="/backup/influxdb3/$(date +%Y-%m-%d_%H)"
sudo cp -r /var/lib/influxdb3/* $BACKUP_DIR/
```

Prüfen Sie das Backup:
```bash
sudo ls -lah $BACKUP_DIR/
sudo du -sh $BACKUP_DIR/
```
### Aufgabe 1.4: InfluxDB v3 wieder starten

```bash
sudo systemctl start influxdb3-core
sudo systemctl status influxdb3-core
```
## Teil 4: Datenwiederherstellung (Restore)

### Aufgabe 4.1: Testdaten erstellen

Bevor wir wiederherstellen, erstellen Sie Testdaten:

```bash
influxdb3 create database test_restore
influxdb3 write \
  --database test_restore \
  "temperature,location=room1 value=23.5 $(date +%s)000000000"
```

Prüfen Sie die Daten:
```bash
influxdb3 query --database test_restore "SELECT * FROM temperature"
```

### Aufgabe 4.2: Backup erstellen

```bash
sudo systemctl stop influxdb3-core
BACKUP_FILE="/backup/influxdb3/before_restore_$(date +%Y-%m-%d_%H-%M).tar.gz"
sudo tar -czf $BACKUP_FILE -C /var/lib influxdb3/
sudo systemctl start influxdb3-core
```

### Aufgabe 4.3: Datenbank löschen (Simulation eines Datenverlusts)

```bash
influxdb3 delete database test_restore
```

Prüfen Sie, ob die Datenbank weg ist:
```bash
influxdb3 query --database test_restore "SELECT * FROM temperature"
```

**Erwartete Ausgabe:** Fehler oder keine Daten

### Aufgabe 4.4: Daten wiederherstellen

```bash
# Service stoppen
sudo systemctl stop influxdb3-core

# Alte Daten sichern (optional, als Sicherheit)
sudo mv /var/lib/influxdb3 /var/lib/influxdb3.old

# Backup entpacken
sudo mkdir -p /var/lib/influxdb3
sudo tar -xzf $BACKUP_FILE -C /var/lib/

# Berechtigungen wiederherstellen
sudo chown -R influxdb3:influxdb3 /var/lib/influxdb3

# Service starten
sudo systemctl start influxdb3-core
```

### Aufgabe 4.5: Wiederherstellung prüfen

```bash
influxdb3 query --database test_restore "SELECT * FROM temperature"
```