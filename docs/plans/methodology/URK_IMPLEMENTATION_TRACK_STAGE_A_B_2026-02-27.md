# URK Implementation Track (Stage A/B)

**Date:** February 27, 2026  
**Status:** Ready to implement  
**Scope:** Stage A (contract + policy freeze) and Stage B (Event Ops shadow runtime).

---

## 1. Stage A (Must Complete First)

## 1.1 Contract freeze

Freeze these interfaces before runtime code wiring:

1. `RuntimeRequestEnvelope`
2. `RuntimeDecisionEnvelope`
3. runtime endpoints (`ingest/plan/commit/observe/recover/lineage/override`)
4. trigger type enum and trigger contract fields
5. privacy mode enum and policy contract fields
6. dual-time schema (`atomic_time`, `semantic_time`)

Authority:

1. `docs/plans/architecture/URK_INTERFACE_CONTRACTS_2026-02-27.md`
2. `docs/plans/architecture/UNIFIED_RUNTIME_KERNEL_BLUEPRINT_2026-02-27.md`

## 1.2 Required runtime guard components

Implement and wire (no bypass):

1. `TriggerService`
2. `PrivacyModePolicy`
3. `ConsentGate`
4. `NoEgressGate`

## 1.3 Policy behavior

1. AI2AI default product posture: opt-out.
2. Privacy mode resolved per request before planning.
3. `local_sovereign` must hard-fail outbound runtime egress.
4. High-impact commit requires conviction + policy + rollback path.

---

## 2. Stage B (Event Ops Reference Runtime, Shadow)

## 2.1 Runtime target

1. runtime type: `event_ops_runtime`
2. execution mode: shadow-only (no high-impact auto commits)
3. user-facing recommendation/training flows may map to `user_runtime` while reusing Stage B shadow contracts.

## 2.2 Shadow execution behavior

1. Run full ingest -> plan -> gate -> recommend path.
2. Emit decision envelopes with confidence + policy checks.
3. Do not auto-commit high-impact actions.
4. Write lineage and memory tuples.

## 2.3 Event Ops shadow acceptance gates

1. trigger-to-plan flow deterministic in replay.
2. no dead/orphan action states.
3. lineage reconstructs end-to-end decision chain.
4. no policy-bypassing path exists.

---

## 3. Build/CI Wiring for Stage A/B

Before merge:

1. `dart run tool/update_execution_board.dart --check`
2. `python3 scripts/validate_execution_board_urk_quality.py`
3. `python3 scripts/validate_pr_traceability.py ... --require-urk-tags`
4. `dart run tool/update_three_prong_reviews.dart --check`

Execution board updates required:

1. milestone URK metadata (`runtime/prong/mode/impact`) must be specific.
2. stage evidence links must include shadow report artifacts.

---

## 4. Next Stage Hand-off

After Stage B is stable:

1. Stage C: low-impact autonomous actions for Event Ops.
2. Stage D: Business + Expert runtime replication using same URK contracts.

---

## 5. Stage A Completion Evidence (M7-P7-3)

1. Baseline: `docs/plans/methodology/M7_P7_3_URK_STAGE_A_TRIGGER_PRIVACY_NO_EGRESS_BASELINE.md`
2. Controls: `configs/runtime/urk_stage_a_trigger_privacy_no_egress_controls.json`
3. Generator/check: `scripts/runtime/generate_urk_stage_a_trigger_privacy_no_egress_report.py`
4. Reports:
   - `docs/plans/methodology/MASTER_PLAN_URK_STAGE_A_TRIGGER_PRIVACY_NO_EGRESS_REPORT.json`
   - `docs/plans/methodology/MASTER_PLAN_URK_STAGE_A_TRIGGER_PRIVACY_NO_EGRESS_REPORT.md`
5. Contract/test:
   - `lib/core/controllers/urk_stage_a_trigger_privacy_no_egress_contract.dart`
   - `test/unit/controllers/urk_stage_a_trigger_privacy_no_egress_contract_test.dart`

## 6. Stage B Completion Evidence (M7-P7-4)

