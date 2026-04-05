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
DOCS_DIR = ROOT / "docs"
CONFIG_PATH = AUTOPILOT_DIR / "config.json"
QUEUE_PATH = AUTOPILOT_DIR / "queue" / "milestones_queue.json"
BLOCKED_PATH = AUTOPILOT_DIR / "queue" / "blocked_queue.json"
LEDGER_PATH = AUTOPILOT_DIR / "queue" / "run_ledger.jsonl"
STATE_PATH = AUTOPILOT_DIR / "state" / "runtime_state.json"
MILESTONE_DIR = AUTOPILOT_DIR / "milestones"
SNAPSHOT_DIR = AUTOPILOT_DIR / "snapshots"
MASTER_PLAN_PATH = DOCS_DIR / "MASTER_PLAN.md"
MASTER_PLAN_TRACKER_PATH = DOCS_DIR / "MASTER_PLAN_TRACKER.md"
ARCHITECTURE_INDEX_PATH = DOCS_DIR / "plans" / "architecture" / "ARCHITECTURE_INDEX.md"

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


def git_upstream_branch() -> str:
    rc, out, _ = run_cmd("git rev-parse --abbrev-ref --symbolic-full-name @{u}")
    return out if rc == 0 else ""


def expected_phase_root_branch(cfg: dict[str, Any], phase: str) -> str:
    git_cfg = cfg.get("git", {})
    template = git_cfg.get("phase_root_template", "phase{phase}_work")
    phase_token = normalize_phase_token(phase)
    return template.format(phase=phase_token)


def branch_matches_phase(cfg: dict[str, Any], branch: str, phase: str) -> bool:
    root = expected_phase_root_branch(cfg, phase)
    if branch == root:
        return True
    if cfg.get("git", {}).get("allow_phase_child_branches", True) and branch.startswith(root + "/"):
        return True
    return False


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


def normalize_phase_token(token: str) -> str:
    raw = token.strip().upper()
    if not raw:
        return ""
    if raw.startswith("P"):
        return raw[1:]
    return raw


def eligible_milestones(milestones: list[Milestone], phase_scope: set[str] | None = None) -> list[Milestone]:
    by_id = {m.milestone_id: m for m in milestones}
    candidates = [
        m
        for m in milestones
        if m.status in {"Ready", "In Progress"} and dependencies_satisfied(m, by_id)
        and (phase_scope is None or normalize_phase_token(m.phase) in phase_scope)
    ]
    return sorted(
        candidates,
        key=lambda m: (
            0 if m.status == "In Progress" else 1,
            PRIORITY_RANK.get(m.priority, 9),
            m.milestone_id,
        ),
    )


def ensure_queue_from_board(force: bool = False, phase_scope: set[str] | None = None) -> dict[str, Any]:
    cfg = load_config()
    csv_path = ROOT / cfg["execution_board_csv"]
    milestones = load_milestones(csv_path)
    candidates = eligible_milestones(milestones, phase_scope=phase_scope)

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


def parse_master_ref_tokens(text: str) -> list[str]:
    if not text:
        return []
    out: list[str] = []
    for token in re.split(r"[;,]", text):
        t = token.strip()
        if t:
            out.append(t)
    return out


def expand_ref_range(token: str) -> list[str]:
    t = token.strip()
    if "-" not in t:
        return [t] if t else []
    left, right = [x.strip() for x in t.split("-", 1)]
    if not left or not right:
        return [t]

    left_parts = left.split(".")
    right_parts = right.split(".")
    if len(left_parts) != len(right_parts):
        return [left, right]
    if not left_parts[-1].isdigit() or not right_parts[-1].isdigit():
        return [left, right]
    if left_parts[:-1] != right_parts[:-1]:
        return [left, right]

    start = int(left_parts[-1])
    end = int(right_parts[-1])
    if end < start:
        start, end = end, start
    prefix = left_parts[:-1]
    return [".".join(prefix + [str(i)]) for i in range(start, end + 1)]


