#!/usr/bin/env bash
# Prüft, ob die wichtigsten Dienste laufen und per HTTP erreichbar sind.
# Dienste: InfluxDB, Prometheus, Node Exporter, Alertmanager, Grafana

set -euo pipefail

# Konfiguration der Checks: NAME|SYSTEMD_UNIT|URL
CHECKS=(
  "InfluxDB|influxdb|http://127.0.0.1:8086/health"
  "Prometheus|prometheus|http://127.0.0.1:9090/-/healthy"
  "Node Exporter|node_exporter|http://127.0.0.1:9100/metrics"
  "Alertmanager|alertmanager|http://127.0.0.1:9093/-/healthy"
  "Grafana|grafana-server|http://127.0.0.1:3000/api/health"
)

ok() { printf "[ OK ] %s\n" "$*"; }
warn() { printf "[WARN] %s\n" "$*"; }
err() { printf "[FAIL] %s\n" "$*"; }

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    err "Benötigtes Kommando fehlt: $1"; exit 2;
  }
}

main() {
  need_cmd systemctl
  need_cmd curl

  local failed=0

  echo "== Dienst- und Erreichbarkeitsprüfung =="

  for entry in "${CHECKS[@]}"; do
    IFS='|' read -r NAME UNIT URL <<<"$entry"

    # 1) Systemd-Status prüfen
    if systemctl is-active --quiet "$UNIT"; then
      ok "$NAME: Dienst '$UNIT' ist aktiv"
    else
      err "$NAME: Dienst '$UNIT' ist NICHT aktiv"
      failed=1
    fi

    # 2) HTTP-Erreichbarkeit prüfen
    if curl --silent --show-error --fail --max-time 5 "$URL" >/dev/null; then
      ok "$NAME: Endpoint erreichbar: $URL"
    else
      err "$NAME: Endpoint NICHT erreichbar: $URL"
      failed=1
    fi

    echo
  done

  if [ "$failed" -ne 0 ]; then
    echo "Mindestens ein Dienst ist nicht funktionsfähig. Bitte Logs prüfen (journalctl -u <dienst>) und Konfigurationen verifizieren."
    exit 1
  fi

  echo "Alle Dienste laufen und sind erreichbar."
}

main "$@"
