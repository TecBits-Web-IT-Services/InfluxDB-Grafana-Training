# Lösungsblatt: Prometheus - Alerts und Benachrichtigungen

Dieses Lösungsblatt enthält die Lösungen für die Aufgaben aus dem Aufgabenfeld 7: Alerts und Benachrichtigungen mit Prometheus Alertmanager.

## Aufgabe 1: Installation des Alertmanagers

### Lösung:

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

## Aufgabe 2: Konfiguration des Alertmanagers als Systemdienst

### Lösung:

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

## Aufgabe 3: Grundlegende Konfiguration des Alertmanagers

### Lösung:

1. Öffnen Sie die Alertmanager-Konfigurationsdatei zum Bearbeiten:
   ```bash
   nano /etc/alertmanager/alertmanager.yml
   ```

2. Ersetzen Sie den Inhalt durch folgende Konfiguration (passen Sie die E-Mail-Adresse an):
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

3. Speichern Sie die Datei (bei nano: STRG+O, ENTER, STRG+X)

4. Starten Sie den Alertmanager neu, um die Änderungen zu übernehmen:
   ```bash
   systemctl restart alertmanager
   ```

## Aufgabe 4: Konfiguration von Prometheus für die Verwendung des Alertmanagers

### Lösung:

1. Bearbeiten Sie die Prometheus-Konfigurationsdatei:
   ```bash
   nano /etc/prometheus/prometheus.yml
   ```

2. Fügen Sie den folgenden Abschnitt hinzu (vor dem `scrape_configs`-Abschnitt):
   ```yaml
   alerting:
     alertmanagers:
     - static_configs:
       - targets:
         - localhost:9093

   rule_files:
     - "/etc/prometheus/rules/*.yml"
   ```

3. Speichern Sie die Datei (bei nano: STRG+O, ENTER, STRG+X)

4. Erstellen Sie ein Verzeichnis für die Alerting-Regeln:
   ```bash
   mkdir -p /etc/prometheus/rules
   ```

## Aufgabe 5: Erstellen von Alerting-Regeln

### Lösung:

1. Erstellen Sie eine Datei für Alerting-Regeln:
   ```bash
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
   ```

2. Setzen Sie die Berechtigungen:
   ```bash
   chown prometheus:prometheus /etc/prometheus/rules/node_alerts.yml
   ```

3. Starten Sie Prometheus neu, um die Änderungen zu übernehmen:
   ```bash
   systemctl restart prometheus
   ```

## Aufgabe 6: Überprüfen der Alerting-Regeln

### Lösung:

1. Öffnen Sie das Prometheus-Webinterface unter http://localhost:9090
2. Navigieren Sie zu Status > Rules, um zu überprüfen, ob Ihre Alerting-Regeln geladen wurden
3. Überprüfen Sie, ob die drei definierten Regeln (HighCPULoad, HighMemoryLoad, HighDiskUsage) angezeigt werden
4. Navigieren Sie zu Alerts, um den aktuellen Status Ihrer Alerts zu sehen
5. Die Alerts sollten im Status "inactive" sein, solange die definierten Schwellenwerte nicht überschritten werden

## Aufgabe 7: Überprüfen des Alertmanagers

### Lösung:

1. Öffnen Sie das Alertmanager-Webinterface unter http://localhost:9093
2. Überprüfen Sie, ob das Webinterface korrekt geladen wird
3. Hier können Sie den Status Ihrer Alerts und die Konfiguration des Alertmanagers überprüfen
4. Zu diesem Zeitpunkt sollten keine aktiven Alerts angezeigt werden

## Aufgabe 8: Testen der Alerting-Funktionalität

### Lösung:

1. Um einen Alert auszulösen, können Sie eine hohe CPU-Last erzeugen:
   ```bash
   # Erzeugen einer hohen CPU-Last für 6 Minuten
   stress --cpu 4 --timeout 360s
   ```
   (Falls das Paket `stress` nicht installiert ist: `apt-get install stress`)

2. Alternativ können Sie einen Alert manuell auslösen, indem Sie die Schwellenwerte in den Alerting-Regeln temporär herabsetzen:
   ```bash
   nano /etc/prometheus/rules/node_alerts.yml
   ```
   Ändern Sie beispielsweise den Schwellenwert für HighCPULoad von 80 auf 10:
   ```yaml
   - alert: HighCPULoad
     expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 10
   ```

3. Speichern Sie die Datei und starten Sie Prometheus neu:
   ```bash
   systemctl restart prometheus
   ```

4. Überprüfen Sie im Prometheus-Webinterface unter "Alerts", ob der Alert ausgelöst wurde
5. Nach etwa 5 Minuten (der in der Regel definierten Zeit) sollte der Alert von "pending" zu "firing" wechseln
6. Überprüfen Sie im Alertmanager-Webinterface, ob der Alert empfangen wurde
7. Überprüfen Sie Ihren E-Mail-Posteingang, ob eine Benachrichtigung gesendet wurde

## Zusätzliche Hinweise

- Der Alertmanager bietet verschiedene Benachrichtigungsmethoden, darunter E-Mail, Slack, PagerDuty, OpsGenie und mehr
- Die Konfiguration des Alertmanagers kann angepasst werden, um Alerts zu gruppieren, zu unterdrücken oder weiterzuleiten
- Mit dem `amtool` können Sie den Alertmanager von der Kommandozeile aus verwalten:
  ```bash
  amtool alert
  ```
- Für Produktionsumgebungen sollten Sie die Sicherheit verbessern, indem Sie TLS-Verschlüsselung und Authentifizierung einrichten
- Die Alerting-Regeln können angepasst werden, um spezifische Anforderungen zu erfüllen, z.B. unterschiedliche Schwellenwerte für verschiedene Systeme
- Alerts können mit Labels versehen werden, um sie zu kategorisieren und unterschiedlich zu behandeln
- Der Alertmanager kann so konfiguriert werden, dass er Alerts nur während bestimmter Zeiten sendet oder an unterschiedliche Empfänger weiterleitet
