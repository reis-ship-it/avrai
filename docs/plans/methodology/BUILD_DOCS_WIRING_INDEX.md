# Build Docs Wiring Index

**Date:** February 27, 2026  
**Status:** Canonical wiring map  
**Purpose:** Single update hub for all build/execution/governance documentation that must stay synchronized for URK, 3-prong architecture, Master Plan execution, and CI enforcement.

---

## 1. Core Program Authority

1. `docs/MASTER_PLAN.md`
2. `docs/EXECUTION_BOARD.csv`
3. `docs/STATUS_WEEKLY.md`
4. `docs/agents/status/status_tracker.md`

---

## 2. URK + 3-Prong Architecture Authority

1. `docs/plans/architecture/UNIFIED_RUNTIME_KERNEL_BLUEPRINT_2026-02-27.md`
2. `docs/plans/architecture/URK_INTERFACE_CONTRACTS_2026-02-27.md`
3. `docs/plans/architecture/ARCHITECTURE_INDEX.md`
4. `docs/plans/architecture/MASTER_PLAN_3_PRONG_TARGET_END_STATE.md`
5. `docs/plans/methodology/URK_IMPLEMENTATION_TRACK_STAGE_A_B_2026-02-27.md`
6. `docs/plans/architecture/URK_ADMIN_CONSOLE_PATHWAY_2026-02-27.md`
7. `docs/plans/architecture/PRONG_APPS_CONCURRENT_EXECUTION_PLAN_2026-02-28.md`
8. `docs/plans/architecture/PRONG_RUNTIME_OS_CONCURRENT_EXECUTION_PLAN_2026-02-28.md`
9. `docs/plans/architecture/PRONG_REALITY_MODEL_CONCURRENT_EXECUTION_PLAN_2026-02-28.md`

---

## 3. Plan/Board/PR Traceability Authority

