# AI Learning in SPOTS — User Journey Map (Install → Long‑Term Stability)

**Date:** 2026-01-02  
**Status:** Active reference (device-first, ai2ai-first)  
**Audience:** Product + engineering  
**Goal:** A single map of **how learning works** across **AI2AI**, **vibes/knots**, **federated learning**, and **user interaction**, from first install through long-term stability.

---

## Core philosophy (what we’re optimizing for)

SPOTS is a **skeleton key**: it helps users open doors to places → communities → events → people → meaning.  
The system should learn from **what doors the user actually opens**, not from what an LLM says.

Primary source: `OUR_GUTS.md` and `docs/plans/philosophy_implementation/SPOTS_PHILOSOPHY_AND_ARCHITECTURE.md`.

---

## “Source of truth” principles (non‑negotiable)

- **Device-first personality truth**: onboarding answers map to the 12 dimensions **on-device** (no network dependency).
- **LLM is an elicitation tool**: it helps generate options/prompts; **the truth is what the user chose/rejected/edited/revisited**.
- **AI2AI-first learning**: offline AI2AI exchanges are the least invasive, most “real-world-aligned” learning surface.
- **Truthful compatibility**: when we show “vibe score/compatibility”, it must come from the **quantum + knot** system (with graceful degradation).
- **Safety from above**: model rollouts are guarded by user-facing quality signals (“agent happiness”) and roll back automatically.

---

## Key identities + privacy boundaries

- **`userId`**: Supabase auth user id (PII-adjacent identifier; should stay inside device + user’s authenticated context).
- **`agentId`**: privacy-protected identifier used across learning + storage boundaries.
- **Local stores**: Sembast + SharedPreferences (device-scoped), Secure Storage (keys), optional local file system for model packs.
- **Network boundaries**:
  - AI2AI transport is **mediated** (Signal + AI2AI protocol), even when Bluetooth is used as transport.
  - Supabase edge functions are used for selective sync/aggregation (never “truth override” of local personality).

---

## System map (high-level)

```mermaid
flowchart TD
  subgraph Device["User device (offline-first)"]
    UI[User interactions]
    ONB[OnboardingDataService + OnboardingSuggestionEventStore]
    PERS[PersonalityLearning (12D) + QuantumVibeEngine]
    KNOT[PersonalityKnotService / EntityKnotService]
    VIBE[VibeCompatibilityService (truthful scores)]
    LLM[LLMService (cloud/local switch)]
    PACK[Local LLM pack (download/activate)]
    BOOT[Local LLM bootstrap (deterministic memory)]
    AI2AI[VibeConnectionOrchestrator (BLE + Signal + learning insights)]
    FEDQ[Federated cloud queue (optional)]
    NN[CallingScore + OutcomePrediction (ONNX + logging)]
    SAFE[ModelSafetySupervisor + agent happiness]
  end

  subgraph Edge["Supabase edge + storage (optional enhancement)"]
    OA[onboarding-aggregation (stores aggregation; mirrors device mapping)]
    FS[federated-sync (stores deltas; aggregate later)]
    LLMF[LLM edge functions (cloud chat/generation)]
    MAN[local-llm-manifest (signed manifest envelope)]
  end

  UI --> ONB
  ONB --> PERS
  PERS --> KNOT
  PERS --> VIBE
  KNOT --> VIBE

  PACK --> BOOT --> LLM
  UI --> LLM
  LLM -->|cloud| LLMF

  AI2AI --> PERS
  AI2AI --> FEDQ --> FS

  UI --> NN --> SAFE
  PACK --> SAFE
  SAFE --> PACK
  SAFE --> NN

  ONB --> OA
  PACK --> MAN
```

---

## Journey timeline: Install → onboarding → daily use → long-term stability

## Current vs planned (small legend)

- **DONE**: implemented and used in the product path
- **PARTIAL**: implemented, but has placeholders / not fully “learning” yet
- **PLANNED**: documented architecture/plan; not fully wired into runtime

### Subsystem status (compact)

