# Phase 10 Rationale: Feature Completion, Codebase Reorganization & Polish

**Phase:** 10 | **Tier:** Parallel | **Duration:** 4-6 weeks  
**Companion to:** `docs/MASTER_PLAN.md` Phase 10  
**Read before starting:** `FOUNDATIONAL_DECISIONS.md` (Decisions #5, #9)

---

## Why This Phase Exists

Phase 10 is the cleanup and completion phase. It handles three categories:
1. **Incomplete features** from the legacy plan that still need finishing
2. **Stub/placeholder cleanup** identified by the ML Roadmap
3. **Codebase reorganization** to make the project navigable

---

## Key Design Decisions

### Why Some Reorganization Is Immediate (10.5) and Some Is Deferred (10.6)
**Immediate (10.5):** `lib/core/services/` has 196 flat files. `lib/core/models/` has 123 flat files. Navigating these directories is painful and slows every task. Organizing into domain subdirectories NOW gives new Phase 1-4 services clean landing zones. These are low-risk moves (renaming + import updates, no logic changes).

**Deferred (10.6):**
- **AI/ML consolidation** waits until after Phase 4 because Phases 3-5 will create 15-20 new files in `lib/core/ai/`. Organizing now means organizing again after those land.
- **Quantum consolidation** waits until after Phase 7 because the evolution cascade (7.1.2) rewires quantum orchestrators. Moving files during restructuring causes merge conflicts.
- **Domain layer decision** waits until Phase 7 reveals whether Clean Architecture's `domain/` layer earns its keep (currently 20 files with limited adoption).

### Why 4 Stub ML Services Need Resolution (10.2.1-10.2.4)
`PatternRecognition`, `PredictiveAnalytics`, `PreferenceLearningEngine`, and `SocialContextAnalyzer` return hardcoded values and aren't connected to any flow. They consume code space and suggest features that don't work. Either implement them via the world model or remove them.

**Watch out**: `PreferenceLearningEngine` at `lib/core/ai/continuous_learning/engines/preference_learning_engine.dart` is a DIFFERENT class from stub `PreferenceLearning` at `lib/core/ml/preference_learning.dart`. The engine is real; the stub is not.

### Why User Testing Checkpoint (10.4) Gates Phase 11
Before spending 12-20 weeks on industry integrations, validate that the intelligence-first architecture actually works. Internal dogfooding (2 weeks) and closed beta (50-100 users) must show the world model matches or beats formula baseline.

### Why Key Feature Gaps Are Listed (10.1.5-10.1.12)
Several critical services are missing or stubbed:
- `SpotRecommendationService` (10.1.5): `AIRecommendationController._getSpotRecommendations()` returns empty array
- `ListRecommendationService` (10.1.6): TODO in `AIRecommendationController`
- `BusinessExpertOutreachService.discoverExperts()` (10.1.10): returns empty list (businesses literally can't find experts)
- `BusinessBusinessOutreachService.discoverBusinesses()` (10.1.11): has TODO

These can be implemented pre-world-model using existing scoring services, then upgrade to energy functions post-world-model.

### Why Internationalization (10.3)
i18n is a prerequisite for global locality intelligence, not just cosmetic:

- **Locality intelligence**: Spots, communities, and events exist in local languages. Without i18n, locality agents can't surface relevant content for non-English markets. The world model operates on locality semantics that must be localized.

- **RTL support**: Arabic-speaking markets require right-to-left layout. Supporting RTL is a market access requirement for MENA expansion; without it, Arabic users are excluded.

- **AI explanations must be template-based and localized**: LLM-generated explanations per locale are expensive, inconsistent, and non-auditable. Template-based explanations with localized strings ensure deterministic, reviewable, and cost-effective user-facing AI output.

- **Locality agent language context**: Cross-region knowledge transfer (e.g., spot similarity across regions) requires weighting by language context. Locality agents trained on one language family may transfer poorly to another; explicit language context enables proper weighting.

### Why Accessibility (10.4)
"Every spot is a door" must apply literally to users with disabilities:

- **Literal application**: If a user cannot access spots due to missing accessibility features, the doors philosophy is broken. Accessibility is not an add-on; it is core to the value proposition.

- **Knot audio sonification**: For visually impaired users, knot audio sonification becomes a PRIMARY experience (not a novelty). It enables understanding of compatibility and mesh topology without visual reliance. This is a first-class interaction mode.

- **WCAG AA compliance**: Regulated industries (education, government, healthcare) require WCAG AA for market access. Compliance is a gate, not a nice-to-have.

- **Reduce motion mode**: Users with vestibular disorders can experience nausea or dizziness from animations. Reduce motion is essential for inclusive access, not optional.

**Version note (v12):** Phase 10 sections were renumbered: old 10.3→10.5, 10.4→10.6, 10.5→10.7, 10.6→10.8.

### Why Friend System Lifecycle (10.4A)

**The problem:** The friend system has solid foundations (QR scanning, social media discovery, encrypted chat, braided knots) but is missing critical lifecycle management. There's no unfriend, no block, no friend request state machine, no braided knot evolution over time, no tiering. Friendships are "doors" -- the most important kind -- but the system treats them as binary (connected or not), static (knots never re-weave), and flat (all friends weighted equally).

**What was missing (8 gaps identified):**
1. No `FriendshipStatus` state machine (pending, accepted, removed, blocked)
2. No unfriend implementation (can't close doors)
3. No block implementation (can't lock doors)
4. Braided knots never evolve after initial weaving
5. All friends have equal social signal weight (Dunbar says otherwise)
6. No friend-in-community awareness
7. No "invite friend to community" flow
8. No cross-context chat (community → DM and back)

**Why tiering matters:** Dunbar's number research shows meaningful relationships cap at 150-250. A user with 500 friends where all signals are weighted equally experiences signal dilution -- every signal is weak. Close friends (high interaction) should have 3x signal weight; acquaintances (low interaction) should have 0.5x. The system automatically tiers based on interaction frequency, and users can override.

**Why the friend cap (500):** Beyond social signal dilution, braided knot re-weaving runs during every evolution cascade cycle (every 5 minutes). Each re-weave involves Rust FFI calls to `knot_math`. O(500) Rust FFI calls per cycle is the upper bound before performance degrades on Tier 2 devices.

**GDPR cascade:** Unfriending and blocking must cascade to: dissolve braided knot data, remove from social signal provider, exclude from AI2AI learning exchanges, purge "met through" attribution data. This is a legal obligation.

### Why Trending Analysis Implementation (10.4B)

**The problem:** `TrendingAnalysisService` is a pure stub returning hardcoded empty lists. This is a data visibility gap -- locality agents have the data to compute real trending, but nothing reads it. Users can't discover what's popular. Third parties can't get trending insights. The MPC planner can't use trending context for novelty injection.

**Why replace (not remove):** Unlike some stubs that serve no purpose, trending analysis serves a real user need (discovering what's popular nearby). The data exists in locality agents (aggregate visit patterns per geohash). The implementation gap is: nobody reads the locality data and formats it as trending.

### Why Creator & Business Analytics Dashboard (10.4C)

**The problem:** The energy function trains on business data, but businesses can't see how they're performing. Event hosts don't know their attendee satisfaction. Community creators don't know their retention rate or how many friendships formed through their community. This is the "creator-side intelligence" gap -- the AI learns from creators' entities but gives nothing back.

**Not the same as expert dashboard:** The expert system has a personal progression dashboard (`ExpertiseDashboardPage`). That's inward-facing (how am I growing?). This is outward-facing (how is my entity performing? what impact am I having?).

### Why Decision Audit Trail (10.4D)

**The problem:** When a user complains "why did the AI recommend this terrible restaurant?", there's no way to reconstruct what happened. `DecisionCoordinator._logDecision()` logs to ephemeral `developer.log()` which is lost on app restart. Without a persistent decision audit trail, debugging recommendations is guesswork.

**Why on-device, not cloud:** Decision records contain feature attributions and energy scores that reveal model behavior. Storing on-device respects privacy -- the user owns their decision history. Admin access (10.4D.3) goes through encrypted cloud relay with user consent.

### Why GDPR Data Export Specification (10.4E)

**The problem:** Phase 2.1.2 says "Data export in machine-readable format" but provides no spec. What fields? What format? What about shared data (braided knots contain data from two users)? Without a specification, implementation is guesswork and may violate GDPR requirements.

**Key decisions:**
- JSON primary, CSV for tabular data
- Episodic memory exported as action counts per type (not individual tuples -- too large and too revealing of behavioral patterns)
- Braided knots: export user's own knot + braided invariants (derived), NOT the friend's raw knot
- Community fabric: export user's individual contribution vector, NOT aggregate
- Federated learning gradients: excluded (already DP-noised, meaningless individually)

### Why Test Suite Path Normalization & Grouped Contracts (10.9)

**The problem:** Grouped suite scripts are intended to be fast architecture confidence checks by domain, but after integration test reorganization into domain folders, many suite paths became stale. This creates false confidence: a suite appears to represent a domain but silently misses key integration tests.

**Why this is architectural, not just test housekeeping:**
- Architecture contracts are validated through grouped suites during fast feedback loops. If suites are stale, architecture guardrails are effectively blind in those areas.
- Owner boundaries (`QAE`, `APP`, `AIC`, `SEC`) need explicit suite ownership contracts to avoid test drift when directories are reorganized.
- Design consistency is part of architecture quality. Guardrails alone are insufficient; grouped strategy must include design goldens so visual/system tokens remain validated in the same execution model.

**Why Phase 10:** This is the codebase hardening and cleanup phase. Path normalization, grouped suite contracts, and stale testing doc cleanup belong here before Tier 3 scaling confidence gates.

### Why File/Folder Canonicalization & Rename Contracts (10.10)

**The problem:** The codebase has historical naming drift across working code, tests, and grouped suites. Ad hoc renames increase breakage risk, disconnect tests from implementation paths, and make ownership ambiguous.

**Why this requires architecture contracts:**
- Renames change architecture readability and ownership boundaries, not just file paths.
- Test artifacts and grouped suite references must move in lockstep with source paths to preserve confidence gates.
- Without a manifest and wave model, rollback is undefined and tracker/backlog drift becomes likely.

**Why Phase 10:** Phase 10 is the cleanup/hardening phase. Canonicalization planning belongs here so later phases execute against stable path and naming contracts instead of legacy drift.

### Why Phase Execution Orchestration Contracts (10.11)

**The problem:** Manual phase starts are easy to mis-sequence. Teams can begin a phase without all required architecture/checklist/tracker/design references being current, causing hidden dependency and governance drift.

**Why this requires explicit orchestration contracts:**
- Phase ordering and dependencies must be machine-readable to support repeatable trigger automation.
- Missing documentation references should fail early, not after implementation has begun.
- UI/UX work spans multiple app types; orchestration must enforce design source-of-truth linkage to keep surfaces consistent.
- Design governance needs a single required entrypoint (`docs/design/DESIGN_REF.md`) so app-scoped docs and system architecture docs stay synchronized.

**Why Phase 10:** This is the hardening/control phase. It is the right place to establish an automation-safe execution contract before scaling phase-trigger workflows.

---

## Common Pitfalls

1. **Reorganizing files that are about to be heavily modified**: Don't move a service file if the next phase will rewrite its internals. Move AFTER the rewrite.
2. **Removing ObjectBox before migrating FactsLocalStore**: The semantic memory pipeline (Phase 1.1A) depends on facts storage. Migrate to Drift first, THEN remove ObjectBox.
3. **Skipping user testing to rush to Phase 11**: If the world model underperforms formulas, industry integrations built on top of it will also underperform. Fix the foundation first.

---

**Last Updated:** February 13, 2026 (v12.4: Updated Phase 10.11 rationale to include DESIGN_REF as required design-governance entrypoint)
