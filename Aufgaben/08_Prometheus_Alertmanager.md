# Prometheus - Aufgabenfeld 12 : Alerts und Benachrichtigungen

## Konfiguration von Prometheus Alertmanager für Benachrichtigungen

### 1. Installation des Alertmanagers

```bash
# zum root-Benutzer wechseln
sudo su

# Herunterladen des Alertmanagers
wget https://github.com/prometheus/alertmanager/releases/download/v0.26.0/alertmanager-0.26.0.linux-amd64.tar.gz

# Entpacken des Archivs
tar -xvf alertmanager-0.26.0.linux-amd64.tar.gz

# Erstellen der benötigten Verzeichnisse
mkdir -p /etc/alertmanager
mkdir -p /var/lib/alertmanager

# Kopieren der Binärdateien
cp alertmanager-0.26.0.linux-amd64/alertmanager /usr/local/bin/
cp alertmanager-0.26.0.linux-amd64/amtool /usr/local/bin/

# Kopieren der Konfigurationsdatei
cp alertmanager-0.26.0.linux-amd64/alertmanager.yml /etc/alertmanager/

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
cat > /etc/prometheus/rules/node_alerts.yml << EOF
groups:
- name: node_alerts
  rules:
  - alert: HighCPULoad
    expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "Hohe CPU-Auslastung (instance {{ \$labels.instance }})"
      description: "CPU-Auslastung ist über 80% für mehr als 5 Minuten\n  WERT = {{ \$value }}%"

  - alert: HighMemoryLoad
    expr: 100 * (1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) > 80
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "Hohe Speicherauslastung (instance {{ \$labels.instance }})"
      description: "Speicherauslastung ist über 80% für mehr als 5 Minuten\n  WERT = {{ \$value }}%"

  - alert: HighDiskUsage
    expr: 100 - ((node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100) > 85
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "Hohe Festplattennutzung (instance {{ \$labels.instance }})"
      description: "Festplattennutzung des Root-Dateisystems ist über 85% für mehr als 5 Minuten\n  WERT = {{ \$value }}%"
EOF

# Setzen der Berechtigungen
chown prometheus:prometheus /etc/prometheus/rules/node_alerts.yml
```

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
# Erzeugen einer hohen CPU-Last für 6 Minuten
stress --cpu 4 --timeout 360s
```

> Hinweis: Installieren Sie das stress-Tool, falls es noch nicht installiert ist:
> ```bash
> apt-get install -y stress
> ```

Nach etwa 5 Minuten sollte ein Alert ausgelöst werden, den Sie im Prometheus- und Alertmanager-Webinterface sehen können. Wenn alles korrekt konfiguriert ist, sollten Sie auch eine E-Mail-Benachrichtigung erhalten.

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
