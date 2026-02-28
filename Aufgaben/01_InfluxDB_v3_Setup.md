# InfluxDB v3 - Aufgabenfeld 1 : Installation von InfluxDB v3 unter Ubuntu 24.04

### 1. Installation der Abhängigkeiten, Tools und InfluxDB v3 über die Linux Shell

```bash
# zum root-Benutzer wechseln
sudo su

curl --silent --location -O https://repos.influxdata.com/influxdata-archive.key

gpg --show-keys --with-fingerprint --with-colons ./influxdata-archive.key 2>&1 \
| grep -q '^fpr:\+24C975CBA61A024EE1B631787C3D57159FC2F927:$' \
&& cat influxdata-archive.key \
| gpg --dearmor \
| sudo tee /usr/share/keyrings/influxdata-archive.gpg > /dev/null \
&& echo 'deb [signed-by=/usr/share/keyrings/influxdata-archive.gpg] https://repos.influxdata.com/debian stable main' \
| sudo tee /etc/apt/sources.list.d/influxdata.list

sudo apt-get update && sudo apt-get install influxdb3-core

```

> **Hinweis:** Die Konfigurationsdateien und Datenverzeichnisse, liegen anschließend unter `/etc/influxdb3` und `/var/lib/influxdb3`
>- **Konfigurationsdatei:** `/etc/influxdb3/influxdb3-core.conf`
>- **data-dir**: `/var/lib/influxdb3/data`
>- **plugin-dir**: `/var/lib/influxdb3/plugins`

> **Defaults**
>- **object-store**: file
>- **node-id**: primary-node

> Auf einem systemd system wird die InfluxDB unit file unter `/usr/lib/systemd/system/influxdb3-core.service` erstellt. Aber der Service noch nicht gestartet
### 2. Starten und Stoppen der Datenbank

```bash
# Start der Datenbank
systemctl start influxdb3-core

# Prüfen des Status
systemctl status influxdb3-core

# Anzeigen der Log-Dateien
journalctl --unit influxdb3-core

# Stop der Datenbank
systemctl stop influxdb3-core

#Anzeigen der installierten Version
influxdb3 --version
```

### 3. Einrichtung von Authentifizierung und API-Token

> **Wichtiger Hinweis:** InfluxDB v3 Core hat kein standard Web-Interface mehr. Die Verwaltung erfolgt für den Anfang über die CLI oder API.

>Sichern Sie den im nächsten Schritt erstellten Admin-Token in eine Textdatei. Sie können Ihn im Anschluss nicht erneut abrufen.
>Sollten wir das Setup durchgeführt haben finden Sie den Token unter: /workspace/admin-token.txt
```bash
# Erstellugn des Admin-Tokens
sudo su

# Der einfachheit halber wird der Token in der Home-Verzeichnis des Studenten gespeichert
influxdb3 create token --admin > /home/student/Schreibtisch/admin-token.txt
chown student:student /home/student/Schreibtisch/admin-token.txt

# Token in Umgebungsvariable exportieren
export INFLUXDB3_AUTH_TOKEN=TOKEN_FROM_FILE

# Prüfen der Verbindung
influxdb3 show databases
```

Sie sollten folgende Ausgabe erhalten:
```bash
root@student-VirtualBox:/home/student# influxdb3 show databases
+---------------+
| iox::database |
+---------------+
| _internal     |
+---------------+

```
### 4. Ändern Sie den HTTP-Port auf 8082 und validieren Sie die Änderung

> Hinweise:
>
> - Die Konfigurationsdatei des InfluxDB v3 Services finden Sie unter:
>   **/etc/influxdb3/influxdb3-core.conf**
> - Nach der Anpassung muss der Service neugestartet werden
> - Die CLI-Konfiguration muss angepasst werden, da sich die URL durch die Portänderung verändert

```bash
# Bearbeiten der Konfigurationsdatei
nano /etc/influxdb3/influxdb3-core.conf

# Ändern Sie die Zeile:
#http-bind="0.0.0.0:8181"
# zu:
http-bind="0.0.0.0:8182"

# Service neustarten
systemctl restart influxdb3-core

# Status prüfen
systemctl status influxdb3-core
```
Sie sollten folgende Ausgabe erhalten, wenn die Umstellung erfolgreich war:
```bash
INFO influxdb3_server: startup time: 598ms address=0.0.0.0:8182
```

Nun sollte der zugriff über die CLI nicht mehr funktionieren, da die CLI immernoch auf Port 8181 zugreift.
sie müssten nun bei jeder Abfrage die neue URL verwenden:
```bash
influxdb3 show databases --url "http://localhost:8182"
```
> **STELLEN SIE DEN PORT NUN DER EINFACHHEIT HALBER WIEDER AUF 8181**

### 5. Einrichtung des InfluxDB-Explorers per Docker
```bash
sudo su

mkdir -p /docker/influxdb3-explorer/db
mkdir -p /docker/influxdb3-explorer/config

docker run --detach \
--name influxdb3-explorer \
--pull always \
--publish 8888:80 \
--volume /docker/influxdb3-explorer/db:/db:rw \
--volume /docker/influxdb3-explorer/config:/app-root/config:ro \
--env SESSION_SECRET_KEY=$(openssl rand -hex 32) \
--restart unless-stopped \
influxdata/influxdb3-ui:1.6.2 \
--mode=admin


docker ps
```
Sie sollten eine ähnliche Ausgabe wie diese erhalten, wenn der Start erfolgreich war:
```bash
CONTAINER ID   IMAGE                           COMMAND                  CREATED         STATUS         PORTS                                              NAMES
63804cf28902   influxdata/influxdb3-ui:1.6.2   "./entrypoint.sh --m…"   4 seconds ago   Up 2 seconds   443/tcp, 0.0.0.0:8888->80/tcp, [::]:8888->80/tcp   influxdb3-explorer
```

Sie können nun den InfludDB-Explorer unter [http://localhost:8888/](http://localhost:8888/) im Firefox in der virtuellen Maschine erreichen und die Konfiguration dort abschließen.
Fügen Sie in der Weboberflache einen neuen Server hinzu, verwenden Sie dabei folgende Server URL: http://172.17.0.1:8181