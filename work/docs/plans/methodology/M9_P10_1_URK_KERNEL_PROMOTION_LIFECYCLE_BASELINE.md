# M9-P10-1 URK Kernel Promotion Lifecycle Baseline

## Objective
Enforce a deterministic kernel lifecycle (`draft -> shadow -> enforced -> replicated`) with approval-chain coverage and zero unsafe promotions.

## Baseline Artifacts
- Controls config: `configs/runtime/urk_kernel_promotion_lifecycle_controls.json`
- Report generator/check: `scripts/runtime/generate_urk_kernel_promotion_lifecycle_report.py`
- Report JSON: `docs/plans/methodology/MASTER_PLAN_URK_KERNEL_PROMOTION_LIFECYCLE_REPORT.json`
- Report Markdown: `docs/plans/methodology/MASTER_PLAN_URK_KERNEL_PROMOTION_LIFECYCLE_REPORT.md`
- Contract: `lib/core/controllers/urk_kernel_promotion_lifecycle_contract.dart`
- Tests: `test/unit/controllers/urk_kernel_promotion_lifecycle_contract_test.dart`

## Pass Contract
1. Lifecycle transition and approval-chain coverage meet required thresholds.
2. Unapproved enforced promotions and stage-skip promotions remain within threshold bounds.
3. Contract tests pass and report `verdict` is `PASS`.

## CI Wiring
- `Execution Board Guard` runs this report in `--check` mode.
