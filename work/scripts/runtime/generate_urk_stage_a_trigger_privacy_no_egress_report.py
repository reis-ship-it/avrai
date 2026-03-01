#!/usr/bin/env python3
"""Generate/check URK Stage A trigger/privacy/no-egress baseline report."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import sys
from pathlib import Path

CONFIG_PATH = Path("configs/runtime/urk_stage_a_trigger_privacy_no_egress_controls.json")
OUT_JSON = Path(
    "docs/plans/methodology/MASTER_PLAN_URK_STAGE_A_TRIGGER_PRIVACY_NO_EGRESS_REPORT.json"
)
OUT_MD = Path(
    "docs/plans/methodology/MASTER_PLAN_URK_STAGE_A_TRIGGER_PRIVACY_NO_EGRESS_REPORT.md"
)


def _fail(msg: str) -> None:
    print(f"ERROR: {msg}", file=sys.stderr)
    raise SystemExit(1)


def _parse_ts(raw: str, field: str) -> dt.datetime:
    s = str(raw).strip()
    if not s:
        _fail(f"{field} is required")
    if s.endswith("Z"):
        s = s[:-1] + "+00:00"
    try:
        value = dt.datetime.fromisoformat(s)
    except ValueError:
        _fail(f"invalid {field} '{raw}'")
    if value.tzinfo is None:
        value = value.replace(tzinfo=dt.timezone.utc)
    return value.astimezone(dt.timezone.utc)


def _require_number(value: object, field: str) -> float:
    if not isinstance(value, (int, float)):
        _fail(f"{field} must be numeric")
    return float(value)


def _require_non_negative_number(value: object, field: str) -> float:
    v = _require_number(value, field)
    if v < 0:
        _fail(f"{field} must be non-negative")
    return v


def _require_positive_int(value: object, field: str) -> int:
    if not isinstance(value, int) or value <= 0:
        _fail(f"{field} must be positive integer")
    return int(value)


def _require_non_negative_int(value: object, field: str) -> int:
    if not isinstance(value, int) or value < 0:
        _fail(f"{field} must be non-negative integer")
    return int(value)


def _load() -> dict:
    if not CONFIG_PATH.exists():
        _fail(f"missing config: {CONFIG_PATH}")
    try:
        data = json.loads(CONFIG_PATH.read_text(encoding="utf-8"))
    except Exception as exc:  # pragma: no cover
        _fail(f"invalid JSON config: {exc}")
    if not isinstance(data, dict):
        _fail("config root must be object")
    return data


def _build_summary(cfg: dict) -> dict:
    if str(cfg.get("version", "")).strip() != "v1":
        _fail("config version must be 'v1'")

    evaluation_at = _parse_ts(cfg.get("evaluation_at"), "evaluation_at")

    window = cfg.get("evaluation_window")
    if not isinstance(window, dict):
        _fail("evaluation_window must be object")
    window_start = _parse_ts(window.get("start"), "evaluation_window.start")
    window_end = _parse_ts(window.get("end"), "evaluation_window.end")
    if window_end < window_start:
        _fail("evaluation_window.end must be >= evaluation_window.start")

    trigger = cfg.get("trigger_coverage")
    if not isinstance(trigger, dict):
        _fail("trigger_coverage must be object")
    required_trigger_cov = _require_non_negative_number(
        trigger.get("required_trigger_class_coverage_pct"),
        "trigger_coverage.required_trigger_class_coverage_pct",
    )
    observed_trigger_cov = _require_non_negative_number(
        trigger.get("observed_trigger_class_coverage_pct"),
        "trigger_coverage.observed_trigger_class_coverage_pct",
    )
    trigger_classes_validated = _require_positive_int(
        trigger.get("trigger_classes_validated"),
        "trigger_coverage.trigger_classes_validated",
    )

    privacy = cfg.get("privacy_mode_gating")
    if not isinstance(privacy, dict):
        _fail("privacy_mode_gating must be object")
    required_policy_cov = _require_non_negative_number(
        privacy.get("required_privacy_mode_policy_coverage_pct"),
        "privacy_mode_gating.required_privacy_mode_policy_coverage_pct",
    )
    observed_policy_cov = _require_non_negative_number(
        privacy.get("observed_privacy_mode_policy_coverage_pct"),
        "privacy_mode_gating.observed_privacy_mode_policy_coverage_pct",
    )
    required_consent_cov = _require_non_negative_number(
        privacy.get("required_consent_gate_coverage_pct"),
        "privacy_mode_gating.required_consent_gate_coverage_pct",
    )
    observed_consent_cov = _require_non_negative_number(
        privacy.get("observed_consent_gate_coverage_pct"),
        "privacy_mode_gating.observed_consent_gate_coverage_pct",
    )
    policy_checks = _require_positive_int(
        privacy.get("policy_checks_executed"),
        "privacy_mode_gating.policy_checks_executed",
    )

    no_egress = cfg.get("no_egress_enforcement")
    if not isinstance(no_egress, dict):
        _fail("no_egress_enforcement must be object")
    required_local_cov = _require_non_negative_number(
        no_egress.get("required_local_sovereign_coverage_pct"),
        "no_egress_enforcement.required_local_sovereign_coverage_pct",
    )
    observed_local_cov = _require_non_negative_number(
        no_egress.get("observed_local_sovereign_coverage_pct"),
        "no_egress_enforcement.observed_local_sovereign_coverage_pct",
    )
    max_violations = _require_non_negative_int(
        no_egress.get("max_no_egress_violations"),
        "no_egress_enforcement.max_no_egress_violations",
    )
    observed_violations = _require_non_negative_int(
        no_egress.get("observed_no_egress_violations"),
        "no_egress_enforcement.observed_no_egress_violations",
    )
    no_egress_checks = _require_positive_int(
        no_egress.get("checks_executed"),
        "no_egress_enforcement.checks_executed",
    )

    trigger_ok = observed_trigger_cov >= required_trigger_cov
    privacy_ok = (
        observed_policy_cov >= required_policy_cov
        and observed_consent_cov >= required_consent_cov
    )
    no_egress_ok = (
        observed_local_cov >= required_local_cov
        and observed_violations <= max_violations
    )

    errors: list[str] = []
    if not trigger_ok:
        errors.append("trigger class coverage below required threshold")
    if not privacy_ok:
        errors.append("privacy mode policy/consent gate coverage below threshold")
    if not no_egress_ok:
        errors.append("local sovereign no-egress enforcement threshold failed")

    verdict = "PASS" if trigger_ok and privacy_ok and no_egress_ok and not errors else "FAIL"

    return {
        "version": "v1",
        "source": str(CONFIG_PATH),
        "generated_at": evaluation_at.replace(microsecond=0)
        .isoformat()
        .replace("+00:00", "Z"),
        "evaluation_window": {
            "start": window_start.replace(microsecond=0)
            .isoformat()
            .replace("+00:00", "Z"),
            "end": window_end.replace(microsecond=0)
            .isoformat()
            .replace("+00:00", "Z"),
        },
        "trigger_coverage": {
            "required_trigger_class_coverage_pct": required_trigger_cov,
            "observed_trigger_class_coverage_pct": observed_trigger_cov,
            "trigger_classes_validated": trigger_classes_validated,
            "within_threshold": trigger_ok,
        },
        "privacy_mode_gating": {
            "required_privacy_mode_policy_coverage_pct": required_policy_cov,
            "observed_privacy_mode_policy_coverage_pct": observed_policy_cov,
            "required_consent_gate_coverage_pct": required_consent_cov,
            "observed_consent_gate_coverage_pct": observed_consent_cov,
            "policy_checks_executed": policy_checks,
            "within_threshold": privacy_ok,
        },
        "no_egress_enforcement": {
            "required_local_sovereign_coverage_pct": required_local_cov,
            "observed_local_sovereign_coverage_pct": observed_local_cov,
            "max_no_egress_violations": max_violations,
            "observed_no_egress_violations": observed_violations,
            "checks_executed": no_egress_checks,
            "within_threshold": no_egress_ok,
        },
        "errors": errors,
        "verdict": verdict,
    }


def _render_md(summary: dict) -> str:
    trigger = summary.get("trigger_coverage") or {}
    privacy = summary.get("privacy_mode_gating") or {}
    no_egress = summary.get("no_egress_enforcement") or {}
    window = summary.get("evaluation_window") or {}

    return (
        "# URK Stage A Trigger/Privacy/No-Egress Report\n\n"
        f"**Source config:** `{summary.get('source')}`  \n"
        f"**Generated at:** {summary.get('generated_at')}  \n"
        f"**Evaluation window:** {window.get('start')} -> {window.get('end')}  \n"
        f"**Required trigger class coverage (%):** {trigger.get('required_trigger_class_coverage_pct', 0.0):.2f}  \n"
        f"**Observed trigger class coverage (%):** {trigger.get('observed_trigger_class_coverage_pct', 0.0):.2f}  \n"
        f"**Trigger classes validated:** {trigger.get('trigger_classes_validated', 0)}  \n"
        f"**Trigger coverage check:** {trigger.get('within_threshold')}  \n"
        f"**Required privacy-policy coverage (%):** {privacy.get('required_privacy_mode_policy_coverage_pct', 0.0):.2f}  \n"
        f"**Observed privacy-policy coverage (%):** {privacy.get('observed_privacy_mode_policy_coverage_pct', 0.0):.2f}  \n"
        f"**Required consent-gate coverage (%):** {privacy.get('required_consent_gate_coverage_pct', 0.0):.2f}  \n"
        f"**Observed consent-gate coverage (%):** {privacy.get('observed_consent_gate_coverage_pct', 0.0):.2f}  \n"
        f"**Policy checks executed:** {privacy.get('policy_checks_executed', 0)}  \n"
        f"**Privacy/consent check:** {privacy.get('within_threshold')}  \n"
        f"**Required local-sovereign no-egress coverage (%):** {no_egress.get('required_local_sovereign_coverage_pct', 0.0):.2f}  \n"
        f"**Observed local-sovereign no-egress coverage (%):** {no_egress.get('observed_local_sovereign_coverage_pct', 0.0):.2f}  \n"
        f"**Max no-egress violations:** {no_egress.get('max_no_egress_violations', 0)}  \n"
        f"**Observed no-egress violations:** {no_egress.get('observed_no_egress_violations', 0)}  \n"
        f"**No-egress checks executed:** {no_egress.get('checks_executed', 0)}  \n"
        f"**No-egress check:** {no_egress.get('within_threshold')}  \n"
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
            _fail("URK Stage A report artifacts missing; run generator")
        if OUT_JSON.read_text(encoding="utf-8") != out_json:
            _fail("URK Stage A JSON report out of date")
        if OUT_MD.read_text(encoding="utf-8") != out_md:
            _fail("URK Stage A markdown report out of date")
        print("OK: URK Stage A trigger/privacy/no-egress report is in sync.")
        return 0

    OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
    OUT_MD.parent.mkdir(parents=True, exist_ok=True)
    OUT_JSON.write_text(out_json, encoding="utf-8")
    OUT_MD.write_text(out_md, encoding="utf-8")
    print(f"Updated {OUT_JSON} and {OUT_MD}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
