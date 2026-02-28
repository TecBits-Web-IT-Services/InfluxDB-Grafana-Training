#!/usr/bin/env bash
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Dieses Skript muss als root ausgeführt werden. Bitte mit sudo starten."
  exit 1
fi

echo "[INFO] Richte InfluxDB v3 Explorer Container ein..."

# Prüfe, ob Docker installiert ist
if ! command -v docker >/dev/null 2>&1; then
  echo "[ERROR] Docker ist nicht installiert. Bitte zuerst Docker installieren."
  exit 1
fi

# Prüfe, ob Container bereits existiert
if docker ps -a --format '{{.Names}}' | grep -q "^influxdb3-explorer$"; then
  echo "[INFO] Container 'influxdb3-explorer' existiert bereits."

  # Prüfe, ob Container läuft
  if docker ps --format '{{.Names}}' | grep -q "^influxdb3-explorer$"; then
    echo "[INFO] Container 'influxdb3-explorer' läuft bereits."
  else
    echo "[INFO] Starte Container 'influxdb3-explorer'..."
    docker start influxdb3-explorer
  fi
  exit 0
fi

# Setup influxDB v3 Explorer
echo "[INFO] Erstelle Verzeichnisse für InfluxDB v3 Explorer..."
mkdir -p /docker/influxdb3-explorer/db
mkdir -p /docker/influxdb3-explorer/config

# Extrahiere Admin-Token aus der Token-Datei
TOKEN_FILE="/home/student/Schreibtisch/admin-token.txt"
ADMIN_TOKEN=""

if [ -f "$TOKEN_FILE" ]; then
  echo "[INFO] Lese Admin-Token aus $TOKEN_FILE..."
  # Extrahiere Token aus der Zeile "Token: apiv3_..."
  ADMIN_TOKEN=$(grep "^Token:" "$TOKEN_FILE" | awk '{print $2}')

  if [ -z "$ADMIN_TOKEN" ]; then
    echo "[WARN] Konnte Token nicht aus $TOKEN_FILE extrahieren. Verwende Platzhalter."
    ADMIN_TOKEN="ADMIN_TOKEN"
  else
    echo "[INFO] Admin-Token erfolgreich gelesen."
  fi
else
  echo "[WARN] Token-Datei $TOKEN_FILE nicht gefunden. Verwende Platzhalter."
  ADMIN_TOKEN="ADMIN_TOKEN"
fi

# Erstelle Konfigurationsdatei mit Token
cat > /docker/influxdb3-explorer/config/config.json << EOF
{
  "DEFAULT_INFLUX_SERVER": "http://172.17.0.1:8181",
  "DEFAULT_API_TOKEN": "${ADMIN_TOKEN}",
  "DEFAULT_SERVER_NAME": "Local InfluxDB 3"
}
EOF

echo "[INFO] Konfigurationsdatei erstellt."

echo "[INFO] Starte InfluxDB v3 Explorer Container..."
docker run --detach \
--name influxdb3-explorer \
--pull always \
--publish 8888:80 \
--volume /docker/influxdb3-explorer/db:/db:rw \
--volume /docker/influxdb3-explorer/config:/app-root/config:ro \
--env SESSION_SECRET_KEY=$(openssl rand -hex 32) \
--restart unless-stopped \
influxdata/influxdb3-ui:1.6.2 \
--mode=admin

echo "[INFO] InfluxDB v3 Explorer Container erfolgreich gestartet."