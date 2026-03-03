# Grafana - Aufgabenfeld 13b: Konfiguration von Alerts und Benachrichtigungen

### Vorbereitung

Erstellen Sie eine neue Verbindung wie in Aufgabe 11b aber dieses mal mit der Databank "computer-monitoring" um Zugriff auf die Leistungsmetriken zu bekommen.


### 1. Starten Sie den Telegraf-Prozess aus Aufgabenfeld 3, um die aktuellen Metriken des Rechners in der InfluxDB zu erfassen

### 2. Erstellen Sie ein neues Dashboard "Computer Monitoring" mit einem Diagramm für die aktuelle CPU-Auslastung aus der Computer-Monitoring-Database

> Hinweis:
>  - Verwenden Sie das Tag "cpu-total", um die Auslastung über alle Kerne hinweg zu erhalten
>  - Verwenden Sie als Feld "usage_user"

Beispiel Code:

```sql
SELECT
  time,
  usage_user
FROM cpu
WHERE $__timeFilter(time)
  AND cpu = 'cpu-total'
  AND host = 'TestVm-Ubuntu24'
ORDER BY time
```

### 3. **Notification Channel / Contact Point einrichten**
- Konfigurieren Sie E-Mail-Benachrichtigungen in Grafana im Bereich Alerting/Contact Points.
  - Editieren Sie den bereits vorhandenen "grafana-default-email" Endpunkt und tragen Sie Ihre E-Mail-Adresse ein
  - Verifizieren Sie über den Test-Button die Funktion

### 4. **Alert-Regel definieren**  
- Erstellen Sie eine Alert-Regel mit folgenden Parametern:  
  - **Name:** CPU Load > 50%
  - **Bedingung:** CPU-Auslastung liegt länger als 1 Minute über 50%.  
  - **Zeitraum:** Abfrageintervall: 1 Minute, Auswertungszeitraum: 10 Sekunden.
  - Fügen Sie einen Folder mit dem Namen "Training" hinzu
  - Fügen Sie eine Benachrichtigungsgruppe "Computer Monitoring" hinzu
  - Speichern Sie den Alert
- Führen Sie auf der Linux Shell den Befehl ***"stress --cpu 8 --timeout 2m"*** aus, um künstlich CPU-Last zu erzeugen und warten Sie auf den Alert

> Hinweis:
>  - Für den Test können Sie im Linux Terminal den Befehl ***"stress --cpu 8 --timeout 2m"*** verwenden, um künstlich CPU-Last zu erzeugen
>  - Der Wert der Metrik entspricht einem Bereich von 0-1 pro CPU-Kern (0-100% Last), bei 6 Kernen läuft der Bereich demnach von 0-6 und 50% entsprechen in diesem Beispiel einem Wert von 3
>  - Sie können beim Erstellen der Regel per "Preview alert Rule Condition" prüfen, ob Ihre Abfrage funktioniert und ob sie bereits ausgelöst werden würde.

Beispiel Code:
```sql
SELECT
  time,
  usage_user
FROM cpu
WHERE $__timeFilter(time)
  AND cpu = 'cpu-total'
  AND host = 'TestVm-Ubuntu24'
ORDER BY time
```
