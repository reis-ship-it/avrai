#!/usr/bin/env python3
"""Validate experiment registry coverage and naming contracts."""

from __future__ import annotations

import csv
from pathlib import Path
import re
import subprocess
import sys
from typing import Dict, List

ROOT = Path(__file__).resolve().parents[1]
REGISTRY = ROOT / "configs/experiments/EXPERIMENT_REGISTRY.csv"
GENERATOR = ROOT / "scripts/generate_experiment_registry.py"

CANONICAL_NAME_RE = re.compile(r"^exp_[a-z0-9_]+_v\d+\.(py|sh)$")
EXPERIMENT_ID_RE = re.compile(r"^[a-z0-9_]+$")


def fail(msg: str) -> None:
    print(f"EXPERIMENT REGISTRY CHECK FAILED: {msg}")
    sys.exit(1)


def run_generator_check() -> None:
    result = subprocess.run(
        ["python3", str(GENERATOR), "--check"],
        cwd=ROOT,
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        fail(result.stdout.strip() or result.stderr.strip())


def load_rows() -> List[Dict[str, str]]:
    if not REGISTRY.exists():
        fail("Missing registry CSV.")
    with REGISTRY.open("r", encoding="utf-8", newline="") as f:
        return list(csv.DictReader(f))


def main() -> None:
    run_generator_check()
    rows = load_rows()
    if not rows:
        fail("Registry is empty.")

    ids = set()
    legacy_paths = set()

    for row in rows:
        experiment_id = row.get("experiment_id", "")
        canonical_name = row.get("canonical_script_name", "")
        legacy_path = row.get("legacy_script_path", "")
        target_space = row.get("target_architecture_space", "")
        stage_contract = row.get("stage_contract", "")
        tracking_status = row.get("tracking_status", "")

        if not EXPERIMENT_ID_RE.fullmatch(experiment_id):
            fail(f"Invalid experiment_id format: {experiment_id}")

        if experiment_id in ids:
            fail(f"Duplicate experiment_id: {experiment_id}")
        ids.add(experiment_id)

        if legacy_path in legacy_paths:
            fail(f"Duplicate legacy path entry: {legacy_path}")
        legacy_paths.add(legacy_path)

        if not CANONICAL_NAME_RE.fullmatch(canonical_name):
            fail(f"Non-canonical script name: {canonical_name}")

        if not target_space.startswith("experiments/"):
            fail(f"Invalid target architecture space: {target_space}")

        if stage_contract not in {"sim-standard-v1", "exp-staged-v1"}:
            fail(f"Unsupported stage contract: {stage_contract}")

        if tracking_status != "tracked":
            fail(f"tracking_status must be 'tracked' for {experiment_id}")

        full_legacy = ROOT / legacy_path
        if not full_legacy.exists():
            fail(f"Registry references missing legacy script: {legacy_path}")

    print(f"Experiment registry check passed ({len(rows)} tracked scripts).")


if __name__ == "__main__":
    main()
