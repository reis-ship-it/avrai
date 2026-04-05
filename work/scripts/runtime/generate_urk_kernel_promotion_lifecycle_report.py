#!/usr/bin/env python3
"""Generate/check URK kernel promotion lifecycle report."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

CONFIG_PATH = Path("configs/runtime/urk_kernel_promotion_lifecycle_controls.json")
OUT_JSON = Path("docs/plans/methodology/MASTER_PLAN_URK_KERNEL_PROMOTION_LIFECYCLE_REPORT.json")
OUT_MD = Path("docs/plans/methodology/MASTER_PLAN_URK_KERNEL_PROMOTION_LIFECYCLE_REPORT.md")


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
    coverage = cfg.get("lifecycle_coverage")
    safety = cfg.get("promotion_safety")
    if not isinstance(coverage, dict) or not isinstance(safety, dict):
        _fail("lifecycle_coverage and promotion_safety must be objects")

    req_lifecycle = _req_num(
        coverage.get("required_lifecycle_transition_coverage_pct"),
        "lifecycle_coverage.required_lifecycle_transition_coverage_pct",
    )
    obs_lifecycle = _req_num(
        coverage.get("observed_lifecycle_transition_coverage_pct"),
        "lifecycle_coverage.observed_lifecycle_transition_coverage_pct",
    )
    req_approval = _req_num(
        coverage.get("required_approval_chain_coverage_pct"),
        "lifecycle_coverage.required_approval_chain_coverage_pct",
    )
    obs_approval = _req_num(
        coverage.get("observed_approval_chain_coverage_pct"),
        "lifecycle_coverage.observed_approval_chain_coverage_pct",
    )
    coverage_checks = _req_pos_int(
        coverage.get("checks_executed"), "lifecycle_coverage.checks_executed"
    )

    max_unapproved = _req_int(
        safety.get("max_unapproved_enforced_promotions"),
        "promotion_safety.max_unapproved_enforced_promotions",
    )
    obs_unapproved = _req_int(
        safety.get("observed_unapproved_enforced_promotions"),
        "promotion_safety.observed_unapproved_enforced_promotions",
    )
    max_skip = _req_int(
        safety.get("max_stage_skip_promotions"),
        "promotion_safety.max_stage_skip_promotions",
    )
    obs_skip = _req_int(
        safety.get("observed_stage_skip_promotions"),
        "promotion_safety.observed_stage_skip_promotions",
    )
    safety_checks = _req_pos_int(
        safety.get("checks_executed"), "promotion_safety.checks_executed"
    )

    coverage_ok = obs_lifecycle >= req_lifecycle and obs_approval >= req_approval
    safety_ok = obs_unapproved <= max_unapproved and obs_skip <= max_skip
    errors: list[str] = []
    if not coverage_ok:
        errors.append("lifecycle coverage/approval chain threshold failed")
    if not safety_ok:
        errors.append("unsafe promotion threshold failed")

    return {
        "version": "v1",
        "source": str(CONFIG_PATH),
        "lifecycle_coverage": {
            "required_lifecycle_transition_coverage_pct": req_lifecycle,
            "observed_lifecycle_transition_coverage_pct": obs_lifecycle,
            "required_approval_chain_coverage_pct": req_approval,
            "observed_approval_chain_coverage_pct": obs_approval,
            "checks_executed": coverage_checks,
            "within_threshold": coverage_ok,
        },
        "promotion_safety": {
            "max_unapproved_enforced_promotions": max_unapproved,
            "observed_unapproved_enforced_promotions": obs_unapproved,
            "max_stage_skip_promotions": max_skip,
            "observed_stage_skip_promotions": obs_skip,
            "checks_executed": safety_checks,
            "within_threshold": safety_ok,
        },
        "errors": errors,
        "verdict": "PASS" if not errors else "FAIL",
    }


def _render(summary: dict) -> str:
    return (
        "# URK Kernel Promotion Lifecycle Report\n\n"
        f"**Source config:** `{summary['source']}`  \n"
        f"**Lifecycle coverage check:** {summary['lifecycle_coverage']['within_threshold']}  \n"
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
            _fail("kernel promotion lifecycle artifacts missing; run generator")
        if OUT_JSON.read_text(encoding="utf-8") != out_json:
            _fail("kernel promotion lifecycle JSON report out of date")
        if OUT_MD.read_text(encoding="utf-8") != out_md:
            _fail("kernel promotion lifecycle markdown report out of date")
        print("OK: URK kernel promotion lifecycle report is in sync.")
        return 0

    OUT_JSON.write_text(out_json, encoding="utf-8")
    OUT_MD.write_text(out_md, encoding="utf-8")
    print(f"Updated {OUT_JSON} and {OUT_MD}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
