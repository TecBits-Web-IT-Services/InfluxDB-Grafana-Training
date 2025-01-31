# InfluxDB - Aufgabenfeld 1 : Setup

## Installation von InfluxDB unter Ubunut 24.04

### 1. Installation der Abhängikeiten, Tools und von InfluxDB über die Shell
    
```bash
# zum root-Benutzer wechseln
sudo su

# installation der Tools und abhängigkeiten für einfacheres arbeiten
apt-get update && apt-get install curl git 

#download des InfluxDB Repository Schlüssels
curl --silent --location -O https://repos.influxdata.com/influxdata-archive.key 

#validierung des Schlüssels und hinzufügen zum Ubuntu Keyring
echo "943666881a1b8d9b849b74caebf02d3465d6beb716510d86a39f6c8e8dac7515  influxdata-archive.key" \
| sha256sum --check - && cat influxdata-archive.key \
| gpg --dearmor \
| tee /etc/apt/trusted.gpg.d/influxdata-archive.gpg > /dev/null \
&& echo 'deb [signed-by=/etc/apt/trusted.gpg.d/influxdata-archive.gpg] https://repos.influxdata.com/debian stable main' \
| tee /etc/apt/sources.list.d/influxdata.list

# Installieren von influxdb2
apt-get update && apt-get install influxdb2

# Starten von InfluxDB als Dienst
service influxdb start

#Prüfen ob der InfluxDB Service aktiv ist
service influxdb status

# Neustarten von InfluxDB
service influxdb restart
```

### 2. Einrichtung des Hauptbenutzers über das Webinterface im Browser

    - Öffnen Sie [das Webinterface](http://localhost:8086) im Browser ihrer Wahl
    - Schließen Sie das initial Setup mit folgenden Daten ab
        - Username: testuser
        - Passwort: Test4711-
        - Initial Organization Name: Test-Organisation
        - Initial Bucket Name: main-bucket
    - speichern Sie den Angezeigten "operator Api Token" in einer Textdatei ab
    - schließen Sie das initial Setup über den Button "Configure Later" ab


### 3. Einrichten der influx-Cli auf der Shell und prüfung der Benutzer-Konfiguration
```bash

# Erstellung einer Benutzerkonfiguration für den gerade angemeldeten Benutzer - diese wird in einer Datei unter /home oder /root, je nach verwendetem Benutzer, im Ordner .influxdbv2 in der Datei configs hinterlegt und kann dort nach der Erstellung auch editiert werden. Zum Beispiel mit vi, vim, nano oder einem anderen beliebigen Texteditor. Änderungen an der Datei erfordern KEINEN Service neustart.

influx config create --config-name "NAME_DER_KONFIGURATION" --host-url "http://localhost:8086" --org "ORGANISATIONS_NAME" --token "OPERATOR_TOKEN" --active

# Anzeige der Hilfe zum Influx CLI Tool
influx --help

# Prüfen ob die Konfiguration erfolgreich angelegt und aktiviert wurde
influx config

#Prüfen ob die Verbindung zum Server besteht
influx ping

#Ausgabe der Serverkonfiguration
influx server-config
```
>Hinweise:
>- Der ``--help`` Parameter kann ach bei Unterbefehlen wie ``influx config --help`` verwendet werden
>- Normalerweise wird die Config auf dem Rechner den Clients und nicht auf dem Server hinterlegt und der Port sollte durch eine Firewall abgesichert werden


### 4. Abschlussaufgabe 

Ändern Sie mithilfe der Liste der [möglichen Konfigurationsparameter](https://docs.influxdata.com/influxdb/v2/reference/config-options/#configuration-options) den Port des Webinterfaces und der HTTP Api auf den PORT 8087 und validieren Sie die Änderung über die Ausgabe der Server Konfiguration


>Hinweise:
>
>- Die Konfigurationsdatei des InfluxDB Service finden Sie unter folgendem Pfad:  
>    **/etc/influxdb/config.toml**
>- Nach der Anpassung mit der Service neugestartet werden
>- Die Benutzerkonfiguration muss Angepasst werden, da sich die Host-Url durch die Portänderung verändert   


