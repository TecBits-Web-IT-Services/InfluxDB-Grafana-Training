# Lösungsblatt: InfluxDB - Setup

Dieses Lösungsblatt enthält die Lösungen für die Aufgaben aus dem Aufgabenfeld 1: InfluxDB Setup.

## Aufgabe 1: Installation der Abhängigkeiten, Tools und InfluxDB über die Linux Shell

### Lösung:

```bash
# zum root-Benutzer wechseln
sudo su

# Installation der Tools und Abhängigkeiten
apt-get update && apt-get install curl 

# Download des InfluxDB Repository Schlüssels
curl --silent --location -O https://repos.influxdata.com/influxdata-archive.key 

# Validierung des Schlüssels und Hinzufügen zum Ubuntu Keyring
echo "943666881a1b8d9b849b74caebf02d3465d6beb716510d86a39f6c8e8dac7515 influxdata-archive.key" \
| sha256sum --check - && cat influxdata-archive.key \
| gpg --dearmor \
| tee /etc/apt/trusted.gpg.d/influxdata-archive.gpg > /dev/null \
&& echo 'deb [signed-by=/etc/apt/trusted.gpg.d/influxdata-archive.gpg] https://repos.influxdata.com/debian stable main' \
| tee /etc/apt/sources.list.d/influxdata.list

# Installieren von influxdb2
apt-get update && apt-get install influxdb2

# Starten von InfluxDB als Dienst
service influxdb start

# Prüfen ob der InfluxDB Service aktiv ist
service influxdb status

# Neustarten von InfluxDB
service influxdb restart
```

## Aufgabe 2: Einrichtung des Hauptbenutzers über das Webinterface im Browser

### Lösung:

1. Öffnen Sie das Webinterface unter http://localhost:8086 in einem Browser
2. Füllen Sie das Initial Setup Formular mit folgenden Daten aus:
   - Username: testuser
   - Passwort: Test4711-
   - Initial Organization Name: Test-Organisation
   - Initial Bucket Name: main-bucket
3. Speichern Sie den angezeigten "Operator API Token" in einer Textdatei
4. Klicken Sie auf "Configure Later", um das Initial Setup abzuschließen

## Aufgabe 3: Einrichten der influx-CLI auf der Shell und Prüfung der Benutzer-Konfiguration

### Lösung:

```bash
# Erstellung einer Benutzerkonfiguration für den angemeldeten Benutzer
influx config create --config-name "meine_konfiguration" --host-url "http://localhost:8086" --org "Test-Organisation" --token "OPERATOR_TOKEN_AUS_SCHRITT_2" --active

# Anzeige der Hilfe zum Influx CLI Tool
influx --help

# Prüfen ob die Konfiguration erfolgreich angelegt und aktiviert wurde
influx config

# Prüfen ob die Verbindung zum Server besteht
influx ping

# Ausgabe der Serverkonfiguration
influx server-config
```

## Aufgabe 4: Ändern des Ports des Webinterfaces und der HTTP API

### Lösung:

1. Öffnen Sie die Konfigurationsdatei mit einem Texteditor:
   ```bash
   nano /etc/influxdb/config.toml
   ```

2. Suchen Sie den Abschnitt `[http]` und ändern Sie den Port-Eintrag:
   ```toml
   [http]
     # Bind address to use for the HTTP service.
     bind-address = ":8087"
   ```

3. Speichern Sie die Datei und beenden Sie den Editor (bei nano: STRG+O, ENTER, STRG+X)

4. Starten Sie den InfluxDB-Service neu:
   ```bash
   service influxdb restart
   ```

5. Überprüfen Sie, ob der Service mit dem neuen Port läuft:
   ```bash
   service influxdb status
   ```

6. Aktualisieren Sie die Benutzerkonfiguration mit der neuen Host-URL:
   ```bash
   influx config update --name "meine_konfiguration" --host-url "http://localhost:8087"
   ```

7. Überprüfen Sie die aktualisierte Konfiguration:
   ```bash
   influx config
   ```

8. Testen Sie die Verbindung zum Server mit dem neuen Port:
   ```bash
   influx ping
   ```

9. Überprüfen Sie die Serverkonfiguration, um zu bestätigen, dass der Port geändert wurde:
   ```bash
   influx server-config
   ```

10. Öffnen Sie das Webinterface unter der neuen URL: http://localhost:8087

## Zusätzliche Hinweise

- Die Konfigurationsdatei des InfluxDB-Services befindet sich unter `/etc/influxdb/config.toml`
- Nach jeder Änderung an der Konfigurationsdatei muss der Service neu gestartet werden
- Die Benutzerkonfiguration wird in `~/.influxdbv2/configs` gespeichert und kann dort auch manuell bearbeitet werden
- Der `--help` Parameter kann bei allen Unterbefehlen verwendet werden, z.B. `influx config --help`
- Für Produktionsumgebungen sollte der Port durch eine Firewall abgesichert werden
