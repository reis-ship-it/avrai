# Master Plan - Intelligence-First Architecture

**Created:** February 8, 2026  
**Status:** Active Execution Plan  
**Purpose:** Single source of truth for implementation order -- intelligence-first, business-ready  
**Source of Truth:** `docs/agents/reports/ML_SYSTEM_DEEP_ANALYSIS_AND_IMPROVEMENT_ROADMAP.md`  
**Legacy Plan:** `docs/MASTER_PLAN_LEGACY.md` (Phases 1-31, defunct, historical reference only)  
**Canonical phase/milestone status:** `docs/EXECUTION_BOARD.csv` (with weekly deltas in `docs/STATUS_WEEKLY.md`)  
**Program-level companion tracker:** `docs/agents/status/status_tracker.md`  
**Canonical experiment/training script registry:** `docs/EXPERIMENT_REGISTRY.md` (generated from `configs/experiments/EXPERIMENT_REGISTRY.csv`)  
**Canonical AVRAI-native training data contracts:** `configs/ml/feature_label_contracts.json` + `configs/ml/avrai_native_type_contracts.json`  
**Design rationale:** `docs/plans/rationale/` (WHY decisions were made -- read before each phase)  
**Foundational decisions:** `docs/plans/rationale/FOUNDATIONAL_DECISIONS.md`  
**Cross-phase connections:** `docs/plans/rationale/CROSS_PHASE_CONNECTIONS.md`

---

## Why This Plan Exists

The legacy Master Plan (Phases 1-31) was feature-first: build features, bolt on ML later. The ML System Deep Analysis and Improvement Roadmap revealed that this approach produced 30+ hardcoded formulas, no outcome data, no episodic memory, and an architecture that couldn't learn from its own predictions.

This plan is intelligence-first: build the learning infrastructure, then systematically replace every hardcoded formula with learned functions, then scale. Every feature built from here forward feeds the world model rather than creating more technical debt.

**What's already built and stays:** 330+ services, 150+ models, 9 packages, 21 controllers, quantum/knot/fabric/worldsheet systems, Signal Protocol encryption, reservation system, payment system, BLE mesh networking. None of this is discarded.

**What changes:** How decisions are made. Every weighted formula, hardcoded threshold, and hand-crafted scoring function gets replaced by learned energy functions trained on real outcome data.

---

## Notation System

All work uses **Phase.Section.Subsection** notation:

- **Phase X**: major milestone (e.g., Phase 3: Energy Function)
- **Section Y**: work unit within phase (e.g., Section 3.2)
- **Subsection Z**: specific task within section (e.g., 3.2.1)

Shorthand: `X.Y.Z` (e.g., `3.2.1`), `X.Y` (e.g., `3.2`), `X` (e.g., `3`)

---

## Philosophy + Methodology (Non-Negotiable)

**The complete philosophy is documented in `docs/plans/philosophy_implementation/`. These principles are the operational distillation that every phase, task, and line of code must satisfy.**

### Core Philosophy

- **Doors, not badges**: there is no secret to life, just doors that haven't been opened yet. Every spot is a door. Every person is a door. Every community is a door. Every event is a door. Every list is a door. Every business partnership is a door. AVRAI is the key. Every phase must answer: What doors does this open? When are users ready? Is this being a good key? Is the AI learning with the user?
- **Meaningful connections**: the entire purpose is to open doors for meaningful connections. Meaning, fulfillment, happiness. Not engagement metrics, not time-in-app, not ad impressions. The energy function optimizes for doors that lead somewhere meaningful, not doors that get clicked.
- **Spots → Community → Life**: users find their spots, those spots have communities, those communities have events, they find their people, AVRAI gives them life. This journey is the product. Everything else is infrastructure.
- **Real world enhancement, never replacement**: technology serves life in the real world. No gamification that replaces authentic engagement. No capitalizing on usage. AI is used for the right reasons -- giving people a better experience in the real world. The doors we open lead to real places, real people, real communities.
- **Calling to action**: users are called to action in the real world by being shown doors that would make their life better. The world model's MPC planner is the mathematical expression of this -- it plans action sequences that open the best doors for each person. The AI2AI system enables this while preserving privacy.
- **Authenticity preservation**: your doors stay yours. The world model protects against homogenization -- the energy function learns what makes YOU unique, not what makes everyone average. Growth without loss of identity. The transition predictor learns YOUR evolution, not a population average.

### Methodology

- **40-minute context protocol**: read plans + search existing implementations before building.
- **Architecture**: ai2ai only (never p2p), offline-first, self-improving, world-model-driven.
- **Intelligence principle**: learned functions > hardcoded formulas. Energy functions > classifiers. Predictions > static scores.
- **Chat-as-accelerator (never gate)**: the world model must converge to accurate predictions from pure behavioral observation alone. A user who never chats with their AI agent must approach the SAME accuracy limit as a user who chats daily -- it just takes more observations. Chat accelerates convergence by 2-5x (fewer interactions needed) but is NEVER required for model quality. This applies to users AND businesses. Passive signals (location, dwell time, dismissals, return visits, temporal patterns) are the primary learning channel; chat is the turbo button.
- **Packaging**: build packageable code with clear APIs.
- **Quantum-ready**: build pure intelligence functions (no side effects) on classical compute with clean abstraction layers. When quantum hardware arrives, the migration is a backend swap, not an architecture rewrite.

### Hardcoded Invariants vs Learned Components (Reality Model Boundaries)

This boundary is mandatory for all self-improvement work: **hardcode the guardrails and learning mechanics, learn the decision policies and rankings**.

| Domain | Hardcoded (must be explicit and non-self-modifying) | Learned (allowed to self-improve within gates) | Plan Anchors |
|--------|------------------------------------------------------|-------------------------------------------------|--------------|
| Safety & legal | Age gating, policy-denied actions, consent enforcement, jurisdiction/compliance constraints | Risk scoring under approved policy space | 2.1, 2.2, 6.2, 7.7A.8 |
| Autonomy control | Shadow-mode requirement, promotion thresholds, rollback triggers, kill switches | Candidate ranker/rewrite parameter updates | 7.7, 7.7A |
| Search architecture | Retrieval lanes (keyword/semantic/structured), required filters, trace schema | Query rewrite behavior, lane weighting, fusion ranking | 1.1D.1-1.1D.7, 1.1D.10 |
| Experiment mechanics | A/B assignment method, canary percentages, statistical confidence rules | Treatment-specific ranking strategies | 7.7.4, 7.7A.2-7.7A.4 |
| Data integrity | Event schemas, deduplication, anti-spam/fraud rules, missing-data defaults | Feature importance and representation learning from valid events | 1.1, 1.2, 3.1 |
| Drift & health | Drift detection thresholds, freshness SLOs, alert policies | Retraining cadence and adaptation parameters triggered by drift | 1.1C, 7.7A.7 |
| Federated cognition + self-healing | Failure signatures, healing state machine, safe-mode fallbacks, retry budgets, circuit breakers, and channel-level kill switches | Recovery-policy prioritization, break-pattern prediction, and adaptive remediation sequencing | 7.3.4, 7.7, 8.1, 8.8, 10.9.9-10.9.12 |
| Resource budgets | CPU/memory/battery/latency caps per device tier, offline fallbacks | Compute-aware model/ranker selection under budget | 3.6, 7.5 |
| Explainability & audit | Immutable change logs, signed manifests, rollback provenance | Explanatory ranking features and calibration | 7.7.1, 7.7A.5, 7.7A.6 |
| World-model planning | Non-negotiable hard constraints for MPC (safety/diversity/quiet hours) | Energy function + transition dynamics + policy planning | 4.1, 5.1, 6.1, 6.2 |
| Kernel governance | `PurposeKernel`, `SafetyKernel`, `TruthKernel`, `RecoveryKernel`, `LearningKernel`, `ExplorationKernel`, `FederationKernel`, `ResourceKernel`, `HumanOverrideKernel` contracts with immutable precedence rules, signed lifecycle policy, emergency freeze path, and rollback TTL | Kernel weights/tactics are learnable only inside immutable kernel boundaries with auditable promotion gates | 1.1E, 6.2, 7.9, 8.1, 10.9 |

**Implementation rule:** Any component that can change production behavior autonomously must declare: (1) immutable constraints, (2) learnable parameters, (3) promotion gates, (4) rollback path.

### Universal Self-Healing Contract (All Reality/Universe Models)

Every subsystem must be self-healable and treat break events as training signals.
This applies to all implemented systems now and all future systems added later. No subsystem is exempt.

Scope coverage (non-exhaustive, always-expanding):
- perception/sensing, ingestion, memory, reasoning, planning, action execution
- AI2AI/federated learning, locality advisory, orchestration, rollout/lifecycle, schema/versioning
- storage/sync, security/privacy/compliance, networking/transport, device-tier adaptations
- UI/agent interaction pathways, experimentation pipelines, recovery tooling, and governance/CI controls

For any new subsystem introduced in the future:
- it must register break classes, safe-mode behavior, and recovery actions before production enablement
- it inherits this contract automatically and must emit compatible healing telemetry

- **Eyes (perception):** sensor/feature freshness failures, missing inputs, and modality drift must trigger perception-safe fallback + drift event logging.
- **Ears (ingest/listen):** trigger loss, duplicate events, or federated update corruption must trigger dedupe/replay + channel quarantine.
- **Mouth (actions/output):** invalid recommendations, policy-unsafe actions, or rollout regressions must trigger immediate rollback/circuit break + bounded retry.
- **Brain (reasoning/learning/knowledge/convictions):** planner contradiction, model instability, memory inconsistency, or belief divergence across federated peers must trigger recovery state transitions (`open -> scheduled -> recovering -> resolved`) and provenance logging.
- **Hands (execution/orchestration):** failed workflow steps must auto-schedule remediation jobs, not leave dead states.

Required behavior for any break, regardless of domain:
1. Detect deterministically and classify break type/severity.
2. Fail closed to a safe mode with bounded blast radius.
3. Capture canonical incident context: `what`, `where`, `when`, `who/which entity`, `how`, `why` (best-known cause).
4. Auto-schedule a recovery action and track it through healing states (`open -> scheduled -> recovering -> resolved`).
5. Run automated verification of the fix path before re-entry to autonomous mode.
6. Record break + healing as learning metrics (frequency, time-to-detect, time-to-heal, recurrence risk, impact radius).
7. Feed root-cause and recovery outcome back into memory/reliability stores as reusable failure signatures.
8. Update prevention policy (guardrails, retries, thresholds, or routing) to reduce repeat probability.
9. Re-test adjacent systems for correlated failure modes.
10. Keep the loop perpetual: each break must improve future detection, diagnosis, and self-repair quality.

### LeCun World Model Framework Mapping

Every component in this plan maps to a specific role in LeCun's autonomous machine intelligence architecture. This mapping is the design authority -- if a proposed change doesn't fit this framework, it doesn't belong.

| LeCun Component | Role | Our Implementation | Phase |
|----------------|------|-------------------|-------|
| **Perception Module** | Observes the world, produces state representation | `WorldModelFeatureExtractor` (145-155D from 19+ services) + `FeatureFreshnessTracker` | Phase 3.1 |
| **World Model** | Predicts next state given current state and action | `TransitionPredictor` (ONNX MLP, replaces ODE/extrapolation/possibility engine) | Phase 5.1 |
| **Cost Module (Critic)** | Evaluates quality of state-action pairs as energy | `EnergyFunctionService` (ONNX critic, replaces 30+ hardcoded formulas) | Phase 4.1 |
| **Actor** | Proposes action sequences to minimize cost | `MPCPlanner` (simulates N-step futures, picks lowest total energy) | Phase 6.1 |
| **Guardrail Module** | Hard constraints the actor cannot violate | Diversity, exploration, safety, doors, age, notification, quiet-hours constraints | Phase 6.2 |
| **Short-Term Memory** | Recent observations and predictions | `EpisodicMemoryStore` (state, action, next_state, outcome tuples) | Phase 1.1 |
| **Semantic Memory** | Compressed knowledge from experience | Vector store extending `StructuredFactsIndex` with embeddings | Phase 1.1A |
| **Procedural Memory** | Learned strategy heuristics | If-then rules extracted from episodic patterns | Phase 1.1B |
| **Memory Consolidation** | Nightly compression/pruning cycle | Episode → knowledge compression, rule extraction, pruning | Phase 1.1C |
| **Configurator** | Adjusts modules based on task/context | `DeferredInitializationService` + `FeatureFlagService` + `AgentCapabilityTier` (device-tier-aware degradation) | Phase 3.5, 7.5 |
| **Latent Variable** | Represents uncertainty about future | Variance head on transition predictor + multi-future sampling (z-vector) | Phase 5.3 |
| **System 1 (Fast)** | Instant reactive decisions | Distilled ONNX model trained from MPC planner outputs | Phase 6.5 |
| **System 2 (Slow)** | Deliberate multi-step planning | MPC planner with N-step horizon simulation | Phase 6.1 |
| **Language Module** | Human-readable explanations | SLM (1-3B, on-device) -- interface to the brain, not the brain | Phase 6.7 |
| **Trigger System** | Event-driven agent activation | `AgentTriggerService` replacing 1s polling timer | Phase 7.4 |
| **Device Tiers** | Graceful capability degradation | `AgentCapabilityTier` enum (full/standard/basic/minimal) | Phase 7.5 |
| **JEPA** | Optimal personality embedding from behavior | Self-supervised parallel embedding (research track) | Phase 11.3 |
| **Multi-Entity State** | Lists, communities, events, businesses, brands as first-class world model entities | Lists get full representation (Phase 3.4); businesses/brands get state encoders and bidirectional energy (Phase 4.4.8-4.4.12) | Phase 3.4, 4.4 |
| **Bilateral Cost Modules** | Business partnerships and sponsorships require bidirectional energy | Both parties evaluated: business-expert, brand-event, business-business, business-patron. Each side has its own cost function | Phase 4.4.8-4.4.14 |

**Key LeCun principles enforced:**
1. **Energy-based, not probabilistic**: We learn energy functions (low = good), not probability distributions. This avoids the "curse of dimensionality" in high-D probability estimation.
2. **JEPA over generative**: The state encoder learns abstract representations, not pixel-level reconstructions. Quantum/knot/fabric features are already abstract -- we preserve this.
3. **Hierarchical planning**: MPC operates at short (1-action), medium (3-action), and long (7-action) horizons. Short-horizon plans are concrete; long-horizon plans are abstract.
4. **Self-supervised from observation**: The world model learns from episodic memory (self-supervised), not from labeled datasets. Outcome signals provide the training supervision.
5. **Consistent state observation**: The evolution cascade (Phase 7.1.2) ensures all feature sources update atomically when personality changes, so the perception module always sees a consistent world state.

**Required references:**
- `docs/plans/philosophy_implementation/DOORS.md`
- `OUR_GUTS.md`
- `docs/plans/philosophy_implementation/AVRAI_PHILOSOPHY_AND_ARCHITECTURE.md`
- `docs/plans/methodology/DEVELOPMENT_METHODOLOGY.md`
- `docs/agents/reports/ML_SYSTEM_DEEP_ANALYSIS_AND_IMPROVEMENT_ROADMAP.md`
- `docs/plans/architecture/EXTERNAL_RESEARCH_ADDENDUM_2026-02-15_ARXIV_2602_09000.md`
- `docs/plans/architecture/EXTERNAL_RESEARCH_ADDENDUM_2026-02-15_ARXIV_2601_19897.md`
- `docs/plans/architecture/EXTERNAL_RESEARCH_ADDENDUM_2026-02-15_ARXIV_2602_12259.md`
- `docs/plans/architecture/EXTERNAL_RESEARCH_ADDENDUM_2026-02-16_ARXIV_2501_02305.md`
- `docs/plans/architecture/EXTERNAL_RESEARCH_ADDENDUM_2026-02-16_ARXIV_2502_17779.md`
- `docs/plans/architecture/EXTERNAL_RESEARCH_ADDENDUM_2026-02-16_ARXIV_2602_11136.md`
- `docs/plans/architecture/EXTERNAL_RESEARCH_ADDENDUM_2026-02-16_ARXIV_2602_11865.md`
- `docs/plans/architecture/EXTERNAL_RESEARCH_ADDENDUM_2026-02-16_BATCH_ADAPTIVE_REASONING_RUNTIME.md`
- `docs/plans/architecture/EXTERNAL_RESEARCH_ADDENDUM_PHASE_PLACEMENT_MATRIX_2026-02-16.md`
- `docs/plans/architecture/EXTERNAL_RESEARCH_ADDENDUM_2026-02-19_RECURSIVE_META_KERNELS_AND_DISCOVERABILITY.md`
- `docs/plans/architecture/EXTERNAL_RESEARCH_ADDENDUM_2026-02-19_ARXIV_2507_00885.md`
- `docs/plans/architecture/EXTERNAL_RESEARCH_ADDENDUM_2026-02-15_BATCH_OTHERS.md`
- `docs/plans/architecture/EXTERNAL_RESEARCH_ADDENDUM_2026-02-15_GITHUB_NANOBOT.md`
- `docs/plans/architecture/AUTONOMOUS_RESEARCH_EXPERIMENTATION_ENGINE.md`
- `docs/plans/architecture/DREAM_TRAINING_CONVICTION_GOVERNANCE.md`
- `docs/security/RED_TEAM_TEST_MATRIX.md`
- `docs/EXPERIMENT_REGISTRY.md`
- `docs/plans/methodology/ML_TRAINING_AUTOMATION_GOVERNANCE.md`
- `docs/plans/methodology/PRD_EXECUTION_BOARD_INTEGRATION.md`
- `docs/GITHUB_ENFORCEMENT_SETUP.md`

---

## Parallel Execution (Tier-Aware)

- **Tier 0**: Blocks everything else. Must complete first.
- **Tier 1**: Core intelligence. Can run in parallel with each other once Tier 0 is done.
- **Tier 2**: Advanced intelligence + integration. Depends on Tier 1.
- **Tier 3**: Scaling + business expansion. Depends on Tier 2.
- **Parallel Track**: Features and business work that can run alongside any tier.

---

## Execution Index

| Phase | Name | Tier | Key Dependencies | Est. Duration |
|------:|------|------|------------------|---------------|
| 1 | Outcome Data, Memory Systems & Quick Wins | Tier 0 | None | 4-5 weeks |
| 2 | Privacy, Compliance & Legal Infrastructure | Tier 0 | None (parallel with Phase 1) | 3-4 weeks |
| 3 | World Model State & Action Encoders + List Quantum Entity | Tier 1 | Phases 1, 2 | 5-6 weeks |
| 4 | Energy Function & Formula Replacement (VICReg) | Tier 1 | Phase 1 (outcome data) | 6-8 weeks |
| 5 | Transition Predictor & On-Device Training (VICReg) | Tier 1 | Phases 1, 3 | 5-6 weeks |
| 6 | MPC Planner, System 1/2, SLM & Agent | Tier 2 | Phases 4, 5 | 6-8 weeks |
| 7 | Orchestrators, Triggers, Device Tiers, Lifecycle & Autonomous Research | Tier 2 | Phase 4 (energy function) | 6-8 weeks |
| 8 | Ecosystem Intelligence, Group Negotiation & AI2AI | Tier 3 | Phases 5, 6 | 8-10 weeks |
| 9 | Business Operations & Monetization | Parallel | Phase 2 (compliance) | 6-8 weeks |
| 10 | Feature Completion, Stub Cleanup, Codebase Reorganization & Polish | Parallel | Varies (10.5 immediate; 10.6 after Phases 4/7) | 4-6 weeks |
| 11 | Industry Integrations, JEPA & Platform Expansion | Tier 3 | Phases 8, 9 | 12-20 weeks |

---

## Phase 1: Outcome Data & Episodic Memory Infrastructure

**Tier:** 0 (Blocks everything)  
**Duration:** 4-5 weeks  
**Dependencies:** None  
**Why first:** You cannot train any learned function without outcome data. This is the #1 blocker identified by the ML Roadmap (Section 7.4.1).

### 1.1 Episodic Memory Store

Build the `(state_before, action, next_state, outcome)` tuple storage system.

| Task | Description | Extends |
|------|-------------|---------|
| 1.1.1 | Design episodic memory schema (SQLite via Drift, not ObjectBox -- Drift is proven) | New |
| 1.1.2 | Implement `EpisodicMemoryStore` service with CRUD + query by recency/relevance | New |
| 1.1.3 | Define `EpisodicTuple` model: state snapshot, action taken, resulting state, outcome signal, timestamp (AtomicTimestamp) | New, uses `AtomicClockService` |
| 1.1.4 | Implement state snapshot capture (current personality 12D + quantum vibe 24D + knot invariants + decoherence phase + locality vector) | Uses existing services |
| 1.1.5 | Implement memory pruning (keep last N episodes per action type, compress old episodes into summary statistics) | New |
| 1.1.6 | Register in `injection_container.dart` | Existing pattern |

### 1.1A Semantic Memory (Vector Store -- Knowledge)

Compressed generalizations from episodes. The agent queries "what does this user like on Saturday evenings?" and gets relevant compressed knowledge. Extends existing `StructuredFactsIndex` with embeddings for semantic retrieval.

| Task | Description | Extends |
|------|-------------|---------|
| 1.1A.1 | Design semantic memory schema: embedding vector + natural language generalization + evidence count + confidence + timestamp | New -- COMPLETE (2026-02-19: added `SemanticMemoryEntry` schema with embedding/generalization/evidence/confidence/timestamp fields in `semantic_memory_schema.dart`, including merge semantics and schema round-trip coverage in `semantic_memory_schema_test`) |
| 1.1A.2 | Extend `StructuredFactsIndex` with vector embeddings for semantic retrieval (nearest-neighbor query) | Extends existing -- COMPLETE (2026-02-19: extended `FactsIndex` retrieval path with semantic embedding indexing and cosine-similarity nearest-neighbor query APIs (`indexSemanticMemory`, `retrieveSemanticNearest`), backed by `SemanticMemoryLocalStore` for offline-first operation and covered by `facts_index_test`) |
| 1.1A.3 | Implement generalization extraction: cluster similar episodic tuples → produce compressed knowledge entries (e.g., "user enjoys high-curation spots on weekends") | New -- COMPLETE (2026-02-19: added `SemanticGeneralizationExtractor` to cluster episodic tuples by recurring action/category/daypart patterns and emit compressed `SemanticMemoryEntry` knowledge entries with confidence/evidence scoring; covered by `semantic_generalization_extractor_test`) |
| 1.1A.4 | Implement semantic query API: given a context (time, location, activity type), retrieve top-K relevant knowledge entries by embedding similarity | New -- COMPLETE (2026-02-19: added `querySemanticMemoryByContext` + `SemanticQueryContext`/`SemanticContextMatch` in `facts_index.dart`, combining embedding-nearest retrieval with time/location/activity relevance scoring and confidence gating; covered by new context-query tests in `facts_index_test`) |
| 1.1A.5 | Wire semantic memory as optional MPC planner context (Phase 6): planner uses retrieved knowledge to narrow candidate space before scoring | Feeds Phase 6 -- COMPLETE (2026-02-20: added `SemanticPlannerContextBuilder` + `SemanticMemoryContextClient` adapter in `world_model/mpc_planner/semantic_planner_context_builder.dart`, wired via DI to `FactsIndex` semantic query API, and added candidate-action narrowing + unit coverage in `semantic_planner_context_builder_test`) |

> **ML Roadmap Reference:** Section 16.2, Roadmap Item #31. Extends existing `StructuredFactsIndex` from basic key-value to vector embeddings for semantic retrieval.

