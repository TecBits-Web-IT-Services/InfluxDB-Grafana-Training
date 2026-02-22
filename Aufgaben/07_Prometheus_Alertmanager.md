# Prometheus - Aufgabenfeld 7 : Alerts und Benachrichtigungen

## Konfiguration von Prometheus Alertmanager für Benachrichtigungen

### 1. Installation des Alertmanagers

```bash
# zum root-Benutzer wechseln
sudo su

# Herunterladen des Alertmanagers (aktuelle stabile Version)
wget https://github.com/prometheus/alertmanager/releases/download/v0.27.0/alertmanager-0.27.0.linux-amd64.tar.gz

# Entpacken des Archivs
tar -xvf alertmanager-0.27.0.linux-amd64.tar.gz

# Erstellen der benötigten Verzeichnisse
mkdir -p /etc/alertmanager
mkdir -p /var/lib/alertmanager

# Kopieren der Binärdateien
cp alertmanager-0.27.0.linux-amd64/alertmanager /usr/local/bin/
cp alertmanager-0.27.0.linux-amd64/amtool /usr/local/bin/

# Kopieren der Konfigurationsdatei
cp alertmanager-0.27.0.linux-amd64/alertmanager.yml /etc/alertmanager/

# Erstellen eines Alertmanager-Benutzers
useradd --no-create-home --shell /bin/false alertmanager

# Setzen der Berechtigungen
chown -R alertmanager:alertmanager /etc/alertmanager
chown -R alertmanager:alertmanager /var/lib/alertmanager
chown alertmanager:alertmanager /usr/local/bin/alertmanager
chown alertmanager:alertmanager /usr/local/bin/amtool
```

### 2. Konfiguration des Alertmanagers als Systemdienst

```bash
# Erstellen der Systemd-Service-Datei
cat > /etc/systemd/system/alertmanager.service << EOF
[Unit]
Description=Alertmanager
Wants=network-online.target
After=network-online.target

[Service]
User=alertmanager
Group=alertmanager
Type=simple
ExecStart=/usr/local/bin/alertmanager \\
    --config.file=/etc/alertmanager/alertmanager.yml \\
    --storage.path=/var/lib/alertmanager

[Install]
WantedBy=multi-user.target
EOF

# Neuladen der Systemd-Konfiguration
systemctl daemon-reload

# Starten des Alertmanager-Dienstes
systemctl start alertmanager

# Aktivieren des Alertmanager-Dienstes für den Autostart
systemctl enable alertmanager

# Überprüfen des Status des Alertmanager-Dienstes
systemctl status alertmanager
```

### 3. Grundlegende Konfiguration des Alertmanagers

Die Standardkonfigurationsdatei des Alertmanagers befindet sich unter `/etc/alertmanager/alertmanager.yml`. Bearbeiten wir diese, um E-Mail-Benachrichtigungen einzurichten:

```bash
# Bearbeiten der Alertmanager-Konfigurationsdatei
nano /etc/alertmanager/alertmanager.yml
```

Ersetzen Sie den Inhalt durch folgende Konfiguration:

> Hinweis : 
> - Das Passwort für den SMTP Server wird während der Schulung ausgegeben und muss in der unten stehenden Konfiguration ergänzt werden.
> - Tragen Sie in der Konfiguration IHRE E-Mail-Adresse als Empfänger ein
```yaml
global:
  smtp_smarthost: 'mail01.tecbits.de:587'
  smtp_from: 'training@tecbits.de'
  smtp_auth_username: 'training@tecbits.de'
  smtp_auth_password: 'WIRD_WÄHREND_DER_SCHULUNG_AUSGEGEBEN'
  smtp_require_tls: true

route:
  group_by: ['alertname']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 1h
  receiver: 'email'

receivers:
- name: 'email'
  email_configs:
  - to: 'ihre-email@beispiel.de'
    send_resolved: true
```