- **Onboarding → 12D mapping (device-first)**: **DONE** (`PersonalityLearning.initializePersonalityFromOnboarding`, `OnboardingDimensionMapper`)
- **Onboarding structured signals (events + provenance)**: **DONE** (baseline lists emits events; store exists) / **PLANNED** (expand to every onboarding suggestion surface)
- **Quantum compilation of dimensions**: **PARTIAL** (best-effort; continues on failure)
- **Knot generation + storage**: **PARTIAL** (best-effort; depends on native runtime availability)
- **Truthful “vibe score” (quantum+knot breakdown)**: **DONE** (kernel exists: `VibeCompatibilityService`) / **PLANNED** (converge all “compatibility” displays to this kernel)
- **Local LLM download (opt-out, Wi‑Fi-first) + progress**: **DONE** (`LocalLlmAutoInstallService`, `LocalLlmProvisioningStateService`)
- **Local LLM bootstrap (onboarding → deterministic memory)**: **DONE** (bootstraps on install; supports refinement picks)
- **LLM routing (local when installed, cloud otherwise)**: **DONE** (`LLMService._selectBackend` + local prompt injection)
- **AI2AI walk-by discovery + compatibility + passive learning**: **DONE** (hot path + learning insight application)
- **Federated (Pattern 1) BLE gossip forwarding**: **DONE** (limited hop, quality gated)
- **Federated (Pattern 2) optional cloud sync of bounded deltas**: **DONE** (queue + edge invoke) / **PLANNED** (server-side aggregation into usable priors)
- **Federated deltas → on-device ONNX weight updates**: **PARTIAL** (`OnnxDimensionScorer.updateWithDeltas` is placeholder)
- **Neural models (calling score + outcome prediction) inference**: **DONE** (hybrid path + fallbacks)
- **Neural training loop closure (logging → retrain → deploy)**: **PARTIAL** (logging exists; automated retrain/deploy is plan-backed)
- **Safety from above (happiness-gated rollouts + rollback)**: **DONE** (`ModelSafetySupervisor` covers neural + local LLM pack)

### Stage 0 — Install + first app open (pre-onboarding / “workable” baseline)

- **User journey interactions**
  - **[UX-000]** Install app, open app.
  - **[UX-001]** (Optional) sign in / create account.
  - **[UX-002]** (Optional) enable “On-device AI” (defaults ON for eligible devices; opt-out).

- **AI learning moments**
  - **[LM-000]** “Local LLM eligibility + opt-out default” is evaluated on-device via capability gate.
  - **[LM-001]** Local LLM pack auto-install may start (Wi‑Fi-first) and records provisioning state/progress.

- **What runs**
  - **Local pack auto-install**: `LocalLlmAutoInstallService.maybeAutoInstall()` called at startup (`lib/main.dart`).
  - **Model safety**: local pack activation is tracked as a rollout candidate (`ModelSafetySupervisor`, `ModelSafetySupervisor.startRolloutCandidate()` via pack manager).

- **Data written**
  - SharedPreferences:
    - `offline_llm_enabled_v1` (opt-out default)
    - `local_llm_provisioning_*` (phase + progress)
    - `local_llm_active_model_*` (active pack pointers once installed)

---

### Stage 1 — Onboarding (Phase 8)

- **User journey interactions**
  - **[UX-010]** Answer onboarding questions (homebase, preferences, favorite places, baseline lists, social connections).
  - **[UX-011]** Select/deselect/edit baseline lists (first “door preference” signal).
  - **[UX-012]** Connect social accounts (optional) to enrich signals.

- **AI learning moments**
  - **[LM-010]** Onboarding answers are saved locally (`OnboardingDataService`) keyed by agentId.
  - **[LM-011]** Onboarding suggestion surfaces log events with provenance + user reaction (`OnboardingSuggestionEventStore`).
  - **[LM-012]** Device computes initial 12D personality insights (local mapping), then applies quantum compilation (best-effort).
  - **[LM-013]** Knot generation (best-effort) from the initial personality profile.

- **Truth contract (important)**
  - **On-device mapping is authoritative**: onboarding → dimensions happens locally; the edge “aggregation” is a mirror/analytics store.
  - Local mapper: `OnboardingDimensionMapper` + `PersonalityLearning.initializePersonalityFromOnboarding(...)`.

- **Data written**
  - Sembast:
    - onboarding data (agentId-scoped)
    - onboarding suggestion events (append-only)
  - Optional edge write (non-blocking):
    - onboarding aggregation storage in Supabase (`onboarding-aggregation`)

---

### Stage 2 — First “doors” after onboarding (early sessions)

