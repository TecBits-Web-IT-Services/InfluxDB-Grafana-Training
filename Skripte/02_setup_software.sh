#!/usr/bin/env bash
set -euo pipefail

# Parent orchestrator script: runs all setup steps in order
# Usage: sudo bash Skripte/full-setup.sh

if [ "$(id -u)" -ne 0 ]; then
  echo "Dieses Skript muss als root ausgeführt werden (z.B. via: sudo bash Skripte/full-setup.sh)."
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "$SCRIPT_DIR/02a_setup_prereqs.sh"
bash "$SCRIPT_DIR/02b_install_influxdb.sh"
bash "$SCRIPT_DIR/02c_install_prometheus.sh"
bash "$SCRIPT_DIR/02d_install_node_exporter.sh"
bash "$SCRIPT_DIR/02e_install_alertmanager.sh"
bash "$SCRIPT_DIR/02f_install_grafana.sh"
bash "$SCRIPT_DIR/02g_add_custom_configs.sh"
bash "$SCRIPT_DIR/02g_install_docker.sh"

echo "Alle Komponenten wurden installiert."

bash "$SCRIPT_DIR/03_check_status.sh"