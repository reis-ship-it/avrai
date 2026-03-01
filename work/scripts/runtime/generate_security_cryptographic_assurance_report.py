#!/usr/bin/env python3
"""Generate/check security + cryptographic assurance report."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import sys
from pathlib import Path

CONFIG_PATH = Path("configs/runtime/security_cryptographic_assurance_controls.json")
OUT_JSON = Path(
    "docs/plans/methodology/MASTER_PLAN_SECURITY_CRYPTOGRAPHIC_ASSURANCE_REPORT.json"
)
OUT_MD = Path(
    "docs/plans/methodology/MASTER_PLAN_SECURITY_CRYPTOGRAPHIC_ASSURANCE_REPORT.md"
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

    pq = cfg.get("post_quantum_hardening")
    if not isinstance(pq, dict):
        _fail("post_quantum_hardening must be object")
    required_pq = _require_non_negative_number(
        pq.get("required_critical_path_coverage_pct"),
        "post_quantum_hardening.required_critical_path_coverage_pct",
    )
    observed_pq = _require_non_negative_number(
        pq.get("observed_critical_path_coverage_pct"),
        "post_quantum_hardening.observed_critical_path_coverage_pct",
    )
    critical_paths_evaluated = _require_positive_int(
        pq.get("critical_paths_evaluated"),
        "post_quantum_hardening.critical_paths_evaluated",
    )

    attestation = cfg.get("attestation_integrity")
    if not isinstance(attestation, dict):
        _fail("attestation_integrity must be object")
    required_attestation = _require_non_negative_number(
        attestation.get("required_attested_channel_coverage_pct"),
        "attestation_integrity.required_attested_channel_coverage_pct",
    )
    observed_attestation = _require_non_negative_number(
        attestation.get("observed_attested_channel_coverage_pct"),
        "attestation_integrity.observed_attested_channel_coverage_pct",
    )
    unsigned_updates = _require_non_negative_number(
        attestation.get("unsigned_update_events_detected"),
        "attestation_integrity.unsigned_update_events_detected",
    )
    attestation_checks = _require_positive_int(
        attestation.get("attestation_checks_executed"),
        "attestation_integrity.attestation_checks_executed",
    )

    kill_switch = cfg.get("kill_switch_readiness")
    if not isinstance(kill_switch, dict):
        _fail("kill_switch_readiness must be object")
    required_drill_rate = _require_non_negative_number(
        kill_switch.get("required_kill_switch_drill_pass_rate_pct"),
        "kill_switch_readiness.required_kill_switch_drill_pass_rate_pct",
    )
    observed_drill_rate = _require_non_negative_number(
        kill_switch.get("observed_kill_switch_drill_pass_rate_pct"),
        "kill_switch_readiness.observed_kill_switch_drill_pass_rate_pct",
    )
    max_activation_latency_ms = _require_non_negative_number(
        kill_switch.get("max_kill_switch_activation_latency_ms"),
        "kill_switch_readiness.max_kill_switch_activation_latency_ms",
    )
    observed_activation_latency_ms = _require_non_negative_number(
        kill_switch.get("observed_kill_switch_activation_latency_ms"),
        "kill_switch_readiness.observed_kill_switch_activation_latency_ms",
    )
    drills_executed = _require_positive_int(
        kill_switch.get("drills_executed"),
        "kill_switch_readiness.drills_executed",
    )

    pq_ok = observed_pq >= required_pq
    attestation_ok = observed_attestation >= required_attestation and unsigned_updates == 0
    kill_switch_ok = (
        observed_drill_rate >= required_drill_rate
        and observed_activation_latency_ms <= max_activation_latency_ms
    )

    errors: list[str] = []
    if not pq_ok:
        errors.append("post-quantum hardening coverage threshold failed")
    if not attestation_ok:
        errors.append("attestation integrity threshold failed")
    if not kill_switch_ok:
        errors.append("kill-switch drill/latency threshold failed")

    verdict = "PASS" if pq_ok and attestation_ok and kill_switch_ok and not errors else "FAIL"

    return {
        "version": "v1",
        "source": str(CONFIG_PATH),
        "generated_at": generated_at.replace(microsecond=0).isoformat().replace("+00:00", "Z"),
        "post_quantum_hardening": {
            "required_critical_path_coverage_pct": required_pq,
            "observed_critical_path_coverage_pct": observed_pq,
            "critical_paths_evaluated": critical_paths_evaluated,
            "within_threshold": pq_ok,
        },
        "attestation_integrity": {
            "required_attested_channel_coverage_pct": required_attestation,
            "observed_attested_channel_coverage_pct": observed_attestation,
            "unsigned_update_events_detected": int(unsigned_updates),
            "attestation_checks_executed": attestation_checks,
            "within_threshold": attestation_ok,
        },
        "kill_switch_readiness": {
            "required_kill_switch_drill_pass_rate_pct": required_drill_rate,
            "observed_kill_switch_drill_pass_rate_pct": observed_drill_rate,
            "max_kill_switch_activation_latency_ms": max_activation_latency_ms,
            "observed_kill_switch_activation_latency_ms": observed_activation_latency_ms,
            "drills_executed": drills_executed,
            "within_threshold": kill_switch_ok,
        },
        "errors": errors,
        "verdict": verdict,
    }


def _render_md(summary: dict) -> str:
    pq = summary.get("post_quantum_hardening") or {}
    attestation = summary.get("attestation_integrity") or {}
    kill_switch = summary.get("kill_switch_readiness") or {}

    return (
        "# Security/Cryptographic Assurance Report\n\n"
        f"**Source config:** `{summary.get('source')}`  \n"
        f"**Generated at:** {summary.get('generated_at')}  \n"
        f"**Required PQ critical-path coverage (%):** {pq.get('required_critical_path_coverage_pct', 0.0):.2f}  \n"
        f"**Observed PQ critical-path coverage (%):** {pq.get('observed_critical_path_coverage_pct', 0.0):.2f}  \n"
        f"**PQ critical paths evaluated:** {pq.get('critical_paths_evaluated', 0)}  \n"
        f"**PQ threshold check:** {pq.get('within_threshold')}  \n"
        f"**Required attested-channel coverage (%):** {attestation.get('required_attested_channel_coverage_pct', 0.0):.2f}  \n"
        f"**Observed attested-channel coverage (%):** {attestation.get('observed_attested_channel_coverage_pct', 0.0):.2f}  \n"
        f"**Unsigned update events:** {attestation.get('unsigned_update_events_detected', 0)}  \n"
        f"**Attestation checks executed:** {attestation.get('attestation_checks_executed', 0)}  \n"
        f"**Attestation threshold check:** {attestation.get('within_threshold')}  \n"
        f"**Required kill-switch drill pass rate (%):** {kill_switch.get('required_kill_switch_drill_pass_rate_pct', 0.0):.2f}  \n"
        f"**Observed kill-switch drill pass rate (%):** {kill_switch.get('observed_kill_switch_drill_pass_rate_pct', 0.0):.2f}  \n"
        f"**Max kill-switch activation latency (ms):** {kill_switch.get('max_kill_switch_activation_latency_ms', 0.0):.2f}  \n"
        f"**Observed kill-switch activation latency (ms):** {kill_switch.get('observed_kill_switch_activation_latency_ms', 0.0):.2f}  \n"
        f"**Kill-switch drills executed:** {kill_switch.get('drills_executed', 0)}  \n"
        f"**Kill-switch threshold check:** {kill_switch.get('within_threshold')}  \n"
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
            _fail("security/cryptographic assurance report artifacts missing; run generator")
        if OUT_JSON.read_text(encoding="utf-8") != out_json:
            _fail("security/cryptographic assurance JSON report out of date")
        if OUT_MD.read_text(encoding="utf-8") != out_md:
            _fail("security/cryptographic assurance markdown report out of date")
        print("OK: security/cryptographic assurance report is in sync.")
        return 0

    OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
    OUT_MD.parent.mkdir(parents=True, exist_ok=True)
    OUT_JSON.write_text(out_json, encoding="utf-8")
    OUT_MD.write_text(out_md, encoding="utf-8")
    print(f"Updated {OUT_JSON} and {OUT_MD}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
