# Foundational Decisions

**Created:** February 10, 2026  
**Purpose:** Explains the "why" behind every architecture-wide decision in the Master Plan. Read this before starting ANY phase.  
**Companion to:** `docs/MASTER_PLAN.md` (what to build), `docs/MASTER_PLAN_TRACKER.md` (where things live), `docs/plans/architecture/REALITY_COHERENCE_TEST_MATRIX.md` (what must be proven coherent)  
**Status:** Active -- update when foundational decisions change

---

## How to Use This Document

Before starting any phase of the Master Plan, read:
1. **This document** (foundational decisions that apply everywhere)
2. **The phase-specific rationale** (`docs/plans/rationale/PHASE_X_RATIONALE.md`)
3. **Cross-phase connections** (`docs/plans/rationale/CROSS_PHASE_CONNECTIONS.md`)

These three documents together answer: *Why is the plan designed this way? What breaks if I deviate?*

---

## Decision 1: Intelligence-First, Not Feature-First

### The Decision
Rebuild the decision-making architecture around a learned world model before adding new features.

### Why
The legacy plan (Phases 1-31) was feature-first: build everything, bolt on ML later. The ML System Deep Analysis (`docs/agents/reports/ML_SYSTEM_DEEP_ANALYSIS_AND_IMPROVEMENT_ROADMAP.md`) revealed what this produced:
- 30+ hardcoded scoring formulas with hand-tuned weights (40/30/20/10, 50/30/20, etc.)
- Zero outcome data -- the system had no way to know if its recommendations worked
- No episodic memory -- the system couldn't learn from its own predictions
- Each new feature added another formula that couldn't improve itself

Every new feature built on top of hardcoded formulas creates more technical debt that's harder to replace later. Intelligence-first means: build the learning infrastructure, THEN let every new feature benefit from it automatically.

### External Validation: Zeng et al. (2026) Anti-Fragmentation Thesis
The February 2026 paper "Research on World Models Is Not Merely Injecting World Knowledge into Specific Tasks" (Zeng et al., Peking University, arXiv:2602.01630) independently validates this decision from the academic world model research community. Their core thesis: **the dominant pattern in AI research -- bolting world knowledge onto individual tasks (video generation, autonomous driving, 3D estimation) -- produces fragmented systems that can't achieve holistic understanding.** They demonstrate through failure cases that task-specific knowledge injection produces models that lack long-term memory consistency, violate physical laws in edge cases, and can't generalize beyond their training distribution.

This is exactly what AVRAI's legacy plan produced at a product level: 30+ isolated formulas that each "knew" something about matching but couldn't share knowledge, learn from outcomes, or improve themselves. The Zeng paper's proposed solution -- a unified framework with integrated interaction, reasoning, memory, environment, and generation modules -- mirrors AVRAI's intelligence-first approach of building a single world model pipeline (perception → cost → actor → guardrails) that all features feed into and benefit from.

**Key takeaway from Zeng:** "Overemphasis on aligning the outputs of specific tasks with world rules may impede the development of world models." In AVRAI terms: perfecting individual scoring formulas one at a time impedes building a system that actually learns.

### What Breaks If Ignored
Building features first means every new scoring formula becomes another item in the Phase 4.2 replacement schedule. A feature built today with a hardcoded formula is a feature you'll rewrite in 3 months.

### Alternatives Considered
- **Feature-first with ML bolted on later** (the legacy approach) -- rejected because it produced the current 30+ formula problem. Additionally validated by Zeng et al. as the dominant failure mode in world model research broadly
- **Hybrid: build some features while building ML** -- this IS what we're doing with Phases 9 and 10 running in parallel, but only for features that don't involve scoring decisions

---

## Decision 2: Energy-Based Models, Not Probabilistic

### The Decision
Use energy functions (low energy = good match) instead of probability distributions for all scoring.

### Why
This follows LeCun's explicit recommendation. Probabilistic models estimate P(match | user, entity), which requires modeling the full probability distribution in 145-155 dimensional space. That's intractable for on-device compute. Energy functions learn E(user, entity) where low = good. They avoid the "curse of dimensionality" because they only need to rank outcomes, not estimate exact probabilities.

In plain English: we don't need to know "there's a 73% chance you'll like this spot." We need to know "you'll like Spot A more than Spot B." Energy functions are rank-ordering machines, and that's exactly what recommendation systems need.

