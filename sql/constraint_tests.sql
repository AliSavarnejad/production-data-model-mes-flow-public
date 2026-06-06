-- Production Data Model and MES/Database Data Flow
-- Constraint tests
-- Dialect: SQLite
--
-- Purpose:
-- These tests intentionally try to insert invalid records.
-- The expected result is that SQLite rejects the invalid data.
--
-- Important:
-- Run schema.sql first.
-- Run sample_data.sql second.
-- Then run each test block separately.
--
-- Do not run this entire file at once.
-- Each invalid INSERT is expected to fail.

PRAGMA foreign_keys = ON;

-- ============================================================
-- Test 1: Invalid machine active status
-- Expected result:
-- CHECK constraint failed because is_active must be 0 or 1.
-- ============================================================

INSERT INTO machines (
    machine_id,
    machine_name,
    line_name,
    area_name,
    plc_type,
    opcua_endpoint,
    is_active
)
VALUES
(
    'M999',
    'Invalid Test Machine',
    'Test Line',
    'Test Area',
    'Siemens S7-1500',
    'opc.tcp://invalid-machine.local:4840',
    99
);

-- ============================================================
-- Test 2: Invalid planned quantity
-- Expected result:
-- CHECK constraint failed because planned_quantity must be greater than 0.
-- ============================================================

INSERT INTO production_orders (
    order_number,
    machine_db_id,
    product_code,
    product_name,
    planned_quantity,
    order_status
)
VALUES
(
    'ORD-INVALID-QTY',
    (SELECT id FROM machines WHERE machine_id = 'M001'),
    'BAD-QTY',
    'Invalid Quantity Test',
    0,
    'planned'
);

-- ============================================================
-- Test 3: Invalid production order status
-- Expected result:
-- CHECK constraint failed because order_status must be one of:
-- planned, running, completed, cancelled.
-- ============================================================

INSERT INTO production_orders (
    order_number,
    machine_db_id,
    product_code,
    product_name,
    planned_quantity,
    order_status
)
VALUES
(
    'ORD-INVALID-STATUS',
    (SELECT id FROM machines WHERE machine_id = 'M001'),
    'BAD-STATUS',
    'Invalid Status Test',
    100,
    'paused'
);

-- ============================================================
-- Test 4: Invalid production order machine reference
-- Expected result:
-- FOREIGN KEY constraint failed because machine_db_id = 999 does not exist.
-- ============================================================

INSERT INTO production_orders (
    order_number,
    machine_db_id,
    product_code,
    product_name,
    planned_quantity,
    order_status
)
VALUES
(
    'ORD-INVALID-MACHINE',
    999,
    'BAD-FK',
    'Invalid Machine Reference Test',
    100,
    'planned'
);

-- ============================================================
-- Test 5: Invalid machine event type
-- Expected result:
-- CHECK constraint failed because event_type is not allowed.
-- ============================================================

INSERT INTO machine_events (
    machine_db_id,
    order_db_id,
    event_time_utc,
    event_type,
    event_value,
    event_source,
    severity,
    source_tag,
    description
)
VALUES
(
    (SELECT id FROM machines WHERE machine_id = 'M001'),
    (SELECT id FROM production_orders WHERE order_number = 'ORD-2026-001'),
    '2026-06-01 09:00:00',
    'strange_state',
    'unknown',
    'opcua',
    'info',
    'Machine01.Status.State',
    'Invalid event type test.'
);

-- ============================================================
-- Test 6: Invalid machine event source
-- Expected result:
-- CHECK constraint failed because event_source is not allowed.
-- ============================================================

INSERT INTO machine_events (
    machine_db_id,
    order_db_id,
    event_time_utc,
    event_type,
    event_value,
    event_source,
    severity,
    source_tag,
    description
)
VALUES
(
    (SELECT id FROM machines WHERE machine_id = 'M001'),
    (SELECT id FROM production_orders WHERE order_number = 'ORD-2026-001'),
    '2026-06-01 09:05:00',
    'state_change',
    'running',
    'telegram_message',
    'info',
    'Machine01.Status.State',
    'Invalid event source test.'
);

