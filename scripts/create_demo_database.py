from pathlib import Path
import sqlite3


PROJECT_ROOT = Path(__file__).resolve().parents[1]

SCHEMA_PATH = PROJECT_ROOT / "sql" / "schema.sql"
SAMPLE_DATA_PATH = PROJECT_ROOT / "sql" / "sample_data.sql"

DATABASE_DIR = PROJECT_ROOT / "data" / "generated"
DATABASE_PATH = DATABASE_DIR / "demo_production.db"


def read_sql_file(path: Path) -> str:
    if not path.exists():
        raise FileNotFoundError(f"SQL file not found: {path}")

    return path.read_text(encoding="utf-8")


def create_demo_database() -> None:
    DATABASE_DIR.mkdir(
        parents=True,
        exist_ok=True,
    )

    if DATABASE_PATH.exists():
        DATABASE_PATH.unlink()

    schema_sql = read_sql_file(SCHEMA_PATH)
    sample_data_sql = read_sql_file(SAMPLE_DATA_PATH)

    with sqlite3.connect(DATABASE_PATH) as connection:
        connection.execute("PRAGMA foreign_keys = ON;")
        connection.executescript(schema_sql)
        connection.executescript(sample_data_sql)

    print("Demo SQLite database created successfully.")
    print(f"Database file: {DATABASE_PATH.relative_to(PROJECT_ROOT)}")


if __name__ == "__main__":
    create_demo_database()