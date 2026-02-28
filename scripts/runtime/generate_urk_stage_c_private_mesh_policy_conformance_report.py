#!/usr/bin/env python3
"""Generate/check URK Stage C private-mesh policy conformance report."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import sys
from pathlib import Path

CONFIG_PATH = Path("configs/runtime/urk_stage_c_private_mesh_policy_conformance_controls.json")
OUT_JSON = Path(
    "docs/plans/methodology/MASTER_PLAN_URK_STAGE_C_PRIVATE_MESH_POLICY_CONFORMANCE_REPORT.json"
)
OUT_MD = Path(
    "docs/plans/methodology/MASTER_PLAN_URK_STAGE_C_PRIVATE_MESH_POLICY_CONFORMANCE_REPORT.md"
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

    window = cfg.get("evaluation_window")
    if not isinstance(window, dict):
        _fail("evaluation_window must be object")
    window_start = _parse_ts(window.get("start"), "evaluation_window.start")
    window_end = _parse_ts(window.get("end"), "evaluation_window.end")
    if window_end < window_start:
        _fail("evaluation_window.end must be >= evaluation_window.start")

    payload = cfg.get("payload_minimization")
    if not isinstance(payload, dict):
        _fail("payload_minimization must be object")
    required_schema = _require_non_negative_number(
        payload.get("required_schema_conformance_pct"),
        "payload_minimization.required_schema_conformance_pct",
    )
    observed_schema = _require_non_negative_number(
        payload.get("observed_schema_conformance_pct"),
        "payload_minimization.observed_schema_conformance_pct",
    )
    max_leaks = _require_non_negative_int(
        payload.get("max_direct_identifier_leaks"),
        "payload_minimization.max_direct_identifier_leaks",
    )
    observed_leaks = _require_non_negative_int(
        payload.get("observed_direct_identifier_leaks"),
        "payload_minimization.observed_direct_identifier_leaks",
    )
    payload_checks = _require_positive_int(
        payload.get("checks_executed"),
        "payload_minimization.checks_executed",
    )

    encryption = cfg.get("encryption_and_keying")
    if not isinstance(encryption, dict):
        _fail("encryption_and_keying must be object")
    required_double_enc = _require_non_negative_number(
        encryption.get("required_double_encryption_coverage_pct"),
        "encryption_and_keying.required_double_encryption_coverage_pct",
    )
    observed_double_enc = _require_non_negative_number(
        encryption.get("observed_double_encryption_coverage_pct"),
        "encryption_and_keying.observed_double_encryption_coverage_pct",
    )
    required_key_rotation = _require_non_negative_number(
        encryption.get("required_key_rotation_coverage_pct"),
        "encryption_and_keying.required_key_rotation_coverage_pct",
    )
    observed_key_rotation = _require_non_negative_number(
        encryption.get("observed_key_rotation_coverage_pct"),
        "encryption_and_keying.observed_key_rotation_coverage_pct",
    )
    encryption_checks = _require_positive_int(
        encryption.get("checks_executed"),
        "encryption_and_keying.checks_executed",
    )

    lineage_policy = cfg.get("lineage_and_policy_gate")
    if not isinstance(lineage_policy, dict):
        _fail("lineage_and_policy_gate must be object")
    required_lineage = _require_non_negative_number(
        lineage_policy.get("required_lineage_tag_coverage_pct"),
        "lineage_and_policy_gate.required_lineage_tag_coverage_pct",
    )
    observed_lineage = _require_non_negative_number(
        lineage_policy.get("observed_lineage_tag_coverage_pct"),
        "lineage_and_policy_gate.observed_lineage_tag_coverage_pct",
    )
    required_policy_gate = _require_non_negative_number(
        lineage_policy.get("required_policy_gate_coverage_pct"),
        "lineage_and_policy_gate.required_policy_gate_coverage_pct",
    )
    observed_policy_gate = _require_non_negative_number(
        lineage_policy.get("observed_policy_gate_coverage_pct"),
        "lineage_and_policy_gate.observed_policy_gate_coverage_pct",
    )
    max_bypass = _require_non_negative_int(
        lineage_policy.get("max_policy_bypass_events"),
        "lineage_and_policy_gate.max_policy_bypass_events",
    )
    observed_bypass = _require_non_negative_int(
        lineage_policy.get("observed_policy_bypass_events"),
        "lineage_and_policy_gate.observed_policy_bypass_events",
    )
    lineage_policy_checks = _require_positive_int(
        lineage_policy.get("checks_executed"),
        "lineage_and_policy_gate.checks_executed",
    )

    payload_ok = observed_schema >= required_schema and observed_leaks <= max_leaks
    encryption_ok = (
        observed_double_enc >= required_double_enc
        and observed_key_rotation >= required_key_rotation
    )
    lineage_policy_ok = (
        observed_lineage >= required_lineage
        and observed_policy_gate >= required_policy_gate
        and observed_bypass <= max_bypass
    )

    errors: list[str] = []
    if not payload_ok:
        errors.append("payload minimization/schema conformance threshold failed")
    if not encryption_ok:
        errors.append("double encryption/key rotation threshold failed")
    if not lineage_policy_ok:
        errors.append("lineage tagging/policy gate threshold failed")

    verdict = "PASS" if not errors else "FAIL"

    return {
        "version": "v1",
        "source": str(CONFIG_PATH),
        "generated_at": generated_at.replace(microsecond=0).isoformat().replace("+00:00", "Z"),
        "evaluation_window": {
            "start": window_start.replace(microsecond=0).isoformat().replace("+00:00", "Z"),
            "end": window_end.replace(microsecond=0).isoformat().replace("+00:00", "Z"),
        },
        "payload_minimization": {
            "required_schema_conformance_pct": required_schema,
            "observed_schema_conformance_pct": observed_schema,
            "max_direct_identifier_leaks": max_leaks,
            "observed_direct_identifier_leaks": observed_leaks,
            "checks_executed": payload_checks,
            "within_threshold": payload_ok,
        },
        "encryption_and_keying": {
            "required_double_encryption_coverage_pct": required_double_enc,
            "observed_double_encryption_coverage_pct": observed_double_enc,
            "required_key_rotation_coverage_pct": required_key_rotation,
            "observed_key_rotation_coverage_pct": observed_key_rotation,
            "checks_executed": encryption_checks,
            "within_threshold": encryption_ok,
        },
        "lineage_and_policy_gate": {
            "required_lineage_tag_coverage_pct": required_lineage,
            "observed_lineage_tag_coverage_pct": observed_lineage,
            "required_policy_gate_coverage_pct": required_policy_gate,
            "observed_policy_gate_coverage_pct": observed_policy_gate,
            "max_policy_bypass_events": max_bypass,
            "observed_policy_bypass_events": observed_bypass,
            "checks_executed": lineage_policy_checks,
            "within_threshold": lineage_policy_ok,
        },
        "errors": errors,
        "verdict": verdict,
    }


def _render_md(summary: dict) -> str:
    payload = summary.get("payload_minimization") or {}
    encryption = summary.get("encryption_and_keying") or {}
    lineage_policy = summary.get("lineage_and_policy_gate") or {}
    window = summary.get("evaluation_window") or {}

    return (
        "# URK Stage C Private Mesh Policy Conformance Report\n\n"
        f"**Source config:** `{summary.get('source')}`  \n"
        f"**Generated at:** {summary.get('generated_at')}  \n"
        f"**Evaluation window:** {window.get('start')} -> {window.get('end')}  \n"
        f"**Required schema conformance (%):** {payload.get('required_schema_conformance_pct', 0.0):.2f}  \n"
        f"**Observed schema conformance (%):** {payload.get('observed_schema_conformance_pct', 0.0):.2f}  \n"
        f"**Max direct identifier leaks:** {payload.get('max_direct_identifier_leaks', 0)}  \n"
        f"**Observed direct identifier leaks:** {payload.get('observed_direct_identifier_leaks', 0)}  \n"
        f"**Payload checks executed:** {payload.get('checks_executed', 0)}  \n"
        f"**Payload minimization check:** {payload.get('within_threshold')}  \n"
        f"**Required double-encryption coverage (%):** {encryption.get('required_double_encryption_coverage_pct', 0.0):.2f}  \n"
        f"**Observed double-encryption coverage (%):** {encryption.get('observed_double_encryption_coverage_pct', 0.0):.2f}  \n"
        f"**Required key-rotation coverage (%):** {encryption.get('required_key_rotation_coverage_pct', 0.0):.2f}  \n"
        f"**Observed key-rotation coverage (%):** {encryption.get('observed_key_rotation_coverage_pct', 0.0):.2f}  \n"
        f"**Encryption checks executed:** {encryption.get('checks_executed', 0)}  \n"
        f"**Encryption/keying check:** {encryption.get('within_threshold')}  \n"
        f"**Required lineage-tag coverage (%):** {lineage_policy.get('required_lineage_tag_coverage_pct', 0.0):.2f}  \n"
        f"**Observed lineage-tag coverage (%):** {lineage_policy.get('observed_lineage_tag_coverage_pct', 0.0):.2f}  \n"
        f"**Required policy-gate coverage (%):** {lineage_policy.get('required_policy_gate_coverage_pct', 0.0):.2f}  \n"
        f"**Observed policy-gate coverage (%):** {lineage_policy.get('observed_policy_gate_coverage_pct', 0.0):.2f}  \n"
        f"**Max policy bypass events:** {lineage_policy.get('max_policy_bypass_events', 0)}  \n"
        f"**Observed policy bypass events:** {lineage_policy.get('observed_policy_bypass_events', 0)}  \n"
        f"**Lineage/policy checks executed:** {lineage_policy.get('checks_executed', 0)}  \n"
        f"**Lineage/policy check:** {lineage_policy.get('within_threshold')}  \n"
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
            _fail("URK Stage C report artifacts missing; run generator")
        if OUT_JSON.read_text(encoding="utf-8") != out_json:
            _fail("URK Stage C JSON report out of date")
        if OUT_MD.read_text(encoding="utf-8") != out_md:
            _fail("URK Stage C markdown report out of date")
        print("OK: URK Stage C private mesh policy conformance report is in sync.")
        return 0

    OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
    OUT_MD.parent.mkdir(parents=True, exist_ok=True)
    OUT_JSON.write_text(out_json, encoding="utf-8")
    OUT_MD.write_text(out_md, encoding="utf-8")
    print(f"Updated {OUT_JSON} and {OUT_MD}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
