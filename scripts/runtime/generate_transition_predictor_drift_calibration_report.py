#!/usr/bin/env python3
"""Generate/check transition predictor drift + calibration report."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import sys
from pathlib import Path

CONFIG_PATH = Path("configs/runtime/transition_predictor_drift_calibration_controls.json")
OUT_JSON = Path(
    "docs/plans/methodology/MASTER_PLAN_TRANSITION_PREDICTOR_DRIFT_CALIBRATION_REPORT.json"
)
OUT_MD = Path(
    "docs/plans/methodology/MASTER_PLAN_TRANSITION_PREDICTOR_DRIFT_CALIBRATION_REPORT.md"
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

    residual = cfg.get("residual_drift")
    if not isinstance(residual, dict):
        _fail("residual_drift must be object")
    max_ema_ratio = _require_non_negative_number(
        residual.get("max_ema_ratio"),
        "residual_drift.max_ema_ratio",
    )
    observed_ema_ratio = _require_non_negative_number(
        residual.get("observed_ema_ratio"),
        "residual_drift.observed_ema_ratio",
    )
    residual_samples = _require_positive_int(
        residual.get("residual_samples"),
        "residual_drift.residual_samples",
    )
    drift_event_triggered = residual.get("drift_event_triggered") is True

    calibration = cfg.get("calibration")
    if not isinstance(calibration, dict):
        _fail("calibration must be object")
    max_ece = _require_non_negative_number(
        calibration.get("max_expected_calibration_error"),
        "calibration.max_expected_calibration_error",
    )
    observed_ece = _require_non_negative_number(
        calibration.get("observed_expected_calibration_error"),
        "calibration.observed_expected_calibration_error",
    )
    max_gap_pct = _require_non_negative_number(
        calibration.get("max_confidence_accuracy_gap_pct"),
        "calibration.max_confidence_accuracy_gap_pct",
    )
    observed_gap_pct = _require_non_negative_number(
        calibration.get("observed_confidence_accuracy_gap_pct"),
        "calibration.observed_confidence_accuracy_gap_pct",
    )
    calibration_samples = _require_positive_int(
        calibration.get("calibration_samples"),
        "calibration.calibration_samples",
    )

    divergence = cfg.get("divergence_gate")
    if not isinstance(divergence, dict):
        _fail("divergence_gate must be object")
    divergence_detected = divergence.get("confidence_accuracy_divergence_detected") is True
    auto_throttle_triggered = divergence.get("auto_throttle_triggered") is True
    verification_escalation_triggered = (
        divergence.get("verification_prompt_escalation_triggered") is True
    )

    residual_ok = observed_ema_ratio <= max_ema_ratio and not drift_event_triggered
    calibration_ok = observed_ece <= max_ece and observed_gap_pct <= max_gap_pct
    divergence_ok = (
        not divergence_detected
        and not auto_throttle_triggered
        and not verification_escalation_triggered
    )

    errors: list[str] = []
    if not residual_ok:
        errors.append("residual drift threshold exceeded or drift event triggered")
    if not calibration_ok:
        errors.append("calibration error/gap exceeded threshold")
    if not divergence_ok:
        errors.append("confidence-vs-outcome divergence gate triggered")

    verdict = "PASS" if residual_ok and calibration_ok and divergence_ok and not errors else "FAIL"

    return {
        "version": "v1",
        "source": str(CONFIG_PATH),
        "generated_at": generated_at.replace(microsecond=0).isoformat().replace("+00:00", "Z"),
        "residual_drift": {
            "max_ema_ratio": max_ema_ratio,
            "observed_ema_ratio": observed_ema_ratio,
            "residual_samples": residual_samples,
            "drift_event_triggered": drift_event_triggered,
            "within_threshold": residual_ok,
        },
        "calibration": {
            "max_expected_calibration_error": max_ece,
            "observed_expected_calibration_error": observed_ece,
            "max_confidence_accuracy_gap_pct": max_gap_pct,
            "observed_confidence_accuracy_gap_pct": observed_gap_pct,
            "calibration_samples": calibration_samples,
            "within_threshold": calibration_ok,
        },
        "divergence_gate": {
            "confidence_accuracy_divergence_detected": divergence_detected,
            "auto_throttle_triggered": auto_throttle_triggered,
            "verification_prompt_escalation_triggered": verification_escalation_triggered,
            "within_threshold": divergence_ok,
        },
        "errors": errors,
        "verdict": verdict,
    }


def _render_md(summary: dict) -> str:
    residual = summary.get("residual_drift") or {}
    calibration = summary.get("calibration") or {}
    divergence = summary.get("divergence_gate") or {}

    return (
        "# Transition Predictor Drift/Calibration Report\n\n"
        f"**Source config:** `{summary.get('source')}`  \n"
        f"**Generated at:** {summary.get('generated_at')}  \n"
        f"**Max residual EMA ratio:** {residual.get('max_ema_ratio', 0.0):.2f}  \n"
        f"**Observed residual EMA ratio:** {residual.get('observed_ema_ratio', 0.0):.2f}  \n"
        f"**Residual samples:** {residual.get('residual_samples', 0)}  \n"
        f"**Drift event triggered:** {residual.get('drift_event_triggered')}  \n"
        f"**Residual threshold check:** {residual.get('within_threshold')}  \n"
        f"**Max ECE:** {calibration.get('max_expected_calibration_error', 0.0):.4f}  \n"
        f"**Observed ECE:** {calibration.get('observed_expected_calibration_error', 0.0):.4f}  \n"
        f"**Max confidence-accuracy gap (%):** {calibration.get('max_confidence_accuracy_gap_pct', 0.0):.2f}  \n"
        f"**Observed confidence-accuracy gap (%):** {calibration.get('observed_confidence_accuracy_gap_pct', 0.0):.2f}  \n"
        f"**Calibration samples:** {calibration.get('calibration_samples', 0)}  \n"
        f"**Calibration threshold check:** {calibration.get('within_threshold')}  \n"
        f"**Divergence detected:** {divergence.get('confidence_accuracy_divergence_detected')}  \n"
        f"**Auto-throttle triggered:** {divergence.get('auto_throttle_triggered')}  \n"
        f"**Verification escalation triggered:** {divergence.get('verification_prompt_escalation_triggered')}  \n"
        f"**Divergence gate check:** {divergence.get('within_threshold')}  \n"
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
            _fail("transition predictor drift/calibration report artifacts missing; run generator")
        if OUT_JSON.read_text(encoding="utf-8") != out_json:
            _fail("transition predictor drift/calibration JSON report out of date")
        if OUT_MD.read_text(encoding="utf-8") != out_md:
            _fail("transition predictor drift/calibration markdown report out of date")
        print("OK: transition predictor drift/calibration report is in sync.")
        return 0

    OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
    OUT_MD.parent.mkdir(parents=True, exist_ok=True)
    OUT_JSON.write_text(out_json, encoding="utf-8")
    OUT_MD.write_text(out_md, encoding="utf-8")
    print(f"Updated {OUT_JSON} and {OUT_MD}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
