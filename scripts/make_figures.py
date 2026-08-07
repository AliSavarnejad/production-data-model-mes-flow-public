"""Regenerate the four report figures from the demo database.

Reads data straight from SQLite with SQL, so the charts always match the
schema and never depend on notebook state.

Usage:
    python scripts/create_demo_database.py
    python scripts/make_figures.py

Writes to outputs/figures/:
    production_progress_by_order.png
    alarm_count_by_machine.png
    total_energy_by_machine.png
    mean_cycle_time_by_machine.png
"""

from __future__ import annotations

import sqlite3
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.ticker import MaxNLocator

PROJECT_ROOT = Path(__file__).resolve().parents[1]
DB_PATH = PROJECT_ROOT / "data" / "generated" / "demo_production.db"
FIG_DIR = PROJECT_ROOT / "outputs" / "figures"

# Shared visual style, matching the data-model diagram.
BLUE = "#14487F"
BLUE_LIGHT = "#7FA8CE"
ORANGE = "#D98324"
GREY = "#8A8A8A"
SEVERITY_COLORS = {"critical": "#C0392B", "warning": ORANGE, "info": BLUE_LIGHT}

plt.rcParams.update({
    "figure.dpi": 150,
    "savefig.dpi": 150,
    "figure.facecolor": "white",
    "axes.facecolor": "white",
    "axes.edgecolor": "#CCCCCC",
    "axes.labelcolor": "#333333",
    "axes.titlesize": 13,
    "axes.titlepad": 30,
    "axes.titleweight": "bold",
    "axes.titlecolor": BLUE,
    "axes.spines.top": False,
    "axes.spines.right": False,
    "font.size": 10,
    "text.color": "#333333",
    "xtick.color": "#555555",
    "ytick.color": "#555555",
})

SUBTITLE = "Synthetic demonstration dataset - not real production performance"


def add_subtitle(ax) -> None:
    ax.text(0.0, 1.012, SUBTITLE, transform=ax.transAxes,
            fontsize=8, color=GREY, ha="left", va="bottom")


def save(fig, name: str) -> None:
    FIG_DIR.mkdir(parents=True, exist_ok=True)
    path = FIG_DIR / name
    fig.savefig(path, bbox_inches="tight", facecolor="white")
    plt.close(fig)
    print(f"wrote {path.relative_to(PROJECT_ROOT)}")


def query(con: sqlite3.Connection, sql: str) -> list[sqlite3.Row]:
    con.row_factory = sqlite3.Row
    return con.execute(sql).fetchall()


# --------------------------------------------------------------------------
# 1. Production progress by order: planned vs produced, log scale
# --------------------------------------------------------------------------
def figure_production_progress(con: sqlite3.Connection) -> None:
    rows = query(con, """
        SELECT po.order_number,
               po.product_code,
               po.planned_quantity,
               COALESCE(SUM(cr.produced_quantity), 0) AS produced_quantity
        FROM production_orders AS po
        LEFT JOIN cycle_records AS cr ON cr.order_db_id = po.id
        GROUP BY po.id
        ORDER BY po.order_number;
    """)

    labels = [f"{r['order_number']}\n{r['product_code']}" for r in rows]
    planned = [r["planned_quantity"] for r in rows]
    produced = [r["produced_quantity"] for r in rows]
    y = range(len(rows))
    height = 0.36

    fig, ax = plt.subplots(figsize=(8, 0.9 * len(rows) + 2.0))
    ax.barh([i + height / 2 for i in y], planned, height,
            color=BLUE_LIGHT, label="Planned quantity")
    ax.barh([i - height / 2 for i in y], produced, height,
            color=BLUE, label="Produced quantity")

    ax.set_yticks(list(y))
    ax.set_yticklabels(labels)
    ax.set_xscale("symlog")
    ax.set_xlabel("Quantity (log scale)")
    ax.set_title("Planned vs produced quantity by production order")
    ax.grid(axis="x", color="#EEEEEE")
    ax.set_axisbelow(True)
    ax.legend(frameon=False, loc="lower right")

    for i, (p, q) in enumerate(zip(planned, produced)):
        ax.text(p, i + height / 2, f" {p}", va="center", fontsize=9, color="#555555")
        pct = (q / p * 100) if p else 0.0
        ax.text(max(q, 0.6), i - height / 2, f" {q}  ({pct:.2f} %)",
                va="center", fontsize=9, color=BLUE)

    add_subtitle(ax)
    save(fig, "production_progress_by_order.png")


