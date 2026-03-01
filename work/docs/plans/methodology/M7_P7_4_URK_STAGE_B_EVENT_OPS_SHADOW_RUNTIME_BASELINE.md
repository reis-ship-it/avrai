# M7-P7-4 URK Stage B Event Ops Shadow Runtime Baseline

## Objective
Enforce Event Ops shadow runtime wiring for `ingest -> plan -> gate -> observe` so decisions are lineage-complete and high-impact autonomous commits remain blocked in shadow mode.

## Baseline Artifacts
- URK Stage B controls config: `configs/runtime/urk_stage_b_event_ops_shadow_runtime_controls.json`
- URK Stage B report generator/check: `scripts/runtime/generate_urk_stage_b_event_ops_shadow_runtime_report.py`
- URK Stage B report JSON: `docs/plans/methodology/MASTER_PLAN_URK_STAGE_B_EVENT_OPS_SHADOW_RUNTIME_REPORT.json`
- URK Stage B report Markdown: `docs/plans/methodology/MASTER_PLAN_URK_STAGE_B_EVENT_OPS_SHADOW_RUNTIME_REPORT.md`
- URK Stage B contract: `lib/core/controllers/urk_stage_b_event_ops_shadow_runtime_contract.dart`
- URK Stage B tests: `test/unit/controllers/urk_stage_b_event_ops_shadow_runtime_contract_test.dart`

## Pass Contract
1. Config format is valid (`version = v1`, deterministic evaluation timestamps and window).
2. Shadow pipeline coverage and decision-envelope coverage meet required thresholds.
3. Lineage completeness meets threshold and orphan action states remain within configured maximum.
4. High-impact autonomous commits remain within max bound (`0` for shadow mode) and shadow-block coverage meets threshold.
5. Contract tests pass and report `verdict` is `PASS`.

## CI Wiring
- `Execution Board Guard` runs URK Stage B report in `--check` mode.

This baseline closes M7-P7-4 with deterministic shadow runtime governance evidence for Event Ops Stage B.
