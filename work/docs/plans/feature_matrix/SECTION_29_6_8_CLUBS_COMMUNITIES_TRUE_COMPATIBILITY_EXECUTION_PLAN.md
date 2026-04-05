# Section 29 (6.8): Clubs/Communities — True Compatibility + Join UX + Signal Pipeline (Execution Plan)

**Date:** 2026-01-02  
**Status:** ✅ Complete  
**Priority:** HIGH (core “doors” surface: communities)  
**Primary Master Plan References:**
- `docs/MASTER_PLAN_APPENDIX.md` → **Section 29 (6.8): Clubs/Communities**
- `docs/agents/reports/agent_2/phase_6/community_discovery_true_compatibility_addendum_2026-01-01.md` (what shipped already)

**Cross-Phase Dependencies (Onboarding + Local LLM):**
- `docs/plans/onboarding/ONBOARDING_LLM_DOWNLOAD_AND_BOOTSTRAP_ARCHITECTURE.md` (source of truth)
- `docs/plans/onboarding/ONBOARDING_PROCESS_PLAN.md` (Phase 8)

---

## 🚪 Doors / Philosophy Alignment

**What doors does this open?**
- A **community door**: users can discover and join communities that fit them (not just places).
- A **truth door**: “true compatibility” is explainable (quantum + knot topology + weave fit).
- A **memory door**: onboarding choices become persistent signals that improve offline/local AI.

**When are users ready?**
- Immediately after onboarding (first discover surface) and anytime inside Explore (community as “doors to people”).

**Is this a good key?**
- Yes if: it is privacy-preserving (agentId), explainable, fast, and doesn’t silently degrade to neutral scoring.

**Is the AI learning with the user?**
- Yes if: onboarding events + join actions are stored as structured signals and reused for future ranking + local LLM bootstrap.

---

## ✅ Current State (already implemented)

**Community discovery ranking is live** via `/communities/discover` and uses combined “true compatibility” ranking (quantum + topo + weave fit).  
**Community quantum term** uses privacy-safe 12D centroid when present (`vibeCentroidDimensions`).  
**Local persistence**: communities list + per-member centroid contributions are persisted locally (StorageService-backed local repo).  
**TTL caching**: `CommunityService.calculateUserCommunityTrueCompatibility()` caches short-lived scores.  
**Onboarding event store + local LLM bootstrap services** exist and are registered in `lib/injection_container_ai.dart`.
**Explore entry point**: Communities are now first-class under Home → Explore → **Communities**.

---

## 📋 Execution Plan (tracked, Master-Plan style)

## ✅ Implementation Status (2026-01-02)

- ✅ **6.8.1** Join directly from Discover (per-card Join + loading state + optimistic remove)
- ✅ **6.8.2** True-compatibility breakdown DTO exposed + shown in UI
- ✅ **6.8.3** Bounded concurrency scoring (avoid unbounded parallelism) + TTL cache invalidation hooks
- ✅ **6.8.4** Centroid lifecycle w/ privacy-safe per-member contributions + quantization + leave recompute
- ✅ **6.8.5** Community timestamps aligned to `AtomicClockService` (best-effort server-time via `AtomicClockService`)
- ✅ **6.8.6** Supabase schema + repository layer + local-first hybrid sync behind feature flag (`communities_supabase_sync_v1`)
- ✅ **8.5.1** OnboardingSuggestionEventStore DI-decoupled + tests
- ✅ **8.5.2** Local LLM post-install bootstrap hardened + install-flow integrations + tests

### 6.8.1 — Ship “Join” directly from Discover

**Goal:** From `CommunitiesDiscoverPage`, users can join a community without leaving the list.

**Implementation:**
- Add a per-card **Join** button calling `CommunityService.addMember(communityId, userId)`.
- Disable button + show progress spinner during join.
- Update card UI to reflect joined state (e.g., “Joined” badge) and refresh ranking list.

**Acceptance:**
- User can join from Discover in < 1 tap (auth required).
- Join action updates UI state immediately (optimistic or post-success).
- Failures are surfaced with user-friendly messaging (and logged).

**Tests:**
- Widget test: discover list renders, tap Join updates card state.
- Unit test: `CommunityService.addMember` invalidates true-compat cache and persists.

---

### 6.8.2 — Expose true-compatibility breakdown (quantum/topo/weave) to UI

**Goal:** The UI can show explainability for the combined score without re-running expensive work multiple times.

**Implementation:**
- Add a DTO (e.g., `CommunityTrueCompatibilityBreakdown`) and method in `CommunityService`:
  - `calculateUserCommunityTrueCompatibilityBreakdown(userId, communityId)`
  - returns `{ quantum, topological, weaveFit, combined }` + optional debug fields.
- Update `CommunitiesDiscoverPage` to display breakdown (collapsed by default).

**Acceptance:**
- Breakdown values sum correctly to combined using the canonical weights.
- UI can show breakdown without a second full recomputation per card.

**Tests:**
- Unit test: breakdown combined matches `calculateUserCommunityTrueCompatibility`.