# --------------------------------------------------------------------------
# 2. Alarm count by machine, split by severity
# --------------------------------------------------------------------------
def figure_alarm_count(con: sqlite3.Connection) -> None:
    machines = query(con, """
        SELECT id, machine_id, machine_name
        FROM machines
        ORDER BY machine_id;
    """)
    counts = query(con, """
        SELECT machine_db_id, severity, COUNT(*) AS n
        FROM alarm_events
        GROUP BY machine_db_id, severity;
    """)

    by_machine: dict[int, dict[str, int]] = {m["id"]: {} for m in machines}
    for row in counts:
        by_machine[row["machine_db_id"]][row["severity"]] = row["n"]

    labels = [f"{m['machine_id']}\n{m['machine_name']}" for m in machines]
    x = range(len(machines))

    fig, ax = plt.subplots(figsize=(1.9 * len(machines) + 3.0, 4.6))
    bottom = [0.0] * len(machines)
    for severity in ("critical", "warning", "info"):
        values = [by_machine[m["id"]].get(severity, 0) for m in machines]
        if not any(values):
            continue
        ax.bar(list(x), values, 0.5, bottom=bottom,
               color=SEVERITY_COLORS[severity], label=severity)
        for i, (v, b) in enumerate(zip(values, bottom)):
            if v:
                ax.text(i, b + v / 2, str(v), ha="center", va="center",
                        color="white", fontsize=10, fontweight="bold")
        bottom = [b + v for b, v in zip(bottom, values)]

    for i, total in enumerate(bottom):
        if total == 0:
            ax.text(i, 0.05, "no alarms recorded", ha="center",
                    fontsize=9, color=GREY)

    ax.set_ylim(0, (max(bottom) or 1) * 1.28)
    ax.yaxis.set_major_locator(MaxNLocator(integer=True))
    ax.set_xticks(list(x))
    ax.set_xticklabels(labels)
    ax.set_ylabel("Alarm count")
    ax.set_title("Alarm count by machine and severity")
    ax.grid(axis="y", color="#EEEEEE")
    ax.set_axisbelow(True)
    ax.legend(frameon=False, title="Severity")
    add_subtitle(ax)
    save(fig, "alarm_count_by_machine.png")


# --------------------------------------------------------------------------
# 3. Total energy by machine
# --------------------------------------------------------------------------
def figure_total_energy(con: sqlite3.Connection) -> None:
    rows = query(con, """
        SELECT m.machine_id,
               m.machine_name,
               COALESCE(SUM(e.energy_kwh), 0) AS total_kwh,
               COUNT(e.id) AS reading_count
        FROM machines AS m
        LEFT JOIN energy_readings AS e ON e.machine_db_id = m.id
        GROUP BY m.id
        ORDER BY m.machine_id;
    """)

    labels = [f"{r['machine_id']}\n{r['machine_name']}" for r in rows]
    values = [r["total_kwh"] for r in rows]
    x = range(len(rows))

    fig, ax = plt.subplots(figsize=(1.9 * len(rows) + 3.0, 4.6))
    ax.bar(list(x), values, 0.5, color=BLUE)
    for i, (v, r) in enumerate(zip(values, rows)):
        if r["reading_count"] == 0:
            ax.text(i, 0.02 * (max(values) or 1), "no energy readings",
                    ha="center", fontsize=9, color=GREY)
        else:
            ax.text(i, v, f"{v:.2f} kWh", ha="center", va="bottom",
                    fontsize=10, color=BLUE)

    ax.set_xticks(list(x))
    ax.set_xticklabels(labels)
    ax.set_ylim(0, (max(values) or 1) * 1.20)
    ax.set_ylabel("Total energy (kWh)")
    ax.set_title("Total recorded energy by machine")
    ax.grid(axis="y", color="#EEEEEE")
    ax.set_axisbelow(True)
    add_subtitle(ax)
    save(fig, "total_energy_by_machine.png")


# --------------------------------------------------------------------------
# 4. Mean cycle time by machine - every machine shown, gaps made explicit
# --------------------------------------------------------------------------
def figure_mean_cycle_time(con: sqlite3.Connection) -> None:
    rows = query(con, """
        SELECT m.machine_id,
               m.machine_name,
               AVG(cr.cycle_time_ms) AS mean_cycle_time_ms,
               COUNT(cr.id) AS cycle_count
        FROM machines AS m
        LEFT JOIN cycle_records AS cr ON cr.machine_db_id = m.id
        GROUP BY m.id
        ORDER BY m.machine_id;
    """)

    labels = [f"{r['machine_id']}\n{r['machine_name']}" for r in rows]
    values = [r["mean_cycle_time_ms"] or 0.0 for r in rows]
    counts = [r["cycle_count"] for r in rows]
    x = range(len(rows))
    top = max(values) if any(values) else 1.0

    fig, ax = plt.subplots(figsize=(1.9 * len(rows) + 3.0, 4.6))
    colors = [BLUE if c else "#E6E6E6" for c in counts]
    ax.bar(list(x), values, 0.5, color=colors)

    for i, (v, c) in enumerate(zip(values, counts)):
        if c == 0:
            ax.text(i, top * 0.03, "no cycle records\nin the sample data",
                    ha="center", va="bottom", fontsize=9, color=GREY)
        else:
            ax.text(i, v, f"{v:,.0f} ms\n({c} cycles)", ha="center",
                    va="bottom", fontsize=10, color=BLUE)

    ax.set_ylim(0, top * 1.30)
    ax.set_xticks(list(x))
    ax.set_xticklabels(labels)
    ax.set_ylabel("Mean cycle time (ms)")
    ax.set_title("Mean cycle time by machine")
    ax.grid(axis="y", color="#EEEEEE")
    ax.set_axisbelow(True)
    add_subtitle(ax)
    save(fig, "mean_cycle_time_by_machine.png")


def main() -> None:
    if not DB_PATH.exists():
        raise SystemExit(
            f"Database not found: {DB_PATH}\n"
            "Create it first with: python scripts/create_demo_database.py"
        )
    con = sqlite3.connect(DB_PATH)
    try:
        figure_production_progress(con)
        figure_alarm_count(con)
        figure_total_energy(con)
        figure_mean_cycle_time(con)
    finally:
        con.close()
    print("All figures regenerated.")


if __name__ == "__main__":
    main()