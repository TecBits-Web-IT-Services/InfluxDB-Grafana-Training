# Lösungsblatt 09 – Grafana Alerts und Notifications (InfluxDB)

Dieses Lösungsblatt beschreibt das Erstellen einer Alarmregel in Grafana, das Anlegen eines Kontaktpunkts und das Testen der Zustellung.

## 1. Ziel
- Alarmregel vorhanden und aktiv
- Kontaktpunkt (z. B. E-Mail) eingerichtet
- Test-Alert erfolgreich zugestellt

## 2. Kontaktpunkt anlegen
- Grafana → Alerting → Contact points → New contact point
- Typ gemäß Schulungsumgebung (E-Mail/Slack/Webhook)
- Testen: „Send test notification“ → Zustellung prüfen

## 3. Alarmregel (Beispiel: Hohe Temperatur)
- Data source: InfluxDB (Flux)
- Query A:
  ```flux
  from(bucket: "training")
    |> range(start: -5m)
    |> filter(fn: (r) => r._measurement == "airSensors" and r._field == "temperature")
    |> aggregateWindow(every: 1m, fn: mean, createEmpty: false)
  ```
- Reduce: Last() oder Mean()
- Threshold: Is above 75 (für 2m)
- Labels: `severity=warning`
- Notification policy: Kontaktpunkt zuordnen

## 4. Validierung
- Alert State changes sichtbar (OK → Pending → Firing)
- Notification in Kanal eingetroffen

## 5. Troubleshooting
- Datasource/Query liefert Daten?
- Kontaktpunkt korrekt konfiguriert (SMTP/Token)?
- Alert rule evaluation interval ausreichend kurz (z. B. 1m)
