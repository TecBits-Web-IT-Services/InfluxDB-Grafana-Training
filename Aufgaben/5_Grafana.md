# InfluxDB - Aufgabenfeld 5 : Einrichtung und Verwendung von Grafana

### 1. Installation von Grafana über die Linux Shell

```bash
# zum root-Benutzer wechseln
sudo su

# installation von Telegraf und Apache Webserver
apt-get install apt-transport-https software-properties-common wget

mkdir -p /etc/apt/keyrings/

wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | sudo tee /etc/apt/keyrings/grafana.gpg > /dev/null

echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list

apt-get update && apt install grafana

# Starten von Grafana
systemctl start grafana-server
```
- Öffnen Sie im Anschluss im Browser der VM [http://localhost:3000](http://localhost:3000) und pürfen Sie ob der Grafana Login Bildschirm erscheint
- Die Standart Login Daten lauten wie folgt:
    - Benutzername: **admin**
    - Passwort: **admin**
- Bei der ersten Anmeldung werden Sie aufgefordert das Passwort zu ändern, für die Übung verwenden Sie bitte **``Test4711-``**

### 2. Erstellen Sie in der InfluxDB Oberfläche einen neuen API Token "GRAFANA" mit folgenden berechtigungen:
- Lese Berechtigung für das **apache-logs** Bucket
- Lese Berechtigung für das **computer-monitoring** Bucket
- Speichern sie den Token in eine Textdatei

## 5a. Option 1: InfluxDB mit FLUX 

### 3. Einrichtung von InfluxDB als Datenquelle für Grafana
- Klicken Sie im Grafana Dashboard oben links auf das Grafana Symbol und dem erscheinenden Menü auf Connections
- Wählen Sie in der Liste InfluxDB aus und dann oben rechts "Add new data Source"
- Setzten Sie im erscheinenden Dialog folgende Daten:
    - Name: InfluxDB Local
    - Query Language: FLUX
    - URL: http://localhost:8087
    - Organisation: Test-Organisation
    - Token: TOKEN AUS TEXTDATEI in SCHRITT 3.
    - Default Bucket: computer-monitoring
- Klicken Sie "Save & Test"
    - Es sollte eine Meldung mit ``datasource is working. 2 buckets found`` erscheinen

### 4. Erstellen Sie in Grafana ein neues Dashboard und richten Sie ein Diagramm Widget für die CPU und Memory Auslastung ein.

> Hinweis:
> - Sie können folgende Flux Abfrage für die CPU Auslastung als Grundlage verwenden verwenden:
```
from(bucket: "computer-monitoring")
  |> range(start: -30d)
  |> filter(fn: (r) => r["_measurement"] == "cpu")
  |> filter(fn: (r) => r["_field"] == "usage_system")
  |> filter(fn: (r) => r["cpu"] == "cpu-total")
```

### 5. Erstellen Sie in ihrem Dashbard eine neues Widget vom Typ Tabelle für die Ausgabe der Log Informationen des Apache Webservers

> Hinweis:
> - Sie können folgende Flux Abfrage für die CPU Auslastung als Grundlage verwenden verwenden:
```
from(bucket: "apache-logs")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r["_measurement"] == "apache_access_log")
  |> filter(fn: (r) => r["_field"] == "request")
  |> filter(fn: (r) => r["host"] == "TestVm-Ubuntu24")
  |> filter(fn: (r) => r["path"] == "/var/log/apache2/access.log")
  |> filter(fn: (r) => r["resp_code"] == "200" or r["resp_code"] == "404")
```

## 5b. Option 2: InfluxDB mit InfluxQL 
### 3. Einrichtung von InfluxDB als Datenquelle für Grafana
- Klicken Sie im Grafana Dashboard oben links auf das Grafana Symbol und dem erscheinenden Menü auf Connections
- Wählen Sie in der Liste InfluxDB aus und dann oben rechts "Add new data Source"
- Setzten Sie im erscheinenden Dialog folgende Daten:
    - Name: InfluxDB Local
    - Query Language: InfluxQL
    - URL: http://localhost:8087
    - Custom HTTP Headers:
        Header: Authorization
        Value: Token TOKEN_AUS_AUFGABE_2
    - Database: computer-monitoring
    - HTTP Method: GET
- Klicken Sie "Save & Test"

### 4. Erstellen Sie in Grafana ein neues Dashboard und richten Sie ein Diagramm Widget für die CPU und Memory Auslastung ein.

### 5. Erstellen Sie in ihrem Dashbard eine neues Widget vom Typ Tabelle für die Ausgabe der Log Informationen des Apache Webservers