-- ============================================================
-- Test 7: Invalid machine event severity
-- Expected result:
-- CHECK constraint failed because severity is not allowed.
-- ============================================================

INSERT INTO machine_events (
    machine_db_id,
    order_db_id,
    event_time_utc,
    event_type,
    event_value,
    event_source,
    severity,
    source_tag,
    description
)
VALUES
(
    (SELECT id FROM machines WHERE machine_id = 'M001'),
    (SELECT id FROM production_orders WHERE order_number = 'ORD-2026-001'),
    '2026-06-01 09:10:00',
    'fault',
    'ALM-999',
    'opcua',
    'urgent',
    'Machine01.Alarms.ActiveAlarmCode',
    'Invalid machine event severity test.'
);

-- ============================================================
-- Test 8: Invalid machine event machine reference
-- Expected result:
-- FOREIGN KEY constraint failed because machine_db_id = 999 does not exist.
-- ============================================================

INSERT INTO machine_events (
    machine_db_id,
    order_db_id,
    event_time_utc,
    event_type,
    event_value,
    event_source,
    severity,
    source_tag,
    description
)
VALUES
(
    999,
    NULL,
    '2026-06-01 09:15:00',
    'state_change',
    'running',
    'opcua',
    'info',
    'UnknownMachine.Status.State',
    'Invalid machine reference test.'
);

-- ============================================================
-- Test 9: Invalid machine event order reference
-- Expected result:
-- FOREIGN KEY constraint failed because order_db_id = 999 does not exist.
-- ============================================================

INSERT INTO machine_events (
    machine_db_id,
    order_db_id,
    event_time_utc,
    event_type,
    event_value,
    event_source,
    severity,
    source_tag,
    description
)
VALUES
(
    (SELECT id FROM machines WHERE machine_id = 'M001'),
    999,
    '2026-06-01 09:20:00',
    'state_change',
    'running',
    'opcua',
    'info',
    'Machine01.Status.State',
    'Invalid order reference test.'
);

-- ============================================================
-- Test 10: Invalid cycle time
-- Expected result:
-- CHECK constraint failed because cycle_time_ms must be greater than 0.
-- ============================================================

INSERT INTO cycle_records (
    machine_db_id,
    order_db_id,
    cycle_counter,
    cycle_start_utc,
    cycle_end_utc,
    cycle_time_ms,
    produced_quantity,
    source_tag,
    description
)
VALUES
(
    (SELECT id FROM machines WHERE machine_id = 'M001'),
    (SELECT id FROM production_orders WHERE order_number = 'ORD-2026-001'),
    99901,
    '2026-06-01 09:25:00',
    '2026-06-01 09:25:05',
    0,
    1,
    'Machine01.Production.CycleTime_ms',
    'Invalid cycle time test.'
);

-- ============================================================
-- Test 11: Invalid cycle time order
-- Expected result:
-- CHECK constraint failed because cycle_end_utc is earlier than cycle_start_utc.
-- ============================================================

INSERT INTO cycle_records (
    machine_db_id,
    order_db_id,
    cycle_counter,
    cycle_start_utc,
    cycle_end_utc,
    cycle_time_ms,
    produced_quantity,
    source_tag,
    description
)
VALUES
(
    (SELECT id FROM machines WHERE machine_id = 'M001'),
    (SELECT id FROM production_orders WHERE order_number = 'ORD-2026-001'),
    99902,
    '2026-06-01 09:30:05',
    '2026-06-01 09:30:00',
    5000,
    1,
    'Machine01.Production.CycleCounter',
    'Invalid cycle time order test.'
);

-- ============================================================
-- Test 12: Invalid produced quantity
-- Expected result:
-- CHECK constraint failed because produced_quantity cannot be negative.
-- ============================================================

