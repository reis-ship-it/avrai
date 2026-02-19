#!/usr/bin/env python3
"""Supervised Master Plan autopilot orchestrator.

This runner is intentionally conservative:
- keeps all autopilot state under ./autopilot
- records every run event in queue/run_ledger.jsonl
- writes a new escalation doc for every blocking issue
- never force-resets or rewrites git history
"""

from __future__ import annotations

import argparse
import csv
import json
import os
import re
import shlex
import subprocess
import sys
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any
from urllib import request

ROOT = Path(__file__).resolve().parent.parent
AUTOPILOT_DIR = ROOT / "autopilot"
CONFIG_PATH = AUTOPILOT_DIR / "config.json"
QUEUE_PATH = AUTOPILOT_DIR / "queue" / "milestones_queue.json"
BLOCKED_PATH = AUTOPILOT_DIR / "queue" / "blocked_queue.json"
LEDGER_PATH = AUTOPILOT_DIR / "queue" / "run_ledger.jsonl"
STATE_PATH = AUTOPILOT_DIR / "state" / "runtime_state.json"
MILESTONE_DIR = AUTOPILOT_DIR / "milestones"
SNAPSHOT_DIR = AUTOPILOT_DIR / "snapshots"

PRIORITY_RANK = {"Critical": 0, "High": 1, "Medium": 2, "Low": 3}


@dataclass
class Milestone:
    milestone_id: str
    phase: str
    name: str
    status: str
    priority: str
    dependencies: list[str]
    prd_ids: str
    master_refs: str
    architecture_spot: str


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


def utc_stamp() -> str:
    return utc_now().strftime("%Y%m%d_%H%M%S")


def utc_iso() -> str:
    return utc_now().replace(microsecond=0).isoformat()


