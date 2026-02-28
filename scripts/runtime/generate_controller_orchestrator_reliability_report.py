#!/usr/bin/env python3
"""Generate/check controller-orchestrator reliability canary report."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import sys
from pathlib import Path

CONFIG_PATH = Path("configs/runtime/controller_orchestrator_reliability_canary.json")
OUT_JSON = Path(
    "docs/plans/methodology/MASTER_PLAN_CONTROLLER_ORCHESTRATOR_RELIABILITY_REPORT.json"
)
OUT_MD = Path(
    "docs/plans/methodology/MASTER_PLAN_CONTROLLER_ORCHESTRATOR_RELIABILITY_REPORT.md"
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

    error_budget = cfg.get("error_budget")
    if not isinstance(error_budget, dict):
        _fail("error_budget must be object")

    max_rate = error_budget.get("max_error_rate_pct")
    observed_rate = error_budget.get("observed_error_rate_pct")
    sample_size = error_budget.get("sample_size")
    if not isinstance(max_rate, (int, float)) or max_rate < 0:
        _fail("error_budget.max_error_rate_pct must be non-negative number")
    if not isinstance(observed_rate, (int, float)) or observed_rate < 0:
        _fail("error_budget.observed_error_rate_pct must be non-negative number")
    if not isinstance(sample_size, int) or sample_size <= 0:
        _fail("error_budget.sample_size must be positive integer")

    assertions = cfg.get("dead_path_assertions")
    if not isinstance(assertions, list) or not assertions:
        _fail("dead_path_assertions must be non-empty list")

    errors: list[str] = []
    dead_paths = 0
    checked_controllers = 0

    for idx, raw in enumerate(assertions, start=1):
        if not isinstance(raw, dict):
            errors.append(f"assertion[{idx}] must be object")
            continue
        checked_controllers += 1
        controller = str(raw.get("controller", "")).strip()
        primary = str(raw.get("primary_orchestrator_path", "")).strip()
        fallback = str(raw.get("fallback_path", "")).strip()
        dead_path = raw.get("dead_path_detected") is True

        if not controller:
            errors.append(f"assertion[{idx}] missing controller")
        if not primary:
            errors.append(f"assertion[{idx}] missing primary_orchestrator_path")
        if not fallback:
            errors.append(f"assertion[{idx}] missing fallback_path")
        if dead_path:
            dead_paths += 1
            errors.append(f"assertion[{idx}] dead path detected for {controller or 'unknown'}")

    error_budget_ok = float(observed_rate) <= float(max_rate)
    dead_path_ok = dead_paths == 0
    verdict = "PASS" if error_budget_ok and dead_path_ok and not errors else "FAIL"

    return {
        "version": "v1",
        "source": str(CONFIG_PATH),
        "generated_at": generated_at.replace(microsecond=0).isoformat().replace("+00:00", "Z"),
        "controllers_checked": checked_controllers,
        "dead_paths_detected": dead_paths,
        "error_budget": {
            "max_error_rate_pct": float(max_rate),
            "observed_error_rate_pct": float(observed_rate),
            "sample_size": int(sample_size),
            "within_budget": error_budget_ok,
        },
        "dead_path_check_passed": dead_path_ok,
        "errors": errors,
        "verdict": verdict,
    }


def _render_md(summary: dict) -> str:
    eb = summary.get("error_budget") or {}
    return (
        "# Controller/Orchestrator Reliability Report\n\n"
        f"**Source config:** `{summary.get('source')}`  \n"
        f"**Generated at:** {summary.get('generated_at')}  \n"
        f"**Controllers checked:** {summary.get('controllers_checked', 0)}  \n"
        f"**Dead paths detected:** {summary.get('dead_paths_detected', 0)}  \n"
        f"**Error budget max rate (%):** {eb.get('max_error_rate_pct', 0.0):.2f}  \n"
        f"**Error budget observed rate (%):** {eb.get('observed_error_rate_pct', 0.0):.2f}  \n"
        f"**Error budget sample size:** {eb.get('sample_size', 0)}  \n"
        f"**Error budget within threshold:** {eb.get('within_budget')}  \n"
        f"**Dead-path check passed:** {summary.get('dead_path_check_passed')}  \n"
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
            _fail("reliability report artifacts missing; run generator")
        if OUT_JSON.read_text(encoding="utf-8") != out_json:
            _fail("reliability JSON report out of date")
        if OUT_MD.read_text(encoding="utf-8") != out_md:
            _fail("reliability markdown report out of date")
        print("OK: controller/orchestrator reliability report is in sync.")
        return 0

    OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
    OUT_MD.parent.mkdir(parents=True, exist_ok=True)
    OUT_JSON.write_text(out_json, encoding="utf-8")
    OUT_MD.write_text(out_md, encoding="utf-8")
    print(f"Updated {OUT_JSON} and {OUT_MD}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
