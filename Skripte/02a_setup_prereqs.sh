#!/usr/bin/env bash
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Dieses Skript muss als root ausgeführt werden. Bitte mit sudo starten."
  exit 1
fi

apt-get update
apt-get install -y curl nano mc net-tools wget gnupg2 software-properties-common stress
