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

**Last Updated:** February 11, 2026  
**Version:** 1.4 (added Zeng et al. 2026 anti-fragmentation principle as motivation for cross-phase connection discipline. Previous: 1.3 v12 gap fill)