Speichern Sie die Datei und starten Sie den Alertmanager neu:

```bash
# Neustarten des Alertmanager-Dienstes
systemctl restart alertmanager
```

### 4. Konfiguration von Prometheus für die Verwendung des Alertmanagers

Bearbeiten Sie die Prometheus-Konfigurationsdatei, um den Alertmanager hinzuzufügen:

```bash
# Bearbeiten der Prometheus-Konfigurationsdatei
nano /etc/prometheus/prometheus.yml
```

Fügen Sie den folgenden Abschnitt hinzu:

```yaml
alerting:
  alertmanagers:
  - static_configs:
    - targets:
      - localhost:9093

rule_files:
  - "/etc/prometheus/rules/*.yml"
```

Erstellen Sie ein Verzeichnis für die Alerting-Regeln:

```bash
# Erstellen des Verzeichnisses für Alerting-Regeln
mkdir -p /etc/prometheus/rules
```

### 5. Erstellen von Alerting-Regeln

Erstellen Sie eine Datei für Alerting-Regeln:

```bash
# Erstellen einer Datei für Alerting-Regeln
cat > /etc/prometheus/rules/node_alerts.yml << 'EOF'
groups:
- name: node_alerts
  rules:
  - alert: HighCPULoad
    expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "Hohe CPU-Auslastung (instance {{ $labels.instance }})"
      description: "CPU-Auslastung ist über 80% für mehr als 5 Minuten\n  WERT = {{ $value | humanize }}%"

  - alert: CriticalCPULoad
    expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 95
    for: 3m
    labels:
      severity: critical
    annotations:
      summary: "Kritische CPU-Auslastung (instance {{ $labels.instance }})"
      description: "CPU-Auslastung ist über 95% für mehr als 3 Minuten\n  WERT = {{ $value | humanize }}%"

  - alert: HighMemoryLoad
    expr: 100 * (1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) > 85
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "Hohe Speicherauslastung (instance {{ $labels.instance }})"
      description: "Speicherauslastung ist über 85% für mehr als 5 Minuten\n  WERT = {{ $value | humanize }}%"

  - alert: HighDiskUsage
    expr: 100 - ((node_filesystem_avail_bytes{mountpoint="/",fstype!~"tmpfs|fuse.*"} / node_filesystem_size_bytes{mountpoint="/",fstype!~"tmpfs|fuse.*"}) * 100) > 85
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "Hohe Festplattennutzung (instance {{ $labels.instance }})"
      description: "Festplattennutzung des Root-Dateisystems ist über 85% für mehr als 5 Minuten\n  WERT = {{ $value | humanize }}%"

  - alert: NodeExporterDown
    expr: up{job="node"} == 0
    for: 2m
    labels:
      severity: critical
    annotations:
      summary: "Node Exporter down (instance {{ $labels.instance }})"
      description: "Node Exporter auf {{ $labels.instance }} ist seit mehr als 2 Minuten nicht erreichbar."
EOF

# Setzen der Berechtigungen
chown prometheus:prometheus /etc/prometheus/rules/node_alerts.yml

# Validieren der Alert-Regeln
promtool check rules /etc/prometheus/rules/node_alerts.yml
```

> **Änderungen und Verbesserungen**:
> - **HighCPULoad**: Verwendet nun 5m statt 1m für stabilere Alerts (verhindert Flapping)
> - **CriticalCPULoad**: Neuer Alert für kritische Situationen (>95%)
> - **HighMemoryLoad**: Schwellwert von 80% auf 85% erhöht (realistischer)
> - **HighDiskUsage**: Filtert tmpfs und fuse-Filesysteme aus
> - **NodeExporterDown**: Neuer Alert für ausgefallene Node Exporter
> - Verwendung von `| humanize` für bessere Formatierung der Werte

Starten Sie Prometheus neu, um die Änderungen zu übernehmen:

```bash
# Neustarten des Prometheus-Dienstes
systemctl restart prometheus
```

