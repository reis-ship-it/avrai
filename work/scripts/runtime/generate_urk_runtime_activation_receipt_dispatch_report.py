#!/usr/bin/env python3
"""Generate/check URK runtime activation receipt dispatch report."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

CONFIG_PATH = Path("configs/runtime/urk_runtime_activation_receipt_dispatch_controls.json")
OUT_JSON = Path(
    "docs/plans/methodology/MASTER_PLAN_URK_RUNTIME_ACTIVATION_RECEIPT_DISPATCH_REPORT.json"
)
OUT_MD = Path(
    "docs/plans/methodology/MASTER_PLAN_URK_RUNTIME_ACTIVATION_RECEIPT_DISPATCH_REPORT.md"
)


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

    coverage = cfg.get("dispatch_coverage")
    safety = cfg.get("dispatch_safety")
    if not isinstance(coverage, dict) or not isinstance(safety, dict):
        _fail("dispatch_coverage and dispatch_safety must be objects")

    req_path = _req_num(
        coverage.get("required_runtime_path_coverage_pct"),
        "dispatch_coverage.required_runtime_path_coverage_pct",
    )
    obs_path = _req_num(
        coverage.get("observed_runtime_path_coverage_pct"),
        "dispatch_coverage.observed_runtime_path_coverage_pct",
    )
    req_trigger = _req_num(
        coverage.get("required_trigger_mapping_coverage_pct"),
        "dispatch_coverage.required_trigger_mapping_coverage_pct",
    )
    obs_trigger = _req_num(
        coverage.get("observed_trigger_mapping_coverage_pct"),
        "dispatch_coverage.observed_trigger_mapping_coverage_pct",
    )
    req_receipt = _req_num(
        coverage.get("required_receipt_persistence_coverage_pct"),
        "dispatch_coverage.required_receipt_persistence_coverage_pct",
    )
    obs_receipt = _req_num(
        coverage.get("observed_receipt_persistence_coverage_pct"),
        "dispatch_coverage.observed_receipt_persistence_coverage_pct",
    )
    coverage_checks = _req_pos_int(
        coverage.get("checks_executed"), "dispatch_coverage.checks_executed"
    )

    max_untracked = _req_int(
        safety.get("max_untracked_activation_events"),
        "dispatch_safety.max_untracked_activation_events",
    )
    obs_untracked = _req_int(
        safety.get("observed_untracked_activation_events"),
        "dispatch_safety.observed_untracked_activation_events",
    )
    max_collisions = _req_int(
        safety.get("max_trigger_mapping_collisions"),
        "dispatch_safety.max_trigger_mapping_collisions",
    )
    obs_collisions = _req_int(
        safety.get("observed_trigger_mapping_collisions"),
        "dispatch_safety.observed_trigger_mapping_collisions",
    )
    safety_checks = _req_pos_int(
        safety.get("checks_executed"), "dispatch_safety.checks_executed"
    )

    coverage_ok = (
        obs_path >= req_path and obs_trigger >= req_trigger and obs_receipt >= req_receipt
    )
    safety_ok = obs_untracked <= max_untracked and obs_collisions <= max_collisions

    errors: list[str] = []
    if not coverage_ok:
        errors.append("runtime activation receipt dispatch coverage threshold failed")
    if not safety_ok:
        errors.append("runtime activation receipt dispatch safety threshold failed")

    return {
        "version": "v1",
        "source": str(CONFIG_PATH),
        "dispatch_coverage": {
            "required_runtime_path_coverage_pct": req_path,
            "observed_runtime_path_coverage_pct": obs_path,
            "required_trigger_mapping_coverage_pct": req_trigger,
            "observed_trigger_mapping_coverage_pct": obs_trigger,
            "required_receipt_persistence_coverage_pct": req_receipt,
            "observed_receipt_persistence_coverage_pct": obs_receipt,
            "checks_executed": coverage_checks,
            "within_threshold": coverage_ok,
        },
        "dispatch_safety": {
            "max_untracked_activation_events": max_untracked,
            "observed_untracked_activation_events": obs_untracked,
            "max_trigger_mapping_collisions": max_collisions,
            "observed_trigger_mapping_collisions": obs_collisions,
            "checks_executed": safety_checks,
            "within_threshold": safety_ok,
        },
        "errors": errors,
        "verdict": "PASS" if not errors else "FAIL",
    }


def _render(summary: dict) -> str:
    return (
        "# URK Runtime Activation Receipt Dispatch Report\n\n"
        f"**Source config:** `{summary['source']}`  \n"
        f"**Dispatch coverage check:** {summary['dispatch_coverage']['within_threshold']}  \n"
        f"**Dispatch safety check:** {summary['dispatch_safety']['within_threshold']}  \n"
        f"**Verdict:** {summary['verdict']}\n\n"
        "## Validation Errors\n\n"
        + (
            "- None\n"
            if not summary["errors"]
            else "\n".join(f"- {e}" for e in summary["errors"]) + "\n"
        )
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
            _fail("runtime activation receipt dispatch artifacts missing; run generator")
        if OUT_JSON.read_text(encoding="utf-8") != out_json:
            _fail("runtime activation receipt dispatch JSON report out of date")
        if OUT_MD.read_text(encoding="utf-8") != out_md:
            _fail("runtime activation receipt dispatch markdown report out of date")
        print("OK: URK runtime activation receipt dispatch report is in sync.")
        return 0

    OUT_JSON.write_text(out_json, encoding="utf-8")
    OUT_MD.write_text(out_md, encoding="utf-8")
    print(f"Updated {OUT_JSON} and {OUT_MD}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
