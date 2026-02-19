# AVRAI Autopilot

Single-folder supervised autopilot for Master Plan execution.

Everything autopilot-related lives under `autopilot/`:
- Python runner
- queue + ledger + state
- milestone snapshots
- human-in-the-loop escalation docs
- templates + usage docs

## Quick Start

1. Initialize queue from `docs/EXECUTION_BOARD.csv`:
```bash
python3 autopilot/orchestrator.py init --force --phase P1
```

2. Run supervised autopilot cycle:
```bash
python3 autopilot/orchestrator.py run --resume --phase P1
```

3. Check status:
```bash
python3 autopilot/orchestrator.py status
```

## Commands

- `python3 autopilot/orchestrator.py init [--force] [--phase P# ...]`
  - Reads execution board and fills queue with eligible milestones.
  - Optional `--phase` limits queueing to selected phase IDs.
  - Enforces phase branch structure from `autopilot/config.json` (`phase{phase}_work` by default).

- `python3 autopilot/orchestrator.py run [--resume] [--max N] [--phase P# ...]`
  - Runs guard cycle per queued milestone.
  - Expands each milestone's Master Plan subsection references into subtask units.
  - Writes milestone snapshots including expanded subtasks and linked docs.
  - Writes a Codex execution brief per milestone under `autopilot/snapshots/` with:
    - what to build
    - what not to build
    - approach + validation gates
  - Emits subtask-level events in the run ledger (`subtask_started`, `subtask_completed`, `subtask_blocked`).
  - On failure, writes escalation doc to `autopilot/hitl/open/`.
  - Continues to next queued milestone (up to run max).

- `python3 autopilot/orchestrator.py resolve --milestone M#-P#-# --note "..." [--requeue]`
  - Marks blocked item resolved.
  - Writes resolution doc under `autopilot/hitl/resolved/`.
  - Optionally puts milestone back into queue.

- `python3 autopilot/orchestrator.py status`
  - Prints queue counts + last run metadata.

## Human In The Loop Flow

When a blocking issue occurs, autopilot writes:
- `autopilot/hitl/open/<timestamp>_<milestone>_<slug>.md`

That doc includes:
- run context
- failure details
- recommended actions
- exact resume command

After fixing, run:
```bash
python3 autopilot/orchestrator.py resolve --milestone <ID> --note "fixed" --requeue
python3 autopilot/orchestrator.py run --resume
```

## Slack Notifications (Optional)

Set webhook env var matching `autopilot/config.json`:
```bash
export AUTOPILOT_SLACK_WEBHOOK='https://hooks.slack.com/services/...'
```

Autopilot posts blocked-run alerts if this is set.

## Safety Model

- No destructive git operations.
- Requires clean working tree by default.
- Requires phase-correct branch naming for each milestone (`phase{phase}_work` or child branch).
- Requires upstream tracking branch for push readiness.
- Blocks milestone progress if Master Plan refs cannot be expanded/resolved.
- Never edits outside `autopilot/` unless explicit guard commands do so.
- Records every event in `autopilot/queue/run_ledger.jsonl`.

## Scope Guidance

- For strict Phase 1 execution, always include `--phase P1` on both `init` and `run`.
- Without phase scoping, autopilot orders milestones by status/priority and may include cross-phase ready items.
- Before running a phase milestone, switch to that phase branch (example: `phase1_work` for Phase 1).

## Files

- `autopilot/config.json`
- `autopilot/orchestrator.py`
- `autopilot/run.sh`
- `autopilot/queue/milestones_queue.json`
- `autopilot/queue/blocked_queue.json`
- `autopilot/queue/run_ledger.jsonl`
- `autopilot/state/runtime_state.json`
- `autopilot/hitl/open/`
- `autopilot/hitl/resolved/`
- `autopilot/milestones/`
- `autopilot/snapshots/`
- `autopilot/templates/`
