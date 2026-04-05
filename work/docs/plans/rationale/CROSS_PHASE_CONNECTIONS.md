# Cross-Phase Connections

**Created:** February 10, 2026  
**Purpose:** Maps every data flow, dependency, and breaking change risk between phases. The Master Plan says what depends on what; this document explains why and what specifically flows between them.  
**Companion to:** `docs/MASTER_PLAN.md`, `docs/plans/rationale/FOUNDATIONAL_DECISIONS.md`

---

## How to Use This Document

When starting a phase, find that phase in the **Data Flow Map** below. Read:
1. **What this phase CONSUMES** (inputs from upstream phases)
2. **What this phase PRODUCES** (outputs consumed by downstream phases)
3. **Breaking change risks** (what changes here would break other phases)

### Why Cross-Phase Connections Matter: The Anti-Fragmentation Principle

This document exists because fragmented systems fail. Zeng et al. (arXiv:2602.01630, Feb 2026) demonstrate this across AI research: "current research landscape remains fragmented, with approaches predominantly focused on injecting world knowledge into isolated tasks... rather than establishing a unified definition or framework." Their failure cases show video generators that forget objects when the camera pans back, image editors that violate lighting physics, and 3D scenes that fragment at scale -- all because individual components were optimized independently without a unified framework connecting them.

AVRAI's Master Plan faces the same risk at a system design level. If Phase 3 (state encoder) changes its output format without Phase 4 (energy function) and Phase 5 (transition predictor) adapting, the system fragments. If Phase 4 replaces formulas without Phase 7 (orchestrators) wiring them in, the intelligence is built but unreachable. The cross-cutting contracts, breaking change risks, and data flow maps in this document are AVRAI's mechanism for preventing exactly the fragmentation that Zeng et al. identify as the primary failure mode in world model research.

**The Zeng principle applied to AVRAI:** A world model is not a loose collection of capabilities (or phases). It's a normative framework where interaction, reasoning, memory, and planning are integrally designed. This document maps that integral design.

---

## Data Flow Map

### Phase 1 → Everything

Phase 1 is the data foundation. Almost everything downstream consumes its outputs.

| Output | Format | Consumed By |
|--------|--------|-------------|
| Episodic tuples `(state, action, next_state, outcome)` | `EpisodicTuple` model in SQLite/Drift | Phase 4 (energy function training), Phase 5 (transition predictor training), Phase 6 (MPC planning quality) |
| **Markov transition tuples** `(agentId, engagementPhase_t, action, engagementPhase_t+1, timestamp)` | `MarkovTransitionStore` (SharedPreferences, per agentId) | Phase 5 (`TransitionPredictor` training — these ARE `(state, action, next_state)` tuples in macro-state space), Phase 7.3.3 (`FeatureFlagService` flip to `NeuralTransitionPredictor`) |
| **`EngagementPhasePredictor` interface** (abstract) | Dart abstract class in `services/prediction/` | Phase 5 (must be implemented by `NeuralTransitionPredictor`), Phase 7 (proactive outreach triggers, `PredictionAPIService` journey predictions) |
| **Swarm city-stratified priors** (NYC, Denver, Atlanta transition counts) | JSON asset bundled with app | Phase 1.5E (cold-start seed for `MarkovTransitionStore`), Phase 8 (federated cohort priors when real user data exists) |
| Outcome taxonomy (binary, quality, behavioral, temporal) | Enum/constants | Phase 4 (training labels), Phase 8 (federated outcome aggregation) |
| Signal strength hierarchy (10x explicit → 0.5x scroll-past) | Weight constants | Phase 4 (training sample weighting) |
| Semantic memory entries (compressed knowledge) | Vector embeddings + text in Drift | Phase 6 (MPC planner context), Phase 8.5 (agent insight exchange) |
| Procedural memory rules (if-then heuristics) | Rule model in Drift | Phase 6 (MPC candidate pruning) |
| Consolidation scheduler (nightly window) | `WorkManager`/`BGTaskScheduler` | Phase 5.2 (on-device training trigger), Phase 8.1 (gradient sync trigger) |
| `BaselineMetricsService` (generalized from CallingScore) | Service API | Phase 4 (formula vs energy function comparison baseline) |
| `FormulaABTestingService` | Service API | Phase 4 (parallel-run mode for every formula) |
| Cold-start state vectors (population priors, behavioral archetype) | `StateFeatureVector` with confidence | Phase 3 (state encoder input), Phase 6 (uncertainty-aware planning) |
| Pre-seeded model weights (Big Five OCEAN trained) | ONNX model file | Phase 4 (energy function starting weights), Phase 5 (transition predictor starting weights) |
| **Organic discovery candidates** (`DiscoveredSpotCandidate`) | JSON in GetStorage (per-user) | Phase 3 (location intelligence features), Phase 4 (discovery outcome training data), Phase 6 (MPC can suggest "save this place?"), Phase 8 (mesh signal sharing) |
| **Organic discovery learning events** (3 event types) | `ContinuousLearningSystem` events | Phase 4 (training signals), Phase 7 (personality evolution via `PersonalityLearning`) |
| **Negative outcome amplification weights** (asymmetric 2x, model failure 3x) | Weight multipliers in episodic tuple metadata | Phase 4.1.7 (asymmetric loss training), Phase 4.1.8 (self-monitoring accuracy) |
| **Dormancy prediction features** (interaction frequency trend, outcome rate trend) | Derived from episodic memory aggregates | Phase 5.1.11 (dormancy prediction), Phase 6.2.12-6.2.15 (re-engagement guardrails) |

