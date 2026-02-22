# Lösungsblatt 10– Prometheus Backup und Wiederherstellung

Dieses Lösungsblatt führt Sie durch die erfolgreiche Einrichtung und Durchführung von Prometheus-Backups sowie deren Wiederherstellung.

## 1. Ziel
- Snapshot-API aktiviert und funktionsfähig
- Backup-Skript installiert und getestet
- Erfolgreiche Wiederherstellung aus Backup durchgeführt
- Backup-Monitoring eingerichtet

---

## Übungsaufgaben - Lösungen

### Aufgabe 1: Snapshot-Backup erstellen und wiederherstellen

#### Schritt 1: Admin-API aktivieren

```bash
# Service-Datei bearbeiten
sudo nano /etc/systemd/system/prometheus.service

# Flag hinzufügen: --web.enable-admin-api
# Beispiel:
# ExecStart=/usr/local/bin/prometheus \
#     --config.file /etc/prometheus/prometheus.yml \
#     --storage.tsdb.path /var/lib/prometheus/ \
#     --web.console.templates=/etc/prometheus/consoles \
#     --web.console.libraries=/etc/prometheus/console_libraries \
#     --web.enable-admin-api

# Systemd neu laden und Prometheus neu starten
sudo systemctl daemon-reload
sudo systemctl restart prometheus

# Status prüfen
sudo systemctl status prometheus
```

**Validierung**:
```bash
# API-Endpoint testen
curl -XPOST http://localhost:9090/api/v1/admin/tsdb/snapshot
```

**Erwartete Ausgabe**:
```json
{"status":"success","data":{"name":"20250216T120000Z-1234567890abcdef"}}
```

#### Schritt 2: Snapshot erstellen

```bash
# Snapshot erstellen
RESPONSE=$(curl -s -XPOST http://localhost:9090/api/v1/admin/tsdb/snapshot)
echo $RESPONSE

# Snapshot-Name extrahieren
SNAPSHOT_NAME=$(echo $RESPONSE | jq -r '.data.name')
echo "Snapshot Name: $SNAPSHOT_NAME"

# Snapshot-Verzeichnis prüfen
sudo ls -lh /var/lib/prometheus/snapshots/$SNAPSHOT_NAME/
```

**Erwartete Ausgabe**:
```
total 16K
drwxr-xr-x 5 prometheus prometheus 4.0K Feb 16 12:00 01HQXXXXXXXXXXXXXX
drwxr-xr-x 5 prometheus prometheus 4.0K Feb 16 12:00 01HQYYYYYYYYYYYY
drwxr-xr-x 2 prometheus prometheus 4.0K Feb 16 12:00 chunks_head
-rw-r--r-- 1 prometheus prometheus    0 Feb 16 12:00 wal
```

#### Schritt 3: Snapshot sichern

```bash
# Backup-Verzeichnis erstellen
sudo mkdir -p /backup/prometheus

# Als TAR-Archiv sichern
sudo tar -czf /backup/prometheus/prometheus-snapshot-$(date +%Y%m%d-%H%M%S).tar.gz \
    -C /var/lib/prometheus/snapshots/ $SNAPSHOT_NAME/

# Backup-Größe prüfen
ls -lh /backup/prometheus/

# Snapshot nach Backup löschen (optional)
sudo rm -rf /var/lib/prometheus/snapshots/$SNAPSHOT_NAME
```

#### Schritt 4: Wiederherstellung testen

```bash
# 1. Aktuelle TSDB-Größe notieren
du -sh /var/lib/prometheus/

# 2. Prometheus stoppen
sudo systemctl stop prometheus

# 3. Alte Daten sichern
sudo mv /var/lib/prometheus /var/lib/prometheus.backup-$(date +%Y%m%d-%H%M%S)

# 4. Neues Verzeichnis erstellen
sudo mkdir -p /var/lib/prometheus

# 5. Backup wiederherstellen (neuestes Backup verwenden)
LATEST_BACKUP=$(ls -t /backup/prometheus/prometheus-snapshot-*.tar.gz | head -1)
echo "Restore von: $LATEST_BACKUP"

sudo tar -xzf $LATEST_BACKUP -C /var/lib/prometheus/

# 6. Berechtigungen setzen
sudo chown -R prometheus:prometheus /var/lib/prometheus

# 7. Prometheus starten
sudo systemctl start prometheus

# 8. Status prüfen
sudo systemctl status prometheus

# 9. Logs prüfen
sudo journalctl -u prometheus -n 50 --no-pager | grep -i error

# 10. Prometheus erreichbar?
curl -s http://localhost:9090/api/v1/status/tsdb | jq

# 11. Daten verfügbar?
curl -s 'http://localhost:9090/api/v1/query?query=up' | jq '.data.result[] | {metric: .metric, value: .value}'
```

