#!/usr/bin/env python3
"""Generate/check URK Stage D expert runtime replication report."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import sys
from pathlib import Path

CONFIG_PATH = Path("configs/runtime/urk_stage_d_expert_runtime_replication_controls.json")
OUT_JSON = Path(
    "docs/plans/methodology/MASTER_PLAN_URK_STAGE_D_EXPERT_RUNTIME_REPLICATION_REPORT.json"
)
OUT_MD = Path(
    "docs/plans/methodology/MASTER_PLAN_URK_STAGE_D_EXPERT_RUNTIME_REPLICATION_REPORT.md"
)


def _fail(msg: str) -> None:
    print(f"ERROR: {msg}", file=sys.stderr)
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
    window = cfg.get("evaluation_window")
    if not isinstance(window, dict):
        _fail("evaluation_window must be object")
    window_start = _parse_ts(window.get("start"), "evaluation_window.start")
    window_end = _parse_ts(window.get("end"), "evaluation_window.end")
    if window_end < window_start:
        _fail("evaluation_window.end must be >= evaluation_window.start")

    pipeline = cfg.get("runtime_request_pipeline")
    if not isinstance(pipeline, dict):
        _fail("runtime_request_pipeline must be object")
    required_pipeline = _require_non_negative_number(
        pipeline.get("required_pipeline_coverage_pct"),
        "runtime_request_pipeline.required_pipeline_coverage_pct",
    )
    observed_pipeline = _require_non_negative_number(
        pipeline.get("observed_pipeline_coverage_pct"),
        "runtime_request_pipeline.observed_pipeline_coverage_pct",
    )
    required_policy_gate = _require_non_negative_number(
        pipeline.get("required_expertise_policy_gate_coverage_pct"),
        "runtime_request_pipeline.required_expertise_policy_gate_coverage_pct",
    )
    observed_policy_gate = _require_non_negative_number(
        pipeline.get("observed_expertise_policy_gate_coverage_pct"),
        "runtime_request_pipeline.observed_expertise_policy_gate_coverage_pct",
    )
    requests_evaluated = _require_positive_int(
        pipeline.get("requests_evaluated"),
        "runtime_request_pipeline.requests_evaluated",
    )

    lineage = cfg.get("lineage_and_provenance")
    if not isinstance(lineage, dict):
        _fail("lineage_and_provenance must be object")
    required_lineage = _require_non_negative_number(
        lineage.get("required_lineage_coverage_pct"),
        "lineage_and_provenance.required_lineage_coverage_pct",
    )
    observed_lineage = _require_non_negative_number(
        lineage.get("observed_lineage_coverage_pct"),
        "lineage_and_provenance.observed_lineage_coverage_pct",
    )
    required_provenance = _require_non_negative_number(
        lineage.get("required_provenance_tag_coverage_pct"),
        "lineage_and_provenance.required_provenance_tag_coverage_pct",
    )
    observed_provenance = _require_non_negative_number(
        lineage.get("observed_provenance_tag_coverage_pct"),
        "lineage_and_provenance.observed_provenance_tag_coverage_pct",
    )
    lineage_checks = _require_positive_int(
        lineage.get("checks_executed"),
        "lineage_and_provenance.checks_executed",
    )

    safety = cfg.get("commit_safety")
    if not isinstance(safety, dict):
        _fail("commit_safety must be object")
    max_unverified = _require_non_negative_int(
        safety.get("max_unverified_expert_commits"),
        "commit_safety.max_unverified_expert_commits",
    )
    observed_unverified = _require_non_negative_int(
        safety.get("observed_unverified_expert_commits"),
        "commit_safety.observed_unverified_expert_commits",
    )
    required_review = _require_non_negative_number(
        safety.get("required_high_impact_review_coverage_pct"),
        "commit_safety.required_high_impact_review_coverage_pct",
    )
    observed_review = _require_non_negative_number(
        safety.get("observed_high_impact_review_coverage_pct"),
        "commit_safety.observed_high_impact_review_coverage_pct",
    )
    safety_checks = _require_positive_int(
        safety.get("checks_executed"),
        "commit_safety.checks_executed",
    )

    pipeline_ok = observed_pipeline >= required_pipeline and observed_policy_gate >= required_policy_gate
    lineage_ok = observed_lineage >= required_lineage and observed_provenance >= required_provenance
    safety_ok = observed_unverified <= max_unverified and observed_review >= required_review

    errors: list[str] = []
    if not pipeline_ok:
        errors.append("runtime pipeline/expertise policy gate threshold failed")
    if not lineage_ok:
        errors.append("lineage/provenance threshold failed")
    if not safety_ok:
        errors.append("expert commit safety threshold failed")

    verdict = "PASS" if not errors else "FAIL"

    return {
        "version": "v1",
        "source": str(CONFIG_PATH),
        "generated_at": generated_at.replace(microsecond=0).isoformat().replace("+00:00", "Z"),
        "evaluation_window": {
            "start": window_start.replace(microsecond=0).isoformat().replace("+00:00", "Z"),
            "end": window_end.replace(microsecond=0).isoformat().replace("+00:00", "Z"),
        },
        "runtime_request_pipeline": {
            "required_pipeline_coverage_pct": required_pipeline,
            "observed_pipeline_coverage_pct": observed_pipeline,
            "required_expertise_policy_gate_coverage_pct": required_policy_gate,
            "observed_expertise_policy_gate_coverage_pct": observed_policy_gate,
            "requests_evaluated": requests_evaluated,
            "within_threshold": pipeline_ok,
        },
        "lineage_and_provenance": {
            "required_lineage_coverage_pct": required_lineage,
            "observed_lineage_coverage_pct": observed_lineage,
            "required_provenance_tag_coverage_pct": required_provenance,
            "observed_provenance_tag_coverage_pct": observed_provenance,
            "checks_executed": lineage_checks,
            "within_threshold": lineage_ok,
        },
        "commit_safety": {
            "max_unverified_expert_commits": max_unverified,
            "observed_unverified_expert_commits": observed_unverified,
            "required_high_impact_review_coverage_pct": required_review,
            "observed_high_impact_review_coverage_pct": observed_review,
            "checks_executed": safety_checks,
            "within_threshold": safety_ok,
        },
        "errors": errors,
        "verdict": verdict,
    }


def _render_md(summary: dict) -> str:
    pipeline = summary.get("runtime_request_pipeline") or {}
    lineage = summary.get("lineage_and_provenance") or {}
    safety = summary.get("commit_safety") or {}
    window = summary.get("evaluation_window") or {}

    return (
        "# URK Stage D Expert Runtime Replication Report\n\n"
        f"**Source config:** `{summary.get('source')}`  \n"
        f"**Generated at:** {summary.get('generated_at')}  \n"
        f"**Evaluation window:** {window.get('start')} -> {window.get('end')}  \n"
        f"**Runtime pipeline check:** {pipeline.get('within_threshold')}  \n"
        f"**Lineage/provenance check:** {lineage.get('within_threshold')}  \n"
        f"**Commit safety check:** {safety.get('within_threshold')}  \n"
        f"**Verdict:** {summary.get('verdict')}\n\n"
        "## Validation Errors\n\n"
        + ("- None\n" if not summary.get("errors") else "\n".join(f"- {e}" for e in summary.get("errors", [])) + "\n")
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
            _fail("URK Stage D expert report artifacts missing; run generator")
        if OUT_JSON.read_text(encoding="utf-8") != out_json:
            _fail("URK Stage D expert JSON report out of date")
        if OUT_MD.read_text(encoding="utf-8") != out_md:
            _fail("URK Stage D expert markdown report out of date")
        print("OK: URK Stage D expert runtime replication report is in sync.")
        return 0

    OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
    OUT_MD.parent.mkdir(parents=True, exist_ok=True)
    OUT_JSON.write_text(out_json, encoding="utf-8")
    OUT_MD.write_text(out_md, encoding="utf-8")
    print(f"Updated {OUT_JSON} and {OUT_MD}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