1. Baseline: `docs/plans/methodology/M7_P7_4_URK_STAGE_B_EVENT_OPS_SHADOW_RUNTIME_BASELINE.md`
2. Controls: `configs/runtime/urk_stage_b_event_ops_shadow_runtime_controls.json`
3. Generator/check: `scripts/runtime/generate_urk_stage_b_event_ops_shadow_runtime_report.py`
4. Reports:
   - `docs/plans/methodology/MASTER_PLAN_URK_STAGE_B_EVENT_OPS_SHADOW_RUNTIME_REPORT.json`
   - `docs/plans/methodology/MASTER_PLAN_URK_STAGE_B_EVENT_OPS_SHADOW_RUNTIME_REPORT.md`
5. Contract/test:
   - `lib/core/controllers/urk_stage_b_event_ops_shadow_runtime_contract.dart`
   - `test/unit/controllers/urk_stage_b_event_ops_shadow_runtime_contract_test.dart`

## 7. Stage C Prep Evidence (M7-P8-3)

1. Baseline: `docs/plans/methodology/M7_P8_3_URK_STAGE_C_PRIVATE_MESH_POLICY_CONFORMANCE_BASELINE.md`
2. Controls: `configs/runtime/urk_stage_c_private_mesh_policy_conformance_controls.json`
3. Generator/check: `scripts/runtime/generate_urk_stage_c_private_mesh_policy_conformance_report.py`
4. Reports:
   - `docs/plans/methodology/MASTER_PLAN_URK_STAGE_C_PRIVATE_MESH_POLICY_CONFORMANCE_REPORT.json`
   - `docs/plans/methodology/MASTER_PLAN_URK_STAGE_C_PRIVATE_MESH_POLICY_CONFORMANCE_REPORT.md`
5. Contract/test:
   - `lib/core/ai2ai/urk_stage_c_private_mesh_policy_conformance_contract.dart`
   - `test/unit/ai2ai/urk_stage_c_private_mesh_policy_conformance_contract_test.dart`

## 8. Stage D Replication Evidence (M8-P9-2, M8-P11-2)

1. Business runtime replication (`M8-P9-2`):
   - Baseline: `docs/plans/methodology/M8_P9_2_URK_STAGE_D_BUSINESS_RUNTIME_REPLICATION_BASELINE.md`
   - Controls: `configs/runtime/urk_stage_d_business_runtime_replication_controls.json`
   - Generator/check: `scripts/runtime/generate_urk_stage_d_business_runtime_replication_report.py`
   - Reports:
     - `docs/plans/methodology/MASTER_PLAN_URK_STAGE_D_BUSINESS_RUNTIME_REPLICATION_REPORT.json`
     - `docs/plans/methodology/MASTER_PLAN_URK_STAGE_D_BUSINESS_RUNTIME_REPLICATION_REPORT.md`
   - Contract/test:
     - `lib/core/services/business/urk_stage_d_business_runtime_replication_contract.dart`
     - `test/unit/services/urk_stage_d_business_runtime_replication_contract_test.dart`
2. Expert runtime replication (`M8-P11-2`):
   - Baseline: `docs/plans/methodology/M8_P11_2_URK_STAGE_D_EXPERT_RUNTIME_REPLICATION_BASELINE.md`
   - Controls: `configs/runtime/urk_stage_d_expert_runtime_replication_controls.json`
   - Generator/check: `scripts/runtime/generate_urk_stage_d_expert_runtime_replication_report.py`
   - Reports:
     - `docs/plans/methodology/MASTER_PLAN_URK_STAGE_D_EXPERT_RUNTIME_REPLICATION_REPORT.json`
     - `docs/plans/methodology/MASTER_PLAN_URK_STAGE_D_EXPERT_RUNTIME_REPLICATION_REPORT.md`
   - Contract/test:
   - `lib/core/services/expertise/urk_stage_d_expert_runtime_replication_contract.dart`
   - `test/unit/services/urk_stage_d_expert_runtime_replication_contract_test.dart`

## 9. Stage E Cross-Runtime Evidence (M8-P10-4)

