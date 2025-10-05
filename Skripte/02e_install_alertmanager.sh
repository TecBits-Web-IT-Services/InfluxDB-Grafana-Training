#!/usr/bin/env bash
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Dieses Skript muss als root ausgeführt werden. Bitte mit sudo starten."
  exit 1
fi

# Installation von Alertmanager
AM_VERSION="0.26.0"
AM_ARCHIVE="alertmanager-${AM_VERSION}.linux-amd64.tar.gz"
AM_URL="https://github.com/prometheus/alertmanager/releases/download/v${AM_VERSION}/${AM_ARCHIVE}"

wget "$AM_URL"
tar -xvf "$AM_ARCHIVE"
mkdir -p /etc/alertmanager
mkdir -p /var/lib/alertmanager
cp "alertmanager-${AM_VERSION}.linux-amd64/alertmanager" /usr/local/bin/
cp "alertmanager-${AM_VERSION}.linux-amd64/amtool" /usr/local/bin/
cp "alertmanager-${AM_VERSION}.linux-amd64/alertmanager.yml" /etc/alertmanager/
id -u alertmanager >/dev/null 2>&1 || useradd --no-create-home --shell /bin/false alertmanager
chown -R alertmanager:alertmanager /etc/alertmanager
chown -R alertmanager:alertmanager /var/lib/alertmanager
chown alertmanager:alertmanager /usr/local/bin/alertmanager
chown alertmanager:alertmanager /usr/local/bin/amtool

cat > /etc/systemd/system/alertmanager.service << 'EOF'
[Unit]
Description=Alertmanager
Wants=network-online.target
After=network-online.target

[Service]
User=alertmanager
Group=alertmanager
Type=simple
ExecStart=/usr/local/bin/alertmanager \
    --config.file=/etc/alertmanager/alertmanager.yml \
    --storage.path=/var/lib/alertmanager

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl start alertmanager
systemctl enable alertmanager
