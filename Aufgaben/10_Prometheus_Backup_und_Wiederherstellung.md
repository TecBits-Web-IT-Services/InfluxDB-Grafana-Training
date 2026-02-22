# Prometheus - Aufgabenfeld 10: Backup und Wiederherstellung

## Sicherung und Wiederherstellung von Prometheus-Daten

### Voraussetzungen
- Abgeschlossene Aufgabenfelder 5, 6 (Prometheus Setup und Node Exporter)
- Prometheus sammelt aktiv Metriken

### Warum Prometheus-Backups?

Prometheus speichert alle Metriken lokal in der Time Series Database (TSDB). Obwohl Prometheus für kurzfristige Metriken konzipiert ist, gibt es Szenarien, in denen Backups wichtig sind:

1. **Disaster Recovery**: Server-Ausfall oder Datenverlust
2. **Migration**: Umzug auf neue Hardware
3. **Compliance**: Langzeit-Aufbewahrung für Audits
4. **Testing**: Restore von Produktionsdaten in Test-Umgebung
5. **Forensik**: Analyse historischer Incidents

---

## 1. Prometheus TSDB-Struktur verstehen

Prometheus speichert Daten in `/var/lib/prometheus/`:

```bash
# Struktur der TSDB anzeigen
sudo ls -lh /var/lib/prometheus/

# Typische Verzeichnisstruktur:
# /var/lib/prometheus/
# ├── 01HQXXXXXXXXXXXXXX/  # Block (2 Stunden Daten)
# │   ├── chunks/
# │   ├── index
# │   └── meta.json
# ├── 01HQYYYYYYYYYYYY/  # Weiterer Block
# ├── wal/                # Write-Ahead Log
# └── queries.active
```

**Wichtige Konzepte**:
- **Blocks**: Prometheus speichert Daten in 2-Stunden-Blöcken
- **WAL (Write-Ahead Log)**: Neueste, noch nicht komprimierte Daten
- **Chunks**: Komprimierte Metrik-Daten
- **Index**: Ermöglicht schnelles Suchen

### TSDB-Status prüfen

```bash
# Größe der TSDB
sudo du -sh /var/lib/prometheus/

# Anzahl der Time Series
curl -s http://localhost:9090/api/v1/status/tsdb | jq

# TSDB-Statistiken im Webinterface
# http://localhost:9090/tsdb-status
```

---

## 2. Snapshot-basiertes Backup (Empfohlene Methode)

Prometheus bietet eine eingebaute Snapshot-Funktion, die konsistente Backups erstellt.

### 2.1 Snapshot-API aktivieren

Standardmäßig ist die Snapshot-API aus Sicherheitsgründen deaktiviert. Aktivieren Sie sie:

```bash
# Bearbeiten der Prometheus-Systemd-Service-Datei
sudo nano /etc/systemd/system/prometheus.service
```

Fügen Sie das Flag `--web.enable-admin-api` hinzu:

```ini
[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file /etc/prometheus/prometheus.yml \
    --storage.tsdb.path /var/lib/prometheus/ \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries \
    --web.enable-admin-api
```

Prometheus neu starten:

```bash
# Systemd neu laden
sudo systemctl daemon-reload

# Prometheus neu starten
sudo systemctl restart prometheus

# Status prüfen
sudo systemctl status prometheus
```

> ⚠️ **Sicherheitshinweis**: Die Admin-API ermöglicht das Löschen von Daten. Aktivieren Sie sie nur in sicheren Umgebungen oder schützen Sie den Zugriff mit einem Reverse-Proxy.

### 2.2 Snapshot erstellen

```bash
# Snapshot über API erstellen
curl -XPOST http://localhost:9090/api/v1/admin/tsdb/snapshot

# Ausgabe (Beispiel):
# {"status":"success","data":{"name":"20250216T120000Z-1234567890abcdef"}}
```

Der Snapshot wird in `/var/lib/prometheus/snapshots/` gespeichert:

```bash
# Snapshots anzeigen
sudo ls -lh /var/lib/prometheus/snapshots/

# Beispiel:
# drwxr-xr-x 2 prometheus prometheus 4.0K Feb 16 12:00 20250216T120000Z-1234567890abcdef
```

### 2.3 Snapshot sichern

