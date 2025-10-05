#!/usr/bin/env bash

mkdir -p /etc/prometheus/rules

# Prometheus so konfigurieren, dass Prometheus und Node Exporter gescraped werden und der Alertmanager angebunden ist
if [ -f /etc/prometheus/prometheus.yml ]; then
  cp /etc/prometheus/prometheus.yml /etc/prometheus/prometheus.yml.bak || true
fi
cat > /etc/prometheus/prometheus.yml << 'EOF'
# my global config
global:
  scrape_interval: 15s # Set the scrape interval to every 15 seconds. Default is every 1 minute.
  evaluation_interval: 15s # Evaluate rules every 15 seconds. The default is every 1 minute.
  # scrape_timeout is set to the global default (10s).

# Alertmanager configuration
alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093

# Load rules once and periodically evaluate them according to the global 'evaluation_interval'.
rule_files:
  - "/etc/prometheus/rules/*.yml"

# A scrape configuration containing exactly one endpoint to scrape:
# Here it's Prometheus itself.
scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

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

EOF
chown prometheus:prometheus /etc/prometheus/prometheus.yml || true

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

chown prometheus:prometheus /etc/prometheus/rules/node_alerts.yml

systemctl restart prometheus || true