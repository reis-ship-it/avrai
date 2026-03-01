# M10-P11-2 URK Runtime Activation Receipt Dispatch Baseline

## Summary

Implements runtime dispatch wiring that turns concrete runtime decisions into activation-engine evaluations and persisted control-plane activation receipts.

Initial wired runtime paths:

1. Conviction gate decisions (`policy_violation_detected`, `runtime_health_breach`, `release_candidate_validation`)
2. Online learning successful retraining (`learning_patch_candidate`)
3. AI2AI private-mesh learning application (`ai2ai_private_mesh_sync`)
4. Admin control-plane kernel state changes (`admin_control_plane_state_change`)
5. Business runtime replication validation (`business_runtime_request` / failure triggers)
6. Expert runtime replication validation (`expert_runtime_request` / failure triggers)
7. General user runtime path for recommendations/training-first signals (`event_ops_shadow_execution` / failure triggers)
8. Handoff dependency for dedicated user-runtime intake kernel planning (`M11-P3-1`)
9. User-runtime learning intake dispatch reads persisted settings consent (`user_runtime_learning_enabled`) before emitting `user_runtime_learning_signal`; AI2AI consent remains an independent control.

## Scope

1. Dispatcher: `lib/core/controllers/urk_runtime_activation_receipt_dispatcher.dart`
2. Runtime integrations:
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
3. Tests:
   - `test/unit/controllers/urk_runtime_activation_receipt_dispatcher_test.dart`
   - `test/unit/controllers/conviction_shadow_gate_test.dart`
   - `test/unit/controllers/conviction_shadow_gate_persistence_test.dart`
   - `test/unit/services/urk_stage_d_business_runtime_replication_contract_test.dart`
   - `test/unit/services/urk_stage_d_expert_runtime_replication_contract_test.dart`
   - `test/unit/services/business_service_urk_runtime_dispatch_test.dart`
   - `test/unit/services/expert_recommendations_service_test.dart`
   - `test/unit/controllers/urk_stage_b_event_ops_shadow_runtime_contract_test.dart`
   - `test/unit/services/event_recommendation_urk_runtime_dispatch_test.dart`
4. Controls: `configs/runtime/urk_runtime_activation_receipt_dispatch_controls.json`
5. Report generator: `scripts/runtime/generate_urk_runtime_activation_receipt_dispatch_report.py`
6. Generated reports:
   - `docs/plans/methodology/MASTER_PLAN_URK_RUNTIME_ACTIVATION_RECEIPT_DISPATCH_REPORT.json`
   - `docs/plans/methodology/MASTER_PLAN_URK_RUNTIME_ACTIVATION_RECEIPT_DISPATCH_REPORT.md`

## Exit Criteria

1. Runtime path coverage meets threshold for all wired flows.
2. Trigger mapping coverage meets threshold and has zero collisions.
3. Receipt persistence coverage meets threshold with zero untracked activations.
4. Dispatcher, AI2AI orchestrator, business/expert runtime replication, control-plane, and conviction-gate tests pass in CI.