**Validierung erfolgreich wenn**:
- Prometheus startet ohne Fehler
- `/api/v1/status/tsdb` liefert Daten
- Metriken im Webinterface sichtbar sind
- Keine Fehlermeldungen in den Logs

---

### Aufgabe 2: Automatisches Backup-Skript

#### Schritt 1: Backup-Skript installieren

Das vollständige Skript aus dem Aufgabenfeld kopieren oder verkürzte Version:

```bash
sudo cat > /usr/local/bin/prometheus-backup.sh << 'EOF'
#!/bin/bash
set -e

# Konfiguration
PROMETHEUS_URL="http://localhost:9090"
BACKUP_DIR="/backup/prometheus"
RETENTION_DAYS=30
LOG_PREFIX="[$(date '+%Y-%m-%d %H:%M:%S')]"

# Backup-Verzeichnis erstellen
mkdir -p "$BACKUP_DIR"

echo "$LOG_PREFIX Erstelle Prometheus Snapshot..."
SNAPSHOT_RESPONSE=$(curl -s -XPOST "$PROMETHEUS_URL/api/v1/admin/tsdb/snapshot")
SNAPSHOT_NAME=$(echo "$SNAPSHOT_RESPONSE" | jq -r '.data.name')

if [ "$SNAPSHOT_NAME" == "null" ] || [ -z "$SNAPSHOT_NAME" ]; then
    echo "$LOG_PREFIX FEHLER - Snapshot-Erstellung fehlgeschlagen"
    echo "Response: $SNAPSHOT_RESPONSE"
    exit 1
fi

echo "$LOG_PREFIX Snapshot erstellt: $SNAPSHOT_NAME"

# Backup erstellen
BACKUP_FILE="$BACKUP_DIR/prometheus-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
echo "$LOG_PREFIX Erstelle Backup nach $BACKUP_FILE..."

tar -czf "$BACKUP_FILE" -C /var/lib/prometheus/snapshots/ "$SNAPSHOT_NAME/"

if [ $? -eq 0 ]; then
    echo "$LOG_PREFIX Backup erfolgreich: $BACKUP_FILE"

    # Snapshot löschen
    rm -rf "/var/lib/prometheus/snapshots/$SNAPSHOT_NAME"

    # Alte Backups löschen
    find "$BACKUP_DIR" -name "prometheus-backup-*.tar.gz" -mtime +$RETENTION_DAYS -delete

    echo "$LOG_PREFIX Backup abgeschlossen"
    exit 0
else
    echo "$LOG_PREFIX FEHLER - Backup fehlgeschlagen"
    exit 1
fi
EOF

# Ausführbar machen
sudo chmod +x /usr/local/bin/prometheus-backup.sh

# Berechtigungen prüfen
ls -l /usr/local/bin/prometheus-backup.sh
```

#### Schritt 2: Cron-Job konfigurieren

```bash
# Cron-Job für tägliches Backup um 2 Uhr nachts
(sudo crontab -l 2>/dev/null; echo "0 2 * * * /usr/local/bin/prometheus-backup.sh >> /var/log/prometheus-backup.log 2>&1") | sudo crontab -

# Cron-Jobs anzeigen
sudo crontab -l

# Log-Datei anlegen
sudo touch /var/log/prometheus-backup.log
sudo chmod 644 /var/log/prometheus-backup.log
```

**Alternative Cron-Konfigurationen**:

```bash
# Alle 6 Stunden
0 */6 * * * /usr/local/bin/prometheus-backup.sh >> /var/log/prometheus-backup.log 2>&1

# Täglich um 3 Uhr
0 3 * * * /usr/local/bin/prometheus-backup.sh >> /var/log/prometheus-backup.log 2>&1

# Nur Werktags (Mo-Fr) um 2 Uhr
0 2 * * 1-5 /usr/local/bin/prometheus-backup.sh >> /var/log/prometheus-backup.log 2>&1

# Wöchentlich (Sonntag, 1 Uhr)
0 1 * * 0 /usr/local/bin/prometheus-backup.sh >> /var/log/prometheus-backup.log 2>&1
```

