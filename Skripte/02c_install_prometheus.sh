#!/usr/bin/env bash
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Dieses Skript muss als root ausgeführt werden. Bitte mit sudo starten."
  exit 1
fi

echo "[INFO] Installiere Prometheus..."

# Installation von Prometheus
PR_VERSION="2.54.1"
PR_ARCHIVE="prometheus-${PR_VERSION}.linux-amd64.tar.gz"
PR_URL="https://github.com/prometheus/prometheus/releases/download/v${PR_VERSION}/${PR_ARCHIVE}"

# Prüfe, ob Prometheus bereits installiert ist
if [ -f /usr/local/bin/prometheus ]; then
  INSTALLED_VERSION=$(/usr/local/bin/prometheus --version 2>&1 | grep prometheus | awk '{print $3}' || echo "unknown")
  echo "[INFO] Prometheus ist bereits installiert (Version: $INSTALLED_VERSION)."

  if systemctl is-active --quiet prometheus; then
    echo "[INFO] Prometheus-Dienst läuft bereits."
  else
    echo "[INFO] Starte Prometheus-Dienst..."
    systemctl start prometheus
  fi
  exit 0
fi

# Download nur wenn Archiv nicht bereits existiert
if [ ! -f "$PR_ARCHIVE" ]; then
  echo "[INFO] Lade Prometheus herunter..."
  wget "$PR_URL"
fi

# Entpacke nur wenn Verzeichnis nicht existiert
if [ ! -d "prometheus-${PR_VERSION}.linux-amd64" ]; then
  echo "[INFO] Entpacke Prometheus..."
  tar -xzf "$PR_ARCHIVE"
fi

echo "[INFO] Installiere Prometheus Binaries..."
mkdir -p /etc/prometheus
mkdir -p /var/lib/prometheus
id -u prometheus >/dev/null 2>&1 || useradd --no-create-home --shell /bin/false prometheus
chown prometheus:prometheus /var/lib/prometheus

cp "prometheus-${PR_VERSION}.linux-amd64/prometheus" /usr/local/bin/
cp "prometheus-${PR_VERSION}.linux-amd64/promtool" /usr/local/bin/

# Kopiere Konfiguration nur wenn sie noch nicht existiert
if [ ! -d /etc/prometheus/consoles ]; then
  cp -r "prometheus-${PR_VERSION}.linux-amd64/consoles" /etc/prometheus
fi
if [ ! -d /etc/prometheus/console_libraries ]; then
  cp -r "prometheus-${PR_VERSION}.linux-amd64/console_libraries" /etc/prometheus
fi
if [ ! -f /etc/prometheus/prometheus.yml ]; then
  cp "prometheus-${PR_VERSION}.linux-amd64/prometheus.yml" /etc/prometheus/
fi

chown -R prometheus:prometheus /etc/prometheus
chown prometheus:prometheus /usr/local/bin/prometheus
chown prometheus:prometheus /usr/local/bin/promtool

# Aufräumen
rm -rf "prometheus-${PR_VERSION}.linux-amd64" "$PR_ARCHIVE"

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

echo "[INFO] Starte Prometheus-Dienst..."
systemctl daemon-reload
systemctl start prometheus
systemctl enable prometheus

echo "[INFO] Prometheus erfolgreich installiert."
