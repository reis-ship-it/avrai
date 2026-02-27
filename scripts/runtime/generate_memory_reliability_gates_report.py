#!/usr/bin/env python3
"""Generate/check memory reliability gates report."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import sys
from pathlib import Path

CONFIG_PATH = Path("configs/runtime/memory_reliability_gates.json")
OUT_JSON = Path("docs/plans/methodology/MASTER_PLAN_MEMORY_RELIABILITY_GATES_REPORT.json")
OUT_MD = Path("docs/plans/methodology/MASTER_PLAN_MEMORY_RELIABILITY_GATES_REPORT.md")


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


def _require_non_negative_number(value: object, field_name: str) -> float:
    if not isinstance(value, (int, float)) or value < 0:
        _fail(f"{field_name} must be non-negative number")
    return float(value)


def _require_positive_int(value: object, field_name: str) -> int:
    if not isinstance(value, int) or value <= 0:
        _fail(f"{field_name} must be positive integer")
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

    schema = cfg.get("schema_consistency")
    if not isinstance(schema, dict):
        _fail("schema_consistency must be object")
    schema_total = _require_positive_int(schema.get("total_records"), "schema_consistency.total_records")
    schema_missing = _require_non_negative_number(
        schema.get("records_with_missing_required_fields"),
        "schema_consistency.records_with_missing_required_fields",
    )
    schema_max_pct = _require_non_negative_number(
        schema.get("max_missing_field_rate_pct"),
        "schema_consistency.max_missing_field_rate_pct",
    )
    if schema_missing > schema_total:
        _fail("schema_consistency.records_with_missing_required_fields cannot exceed total_records")

    dedupe = cfg.get("dedupe")
    if not isinstance(dedupe, dict):
        _fail("dedupe must be object")
    input_records = _require_positive_int(dedupe.get("input_records"), "dedupe.input_records")
    unique_records = _require_positive_int(dedupe.get("unique_records"), "dedupe.unique_records")
    duplicate_records = _require_non_negative_number(dedupe.get("duplicate_records"), "dedupe.duplicate_records")
    dedupe_max_pct = _require_non_negative_number(
        dedupe.get("max_duplicate_rate_pct"),
        "dedupe.max_duplicate_rate_pct",
    )
    if unique_records > input_records:
        _fail("dedupe.unique_records cannot exceed input_records")
    if abs((input_records - unique_records) - duplicate_records) > 1e-9:
        _fail("dedupe counts must satisfy duplicate_records = input_records - unique_records")

    replay = cfg.get("replay_validation")
    if not isinstance(replay, dict):
        _fail("replay_validation must be object")
    scenarios_tested = _require_positive_int(
        replay.get("scenarios_tested"),
        "replay_validation.scenarios_tested",
    )
    scenarios_passed = _require_non_negative_number(
        replay.get("scenarios_passed"),
        "replay_validation.scenarios_passed",
    )
    max_allowed_failures = _require_non_negative_number(
        replay.get("max_allowed_failures"),
        "replay_validation.max_allowed_failures",
    )
    deterministic_hash_match = replay.get("deterministic_hash_match") is True

    if scenarios_passed > scenarios_tested:
        _fail("replay_validation.scenarios_passed cannot exceed scenarios_tested")

    schema_missing_rate = (schema_missing / float(schema_total)) * 100.0
    schema_ok = schema_missing_rate <= schema_max_pct

    observed_duplicate_rate = (duplicate_records / float(input_records)) * 100.0
    dedupe_ok = observed_duplicate_rate <= dedupe_max_pct

    replay_failures = float(scenarios_tested) - float(scenarios_passed)
    replay_ok = replay_failures <= max_allowed_failures and deterministic_hash_match

    errors: list[str] = []
    if not schema_ok:
        errors.append("schema consistency missing-field rate exceeded threshold")
    if not dedupe_ok:
        errors.append("dedupe duplicate-rate exceeded threshold")
    if replay_failures > max_allowed_failures:
        errors.append("replay scenario failures exceeded max_allowed_failures")
    if not deterministic_hash_match:
        errors.append("replay deterministic hash mismatch detected")

    verdict = "PASS" if schema_ok and dedupe_ok and replay_ok and not errors else "FAIL"

    return {
        "version": "v1",
        "source": str(CONFIG_PATH),
        "generated_at": generated_at.replace(microsecond=0).isoformat().replace("+00:00", "Z"),
        "schema_consistency": {
            "total_records": schema_total,
            "records_with_missing_required_fields": int(schema_missing),
            "missing_field_rate_pct": round(schema_missing_rate, 4),
            "max_missing_field_rate_pct": float(schema_max_pct),
            "within_threshold": schema_ok,
        },
        "dedupe": {
            "input_records": input_records,
            "unique_records": unique_records,
            "duplicate_records": int(duplicate_records),
            "observed_duplicate_rate_pct": round(observed_duplicate_rate, 4),
            "max_duplicate_rate_pct": float(dedupe_max_pct),
            "within_threshold": dedupe_ok,
        },
        "replay_validation": {
            "scenarios_tested": scenarios_tested,
            "scenarios_passed": int(scenarios_passed),
            "scenario_failures": int(replay_failures),
            "max_allowed_failures": int(max_allowed_failures),
            "deterministic_hash_match": deterministic_hash_match,
            "within_threshold": replay_ok,
        },
        "errors": errors,
        "verdict": verdict,
    }


def _render_md(summary: dict) -> str:
    schema = summary.get("schema_consistency") or {}
    dedupe = summary.get("dedupe") or {}
    replay = summary.get("replay_validation") or {}

    return (
        "# Memory Reliability Gates Report\n\n"
        f"**Source config:** `{summary.get('source')}`  \n"
        f"**Generated at:** {summary.get('generated_at')}  \n"
        f"**Schema total records:** {schema.get('total_records', 0)}  \n"
        f"**Schema missing required fields:** {schema.get('records_with_missing_required_fields', 0)}  \n"
        f"**Schema missing rate (%):** {schema.get('missing_field_rate_pct', 0.0):.4f}  \n"
        f"**Schema max missing rate (%):** {schema.get('max_missing_field_rate_pct', 0.0):.4f}  \n"
        f"**Schema threshold check:** {schema.get('within_threshold')}  \n"
        f"**Dedupe input records:** {dedupe.get('input_records', 0)}  \n"
        f"**Dedupe unique records:** {dedupe.get('unique_records', 0)}  \n"
        f"**Dedupe duplicate records:** {dedupe.get('duplicate_records', 0)}  \n"
        f"**Observed duplicate rate (%):** {dedupe.get('observed_duplicate_rate_pct', 0.0):.4f}  \n"
        f"**Max duplicate rate (%):** {dedupe.get('max_duplicate_rate_pct', 0.0):.4f}  \n"
        f"**Dedupe threshold check:** {dedupe.get('within_threshold')}  \n"
        f"**Replay scenarios tested:** {replay.get('scenarios_tested', 0)}  \n"
        f"**Replay scenarios passed:** {replay.get('scenarios_passed', 0)}  \n"
        f"**Replay scenario failures:** {replay.get('scenario_failures', 0)}  \n"
        f"**Replay max allowed failures:** {replay.get('max_allowed_failures', 0)}  \n"
        f"**Replay deterministic hash match:** {replay.get('deterministic_hash_match')}  \n"
        f"**Replay threshold check:** {replay.get('within_threshold')}  \n"
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
            _fail("memory reliability report artifacts missing; run generator")
        if OUT_JSON.read_text(encoding="utf-8") != out_json:
            _fail("memory reliability JSON report out of date")
        if OUT_MD.read_text(encoding="utf-8") != out_md:
            _fail("memory reliability markdown report out of date")
        print("OK: memory reliability gates report is in sync.")
        return 0

    OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
    OUT_MD.parent.mkdir(parents=True, exist_ok=True)
    OUT_JSON.write_text(out_json, encoding="utf-8")
    OUT_MD.write_text(out_md, encoding="utf-8")
    print(f"Updated {OUT_JSON} and {OUT_MD}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
