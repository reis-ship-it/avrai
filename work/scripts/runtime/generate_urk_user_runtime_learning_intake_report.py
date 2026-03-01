#!/usr/bin/env python3
"""Generate/check URK user runtime learning intake report."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

CONFIG_PATH = Path("configs/runtime/urk_user_runtime_learning_intake_controls.json")
OUT_JSON = Path(
    "docs/plans/methodology/MASTER_PLAN_URK_USER_RUNTIME_LEARNING_INTAKE_REPORT.json"
)
OUT_MD = Path(
    "docs/plans/methodology/MASTER_PLAN_URK_USER_RUNTIME_LEARNING_INTAKE_REPORT.md"
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

    coverage = cfg.get("learning_intake_coverage")
    safety = cfg.get("learning_intake_safety")
    if not isinstance(coverage, dict) or not isinstance(safety, dict):
        _fail("learning_intake_coverage and learning_intake_safety must be objects")

    req_signal = _req_num(
        coverage.get("required_signal_capture_coverage_pct"),
        "learning_intake_coverage.required_signal_capture_coverage_pct",
    )
    obs_signal = _req_num(
        coverage.get("observed_signal_capture_coverage_pct"),
        "learning_intake_coverage.observed_signal_capture_coverage_pct",
    )
    req_pseudo = _req_num(
        coverage.get("required_pseudonymous_actor_coverage_pct"),
        "learning_intake_coverage.required_pseudonymous_actor_coverage_pct",
    )
    obs_pseudo = _req_num(
        coverage.get("observed_pseudonymous_actor_coverage_pct"),
        "learning_intake_coverage.observed_pseudonymous_actor_coverage_pct",
    )
    req_local = _req_num(
        coverage.get("required_on_device_first_processing_pct"),
        "learning_intake_coverage.required_on_device_first_processing_pct",
    )
    obs_local = _req_num(
        coverage.get("observed_on_device_first_processing_pct"),
        "learning_intake_coverage.observed_on_device_first_processing_pct",
    )
    coverage_checks = _req_pos_int(
        coverage.get("checks_executed"), "learning_intake_coverage.checks_executed"
    )

    max_raw = _req_int(
        safety.get("max_raw_user_identifier_egress_events"),
        "learning_intake_safety.max_raw_user_identifier_egress_events",
    )
    obs_raw = _req_int(
        safety.get("observed_raw_user_identifier_egress_events"),
        "learning_intake_safety.observed_raw_user_identifier_egress_events",
    )
    max_missing_consent = _req_int(
        safety.get("max_missing_consent_events"),
        "learning_intake_safety.max_missing_consent_events",
    )
    obs_missing_consent = _req_int(
        safety.get("observed_missing_consent_events"),
        "learning_intake_safety.observed_missing_consent_events",
    )
    safety_checks = _req_pos_int(
        safety.get("checks_executed"), "learning_intake_safety.checks_executed"
    )

    coverage_ok = (
        obs_signal >= req_signal and obs_pseudo >= req_pseudo and obs_local >= req_local
    )
    safety_ok = obs_raw <= max_raw and obs_missing_consent <= max_missing_consent

    errors: list[str] = []
    if not coverage_ok:
        errors.append("user runtime learning intake coverage threshold failed")
    if not safety_ok:
        errors.append("user runtime learning intake safety threshold failed")

    return {
        "version": "v1",
        "source": str(CONFIG_PATH),
        "learning_intake_coverage": {
            "required_signal_capture_coverage_pct": req_signal,
            "observed_signal_capture_coverage_pct": obs_signal,
            "required_pseudonymous_actor_coverage_pct": req_pseudo,
            "observed_pseudonymous_actor_coverage_pct": obs_pseudo,
            "required_on_device_first_processing_pct": req_local,
            "observed_on_device_first_processing_pct": obs_local,
            "checks_executed": coverage_checks,
            "within_threshold": coverage_ok,
        },
        "learning_intake_safety": {
            "max_raw_user_identifier_egress_events": max_raw,
            "observed_raw_user_identifier_egress_events": obs_raw,
            "max_missing_consent_events": max_missing_consent,
            "observed_missing_consent_events": obs_missing_consent,
            "checks_executed": safety_checks,
            "within_threshold": safety_ok,
        },
        "errors": errors,
        "verdict": "PASS" if not errors else "FAIL",
    }


def _render(summary: dict) -> str:
    return (
        "# URK User Runtime Learning Intake Report\n\n"
        f"**Source config:** `{summary['source']}`  \n"
        f"**Learning intake coverage check:** {summary['learning_intake_coverage']['within_threshold']}  \n"
        f"**Learning intake safety check:** {summary['learning_intake_safety']['within_threshold']}  \n"
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
            _fail("user runtime learning intake artifacts missing; run generator")
        if OUT_JSON.read_text(encoding="utf-8") != out_json:
            _fail("user runtime learning intake JSON report out of date")
        if OUT_MD.read_text(encoding="utf-8") != out_md:
            _fail("user runtime learning intake markdown report out of date")
        print("OK: URK user runtime learning intake report is in sync.")
        return 0

    OUT_JSON.write_text(out_json, encoding="utf-8")
    OUT_MD.write_text(out_md, encoding="utf-8")
    print(f"Updated {OUT_JSON} and {OUT_MD}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
