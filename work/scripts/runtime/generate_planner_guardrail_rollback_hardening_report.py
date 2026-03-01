#!/usr/bin/env python3
"""Generate/check planner guardrail + rollback hardening report."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import sys
from pathlib import Path

CONFIG_PATH = Path("configs/runtime/planner_guardrail_rollback_hardening_controls.json")
OUT_JSON = Path(
    "docs/plans/methodology/MASTER_PLAN_PLANNER_GUARDRAIL_ROLLBACK_HARDENING_REPORT.json"
)
OUT_MD = Path(
    "docs/plans/methodology/MASTER_PLAN_PLANNER_GUARDRAIL_ROLLBACK_HARDENING_REPORT.md"
)


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

    guardrails = cfg.get("planner_guardrails")
    if not isinstance(guardrails, dict):
        _fail("planner_guardrails must be object")
    max_violation = _require_non_negative_number(
        guardrails.get("max_hard_constraint_violation_rate_pct"),
        "planner_guardrails.max_hard_constraint_violation_rate_pct",
    )
    observed_violation = _require_non_negative_number(
        guardrails.get("observed_hard_constraint_violation_rate_pct"),
        "planner_guardrails.observed_hard_constraint_violation_rate_pct",
    )
    actions_evaluated = _require_positive_int(
        guardrails.get("planned_actions_evaluated"),
        "planner_guardrails.planned_actions_evaluated",
    )
    envelope_passed = guardrails.get("hard_constraint_envelope_passed") is True

    rollback = cfg.get("rollback_drill")
    if not isinstance(rollback, dict):
        _fail("rollback_drill must be object")
    required_success_rate = _require_non_negative_number(
        rollback.get("required_success_rate_pct"),
        "rollback_drill.required_success_rate_pct",
    )
    observed_success_rate = _require_non_negative_number(
        rollback.get("observed_success_rate_pct"),
        "rollback_drill.observed_success_rate_pct",
    )
    max_recovery_latency = _require_non_negative_number(
        rollback.get("max_recovery_latency_seconds"),
        "rollback_drill.max_recovery_latency_seconds",
    )
    observed_recovery_latency = _require_non_negative_number(
        rollback.get("observed_p95_recovery_latency_seconds"),
        "rollback_drill.observed_p95_recovery_latency_seconds",
    )
    drills_executed = _require_positive_int(
        rollback.get("drills_executed"),
        "rollback_drill.drills_executed",
    )

    integrity = cfg.get("atomic_bundle_integrity")
    if not isinstance(integrity, dict):
        _fail("atomic_bundle_integrity must be object")
    soft_integrity = integrity.get("soft_rollback_integrity_passed") is True
    hard_integrity = integrity.get("hard_rollback_integrity_passed") is True
    provenance_integrity = integrity.get("provenance_log_completeness_passed") is True
    bundle_checks = _require_positive_int(
        integrity.get("bundle_checks_executed"),
        "atomic_bundle_integrity.bundle_checks_executed",
    )

    guardrail_ok = observed_violation <= max_violation and envelope_passed
    rollback_ok = (
        observed_success_rate >= required_success_rate
        and observed_recovery_latency <= max_recovery_latency
    )
    integrity_ok = soft_integrity and hard_integrity and provenance_integrity

    errors: list[str] = []
    if not guardrail_ok:
        errors.append("planner hard-constraint violation rate exceeded threshold")
    if not rollback_ok:
        errors.append("rollback drill success/latency threshold failed")
    if not integrity_ok:
        errors.append("atomic rollback bundle integrity/provenance check failed")

    verdict = "PASS" if guardrail_ok and rollback_ok and integrity_ok and not errors else "FAIL"

    return {
        "version": "v1",
        "source": str(CONFIG_PATH),
        "generated_at": generated_at.replace(microsecond=0).isoformat().replace("+00:00", "Z"),
        "planner_guardrails": {
            "max_hard_constraint_violation_rate_pct": max_violation,
            "observed_hard_constraint_violation_rate_pct": observed_violation,
            "planned_actions_evaluated": actions_evaluated,
            "hard_constraint_envelope_passed": envelope_passed,
            "within_threshold": guardrail_ok,
        },
        "rollback_drill": {
            "required_success_rate_pct": required_success_rate,
            "observed_success_rate_pct": observed_success_rate,
            "max_recovery_latency_seconds": max_recovery_latency,
            "observed_p95_recovery_latency_seconds": observed_recovery_latency,
            "drills_executed": drills_executed,
            "within_threshold": rollback_ok,
        },
        "atomic_bundle_integrity": {
            "soft_rollback_integrity_passed": soft_integrity,
            "hard_rollback_integrity_passed": hard_integrity,
            "provenance_log_completeness_passed": provenance_integrity,
            "bundle_checks_executed": bundle_checks,
            "within_threshold": integrity_ok,
        },
        "errors": errors,
        "verdict": verdict,
    }


def _render_md(summary: dict) -> str:
    guardrails = summary.get("planner_guardrails") or {}
    rollback = summary.get("rollback_drill") or {}
    integrity = summary.get("atomic_bundle_integrity") or {}

    return (
        "# Planner Guardrail/Rollback Hardening Report\n\n"
        f"**Source config:** `{summary.get('source')}`  \n"
        f"**Generated at:** {summary.get('generated_at')}  \n"
        f"**Max hard-constraint violation rate (%):** {guardrails.get('max_hard_constraint_violation_rate_pct', 0.0):.2f}  \n"
        f"**Observed hard-constraint violation rate (%):** {guardrails.get('observed_hard_constraint_violation_rate_pct', 0.0):.2f}  \n"
        f"**Planned actions evaluated:** {guardrails.get('planned_actions_evaluated', 0)}  \n"
        f"**Hard-constraint envelope passed:** {guardrails.get('hard_constraint_envelope_passed')}  \n"
        f"**Guardrail threshold check:** {guardrails.get('within_threshold')}  \n"
        f"**Required rollback success rate (%):** {rollback.get('required_success_rate_pct', 0.0):.2f}  \n"
        f"**Observed rollback success rate (%):** {rollback.get('observed_success_rate_pct', 0.0):.2f}  \n"
        f"**Max recovery latency (s):** {rollback.get('max_recovery_latency_seconds', 0.0):.2f}  \n"
        f"**Observed p95 recovery latency (s):** {rollback.get('observed_p95_recovery_latency_seconds', 0.0):.2f}  \n"
        f"**Rollback drills executed:** {rollback.get('drills_executed', 0)}  \n"
        f"**Rollback threshold check:** {rollback.get('within_threshold')}  \n"
        f"**Soft rollback integrity passed:** {integrity.get('soft_rollback_integrity_passed')}  \n"
        f"**Hard rollback integrity passed:** {integrity.get('hard_rollback_integrity_passed')}  \n"
        f"**Provenance completeness passed:** {integrity.get('provenance_log_completeness_passed')}  \n"
        f"**Bundle checks executed:** {integrity.get('bundle_checks_executed', 0)}  \n"
        f"**Integrity threshold check:** {integrity.get('within_threshold')}  \n"
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
            _fail("planner guardrail/rollback report artifacts missing; run generator")
        if OUT_JSON.read_text(encoding="utf-8") != out_json:
            _fail("planner guardrail/rollback JSON report out of date")
        if OUT_MD.read_text(encoding="utf-8") != out_md:
            _fail("planner guardrail/rollback markdown report out of date")
        print("OK: planner guardrail/rollback hardening report is in sync.")
        return 0

    OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
    OUT_MD.parent.mkdir(parents=True, exist_ok=True)
    OUT_JSON.write_text(out_json, encoding="utf-8")
    OUT_MD.write_text(out_md, encoding="utf-8")
    print(f"Updated {OUT_JSON} and {OUT_MD}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
