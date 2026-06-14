# Industrial Production Data Analysis Workflow

This project demonstrates a small industrial production-data analysis workflow using SQLite, Python, pandas, and Matplotlib.

The goal is to show how production-related data can be loaded from a relational database, validated, analyzed, exported as CSV files, visualized, and summarized with an engineering interpretation.

The project is designed as a portfolio example for industrial automation, PLC, and IT/OT data-analysis topics.

---

## Project Scenario

The dataset represents a small synthetic production scenario:

* Two machines are included:

  * `M001` Packaging Machine 1
  * `M002` Assembly Station 1
* Two production orders are included.
* The main example event is alarm `ALM-304`, a critical packaging-line fault.
* The analysis reviews machine records, production orders, cycle records, alarm events, energy readings, and machine events.
* The dataset is intentionally small and synthetic.
* The results are not intended to represent real production performance.

---

## Technologies Used

* Python
* pandas
* SQLite
* Matplotlib
* Jupyter Notebook
* SQL

---

## Repository Structure

```text
production-data-model-mes-flow-public/
├── data/
│   └── generated/                 # Local generated database, ignored by Git
├── docs/
│   └── analysis_summary.md
├── notebooks/
│   └── machine_data_analysis.ipynb
├── outputs/
│   ├── figures/
│   │   ├── alarm_count_by_machine.png
│   │   ├── mean_cycle_time_by_machine.png
│   │   ├── production_progress_by_order.png
│   │   └── total_energy_by_machine.png
│   └── tables/
│       ├── analysis_metric_summary.csv
│       ├── export_validation_summary.csv
│       ├── machine_operational_summary.csv
│       ├── production_order_summary.csv
│       └── visualization_export_summary.csv
├── scripts/
│   ├── create_demo_database.py
│   └── simulate_ingest.py
├── sql/
│   ├── constraint_tests.sql
│   ├── sample_data.sql
│   ├── schema.sql
│   └── validation_queries.sql
├── .gitignore
├── README.md
└── requirements.txt
```

---

## Data Model

The simplified data model contains the following tables:

* `machines`
* `production_orders`
* `cycle_records`
* `alarm_events`
* `energy_readings`
* `machine_events`

The tables are connected using:

* `machine_db_id`
* `order_db_id`

This allows analysis at both machine level and production-order level.

---

## How to Reproduce the Demo Database

Install the required packages:

```bash
pip install -r requirements.txt
```

Create the demo SQLite database from the SQL schema and sample data:

```bash
python scripts/create_demo_database.py
```

Expected output:

```text
Demo SQLite database created successfully.
Database file: data/generated/demo_production.db
```

The generated `.db` file is ignored by Git and should not be committed.

---

## How to Run the Analysis

Open the notebook:

```text
notebooks/machine_data_analysis.ipynb
```

Then run all cells.

The notebook performs the following workflow:

1. Detects the project root and database path.
2. Connects to SQLite.
3. Discovers and loads database tables.
4. Validates table structure and data quality.
5. Previews key tables.
6. Analyzes production-cycle duration.
7. Analyzes alarm events.
8. Reviews energy readings around the selected fault window.
9. Builds a machine-level operational summary.
10. Builds a production-order-level summary.
11. Validates exported output files.
12. Creates basic visualizations.
13. Generates a final engineering interpretation.

---

## Generated Outputs

The notebook exports reusable CSV files:

```text
outputs/tables/
├── analysis_metric_summary.csv
├── export_validation_summary.csv
├── machine_operational_summary.csv
├── production_order_summary.csv
└── visualization_export_summary.csv
```

It also exports visualization files:

```text
outputs/figures/
├── alarm_count_by_machine.png
├── mean_cycle_time_by_machine.png
├── production_progress_by_order.png
└── total_energy_by_machine.png
```

---

## Example Visualizations

### Production Progress by Order

![Production Progress by Order](outputs/figures/production_progress_by_order.png)

### Alarm Count by Machine

![Alarm Count by Machine](outputs/figures/alarm_count_by_machine.png)

### Total Energy by Machine

![Total Energy by Machine](outputs/figures/total_energy_by_machine.png)

### Mean Cycle Time by Machine

![Mean Cycle Time by Machine](outputs/figures/mean_cycle_time_by_machine.png)

---

## Key Results from the Sample Dataset

The final analysis summary reports:

* Machines analyzed: `2`
* Active machines: `2`
* Production orders analyzed: `2`
* Total planned quantity: `1500`
* Total produced quantity: `3`
* Overall production progress: `0.20 %`
* Mean order-level progress: `0.15 %`
* Total alarm count: `3`
* Critical alarm count: `1`
* Warning alarm count: `2`
* Total recorded energy: `2.68 kWh`
* Valid CSV exports: `2 of 2`
* Valid figure exports: `4 of 4`

These values are based on a small generated dataset and are intended to demonstrate the workflow rather than evaluate a real production system.

---

## Engineering Interpretation

The project demonstrates how industrial production data from several related tables can be transformed into reusable operational views.

The machine-level summary combines machine master data with cycle counts, produced quantity, alarm counts, energy readings, and machine-event activity.

The production-order summary combines order data with cycle records, alarm records, energy readings, machine events, and machine master data. This makes it possible to review production progress and operational context at order level.

The alarm and energy analysis around `ALM-304` shows how event timestamps and energy readings can be compared in the same workflow. The result should be interpreted as temporal correlation only, not as proof of causation.

---

## Validation Checks

The notebook includes checks for:

* Expected database tables
* Loaded table row and column counts
* Required output variables
* Exported CSV file existence
* Exported CSV row counts
* Required CSV columns
* Exported figure file existence
* Exported figure file size

The project also includes SQL validation files for additional database checks.

---

## Limitations

This project uses a small synthetic dataset.

The results should not be interpreted as real production KPIs or a real OEE calculation.

A real industrial analysis would require more historical data, validated machine-state information, downtime classification, shift context, quality results, maintenance records, and verified production counters.

Alarm duration is not labeled as downtime because alarm records alone do not prove that the machine was stopped.

---

## What This Project Demonstrates

This project demonstrates practical skills in:

* Relational production-data modeling
* SQLite database usage
* SQL schema and sample-data design
* Python-based data loading
* pandas data validation and transformation
* Machine-level and order-level KPI summaries
* CSV export validation
* Matplotlib visualization
* Engineering interpretation of IT/OT production data
* Reproducible portfolio project structure

---

## Author

Ali Savarnejad

Automation / PLC Engineer with focus on IT/OT, industrial data workflows, machine connectivity, and production-data analysis.