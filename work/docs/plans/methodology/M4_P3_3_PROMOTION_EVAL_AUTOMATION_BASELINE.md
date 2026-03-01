# M4-P3-3 Promotion Eval Automation Baseline

## Objective
Establish a deterministic promotion contract and CI check that blocks `approve` decisions unless all mandatory suites pass with attested artifacts:
- `offline_replay`
- `adversarial_robustness`
- `contradiction_stress`

## Baseline Artifacts
- Contract: `lib/core/ml/promotion_eval_contract.dart`
- Unit tests: `test/unit/ml/promotion_eval_contract_test.dart`
- Canonical manifest: `configs/ml/promotion_eval_manifest.json`
- CI check script: `scripts/ml/check_promotion_eval_manifest.py`
- Check summary output: `docs/plans/methodology/MASTER_PLAN_3_PRONG_PROMOTION_EVAL_CHECK.json`

## Enforcement Rules
1. Manifest must declare `manifest_version = v1`.
2. `required_suites` must exactly match the mandatory suite list in policy order.
3. Any candidate with `promotion_decision = approve` must include all required suite results.
4. Each required suite on an approved candidate must be `status = pass` and include a non-empty `artifact_uri`.

## CI Wiring
- `Execution Board Guard` runs the manifest checker.
- `ML Training Governance Guard` runs the manifest checker.

This baseline keeps M4-P3-3 in enforcement-ready state for follow-on rollout milestones.
