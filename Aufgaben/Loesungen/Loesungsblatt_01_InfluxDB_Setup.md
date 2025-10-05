# Lösungsblatt 01 – InfluxDB Setup (formale Ansprache)

Dieses Lösungsblatt führt Sie durch eine funktionierende Installation und Grundkonfiguration von InfluxDB. Ziel ist, dass InfluxDB als Dienst läuft, erreichbar ist und erste Prüf-Queries erfolgreich sind.

## 1. Zielbild
- InfluxDB installiert (Version gemäß Unterrichtsumgebung)
- Dienst aktiv: `systemctl status influxdb` → active (running)
- Web UI/API erreichbar (Port standardgemäß offen)

## 2. Installation (Beispiel Ubuntu/Debian)
- Paketquellen gemäß Hersteller hinzufügen (ggf. durch Schulungsumgebung vorgegeben)
- Installation durchführen: `apt install influxdb2`
- Dienst starten und aktivieren:  
  `systemctl enable --now influxdb`

## 3. Ersteinrichtung
- Aufruf Web UI (Standard: https://<host>:8086 oder http://<host>:8086 je nach Setup)
- Initial Wizard: Organisation, Bucket (z. B. „training“), Admin-User und Token anlegen.
- Notieren Sie sich Admin-Token sicher (für CLI/Telegraf/Grafana).

## 4. CLI-Verbindung prüfen
- Konfiguration setzen (Beispiel):  
  `influx config create --config-name training --host-url http://localhost:8086 --org <ORG> --token <TOKEN> --active`  
- Buckets anzeigen: `influx bucket list`
- Nutzer/Orgs prüfen: `influx org list`, `influx user list`

## 5. Funktionstest mit Beispiel-Daten
- Write-Test (Line Protocol):  
  `influx write --bucket training "demo,host=host1 value=1i"`  
- Abfrage (Flux):  
  ```flux
  from(bucket: "training")
    |> range(start: -5m)
    |> filter(fn: (r) => r._measurement == "demo")
  ```
- Erwartung: Ein Datenpunkt mit `_measurement=demo` und `_field=value`.

## 6. Troubleshooting
- Dienststatus: `systemctl status influxdb`  
- Logs: `journalctl -u influxdb -e`  
- Port belegt/Firewall prüfen (8086)
- Token/Org korrekt gesetzt? `influx config list`

## 7. Abschlusskriterien
- Web UI erreichbar, Login möglich
- CLI-Befehle liefern erwartete Ergebnisse
- Minimaler Write/Read-Flow erfolgreich