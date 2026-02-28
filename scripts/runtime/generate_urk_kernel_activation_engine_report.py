#!/usr/bin/env python3
"""Generate/check URK kernel activation engine report."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

CONFIG_PATH = Path("configs/runtime/urk_kernel_activation_engine_controls.json")
OUT_JSON = Path(
    "docs/plans/methodology/MASTER_PLAN_URK_KERNEL_ACTIVATION_ENGINE_REPORT.json"
)
OUT_MD = Path(
    "docs/plans/methodology/MASTER_PLAN_URK_KERNEL_ACTIVATION_ENGINE_REPORT.md"
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

    coverage = cfg.get("activation_coverage")
    safety = cfg.get("activation_safety")
    if not isinstance(coverage, dict) or not isinstance(safety, dict):
        _fail("activation_coverage and activation_safety must be objects")

    req_trigger = _req_num(
        coverage.get("required_trigger_routing_coverage_pct"),
        "activation_coverage.required_trigger_routing_coverage_pct",
    )
    obs_trigger = _req_num(
        coverage.get("observed_trigger_routing_coverage_pct"),
        "activation_coverage.observed_trigger_routing_coverage_pct",
    )
    req_policy = _req_num(
        coverage.get("required_policy_gate_coverage_pct"),
        "activation_coverage.required_policy_gate_coverage_pct",
    )
    obs_policy = _req_num(
        coverage.get("observed_policy_gate_coverage_pct"),
        "activation_coverage.observed_policy_gate_coverage_pct",
    )
    req_receipt = _req_num(
        coverage.get("required_receipt_coverage_pct"),
        "activation_coverage.required_receipt_coverage_pct",
    )
    obs_receipt = _req_num(
        coverage.get("observed_receipt_coverage_pct"),
        "activation_coverage.observed_receipt_coverage_pct",
    )
    coverage_checks = _req_pos_int(
        coverage.get("checks_executed"), "activation_coverage.checks_executed"
    )

    max_unauthorized = _req_int(
        safety.get("max_unauthorized_activations"),
        "activation_safety.max_unauthorized_activations",
    )
    obs_unauthorized = _req_int(
        safety.get("observed_unauthorized_activations"),
        "activation_safety.observed_unauthorized_activations",
    )
    max_bypass = _req_int(
        safety.get("max_dependency_bypasses"),
        "activation_safety.max_dependency_bypasses",
    )
    obs_bypass = _req_int(
        safety.get("observed_dependency_bypasses"),
        "activation_safety.observed_dependency_bypasses",
    )
    safety_checks = _req_pos_int(
        safety.get("checks_executed"), "activation_safety.checks_executed"
    )

    coverage_ok = (
        obs_trigger >= req_trigger
        and obs_policy >= req_policy
        and obs_receipt >= req_receipt
    )
    safety_ok = obs_unauthorized <= max_unauthorized and obs_bypass <= max_bypass

    errors: list[str] = []
    if not coverage_ok:
        errors.append("kernel activation routing/policy/receipt coverage threshold failed")
    if not safety_ok:
        errors.append("kernel activation safety threshold failed")

    return {
        "version": "v1",
        "source": str(CONFIG_PATH),
        "activation_coverage": {
            "required_trigger_routing_coverage_pct": req_trigger,
            "observed_trigger_routing_coverage_pct": obs_trigger,
            "required_policy_gate_coverage_pct": req_policy,
            "observed_policy_gate_coverage_pct": obs_policy,
            "required_receipt_coverage_pct": req_receipt,
            "observed_receipt_coverage_pct": obs_receipt,
            "checks_executed": coverage_checks,
            "within_threshold": coverage_ok,
        },
        "activation_safety": {
            "max_unauthorized_activations": max_unauthorized,
            "observed_unauthorized_activations": obs_unauthorized,
            "max_dependency_bypasses": max_bypass,
            "observed_dependency_bypasses": obs_bypass,
            "checks_executed": safety_checks,
            "within_threshold": safety_ok,
        },
        "errors": errors,
        "verdict": "PASS" if not errors else "FAIL",
    }


def _render(summary: dict) -> str:
    return (
        "# URK Kernel Activation Engine Report\n\n"
        f"**Source config:** `{summary['source']}`  \n"
        f"**Activation coverage check:** {summary['activation_coverage']['within_threshold']}  \n"
        f"**Activation safety check:** {summary['activation_safety']['within_threshold']}  \n"
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
            _fail("kernel activation engine artifacts missing; run generator")
        if OUT_JSON.read_text(encoding="utf-8") != out_json:
            _fail("kernel activation engine JSON report out of date")
        if OUT_MD.read_text(encoding="utf-8") != out_md:
            _fail("kernel activation engine markdown report out of date")
        print("OK: URK kernel activation engine report is in sync.")
        return 0

    OUT_JSON.write_text(out_json, encoding="utf-8")
    OUT_MD.write_text(out_md, encoding="utf-8")
    print(f"Updated {OUT_JSON} and {OUT_MD}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
