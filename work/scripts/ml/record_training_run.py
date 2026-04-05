#!/usr/bin/env python3
"""Record model training completion into canonical registry and regenerate docs."""

from __future__ import annotations

import argparse
import csv
import datetime as dt
import json
from pathlib import Path
import subprocess
import sys
from typing import Dict, List

ROOT = Path(__file__).resolve().parents[2]
REGISTRY_CSV = ROOT / "configs/ml/model_training_registry.csv"
GENERATOR = ROOT / "scripts/generate_ml_training_checklist.py"
AUTO_RECOVERY = ROOT / "scripts/ml/auto_recover_learning_cycles.py"


def fail(msg: str) -> None:
    print(f"RECORD TRAINING RUN FAILED: {msg}")
    sys.exit(1)


def read_registry() -> List[Dict[str, str]]:
    if not REGISTRY_CSV.exists():
        fail(f"Missing registry: {REGISTRY_CSV}")
    with REGISTRY_CSV.open("r", encoding="utf-8", newline="") as f:
        return list(csv.DictReader(f))


def write_registry(rows: List[Dict[str, str]]) -> None:
    if not rows:
        fail("Registry has no rows.")
    fieldnames = list(rows[0].keys())
    with REGISTRY_CSV.open("w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def regenerate_docs() -> None:
    cmd = ["python3", str(GENERATOR)]
    result = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True, check=False)
    if result.returncode != 0:
        fail(f"Doc generation failed:\n{result.stdout}\n{result.stderr}")
    print(result.stdout.strip())


def run_auto_recovery() -> None:
    cmd = ["python3", str(AUTO_RECOVERY)]
    result = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True, check=False)
    if result.returncode != 0:
        fail(f"Auto-recovery sync failed:\n{result.stdout}\n{result.stderr}")
    if result.stdout.strip():
        print(result.stdout.strip())


def main() -> None:
    parser = argparse.ArgumentParser(description="Record model training run metadata.")
    parser.add_argument("--model-id", required=True)
    parser.add_argument("--dataset-snapshot-id", required=True)
    parser.add_argument("--run-id", required=True)
    parser.add_argument("--metrics-json", required=True, help='JSON object string, e.g. {"auc":0.81}')
    parser.add_argument("--artifact-uri", required=True)
    parser.add_argument("--rollback-artifact-uri", required=True)
    parser.add_argument("--status", default="trained")
    parser.add_argument("--execution-milestone-id", default="")
    parser.add_argument("--master-plan-refs", default="")
    parser.add_argument("--trained-at-utc", default="")
    parser.add_argument("--skip-auto-recovery", action="store_true")
    parser.add_argument("--no-regenerate", action="store_true")
    args = parser.parse_args()

    try:
        metrics = json.loads(args.metrics_json)
    except json.JSONDecodeError as e:
        fail(f"Invalid --metrics-json: {e}")
    if not isinstance(metrics, dict):
        fail("--metrics-json must be a JSON object.")

    trained_at = args.trained_at_utc.strip() or dt.datetime.now(dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

    rows = read_registry()
    match = None
    for row in rows:
        if row.get("model_id") == args.model_id:
            match = row
            break
    if match is None:
        fail(f"Unknown model_id: {args.model_id}")

    match["status"] = args.status
    match["last_dataset_snapshot_id"] = args.dataset_snapshot_id
    match["last_run_id"] = args.run_id
    match["last_trained_at_utc"] = trained_at
    match["last_metrics_json"] = json.dumps(metrics, sort_keys=True)
    match["artifact_uri"] = args.artifact_uri
    match["rollback_artifact_uri"] = args.rollback_artifact_uri

    if args.execution_milestone_id:
        match["execution_milestone_id"] = args.execution_milestone_id
    if args.master_plan_refs:
        match["master_plan_refs"] = args.master_plan_refs

    write_registry(rows)
    print(f"Updated training registry for {args.model_id}")

    if not args.skip_auto_recovery:
        run_auto_recovery()

    if not args.no_regenerate:
        regenerate_docs()


if __name__ == "__main__":
    main()
