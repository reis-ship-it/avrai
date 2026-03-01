# M4-P3-2 Conviction Gate Shadow Baseline

Date: 2026-02-27  
Milestone: `M4-P3-2`  
Status: In progress baseline artifact

## Runtime Gate Contract

1. Evaluate every request with policy signal + claim lifecycle state.
2. For high-impact actions, canonical conviction is required to pass gate policy.
3. In `shadow` mode, serve request unchanged and emit gate decision telemetry.
4. In `enforce` mode, block serving when requirements fail.

## Telemetry Persistence

1. Shadow gate decisions persist to local storage key: `conviction_gate_shadow_decisions_v1`.
2. Storage keeps the most recent bounded window for weekly/final review artifacts.
3. Default runtime sink auto-resolves from DI (`SharedPreferencesCompat`) when available.
4. Runtime mirror export is best-effort at `runtime_exports/conviction_gate_shadow_decisions.json`.

## Decision Outputs

1. `wouldAllow` (counterfactual enforcement result)
2. `servingAllowed` (actual runtime behavior)
3. `shadowBypassApplied` (explicit non-blocking bypass signal)
4. `reasonCodes` (machine-readable policy/conviction failures)

## Code Baseline

1. `lib/core/controllers/conviction_shadow_gate.dart`
2. `lib/core/controllers/list_creation_controller.dart`
3. `lib/core/controllers/event_creation_controller.dart`
4. `lib/core/controllers/ai_recommendation_controller.dart`
5. `lib/core/controllers/checkout_controller.dart`
6. `lib/core/controllers/payment_processing_controller.dart`
7. `test/unit/controllers/conviction_shadow_gate_test.dart`
8. `test/unit/controllers/conviction_shadow_gate_persistence_test.dart`