#### Schritt 3: Skript manuell testen

```bash
# Vor dem Test: Vorhandene Backups prüfen
ls -lh /backup/prometheus/

# Skript manuell ausführen
sudo /usr/local/bin/prometheus-backup.sh

# Ausgabe sollte sein:
# [2025-02-16 12:30:00] Erstelle Prometheus Snapshot...
# [2025-02-16 12:30:01] Snapshot erstellt: 20250216T123000Z-...
# [2025-02-16 12:30:01] Erstelle Backup nach /backup/prometheus/prometheus-backup-...
# [2025-02-16 12:30:05] Backup erfolgreich: /backup/prometheus/prometheus-backup-...
# [2025-02-16 12:30:05] Backup abgeschlossen

# Neues Backup prüfen
ls -lh /backup/prometheus/

# Backup-Inhalt prüfen
tar -tzf /backup/prometheus/prometheus-backup-*.tar.gz | head -20
```

#### Schritt 4: Log-Datei prüfen

```bash
# Log-Datei anzeigen
cat /var/log/prometheus-backup.log

# Letzte 20 Zeilen
tail -20 /var/log/prometheus-backup.log

# Live-Monitoring (wenn Cron-Job läuft)
tail -f /var/log/prometheus-backup.log

# Fehler suchen
grep -i fehler /var/log/prometheus-backup.log
grep -i error /var/log/prometheus-backup.log
```

**Validierung erfolgreich wenn**:
- Skript läuft ohne Fehler (Exit Code 0)
- Backup-Datei in `/backup/prometheus/` erstellt wurde
- Backup-Datei nicht leer ist (> 1 MB)
- Log-Datei Erfolgs-Meldung enthält

---

### Aufgabe 3: Backup-Monitoring

#### Schritt 1: Backup-Metrik hinzufügen

**Erweiterte Version des Backup-Skripts mit Metriken**:

```bash
# Am Ende des Skripts hinzufügen
sudo cat >> /usr/local/bin/prometheus-backup.sh << 'EOF'

# Metrik für Node Exporter Textfile Collector
TEXTFILE_DIR="/var/lib/node_exporter/textfile_collector"
if [ -d "$TEXTFILE_DIR" ]; then
    TEMP_FILE="$TEXTFILE_DIR/prometheus_backup.prom.$$"
    PROM_FILE="$TEXTFILE_DIR/prometheus_backup.prom"

    {
        echo "# HELP prometheus_backup_last_success_timestamp_seconds Last successful backup timestamp"
        echo "# TYPE prometheus_backup_last_success_timestamp_seconds gauge"
        echo "prometheus_backup_last_success_timestamp_seconds $(date +%s)"

        echo "# HELP prometheus_backup_last_duration_seconds Duration of last backup in seconds"
        echo "# TYPE prometheus_backup_last_duration_seconds gauge"
        echo "prometheus_backup_last_duration_seconds $SECONDS"

        echo "# HELP prometheus_backup_size_bytes Size of last backup in bytes"
        echo "# TYPE prometheus_backup_size_bytes gauge"
        BACKUP_SIZE=$(stat -f%z "$BACKUP_FILE" 2>/dev/null || stat -c%s "$BACKUP_FILE")
        echo "prometheus_backup_size_bytes $BACKUP_SIZE"
    } > "$TEMP_FILE"

    mv "$TEMP_FILE" "$PROM_FILE"
    echo "$LOG_PREFIX Backup-Metriken aktualisiert"
fi
EOF
```

**Backup erneut ausführen um Metriken zu generieren**:

```bash
sudo /usr/local/bin/prometheus-backup.sh

# Metriken prüfen
cat /var/lib/node_exporter/textfile_collector/prometheus_backup.prom
```

**In Prometheus prüfen** (nach 1-2 Minuten):

```promql
# Letzte erfolgreiche Backup-Zeit
prometheus_backup_last_success_timestamp_seconds

# Wie lange her?
(time() - prometheus_backup_last_success_timestamp_seconds) / 3600

# Dauer des letzten Backups in Sekunden
prometheus_backup_last_duration_seconds

# Größe des letzten Backups in MB
prometheus_backup_size_bytes / 1024 / 1024
```

#### Schritt 2: Alert für fehlgeschlagene Backups erstellen

