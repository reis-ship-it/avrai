# M11-P3-1 URK User Runtime Learning Intake Kernel Baseline

## Summary

Adds a dedicated `user_runtime` kernel contract for realtime, user-origin learning intake so training starts in-app under consent-gated, pseudonymous, on-device-first policy controls.

## Scope

1. Contract: `lib/core/services/user/urk_user_runtime_learning_intake_contract.dart`
2. Tests: `test/unit/services/urk_user_runtime_learning_intake_contract_test.dart`
3. Runtime integration path: `lib/core/services/events/event_recommendation_service.dart`
4. Runtime dispatch integration test: `test/unit/services/event_recommendation_urk_runtime_dispatch_test.dart`
5. Controls: `configs/runtime/urk_user_runtime_learning_intake_controls.json`
6. Report generator: `scripts/runtime/generate_urk_user_runtime_learning_intake_report.py`
7. Admin observability wiring:
   - `lib/core/services/admin/urk_kernel_control_plane_service.dart` (`summarizeUserRuntimeLearning`)
   - `lib/presentation/pages/admin/urk_kernel_console_page.dart` (runtime lane/mode opt-out + acceptance card)
   - `lib/core/services/admin/urk_user_runtime_observability_threshold_service.dart` (range threshold loader + local override persistence + audit events)
   - `configs/runtime/urk_user_runtime_observability_thresholds.json` (runtime controls for warning/critical thresholds + per-field validation bounds)
   - `test/unit/services/admin/urk_kernel_control_plane_service_test.dart`
   - `test/unit/services/admin/urk_user_runtime_observability_threshold_service_test.dart`
8. Generated reports:
   - `docs/plans/methodology/MASTER_PLAN_URK_USER_RUNTIME_LEARNING_INTAKE_REPORT.json`
   - `docs/plans/methodology/MASTER_PLAN_URK_USER_RUNTIME_LEARNING_INTAKE_REPORT.md`

## Runtime + Privacy Intent

1. Runtime lane: `user_runtime` (first-hop learning origin)
2. Privacy mode impact: `local_sovereign` default posture
3. Actor model: pseudonymous agent identity (`agt_*`) only
4. Consent source: persisted settings (`user_runtime_learning_enabled`) from `StorageService` determine whether `user_runtime_learning` scope is present.
5. AI2AI learning consent (`ai2ai_learning_enabled`) is separate and does not disable user-runtime learning when user-runtime consent remains enabled.
6. Safety rule: block raw sensitive content ingestion from learning intake path

## Exit Criteria

1. User-runtime intake coverage checks meet threshold.
2. Pseudonymous actor coverage is complete.
3. On-device-first processing threshold is met.
4. Raw identifier egress and missing-consent events remain at zero.
