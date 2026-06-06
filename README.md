# Production Data Model and MES/Database Data Flow

## Overview

This project demonstrates a simplified IT/OT data architecture for collecting selected machine and production data and storing it in a structured SQLite database.

It shows how automation-side signals such as machine states, alarms, cycle counters, production order context, and energy readings can be transformed into relational database records for MES-style reporting, troubleshooting, and later IT/OT analytics.

The project is implemented with SQLite and includes schema design, sample data, validation queries, constraint tests, screenshots, documentation, and a small Python ingest demo.

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
- documentation for database relationships and IT/OT data flow
- a small runnable Python ingest demo

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

## Repository Structure

```text
production-data-model-mes-flow-public/

├── README.md
├── .gitignore
│
├── sql/
│   ├── schema.sql
│   ├── sample_data.sql
│   ├── validation_queries.sql
│   └── constraint_tests.sql
│
├── scripts/
│   └── simulate_ingest.py
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
│   ├── invalid_energy_value.png
│   └── python_ingest_demo.png
│
└── data/
    └── .gitkeep
```

The local SQLite database file is stored in the `data/` folder during execution, but it is intentionally excluded from Git.

---

## How to Run the Project

### 1. Create a Local SQLite Database

Create a new SQLite database file locally, for example:

```text
data/production_data_model.db
```

The database file is not included in the repository because it is generated locally.

---

### 2. Execute the SQL Files

Run the files in this order:

```text
1. sql/schema.sql
2. sql/sample_data.sql
3. sql/validation_queries.sql
4. sql/constraint_tests.sql
```

Recommended tool:

```text
DB Browser for SQLite
```

---

### 3. Expected Record Counts

After running the schema and sample data, the validation query should return:

| Table | Expected record count |
|---|---:|
| `machines` | 2 |
| `production_orders` | 2 |
| `machine_events` | 4 |
| `cycle_records` | 4 |
| `alarm_events` | 3 |
| `energy_readings` | 4 |

After running the Python ingest demo, the local `machine_events` count increases by one because the script inserts one additional simulated event.

---

### 4. Python Ingest Demo

This project includes a small Python script that simulates one OPC UA-style machine event and inserts it into the local SQLite database.

The script demonstrates:

- opening the SQLite database
- resolving machine and production order references
- inserting one machine event into the `machine_events` table
- preventing duplicate demo inserts when the script is executed more than once

The script does not connect to a real PLC or OPC UA server. It demonstrates the basic ingest logic using simulated machine data.

---

### 5. Run the Python Script

Before running the script, create the local SQLite database and execute:

```text
sql/schema.sql
sql/sample_data.sql
```

Then run:

```text
python scripts/simulate_ingest.py
```

Expected first run:

```text
Simulated ingest completed successfully.
Inserted one machine event into the SQLite database.
Machine: M001
Production order: ORD-2026-001
Event type: operator_action
Event value: fault_acknowledged
```

Expected second run:

```text
Demo event already exists. No duplicate row was inserted.
```

The inserted row can be verified in DB Browser for SQLite using this source tag:

```text
SimulatedIngest.M001.OperatorAction
```

A screenshot of the executed Python ingest demo is available here:

```text
screenshots/python_ingest_demo.png
```

---

### 6. Purpose of the Python Demo

The Python ingest demo is intentionally small.

It is included to show how simulated machine-side data can be inserted into the relational production data model.

In a real industrial environment, this logic could be part of an edge gateway, OPC UA client, SCADA interface, or IT/OT data collector.

For this portfolio project, the script only demonstrates the core ingest concept.

---

## Validation Queries

The project includes validation queries that confirm:

- all main tables were created successfully
- sample data was inserted correctly
- table relationships work through foreign keys
- machine events can be displayed as a timeline
- production cycle data can be summarized by production order
- critical alarms can be filtered
- energy readings can be analyzed around a fault window
- alarm context can be connected to machine and production order data

Screenshots of the validation results are stored in the `screenshots` folder.

---

## Constraint Tests

The project also includes constraint tests that intentionally insert invalid data.

These tests confirm that the database rejects invalid records, such as:

- invalid machine active status
- invalid production order quantity
- invalid cycle time order
- invalid negative energy value

A failed insert is the expected result for these tests because the database is protecting the data model from invalid input.

---

## Key Design Decisions

### Internal Database Keys

Each main table uses an internal primary key named `id`.

Readable business identifiers such as `machine_id` and `order_number` are stored separately.

This keeps database relationships stable even if readable identifiers or display names change later.

---

### Required Machine Context

Operational records require `machine_db_id`.

This means every event, cycle, alarm, or energy reading must belong to a known machine.

This prevents orphan records that cannot be connected to machine context.

---

### Optional Production Order Context

Some operational records include `order_db_id`, but it is optional.

This is intentional because machine activity can happen outside an active production order, for example:

- setup cycles
- maintenance events
- test operation
- mode changes before production
- energy readings during idle periods

---

### UTC Timestamp Policy

All timestamps are stored as UTC text values using a consistent format.

This keeps ordering and comparison predictable in a simplified SQLite model.

In a production system, timestamp handling should also define conversion rules between local plant time, UTC storage, and reporting time zones.

---

### Constraint-Based Validation

The schema uses database constraints to reject basic invalid data.

Examples:

- `is_active` must be `0` or `1`
- `planned_quantity` must be greater than `0`
- `cycle_time_ms` must be greater than `0`
- `cycle_end_utc` must not be earlier than `cycle_start_utc`
- `power_kw_avg` must not be negative

These constraints help protect the data model from invalid records.

---

### Duplicate Prevention in the Python Demo

The Python ingest demo checks whether the same simulated event already exists before inserting it.

The duplicate check uses:

- machine reference
- production order reference
- event timestamp
- event type
- event value
- source tag

This keeps the demo simple while showing the basic idea of avoiding repeated inserts.

---

## Documentation

Additional documentation is available in the `docs/` folder:

| Document | Purpose |
|---|---|
| `architecture_overview.md` | Explains the simplified IT/OT architecture and data flow |
| `opcua_to_database_mapping.md` | Shows how OPC UA-style source tags map to database tables and columns |
| `data_dictionary.md` | Describes tables, columns, constraints, and relationships |
| `validation_results.md` | Summarizes validation queries, expected results, screenshots, and constraint tests |
| `project_summary.md` | Provides a final project overview and conclusion |

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
- basic Python-to-SQLite ingest logic
- duplicate insert prevention
- IT/OT documentation
- troubleshooting-oriented data analysis

---

## Scope

This is a portfolio database modeling project with a small simulated ingest demo.

It demonstrates database structure, relationships, validation logic, sample data, Python-based simulated insertion, and IT/OT data flow documentation.

It does not implement:

- live OPC UA communication
- real PLC connectivity
- production-scale historian storage
- real-time data collection
- dashboard visualization
- OEE calculation
- production MES deployment

---

## Conclusion

The project shows how selected machine and production data can be structured into a relational database model for MES-style reporting, troubleshooting, and later IT/OT analytics.

It is intentionally simplified, but it demonstrates the core logic needed to connect automation-side signals with structured production data.

The Python ingest demo adds a small executable example that shows how simulated machine-side data can be inserted into the database model.