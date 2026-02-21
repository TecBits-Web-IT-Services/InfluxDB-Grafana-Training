# Prometheus - Aufgabenfeld 5: Setup und Grundkonfiguration

## Installation von Prometheus unter Ubuntu 24.04

### 1. Installation der Abhängigkeiten und Tools über die Linux Shell

```bash
# zum root-Benutzer wechseln
sudo su

# Installation der Tools und Abhängigkeiten
apt-get update && apt-get install -y curl net-tools wget gnupg2 software-properties-common stress openssh-server
```

### 2. Installation von Prometheus über die Linux Shell

```bash
# Herunterladen und Installieren von Prometheus (aktuelle LTS-Version)
wget https://github.com/prometheus/prometheus/releases/download/v2.54.1/prometheus-2.54.1.linux-amd64.tar.gz

# Entpacken des Archivs
tar -xvf prometheus-2.54.1.linux-amd64.tar.gz

# Erstellen der benötigten Verzeichnisse
mkdir -p /etc/prometheus
mkdir -p /var/lib/prometheus

# Erstellen eines Prometheus-Benutzers
useradd --no-create-home --shell /bin/false prometheus

# Setzen der Berechtigungen
chown prometheus:prometheus /var/lib/prometheus

# Kopieren der Binärdateien
cp prometheus-2.54.1.linux-amd64/prometheus /usr/local/bin/
cp prometheus-2.54.1.linux-amd64/promtool /usr/local/bin/

# Kopieren der Konfigurationsdateien
cp -r prometheus-2.54.1.linux-amd64/consoles /etc/prometheus
cp -r prometheus-2.54.1.linux-amd64/console_libraries /etc/prometheus
cp prometheus-2.54.1.linux-amd64/prometheus.yml /etc/prometheus/

# Setzen der Berechtigungen
chown -R prometheus:prometheus /etc/prometheus
chown prometheus:prometheus /usr/local/bin/prometheus
chown prometheus:prometheus /usr/local/bin/promtool
```

### 3. Konfiguration von Prometheus als Systemdienst

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
> Hinweis: Die Ausgabe des letzten Befehls sollte eine Zeile mit dem Inhalt "Active: active (running)" enthalten.

### 4. Überprüfen der Prometheus-Installation über das Webinterface

- Öffnen Sie [das Webinterface](http://localhost:9090) (http://localhost:9090) im Browser Firefox in der virtuellen Umgebung
    - Sollten Sie eine andere Umgebung als die durch die GFU Bereitgestellte verwenden müssen Sie gegebenenfalls einen anderen Hostname/IP anstatt von "localhost" verwenden
- Überprüfen Sie, ob die Prometheus-Benutzeroberfläche angezeigt wird
- Navigieren Sie zu Status > Targets, um zu überprüfen, ob Prometheus sich selbst überwacht

### 5. Grundlegende Konfiguration von Prometheus

Die Standardkonfigurationsdatei von Prometheus befindet sich unter `/etc/prometheus/prometheus.yml`. Schauen wir uns die Grundstruktur an:

```bash
# Anzeigen der Prometheus-Konfigurationsdatei
cat /etc/prometheus/prometheus.yml
```

Die Konfigurationsdatei enthält folgende Hauptabschnitte:

- `global`: Globale Konfigurationseinstellungen wie Scrape-Intervall
- `rule_files`: Dateien mit Regeln für Alerting und Recording
- `alerting`: Konfiguration von Alerts
- `scrape_configs`: Konfiguration der Ziele, von denen Prometheus Metriken sammelt

Hier ist ein Beispiel für die Standardkonfiguration:

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
```

### 6. Anpassen der Prometheus-Konfiguration

Bearbeiten Sie die Konfigurationsdatei, um das Scrape-Intervall zu ändern:

```bash
# Bearbeiten der Prometheus-Konfigurationsdatei
nano /etc/prometheus/prometheus.yml
```

Ändern Sie das `scrape_interval` im `global`-Abschnitt auf 10 Sekunden:

```yaml
global:
  scrape_interval: 10s
  evaluation_interval: 15s
```

Speichern Sie die Datei und starten Sie Prometheus neu:

```bash
# Neustarten des Prometheus-Dienstes
systemctl restart prometheus
```

### 7. Überprüfen der Konfigurationsänderung

- Öffnen Sie erneut das Webinterface unter [http://localhost:9090](http://localhost:9090)
- Navigieren Sie zu Status > Configuration, um zu überprüfen, ob Ihre Änderungen übernommen wurden

### 8. Wichtige Prometheus-Konzepte verstehen

#### Time Series Database (TSDB)
Prometheus verwendet eine lokale Time Series Database zur Speicherung von Metriken. Die Daten werden in `/var/lib/prometheus/` gespeichert.

#### Retention und Storage
Standardmäßig speichert Prometheus Daten für 15 Tage. Sie können dies mit dem Flag `--storage.tsdb.retention.time` anpassen, welches in der System-Service-Datei aus Schritt 3 angegeben werden muss:

```bash
# Beispiel: 30 Tage Retention
# Bearbeiten Sie /etc/systemd/system/prometheus.service und fügen Sie hinzu:
ExecStart=/usr/local/bin/prometheus \
    --config.file /etc/prometheus/prometheus.yml \
    --storage.tsdb.path /var/lib/prometheus/ \
    --storage.tsdb.retention.time=30d \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries
```

Im Webinterface unter [http://localhost:9090/flags](http://localhost:9090/flags) können alle aktuellen Flags angezeigt werden.

#### Scraping
Prometheus sammelt Metriken durch regelmäßiges "Scrapen" (Abrufen) von konfigurierten Endpoints.

#### Labels und Time Series
Jede Metrik in Prometheus ist eine eindeutige Time Series, identifiziert durch:
- Metrikname (z.B. `http_requests_total`)
- Labels (z.B. `{method="GET", status="200"}`)

### 9. Erste PromQL-Abfragen

Testen Sie im Webinterface unter [http://localhost:9090/graph](http://localhost:9090/graph):

```promql
# Zeigt Build-Informationen von Prometheus
prometheus_build_info

# Anzahl der Time Series in der Datenbank
prometheus_tsdb_symbol_table_size_bytes

# HTTP-Anfragen an Prometheus selbst
rate(prometheus_http_requests_total[5m])
```

> Hinweise:
> - Die Prometheus-Konfigurationsdatei verwendet das YAML-Format, achten Sie auf die korrekte Einrückung
> - Nach jeder Änderung der Konfigurationsdatei muss der Prometheus-Dienst neu gestartet werden
> - Prometheus bietet eine integrierte Validierung der Konfigurationsdatei mit dem Befehl `promtool check config /etc/prometheus/prometheus.yml`
> - Verwenden Sie `systemctl reload prometheus` statt `restart` um laufende Scrapes nicht zu unterbrechen (sofern nur Config geändert wurde)
