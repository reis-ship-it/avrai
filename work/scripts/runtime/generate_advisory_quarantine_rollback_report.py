#!/usr/bin/env python3
"""Generate/check advisory quarantine + rollback independence report."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import sys
from pathlib import Path

CONFIG_PATH = Path("configs/runtime/advisory_quarantine_rollback_independence.json")
OUT_JSON = Path(
    "docs/plans/methodology/MASTER_PLAN_ADVISORY_QUARANTINE_ROLLBACK_REPORT.json"
)
OUT_MD = Path(
    "docs/plans/methodology/MASTER_PLAN_ADVISORY_QUARANTINE_ROLLBACK_REPORT.md"
)
ALLOWED_QUARANTINE_STATUS = {"shadow", "quarantine", "disabled"}


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


def _build_summary(cfg: dict) -> dict:
    if str(cfg.get("version", "")).strip() != "v1":
        _fail("config version must be 'v1'")

    eval_raw = str(cfg.get("evaluation_at", "")).strip()
    if not eval_raw:
        _fail("evaluation_at is required")
    try:
        generated_at = _parse_ts(eval_raw)
    except Exception:
        _fail(f"invalid evaluation_at '{eval_raw}'")

    policy = cfg.get("policy")
    sources = cfg.get("advisory_sources")
    if not isinstance(policy, dict):
        _fail("policy must be object")
    if not isinstance(sources, list) or not sources:
        _fail("advisory_sources must be non-empty list")

    quarantine_required = policy.get("quarantine_mode_required") is True
    rollback_independence_required = (
        policy.get("advisory_rollback_must_be_independent") is True
    )

    errors: list[str] = []
    sources_checked = 0
    sources_quarantined = 0
    independent_rollbacks = 0

    for idx, raw in enumerate(sources, start=1):
        if not isinstance(raw, dict):
            errors.append(f"source[{idx}] must be object")
            continue

        sources_checked += 1
        source_id = str(raw.get("source_id", "")).strip()
        credibility = raw.get("credibility_score")
        quarantine_status = str(raw.get("quarantine_status", "")).strip()
        anomaly_detected = raw.get("anomaly_detected") is True
        rollback_available = raw.get("advisory_rollback_available") is True
        rollback_independent = (
            raw.get("advisory_rollback_independent_of_model") is True
        )

        if not source_id:
            errors.append(f"source[{idx}] missing source_id")
        if not isinstance(credibility, (int, float)) or not (0.0 <= float(credibility) <= 1.0):
            errors.append(f"source[{idx}] invalid credibility_score '{credibility}'")
        if quarantine_status not in ALLOWED_QUARANTINE_STATUS:
            errors.append(f"source[{idx}] invalid quarantine_status '{quarantine_status}'")
        else:
            if quarantine_status in {"shadow", "quarantine"}:
                sources_quarantined += 1

        if anomaly_detected and quarantine_status not in {"quarantine", "disabled"}:
            errors.append(f"source[{idx}] anomaly_detected requires quarantine/disabled status")

        if not rollback_available:
            errors.append(f"source[{idx}] advisory rollback unavailable")

        if rollback_independent:
            independent_rollbacks += 1
        elif rollback_independence_required:
            errors.append(f"source[{idx}] rollback is not independent of model rollback")

    quarantine_policy_passed = (not quarantine_required) or (sources_quarantined == sources_checked)
    if not quarantine_policy_passed:
        errors.append("not all advisory sources are in shadow/quarantine mode")

    rollback_independence_passed = (not rollback_independence_required) or (
        independent_rollbacks == sources_checked
    )
    if not rollback_independence_passed:
        errors.append("not all advisory sources support independent rollback")

    verdict = "PASS" if quarantine_policy_passed and rollback_independence_passed and not errors else "FAIL"

    return {
        "version": "v1",
        "source": str(CONFIG_PATH),
        "generated_at": generated_at.replace(microsecond=0).isoformat().replace("+00:00", "Z"),
        "sources_checked": sources_checked,
        "sources_in_shadow_or_quarantine": sources_quarantined,
        "independent_rollbacks": independent_rollbacks,
        "quarantine_policy_passed": quarantine_policy_passed,
        "rollback_independence_passed": rollback_independence_passed,
        "errors": errors,
        "verdict": verdict,
    }


def _render_md(summary: dict) -> str:
    return (
        "# Advisory Quarantine + Rollback Independence Report\n\n"
        f"**Source config:** `{summary.get('source')}`  \n"
        f"**Generated at:** {summary.get('generated_at')}  \n"
        f"**Sources checked:** {summary.get('sources_checked', 0)}  \n"
        f"**Sources in shadow/quarantine:** {summary.get('sources_in_shadow_or_quarantine', 0)}  \n"
        f"**Independent rollbacks:** {summary.get('independent_rollbacks', 0)}  \n"
        f"**Quarantine policy passed:** {summary.get('quarantine_policy_passed')}  \n"
        f"**Rollback independence passed:** {summary.get('rollback_independence_passed')}  \n"
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
            _fail("advisory quarantine artifacts missing; run generator")
        if OUT_JSON.read_text(encoding="utf-8") != out_json:
            _fail("advisory quarantine JSON report out of date")
        if OUT_MD.read_text(encoding="utf-8") != out_md:
            _fail("advisory quarantine markdown report out of date")
        print("OK: advisory quarantine rollback report is in sync.")
        return 0

    OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
    OUT_MD.parent.mkdir(parents=True, exist_ok=True)
    OUT_JSON.write_text(out_json, encoding="utf-8")
    OUT_MD.write_text(out_md, encoding="utf-8")
    print(f"Updated {OUT_JSON} and {OUT_MD}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