1. Baseline: `docs/plans/methodology/M8_P10_4_URK_STAGE_E_CROSS_RUNTIME_CONFORMANCE_BASELINE.md`
2. Controls: `configs/runtime/urk_stage_e_cross_runtime_conformance_controls.json`
3. Generator/check: `scripts/runtime/generate_urk_stage_e_cross_runtime_conformance_report.py`
4. Reports:
   - `docs/plans/methodology/MASTER_PLAN_URK_STAGE_E_CROSS_RUNTIME_CONFORMANCE_REPORT.json`
   - `docs/plans/methodology/MASTER_PLAN_URK_STAGE_E_CROSS_RUNTIME_CONFORMANCE_REPORT.md`
5. Contract/test:
   - `lib/core/controllers/urk_stage_e_cross_runtime_conformance_contract.dart`
   - `test/unit/controllers/urk_stage_e_cross_runtime_conformance_contract_test.dart`

## 10. Stage F Universal Kernel Governance Evidence (M9-P10-1, M9-P3-2, M9-P10-2)

1. Kernel promotion lifecycle (`M9-P10-1`):
   - Baseline: `docs/plans/methodology/M9_P10_1_URK_KERNEL_PROMOTION_LIFECYCLE_BASELINE.md`
   - Controls: `configs/runtime/urk_kernel_promotion_lifecycle_controls.json`
   - Generator/check: `scripts/runtime/generate_urk_kernel_promotion_lifecycle_report.py`
   - Reports:
     - `docs/plans/methodology/MASTER_PLAN_URK_KERNEL_PROMOTION_LIFECYCLE_REPORT.json`
     - `docs/plans/methodology/MASTER_PLAN_URK_KERNEL_PROMOTION_LIFECYCLE_REPORT.md`
   - Contract/test:
     - `lib/core/controllers/urk_kernel_promotion_lifecycle_contract.dart`
     - `test/unit/controllers/urk_kernel_promotion_lifecycle_contract_test.dart`
2. Learning update governance (`M9-P3-2`):
   - Baseline: `docs/plans/methodology/M9_P3_2_URK_LEARNING_UPDATE_GOVERNANCE_BASELINE.md`
   - Controls: `configs/runtime/urk_learning_update_governance_controls.json`
   - Generator/check: `scripts/runtime/generate_urk_learning_update_governance_report.py`
   - Reports:
     - `docs/plans/methodology/MASTER_PLAN_URK_LEARNING_UPDATE_GOVERNANCE_REPORT.json`
     - `docs/plans/methodology/MASTER_PLAN_URK_LEARNING_UPDATE_GOVERNANCE_REPORT.md`
   - Contract/test:
     - `lib/core/ai/urk_learning_update_governance_contract.dart`
     - `test/unit/ai/urk_learning_update_governance_contract_test.dart`
3. Kernel registry + admin catalog (`M9-P10-2`):
   - Baseline: `docs/plans/methodology/M9_P10_2_URK_KERNEL_REGISTRY_AND_ADMIN_CATALOG_BASELINE.md`
   - Registry: `configs/runtime/kernel_registry.json`
   - Validator/check: `scripts/runtime/check_urk_kernel_registry.py`
   - Catalog generator/check: `scripts/runtime/generate_urk_kernel_catalog.py`
   - Admin catalog: `docs/admin/URK_KERNEL_CATALOG.md`

## 11. Reality Kernel Evidence (M9-P3-3, M9-P5-2)

1. Reality world-state coherence (`M9-P3-3`):
   - Baseline: `docs/plans/methodology/M9_P3_3_URK_REALITY_WORLD_STATE_COHERENCE_BASELINE.md`
   - Controls: `configs/runtime/urk_reality_world_state_coherence_controls.json`
   - Generator/check: `scripts/runtime/generate_urk_reality_world_state_coherence_report.py`
   - Reports:
     - `docs/plans/methodology/MASTER_PLAN_URK_REALITY_WORLD_STATE_COHERENCE_REPORT.json`
     - `docs/plans/methodology/MASTER_PLAN_URK_REALITY_WORLD_STATE_COHERENCE_REPORT.md`
   - Contract/test:
     - `lib/core/models/urk_reality_world_state_coherence_contract.dart`
     - `test/unit/models/urk_reality_world_state_coherence_contract_test.dart`
