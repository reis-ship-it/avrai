#!/usr/bin/env python3
"""Generate/check URK reality temporal truth report."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

CONFIG_PATH = Path("configs/runtime/urk_reality_temporal_truth_controls.json")
OUT_JSON = Path("docs/plans/methodology/MASTER_PLAN_URK_REALITY_TEMPORAL_TRUTH_REPORT.json")
OUT_MD = Path("docs/plans/methodology/MASTER_PLAN_URK_REALITY_TEMPORAL_TRUTH_REPORT.md")


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
    alignment = cfg.get("temporal_alignment")
    safety = cfg.get("timeline_safety")
    if not isinstance(alignment, dict) or not isinstance(safety, dict):
        _fail("temporal_alignment and timeline_safety must be objects")

    req_align = _req_num(
        alignment.get("required_atomic_semantic_alignment_pct"),
        "temporal_alignment.required_atomic_semantic_alignment_pct",
    )
    obs_align = _req_num(
        alignment.get("observed_atomic_semantic_alignment_pct"),
        "temporal_alignment.observed_atomic_semantic_alignment_pct",
    )
    req_tz = _req_num(
        alignment.get("required_timezone_normalization_coverage_pct"),
        "temporal_alignment.required_timezone_normalization_coverage_pct",
    )
    obs_tz = _req_num(
        alignment.get("observed_timezone_normalization_coverage_pct"),
        "temporal_alignment.observed_timezone_normalization_coverage_pct",
    )
    align_checks = _req_pos_int(alignment.get("checks_executed"), "temporal_alignment.checks_executed")

    max_contra = _req_int(
        safety.get("max_temporal_contradiction_events"),
        "timeline_safety.max_temporal_contradiction_events",
    )
    obs_contra = _req_int(
        safety.get("observed_temporal_contradiction_events"),
        "timeline_safety.observed_temporal_contradiction_events",
    )
    max_regress = _req_int(
        safety.get("max_clock_regression_events"),
        "timeline_safety.max_clock_regression_events",
    )
    obs_regress = _req_int(
        safety.get("observed_clock_regression_events"),
        "timeline_safety.observed_clock_regression_events",
    )
    safety_checks = _req_pos_int(safety.get("checks_executed"), "timeline_safety.checks_executed")

    align_ok = obs_align >= req_align and obs_tz >= req_tz
    safety_ok = obs_contra <= max_contra and obs_regress <= max_regress
    errors: list[str] = []
    if not align_ok:
        errors.append("temporal alignment coverage threshold failed")
    if not safety_ok:
        errors.append("timeline safety threshold failed")

    return {
        "version": "v1",
        "source": str(CONFIG_PATH),
        "temporal_alignment": {
            "required_atomic_semantic_alignment_pct": req_align,
            "observed_atomic_semantic_alignment_pct": obs_align,
            "required_timezone_normalization_coverage_pct": req_tz,
            "observed_timezone_normalization_coverage_pct": obs_tz,
            "checks_executed": align_checks,
            "within_threshold": align_ok,
        },
        "timeline_safety": {
            "max_temporal_contradiction_events": max_contra,
            "observed_temporal_contradiction_events": obs_contra,
            "max_clock_regression_events": max_regress,
            "observed_clock_regression_events": obs_regress,
            "checks_executed": safety_checks,
            "within_threshold": safety_ok,
        },
        "errors": errors,
        "verdict": "PASS" if not errors else "FAIL",
    }


def _render(summary: dict) -> str:
    return (
        "# URK Reality Temporal Truth Report\n\n"
        f"**Source config:** `{summary['source']}`  \n"
        f"**Temporal alignment check:** {summary['temporal_alignment']['within_threshold']}  \n"
        f"**Timeline safety check:** {summary['timeline_safety']['within_threshold']}  \n"
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
            _fail("reality temporal truth artifacts missing; run generator")
        if OUT_JSON.read_text(encoding="utf-8") != out_json:
            _fail("reality temporal truth JSON report out of date")
        if OUT_MD.read_text(encoding="utf-8") != out_md:
            _fail("reality temporal truth markdown report out of date")
        print("OK: URK reality temporal truth report is in sync.")
        return 0

    OUT_JSON.write_text(out_json, encoding="utf-8")
    OUT_MD.write_text(out_md, encoding="utf-8")
    print(f"Updated {OUT_JSON} and {OUT_MD}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
