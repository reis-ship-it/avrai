#!/usr/bin/env python3
"""Generate/check conviction canary rollback drill report artifacts."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

CANARY_CONFIG_PATH = Path("configs/runtime/conviction_gate_canary_rollout.json")
DRILL_FIXTURE_PATH = Path("configs/runtime/conviction_gate_canary_rollback_drill_fixture.json")
OUT_JSON = Path("docs/plans/methodology/MASTER_PLAN_3_PRONG_CANARY_ROLLBACK_DRILL_REPORT.json")
OUT_MD = Path("docs/plans/methodology/MASTER_PLAN_3_PRONG_CANARY_ROLLBACK_DRILL_REPORT.md")
REQUIRED_FLAGS = (
    "conviction_gate_production_enforcement",
    "conviction_gate_high_impact_enforcement",
)


def _fail(msg: str) -> None:
    print(f"ERROR: {msg}", file=sys.stderr)
    raise SystemExit(1)


def _load_json(path: Path):
    if not path.exists():
        _fail(f"missing file: {path}")
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:
        _fail(f"invalid JSON at {path}: {exc}")


def _rollback_profile_is_fail_closed(config: dict) -> tuple[bool, list[str]]:
    errors: list[str] = []
    rollback = config.get("rollback_profile")
    if not isinstance(rollback, dict):
        return False, ["rollback_profile missing or invalid"]

    for flag in REQUIRED_FLAGS:
        entry = rollback.get(flag)
        if not isinstance(entry, dict):
            errors.append(f"rollback_profile.{flag} missing")
            continue
        if entry.get("enabled") is not False:
            errors.append(f"rollback_profile.{flag}.enabled must be false")
        if entry.get("rolloutPercentage") != 0:
            errors.append(f"rollback_profile.{flag}.rolloutPercentage must be 0")
        users = entry.get("targetUsers")
        if not isinstance(users, list) or len(users) != 0:
            errors.append(f"rollback_profile.{flag}.targetUsers must be []")

    return not errors, errors


def _build_summary(config: dict, fixture: dict) -> dict:
    incidents = fixture.get("incidents")
    if not isinstance(incidents, list):
        _fail("fixture.incidents must be a list")

    rollback_incidents = [i for i in incidents if isinstance(i, dict) and i.get("rollback_required") is True]
    fail_closed_ok, fail_closed_errors = _rollback_profile_is_fail_closed(config)

    drill_passed = bool(rollback_incidents) and fail_closed_ok
    verdict = "PASS" if drill_passed else "FAIL"

    return {
        "version": "v1",
        "source": {
            "canary_config": str(CANARY_CONFIG_PATH),
            "drill_fixture": str(DRILL_FIXTURE_PATH),
        },
        "window_start": fixture.get("window_start"),
        "window_end": fixture.get("window_end"),
        "total_incidents": len(incidents),
        "rollback_required_incidents": len(rollback_incidents),
        "rollback_profile_fail_closed": fail_closed_ok,
        "rollback_profile_errors": fail_closed_errors,
        "verdict": verdict,
    }


def _render_md(summary: dict) -> str:
    return (
        "# 3-Prong Canary Rollback Drill Report\n\n"
        f"**Canary config:** `{summary['source']['canary_config']}`  \n"
        f"**Drill fixture:** `{summary['source']['drill_fixture']}`  \n"
        f"**Window:** {summary.get('window_start')} -> {summary.get('window_end')}  \n"
        f"**Total incidents:** {summary.get('total_incidents', 0)}  \n"
        f"**Rollback-required incidents:** {summary.get('rollback_required_incidents', 0)}  \n"
        f"**Fail-closed rollback profile:** {summary.get('rollback_profile_fail_closed')}  \n"
        f"**Verdict:** {summary.get('verdict')}\n\n"
        "## Rollback Profile Checks\n\n"
        + (
            "- No rollback profile errors detected.\n"
            if not summary.get("rollback_profile_errors")
            else "\n".join(f"- {e}" for e in summary.get("rollback_profile_errors", [])) + "\n"
        )
    )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    config = _load_json(CANARY_CONFIG_PATH)
    fixture = _load_json(DRILL_FIXTURE_PATH)
    summary = _build_summary(config, fixture)
    out_json = json.dumps(summary, indent=2, sort_keys=True) + "\n"
    out_md = _render_md(summary)

    if args.check:
        if not OUT_JSON.exists() or not OUT_MD.exists():
            _fail("rollback drill report artifacts missing; run generator")
        if OUT_JSON.read_text(encoding="utf-8") != out_json:
            _fail("rollback drill JSON report out of date")
        if OUT_MD.read_text(encoding="utf-8") != out_md:
            _fail("rollback drill markdown report out of date")
        print("OK: conviction canary rollback drill report is in sync.")
        return 0

    OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
    OUT_MD.parent.mkdir(parents=True, exist_ok=True)
    OUT_JSON.write_text(out_json, encoding="utf-8")
    OUT_MD.write_text(out_md, encoding="utf-8")
    print(f"Updated {OUT_JSON} and {OUT_MD}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
