# Lösungsblatt: Grafana - Konfiguration von Alerts und Benachrichtigungen

Dieses Lösungsblatt enthält die Lösungen für die Aufgaben aus dem Aufgabenfeld 11: Konfiguration von Alerts und Benachrichtigungen in Grafana.

## Aufgabe 1: Starten des Telegraf-Prozesses

### Lösung:

1. Öffnen Sie ein Terminal

2. Setzen Sie den Token als Umgebungsvariable:
   ```bash
   export INFLUX_TOKEN=Ihr_Token_Aus_Aufgabe_3
   ```

3. Starten Sie Telegraf mit dem Befehl aus Aufgabenfeld 3:
   ```bash
   telegraf --config http://localhost:8087/api/v2/telegrafs/[ID]
   ```
   
   Hinweis: Ersetzen Sie [ID] durch die tatsächliche ID Ihrer Telegraf-Konfiguration. Dieser Befehl sollte in Ihrer Textdatei aus Aufgabenfeld 3 gespeichert sein.

## Aufgabe 2: Erstellen eines Dashboards für CPU-Auslastung

### Lösung:

1. Melden Sie sich bei Grafana an (http://localhost:3000)

2. Klicken Sie im linken Menü auf "Dashboards"

3. Klicken Sie auf "New" > "New Dashboard"

4. Klicken Sie auf "Add visualization" (oder "Add panel"), um ein neues Panel hinzuzufügen

5. Wählen Sie "InfluxDB Local" als Datenquelle

6. Fügen Sie folgende Flux-Abfrage in den Query-Editor ein:
   ```flux
   from(bucket: "computer-monitoring")
     |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
     |> filter(fn: (r) => r["_measurement"] == "cpu")
     |> filter(fn: (r) => r["_field"] == "usage_user")
     |> filter(fn: (r) => r["cpu"] == "cpu-total")
     |> filter(fn: (r) => r["host"] == "TestVm-Ubuntu24")
   ```

7. Konfigurieren Sie das Panel:
   - Titel: "CPU-Auslastung"
   - Visualisierungstyp: Time series (Zeitreihe)
   - Einheit: Percent (0-100)

8. Klicken Sie auf "Apply"

9. Klicken Sie auf das Disketten-Symbol in der oberen rechten Ecke, um das Dashboard zu speichern

10. Geben Sie als Namen "Computer Monitoring" ein und klicken Sie auf "Save"

## Aufgabe 3: Notification Channel / Contact Point einrichten

### Lösung:

1. Klicken Sie im linken Menü auf "Alerting"

2. Klicken Sie auf "Contact points"

3. Suchen Sie den Eintrag "grafana-default-email" und klicken Sie auf das Bearbeiten-Symbol (Stift)

4. Tragen Sie Ihre E-Mail-Adresse im Feld "Addresses" ein
   - Wenn mehrere E-Mail-Adressen eingegeben werden sollen, trennen Sie diese durch Kommas

5. Klicken Sie auf "Test" um die Konfiguration zu testen
   - Es sollte eine Test-E-Mail an die angegebene Adresse gesendet werden

6. Klicken Sie auf "Save contact point", um die Änderungen zu speichern

## Aufgabe 4: Alert-Regel definieren

### Lösung:

1. Klicken Sie im linken Menü auf "Alerting"

2. Klicken Sie auf "Alert rules"

3. Klicken Sie auf "New alert rule"

4. Konfigurieren Sie die Alert-Regel:
   - Schritt 1: Definieren Sie die Abfrage
     - Datenquelle: InfluxDB Local
     - Fügen Sie folgende Flux-Abfrage ein:
       ```flux
       from(bucket: "computer-monitoring")
       |> range(start: -1h)
       |> filter(fn: (r) => r["_measurement"] == "cpu")
       |> filter(fn: (r) => r["_field"] == "usage_user")
       |> filter(fn: (r) => r["cpu"] == "cpu-total")
       |> filter(fn: (r) => r["host"] == "TestVm-Ubuntu24")
       |> aggregateWindow(every: 1m, fn: mean, createEmpty: false)
       ```
     - Klicken Sie auf "Preview alert rule condition", um die Abfrage zu testen

   - Schritt 2: Definieren Sie die Bedingungen
     - Reduce: Reduce values to "Last"
     - Threshold: "IS ABOVE 50"
     - For: "1m" (1 Minute)

   - Schritt 3: Fügen Sie Details hinzu
     - Rule name: "CPU Load > 50%"
     - Folder: Klicken Sie auf "Add new" und geben Sie "Training" ein
     - Evaluation group: Klicken Sie auf "Add new" und geben Sie "Computer Monitoring" ein
     - Evaluation interval: "10s" (10 Sekunden)

5. Klicken Sie auf "Save and exit", um die Alert-Regel zu speichern

6. Öffnen Sie ein Terminal und führen Sie den Befehl `stress --cpu 8 --timeout 2m` aus, um künstlich CPU-Last zu erzeugen:
   ```bash
   stress --cpu 8 --timeout 2m
   ```

7. Warten Sie etwa 1-2 Minuten, bis der Alert ausgelöst wird
   - Sie können den Status im Bereich "Alerting" > "Alert rules" überprüfen
   - Der Status sollte von "Normal" zu "Pending" und dann zu "Firing" wechseln

8. Sobald der Alert ausgelöst wurde, sollten Sie eine E-Mail-Benachrichtigung erhalten

9. Beenden Sie den Befehl mit STRG+C, um die CPU-Last zu reduzieren

10. Warten Sie, bis der Alert-Status wieder auf "Normal" zurückgeht

## Zusätzliche Hinweise

- Die CPU-Auslastung wird in Prozent gemessen (0-100%)
- Bei mehreren CPU-Kernen kann der Wert auch über 100% liegen, da jeder Kern bis zu 100% beitragen kann
- Für reale Anwendungen sollten Sie die Schwellenwerte und Zeiträume sorgfältig wählen, um unnötige Alarme zu vermeiden
- Grafana bietet verschiedene Benachrichtigungskanäle, darunter E-Mail, Slack, PagerDuty, und mehr
- Sie können mehrere Benachrichtigungskanäle für einen Alert konfigurieren
- Alerts können auch mit Dashboards verknüpft werden, um visuelle Hinweise zu geben
- Für Produktionsumgebungen sollten Sie die Sicherheit verbessern, indem Sie HTTPS und Authentifizierung einrichten
