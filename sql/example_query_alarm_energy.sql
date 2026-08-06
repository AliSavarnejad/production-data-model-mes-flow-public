-- example_query_alarm_energy.sql
--
-- Example analysis query for the industrial production data model.
--
-- It joins every alarm event to the energy readings of the same machine
-- whose measurement interval overlaps the alarm window, and returns the
-- alarm duration together with the energy recorded during that window.
--
-- Alarm duration is calculated from alarm_start_utc and alarm_end_utc.
-- It is deliberately NOT treated as machine downtime: an alarm record
-- alone does not prove that the machine was stopped.
--
-- alarm_end_utc is nullable. An alarm that is still open returns NULL
-- for alarm_minutes and matches no energy readings.

SELECT
    m.machine_id,
    m.machine_name,
    a.alarm_code,
    a.alarm_category,
    a.severity,
    a.alarm_start_utc,
    a.alarm_end_utc,
    ROUND(
        (julianday(a.alarm_end_utc) - julianday(a.alarm_start_utc)) * 1440.0,
        2
    )                                AS alarm_minutes,
    COUNT(e.id)                      AS overlapping_energy_readings,
    ROUND(SUM(e.energy_kwh), 3)      AS energy_kwh_in_alarm_window,
    ROUND(AVG(e.power_kw_avg), 3)    AS avg_power_kw_in_alarm_window
FROM alarm_events AS a
JOIN machines AS m
    ON m.id = a.machine_db_id
LEFT JOIN energy_readings AS e
    ON  e.machine_db_id     = a.machine_db_id
    AND e.reading_start_utc <  a.alarm_end_utc
    AND e.reading_end_utc   >  a.alarm_start_utc
GROUP BY a.id
ORDER BY a.alarm_start_utc;
