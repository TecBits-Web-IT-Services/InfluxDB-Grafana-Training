#!/usr/bin/env bash
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Dieses Skript muss als root ausgeführt werden. Bitte mit sudo starten."
  exit 1
fi

echo "[INFO] Installiere Docker..."

# Prüfe, ob Docker bereits installiert ist
if command -v docker >/dev/null 2>&1; then
  echo "[INFO] Docker ist bereits installiert."
  if systemctl is-active --quiet docker; then
    echo "[INFO] Docker-Dienst läuft bereits."
  else
    echo "[INFO] Starte Docker-Dienst..."
    systemctl start docker
  fi
  exit 0
fi

# Add Docker's official GPG key:
echo "[INFO] Installiere Voraussetzungen..."
apt install -y ca-certificates curl

echo "[INFO] Füge Docker Repository hinzu..."
install -m 0755 -d /etc/apt/keyrings

if [ ! -f /etc/apt/keyrings/docker.asc ]; then
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  chmod a+r /etc/apt/keyrings/docker.asc
fi

if [ ! -f /etc/apt/sources.list.d/docker.sources ]; then
  tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF
fi

echo "[INFO] Installiere Docker..."
apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "[INFO] Starte Docker-Dienst..."
systemctl start docker
systemctl enable docker || true

echo "[INFO] Docker erfolgreich installiert."