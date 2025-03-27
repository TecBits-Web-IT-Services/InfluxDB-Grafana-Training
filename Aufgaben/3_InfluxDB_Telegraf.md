# InfluxDB - Aufgabenfeld 4 : Einrichtung und Verwendung von Telegraf

### 1. Installation von Telegraf über die Linux Shell
    
```bash
# zum root-Benutzer wechseln
sudo su

# installation von Telegraf und Apache Webserver
apt-get install telegraf apache2
```

### 2. Erstellen Sie mit der CLI oder dem Webinterface ein neues Bucket "computer-monitoring".

### 3. Erstellen Sie über das Webinterface eine neue Telegraf Konfiguration mit dem gerade erstellten Bucket und der Vorauswahl für **CPU** und dem Namen Monitoring
 - Belassen Sie die Konfiguration so wie sie ist
 - Kopieren Sie den angezeigten Token Befehl in eine neue Textdatei
 - Führen Sie den Befehl in der Linux Shell aus
 - Kopieren Sie den 'Start Telegraf' Befehl in die erstelle Textdatei und führen Sie ihn in der Linux Shell aus um Telegraf zu starten
 - Prüfen Sie mit dem Data Explorer in der Weboberfläche ob Daten in das computer-monitoring Bucket einlaufen

> Hinweis:
>
> - Sie können die Konfiguration im Bereich **Load Data** Telegraf erstellen und dort auch später editieren
> - Für die Übung starten wir Telegraf nicht als Dienst sondern interactive in der Shell, per STRG+C kann der Prozess beendet und die Datensammlugn gestoppt werden

### 4. Editieren Sie über die Weboberfläche die erstellte Telegraf-Konfiguration und ersetzen Sie den Inhalt mit dem Inhalt der Datei "Telegraf_Computer_Monitoring.conf" aus dem Ordner mit dem Beispielkonfigurationen

- Starten Sie im Anschluss wieder den Telegraf Prozess und prüfen Sie, ob nun neben den CPU Metriken weitere Daten im Data Explorer zu finden sind.

### 5. Aktivieren Sie den Debug Modus des Telegraf Services

>Hinweis:
> - Der Parameter sollte bereits in der automatisch erstellten Telegraf Konfiguration aus Schritt 2 zu finden sein.

### 6. Erstellen Sie mit der CLI oder dem Webinterface ein neues Bucket "apache-logs".

### 7. Erstellen Sie im Bereich Load Data - API Tokens einen neuen API Token 

- Der Name sollte TELEGRAF_MULTI_BUCKET_ACCESS lauten und erlauben die den Schreibzugriff auf die beiden neuen Buckets und den Lese Zugriff auf die neue Telegraf Konfiguration
- Speichern Sie den angezeigten Token in die Textdatei


### 8. Editieren Sie über die Weboberfläche die erstellte Telegraf Konfiguration und erweitern Sie sie um einen Bereich für das Apache Acces Log Monitoring unter verwendung der folgenden Konfiguration
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

### 9. Ergänzen Sie die Konfiguration der Outputkomponente  in der Telegrafkonfiguration

- Fügen sie folgende Zeile im Bereich ``[[outputs.influxdb_v2]]`` hinzu

```
bucket_tag = "targetBucket"
```

### 10. Hinterlegen Sie den neuen Access Token und starten Sie Telegraf erneut mit dem Befehl aus Aufgabe 3
```bash

export INFLUX_TOKEN=NEW_ACCESS_TOKEN
```

### 11. Rufen Sie in der VM über einen Browser ihrer Wahl mehrfach die URL der Apache Testseite [http://localhost](http://localhost) auf um Testdaten zu erzeugen und verifizieren Sie im Anschluss über den Data Explorer das sich Daten im Bucket "apache-logs" befinden.
- Rufen Sie gerne auch mehrfach [http://localhost/zonk](http://localhost/zonk) auf um Einträge für nicht erfolgreiche 404 Antworten zu erzeugen
> Hinweis
> - Sie müssen die Aggregierungsfunktion deaktiveren und die Rohwert Ansicht Verwenden damit die Daten angezeigt werden.