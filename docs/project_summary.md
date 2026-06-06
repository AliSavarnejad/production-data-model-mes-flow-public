# Project Summary

## Project Title

Production Data Model and MES/Database Data Flow

## Overview

This project demonstrates a simplified IT/OT data architecture for collecting selected machine and production data and storing it in a structured SQL database.

The model shows how automation-side signals such as machine states, alarms, cycle counters, production order context, and energy readings can be transformed into relational database records for MES-style reporting, troubleshooting, and later IT/OT analytics.

The project is implemented with SQLite and documented with schema files, sample data, validation queries, constraint tests, and result screenshots.

---

## Project Goal

The goal is to design and validate a database-oriented data model that connects machine data with production context.

The project focuses on:

- machine master data
- production orders
- machine event timelines
- production cycle records
- structured alarm records
- interval-based energy readings
- OPC UA-style signal-to-database mapping
- validation queries and constraint tests

---

## High-Level Data Flow

```text
PLC / Machine
     ↓
OPC UA Server or Source Tags
     ↓
IT/OT Data Collector or Edge Gateway
     ↓
Mapping and Normalization Logic
     ↓
SQLite Production Database
     ↓
MES-style Reporting / Troubleshooting / Analytics
```

---

## Main Database Tables

| Table | Purpose |
|---|---|
| `machines` | Stores machine master data |
| `production_orders` | Stores simplified MES-style production order data |
| `machine_events` | Stores generic timestamped machine events |
| `cycle_records` | Stores measured production cycle records |
| `alarm_events` | Stores structured alarm lifecycle data |
| `energy_readings` | Stores interval-based machine energy readings |

---

## Main Scenario

The sample data describes a simplified production scenario for machine `M001`.

The scenario includes:

- a production order assigned to the machine
- machine start event
- normal production cycles
- a slower cycle shortly before a fault
- critical alarm `ALM-304`
- alarm acknowledgement by an operator
- lower power reading during the fault or idle window
- machine restart after fault clearance

This scenario shows how several database tables can work together to support troubleshooting and production analysis.

---

## Validation Results

The project includes validation queries that confirm:

- all main tables were created successfully
- sample data was inserted correctly
- table relationships work through foreign keys
- machine events can be displayed as a timeline
- production cycle data can be summarized by production order
- critical alarms can be filtered
- energy readings can be analyzed around a fault window
- alarm context can be connected to machine and production order data

The project also includes constraint tests that confirm invalid records are rejected by the database.

Examples include:

- invalid machine active status
- invalid production order quantity
- invalid cycle time order
- invalid negative power value

---

## Key Design Decisions

### Internal Database Keys

Each main table uses an internal primary key named `id`.

Readable business identifiers such as `machine_id` and `order_number` are stored separately.

This keeps relationships stable even if readable names or external identifiers change later.

### Required Machine Context

Operational records require `machine_db_id`.

This means every event, cycle, alarm, or energy reading must belong to a known machine.

This prevents orphan records that cannot be connected to machine context.

### Optional Production Order Context

Some operational records include `order_db_id`, but it is optional.

This is intentional because machine activity can happen outside an active production order, for example:

- setup cycles
- maintenance events
- test operation
- mode changes before production
- energy readings during idle periods

### UTC Timestamp Policy

All timestamps are stored as UTC text values using a consistent format.

This keeps ordering and comparison predictable in a simplified SQLite model.

### Constraint-Based Validation

The schema uses database constraints to reject basic invalid data.

Examples:

- `is_active` must be `0` or `1`
- `planned_quantity` must be greater than `0`
- `cycle_time_ms` must be greater than `0`
- `cycle_end_utc` must not be earlier than `cycle_start_utc`
- `power_kw_avg` must not be negative

---

## Repository Structure

```text
production-data-model-mes-flow-public/
│
├── README.md
├── .gitignore
│
├── sql/
│   ├── schema.sql
│   ├── sample_data.sql
│   ├── validation_queries.sql
│   └── constraint_tests.sql
│
├── docs/
│   ├── architecture_overview.md
│   ├── opcua_to_database_mapping.md
│   ├── data_dictionary.md
│   ├── validation_results.md
│   └── project_summary.md
│
├── screenshots/
│   ├── record_counts.png
│   ├── machine_event_timeline.png
│   ├── cycle_summary_by_order.png
│   ├── critical_alarms.png
│   ├── energy_around_fault_window.png
│   ├── alm304_context.png
│   ├── invalid_machine_active_status.png
│   ├── invalid_production_order_quantity.png
│   ├── invalid_cycle_time_order.png
│   └── invalid_energy_value.png
│
└── data/
    └── .gitkeep
```

---

## Scope

This is a portfolio database modeling project.

It demonstrates database structure, relationships, validation logic, sample data, and IT/OT data flow documentation.

It does not implement:

- live OPC UA communication
- real PLC connectivity
- production-scale historian storage
- real-time data collection
- full MES functionality
- dashboard visualization
- OEE calculation
- production deployment

---

## Skills Demonstrated

This project demonstrates:

- SQL database schema design
- relational data modeling
- foreign key relationships
- constraint-based validation
- machine data structuring
- production order context modeling
- alarm and event data modeling
- OPC UA-style tag mapping
- validation query design
- IT/OT documentation
- troubleshooting-oriented data analysis

---

## Conclusion

The project shows how selected machine and production data can be structured into a relational database model for MES-style reporting, troubleshooting, and later IT/OT analytics.

It is intentionally simplified, but it demonstrates the core logic needed to connect automation-side signals with structured production data.