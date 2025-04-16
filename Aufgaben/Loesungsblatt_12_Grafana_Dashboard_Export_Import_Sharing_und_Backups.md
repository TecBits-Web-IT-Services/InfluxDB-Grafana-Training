# Lösungsblatt: Grafana - Dashboard Export/Import, Sharing und Backup

Dieses Lösungsblatt enthält die Lösungen für die Aufgaben aus dem Aufgabenfeld 12: Dashboard Export/Import, Sharing und Backup in Grafana.

## Aufgabe 1: Exportieren, Löschen und Reimportieren des Air Sensor Dashboards

### Lösung:

#### Exportieren des Dashboards:

1. Melden Sie sich bei Grafana an (http://localhost:3000)

2. Klicken Sie im linken Menü auf "Dashboards"

3. Suchen Sie das "AirSensors" Dashboard in der Liste und klicken Sie darauf, um es zu öffnen

4. Klicken Sie auf das Zahnrad-Symbol in der oberen rechten Ecke, um die Dashboard-Einstellungen zu öffnen

5. Klicken Sie auf "JSON Model" im linken Menü der Einstellungen

6. Klicken Sie auf "Save to file", um das Dashboard als JSON-Datei zu exportieren
   - Die Datei wird in Ihrem Download-Ordner gespeichert (z.B. als "airsensors-dashboard.json")

#### Löschen des Dashboards:

1. Kehren Sie zur Dashboard-Übersicht zurück (klicken Sie auf "Dashboards" im linken Menü)

2. Suchen Sie das "AirSensors" Dashboard in der Liste

3. Klicken Sie auf das Drei-Punkte-Menü (⋮) rechts neben dem Dashboard-Namen

4. Wählen Sie "Delete"

5. Bestätigen Sie den Löschvorgang, indem Sie auf "Delete" im Bestätigungsdialog klicken

#### Reimportieren des Dashboards:

1. Klicken Sie im linken Menü auf "Dashboards"

2. Klicken Sie auf "New" > "Import"

3. Klicken Sie auf "Upload JSON file"

4. Wählen Sie die zuvor exportierte JSON-Datei aus Ihrem Download-Ordner aus

5. Überprüfen Sie die Import-Einstellungen:
   - Name: "AirSensors" (oder passen Sie den Namen an, falls gewünscht)
   - Folder: "General" (oder wählen Sie einen anderen Ordner)
   - Unique identifier (uid): Lassen Sie dieses Feld leer, um eine neue UID zu generieren

6. Klicken Sie auf "Import"

7. Das Dashboard sollte nun wieder verfügbar sein und alle vorherigen Konfigurationen enthalten

## Aufgabe 2: Importieren des Computer-Monitoring Dashboards aus einer Beispieldatei

### Lösung:

1. Klicken Sie im linken Menü auf "Dashboards"

2. Klicken Sie auf "New" > "Import"

3. Klicken Sie auf "Upload JSON file"

4. Navigieren Sie zum Beispielkonfigurationen-Ordner und wählen Sie die Datei "ComputerMonitoring.json" aus

5. Überprüfen Sie die Import-Einstellungen:
   - Name: Behalten Sie den vorgeschlagenen Namen bei oder passen Sie ihn an
   - Folder: "General" (oder wählen Sie einen anderen Ordner)
   - Unique identifier (uid): Lassen Sie dieses Feld leer, um eine neue UID zu generieren
   - Wenn Variablen vorhanden sind, stellen Sie sicher, dass sie korrekt konfiguriert sind

6. Klicken Sie auf "Import"

7. Nach dem Import des Dashboards:
   - Suchen Sie im oberen Bereich des Dashboards nach einem Dropdown-Menü für das Bucket
   - Wählen Sie "computer-monitoring" aus dem Dropdown-Menü aus
   - Die Daten sollten nun im Dashboard angezeigt werden

## Zusätzliche Hinweise

- Das Exportieren und Importieren von Dashboards ist nützlich für:
  - Backup-Zwecke
  - Übertragung von Dashboards zwischen verschiedenen Grafana-Instanzen
  - Versionskontrolle von Dashboards
  - Teilen von Dashboards mit anderen Benutzern oder der Community

- Beim Importieren von Dashboards müssen Sie möglicherweise Anpassungen vornehmen:
  - Datenquellen können unterschiedliche Namen haben
  - Variablen müssen möglicherweise neu konfiguriert werden
  - Berechtigungen müssen möglicherweise neu gesetzt werden

- Grafana bietet auch eine Snapshot-Funktion, mit der Sie den aktuellen Zustand eines Dashboards ohne die zugrunde liegenden Daten teilen können

- Für Produktionsumgebungen sollten Sie regelmäßige Backups Ihrer Dashboards erstellen, entweder durch manuellen Export oder durch Automatisierung mit der Grafana API

- Die Grafana-Community bietet viele vorgefertigte Dashboards, die Sie importieren und an Ihre Bedürfnisse anpassen können