2. Reality temporal truth (`M9-P5-2`):
   - Baseline: `docs/plans/methodology/M9_P5_2_URK_REALITY_TEMPORAL_TRUTH_BASELINE.md`
   - Controls: `configs/runtime/urk_reality_temporal_truth_controls.json`
   - Generator/check: `scripts/runtime/generate_urk_reality_temporal_truth_report.py`
   - Reports:
     - `docs/plans/methodology/MASTER_PLAN_URK_REALITY_TEMPORAL_TRUTH_REPORT.json`
     - `docs/plans/methodology/MASTER_PLAN_URK_REALITY_TEMPORAL_TRUTH_REPORT.md`
   - Contract/test:
     - `lib/core/services/quantum/urk_reality_temporal_truth_contract.dart`
     - `test/unit/services/urk_reality_temporal_truth_contract_test.dart`

## 12. Self-Learning + Self-Healing Kernel Evidence (M10-P3-1, M10-P6-1, M10-P10-3)

1. Self-learning governance (`M10-P3-1`):
   - Baseline: `docs/plans/methodology/M10_P3_1_URK_SELF_LEARNING_GOVERNANCE_KERNEL_BASELINE.md`
   - Controls: `configs/runtime/urk_self_learning_governance_controls.json`
   - Generator/check: `scripts/runtime/generate_urk_self_learning_governance_report.py`
   - Reports:
     - `docs/plans/methodology/MASTER_PLAN_URK_SELF_LEARNING_GOVERNANCE_REPORT.json`
     - `docs/plans/methodology/MASTER_PLAN_URK_SELF_LEARNING_GOVERNANCE_REPORT.md`
   - Contract/test:
     - `lib/core/ai/urk_self_learning_governance_contract.dart`
     - `test/unit/ai/urk_self_learning_governance_contract_test.dart`
2. Self-healing recovery (`M10-P6-1`):
   - Baseline: `docs/plans/methodology/M10_P6_1_URK_SELF_HEALING_RECOVERY_KERNEL_BASELINE.md`
   - Controls: `configs/runtime/urk_self_healing_recovery_controls.json`
   - Generator/check: `scripts/runtime/generate_urk_self_healing_recovery_report.py`
   - Reports:
     - `docs/plans/methodology/MASTER_PLAN_URK_SELF_HEALING_RECOVERY_REPORT.json`
     - `docs/plans/methodology/MASTER_PLAN_URK_SELF_HEALING_RECOVERY_REPORT.md`
   - Contract/test:
     - `lib/core/services/urk_self_healing_recovery_contract.dart`
     - `test/unit/services/urk_self_healing_recovery_contract_test.dart`
3. Learning-healing bridge (`M10-P10-3`):
   - Baseline: `docs/plans/methodology/M10_P10_3_URK_LEARNING_HEALING_BRIDGE_KERNEL_BASELINE.md`
   - Controls: `configs/runtime/urk_learning_healing_bridge_controls.json`
   - Generator/check: `scripts/runtime/generate_urk_learning_healing_bridge_report.py`
   - Reports:
     - `docs/plans/methodology/MASTER_PLAN_URK_LEARNING_HEALING_BRIDGE_REPORT.json`
     - `docs/plans/methodology/MASTER_PLAN_URK_LEARNING_HEALING_BRIDGE_REPORT.md`
   - Contract/test:
     - `lib/core/controllers/urk_learning_healing_bridge_contract.dart`
     - `test/unit/controllers/urk_learning_healing_bridge_contract_test.dart`

## 13. Kernel Activation Engine Evidence (M10-P7-1)

1. Kernel activation engine (`M10-P7-1`):
   - Baseline: `docs/plans/methodology/M10_P10_4_URK_KERNEL_ACTIVATION_ENGINE_BASELINE.md`
   - Controls: `configs/runtime/urk_kernel_activation_engine_controls.json`
   - Generator/check: `scripts/runtime/generate_urk_kernel_activation_engine_report.py`
   - Reports:
     - `docs/plans/methodology/MASTER_PLAN_URK_KERNEL_ACTIVATION_ENGINE_REPORT.json`
     - `docs/plans/methodology/MASTER_PLAN_URK_KERNEL_ACTIVATION_ENGINE_REPORT.md`
   - Contract/test:
     - `lib/core/controllers/urk_kernel_activation_engine_contract.dart`
     - `test/unit/controllers/urk_kernel_activation_engine_contract_test.dart`

## 14. Kernel Control Plane Evidence (M10-P11-1)