- **User journey interactions**
  - **[UX-020]** Browse suggested lists/spots/events.
  - **[UX-021]** Save/like/respect a spot or list.
  - **[UX-022]** Join a community from discovery (community door).
  - **[UX-023]** Attend an event / provide feedback (rating).
  - **[UX-024]** Chat with the AI (local if pack installed; cloud otherwise).

- **AI learning moments**
  - **[LM-020]** Personality evolves from user actions (dimension updates) — this is the core “doors opened” learning loop.
  - **[LM-021]** Calling score + outcome prediction run; training data is logged (best-effort).
  - **[LM-022]** Truthful compatibility scores (quantum + knot) should drive rankings where “match/compat” is shown.
  - **[LM-023]** If local LLM becomes available mid-journey, bootstrap runs and may ask 1–3 refinement picks (only if onboarding used heuristics).

- **LLM behavior (downloaded local LLM impact)**
  - If a local pack is installed + enabled:
    - `LLMService` selects local backend.
    - A deterministic “system prompt” is injected for local chat using onboarding signals (`LocalLlmPostInstallBootstrapService`).
  - If not:
    - `LLMService` uses cloud backend when online.
    - Onboarding quality must still be preserved via structured event capture + heuristics fallback.

---

### Stage 3 — AI2AI learning in the wild (ongoing, offline-first)

- **User journey interactions**
  - **[UX-030]** User enables “discovery” (walk-by connections).
  - **[UX-031]** User is near other users/businesses in real space (BLE scan windows capture proximity).
  - **[UX-032]** User may receive “doors to people” suggestions (community/event/people doors).

- **AI learning moments**
  - **[LM-030]** Device discovers nearby AI nodes, reads anonymized vibe payload, computes compatibility locally.
  - **[LM-031]** Incoming learning insight messages (Signal-mediated) evolve personality on-device (`evolveFromAI2AILearning`).
  - **[LM-032]** Optional federated behaviors:
    - **BLE gossip forwarding** (limited hop) to propagate high-quality learning insights offline.
    - **Cloud sync** (edge `federated-sync`) of bounded deltas (optional).

- **Notes**
  - AI2AI learning is throttled to avoid noise-driven drift (cooldowns + quality thresholds).
  - “Federated learning” in this repo currently exists in **two forms**:
    - AI2AI learning-insight deltas + cloud queue (`federated_learning_codec.dart` + `federated-sync`)
    - EmbeddingDeltaCollector + OnnxDimensionScorer updates (placeholder application until ONNX weight updates are real)

---

### Stage 4 — Long-term stability (long-horizon)

- **User journey interactions**
  - **[UX-040]** User changes cities/life context; behavior patterns shift.
  - **[UX-041]** User’s communities + routines evolve.
  - **[UX-042]** User occasionally adjusts preferences or opts out of certain learning modes.

- **AI learning moments**
  - **[LM-040]** Contextual personality prevents homogenization (core identity + contextual layers + life-phase timeline).
  - **[LM-041]** Model rollouts are guarded:
    - Neural models (calling/outcome) and local LLM packs roll back automatically if happiness drops.
  - **[LM-042]** Long-horizon “network wisdom” can enhance recommendations without overriding local truth.

---

## Catalog: Key user interactions (explicitly marked)

- **Install + provisioning**
  - **[UX-000]** Install/open app
  - **[UX-002]** Toggle offline LLM (opt-out; defaults ON if eligible)
  - **[UX-003]** View download/provisioning state (queued/downloading/installed/error)
  - **[UX-004]** Provide refinement picks after local pack install (optional)

- **Onboarding**
  - **[UX-010]** Provide onboarding answers
  - **[UX-011]** Baseline lists select/deselect/edit/skip (logged with provenance)
  - **[UX-012]** Connect social accounts (optional)

- **Core product**
  - **[UX-020]** Browse discovery surfaces
  - **[UX-021]** Save/like/respect interactions
  - **[UX-022]** Join/leave communities
  - **[UX-023]** Attend event + rate/feedback
  - **[UX-024]** Chat with AI (local/cloud)

- **AI2AI**
  - **[UX-030]** Enable discovery (walk-by)
  - **[UX-031]** Physical proximity encounter (BLE)
  - **[UX-032]** Respond to “doors to people” suggestions

---

## Catalog: Key AI learning moments (explicitly marked)

- **Provisioning + safety**
  - **[LM-000]** Device capability gate selects local tier (or none)
  - **[LM-001]** Pack download + activation + rollback safety candidate
  - **[LM-002]** Agent happiness monitoring triggers rollbacks (“protect from above”)

