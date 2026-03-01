# 27 - Large File Split Backlog and Queue (3-Prong)

Date: 2026-02-27
Purpose: keep decomposition work ordered, bounded, and cross-OS safe while Phase 1 continues.

## Selection Rule

- Prioritize files above ~1200 LOC with mixed concerns.
- Split by boundary:
  - Reality Engine: cognition/learning/prediction/planning.
  - Runtime OS: transport/identity/storage/capability/scheduling/security.
  - App: pages/widgets/blocs/workflows.
- Preserve a compatibility facade during each split pass.

## Immediate Queue (next)

1. `lib/core/ai2ai/connection_orchestrator.dart` (~4.5k)
2. `lib/core/services/social_media/social_media_connection_service.dart` (~2.7k)
3. `lib/injection_container.dart` (~1.8k)
4. `lib/core/services/community/community_service.dart` (~1.8k)
5. `lib/core/ai/feedback_learning.dart` (~1.6k)
6. `lib/core/services/ai_infrastructure/llm_service.dart` (~1.5k)
7. `lib/core/services/quantum/real_time_user_calling_service.dart` (~1.5k)

## Target Split Shapes

### A) `connection_orchestrator.dart` (Runtime OS)
- `ai2ai/discovery/` (scan/candidate ranking)
- `ai2ai/routing/` (cooldown/worthiness/session pathing)
- `ai2ai/trust/` (identity/provenance/credibility decisions)
- `ai2ai/resilience/` (retry/backoff/heal/failure handoff)
- `ai2ai/telemetry/` (latency/window/slo emission)

### B) `social_media_connection_service.dart` (Runtime OS)
- `social_media/oauth/` (auth flows)
- `social_media/sync/` (token/profile sync lanes)
- `social_media/mapping/` (platform normalization/contracts)
- `social_media/fallbacks/` (test/degraded behavior)
- `social_media/cache/` (profile/token cache controls)

### C) `community_service.dart` (App domain + Runtime adapter edge)
- `community/policy/`
- `community/orchestrator/`
- `community/repository_adapter/`
- `community/analytics/`

### D) `feedback_learning.dart` (Reality Engine)
- `ai/learning/feedback_ingestion/`
- `ai/learning/feedback_weighting/`
- `ai/learning/feedback_outcomes/`
- `ai/learning/feedback_runtime_adapters/`

### E) `llm_service.dart` (Runtime OS + Engine adapter edge)
- `ai_infrastructure/model_runtime/`
- `ai_infrastructure/prompt_pipeline/`
- `ai_infrastructure/safety_filters/`
- `ai_infrastructure/provider_adapters/`

## Cross-OS Compatibility Requirements (all splits)

- Runtime modules must read host capability contract first:
  - `configs/runtime/capabilities/ios.json`
  - `configs/runtime/capabilities/android.json`
  - `configs/runtime/capabilities/macos.json`
  - `configs/runtime/capabilities/windows.json`
  - `configs/runtime/capabilities/linux.json`
  - `configs/runtime/capabilities/web.json`
- Never hard-assume BLE/Wi-Fi Direct/P2P availability.
- Always provide degraded path for `minimal` tier.

## Gate Checklist Per Split PR

1. `dart analyze` on touched modules.
2. Relevant unit tests green.
3. `python3 scripts/ci/check_three_prong_boundaries.py` passes.
4. `python3 scripts/ci/check_runtime_capability_contracts.py` passes.
5. `dart run scripts/ci/check_architecture.dart` passes.
6. `bash scripts/ci/run_headless_engine_smoke.sh` passes.
