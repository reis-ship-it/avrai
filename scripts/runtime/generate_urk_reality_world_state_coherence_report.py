#!/usr/bin/env python3
"""Generate/check URK reality world-state coherence report."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

CONFIG_PATH = Path("configs/runtime/urk_reality_world_state_coherence_controls.json")
OUT_JSON = Path("docs/plans/methodology/MASTER_PLAN_URK_REALITY_WORLD_STATE_COHERENCE_REPORT.json")
OUT_MD = Path("docs/plans/methodology/MASTER_PLAN_URK_REALITY_WORLD_STATE_COHERENCE_REPORT.md")


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
    coverage = cfg.get("coherence_coverage")
    stability = cfg.get("stability_guard")
    if not isinstance(coverage, dict) or not isinstance(stability, dict):
        _fail("coherence_coverage and stability_guard must be objects")

    req_plane = _req_num(
        coverage.get("required_plane_consistency_coverage_pct"),
        "coherence_coverage.required_plane_consistency_coverage_pct",
    )
    obs_plane = _req_num(
        coverage.get("observed_plane_consistency_coverage_pct"),
        "coherence_coverage.observed_plane_consistency_coverage_pct",
    )
    req_knot = _req_num(
        coverage.get("required_knot_string_constraint_coverage_pct"),
        "coherence_coverage.required_knot_string_constraint_coverage_pct",
    )
    obs_knot = _req_num(
        coverage.get("observed_knot_string_constraint_coverage_pct"),
        "coherence_coverage.observed_knot_string_constraint_coverage_pct",
    )
    cov_checks = _req_pos_int(coverage.get("checks_executed"), "coherence_coverage.checks_executed")

    max_conflict = _req_int(
        stability.get("max_cross_plane_conflicts"),
        "stability_guard.max_cross_plane_conflicts",
    )
    obs_conflict = _req_int(
        stability.get("observed_cross_plane_conflicts"),
        "stability_guard.observed_cross_plane_conflicts",
    )
    max_unresolved = _req_int(
        stability.get("max_unresolved_state_transitions"),
        "stability_guard.max_unresolved_state_transitions",
    )
    obs_unresolved = _req_int(
        stability.get("observed_unresolved_state_transitions"),
        "stability_guard.observed_unresolved_state_transitions",
    )
    stab_checks = _req_pos_int(stability.get("checks_executed"), "stability_guard.checks_executed")

    coverage_ok = obs_plane >= req_plane and obs_knot >= req_knot
    stability_ok = obs_conflict <= max_conflict and obs_unresolved <= max_unresolved
    errors: list[str] = []
    if not coverage_ok:
        errors.append("world-state coherence coverage threshold failed")
    if not stability_ok:
        errors.append("cross-plane stability threshold failed")

    return {
        "version": "v1",
        "source": str(CONFIG_PATH),
        "coherence_coverage": {
            "required_plane_consistency_coverage_pct": req_plane,
            "observed_plane_consistency_coverage_pct": obs_plane,
            "required_knot_string_constraint_coverage_pct": req_knot,
            "observed_knot_string_constraint_coverage_pct": obs_knot,
            "checks_executed": cov_checks,
            "within_threshold": coverage_ok,
        },
        "stability_guard": {
            "max_cross_plane_conflicts": max_conflict,
            "observed_cross_plane_conflicts": obs_conflict,
            "max_unresolved_state_transitions": max_unresolved,
            "observed_unresolved_state_transitions": obs_unresolved,
            "checks_executed": stab_checks,
            "within_threshold": stability_ok,
        },
        "errors": errors,
        "verdict": "PASS" if not errors else "FAIL",
    }


def _render(summary: dict) -> str:
    return (
        "# URK Reality World-State Coherence Report\n\n"
        f"**Source config:** `{summary['source']}`  \n"
        f"**Coherence coverage check:** {summary['coherence_coverage']['within_threshold']}  \n"
        f"**Stability guard check:** {summary['stability_guard']['within_threshold']}  \n"
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
            _fail("reality world-state coherence artifacts missing; run generator")
        if OUT_JSON.read_text(encoding="utf-8") != out_json:
            _fail("reality world-state coherence JSON report out of date")
        if OUT_MD.read_text(encoding="utf-8") != out_md:
            _fail("reality world-state coherence markdown report out of date")
        print("OK: URK reality world-state coherence report is in sync.")
        return 0

    OUT_JSON.write_text(out_json, encoding="utf-8")
    OUT_MD.write_text(out_md, encoding="utf-8")
    print(f"Updated {OUT_JSON} and {OUT_MD}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
