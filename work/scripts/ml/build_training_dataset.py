#!/usr/bin/env python3
"""Build AVRAI-native training datasets from external/raw snapshots.

Input: CSV or JSONL rows containing feature fields.
Output:
- AVRAI-native JSONL dataset under data/training/<model_id>/<snapshot_id>/
- Manifest with gate metrics for simulation/training handoff.
"""

from __future__ import annotations

import argparse
import csv
import datetime as dt
import json
from pathlib import Path
import sys
from typing import Dict, Iterable, List, Tuple

ROOT = Path(__file__).resolve().parents[2]
MODEL_REGISTRY_CSV = ROOT / "configs/ml/model_training_registry.csv"
FEATURE_CONTRACTS_JSON = ROOT / "configs/ml/feature_label_contracts.json"
NATIVE_CONTRACTS_JSON = ROOT / "configs/ml/avrai_native_type_contracts.json"
DEFAULT_TRAINING_ROOT = ROOT / "data/training"


def fail(message: str) -> None:
    print(f"BUILD TRAINING DATASET FAILED: {message}")
    sys.exit(1)


def read_json(path: Path) -> Dict:
    if not path.exists():
        fail(f"Missing JSON file: {path}")
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def read_csv_rows(path: Path) -> List[Dict[str, str]]:
    if not path.exists():
        fail(f"Missing CSV file: {path}")
    with path.open("r", encoding="utf-8", newline="") as f:
        return list(csv.DictReader(f))


def read_input_rows(path: Path, input_format: str) -> List[Dict[str, str]]:
    if not path.exists():
        fail(f"Missing input dataset file: {path}")
    if input_format == "csv":
        return read_csv_rows(path)
    rows: List[Dict[str, str]] = []
    with path.open("r", encoding="utf-8") as f:
        for idx, line in enumerate(f, start=1):
            line = line.strip()
            if not line:
                continue
            try:
                obj = json.loads(line)
            except json.JSONDecodeError as exc:
                fail(f"Invalid JSONL at line {idx}: {exc}")
            if not isinstance(obj, dict):
                fail(f"JSONL row {idx} is not an object.")
            rows.append({str(k): v for k, v in obj.items()})
    return rows


