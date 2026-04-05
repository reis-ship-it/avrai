#!/usr/bin/env python3
"""Generate/check integration governance + contract security report."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import sys
from pathlib import Path

CONFIG_PATH = Path("configs/runtime/integration_governance_contract_security_controls.json")
OUT_JSON = Path(
    "docs/plans/methodology/MASTER_PLAN_INTEGRATION_GOVERNANCE_CONTRACT_SECURITY_REPORT.json"
)
OUT_MD = Path(
    "docs/plans/methodology/MASTER_PLAN_INTEGRATION_GOVERNANCE_CONTRACT_SECURITY_REPORT.md"
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

    contract = cfg.get("contract_compatibility")
    if not isinstance(contract, dict):
        _fail("contract_compatibility must be object")
    min_contract_rate = _require_non_negative_number(
        contract.get("min_contract_pass_rate_pct"),
        "contract_compatibility.min_contract_pass_rate_pct",
    )
    observed_contract_rate = _require_non_negative_number(
        contract.get("observed_contract_pass_rate_pct"),
        "contract_compatibility.observed_contract_pass_rate_pct",
    )
    breaking_changes = _require_non_negative_number(
        contract.get("critical_breaking_changes_detected"),
        "contract_compatibility.critical_breaking_changes_detected",
    )
    contracts_evaluated = _require_positive_int(
        contract.get("contracts_evaluated"),
        "contract_compatibility.contracts_evaluated",
    )

    security = cfg.get("security_conformance")
    if not isinstance(security, dict):
        _fail("security_conformance must be object")
    required_security_rate = _require_non_negative_number(
        security.get("required_security_gate_pass_rate_pct"),
        "security_conformance.required_security_gate_pass_rate_pct",
    )
    observed_security_rate = _require_non_negative_number(
        security.get("observed_security_gate_pass_rate_pct"),
        "security_conformance.observed_security_gate_pass_rate_pct",
    )
    critical_security_findings = _require_non_negative_number(
        security.get("critical_security_findings"),
        "security_conformance.critical_security_findings",
    )
    security_checks = _require_positive_int(
        security.get("security_checks_executed"),
        "security_conformance.security_checks_executed",
    )

    release = cfg.get("release_gate_governance")
    if not isinstance(release, dict):
        _fail("release_gate_governance must be object")
    required_release_rate = _require_non_negative_number(
        release.get("required_release_gate_pass_rate_pct"),
        "release_gate_governance.required_release_gate_pass_rate_pct",
    )
    observed_release_rate = _require_non_negative_number(
        release.get("observed_release_gate_pass_rate_pct"),
        "release_gate_governance.observed_release_gate_pass_rate_pct",
    )
    critical_open_findings = _require_non_negative_number(
        release.get("critical_open_findings"),
        "release_gate_governance.critical_open_findings",
    )
    release_gates = _require_positive_int(
        release.get("release_gates_executed"),
        "release_gate_governance.release_gates_executed",
    )

    contract_ok = observed_contract_rate >= min_contract_rate and breaking_changes == 0
    security_ok = (
        observed_security_rate >= required_security_rate
        and critical_security_findings == 0
    )
    release_ok = observed_release_rate >= required_release_rate and critical_open_findings == 0

    errors: list[str] = []
    if not contract_ok:
      errors.append("integration contract compatibility threshold failed")
    if not security_ok:
      errors.append("security conformance threshold failed")
    if not release_ok:
      errors.append("release gate governance threshold failed")

    verdict = "PASS" if contract_ok and security_ok and release_ok and not errors else "FAIL"

    return {
        "version": "v1",
        "source": str(CONFIG_PATH),
        "generated_at": generated_at.replace(microsecond=0).isoformat().replace("+00:00", "Z"),
        "contract_compatibility": {
            "min_contract_pass_rate_pct": min_contract_rate,
            "observed_contract_pass_rate_pct": observed_contract_rate,
            "critical_breaking_changes_detected": int(breaking_changes),
            "contracts_evaluated": contracts_evaluated,
            "within_threshold": contract_ok,
        },
        "security_conformance": {
            "required_security_gate_pass_rate_pct": required_security_rate,
            "observed_security_gate_pass_rate_pct": observed_security_rate,
            "critical_security_findings": int(critical_security_findings),
            "security_checks_executed": security_checks,
            "within_threshold": security_ok,
        },
        "release_gate_governance": {
            "required_release_gate_pass_rate_pct": required_release_rate,
            "observed_release_gate_pass_rate_pct": observed_release_rate,
            "critical_open_findings": int(critical_open_findings),
            "release_gates_executed": release_gates,
            "within_threshold": release_ok,
        },
        "errors": errors,
        "verdict": verdict,
    }


def _render_md(summary: dict) -> str:
    contract = summary.get("contract_compatibility") or {}
    security = summary.get("security_conformance") or {}
    release = summary.get("release_gate_governance") or {}

    return (
        "# Integration Governance/Contract Security Report\n\n"
        f"**Source config:** `{summary.get('source')}`  \n"
        f"**Generated at:** {summary.get('generated_at')}  \n"
        f"**Min contract pass rate (%):** {contract.get('min_contract_pass_rate_pct', 0.0):.2f}  \n"
        f"**Observed contract pass rate (%):** {contract.get('observed_contract_pass_rate_pct', 0.0):.2f}  \n"
        f"**Critical breaking changes:** {contract.get('critical_breaking_changes_detected', 0)}  \n"
        f"**Contracts evaluated:** {contract.get('contracts_evaluated', 0)}  \n"
        f"**Contract threshold check:** {contract.get('within_threshold')}  \n"
        f"**Required security gate pass rate (%):** {security.get('required_security_gate_pass_rate_pct', 0.0):.2f}  \n"
        f"**Observed security gate pass rate (%):** {security.get('observed_security_gate_pass_rate_pct', 0.0):.2f}  \n"
        f"**Critical security findings:** {security.get('critical_security_findings', 0)}  \n"
        f"**Security checks executed:** {security.get('security_checks_executed', 0)}  \n"
        f"**Security threshold check:** {security.get('within_threshold')}  \n"
        f"**Required release gate pass rate (%):** {release.get('required_release_gate_pass_rate_pct', 0.0):.2f}  \n"
        f"**Observed release gate pass rate (%):** {release.get('observed_release_gate_pass_rate_pct', 0.0):.2f}  \n"
        f"**Critical open findings:** {release.get('critical_open_findings', 0)}  \n"
        f"**Release gates executed:** {release.get('release_gates_executed', 0)}  \n"
        f"**Release threshold check:** {release.get('within_threshold')}  \n"
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
            _fail("integration governance/security report artifacts missing; run generator")
        if OUT_JSON.read_text(encoding="utf-8") != out_json:
            _fail("integration governance/security JSON report out of date")
        if OUT_MD.read_text(encoding="utf-8") != out_md:
            _fail("integration governance/security markdown report out of date")
        print("OK: integration governance/contract security report is in sync.")
        return 0

    OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
    OUT_MD.parent.mkdir(parents=True, exist_ok=True)
    OUT_JSON.write_text(out_json, encoding="utf-8")
    OUT_MD.write_text(out_md, encoding="utf-8")
    print(f"Updated {OUT_JSON} and {OUT_MD}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
