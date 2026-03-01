# M10-P6-1 URK Self-Healing Recovery Kernel Baseline

## Objective
Govern self-healing behavior so detect-contain-recover and rollback paths stay deterministic with zero uncontained or failed recovery incidents.

## Baseline Artifacts
- Controls config: `configs/runtime/urk_self_healing_recovery_controls.json`
- Report generator/check: `scripts/runtime/generate_urk_self_healing_recovery_report.py`
- Report JSON: `docs/plans/methodology/MASTER_PLAN_URK_SELF_HEALING_RECOVERY_REPORT.json`
- Report Markdown: `docs/plans/methodology/MASTER_PLAN_URK_SELF_HEALING_RECOVERY_REPORT.md`
- Contract: `lib/core/services/urk_self_healing_recovery_contract.dart`
- Tests: `test/unit/services/urk_self_healing_recovery_contract_test.dart`

## Pass Contract
1. Detect-contain-recover and rollback coverage meet thresholds.
2. Uncontained incidents and failed recoveries remain within threshold bounds.
3. Contract tests pass and report `verdict` is `PASS`.

## CI Wiring
- `Execution Board Guard` runs this report in `--check` mode.
