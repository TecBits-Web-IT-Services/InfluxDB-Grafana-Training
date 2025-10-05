# Lösungsblatt 09a – Grafana Alerts und Notifications (Prometheus)

Dieses Lösungsblatt zeigt eine Prometheus-basierte Alarmregel in Grafana inkl. Zustellung über Kontaktpunkte.

## 1. Ziel
- Prometheus als Datenquelle für Alerts genutzt
- Testalarm ausgelöst (z. B. hohe CPU)

## 2. Kontaktpunkt anlegen
- Grafana → Alerting → Contact points → New contact point
- Kanal gemäß Schulungsumgebung (E-Mail/Slack/Webhook)
- Test senden und Empfang prüfen

## 3. Alarmregel (Beispiel: Hohe CPU > 90 % über 5m)
- Data source: Prometheus
- Query A (CPU Utilization %):
  ```promql
  100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
  ```
- Reduce: Last() oder Mean()
- Threshold: Is above 90, For: 5m
- Labels: `severity=warning`
- Instances ggf. per Dashboard-Variable filtern (optional)

## 4. Validierung
- Panel „Alert rules“ zeigt Statewechsel
- Notification im Zielkanal eingetroffen

## 5. Troubleshooting
- Stellen Sie sicher, dass `up{job="node"}` Daten liefert
- Abtastrate/Evaluation interval genügend kurz (z. B. 1m)
- Richtige Datenquelle in der Alertregel gewählt
