## Phase 8 — Onboarding ↔ Local LLM download ↔ Bootstrap Enhancements

**Date:** January 2, 2026  
**Updated By:** Agent (Cursor)  
**Status:** ✅ Complete  

### Scope (this report)
Log the completed work in this chat session, end-to-end, covering:
- Post-install bootstrap refinement flow + persistence
- Download progress tracking + UI surfacing
- Stricter auto-download gating (Wi‑Fi + charging + idle)
- Safe periodic update strategy for installed packs (trusted manifest)
- Structured memory persistence (not only rendered prompt)
- Expanded onboarding suggestion provenance logging beyond baseline lists

### Summary of what changed
- **Refinement picks UI (Settings)**: Added a “Refine offline AI” flow that presents quick refinement prompts once the local model pack is installed and onboarding used heuristic fallbacks. User selections are persisted and used to regenerate the local system prompt.
- **Progress tracking**: Added coarse per-byte progress (`receivedBytes/totalBytes`) to provisioning state; updated onboarding UI to show percent + progress bar. Pack downloads now report progress via callbacks.
- **Stricter auto-install gating**: Auto-install is now gated behind **Wi‑Fi + charging/full + idle window** (00:00–06:00 local). Added queued phases to explain why a download hasn’t started yet.
- **Update strategy**: When a pack is already installed, the auto-install service performs a best-effort trusted update check (release only, once per 24h) under the same safe conditions. The pack manager skips re-download if the requested pack is already active.
- **Structured memory**: Bootstrap state now stores a structured memory profile (`LocalLlmMemoryProfile`) alongside the rendered `systemPrompt`. Prompt rendering is deterministic from the structured memory.
- **Provenance logging expanded**:
  - Favorite places suggestion surfaces now append onboarding suggestion events for shown/select/deselect actions.
  - AI loading list generation now logs the lists used/generated as a suggestion event.

### Key implementation details
#### Refinement picks → persisted selections → regenerated prompt
- `LocalLlmBootstrapState` now includes:
  - `refinementSelections` (promptId → selected option ids)
  - `memoryProfile` (`LocalLlmMemoryProfile`) for structured memory persistence
- `LocalLlmPostInstallBootstrapService.applyRefinementSelection()`:
  - persists selections
  - updates `pendingRefinementPromptIds`
  - regenerates `systemPrompt` deterministically from structured memory
  - logs a `local_llm_refinement` suggestion event (local provenance) for future learning

#### Provisioning progress reporting
- `LocalLlmProvisioningStateService` now stores:
  - `receivedBytes` / `totalBytes` and derives `progressFraction`
  - new phases: `queuedCharging`, `queuedIdle`
- `LocalLlmModelPackManager` now:
  - supports `onProgress(received,total)` callbacks for `downloadAndActivate*()`
  - verifies SHA-256 via streamed hashing (avoids reading multi‑GB files into memory)

#### Stricter auto-download gating (Wi‑Fi + charging + idle)
- `LocalLlmAutoInstallService.maybeAutoInstall()` now:
  - queues for Wi‑Fi (`queuedWifi`) and listens for connectivity changes
  - queues for charging (`queuedCharging`) and listens for battery state changes
  - queues for idle window (`queuedIdle`) and schedules a re-check timer
  - uses a battery facade (`BatteryFacade`) for testability

#### Trusted update check for installed packs
- Release builds: `_maybeAutoUpdateInstalled()` runs once per 24 hours (best effort).
- The pack manager short-circuits if `manifest.packId` is already active and installed.
- Rollout safety remains handled by `ModelSafetySupervisor` candidate tracking (already present).

### Files changed / added (high signal)
- **Bootstrap + refinement**
  - `lib/core/services/local_llm/local_llm_post_install_bootstrap_service.dart`
  - `lib/core/models/local_llm_bootstrap_state.dart`
  - `lib/core/models/local_llm_memory_profile.dart` (new)
  - `lib/presentation/pages/settings/on_device_ai_settings_page.dart`
- **Provisioning + progress**
  - `lib/core/services/local_llm/local_llm_provisioning_state_service.dart`
  - `lib/core/services/local_llm/model_pack_manager.dart`
  - `lib/core/services/local_llm/local_llm_auto_install_service.dart`
  - `lib/presentation/pages/onboarding/onboarding_page.dart`
- **Expanded provenance logging**
  - `lib/presentation/pages/onboarding/favorite_places_page.dart`
  - `lib/presentation/pages/onboarding/ai_loading_page.dart`
- **DI / plumbing (session edits)**
  - `lib/core/services/llm_service.dart` (bootstrap via GetIt when available)
  - `lib/injection_container_ai.dart` (community repository wiring — session-local change)
- **Tests (session edits)**
  - `test/unit/services/local_llm_post_install_bootstrap_service_test.dart` (migrated away from mocktail + uses real prefs + local dir)

### Docs updated in this session
- `docs/agents/status/status_tracker.md` (new update entry linking to this report)
- `docs/plans/onboarding/ONBOARDING_LLM_DOWNLOAD_AND_BOOTSTRAP_ARCHITECTURE.md` (implementation status)
- `docs/plans/architecture/LOCAL_LLM_MODEL_PACK_SYSTEM.md` (implementation status)

### Tests executed (evidence)
- `flutter test test/unit/services/local_llm_post_install_bootstrap_service_test.dart`
- `flutter test test/unit/services/local_llm_auto_install_service_wifi_gating_test.dart`
- `flutter test test/unit/services/local_llm_model_pack_manager_test.dart`
- `flutter test test/unit/services/onboarding_suggestion_event_store_test.dart`

