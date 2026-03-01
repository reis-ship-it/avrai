#!/usr/bin/env python3
"""Generate/check URK learning update governance report."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

CONFIG_PATH = Path("configs/runtime/urk_learning_update_governance_controls.json")
OUT_JSON = Path("docs/plans/methodology/MASTER_PLAN_URK_LEARNING_UPDATE_GOVERNANCE_REPORT.json")
OUT_MD = Path("docs/plans/methodology/MASTER_PLAN_URK_LEARNING_UPDATE_GOVERNANCE_REPORT.md")


def _fail(msg: str) -> None:
    print(f"ERROR: {msg}", file=sys.stderr)
    raise SystemExit(1)


def _req_num(v: object, f: str) -> float:
    if not isinstance(v, (int, float)) or float(v) < 0:
        _fail(f"{f} must be non-negative number")
    return float(v)


def _req_int(v: object, f: str) -> int:
    if not isinstance(v, int) or v < 0:
        _fail(f"{f} must be non-negative integer")
    return int(v)


def _req_pos_int(v: object, f: str) -> int:
    if not isinstance(v, int) or v <= 0:
        _fail(f"{f} must be positive integer")
    return int(v)


def _load() -> dict:
    if not CONFIG_PATH.exists():
        _fail(f"missing config: {CONFIG_PATH}")
    data = json.loads(CONFIG_PATH.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        _fail("config root must be object")
    return data


def _build(cfg: dict) -> dict:
    if cfg.get("version") != "v1":
        _fail("config version must be v1")
    coverage = cfg.get("learning_gate_coverage")
    safety = cfg.get("promotion_safety")
    if not isinstance(coverage, dict) or not isinstance(safety, dict):
        _fail("learning_gate_coverage and promotion_safety must be objects")

    req_valid = _req_num(
        coverage.get("required_update_validation_coverage_pct"),
        "learning_gate_coverage.required_update_validation_coverage_pct",
    )
    obs_valid = _req_num(
        coverage.get("observed_update_validation_coverage_pct"),
        "learning_gate_coverage.observed_update_validation_coverage_pct",
    )
    req_lineage = _req_num(
        coverage.get("required_data_lineage_coverage_pct"),
        "learning_gate_coverage.required_data_lineage_coverage_pct",
    )
    obs_lineage = _req_num(
        coverage.get("observed_data_lineage_coverage_pct"),
        "learning_gate_coverage.observed_data_lineage_coverage_pct",
    )
    coverage_checks = _req_pos_int(
        coverage.get("checks_executed"), "learning_gate_coverage.checks_executed"
    )

    max_unreviewed = _req_int(
        safety.get("max_unreviewed_high_impact_learning_updates"),
        "promotion_safety.max_unreviewed_high_impact_learning_updates",
    )
    obs_unreviewed = _req_int(
        safety.get("observed_unreviewed_high_impact_learning_updates"),
        "promotion_safety.observed_unreviewed_high_impact_learning_updates",
    )
    max_recovery = _req_int(
        safety.get("max_failed_rollback_recovery_events"),
        "promotion_safety.max_failed_rollback_recovery_events",
    )
    obs_recovery = _req_int(
        safety.get("observed_failed_rollback_recovery_events"),
        "promotion_safety.observed_failed_rollback_recovery_events",
    )
    safety_checks = _req_pos_int(
        safety.get("checks_executed"), "promotion_safety.checks_executed"
    )

    coverage_ok = obs_valid >= req_valid and obs_lineage >= req_lineage
    safety_ok = obs_unreviewed <= max_unreviewed and obs_recovery <= max_recovery
    errors: list[str] = []
    if not coverage_ok:
        errors.append("learning validation/lineage threshold failed")
    if not safety_ok:
        errors.append("learning promotion safety threshold failed")

    return {
        "version": "v1",
        "source": str(CONFIG_PATH),
        "learning_gate_coverage": {
            "required_update_validation_coverage_pct": req_valid,
            "observed_update_validation_coverage_pct": obs_valid,
            "required_data_lineage_coverage_pct": req_lineage,
            "observed_data_lineage_coverage_pct": obs_lineage,
            "checks_executed": coverage_checks,
            "within_threshold": coverage_ok,
        },
        "promotion_safety": {
            "max_unreviewed_high_impact_learning_updates": max_unreviewed,
            "observed_unreviewed_high_impact_learning_updates": obs_unreviewed,
            "max_failed_rollback_recovery_events": max_recovery,
            "observed_failed_rollback_recovery_events": obs_recovery,
            "checks_executed": safety_checks,
            "within_threshold": safety_ok,
        },
        "errors": errors,
        "verdict": "PASS" if not errors else "FAIL",
    }


def _render(summary: dict) -> str:
    return (
        "# URK Learning Update Governance Report\n\n"
        f"**Source config:** `{summary['source']}`  \n"
        f"**Learning gate coverage check:** {summary['learning_gate_coverage']['within_threshold']}  \n"
        f"**Promotion safety check:** {summary['promotion_safety']['within_threshold']}  \n"
        f"**Verdict:** {summary['verdict']}\n\n"
        "## Validation Errors\n\n"
        + ("- None\n" if not summary["errors"] else "\n".join(f"- {e}" for e in summary["errors"]) + "\n")
    )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    summary = _build(_load())
    out_json = json.dumps(summary, indent=2, sort_keys=True) + "\n"
    out_md = _render(summary)

    if args.check:
        if not OUT_JSON.exists() or not OUT_MD.exists():
            _fail("learning update governance artifacts missing; run generator")
        if OUT_JSON.read_text(encoding="utf-8") != out_json:
            _fail("learning update governance JSON report out of date")
        if OUT_MD.read_text(encoding="utf-8") != out_md:
            _fail("learning update governance markdown report out of date")
        print("OK: URK learning update governance report is in sync.")
        return 0

    OUT_JSON.write_text(out_json, encoding="utf-8")
    OUT_MD.write_text(out_md, encoding="utf-8")
    print(f"Updated {OUT_JSON} and {OUT_MD}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
