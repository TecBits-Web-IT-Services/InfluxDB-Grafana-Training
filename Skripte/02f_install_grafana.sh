#!/usr/bin/env bash
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Dieses Skript muss als root ausgeführt werden. Bitte mit sudo starten."
  exit 1
fi

echo "[INFO] Installiere Grafana OSS..."

# Prüfe, ob Grafana bereits installiert ist
if dpkg-query -W -f='${Status}' grafana 2>/dev/null | grep -q "install ok installed"; then
  echo "[INFO] Grafana ist bereits installiert."
  if systemctl is-active --quiet grafana-server; then
    echo "[INFO] Grafana-Dienst läuft bereits."
  else
    echo "[INFO] Starte Grafana-Dienst..."
    systemctl start grafana-server
  fi
  exit 0
fi

# Installation von Grafana OSS
echo "[INFO] Füge Grafana Repository hinzu..."
mkdir -p /etc/apt/keyrings/

if [ ! -f /etc/apt/keyrings/grafana.gpg ]; then
  wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | tee /etc/apt/keyrings/grafana.gpg > /dev/null
fi

if [ ! -f /etc/apt/sources.list.d/grafana.list ]; then
  echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | tee /etc/apt/sources.list.d/grafana.list
fi

echo "[INFO] Installiere Grafana..."
apt-get update && apt-get install -y grafana

echo "[INFO] Starte Grafana-Dienst..."
systemctl start grafana-server
systemctl enable grafana-server || true

echo "[INFO] Grafana erfolgreich installiert."