> **Integration Risk:** The existing `FactsIndex` (`lib/core/ai/facts_index.dart`) uses `FactsLocalStore` backed by ObjectBox (`lib/data/objectbox/entities/structured_facts_entity.dart`). Phase 10.2.6 proposes removing ObjectBox. **Resolution order:** Migrate `FactsLocalStore` from ObjectBox to Drift/SQLite FIRST (as part of Phase 1.1 episodic memory work, which already uses Drift), THEN add vector embeddings on top. Do not build semantic memory on ObjectBox only to rip it out later. The existing `FactsIndex` class (not `StructuredFactsIndex` -- that's the data model, not the index) is the correct extension point.

### 1.1B Procedural Memory (Learned Strategy Rules)

If-then heuristics extracted from episode patterns. Used by the planning loop to prune unpromising action branches before full energy scoring.

| Task | Description |
|------|-------------|
| 1.1B.1 | Design procedural memory schema: condition (feature thresholds) + action preference + evidence count + success rate | COMPLETE (2026-02-20: added `ProceduralRule` and `FeatureThreshold` schema in `procedural_rule_schema.dart` with JSON round-trip, threshold matching, and evidence-weighted merge semantics; covered by `procedural_rule_schema_test`) |
| 1.1B.2 | Implement rule extraction: identify recurring patterns in episodic memory where specific state features consistently predict action success (e.g., "When novelty_saturation > 0.8 AND energy is moderate, novel exploration spots outperform familiar comfort spots by 23%") | COMPLETE (2026-02-20: added `ProceduralRuleExtractor` in `procedural_rule_extractor.dart` using episodic replay + per-action feature quantile bins to extract recurring state-action-success rules as `ProceduralRule` entries, registered in DI, and covered by `procedural_rule_extractor_test`) |
| 1.1B.3 | Implement rule application API: given current state features, return applicable strategy rules with confidence scores | COMPLETE (2026-02-20: added `ProceduralRuleApplier` in `procedural_rule_applier.dart` to evaluate current state feature maps against extracted `ProceduralRule` thresholds, returning ranked `ApplicableProceduralRule` results with final confidence scores; wired in DI and covered by `procedural_rule_applier_test`) |
| 1.1B.4 | Wire procedural rules as heuristics in MPC planning loop (Phase 6): rules pre-filter candidate actions before exhaustive energy scoring, reducing compute | COMPLETE (2026-02-20: added `PlannerActionPreFilter` in `world_model/mpc_planner/planner_action_prefilter.dart` to combine semantic preferences and `ProceduralRuleApplier` outputs, narrowing candidate action sets before exhaustive scoring; wired in DI and covered by `planner_action_prefilter_test`) |
| 1.1B.5 | Implement rule retirement: if a procedural rule's success rate drops below threshold (evidence of distribution shift), demote or remove it | COMPLETE (2026-02-20: added `ProceduralRuleRetirementService` in `procedural_rule_retirement_service.dart` with deterministic `keep/demote/remove` decisions based on observed rule success + evidence thresholds under distribution shift; wired in DI and covered by `procedural_rule_retirement_service_test`) |

> **ML Roadmap Reference:** Section 16.2, Roadmap Item #32. No existing infrastructure -- build from scratch.

### 1.1C Nightly Memory Consolidation

Runs during charging + WiFi + idle via `WorkManager` (Android) / `BGTaskScheduler` (iOS). Compresses episodes into knowledge, extracts strategy rules, and prunes old episodes.

| Task | Description | Depends |
|------|-------------|---------|
| 1.1C.1 | Implement consolidation scheduler: triggers when device is (a) charging, (b) connected to WiFi, (c) idle (screen off for > 30min). Uses `BatteryAdaptiveBleScheduler` patterns | Extends existing -- COMPLETE (2026-02-20: added `NightlyMemoryConsolidationScheduler` in `memory/consolidation/nightly_memory_consolidation_scheduler.dart` with charging+WiFi+screen-off-idle gating, lifecycle-aware idle tracking, and trigger cooldown to schedule nightly consolidation requests; wired in DI and covered by `nightly_memory_consolidation_scheduler_test`) |
| 1.1C.2 | Implement episode → semantic memory compression: cluster episodes by similarity, produce generalization entries, update existing generalizations with new evidence | 1.1A -- COMPLETE (2026-02-20: extended `SemanticGeneralizationExtractor` to merge newly extracted cluster evidence into existing semantic entries (by deterministic cluster ID) instead of overwriting, preserving and increasing evidence/confidence over time; covered by merge-path assertions in `semantic_generalization_extractor_test`) |
| 1.1C.3 | Implement episode → procedural rule extraction: scan for recurring state-action-outcome patterns that exceed confidence threshold | 1.1B -- COMPLETE (2026-02-20: added `ProceduralRuleConsolidationService` in `memory/consolidation/procedural_rule_consolidation_service.dart` to run episodic replay extraction via `ProceduralRuleExtractor`, persist extracted rules to `ProceduralRuleLocalStore`, and merge additional evidence into existing rules; wired in DI and covered by `procedural_rule_consolidation_service_test`) |
| 1.1C.4 | Implement episode pruning: after consolidation, discard episodes older than N days that have been compressed into semantic/procedural memory. Keep recent episodes and high-surprise episodes (outcomes that contradicted predictions) | 1.1.5 -- COMPLETE (2026-02-20: added `EpisodicMemoryStore.pruneConsolidated(...)` with retention gates for recency, compression status, and high-surprise contradictions/prediction error signals; returns structured prune counts and is covered by `episodic_memory_store_test`) |
| 1.1C.5 | Implement consolidation metrics: episodes compressed, rules extracted, memory size before/after, consolidation duration. Log via `AIImprovementTrackingService` | Extends existing -- COMPLETE (2026-02-20: added `ConsolidationMetricsService` to log consolidation snapshots and emit operational metrics into `AIImprovementTrackingService` via new `recordOperationalMetric/getOperationalMetrics` APIs; wired in DI and covered by `consolidation_metrics_service_test` + `ai_improvement_tracking_service_test`) |
| 1.1C.6 | Wire on-device world model training (Phase 5.2) into consolidation window: gradient updates run during the same overnight window after memory consolidation completes | Feeds Phase 5.2 -- COMPLETE (2026-02-20: added `OnDeviceWorldModelTrainingService` and wired it into `NightlyMemoryConsolidationScheduler` callback so post-consolidation window triggers scheduled `OnlineLearningService` retraining with strict local-first requirement; covered by `on_device_world_model_training_service_test`) |
| 1.1C.7 | Wire federated gradient sync (Phase 8.1) into consolidation window: share DP-noised gradients with mesh/cloud after local training | Feeds Phase 8.1 -- COMPLETE (2026-02-20: added `ConsolidationFederatedGradientSyncService` and wired nightly consolidation callback to trigger `VibeConnectionOrchestrator.syncFederatedCloudQueue()` after successful on-device training in the same window; covered by `consolidation_federated_gradient_sync_service_test`) |

> **ML Roadmap Reference:** Section 15.7, Roadmap Item #33. The consolidation cycle is: compress episodes → extract rules → prune old episodes → train world model → sync gradients. All during one overnight window.

### 1.1D Hybrid Retrieval & Search Intelligence (Universe Models)

Universe models need retrieval that combines explicit search intent, semantic intent, and structured constraints (time, place, platform, trust). `grep`-style keyword matching is useful but insufficient by itself.

| Task | Description | Extends |
|------|-------------|---------|
| 1.1D.1 | Define unified retrieval contract for local events/places/platforms: query text, semantic embedding, filters (`time_window`, `geo_radius`, `category`, `platform`, `trust_tier`), and ranking trace fields | New -- COMPLETE (2026-02-20: added `unified_retrieval_contract.dart` with lane-agnostic query/filter models, ranking trace schema, response contract, and interface boundary for keyword/semantic/structured lanes; covered by `unified_retrieval_contract_test`) |
| 1.1D.2 | Implement keyword retrieval lane (BM25/FTS equivalent) for exact intent and hard term matching. Keep as first-class lane, not fallback-only | New -- COMPLETE (2026-02-20: added `KeywordRetrievalLane` with first-class lexical scoring over a corpus boundary, filter support for time/geo/category/platform/trust-tier, and ranking-trace emission into unified retrieval items; covered by `keyword_retrieval_lane_test`) |
| 1.1D.3 | Implement semantic retrieval lane (vector ANN over embeddings) for intent-level matches beyond literal keywords | Extends 1.1A -- COMPLETE (2026-02-20: added `SemanticRetrievalLane` with vector similarity ranking over semantic corpus documents, unified filter handling for time/geo/category/platform/trust-tier, and semantic lane score traces in retrieval output; covered by `semantic_retrieval_lane_test`) |
| 1.1D.4 | Implement structured retrieval lane for hard constraints: date/time, geo bounds, open-now, platform availability, age/safety constraints | New |
| 1.1D.5 | Implement fusion ranker: blend keyword + semantic + structured scores with recency, source trust, and locality relevance | New -- COMPLETE (2026-02-20: added `RetrievalFusionRanker` to merge/dedupe lane outputs by item id, normalize lane signals, and apply explicit recency + source-trust + locality contributions with rank-trace transparency; covered by `retrieval_fusion_ranker_test`) |
| 1.1D.6 | Add retrieval observability: log per-lane candidate sets, score contributions, selected top-K, latency budget, and final user action outcome | Extends `AIImprovementTrackingService` |
| 1.1D.7 | Build query-rewrite stage for low-result or low-quality queries (spelling normalization, synonym expansion, geo disambiguation, temporal normalization) | New -- COMPLETE (2026-02-20: added deterministic `SearchQueryRewriteStage` that conditionally rewrites low-quality/low-result queries via spelling normalization, synonym expansion, ambiguous-geo disambiguation, and temporal normalization into `RetrievalTimeWindow`; covered by `search_query_rewrite_stage_test`) |
| 1.1D.8 | Build retrieval evaluation set for local events/places/platforms (golden queries + expected relevance tiers). Include edge cases: sparse areas, ambiguous places, multilingual names | New |
| 1.1D.9 | Wire retrieval outcomes into episodic tuples: `(search_state, issued_query, result_set_features, downstream_outcome)` where outcome includes click, save, check-in, bounce, no-action | Extends 1.2 -- COMPLETE (2026-02-20: added `SearchOutcomeEpisodicAdapter` to write retrieval episodic tuples with `search_state`, `issued_query`, `result_set_features`, and `downstream_outcome` payloads, plus outcome-taxonomy mappings for click/save/check-in/bounce/no-action; covered by `search_outcome_episodic_adapter_test` + `outcome_taxonomy_search_test`) |
| 1.1D.10 | Add `SearchLearningAdapter`: learns better ranking/query-rewrite parameters from outcomes without changing core production logic directly | New |

> **Training principle:** Knowledge is primarily runtime retrieval from fresh sources (indexes/DB/APIs), not static "beliefs" in model weights. Model weights learn ranking/policy; indexes hold changing facts.

### 1.1E Lightweight Deterministic Memory Core (Fallback + Recovery Journal)

Add a lightweight, grepable memory lane for deterministic recall, auditability, and recovery diagnostics. This layer complements (not replaces) episodic/semantic/procedural memory.

| Task | Description | Extends |
|------|-------------|---------|
| 1.1E.1 | Define `FactsJournal` schema (append-only factual entries with source, confidence, timestamp, provenance id) | New |
| 1.1E.2 | Define `HistoryJournal` schema (chronological decision/event trace: hypothesis, experiment, rollout, rollback, outcome) | New |
| 1.1E.3 | Implement deterministic retrieval API (keyword + metadata filters) as a fallback when semantic retrieval confidence is low | Extends 1.1A |
| 1.1E.4 | Implement memory-window consolidation for journals: summarize older entries, keep critical facts and failure signatures verbatim | Extends 1.1C |
| 1.1E.5 | Wire autonomous research lane (Phase 7.9) to write every experiment contract and outcome summary into `HistoryJournal` | Feeds 7.9 |
| 1.1E.6 | Wire model lifecycle (Phase 7.7) to log promotion rationale and rollback triggers in deterministic form | Feeds 7.7 |
| 1.1E.7 | Add privacy boundaries: journals remain local plaintext only if protected by on-device encryption at rest; federated sync shares DP-safe summaries only (no raw journal text) | Extends Phase 2, 8.1 |
| 1.1E.8 | Add failure-signature index: known bad patterns from prior rollbacks are tagged and queryable to prevent repeat regressions | Feeds 7.7, 7.9 |
| 1.1E.9 | Add `EvidenceBundle` deterministic envelope for external and internal research claims: source URI, method class, recency, dataset fingerprint, experiment contract ID, and adoption verdict | Extends 7.9, 9.2.6 |
| 1.1E.10 | Add `ConvictionLedger` append-only journal: every confidence increase/decrease must record supporting evidence IDs, contradiction IDs, and delayed-outcome validation window IDs | Feeds 1.4, 4.1, 5.1, 5.2, 6.1 |
| 1.1E.11 | Add third-party research ingest receipts: consent scope, legal basis, DP tier, retention window, and allowed-use class before any claim can influence training/planning | Extends 2.1, 2.2, 9.2.6 |
| 1.1E.12 | Add immutable `KernelRegistry` contract for core behavior kernels (`Purpose`, `Safety`, `Truth`, `Recovery`, `Learning`, `Exploration`, `Federation`, `Resource`, `HumanOverride`). Runtime reads only signed kernel manifests | Extends Hardcoded Invariants, 7.7.1 |
| 1.1E.13 | Add `PurposeKernel` schema with explicit initial goals: understand human condition, test/prove convictions, learn from mistakes and fixes, improve user and agent happiness, discover new goals under safety/legal bounds | Feeds 6.1, 7.9, 8.9 |
| 1.1E.14 | Add `FirstOccurrenceIssueLedger`: first-seen issue signature must create deterministic triage entry with severity, impact radius, and next action (`fix`, `experiment`, `escalate`) | Extends 1.1E.8, 10.9.12 |
| 1.1E.15 | Add `DwellBudgetPolicy` contract per issue class (max active attempts, max wall-clock dwell time, forced escalation path) to prevent infinite rumination loops | Extends 7.9, 10.9.12 -- COMPLETE (2026-02-20: added deterministic `DwellBudgetPolicy` contract + registry with per-issue-class attempt/time budgets and forced escalation path evaluation, including JSON contract parsing and escalation decision coverage in `dwell_budget_policy_test`) |
| 1.1E.16 | Add model-family namespace for deterministic memory and telemetry (`reality_model`, `universe_model`, `world_model`) so federated/meta-learning decisions remain traceable by family and locality | Extends 8.1, 10.9.5 |
| 1.1E.17 | Add `KernelLifecyclePolicy` contract: upgrade/downgrade protocol, compatibility matrix, mandatory rollback TTL by kernel family, and signed change windows | Extends 1.1E.12, 10.9.13 |
| 1.1E.18 | Add `KernelEmergencyFreeze` contract: deterministic freeze trigger classes, freeze scope (`single_kernel`, `family`, `global`), and required human-release path | Extends 1.1E.17, 10.9.13 |
| 1.1E.19 | Add `DreamLedger` schema for speculative episodes: dream id, model family, assumptions, simulator version, hypothesis refs, predicted deltas, and falsification plan id | Extends 7.9, 5.2 |
| 1.1E.20 | Add `BeliefTierContract` with immutable precedence (`dream < hypothesis < candidate_conviction < proven_conviction`) and confidence ceilings per tier; reject any write that violates monotonic promotion flow | Extends 1.1E.10, 10.9.21 |
| 1.1E.21 | Add dream-conviction bridge contract: every dream-derived confidence update must include dual-key evidence (`internal_validation_id` + `external_or_real_outcome_id`) before it can rise above `hypothesis` tier | Extends 1.1E.9, 1.1E.10, 7.7 |
| 1.1E.22 | Add `DreamFailureArchive` with anti-repeat suppression tags so invalidated dream paths are queryable and blocked from re-promotion without new contradiction-clearing evidence | Extends 1.1E.8, 7.7.11 |

### 1.2 Outcome Data Collection Pipeline

Wire every user action to capture outcomes.

| Task | Description | Extends |
|------|-------------|---------|
| 1.2.1 | Create `UnifiedOutcomeCollector` service (generalizes `CallingScoreDataCollector` pattern to all entity types) | Extends existing |
| 1.2.2 | Wire `ReservationCheckInService` confirmations as attendance outcomes | Existing service |
| 1.2.3 | Wire `PostEventFeedbackService` responses as quality outcomes | Existing service |
| 1.2.4 | Wire `ContinuousLearningSystem.processUserInteraction` to write episodic tuples (not just dimension updates) | Existing service |
| 1.2.5 | Add `community_join` as an interaction type in `ContinuousLearningSystem` (currently missing) | Gap fix |
| 1.2.6 | Wire `EventAttendanceController` to record `(state, attend_event, next_state, checkin_confirmed)` tuples | Existing controller |
| 1.2.7 | Wire list interactions (view, save, dismiss) as outcome signals via `PerpetualListOrchestrator`. **Critical:** `PerpetualListOrchestrator.processListInteraction()` currently feeds `_ai2aiIntegration` but does NOT write episodic tuples. Must add: `episodicMemory.write(EpisodicTuple(state: currentState, action: ListAction(type, listId), nextState: stateAfterInteraction, outcome: interactionType))` | Existing orchestrator -- COMPLETE (2026-02-16: `processListInteraction` now writes episodic tuples for view/save/dismiss and related list actions; covered by `perpetual_list_orchestrator_test`) |
| 1.2.8 | **User-created list signals:** When a user creates a `SpotList` (curates spots/events), capture: `(user_state, create_list, list_composition_features, list_metadata)` as an episodic tuple. List composition features = {avg vibe of included spots, category distribution, geographic spread, price range, number of items, user's stated purpose/tags}. **Why:** A user choosing to curate "Late Night Jazz Spots" reveals strong preference signals that passive browsing doesn't. This is a first-class training signal for the energy function | New -- COMPLETE (2026-02-16: `ListsRepositoryImpl.createList` now writes `create_list` episodic tuples with `list_composition_features` and `list_metadata`, including item/category/geographic/purpose-tag signals for local-first list creation flows; covered by `lists_repository_impl_test`) |
| 1.2.9 | **List modification signals:** When a user adds/removes items from a `SpotList`, capture: `(list_state_before, modify_list, item_added_or_removed_features, list_state_after)`. The delta between list versions reveals preference refinement -- the user is actively sculpting their taste profile | New -- COMPLETE (2026-02-16: `ListsRepositoryImpl.updateList` now writes `modify_list` episodic tuples with before/after list snapshots and add/remove delta features in `item_added_or_removed_features`; covered by `lists_repository_impl_test`) |
| 1.2.10 | **List sharing/collaboration signals:** When a user shares a list or adds collaborators, capture: `(user_state, share_list, recipient_features, list_features)`. Collaborative lists reveal social taste alignment -- who you share lists with implies whose taste you trust | New -- COMPLETE (2026-02-16: `SocialMediaSharingService.shareList` writes `share_list` tuples for platform sharing, and `ListsRepositoryImpl.updateList` writes `share_list` tuples when collaborator membership changes; covered by `social_media_sharing_service_phase1_test` and `lists_repository_impl_test`) |
| 1.2.11 | Wire AI2AI connection outcomes (connection quality, learning value) via `ConnectionManager` | Existing service -- COMPLETE (2026-02-16: `ConnectionManager` now writes `connect_ai2ai` episodic tuples with `ai2ai_connection_outcome` quality signals for both online and offline-peer connection flows; wired through `VibeConnectionOrchestrator` DI and covered by `connection_manager_phase1_test`) |
| 1.2.12 | Define outcome taxonomy: binary (did/didn't), quality (1-5 rating), behavioral (personality shift magnitude), temporal (returned within N days) | New -- COMPLETE (2026-02-16: `OutcomeTaxonomy` standardized category mapping with explicit binary/quality/behavioral/temporal helpers, scale metadata (`0-1` and `0-5`), temporal window metadata, and coverage in `episodic_memory_store_test`) |
| 1.2.13 | Wire chat metadata as action types: `message_friend`, `message_community`, `ask_agent` -- record participant, timestamp, community (NOT message content) | Extends `FriendChatService`, `CommunityChatService`, `PersonalityAgentChatService` -- COMPLETE (2026-02-16: all three services now write metadata-only episodic tuples with action types `message_friend`, `message_community`, and `ask_agent`; payloads include participant/community/timestamp only with no message content, and taxonomy maps these to binary outcome signals) |
| 1.2.14 | Wire chat-to-outcome correlations: "user chatted in community X, then attended event in community X" as correlated episodic tuples | New -- COMPLETE (2026-02-16: `ContinuousLearningSystem` now writes `chat_to_outcome_correlation` tuples when `message_community` is followed by same-community `event_attended`/`attend_event`, with latency metadata and `chat_to_event_conversion` outcome signal; covered in `continuous_learning_system_test`) |
| 1.2.15 | Wire business chat outcomes: "business-expert chat led to partnership/event/reservation" via `BusinessExpertChatServiceAI2AI` | Extends existing -- COMPLETE (2026-02-16: `BusinessExpertChatServiceAI2AI` now records `business_chat_outcome_correlation` episodic tuples for partnership/event/reservation outcomes with chat-to-outcome latency metadata and metadata-only context payloads; covered by `business_expert_chat_service_ai2ai_outcome_test`) |
| 1.2.16 | **Contrastive training signals:** When MPC planner recommends action A but user takes action B, record `(state, recommended_A, actual_B, outcome_of_B)` as a contrastive episodic tuple. This is the most valuable training signal -- it teaches the energy function what the user *prefers* over what the model thinks is optimal (LeCun: the critic learns from observed preferences, not just outcomes) | New -- COMPLETE (2026-02-16: `ContinuousLearningSystem` now writes `contrastive_preference_signal` tuples when `recommended_action` differs from the actual user action, capturing recommendation source/payload plus `outcome_of_B` from the realized action tuple; covered by `continuous_learning_system_contrastive_signal_test`) |
| 1.2.17 | Capture recommendation-rejection rate per entity type: if energy function consistently recommends entity type X but user consistently chooses type Y, that's a systematic bias the energy function needs to correct | New -- COMPLETE (2026-02-16: `ContinuousLearningSystem` now writes `recommendation_bias_correction_signal` tuples when `recommendation_rejected` rates indicate systematic bias by entity type, including recommended/preferred type pair and rejection-rate counters; covered by `continuous_learning_system_recommendation_bias_test`) |
| 1.2.18 | **Spot outcome pipeline:** Wire spot visit outcomes explicitly. When a user visits a spot (detected via `ReservationCheckInService` or `AutomaticCheckInService` geofence), record `(user_state, visit_spot, spot_features, outcome)`. Outcomes: return visit within 30 days (strong positive), single visit only (neutral), dismiss from future suggestions (negative). Currently `ContinuousLearningSystem` records `spot_visited` with hardcoded dimension bumps but does NOT record the full episodic tuple with outcome tracking | Gap fix -- COMPLETE (2026-02-16: `AutomaticCheckInService.checkOut` and `ReservationCheckInService.checkInViaNFC` now emit `visit_spot` episodic tuples with `spot_features` and 30-day return-vs-single outcome classification; negative dismiss path remains wired via `dismiss_spot` in `ContinuousLearningSystem`; covered by `automatic_check_in_service_test` and existing episodic/continuous-learning tests) |
| 1.2.19 | **Exploration behavior capture:** When a user browses without acting (opens spot details but doesn't save/visit, scrolls event list but doesn't attend, views community but doesn't join), capture as negative-intent-free observations: `(user_state, browse_entity, entity_features, no_action)`. These "looked but didn't act" signals are valuable: they define the boundary between interest and commitment. Store with a separate `browse` outcome type (distinct from `dismiss`) | New -- COMPLETE (2026-02-16: `SpotDetailsPage`, `ListDetailsPage`, `EventDetailsPage`, `CommunityPage`, and `EventsBrowsePage` browse/no-action episodic tuples wired) |
| 1.2.20 | **Expert-hosted event detailed outcomes:** Extend `PostEventFeedbackService` for expert events specifically: capture expert rating by attendees, topic relevance rating, "would attend again" binary, expertise level match (too basic/just right/too advanced). Wire as `(attendee_state, attend_expert_event, expert_event_features, detailed_feedback)` episodic tuples | Extends existing -- COMPLETE (2026-02-16: `PostEventFeedbackService` writes `attend_expert_event` episodic tuples with detailed feedback payload and outcome taxonomy support; covered by `post_event_feedback_service_test`) |
| 1.2.21 | **Sponsorship outcome pipeline.** When a brand sponsors an event, capture the full lifecycle as episodic tuples: `(brand_state, sponsor_event, event_features, sponsorship_outcome)`. Outcomes: attendee engagement with brand (views, interactions), brand awareness lift (measured via post-event survey or repeat sponsorship), revenue generated vs contributed, event quality impact (did sponsorship improve or degrade event ratings?). `SponsorshipService` already has a "Feedback" stage but no outcome data is captured for model training | New -- COMPLETE (2026-02-16: `SponsorshipService` writes creation and outcome episodic tuples, including engagement/awareness/revenue/quality metrics and brand+sponsor quantum-state updates; covered by `sponsorship_service_test`) |
| 1.2.22 | **Partnership outcome pipeline.** When a business-expert partnership forms (via `PartnershipMatchingService` → `PartnershipService`), capture: `(business_state, form_partnership, expert_features, partnership_outcome)`. Outcomes: partnership longevity (still active after 30/90/180 days), events co-hosted, revenue generated, mutual satisfaction (both sides rate). Currently no partnership outcome data feeds any learning system | New -- COMPLETE (2026-02-16: `PartnershipService` writes `form_partnership` and `partnership_outcome_recorded` episodic tuples with longevity/co-host/revenue/satisfaction metrics; covered by `partnership_service_test`) |
| 1.2.23 | **Business-expert chat → action correlation.** Extend 1.2.15: capture not just "chat led to partnership" but the full chain: `(business_state, initiate_outreach, expert_features, chat_started)` → `(chat_state, negotiate_terms, partnership_features, partnership_formed)` → `(partnership_state, co_host_event, event_features, event_outcome)`. This multi-step chain teaches the MPC planner that business-expert partnerships are means to events, not ends in themselves | Extends 1.2.15 -- COMPLETE (2026-02-16: `BusinessExpertOutreachService` writes `initiate_outreach`→`chat_started`, and `PartnershipService` writes `negotiate_terms`→`partnership_formed` plus `co_host_event`→`event_outcome`; covered by `business_expert_outreach_service_test` and `partnership_service_test`) |
| 1.2.24 | **Business-to-business partnership outcomes.** When businesses partner (via `BusinessBusinessOutreachService` → `BusinessBusinessChatServiceAI2AI`), capture: `(business_A_state, partner_with, business_B_features, partnership_outcome)`. Outcomes: joint event success, cross-referral rate, partnership renewal. Currently `BusinessBusinessOutreachService` has no feedback loop at all | New -- COMPLETE (2026-02-16: `BusinessBusinessOutreachService.recordPartnershipOutcome` writes `partner_with` episodic tuples with joint success/cross-referral/renewal metrics; covered by `business_business_outreach_service_test`) |
| 1.2.25 | **Brand/sponsor quantum state training signals.** Brand and sponsor entities have `QuantumEntityType.brand` and `QuantumEntityType.sponsor` states but no mechanism to update those states based on sponsorship outcomes. Wire: when a brand's sponsored event succeeds, update the brand's quantum state to reflect "this brand is a good fit for events of type X." This requires defining brand state evolution rules (currently brands have static quantum states) | New -- COMPLETE (2026-02-16: `SponsorshipService.recordSponsorshipOutcome` updates both brand and sponsor quantum states from outcome metrics; verified in `sponsorship_service_test`) |
| 1.2.26 | **Business patron engagement outcomes.** When users engage with a business (visit, reservation, purchase, review), capture: `(user_state, engage_business, business_features, engagement_outcome)`. This creates training data for the business-side energy function: which users are good patrons for which businesses? Currently business-patron interaction data exists in `ReservationService` and `AutomaticCheckInService` but is not captured as episodic tuples | New -- COMPLETE (2026-02-16: `ReservationService` and `AutomaticCheckInService` write `engage_business` episodic tuples with engagement outcomes; covered by `reservation_service_test` and `automatic_check_in_service_test`) |
| 1.2.26A | **Passive↔Active intent transition learning.** Add explicit transition tuples that link passive observations to later active outcomes (and vice versa) across users and businesses. Examples: `(user_state, browse_entity, spot_features, no_action)` + later `(user_state, visit_spot, same_spot, outcome)` → write `passive_to_active_conversion`; reverse sequence writes `active_to_passive_regression`. Business analogs: profile/list/partner browse with no action later converting to outreach/partnership/sponsorship/reservation (or regressing). Store transition latency (`minutes/hours/days`) and journey context so planner learns activation windows and cooling signals, not just isolated events | New -- COMPLETE (2026-02-16: `ContinuousLearningSystem` transition tuples verified for spot/business/event/community/list/brand/sponsor in both passive→active and active→passive directions; covered by `continuous_learning_system_test`) |
| 1.2.27 | **Wearable/physiology outcome channel (consent-gated).** Capture optional physiological context tuples `(state, context_signal, physiology_features, downstream_outcome)` for temporal conditioning and drift interpretation. Zero-fill when consent absent | Extends 2.1.3, 5.1.12 |
| 1.2.28 | **Volunteer action/outcome pipeline.** Add first-class volunteer actions across community/event/business lanes: `volunteer_signup`, `volunteer_attend`, `volunteer_retention`, `volunteer_dropoff` with positive-social weighting and delayed outcomes (30/90-day community impact) | Extends 6.1, 8.9, 9.2.6 |
| 1.2.29 | **Nearby invite/install conversion telemetry.** Capture non-user discovery/install funnel tuples for BLE/Wi-Fi invite pathways: `nearby_discovered_non_member`, `invite_sent`, `install_started`, `install_completed`, `first_action_after_install` (privacy-safe, consent-bounded) | Extends 8.4, 10.1 |

### 1.3 Calling Score Pipeline Generalization

The existing `CallingScoreDataCollector` → `CallingScoreNeuralModel` → `CallingScoreABTestingService` pipeline is the template. Generalize it.

| Task | Description | Extends |
|------|-------------|---------|
| 1.3.1 | Extract `BaselineMetricsService` from `CallingScoreBaselineMetrics` (generalize to any formula) | Extends existing -- COMPLETE (2026-02-19: extracted generic `BaselineMetricsService` with reusable `BaselineEvaluationRecord`/`BaselineMetricsResult`, wired into `CallingScoreBaselineMetrics` via DI, and covered by `baseline_metrics_service_test`) |
| 1.3.2 | Extract `FormulaABTestingService` from `CallingScoreABTestingService` (generalize to any formula vs learned comparison) | Extends existing -- COMPLETE (2026-02-19: extracted reusable `FormulaABTestingService` for deterministic treatment assignment and generic control/treatment metric comparison, wired into `CallingScoreABTestingService` and DI, and covered by `formula_ab_testing_service_test`) |
| 1.3.3 | Create `TrainingDataPreparationService` generalized from `CallingScoreTrainingDataPreparer` | Extends existing -- COMPLETE (2026-02-19: extracted reusable `TrainingDataPreparationService` for split validation, normalization, and dataset partitioning; wired into `CallingScoreTrainingDataPreparer` via DI and covered by `training_data_preparation_service_test` and `calling_score_training_data_preparer_test`) |
| 1.3.4 | Add feature flag support for each formula replacement (extend `FeatureFlagService`) | Extends existing -- COMPLETE (2026-02-16) |

### 1.4 Feedback Collection UX

Outcome data comes from both implicit signals and explicit feedback. This section covers the user-facing collection.

| Task | Description |
|------|-------------|
| 1.4.1 | Define implicit feedback signals: dwell time on entity listing, scroll-past-without-tap, re-open after recommendation, save/dismiss actions, chat-after-recommendation |
| 1.4.2 | Define explicit feedback triggers: post-event (next app open after check-in), post-reservation (24hr after), post-community-join (7 days after) |
| 1.4.3 | Design minimal-friction feedback UI: 1-tap thumbs up/down as default, optional 1-5 star and free-text for users who want to elaborate |
| 1.4.4 | Implement feedback rate limiting: max 1 explicit feedback request per session, never back-to-back, respect `OutreachPreferencesService` settings |
| 1.4.5 | Implement negative signal detection: user sees recommendation → closes app → doesn't return for N days = implicit negative outcome |
| 1.4.6 | **One-tap rejection on recommendation cards.** Every recommendation card (spot, event, list, community) gets a small "X" or swipe-left dismiss action. One tap, zero chat, zero text. Record as `(user_state, dismiss_entity, entity_features, explicit_rejection)` episodic tuple. This is orders of magnitude more informative than browse-and-leave (Phase 1.2.19): browse-and-leave is ambiguous ("didn't notice" vs "not interested"), but a tap on X is an explicit "not this." Weight: 5x stronger negative signal than browse-and-leave, 2x stronger than recommendation-shown-but-ignored |
| 1.4.7 | **"Not for me" category dismiss.** After 3 dismissals of the same entity category (e.g., 3 nightclubs dismissed), offer a one-tap "Show fewer [category]?" option. If accepted, record as `(user_state, suppress_category, category_features, explicit_preference)`. This creates an extremely strong negative signal without any conversation. The energy function should learn to assign HIGH energy to that category for this user |
| 1.4.8 | **Implicit positive signals (no interaction required).** Define implicit positive signals that require zero user action: (a) Return visit to a spot within 30 days (Phase 1.2.18), (b) Opening the app within 1 hour of receiving a recommendation notification (interested enough to check), (c) Visiting a spot/event that was recommended even without tapping the recommendation (discovered organically but model was right), (d) Spending >60s on entity detail page (genuine interest). These are the chat-free equivalents of "the user told their agent they liked it" |
| 1.4.9 | **Signal strength hierarchy.** Define explicit ordering of signal informativeness for training the energy function. Strongest to weakest: (1) Explicit rating (1-5 stars) -- 10x, (2) Return visit / repeat action -- 8x, (3) One-tap rejection / dismiss -- 5x, (4) Category suppress -- 10x negative, (5) Reservation/attendance -- 4x, (6) Save/bookmark -- 3x, (7) Notification opened -- 2x, (8) Detail page >60s dwell -- 1.5x, (9) Browse-and-leave -- 1x baseline, (10) Scroll-past-without-tap -- 0.5x (weakest, most ambiguous). These weights are initial values; the model should learn to adjust them from outcome data over time |
| 1.4.10 | **Negative outcome amplification (asymmetric loss).** Bad experiences are more damaging than good experiences are rewarding (loss aversion). The outcome pipeline must implement asymmetric weighting: negative outcomes get 2x the training weight of positive outcomes of the same signal strength. Example: if a user rates a spot 1 star (10x signal), that becomes 20x effective weight vs. a 5-star rating (10x). This teaches the energy function to AVOID bad recommendations more aggressively than it pursues good ones. The asymmetry factor (2x) is a starting value; learn the optimal ratio from outcome data over time. Wire into energy function training (Phase 4.1.7) |
| 1.4.11 | **Negative outcome → confidence decay.** When a recommendation results in a negative outcome: (a) reduce confidence in the relevant entity category by 20% (multiplicative: `confidence *= 0.8`), (b) if 3 consecutive negative outcomes in the same category, trigger re-exploration for that category (Phase 6.2.9-6.2.10), (c) log a "model failure" event to episodic memory with context: `(user_state_at_recommendation, entity, predicted_outcome, actual_negative_outcome)`. These model failure tuples are the MOST valuable training data -- they represent exactly where the model was wrong. Weight them 3x in the next training cycle |
| 1.4.12 | **"Bad day" detection and dampening.** If a user gives 3+ negative signals in a single session (e.g., rapid-fire dismissals, multiple 1-star ratings), detect potential mood-driven feedback. Options: (a) downweight session signals by 0.5x (possible bad mood, not genuine dislike), OR (b) treat as genuine (the model really misfired). Resolution: track whether the user's NEXT session returns to normal patterns. If yes: apply 0.5x retroactive dampening to the negative session. If the user continues the negative pattern across 2+ sessions: treat as genuine taste shift and keep full weight |
| 1.4.13 | **Conviction feedback signals.** Add explicit "helpful / unhelpful / uncertain" feedback for high-impact recommendations and model explanations. Record as `(state, recommendation_or_explanation, conviction_feedback, outcome)` and route to `ConvictionLedger` updates |
| 1.4.14 | **Delayed conviction validation windows.** For strong confidence updates, require 7/30/90-day delayed-outcome checkpoints before finalizing conviction increase. Early positive signals can provisionally increase confidence, but missing delayed validation decays it |
| 1.4.15 | **Source utility feedback loop.** Track whether recommendations influenced by a research source family (internal telemetry, external paper, third-party dataset) actually improve outcomes. De-rank source families that repeatedly fail downstream validation |
| 1.4.16 | **Discoverability non-gate feedback channel.** Add explicit user controls for "show everything in this area/category" and log outcomes to ensure personalized ranking never becomes hard suppression outside safety/legal constraints |
| 1.4.17 | **First-occurrence pain signal priority.** If a novel high-severity negative signal appears once (new failure signature), boost triage priority immediately and emit `first_occurrence_alert` telemetry for self-healing queue intake |

### 1.5 Cold-Start Strategy & Chat-Free Learning

New users have no outcome data. The world model must still serve them. **Critical design principle: the model must converge to accurate predictions from pure behavioral observation alone. Chat with the AI agent is an ACCELERATOR that speeds convergence, but is NEVER required. A user who never chats must approach the same accuracy limit as a user who chats daily -- it just takes more interactions.**

#### 1.5A User Cold-Start (with onboarding)

| Task | Description |
|------|-------------|
| 1.5A.1 | Define default state vector for new users: use population priors from `LocalityAgentGlobalRepositoryV1` (locality-specific average) as initial state features |
| 1.5A.2 | Bootstrap from onboarding: `OnboardingDimensionComputer` produces initial personality dimensions (confidence 0.3) -- wire as initial state encoder input |
| 1.5A.3 | Bootstrap from `ArchetypeTemplateSystem` (Phase 10.1.4): selected archetype provides prior distribution for state features |
| 1.5A.4 | Define minimum interactions before world model activates: use formula-based scoring for first N interactions (e.g., 10), then blend formula → energy function over next M interactions |
| 1.5A.5 | Track cold-start-to-useful metric: how many interactions until the world model's predictions are better than formula baseline? Target: < 20 interactions |

#### 1.5B User Cold-Start (onboarding SKIPPED -- pure behavioral learning)

Users who skip onboarding entirely have no personality dimensions, no archetype, no explicit preferences. The model must still work from Day 1 using ONLY passive signals.

| Task | Description |
|------|-------------|
| 1.5B.1 | **Skip-onboarding fallback path.** When `OnboardingDimensionComputer` has no data and `ArchetypeTemplateSystem` has no selection, the state encoder receives: locality priors (1.5A.1) + device timezone/locale (day/night cycle hint) + zero-vectors for personality dimensions (with confidence = 0.0). The zero-confidence flag tells the energy function to widen its uncertainty band -- all entity types get similar energy scores, producing diverse exploratory recommendations rather than personality-biased ones |
| 1.5B.2 | **First-session behavioral bootstrapping.** The FIRST 5 minutes of app usage are disproportionately informative because they reflect unbiased initial preferences (no recommendation influence yet). Implement `FirstSessionTracker`: record every UI interaction during session 1 with 3x episodic weight. Signals: first map region zoomed to, first category tapped, first 3 entity detail pages opened, first search query, time spent on each screen. These 5-10 data points are worth more than 50 subsequent interactions because they haven't been shaped by model recommendations |
| 1.5B.3 | **Behavioral onboarding-equivalent.** After `FirstSessionTracker` collects initial signals, compute a "behavioral archetype" from the first session: map region → locality cluster, categories tapped → interest profile, price tiers browsed → economic segment. Use this as a lightweight replacement for `OnboardingDimensionComputer` output -- same data shape, same confidence level (0.3), but derived from behavior instead of answers |
| 1.5B.4 | **Accelerated learning phase for skip-onboarding users.** For users with confidence < 0.3 on personality dimensions, the MPC planner should prioritize INFORMATIVE recommendations (ones that reduce uncertainty) over OPTIMAL recommendations (ones that minimize energy). Concretely: if the model is uncertain whether you like jazz or classical, recommend one of each rather than the one it thinks is slightly better. This is Thompson sampling / exploration-exploitation applied to cold-start. See Phase 6.2.9 for the guardrail implementation |
| 1.5B.5 | **Convergence tracking: onboarding vs. skip-onboarding.** Track how fast each path converges to the same accuracy level. Target: skip-onboarding users should reach the SAME recommendation quality as onboarded users within 50 interactions (vs. 20 for onboarded). If the gap is larger, the implicit signal pipeline needs more features. This metric is the primary KPI for chat-free learning quality |

#### 1.5C Business Cold-Start

New businesses joining the platform have no patron history, no reservation data, and no quantum state evolution. They need bootstrap signals just like new users.

| Task | Description |
|------|-------------|
| 1.5C.1 | **Bootstrap business quantum state from public data.** When a `BusinessAccount` is created, populate initial features from: business category (restaurant, bar, gallery, etc.), price tier (from menu/pricing), operating hours, location (geohash + neighborhood), Google/Yelp rating (if available and consented). This gives the business a starting position in quantum vibe space without any patron interaction data |
| 1.5C.2 | **Locality-based business priors.** Use `LocalityAgentGlobalRepositoryV1` to set prior patron expectations: "restaurants in this neighborhood tend to attract users with X vibe profile." This bootstraps the business-side energy function for patron matching (Phase 4.4.8-4.4.12) before any real patron data exists |
| 1.5C.3 | **Category peer transfer.** When a new coffee shop joins in Brooklyn, transfer learnings from EXISTING coffee shops in Brooklyn (via federated aggregation, not raw data): "coffee shops here tend to attract morning users aged 25-40 with high openness scores." Uses DP-protected aggregate statistics, never individual user data |
| 1.5C.4 | **Business cold-start-to-useful metric.** Track: how many patron interactions until the business-side energy function predicts patron engagement better than category average? Target: < 30 patron visits |

#### 1.5D Pre-Seeded Global Model

| Task | Description |
|------|-------------|
| 1.5D.1 | **Pre-train energy function from Big Five OCEAN dataset.** The `data/raw/big_five.csv` dataset (100k+ real personality profiles) provides population-level correlations between personality dimensions and preference patterns. Pre-train the energy function on simulated `(personality_state, action_category) → predicted_preference` tuples derived from this data. This means Day 1 users get a model that already understands personality-to-preference mapping at a population level, NOT a random model |
| 1.5D.2 | **Pre-train transition predictor from longitudinal personality data.** If the Big Five dataset includes temporal data (personality change over time), use it to pre-train the transition predictor's personality evolution dynamics. Even coarse population-level evolution rates ("openness tends to increase in users aged 20-30") are better than random initialization |
| 1.5D.3 | **Ship pre-trained model weights in app binary.** The pre-trained energy function and transition predictor weights ship with the app (part of the ~1MB ONNX model budget from Appendix D). Every new install starts with a globally-informed model, not a blank slate. On-device training personalizes from there |
| 1.5D.4 | **Federated global model updates.** As the user base grows, the federated aggregation server (Phase 8.1.3) produces improved global model weights. New installs receive the LATEST global model (via app update or cloud sync), which encodes collective learning from all prior users. This is the mechanism by which user #100,000 benefits from user #1's learning |

### 1.6 Quick-Win Data & Model Improvements (Tier 1-3 from Roadmap)

These are high-ROI items from the ML Roadmap (Section 17, Tiers 1-3) that can start immediately and directly improve data quality for all downstream world model training. They don't require the world model architecture -- they fix the existing pipeline.

**Tier 1: Highest ROI, Do Now**

| Task | Description | Effort |
|------|-------------|--------|
| 1.6.1 | **Run OSM spot data pipeline:** Execute the existing OSM data pipeline to retrain models on real spot data instead of synthetic. Pipeline is built but has never been run. Every downstream model improves | 1 day |
| 1.6.2 | **Wire `FeedbackProcessor` to `ContinuousLearningSystem`:** `FeedbackProcessor` exists but `_savePreferences` and `_applyModelUpdates` are stubs. Wire explicit user feedback (love/like/dislike/hate) into `ContinuousLearningSystem.processUserInteraction()` so it reaches the learning pipeline. **Integration note:** `FeedbackProcessor` (`lib/core/ml/feedback_processor.dart`) takes `User` + `Spot` objects; `processUserInteraction` takes `userId` + `payload` Map. Build an adapter that translates `FeedbackType` → payload format: `{'event_type': 'explicit_feedback', 'feedback': 'love/hate', 'spot_id': spot.id, ...}` | 1-2 days |
| 1.6.3 | **Build monthly batch retraining pipeline:** Pull collected data from Supabase (already agent-ID pseudonymized), merge with synthetic data for coverage, retrain calling score + outcome prediction models. Ship updated models via app update or on-device download | 2-3 days |
| 1.6.4 | **Add `community_join` and `event_attend` interaction types:** Enable cross-domain learning in `ContinuousLearningSystem` (also covered by 1.2.5 but tracked here as a quick win) | 1 day |
| 1.6.5 | **Round-trip consistency test (Python vs. Dart):** Verify that Python training feature extraction and Dart inference feature extraction produce identical outputs on the same inputs. Prevents silent inference bugs | 0.5 day |

**Tier 2: Meaningful Improvements**

| Task | Description | Effort |
|------|-------------|--------|
| 1.6.6 | **Add cross-features to calling score model:** User dimension × Spot dimension product features (user_i * spot_i). Free accuracy improvement, no architecture change needed | 1 day |
| 1.6.7 | **Calibration testing + temperature scaling:** Plot reliability diagram, apply temperature scaling. Ensures prediction probabilities are meaningful. A model predicting 0.7 should be right 70% of the time | 1 day |
| 1.6.8 | **Stratified evaluation:** Break test set performance by user archetype (Explorer/Connector/Creator), spot category (Food/Nightlife/Attractions), and time context (Morning/Evening/Night). Reveals where model systematically fails | 0.5 day |
| 1.6.9 | **Generalize `opportunity_id` before cloud upload:** Replace exact spot IDs with `spot_category + city_region` to prevent re-identification (privacy hardening) | 0.5 day |
| 1.6.10 | **Fix `CloudIntelligenceSync` user_id → agent_id:** Currently queries by `user_id` instead of `agent_id`, breaking the anonymization boundary | 0.5 day |
| 1.6.11 | **Activate Laplace noise:** Replace uniform noise in `UserVibe.fromPersonalityProfile` with the already-stubbed `_generateLaplaceNoise`. Calibrate epsilon = 1.0. Track cumulative privacy budget per user | 1 day |

**Tier 3: Competitive Upgrades**

| Task | Description | Effort |
|------|-------------|--------|
| 1.6.12 | **Multi-task learning:** Calling score + outcome prediction with shared encoder. Better representations from dual supervision signal | 2-3 days |
| 1.6.13 | **Category affinity tracking:** Track user affinity across spot/community/event categories. Explicit cross-domain signal for world model training | 2-3 days |
| 1.6.14 | **Two-tower user/spot embedding model:** Replace 39D concatenated input with separate user tower (user_12D + history_6D + cross-app → 32D) and spot tower (spot_12D + metadata → 32D). Score via dot product. Scales to millions of spots. Industry-standard architecture (YouTube, TikTok, Pinterest) | 1-2 weeks |

> **ML Roadmap Reference:** Section 17, Tiers 1-3. These items are foundational -- world model training quality depends directly on data quality. Items 1.6.9, 1.6.10, 1.6.11 are also privacy fixes identified in Section 9.3 of the roadmap.

### 1.7 Organic Spot Discovery (Behavioral Location Learning)

Learns meaningful locations from user behavior that don't exist in any external database (Google Places, Apple Maps, OSM). When users repeatedly visit unregistered locations (hidden parks, garages, rooftops, informal gathering places), the system clusters these visits, infers a category, and surfaces discovery candidates. This is the "the system learns places from how people live" pipeline.

**Philosophy:** "Every spot is a door." These are doors that haven't been named yet. The system discovers them organically -- never forces creation, just surfaces the insight and lets the user decide.

**Why in Phase 1:** This is behavioral data infrastructure. It produces learning signals (new episodic tuples, personality evolution events) and feeds the outcome collection pipeline. It doesn't require the world model (Phases 3-6) -- it works with the existing learning systems and enriches the data foundation.

**Status:** 🟡 In Progress (core service + model + integrations implemented)

| Task | Description | Status |
|------|-------------|--------|
| 1.7.1 | **`DiscoveredSpotCandidate` model.** Data structure for organically discovered locations with lifecycle states (detecting → ready → prompted → created/dismissed), inferred categories from timing/dwell/group patterns, confidence scoring, geohash clustering, and round-trip JSON serialization. Located at `lib/core/models/discovered_spot_candidate.dart` | ✅ Complete |
| 1.7.2 | **`OrganicSpotDiscoveryService`.** Core service that detects, clusters, and manages discovered spot candidates. Geohash precision 7 (~153m) for clustering. Confidence calculation from visit count, unique mesh users, group visits, and timing consistency. Category inference from time slot, dwell time, day of week, and group size. Located at `lib/core/services/places/organic_spot_discovery_service.dart` | ✅ Complete |
| 1.7.3 | **Integration: `LocationPatternAnalyzer` → `OrganicSpotDiscoveryService`.** When `recordVisit()` finds no matching place (placeId == null), forward the unmatched visit to the discovery service. This is the primary entry point for organic discovery -- it catches every visit to an unregistered location | ✅ Complete |
| 1.7.4 | **Integration: AI2AI mesh sharing.** `ConnectionOrchestrator` sends anonymized discovery signals (geohash + visit count only, never raw GPS or user ID) to nearby devices via `AnonymousCommunicationProtocol`. Receiving AIs boost confidence for the same geohash cluster, enabling community-validated discoveries | ✅ Complete |
| 1.7.5 | **Integration: `ContinuousLearningSystem`.** Three new learning events: `organic_spot_discovered` (location intelligence boost), `organic_spot_created` (strong positive: recommendation accuracy, community evolution), `organic_spot_dismissed` (small negative: recommendation accuracy). These feed dimension updates into the personality evolution pipeline | ✅ Complete |
| 1.7.6 | **Integration: `PersonalityLearning`.** New `UserActionType.organicSpotCreation` triggers personality dimension updates: `exploration_eagerness` +0.15, `curation_tendency` +0.12, `authenticity_preference` +0.08, `community_orientation` +0.06. Confidence boost: 1.5x for exploration, 1.3x for curation, 1.2x for authenticity | ✅ Complete |
| 1.7.7 | **Integration: `ContextEngine` + `ListGenerationContext`.** Discovered spot candidates flow into the perpetual list context so the recommendation engine can surface "save this place?" prompts. `ListGenerationContext` extended with `discoveredSpotCandidates` field | ✅ Complete |
| 1.7.8 | **Integration: `injection_container.dart`.** `OrganicSpotDiscoveryService` registered as lazy singleton with `AtomicClockService` dependency | ✅ Complete |
| 1.7.9 | Unit tests for `DiscoveredSpotCandidate` model: round-trip JSON, threshold logic (`isReadyToSurface`), `copyWith`, equality, `categoryDescription` | Unassigned |
| 1.7.10 | Unit tests for `OrganicSpotDiscoveryService`: `processUnmatchedVisit` (new cluster creation, existing cluster update, dwell time filtering), `processMeshDiscoverySignal` (confidence boosting, threshold transitions), confidence calculations, category inference, status transitions | Unassigned |
| 1.7.11 | Integration tests: `LocationPatternAnalyzer` → `OrganicSpotDiscoveryService` flow (unmatched visit forwarding, error resilience) | Unassigned |
| 1.7.12 | **Episodic tuple recording.** When a candidate transitions to `ready` or `created`, write an episodic tuple: `(user_state, discover_spot/create_spot, candidate_features, discovery_outcome)`. This feeds the energy function (Phase 4) with organic discovery training data | Unassigned |
| 1.7.13 | **UI: Discovery prompt card.** Minimal-friction UI card in the perpetual list or spot detail view: "You keep coming back here. Want to save this place?" with one-tap create or dismiss. Must use `AppColors`/`AppTheme` design tokens. Follows the "doors" pattern -- never forces creation | Unassigned |
| 1.7.14 | **Reverse geocoding enrichment.** When a candidate reaches `ready` status, attempt reverse geocoding via `PlacesDataSource` to populate `suggestedName` and `suggestedAddress`. Falls back gracefully if offline | Unassigned |
| 1.7.15 | **Locality agent ↔ organic discovery bidirectional feed.** Connect organic discovery signals to locality agents (Phase 8.2). When `OrganicSpotDiscoveryService` detects a new cluster, forward the geohash + category + confidence to the locality agent for that geohash region. The locality agent uses this to update its vibe vector (e.g., if many users are discovering informal music venues in a neighborhood, the locality's "arts & culture" vibe weight increases). Reverse direction: when a locality agent has a strong vibe signal in a category but the local spot database is sparse for that category, signal `OrganicSpotDiscoveryService` to LOWER the confidence threshold for candidates in that category in that region. This creates a "the neighborhood knows it's a music district, but the map doesn't have the venues yet" pattern | Extends Phase 8.2, `LocalityAgentEngineV1` |
| 1.7.16 | **Organic discovery → community suggestion pipeline.** When an organic spot candidate is created by multiple users (3+ unique users via mesh validation), and those users are not already in a shared community, suggest a community formation: "Several people who visit [discovered spot] share similar vibes. Want to start a community?" This uses `KnotFabricService` to verify the potential members have compatible knots BEFORE suggesting. Wire as a `ContextEngine` signal that the MPC planner (Phase 6) can act on | New |

> **Plan Document:** `docs/plans/organic_spot_discovery/ORGANIC_SPOT_DISCOVERY_PLAN.md`
> **Integration Points:** LocationPatternAnalyzer (entry), ConnectionOrchestrator (mesh), ContinuousLearningSystem (learning events), PersonalityLearning (personality evolution), ContextEngine (recommendations), PerpetualListOrchestrator (surfacing), LocalityAgentEngineV1 (locality vibe feed)
> **Privacy:** Only geohash + visit count shared over mesh. Never raw GPS, user identity, or visit timing.

---

## Phase 2: Privacy, Compliance & Legal Infrastructure

**Tier:** 0 (Blocks business features; legal necessity)  
**Duration:** 3-4 weeks  
**Dependencies:** None (runs parallel with Phase 1)  
**Why:** The ML Roadmap (Section 13) identified that GDPR compliance is a legal requirement, not a policy decision. The legacy plan incorrectly marked Operations & Compliance as "policy-gated."

### 2.1 GDPR Compliance (Non-Negotiable)

| Task | Description | Status |
|------|-------------|--------|
| 2.1.1 | Account deletion with complete data purge (including episodic memory, knot data, quantum states) | Required |
| 2.1.2 | Data export (all personal data in machine-readable format) | Required |
| 2.1.3 | Opt-in consent for all data collection (granular: personality learning, outcome tracking, AI2AI sharing, cross-app) | Partially exists (`CrossAppConsentService`) |
| 2.1.4 | Consent revocation with data cleanup | Required |
| 2.1.5 | Data retention policies (automated cleanup after configurable periods) | Required |
| 2.1.6 | Consent UX: progressive consent during onboarding (ask for personality learning first, defer AI2AI/cross-app/wearable consent until relevant) | New |
| 2.1.7 | Consent management page: view all current consents, revoke individually, see what data each consent covers | New |
| 2.1.8 | **Data transparency UI: "What My AI Knows" page.** Show user-friendly summary of what the world model has learned. NOT raw data -- translated summaries. Sections: (a) "Your interests" -- top 5 inferred categories with confidence bars (e.g., "Coffee shops: very confident, Jazz: learning"), (b) "Activity patterns" -- weekly interaction heatmap (when you're most active, zero PII), (c) "Learning progress" -- how many interactions the AI has learned from, what it's still uncertain about. All data derived from `PersonalityLearning` + `WorldModelFeatureExtractor` + Phase 6.2.10 domain uncertainty. No raw episodic tuples ever shown to user | New |
| 2.1.8A | **"Why this recommendation?" tap-through.** On any recommendation card, a small (i) icon expands to show a 1-sentence explanation: "Suggested because you enjoy [category] and this spot matches your [dimension] vibe." Uses Phase 4.6.1 feature attribution to generate explanations. Template-based (not LLM-generated) for privacy and speed. Never reveals other users' data. Examples: "Based on your visits to similar spots," "Popular with people who share your interests," "New in your area" | Extends Phase 4.6.1 |
| 2.1.8B | **Data correction mechanism.** If a user sees an incorrect inference in "What My AI Knows" (e.g., "The AI thinks I like nightclubs but I don't"), provide a "That's not right" button that: (a) records an explicit negative signal for that category (10x weight, Phase 1.4.9), (b) temporarily increases exploration in that category to recalibrate (Phase 6.2.9), (c) shows "Got it, I'll adjust" confirmation. This closes the feedback loop between transparency and learning | New |
| 2.1.8C | **Admin data transparency dashboard.** Extend `AdminSystemMonitoringService` with aggregate transparency metrics: how many users view "What My AI Knows" page, how often "That's not right" is triggered (signals model confusion at scale), which categories have highest uncertainty across user base. All aggregate, never individual-user | Extends `AdminSystemMonitoringService` |
| 2.1.9 | Consent-revocation world model handling: when user revokes outcome tracking, purge their episodic memory; DP guarantee means existing model weights are safe | New |

### 2.2 Differential Privacy for World Model

| Task | Description | Extends |
|------|-------------|---------|
| 2.2.1 | Implement Laplace noise injection for gradient sharing (federated learning) | Extends `FederatedLearning` |
| 2.2.2 | Validate `LocationObfuscationService` precision levels (~1km city, ~500m noise) against GDPR requirements | Existing service |
| 2.2.3 | Implement privacy budget tracking (epsilon accounting per user) | New |
| 2.2.4 | Audit `ThirdPartyDataPrivacyService` for world model compatibility | Existing service |

### 2.3 Operations & Compliance (from legacy Phase 5)

| Task | Description | Legacy Ref |
|------|-------------|------------|
| 2.3.1 | Refund policy implementation | Legacy 5.x |
| 2.3.2 | Tax compliance (sales tax calculation -- `SalesTaxService` exists) | Existing |
| 2.3.3 | Fraud prevention (`FraudDetectionService`, `ReviewFraudDetectionService` exist) | Existing |
| 2.3.4 | Terms of Service and legal document management (`LegalDocumentService` exists) | Existing |

### 2.4 Signal Protocol Default Activation

Signal Protocol is fully implemented but not yet the default. Activating it is a privacy upgrade that also enables trust features for the world model (Phase 3).

| Task | Description | Extends |
|------|-------------|---------|
| 2.4.1 | Flip `MessageEncryptionService` default from AES-256-GCM to Signal Protocol for all 5 chat services | Extends `SignalProtocolEncryptionService` |
| 2.4.2 | Implement Signal session migration: existing AES conversations → Signal sessions (users re-verify) | New |
| 2.4.3 | Verify `FriendChatService`, `CommunityChatService`, `PersonalityAgentChatService` work with Signal Protocol default | Existing services |
| 2.4.4 | Verify `BusinessExpertChatServiceAI2AI`, `BusinessBusinessChatServiceAI2AI` work with Signal Protocol via `AnonymousCommunicationProtocol` | Existing services |
| 2.4.5 | Key verification UX: allow users to verify each other's identity keys (QR code or safety number comparison) | New |
| 2.4.6 | Add `SignalProtocolService.getSessionStats()` API: returns aggregate metadata (active session count, average session age, verified session count) without exposing session keys or encryption internals. Required by state encoder (Phase 3.1.14) | Extends existing |

### 2.5 Post-Quantum Cryptography Hardening

PQXDH (hybrid X3DH + ML-KEM/Kyber) is already implemented and REQUIRED in `SignalProtocolService` -- every session establishment validates Kyber prekeys are present (`code: 'PQXDH_REQUIRED'`). The `SignalKeyManager` generates, stores, rotates, and validates Kyber prekeys via libsignal-ffi. The `SignalFFIBindings` has full Kyber FFI bindings (key generation, serialization, signing, PreKeyBundle creation with Kyber fields).

**What's already done:** Session-level post-quantum protection for all new Signal Protocol sessions. An attacker with a future quantum computer who recorded the key exchange CANNOT derive the session key because the Kyber KEM component is quantum-resistant.

**What's NOT done:** The gaps below. These are security hardening tasks that close remaining attack surfaces a quantum adversary could exploit.

| Task | Description | Priority | Extends |
|------|-------------|----------|---------|
| 2.5.1 | **Audit existing sessions for PQXDH coverage.** Any Signal sessions established BEFORE Kyber prekeys were available lack post-quantum protection. Implement `SignalSessionManager.auditPQXDHCoverage()`: scan all active sessions, flag any that were established without Kyber KEM material. For flagged sessions, schedule automatic re-keying (trigger new X3DH+PQXDH handshake) within 7 days. Log audit results to `AIImprovementTrackingService` | HIGH -- "harvest now, decrypt later" attacks mean old sessions are vulnerable today | Extends `SignalSessionManager` |
| 2.5.2 | **Kyber prekey rotation hardening.** Current rotation interval is 12 hours (`_preKeyRotationInterval`). For post-quantum security, Kyber prekeys should rotate independently from signed prekeys because Kyber key generation is cheaper and more frequent rotation limits the window of vulnerability. Implement separate rotation schedule: Kyber prekeys every 6 hours, signed prekeys every 12 hours. Track rotation health in `SignalKeyManager` diagnostics | HIGH -- shorter Kyber rotation window reduces exposure | Extends `SignalKeyManager` |
| 2.5.3 | **Kyber prekey exhaustion monitoring.** If a device's Kyber one-time prekeys are exhausted on the server (all consumed by incoming session requests), new sessions fall back to signed-prekey-only mode, which is NOT post-quantum secure. Implement `SignalKeyManager.monitorKyberPreKeyInventory()`: when Kyber prekey count on server drops below threshold (e.g., 5 remaining), proactively generate and upload more. Alert via agent trigger system (Phase 7.4) if replenishment fails | HIGH -- prekey exhaustion silently degrades quantum security | Extends `SignalKeyManager` |
| 2.5.4 | **Post-quantum security for BLE mesh transport.** Signal Protocol over BLE mesh (Phase 6.6) inherits PQXDH protection because the transport layer is transparent to encryption (Phase 6.6.5). HOWEVER, the BLE advertisement data used by `DeviceDiscoveryService` and `AnonymousCommunicationProtocol` for initial device discovery is NOT encrypted with post-quantum algorithms. An attacker who can record BLE advertisements and later break ECDH can correlate device identities. Implement: use Kyber-encapsulated session tokens in BLE handshake metadata. This ensures the initial BLE connection establishment is also quantum-resistant, not just the subsequent Signal Protocol session | MEDIUM -- BLE discovery is a separate attack surface | Extends `AnonymousCommunicationProtocol` |
| 2.5.5 | **Post-quantum security for federated gradient sharing.** Federated learning gradient transfers (Phase 8.1) use the AI2AI Protocol over BLE mesh. Gradients are anonymized via differential privacy (Phase 2.2.1), but the transport encryption for gradient payloads must also be post-quantum. Verify that gradient sharing uses Signal Protocol sessions (which have PQXDH). If gradient sharing uses a separate channel (e.g., raw BLE data transfer for bandwidth), implement Kyber-based key encapsulation for that channel | MEDIUM -- gradients contain model update information | Extends `FederatedLearning` |
| 2.5.6 | **Post-quantum security for Supabase cloud transport.** All cloud data sync (`BackupSyncCoordinator`, `SupabaseService`) currently relies on TLS 1.3 for transport encryption. TLS 1.3's key exchange uses ECDHE, which is vulnerable to quantum attack. Track Supabase/PostgreSQL adoption of post-quantum TLS (ML-KEM in TLS 1.3 is standardized as of 2024). When available, enable PQ-TLS for all Supabase connections. Until then, ensure sensitive data (episodic memory, personality states) is encrypted at the application layer BEFORE cloud upload using a locally-derived key, so even a TLS compromise reveals only ciphertext | MEDIUM -- cloud transport is a "harvest now, decrypt later" target | Extends `BackupSyncCoordinator` |
| 2.5.7 | **Quantum-safe key derivation for on-device storage.** `FlutterSecureStorage` (used by `SignalKeyManager` for identity keys, prekeys) relies on platform keychain (iOS Keychain, Android Keystore). These use AES-256 for encryption at rest, which IS quantum-resistant (Grover's algorithm reduces AES-256 to ~AES-128 security, still considered safe). Verify: no on-device encryption uses RSA or ECC for key wrapping. If any does, replace with AES-256-KW or HKDF-based derivation | LOW -- AES-256 at rest is quantum-safe, but verify no RSA/ECC key wrapping exists | Audit |
| 2.5.8 | **Post-quantum readiness dashboard.** Add a diagnostic endpoint (admin-only, not user-facing) that reports: (a) % of active sessions with PQXDH coverage, (b) Kyber prekey inventory health, (c) BLE mesh PQ status, (d) Cloud transport PQ status, (e) On-device storage PQ status. Wire into `AdminSystemMonitoringService`. Target: 100% PQXDH session coverage within 30 days of Phase 2.5 completion | LOW -- monitoring, not protection | New |

> **Why this matters NOW, not later:** The "harvest now, decrypt later" attack means adversaries can record encrypted traffic TODAY and decrypt it YEARS from now when quantum computers are available. Signal Protocol sessions, BLE advertisements, and cloud API calls recorded today are all vulnerable if they used ECDH-only key exchange. PQXDH protects against this for Signal sessions, but the other transport layers (BLE discovery, cloud TLS, gradient sharing) need the same treatment. This is the one quantum-related priority that has a deadline driven by attackers, not by your feature roadmap.

---

## Phase 3: World Model State & Action Encoders + List Quantum Entity

**Tier:** 1 (Core intelligence)  
**Duration:** 5-6 weeks  
**Dependencies:** Phases 1 and 2 complete  
**ML Roadmap Reference:** Section 15.2 (Networks 1 & 2), Section 7.4.2

### 3.1 Unified Feature Extraction Pipeline

Build the service that collects ALL features from existing systems into a single feature vector for the world model.

| Task | Feature Source | Dimensions | Existing Service |
|------|--------------|------------|------------------|
| 3.1.1 | Quantum vibe state (real + imaginary per dimension) | 24D | `QuantumVibeEngine` |
| 3.1.2 | Personality knot invariants (crossing, writhe, bridge, unknotting, Jones coefficients) | 5-10D | `PersonalityKnotService` |
| 3.1.3 | Fabric invariants (stability, density, crossing, cluster features) | 5-10D | `KnotFabricService` |
| 3.1.4 | Decoherence pattern features (phase, rate, stability) | 5D | `DecoherenceTrackingService` |
| 3.1.5 | Worldsheet trajectory features (evolution rate, stability trend, density rate) | 5D | `WorldsheetAnalyticsService` |
| 3.1.6 | Locality agent vector (12D context vibe) | 12D | `LocalityAgentEngineV1` |
| 3.1.7 | Temporal features (time of day, day of week, recency, session duration) | 5D | `AtomicClockService` |
| 3.1.8 | String evolution rates (Jones rate, crossing rate, stability rate) | 5D | `KnotEvolutionStringService` |
| 3.1.9 | Entanglement correlations (compressed from 66 pairs) | 10D | `QuantumEntanglementMLService` |
| 3.1.10 | Wearable data features (heart rate variability, activity, sleep -- optional) | 3D | `WearableDataService` |
| 3.1.11 | Cross-app context (with consent -- app usage patterns) | 3D | `CrossAppLearningInsightService` |
| 3.1.12 | Behavioral trajectory (exploration/settling/settled phase, momentum) | 5D | `BehaviorAssessmentService` |
| 3.1.13 | Language profile features (word diversity, emotional tone, formality, vocabulary richness) | 4D | `LanguagePatternLearningService` |
| 3.1.14 | Signal Protocol trust features (active session count, average session age, key verification status) | 3D | `SignalProtocolService` |
| 3.1.15 | Chat activity features (messages sent per day, unique conversations, community chat participation rate) | 3D | Chat services (metadata only) |
| 3.1.16 | **List engagement features:** number of lists created, average list size, list modification frequency, list category diversity (entropy), list sharing rate, total list followers, public vs. private ratio | 7D | `PerpetualListOrchestrator` + `SpotList` model |
| 3.1.17 | **Active list composition summary:** mean quantum vibe vector across user's active lists (computed from member spots), weighted by recency. This gives the state encoder a compressed view of what the user's curated taste looks like RIGHT NOW | 12D | Computed from `SpotList` members via `QuantumVibeEngine` |
| 3.1.18 | **Business account features (for business entity states):** patron preferences summary (preferred vibe dimensions, preferred expertise categories, preferred patron demographics), partnership history (active partnerships count, avg partnership duration, partnership success rate), event hosting frequency, reservation volume, business verification status, business category | 10D | `BusinessAccount` + `BusinessPatronPreferences` + `PartnershipService` |
| 3.1.19 | **Brand/sponsor features (for brand entity states):** sponsorship history (events sponsored count, avg contribution, success rate), brand values alignment vector (from `BrandAccount`), category coverage, reach metrics, renewal rate | 8D | `BrandAccount` + `SponsorshipService` |

**Total state vector: ~145-155D** (vs. raw 12D personality dimensions today. Includes user features ~125D + business entity features ~10D + brand entity features ~8D. Not all features apply to all entity types -- business/brand features are only used when scoring business/brand entity states)

> **Privacy note:** Chat features are derived from metadata counts and patterns only. NO message content, encryption keys, or plaintext ever enters the feature pipeline. Signal Protocol features are derived from the session store, not from decrypted messages.

| Task | Description |
|------|-------------|
| 3.1.20 | Implement `WorldModelFeatureExtractor` service that collects all above features into a single `StateFeatureVector` | 
| 3.1.21 | Implement feature normalization (all features → 0.0-1.0 range) |
| 3.1.22 | Implement feature caching (recompute only changed features) |
| 3.1.23 | Register in DI, wire into `DeferredInitializationService` for warm-up |

### 3.1A Feature Freshness Lifecycle

In LeCun's framework, the world model's predictions are only as good as its observation of current state. Stale features = inaccurate state = wrong energy scores. Each feature group updates at a different rate; the state encoder must know which features are fresh.

| Task | Description |
|------|-------------|
| 3.1A.1 | Define per-feature-group staleness tolerances: temporal (1s), personality/quantum (5s), knot/fabric/decoherence (5min via `UnifiedEvolutionOrchestrator`), wearable (1hr), cross-app (1day), language profile (1hr), Signal trust (1day) |
| 3.1A.2 | Implement `FeatureFreshnessTracker`: each feature slot in `StateFeatureVector` carries a `last_updated` timestamp (using `AtomicClockService`) |
| 3.1A.3 | Implement freshness-weighted encoding: the state encoder receives a per-feature freshness weight (1.0 = fresh, decays toward 0.0 as staleness grows). This lets the model learn to rely less on stale features rather than treating old data as current truth |
| 3.1A.4 | Implement proactive refresh: when a feature group exceeds 2x its staleness tolerance, trigger a targeted refresh from that service (not a full re-extraction) |
| 3.1A.5 | Track feature staleness metrics: which features are most frequently stale? Which features cause the most energy function prediction errors when stale? Use to prioritize refresh scheduling |

### 3.2 State Encoder Network

| Task | Description |
|------|-------------|
| 3.2.1 | Design state encoder architecture: `StateFeatureVector (145-155D) → MLP → Embedding (32-64D)` |
| 3.2.2 | Implement ONNX model for state encoding (extend `InferenceOrchestrator`) |
| 3.2.3 | Implement fallback: if ONNX model not loaded, use raw features (graceful degradation) |
| 3.2.4 | Add to `DeferredInitializationService` startup sequence (after feature extractor) |

### 3.3 Action Encoder Network

| Task | Description |
|------|-------------|
| 3.3.1 | Define action taxonomy: visit_spot, attend_event, join_community, connect_ai2ai, save_list, **create_list**, **modify_list**, **share_list**, create_reservation, message_friend, message_community, ask_agent, host_event, **browse_entity**, **intent_transition**, **initiate_business_outreach**, **propose_sponsorship**, **form_partnership**, **engage_business** (expanded taxonomy includes list actions from Phase 1.2.8-1.2.10, browse from 1.2.19, intent transitions from 1.2.26A, and business/sponsorship actions from 1.2.21-1.2.26) |
| 3.3.2 | **Spot features:** vibe dimensions, category, price tier, popularity (visit count), geographic features (geohash, neighborhood), operating hours, accessibility, rating stats |
| 3.3.3 | **Event features:** event type, host expert score, ticket price tier, expected attendance, timing features (day of week, time of day, duration), community affiliation, recurrence pattern |
| 3.3.4 | **Community features:** `KnotFabricService` invariants (stability, density, crossing), member count, activity rate, worldsheet evolution trajectory, age |
| 3.3.5 | **Connection features:** partner's quantum vibe compatibility, knot similarity, entanglement correlation, AI2AI discovery quality scores, prior interaction history length |
| 3.3.6 | **Reservation features:** slot time, party size, spot vibe match, historical no-show rate for this (user, spot) pair, price tier |
| 3.3.7 | **Chat features (metadata only, never content):** message frequency (msgs/day), active conversation count, recency of last message, Signal Protocol session age (trust proxy), community chat participation rate |
| 3.3.8 | **List features (for `save_list`, `create_list`, `modify_list`, `share_list` actions):** list composition vector (avg vibe of included spots across all 12 quantum dimensions), category diversity (Shannon entropy over spot categories), geographic spread (convex hull area of spot locations in geohash space), price range (min/max/mean tier), item count, list age (days since creation), modification frequency (edits/week), collaboration count, follower count, public/private flag, user's tags/purpose text embedding (if SLM available, else bag-of-words). **Why this matters:** A list IS a compressed preference manifold -- a user's curated list is literally their taste function sampled at specific spots |
| 3.3.9 | **List composition quantum state:** For each list, compute a composite quantum vibe by averaging the quantum entity states of its member spots. This gives the list a position in the same 12D vibe space as individual spots, enabling direct compatibility comparison via `VibeCompatibilityService` against user state |
| 3.3.10 | **Browse features (for `browse_entity` action):** browsed entity type, view duration (seconds), scroll depth (% of detail page viewed), number of images viewed, time of day, was this entity recommended or organically discovered, context (from search, from list, from map, from feed) |
| 3.3.10A | **Intent transition features (for `intent_transition` action):** transition direction (`passive_to_active` or `active_to_passive`), entity type, entity category, time-to-transition, prior recommendation source, intermediate touches count, and whether the transition followed explicit feedback vs implicit behavior. These features let the world model learn activation windows ("user warms up after 2 passive touches") and cooling patterns ("active last month, passive this week") |
| 3.3.11 | Design action encoder: `ActionType + EntityFeatures → MLP → Embedding (32-64D)` |
| 3.3.12 | Implement ONNX model for action encoding |
| 3.3.13 | Wire community fabric features into action encoder for `join_community` actions (uses `KnotFabricService`) |
| 3.3.14 | Wire worldsheet analytics into action encoder for group actions (uses `WorldsheetAnalyticsService`) |
| 3.3.15 | Wire list composition features into action encoder for all list actions. The encoder must handle variable-length lists (use attention-pooled spot embeddings or mean-pooled vibe vectors for the list composition input) |
| 3.3.16 | **Business-expert outreach features (for `initiate_business_outreach`, `form_partnership` actions):** business quantum state compatibility with expert, expertise category match, geographic proximity, partnership history between these entities (prior collaborations?), business patron preferences alignment with expert's audience, expert's golden expert score, event hosting track record |
| 3.3.17 | **Sponsorship features (for `propose_sponsorship` action):** brand quantum state compatibility with event, brand category overlap with event category, brand budget tier, historical sponsorship success rate for similar events, brand reach metrics, event expected attendance, contribution type (financial/product/hybrid) |
| 3.3.18 | **Business-patron engagement features (for `engage_business` action):** business quantum state compatibility with user, business category match with user preferences, geographic distance, reservation history at this business, price tier compatibility, vibe match between user and business's patron base |

### 3.4 List as Quantum Entity & World Model Participant

Lists are currently absent from the quantum/knot/fabric/worldsheet/string systems entirely. `QuantumEntityType` includes `expert`, `business`, `brand`, `event`, `user`, `sponsor` -- but NOT `list`. This section promotes lists to first-class entities in every representation layer.

**Why:** A curated list is a *compressed preference manifold*. It's not just a bag of spots -- it's a user's explicit statement of "these things belong together." That composition carries rich structural information: thematic coherence, geographic patterns, vibe gradients, and taste evolution over time.

| Task | Description | Extends |
|------|-------------|---------|
| 3.4.1 | **Add `list` to `QuantumEntityType` enum.** Update `quantum_entity_type.dart` to add `QuantumEntityType.list`. Set default weight 0.15 (same as user). Lists can participate in entanglement matching, meaning users can be matched to lists the way they're matched to events or spots | `QuantumEntityType` |
| 3.4.2 | **Implement `_convertListToQuantumState()` in `QuantumMatchingController`.** Compute list quantum state from: (a) mean-pooled quantum vibe vectors of member spots, (b) list metadata (category, tags, creation date), (c) curator personality state (if available). This gives lists a position in the same Hilbert space as users and spots | `QuantumMatchingController` |
| 3.4.3 | **Implement list PersonalityKnot.** A list's "personality" is defined by the invariants of its composition: crossing number (how diverse are the spots?), writhe (directional bias -- all similar or varied?), bridge number (minimum number of "category clusters"), Jones polynomial coefficients (algebraic topology of the list's vibe structure). Compute from member spot knots via `PersonalityKnotService` | `PersonalityKnotService` |
| 3.4.4 | **Implement list KnotFabric.** When multiple users collaborate on a list, or when a list has followers, the list develops a community-like structure. Model this as a KnotFabric where each strand is a contributor/follower knot. Fabric invariants (stability, density, crossing) describe the list's community health | `KnotFabricService` |
| 3.4.5 | **Implement list Worldsheet.** A list evolves over time as items are added/removed. Track the list's worldsheet: a 2D surface with time on one axis and list composition on the other. `WorldsheetEvolutionDynamics` can predict where a list's vibe is heading, enabling "this list is evolving toward jazz" predictions. Uses `WorldsheetAnalyticsService` pattern | `WorldsheetAnalyticsService` |
| 3.4.6 | **Implement list KnotString evolution.** As a list is modified over time, its knot invariants change. Track these changes as a KnotString -- a continuous curve in knot invariant space. Use `KnotEvolutionStringService` pattern. String evolution rate = how fast is the list's character changing? A rapidly evolving list means an actively refining taste profile | `KnotEvolutionStringService` |
| 3.4.7 | **Implement list decoherence tracking.** When list spots have inconsistent vibes (e.g., a "chill spots" list with one nightclub), that's decoherence. Use `DecoherenceTrackingService` pattern to track list coherence over time. High decoherence = user is exploring; low decoherence = clear taste signal | `DecoherenceTrackingService` |
| 3.4.8 | **Implement list entanglement with creator.** Compute entanglement correlation between list quantum state and creator personality state. High entanglement = list is a faithful expression of the creator's personality. Low entanglement = list might be aspirational (what the user wants to like) or utilitarian (planning purposes). Both are valuable training signals for different reasons | `QuantumEntanglementMLService` |
| 3.4.9 | **Wire list quantum states into `CrossEntityCompatibilityService`.** Enable user-to-list compatibility scoring. A user should see lists that match their personality quantum state, not just lists with popular spots | `CrossEntityCompatibilityService` |
| 3.4.10 | **Wire list states into `GroupMatchingService`.** When recommending group activities, suggest lists curated by community members. Use fabric compatibility between group entangled state and list quantum state | `GroupMatchingService` |
| 3.4.11 | **Implement `StringTheoryPossibilityEngine` for lists.** Generate multiple possible future states for a list: "if you keep adding spots like this, your list will evolve into X" or "this list is converging toward Y vibe." Uses the same latent variable sampling from variance head (Phase 5.1.7) applied to list quantum states | `StringTheoryPossibilityEngine` |
| 3.4.12 | **Implement list-to-list compatibility.** Two lists can be compatible (complementary vibes for a full day itinerary) or redundant (same vibe, different curator). Use inner product of list quantum states to measure compatibility. Wire into `ItineraryCalendarLists` feature (Phase 10.1.3) for multi-list combination recommendations | New |

> **Key insight:** Lists bridge the gap between individual preferences and community knowledge. A user's lists are their exported taste function. A community's lists are collective intelligence. By giving lists full quantum representation, the world model can learn from curation patterns -- not just consumption patterns.

> **Integration risk:** Adding `list` to `QuantumEntityType` changes the entity type set. All `switch` statements on `QuantumEntityType` will need a `case QuantumEntityType.list:` branch. Run a codebase-wide search for `QuantumEntityType` switch statements and update each.

### 3.5 Locality Agent Upgrade

| Task | Description | Extends |
|------|-------------|---------|
| 3.5.1 | Upgrade `LocalityAgentEngineV1` to produce features for state encoder (not just raw 12D vector) | Existing service |
| 3.5.2 | Add locality evolution rate (how fast is this area's vibe changing?) | New feature |
| 3.5.3 | Add community density feature (how many active communities in this geohash cell?) | New feature |
| 3.5.4 | Add event frequency feature (how many events in this area recently?) | New feature |

### 3.6 Latency Budgets & Performance Targets

The world model runs on-device. If it's slow, users won't wait and the app feels worse than the formula-based version.

| Task | Description | Target |
|------|-------------|--------|
| 3.6.1 | Define latency budget: feature extraction (state vector assembly from all services) | < 50ms |
| 3.6.2 | Define latency budget: state encoder ONNX inference | < 20ms |
| 3.6.3 | Define latency budget: action encoder ONNX inference | < 15ms |
| 3.6.4 | Define latency budget: energy function inference | < 10ms |
| 3.6.5 | Define latency budget: full recommendation scoring (state encode + N action encodes + N energy evals) | < 200ms for 50 candidates |
| 3.6.6 | Define latency budget: MPC planning (Phase 6) | < 500ms for 3-step horizon |
| 3.6.7 | Implement latency tracking in `PerformanceMonitorService` for each budget item |
| 3.6.8 | Implement device-capability-aware degradation: if `DeviceCapabilityService` reports < 3GB RAM, reduce candidate pool and planning horizon |
| 3.6.9 | Implement model size budget: all ONNX models combined < 20MB (fits comfortably on any device) |

> **Rule:** If any latency budget is exceeded in testing, that component must be optimized or simplified before it ships. Never trade UX responsiveness for model sophistication.

### 3.7 Mesh Communication Unification

The codebase has two independent mesh pathways: `AdvancedAICommunication` (used by `AIMasterOrchestrator`, `ContinuousLearningOrchestrator`) and `AnonymousCommunicationProtocol` (formal multi-hop privacy-preserving mesh). The world model needs one clear communication backbone -- LeCun's framework assumes a coherent information channel between agents.

| Task | Description |
|------|-------------|
| 3.7.1 | Audit all uses of `AdvancedAICommunication.sendEncryptedMessage()` -- catalog what data each orchestrator shares to `'ai_network'` |
| 3.7.2 | Define message type taxonomy for `AnonymousCommunicationProtocol`: `MessageType.chat` (existing), `MessageType.gradient` (Phase 8), `MessageType.insight` (learning insights), `MessageType.localityUpdate` (existing), `MessageType.expertiseAdvertisement` (Phase 8.5) |
| 3.7.3 | Migrate `AIMasterOrchestrator`, `ContinuousLearningOrchestrator`, and `UnifiedEvolutionOrchestrator` to use `AnonymousCommunicationProtocol` with appropriate `MessageType` instead of `AdvancedAICommunication` |
| 3.7.4 | Deprecate `AdvancedAICommunication` -- it becomes a thin wrapper around `AnonymousCommunicationProtocol` for backward compatibility, then is removed |
| 3.7.5 | Define per-message-type routing policy: chat uses multi-hop privacy routing, gradients use direct BLE (lower overhead), insights use single-hop (peer-to-peer), locality updates use broadcast |

> **LeCun alignment:** In the world model framework, all information between agents flows through a single "perception module." Unifying the mesh ensures the world model has one coherent view of what the network provides, rather than two competing channels with different reliability guarantees.

### 3.8 AI2AI Insight Extraction Upgrade

Upgrade the existing AI2AI learning pipeline to produce world-model-compatible features.

| Task | Description | Extends |
|------|-------------|---------|
| 3.8.1 | Upgrade `ConversationInsightsExtractor` to emit structured features (not just confidence-weighted dimension updates) | Extends existing |
| 3.8.2 | Define AI2AI insight feature schema: shared preference dimensions, conversation quality score, learning value, reciprocity measure | New |
| 3.8.3 | Wire AI2AI insights as optional state encoder features (available only for users with active AI2AI sessions) | New |
| 3.8.4 | Ensure `AI2AILearningOrchestrator` only feeds insights to world model after confidence threshold (currently >= 0.6, keep as initial value, learn from data later in Phase 4) | Extends existing |

---

## Phase 4: Energy Function & Formula Replacement

**Tier:** 1 (Core intelligence -- can run parallel with Phase 3 and 5)  
**Duration:** 6-8 weeks  
**Dependencies:** Phase 1 (outcome data required for training)  
**ML Roadmap Reference:** Section 7.4.5, Section 15.3

### 4.1 Energy Function (Critic Network)

The energy function replaces ALL hardcoded scoring formulas. It takes state embedding + action embedding → scalar energy (low = good match).

| Task | Description |
|------|-------------|
| 4.1.1 | Design critic architecture: `Concat(StateEmbed, ActionEmbed) → MLP(128→64→32→1) → Energy` |
| 4.1.2 | Implement ONNX critic model |
| 4.1.3 | Implement training loop: VICReg-regularized loss from episodic memory. **Variance:** ensure energy function uses all embedding dimensions (prevent collapse). **Invariance:** compatible pairs (good outcomes) → low energy, incompatible pairs (bad outcomes) → high energy. **Covariance:** embedding dimensions decorrelated. Positive examples from good outcome episodes, negative examples from bad outcome + contrastive episodes (Section 1.2.13). This follows LeCun's recommendation: "abandon contrastive methods in favor of regularized methods (VICReg)" |
| 4.1.4 | Implement `EnergyFunctionService` with inference API: `energy(user, entity) → double` |
| 4.1.5 | Implement parallel-run mode: compute both formula score AND energy score, log comparison |
| 4.1.6 | Implement A/B switch: feature flag per formula to swap from formula to energy function |
| 4.1.7 | **Implement asymmetric loss for negative outcome amplification.** The energy function's training loss must weight negative outcomes more heavily than positive ones (Phase 1.4.10). Implementation: `loss = MSE(predicted_energy, target_energy) * weight`, where `weight = 2.0` for negative-outcome pairs and `weight = 1.0` for positive-outcome pairs. The asymmetry factor (2.0) is stored in `FeatureFlagService` and tunable. Additionally, "model failure" tuples from Phase 1.4.11 (where the model's prediction was wrong) receive `weight = 3.0` -- these are the highest-value training signals because they represent the model's blind spots |
| 4.1.8 | **Energy function self-monitoring.** The energy function must track its own accuracy over time: (a) maintain a rolling 30-day accuracy metric (what % of low-energy predictions resulted in positive outcomes), (b) maintain per-category accuracy (the model may be accurate for "food" but inaccurate for "nightlife"), (c) when per-category accuracy drops below 60%, automatically increase exploration for that category (wired into Phase 6.2.10). This creates a self-correcting feedback loop: the energy function identifies its own weaknesses and triggers targeted data collection to fix them |
| 4.1.9 | **Conviction-aware energy regularizer.** Penalize overconfident low-energy recommendations when evidence coverage is weak or contradictory (`ConvictionLedger` conflict high, coverage low). Confidence must be earned by evidence depth, not score sharpness |
| 4.1.10 | **Cross-source robustness objective.** During training/evaluation, require gains to hold across internal-only, external-research-informed, and third-party-data-informed slices. Block promotion if lift depends on a single fragile source lane |
| 4.1.11 | **Contradiction stress testing for critic outputs.** Add adversarial replay sets where prior high-confidence predictions failed; require critic recalibration on these sets before promotion to keep conviction aligned with observed reality |

### 4.2 Formula Replacement Schedule

Each formula replacement follows the same protocol:
1. Log both formula and energy function outputs (parallel run)
2. Collect comparison data for N days
3. When energy function matches or beats formula on held-out outcomes, flip the feature flag
4. Keep formula as fallback for M weeks
5. Remove formula code

**Replacement Priority (ordered by impact and data availability):**

| Priority | Service | Formula | Current Weights |
|----------|---------|---------|-----------------|
| 4.2.1 | `CallingScoreCalculator` | Calling Score | 40/30/15/10/5 (vibe/betterment/connection/context/timing) |
| 4.2.2 | `VibeCompatibilityService` | Combined compatibility | 50/30/20 (quantum/topological/weave) |
| 4.2.3 | `VibeCompatibilityService` | Weave compatibility | 60/40 (crossing/polynomial) |
| 4.2.4 | `EventRecommendationService` | Exploration balance | 70/30 (familiar/explore) |
| 4.2.5 | `GroupMatchingService` | Group core + modifiers | geometric mean + 40/30/20/10 |
| 4.2.6 | `ReservationQuantumService` | Reservation compatibility | 40/30/20/10 |
| 4.2.7 | `RealTimeUserCallingService` | Real-time compatibility | 50/30/20/15 |
| 4.2.8 | `UserEventPredictionMatchingService` | Event prediction | 35/25/20/15/5 |
| 4.2.9 | `BusinessExpertMatchingService` | Expert matching | 50/30/20 (vibe/expertise/location) |
| 4.2.10 | `KnotFabricService` | Fabric stability | 40/30/30 (density/complexity/cohesion) |
| 4.2.11 | `CommunityService` | Community compatibility | 50/30/20 (quantum/topological/weaveFit) |
| 4.2.12 | `DiscoveryManager` | AI2AI discovery priority | 40/30/20/10 (basic/pleasure/learning/trust) |
| 4.2.13 | `ExpertiseMatchingService` | Expert match scoring | Hardcoded expertise match + complementary |
| 4.2.14 | `ExpertiseEventService` | Local expert priority | Hardcoded priority calculation |
| 4.2.15 | `ExpertSearchService` | Expert relevance | Hardcoded relevance scoring |
| 4.2.16 | `MultiPathExpertiseService` | 6 expertise paths | 40/25/20/25/15/varies |
| 4.2.17 | `SaturationAlgorithmService` | Saturation factors | 25/20/20/15/10/10 |
| 4.2.18 | `MeaningfulExperienceCalculator` | Timing flexibility | Thresholds 0.7/0.8/0.9, weights 40/30/20/10 |
| 4.2.19 | `SpotVibeMatchingService` | Spot matching | Hardcoded matching |
| 4.2.20 | `EventMatchingService` | Event matching signals | Hardcoded signals |
| 4.2.21A | `PartnershipMatchingService` | Partnership compatibility | 70% quantum / 30% classical hybrid, 70%+ threshold. Uses `VibeCompatibilityService` internally but adds its own quantum-classical blend weights. Delegates to `PartnershipService.calculateVibeCompatibility()` |
| 4.2.21B | `SponsorshipService` (via `VibeCompatibilityService.calculateEventBrandVibe()`) | Brand-event sponsorship compatibility | Hardcoded quantum/topological/weave scoring for brand-event pairs, 70%+ threshold |
| 4.2.21C | `BrandDiscoveryService` | Brand discovery scoring | Uses `SponsorshipService.calculateCompatibility()` + category/location filters. Has quantum matching behind feature flag `phase19_quantum_brand_discovery` but falls back to hardcoded classical |
| 4.2.21D | `BusinessBusinessOutreachService` | Business-business partnership scoring | Currently uses `BusinessAccountService` for discovery + basic compatibility. No formal scoring formula yet -- will need energy function from the start rather than replacing an existing formula |
| 4.2.21E | `BusinessExpertOutreachService` | Expert discovery for businesses | Currently **stubbed** (returns empty list). Must be implemented with energy function scoring rather than hardcoded formulas. Skip the intermediate hardcoded step -- go straight to energy function |

**Threshold Replacements (same protocol, different output):**

| Priority | Service | Threshold | Current Value |
|----------|---------|-----------|---------------|
| 4.2.21 | `PerpetualListOrchestrator` | List generation interval | 8hr min, max 3/day |
| 4.2.22 | `PerpetualListOrchestrator` | Personality drift limit | 30% max |
| 4.2.23 | `AutomaticCheckInService` | Check-in triggers | 50m radius, 5min dwell |
| 4.2.24 | `DynamicThresholdService` | Expertise thresholds | 0.7x-1.3x multiplier |
| 4.2.25 | `ContinuousLearningOrchestrator` | Confidence threshold | >= 0.6 |
| 4.2.26 | `SearchCacheService` | Cache expiry tiers | 15min/2hr/1day/7day |

### 4.3 Expert System Integration

The expert system has 7+ services with hardcoded formulas. These are integrated via the energy function.

| Task | Description |
|------|-------------|
| 4.3.1 | Wire expert reputation data (golden expert score, expertise level, path scores) as state encoder features |
| 4.3.2 | Wire geographic hierarchy data (neighborhood, locality, city) as action encoder features for expert matching |
| 4.3.3 | Add expert event outcome collector (did attendees return? did ratings improve? did the expert's reputation grow?) with detailed outcomes from Phase 1.2.20 (topic relevance, "would attend again", expertise level match) |
| 4.3.4 | Replace `ExpertiseEventService._calculateLocalExpertPriority()` with energy function |
| 4.3.5 | Close feedback loop: expert event outcomes → episodic memory → energy function training |
| 4.3.6 | **Expert-curated lists as authority signals.** When an expert creates a list of recommended spots, that list carries higher authority weight than a regular user's list. Wire expert verification status as a list metadata feature (Phase 3.3.8). The energy function should learn that expert-curated lists are more reliable training signals for spot quality |
| 4.3.7 | **Expert event → list conversion pipeline.** After a successful expert event (positive attendee outcomes), automatically suggest that the expert create a list of related spots. The list becomes a reusable knowledge artifact from the expert's domain expertise. Wire as `(expert_state, event_success, suggested_list_action)` training signal |

### 4.4 Community-Perspective Energy Function

The energy function scores `(individual_state, action) → energy`. But for group actions (`join_community`, `attend_event`, `connect_ai2ai`), the world model must also consider the entity's perspective. In LeCun's framework, this is a multi-agent extension: each entity has its own "cost module" (energy function) that evaluates whether an interaction is beneficial from its side.

| Task | Description |
|------|-------------|
| 4.4.1 | Implement bidirectional energy for `join_community`: evaluate BOTH `energy(user_state, join_community_X)` AND `energy(community_X_state, gain_member_user)`. Community state derived from `KnotFabricService` invariants (stability, density, crossing) |
| 4.4.2 | Implement bidirectional energy for `attend_event`: evaluate both user benefit AND event benefit (does this attendee improve event diversity? fill capacity? match host intent?) |
| 4.4.3 | Implement bidirectional energy for `connect_ai2ai`: evaluate both user learning value AND peer learning value (reciprocity -- in LeCun's framework, the world model predicts outcomes for BOTH agents) |
| 4.4.4 | **Implement bidirectional energy for `save_list` / `create_list`:** evaluate user benefit (does this list match their taste trajectory?) AND list/community benefit (does this follower add diversity or redundancy to the list's audience? Does this curator's expertise enrich the list's domain?). List state derived from list quantum state (Phase 3.4.2) + list KnotFabric invariants (Phase 3.4.4) + list worldsheet trajectory (Phase 3.4.5) |
| 4.4.5 | **Implement list-as-social-entity energy.** Public lists with followers are mini-communities. The energy function must protect list quality: if a modification would make a popular list's decoherence spike (Phase 3.4.7), the entity-side energy should increase (bad for list health). This prevents "taste pollution" where modifications degrade list coherence |
| 4.4.6 | Define community state encoder: `CommunityFeatures (fabric invariants + worldsheet trajectory + member stats + chat activity) → MLP → CommunityStateEmbed`. This is a smaller encoder than user state (fewer features) |
| 4.4.7 | **Define list state encoder:** `ListFeatures (list quantum state + knot invariants + fabric invariants + worldsheet trajectory + composition summary + engagement stats) → MLP → ListStateEmbed`. Reuses community encoder architecture but with list-specific feature groups |
| 4.4.8 | **Implement bidirectional energy for `business_expert_match`:** evaluate BOTH `energy(business_state, partner_with_expert_X)` AND `energy(expert_state, partner_with_business_Y)`. Business state from `BusinessAccount` quantum state + patron preferences + partnership history. Expert state from personality quantum state + expertise level + golden expert score. Both sides must benefit: the expert needs career growth/meaningful work, the business needs authentic expertise (not just a warm body). Uses `BusinessExpertMatchingService` hardcoded 50/30/20 as baseline to beat |
| 4.4.9 | **Implement bidirectional energy for `sponsor_event`:** evaluate BOTH `energy(brand_state, sponsor_event_X)` AND `energy(event_state, accept_sponsor_brand_Y)`. Brand state from brand quantum state + brand values + sponsorship history. Event state from event quantum state + host intent + attendee composition. The event side must evaluate: does this brand align with the event's vibe, or will it feel like an awkward ad? (Currently `SponsorshipService` only checks a single-direction 70%+ vibe threshold) |
| 4.4.10 | **Implement bidirectional energy for `business_business_partner`:** evaluate BOTH `energy(business_A_state, partner_with_business_B)` AND `energy(business_B_state, partner_with_business_A)`. Business-to-business partnerships should be symmetric: both sides must see value. Uses partnership history outcomes (Phase 1.2.24) to learn what makes partnerships work |
| 4.4.11 | **Define business state encoder:** `BusinessFeatures (business quantum state + patron preferences + expertise domain + partnership history + reservation patterns + location features) → MLP → BusinessStateEmbed`. Extends the entity state encoder pattern. Business quantum state already exists (`QuantumEntityType.business`) but isn't used for bidirectional energy |
| 4.4.12 | **Define brand state encoder:** `BrandFeatures (brand quantum state + brand values + sponsorship history + category alignment + reach metrics) → MLP → BrandStateEmbed`. Brand quantum state already exists (`QuantumEntityType.brand`) but isn't used for bidirectional energy |
| 4.4.13 | Define combined scoring: `final_energy = alpha * user_energy + (1 - alpha) * entity_energy`, where alpha is learned per action type (some actions are more about user benefit, others more about community/business health) |
| 4.4.14 | Guardrail: if `entity_energy` is very high (bad for the community/list/business/brand), override even if `user_energy` is low (good for user). Protect community, list, business, and brand health -- this is the "doors" philosophy: don't open one person's door by closing another's |

> **LeCun alignment:** LeCun's world model predicts future states for ALL agents, not just the ego agent. The transition predictor already predicts `next_user_state`; community energy requires predicting `next_community_state` when a member joins; business energy requires predicting `next_business_state` when a partnership forms. This uses the same transition predictor architecture with entity-specific state encoders. The multi-agent extension is critical for the business layer: unlike user-to-spot matching (one-sided), business partnerships and sponsorships are fundamentally bilateral -- both parties invest resources and expect returns.

### 4.5 Transition Period UX

Users will experience recommendations changing as the energy function replaces formulas. This must feel like improvement, not instability.

| Task | Description |
|------|-------------|
| 4.5.1 | Implement blending mode: during parallel-run phase, show results ordered by `alpha * formula + (1 - alpha) * energy`, where alpha decreases from 1.0 → 0.0 over the transition period |
| 4.5.2 | Implement surprise detection: if the energy function's top recommendations are dramatically different from the formula's, flag for manual review before flipping that formula |
| 4.5.3 | Implement user-facing "quality indicator": subtle UI signal showing the AI is learning (e.g., "Personalized for you" badge appears once energy function has sufficient data) |
| 4.5.4 | Implement rollback per-user: if a user's outcomes get worse after an energy function flip, automatically revert to formula for that user and flag for investigation |
| 4.5.5 | Monitor transition metrics: recommendation diversity change, outcome rate change, user retention change during each formula flip |
| 4.5.6 | **Agent happiness as energy function training signal.** The `AgentHappinessService` (Phase 8.9) produces a 0.0-1.0 happiness score per agent based on learning satisfaction and fulfillment satisfaction. Feed this as a training signal to the energy function: recommendations that INCREASE agent happiness (user follows suggestion → positive outcome → agent fulfillment rises) should receive lower energy (better) in future scoring. Recommendations that DECREASE agent happiness (user ignores suggestion or has bad outcome → agent frustration) should receive higher energy (worse). Implementation: after each happiness score update, backpropagate a reward signal to the energy function's training set: `(user_state_at_recommendation, recommended_action, delta_happiness)`. This creates a direct "agent happiness ↔ recommendation quality" feedback loop that doesn't exist if happiness only aggregates to localities |
| 4.5.7 | **Happiness-weighted exploration.** When an agent's happiness score drops below 0.5 for 7+ consecutive days, the energy function should automatically increase its exploration bonus for that user (wired into Phase 6.2.9-6.2.11). The reasoning: a persistently unhappy agent means the model is failing to serve this user. The fix is more exploration to find what DOES work, not doubling down on the current strategy. This is the individual-agent analog of the locality-level advisory system (Phase 8.9B) |

### 4.6 Explainability & Transparency

The world model must not be a black box. Users and admins need to understand why recommendations are made.

| Task | Description |
|------|-------------|
| 4.6.1 | Implement feature attribution: for each recommendation, which input features contributed most to the energy score (gradient-based or SHAP-lite) |
| 4.6.2 | Implement admin explainability dashboard: show energy function inputs and outputs for any user/entity pair (for debugging, not displayed to users) |
| 4.6.3 | Implement user-facing "Why this?" tap: show top 3 human-readable reasons (e.g., "Your vibe strongly matches", "People like you enjoyed this", "New experience that broadens your doors") |
| 4.6.4 | Map feature attributions to "doors" language: never show "your quantum state inner product was 0.87" -- show "this spot resonates with your adventurous side" |
| 4.6.5 | Wire explainability into `AnswerLayerOrchestrator` for conversational explanations via the personality agent |

---

## Phase 5: Transition Predictor & On-Device Training

**Tier:** 1 (Core intelligence -- can run parallel with Phase 4)  
**Duration:** 5-6 weeks  
**Dependencies:** Phases 1 and 3 (episodic memory + state encoder)  
**ML Roadmap Reference:** Section 7.4.3, Section 7.4.4, Section 15.4

### 5.1 Transition Predictor Network

Predicts `next_state = current_state + delta(current_state, action)`. Replaces all hand-crafted evolution dynamics.

| Task | Description | Replaces |
|------|-------------|----------|
| 5.1.1 | Design transition predictor: `Concat(StateEmbed, ActionEmbed) → MLP → StateDelta + Variance` | -- |
| 5.1.2 | Implement ONNX transition predictor model | -- |
| 5.1.3 | Train from episodic memory: `loss = MSE(predicted_next_state, actual_next_state)` + VICReg regularization (variance-invariance-covariance) to prevent embedding collapse. **Variance:** ensure embedding dimensions are used (no constant dimensions). **Invariance:** ensure compatible state pairs produce similar embeddings. **Covariance:** ensure dimensions are decorrelated (each carries unique information). This follows LeCun's explicit recommendation to "abandon contrastive methods in favor of regularized methods (VICReg, SIGReg)" | -- |
| 5.1.4 | Implement variance head for uncertainty quantification (how confident is the prediction?) | -- |
| 5.1.5 | Replace `WorldsheetEvolutionDynamics` ODE extrapolation with transition predictor | `F(t) = F(t₀) + ∫dF/dt dt` |
| 5.1.6 | Replace `KnotEvolutionStringService._extrapolateFutureKnot()` with transition predictor | Polynomial extrapolation |
| 5.1.7 | Replace `StringTheoryPossibilityEngine` hardcoded branches with latent variable sampling from variance head | Hardcoded stable/growth/consolidation |
| 5.1.8 | **Predict list state transitions.** The transition predictor must handle list actions: `(user_state_with_list_features, create_list) → predicted_next_state`. This means the model learns how creating/modifying/sharing a list changes a user's personality trajectory. Also predict the list's own state transition: `(list_state, add_spot) → predicted_next_list_state` -- this enables Phase 3.4.5 (list worldsheet) to use learned dynamics instead of simple extrapolation | New -- bridges user and list world models |
| 5.1.9 | **Behavioral taste drift detector (no chat required).** The transition predictor should detect when a user's ACTUAL behavior diverges significantly from what the model PREDICTS. If the model predicts "this user will visit coffee shops and skip nightclubs" but the user suddenly starts visiting nightclubs, the prediction residuals spike. Implement a running Exponential Moving Average (EMA) of prediction residuals. When the EMA exceeds 2x the user's historical average residual, trigger a "taste drift event." A taste drift event causes: (1) Reset confidence to 0.5 for the affected entity categories, (2) Re-enter accelerated exploration phase (Phase 6.2.11) for those categories, (3) Log drift event to episodic memory as `(old_state, drift_detected, behavioral_evidence)`. This is how the model handles life changes (new city, new relationship, new job) WITHOUT the user having to tell their AI agent anything | New -- critical for chat-free accuracy |
| 5.1.10 | **Seasonal and temporal pattern learning.** Users have recurring behavioral patterns that change over time (summer vs winter activities, weekday vs weekend, morning vs evening). The transition predictor must include temporal features (time of day, day of week, month, season) as conditioning variables. When the model detects that a user's summer state differs from their winter state, it should PREDICT the seasonal shift before it happens and proactively adjust recommendations. Not drift -- a CYCLE. Implement as sinusoidal temporal embeddings fed into the transition predictor: `sin(2π * day/365)`, `cos(2π * day/365)`, `sin(2π * hour/24)`, `cos(2π * hour/24)`. The model learns "this user shifts from outdoor spots in summer to indoor spots in winter" purely from behavior patterns | New -- temporal intelligence |
| 5.1.11 | **Dormancy prediction and re-engagement modeling.** The transition predictor must learn to predict user disengagement BEFORE it happens. Define dormancy as: user's interaction frequency drops below 30% of their 30-day rolling average for 7+ consecutive days. The model predicts `P(dormant_in_7_days | current_state, recent_actions)` using features: interaction frequency trend (slope over last 14 days), recommendation acceptance rate trend, time-since-last-positive-outcome, seasonal baseline. When `P(dormant) > 0.6`, flag user for the MPC planner's re-engagement action set (Phase 6.2.12-6.2.15). **Critical:** this is NOT a "please come back" spam trigger -- it's a signal that the AI agent may be failing this user and should change strategy | New -- retention intelligence |
| 5.1.12 | **Wearable → temporal context conditioning.** When wearable data is available (Phase 1.2.27+), extend the transition predictor's temporal features with physiological context: resting heart rate trend (stress proxy), sleep quality rolling average, activity level (steps/day). These become conditioning variables alongside temporal embeddings. The model learns correlations like "when sleep quality drops AND it's winter, user shifts from outdoor to comfort spots." Not gating -- conditioning. The model works without wearable data but improves with it. Implement as optional feature channels that zero-fill when wearable consent is not given | Extends Phase 1.2.27, Phase 5.1.10 |
| 5.1.13 | **Evidence-conditioned transition forecasting.** Add context inputs for evidence quality and source agreement (`agreement_score`, `conflict_score`, `coverage_score`) so state-transition predictions can discount low-quality external claims instead of overfitting to noisy priors | Extends 1.1E.9, 7.9.16 |
| 5.1.14 | **Third-party data drift forecasting.** Predict when external dataset distributions diverge from internal behavioral distributions; trigger fallback to internal-only transition lane and quarantine drifted external features until revalidated | Extends 2.2, 9.2.6 |
| 5.1.15 | **Delayed-credit transition chains.** Learn explicit long-horizon action chains with distal objectives (7/30/90-day outcome links), so transition learning captures why early actions later succeed/fail rather than optimizing immediate proxies only | Extends 1.4.14, 6.1 |

### 5.2 On-Device Training Loop

| Task | Description | Extends |
|------|-------------|---------|
| 5.2.1 | Implement on-device gradient computation from episodic memory batches | New |
| 5.2.2 | Implement `BatteryAdaptiveTrainingScheduler` (extend `BatteryAdaptiveBleScheduler` pattern) | Extends existing |
| 5.2.3 | Training only when: charging OR battery > 50% AND not in power-save mode | Uses `DeviceCapabilityService` |
| 5.2.4 | Implement model weight update with exponential moving average (prevent catastrophic updates) | New |
| 5.2.5 | Implement training metrics logging via `AIImprovementTrackingService` | Extends existing |
| 5.2.6 | Add training status to `DeferredInitializationService` lifecycle | Extends existing |
| 5.2.7 | Implement user-transparent training status: "Your AI is learning" indicator when training is active (subtle, not alarming) | New |
| 5.2.8 | Implement battery impact estimation: show user "Training will use ~X% battery" in settings, respect user override to disable training | New |
| 5.2.9 | Implement device thermal monitoring: pause training if device gets warm (extend `DeviceCapabilityService`) | Extends existing |
| 5.2.10 | Implement training priority: training during natural idle moments (screen off, charging, WiFi connected) is preferred over active-use training | New |
| 5.2.11 | **Anchor Mind + Exploration Mind continual loop.** Keep a stable `AnchorMind` checkpoint (proven behavior baseline) while `ExplorationMind` learns from fresh episodic trajectories; apply `ContinuityAlignment` objective so new learning remains compatible with prior high-confidence behavior | Extends 1.1, 5.2.4 |
| 5.2.12 | **Door-Loss Drift metrics.** Add explicit catastrophic-forgetting metrics on legacy cohorts (prior recommendation, scheduling, community/business matching lanes). Promote only when legacy deltas stay inside configured continuity bounds | Extends 5.2.5, 7.7 |
| 5.2.13 | **Door-Ladder Expansion protocol.** Train capability slices sequentially (recommendation -> scheduling -> community matching -> business matching), with mandatory no-regression gate after each slice before moving to the next | Extends 7.7.4, 7.7A.3 |
| 5.2.14 | **Evidence-tiered training curriculum.** Train in ordered lanes: internal verified data -> external research-derived features -> third-party datasets. Advancement requires no-regression + contradiction checks at each lane boundary | Extends 1.1E.9, 4.1.10, 9.2.6 |
| 5.2.15 | **Conviction-gated optimizer control.** Adjust learning rate, update magnitude, and EMA blending based on contradiction rate and delayed-validation misses. High contradiction automatically slows adaptation and increases rollback sensitivity | Extends 1.4.14, 7.7 |
| 5.2.16 | **Source-family reliability weighting.** Maintain reliability weights per source family (internal telemetry, peer-reviewed external, third-party commercial data). Training batches are weighted by reliability and decay when downstream outcome lift fails replication | Extends 1.4.15, 8.1, 9.2.6 |
| 5.2.17 | **Recursive meta-learning supervisor.** Add real-time planned-vs-actual learning cycle evaluator (`MetaLearningSupervisor`) that scores hypothesis quality, experiment adherence, and update effectiveness; writes corrections back into training policy | Extends 7.9, 10.9.12 |
| 5.2.18 | **Plan-drift and hallucination macro monitor.** Maintain macro-level truth checks over micro-learning updates: if local gains conflict with global truth constraints or deterministic journals, quarantine update and trigger contradiction review | Extends 1.1E, 4.1.11, 8.1.7 |
| 5.2.19 | **Kernel-compliance training gate.** Every training candidate must emit kernel-compliance metrics (purpose/safety/truth/recovery/exploration bounds). Non-compliant candidates cannot enter promotion stages | Extends 1.1E.12, 10.9.11 |
| 5.2.20 | **Downstream scaling behavior profiler.** For each training lane, classify observed scaling regime (`predictable`, `inverse`, `nonmonotonic`, `trendless/noisy`, `breakthrough`) instead of assuming linear gain from added scale | Extends 7.9.40, 10.9.19 |
| 5.2.21 | **Multi-setting scaling robustness gate.** Promotion requires consistency checks across validation corpus variants, task framing variants, and eval setup variants; single-setting linear gains are insufficient | Extends 7.9.41, 7.7.15 |
| 5.2.22 | **DreamEnv bounded training lane.** Add internal dream simulation lane (`DreamEnv`) that runs counterfactual rollouts using `state_encoder + transition_predictor + energy_function + planner` and emits speculative candidates only (never direct production truth) | Extends 5.1, 6.1, 7.7 |
| 5.2.23 | **Simulator-exploit mismatch gate.** Add dream-vs-reality mismatch score; if dream gains fail replay/holdout alignment, auto-quarantine candidate and decay conviction update weight | Extends 7.7.4, 10.9.14 |
| 5.2.24 | **OOD/leakage/spec-gaming checks for dream training.** Block dream promotions when out-of-distribution support is low, temporal leakage is detected, or objective-gaming probes fail | Extends 7.9.31, 10.9.11 |
| 5.2.25 | **Dream compute + safety budget controller.** Enforce strict resource budgets, max cycles, and auto-freeze triggers for runaway dream loops; preserve runtime QoS for live user paths | Extends 7.9.28, 10.9.18 |
| 5.2.26 | **No recursive self-confirmation rule.** Dream-generated labels may train exploration policies only; policy-critical updates require later real-outcome confirmation to prevent self-proving loops | Extends 1.1E.21, 10.9.21 |

### 5.3 Latent Variable System (Multi-Future Prediction)

The `StringTheoryPossibilityEngine` concept, but learned instead of hand-crafted.

| Task | Description |
|------|-------------|
| 5.3.1 | Implement latent variable sampling: vary z vector to generate N plausible futures |
| 5.3.2 | Implement expected-value computation: average energy across z samples |
| 5.3.3 | Implement worst-case computation: max energy across z samples (risk assessment) |
| 5.3.4 | Integrate with `PerpetualListOrchestrator` for multi-future recommendation scoring |

---

## Phase 6: MPC Planner & Autonomous Agent

**Tier:** 2 (Depends on Phases 4 and 5)  
**Duration:** 5-6 weeks  
**ML Roadmap Reference:** Section 7.4.6, Section 7.4.7, Section 15.5

### 6.1 Model-Predictive Control Planner

Uses the transition predictor to simulate action sequences and pick the best one.

| Task | Description |
|------|-------------|
| 6.1.1 | Implement MPC planning loop: generate candidate actions → simulate N steps forward → evaluate total energy → pick lowest |
| 6.1.2 | Implement planning horizon (short: 1 action, medium: 3 actions, long: 7 actions) |
| 6.1.3 | Wire into `PerpetualListOrchestrator` (replace trigger-based generation with MPC-planned recommendations) |
| 6.1.4 | Wire into `PredictiveOutreachScheduler` (replace 3-hour cycle with MPC-planned outreach timing) |
| 6.1.5 | Wire into `AIRecommendationController` (MPC replaces ad-hoc recommendation scoring) |
| 6.1.6 | **List actions in MPC candidate space.** MPC planner must include `create_list`, `modify_list`, `save_list`, `share_list` as candidate actions alongside `visit_spot`, `attend_event`, etc. When the planner evaluates "what should the agent suggest next?", curating a list is a valid action. Example: after the user visits 3 similar spots, the MPC planner predicts that suggesting "Create a list of your favorite spots like these" produces a lower energy (better outcome) than suggesting a 4th similar spot. This models the user's desire to organize, not just consume |
| 6.1.7 | **List-as-context for multi-step planning.** When the user has active lists, include list composition as context for all other actions. The MPC planner should predict: "if the user saves this spot to their jazz list, the list's worldsheet evolves toward X, and then the user is more likely to attend jazz event Y." Lists create conditional dependencies between actions that single-step recommendation misses |
| 6.1.8 | **List recommendation as MPC output.** The planner should be able to recommend EXISTING lists (from other users, from the community, or AI-generated via `PerpetualListOrchestrator`) as a complete action, not just individual spots or events. Uses list-to-user compatibility from Phase 3.4.9 |
| 6.1.9 | **Multi-step partnership planning.** The MPC planner must plan business-expert partnership sequences, not just single-shot matching. Example sequence: `(initiate_outreach, casual_chat, small_collaboration, co_hosted_event, formal_partnership)`. Each step has its own energy and predicted state transition. The planner selects the optimal SEQUENCE, not just the best expert. This replaces `BusinessExpertMatchingService.findExpertsForBusiness()` which returns a flat ranked list with no temporal planning. Wire into `BusinessExpertOutreachService` and `ExpertProactiveOutreachService` |
| 6.1.10 | **Multi-step sponsorship planning.** The MPC planner must plan brand-event sponsorship sequences: `(discover_brand, evaluate_fit, propose_sponsorship, negotiate_terms, finalize_agreement)`. Each step's predicted outcome informs the next. The planner can also predict: "if this brand sponsors event A, and it goes well, they'll likely sponsor the follow-up event B" -- multi-event sponsorship trajectory planning. Wire into `BrandDiscoveryService` and `SponsorshipService` |
| 6.1.11 | **User/community → sponsorship seeking.** The MPC planner must support the reverse direction: when a user or community plans an event that needs funding, the planner identifies `seek_sponsorship` as a candidate action. It evaluates which brands are likely to sponsor (using bidirectional energy from Phase 4.4.9), what sponsorship level to request, and what timing works best. This addresses the gap where users/communities have no mechanism to actively seek sponsors for their events |
| 6.1.12 | **Business-to-patron outreach planning.** The MPC planner must support business-side agent actions: `(identify_target_patron_segment, plan_event_for_segment, send_personalized_outreach, host_event, collect_outcomes)`. Uses `BusinessPatronPreferences` as intent signal, but the planner should LEARN which patron segments actually engage (from Phase 1.2.26), not just use the business's declared preferences. Wire into `PredictiveOutreachScheduler` for business-side outreach |
| 6.1.13 | **Community creator intelligence.** The MPC planner must support community host/admin actions: `(plan_community_event, set_event_parameters, invite_target_members, select_venue, schedule_event)`. Uses the community's fabric invariants (Phase 3.4.4) and member satisfaction history to predict which event types will engage current members. The planner helps creators answer: "What should our community do next?" by simulating event outcomes for different event types/venues/times. Wire into community admin tools as "Suggested Next Event" with explanation |
| 6.1.14 | **Event creator optimization.** For event hosts (community or individual), the MPC planner optimizes event parameters BEFORE the event is created: (a) Predict optimal time slot by simulating attendance for different time options, (b) Predict optimal venue by matching event vibe with candidate venue vibes, (c) Predict optimal capacity by simulating attendee mix quality at different sizes (small intimate vs. large diverse), (d) Predict pricing sweet spot by simulating attendance drop-off at different price points. Present as suggestions during event creation: "Based on your community, Saturday 7pm at [venue] for ~25 people would work best." Uses bidirectional energy (Phase 4.4.2) to ensure both host and attendee perspectives are considered |
| 6.1.15 | **Creator feedback loop.** After a creator-hosted event completes, run a post-hoc analysis comparing predictions vs. actuals: predicted attendance vs. actual, predicted vibe vs. post-event feedback, predicted duration vs. actual. Store as creator-specific episodic tuples: `(creator_state, event_params, predicted_outcomes, actual_outcomes)`. This trains the MPC planner to make better creator-side predictions over time. Show creators a "How your event went" summary with insights: "Your event attracted more arts enthusiasts than expected -- consider more arts-focused events" |
| 6.1.16 | **Evidence-backed action priors.** Add planner priors derived from validated research (`EvidenceBundle` + `ConvictionLedger`) but require local simulation win before action selection. Research can bias search order, never bypass energy/transition checks |
| 6.1.17 | **Internal vs external data route selection.** For each planning decision, choose `internal_only`, `blended`, or `external_suppressed` route based on consent scope, DP class, drift risk, and source reliability. Route choice is logged for audit and post-hoc learning |
| 6.1.18 | **Conviction-aware horizon control.** Increase planning horizon only when conviction is supported by delayed validation and cross-source agreement; when contradiction rises, shorten horizon and shift to information-gathering actions |
| 6.1.19 | **Volunteer pathway planning.** Include volunteer actions in MPC candidate space for community/event/business lanes and optimize for sustained positive community impact, not only short-term engagement |
| 6.1.20 | **Nearby invite/install planner action.** Add planner action family for compliant nearby growth routes (`show_invite_qr`, `share_install_link`, `mesh_invite_ping`) with platform/legal constraints and consent checks |
| 6.1.21 | **Unrestricted discovery action lane.** Add planner option `show_unfiltered_results` so users can access full discoverability views by explicit intent; personalization ranks but does not gate non-restricted entities |

### 6.2 Guardrail Objectives

The world model optimizes for outcomes, but must respect constraints.

| Task | Description |
|------|-------------|
| 6.2.1 | Implement diversity constraint (don't recommend the same entity type repeatedly) |
| 6.2.2 | Implement exploration bonus (reward novel actions that reduce uncertainty) |
| 6.2.3 | Implement safety constraint (never recommend entities with safety flags -- uses `EventSafetyService`) |
| 6.2.4 | Implement "doors" constraint (every recommendation must open a door, not just optimize engagement) |
| 6.2.5 | Implement age-appropriate constraint (extend `BehaviorAssessmentService` age-awareness) |
| 6.2.6 | Implement notification frequency constraint: MPC planner respects `OutreachPreferencesService` limits -- never send more recommendations than user has permitted |
| 6.2.7 | Implement time-of-day constraint: no notifications between user's quiet hours (learn quiet hours from usage patterns, fall back to 10pm-8am) |
| 6.2.8 | Implement diminishing returns penalty: if user dismisses N consecutive recommendations, reduce outreach frequency for that entity type |
| 6.2.9 | **Active uncertainty reduction (Thompson sampling for cold-start).** When the transition predictor's variance head (Phase 5.1.4) reports HIGH uncertainty for a user in a specific domain (e.g., "I don't know if this user likes live music"), the MPC planner should bias toward recommendations that REDUCE uncertainty in that domain, even if they have slightly higher expected energy. Concretely: if the model is split between jazz and classical for a new user, recommend one of each in consecutive sessions rather than hedging with "acoustic music." The information value of learning "they liked jazz, skipped classical" exceeds the cost of one suboptimal recommendation. Implement as an additive uncertainty-reduction bonus in the MPC energy calculation: `effective_energy = predicted_energy - lambda * uncertainty_reduction`, where lambda decays as the user accumulates more data (less need for exploration over time) |
| 6.2.10 | **Domain-specific uncertainty tracking.** Maintain a per-user, per-entity-category uncertainty score derived from the variance head. Categories: Food & Drink, Nightlife, Arts & Culture, Outdoor, Sports & Fitness, Shopping, Learning/Expert Events, Community, Business Partnerships. When a category's uncertainty drops below threshold, the exploration bonus for that category drops to 0 (the model is confident). When uncertainty is high, exploration bonus is high. This ensures the model strategically fills knowledge gaps WITHOUT requiring the user to tell it what they like |
| 6.2.11 | **Exploration-exploitation balance per user lifecycle stage.** Define 3 stages: (1) Exploration-heavy (first 20 interactions, or skip-onboarding users with confidence < 0.3): 60% exploration / 40% exploitation. (2) Balanced (20-100 interactions): 30% exploration / 70% exploitation. (3) Exploitation-heavy (100+ interactions): 10% exploration / 90% exploitation. The exploration percentage determines how much the MPC planner values uncertainty reduction vs. pure energy minimization. This schedule is the mechanism that makes the model converge WITHOUT chat |
| 6.2.12 | **Re-engagement strategy selection (dormancy response).** When the transition predictor flags `P(dormant) > 0.6` (Phase 5.1.11), the MPC planner switches to a re-engagement action set. Available actions: (a) `novelty_injection` -- recommend something outside the user's established pattern (a new category, a trending event), (b) `social_nudge` -- highlight a friend's recent activity at a spot the user has visited, (c) `achievement_door` -- surface a "door" the user is close to opening (e.g., "You've explored 4 of 5 neighborhoods in your area"), (d) `reduce_frequency` -- paradoxically send FEWER recommendations (the user may be over-notified). MPC simulates each strategy's predicted outcome and picks the one with lowest energy (best predicted re-engagement). **Not spam:** the MPC planner may decide "do nothing" is the lowest-energy action if the user is taking a natural break |
| 6.2.13 | **Re-engagement frequency guardrail.** Re-engagement actions are limited to 1 per week maximum. If the user does not respond to 3 consecutive re-engagement attempts (over 3 weeks), enter "silent mode" for 30 days: stop all proactive outreach, but keep the AI agent ready to respond instantly when the user returns. After silent mode: one final "we're still here" notification with the most compelling recommendation the model can find. After that: fully passive until user initiates |
| 6.2.14 | **Returning user fast-ramp.** When a dormant user returns (first interaction after 14+ days of inactivity), the MPC planner temporarily increases exploration to 40% (regardless of lifecycle stage) for the first 5 interactions. This accounts for possible taste drift during absence (Phase 5.1.9 catches real drift; this is a precautionary exploration bump). After 5 interactions, revert to the user's lifecycle-stage exploration rate |
| 6.2.15 | **Dormancy outcome logging.** Every dormancy prediction and re-engagement action is logged as an episodic tuple: `(user_state_at_prediction, re-engagement_action, user_response, days_to_return)`. This data trains the transition predictor to improve dormancy prediction AND the energy function to score re-engagement actions. Wire into `UnifiedOutcomeCollector` |
| 6.2.16 | **Discoverability guarantee invariant.** Personalization may rank results, but cannot hide discoverable spots/events/businesses/communities outside explicit legal/safety/consent constraints. Provide user-toggle unfiltered mode |
| 6.2.17 | **First-occurrence response invariant.** Any first-seen high-severity issue signature must trigger immediate triage route (`fix`, `experiment`, or `human_guidance`) within bounded SLA and create deterministic ledger entries |
| 6.2.18 | **Dwell-time escalation invariant.** Enforce per-issue dwell budgets; when budget expires without resolution, escalate to alternate strategy or human guidance and mark unresolved path for recurrence prevention |
| 6.2.19 | **Discoverability precedence matrix.** Add explicit precedence ordering for conflicting controls: legal > safety > privacy/consent > user intent (`show_unfiltered_results`) > personalization ranker. Emit deterministic rationale telemetry whenever constraints suppress user-requested discoverability |
| 6.2.20 | **Dwell exit criteria invariant.** Every dwell policy must declare measurable stop conditions (minimum confidence gain, contradiction reduction, and residual risk threshold). If stop conditions are not met before dwell budget expiry, force escalation |
| 6.2.21 | **Belief-tier action authority gate.** High-impact actions must read `proven_conviction` only; `dream` and `hypothesis` tiers may influence exploration branches but cannot drive hard action execution |
| 6.2.22 | **Dream contradiction dampener.** When dream-derived recommendations conflict with proven convictions or deterministic journals, apply automatic penalty, route to shadow exploration, and emit contradiction telemetry |
| 6.2.23 | **Dream-safe discoverability rule.** Dream policies may reorder but cannot suppress non-restricted discoverability; explicit user unfiltered intent always bypasses dream-tier ranking constraints within legal/safety bounds |

### 6.3 Agent Architecture

The AI agent becomes autonomous: persistent memory, tool use, self-directed learning.

| Task | Description | Extends |
|------|-------------|---------|
| 6.3.1 | Implement persistent agent memory (beyond episodic -- includes learned preferences, exploration history, goal state) | New |
| 6.3.2 | Implement tool registry (the agent can invoke: search, recommend, schedule, message, navigate) | New |
| 6.3.3 | Implement self-directed learning: agent identifies high-uncertainty areas and proactively collects data | Extends `AISelfImprovementSystem` |
| 6.3.4 | Wire into `AIMasterOrchestrator` as the central intelligence loop | Extends existing |

### 6.4 Offline Confirmation & Graceful Degradation

The MPC planner must work offline. Users in tunnels, airplanes, or bad coverage areas must still get good recommendations.

| Task | Description |
|------|-------------|
| 6.4.1 | Confirm all world model inference runs on-device (state encoder, action encoder, energy function, transition predictor) with zero network dependency |
| 6.4.2 | Implement entity cache: pre-fetch candidate entities (spots, events, communities) during last online moment, use cached entities for offline scoring |
| 6.4.3 | Implement offline-to-online reconciliation: when connectivity returns, re-score recent recommendations with fresh entity data and update if top picks changed |
| 6.4.4 | Implement `BackupSyncCoordinator` integration: sync episodic memory, training gradients, and model weight updates when coming online |
| 6.4.5 | Define offline UI behavior: show "Personalized for you (from earlier today)" with timestamp when using cached recommendations, no "loading" spinners for on-device inference |

### 6.5 System 1/System 2 Compilation (Distillation)

Once the MPC planner (Phase 6.1) produces high-quality recommendation sequences, distill its decisions into a fast reactive model. This mirrors human cognition: most daily decisions are fast/automatic (System 1), but important decisions involve deliberate planning (System 2). Over time, System 2's wisdom gets compiled into System 1's reflexes.

| Task | Description |
|------|-------------|
| 6.5.1 | **System 2 (slow, deliberate):** The MPC planner simulates N-step futures, evaluates total energy, picks optimal sequence. ~6ms for 20 candidates × 2-step horizon. Used for: first community recommendation, major life events, low-confidence situations |
| 6.5.2 | **System 1 (fast, reactive):** Train a lightweight ONNX MLP that maps `(state_embedding, action_embedding) → recommendation_score` by imitating the MPC planner's output. Inference: microseconds. Handles 95% of recommendations instantly |
| 6.5.3 | Implement distillation training loop: collect MPC planner (state, action, score) tuples during normal operation → train System 1 model to reproduce MPC's scoring |
| 6.5.4 | Implement confidence-based routing: System 1 handles recommendations when its confidence > threshold. When confidence is low (novel situation, ambiguous state), route to System 2 (full MPC planning) |
| 6.5.5 | Implement transition tracking: measure how often System 1 agrees with System 2. As agreement rate increases, the distilled model is learning. Target: > 95% agreement before relying on System 1 for most decisions |
| 6.5.6 | Wire into existing `InferenceOrchestrator` device-first strategy: System 1 is the new fast path, System 2 is the fallback. This replaces the current ONNX + optional Gemini expansion pattern |

> **ML Roadmap Reference:** Section 7.4.7, Roadmap Item #27. In AVRAI terms: the current formula + ONNX hybrid IS System 1 (but a hand-crafted one). Building MPC creates System 2. Distilling MPC outputs into the ONNX model creates a *learned* System 1 that incorporates trajectory-aware reasoning even though it runs in microseconds.

### 6.6 Mesh-Fallback Communication (Offline Chat + Actions)

In LeCun's framework, the actor must be able to take actions even when parts of the environment are unavailable. The MPC planner's action space includes `message_friend` and `message_community`, but these currently require cloud connectivity. If the agent recommends "message your friend about this event" while offline, the action must still be possible when the friend is nearby on mesh.

| Task | Description |
|------|-------------|
| 6.6.1 | Enable mesh transport fallback for `FriendChatService`: when cloud is unavailable AND recipient is in BLE range (discovered via `DeviceDiscoveryService`), route message through `AnonymousCommunicationProtocol` instead of Supabase |
| 6.6.2 | Enable mesh transport fallback for `CommunityChatService`: when cloud is unavailable AND community members are in BLE range, route via mesh with Sender Keys encryption |
| 6.6.3 | Implement message deduplication: when connectivity returns, deduplicate messages sent via mesh AND cloud (same message ID, prefer cloud timestamp) |
| 6.6.4 | Update MPC planner action availability: the planner must know which actions are available offline. `message_friend` is available if friend is nearby on mesh OR message can be queued for later. `attend_event` is always available (on-device). `create_reservation` requires cloud (mark unavailable offline) |
| 6.6.5 | Signal Protocol works the same over mesh as over cloud -- the transport layer is transparent to encryption. Verify this with integration tests |

> **LeCun alignment:** The world model must have an accurate "action space" -- knowing which actions are available given current state (including connectivity state). An offline-aware MPC planner is a direct implementation of LeCun's "action-conditioned prediction" where the set of available actions changes with the environment.

### 6.7 SLM Language Interface (On-Device)

The Small Language Model (SLM, 1-3B parameters) is NOT the brain -- it's the mouth. The world model handles all decisions (perception, prediction, scoring, planning). The SLM translates those decisions into human-readable explanations. Only available on Tier 3 devices (see Phase 7.6).

| Task | Description | Extends |
|------|-------------|---------|
| 6.7.1 | Switch `model_pack_manager.dart` from Llama 8B to a 1-3B SLM (e.g., Llama 3.2 1B, Phi-3 mini, Gemma 2B). Smaller model = faster inference, less storage, same quality for explanation-only use | Extends existing |
| 6.7.2 | Implement explanation generation: world model produces `(recommended_entity, energy_score, top_3_feature_attributions)` → SLM generates natural language: "I think you'd love this because your adventurous side matches this spot's vibe" | New |
| 6.7.3 | Implement agent personality voice: SLM generates text consistent with the user's personality agent character (extending `PersonalityAgentChatService` with richer responses) | Extends existing |
| 6.7.4 | Implement reflection summaries: during nightly consolidation (Phase 1.1C), SLM optionally generates 1-sentence episode summaries for semantic memory (e.g., "Great evening at jazz bar, felt energized and social") | Feeds Phase 1.1A |
| 6.7.5 | Tier gating: SLM only loads on Tier 3 devices (iPhone 15 Pro+, Pixel 8 Pro+). On Tier 2 and below, explanations use template strings filled from feature attributions. On Tier 0-1, fallback to cloud LLM (`LlmService` → Gemini) if online, template strings if offline | Uses Phase 7.6 |
| 6.7.6 | Implement SLM size budget: model file < 2GB on disk, < 700MB RAM during inference. Model downloaded on-demand (not bundled with app), cached after first download | New |

> **ML Roadmap Reference:** Section 16.2, Roadmap Item #41. The world model is ~20,000x faster than SLM reasoning for the same task (6ms vs. ~125s). The SLM's only job is turning numeric outputs into words. LLM cloud fallback (Gemini) remains available for users without Tier 3 devices or when SLM isn't downloaded.

---

## Phase 7: Orchestrator Restructuring & System Integration

**Tier:** 2 (Depends on Phase 4 energy function)  
**Duration:** 6-8 weeks  
**Dependencies:** Phase 4 minimum, Phases 5-6 for full integration

### 7.1 Orchestrator Updates

Each orchestrator needs world model integration.

| Task | Orchestrator | Change |
|------|-------------|--------|
| 7.1.1 | `AIMasterOrchestrator` (5s cycle) | Replace placeholder methods (`_coordinatePredictiveAnalytics`, `_processLearningInsights`, `_processPatternInsights`, `_optimizeUserInterface`, etc.) with world model inference steps. Implement `_saveOrchestrationState()` (currently log-only) |
| 7.1.2 | `UnifiedEvolutionOrchestrator` (5min cycle) | **Fix evolution cascade:** replace placeholder coordination methods with real cascade: `personality_change → QuantumVibeEngine.recompile() → PersonalityKnotService.recompute() → KnotFabricService.updateInvariants() → WorldsheetEvolutionDynamics.step() → KnotEvolutionStringService.updateRates() → DecoherenceTrackingService.updatePhase()` → then trigger full state snapshot for episodic memory. Currently only knot evolution is wired; quantum, worldsheet, string, and decoherence coordination methods are all placeholders (log-only) |
| 7.1.3 | `ContinuousLearningOrchestrator` (1s cycle) | Write episodic tuples, not just dimension updates. Implement `_saveLearningState()` (currently a TODO placeholder) |
| 7.1.4 | `PerpetualListOrchestrator` (trigger) | Replace `StringTheoryPossibilityEngine` with MPC planner (Phase 6) |
| 7.1.5 | `AI2AILearningOrchestrator` | Share anonymized world model gradients, not raw personality data |
| 7.1.6 | `AnswerLayerOrchestrator` | Use world model context for RAG decisions |

> **LeCun alignment (7.1.2):** The world model's state observation must be **consistent**. In LeCun's framework, the perception module produces a single coherent state representation. If personality evolves but quantum vibe state, knot invariants, fabric metrics, worldsheet trajectory, string evolution rates, and decoherence phase don't cascade-update, the state encoder receives an internally inconsistent observation. The cascade ensures atomic state consistency -- every personality change produces a full-stack update before the next state snapshot is captured.

### 7.2 Controller Updates

| Task | Controller | Change |
|------|-----------|--------|
| 7.2.1 | `QuantumMatchingController` | Energy function replaces compatibility formula |
| 7.2.2 | `AIRecommendationController` | MPC planner replaces recommendation scoring |
| 7.2.3 | `GroupMatchingController` | Energy function for group compatibility |
| 7.2.4 | `ReservationCreationController` | Energy function for reservation compatibility + complete TODOs (availability, rate limits, queue, waitlist, notifications) |
| 7.2.5 | `EventCreationController` | World model predicts event outcomes for host feedback |
| 7.2.6 | `EventAttendanceController` | Outcome recording confirmed for episodic memory |

### 7.3 Sync & Background Updates

| Task | Description | Extends |
|------|-------------|---------|
| 7.3.1 | Add `WorldModelSyncStep` to `BackupSyncCoordinator` (sync gradients when coming online) | Extends existing |
| 7.3.2 | Add world model inference to `DeferredInitializationService` startup sequence | Extends existing |
| 7.3.3 | Extend `FeatureFlagService` with world model feature flags (energy_function_enabled, transition_predictor_enabled, mpc_planner_enabled) | Extends existing |
| 7.3.4 | Add world model metrics to `AdminSystemMonitoringService` | Extends existing |

### 7.4 Agent Trigger System (Event-Driven Activation)

Replace the `ContinuousLearningOrchestrator`'s 1-second polling timer with event-driven triggers. The agent does NOT run continuously (battery death). It activates on specific events, processes 1-5 reasoning steps (~6-30ms total compute), and goes back to sleep.

| Task | Description | Extends |
|------|-------------|---------|
| 7.4.1 | Define trigger event taxonomy with frequency estimates: | New |

| Trigger | What Happens | Frequency |
|---------|-------------|-----------|
| App opened | Full planning cycle: encode state, plan over all candidates, present recommendations | ~5-15x/day |
| Significant location change | Re-plan with new location context, check nearby spots/events | ~5-20x/day |
| Timer (active hours only) | Background check: any high-energy opportunities nearby? | Every 2 hours |
| AI2AI connection established | Exchange insights, update critic calibration, check group activity potential | Varies (~0-10x/day) |
| Community/event notification | Evaluate notification against current plan, decide whether to surface | Varies |
| Calendar event approaching | Check if preparation or alternative suggestion is appropriate | ~0-5x/day |
| Overnight (charging + WiFi) | Memory consolidation, on-device training, federated sync | 1x/day |

| Task | Description | Extends |
|------|-------------|---------|
| 7.4.2 | Implement `AgentTriggerService` that listens for trigger events and dispatches to agent reasoning loop. Replace `ContinuousLearningOrchestrator`'s 1-second `Timer.periodic` with event listeners | Replaces existing |
| 7.4.3 | Wire location change trigger via `LocationTrackingService` significant location change events (not continuous GPS polling) | Extends existing |
| 7.4.4 | Wire timer trigger via `WorkManager` (Android) / `BGTaskScheduler` (iOS) for background checks during active hours only | New |
| 7.4.5 | Wire AI2AI connection trigger via `DeviceDiscoveryService` connection events | Extends existing |
| 7.4.6 | Wire overnight trigger for consolidation cycle (Phase 1.1C) via charging + WiFi + idle detection | Extends existing |
| 7.4.7 | Implement trigger throttling: no trigger fires more than once per 30 seconds (debounce) to prevent cascade activation. Between triggers, agent sleeps (zero battery) | New |
| 7.4.8 | Implement trigger metrics: which triggers fire most? Which produce the most valuable recommendations? Use to tune trigger frequency and priority | New |

> **ML Roadmap Reference:** Section 16.3, Roadmap Item #34. Between triggers, the agent sleeps. Each activation: 1-5 reasoning steps, ~6-30ms total compute, negligible battery impact. This replaces the always-on 1-second polling that would drain battery.

> **Integration Risk:** `ContinuousLearningOrchestrator` (`lib/core/ai/continuous_learning/orchestrator.dart`) uses `Timer.periodic(_cycleInterval, ...)` (line 123) that drives 5 learning engines (personality, behavior, preference, interaction, location intelligence). It tracks `_cyclesCompleted`, `_learningStartTime`, and dimension convergence -- all of which assume periodic execution. **Resolution:** When replacing the timer with event-driven triggers, each learning engine must become callable on-demand (they already are -- they're async methods). But the orchestration state (cycle counting, convergence tracking) must be refactored to track "activations" instead of "cycles." Also, `_saveLearningState()` (line 854) is currently a TODO placeholder -- implement it as part of this work so state persists across trigger activations.

### 7.5 Device Capability Tiers

Not every phone can run every component. The agent gracefully degrades based on device hardware. Every user gets an AI agent -- the agent's capabilities scale with their device.

| Task | Description | Extends |
|------|-------------|---------|
| 7.5.1 | Extend `on_device_ai_capability_gate.dart` with `AgentCapabilityTier` enum: `full`, `standard`, `basic`, `minimal` | Extends existing |

| Tier | Device Example | Components Available |
|------|---------------|---------------------|
| **Tier 3 (Full)** | iPhone 15 Pro+, Pixel 8 Pro+ | World model + SLM + all memory types + federated learning + on-device training |
| **Tier 2 (Standard)** | iPhone 13+, Pixel 7+ | World model + all memory + federated learning. No SLM, no on-device training |
| **Tier 1 (Basic)** | iPhone 11+, Pixel 5+ | Existing ONNX models + episodic memory + bias overlay learning. No world model |
| **Tier 0 (Minimal)** | Older devices | Formula-only calling score. No ONNX models. Rule-based personality evolution |

| Task | Description | Extends |
|------|-------------|---------|
| 7.5.2 | Implement tier detection: check RAM, CPU cores, Neural Engine/GPU availability, storage space. Map to tier | Extends `DeviceCapabilityService` |
| 7.5.3 | Implement tier-based module loading: `DeferredInitializationService` only initializes components available at the detected tier. No wasted memory loading world model on Tier 0 devices | Extends existing |
| 7.5.4 | Implement tier fallback chain: if world model inference fails (OOM, crash), automatically degrade to next lower tier. Log tier downgrades for analytics | New |
| 7.5.5 | Implement tier display: show user their current AI tier in settings (optional, non-alarming: "AI: Enhanced" for Tier 2+, "AI: Standard" for Tier 1, "AI: Basic" for Tier 0) | New |
| 7.5.6 | Wire tier into all world model gates: every Phase 3-6 component checks tier before executing. Tier 0/1 devices skip world model and use formula path | All phases |

> **ML Roadmap Reference:** Section 16.4, Roadmap Item #35. The core experience (recommendations that improve over time) works on all tiers. The existing `on_device_ai_capability_gate.dart` already performs device capability checks -- this extends it.

> **Integration Risk:** `OnDeviceAiCapabilityGate` (`lib/core/services/on_device_ai_capability_gate.dart`) already has an `OfflineLlmTier` enum (`none`, `small3b`, `llama8b`) used by onboarding, settings pages, and LLM auto-install services. The new `AgentCapabilityTier` enum (`full`, `standard`, `basic`, `minimal`) overlaps in meaning. **Resolution:** Make `AgentCapabilityTier` the primary enum that subsumes `OfflineLlmTier`. Mapping: Tier 3 (full) = `llama8b`, Tier 2 (standard) = `small3b`, Tier 1 (basic) = `none` + ONNX models, Tier 0 (minimal) = `none`. Keep `OfflineLlmTier` as a derived property (`agentTier.llmTier`) for backward compatibility with existing UI pages (`on_device_ai_settings_page.dart`, `onboarding_page.dart`) that already reference it.

### 7.6 Dependency Chain Management

These dependency chains must be respected during integration:

```
PersonalityLearning → QuantumVibeEngine → VibeCompatibilityService → CallingScoreCalculator
                    → PersonalityKnotService → KnotFabricService → CommunityService
                    → ContinuousLearningSystem → UnifiedEvolutionOrchestrator
```

**Evolution cascade (must execute atomically in UnifiedEvolutionOrchestrator):**
```
PersonalityChange → QuantumVibeEngine.recompile()
                  → PersonalityKnotService.recompute()
                  → KnotFabricService.updateInvariants()
                  → WorldsheetEvolutionDynamics.step()
                  → KnotEvolutionStringService.updateRates()
                  → DecoherenceTrackingService.updatePhase()
                  → WorldModelFeatureExtractor.captureFullSnapshot()
```

```
AtomicClockService → QuantumEntanglementService → QuantumMatchingController
                   → JourneyTrackingService → MeaningfulExperienceCalculator
```

```
AgentIdService → ALL services (privacy boundary)
```

```
SignalProtocolService → AI2AIProtocol → BLEForegroundService → DeviceDiscovery
```

```
SignalProtocolService → MessageEncryptionService → FriendChatService, CommunityChatService,
                                                   PersonalityAgentChatService, BusinessExpertChatServiceAI2AI,
                                                   BusinessBusinessChatServiceAI2AI
                      → LanguagePatternLearningService → ContinuousLearningSystem (agent chat only)
                      → AI2AILearningOrchestrator → ConversationInsightsExtractor
```

**Rule:** When replacing a formula in a service, update ALL downstream consumers in the same deployment. Use feature flags to flip atomically.

### 7.7 Model Lifecycle Management (Versioning, OTA, Rollback)

ONNX models ship in the app binary (Phase 1.5D.3) and improve via federated aggregation (Phase 1.5D.4). But the Master Plan had no section addressing how updated models reach devices, how versions coexist with stored episodic memory, or how to roll back a bad model globally.

| Task | Description | Extends |
|------|-------------|---------|
| 7.7.1 | **Define model version schema.** Each ONNX model bundle includes: `model_id` (energy_function, transition_predictor, state_encoder, action_encoder, system1), `version` (semver), `min_episodic_schema_version` (backward compatibility gate), `training_epoch` (federated round number), `hash` (integrity check). Store as `ModelManifest` model | Extends `ModelVersionManager` |
| 7.7.2 | **Implement OTA model delivery via cloud sync.** When federated aggregation (Phase 8.1.3) produces improved global weights, push to a Supabase storage bucket. On-device: `BackupSyncCoordinator` checks for new model versions when online (WiFi preferred). Download is background, non-blocking. Never interrupt active inference | Extends `BackupSyncCoordinator`, `ModelVersionManager` |
| 7.7.3 | **Model-episodic compatibility gate.** Before loading a new model version, verify `min_episodic_schema_version` matches the device's episodic memory schema. If mismatch: (a) if model is NEWER, migrate episodic schema first, (b) if model is OLDER (rollback), keep episodic schema and pad missing fields with defaults. Prevents crashes from schema mismatch | New |
| 7.7.4 | **Staged rollout with canary.** New model versions deploy to 5% of devices first (canary group, selected via `AgentIdService` hash). Monitor canary group's agent happiness (Phase 8.9) and outcome rates for 48 hours. If happiness drops > 10% vs. control, abort rollout. If stable, expand to 25% → 100% over 7 days. Wire into `FeatureFlagService` for rollout percentage control | Extends `FeatureFlagService`, `ModelSafetySupervisor` |
| 7.7.5 | **Global model rollback.** If a deployed model degrades outcomes globally (detected by `ModelSafetySupervisor` across multiple devices via federated happiness reporting), the aggregation server marks the current version as `deprecated` and re-serves the previous version. On-device: `BackupSyncCoordinator` detects the rollback flag and reverts to the previous model bundle stored locally (keep last 2 versions on device) | Extends `ModelSafetySupervisor`, `BackupSyncCoordinator` |
| 7.7.6 | **Per-user model rollback.** Phase 4.5.4 rolls back formula-to-energy-function transitions per user. Extend this: if a user's outcomes degrade after ANY model update (not just formula flip), automatically revert that user to the previous model version. Track per-user model version in `AgentHappinessService` metadata | Extends Phase 4.5.4, `AgentHappinessService` |
| 7.7.7 | **Model version display in settings.** Show current model versions in AI settings page (e.g., "AI Model: v2.3 (updated 3 days ago)"). Non-alarming, informational. Include "Last improved" timestamp so users can see the system is actively learning | Extends `OnDeviceAiSettingsPage` |
| 7.7.8 | **Model storage budget enforcement.** Keep at most 2 model versions on device (current + previous for rollback). Total ONNX budget: ~2MB (current ~1MB + previous ~1MB). Prune oldest version when a new one downloads. Respect Appendix D storage budget | New |
| 7.7.9 | **Deterministic rollout ledger.** For each model/policy promotion, persist a journal record with candidate id, expected deltas, guardrails, and rollback conditions for forensic traceability | Extends 1.1E.2 |
| 7.7.10 | **Rollback diagnosis from lightweight memory core.** `RollbackGuardian` queries failure signatures and recent `HistoryJournal` windows before/after degradation to identify likely cause class (data drift, policy overfit, noise sensitivity, safety regression) | Extends 1.1E.8, 7.9.7 |
| 7.7.11 | **Known-bad suppression rule.** Block re-deploy of previously failed candidate patterns unless new evidence clears contradiction and coverage gates | Extends 7.7.5, 7.9.8 |
| 7.7.12 | **Continuity gate in promotion policy.** Rollout criteria must include `DoorContinuityScore` from `AnchorMind` vs `ExplorationMind` evaluation; candidate is blocked when continuity drops below threshold even if new-skill metrics improve | Extends 5.2.12, 7.7.4 |
| 7.7.13 | **Forgetting-risk-aware rollback policy.** Attach `door_loss_risk` to every candidate manifest and auto-rollback when risk spikes after canary or limited rollout; persist cause class in deterministic ledger for future suppression | Extends 7.7.5, 7.7.9, 1.1E.8 |
| 7.7.14 | **Scaling reliability metadata in manifests.** Add `scaling_profile` fields to candidate manifests (`regime_class`, `fit_confidence`, `sensitivity_index`, `cross-setting_consistency`) for promotion/rollback decisions | Extends 7.7.1, 5.2.20 |
| 7.7.15 | **No linear-only extrapolation promotion rule.** Block rollout when expected gains are justified only by single-setting linear extrapolation without cross-setting confirmation and inversion/nonmonotonic containment plan | Extends 7.7.4, 10.9.19 |
| 7.7.16 | **Dream promotion chain enforcement.** Enforce lifecycle states `dream -> hypothesis -> candidate_conviction -> proven_conviction`; direct jumps are invalid and fail promotion checks | Extends 1.1E.20, 7.7.4 |
| 7.7.17 | **Dream conflict fail-closed rule.** If dream-derived candidates conflict with `proven_conviction` and real-outcome checks do not justify reopening, block rollout and archive as negative path | Extends 1.1E.22, 7.7.11 |
| 7.7.18 | **Dream rollback bundle requirement.** Every dream-derived promotion must include rollback artifacts, mismatch diagnostics, and delayed-validation checkpoints before advancing beyond canary | Extends 7.7.5, 1.4.14 |

> **Why this matters:** Without model lifecycle management, updated models either ship only via App Store updates (slow, requires user action) or arrive unversioned and unrollbackable (dangerous). The staged rollout + canary + per-user rollback ensures model improvements reach users quickly while protecting against regressions.

### 7.7A Self-Improving Search Governance (Gated Autonomy)

Search can self-improve, but production behavior changes must be gated by measurable wins and safety checks.

| Task | Description | Extends |
|------|-------------|---------|
| 7.7A.1 | Implement proposal pipeline: `SearchLearningAdapter` can propose ranker/query-rewrite updates as versioned candidates with metric deltas and confidence intervals | Extends 1.1D.10 |
| 7.7A.2 | Implement shadow mode for every candidate: run candidate ranking in parallel with active ranking, log counterfactual deltas (precision@K, recall@K, nDCG, latency, safety violations) | New |
| 7.7A.3 | Define promotion gates: candidate can advance only if it beats control on primary metrics and does not regress safety/latency beyond thresholds | New |
| 7.7A.4 | Implement limited A/B canary rollout after shadow pass; auto-halt if guardrails trip (latency spike, safety regression, trust-source degradation) | Extends 7.7 |
| 7.7A.5 | Require signed changelog + audit record for every promotion (candidate version, training window, eval set version, gate metrics, approver) | Extends `ModelVersionManager` |
| 7.7A.6 | Implement one-click rollback for search candidate artifacts (ranker weights, rewrite rules, fusion params, feature flags) with full state restore | Extends 7.7 rollback |
| 7.7A.7 | Add anti-drift monitor: detect when live query distribution shifts from eval distribution; auto-route to shadow retraining cycle before promoting new candidates | New |
| 7.7A.8 | Add policy boundary: autonomous system may tune parameters and ranking functions, but may NOT mutate hard safety/compliance rules without explicit human approval | Extends Phase 2 guardrails |

> **Autonomy boundary:** Self-improving search is allowed. Unsupervised self-modifying production logic is not.

### 7.8 Multi-Device State Reconciliation

Users may have multiple devices (phone + tablet, old phone + new phone). Episodic memory, personality state, and model weights live on-device. Without reconciliation, a user's iPad and iPhone develop divergent personality models.

| Task | Description | Extends |
|------|-------------|---------|
| 7.8.1 | **Define device-linked account model.** A user account can have N linked devices, each with its own `AgentId`, `AgentCapabilityTier`, and model state. Primary device = highest tier. Secondary devices sync FROM primary, not independently. Track via `BackupSyncCoordinator` device registry | Extends `BackupSyncCoordinator`, `AgentIdService` |
| 7.8.2 | **Episodic memory merge strategy.** When secondary device comes online: (a) push its locally-collected episodic tuples to the primary device's episodic store (via encrypted cloud relay in `BackupSyncCoordinator`), (b) primary device incorporates secondary's tuples into its training set. Secondary tuples are tagged with `source_device_id` for deduplication. Never duplicate identical tuples (same timestamp + action + entity) | Extends Phase 1.1, `BackupSyncCoordinator` |
| 7.8.3 | **Personality state sync (primary → secondary).** After nightly consolidation (Phase 1.1C), primary device pushes its latest personality state and model weights to cloud. Secondary devices pull on next sync. This means the primary device drives the personality model; secondary devices are observation collectors that feed back to the primary | Extends Phase 1.1C |
| 7.8.4 | **Tier-aware sync.** If primary = Tier 3 (full world model) and secondary = Tier 1 (basic), the secondary uses the primary's System 1 distilled model (Phase 6.5) rather than formula-only scoring. This means even basic devices get world-model-quality recommendations when paired with a capable primary device | Extends Phase 7.5, Phase 6.5 |
| 7.8.5 | **Device migration (old phone → new phone).** When a user sets up a new device, offer "Transfer AI" option that pulls: episodic memory, personality state, model weights, procedural rules, and semantic memory from the old device via `BackupSyncCoordinator`. The new device starts where the old one left off, not from cold-start | Extends `BackupSyncCoordinator` |
| 7.8.6 | **Conflict resolution for simultaneous use.** If user uses both devices in the same day (e.g., phone for commute, tablet at home), both collect episodic data. On next sync: merge by timestamp ordering, deduplicate overlapping actions, re-train from combined dataset. Use last-write-wins for personality state (primary's nightly consolidation is authoritative) | New |

> **Privacy note:** Multi-device sync goes through `BackupSyncCoordinator`, which uses application-layer encryption. Episodic data is encrypted before cloud relay. The cloud never sees plaintext personality data.

### 7.9 Autonomous Research, Experimentation, and Evidence Cross-Reference

This section operationalizes the always-on research/experiment loop so AVRAI can expand its own research definitions, test ideas safely, and integrate validated findings from external and internal evidence.

**Placement rule:** Phase `7.9` owns research orchestration/governance. Runtime/training/lifecycle implementations from addenda must land in their owning phases (1.x, 5.x, 6.x, 7.5/7.7, 8.1, 10.9.x) per `docs/plans/architecture/EXTERNAL_RESEARCH_ADDENDUM_PHASE_PLACEMENT_MATRIX_2026-02-16.md`.

| Task | Description | Extends |
|------|-------------|---------|
| 7.9.1 | **Hypothesis mining trigger pipeline.** Build `HypothesisMiner` to convert uncertainty spikes, model failures, contradiction signals, and stale assumptions into ranked testable hypotheses | Phase 1.1, Phase 5.1 |
| 7.9.2 | **Interdisciplinary retrieval policy.** Implement `InterdisciplinaryRetrievalPolicy` with dual-track retrieval (`Analytic Track` + `Creative Track`) and coverage checks for human-centered questions | Phase 7.4, Phase 2 guardrails |
| 7.9.3 | **Self-expanding research definitions.** Implement `ResearchDefinitionExpander` to discover new research tags/lenses from blind spots and failed experiments; use probation -> promotion flow before permanent policy inclusion | New |
| 7.9.4 | **Evidence normalization + provenance.** Every external source is normalized into claim/assumption/method/evidence-quality metadata and linked to immutable provenance IDs | Extends Phase 2 compliance logging |
| 7.9.5 | **Experiment-plan contracts.** Build `ExperimentPlanner` DSL with mandatory pre-registered success criteria, failure criteria, MDE, safety constraints, and affected cohorts | Extends 7.7A governance |
| 7.9.6 | **Staged experiment execution lane.** `ExperimentOrchestrator` must enforce replay -> shadow -> limited rollout gates; high-impact experiments cannot skip stages | Extends 7.7 rollout gates |
| 7.9.7 | **Causal attribution reports.** Build `CausalAttributionEngine` output with ablations, counterfactual replay, subgroup deltas, and "worked because / failed because" traces | New |
| 7.9.8 | **External/internal claim scoring.** Implement `CrossReferenceGraphService` and score each candidate claim with `agreement`, `conflict`, `coverage`, and `novelty` against internal episodic/outcome/planner evidence | Phase 1.1, 1.2, 6.1 |
| 7.9.9 | **Belief graph updates with conviction bounds.** Update confidence/contradiction state only when evidence thresholds pass; conviction must decrease on failed replication or stronger contradiction | Extends `BeliefGraphService` |
| 7.9.10 | **Research integrator into model lifecycle.** `ResearchIntegrator` may propose model/policy updates, but promotion requires existing lifecycle gates (canary + rollback + safety checks) | Extends 7.7.4-7.7.6 |
| 7.9.11 | **Self-healing rollback guardian.** Implement `RollbackGuardian` that auto-reverts degradations and suppresses failed paths until new evidence supports retry | Extends 7.7.5 |
| 7.9.12 | **Retrieval diversity and experiment-yield KPIs.** Track domain breadth, lens novelty, replication lift, unresolved-hypothesis backlog, and recovery time after failed promotions | New |
| 7.9.13 | **Human approval boundary for hard policy changes.** Autonomous system may tune models/planning parameters, but cannot mutate legal/safety/compliance constraints without explicit approval | Extends Phase 2 |
| 7.9.14 | **Deterministic experiment journal contract.** Every experiment must record pre-registered success/failure criteria and final verdict in `HistoryJournal` before promotion decision | Extends 1.1E.2 |
| 7.9.15 | **Fallback memory route for hypothesis evaluation.** When semantic retrieval is uncertain/conflicting, force additional checks against `FactsJournal` and prior failure signatures before proposal approval | Extends 1.1E.3, 1.1E.8 |
| 7.9.16 | **Cross-reference completeness gate.** No autonomous conviction increase unless external evidence is cross-checked with both internal learned memory and deterministic journals | Extends 7.9.8, 1.1E.1 |
| 7.9.17 | **Hash-table internals are profile-gated.** Before any custom open-addressing implementation, require measured bottleneck evidence in targeted paths (deterministic journals, failure-signature index, dedupe caches), plus benchmark win against built-in `Map/Set` under AVRAI workloads. No benchmark win = no custom table rollout | Research-gated, extends 1.1E, 8.1 |
| 7.9.18 | **Memory-bounded temporal simulation algorithms.** Add bounded-space replay policy for long-horizon experiment/planner simulation using checkpoint-and-recompute (rematerialization) and tree-reduction evaluation when memory caps are tight | Extends 6.1, 7.7, 7.9.6 |
| 7.9.19 | **Tier-aware model family for bounded memory.** Maintain dual model lanes (`full_state_model`, `compressed_state_model`) with online agreement checks and deterministic fallback routing by `AgentCapabilityTier` | Extends 7.5, 5.1, 6.5 |
| 7.9.20 | **Atomic-time replay lineage for self-healing.** Stamp every checkpoint, replay segment, and rollback decision with `AtomicTimestamp` lineage IDs so failures can be reconstructed exactly and mitigation policies can be transferred safely across devices | Extends 1.1.3, 7.7.11, 8.1 |
| 7.9.21 | **InvariantSplit formalization for hard guardrails.** Build `IntegrityArbiter` to decompose non-negotiable policy constraints (safety/compliance/consent/quiet-hours) into machine-checkable invariant clauses before promotion decisions | Extends 7.9.5, 7.9.13, 7.7A.8 |
| 7.9.22 | **ProofBackedGate for critical promotions.** Require `GuardrailProof` pass on hard-constraint lanes in addition to metric gates; proof failure blocks rollout even if aggregate outcomes look positive | Extends 7.7.4, 7.7A.3, 10.9.11 |
| 7.9.23 | **ConvictionIntegrityBreach challenge lane.** Add adversarial contradiction checks between model rationales and formal constraint results; quarantine candidate updates when rationale and proof outputs diverge | Extends 7.9.7, 7.9.8, 7.9.11 |
| 7.9.24 | **Contract-first delegation lane.** Build `DelegationContract` for autonomous subtask delegation with explicit acceptance tests, evidence requirements, and fallback routes. Delegation without a contract is blocked | Extends 7.9.5, 7.9.6, 10.9.11 |
| 7.9.25 | **Trust-by-evidence calibration.** Add `DelegationTrustLedger` that updates trust per task family/cohort from measured outcomes and contradiction rates; low-trust lanes are auto-demoted to shadow or routed to approval | Extends 7.9.8, 7.7A.3, 7.9.11 |
| 7.9.26 | **Bounded authority tokens + escalation routing.** Enforce `AuthorityScopeToken` limits (time/budget/data/action class) for delegated actions; scope breaches trigger halt, rollback, and `HumanOverrideRoute` escalation | Extends 7.9.13, 7.7.5, 10.9.12 |
| 7.9.27 | **AdaptiveDepthPolicy for reasoning loops.** Allocate additional recurrent reasoning depth only when uncertainty/impact thresholds are exceeded; default to shallow inference for low-risk queries | Extends 7.5, 6.1, 7.9.6 |
| 7.9.28 | **PonderBudgetController with dynamic halting.** Add tier-aware compute halting policy (`full/standard/basic/minimal`) that enforces latency/battery budgets while preserving high-confidence outcomes | Extends 7.5, 5.2, 6.1 |
| 7.9.29 | **CapabilityBoundaryGate for promotion.** Require boundary evaluations (short-horizon metrics + deep-reasoning stress) before promoting RL/VR-optimized candidates; block rollout on overclaim signatures | Extends 7.7A.3, 7.9.7, 10.9.11 |
| 7.9.30 | **ComputeOptimalTrainingPlanner.** Use scaling-law-informed model/data/compute allocation and stop criteria for training jobs; reject runs that violate compute-efficiency policy | Extends 5.2, ML training governance |
| 7.9.31 | **SyntheticLawStressSuite + data-tier governance.** Add controlled synthetic environments and adversarial compositional tests plus explicit data-quality tiers before promotion to production lanes | Extends 7.9.6, 7.9.12, 10.9.12 |
| 7.9.32 | **Kernel-bound autonomous loop contract.** `AutonomousResearchEngine` must consume immutable kernel manifests (`Purpose/Safety/Truth/Recovery/Learning/Exploration/Federation/Resource/HumanOverride`) before generating hypotheses or experiments |
| 7.9.33 | **Recursive meta-learning audit loop.** Every research cycle must evaluate the prior cycle's process quality (hypothesis validity, protocol adherence, replication quality) and update the next cycle plan automatically |
| 7.9.34 | **First-occurrence issue triage protocol.** First-seen critical contradictions/failures immediately open bounded experiments or mitigation actions; repeated occurrences reuse prior mitigations before novel branching |
| 7.9.35 | **DwellBudgetController for autonomous research.** Apply hard time/attempt ceilings per hypothesis class; unresolved hypotheses auto-route to human review or downgraded confidence state |
| 7.9.36 | **Interdisciplinary purpose expansion governance.** New candidate purposes/goals discovered by research must pass evidence, safety, and contradiction gates before entering active `PurposeKernel` set |
| 7.9.37 | **First-occurrence storm suppression policy.** Add global rate limits, dedupe horizon, and incident bundling rules so critical first-occurrence alerts remain actionable and do not overload autonomous queues |
| 7.9.38 | **Hypothesis dwell objective contracts.** Require per-hypothesis-class objective completion criteria (`target_signal`, `min_effect`, `confidence_floor`, `risk_floor`) before a loop may continue; otherwise auto-stop and escalate |
| 7.9.39 | **High-impact autonomy cycle cap.** For safety/legal/high-impact social domains, enforce maximum autonomous cycle count before mandatory human oversight review with signed disposition |
| 7.9.40 | **Downstream scaling failure-mode taxonomy.** Every candidate must be tagged with observed downstream scaling regime (`predictable`, `inverse`, `nonmonotonic`, `trendless/noisy`, `breakthrough`) and required mitigation playbook before promotion consideration |
| 7.9.41 | **Validation/task/setup sensitivity sweeps.** Require controlled perturbation sweeps across validation corpus, task framing, and eval setup; promotion is blocked when candidate behavior is brittle to benign setup changes |
| 7.9.42 | **Dream hypothesis contract.** Every dream episode must define explicit falsification tests, contradiction probes, and real-world validation plan before it can create `candidate_conviction` artifacts |
| 7.9.43 | **Negative dream archive governance.** Failed dream paths are retained with cause taxonomy (`simulator_exploit`, `ood_gap`, `policy_conflict`, `cohort_harm`, `leakage`) and enforced as anti-repeat suppression priors |
| 7.9.44 | **Dream/reality divergence monitor.** Continuously track drift between DreamEnv predictions and observed outcomes; sustained divergence auto-throttles dream influence and triggers recalibration experiments |
| 7.9.45 | **Belief-tier audit dashboard.** Publish tier transition metrics (promotion/demotion counts, contradiction density, delayed-validation pass rates, override-attempt rejects) for governance review |

> **Required companion specs:** `docs/plans/architecture/AUTONOMOUS_RESEARCH_EXPERIMENTATION_ENGINE.md`, `docs/plans/architecture/DREAM_TRAINING_CONVICTION_GOVERNANCE.md`
>
> **Non-negotiable constraint:** Interdisciplinary and creative framing is required for human-centered hypotheses, but production promotion remains evidence-gated and falsification-first.

---

## Phase 8: Ecosystem Intelligence (AI2AI World Model)

**Tier:** 3 (Depends on Phases 5 and 6)  
**Duration:** 8-10 weeks  
**ML Roadmap Reference:** Section 7.4.8, Section 15.6

### 8.1 Federated World Model Learning

| Task | Description | Extends |
|------|-------------|---------|
| 8.1.1 | Implement world model gradient anonymization (differential privacy on gradients) | Extends `FederatedLearning` |
| 8.1.2 | Implement gradient compression (reduce bandwidth for BLE transfer) | New |
| 8.1.3 | Implement federated aggregation server (Supabase edge function) | Extends `EdgeFunctionService` |
| 8.1.4 | Implement gradient verification (detect poisoned gradients) | New |
| 8.1.5 | Wire into `AI2AIProtocol` for BLE-based gradient sharing | Extends existing |
| 8.1.6 | Add DP-safe journal summary channel: share only aggregate failure-signature counts, hypothesis-class success rates, and rollback incidence (no raw journal entries) | Extends 1.1E.7 |
| 8.1.7 | Add federated contradiction feedback: if global updates conflict with local deterministic outcomes, quarantine candidate update for shadow evaluation | Extends 7.9.8, 7.7.4 |
| 8.1.8 | Add federated self-healing prior sync: distribute known-bad signature hashes and mitigation priors so devices can avoid repeating proven failure patterns | Extends 1.1E.8, 7.7.11 |
| 8.1.9 | Add federated meta-learning split by `locality x model_family` (`reality_model`, `universe_model`, `world_model`) so each family adapts with cohort-appropriate hyperpolicy deltas | Extends 1.1E.16, 10.9.5 |
| 8.1.10 | Add federated kernel-drift monitor: if local nodes diverge from immutable kernel manifests, block update import and issue signed drift alerts | Extends 1.1E.12, 10.9.11 |
| 8.1.11 | Add first-occurrence failure signature propagation with bounded fan-out and dedupe windows so one proven critical failure can trigger immediate preventive mitigation without broadcast storms | Extends 1.1E.14, 10.9.12 |
| 8.1.12 | Add federated dwell-budget harmonization: share recommended dwell/escalation budgets by issue class across similar localities and model families, with local override safety bounds | Extends 1.1E.15, 7.9.35 |
| 8.1.13 | Add anti-fragmentation shared-core policy: enforce minimum global kernel/truth core and bounded local hyperpolicy divergence budgets per `locality x model_family` | Extends 8.1.9, 10.9.5 |
| 8.1.14 | Add periodic cross-locality reconciliation cadence with signed merge proposals and quarantine path when locality-specific gains harm cross-cohort consistency | Extends 8.1.13, 10.9.14 |
| 8.1.15 | Add federated downstream scaling profile registry per `locality x model_family`, including regime class and sensitivity index, so aggregation policies are conditioned on measured scaling reliability | Extends 5.2.20, 7.7.14 |
| 8.1.16 | Add cross-cohort scaling inversion quarantine: if a global candidate improves one cohort but shows inverse/nonmonotonic response in protected cohorts, hold in shadow and require targeted mitigation before promotion | Extends 8.1.15, 10.9.19 |
| 8.1.17 | Add federated dream-policy quarantine lane: share only vetted dream-derived candidates (`candidate_conviction` or higher), never raw dream episodes or speculative labels | Extends 1.1E.20, 7.7.16 |
| 8.1.18 | Add cross-locality dream divergence exchange: publish DP-safe DreamEnv mismatch summaries and block import of dream-derived updates from divergent cohorts until recalibrated | Extends 7.9.44, 10.9.14 |
| 8.1.19 | Add federated belief-tier consistency checks across `reality_model/universe_model/world_model`; reject updates that attempt tier escalation without dual-key evidence receipts | Extends 1.1E.21, 10.9.21 |

### 8.2 Gradient Bandwidth Budget

BLE throughput is ~100KB/s. World model gradients must fit within this constraint or the mesh becomes a bottleneck.

| Task | Description | Target |
|------|-------------|--------|
| 8.2.1 | Define gradient payload size budget: compressed gradient update for 64D model | < 2KB per update (fits BLE MTU) |
| 8.2.2 | Implement gradient quantization: reduce float32 → int8 for mesh transfer, dequantize on receipt | 4x compression |
| 8.2.3 | Implement top-k sparsification: only share the k largest gradient components, zero out the rest | 5-10x compression |
| 8.2.4 | Define hybrid sync strategy: small gradient updates via BLE mesh (< 2KB), full model checkpoints via cloud (`BackupSyncCoordinator`) when WiFi available | Bandwidth-aware |
| 8.2.5 | Test gradient sharing under realistic BLE conditions: multiple peers, interference, partial transfers, reconnections | Integration test |

> **LeCun alignment:** Federated learning in LeCun's framework assumes agents can share learned representations efficiently. The bandwidth constraint is real-world physics that the architecture must respect. Quantized, sparse gradients are standard practice and don't meaningfully degrade convergence.

### 8.3 AI2AI Network Intelligence

| Task | Description | Extends |
|------|-------------|---------|
| 8.3.1 | Replace `DiscoveryManager` hardcoded priority (40/30/20/10) with energy-function-based connection value | Extends existing |
| 8.3.2 | Replace `ConnectionManager` compatibility threshold with learned threshold | Extends existing |
| 8.3.3 | Replace `P2PNodeManager` connection limit (max 8) with dynamic limit based on battery and learning value | Extends existing |
| 8.3.4 | Wire `BatteryAdaptiveBleScheduler` to consider world model training needs (prioritize connections that provide high-value gradients) | Extends existing |

### 8.4 Expert Discovery Over Mesh

`ExpertiseMatchingService._getAllUsers()` currently returns an empty list -- experts can't be found. The energy function can score experts (Phase 4.3), but only if they're discovered first. The BLE mesh already discovers peers; it should also discover expertise.

| Task | Description | Extends |
|------|-------------|---------|
| 8.4.1 | Extend BLE discovery advertisements to include expertise metadata: top 3 expertise dimensions (from `MultiPathExpertiseService`), golden expert flag, geographic hierarchy level | Extends `DeviceDiscoveryService` |
| 8.4.2 | Implement `ExpertiseMatchingService._getAllUsers()` to return mesh-discovered experts + cloud-cached experts (replace empty-list placeholder) | Fixes existing gap |
| 8.4.3 | Wire mesh-discovered experts into action encoder for `consult_expert` action type (new action in taxonomy) | Extends Phase 3.3 |
| 8.4.4 | Wire expert discovery quality into AI2AI connection value (Phase 8.3.1): peers who are experts in complementary domains have higher connection value | Extends Phase 8.3 |
| 8.4.5 | Respect privacy: expertise metadata in BLE advertisements uses anonymized agent IDs (`AgentIdService`), not real user identity. Expertise dimensions are coarse-grained (3 top dimensions, not full profile) | Privacy requirement |

> **LeCun alignment:** In the world model framework, the actor's available action set depends on what entities are observable. If experts can't be discovered, `consult_expert` is never in the action set and the MPC planner can never recommend it. Expert discovery over mesh makes the action space richer and more accurate.

### 8.5 Agent-to-Agent Insight Exchange

Extend AI2AI from 12D personality deltas to structured `AgentInsight` objects. Agents learn from each other's compressed experience without sharing personal data.

| Task | Description | Extends |
|------|-------------|---------|
| 8.5.1 | Define `AgentInsight` model: `category` (coffee_spots, nightlife, nature), `region` (downtown, midtown -- not exact location), `generalization` (high_curation_morning_positive), `confidence` (0.0-1.0), `evidenceCount`, `timestamp` | New |
| 8.5.2 | Implement insight sharing over `AnonymousCommunicationProtocol` with `MessageType.insight`: when agents connect, they share generalizations from semantic memory (Phase 1.1A), not raw episodes | Extends existing |
| 8.5.3 | Implement insight reception: validate received insights, integrate into local semantic memory with lower confidence (foreign insight discount: 0.5x confidence), mark as externally-sourced | New |
| 8.5.4 | Wire insights into world model: received insights become optional context for MPC planner (e.g., "similar-personality agents report coffee spots in Midtown are positive on weekday mornings") | Feeds Phase 6 |

> **ML Roadmap Reference:** Section 16.6, Roadmap Item #39. Agents share compressed experience, not raw data.

### 8.6 Agent-to-Agent Group Negotiation

When agents detect high entanglement between their users, they negotiate group activities. Both agents run world model planning for joint actions and recommend the lowest combined energy option. This is genuinely novel -- no existing app has agents that plan social activities on behalf of users while keeping all personal data on-device.

| Task | Description | Extends |
|------|-------------|---------|
| 8.6.1 | Define `GroupProposal` model: `proposedActivityType` (spot_visit, event_attend), `category` (coffee, music, outdoor), `timeWindow` (saturday_evening), `compatibilityScore`, `vibeProfile` (12D vibe of proposed activity) | New |
| 8.6.2 | Implement entanglement-triggered negotiation: when `QuantumEntanglementMLService` detects high entanglement between two users (via AI2AI), agents initiate group planning | Uses existing |
| 8.6.3 | Implement negotiation protocol: Agent A proposes activity constraints (time, energy level, preference). Agent B evaluates against own user's state and counter-proposes. Both agents run MPC planning for joint actions. Converge on lowest combined energy | New |
| 8.6.4 | Implement privacy-preserving negotiation: agents share vibe profile summaries and availability windows, NOT raw personality states or location. All negotiation via `AnonymousCommunicationProtocol` with `MessageType.groupNegotiation` | Privacy requirement |
| 8.6.5 | Implement joint recommendation: when negotiation converges, both users receive a suggestion: "Want to check out this wine bar Saturday?" with the mutual compatibility explanation | New |
| 8.6.6 | Wire group negotiation outcomes into episodic memory: did both users follow through? Did they enjoy it? This trains the world model on multi-agent outcomes (feeds Phase 4.4 community-perspective energy) | Feeds Phase 4.4 |

> **ML Roadmap Reference:** Section 16.6, Roadmap Item #40. Group negotiation requires: high entanglement detection (existing), world model planning (Phase 6), energy scoring (Phase 4), and mesh communication (Phase 3.6). This is the culmination of the agent architecture.

### 8.7 Chat-Informed Network Intelligence

Chat activity patterns (never content) can inform AI2AI world model learning.

| Task | Description | Extends |
|------|-------------|---------|
| 8.7.1 | Include community chat activity rate as an entity feature in federated gradient sharing (DP-protected) | New |
| 8.7.2 | Use AI2AI chat event insights (from `ConversationInsightsExtractor`) as federated learning signals -- share what personality dimensions changed, not what was said | Extends existing |
| 8.7.3 | Implement AI2AI "conversation value" metric: how much did each AI2AI conversation reduce state uncertainty? Use to prioritize which AI peers to connect with next | New |
| 8.7.4 | Wire `LanguagePatternLearningService` evolution (vocabulary growth, tone shifts) as temporal features for federated aggregation (DP-protected aggregate only) | Extends existing |

### 8.8 Network Monitoring (from legacy Phase 20)

| Task | Description |
|------|-------------|
| 8.8.1 | Implement network health monitoring only AFTER AI2AI propagation is verified working |
| 8.8.2 | Monitor gradient sharing success rates |
| 8.8.3 | Monitor federated aggregation convergence |
| 8.8.4 | Admin dashboard for network intelligence metrics |

### 8.9 Locality Happiness Advisory System

Individual agent happiness stays trapped on-device. Locality agents know "what this area is like" (12D vibe vector) but not "how well agents here are doing." The federated system shares model gradients but not happiness-driven strategies. This section connects all three: agent happiness flows UP to locality agents, struggling localities seek advice from thriving ones, and the whole ecosystem self-heals.

**Philosophy:** The agent's happiness comes first from *deeply learning the person*, then from *guiding the user to real-world activities they enjoy*. When locality happiness is low, it means agents in that area are struggling to fulfill either of those roles. Advisory transfer from thriving localities provides the strategies and patterns that make agents successful elsewhere.

#### 8.9A Happiness Aggregation (Agent → Locality)

| Task | Description | Extends |
|------|-------------|---------|
| 8.9A.1 | **Extend `LocalityAgentUpdateEventV1` with `happinessScore` field (0.0-1.0).** When an agent emits a locality update, include its current happiness from `AgentHappinessService.getSnapshot().score`. Field is optional for backward compatibility (null = unknown). Uses existing emit pipeline via `LocalityAgentUpdateEmitterV1` | Extends `LocalityAgentUpdateEventV1`, `AgentHappinessService` |
| 8.9A.2 | **Extend `LocalityAgentGlobalStateV1` with `aggregateHappiness` field (0.0-1.0).** The Supabase aggregation computes weighted-average happiness from contributing agents in the geohash cell. Also add `happinessSampleCount` (how many agents contributed) and `happinessTrendSlope` (is happiness rising or falling in this locality -- computed from last N updates). Field defaults to 0.5 when no data | Extends `LocalityAgentGlobalStateV1` |
| 8.9A.3 | **Server-side happiness aggregation edge function.** Extend the federated aggregation server (Phase 8.1.3) to compute `aggregateHappiness` per locality from incoming `LocalityAgentUpdateEventV1` updates. Weighted by recency (exponential decay, half-life 7 days). Emit to `locality_agent_global_v1` table alongside existing vector12 aggregation | Extends `EdgeFunctionService`, Phase 8.1.3 |
| 8.9A.4 | **Happiness flows through existing cache/offline pipeline.** When `LocalityAgentGlobalRepositoryV1.getGlobalState()` downloads a locality's global state, `aggregateHappiness` comes with it automatically (it's a field on the existing model). No new download logic needed. Offline: cached value used | Inherits existing |
| 8.9A.5 | **Admin happiness heatmap endpoint.** Expose aggregate happiness per geohash cell via Supabase view for admin monitoring. Wire into `AdminSystemMonitoringService` (Phase 7.3.4). Includes: happiness by geohash, trend direction, sample count, and comparison to city/global averages. Enables geographic anomaly detection (sudden drops = investigate) | Extends `AdminSystemMonitoringService` |

#### 8.9B Advisory Threshold & Strategy Seeking

| Task | Description | Extends |
|------|-------------|---------|
| 8.9B.1 | **Define happiness threshold constant: 0.6 (60%).** When a locality's `aggregateHappiness` drops below this threshold, it enters advisory mode. Threshold is configurable via `FeatureFlagService` for tuning. Hysteresis: must drop below 0.6 to enter advisory mode, must rise above 0.65 to exit (prevents oscillation) | New, extends `FeatureFlagService` |
| 8.9B.2 | **Implement advisory query in `LocalityAgentEngineV1`.** After `inferVector12()` downloads global state and sees `aggregateHappiness < threshold`, the engine triggers an advisory fetch: request strategies from high-happiness (> 0.7) localities with similar vibe profiles (cosine similarity > 0.6 on vector12). Query goes to Supabase: `SELECT * FROM locality_agent_global_v1 WHERE aggregate_happiness > 0.7 ORDER BY cosine_similarity(vector12, my_vector12) DESC LIMIT 5` | Extends `LocalityAgentEngineV1`, `LocalityAgentGlobalRepositoryV1` |
| 8.9B.3 | **Define advisory response model: `LocalityAdvisoryResponseV1`.** Contains: (a) advisor locality key + happiness score, (b) vector12 difference (what's different about the happy locality's vibe profile), (c) recommendation strategy hints -- aggregate statistics from the advisor locality: top 3 action types by positive outcome rate, interest category distribution, co-visitation strength (ties to co-visitation system), temporal patterns (when are agents happiest). All aggregate, never individual | New |
| 8.9B.4 | **Advisory blending in `LocalityAgentEngineV1._blendGlobal()`.** When in advisory mode, blend advisor locality vectors into the global prior with configurable weight (default 0.2 advisory, 0.8 own). This nudges the locality's vibe profile toward what works in similar happy localities. Weight decays over time as own happiness improves (don't depend on advice forever) | Extends `LocalityAgentEngineV1` |
| 8.9B.5 | **Agent trigger for advisory mode.** When locality happiness drops below threshold, fire an agent trigger (Phase 7.4 `AgentTriggerType.localityAdvisory`) that causes the agent to: (a) fetch advisory data, (b) adjust recommendation strategies based on advisory hints, (c) log the advisory event for tracking. This makes the advisory system event-driven, not poll-based | Extends Phase 7.4 agent trigger system |
| 8.9B.6 | **Rate limit advisory queries.** At most one advisory fetch per locality per 24 hours to prevent query storms. Cached locally via `StorageService`. If multiple agents in the same locality trigger advisory, only the first one queries -- others use the cached result | New |

#### 8.9C Cross-Region Advisory Transfer (Global Learning)

| Task | Description | Extends |
|------|-------------|---------|
| 8.9C.1 | **Cross-region advisory matching.** The advisory query (8.9B.2) is NOT limited to nearby geohash cells. The Supabase query searches globally: a struggling locality in Tokyo can receive advisory from a thriving locality in Brooklyn if their vibe profiles are similar. Geographic distance is irrelevant -- vibe similarity is the matching criterion. This is how "same pattern, different place" transfers knowledge | Extends 8.9B.2 |
| 8.9C.2 | **Federated advisory aggregation.** The aggregation server (Phase 8.1.3) computes a global advisory model: across ALL high-happiness localities, what are the common strategy patterns? This global advisory is a fallback for localities with no vibe-similar high-happiness peers. Essentially a "population-level best practices" model, same pattern as pre-seeded global model (Phase 1.5D) but for strategies, not personality | Extends Phase 8.1.3 |
| 8.9C.3 | **Category peer advisory.** Extend Phase 1.5C.3 (Category Peer Transfer) pattern: "coffee shop neighborhoods that are happy do X" transfers to struggling coffee shop neighborhoods. The category layer provides finer-grained advisory than pure vibe similarity. Uses the same DP-protected aggregate statistics pipeline | Extends Phase 1.5C.3 |
| 8.9C.4 | **Advisory effectiveness tracking.** After advisory transfer, track: did the locality's happiness improve within 14 days? Log (locality_key, advisory_source, pre_happiness, post_happiness, strategy_hints_applied). Feed back into the advisory matching model: which advisor-advisee pairings actually work? This makes the advisory system itself self-improving | New |
| 8.9C.5 | **Advisory data for third-party insights (DP-protected).** Extend `ThirdPartyDataPrivacyService` to expose aggregate locality happiness trends and advisory transfer patterns. Third parties receive: happiness heatmaps (geohash-level, never individual), vibe gap analysis (underserved areas), strategy effectiveness by area type. All differentially private, never individual data. Connects to Phase 9.2.6 (Outside Data-Buyer Insights) | Extends `ThirdPartyDataPrivacyService`, Phase 9.2.6 |

#### 8.9D Quantum Hardware Readiness (Architecture Notes -- No Active Tasks)

These notes document how locality happiness maps to quantum computing structures. No action required now.

| Concept | Classical (Today) | Quantum Advantage | Notes |
|---------|-------------------|-------------------|-------|
| **Advisory locality search** | SQL cosine similarity over locality vectors | Grover's search over locality states -- quadratic speedup (sqrt(N) vs N comparisons) | Energy function is already pure/stateless, trivially wrappable as Grover oracle. Same pattern as Quantum MPC search (Phase 11.4B) |
| **Happiness aggregation** | Weighted average on server | Quantum amplitude estimation -- quadratic speedup in precision per sample | When aggregating from thousands of agents, QAE gives better precision with fewer samples |
| **Cross-locality pattern detection** | SQL aggregation + cosine similarity | VQE for finding correlated happiness-driving patterns across high-dimensional state spaces | Same circuit as `CloudQuantumBackend.detectEntanglementPatterns()` stub (Phase 11.4A) |
| **Advisory routing optimization** | Top-5 by similarity (greedy) | QAOA for optimal advisor-advisee matching across the full locality graph | Same pattern as parameter optimization (Phase 11.4A). Useful when locality count exceeds 10,000 |

> **Quantum readiness:** All locality happiness functions are pure (no side effects): aggregation is a pure function of happiness signals, similarity comparison is a pure function of two vectors, advisory selection is a pure search over a dataset. These are trivially convertible to quantum circuits per Phase 11.4's key architectural principle. The `QuantumComputeBackend` abstraction already supports this -- swap the backend, zero callers change.

> **Doors philosophy:** Locality happiness is the ecosystem-level measure of "are we opening doors well?" A high-happiness locality means agents in that area are successfully guiding users to meaningful connections. A low-happiness locality means doors are being missed. The advisory system ensures no locality stays stuck -- it gets help from places where doors are being opened successfully. This is the ecosystem version of "being a good key."

> **Agent happiness model:** The agent's happiness comes from two sources: (1) deeply understanding the user (learning satisfaction), and (2) successfully guiding the user to real-world activities they enjoy (fulfillment satisfaction). Locality happiness aggregates both: if agents are learning well AND users are following through on suggestions, the locality thrives. If not, the advisory system intervenes.

---

## Phase 9: Business Operations & Monetization

**Tier:** Parallel (can run alongside any tier, depends on Phase 2 for compliance)  
**Duration:** 6-8 weeks

### 9.1 Business-Critical Services (Preserve As-Is)

These services are production-ready and independent of the world model:

| Service | Status |
|---------|--------|
| `PaymentService` + `StripeService` | Production |
| `RevenueSplitService` (N-way splits) | Production |
| `SalesTaxService` | Production |
| `RefundService` | Production |
| `ReservationService` (core CRUD) | Production |
| `SignalProtocolService` (encryption) | Production |
| `LegalDocumentService` | Production |
| `BusinessVerificationService` | Production |
| `IdentityVerificationService` | Production |
| `IRSFilingService` | Production |
| `DisputeResolutionService` | Production |
| `FraudDetectionService` | Production |
| `AuditLogService` | Production |
| `LedgerRecorderServiceV0` | Production |

### 9.2 Business Features (from legacy plan)

| Task | Description | Legacy Phase |
|------|-------------|-------------|
| 9.2.1 | Services Marketplace implementation | Legacy 27 |
| 9.2.2 | Brand Discovery & Multi-Party Sponsorship | Active plan |
| 9.2.3 | Event Partnership & Monetization completion | Active plan |
| 9.2.4 | Partnership Profile Visibility | Active plan |
| 9.2.5 | Business-Expert Communication system | Active plan |
| 9.2.6 | **Outside Data-Buyer Insights (DP export).** Detailed implementation below in 9.2.6A-9.2.6G | Legacy 22 |
| 9.2.7 | E-Commerce Data Enrichment (after privacy infra) | Legacy 21 |

### 9.2.6 Third-Party Data Insights Pipeline (DP-Protected)

The `ThirdPartyDataPrivacyService` exists but currently only implements basic anonymization. This section builds the complete pipeline from raw aggregate insights to privacy-protected, commercially valuable data products.

**Principle:** Zero individual user data ever leaves the system. All exports are aggregate, DP-protected, and reversible (AVRAI can revoke access). Third parties see PATTERNS, never PEOPLE.

| Task | Description | Extends |
|------|-------------|---------|
| 9.2.6A | **Define insight product catalog.** Available data products: (1) Locality vibe trends (neighborhood-level vibe vectors over time, min 50 users per locality for DP guarantee), (2) Category demand heatmaps (which entity categories are trending/declining per region), (3) Event attendance prediction signals (aggregate predicted attendance for event types/times/locations), (4) Seasonal pattern reports (how user preferences shift across seasons per region), (5) Organic discovery signals (where new spots are emerging, from Phase 1.7). Each product has a minimum aggregation threshold (k-anonymity floor: 50 users minimum) | Extends `ThirdPartyDataPrivacyService` |
| 9.2.6B | **Implement DP noise injection per product.** Each data product gets Laplace noise calibrated to its privacy budget. Budget allocation: locality vibes get epsilon = 1.0 (low sensitivity, high aggregation), category demand gets epsilon = 0.5 (moderate sensitivity), event attendance gets epsilon = 2.0 (less sensitive, more valuable if precise). Total per-user epsilon budget: 5.0 per quarter. When budget is exhausted, that user's data stops contributing to exports until next quarter. Wire into Phase 2.2.3 epsilon accounting | Extends Phase 2.2.3, `ThirdPartyDataPrivacyService` |
| 9.2.6C | **Implement data product generation pipeline.** Scheduled jobs (weekly or monthly depending on product): (1) Query aggregate data from locality agents and episodic memory aggregates, (2) Apply DP noise, (3) Verify k-anonymity threshold (reject if any cell has < 50 users), (4) Format as JSON/CSV export, (5) Store in access-controlled Supabase storage with audit trail. Pipeline runs server-side, never on-device | New |
| 9.2.6D | **Implement consent verification gate.** Before any user's data contributes to third-party exports, verify they have opted into "anonymous insights sharing" (Phase 2.1.3 granular consent). Users who opt out are COMPLETELY excluded from aggregation (their data is never counted, even anonymously). Show consent rate in admin dashboard (Phase 2.1.8C) | Extends Phase 2.1.3 |
| 9.2.6E | **Implement access control and audit.** Third-party data buyers authenticate via API key. Each API key has: allowed products (subset of catalog), rate limits, data retention requirements (buyer must delete after N days), and audit trail (who accessed what, when). `AdminSystemMonitoringService` tracks all third-party data access. Revocation: AVRAI can instantly revoke any API key, cutting off access | New |
| 9.2.6F | **Implement data buyer onboarding.** Workflow for new third-party data buyers: (1) Application with intended use case, (2) Privacy review (does their use case align with AVRAI's doors philosophy?), (3) Data Processing Agreement signed, (4) API key provisioned, (5) Test access with synthetic data, (6) Production access with real DP-protected data. Reject any buyer whose use case involves re-identification, targeted advertising to individuals, or surveillance | New |
| 9.2.6G | **Revenue attribution tracking.** Track which data products generate revenue, which insight types are most valuable (highest willingness to pay), and which products drive repeat purchases. Feed into business intelligence for AVRAI's own product roadmap: if "organic discovery signals" sell well, invest more in Phase 1.7 infrastructure. Wire into `AdminSystemMonitoringService` financial metrics | Extends `AdminSystemMonitoringService` |

### 9.3 Revenue Projections Enhanced by World Model

The world model doesn't just improve user experience -- it improves business features:
- Better expert-business matching → higher partnership conversion
- Better event recommendations → higher ticket sales
- Better reservation matching → lower no-show rates
- Better data insights → higher-value aggregate data products

---

## Phase 10: Feature Completion, Codebase Reorganization & Polish

**Tier:** Parallel (can run alongside any tier)  
**Duration:** 8-12 weeks

### 10.1 Incomplete Features (from legacy plan)

| Task | Description | Legacy Phase | Status |
|------|-------------|-------------|--------|
| 10.1.1 | Onboarding pipeline fix (remaining items) | Legacy 8 | Mostly complete |
| 10.1.2 | Social Media Integration | Legacy 10 | Ready |
| 10.1.3 | Itinerary Calendar Lists -- **enhanced with list quantum state:** When building itineraries from multiple lists, use list-to-list compatibility (Phase 3.4.12) to suggest complementary list combinations. An itinerary composed of lists with diverse but harmonious vibes (low combined energy) is better than one composed of redundant lists. Wire list worldsheet predictions (Phase 3.4.5) to show how the itinerary's vibe evolves over the planned day | Legacy 13 | Ready (needs world model integration) |
| 10.1.4 | Archetype Template System | Legacy 16 | Ready |
| 10.1.5 | **Spot Recommendation Service** (TODO in `AIRecommendationController`). Pre-world-model: implement `SpotRecommendationService` using existing `VibeCompatibilityService` + `SpotVibeMatchingService` + `QuantumMatchingController` to fill the empty array in `AIRecommendationController._getSpotRecommendations()`. Post-world-model (Phase 6): MPC planner replaces this with energy-function-scored spot ranking. Must include spot outcome pipeline (Phase 1.2.18) for feedback loop | Gap | Missing |
| 10.1.6 | **List Recommendation Service** (TODO in `AIRecommendationController`). Pre-world-model: implement `ListRecommendationService` using list quantum state (Phase 3.4.2) + user-to-list compatibility (Phase 3.4.9) to recommend both AI-generated lists (`SuggestedList` from `PerpetualListOrchestrator`) and user-curated lists (`SpotList`). Post-world-model (Phase 6): MPC planner replaces this with energy-function-scored list ranking via Phase 6.1.8. Must include list decoherence (Phase 3.4.7) as a quality filter -- don't recommend incoherent lists | Gap | Missing |
| 10.1.6A | **List Discovery Feed.** Users need to discover other users' public lists. Implement list browsing/search using list quantum state similarity (Phase 3.4.9), list knot compatibility, and list popularity (follower count, respect count). This is the "list social layer" that turns individual curation into community knowledge | Gap | Missing |
| 10.1.7 | Private Communities membership approval workflow | Active plan | Ready |
| 10.1.8 | Complete `ReservationCreationController` TODOs (availability, rate limits, queue, waitlist) | Gap | Partial |
| 10.1.9 | **Business-to-Patron Matching Service.** `BusinessPatronPreferencesWidget` exists (businesses set demographic, interest, personality preferences) but NO matching service uses these to find/recommend users. Pre-world-model: implement `BusinessPatronMatchingService` using `VibeCompatibilityService` + business preferences + reservation history to recommend patron segments. Post-world-model (Phase 6): MPC planner replaces with energy-function-scored patron matching via Phase 6.1.12. Must respect privacy: business sees aggregate patron segments (e.g., "jazz enthusiasts aged 25-35"), never individual user profiles directly | Gap | Missing |
| 10.1.10 | **Complete `BusinessExpertOutreachService.discoverExperts()`.** Currently stubbed (returns empty list with TODO). Pre-world-model: implement using `BusinessExpertMatchingService` scoring + `ExpertSearchService` for expert discovery. Post-world-model (Phase 6): MPC planner replaces with multi-step partnership planning via Phase 6.1.9. The stub is the most critical gap in the business-expert pipeline -- without it, businesses literally cannot find experts | Gap | Stubbed |
| 10.1.11 | **Complete `BusinessBusinessOutreachService.discoverBusinesses()` TODO.** Has a TODO for `getAllBusinessAccounts()` method. Implement proper business discovery with geographic, category, and vibe-based filtering | Gap | Partial |
| 10.1.12 | **Event Sponsorship Seeking Flow.** Users/communities hosting events have no UI or workflow to actively seek sponsors. Implement: event host marks event as "seeking sponsorship" → `BrandDiscoveryService.findBrandsForEvent()` suggests compatible brands → host sends sponsorship proposal → brand reviews → negotiation → agreement. Currently `BrandDiscoveryService.findBrandsForEvent()` exists but is not wired into any user-facing flow for event hosts to initiate | Gap | Missing UI flow |

### 10.2 Stub/Placeholder Cleanup

The ML Roadmap (Section 1.3, 11.1) identified 4 stub ML services consuming code space and suggesting features that don't work, plus additional stubs throughout the codebase. These must be either implemented or removed.

**ML Service Stubs (Roadmap Section 1.3):**

| Task | Service | Current Status | Action |
|------|---------|---------------|--------|
| 10.2.1 | `PatternRecognition` | Returns hardcoded values, not connected to any flow | Replace with world model pattern detection (Phase 5 transition predictor) OR remove if world model subsumes |
| 10.2.2 | `PredictiveAnalytics` | Returns hardcoded values, not connected to any flow | Replace with MPC planner predictions (Phase 6) OR remove |
| 10.2.3 | `PreferenceLearningEngine` | Returns hardcoded values, not connected to any flow | Replace with energy function learned preferences (Phase 4) OR remove |
| 10.2.4 | `SocialContextAnalyzer` | Returns hardcoded values (e.g., optimal group size = 4), not connected | Replace with community-perspective energy function (Phase 4.4) OR remove |
| 10.2.5 | `FeedbackProcessor` | Structure exists but `_savePreferences`, `_applyModelUpdates` are stubs | Wire to `ContinuousLearningSystem` (Phase 1.6.2), implement stub methods |

**Other Stubs/Placeholders:**

| Task | Description | Action |
|------|-------------|--------|
| 10.2.6 | ObjectBox store (Phase 26 placeholder) -- decide: use for episodic memory or remove. Recommendation: remove, use Drift/SQLite for episodic memory (Phase 1.1) | Decision needed |
| 10.2.7 | `AIMasterOrchestrator` placeholder methods (pattern analysis, predictive analytics, process learning insights, optimize user interface) -- all currently log-only | Implement via world model (Phase 7.1.1) |
| 10.2.8 | `DecisionCoordinator` TODOs (mesh insights, decision logs, caching) | Complete |
| 10.2.9 | `BusinessOnboardingController` Stripe Connect TODO | Complete |
| 10.2.10 | `_checkDataLeakage` and `_validateEntropyLevels` in anonymization: return hardcoded values (0.05 and 0.9), not actually validating anything | Implement real validation |
| 10.2.11 | `_propagateLearningToMesh()` in continuous learning: logs "propagating to mesh" but `ConnectionOrchestrator` has no public `propagateLearningInsight()` API. Learning insights stay local | Fix mesh propagation (Phase 3.6) |
| 10.2.12 | `_saveLearningState()` in `ContinuousLearningOrchestrator`: currently a TODO placeholder | Implement state persistence |
| 10.2.13 | `_saveOrchestrationState()` in `AIMasterOrchestrator`: currently log-only | Implement state persistence |

> **ML Roadmap Reference:** Section 1.3 (stub services), Section 11.1 (architectural gaps). "4 stub ML services consume code space and suggest features that don't work. Either implement or remove."

> **Integration Risk (10.2.1-10.2.4):** The 4 stub ML services have real class files (`lib/core/ml/pattern_recognition.dart`, `lib/core/ml/predictive_analytics.dart`, `lib/core/ml/preference_learning.dart`, `lib/core/ml/social_context_analyzer.dart`) and may be registered in `injection_container.dart` or `injection_container_ai.dart`. **Before removing any stub:** (1) grep for `sl<PatternRecognitionSystem>()` / `sl<PredictiveAnalytics>()` / etc. in all production code, (2) check if any orchestrator or service has them as constructor dependencies, (3) if injected somewhere, replace with world model equivalent first, then remove. Also note: `PreferenceLearningEngine` at `lib/core/ai/continuous_learning/engines/preference_learning_engine.dart` is a DIFFERENT class from the stub `PreferenceLearning` at `lib/core/ml/preference_learning.dart` -- don't confuse them. The engine is real and functional; the stub is not.

> **Integration Risk (10.2.11):** Fixing `_propagateLearningToMesh()` requires wiring into `ConnectionOrchestrator` which currently uses `AdvancedAICommunication`. Phase 3.6 deprecates `AdvancedAICommunication` in favor of `AnonymousCommunicationProtocol`. **Resolution:** Do NOT fix 10.2.11 independently. Let Phase 3.6 (Mesh Communication Unification) handle it -- when `AdvancedAICommunication` is migrated to `AnonymousCommunicationProtocol`, the propagation API should be part of that migration. If 10.2.11 is attempted before 3.6 completes, it will be immediately re-wired.

### 10.3 Internationalization & Localization (i18n/L10n)

The app currently has English-only strings. For global deployment (especially with locality agents learning from global users), the UI, recommendations, and AI explanations must work in multiple languages.

| Task | Description | Extends |
|------|-------------|---------|
| 10.3.1 | **Extract all hardcoded strings to ARB files.** Audit all UI code for hardcoded English strings. Migrate to Flutter's `intl` package with `.arb` (Application Resource Bundle) files. Start with `lib/presentation/` -- every `Text()`, `tooltip`, `label`, `hintText`, and `semanticLabel` gets an `AppLocalizations.of(context).keyName` call. Estimate: ~800-1200 strings across the app | New |
| 10.3.2 | **Implement locale detection and switching.** Auto-detect device locale on first launch. Allow manual locale override in settings. Persist preference in `SharedPreferences`. Support: English (en), Spanish (es), French (fr), German (de), Japanese (ja), Portuguese (pt), Chinese Simplified (zh-CN), Arabic (ar), Korean (ko) as initial targets. Add more based on user demand | New |
| 10.3.3 | **RTL layout support.** For Arabic (and future RTL languages): verify all layouts use `Directionality`-aware padding/alignment. Audit `Row`, `Positioned`, `Padding` widgets for hardcoded left/right that should be start/end. Three.js visualizations and knot displays need RTL mirroring tested | New |
| 10.3.4 | **AI explanation localization.** Phase 2.1.8A generates template-based explanations ("Suggested because you enjoy [category]"). These templates must be localized per language, respecting grammar differences (subject-verb-object vs. subject-object-verb). Store templates per locale. Energy function feature names must have localized display names | Extends Phase 2.1.8A |
| 10.3.5 | **Spot/event/community name handling.** Entity names are user-generated and multilingual. Do NOT translate spot names (a Japanese restaurant in NYC keeps its Japanese name). DO translate category labels, UI chrome, and system-generated text. Ensure search works across character sets (CJK, Arabic, Cyrillic) via Unicode normalization | New |
| 10.3.6 | **Date/time/currency/distance localization.** Use `intl` package formatters for: date/time formats (MM/DD vs DD/MM), currency symbols, distance units (miles vs km). Respect device locale settings. Distance display in recommendations (e.g., "0.3 mi away" vs "500m away") must use locale-appropriate units | New |
| 10.3.7 | **Locality agent language context.** When a locality agent operates in a region with a dominant language (e.g., Tokyo → Japanese), include language as a locality feature. This helps the federated learning system (Phase 8.1) weight cross-region knowledge transfer appropriately: a locality in Tokyo sharing advisory insights with a locality in Osaka is higher-value than sharing with one in NYC, partly due to shared language context | Extends Phase 8.2, `LocalityAgentEngineV1` |

> **Scope note:** Full AI agent conversation in multiple languages requires multilingual SLM support (Phase 7.3), which is a separate concern from UI localization. This section covers UI and recommendation explanation localization. Agent chat localization depends on SLM language capabilities.

### 10.4 Accessibility (a11y)

Accessibility is not an afterthought. Users with disabilities must have full access to AVRAI's intelligence features. "Every spot is a door" applies literally -- the app must open doors for all users.

| Task | Description | Extends |
|------|-------------|---------|
| 10.4.1 | **Semantic labels for all interactive elements.** Audit every `GestureDetector`, `InkWell`, `IconButton`, and custom widget for `Semantics` labels. Every tappable element needs a descriptive label for screen readers (VoiceOver/TalkBack). Priority: recommendation cards, navigation, feedback buttons (thumbs up/down), one-tap reject (Phase 1.4.6) | New |
| 10.4.2 | **Screen reader navigation flow.** Define logical reading order for key screens: home/perpetual list, spot detail, event detail, community page, settings. Ensure `Semantics` `sortKey` is set so screen readers traverse content in the intended order (not DOM order). Test with VoiceOver (iOS) and TalkBack (Android) | New |
| 10.4.3 | **Color contrast compliance (WCAG AA).** Verify all `AppColors` meet WCAG AA contrast ratios (4.5:1 for normal text, 3:1 for large text). Audit design tokens. Fix any that fail. Test in light and dark mode. Ensure energy function explanations (Phase 2.1.8A) are readable with sufficient contrast | Extends `AppColors`, `AppTheme` |
| 10.4.4 | **Dynamic text size support.** Respect system-level text scaling (iOS Dynamic Type, Android font scale). Test at 1.0x, 1.5x, and 2.0x scales. Ensure layouts don't overflow or clip. Critical screens: recommendation cards, feedback UI, event details, settings | New |
| 10.4.5 | **Knot visualization alt-text.** Three.js knot and fabric visualizations are inherently visual. Provide meaningful alt-text alternatives: "Your personality knot: most prominent traits are [top 3 dimensions]. Knot complexity: [simple/moderate/complex]." Derived from `PersonalityKnotService` data. Accessible via `Semantics` on the knot widget | Extends `ThreeJsBridgeService` widgets |
| 10.4.6 | **Haptic feedback alternatives.** `HapticsService` provides tactile feedback. For users who disable haptics or use devices without haptic motors, provide visual or audio alternatives: subtle animation or sound effect. Ensure haptic feedback is informational, not decorative (used for confirmation, not just flair) | Extends `HapticsService` |
| 10.4.7 | **Knot audio sonification as primary experience.** For visually impaired users, `KnotAudioService` sonification becomes the PRIMARY way to experience their personality knot (not just a novelty feature). Ensure audio sonification conveys the same information as the visual: which traits are dominant, how the knot has evolved, stability vs. flux. Add voice description option: "Your knot sounds [description] because [trait] is growing" | Extends `KnotAudioService` |
| 10.4.8 | **Reduce motion mode.** For users who enable "Reduce Motion" system setting, disable: knot animation, worldsheet animation, parallax effects, page transitions with heavy animation. Replace with crossfade or instant transitions. Detect via `MediaQuery.disableAnimations` | New |

### 10.5 Unique Features to Preserve

These are differentiating features that don't need world model changes:

| Feature | Service | Status |
|---------|---------|--------|
| Knot audio sonification | `KnotAudioService`, `WavetableKnotAudioService` | Production |
| Dynamic Island knot display | `DynamicIslandKnotService` | Production |
| iOS home screen widgets | `KnotWidget.swift`, `NearbySpotWidget.swift`, `ReservationWidget.swift` | Production |
| Three.js knot/fabric visualization | `ThreeJsBridgeService`, widgets | Production |
| World orientation sensor fusion | `WorldOrientationService` | Production |
| Haptic feedback | `HapticsService` | Production |

### 10.6 User Testing Checkpoint

Before proceeding to Tier 3 (industry integrations), validate that the intelligence-first architecture actually improves user experience.

| Task | Description |
|------|-------------|
| 10.4.1 | Define success metrics: recommendation acceptance rate, event attendance rate, community retention (7-day, 30-day), average energy function confidence, cold-start-to-useful time |
| 10.4.2 | Conduct internal dogfooding: team uses the app with world model active for 2 weeks, document friction points |
| 10.4.3 | Conduct closed beta: 50-100 users with world model (treatment) vs. formula-only (control), measure success metrics |
| 10.4.4 | Analyze results: if world model underperforms formula on any key metric, identify root cause and fix before proceeding |
| 10.4.5 | Document "learned surprises": what did the energy function discover that the formulas missed? What counterintuitive recommendations worked? |
| 10.4.6 | Validate privacy experience: can users understand what the AI learns about them? Does consent flow feel trustworthy? |
| 10.4.7 | Validate offline experience: does the app feel responsive with on-device inference? Any noticeable battery impact during normal use? |

> **Gate:** Phase 11 (Tier 3) should NOT begin until this testing checkpoint demonstrates that the world model is at least as good as the formula baseline on all key metrics.

### 10.7 Codebase Structure Reorganization — Immediate (Run Now, Parallel With Phases 1-2)

**Why now:** `lib/core/services/` has 196 flat `.dart` files and `lib/core/models/` has 123 flat `.dart` files. Navigating either directory is painful and slows every implementation task. Organizing these now gives new Phase 1-4 services clean landing zones. These are low-risk moves (renaming + import updates only, no logic changes) that won't conflict with active intelligence work.

**Why not later:** Waiting until after Phases 1-4 means 20-40 new services land in an already-chaotic flat directory, making the eventual cleanup harder. The domain groupings (business, community, expertise, payment, quantum, etc.) are stable and won't change regardless of world model architecture decisions.

#### 10.7.1 Services Directory Reorganization — Domain-Clustered Files

Move the ~66 service files that clearly belong to existing domain clusters into subdirectories. Many subdirectories already exist (e.g., `services/quantum/`, `services/reservation/`, `services/payment/`); others need creation.

| Task | Domain Cluster | Files | Target Subdirectory |
|------|---------------|-------|-------------------|
| 10.7.1a | Business services | `business_service.dart`, `business_member_service.dart`, `business_expert_chat_service_ai2ai.dart`, `business_place_knot_service.dart`, etc. (~12 files) | `services/business/` (exists) |
| 10.7.1b | Community/club services | `community_service.dart`, `community_event_service.dart`, etc. (~8 files) | `services/community/` (exists) |
| 10.7.1c | Expertise services | `expert_search_service.dart`, `expertise_network_service.dart`, `multi_path_expertise_service.dart`, etc. (~8 files) | `services/expertise/` (create) |
| 10.7.1d | Social media services | `social_media_connection_service.dart`, `social_media_discovery_service.dart`, `social_media_vibe_analyzer.dart`, `social_enrichment_service.dart` (~5 files) | `services/social_media/` (exists) |
| 10.7.1e | Calling score services | `calling_score_data_collector.dart`, etc. (~5 files) | `services/calling_score/` (create) |
| 10.7.1f | Event services | `event_recommendation_service.dart`, `event_safety_service.dart`, `post_event_feedback_service.dart`, etc. (~5 files) | `services/events/` (create) |
| 10.7.1g | List/analytics services | `list_notification_service.dart`, etc. (~5 files) | `services/lists/` (create) |
| 10.7.1h | Payment/stripe/tax/payout services | `sales_tax_service.dart`, `refund_service.dart`, `revenue_split_service.dart`, `irs_filing_service.dart`, `pdf_generation_service.dart`, `product_sales_service.dart`, `product_tracking_service.dart` (~7 files) | `services/payment/` (exists) |
| 10.7.1i | Cross-app services | `cross_app_consent_service.dart`, `cross_locality_connection_service.dart` (~3 files) | `services/cross_app/` (create) |
| 10.7.1j | Admin services | `admin_privacy_filter.dart`, `audit_log_service.dart`, `role_management_service.dart` (~4 files) | `services/admin/` (exists) |

#### 10.7.2 Services Directory Reorganization — Unclustered Files

Triage the remaining ~130 flat service files into new domain groupings. These files don't have an obvious existing cluster but can be grouped by functional area.

| Task | Functional Group | Example Files | Target Subdirectory |
|------|-----------------|---------------|-------------------|
| 10.7.2a | Security & encryption | `field_encryption_service.dart`, `hybrid_encryption_service.dart`, `message_encryption_service.dart`, `secure_mapping_encryption_service.dart`, `mapping_key_rotation_service.dart`, `security_validator.dart`, `identity_verification_service.dart` | `services/security/` (create) |
| 10.7.2b | Device & hardware | `device_capabilities.dart`, `device_capability_service.dart`, `device_motion_service.dart`, `haptics_service.dart`, `live_activity_service.dart`, `nearby_interaction_service.dart`, `wearable_data_service.dart`, `wifi_fingerprint_service.dart`, `world_orientation_service.dart` | `services/device/` (create) |
| 10.7.2c | AI & ML helpers | `ai_improvement_tracking_service.dart`, `ai_search_suggestions_service.dart`, `ai2ai_learning_service.dart`, `llm_service.dart`, `model_retraining_service.dart`, `model_safety_supervisor.dart`, `model_version_manager.dart`, `on_device_ai_capability_gate.dart`, `foundation_models_service.dart` | `services/ai_infrastructure/` (create) |
| 10.7.2d | Analytics & tracking | `app_usage_service.dart`, `brand_analytics_service.dart`, `media_tracking_service.dart`, `usage_pattern_tracker.dart`, `calendar_tracking_service.dart`, `trending_analysis_service.dart` | `services/analytics/` (create) |
| 10.7.2e | Personality & matching | `personality_analysis_service.dart`, `personality_sync_service.dart`, `vibe_compatibility_service.dart`, `spot_vibe_matching_service.dart`, `age_compatibility_filter.dart`, `attraction_12d_resolver.dart`, `patron_prefs_to_12d_mapper.dart`, `group_formation_service.dart`, `group_matching_service.dart`, `partnership_matching_service.dart` | `services/matching/` (create) |
| 10.7.2f | Fraud & compliance | `fraud_detection_service.dart`, `review_fraud_detection_service.dart`, `dispute_resolution_service.dart` | `services/fraud/` (create) |
| 10.7.2g | Google/Maps/Places | `google_place_id_finder_service.dart`, `google_place_id_finder_service_new.dart`, `google_places_cache_service.dart`, `google_places_sync_service.dart`, `mapkit_places_cache_service.dart`, `mapkit_search_channel.dart`, `geohash_service.dart`, `place_claim_service.dart` | `services/places/` (create) |
| 10.7.2h | Notifications & outreach | `agent_happiness_service.dart`, `dynamic_threshold_service.dart`, `predictive_analysis_service.dart`, `expert_recommendations_service.dart` | `services/recommendations/` (create) |
| 10.7.2i | Network & connectivity | `enhanced_connectivity_service.dart`, `network_analysis_service.dart`, `network_circuit_breaker.dart`, `rate_limiting_service.dart`, `edge_function_service.dart` | `services/network/` (create) |
| 10.7.2j | Partnership & sponsorship | `partnership_profile_service.dart`, `partnership_service.dart`, `sponsorship_service.dart`, `mentorship_service.dart` | `services/partnerships/` (create) |
| 10.7.2k | Storage & infrastructure | `storage_service.dart`, `storage_health_checker.dart`, `supabase_service.dart`, `config_service.dart`, `feature_flag_service.dart`, `deferred_initialization_service.dart`, `deployment_validator.dart`, `logger.dart`, `performance_monitor.dart`, `ab_testing_service.dart` | `services/infrastructure/` (create) |
| 10.7.2l | User identity | `user_anonymization_service.dart`, `user_business_matching_service.dart`, `user_name_resolution_service.dart`, `user_preference_learning_service.dart`, `agent_id_service.dart`, `agent_id_migration_service.dart`, `permissions_persistence_service.dart` | `services/user/` (create) |
| 10.7.2m | Remaining uncategorized | Any files not captured above: `cancellation_service.dart`, `legal_document_service.dart`, `dm_message_store.dart`, `friend_chat_service.dart`, `friend_qr_service.dart`, `search_cache_service.dart`, `oauth_deep_link_handler.dart`, etc. | Review individually — place in closest domain or `services/misc/` as last resort |

> **Import update strategy:** After each batch of file moves, run `dart fix --apply` for automatic import updates where possible. For remaining broken imports, use project-wide find-and-replace: `import 'package:spots/core/services/old_file.dart'` → `import 'package:spots/core/services/new_subdirectory/old_file.dart'`. Verify with `flutter analyze`.

> **Barrel file strategy:** After organizing each subdirectory, create a barrel file (e.g., `services/business/business.dart`) that re-exports all public APIs. This stabilizes import paths for consumers -- future reorganization within a subdirectory only requires updating the barrel file, not all consumers.

#### 10.7.3 Models Directory Reorganization

Group the 123 flat model files in `lib/core/models/` into domain subdirectories matching the service domains. Models are data classes with minimal behavior -- low risk.

| Task | Domain | Example Files | Target Subdirectory |
|------|--------|---------------|-------------------|
| 10.7.3a | Business models | `business_account.dart`, `business_member.dart`, `business_verification.dart`, `business_expert_*.dart`, `business_patron_preferences.dart`, `brand_*.dart`, `partnership_*.dart` | `models/business/` |
| 10.7.3b | Community models | `community.dart`, `community_event.dart`, `community_validation.dart`, `club.dart`, `club_hierarchy.dart` | `models/community/` |
| 10.7.3c | Event models | `event_feedback.dart`, `event_matching_score.dart`, `event_partnership.dart`, `event_safety_guidelines.dart`, `event_success_*.dart`, `event_template.dart`, `expertise_event.dart` | `models/events/` |
| 10.7.3d | Payment/tax models | `payment.dart`, `payment_intent.dart`, `payment_result.dart`, `tax_*.dart`, `refund_*.dart`, `revenue_split.dart` | `models/payment/` |
| 10.7.3e | User/personality models | `user.dart`, `user_preferences.dart`, `user_role.dart`, `user_vibe.dart`, `user_movement_pattern.dart`, `mood_state.dart`, `preferences_profile.dart`, `language_profile.dart`, `onboarding_data.dart` | `models/user/` |
| 10.7.3f | Quantum/matching models | `quantum_prediction_features.dart`, `quantum_satisfaction_features.dart`, `matching_input.dart`, `matching_result.dart`, `group_matching_result.dart`, `decoherence_pattern.dart` | `models/quantum/` |
| 10.7.3g | Location/geographic models | `locality.dart`, `locality_value.dart`, `large_city.dart`, `neighborhood_boundary.dart`, `geographic_expansion.dart`, `cross_locality_connection.dart` | `models/geographic/` |
| 10.7.3h | Social media models | `social_media_connection.dart`, `social_media_insights.dart`, `social_media_profile.dart` | `models/social_media/` |
| 10.7.3i | Expertise models | `expertise_level.dart`, `expertise_pin.dart`, `expertise_progress.dart`, `expertise_requirements.dart`, `local_expert_qualification.dart`, `multi_path_expertise.dart` | `models/expertise/` |
| 10.7.3j | Fraud/disputes models | `fraud_*.dart`, `dispute.dart`, `dispute_message.dart`, `dispute_status.dart` | `models/disputes/` |
| 10.7.3k | Sponsorship models | `sponsorship.dart`, `sponsorship_status.dart`, `multi_party_sponsorship.dart` | `models/sponsorship/` |
| 10.7.3l | Remaining models | `cancellation.dart`, `visit.dart`, `spot.dart`, `spot_vibe.dart`, `list.dart`, `unified_*.dart`, etc. | Place in closest domain or `models/core/` |

> **Import impact:** Models are referenced by ~527 files across the codebase. Use barrel files to minimize churn. Create `models/business/business_models.dart`, `models/events/event_models.dart`, etc., and have them re-export all models in the subdirectory. Then update import sites to use barrel files rather than individual model files.

> **Preserve `models/entities/`:** The existing `entities/` subdirectory (`list.dart`, `spot.dart`, `user.dart`) stays as-is -- these are Drift/database entity models, distinct from the domain models.

### 10.8 Codebase Structure Reorganization — Deferred (Timing-Dependent)

These reorganization tasks depend on active intelligence work settling first. Doing them prematurely would cause merge conflicts with in-flight feature development or require re-reorganizing after new files land.

#### 10.8.1 AI/ML Directory Consolidation (After Phase 4 Completes)

**Why deferred:** Phases 3-5 will create 15-20 new files in `lib/core/ai/` (state encoder, feature extractor, transition predictor, energy function components). Reorganizing `ai/` now means reorganizing again when those files land. Additionally, the `ai/` vs `ml/` boundary is unclear -- the Phase 4 energy function work will naturally clarify which files belong where.

**Trigger:** Begin after Phase 4 (Energy Function) is complete and Phase 5 is underway.

| Task | Description |
|------|-------------|
| 10.8.1a | **Merge `lib/core/ml/` into `lib/core/ai/`.** `ml/` has 15 files (4 deprecated stubs slated for removal in 10.2.1-10.2.4). After stub removal, ~11 files remain. These are functionally inseparable from `ai/` -- `feedback_processor.dart`, `inference_orchestrator.dart`, `preference_learning.dart`, etc. The boundary between "AI" and "ML" is artificial in this codebase. Move all remaining `ml/` files into appropriate `ai/` subdirectories |
| 10.8.1b | **Group `ai/` flat files into subdirectories.** After the ml/ merge, `ai/` will have ~55-60 flat files plus existing subdirectories. Group into: `ai/rag/` (rag_*.dart, retrieval_*.dart, scope_classifier.dart, answer_layer_orchestrator.dart), `ai/facts/` (facts_index.dart, facts_local_store.dart, structured_facts.dart, structured_facts_extractor.dart), `ai/learning/` (continuous_learning_system.dart, ai_learning_demo.dart, cloud_learning.dart, feedback_learning.dart, personality_learning.dart, ai_self_improvement_system.dart), `ai/orchestration/` (ai_master_orchestrator.dart, decision_coordinator.dart, action_executor.dart, action_parser.dart, action_models.dart), `ai/communication/` (advanced_communication.dart, collaboration_networks.dart, network_cue_retrieval.dart, network_retrieval_cue.dart), `ai/privacy/` (privacy_protection.dart, bypass_intent_detector.dart), `ai/vibe/` (vibe_analysis_engine.dart) |
| 10.8.1c | **Create barrel files** for each new `ai/` subdirectory |

#### 10.8.2 Quantum Code Consolidation (After Phase 7 Completes)

**Why deferred:** Quantum code currently lives in 3 locations: `lib/core/services/quantum/` (17 files -- integration/matching services), `lib/core/ai/quantum/` (17 files -- compute backends/engines), and 2 flat `quantum_*.dart` files in `services/`. Phase 7 (Orchestrator Restructuring) rewires quantum orchestrators and the evolution cascade (7.1.2). Consolidating quantum code before that restructuring means moving files that will immediately be modified, risking merge conflicts.

**Trigger:** Begin after Phase 7 (Orchestrator Restructuring) is complete.

| Task | Description |
|------|-------------|
| 10.8.2a | **Decide canonical quantum home.** Recommendation: `lib/core/ai/quantum/` for compute primitives (backends, engines, state representations) and `lib/core/services/quantum/` for integration services (matching, prediction, metrics). The split is: `ai/quantum/` = "how quantum math works," `services/quantum/` = "how quantum math is applied to users/spots/events." This preserves the existing split rather than forcing everything into one directory |
| 10.8.2b | **Move the 2 flat quantum files** (`quantum_prediction_enhancer.dart`, `quantum_satisfaction_enhancer.dart`) from `services/` root into `services/quantum/` |
| 10.8.2c | **Verify no circular dependencies** between `ai/quantum/` and `services/quantum/`. Dependency must flow one way: `services/quantum/` depends on `ai/quantum/`, never the reverse |
| 10.8.2d | **Create barrel files** for both quantum directories |

#### 10.8.3 Domain Layer Decision (After Phase 7 Completes)

**Why deferred:** `lib/domain/` currently has 20 files (5 repository interfaces, 15 use cases) covering only auth, lists, spots, search, and communities. The Master Plan creates no new domain-layer components -- all new services go into `core/`. The decision of whether to commit to Clean Architecture's domain layer or merge it into `core/` depends on seeing the final shape of the world model architecture.

**Trigger:** Begin after Phase 7 (Orchestrator Restructuring) is complete. By then, the world model components (Phases 3-6) are built and the integration pattern is clear.

| Task | Description |
|------|-------------|
| 10.8.3a | **Audit domain/ usage.** Count how many files import from `lib/domain/`. If < 20 files reference it, the abstraction layer isn't earning its keep |
| 10.8.3b | **Decision: expand or merge.** Option A: Commit to Clean Architecture -- create use cases and repository interfaces for world model components (energy function, transition predictor, MPC planner). Option B: Merge `domain/` into `core/` -- move repository interfaces into `core/services/interfaces/` (which already exists) and inline use cases into their calling services. **Recommendation:** Option B (merge), because the Master Plan's 330+ services already live in `core/` and the 20-file `domain/` layer creates indirection without providing meaningful separation |
| 10.8.3c | **Execute chosen option** and update all import paths |

> **Injection container note:** The 11 injection container files (`injection_container.dart` at 2,157 lines, `injection_container_ai.dart` at 1,096 lines, etc.) are a symptom of the flat services directory, not a separate problem. As services move into domain subdirectories (10.7.1-10.7.2), the DI registrations should follow: each domain subdirectory gets its own registration file (e.g., `services/business/business_di.dart`), called from the main `injection_container.dart`. This happens naturally during 10.7 execution -- no separate phase needed.

### 10.9 Reality Model Robustness Hardening (Self-Learning + Self-Healing)

These tasks convert the self-learning/self-healing architecture from "planned behavior" into enforceable reliability guarantees. This section is a release gate for autonomous adaptation features.

| Task | Description | Extends |
|------|-------------|---------|
| 10.9.1 | **Production readiness gate for adaptive paths.** Add `ProductionReadinessGate` checks that block enabling autonomous learning/healing when critical code paths contain TODO/log-only placeholders. Required checks: (a) persistence implemented for orchestration/learning state, (b) fail-closed behavior on persistence failure, (c) no placeholder methods in recommendation/training/rollback critical paths | Phases 7.1, 10.2.12, 10.2.13 |
| 10.9.2 | **Trigger reliability specification.** Define idempotency keys, dedupe window, ordering rules, and replay on restart for `AgentTriggerService`. Add trigger fuzz tests and reliability SLOs: dropped-trigger rate, duplicate-trigger rate, trigger-to-action latency | Phase 7.4 |
| 10.9.3 | **Signal quality governance for rollback decisions.** Require minimum sample sizes and confidence bounds before self-healing actions. Rollback decisions need at least two corroborating signals (e.g., happiness drop + recommendation outcome degradation). Add anti-flap hysteresis and cooldown windows | Phase 7.7A, 8.8 |
| 10.9.4 | **Atomic rollback bundles.** Rollback unit becomes `(model version + feature flags + orchestrator policy + schema compatibility target)`, not model weight alone. Implement soft rollback (weights only) and hard rollback (full bundle) with provenance logs and rollback drills | Phase 7.7 |
| 10.9.5 | **Federated robustness cohorts.** Federated aggregation must evaluate per-cohort (device tier, locality type, language, recency bucket), not global mean only. Add bounded update magnitude, canary rounds, and shadow evaluation before promoting global weights | Phase 8.1, 7.5 |
| 10.9.6 | **Advisory quarantine and credibility controls.** Locality advisory strategies enter shadow/quarantine mode before broad rollout. Add advisor credibility scores with decay, anomaly detection, and fast advisory rollback independent of model rollback | Phase 8.9 |
| 10.9.7 | **Schema/model compatibility matrix testing.** Add CI matrix tests across current + previous N model versions against episodic memory schema versions. Block deployment if forward/backward compatibility fails | Phase 7.7.1, 1.1 |
| 10.9.8 | **Tier parity and fairness guardrails.** Define expected behavior envelopes across capability tiers for core outcomes. Add tier-specific regression checks and alerting to prevent lower-tier silent degradation | Phase 7.5 |
| 10.9.9 | **Causal observability baseline.** Every adaptive decision logs model version, feature flags, trigger source, confidence, and rollback provenance with trace IDs. Add mandatory dashboards for drift, failed-heal cycles, rollback outcomes, and unexplained outcome drops | Phase 7.3.4, 8.8 |
| 10.9.10 | **Adversarial hardening for learning channels.** Add poisoning/outlier detection, signed federated/advisory updates, participant reputation weighting, and emergency kill switches to disable specific learning pathways without shutting down the whole agent | Phase 2.5, 8.1, 8.9 |
| 10.9.11 | **Autonomous change control policy.** Any self-updating component must declare immutable policy space, promotion gates, rollback path, and human override controls. Autonomous updates are staged (shadow → canary → partial → full) by policy, not per-feature discretion | Hardcoded Invariants section, 7.7A |
| 10.9.12 | **Universal break-to-learning healing loop.** Any subsystem break (perception, ingest, reasoning, memory, planner, federated sync, advisory, rollout, communication) must auto-create a healing cycle entry, auto-schedule remediation, and feed break telemetry back into learning quality metrics (time-to-detect, time-to-heal, recurrence, impact radius). | 1.1E.8, 7.3.4, 7.4, 7.7, 8.1, 8.8 |
| 10.9.13 | **Kernel integrity enforcement.** CI/runtime must verify immutable kernel manifests are signed, versioned, and unchanged by self-updating components; non-compliant updates fail closed | 1.1E.12, 7.9.32 |
| 10.9.14 | **Recursive meta-learning anti-drift gate.** Promotion requires macro-vs-micro alignment metrics: local learning wins cannot ship if they violate global truth constraints, contradiction tolerances, or purpose kernel bounds | 5.2.17, 5.2.18, 8.1.9 |
| 10.9.15 | **Universal first-occurrence + dwell SLA enforcement.** Every subsystem must enforce first-occurrence triage latency and dwell-budget escalation policy with observable SLOs and recurrence suppression checks | 1.1E.14, 1.1E.15, 6.2.17, 6.2.18, 10.9.12 |
| 10.9.16 | **Kernel lifecycle governance gate.** Enforce upgrade/downgrade protocol, compatibility proofs, rollback TTL compliance, and emergency freeze rehearsal before kernel promotion | 1.1E.17, 1.1E.18, 10.9.13 |
| 10.9.17 | **First-occurrence storm-control SLO.** Enforce global alert rate caps, dedupe horizon, and incident-bundle quality thresholds; block rollout if first-occurrence pipeline exceeds storm limits | 7.9.37, 8.1.11, 10.9.15 |
| 10.9.18 | **High-impact autonomy oversight SLO.** Enforce maximum autonomous cycle count and mandatory human review latency for high-impact domains; no silent bypass allowed | 7.9.39, 10.9.11 |
| 10.9.19 | **Downstream scaling reliability gate.** Promotion requires cross-setting scaling robustness evidence (validation/task/setup sensitivity sweeps), explicit regime classification, and documented mitigation for inversion/nonmonotonic responses | 5.2.20, 5.2.21, 7.7.15, 7.9.40, 7.9.41, 8.1.16 |
| 10.9.20 | **System hijack red-team gate.** Maintain and execute canonical red-team matrix across auth/session, backend authorization, secrets/CI, federated/advisory channels, encryption lifecycle, BLE discovery metadata, third-party exports, autonomy governance, logging, supply chain, and operator controls. Critical lanes block autonomous scope expansion when red | 2.1, 2.5, 7.7, 8.1, 9.2.6, 10.9.10-10.9.18 |
| 10.9.21 | **Dream-conviction hierarchy safety gate.** Enforce immutable belief-tier precedence, no dream override of proven convictions, dual-key evidence requirement for tier elevation, simulator-exploit containment, and fail-closed dream promotion control | 1.1E.20, 1.1E.21, 5.2.23, 5.2.26, 7.7.16, 8.1.19 |

> **Release policy:** No autonomous adaptation feature (including 7.7, 7.7A, 8.1, 8.9 promotion paths) may be marked production-ready until 10.9.1-10.9.4 are complete and validated in CI.

#### 10.9A Execution Mapping (Owner + Acceptance + Duration)

| Task | Owner Team | Key Dependencies | Est. Duration | Acceptance Criteria |
|------|------------|------------------|---------------|---------------------|
| 10.9.1 | AI Platform + Reliability Engineering | 7.1, 10.2.12, 10.2.13 | 4-6 days | `ProductionReadinessGate` exists in CI; critical adaptive paths fail build if placeholder/TODO/log-only methods are detected; persistence failures are fail-closed with tests proving no unsafe fallback |
| 10.9.2 | Mobile Platform + AI Runtime | 7.4 | 5-7 days | `AgentTriggerService` supports idempotency keying, dedupe, replay-on-restart; trigger fuzz suite added; SLO dashboards show dropped triggers < 0.1%, duplicate trigger handling verified, p95 trigger-to-action latency within target |
| 10.9.3 | Recommender/ML + Experimentation | 7.7A, 8.8 | 4-6 days | Rollback decision engine enforces minimum sample thresholds + confidence bounds; dual-signal confirmation required; anti-flap hysteresis/cooldown tested with synthetic sparse/noisy signal scenarios |
| 10.9.4 | AI Infrastructure + Release Engineering | 7.7 | 5-8 days | Rollback artifacts are bundle-based (`model + flags + orchestrator policy + schema target`); soft/hard rollback both implemented; rollback provenance logged; quarterly rollback drill script passes in staging |
| 10.9.5 | Federated Learning + Data Science | 8.1, 7.5 | 1-2 weeks | Aggregation reports per cohort (tier/locality/language/recency); bounded update magnitude enforced; canary + shadow promotion pipeline implemented; no-regression gates required per cohort before promotion |
| 10.9.6 | Locality Intelligence + Safety Engineering | 8.9 | 1-2 weeks | Advisory strategies support quarantine/shadow phase; advisor credibility + decay model implemented; anomaly detector can disable advisory source; advisory rollback can execute independently of model rollback |
| 10.9.7 | Data Platform + QA Automation | 7.7.1, 1.1 | 4-6 days | CI compatibility matrix runs current + previous N model versions against episodic schema versions; deployment blocked on any forward/backward incompatibility failure; migration test fixtures include historical snapshots |
| 10.9.8 | Mobile Platform + Applied ML | 7.5 | 4-6 days | Tier parity envelopes defined for core outcomes; tier-specific regression tests added to CI; alerting for lower-tier degradation live in monitoring; fallback chain correctness tested on all tiers |
| 10.9.9 | Observability + AI Platform | 7.3.4, 8.8 | 5-7 days | Adaptive decision log schema includes trace ID, trigger, model version, flags, confidence, rollback provenance; required dashboards live (drift, failed-heal cycles, rollback outcomes, unexplained drop detector) |
| 10.9.10 | Security Engineering + Federated Learning | 2.5, 8.1, 8.9 | 1-2 weeks | Signed update attestation path implemented; poisoning/outlier detection enforced at aggregation and advisory ingest; reputation-weighted participation active; scoped kill-switches can disable individual learning channels |
| 10.9.11 | Architecture Council + Release Governance | Hardcoded Invariants section, 7.7A | 3-5 days | Autonomous change-control policy codified in docs + CI checks; every self-updating component declares immutable policy space, promotion gates, rollback path, human override; staged rollout lifecycle enforced by tooling |
| 10.9.12 | AI Platform + Reliability + Federated Ops | 1.1E.8, 7.3.4, 7.4, 7.7, 8.1, 8.8 | 1-2 weeks | Universal healing queue exists for all break classes; automatic remediation scheduling works across entities; recovery SLOs tracked (`TTD`, `TTH`, recurrence); healed incidents are fed back into learning metrics and model governance reviews |
| 10.9.13 | Platform Security + Governance | 1.1E.12, 7.9.32 | 4-6 days | Kernel manifests are signed/versioned; runtime and CI reject unsigned or self-mutated kernel changes; fail-closed behavior verified |
| 10.9.14 | Applied ML + Reliability Science | 5.2.17, 5.2.18, 8.1.9 | 1-2 weeks | Macro-vs-micro alignment metrics are required for promotion; contradiction and purpose-bound violations block rollout; anti-drift dashboards active |
| 10.9.15 | Reliability Engineering + Federated Ops | 1.1E.14, 1.1E.15, 6.2.17, 6.2.18, 10.9.12 | 1-2 weeks | First-occurrence triage SLA enforced for all break classes; dwell-budget escalation automated; recurrence suppression verified in CI/staging drills |
| 10.9.16 | Platform Security + Architecture Council | 1.1E.17, 1.1E.18, 10.9.13 | 4-6 days | Kernel lifecycle checks enforced in CI/runtime; compatibility and rollback TTL proofs required; emergency freeze drill passes with signed release control |
| 10.9.17 | Reliability Engineering + Observability | 7.9.37, 8.1.11, 10.9.15 | 4-6 days | First-occurrence alert storms stay within SLO; dedupe horizon and incident bundling verified in load tests; rollout blocked on storm overflow |
| 10.9.18 | Governance + Reliability Engineering | 7.9.39, 10.9.11 | 3-5 days | High-impact domains enforce max autonomous cycle count; mandatory human review SLA met; audit trail proves no bypass in staging drills |
| 10.9.19 | Applied ML + Reliability Science + Federated Learning | 5.2.20, 5.2.21, 7.7.15, 7.9.40, 8.1.16 | 1-2 weeks | Cross-setting scaling sweeps are mandatory before promotion; regime classification attached to manifests; inversion/nonmonotonic cohorts are quarantined or mitigated before rollout |
| 10.9.20 | Security Engineering + Reliability Engineering + Governance | 2.1, 2.5, 7.7, 8.1, 9.2.6, 10.9.10-10.9.18 | 1-2 weeks | `docs/security/RED_TEAM_TEST_MATRIX.md` is current; critical lanes execute on cadence in staging; failed lanes auto-open remediation milestones; autonomous scope expansion is blocked while critical lanes are red |
| 10.9.21 | Applied ML + Governance + Reliability Engineering | 1.1E.20, 1.1E.21, 5.2.23, 7.7.16, 8.1.19 | 1-2 weeks | CI/runtime reject any tier-precedence violations; dream-only updates cannot promote; dual-key evidence receipts required for tier elevation; dream/reality mismatch alarms auto-trigger quarantine and rollback paths |

> **Sequencing rule:** Execute 10.9.1-10.9.4 first (hard gate), then 10.9.5-10.9.21 in parallel where dependencies allow.

#### 10.9B Milestone Rollout Plan (Expanded Across Existing Phases)

This milestone plan expands robustness hardening into the already-defined phase structure so work lands where ownership and dependencies already exist.

| Milestone | Scope | Phase Anchors | Est. Window | Exit / Go-NoGo Criteria |
|-----------|-------|---------------|-------------|--------------------------|
| M1: Adaptive Foundation Gate | Implement hard gate prerequisites and unblock safe autonomy rollout | 10.9.1-10.9.4, 7.1, 7.7, 10.2.12, 10.2.13 | Week 1-2 | `ProductionReadinessGate` enforced in CI; trigger reliability baseline live; rollback bundle path proven in staging drill; no critical placeholder methods in adaptive critical path |
| M2: Observability + Signal Integrity | Ensure adaptation decisions are measurable and evidence quality is sufficient | 10.9.3, 10.9.9, 10.9.12, 7.3.4, 7.7A, 8.8 | Week 2-3 | Required dashboards live; dual-signal rollback gating active; confidence thresholds enforced; unexplained-outcome-drop detector alerting; universal break-to-heal metrics active |
| M3: Federated + Advisory Safety | Harden cross-device and cross-locality propagation paths | 10.9.5, 10.9.6, 8.1, 8.9 | Week 3-5 | Cohort-wise no-regression checks passing; advisory quarantine enabled; credibility scoring + anomaly disable path operational; canary/shadow promotion policy enforced |
| M4: Tier + Compatibility + Security Closure | Close resilience gaps across device tiers, schemas, and adversarial vectors | 10.9.7, 10.9.8, 10.9.10, 10.9.20, 2.5, 7.5, 7.7.1 | Week 5-7 | Compatibility matrix blocks bad deploys; tier parity checks active; poisoning/outlier detection + signed update attestation enabled; red-team critical lanes passing; scoped kill switches validated |
| M5: Governance Lock-In | Make robustness requirements durable and non-optional | 10.9.11, 10.9.13, Hardcoded Invariants section, 7.7A | Week 7-8 | Autonomous change-control policy ratified; kernel integrity enforcement active; staged rollout lifecycle tooling-enforced; all self-updating components declare policy space + rollback + human override |
| M6: Meta-Learning Integrity + Response SLA | Enforce recursive anti-drift controls, dream-conviction hierarchy safety, and universal first-occurrence/dwell-time response guarantees | 10.9.14, 10.9.15, 10.9.17, 10.9.19, 10.9.21, 5.2.17, 6.2.17, 6.2.18, 8.1.9 | Week 8-10 | Promotion requires macro/micro alignment pass; dream-tier precedence checks remain green; first-occurrence triage SLA meets target; dwell-budget escalations auto-route; recurrence trend decreases across cohorts, alert storm SLO remains green, and scaling reliability gates pass |
| M7: Oversight + Kernel Lifecycle Closure | Make kernel lifecycle and high-impact autonomy oversight operational and auditable | 10.9.16, 10.9.18, 1.1E.17, 1.1E.18, 7.9.39 | Week 10-11 | Kernel upgrade/downgrade/freeze drills pass; rollback TTL enforced; high-impact autonomous loop caps and mandatory human review SLA validated |

#### 10.9C Cross-Phase Expansion Map (What to Update in Each Existing Phase)

| Existing Phase | Required Robustness Expansion | Related 10.9 Tasks |
|----------------|-------------------------------|--------------------|
| 2.5 Post-Quantum Cryptography Hardening | Add signed update attestation for federated/advisory payload authenticity and scoped emergency kill switches for compromised channels | 10.9.10 |
| 7.4 Agent Trigger System | Add idempotency keys, dedupe/replay semantics, trigger fuzz testing, and trigger SLOs | 10.9.2 |
| 7.5 Device Capability Tiers | Add tier parity envelopes, tier-specific regression gating, lower-tier degradation alerting | 10.9.8 |
| 7.7 Model Lifecycle Management | Expand rollback unit to atomic bundles and require periodic rollback drills | 10.9.4 |
| 7.7A Self-Improving Search Governance | Add signal-confidence policy, dual-signal rollback requirement, anti-flap cooldown governance | 10.9.3, 10.9.11 |
| 7.3 Sync & Monitoring | Add causal observability schema with trace IDs and rollback provenance dashboards | 10.9.9 |
| 8.1 Federated World Model Learning | Add cohort-gated promotion, bounded update magnitude, canary + shadow federated promotion flow | 10.9.5 |
| 8.8 Network Monitoring | Add failed-heal cycle monitoring, unexplained drift alarms, and cohort-level convergence/regression views | 10.9.3, 10.9.9 |
| 8.9 Locality Happiness Advisory | Add advisory quarantine, advisor credibility decay, anomaly-based advisory source disable, advisory rollback independence | 10.9.6 |
| 1.1E Lightweight Deterministic Memory Core | Add cross-subsystem failure-signature indexing and replayable healing provenance for all break classes | 10.9.12 |
| 1.1E Lightweight Deterministic Memory Core | Add immutable kernel manifest registry and deterministic first-occurrence/dwell budget contracts | 10.9.13, 10.9.15 |
| 1.1E Lightweight Deterministic Memory Core | Add kernel lifecycle protocol and emergency freeze controls | 10.9.16 |
| 5.2 On-Device Training Loop | Add recursive meta-learning supervisor and anti-drift promotion controls | 10.9.14 |
| 5.2 On-Device Training Loop | Add downstream scaling regime classification + multi-setting robustness gates | 10.9.19 |
| 6.2 Guardrail Objectives | Add discoverability guarantee + first-occurrence and dwell-time escalation invariants | 10.9.15 |
| 6.2 Guardrail Objectives | Add discoverability precedence matrix and measurable dwell exit criteria | 10.9.15, 10.9.17 |
| 7.9 Autonomous Research Lane | Add first-occurrence storm suppression, objective dwell contracts, and high-impact autonomy cycle caps | 10.9.17, 10.9.18 |
| 7.9 Autonomous Research Lane | Add downstream scaling failure-mode taxonomy and sensitivity sweep protocol | 10.9.19 |
| 2.1 Privacy, Compliance & Legal Infrastructure | Add account/session takeover and backend authorization hijack drills with deterministic evidence capture | 10.9.20 |
| 2.5 Post-Quantum Cryptography Hardening | Add mandatory downgrade/replay attack drills and coverage reporting in security validation cadence | 10.9.20 |
| 9.2.6 Third-Party Data Insights Pipeline | Add re-identification simulation and buyer-retention enforcement drills as export release gates | 10.9.20 |
| 8.1 Federated World Model Learning | Add anti-fragmentation shared-core policy and cross-locality reconciliation cadence | 10.9.14, 10.9.17 |
| 8.1 Federated World Model Learning | Add federated scaling profile registry and inversion quarantine | 10.9.19 |
| 1.1E Lightweight Deterministic Memory Core | Add dream ledger + belief-tier precedence contracts and dual-key evidence bridge | 10.9.21 |
| 5.2 On-Device Training Loop | Add DreamEnv mismatch containment, OOD/leakage/spec-gaming checks, and no-recursive-self-confirmation rule | 10.9.21 |
| 6.2 Guardrail Objectives | Add belief-tier action authority and dream contradiction dampening rules | 10.9.21 |
| 7.7 Model Lifecycle Management | Add dream promotion chain enforcement and dream-specific rollback bundles | 10.9.21 |
| 7.9 Autonomous Research Lane | Add dream falsification contracts, negative-dream archive governance, and divergence monitoring | 10.9.21 |
| 8.1 Federated World Model Learning | Add federated dream-policy quarantine and cross-family belief-tier consistency checks | 10.9.21 |
| 10.2 Stub/TODO Cleanup | Enforce adaptive critical-path placeholder elimination as release blocker | 10.9.1 |

#### 10.9D Program-Level Checkpoints (Portfolio View)

| Checkpoint | Trigger | Required Evidence | Decision |
|------------|---------|-------------------|----------|
| C1: Autonomy Enablement | Before enabling any autonomous adaptation in prod | M1 complete + CI gate green + rollback drill pass | Enable canary autonomy only |
| C2: Federated Promotion | Before promoting any global federated update outside canary | M2 + M3 complete; cohort no-regression pass | Promote to staged rollout |
| C3: Broad Rollout | Before full-population adaptive rollout | M4 complete + adversarial controls active + compatibility matrix pass | Full rollout allowed |
| C4: Continuous Operation | Quarterly | M5 policy audit + M6 meta-learning integrity review + M7 oversight/lifecycle audit + rollback drill + incident postmortem review | Continue / tighten policy |

#### 10.9E Governance RACI + Risk Scoring

Risk scoring uses `P x I` where:
- `P` (Probability): 1-5 likelihood of failure/regression if not addressed
- `I` (Impact): 1-5 user/system/business impact if failure occurs
- `Score`: `P x I` (max 25)
- Priority bands: `20-25 Critical`, `12-19 High`, `6-11 Medium`, `1-5 Low`

Role abbreviations:
- `AP` = AI Platform
- `MOB` = Mobile Platform
- `REL` = Reliability Engineering
- `MLE` = Recommender/ML
- `FED` = Federated Learning
- `LOC` = Locality Intelligence
- `OBS` = Observability
- `SEC` = Security Engineering
- `QA` = QA Automation
- `RE` = Release Engineering
- `ARCH` = Architecture Council
- `GOV` = Release Governance

| Task | R | A | C | I | P | I(Impact) | Score | Priority |
|------|---|---|---|---|---|-----------|-------|----------|
| 10.9.1 | AP, REL | GOV | QA, RE | ARCH | 5 | 5 | 25 | Critical |
| 10.9.2 | MOB, AP | REL | QA, OBS | GOV | 4 | 4 | 16 | High |
| 10.9.3 | MLE | AP | OBS, QA | GOV | 4 | 5 | 20 | Critical |
| 10.9.4 | AP, RE | GOV | REL, QA | ARCH | 4 | 5 | 20 | Critical |
| 10.9.5 | FED, MLE | AP | OBS, QA, MOB | GOV | 4 | 4 | 16 | High |
| 10.9.6 | LOC | AP | FED, SEC, QA | GOV | 3 | 4 | 12 | High |
| 10.9.7 | QA, Data Platform | GOV | AP, RE | ARCH | 3 | 5 | 15 | High |
| 10.9.8 | MOB, MLE | AP | QA, OBS | GOV | 3 | 4 | 12 | High |
| 10.9.9 | OBS, AP | REL | QA, MLE | GOV | 3 | 5 | 15 | High |
| 10.9.10 | SEC, FED | GOV | AP, REL, QA | ARCH | 4 | 5 | 20 | Critical |
| 10.9.11 | ARCH, GOV | GOV | AP, RE, REL | All teams | 3 | 5 | 15 | High |
| 10.9.12 | AP, REL, FED | GOV | OBS, QA, MLE | All teams | 4 | 5 | 20 | Critical |
| 10.9.13 | SEC, ARCH | GOV | AP, REL, QA | All teams | 4 | 5 | 20 | Critical |
| 10.9.14 | MLE, REL | GOV | AP, FED, OBS | ARCH | 4 | 5 | 20 | Critical |
| 10.9.15 | REL, AP, FED | GOV | OBS, QA, SEC | All teams | 4 | 5 | 20 | Critical |
| 10.9.16 | SEC, ARCH | GOV | AP, REL, QA | All teams | 4 | 5 | 20 | Critical |
| 10.9.17 | REL, OBS | GOV | AP, FED, QA | All teams | 4 | 4 | 16 | High |
| 10.9.18 | GOV, REL | GOV | ARCH, SEC, QA | All teams | 4 | 5 | 20 | Critical |
| 10.9.19 | MLE, REL, FED | GOV | AP, OBS, QA | ARCH | 4 | 5 | 20 | Critical |
| 10.9.20 | SEC, REL, GOV | GOV | AP, FED, OBS, QA | ARCH | 4 | 5 | 20 | Critical |
| 10.9.21 | MLE, GOV, REL | GOV | AP, FED, OBS, QA | ARCH | 4 | 5 | 20 | Critical |

> **Execution policy:** Tasks with `Critical` priority (`10.9.1`, `10.9.3`, `10.9.4`, `10.9.10`, `10.9.12`, `10.9.13`, `10.9.14`, `10.9.15`, `10.9.16`, `10.9.18`, `10.9.19`, `10.9.20`, `10.9.21`) must have active owners and weekly status review before any autonomous scope expansion.

#### 10.9F Reusable Governance Template (Apply to All Phases)

Use this template whenever adding or updating any phase workstream:

| Field | Required Content |
|------|------------------|
| Milestone ID | `Mx-Py-z` (example: `M2-P7-1`) |
| Scope | Concrete deliverable, not activity wording |
| Owner Team (R) | Team(s) implementing work |
| Accountable (A) | Single accountable role/team |
| Consulted (C) | Cross-functional reviewers |
| Informed (I) | Stakeholders receiving updates |
| Dependencies | Prior tasks/phases required to start |
| Duration | Estimated window in days/weeks |
| Risk Score | `P x I` with band (Critical/High/Medium/Low) |
| Exit Criteria | Objective go/no-go criteria (tests/metrics/drills) |

> **Template rule:** Every phase milestone must declare all fields above; no phase can enter implementation without risk score + exit criteria.

#### 10.9F.1 Execution Board Enforcement (Phase 1-N)

`docs/EXECUTION_BOARD.csv` is the canonical execution state for all phase work derived from this plan.

Mandatory enforcement rules:
1. Every plan-derived implementation item must map to a milestone ID (`Mx-Py-z`) in `docs/EXECUTION_BOARD.csv`.
2. Every PR that changes plan-scoped code/docs must reference exactly one milestone ID (`Mx-Py-z`) in PR title.
3. Every non-merge commit in that PR must include the same milestone ID and at least one master plan subsection reference (`X.Y.Z`).
4. Milestones cannot move to `Done` without evidence links (tests, dashboards, reports, or docs).
5. Phase progression cannot skip failed gates from prerequisite waves.
6. Board sync/validation must pass before merge:
`dart run tool/update_execution_board.dart --check`
7. Deferred rename governance must pass before merge:
`python3 scripts/validate_rename_candidates.py` and `python3 scripts/suggest_rename_candidates_inventory.py --fail-on-untracked` (all `status=ready` entries in `docs/architecture/RENAME_CANDIDATES.md` must include a valid target milestone `Mx-Py-z`, and no untracked `*Service`/`*Orchestrator` names may remain).
8. End-of-phase rename closeout is mandatory before setting any phase to `Done`:
run `python3 scripts/suggest_rename_candidates_inventory.py`, update `docs/architecture/RENAME_CANDIDATES.md` with new candidates/categories/phase targets, execute approved renames, then re-run `python3 scripts/validate_rename_candidates.py`.
Preferred one-command flow:
`scripts/run_phase_rename_closeout.sh P#`
9. Phase branch workflow is mandatory:
each phase uses a stable branch name `phase#_work`; section/subsection branches are created as children of the current phase branch path (`.../sX_Y_Z`) and merged back by PR into the immediate parent branch.
Preferred local automation:
`scripts/phase_section_start.sh --phase P# --section X.Y.Z`
`scripts/phase_subsection_complete.sh --phase P# --subsection X.Y.Z`
GitHub auto-PR workflow:
`.github/workflows/phase-subsection-autopr.yml`
10. Naming verification gate is mandatory before subsection auto-PR creation:
`scripts/verify_phase_naming.sh --phase P# --branch <phase-branch-or-child>`

Authoring workflow:
1. Edit `docs/EXECUTION_BOARD.csv`.
2. Run `dart run tool/update_execution_board.dart` to regenerate board sections.
3. Update `docs/STATUS_WEEKLY.md`.
4. Commit CSV + generated board changes together.

#### 10.9G Governance Rollout Order (All Phases, Suggested Execution Order)

| Wave | Phase Set | Governance Depth | Primary Objective |
|------|-----------|------------------|-------------------|
| Wave 0 (active foundation) | Phase 2 + Phase 10 | Full | Security, compliance, and production-readiness gates that all other phases depend on |
| Wave 1 | Phase 7 + Phase 8 | Full | Stabilize orchestration, rollout controls, federated/advisory safety before expanding adaptive scope |
| Wave 2 | Phase 1 + Phase 3 + Phase 4 + Phase 5 + Phase 6 | Full for 4-6, Hybrid for 1/3 | Harden core learning/planning pipeline end-to-end |
| Wave 3 | Phase 9 + Phase 11 | Hybrid | Apply governance to business/integration expansion and research tracks |

> **Ordering rule:** Start work in the listed wave order. A later wave cannot promote to production if earlier-wave go/no-go gates are red.

#### 10.9H Phase Governance Matrix (Portfolio-Level)

| Phase | Governance Tier | R | A | C | I | Portfolio Risk (P x I) | Priority | Phase Gate |
|------|------------------|---|---|---|---|------------------------|----------|------------|
| Phase 1 (Outcome + Memory) | Hybrid | AP, MLE | AP | QA, OBS | GOV | 3 x 4 = 12 | High | Data integrity + schema/backfill validation green |
| Phase 2 (Privacy/Compliance) | Full | SEC | GOV | AP, REL, QA | ARCH | 4 x 5 = 20 | Critical | Security controls + compliance tests + key-rotation drill pass |
| Phase 3 (State/Encoders) | Hybrid | AP, MLE | AP | QA, REL | GOV | 3 x 4 = 12 | High | Feature freshness + consistency checks pass |
| Phase 4 (Energy Function) | Full | MLE | AP | QA, OBS, REL | GOV | 4 x 5 = 20 | Critical | Asymmetric-loss regression and safety guardrails pass |
| Phase 5 (Transition Predictor) | Full | MLE | AP | QA, OBS | GOV | 4 x 5 = 20 | Critical | Drift/error bounds + uncertainty calibration pass |
| Phase 6 (MPC Planner) | Full | AP, MLE | AP | REL, QA, OBS | GOV | 4 x 5 = 20 | Critical | Guardrail constraints + planner rollback drills pass |
| Phase 7 (Orchestrators/Integration) | Full | AP, MOB | REL | QA, OBS, RE | GOV | 5 x 5 = 25 | Critical | Trigger reliability + orchestration persistence gates pass |
| Phase 8 (Ecosystem Intelligence) | Full | FED, LOC | AP | SEC, QA, OBS | GOV | 4 x 5 = 20 | Critical | Federated cohort no-regression + advisory quarantine pass |
| Phase 9 (Business/Monetization) | Hybrid | Business Platform, AP | GOV | SEC, QA | ARCH | 3 x 4 = 12 | High | Data-sharing consent + revenue attribution integrity pass |
| Phase 10 (Feature Completion/Reorg) | Full | AP, REL | GOV | QA, RE | ARCH | 4 x 4 = 16 | High | Placeholder elimination + reorg import/CI stability pass |
| Phase 11 (Integrations/Expansion) | Hybrid | Integrations Platform | GOV | SEC, AP, QA | ARCH | 3 x 5 = 15 | High | Integration contract/security conformance pass |

#### 10.9I Phase Milestone Tracks (Detailed, In Rollout Order)

| Milestone ID | Phase | Scope | R | A | Dependencies | Duration | Risk | Exit Criteria |
|-------------|-------|-------|---|---|--------------|----------|------|---------------|
| M1-P7-1 | 7 | Trigger + orchestration persistence hardening | AP, MOB | REL | 10.9.1-10.9.4 | 1-2 weeks | 25 Critical | Trigger SLOs green, no placeholder critical-path methods, state persistence verified |
| M1-P7-2 | 7 | Controller/orchestrator integration reliability | AP | REL | M1-P7-1 | 1 week | 20 Critical | No orchestration dead paths; canary error budget within target |
| M1-P8-1 | 8 | Federated cohort gating + canary/shadow pipeline | FED, MLE | AP | M1-P7-1 | 1-2 weeks | 20 Critical | Cohort no-regression checks pass; promotion policy enforced |
| M1-P8-2 | 8 | Advisory quarantine + rollback independence | LOC | AP | M1-P8-1 | 1 week | 16 High | Advisory source quarantine and disable path validated |
| M2-P1-1 | 1 | Episodic/semantic/procedural memory reliability gates | AP, MLE | AP | M1-P7-1 | 1 week | 12 High | Schema consistency, dedupe, and replay tests pass |
| M2-P3-1 | 3 | State encoder consistency/freshness controls | AP, MLE | AP | M2-P1-1 | 1 week | 12 High | Feature freshness tracker SLO + atomic snapshot checks pass |
| M2-P4-1 | 4 | Energy function safety and regression governance | MLE | AP | M2-P3-1 | 1-2 weeks | 20 Critical | Safety bounds + asymmetric-loss regression suite pass |
| M2-P5-1 | 5 | Transition predictor drift/calibration controls | MLE | AP | M2-P4-1 | 1-2 weeks | 20 Critical | Error/drift thresholds green; uncertainty calibration validated |
| M2-P6-1 | 6 | Planner guardrail and rollback-hardening | AP, MLE | AP | M2-P5-1 | 1-2 weeks | 20 Critical | Planner respects hard constraints; rollback drill pass |
| M3-P9-1 | 9 | Business data/consent governance hardening | Business Platform, AP | GOV | M2-P6-1 | 1 week | 12 High | Consent and DP checks enforced; audit logs complete |
| M3-P11-1 | 11 | Integration governance + contract security gates | Integrations Platform | GOV | M3-P9-1 | 1-2 weeks | 15 High | Integration contract tests + security conformance pass |
| M0-P2-1 | 2 | Security + cryptographic assurance baseline | SEC | GOV | none | parallel baseline | 20 Critical | PQ hardening tasks + attestation and kill-switch validation pass |
| M0-P10-1 | 10 | Production readiness + cleanup enforcement | AP, REL | GOV | none | parallel baseline | 16 High | Adaptive-path placeholder gate and CI stability pass |

> **Program management rule:** `M0-P2-1` and `M0-P10-1` run continuously as cross-cutting controls while Waves 1-3 execute in sequence.

---

## Phase 11: Industry Integrations & Platform Expansion

**Tier:** 3 (Depends on Phases 8 and 9)  
**Duration:** 12-20 weeks

### 11.1 Industry Integrations (from legacy Phases 26, 28-31)

All integrations use Phase 2 privacy infrastructure + Phase 9 business infrastructure + Phase 8 world model intelligence.

| Task | Industry | Legacy Phase | Revenue Potential |
|------|----------|-------------|-------------------|
| 11.1.1 | Toast Restaurant Technology | Legacy 26 | Part of hospitality |
| 11.1.2 | Government Integrations | Legacy 28 | $2M-$20M/yr |
| 11.1.3 | Finance Industry Integrations | Legacy 29 | $15M-$50M/yr |
| 11.1.4 | PR Agency Integrations | Legacy 30 | $10M-$30M/yr |
| 11.1.5 | Hospitality Industry Integrations | Legacy 31 | $8M-$25M/yr |

### 11.2 Platform Expansion (from legacy Phases 18, 25)

| Task | Platform | Legacy Phase |
|------|----------|-------------|
| 11.2.1 | White-Label infrastructure | Legacy 18 |
| 11.2.2 | Native Desktop platform | Legacy 25 |

### 11.3 JEPA for Personality Representation Learning (Research Track)

Instead of hand-crafting which 12 dimensions matter and how they're computed from Big Five OCEAN data, use a Joint-Embedding Predictive Architecture (JEPA) to *discover* the optimal personality embedding from behavior data. This is the most ambitious item in the roadmap and requires substantial real user data.

| Task | Description |
|------|-------------|
| 11.3.1 | **Context encoder:** Raw user behavior (spot visits, feedback, timing patterns, community activity) → abstract personality representation (learned dimensionality, may not be 12D) |
| 11.3.2 | **Target encoder:** Future behavior outcome (did they visit? did they enjoy it?) → target representation |
| 11.3.3 | **Predictor:** Given context representation + hypothetical action → predicted target representation |
| 11.3.4 | Train with VICReg/SIGReg information maximization: **Variance** (all embedding dimensions are used, no collapse), **Covariance** (dimensions are decorrelated, each carries unique info), **Prediction** (context + action accurately predicts target) |
| 11.3.5 | The learned embedding might not be 12D. It might be 24D or 8D. The dimensions might not map to human-interpretable concepts like "openness" or "energy_preference." But they'd be *optimally predictive* of user behavior |
| 11.3.6 | **Important: dual embedding system.** The JEPA embedding does NOT replace the 12D personality model for user-facing features (personality insights, explaining recommendations). It creates a *parallel* learned embedding used internally for prediction and planning, while the interpretable 12D model remains for UI/UX |
| 11.3.7 | Implement shadow mode: run JEPA embedding alongside existing state encoder, compare prediction accuracy. JEPA only replaces state encoder when it measurably outperforms |
| 11.3.8 | If JEPA embedding dimensions don't map to interpretable concepts, implement post-hoc interpretation: which behavioral clusters correspond to which JEPA dimensions? Document for admin explainability (Phase 4.6) |

> **ML Roadmap Reference:** Section 7.4.6, Roadmap Item #29. This follows LeCun's recommendation for JEPA over generative architectures. Requires Tier 1 (#1-3) complete + substantial real user data. Estimated effort: 3-4 weeks. This is the "most ambitious item" from the roadmap.

### 11.4 Quantum Hardware Readiness (Architecture Notes -- Not Active Tasks)

These are NOT active tasks. They are architectural notes documenting how the current classical system maps to future quantum hardware, what the migration path looks like, and where quantum hardware would provide genuine advantage. They exist so future developers understand the quantum-readiness decisions made in this plan.

**Current approach (correct):** Build for classical now, abstract the compute layer (`QuantumComputeBackend` interface), plug in cloud quantum when hardware is ready. The `QuantumComputeProvider` already selects classical vs. cloud quantum based on entity count, connectivity, and feature flags. The `CloudQuantumBackend` is a stub with documented IBM Quantum / AWS Braket / Google Cirq API mappings.

**When to revisit these notes:** When quantum hardware can reliably run ~100-200 logical qubits with error rates < 10^-6 (estimated 2028-2032 for the operations AVRAI cares about).

#### 11.4A Quantum Advantage Points (from ML Roadmap Section 14.5)

| Operation | Classical (Today) | Quantum Advantage | Estimated Timeline | Existing Code |
|---|---|---|---|---|
| Jones polynomial evaluation | Classical computation in `VibeCompatibilityService` (0.4 weight in knot weave scoring) | BQP-complete -- exponential speedup. First concrete quantum advantage for AVRAI | 2028-2030 (needs ~20 logical qubits) | `CloudQuantumBackend` stub documents circuit design |
| N-way group entanglement | Pairwise fidelities O(N^2) in `ClassicalQuantumBackend.createEntangledState()` | Native on QPU, exponential speedup for N >= 5. State space grows as 2^N | 2028-2030 (needs N * 4 logical qubits) | `QuantumComputeProvider` routes to cloud when entityCount >= 5 |
| State fidelity | Inner product on float vectors | SWAP test on QPU for true quantum fidelity | 2028-2030 (needs 8 qubits per pair) | `CloudQuantumBackend.calculateFidelity()` stub documents SWAP test circuit |
| Entanglement pattern detection | ONNX MLP in `QuantumEntanglementMLService` | VQE with custom ansatz for nonlinear correlations | 2030-2032 (more complex) | `CloudQuantumBackend.detectEntanglementPatterns()` stub documents Hamiltonian |
| Parameter optimization | ONNX MLP / hardcoded weights | QAOA for larger parameter spaces | 2030-2032 | `CloudQuantumBackend.optimizeSuperpositionWeights()` stub documents QAOA |

**Migration path for these:** Fill in the `CloudQuantumBackend` stubs. One file changes, zero callers change. This is configuration, not architecture.

#### 11.4B Future Quantum-Native Intelligence (Research Horizon)

These represent a DEEPER level of quantum integration where the world model itself runs on quantum hardware. These are research-level items that depend on quantum hardware that doesn't exist yet. They are documented here so the architecture doesn't accidentally close these doors.

**Note: None of these require action now. The current architecture already supports them because the intelligence functions (energy function, transition predictor, state encoder, MPC planner) are implemented as pure functions via ONNX models. Pure functions are trivially convertible to quantum circuits.**

| Concept | What It Would Mean | Why AVRAI Architecture Is Ready | When to Revisit |
|---|---|---|---|
| **Quantum energy function** | The energy function `E(state, action) → scalar` runs as a Variational Quantum Eigensolver (VQE) or parameterized quantum circuit (PQC) instead of an ONNX MLP. Could find better optima in the energy landscape, especially as state vector grows beyond 200D | Energy function is a pure function behind the `QuantumComputeBackend` abstraction. Swapping ONNX → PQC requires a new backend implementation, not architectural changes | When VQE on 50+ qubits is practical (~2032+) |
| **Amplitude-encoded state vector** | The 145-155D state vector is encoded in ~8 qubits via amplitude encoding (log2(155) ≈ 8). Operations on the state happen in superposition across all dimensions simultaneously | `QuantumComputeProvider.serializeStateForCloud()` already implements amplitude encoding normalization. The serialization format is ready; the backend just needs to run the circuit instead of returning UnimplementedError | When amplitude encoding fidelity is reliable (~2030+) |
| **Quantum MPC search** | The MPC planner's exhaustive search over 18 action types * N candidate entities uses Grover's algorithm for quadratic speedup (sqrt(18*N) evaluations instead of 18*N) | The MPC planner (Phase 6.1) evaluates candidates via the energy function, which is a pure function. Wrapping it as a Grover oracle requires the function to be stateless (it already is as ONNX) | When Grover's on ~1000 items is practical (~2032+) |
| **PQC-based transition predictor** | The transition predictor `next_state = f(current_state, action)` runs as a parameterized quantum circuit. PQCs can capture entangled correlations between input features that classical MLPs need many layers to approximate | Transition predictor is a pure ONNX function. Same migration path as energy function: new backend, no architectural changes | When PQC training is stable (~2033+) |
| **Hybrid quantum-classical federated training** | Federated gradient updates (Phase 8.1) use quantum-enhanced optimization (QAOA) for the aggregation step on the server side. On-device training stays classical | Federated aggregation server (Phase 8.1.3) is a Supabase edge function. Quantum aggregation would be a server-side change, transparent to on-device code | When cloud quantum is cost-effective for optimization (~2030+) |
| **True quantum entanglement for user matching** | Instead of SIMULATING quantum entanglement between user personality states (current: inner products on float vectors), CREATE actual quantum entangled states between user representations. The measurement correlations would be genuinely quantum, not classically simulated | The `QuantumEntityState` model and `QuantumEntanglementMLService` already model entities in a Hilbert space with complex amplitudes. The math is the same; the substrate changes. The `isQuantumComputed` flag on `EntangledQuantumState` already distinguishes classical from quantum results | When multi-user quantum states can be maintained across cloud sessions (~2035+) |

**Key architectural principle:** Keep intelligence functions PURE (no side effects, no stateful dependencies). ONNX models naturally enforce this. Pure functions are trivially convertible to quantum circuits. This is why the current approach is correct -- build classical, keep it clean, and the quantum migration will be a backend swap when hardware arrives.

### 11.5 Obsolete Legacy Phases (Removed)

These legacy phases are explicitly not carried forward:

| Legacy Phase | Name | Reason |
|-------------|------|--------|
| 17 | Complete Model Deployment (99% accuracy) | Obsolete framing. Replaced by world model architecture (Phases 3-6). The "99% accuracy" goal is meaningless for energy-based models. |
| 24 | Web App-Phone LLM Sync Hub | Invalidated by on-device world model. Small on-device models eliminate the need for syncing LLM updates via a web intermediary. |
| 11 | User-AI Interaction Update (old) | Architecturally superseded by world model inference path (Phase 3). The layered ONNX + Gemini approach in `InferenceOrchestrator` is kept but now serves the world model. |
| 20 | AI2AI Network Monitoring (premature) | Deferred to Phase 8.3. Monitoring a network that doesn't propagate correctly is waste. Fix propagation first (Phase 8.1-8.2), then monitor. |

---

## Legacy Phase Cross-Reference

For agents and developers who encounter legacy phase numbers in code comments, TODOs, or documentation:

| Legacy Phase | Legacy Name | New Location | Notes |
|-------------|-------------|-------------|-------|
| 1-4, 4.5 | MVP through Testing | Historical | Complete, no changes needed |
| 5 | Operations & Compliance | Phase 2 | GDPR elevated from policy-gated to legal requirement |
| 6 | Local Expert System | Phase 4.3 | Expert formulas replaced by energy function |
| 7 | Feature Matrix | Phase 10.1 | Remaining items in feature completion |
| 8 | Onboarding | Phase 10.1.1 | Mostly complete |
| 9 | Test Suite | Complete | No changes needed |
| 10 | Social Media | Phase 10.1.2 | Unchanged |
| 11 | User-AI Interaction | Obsolete | Superseded by Phase 3 |
| 12 | Neural Network | Absorbed into Phase 4 | CallingScore pipeline generalized |
| 13 | Itinerary Lists | Phase 10.1.3 | Unchanged |
| 14 | Signal Protocol | Complete | No changes needed |
| 15 | Reservations | Complete | No changes needed |
| 16 | Archetype System | Phase 10.1.4 | Unchanged |
| 17 | Model Deployment | Obsolete | Replaced by Phases 3-6 |
| 18 | White-Label | Phase 11.2.1 | Deferred to Tier 3 |
| 19 | Quantum Matching | Complete | No changes needed |
| 20 | AI2AI Monitoring | Phase 8.3 | Deferred until network works |
| 21 | E-Commerce | Phase 9.2.7 | After privacy infrastructure |
| 22 | Data-Buyer Insights | Phase 9.2.6 | After privacy infrastructure |
| 23 | BLE Optimization | Phase 8.2 | Part of ecosystem intelligence |
| 24 | Web-Phone Sync | Obsolete | Invalidated by on-device model |
| 25 | Desktop Platform | Phase 11.2.2 | Deferred to Tier 3 |
| 26 | Toast Integration | Phase 11.1.1 | Deferred to Tier 3 |
| 27 | Services Marketplace | Phase 9.2.1 | Business track |
| 28 | Government | Phase 11.1.2 | Deferred to Tier 3 |
| 29 | Finance | Phase 11.1.3 | Deferred to Tier 3 |
| 30 | PR Agency | Phase 11.1.4 | Deferred to Tier 3 |
| 31 | Hospitality | Phase 11.1.5 | Deferred to Tier 3 |

---

## Representations That Survive as World Model Input

These systems are NOT replaced. They provide the rich feature substrate that makes this world model unique.

| System | Role | Phase |
|--------|------|-------|
| Quantum vibe states (complex amplitudes) | 24D state encoder input | Phase 3.1.1 |
| PersonalityKnot invariants | 5-10D state encoder input | Phase 3.1.2 |
| KnotFabric invariants | 5-10D action encoder input (community context) | Phase 3.1.3 |
| Decoherence patterns | 5D trajectory features | Phase 3.1.4 |
| Worldsheet analytics | 5D evolution trajectory | Phase 3.1.5 |
| Locality agent vectors | 12D location context | Phase 3.1.6 |
| String evolution rates | 5D temporal dynamics | Phase 3.1.8 |
| Entanglement correlations | 10D compressed correlations | Phase 3.1.9 |
| Language profile patterns | 4D communication style | Phase 3.1.13 |
| Signal Protocol trust metrics | 3D trust/verification state | Phase 3.1.14 |
| Chat activity patterns | 3D engagement metadata | Phase 3.1.15 |
| **List engagement features** | 7D curation behavior patterns | Phase 3.1.16 |
| **Active list composition summary** | 12D compressed taste manifold | Phase 3.1.17 |
| **List quantum states** (per list) | Same Hilbert space as users/spots -- enables list compatibility scoring | Phase 3.4.2 |
| **List PersonalityKnot** | Composition diversity, category structure | Phase 3.4.3 |
| **List KnotFabric** | Multi-contributor list community health | Phase 3.4.4 |
| **List Worldsheet** | Temporal evolution of list composition | Phase 3.4.5 |
| **List KnotString** | Continuous knot invariant evolution history | Phase 3.4.6 |
| **List decoherence** | Composition coherence/exploration signal | Phase 3.4.7 |
| **List-creator entanglement** | Faithfulness of list to creator personality | Phase 3.4.8 |
| **Business account features** | 10D business entity state (patron preferences, partnership history, event hosting, verification) | Phase 3.1.18 |
| **Brand/sponsor features** | 8D brand entity state (sponsorship history, values, category, reach, renewal rate) | Phase 3.1.19 |
| AtomicClockService timestamps | Temporal precision for all state snapshots | Foundational |
| Semantic memory (vector store) | Compressed knowledge from episodic experience | Phase 1.1A |
| Procedural memory (strategy rules) | Learned heuristics for planning loop | Phase 1.1B |
| StructuredFactsIndex (existing) | Base for semantic memory vector store | Extends existing |
| **First-session behavioral signals** | Initial unbiased preferences with 3x weight | Phase 1.5B.2 |
| **Behavioral archetype** | Implicit personality proxy for skip-onboarding users | Phase 1.5B.3 |
| **Business public data bootstrap** | Category, price tier, hours, location, ratings | Phase 1.5C.1 |
| **Pre-seeded model weights** | Population-level Big Five → preference mapping | Phase 1.5D.1 |
| **One-tap rejection signals** | Explicit negative without conversation (5x weight) | Phase 1.4.6 |
| **Category suppress signals** | Strong negative preference (10x weight) | Phase 1.4.7 |
| **Organic discovery signals** | Unmatched visit patterns, discovered spot candidates, mesh-validated locations | Phase 1.7.1-1.7.8 |
| **Temporal embeddings** | Sinusoidal day/year cycle features (4D) | Phase 5.1.10 |
| **Taste drift residuals** | EMA of prediction errors for drift detection | Phase 5.1.9 |
| **Locality aggregate happiness** | Ecosystem health signal per geohash cell (0.0-1.0), enables advisory transfer from thriving to struggling localities | Phase 8.9A.2 |
| **Dormancy prediction signals** | Interaction frequency trends, outcome rate trends for re-engagement | Phase 5.1.11 |
| **Wearable physiological context** | Heart rate trend, sleep quality, activity level (optional, 3D) | Phase 5.1.12 |
| **Negative outcome amplification weights** | Asymmetric loss signals, model failure tuples | Phase 1.4.10-1.4.11 |
| **Agent happiness training signal** | Per-agent delta-happiness as energy function reward | Phase 4.5.6 |

---

## Appendix

### A. ML Roadmap Phase Mapping

| ML Roadmap Phase | Duration | New Master Plan Phase |
|-----------------|----------|----------------------|
| Phase A: Outcome Collection & Episodic Memory | 2-3 weeks | Phase 1 (1.1-1.5, expanded: 1.5B skip-onboarding, 1.5C business cold-start, 1.5D pre-seeded model, 1.7 organic spot discovery) |
| Quick-Win Data/Model Improvements (Tiers 1-3) | 1-2 weeks | Phase 1.6 |
| Semantic/Procedural Memory + Consolidation | 1-2 weeks | Phase 1.1A-1.1C |
| Lightweight Deterministic Memory Core (Fallback + Recovery Journal) | 1 week | Phase 1.1E (facts/history journals, deterministic retrieval fallback, failure signature index) |
| Phase B: State/Action Encoders + List Quantum Entity | 4-5 weeks | Phase 3 (expanded: 3.4 List as Quantum Entity is new) |
| Phase C: Energy Function (Critic) | 3-4 weeks | Phase 4 (VICReg training) |
| Phase D: Transition Predictor | 3-4 weeks | Phase 5 (VICReg training, expanded: 5.1.9 taste drift, 5.1.10 temporal patterns, **5.1.11 dormancy prediction**, **5.1.12 wearable conditioning**) |
| Phase E: MPC Planner + Guardrails | 2-3 weeks | Phase 6.1-6.4 (expanded: 6.2.9-6.2.11 active uncertainty reduction, **6.2.12-6.2.15 re-engagement guardrails**, **6.1.13-6.1.15 creator intelligence**) |
| System 1/System 2 Compilation | 2-3 weeks | Phase 6.5 |
| SLM Language Interface | 2-3 days | Phase 6.7 |
| Agent Trigger System | 1-2 days | Phase 7.4 |
| Device Capability Tiers | 1 day | Phase 7.5 |
| Model Lifecycle Management | 1-2 weeks | Phase 7.7 (version schema, OTA, staged rollout, rollback) |
| Autonomous Research + Experimentation Engine | 3-5 weeks | Phase 7.9 (hypothesis mining, interdisciplinary retrieval, staged experiments, external/internal cross-reference, conviction governance) |
| Multi-Device Reconciliation | 1-2 weeks | Phase 7.8 (episodic merge, personality sync, device migration) |
| Phase F: Federated + Agent Architecture | 4-6 weeks | Phases 8.1-8.4 |
| Agent-to-Agent Insight + Group Negotiation | 5-8 days | Phases 8.5-8.6 |
| Locality Happiness Advisory System | 1-2 weeks | Phase 8.9 (happiness aggregation, advisory threshold, cross-region transfer, quantum readiness notes) |
| Stub Cleanup | 1-2 weeks | Phase 10.2 |
| Internationalization & Localization | 2-3 weeks | Phase 10.3 (ARB extraction, locale detection, RTL, AI explanation localization) |
| Accessibility | 1-2 weeks | Phase 10.4 (semantic labels, screen reader, contrast, dynamic text, alt-text, reduce motion) |
| Codebase Reorganization — Immediate (services + models) | 1-2 weeks | Phase 10.7 (parallel with Phases 1-2) |
| Codebase Reorganization — Deferred (ai/ml, quantum, domain/) | 1 week | Phase 10.8 (after Phases 4/7) |
| Third-Party Data Pipeline | 1-2 weeks | Phase 9.2.6A-G (insight catalog, DP noise, generation pipeline, consent, access control) |
| JEPA for Personality (Research) | 3-4 weeks | Phase 11.3 |
| Quantum Hardware Readiness | Architecture notes (no active tasks) | Phase 11.4 (notes only) |
| Post-Quantum Cryptography Hardening | 2-3 weeks | Phase 2.5 (8 tasks: session audit, rotation, exhaustion, BLE/federated/cloud PQ, dashboard) |

### B. Total Hardcoded Formula Count

- **Scoring formulas:** 20+ (weighted combinations)
- **Threshold values:** 6+ (interval timers, confidence thresholds, cache expiry)
- **Evolution dynamics:** 3 (worldsheet ODE, string extrapolation, possibility branches)
- **Stub ML services:** 4 (PatternRecognition, PredictiveAnalytics, PreferenceLearningEngine, SocialContextAnalyzer)
- **Total candidates for energy function replacement:** 30+

### C. Codebase Statistics

- **Total services:** 330+
- **Total models:** 150+
- **Total controllers:** 21
- **Total orchestrators:** 6
- **Total packages:** 9
- **Services preserved as-is:** 15+ business-critical
- **Services needing world model integration:** ~50
- **Services unaffected by world model:** ~265
- **Chat services affected by Signal Protocol flip:** 5 (friend, community, agent, business-expert, business-business)
- **New state vector dimensions (from all sources):** ~145-155D total (quantum 24D + knot 5-10D + fabric 5-10D + decoherence 5D + worldsheet 5D + locality 12D + temporal 5D + string 5D + entanglement 10D + wearable 3D + cross-app 3D + behavioral 5D + language 4D + trust 3D + chat 3D + list engagement 7D + list composition 12D + **business features 10D** + **brand features 8D**)
- **Stub ML services to resolve:** 4 (PatternRecognition, PredictiveAnalytics, PreferenceLearningEngine, SocialContextAnalyzer)
- **Memory types:** 4 (episodic + semantic + procedural + deterministic journal core) + nightly consolidation cycle
- **Device capability tiers:** 4 (full, standard, basic, minimal)
- **Agent triggers:** 9 event types (app open, location change, timer, AI2AI, notification, calendar, overnight, **locality advisory**, **dormancy prediction**)
- **Quantum entity types:** 7 (expert, business, brand, event, user, sponsor, **list**) -- list is new
- **List representation layers:** 8 (quantum state, knot, fabric, worldsheet, string, decoherence, entanglement, possibility engine)
- **Action types in MPC space:** 22 (visit_spot, attend_event, join_community, connect_ai2ai, save_list, create_list, modify_list, share_list, create_reservation, message_friend, message_community, ask_agent, host_event, browse_entity, **initiate_business_outreach**, **propose_sponsorship**, **form_partnership**, **engage_business**, **novelty_injection**, **social_nudge**, **achievement_door**, **reduce_frequency**)
- **Outcome data collection points:** 30 (Phase 1.2.1 through 1.2.29 plus 1.2.26A transition lane) + organic discovery signals (Phase 1.7)
- **Feedback signal types:** 10 hierarchically weighted (Phase 1.4.9: explicit rating 10x → scroll-past 0.5x) + 8 advanced governance signals (1.4.10-1.4.17: amplification, conviction, delayed validation, discoverability, first-occurrence priority)
- **Cold-start paths:** 3 (1.5A onboarding-based, 1.5B skip-onboarding behavioral, 1.5C business cold-start) + 1 pre-seeded global model (1.5D)
- **Bidirectional energy pairings:** 7 (user↔community, user↔event, user↔connection, user↔list, **business↔expert**, **brand↔event**, **business↔business**)
- **Guardrail objectives:** 20 (diversity, exploration, safety, doors, age, notification freq, quiet hours, diminishing returns, **active uncertainty reduction**, **domain-specific uncertainty tracking**, **lifecycle-stage exploration balance**, **re-engagement strategy**, **re-engagement frequency**, **returning user fast-ramp**, **dormancy outcome logging**, **discoverability guarantee**, **first-occurrence response invariant**, **dwell-time escalation invariant**, **discoverability precedence matrix**, **dwell exit criteria invariant**)
- **Transition predictor outputs:** 12 (5.1.1 base + 5.1.4 variance + 5.1.5-5.1.7 replacements + 5.1.8 list transitions + **5.1.9 taste drift** + **5.1.10 temporal patterns** + **5.1.11 dormancy prediction** + **5.1.12 wearable temporal conditioning**)
- **Formula replacement candidates (business layer):** 5 new (PartnershipMatchingService, SponsorshipService, BrandDiscoveryService, BusinessBusinessOutreachService, BusinessExpertOutreachService)
- **Post-quantum security tasks:** 8 (Phase 2.5.1-2.5.8: session audit, Kyber rotation, prekey exhaustion, BLE mesh PQ, federated gradient PQ, cloud transport PQ, on-device storage audit, PQ dashboard)
- **Post-quantum transport coverage:** Signal sessions (DONE via PQXDH), BLE discovery (Phase 2.5.4), federated gradients (Phase 2.5.5), cloud TLS (Phase 2.5.6), on-device storage (Phase 2.5.7 -- audit only, likely already safe)
- **Locality happiness advisory tasks:** 17 (8.9A.1-8.9A.5 happiness aggregation, 8.9B.1-8.9B.6 advisory threshold, 8.9C.1-8.9C.5 cross-region transfer, 8.9D quantum readiness notes)
- **Model lifecycle management tasks:** 13 (Phase 7.7.1-7.7.13: version schema, OTA delivery, compatibility gate, staged rollout, rollback controls, deterministic rollout ledger, known-bad suppression, continuity/forgetting-risk governance)
- **Autonomous research/experimentation tasks:** 41 (Phase 7.9.1-7.9.41: hypothesis mining, interdisciplinary retrieval, self-expanding taxonomy, staged experiments, deterministic journaling, cross-reference scoring, rollback governance, profile-gated systems optimization, bounded-space simulation/model policies, formal invariant oversight, delegation-control governance, adaptive-depth runtime + compute-optimal governance, kernel-bound autonomy + recursive meta-audit + first-occurrence/dwell controls + storm suppression + high-impact oversight caps + downstream scaling regime/sensitivity governance)
- **Multi-device reconciliation tasks:** 6 (Phase 7.8.1-7.8.6: device-linked accounts, episodic merge, personality sync, tier-aware sync, device migration, conflict resolution)
- **Data transparency tasks:** 4 (Phase 2.1.8-2.1.8C: "What My AI Knows" page, "Why this recommendation?" tap-through, data correction mechanism, admin transparency dashboard)
- **Third-party data pipeline tasks:** 7 (Phase 9.2.6A-9.2.6G: insight catalog, DP noise injection, generation pipeline, consent gate, access control, buyer onboarding, revenue attribution)
- **Creator-side intelligence tasks:** 3 (Phase 6.1.13-6.1.15: community creator intelligence, event creator optimization, creator feedback loop)
- **Internationalization tasks:** 7 (Phase 10.3.1-10.3.7: ARB extraction, locale detection, RTL support, AI explanation localization, name handling, date/currency localization, locality agent language context)
- **Accessibility tasks:** 8 (Phase 10.4.1-10.4.8: semantic labels, screen reader navigation, color contrast, dynamic text, knot alt-text, haptic alternatives, audio sonification primary, reduce motion)
- **Quantum hardware readiness level:** Plug-in ready (5 operations documented with circuit designs in `CloudQuantumBackend`), 6 future quantum-native concepts documented as architecture notes (Phase 11.4B), **4 locality happiness quantum advantage points** documented (Phase 8.9D)

### D. On-Device Storage Budget

| Component | Size |
|-----------|------|
| World model (4 ONNX models, current + 1 rollback per Phase 7.7.8) | ~2MB |
| Existing skill models (4 ONNX) | ~50KB |
| Episodic memory (SQLite) | ~5-50MB over time |
| Semantic memory (vector store) | ~1-5MB |
| ARB localization bundles (Phase 10.3) | ~2-5MB |
| Optional SLM (1-3B) | 700MB-2GB |
| **Total without SLM** | **~12-65MB** |
| **Total with SLM** | **~712MB-2.1GB** |

---

**Last Updated:** February 15, 2026 (v14 -- Execution Boundary Hardening Update. Tightened 10.9F.1 enforcement to require exactly one milestone ID per PR (`Mx-Py-z`) and mandatory `X.Y.Z` subsection references in every non-merge commit. This aligns CI traceability enforcement with phase-by-phase anti-drift execution governance. Previous: v13 robustness hardening update)  
**Source of Truth:** `docs/agents/reports/ML_SYSTEM_DEEP_ANALYSIS_AND_IMPROVEMENT_ROADMAP.md`
