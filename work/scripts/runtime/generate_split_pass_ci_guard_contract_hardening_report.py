#!/usr/bin/env python3
"""Generate/check split-pass CI guard and contract hardening report."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import sys
from pathlib import Path

CONFIG_PATH = Path("configs/runtime/split_pass_ci_guard_contract_hardening_controls.json")
OUT_JSON = Path(
    "docs/plans/methodology/MASTER_PLAN_SPLIT_PASS_CI_GUARD_CONTRACT_HARDENING_REPORT.json"
)
OUT_MD = Path(
    "docs/plans/methodology/MASTER_PLAN_SPLIT_PASS_CI_GUARD_CONTRACT_HARDENING_REPORT.md"
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

    workflow_path = Path(str(cfg.get("workflow_path", "")).strip())
    if not workflow_path.exists():
        _fail(f"workflow_path not found: {workflow_path}")

    required_commands = cfg.get("required_commands")
    if not isinstance(required_commands, list) or not required_commands:
        _fail("required_commands must be a non-empty list")

    workflow_text = workflow_path.read_text(encoding="utf-8")
    missing: list[str] = []
    duplicated: list[str] = []

    for raw in required_commands:
        command = str(raw).strip()
        if not command:
            _fail("required_commands entries must be non-empty strings")
        occurrences = workflow_text.count(command)
        if occurrences == 0:
            missing.append(command)
        if occurrences > 1:
            duplicated.append(command)

    verdict = "PASS" if not missing and not duplicated else "FAIL"

    return {
        "version": "v1",
        "source": str(CONFIG_PATH),
        "workflow_path": str(workflow_path),
        "generated_at": generated_at.replace(microsecond=0).isoformat().replace("+00:00", "Z"),
        "required_command_count": len(required_commands),
        "missing_commands": missing,
        "duplicated_commands": duplicated,
        "verdict": verdict,
    }


def _render_md(summary: dict) -> str:
    missing = summary.get("missing_commands", [])
    duplicated = summary.get("duplicated_commands", [])

    return (
        "# Split-Pass CI Guard/Contract Hardening Report\n\n"
        f"**Source config:** `{summary.get('source')}`  \n"
        f"**Workflow path:** `{summary.get('workflow_path')}`  \n"
        f"**Generated at:** {summary.get('generated_at')}  \n"
        f"**Required commands checked:** {summary.get('required_command_count', 0)}  \n"
        f"**Verdict:** {summary.get('verdict')}\n\n"
        "## Missing Commands\n\n"
        + ("- None\n" if not missing else "\n".join(f"- {v}" for v in missing) + "\n")
        + "\n## Duplicated Commands\n\n"
        + (
            "- None\n"
            if not duplicated
            else "\n".join(f"- {v}" for v in duplicated) + "\n"
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
            _fail("split-pass CI guard report artifacts missing; run generator")
        if OUT_JSON.read_text(encoding="utf-8") != out_json:
            _fail("split-pass CI guard JSON report out of date")
        if OUT_MD.read_text(encoding="utf-8") != out_md:
            _fail("split-pass CI guard markdown report out of date")
        print("OK: split-pass CI guard/contract hardening report is in sync.")
        return 0

    OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
    OUT_MD.parent.mkdir(parents=True, exist_ok=True)
    OUT_JSON.write_text(out_json, encoding="utf-8")
    OUT_MD.write_text(out_md, encoding="utf-8")
    print(f"Updated {OUT_JSON} and {OUT_MD}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
