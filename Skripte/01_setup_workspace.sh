#!/usr/bin/env bash
# Erstellt auf dem Desktop des Benutzers den Ordner "Workspace" und
# lädt dort die aktuelle Release-Version des Repositories als ZIP herunter
# und entpackt sie ohne Git-Abhängigkeit.
#
# Anforderung: Kein git erforderlich. Bevorzugt wird der neueste Release-Stand.
# Fallback: Wenn kein Release ermittelt werden kann, wird der Standard-Branch als ZIP geladen.
#
# Hinweis: Es wird versucht, curl oder wget zu verwenden. Zum Entpacken wird
# bevorzugt 'unzip' genutzt; falls nicht vorhanden, wird Python (zipfile) verwendet.

set -euo pipefail

OWNER="TecBits-Web-IT-Services"
REPO="InfluxDB-Grafana-Training"
REPO_NAME="$REPO"

info() { printf "[INFO] %s\n" "$*"; }
err()  { printf "[ERROR] %s\n" "$*" >&2; }

# Ermittelt den Desktop-Pfad gemäß XDG-Spezifikation, fallback: ~/Desktop
get_desktop_dir() {
  if [[ -n "${XDG_DESKTOP_DIR:-}" ]]; then
    echo "$XDG_DESKTOP_DIR"
    return 0
  fi
  local config="$HOME/.config/user-dirs.dirs"
  if [[ -f "$config" ]]; then
    # Zeile wie: XDG_DESKTOP_DIR="/home/user/Desktop"
    local val
    val=$(grep -E '^XDG_DESKTOP_DIR=' "$config" | cut -d= -f2- | tr -d '"') || true
    if [[ -n "${val:-}" ]]; then
      # Pfade können ~ oder $HOME enthalten
      # shellcheck disable=SC2086
      eval echo $val
      return 0
    fi
  fi
  echo "$HOME/Desktop"
}

have_cmd() { command -v "$1" >/dev/null 2>&1; }

# Lädt eine URL in eine Datei (nutzt curl oder wget)
download_to() {
  local url="$1" out="$2"
  if have_cmd curl; then
    curl -fL --retry 3 --retry-delay 2 -o "$out" "$url"
  elif have_cmd wget; then
    wget -q -O "$out" "$url"
  else
    err "Weder curl noch wget gefunden. Bitte eines davon installieren."
    return 1
  fi
}

