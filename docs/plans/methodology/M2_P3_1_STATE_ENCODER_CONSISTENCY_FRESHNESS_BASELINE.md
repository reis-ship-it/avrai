# M2-P3-1 State Encoder Consistency/Freshness Controls Baseline

## Objective
Enforce deterministic state encoder controls so feature freshness SLOs and atomic snapshot consistency checks remain within policy before downstream world-model promotion.

## Baseline Artifacts
- State encoder consistency/freshness config: `configs/runtime/state_encoder_consistency_freshness_controls.json`
- State encoder consistency/freshness report generator/check: `scripts/runtime/generate_state_encoder_consistency_freshness_report.py`
- State encoder consistency/freshness report JSON: `docs/plans/methodology/MASTER_PLAN_STATE_ENCODER_CONSISTENCY_FRESHNESS_REPORT.json`
- State encoder consistency/freshness report Markdown: `docs/plans/methodology/MASTER_PLAN_STATE_ENCODER_CONSISTENCY_FRESHNESS_REPORT.md`
- State encoder consistency contract: `lib/core/models/state_encoder_consistency_contract.dart`
- State encoder consistency tests: `test/unit/models/state_encoder_consistency_contract_test.dart`

## Pass Contract
1. Config format valid (`version = v1`, deterministic `evaluation_at`, valid numeric thresholds).
2. Feature freshness p95 age is within configured freshness SLO.
3. Snapshot consistency mismatch rate is within configured threshold.
4. Atomic snapshot monotonicity and lineage completeness checks pass.
5. Contract unit tests pass and report `verdict` is `PASS`.

## CI Wiring
- `Execution Board Guard` runs state encoder consistency/freshness report in `--check` mode.

This baseline closes M2-P3-1 with deterministic feature freshness and atomic snapshot consistency governance evidence.
