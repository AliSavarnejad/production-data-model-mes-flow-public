-- Production Data Model and MES/Database Data Flow
-- Validation queries
-- Dialect: SQLite
--
-- Purpose:
-- These queries validate that the production data model stores and connects
-- machine, order, event, cycle, alarm, and energy data correctly.
--
-- Run schema.sql first.
-- Run sample_data.sql second.
-- Then run selected queries from this file.

PRAGMA foreign_keys = ON;

-- Query 1:
-- Show all machines.

SELECT
    id,
    machine_id,
    machine_name,
    line_name,
    area_name,
    plc_type,
    opcua_endpoint,
    is_active,
    created_at
FROM machines
ORDER BY machine_id;

-- Query 2:
-- Show production orders with assigned machine information.
--
-- JOIN is used because every production order must reference a known machine.

SELECT
    po.order_number,
    po.order_status,
    po.product_code,
    po.product_name,
    po.planned_quantity,
    m.machine_id,
    m.machine_name,
    m.line_name,
    po.planned_start_utc,
    po.planned_end_utc,
    po.actual_start_utc,
    po.actual_end_utc
FROM production_orders po
JOIN machines m
    ON po.machine_db_id = m.id
ORDER BY po.order_number;

-- Query 3:
-- Show the full machine event timeline.
--
-- JOIN is used with machines because every event must belong to a machine.
-- LEFT JOIN is used with production_orders because order context is optional.

SELECT
    me.event_time_utc,
    m.machine_id,
    m.machine_name,
    po.order_number,
    me.event_type,
    me.event_value,
    me.event_source,
    me.severity,
    me.source_tag,
    me.description
FROM machine_events me
JOIN machines m
    ON me.machine_db_id = m.id
LEFT JOIN production_orders po
    ON me.order_db_id = po.id
ORDER BY me.event_time_utc;

-- Query 4:
-- Show only fault events.

SELECT
    me.event_time_utc,
    m.machine_id,
    m.machine_name,
    po.order_number,
    me.event_value AS alarm_code,
    me.severity,
    me.description
FROM machine_events me
JOIN machines m
    ON me.machine_db_id = m.id
LEFT JOIN production_orders po
    ON me.order_db_id = po.id
WHERE me.event_type = 'fault'
ORDER BY me.event_time_utc;

-- Query 5:
-- Show the full cycle record timeline.
--
-- LEFT JOIN is used with production_orders because some cycles can happen
-- outside an active production order.

SELECT
    cr.cycle_start_utc,
    cr.cycle_end_utc,
    m.machine_id,
    m.machine_name,
    po.order_number,
    cr.cycle_counter,
    cr.cycle_time_ms,
    cr.produced_quantity,
    cr.source_tag,
    cr.description
FROM cycle_records cr
JOIN machines m
    ON cr.machine_db_id = m.id
LEFT JOIN production_orders po
    ON cr.order_db_id = po.id
ORDER BY cr.cycle_start_utc;

-- Query 6:
-- Summarize cycle performance by production order.
--
-- JOIN is used here intentionally because this summary only includes
-- cycles explicitly linked to a production order.

SELECT
    po.order_number,
    m.machine_id,
    m.machine_name,
    COUNT(cr.id) AS cycle_count,
    SUM(cr.produced_quantity) AS total_produced_quantity,
    ROUND(AVG(cr.cycle_time_ms), 2) AS average_cycle_time_ms,
    MIN(cr.cycle_start_utc) AS first_cycle_start_utc,
    MAX(cr.cycle_end_utc) AS last_cycle_end_utc
FROM cycle_records cr
JOIN machines m
    ON cr.machine_db_id = m.id
JOIN production_orders po
    ON cr.order_db_id = po.id
GROUP BY
    po.order_number,
    m.machine_id,
    m.machine_name
ORDER BY po.order_number;

-- Query 7:
-- Show slower cycles above 5500 ms.

SELECT
    cr.cycle_start_utc,
    m.machine_id,
    m.machine_name,
    po.order_number,
    cr.cycle_counter,
    cr.cycle_time_ms,
    cr.description
FROM cycle_records cr
JOIN machines m
    ON cr.machine_db_id = m.id
LEFT JOIN production_orders po
    ON cr.order_db_id = po.id
WHERE cr.cycle_time_ms > 5500
ORDER BY cr.cycle_time_ms DESC;