1. `docs/plans/methodology/PRD_EXECUTION_BOARD_INTEGRATION.md`
2. `docs/GITHUB_ENFORCEMENT_SETUP.md`
3. `.github/workflows/execution-board-guard.yml`
4. `.github/workflows/prd-traceability-guard.yml`
5. `scripts/validate_pr_traceability.py`
6. `tool/update_execution_board.dart`
7. `scripts/validate_execution_board_urk_quality.py`
8. `docs/plans/methodology/M7_P7_3_URK_STAGE_A_TRIGGER_PRIVACY_NO_EGRESS_BASELINE.md`
9. `scripts/runtime/generate_urk_stage_a_trigger_privacy_no_egress_report.py`
10. `docs/plans/methodology/MASTER_PLAN_URK_STAGE_A_TRIGGER_PRIVACY_NO_EGRESS_REPORT.json`
11. `docs/plans/methodology/MASTER_PLAN_URK_STAGE_A_TRIGGER_PRIVACY_NO_EGRESS_REPORT.md`
12. `docs/plans/methodology/M7_P7_4_URK_STAGE_B_EVENT_OPS_SHADOW_RUNTIME_BASELINE.md`
13. `scripts/runtime/generate_urk_stage_b_event_ops_shadow_runtime_report.py`
14. `docs/plans/methodology/MASTER_PLAN_URK_STAGE_B_EVENT_OPS_SHADOW_RUNTIME_REPORT.json`
15. `docs/plans/methodology/MASTER_PLAN_URK_STAGE_B_EVENT_OPS_SHADOW_RUNTIME_REPORT.md`
16. `docs/plans/methodology/M7_P8_3_URK_STAGE_C_PRIVATE_MESH_POLICY_CONFORMANCE_BASELINE.md`
17. `scripts/runtime/generate_urk_stage_c_private_mesh_policy_conformance_report.py`
18. `docs/plans/methodology/MASTER_PLAN_URK_STAGE_C_PRIVATE_MESH_POLICY_CONFORMANCE_REPORT.json`
19. `docs/plans/methodology/MASTER_PLAN_URK_STAGE_C_PRIVATE_MESH_POLICY_CONFORMANCE_REPORT.md`
20. `docs/plans/methodology/M8_P9_2_URK_STAGE_D_BUSINESS_RUNTIME_REPLICATION_BASELINE.md`
21. `scripts/runtime/generate_urk_stage_d_business_runtime_replication_report.py`
22. `docs/plans/methodology/MASTER_PLAN_URK_STAGE_D_BUSINESS_RUNTIME_REPLICATION_REPORT.json`
23. `docs/plans/methodology/MASTER_PLAN_URK_STAGE_D_BUSINESS_RUNTIME_REPLICATION_REPORT.md`
24. `docs/plans/methodology/M8_P11_2_URK_STAGE_D_EXPERT_RUNTIME_REPLICATION_BASELINE.md`
25. `scripts/runtime/generate_urk_stage_d_expert_runtime_replication_report.py`
26. `docs/plans/methodology/MASTER_PLAN_URK_STAGE_D_EXPERT_RUNTIME_REPLICATION_REPORT.json`
27. `docs/plans/methodology/MASTER_PLAN_URK_STAGE_D_EXPERT_RUNTIME_REPLICATION_REPORT.md`
28. `docs/plans/methodology/M8_P10_4_URK_STAGE_E_CROSS_RUNTIME_CONFORMANCE_BASELINE.md`
29. `scripts/runtime/generate_urk_stage_e_cross_runtime_conformance_report.py`
30. `docs/plans/methodology/MASTER_PLAN_URK_STAGE_E_CROSS_RUNTIME_CONFORMANCE_REPORT.json`
31. `docs/plans/methodology/MASTER_PLAN_URK_STAGE_E_CROSS_RUNTIME_CONFORMANCE_REPORT.md`
32. `docs/plans/methodology/M9_P10_1_URK_KERNEL_PROMOTION_LIFECYCLE_BASELINE.md`
33. `scripts/runtime/generate_urk_kernel_promotion_lifecycle_report.py`
34. `docs/plans/methodology/MASTER_PLAN_URK_KERNEL_PROMOTION_LIFECYCLE_REPORT.json`
35. `docs/plans/methodology/MASTER_PLAN_URK_KERNEL_PROMOTION_LIFECYCLE_REPORT.md`
36. `docs/plans/methodology/M9_P3_2_URK_LEARNING_UPDATE_GOVERNANCE_BASELINE.md`
37. `scripts/runtime/generate_urk_learning_update_governance_report.py`
38. `docs/plans/methodology/MASTER_PLAN_URK_LEARNING_UPDATE_GOVERNANCE_REPORT.json`
39. `docs/plans/methodology/MASTER_PLAN_URK_LEARNING_UPDATE_GOVERNANCE_REPORT.md`
40. `docs/plans/methodology/M9_P10_2_URK_KERNEL_REGISTRY_AND_ADMIN_CATALOG_BASELINE.md`
41. `configs/runtime/kernel_registry.json`
42. `scripts/runtime/check_urk_kernel_registry.py`
43. `scripts/runtime/generate_urk_kernel_catalog.py`
44. `docs/admin/URK_KERNEL_CATALOG.md`
45. `docs/plans/methodology/M9_P3_3_URK_REALITY_WORLD_STATE_COHERENCE_BASELINE.md`
46. `scripts/runtime/generate_urk_reality_world_state_coherence_report.py`
47. `docs/plans/methodology/MASTER_PLAN_URK_REALITY_WORLD_STATE_COHERENCE_REPORT.json`
48. `docs/plans/methodology/MASTER_PLAN_URK_REALITY_WORLD_STATE_COHERENCE_REPORT.md`
49. `docs/plans/methodology/M9_P5_2_URK_REALITY_TEMPORAL_TRUTH_BASELINE.md`
50. `scripts/runtime/generate_urk_reality_temporal_truth_report.py`
51. `docs/plans/methodology/MASTER_PLAN_URK_REALITY_TEMPORAL_TRUTH_REPORT.json`
52. `docs/plans/methodology/MASTER_PLAN_URK_REALITY_TEMPORAL_TRUTH_REPORT.md`
53. `docs/plans/methodology/M10_P3_1_URK_SELF_LEARNING_GOVERNANCE_KERNEL_BASELINE.md`
54. `scripts/runtime/generate_urk_self_learning_governance_report.py`
55. `docs/plans/methodology/MASTER_PLAN_URK_SELF_LEARNING_GOVERNANCE_REPORT.json`
56. `docs/plans/methodology/MASTER_PLAN_URK_SELF_LEARNING_GOVERNANCE_REPORT.md`
57. `docs/plans/methodology/M10_P6_1_URK_SELF_HEALING_RECOVERY_KERNEL_BASELINE.md`
58. `scripts/runtime/generate_urk_self_healing_recovery_report.py`
59. `docs/plans/methodology/MASTER_PLAN_URK_SELF_HEALING_RECOVERY_REPORT.json`
60. `docs/plans/methodology/MASTER_PLAN_URK_SELF_HEALING_RECOVERY_REPORT.md`
61. `docs/plans/methodology/M10_P10_3_URK_LEARNING_HEALING_BRIDGE_KERNEL_BASELINE.md`
62. `scripts/runtime/generate_urk_learning_healing_bridge_report.py`
63. `docs/plans/methodology/MASTER_PLAN_URK_LEARNING_HEALING_BRIDGE_REPORT.json`
64. `docs/plans/methodology/MASTER_PLAN_URK_LEARNING_HEALING_BRIDGE_REPORT.md`
65. `docs/plans/methodology/M10_P10_4_URK_KERNEL_ACTIVATION_ENGINE_BASELINE.md`
66. `scripts/runtime/generate_urk_kernel_activation_engine_report.py`
67. `docs/plans/methodology/MASTER_PLAN_URK_KERNEL_ACTIVATION_ENGINE_REPORT.json`
68. `docs/plans/methodology/MASTER_PLAN_URK_KERNEL_ACTIVATION_ENGINE_REPORT.md`
69. `docs/plans/methodology/M10_P11_1_URK_KERNEL_CONTROL_PLANE_BASELINE.md`
70. `scripts/runtime/generate_urk_kernel_control_plane_report.py`
71. `docs/plans/methodology/MASTER_PLAN_URK_KERNEL_CONTROL_PLANE_REPORT.json`
72. `docs/plans/methodology/MASTER_PLAN_URK_KERNEL_CONTROL_PLANE_REPORT.md`
73. `docs/plans/methodology/M10_P11_2_URK_RUNTIME_ACTIVATION_RECEIPT_DISPATCH_BASELINE.md`
74. `scripts/runtime/generate_urk_runtime_activation_receipt_dispatch_report.py`
75. `docs/plans/methodology/MASTER_PLAN_URK_RUNTIME_ACTIVATION_RECEIPT_DISPATCH_REPORT.json`
76. `docs/plans/methodology/MASTER_PLAN_URK_RUNTIME_ACTIVATION_RECEIPT_DISPATCH_REPORT.md`

