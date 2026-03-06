# Foundational Decisions

**Created:** February 10, 2026  
**Purpose:** Explains the "why" behind every architecture-wide decision in the Master Plan. Read this before starting ANY phase.  
**Companion to:** `docs/MASTER_PLAN.md` (what to build), `docs/MASTER_PLAN_TRACKER.md` (where things live)  
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
| 1 | #1 (intelligence-first), #5 (Drift over ObjectBox), #7 (chat-as-accelerator), #8 (AI2AI only -- organic discovery mesh), #12 (doors -- discovered locations) |
| 2 | #4 (on-device/privacy), #15 (post-quantum) |
| 3 | #2 (energy-based), #6 (ONNX), #9 (preserve quantum systems), #13 (lists as entities) |
| 4 | #2 (energy-based), #3 (VICReg), #11 (feature flag replacement), #14 (bilateral energy) |
| 5 | #3 (VICReg), #4 (on-device), #7 (chat-as-accelerator) |
| 6 | #7 (chat-as-accelerator), #12 (doors philosophy), #4 (on-device/offline) |
| 7 | #10 (device tiers), #9 (preserve quantum systems), #17 (model lifecycle/OTA), #18 (multi-device) |
| 8 | #4 (on-device/privacy), #8 (AI2AI only), #16 (locality happiness advisory) |
| 9 | #14 (bilateral energy), #12 (doors philosophy), #19 (third-party data pipeline) |
| 10 | #5 (Drift over ObjectBox), #9 (preserve quantum systems), #20 (accessibility as doors), #21 (internationalization) |
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

---

### Decision 22: Cognitive Kernel as Stable OS Layer (Phase 12)

**Phase:** 12.1-12.2  
**Why:** The three-prong architecture (apps → runtime → engine) already encodes OS-like layering in its dependency rules. The foundational decision to formalize this into an actual kernel process is: **the runtime must own agent state and cognitive resources as a durable process, not as a service registry inside another application's memory space.**

**The core reasoning:**
- GetIt DI container is a service locator inside one Flutter process. When iOS suspends the app, all cognitive state goes dark. This is incompatible with an OS, which must persist.
- A separate OS process with its own PID (Android `:avrai_runtime` bound service; iOS XPC service; Linux daemon) gives the runtime the same durability guarantee that a real OS provides: process crash does not lose state; host can restart without losing cognitive continuity.
- The platform adapter pattern (one thin shim per host OS, all delegating to the same Rust kernel) is the same pattern that lets Android run on ARM, x86, and RISC-V without changing the Android framework. AVRAI should have the same portability.

**What it covers:**
- Rust cognitive kernel runs headless (without Flutter)
- Platform adapters hold hardware capability grants on behalf of the kernel
- Flutter app becomes a kernel client, not the kernel host
- Stable cognitive syscall API (perceive, plan, commit, observe, recover) is a versioned contract, not an implementation detail

**What breaks if ignored:** AVRAI remains a Flutter app that happens to have good ML. It cannot be packaged as infrastructure. AI companies cannot integrate with it (no stable API to call). It dies when the app is backgrounded. It cannot run on a home server or in a container.

**Alternatives considered:**
- **Keep everything in Flutter, add background service later**: deferred OS work always becomes harder as coupling grows. The three-prong boundary rules already enforce the correct dependency direction — the kernel extraction simply makes that boundary a real process boundary, not just an import rule.
- **Build the OS separately from the app**: rejected because 80% of the runtime layer already exists. Extraction is the correct path, not greenfield.

---

### Decision 23: Delegation Through Hardware Is Sufficient OS Authority (Phase 12)

**Phase:** 12.2  
**Why:** A common objection to calling AVRAI an OS is "it doesn't own the hardware." This decision formally resolves that objection.

**The reasoning:** Android doesn't own ARM silicon — it delegates through Linux. The JVM doesn't own any hardware — it runs on any OS. Both are unambiguously OS-like because they provide a mandatory mediation layer that everything above them depends on. Authority over a resource domain is what makes an OS, not ownership of the physical substrate.

