# M31-P12-3 Baseline: Compressed Reality-Model Training Acceptance + Regression-Gate Hardening

Date: 2026-03-31
Milestone: M31-P12-3
Master Plan refs: 12.4B.6

## Scope

Harden the already-seeded `12.4B` compressed reality-model training lane by making promotion acceptance fail closed when compression-specific regression evidence is missing, unattested, or outside declared budget.

## Deliverables

1. Baseline doc:
   - `docs/plans/methodology/M31_P12_3_COMPRESSED_REALITY_MODEL_TRAINING_ACCEPTANCE_GATE_BASELINE.md`
2. Controls:
   - `apps/avrai_app/configs/runtime/compressed_reality_model_training_acceptance_controls.json`
3. Contract and manifest ownership:
   - `runtime/avrai_runtime_os/lib/ml/promotion_eval_contract.dart`
   - `apps/avrai_app/configs/ml/promotion_eval_manifest.json`
   - `work/scripts/ml/check_promotion_eval_manifest.py`
   - `work/docs/plans/methodology/MASTER_PLAN_3_PRONG_PROMOTION_EVAL_CHECK.json`
4. Verification ownership:
   - `apps/avrai_app/test/unit/ml/promotion_eval_contract_test.dart`

## Explicit Objectives

1. preserve the original replay/adversarial/contradiction promotion suites for all candidates
2. add a bounded compression rollout profile for candidates that rely on compressed training infrastructure
3. require attested regression evidence for ranking drift, calibration drift, contradiction-detection degradation, and uncertainty-honesty regression before compressed rollout promotion
4. keep manifest and CI validation fail closed when compression evidence exceeds declared regression budgets

## Guardrails

1. this slice is acceptance hardening only; it does not reopen control-plane authority, replay execution, or runtime rollout orchestration
2. compression-specific promotion gates must remain conditional on an explicit compression rollout profile so historical non-compressed candidates are not retroactively misclassified
3. the manifest, Dart contract, and Python validator must stay aligned on required suite names and manifest version
4. regression budgets are evidence gates, not tuning knobs; passing status without artifact or budget compliance is invalid

## Exact File Ownership

### Primary implementation files

1. `runtime/avrai_runtime_os/lib/ml/promotion_eval_contract.dart`
2. `apps/avrai_app/configs/ml/promotion_eval_manifest.json`
3. `work/scripts/ml/check_promotion_eval_manifest.py`
4. `work/docs/plans/methodology/MASTER_PLAN_3_PRONG_PROMOTION_EVAL_CHECK.json`

### Primary verification files

1. `apps/avrai_app/test/unit/ml/promotion_eval_contract_test.dart`

## Exit Criteria

1. the canonical promotion manifest advances to a compression-aware schema version and remains valid under the updated guard
2. compressed-training candidates declare a rollout profile plus the four required compression regression suites
3. approve decisions fail closed when compression suite evidence is missing, unattested, or beyond regression budget
4. targeted tests and the manifest guard prove the Dart contract and Python validation remain aligned

## March 31 Execution Slice

`M31-P12-3` lands as one bounded acceptance-normalization slice:

1. add a compression-specific suite family to the promotion-eval contract without disturbing the original baseline gate
2. add a `compressed_reality_model_v1` rollout profile plus canonical regression budgets to the manifest
3. update the Python guard so the canonical summary reflects conditional compression gating
4. keep the lane verifiable with focused Dart tests and the manifest-check script

## Closeout

`M31-P12-3` is complete once compressed-training promotion candidates can no longer approve on the strength of replay/adversarial/contradiction evidence alone. Ranking drift, calibration drift, contradiction-detection degradation, and uncertainty-honesty regression must each carry an artifact, a bounded regression budget, and a passing status before rollout remains eligible.
