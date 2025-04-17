# Lösungsblatt: InfluxDB - Einrichtung und Verwendung von Telegraf

Dieses Lösungsblatt enthält die Lösungen für die Aufgaben aus dem Aufgabenfeld 3: Einrichtung und Verwendung von Telegraf.

## Aufgabe 1: Installation von Telegraf über die Linux Shell

### Lösung:

```bash
# zum root-Benutzer wechseln
sudo su

# Installation von Telegraf und Apache Webserver
apt-get install telegraf apache2
```

## Aufgabe 2: Erstellen eines neuen Buckets "computer-monitoring"

### Lösung:

#### Über das Webinterface:
1. Öffnen Sie das InfluxDB Webinterface unter http://localhost:8087
2. Navigieren Sie zu "Load Data" > "Buckets"
3. Klicken Sie auf "Create Bucket"
4. Geben Sie als Namen "computer-monitoring" ein
5. Wählen Sie eine Retention-Periode (z.B. "Never" für unbegrenzte Speicherung)
6. Klicken Sie auf "Create"

#### Über die CLI:
```bash
influx bucket create --name computer-monitoring --org "Test-Organisation"
```

## Aufgabe 3: Erstellen einer neuen Telegraf-Konfiguration

### Lösung:

1. Navigieren Sie im InfluxDB Webinterface zu "Load Data" > "Telegraf"
2. Klicken Sie auf "Create Configuration"
3. Wählen Sie "System" und dann "CPU" aus
4. Klicken Sie auf "Continue"
5. Geben Sie als Namen "Monitoring" ein
6. Wählen Sie als Bucket "computer-monitoring" aus
7. Klicken Sie auf "Save and Test"
8. Kopieren Sie den angezeigten Token-Befehl in eine Textdatei, er sollte etwa so aussehen:
   ```bash
   export INFLUX_TOKEN=Ihr_Token_Hier
   ```
9. Führen Sie diesen Befehl in der Linux Shell aus
10. Kopieren Sie den 'Start Telegraf' Befehl in die Textdatei, er sollte etwa so aussehen:
    ```bash
    telegraf --config http://localhost:8087/api/v2/telegrafs/[ID]
    ```
11. Führen Sie diesen Befehl in der Linux Shell aus, um Telegraf zu starten
12. Überprüfen Sie im Data Explorer, ob Daten einfließen:
    - Navigieren Sie zu "Data Explorer"
    - Wählen Sie das Bucket "computer-monitoring"
    - Wählen Sie die Messung "cpu" und das Feld "usage_user"
    - Klicken Sie auf "Submit"

## Aufgabe 4: Editieren der Telegraf-Konfiguration

### Lösung:

1. Navigieren Sie im InfluxDB Webinterface zu "Load Data" > "Telegraf"
2. Finden Sie Ihre "Monitoring" Konfiguration und klicken Sie auf "Edit"
3. Öffnen Sie die Datei "Telegraf_Computer_Monitoring.conf" aus dem Ordner mit den Beispielkonfigurationen
4. Kopieren Sie den gesamten Inhalt dieser Datei
5. Ersetzen Sie den Inhalt im Konfigurationseditor mit dem kopierten Inhalt
6. Klicken Sie auf "Save Changes"
7. Starten Sie Telegraf erneut mit dem Befehl aus Schritt 3.11
8. Überprüfen Sie im Data Explorer, ob nun weitere Metriken (z.B. Speicher, Festplatte) verfügbar sind

## Aufgabe 5: Aktivieren des Debug-Modus

### Lösung:

1. Navigieren Sie im InfluxDB Webinterface zu "Load Data" > "Telegraf"
2. Finden Sie Ihre "Monitoring" Konfiguration und klicken Sie auf "Edit"
3. Suchen Sie im Konfigurationseditor nach dem Parameter `debug`
4. Ändern Sie den Wert von `false` auf `true`:
   ```
   debug = true
   ```
5. Klicken Sie auf "Save Changes"
6. Starten Sie Telegraf erneut mit dem Befehl aus Schritt 3.11
7. Sie sollten nun detailliertere Debug-Ausgaben in der Konsole sehen

## Aufgabe 6: Erstellen eines neuen Buckets "apache-logs"

### Lösung:

#### Über das Webinterface:
1. Navigieren Sie zu "Load Data" > "Buckets"
2. Klicken Sie auf "Create Bucket"
3. Geben Sie als Namen "apache-logs" ein
4. Wählen Sie eine Retention-Periode (z.B. "Never" für unbegrenzte Speicherung)
5. Klicken Sie auf "Create"

#### Über die CLI:
```bash
influx bucket create --name apache-logs --org "Test-Organisation"
```

