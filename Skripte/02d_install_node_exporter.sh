#!/usr/bin/env bash
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Dieses Skript muss als root ausgeführt werden. Bitte mit sudo starten."
  exit 1
fi

echo "[INFO] Installiere Node Exporter..."

# Installation von Node Exporter
NE_VERSION="1.9.1"
NE_ARCHIVE="node_exporter-${NE_VERSION}.linux-amd64.tar.gz"
NE_URL="https://github.com/prometheus/node_exporter/releases/download/v${NE_VERSION}/${NE_ARCHIVE}"

# Prüfe, ob Node Exporter bereits installiert ist
if [ -f /usr/local/bin/node_exporter ]; then
  echo "[INFO] Node Exporter ist bereits installiert."

  if systemctl is-active --quiet node_exporter; then
    echo "[INFO] Node Exporter-Dienst läuft bereits."
  else
    echo "[INFO] Starte Node Exporter-Dienst..."
    systemctl start node_exporter
  fi
  exit 0
fi

# Download nur wenn Archiv nicht bereits existiert
if [ ! -f "$NE_ARCHIVE" ]; then
  echo "[INFO] Lade Node Exporter herunter..."
  wget "$NE_URL"
fi

# Entpacke nur wenn Verzeichnis nicht existiert
if [ ! -d "node_exporter-${NE_VERSION}.linux-amd64" ]; then
  echo "[INFO] Entpacke Node Exporter..."
  tar -xzf "$NE_ARCHIVE"
fi

echo "[INFO] Installiere Node Exporter Binary..."
cp "node_exporter-${NE_VERSION}.linux-amd64/node_exporter" /usr/local/bin/
id -u node_exporter >/dev/null 2>&1 || useradd --no-create-home --shell /bin/false node_exporter
chown node_exporter:node_exporter /usr/local/bin/node_exporter

# Aufräumen
rm -rf "node_exporter-${NE_VERSION}.linux-amd64" "$NE_ARCHIVE"

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

echo "[INFO] Starte Node Exporter-Dienst..."
systemctl daemon-reload
systemctl start node_exporter
systemctl enable node_exporter

echo "[INFO] Node Exporter erfolgreich installiert."