AVRAI's resource domain is **AI cognition**: behavioral memory, inference compute, agent identity, AI-to-AI communication. If every AI company and application that wants access to these resources must call AVRAI's stable API, AVRAI has OS-level authority over that domain — regardless of what silicon it runs on.

**Implication:** Platform adapters (12.2) are sufficient. AVRAI does not need to own iOS/Android/Linux hardware. It needs to own the capability grants that those OSes provide (BLE, Neural Engine, background execution, network) and make them available to the cognitive kernel as delegated resources.

**What breaks if ignored:** Confusion about whether AVRAI is "really" an OS will derail architectural decisions during Phase 12. This decision makes the definition explicit and non-negotiable: authority over a domain is the criterion, not hardware ownership.

---

### Decision 24: Beta Validates Product; OS Phase Validates Platform (Phase 12)

**Phase:** Cross-cutting (beta and Phase 12)  
**Why:** The OS work (Phase 12) must not start until beta has validated product-market fit. This is a sequencing decision with significant consequence.

**The reasoning:**
- Building OS infrastructure before proving users want the product is the same mistake as the legacy plan's "build features, bolt on ML later." You'd be building infrastructure for a product that might need to change.
- Beta produces the first real behavioral data that trains the reality model — which is required for Phase 12.4 (reality model baseline). Beta comes first not just strategically but architecturally.
- The cognitive syscall API (12.3.1) should be designed with knowledge of how users actually interact with the system. Beta provides that knowledge.

**What it covers:** Phase 12 has a hard gate: beta must validate product-market fit before Phase 12.1 begins. The swarm simulation (v0.3 Sprint) provides the synthetic baseline for Phase 12.4 — but real beta data improves it dramatically.

**What breaks if ignored:** Phase 12 infrastructure is built for a product that doesn't exist yet. If beta reveals the core loop needs fundamental changes, OS infrastructure built on the pre-pivot product is wasted.

### Decision 25: Air Gap as Privacy Physics — Gas/Liquid/Solid Permeability Model

**Phase:** Cross-cutting (all phases). Air Gap is the oldest privacy invariant in the system.  
**Why:** AVRAI's privacy model needs to be both rock-solid (raw data NEVER persists) and user-controllable (different people want different levels of context sharing). These two goals are in tension if privacy is treated as a policy toggle. Decision 25 resolves the tension by making privacy a law of physics (the Air Gap always enforces the boundary) while making permeability a user-configurable property of that boundary.

**The core reasoning:**
- A policy-based privacy model ("don't store raw data unless user opts in") is fragile: it can be broken by a bug, a bad deployment, a security hole, or a confused developer who doesn't read the policy. Policies break.
- A physics-based model (the only architectural path for data to reach storage IS the TupleExtractionEngine, which destroys the raw payload) is structurally enforced. You cannot accidentally bypass it any more than you can accidentally bypass the laws of thermodynamics.
- But a physics model without user control is paternalistic: users who want their AI agent to learn from ALL of their context (health, calendar, home, physical presence) deserve that richness. A completely opaque Air Gap that rejects all external signals is not serving users.

**The gas/liquid/solid model solves this:** Three permeability states give users intuitive control over how much of their reality the Air Gap allows through:
- **Gas:** maximum permeability, maximum personalization. Default. Raw data still cannot persist.
- **Liquid:** filtered permeability, domain-by-domain control. For cautious users.
- **Solid:** opaque, for specific domains where the user wants complete separation.

**What the model covers:**
- App data permeability (Phase 12.5 Plugin Framework — which local apps can contribute signals)
- Physical identity permeability (Phase 12.8 — physical-to-digital matching opt-in)
- Per-domain solid settings (work/relationships/health can each be independently solidified)
- The permeability setting controls WHAT passes through the Air Gap, never WHETHER the Air Gap exists. The TupleExtractionEngine is always the crossing point.

