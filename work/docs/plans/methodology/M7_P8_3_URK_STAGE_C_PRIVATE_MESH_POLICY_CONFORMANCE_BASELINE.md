# M7-P8-3 URK Stage C Private-Mesh Policy Conformance Baseline

## Objective
Enforce private-mesh conformance for Event Ops deltas so only anonymized policy-approved payload classes propagate with lineage tags and double-encrypted transport.

## Baseline Artifacts
- URK Stage C controls config: `configs/runtime/urk_stage_c_private_mesh_policy_conformance_controls.json`
- URK Stage C report generator/check: `scripts/runtime/generate_urk_stage_c_private_mesh_policy_conformance_report.py`
- URK Stage C report JSON: `docs/plans/methodology/MASTER_PLAN_URK_STAGE_C_PRIVATE_MESH_POLICY_CONFORMANCE_REPORT.json`
- URK Stage C report Markdown: `docs/plans/methodology/MASTER_PLAN_URK_STAGE_C_PRIVATE_MESH_POLICY_CONFORMANCE_REPORT.md`
- URK Stage C contract: `lib/core/ai2ai/urk_stage_c_private_mesh_policy_conformance_contract.dart`
- URK Stage C tests: `test/unit/ai2ai/urk_stage_c_private_mesh_policy_conformance_contract_test.dart`

## Pass Contract
1. Config format is valid (`version = v1`, deterministic evaluation timestamps and window).
2. Payload minimization/schema conformance stays within threshold with zero direct identifier leaks.
3. Double-encryption and key-rotation coverage meet required thresholds.
4. Lineage-tag and policy-gate coverage meet thresholds with zero policy-bypass events.
5. Contract tests pass and report `verdict` is `PASS`.

## CI Wiring
- `Execution Board Guard` runs URK Stage C report in `--check` mode.

This baseline closes M7-P8-3 with deterministic private-mesh policy conformance evidence for URK Stage C prep.