-- Query 8:
-- Show the alarm event timeline.
--
-- LEFT JOIN is used with production_orders because alarms can happen
-- outside an active production order.

SELECT
    ae.alarm_start_utc,
    ae.alarm_end_utc,
    m.machine_id,
    m.machine_name,
    po.order_number,
    ae.alarm_code,
    ae.alarm_message,
    ae.alarm_category,
    ae.severity,
    ae.acknowledged_at_utc,
    ae.acknowledged_by,
    ae.source_tag,
    ae.description
FROM alarm_events ae
JOIN machines m
    ON ae.machine_db_id = m.id
LEFT JOIN production_orders po
    ON ae.order_db_id = po.id
ORDER BY ae.alarm_start_utc;

-- Query 9:
-- Show only critical alarms.

SELECT
    ae.alarm_start_utc,
    ae.alarm_end_utc,
    m.machine_id,
    m.machine_name,
    po.order_number,
    ae.alarm_code,
    ae.alarm_message,
    ae.severity,
    ae.description
FROM alarm_events ae
JOIN machines m
    ON ae.machine_db_id = m.id
LEFT JOIN production_orders po
    ON ae.order_db_id = po.id
WHERE ae.severity = 'critical'
ORDER BY ae.alarm_start_utc;

-- Query 10:
-- Show the energy reading timeline.

SELECT
    er.reading_start_utc,
    er.reading_end_utc,
    m.machine_id,
    m.machine_name,
    po.order_number,
    er.power_kw_avg,
    er.energy_kwh,
    er.reading_source,
    er.source_tag,
    er.description
FROM energy_readings er
JOIN machines m
    ON er.machine_db_id = m.id
LEFT JOIN production_orders po
    ON er.order_db_id = po.id
ORDER BY er.reading_start_utc;

-- Query 11:
-- Summarize energy consumption by production order.
--
-- JOIN is used here intentionally because this summary only includes
-- energy readings explicitly linked to a production order.

SELECT
    po.order_number,
    m.machine_id,
    m.machine_name,
    COUNT(er.id) AS reading_count,
    ROUND(SUM(er.energy_kwh), 3) AS total_energy_kwh,
    ROUND(AVG(er.power_kw_avg), 2) AS average_power_kw
FROM energy_readings er
JOIN machines m
    ON er.machine_db_id = m.id
JOIN production_orders po
    ON er.order_db_id = po.id
GROUP BY
    po.order_number,
    m.machine_id,
    m.machine_name
ORDER BY po.order_number;

-- Query 12:
-- Show energy readings around the ALM-304 fault window.

SELECT
    er.reading_start_utc,
    er.reading_end_utc,
    m.machine_id,
    m.machine_name,
    er.power_kw_avg,
    er.energy_kwh,
    er.description
FROM energy_readings er
JOIN machines m
    ON er.machine_db_id = m.id
WHERE m.machine_id = 'M001'
  AND er.reading_start_utc >= '2026-06-01 08:25:00'
  AND er.reading_end_utc <= '2026-06-01 08:35:00'
ORDER BY er.reading_start_utc;

-- Query 13:
-- Show the complete ALM-304 context from alarm_events.

SELECT
    ae.alarm_code,
    ae.alarm_message,
    ae.severity,
    ae.alarm_start_utc,
    ae.alarm_end_utc,
    ae.acknowledged_at_utc,
    ae.acknowledged_by,
    m.machine_id,
    m.machine_name,
    po.order_number,
    ae.description
FROM alarm_events ae
JOIN machines m
    ON ae.machine_db_id = m.id
LEFT JOIN production_orders po
    ON ae.order_db_id = po.id
WHERE ae.alarm_code = 'ALM-304';

-- Query 14:
-- Show machine records that are not active.

SELECT
    machine_id,
    machine_name,
    line_name,
    is_active
FROM machines
WHERE is_active = 0;

-- Query 15:
-- Count records in each main table.

SELECT 'machines' AS table_name, COUNT(*) AS record_count FROM machines
UNION ALL
SELECT 'production_orders', COUNT(*) FROM production_orders
UNION ALL
SELECT 'machine_events', COUNT(*) FROM machine_events
UNION ALL
SELECT 'cycle_records', COUNT(*) FROM cycle_records
UNION ALL
SELECT 'alarm_events', COUNT(*) FROM alarm_events
UNION ALL
SELECT 'energy_readings', COUNT(*) FROM energy_readings;