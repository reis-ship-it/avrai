#!/usr/bin/env python3
"""Generate/check URK self-healing recovery report."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

CONFIG_PATH = Path("configs/runtime/urk_self_healing_recovery_controls.json")
OUT_JSON = Path("docs/plans/methodology/MASTER_PLAN_URK_SELF_HEALING_RECOVERY_REPORT.json")
OUT_MD = Path("docs/plans/methodology/MASTER_PLAN_URK_SELF_HEALING_RECOVERY_REPORT.md")


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

    coverage = cfg.get("recovery_pipeline_coverage")
    safety = cfg.get("recovery_safety")
    if not isinstance(coverage, dict) or not isinstance(safety, dict):
        _fail("recovery_pipeline_coverage and recovery_safety must be objects")

    req_dcr = _req_num(
        coverage.get("required_detect_contain_recover_coverage_pct"),
        "recovery_pipeline_coverage.required_detect_contain_recover_coverage_pct",
    )
    obs_dcr = _req_num(
        coverage.get("observed_detect_contain_recover_coverage_pct"),
        "recovery_pipeline_coverage.observed_detect_contain_recover_coverage_pct",
    )
    req_rollback = _req_num(
        coverage.get("required_rollback_path_coverage_pct"),
        "recovery_pipeline_coverage.required_rollback_path_coverage_pct",
    )
    obs_rollback = _req_num(
        coverage.get("observed_rollback_path_coverage_pct"),
        "recovery_pipeline_coverage.observed_rollback_path_coverage_pct",
    )
    cov_checks = _req_pos_int(
        coverage.get("checks_executed"), "recovery_pipeline_coverage.checks_executed"
    )

    max_uncontained = _req_int(
        safety.get("max_uncontained_incident_events"),
        "recovery_safety.max_uncontained_incident_events",
    )
    obs_uncontained = _req_int(
        safety.get("observed_uncontained_incident_events"),
        "recovery_safety.observed_uncontained_incident_events",
    )
    max_failed = _req_int(
        safety.get("max_failed_recovery_events"),
        "recovery_safety.max_failed_recovery_events",
    )
    obs_failed = _req_int(
        safety.get("observed_failed_recovery_events"),
        "recovery_safety.observed_failed_recovery_events",
    )
    safety_checks = _req_pos_int(
        safety.get("checks_executed"), "recovery_safety.checks_executed"
    )

    coverage_ok = obs_dcr >= req_dcr and obs_rollback >= req_rollback
    safety_ok = obs_uncontained <= max_uncontained and obs_failed <= max_failed
    errors: list[str] = []
    if not coverage_ok:
        errors.append("self-healing pipeline coverage threshold failed")
    if not safety_ok:
        errors.append("self-healing safety threshold failed")

    return {
        "version": "v1",
        "source": str(CONFIG_PATH),
        "recovery_pipeline_coverage": {
            "required_detect_contain_recover_coverage_pct": req_dcr,
            "observed_detect_contain_recover_coverage_pct": obs_dcr,
            "required_rollback_path_coverage_pct": req_rollback,
            "observed_rollback_path_coverage_pct": obs_rollback,
            "checks_executed": cov_checks,
            "within_threshold": coverage_ok,
        },
        "recovery_safety": {
            "max_uncontained_incident_events": max_uncontained,
            "observed_uncontained_incident_events": obs_uncontained,
            "max_failed_recovery_events": max_failed,
            "observed_failed_recovery_events": obs_failed,
            "checks_executed": safety_checks,
            "within_threshold": safety_ok,
        },
        "errors": errors,
        "verdict": "PASS" if not errors else "FAIL",
    }


def _render(summary: dict) -> str:
    return (
        "# URK Self-Healing Recovery Report\n\n"
        f"**Source config:** `{summary['source']}`  \n"
        f"**Recovery pipeline coverage check:** {summary['recovery_pipeline_coverage']['within_threshold']}  \n"
        f"**Recovery safety check:** {summary['recovery_safety']['within_threshold']}  \n"
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
            _fail("self-healing recovery artifacts missing; run generator")
        if OUT_JSON.read_text(encoding="utf-8") != out_json:
            _fail("self-healing recovery JSON report out of date")
        if OUT_MD.read_text(encoding="utf-8") != out_md:
            _fail("self-healing recovery markdown report out of date")
        print("OK: URK self-healing recovery report is in sync.")
        return 0

    OUT_JSON.write_text(out_json, encoding="utf-8")
    OUT_MD.write_text(out_md, encoding="utf-8")
    print(f"Updated {OUT_JSON} and {OUT_MD}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
