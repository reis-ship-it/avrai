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
     - architecture mapping + spot registry validity (`scripts/validate_architecture_placement.py`)
     - generated architecture artifacts are committed

2. `PRD Traceability Guard`
   - File: `.github/workflows/prd-traceability-guard.yml`
   - Check name: `PRD Traceability Guard / traceability`
   - Enforces PR metadata includes:
     - `PRD-###`
     - exactly one execution milestone ID format `M#-P#-#`
     - at least one master plan subsection reference `X.Y.Z`
     - every non-merge PR commit includes the same milestone ID + at least one `X.Y.Z` reference

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
6. Optional but recommended:
   - `Require conversation resolution before merging`
   - `Include administrators`
   - `Restrict who can push to matching branches`

Notes:
- You do not need to add `Architecture Placement Guard / architecture-placement` as a separate required check if `execution-board-check` is required, because architecture placement validation is now part of `execution-board-check`.
- Keeping `Architecture Placement Guard` enabled is still useful for standalone troubleshooting visibility.

## 3) PR Author Checklist

Every PR touching plan-derived work must:
1. Reference PRD IDs (`PRD-###`)
2. Reference exactly one execution milestone ID (`M#-P#-#`)
3. Reference master plan subsection IDs (`X.Y.Z`)
4. Ensure every non-merge commit message includes the same milestone ID + at least one `X.Y.Z` reference
5. Update evidence links for milestones moved to `Done`
6. Pass `Execution Board Guard` and `PRD Traceability Guard`

Template:
- `.github/pull_request_template.md` already includes these fields.

## 4) Local Pre-PR Commands

Run before opening or updating a PR:

```bash
dart run tool/update_execution_board.dart
dart run tool/update_execution_board.dart --check
python3 scripts/generate_master_plan_file_mapping.py
python3 scripts/generate_architecture_spots_registry.py
python3 scripts/validate_architecture_placement.py
python3 scripts/validate_pr_traceability.py \
  --title "PRD-123 M1-P7-1" \
  --body "phase/task refs: 7.4.2, 10.9.1" \
  --require-execution-id \
  --require-single-milestone \
  --require-master-plan-ref

# Optional full boundary check against current branch:
python3 scripts/validate_pr_traceability.py \
  --title "PRD-123 M1-P7-1" \
  --body "phase/task refs: 7.4.2, 10.9.1" \
  --require-execution-id \
  --require-single-milestone \
  --require-master-plan-ref \
  --validate-commit-boundaries \
  --base-sha origin/main \
  --head-sha HEAD
```

## 5) Operating Rules (Phase 1-N)

1. `docs/EXECUTION_BOARD.csv` is the canonical execution state.
2. `docs/EXECUTION_BOARD.md` is generated/synced output.
3. No plan-derived work merges without exactly one milestone mapping per PR.
4. Every non-merge commit must include milestone ID + `X.Y.Z` subsection reference.
5. No milestone transitions to `Done` without evidence.
6. New plan phases require same-PR board expansion:
phase row + milestone row(s) + risk + gate criteria.

## 6) Troubleshooting

1. Check fails with "board out of sync":
   - Run: `dart run tool/update_execution_board.dart`
   - Commit regenerated `docs/EXECUTION_BOARD.md`

2. Check fails with "missing phase row":
   - Add missing phase row to `docs/EXECUTION_BOARD.csv`
   - Re-run sync/check commands

3. Traceability check fails:
   - Add `PRD-###` and exactly one `M#-P#-#` ID to PR title/body
   - Add at least one `X.Y.Z` reference to PR title/body
   - Ensure each non-merge commit message contains the same milestone + an `X.Y.Z` reference
   - Keep formatting exact
