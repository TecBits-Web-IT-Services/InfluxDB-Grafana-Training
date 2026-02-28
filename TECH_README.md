![TecBits Logo](https://www.tecbits.de/user/themes/tecbits/images/logo.png)

# TecBits Web & IT Services – Training für InfluxDB/Prometheus und Grafana
## Technische Dokumentation

---

## Download des Workspaces

Das Setup-Skript befindet sich unter `Skripte/01_setup_workspace.sh`. Sie können es mit dem folgenden Befehl in der Bash direkt herunterladen und ausführen.

```
wget -O - https://raw.githubusercontent.com/TecBits-Web-IT-Services/InfluxDB-Grafana-Training/refs/heads/main/Skripte/01_setup_workspace.sh | bash
```

Hinweise:
- Das Skript benötigt unter Ubuntu: `wget` und `unzip`.
- Das Skript erstellt auf dem Desktop des aktuellen Benutzers einen Ordner `Workspace` und lädt dort die neueste Release-Version des Trainings-Repos als ZIP herunter und entpackt sie.
- Wenn Sie ungern per Pipe in die Shell ausführen, nutzen Sie die "Speichern und dann ausführen"-Variante.


---

## Modulare Software-Installation

Die Einrichtung der Software erfolgt in mehreren Schritten wenn die Studenten nicht die initialen Setup-Aufgaben übernehmen sollen.
Alle Skripte sind **idempotent** und können mehrfach ausgeführt werden, ohne Fehler zu verursachen.

### Verfügbare Skripte

Die Skripte befinden sich im Ordner `Skripte`:

- **Hauptskript** (führt alle Schritte in korrekter Reihenfolge aus):
  - `Skripte/02_setup_software.sh`

- **Einzelschritte - Basis-Installation**:
  - `Skripte/02a_setup_prereqs.sh` – Grundpakete (curl, wget, gpg, …)
  - `Skripte/02b_install_influxdb.sh` – InfluxDB 2
  - `Skripte/02bb_install_influxdb_V3.sh` – InfluxDB 3 Core
  - `Skripte/02c_install_prometheus.sh` – Prometheus
  - `Skripte/02d_install_node_exporter.sh` – Node Exporter
  - `Skripte/02e_install_alertmanager.sh` – Alertmanager
  - `Skripte/02f_install_grafana.sh` – Grafana OSS
  - `Skripte/02g_install_docker.sh` – Docker CE

- **Konfiguration & Container**:
  - `Skripte/02h_add_custom_configs.sh` – Prometheus Custom Configs & Alert Rules
  - `Skripte/02i_setup_docker_containers.sh` – InfluxDB v3 Explorer Container

- **Status-Check**:
  - `Skripte/03_check_status.sh` – Prüft alle Dienste und Container

### Wichtige Hinweise

⚠️ **Alle Installations-Skripte benötigen Root-Rechte.**

✅ **Idempotenz**: Alle Skripte können mehrfach ausgeführt werden:
- Prüfen automatisch, ob Software bereits installiert ist
- Überspringen bereits durchgeführte Installationen
- Starten Services nur wenn nötig
- Vermeiden redundante Downloads

⏱️ **Wartezeit**: Das Status-Check-Skript (`03_check_status.sh`) wartet automatisch 20 Sekunden nach Start, damit alle Dienste vollständig hochfahren können.

### Installation durchführen

**Alles in einem Rutsch installieren (empfohlen):**
```bash
sudo bash Skripte/02_setup_software.sh
```

**Einzelne Komponenten installieren:**
```bash
# Grundpakete installieren
sudo bash Skripte/02a_setup_prereqs.sh

# Monitoring-Stack
sudo bash Skripte/02c_install_prometheus.sh
sudo bash Skripte/02d_install_node_exporter.sh
sudo bash Skripte/02e_install_alertmanager.sh

# InfluxDB (v2 ODER v3)
sudo bash Skripte/02b_install_influxdb.sh      # InfluxDB v2
# ODER
sudo bash Skripte/02bb_install_influxdb_V3.sh  # InfluxDB v3 Core

# Visualisierung
sudo bash Skripte/02f_install_grafana.sh

# Docker & Container
sudo bash Skripte/02g_install_docker.sh
sudo bash Skripte/02i_setup_docker_containers.sh  # InfluxDB v3 Explorer

# Konfiguration anpassen
sudo bash Skripte/02h_add_custom_configs.sh

# Status prüfen (wartet 20 Sekunden, dann prüft alle Services)
sudo bash Skripte/03_check_status.sh
```

### Was prüft das Status-Check-Skript?

Das Skript `03_check_status.sh` prüft:
- ✅ Systemd-Dienste (aktiv/inaktiv)
- ✅ HTTP-Endpoints (erreichbar/nicht erreichbar)
- ✅ Docker Container (läuft/gestoppt)
- ✅ InfluxDB v3 Core (Prozess-Status, kein HTTP-Endpoint)

**Ausgabe-Beispiel:**
```
== Dienst- und Erreichbarkeitsprüfung ==
[ OK ] Prometheus: Dienst 'prometheus' ist aktiv
[ OK ] Prometheus: Endpoint erreichbar: http://127.0.0.1:9090/-/healthy
[ OK ] Node Exporter: Dienst 'node_exporter' ist aktiv
[ OK ] Node Exporter: Endpoint erreichbar: http://127.0.0.1:9100/metrics
...
== Docker Container Checks ==
[ OK ] Docker Container 'influxdb3-explorer' läuft
[ OK ] Docker Container 'influxdb3-explorer': Endpoint erreichbar: http://127.0.0.1:8888
```