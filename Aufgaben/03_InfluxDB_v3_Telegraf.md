# InfluxDB v3 - Aufgabenfeld 3 : Einrichtung und Verwendung von Telegraf

> Hinweis:
> - Telegraf unterstützt InfluxDB v3 über ein spezielles Output-Plugin
> - Die Konfiguration unterscheidet sich von v2
> - Sollten Sie Probleme haben, finden Sie Beispielkonfigurationen im Ordner Beispielkonfigurationen

### 1. Installation von Telegraf über die Linux Shell

```bash
# zum root-Benutzer wechseln
sudo su

# Installation von Telegraf und Apache Webserver
apt-get install telegraf apache2

# Telegraf Version prüfen
telegraf version
```

### 2. Erstellen Sie mit der CLI eine neue Database "computer-monitoring" und einen neuen ADMIN-Token über den InfluxDB Explorer

> Hinweis:
> Speichern Sie den Token unter /workspace/telegraf-token.txt, er kann nach dem Schließen in der Oberfläche nicht wieder angezeigt werden.

### 3. Erstellen Sie eine Telegraf-Konfiguration für CPU-Monitoring

> **Wichtig:** Für InfluxDB v3 verwenden wir das `outputs.influxdb_v2` Plugin mit v3-kompatiblen Einstellungen

> Tauschen Sie den Access-Token durch den Token aus dem vorherigen Schritt.
```bash
# Backup der originalen Konfiguration
cp /etc/telegraf/telegraf.conf /etc/telegraf/telegraf.conf.backup

# Erstellen einer neuen Konfiguration
cat > /etc/telegraf/telegraf.conf << 'EOF'
# Global Agent Configuration
[agent]
  interval = "10s"
  round_interval = true
  metric_batch_size = 1000
  metric_buffer_limit = 10000
  collection_jitter = "0s"
  flush_interval = "10s"
  flush_jitter = "0s"
  precision = "0s"
  debug = false
  quiet = false
  logfile = ""
  hostname = ""
  omit_hostname = false

# Output Plugin für InfluxDB v3
[[outputs.influxdb_v2]]
  ## InfluxDB v3 URL
  urls = ["http://localhost:8181"]

  ## Token für Authentifizierung
  token = "TOKEN_AUS_DEM_VORHERIGEN_SCHRITT"

  ## Organisation (in v3 optional, kann leer sein)
  organization = ""

  ## Database (verwendet bucket-Parameter für Kompatibilität)
  bucket = "computer-monitoring"

  ## Timeout
  timeout = "5s"

# Input Plugin für CPU Metrics
[[inputs.cpu]]
  ## Ob CPU-Metriken pro Core oder gesamt erfasst werden
  percpu = true
  totalcpu = true
  collect_cpu_time = false
  report_active = false
  core_tags = false
EOF

# Ersetzen Sie den Token durch den aus dem vorherigen Schritt kopierten Wert
nano /etc/telegraf/telegraf.conf

# Konfiguration testen
telegraf --config /etc/telegraf/telegraf.conf --test

# Telegraf interaktiv starten (zum Testen)
telegraf --config /etc/telegraf/telegraf.conf
```
Nach einer Minute sollten Sie im InfluxDB Explorer Data Explorer die CPU Werte sehen können.
Beenden Sie den Telegraf Prozess mit `STRG+C` für die nächste Aufgabe.


### 4. Erweitern Sie die Telegraf-Konfiguration um weitere System-Metriken

```bash
# Konfiguration erweitern
nano /etc/telegraf/telegraf.conf
```
```bash
# Memory Metrics
[[inputs.mem]]

# Disk Metrics
[[inputs.disk]]
  ## Ignoriere bestimmte Dateisysteme
  ignore_fs = ["tmpfs", "devtmpfs", "devfs", "iso9660", "overlay", "aufs", "squashfs"]

# Disk IO Metrics
[[inputs.diskio]]

# System Load und Uptime
[[inputs.system]]

# Network Metrics
[[inputs.net]]
  ## Interface pattern to collect
  interfaces = ["eth*", "enp*", "lo"]

# Process Metrics
[[inputs.processes]]

# Kernel Metrics
[[inputs.kernel]]
```
```bash
# Telegraf neustarten
telegraf --config /etc/telegraf/telegraf.conf
```
Nach einer Minute sollten Sie im InfluxDB Explorer Data Explorer die neuen Metriken sehen können.
Beenden Sie den Telegraf Prozess mit `STRG+C` für die nächste Aufgabe.