def now_utc() -> str:
    return dt.datetime.now(dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def normalize_value(value: object) -> str:
    if value is None:
        return ""
    if isinstance(value, bool):
        return "true" if value else "false"
    return str(value)


def is_missing(value: object) -> bool:
    s = normalize_value(value).strip().lower()
    return s in {"", "null", "none", "na", "n/a", "nan"}


def infer_entity_type(model_id: str) -> str:
    rows = read_csv_rows(MODEL_REGISTRY_CSV)
    for row in rows:
        if row.get("model_id") == model_id:
            entity_type = row.get("entity_type", "").strip()
            if entity_type:
                return entity_type
            break
    fail(f"Could not infer entity_type for model_id: {model_id}")
    return ""


def required_fields(feature_contracts: Dict, entity_type: str) -> Tuple[List[str], Dict]:
    global_cfg = feature_contracts.get("global", {})
    entities = feature_contracts.get("entities", {})
    entity_cfg = entities.get(entity_type)
    if not entity_cfg:
        fail(f"Missing entity contract: {entity_type}")

    fields: List[str] = []
    fields.extend(global_cfg.get("required_common_fields", []))
    fields.extend(global_cfg.get("required_location_fields", []))
    groups = entity_cfg.get("required_feature_groups", {})
    for group_name in ["location", "type", "event_scale", "outcomes"]:
        fields.extend(groups.get(group_name, []))

    deduped = sorted(set(fields))
    return deduped, entity_cfg


def positive_outcome(value: object) -> bool:
    s = normalize_value(value).strip().lower()
    if s in {"1", "true", "pass", "success", "converted", "retained", "positive"}:
        return True
    if s in {"0", "false", "fail", "failed", "negative"}:
        return False
    return False


def build_native_payload(
    row: Dict[str, object],
    model_id: str,
    entity_type: str,
    snapshot_id: str,
    native_contracts: Dict,
    entity_cfg: Dict,
    source_id: str,
) -> Dict:
    native_entities = native_contracts.get("entities", {})
    native_cfg = native_entities.get(entity_type, {})
    native_type_id = native_cfg.get(
        "native_type_id",
        native_contracts.get("default_native_type_id", "avrai.entity.frame.v1"),
    )

    groups = entity_cfg.get("required_feature_groups", {})
    native = {
        "avrai_type": native_type_id,
        "model_id": model_id,
        "entity_type": entity_type,
        "snapshot_id": snapshot_id,
        "source_id": source_id,
        "event_id": normalize_value(row.get("event_id")),
        "agent_id": normalize_value(row.get("agent_id")),
        "entity_id": normalize_value(row.get("entity_id")),
        "timestamp_utc": normalize_value(row.get("timestamp_utc")),
        "consent_scope": normalize_value(row.get("consent_scope")),
        "location": {k: normalize_value(row.get(k)) for k in groups.get("location", [])},
        "type": {k: normalize_value(row.get(k)) for k in groups.get("type", [])},
        "event_scale": {k: normalize_value(row.get(k)) for k in groups.get("event_scale", [])},
        "outcomes": {k: normalize_value(row.get(k)) for k in groups.get("outcomes", [])},
        "outcome": normalize_value(row.get("outcome")),
        "state_before": normalize_value(row.get("state_before")),
        "next_state": normalize_value(row.get("next_state")),
        "feature_spec_version": normalize_value(row.get("feature_spec_version")),
        "label_spec_version": normalize_value(row.get("label_spec_version")),
        "native_blocks": {},
    }

    for block_name, fields in native_cfg.get("native_blocks", {}).items():
        native["native_blocks"][block_name] = {
            field: normalize_value(row.get(field)) for field in fields
        }

    return native


def evaluate_gates(
    rows: List[Dict[str, object]],
    all_required_fields: List[str],
    min_req: Dict,
) -> Dict:
    episodes = len(rows)
    positives = 0
    missing_cells = 0

    for row in rows:
        if positive_outcome(row.get("outcome")):
            positives += 1
        for field in all_required_fields:
            if is_missing(row.get(field)):
                missing_cells += 1

    field_cells = max(1, episodes * max(1, len(all_required_fields)))
    null_rate = round(missing_cells / field_cells, 6)

    min_episodes = int(min_req.get("min_episodes", 0))
    min_positive = int(min_req.get("min_positive_outcomes", 0))
    max_null_rate = float(min_req.get("max_null_rate", 1.0))

    checks = {
        "episodes": episodes >= min_episodes,
        "positive_outcomes": positives >= min_positive,
        "null_rate": null_rate <= max_null_rate,
    }

    return {
        "records_total": episodes,
        "records_positive": positives,
        "required_fields_count": len(all_required_fields),
        "null_rate": null_rate,
        "gate_checks": checks,
        "gate_passed": all(checks.values()),
    }


def write_jsonl(path: Path, rows: Iterable[Dict]) -> int:
    path.parent.mkdir(parents=True, exist_ok=True)
    count = 0
    with path.open("w", encoding="utf-8") as f:
        for row in rows:
            f.write(json.dumps(row, sort_keys=True))
            f.write("\n")
            count += 1
    return count


def main() -> None:
    parser = argparse.ArgumentParser(description="Build AVRAI-native training dataset.")
    parser.add_argument("--model-id", required=True)
    parser.add_argument("--snapshot-id", required=True)
    parser.add_argument("--input-path", required=True)
    parser.add_argument("--input-format", choices=["jsonl", "csv"], default="jsonl")
    parser.add_argument("--entity-type", default="")
    parser.add_argument("--source-id", default="external")
    parser.add_argument("--output-root", default=str(DEFAULT_TRAINING_ROOT))
    args = parser.parse_args()

    model_id = args.model_id.strip()
    entity_type = args.entity_type.strip() or infer_entity_type(model_id)

    feature_contracts = read_json(FEATURE_CONTRACTS_JSON)
    native_contracts = read_json(NATIVE_CONTRACTS_JSON)
    required, entity_cfg = required_fields(feature_contracts, entity_type)

    input_path = Path(args.input_path).resolve()
    raw_rows = read_input_rows(input_path, args.input_format)
    if not raw_rows:
        fail("Input dataset is empty.")

    native_rows = [
        build_native_payload(
            row=row,
            model_id=model_id,
            entity_type=entity_type,
            snapshot_id=args.snapshot_id,
            native_contracts=native_contracts,
            entity_cfg=entity_cfg,
            source_id=args.source_id,
        )
        for row in raw_rows
    ]

    gates = evaluate_gates(raw_rows, required, entity_cfg.get("minimum_data_requirements", {}))

    out_dir = Path(args.output_root).resolve() / model_id / args.snapshot_id
    dataset_path = out_dir / "avrai_native_dataset.jsonl"
    manifest_path = out_dir / "manifest.json"
    wrote = write_jsonl(dataset_path, native_rows)

    manifest = {
        "model_id": model_id,
        "entity_type": entity_type,
        "snapshot_id": args.snapshot_id,
        "source_id": args.source_id,
        "input_path": str(input_path),
        "input_format": args.input_format,
        "output_dataset_path": str(dataset_path),
        "generated_at_utc": now_utc(),
        "minimum_data_requirements": entity_cfg.get("minimum_data_requirements", {}),
        "gate_summary": gates,
        "native_type_id": native_contracts.get("entities", {})
        .get(entity_type, {})
        .get("native_type_id", native_contracts.get("default_native_type_id", "avrai.entity.frame.v1")),
    }
    manifest_path.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8")

    print(f"Built AVRAI-native dataset: {dataset_path}")
    print(f"Wrote records: {wrote}")
    print(f"Gate passed: {manifest['gate_summary']['gate_passed']}")
    print(f"Manifest: {manifest_path}")


if __name__ == "__main__":
    main()
