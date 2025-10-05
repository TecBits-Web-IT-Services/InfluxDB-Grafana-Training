# Grafana - Aufgabenfeld 8: Einrichtung und Verwendung von Grafana mit Prometheus

## Konfiguration von Grafana zur Visualisierung von Prometheus-Metriken

### 1. Überprüfen der Grafana-Installation

Wenn Sie den vorherigen Aufgabenfeldern gefolgt sind, sollte Grafana bereits installiert sein. Falls nicht, führen Sie die folgenden Befehle aus:

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
systemctl enable grafana-server
```

### 2. Konfiguration der Grafana Email-Einstellungen

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

### 2. Einrichtung von Prometheus als Datenquelle für Grafana

- Öffnen Sie im Browser [http://localhost:3000](http://localhost:3000)
- Melden Sie sich mit den Standardanmeldedaten an (falls Sie diese noch nicht geändert haben):
    - Benutzername: **admin**
    - Passwort: **admin**
- Klicken Sie im linken Menü auf "Connections" und dann auf "Data sources"
- Klicken Sie auf "Add data source"
- Wählen Sie "Prometheus" aus der Liste der Datenquellen
- Konfigurieren Sie die Datenquelle mit folgenden Einstellungen:
    - Name: Prometheus
    - URL: http://localhost:9090
    - Scrape interval: 10s (oder entsprechend Ihrer Prometheus-Konfiguration)
- Klicken Sie auf "Save & Test"
- Sie sollten eine Erfolgsmeldung sehen: "Successfully queried the Prometheus API."

### 3. Erstellen Sie in Grafana ein neues Dashboard "Server Monitoring".

> Für alle weiteren Aufgabenfelder in diesem Block verwenden Sie bitte die Daten von Node Exporter Host-1

### 4. Erstellen Sie einfache Visualisierungen für Systemmetriken

Der Titel des Panel soll "CPU Usage" lauten und Max und Min sollen 100 und 0 sein.

- Klicken Sie im linken Menü auf "Dashboards" und dann auf "New" > "New Dashboard"
- Klicken Sie auf "Add visualization"
- Wählen Sie "Prometheus" als Datenquelle
- Erstellen Sie ein Panel für die CPU-Auslastung mit folgender PromQL-Abfrage:

Definieren Sie bitte farblich markierte Thresholds nach folgendem Muster:

- Grün: 0–60%
- Gelb: 60–85%
- Rot: 85–100%

Diese Formel berechnet die durchschnittliche CPU-Auslastung der letzten Minute, indem sie den „idle“-Anteil von der Gesamtmöglichen Auslastung subtrahiert.

```
100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[1m])) * 100)
```
### 5. Hinzufügen weiterer Panels zum Dashboard

Fügen Sie weitere Panels für andere Systemmetriken hinzu:

#### Speichernutzung

- Klicken Sie auf "Add panel" > "Add visualization"
- Wählen Sie "Prometheus" als Datenquelle
- Verwenden Sie folgende PromQL-Abfrage:

```
100 * (1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)
```

- Konfigurieren Sie das Panel:
    - Titel: "Speichernutzung"
    - Einheit: Percent (0-100)
    - Min: 0, Max: 100

#### Festplattennutzung

- Klicken Sie auf "Add panel" > "Add visualization"
- Wählen Sie "Prometheus" als Datenquelle
- Verwenden Sie folgende PromQL-Abfrage:

```
100 - ((node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100)
```

- Konfigurieren Sie das Panel:
    - Titel: "Festplattennutzung /"
    - Einheit: Percent (0-100)
    - Min: 0, Max: 100

#### Systemlast

- Klicken Sie auf "Add panel" > "Add visualization"
- Wählen Sie "Prometheus" als Datenquelle
- Verwenden Sie folgende PromQL-Abfrage:

```
node_load1
```

- Konfigurieren Sie das Panel:
    - Titel: "Systemlast (1 min)"

### 6. Anpassen des Dashboard-Layouts

- Ordnen Sie die Panels an, indem Sie sie ziehen und ihre Größe ändern
- Klicken Sie auf das Zahnradsymbol in der oberen rechten Ecke, um die Dashboard-Einstellungen zu öffnen
- Geben Sie dem Dashboard einen Namen, z.B. "System Monitoring"
- Klicken Sie auf "Save"

### 7. Importieren eines vorgefertigten Dashboards

Grafana bietet eine Vielzahl vorgefertigter Dashboards, die Sie importieren können:

- Klicken Sie im linken Menü auf "Dashboards" und dann auf "New" > "Import"
- Geben Sie die Dashboard-ID 1860 ein (Node Exporter Full)
- Klicken Sie auf "Load"
- Wählen Sie "Prometheus" als Datenquelle
- Klicken Sie auf "Import"

