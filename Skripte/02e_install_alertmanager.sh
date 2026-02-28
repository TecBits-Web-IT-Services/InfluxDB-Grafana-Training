#!/usr/bin/env bash
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Dieses Skript muss als root ausgeführt werden. Bitte mit sudo starten."
  exit 1
fi

echo "[INFO] Installiere Alertmanager..."

# Installation von Alertmanager
AM_VERSION="0.26.0"
AM_ARCHIVE="alertmanager-${AM_VERSION}.linux-amd64.tar.gz"
AM_URL="https://github.com/prometheus/alertmanager/releases/download/v${AM_VERSION}/${AM_ARCHIVE}"

# Prüfe, ob Alertmanager bereits installiert ist
if [ -f /usr/local/bin/alertmanager ]; then
  echo "[INFO] Alertmanager ist bereits installiert."

  if systemctl is-active --quiet alertmanager; then
    echo "[INFO] Alertmanager-Dienst läuft bereits."
  else
    echo "[INFO] Starte Alertmanager-Dienst..."
    systemctl start alertmanager
  fi
  exit 0
fi

# Download nur wenn Archiv nicht bereits existiert
if [ ! -f "$AM_ARCHIVE" ]; then
  echo "[INFO] Lade Alertmanager herunter..."
  wget "$AM_URL"
fi

# Entpacke nur wenn Verzeichnis nicht existiert
if [ ! -d "alertmanager-${AM_VERSION}.linux-amd64" ]; then
  echo "[INFO] Entpacke Alertmanager..."
  tar -xzf "$AM_ARCHIVE"
fi

echo "[INFO] Installiere Alertmanager Binaries..."
mkdir -p /etc/alertmanager
mkdir -p /var/lib/alertmanager

cp "alertmanager-${AM_VERSION}.linux-amd64/alertmanager" /usr/local/bin/
cp "alertmanager-${AM_VERSION}.linux-amd64/amtool" /usr/local/bin/

# Kopiere Konfiguration nur wenn sie noch nicht existiert
if [ ! -f /etc/alertmanager/alertmanager.yml ]; then
  cp "alertmanager-${AM_VERSION}.linux-amd64/alertmanager.yml" /etc/alertmanager/
fi

id -u alertmanager >/dev/null 2>&1 || useradd --no-create-home --shell /bin/false alertmanager
chown -R alertmanager:alertmanager /etc/alertmanager
chown -R alertmanager:alertmanager /var/lib/alertmanager
chown alertmanager:alertmanager /usr/local/bin/alertmanager
chown alertmanager:alertmanager /usr/local/bin/amtool

# Aufräumen
rm -rf "alertmanager-${AM_VERSION}.linux-amd64" "$AM_ARCHIVE"

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

echo "[INFO] Starte Alertmanager-Dienst..."
systemctl daemon-reload
systemctl start alertmanager
systemctl enable alertmanager

echo "[INFO] Alertmanager erfolgreich installiert."
