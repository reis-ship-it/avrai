#!/usr/bin/env python3
"""Generate/check research replication queue SLA report artifacts."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import sys
from pathlib import Path

QUEUE_PATH = Path("configs/runtime/research_replication_queue.json")
OUT_JSON = Path("docs/plans/methodology/MASTER_PLAN_3_PRONG_RESEARCH_REPLICATION_SLA_REPORT.json")
OUT_MD = Path("docs/plans/methodology/MASTER_PLAN_3_PRONG_RESEARCH_REPLICATION_SLA_REPORT.md")
ACTIVE_STATUSES = {"open", "in_progress"}
ALLOWED_STATUSES = ACTIVE_STATUSES | {"closed"}
ALLOWED_PRIORITIES = {"critical", "high", "medium", "low"}


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


def _load_queue() -> dict:
    if not QUEUE_PATH.exists():
        _fail(f"missing queue file: {QUEUE_PATH}")
    try:
        data = json.loads(QUEUE_PATH.read_text(encoding="utf-8"))
    except Exception as exc:
        _fail(f"invalid JSON in queue file: {exc}")
    if not isinstance(data, dict):
        _fail("queue root must be JSON object")
    return data


def _build_summary(data: dict) -> dict:
    version = str(data.get("version", "")).strip()
    if version != "v1":
        _fail("queue version must be 'v1'")

    items = data.get("items")
    if not isinstance(items, list):
        _fail("items must be list")

    evaluation_at_raw = str(data.get("evaluation_at", "")).strip()
    if not evaluation_at_raw:
        _fail("evaluation_at is required for deterministic SLA reporting")
    try:
        now = _parse_ts(evaluation_at_raw)
    except Exception:
        _fail(f"invalid evaluation_at '{evaluation_at_raw}'")

    total = 0
    active = 0
    overdue = 0
    active_open = 0
    active_in_progress = 0
    per_priority = {k: 0 for k in sorted(ALLOWED_PRIORITIES)}
    errors: list[str] = []

    for idx, raw in enumerate(items, start=1):
      if not isinstance(raw, dict):
        errors.append(f"item[{idx}] must be object")
        continue

      total += 1
      claim_id = str(raw.get("claim_id", "")).strip()
      if not claim_id:
        errors.append(f"item[{idx}] missing claim_id")

      status = str(raw.get("status", "")).strip()
      if status not in ALLOWED_STATUSES:
        errors.append(f"item[{idx}] invalid status '{status}'")
        continue

      priority = str(raw.get("priority", "")).strip()
      if priority not in ALLOWED_PRIORITIES:
        errors.append(f"item[{idx}] invalid priority '{priority}'")
      else:
        per_priority[priority] += 1

      sla_hours = raw.get("sla_hours", data.get("default_sla_hours", 72))
      if not isinstance(sla_hours, (int, float)) or sla_hours <= 0:
        errors.append(f"item[{idx}] invalid sla_hours '{sla_hours}'")
        continue

      opened_raw = str(raw.get("opened_at", "")).strip()
      try:
        opened_at = _parse_ts(opened_raw)
      except Exception:
        errors.append(f"item[{idx}] invalid opened_at '{opened_raw}'")
        continue

      if status in ACTIVE_STATUSES:
        active += 1
        if status == "open":
          active_open += 1
        elif status == "in_progress":
          active_in_progress += 1
        due_at = opened_at + dt.timedelta(hours=float(sla_hours))
        if now > due_at:
          overdue += 1

    active_sla_ok = overdue == 0 and active > 0
    verdict = "PASS" if active_sla_ok and not errors else "FAIL"

    return {
      "version": "v1",
      "source": str(QUEUE_PATH),
      "generated_at": now.replace(microsecond=0).isoformat().replace("+00:00", "Z"),
      "total_items": total,
      "active_items": active,
      "active_open": active_open,
      "active_in_progress": active_in_progress,
      "overdue_items": overdue,
      "active_sla_compliant": overdue == 0,
      "per_priority": per_priority,
      "errors": errors,
      "verdict": verdict,
    }


def _render_md(summary: dict) -> str:
    per_priority = summary.get("per_priority", {})
    if not isinstance(per_priority, dict):
      per_priority = {}
    lines = [
      "# 3-Prong Research Replication SLA Report",
      "",
      f"**Source queue:** `{summary.get('source')}`  ",
      f"**Generated at:** {summary.get('generated_at')}  ",
      f"**Total items:** {summary.get('total_items', 0)}  ",
      f"**Active items:** {summary.get('active_items', 0)} (`open`={summary.get('active_open', 0)}, `in_progress`={summary.get('active_in_progress', 0)})  ",
      f"**Overdue active items:** {summary.get('overdue_items', 0)}  ",
      f"**SLA compliant:** {summary.get('active_sla_compliant')}  ",
      f"**Verdict:** {summary.get('verdict')}  ",
      "",
      "## Priority Distribution",
      "",
      "| Priority | Count |",
      "|----------|-------|",
    ]
    for key in sorted(per_priority.keys()):
      lines.append(f"| {key} | {per_priority.get(key, 0)} |")

    lines.extend(["", "## Validation Errors", ""])
    errors = summary.get("errors") or []
    if errors:
      lines.extend([f"- {e}" for e in errors])
    else:
      lines.append("- None")

    return "\n".join(lines).rstrip() + "\n"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    summary = _build_summary(_load_queue())
    out_json = json.dumps(summary, indent=2, sort_keys=True) + "\n"
    out_md = _render_md(summary)

    if args.check:
      if not OUT_JSON.exists() or not OUT_MD.exists():
        _fail("replication SLA artifacts missing; run generator")
      if OUT_JSON.read_text(encoding="utf-8") != out_json:
        _fail("replication SLA JSON report out of date")
      if OUT_MD.read_text(encoding="utf-8") != out_md:
        _fail("replication SLA markdown report out of date")
      print("OK: research replication SLA report is in sync.")
      return 0

    OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
    OUT_MD.parent.mkdir(parents=True, exist_ok=True)
    OUT_JSON.write_text(out_json, encoding="utf-8")
    OUT_MD.write_text(out_md, encoding="utf-8")
    print(f"Updated {OUT_JSON} and {OUT_MD}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
