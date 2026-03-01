#!/usr/bin/env python3
"""Generate/check URK kernel control plane report."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

CONFIG_PATH = Path("configs/runtime/urk_kernel_control_plane_controls.json")
OUT_JSON = Path(
    "docs/plans/methodology/MASTER_PLAN_URK_KERNEL_CONTROL_PLANE_REPORT.json"
)
OUT_MD = Path(
    "docs/plans/methodology/MASTER_PLAN_URK_KERNEL_CONTROL_PLANE_REPORT.md"
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

    coverage = cfg.get("control_plane_coverage")
    safety = cfg.get("control_plane_safety")
    if not isinstance(coverage, dict) or not isinstance(safety, dict):
        _fail("control_plane_coverage and control_plane_safety must be objects")

    req_state = _req_num(
        coverage.get("required_state_query_coverage_pct"),
        "control_plane_coverage.required_state_query_coverage_pct",
    )
    obs_state = _req_num(
        coverage.get("observed_state_query_coverage_pct"),
        "control_plane_coverage.observed_state_query_coverage_pct",
    )
    req_health = _req_num(
        coverage.get("required_health_query_coverage_pct"),
        "control_plane_coverage.required_health_query_coverage_pct",
    )
    obs_health = _req_num(
        coverage.get("observed_health_query_coverage_pct"),
        "control_plane_coverage.observed_health_query_coverage_pct",
    )
    req_lineage = _req_num(
        coverage.get("required_lineage_query_coverage_pct"),
        "control_plane_coverage.required_lineage_query_coverage_pct",
    )
    obs_lineage = _req_num(
        coverage.get("observed_lineage_query_coverage_pct"),
        "control_plane_coverage.observed_lineage_query_coverage_pct",
    )
    cov_checks = _req_pos_int(
        coverage.get("checks_executed"), "control_plane_coverage.checks_executed"
    )

    max_unauthorized = _req_int(
        safety.get("max_unauthorized_state_changes"),
        "control_plane_safety.max_unauthorized_state_changes",
    )
    obs_unauthorized = _req_int(
        safety.get("observed_unauthorized_state_changes"),
        "control_plane_safety.observed_unauthorized_state_changes",
    )
    max_invalid_transition = _req_int(
        safety.get("max_invalid_transition_attempts"),
        "control_plane_safety.max_invalid_transition_attempts",
    )
    obs_invalid_transition = _req_int(
        safety.get("observed_invalid_transition_attempts"),
        "control_plane_safety.observed_invalid_transition_attempts",
    )
    safety_checks = _req_pos_int(
        safety.get("checks_executed"), "control_plane_safety.checks_executed"
    )

    coverage_ok = (
        obs_state >= req_state
        and obs_health >= req_health
        and obs_lineage >= req_lineage
    )
    safety_ok = (
        obs_unauthorized <= max_unauthorized
        and obs_invalid_transition <= max_invalid_transition
    )
    errors: list[str] = []
    if not coverage_ok:
        errors.append("kernel control-plane query coverage threshold failed")
    if not safety_ok:
        errors.append("kernel control-plane transition safety threshold failed")

    return {
        "version": "v1",
        "source": str(CONFIG_PATH),
        "control_plane_coverage": {
            "required_state_query_coverage_pct": req_state,
            "observed_state_query_coverage_pct": obs_state,
            "required_health_query_coverage_pct": req_health,
            "observed_health_query_coverage_pct": obs_health,
            "required_lineage_query_coverage_pct": req_lineage,
            "observed_lineage_query_coverage_pct": obs_lineage,
            "checks_executed": cov_checks,
            "within_threshold": coverage_ok,
        },
        "control_plane_safety": {
            "max_unauthorized_state_changes": max_unauthorized,
            "observed_unauthorized_state_changes": obs_unauthorized,
            "max_invalid_transition_attempts": max_invalid_transition,
            "observed_invalid_transition_attempts": obs_invalid_transition,
            "checks_executed": safety_checks,
            "within_threshold": safety_ok,
        },
        "errors": errors,
        "verdict": "PASS" if not errors else "FAIL",
    }


def _render(summary: dict) -> str:
    return (
        "# URK Kernel Control Plane Report\n\n"
        f"**Source config:** `{summary['source']}`  \n"
        f"**Control-plane coverage check:** {summary['control_plane_coverage']['within_threshold']}  \n"
        f"**Control-plane safety check:** {summary['control_plane_safety']['within_threshold']}  \n"
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
            _fail("kernel control-plane artifacts missing; run generator")
        if OUT_JSON.read_text(encoding="utf-8") != out_json:
            _fail("kernel control-plane JSON report out of date")
        if OUT_MD.read_text(encoding="utf-8") != out_md:
            _fail("kernel control-plane markdown report out of date")
        print("OK: URK kernel control plane report is in sync.")
        return 0

    OUT_JSON.write_text(out_json, encoding="utf-8")
    OUT_MD.write_text(out_md, encoding="utf-8")
    print(f"Updated {OUT_JSON} and {OUT_MD}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
