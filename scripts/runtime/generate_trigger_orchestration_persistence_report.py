#!/usr/bin/env python3
"""Generate/check trigger + orchestration persistence hardening report."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import sys
from pathlib import Path

CONFIG_PATH = Path("configs/runtime/trigger_orchestration_persistence_hardening_controls.json")
OUT_JSON = Path(
    "docs/plans/methodology/MASTER_PLAN_TRIGGER_ORCHESTRATION_PERSISTENCE_REPORT.json"
)
OUT_MD = Path(
    "docs/plans/methodology/MASTER_PLAN_TRIGGER_ORCHESTRATION_PERSISTENCE_REPORT.md"
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

    trig = cfg.get("trigger_reliability")
    if not isinstance(trig, dict):
        _fail("trigger_reliability must be object")
    max_drop = _require_non_negative_number(
        trig.get("max_dropped_trigger_rate_pct"),
        "trigger_reliability.max_dropped_trigger_rate_pct",
    )
    observed_drop = _require_non_negative_number(
        trig.get("observed_dropped_trigger_rate_pct"),
        "trigger_reliability.observed_dropped_trigger_rate_pct",
    )
    max_dup = _require_non_negative_number(
        trig.get("max_duplicate_trigger_rate_pct"),
        "trigger_reliability.max_duplicate_trigger_rate_pct",
    )
    observed_dup = _require_non_negative_number(
        trig.get("observed_duplicate_trigger_rate_pct"),
        "trigger_reliability.observed_duplicate_trigger_rate_pct",
    )
    triggers_evaluated = _require_positive_int(
        trig.get("triggers_evaluated"),
        "trigger_reliability.triggers_evaluated",
    )

    persistence = cfg.get("persistence_recovery")
    if not isinstance(persistence, dict):
        _fail("persistence_recovery must be object")
    idempotency_coverage = _require_non_negative_number(
        persistence.get("idempotency_key_coverage_pct"),
        "persistence_recovery.idempotency_key_coverage_pct",
    )
    required_idempotency_coverage = _require_non_negative_number(
        persistence.get("required_idempotency_key_coverage_pct"),
        "persistence_recovery.required_idempotency_key_coverage_pct",
    )
    replay_passed = persistence.get("replay_on_restart_passed") is True
    unrecovered_records = _require_non_negative_number(
        persistence.get("unrecovered_state_records"),
        "persistence_recovery.unrecovered_state_records",
    )
    persistence_checks = _require_positive_int(
        persistence.get("persistence_checks_executed"),
        "persistence_recovery.persistence_checks_executed",
    )

    latency = cfg.get("latency_slo")
    if not isinstance(latency, dict):
        _fail("latency_slo must be object")
    max_p95_latency = _require_non_negative_number(
        latency.get("max_p95_trigger_to_action_latency_ms"),
        "latency_slo.max_p95_trigger_to_action_latency_ms",
    )
    observed_p95_latency = _require_non_negative_number(
        latency.get("observed_p95_trigger_to_action_latency_ms"),
        "latency_slo.observed_p95_trigger_to_action_latency_ms",
    )
    latency_samples = _require_positive_int(
        latency.get("samples"),
        "latency_slo.samples",
    )

    reliability_ok = observed_drop <= max_drop and observed_dup <= max_dup
    persistence_ok = (
        idempotency_coverage >= required_idempotency_coverage
        and replay_passed
        and unrecovered_records == 0
    )
    latency_ok = observed_p95_latency <= max_p95_latency

    errors: list[str] = []
    if not reliability_ok:
        errors.append("trigger dropped/duplicate rate threshold failed")
    if not persistence_ok:
        errors.append("persistence idempotency/replay recovery checks failed")
    if not latency_ok:
        errors.append("trigger-to-action latency threshold failed")

    verdict = "PASS" if reliability_ok and persistence_ok and latency_ok and not errors else "FAIL"

    return {
        "version": "v1",
        "source": str(CONFIG_PATH),
        "generated_at": generated_at.replace(microsecond=0).isoformat().replace("+00:00", "Z"),
        "trigger_reliability": {
            "max_dropped_trigger_rate_pct": max_drop,
            "observed_dropped_trigger_rate_pct": observed_drop,
            "max_duplicate_trigger_rate_pct": max_dup,
            "observed_duplicate_trigger_rate_pct": observed_dup,
            "triggers_evaluated": triggers_evaluated,
            "within_threshold": reliability_ok,
        },
        "persistence_recovery": {
            "idempotency_key_coverage_pct": idempotency_coverage,
            "required_idempotency_key_coverage_pct": required_idempotency_coverage,
            "replay_on_restart_passed": replay_passed,
            "unrecovered_state_records": int(unrecovered_records),
            "persistence_checks_executed": persistence_checks,
            "within_threshold": persistence_ok,
        },
        "latency_slo": {
            "max_p95_trigger_to_action_latency_ms": max_p95_latency,
            "observed_p95_trigger_to_action_latency_ms": observed_p95_latency,
            "samples": latency_samples,
            "within_threshold": latency_ok,
        },
        "errors": errors,
        "verdict": verdict,
    }


def _render_md(summary: dict) -> str:
    trig = summary.get("trigger_reliability") or {}
    persistence = summary.get("persistence_recovery") or {}
    latency = summary.get("latency_slo") or {}

    return (
        "# Trigger/Orchestration Persistence Report\n\n"
        f"**Source config:** `{summary.get('source')}`  \n"
        f"**Generated at:** {summary.get('generated_at')}  \n"
        f"**Max dropped-trigger rate (%):** {trig.get('max_dropped_trigger_rate_pct', 0.0):.3f}  \n"
        f"**Observed dropped-trigger rate (%):** {trig.get('observed_dropped_trigger_rate_pct', 0.0):.3f}  \n"
        f"**Max duplicate-trigger rate (%):** {trig.get('max_duplicate_trigger_rate_pct', 0.0):.3f}  \n"
        f"**Observed duplicate-trigger rate (%):** {trig.get('observed_duplicate_trigger_rate_pct', 0.0):.3f}  \n"
        f"**Triggers evaluated:** {trig.get('triggers_evaluated', 0)}  \n"
        f"**Reliability check:** {trig.get('within_threshold')}  \n"
        f"**Idempotency coverage (%):** {persistence.get('idempotency_key_coverage_pct', 0.0):.2f}  \n"
        f"**Required idempotency coverage (%):** {persistence.get('required_idempotency_key_coverage_pct', 0.0):.2f}  \n"
        f"**Replay on restart passed:** {persistence.get('replay_on_restart_passed')}  \n"
        f"**Unrecovered state records:** {persistence.get('unrecovered_state_records', 0)}  \n"
        f"**Persistence checks executed:** {persistence.get('persistence_checks_executed', 0)}  \n"
        f"**Persistence check:** {persistence.get('within_threshold')}  \n"
        f"**Max p95 trigger-to-action latency (ms):** {latency.get('max_p95_trigger_to_action_latency_ms', 0.0):.2f}  \n"
        f"**Observed p95 trigger-to-action latency (ms):** {latency.get('observed_p95_trigger_to_action_latency_ms', 0.0):.2f}  \n"
        f"**Latency samples:** {latency.get('samples', 0)}  \n"
        f"**Latency check:** {latency.get('within_threshold')}  \n"
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
            _fail("trigger/orchestration persistence report artifacts missing; run generator")
        if OUT_JSON.read_text(encoding="utf-8") != out_json:
            _fail("trigger/orchestration persistence JSON report out of date")
        if OUT_MD.read_text(encoding="utf-8") != out_md:
            _fail("trigger/orchestration persistence markdown report out of date")
        print("OK: trigger/orchestration persistence report is in sync.")
        return 0

    OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
    OUT_MD.parent.mkdir(parents=True, exist_ok=True)
    OUT_JSON.write_text(out_json, encoding="utf-8")
    OUT_MD.write_text(out_md, encoding="utf-8")
    print(f"Updated {OUT_JSON} and {OUT_MD}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
