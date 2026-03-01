#!/usr/bin/env python3
"""Generate/check self-healing incident routing readiness report."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import sys
from pathlib import Path

CONFIG_PATH = Path("configs/runtime/self_healing_incident_routing_queue.json")
OUT_JSON = Path(
    "docs/plans/methodology/MASTER_PLAN_3_PRONG_SELF_HEALING_INCIDENT_ROUTING_REPORT.json"
)
OUT_MD = Path(
    "docs/plans/methodology/MASTER_PLAN_3_PRONG_SELF_HEALING_INCIDENT_ROUTING_REPORT.md"
)
ALLOWED_STATUS = {"open", "contained", "recovered", "closed"}
ACTIVE_STATUS = {"open", "contained"}
ALLOWED_SEVERITY = {"p0", "p1", "p2", "p3"}


def _fail(msg: str) -> None:
    print(f"ERROR: {msg}", file=sys.stderr)
    raise SystemExit(1)


def _parse_ts(raw: str) -> dt.datetime:
    s = raw.strip()
    if s.endswith("Z"):
        s = s[:-1] + "+00:00"
    value = dt.datetime.fromisoformat(s)
    if value.tzinfo is None:
        value = value.replace(tzinfo=dt.timezone.utc)
    return value.astimezone(dt.timezone.utc)


def _load_config() -> dict:
    if not CONFIG_PATH.exists():
        _fail(f"missing self-healing incident routing config: {CONFIG_PATH}")
    try:
        data = json.loads(CONFIG_PATH.read_text(encoding="utf-8"))
    except Exception as exc:
        _fail(f"invalid JSON in self-healing config: {exc}")
    if not isinstance(data, dict):
        _fail("self-healing config root must be JSON object")
    return data


def _check_slo(
    opened_at: dt.datetime,
    event_at: dt.datetime,
    limit_hours: float,
) -> bool:
    return (event_at - opened_at) <= dt.timedelta(hours=limit_hours)


def _build_summary(data: dict) -> dict:
    if str(data.get("version", "")).strip() != "v1":
        _fail("self-healing config version must be 'v1'")

    evaluation_at_raw = str(data.get("evaluation_at", "")).strip()
    if not evaluation_at_raw:
        _fail("evaluation_at is required for deterministic report generation")

    try:
        generated_at = _parse_ts(evaluation_at_raw)
    except Exception:
        _fail(f"invalid evaluation_at '{evaluation_at_raw}'")

    slo = data.get("slo_hours")
    if not isinstance(slo, dict):
        _fail("slo_hours must be object")

    detect_slo = slo.get("detect")
    contain_slo = slo.get("contain")
    recover_slo = slo.get("recover")
    for key, value in {
        "detect": detect_slo,
        "contain": contain_slo,
        "recover": recover_slo,
    }.items():
        if not isinstance(value, (int, float)) or value <= 0:
            _fail(f"invalid slo_hours.{key} '{value}'")

    incidents = data.get("incidents")
    if not isinstance(incidents, list) or not incidents:
        _fail("incidents must be non-empty list")

    errors: list[str] = []
    total = 0
    active = 0
    routed = 0
    detect_ok = 0
    contain_required = 0
    contain_ok = 0
    recover_required = 0
    recover_ok = 0
    slo_breaches = 0
    per_domain: dict[str, int] = {}
    per_severity = {key: 0 for key in sorted(ALLOWED_SEVERITY)}

    for idx, raw in enumerate(incidents, start=1):
        if not isinstance(raw, dict):
            errors.append(f"incident[{idx}] must be object")
            continue

        total += 1

        incident_id = str(raw.get("incident_id", "")).strip()
        if not incident_id:
            errors.append(f"incident[{idx}] missing incident_id")

        domain = str(raw.get("domain", "")).strip()
        if not domain:
            errors.append(f"incident[{idx}] missing domain")
        else:
            per_domain[domain] = per_domain.get(domain, 0) + 1

        severity = str(raw.get("severity", "")).strip()
        if severity not in ALLOWED_SEVERITY:
            errors.append(f"incident[{idx}] invalid severity '{severity}'")
        else:
            per_severity[severity] += 1

        status = str(raw.get("status", "")).strip()
        if status not in ALLOWED_STATUS:
            errors.append(f"incident[{idx}] invalid status '{status}'")
            continue

        if status in ACTIVE_STATUS:
            active += 1

        route = str(raw.get("route", "")).strip()
        auto_route_enabled = raw.get("auto_route_enabled") is True
        if route and auto_route_enabled:
            routed += 1
        else:
            errors.append(
                f"incident[{idx}] missing route or auto_route_enabled=false"
            )

        opened_at_raw = str(raw.get("opened_at", "")).strip()
        detect_at_raw = str(raw.get("detect_at", "")).strip()
        try:
            opened_at = _parse_ts(opened_at_raw)
            detect_at = _parse_ts(detect_at_raw)
        except Exception:
            errors.append(
                f"incident[{idx}] invalid opened_at/detect_at timestamp"
            )
            continue

        if detect_at < opened_at:
            errors.append(f"incident[{idx}] detect_at before opened_at")
        if _check_slo(opened_at, detect_at, float(detect_slo)):
            detect_ok += 1
        else:
            slo_breaches += 1
            errors.append(f"incident[{idx}] detect SLO breach")

        contain_raw = raw.get("contain_at")
        contain_at = None
        if contain_raw not in (None, ""):
            try:
                contain_at = _parse_ts(str(contain_raw))
            except Exception:
                errors.append(f"incident[{idx}] invalid contain_at timestamp")

        recover_raw = raw.get("recover_at")
        recover_at = None
        if recover_raw not in (None, ""):
            try:
                recover_at = _parse_ts(str(recover_raw))
            except Exception:
                errors.append(f"incident[{idx}] invalid recover_at timestamp")

        if status in {"contained", "recovered", "closed"}:
            contain_required += 1
            if contain_at is None:
                errors.append(
                    f"incident[{idx}] status '{status}' requires contain_at"
                )
            else:
                if contain_at < detect_at:
                    errors.append(f"incident[{idx}] contain_at before detect_at")
                if _check_slo(opened_at, contain_at, float(contain_slo)):
                    contain_ok += 1
                else:
                    slo_breaches += 1
                    errors.append(f"incident[{idx}] contain SLO breach")

        if status in {"recovered", "closed"}:
            recover_required += 1
            if recover_at is None:
                errors.append(
                    f"incident[{idx}] status '{status}' requires recover_at"
                )
            else:
                pivot = contain_at if contain_at is not None else detect_at
                if recover_at < pivot:
                    errors.append(f"incident[{idx}] recover_at before containment")
                if _check_slo(opened_at, recover_at, float(recover_slo)):
                    recover_ok += 1
                else:
                    slo_breaches += 1
                    errors.append(f"incident[{idx}] recover SLO breach")

    all_routed = routed == total and total > 0
    detect_compliant = detect_ok == total and total > 0
    contain_compliant = contain_required == contain_ok
    recover_compliant = recover_required == recover_ok
    slo_compliant = slo_breaches == 0

    verdict = "PASS"
    if (
        not all_routed
        or not detect_compliant
        or not contain_compliant
        or not recover_compliant
        or not slo_compliant
        or bool(errors)
    ):
        verdict = "FAIL"

    return {
        "version": "v1",
        "source": str(CONFIG_PATH),
        "generated_at": generated_at.replace(microsecond=0)
        .isoformat()
        .replace("+00:00", "Z"),
        "total_incidents": total,
        "active_incidents": active,
        "routed_incidents": routed,
        "all_routed": all_routed,
        "detect_slo_compliant": detect_compliant,
        "contain_slo_compliant": contain_compliant,
        "recover_slo_compliant": recover_compliant,
        "slo_breaches": slo_breaches,
        "slo_compliant": slo_compliant,
        "per_domain": dict(sorted(per_domain.items())),
        "per_severity": per_severity,
        "errors": errors,
        "verdict": verdict,
    }


def _render_md(summary: dict) -> str:
    per_domain = summary.get("per_domain") or {}
    per_severity = summary.get("per_severity") or {}
    lines = [
        "# 3-Prong Self-Healing Incident Routing Report",
        "",
        f"**Source config:** `{summary.get('source')}`  ",
        f"**Generated at:** {summary.get('generated_at')}  ",
        f"**Total incidents:** {summary.get('total_incidents', 0)}  ",
        f"**Active incidents:** {summary.get('active_incidents', 0)}  ",
        f"**Routed incidents:** {summary.get('routed_incidents', 0)}  ",
        f"**SLO breaches:** {summary.get('slo_breaches', 0)}  ",
        f"**Detect SLO compliant:** {summary.get('detect_slo_compliant')}  ",
        f"**Contain SLO compliant:** {summary.get('contain_slo_compliant')}  ",
        f"**Recover SLO compliant:** {summary.get('recover_slo_compliant')}  ",
        f"**Verdict:** {summary.get('verdict')}  ",
        "",
        "## Incidents by Domain",
        "",
        "| Domain | Count |",
        "|--------|-------|",
    ]

    for domain in sorted(per_domain.keys()):
        lines.append(f"| {domain} | {per_domain.get(domain, 0)} |")

    lines.extend([
        "",
        "## Incidents by Severity",
        "",
        "| Severity | Count |",
        "|----------|-------|",
    ])

    for severity in sorted(per_severity.keys()):
        lines.append(f"| {severity} | {per_severity.get(severity, 0)} |")

    lines.extend(["", "## Validation Errors", ""])
    errors = summary.get("errors") or []
    if errors:
        lines.extend([f"- {error}" for error in errors])
    else:
        lines.append("- None")

    return "\n".join(lines).rstrip() + "\n"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    summary = _build_summary(_load_config())
    out_json = json.dumps(summary, indent=2, sort_keys=True) + "\n"
    out_md = _render_md(summary)

    if args.check:
        if not OUT_JSON.exists() or not OUT_MD.exists():
            _fail("self-healing incident routing artifacts missing; run generator")
        if OUT_JSON.read_text(encoding="utf-8") != out_json:
            _fail("self-healing incident routing JSON report out of date")
        if OUT_MD.read_text(encoding="utf-8") != out_md:
            _fail("self-healing incident routing markdown report out of date")
        print("OK: self-healing incident routing report is in sync.")
        return 0

    OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
    OUT_MD.parent.mkdir(parents=True, exist_ok=True)
    OUT_JSON.write_text(out_json, encoding="utf-8")
    OUT_MD.write_text(out_md, encoding="utf-8")
    print(f"Updated {OUT_JSON} and {OUT_MD}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
