#!/usr/bin/env python3
"""Run experiments using canonical registry keys or legacy paths.

Usage:
  python3 scripts/experiments/run_experiment.py --experiment-id <id> [-- ...args]
  python3 scripts/experiments/run_experiment.py --canonical-name <name> [-- ...args]
  python3 scripts/experiments/run_experiment.py --legacy-path <path> [-- ...args]
"""

from __future__ import annotations

import argparse
import csv
from pathlib import Path
import subprocess
import sys
from typing import Dict, List

ROOT = Path(__file__).resolve().parents[2]
REGISTRY = ROOT / "configs/experiments/EXPERIMENT_REGISTRY.csv"


def fail(msg: str) -> None:
    print(f"RUN EXPERIMENT FAILED: {msg}")
    sys.exit(1)


def load_rows() -> List[Dict[str, str]]:
    if not REGISTRY.exists():
        fail(f"Missing registry: {REGISTRY}")
    with REGISTRY.open("r", encoding="utf-8", newline="") as f:
        return list(csv.DictReader(f))


def resolve_script(rows: List[Dict[str, str]], args: argparse.Namespace) -> str:
    matches: List[Dict[str, str]] = []

    if args.experiment_id:
        matches = [r for r in rows if r.get("experiment_id") == args.experiment_id]
    elif args.canonical_name:
        matches = [r for r in rows if r.get("canonical_script_name") == args.canonical_name]
    elif args.legacy_path:
        matches = [r for r in rows if r.get("legacy_script_path") == args.legacy_path]
    else:
        fail("One of --experiment-id, --canonical-name, --legacy-path is required.")

    if len(matches) != 1:
        fail("Could not resolve unique experiment script in registry.")

    legacy = matches[0]["legacy_script_path"]
    full = ROOT / legacy
    if not full.exists():
        fail(f"Legacy script does not exist: {legacy}")
    return str(full)


def main() -> None:
    parser = argparse.ArgumentParser(description="Run experiment using canonical registry mapping.")
    parser.add_argument("--experiment-id", default="")
    parser.add_argument("--canonical-name", default="")
    parser.add_argument("--legacy-path", default="")
    parser.add_argument("args", nargs=argparse.REMAINDER, help="Arguments passed to the script (prefix with --)")
    parsed = parser.parse_args()

    rows = load_rows()
    script_path = resolve_script(rows, parsed)

    extra_args = parsed.args
    if extra_args and extra_args[0] == "--":
        extra_args = extra_args[1:]

    cmd = ["bash", script_path, *extra_args] if script_path.endswith(".sh") else ["python3", script_path, *extra_args]
    print("Executing:", " ".join(cmd))
    result = subprocess.run(cmd, cwd=ROOT, check=False)
    sys.exit(result.returncode)


if __name__ == "__main__":
    main()
