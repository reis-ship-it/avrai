#!/usr/bin/env python3
"""Generate/check URK Stage E cross-runtime conformance report."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import sys
from pathlib import Path

CONFIG_PATH = Path("configs/runtime/urk_stage_e_cross_runtime_conformance_controls.json")
OUT_JSON = Path(
    "docs/plans/methodology/MASTER_PLAN_URK_STAGE_E_CROSS_RUNTIME_CONFORMANCE_REPORT.json"
)
OUT_MD = Path(
    "docs/plans/methodology/MASTER_PLAN_URK_STAGE_E_CROSS_RUNTIME_CONFORMANCE_REPORT.md"
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

    runtime_set = cfg.get("runtime_set")
    if not isinstance(runtime_set, dict):
        _fail("runtime_set must be object")
    required_runtime_count = _require_positive_int(
        runtime_set.get("required_runtime_count"),
        "runtime_set.required_runtime_count",
    )
    observed_runtime_count = _require_non_negative_int(
        runtime_set.get("observed_runtime_count"),
        "runtime_set.observed_runtime_count",
    )
    runtimes = runtime_set.get("runtimes")
    if not isinstance(runtimes, list) or not all(isinstance(v, str) for v in runtimes):
        _fail("runtime_set.runtimes must be a list of strings")

    invariants = cfg.get("invariant_conformance")
    if not isinstance(invariants, dict):
        _fail("invariant_conformance must be object")
    required_contract_cov = _require_non_negative_number(
        invariants.get("required_contract_coverage_pct"),
        "invariant_conformance.required_contract_coverage_pct",
    )
    observed_contract_cov = _require_non_negative_number(
        invariants.get("observed_contract_coverage_pct"),
        "invariant_conformance.observed_contract_coverage_pct",
    )
    required_replay = _require_non_negative_number(
        invariants.get("required_replay_determinism_pct"),
        "invariant_conformance.required_replay_determinism_pct",
    )
    observed_replay = _require_non_negative_number(
        invariants.get("observed_replay_determinism_pct"),
        "invariant_conformance.observed_replay_determinism_pct",
    )
    max_divergence = _require_non_negative_int(
        invariants.get("max_policy_divergence_events"),
        "invariant_conformance.max_policy_divergence_events",
    )
    observed_divergence = _require_non_negative_int(
        invariants.get("observed_policy_divergence_events"),
        "invariant_conformance.observed_policy_divergence_events",
    )
    checks_executed = _require_positive_int(
        invariants.get("checks_executed"),
        "invariant_conformance.checks_executed",
    )

    runtime_ok = observed_runtime_count >= required_runtime_count
    invariant_ok = (
        observed_contract_cov >= required_contract_cov
        and observed_replay >= required_replay
        and observed_divergence <= max_divergence
    )

    errors: list[str] = []
    if not runtime_ok:
        errors.append("runtime set count below threshold")
    if observed_contract_cov < required_contract_cov:
        errors.append("contract coverage below threshold")
    if observed_replay < required_replay:
        errors.append("replay determinism below threshold")
    if observed_divergence > max_divergence:
        errors.append("policy divergence events above threshold")

    verdict = "PASS" if not errors else "FAIL"

    return {
        "version": "v1",
        "source": str(CONFIG_PATH),
        "generated_at": generated_at.replace(microsecond=0).isoformat().replace("+00:00", "Z"),
        "evaluation_window": {
            "start": window_start.replace(microsecond=0).isoformat().replace("+00:00", "Z"),
            "end": window_end.replace(microsecond=0).isoformat().replace("+00:00", "Z"),
        },
        "runtime_set": {
            "required_runtime_count": required_runtime_count,
            "observed_runtime_count": observed_runtime_count,
            "runtimes": runtimes,
            "within_threshold": runtime_ok,
        },
        "invariant_conformance": {
            "required_contract_coverage_pct": required_contract_cov,
            "observed_contract_coverage_pct": observed_contract_cov,
            "required_replay_determinism_pct": required_replay,
            "observed_replay_determinism_pct": observed_replay,
            "max_policy_divergence_events": max_divergence,
            "observed_policy_divergence_events": observed_divergence,
            "checks_executed": checks_executed,
            "within_threshold": invariant_ok,
        },
        "errors": errors,
        "verdict": verdict,
    }


def _render_md(summary: dict) -> str:
    runtime_set = summary.get("runtime_set") or {}
    invariants = summary.get("invariant_conformance") or {}
    window = summary.get("evaluation_window") or {}

    runtimes = runtime_set.get("runtimes", [])
    runtime_list = ", ".join(str(v) for v in runtimes)

    return (
        "# URK Stage E Cross Runtime Conformance Report\n\n"
        f"**Source config:** `{summary.get('source')}`  \n"
        f"**Generated at:** {summary.get('generated_at')}  \n"
        f"**Evaluation window:** {window.get('start')} -> {window.get('end')}  \n"
        f"**Runtimes covered:** {runtime_list}  \n"
        f"**Runtime-set check:** {runtime_set.get('within_threshold')}  \n"
        f"**Invariant check:** {invariants.get('within_threshold')}  \n"
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
            _fail("URK Stage E report artifacts missing; run generator")
        if OUT_JSON.read_text(encoding="utf-8") != out_json:
            _fail("URK Stage E JSON report out of date")
        if OUT_MD.read_text(encoding="utf-8") != out_md:
            _fail("URK Stage E markdown report out of date")
        print("OK: URK Stage E cross-runtime conformance report is in sync.")
        return 0

    OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
    OUT_MD.parent.mkdir(parents=True, exist_ok=True)
    OUT_JSON.write_text(out_json, encoding="utf-8")
    OUT_MD.write_text(out_md, encoding="utf-8")
    print(f"Updated {OUT_JSON} and {OUT_MD}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