**Breaking change risk:** If the episodic tuple schema changes (e.g., adding fields), all consumers must handle both old and new format tuples. Use schema migration, not replacement. Phase 7.7.3 (model-episodic compatibility gate) enforces this at the model level.

---

### Phase 2 → Privacy-Dependent Phases

| Output | Consumed By |
|--------|-------------|
| Consent infrastructure (opt-in per data type) | Phase 1 (outcome collection requires consent), Phase 8 (gradient sharing requires consent) |
| GDPR deletion API | Phase 1 (must delete episodic memory on account deletion), Phase 3 (must delete state snapshots) |
| Differential privacy (Laplace noise) | Phase 8.1 (gradient anonymization) |
| Privacy budget tracking (epsilon) | Phase 8 (cumulative epsilon cap per user) |
| Signal Protocol default activation | Phase 3.1.14 (trust features), Phase 6.6 (mesh-fallback chat), Phase 8 (AI2AI communication) |
| Post-quantum security | Phase 8 (BLE/gradient/cloud PQ protection) |
| Compliance (refund, tax, fraud) | Phase 9 (all business operations) |
| `SecretVaultService` (dynamic credential lifecycle) | Phase 6.3.5 (tool registry credentials), Phase 6.10 (action gateway credentials), Phase 10.9.26 (audit log service credentials), Phase 12.3.5 (external caller authentication) |
| `ContinuousVerificationService` (session re-validation) | Phase 6.10 (action gateway validates session before high-impact actions), Phase 10.9.29 (zero trust compliance dashboard) |
| Certificate pinning (HTTP client security) | All phases that make HTTP calls to Supabase or external APIs |