```bash
# Alert-Regel erstellen
sudo cat > /etc/prometheus/rules/backup_alerts.yml << 'EOF'
groups:
  - name: backup_alerts
    interval: 1m
    rules:

    # Alert wenn Backup älter als 24 Stunden
    - alert: PrometheusBackupMissing
      expr: (time() - prometheus_backup_last_success_timestamp_seconds) > 86400
      for: 1h
      labels:
        severity: warning
      annotations:
        summary: "Prometheus Backup fehlt (instance {{ $labels.instance }})"
        description: |
          Letztes erfolgreiches Backup ist {{ $value | humanizeDuration }} alt.
          Erwartete Frequenz: 24 Stunden.

    # Alert wenn Backup zu langsam
    - alert: PrometheusBackupTooSlow
      expr: prometheus_backup_last_duration_seconds > 1800
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "Prometheus Backup zu langsam (instance {{ $labels.instance }})"
        description: |
          Letztes Backup dauerte {{ $value | humanizeDuration }}.
          Normal: < 30 Minuten.

    # Alert wenn Backup-Größe dramatisch abweicht
    - alert: PrometheusBackupSizeChanged
      expr: |
        abs(
          (prometheus_backup_size_bytes - prometheus_backup_size_bytes offset 24h)
          / prometheus_backup_size_bytes offset 24h
        ) > 0.5
      for: 10m
      labels:
        severity: info
      annotations:
        summary: "Prometheus Backup-Größe verändert (instance {{ $labels.instance }})"
        description: |
          Backup-Größe hat sich um {{ $value | humanizePercentage }} verändert.
          Aktuelle Größe: {{ query "prometheus_backup_size_bytes / 1024 / 1024" | first | value | humanize }} MB
EOF

# Berechtigungen setzen
sudo chown prometheus:prometheus /etc/prometheus/rules/backup_alerts.yml

# Regel validieren
promtool check rules /etc/prometheus/rules/backup_alerts.yml

# Prometheus neu laden
sudo systemctl reload prometheus

# Alert-Regeln prüfen
curl -s http://localhost:9090/api/v1/rules | jq '.data.groups[] | select(.name=="backup_alerts")'
```

#### Schritt 3: Alert testen (fehlgeschlagenes Backup simulieren)

**Methode 1: Alte Timestamp setzen**

```bash
# Backup-Metrik manuell auf alten Zeitstempel setzen
sudo cat > /var/lib/node_exporter/textfile_collector/prometheus_backup.prom << EOF
# HELP prometheus_backup_last_success_timestamp_seconds Last successful backup timestamp
# TYPE prometheus_backup_last_success_timestamp_seconds gauge
prometheus_backup_last_success_timestamp_seconds $(date -d "2 days ago" +%s)

# HELP prometheus_backup_last_duration_seconds Duration of last backup in seconds
# TYPE prometheus_backup_last_duration_seconds gauge
prometheus_backup_last_duration_seconds 120
EOF

# Nach 1-2 Minuten in Prometheus prüfen:
# http://localhost:9090/alerts
# Alert "PrometheusBackupMissing" sollte nach 1 Stunde FIRING sein
```

**Methode 2: Snapshot-API vorübergehend deaktivieren**

```bash
# Prometheus-Config bearbeiten und --web.enable-admin-api entfernen
sudo nano /etc/systemd/system/prometheus.service

# Prometheus neu starten
sudo systemctl daemon-reload
sudo systemctl restart prometheus

# Backup-Skript ausführen (wird fehlschlagen)
sudo /usr/local/bin/prometheus-backup.sh

# Log prüfen
tail -20 /var/log/prometheus-backup.log

# Admin-API wieder aktivieren
# (Flag wieder hinzufügen und Prometheus neu starten)
```

**Alert-Status überwachen**:

```bash
# Alerts im Webinterface prüfen
# http://localhost:9090/alerts

# Via API prüfen
curl -s http://localhost:9090/api/v1/alerts | jq '.data.alerts[] | select(.labels.alertname=="PrometheusBackupMissing")'

# Alert-Status
curl -s http://localhost:9090/api/v1/alerts | jq '.data.alerts[] | {alert: .labels.alertname, state: .state, value: .value}'
```

**Validierung erfolgreich wenn**:
- Alert "PrometheusBackupMissing" wird FIRING
- E-Mail-Benachrichtigung wird empfangen (wenn Alertmanager konfiguriert)
- Alert erscheint in Prometheus UI unter "Alerts"