**What breaks if ignored:** Users who want rich personalization but get opaque privacy will choose competitors. Users who want privacy but get data leakage lose trust permanently. The gas/liquid/solid model prevents both failure modes by giving users a visceral, correct mental model of how their data moves.

**Alternatives considered:**
- **Binary opt-in/opt-out per feature:** Too granular to manage; users stop caring and click "allow all." Gas/liquid/solid gives coarser but more meaningful control.
- **Differential privacy only:** DP is for aggregate output, not for controlling what the model learns. The Air Gap and DP are complementary, not alternatives.
- **User-controlled consent scopes per app:** Phase 12.3.3 already does this. Gas/liquid/solid is a higher-level abstraction that sits above per-app consent.

**Implementation:**
- `AirGapContract` and `TupleExtractionEngine` are the physics layer (already implemented)
- `AirGapPermeabilityService` (Phase 2, extend for plugin framework and physical identity) manages per-domain permeability state
- UI: gas/liquid/solid visualized as a material-design state toggle in privacy settings, not a checkbox list

---

---

### Decision 26: Transport Backend Abstraction (Polymorphic Transport Layer)

**Phase:** 3.7A (companion to 3.7 mesh unification)  
**Why:** The runtime has 93+ transport files across BLE, mesh, and Supabase realtime — each with its own parameter shapes, orchestration patterns, and lifecycle management. Adding new transports (DTN wormhole routing, future protocols) requires touching the orchestrator directly. This coupling means the orchestrator must *know* about every transport, which violates the principle that intelligence infrastructure should be transport-agnostic.

**The decision:** Define a `TransportBackend` abstract interface that all transports implement. The interface has: `initialize`, `shutdown`, `send`, `startDiscovery`, `stopDiscovery`, `inboundMessages`, `discoveredPeers`, and a `capabilities` set (`Set<TransportCapability>`). A `TransportOrchestrator` selects backends based on capabilities and target requirements.

**The core reasoning:**
- The energy function (Phase 4) and MPC planner (Phase 6) need to make *learned* transport decisions — "is BLE or mesh better for this message right now?" The transport interface provides the abstraction on which learned routing operates. Without it, transport routing is hardcoded in orchestration lanes.
- Phase 8.2's hybrid sync strategy (BLE for small gradients, cloud for checkpoints) is naturally expressed as capability-based transport selection, not if-else branches.
- The `TransportCapability` set is the key design element: each backend declares what it can do (`rssiProximity`, `storeAndForward`, `realtime`, `highBandwidth`, etc.) and the orchestrator selects based on capabilities, not transport identity. New transports register and work without code changes.

**What breaks if ignored:** Every new transport requires modifying `VibeConnectionOrchestrator` (or its successor). DTN wormhole routing (Phase 6.6) requires custom integration. Phase 8.2's hybrid sync strategy is implemented as scattered if-else logic instead of declarative capability matching.

**Alternatives considered:**
- **Keep transport-specific code inline:** Rejected because the current 93-file transport layer already demonstrates this approach's scalability problems.
- **Declarative routing table (OpenClaw-style):** Rejected because static routing tables contradict Decision #1 (intelligence-first). Transport routing should be *learned* by the energy function, with the interface providing the infrastructure for that learning.

**Phase 12 note:** Phase 12's Rust kernel will likely define its own transport abstraction. The Dart `TransportBackend` concept and capability model inform that design, even though the Dart implementation may be replaced.

---

### Decision 27: Subsystem Isolation (Decomposed Orchestrator Architecture)

**Phase:** 7.10 (prerequisite for 10.9.12 self-healing)  
**Why:** `VibeConnectionOrchestrator` is a 1000+ line god object with 70+ imports and 30+ mutable state variables. It owns discovery, connection lifecycle, learning insight dispatch, event mode, BLE inbox processing, mesh forwarding, and replay guard — all in one class. Phase 10.9.12 requires every *subsystem* to auto-create healing cycles and feed break telemetry back into learning metrics. If there is no subsystem boundary, there is nothing to attach break detection to.