1. Kernel control plane (`M10-P11-1`):
   - Baseline: `docs/plans/methodology/M10_P11_1_URK_KERNEL_CONTROL_PLANE_BASELINE.md`
   - Controls: `configs/runtime/urk_kernel_control_plane_controls.json`
   - Generator/check: `scripts/runtime/generate_urk_kernel_control_plane_report.py`
   - Reports:
     - `docs/plans/methodology/MASTER_PLAN_URK_KERNEL_CONTROL_PLANE_REPORT.json`
     - `docs/plans/methodology/MASTER_PLAN_URK_KERNEL_CONTROL_PLANE_REPORT.md`
   - Service/test:
     - `lib/core/services/admin/urk_kernel_control_plane_service.dart`
     - `test/unit/services/admin/urk_kernel_control_plane_service_test.dart`

## 15. Runtime Activation Receipt Dispatch Evidence (M10-P11-2)

1. Runtime activation receipt dispatch (`M10-P11-2`):
   - Baseline: `docs/plans/methodology/M10_P11_2_URK_RUNTIME_ACTIVATION_RECEIPT_DISPATCH_BASELINE.md`
   - Controls: `configs/runtime/urk_runtime_activation_receipt_dispatch_controls.json`
   - Generator/check: `scripts/runtime/generate_urk_runtime_activation_receipt_dispatch_report.py`
   - Reports:
     - `docs/plans/methodology/MASTER_PLAN_URK_RUNTIME_ACTIVATION_RECEIPT_DISPATCH_REPORT.json`
     - `docs/plans/methodology/MASTER_PLAN_URK_RUNTIME_ACTIVATION_RECEIPT_DISPATCH_REPORT.md`
   - Runtime wiring/tests:
     - `lib/core/controllers/urk_runtime_activation_receipt_dispatcher.dart`
     - `lib/core/controllers/conviction_shadow_gate.dart`
     - `lib/core/services/ai_infrastructure/online_learning_service.dart`
     - `lib/core/ai2ai/connection_orchestrator.dart`
     - `lib/core/services/admin/urk_kernel_control_plane_service.dart`
     - `lib/core/services/business/urk_stage_d_business_runtime_replication_contract.dart`
     - `lib/core/services/expertise/urk_stage_d_expert_runtime_replication_contract.dart`
     - `lib/core/services/business/business_service.dart`
     - `lib/core/services/expertise/expert_recommendations_service.dart`
     - `lib/core/controllers/urk_stage_b_event_ops_shadow_runtime_contract.dart`
     - `lib/core/services/events/event_recommendation_service.dart`
     - Notes: general-user pathway is classified as `user_runtime` even when it reuses Stage B event shadow trigger contracts.
      - `test/unit/controllers/urk_runtime_activation_receipt_dispatcher_test.dart`
     - `test/unit/services/urk_stage_d_business_runtime_replication_contract_test.dart`
     - `test/unit/services/urk_stage_d_expert_runtime_replication_contract_test.dart`
     - `test/unit/services/business_service_urk_runtime_dispatch_test.dart`
     - `test/unit/services/expert_recommendations_service_test.dart`
     - `test/unit/controllers/urk_stage_b_event_ops_shadow_runtime_contract_test.dart`
     - `test/unit/services/event_recommendation_urk_runtime_dispatch_test.dart`

## 16. User Runtime Intake Kernel Handoff (M11-P3-1)

1. Dedicated user-runtime intake governance kernel (`M11-P3-1`) is queued as the training-first expansion lane.
2. Evidence package:
   - Baseline: `docs/plans/methodology/M11_P3_1_URK_USER_RUNTIME_LEARNING_INTAKE_KERNEL_BASELINE.md`
   - Controls: `configs/runtime/urk_user_runtime_learning_intake_controls.json`
   - Generator/check: `scripts/runtime/generate_urk_user_runtime_learning_intake_report.py`
   - Contract/test:
     - `lib/core/services/user/urk_user_runtime_learning_intake_contract.dart`
     - `test/unit/services/urk_user_runtime_learning_intake_contract_test.dart`
   - Live runtime wiring:
     - `lib/core/services/events/event_recommendation_service.dart`
     - `test/unit/services/event_recommendation_urk_runtime_dispatch_test.dart`