```bash
# Snapshot-Name aus der API-Antwort verwenden
SNAPSHOT_NAME="20250216T120000Z-1234567890abcdef"

# Backup-Verzeichnis erstellen
sudo mkdir -p /backup/prometheus

# Snapshot kopieren (mit rsync für Effizienz)
sudo rsync -av /var/lib/prometheus/snapshots/$SNAPSHOT_NAME/ \
    /backup/prometheus/snapshot-$(date +%Y%m%d-%H%M%S)/

# Oder als TAR-Archiv
sudo tar -czf /backup/prometheus/prometheus-snapshot-$(date +%Y%m%d-%H%M%S).tar.gz \
    -C /var/lib/prometheus/snapshots/ $SNAPSHOT_NAME/

# Snapshot nach dem Backup löschen (optional, spart Speicher)
sudo rm -rf /var/lib/prometheus/snapshots/$SNAPSHOT_NAME
```

### 2.4 Automatisiertes Backup-Skript

Erstellen Sie ein Skript für regelmäßige Backups:

```bash
# Backup-Skript erstellen
sudo cat > /usr/local/bin/prometheus-backup.sh << 'EOF'
#!/bin/bash

# Konfiguration
PROMETHEUS_URL="http://localhost:9090"
BACKUP_DIR="/backup/prometheus"
RETENTION_DAYS=30

# Verzeichnis erstellen
mkdir -p "$BACKUP_DIR"

# Snapshot erstellen
echo "$(date): Erstelle Prometheus Snapshot..."
SNAPSHOT_RESPONSE=$(curl -s -XPOST "$PROMETHEUS_URL/api/v1/admin/tsdb/snapshot")
SNAPSHOT_NAME=$(echo "$SNAPSHOT_RESPONSE" | jq -r '.data.name')

if [ "$SNAPSHOT_NAME" == "null" ] || [ -z "$SNAPSHOT_NAME" ]; then
    echo "$(date): FEHLER - Snapshot-Erstellung fehlgeschlagen"
    echo "Response: $SNAPSHOT_RESPONSE"
    exit 1
fi

echo "$(date): Snapshot erstellt: $SNAPSHOT_NAME"

# Backup erstellen
BACKUP_FILE="$BACKUP_DIR/prometheus-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
echo "$(date): Erstelle Backup nach $BACKUP_FILE..."

tar -czf "$BACKUP_FILE" -C /var/lib/prometheus/snapshots/ "$SNAPSHOT_NAME/"

if [ $? -eq 0 ]; then
    echo "$(date): Backup erfolgreich erstellt: $BACKUP_FILE"

    # Snapshot löschen
    rm -rf "/var/lib/prometheus/snapshots/$SNAPSHOT_NAME"
    echo "$(date): Snapshot gelöscht"

    # Alte Backups löschen
    find "$BACKUP_DIR" -name "prometheus-backup-*.tar.gz" -mtime +$RETENTION_DAYS -delete
    echo "$(date): Alte Backups (älter als $RETENTION_DAYS Tage) gelöscht"

    echo "$(date): Backup abgeschlossen"
else
    echo "$(date): FEHLER - Backup fehlgeschlagen"
    exit 1
fi
EOF

# Ausführbar machen
sudo chmod +x /usr/local/bin/prometheus-backup.sh

# Berechtigungen setzen
sudo chown root:root /usr/local/bin/prometheus-backup.sh
```

### 2.5 Automatisches Backup via Cron

```bash
# Cron-Job für tägliches Backup um 2 Uhr nachts
(sudo crontab -l 2>/dev/null; echo "0 2 * * * /usr/local/bin/prometheus-backup.sh >> /var/log/prometheus-backup.log 2>&1") | sudo crontab -

# Cron-Jobs anzeigen
sudo crontab -l

# Log-Datei anlegen und Berechtigungen setzen
sudo touch /var/log/prometheus-backup.log
sudo chmod 644 /var/log/prometheus-backup.log
```

**Alternative Backup-Frequenzen**:
```bash
# Alle 6 Stunden
0 */6 * * * /usr/local/bin/prometheus-backup.sh

# Täglich um 3 Uhr
0 3 * * * /usr/local/bin/prometheus-backup.sh

# Wöchentlich (Sonntag, 1 Uhr)
0 1 * * 0 /usr/local/bin/prometheus-backup.sh
```

---

## 3. Manuelles Filesystem-Backup (Alternative Methode)

Falls die Snapshot-API nicht verfügbar ist, können Sie auch ein Filesystem-Backup erstellen.

### 3.1 Prometheus stoppen (Cold Backup)

```bash
# Prometheus stoppen
sudo systemctl stop prometheus

# Backup erstellen
sudo tar -czf /backup/prometheus/prometheus-cold-backup-$(date +%Y%m%d-%H%M%S).tar.gz \
    -C /var/lib/ prometheus/

# Prometheus wieder starten
sudo systemctl start prometheus

# Status prüfen
sudo systemctl status prometheus
```

