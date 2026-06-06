-- Production Data Model and MES/Database Data Flow
-- Main database schema
-- Dialect: SQLite
--
-- Purpose:
-- This schema models selected production, machine, alarm, cycle, and energy data
-- for MES-style reporting, troubleshooting, and IT/OT analytics.
--
-- Timestamp policy:
-- All timestamps are stored in UTC.
--
-- Design principles:
-- - Internal database keys use "id".
-- - Business identifiers use names such as "machine_id" and "order_number".
-- - Operational tables use "machine_db_id" to reference machines.
-- - "machine_db_id" is required for operational records.
-- - "order_db_id" is optional because events, cycles, alarms, and energy readings
--   can happen outside an active production order.

PRAGMA foreign_keys = ON;

CREATE TABLE machines (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    machine_id TEXT NOT NULL UNIQUE,
    machine_name TEXT NOT NULL,
    line_name TEXT NOT NULL,
    area_name TEXT,
    plc_type TEXT,
    opcua_endpoint TEXT,
    is_active INTEGER NOT NULL DEFAULT 1 CHECK(is_active IN (0, 1)),
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT
);

CREATE TABLE production_orders (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    order_number TEXT NOT NULL UNIQUE,
    machine_db_id INTEGER NOT NULL,
    product_code TEXT NOT NULL,
    product_name TEXT,
    planned_quantity INTEGER NOT NULL CHECK(planned_quantity > 0),
    order_status TEXT NOT NULL DEFAULT 'planned'
        CHECK(order_status IN ('planned', 'running', 'completed', 'cancelled')),
    planned_start_utc TEXT,
    planned_end_utc TEXT,
    actual_start_utc TEXT,
    actual_end_utc TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT,

    FOREIGN KEY (machine_db_id) REFERENCES machines(id)
);

CREATE TABLE machine_events (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    machine_db_id INTEGER NOT NULL,
    order_db_id INTEGER,
    event_time_utc TEXT NOT NULL,
    event_type TEXT NOT NULL
        CHECK(event_type IN ('state_change', 'fault', 'mode_change', 'maintenance', 'operator_action')),
    event_value TEXT NOT NULL,
    event_source TEXT NOT NULL DEFAULT 'opcua'
        CHECK(event_source IN ('opcua', 'hmi', 'scada', 'manual_entry', 'system')),
    severity TEXT NOT NULL DEFAULT 'info'
        CHECK(severity IN ('info', 'warning', 'critical')),
    source_tag TEXT,
    description TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),

    FOREIGN KEY (machine_db_id) REFERENCES machines(id),
    FOREIGN KEY (order_db_id) REFERENCES production_orders(id)
);

CREATE TABLE cycle_records (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    machine_db_id INTEGER NOT NULL,
    order_db_id INTEGER,
    cycle_counter INTEGER NOT NULL CHECK(cycle_counter >= 0),
    cycle_start_utc TEXT NOT NULL,
    cycle_end_utc TEXT NOT NULL,
    cycle_time_ms INTEGER NOT NULL CHECK(cycle_time_ms > 0),
    produced_quantity INTEGER NOT NULL DEFAULT 1 CHECK(produced_quantity >= 0),
    source_tag TEXT,
    description TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),

    -- cycle_time_ms > 0 ensures measurable duration even when start and end timestamps are equal.
    CHECK(cycle_end_utc >= cycle_start_utc),

    FOREIGN KEY (machine_db_id) REFERENCES machines(id),
    FOREIGN KEY (order_db_id) REFERENCES production_orders(id)
);

CREATE TABLE alarm_events (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    machine_db_id INTEGER NOT NULL,
    order_db_id INTEGER,
    alarm_code TEXT NOT NULL,
    alarm_message TEXT NOT NULL,
    alarm_category TEXT NOT NULL DEFAULT 'process'
        CHECK(alarm_category IN ('process', 'safety', 'quality', 'maintenance', 'communication')),
    severity TEXT NOT NULL
        CHECK(severity IN ('warning', 'critical')),
    alarm_start_utc TEXT NOT NULL,
    alarm_end_utc TEXT,
    acknowledged_at_utc TEXT,
    acknowledged_by TEXT,
    source_tag TEXT,
    description TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),

    CHECK(alarm_end_utc IS NULL OR alarm_end_utc >= alarm_start_utc),
    CHECK(acknowledged_at_utc IS NULL OR acknowledged_at_utc >= alarm_start_utc),

    FOREIGN KEY (machine_db_id) REFERENCES machines(id),
    FOREIGN KEY (order_db_id) REFERENCES production_orders(id)
);

CREATE TABLE energy_readings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    machine_db_id INTEGER NOT NULL,
    order_db_id INTEGER,
    reading_start_utc TEXT NOT NULL,
    reading_end_utc TEXT NOT NULL,
    power_kw_avg REAL NOT NULL CHECK(power_kw_avg >= 0),
    energy_kwh REAL NOT NULL CHECK(energy_kwh >= 0),
    reading_source TEXT NOT NULL DEFAULT 'opcua'
        CHECK(reading_source IN ('opcua', 'meter', 'scada', 'manual_entry', 'system')),
    source_tag TEXT,
    description TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),

    CHECK(reading_end_utc > reading_start_utc),

    FOREIGN KEY (machine_db_id) REFERENCES machines(id),
    FOREIGN KEY (order_db_id) REFERENCES production_orders(id)
);

CREATE INDEX idx_production_orders_machine
ON production_orders(machine_db_id);

CREATE INDEX idx_production_orders_status
ON production_orders(order_status);

CREATE INDEX idx_machine_events_machine
ON machine_events(machine_db_id);

CREATE INDEX idx_machine_events_order
ON machine_events(order_db_id);

CREATE INDEX idx_machine_events_time
ON machine_events(event_time_utc);

CREATE INDEX idx_machine_events_type
ON machine_events(event_type);

CREATE INDEX idx_cycle_records_machine
ON cycle_records(machine_db_id);

CREATE INDEX idx_cycle_records_order
ON cycle_records(order_db_id);

CREATE INDEX idx_cycle_records_start_time
ON cycle_records(cycle_start_utc);

CREATE INDEX idx_alarm_events_machine
ON alarm_events(machine_db_id);

CREATE INDEX idx_alarm_events_order
ON alarm_events(order_db_id);

CREATE INDEX idx_alarm_events_start_time
ON alarm_events(alarm_start_utc);

CREATE INDEX idx_alarm_events_code
ON alarm_events(alarm_code);

CREATE INDEX idx_alarm_events_severity
ON alarm_events(severity);

CREATE INDEX idx_energy_readings_machine
ON energy_readings(machine_db_id);

CREATE INDEX idx_energy_readings_order
ON energy_readings(order_db_id);

CREATE INDEX idx_energy_readings_start_time
ON energy_readings(reading_start_utc);