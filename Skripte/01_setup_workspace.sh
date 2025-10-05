#!/usr/bin/env bash
# Erstellt auf dem Desktop des Benutzers den Ordner "Workspace" und
# lädt dort die aktuelle Release-Version des Repositories als ZIP herunter und entpackt diese

# Hinweis: Benötigt unter Ubuntu: wget und unzip.
#

set -euo pipefail

OWNER="TecBits-Web-IT-Services"
REPO="InfluxDB-Grafana-Training"
DOWNLOADURL="https://github.com/${OWNER}/${REPO}/releases/latest/download/release.zip"
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



# Lädt eine URL in eine Datei (verwendet wget)
download_to() {
  local url="$1" out="$2"
  wget -q -O "$out" "$url"
}

# Entpackt eine ZIP-Datei nach Zielverzeichnis (unzip)
extract_zip() {
  local zipfile="$1" dest="$2"
  mkdir -p "$dest"
  unzip -q "$zipfile" -d "$dest"
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
  ZIP_URL="$DOWNLOADURL"
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
