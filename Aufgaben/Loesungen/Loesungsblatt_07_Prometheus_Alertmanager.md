# Lösungsblatt 07 – Prometheus Alertmanager

Dieses Lösungsblatt zeigt Installation, Konfiguration und Tests des Alertmanagers inkl. Beispiel-Regeln.

## 1. Ziel
- Alertmanager läuft als Dienst und empfängt Alarme von Prometheus
- Mindestens ein Test-Alert wird ausgelöst und zugestellt (z. B. E-Mail/Slack in Schulungsumgebung)

## 2. Installation
- Binarys (alertmanager, amtool) nach `/usr/local/bin` kopieren
- Verzeichnis: `/etc/alertmanager`, Config: `/etc/alertmanager/alertmanager.yml`
- Service gemäß Aufgabenblatt einrichten: `systemctl enable --now alertmanager`

## 3. Beispiel-Alertmanager-Konfiguration
```yaml
route:
  receiver: 'mail'
receivers:
  - name: 'mail'
    email_configs:
      - to: 'training@example.org'
        from: 'grafana@example.org'
        smarthost: 'mail.example.org:587'
        auth_username: 'user'
        auth_password: 'pass'
```
Passen Sie Empfänger gemäß Schulungsumgebung an (oder verwenden Sie Webhook/Slack).

## 4. Prometheus mit Alertmanager verbinden
- In `/etc/prometheus/prometheus.yml`:
  ```yaml
  alerting:
    alertmanagers:
      - static_configs:
          - targets: ['localhost:9093']
  rule_files:
    - "/etc/prometheus/rules/*.yml"
  ```

## 5. Beispiel-Regel (Prometheus rules)
- Datei: `/etc/prometheus/rules/host_down.yml`
  ```yaml
  groups:
    - name: host_down
      rules:
        - alert: InstanceDown
          expr: up == 0
          for: 1m
          labels:
            severity: critical
          annotations:
            summary: "Instance {{ $labels.instance }} down"
            description: "Instance {{ $labels.instance }} ist seit 1m nicht erreichbar."
  ```
- Prometheus neu laden: `systemctl reload prometheus`

## 6. Validierung
- Alertmanager UI: http://localhost:9093
- Prometheus Alerts-Tab: „InstanceDown“ → PENDING → FIRING (nach 1m)
- Zustellung in Alertmanager prüfen (Receiver)
- `amtool alert` zur Kontrolle

## 7. Troubleshooting
- Logs: `journalctl -u alertmanager -e`
- Netz/Firewall Port 9093
- Prometheus rule syntax: `promtool check rules /etc/prometheus/rules/*.yml`
