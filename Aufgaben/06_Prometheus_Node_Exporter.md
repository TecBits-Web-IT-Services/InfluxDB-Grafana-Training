# Prometheus - Aufgabenfeld 6 : Erfassung von Leistungsmetriken mit Node Exporter

## Installation und Konfiguration von Node Exporter zur Überwachung von Systemmetriken

### 1. Installation von Node Exporter über die Linux Shell

```bash
# zum root-Benutzer wechseln
sudo su

# Herunterladen von Node Exporter (aktuelle stabile Version)
wget https://github.com/prometheus/node_exporter/releases/download/v1.8.2/node_exporter-1.8.2.linux-amd64.tar.gz

# Entpacken des Archivs
tar -xvf node_exporter-1.8.2.linux-amd64.tar.gz

# Kopieren der Binärdatei
cp node_exporter-1.8.2.linux-amd64/node_exporter /usr/local/bin/

# Erstellen eines Node-Exporter-Benutzers
useradd --no-create-home --shell /bin/false node_exporter

# Setzen der Berechtigungen
chown node_exporter:node_exporter /usr/local/bin/node_exporter
```

### 2. Konfiguration von Node Exporter als Systemdienst

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

### 3. Überprüfen der Node Exporter Installation

```bash
# Testen, ob Node Exporter Metriken bereitstellt
curl http://localhost:9100/metrics
```
Sollten Sie eine andere Umgebung als die durch die GFU Bereitgestellte verwenden müssen Sie gegebenenfalls einen anderen Hostname/IP anstatt von "localhost" verwenden

Sie sollten eine Ausgabe mit Metriken sehen, die mit `# HELP` und `# TYPE` beginnen, gefolgt von den eigentlichen Metrikdaten.

### 4. Konfiguration von Prometheus zur Erfassung von Node Exporter Metriken

Bearbeiten Sie die Prometheus-Konfigurationsdatei, um Node Exporter als Ziel hinzuzufügen:

```bash
# Bearbeiten der Prometheus-Konfigurationsdatei
nano /etc/prometheus/prometheus.yml
```

Fügen Sie einen neuen Job für Node Exporter im Abschnitt `scrape_configs` hinzu:

```yaml
scrape_configs:
  - job_name: 'node_exporter_host1'
    static_configs:
      - targets: ['localhost:9100']
    relabel_configs:
      - source_labels: ['__address__']
        target_label: 'instance'
        replacement: 'Host-1'

  - job_name: 'node_exporter_host2'
    static_configs:
      - targets: ['localhost:9100']
    relabel_configs:
      - source_labels: ['__address__']
        target_label: 'instance'
        replacement: 'Host-2'
```

> **Erklärung**:
> - `job_name`: Definiert den Namen des Scraping-Jobs (hier getrennt für `host1` und `host2`)
> - `targets`: Gibt die Endpunkte an, von denen Metriken abgerufen werden
> - `relabel_configs`: Erlaubt die dynamische Anpassung von Labels. Hier wird das `instance` Label, das standardmäßig die IP:Port-Kombination enthält, durch einen sprechenden Namen (`Host-1`, `Host-2`) ersetzt.
>
> **Best Practice**: Wenn Sie mehrere Server mit derselben Konfiguration überwachen möchten, können Sie diese auch innerhalb eines Jobs zusammenfassen:
>
> ```yaml
> scrape_configs:
>   - job_name: 'node'
>     static_configs:
>       - targets: ['server1.example.com:9100']
>         labels:
>           instance: 'Host-1'
>       - targets: ['server2.example.com:9100']
>         labels:
>           instance: 'Host-2'
> ```

Speichern Sie die Datei und starten Sie Prometheus neu:

```bash
# Neustarten des Prometheus-Dienstes
systemctl restart prometheus
```

### 5. Überprüfen der Node Exporter Integration in Prometheus

