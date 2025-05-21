# Prometheus - Aufgabenfeld 12: Integration mit Grafana

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

### 3. Erstellen eines einfachen Dashboards für Systemmetriken

- Klicken Sie im linken Menü auf "Dashboards" und dann auf "New" > "New Dashboard"
- Klicken Sie auf "Add visualization"
- Wählen Sie "Prometheus" als Datenquelle
- Erstellen Sie ein Panel für die CPU-Auslastung mit folgender PromQL-Abfrage:

```
100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[1m])) * 100)
```

- Konfigurieren Sie das Panel:
  - Titel: "CPU-Auslastung"
  - Einheit: Percent (0-100)
  - Min: 0, Max: 100
- Klicken Sie auf "Apply"

### 4. Hinzufügen weiterer Panels zum Dashboard

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

### 5. Anpassen des Dashboard-Layouts

- Ordnen Sie die Panels an, indem Sie sie ziehen und ihre Größe ändern
- Klicken Sie auf das Zahnradsymbol in der oberen rechten Ecke, um die Dashboard-Einstellungen zu öffnen
- Geben Sie dem Dashboard einen Namen, z.B. "System Monitoring"
- Klicken Sie auf "Save"

### 6. Importieren eines vorgefertigten Dashboards

Grafana bietet eine Vielzahl vorgefertigter Dashboards, die Sie importieren können:

- Klicken Sie im linken Menü auf "Dashboards" und dann auf "New" > "Import"
- Geben Sie die Dashboard-ID 1860 ein (Node Exporter Full)
- Klicken Sie auf "Load"
- Wählen Sie "Prometheus" als Datenquelle
- Klicken Sie auf "Import"

Sie sollten nun ein umfassendes Dashboard für Node Exporter-Metriken sehen.

### 7. Konfiguration von Benachrichtigungen für Prometheus-Metriken

- Klicken Sie im linken Menü auf "Alerting"
- Klicken Sie auf "Create alert rule"
- Wählen Sie "Prometheus" als Datenquelle
- Konfigurieren Sie eine Benachrichtigungsregel für hohe CPU-Auslastung:
  - Abfrage: `100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80`
  - Bedingung: "IS ABOVE 80"
  - Zeitraum: "FOR 5m"
  - Name: "Hohe CPU-Auslastung"
  - Zusammenfassung: "CPU-Auslastung über 80% für mehr als 5 Minuten"
- Klicken Sie auf "Save"

### 8. Erstellen eines Dashboards mit Variablen

Variablen machen Dashboards dynamischer und wiederverwendbarer:

- Erstellen Sie ein neues Dashboard
- Klicken Sie auf das Zahnradsymbol und dann auf "Variables" > "Add variable"
- Konfigurieren Sie eine Variable für die Instanz:
  - Name: instance
  - Label: Instance
  - Type: Query
  - Data source: Prometheus
  - Query: `label_values(node_exporter_build_info, instance)`
- Klicken Sie auf "Apply"

Nun können Sie diese Variable in Ihren Abfragen verwenden:

```
100 - (avg by(instance) (rate(node_cpu_seconds_total{instance="$instance",mode="idle"}[1m])) * 100)
```

> Hinweise:
> - Grafana bietet viele Möglichkeiten zur Visualisierung von Prometheus-Metriken
> - Die Grafana-Community stellt viele vorgefertigte Dashboards zur Verfügung
> - Mit PromQL können Sie komplexe Abfragen erstellen, um genau die Metriken zu visualisieren, die Sie benötigen
> - Variablen machen Dashboards flexibler und wiederverwendbarer
> - Benachrichtigungen helfen Ihnen, proaktiv auf Probleme zu reagieren
