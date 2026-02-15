# Phase 7 Rationale: Orchestrator Restructuring, System Integration, Self-Interrogation, Agent Cognition & Observation Service

**Phase:** 7 | **Tier:** 2 (Depends on Phase 4 minimum) | **Duration:** 16-20 weeks  
**Companion to:** `docs/MASTER_PLAN.md` Phase 7  
**Read before starting:** `FOUNDATIONAL_DECISIONS.md` (Decisions #9, #10, #51, #52, #53)

---

## Why This Phase Exists

Phases 3-6 build new intelligence components. Phase 7 wires them into the EXISTING system. The codebase has 6 orchestrators, 21 controllers, 330+ services -- all currently running on hardcoded formulas. Phase 7 replaces their decision-making with the world model.

This is the integration phase. Without it, the world model exists in isolation and users never see its benefits.

---

## Key Design Decisions

### Why the Evolution Cascade Must Be Atomic (7.1.2)
When personality changes, 6 systems must update in sequence:
```
PersonalityChange → QuantumVibeEngine.recompile()
                  → PersonalityKnotService.recompute()
                  → KnotFabricService.updateInvariants()
                  → WorldsheetEvolutionDynamics.step()
                  → KnotEvolutionStringService.updateRates()
                  → DecoherenceTrackingService.updatePhase()
                  → WorldModelFeatureExtractor.captureFullSnapshot()
```

Currently, only knot evolution is wired. The rest are placeholder log-only methods. If the state encoder reads features mid-cascade (quantum updated but knot not yet), it sees an internally inconsistent state. LeCun's framework requires coherent state observation.

### Why Event-Driven Triggers Replace Polling (7.4)
`ContinuousLearningOrchestrator` currently uses a 1-second `Timer.periodic`. Running inference every second means:
- Constant battery drain even when nothing changes
- ~5-30ms compute 86,400 times per day = significant cumulative cost
- Most cycles do nothing (user hasn't moved, no new data)

Event-driven triggers (app open, location change, AI2AI connection, timer every 2hr) fire 20-50 times per day instead of 86,400. Between triggers, the agent SLEEPS (zero battery). Each activation: 1-5 reasoning steps, 6-30ms compute, negligible impact.

**Integration risk**: The orchestrator's state tracking (cycle counting, convergence) assumes periodic execution. Refactor to track "activations" instead of "cycles."

### Why 4 Device Tiers (7.5)
See Foundational Decision #10. Every user gets an agent, but its capabilities scale with hardware. The key insight: the SAME codebase serves all devices. `DeferredInitializationService` only loads components available at the detected tier. No wasted memory loading world model ONNX on a Tier 0 device that will never use it.

**Integration risk**: The existing `OfflineLlmTier` enum overlaps with the new `AgentCapabilityTier`. Resolution: `AgentCapabilityTier` subsumes `OfflineLlmTier`. Keep the old enum as a derived property for backward compatibility with settings pages.

### Why Dependency Chain Management Is Documented Here (7.6)
When replacing a formula in a service, ALL downstream consumers must update atomically. Example: if `VibeCompatibilityService` switches from formula to energy function, `CallingScoreCalculator`, `CommunityService`, and `GroupMatchingService` all use it. Feature flags must flip atomically, not one-at-a-time.

### Why Model Lifecycle Management (7.7)
OTA model delivery is necessary because App Store updates are too slow for iterative model improvement. Users expect weekly or monthly releases; the world model needs to evolve faster. Staged rollout with canary prevents regressions from hitting all users simultaneously -- a small percentage receives the new model first, and metrics are validated before broader deployment. Per-user rollback is needed in addition to global rollback because some users degrade while global metrics stay fine; individual users may have edge-case data or device states that cause the new model to fail. The model-episodic compatibility gate prevents crashes from schema mismatch: when the model expects a different feature structure than the episodic store provides, the gate blocks deployment.

### Why Multi-Device Reconciliation (7.8)
Primary/secondary architecture (not peer-to-peer model merge) is the right approach. Peer-to-peer merge would require conflict resolution across arbitrary device graphs; primary/secondary gives a clear source of truth. Episodic data flows secondary → primary (accumulate experiences from all devices) while personality state flows primary → secondary (the canonical AI state is defined on the primary device). Device migration should transfer AI state so users don't cold-start on a new phone; the personality, learning history, and world model state should move with the user.

### Why Autonomous Self-Optimization Engine (7.9)

**The problem:** AVRAI collects data from 23+ sources (quantum states, knot invariants, weather, app usage, friend networks, wearable data, etc.), but there's no systematic way to know which data actually helps users. Engineers manually tune parameters, but this doesn't scale. The system is supposed to be "always self-improving" -- but currently it improves only by retraining model weights, not by evaluating whether its own inputs are valuable.

**Why bounded autonomy:** Three approaches were considered:
1. **Manual tuning** -- engineers adjust parameters based on intuition. Doesn't scale, slow iteration cycle, can't personalize.
2. **Full autonomy** -- the system changes anything to maximize happiness. Unsafe: could modify encryption settings, consent defaults, or privacy budgets.
3. **Bounded autonomy with transparency** -- chosen. The system experiments within human-set bounds, reports everything it does, and halts if things go wrong.

**Why the safety guardrails are non-negotiable:**
- **Global happiness floor (7.9E.1):** If system-wide happiness drops below 0.4, ALL experiments halt. This prevents cascading failures.
- **Per-experiment circuit breaker (7.9E.2):** Any experiment that drops canary happiness 15%+ is immediately aborted.
- **Consecutive failure limit (7.9E.3):** 3 failures in a row → 7-day pause + human notification. The system might be in an unstable state.
- **Per-user exemption (7.9E.4):** Users with happiness < 0.3 are excluded from all experiments -- they get the best-known configuration.
- **Privacy protection (7.9E.6):** Encryption, consent, DP epsilon, k-anonymity thresholds are NEVER autonomously optimizable.

**How this answers the knot_math question:** The `knot_math` Rust FFI produces 5-10D knot invariants for the state vector. Is this useful? Instead of engineers debating, the self-optimization engine registers knot invariants as an optimizable feature group, monitors its happiness correlation, and if it drops below threshold, runs a canary experiment zeroing knot weight. The data answers the question automatically.

**LeCun alignment:** This is the Configurator module from LeCun's framework, made autonomous. The configurator adjusts system modules based on empirically measured happiness outcomes, not just task/context heuristics.

---

## Pre-Flight Checklist for Phases That Depend on Phase 7

**Before starting Phase 8 (Ecosystem Intelligence):**
- [ ] Evolution cascade (7.1.2) executes atomically on personality changes
- [ ] Agent trigger system (7.4) fires on AI2AI connection events
- [ ] World model sync step wired into `BackupSyncCoordinator` (7.3.1)
- [ ] Device tier detection works and gates world model components

**Before starting Phase 10.6 (Deferred Codebase Reorganization):**
- [ ] Orchestrator restructuring (7.1) is complete -- moving orchestrator files after restructuring avoids double work
- [ ] Quantum code consolidation (10.6.2) waits for Phase 7 because quantum orchestrators are being rewired

---

## Common Pitfalls

1. **Updating one orchestrator without the others**: If `AIMasterOrchestrator` uses energy functions but `ContinuousLearningOrchestrator` still uses formulas, the system is in a split-brain state.
2. **Forgetting `_saveLearningState()` and `_saveOrchestrationState()`**: Both are currently TODO placeholders. Without persistence, state is lost on app restart.
3. **Breaking the tier fallback chain**: If Tier 2 inference fails, the system must automatically degrade to Tier 1 behavior. Don't assume the happy path.

---

## Why User Request Self-Healing (7.9F)

**The problem:** The self-optimization engine learns from behavioral signals, but sometimes users know exactly what they want: "fewer notifications," "more outdoor spots," "weekend events only." Ignoring explicit requests while tuning on implicit signals is backwards. Users have direct knowledge the system lacks.

**Why immediate per-user adjustment:** Parameter-tunable requests (notification frequency, exploration weight) can be applied instantly for that user. No need to wait for an experiment cycle -- the user asked for it. If it makes things worse, the feedback loop (7.9F.4) catches it within 7 days.

**Why classification engine:** Not all requests are parameter-tunable. Some require strategy changes (MPC planner behavior), others require code changes (new features). Classifying correctly means the right subsystem handles the request. Misclassification → wrong action → user frustration.

**Why outcome tracking:** Recording request outcomes feeds the self-optimization engine: the system learns which types of requests lead to happiness improvements, enabling preemptive adjustments before users even ask.

---

## Why Collective Request Aggregation (7.9G)

**The problem:** Individual request handling (7.9F) optimizes one user at a time. But when 50+ users independently ask for the same thing, that's a system-wide signal. Ignoring collective demand means missing improvements that would benefit everyone.

**Why threshold-triggered experiments:** Popularity isn't quality. 50 users wanting something doesn't mean it's good -- it means it's worth testing. The canary experiment validates whether the change actually improves happiness before rolling out.

**Why minority protection:** The majority shouldn't override the minority. If a change helps 90% but tanks a segment, the change goes per-segment (7.9C.6), not global. This is fairness baked into the optimization loop.

**Why admin feature request aggregation:** When users ask for things that require code changes, the demand data should reach the AVRAI creator automatically. No separate "feature request" website needed -- the system surfaces real demand with evidence.

---

### Why Life Pattern Intelligence (7.10)

**Problem:** The system only learns from the user when the app is open. If the user doesn't open the app for 2 weeks, the agent stops learning. App-open time captures maybe 10% of a user's day. The other 90% -- commute, gym, lunch spot, weekend routine, social outings -- is invisible.

**Solution:** A three-part system:
1. **Passive Engine (7.10A):** Background OS signals (significant location changes, widget refreshes) build a per-user routine model. The deviation classifier (noise/exploration/drift/life change) turns raw location streams into meaningful behavioral signals. The agent knows "it's Tuesday 12:30pm, you're probably at your usual lunch spot" even if the app hasn't been opened in a month.
2. **Privacy Architecture (7.10B):** Raw location data NEVER leaves the device. All data keyed to agent_id, not user_id. Off-device contributions coarsened from geohash-7 (~153m) to geohash-4 (~20km) with Laplace noise. Co-location matching uses BLE (primary) or encrypted hash comparison (fallback) -- never plaintext cross-referencing.
3. **Social Quality-of-Life Layer (7.10C):** Correlates co-location with happiness outcomes. Learns which friends make the user happier, which group compositions produce the best outcomes, and when social isolation is creeping in. Adds 3D to state encoder (routine adherence, deviation frequency, social co-location density).
4. **Notification Philosophy (7.10D):** Hard constraints: NEVER ask "where are you?", max 1 labeling question/week (immutable guardrail), exhaust all 5 inference channels before asking anything.

**Why not simpler alternatives:**
- "Just ask the user" -- Violates notification philosophy. Users don't want to report their location.
- "Cloud-based location tracking" -- Violates privacy architecture. Raw location data must stay on-device.
- "Only learn when app is open" -- Misses 90% of user's life. The system becomes stale during dormancy.
- "Skip the social layer" -- Misses the strongest predictor of happiness. WHO you're with matters more than WHERE you are.

**Pre-flight checklist for Phase 7.10:**
- [ ] `LocationPatternAnalyzer` exists and has `recordVisit()` method
- [ ] `AgentIdService` exists with encrypted agent_id ↔ user_id mapping
- [ ] `WidgetDataService` exists with `updateNearbySpotData()` method
- [ ] iOS `NearbySpotWidget.swift` has `TimelineProvider` with 15-min refresh
- [ ] `AgentHappinessService` exists for happiness delta measurement
- [ ] Phase 7.4 trigger system exists for new trigger types
- [ ] Phase 7.9E.0 immutable guardrail infrastructure exists for labeling rate limit

---

---

## Why DSL Self-Modification Engine (7.9H)

**Problem:** The self-optimization engine (7.9A-G) tunes parameters, and the admin platform (Phase 12) handles code changes. But there's a gap: changes that are more complex than parameter tuning but simpler than code changes. These represent ~80% of optimization opportunities: weight overrides for specific archetypes, conditional guardrail additions, notification timing rules, feature pipeline compositions, strategy switches.

**Solution (6 parts):**
1. **Strategy DSL grammar** (7.9H.1) -- Deliberately limited declarative language. Can express weights, rules, compositions, timing, and strategy switches. Cannot express loops, recursion, memory allocation, or system calls. Safe by construction.
2. **Sandboxed interpreter** (7.9H.2) -- On-device execution with no filesystem/network access. Budget: 10ms/rule, max 100 rules/user.
3. **Guardrail-validated compiler** (7.9H.3) -- Every rule checked against immutable guardrails before activation. Contradictions rejected.
4. **Strategy experiments** (7.9H.4) -- Self-optimization composes DSL strategies autonomously, tests them as canary experiments.
5. **OTA delivery** (7.9H.5) -- DSL rules delivered via model lifecycle infrastructure (Phase 7.7). Data, not code -- App Store compliant.
6. **Scope coverage** (7.9H.6) -- 80% of optimizations are DSL-expressible. Clear boundary: what DSL can change vs. what requires code.

**Alternatives considered:**
- **No DSL layer (only parameters + code):** Misses the ~80% middle ground. Most optimizations either wait for code review (slow) or are too complex for parameter tuning.
- **Full scripting language (Lua/JS):** Too powerful. Turing-complete languages can loop forever, access memory, and create security vulnerabilities. DSL safety comes from deliberate limitation.
- **Server-side rule evaluation:** Requires network. On-device evaluation is faster, works offline, and keeps user state private.

**Pre-flight checklist:**
- [ ] Phase 7.9E immutable guardrails must be finalized before compiler can validate against them.
- [ ] Phase 7.9C experiment orchestrator must support DSL experiments as a new experiment type.
- [ ] Phase 7.7 OTA infrastructure must handle DSL rule sets alongside model weights.
- [ ] `OptimizableParameter` registry must define bounds for all DSL-adjustable parameters.

---

## Why Meta-Learning Engine (7.9I)

**Problem:** The system learns from data but never reflects on how it learns. Every consolidation cycle uses the same frequency. Every experiment uses the same canary size (5%) and duration (14 days). Every federation round uses the same parameters. The system has no memory of which learning methods worked best in the past and can't adapt its learning strategy as the population evolves.

**Solution (4 layers):**
1. **Learning Cycle Ledger** (7.9I.1-2) -- Structured record of every learning event with causal parent references forming a DAG. The system can trace "why do I know X?" back to specific data points.
2. **Weekly meta-analysis** (7.9I.3) -- Analyze experiment effectiveness, signal quality rankings, consolidation efficiency, federation value, and learning velocity trends. Run during consolidation window.
3. **Learning process optimization** (7.9I.4-5) -- Propose hyperparameter adjustments within bounded ranges. Meta-experiments test learning methods against each other.
4. **Cross-hierarchy federation** (7.9I.9) -- Meta-insights federate through the universe model. New instances get meta-learning intelligence, not just model intelligence.

**7 immutable meta-guardrails:**
1. Bounded hyperparameter ranges (consolidation 1/week-2/day, canary 1%-10%, etc.)
2. All meta-changes canary-tested before full deployment
3. All meta-proposals visible in admin platform within 60 seconds
4. No modification of privacy, security, or data sovereignty
5. No modification of immutable guardrails (second-order immutability)
6. Learning velocity floor -- auto-revert if velocity drops below 50% baseline
7. Battery/performance budget -- max 20% of consolidation window

**Alternatives considered:**
- **No meta-learning (fixed hyperparameters):** Simple, but leaves optimization opportunities on the table. The system can't discover that its own learning is suboptimal.
- **Fully autonomous meta-learning (no bounds):** Dangerous. Unbounded self-modification of learning processes could spiral into overfitting, resource exhaustion, or "learning to game the happiness metric" instead of genuinely improving.
- **Human-only hyperparameter tuning:** Doesn't scale. With thousands of federation instances, each needing potentially different learning strategies, manual tuning is impossible.

**Pre-flight checklist:**
- [ ] Phase 1.1C consolidation window must have slack capacity for meta-analysis (~20% budget).
- [ ] Phase 7.9C experiment orchestrator must support meta-experiments as a new type.
- [ ] Phase 7.9E immutable guardrails must include meta-learning bounds.
- [ ] Phase 12.1.3 system monitor must have learning velocity dashboard module designed.
- [ ] `AIImprovementTrackingService` must be extended to support Learning Cycle Ledger entries.

---

## Why Self-Interrogation System (7.9J)

**Problem:** Convictions (Phase 1.1D) can calcify without challenge. The system stores high-certainty beliefs derived from episodic experience, but there is no mechanism to stress-test them. Over time, convictions become dogma — the system treats them as immutable truths rather than hypotheses worth revisiting. Unchallenged convictions lead to stale recommendations, blind spots in user modeling, and inability to recover from drift.

**Solution:** A structured self-questioning capability. The self-interrogation system periodically reviews convictions, compares them across scopes (user vs. segment vs. population), stress-tests them using the transition predictor (predictions that contradict convictions flag candidates for revision), and integrates human challenges (when a user corrects a belief, that feedback propagates). Without this, the system becomes dogmatic — it learns once and stops questioning. With it, the system maintains epistemic humility: every conviction remains open to evidence.

**Pre-flight checklist:**
- [ ] Phase 1.1D conviction memory must be available (self-interrogation reviews convictions)

---

## Why Agent Cognition & Continuity (7.11)

**Problem:** The current event-driven agent is reactive, not deliberative. It wakes on triggers (app open, location change, AI2AI connection), runs a few reasoning steps, and sleeps. There is no sustained thinking, no planning ahead, no reflection between activations. The agent responds to events but does not anticipate, prepare, or maintain coherent goals across sessions. It is a search engine, not a companion.

**Solution:** Phase 7.11 introduces persistent working memory (`AgentContext`), scheduled thinking sessions during device idle time, multi-horizon reasoning (hours / weeks / months), and the ability to self-schedule future wake-ups (e.g., "remind me to revisit this when the user returns from travel"). The thinking process itself feeds meta-learning — how the agent reasons, what it considers, and what it defers becomes training data for improving its own cognition. Without this, the agent stays reactive. With it, the agent gains continuity: it remembers what it was working on, plans ahead, and thinks even when the user is not actively engaging.

**Pre-flight checklist:**
- [ ] Phase 7.4 trigger system must support self-scheduled triggers (agent cognition injects wake events)
- [ ] Phase 7.9I meta-learning must accept thinking session logs as input

---

## Why Unified Observation & Introspection Service (7.12)

**Problem:** The system has 330+ services, 6 orchestrators, 21 controllers, and multiple ML components -- but no way to watch itself. Each component operates in isolation. If the energy function silently degrades (concept drift), the system keeps recommending poorly until a human notices. If the translation layer produces grounded but confusing text, nobody knows until users disengage. If two components contradict each other (MPC planner recommends exploration while notification system recommends familiar spots), the contradiction is invisible.

Without self-observation, the self-optimization engine (7.9) is blind. It can run experiments, but it can't detect WHAT needs experimenting on. It's like having a laboratory but no microscope.

**Solution:** A system-wide observation bus (Phase 7.12.1) where every component publishes lightweight diagnostic signals: `ObservationSignal { source_component, signal_type: (health | anomaly | opportunity | attribution | degradation), payload, timestamp }`. These signals are fire-and-forget (never block the primary pipeline, <1ms overhead per component) and ephemeral (sampled into periodic self-model snapshots, not individually persisted).

**Key components:**
1. **Observation Bus (7.12.1):** Typed event bus for inter-component diagnostics. Same infrastructure as agent triggers (Phase 7.4), but separate channel. Components publish health signals; interested components subscribe.
2. **Component Health Reporter Protocol (7.12.2):** Standardized interface every service implements: `publishHealth()` → latency, throughput, error rate, accuracy (if measurable), resource usage. The health reporter is intentionally lightweight -- it reports, it doesn't analyze.
3. **Self-Model Service (7.12.3):** Aggregates health signals into a compact system self-portrait: "what am I good at right now? what am I struggling with? what have I been ignoring?" Updated at consolidation intervals. This is the system's answer to "how am I doing?" -- not a dashboard for humans, but a data structure for the self-optimization engine to query.
4. **Attribution Tracing (7.12.4):** Backward traces from outcomes to component-level contributions. When a recommendation succeeds or fails, attribution tracing answers "which components contributed most to this outcome?" This feeds Phase 4.6 explainability and the self-optimization engine's feature importance tracking.
5. **Anomaly Detector (7.12.5):** Statistical monitoring for sudden accuracy drops, distribution shifts, latency spikes, and correlation changes. Fires `anomaly_detected` signals that route directly to the self-optimization engine (Phase 7.9) -- NOT through the agent trigger system (agent triggers are for user-facing events; observation bus signals are internal diagnostics).
6. **Opportunity Detector (7.12.6):** Complement to anomaly detection -- spots improvement opportunities rather than failures. "Component X has stable accuracy but high latency; a DSL rule could cache its output" or "Feature group Y has low correlation with outcomes; worth running a feature importance experiment."
7. **Cross-Feed Protocol (7.12.7):** Eyes → Ears (input quality metrics), Eyes → Mouth (delivery effectiveness), Eyes → Senses (sensor degradation), Eyes → Brain (self-model for strategy adjustment). The observation bus doesn't just watch -- it actively feeds corrective signals to all other senses.
8. **Observation Bus Federation (7.12.8):** Anonymized, aggregated observation summaries shared via federation (Phase 8.1). New instances learn "which components typically need attention" from collective experience.

**Why not alternatives:**
- "Let each component monitor itself" -- Components can detect their OWN issues, but not cross-component contradictions. The MPC planner doesn't know the translation layer is confusing users. Only a central observation bus sees the full picture.
- "Add logging and read the logs" -- Logs are for humans. The observation bus is for the system. Logs are unstructured text; observation signals are typed data structures that the self-optimization engine can programmatically query and act on.
- "Wait for user complaints" -- Too slow. By the time users complain, they've had bad experiences. The anomaly detector catches degradation within hours, not weeks.

**Relationship to the Sensory Architecture (Decision #51):**
The observation bus IS the "eyes" of the sensory architecture. It watches every junction between senses → ears → brain → mouth → senses. It's the internal nervous system that makes the universal self-healing doctrine (Decision #52) operational -- you can't heal what you can't see.

**Pre-flight checklist for Phase 7.12:**
- [ ] Phase 7.4 trigger system infrastructure exists (observation bus shares event bus infrastructure)
- [ ] Phase 7.9 self-optimization engine exists (anomaly/opportunity signals need a consumer)
- [ ] Phase 7.9I meta-learning engine exists (anomalies are logged as meta-learning input)
- [ ] Phase 4.6 explainability exists (attribution tracing extends feature attribution)

---

**Last Updated:** February 13, 2026 (v20 -- added Unified Observation & Introspection Service 7.12 rationale. Updated title to match Master Plan, duration 5-6→16-20 weeks, added Foundational Decisions #51/#52/#53 reference. Previous: v16 Self-Interrogation 7.9J and Agent Cognition 7.11. Previous: v15 Meta-Learning Engine 7.9I)
