# GitHub Enforcement Setup (Execution Board + Traceability)

Purpose: make execution-governance rules automatic for all plan-derived work.

Applies to:
- `docs/MASTER_PLAN.md`
- `docs/EXECUTION_BOARD.csv`
- `docs/EXECUTION_BOARD.md`
- `docs/STATUS_WEEKLY.md`

## 1) Required Workflows

Ensure these workflows exist and are green on pull requests:

1. `Execution Board Guard`
   - File: `.github/workflows/execution-board-guard.yml`
   - Check name: `Execution Board Guard / execution-board-check`
   - Enforces:
     - board sync validity (`dart run tool/update_execution_board.dart --check`)
     - phase coverage parity with `docs/MASTER_PLAN.md`

2. `PRD Traceability Guard`
   - File: `.github/workflows/prd-traceability-guard.yml`
   - Check name: `PRD Traceability Guard / traceability`
   - Enforces PR metadata includes:
    - `PRD-###`
    - execution milestone ID format `M#-P#-#` (legacy `CARD-<number>` temporarily allowed)

Optional PR quality workflow:
3. `Quick Tests`
   - File: `.github/workflows/quick-tests.yml`
   - Use as required check only if you want stricter merge quality gates.

## 1.1 Noise-Controlled Workflow Policy (Recommended)

To avoid CI email spam and non-actionable failures, this repo is configured with:
- PR-focused automatic workflows for governance and quality.
- Manual-only (`workflow_dispatch`) for heavy/legacy/operational workflows.

Manual-only workflows (intentionally not automatic):
- `SPOTS Background Testing`
- `SPOTS Background Testing (Optimized)`
- `Auto-Apply Background Agent Fixes`
- `Storage health`
- `Deploy SPOTS`

PR-triggered workflows (automatic):
- `Execution Board Guard`
- `PRD Traceability Guard`
- `Architecture Placement Guard`
- `Quick Tests`
- `Test Coverage Report` (PR + manual)
- `Test Quality Check` (PR path-filtered + manual)

## 2) Branch Protection (GitHub UI)

Repository settings:
1. `Settings` -> `Branches` -> `Add branch protection rule`
2. Branch name pattern: `main`
3. Enable:
   - `Require a pull request before merging`
   - `Require status checks to pass before merging`
   - `Require branches to be up to date before merging`
4. In required checks, add:
   - `Execution Board Guard / execution-board-check`
   - `PRD Traceability Guard / traceability`
5. Optional required checks:
   - `Quick Tests / quick-unit-tests`
5. Optional but recommended:
   - `Require conversation resolution before merging`
   - `Include administrators`
   - `Restrict who can push to matching branches`

## 3) PR Author Checklist

Every PR touching plan-derived work must:
1. Reference PRD IDs (`PRD-###`)
2. Reference execution milestone IDs (`M#-P#-#`)
3. Reference master plan tasks (`X.Y.Z`)
4. Update evidence links for milestones moved to `Done`
5. Pass `Execution Board Guard` and `PRD Traceability Guard`

Template:
- `.github/pull_request_template.md` already includes these fields.

## 4) Local Pre-PR Commands

Run before opening or updating a PR:

```bash
dart run tool/update_execution_board.dart
dart run tool/update_execution_board.dart --check
python3 scripts/validate_pr_traceability.py \
  --title "PRD-123 M1-P7-1" \
  --body "phase/task refs: 7.4.2, 10.9.1" \
  --require-execution-id --allow-legacy-card
```

## 5) Operating Rules (Phase 1-N)

1. `docs/EXECUTION_BOARD.csv` is the canonical execution state.
2. `docs/EXECUTION_BOARD.md` is generated/synced output.
3. No plan-derived work merges without milestone mapping.
4. No milestone transitions to `Done` without evidence.
5. New plan phases require same-PR board expansion:
phase row + milestone row(s) + risk + gate criteria.

## 6) Troubleshooting

1. Check fails with "board out of sync":
   - Run: `dart run tool/update_execution_board.dart`
   - Commit regenerated `docs/EXECUTION_BOARD.md`

2. Check fails with "missing phase row":
   - Add missing phase row to `docs/EXECUTION_BOARD.csv`
   - Re-run sync/check commands

3. Traceability check fails:
   - Add `PRD-###` and `M#-P#-#` IDs to PR title/body
   - Keep formatting exact