- Öffnen Sie das Prometheus-Webinterface unter [http://localhost:9090](http://localhost:9090)
  - Sollten Sie eine andere Umgebung als die durch die GFU Bereitgestellte verwenden müssen Sie gegebenenfalls einen anderen Hostname/IP anstatt von "localhost" verwenden 
- Navigieren Sie zu Status > Targets, um zu überprüfen, ob Node Exporter als Ziel erkannt wird
- Der Status sollte "UP" sein

### 6. Erkunden der verfügbaren Systemmetriken

Node Exporter stellt eine Vielzahl von Systemmetriken bereit. Hier sind einige wichtige Kategorien:

- CPU-Auslastung: `node_cpu_seconds_total`
- Speichernutzung: `node_memory_MemTotal_bytes`, `node_memory_MemFree_bytes`
- Festplattennutzung: `node_filesystem_avail_bytes`, `node_filesystem_size_bytes`
- Netzwerkverkehr: `node_network_receive_bytes_total`, `node_network_transmit_bytes_total`
- Systemlast: `node_load1`, `node_load5`, `node_load15`

Testen Sie einige dieser Metriken im Prometheus-Webinterface:

1. Öffnen Sie [http://localhost:9090/graph](http://localhost:9090/graph)
2. Geben Sie eine der folgenden PromQL-Abfragen ein und klicken Sie auf "Execute":

```
# CPU-Auslastung in Prozent (100 - Leerlauf)
100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[1m])) * 100)

# Freier Speicher in Prozent
100 * node_memory_MemFree_bytes / node_memory_MemTotal_bytes

# Festplattennutzung in Prozent
100 - ((node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100)

# Netzwerkverkehr in MB/s (Empfang)
rate(node_network_receive_bytes_total{device!~"lo|veth.*"}[1m]) / 1024 / 1024

# Netzwerkverkehr in MB/s (Senden)
rate(node_network_transmit_bytes_total{device!~"lo|veth.*"}[1m]) / 1024 / 1024
```

> **Hinweis zu Netzwerk-Interfaces**: Die Query filtert das Loopback-Interface (`lo`) und virtuelle Interfaces (`veth.*`) heraus. Moderne Ubuntu-Systeme verwenden oft `enp*` oder `ens*` statt `eth0` für Netzwerk-Interfaces.

### 7. Anpassen der Node Exporter Konfiguration

Node Exporter kann mit verschiedenen Flags gestartet werden, um bestimmte Collector zu aktivieren oder zu deaktivieren. Bearbeiten Sie die Systemd-Service-Datei:

```bash
# Bearbeiten der Node-Exporter-Service-Datei
nano /etc/systemd/system/node_exporter.service
```

Ändern Sie die `ExecStart`-Zeile, um beispielsweise den Textfile-Collector zu aktivieren:

```
ExecStart=/usr/local/bin/node_exporter --collector.textfile.directory=/var/lib/node_exporter/textfile_collector
```

Erstellen Sie das Verzeichnis für den Textfile-Collector:

```bash
# Erstellen des Verzeichnisses für den Textfile-Collector
mkdir -p /var/lib/node_exporter/textfile_collector
chown -R node_exporter:node_exporter /var/lib/node_exporter
```

Starten Sie Node Exporter neu:

```bash
# Neuladen der Systemd-Konfiguration
systemctl daemon-reload

# Neustarten des Node-Exporter-Dienstes
systemctl restart node_exporter
```

### 8. Erstellen eines benutzerdefinierten Metrics mit dem Textfile-Collector

Der Textfile-Collector ermöglicht es, benutzerdefinierte Metriken zu erstellen. Hier ist ein Beispiel für ein Skript, das die Anzahl der SSH-Verbindungen zählt:

```bash
# Erstellen eines Skripts zur Erfassung der SSH-Verbindungen
cat > /usr/local/bin/ssh_connections.sh << 'EOF'
#!/bin/bash

# Temporäre Datei für atomare Schreiboperationen
TEMP_FILE="/var/lib/node_exporter/textfile_collector/ssh_connections.prom.$$"
PROM_FILE="/var/lib/node_exporter/textfile_collector/ssh_connections.prom"

# Fehlerbehandlung
set -e

# Zähle etablierte SSH-Verbindungen (Port 22)
# ss ist der moderne Ersatz für netstat
count=$(ss -tn state established '( sport = :22 or dport = :22 )' | grep -v "^State" | wc -l)

# Prometheus-Format schreiben
{
  echo "# HELP ssh_connections_total Current number of established SSH connections"
  echo "# TYPE ssh_connections_total gauge"
  echo "ssh_connections_total $count"
} > "$TEMP_FILE"

# Atomares Verschieben der Datei
mv "$TEMP_FILE" "$PROM_FILE"
EOF

# Ausführbar machen
chmod +x /usr/local/bin/ssh_connections.sh

# Berechtigungen setzen
chown root:root /usr/local/bin/ssh_connections.sh

# Erstellen eines Cron-Jobs, der das Skript regelmäßig ausführt (alle 2 Minuten)
(crontab -l 2>/dev/null; echo "*/2 * * * * /usr/local/bin/ssh_connections.sh 2>&1 | logger -t ssh_connections") | crontab -
```

Nach zwei Minuten sollten Sie die neue Metrik `ssh_connections_total` in Prometheus sehen können.

> Hinweise:
> - Node Exporter läuft standardmäßig auf Port 9100
> - Die vollständige Liste der verfügbaren Collector finden Sie in der [Node Exporter-Dokumentation](https://github.com/prometheus/node_exporter)
> - Für die Überwachung spezifischer Anwendungen gibt es spezialisierte Exporter, z.B. für MySQL, PostgreSQL, Redis, etc.
> - Der Textfile-Collector ist nützlich, um benutzerdefinierte Metriken zu erstellen, die nicht direkt von Node Exporter erfasst werden
