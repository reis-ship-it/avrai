#!/usr/bin/env python3
"""Detect and auto-schedule recovery for broken learning cycles.

Canonical inputs:
- configs/ml/model_training_registry.csv
- configs/ml/simulation_experiment_runs.csv
- configs/ml/simulation_experiment_contracts.json
- configs/ml/learning_cycle_recovery_queue.csv

This script supports:
- --check: fail if recovery queue/registry/runs are out of sync with detected state.
- --apply-fixes: schedule deterministic recovery attempts (append pending runs + mark recovering).
"""

from __future__ import annotations

import argparse
import csv
import datetime as dt
import json
from pathlib import Path
import sys
from typing import Dict, List, Tuple

ROOT = Path(__file__).resolve().parents[2]

REGISTRY_CSV = ROOT / "configs/ml/model_training_registry.csv"
SIM_RUNS_CSV = ROOT / "configs/ml/simulation_experiment_runs.csv"
SIM_CONTRACTS_JSON = ROOT / "configs/ml/simulation_experiment_contracts.json"
RECOVERY_QUEUE_CSV = ROOT / "configs/ml/learning_cycle_recovery_queue.csv"

RECOVERY_FIELDS = [
    "recovery_id",
    "model_id",
    "entity_type",
    "trigger_type",
    "trigger_stage",
    "trigger_run_id",
    "detected_at_utc",
    "status",
    "attempt_count",
    "last_attempt_at_utc",
    "resolved_at_utc",
    "action_plan",
    "next_action",
    "notes",
]


def fail(message: str) -> None:
    print(f"LEARNING CYCLE AUTO-RECOVERY FAILED: {message}")
    sys.exit(1)