---

### 6.8.3 — Performance polish for discovery ranking

**Goal:** Ranking stays responsive for 100–500 communities.

**Implementation:**
- Compute per-community scores with `Future.wait` **with a concurrency cap** (avoid 500 parallel tasks).
- Keep TTL cache; add invalidation triggers on join/leave and centroid updates (already partly done).
- Add pagination hooks (UI incremental load) as follow-up if needed.

**Acceptance:**
- Discover page completes scoring without UI jank on moderate lists.

**Tests:**
- Unit test: cache hit avoids recompute within TTL.

---

### 6.8.4 — Centroid correctness + lifecycle (join + leave) with privacy

**Goal:** Community centroid remains correct across joins/leaves without requiring full member profile access.

**Implementation (local-first):**
- Store **per-member anonymized centroid contributions** (12D map) keyed by `(communityId, agentId)` in local persistence.
- On join: write contribution + recompute centroid as mean of active contributions.
- On leave: delete/deactivate contribution + recompute centroid.
- Add DP/quantization (e.g., 32–64 bins) to reduce reconstruction risk.

**Acceptance:**
- Leave updates centroid correctly (not “neutral reset”).
- Centroid remains bounded to `[0,1]` and includes all 12 dimensions.
- Privacy: stored vectors are anonymized + optionally quantized; never store raw `PersonalityProfile`.

**Tests:**
- Unit test: join then leave returns centroid to previous value (within tolerance if quantized).
- Unit test: recompute path works after storage hydration.

---

### 6.8.5 — Align with AtomicClockService requirement

**Goal:** Community timestamps follow `AtomicClockService` instead of `DateTime.now()`.

**Implementation:**
- Inject `AtomicClockService` into `CommunityService` (optional default allowed).
- Replace `DateTime.now()` usages for community mutation timestamps (created/updated/joined where applicable).
- Update docs where reality differed previously.

**Acceptance:**
- All community/club timestamps originate from `AtomicClockService`.

**Tests:**
- Unit test: timestamps equal deterministic injected clock values.

---

### 6.8.6 — Backend persistence (Supabase) behind a feature flag

**Goal:** Real persistence + multi-device sync while staying local-first.

**Implementation:**
- Add migrations:
  - `communities_v1`
  - `community_members_v1`
  - `community_vibe_contributions_v1` (optional but recommended for centroid lifecycle)
- Define RLS policies (user can only mutate their own membership + contribution).
- Introduce repository interface(s):
  - `CommunityRepository` (domain)
  - `LocalCommunityRepository` (Sembast/StorageService)
  - `SupabaseCommunityRepository` (remote)
- `CommunityService` becomes orchestration:
  - read local first
  - write local, enqueue remote sync
  - conflict policy: last-write-wins for mutable fields; append-only for membership.

**Acceptance:**
- Feature flag can disable Supabase path entirely with no behavior change.
- Local-first behavior preserved even when remote fails.

**Tests:**
- Unit tests for local repository behavior (no mocks/stubs; use real local store).
- Integration tests for Supabase repository **behind flag** (skipped if env not configured).

---

### 8.5.1 — OnboardingSuggestionEventStore: remove DI coupling + expand event schema usage

**Goal:** Onboarding surfaces emit structured events without importing `injection_container.dart`.

**Implementation:**
- Refactor `OnboardingSuggestionEventStore` to resolve dependencies via `GetIt` (safe optional lookup) rather than `di.sl`.
- Expand write coverage to key onboarding surfaces (minimum):
  - baseline lists: shown/select/deselect/edit/skip
  - (follow-up) onboarding recommendation surfaces as they exist

**Acceptance:**
- Store usable in tests without pulling in heavy DI / platform bindings.
- Event payloads include: `surface`, `provenance`, `promptCategory`, `suggestions`, `userAction`, timestamps.

**Tests:**
- Unit test: append + load round-trip for events (single user).

---

### 8.5.2 — LocalLlmPostInstallBootstrapService hardening + install flow integration

**Goal:** When a model pack becomes installed, local LLM gets a deterministic system prompt built from onboarding signals.

**Implementation:**
- Refactor bootstrap service to avoid `injection_container.dart` imports; resolve via `GetIt` with fallbacks.
- Ensure `LocalLlmAutoInstallService` calls the bootstrap service via DI when registered (fallback to direct instantiation otherwise).
- Add guardrails:
  - if onboarding data missing → no prompt
  - if events missing → minimal prompt
  - stable prompt formatting

**Acceptance:**
- Local backend gets a system prompt injected (when available) via `LLMService`.
- No crashes if Supabase auth not initialized (best-effort bootstrap).

**Tests:**
- Unit test: given onboarding data + events, prompt is non-empty and deterministic.

---

## 📌 Notes / Risks

- **No `print()` / `debugPrint()`** in production code; use `developer.log()` or `AppLogger`.
- Avoid mocks/stubs in tests (use real local stores or purpose-built fakes only if approved).
- Be careful with privacy: avoid storing raw userId in shared/community-visible structures; use agentId where possible.

