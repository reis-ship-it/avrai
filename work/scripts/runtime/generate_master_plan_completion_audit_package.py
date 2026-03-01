#!/usr/bin/env python3
"""Generate/check master-plan completion audit/sign-off package artifacts."""

from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import sys
from pathlib import Path

CONFIG_PATH = Path("configs/runtime/master_plan_completion_audit_package.json")
OUT_JSON = Path(
    "docs/plans/methodology/MASTER_PLAN_3_PRONG_COMPLETION_AUDIT_PACKAGE.json"
)
OUT_MD = Path(
    "docs/plans/methodology/MASTER_PLAN_3_PRONG_COMPLETION_AUDIT_PACKAGE.md"
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


def _load_json(path: Path) -> dict:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:
        _fail(f"invalid JSON at {path}: {exc}")
    if not isinstance(data, dict):
        _fail(f"expected JSON object at {path}")
    return data


def _build_summary(config: dict) -> dict:
    if str(config.get("version", "")).strip() != "v1":
        _fail("audit package config version must be 'v1'")

    evaluation_at_raw = str(config.get("evaluation_at", "")).strip()
    if not evaluation_at_raw:
        _fail("evaluation_at is required")
    try:
        generated_at = _parse_ts(evaluation_at_raw)
    except Exception:
        _fail(f"invalid evaluation_at '{evaluation_at_raw}'")

    required_gate_reports = config.get("required_gate_reports")
    required_documents = config.get("required_documents")
    required_signoff_roles = config.get("required_signoff_roles")
    signoff_registry_raw = config.get("signoff_registry")
    verdict_keys = config.get("verdict_keys")

    if not isinstance(required_gate_reports, list) or not required_gate_reports:
        _fail("required_gate_reports must be non-empty list")
    if not isinstance(required_documents, list) or not required_documents:
        _fail("required_documents must be non-empty list")
    if not isinstance(required_signoff_roles, list) or not required_signoff_roles:
        _fail("required_signoff_roles must be non-empty list")
    if not isinstance(signoff_registry_raw, str) or not signoff_registry_raw.strip():
        _fail("signoff_registry must be non-empty string path")
    if not isinstance(verdict_keys, dict):
        _fail("verdict_keys must be object")

    missing_reports: list[str] = []
    missing_documents: list[str] = []
    verdict_failures: list[str] = []
    verdicts: dict[str, str] = {}
    missing_signoff_roles: list[str] = []
    approved_signoff_roles: list[str] = []
    notes: list[str] = []

    package_fingerprint_parts: list[str] = [generated_at.isoformat()]

    for raw in required_gate_reports:
        path = Path(str(raw))
        if not path.exists():
            missing_reports.append(str(path))
            continue

        package_fingerprint_parts.append(str(path))
        package_fingerprint_parts.append(
            hashlib.sha256(path.read_bytes()).hexdigest()
        )

        if path.suffix == ".json":
            data = _load_json(path)
            key = verdict_keys.get(str(path))
            if key is not None:
                verdict = str(data.get(str(key), "")).strip()
                verdicts[str(path)] = verdict
                if verdict != "PASS":
                    verdict_failures.append(f"{path}:{key}={verdict or 'MISSING'}")
            elif "verdict" in data:
                verdict = str(data.get("verdict", "")).strip()
                verdicts[str(path)] = verdict

    for raw in required_documents:
        path = Path(str(raw))
        if not path.exists():
            missing_documents.append(str(path))
            continue
        package_fingerprint_parts.append(str(path))
        package_fingerprint_parts.append(
            hashlib.sha256(path.read_bytes()).hexdigest()
        )

    signoff_registry_path = Path(signoff_registry_raw)
    if not signoff_registry_path.exists():
        _fail(f"missing signoff registry: {signoff_registry_path}")

    package_fingerprint_parts.append(str(signoff_registry_path))
    package_fingerprint_parts.append(
        hashlib.sha256(signoff_registry_path.read_bytes()).hexdigest()
    )

    signoff_data = _load_json(signoff_registry_path)
    if str(signoff_data.get("version", "")).strip() != "v1":
        _fail("signoff registry version must be 'v1'")
    signoffs = signoff_data.get("signoffs")
    if not isinstance(signoffs, list):
        _fail("signoff registry signoffs must be list")

    signoff_by_role: dict[str, dict] = {}
    for idx, raw in enumerate(signoffs, start=1):
        if not isinstance(raw, dict):
            _fail(f"signoff[{idx}] must be object")
        role = str(raw.get("role", "")).strip()
        if not role:
            _fail(f"signoff[{idx}] missing role")
        if role in signoff_by_role:
            _fail(f"duplicate signoff role in registry: {role}")
        signoff_by_role[role] = raw

    for role_raw in required_signoff_roles:
        role = str(role_raw)
        entry = signoff_by_role.get(role)
        if entry is None:
            missing_signoff_roles.append(role)
            notes.append(f"role missing in signoff registry: {role}")
            continue

        approved = entry.get("approved") is True
        approved_by = entry.get("approved_by")
        approved_at = entry.get("approved_at")
        if approved:
            if not isinstance(approved_by, str) or not approved_by.strip():
                notes.append(f"role approved without approved_by: {role}")
                missing_signoff_roles.append(role)
                continue
            if not isinstance(approved_at, str) or not approved_at.strip():
                notes.append(f"role approved without approved_at: {role}")
                missing_signoff_roles.append(role)
                continue
            try:
                _parse_ts(approved_at)
            except Exception:
                notes.append(f"role approved_at invalid ISO timestamp: {role}")
                missing_signoff_roles.append(role)
                continue
            approved_signoff_roles.append(role)
            continue

        missing_signoff_roles.append(role)

    gates_ready = not missing_reports and not verdict_failures
    docs_ready = not missing_documents
    signoff_ready = not missing_signoff_roles

    verdict = "PASS" if gates_ready and docs_ready and signoff_ready else "FAIL"

    fingerprint_raw = "|".join(package_fingerprint_parts)
    package_hash = hashlib.sha256(fingerprint_raw.encode("utf-8")).hexdigest()

    return {
        "version": "v1",
        "source": str(CONFIG_PATH),
        "generated_at": generated_at.replace(microsecond=0)
        .isoformat()
        .replace("+00:00", "Z"),
        "required_gate_reports": [str(x) for x in required_gate_reports],
        "required_documents": [str(x) for x in required_documents],
        "required_signoff_roles": [str(x) for x in required_signoff_roles],
        "signoff_registry": str(signoff_registry_path),
        "approved_signoff_roles": sorted(approved_signoff_roles),
        "missing_reports": missing_reports,
        "missing_documents": missing_documents,
        "gate_verdicts": verdicts,
        "verdict_failures": verdict_failures,
        "missing_signoff_roles": missing_signoff_roles,
        "gates_ready": gates_ready,
        "documents_ready": docs_ready,
        "signoff_ready": signoff_ready,
        "package_hash": package_hash,
        "notes": notes,
        "verdict": verdict,
    }


def _render_md(summary: dict) -> str:
    lines = [
        "# 3-Prong Completion Audit Package",
        "",
        f"**Source config:** `{summary.get('source')}`  ",
        f"**Sign-off registry:** `{summary.get('signoff_registry')}`  ",
        f"**Generated at:** {summary.get('generated_at')}  ",
        f"**Package hash:** `{summary.get('package_hash')}`  ",
        f"**Gates ready:** {summary.get('gates_ready')}  ",
        f"**Documents ready:** {summary.get('documents_ready')}  ",
        f"**Sign-off ready:** {summary.get('signoff_ready')}  ",
        f"**Verdict:** {summary.get('verdict')}  ",
        "",
        "## Gate Verdicts",
        "",
        "| Report | Verdict |",
        "|--------|---------|",
    ]

    gate_verdicts = summary.get("gate_verdicts") or {}
    if isinstance(gate_verdicts, dict) and gate_verdicts:
        for report in sorted(gate_verdicts.keys()):
            lines.append(f"| {report} | {gate_verdicts.get(report, '')} |")
    else:
        lines.append("| - | - |")

    def _section(title: str, items: list[str]) -> None:
        lines.extend(["", f"## {title}", ""])
        if items:
            lines.extend([f"- {item}" for item in items])
        else:
            lines.append("- None")

    _section("Missing Gate Reports", summary.get("missing_reports") or [])
    _section("Missing Documents", summary.get("missing_documents") or [])
    _section("Gate Verdict Failures", summary.get("verdict_failures") or [])
    _section("Approved Sign-Off Roles", summary.get("approved_signoff_roles") or [])
    _section("Missing Sign-Off Roles", summary.get("missing_signoff_roles") or [])
    _section("Notes", summary.get("notes") or [])

    return "\n".join(lines).rstrip() + "\n"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    if not CONFIG_PATH.exists():
        _fail(f"missing config: {CONFIG_PATH}")

    config = _load_json(CONFIG_PATH)
    summary = _build_summary(config)
    out_json = json.dumps(summary, indent=2, sort_keys=True) + "\n"
    out_md = _render_md(summary)

    if args.check:
        if not OUT_JSON.exists() or not OUT_MD.exists():
            _fail("completion audit artifacts missing; run generator")
        if OUT_JSON.read_text(encoding="utf-8") != out_json:
            _fail("completion audit JSON report out of date")
        if OUT_MD.read_text(encoding="utf-8") != out_md:
            _fail("completion audit markdown report out of date")
        print("OK: completion audit package is in sync.")
        return 0

    OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
    OUT_MD.parent.mkdir(parents=True, exist_ok=True)
    OUT_JSON.write_text(out_json, encoding="utf-8")
    OUT_MD.write_text(out_md, encoding="utf-8")
    print(f"Updated {OUT_JSON} and {OUT_MD}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
