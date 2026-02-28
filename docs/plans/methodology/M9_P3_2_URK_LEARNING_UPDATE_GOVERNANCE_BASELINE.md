# M9-P3-2 URK Learning Update Governance Baseline

## Objective
Enforce learning update governance so model update validation, data lineage, and high-impact promotion safety stay within deterministic policy bounds.

## Baseline Artifacts
- Controls config: `configs/runtime/urk_learning_update_governance_controls.json`
- Report generator/check: `scripts/runtime/generate_urk_learning_update_governance_report.py`
- Report JSON: `docs/plans/methodology/MASTER_PLAN_URK_LEARNING_UPDATE_GOVERNANCE_REPORT.json`
- Report Markdown: `docs/plans/methodology/MASTER_PLAN_URK_LEARNING_UPDATE_GOVERNANCE_REPORT.md`
- Contract: `lib/core/ai/urk_learning_update_governance_contract.dart`
- Tests: `test/unit/ai/urk_learning_update_governance_contract_test.dart`

## Pass Contract
1. Learning update validation and lineage coverage meet required thresholds.
2. Unreviewed high-impact learning updates and failed rollback recovery events remain within threshold bounds.
3. Contract tests pass and report `verdict` is `PASS`.

## CI Wiring
- `Execution Board Guard` runs this report in `--check` mode.
