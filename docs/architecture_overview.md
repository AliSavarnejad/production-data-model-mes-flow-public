# Architecture Overview

## Purpose

This project demonstrates a simplified IT/OT data architecture for collecting selected machine and production data and storing it in a structured SQL database.

The main goal is to show how automation-side signals can be transformed into useful database records for MES-style reporting, troubleshooting, and later analytics.

## High-Level Data Flow

```text
PLC / Machine
        ↓
OPC UA Server
        ↓
IT/OT Data Collector or Edge Gateway
        ↓
Mapping and Normalization Logic
        ↓
Production Database
        ↓
MES / Reporting / Troubleshooting / Analytics
```

## System Components

### PLC / Machine

The machine or PLC is the source of operational data.

Example data points include:

- machine state
- alarm code
- cycle counter
- cycle time
- produced quantity
- power consumption
- energy consumption

In a real industrial environment, these values may come from PLC tags, HMI systems, SCADA systems, energy meters, or other automation devices.

### OPC UA Server

The OPC UA server provides a standardized interface for accessing machine data.

In this project, OPC UA is represented conceptually through source tags such as:

```text
Machine01.Status.State
Machine01.Alarms.ActiveAlarmCode
Machine01.Production.CycleCounter
Machine01.Energy.Power_kW
```

The project does not implement a live OPC UA client. Instead, it models how selected OPC UA-style signals could be mapped into database tables.

### IT/OT Data Collector or Edge Gateway

The IT/OT data collector represents the layer between the automation network and the database.

Its role is to:

- read selected machine signals
- apply basic validation
- normalize signal names and values
- assign machine and production order context
- write structured records into the database

In a real system, this layer could be implemented using an edge gateway, industrial PC, middleware, SCADA connector, or custom application.

### Mapping and Normalization Logic

Raw machine signals are not always suitable for direct reporting.

The mapping layer converts raw signals into database-ready records.

Examples:

| Source signal | Database target | Purpose |
|---|---|---|
| Machine state | `machine_events.event_value` | Store state changes |
| Active alarm code | `machine_events.event_value` and `alarm_events.alarm_code` | Store generic event and structured alarm |
| Cycle counter | `cycle_records.cycle_counter` | Store production cycle history |
| Power value | `energy_readings.power_kw_avg` | Store energy behavior over time |

This separation makes the database easier to query and explain.

### Production Database

The database stores normalized production-related data.

The main tables are:

| Table | Purpose |
|---|---|
| `machines` | Stores machine master data |
| `production_orders` | Stores simplified MES-style production orders |
| `machine_events` | Stores generic machine timeline events |
| `cycle_records` | Stores measured production cycle data |
| `alarm_events` | Stores structured alarm lifecycle data |
| `energy_readings` | Stores interval-based energy readings |

## Key Design Decisions

### Internal IDs and Business Identifiers

Each table uses an internal database key named `id`.

Business identifiers are stored separately, for example:

```text
machine_id
order_number
```

This keeps database relationships stable while preserving readable identifiers for reporting and documentation.

### Required Machine Context

Operational records require `machine_db_id`.

This means every event, cycle, alarm, or energy reading must belong to a known machine.

This prevents orphan records that cannot be connected to a machine.

### Optional Production Order Context

Some records include `order_db_id`, but it is optional.

This is intentional because some records can happen outside an active production order, for example:

- setup cycles
- maintenance events
- safety door events
- machine mode changes
- test runs before production

### UTC Timestamp Policy

All timestamps are stored in UTC.

This avoids ambiguity when data is exchanged between systems, plants, shifts, or time zones.

### Constraint-Based Validation

The schema uses constraints to reject invalid data.

Examples:

- `is_active` must be `0` or `1`
- `planned_quantity` must be greater than `0`
- `cycle_time_ms` must be greater than `0`
- `cycle_end_utc` must not be earlier than `cycle_start_utc`
- `power_kw_avg` must not be negative

These constraints protect the data model from basic invalid records.

## Example Scenario

The sample data contains an alarm scenario for machine `M001` during production order `ORD-2026-001`.

The scenario includes:

- normal machine start
- production cycles
- a slower cycle shortly before the fault
- critical alarm `ALM-304`
- lower power reading during the fault or idle window
- machine restart after fault clearance

This shows how multiple tables can be used together to support troubleshooting.

## Scope

This project focuses on database modeling, data relationships, validation queries, constraint tests, and documentation.

It does not implement:

- live OPC UA communication
- real PLC communication
- production-ready MES functionality
- dashboard visualization
- OEE calculation
- historical data storage at scale
- user management or operator database