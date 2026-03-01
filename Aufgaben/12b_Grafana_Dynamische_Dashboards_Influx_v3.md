# Grafana - Aufgabenfeld 12: Erstellung dynamischer Dashboards mit Variablen (Templating)

### Vorbereitung

Erstellen Sie eine neue Verbindung wie in Aufgabe 11b aber dieses mal mit der Databank "airSensorData" um Zugriff auf die Importierten Sensordaten zu bekommen.

### 1. **Neues Dashboard anlegen**
   Erstellen Sie ein neues Dashboard in Grafana mit dem Namen "air_sensors" und fügen Sie mindestens ein Diagramm-Panel hinzu.

### 2. **Variable definieren**
   - Gehen Sie in den Dashboard-Einstellungen auf den Reiter „Variables" (Variablen).
   - Fügen Sie eine neue Variable mit dem Namen "sensor_id".
   - Definieren Sie die Abfrage zum Abrufen der Hostnamen.
     - **SQL-Abfrage:**
       ```sql
        SELECT DISTINCT sensor_id
        FROM air_sensors
        WHERE sensor_id IS NOT NULL
        ORDER BY sensor_id
       ```
   - Legen Sie ggf. einen Standardwert fest.
   - Aktivieren Sie die Option "Include All Value" mit dem Custom all Value "All"

### 3. **Dashboard-Panel konfigurieren**
   Ändern Sie die Abfrage des Panels, um die Variable zu nutzen. Beispiel:
   ```sql
SELECT
    date_bin(INTERVAL '1 minute', time) AS time,
  sensor_id,
  AVG(temperature) AS temperature
FROM air_sensors
WHERE $__timeFilter(time)
  AND temperature IS NOT NULL
  AND sensor_id IN (${sensor_id:sqlstring})
GROUP BY time, sensor_id
ORDER BY time, sensor_id
   ```

### 4. **Testen**
   Wählen Sie unterschiedliche Sensor-IDs aus der Variable und beobachten Sie die Änderungen im Dashboard.

### 5. **Weiteres Diagramm einfügen**
   Fügen Sie dem Air Sensor Dashboard weitere Diagramme hinzu, um die Luftfeuchtigkeit und den CO-Wert anzuzeigen.

### 6. **Annotations**

> Hinweis: Für diese Aufgabe müssen Sie sie eine weitere Verbindung einrichten, mit der Abfragesprache InfluxQL.
> Dabei muss ein weiterer Custom Header hinzugefügt werden, der Header heißt "Authorization" und der Wert ist "Token ${token}".

   Fügen Sie dem Air Sensor Dashboard in seinen Einstellungen eine Annotation für die Temperatur hinzu, um einen Anstieg des
   Wertes über 75 °C über alle Diagramme des Sensors angezeigt zu bekommen.

   Prüfen Sie im Anschluss, bei welchem Sensor ein solches Ereignis eingetreten ist.

   ```influxql
    SELECT max(temperature) 
    FROM air_sensors 
    WHERE temperature > 75.0 
    GROUP BY time(1h), sensor_id
   ```