def now_utc() -> str:
    return dt.datetime.now(dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def read_csv_rows(path: Path) -> List[Dict[str, str]]:
    if not path.exists():
        fail(f"Missing CSV: {path}")
    with path.open("r", encoding="utf-8", newline="") as f:
        return list(csv.DictReader(f))


def write_csv_rows(path: Path, rows: List[Dict[str, str]], fieldnames: List[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def read_json(path: Path) -> Dict:
    if not path.exists():
        fail(f"Missing JSON: {path}")
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def latest_runs_by_model_stage(sim_runs: List[Dict[str, str]]) -> Dict[Tuple[str, str], Dict[str, str]]:
    latest: Dict[Tuple[str, str], Dict[str, str]] = {}
    for row in sim_runs:
        model_id = row.get("model_id", "")
        stage = row.get("stage", "")
        key = (model_id, stage)
        completed = row.get("completed_at_utc", "") or ""
        started = row.get("started_at_utc", "") or ""
        stamp = completed or started
        current = latest.get(key)
        if current is None:
            latest[key] = row
            continue
        current_stamp = (current.get("completed_at_utc", "") or current.get("started_at_utc", "") or "")
        if stamp >= current_stamp:
            latest[key] = row
    return latest


def recovery_id(model_id: str, trigger_type: str, trigger_stage: str) -> str:
    stage = trigger_stage or "none"
    return f"recovery-{model_id}-{trigger_type}-{stage}"


def parse_int(value: str, default: int = 0) -> int:
    try:
        return int(value)
    except (TypeError, ValueError):
        return default


def normalize_status(value: str) -> str:
    return (value or "").strip().lower()


def model_break_state(
    model: Dict[str, str],
    stages: List[str],
    latest_stage_runs: Dict[Tuple[str, str], Dict[str, str]],
) -> Dict[str, str]:
    model_id = model.get("model_id", "")
    model_status = normalize_status(model.get("status", ""))

    # Highest-priority break: any failed latest stage run.
    for stage in stages:
        run = latest_stage_runs.get((model_id, stage))
        if run and normalize_status(run.get("status", "")) == "fail":
            return {
                "is_broken": "true",
                "trigger_type": "stage_fail",
                "trigger_stage": stage,
                "trigger_run_id": run.get("run_id", ""),
                "detected_at_utc": run.get("completed_at_utc", "") or run.get("started_at_utc", ""),
                "action_plan": "rerun_stage_then_advance_or_rollback",
                "next_action": f"record_simulation_run:{stage}:pending",
                "notes": "Latest required stage has failed.",
            }

    if model_status in {"needs_improvement", "failed", "broken"}:
        return {
            "is_broken": "true",
            "trigger_type": "registry_status",
            "trigger_stage": "offline_replay",
            "trigger_run_id": model.get("last_run_id", ""),
            "detected_at_utc": model.get("last_trained_at_utc", ""),
            "action_plan": "run_offline_replay_then_retrain",
            "next_action": "record_simulation_run:offline_replay:pending",
            "notes": "Registry status indicates recovery required.",
        }

    # Detect missing offline replay once model entered active lifecycle.
    active = model_status in {"simulated", "trained", "recovering"}
    offline = latest_stage_runs.get((model_id, "offline_replay"))
    if active and offline is None:
        return {
            "is_broken": "true",
            "trigger_type": "missing_stage",
            "trigger_stage": "offline_replay",
            "trigger_run_id": "",
            "detected_at_utc": model.get("last_trained_at_utc", "") or "1970-01-01T00:00:00Z",
            "action_plan": "bootstrap_offline_replay",
            "next_action": "record_simulation_run:offline_replay:pending",
            "notes": "Active model missing offline replay evidence.",
        }

    return {
        "is_broken": "false",
        "trigger_type": "",
        "trigger_stage": "",
        "trigger_run_id": "",
        "detected_at_utc": "",
        "action_plan": "",
        "next_action": "",
        "notes": "",
    }


def main() -> None:
    parser = argparse.ArgumentParser(description="Auto-recover broken learning cycles.")
    parser.add_argument("--check", action="store_true", help="Fail if any files would change.")
    parser.add_argument("--apply-fixes", action="store_true", help="Schedule recovery attempts.")
    parser.add_argument("--no-write", action="store_true", help="Analyze only.")
    args = parser.parse_args()

    registry = read_csv_rows(REGISTRY_CSV)
    sim_runs = read_csv_rows(SIM_RUNS_CSV)
    contracts = read_json(SIM_CONTRACTS_JSON)
    queue = read_csv_rows(RECOVERY_QUEUE_CSV)
    queue_by_id = {row.get("recovery_id", ""): row for row in queue if row.get("recovery_id")}

    spec = contracts.get("simulation_specs", {}).get("sim-standard-v1", {})
    stages = [s.get("name", "") for s in spec.get("stages", []) if s.get("name", "")]
    if not stages:
        fail("No simulation stages found in sim-standard-v1.")

    latest = latest_runs_by_model_stage(sim_runs)
    queue_changed = False
    registry_changed = False
    sim_runs_changed = False

    open_or_scheduled = {"open", "scheduled"}

    for model in registry:
        model_id = model.get("model_id", "")
        entity_type = model.get("entity_type", "")
        state = model_break_state(model, stages, latest)
        is_broken = state["is_broken"] == "true"

        if is_broken:
            rid = recovery_id(model_id, state["trigger_type"], state["trigger_stage"])
            existing = queue_by_id.get(rid)
            if existing is None:
                new_row = {
                    "recovery_id": rid,
                    "model_id": model_id,
                    "entity_type": entity_type,
                    "trigger_type": state["trigger_type"],
                    "trigger_stage": state["trigger_stage"],
                    "trigger_run_id": state["trigger_run_id"],
                    "detected_at_utc": state["detected_at_utc"] or "1970-01-01T00:00:00Z",
                    "status": "open",
                    "attempt_count": "0",
                    "last_attempt_at_utc": "",
                    "resolved_at_utc": "",
                    "action_plan": state["action_plan"],
                    "next_action": state["next_action"],
                    "notes": state["notes"],
                }
                queue.append(new_row)
                queue_by_id[rid] = new_row
                queue_changed = True
                existing = new_row

            if args.apply_fixes:
                stage = state["trigger_stage"] or "offline_replay"
                has_pending = any(
                    row.get("model_id") == model_id
                    and row.get("stage") == stage
                    and normalize_status(row.get("status", "")) == "pending"
                    for row in sim_runs
                )
                if not has_pending:
                    stamp = dt.datetime.now(dt.timezone.utc).strftime("%Y%m%d%H%M%S")
                    run_id = f"auto-recover-{model_id}-{stage}-{stamp}"
                    sim_runs.append(
                        {
                            "run_id": run_id,
                            "model_id": model_id,
                            "stage": stage,
                            "started_at_utc": now_utc(),
                            "completed_at_utc": "",
                            "status": "pending",
                            "metric_name": "",
                            "metric_value": "",
                            "threshold": "",
                            "direction": "",
                            "regression_delta": "",
                            "auto_created_followup_id": existing.get("recovery_id", ""),
                            "followup_status": "open",
                            "notes": "auto-recovery scheduled",
                        }
                    )
                    sim_runs_changed = True

                if normalize_status(model.get("status", "")) != "recovering":
                    model["status"] = "recovering"
                    registry_changed = True

                existing["status"] = "scheduled"
                existing["attempt_count"] = str(parse_int(existing.get("attempt_count", "0")) + 1)
                existing["last_attempt_at_utc"] = now_utc()
                queue_changed = True

        # Resolve matching open queue rows when cycle no longer broken.
        if not is_broken:
            for row in queue:
                if row.get("model_id") != model_id:
                    continue
                if normalize_status(row.get("status", "")) not in open_or_scheduled:
                    continue
                row["status"] = "resolved"
                row["resolved_at_utc"] = (
                    model.get("last_trained_at_utc", "")
                    or latest.get((model_id, "limited_rollout"), {}).get("completed_at_utc", "")
                    or "1970-01-01T00:00:00Z"
                )
                row["notes"] = "Auto-resolved: no active break conditions."
                queue_changed = True

    # Keep queue deterministic.
    queue = sorted(
        queue,
        key=lambda r: (
            r.get("model_id", ""),
            r.get("trigger_type", ""),
            r.get("trigger_stage", ""),
            r.get("recovery_id", ""),
        ),
    )

    if args.check:
        if queue_changed or registry_changed or sim_runs_changed:
            reasons = []
            if queue_changed:
                reasons.append("recovery queue out of sync")
            if registry_changed:
                reasons.append("model training registry needs recovery status updates")
            if sim_runs_changed:
                reasons.append("simulation runs need auto-recovery scheduling entries")
            fail("CHECK FAILED: " + "; ".join(reasons))
        print("Learning cycle recovery check passed.")
        return

    if not args.no_write:
        write_csv_rows(RECOVERY_QUEUE_CSV, queue, RECOVERY_FIELDS)
        if registry_changed:
            write_csv_rows(REGISTRY_CSV, registry, list(registry[0].keys()))
        if sim_runs_changed:
            write_csv_rows(SIM_RUNS_CSV, sim_runs, list(sim_runs[0].keys()))

    broken_count = sum(1 for row in queue if normalize_status(row.get("status", "")) in open_or_scheduled)
    print(f"Learning cycle recovery queue updated: {RECOVERY_QUEUE_CSV}")
    print(f"Open/scheduled recoveries: {broken_count}")
    if args.apply_fixes:
        print("Auto-fix scheduling applied.")
    else:
        print("Detection-only mode (no auto-fix scheduling).")


if __name__ == "__main__":
    main()
