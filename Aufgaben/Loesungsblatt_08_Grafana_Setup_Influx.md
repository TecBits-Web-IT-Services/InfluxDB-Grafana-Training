# Lösungsblatt: Grafana - Einrichtung und Verwendung von Grafana

Dieses Lösungsblatt enthält die Lösungen für die Aufgaben aus dem Aufgabenfeld 8: Einrichtung und Verwendung von Grafana.

## Aufgabe 1: Installation von Grafana über die Linux Shell

### Lösung:

```bash
# zum root-Benutzer wechseln
sudo su

# Installation von Grafana
apt-get install apt-transport-https software-properties-common wget

mkdir -p /etc/apt/keyrings/

wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | sudo tee /etc/apt/keyrings/grafana.gpg > /dev/null

echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list

apt-get update && apt install grafana

# Starten von Grafana
systemctl start grafana-server
```

### Einrichtung des E-Mail-Versands:

1. Öffnen Sie die Grafana-Konfigurationsdatei mit Root-Rechten:
   ```bash
   sudo nano /etc/grafana/grafana.ini
   ```

2. Suchen Sie den Bereich "[smtp]" und nehmen Sie folgende Änderungen vor:
   - Entfernen Sie die Semikolons (;) vor den folgenden Zeilen
   - Setzen Sie die Werte wie folgt:
     ```ini
     [smtp]
     enabled = true
     host = "mail01.tecbits.de:587"
     user = "training@tecbits.de"
     password = "WIRD WÄHREND DER SCHULUNG AUSGEGEBEN"
     from_address = "training@tecbits.de"
     from_name = "Grafana E-Mail Training"
     ```

3. Speichern Sie die Datei (bei nano: STRG+O, ENTER, STRG+X)

4. Starten Sie den Grafana-Service neu und laden Sie den den Systemd Daemon:
   ```bash
   systemctl daemon-reload
   service grafana-server restart
   ```

5. Öffnen Sie im Browser der VM http://localhost:3000 und prüfen Sie, ob der Grafana-Login-Bildschirm erscheint

6. Melden Sie sich mit den Standard-Login-Daten an:
   - Benutzername: **admin**
   - Passwort: **admin**

7. Bei der ersten Anmeldung werden Sie aufgefordert, das Passwort zu ändern. Setzen Sie es auf:
   - Neues Passwort: **Test4711-**

## Aufgabe 2: Erstellen eines API-Tokens in InfluxDB

### Lösung:

1. Öffnen Sie die InfluxDB-Weboberfläche unter http://localhost:8087

2. Navigieren Sie zu "Load Data" > "API Tokens"

3. Klicken Sie auf "Generate API Token" > "Custom API Token"

4. Geben Sie als Beschreibung "GRAFANA" ein

5. Unter "Read" fügen Sie folgende Buckets hinzu:
   - apache-logs
   - computer-monitoring
   - testdata-web

6. Klicken Sie auf "Generate"

7. Kopieren Sie den angezeigten Token in eine Textdatei zur späteren Verwendung

## Aufgabe 3: Einrichtung von InfluxDB als Datenquelle für Grafana

### Lösung:

1. Melden Sie sich bei Grafana an (http://localhost:3000)

2. Klicken Sie im Grafana-Dashboard oben links auf das Grafana-Symbol und im erscheinenden Menü auf "Connections"

3. Klicken Sie auf "Add new connection"

4. Suchen Sie nach "InfluxDB" und klicken Sie auf diesen Eintrag

5. Klicken Sie auf "Add new data source"

6. Füllen Sie das Formular mit folgenden Daten aus:
   - Name: InfluxDB Local
   - Query Language: FLUX
   - URL: http://localhost:8087
   - Organisation: Test-Organisation
   - Token: [Fügen Sie hier den Token aus Aufgabe 2 ein]
   - Default Bucket: computer-monitoring

7. Klicken Sie auf "Save & Test"

8. Es sollte eine Erfolgsmeldung erscheinen: `datasource is working. 3 buckets found`

## Aufgabe 4: Erstellen eines neuen Dashboards "Apache Monitoring"

### Lösung:

1. Klicken Sie im Grafana-Dashboard auf "Dashboards" in der linken Seitenleiste

2. Klicken Sie auf "New" > "New Dashboard"

3. Klicken Sie auf "Save dashboard" (Disketten-Symbol in der oberen rechten Ecke)

4. Geben Sie als Namen "Apache Monitoring" ein

5. Klicken Sie auf "Save"

## Aufgabe 5: Erstellen eines Tabellen-Widgets für Apache-Logs

### Lösung:

1. Klicken Sie im Dashboard auf "Add panel" > "Add a new panel"

2. Wählen Sie im Dropdown-Menü rechts oben "Table" als Visualisierungstyp

3. Wählen Sie als Datenquelle "InfluxDB Local"

4. Fügen Sie folgende Flux-Abfrage in den Query-Editor ein:
   ```flux
   from(bucket: "apache-logs")
     |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
     |> filter(fn: (r) => r["_measurement"] == "apache_access_log")
     |> filter(fn: (r) => r["_field"] == "request")
     |> filter(fn: (r) => r["host"] == "NAME_DER_VM")
     |> filter(fn: (r) => r["path"] == "/var/log/apache2/access.log")
     |> filter(fn: (r) => r["resp_code"] == "200" or r["resp_code"] == "404")
   ```

5. Klicken Sie auf "Apply" in der oberen rechten Ecke

6. Geben Sie dem Panel einen Titel, z.B. "Apache Access Logs"

7. Passen Sie die Zeitspanne in der oberen rechten Ecke des Dashboards an, um einen geeigneten Zeitraum zu wählen (z.B. "Last 1 hour")

8. Klicken Sie erneut auf "Save" (Disketten-Symbol), um das Dashboard mit dem neuen Panel zu speichern

## Zusätzliche Anpassungen (optional):

1. Formatierung der Tabelle:
   - Klicken Sie auf das Panel, um es zu bearbeiten
   - Gehen Sie zum Tab "Field"
   - Hier können Sie die Anzeige der Spalten anpassen, z.B. Spalten umbenennen oder ausblenden

2. Sortierung:
   - Standardmäßig werden die Daten nach Zeitstempel sortiert
   - Sie können die Sortierung ändern, indem Sie auf den Spaltenkopf in der Tabelle klicken

3. Aktualisierungsintervall:
   - Klicken Sie auf das Zahnrad-Symbol in der oberen rechten Ecke des Dashboards
   - Wählen Sie "Settings" > "Time options"
   - Stellen Sie "Auto-refresh" auf ein geeignetes Intervall ein, z.B. "10s"

## Zusätzliche Hinweise

- Grafana bietet viele verschiedene Visualisierungstypen, die für unterschiedliche Datenarten geeignet sind
- Für Zeitreihendaten wie CPU-Auslastung sind Linien- oder Flächendiagramme oft besser geeignet als Tabellen
- Die Flux-Abfrage kann angepasst werden, um andere Daten anzuzeigen oder zu filtern
- Dashboards können exportiert und importiert werden, um sie mit anderen zu teilen
- Für Produktionsumgebungen sollten Sie die Sicherheit verbessern, indem Sie HTTPS und Authentifizierung einrichten
