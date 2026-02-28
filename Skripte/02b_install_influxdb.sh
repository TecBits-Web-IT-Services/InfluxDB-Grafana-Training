#!/usr/bin/env bash
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Dieses Skript muss als root ausgeführt werden. Bitte mit sudo starten."
  exit 1
fi

echo "[INFO] Installiere InfluxDB 2..."

# Prüfe, ob InfluxDB 2 bereits installiert ist
if dpkg -l | grep -q "^ii  influxdb2 "; then
  echo "[INFO] InfluxDB 2 ist bereits installiert."
  if systemctl is-active --quiet influxdb; then
    echo "[INFO] InfluxDB-Dienst läuft bereits."
  else
    echo "[INFO] Starte InfluxDB-Dienst..."
    systemctl start influxdb
  fi
  exit 0
fi

# Installation von InfluxDB 2
echo "[INFO] Füge InfluxDB Repository hinzu..."
mkdir -p /etc/apt/keyrings

if [ ! -f /etc/apt/keyrings/influxdata-archive.gpg ]; then
  curl --silent --location -O https://repos.influxdata.com/influxdata-archive.key
  gpg --show-keys --with-fingerprint --with-colons ./influxdata-archive.key 2>&1 \
  | grep -q '^fpr:\+24C975CBA61A024EE1B631787C3D57159FC2F927:$' \
  && cat influxdata-archive.key \
  | gpg --dearmor \
  | tee /etc/apt/keyrings/influxdata-archive.gpg > /dev/null
  rm -f influxdata-archive.key
fi

if [ ! -f /etc/apt/sources.list.d/influxdata.list ]; then
  echo 'deb [signed-by=/etc/apt/keyrings/influxdata-archive.gpg] https://repos.influxdata.com/debian stable main' \
  | tee /etc/apt/sources.list.d/influxdata.list
fi

echo "[INFO] Installiere InfluxDB 2..."
apt-get update && apt-get install -y influxdb2

echo "[INFO] Starte InfluxDB-Dienst..."
systemctl start influxdb
systemctl enable influxdb || true

echo "[INFO] InfluxDB 2 erfolgreich installiert."
