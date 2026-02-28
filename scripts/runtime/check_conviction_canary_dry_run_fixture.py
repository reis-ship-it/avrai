#!/usr/bin/env python3
"""Validate canary dry-run fixture includes mixed shadow/enforce outcomes."""

from __future__ import annotations

import json
import sys
from pathlib import Path

FIXTURE_PATH = Path("configs/runtime/conviction_gate_canary_dry_run_fixture.json")


def _fail(msg: str) -> None:
    print(f"ERROR: {msg}", file=sys.stderr)
    raise SystemExit(1)


def main() -> int:
    if not FIXTURE_PATH.exists():
        _fail(f"missing fixture file: {FIXTURE_PATH}")

    try:
        payload = json.loads(FIXTURE_PATH.read_text(encoding="utf-8"))
    except Exception as exc:
        _fail(f"invalid fixture JSON: {exc}")

    if not isinstance(payload, list) or not payload:
        _fail("fixture must be a non-empty JSON list")

    modes = set()
    has_shadow_bypass = False
    has_enforce_block = False
    has_enforce_allow = False
    has_high_impact_enforce = False

    for idx, row in enumerate(payload, start=1):
        if not isinstance(row, dict):
            _fail(f"row {idx} must be an object")
        mode = str(row.get("mode", "")).strip()
        if mode not in {"shadow", "enforce"}:
            _fail(f"row {idx} has invalid mode: {mode}")
        modes.add(mode)

        serving_allowed = row.get("servingAllowed") is True
        shadow_bypass = row.get("shadowBypassApplied") is True
        is_high_impact = row.get("isHighImpact") is True

        if shadow_bypass:
            has_shadow_bypass = True
        if mode == "enforce" and not serving_allowed:
            has_enforce_block = True
        if mode == "enforce" and serving_allowed:
            has_enforce_allow = True
        if mode == "enforce" and is_high_impact:
            has_high_impact_enforce = True

    if modes != {"shadow", "enforce"}:
        _fail("fixture must include both shadow and enforce mode decisions")
    if not has_shadow_bypass:
        _fail("fixture must include at least one shadow bypass decision")
    if not has_enforce_block:
        _fail("fixture must include at least one enforce blocked decision")
    if not has_enforce_allow:
        _fail("fixture must include at least one enforce allowed decision")
    if not has_high_impact_enforce:
        _fail("fixture must include at least one high-impact enforce decision")

    print(f"OK: canary dry-run fixture valid ({FIXTURE_PATH})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
