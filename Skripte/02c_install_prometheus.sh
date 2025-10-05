#!/usr/bin/env bash
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Dieses Skript muss als root ausgeführt werden. Bitte mit sudo starten."
  exit 1
fi

# Installation von Prometheus
PR_VERSION="2.46.0"
PR_ARCHIVE="prometheus-${PR_VERSION}.linux-amd64.tar.gz"
PR_URL="https://github.com/prometheus/prometheus/releases/download/v${PR_VERSION}/${PR_ARCHIVE}"

wget "$PR_URL"
tar -xvf "$PR_ARCHIVE"
mkdir -p /etc/prometheus
mkdir -p /var/lib/prometheus
id -u prometheus >/dev/null 2>&1 || useradd --no-create-home --shell /bin/false prometheus
chown prometheus:prometheus /var/lib/prometheus
cp "prometheus-${PR_VERSION}.linux-amd64/prometheus" /usr/local/bin/
cp "prometheus-${PR_VERSION}.linux-amd64/promtool" /usr/local/bin/
cp -r "prometheus-${PR_VERSION}.linux-amd64/consoles" /etc/prometheus
cp -r "prometheus-${PR_VERSION}.linux-amd64/console_libraries" /etc/prometheus
cp "prometheus-${PR_VERSION}.linux-amd64/prometheus.yml" /etc/prometheus/
chown -R prometheus:prometheus /etc/prometheus
chown prometheus:prometheus /usr/local/bin/prometheus
chown prometheus:prometheus /usr/local/bin/promtool

cat > /etc/systemd/system/prometheus.service << 'EOF'
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file /etc/prometheus/prometheus.yml \
    --storage.tsdb.path /var/lib/prometheus/ \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl start prometheus
systemctl enable prometheus