def build_master_plan_index() -> dict[str, str]:
    if not MASTER_PLAN_PATH.exists():
        return {}
    idx: dict[str, str] = {}
    row_re = re.compile(r"^\|\s*([0-9]+(?:\.[0-9A-Za-z]+)+)\s*\|\s*(.*?)\s*\|")
    with MASTER_PLAN_PATH.open("r", encoding="utf-8") as f:
        for raw in f:
            m = row_re.match(raw)
            if not m:
                continue
            ref_id = m.group(1).strip()
            desc = re.sub(r"\s+", " ", re.sub(r"`|\*\*?", "", m.group(2))).strip()
            if ref_id and ref_id not in idx:
                idx[ref_id] = desc or "(no description)"
    return idx


def extract_doc_paths_from_text(text: str, base_dir: Path) -> list[str]:
    paths: list[str] = []
    for m in re.finditer(r"`((?:docs|autopilot|scripts|configs)/[^`]+)`", text):
        paths.append(m.group(1))
    for m in re.finditer(r"\[[^\]]+\]\(([^)]+)\)", text):
        link = m.group(1).strip()
        if not link or "://" in link or link.startswith("#"):
            continue
        resolved = (base_dir / link).resolve()
        try:
            rel = resolved.relative_to(ROOT).as_posix()
        except ValueError:
            continue
        if rel.startswith("docs/"):
            paths.append(rel)
    return paths


def related_docs_for_milestone(m: Milestone, expanded_refs: list[str]) -> list[str]:
    docs: set[str] = {
        "docs/MASTER_PLAN.md",
        "docs/EXECUTION_BOARD.csv",
        "docs/STATUS_WEEKLY.md",
        "docs/MASTER_PLAN_TRACKER.md",
        "docs/plans/architecture/ARCHITECTURE_INDEX.md",
        "docs/GITHUB_ENFORCEMENT_SETUP.md",
    }
    if (DOCS_DIR / "security" / "RED_TEAM_TEST_MATRIX.md").exists():
        docs.add("docs/security/RED_TEAM_TEST_MATRIX.md")

    if MASTER_PLAN_PATH.exists():
        mp_text = MASTER_PLAN_PATH.read_text(encoding="utf-8")
        docs.update(extract_doc_paths_from_text(mp_text, MASTER_PLAN_PATH.parent))
        for line in mp_text.splitlines():
            if any(ref in line for ref in expanded_refs):
                docs.update(extract_doc_paths_from_text(line, MASTER_PLAN_PATH.parent))

    if ARCHITECTURE_INDEX_PATH.exists():
        docs.update(
            extract_doc_paths_from_text(
                ARCHITECTURE_INDEX_PATH.read_text(encoding="utf-8"),
                ARCHITECTURE_INDEX_PATH.parent,
            )
        )

    if MASTER_PLAN_TRACKER_PATH.exists():
        phase_markers = {f"Phase {normalize_phase_token(m.phase)}", f"P{normalize_phase_token(m.phase)}"}
        for line in MASTER_PLAN_TRACKER_PATH.read_text(encoding="utf-8").splitlines():
            if any(marker in line for marker in phase_markers):
                docs.update(extract_doc_paths_from_text(line, MASTER_PLAN_TRACKER_PATH.parent))

    return sorted(path for path in docs if (ROOT / path).exists())


def expand_milestone_subtasks(master_refs: str) -> list[tuple[str, str]]:
    tokens = parse_master_ref_tokens(master_refs)
    expanded: list[str] = []
    for t in tokens:
        expanded.extend(expand_ref_range(t))
    unique_ids: list[str] = []
    seen: set[str] = set()
    for t in expanded:
        if t and t not in seen:
            seen.add(t)
            unique_ids.append(t)
    index = build_master_plan_index()
    return [(ref_id, index.get(ref_id, "(reference not found in MASTER_PLAN table rows)")) for ref_id in unique_ids]


