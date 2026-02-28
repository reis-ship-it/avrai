# URK Kernel Catalog

Generated from `configs/runtime/kernel_registry.json`.

## Kernel Inventory

| Kernel ID | Runtime Scope | Prong | Privacy Modes | Impact | Lifecycle | Milestone | Purpose |
| --- | --- | --- | --- | --- | --- | --- | --- |
| urk_kernel_activation_engine | shared | runtime_core | multi_mode | L4 | enforced | M10-P7-1 | Deterministically route triggers to eligible kernels with privacy-mode and dependency gate enforcement plus activation receipts. |
| urk_kernel_control_plane | shared | governance_core | multi_mode | L4 | enforced | M10-P11-1 | Provide live kernel state, health, lineage, and guarded state transition APIs for admin runtime governance. |
| urk_kernel_promotion_lifecycle | shared | governance_core | multi_mode | L3 | enforced | M9-P10-1 | Govern kernel progression across draft, shadow, enforced, and replicated with approval chain coverage. |
| urk_learning_healing_bridge | shared | cross_prong | multi_mode | L4 | enforced | M10-P10-3 | Close the loop from incidents to validated learning updates so recovery outcomes become safe policy-governed improvements. |
| urk_learning_update_governance | shared | model_core | multi_mode | L4 | enforced | M9-P3-2 | Govern learning update validation, lineage traceability, and high-impact learning promotion safety. |
| urk_reality_temporal_truth | shared | runtime_core | multi_mode | L4 | enforced | M9-P5-2 | Align atomic and semantic time while blocking timeline contradictions and clock regressions. |
| urk_reality_world_state_coherence | shared | model_core | multi_mode | L4 | enforced | M9-P3-3 | Maintain coherence across reality-model planes/knots/strings with zero unresolved state conflicts. |
| urk_runtime_activation_receipt_dispatch | shared | runtime_core | multi_mode | L4 | enforced | M10-P11-2 | Wire runtime decisions to activation-engine evaluation and persisted control-plane receipts with deterministic trigger mapping. |
| urk_self_healing_recovery | shared | runtime_core | multi_mode | L4 | enforced | M10-P6-1 | Detect, contain, and recover runtime/model degradations with deterministic incident lineage and rollback guarantees. |
| urk_self_learning_governance | shared | model_core | multi_mode | L4 | enforced | M10-P3-1 | Continuously gate self-learning proposals with policy, quality, lineage, and promotion safety constraints. |
| urk_stage_a_trigger_privacy_no_egress | user_runtime, event_ops_runtime | runtime_core | multi_mode | L3 | replicated | M7-P7-3 | Enforce trigger coverage, privacy policy coverage, and local sovereign no-egress guarantees. |
| urk_stage_b_event_ops_shadow_runtime | user_runtime, event_ops_runtime | runtime_core | multi_mode | L3 | replicated | M7-P7-4 | Run ingest-plan-gate-observe shadow path with lineage and high-impact block guarantees. |
| urk_stage_c_private_mesh_policy_conformance | user_runtime, event_ops_runtime | governance_core | private_mesh | L3 | replicated | M7-P8-3 | Enforce private-mesh payload minimization, encryption, lineage tags, and policy gating. |
| urk_stage_d_business_runtime_replication | business_ops_runtime | runtime_core | federated_cloud | L3 | replicated | M8-P9-2 | Replicate URK request-policy-lineage-review invariants into business runtime. |
| urk_stage_d_expert_runtime_replication | expert_services_runtime | runtime_core | private_mesh | L3 | replicated | M8-P11-2 | Replicate URK request-policy-lineage-provenance-review invariants into expert runtime. |
| urk_stage_e_cross_runtime_conformance | shared | cross_prong | multi_mode | L3 | replicated | M8-P10-4 | Prove cross-runtime invariant conformance and deterministic replay across Event/Business/Expert. |
| urk_user_runtime_learning_intake | user_runtime | model_core | local_sovereign, private_mesh | L3 | draft | M11-P3-1 | Gate user-origin realtime learning intake with consent, pseudonymous actor constraints, and on-device-first safety policy. |

## Completeness Checklist

Each kernel must include: `controls`, `contract`, `test`, `report_generator`, `report_json`, `report_md`, `baseline`.

Validation command:

```bash
python3 scripts/runtime/check_urk_kernel_registry.py
```
