# M10-P10-4 URK Kernel Activation Engine Baseline

## Summary

Implements deterministic kernel activation routing for URK:

1. trigger -> candidate kernels
2. privacy mode gating
3. dependency gating
4. ordered activation receipts

This baseline defines the enforceable contract and validation package for activation coverage, policy-gate coverage, receipt completeness, unauthorized activation protection, and dependency-bypass prevention.

## Scope

1. Contract: `lib/core/controllers/urk_kernel_activation_engine_contract.dart`
2. Tests: `test/unit/controllers/urk_kernel_activation_engine_contract_test.dart`
3. Controls: `configs/runtime/urk_kernel_activation_engine_controls.json`
4. Report generator: `scripts/runtime/generate_urk_kernel_activation_engine_report.py`
5. Generated reports:
   - `docs/plans/methodology/MASTER_PLAN_URK_KERNEL_ACTIVATION_ENGINE_REPORT.json`
   - `docs/plans/methodology/MASTER_PLAN_URK_KERNEL_ACTIVATION_ENGINE_REPORT.md`

## Exit Criteria

1. Trigger routing coverage at or above required threshold.
2. Policy gate coverage at or above required threshold.
3. Activation receipt coverage at or above required threshold.
4. Unauthorized activations remain at or below threshold.
5. Dependency bypasses remain at or below threshold.
6. Contract tests and report checks pass in CI.
