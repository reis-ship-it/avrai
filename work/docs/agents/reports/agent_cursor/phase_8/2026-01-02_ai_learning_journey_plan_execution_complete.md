# AI Learning Journey — Plan Execution Log (Implementation → Reality)

**Date:** 2026-01-02  
**Updated By:** Agent (Cursor)  
**Status:** ✅ Complete (engineering); ⚠️ pending real-device validation for BLE/OS variance + Signal native runtime

## Scope (what this report logs)
This report logs the work executed from the AI Learning user journey plan to:
- Keep **DONE** paths stable (regression coverage)
- Finish **PARTIAL** subsystems enough to be workable
- Make key **PLANNED** items real in runtime wiring (not just docs)
- Add at least one **acceptance-style check** for a user-visible promise

Primary reference map:
- `docs/agents/guides/AI_LEARNING_USER_JOURNEY_MAP.md`

## Executive summary
We made the “download → onboarding → first-use → learning” journey **workable** and **truthful** by:
- Enforcing **device-first** onboarding → 12D mapping as the source of truth (cloud mirrors only).
- Making **offline LLM** default **opt-out** (auto-enabled on eligible devices), while keeping downloads safe (Wi‑Fi/charging/idle gating).
- Wiring **cloud LLM failover** so chat degrades gracefully when the primary cloud path fails.
- Making federated learning **meaningfully influence** on-device scoring via a bounded, persisted personalization overlay.
- Ensuring “truthful vibe score” uses **quantum + knot** with graceful degradation when knot runtime is unavailable.

## Work completed (high signal)

### Phase 8 (Onboarding pipeline fix) — device-first truth
- Device computes onboarding → 12D locally and sends `mappingSource: device` to the edge function (mirror/analytics only):
  - `lib/core/services/onboarding_dimension_mapper.dart`
  - `lib/core/services/onboarding_aggregation_service.dart`
  - `supabase/functions/onboarding-aggregation/index.ts` (mirror behavior)
- **Acceptance-style test** to lock the contract:
  - `test/unit/services/onboarding_aggregation_device_first_acceptance_test.dart`

### Phase 8 / Phase 0 behavior (workable onboarding experience)
- Knot generation during onboarding is now **best-effort** (onboarding continues without blocking if knot runtime fails):
  - `lib/presentation/pages/onboarding/knot_discovery_page.dart`

### Phase 11 (User‑AI interaction update) — planned → real wiring
- Onboarding suggestion event coverage expanded (heuristic suggestion surfaces now log shown/select/deselect where implemented):
  - `lib/presentation/pages/onboarding/friends_respect_page.dart`
  - `lib/presentation/pages/onboarding/onboarding_page.dart` (passes `userId`)
- Cloud LLM fallback routing implemented:
  - `lib/core/services/llm_service.dart`
  - New backends:
    - `CloudFailoverBackend` (primary → fallback on transient failures)
    - `CloudGeminiGenerationBackend` (fallback via `llm-generation`)
  - Regression test:
    - `test/unit/services/llm_cloud_failover_backend_test.dart`

### Phase 12 (Neural/ML integration) — federated deltas become workable
- Federated delta vector ordering/length standardized to the canonical 12 dims:
  - `lib/core/ai2ai/embedding_delta_collector.dart`
  - Test:
    - `test/unit/ai2ai/embedding_delta_collector_test.dart`
- `OnnxDimensionScorer.updateWithDeltas` made workable via a **bounded, persisted personalization overlay** (bias):
  - `lib/core/ml/onnx_dimension_scorer.dart`
  - Test:
    - `test/unit/ml/onnx_dimension_scorer_personalization_overlay_test.dart`

### Phase 23 (AI2AI hybrid learning) — optional cloud aggregation → priors
- If `federated-sync` returns `global_average_deltas`, apply as a network prior into the on-device overlay (non-blocking):
  - `lib/core/ai2ai/connection_orchestrator.dart`
  - Edge function + table (already present, now used more fully):
    - `supabase/functions/federated-sync/index.ts`
    - `supabase/migrations/036_federated_embedding_deltas_v1.sql`

### Safety/Truthfulness regression coverage
- Truthful vibe kernel degrades to quantum-only if knot fails (no fake constants):
  - `test/unit/services/vibe_compatibility_service_truthful_degradation_test.dart`
- AI2AI learning delta application clamps to `[0,1]` (prevents drift overflow/underflow):
  - `test/unit/ai2ai/personality_learning_ai2ai_bounds_test.dart`

## Tests executed (evidence)
- `flutter test test/unit/services/llm_cloud_failover_backend_test.dart`
- `flutter test test/unit/services/onboarding_aggregation_device_first_acceptance_test.dart`
- `flutter test test/unit/ai2ai/personality_learning_ai2ai_bounds_test.dart`
- `flutter test test/unit/ai2ai/embedding_delta_collector_test.dart`

> Note: Signal-native tests are gated behind `RUN_SIGNAL_NATIVE_TESTS=true` and require native runtime availability.

## Known remaining validation (non-code blockers)
- **Real-device AI2AI smoke test** (BLE scanning + OS permission variance + background behavior).
- **Signal-native runtime** execution test run with `RUN_SIGNAL_NATIVE_TESTS=true` in an environment with the native library available.

