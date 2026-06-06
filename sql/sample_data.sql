-- Production Data Model and MES/Database Data Flow
-- Sample data
-- Dialect: SQLite
--
-- Purpose:
-- This file inserts realistic sample records into the production data model.
--
-- Important:
-- Run schema.sql first on a clean SQLite database.
-- Then run this file.

PRAGMA foreign_keys = ON;

-- Machine master data

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
    'M001',
    'Packaging Machine 1',
    'Packaging Line',
    'Production Area A',
    'Siemens S7-1500',
    'opc.tcp://machine01.local:4840',
    1
),
(
    'M002',
    'Assembly Station 1',
    'Assembly Line',
    'Production Area B',
    'Siemens S7-1200',
    'opc.tcp://machine02.local:4840',
    1
);

-- Production orders

INSERT INTO production_orders (
    order_number,
    machine_db_id,
    product_code,
    product_name,
    planned_quantity,
    order_status,
    planned_start_utc,
    planned_end_utc,
    actual_start_utc,
    actual_end_utc
)
VALUES
(
    'ORD-2026-001',
    (SELECT id FROM machines WHERE machine_id = 'M001'),
    'PKG-A',
    'Packaging Part A',
    1000,
    'running',
    '2026-06-01 06:00:00',
    '2026-06-01 14:00:00',
    '2026-06-01 06:05:00',
    NULL
),
(
    'ORD-2026-002',
    (SELECT id FROM machines WHERE machine_id = 'M002'),
    'ASM-B',
    'Assembly Part B',
    500,
    'planned',
    '2026-06-01 14:00:00',
    '2026-06-01 22:00:00',
    NULL,
    NULL
);

-- Machine events

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
    '2026-06-01 06:05:00',
    'state_change',
    'running',
    'opcua',
    'info',
    'Machine01.Status.State',
    'Machine started running for production order ORD-2026-001.'
),
(
    (SELECT id FROM machines WHERE machine_id = 'M001'),
    (SELECT id FROM production_orders WHERE order_number = 'ORD-2026-001'),
    '2026-06-01 08:30:00',
    'fault',
    'ALM-304',
    'opcua',
    'critical',
    'Machine01.Alarms.ActiveAlarmCode',
    'Jam detected at packaging station.'
),
(
    (SELECT id FROM machines WHERE machine_id = 'M001'),
    (SELECT id FROM production_orders WHERE order_number = 'ORD-2026-001'),
    '2026-06-01 08:42:00',
    'state_change',
    'running',
    'opcua',
    'info',
    'Machine01.Status.State',
    'Machine restarted after fault clearance.'
),
(
    (SELECT id FROM machines WHERE machine_id = 'M002'),
    NULL,
    '2026-06-01 13:50:00',
    'mode_change',
    'automatic',
    'hmi',
    'info',
    'Machine02.Mode.Automatic',
    'Machine switched to automatic mode before the planned production order.'
);

-- Production cycle records

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
    15241,
    '2026-06-01 06:05:05',
    '2026-06-01 06:05:10',
    5000,
    1,
    'Machine01.Production.CycleCounter',
    'Normal production cycle for ORD-2026-001.'
),
(
    (SELECT id FROM machines WHERE machine_id = 'M001'),
    (SELECT id FROM production_orders WHERE order_number = 'ORD-2026-001'),
    15242,
    '2026-06-01 06:05:10',
    '2026-06-01 06:05:15',
    5000,
    1,
    'Machine01.Production.CycleCounter',
    'Normal production cycle for ORD-2026-001.'
),
(
    (SELECT id FROM machines WHERE machine_id = 'M001'),
    (SELECT id FROM production_orders WHERE order_number = 'ORD-2026-001'),
    15243,
    '2026-06-01 08:28:55',
    '2026-06-01 08:29:01',
    6000,
    1,
    'Machine01.Production.CycleCounter',
    'Slower production cycle before the ALM-304 fault event.'
),
(
    (SELECT id FROM machines WHERE machine_id = 'M002'),
    NULL,
    8001,
    '2026-06-01 13:55:00',
    '2026-06-01 13:55:04',
    4000,
    0,
    'Machine02.Production.CycleCounter',
    'Test cycle before the planned production order.'
);

-- Structured alarm lifecycle records

INSERT INTO alarm_events (
    machine_db_id,
    order_db_id,
    alarm_code,
    alarm_message,
    alarm_category,
    severity,
    alarm_start_utc,
    alarm_end_utc,
    acknowledged_at_utc,
    acknowledged_by,
    source_tag,
    description
)
VALUES
(
    (SELECT id FROM machines WHERE machine_id = 'M001'),
    (SELECT id FROM production_orders WHERE order_number = 'ORD-2026-001'),
    'ALM-304',
    'Jam detected at packaging station',
    'process',
    'critical',
    '2026-06-01 08:30:00',
    '2026-06-01 08:42:00',
    '2026-06-01 08:31:00',
    'operator_01',
    'Machine01.Alarms.ActiveAlarmCode',
    'Critical process alarm during production order ORD-2026-001.'
),
(
    (SELECT id FROM machines WHERE machine_id = 'M001'),
    (SELECT id FROM production_orders WHERE order_number = 'ORD-2026-001'),
    'ALM-120',
    'Low air pressure warning',
    'process',
    'warning',
    '2026-06-01 07:15:00',
    '2026-06-01 07:18:00',
    NULL,
    NULL,
    'Machine01.Alarms.WarningCode',
    'Temporary low air pressure warning during production.'
),
(
    (SELECT id FROM machines WHERE machine_id = 'M002'),
    NULL,
    'ALM-010',
    'Safety door opened during setup',
    'safety',
    'warning',
    '2026-06-01 13:45:00',
    '2026-06-01 13:48:00',
    '2026-06-01 13:46:00',
    'operator_02',
    'Machine02.Safety.DoorStatus',
    'Safety warning during setup before production order start.'
);

-- Energy readings

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
    '2026-06-01 06:05:00',
    '2026-06-01 06:10:00',
    12.5,
    1.04,
    'opcua',
    'Machine01.Energy.Power_kW',
    'Normal production energy reading for ORD-2026-001.'
),
(
    (SELECT id FROM machines WHERE machine_id = 'M001'),
    (SELECT id FROM production_orders WHERE order_number = 'ORD-2026-001'),
    '2026-06-01 08:25:00',
    '2026-06-01 08:30:00',
    14.2,
    1.18,
    'opcua',
    'Machine01.Energy.Power_kW',
    'Higher power reading shortly before ALM-304.'
),
(
    (SELECT id FROM machines WHERE machine_id = 'M001'),
    (SELECT id FROM production_orders WHERE order_number = 'ORD-2026-001'),
    '2026-06-01 08:30:00',
    '2026-06-01 08:35:00',
    2.0,
    0.17,
    'opcua',
    'Machine01.Energy.Power_kW',
    'Lower power reading during fault or idle period.'
),
(
    (SELECT id FROM machines WHERE machine_id = 'M002'),
    NULL,
    '2026-06-01 13:55:00',
    '2026-06-01 14:00:00',
    3.5,
    0.29,
    'opcua',
    'Machine02.Energy.Power_kW',
    'Energy reading during test cycle before production order.'
);