INSERT INTO cycle_records (
    machine_db_id,
    order_db_id,
    cycle_counter,
    cycle_start_utc,
    cycle_end_utc,
    cycle_time_ms,
    produced_quantity,
    source_tag,
    description
)
VALUES
(
    (SELECT id FROM machines WHERE machine_id = 'M001'),
    (SELECT id FROM production_orders WHERE order_number = 'ORD-2026-001'),
    99903,
    '2026-06-01 09:35:00',
    '2026-06-01 09:35:05',
    5000,
    -1,
    'Machine01.Production.PartsProduced',
    'Invalid produced quantity test.'
);

-- ============================================================
-- Test 13: Invalid cycle machine reference
-- Expected result:
-- FOREIGN KEY constraint failed because machine_db_id = 999 does not exist.
-- ============================================================

INSERT INTO cycle_records (
    machine_db_id,
    order_db_id,
    cycle_counter,
    cycle_start_utc,
    cycle_end_utc,
    cycle_time_ms,
    produced_quantity,
    source_tag,
    description
)
VALUES
(
    999,
    NULL,
    99904,
    '2026-06-01 09:40:00',
    '2026-06-01 09:40:05',
    5000,
    1,
    'UnknownMachine.Production.CycleCounter',
    'Invalid cycle machine reference test.'
);

-- ============================================================
-- Test 14: Invalid alarm category
-- Expected result:
-- CHECK constraint failed because alarm_category is not allowed.
-- ============================================================

INSERT INTO alarm_events (
    machine_db_id,
    order_db_id,
    alarm_code,
    alarm_message,
    alarm_category,
    severity,
    alarm_start_utc,
    source_tag,
    description
)
VALUES
(
    (SELECT id FROM machines WHERE machine_id = 'M001'),
    (SELECT id FROM production_orders WHERE order_number = 'ORD-2026-001'),
    'ALM-997',
    'Invalid alarm category test',
    'random_category',
    'warning',
    '2026-06-01 09:45:00',
    'Machine01.Alarms.WarningCode',
    'Invalid alarm category test.'
);

-- ============================================================
-- Test 15: Invalid alarm severity
-- Expected result:
-- CHECK constraint failed because severity must be warning or critical.
-- ============================================================

INSERT INTO alarm_events (
    machine_db_id,
    order_db_id,
    alarm_code,
    alarm_message,
    alarm_category,
    severity,
    alarm_start_utc,
    source_tag,
    description
)
VALUES
(
    (SELECT id FROM machines WHERE machine_id = 'M001'),
    (SELECT id FROM production_orders WHERE order_number = 'ORD-2026-001'),
    'ALM-998',
    'Invalid alarm severity test',
    'process',
    'urgent',
    '2026-06-01 09:50:00',
    'Machine01.Alarms.ActiveAlarmCode',
    'Invalid alarm severity test.'
);

-- ============================================================
-- Test 16: Invalid alarm time order
-- Expected result:
-- CHECK constraint failed because alarm_end_utc is earlier than alarm_start_utc.
-- ============================================================

INSERT INTO alarm_events (
    machine_db_id,
    order_db_id,
    alarm_code,
    alarm_message,
    alarm_category,
    severity,
    alarm_start_utc,
    alarm_end_utc,
    source_tag,
    description
)
VALUES
(
    (SELECT id FROM machines WHERE machine_id = 'M001'),
    (SELECT id FROM production_orders WHERE order_number = 'ORD-2026-001'),
    'ALM-999',
    'Invalid alarm time order test',
    'process',
    'warning',
    '2026-06-01 10:00:00',
    '2026-06-01 09:55:00',
    'Machine01.Alarms.WarningCode',
    'Invalid alarm time order test.'
);

-- ============================================================
-- Test 17: Invalid alarm acknowledgement time
-- Expected result:
-- CHECK constraint failed because acknowledged_at_utc is earlier than alarm_start_utc.
-- ============================================================

INSERT INTO alarm_events (
    machine_db_id,
    order_db_id,
    alarm_code,
    alarm_message,
    alarm_category,
    severity,
    alarm_start_utc,
    acknowledged_at_utc,
    source_tag,
    description
)
VALUES
(
    (SELECT id FROM machines WHERE machine_id = 'M001'),
    (SELECT id FROM production_orders WHERE order_number = 'ORD-2026-001'),
    'ALM-996',
    'Invalid acknowledgement time test',
    'process',
    'warning',
    '2026-06-01 10:05:00',
    '2026-06-01 10:00:00',
    'Machine01.Alarms.WarningCode',
    'Invalid acknowledgement time test.'
);

