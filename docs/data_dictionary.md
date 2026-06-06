# Data Dictionary

## Purpose

This document describes the database tables, columns, relationships, and validation rules used in the Production Data Model and MES/Database Data Flow project.

The database models a simplified IT/OT scenario where selected machine, production, alarm, cycle, and energy data is stored in structured SQL tables for reporting, troubleshooting, and later analytics.

## Naming Principles

The project uses consistent naming to make the data model easier to understand and maintain.

| Naming pattern | Meaning |
|---|---|
| `id` | Internal database primary key |
| `machine_id` | Readable machine identifier used by engineering and reporting |
| `order_number` | Readable production order identifier |
| `machine_db_id` | Internal foreign key reference to `machines.id` |
| `order_db_id` | Internal foreign key reference to `production_orders.id` |
| `_utc` | Timestamp stored in UTC |
| `_ms` | Duration stored in milliseconds |
| `_kw` | Power value in kilowatts |
| `_kwh` | Energy value in kilowatt-hours |

## Table Overview

| Table | Purpose |
|---|---|
| `machines` | Stores machine master data |
| `production_orders` | Stores simplified MES-style production order information |
| `machine_events` | Stores generic machine timeline events |
| `cycle_records` | Stores measured production cycle records |
| `alarm_events` | Stores structured alarm lifecycle records |
| `energy_readings` | Stores interval-based energy readings |

---

# Table: `machines`

## Purpose

The `machines` table stores master data for production machines.

It is the central reference table for operational records. Other tables such as `production_orders`, `machine_events`, `cycle_records`, `alarm_events`, and `energy_readings` reference this table through `machine_db_id`.

## Columns

| Column | Type | Required | Constraint / Key | Description |
|---|---|---|---|---|
| `id` | INTEGER | Yes | Primary key, autoincrement | Internal database key |
| `machine_id` | TEXT | Yes | Unique | Stable business or factory identifier |
| `machine_name` | TEXT | Yes | None | Human-readable machine name |
| `line_name` | TEXT | Yes | None | Production line name |
| `area_name` | TEXT | No | None | Production area or plant area |
| `plc_type` | TEXT | No | None | PLC platform or controller type |
| `opcua_endpoint` | TEXT | No | None | OPC UA endpoint address |
| `is_active` | INTEGER | Yes | `CHECK(is_active IN (0, 1))` | Defines whether the machine is active |
| `created_at` | TEXT | Yes | Default `datetime('now')` | Database insert timestamp |
| `updated_at` | TEXT | No | None | Reserved for future update tracking |

## Example

| machine_id | machine_name | line_name | plc_type |
|---|---|---|---|
| `M001` | `Packaging Machine 1` | `Packaging Line` | `Siemens S7-1500` |

## Design Notes

`machine_id` is the readable business identifier.

`id` is the internal database key used for relationships.

This separation keeps database relationships stable even if a readable machine identifier or display name changes later.

---

# Table: `production_orders`

## Purpose

The `production_orders` table stores simplified production order information.

It connects production planning data to a machine and provides production order context for events, cycles, alarms, and energy readings.

## Columns

| Column | Type | Required | Constraint / Key | Description |
|---|---|---|---|---|
| `id` | INTEGER | Yes | Primary key, autoincrement | Internal database key |
| `order_number` | TEXT | Yes | Unique | Readable production order number |
| `machine_db_id` | INTEGER | Yes | Foreign key to `machines(id)` | Machine assigned to the order |
| `product_code` | TEXT | Yes | None | Product identifier |
| `product_name` | TEXT | No | None | Human-readable product name |
| `planned_quantity` | INTEGER | Yes | `CHECK(planned_quantity > 0)` | Planned quantity for the order |
| `order_status` | TEXT | Yes | Allowed values only | Current production order status |
| `planned_start_utc` | TEXT | No | None | Planned start timestamp in UTC |
| `planned_end_utc` | TEXT | No | None | Planned end timestamp in UTC |
| `actual_start_utc` | TEXT | No | None | Actual start timestamp in UTC |
| `actual_end_utc` | TEXT | No | None | Actual end timestamp in UTC |
| `created_at` | TEXT | Yes | Default `datetime('now')` | Database insert timestamp |
| `updated_at` | TEXT | No | None | Reserved for future update tracking |

## Allowed Values for `order_status`

| Value | Meaning |
|---|---|
| `planned` | Order is planned but not started |
| `running` | Order is currently active |
| `completed` | Order has been completed |
| `cancelled` | Order has been cancelled |

## Example

| order_number | machine_id | product_code | planned_quantity | order_status |
|---|---|---|---:|---|
| `ORD-2026-001` | `M001` | `PKG-A` | `1000` | `running` |

## Design Notes

`planned_quantity` must be greater than zero.

A production order with zero planned quantity is not valid in this simplified model.

---

# Table: `machine_events`

## Purpose

The `machine_events` table stores timestamped machine events.

It provides a generic machine timeline for state changes, faults, mode changes, maintenance events, and operator actions.

## Columns