### What Breaks If Ignored
Building a probabilistic classifier (softmax, logistic regression, etc.) would require either:
- Massive compute for high-dimensional probability estimation (won't fit on device)
- Dimensional reduction that throws away the rich 145-155D features we carefully extract

### Connection to LeCun Framework
The energy function IS the "Cost Module (Critic)" in LeCun's architecture. The transition predictor predicts next state, the energy function evaluates whether that state is good. This separation is fundamental -- the world model predicts, the critic evaluates.

### Why LeCun Over Zeng et al.'s Unified Framework
Zeng et al. (arXiv:2602.01630, Feb 2026) propose a competing unified world model framework with five components: Interaction, Reasoning, Memory, Environment, and Multimodal Generation. Notably, **their framework has no cost function or energy concept.** They have "Reasoning" (inferring causality and physical laws) but no mechanism for scoring how good a state-action pair is. AVRAI needs to rank-order thousands of potential recommendations efficiently -- "Spot A is better than Spot B for this person" -- and energy functions are purpose-built for that. Reasoning about whether a door is good is slow and ambiguous; computing an energy scalar is fast and differentiable. LeCun's energy-based approach was the right choice for a recommendation system that must score 50+ candidates in under 200ms on a mobile device.

---

## Decision 3: VICReg Training, Not Contrastive Loss

### The Decision
Train all embeddings using Variance-Invariance-Covariance Regularization (VICReg) instead of contrastive learning.

### Why
Contrastive methods (SimCLR, MoCo, etc.) require carefully constructed negative pairs and are sensitive to batch size. VICReg avoids this:
- **Variance**: ensures embedding dimensions are actually used (prevents dimensional collapse where the model ignores some dimensions)
- **Invariance**: ensures compatible pairs produce similar embeddings
- **Covariance**: ensures embedding dimensions carry different information (decorrelated)

This matters because our state vector has 145-155D of carefully extracted features. If the model collapses to using only 10 of those dimensions, we've wasted the knot invariants, fabric metrics, worldsheet trajectories, and all the other rich features.

### What Breaks If Ignored
Contrastive loss with small on-device batch sizes (we're training on one user's data, so batches are small) tends to produce collapsed embeddings. VICReg's explicit variance term prevents this regardless of batch size.

### Where This Applies
- Phase 4.1.3: Energy function training
- Phase 5.1.3: Transition predictor training
- Phase 11.3.4: JEPA embedding training

---

## Decision 4: On-Device Everything, Cloud as Fallback

### The Decision
All world model inference (state encoding, action encoding, energy scoring, transition prediction, MPC planning) runs on-device. Cloud is never required for core functionality.

### Why
Three reasons, in order of importance:
1. **Privacy**: User personality data, behavioral patterns, and episodic memory never leave the device. GDPR compliance is trivially satisfied when data doesn't travel.
2. **Latency**: On-device inference runs in single-digit milliseconds. Cloud round-trips add 100-500ms minimum. For real-time recommendation scoring, that's the difference between fluid and laggy.
3. **Offline**: Users in subways, rural areas, or airplanes still get personalized recommendations. The world model works with zero connectivity.

### What Breaks If Ignored
Cloud-dependent inference means:
- Every recommendation requires network, killing the offline experience
- Personality data flows to servers, creating privacy liability
- Latency makes the app feel slow compared to formula-based scoring

### The Cloud's Actual Role
- Federated gradient aggregation (Phase 8.1.3) -- anonymous, DP-protected
- Pre-trained model weight distribution (Phase 1.5D.3-4) -- shipping model updates
- SLM fallback for devices that can't run on-device LLM (Phase 6.7.5)
- Data backup via `BackupSyncCoordinator` (encrypted)

---

## Decision 5: Drift (SQLite) Over ObjectBox for New Storage

### The Decision
All new persistent storage (episodic memory, semantic memory, procedural memory) uses Drift/SQLite, not ObjectBox.

### Why
ObjectBox was used for the legacy `StructuredFactsIndex` (`FactsLocalStore`). But:
- Phase 10.2.6 proposes removing ObjectBox from the project
- Drift is already proven in the codebase for other storage patterns
- Building on ObjectBox means building something you'll rip out and rebuild on Drift later

### What Breaks If Ignored
Building episodic memory on ObjectBox (Phase 1.1) means:
1. Build it on ObjectBox
2. Phase 10.2.6 removes ObjectBox
3. Rebuild it on Drift
That's building the same thing twice.

### Migration Path
The existing `FactsLocalStore` (ObjectBox) must migrate to Drift FIRST (as part of Phase 1.1 work), THEN semantic memory (Phase 1.1A) builds on top of the Drift-based facts store.

---

## Decision 6: ONNX as the Universal Model Format

### The Decision
All ML models ship as ONNX format. State encoder, action encoder, energy function, transition predictor, System 1 distilled model -- all ONNX.

### Why
- ONNX runs on every platform (iOS CoreML bridge, Android NNAPI, raw CPU)
- Models are pure functions: input tensor in, output tensor out, no side effects
- Pure functions are trivially convertible to quantum circuits later (Phase 11.4)
- `InferenceOrchestrator` already handles ONNX model loading and inference
- Total model budget is ~1MB for all 4 world model ONNX models (fits any device)

### What Breaks If Ignored
Using TensorFlow Lite, PyTorch Mobile, or custom formats means:
- Platform-specific inference code (double the maintenance)
- Breaking the existing `InferenceOrchestrator` patterns
- Losing the quantum-readiness property (ONNX models are pure functions; framework-specific models carry runtime state)

---

## Decision 7: Chat-as-Accelerator, Never Gate

### The Decision
The world model must converge to accurate predictions from pure behavioral observation alone. Chatting with the AI agent speeds up convergence but is never required.

### Why
Most people don't want to chat with an AI assistant about their preferences. They want to open the app, see good recommendations, and go live their life. If the model REQUIRES chat to work well, it fails for 80%+ of users.

The design principle: a user who never chats must approach the SAME accuracy limit as a user who chats daily -- it just takes more observations (50 interactions vs. 20).

### What Breaks If Ignored
If features assume chat data is available:
- Skip-onboarding users (Phase 1.5B) get degraded recommendations permanently
- Users who disable the agent chat get worse recommendations
- The system optimizes for chatty users instead of all users

### How It's Enforced
- Phase 1.5B explicitly handles skip-onboarding users with zero chat data
- Implicit signals (Phase 1.4.8: return visits, dwell time, app opens) provide training data without any user action
- One-tap rejection (Phase 1.4.6) and category suppress (Phase 1.4.7) are the "chat-free" equivalents of telling the agent what you don't like
- Phase 5.1.9 (taste drift detector) handles life changes WITHOUT the user telling the agent
- **Phase 1.7 (Organic Spot Discovery)**: the system learns about meaningful locations purely from visit behavior -- no user action required. Repeated visits to unregistered locations are clustered and surfaced as discoveries. The user never needs to tell the agent "I like this park" -- the system learns it from behavior

---

## Decision 8: AI2AI Only, Never P2P

### The Decision
All device interactions happen through personality learning AIs. Users never interact directly at the protocol level.

### Why
AI2AI means:
- Privacy is structural: AIs share anonymized vibe signatures, never raw personality data
- Learning is bidirectional: both AIs learn from the interaction
- Consent is granular: AIs respect both users' privacy preferences
- Quality is guaranteed: AIs filter low-value connections before surfacing them

P2P would mean raw data exchange between devices with ad-hoc privacy bolted on.

### What Breaks If Ignored
P2P connections bypass the learning pipeline. A P2P connection:
- Doesn't produce episodic tuples for training
- Doesn't respect the anonymization boundary (`AgentIdService`)
- Doesn't benefit from energy function scoring
- Can't be replayed for world model improvement

---

## Decision 9: Preserve Existing Quantum/Knot/Fabric Systems

### The Decision
The quantum vibe states, personality knots, knot fabric, worldsheets, string evolution, decoherence tracking, and entanglement systems are NOT replaced by the world model. They become INPUT to it.

### Why
These systems produce the rich 145-155D feature vector that makes AVRAI's world model unique. No other recommendation system has:
- 24D complex quantum vibe amplitudes (Phase 3.1.1)
- Topological invariants from personality knots (Phase 3.1.2)
- Community health metrics from knot fabric (Phase 3.1.3)
- Personality evolution trajectories from worldsheets (Phase 3.1.5)

Throwing these away to build a simpler feature set would reduce AVRAI to a generic recommendation system with fewer features than YouTube or TikTok.

### What Breaks If Ignored
Replacing quantum features with simpler alternatives means:
- The state encoder has fewer dimensions to work with
- The energy function has less information to distinguish between candidates
- The transition predictor can't capture the rich dynamics that quantum states evolve through
- The system loses its technological moat

### External Validation: Zeng et al. on Unified Perception
Zeng et al.'s Interaction module calls for "generalized perception" that fuses multimodal inputs into a unified world state representation. AVRAI's 145-155D state vector -- drawing from 19+ services spanning quantum vibe, knot topology, fabric metrics, temporal patterns, location, and behavioral history -- is exactly this kind of unified perception. The key difference: Zeng envisions fusing physical-world modalities (text, images, video, audio, 3D point clouds), while AVRAI fuses *personality-world modalities* (quantum states, topological invariants, community health, behavioral trajectories). The principle is the same: rich, multi-source perception fed into a unified representation that downstream modules can reason over.

### What DOES Change
How these features are USED changes. Instead of hardcoded formulas like `0.5 * quantum + 0.3 * topological + 0.2 * weave`, the energy function LEARNS the optimal combination from outcome data.

---

## Decision 10: Tier-Based Device Degradation

### The Decision
Every user gets an AI agent. The agent's capabilities scale with device hardware across 4 tiers (full, standard, basic, minimal).

### Why
If the world model only runs on flagship phones, most users get the formula-based experience indefinitely. That defeats the purpose of intelligence-first.

The tier system means:
- **Tier 3 (iPhone 15 Pro+)**: Full world model + SLM + federated learning + on-device training
- **Tier 2 (iPhone 13+)**: Full world model + all memory. No SLM, no on-device training
- **Tier 1 (iPhone 11+)**: Existing ONNX models + episodic memory. No full world model
- **Tier 0 (older)**: Formula-only. Rule-based personality evolution

### What Breaks If Ignored
No device tiers means either:
- Crash/OOM on lower-end devices (bad UX)
- Limiting the world model to what the worst device can run (wastes flagship hardware)

### Connection to Existing Code
`OnDeviceAiCapabilityGate` already has device capability checks. Phase 7.5 extends this with `AgentCapabilityTier` that subsumes the existing `OfflineLlmTier` enum.

---

## Decision 11: Formula Replacement via Feature Flags

### The Decision
Every hardcoded formula replacement follows a 5-step protocol: parallel run → comparison data → A/B test → feature flag flip → formula removal.

### Why
Flipping from formula to energy function all at once risks degrading recommendations for users who are happy with the current experience. The parallel-run approach means:
1. Both formula and energy function compute scores simultaneously
2. Comparison data reveals where the energy function is better or worse
3. When the energy function matches or beats the formula on held-out outcomes, flip the flag
4. Keep formula as fallback for M weeks
5. Remove formula code only after confidence

### What Breaks If Ignored
- Hard-swapping to energy function without comparison data risks degraded recommendations
- No rollback path if the energy function underperforms for specific user segments
- Per-user rollback (Phase 4.5.4) requires feature flags per formula

---

## Decision 12: Doors Philosophy as Design Authority

### The Decision
Every feature must answer four questions:
1. What doors does this help users open?
2. When are users ready for these doors?
3. Is this being a good key?
4. Is the AI learning with the user?

### Why
Without this filter, features drift toward engagement optimization. "More time in app" is not the same as "better life." The doors philosophy keeps the product honest:
- A feature that increases session time but doesn't lead to real-world action is NOT a good feature
- A feature that opens one person's door by closing another's violates the bidirectional energy principle (Phase 4.4.14)
- Gamification that replaces authentic engagement is explicitly forbidden

### What Breaks If Ignored
The energy function optimizes for whatever outcome signal you train it on. If outcome signals measure engagement instead of meaningful connections, the AI becomes an engagement-maximizing machine. The doors philosophy ensures outcome signals are anchored in real-world impact.

### Where This Is Enforced
- Phase 4.6.4: Feature attributions mapped to "doors" language (never "quantum state inner product was 0.87")
- Phase 6.2.4: "Doors" constraint in MPC guardrails
- Phase 4.4.14: Bidirectional energy protects communities and businesses ("don't open one person's door by closing another's")
- **Phase 1.7 (Organic Spot Discovery)**: discovered locations are "doors that haven't been named yet." The system surfaces the insight ("you keep coming back here") but never forces creation -- the user opens the door by choosing to save the place. This is "being a good key" in its purest form

---

## Decision 13: Lists as First-Class Quantum Entities

### The Decision
Lists (`SpotList`) get full quantum state, personality knot, knot fabric, worldsheet, string evolution, decoherence, and entanglement representations -- the same as users, spots, events, and communities.

### Why
A curated list is a *compressed preference manifold*. When a user creates "Best Late Night Jazz Spots," they're encoding:
- Taste preferences (jazz, nightlife, high curation)
- Geographic patterns (clustered or spread)
- Vibe preferences (what the list's composite quantum state reveals)
- Community knowledge (shared lists are collective intelligence)

Without quantum representation, lists are just bags of IDs. With it, the world model can:
- Match users to compatible lists (not just popular ones)
- Predict how a list evolves over time (worldsheet)
- Detect list coherence/decoherence (is the list focused or scattered?)
- Use list creation as a first-class training signal

### What Breaks If Ignored
- List recommendations fall back to popularity-based ranking
- List creation doesn't produce useful training signals
- List-to-list compatibility (for itinerary building) has no mathematical foundation
- A major differentiator disappears

---

## Decision 14: Businesses and Partnerships as Bilateral Energy

### The Decision
Business partnerships, sponsorships, and business-expert matching all use bidirectional energy: both sides must benefit. The energy function evaluates the interaction from BOTH perspectives.

### Why
Unlike user-to-spot matching (one-sided: does the user like the spot?), business relationships are fundamentally bilateral. A partnership where the business benefits but the expert doesn't will fail. A sponsorship where the brand benefits but the event quality degrades hurts everyone.

The doors philosophy demands this: "don't open one person's door by closing another's."

### What Breaks If Ignored
- One-sided matching produces partnerships where one party is unhappy
- Sponsorships degrade event quality (brand force-fits that don't match event vibe)
- Business-to-business partnerships with unequal value extraction
- The MPC planner can't plan multi-step partnership sequences if it doesn't model both sides

---

## Decision 15: Post-Quantum Cryptography Now, Not Later

### The Decision
Signal Protocol with PQXDH (hybrid X3DH + ML-KEM/Kyber) is mandatory for all new sessions. Additional post-quantum hardening covers BLE, federated gradients, and cloud transport.

### Why
"Harvest now, decrypt later" attacks mean adversaries record encrypted traffic TODAY and decrypt it YEARS from now when quantum computers arrive. Signal Protocol sessions, BLE advertisements, and cloud API calls recorded today are all vulnerable if they used ECDH-only key exchange.

This has a deadline driven by attackers, not by our feature roadmap. Every day of delay is another day of vulnerable traffic recorded.

### What Breaks If Ignored
All historical encrypted communications become retroactively readable once quantum computers can break ECDH. This includes:
- User chat messages
- AI2AI personality exchanges
- Federated gradient sharing
- Cloud-synced episodic memory

---

## Decision 16: Locality Happiness as Ecosystem Self-Healing

### The Decision
Locality agents aggregate individual agent happiness into a per-geohash score. When happiness drops below 60%, the locality seeks advisory from thriving localities through the federated global system.

### Why
Individual agents learning in isolation can get stuck. A new neighborhood, a seasonal shift, or a bad model update can leave agents in an area struggling to open doors. Without a feedback loop, struggling areas stay stuck indefinitely.

The locality happiness advisory creates a self-healing ecosystem:
- Happiness flows UP (individual agents → locality aggregate)
- When a locality struggles (< 60%), it asks thriving localities "what works for you?"
- Advisory flows DOWN (thriving locality strategies → struggling locality adjustments)
- The struggling locality improves, and eventually becomes an advisor itself

This mirrors how real communities work: neighborhoods learn from each other. Brooklyn coffee culture influenced Portland which influenced Melbourne. AVRAI's locality agents do the same thing, at machine speed, with privacy guarantees.

### Agent Happiness Model
The agent's happiness comes from two sources:
1. **Learning satisfaction** — deeply understanding the user (personality convergence, prediction accuracy improving)
2. **Fulfillment satisfaction** — successfully guiding the user to real-world activities they enjoy (positive outcomes from suggestions)

Both must be high for the agent to be happy. An agent that understands the user but can't find good suggestions is unsatisfied. An agent that gets lucky suggestions but doesn't understand why they work is fragile. Locality happiness aggregates both signals, so advisory transfer addresses both knowledge gaps (what patterns work here?) and strategy gaps (how should suggestions be delivered?).

### What Breaks If Ignored
- Struggling areas never improve without manual intervention
- No feedback signal for whether the recommendation system is working at an ecosystem level
- Admin has no geographic visibility into system health
- Third-party insights lack the most valuable signal: where are things working and where aren't they?
- The "same pattern, different place" global transfer never happens

### Connection to Existing Systems
- `AgentHappinessService` already records per-agent happiness signals (0.0-1.0)
- `LocalityAgentGlobalStateV1` already has a 12D vector per geohash in Supabase
- `LocalityAgentUpdateEmitterV1` already emits privacy-bounded updates to Supabase
- `LocalityAgentEngineV1` already blends global priors + neighbors + mesh + personal deltas
- The advisory query is an extension of the existing global repository pattern
- All functions involved are pure (no side effects), making them quantum-ready per Decision 6

---

## Quick Reference: Key Decisions by Phase Relevance

| Phase | Most Relevant Decisions |
|------:|------------------------|
| 1 | #1 (intelligence-first), #5 (Drift over ObjectBox), #7 (chat-as-accelerator), #8 (AI2AI only -- organic discovery mesh), #12 (doors -- discovered locations), #23 (friend system lifecycle) |
| 2 | #4 (on-device/privacy), #15 (post-quantum), #24 (data visibility -- AI visibility), #25 (BLE payload budget -- post-quantum overhead) |
| 3 | #2 (energy-based), #6 (ONNX), #9 (preserve quantum systems), #13 (lists as entities), #22 (self-optimization -- feature weights), #24 (data visibility -- weather/app usage/friend features) |
| 4 | #2 (energy-based), #3 (VICReg), #11 (feature flag replacement), #14 (bilateral energy), #22 (self-optimization -- energy function tuning), #23 (friend system -- community energy), #33 (social QoL layer), #35 (ad-hoc groups -- joint energy) |
| 5 | #3 (VICReg), #4 (on-device), #7 (chat-as-accelerator), #31 (passive life pattern engine) |
| 6 | #7 (chat-as-accelerator), #12 (doors philosophy), #4 (on-device/offline), #22 (self-optimization -- guardrail thresholds), #25 (BLE payload budget -- mesh chat), #32 (active life pattern engine -- SLM intent), #34 (notification philosophy) |
| 7 | #10 (device tiers), #9 (preserve quantum systems), #17 (model lifecycle/OTA), #18 (multi-device), #22 (self-optimization -- bounded autonomy), #23 (friend system -- braided knot evolution), #31 (passive life pattern engine), #33 (social QoL layer), #34 (notification philosophy) |
| 8 | #4 (on-device/privacy), #8 (AI2AI only), #16 (locality happiness advisory), #22 (self-optimization -- locality advisory thresholds), #25 (BLE payload budget -- locality agent), #33 (social QoL layer), #35 (ad-hoc group formation) |
| 9 | #14 (bilateral energy), #12 (doors philosophy), #19 (third-party data pipeline), #32 (active life pattern engine) |
| 10 | #5 (Drift over ObjectBox), #9 (preserve quantum systems), #20 (accessibility as doors), #21 (internationalization), #23 (friend system -- GDPR cascading deletion), #24 (data visibility -- creator dashboard/trending/GDPR export), #33 (social QoL layer) |
| 11 | #6 (ONNX/quantum-ready), #3 (VICReg for JEPA) |

---

### Decision 17: Model Lifecycle Management (OTA, Versioning, Rollback)

**Why:** ONNX models improve via federated aggregation (Phase 8.1.3) and on-device training (Phase 5.2), but the Master Plan had no mechanism for delivering updated models to devices, versioning them, or rolling back bad models. Without this, model updates require App Store releases (slow, requires user action) or arrive unversioned (dangerous).

**What it covers:**
- Model version schema (`ModelManifest`) with semver, compatibility gates, integrity hashes
- OTA delivery via `BackupSyncCoordinator` (WiFi preferred, background, non-blocking)
- Staged rollout with canary (5% → 25% → 100% over 7 days, monitored by agent happiness)
- Per-user rollback (Phase 4.5.4 extended) and global rollback (via `ModelSafetySupervisor`)
- Storage budget: keep 2 model versions on device (current + previous for rollback)

**What breaks if ignored:** Models only improve via App Store updates (multi-week delay), no rollback capability for bad models (regressions hit all users simultaneously), no compatibility checking between model versions and episodic memory schemas.

---

### Decision 18: Multi-Device State Reconciliation

**Why:** Users may have multiple devices. Without reconciliation, each device develops its own divergent personality model. The user's iPad "knows" them differently than their iPhone.

**What it covers:**
- Primary device drives personality model; secondary devices are observation collectors
- Episodic memory merge (secondary → primary, tagged with source device for deduplication)
- Personality state sync (primary → secondary, after nightly consolidation)
- Tier-aware sync (secondary devices get primary's System 1 model for better-than-formula recommendations)
- Device migration (old phone → new phone transfers all AI state, not just data)

**What breaks if ignored:** Users with multiple devices get inconsistent recommendations. New phone means cold-start all over again. Episodic data collected on tablet never reaches the training loop on phone.

---

### Decision 19: Third-Party Data Pipeline (DP-Protected Insights)

**Why:** Phase 9.2.6 existed as a one-line task ("Outside Data-Buyer Insights (DP export)") but had no implementation detail. The data pipeline from raw aggregate insights to commercially valuable, privacy-protected products requires careful design around consent, DP noise calibration, k-anonymity thresholds, access control, and buyer ethics review.

**What it covers:**
- Insight product catalog (5 product types: locality vibes, category demand, event attendance, seasonal patterns, organic discovery)
- Per-product DP noise injection (Laplace, calibrated epsilon per product type, total 5.0/quarter/user budget)
- Consent verification gate (excluded users are COMPLETELY excluded, not just anonymized)
- Buyer onboarding with ethics review (reject surveillance, re-identification, individual targeting use cases)
- Revenue attribution tracking to inform AVRAI's own product roadmap

**What breaks if ignored:** Third-party data remains vaporware. Revenue opportunity from data products is lost. Or worse: data is shared without proper DP guarantees, creating privacy risk.

---

### Decision 20: Accessibility as Doors

**Why:** "Every spot is a door" must apply literally -- the app must open doors for users with disabilities. Accessibility is not a polish task; it's a core product principle. Screen reader users must get the same intelligence benefits (personalized recommendations, knot visualization meaning, energy function explanations) as sighted users.

**What it covers:**
- Semantic labels for all interactive elements (VoiceOver/TalkBack)
- Screen reader navigation flow with logical reading order
- WCAG AA color contrast compliance
- Knot audio sonification as PRIMARY experience (not novelty) for visually impaired users
- Dynamic text size support (1x-2x scaling)
- Reduce motion mode

**What breaks if ignored:** Users with disabilities are excluded from AVRAI's intelligence features. Knot visualization -- a core differentiator -- is inaccessible. App may fail accessibility compliance reviews in regulated markets.

---

### Decision 21: Internationalization as Global Locality Intelligence

**Why:** Locality agents (Phase 8.2) learn from global users. If the UI only supports English, the system can't reach the user base needed for meaningful global locality intelligence. i18n is not cosmetic -- it's a prerequisite for the federated learning system to have diverse, representative training data.

**What it covers:**
- ARB string extraction (~800-1200 strings)
- Locale detection and switching (9 initial languages)
- RTL layout support (Arabic)
- AI explanation localization (template-based, not LLM-generated, for privacy/speed)
- Locality agent language context (language as a locality feature for cross-region knowledge transfer weighting)

**What breaks if ignored:** AVRAI is English-only. Locality agents in non-English regions get no data. Federated learning is geographically biased. Global expansion is blocked.

---

### Decision 22: Autonomous Self-Optimization with Bounded Autonomy (Phase 7.9)

**What:** The system continuously evaluates its own features, strategies, and parameters through canary experiments, adjusting those that improve happiness and reverting those that don't.

**Why:** "AIs must always be self-improving" requires not just better model weights but also validating which inputs matter. Manual parameter tuning doesn't scale; the system must optimize itself.

**Alternatives considered:**
- **(a) Manual tuning by engineers** -- doesn't scale, slow iteration
- **(b) Full autonomy without guardrails** -- unsafe, hard to debug
- **(c) Bounded autonomy with human notification** -- chosen. Safe experimentation within human-set bounds, full transparency

**Key constraint:** Privacy-protected parameters (encryption, consent defaults, DP epsilon, k-anonymity) are NEVER autonomously optimizable. Safety guardrails include global happiness floor circuit breaker, per-experiment circuit breaker, consecutive failure limit, and per-user exemption.

**Affects:** All phases (every parameter becomes a candidate for optimization), Phase 3.1 (feature weights), Phase 4.1 (energy function tuning), Phase 6.2 (guardrail thresholds), Phase 8.9 (locality advisory thresholds).

**LeCun mapping:** This is the Configurator module made autonomous.

---

### Decision 23: Friend System as First-Class World Model Entity (Phase 10.4A, 1.2.27-29)

**What:** Friendships get full lifecycle management (request → accept → evolve → unfriend/block), braided knot evolution, tiered weighting, and outcome tracking as episodic tuples.

**Why:** Friendships are "doors" that lead to other doors (communities, events, shared experiences). The AI must learn from the complete friendship lifecycle, not just the existence of a connection.

**Key constraint:** GDPR requires cascading data deletion on unfriend/block (braided knots dissolved, social signals purged, AI2AI exchanges excluded). Friend cap of 500 prevents O(N²) braided knot cost explosion.

**Affects:** Phase 1.2 (outcome data), Phase 3.1 (friend network features in state vector), Phase 4.4 (community energy considers friend membership), Phase 6.2 (social nudges for friend-joined-community), Phase 7.1 (evolution cascade re-weaves braided knots).

---

### Decision 24: Data Visibility as a First-Class Concern (Phases 3.1.20A-D, 10.4B-E, 2.1.8D)

**What:** All collected data must be surfaced to its relevant audience: users see AI learning progress, creators see performance analytics, admins see decision audit trails, third parties see DP-protected aggregates. Trending data gets real implementation (not stubs).

**Why:** Blind data is wasted data. Weather is collected but the world model can't use it. App usage is tracked but the state encoder doesn't see it. Creators can't see their impact. Users can't see their AI improving. Every invisible data stream is a missed feedback loop.

**Key constraint:** User-facing transparency must never expose raw episodic tuples or other users' data. Creator analytics use DP-protected aggregates. Admin access is audit-logged.

**Affects:** Phase 2.1 (AI visibility), Phase 3.1 (weather, app usage, friend network, cross-app features wired into state vector), Phase 10 (trending, creator dashboard, decision audit, GDPR export).

---

### Decision 25: BLE Advertisement Payload Budget (Phase 6.6.6-6.6.7)

**What:** A versioned payload schema allocates the ~31 bytes of BLE advertisement space across competing features (AI2AI personality, organic spot discovery, device discovery, mesh chat, locality agent) with prioritized multiplexing.

**Why:** Multiple features now compete for the same BLE advertisement space. Without a budget, features silently clobber each other's data.

**Affects:** Phase 1.7 (organic spot discovery over BLE), Phase 6.6 (mesh chat), Phase 8.9 (locality agent), Phase 2.5 (post-quantum adds overhead to BLE payloads).

---

### Decision 26: Guardrail Immutability (Meta-Guardrail)

**What:** Safety guardrail parameters (7.9E.0-7.9E.7) are NEVER registered as `OptimizableParameter`s and can ONLY be changed through code deploy by the AVRAI creator.

**Why:** If the self-optimization engine could modify its own safety limits, it could disable them -- creating catastrophic failure. The creator's unhappiness = system goes to 0. Guardrails are the constitution the engine cannot amend.

**Impact:** 7.9E.0 implements compile-time + runtime validation. `GuardrailConstants` sealed class with `static const` values.

**Affects:** Phase 7.9 (all subsections respect immutable guardrails).

---

### Decision 27: User-Driven Self-Healing

**What:** Users can submit explicit requests to steer optimization via `UserRequestIntakeService`, with immediate per-user parameter adjustment for tunable parameters.

**Why:** The AI learns from behavior (implicit) and from what users say (explicit). Explicit requests are the strongest signal -- users literally telling the system what they want. Ignoring explicit feedback while optimizing on implicit signals is backwards.

**Impact:** Phase 7.9F adds 5 tasks. User-initiated overrides take priority over system-initiated experiments for that parameter.

**Affects:** Phase 7.9F → 7.9C (parameter system), 6.7 (SLM classification), 1.2 (outcome tracking).

---

### Decision 28: Collective Democracy-by-Happiness

**What:** When 50+ users independently request the same change, the system auto-triggers a canary experiment. Changes validated by happiness improvement get rolled out system-wide.

**Why:** Collective user intelligence is a signal the system should act on. But popularity ≠ quality, so every collective request still passes through the happiness validation pipeline. Minority protection prevents tyranny of the majority.

**Impact:** Phase 7.9G adds 5 tasks. Semantic clustering, threshold-triggered experiments, minority protection guard.

**Affects:** Phase 7.9G → 7.9C (experiment orchestration), 7.9D (admin notification), 1.1A (semantic embeddings for clustering).

---

### Decision 29: Multi-Transport AI2AI

**What:** AI2AI communication uses the best available transport: BLE (always available, low bandwidth), WiFi local network (same subnet, high bandwidth), or WiFi Direct (peer-to-peer, highest bandwidth). VPN detection triggers graceful fallback to BLE-only.

**Why:** BLE's 31-byte payload budget is a hard constraint that forces lossy compression for learning insights. WiFi provides kilobytes-to-megabytes bandwidth, completely solving the payload problem for same-network devices. WiFi Direct enables event-mode deep sync. VPN blocks local discovery (privacy choice respected) but shouldn't break the system.

**Impact:** Phase 6.6.8-6.6.12 (5 tasks). Signal Protocol encryption is transport-agnostic. `AI2AITransportSelector` picks best channel.

**Affects:** Phase 6.6 → 8.5/8.6 (AI2AI insight exchange benefits from WiFi bandwidth), 7.8 (multi-device sync via WiFi Direct), 9.4G (service marketplace federated data).

---

### Decision 30: Services Marketplace as First-Class World Model Entity

**What:** Service providers are a new quantum entity type (`QuantumEntityType.serviceProvider`) with full 10D feature encoding, braided knots, bidirectional energy scoring, MPC action types, and outcome collection.

**Why:** Services are doors. A painter, dog walker, or stylist enhances a user's life -- same as a spot, event, or community. Treating services as second-class (no world model integration) would mean worse matching, no compatibility prediction, no timing intelligence. The world model should know about ALL the doors.

**Impact:** Phase 9.4 adds 27 tasks across 7 subsections. State vector +10D. 5 new MPC actions. 1 new bidirectional energy pairing.

**Affects:** Phase 9.4 → 3.1 (feature extraction), 4.1 (energy function), 6.1 (MPC planner), 8.9 (locality demand), 8.1 (federated quality signals), 1.2 (outcome collection), 10.4A (friend recommendations for services).

---

### Decision 31: Life Pattern Intelligence (Passive Engine)

**The Decision:** The system learns from the user's LIFE, not just app usage. Background location, widget checks, and absence patterns build a per-user routine model on-device.

**Why:** App-open learning captures maybe 10% of a user's life. The remaining 90% happens when the app isn't open. The passive engine closes this gap by learning from OS-level signals (significant location changes, widget refreshes) that run even when the app is closed.

**Why not alternative:** Cloud-based location tracking (Foursquare model) would be simpler but violates privacy principles. Passive on-device processing keeps all raw location data local.

**What breaks if ignored:** The world model sees only a thin slice of user behavior. Routine-aware suggestions (time-of-day, day-of-week, habitual patterns) remain impossible. Phase 7.10A routine model never materializes.

---

### Decision 32: Active Life Pattern Engine (SLM as Conversational Planner)

**The Decision:** The SLM becomes the user's conversational interface for sharing intent, plans, and context. It extracts structured intents and triggers world model services via a tool-calling framework.

**Why:** Explicit user statements are the highest-confidence signals the system can receive (8x weight). A conversational interface is natural and non-invasive -- the user volunteers information when they want to.

**Why not alternative:** Form-based preference entry (like Yelp filters) captures intent but feels transactional. A conversation captures nuance ("I want somewhere quiet but not too fancy for my mom's birthday") that structured forms can't.

**What breaks if ignored:** The system misses high-value explicit signals. Users who prefer to articulate intent have no natural outlet. Phase 6.7B intent extraction and tool-calling framework remain unimplemented.

---

### Decision 33: Social Quality-of-Life Layer

**The Decision:** The people around the user are a first-class feature in the world model. Per-friend happiness correlations, group composition intelligence, and social absence detection drive proactive social suggestions.

**Why:** Happiness research consistently shows that social connection is the strongest predictor of well-being. A system that only optimizes for places/activities misses the fundamental insight that WHO you're with matters more than WHERE you are.

**What breaks if ignored:** Recommendations ignore the social dimension. The system can't suggest "invite Sarah" or "you haven't seen Alex in 3 weeks." Social absence detection and group composition intelligence never materialize.

---

### Decision 34: Notification Philosophy (Passive Engine Boundaries)

**The Decision:** The passive engine is an observer, not an interrogator. It NEVER asks location questions, RARELY asks labeling questions (max 1/week), and exhausts all inference before prompting.

**Why:** Location-based notifications that reference specific locations feel like surveillance. The system must earn trust by being helpful without being intrusive. A 1/week hard cap on labeling questions (immutable guardrail) ensures the system can never become annoying.

**What breaks if ignored:** Users feel surveilled. Notification fatigue drives churn. The 1/week labeling cap is a meta-guardrail per Decision 26 -- it must be immutable.

---

### Decision 35: Ad-Hoc Group Formation (SLM-Triggered)

**The Decision:** Users can form ad-hoc groups through natural conversation ("the 5 of us are hungry"), triggering BLE discovery, confirmation pop-ups, and joint energy scoring -- all in under 5 seconds.

**Why:** Existing group negotiation (8.6) is agent-initiated based on entanglement. But real-world group decisions happen spontaneously. The SLM must be able to handle "right now" group needs with speed over optimality.

**What breaks if ignored:** Spontaneous group formation requires multi-step manual coordination. "Right now" group needs go unmet. Phase 8.6B ad-hoc group formation remains unimplemented.

---

### Decision 36: Multi-Dimensional Self-Calibrating Happiness

**The Decision:** Happiness is not a single number. It's a vector of learned dimensions (discovery, social, routine, professional, growth, trust) with self-calibrating per-user weights and self-adjusting dimension definitions.

**Why:** A single happiness score hides critical information. A user at 0.7 who's socially thriving but professionally miserable needs different help than a user at 0.7 who's professionally thriving but socially isolated. Per-user learned weights let the system understand what happiness MEANS for each individual. Self-adjusting dimensions let the system discover happiness factors we haven't thought of.

**What breaks if ignored:** The system can't diagnose WHY a user is unhappy. It can't optimize for professional fulfillment (critical for earners). Locality thresholds are static (60% everywhere), missing that different populations have different baselines.

---

### Decision 37: DSL Self-Modification Engine (Layer 1 Self-Coding)

**The Decision:** ~80% of what AVRAI would want to change about itself is expressible as declarative strategy compositions, not compiled code. The DSL engine enables safe on-device self-modification without app store updates.

**Why:** App store updates take days. Model weight updates take hours. DSL rule updates take seconds. Most optimization opportunities (weight overrides, guardrail additions, notification timing, strategy selection) don't need code changes -- they need configuration changes with safety validation.

**What breaks if ignored:** Self-optimization is limited to parameter tuning within rigid code structures. Most improvements require code changes via the admin platform (Phase 12), which is slower and requires human review. The system's self-improvement speed is capped at human review throughput.

---

### Decision 38: Tax & Legal Compliance via Locality/Universe Models

**The Decision:** Tax and legal compliance rules are stored IN the locality agents and universe model hierarchy, not in a separate compliance database. Rules flow DOWN through the hierarchy (national → state → city). Cross-jurisdiction reconciliation is automatic.

**Why:** Tax rules are fundamentally geographic. Tying them to the same geographic hierarchy that powers everything else (locality agents, universe models) means: (a) when a new jurisdiction joins the federation, it brings its tax rules with it, (b) the system automatically knows which rules apply based on WHERE a transaction occurs, (c) cross-jurisdiction earners get automatic reconciliation because the hierarchy already knows the relationship between jurisdictions.

**What breaks if ignored:** Tax compliance becomes a standalone system that duplicates geographic knowledge. Adding a new jurisdiction requires updating two systems (world model + tax). Cross-jurisdiction reconciliation requires manual geographic mapping. The universe model hierarchy's power is wasted.

---

### Decision 39: Hybrid Expertise System (Behavioral + Credentialed)

**The Decision:** Expertise comes from two sources -- behavioral evidence from life patterns AND verified credentials. Both contribute to a fused hybrid score. The system learns what makes experts successful and helps emerging experts find better patterns.

**Why:** Purely behavioral expertise misses the chemistry PhD who just moved to town. Purely credentialed expertise misses the self-taught baker with 500 dinner parties. The hybrid approach recognizes both paths, with behavioral and credentials reinforcing each other. Expert success pattern analysis creates a feedback loop: the more experts the system observes, the better it gets at guiding new experts.

**What breaks if ignored:** New residents with extensive credentials start at zero expertise. Self-taught practitioners never get recognized. The system can't guide emerging experts because it doesn't know what success looks like.

---

### Decision 40: AVRAI Admin Platform as Separate Desktop Application

**The Decision:** The admin platform is a standalone Flutter Desktop application with its own dedicated API layer. Third parties build on the same API through the Partner SDK. The admin app is NOT a web dashboard and NOT part of the mobile app.

**Why:** Desktop gives: (a) persistent monitoring (always on, not a mobile screen), (b) multi-pane views (system monitor + code studio + experiment dashboard simultaneously), (c) local LLM execution for code generation (keeps AVRAI IP off third-party APIs), (d) a clear security boundary (admin functions physically separate from user functions). The shared API layer means the same security, audit, and access control applies to admin and third-party access.

**What breaks if ignored:** Code generation is limited to cloud APIs (IP risk). Admin UX is cramped on mobile. Third parties need a separate API from admin (double maintenance). Security boundary between admin and user functions is blurred.

---

### Decision 41: Fractal Federation Architecture (Universe Model)

**The Decision:** The federation hierarchy is fractal: world → organization universe → category model → AVRAI universe. Each level has absolute data sovereignty. Only DP-protected gradients flow upward. Intelligence flows downward as model priors. The same pattern works for universities, corporations, and governments (city → state → national → international).

**Why:** Real-world organizations are hierarchical. A single-level federation (all instances equal) misses that UC Berkeley and UC Davis share insights that don't apply to Google. The fractal model captures natural organizational relationships while maintaining privacy: each level adds DP noise before passing upward, so the AVRAI universe can't reconstruct individual instance data. Governments have deeper hierarchies (4 levels) than corporations (2-3 levels), and the same architecture handles both.

**What breaks if ignored:** University system-wide insights are lost (each campus is isolated). Government hierarchy is impossible. Cross-instance learning is flat (can't distinguish UC-specific from university-universal patterns). New instances don't benefit from category-specific intelligence.

---

### Decision 42: Seamless World Model Adoption

**The Decision:** World models come to users automatically. When a new white-label instance covers a user's location or affiliation, the user's device discovers it, creates a new context layer with a new agent_id, and enriches recommendations -- all silently.

**Why:** Users should never know or care about the infrastructure behind their experience. If their city starts providing AVRAI services, they shouldn't have to download a new app, create a new account, or toggle a setting. They should just notice that recommendations got better. This is the ultimate expression of "technology serves life."

**What breaks if ignored:** Users must manually discover and opt into new instances. Coverage expansion requires marketing/onboarding for each new instance. Users in white-label areas who already have public AVRAI must manage two apps.

---

### Decision 43: Meta-Learning Engine (Learning How to Learn)

**The Decision:** The system records every learning event (consolidation, experiment, federation round, model update) in a structured Learning Cycle Ledger with causal parent references. Weekly meta-analysis identifies which learning methods work best. The system proposes changes to its own learning process -- all within bounded hyperparameters and with full admin visibility.

**Why:** A system that learns but never reflects on HOW it learns has a ceiling. Every consolidation uses the same frequency. Every experiment uses the same canary size. Every federation round uses the same parameters. Over time, what's optimal changes: new users need different learning strategies than established users. High-deviation users need different consolidation frequency than routine users. The meta-learning engine removes this ceiling by making the learning process itself optimizable.

**What breaks if ignored:** Learning hyperparameters are hardcoded forever. Experiments take the same duration regardless of how much data exists. Federation runs the same number of rounds even when diminishing returns set in after round 3. The system can't discover that "explicit ratings matter 3x more in the first 30 days" because it never compares signal effectiveness across learning cycles. New federation instances start with model intelligence but not meta-learning intelligence -- they repeat the same learning mistakes the first instances already solved.

---

### Decision #44: Value Intelligence System (Proving Value is as Important as Delivering Value)

**Decision:** Build a first-class Value Intelligence System (Phase 12.4) with a causal chain attribution engine, intelligent hindsight surveys, stakeholder-specific metrics, controlled pilot toolkit, automated report generation, and self-proving intelligence. Every in-app interaction is AVRAI-attributed. Surveys feel like the AI learning, not data extraction. Proof aggregates fractally up the federation hierarchy.

**Alternatives considered:**
- **Scattered dashboards**: Each stakeholder gets their own hand-built dashboard. Problem: no causal attribution, no common framework, no aggregate proof.
- **Post-hoc surveys only**: Ask users and institutions after the fact. Problem: survey fatigue, recall bias, no causal chain, no counterfactual.
- **Revenue-only metrics**: Prove value only through revenue. Problem: misses social value, community health, life quality improvements -- which are AVRAI's core proposition.

**Why:** Without provable value, no institution renews, no investor invests, no government funds, and no business pays. AVRAI's value proposition is that it opens doors -- but that claim must be empirically verifiable. The attribution engine walks backward through episodic memory to find every AVRAI touchpoint in a user's outcome chain. The hindsight survey engine learns when each user gives the best feedback and asks during reflective moments, not post-event. The pilot toolkit provides controlled experiments with statistical rigor. Self-proving intelligence uses the world model's own accuracy and learning velocity as proof. Fractal aggregation gives every level of the federation hierarchy appropriate value metrics.

**What breaks if ignored:** AVRAI delivers value but can't prove it. University contracts go to competitors with better dashboards. Investors see no defensibility metrics. Businesses can't compare AVRAI vs. Google Ads. Government pilots produce anecdotal evidence, not statistical proof. The system opens doors but nobody documents which doors it opened.

### Decision #45: Knowledge-Wisdom-Conviction Architecture (The System Develops Understanding)

**Decision:** Implement a hierarchical intelligence progression: Data → Knowledge → Wisdom → Conviction. Knowledge entries are structured claims extracted during consolidation. Wisdom is the contextual application layer that selects and weights knowledge for the current situation. Convictions are knowledge that has been tried, tested, and found true across enough contexts. Convictions flow fractally: bottom-up from lived experience, top-down as cold-start intelligence. Every entity in the system (user, community, locality, instance, world, universe) develops its own knowledge, wisdom, and convictions.

**Alternatives considered:**
- **Model weights only**: Let the neural network learn everything implicitly. Problem: no explainability, no way to share structured insights across federation, no human-auditable beliefs.
- **Rule-based system**: Encode expert rules manually. Problem: doesn't scale, can't learn, can't adapt to different populations.
- **Knowledge-only (no conviction tier)**: Track knowledge without the conviction promotion mechanism. Problem: the system would treat a pattern observed once the same as one observed 10,000 times.

**Why:** A system that learns WHAT but not WHY or WHEN is dangerous. Wisdom prevents misapplication of knowledge. Conviction prevents the system from constantly second-guessing validated truths while remaining open to revision. The fractal architecture ensures that a truth discovered at one level can benefit all levels without compromising data sovereignty. The emotional experience vector prevents the system from flattening the human experience into pure positivity optimization.

**What breaks if ignored:** The system has knowledge but no judgment. It applies patterns indiscriminately without context. It can't share structured insights across the federation. It has no mechanism for earned certainty or structured self-questioning.

### Decision #46: Agent Cognition & Continuity (The Agent Thinks, Not Just Reacts)

**Decision:** Give the agent persistent working memory (`AgentContext`) across wake cycles, scheduled thinking sessions during device idle time, multi-horizon reasoning (hours/days-weeks/months-seasons), and the ability to self-schedule future wake-ups. The agent's thinking process feeds the meta-learning engine so the system learns how it thinks.

**Alternatives considered:**
- **Reactive-only**: The agent only acts on explicit triggers. Problem: no deliberation, no long-term planning, no hypothesis development.
- **Cloud-based reasoning**: Move thinking to the cloud. Problem: violates offline-first principle, introduces latency, requires network.
- **Always-on foreground service**: Keep the agent running continuously. Problem: battery drain, user annoyance, platform policy violations.

**Why:** A recommendation engine reacts. A personal AI companion thinks. The agent needs to observe patterns over days, develop hypotheses, and wait for the right moment to act. Platform-specific background execution strategies (BGProcessingTask on iOS, WorkManager on Android) allow genuine background reasoning within OS constraints.

**What breaks if ignored:** The agent is reactive, not deliberative. It can't develop hypotheses about the user's trajectory. Multi-horizon planning is impossible. The user doesn't experience a living agent -- they experience a smart search engine.

### Decision #47: Self-Interrogation (The System Questions Its Own Beliefs)

**Decision:** The system periodically examines its own convictions through structured self-questioning, cross-scope comparison, stress testing, and integration of human challenges. A conviction that goes unchallenged stops improving.

**Why:** Without self-interrogation, convictions calcify. The system becomes confident about things that are no longer true. Self-questioning is the engine that keeps the pursuit of understanding moving.

### Decision #48: Researcher Access (Opening Doors for Academic Understanding)

**Decision:** Build a dedicated researcher access pathway with IRB-compatible anonymization, consent framework, research API, longitudinal cohorts, and a sandbox environment. Research findings feed back into the conviction system.

**Why:** Researchers ask questions the system can't generate internally. Their findings strengthen or challenge convictions. AVRAI's uniquely rich dataset (longitudinal behavior with happiness outcomes) would be wasted if only used commercially.

### Decision #49: Composite Entity Identity (Real-World Entities Are Multi-Dimensional)

**Decision:** Allow single real-world entities to occupy multiple quantum entity types simultaneously (business + event host + service provider). Linked through a shared `entity_root_id` with cross-role learning via the conviction system.

**Why:** Real-world entities don't fit into single categories. A hairdresser business that hosts wine-and-art nights is simultaneously a business, event host, and service provider. Forcing them into one role loses data and creates a poor experience.

### Decision #50: Conviction Oracle (A Physical Place to Sit with System Truths)

**Decision:** Dedicate a physically isolated machine (or hardened container) to house the universe-scope conviction store with a creator-only conversational interface. The oracle receives DP-protected conviction serializations from the federation, maintains the complete conviction audit trail, and provides an LLM-backed chat interface for querying, challenging, injecting, freezing, and simulating convictions. Air-gapped from raw user data by design.

**Why:** Universe-scope convictions represent the highest-order truths AVRAI has discovered across all populations. The creator needs a direct, private, conversational line to this intelligence -- not buried in dashboards, but a dedicated place to sit with the system's understanding and question it. The self-interrogation system (Phase 7.9J) runs continuously, so when the creator visits, the oracle genuinely has new thoughts to share. Physical isolation ensures: (a) conviction data cannot be conflated with user-identifying data, (b) a single point of trust for the system's deepest beliefs, (c) a philosophical space, not just a technical endpoint.

**Alternatives considered:**
1. **Admin platform module only** -- Rejected because the admin platform serves many purposes; conviction introspection deserves focused, dedicated space without UI clutter
2. **Cloud-hosted service** -- Viable as a fallback (containerized with SSH/VPN), but a physical machine creates a stronger philosophical connection and eliminates cloud provider dependency for the most sensitive data
3. **No dedicated service** -- Rejected because querying universe convictions through general-purpose APIs loses the conversational, narrative quality that makes the oracle valuable

### Decision #51: Sensory Architecture (The System Has Eyes, Ears, a Mouth, and Senses)

**Decision:** Map every component to a sensory metaphor: Eyes (observation bus, self-model), Ears (input normalization), Mouth (output delivery with grounding), Senses (raw signal acquisition), Brain (decision core). All senses feed each other bidirectionally via the observation bus. No sense is dominant.

**Why:** The system's architecture was implicitly organized around these roles, but without an explicit mapping, components evolved in isolation. The sensory architecture formalizes the cross-feeding requirement: the energy function's diagnostics inform the translation layer's vocabulary; the SLM's grounding rate informs the state encoder's feature weighting; sensor degradation informs input normalization. Making these relationships explicit prevents architectural drift where components optimize locally but degrade globally.

**Alternatives considered:**
1. **Implicit cross-component communication** -- Rejected because it leads to point-to-point coupling without systematic coverage
2. **Centralized orchestrator** -- Rejected because it creates a bottleneck and single point of failure; the observation bus is decentralized
3. **No metaphor (pure technical)** -- The metaphor helps with communication and reasoning about the system, and maps to the Humanity Mapping (awareness, agency, resilience)

### Decision #52: Universal Self-Healing Doctrine (Every Non-Guardrail Component Can Improve Itself)

**Decision:** Declare that every component of the system -- not just models and parameters, but mathematical output formats, data pipeline structures, model architectures, inter-component protocols, translation vocabularies, and input processing rules -- is a candidate for self-improvement. Self-healing proposals go through the self-optimization engine (Phase 7.9) and are validated by the observation bus (Phase 7.12). Only guardrails (Phase 7.9E), privacy protections (Phase 2), and the conviction challenge protocol (Phase 7.9J) are exempt.

**Why:** Previous self-optimization was limited to model parameters and feature flags. But many performance improvements require changing the formats, schemas, or structures that connect components. If the energy function's output format is suboptimal for the translation layer, fixing this requires changing the output format -- not just the model weights. The system needs the authority and mechanism to improve its own infrastructure, not just its intelligence functions.

**Alternatives considered:**
1. **Self-healing limited to models and parameters** -- Rejected because the biggest improvements often come from structural changes (format optimization, pipeline restructuring)
2. **No guardrail exemption** -- Rejected because guardrails and privacy must be immutable to maintain trust
3. **Human-only infrastructure changes** -- Viable but prevents autonomous improvement of non-critical structural decisions; the observation bus provides enough diagnostic evidence for safe automated proposals

### Decision #53: Reality Model Definition (AVRAI as a Reality Model, Not a Language Model)

**Decision:** Formally define AVRAI as a "Reality Model" -- the full hierarchy of world models (individual) → universe models (collective) → reality (composition). The reality model is distinct from language models (SLM/LLM) which serve as the "mouth" and "ears" interfaces. The reality model learns from actual behavior, is grounded in physical space and time, composes collective reality from individual experiences, tracks emotional states, self-interrogates its convictions, and holds truths provisionally.

**Why:** The distinction prevents architectural confusion between the brain (small ONNX networks that produce numeric outputs representing reality) and the mouth (SLM/LLM that produces text). All intelligence and understanding lives in the reality model. The SLM is an interface to that intelligence, not intelligence itself. This definition also positions the system as fundamentally different from LLM-based products: AVRAI understands behavior and experience; LLMs understand language.

**Alternatives considered:**
1. **"World model" only** -- Insufficient because the system spans multiple scales (individual → collective → universal) that "world model" doesn't capture
2. **"AI system" (generic)** -- Misses the philosophical distinction between modeling language and modeling reality
3. **No formal definition** -- Leads to confusion about which components are "the brain" vs. "the mouth"

### Decision #54: Hardware Abstraction Hierarchy (Classical → NPU → Quantum)

**Decision:** Expand the existing `QuantumComputeProvider` into a three-tier `HardwareComputeRouter`: classical CPU (always available), AI chips/NPU (available today on flagship devices), and cloud quantum (future). Each operation is routed to the optimal tier based on operation type, device capability, battery level, and latency requirement. The Sensor Abstraction Layer ensures new hardware sensors register on the same interface.

**Why:** The existing quantum abstraction skipped the NPU tier that's available today. Modern flagship phones have dedicated AI chips (Apple Neural Engine, Google Tensor TPU, Qualcomm Hexagon) that provide 2-5x speedup for the exact operations AVRAI runs most frequently (ONNX model inference). Ignoring this hardware wastes real, available performance. The three-tier hierarchy ensures the system works on any device (classical fallback) while accelerating on what's available.

**Alternatives considered:**
1. **Quantum-only abstraction** -- Rejected because NPUs are available now and provide immediate benefit
2. **Framework-specific acceleration (CoreML, NNAPI)** -- Too tightly coupled to platform; ONNX Runtime delegates provide cross-platform abstraction
3. **No hardware abstraction** -- Would require re-architecture when NPU or quantum hardware is adopted

### Decision #55: Agent Happiness Philosophy and User Agency Doctrine

**Decision:** Codify two principles: (1) Agent happiness measures quality of life improvement, not prediction accuracy. Both successful and unsuccessful predictions are equally valuable learning signals. (2) Users always have a choice to act on suggestions. Non-participation is a valid, informative signal. Over-suggestion triggers frequency reduction, not persuasion increase.

**Why:** Without explicit principles, optimization systems naturally converge toward maximizing prediction accuracy and user action rates -- which leads to engagement traps. AVRAI's purpose is to open doors, not optimize clicks. A prediction the user ignores teaches the model about user preferences and agency. A prediction the user follows teaches the model about good recommendations. Both are valuable. The user agency doctrine also prevents the system from interpreting declined suggestions as failures and escalating to more aggressive recommendations.

**Alternatives considered:**
1. **Accuracy-first optimization** -- Rejected because it would lead to safe, obvious recommendations (high accuracy but low value)
2. **No formal principle** -- Leads to implicit accuracy optimization by default
3. **User agency without learning** -- Rejected because non-participation data is too valuable to discard

---

## v16 Quick Reference

| Name | Description | Phase | Related Phases |
|------|-------------|------:|-----------------|
| Multi-Dimensional Happiness | Learned happiness dimensions with self-calibrating per-user weights | 4.5B | 8.9B, 7.9, 5.1, 6.1 |
| DSL Self-Modification | Safe on-device strategy composition without code changes | 7.9H | 7.9C, 7.9E, 7.7 |
| Tax & Legal Compliance | Jurisdiction rules stored in locality agents/universe hierarchy | 9.4H | 8.9, 13, 9.4E, 5.1 |
| Hybrid Expertise | Behavioral evidence + verified credentials → fused expertise score | 9.5 | 7.10A, 6.7B, 8.1, 13 |
| Partnership Matching | Agents proactively scout B2B, expert, and community partnerships | 9.5B | 4.4, 8.6, 9.4, 8.1 |
| Admin Platform | Desktop app with AI Code Studio, system monitor, partner SDK | 12 | 7.9, 7.7, 9.5.5, 9.2.6 |
| Universe Model | Fractal federation: world → org → category → AVRAI universe | 13 | 8.1, 8.9E, 7.7, 1.5D |
| Seamless Adoption | World models auto-activate for users based on location | 13.1.5 | 6.6, 13.1.3, AgentIdService |
| University Lifecycle | Freshman→senior progression learned from category model | 13.3 | 5.1, 9.5, 8.6 |
| Cross-Instance Intelligence | Learning/healing/adapting/coding across federation levels | 13.4 | 7.9H, 12.2, 8.1, 7.9F |
| Meta-Learning Engine | Learning Cycle Ledger + weekly meta-analysis + process optimization + 7 immutable meta-guardrails | 7.9I | 1.1C, 7.9C, 7.9E, 12.1.3, 13.2 |
| Value Intelligence | Causal chain attribution + hindsight surveys + stakeholder metrics + pilot toolkit + self-proving intelligence | 12.4 | 1.1, 5.1, 4.5B, 6.7B, 7.9I, 7.10A, 13.2 |
| Knowledge-Wisdom-Conviction | Knowledge store + wisdom layer + conviction formation/challenge + fractal bidirectional flow + emotional experience vector | 1.1D | 1.1C, 4.5B, 7.9I, 7.9J, 13.2, 13.4 |
| Self-Interrogation | Conviction review + cross-scope comparison + stress testing + human challenge + constructive disruption | 7.9J | 1.1D, 7.9I, 5.1, 12.1.3, 14 |
| Agent Cognition | Persistent AgentContext + thinking sessions + multi-horizon reasoning + self-scheduled triggers | 7.11 | 7.4, 7.9I, 1.1D.2, 6.7B, 6.1 |
| Composite Entity Identity | Multi-role entities with cross-role learning via conviction system | 9.6 | 1.1D, 4.4, 1.7, 12.1.3 |
| Researcher Access | IRB-compatible anonymization + research API + longitudinal cohorts + sandbox + feedback loop | 14 | 2.2, 8, 12, 13, 1.1D |
| Conviction Oracle | Dedicated universe conviction server with creator-only conversational interface, simulation sandbox | 12.5 | 1.1D, 7.9J, 7.9I, 7.11, 12, 13, 2 |
| Emotional Experience | Full emotional spectrum (7 emotions + mixed) as episodic context and wisdom layer input | 1.1D.7 | 4.5B, 3.1, 6.1, 7.10C |
| Sensory Architecture | Eyes/Ears/Mouth/Senses/Brain mapped to technical components with bidirectional cross-feeding | 7.12, 6.7C, 3.1, 6.7 | All phases |
| Universal Self-Healing | Every non-guardrail component can diagnose, experiment on, and improve itself | 7.9, 7.12 | 6.7C, 7.9H, 13.4 |
| Reality Model | Full hierarchy: world models → universe models → reality. Multi-layered understanding of humanity | 5, 8, 13, 1.1D | All phases |
| Hardware Abstraction | Three-tier compute: Classical CPU → AI chip/NPU → Quantum. Sensor abstraction for future hardware | 11.4C-F | 7.5, 7.12, 7.10B |
| Agent Happiness Philosophy | Predictions are metrics, not baselines; both outcomes equally valuable for learning | Core | 4.5B, 7.9, 6.1 |
| User Agency Doctrine | Non-participation is valid signal; over-suggestion triggers reduction, not persuasion | Core | 1.2.16, 6.1, 7.10D |
| Translation Layer | Self-healing semantic bridge between numeric reality model outputs and conversational language | 6.7C | 6.7, 7.9, 7.12, 7.9H |

---

## Life Pattern Intelligence Quick Reference

| Name | Description | Phase | Related Phases |
|------|-------------|------:|-----------------|
| Passive Life Pattern Engine | Background location + widget + absence → routine model on-device | 7.10A | 1.7, 5.1.9, 5.1.11, 7.4 |
| Active Life Pattern Engine | SLM intent extraction + tool-calling framework (7 tools) | 6.7B | 6.7, 7.10A.2, 8.6B, 9.4 |
| Social Quality-of-Life Layer | Per-friend happiness correlation + group composition + social absence detection | 7.10C | 4.4, 8.6, 10.4A |
| Notification Philosophy | 4-tier hierarchy: never/rarely/user-only/active-engine-ok + inference exhaustion | 7.10D | 7.9E, 6.2.6 |
| Ad-Hoc Group Formation | SLM intent → BLE scan → confirm → joint score → book | 8.6B | 6.7B.2, 6.6, 4.4, 9.4 |

---

**Last Updated:** February 13, 2026  
**Version:** 4.0 (added Decisions #51-55: Sensory Architecture, Universal Self-Healing Doctrine, Reality Model Definition, Hardware Abstraction Hierarchy, Agent Happiness Philosophy & User Agency Doctrine. Previous: 3.1 added Decision #50: Conviction Oracle. Previous: 3.0 added Decisions #45-49. Previous: 2.0)