def slug(text: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")[:80]


def read_json(path: Path, default: Any) -> Any:
    if not path.exists():
        return default
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def write_json(path: Path, payload: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as f:
        json.dump(payload, f, indent=2, ensure_ascii=True)
        f.write("\n")


def append_ledger(event: dict[str, Any]) -> None:
    event.setdefault("timestamp", utc_iso())
    LEDGER_PATH.parent.mkdir(parents=True, exist_ok=True)
    with LEDGER_PATH.open("a", encoding="utf-8") as f:
        f.write(json.dumps(event, ensure_ascii=True) + "\n")


def run_cmd(cmd: str, cwd: Path = ROOT) -> tuple[int, str, str]:
    proc = subprocess.run(
        cmd,
        cwd=str(cwd),
        shell=True,
        text=True,
        capture_output=True,
    )
    return proc.returncode, proc.stdout.strip(), proc.stderr.strip()


def current_branch() -> str:
    rc, out, _ = run_cmd("git rev-parse --abbrev-ref HEAD")
    return out if rc == 0 else "unknown"


def git_is_clean() -> bool:
    rc, out, _ = run_cmd("git status --porcelain")
    return rc == 0 and out == ""


def load_config() -> dict[str, Any]:
    cfg = read_json(CONFIG_PATH, {})
    if not cfg:
        raise RuntimeError(f"Missing config: {CONFIG_PATH}")
    return cfg


def split_deps(text: str) -> list[str]:
    if not text or text.strip().lower() == "none":
        return []
    parts = re.split(r"[;,]\s*", text.strip())
    return [p for p in (s.strip() for s in parts) if p]


def load_milestones(csv_path: Path) -> list[Milestone]:
    milestones: list[Milestone] = []
    with csv_path.open("r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            if row.get("type", "").strip() != "milestone":
                continue
            milestones.append(
                Milestone(
                    milestone_id=row.get("id", "").strip(),
                    phase=row.get("phase", "").strip(),
                    name=row.get("name_or_scope", "").strip(),
                    status=row.get("status", "").strip(),
                    priority=row.get("priority", "High").strip() or "High",
                    dependencies=split_deps(row.get("dependencies", "")),
                    prd_ids=row.get("prd_ids", "").strip(),
                    master_refs=row.get("master_plan_refs", "").strip(),
                    architecture_spot=row.get("architecture_spot", "").strip(),
                )
            )
    return milestones


def dependencies_satisfied(m: Milestone, by_id: dict[str, Milestone]) -> bool:
    for dep in m.dependencies:
        dep_row = by_id.get(dep)
        if dep_row is None:
            return False
        if dep_row.status != "Done":
            return False
    return True


def eligible_milestones(milestones: list[Milestone]) -> list[Milestone]:
    by_id = {m.milestone_id: m for m in milestones}
    candidates = [
        m
        for m in milestones
        if m.status in {"Ready", "In Progress"} and dependencies_satisfied(m, by_id)
    ]
    return sorted(
        candidates,
        key=lambda m: (
            0 if m.status == "In Progress" else 1,
            PRIORITY_RANK.get(m.priority, 9),
            m.milestone_id,
        ),
    )


def ensure_queue_from_board(force: bool = False) -> dict[str, Any]:
    cfg = load_config()
    csv_path = ROOT / cfg["execution_board_csv"]
    milestones = load_milestones(csv_path)
    candidates = eligible_milestones(milestones)

    queue = read_json(
        QUEUE_PATH,
        {"queued": [], "in_progress": [], "blocked": [], "completed": []},
    )

    if force:
        queue = {"queued": [], "in_progress": [], "blocked": [], "completed": []}

    seen = set(queue["queued"] + queue["in_progress"] + queue["blocked"] + queue["completed"])
    for m in candidates:
        if m.milestone_id not in seen:
            queue["queued"].append(m.milestone_id)

    write_json(QUEUE_PATH, queue)
    return queue


def save_state(**kwargs: Any) -> None:
    state = read_json(
        STATE_PATH,
        {
            "last_run_at": None,
            "last_run_id": None,
            "last_status": "never-run",
            "last_error": None,
        },
    )
    state.update(kwargs)
    write_json(STATE_PATH, state)


def write_milestone_snapshot(m: Milestone) -> Path:
    MILESTONE_DIR.mkdir(parents=True, exist_ok=True)
    p = MILESTONE_DIR / f"{m.milestone_id}.md"
    text = (
        f"# Milestone Snapshot: {m.milestone_id}\n\n"
        f"- Name: {m.name}\n"
        f"- Phase: {m.phase}\n"
        f"- Status: {m.status}\n"
        f"- Priority: {m.priority}\n"
        f"- Dependencies: {', '.join(m.dependencies) if m.dependencies else 'none'}\n"
        f"- PRD IDs: {m.prd_ids or 'none'}\n"
        f"- Master Plan refs: {m.master_refs or 'none'}\n"
        f"- Architecture spot: {m.architecture_spot or 'none'}\n"
        f"- Captured at (UTC): {utc_iso()}\n"
    )
    p.write_text(text, encoding="utf-8")
    return p


def notify_slack(cfg: dict[str, Any], message: str) -> None:
    webhook_env = cfg.get("notifications", {}).get("slack_webhook_env", "")
    if not webhook_env:
        return
    webhook = os.getenv(webhook_env)
    if not webhook:
        return
    payload = json.dumps({"text": message}).encode("utf-8")
    req = request.Request(
        webhook,
        data=payload,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        request.urlopen(req, timeout=8)  # noqa: S310
    except Exception:
        # Notifications should never crash orchestration.
        pass


def write_escalation_doc(
    cfg: dict[str, Any],
    run_id: str,
    milestone_id: str,
    summary: str,
    details: str,
    actions: list[str],
) -> Path:
    open_dir = ROOT / cfg["escalation"]["open_dir"]
    open_dir.mkdir(parents=True, exist_ok=True)
    ts = utc_stamp()
    branch = current_branch()
    filename = f"{ts}_{milestone_id}_{slug(summary)}.md"
    path = open_dir / filename

    action_lines = "\n".join(f"- {a}" for a in actions)
    body = (
        f"# Autopilot Escalation: {summary}\n\n"
        f"## Summary\n{summary}\n\n"
        f"## Context\n"
        f"- Run ID: `{run_id}`\n"
        f"- Milestone: `{milestone_id}`\n"
        f"- Branch: `{branch}`\n"
        f"- Timestamp (UTC): `{utc_iso()}`\n\n"
        f"## Failure Details\n```\n{details}\n```\n\n"
        f"## Recommended Actions\n{action_lines}\n\n"
        f"## Resume Command\n```bash\npython3 autopilot/orchestrator.py run --resume\n```\n"
    )
    path.write_text(body, encoding="utf-8")
    return path


def update_queue(queue: dict[str, Any], milestone_id: str, src: str, dst: str) -> None:
    if milestone_id in queue[src]:
        queue[src].remove(milestone_id)
    if milestone_id not in queue[dst]:
        queue[dst].append(milestone_id)


def run_guards(cfg: dict[str, Any]) -> tuple[bool, str]:
    guards = cfg.get("guards", {})
    if not guards.get("enabled", True):
        return True, "guards disabled"

    commands = guards.get("commands", [])
    for cmd in commands:
        rc, out, err = run_cmd(cmd)
        if rc != 0:
            detail = (
                f"Guard failed: {cmd}\n"
                f"exit={rc}\n"
                f"stdout:\n{out or '<empty>'}\n\n"
                f"stderr:\n{err or '<empty>'}"
            )
            return False, detail
    return True, "all guards passed"


def handle_block(
    cfg: dict[str, Any],
    run_id: str,
    queue: dict[str, Any],
    milestone_id: str,
    reason: str,
    details: str,
) -> None:
    update_queue(queue, milestone_id, "in_progress", "blocked")
    write_json(QUEUE_PATH, queue)

    blocked = read_json(BLOCKED_PATH, {"blocked": []})
    blocked["blocked"].append(
        {
            "milestone_id": milestone_id,
            "reason": reason,
            "details": details,
            "timestamp": utc_iso(),
            "run_id": run_id,
        }
    )
    write_json(BLOCKED_PATH, blocked)

    doc = write_escalation_doc(
        cfg,
        run_id=run_id,
        milestone_id=milestone_id,
        summary=reason,
        details=details,
        actions=[
            "Apply the fix on a scoped branch/worktree.",
            "Re-run required guards/tests.",
            "Run: python3 autopilot/orchestrator.py resolve --milestone " + milestone_id + " --requeue --note \"fixed\"",
        ],
    )

    append_ledger(
        {
            "event": "milestone_blocked",
            "run_id": run_id,
            "milestone_id": milestone_id,
            "reason": reason,
            "doc": str(doc),
        }
    )
    notify_slack(cfg, f"Autopilot blocked: {milestone_id} - {reason}\n{doc}")


def do_run(resume: bool = False, max_count: int | None = None) -> int:
    cfg = load_config()
    run_id = f"run_{utc_stamp()}"
    save_state(last_run_id=run_id, last_run_at=utc_iso(), last_status="running", last_error=None)

    queue = ensure_queue_from_board(force=not resume)

    if cfg.get("git", {}).get("require_clean_worktree", True) and not git_is_clean():
        details = "Working tree is not clean. Autopilot requires a clean workspace for safe orchestration."
        doc = write_escalation_doc(
            cfg,
            run_id=run_id,
            milestone_id="workspace",
            summary="Dirty working tree blocks autopilot run",
            details=details,
            actions=[
                "Commit or stash local changes.",
                "Re-run: python3 autopilot/orchestrator.py run --resume",
            ],
        )
        append_ledger({"event": "run_blocked", "run_id": run_id, "reason": "dirty_worktree", "doc": str(doc)})
        save_state(last_status="blocked", last_error="dirty_worktree")
        notify_slack(cfg, f"Autopilot blocked: dirty worktree\n{doc}")
        print(f"Blocked: dirty working tree. See {doc}")
        return 2

    csv_path = ROOT / cfg["execution_board_csv"]
    milestones = {m.milestone_id: m for m in load_milestones(csv_path)}

    limit = max_count if max_count is not None else int(cfg.get("max_milestones_per_run", 1))
    processed = 0

    while queue["queued"] and processed < limit:
        milestone_id = queue["queued"].pop(0)
        m = milestones.get(milestone_id)
        if m is None:
            append_ledger({"event": "queue_skip_missing", "run_id": run_id, "milestone_id": milestone_id})
            continue

        queue["in_progress"].append(milestone_id)
        write_json(QUEUE_PATH, queue)

        snapshot_path = write_milestone_snapshot(m)
        append_ledger(
            {
                "event": "milestone_started",
                "run_id": run_id,
                "milestone_id": milestone_id,
                "snapshot": str(snapshot_path),
            }
        )

        ok, detail = run_guards(cfg)
        if not ok:
            handle_block(
                cfg,
                run_id=run_id,
                queue=queue,
                milestone_id=milestone_id,
                reason="Guard failure",
                details=detail,
            )
            processed += 1
            continue

        update_queue(queue, milestone_id, "in_progress", "completed")
        write_json(QUEUE_PATH, queue)
        append_ledger(
            {
                "event": "milestone_completed",
                "run_id": run_id,
                "milestone_id": milestone_id,
                "note": "Autopilot guard cycle passed; ready for implementation/PR loop.",
            }
        )
        processed += 1

    save_state(last_status="ok", last_error=None)
    print(
        f"Run complete: {run_id}\n"
        f"queued={len(queue['queued'])} in_progress={len(queue['in_progress'])} "
        f"blocked={len(queue['blocked'])} completed={len(queue['completed'])}"
    )
    return 0


def do_status() -> int:
    queue = read_json(
        QUEUE_PATH,
        {"queued": [], "in_progress": [], "blocked": [], "completed": []},
    )
    state = read_json(STATE_PATH, {})

    print("Autopilot status")
    print(f"- last_run_id: {state.get('last_run_id')}")
    print(f"- last_run_at: {state.get('last_run_at')}")
    print(f"- last_status: {state.get('last_status')}")
    print(f"- queued: {len(queue['queued'])}")
    print(f"- in_progress: {len(queue['in_progress'])}")
    print(f"- blocked: {len(queue['blocked'])}")
    print(f"- completed: {len(queue['completed'])}")

    if queue["queued"]:
        print("- next_queued:")
        for m in queue["queued"][:5]:
            print(f"  - {m}")

    return 0


def do_resolve(milestone_id: str, note: str, requeue: bool) -> int:
    queue = read_json(
        QUEUE_PATH,
        {"queued": [], "in_progress": [], "blocked": [], "completed": []},
    )
    blocked = read_json(BLOCKED_PATH, {"blocked": []})

    if milestone_id in queue["blocked"]:
        queue["blocked"].remove(milestone_id)
        if requeue and milestone_id not in queue["queued"]:
            queue["queued"].append(milestone_id)
        write_json(QUEUE_PATH, queue)

    kept = []
    moved = []
    for item in blocked.get("blocked", []):
        if item.get("milestone_id") == milestone_id:
            moved.append(item)
        else:
            kept.append(item)
    blocked["blocked"] = kept
    write_json(BLOCKED_PATH, blocked)

    resolved_dir = AUTOPILOT_DIR / "hitl" / "resolved"
    resolved_dir.mkdir(parents=True, exist_ok=True)
    out = resolved_dir / f"{utc_stamp()}_{milestone_id}_resolved.md"
    out.write_text(
        f"# Resolved: {milestone_id}\n\n"
        f"- Resolved at (UTC): {utc_iso()}\n"
        f"- Requeued: {'yes' if requeue else 'no'}\n"
        f"- Note: {note}\n\n"
        f"## Prior Block Records\n"
        f"```json\n{json.dumps(moved, indent=2)}\n```\n",
        encoding="utf-8",
    )

    append_ledger(
        {
            "event": "milestone_resolved",
            "milestone_id": milestone_id,
            "requeue": requeue,
            "note": note,
            "resolved_doc": str(out),
        }
    )
    print(f"Resolved {milestone_id}. Doc: {out}")
    return 0


def do_init(force: bool) -> int:
    queue = ensure_queue_from_board(force=force)
    save_state(last_run_id=None, last_run_at=utc_iso(), last_status="initialized", last_error=None)
    append_ledger({"event": "queue_initialized", "force": force, "queued": len(queue["queued"])})
    print(
        f"Initialized queue (force={force}): queued={len(queue['queued'])}, "
        f"blocked={len(queue['blocked'])}, completed={len(queue['completed'])}"
    )
    return 0


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Supervised Master Plan autopilot")
    sub = p.add_subparsers(dest="cmd", required=True)

    s_init = sub.add_parser("init", help="Initialize/refresh queue from execution board")
    s_init.add_argument("--force", action="store_true", help="Reset queue before refill")

    s_run = sub.add_parser("run", help="Run autopilot cycle")
    s_run.add_argument("--resume", action="store_true", help="Resume existing queue")
    s_run.add_argument("--max", type=int, default=None, help="Override max milestones this run")

    sub.add_parser("status", help="Show autopilot status")

    s_resolve = sub.add_parser("resolve", help="Resolve blocked milestone")
    s_resolve.add_argument("--milestone", required=True, help="Milestone ID (e.g., M2-P1-1)")
    s_resolve.add_argument("--note", required=True, help="Resolution note")
    s_resolve.add_argument("--requeue", action="store_true", help="Move milestone back to queue")

    return p.parse_args()


def main() -> int:
    args = parse_args()
    if args.cmd == "init":
        return do_init(force=args.force)
    if args.cmd == "run":
        return do_run(resume=args.resume, max_count=args.max)
    if args.cmd == "status":
        return do_status()
    if args.cmd == "resolve":
        return do_resolve(args.milestone, args.note, args.requeue)
    print(f"Unknown command: {args.cmd}", file=sys.stderr)
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
