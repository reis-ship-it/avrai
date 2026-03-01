#!/usr/bin/env python3
"""Generate/check business data consent governance report."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import sys
from pathlib import Path

CONFIG_PATH = Path("configs/runtime/business_data_consent_governance_controls.json")
OUT_JSON = Path(
    "docs/plans/methodology/MASTER_PLAN_BUSINESS_DATA_CONSENT_GOVERNANCE_REPORT.json"
)
OUT_MD = Path(
    "docs/plans/methodology/MASTER_PLAN_BUSINESS_DATA_CONSENT_GOVERNANCE_REPORT.md"
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

    consent = cfg.get("consent_coverage")
    if not isinstance(consent, dict):
        _fail("consent_coverage must be object")
    min_coverage = _require_non_negative_number(
        consent.get("min_coverage_pct"),
        "consent_coverage.min_coverage_pct",
    )
    observed_coverage = _require_non_negative_number(
        consent.get("observed_coverage_pct"),
        "consent_coverage.observed_coverage_pct",
    )
    unauthorized_events = _require_non_negative_number(
        consent.get("unauthorized_processing_events"),
        "consent_coverage.unauthorized_processing_events",
    )
    flows = _require_positive_int(
        consent.get("evaluated_data_flows"),
        "consent_coverage.evaluated_data_flows",
    )

    dp = cfg.get("dp_enforcement")
    if not isinstance(dp, dict):
        _fail("dp_enforcement must be object")
    max_dp_usage = _require_non_negative_number(
        dp.get("max_dp_budget_usage_pct"),
        "dp_enforcement.max_dp_budget_usage_pct",
    )
    observed_dp_usage = _require_non_negative_number(
        dp.get("observed_dp_budget_usage_pct"),
        "dp_enforcement.observed_dp_budget_usage_pct",
    )
    epsilon_exceeded = _require_non_negative_number(
        dp.get("epsilon_budget_exceeded_events"),
        "dp_enforcement.epsilon_budget_exceeded_events",
    )
    dp_checks = _require_positive_int(
        dp.get("dp_checks_executed"),
        "dp_enforcement.dp_checks_executed",
    )

    audit = cfg.get("audit_completeness")
    if not isinstance(audit, dict):
        _fail("audit_completeness must be object")
    required_completeness = _require_non_negative_number(
        audit.get("required_completeness_pct"),
        "audit_completeness.required_completeness_pct",
    )
    observed_completeness = _require_non_negative_number(
        audit.get("observed_completeness_pct"),
        "audit_completeness.observed_completeness_pct",
    )
    retention_passed = audit.get("retention_policy_passed") is True
    audit_entries = _require_positive_int(
        audit.get("audit_entries_verified"),
        "audit_completeness.audit_entries_verified",
    )

    consent_ok = observed_coverage >= min_coverage and unauthorized_events == 0
    dp_ok = observed_dp_usage <= max_dp_usage and epsilon_exceeded == 0
    audit_ok = observed_completeness >= required_completeness and retention_passed

    errors: list[str] = []
    if not consent_ok:
        errors.append("consent coverage threshold failed or unauthorized processing detected")
    if not dp_ok:
        errors.append("DP budget threshold failed or epsilon budget exceeded")
    if not audit_ok:
        errors.append("audit completeness/retention threshold failed")

    verdict = "PASS" if consent_ok and dp_ok and audit_ok and not errors else "FAIL"

    return {
        "version": "v1",
        "source": str(CONFIG_PATH),
        "generated_at": generated_at.replace(microsecond=0).isoformat().replace("+00:00", "Z"),
        "consent_coverage": {
            "min_coverage_pct": min_coverage,
            "observed_coverage_pct": observed_coverage,
            "unauthorized_processing_events": int(unauthorized_events),
            "evaluated_data_flows": flows,
            "within_threshold": consent_ok,
        },
        "dp_enforcement": {
            "max_dp_budget_usage_pct": max_dp_usage,
            "observed_dp_budget_usage_pct": observed_dp_usage,
            "epsilon_budget_exceeded_events": int(epsilon_exceeded),
            "dp_checks_executed": dp_checks,
            "within_threshold": dp_ok,
        },
        "audit_completeness": {
            "required_completeness_pct": required_completeness,
            "observed_completeness_pct": observed_completeness,
            "retention_policy_passed": retention_passed,
            "audit_entries_verified": audit_entries,
            "within_threshold": audit_ok,
        },
        "errors": errors,
        "verdict": verdict,
    }


def _render_md(summary: dict) -> str:
    consent = summary.get("consent_coverage") or {}
    dp = summary.get("dp_enforcement") or {}
    audit = summary.get("audit_completeness") or {}

    return (
        "# Business Data/Consent Governance Report\n\n"
        f"**Source config:** `{summary.get('source')}`  \n"
        f"**Generated at:** {summary.get('generated_at')}  \n"
        f"**Min consent coverage (%):** {consent.get('min_coverage_pct', 0.0):.2f}  \n"
        f"**Observed consent coverage (%):** {consent.get('observed_coverage_pct', 0.0):.2f}  \n"
        f"**Unauthorized processing events:** {consent.get('unauthorized_processing_events', 0)}  \n"
        f"**Evaluated data flows:** {consent.get('evaluated_data_flows', 0)}  \n"
        f"**Consent threshold check:** {consent.get('within_threshold')}  \n"
        f"**Max DP budget usage (%):** {dp.get('max_dp_budget_usage_pct', 0.0):.2f}  \n"
        f"**Observed DP budget usage (%):** {dp.get('observed_dp_budget_usage_pct', 0.0):.2f}  \n"
        f"**Epsilon exceeded events:** {dp.get('epsilon_budget_exceeded_events', 0)}  \n"
        f"**DP checks executed:** {dp.get('dp_checks_executed', 0)}  \n"
        f"**DP threshold check:** {dp.get('within_threshold')}  \n"
        f"**Required audit completeness (%):** {audit.get('required_completeness_pct', 0.0):.2f}  \n"
        f"**Observed audit completeness (%):** {audit.get('observed_completeness_pct', 0.0):.2f}  \n"
        f"**Retention policy passed:** {audit.get('retention_policy_passed')}  \n"
        f"**Audit entries verified:** {audit.get('audit_entries_verified', 0)}  \n"
        f"**Audit threshold check:** {audit.get('within_threshold')}  \n"
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
            _fail("business data/consent governance report artifacts missing; run generator")
        if OUT_JSON.read_text(encoding="utf-8") != out_json:
            _fail("business data/consent governance JSON report out of date")
        if OUT_MD.read_text(encoding="utf-8") != out_md:
            _fail("business data/consent governance markdown report out of date")
        print("OK: business data/consent governance report is in sync.")
        return 0

    OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
    OUT_MD.parent.mkdir(parents=True, exist_ok=True)
    OUT_JSON.write_text(out_json, encoding="utf-8")
    OUT_MD.write_text(out_md, encoding="utf-8")
    print(f"Updated {OUT_JSON} and {OUT_MD}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
