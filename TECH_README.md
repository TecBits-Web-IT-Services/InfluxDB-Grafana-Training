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

Die Einrichtung der Software erfolgt in mehreren Schritten wenn die Studenten nicht die Initialen Setup Aufgaben übernehmen sollen.
Außerdem gibt es ein Skript um nach der installation zu prüfen ob alle Dienste laufen und erreichbar sind.
Die Skripte dazu befinden sich im Ordner `Skripte`:.

- Hauptskript (führt alle Schritte in korrekter Reihenfolge aus):
  - Skripte/02_setup_software.sh
- Einzelschritte:
  - Skripte/02a_setup_prereqs.sh – Grundpakete (curl, wget, gpg, …)
  - Skripte/02b_install_influxdb.sh – InfluxDB 2
  - Skripte/02c_install_prometheus.sh – Prometheus
  - Skripte/02d_install_node_exporter.sh – Node Exporter
  - Skripte/02e_install_alertmanager.sh – Alertmanager
  - Skripte/02f_install_grafana.sh – Grafana
  - Skripte/02g_add_custom_configs.sh — Add Custom Configs
  - Skripte/03_check_status.sh - Check Services

Wichtig: Alle diese Skripte benötigen Root-Rechte.

- Alles in einem Rutsch installieren (empfohlen):
```
  sudo bash Skripte/02_setup_software.sh
```
- Einzelne Komponenten installieren:
```
  sudo bash Skripte/02b_install_influxdb.sh
  sudo bash Skripte/02c_install_prometheus.sh
  sudo bash Skripte/02d_install_node_exporter.sh
  sudo bash Skripte/02e_install_alertmanager.sh
  sudo bash Skripte/02f_install_grafana.sh
  sudo bash Skripte/02g_add_custom_configs.sh
  sudo bash Skripte/03_check_status.sh
```