def write_codex_plan_brief(
    run_id: str,
    m: Milestone,
    subtasks: list[tuple[str, str]],
    related_docs: list[str],
) -> Path:
    SNAPSHOT_DIR.mkdir(parents=True, exist_ok=True)
    path = SNAPSHOT_DIR / f"{utc_stamp()}_{m.milestone_id}_codex_plan.md"
    sub_lines = "\n".join(f"- `{sid}` {title}" for sid, title in subtasks) or "- none"
    doc_lines = "\n".join(f"- `{d}`" for d in related_docs) or "- none"
    text = (
        f"# Codex Execution Brief: {m.milestone_id}\n\n"
        f"- Run ID: `{run_id}`\n"
        f"- Milestone: `{m.milestone_id}`\n"
        f"- Phase: `{m.phase}`\n"
        f"- Branch: `{current_branch()}`\n"
        f"- Generated (UTC): `{utc_iso()}`\n\n"
        f"## Build Scope\n"
        f"{sub_lines}\n\n"
        f"## Do Not Build\n"
        f"- Features or docs outside this milestone's Master Plan refs unless explicitly cross-linked in listed docs.\n"
        f"- Any unreferenced phase/subphase work not included in this milestone's scope.\n\n"
        f"## Approach\n"
        f"- Execute subtasks in listed order.\n"
        f"- Validate architecture placement + execution-board sync before milestone closure.\n"
        f"- Record blockers via HITL escalation and resume through `resolve --requeue`.\n\n"
        f"## Validation Gates\n"
        f"- `dart run tool/update_execution_board.dart --check`\n"
        f"- `python3 scripts/validate_architecture_placement.py`\n\n"
        f"## Linked Build Docs\n"
        f"{doc_lines}\n"
    )
    path.write_text(text, encoding="utf-8")
    return path


def milestone_governance_preflight(
    cfg: dict[str, Any],
    m: Milestone,
    subtasks: list[tuple[str, str]],
) -> tuple[bool, str]:
    issues: list[str] = []
    gov_cfg = cfg.get("governance", {})
    branch = current_branch()

    if cfg.get("git", {}).get("require_phase_branch", True):
        if not branch_matches_phase(cfg, branch, m.phase):
            expected = expected_phase_root_branch(cfg, m.phase)
            issues.append(
                f"branch_mismatch: current branch '{branch}' does not match phase branch '{expected}'"
            )

    if cfg.get("git", {}).get("require_upstream_tracking", True):
        upstream = git_upstream_branch()
        if not upstream:
            issues.append("missing_upstream: current branch has no upstream tracking branch")

    if gov_cfg.get("require_nonempty_master_refs", True) and not m.master_refs.strip():
        issues.append("missing_master_refs: milestone has no master_plan_refs")

    if gov_cfg.get("require_nonempty_subtasks", True) and not subtasks:
        issues.append("missing_subtasks: no subtask refs expanded from milestone")

    if gov_cfg.get("require_resolved_subtask_descriptions", True):
        unresolved = [sid for sid, title in subtasks if "reference not found" in title]
        if unresolved:
            issues.append("unresolved_subtasks: " + ", ".join(unresolved))

    if issues:
        return False, "\n".join(issues)
    return True, "governance checks passed"


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


def write_milestone_snapshot(
    m: Milestone,
    subtasks: list[tuple[str, str]],
    related_docs: list[str],
) -> Path:
    MILESTONE_DIR.mkdir(parents=True, exist_ok=True)
    p = MILESTONE_DIR / f"{m.milestone_id}.md"
    subtask_lines = "\n".join(f"- [ ] `{sid}` {title}" for sid, title in subtasks) if subtasks else "- none"
    doc_lines = "\n".join(f"- `{d}`" for d in related_docs) if related_docs else "- none"
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
        f"- Expanded subtasks: {len(subtasks)}\n"
        f"- Linked docs: {len(related_docs)}\n\n"
        f"## Subtask Expansion\n"
        f"{subtask_lines}\n\n"
        f"## Linked Build Docs\n"
        f"{doc_lines}\n"
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


