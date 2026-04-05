# M31-P3-1 Baseline: Reality Model Wave 31 Deterministic Interface + Promotion/Rollback Hardening

Date: 2026-03-31
Milestone: M31-P3-1
Master Plan refs: 3.1.1, 3.2.1, 7.7.5, 10.10.9, 10.10.12

## Scope

Advance Reality Model lane by hardening deterministic interface contracts and promotion/rollback lifecycle safety for concurrent lane operation, including post-`M31-P10-5` control-plane compatibility.

## Deliverables

1. Reality model wave-31 baseline:
   - `docs/plans/methodology/M31_P3_1_REALITY_MODEL_WAVE31_DETERMINISTIC_INTERFACE_PROMOTION_ROLLBACK_HARDENING_BASELINE.md`
2. Reality model lane controls:
   - `configs/runtime/reality_model_wave31_deterministic_interface_promotion_rollback_hardening_controls.json`
3. Reality model lane reports:
   - `docs/plans/methodology/MASTER_PLAN_REALITY_MODEL_WAVE31_DETERMINISTIC_INTERFACE_PROMOTION_ROLLBACK_HARDENING_REPORT.json`
   - `docs/plans/methodology/MASTER_PLAN_REALITY_MODEL_WAVE31_DETERMINISTIC_INTERFACE_PROMOTION_ROLLBACK_HARDENING_REPORT.md`

## Guardrails

1. Deterministic interface contracts remain stable or explicitly versioned.
2. Promotion and rollback gates are explicit, auditable, and backed by structurally valid reality-model artifacts.
3. No engine-to-runtime/apps imports.
4. Compatibility with shared/runtime consumers is preserved.

## Exit Criteria

1. Shared reality-model contracts support deterministic normalization and strict fail-closed parsing.
2. Reality-model port guard rejects structurally invalid evaluations, traces, and explanations before relational drift checks.
3. Board evidence row is updated and milestone is closed.
4. Boundary, board, and URK quality checks pass.
