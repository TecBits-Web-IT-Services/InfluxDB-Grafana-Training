# InfluxDB - Aufgabenfeld 3 : Backups und Datenexport

### 1. Erstellen Sie ein komplettes Backup ihrer InfluxDB Datenbank über die Influx CLI
> Hinweis
>
> - Verwenden Sie den Befehl ``influx backup``
> - Bei Bedarf verwenden Sie die Hilfe (``--help``) um die benötigten Parameter zu bestimmen
> - Standardmässig wird GZIP als Kompression verwendet, weshalb der zu wählende Dateiname mit ``.gz`` enden sollte

### 2. Löschen Sie eines der erstellten Buckets über die Influx CLI und verifizieren Sie das es nicht mehr vorhanden ist.
> Hinweis
>
> - Verwenden Sie den Befehl ``influx bucket``
> - Bei Bedarf verwenden Sie die Hilfe (``--help``) um die benötigten Parameter zu bestimmen

### 3. Stellen Sie über die Influx CLI mithilfe des in Aufgabe 1 erstelten Backups das gelöschte Bucket wieder her und überprüfen Sie ob das gelöschte Bucket wieder vorhanden ist
> Hinweis
>
> - Wir stellen nur ein Bucket wieder her, deshalb ist die angabe des Bucket Namens erforderlich, alternativ kann die komplette Instanz mit dem ``--full`` Parameter wiederhergestellt werden
> - Verwenden Sie den Befehl ``influx restore``
> - Bei Bedarf verwenden Sie die Hilfe (``--help``) um die benötigten Parameter zu bestimmen

### 4. Erstellen Sie einen CSV Export der Temperatur Werte des Sensors TLM0102 aus dem CLI Bucket mithilfe von Flux
> Hinweis
>
> - Verwenden Sie den Befehl ``influx query`` als Basis, z.B.: (``influx query --raw 'FLUXQUERY'``)
> - Der ``--raw`` Parameter sorgt dafür, das die Ausgabe als Annotated CSV erfolgt, diese kann direkt in eine Datei umgeleitet werden (``BEFEHL > output.csv``)
> - Sie können sich eine Beispielhafte Abfrage über das Webinterface des Data Explorers zusammenstellen, allerdings kann diese nicht ohne Anpassung verwendet werden
> - Verwenden Sie als Range für die Abfrage ``|> range(start: -30d)``
> - Bei Bedarf verwenden Sie die Hilfe (``--help``) um die benötigten Parameter zu bestimmen