> ⚠️ **Nachteil**: Prometheus ist während des Backups offline (keine Metriken werden gesammelt).

### 3.2 Hot Backup mit rsync (bei laufendem Prometheus)

```bash
# Backup mit rsync (während Prometheus läuft)
sudo rsync -av --exclude='wal' --exclude='queries.active' \
    /var/lib/prometheus/ \
    /backup/prometheus/hot-backup-$(date +%Y%m%d-%H%M%S)/
```

> ⚠️ **Achtung**: Hot Backups können inkonsistent sein, wenn während des Backups geschrieben wird. Verwenden Sie wenn möglich Snapshots.

---

## 4. Wiederherstellung von Backups

### 4.1 Wiederherstellung aus Snapshot

```bash
# Prometheus stoppen
sudo systemctl stop prometheus

# Alte Daten sichern (optional)
sudo mv /var/lib/prometheus /var/lib/prometheus.old

# Backup-Verzeichnis erstellen
sudo mkdir -p /var/lib/prometheus

# Aus TAR-Archiv wiederherstellen
sudo tar -xzf /backup/prometheus/prometheus-backup-20250216-120000.tar.gz \
    -C /var/lib/prometheus/

# Berechtigungen setzen
sudo chown -R prometheus:prometheus /var/lib/prometheus

# Prometheus starten
sudo systemctl start prometheus

# Status prüfen
sudo systemctl status prometheus

# Logs prüfen
sudo journalctl -u prometheus -n 50 --no-pager
```

### 4.2 Überprüfung nach Restore

```bash
# Prometheus erreichbar?
curl -s http://localhost:9090/api/v1/status/tsdb

# Time Series Count prüfen
curl -s http://localhost:9090/api/v1/status/tsdb | jq '.data.seriesCountByMetricName'

# Älteste Daten prüfen
curl -s 'http://localhost:9090/api/v1/query?query=up' | jq '.data.result[0].value'

# Im Webinterface prüfen
# http://localhost:9090/graph
# Query: up{job="prometheus"}
```

### 4.3 Teilweise Wiederherstellung (einzelne Blöcke)

Falls nur bestimmte Zeiträume wiederhergestellt werden sollen:

```bash
# Prometheus stoppen
sudo systemctl stop prometheus

# Einzelne Blöcke aus Backup extrahieren
# Block-IDs entsprechen Zeitstempeln (ULID-Format)
sudo tar -xzf /backup/prometheus/prometheus-backup-20250216-120000.tar.gz \
    --wildcards '01HQ*' \
    -C /var/lib/prometheus/

# Berechtigungen setzen
sudo chown -R prometheus:prometheus /var/lib/prometheus

# Prometheus starten
sudo systemctl start prometheus
```

---

## 5. Remote Storage für Langzeit-Backups

Für Langzeit-Aufbewahrung bietet Prometheus Remote Write/Read.

### 5.1 Remote Write konfigurieren (Beispiel mit Thanos oder Cortex)

```yaml
# In /etc/prometheus/prometheus.yml
remote_write:
  - url: "http://thanos-receiver:19291/api/v1/receive"
    queue_config:
      capacity: 10000
      max_shards: 50
      max_samples_per_send: 5000
```

### 5.2 Alternative: VictoriaMetrics als Remote Storage

```bash
# VictoriaMetrics installieren (Beispiel)
wget https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v1.96.0/victoria-metrics-linux-amd64-v1.96.0.tar.gz
tar -xzf victoria-metrics-linux-amd64-v1.96.0.tar.gz
sudo mv victoria-metrics-prod /usr/local/bin/

# Prometheus konfigurieren
# remote_write:
#   - url: http://localhost:8428/api/v1/write
```

---

## 6. Backup-Monitoring und Alerting

### 6.1 Backup-Success-Metrik erstellen

Erweitern Sie das Backup-Skript:

```bash
# Am Ende von /usr/local/bin/prometheus-backup.sh hinzufügen:
cat >> /usr/local/bin/prometheus-backup.sh << 'EOF'

# Metrik für Node Exporter Textfile Collector
TEXTFILE_DIR="/var/lib/node_exporter/textfile_collector"
if [ -d "$TEXTFILE_DIR" ]; then
    {
        echo "# HELP prometheus_backup_last_success_timestamp_seconds Last successful backup timestamp"
        echo "# TYPE prometheus_backup_last_success_timestamp_seconds gauge"
        echo "prometheus_backup_last_success_timestamp_seconds $(date +%s)"

        echo "# HELP prometheus_backup_last_duration_seconds Duration of last backup in seconds"
        echo "# TYPE prometheus_backup_last_duration_seconds gauge"
        echo "prometheus_backup_last_duration_seconds $SECONDS"
    } > "$TEXTFILE_DIR/prometheus_backup.prom.$$"
    mv "$TEXTFILE_DIR/prometheus_backup.prom.$$" "$TEXTFILE_DIR/prometheus_backup.prom"
fi
EOF
```

