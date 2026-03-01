#!/usr/bin/env python3
"""Generate/check energy function safety + regression governance report."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import sys
from pathlib import Path

CONFIG_PATH = Path("configs/runtime/energy_function_safety_regression_controls.json")
OUT_JSON = Path("docs/plans/methodology/MASTER_PLAN_ENERGY_FUNCTION_SAFETY_REGRESSION_REPORT.json")
OUT_MD = Path("docs/plans/methodology/MASTER_PLAN_ENERGY_FUNCTION_SAFETY_REGRESSION_REPORT.md")


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

    safety = cfg.get("safety_bounds")
    if not isinstance(safety, dict):
        _fail("safety_bounds must be object")
    max_violation_rate = _require_non_negative_number(
        safety.get("max_policy_violation_rate_pct"),
        "safety_bounds.max_policy_violation_rate_pct",
    )
    observed_violation_rate = _require_non_negative_number(
        safety.get("observed_policy_violation_rate_pct"),
        "safety_bounds.observed_policy_violation_rate_pct",
    )
    evaluated_decisions = _require_positive_int(
        safety.get("evaluated_decisions"),
        "safety_bounds.evaluated_decisions",
    )
    hard_bounds_passed = safety.get("hard_bounds_passed") is True

    regression = cfg.get("asymmetric_loss_regression")
    if not isinstance(regression, dict):
        _fail("asymmetric_loss_regression must be object")
    max_regression_delta = _require_non_negative_number(
        regression.get("max_regression_delta_pct"),
        "asymmetric_loss_regression.max_regression_delta_pct",
    )
    observed_regression_delta = _require_non_negative_number(
        regression.get("observed_regression_delta_pct"),
        "asymmetric_loss_regression.observed_regression_delta_pct",
    )
    holdout_samples = _require_positive_int(
        regression.get("holdout_samples"),
        "asymmetric_loss_regression.holdout_samples",
    )

    weights = cfg.get("loss_weight_policy")
    if not isinstance(weights, dict):
        _fail("loss_weight_policy must be object")
    negative_weight = _require_non_negative_number(
        weights.get("negative_outcome_weight"),
        "loss_weight_policy.negative_outcome_weight",
    )
    positive_weight = _require_non_negative_number(
        weights.get("positive_outcome_weight"),
        "loss_weight_policy.positive_outcome_weight",
    )
    model_failure_weight = _require_non_negative_number(
        weights.get("model_failure_weight"),
        "loss_weight_policy.model_failure_weight",
    )

    guardrails = cfg.get("promotion_guardrails")
    if not isinstance(guardrails, dict):
        _fail("promotion_guardrails must be object")
    fail_closed_enabled = guardrails.get("fail_closed_enabled") is True
    rollback_readiness_passed = guardrails.get("rollback_readiness_passed") is True
    guardrail_audits = _require_positive_int(
        guardrails.get("guardrail_audits"),
        "promotion_guardrails.guardrail_audits",
    )

    safety_ok = observed_violation_rate <= max_violation_rate and hard_bounds_passed
    regression_ok = observed_regression_delta <= max_regression_delta
    weights_ok = (
        positive_weight > 0
        and negative_weight >= 2.0
        and model_failure_weight >= 3.0
        and negative_weight >= positive_weight
        and model_failure_weight >= negative_weight
    )
    guardrails_ok = fail_closed_enabled and rollback_readiness_passed

    errors: list[str] = []
    if not safety_ok:
        errors.append("safety bounds failed or violation rate exceeded threshold")
    if not regression_ok:
        errors.append("asymmetric-loss regression exceeded threshold")
    if not weights_ok:
        errors.append("loss weight policy does not meet asymmetric-loss requirements")
    if not guardrails_ok:
        errors.append("promotion guardrails fail-closed/rollback readiness check failed")

    verdict = "PASS" if safety_ok and regression_ok and weights_ok and guardrails_ok and not errors else "FAIL"

    return {
        "version": "v1",
        "source": str(CONFIG_PATH),
        "generated_at": generated_at.replace(microsecond=0).isoformat().replace("+00:00", "Z"),
        "safety_bounds": {
            "max_policy_violation_rate_pct": max_violation_rate,
            "observed_policy_violation_rate_pct": observed_violation_rate,
            "evaluated_decisions": evaluated_decisions,
            "hard_bounds_passed": hard_bounds_passed,
            "within_threshold": safety_ok,
        },
        "asymmetric_loss_regression": {
            "max_regression_delta_pct": max_regression_delta,
            "observed_regression_delta_pct": observed_regression_delta,
            "holdout_samples": holdout_samples,
            "within_threshold": regression_ok,
        },
        "loss_weight_policy": {
            "negative_outcome_weight": negative_weight,
            "positive_outcome_weight": positive_weight,
            "model_failure_weight": model_failure_weight,
            "within_threshold": weights_ok,
        },
        "promotion_guardrails": {
            "fail_closed_enabled": fail_closed_enabled,
            "rollback_readiness_passed": rollback_readiness_passed,
            "guardrail_audits": guardrail_audits,
            "within_threshold": guardrails_ok,
        },
        "errors": errors,
        "verdict": verdict,
    }


def _render_md(summary: dict) -> str:
    safety = summary.get("safety_bounds") or {}
    regression = summary.get("asymmetric_loss_regression") or {}
    weights = summary.get("loss_weight_policy") or {}
    guardrails = summary.get("promotion_guardrails") or {}

    return (
        "# Energy Function Safety/Regression Report\n\n"
        f"**Source config:** `{summary.get('source')}`  \n"
        f"**Generated at:** {summary.get('generated_at')}  \n"
        f"**Max policy violation rate (%):** {safety.get('max_policy_violation_rate_pct', 0.0):.2f}  \n"
        f"**Observed policy violation rate (%):** {safety.get('observed_policy_violation_rate_pct', 0.0):.2f}  \n"
        f"**Evaluated decisions:** {safety.get('evaluated_decisions', 0)}  \n"
        f"**Hard bounds passed:** {safety.get('hard_bounds_passed')}  \n"
        f"**Safety threshold check:** {safety.get('within_threshold')}  \n"
        f"**Max regression delta (%):** {regression.get('max_regression_delta_pct', 0.0):.2f}  \n"
        f"**Observed regression delta (%):** {regression.get('observed_regression_delta_pct', 0.0):.2f}  \n"
        f"**Holdout samples:** {regression.get('holdout_samples', 0)}  \n"
        f"**Regression threshold check:** {regression.get('within_threshold')}  \n"
        f"**Negative outcome weight:** {weights.get('negative_outcome_weight', 0.0):.2f}  \n"
        f"**Positive outcome weight:** {weights.get('positive_outcome_weight', 0.0):.2f}  \n"
        f"**Model failure weight:** {weights.get('model_failure_weight', 0.0):.2f}  \n"
        f"**Weight policy check:** {weights.get('within_threshold')}  \n"
        f"**Fail-closed enabled:** {guardrails.get('fail_closed_enabled')}  \n"
        f"**Rollback readiness passed:** {guardrails.get('rollback_readiness_passed')}  \n"
        f"**Guardrail audits:** {guardrails.get('guardrail_audits', 0)}  \n"
        f"**Guardrail check:** {guardrails.get('within_threshold')}  \n"
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
            _fail("energy function safety/regression report artifacts missing; run generator")
        if OUT_JSON.read_text(encoding="utf-8") != out_json:
            _fail("energy function safety/regression JSON report out of date")
        if OUT_MD.read_text(encoding="utf-8") != out_md:
            _fail("energy function safety/regression markdown report out of date")
        print("OK: energy function safety/regression report is in sync.")
        return 0

    OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
    OUT_MD.parent.mkdir(parents=True, exist_ok=True)
    OUT_JSON.write_text(out_json, encoding="utf-8")
    OUT_MD.write_text(out_md, encoding="utf-8")
    print(f"Updated {OUT_JSON} and {OUT_MD}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
