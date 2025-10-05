# Grafana - Aufgabenfeld 9a: Konfiguration von Alerts und Benachrichtigungen für Prometheus

### 1. Konfiguration von Contact Points
- Editieren Sie unter "Alerting > Contact Points" des Grafana Default Kontaktpunkt und hinterlegen Sie eine gültige Email-Adresse.

### 2. Konfiguration von Benachrichtigungen für Prometheus-Metriken

- Klicken Sie im linken Menü auf "Alerting", dann auf "Alert Rules"

> In der Überischt sollten Sie bereits 3 Regeln sehen können
> - Diese sind die Regeln, welche in Aufgabenfeld 7 im Prometheus Alert Manager von Ihnen oder von uns während des Setups konfiguriert wurden.

### 3. Erstellen Sie eine neuen Alert-Regel

- Klicken Sie auf "Create alert rule"
- Wählen Sie "Prometheus" als Datenquelle
- Konfigurieren Sie eine Benachrichtigungsregel für hohe CPU-Auslastung:
    - Abfrage: `100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle", instance="Host-1"}[1m])) * 100) > 80`
    - Bedingung: "IS ABOVE 80"
    - Zeitraum: "FOR 1m"
    - Name: "Hohe CPU-Auslastung"
    - Zusammenfassung: "CPU-Auslastung über 80% für mehr als 1 Minuten"
- Klicken Sie auf "Save"

- Führen Sie folgenden Befehl aus um die CPU Last auf ein Maximum zu treiben und warten Sie bis die die Alerts abgefeuert werden.
  - Mit STRG+X kann der Befehlt gestoppt werden, wenn er nicht nach 2 Minuten automatisch beendet wird.
  
  ``stress --cpu 8 --timeout 2m``

- Neben den Alert Meldungen im Dashboard sollten nun auch Anotation in den Metriken gezeigt werden.