### 6.2 Alert für fehlgeschlagene Backups

```yaml
# In /etc/prometheus/rules/backup_alerts.yml
groups:
  - name: backup_alerts
    rules:
    - alert: PrometheusBackupFailed
      expr: (time() - prometheus_backup_last_success_timestamp_seconds) > 86400
      for: 1h
      labels:
        severity: warning
      annotations:
        summary: "Prometheus Backup fehlt"
        description: "Letztes erfolgreiches Backup ist älter als 24 Stunden"

    - alert: PrometheusBackupTooSlow
      expr: prometheus_backup_last_duration_seconds > 1800
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "Prometheus Backup zu langsam"
        description: "Letztes Backup dauerte {{ $value | humanizeDuration }}"
```

---

## 7. Best Practices für Prometheus-Backups

### ✅ Do's:
1. **Verwenden Sie Snapshots** für konsistente Backups
2. **Automatisieren Sie Backups** via Cron
3. **Testen Sie Restores** regelmäßig
4. **Speichern Sie Backups off-site** (z.B. S3, NAS)
5. **Überwachen Sie Backup-Status** mit Alerts
6. **Dokumentieren Sie** den Restore-Prozess
7. **Löschen Sie alte Snapshots** nach dem Backup

### ❌ Don'ts:
1. **Nicht die Admin-API** öffentlich zugänglich machen
2. **Keine Hot Backups ohne Snapshots** bei kritischen Daten
3. **Nicht vergessen** Prometheus-Config mitzusichern
4. **Keine ungetesteten Backups** als einzige Sicherung
5. **Nicht nur lokal** speichern (Single Point of Failure)

---

## 8. Übungsaufgaben

### Aufgabe 1: Snapshot-Backup erstellen und wiederherstellen
1. Aktivieren Sie die Admin-API
2. Erstellen Sie einen Snapshot
3. Sichern Sie den Snapshot
4. Stellen Sie ihn wieder her

### Aufgabe 2: Automatisches Backup-Skript
1. Installieren Sie das Backup-Skript
2. Konfigurieren Sie einen Cron-Job
3. Testen Sie das Skript manuell
4. Prüfen Sie die Log-Datei

### Aufgabe 3: Backup-Monitoring
1. Fügen Sie die Backup-Metrik hinzu
2. Erstellen Sie einen Alert für fehlgeschlagene Backups
3. Testen Sie den Alert (simulieren Sie ein fehlgeschlagenes Backup)

---

## 9. Troubleshooting

### Snapshot-Erstellung schlägt fehl

```bash
# Prüfen ob Admin-API aktiviert ist
curl -XPOST http://localhost:9090/api/v1/admin/tsdb/snapshot

# Fehler: "admin APIs disabled"
# Lösung: --web.enable-admin-api Flag hinzufügen

# Logs prüfen
sudo journalctl -u prometheus -n 100 --no-pager
```

### Restore schlägt fehl

```bash
# Berechtigungen prüfen
ls -la /var/lib/prometheus/

# Berechtigungen korrigieren
sudo chown -R prometheus:prometheus /var/lib/prometheus

# TSDB-Integrität prüfen (nur wenn Prometheus läuft)
curl http://localhost:9090/api/v1/status/tsdb

# Bei Korruption: promtool verwenden
promtool tsdb analyze /var/lib/prometheus/
```

### Backup-Skript schlägt fehl

```bash
# Manuell ausführen mit Debug
sudo bash -x /usr/local/bin/prometheus-backup.sh

# jq installiert?
which jq || sudo apt-get install -y jq

# Backup-Verzeichnis existiert?
sudo mkdir -p /backup/prometheus

# Berechtigungen prüfen
ls -la /backup/prometheus/
```

---

## 10. Weiterführende Themen

- **Object Storage**: Backup nach S3, MinIO, GCS
- **Thanos**: Langzeit-Storage und HA für Prometheus
- **Cortex**: Multi-Tenant Prometheus-Storage
- **VictoriaMetrics**: Alternatives TSDB mit besserer Kompression
- **Grafana Mimir**: Horizontally scalable long-term storage

> **Hinweis**: Diese Aufgabe konzentriert sich auf lokale Backups. Für Produktionsumgebungen sollten Remote-Storage-Lösungen in Betracht gezogen werden.
