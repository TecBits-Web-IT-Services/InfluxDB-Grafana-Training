# Lösungsblatt: Prometheus - Integration mit Grafana

Dieses Lösungsblatt enthält die Lösungen für die Aufgaben aus dem Aufgabenfeld 9: Integration von Prometheus mit Grafana.

## Aufgabe 1: Überprüfen der Grafana-Installation

### Lösung:

Wenn Grafana bereits installiert ist, können Sie den Status überprüfen mit:

```bash
# Überprüfen des Status des Grafana-Dienstes
systemctl status grafana-server
```

Falls Grafana noch nicht installiert ist, führen Sie folgende Befehle aus:

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

## Aufgabe 2: Einrichtung von Prometheus als Datenquelle für Grafana

### Lösung:

1. Öffnen Sie im Browser http://localhost:3000

2. Melden Sie sich mit den Standardanmeldedaten an (falls Sie diese noch nicht geändert haben):
   - Benutzername: **admin**
   - Passwort: **admin** (oder **Test4711-** falls Sie es bereits geändert haben)

3. Klicken Sie im linken Menü auf "Connections" und dann auf "Data sources"

4. Klicken Sie auf "Add data source"

5. Wählen Sie "Prometheus" aus der Liste der Datenquellen

6. Konfigurieren Sie die Datenquelle mit folgenden Einstellungen:
   - Name: Prometheus
   - URL: http://localhost:9090
   - Scrape interval: 10s (oder entsprechend Ihrer Prometheus-Konfiguration)

7. Klicken Sie auf "Save & Test"

8. Sie sollten eine Erfolgsmeldung sehen: "Data source is working"

## Aufgabe 3: Erstellen eines einfachen Dashboards für Systemmetriken

### Lösung:

1. Klicken Sie im linken Menü auf "Dashboards" und dann auf "New" > "New Dashboard"

2. Klicken Sie auf "Add visualization"

3. Wählen Sie "Prometheus" als Datenquelle

4. Erstellen Sie ein Panel für die CPU-Auslastung mit folgender PromQL-Abfrage:
   ```
   100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[1m])) * 100)
   ```

5. Konfigurieren Sie das Panel:
   - Titel: "CPU-Auslastung"
   - Einheit: Percent (0-100)
   - Min: 0, Max: 100

6. Klicken Sie auf "Apply"

## Aufgabe 4: Hinzufügen weiterer Panels zum Dashboard

### Lösung:

#### Speichernutzung:

1. Klicken Sie auf "Add panel" > "Add visualization"

2. Wählen Sie "Prometheus" als Datenquelle

3. Verwenden Sie folgende PromQL-Abfrage:
   ```
   100 * (1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)
   ```

4. Konfigurieren Sie das Panel:
   - Titel: "Speichernutzung"
   - Einheit: Percent (0-100)
   - Min: 0, Max: 100

5. Klicken Sie auf "Apply"

#### Festplattennutzung:

1. Klicken Sie auf "Add panel" > "Add visualization"

2. Wählen Sie "Prometheus" als Datenquelle

3. Verwenden Sie folgende PromQL-Abfrage:
   ```
   100 - ((node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100)
   ```

4. Konfigurieren Sie das Panel:
   - Titel: "Festplattennutzung /"
   - Einheit: Percent (0-100)
   - Min: 0, Max: 100

5. Klicken Sie auf "Apply"

#### Systemlast:

1. Klicken Sie auf "Add panel" > "Add visualization"

2. Wählen Sie "Prometheus" als Datenquelle

3. Verwenden Sie folgende PromQL-Abfrage:
   ```
   node_load1
   ```

4. Konfigurieren Sie das Panel:
   - Titel: "Systemlast (1 min)"

5. Klicken Sie auf "Apply"

## Aufgabe 5: Anpassen des Dashboard-Layouts

### Lösung:

1. Ordnen Sie die Panels an, indem Sie sie ziehen und ihre Größe ändern:
   - Klicken und halten Sie den oberen Bereich eines Panels
   - Ziehen Sie es an die gewünschte Position
   - Verwenden Sie die Ecken, um die Größe zu ändern