| Column | Type | Required | Constraint / Key | Description |
|---|---|---|---|---|
| `id` | INTEGER | Yes | Primary key, autoincrement | Internal database key |
| `machine_db_id` | INTEGER | Yes | Foreign key to `machines(id)` | Machine related to the event |
| `order_db_id` | INTEGER | No | Foreign key to `production_orders(id)` | Optional production order context |
| `event_time_utc` | TEXT | Yes | None | Event timestamp in UTC |
| `event_type` | TEXT | Yes | Allowed values only | Type of machine event |
| `event_value` | TEXT | Yes | None | Event value, state, or alarm code |
| `event_source` | TEXT | Yes | Allowed values only | Source system of the event |
| `severity` | TEXT | Yes | Allowed values only | Event severity |
| `source_tag` | TEXT | No | None | Source signal or OPC UA-style tag |
| `description` | TEXT | No | None | Human-readable explanation |
| `created_at` | TEXT | Yes | Default `datetime('now')` | Database insert timestamp |

## Allowed Values for `event_type`

| Value | Meaning |
|---|---|
| `state_change` | Machine state changed |
| `fault` | Fault event occurred |
| `mode_change` | Machine mode changed |
| `maintenance` | Maintenance-related event |
| `operator_action` | Operator action was recorded |

## Allowed Values for `event_source`

| Value | Meaning |
|---|---|
| `opcua` | Read from OPC UA-style machine signal |
| `hmi` | Entered or triggered from HMI |
| `scada` | Generated from SCADA |
| `manual_entry` | Entered manually |
| `system` | Generated by the system or integration layer |

## Allowed Values for `severity`

| Value | Meaning |
|---|---|
| `info` | Informational event |
| `warning` | Warning event |
| `critical` | Critical event |

## Example

| machine_id | order_number | event_type | event_value | severity |
|---|---|---|---|---|
| `M001` | `ORD-2026-001` | `fault` | `ALM-304` | `critical` |

## Design Notes

`order_db_id` is optional because not every machine event belongs to an active production order.

For example, a machine can switch to automatic mode before an order starts.

---

# Table: `cycle_records`

## Purpose

The `cycle_records` table stores measured production cycle data.

It supports analysis of cycle history, cycle duration, produced quantity, and order-related production behavior.

## Columns

| Column | Type | Required | Constraint / Key | Description |
|---|---|---|---|---|
| `id` | INTEGER | Yes | Primary key, autoincrement | Internal database key |
| `machine_db_id` | INTEGER | Yes | Foreign key to `machines(id)` | Machine related to the cycle |
| `order_db_id` | INTEGER | No | Foreign key to `production_orders(id)` | Optional production order context |
| `cycle_counter` | INTEGER | Yes | `CHECK(cycle_counter >= 0)` | PLC or machine cycle counter |
| `cycle_start_utc` | TEXT | Yes | None | Cycle start timestamp in UTC |
| `cycle_end_utc` | TEXT | Yes | `CHECK(cycle_end_utc >= cycle_start_utc)` | Cycle end timestamp in UTC |
| `cycle_time_ms` | INTEGER | Yes | `CHECK(cycle_time_ms > 0)` | Cycle duration in milliseconds |
| `produced_quantity` | INTEGER | Yes | `CHECK(produced_quantity >= 0)` | Quantity produced during the cycle |
| `source_tag` | TEXT | No | None | Source signal or OPC UA-style tag |
| `description` | TEXT | No | None | Human-readable explanation |
| `created_at` | TEXT | Yes | Default `datetime('now')` | Database insert timestamp |

## Example

| machine_id | order_number | cycle_counter | cycle_time_ms | produced_quantity |
|---|---|---:|---:|---:|
| `M001` | `ORD-2026-001` | `15243` | `6000` | `1` |

## Design Notes

`cycle_counter` is not globally unique.

In real machines, PLC counters can reset after:

- machine restart
- maintenance
- order change
- commissioning
- counter overflow

For this reason, the table uses the internal database column `id` as the primary key.

`cycle_time_ms > 0` ensures measurable cycle duration.

`cycle_end_utc >= cycle_start_utc` prevents logically impossible cycle records.

---

# Table: `alarm_events`

## Purpose

The `alarm_events` table stores structured alarm lifecycle data.

It supports analysis of alarm start time, end time, severity, category, acknowledgement time, and acknowledgement user.

## Columns

| Column | Type | Required | Constraint / Key | Description |
|---|---|---|---|---|
| `id` | INTEGER | Yes | Primary key, autoincrement | Internal database key |
| `machine_db_id` | INTEGER | Yes | Foreign key to `machines(id)` | Machine related to the alarm |
| `order_db_id` | INTEGER | No | Foreign key to `production_orders(id)` | Optional production order context |
| `alarm_code` | TEXT | Yes | None | Alarm code |
| `alarm_message` | TEXT | Yes | None | Human-readable alarm message |
| `alarm_category` | TEXT | Yes | Allowed values only | Alarm category |
| `severity` | TEXT | Yes | Allowed values only | Alarm severity |
| `alarm_start_utc` | TEXT | Yes | None | Alarm start timestamp in UTC |
| `alarm_end_utc` | TEXT | No | Must not be earlier than alarm start | Alarm end timestamp in UTC |
| `acknowledged_at_utc` | TEXT | No | Must not be earlier than alarm start | Alarm acknowledgement timestamp |
| `acknowledged_by` | TEXT | No | None | User or system that acknowledged the alarm |
| `source_tag` | TEXT | No | None | Source signal or OPC UA-style tag |
| `description` | TEXT | No | None | Human-readable explanation |
| `created_at` | TEXT | Yes | Default `datetime('now')` | Database insert timestamp |

