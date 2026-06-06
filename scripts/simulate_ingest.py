"""
Simulated OPC UA-style ingest demo.

This script demonstrates how selected machine data can be inserted into
the SQLite production data model.

It does not connect to a real PLC or OPC UA server.
It simulates one machine event and writes it into the local SQLite database.
"""

from pathlib import Path
from typing import Optional
import sqlite3
import sys


PROJECT_ROOT = Path(__file__).resolve().parents[1]
DB_PATH = PROJECT_ROOT / "data" / "production_data_model.db"


def get_single_value(
    cursor: sqlite3.Cursor,
    query: str,
    params: tuple
) -> Optional[int]:
    """
    Execute a query that should return one value.

    Returns:
        The first value from the first row, or None if no row exists.
    """
    cursor.execute(query, params)
    row = cursor.fetchone()

    if row is None:
        return None

    return row[0]


def main() -> int:
    """
    Insert one simulated machine event into the database.

    Required existing sample data:
    - machine_id: M001
    - order_number: ORD-2026-001

    The script checks whether the same demo event already exists.
    This prevents duplicate demo rows when the script is executed more than once.
    """

    if not DB_PATH.exists():
        print(f"Database file not found: {DB_PATH}")
        print("Create the SQLite database first.")
        print("Then run:")
        print("1. sql/schema.sql")
        print("2. sql/sample_data.sql")
        return 1

    connection = sqlite3.connect(DB_PATH)
    connection.execute("PRAGMA foreign_keys = ON;")

    try:
        cursor = connection.cursor()

        machine_db_id = get_single_value(
            cursor,
            "SELECT id FROM machines WHERE machine_id = ?;",
            ("M001",),
        )

        if machine_db_id is None:
            print("Machine M001 was not found.")
            print("Run sql/sample_data.sql before running this script.")
            return 1

        order_db_id = get_single_value(
            cursor,
            "SELECT id FROM production_orders WHERE order_number = ?;",
            ("ORD-2026-001",),
        )

        if order_db_id is None:
            print("Production order ORD-2026-001 was not found.")
            print("Run sql/sample_data.sql before running this script.")
            return 1

        simulated_event = {
            "machine_db_id": machine_db_id,
            "order_db_id": order_db_id,
            "event_time_utc": "2026-06-01 08:45:00",
            "event_type": "operator_action",
            "event_value": "fault_acknowledged",
            "event_source": "manual_entry",
            "severity": "info",
            "source_tag": "SimulatedIngest.M001.OperatorAction",
            "description": (
                "Simulated Python ingest demo: "
                "operator acknowledged the fault after ALM-304."
            ),
        }

        cursor.execute(
            """
            SELECT id
            FROM machine_events
            WHERE machine_db_id = ?
              AND order_db_id = ?
              AND event_time_utc = ?
              AND event_type = ?
              AND event_value = ?
              AND source_tag = ?;
            """,
            (
                simulated_event["machine_db_id"],
                simulated_event["order_db_id"],
                simulated_event["event_time_utc"],
                simulated_event["event_type"],
                simulated_event["event_value"],
                simulated_event["source_tag"],
            ),
        )

        existing_event = cursor.fetchone()

        if existing_event is not None:
            print("Demo event already exists. No duplicate row was inserted.")
            print(f"Existing machine_events.id: {existing_event[0]}")
            return 0

        cursor.execute(
            """
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
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);
            """,
            (
                simulated_event["machine_db_id"],
                simulated_event["order_db_id"],
                simulated_event["event_time_utc"],
                simulated_event["event_type"],
                simulated_event["event_value"],
                simulated_event["event_source"],
                simulated_event["severity"],
                simulated_event["source_tag"],
                simulated_event["description"],
            ),
        )

        connection.commit()

        print("Simulated ingest completed successfully.")
        print("Inserted one machine event into the SQLite database.")
        print("Machine: M001")
        print("Production order: ORD-2026-001")
        print("Event type: operator_action")
        print("Event value: fault_acknowledged")

        return 0

    except sqlite3.Error as error:
        connection.rollback()
        print("SQLite error occurred:")
        print(error)
        return 1

    finally:
        connection.close()


if __name__ == "__main__":
    sys.exit(main())