def do_run(
    resume: bool = False,
    max_count: int | None = None,
    phase_scope: set[str] | None = None,
) -> int:
    cfg = load_config()
    run_id = f"run_{utc_stamp()}"
    save_state(last_run_id=run_id, last_run_at=utc_iso(), last_status="running", last_error=None)

    queue = ensure_queue_from_board(force=not resume, phase_scope=phase_scope)

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

        subtasks = expand_milestone_subtasks(m.master_refs)
        related_docs = related_docs_for_milestone(m, [sid for sid, _ in subtasks])
        snapshot_path = write_milestone_snapshot(m, subtasks=subtasks, related_docs=related_docs)
        plan_brief_path = write_codex_plan_brief(run_id=run_id, m=m, subtasks=subtasks, related_docs=related_docs)
        append_ledger(
            {
                "event": "milestone_started",
                "run_id": run_id,
                "milestone_id": milestone_id,
                "snapshot": str(snapshot_path),
                "codex_plan_brief": str(plan_brief_path),
                "subtask_count": len(subtasks),
                "related_doc_count": len(related_docs),
            }
        )
        for sid, _ in subtasks:
            append_ledger(
                {
                    "event": "subtask_started",
                    "run_id": run_id,
                    "milestone_id": milestone_id,
                    "subtask_id": sid,
                }
            )

        gov_ok, gov_detail = milestone_governance_preflight(cfg, m, subtasks)
        if not gov_ok:
            for sid, _ in subtasks:
                append_ledger(
                    {
                        "event": "subtask_blocked",
                        "run_id": run_id,
                        "milestone_id": milestone_id,
                        "subtask_id": sid,
                        "reason": "governance_preflight_failure",
                    }
                )
            handle_block(
                cfg,
                run_id=run_id,
                queue=queue,
                milestone_id=milestone_id,
                reason="Governance drift prevention check failed",
                details=gov_detail,
            )
            processed += 1
            continue

        ok, detail = run_guards(cfg)
        if not ok:
            for sid, _ in subtasks:
                append_ledger(
                    {
                        "event": "subtask_blocked",
                        "run_id": run_id,
                        "milestone_id": milestone_id,
                        "subtask_id": sid,
                        "reason": "guard_failure",
                    }
                )
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

        for sid, _ in subtasks:
            append_ledger(
                {
                    "event": "subtask_completed",
                    "run_id": run_id,
                    "milestone_id": milestone_id,
                    "subtask_id": sid,
                }
            )
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


def do_init(force: bool, phase_scope: set[str] | None = None) -> int:
    queue = ensure_queue_from_board(force=force, phase_scope=phase_scope)
    save_state(last_run_id=None, last_run_at=utc_iso(), last_status="initialized", last_error=None)
    append_ledger(
        {
            "event": "queue_initialized",
            "force": force,
            "queued": len(queue["queued"]),
            "phase_scope": sorted(phase_scope) if phase_scope else [],
        }
    )
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
    s_init.add_argument("--phase", action="append", default=[], help="Restrict to phase ID(s), e.g., P1")

    s_run = sub.add_parser("run", help="Run autopilot cycle")
    s_run.add_argument("--resume", action="store_true", help="Resume existing queue")
    s_run.add_argument("--max", type=int, default=None, help="Override max milestones this run")
    s_run.add_argument("--phase", action="append", default=[], help="Restrict queue build to phase ID(s), e.g., P1")

    sub.add_parser("status", help="Show autopilot status")

    s_resolve = sub.add_parser("resolve", help="Resolve blocked milestone")
    s_resolve.add_argument("--milestone", required=True, help="Milestone ID (e.g., M2-P1-1)")
    s_resolve.add_argument("--note", required=True, help="Resolution note")
    s_resolve.add_argument("--requeue", action="store_true", help="Move milestone back to queue")

    return p.parse_args()


def main() -> int:
    args = parse_args()
    if args.cmd == "init":
        phase_scope = {normalize_phase_token(p) for p in args.phase if normalize_phase_token(p)}
        return do_init(force=args.force, phase_scope=phase_scope if phase_scope else None)
    if args.cmd == "run":
        phase_scope = {normalize_phase_token(p) for p in args.phase if normalize_phase_token(p)}
        return do_run(resume=args.resume, max_count=args.max, phase_scope=phase_scope if phase_scope else None)
    if args.cmd == "status":
        return do_status()
    if args.cmd == "resolve":
        return do_resolve(args.milestone, args.note, args.requeue)
    print(f"Unknown command: {args.cmd}", file=sys.stderr)
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
