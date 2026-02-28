#!/usr/bin/env python3
"""Generate/check production readiness + cleanup enforcement report."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import sys
from pathlib import Path

CONFIG_PATH = Path("configs/runtime/production_readiness_cleanup_enforcement_controls.json")
OUT_JSON = Path("docs/plans/methodology/MASTER_PLAN_PRODUCTION_READINESS_CLEANUP_REPORT.json")
OUT_MD = Path("docs/plans/methodology/MASTER_PLAN_PRODUCTION_READINESS_CLEANUP_REPORT.md")


def _fail(msg: str) -> None:
    print(f"ERROR: {msg}", file=sys.stderr)
    raise SystemExit(1)


def _parse_ts(raw: str) -> dt.datetime:
    s = raw.strip()
    if s.endswith("Z"):
        s = s[:-1] + "+00:00"
    v = dt.datetime.fromisoformat(s)
    if v.tzinfo is None:
        v = v.replace(tzinfo=dt.timezone.utc)
    return v.astimezone(dt.timezone.utc)


def _load() -> dict:
    if not CONFIG_PATH.exists():
        _fail(f"missing config: {CONFIG_PATH}")
    try:
        data = json.loads(CONFIG_PATH.read_text(encoding="utf-8"))
    except Exception as exc:
        _fail(f"invalid JSON config: {exc}")
    if not isinstance(data, dict):
        _fail("config root must be object")
    return data


def _require_non_negative_number(value: object, field: str) -> float:
    if not isinstance(value, (int, float)) or value < 0:
        _fail(f"{field} must be non-negative number")
    return float(value)


def _require_positive_int(value: object, field: str) -> int:
    if not isinstance(value, int) or value <= 0:
        _fail(f"{field} must be positive integer")
    return int(value)


def _build_summary(cfg: dict) -> dict:
    if str(cfg.get("version", "")).strip() != "v1":
        _fail("config version must be 'v1'")

    evaluation_at_raw = str(cfg.get("evaluation_at", "")).strip()
    if not evaluation_at_raw:
        _fail("evaluation_at is required")
    try:
        generated_at = _parse_ts(evaluation_at_raw)
    except Exception:
        _fail(f"invalid evaluation_at '{evaluation_at_raw}'")

    gate = cfg.get("adaptive_path_placeholder_gate")
    if not isinstance(gate, dict):
        _fail("adaptive_path_placeholder_gate must be object")
    max_violations = _require_non_negative_number(
        gate.get("max_placeholder_violations"),
        "adaptive_path_placeholder_gate.max_placeholder_violations",
    )
    observed_violations = _require_non_negative_number(
        gate.get("observed_placeholder_violations"),
        "adaptive_path_placeholder_gate.observed_placeholder_violations",
    )
    paths_checked = _require_positive_int(
        gate.get("paths_checked"),
        "adaptive_path_placeholder_gate.paths_checked",
    )

    stability = cfg.get("ci_stability")
    if not isinstance(stability, dict):
        _fail("ci_stability must be object")
    required_pass_rate = _require_non_negative_number(
        stability.get("required_pass_rate_pct"),
        "ci_stability.required_pass_rate_pct",
    )
    observed_pass_rate = _require_non_negative_number(
        stability.get("observed_pass_rate_pct"),
        "ci_stability.observed_pass_rate_pct",
    )
    critical_flaky = _require_non_negative_number(
        stability.get("critical_flaky_failures"),
        "ci_stability.critical_flaky_failures",
    )
    runs_evaluated = _require_positive_int(
        stability.get("runs_evaluated"),
        "ci_stability.runs_evaluated",
    )

    checklist = cfg.get("readiness_checklist")
    if not isinstance(checklist, dict):
        _fail("readiness_checklist must be object")
    required_coverage = _require_non_negative_number(
        checklist.get("required_checklist_coverage_pct"),
        "readiness_checklist.required_checklist_coverage_pct",
    )
    observed_coverage = _require_non_negative_number(
        checklist.get("observed_checklist_coverage_pct"),
        "readiness_checklist.observed_checklist_coverage_pct",
    )
    blocking_items_open = _require_non_negative_number(
        checklist.get("blocking_items_open"),
        "readiness_checklist.blocking_items_open",
    )
    checklist_items = _require_positive_int(
        checklist.get("checklist_items_evaluated"),
        "readiness_checklist.checklist_items_evaluated",
    )

    gate_ok = observed_violations <= max_violations
    stability_ok = observed_pass_rate >= required_pass_rate and critical_flaky == 0
    checklist_ok = observed_coverage >= required_coverage and blocking_items_open == 0

    errors: list[str] = []
    if not gate_ok:
        errors.append("adaptive-path placeholder gate violation threshold failed")
    if not stability_ok:
        errors.append("CI stability threshold failed")
    if not checklist_ok:
        errors.append("readiness checklist coverage/open-blocker threshold failed")

    verdict = "PASS" if gate_ok and stability_ok and checklist_ok and not errors else "FAIL"

    return {
        "version": "v1",
        "source": str(CONFIG_PATH),
        "generated_at": generated_at.replace(microsecond=0).isoformat().replace("+00:00", "Z"),
        "adaptive_path_placeholder_gate": {
            "max_placeholder_violations": int(max_violations),
            "observed_placeholder_violations": int(observed_violations),
            "paths_checked": paths_checked,
            "within_threshold": gate_ok,
        },
        "ci_stability": {
            "required_pass_rate_pct": required_pass_rate,
            "observed_pass_rate_pct": observed_pass_rate,
            "critical_flaky_failures": int(critical_flaky),
            "runs_evaluated": runs_evaluated,
            "within_threshold": stability_ok,
        },
        "readiness_checklist": {
            "required_checklist_coverage_pct": required_coverage,
            "observed_checklist_coverage_pct": observed_coverage,
            "blocking_items_open": int(blocking_items_open),
            "checklist_items_evaluated": checklist_items,
            "within_threshold": checklist_ok,
        },
        "errors": errors,
        "verdict": verdict,
    }


def _render_md(summary: dict) -> str:
    gate = summary.get("adaptive_path_placeholder_gate") or {}
    stability = summary.get("ci_stability") or {}
    checklist = summary.get("readiness_checklist") or {}

    return (
        "# Production Readiness/Cleanup Report\n\n"
        f"**Source config:** `{summary.get('source')}`  \n"
        f"**Generated at:** {summary.get('generated_at')}  \n"
        f"**Max placeholder violations:** {gate.get('max_placeholder_violations', 0)}  \n"
        f"**Observed placeholder violations:** {gate.get('observed_placeholder_violations', 0)}  \n"
        f"**Paths checked:** {gate.get('paths_checked', 0)}  \n"
        f"**Placeholder gate check:** {gate.get('within_threshold')}  \n"
        f"**Required CI pass rate (%):** {stability.get('required_pass_rate_pct', 0.0):.2f}  \n"
        f"**Observed CI pass rate (%):** {stability.get('observed_pass_rate_pct', 0.0):.2f}  \n"
        f"**Critical flaky failures:** {stability.get('critical_flaky_failures', 0)}  \n"
        f"**Runs evaluated:** {stability.get('runs_evaluated', 0)}  \n"
        f"**CI stability check:** {stability.get('within_threshold')}  \n"
        f"**Required checklist coverage (%):** {checklist.get('required_checklist_coverage_pct', 0.0):.2f}  \n"
        f"**Observed checklist coverage (%):** {checklist.get('observed_checklist_coverage_pct', 0.0):.2f}  \n"
        f"**Blocking items open:** {checklist.get('blocking_items_open', 0)}  \n"
        f"**Checklist items evaluated:** {checklist.get('checklist_items_evaluated', 0)}  \n"
        f"**Checklist check:** {checklist.get('within_threshold')}  \n"
        f"**Verdict:** {summary.get('verdict')}\n\n"
        "## Validation Errors\n\n"
        + (
            "- None\n"
            if not summary.get("errors")
            else "\n".join(f"- {e}" for e in summary.get("errors", [])) + "\n"
        )
    )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    summary = _build_summary(_load())
    out_json = json.dumps(summary, indent=2, sort_keys=True) + "\n"
    out_md = _render_md(summary)

    if args.check:
        if not OUT_JSON.exists() or not OUT_MD.exists():
            _fail("production readiness/cleanup report artifacts missing; run generator")
        if OUT_JSON.read_text(encoding="utf-8") != out_json:
            _fail("production readiness/cleanup JSON report out of date")
        if OUT_MD.read_text(encoding="utf-8") != out_md:
            _fail("production readiness/cleanup markdown report out of date")
        print("OK: production readiness/cleanup report is in sync.")
        return 0

    OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
    OUT_MD.parent.mkdir(parents=True, exist_ok=True)
    OUT_JSON.write_text(out_json, encoding="utf-8")
    OUT_MD.write_text(out_md, encoding="utf-8")
    print(f"Updated {OUT_JSON} and {OUT_MD}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
