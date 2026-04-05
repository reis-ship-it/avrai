#!/usr/bin/env python3
"""Generate/check URK self-learning governance report."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

CONFIG_PATH = Path("configs/runtime/urk_self_learning_governance_controls.json")
OUT_JSON = Path("docs/plans/methodology/MASTER_PLAN_URK_SELF_LEARNING_GOVERNANCE_REPORT.json")
OUT_MD = Path("docs/plans/methodology/MASTER_PLAN_URK_SELF_LEARNING_GOVERNANCE_REPORT.md")


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

    coverage = cfg.get("learning_policy_coverage")
    safety = cfg.get("learning_safety")
    if not isinstance(coverage, dict) or not isinstance(safety, dict):
        _fail("learning_policy_coverage and learning_safety must be objects")

    req_signal = _req_num(
        coverage.get("required_signal_validation_coverage_pct"),
        "learning_policy_coverage.required_signal_validation_coverage_pct",
    )
    obs_signal = _req_num(
        coverage.get("observed_signal_validation_coverage_pct"),
        "learning_policy_coverage.observed_signal_validation_coverage_pct",
    )
    req_approval = _req_num(
        coverage.get("required_approval_path_coverage_pct"),
        "learning_policy_coverage.required_approval_path_coverage_pct",
    )
    obs_approval = _req_num(
        coverage.get("observed_approval_path_coverage_pct"),
        "learning_policy_coverage.observed_approval_path_coverage_pct",
    )
    cov_checks = _req_pos_int(
        coverage.get("checks_executed"), "learning_policy_coverage.checks_executed"
    )

    max_unbounded = _req_int(
        safety.get("max_unbounded_self_learning_updates"),
        "learning_safety.max_unbounded_self_learning_updates",
    )
    obs_unbounded = _req_int(
        safety.get("observed_unbounded_self_learning_updates"),
        "learning_safety.observed_unbounded_self_learning_updates",
    )
    max_unverified = _req_int(
        safety.get("max_unverified_training_lineage_events"),
        "learning_safety.max_unverified_training_lineage_events",
    )
    obs_unverified = _req_int(
        safety.get("observed_unverified_training_lineage_events"),
        "learning_safety.observed_unverified_training_lineage_events",
    )
    safety_checks = _req_pos_int(
        safety.get("checks_executed"), "learning_safety.checks_executed"
    )

    coverage_ok = obs_signal >= req_signal and obs_approval >= req_approval
    safety_ok = obs_unbounded <= max_unbounded and obs_unverified <= max_unverified
    errors: list[str] = []
    if not coverage_ok:
        errors.append("self-learning validation/approval coverage threshold failed")
    if not safety_ok:
        errors.append("self-learning safety threshold failed")

    return {
        "version": "v1",
        "source": str(CONFIG_PATH),
        "learning_policy_coverage": {
            "required_signal_validation_coverage_pct": req_signal,
            "observed_signal_validation_coverage_pct": obs_signal,
            "required_approval_path_coverage_pct": req_approval,
            "observed_approval_path_coverage_pct": obs_approval,
            "checks_executed": cov_checks,
            "within_threshold": coverage_ok,
        },
        "learning_safety": {
            "max_unbounded_self_learning_updates": max_unbounded,
            "observed_unbounded_self_learning_updates": obs_unbounded,
            "max_unverified_training_lineage_events": max_unverified,
            "observed_unverified_training_lineage_events": obs_unverified,
            "checks_executed": safety_checks,
            "within_threshold": safety_ok,
        },
        "errors": errors,
        "verdict": "PASS" if not errors else "FAIL",
    }


def _render(summary: dict) -> str:
    return (
        "# URK Self-Learning Governance Report\n\n"
        f"**Source config:** `{summary['source']}`  \n"
        f"**Learning policy coverage check:** {summary['learning_policy_coverage']['within_threshold']}  \n"
        f"**Learning safety check:** {summary['learning_safety']['within_threshold']}  \n"
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
            _fail("self-learning governance artifacts missing; run generator")
        if OUT_JSON.read_text(encoding="utf-8") != out_json:
            _fail("self-learning governance JSON report out of date")
        if OUT_MD.read_text(encoding="utf-8") != out_md:
            _fail("self-learning governance markdown report out of date")
        print("OK: URK self-learning governance report is in sync.")
        return 0

    OUT_JSON.write_text(out_json, encoding="utf-8")
    OUT_MD.write_text(out_md, encoding="utf-8")
    print(f"Updated {OUT_JSON} and {OUT_MD}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