- **Onboarding**
  - **[LM-010]** Save onboarding data locally (agentId-scoped)
  - **[LM-011]** Append suggestion events with provenance + reaction
  - **[LM-012]** Local 12D mapping + quantum compilation
  - **[LM-013]** Knot generation for identity + matching (best-effort)

- **Daily learning**
  - **[LM-020]** Evolve personality from user actions (doors opened)
  - **[LM-021]** Calling score + outcome prediction produce training rows (best-effort logging)
  - **[LM-022]** Truthful compatibility (quantum + knot) used for matching/ranking explainability

- **AI2AI + federated**
  - **[LM-030]** Walk-by compatibility + passive learning
  - **[LM-031]** Apply incoming learning insight (bounded deltas + throttling)
  - **[LM-032]** Optional federated cloud sync of deltas (edge `federated-sync`)

- **Long-term stability**
  - **[LM-040]** Contextual personality drift resistance (core vs contexts vs life phases)
  - **[LM-041]** Safe rollout governance across all models (neural + local LLM packs)

---

## Concrete implementation anchors (source of truth in repo)

- **On-device onboarding → personality mapping (authoritative)**
  - `lib/core/ai/personality_learning.dart` (initialization + quantum compilation)
  - `lib/core/services/onboarding_dimension_mapper.dart` (mapping logic)

- **Onboarding signals storage**
  - `lib/core/services/onboarding_data_service.dart`
  - `lib/core/services/onboarding_suggestion_event_store.dart`
  - `lib/core/models/onboarding_suggestion_event.dart`

- **Local LLM download + bootstrap**
  - Startup auto-install: `lib/main.dart` + `LocalLlmAutoInstallService`
  - Pack manager: `lib/core/services/local_llm/model_pack_manager.dart`
  - Provisioning state: `lib/core/services/local_llm/local_llm_provisioning_state_service.dart`
  - Bootstrap: `lib/core/services/local_llm/local_llm_post_install_bootstrap_service.dart`
  - Local prompt injection: `lib/core/services/llm_service.dart`
  - UX: `lib/presentation/pages/settings/on_device_ai_settings_page.dart`
  - Architecture: `docs/plans/onboarding/ONBOARDING_LLM_DOWNLOAD_AND_BOOTSTRAP_ARCHITECTURE.md`

- **AI2AI learning + federated sync (hybrid)**
  - Orchestrator: `lib/core/ai2ai/connection_orchestrator.dart`
  - Federated delta shaping: `lib/core/ai2ai/federated_learning_codec.dart`
  - Edge receiver: `supabase/functions/federated-sync/index.ts`

- **Truthful vibe compatibility (quantum + knot)**
  - `lib/core/services/vibe_compatibility_service.dart` (`QuantumKnotVibeCompatibilityService`)

- **Neural models + data**
  - `lib/core/services/calling_score_calculator.dart`
  - `lib/core/services/outcome_prediction_service.dart`
  - `lib/core/services/calling_score_data_collector.dart`
  - Model versioning: `lib/core/ml/model_version_registry.dart`
  - Safety: `lib/core/services/model_safety_supervisor.dart`

---

## What “works best” (recommended operating mode)

- **Phase 0 (shipping baseline)**
  - Local onboarding mapping is the truth.
  - Local LLM is opt-out and Wi‑Fi-first, but onboarding is never blocked by pack availability.
  - Every onboarding surface logs structured “suggestion events” (provenance + user reaction).
  - Vibe scores shown to users use the truthful compatibility kernel (quantum + knot), with graceful degradation.

- **Phase 8/11/12/23 (scaling learning)**
  - AI2AI learning is bounded (quality thresholds + throttles + drift resistance).
  - Federated cloud sync is optional and never overrides local personality; it only provides priors/aggregation.
  - Neural nets augment the calling system; they are guarded by model safety + happiness rollbacks.

---

## Open gaps / planned upgrades (explicitly marked)

- **ONNX delta application is placeholder**: `OnnxDimensionScorer.updateWithDeltas()` logs but does not update weights yet.
- **Cloud intelligence sync upload is placeholder**: `CloudIntelligenceSync._uploadConnectionToCloud()` is TODO.
- **Wider adoption of truthful compatibility**: some callers still use older compatibility paths; should converge on `VibeCompatibilityService` where “compatibility” is displayed.