## Aufgabe 7: Erstellen eines neuen API-Tokens

### Lösung:

1. Navigieren Sie im InfluxDB Webinterface zu "Load Data" > "API Tokens"
2. Klicken Sie auf "Generate API Token" > "Custom API Token"
3. Geben Sie als Beschreibung "TELEGRAF_MULTI_BUCKET_ACCESS" ein
4. Unter "Read" fügen Sie hinzu:
   - Telegraf-Konfiguration (die Sie in Aufgabe 3 erstellt haben)
5. Unter "Write" fügen Sie hinzu:
   - Bucket "computer-monitoring"
   - Bucket "apache-logs"
6. Klicken Sie auf "Generate"
7. Kopieren Sie den angezeigten Token in Ihre Textdatei

## Aufgabe 8: Erweitern der Telegraf-Konfiguration für Apache Access Log Monitoring

### Lösung:

1. Navigieren Sie im InfluxDB Webinterface zu "Load Data" > "Telegraf"
2. Finden Sie Ihre "Monitoring" Konfiguration und klicken Sie auf "Edit"
3. Fügen Sie am Ende der Konfiguration (vor dem letzten `[[outputs.influxdb_v2]]` Abschnitt) folgenden Code ein:
   ```
   [[inputs.tail]]
     files = ["/var/log/apache2/access.log"]
     from_beginning = false
     grok_patterns = ["%{COMBINED_LOG_FORMAT}"]
     name_override = "apache_access_log"
     grok_custom_pattern_files = []
       grok_custom_patterns = '''
     '''
     data_format = "grok"
     grok_timezone = "Europe/Berlin"
     tags = { targetBucket = "apache-logs"}
   ```
4. Klicken Sie auf "Save Changes"

## Aufgabe 9: Ergänzen der Outputkomponente

### Lösung:

1. Navigieren Sie im InfluxDB Webinterface zu "Load Data" > "Telegraf"
2. Finden Sie Ihre "Monitoring" Konfiguration und klicken Sie auf "Edit"
3. Suchen Sie den Abschnitt `[[outputs.influxdb_v2]]`
4. Fügen Sie folgende Zeile innerhalb dieses Abschnitts hinzu:
   ```
   bucket_tag = "targetBucket"
   ```
5. Klicken Sie auf "Save Changes"

## Aufgabe 10: Hinterlegen des neuen Access-Tokens und Starten von Telegraf

### Lösung:

1. Öffnen Sie ein Terminal
2. Setzen Sie den neuen Token als Umgebungsvariable:
   ```bash
   export INFLUX_TOKEN=Ihr_Neuer_Token_Aus_Aufgabe_7
   ```
3. Starten Sie Telegraf mit dem Befehl aus Aufgabe 3:
   ```bash
   telegraf --config http://localhost:8087/api/v2/telegrafs/[ID]
   ```

## Aufgabe 11: Erzeugen von Testdaten und Überprüfung

### Lösung:

1. Öffnen Sie einen Browser in der VM
2. Rufen Sie mehrfach die URL http://localhost auf
3. Rufen Sie auch mehrfach die URL http://localhost/zonk auf, um 404-Fehler zu erzeugen
4. Navigieren Sie im InfluxDB Webinterface zum "Data Explorer"
5. Wählen Sie das Bucket "apache-logs"
6. Wählen Sie die Messung "apache_access_log"
7. Deaktivieren Sie die Aggregierungsfunktion, indem Sie:
   - Auf "Aggregate Functions" klicken und "none" auswählen
   - Oder auf "Raw Data" umschalten
8. Klicken Sie auf "Submit"
9. Sie sollten nun die Apache-Zugriffslogs in der Tabelle sehen, einschließlich der 404-Fehler für "/zonk"

## Zusätzliche Hinweise

- Telegraf sammelt standardmäßig alle 10 Sekunden Daten. Dies kann in der Konfiguration angepasst werden.
- Der Debug-Modus ist nützlich für die Fehlersuche, sollte aber in Produktionsumgebungen deaktiviert werden.
- Die Verwendung von Tags wie `targetBucket` ermöglicht es, Daten dynamisch in verschiedene Buckets zu schreiben.
- Die Grok-Muster für das Apache-Log-Parsing können angepasst werden, um spezifische Informationen zu extrahieren.
- Wenn keine Daten erscheinen, überprüfen Sie:
  - Ob der Token korrekt gesetzt ist
  - Ob Telegraf ohne Fehler läuft
  - Ob die Zeitspanne im Data Explorer groß genug ist
  - Ob die richtigen Messungen und Felder ausgewählt sind