---

## Troubleshooting-Szenarien und Lösungen

### Problem 1: Snapshot-API gibt 404

**Symptom**:
```bash
curl -XPOST http://localhost:9090/api/v1/admin/tsdb/snapshot
# {"status":"error","errorType":"not_found","error":"not found"}
```

**Lösung**:
```bash
# 1. Prüfen ob Flag gesetzt ist
grep "web.enable-admin-api" /etc/systemd/system/prometheus.service

# 2. Flag hinzufügen falls fehlt
sudo nano /etc/systemd/system/prometheus.service

# 3. Prometheus neu starten
sudo systemctl daemon-reload
sudo systemctl restart prometheus
```

### Problem 2: Backup-Skript gibt "jq: command not found"

**Lösung**:
```bash
# jq installieren
sudo apt-get update
sudo apt-get install -y jq

# Skript erneut ausführen
sudo /usr/local/bin/prometheus-backup.sh
```

### Problem 3: Restore schlägt fehl mit "permission denied"

**Lösung**:
```bash
# Berechtigungen prüfen
ls -la /var/lib/prometheus/

# Berechtigungen korrigieren
sudo chown -R prometheus:prometheus /var/lib/prometheus
sudo chmod -R 755 /var/lib/prometheus

# SELinux prüfen (falls aktiviert)
sudo setenforce 0  # Temporär deaktivieren
sudo getenforce    # Status prüfen

# Prometheus neu starten
sudo systemctl restart prometheus
```

### Problem 4: Backup-Metrik wird nicht in Prometheus angezeigt

**Diagnose**:
```bash
# 1. Metrik-Datei existiert?
ls -la /var/lib/node_exporter/textfile_collector/prometheus_backup.prom

# 2. Inhalt korrekt?
cat /var/lib/node_exporter/textfile_collector/prometheus_backup.prom

# 3. Node Exporter läuft?
systemctl status node_exporter

# 4. Textfile Collector aktiviert?
ps aux | grep node_exporter | grep textfile
```

**Lösung**:
```bash
# Node Exporter mit Textfile Collector neu starten
sudo nano /etc/systemd/system/node_exporter.service

# Stelle sicher dass Flag gesetzt ist:
# ExecStart=/usr/local/bin/node_exporter --collector.textfile.directory=/var/lib/node_exporter/textfile_collector

sudo systemctl daemon-reload
sudo systemctl restart node_exporter
```

---

## Zusätzliche Best Practices

### 1. Backup-Verschlüsselung

```bash
# Backup mit GPG verschlüsseln
sudo tar -czf - -C /var/lib/prometheus/snapshots/ $SNAPSHOT_NAME/ | \
    gpg --symmetric --cipher-algo AES256 -o /backup/prometheus/backup-$(date +%Y%m%d).tar.gz.gpg

# Entschlüsseln
gpg --decrypt /backup/prometheus/backup-20250216.tar.gz.gpg | \
    sudo tar -xzf - -C /var/lib/prometheus/
```

### 2. Backup nach S3/Object Storage

```bash
# AWS CLI installieren
sudo apt-get install -y awscli

# Backup nach S3 hochladen
aws s3 cp /backup/prometheus/prometheus-backup-$(date +%Y%m%d).tar.gz \
    s3://mein-bucket/prometheus-backups/
```

### 3. Backup-Retention mit Logrotate

```bash
# Logrotate-Config für Backup-Logs
sudo cat > /etc/logrotate.d/prometheus-backup << 'EOF'
/var/log/prometheus-backup.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 0644 root root
}
EOF
```

---

## Zusammenfassung

Erfolgreiche Backup-Strategie umfasst:

1. ✅ **Automatisierte Snapshots** via Cron
2. ✅ **Regelmäßige Restore-Tests** (mindestens monatlich)
3. ✅ **Off-Site Backups** (Cloud, Remote-Server)
4. ✅ **Monitoring** mit Alerts für fehlgeschlagene Backups
5. ✅ **Dokumentation** des Restore-Prozesses
6. ✅ **Retention-Policy** (z.B. 30 Tage)
7. ✅ **Backup-Verschlüsselung** für sensitive Daten

**Nächste Schritte**:
- Backup nach Remote-Storage konfigurieren
- Disaster Recovery Plan dokumentieren
- Restore-Prozedur mit Team üben
