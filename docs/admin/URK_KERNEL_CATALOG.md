# URK Kernel Catalog

Generated from `configs/runtime/kernel_registry.json`.

## Kernel Inventory

| Kernel ID | Runtime Scope | Prong | Privacy Modes | Impact | Lifecycle | Milestone | Purpose |
| --- | --- | --- | --- | --- | --- | --- | --- |
| urk_kernel_promotion_lifecycle | shared | governance_core | multi_mode | L3 | enforced | M9-P10-1 | Govern kernel progression across draft, shadow, enforced, and replicated with approval chain coverage. |
| urk_stage_a_trigger_privacy_no_egress | user_runtime, event_ops_runtime | runtime_core | multi_mode | L3 | replicated | M7-P7-3 | Enforce trigger coverage, privacy policy coverage, and local sovereign no-egress guarantees. |
| urk_stage_b_event_ops_shadow_runtime | user_runtime, event_ops_runtime | runtime_core | multi_mode | L3 | replicated | M7-P7-4 | Run ingest-plan-gate-observe shadow path with lineage and high-impact block guarantees. |
| urk_stage_c_private_mesh_policy_conformance | user_runtime, event_ops_runtime | governance_core | private_mesh | L3 | replicated | M7-P8-3 | Enforce private-mesh payload minimization, encryption, lineage tags, and policy gating. |
| urk_stage_d_business_runtime_replication | business_ops_runtime | runtime_core | federated_cloud | L3 | replicated | M8-P9-2 | Replicate URK request-policy-lineage-review invariants into business runtime. |
| urk_stage_d_expert_runtime_replication | expert_services_runtime | runtime_core | private_mesh | L3 | replicated | M8-P11-2 | Replicate URK request-policy-lineage-provenance-review invariants into expert runtime. |
| urk_stage_e_cross_runtime_conformance | shared | cross_prong | multi_mode | L3 | replicated | M8-P10-4 | Prove cross-runtime invariant conformance and deterministic replay across Event/Business/Expert. |

## Completeness Checklist

Each kernel must include: `controls`, `contract`, `test`, `report_generator`, `report_json`, `report_md`, `baseline`.

Validation command:

```bash
python3 scripts/runtime/check_urk_kernel_registry.py
```
