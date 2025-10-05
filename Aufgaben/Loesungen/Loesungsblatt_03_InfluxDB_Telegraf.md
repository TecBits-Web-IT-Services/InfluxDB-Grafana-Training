# Lösungsblatt 03 – InfluxDB Telegraf

Dieses Lösungsblatt zeigt eine funktionierende Telegraf-Installation inkl. Output nach InfluxDB und grundlegender Validierungen.

## 1. Ziel
- Telegraf ist installiert und als Dienst aktiv
- Metriken werden in den Ziel-Bucket in InfluxDB geschrieben

## 2. Installation (Ubuntu/Debian, Beispiel)
- `apt install telegraf`
- Dienst aktivieren/starten: `systemctl enable --now telegraf`

## 3. Grundkonfiguration
- Datei: `/etc/telegraf/telegraf.conf` oder separate `.d`-Fragmente
- Minimales Beispiel:
  ```toml
  [agent]
    interval = "10s"

  [[outputs.influxdb_v2]]
    urls = ["http://localhost:8086"]
    token = "${INFLUX_TOKEN}"
    organization = "${INFLUX_ORG}"
    bucket = "training"

  [[inputs.cpu]]
    percpu = false
    totalcpu = true
  [[inputs.mem]]
  [[inputs.system]]
  ```
- Geheimnisse (Token) vorzugsweise via Umgebungsvariablen oder `/etc/default/telegraf` setzen.

## 4. Validierung
- Dienststatus: `systemctl status telegraf`
- Logs: `journalctl -u telegraf -e`
- Daten in Influx prüfen (Flux):
  ```flux
  from(bucket: "training")
    |> range(start: -10m)
    |> filter(fn: (r) => r._measurement =~ /cpu|mem|system/)
  ```
- Erwartung: aktuelle Messpunkte vorhanden

## 5. Troubleshooting
- Token/Org/Bucket falsch → 401/404 Fehler in Logs
- Firewall/Port 8086 erreichbar?
- Zeitsynchronisation (NTP) für korrekte Timestamps sicherstellen
