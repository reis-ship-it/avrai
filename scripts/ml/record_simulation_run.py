#!/usr/bin/env python3
"""Record simulation experiment run and auto-create follow-up for failures."""

from __future__ import annotations

import argparse
import csv
import datetime as dt
from pathlib import Path
import subprocess
import sys
from typing import Dict, List

ROOT = Path(__file__).resolve().parents[2]
RUNS_CSV = ROOT / "configs/ml/simulation_experiment_runs.csv"
REGISTRY_CSV = ROOT / "configs/ml/model_training_registry.csv"
GENERATOR = ROOT / "scripts/generate_ml_training_checklist.py"


def fail(msg: str) -> None:
    print(f"RECORD SIMULATION RUN FAILED: {msg}")
    sys.exit(1)


def now_utc() -> str:
    return dt.datetime.now(dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def read_csv_rows(path: Path) -> List[Dict[str, str]]:
    if not path.exists():
        fail(f"Missing CSV: {path}")
    with path.open("r", encoding="utf-8", newline="") as f:
        return list(csv.DictReader(f))


def write_csv_rows(path: Path, rows: List[Dict[str, str]]) -> None:
    if not rows:
        fail(f"Cannot write empty CSV: {path}")
    fieldnames = list(rows[0].keys())
    with path.open("w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def to_float(value: str) -> float:
    try:
        return float(value)
    except ValueError as e:
        fail(f"Expected numeric value, got '{value}': {e}")


def compute_regression_delta(metric_value: float, threshold: float, direction: str) -> float:
    direction = direction.strip().lower()
    if direction == "gte":
        return round(metric_value - threshold, 6)
    if direction == "lte":
        return round(threshold - metric_value, 6)
    fail("direction must be 'gte' or 'lte'")
    return 0.0


def update_registry_for_failure(model_id: str, failed: bool) -> None:
    rows = read_csv_rows(REGISTRY_CSV)
    changed = False
    for row in rows:
        if row.get("model_id") != model_id:
            continue
        if failed:
            row["status"] = "needs_improvement"
        else:
            if row.get("status") in {"planned", "needs_improvement"}:
                row["status"] = "simulated"
        changed = True
        break
    if not changed:
        fail(f"Unknown model_id in registry: {model_id}")
    write_csv_rows(REGISTRY_CSV, rows)


def regenerate_docs() -> None:
    cmd = ["python3", str(GENERATOR)]
    result = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True, check=False)
    if result.returncode != 0:
        fail(f"Doc generation failed:\n{result.stdout}\n{result.stderr}")
    print(result.stdout.strip())


def main() -> None:
    parser = argparse.ArgumentParser(description="Record a simulation stage run.")
    parser.add_argument("--model-id", required=True)
    parser.add_argument("--stage", required=True, choices=["offline_replay", "shadow", "limited_rollout"])
    parser.add_argument("--status", required=True, choices=["pass", "fail", "pending"])
    parser.add_argument("--metric-name", default="")
    parser.add_argument("--metric-value", default="")
    parser.add_argument("--threshold", default="")
    parser.add_argument("--direction", default="")
    parser.add_argument("--notes", default="")
    parser.add_argument("--no-regenerate", action="store_true")
    args = parser.parse_args()

    run_rows = read_csv_rows(RUNS_CSV)

    run_id = f"sim-{args.model_id}-{args.stage}-{dt.datetime.now(dt.timezone.utc).strftime('%Y%m%d%H%M%S')}"
    started = now_utc()
    completed = now_utc() if args.status in {"pass", "fail"} else ""

    metric_value = to_float(args.metric_value) if args.metric_value else None
    threshold = to_float(args.threshold) if args.threshold else None
    direction = args.direction.strip().lower() if args.direction else ""

    regression_delta = ""
    if metric_value is not None and threshold is not None and direction:
        regression_delta = str(compute_regression_delta(metric_value, threshold, direction))

    followup_id = ""
    followup_status = "none"
    if args.status == "fail":
        followup_id = f"followup-{args.model_id}-{args.stage}-{dt.datetime.now(dt.timezone.utc).strftime('%Y%m%d%H%M%S')}"
        followup_status = "open"

    new_row = {
        "run_id": run_id,
        "model_id": args.model_id,
        "stage": args.stage,
        "started_at_utc": started,
        "completed_at_utc": completed,
        "status": args.status,
        "metric_name": args.metric_name,
        "metric_value": args.metric_value,
        "threshold": args.threshold,
        "direction": direction,
        "regression_delta": regression_delta,
        "auto_created_followup_id": followup_id,
        "followup_status": followup_status,
        "notes": args.notes,
    }
    run_rows.append(new_row)
    write_csv_rows(RUNS_CSV, run_rows)
    update_registry_for_failure(args.model_id, args.status == "fail")

    print(f"Recorded simulation run: {run_id}")
    if followup_id:
        print(f"Auto-created follow-up id: {followup_id}")

    if not args.no_regenerate:
        regenerate_docs()


if __name__ == "__main__":
    main()