## Allowed Values for `alarm_category`

| Value | Meaning |
|---|---|
| `process` | Process-related alarm |
| `safety` | Safety-related alarm |
| `maintenance` | Maintenance-related alarm |
| `communication` | Communication-related alarm |
| `quality` | Quality-related alarm |

## Allowed Values for `severity`

| Value | Meaning |
|---|---|
| `warning` | Warning alarm |
| `critical` | Critical alarm |

## Example

| alarm_code | alarm_message | severity | acknowledged_by |
|---|---|---|---|
| `ALM-304` | `Jam detected at packaging station` | `critical` | `operator_01` |

## Design Notes

`acknowledged_by` is stored as text in this project.

A production-ready system could use a separate operator or user table, but that is outside the current scope.

---

# Table: `energy_readings`

## Purpose

The `energy_readings` table stores interval-based energy data.

It supports analysis of machine energy behavior before, during, or after production events.

## Columns

| Column | Type | Required | Constraint / Key | Description |
|---|---|---|---|---|
| `id` | INTEGER | Yes | Primary key, autoincrement | Internal database key |
| `machine_db_id` | INTEGER | Yes | Foreign key to `machines(id)` | Machine related to the reading |
| `order_db_id` | INTEGER | No | Foreign key to `production_orders(id)` | Optional production order context |
| `reading_start_utc` | TEXT | Yes | None | Start of reading interval in UTC |
| `reading_end_utc` | TEXT | Yes | Must be later than start | End of reading interval in UTC |
| `power_kw_avg` | REAL | Yes | `CHECK(power_kw_avg >= 0)` | Average power in kilowatts |
| `energy_kwh` | REAL | Yes | `CHECK(energy_kwh >= 0)` | Energy consumption in kilowatt-hours |
| `reading_source` | TEXT | Yes | Allowed values only | Source of energy reading |
| `source_tag` | TEXT | No | None | Source signal or OPC UA-style tag |
| `description` | TEXT | No | None | Human-readable explanation |
| `created_at` | TEXT | Yes | Default `datetime('now')` | Database insert timestamp |

## Allowed Values for `reading_source`

| Value | Meaning |
|---|---|
| `opcua` | Read from OPC UA-style signal |
| `meter` | Read from energy meter |
| `scada` | Read from SCADA system |
| `manual_entry` | Entered manually |
| `system` | Generated by the system or integration layer |

## Example

| machine_id | order_number | power_kw_avg | energy_kwh | description |
|---|---|---:|---:|---|
| `M001` | `ORD-2026-001` | `14.2` | `1.18` | Higher power reading shortly before ALM-304 |

## Design Notes

Energy readings are stored as interval records.

Each record represents a time window, not only a single instant.

This project uses energy readings to show a simple troubleshooting relationship around the `ALM-304` scenario.

---

# Relationship Summary

## Main Relationships

| From table | Column | To table | Column | Relationship type |
|---|---|---|---|---|
| `production_orders` | `machine_db_id` | `machines` | `id` | Required |
| `machine_events` | `machine_db_id` | `machines` | `id` | Required |
| `machine_events` | `order_db_id` | `production_orders` | `id` | Optional |
| `cycle_records` | `machine_db_id` | `machines` | `id` | Required |
| `cycle_records` | `order_db_id` | `production_orders` | `id` | Optional |
| `alarm_events` | `machine_db_id` | `machines` | `id` | Required |
| `alarm_events` | `order_db_id` | `production_orders` | `id` | Optional |
| `energy_readings` | `machine_db_id` | `machines` | `id` | Required |
| `energy_readings` | `order_db_id` | `production_orders` | `id` | Optional |

## Required Machine Relationship

Every operational record must belong to a known machine.

This prevents orphan records that cannot be connected to machine context.

## Optional Production Order Relationship

Production order context is optional for operational records.

This supports realistic industrial situations where machine activity can happen outside an active production order.

Examples:

- setup cycle
- maintenance event
- alarm during idle state
- machine mode change before order start
- energy reading during test operation

---

# Timestamp Policy

All timestamps are stored in UTC.

SQLite stores these timestamps as text in this project.

The consistent timestamp format is:

```text
YYYY-MM-DD HH:MM:SS
```

This format keeps ordering and simple time comparisons predictable.

---

# Scope

This data dictionary documents a simplified portfolio database model.

It does not describe a production-ready MES, historian, SCADA archive, or full manufacturing data platform.

The purpose is to show clear database modeling, table relationships, constraints, and IT/OT data flow logic.