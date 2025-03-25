# InfluxDB - Aufgabenfeld 2 : Buckets und Daten Import

### 1. Erstellen Sie ein Bucket **"testdata-web"** über das Webinterface mit einem Delete Wert von Never über den Reiter **Buckets**

### 2. Importieren Sie die Testdaten **"air-sensor-data.lp"** in das testdata-web Bucket

### 3. Erstellen Sie ein Bucket **"testdata-cli"** über die CLI mit einer Retentionzeit von 0 und lassen Sie sich die Bucket Informationen anzeigen zu lasen
> Hinweis
>
> - Verwenden Sie den Befehl ``influx bucket``
> - Bei Bedarf verwenden Sie die Hilfe (``--help``) um die benötigten Parameter zu bestimmen
> - Sie können entweder den Parameter ``--org-id`` mit der Organisations ID Verwenden ODER den Organisations Namen mit ``--org``
> - Die Werte für beide Parameter finden Sie im Webinterface 

### 4. Importieren Sie die Testdaten "air-sensor-data-annotated.csv" in das testdata-cli Bucket
> Hinweis
>
> - Verwenden Sie den Befehl influx ``write``
> - Bei Bedarf verwenden Sie die Hilfe (``--help``) um die benötigten Parameter zu bestimmen
> - Sie benötigen min. die Parameter ``bucket``, ``format`` und ``file``

### 5. Verwenden Sie die V1 CLI um sich die Bucket Informationen, die Felder, die Messreihen, die Serien und Tags anzeugen zu lasen
> Hinweis
>
> - Verwenden Sie den Befehl ``influx v1 shell``
> - Bei Bedarf verwenden Sie die Hilfe (``help``) 
> - verwenden Sie den ``use BUCKET/DATABASE`` Befehl um das CLI Bucket zu verwenden

### 6. Verwenden Sie den **Data-Explorer** im Webinterface um sich mit diesem Vertraut zu machen und die Importierten Sensor Werte anzuzeigen
> Hinweis
>
>- Eventuell müssen Sie den Zeitraum der Anzeige Vergößern um die Daten zu sehen (Button Links neben dem Button "Script Editor")
>- Spielen sie mit Verschiedenen Diagramm Typen, verschiedenen Window-Perioden, und Agregierungs Methoden

### 7. Verwenden Sie die V1 CLI mit InfluxQL um sich alle Werte aus der airSensors Messreihe anzeigen zu lassen und verfeinern Sie anschließend die Ausgabe um nur die Daten für den Sensor mit der ID TLM0102 anzuzeigen. Optimieren Sie dann die Abfrage um nur Temperatur Werte anzuzeigen. Wie ist der Durchschnittswert der Temperatur?
> Hinweis
>
> - Verwenden Sie den Befehl ``influx v1 shell`` und InfluxQL
> - Bei Bedarf verwenden Sie die Hilfe (``help``) 
> - verwenden Sie den ``use BUCKET/DATABASE`` Befehl um das CLI Bucket zu verwenden
> - ' unterscheiden sich von " :-)




