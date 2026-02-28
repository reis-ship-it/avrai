#!/usr/bin/env python3
"""Validate URK metadata quality for docs/EXECUTION_BOARD.csv."""

from __future__ import annotations

import csv
import sys
from pathlib import Path

CSV_PATH = Path("docs/EXECUTION_BOARD.csv")

DEFAULT_RUNTIME = "shared"
DEFAULT_PRONG = "cross_prong"
DEFAULT_MODE = "multi_mode"
DEFAULT_IMPACT = "L4"

ALLOWED_RUNTIME = {
    "user_runtime",
    "event_ops_runtime",
    "business_ops_runtime",
    "expert_services_runtime",
    "shared",
}
ALLOWED_PRONG = {"model_core", "runtime_core", "governance_core", "cross_prong"}
ALLOWED_MODE = {"local_sovereign", "private_mesh", "federated_cloud", "multi_mode"}
ALLOWED_IMPACT = {"L1", "L2", "L3", "L4"}


def fail(msg: str) -> None:
    print(f"URK BOARD QUALITY CHECK FAILED: {msg}")
    raise SystemExit(1)


def main() -> int:
    if not CSV_PATH.exists():
        fail(f"missing execution board csv: {CSV_PATH}")

    with CSV_PATH.open("r", encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)
        required = {
            "type",
            "id",
            "urk_runtime_type",
            "urk_prong",
            "privacy_mode_impact",
            "impact_tier_max",
        }
        missing = required - set(reader.fieldnames or [])
        if missing:
            fail(f"missing URK columns: {sorted(missing)}")

        milestones = [row for row in reader if (row.get("type") or "").strip() == "milestone"]

    if not milestones:
        fail("no milestone rows found")

    defaults = 0
    runtime_seen: set[str] = set()
    prong_seen: set[str] = set()
    mode_seen: set[str] = set()
    impact_seen: set[str] = set()

    for row in milestones:
        mid = (row.get("id") or "").strip()
        runtime = (row.get("urk_runtime_type") or "").strip()
        prong = (row.get("urk_prong") or "").strip()
        mode = (row.get("privacy_mode_impact") or "").strip()
        impact = (row.get("impact_tier_max") or "").strip()

        if runtime not in ALLOWED_RUNTIME:
            fail(f"{mid} invalid urk_runtime_type: {runtime}")
        if prong not in ALLOWED_PRONG:
            fail(f"{mid} invalid urk_prong: {prong}")
        if mode not in ALLOWED_MODE:
            fail(f"{mid} invalid privacy_mode_impact: {mode}")
        if impact not in ALLOWED_IMPACT:
            fail(f"{mid} invalid impact_tier_max: {impact}")

        runtime_seen.add(runtime)
        prong_seen.add(prong)
        mode_seen.add(mode)
        impact_seen.add(impact)

        if (
            runtime == DEFAULT_RUNTIME
            and prong == DEFAULT_PRONG
            and mode == DEFAULT_MODE
            and impact == DEFAULT_IMPACT
        ):
            defaults += 1

    total = len(milestones)
    default_ratio = defaults / total

    # Quality gates: board should not be mostly default placeholders.
    if default_ratio > 0.60:
        fail(
            f"default URK metadata ratio too high: {default_ratio:.2%} "
            f"({defaults}/{total}). Reclassify milestones with specific URK values."
        )

    if "event_ops_runtime" not in runtime_seen:
        fail("missing event_ops_runtime milestone coverage")
    if "user_runtime" not in runtime_seen:
        fail("missing user_runtime milestone coverage")
    if "model_core" not in prong_seen or "runtime_core" not in prong_seen or "governance_core" not in prong_seen:
        fail("missing one or more required prong lanes (model/runtime/governance)")
    if "L2" not in impact_seen or "L3" not in impact_seen or "L4" not in impact_seen:
        fail("missing impact tier spread across L2/L3/L4")

    print("URK board quality check passed.")
    print(f"Milestones: {total}")
    print(f"Default ratio: {default_ratio:.2%}")
    print(f"Runtime lanes: {', '.join(sorted(runtime_seen))}")
    print(f"Prong lanes: {', '.join(sorted(prong_seen))}")
    print(f"Mode lanes: {', '.join(sorted(mode_seen))}")
    print(f"Impact tiers: {', '.join(sorted(impact_seen))}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
