#!/usr/bin/env bash
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Dieses Skript muss als root ausgeführt werden. Bitte mit sudo starten."
  exit 1
fi

# Installation von Node Exporter
NE_VERSION="1.9.1"
NE_ARCHIVE="node_exporter-${NE_VERSION}.linux-amd64.tar.gz"
NE_URL="https://github.com/prometheus/node_exporter/releases/download/v${NE_VERSION}/${NE_ARCHIVE}"

wget "$NE_URL"
tar -xvf "$NE_ARCHIVE"
cp "node_exporter-${NE_VERSION}.linux-amd64/node_exporter" /usr/local/bin/
id -u node_exporter >/dev/null 2>&1 || useradd --no-create-home --shell /bin/false node_exporter
chown node_exporter:node_exporter /usr/local/bin/node_exporter

cat > /etc/systemd/system/node_exporter.service << 'EOF'
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

systemctl daemon-reload
systemctl start node_exporter
systemctl enable node_exporter
