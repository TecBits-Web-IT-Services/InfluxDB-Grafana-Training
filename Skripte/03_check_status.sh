#!/usr/bin/env bash
# Prüft, ob die wichtigsten Dienste laufen und per HTTP erreichbar sind.
# Dienste: InfluxDB v2/v3, Prometheus, Node Exporter, Alertmanager, Grafana, InfluxDB Explorer

set -euo pipefail

# Wartezeit: Mindestens 20 Sekunden nach Installation warten, damit Dienste vollständig starten können
WAIT_TIME=20

echo "[INFO] Warte ${WAIT_TIME} Sekunden, damit alle Dienste vollständig starten können..."
sleep "$WAIT_TIME"

# Konfiguration der Checks: NAME|SYSTEMD_UNIT|URL|TYPE
# TYPE kann sein: optional, required, nohttp (Service ohne HTTP-Endpoint)
CHECKS=(
  "InfluxDB v2|influxdb|http://127.0.0.1:8086/health|optional"
  "InfluxDB v3 Core|influxdb3-core|NOHTTP|nohttp"
  "Prometheus|prometheus|http://127.0.0.1:9090/-/healthy|required"
  "Node Exporter|node_exporter|http://127.0.0.1:9100/metrics|required"
  "Alertmanager|alertmanager|http://127.0.0.1:9093/-/healthy|required"
  "Grafana|grafana-server|http://127.0.0.1:3000/api/health|required"
)

ok() { printf "[ OK ] %s\n" "$*"; }
warn() { printf "[WARN] %s\n" "$*"; }
err() { printf "[FAIL] %s\n" "$*"; }

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    err "Benötigtes Kommando fehlt: $1"; exit 2;
  }
}

check_docker_container() {
  local container_name="$1"
  local port="$2"
  local url="$3"

  if command -v docker >/dev/null 2>&1; then
    if docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
      ok "Docker Container '${container_name}' läuft"

      # Prüfe HTTP-Erreichbarkeit
      if curl --silent --show-error --fail --max-time 5 "$url" >/dev/null 2>&1; then
        ok "Docker Container '${container_name}': Endpoint erreichbar: $url"
      else
        warn "Docker Container '${container_name}': Endpoint NICHT erreichbar: $url"
      fi
    else
      warn "Docker Container '${container_name}' läuft NICHT (optional)"
    fi
  else
    warn "Docker ist nicht installiert, überspringe Container-Checks"
  fi
  echo
}

main() {
  need_cmd systemctl
  need_cmd curl

  local failed=0

  echo "== Dienst- und Erreichbarkeitsprüfung =="
  echo

  for entry in "${CHECKS[@]}"; do
    IFS='|' read -r NAME UNIT URL TYPE <<<"$entry"

    # Prüfe, ob Service-Datei existiert (robustere Methode)
    if ! systemctl cat "$UNIT" >/dev/null 2>&1; then
      if [ "$TYPE" = "optional" ] || [ "$TYPE" = "nohttp" ]; then
        warn "$NAME: Dienst '$UNIT' ist nicht installiert (optional)"
        echo
        continue
      else
        err "$NAME: Dienst '$UNIT' ist nicht installiert"
        failed=1
        echo
        continue
      fi
    fi

    # 1) Systemd-Status prüfen
    if systemctl is-active --quiet "$UNIT" 2>/dev/null; then
      ok "$NAME: Dienst '$UNIT' ist aktiv"

      # 2) HTTP-Erreichbarkeit prüfen (nur wenn Service aktiv und HTTP-Check gewünscht)
      if [ "$TYPE" = "nohttp" ]; then
        # Für Services ohne HTTP-Endpoint: Prüfe ob Prozess läuft
        if systemctl show "$UNIT" -p MainPID --value 2>/dev/null | grep -qv "^0$"; then
          ok "$NAME: Prozess läuft (PID: $(systemctl show "$UNIT" -p MainPID --value))"
        else
          warn "$NAME: Kein aktiver Prozess gefunden"
        fi
      elif curl --silent --show-error --fail --max-time 5 "$URL" >/dev/null 2>&1; then
        ok "$NAME: Endpoint erreichbar: $URL"
      else
        if [ "$TYPE" = "optional" ]; then
          warn "$NAME: Endpoint NICHT erreichbar: $URL (optional)"
        else
          err "$NAME: Endpoint NICHT erreichbar: $URL"
          failed=1
        fi
      fi
    else
      if [ "$TYPE" = "optional" ] || [ "$TYPE" = "nohttp" ]; then
        warn "$NAME: Dienst '$UNIT' ist NICHT aktiv (optional)"
      else
        err "$NAME: Dienst '$UNIT' ist NICHT aktiv"
        failed=1
      fi
    fi

    echo
  done

  # Prüfe Docker Container (InfluxDB v3 Explorer)
  echo "== Docker Container Checks =="
  echo
  check_docker_container "influxdb3-explorer" "8888" "http://127.0.0.1:8888"

  if [ "$failed" -ne 0 ]; then
    echo "======================================"
    echo "Mindestens ein erforderlicher Dienst ist nicht funktionsfähig."
    echo "Bitte Logs prüfen: journalctl -u <dienst>"
    echo "======================================"
    exit 1
  fi

  echo "======================================"
  echo "Alle erforderlichen Dienste laufen und sind erreichbar."
  echo "======================================"
}

main "$@"