### 5. Aktivieren Sie den Debug-Modus des Telegraf-Services

```bash
# Debug-Modus in der Konfiguration aktivieren
sed -i 's/debug = false/debug = true/g' /etc/telegraf/telegraf.conf

# Alternativ: direkt mit Parameter starten
telegraf --config /etc/telegraf/telegraf.conf --debug
```

### 6. Verifizieren Sie die Daten mit SQL-Abfragen

```bash
# CPU-Daten abfragen
influxdb3 query \
  --database "computer-monitoring" \
  "SELECT * FROM cpu ORDER BY time DESC LIMIT 10"
```

### 7. Erstellen Sie eine neue Database "apache-logs" für Apache-Monitoring

```bash
# Database erstellen
influxdb3 create database "apache-logs"
```

### 8. Erweitern Sie die Telegraf-Konfiguration für Apache Log-Monitoring mit Bucket-Routing
> Tauschen Sie den Access-Token durch den Token aus dem vorherigen Schritt.
```bash
# Erstellen einer erweiterten Konfiguration
```

```bash
# Output für Apache Logs
[[outputs.influxdb_v2]]
  urls = ["http://localhost:8181"]
  token = "TOKEN_AUS_DEM_VORHERIGEN_SCHRITT"
  organization = ""
  bucket = "apache-logs"

  ## Nur Metriken mit targetBucket = apache-logs
  [outputs.influxdb_v2.tagpass]
    targetBucket = ["apache-logs"]

# Apache Access Log Input
[[inputs.tail]]
  files = ["/var/log/apache2/access.log"]
  from_beginning = false

  ## Grok Pattern für Apache Combined Log Format
  data_format = "grok"
  grok_patterns = ["%{COMBINED_LOG_FORMAT}"]
  grok_timezone = "Europe/Berlin"

  ## Name Override
  name_override = "apache_access_log"

  ## Tags für Routing
  [inputs.tail.tags]
    targetBucket = "apache-logs"

# Apache Error Log Input
[[inputs.tail]]
  files = ["/var/log/apache2/error.log"]
  from_beginning = false

  data_format = "grok"
  grok_patterns = ['\\[%{HTTPDERROR_DATE:timestamp}\\] \\[%{LOGLEVEL:loglevel}\\]( \\[client %{IPORHOST:clientip}\\])? %{GREEDYDATA:message}']
  grok_custom_patterns = '''
    HTTPDERROR_DATE %{DAY} %{MONTH} %{MONTHDAY} %{TIME} %{YEAR}
  '''
  grok_timezone = "Europe/Berlin"

  name_override = "apache_error_log"

  [inputs.tail.tags]
    targetBucket = "apache-logs"
```

```bash
# Telegraf neustarten
telegraf --config /etc/telegraf/telegraf.conf
```

### 9. Generieren Sie Apache-Testdaten und verifizieren Sie die Logs

```bash
# In einem neuen Terminal: Test-Traffic generieren
curl http://localhost/
curl http://localhost/
curl http://localhost/zonk  # 404 Error
curl http://localhost/test  # 404 Error
curl http://localhost/

# Daten in der apache-logs Database prüfen
influxdb3 query \
  --database "apache-logs" \
  "SELECT * FROM apache_access_log ORDER BY time DESC LIMIT 10"

# HTTP-Statuscodes analysieren
influxdb3 query \
  --database "apache-logs" \
  "SELECT
     resp_code,
     COUNT(*) as request_count
   FROM apache_access_log
   GROUP BY resp_code
   ORDER BY request_count DESC"

# Fehlerhafte Requests identifizieren
influxdb3 query \
  --database "apache-logs" \
  "SELECT time, request, resp_code, client_ip
   FROM apache_access_log
   WHERE resp_code >= 400
   ORDER BY time DESC"
```

### 10. Telegraf als Systemd-Service konfigurieren

```bash
# Service-Datei anpassen
cat > /etc/systemd/system/telegraf.service << 'EOF'
[Unit]
Description=Telegraf
Documentation=https://github.com/influxdata/telegraf
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=telegraf
ExecStart=/usr/bin/telegraf --config /etc/telegraf/telegraf.conf
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Service aktivieren und starten
systemctl daemon-reload
systemctl enable telegraf
systemctl restart telegraf

# Status prüfen
systemctl status telegraf

# Logs anzeigen
journalctl -u telegraf -f
```