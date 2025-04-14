# Grafana - Aufgabenfeld 11: Konfiguration von Alerts und Benachrichtigungen

### 1. Starten Sie den Telegraph Prozess aus Aufgabenfeld 3 um die aktuellen Metriken des Rechners in der InfluxDB zu erfassen
### 2. Erstellen Sie ein neues Dashboard "Computer Monitoring" mit einem Diagramm für die aktelle CPU Auslastung aus dem Computer Monitoring Bucket

> Hinweis:
>  - nehmen Sie dabei den Data-Explorer der InfluxDB Web UI zur Hilfe.
>  - Verwenden Sie das Tag "cpu-total" um die Auslastung über alle Kerne Hinweg zu erhalten
>  - Verwenden Sie als Feld "usage_user"

Beispiel Code:

```flux
from(bucket: "computer-monitoring")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r["_measurement"] == "cpu")
  |> filter(fn: (r) => r["_field"] == "usage_user")
  |> filter(fn: (r) => r["cpu"] == "cpu-total")
  |> filter(fn: (r) => r["host"] == "TestVm-Ubuntu24")
```

### 3.**Notification Channel / Contact Point einrichten**
    - Konfigurieren Sie E-Mail-Benachrichtigungen in Grafana im Bereich Alerting/Contact Points.
      - editieren Sie den Bereits vorhandene "grafana-default-email" Endpunkt und tragen Sie Ihre E-Mail Adresse ein
      - Verifizieren Sie über den Test Button die Funktion

### 3. **Alert-Regel definieren**  
   - Erstellen Sie eine Alert-Regel mit folgenden Parametern:  
     - **Name:** CPU Load > 50%
     - **Bedingung:** CPU-Auslastung liegt länger als 1 Minuten über 50 %.  
     - **Zeitraum:** Abfrageintervall: 1 Minute, Auswertungszeitraum: 10 Sekunden.
     - Fügen Sie einen Folder mit dem Namen "Training" hinzu
     - Fügen Sie eine Benachrichtigungsgruppe "Computer Monitoring" hinzu
     - Speichern Sie den Alert
   - Führen Sie auf der Linux Shell den Befehl ***"yes"*** aus um künstlich CPU Last zu erzeugen und warten Sie auf den Alert

> Hinweis:
>  - Für den Test können Sie im Linux Terminal den Befehl ***"yes"*** verwenden um künstlich CPU Last zu erzeugen
>  - Der Wert der Metrik entspricht einem Bereich von 0-1 pro CPU Kern (0-100% Last), bei 6 Kernen läuft der Bereich demnach von 0-6 und 50% entsprechen in diesem Beispiel einem Wert von 3
>  - Sie können beim Erstellen der Regel per "Preview alert Rule Condition" prüfen, ob Ihre Abfrage funktioniert und ob Sie bereits ausgelöst werden würde.

Beispiel Code:
```flux
from(bucket: "computer-monitoring")
|> range(start: -1h)
|> filter(fn: (r) => r["_measurement"] == "cpu")
|> filter(fn: (r) => r["_field"] == "usage_user")
|> filter(fn: (r) => r["cpu"] == "cpu-total")
|> filter(fn: (r) => r["host"] == "TestVm-Ubuntu24")
|> aggregateWindow(every: 1m, fn: mean, createEmpty: false)
```