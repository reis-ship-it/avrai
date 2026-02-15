# Phase 1 Rationale: Outcome Data & Episodic Memory Infrastructure

**Phase:** 1 | **Tier:** 0 (Blocks everything) | **Duration:** 4-5 weeks  
**Companion to:** `docs/MASTER_PLAN.md` Phase 1  
**Read before starting:** `FOUNDATIONAL_DECISIONS.md` (Decisions #1, #5, #7)

---

## Why This Phase Exists

The ML Roadmap (Section 7.4.1) identified the #1 blocker: **you cannot train any learned function without outcome data.** The existing system has 30+ scoring formulas but no mechanism to know if their recommendations were good. It's like a chef who cooks but never tastes the food.

This phase builds the taste buds. Everything downstream -- energy functions (Phase 4), transition predictors (Phase 5), MPC planning (Phase 6) -- requires training data that starts accumulating here.

---

## Why Tier 0 (Blocks Everything)

Every other phase needs what Phase 1 produces:
- **Phase 3** (state encoders) needs feature freshness data and episodic context
- **Phase 4** (energy function) needs `(state, action, outcome)` tuples for training. Without Phase 1, the energy function has nothing to learn from
- **Phase 5** (transition predictor) needs `(state, action, next_state)` tuples from episodic memory
- **Phase 6** (MPC planner) needs outcome history to evaluate planning quality
- **Phase 8** (federated learning) needs locally-trained gradients, which need local training data

The math is simple: no outcome data = no learning = no intelligence-first architecture. That's why this blocks everything.

---

## Key Design Decisions

### Why Episodic Memory Uses `(state, action, next_state, outcome)` Tuples
This isn't arbitrary -- it's the minimum unit of learning for LeCun's world model:
- **state**: what the world looked like before the action (input to energy function)
- **action**: what the user did (the choice we want to learn about)
- **next_state**: what the world looked like after (ground truth for transition predictor)
- **outcome**: was it good? (training signal for energy function)

Without all four components, you can't train both the energy function AND the transition predictor from the same data.

### Why 26 Outcome Collection Points (1.2.1 through 1.2.26)
The legacy system had ONE learning input: `ContinuousLearningSystem.processUserInteraction()` which only recorded personality dimension bumps. The expanded 26-point pipeline captures:
- **Attendance outcomes** (1.2.2-1.2.3): did they show up? did they like it?
- **List interaction outcomes** (1.2.7-1.2.10): curation as a training signal
- **Business outcomes** (1.2.21-1.2.26): partnership, sponsorship, and patron engagement
- **Contrastive signals** (1.2.16-1.2.17): what users PREFER over what the model recommends (the most valuable signal)
- **Browse behavior** (1.2.19): "looked but didn't act" defines the interest/commitment boundary

Each point exists because it captures a unique behavioral signal the energy function needs.

### Why Three Memory Types (Episodic + Semantic + Procedural)
This mirrors human memory:
- **Episodic** (1.1): raw experiences -- "I went to the jazz bar Tuesday, felt energized"
- **Semantic** (1.1A): compressed knowledge -- "I generally enjoy high-curation spots on weekends"
- **Procedural** (1.1B): strategy rules -- "When novelty saturation > 0.8, novel exploration outperforms familiar comfort by 23%"

Why not just episodic? Storage and compute. Keeping every raw episode forever means the database grows without bound and queries slow down. Nightly consolidation (1.1C) compresses episodes into knowledge and rules, then prunes the raw episodes.

**External validation (Zeng et al., arXiv:2602.01630, Feb 2026):** The Zeng paper identifies Memory as one of five essential components of any world model framework, calling for "structured and dynamic management of information" that can "categorize, associate, and fuse experiential data from different modalities" and "actively filter and retain states and events core to the task." Their explicit requirements -- key information extraction, compression, and continuous merge/update/purge -- map directly to AVRAI's three-tier memory with nightly consolidation. The paper further argues that "simple sequential storage" is insufficient and that the memory system must construct "a unified and queryable internal knowledge system." AVRAI's approach (episodic → semantic compression → procedural rule extraction → nightly pruning) is exactly this architecture. The fact that a major 2026 survey identifies these same memory requirements as essential for any serious world model validates that AVRAI's memory design is not over-engineered -- it's the minimum viable architecture for a world model that actually learns.

### Why Nightly Consolidation (1.1C)
Training and compression run overnight because:
- Device is charging (no battery impact)
- WiFi is available (can sync gradients)
- User is idle (no inference latency competition)
- `BatteryAdaptiveBleScheduler` patterns already exist for this

The consolidation cycle: compress episodes → extract rules → prune old episodes → train world model → sync gradients. All in one overnight window.

### Why the Cold-Start Strategy Has 4 Paths (1.5A through 1.5D)
Because users arrive in different states:
- **1.5A (onboarding complete)**: personality dimensions from `OnboardingDimensionComputer` + archetype. Confidence 0.3, converges in ~20 interactions
- **1.5B (onboarding skipped)**: zero explicit data. First-session behavioral bootstrapping gives a "behavioral archetype." Converges in ~50 interactions
- **1.5C (business)**: new businesses have no patron data. Bootstrap from public data + locality priors + category peer transfer
- **1.5D (pre-seeded model)**: the model ships pre-trained on Big Five OCEAN data so Day 1 users get population-level intelligence, not random

The chat-as-accelerator principle (Foundational Decision #7) demands that 1.5A and 1.5B converge to the SAME accuracy limit. The gap should be 50 interactions vs. 20, not infinite vs. 20.

### Why Organic Spot Discovery (1.7)
The existing spot system only knows about places in external databases (Google Places, Apple Maps, OSM) or explicitly created by users. But many of the most meaningful locations -- a hidden park, a garage music venue, a rooftop with a view, a parking lot that turns into a farmers market on Saturdays -- don't exist in any database. Users visit these places, but the system can't see them.

Organic Spot Discovery fills this gap by watching for *unmatched visits* -- when `LocationPatternAnalyzer.recordVisit()` can't find a `placeId` match. These "invisible" visits get clustered by geohash (~153m precision), and when a cluster reaches threshold (3+ visits by the user or 2+ unique mesh users), it surfaces as a discovery candidate.

**Why in Phase 1 (not Phase 3 or later):** This is data infrastructure, not intelligence. It produces:
- New learning signals for `ContinuousLearningSystem` (3 event types)
- Personality evolution data for `PersonalityLearning` (explorer/curator traits)
- Context for `ContextEngine` (discovered spots in recommendation context)
- Future episodic tuples (Phase 1.7.12) for energy function training

The earlier these signals start accumulating, the richer the training data for downstream phases.

**Why geohash precision 7:** ~153m radius. Tight enough to distinguish a park from the restaurant across the street. Loose enough that GPS drift doesn't create false clusters.

**Why mesh sharing:** If 3 different users' AIs independently detect the same geohash cluster, that's strong community validation. The mesh signal only contains geohash + visit count -- never raw GPS, user identity, or visit timing. This aligns with Foundational Decision #8 (AI2AI only, never P2P) and #4 (on-device/privacy).

**Why the "doors" framing:** The system never forces spot creation. It surfaces the insight ("you keep coming back here") and lets the user decide. This is "being a good key" per Foundational Decision #12.

**Locality agent ↔ organic discovery (1.7.15-1.7.16):** The locality agent can surface organic discovery candidates as "nearby places you've found" when the user is in the area. Conversely, organic discovery clusters feed into the community pipeline -- when mesh users validate a geohash cluster, that becomes a community-curated recommendation candidate. This closes the loop: organic discovery → locality agent → community pipeline → better recommendations.

### Why Signal Strength Hierarchy (1.4.9)
Not all user signals are equally informative:
- An explicit 5-star rating (10x weight) is unambiguous
- A scroll-past-without-tap (0.5x weight) is highly ambiguous

The hierarchy ensures the energy function weights its training data appropriately. These weights are initial values that the model should learn to adjust over time.

### Why Negative Outcome Amplification (1.4.10-1.4.12)
**Loss aversion asymmetry:** Bad experiences are more damaging than good ones are rewarding -- a well-established finding from behavioral economics. The energy function must learn this asymmetry. Negative outcomes therefore receive **2x weight** in training so the model learns to avoid recommendations that lead to disengagement, disappointment, or regret. Without this, the model would underweight avoidance signals and over-recommend risky choices.

**Model failure tuples (3x weight):** When the prediction was wrong -- the user chose something else, ghosted, or explicitly rejected -- that tuple is the model's blind spot. These "model failure" cases are the highest-value training data because they reveal where the energy function miscalibrates. They get **3x weight** so the model prioritizes correcting its mistakes over reinforcing already-correct predictions.

**"Bad day" detection:** Mood-driven feedback can masquerade as genuine taste shifts. A user who had a stressful day might down-rate everything they tried; that's not a signal about spots, it's about context. Bad-day detection (1.4.12) distinguishes transitory mood from genuine preference changes, preventing the model from overfitting to noise. This feeds into Phase 4.1.7 (asymmetric loss training) and Phase 4.1.8 (self-monitoring) -- the energy function needs to know when its training signal is contaminated.

---

## Pre-Flight Checklist for Phases That Depend on Phase 1

**Before starting Phase 3 (State Encoders):**
- [ ] `EpisodicMemoryStore` is deployed and accepting writes
- [ ] `UnifiedOutcomeCollector` is wired to at least 5 action types
- [ ] `FeatureFreshnessTracker` concept is designed (Phase 3 implements it, but Phase 1 defines the timestamps)
- [ ] `AtomicClockService` timestamps are used for all episodic tuples

**Before starting Phase 3 (State Encoders) -- Organic Discovery readiness:**
- [ ] `OrganicSpotDiscoveryService` is deployed and accepting unmatched visits
- [ ] At least a few discovery candidates exist in test environment (validates the pipeline)
- [ ] Mesh signal format (`organic_spot_discovery`) is stable

**Before starting Phase 4 (Energy Function):**
- [ ] At least 500 episodic tuples exist in test environment
- [ ] Outcome taxonomy (1.2.12) is defined: binary, quality, behavioral, temporal
- [ ] `CallingScoreDataCollector` → `BaselineMetricsService` generalization (1.3.1) is complete
- [ ] `FormulaABTestingService` (1.3.2) is ready for parallel-run mode
- [ ] Feature flag support for formula replacement is in place (1.3.4)

**Before starting Phase 1.1D (Conviction Memory):**
- [ ] Phase 1.1C consolidation must be functional (knowledge extraction runs during consolidation)
- [ ] Phase 4.1 energy function must be queryable (wisdom layer uses energy function for applicability scoring)

**Before starting Phase 5 (Transition Predictor):**
- [ ] Episodic tuples contain `next_state` snapshots (not just outcomes)
- [ ] Consolidation scheduler (1.1C) runs successfully, providing a training window
- [ ] 1.1C.6 (world model training wire) connects consolidation to the training loop

**Before starting Phase 8 (Federated Learning):**
- [ ] 1.1C.7 (federated gradient sync) wires gradient sharing into the consolidation window
- [ ] Privacy budget tracking (Phase 2.2.3) is in place for gradient anonymization

---

## Common Pitfalls

1. **Building outcome collection without the taxonomy first**: Define 1.2.12 (outcome taxonomy) before wiring individual collectors. Otherwise you get inconsistent outcome formats.
2. **Forgetting contrastive signals (1.2.16)**: These are the MOST valuable training data because they show what users prefer over model recommendations. Don't skip them.
3. **Building semantic memory on ObjectBox**: The existing `FactsLocalStore` uses ObjectBox. Migrate to Drift FIRST (Foundational Decision #5), then build semantic memory on top.
4. **Ignoring the business cold-start (1.5C)**: Business outcomes are a separate pipeline from user outcomes. New businesses need bootstrap signals just like new users.
5. **Treating organic discovery as a spot creation feature**: It's a *data pipeline*, not a UI feature. The core value is the learning signals it produces (episodic tuples, personality evolution, mesh validation). The UI prompt (1.7.13) is just the surface -- the intelligence is in the clustering and confidence calculation.
6. **Sharing raw GPS over mesh for organic discovery**: Only geohash + visit count. Never coordinates, user identity, or timing. The geohash precision is carefully chosen to balance clustering accuracy and privacy.

---

## Additional Design Rationale

### Why Friendship Lifecycle Outcome Collection (1.2.27-1.2.29)

**The problem:** The outcome data pipeline captures 26 types of episodic tuples (visits, events, chats, partnerships), but friendship outcomes are completely missing. When two users become friends through a community, that's never recorded. When friends co-attend an event, that's never linked. When a friendship ends (unfriend), there's no negative signal. The world model is blind to the most important "doors" -- the people.

**Why "met through" attribution (1.2.28) is uniquely valuable:** This captures the causal chain: community → friendship. It's proof that a community opened a door to a meaningful connection. This is exactly what the doors philosophy measures -- and exactly what the community-perspective energy function (Phase 4.4) needs to score community value.

**Why friend-driven activity (1.2.29) matters:** When user A visits a spot because friend B visited it, that's social influence on real-world behavior. It's different from organic discovery (the user found it themselves) and different from AI recommendation (the system suggested it). It's the friend acting as a "door" to a new experience.

### Why Conviction Memory (1.1D)

**Problem:** The system collects data and learns patterns, but has no structured way to distinguish between a pattern observed once and a truth validated thousands of times. It has no contextual judgment layer for applying knowledge appropriately. It has no mechanism for the full emotional spectrum.

**Solution:** Phase 1.1D implements the Knowledge-Wisdom-Conviction hierarchy. Knowledge entries are structured claims. The wisdom layer applies knowledge contextually. Convictions are earned truths with full audit trails. Emotional context vectors capture the full human experience. Fractal bidirectional flow connects all scopes.

**Alternatives considered:**
- **Model weights only (no explainability):** Would capture patterns but give no interpretable structure for "why" or "how sure" the system is. Users and auditors cannot inspect or debug.
- **Rule-based:** Does not scale. Cannot adapt to new domains or learn from outcomes.
- **Knowledge-only without conviction tier:** Treats all patterns equally — a single observation would carry the same weight as a truth validated thousands of times, leading to overconfidence in weak signals.

---

**Last Updated:** February 10, 2026 -- Version 1.4 (added Why Conviction Memory 1.1D, Phase 1.1D pre-flight checklist. Previous: 1.3 Zeng et al. 2026 external validation for memory architecture)