**The decision:** Decompose the orchestrator into isolated `RuntimeSubsystem` instances (discovery, connection, learning, event mode, etc.) that communicate through typed events (`Stream<RuntimeEvent>`), not shared mutable state. A thin `SubsystemOrchestrator` manages lifecycle and routes events between subsystems.

**The core reasoning:**
- Self-healing (10.9.12) requires fault isolation: if discovery fails, connection lifecycle should continue to function for existing connections. With one monolithic class, any failure potentially corrupts all state.
- Each subsystem owns its state and can be independently restarted. This makes the self-healing loop concrete: restart the broken subsystem, not the entire orchestrator.
- The decomposition is incremental — each subsystem is extracted one at a time, with the old orchestrator wrapping subsystem calls during transition. No big-bang rewrite.

**What breaks if ignored:** Phase 10.9.12's universal break-to-learning healing loop cannot be implemented because there are no subsystem boundaries to detect breaks across. Self-healing remains blocked, which blocks autonomous adaptation features from production.

**Connection to Decision #26:** Subsystems use `TransportOrchestrator` (from Decision #26) for transport operations and `TransportRuntimeContext` for shared state. The transport layer and the subsystem layer are complementary: transports handle *how messages move*, subsystems handle *what the runtime does with them*.

---

### Decision 28: Connection Capability Model (Declarative AI2AI Permissions)

**Phase:** 8.2A (architecture decision within Phase 8)  
**Why:** AI2AI permission logic is currently scattered as ad-hoc boolean checks across `ConnectionOrchestrator`, `DiscoveryManager`, `ConnectionManager`, and various lane files. As Phase 8 adds richer interactions (insight exchange, group negotiation, expert discovery, gradient sharing), these scattered checks become unmaintainable. A missed permission check is a privacy violation.

**The decision:** Define a `ConnectionCapabilityProfile` per peer that consolidates all permissions into a single queryable object. The orchestrator calls `canDo(capability)` instead of scattered if-checks. Capabilities have constraints (rate limits, trust level requirements, consent gates, expiry) that are evaluated compositionally.

