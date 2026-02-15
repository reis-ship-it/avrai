# Cross-Phase Connections

**Created:** February 10, 2026  
**Purpose:** Maps every data flow, dependency, and breaking change risk between phases. The Master Plan says what depends on what; this document explains why and what specifically flows between them.  
**Companion to:** `docs/MASTER_PLAN.md`, `docs/plans/rationale/FOUNDATIONAL_DECISIONS.md`, `docs/plans/architecture/REALITY_COHERENCE_TEST_MATRIX.md`

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

**Breaking change risk:** Changing the consent model (what's collected under which consent) requires re-consent from existing users. Design consent categories carefully in Phase 2.1.6.

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

**Breaking change risk:** Changing the state vector dimensionality (adding/removing features) requires retraining ALL downstream ONNX models. Add features by extending the vector; never remove without retraining.

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

### Phase 6 → Integration and Ecosystem Phases

| Output | Consumed By |
|--------|-------------|
| MPC planner (recommendation sequences) | Phase 7 (wired into orchestrators/controllers), Phase 8 (group negotiation uses joint planning) |
| System 1 distilled model (fast inference) | Phase 7 (default inference path for 95% of recommendations) |
| Guardrail objectives (diversity, exploration, safety, doors) | Phase 7 (enforced in all recommendation paths) |
| Agent architecture (persistent memory, tool use) | Phase 8 (agents negotiate with each other) |
| SLM explanations | Phase 7 (user-facing "why this?" UI) |
| Offline confirmation (all inference on-device) | Phase 8 (offline AI2AI still works) |

**Breaking change risk:** Changing the MPC planner's action taxonomy (adding/removing action types) affects the action encoder (Phase 3), the energy function training (Phase 4), and the transition predictor (Phase 5). Action types are a cross-cutting contract.

---

### Phase 7 → Completion and Scaling

| Output | Consumed By |
|--------|-------------|
| Orchestrators wired to world model | Phase 8 (ecosystem intelligence assumes orchestrators work), Phase 10 (testing checkpoint validates) |
| Device tier system | Phase 8 (federated learning only on Tier 2+), Phase 11 (industry integrations use tier-aware features) |
| Agent trigger system | Phase 8 (AI2AI triggers), Phase 10 (background processing) |
| **Model lifecycle management** (OTA, versioning, staged rollout, rollback) | Phase 8 (federated model updates delivered via Phase 7.7.2), Phase 10 (testing checkpoint uses Phase 7.7.4 canary rollout) |
| **Multi-device reconciliation** (episodic merge, personality sync) | Phase 8 (federated learning works across linked devices), Phase 10 (user testing includes multi-device scenarios) |

---

### Phase 8 → Scaling Phases

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

---

## Parallel Execution Safety

### Safe Parallelism
These phase pairs can safely run simultaneously:
- **Phase 1 + Phase 2**: No shared code, no shared data structures, different concerns
- **Phase 3 + Phase 4**: Phase 4 needs Phase 1 data, not Phase 3 outputs (it can use raw features initially, then switch to encoded features)
- **Phase 9 + Phases 1-8**: Business features use existing formulas; world model upgrade is additive
- **Phase 10.5 (immediate reorg) + Phases 1-2**: Reorganization moves files; intelligence work creates new files in the reorganized structure

### Dangerous Parallelism (Avoid)
- **Phase 3 state encoder + Phase 5 transition predictor**: Phase 5 consumes Phase 3's output. If Phase 3 changes the state encoder mid-development, Phase 5 targets a moving interface.
- **Phase 7 orchestrator restructuring + Phase 10.6 AI/ML consolidation**: Both modify overlapping files in `lib/core/ai/`.
- **Phase 4 formula replacement + Phase 7 controller updates**: Phase 7 wires energy functions into controllers. If the energy function API changes during Phase 4, Phase 7 breaks.

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
```

---

### Self-Optimization Engine Outputs (Phase 7.9 → All Phases)

**What 7.9 produces:**
- `OptimizableParameter` registry with per-parameter happiness correlation
- `SelfOptimizationExperimentService` that runs canary experiments on any registered parameter
- Feature importance-to-happiness R² scores per feature group
- Monthly self-optimization reports and experiment audit trail
- Proposal pipeline for non-reversible changes

**Who consumes it:**
- **Phase 3.1 (Feature Extraction):** Feature group weights are optimizable parameters. The engine validates whether weather features (3.1.20A), app usage (3.1.20B), friend network (3.1.20C), knot invariants (3.1.2), etc. actually help happiness. Low-value feature groups get weight reduced; potentially valuable new sources get canary-tested.
- **Phase 4.1 (Energy Function):** Asymmetric loss weights (4.1.7), self-monitoring thresholds (4.1.8), and energy function hyperparameters are registered for autonomous tuning.
- **Phase 6.2 (Guardrails):** Exploration/exploitation ratios, notification frequency limits, re-engagement strategy weights, and all guardrail thresholds are optimizable within human-set bounds.
- **Phase 8.9 (Locality Happiness):** Advisory happiness threshold (8.9B.1, default 0.6) and strategy recommendation weights are tunable by the engine based on cross-region happiness outcomes.
- **All phases:** Any numeric parameter registered with `FeatureFlagService` becomes a candidate for self-optimization.

**Breaking change risk:** LOW. Self-optimization only adjusts values within human-set bounds. All changes are reversible within 60 seconds. Circuit breakers halt experimentation if happiness drops.

**Contract:** `OptimizableParameter` model, `SelfOptimizationExperimentService` API, experiment notification format.

---

### Friend System Lifecycle Outputs (Phase 10.4A → Multiple Phases)

**What 10.4A produces:**
- `FriendshipStatus` state machine (none → pending → accepted → removed/blocked)
- Friend tiering (close/regular/acquaintance) with weighted social signals
- Periodically re-woven braided knots (evolving, not static)
- Friend-in-community awareness
- "Invite friend to community" flow

**Who consumes it:**
- **Phase 1.2 (Outcome Data):** Friendship lifecycle tuples (1.2.27-1.2.29) feed episodic memory: request, acceptance, co-activity, unfriending, "met through" attribution.
- **Phase 3.1 (Feature Extraction):** Friend network features (3.1.20C: friend count, activity overlap, braided knot compatibility, friend-driven activity rate) enter the state vector.
- **Phase 4.4 (Community Energy):** Community-perspective energy considers friend membership (10.4A.6) -- communities where friends are members get energy boost.
- **Phase 6.2 (Guardrails):** "Your friend joined this club" social nudge (10.4A.9) is a new re-engagement strategy.
- **Phase 7.1 (Evolution Cascade):** Braided knot re-weaving triggers on personality evolution events.

**Breaking change risk:** MEDIUM. Unfriending cascades data deletion (braided knots, social signals, AI2AI exchanges). Must coordinate with GDPR compliance (Phase 2.1).

**Contract:** `FriendshipStatus` enum, `FriendTier` enum, `BraidedKnot` evolution API, friend-in-community query API.

---

### Data Visibility Pipeline Outputs (Phases 3.1.20A-D, 10.4B-E → Multiple Phases)

**What these produce:**
- Weather, app usage, friend network, cross-app features wired into state vector (3.1.20A-D)
- Real trending data from locality agents (10.4B)
- Creator/business analytics dashboards (10.4C)
- Decision audit trail with full recommendation replay (10.4D)
- GDPR data export specification and pipeline (10.4E)
- AI learning trajectory visualization (2.1.8D)

**Who consumes it:**
- **Phase 3.2 (State Encoder):** 4 new feature groups (11D total) enter the state encoder input. State encoder architecture updated from 145-155D to 156-166D.
- **Phase 9.2.6 (Third-Party Pipeline):** Trending data is a new data product in the insight catalog (10.4B.3).
- **Phase 6.2 (Guardrails):** Trending entities preferred for novelty injection (10.4B.4).
- **Phase 7.9 (Self-Optimization):** All new feature groups are registered as optimizable parameters for autonomous validation.
- **Phase 2.1 (GDPR):** Export specification (10.4E) fulfills the requirement from 2.1.2. Shared data handling respects both user's and friends' privacy.

**Breaking change risk:** LOW. New features are additive (default weight 0.0 until validated by self-optimization engine or manually enabled).

**Contract:** `StateFeatureVector` extended fields, `DecisionAuditRecord` model, `GDPRExportSchema`, trending query API.

---

### BLE Payload Budget Outputs (Phase 6.6.6-6.6.7 → Multiple Phases)

**What 6.6.6-6.6.7 produce:**
- Versioned BLE advertisement payload schema with byte budgets per feature type
- Multiplexing strategy (rotation across advertisement intervals)
- Priority ordering under contention

**Who consumes it:**
- **Phase 1.7 (Organic Spot Discovery):** Discovery signals must fit within allocated BLE bytes.
- **Phase 8.9 (Locality Agent):** Locality agent updates must fit within allocated BLE bytes.
- **Phase 2.5 (Post-Quantum):** PQ adds overhead to BLE payloads; budget must account for larger encrypted headers.
- **Phase 7.9 (Self-Optimization):** Priority ordering is an optimizable parameter -- the engine can experiment with different orderings to maximize happiness.

**Breaking change risk:** MEDIUM. Any existing BLE feature that currently uses the full advertisement payload will need to be reformatted to fit within its allocated budget. Version header enables forward compatibility.

**Contract:** `BLEPayloadSchema` (versioned), `BLEPayloadPriority` enum, multiplexing configuration.

---

## Execution Dependency Tree

| Phase | Depends On | Reason |
|-------|-----------|--------|
| Phase 7.9 (Self-Optimization Engine) | Phase 7.7 (staged rollout pattern) | Self-optimization uses canary rollout infrastructure for parameter experiments |
| Phase 7.9 (Self-Optimization Engine) | Phase 4.6.1 (feature attribution) | Feature importance-to-happiness R² scores require attribution infrastructure |
| Phase 7.9 (Self-Optimization Engine) | Phase 4.1.8 (self-monitoring) | Self-optimization monitors happiness impact via self-monitoring service |
| Phase 10.4A (Friend System Lifecycle) | Phase 1.2 (outcome data) | Friendship lifecycle tuples feed episodic memory |
| Phase 10.4A (Friend System Lifecycle) | Phase 7.1.2 (evolution cascade) | Braided knot re-weaving triggers on personality evolution events |
| Phase 10.4B (Trending Data) | Phase 8.9 (locality agents) | Real trending data comes from locality agent aggregation |
| Phase 10.4B (Trending Data) | Phase 1.1 (episodic memory) | Trending signals derived from episodic interaction patterns |
| Phase 10.4D (Decision Audit Trail) | Phase 4.6.1 (feature attribution) | Audit trail includes full feature attribution for each recommendation |
| Phase 10.4D (Decision Audit Trail) | Phase 1.2 (outcomes) | Audit trail links recommendations to observed outcomes |
| Phase 7.9F (User Request Self-Healing) | Phase 7.9A, Phase 7.9C, Phase 6.7 | Parameter registry must exist; experiment system; SLM for classification |
| Phase 7.9G (Collective Request Aggregation) | Phase 7.9F, Phase 7.9C, Phase 1.1A | Individual requests feed clusters; experiment system; embeddings |
| Phase 6.6.8-6.6.12 (Multi-Transport AI2AI) | Phase 6.6.1-6.6.7, Phase 2.5 | Existing mesh; post-quantum for WiFi channel |
| Phase 8.9E (Behavioral Archetype) | Phase 8.9A-8.9C, Phase 1.1, Phase 8.1 | Locality agents; episodic memory aggregates; federated sharing |
| Phase 9.4 (Services Marketplace) | Phase 3.1, Phase 4.1, Phase 6.1, Phase 2.1, Phase 1.2 | Feature extraction; energy function; MPC planner; GDPR; outcome collection |
| Phase 7.10 (Life Pattern Intelligence) | Phase 1, Phase 3.1, Phase 5.1, Phase 6.2, Phase 7.4 | Episodic memory; state encoder features; transition predictor; guardrails; triggers |
| Phase 6.7B (SLM Active Engine) | Phase 6.7, Phase 7.5 | SLM model (explanation + intent); device tier system |
| Phase 8.6B (Ad-Hoc Group Formation) | Phase 6.7B, Phase 6.6, Phase 4.4 | SLM intent extraction; multi-transport discovery; bilateral energy aggregation |

---

## User Request Self-Healing Outputs (Phase 7.9F)

**Data produced:**
- User request records: structured feedback with category, severity, free-text
- Request classification: parameter-tunable / strategy-adjustable / feature-request
- Per-user parameter overrides: user-initiated values that take priority over system experiments
- Feedback confirmation outcomes: satisfaction_improved / unchanged / declined / reverted

**Consumed by:**
- Phase 7.9C (self-optimization experiment orchestrator -- user overrides take priority)
- Phase 7.9G (collective request aggregation -- individual requests feed clusters)
- Phase 6.7 (SLM classifies free-text requests if available)
- Phase 1.2 (outcome tuples from request outcomes)

**Breaking change risks:**
- Parameter priority: user overrides must not conflict with safety guardrails (7.9E). Guardrails always win over user requests.
- Self-optimization engine must check for user overrides before applying experiment changes to a user.

---

## Collective Request Aggregation Outputs (Phase 7.9G)

**Data produced:**
- Request clusters: semantically similar user requests grouped by embedding similarity
- Threshold triggers: cluster size reaching 50+ unique users triggers canary experiment
- Collective experiment results: happiness delta for requested changes
- Minority protection reports: per-segment impact analysis before system-wide rollout

**Consumed by:**
- Phase 7.9C (experiment orchestrator runs the collective experiments)
- Phase 7.9D (admin dashboard shows trending requests and experiment results)
- Phase 1.1A (semantic memory embeddings used for request clustering)

**Breaking change risks:**
- Feature request aggregation (7.9G.4) generates proposals in 7.9D.2 format -- must match proposal schema.
- Minority protection (7.9G.5) depends on 7.9C.6 segment definitions existing.

---

## Multi-Transport AI2AI Outputs (Phase 6.6.8-6.6.12)

**Data produced:**
- Transport metadata: which channel was used (BLE/WiFi/WiFi Direct) per exchange
- VPN detection state: boolean per device, triggers WiFi discovery disable
- Transport quality metrics: bandwidth achieved, latency, error rates by transport type
- WiFi security verification: subnet check results, replay protection logs

**Consumed by:**
- Phase 8.5/8.6 (AI2AI insight exchange benefits from WiFi bandwidth -- larger payloads)
- Phase 7.8 (multi-device sync can use WiFi Direct for bulk transfers)
- Phase 7.9 (self-optimization engine evaluates whether transport type affects learning quality)
- Phase 9.4G (service marketplace federated data can transfer over WiFi)

**Breaking change risks:**
- `ConnectionOrchestrator` currently gates on BLE-only. Removing that gate affects all AI2AI callers.
- Signal Protocol session must be transport-agnostic -- same ratchet state across BLE and WiFi. Breaking this = security vulnerability.
- VPN detection must be passive (no user prompt) -- active detection could alarm privacy-conscious users.

---

## Behavioral Archetype Outputs (Phase 8.9E)

**Data produced:**
- `BehavioralArchetype` model: cluster of temporal-categorical behavior patterns (top 3 categories, temporal preference, exploration ratio, social density, lifecycle stage)
- Per-locality archetype distribution: what % of users match each archetype (DP-protected)
- Archetype-based segment definitions: for cross-archetype experiment validation

**Consumed by:**
- Phase 8.1 (federated learning shares archetype distributions across localities)
- Phase 7.9C.6 (per-segment optimization uses archetype as segmentation dimension)
- Phase 5.1 (transition predictor learns archetype shift patterns as strong life-change signals)
- Phase 8.9C (advisory system matches localities by archetype similarity + vibe similarity)

**Breaking change risks:**
- Archetype model depends on episodic memory aggregate patterns -- Phase 1.1 must be complete.
- Timezone-aware matching depends on `AtomicClockService` temporal states being correct.
- Archetype labels are internal-only -- if accidentally surfaced to users, it's a privacy incident.

---

## Services Marketplace Outputs (Phase 9.4)

**Data produced:**
- Service provider quantum states: 10D feature vectors per provider
- Service booking outcome tuples: full lifecycle (search → book → complete → rate → rebook)
- User-provider braided knots: relationship evolution from booking history
- Service demand signals: aggregate category demand per geohash cell
- Service category → interest bridging signals: implicit interest from service bookings
- Cross-locality service pricing intelligence: market rate aggregates

**Consumed by:**
- Phase 3.1 (state encoder adds 10D service provider features)
- Phase 4.1 (energy function scores user-serviceProvider pairings bidirectionally)
- Phase 6.1 (MPC planner includes 5 new service action types)
- Phase 6.2 (guardrails: service recommendation frequency, minimum rating floor)
- Phase 8.9 (locality agents include service demand in global state)
- Phase 8.1 (federated learning shares service quality aggregates)
- Phase 1.2 (outcome collection expanded with service lifecycle tuples)
- Phase 10.4C (creator analytics dashboard extends to service providers)

**Breaking change risks:**
- New quantum entity type (`serviceProvider`) must be handled by ALL quantum services (QuantumVibeEngine, PersonalityKnotService, EntityKnotService, etc.) or they'll crash on unknown type.
- Service provider 10D features increase state vector from ~156-166D to ~166-176D. All downstream models (state encoder, energy function, transition predictor) must be retrained with the larger input.
- Service timing prediction (9.4C.2) depends on MPC planner (Phase 6.1) being operational.
- Legal compliance (9.4F) is a hard dependency before any revenue flows.

---

## Life Pattern Intelligence Cross-Phase Connections (Phase 7.10)

**What 7.10 produces:**
- Episodic tuples (passive engine: location changes, widget checks; active engine: 8x-weight preference tuples)
- State encoder features: routine adherence (1D), deviation frequency (1D), social co-location density (1D)
- Deviation classifier for taste drift; dormancy predictive state
- Social suggestions and schedule-sharing constraints for MPC
- Notification philosophy rate limiter; absence pattern analysis for re-engagement
- Triggers: significant location change, widget timeline refresh, SLM tool call
- OptimizableParameter (passive check frequency); notification inference pipeline
- SLM-triggered ad-hoc group formation; routine patterns for archetype clustering
- Social co-location data keyed to friend list; SLM service booking triggers

**Consumed by:**
- **Phase 1 (Episodic Memory):** Passive engine produces episodic tuples for every background location change and widget check. Active engine (6.7B) produces highest-confidence preference tuples (8x weight) from user chat.
- **Phase 3.1 (Feature Extraction):** Adds 3 new state encoder features: routine adherence score (1D), deviation frequency (1D), social co-location density (1D).
- **Phase 5.1 (Transition Predictor):** Deviation classifier feeds taste drift detector (5.1.9). Dormancy predictive state extends dormancy predictor (5.1.11).
- **Phase 6.1 (MPC Planner):** Social suggestions (7.10C.2) feed joint activities to MPC. Schedule sharing (6.7B.6) provides temporal constraints.
- **Phase 6.2 (Guardrails):** Notification philosophy (7.10D) adds immutable labeling question rate limiter. Re-engagement strategies (6.2.12-6.2.15) consume absence pattern analysis.
- **Phase 7.4 (Triggers):** Three new triggers: significant location change, widget timeline refresh, SLM tool call.
- **Phase 7.9 (Self-Optimization):** Passive engine check frequency registered as OptimizableParameter. Notification inference pipeline evaluated by self-optimization.
- **Phase 8.6 (Group Negotiation):** Ad-hoc group formation (8.6B) extends negotiation with SLM-triggered user-initiated groups.
- **Phase 8.9E (Behavioral Archetypes):** Routine model feeds archetype clustering with temporal-spatial patterns.
- **Phase 9.4 (Services Marketplace):** SLM tool-calling can trigger service bookings for groups.
- **Phase 10.4A (Friend System):** Social co-location data keyed to friend list. Per-friend happiness correlation requires friend tiering.

**Breaking change risks:**
- If `LocationPatternAnalyzer` interface changes, passive engine pipeline breaks.
- If `AgentIdService` changes validation, privacy architecture 7.10B.2 audit fails.

---

## SLM Active Engine Cross-Phase Connections (Phase 6.7B)

**What 6.7B produces:**
- Intent extraction from user chat (distinct from explanation generation)
- Preference tuples at 8x signal weight (between explicit rating 10x and return visit 8x)
- Conversational onboarding data for routine model head start (2-4 weeks)
- Tiered inference: SLM on Tier 3, cloud LLM on Tier 2 online, template matching on Tier 1/0
- Tool-calling outputs for 7 tools (schema-stable)

**Consumed by:**
- **Phase 6.7 (SLM):** Direct extension. SLM model must support both explanation generation (6.7.2) and intent extraction (6.7B.1). Same model, different system prompt.
- **Phase 7.5 (Device Tiers):** Active engine tiers: SLM on Tier 3, cloud LLM on Tier 2 online, template matching on Tier 1/0.
- **Phase 1.4 (Signal Hierarchy):** SLM preference tuples weighted at 8x (between explicit rating 10x and return visit 8x).
- **Phase 7.10A.2 (Routine Model):** Conversational onboarding (6.7B.3) gives routine model a 2-4 week head start.

**Breaking change risks:**
- If SLM model changes, both explanation and intent extraction prompts need updating.
- Tool-calling schema changes affect all 7 tools.

---

## Ad-Hoc Group Formation Cross-Phase Connections (Phase 8.6B)

**What 8.6B produces:**
- User-initiated group formation (SLM intent) — same outcome format as agent-initiated 8.6
- BLE scan for nearby agents; WiFi local as fallback
- Simplified energy aggregation (average scores) for speed (<5s)
- Group booking bridge for service marketplace

**Consumed by:**
- **Phase 8.6 (Group Negotiation):** Extension. 8.6 is agent-initiated (high entanglement), 8.6B is user-initiated (SLM intent). Same outcome format.
- **Phase 6.6 (Multi-Transport):** BLE scan for nearby agents. WiFi local as fallback.
- **Phase 4.4 (Bilateral Energy):** Ad-hoc group uses simplified aggregation (average scores) for speed (<5s).
- **Phase 9.4 (Services Marketplace):** Group booking bridge enables SLM to reserve for the whole party.

**Breaking change risks:**
- If AI2AI message types change, group confirmation protocol (8.6B.2) breaks.

---

## Multi-Dimensional Happiness Cross-Phase Connections (Phase 4.5B)

**What 4.5B produces:**
- `HappinessVector` with 6+ learned dimensions per user (replacing single scalar)
- Self-calibrating per-user dimension weights (updated weekly during consolidation)
- Self-adjusting dimension definitions (new dimensions proposed by self-optimization, stale ones retired)
- Dynamic per-locality thresholds (replacing fixed 60%)
- Happiness trajectory prediction (7-day forecast)
- Professional fulfillment dimension for earners

**Consumed by:**
- **Phase 4.5.6 (Agent happiness training signal):** Energy function now backpropagates per-dimension deltas, not just scalar deltas. More precise signal.
- **Phase 8.9B (Locality advisory):** Uses dynamic locality thresholds (4.5B.4) instead of fixed 60%. Advisory is now relative to each locality's baseline.
- **Phase 5.1 (Transition predictor):** Forecasts happiness trajectory (4.5B.5), not just current state. Enables preemptive MPC action.
- **Phase 6.1 (MPC planner):** Plans against happiness trajectory, not snapshot. Increasing exploration when trajectory declines.
- **Phase 7.9 (Self-optimization):** Can propose new happiness dimensions (4.5B.3). Optimization targets are now multi-objective.
- **Phase 9.4/9.5 (Marketplace/Expertise):** Professional fulfillment (4.5B.6) is the optimization target for earner recommendations.
- **Phase 12.1.3 (System monitor):** Displays multi-dimensional happiness heatmaps.
- **Phase 13.2 (Universe model):** Locality-specific thresholds and dimension weights aggregate through federation hierarchy.

**Breaking change risks:**
- Every consumer of `AgentHappinessService.happiness` must handle vector output, not scalar. Migration: scalar = weighted sum of vector.
- If dimension schema changes (new dimensions added/retired), all downstream consumers that store historical happiness must handle schema evolution.

---

## DSL Self-Modification Cross-Phase Connections (Phase 7.9H)

**What 7.9H produces:**
- Strategy DSL grammar for expressing rule-based system modifications
- Sandboxed on-device interpreter (max 100 rules, 10ms/rule)
- Guardrail-validated compiler that prevents guardrail override
- DSL-composed strategy experiments (canary deployments)
- OTA delivery of DSL rule sets via Phase 7.7

**Consumed by:**
- **Phase 7.9C (Experiment orchestrator):** Composes and tests DSL strategies autonomously. DSL experiments are a new experiment type.
- **Phase 7.9E (Guardrails):** Compiler validates every rule against immutable guardrails. Meta-guardrail (7.9E.0) cannot be expressed or overridden in DSL.
- **Phase 7.7 (Model lifecycle):** DSL rules delivered via same OTA infrastructure as model weights. Same staging, rollback, and version management.
- **Phase 13.4.3 (Cross-instance adapting):** DSL strategies federated across instances. Category model learns which strategies work universally.
- **Phase 12.2.1 (Admin Code Studio):** Proposals beyond DSL capability are elevated to Code Studio. Clear handoff: "DSL can't express this, needs code change."

**Breaking change risks:**
- DSL grammar changes require interpreter update on all devices (OTA).
- If `OptimizableParameter` schema changes, DSL compiler's bounds validation must update.

---

## Tax & Legal Compliance Cross-Phase Connections (Phase 9.4H)

**What 9.4H produces:**
- Per-jurisdiction earnings records (keyed by geohash, service type, agent_id)
- Jurisdiction-specific tax/legal rule lookups (from locality agents and universe hierarchy)
- Automatic tax document generation (1099-K, VAT summary, local equivalents)
- Business license threshold alerts
- Cross-jurisdiction reconciliation reports
- Point-of-sale sales tax calculation

**Consumed by:**
- **Phase 8.9 (Locality agents):** Store jurisdiction-specific tax rules. Tax rules are part of the locality agent's structured data.
- **Phase 13 (Universe model):** Tax rules propagate through the hierarchy (national → state → city). More specific rules override more general. When a new jurisdiction joins, it brings its tax rules.
- **Phase 9.4E (Provider dashboard):** Displays earnings, tax summaries, compliance status, document downloads.
- **Phase 5.1 (Transition predictor):** Forecasts when earners will cross business license thresholds. Proactive alerts.
- **Phase 9.4D (MPC actions):** Sales tax calculated during booking checkout as part of the book_service action.
- **Phase 12.1.5 (Privacy audit):** Verifies earnings data doesn't leak cross-jurisdiction identities.

**Breaking change risks:**
- If locality agent data schema changes, tax rule lookups (9.4H.2) must update.
- If universe hierarchy depth changes (e.g., adding county level between state and city), tax rule cascading logic must handle the new level.
- **CRITICAL: Tax rules must be jurisdiction-correct.** Incorrect tax calculations have legal consequences. Rules require human verification in admin platform before activation.

---

## Hybrid Expertise System Cross-Phase Connections (Phase 9.5 + 9.5B)

**What 9.5/9.5B produces:**
- Per-user per-category behavioral expertise scores (from life patterns)
- Verified/corroborated/self-reported credentials
- Hybrid expertise scores (behavioral + credentials fused)
- Expert success patterns (federated across localities and categories)
- Partnership energy scores (B2B, expert↔business, community↔brand)
- Partnership outcome data

**Consumed by:**
- **Phase 7.10A (Passive engine):** Behavioral expertise recognition uses passive life pattern data. Expertise scores update during consolidation.
- **Phase 6.7B (SLM active engine):** Active engine signals contribute to behavioral expertise. SLM-shared preferences count as high-weight expertise evidence.
- **Phase 8.1 (Federated learning):** Expert success patterns are federated across localities. Category model distills universal success patterns.
- **Phase 13 (Universe model):** Expertise patterns aggregate through hierarchy. University category model learns student expertise development trajectories.
- **Phase 12.2.6 (Expertise self-improvement):** AI Code Studio continuously improves expertise recognition algorithms.
- **Phase 4.4 (Bilateral energy):** Partnership energy extends bilateral scoring to B2B pairs.
- **Phase 9.4 (Services marketplace):** Expertise score determines marketplace visibility and search ranking.
- **Phase 4.5B.6 (Professional fulfillment):** Expertise growth rate feeds the professional fulfillment happiness dimension.

**Breaking change risks:**
- If expertise score schema changes, marketplace ranking, partnership matching, and energy function all need updating.
- Credential verification depends on external APIs (university registries, licensing boards). API changes break verification.

---

## Admin Platform Cross-Phase Connections (Phase 12)

**What Phase 12 produces:**
- Desktop application shell for system oversight and management
- Admin API layer (shared with Partner SDK)
- AI Code Studio for code-level self-improvement
- Deployment manager for staged rollouts (single instance → org → category → global)
- Partner SDK and plugin architecture
- Third-party conversational planning interface

**Consumed by:**
- **Phase 7.9 (Self-optimization):** Proposals beyond DSL capability elevated to Code Studio. Human-in-the-loop for code-level changes.
- **Phase 7.9D (Notification pipeline):** ADMIN-ONLY notifications routed to admin desktop app (not mobile).
- **Phase 9.5.5 (Expertise self-improvement):** Code Studio workflow for improving expertise recognition algorithms.
- **Phase 13 (Universe model):** Deployment manager scopes deployments to specific instances, organizations, categories, or globally.
- **Phase 13.4.4 (Cross-instance coding):** Code improvements validated at one instance are proposed to others through the admin platform.
- **Phase 9.2.6 (Third-party data):** Partner SDK provides tiered data access for data buyers.

**Breaking change risks:**
- Admin API schema changes affect both desktop app and all Partner SDK consumers.
- Deployment manager must support federation hierarchy scoping. If hierarchy changes, deployment scoping must update.

---

## White-Label Federation & Universe Model Cross-Phase Connections (Phase 13)

**What Phase 13 produces:**
- White-label instance provisioning and configuration
- Knowledge base pre-population per instance type (university, corporate, government)
- Dual identity / context layers with per-context agent_ids
- Network-aware automatic context switching
- Seamless world model adoption (new instances auto-discover)
- Fractal federation hierarchy (world → org universe → category → AVRAI universe)
- Government hierarchy (city → state → national → international)
- Downward intelligence flow (cold-start priors from category/universe models)
- University lifecycle architecture (progression model, faculty matching)
- Cross-instance self-learning, self-healing, self-adapting, self-coding

**Consumed by:**
- **Phase 8.1 (Federated learning):** Extended with hierarchy-aware gradient routing. Gradients flow upward through the hierarchy with DP noise at each level.
- **Phase 8.9E (Behavioral archetypes):** Category models aggregate archetype data across all instances of the same type.
- **Phase 9.4H (Tax/legal):** Jurisdiction rules stored in locality agents, propagated through universe hierarchy.
- **Phase 7.7 (Model lifecycle):** OTA delivery scoped by federation hierarchy. Downward intelligence = model weight updates from category/universe models.
- **Phase 1.5D (Global model):** Pre-seeded global model is now the AVRAI universe model. Cold-start for any new instance.
- **Phase 5.1 (Transition predictor):** University category model informs progression model (13.3.1). Predictions improve with cross-instance data.
- **Phase 6.6 (Multi-transport):** Network detection determines active context layer. VPN → white-label instance, public WiFi → public AVRAI.
- **Phase 12 (Admin platform):** Instance admins get scoped admin views. Organization admins see aggregate. AVRAI admin sees everything.
- **Phase 7.9H (DSL engine):** DSL strategies can be instance-specific, organization-specific, category-specific, or universal.

**Breaking change risks:**
- **CRITICAL:** Federation hierarchy changes (adding/removing levels) affect every system that routes by hierarchy.
- AgentIdService changes affect all context layers (13.1.3). Agent_id format must be stable across hierarchy.
- If federated learning gradient schema changes, all hierarchy-level aggregators must update simultaneously.
- Knowledge base schemas are instance-type-specific. Changing university schema doesn't affect corporate.

---

## Meta-Learning Engine Cross-Phase Connections (Phase 7.9I)

**What 7.9I produces:**
- Learning Cycle Ledger (structured append-only record of every learning event with causal parent_cycles references)
- Causal learning graph (DAG of how the system arrived at its current knowledge)
- Weekly meta-analysis reports (experiment effectiveness, signal quality, consolidation efficiency, federation value, learning velocity)
- Learning process optimization proposals (hyperparameter adjustments within bounded ranges)
- Meta-experiments (testing learning methods against each other)
- Cross-hierarchy meta-insights (federated through universe model)
- Learning regression detection and auto-revert

**Consumed by:**
- **Phase 1.1C (Consolidation):** Meta-analysis runs during consolidation window (max 20% of budget). Consolidation frequency itself becomes a meta-optimizable parameter.
- **Phase 7.9C (Experiment orchestrator):** Meta-experiments use the same canary infrastructure. Experiment design parameters (canary size, duration) are meta-optimizable.
- **Phase 7.9E (Guardrails):** 7 immutable meta-guardrails extend the guardrail system. Meta-learning cannot modify immutable guardrails or its own bounds.
- **Phase 7.9H (DSL engine):** DSL strategy effectiveness feeds the Learning Cycle Ledger. Meta-analysis identifies which DSL strategies work best.
- **Phase 8.1 (Federated learning):** Federation round parameters (frequency, gradient batch size) are meta-optimizable. Diminishing returns detection prevents wasteful federation rounds.
- **Phase 12.1.3 (System monitor):** Learning velocity dashboard displays meta-analysis results, learning velocity trends, and meta-experiment status.
- **Phase 13.2 (Universe model):** Meta-insights federate through the hierarchy. Category models learn which learning strategies work for their population type. New instances receive meta-learning priors.
- **Phase 2.1.8D (AI learning trajectory):** User-facing learning narrative generated from meta-analysis ("Your AI is learning faster this month").

**Breaking change risks:**
- `AIImprovementTrackingService` must be extended to support Learning Cycle Ledger entries. Existing consumers of AITS must handle new entry types gracefully.
- If consolidation window duration changes (e.g., shorter overnight window on some devices), meta-analysis budget (20%) shrinks proportionally.
- Meta-learning hyperparameter bounds are immutable guardrails. Changing them is a code change through the admin platform, not a meta-learning proposal.

---

## Value Intelligence System Cross-Phase Connections (Phase 12.4)

**What 12.4 produces:**
- Attribution chain records (per-outcome causal chain with per-hop tier classification: Direct AI / Platform-Facilitated / Ecosystem / Ambient)
- Multi-touch credit distributions (5 attribution models: first-touch, last-touch, even, decay, bookend)
- Counterfactual trajectory estimates (predicted without-AVRAI happiness/activity from transition predictor)
- Non-AVRAI shrinkage rate (decreasing percentage = deeper life integration)
- Per-user survey receptivity model (optimal timing, format, response quality history)
- Hindsight survey responses (structured feedback timed by emotional distance, never immediate)
- Stakeholder-specific value metrics (7 types: individual, university, corporate, government, business, expert, investor)
- Pilot experiment results (treatment vs. control with statistical significance)
- Automated periodic reports (tailored per stakeholder type and reporting cadence)
- Self-proving intelligence signals (world model accuracy, meta-learning velocity, happiness trajectory, federation contribution)
- Fractal value aggregation (metrics flow up federation hierarchy)

**Consumed by / Consumes from:**
- **Phase 1.1 (Episodic memory) → Attribution Engine:** The attribution engine traverses episodic tuples backward via `parent_action` references to reconstruct causal chains. Every episodic tuple gains an `attribution_tier` field. This is the fundamental data source -- without episodic memory, there's nothing to attribute.
- **Phase 1.2 (Outcome collection) → Attribution Engine:** Every new outcome type (1.2.1-1.2.29) is automatically eligible for attribution chain reconstruction. The attribution engine doesn't need to know about new outcome types explicitly -- it follows tuple chains generically.
- **Phase 4.1 (Energy function) → Question Intelligence:** The survey engine's question intelligence (12.4B.5) queries the energy function for its highest-uncertainty dimensions to decide what to ask about. This is the most efficient use of survey budget -- ask what the model doesn't already know.
- **Phase 4.5B (Happiness vector) → Longitudinal Check-ins:** Monthly/quarterly check-ins (12.4B.9) map directly to happiness dimensions. User responses feed into dimension weight self-calibration (4.5B.2). This is the strongest signal for what the user actually cares about.
- **Phase 4.5B (Happiness vector) → Self-Proving Intelligence:** Per-institution happiness trajectory is real-time proof-of-value without surveys or manual data collection (12.4F.3).
- **Phase 5.1 (Transition predictor) → Counterfactual Estimation:** The counterfactual engine (12.4A.5) uses the transition predictor to simulate "what would have happened without AVRAI" by forward-simulating from pre-AVRAI baseline with zero AVRAI-attributed actions. Also powers projected value forecasting (12.4E.3).
- **Phase 5.1.11 (Dormancy prediction) → Exit Surveys:** Dormancy detection triggers exit survey timing (12.4B.10) -- these are the most valuable for understanding churn.
- **Phase 6.7B (SLM Active Engine) → Conversational Reflection:** The SLM weaves reflective questions into natural dialogue (12.4B.3). The SLM's preference tuple extraction (6.7B.7) processes conversational feedback into structured data. Only during user-initiated sessions -- never proactive for surveys.
- **Phase 7.9A (Self-optimization) → Anti-Fatigue:** Survey frequency registered as `OptimizableParameter` (12.4B.7). The self-optimization engine can tune survey timing/frequency to maximize information per touch.
- **Phase 7.9I (Meta-learning) → Self-Proving Intelligence:** Meta-learning velocity is proof that AVRAI actively adapts (12.4F.2). High velocity = active learning. Low velocity + high accuracy = population well-understood. Both are positive for different audiences.
- **Phase 7.10A (Passive engine routine model) → Survey Timing:** The receptivity model (12.4B.1) uses the routine model's knowledge of downtime windows to time surveys. Emotional distance timing (12.4B.2) uses the deviation classifier to detect if the user has "processed" an experience.
- **Phase 8.9 (Locality agents) → Government/Business Metrics:** Locality intelligence feeds government value metrics (12.4C.4) and business metrics (12.4C.5) on community health and economic activity.
- **Phase 10.4C (Creator dashboards) → Value Metrics:** Existing creator dashboards are extended with attribution chain data -- creators can see not just engagement but the causal chain that led to each booking/attendance.
- **Phase 12.1 (Admin platform) → Dashboards/Reports:** Value Intelligence is a first-class admin module. System monitor (12.1.3) displays value metrics alongside health metrics. Contract renewal intelligence (12.4E.4) is admin-only.
- **Phase 13 (Federation) → Fractal Aggregation:** Value metrics aggregate up the hierarchy (12.4F.5). Category models provide "expected benchmarks" for new instances. Comparison reports (12.4E.2) use category-level aggregates with DP protection.
- **Phase 13.1.3 (Context layers) → Pilot Scoping:** The pilot design wizard (12.4D.1) uses federation context layers for scoped deployment (one dorm, one department, one neighborhood).
- **Phase 13.3 (University lifecycle) → University Metrics:** Freshman integration velocity, cross-department pollination, faculty-student connection rates (12.4C.2) directly consume Phase 13.3 data.
- **Phase 2.1.8 ("What My AI Knows") → User Value Profile:** Individual user value profiles (12.4C.1) surface in the existing transparency page as "Your AVRAI impact" -- doors opened, time saved, financial value.

**Breaking change risks:**
- Episodic tuple schema gains `attribution_tier` field (Phase 1.1). Existing consumers must tolerate the new nullable field. Migration: backfill as `null` (no attribution available for historical tuples without chain reconstruction).
- Survey responses create a new data category that must be included in GDPR export (Phase 10.4E). Schema already expanded in v16.1 -- extend further with `survey_responses[]`.
- Anti-fatigue guardrails are hard caps. If the self-optimization engine (7.9A) tries to increase survey frequency beyond 2/week, the hard cap wins. This is intentional -- not a bug.
- Institution-scoped surveys (12.4B.10) require admin API authorization. Without Phase 12.1 admin platform, institution surveys are unavailable.
- Counterfactual estimation (12.4A.5) requires 90+ days of user history. For new deployments, counterfactuals are unreliable for the first quarter. Reports should clearly state confidence levels.

---

## Updated Execution Dependency Tree (v17 additions)

```
Phase 4.5B  (Happiness dimensions)    ← Phase 4.5, 1.1C, 7.10C, 9.4, 9.5
Phase 7.9H  (DSL engine)             ← Phase 7.9E, 7.9C, 7.7
Phase 7.9I  (Meta-learning)          ← Phase 1.1C, 7.9C, 7.9E, 7.9H, 8.1, 12.1.3, 13.2
Phase 9.4H  (Tax/legal)              ← Phase 8.9, 9.4B, 9.4D, 9.4E, 5.1, 13
Phase 9.5   (Expertise)              ← Phase 7.10A, 6.7B, 8.1, 4.4
Phase 9.5B  (Partnerships)           ← Phase 4.4, 8.6, 9.5, 8.1
Phase 12    (Admin platform)         ← Phase 7.9, 7.7, 7.9D, 9.5.5
Phase 12.4  (Value Intelligence)     ← Phase 1.1, 4.1, 4.5B, 5.1, 6.7B, 7.9A, 7.9I, 7.10A, 12.1, 13
Phase 12.4A (Attribution engine)     ← Phase 1.1 (episodic tuples), 1.2 (outcomes), 5.1 (counterfactual)
Phase 12.4B (Hindsight surveys)      ← Phase 4.1 (uncertainty), 6.7B (SLM), 7.10A (routine model)
Phase 12.4D (Pilot toolkit)          ← Phase 13.1.3 (context layers for scoped deployment)
Phase 12.4F (Self-proving)           ← Phase 4.1 (accuracy), 7.9I (velocity), 4.5B (happiness), 13.4 (federation)
Phase 6.7C  (Translation layer)     ← Phase 6.7 (SLM), 4.6 (explainability), 7.9 (self-optimization), 7.12 (observation), 1.2.16 (contrastive)
Phase 7.12  (Observation service)   ← Phase 7.4 (triggers), 7.9 (self-optimization), 7.9I (meta-learning)
Phase 11.4C (Hardware abstraction)  ← Phase 7.5 (device tiers), 7.10B (battery)
Phase 12.5  (Conviction Oracle)      ← Phase 1.1D (conviction store), 1.1D.5 (fractal flow), 1.1D.8 (serialization), 7.9J (self-interrogation), 7.9I (meta-learning), 7.11 (agent cognition), 12 (admin), 13 (federation), 2 (privacy)
Phase 13    (Federation)             ← Phase 8.1, 8.9, 6.6, 7.7, 1.5D, 12
Phase 13.3  (University)             ← Phase 5.1, 9.5, 8.6, 13.2
Phase 13.4  (Cross-instance)         ← Phase 7.9H, 12.2, 8.1, 7.9F, 13.2
Phase 1.1D  (Conviction memory)      ← Phase 1.1C (consolidation), 4.5B (emotional), 7.9I (meta-learning), 13.2 (federation)
Phase 7.9J  (Self-interrogation)     ← Phase 1.1D (convictions), 7.9I (meta-analysis), 5.1 (transition predictor for stress tests), 12 (admin), 14 (researchers)
Phase 7.11  (Agent cognition)        ← Phase 7.4 (triggers), 7.9I (meta-learning input), 1.1D.2 (wisdom layer), 6.7B (SLM), 6.1 (MPC)
Phase 9.6   (Composite entities)     ← Phase 1.1D (cross-role learning), 4.4 (bilateral energy), 1.7 (role discovery), 12.1.3 (dashboard)
Phase 14    (Researcher access)      ← Phase 2.2 (DP), 8 (federated data), 12 (admin platform), 13 (federation), 1.1D (conviction feedback)
```

**Note:** Phase 9.4H (tax/legal) has a forward dependency on Phase 13 (universe model) for full hierarchy-aware jurisdiction rules. The tax system works without Phase 13 (using flat locality agent rules), but cross-jurisdiction reconciliation and rule cascading require the federation hierarchy.

## v18 Cross-Phase Connections

### Knowledge-Wisdom-Conviction Cross-Phase Connections (Phase 1.1D)

**What 1.1D produces:**
- Knowledge entries (structured claims about the world)
- Wisdom context snapshots (per-decision application of knowledge)
- Conviction entries (promoted knowledge with full audit trail)
- Emotional context vectors (7 emotion types per episodic tuple)
- Conviction propagation chains (bottom-up promotion records)
- Preserved high-information insights (anomalous observations flagged for retention)

**Consumed by / Consumes from:**
- **Phase 1.1C (Consolidation) → Knowledge store:** Consolidation produces knowledge entries from episodic compression and rule extraction
- **Phase 4.1 (Energy function) → Wisdom layer:** Energy function scores knowledge applicability to current context
- **Phase 4.5B (Happiness) → Emotional experience vector:** Happiness dimensions extended with full emotional spectrum
- **Phase 6.1 (MPC planner) → Wisdom context:** Planner receives wisdom context as additional input for multi-horizon planning
- **Phase 7.9I (Meta-learning) → Conviction formation:** Meta-learning identifies which knowledge entries should be considered for conviction promotion
- **Phase 7.9J (Self-interrogation) → Conviction challenge:** Self-interrogation system reviews and challenges existing convictions
- **Phase 7.11 (Agent cognition) → Wisdom layer:** Agent thinking sessions use wisdom layer for multi-horizon reasoning
- **Phase 8.1 (Federated learning) → Conviction serialization:** Convictions federated as DP-protected embeddings
- **Phase 13.2 (Fractal federation) → Bottom-up/top-down conviction flow:** Convictions propagate through the hierarchy
- **Phase 14 (Researcher access) → Conviction audit trail:** Researchers can analyze conviction evolution patterns

### Agent Cognition Cross-Phase Connections (Phase 7.11)

**What 7.11 produces:**
- AgentContext working memory (persistent across wake cycles)
- Thinking session logs (process records of background reasoning)
- Multi-horizon plans (short/medium/long)
- Self-scheduled triggers (agent-generated future wake events)

**Consumed by / Consumes from:**
- **Phase 7.4 (Trigger system) → Thinking scheduler:** Agent Trigger Service manages thinking session scheduling alongside other triggers
- **Phase 7.9I (Meta-learning) → Thinking as input:** Every thinking session is logged as a learning cycle entry
- **Phase 1.1D.2 (Wisdom layer) → Multi-horizon reasoning:** Long-horizon plans use conviction-weighted wisdom
- **Phase 6.1 (MPC planner) → Short-horizon plans:** MPC produces short-horizon action plans that populate AgentContext
- **Phase 6.7B (SLM) → Proactive insights:** SLM generates natural language from hypotheses during user conversations

### Conviction Oracle Cross-Phase Connections (Phase 12.5)

**What 12.5 produces:**
- Universe-scope conviction store (materialized view with full audit trail)
- Creator-only conversational query interface (LLM-backed)
- Creator admin privileges (direct challenge, injection, freeze/unfreeze, retirement)
- Conviction narrative reports (weekly + on-demand)
- Conviction simulation sandbox (counterfactual analysis)

**Consumed by / Consumes from:**
- **Phase 1.1D.5 (Fractal bottom-up flow) → Conviction promotion:** Universe convictions arrive at the oracle via the bottom-up promotion pipeline
- **Phase 1.1D.6 (Fractal top-down flow) → Cold-start priors:** Creator can inject or freeze convictions that flow downward as cold-start intelligence
- **Phase 1.1D.8 (Conviction serialization) → Synchronization:** The oracle receives DP-protected serialized convictions from the federation; it never receives raw user data
- **Phase 7.9J (Self-Interrogation) → Conviction reviews and audit trail:** The oracle materializes the self-interrogation system's outputs -- conviction reviews, stress tests, challenge resolutions
- **Phase 7.9J.4 (Human challenger) → Creator challenge path:** The oracle extends the admin challenge capability with direct conversational access to formal challenges
- **Phase 7.9J.6 (Constructive disruption) → External disruption injection:** The creator can introduce disruption events from outside the system
- **Phase 7.9I (Meta-learning) → Learning cycle ledger:** The oracle reads the meta-learning ledger to contextualize conviction evolution within the system's learning trajectory
- **Phase 7.11 (Agent cognition) → Thinking session context:** Agent thinking outputs feed conviction formation, which the oracle then materializes
- **Phase 12 (Admin platform) → Shared authentication and infrastructure:** The oracle extends the admin platform's security model with dedicated hardware key auth
- **Phase 13 (Federation) → Cross-world conviction synchronization:** The oracle is the top of the federation hierarchy for conviction data; world models push up, oracle pushes down
- **Phase 2 (Privacy) → Air-gap enforcement:** The oracle inherits the privacy architecture's DP guarantees and adds physical isolation

**Breaking change risk:** LOW. The oracle is a read-heavy materialized view of data that already flows through the federation. It adds no new data collection requirements. The only novel capability is creator-initiated conviction injection/freeze, which extends existing challenge protocols.

**Contract:** `UniverseConvictionStoreService`, `ConvictionOracleQueryInterface`, `CreatorConvictionAdmin { challenge(), inject(), freeze(), unfreeze(), retire(), simulate() }`, `ConvictionNarrativeGenerator`.

### Reality-to-Language Translation Layer Cross-Phase Connections (Phase 6.7C)

**What 6.7C produces:**
- Semantic Bridge Schema (structured intermediate representation between numeric outputs and text)
- Output Format Registry (catalog of all world model output types)
- Self-healing format optimization proposals (mathematical output format improvements)
- Self-healing vocabulary evolution (learned semantic mappings)
- Grounding enforcement results (validation that SLM output matches data)
- Round-trip validation metrics (information loss measurement)

**Consumed by / Consumes from:**
- **Phase 4.6 (Explainability) → Feature attributions:** Translation layer uses feature attribution rankings to populate the semantic bridge
- **Phase 6.7 (SLM) → Text generation:** SLM consumes Semantic Bridge Schema to generate grounded natural language
- **Phase 6.7B.1 (Intent extraction) → Round-trip validation:** Intent extraction engine re-extracts intent from SLM output for quality testing
- **Phase 7.9 (Self-optimization) → Format optimization proposals:** Translation layer's format change proposals go through the experiment orchestrator
- **Phase 7.9H (DSL engine) → Vocabulary experiments:** Vocabulary evolution treated as DSL strategy experiments
- **Phase 7.12 (Observation bus) → Health metrics:** Translation layer publishes grounding pass rate, round-trip loss, vocabulary effectiveness to observation bus
- **Phase 1.1C (Consolidation) → Round-trip testing:** Nightly consolidation triggers periodic round-trip validation
- **Phase 1.2.16 (Contrastive signals) → Vocabulary feedback:** User response data tells the translation layer which vocabulary works

**Breaking change risk:** MEDIUM. Changes to the Semantic Bridge Schema affect how all downstream SLM generation works. The Output Format Registry changes affect the contract between brain components and the translation layer. Both require versioning and staged rollout.

**Contract:** `SemanticBridgeSchema`, `OutputFormatRegistry`, `FormatToSemanticsTranslator`, `GroundingEnforcer`, `VocabularyEvolutionService`.

### Unified Observation & Introspection Service Cross-Phase Connections (Phase 7.12)

**What 7.12 produces:**
- Observation Bus (typed event bus for inter-component diagnostic signals)
- Component Health Snapshots (per-component performance diagnostics)
- Self-Model (system's understanding of its own performance)
- Attribution Chains (backward traces from outcomes to component contributions)
- Anomaly alerts (statistical deviations from normal component behavior)
- Opportunity proposals (improvement candidates based on cross-component analysis)

**Consumed by / Consumes from:**
- **Phase 7.4 (Trigger system) → Bus infrastructure:** Observation bus uses same event infrastructure as agent triggers
- **Phase 7.9 (Self-optimization) → Anomaly/opportunity signals:** Self-optimization engine investigates anomalies and evaluates opportunities
- **Phase 7.9I (Meta-learning) → Cross-component patterns:** Meta-learning engine analyzes observation bus signals for system-wide learning patterns
- **Phase 3.1 (Feature extraction) → Feature health metrics:** Feature extractor publishes staleness, accuracy, and correlation metrics
- **Phase 4.1 (Energy function) → Score distribution health:** Energy function publishes discrimination quality, score distribution, and confidence
- **Phase 5.1 (Transition predictor) → Prediction accuracy health:** Transition predictor publishes prediction error rates and drift detection
- **Phase 6.1 (MPC planner) → Planning effectiveness:** MPC planner publishes action recommendation acceptance rates and horizon effectiveness
- **Phase 6.7 (SLM) → Generation health:** SLM publishes grounding pass rate and user response quality
- **Phase 6.7C (Translation) → Translation quality:** Translation layer publishes round-trip loss and vocabulary effectiveness
- **Phase 8.1 (Federation) → Federated health aggregates:** DP-protected health aggregates shared across instances
- **Phase 12.5 (Conviction Oracle) → Self-model access:** Oracle reads self-model for creator introspection
- **Phase 1.2 (Outcome data) → Attribution chains:** Outcomes trigger backward attribution tracing through the pipeline

**Breaking change risk:** LOW. The observation bus is additive -- components publish signals without requiring consumers. New components can join the bus without affecting existing ones. The `HealthReporter` interface is the only contract that existing components must implement.

**Contract:** `ObservationBus`, `HealthReporter { reportHealth() → ComponentHealthSnapshot }`, `SystemSelfModel`, `AttributionTracingService`, `AnomalyDetector`, `OpportunityDetector`.

### Hardware Abstraction Hierarchy Cross-Phase Connections (Phase 11.4C-F)

**What 11.4C-F produces:**
- `HardwareComputeRouter` (three-tier compute routing: CPU → NPU → Quantum)
- `DeviceHardwareProfile` (per-device NPU capability detection)
- ONNX delegate selection (optimal inference hardware per model)
- Sensor Abstraction Layer interface (standardized raw signal acquisition)

**Consumed by / Consumes from:**
- **Phase 7.5 (Device tiers) → Hardware profile:** NPU detection feeds into `AgentCapabilityTier` classification
- **Phase 7.12 (Observation bus) → Delegate performance:** ONNX delegate selection publishes inference latency and hardware utilization metrics
- **Phase 7.10B (Battery-adaptive) → Power-aware routing:** Hardware compute router respects battery constraints when selecting NPU vs CPU
- **Phase 3.1 (Feature extraction) → Accelerated normalization:** Feature extraction can use NPU for batch normalization when available
- **Phase 4.1 (Energy function) → Accelerated inference:** Energy function ONNX model uses NPU delegate when available
- **Phase 5.1 (Transition predictor) → Accelerated inference:** Same NPU delegate benefit as energy function
- **Phase 6.5 (System 1) → Fastest inference path:** Distilled model benefits most from NPU (latency-critical path)
- **Phase 6.7 (SLM) → Model loading:** SLM already prefers NPU; hardware router formalizes this

**Breaking change risk:** LOW. The `HardwareComputeRouter` extends `QuantumComputeProvider` -- existing callers continue to work. New capability detection is additive. Sensor Abstraction Layer is an interface that existing sensors can adopt incrementally.

**Contract:** `HardwareComputeRouter { route(operation, constraints) → HardwareTier }`, `DeviceHardwareProfile`, `SensorSource { acquire() → RawSignal }`.

---

**Last Updated:** February 13, 2026  
**Version:** 4.0 (added v20 connections: Reality-to-Language Translation Layer (Phase 6.7C), Unified Observation & Introspection Service (Phase 7.12), Hardware Abstraction Hierarchy (Phase 11.4C-F). Previous: 3.1 added Conviction Oracle (Phase 12.5). Previous: 3.0 added v18 connections. Previous: 2.0)
