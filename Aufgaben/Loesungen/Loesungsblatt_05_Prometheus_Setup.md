# Lösungsblatt 05 – Prometheus Setup

Dieses Lösungsblatt führt Sie durch die erfolgreiche Installation, Dienstkonfiguration und Funktionsprüfung von Prometheus.

## 1. Ziel
- Prometheus installiert, läuft als Dienst
- Web-UI erreichbar (Standard: http://localhost:9090)
- Mindestens ein Scrape-Target ist „UP“

## 2. Installation (Beispiel manuell, laut Aufgabenblatt)
- Binary entpacken und nach `/usr/local/bin` kopieren (prometheus, promtool)
- Verzeichnisse anlegen: `/etc/prometheus`, `/var/lib/prometheus`
- Konfiguration `prometheus.yml` in `/etc/prometheus` ablegen

Beispiel-Mindestkonfiguration:
```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
```

## 3. Systemd-Dienst
- Service-Datei gemäß Aufgabenblatt erstellen und `systemctl daemon-reload`
- Dienst starten und aktivieren: `systemctl enable --now prometheus`
- Status prüfen: `systemctl status prometheus`

## 4. Validierung
- UI: http://localhost:9090 öffnen
- Menü Status → Targets: `prometheus` sollte UP sein
- Beispiel-Query: `prometheus_build_info` → sollte mindestens eine Serie liefern

## 5. Troubleshooting
- Logs: `journalctl -u prometheus -e`
- YAML-Fehler mit `promtool check config /etc/prometheus/prometheus.yml`
- Firewall/Port 9090 prüfen
- Pfade/Dateirechte der Konfiguration kontrollieren
