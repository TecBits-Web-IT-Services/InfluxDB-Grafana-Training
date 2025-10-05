# Lösungsblatt 11 – Grafana Dashboard Export, Import, Sharing und Backups

Dieses Lösungsblatt zeigt die sicheren Wege, Dashboards zu exportieren, importieren, teilen und zu sichern.

## 1. Ziel
- Dashboard-JSON exportiert und versioniert
- Import in anderer Instanz erfolgreich
- Sharing-Optionen bekannt (Link, Snapshot)

## 2. Export (JSON)
- Dashboard öffnen → Share → Export → Export to JSON (Ohne/mit Datenquellenabhängigkeiten je nach Bedarf)
- Datei sinnvoll benennen (z. B. `dashboard_nodes_overview.json`) und ins Repo legen (z. B. `Grafana-Exports/`)

## 3. Import
- Dashboards → New → Import
- JSON-Datei hochladen oder JSON in Textfeld einfügen
- Datenquellen zuordnen (z. B. InfluxDB/Prometheus)
- Import bestätigen → Dashboard prüfen

## 4. Sharing
- Link teilen: Share → Link → „Use current time range/variables“ nach Bedarf aktivieren
- Snapshot: Share → Snapshot → „Local snapshot“ erzeugen (anonymisierte Daten), URL kopieren
- Öffentliche Freigaben (Achtung Security): nur in sicheren Umgebungen nutzen

## 5. Backups (Empfehlungen)
- Regelmäßiger Export der wichtigsten Dashboards ins Versionskontrollsystem
- Grafana Provisioning nutzen (YAML + JSON) für reproduzierbare Deployments
- Optional: Grafana-Instanz-Backups (z. B. Docker-Volume, VM-Snapshots)

## 6. Validierung
- Importiertes Dashboard rendert ohne Fehlermeldungen
- Variablen/Datenquellen korrekt zugeordnet

## 7. Troubleshooting
- Fehlende Datasource: vor Import anlegen
- Versioninkompatibilitäten: ggf. Dashboard JSON aktualisieren
- Private Links: Berechtigungen prüfen (Folder/Team/Viewer)