-- ============================================================
-- Test 18: Invalid energy value
-- Expected result:
-- CHECK constraint failed because power_kw_avg cannot be negative.
-- ============================================================

INSERT INTO energy_readings (
    machine_db_id,
    order_db_id,
    reading_start_utc,
    reading_end_utc,
    power_kw_avg,
    energy_kwh,
    reading_source,
    source_tag,
    description
)
VALUES
(
    (SELECT id FROM machines WHERE machine_id = 'M001'),
    (SELECT id FROM production_orders WHERE order_number = 'ORD-2026-001'),
    '2026-06-01 10:10:00',
    '2026-06-01 10:15:00',
    -5.0,
    0.40,
    'opcua',
    'Machine01.Energy.Power_kW',
    'Invalid negative power test.'
);

-- ============================================================
-- Test 19: Invalid energy consumption value
-- Expected result:
-- CHECK constraint failed because energy_kwh cannot be negative.
-- ============================================================

INSERT INTO energy_readings (
    machine_db_id,
    order_db_id,
    reading_start_utc,
    reading_end_utc,
    power_kw_avg,
    energy_kwh,
    reading_source,
    source_tag,
    description
)
VALUES
(
    (SELECT id FROM machines WHERE machine_id = 'M001'),
    (SELECT id FROM production_orders WHERE order_number = 'ORD-2026-001'),
    '2026-06-01 10:15:00',
    '2026-06-01 10:20:00',
    5.0,
    -0.40,
    'opcua',
    'Machine01.Energy.Energy_kWh',
    'Invalid negative energy test.'
);

-- ============================================================
-- Test 20: Invalid energy reading time order
-- Expected result:
-- CHECK constraint failed because reading_end_utc is earlier than reading_start_utc.
-- ============================================================

INSERT INTO energy_readings (
    machine_db_id,
    order_db_id,
    reading_start_utc,
    reading_end_utc,
    power_kw_avg,
    energy_kwh,
    reading_source,
    source_tag,
    description
)
VALUES
(
    (SELECT id FROM machines WHERE machine_id = 'M001'),
    (SELECT id FROM production_orders WHERE order_number = 'ORD-2026-001'),
    '2026-06-01 10:25:00',
    '2026-06-01 10:20:00',
    10.0,
    0.80,
    'opcua',
    'Machine01.Energy.Power_kW',
    'Invalid energy time order test.'
);

-- ============================================================
-- Test 21: Invalid energy reading source
-- Expected result:
-- CHECK constraint failed because reading_source is not allowed.
-- ============================================================

INSERT INTO energy_readings (
    machine_db_id,
    order_db_id,
    reading_start_utc,
    reading_end_utc,
    power_kw_avg,
    energy_kwh,
    reading_source,
    source_tag,
    description
)
VALUES
(
    (SELECT id FROM machines WHERE machine_id = 'M001'),
    (SELECT id FROM production_orders WHERE order_number = 'ORD-2026-001'),
    '2026-06-01 10:30:00',
    '2026-06-01 10:35:00',
    10.0,
    0.80,
    'spreadsheet_guess',
    'Machine01.Energy.Power_kW',
    'Invalid energy reading source test.'
);

-- ============================================================
-- Test 22: Invalid energy machine reference
-- Expected result:
-- FOREIGN KEY constraint failed because machine_db_id = 999 does not exist.
-- ============================================================

INSERT INTO energy_readings (
    machine_db_id,
    order_db_id,
    reading_start_utc,
    reading_end_utc,
    power_kw_avg,
    energy_kwh,
    reading_source,
    source_tag,
    description
)
VALUES
(
    999,
    NULL,
    '2026-06-01 10:40:00',
    '2026-06-01 10:45:00',
    8.0,
    0.67,
    'opcua',
    'UnknownMachine.Energy.Power_kW',
    'Invalid energy machine reference test.'
);