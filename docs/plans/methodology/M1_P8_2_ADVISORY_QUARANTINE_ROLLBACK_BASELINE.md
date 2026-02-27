# M1-P8-2 Advisory Quarantine + Rollback Independence Baseline

## Objective
Enforce deterministic advisory quarantine controls with rollback paths that remain independent from model rollback.

## Baseline Artifacts
- Advisory quarantine config: `configs/runtime/advisory_quarantine_rollback_independence.json`
- Advisory quarantine report generator/check: `scripts/runtime/generate_advisory_quarantine_rollback_report.py`
- Advisory quarantine report JSON: `docs/plans/methodology/MASTER_PLAN_ADVISORY_QUARANTINE_ROLLBACK_REPORT.json`
- Advisory quarantine report Markdown: `docs/plans/methodology/MASTER_PLAN_ADVISORY_QUARANTINE_ROLLBACK_REPORT.md`

## Pass Contract
1. Config format valid (`version = v1`, deterministic `evaluation_at`, explicit quarantine/rollback policy).
2. All advisory sources run in `shadow`/`quarantine` mode while validation is active.
3. All advisory sources expose rollback paths.
4. Advisory rollback is independent from model rollback for all sources.
5. Report `verdict` is `PASS`.

## CI Wiring
- `Execution Board Guard` runs advisory quarantine report in `--check` mode.

This baseline moves M1-P8-2 into active execution with deterministic advisory quarantine and rollback-independence evidence.
