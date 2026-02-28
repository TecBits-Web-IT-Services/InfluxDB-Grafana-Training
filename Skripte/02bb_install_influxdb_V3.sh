#!/usr/bin/env bash
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Dieses Skript muss als root ausgeführt werden. Bitte mit sudo starten."
  exit 1
fi

echo "[INFO] Installiere InfluxDB 3 Core..."

# Prüfe, ob InfluxDB 3 Core bereits installiert ist
if dpkg-query -W -f='${Status}' influxdb3-core 2>/dev/null | grep -q "install ok installed"; then
  echo "[INFO] InfluxDB 3 Core ist bereits installiert."
  if systemctl is-active --quiet influxdb3-core; then
    echo "[INFO] InfluxDB3-Dienst läuft bereits."
  else
    echo "[INFO] Starte InfluxDB3-Dienst..."
    systemctl start influxdb3-core
  fi

  # Prüfe, ob Token-Datei bereits existiert
  if [ -f /home/student/Schreibtisch/admin-token.txt ]; then
    echo "[INFO] Admin-Token existiert bereits."
  else
    echo "[INFO] Erstelle Admin-Token..."
    influxdb3 create token --admin > /home/student/Schreibtisch/admin-token.txt
    chown student:student /home/student/Schreibtisch/admin-token.txt
  fi
  exit 0
fi

# Installation von InfluxDB 3 Core
echo "[INFO] Füge InfluxDB Repository hinzu..."
mkdir -p /usr/share/keyrings

if [ ! -f /usr/share/keyrings/influxdata-archive.gpg ]; then
  curl --silent --location -O https://repos.influxdata.com/influxdata-archive.key
  gpg --show-keys --with-fingerprint --with-colons ./influxdata-archive.key 2>&1 \
  | grep -q '^fpr:\+24C975CBA61A024EE1B631787C3D57159FC2F927:$' \
  && cat influxdata-archive.key \
  | gpg --dearmor \
  | tee /usr/share/keyrings/influxdata-archive.gpg > /dev/null
  rm -f influxdata-archive.key
fi

if [ ! -f /etc/apt/sources.list.d/influxdata.list ]; then
  echo 'deb [signed-by=/usr/share/keyrings/influxdata-archive.gpg] https://repos.influxdata.com/debian stable main' \
  | tee /etc/apt/sources.list.d/influxdata.list
fi

echo "[INFO] Installiere InfluxDB 3 Core..."
apt-get update && apt-get install -y influxdb3-core

echo "[INFO] Starte InfluxDB3-Dienst..."
systemctl start influxdb3-core
systemctl enable influxdb3-core || true

# Erstelle Admin-Token (nur wenn noch nicht vorhanden)
if [ ! -f /home/student/Schreibtisch/admin-token.txt ]; then
  echo "[INFO] Erstelle Admin-Token..."
  influxdb3 create token --admin > /home/student/Schreibtisch/admin-token.txt
  chown student:student /home/student/Schreibtisch/admin-token.txt
fi

echo "[INFO] InfluxDB 3 Core erfolgreich installiert."