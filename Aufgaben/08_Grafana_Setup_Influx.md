# Grafana - Aufgabenfeld 8: Einrichtung und Verwendung von Grafana mit InfluxDB

### 1. Installation von Grafana über die Linux Shell

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
- Einrichtung E-Mail-Versand
  - Öffnen Sie die Grafana-Konfigurationsdatei (Ubuntu/Debian -> /etc/grafana/grafana.ini) in einem Editor Ihrer Wahl mit Root-Rechten
    - Beispiel: **sudo nano /etc/grafana/grafana.ini**
  - Editieren Sie den Bereich "[smtp]" und ergänzen Sie folgende Informationen und entfernen Sie die ";" in den entsprechenden Zeilen
    - enabled = true
    - host = "mail01.tecbits.de:587"
    - user = "training@tecbits.de"
    - password = **"WIRD WÄHREND DER SCHULUNG AUSGEGEBEN"**
    - from_address = "training@tecbits.de"
    - from_name = "Grafana E-Mail Training"
  - Starten Sie den Grafana-Service neu
    - **service grafana-server restart**

- Öffnen Sie im Anschluss im Browser der VM [http://localhost:3000](http://localhost:3000) und prüfen Sie, ob der Grafana-Login-Bildschirm erscheint
- Die Standard-Login-Daten lauten wie folgt:
    - Benutzername: **admin**
    - Passwort: **admin**
- Bei der ersten Anmeldung werden Sie aufgefordert, das Passwort zu ändern. Für die Übung verwenden Sie bitte **`Test4711-`**

### 2. Erstellen Sie in der InfluxDB-Oberfläche einen neuen API-Token "GRAFANA" mit folgenden Berechtigungen:
- Lese-Berechtigung für das **apache-logs** Bucket
- Lese-Berechtigung für das **computer-monitoring** Bucket
- Lese-Berechtigungen für das **testdata-web** Bucket

- Speichern Sie den Token in eine Textdatei

## InfluxDB mit FLUX 

### 3. Einrichtung von InfluxDB als Datenquelle für Grafana
- Klicken Sie im Grafana-Dashboard oben links auf das Grafana-Symbol und im erscheinenden Menü auf Connections
- Wählen Sie in der Liste InfluxDB aus und dann oben rechts "Add new data Source"
- Setzen Sie im erscheinenden Dialog folgende Daten:
    - Name: InfluxDB Local
    - Query Language: FLUX
    - URL: http://localhost:8087
    - Organisation: Test-Organisation
    - Token: TOKEN AUS TEXTDATEI in SCHRITT 2
    - Default Bucket: computer-monitoring
- Klicken Sie "Save & Test"
    - Es sollte eine Meldung mit `datasource is working. 3 buckets found` erscheinen

### 4. Erstellen Sie in Grafana ein neues Dashboard "Apache Monitoring".

### 5. Erstellen Sie in Ihrem Dashboard ein neues Widget vom Typ Tabelle für die Ausgabe der Log-Informationen des Apache-Webservers

> Hinweis:
> - Sie können folgende Flux-Abfrage für die Apache-Logs als Grundlage verwenden:
```
from(bucket: "apache-logs")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r["_measurement"] == "apache_access_log")
  |> filter(fn: (r) => r["_field"] == "request")
  |> filter(fn: (r) => r["host"] == "TestVm-Ubuntu24")
  |> filter(fn: (r) => r["path"] == "/var/log/apache2/access.log")
  |> filter(fn: (r) => r["resp_code"] == "200" or r["resp_code"] == "404")
```
