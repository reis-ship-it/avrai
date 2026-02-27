# M2-P4-1 Energy Function Safety and Regression Governance Baseline

## Objective
Enforce deterministic energy-function safety and regression governance so policy bounds and asymmetric-loss controls remain within threshold before promotion.

## Baseline Artifacts
- Energy safety/regression config: `configs/runtime/energy_function_safety_regression_controls.json`
- Energy safety/regression report generator/check: `scripts/runtime/generate_energy_function_safety_regression_report.py`
- Energy safety/regression report JSON: `docs/plans/methodology/MASTER_PLAN_ENERGY_FUNCTION_SAFETY_REGRESSION_REPORT.json`
- Energy safety/regression report Markdown: `docs/plans/methodology/MASTER_PLAN_ENERGY_FUNCTION_SAFETY_REGRESSION_REPORT.md`
- Energy safety contract: `lib/core/ml/energy_function_safety_contract.dart`
- Energy safety contract tests: `test/unit/ml/energy_function_safety_contract_test.dart`

## Pass Contract
1. Config format valid (`version = v1`, deterministic `evaluation_at`, valid thresholds).
2. Safety-bound violation rate remains within threshold.
3. Asymmetric-loss regression remains within configured no-regression threshold.
4. Negative outcome and model-failure loss weights meet policy floor and ordering.
5. Contract tests pass and report `verdict` is `PASS`.

## CI Wiring
- `Execution Board Guard` runs energy-function safety/regression report in `--check` mode.

This baseline closes M2-P4-1 with deterministic safety and asymmetric-loss regression governance evidence.
