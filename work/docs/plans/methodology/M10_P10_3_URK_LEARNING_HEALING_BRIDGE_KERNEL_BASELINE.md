# M10-P10-3 URK Learning-Healing Bridge Kernel Baseline

## Objective
Bridge self-healing incidents to self-learning updates so every incident class generates lineage-linked learning records and recovery linkbacks.

## Baseline Artifacts
- Controls config: `configs/runtime/urk_learning_healing_bridge_controls.json`
- Report generator/check: `scripts/runtime/generate_urk_learning_healing_bridge_report.py`
- Report JSON: `docs/plans/methodology/MASTER_PLAN_URK_LEARNING_HEALING_BRIDGE_REPORT.json`
- Report Markdown: `docs/plans/methodology/MASTER_PLAN_URK_LEARNING_HEALING_BRIDGE_REPORT.md`
- Contract: `lib/core/controllers/urk_learning_healing_bridge_contract.dart`
- Tests: `test/unit/controllers/urk_learning_healing_bridge_contract_test.dart`

## Pass Contract
1. Incident-to-learning linkage and lineage reference coverage meet thresholds.
2. Orphan incident-learning records and missing recovery linkbacks remain within threshold bounds.
3. Contract tests pass and report `verdict` is `PASS`.

## CI Wiring
- `Execution Board Guard` runs this report in `--check` mode.