# Ermittelt die URL des Assets "release.zip" des neuesten Releases über die GitHub API.
# Fällt auf den Source-Zipball bzw. den Standard-Branch (main/master) zurück, wenn kein Asset gefunden wird.
get_latest_zip_url() {
  local api="https://api.github.com/repos/${OWNER}/${REPO}/releases/latest"
  local json url=""
  if have_cmd curl; then
    json=$(curl -fsSL "$api" || true)
  elif have_cmd wget; then
    json=$(wget -q -O - "$api" || true)
  else
    json=""
  fi

  if [[ -n "$json" ]]; then
    # Bevorzugt per Python (falls vorhanden) sauber aus JSON lesen
    if have_cmd python3; then
      url=$(python3 - <<'PY'
import sys, json
j = json.load(sys.stdin)
for a in j.get('assets', []):
    if a.get('name') == 'release.zip' and a.get('browser_download_url'):
        print(a['browser_download_url'])
        break
PY
      <<<"$json") || true
    elif have_cmd python; then
      url=$(python - <<'PY'
import sys, json
j = json.load(sys.stdin)
for a in j.get('assets', []):
    if a.get('name') == 'release.zip' and a.get('browser_download_url'):
        print(a['browser_download_url'])
        break
PY
      <<<"$json") || true
    fi

    # Falls keine Python-Laufzeit, versuche grobes sed-Matching innerhalb des passenden Asset-Objekts
    if [[ -z "$url" ]]; then
      # Einfache Heuristik: Alles in eine Zeile, den Abschnitt um name==release.zip finden und daraus browser_download_url extrahieren
      url=$(printf %s "$json" | tr -d '\n' | sed -n 's/.*\{[^\}]*"name"[[:space:]]*:[[:space:]]*"release\.zip"[^\}]*"browser_download_url"[[:space:]]*:[[:space:]]*"\([^"]*\)"[^\}]*\}.*/\1/p' | head -n1)
    fi

    if [[ -n "$url" ]]; then
      echo "$url"
      return 0
    fi

    # Fallback: wenn kein Asset gefunden wurde, nimm zipball_url (Source ZIP des Tags)
    local zipball
    zipball=$(printf %s "$json" | sed -n 's/.*"zipball_url"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)
    if [[ -n "$zipball" ]]; then
      echo "$zipball"
      return 0
    fi
  fi

  # Letzter Fallback: Branch-ZIPs
  local branch_zip="https://github.com/${OWNER}/${REPO}/archive/refs/heads/main.zip"
  if have_cmd curl; then
    if curl -fsI "$branch_zip" >/dev/null 2>&1; then
      echo "$branch_zip"; return 0
    fi
  elif have_cmd wget; then
    if wget --spider -q "$branch_zip" >/dev/null 2>&1; then
      echo "$branch_zip"; return 0
    fi
  fi
  echo "https://github.com/${OWNER}/${REPO}/archive/refs/heads/master.zip"
}

# Entpackt eine ZIP-Datei nach Zielverzeichnis (unzip oder Python)
extract_zip() {
  local zipfile="$1" dest="$2"
  mkdir -p "$dest"
  if have_cmd unzip; then
    unzip -q "$zipfile" -d "$dest"
  elif have_cmd python3; then
    python3 - "$zipfile" "$dest" <<'PY'
import sys, zipfile, os
zf_path, dest = sys.argv[1], sys.argv[2]
with zipfile.ZipFile(zf_path) as zf:
    zf.extractall(dest)
PY
  elif have_cmd python; then
    python - "$zipfile" "$dest" <<'PY'
import sys, zipfile, os
zf_path, dest = sys.argv[1], sys.argv[2]
with zipfile.ZipFile(zf_path) as zf:
    zf.extractall(dest)
PY
  else
    err "Weder 'unzip' noch 'python(3)' vorhanden, kann ZIP nicht entpacken."
    return 1
  fi
}

main() {
  local DESKTOP_DIR WORKSPACE_DIR TARGET_DIR
  DESKTOP_DIR=$(get_desktop_dir)
  WORKSPACE_DIR="$DESKTOP_DIR/Workspace"
  TARGET_DIR="$WORKSPACE_DIR/$REPO_NAME"

  info "Verwende Desktop-Pfad: $DESKTOP_DIR"
  mkdir -p "$WORKSPACE_DIR"

  if [[ -d "$TARGET_DIR" ]]; then
    info "Zielverzeichnis existiert bereits: $TARGET_DIR"
    info "Keine Änderungen vorgenommen."
    exit 0
  fi

  local TMP_DIR
  TMP_DIR=$(mktemp -d)
  __TMP_DIR="$TMP_DIR"
  trap 'tmp="${__TMP_DIR-}"; if [ -n "$tmp" ]; then rm -rf -- "$tmp"; fi' EXIT

  info "Ermittle neueste Release-ZIP …"
  local ZIP_URL
  ZIP_URL=$(get_latest_zip_url)
  if [[ -z "${ZIP_URL:-}" ]]; then
    err "Konnte keine ZIP-URL ermitteln."
    exit 1
  fi
  info "ZIP-Quelle: $ZIP_URL"

  local ZIP_FILE="$TMP_DIR/src.zip"
  info "Lade ZIP herunter …"
  download_to "$ZIP_URL" "$ZIP_FILE"

  info "Entpacke ZIP …"
  local EXTRACT_DIR="$TMP_DIR/extracted"
  extract_zip "$ZIP_FILE" "$EXTRACT_DIR"

  # Finde das Top-Level-Verzeichnis aus dem Archiv
  local TOP
  TOP=$(find "$EXTRACT_DIR" -mindepth 1 -maxdepth 1 -type d | head -n1 || true)
  if [[ -z "${TOP:-}" ]]; then
    err "Konnte entpackten Inhalt nicht finden."
    exit 1
  fi

  info "Kopiere Dateien nach: $TARGET_DIR"
  mkdir -p "$TARGET_DIR"
  shopt -s dotglob nullglob
  mv "$TOP"/* "$TARGET_DIR"/
  shopt -u dotglob nullglob

  info "Fertig. Inhalte bereitgestellt unter:"
  info "  $TARGET_DIR"
}

main "$@"