### 6. Überprüfen der Alerting-Regeln

- Öffnen Sie das Prometheus-Webinterface unter [http://localhost:9090](http://localhost:9090)
- Navigieren Sie zu Status > Rules, um zu überprüfen, ob Ihre Alerting-Regeln geladen wurden
- Navigieren Sie zu Alerts, um den aktuellen Status Ihrer Alerts zu sehen

### 7. Überprüfen des Alertmanagers

- Öffnen Sie das Alertmanager-Webinterface unter [http://localhost:9093](http://localhost:9093)
- Hier können Sie den Status Ihrer Alerts und die Konfiguration des Alertmanagers überprüfen

### 8. Testen der Alerts

Um einen Alert auszulösen, können Sie die CPU-Auslastung künstlich erhöhen:

```bash
# Erzeugen einer hohen CPU-Last für 8 Minuten
# Passen Sie --cpu an die Anzahl Ihrer CPU-Kerne an
stress --cpu 4 --timeout 8m
```

> **Hinweise zum Testen**:
> - Installieren Sie das stress-Tool, falls es noch nicht installiert ist: `apt-get install -y stress`
> - Je nach Anzahl der verfügbaren CPU-Kerne in der Test-Maschine können Sie den Wert für `--cpu` anpassen
> - Prüfen Sie die CPU-Kerne mit: `nproc` oder `lscpu`
> - Mit dem PromQL-Befehl `100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)` können Sie den aktuellen Wert der Auslastung prüfen
> - Der Alert wird nach 5 Minuten in den Status "PENDING" wechseln und dann "FIRING"

**Timeline des Alert-Tests**:
1. **0-1 Min**: CPU-Last steigt, noch kein Alert
2. **1-5 Min**: Bedingung erfüllt, Alert im Status "PENDING"
3. **Nach 5 Min**: Alert wechselt zu "FIRING", E-Mail wird versendet
4. **Nach 8 Min**: stress-Tool stoppt, CPU-Last normalisiert sich
5. **Nach weiteren ~5 Min**: Alert wird resolved, Resolved-E-Mail wird versendet

Sie können den Status in Echtzeit beobachten:
- **Prometheus**: [http://localhost:9090/alerts](http://localhost:9090/alerts)
- **Alertmanager**: [http://localhost:9093](http://localhost:9093)

### 9. Erweiterte Konfiguration des Alertmanagers

Der Alertmanager bietet viele Möglichkeiten zur Konfiguration von Benachrichtigungen. Hier ist ein Beispiel für eine erweiterte Konfiguration mit verschiedenen Empfängern und Routing-Optionen:

```yaml
global:
  smtp_smarthost: 'mail01.tecbits.de:587'
  smtp_from: 'training@tecbits.de'
  smtp_auth_username: 'training@tecbits.de'
  smtp_auth_password: 'WIRD_WÄHREND_DER_SCHULUNG_AUSGEGEBEN'
  smtp_require_tls: true

route:
  group_by: ['alertname', 'instance']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 1h
  receiver: 'email-team'
  routes:
  - match:
      severity: critical
    receiver: 'email-admin'
    continue: true

receivers:
- name: 'email-team'
  email_configs:
  - to: 'team@beispiel.de'
    send_resolved: true

- name: 'email-admin'
  email_configs:
  - to: 'admin@beispiel.de'
    send_resolved: true
```

> Hinweise:
> - Der Alertmanager läuft standardmäßig auf Port 9093
> - Alerts werden basierend auf PromQL-Ausdrücken definiert
> - Der Alertmanager kann Benachrichtigungen über verschiedene Kanäle senden, z.B. E-Mail, Slack, PagerDuty, etc.
> - Die Konfiguration des Alertmanagers ermöglicht komplexes Routing und Gruppieren von Alerts
> - Alerts können mit Labels und Annotations angereichert werden, um zusätzliche Informationen bereitzustellen
