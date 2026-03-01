# M5-P3-2 Operational Canary + Rollback Automation Baseline

## Objective
Automate canary rollback-drill checks so conviction enforcement can be safely disabled (fail-closed) when canary thresholds are breached.

## Baseline Artifacts
- Canary config: `configs/runtime/conviction_gate_canary_rollout.json`
- Rollback drill fixture: `configs/runtime/conviction_gate_canary_rollback_drill_fixture.json`
- Rollback drill generator/check: `scripts/runtime/generate_conviction_canary_rollback_drill_report.py`
- Rollback drill report JSON: `docs/plans/methodology/MASTER_PLAN_3_PRONG_CANARY_ROLLBACK_DRILL_REPORT.json`
- Rollback drill report Markdown: `docs/plans/methodology/MASTER_PLAN_3_PRONG_CANARY_ROLLBACK_DRILL_REPORT.md`

## Pass Contract
1. At least one canary incident in drill fixture requires rollback.
2. Rollback profile must be fail-closed for both required flags:
   - `conviction_gate_production_enforcement`
   - `conviction_gate_high_impact_enforcement`
3. Fail-closed means:
   - `enabled = false`
   - `rolloutPercentage = 0`
   - `targetUsers = []`
4. Drill report verdict must be `PASS`.

## CI Wiring
- `Execution Board Guard` runs rollback drill report generator in `--check` mode.

This baseline sets M5-P3-2 to active implementation state and provides deterministic rollback evidence.