2. Klicken Sie auf das Zahnradsymbol in der oberen rechten Ecke, um die Dashboard-Einstellungen zu öffnen

3. Geben Sie dem Dashboard einen Namen, z.B. "System Monitoring"

4. Klicken Sie auf "Save"

## Aufgabe 6: Importieren eines vorgefertigten Dashboards

### Lösung:

1. Klicken Sie im linken Menü auf "Dashboards" und dann auf "New" > "Import"

2. Geben Sie die Dashboard-ID 1860 ein (Node Exporter Full)

3. Klicken Sie auf "Load"

4. Wählen Sie "Prometheus" als Datenquelle

5. Klicken Sie auf "Import"

6. Sie sollten nun ein umfassendes Dashboard für Node Exporter-Metriken sehen

## Aufgabe 7: Konfiguration von Benachrichtigungen für Prometheus-Metriken

### Lösung:

1. Klicken Sie im linken Menü auf "Alerting"

2. Klicken Sie auf "Create alert rule"

3. Wählen Sie "Prometheus" als Datenquelle

4. Konfigurieren Sie eine Benachrichtigungsregel für hohe CPU-Auslastung:
   - Abfrage: `100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80`
   - Bedingung: "IS ABOVE 80"
   - Zeitraum: "FOR 5m"
   - Name: "Hohe CPU-Auslastung"
   - Zusammenfassung: "CPU-Auslastung über 80% für mehr als 5 Minuten"

5. Klicken Sie auf "Save"

## Aufgabe 8: Erstellen eines Dashboards mit Variablen

### Lösung:

1. Erstellen Sie ein neues Dashboard:
   - Klicken Sie im linken Menü auf "Dashboards"
   - Klicken Sie auf "New" > "New Dashboard"

2. Klicken Sie auf das Zahnradsymbol und dann auf "Variables" > "Add variable"

3. Konfigurieren Sie eine Variable für die Instanz:
   - Name: instance
   - Label: Instance
   - Type: Query
   - Data source: Prometheus
   - Query: `label_values(node_exporter_build_info, instance)`

4. Klicken Sie auf "Apply"

5. Erstellen Sie ein neues Panel:
   - Klicken Sie auf "Add visualization"
   - Wählen Sie "Prometheus" als Datenquelle
   - Verwenden Sie folgende PromQL-Abfrage mit der Variable:
     ```
     100 - (avg by(instance) (rate(node_cpu_seconds_total{instance="$instance",mode="idle"}[1m])) * 100)
     ```

6. Konfigurieren Sie das Panel:
   - Titel: "CPU-Auslastung für $instance"
   - Einheit: Percent (0-100)
   - Min: 0, Max: 100

7. Klicken Sie auf "Apply"

8. Speichern Sie das Dashboard mit einem aussagekräftigen Namen, z.B. "Dynamisches System Monitoring"

## Zusätzliche Hinweise

- Grafana bietet viele Möglichkeiten zur Visualisierung von Prometheus-Metriken, darunter Liniendiagramme, Balkendiagramme, Heatmaps und mehr
- Die Grafana-Community stellt viele vorgefertigte Dashboards zur Verfügung, die Sie importieren und an Ihre Bedürfnisse anpassen können
- Mit PromQL können Sie komplexe Abfragen erstellen, um genau die Metriken zu visualisieren, die Sie benötigen
- Variablen machen Dashboards flexibler und wiederverwendbarer, indem sie es ermöglichen, Teile der Abfrage dynamisch zu ändern
- Benachrichtigungen helfen Ihnen, proaktiv auf Probleme zu reagieren, bevor sie kritisch werden
- Für Produktionsumgebungen sollten Sie die Sicherheit verbessern, indem Sie HTTPS und Authentifizierung einrichten
- Dashboards können exportiert und mit anderen geteilt werden, entweder als JSON-Datei oder über die Grafana-Community
