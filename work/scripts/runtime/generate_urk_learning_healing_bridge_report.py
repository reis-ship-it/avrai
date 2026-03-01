#!/usr/bin/env python3
"""Generate/check URK learning-healing bridge report."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

CONFIG_PATH = Path("configs/runtime/urk_learning_healing_bridge_controls.json")
OUT_JSON = Path("docs/plans/methodology/MASTER_PLAN_URK_LEARNING_HEALING_BRIDGE_REPORT.json")
OUT_MD = Path("docs/plans/methodology/MASTER_PLAN_URK_LEARNING_HEALING_BRIDGE_REPORT.md")


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

    coverage = cfg.get("bridge_coverage")
    safety = cfg.get("bridge_safety")
    if not isinstance(coverage, dict) or not isinstance(safety, dict):
        _fail("bridge_coverage and bridge_safety must be objects")

    req_link = _req_num(
        coverage.get("required_incident_to_learning_linkage_coverage_pct"),
        "bridge_coverage.required_incident_to_learning_linkage_coverage_pct",
    )
    obs_link = _req_num(
        coverage.get("observed_incident_to_learning_linkage_coverage_pct"),
        "bridge_coverage.observed_incident_to_learning_linkage_coverage_pct",
    )
    req_lineage = _req_num(
        coverage.get("required_lineage_reference_coverage_pct"),
        "bridge_coverage.required_lineage_reference_coverage_pct",
    )
    obs_lineage = _req_num(
        coverage.get("observed_lineage_reference_coverage_pct"),
        "bridge_coverage.observed_lineage_reference_coverage_pct",
    )
    cov_checks = _req_pos_int(
        coverage.get("checks_executed"), "bridge_coverage.checks_executed"
    )

    max_orphan = _req_int(
        safety.get("max_orphan_incident_learning_records"),
        "bridge_safety.max_orphan_incident_learning_records",
    )
    obs_orphan = _req_int(
        safety.get("observed_orphan_incident_learning_records"),
        "bridge_safety.observed_orphan_incident_learning_records",
    )
    max_missing = _req_int(
        safety.get("max_missing_recovery_linkbacks"),
        "bridge_safety.max_missing_recovery_linkbacks",
    )
    obs_missing = _req_int(
        safety.get("observed_missing_recovery_linkbacks"),
        "bridge_safety.observed_missing_recovery_linkbacks",
    )
    safety_checks = _req_pos_int(safety.get("checks_executed"), "bridge_safety.checks_executed")

    coverage_ok = obs_link >= req_link and obs_lineage >= req_lineage
    safety_ok = obs_orphan <= max_orphan and obs_missing <= max_missing
    errors: list[str] = []
    if not coverage_ok:
        errors.append("learning-healing bridge coverage threshold failed")
    if not safety_ok:
        errors.append("learning-healing bridge safety threshold failed")

    return {
        "version": "v1",
        "source": str(CONFIG_PATH),
        "bridge_coverage": {
            "required_incident_to_learning_linkage_coverage_pct": req_link,
            "observed_incident_to_learning_linkage_coverage_pct": obs_link,
            "required_lineage_reference_coverage_pct": req_lineage,
            "observed_lineage_reference_coverage_pct": obs_lineage,
            "checks_executed": cov_checks,
            "within_threshold": coverage_ok,
        },
        "bridge_safety": {
            "max_orphan_incident_learning_records": max_orphan,
            "observed_orphan_incident_learning_records": obs_orphan,
            "max_missing_recovery_linkbacks": max_missing,
            "observed_missing_recovery_linkbacks": obs_missing,
            "checks_executed": safety_checks,
            "within_threshold": safety_ok,
        },
        "errors": errors,
        "verdict": "PASS" if not errors else "FAIL",
    }


def _render(summary: dict) -> str:
    return (
        "# URK Learning-Healing Bridge Report\n\n"
        f"**Source config:** `{summary['source']}`  \n"
        f"**Bridge coverage check:** {summary['bridge_coverage']['within_threshold']}  \n"
        f"**Bridge safety check:** {summary['bridge_safety']['within_threshold']}  \n"
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
            _fail("learning-healing bridge artifacts missing; run generator")
        if OUT_JSON.read_text(encoding="utf-8") != out_json:
            _fail("learning-healing bridge JSON report out of date")
        if OUT_MD.read_text(encoding="utf-8") != out_md:
            _fail("learning-healing bridge markdown report out of date")
        print("OK: URK learning-healing bridge report is in sync.")
        return 0

    OUT_JSON.write_text(out_json, encoding="utf-8")
    OUT_MD.write_text(out_md, encoding="utf-8")
    print(f"Updated {OUT_JSON} and {OUT_MD}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
