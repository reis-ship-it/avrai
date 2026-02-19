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
python3 autopilot/orchestrator.py init --force
```

2. Run supervised autopilot cycle:
```bash
./autopilot/run.sh
```

3. Check status:
```bash
python3 autopilot/orchestrator.py status
```

## Commands

- `python3 autopilot/orchestrator.py init [--force]`
  - Reads execution board and fills queue with eligible milestones.

- `python3 autopilot/orchestrator.py run [--resume] [--max N]`
  - Runs guard cycle per queued milestone.
  - Writes milestone snapshots.
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
- Never edits outside `autopilot/` unless explicit guard commands do so.
- Records every event in `autopilot/queue/run_ledger.jsonl`.

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
