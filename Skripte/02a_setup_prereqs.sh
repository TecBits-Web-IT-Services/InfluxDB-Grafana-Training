#!/usr/bin/env bash
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Dieses Skript muss als root ausgeführt werden. Bitte mit sudo starten."
  exit 1
fi

echo "[INFO] Installiere Voraussetzungen..."

# Prüfe, ob alle wichtigen Pakete bereits installiert sind
MISSING_PACKAGES=()
PACKAGES="curl nano mc htop net-tools wget gnupg2 software-properties-common stress openssh-server"

for pkg in $PACKAGES; do
  if ! dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"; then
    MISSING_PACKAGES+=("$pkg")
  fi
done

if [ ${#MISSING_PACKAGES[@]} -eq 0 ]; then
  echo "[INFO] Alle benötigten Pakete sind bereits installiert."
else
  echo "[INFO] Installiere fehlende Pakete: ${MISSING_PACKAGES[*]}"
  apt-get update
  apt-get install -y "${MISSING_PACKAGES[@]}"
  echo "[INFO] Pakete erfolgreich installiert."
fi
