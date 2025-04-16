# Lösungsblatt: Prometheus - Setup

Dieses Lösungsblatt enthält die Lösungen für die Aufgaben aus dem Aufgabenfeld 5: Prometheus Setup.

## Aufgabe 1: Installation der Abhängigkeiten und Tools über die Linux Shell

### Lösung:

```bash
# zum root-Benutzer wechseln
sudo su

# Installation der Tools und Abhängigkeiten
apt-get update && apt-get install -y curl net-tools wget gnupg2 software-properties-common
```

## Aufgabe 2: Installation von Prometheus über die Linux Shell

### Lösung:

```bash
# Herunterladen und Installieren von Prometheus
wget https://github.com/prometheus/prometheus/releases/download/v2.46.0/prometheus-2.46.0.linux-amd64.tar.gz

# Entpacken des Archivs
tar -xvf prometheus-2.46.0.linux-amd64.tar.gz

# Erstellen der benötigten Verzeichnisse
mkdir -p /etc/prometheus
mkdir -p /var/lib/prometheus

# Erstellen eines Prometheus-Benutzers
useradd --no-create-home --shell /bin/false prometheus

# Setzen der Berechtigungen
chown prometheus:prometheus /var/lib/prometheus

# Kopieren der Binärdateien
cp prometheus-2.46.0.linux-amd64/prometheus /usr/local/bin/
cp prometheus-2.46.0.linux-amd64/promtool /usr/local/bin/

# Kopieren der Konfigurationsdateien
cp -r prometheus-2.46.0.linux-amd64/consoles /etc/prometheus
cp -r prometheus-2.46.0.linux-amd64/console_libraries /etc/prometheus
cp prometheus-2.46.0.linux-amd64/prometheus.yml /etc/prometheus/

# Setzen der Berechtigungen
chown -R prometheus:prometheus /etc/prometheus
chown prometheus:prometheus /usr/local/bin/prometheus
chown prometheus:prometheus /usr/local/bin/promtool
```

## Aufgabe 3: Konfiguration von Prometheus als Systemdienst

### Lösung:

```bash
# Erstellen der Systemd-Service-Datei
cat > /etc/systemd/system/prometheus.service << EOF
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \\
    --config.file /etc/prometheus/prometheus.yml \\
    --storage.tsdb.path /var/lib/prometheus/ \\
    --web.console.templates=/etc/prometheus/consoles \\
    --web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=multi-user.target
EOF

# Neuladen der Systemd-Konfiguration
systemctl daemon-reload

# Starten des Prometheus-Dienstes
systemctl start prometheus

# Aktivieren des Prometheus-Dienstes für den Autostart
systemctl enable prometheus

# Überprüfen des Status des Prometheus-Dienstes
systemctl status prometheus
```

## Aufgabe 4: Überprüfen der Prometheus-Installation über das Webinterface

### Lösung:

1. Öffnen Sie das Webinterface im Browser unter http://localhost:9090
2. Überprüfen Sie, ob die Prometheus-Benutzeroberfläche korrekt angezeigt wird
3. Navigieren Sie zu Status > Targets, um zu überprüfen, ob Prometheus sich selbst überwacht
4. Vergewissern Sie sich, dass der Status des Targets "UP" ist

## Aufgabe 5: Grundlegende Konfiguration von Prometheus

### Lösung:

1. Zeigen Sie die aktuelle Konfigurationsdatei an:
   ```bash
   cat /etc/prometheus/prometheus.yml
   ```

2. Die Standardkonfiguration enthält folgende Hauptabschnitte:
   - `global`: Globale Konfigurationseinstellungen wie Scrape-Intervall
   - `scrape_configs`: Konfiguration der Ziele, von denen Prometheus Metriken sammelt

3. Die Standardkonfiguration sieht etwa so aus:
   ```yaml
   global:
     scrape_interval: 15s
     evaluation_interval: 15s

   scrape_configs:
     - job_name: 'prometheus'
       static_configs:
         - targets: ['localhost:9090']
   ```

## Aufgabe 6: Anpassen der Prometheus-Konfiguration

### Lösung:

1. Öffnen Sie die Konfigurationsdatei zum Bearbeiten:
   ```bash
   nano /etc/prometheus/prometheus.yml
   ```

2. Ändern Sie das `scrape_interval` im `global`-Abschnitt auf 10 Sekunden:
   ```yaml
   global:
     scrape_interval: 10s
     evaluation_interval: 15s
   ```

3. Speichern Sie die Datei (bei nano: STRG+O, ENTER, STRG+X)

4. Starten Sie Prometheus neu, um die Änderungen zu übernehmen:
   ```bash
   systemctl restart prometheus
   ```

## Aufgabe 7: Überprüfen der Konfigurationsänderung

### Lösung:

1. Öffnen Sie erneut das Webinterface unter http://localhost:9090
2. Navigieren Sie zu Status > Configuration
3. Überprüfen Sie, ob das `scrape_interval` auf 10s geändert wurde
4. Alternativ können Sie auch die Konfiguration über die Kommandozeile überprüfen:
   ```bash
   curl http://localhost:9090/api/v1/status/config | jq
   ```
   (Falls `jq` nicht installiert ist: `apt-get install jq`)

## Zusätzliche Hinweise

- Die Prometheus-Konfigurationsdatei verwendet das YAML-Format, achten Sie auf die korrekte Einrückung
- Nach jeder Änderung der Konfigurationsdatei muss der Prometheus-Dienst neu gestartet werden
- Sie können die Konfigurationsdatei vor dem Neustart validieren:
  ```bash
  promtool check config /etc/prometheus/prometheus.yml
  ```
- Prometheus speichert seine Daten standardmäßig in `/var/lib/prometheus/`
- Die Standardport für das Webinterface ist 9090
- Für Produktionsumgebungen sollten Sie zusätzliche Sicherheitsmaßnahmen wie Authentifizierung und TLS-Verschlüsselung einrichten
- Die Retention-Zeit (wie lange Daten gespeichert werden) kann mit dem Parameter `--storage.tsdb.retention.time` konfiguriert werden
