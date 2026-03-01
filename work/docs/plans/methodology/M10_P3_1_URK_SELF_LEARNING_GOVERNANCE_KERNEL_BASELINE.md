# M10-P3-1 URK Self-Learning Governance Kernel Baseline

## Objective
Govern self-learning updates so signal validation, approval paths, and training lineage remain deterministic and bounded by policy.

## Baseline Artifacts
- Controls config: `configs/runtime/urk_self_learning_governance_controls.json`
- Report generator/check: `scripts/runtime/generate_urk_self_learning_governance_report.py`
- Report JSON: `docs/plans/methodology/MASTER_PLAN_URK_SELF_LEARNING_GOVERNANCE_REPORT.json`
- Report Markdown: `docs/plans/methodology/MASTER_PLAN_URK_SELF_LEARNING_GOVERNANCE_REPORT.md`
- Contract: `lib/core/ai/urk_self_learning_governance_contract.dart`
- Tests: `test/unit/ai/urk_self_learning_governance_contract_test.dart`

## Pass Contract
1. Self-learning signal validation and approval-path coverage meet thresholds.
2. Unbounded updates and unverified training-lineage events remain within threshold bounds.
3. Contract tests pass and report `verdict` is `PASS`.

## CI Wiring
- `Execution Board Guard` runs this report in `--check` mode.
