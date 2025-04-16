# Lösungsblatt: Prometheus - Erfassung von Leistungsmetriken mit Node Exporter

Dieses Lösungsblatt enthält die Lösungen für die Aufgaben aus dem Aufgabenfeld 6: Erfassung von Leistungsmetriken mit Node Exporter.

## Aufgabe 1: Installation von Node Exporter über die Linux Shell

### Lösung:

```bash
# zum root-Benutzer wechseln
sudo su

# Herunterladen von Node Exporter
wget https://github.com/prometheus/node_exporter/releases/download/v1.9.1/node_exporter-1.9.1.linux-amd64.tar.gz

# Entpacken des Archivs
tar -xvf node_exporter-1.9.1.linux-amd64.tar.gz

# Kopieren der Binärdatei
cp node_exporter-1.9.1.linux-amd64/node_exporter /usr/local/bin/

# Erstellen eines Node-Exporter-Benutzers
useradd --no-create-home --shell /bin/false node_exporter

# Setzen der Berechtigungen
chown node_exporter:node_exporter /usr/local/bin/node_exporter
```

## Aufgabe 2: Konfiguration von Node Exporter als Systemdienst

### Lösung:

```bash
# Erstellen der Systemd-Service-Datei
cat > /etc/systemd/system/node_exporter.service << EOF
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF

# Neuladen der Systemd-Konfiguration
systemctl daemon-reload

# Starten des Node-Exporter-Dienstes
systemctl start node_exporter

# Aktivieren des Node-Exporter-Dienstes für den Autostart
systemctl enable node_exporter

# Überprüfen des Status des Node-Exporter-Dienstes
systemctl status node_exporter
```

## Aufgabe 3: Überprüfen der Node Exporter Installation

### Lösung:

```bash
# Testen, ob Node Exporter Metriken bereitstellt
curl http://localhost:9100/metrics | head
```

Sie sollten eine Ausgabe mit Metriken sehen, die mit `# HELP` und `# TYPE` beginnen, gefolgt von den eigentlichen Metrikdaten. Dies bestätigt, dass Node Exporter korrekt läuft und Metriken bereitstellt.

## Aufgabe 4: Konfiguration von Prometheus zur Erfassung von Node Exporter Metriken

### Lösung:

1. Öffnen Sie die Prometheus-Konfigurationsdatei zum Bearbeiten:
   ```bash
   nano /etc/prometheus/prometheus.yml
   ```

2. Fügen Sie einen neuen Job für Node Exporter im Abschnitt `scrape_configs` hinzu:
   ```yaml
   scrape_configs:
     - job_name: 'prometheus'
       static_configs:
         - targets: ['localhost:9090']
     
     - job_name: 'node_exporter'
       static_configs:
         - targets: ['localhost:9100']
   ```

3. Speichern Sie die Datei (bei nano: STRG+O, ENTER, STRG+X)

4. Starten Sie Prometheus neu, um die Änderungen zu übernehmen:
   ```bash
   systemctl restart prometheus
   ```

## Aufgabe 5: Überprüfen der Node Exporter Integration in Prometheus

### Lösung:

1. Öffnen Sie das Prometheus-Webinterface unter http://localhost:9090
2. Navigieren Sie zu Status > Targets
3. Überprüfen Sie, ob Node Exporter als Ziel erkannt wird und der Status "UP" ist
4. Wenn der Status "UP" ist, bedeutet dies, dass Prometheus erfolgreich Metriken von Node Exporter sammelt

## Aufgabe 6: Erkunden der verfügbaren Systemmetriken

### Lösung:

1. Öffnen Sie das Prometheus-Webinterface unter http://localhost:9090/graph
2. Testen Sie die folgenden PromQL-Abfragen, um verschiedene Systemmetriken zu erkunden:

   a. CPU-Auslastung in Prozent (100 - Leerlauf):
   ```
   100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[1m])) * 100)
   ```

   b. Freier Speicher in Prozent:
   ```
   100 * node_memory_MemFree_bytes / node_memory_MemTotal_bytes
   ```

   c. Festplattennutzung in Prozent:
   ```
   100 - ((node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100)
   ```

   d. Netzwerkverkehr in MB/s:
   ```
   rate(node_network_receive_bytes_total{device="eth0"}[1m]) / 1024 / 1024
   ```

