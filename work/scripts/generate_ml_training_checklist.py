#!/usr/bin/env python3
"""Generate canonical ML training checklist and simulation log docs.

Sources:
- configs/ml/model_training_registry.csv
- configs/ml/feature_label_contracts.json
- configs/ml/simulation_experiment_contracts.json
- configs/ml/simulation_experiment_runs.csv

Outputs:
- docs/ML_MODEL_TRAINING_CHECKLIST.md
- docs/ML_SIMULATION_EXPERIMENT_LOG.md
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
from pathlib import Path
import sys
from typing import Dict, List, Tuple

ROOT = Path(__file__).resolve().parents[1]
REGISTRY_CSV = ROOT / "configs/ml/model_training_registry.csv"
CONTRACTS_JSON = ROOT / "configs/ml/feature_label_contracts.json"
SIM_CONTRACTS_JSON = ROOT / "configs/ml/simulation_experiment_contracts.json"
SIM_RUNS_CSV = ROOT / "configs/ml/simulation_experiment_runs.csv"
NATIVE_CONTRACTS_JSON = ROOT / "configs/ml/avrai_native_type_contracts.json"
RECOVERY_QUEUE_CSV = ROOT / "configs/ml/learning_cycle_recovery_queue.csv"
CHECKLIST_MD = ROOT / "docs/ML_MODEL_TRAINING_CHECKLIST.md"
SIM_LOG_MD = ROOT / "docs/ML_SIMULATION_EXPERIMENT_LOG.md"
SOURCE_FILES = [
    REGISTRY_CSV,
    CONTRACTS_JSON,
    SIM_CONTRACTS_JSON,
    SIM_RUNS_CSV,
    NATIVE_CONTRACTS_JSON,
    RECOVERY_QUEUE_CSV,
]


def fail(message: str) -> None:
    print(f"ML TRAINING CHECKLIST GENERATION FAILED: {message}")
    sys.exit(1)


def read_csv(path: Path) -> List[Dict[str, str]]:
    if not path.exists():
        fail(f"Missing CSV: {path}")
    with path.open("r", encoding="utf-8", newline="") as f:
        return list(csv.DictReader(f))


def read_json(path: Path) -> Dict:
    if not path.exists():
        fail(f"Missing JSON: {path}")
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def file_sha256(path: Path) -> str:
    digest = hashlib.sha256()
    digest.update(path.read_bytes())
    return digest.hexdigest()


def deterministic_source_digest() -> str:
    """Use source file content digest for reproducible output across environments."""
    digest = hashlib.sha256()
    for path in sorted(SOURCE_FILES, key=lambda p: str(p.relative_to(ROOT))):
        if not path.exists():
            fail(f"Missing source file: {path}")
        digest.update(str(path.relative_to(ROOT)).encode("utf-8"))
        digest.update(b"\0")
        digest.update(path.read_bytes())
        digest.update(b"\0")
    return digest.hexdigest()[:16]


def normalize_status(value: str) -> str:
    value = (value or "").strip().lower()
    return value or "unknown"


def parse_float(value: str) -> float | None:
    try:
        if value is None or value == "":
            return None
        return float(value)
    except ValueError:
        return None


def build_latest_stage_map(sim_runs: List[Dict[str, str]]) -> Dict[Tuple[str, str], Dict[str, str]]:
    latest: Dict[Tuple[str, str], Dict[str, str]] = {}
    for row in sim_runs:
        key = (row.get("model_id", ""), row.get("stage", ""))
        completed = row.get("completed_at_utc", "") or ""
        current = latest.get(key)
        if current is None:
            latest[key] = row
            continue
        current_completed = current.get("completed_at_utc", "") or ""
        if completed >= current_completed:
            latest[key] = row
    return latest


def render_checklist(
    registry: List[Dict[str, str]],
    contracts: Dict,
    sim_contracts: Dict,
    native_contracts: Dict,
) -> str:
    lines: List[str] = []
    generated = deterministic_source_digest()

    lines.append("# ML Model Training Checklist")
    lines.append("")
    lines.append(f"Generated Source Digest: `{generated}`")
    lines.append("")
    lines.append("## Purpose")
    lines.append("This file is generated. Do not edit manually.")
    lines.append("It is the canonical, uniform checklist for model training readiness and completion across all entity models.")
    lines.append("")

    lines.append("## Registry")
    lines.append("")
    lines.append("| Model ID | Entity | AVRAI Native Type | Status | Last Trained (UTC) | Dataset Snapshot | Run ID | Auto Train | Milestone | Master Plan Refs |")
    lines.append("|---|---|---|---|---|---|---|---|---|---|")
    native_entities = native_contracts.get("entities", {})
    default_native_type = native_contracts.get("default_native_type_id", "avrai.entity.frame.v1")
    for row in sorted(registry, key=lambda r: r["model_id"]):
        entity = row.get("entity_type", "")
        native_type = native_entities.get(entity, {}).get("native_type_id", default_native_type)
        lines.append(
            "| {model_id} | {entity_type} | {native_type} | {status} | {last_trained_at_utc} | {last_dataset_snapshot_id} | {last_run_id} | {auto_train_enabled} | {execution_milestone_id} | {master_plan_refs} |".format(
                model_id=row.get("model_id", ""),
                entity_type=entity,
                native_type=native_type,
                status=normalize_status(row.get("status", "")),
                last_trained_at_utc=row.get("last_trained_at_utc", "") or "-",
                last_dataset_snapshot_id=row.get("last_dataset_snapshot_id", "") or "-",
                last_run_id=row.get("last_run_id", "") or "-",
                auto_train_enabled=row.get("auto_train_enabled", ""),
                execution_milestone_id=row.get("execution_milestone_id", ""),
                master_plan_refs=row.get("master_plan_refs", ""),
            )
        )
    lines.append("")

    lines.append("## Uniform Training Contract")
    lines.append("")
    global_contract = contracts.get("global", {})
    lines.append("Required common fields:")
    for field in global_contract.get("required_common_fields", []):
        lines.append(f"- `{field}`")
    lines.append("")
    lines.append("Required location fields:")
    for field in global_contract.get("required_location_fields", []):
        lines.append(f"- `{field}`")
    lines.append("")
    lines.append("Uniform stages:")
    for stage in global_contract.get("uniform_training_stages", []):
        lines.append(f"- `{stage}`")
    lines.append("")

    lines.append("## Entity Data Requirements")
    lines.append("")
    entity_contracts = contracts.get("entities", {})
    for row in sorted(registry, key=lambda r: r["model_id"]):
        model_id = row["model_id"]
        entity = row["entity_type"]
        contract = entity_contracts.get(entity)
        if contract is None:
            fail(f"Missing entity contract for '{entity}' used by {model_id}")

        lines.append(f"### {model_id}")
        lines.append("")
        lines.append(f"- Entity: `{entity}`")
        lines.append(f"- Feature spec: `{contract.get('feature_spec_id', '-')}`")
        min_req = contract.get("minimum_data_requirements", {})
        lines.append(
            "- Minimum data gate: episodes >= {episodes}, positives >= {positives}, null rate <= {null_rate}, freshness <= {freshness}h".format(
                episodes=min_req.get("min_episodes", "-"),
                positives=min_req.get("min_positive_outcomes", "-"),
                null_rate=min_req.get("max_null_rate", "-"),
                freshness=min_req.get("freshness_hours", "-"),
            )
        )

        groups = contract.get("required_feature_groups", {})
        for group in ["location", "type", "event_scale", "outcomes"]:
            lines.append(f"- {group.replace('_', ' ').title()} fields:")
            group_fields = groups.get(group, [])
            if not group_fields:
                lines.append("  - (none)")
            else:
                lines.append("  - " + ", ".join(f"`{f}`" for f in group_fields))
        lines.append("")

    lines.append("## Simulation Contract")
    lines.append("")
    spec = sim_contracts["simulation_specs"]["sim-standard-v1"]
    lines.append(f"Spec: `sim-standard-v1` - {spec.get('description', '')}")
    lines.append("")
    lines.append("| Stage | Metric | Direction | Threshold |")
    lines.append("|---|---|---|---|")
    for stage in spec.get("stages", []):
        stage_name = stage.get("name", "")
        metrics = stage.get("required_metrics", [])
        for metric in metrics:
            lines.append(
                f"| {stage_name} | {metric.get('name', '')} | {metric.get('direction', '')} | {metric.get('threshold', '')} |"
            )
    lines.append("")

    lines.append("## Source Files")
    lines.append("")
    lines.append("- `configs/ml/model_training_registry.csv`")
    lines.append("- `configs/ml/feature_label_contracts.json`")
    lines.append("- `configs/ml/avrai_native_type_contracts.json`")
    lines.append("- `configs/ml/simulation_experiment_contracts.json`")
    lines.append("- `configs/ml/simulation_experiment_runs.csv`")
    lines.append("- `configs/ml/learning_cycle_recovery_queue.csv`")
    lines.append("- `scripts/ml/auto_recover_learning_cycles.py`")
    lines.append("- `scripts/ml/build_training_dataset.py`")
    lines.append("- `scripts/generate_ml_training_checklist.py`")
    lines.append("")
    return "\n".join(lines) + "\n"


def render_sim_log(
    registry: List[Dict[str, str]],
    sim_contracts: Dict,
    sim_runs: List[Dict[str, str]],
    recovery_queue: List[Dict[str, str]],
) -> str:
    lines: List[str] = []
    generated = deterministic_source_digest()

    latest_stage = build_latest_stage_map(sim_runs)

    lines.append("# ML Simulation Experiment Log")
    lines.append("")
    lines.append(f"Generated Source Digest: `{generated}`")
    lines.append("")
    lines.append("## Purpose")
    lines.append("This file is generated. It summarizes the latest simulation stage status and auto-improvement backlog.")
    lines.append("")

    lines.append("## Latest Stage Status")
    lines.append("")
    lines.append("| Model ID | Stage | Status | Metric | Value | Threshold | Direction | Follow-up | Follow-up Status |")
    lines.append("|---|---|---|---|---|---|---|---|---|")

    stages = [s.get("name", "") for s in sim_contracts["simulation_specs"]["sim-standard-v1"].get("stages", [])]
    for row in sorted(registry, key=lambda r: r["model_id"]):
        model_id = row["model_id"]
        for stage in stages:
            run = latest_stage.get((model_id, stage), {})
            lines.append(
                "| {model} | {stage} | {status} | {metric} | {value} | {threshold} | {direction} | {followup} | {followup_status} |".format(
                    model=model_id,
                    stage=stage,
                    status=normalize_status(run.get("status", "pending") or "pending"),
                    metric=run.get("metric_name", "") or "-",
                    value=run.get("metric_value", "") or "-",
                    threshold=run.get("threshold", "") or "-",
                    direction=run.get("direction", "") or "-",
                    followup=run.get("auto_created_followup_id", "") or "-",
                    followup_status=run.get("followup_status", "") or "-",
                )
            )
    lines.append("")

    lines.append("## Learning Cycle Recovery Queue")
    lines.append("")
    lines.append("| Recovery ID | Model ID | Trigger | Stage | Status | Attempts | Next Action | Last Attempt (UTC) | Resolved (UTC) |")
    lines.append("|---|---|---|---|---|---|---|---|---|")
    if not recovery_queue:
        lines.append("| - | - | - | - | - | - | - | - | - |")
    else:
        for row in sorted(recovery_queue, key=lambda r: (r.get("model_id", ""), r.get("recovery_id", ""))):
            lines.append(
                "| {recovery_id} | {model_id} | {trigger_type} | {trigger_stage} | {status} | {attempt_count} | {next_action} | {last_attempt_at_utc} | {resolved_at_utc} |".format(
                    recovery_id=row.get("recovery_id", "") or "-",
                    model_id=row.get("model_id", "") or "-",
                    trigger_type=row.get("trigger_type", "") or "-",
                    trigger_stage=row.get("trigger_stage", "") or "-",
                    status=normalize_status(row.get("status", "")) or "-",
                    attempt_count=row.get("attempt_count", "") or "0",
                    next_action=row.get("next_action", "") or "-",
                    last_attempt_at_utc=row.get("last_attempt_at_utc", "") or "-",
                    resolved_at_utc=row.get("resolved_at_utc", "") or "-",
                )
            )
    lines.append("")

    lines.append("## Auto-Improvement Backlog")
    lines.append("")
    lines.append("| Run ID | Model ID | Stage | Failure Metric | Value | Threshold | Suggested Action | Follow-up ID | Follow-up Status |")
    lines.append("|---|---|---|---|---|---|---|---|---|")

    improvement_actions = {
        "offline_replay": "create_data_gap_followup",
        "shadow": "create_guardrail_tuning_followup",
        "limited_rollout": "auto_rollback_and_retrain",
    }

    failures = [r for r in sim_runs if normalize_status(r.get("status", "")) == "fail"]
    if not failures:
        lines.append("| - | - | - | - | - | - | - | - | - |")
    else:
        for run in sorted(failures, key=lambda r: r.get("completed_at_utc", ""), reverse=True):
            stage = run.get("stage", "")
            lines.append(
                "| {run_id} | {model_id} | {stage} | {metric_name} | {metric_value} | {threshold} | {action} | {followup} | {followup_status} |".format(
                    run_id=run.get("run_id", ""),
                    model_id=run.get("model_id", ""),
                    stage=stage,
                    metric_name=run.get("metric_name", "") or "-",
                    metric_value=run.get("metric_value", "") or "-",
                    threshold=run.get("threshold", "") or "-",
                    action=improvement_actions.get(stage, "manual_followup"),
                    followup=run.get("auto_created_followup_id", "") or "-",
                    followup_status=run.get("followup_status", "") or "-",
                )
            )
    lines.append("")

    lines.append("## Writing Pattern")
    lines.append("")
    lines.append("Use this exact decision line for each stage:")
    lines.append("")
    lines.append("`<model_id> <stage> <pass_or_fail> <metric>=<value> threshold=<threshold> action=<next_action>`")
    lines.append("")
    return "\n".join(lines) + "\n"


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate ML training checklist and simulation log docs.")
    parser.add_argument("--check", action="store_true", help="Fail if generated docs are out of date.")
    args = parser.parse_args()

    registry = read_csv(REGISTRY_CSV)
    contracts = read_json(CONTRACTS_JSON)
    sim_contracts = read_json(SIM_CONTRACTS_JSON)
    sim_runs = read_csv(SIM_RUNS_CSV)
    native_contracts = read_json(NATIVE_CONTRACTS_JSON)
    recovery_queue = read_csv(RECOVERY_QUEUE_CSV)

    checklist_content = render_checklist(registry, contracts, sim_contracts, native_contracts)
    sim_log_content = render_sim_log(registry, sim_contracts, sim_runs, recovery_queue)

    if args.check:
        for path, generated in [(CHECKLIST_MD, checklist_content), (SIM_LOG_MD, sim_log_content)]:
            if not path.exists():
                fail(f"Missing generated doc: {path}")
            current = path.read_text(encoding="utf-8")
            if current != generated:
                fail(
                    f"Stale generated doc: {path}. Run: python3 scripts/generate_ml_training_checklist.py"
                )
        print("ML training checklist docs are up to date.")
        return

    CHECKLIST_MD.write_text(checklist_content, encoding="utf-8")
    SIM_LOG_MD.write_text(sim_log_content, encoding="utf-8")

    print("Generated:")
    print(f"- {CHECKLIST_MD}")
    print(f"- {SIM_LOG_MD}")
    print("Source hashes:")
    for path in SOURCE_FILES:
        print(f"- {path}: {file_sha256(path)}")


if __name__ == "__main__":
    main()