**Breaking change risk:** Changing the consent model (what's collected under which consent) requires re-consent from existing users. Design consent categories carefully in Phase 2.1.6. Changing `SecretVaultService` credential format requires migration of all services that consume credentials — use versioned credential envelopes.

---

### Phase 3 → Intelligence Phases

| Output | Consumed By |
|--------|-------------|
| `WorldModelFeatureExtractor` (145-155D state vector) | Phase 4 (energy function input), Phase 5 (transition predictor input), Phase 6 (MPC state) |
| State encoder ONNX (StateFeatureVector → 32-64D embedding) | Phase 4 (concat with action embed), Phase 5 (concat with action embed), Phase 6 (MPC state embed) |
| Action encoder ONNX (ActionType + EntityFeatures → 32-64D embedding) | Phase 4 (energy function input), Phase 5 (transition predictor input), Phase 6 (MPC action embed) |
| `FeatureFreshnessTracker` (per-feature staleness weights) | Phase 4 (energy function sees fresh vs stale features), Phase 5 (transition predictor adjusts for staleness) |
| List quantum states (`QuantumEntityType.list`) | Phase 4.4 (bidirectional list energy), Phase 5.1.8 (list state transitions), Phase 6 (list actions in MPC) |
| Unified mesh (`AnonymousCommunicationProtocol`) | Phase 8 (gradient sharing), Phase 6.6 (mesh-fallback chat) |
| Latency budgets | All downstream phases must respect budgets (50ms feature extraction, 20ms state encode, 10ms energy, 200ms full scoring) |
| Business/brand entity features (3.1.18-3.1.19) | Phase 4.4.8-4.4.12 (bidirectional business energy) |
| **`TransportBackend` interface** (3.7A.1) | Phase 7.10 (subsystems use `TransportOrchestrator`), Phase 8.2 (hybrid sync via capability-based transport selection), Phase 8.2A (capability service checks transport availability), Phase 12 (informs Rust kernel transport abstraction) |
| **`TransportRuntimeContext`** (3.7A.5) | Phase 7 (all restructured orchestrators accept context objects instead of parameter lists), Phase 7.10 (subsystems share context), Phase 10.9.12 (context carries state needed for break detection) |
| **`TransportOrchestrator`** (3.7A.6) | Phase 7.10 (subsystems delegate to it for all transport), Phase 8.1 (gradient sharing via capability-selected transport), Phase 8.2 (hybrid sync strategy implemented as capability rules) |

**Breaking change risk:** Changing the state vector dimensionality (adding/removing features) requires retraining ALL downstream ONNX models. Add features by extending the vector; never remove without retraining. Changing the `TransportBackend` interface (3.7A.1) after backends are implemented requires updating all backend implementations — use interface versioning (additive methods with defaults).

---

### Phase 4 → Planning and Integration Phases

| Output | Consumed By |
|--------|-------------|
| `EnergyFunctionService` (state + action → energy score) | Phase 6 (MPC planner uses energy to rank candidates), Phase 7 (controllers/orchestrators replace formulas) |
| Formula replacement feature flags | Phase 7 (controllers check flags before calling formula vs energy function) |
| Bidirectional energy (user + entity perspectives) | Phase 6 (MPC respects entity-side energy), Phase 8 (group negotiation evaluates both agents) |
| Business/brand state encoders | Phase 6 (MPC plans business-expert sequences), Phase 8 (business participation in ecosystem) |
| Explainability (feature attributions) | Phase 6.7 (SLM translates attributions to natural language), Phase 2.1.8A ("Why this recommendation?" transparency) |
| **Asymmetric loss training** (negative 2x, model failure 3x) | Phase 4.1.7 consumes Phase 1.4.10-1.4.11 amplification weights |
| **Energy function self-monitoring** (per-category accuracy) | Phase 6.2.10 (trigger exploration when accuracy drops), Phase 4.5.7 (happiness-weighted exploration) |
| **Agent happiness → energy function signal** | Phase 4.5.6 (delta-happiness as training reward from Phase 8.9) |

**Breaking change risk:** Changing the energy function's input format (embedding dimensions) breaks Phase 6 MPC and Phase 7 controllers. The state/action encoder output dimensions are a contract between Phase 3 and Phase 4.

---

### Phase 5 → Planning and Ecosystem Phases

| Output | Consumed By |
|--------|-------------|
| Transition predictor (state + action → next_state delta + variance) | Phase 6 (MPC simulates multi-step futures) |
| Variance head (uncertainty estimates) | Phase 6.2.9 (active exploration), Phase 6.2.10 (domain-specific uncertainty) |
| On-device training loop (gradient production) | Phase 8.1 (federated gradient sharing) |
| Taste drift detector (EMA of prediction residuals) | Phase 6 (re-enter exploration when drift detected), Phase 7 (trigger replanning) |
| Temporal embeddings (sinusoidal day/year cycles) | Phase 6 (MPC uses time context), Phase 8 (federated models learn temporal patterns) |
| **Dormancy prediction** (P(dormant) probability) | Phase 6.2.12 (re-engagement strategy selection), Phase 6.2.13-6.2.15 (re-engagement guardrails) |
| **Wearable temporal conditioning** (optional physiological features) | Phase 5.1.12 → Phase 6 (MPC uses physiological context), Phase 8 (federated models learn physiological patterns) |

**Breaking change risk:** If the transition predictor's output format changes (delta dimensionality, variance format), the MPC planner breaks. The output contract must be stable.

---

### Phase 3.10 (Prompt Injection Hardening) → All LLM Consumers

| Output | Consumed By |
|--------|-------------|
| `PromptSanitizationService` (input sanitization) | Phase 3 (`TupleExtractionEngine`), Phase 6 (`AICommandProcessor`), Phase 6.7 (SLM input), Phase 12.5 (plugin framework LLM calls) |
| Canary token detection (3.10.4) | Phase 6.10 (`AgentActionGateway` treats canary leak as critical security event), Phase 10.9.24 (SOC alerting) |
| Engine-layer input validation contracts (3.10.5) | Phase 10.9.27 (engine security boundaries enforce these contracts) |

**Breaking change risk:** `PromptSanitizationService` is additive — existing LLM call sites gain a sanitization step before the LLM invocation. If sanitization patterns are changed (e.g., relaxed), downstream security assumptions may be violated. Sanitization changes must be reviewed with the red-team matrix (10.9.20).

---

### Phase 6 → Integration and Ecosystem Phases

| Output | Consumed By |
|--------|-------------|
| MPC planner (recommendation sequences) | Phase 7 (wired into orchestrators/controllers), Phase 8 (group negotiation uses joint planning) |
| System 1 distilled model (fast inference) | Phase 7 (default inference path for 95% of recommendations) |
| Guardrail objectives (diversity, exploration, safety, doors) | Phase 7 (enforced in all recommendation paths) |
| Agent architecture (persistent memory, tool use) | Phase 8 (agents negotiate with each other) |
| SLM explanations | Phase 7 (user-facing "why this?" UI) |
| Offline confirmation (all inference on-device) | Phase 8 (offline AI2AI still works) |
| **Geographic DTN & Wormhole Routing (Phase 6.6)** | Phase 8 (AI2AI global sharing, locality agents across cities), Phase 4.4 (business pheromone spatial decay) |
| **DTN Spatial Decay `scentVibe` (Cultural Seed)** | Phase 6 (ContextEngine personal recommendations), Phase 8.2 (LocalityAgent foreign influence vector) |
| **`AgentActionGateway` (Phase 6.10)** | Phase 7 (all orchestrator-driven actions pass through gateway), Phase 10.9.25 (digital twins intervention controls connect to gateway kill switch), Phase 10.9.29 (zero trust dashboard shows gateway allow/deny/escalate rates) |
| **`ToolRegistryService` with signed manifests (Phase 6.3.5)** | Phase 8 (AI2AI tool invocation validates against registry), Phase 10.9.20 (red-team gate verifies tool registry integrity), Phase 12.5 (plugin framework tool calls use registered tools only) |

**Breaking change risk:** Changing the MPC planner's action taxonomy (adding/removing action types) affects the action encoder (Phase 3), the energy function training (Phase 4), and the transition predictor (Phase 5). Action types are a cross-cutting contract. Changing `AgentActionGateway` policy format requires updating all action policy definitions — use versioned policies.

---

### Phase 7 → Completion and Scaling

| Output | Consumed By |
|--------|-------------|
| Orchestrators wired to world model | Phase 8 (ecosystem intelligence assumes orchestrators work), Phase 10 (testing checkpoint validates) |
| Device tier system | Phase 8 (federated learning only on Tier 2+), Phase 11 (industry integrations use tier-aware features) |
| Agent trigger system | Phase 8 (AI2AI triggers), Phase 10 (background processing) |
| **Model lifecycle management** (OTA, versioning, staged rollout, rollback) | Phase 8 (federated model updates delivered via Phase 7.7.2), Phase 10 (testing checkpoint uses Phase 7.7.4 canary rollout) |
| **Multi-device reconciliation** (episodic merge, personality sync) | Phase 8 (federated learning works across linked devices), Phase 10 (user testing includes multi-device scenarios) |
| **`RuntimeSubsystem` interface** (7.10.1) | Phase 10.9.12 (break detection per subsystem), Phase 12 (subsystem boundaries become process boundaries in Rust kernel) |
| **`SubsystemOrchestrator`** (7.10.6) | Phase 10.9.12 (healing loop attaches to subsystem lifecycle events), Phase 10.9.1 (production readiness gate checks subsystem persistence), Phase 12 (promoted to kernel process manager) |
| **`RuntimeEvent` taxonomy** (7.10.1) | Phase 7.4 (agent trigger system emits and consumes runtime events), Phase 10.9.9 (causal observability logs event flows between subsystems) |

---

### Phase 8 → Scaling Phases

#### Phase 8.2A (Connection Capability Model) → Phase 8 Interactions

| Output | Consumed By |
|--------|-------------|
| `ConnectionCapabilityProfile` (per-peer permissions) | Phase 8.3 (energy-function-based connection value checks `canDo` before scoring), Phase 8.4 (expert discovery checks `expertiseDiscovery` capability), Phase 8.5 (insight exchange checks `learningInsightSharing`), Phase 8.6 (group negotiation checks `groupNegotiation`) |
| `ConnectionCapabilityService` | Phase 8.1 (gradient sharing checks `gradientSharing` capability + rate constraints), Phase 10.9.10 (adversarial hardening uses capability service to disable specific interaction types per peer) |
| Capability evolution data (trust changes over time) | Phase 4 (energy function can learn which capability configurations produce best outcomes), Phase 8.9 (locality-level capability statistics for advisory) |

**Breaking change risk:** `ConnectionCapability` enum is additive — new capabilities can be added without breaking existing profiles (unknown capabilities default to `denied`). Removing a capability from the enum breaks all profiles that reference it. Use deprecation flags, not removal.

| Output | Consumed By |
|--------|-------------|
| Federated global model (aggregated weights) | Phase 11 (industry integrations benefit from collective intelligence) |
| Agent insight exchange protocol | Phase 11 (experts share domain insights across industries) |
| Group negotiation | Phase 10.4 (user testing validates group features) |
| **Locality aggregate happiness** (per geohash, 0.0-1.0) | Phase 7.3.4 (admin monitoring heatmap), Phase 7.4 (advisory mode trigger), Phase 9.2.6 (third-party DP-protected insights), Phase 11.4 (quantum readiness -- advisory search maps to Grover's) |
| **Advisory transfer strategies** (from thriving to struggling localities) | Phase 6 (MPC planner biases toward advisory-suggested strategies), Phase 8.1.3 (federated aggregation server computes global advisory), Phase 9.2.6 (strategy effectiveness data for third-party insights) |
| **Advisory effectiveness data** (pre/post happiness tracking) | Phase 8.9C.4 (self-improving advisory matching), Phase 9.2.6 (what strategies work where -- market intelligence) |

**Breaking change risk:** Changing `LocalityAgentGlobalStateV1` (adding `aggregateHappiness`, `happinessSampleCount`, `happinessTrendSlope`) is additive -- existing consumers get default values (0.5, 0, 0). No breaking change. However, changing the advisory threshold (0.6) or the advisory query interface after deployment affects all localities simultaneously -- use feature flags.

---

## Critical Cross-Cutting Contracts

These are interfaces/formats that multiple phases depend on. Changing them has cascade effects.

| Contract | Defined In | Consumed By | Change Impact |
|----------|-----------|-------------|---------------|
| `StateFeatureVector` (145-155D) | Phase 3.1 | Phases 4, 5, 6, 7, 8 | Requires retraining all ONNX models |
| `EpisodicTuple` schema | Phase 1.1 | Phases 4, 5, 6, 8 | Schema migration for all consumers |
| Action type taxonomy (18 types) | Phase 3.3.1 | Phases 4, 5, 6, 7 | Retraining + encoder update |
| `QuantumEntityType` enum (7 types) | Phase 3.4.1 | All quantum/matching services | Every switch statement needs update |
| ONNX model input/output dimensions | Phases 3, 4, 5 | Phase 6 MPC, Phase 7 controllers | Contract-breaking requires retraining |
| Outcome taxonomy | Phase 1.2.12 | Phase 4 (training), Phase 8 (aggregation) | Retraining on new taxonomy categories |
| `AnonymousCommunicationProtocol` message types | Phase 3.7.2 | Phases 1.7 (organic discovery), 6.6, 8.1-8.7 | New message types are additive (safe); removing types breaks consumers |
| `ModelManifest` (version schema) | Phase 7.7.1 | Phase 7.7.2-7.7.8 (OTA, rollback, display), Phase 8.1.3 (federated model distribution) | Changing version format requires migration on all devices |
| Action type taxonomy (22 types, expanded from 18) | Phase 3.3.1 + Phase 6.2.12 | Phases 4, 5, 6, 7 | Re-engagement actions (novelty_injection, social_nudge, achievement_door, reduce_frequency) are additive |
| Third-party insight product catalog | Phase 9.2.6A | Phase 9.2.6B-G (DP noise, pipeline, consent, access), Phase 8.9C.5 (advisory data for insights) | Adding products is safe; removing requires buyer notification |
| `DiscoveredSpotCandidate` schema | Phase 1.7.1 | Phases 1.7 (service), 3 (features), 4 (training), 6 (MPC) | Schema changes require migration of per-user GetStorage data |
| `AgentCapabilityTier` enum | Phase 7.5 | All world model components | Must be backward compatible (new tiers OK, removing tiers breaks) |
| Signal Protocol trust API | Phase 2.4.6 | Phase 3.1.14 (state encoder feature) | API changes break feature extraction |
| `LocalityAgentGlobalStateV1` happiness fields | Phase 8.9A.2 | Phase 7.3.4 (admin), Phase 7.4 (triggers), Phase 8.9B (advisory engine), Phase 9.2.6 (third-party) | Additive (default 0.5). Changing threshold or advisory query format is a soft change (feature-flagged) |
| `LocalityAdvisoryResponseV1` schema | Phase 8.9B.3 | Phase 8.9B.4 (blending), Phase 8.9C (cross-region), Phase 9.2.6 (insights) | New schema with no legacy consumers. Future changes must be additive |
| `TransportBackend` interface | Phase 3.7A.1 | Phases 7.10 (subsystems), 8.1 (gradients), 8.2 (hybrid sync), 12 (kernel) | Additive methods with defaults are safe; removing methods breaks all backend implementations |
| `TransportCapability` enum | Phase 3.7A.1 | Phase 3.7A.2-4 (backends declare), 3.7A.6 (orchestrator selects), 8.2 (hybrid sync), 12 (kernel) | New capabilities are additive (safe); removing capabilities breaks transport selection logic |
| `RuntimeSubsystem` interface | Phase 7.10.1 | Phase 7.10.2-5 (subsystems), 7.10.6 (orchestrator), 10.9.12 (healing), 12 (kernel) | Interface changes require updating all subsystem implementations |
| `RuntimeEvent` taxonomy | Phase 7.10.1 | Phases 7.4 (triggers), 7.10.2-5 (subsystems emit/consume), 10.9.9 (observability) | New event types are additive; removing types breaks subscribers |
| `ConnectionCapabilityProfile` | Phase 8.2A.2 | Phases 8.1-8.6 (all AI2AI interactions check capabilities), 10.9.10 (adversarial hardening) | Profile schema changes require migration of per-peer stored profiles |
| `ConnectionCapability` enum | Phase 8.2A.1 | Phase 8.2A.2-6 (profiles, service, migration), all Phase 8 interaction types | New capabilities additive; removal breaks stored profiles |
| `SecretVaultService` credential format | Phase 2.7.1 | Phases 6.3.5 (tool registry), 6.10 (action gateway), 10.9.26 (audit log), 12.3.5 (external auth) | Credential format changes require migration of all consumers; use versioned credential envelopes |
| `PromptSanitizationService` patterns | Phase 3.10.1 | Phases 3 (TupleExtractionEngine), 6 (AICommandProcessor), 6.7 (SLM), 12.5 (plugins) | Relaxing patterns weakens security for all consumers; changes require red-team review (10.9.20) |
| `AgentActionGateway` policy format | Phase 6.10.2 | Phases 7 (orchestrators), 10.9.25 (digital twins), 10.9.29 (compliance dashboard) | Policy format changes require updating all policy definitions; use versioned policies |
| `ToolRegistryService` manifest schema | Phase 6.3.5 | Phases 6 (agent tool use), 8 (AI2AI tool invocation), 12.5 (plugin framework) | Manifest schema changes require re-signing all tool manifests; additive fields are safe |

---

## Parallel Execution Safety

### Safe Parallelism
These phase pairs can safely run simultaneously:
- **Phase 1 + Phase 2**: No shared code, no shared data structures, different concerns
- **Phase 3 + Phase 4**: Phase 4 needs Phase 1 data, not Phase 3 outputs (it can use raw features initially, then switch to encoded features)
- **Phase 3.7A (transport interface) + Phase 3.7 (mesh unification)**: Complementary — 3.7 unifies protocol, 3.7A unifies transport. No conflicting file changes.
- **Phase 9 + Phases 1-8**: Business features use existing formulas; world model upgrade is additive
- **Phase 10.5 (immediate reorg) + Phases 1-2**: Reorganization moves files; intelligence work creates new files in the reorganized structure

### Dangerous Parallelism (Avoid)
- **Phase 3 state encoder + Phase 5 transition predictor**: Phase 5 consumes Phase 3's output. If Phase 3 changes the state encoder mid-development, Phase 5 targets a moving interface.
- **Phase 7 orchestrator restructuring + Phase 10.6 AI/ML consolidation**: Both modify overlapping files in `lib/core/ai/`.
- **Phase 4 formula replacement + Phase 7 controller updates**: Phase 7 wires energy functions into controllers. If the energy function API changes during Phase 4, Phase 7 breaks.
- **Phase 7.10 (subsystem isolation) + Phase 7.1 (orchestrator updates)**: Both modify `VibeConnectionOrchestrator` and related orchestrators. Subsystem extraction must complete or stabilize before world model integration rewires the orchestrators. **Recommended sequence:** 3.7A (transport interface) → 7.10.1-7.10.5 (extract subsystems) → 7.1 (integrate world model into subsystems).

### Resolution Pattern
When parallel work touches the same interface, use **contract-first development**:
1. Define the interface/schema/model first (both teams agree)
2. Both phases develop against the contract
3. Integration happens after both sides are stable
4. Feature flags gate the integration point

---

## The Chain Reaction: What Happens When Key Components Change

### Scenario: State vector gains new features
1. Phase 3: `WorldModelFeatureExtractor` adds 5D from a new service
2. Phase 3: State encoder ONNX must be retrained (input dimension changed)
3. Phase 4: Energy function ONNX must be retrained (concat dimension changed)
4. Phase 5: Transition predictor ONNX must be retrained (state dimension changed)
5. Phase 6: MPC planner automatically benefits (no code change, just new model weights)
6. **Total impact**: 3 model retrains, 0 code changes (if ONNX input is properly abstracted)

### Scenario: New action type added to taxonomy
1. Phase 3: Action encoder ONNX must be retrained (new action type)
2. Phase 4: Energy function may need retraining (if it uses action type features)
3. Phase 5: Transition predictor must learn the new action's state transitions
4. Phase 6: MPC planner must include the new action in candidate generation
5. **Total impact**: 3 model retrains, 1 code change (MPC candidate generation)

### Scenario: Organic discovery candidate schema changes
1. Phase 1.7: `DiscoveredSpotCandidate` gains new fields (e.g., inferred vibe vector)
2. Phase 1.7: `OrganicSpotDiscoveryService` storage migration needed for existing candidates
3. Phase 3: Feature extractor must handle old candidates (no new field) and new candidates (with field)
4. Phase 8: Mesh signal format may need update if new fields affect sharing
5. **Resolution**: Schema migration in GetStorage -- old candidates get default values for new fields. Mesh signal format is independently versioned (additive only).

### Scenario: Locality happiness threshold changes
1. Phase 8.9B.1: Threshold changes from 0.6 to 0.5 (more localities enter advisory mode)
2. Phase 8.9B.2: More advisory queries hit Supabase (increased load)
3. Phase 8.9B.6: Rate limiting becomes more important (more localities querying)
4. Phase 8.9C.4: Advisory effectiveness tracking sees more data points (larger evaluation dataset)
5. Phase 7.4: More advisory triggers fire (agent trigger frequency increases)
6. **Resolution**: Threshold is behind `FeatureFlagService` -- can be adjusted per-deployment without code change. Rate limiting (8.9B.6) absorbs the load increase.

### Scenario: Episodic tuple schema changes
1. Phase 1: New field added to `EpisodicTuple`
2. Phase 4: Training pipeline must handle old tuples (no new field) and new tuples (with field)
3. Phase 5: Same as Phase 4
4. **Resolution**: Schema migration -- old tuples get default values for new fields

### Scenario: New transport added (e.g., DTN wormhole)
1. Phase 3.7A: New `DtnWormholeTransportBackend` implements `TransportBackend` interface, declares capabilities `{delayTolerant, storeAndForward, geographicRouting}`
2. Phase 3.7A.6: `TransportOrchestrator` automatically includes new backend in capability-based routing — zero code changes to orchestrator
3. Phase 7.10: Subsystems continue working unchanged — they talk to `TransportOrchestrator`, not individual backends
4. Phase 8.2: Hybrid sync strategy gains a new delivery option for delay-tolerant gradient sharing without any rule changes
5. **Total impact**: 1 new class (the backend implementation), 1 DI registration. No changes to orchestrator, subsystems, or downstream consumers.

### Scenario: Prompt injection bypasses sanitization
1. Phase 3.10: Attacker crafts input that bypasses `PromptSanitizationService` pattern matching
2. Phase 3 (`TupleExtractionEngine`): Injected prompt causes LLM to produce malicious semantic tuples
3. Phase 1.1: Malicious tuples enter episodic memory as training data
4. Phase 4: Energy function trains on poisoned data, producing biased scores
5. Phase 6.10: `AgentActionGateway` anomaly detector (6.10.4) flags unusual action patterns from biased scoring
6. Phase 10.9.10: Kill switch disables the affected learning pathway
7. **Resolution**: Defense-in-depth — sanitization (3.10) is the first line, the Air Gap (raw data destruction) limits payload size, the action gateway (6.10) catches anomalous downstream effects, and the kill switch (10.9.10) halts the pathway. All layers must be present; no single layer is sufficient alone.

### Scenario: Subsystem crashes (e.g., DiscoverySubsystem fails)
1. Phase 7.10.6: `SubsystemOrchestrator` detects failure in `DiscoverySubsystem` event stream
2. Phase 10.9.12: Healing loop creates healing cycle entry with failure signature and subsystem identity
3. Phase 7.10.6: Orchestrator restarts `DiscoverySubsystem` — other subsystems (`ConnectionSubsystem`, `LearningInsightSubsystem`) continue functioning for existing connections
4. Phase 10.9.9: Causal observability logs the full event flow: failure → detection → healing → restart → recovery verification
5. **Total impact**: Brief discovery interruption. No impact on existing connections, ongoing learning, or mesh forwarding. Self-healing loop learns from the break.

---

---

### Phase 3.9 (Affective State Inference) → Downstream Phases

Affective state (VAD — Valence, Arousal, Dominance) is a derived output of the state encoder. It is computed from behavioral signals already flowing through Phase 3.1 and adds 3D to the state vector.

| Output | Consumed By |
|--------|-------------|
| VAD vector (3D affective state) | Phase 4.1 (energy penalty for high-effort doors when valence low), Phase 6.1 (planner avoids cognitively demanding recommendations when arousal depleted), Phase 6.7 (SLM tonal calibration), Phase 12.5 (AffectiveStateService for behavioral health plugins) |
| `AffectiveStateService.getCurrentVAD()` | Phase 12.5.7 (plugin framework outbound context) |

**Breaking change risk:** Affective state dimensions are additive to `StateFeatureVector` (3 new dimensions). Energy function and transition predictor require retraining when VAD is added. The retraining is captured by the standard chain reaction for state vector changes (see above).

---

### Phase 6.8 (Intrinsic Curiosity) + Phase 6.9 (Memory-Augmented) → Planner

| Output | Consumed By |
|--------|-------------|
| ICM prediction error per episode | Phase 6.1 (curiosity bonus additive to MPC energy), Phase 8.10.1 (FAL uses ICM error as information score) |
| `PlannerMemoryBank` retrieval results | Phase 6.1 (additive bias in energy scoring), Phase 5.1 (fallback for uncertain predictions) |

**Breaking change risk:** ICM is additive to the energy calculation. The `curiosity_bonus` is bounded at 30% of base energy (6.8.7 guardrail). Memory bank retrieval is additive bias — removing it doesn't break planning, only reduces quality. Neither introduces a required contract dependency.

---

### Phase 8.10 (Federated Active Learning) → Global Model Quality

| Output | Consumed By |
|--------|-------------|
| Information score per device per round | Phase 8.1.3 (server uses to select top-K devices for training round) |
| Convergence acceleration metrics | Phase 7.3 (admin monitoring), Phase 8.1.3 (aggregation quality tracking) |

**Breaking change risk:** FAL is layered on top of Phase 8.1 federated learning. If Phase 8.1's round structure changes (e.g., round frequency), the information score timing must be updated. The minimum participation floor (8.10.5) is a safety net — devices never permanently exit training.

---

### Phase 11.5-11.7 (Causal AI, Continual Learning, Neuro-Symbolic) → Phase 4/6/7

These are research tracks. They do not introduce required dependencies — they are additive improvements to existing systems.

| Output | Consumed By |
|--------|-------------|
| Causal SCM (Phase 11.5) | Phase 6.1 (intervention-aware recommendations for high-stakes doors) |
| EWC continual learning (Phase 11.6) | Phase 4/5 ONNX training pipeline (prevents forgetting during model updates) |
| Symbolic constraint layer (Phase 11.7) | Phase 6.1 candidate filter (hard constraint enforcement), Phase 6.2 (replaces ad-hoc guardrails with formal verification) |
| Symbolic trace (Phase 11.7.4) | Phase 4.6 (explainability audit), Phase 6.7 (SLM explanation enrichment) |

**Breaking change risk:** All three are layered on existing systems. Symbolic constraints (11.7.2) wrap the MPC planner's candidate generation — if the action taxonomy changes (Phase 3.3), the symbolic ontology predicates (11.7.1) must be updated. This is the only forward dependency.

---

### Phase 2.6 (Air Gap Permeability) → All Data Ingestion Points

| Output | Consumed By |
|--------|-------------|
| `AirGapPermeabilityService` state | Phase 12.5.10 (plugin inbound data pipeline — checks permeability before accepting payloads), Phase 12.8.6 (physical identity permeability), Phase 2.1.1 (GDPR deletion shows "no data stored" for solid domains) |
| Permeability audit log | Phase 2.1.8 ("What My AI Knows" page — shows blocked signals) |

**Breaking change risk:** `AirGapPermeabilityService` is a new gating layer on `TupleExtractionEngine`. Existing inbound pipelines (7.3.5 macro-news crawler) that call the Air Gap must be updated to check permeability before pushing payloads. Adding the permeability check is a non-breaking additive change — existing callers get the default gas state.

---

### Phase 12.8 (Physical-to-Digital Matching) → Phase 8.2

| Output | Consumed By |
|--------|-------------|
| Biometric embedding (128D, on-device only) | Phase 8.2 (AI2AI proximity matching uses commitment scheme over embedding hashes) |
| Physical presence signal (Air Gap output) | Phase 1.1 (episodic co-presence events), Phase 8.2 (behavioral co-presence in AI2AI mesh) |

**Breaking change risk:** Physical matching is entirely opt-in and late-stage (Phase 12.8). It consumes Phase 8.2 AI2AI proximity — changes to AI2AI proximity discovery protocol (Phase 8.2) must remain compatible with the commitment scheme matching (12.8.3). The commitment scheme is an additional layer on top of existing proximity discovery, not a replacement.

---

### Phase 12 (AVRAI OS) ← Phases 1-8, Beta, v0.3 Swarm

Phase 12 is the platform tier — it converts the product into infrastructure. Everything from Phases 1-8 flows INTO Phase 12 as the substrate it operates over.

| What Phase 12 CONSUMES | Source | Notes |
|------------------------|--------|-------|
| Episodic memory store and schema | Phase 1.1 | Kernel takes ownership of memory management |
| Energy function ONNX model | Phase 4.1 | Core of the Reality Model API and cognitive syscall `plan` |
| Transition predictor ONNX model | Phase 5.1 | Powers `perceive` and `plan` syscalls |
| MPC planner | Phase 6.1 | Powers Action Grounding API action sequencing |
| ICM curiosity model | Phase 6.8 | Informs active learning selection (8.10), exposed via Inference Routing API |
| Memory bank | Phase 6.9 | Powers memory-augmented context in `perceive` syscall output |
| Affective state service | Phase 3.9 | Exposed via Plugin Framework outbound context API |
| Air Gap permeability service | Phase 2.6 | Plugin Framework enforces permeability before accepting plugin payloads |
| Federated active learning | Phase 8.10 | Kernel's information score drives which rounds contribute to global model |
| AI2AI anonymous communication + trust network | Phase 8.1-8.2 | Promoted from runtime service to kernel-owned IPC table |
| Signal Protocol session state | Phase 2.x | Kernel owns session lifecycle across process boundaries |
| Battery-adaptive scheduler | Phase 7.5 | Kernel's cognitive resource scheduler; applies to external API calls too |
| Swarm simulation baseline model weights | v0.3 Sprint | Phase 12.4 fine-tunes from this baseline |
| Beta behavioral data | Beta | Fine-tunes baseline model weights; informs syscall API design |
| Federated gradient sync | Phase 8.1 | External API read-only; real training data comes only from OS observation pipeline |

| What Phase 12 PRODUCES | Consumed By |
|------------------------|-------------|
| Stable cognitive syscall API (v1) | All external integrators, third-party app developers, AI companies |
| Context Enrichment API | OpenAI, Anthropic, Perplexity, healthcare apps, EdTech |
| Reality Model API | AI companies wanting local ground truth; civic / urban planning use cases |
| Action Grounding API | AI companies wanting recommendation → real-world outcome |
| Inference Routing API | AI companies, developers wanting on-device vs. cloud routing |
| Local App Plugin Framework | IoT/smart home apps, wearables, health apps, calendar apps on same device |
| SDK packages (pub.dev, Maven, SPM, crates.io, PyPI, gRPC, npm) | External developer ecosystem |
| Docker OCI container | Enterprise, cloud, CI/CD deployments |
| Open-source community edition | Developer ecosystem, researchers, civic use |
| Cognitive permission model | Third-party app consent infrastructure |
| Revenue stream (per-API-call commercial pricing) | Phase 9 monetization model extends to OS revenue |
| Physical-to-digital matching (12.8, opt-in) | Users who choose physical proximity discovery |

**Breaking change risk — Phase 12 is a consumer of all upstream, never a producer that upstream depends on.** This is by design: Phase 12 is a post-production tier. Changes to Phase 12 cannot break Phases 1-11. Changes to Phases 1-11 (e.g., state vector dimensions change in Phase 3) require model retraining in Phase 12.4 but not architectural changes.

**Critical contract: external callers cannot train the reality model.** External API calls are read-only from the training pipeline's perspective. This is the fundamental distinction between a platform (AVRAI OS) and a data marketplace. The only things that train the world model are real behavioral outcomes observed through the OS's own observation pipeline (`observe` syscall). This rule is enforced at the permission model level and is not overridable by any external caller regardless of commercial relationship.

**Chain reaction: if energy function architecture changes (Phase 4)**
1. Reality Model API response schema may change (new feature dimensions available)
2. Phase 12.4 baseline must be regenerated with new model
3. External integrators on the Reality Model API must be notified via API versioning (additive change → same major version; breaking change → new major version with migration path)
4. **Resolution**: Energy function changes are additive within a ONNX version. If output schema changes, Phase 12.3.7 (API versioning contract) handles migration.

**Chain reaction: if AI2AI protocol changes (Phase 8)**
1. Kernel IPC table (12.1.4) must be updated to new protocol version
2. Action Grounding API (12.5.3) may change behavior (if social connection path changes)
3. **Resolution**: AI2AI protocol is independently versioned. Kernel accepts both current and next-version protocol during overlap windows (same rule as in Phase 8).

---

## Phase Execution Order Visualization

```
Tier 0 (Blocks Everything):
  Phase 1 ─────────────┐
  Phase 2 ──────────────┤ (parallel)
                        │
Tier 1 (Core Intelligence):
  Phase 3 ──────────────┤ (needs 1, 2)
  Phase 4 ──────────────┤ (needs 1)
  Phase 5 ──────────────┤ (needs 1, 3)
                        │
Tier 2 (Advanced Intelligence):
  Phase 6 ──────────────┤ (needs 4, 5)
  Phase 7 ──────────────┤ (needs 4 minimum)
                        │
Tier 3 (Scaling):
  Phase 8 ──────────────┤ (needs 5, 6)
  Phase 11 ─────────────┘ (needs 8, 9)

Parallel (Any Tier):
  Phase 9 ──────── (needs 2)
  Phase 10.3 ───── (i18n, parallel with any, start after UI stabilizes)
  Phase 10.4 ───── (a11y, parallel with any, start after UI stabilizes)
  Phase 10.7 ───── (immediate codebase reorg, parallel with 1-2)
  Phase 10.1-10.2  (parallel with any)
  Phase 10.8 ───── (deferred: after 4 for AI/ML, after 7 for quantum)

Research Tracks (After Phases 1-11 stable):
  Phase 11.5 Causal AI ──── (needs 12+ months real data)
  Phase 11.6 Continual Learning ── (needs production ONNX models stable)
  Phase 11.7 Neuro-Symbolic ── (needs full feature set from Phases 1-10)

Post-Production (After Beta):
  Phase 12 ──────── (needs Phases 1-8 complete + beta PMF validation)
    12.1 Kernel → 12.2 Adapters → 12.3 API + 2.6 Air Gap → 12.4 Baseline → 12.5 External API + Plugin Framework → 12.6 Headless → 12.7 SDK + 12.8 Face Matching (gated)
```

---

**Last Updated:** March 5, 2026 (added zero trust cross-phase connections: Phase 2.7 `SecretVaultService`, Phase 2.8 `ContinuousVerificationService`, Phase 3.10 `PromptSanitizationService`, Phase 6.10 `AgentActionGateway`, Phase 6.3.5 `ToolRegistryService`. Added 4 zero trust contracts to critical contracts table. Added prompt injection chain reaction scenario. Previous: 1.5 transport/subsystem/capability)  
**Version:** 1.6 (added zero trust infrastructure cross-phase connections. Previous: 1.5)