**The core reasoning:**
- The capability model is a *governance structure*, not a scoring formula. It answers "is this interaction allowed?" (constraint), not "how good is this interaction?" (scoring). This keeps Decision #1 (intelligence-first) intact — the energy function handles scoring, the capability model handles permission boundaries.
- The Air Gap (Decision #25) operates at the *data level* (what can cross the boundary). The capability model operates at the *connection level* (what can this specific AI2AI connection do). They are complementary.
- Capability evolution (trust builds over time, tightens after violations) creates a natural adaptive permission system that the energy function can learn to optimize.

**What breaks if ignored:** AI2AI permissions remain scattered, making security audit nearly impossible. New Phase 8 interactions require finding and adding checks in multiple files. Privacy violations from missed checks become likely as the interaction surface grows.

---

### Decision 29: Zero Trust as Security Architecture

**Phase:** Cross-cutting (all phases). Zero trust is an architectural principle, not a single feature.  
**Why:** AVRAI operates in the age of agentic AI — autonomous agents that call APIs, use tools, communicate with other agents, and take actions in the real world. Every new capability adds a new attack surface. Traditional perimeter-based security ("hard crunchy outside, soft chewy center") fails because: (1) AI agents use non-human identities that proliferate faster than human accounts, (2) agent actions are autonomous and can cause damage before a human notices, (3) the attack surface spans app, engine, and runtime layers, and (4) "harvest now, decrypt later" attacks mean even encrypted traffic is vulnerable if credentials are static.

Zero trust replaces perimeter security with four principles:
1. **Verify then trust** — nothing gets access until it proves it should (continuous verification, not just login)
2. **Just-in-time, not just-in-case** — grant minimum privileges, only when needed, then revoke (dynamic credentials via `SecretVaultService`)
3. **Pervasive controls** — security at every layer, not just the network edge (engine validates inputs independently of runtime; action gateway inspects every agent action)
4. **Assume breach** — design as if the attacker is already inside (immutable audit logs, anomaly detection, kill switches, defense-in-depth)

**What it covers:**
- Dynamic credential lifecycle with JIT provisioning and automatic rotation (Phase 2.7)
- Continuous session re-verification with step-up auth for high-impact operations (Phase 2.8)
- LLM input sanitization and prompt injection hardening at every entry point (Phase 3.10)
- Zero trust tool registry with signed manifests and runtime verification (Phase 6.3.5-6.3.6)
- AI action gateway as inspection layer between planner intent and action execution (Phase 6.10)
- Immutable, tamper-evident audit log persistence (Phase 10.9.26)
- Engine-layer security boundaries with independent input validation (Phase 10.9.27)
- BLE anti-spoofing with challenge-response authentication (Phase 10.9.28)
- Zero trust compliance dashboard for real-time posture visibility (Phase 10.9.29)

**What breaks if ignored:** Static credentials become permanent backdoors. LLM inputs are unsanitized attack vectors. Agent actions execute without inspection — a poisoned model or prompt injection can cause damage before anyone notices. Audit logs exist only in console output and vanish on restart. The engine trusts whatever the runtime passes it, eliminating defense-in-depth. BLE discovery is spoofable. Admins have no visibility into zero trust posture.

**Connection to existing decisions:**
- Decision #4 (on-device/privacy): Zero trust extends on-device privacy with credential lifecycle and continuous verification
- Decision #25 (Air Gap): Zero trust adds defense-in-depth layers around the Air Gap (sanitization before extraction, anomaly detection after)
- Decision #28 (Connection Capability Model): Zero trust adds authentication and authorization to the capability model's permission structure

---

## Quick Reference: Key Decisions by Phase Relevance

| Phase | Most Relevant Decisions |
|------:|------------------------|
| 1 | #1 (intelligence-first), #5 (Drift over ObjectBox), #7 (chat-as-accelerator), #8 (AI2AI only -- organic discovery mesh), #12 (doors -- discovered locations) |
| 2 | #4 (on-device/privacy), #15 (post-quantum), #25 (air gap as privacy physics), #29 (zero trust -- credential vault, continuous verification) |
| 3 | #2 (energy-based), #6 (ONNX), #9 (preserve quantum systems), #13 (lists as entities), #26 (transport backend abstraction), #29 (zero trust -- prompt injection hardening) |
| 4 | #2 (energy-based), #3 (VICReg), #11 (feature flag replacement), #14 (bilateral energy) |
| 5 | #3 (VICReg), #4 (on-device), #7 (chat-as-accelerator) |
| 6 | #7 (chat-as-accelerator), #12 (doors philosophy), #4 (on-device/offline), #29 (zero trust -- action gateway, tool registry) |
| 7 | #10 (device tiers), #9 (preserve quantum systems), #17 (model lifecycle/OTA), #18 (multi-device), #27 (subsystem isolation) |
| 8 | #4 (on-device/privacy), #8 (AI2AI only), #16 (locality happiness advisory), #26 (transport abstraction for hybrid sync), #28 (connection capability model) |
| 9 | #14 (bilateral energy), #12 (doors philosophy), #19 (third-party data pipeline) |
| 10 | #5 (Drift over ObjectBox), #9 (preserve quantum systems), #20 (accessibility as doors), #21 (internationalization), #27 (subsystem isolation for 10.9 self-healing), #29 (zero trust -- audit persistence, engine boundaries, BLE hardening, compliance dashboard) |
| 11 | #6 (ONNX/quantum-ready), #3 (VICReg for JEPA) |
| 12 | #22 (cognitive kernel as OS layer), #23 (delegation = OS authority), #24 (beta before OS), #25 (air gap permeability), #4 (on-device/privacy), #6 (ONNX/quantum-ready), #8 (AI2AI only), #26 (transport interface informs Rust kernel), #29 (zero trust -- external caller auth uses credential vault) |

---

**Last Updated:** March 5, 2026  
**Version:** 1.8 (added Decision #29: Zero Trust as Security Architecture. Previous: 1.7 Decisions #26-#28)