3. Klicken Sie auf "Execute", um die Abfragen auszuführen und die Ergebnisse zu sehen
4. Wechseln Sie zwischen "Table" und "Graph" Ansicht, um die Daten in verschiedenen Formaten zu betrachten

## Aufgabe 7: Anpassen der Node Exporter Konfiguration

### Lösung:

1. Bearbeiten Sie die Node-Exporter-Service-Datei:
   ```bash
   nano /etc/systemd/system/node_exporter.service
   ```

2. Ändern Sie die `ExecStart`-Zeile, um den Textfile-Collector zu aktivieren:
   ```
   ExecStart=/usr/local/bin/node_exporter --collector.textfile.directory=/var/lib/node_exporter/textfile_collector
   ```

3. Speichern Sie die Datei (bei nano: STRG+O, ENTER, STRG+X)

4. Erstellen Sie das Verzeichnis für den Textfile-Collector:
   ```bash
   mkdir -p /var/lib/node_exporter/textfile_collector
   chown -R node_exporter:node_exporter /var/lib/node_exporter
   ```

5. Laden Sie die Systemd-Konfiguration neu und starten Sie Node Exporter neu:
   ```bash
   systemctl daemon-reload
   systemctl restart node_exporter
   ```

## Aufgabe 8: Erstellen eines benutzerdefinierten Metrics mit dem Textfile-Collector

### Lösung:

1. Erstellen Sie ein Skript zur Erfassung der SSH-Verbindungen:
   ```bash
   cat > /usr/local/bin/ssh_connections.sh << 'EOF'
   #!/bin/bash
   count=$(netstat -tn | grep :22 | grep -e ESTABLISHED -e VERBUNDEN | wc -l)
   echo "# HELP ssh_connections_total Current number of SSH connections"
   echo "# TYPE ssh_connections_total gauge"
   echo "ssh_connections_total $count"
   EOF
   ```

2. Machen Sie das Skript ausführbar:
   ```bash
   chmod +x /usr/local/bin/ssh_connections.sh
   ```

3. Erstellen Sie einen Cron-Job, um das Skript regelmäßig auszuführen:
   ```bash
   cat > /etc/cron.d/node_exporter_textfile << 'EOF'
   */1 * * * * root /usr/local/bin/ssh_connections.sh > /var/lib/node_exporter/textfile_collector/ssh_connections.prom
   EOF
   ```

4. Führen Sie das Skript einmal manuell aus, um die erste Metrik zu erstellen:
   ```bash
   /usr/local/bin/ssh_connections.sh > /var/lib/node_exporter/textfile_collector/ssh_connections.prom
   ```

5. Überprüfen Sie, ob die neue Metrik in Prometheus verfügbar ist:
   - Öffnen Sie http://localhost:9090/graph
   - Geben Sie `ssh_connections_total` in das Abfragefeld ein
   - Klicken Sie auf "Execute"

## Zusätzliche Hinweise

- Node Exporter stellt standardmäßig viele Collector bereit, die verschiedene Aspekte des Systems überwachen
- Mit dem Parameter `--collector.disable-defaults` können Sie alle Standard-Collector deaktivieren und nur die gewünschten aktivieren
- Eine vollständige Liste der verfügbaren Collector finden Sie in der [Node Exporter-Dokumentation](https://github.com/prometheus/node_exporter)
- Der Textfile-Collector ist besonders nützlich, um benutzerdefinierte Metriken zu erstellen, die nicht direkt von Node Exporter erfasst werden
- Für Produktionsumgebungen sollten Sie die Sicherheit verbessern, indem Sie TLS-Verschlüsselung und Authentifizierung einrichten
- Die Metriken von Node Exporter können in Grafana visualisiert werden, um ansprechende Dashboards zu erstellen
