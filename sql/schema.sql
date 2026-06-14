-- SQLite schema for IT/OT production-data portfolio demonstration
-- This schema defines a small synthetic production-data model.
-- The database is intended for local portfolio demonstration only.
-- Raw SQLite database files should be generated locally and not committed to GitHub.

PRAGMA foreign_keys = ON;

CREATE TABLE machines (
id INTEGER PRIMARY KEY AUTOINCREMENT,
machine_id TEXT NOT NULL UNIQUE,
machine_name TEXT NOT NULL,
line_name TEXT NOT NULL,
area_name TEXT NOT NULL,
plc_type TEXT NOT NULL,
opcua_endpoint TEXT NOT NULL,
is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
created_at_utc TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
updated_at_utc TEXT
);

CREATE TABLE production_orders (
id INTEGER PRIMARY KEY AUTOINCREMENT,
order_number TEXT NOT NULL UNIQUE,
machine_db_id INTEGER NOT NULL,
product_code TEXT NOT NULL,
product_name TEXT NOT NULL,
planned_quantity INTEGER NOT NULL CHECK (planned_quantity >= 0),
order_status TEXT NOT NULL CHECK (
order_status IN ('planned', 'running', 'completed', 'cancelled')
),
planned_start_utc TEXT NOT NULL,
planned_end_utc TEXT NOT NULL,
actual_start_utc TEXT,
actual_end_utc TEXT,
created_at_utc TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
updated_at_utc TEXT,
FOREIGN KEY (machine_db_id) REFERENCES machines(id)
);

CREATE TABLE cycle_records (
id INTEGER PRIMARY KEY AUTOINCREMENT,
machine_db_id INTEGER NOT NULL,
order_db_id INTEGER,
cycle_counter INTEGER NOT NULL,
cycle_start_utc TEXT NOT NULL,
cycle_end_utc TEXT NOT NULL,
cycle_time_ms INTEGER NOT NULL CHECK (cycle_time_ms >= 0),
produced_quantity INTEGER NOT NULL DEFAULT 0 CHECK (produced_quantity >= 0),
source_tag TEXT NOT NULL,
description TEXT,
created_at_utc TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
FOREIGN KEY (machine_db_id) REFERENCES machines(id),
FOREIGN KEY (order_db_id) REFERENCES production_orders(id)
);

CREATE TABLE alarm_events (
id INTEGER PRIMARY KEY AUTOINCREMENT,
machine_db_id INTEGER NOT NULL,
order_db_id INTEGER,
alarm_code TEXT NOT NULL,
alarm_message TEXT NOT NULL,
alarm_category TEXT NOT NULL CHECK (
alarm_category IN ('process', 'safety', 'maintenance', 'communication', 'quality', 'other')
),
severity TEXT NOT NULL CHECK (
severity IN ('info', 'warning', 'critical')
),
alarm_start_utc TEXT NOT NULL,
alarm_end_utc TEXT,
acknowledged_at_utc TEXT,
acknowledged_by TEXT,
source_tag TEXT NOT NULL,
description TEXT,
created_at_utc TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
FOREIGN KEY (machine_db_id) REFERENCES machines(id),
FOREIGN KEY (order_db_id) REFERENCES production_orders(id)
);

CREATE TABLE energy_readings (
id INTEGER PRIMARY KEY AUTOINCREMENT,
machine_db_id INTEGER NOT NULL,
order_db_id INTEGER,
reading_start_utc TEXT NOT NULL,
reading_end_utc TEXT NOT NULL,
power_kw_avg REAL NOT NULL CHECK (power_kw_avg >= 0),
energy_kwh REAL NOT NULL CHECK (energy_kwh >= 0),
reading_source TEXT NOT NULL CHECK (
reading_source IN ('opcua', 'scada', 'meter', 'simulation')
),
source_tag TEXT NOT NULL,
description TEXT,
created_at_utc TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
FOREIGN KEY (machine_db_id) REFERENCES machines(id),
FOREIGN KEY (order_db_id) REFERENCES production_orders(id)
);

CREATE TABLE machine_events (
id INTEGER PRIMARY KEY AUTOINCREMENT,
machine_db_id INTEGER NOT NULL,
order_db_id INTEGER,
event_time_utc TEXT NOT NULL,
event_type TEXT NOT NULL CHECK (
event_type IN ('state_change', 'fault', 'operator_action', 'mode_change', 'maintenance', 'other')
),
event_value TEXT,
event_source TEXT NOT NULL,
severity TEXT NOT NULL CHECK (
severity IN ('info', 'warning', 'critical')
),
source_tag TEXT NOT NULL,
description TEXT,
created_at_utc TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
FOREIGN KEY (machine_db_id) REFERENCES machines(id),
FOREIGN KEY (order_db_id) REFERENCES production_orders(id)
);

CREATE INDEX idx_production_orders_machine_db_id
ON production_orders(machine_db_id);

CREATE INDEX idx_cycle_records_machine_db_id
ON cycle_records(machine_db_id);

CREATE INDEX idx_cycle_records_order_db_id
ON cycle_records(order_db_id);

CREATE INDEX idx_cycle_records_cycle_start_utc
ON cycle_records(cycle_start_utc);

CREATE INDEX idx_alarm_events_machine_db_id
ON alarm_events(machine_db_id);

CREATE INDEX idx_alarm_events_order_db_id
ON alarm_events(order_db_id);

CREATE INDEX idx_alarm_events_alarm_code
ON alarm_events(alarm_code);

CREATE INDEX idx_alarm_events_alarm_start_utc
ON alarm_events(alarm_start_utc);

CREATE INDEX idx_energy_readings_machine_db_id
ON energy_readings(machine_db_id);

CREATE INDEX idx_energy_readings_order_db_id
ON energy_readings(order_db_id);

CREATE INDEX idx_energy_readings_reading_start_utc
ON energy_readings(reading_start_utc);

CREATE INDEX idx_machine_events_machine_db_id
ON machine_events(machine_db_id);

CREATE INDEX idx_machine_events_order_db_id
ON machine_events(order_db_id);

CREATE INDEX idx_machine_events_event_time_utc
ON machine_events(event_time_utc);
