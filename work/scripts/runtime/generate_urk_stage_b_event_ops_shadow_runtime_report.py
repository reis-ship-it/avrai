#!/usr/bin/env python3
"""Generate/check URK Stage B Event Ops shadow runtime report."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import sys
from pathlib import Path

CONFIG_PATH = Path("configs/runtime/urk_stage_b_event_ops_shadow_runtime_controls.json")
OUT_JSON = Path(
    "docs/plans/methodology/MASTER_PLAN_URK_STAGE_B_EVENT_OPS_SHADOW_RUNTIME_REPORT.json"
)
OUT_MD = Path(
    "docs/plans/methodology/MASTER_PLAN_URK_STAGE_B_EVENT_OPS_SHADOW_RUNTIME_REPORT.md"
)


def _fail(message: str) -> None:
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


def _parse_ts(raw: object, field: str) -> dt.datetime:
    text = str(raw).strip()
    if not text:
        _fail(f"{field} is required")
    if text.endswith("Z"):
        text = text[:-1] + "+00:00"
    try:
        value = dt.datetime.fromisoformat(text)
    except ValueError:
        _fail(f"invalid {field} '{raw}'")
    if value.tzinfo is None:
        value = value.replace(tzinfo=dt.timezone.utc)
    return value.astimezone(dt.timezone.utc)


def _require_non_negative_number(value: object, field: str) -> float:
    if not isinstance(value, (int, float)) or float(value) < 0:
        _fail(f"{field} must be non-negative number")
    return float(value)


def _require_non_negative_int(value: object, field: str) -> int:
    if not isinstance(value, int) or value < 0:
        _fail(f"{field} must be non-negative integer")
    return int(value)


def _require_positive_int(value: object, field: str) -> int:
    if not isinstance(value, int) or value <= 0:
        _fail(f"{field} must be positive integer")
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

    generated_at = _parse_ts(cfg.get("evaluation_at"), "evaluation_at")

    evaluation_window = cfg.get("evaluation_window")
    if not isinstance(evaluation_window, dict):
        _fail("evaluation_window must be object")
    window_start = _parse_ts(evaluation_window.get("start"), "evaluation_window.start")
    window_end = _parse_ts(evaluation_window.get("end"), "evaluation_window.end")
    if window_end < window_start:
        _fail("evaluation_window.end must be >= evaluation_window.start")

    pipeline = cfg.get("pipeline_shadow")
    if not isinstance(pipeline, dict):
        _fail("pipeline_shadow must be object")
    required_pipeline = _require_non_negative_number(
        pipeline.get("required_pipeline_coverage_pct"),
        "pipeline_shadow.required_pipeline_coverage_pct",
    )
    observed_pipeline = _require_non_negative_number(
        pipeline.get("observed_pipeline_coverage_pct"),
        "pipeline_shadow.observed_pipeline_coverage_pct",
    )
    required_decision = _require_non_negative_number(
        pipeline.get("required_decision_envelope_coverage_pct"),
        "pipeline_shadow.required_decision_envelope_coverage_pct",
    )
    observed_decision = _require_non_negative_number(
        pipeline.get("observed_decision_envelope_coverage_pct"),
        "pipeline_shadow.observed_decision_envelope_coverage_pct",
    )
    shadow_requests = _require_positive_int(
        pipeline.get("shadow_requests_evaluated"),
        "pipeline_shadow.shadow_requests_evaluated",
    )

    lineage = cfg.get("lineage_integrity")
    if not isinstance(lineage, dict):
        _fail("lineage_integrity must be object")
    required_lineage = _require_non_negative_number(
        lineage.get("required_lineage_completeness_pct"),
        "lineage_integrity.required_lineage_completeness_pct",
    )
    observed_lineage = _require_non_negative_number(
        lineage.get("observed_lineage_completeness_pct"),
        "lineage_integrity.observed_lineage_completeness_pct",
    )
    max_orphan = _require_non_negative_int(
        lineage.get("max_orphan_action_states"),
        "lineage_integrity.max_orphan_action_states",
    )
    observed_orphan = _require_non_negative_int(
        lineage.get("observed_orphan_action_states"),
        "lineage_integrity.observed_orphan_action_states",
    )
    lineage_checks = _require_positive_int(
        lineage.get("lineage_checks_executed"),
        "lineage_integrity.lineage_checks_executed",
    )

    guard = cfg.get("high_impact_commit_guard")
    if not isinstance(guard, dict):
        _fail("high_impact_commit_guard must be object")
    max_autocommits = _require_non_negative_int(
        guard.get("max_high_impact_autocommits"),
        "high_impact_commit_guard.max_high_impact_autocommits",
    )
    observed_autocommits = _require_non_negative_int(
        guard.get("observed_high_impact_autocommits"),
        "high_impact_commit_guard.observed_high_impact_autocommits",
    )
    required_shadow_block = _require_non_negative_number(
        guard.get("required_shadow_block_coverage_pct"),
        "high_impact_commit_guard.required_shadow_block_coverage_pct",
    )
    observed_shadow_block = _require_non_negative_number(
        guard.get("observed_shadow_block_coverage_pct"),
        "high_impact_commit_guard.observed_shadow_block_coverage_pct",
    )
    guard_checks = _require_positive_int(
        guard.get("guard_checks_executed"),
        "high_impact_commit_guard.guard_checks_executed",
    )

    pipeline_ok = observed_pipeline >= required_pipeline
    decision_ok = observed_decision >= required_decision
    lineage_ok = observed_lineage >= required_lineage and observed_orphan <= max_orphan
    guard_ok = (
        observed_autocommits <= max_autocommits
        and observed_shadow_block >= required_shadow_block
    )

    errors: list[str] = []
    if not pipeline_ok:
        errors.append("ingest-plan-gate-observe pipeline coverage below threshold")
    if not decision_ok:
        errors.append("decision envelope coverage below threshold")
    if not lineage_ok:
        errors.append("lineage completeness/orphan action threshold failed")
    if not guard_ok:
        errors.append("high-impact shadow commit guard threshold failed")

    verdict = "PASS" if not errors else "FAIL"

    return {
        "version": "v1",
        "source": str(CONFIG_PATH),
        "generated_at": generated_at.replace(microsecond=0).isoformat().replace("+00:00", "Z"),
        "evaluation_window": {
            "start": window_start.replace(microsecond=0).isoformat().replace("+00:00", "Z"),
            "end": window_end.replace(microsecond=0).isoformat().replace("+00:00", "Z"),
        },
        "pipeline_shadow": {
            "required_pipeline_coverage_pct": required_pipeline,
            "observed_pipeline_coverage_pct": observed_pipeline,
            "required_decision_envelope_coverage_pct": required_decision,
            "observed_decision_envelope_coverage_pct": observed_decision,
            "shadow_requests_evaluated": shadow_requests,
            "within_threshold": pipeline_ok and decision_ok,
        },
        "lineage_integrity": {
            "required_lineage_completeness_pct": required_lineage,
            "observed_lineage_completeness_pct": observed_lineage,
            "max_orphan_action_states": max_orphan,
            "observed_orphan_action_states": observed_orphan,
            "lineage_checks_executed": lineage_checks,
            "within_threshold": lineage_ok,
        },
        "high_impact_commit_guard": {
            "max_high_impact_autocommits": max_autocommits,
            "observed_high_impact_autocommits": observed_autocommits,
            "required_shadow_block_coverage_pct": required_shadow_block,
            "observed_shadow_block_coverage_pct": observed_shadow_block,
            "guard_checks_executed": guard_checks,
            "within_threshold": guard_ok,
        },
        "errors": errors,
        "verdict": verdict,
    }


def _render_md(summary: dict) -> str:
    pipeline = summary.get("pipeline_shadow") or {}
    lineage = summary.get("lineage_integrity") or {}
    guard = summary.get("high_impact_commit_guard") or {}
    window = summary.get("evaluation_window") or {}

    return (
        "# URK Stage B Event Ops Shadow Runtime Report\n\n"
        f"**Source config:** `{summary.get('source')}`  \n"
        f"**Generated at:** {summary.get('generated_at')}  \n"
        f"**Evaluation window:** {window.get('start')} -> {window.get('end')}  \n"
        f"**Required pipeline coverage (%):** {pipeline.get('required_pipeline_coverage_pct', 0.0):.2f}  \n"
        f"**Observed pipeline coverage (%):** {pipeline.get('observed_pipeline_coverage_pct', 0.0):.2f}  \n"
        f"**Required decision envelope coverage (%):** {pipeline.get('required_decision_envelope_coverage_pct', 0.0):.2f}  \n"
        f"**Observed decision envelope coverage (%):** {pipeline.get('observed_decision_envelope_coverage_pct', 0.0):.2f}  \n"
        f"**Shadow requests evaluated:** {pipeline.get('shadow_requests_evaluated', 0)}  \n"
        f"**Pipeline/decision check:** {pipeline.get('within_threshold')}  \n"
        f"**Required lineage completeness (%):** {lineage.get('required_lineage_completeness_pct', 0.0):.2f}  \n"
        f"**Observed lineage completeness (%):** {lineage.get('observed_lineage_completeness_pct', 0.0):.2f}  \n"
        f"**Max orphan action states:** {lineage.get('max_orphan_action_states', 0)}  \n"
        f"**Observed orphan action states:** {lineage.get('observed_orphan_action_states', 0)}  \n"
        f"**Lineage checks executed:** {lineage.get('lineage_checks_executed', 0)}  \n"
        f"**Lineage check:** {lineage.get('within_threshold')}  \n"
        f"**Max high-impact autocommits:** {guard.get('max_high_impact_autocommits', 0)}  \n"
        f"**Observed high-impact autocommits:** {guard.get('observed_high_impact_autocommits', 0)}  \n"
        f"**Required shadow-block coverage (%):** {guard.get('required_shadow_block_coverage_pct', 0.0):.2f}  \n"
        f"**Observed shadow-block coverage (%):** {guard.get('observed_shadow_block_coverage_pct', 0.0):.2f}  \n"
        f"**Guard checks executed:** {guard.get('guard_checks_executed', 0)}  \n"
        f"**Guard check:** {guard.get('within_threshold')}  \n"
        f"**Verdict:** {summary.get('verdict')}\n\n"
        "## Validation Errors\n\n"
        + (
            "- None\n"
            if not summary.get("errors")
            else "\n".join(f"- {error}" for error in summary.get("errors", [])) + "\n"
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
            _fail("URK Stage B report artifacts missing; run generator")
        if OUT_JSON.read_text(encoding="utf-8") != out_json:
            _fail("URK Stage B JSON report out of date")
        if OUT_MD.read_text(encoding="utf-8") != out_md:
            _fail("URK Stage B markdown report out of date")
        print("OK: URK Stage B Event Ops shadow runtime report is in sync.")
        return 0

    OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
    OUT_MD.parent.mkdir(parents=True, exist_ok=True)
    OUT_JSON.write_text(out_json, encoding="utf-8")
    OUT_MD.write_text(out_md, encoding="utf-8")
    print(f"Updated {OUT_JSON} and {OUT_MD}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
