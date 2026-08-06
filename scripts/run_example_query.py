"""Run the example alarm/energy overlap query and print a Markdown table.

Usage:
    python scripts/create_demo_database.py
    python scripts/run_example_query.py

The printed table can be pasted directly into README.md.
"""

from __future__ import annotations

import sqlite3
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]
DB_PATH = PROJECT_ROOT / "data" / "generated" / "demo_production.db"
SQL_PATH = PROJECT_ROOT / "sql" / "example_query_alarm_energy.sql"


def format_value(value: object) -> str:
    """Render NULL explicitly so open alarms stay visible in the table."""
    if value is None:
        return "NULL"
    return str(value)


def main() -> None:
    if not DB_PATH.exists():
        raise SystemExit(
            f"Database not found: {DB_PATH}\n"
            "Create it first with: python scripts/create_demo_database.py"
        )
    if not SQL_PATH.exists():
        raise SystemExit(f"Query file not found: {SQL_PATH}")

    sql = SQL_PATH.read_text(encoding="utf-8")

    connection = sqlite3.connect(DB_PATH)
    try:
        connection.execute("PRAGMA foreign_keys = ON;")
        cursor = connection.execute(sql)
        headers = [column[0] for column in cursor.description]
        rows = cursor.fetchall()
    finally:
        connection.close()

    print("| " + " | ".join(headers) + " |")
    print("|" + "|".join(["---"] * len(headers)) + "|")
    for row in rows:
        print("| " + " | ".join(format_value(value) for value in row) + " |")

    print(f"\n{len(rows)} row(s) returned.")


if __name__ == "__main__":
    main()