---

## 4. ML/Experiment Governance Authority

1. `docs/plans/methodology/ML_TRAINING_AUTOMATION_GOVERNANCE.md`
2. `docs/EXPERIMENT_REGISTRY.md`
3. `docs/ML_MODEL_TRAINING_CHECKLIST.md`
4. `docs/ML_SIMULATION_EXPERIMENT_LOG.md`
5. `configs/ml/feature_label_contracts.json`
6. `configs/ml/avrai_native_type_contracts.json`
7. `configs/experiments/EXPERIMENT_REGISTRY.csv`

---

## 5. Security/Privacy/Autonomy Governance Authority

1. `docs/security/RED_TEAM_TEST_MATRIX.md`
2. `docs/security/SECURITY_ARCHITECTURE.md`
3. `docs/compliance/GDPR_COMPLIANCE.md`
4. `docs/compliance/CCPA_COMPLIANCE.md`
5. `configs/runtime/security_cryptographic_assurance_controls.json`
6. `scripts/runtime/generate_security_cryptographic_assurance_report.py`
7. `docs/plans/methodology/M0_P2_1_SECURITY_CRYPTOGRAPHIC_ASSURANCE_BASELINE.md`
8. `docs/plans/methodology/MASTER_PLAN_SECURITY_CRYPTOGRAPHIC_ASSURANCE_REPORT.json`
9. `docs/plans/methodology/MASTER_PLAN_SECURITY_CRYPTOGRAPHIC_ASSURANCE_REPORT.md`

---

## 6. Update Rules (Mandatory)

When changing URK/runtime behavior, update at minimum:

1. architecture blueprint/contracts (Section 2),
2. plan/board traceability docs (Section 3),
3. Master Plan references (Section 1),
4. CI guard expectations in `docs/GITHUB_ENFORCEMENT_SETUP.md`.

When changing model/training behavior, also update:

1. ML governance and registries (Section 4),
2. corresponding board milestone evidence.

When changing privacy/security/autonomy boundaries, also update:

1. security/compliance docs (Section 5),
2. red-team test matrix mappings,
3. privacy-mode claims and no-egress assertions where applicable.

---

## 7. Recommended Change Checklist

1. Update this index if any canonical wiring doc is added/renamed.
2. Update `docs/MASTER_PLAN.md` top references if new authority docs are introduced.
3. Update `docs/plans/architecture/ARCHITECTURE_INDEX.md` for architecture additions.
4. Update `docs/plans/methodology/PRD_EXECUTION_BOARD_INTEGRATION.md` when metadata/PR traceability rules change.
5. Regenerate board/artifact outputs and run guard checks before merge.
