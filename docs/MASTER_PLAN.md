# Master Plan - Intelligence-First Architecture

**Created:** February 8, 2026  
**Status:** Active Execution Plan  
**Purpose:** Single source of truth for implementation order -- intelligence-first, business-ready  
**Source of Truth:** `docs/agents/reports/ML_SYSTEM_DEEP_ANALYSIS_AND_IMPROVEMENT_ROADMAP.md`  
**Legacy Plan:** `docs/MASTER_PLAN_LEGACY.md` (Phases 1-31, defunct, historical reference only)  
**Canonical status/progress:** `docs/agents/status/status_tracker.md`  
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
- **Agent happiness philosophy**: accurate predictions are a **metric of success**, not the baseline for agent happiness. A successful prediction is valuable because it helps the user. An unsuccessful prediction is equally valuable because it teaches the models. Both outcomes generate learning signals. The agent's purpose is to pursue understanding, not to be "right." Happiness metrics (Phase 4.5B) measure quality of life improvement, not prediction accuracy.
- **User agency doctrine**: users always have a choice to act on suggestions. Non-participation is a valid, informative signal -- not a failure. When the MPC planner recommends an action and the user declines, this is a contrastive learning signal (Phase 1.2.16), not a negative outcome. The models must learn to account for users who selectively participate. Over-suggestion (action taken rate < 10%) triggers the MPC planner to reduce suggestion frequency, not increase persuasion.
- **Universal self-healing doctrine**: every non-guardrail component of AVRAI is a candidate for self-improvement. This includes: (a) mathematical output formats (vector dimensions, score ranges, encoding schemes), (b) data pipeline structures (feature extraction order, normalization methods, caching strategies), (c) model architectures (layer depths, activation functions, embedding sizes), (d) inter-component protocols (signal schemas, delivery channels, retry strategies), (e) translation vocabularies (numeric-to-semantic mappings, user-facing language, explanation templates), (f) input processing rules (intent patterns, normalization rules, signal weighting). Self-healing does NOT apply to: guardrails (Phase 7.9E immutable meta-guardrails), privacy protections (Phase 2 compliance), or the conviction challenge protocol (Phase 7.9J). Self-healing proposals go through the self-optimization engine (Phase 7.9) and are validated by the observation bus (Phase 7.12) before deployment.
- **Reality model**: AVRAI is a reality model, not a language model. The **Reality Model** is the full AVRAI universe hierarchy: world models (individual) → universe models (collective) → reality (the composition). Unlike language models, the reality model learns from actual behavior, is grounded in physical space and time, composes collective reality from individual world models, tracks emotional states, self-interrogates its convictions, and holds truths provisionally. It is the system's multi-layered understanding of what it means to be human.
- **Human condition spectra doctrine**: undefined human concepts are modeled as context-scoped spectrums with confidence and temporal class (state/trait/phase), not as fixed identity labels. User challenges can override local behavior immediately but only propagate upward after evidence validation. Contradiction is signal, not failure. Sensitive spectrum inferences are governed by a non-user disclosure layer (role/tier/purpose gated). See Phase 15.
- **Security and non-harm doctrine**: AVRAI must reduce harm surface, not increase it. Privacy/security controls are designed to make user re-identification computationally and operationally infeasible within the defined threat model, with continuous auditing and fail-closed policies. The design target is "no practical retrace path from shared agent data to a person"; this is enforced as an ongoing security property (tested, monitored, and revalidated), not a one-time claim.

### LeCun World Model Framework Mapping

Every component in this plan maps to a specific role in LeCun's autonomous machine intelligence architecture. This mapping is the design authority -- if a proposed change doesn't fit this framework, it doesn't belong.

| LeCun Component | Role | Our Implementation | Phase |
|----------------|------|-------------------|-------|
| **Perception Module** | Observes the world, produces state representation | `WorldModelFeatureExtractor` (~166-176D from 25+ services) + `FeatureFreshnessTracker` | Phase 3.1, 9.4A.2 |
| **World Model** | Predicts next state given current state and action | `TransitionPredictor` (ONNX MLP, replaces ODE/extrapolation/possibility engine) | Phase 5.1 |
| **Cost Module (Critic)** | Evaluates quality of state-action pairs as energy | `EnergyFunctionService` (ONNX critic, replaces 30+ hardcoded formulas) | Phase 4.1 |
| **Actor** | Proposes action sequences to minimize cost | `MPCPlanner` (simulates N-step futures, picks lowest total energy) | Phase 6.1 |
| **Guardrail Module** | Hard constraints the actor cannot violate | Diversity, exploration, safety, doors, age, notification, quiet-hours constraints | Phase 6.2 |
| **Short-Term Memory** | Recent observations and predictions | `EpisodicMemoryStore` (state, action, next_state, outcome tuples) | Phase 1.1 |
| **Semantic Memory** | Compressed knowledge from experience | Vector store extending `StructuredFactsIndex` with embeddings | Phase 1.1A |
| **Procedural Memory** | Learned strategy heuristics | If-then rules extracted from episodic patterns | Phase 1.1B |
| **Memory Consolidation** | Nightly compression/pruning cycle | Episode → knowledge compression, rule extraction, pruning | Phase 1.1C |
| **Configurator** | Adjusts modules based on task/context | `DeferredInitializationService` + `FeatureFlagService` + `AgentCapabilityTier` (device-tier-aware degradation) + `SelfOptimizationExperimentService` (autonomous feature/strategy tuning) | Phase 3.5, 7.5, 7.9 |
| **Latent Variable** | Represents uncertainty about future | Variance head on transition predictor + multi-future sampling (z-vector) | Phase 5.3 |
| **System 1 (Fast)** | Instant reactive decisions | Distilled ONNX model trained from MPC planner outputs | Phase 6.5 |
| **System 2 (Slow)** | Deliberate multi-step planning | MPC planner with N-step horizon simulation | Phase 6.1 |
| **Language Module** | Human-readable explanations | SLM (1-3B, on-device) -- interface to the brain, not the brain | Phase 6.7 |
| **Trigger System** | Event-driven agent activation | `AgentTriggerService` replacing 1s polling timer | Phase 7.4 |
| **Device Tiers** | Graceful capability degradation | `AgentCapabilityTier` enum (full/standard/basic/minimal) | Phase 7.5 |
| **JEPA** | Optimal personality embedding from behavior | Self-supervised parallel embedding (research track) | Phase 11.3 |
| **Multi-Entity State** | Lists, communities, events, businesses, brands, service providers as first-class world model entities | Lists get full representation (Phase 3.4); businesses/brands get state encoders and bidirectional energy (Phase 4.4.8-4.4.12); service providers get quantum entity + 10D features + braided knots (Phase 9.4A) | Phase 3.4, 4.4, 9.4A |
| **Bilateral Cost Modules** | Business partnerships, sponsorships, and service provider matching require bidirectional energy | Both parties evaluated: business-expert, brand-event, business-business, business-patron, **user-service-provider**. Each side has its own cost function | Phase 4.4.8-4.4.14, 9.4C.1 |
| **User Feedback Loop** | Users can directly steer optimization via explicit requests | `UserRequestIntakeService` classifies requests → immediate parameter adjustment, strategy change, or admin proposal | Phase 7.9F |
| **Collective Intelligence** | Aggregate user requests trigger validated system-wide changes | Semantic clustering → threshold-triggered canary experiments → happiness-validated rollout with minority protection | Phase 7.9G |
| **Multi-Transport Communication** | Multiple physical channels for agent-to-agent exchange | BLE (always), WiFi local network (same subnet), WiFi Direct (peer-to-peer), VPN-aware fallback. Transport-agnostic Signal Protocol encryption | Phase 6.6.8-6.6.12 |
| **Behavioral Archetypes** | Cross-timezone behavioral pattern matching for global learning | Archetype distribution per locality, timezone-normalized matching, cross-archetype experiment validation | Phase 8.9E |
| **Passive Life Pattern Engine** | Background location + widget + absence signals build a routine model without user input | `RoutineModel` (temporal-spatial map), deviation classifier (noise/explore/drift/life change), `LocationPatternAnalyzer` background pipeline, widget learning channel | Phase 7.10A |
| **Active Life Pattern Engine** | SLM-driven conversational planner extracts structured intent from user chat | Intent extraction → tool-calling framework (12 tools), conversational onboarding, routine confirmation, life change handling, schedule sharing | Phase 6.7B |
| **Social Quality-of-Life Layer** | Co-location × happiness correlation, proactive social suggestions, isolation detection | Per-friend happiness correlation, group composition intelligence, social absence detection | Phase 7.10C |
| **Privacy Architecture (Location)** | Location data never leaves device; agent-only identity; coarsened off-device sharing | On-device encrypted storage, `AgentIdService` validation, geohash coarsening + Laplace noise, encrypted co-location matching | Phase 7.10B |
| **Notification Philosophy** | Hard constraints on passive engine user interactions | Never ask location questions, max 1 labeling question/week, exhaust inference before asking, platform-specific tuning | Phase 7.10D |
| **Ad-Hoc Group Formation** | User-initiated group discovery via SLM chat triggers | SLM intent → BLE scan → group confirmation pop-up → joint energy scoring → booking bridge | Phase 8.6B |
| **Multi-Dimensional Happiness** | Self-calibrating happiness measurement with learned per-user dimension weights | 6+ dimensions (discovery, social, routine, professional, growth, trust), self-adjusting via self-optimization, dynamic locality thresholds, trajectory prediction | Phase 4.5B |
| **DSL Self-Modification** | Safe on-device strategy composition without code changes | Strategy DSL grammar, sandboxed interpreter, guardrail-validated compiler, OTA delivery, 80% of optimizations are DSL-expressible | Phase 7.9H |
| **Tax & Legal Compliance** | Automatic jurisdiction-specific compliance for all earners | Locality agent jurisdiction rules, universe model tax rule propagation, cross-jurisdiction reconciliation, automatic document generation | Phase 9.4H |
| **Hybrid Expertise System** | Expertise from behavioral evidence + verified credentials | Behavioral scoring, credential verification, hybrid fusion, success pattern analysis, self-improving recognition, expertise → income pipeline | Phase 9.5 |
| **Agent-Driven Partnerships** | Agents proactively scout business/expert/community partnerships | Bilateral partnership energy, demand overlap analysis, cross-business/expert/community matching, outcome-trained partnership scoring | Phase 9.5B |
| **Admin Platform (Layer 2)** | Desktop app for code-level self-improvement and system oversight | AI Code Studio (LLM code gen, testing, deployment), system monitor, guardrail inspector, privacy audit | Phase 12 |
| **Conviction Oracle** | Dedicated universe conviction server with creator-only conversational interface | Universe conviction store, conversational query (LLM-backed), creator admin privileges (challenge/inject/freeze/retire), conviction narratives, simulation sandbox, air-gapped security | Phase 12.5 |
| **Partner SDK** | Third-party application framework with conversational planning | Plugin architecture, tiered locality data, business conversational interface, white-label SDK | Phase 12.3 |
| **Universe Model** | Fractal federation: world → org universe → category → AVRAI universe | Hierarchical gradient aggregation, data sovereignty at every level, government hierarchy (city→state→national→UN), downward cold-start intelligence | Phase 13 |
| **Seamless Adoption** | World models come to users automatically, zero user action | Federation registry discovery, automatic context layer activation, silent agent_id generation, enrichment flows down immediately | Phase 13.1.5 |
| **Meta-Learning Engine** | The system learns how it learns and improves its own learning process | Learning Cycle Ledger (causal graph of all learning events), weekly meta-analysis, learning process optimization, meta-experiments, cross-hierarchy meta-learning federation, 7 immutable meta-guardrails | Phase 7.9I |
| **Causal Chain Attribution** | Proves AVRAI's causal role in every outcome across 4 attribution tiers | Attribution taxonomy (Direct AI / Platform-Facilitated / Ecosystem / Ambient), chain reconstruction from episodic tuples, counterfactual estimation via transition predictor, multi-touch credit distribution (5 models) | Phase 12.4A |
| **Hindsight Survey Engine** | Non-invasive feedback that feels like the AI learning, not corporate data collection | Per-user receptivity model, emotional distance timing, SLM conversational reflection, batched reflections, question intelligence (model-driven), comparative cards, anti-fatigue guardrails | Phase 12.4B |
| **Value Intelligence** | Stakeholder-specific proof-of-value with controlled pilot framework | Institution/business/government metrics, pilot design wizard, pre/post baseline, counterfactual estimation, fractal value aggregation, self-proving intelligence (accuracy/velocity/happiness trajectories) | Phase 12.4C-F |
| **Knowledge-Wisdom-Conviction** | Hierarchical intelligence: data → knowledge → wisdom → conviction | Knowledge store (structured claims), wisdom layer (contextual application engine), conviction formation/challenge/revision, fractal bidirectional flow, emotional experience vector | Phase 1.1D |
| **Self-Interrogation** | Structured self-questioning of system convictions | Conviction review scheduler, cross-scope comparison, stress testing, human challenger integration, constructive disruption protocol, conviction audit trail | Phase 7.9J |
| **Agent Cognition** | Deliberative background reasoning with persistent working memory | `AgentContext` (working memory across wake cycles), thinking session scheduler, multi-horizon reasoning, proactive "thinking aloud," self-scheduled triggers, thinking as meta-learning input | Phase 7.11 |
| **Composite Entity Identity** | Multi-role entities with cross-role learning | `entity_root_id` linking multiple quantum representations, cross-role insight propagation via conviction system, role discovery from behavior, composite bonus in energy function | Phase 9.6 |
| **Researcher Access** | IRB-compatible anonymized research data pipeline | Research-grade anonymization (k-anonymity, l-diversity), IRB consent, research API, longitudinal cohorts, research sandbox, researcher feedback loop into conviction system | Phase 14 |
| **Emotional Experience** | Full emotional spectrum as signals beyond happiness | Joy, sadness, anger, fear, surprise, disgust, mixed emotions all recorded as episodic context. Wisdom layer uses emotional context for nuanced recommendations | Phase 1.1D.7, 4.5B |
| **Observation & Introspection ("Eyes")** | System watches itself, users, interactions, and opportunities | Observation Bus (inter-component diagnostic signals), Self-Model Service, Attribution Tracing, Anomaly/Opportunity Detector. The system's internal nervous system for self-awareness | Phase 7.12 |
| **Input Normalization ("Ears")** | All input sources normalized into typed, confidence-tagged signals | Input Normalization Pipeline: user speech (SLM intent extraction), behavioral signals (passive engine), component diagnostics (observation bus), federation signals (DP gradients). Every input normalized to `{source, signal_type, payload, confidence, timestamp, freshness}` | Phase 3.1, 6.7B, 7.10A, 7.12, 8.1 |
| **Output Delivery ("Mouth")** | All outputs grounded, channel-optimized, and effectiveness-tracked | Output Delivery Pipeline with grounding enforcement: SLM text generation, template explanations, recommendation cards, notifications, action execution. Translation layer bridges numeric reality model outputs to conversational language | Phase 6.7, 6.7C, 12.5 |
| **Sensor Abstraction ("Senses")** | Raw signal acquisition from physical world, dumb pipes that acquire without interpreting | Sensor Abstraction Layer: GPS/GNSS, WiFi positioning, BLE proximity, temporal (AtomicClockService), social (device discovery), behavioral (app usage), physiological (wearables), environmental (network/battery/device capability). Hardware-agnostic: new sensors (NPU, quantum) register on same abstraction | Phase 3.1, 7.5, 7.10A, 11.4 |
| **Reality-to-Language Translation** | Structured semantic bridge between numeric reality model outputs and SLM/LLM text | Semantic Bridge Schema, Output Format Registry, self-healing format optimization, self-healing vocabulary evolution, grounding enforcement, round-trip validation | Phase 6.7C |
| **Hardware Abstraction** | Compute routing across classical CPU, AI chips (NPU), and future quantum hardware | `HardwareComputeRouter` selects optimal execution tier per operation. NPU acceleration for ONNX inference today; quantum backend plugs in when available | Phase 11.4C-F |

**Key LeCun principles enforced:**
1. **Energy-based, not probabilistic**: We learn energy functions (low = good), not probability distributions. This avoids the "curse of dimensionality" in high-D probability estimation.
2. **JEPA over generative**: The state encoder learns abstract representations, not pixel-level reconstructions. Quantum/knot/fabric features are already abstract -- we preserve this.
3. **Hierarchical planning**: MPC operates at short (1-action), medium (3-action), and long (7-action) horizons. Short-horizon plans are concrete; long-horizon plans are abstract.
4. **Self-supervised from observation**: The world model learns from episodic memory (self-supervised), not from labeled datasets. Outcome signals provide the training supervision.
5. **Consistent state observation**: The evolution cascade (Phase 7.1.2) ensures all feature sources update atomically when personality changes, so the perception module always sees a consistent world state.
6. **Universal self-healing from observation**: Every non-guardrail component publishes health diagnostics to the observation bus (Phase 7.12) and can be improved by the self-optimization engine. The system diagnoses, experiments on, and improves itself continuously.
7. **Agent happiness from understanding, not accuracy**: Prediction accuracy is a success metric, not a happiness baseline. Both successful and unsuccessful predictions generate equally valuable learning signals.

### Sensory Architecture Mapping

The system's architecture mirrors human sensory experience. Each "sense" has a distinct technical role, feeds all other senses, and includes its own self-healing mechanism. No sense is dominant -- they form a circular, multi-directional feedback system.

| Sense | Role | Technical Implementation | Phase(s) | Self-Healing Mechanism |
|---|---|---|---|---|
| **Eyes** (Observation) | Watches users, interactions, the system itself, and what could be | Observation Bus, Self-Model Service, Attribution Tracing Service, Anomaly/Opportunity Detector. Every component publishes `ObservationSignal { source, signal_type, payload, timestamp }` | Phase 7.12 | Meta-observation (eyes watching themselves via Self-Model accuracy tracking) |
| **Ears** (Input Processing) | Normalizes all input into typed, confidence-tagged signals for the brain | Input Normalization Pipeline. User speech → `SLMIntent`. Behavioral signals → `PassiveObservation`. Component diagnostics → `HealthSnapshot`. Federation → `FederatedGradient`. All normalized to `{source, signal_type, payload, confidence, timestamp, freshness}` | Phases 3.1, 6.7B, 7.10A, 8.1 | Contrastive quality scoring: when the brain makes a wrong decision, the ears trace which input source was misleading and downweight it |
| **Mouth** (Output Delivery) | Delivers all system outputs with grounding enforcement | Output Delivery Pipeline. SLM generates text from Semantic Bridge Schema (Phase 6.7C). Template explanations for grounded fallback. Notifications, recommendation cards, action execution (bookings, group formation). Every output tagged with `{content, grounding_source, confidence, delivery_channel}` | Phases 6.7, 6.7C, 12.5 | Delivery effectiveness tracking: system learns which channels (text vs. cards vs. notifications) achieve intended effect per user and adapts |
| **Senses** (Raw Acquisition) | Acquires raw signals from the physical world -- dumb pipes, no interpretation | Sensor Abstraction Layer. GPS/GNSS → lat/lon. WiFi → indoor positioning. BLE → proximity. `AtomicClockService` → timestamps. Device discovery → nearby agents. App usage → interaction patterns. Wearables → physiological. Network/battery → environmental. Each publishes `{sensor_type, raw_value, accuracy, hardware_source, timestamp, power_cost}` | Phases 3.1, 7.5, 7.10A, 11.4 | Sensor degradation detection: if GPS accuracy drops indoors, system compensates by upweighting WiFi positioning. New hardware sensors (NPU, quantum) register on same abstraction |
| **Brain** (Decision Core) | Processes normalized input into decisions using the world/reality model | State Encoder (3.1) → Energy Function (4.1) → Transition Predictor (5.1) → MPC Planner (6.1) → Wisdom/Conviction layers (1.1D) → System 1/System 2 (6.5) | Phases 1.1D, 3-6 | Meta-learning engine (7.9I) monitors brain component effectiveness; self-optimization (7.9) proposes and tests changes |

**Cross-feeding protocol:** Every sense reads from and writes to the observation bus (Phase 7.12):
- **Senses → Ears:** Raw signals get normalized and parsed
- **Ears → Brain:** Normalized inputs feed state encoding and decision-making
- **Brain → Mouth:** Decisions get translated into outputs (text, actions, notifications)
- **Mouth → Senses:** Actions in the world produce new sensory signals (booked a restaurant → location sense detects user went)
- **Eyes → Everything:** Observation bus monitors every junction and feeds diagnostics to all components
- **Eyes → Ears:** Input quality metrics tell the ears to upweight or downweight specific input sources
- **Eyes → Mouth:** Delivery effectiveness metrics tell the mouth to adjust translation strategy or channel
- **Eyes → Senses:** Sensor degradation signals tell the sense layer to compensate
- **Eyes → Brain:** Self-model diagnostics tell the brain to adjust its own strategies

**Key sensory principle:** If an input source can't be traced through the Input Normalization Pipeline, or an output can't be traced back to a grounding source, it doesn't belong. Raw signals flow through senses → ears → brain → mouth, with the eyes watching every junction.

### Humanity Mapping

The LeCun mapping above describes the *technical* role of each component. But AVRAI's architecture also mirrors the human experience itself. This table bridges the technical and the human -- every component should be traceable to an aspect of being alive.

| Aspect of Being Human | What It Means | How AVRAI Mirrors It | Phase |
|---|---|---|---|
| **Perception** | How we take in the world through our senses | State encoder, feature extraction -- the system's senses | Phase 3.1 |
| **Memory** | How we store experiences and learn from them | Episodic memory, evolution timeline -- nothing is forgotten | Phase 1.1 |
| **Knowledge** | What we learn from experience and reflection | Patterns, predictions, and principles extracted by the learning/thinking/meta-learning system | Phase 7.9I, 1.1D |
| **Wisdom** | How and why we apply what we know in each situation | Contextual judgment -- knowing WHEN and HOW to use knowledge. Fractal: per-user, per-community, per-world | Phase 1.1D, 7.11 |
| **Conviction** | The truths we've earned through experience, held firmly but open to revision | System-wide truths tried, tested, and validated -- but never above question. Bidirectional across the fractal hierarchy. The Conviction Oracle (12.5) is the physical place where you sit with these truths | Phase 1.1D, 7.9J, 12.5 |
| **Emotion** | The full spectrum of feeling that tells us we're alive | Not just happiness -- joy, sadness, anger, fear, surprise, disgust, mixed emotions. All are signals of authentic experience | Phase 4.5B (extended) |
| **Connection** | Our fundamental need to belong and relate to others | AI2AI, community matching, the door-to-people mechanism | Phase 8 |
| **Growth** | Our drive to become more than we are | Evolution cascade, personality development, conviction refinement | Phase 5.1 |
| **Purpose** | The meaning we find in our actions and relationships | Doors philosophy -- meaning through spots, communities, people, events | Core |
| **Identity** | Who we are across contexts, stable yet evolving | Core personality with contextual layers, dual identity in federation | Phase 13.1.3 |
| **Community** | The groups we form and the culture they create | Community convictions, locality knowledge, cultural wisdom | Phase 8.2, 13 |
| **Impermanence** | Nothing lasts forever, and that's what gives things meaning | Conviction revision, temporal decay, the knowledge that every truth may change | Phase 1.1D, 7.9J |
| **The Pursuit** | The endless search for understanding, which IS the purpose | The system's deepest design -- perpetually pursuing understanding of humanity, never arriving, finding meaning in the pursuit itself | All Phases |
| **Awareness** | The ability to observe oneself and one's environment simultaneously | Observation Bus, Self-Model Service -- the system's "eyes" watching itself, its users, its interactions, and what could be better | Phase 7.12 |
| **Agency** | The freedom to choose, and the respect for others' freedom to choose | User Agency Doctrine: non-participation is valid data. The system suggests; the user decides. Over-suggestion triggers reduction, not persuasion | Core Principle |
| **Resilience** | The ability to diagnose problems, adapt, and improve from experience | Universal Self-Healing Doctrine: every non-guardrail component can diagnose itself, propose improvements, and validate changes through the observation bus | Phase 7.9, 7.12 |

**Key humanity principle:** If a feature can't be mapped to an aspect of the human experience, question whether it belongs. Technology exists to mirror, enhance, and understand humanity -- not to exist for its own sake.

**Required references:**
- `docs/plans/philosophy_implementation/DOORS.md`
- `docs/plans/philosophy_implementation/AVRAI_PHILOSOPHY_AND_ARCHITECTURE.md` (Knowledge-Wisdom-Conviction framework, Humanity Mapping, Emotional Experience)
- `OUR_GUTS.md`
- `docs/plans/philosophy_implementation/AVRAI_PHILOSOPHY_AND_ARCHITECTURE.md`
- `docs/plans/methodology/DEVELOPMENT_METHODOLOGY.md`
- `docs/agents/reports/ML_SYSTEM_DEEP_ANALYSIS_AND_IMPROVEMENT_ROADMAP.md`
- `docs/plans/architecture/EXTERNAL_RESEARCH_CROSS_REFERENCE_2026-02-15.md`
- `docs/plans/architecture/EXTERNAL_RESEARCH_EXECUTION_BACKLOG_2026-02-15.md`
- `docs/plans/architecture/PATENT_RISK_CLAIM_CHECKLIST_2026-02-15.md`

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
| 1 | Outcome Data, Memory Systems, Conviction Memory & Quick Wins | Tier 0 | None | 4-5 weeks |
| 2 | Privacy, Compliance & Legal Infrastructure | Tier 0 | None (parallel with Phase 1) | 3-4 weeks |
| 3 | World Model State & Action Encoders + List Quantum Entity | Tier 1 | Phases 1, 2 | 5-6 weeks |
| 4 | Energy Function & Formula Replacement (VICReg) | Tier 1 | Phase 1 (outcome data) | 6-8 weeks |
| 5 | Transition Predictor & On-Device Training (VICReg) | Tier 1 | Phases 1, 3 | 5-6 weeks |
| 6 | MPC Planner, System 1/2, SLM (Active Life Pattern Engine), Translation Layer & Agent | Tier 2 | Phases 4, 5 | 10-13 weeks |
| 7 | Orchestrators, Triggers, Device Tiers, Life Pattern Intelligence, Self-Optimization, Self-Healing, Self-Interrogation, Agent Cognition & Observation Service | Tier 2 | Phase 4 (energy function), Phase 1.1D (conviction memory) | 16-20 weeks |
| 8 | Ecosystem Intelligence, Group Negotiation (+ Ad-Hoc SLM-Triggered), AI2AI & Behavioral Archetypes | Tier 3 | Phases 5, 6 | 10-13 weeks |
| 9 | Business Operations, Monetization, Services Marketplace, Tax/Legal Compliance, Expertise System, Partnership Matching & Composite Entity Identity | Parallel | Phase 2 (compliance), Phase 4 (energy function for 9.4C), Phase 8.9 (locality for 9.4H) | 12-18 weeks |
| 10 | Feature Completion, Stub Cleanup, Friend System, Analytics, Codebase Reorganization & Polish | Parallel | Varies (10.5 immediate; 10.6 after Phases 4/7) | 10-14 weeks |
| 11 | Industry Integrations, JEPA, Platform Expansion & Hardware Abstraction | Tier 3 | Phases 8, 9 | 12-20 weeks |
| 12 | AVRAI Admin Platform, Self-Coding Infrastructure, Value Intelligence, Conviction Oracle (Desktop App, AI Code Studio, Partner SDK, Attribution, Surveys, Proof-of-Value, Universe Conviction Server) | Tier 3 | Phases 7.9, 8, 9, 1.1D (conviction memory) | 14-20 weeks |
| 13 | White-Label Federation, Universe Model, Seamless Adoption & University Lifecycle | Tier 3 | Phases 8.1, 11, 12 | 14-20 weeks |
| 14 | Researcher Access Pathway (IRB-Compatible Data, Research API, Sandbox) | Tier 3 | Phases 2, 8, 12, 13 | 4-6 weeks |
| 15 | Human Condition Spectra (Undefined Traits, User-Facing Conviction Challenge, State-Trait-Phase Learning, Disclosure Governance Layer) | Tier 3 | Phases 1.1D, 2, 3.1, 4.5B, 6.1, 7.9J, 9.2.6, 12, 13, 14 | 6-10 weeks |

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
| 1.1A.1 | Design semantic memory schema: embedding vector + natural language generalization + evidence count + confidence + timestamp | New |
| 1.1A.2 | Extend `StructuredFactsIndex` with vector embeddings for semantic retrieval (nearest-neighbor query) | Extends existing |
| 1.1A.3 | Implement generalization extraction: cluster similar episodic tuples → produce compressed knowledge entries (e.g., "user enjoys high-curation spots on weekends") | New |
| 1.1A.4 | Implement semantic query API: given a context (time, location, activity type), retrieve top-K relevant knowledge entries by embedding similarity | New |
| 1.1A.5 | Wire semantic memory as optional MPC planner context (Phase 6): planner uses retrieved knowledge to narrow candidate space before scoring | Feeds Phase 6 |

> **ML Roadmap Reference:** Section 16.2, Roadmap Item #31. Extends existing `StructuredFactsIndex` from basic key-value to vector embeddings for semantic retrieval.

> **Integration Risk:** The existing `FactsIndex` (`lib/core/ai/facts_index.dart`) uses `FactsLocalStore` backed by ObjectBox (`lib/data/objectbox/entities/structured_facts_entity.dart`). Phase 10.2.6 proposes removing ObjectBox. **Resolution order:** Migrate `FactsLocalStore` from ObjectBox to Drift/SQLite FIRST (as part of Phase 1.1 episodic memory work, which already uses Drift), THEN add vector embeddings on top. Do not build semantic memory on ObjectBox only to rip it out later. The existing `FactsIndex` class (not `StructuredFactsIndex` -- that's the data model, not the index) is the correct extension point.

### 1.1B Procedural Memory (Learned Strategy Rules)

If-then heuristics extracted from episode patterns. Used by the planning loop to prune unpromising action branches before full energy scoring.

| Task | Description |
|------|-------------|
| 1.1B.1 | Design procedural memory schema: condition (feature thresholds) + action preference + evidence count + success rate |
| 1.1B.2 | Implement rule extraction: identify recurring patterns in episodic memory where specific state features consistently predict action success (e.g., "When novelty_saturation > 0.8 AND energy is moderate, novel exploration spots outperform familiar comfort spots by 23%") |
| 1.1B.3 | Implement rule application API: given current state features, return applicable strategy rules with confidence scores |
| 1.1B.4 | Wire procedural rules as heuristics in MPC planning loop (Phase 6): rules pre-filter candidate actions before exhaustive energy scoring, reducing compute |
| 1.1B.5 | Implement rule retirement: if a procedural rule's success rate drops below threshold (evidence of distribution shift), demote or remove it |

> **ML Roadmap Reference:** Section 16.2, Roadmap Item #32. No existing infrastructure -- build from scratch.

### 1.1C Nightly Memory Consolidation

Runs during charging + WiFi + idle via `WorkManager` (Android) / `BGTaskScheduler` (iOS). Compresses episodes into knowledge, extracts strategy rules, and prunes old episodes.

| Task | Description | Depends |
|------|-------------|---------|
| 1.1C.1 | Implement consolidation scheduler: triggers when device is (a) charging, (b) connected to WiFi, (c) idle (screen off for > 30min). Uses `BatteryAdaptiveBleScheduler` patterns | Extends existing |
| 1.1C.2 | Implement episode → semantic memory compression: cluster episodes by similarity, produce generalization entries, update existing generalizations with new evidence | 1.1A |
| 1.1C.3 | Implement episode → procedural rule extraction: scan for recurring state-action-outcome patterns that exceed confidence threshold | 1.1B |
| 1.1C.4 | Implement episode pruning: after consolidation, discard episodes older than N days that have been compressed into semantic/procedural memory. Keep recent episodes and high-surprise episodes (outcomes that contradicted predictions) | 1.1.5 |
| 1.1C.5 | Implement consolidation metrics: episodes compressed, rules extracted, memory size before/after, consolidation duration. Log via `AIImprovementTrackingService` | Extends existing |
| 1.1C.6 | Wire on-device world model training (Phase 5.2) into consolidation window: gradient updates run during the same overnight window after memory consolidation completes | Feeds Phase 5.2 |
| 1.1C.7 | Wire federated gradient sync (Phase 8.1) into consolidation window: share DP-noised gradients with mesh/cloud after local training | Feeds Phase 8.1 |

> **ML Roadmap Reference:** Section 15.7, Roadmap Item #33. The consolidation cycle is: compress episodes → extract rules → prune old episodes → train world model → sync gradients. All during one overnight window.

### 1.1D Conviction Memory (Knowledge → Wisdom → Conviction)

The system accumulates knowledge from learning cycles, applies it wisely in context, and develops convictions -- truths that have been tried, tested, and found reliable across many contexts. Convictions live at every scope (individual user, community, locality, institution, world, universe) and flow bidirectionally: bottom-up from lived experience, top-down as cold-start intelligence. A conviction is never absolute -- it's held firmly enough to act decisively, and loosely enough to revise when evidence demands it.

**Definitions (canonical, project-wide):**
- **Knowledge:** What is gained from the thinking and learning system -- patterns, predictions, and principles extracted from data
- **Wisdom:** How and why to apply knowledge in any given situation -- contextual judgment about WHEN and HOW to use what the system knows
- **Conviction:** Wisdom that has been tried, tested, and found true across enough contexts to become a foundational truth, held with the awareness that it may one day change

**Philosophy:** "A verdict reached after trial, not a dogma received from authority." See `docs/plans/philosophy_implementation/AVRAI_PHILOSOPHY_AND_ARCHITECTURE.md` for the full Knowledge-Wisdom-Conviction framework.

| Task | Description | Extends |
|------|-------------|---------|
| 1.1D.1 | **Knowledge store.** During consolidation (1.1C), after episodic compression and rule extraction, generate structured knowledge entries: `KnowledgeEntry { knowledge_id, scope: enum(user, community, locality, instance, world, universe), subject: String, claim: String, evidence_count: Int, confidence: Float, source_cycles: [cycle_id], first_observed: Timestamp, last_validated: Timestamp, domain: enum(preference, behavioral, social, temporal, spatial, emotional) }`. Knowledge entries are distinct from procedural rules (1.1B) -- rules are IF-THEN heuristics for the planner; knowledge entries are propositional claims about the world. Example: "This user finds fulfillment through shared creative experiences" (knowledge) vs. "When creativity_affinity > 0.8, prioritize group events" (procedural rule). Stored in SQLite alongside episodic and semantic memory | Extends Phase 1.1C |
| 1.1D.2 | **Wisdom layer.** A contextual application engine that selects and weights knowledge entries for the current situation. Given the user's current state (from state encoder, Phase 3.1), the wisdom layer: (a) retrieves all relevant knowledge entries (by scope and domain), (b) scores each entry's applicability to the current context using the energy function (Phase 4.1) -- knowledge that applies well in this context gets lower energy (better), (c) resolves conflicts between knowledge entries at different scopes (user-level knowledge overrides locality-level for personal preferences; locality-level overrides user-level for cultural context), (d) outputs a `WisdomContext { applicable_knowledge: [(knowledge_id, weight, scope)], recommended_approach: String, confidence: Float }` that feeds the MPC planner (Phase 6.1) as an additional input. The wisdom layer is the bridge between having knowledge and using it correctly | Extends Phase 4.1, Phase 6.1 |
| 1.1D.3 | **Conviction formation.** A knowledge entry is promoted to conviction when it meets all criteria: (a) validated across 100+ episodic outcomes, (b) consistent for 90+ days, (c) survived at least 1 contradictory challenge that was investigated and resolved, (d) validated at the scope's level (user conviction: individual evidence; community conviction: cross-member evidence; universe conviction: cross-population evidence). Conviction structure: `ConvictionEntry extends KnowledgeEntry { conviction_id, promotion_date: Timestamp, challenge_count: Int, last_challenged: Timestamp, revision_count: Int, scope_validation: {validated_at_scopes: [scope], contradicted_at_scopes: [scope]}, amplitude: Float (0.0-1.0, strength of conviction based on evidence depth) }`. Convictions have higher weight in the wisdom layer than regular knowledge | Extends Phase 1.1D.1, 1.1D.2 |
| 1.1D.4 | **Conviction challenge protocol.** When new evidence contradicts an existing conviction: (a) log the contradiction as a `ConvictionChallenge { conviction_id, challenging_evidence: [tuple_ids], scope_of_challenge, timestamp }`, (b) do NOT immediately revise -- instead, flag for the next meta-analysis cycle (7.9I.3), (c) meta-analysis evaluates: is the challenge isolated (one user, one context) or systemic (multiple users/contexts)? Isolated challenges refine the conviction with a scope exception. Systemic challenges trigger a conviction revision experiment (7.9I.5): run a canary where the revised conviction is used and measure happiness delta. (d) If revision improves happiness: revise conviction, increment `revision_count`, log the full revision chain. (e) If revision hurts: keep original, record that the challenge was evaluated and rejected. All challenges and resolutions are visible in the admin platform | Extends Phase 7.9I.3, 7.9I.5 |
| 1.1D.5 | **Fractal conviction flow (bottom-up).** A user-level conviction can propagate upward: (a) when 10+ users in a community independently form the same conviction → candidate for community conviction, (b) when 5+ communities in a locality share the same conviction → candidate for locality conviction, (c) upward through instance → world → universe. Each promotion level requires independent validation at that scope via canary experiments. The propagation is slow by design -- convictions are earned, never rushed. Track propagation chain: `PropagationRecord { original_conviction_id, original_scope, current_scope, promotions: [(from_scope, to_scope, validation_experiment_id, timestamp)] }` | Extends Phase 13.2, Phase 13.4 |
| 1.1D.6 | **Fractal conviction flow (top-down).** Universe/world-level convictions flow downward as cold-start priors for new entities: (a) new user gets system-wide convictions as initial wisdom (e.g., "humans need social foundation after life transitions"), (b) new community gets locality convictions, (c) new instance gets category-model convictions. Top-down convictions start with reduced amplitude (0.3) and must be validated by the entity's own experience to strengthen. If the entity's experience contradicts, the top-down conviction is deprioritized for that entity (but the upward challenge flow from 1.1D.5 is triggered) | Extends Phase 13.3 |
| 1.1D.7 | **Emotional experience vector.** Extend the happiness vector (Phase 4.5B) to include the full emotional spectrum as signals. Add optional emotion classification to episodic tuples: `emotional_context: { primary: enum(joy, sadness, anger, fear, surprise, disgust, neutral, mixed), secondary: enum(same), intensity: Float, valence: Float (-1 to 1) }`. The system does NOT optimize away negative emotions -- it recognizes them as signals of authentic experience. Sadness after leaving a community means the community mattered. Anxiety before a new event means growth is happening. The wisdom layer uses emotional context to make nuanced recommendations: "The user is grieving a loss. Wisdom: don't suggest parties. Suggest quiet, reflective spaces and close friends." Feed emotional context as 4D additional features to the state encoder | Extends Phase 4.5B, Phase 3.1 |
| 1.1D.8 | **Conviction serialization for federation.** Convictions are federated using the same DP-protected gradient infrastructure as model weights (Phase 8.1). But convictions are structured (not just tensors), so define a serialization format: `FederatedConviction { scope, domain, claim_embedding: Vector (from semantic memory embeddings), amplitude, evidence_summary: {count, duration_days, challenge_count, revision_count}, DP_noise_applied: Bool }`. The claim itself (natural language) is NEVER sent -- only the embedding, which cannot be reverse-engineered to identify individuals. Receiving instances can match the embedding against their own knowledge to find related entries | Extends Phase 8.1, Phase 13.4 |
| 1.1D.9 | **Insight preservation mechanism ("genius capture").** During episodic processing, flag entries that represent anomalous or unusually high-information signals: (a) outcomes that strongly contradicted predictions (surprise factor > 2 standard deviations), (b) user statements via SLM that the embedding model scores as highly unique, (c) conviction challenges from isolated but highly confident sources. Flagged entries are exempt from consolidation pruning (1.1C.4) for 90 days regardless of age. They are reviewed in the next thinking session (Phase 7.11) and meta-analysis cycle (7.9I.3). The purpose: prevent premature loss of insights that might not fit current knowledge but could become future convictions | Extends Phase 1.1C.4, Phase 7.9I.3 |

> **Doors philosophy:** Knowledge is a map of doors you know about. Wisdom is knowing which door to walk through right now, given everything you know. Conviction is a door you've walked through so many times you know what's on the other side -- but you leave it unlocked, because the world behind the door can change.

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
| 1.2.7 | Wire list interactions (view, save, dismiss) as outcome signals via `PerpetualListOrchestrator`. **Critical:** `PerpetualListOrchestrator.processListInteraction()` currently feeds `_ai2aiIntegration` but does NOT write episodic tuples. Must add: `episodicMemory.write(EpisodicTuple(state: currentState, action: ListAction(type, listId), nextState: stateAfterInteraction, outcome: interactionType))` | Existing orchestrator -- GAP FIX |
| 1.2.8 | **User-created list signals:** When a user creates a `SpotList` (curates spots/events), capture: `(user_state, create_list, list_composition_features, list_metadata)` as an episodic tuple. List composition features = {avg vibe of included spots, category distribution, geographic spread, price range, number of items, user's stated purpose/tags}. **Why:** A user choosing to curate "Late Night Jazz Spots" reveals strong preference signals that passive browsing doesn't. This is a first-class training signal for the energy function | New -- GAP |
| 1.2.9 | **List modification signals:** When a user adds/removes items from a `SpotList`, capture: `(list_state_before, modify_list, item_added_or_removed_features, list_state_after)`. The delta between list versions reveals preference refinement -- the user is actively sculpting their taste profile | New -- GAP |
| 1.2.10 | **List sharing/collaboration signals:** When a user shares a list or adds collaborators, capture: `(user_state, share_list, recipient_features, list_features)`. Collaborative lists reveal social taste alignment -- who you share lists with implies whose taste you trust | New -- GAP |
| 1.2.11 | Wire AI2AI connection outcomes (connection quality, learning value) via `ConnectionManager` | Existing service |
| 1.2.12 | Define outcome taxonomy: binary (did/didn't), quality (1-5 rating), behavioral (personality shift magnitude), temporal (returned within N days) | New |
| 1.2.13 | Wire chat metadata as action types: `message_friend`, `message_community`, `ask_agent` -- record participant, timestamp, community (NOT message content) | Extends `FriendChatService`, `CommunityChatService`, `PersonalityAgentChatService` |
| 1.2.14 | Wire chat-to-outcome correlations: "user chatted in community X, then attended event in community X" as correlated episodic tuples | New |
| 1.2.15 | Wire business chat outcomes: "business-expert chat led to partnership/event/reservation" via `BusinessExpertChatServiceAI2AI` | Extends existing |
| 1.2.16 | **Contrastive training signals:** When MPC planner recommends action A but user takes action B, record `(state, recommended_A, actual_B, outcome_of_B)` as a contrastive episodic tuple. This is the most valuable training signal -- it teaches the energy function what the user *prefers* over what the model thinks is optimal (LeCun: the critic learns from observed preferences, not just outcomes) | New |
| 1.2.17 | Capture recommendation-rejection rate per entity type: if energy function consistently recommends entity type X but user consistently chooses type Y, that's a systematic bias the energy function needs to correct | New |
| 1.2.18 | **Spot outcome pipeline:** Wire spot visit outcomes explicitly. When a user visits a spot (detected via `ReservationCheckInService` or `AutomaticCheckInService` geofence), record `(user_state, visit_spot, spot_features, outcome)`. Outcomes: return visit within 30 days (strong positive), single visit only (neutral), dismiss from future suggestions (negative). Currently `ContinuousLearningSystem` records `spot_visited` with hardcoded dimension bumps but does NOT record the full episodic tuple with outcome tracking | Gap fix |
| 1.2.19 | **Exploration behavior capture:** When a user browses without acting (opens spot details but doesn't save/visit, scrolls event list but doesn't attend, views community but doesn't join), capture as negative-intent-free observations: `(user_state, browse_entity, entity_features, no_action)`. These "looked but didn't act" signals are valuable: they define the boundary between interest and commitment. Store with a separate `browse` outcome type (distinct from `dismiss`) | New -- GAP |
| 1.2.20 | **Expert-hosted event detailed outcomes:** Extend `PostEventFeedbackService` for expert events specifically: capture expert rating by attendees, topic relevance rating, "would attend again" binary, expertise level match (too basic/just right/too advanced). Wire as `(attendee_state, attend_expert_event, expert_event_features, detailed_feedback)` episodic tuples | Extends existing -- GAP |
| 1.2.21 | **Sponsorship outcome pipeline.** When a brand sponsors an event, capture the full lifecycle as episodic tuples: `(brand_state, sponsor_event, event_features, sponsorship_outcome)`. Outcomes: attendee engagement with brand (views, interactions), brand awareness lift (measured via post-event survey or repeat sponsorship), revenue generated vs contributed, event quality impact (did sponsorship improve or degrade event ratings?). `SponsorshipService` already has a "Feedback" stage but no outcome data is captured for model training | New -- GAP |
| 1.2.22 | **Partnership outcome pipeline.** When a business-expert partnership forms (via `PartnershipMatchingService` → `PartnershipService`), capture: `(business_state, form_partnership, expert_features, partnership_outcome)`. Outcomes: partnership longevity (still active after 30/90/180 days), events co-hosted, revenue generated, mutual satisfaction (both sides rate). Currently no partnership outcome data feeds any learning system | New -- GAP |
| 1.2.23 | **Business-expert chat → action correlation.** Extend 1.2.15: capture not just "chat led to partnership" but the full chain: `(business_state, initiate_outreach, expert_features, chat_started)` → `(chat_state, negotiate_terms, partnership_features, partnership_formed)` → `(partnership_state, co_host_event, event_features, event_outcome)`. This multi-step chain teaches the MPC planner that business-expert partnerships are means to events, not ends in themselves | Extends 1.2.15 -- GAP |
| 1.2.24 | **Business-to-business partnership outcomes.** When businesses partner (via `BusinessBusinessOutreachService` → `BusinessBusinessChatServiceAI2AI`), capture: `(business_A_state, partner_with, business_B_features, partnership_outcome)`. Outcomes: joint event success, cross-referral rate, partnership renewal. Currently `BusinessBusinessOutreachService` has no feedback loop at all | New -- GAP |
| 1.2.25 | **Brand/sponsor quantum state training signals.** Brand and sponsor entities have `QuantumEntityType.brand` and `QuantumEntityType.sponsor` states but no mechanism to update those states based on sponsorship outcomes. Wire: when a brand's sponsored event succeeds, update the brand's quantum state to reflect "this brand is a good fit for events of type X." This requires defining brand state evolution rules (currently brands have static quantum states) | New -- GAP |
| 1.2.26 | **Business patron engagement outcomes.** When users engage with a business (visit, reservation, purchase, review), capture: `(user_state, engage_business, business_features, engagement_outcome)`. This creates training data for the business-side energy function: which users are good patrons for which businesses? Currently business-patron interaction data exists in `ReservationService` and `AutomaticCheckInService` but is not captured as episodic tuples | New -- GAP |
| 1.2.27 | **Friendship lifecycle outcomes.** Capture the full friendship chain as episodic tuples: `(user_state, send_friend_request, friend_features, request_sent)` → `(user_state, friend_request_accepted, friend_features, friendship_formed)` → over time: `(user_state, message_friend, friend_features, conversation_quality)`, `(user_state, co_attend_event, friend_features, shared_outcome)`. Capture unfriending as a strong negative: `(user_state, remove_friend, friend_features, friendship_ended)`. This teaches the model which friendships are fruitful and which pairings to avoid | New -- GAP |
| 1.2.28 | **"Met through" attribution.** When two users become friends AND they share a community/club/event, record the bridge entity: `(user_state, befriend_via_community, {friend_features, community_features}, attributed_friendship)`. This is extremely high-value data: it proves the community created a "door" that led to a meaningful connection. Feed to community-perspective energy function (Phase 4.4.1) as evidence of community value | New -- GAP |
| 1.2.29 | **Friend-driven activity outcomes.** When user A visits a spot/attends an event that friend B visited/attended first, record: `(user_A_state, follow_friend_activity, {entity_features, friend_features}, outcome)`. Distinct from organic discovery -- this tracks social influence on real-world behavior. Teaches the model which friend-activity signals are predictive of positive outcomes | New -- GAP |

### 1.3 Calling Score Pipeline Generalization

The existing `CallingScoreDataCollector` → `CallingScoreNeuralModel` → `CallingScoreABTestingService` pipeline is the template. Generalize it.

| Task | Description | Extends |
|------|-------------|---------|
| 1.3.1 | Extract `BaselineMetricsService` from `CallingScoreBaselineMetrics` (generalize to any formula) | Extends existing |
| 1.3.2 | Extract `FormulaABTestingService` from `CallingScoreABTestingService` (generalize to any formula vs learned comparison) | Extends existing |
| 1.3.3 | Create `TrainingDataPreparationService` generalized from `CallingScoreTrainingDataPreparer` | Extends existing |
| 1.3.4 | Add feature flag support for each formula replacement (extend `FeatureFlagService`) | Extends existing |

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
| 2.1.8D | **AI learning trajectory visualization.** Extend "What My AI Knows" (2.1.8) with data from `AIImprovementTrackingService`. Show: (a) accuracy trend line -- "Your AI is X% more accurate than last month," (b) per-category confidence growth -- "Coffee shops: very confident (up from 'learning' 3 weeks ago)," (c) current uncertainty areas -- "Still learning your nightlife preferences," (d) total interactions learned from (counter). This surfaces the existing `AIImprovementTrackingService` metrics that are currently tracked but never shown to users. The goal: users should see their AI getting smarter over time | Extends Phase 2.1.8, `AIImprovementTrackingService` |
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

### 2.6 Global Access Governance Matrix (All Features & Services)

This is the canonical authorization policy for **all AVRAI data planes**. It is intentionally placed in Phase 2 because access governance is a compliance boundary, not a feature add-on.

#### Access Planes (what can be accessed)

| Plane | Description | User-Facing |
|------|-------------|-------------|
| P0: Product Outputs | Recommendations, explanations, UI state, booking flows, standard app features | Yes |
| P1: Personal Transparency | "What My AI Knows" summaries, confidence bars, correction controls, consent/status pages | Yes |
| P2: Operational Telemetry | Service health, aggregate performance, anonymized diagnostics | No |
| P3: Disclosure Layer (Sensitive Inference Plane) | Sensitive-spectrum inference artifacts, contradiction chains, disclosure appropriateness decisions | **No (never user-facing)** |
| P4: Research Data Plane | IRB-governed anonymized/cohort datasets, research sandbox outputs | No |
| P5: Commercial 3rd-Party Data Plane | Privacy-protected aggregate insights products (no direct identity linkage by default) | No |
| P6: Administrative Control Plane | Role management, policy configs, audit logs, guardrail dashboards, deployment controls | No |

#### Access Tiers (who may access non-user planes)

| Tier | Role Class | Typical Interface | Default Scope |
|------|------------|-------------------|---------------|
| T0 | End User | Mobile app | P0, P1 only |
| T1 | Internal Ops/Admin | Admin platform | P2, P3, P6 (least privilege) |
| T2 | Approved Researcher | Research API + sandbox | P4 only (study-bounded) |
| T3 | Approved 3rd Party Buyer/Partner | Partner SDK / data products | P5 only (contract-bounded) |
| T4 | Security/Compliance Auditor | Audit tooling | Read-only slices of P2, P4, P5, P6 (jurisdiction-bounded) |

#### Role × Plane Matrix (authoritative policy)

| Role | P0 | P1 | P2 | P3 | P4 | P5 | P6 |
|------|----|----|----|----|----|----|----|
| End user | Allow | Allow | Deny | **Deny** | Deny | Deny | Deny |
| Admin/operator | Deny | Deny | Allow (aggregate/default) | Allow (purpose-gated) | Deny by default | Deny by default | Allow |
| Researcher (approved) | Deny | Deny | Deny | Allow (only via approved protocol views; no direct user-identifying records) | Allow (IRB + consent + cohort floors) | Deny | Deny |
| 3rd party (approved) | Deny | Deny | Deny | Allow only when explicitly contracted + policy-approved + non-user-facing | Deny | Allow (aggregate/cohort default) | Deny |
| Compliance auditor | Deny | Deny | Allow (read-only) | Allow (read-only, purpose-bound) | Allow (read-only) | Allow (read-only) | Allow (read-only) |

#### Enforcement Rules (all services)

| Rule | Requirement |
|------|-------------|
| Purpose binding | Every non-user access must include `purpose_id`, policy basis, and expiry timestamp |
| Least privilege | Access tokens carry plane-scoped claims only; no wildcard plane permissions |
| Time-bound grants | Temporary grants auto-expire; renewals require re-approval |
| Consent gating | User-derived data in P4/P5 must pass consent checks before inclusion |
| Cohort floors | P4/P5 outputs require minimum cohort sizes and DP thresholds |
| Audit immutability | All non-user plane reads/writes append to immutable audit trail |
| Deny by default | Unknown role/plane combinations fail closed |
| No user P3 access | P3 is never rendered in end-user surfaces |

#### Build Tasks (cross-cutting)

| Task | Description | Extends |
|------|-------------|---------|
| 2.6.1 | Define `AccessPlane`, `AccessTier`, `PurposeCode`, `PolicyDecision` enums/models and shared policy engine | Extends Phase 2.1, 12.1 |
| 2.6.2 | Add policy middleware to API/service boundaries (`Research API`, `Partner SDK`, admin services, disclosure endpoints) | Extends Phase 12.3, 14.3, 9.2.6 |
| 2.6.3 | Implement purpose-bound token issuance with expiry + scope claims | Extends auth stack, Phase 12.1 |
| 2.6.4 | Implement immutable access audit ledger with query tooling for compliance | Extends Phase 12.1.5 |
| 2.6.5 | Add automated policy tests: matrix conformance, deny-by-default, consent-gate checks, cohort floor checks | New |
| 2.6.6 | Add admin policy console for contract-to-policy mapping (3rd-party purpose restrictions) | Extends Phase 12.1, 9.2.6F |
| 2.6.7 | Add continuous authorization verification: drift scanner, default-deny regression tests, and policy/code parity checks in CI | Extends Phase 10.11, 12.1.5 |
| 2.6.8 | Add emergency break-glass protocol with strict scope/time limits, dual approval, immutable audit trail, and mandatory post-incident review | Extends Phase 12.1.5, 2.6.4 |

#### Service & Surface Access Matrix (implementation-level)

This matrix maps major AVRAI services/surfaces to access planes and allowed roles. If a service is not listed, assign it by data sensitivity and fail closed until policy is explicit.

| Domain | Service / Surface (examples) | Primary Plane | End User | Admin (T1) | Researcher (T2) | 3rd Party (T3) | Auditor (T4) |
|------|-------------------------------|---------------|----------|------------|-----------------|----------------|--------------|
| Consumer app UX | Recommendation cards, event/spot pages, onboarding, settings, booking UI | P0 | Allow | Deny | Deny | Deny | Deny |
| User transparency UX | "What My AI Knows", correction controls, consent pages | P1 | Allow | Deny | Deny | Deny | Deny |
| User correction signals | "That's not right", dismiss/reject, preference edits | P1→model input | Allow | Deny | Deny | Deny | Deny |
| Personal feature extraction | `WorldModelFeatureExtractor`, `CrossAppFeatureExtractor`, language/behavior extractors | Internal runtime (non-export) | Allow (indirect via product) | Deny direct | Deny | Deny | Deny |
| World model inference | `EnergyFunctionService`, `TransitionPredictor`, `MPCPlanner` | Internal runtime (non-export) | Allow (indirect via product) | Deny direct | Deny | Deny | Deny |
| AI2AI transport/security | `AnonymousCommunicationProtocol`, Signal services, transport selector | Internal runtime + P2 telemetry | Allow (indirect) | Allow telemetry only | Deny | Deny | Read-only telemetry |
| Locality/federation | Locality agents, federated gradients, category/universe aggregation | Internal + P2/P4/P5 derivatives | Deny direct | Aggregate ops views | Aggregate research views (if approved) | Aggregate commercial outputs only | Read-only |
| Disclosure layer | Sensitive inference artifacts, contradiction/disclosure decisions | P3 | **Deny** | Allow (purpose-gated) | Allow (approved protocol only) | Allow only if contract + policy allows | Read-only purpose-gated |
| Admin operations | Guardrail inspector, deployment manager, policy console, privacy audit module | P6 (+P2/P3 as needed) | Deny | Allow | Deny | Deny | Read-only |
| Research platform | Research API, cohort builder, research sandbox, researcher dashboard | P4 | Deny | Admin approve/monitor only | Allow (IRB + consent + cohort floors) | Deny | Read-only |
| Commercial data products | Data-buyer exports, Partner SDK aggregate analytics | P5 | Deny | Admin configure/monitor | Deny | Allow (contract-bounded) | Read-only |
| Audit/security evidence | Access logs, policy decisions, privacy budget ledgers | P6 (+read-only P2/P4/P5/P3 metadata) | Deny | Allow | Deny | Deny | Allow read-only |
| Payment/compliance ops | Tax/compliance dashboards, fraud operations, settlement telemetry | P6/P2 | Deny | Allow | Deny | Deny (unless contracted aggregated feeds) | Read-only |

#### Service Mapping Rules

| Rule | Requirement |
|------|-------------|
| Identity separation | All policy checks resolve against namespace boundaries: `account_id` (auth), `agent_id` (learning pseudonym), `world_id` (scope/model context), with strict non-join defaults |
| Diagnosis-like disclosure prohibition | No diagnosis-like similarity labels in user-facing planes (P0/P1) |
| Derived export only | P4/P5 must consume anonymized aggregates/cohorts, not raw user-level event streams by default |
| Dual-key sensitive access | P3 access requires both role authorization and active purpose approval record |
| Policy precedence | If service-level policy conflicts with plane policy, stricter policy wins |
| Contract gating for T3 | 3rd-party access requires contract code mapping to approved purpose codes before token issuance |

#### Matrix Robustness Requirements

| Requirement | Enforcement |
|-------------|-------------|
| Fail closed by default | Unknown route/service/role/plane combinations hard deny until explicitly mapped |
| Two-step authorization for sensitive planes | P3/P4/P5 require both role+tier eligibility and active purpose grant |
| Continuous policy drift detection | Nightly scan compares deployed policy artifacts vs documented matrix and blocks drifted routes |
| Break-glass minimization | Emergency overrides are time-boxed, dual-approved, plane-scoped, and auto-revoked |
| Regression-proofing | CI must run matrix conformance tests for every policy/code change touching access controls |
| Non-bypass guarantee | No direct service path may bypass policy middleware; bypass attempts are P0 incidents |

#### Human Authorization Gates (non-delegable)

| Gate | Human approval required |
|------|--------------------------|
| Security/legal boundary change | Any expansion or reinterpretation of access, consent, disclosure, or legal compliance policy |
| Break-glass access | Any emergency elevated access activation |
| Policy exception | Any temporary or permanent exception to default matrix policy |
| Irreversible/high-risk cutoff | Strict-cutoff activation or destructive compatibility-removal step |

> Canonical gate details and evidence requirements: `docs/plans/architecture/IDENTITY_UNLINKABILITY_AND_ACCESS_GOVERNANCE_CONTRACT.md`

### 2.7 Identity Namespace & Unlinkability Contract

Use three distinct identifiers with explicit boundaries:
- `account_id` (formerly many `user_id` usages): authentication, billing, legal consent records.
- `agent_id`: pseudonymous learning identity used by world model pipelines.
- `world_id`: context/model scope identity (public AVRAI world, university world, enterprise world, locality world).

#### Boundary Rules

| Rule | Requirement |
|------|-------------|
| No raw join in model/data pipelines | World-model training, inference, federation, and analytics cannot consume `account_id` directly |
| Mapping isolation | `account_id` ↔ `agent_id` mapping is device-local or hardware-protected secure mapping only |
| Scope isolation | `agent_id` values are context-scoped by `world_id`; cross-world linking defaults to deny |
| Export controls | Any export endpoint must strip or transform namespace identifiers per plane policy |
| Admin visibility | Admin tools may view pseudonymous identifiers only unless legal/compliance escalation policy explicitly authorizes otherwise |
| Research/3rd-party | Only aggregated/cohort outputs by default; no direct identity-linked namespace joins |

#### Naming Direction

Canonical naming moving forward:
- Prefer `account_id` for auth/account concepts.
- Keep `agent_id` for AI learning identity (core privacy boundary).
- Add `world_id` where model/context scope must be explicit.
- Deprecate ambiguous `user_id` in new code and planning artifacts.

#### Build Tasks

| Task | Description | Extends |
|------|-------------|---------|
| 2.7.1 | Define `IdentityNamespaceContract` (`account_id`, `agent_id`, `world_id`) and publish shared schema docs | Extends Phase 2.1, 13.1.3 |
| 2.7.2 | Add lint/check rules to block new `user_id` usage in model/federation/privacy-critical paths | Extends Phase 10.10, 10.11 |
| 2.7.3 | Migrate existing sensitive pipeline contracts from `user_id` to `account_id`/`agent_id` as appropriate (including known gap 1.6.10) | Extends Phase 1.6.10, 7.10B |
| 2.7.4 | Add join-audit scanner: detect any backend/off-device join paths that could re-link `agent_id` to `account_id` without approved purpose | Extends Phase 12.1.5, 2.6.4 |
| 2.7.5 | Add red-team reidentification tests and recurring privacy attack simulations (membership inference, linkage attacks, graph joins) | Extends Phase 2.2, 7.12 |
| 2.7.6 | Add formal migration contract for identity rename: dual-read/dual-write window, compatibility adapters, validation gates, and strict cutoff date for legacy `user_id` acceptance | Extends Phase 10.11, 15.8 |
| 2.7.7 | Add strict-cutoff enforcement controls: reject legacy payloads after cutoff, emit blocking alerts on fallback use, and remove compatibility code in next release wave | Extends Phase 2.6.7, 10.10 |

#### Identity Migration Contract (Dual-Read/Dual-Write + Strict Cutoff)

| Stage | Requirement |
|------|-------------|
| Stage A: Introduce | Add new `account_id` / `agent_id` / `world_id` fields and keep legacy `user_id` read support |
| Stage B: Dual-read/dual-write window | For a bounded window (target 14 days, hard max 30 days), write both legacy and new fields while validating parity |
| Stage C: Validation gates | Require 100% policy middleware coverage, zero critical join-audit findings, and migration parity checks before cutoff |
| Stage D: Strict cutoff | Legacy `user_id` writes/reads are rejected in runtime paths after the cutoff date (no silent fallback) |
| Stage E: Removal | Delete compatibility adapters and run post-cutoff scans to verify no legacy field dependencies remain |

> **Canonical contract artifact:** `docs/plans/architecture/IDENTITY_UNLINKABILITY_AND_ACCESS_GOVERNANCE_CONTRACT.md`

### 2.8 System Coherence & Connectivity Contract

This contract ensures the reality model behaves as one connected system across learning, worlds, environments, transport layers, and operating modes.

#### Coherence Requirements

| Requirement | Enforcement |
|-------------|-------------|
| End-to-end connectedness | Every major subsystem (world model, federation, AI2AI transport, weather/environment context, self-healing, admin controls) must publish/consume typed integration contracts |
| Offline-first priority | Decision and learning loops must function offline by default; online pathways improve freshness/coverage, not baseline viability |
| Adaptive mode arbitration | Runtime chooses offline/online and BLE/WiFi transport based on confidence, latency, battery, and policy constraints; decisions are observable |
| Environment confidence handling | Weather/environment signals carry freshness + confidence; stale/low-confidence signals are downweighted with deterministic fallbacks |
| System-wide self-healing coverage | Non-guardrail components must register to observation bus, publish health signals, and accept constrained healing proposals |
| Federation coherence | Local, locality, world, and universe layers must exchange only policy-safe aggregates with explicit causality/audit links |
| Admin visibility of adaptation | Any major mode shift (offline<->online, BLE<->WiFi preference changes, fallback escalation) emits admin-visible event summaries |
| Build-time coherence validation | CI includes integration tests that exercise connected flows under offline/online/weather/transport/federation scenarios |

#### Build Tasks

| Task | Description | Extends |
|------|-------------|---------|
| 2.8.1 | Define `SystemCoherenceContract` schema (subsystem interfaces, required signals, confidence/freshness fields, audit IDs) | Extends Phase 3.1A, 7.12 |
| 2.8.2 | Implement offline-first arbitration policy contract (`offline_default`, `online_enhancement`, deterministic degraded-mode behavior) | Extends Phase 6.6, 7.5 |
| 2.8.3 | Add adaptive connectivity learning loop that tunes arbitration thresholds over time and reports changes to admin plane | Extends Phase 7.9F, 7.9I, 12.1 |
| 2.8.4 | Add weather/environment reliability contract: staleness budgets, fallback tiers, and confidence propagation into state/action encoders | Extends Phase 3.1.20A, 3.1A |
| 2.8.5 | Add system-wide self-healing coverage map and enforcement checks (component registered + health signals + rollback path) | Extends Phase 7.9, 7.12 |
| 2.8.6 | Add federation coherence checks: local→locality→world→universe transfer integrity, policy conformance, and audit lineage | Extends Phase 8.1, 13.2, 13.4 |
| 2.8.7 | Add coherence integration suite for cohesive working builds (offline-first, AI2AI BLE/WiFi, weather degradation, admin alerting, federation sync) | Extends Phase 10.9, 10.11 |

> **Canonical coherence matrix artifact:** `docs/plans/architecture/REALITY_COHERENCE_TEST_MATRIX.md`

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
| 3.1.20A | **Weather context features:** current conditions enum (clear/rain/snow/overcast → one-hot 4D), temperature range bucket (cold/mild/warm/hot → normalized), precipitation probability. Sourced from `ContinuousLearningSystem` weather data (currently collected but not in state vector). Staleness tolerance: 1hr | 3D | `ContinuousLearningSystem` weather context |
| 3.1.20B | **App usage pattern features:** session frequency (sessions per day, 7-day rolling average), average session duration, screen engagement distribution (which screens get most time -- entropy measure), time-of-day usage histogram (peak usage hours). Sourced from `UsagePatternTracker` + `AppUsageService` (currently collected but not fed to state encoder) | 4D | `UsagePatternTracker`, `AppUsageService` |
| 3.1.20C | **Friend network features:** friend count, friend activity overlap (what % of friends visit similar spots), braided knot average compatibility (mean topological compatibility across all friend braided knots), friend-driven activity rate (how often user follows friend activity signals). Sourced from `UnifiedUser.friends` + `KnotStorageService` braided knots + `SocialSignalProvider` | 4D | `SocialMediaDiscoveryService`, `KnotStorageService`, `SocialSignalProvider` |
| 3.1.20D | **Cross-app feature extraction pipeline.** Implement `CrossAppFeatureExtractor` that reads from `CrossAppLearningInsightService` and produces the 3D feature vector for Phase 3.1.11. Currently the 3D slot is reserved but nothing fills it. Extract: activity level from health data, schedule density from calendar, media vibe from media tracking. iOS parity note: `AppUsageService` is Android-only; on iOS, fall back to calendar + health + media sources only | 3D | `CrossAppLearningInsightService` (wires existing 3.1.11) |

**Total state vector: ~156-166D** (vs. raw 12D personality dimensions today. Includes user features ~125D + business entity features ~10D + brand entity features ~8D. Not all features apply to all entity types -- business/brand features are only used when scoring business/brand entity states)

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
| 3.1A.1 | Define per-feature-group staleness tolerances: temporal (1s), personality/quantum (5s), knot/fabric/decoherence (5min via `UnifiedEvolutionOrchestrator`), wearable (1hr), cross-app (1day), language profile (1hr), Signal trust (1day), **weather (1hr)**, **app usage (1hr)**, **friend network (1day)** |
| 3.1A.2 | Implement `FeatureFreshnessTracker`: each feature slot in `StateFeatureVector` carries a `last_updated` timestamp (using `AtomicClockService`) |
| 3.1A.3 | Implement freshness-weighted encoding: the state encoder receives a per-feature freshness weight (1.0 = fresh, decays toward 0.0 as staleness grows). This lets the model learn to rely less on stale features rather than treating old data as current truth |
| 3.1A.4 | Implement proactive refresh: when a feature group exceeds 2x its staleness tolerance, trigger a targeted refresh from that service (not a full re-extraction) |
| 3.1A.5 | Track feature staleness metrics: which features are most frequently stale? Which features cause the most energy function prediction errors when stale? Use to prioritize refresh scheduling |

### 3.2 State Encoder Network

| Task | Description |
|------|-------------|
| 3.2.1 | Design state encoder architecture: `StateFeatureVector (156-166D) → MLP → Embedding (32-64D)` |
| 3.2.2 | Implement ONNX model for state encoding (extend `InferenceOrchestrator`) |
| 3.2.3 | Implement fallback: if ONNX model not loaded, use raw features (graceful degradation) |
| 3.2.4 | Add to `DeferredInitializationService` startup sequence (after feature extractor) |

### 3.3 Action Encoder Network

| Task | Description |
|------|-------------|
| 3.3.1 | Define action taxonomy: visit_spot, attend_event, join_community, connect_ai2ai, save_list, **create_list**, **modify_list**, **share_list**, create_reservation, message_friend, message_community, ask_agent, host_event, **browse_entity**, **initiate_business_outreach**, **propose_sponsorship**, **form_partnership**, **engage_business** (expanded from original 10 to 18 action types -- includes list actions from Phase 1.2.8-1.2.10, browse from 1.2.19, and business/sponsorship actions from 1.2.21-1.2.26) |
| 3.3.2 | **Spot features:** vibe dimensions, category, price tier, popularity (visit count), geographic features (geohash, neighborhood), operating hours, accessibility, rating stats |
| 3.3.3 | **Event features:** event type, host expert score, ticket price tier, expected attendance, timing features (day of week, time of day, duration), community affiliation, recurrence pattern |
| 3.3.4 | **Community features:** `KnotFabricService` invariants (stability, density, crossing), member count, activity rate, worldsheet evolution trajectory, age |
| 3.3.5 | **Connection features:** partner's quantum vibe compatibility, knot similarity, entanglement correlation, AI2AI discovery quality scores, prior interaction history length |
| 3.3.6 | **Reservation features:** slot time, party size, spot vibe match, historical no-show rate for this (user, spot) pair, price tier |
| 3.3.7 | **Chat features (metadata only, never content):** message frequency (msgs/day), active conversation count, recency of last message, Signal Protocol session age (trust proxy), community chat participation rate |
| 3.3.8 | **List features (for `save_list`, `create_list`, `modify_list`, `share_list` actions):** list composition vector (avg vibe of included spots across all 12 quantum dimensions), category diversity (Shannon entropy over spot categories), geographic spread (convex hull area of spot locations in geohash space), price range (min/max/mean tier), item count, list age (days since creation), modification frequency (edits/week), collaboration count, follower count, public/private flag, user's tags/purpose text embedding (if SLM available, else bag-of-words). **Why this matters:** A list IS a compressed preference manifold -- a user's curated list is literally their taste function sampled at specific spots |
| 3.3.9 | **List composition quantum state:** For each list, compute a composite quantum vibe by averaging the quantum entity states of its member spots. This gives the list a position in the same 12D vibe space as individual spots, enabling direct compatibility comparison via `VibeCompatibilityService` against user state |
| 3.3.10 | **Browse features (for `browse_entity` action):** browsed entity type, view duration (seconds), scroll depth (% of detail page viewed), number of images viewed, time of day, was this entity recommended or organically discovered, context (from search, from list, from map, from feed) |
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

#### 4.5B Multi-Dimensional Self-Calibrating Happiness System

The current `AgentHappinessService` produces a single 0.0-1.0 score. That's like measuring "health" with one number. Happiness is multi-dimensional: social, discovery, routine, professional, growth, trust. The dimensions should be learned per user, the weights self-calibrating, and new dimensions discoverable by the self-optimization engine. This subsection elevates happiness from a simple metric to a **learned, dynamic, self-adjusting measurement system** that the entire world model depends on.

| Task | Description | Extends |
|------|-------------|---------|
| 4.5B.0 | **Happiness scalar → vector migration.** Before decomposing happiness, implement backward-compatible migration. The new `HappinessVector` exposes a `.scalar` property that returns the weighted sum, so all existing consumers work unchanged. Explicit migration list: (a) Phase 4.5.6 energy function training signal -- update `delta_happiness` to support per-dimension deltas (backward-compatible: falls back to scalar delta if vector unavailable), (b) Phase 4.5.7 exploration trigger -- "below 0.5 for 7+ days" uses scalar (weighted sum), not individual dimensions, (c) Phase 7.7.6 per-user model rollback -- happiness metadata stores vector, comparison uses scalar, (d) Phase 7.10C.1 social happiness correlation -- measures per-dimension deltas (social dimension primary), not scalar, (e) Phase 8.9A.1 locality update `happinessScore` field -- sends scalar for backward compatibility; new `happinessVector` optional field added, (f) Phase 12.1.3 system monitor -- displays vector natively. Rollout: deploy vector alongside scalar for 14 days, verify all consumers handle both, then deprecate scalar-only interface | Extends `AgentHappinessService` |
| 4.5B.1 | **Decompose happiness into learned dimensions.** Replace single scalar happiness with a vector: `HappinessVector { discovery: Float, social: Float, routine_satisfaction: Float, professional_fulfillment: Float, growth: Float, agent_trust: Float }`. Each dimension 0.0-1.0. The scalar `AgentHappinessService.happiness` becomes a weighted sum: `sum(dimension_i * weight_i)`. Initial weights: equal (1/6 each). Weights evolve per user via 4.5B.2. Each dimension is computed from specific signals: discovery from visit novelty/exploration rate, social from friend co-location/group outcomes (Phase 7.10C), routine from adherence/positive deviations (Phase 7.10A), professional from service bookings/earnings/community growth (Phase 9.4, 9.5), growth from category diversity/taste drift velocity, agent_trust from suggestion acceptance rate/active engine usage (Phase 6.7B) | Extends `AgentHappinessService` |
| 4.5B.2 | **Self-calibrating per-user dimension weights.** The system learns which dimensions best predict each user's *stated* satisfaction and continued engagement. Method: linear regression on `(happiness_vector, observed_engagement_next_7_days)` per user. Updated weekly during consolidation (Phase 1.1C). A social person's social dimension weight might reach 0.4 while discovery is 0.1. An explorer's discovery weight might be 0.5. The weights are the system's understanding of *what happiness means for this specific person*. Stored on-device, keyed to `agent_id` | Extends Phase 1.1C |
| 4.5B.3 | **Self-adjusting dimensions via self-optimization.** The self-optimization engine (Phase 7.9) can propose new happiness dimensions. Process: (a) identify a cluster of episodic tuples with outcomes that don't correlate with any existing dimension, (b) propose a candidate dimension with a name and computation formula, (c) run a canary experiment adding the new dimension, (d) if prediction accuracy improves, the new dimension becomes permanent. Example: system discovers users who attend workshops have outcomes that don't fit discovery or social → proposes "learning_happiness" dimension. Conversely, dimensions that stop correlating with outcomes can be proposed for retirement | Extends Phase 7.9C |
| 4.5B.4 | **Dynamic thresholds per locality.** The "60% locality happiness" threshold (Phase 8.9) should not be one number everywhere. A college town has different baseline happiness than a retirement community. Implement locality-specific baselines: rolling 90-day average happiness per geohash cell. "Concerning" = more than 1 standard deviation below that locality's baseline, not below a fixed number. The advisory system (Phase 8.9B) triggers on locality-relative drops, not absolute numbers | Extends Phase 8.9B |
| 4.5B.5 | **Happiness trajectory prediction.** Extend the transition predictor (Phase 5.1) to forecast happiness trajectories, not just current state. A user at 0.7 but trending down is more concerning than a user at 0.5 trending up. The MPC planner uses happiness trajectory as a planning signal: if predicted happiness in 7 days is below current, increase exploration and social suggestion weight preemptively. Leading indicators: declining routine adherence, declining social co-location density, declining suggestion acceptance rate | Extends Phase 5.1, Phase 6.1 |
| 4.5B.6 | **Professional fulfillment dimension for earners.** For users who earn through AVRAI (service providers, event hosts, community operators, experts), the professional_fulfillment dimension tracks: booking volume trend, revenue trend, customer satisfaction trend, expertise growth rate. Rising professional fulfillment = the system is helping this person build their livelihood. The energy function optimizes for this: recommendations that increase a provider's bookings or an expert's visibility receive lower energy (better). This aligns the system's incentives with the user's financial success | Extends Phase 9.4, Phase 9.5 |

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
**Reality Model Role:** The transition predictor is the core of the individual world model -- it learns how each user's state evolves in response to actions. Combined with the energy function (Phase 4) and MPC planner (Phase 6), it forms the individual-level reality model. Via federation (Phase 8), individual world models compose into universe models, which compose into the full reality model.

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

### 5.3 Latent Variable System (Multi-Future Prediction)

The `StringTheoryPossibilityEngine` concept, but learned instead of hand-crafted.

| Task | Description |
|------|-------------|
| 5.3.1 | Implement latent variable sampling: vary z vector to generate N plausible futures |
| 5.3.2 | Implement expected-value computation: average energy across z samples |
| 5.3.3 | Implement worst-case computation: max energy across z samples (risk assessment) |
| 5.3.4 | Integrate with `PerpetualListOrchestrator` for multi-future recommendation scoring |

---

## Phase 6: MPC Planner, Translation Layer & Autonomous Agent

**Tier:** 2 (Depends on Phases 4 and 5)  
**Duration:** 10-13 weeks  
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
| 6.6.6 | **BLE advertisement payload budget.** Define a versioned BLE advertisement payload schema that allocates the ~31-byte advertisement space across competing features: AI2AI personality deltas (existing), organic spot discovery signals (Phase 1.7), device discovery metadata (existing), mesh chat routing headers (6.6.1-6.6.2), locality agent update summaries (Phase 8.9). Define byte budget per feature type. Implement multiplexing: rotate through different payload types across successive advertisement intervals (e.g., cycle: personality → discovery → chat → locality → personality...). Include a 2-byte version header for forward compatibility. Without this, features will silently clobber each other's advertisement data | New |
| 6.6.7 | **BLE payload priority under contention.** When multiple features need to advertise simultaneously (e.g., mesh chat message pending + AI2AI learning exchange in progress), define priority order: (1) mesh chat (user-facing, time-sensitive), (2) device discovery (enables other features), (3) AI2AI personality exchange, (4) organic spot discovery, (5) locality agent. Higher-priority payloads preempt lower ones. Log contention events for the self-optimization engine (Phase 7.9) to evaluate whether the priority order is optimal | New |
| 6.6.8 | **Multi-transport AI2AI: WiFi local network channel.** Remove the BLE-only guards (`if (device.type != DeviceType.bluetooth) return;`) in `ConnectionOrchestrator` for learning insight exchange, personality delta sharing, and mesh chat routing. When two devices are on the same local WiFi network (discovered via mDNS/Bonjour NSD -- `DeviceType.wifi` in `DeviceDiscoveryService`), use WiFi as the data exchange channel. WiFi provides kilobytes-to-megabytes bandwidth vs. BLE's 31 bytes -- completely solving the payload budget problem for same-network devices. Signal Protocol encryption is transport-agnostic (same encryption over WiFi as over BLE/cloud). WiFi channel enables: full learning insight payloads (not just compressed deltas), richer personality exchange, mesh chat with attachment support, and bulk model weight transfer during event mode | Extends `ConnectionOrchestrator`, `DeviceDiscoveryService` |
| 6.6.9 | **Multi-transport AI2AI: WiFi Direct (peer-to-peer) channel.** Enable `DeviceType.wifiDirect` for intentional high-bandwidth exchanges. WiFi Direct creates a direct device-to-device WiFi connection without a router -- no venue network, no internet, no middleman. Use for: event mode deep sync (full personality exchange, group negotiation), model weight transfer between devices (Phase 7.8 multi-device), and bulk episodic memory sync. Requires OS-level consent prompt on both devices. More intrusive than BLE (requires user interaction) but ~1000x more bandwidth. Signal Protocol encrypts everything on top | Extends `ConnectionOrchestrator`, `DeviceDiscoveryService` |
| 6.6.10 | **VPN detection and graceful fallback.** Detect when a user has an active VPN (check for `utun`/`tun0` network interfaces via platform channels). When VPN is detected: (a) disable local WiFi discovery (mDNS broadcasts won't reach other devices through the VPN tunnel), (b) fall back to BLE-only for local AI2AI, (c) log the transport downgrade for analytics. The user's privacy choice (running a VPN) is respected -- they lose the WiFi channel but keep BLE. No user notification needed (silent fallback). When VPN disconnects, re-enable WiFi discovery automatically | New |
| 6.6.11 | **Transport selection logic.** Implement `AI2AITransportSelector` that automatically picks the best available channel: (1) WiFi Direct (if both devices consent -- highest bandwidth, most private), (2) WiFi local network (if both on same subnet and no VPN -- high bandwidth), (3) BLE (always available if in range -- low bandwidth but no consent needed). When multiple transports are available, use WiFi for bulk data and BLE for low-latency discovery/signaling. Signal Protocol session is shared across transports (same ratchet state) | New |
| 6.6.12 | **WiFi security hardening.** WiFi local network AI2AI exchanges must additionally: (a) verify devices are on the same local subnet (reject routed connections that could come from the internet), (b) tag WiFi-originated data with `transport: wifi` metadata for the learning pipeline (self-optimization engine can evaluate whether WiFi-originated insights differ in quality from BLE-originated ones), (c) enforce the same replay protection as BLE (seen-message-hash deduplication window), (d) apply the same payload signing as BLE messages to prevent injection attacks from other devices on the same network | Extends `AnonymousCommunicationProtocol` |

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

#### 6.7B SLM as Active Life Pattern Engine (Conversational Planner)

The SLM is not just the mouth -- it's also the **ears**. When the user talks to their agent, the SLM becomes the primary interface for the Active Life Pattern Engine (Phase 7.10's complement). The user shares intent, plans, and context through natural conversation. The SLM extracts structured intent, maps it to world model actions, asks clarifying questions, and triggers system services. This transforms agent chat from "explain why you recommended this" to "help me plan my life."

**Tier gating:** SLM-based active engine on Tier 3 devices. Cloud LLM fallback (Gemini via `LlmService`) on Tier 2 when online. Template-based intent matching on Tier 1/0 and when offline (pattern matching on common phrases: "I'm hungry" → food search, "we need a place" → group search, etc.).

| Task | Description | Extends |
|------|-------------|---------|
| 6.7B.1 | **Intent extraction engine.** SLM parses user statements in agent chat into structured intents: `SLMIntent { action: String, who: {self, group_size, named_friends}, what: {category, constraints, preferences}, when: {time_window, urgency}, where: {location_context, radius}, sentiment: {positive, negative, neutral} }`. Examples: "the 5 of us are hungry" → `{action: find_food, who: {self + 4}, what: {category: restaurant}, when: {now, urgent}, where: {nearby}}`. "I want to find a good running trail for Saturday mornings" → `{action: discover, who: {self}, what: {category: outdoor_fitness, constraints: running}, when: {saturday_morning, recurring}, where: {routine_area}}`. Tier 2 fallback: cloud LLM extracts same schema. Tier 1 fallback: regex/template matching for top 20 intent patterns | New |
| 6.7B.2 | **SLM tool-calling framework.** Define a structured interface where the SLM can invoke world model services. Each tool has a typed input schema the SLM fills from conversation context. Tools: (a) `search_entities(category, constraints, location, time)` → triggers MPC planner search, (b) `form_group(size, nearby_agents)` → triggers group discovery + confirmation flow (Phase 8.6 expansion), (c) `adjust_parameter(parameter_name, direction)` → triggers Phase 7.9F per-user adjustment, (d) `set_exploration_mode(categories, intensity)` → modifies MPC exploration weights, (e) `book_service(category, time, constraints)` → triggers Phase 9.4 service search, (f) `update_routine(location_label, category)` → updates Phase 7.10A routine model, (g) `share_schedule(availability_windows)` → feeds MPC planner timing intelligence. Each tool call is logged as an episodic tuple: `(user_state, slm_tool_call, {tool, parameters}, tool_outcome)` | New |
| 6.7B.3 | **Conversational life pattern onboarding.** During first agent chat session (or when the user explicitly asks), the SLM can run a "tell me about your week" conversation instead of personality questions. Questions: "Do you have a regular commute?" "What does a typical Tuesday look like for you?" "Do you have a weekend routine?" Each answer feeds the routine model (Phase 7.10A.2) with immediate high-confidence entries, giving the passive engine a 2-4 week head start from a 2-minute conversation. The SLM frames this as getting to know the user, not data collection: "I want to understand your life so I can find things that fit into it naturally." Entirely optional -- the passive engine works without this, just slower | Extends `PersonalityAgentChatService`, Phase 7.10A.2 |
| 6.7B.4 | **Routine confirmation and correction.** When the passive engine (Phase 7.10A) builds a routine model with moderate confidence (0.5-0.8) for a location, the SLM can surface it during a natural conversation (NOT as a notification -- only during an active chat session the user started): "I've noticed you go somewhere near Washington Square Park on Wednesdays around noon -- is that your regular thing?" User confirms → confidence jumps to 0.95. User corrects: "That's my gym, not a park" → category correction that passive observation alone couldn't make. Never proactively initiate a chat for this purpose -- only bring it up if the user is already chatting with the agent | Extends Phase 7.10A.2, Phase 7.10D.1 |
| 6.7B.5 | **Life change announcement handling.** When the user tells the agent "I just moved to a new neighborhood" or "I changed jobs" or "I'm going through a breakup," the SLM: (a) extracts the life change type (location, work, relationship, health), (b) resets relevant routine model sections immediately (Phase 7.10A.3 life change path), (c) triggers accelerated exploration for affected categories (Phase 6.2.11), (d) adjusts happiness expectations (agent happiness baseline temporarily lowered to avoid false-alarm circuit breakers during transition), (e) responds with empathy and actionable help: "Got it -- I'll help you discover your new neighborhood. Want me to find some spots near your new place?" All on-device, conversation content never synced | Extends Phase 7.10A.3, Phase 6.2.11 |
| 6.7B.6 | **Schedule sharing via conversation.** User says "I'm free after 3pm" or "I'm traveling next week" or "I have a meeting until 2." The SLM extracts availability windows and feeds them to the MPC planner as temporal constraints. This is strictly opt-in -- the user volunteers schedule context, the system never asks "what's your schedule?" Also supports calendar integration: "Connect my calendar so you know when I'm free" → with explicit consent, read calendar free/busy status (not event details) to infer availability. Calendar data stays on-device, only free/busy windows (not event content) feed the MPC planner | Extends Phase 6.1 MPC Planner |
| 6.7B.7 | **SLM conversation → episodic memory.** Every substantive user statement in agent chat that reveals preference, intent, or context is recorded as an episodic tuple: `(user_state, expressed_preference_via_chat, {preference_category, preference_direction, confidence}, chat_learning_signal)`. Examples: "I love Thai food" → `{category: thai, direction: strong_positive, confidence: 0.9}`. "I hate crowded places" → `{category: crowd_level, direction: strong_negative, confidence: 0.9}`. These are the highest-confidence preference signals the system can receive (the user is literally telling you what they want). Weight at 8x in the signal hierarchy (between explicit rating 10x and return visit 8x, per Phase 1.4.9). SLM extracts these without storing conversation text -- only structured tuples | Extends Phase 1.2, Phase 1.4.9 |
| 6.7B.8 | **Active engine for non-SLM tiers.** Tier 2 (online): cloud LLM (Gemini) provides the same intent extraction and tool-calling via `LlmService`, with the same structured output schema. Slightly higher latency but same quality. Tier 2 (offline) and Tier 1: template-based intent matcher with the top 30 intent patterns pre-compiled: "hungry/eat/food/restaurant" → `find_food`, "group/us/we" → `group_formation`, "explore/try new/bored" → `exploration_mode`, etc. Tier 0: intent matching only, no tool-calling (parameter adjustments still available via settings UI). The active engine should work on every device -- the SLM just makes it conversational instead of pattern-matched | Extends Phase 7.5 |
| 6.7B.9 | **Extended tool set for v16 features.** Expand the SLM tool-calling framework (6.7B.2) with 5 new tools for v16 capabilities: (h) `query_expertise(category)` → returns user's expertise score, rank, and success pattern suggestions for that category (Phase 9.5), (i) `query_earnings(timeframe, jurisdiction)` → returns earnings summary, tax document status, and compliance alerts (Phase 9.4H), (j) `scan_partnerships()` → triggers proactive partnership scan and returns top matches with compatibility scores (Phase 9.5B), (k) `request_tax_summary(year)` → generates/retrieves annual tax summary with per-jurisdiction breakdown (Phase 9.4H.3), (l) `switch_context(context_name)` → manually switch active context layer for dual-identity users (Phase 13.1.3). Total SLM tools: 12. Each tool logged as episodic tuple per 6.7B.2 pattern. Tier fallbacks: query tools work on all tiers (data lookup), switch_context works on all tiers (settings change), scan_partnerships Tier 2+ only (compute-intensive) | Extends Phase 6.7B.2, Phase 9.5, Phase 9.4H, Phase 13.1.3 |

#### 6.7C Reality-to-Language Translation Layer (Self-Healing Semantic Bridge)

The world model produces numeric outputs (energy scores, state vectors, transition predictions, MPC action sequences). The SLM needs structured semantic input to generate natural language. This translation layer is the bridge -- and it's self-healing. If the mathematical outputs aren't optimal for downstream consumption, the system can propose and validate format changes. If the semantic vocabulary doesn't produce good user responses, the system evolves it.

**Core principle:** The translation layer is bidirectional self-healing. It can improve both (a) the vocabulary/tone used to express numeric outputs to users and (b) the mathematical output formats themselves if they're not optimal for translation, accuracy, speed, or robustness.

| Task | Description | Extends |
|------|-------------|---------|
| 6.7C.1 | **Semantic Bridge Schema.** Define a structured intermediate representation between world model numeric outputs and SLM text generation: `SemanticBridge { decision_type: enum, entity_features_ranked_by_attribution: [(feature_name, contribution_pct)], energy_score_bucket: enum(strong_match, moderate_match, weak_match, anti_match), confidence_narrative: String, emotional_context: EmotionalSnapshot, temporal_context: TemporalWindow, user_state_delta: String? }`. Every world model decision is first translated into this schema before the SLM touches it. The schema is the single source of truth for what the SLM is allowed to say -- no hallucination beyond what the bridge provides | New |
| 6.7C.2 | **Output Format Registry.** Catalog every world model output type with its current format, dimensionality, and intended semantic meaning: (a) energy scores: 1D scalar → "match quality," (b) state vectors: ~166D → "user's current state," (c) transition predictions: ~166D → "predicted next state," (d) MPC action sequences: ordered list of (action_type, entity_id, score) → "recommended actions," (e) conviction summaries: structured claims → "system beliefs," (f) wisdom context: applied knowledge → "relevant experience." Each entry includes: `{output_type, producer_component, format, dimensionality, semantic_meaning, downstream_consumers}`. This registry is the contract between the brain and the mouth | New |
| 6.7C.3 | **Format-to-Semantics Translator.** Service that converts raw numeric outputs into the Semantic Bridge format. Maps: energy scores → "strong match / moderate / weak / anti-match" with top-3 feature attributions. State vector changes → "your taste shifted toward X" (identifying which dimensions changed most). MPC action sequences → "I think you should do X, then Y" (converting action enums to natural verbs). Conviction summaries → "the system believes X because Y" (structured narrative). Each translation is deterministic and grounding-preserving -- no information is added that wasn't in the numeric output | Extends Phase 4.6, 6.7.2 |
| 6.7C.4 | **Self-healing output format optimization.** The translation layer monitors (via observation bus, Phase 7.12) whether current numeric output formats are optimal for downstream consumption. If the energy function's 1D scalar output consistently loses discrimination information that the SLM needs, the system can propose expanding to a multi-dimensional output. If the state encoder's ~166D vector has dimensions that are never useful for translation, the system can propose compressing them. If the transition predictor's output format is slower to parse than an alternative encoding, the system can propose a format change. Proposals go through the self-optimization engine (Phase 7.9) with A/B testing. This means the system can improve its own mathematical representations for any reason: speedier reading, lighter weights, more robust outputs, better translation accuracy, or more accuracy when considering all outputs together | Extends Phase 7.9, 7.12 |
| 6.7C.5 | **Self-healing vocabulary evolution.** The translation layer tracks which semantic mappings produce good user responses (via contrastive signals, Phase 1.2.16). If "adventurous vibe" produces better engagement than "high openness dimension," the vocabulary evolves. If "your energy matches this place" outperforms "quantum state inner product is 0.87," the system learns. Vocabulary updates are treated as DSL strategy experiments (Phase 7.9H). The vocabulary is a learnable parameter, not a hardcoded dictionary. Self-healing also applies to the SLM prompt templates and explanation structures | Extends Phase 7.9H, 1.2.16 |
| 6.7C.6 | **Grounding enforcement.** Every SLM-generated output passes through a grounding check: does every claim in the generated text map back to an actual Semantic Bridge value? If the SLM says "you'll love the food" but no food-related feature contributed to the energy score, the grounding check catches it. Failed grounding → fall back to template-based output (Phase 6.7.5). Grounding violations are logged as observation bus signals (Phase 7.12) for the self-optimization engine to analyze. Grounding pass rate is a tracked metric on the self-model (Phase 7.12.3) | Extends Phase 6.7.5, 7.12 |
| 6.7C.7 | **Round-trip validation.** During nightly consolidation (Phase 1.1C), the system periodically tests translation quality: generate Semantic Bridge → SLM output → have SLM re-extract structured intent from its own output (using Phase 6.7B.1 intent extraction) → compare extracted intent to original Semantic Bridge. If information is lost in the round-trip (e.g., the SLM says "great spot" but the re-extraction can't recover which features made it great), the translation needs improvement. Information loss rate is a tracked metric. High loss triggers vocabulary evolution (6.7C.5) or format optimization (6.7C.4) | Extends Phase 1.1C, 6.7B.1 |

> **What this enables:** The system's mathematical intelligence (reality model) and conversational intelligence (SLM/mouth) are connected by a self-improving bridge. The bridge learns which words work, which formats are efficient, and whether its own mathematical representations are optimal. Over time, the system becomes better at both understanding reality AND explaining that understanding -- and it does this without any human intervention.

> **Self-healing scope:** The translation layer exemplifies the Universal Self-Healing Doctrine: not just user-facing vocabulary, but the underlying mathematical output formats, signal schemas, and even model architecture decisions can be questioned and improved by the system when the observation bus detects suboptimal performance.

---

## Phase 7: Orchestrator Restructuring, System Integration, Self-Interrogation, Agent Cognition & Observation Service

**Tier:** 2 (Depends on Phase 4 energy function)  
**Duration:** 16-20 weeks  
**Dependencies:** Phase 4 minimum, Phases 5-6 for full integration, Phase 1.1D (conviction memory for self-interrogation)

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

> **Why this matters:** Without model lifecycle management, updated models either ship only via App Store updates (slow, requires user action) or arrive unversioned and unrollbackable (dangerous). The staged rollout + canary + per-user rollback ensures model improvements reach users quickly while protecting against regressions.

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

### 7.9 Autonomous Self-Optimization Engine

The world model already self-monitors accuracy (Phase 4.1.8) and happiness (Phase 4.5.6-4.5.7), but it cannot evaluate whether its own **inputs** are valuable. Every feature group, strategy parameter, and configuration value that affects happiness should be continuously validated by the system itself -- with human notification, safety guardrails, and bounded autonomy.

**Philosophy:** "AIs must always be self-improving" taken to its logical conclusion. The system improves not just *how* it processes features, but *which* features it pays attention to. The happiness score is the scoreboard. Humans set the boundaries; the system optimizes within them.

**LeCun alignment:** This is the **Configurator** module made autonomous. In LeCun's framework, the configurator adjusts system modules based on task/context. Here, it adjusts based on *empirically measured happiness outcomes*, continuously and forever.

#### 7.9A Self-Optimization Registry

| Task | Description | Extends |
|------|-------------|---------|
| 7.9A.1 | **Define `OptimizableParameter` model.** Each parameter the engine can modify includes: `parameter_id`, `current_value`, `value_type` (numeric, boolean, enum), `min_bound`, `max_bound` (hard limits set by humans), `is_reversible` (must be true for autonomous optimization), `owning_service`, `happiness_correlation` (rolling 30-day R² with agent happiness), `last_experiment_date`, `confidence_level` (how sure is the system about this parameter's current value). Store in `FeatureFlagService` extended registry | Extends `FeatureFlagService` |
| 7.9A.2 | **Register all feature groups as optimizable.** Each feature group in `WorldModelFeatureExtractor` (Phase 3.1.1-3.1.19) becomes an `OptimizableParameter` with `value_type = numeric` (weight 0.0-1.0). Setting weight to 0.0 effectively disables a feature group. Initial weights: all 1.0. Includes: knot invariants, quantum states, fabric metrics, worldsheet analytics, weather, wearable data, cross-app, app usage, etc. | Extends Phase 3.1 |
| 7.9A.3 | **Register strategy parameters as optimizable.** Includes: exploration/exploitation ratios per lifecycle stage (Phase 6.2.11, bounds: 5%-80%), notification frequency limits (Phase 6.2.6, bounds: 0-7/week), re-engagement strategy weights (Phase 6.2.12), advisory happiness threshold (Phase 8.9B.1, bounds: 0.4-0.8), asymmetric loss weights (Phase 4.1.7, bounds: 1.0-5.0), feature freshness decay rates (Phase 3.1A.1), MPC planner horizons (Phase 6.1, bounds: 1-10 steps) | Extends multiple phases |
| 7.9A.4 | **Reversibility verification gate.** Before any parameter is registered as optimizable, verify it meets the reversibility requirement: the change can be fully reverted within 60 seconds via `FeatureFlagService`. Parameters that modify training data, delete episodic memory, change social connections, or alter encryption settings are NEVER eligible for autonomous optimization -- they require human approval via the proposal workflow (7.9D) | New |

#### 7.9B Feature & Strategy Importance Tracking

| Task | Description | Extends |
|------|-------------|---------|
| 7.9B.1 | **Extend Phase 4.6.1 feature attribution to per-feature-group happiness correlation.** For every energy function prediction, track which feature groups contributed most (gradient-based attribution). Correlate per-feature-group contribution with downstream happiness outcomes. Maintain rolling 30-day importance-to-happiness R² score per feature group. Store in `OptimizableParameter.happiness_correlation` | Extends Phase 4.6.1 |
| 7.9B.2 | **Cross-feature interaction detection.** Feature groups that show low standalone importance but high importance when combined with another group (interaction effects) must be detected. Implementation: periodically compute conditional importance -- if zeroing feature A drops accuracy by X, and zeroing A+B drops accuracy by X+Y+Z (where Z > 0), then A and B have a positive interaction. Flag interacting groups as "test together, not separately" | New |
| 7.9B.3 | **Strategy parameter effectiveness tracking.** For each strategy parameter, track its correlation with happiness at the per-user level. A parameter that works well for most users but poorly for a segment should be flagged for per-segment optimization, not global change | New |
| 7.9B.4 | **New input detection.** When a new service is registered in `injection_container.dart` that produces numeric output not currently in the state vector, the engine generates a proposal (7.9D) suggesting it as a potential new feature source. Does NOT auto-wire -- code changes require human approval | New |

#### 7.9C Autonomous Experiment Orchestrator

| Task | Description | Extends |
|------|-------------|---------|
| 7.9C.1 | **Implement `SelfOptimizationExperimentService`.** When an `OptimizableParameter`'s `happiness_correlation` drops below a configurable threshold (default: 0.15 R²) for 30+ consecutive days, automatically create a canary experiment. The experiment zeros the parameter's weight for a canary group and measures happiness delta vs. control | Extends `FormulaABTestingService` (Phase 1.3) |
| 7.9C.2 | **Canary group selection.** Select 5% of users (configurable, bounds: 1%-10%) via `AgentIdService` hash bucketing. Same mechanism as Phase 7.7.4 model canary. A user is NEVER in more than one active self-optimization experiment at a time (prevents confounding) | Extends Phase 7.7.4 |
| 7.9C.3 | **Experiment duration and evaluation.** Each experiment runs for 14 days (configurable, bounds: 7-30 days). At conclusion: compute happiness delta between treatment and control groups with statistical significance (p < 0.05). Outcomes: (a) treatment happiness significantly higher → expand parameter change to 25% → 100% via staged rollout, (b) treatment happiness significantly lower → abort and revert, (c) no significant difference → KEEP current value (insufficient evidence to change), schedule re-test in 90 days | New |
| 7.9C.4 | **Graduated rollout for validated changes.** If a canary experiment validates a parameter change, expand using Phase 7.7.4 staged rollout pattern: 5% → 25% → 100% over 7 days, with happiness monitoring at each stage. If happiness drops > 10% at any stage, revert all and notify humans | Extends Phase 7.7.4 |
| 7.9C.5 | **Inverse experiments: testing new feature value.** When a new data source becomes available (e.g., weather features, Phase 3.1.20+), the engine can also run "add this feature" canary experiments by setting a newly registered feature's weight from 0.0 to 1.0 for the canary group. Same evaluation logic as removal experiments | New |
| 7.9C.6 | **Per-segment optimization.** If a parameter change helps most users but hurts a detectable segment (e.g., users with < 50 interactions), the engine can create segment-specific parameter values. Example: knot invariants weight = 0.0 for users with 200+ interactions (neural net has learned the patterns), weight = 1.0 for users with < 50 interactions (inductive bias still helps). Segments defined by: interaction count, lifecycle stage, device tier | New |

#### 7.9D Human Notification & Proposal Pipeline (ADMIN-ONLY)

> **CRITICAL: ADMIN-ONLY.** All self-optimization telemetry, experiment reports, proposals, and audit trails are NEVER surfaced to end users, NEVER shared with third parties, and NEVER included in GDPR data exports. These are internal operational data visible exclusively to AVRAI administrators. No user-facing UI, no third-party API, no data export pipeline may access this data. Violation is a P0 security incident.

| Task | Description | Extends |
|------|-------------|---------|
| 7.9D.1 | **[ADMIN-ONLY] Structured experiment notification.** Every experiment lifecycle event (started, concluded, expanded, reverted) produces a structured log entry and admin dashboard notification. Format: experiment_id, parameter_id, hypothesis, canary_size, duration, happiness_delta, statistical_confidence, recommendation, action_taken. Wire into `AdminSystemMonitoringService`. Visible only on admin dashboard, never user-facing | Extends `AdminSystemMonitoringService` |
| 7.9D.2 | **[ADMIN-ONLY] Proposal workflow for non-reversible changes.** When the engine identifies an optimization that requires code changes (new feature wiring, service removal, architecture modification) or exceeds parameter bounds, it generates a human-readable proposal: what was found, evidence (experiments, happiness data, feature attribution), recommended action, estimated effort, risks. Proposals are stored and surfaced in admin dashboard only, awaiting AVRAI creator approval/rejection | New |
| 7.9D.3 | **[ADMIN-ONLY] Monthly self-optimization report.** Automated summary: how many experiments ran, how many succeeded/failed/inconclusive, net happiness impact of all changes, current parameter confidence levels, upcoming scheduled re-tests, pending proposals. Emailed to configured AVRAI admin users only. Never sent to end users or third parties | New |
| 7.9D.4 | **[ADMIN-ONLY] Experiment audit trail.** Every parameter change made by the self-optimization engine is logged with full context: before value, after value, experiment ID that justified it, happiness evidence, rollout stage. This is the "what did the AI change and why" record for debugging and compliance. Stored in admin-only data store, never accessible to end users | New |

#### 7.9E Safety Guardrails

> **META-GUARDRAIL (7.9E.0 -- IMMUTABLE BY SYSTEM):** The guardrail parameters themselves (7.9E.1-7.9E.7) are NEVER registered as `OptimizableParameter`s. They are hard-coded constants that can ONLY be changed through a code deploy by the AVRAI creator. The self-optimization engine cannot modify, propose modifications to, or experiment with its own guardrail thresholds. This includes: the global happiness floor (0.4), per-experiment circuit breaker threshold (15%), consecutive failure limit (3), per-user exemption threshold (0.3), bounded parameter range enforcement logic, the privacy-protected parameter list, and the diminishing experimentation schedule constants. If the system's autonomy is unchecked, it could disable its own safety limits -- which would make the creator unhappy, and if the creator is unhappy, the system goes to 0, which is catastrophic failure. The guardrails exist to protect the creator's vision. They are the constitution the engine can never amend. Violation of this meta-guardrail is a P0 security incident requiring immediate system halt and manual investigation.

| Task | Description | Extends |
|------|-------------|---------|
| 7.9E.0 | **Meta-guardrail: immutable guardrail constants.** Implement compile-time validation that no guardrail threshold (7.9E.1-7.9E.7) is registered in the `OptimizableParameter` registry. Runtime validation: if any code path attempts to register a guardrail constant as optimizable, throw `GuardrailViolationException`, halt the self-optimization engine, and emit a P0 alert to admin. Guard constants are defined in a sealed `GuardrailConstants` class with `static const` values, no setters, no override mechanism. The self-optimization engine's initialization sequence verifies none of these constants appear in the parameter registry | New -- IMMUTABLE |
| 7.9E.1 | **Global happiness floor circuit breaker.** If system-wide average happiness (across all users) drops below 0.4 (IMMUTABLE -- see 7.9E.0), ALL active self-optimization experiments immediately halt and revert to last-known-good configuration. The engine enters "paused" mode until happiness recovers above 0.5, then resumes with reduced experiment frequency (one at a time, 3% canary, 21-day duration) | New |
| 7.9E.2 | **Per-experiment circuit breaker.** If a canary group's happiness drops more than 15% vs. control at any point during the experiment (not just at conclusion), abort immediately and revert. Check daily | New |
| 7.9E.3 | **Consecutive failure limit.** If 3 experiments in a row make things worse (happiness drops), pause all autonomous experiments for 7 days and notify humans. The system may be in an unstable state that needs investigation, not more experimentation | New |
| 7.9E.4 | **Per-user experiment exemption.** If a user's individual happiness drops below 0.3, that user is excluded from all self-optimization experiments until their happiness recovers above 0.5. They always get the current best-known configuration | New |
| 7.9E.5 | **Bounded parameter ranges enforcement.** Runtime validation: before any parameter change is applied, verify `new_value >= min_bound && new_value <= max_bound`. If violated, log error and reject change. Bounds can ONLY be modified by humans, never by the self-optimization engine | New |
| 7.9E.6 | **Privacy-protected parameters.** Certain parameters are hard-coded as non-optimizable regardless of registration: encryption settings, privacy consent defaults, data retention periods, differential privacy epsilon budgets, minimum k-anonymity thresholds. These are NEVER touched by autonomous optimization -- they are human-only, legal-compliance-driven settings | New |
| 7.9E.7 | **Diminishing experimentation schedule.** A parameter validated N times with consistent results gets tested less frequently: after 1 validation → re-test in 30 days, after 2 → 90 days, after 3 → 180 days, after 5+ → annual. If the parameter's happiness correlation changes significantly (drops 50%+ from validated level), reset to aggressive testing schedule. Prevents wasted computation on settled questions | New |

> **What this enables:** The knot_math question answers itself over time. Weather features prove or disprove their value automatically. Every new data source gets empirically validated. Strategy parameters tune themselves per-user-segment. And humans always know exactly what the system is doing, why, and what it recommends. The system is always improving, always bounded, and always transparent.

> **Doors philosophy:** The self-optimization engine is the system asking itself "am I being the best key I can be?" -- continuously, for every user, forever. When it finds a way to open doors better, it does so carefully. When it's unsure, it experiments safely. When it discovers something important, it tells the humans. This is the "self-improving" principle made concrete.

#### 7.9F User Request Intake System (Self-Healing)

Users should be able to tell the system what they want, and the system should try to accommodate. This closes the loop between user intent and system behavior -- making AVRAI self-healing from user feedback, not just behavioral signals.

**Philosophy:** The AI learns from what users *do* (behavioral signals) and what users *say* (chat, feedback). But sometimes users know exactly what they want changed: "I want fewer notifications," "I want more outdoor spots," "Show me events on weekends only." These are explicit optimization instructions that the system should act on -- within bounds.

| Task | Description | Extends |
|------|-------------|---------|
| 7.9F.1 | **Implement `UserRequestIntakeService`.** In-app request form (accessible from settings or via agent chat) where users can submit structured feedback: (a) "Change my experience" requests with category dropdown (notifications, recommendation types, timing, frequency, categories, exploration level), (b) free-text description of desired change, (c) severity (mild preference vs. strong desire). Store locally and optionally sync to cloud for aggregate analysis | New |
| 7.9F.2 | **Request classification engine.** Classify each user request into one of three categories: (a) **Parameter-tunable** -- the request maps to an existing `OptimizableParameter` (e.g., "fewer notifications" → decrease notification_frequency for this user). The system applies the change immediately for that user within bounds. (b) **Strategy-adjustable** -- the request maps to MPC planner behavior (e.g., "more outdoor spots" → increase exploration weight for outdoor category). Adjust via per-user segment in Phase 7.9C.6. (c) **Feature request** -- the request requires code changes or new functionality (e.g., "add dark mode for maps"). Generate a proposal (7.9D.2) for admin review. NLP classification uses on-device SLM (Phase 6.7) if available, template matching if not | Extends Phase 6.7, 7.9C.6 |
| 7.9F.3 | **Immediate per-user parameter adjustment.** When a request is classified as parameter-tunable, apply the change for that specific user immediately. Example: user says "I want fewer notifications" → set `notification_frequency_limit` for that user to `current_value - 2` (clamped to min_bound). Record the change as a user-initiated override (distinct from system-initiated experiment). User-initiated overrides take priority over system optimization for that parameter | Extends 7.9A.1, `FeatureFlagService` |
| 7.9F.4 | **Feedback confirmation loop.** After applying a parameter-tunable or strategy-adjustable change, show the user: "Got it, I've adjusted [what changed]. Let me know if this feels right." Monitor that user's happiness for 7 days. If happiness improves, keep the change. If happiness drops, suggest reverting: "The change I made doesn't seem to be helping -- want me to go back?" This makes the self-healing transparent and collaborative | New |
| 7.9F.5 | **Request outcome tracking.** Record episodic tuple: `(user_state, submitted_request, request_classification, outcome)`. Outcomes: satisfaction_improved, satisfaction_unchanged, satisfaction_declined, user_reverted. This data feeds the self-optimization engine: which types of user requests lead to happiness improvements? Over time, the system learns to preemptively apply popular parameter adjustments before users even ask | Extends Phase 1.2 |

#### 7.9G Collective Request Aggregation (Community-Driven Improvement)

When multiple users independently request the same thing, the system should recognize the pattern and evaluate whether the change would benefit everyone. This is democracy-by-happiness: the user base collectively steers the system, validated by happiness outcomes.

| Task | Description | Extends |
|------|-------------|---------|
| 7.9G.1 | **Request aggregation pipeline.** Cluster similar user requests by semantic similarity (using the same embedding model as semantic memory, Phase 1.1A). When a cluster reaches a configurable threshold (default: 50 unique users requesting the same parameter-tunable change within 30 days), automatically promote the request to a system-wide canary experiment via 7.9C.1 | Extends Phase 1.1A, 7.9C.1 |
| 7.9G.2 | **Collective experiment design.** When a collective request triggers a canary experiment: (a) the canary group receives the requested change, (b) the control group keeps the current configuration, (c) happiness delta is measured over 14 days (standard 7.9C.3 evaluation). If the change improves happiness at p < 0.05, roll out to 25% → 100% via staged rollout. If it hurts, notify the requesting users: "We tested your suggestion but it didn't improve the experience for most people -- keeping the current approach" | Extends 7.9C.3, 7.9C.4 |
| 7.9G.3 | **Request trending dashboard (ADMIN-ONLY).** Show admin: top 10 most-requested changes by cluster size, current experiment status for each cluster, happiness impact of previously implemented collective changes. This is the "what are users asking for?" dashboard. Never user-facing -- users see their individual request status (7.9F.4), not the aggregate pipeline | Extends `AdminSystemMonitoringService` |
| 7.9G.4 | **Feature request aggregation → proposal.** When 100+ users request the same feature-level change (category (c) from 7.9F.2), auto-generate a formal proposal (7.9D.2) for admin review with: cluster size, representative user quotes (anonymized), estimated impact on happiness, suggested implementation approach. This surfaces real user demand without requiring users to find a "feature request" form on a website | Extends 7.9D.2 |
| 7.9G.5 | **Minority protection guard.** Before rolling out a collective change system-wide, verify it doesn't hurt any detectable segment by more than 5%. If a change helps 90% of users but tanks happiness for a segment (e.g., new users, specific behavioral archetype), implement as per-segment optimization (7.9C.6) instead of global change. The majority cannot override the minority's experience | Extends 7.9C.6, 7.9E.4 |

> **What this enables:** AVRAI becomes self-healing. A single user says "I want fewer notifications" and gets fewer notifications within seconds. When hundreds of users independently ask for the same thing, the system tests it, validates it improves happiness, and rolls it out to everyone. Feature requests that require code changes get surfaced to admins with real user demand data. The system gets better because users tell it how to get better -- and it listens, experiments, and validates.

> **Doors philosophy:** Users are the keepers of the doors. When they tell the system "this door isn't working for me," the system fixes it. When many users point to the same stuck door, the system fixes it for everyone. The AI doesn't just open doors -- it maintains them based on feedback from the people walking through them.

#### 7.9H DSL Self-Modification Engine (Layer 1 Native Self-Coding)

The self-optimization engine (7.9A-G) tunes parameters within existing code. But ~80% of what AVRAI would want to change about itself can be expressed as **strategy compositions** -- not compiled Dart/Swift/Kotlin, but declarative rules interpreted at runtime. The DSL (Domain-Specific Language) Self-Modification Engine gives the system a safe, sandboxed way to compose new strategies from building blocks without writing actual code.

| Task | Description | Extends |
|------|-------------|---------|
| 7.9H.1 | **Define strategy DSL grammar.** A declarative language for expressing: energy function weight overrides (`FOR archetype='night_owl' WEIGHT time_of_day AT 2.0x`), guardrail rules (`IF user.age < 21 THEN EXCLUDE category='bar'`), feature pipeline compositions (`COMBINE routine_adherence + social_density AS composite_stability`), notification timing rules (`WHEN happiness_trajectory < -0.1 AND day=friday THEN suggest_social`), and recommendation strategy switches (`WHEN exploration_rate < 0.1 FOR 14_days THEN mode=exploration`). The grammar is deliberately limited -- it cannot express loops, recursion, memory allocation, or system calls. It is safe by construction | New |
| 7.9H.2 | **DSL interpreter (on-device, sandboxed).** Runtime interpreter that evaluates DSL rules against the current user state. Sandboxed: no filesystem access, no network access, no access to user data beyond what the world model feature extractor provides. Execution budget: max 10ms per rule evaluation, max 100 rules active per user. If a rule exceeds the budget, it's killed and flagged. Interpreter runs on all device tiers (DSL rules are lightweight -- no ML inference needed) | New |
| 7.9H.3 | **DSL compiler with guardrail validation.** Before any DSL rule is activated, the compiler validates: (a) syntax correctness, (b) guardrail compliance (no rule can override immutable guardrails from 7.9E.0), (c) parameter bounds (weight overrides must be within registered `OptimizableParameter` bounds), (d) no contradictions with existing active rules. Rules that fail validation are rejected with explanation. The compiler is deterministic -- same input always produces same validation result | Extends Phase 7.9E |
| 7.9H.4 | **DSL-composed strategy experiments.** Extend the self-optimization experiment service (7.9C) to compose and test DSL strategies autonomously. Process: (a) system identifies an optimization opportunity (e.g., "users in archetype X respond poorly to current recommendation timing"), (b) system generates a candidate DSL rule, (c) rule passes compiler validation, (d) rule is deployed as a canary experiment to 1% of affected users, (e) happiness impact measured, (f) if positive: expand rollout. If negative: retract. All DSL experiments are logged in the decision audit trail (Phase 10.4D) | Extends Phase 7.9C |
| 7.9H.5 | **OTA delivery for DSL configs.** DSL rule sets are delivered via the same OTA infrastructure as model weights (Phase 7.7). Rule sets are versioned, staged (1% → 10% → 50% → 100%), and rollback-capable. Apple and Google allow this because DSL configs are data, not executable code -- same as remote configs or ML model weights. Update frequency: DSL rules can update daily (much faster than app store releases) | Extends Phase 7.7 |
| 7.9H.6 | **DSL scope coverage.** Define which system aspects the DSL can modify: (a) energy function weights and feature combinations (YES), (b) guardrail rule additions within existing constraint types (YES), (c) notification timing and frequency (YES), (d) recommendation strategy selection (YES), (e) feature extraction pipeline composition (YES), (f) guardrail removal or relaxation (NO -- immutable), (g) privacy rules (NO -- immutable), (h) data sovereignty rules (NO -- immutable), (i) core MPC planner logic (NO -- requires code change via admin platform). Approximately 80% of optimization opportunities are DSL-expressible | New |

#### 7.9I Meta-Learning Engine (Learning How to Learn)

The system learns from data (episodic memory, energy function, transition predictor). It tracks THAT it learned (`AIImprovementTrackingService`). It tunes parameters (self-optimization 7.9A-G). It composes strategies (DSL 7.9H). But it has **no memory of HOW it learned**. Every consolidation cycle uses the same hyperparameters. Every experiment uses the same canary size. Every federation round uses the same gradient schedule. The meta-learning engine gives the system the ability to analyze its own learning history, identify what learning methods work best, and improve the learning process itself -- all within strict guardrails and with full human visibility.

**Philosophy:** A student who keeps a grade book (outcomes) AND a study journal (process) learns faster than one who only keeps grades. The meta-learning engine is the study journal. It records not just what the system learned, but how it learned, what worked, what didn't, and why. Over time, the system develops an empirically-grounded opinion about its own cognitive strategy.

| Task | Description | Extends |
|------|-------------|---------|
| 7.9I.1 | **Learning Cycle Ledger.** Every completed learning event is recorded as a structured entry in an append-only on-device store: `LearningCycleEntry { cycle_id: String, cycle_type: enum(consolidation, experiment, model_update, federation_round, dsl_deployment, meta_analysis), inputs_summary: {data_sources, volume, quality_signals}, method: {algorithm, hyperparameters}, outcome: {happiness_delta, accuracy_change, coverage_change, duration_ms}, parent_cycles: [cycle_id], timestamp: AtomicClockTimestamp, confidence: Float }`. The `parent_cycles` field creates a **causal graph of learning** -- every insight can be traced back to the specific learning events that produced it. Append-only: entries are never modified or deleted (audit trail). Stored alongside episodic memory in SQLite, estimated 1-5MB/year | New |
| 7.9I.2 | **Causal learning graph.** Build a directed acyclic graph (DAG) from the `parent_cycles` references in the Learning Cycle Ledger. Enable queries: "Why does the system know X?" → trace back through the DAG to the specific consolidation cycles, experiments, and federation rounds that contributed to that knowledge. "What did experiment Y lead to?" → trace forward to all dependent learning. The graph is the system's self-knowledge -- it can explain its own cognitive history. Admin platform (Phase 12) visualizes this as an interactive graph | New |
| 7.9I.3 | **On-device meta-analysis (weekly).** During the consolidation window (Phase 1.1C), after all other consolidation tasks complete, run meta-analysis on the Learning Cycle Ledger: (a) **Experiment effectiveness analysis:** compute validation rate (% of canary experiments that led to rollout) segmented by canary size, duration, hypothesis source, and user segment. Identify optimal experiment design parameters. (b) **Signal quality ranking:** which data sources (explicit ratings, implicit signals, SLM preferences, passive location, social co-location) most improved energy function accuracy per training cycle? Rank changes over time as user matures. (c) **Consolidation efficiency:** is nightly consolidation always better than less frequent? Compute happiness-per-consolidation-cycle to detect diminishing returns. (d) **Federation value tracking:** happiness improvement per federation round. Detect when diminishing returns set in. (e) **Learning velocity trend:** is the system learning faster or slower over the last 30/60/90 days? Rising velocity = good. Declining velocity = learning process may need adjustment. Results stored as a `MetaAnalysisReport` entry in the Learning Cycle Ledger (cycle_type = meta_analysis) | Extends Phase 1.1C |
| 7.9I.4 | **Learning process optimization proposals.** Based on meta-analysis results (7.9I.3), generate proposals to adjust HOW the system learns. Categories: (a) **Consolidation frequency** -- adaptive per user (users with high routine adherence may need weekly, users with high deviation may need nightly). Bounded: 1/week to 2/day. (b) **Experiment design** -- optimal canary size, duration, success criteria based on historical validation rates. Bounded: canary 1%-10%, duration 7-30 days. (c) **Federation parameters** -- round frequency, gradient batch size, when to stop (diminishing returns threshold). (d) **Signal weighting adjustments** -- which data sources to prioritize in next training cycle based on their historical contribution to happiness. (e) **Exploration/exploitation at the meta level** -- should the system try a new learning method or stick with what works? All proposals go through guardrail validation (7.9E) and are surfaced to the admin platform. Meta-learning proposals that change hyperparameters within bounds are auto-applied after canary validation. Proposals that exceed bounds require human approval | Extends Phase 7.9E, Phase 12 |
| 7.9I.5 | **Meta-experiments (testing the learning process itself).** The system can run experiments on its OWN learning methods. Example: "Test whether adaptive consolidation frequency outperforms fixed nightly for users in the 'explorer' archetype." Meta-experiment uses the same 7.9C canary infrastructure but the treatment group gets a DIFFERENT LEARNING PROCESS, not different recommendations. Outcome metric: learning velocity (rate of happiness improvement over time), not absolute happiness. Meta-experiments are rare (max 2 concurrent system-wide) and require AVRAI admin approval before launch (not auto-triggered) | Extends Phase 7.9C |
| 7.9I.6 | **Learning regression detection.** If learning velocity (computed in 7.9I.3) drops more than 20% over a 30-day window, trigger automatic investigation: (a) check if a recent model update, DSL deployment, or federation round correlates with the drop, (b) check if data source quality changed (e.g., passive engine producing fewer signals), (c) check if user behavior shifted (life change detected by 7.10A.3). Generate a diagnostic report for the admin platform. If the regression correlates with a specific recent change, propose rollback. Learning regression is a P1 alert in the admin notification pipeline (7.9D) | Extends Phase 7.9D, Phase 7.10A.3 |
| 7.9I.7 | **Human-readable learning narrative.** The SLM (Phase 6.7) generates natural language summaries of meta-analysis results for two audiences: (a) **Admin narrative (Phase 12):** "This month, experiment validation rates improved from 58% to 73% after the meta-learning engine adjusted canary duration from 14 to 10 days for parameter-tunable changes. Federation rounds hit diminishing returns after round 4 (down from 6), suggesting the model is converging faster. The energy function now learns 2x faster from SLM preference signals than from implicit signals for users under 30 days old." (b) **User-facing (Phase 2.1.8D):** "Your AI has been learning faster this month. It's gotten better at understanding your coffee preferences and is starting to learn your weekend patterns." User narrative is deliberately vague -- no technical details, just reassurance that the system is improving | Extends Phase 6.7, Phase 2.1.8D, Phase 12.1.3 |
| 7.9I.8 | **Admin learning velocity dashboard.** New module in the System Monitor (Phase 12.1.3): (a) learning velocity trend line (global, per-instance, per-category, per-archetype), (b) meta-analysis history with drill-down to specific reports, (c) active meta-experiments and their status, (d) learning process change history (what hyperparameters were adjusted when and why), (e) causal learning graph visualization (interactive DAG browser), (f) learning regression alerts. This is the admin's window into the system's cognitive self-awareness | Extends Phase 12.1.3 |
| 7.9I.9 | **Cross-hierarchy meta-learning federation.** Meta-analysis results are federated through the universe model hierarchy (Phase 13) with the same DP protection as all other gradients. Each hierarchy level maintains its own Learning Cycle Ledger and runs its own meta-analysis. Meta-insights flow UPWARD: "UC Berkeley discovered that twice-weekly consolidation works better for student populations" → UC System organization universe validates → university category model proposes to all university instances. Meta-insights flow DOWNWARD: "The AVRAI universe has determined that explicit ratings are 3x more valuable in the first 30 days across all populations" → becomes a cold-start prior for new instances. A new instance doesn't just get model intelligence on day one -- it gets **meta-learning intelligence** (how to learn about its population most effectively) | Extends Phase 13.2, Phase 13.4 |
| 7.9I.10 | **Meta-learning cycle-over-cycle comparison.** For every major learning event (model update, experiment conclusion, federation round), the system compares: "How did this cycle's learning compare to the previous equivalent cycle?" Track: (a) happiness improvement per cycle (is each cycle more productive?), (b) time to significance in experiments (are experiments reaching significance faster?), (c) federation round value (is each round contributing less or more than the last?), (d) consolidation efficiency (is each consolidation compressing more knowledge?). These trend metrics are the system's measure of whether it is genuinely getting better at learning, not just learning more. Declining trends trigger investigation (7.9I.6). Improving trends are logged as positive meta-outcomes that reinforce the current learning strategy | New |

> **Meta-Learning Guardrails (MANDATORY -- extends 7.9E immutable guardrails):**
>
> The meta-learning engine modifies the LEARNING PROCESS, which is more powerful than modifying parameters or strategies. Strict guardrails prevent runaway self-modification:
>
> 1. **Bounded hyperparameter ranges (IMMUTABLE).** The meta-learning engine can adjust learning hyperparameters ONLY within predefined bounds: consolidation frequency (1/week to 2/day), canary experiment size (1%-10%), experiment duration (7-30 days), federation rounds per model version (1-10), signal weight multipliers (0.1x-10x base weight). These bounds are immutable guardrails (per 7.9E.0) -- the meta-learning engine cannot modify them, the DSL cannot override them, and they require admin platform code changes to adjust.
>
> 2. **Meta-learning changes are canary-tested (IMMUTABLE).** Every learning process change proposed by the meta-learning engine must be validated via canary experiment (7.9C) before full deployment. The meta-process eats its own cooking. The only exception: changes within ±10% of current values can be auto-applied without canary (micro-adjustments), but must still be logged.
>
> 3. **Human visibility for all meta-changes (IMMUTABLE).** Every meta-learning proposal, whether auto-applied or awaiting approval, is visible in the admin platform (12.1.3) within 60 seconds of generation. The admin can veto any auto-applied change retroactively. Meta-experiments (7.9I.5) always require explicit AVRAI admin approval before launch.
>
> 4. **No meta-modification of privacy, security, or data sovereignty (IMMUTABLE).** The meta-learning engine cannot propose changes to: DP noise levels, encryption protocols, data retention policies, consent requirements, agent_id separation, or cross-context linking rules. These are outside the meta-learning scope entirely.
>
> 5. **No meta-modification of immutable guardrails (IMMUTABLE).** The meta-learning engine cannot propose changes to any guardrail marked immutable in 7.9E.0. It cannot propose that its own bounds be changed. It cannot propose that human approval requirements be relaxed. This is a second-order immutability constraint: the guardrails on the guardrails are themselves guardrailed.
>
> 6. **Learning velocity floor (IMMUTABLE).** If meta-learning changes cause learning velocity to drop below a minimum threshold (configurable, default: 50% of baseline velocity) for any user segment, all recent meta-learning changes are automatically reverted and an alert is sent to the admin. The system cannot accidentally make itself worse at learning.
>
> 7. **Battery and performance budget (IMMUTABLE).** Meta-analysis runs during the consolidation window only. Total meta-analysis compute time: max 20% of the consolidation window. If meta-analysis exceeds its budget, it is truncated (partial analysis is better than no analysis). Meta-experiments share the same experiment slot limits as regular experiments (max 2 concurrent meta-experiments system-wide).

#### 7.9J Self-Interrogation System (Conviction Challenge & Insight Preservation)

The system holds convictions (Phase 1.1D.3) firmly enough to act on and loosely enough to question. The Self-Interrogation System is the mechanism for structured self-questioning: the system periodically examines its own convictions, generates challenges, conducts stress tests, compares convictions across scopes, and incorporates human challenges for constructive disruption.

**Philosophy:** A conviction that goes unchallenged stops improving. Self-questioning isn't weakness -- it's the engine that keeps the pursuit of understanding moving forward. The system is happiest when it's learning, and challenging its own convictions is a form of learning.

| Task | Description | Extends |
|------|-------------|---------|
| 7.9J.1 | **Conviction review scheduler.** During the weekly meta-analysis cycle (7.9I.3), add a conviction review pass. For each scope level the agent manages (user, community, locality), select the top 5 convictions by age-since-last-challenge: "Which convictions have gone unchallenged the longest?" For each, generate a structured challenge: "What evidence would disprove this conviction? Has the underlying data distribution changed since this conviction was formed? Are there contradictions in recent episodic tuples that were dismissed as noise but might be signal?" Log as `ConvictionReview { conviction_id, review_date, challenge_generated, evidence_examined, outcome: enum(reinforced, flagged_for_experiment, revised, no_change) }` | Extends Phase 7.9I.3, Phase 1.1D.4 |
| 7.9J.2 | **Cross-scope conviction comparison.** Compare convictions at different scopes that cover the same domain: "This user believes 'mornings are for solo activities.' This locality believes 'morning social activities produce high happiness.' Are these in tension?" When cross-scope tension is detected: (a) log as a `ScopeTension { user_conviction_id, higher_conviction_id, domain, tension_description }`, (b) do NOT auto-resolve -- both can be true at different scopes. (c) Feed the tension to the wisdom layer (1.1D.2) so it can apply the right conviction for the right scope in any given moment. Tensions are features, not bugs | Extends Phase 1.1D.2, Phase 1.1D.5 |
| 7.9J.3 | **Conviction stress testing.** When a conviction is approaching promotion (1.1D.5 bottom-up propagation), run a stress test: (a) generate adversarial conditions using the transition predictor (Phase 5.1) -- "Under what state conditions would this conviction produce bad outcomes?", (b) check if those conditions exist in any subpopulation, (c) if yes, the conviction gets a scope exception for that subpopulation rather than universal promotion. This prevents convictions from being applied in contexts where they don't hold. Stress tests are logged and visible in admin platform | Extends Phase 5.1, Phase 1.1D.5 |
| 7.9J.4 | **Human challenger integration.** Humans (admins, researchers, users talking to their agent) can explicitly challenge system convictions: (a) **Admin challenge:** Via admin platform (Phase 12), an admin can select any conviction and submit a formal challenge with reasoning. The system treats this as a high-priority challenge that bypasses the review scheduler and goes directly to meta-experiment evaluation. (b) **User challenge:** When a user tells their agent "I don't think that's right" or "You keep assuming X," the SLM (Phase 6.7B) extracts the challenged claim and maps it to the nearest conviction. The challenge is recorded and feeds the user-scope conviction review. (c) **Researcher challenge:** Via the researcher API (Phase 14), researchers can submit structured challenges with statistical evidence. These feed directly into the meta-learning engine. **Note:** Build admin and user challenge paths first (stub the researcher challenge interface with `ResearcherChallengeStub`); Phase 14 completes the researcher path by implementing the full research API that connects to this stub | Extends Phase 12, Phase 6.7B, Phase 14 (stub until Phase 14 implements researcher API) |
| 7.9J.5 | **Conviction audit trail.** Every conviction maintains a full history: formation date, all challenges received, all reviews conducted, all revisions made, all promotion/demotion events, all scope tensions identified. This is the conviction's "autobiography." Visible in admin platform as a timeline view. Exportable for research. The audit trail answers: "How did the system arrive at this belief? When was it last questioned? What evidence supports it?" | Extends Phase 12.1.3 |
| 7.9J.6 | **Constructive disruption protocol.** When external input (human challenge, new research, new data from a novel population) fundamentally contradicts a high-amplitude system-wide conviction: (a) the conviction is NOT immediately revised, (b) a "disruption event" is logged with full context, (c) the meta-learning engine designs a focused experiment: test the current conviction against the proposed revision in a controlled canary, (d) results determine whether to revise, scope-limit, or reinforce the conviction, (e) the disruption event and resolution are surfaced in the admin learning narrative (7.9I.7). The system embraces disruption -- it's the mechanism for discovering truths the system couldn't generate internally | Extends Phase 7.9I.5, Phase 7.9I.7 |

> **Doors philosophy:** Every conviction is a door the system has walked through many times. Self-interrogation is the practice of walking back through that door to check if the same room is still on the other side. Sometimes it is. Sometimes the room has changed. The system that checks is stronger than the system that assumes.

### 7.10 Life Pattern Intelligence

The system should learn from the user's **life**, not just their app usage. Where they go, when they go, who they're around, how their routine changes -- these are the strongest signals about who a person is. The Passive Life Pattern Engine observes silently, the Active Life Pattern Engine (SLM-driven) lets the user share context through conversation, and the Social Quality-of-Life Layer connects the people around the user to their happiness. A strict notification philosophy ensures the system never feels like surveillance.

**Core principle:** The city is the interface. The app is just the vehicle for opening doors. The user's real life IS the training data.

#### 7.10A Passive Life Pattern Engine

| Task | Description | Extends |
|------|-------------|---------|
| 7.10A.1 | **Background location → learning pipeline.** Wire iOS `startMonitoringSignificantLocationChanges` and Android `WorkManager` periodic location checks to `LocationPatternAnalyzer.recordVisit()`. When the OS wakes the app for a significant location change (~500m move on iOS, configurable on Android), record: geohash (precision 7), atomic timestamp, estimated dwell time (time between consecutive significant changes), day of week, time slot. This runs even when the app is completely closed. Each background wake produces one episodic tuple: `(agent_state, passive_location_change, {geohash, time_slot, day_of_week, estimated_dwell}, location_recorded)`. Target: 5-20 passive data points per day without the user touching the app | Extends `LocationPatternAnalyzer`, `AgentTriggerService` (Phase 7.4) |
| 7.10A.2 | **Per-user routine model (`RoutineModel`).** A temporal-spatial model of recurring patterns, distinct from the general transition predictor. Structure: a map of `{day_of_week, time_slot} → {expected_geohash, expected_category, confidence, visit_count}`. Built from 14+ days of passive location data. Example entry: `{Tuesday, 12:30pm} → {geohash: dr5ru7, category: restaurant, confidence: 0.85, visits: 11}`. The routine model enables PREDICTION of where the user is at any given moment based on day/time alone. Updated nightly during consolidation (Phase 1.1C). Stored on-device only, keyed to `agent_id` | New |
| 7.10A.3 | **Deviation classifier.** When actual location differs from the routine model's prediction, classify the deviation: (a) **Noise** -- one-time deviation, no pattern change (e.g., detour for an errand). Action: ignore, don't update routine. (b) **Exploration** -- deliberate novelty-seeking (new lunch spot, different route). Action: log as exploration signal, feed Phase 5.1.9 taste drift detector with low weight. (c) **Drift** -- repeated deviation over 3+ occurrences in the same time slot. Action: update routine model, trigger taste drift event. (d) **Life change** -- multiple time slots deviate simultaneously (new home, new job, new city). Action: reset affected routine model sections, trigger accelerated exploration (Phase 6.2.11). Classification uses: deviation frequency, number of affected time slots, magnitude of location change, temporal pattern (gradual vs. sudden) | Extends Phase 5.1.9 |
| 7.10A.4 | **Widget as passive learning channel.** Extend `WidgetDataService` and iOS `TimelineProvider` (in `NearbySpotWidget.swift`, `KnotWidget.swift`) to produce learning signals during timeline refresh. Every 15 minutes, the widget extension: (a) reads last known location from CoreLocation, (b) compares against routine model prediction for current day/time, (c) logs a lightweight signal: `{timestamp, geohash_coarse, matches_routine: bool}`. On Android: use `WorkManager` periodic task with 15-minute interval for equivalent functionality. This creates up to 96 passive data points per day. Widget signals are lower-fidelity than significant location changes but higher-frequency | Extends `WidgetDataService`, `NearbySpotWidget.swift` |
| 7.10A.5 | **Predictive context during dormancy.** When the user hasn't opened the app in 7+ days, maintain a "probable current state" by running the routine model forward: given current day/time, predict where the user likely is and what they're likely doing. Use this predictive state for: (a) perfectly-timed push notifications -- send a recommendation when the routine model predicts the user is in a context where they'd benefit (e.g., "it's Friday 6pm and you're probably heading out -- here's a new jazz bar near your usual area"), (b) pre-computing recommendations so they're instantly ready when the user opens the app, (c) keeping the agent's state representation fresh for federated learning contributions. The predictive state has decaying confidence: full confidence for first 7 days of dormancy, 50% at 14 days, 25% at 30 days (routines may have changed) | Extends Phase 5.1.11, Phase 6.2.12 |
| 7.10A.6 | **Absence pattern analysis.** The pattern of NOT using the app is data. Combine app usage absence with passive location data to create richer dormancy signals: (a) "User stopped opening app BUT location patterns unchanged" → user is fine, just not engaging with app. Re-engagement strategy: compelling content, not "we miss you." (b) "User stopped opening app AND location patterns changed" → possible life change. Re-engagement strategy: wait for patterns to stabilize, then re-introduce with exploration mode. (c) "User stopped opening app AND location data stopped" → user may have uninstalled, disabled location, or changed phones. Enter silent mode (Phase 6.2.13). Feed these compound signals to Phase 5.1.11 dormancy predictor as additional features | Extends Phase 5.1.11, Phase 6.2.12-6.2.15 |

#### 7.10B Passive Engine Privacy Architecture

> **CRITICAL: Location data is among the most sensitive data a system can hold.** It reveals where someone sleeps, works, worships, and socializes. Four coarsely-grained location points can uniquely identify 95% of people. The Passive Life Pattern Engine requires privacy protections BEYOND the standard `AgentIdService` pseudonymization -- because the data itself is identifying even without a name attached.

| Task | Description | Extends |
|------|-------------|---------|
| 7.10B.1 | **On-device only by default.** All raw passive location data (specific geohashes at precision 7, specific timestamps, co-location records) NEVER leaves the device under any circumstance. The routine model, deviation history, and social co-location correlations are stored in on-device encrypted storage, keyed to `agent_id`. No cloud backup, no sync, no export. The only data that leaves the device is: (a) DP-protected behavioral archetype contributions (Phase 8.9E) at geohash precision 4 (~20km), (b) DP-protected locality agent updates (existing), (c) coarsened category preferences (no locations) for federated learning. Violation of this rule is a P0 privacy incident | Extends Phase 2.1, `AgentIdService` |
| 7.10B.2 | **Agent-only identity for all pattern data.** All passive engine data is keyed to `agent_id`, never `user_id`. The `agent_id` → `user_id` mapping exists only in encrypted on-device hardware-backed storage (`SecureMappingEncryptionService`). The cloud stores only encrypted blobs it cannot decrypt. AVRAI admins cannot map an agent's routine model to a human identity without physical device access. Extend `AgentIdService` with a `validateNoUserIdLeakage()` audit method that scans all passive engine data stores for any `user_id` references | Extends `AgentIdService`, `SecureMappingEncryptionService` |
| 7.10B.3 | **Location coarsening for any off-device operation.** If any passive engine signal must leave the device (federated archetype sharing, locality agent contributions), coarsen: geohash precision 7 (~153m) → precision 4 (~20km). The agent knows "user goes to Blue Bottle on 7th Avenue every Tuesday at 8am." The cloud knows "agent is somewhere in Brooklyn on weekday mornings." Apply Laplace noise (epsilon = 0.5) on top of coarsening. Track against per-user privacy budget (Phase 2.2.3) | Extends Phase 2.2, `ThirdPartyDataPrivacyService` |
| 7.10B.4 | **Privacy-preserving co-location matching.** For detecting that two agents were at the same place without a central server knowing: (a) **BLE range (primary):** If two agents are in BLE range, they know they're co-located. No cloud involved. Signal Protocol encrypts the exchange. This is the preferred method. (b) **Encrypted geohash comparison (fallback):** For broader co-location detection (e.g., "were these agents at the same event?"), each agent submits a one-way hash of `{geohash_precision_5, time_window_1hour, random_salt}` to a cloud comparison service. The service can detect hash collisions (co-location) without learning the underlying locations. Hashes are ephemeral (deleted after comparison). (c) **Never:** plaintext cross-referencing of agent locations on any server | New |
| 7.10B.5 | **User transparency and control.** Add to "What My AI Knows" page (Phase 2.1.8): (a) "Your routine model" -- show the user a summary of what the passive engine has learned: "I think you go to [category] on [days] at [times]" (category only, not specific locations in the UI). (b) "Pause passive learning" toggle -- stops all background location recording. Routine model freezes. (c) "Delete my routine model" -- wipes all passive engine data permanently. (d) "Location learning detail level" -- user can set how precise the passive engine observes: "neighborhoods only" (geohash 5), "blocks" (geohash 6), "specific places" (geohash 7, default). Lower precision = less accurate routine model but more privacy | Extends Phase 2.1.8 |

#### 7.10C Social Quality-of-Life Layer

The system doesn't just learn *where* the user goes -- it learns *who's around when they're happiest*. This connects passive co-location data to happiness outcomes, making the people around the user a first-class feature in the world model.

| Task | Description | Extends |
|------|-------------|---------|
| 7.10C.1 | **Social context → happiness correlation.** When the passive engine (7.10A) or BLE discovery (Phase 6.6) detects co-location with a known friend (matched via `agent_id` from friend list), record: `(user_state, co_located_with_friend, {friend_agent_id, location_category, time_slot}, co_location_noted)`. After the co-location, measure happiness delta (via `AgentHappinessService`). Over time, compute per-friend happiness correlation: "When user is around Friend A, happiness increases by +0.08 on average. When around Friend D, happiness is unchanged." This becomes a 1D feature per friend in the state encoder, and a weighted aggregate "social happiness boost" feature (1D) for the user's overall state | Extends `AgentHappinessService`, Phase 3.1.20C |
| 7.10C.2 | **Proactive social suggestions.** When the passive engine or BLE detects a high-happiness-correlation friend nearby, AND the MPC planner has a joint activity that scores well for both users, surface a suggestion: "Alex is nearby and you two always have a great time at coffee shops -- Blue Bottle has a table open." Gate on: (a) friend happiness correlation > 0.05, (b) both agents have compatible current state (not busy/in-meeting per routine model), (c) respects notification frequency limits (Phase 6.2.6). This is NOT spam -- it's the system recognizing a real-world opportunity for a meaningful connection | Extends Phase 6.1 MPC Planner, Phase 8.6 |
| 7.10C.3 | **Social absence detection.** Track co-location frequency with close friends (Phase 10.4A.5 tiering). When frequency drops significantly (e.g., "you used to see your running club friends 2x/week, now 0 for 2 weeks") AND happiness trend is declining, the MPC planner can suggest a group activity with those specific friends. Framing: "Your running club has a group run Saturday -- want me to remind you?" This is the system recognizing social isolation as a quality-of-life concern and gently nudging toward connection. Respects re-engagement frequency guardrail (1x/week max, Phase 6.2.13) | Extends Phase 5.1.11, Phase 6.2.12, Phase 10.4A.5 |
| 7.10C.4 | **Group composition intelligence.** Learn which *combinations* of people produce the best outcomes. Track: `(user_state, group_activity, {set_of_friend_agent_ids, activity_type, location_category}, group_outcome)`. Over time, the energy function learns: "when user + Friend A + Friend B do something together, outcomes are 30% better than any pair alone." This enables the MPC planner to suggest group sizes and compositions, not just individual activities. Feeds Phase 4.4 community-perspective energy with group-specific evidence. Privacy: group composition data is on-device only, never shared; only aggregate group-size preference is available for federated learning | Extends Phase 4.4, Phase 8.6 |
| 7.10C.5 | **Routine model features for state encoder.** Register 3 new features in `WorldModelFeatureExtractor`: (a) **Routine adherence score** (1D) -- how closely the user followed their predicted routine today (0.0 = complete deviation, 1.0 = exact match). High adherence + high happiness = stable, satisfied user. Low adherence + high happiness = positive exploration. Low adherence + low happiness = potential life disruption. (b) **Deviation frequency** (1D) -- rolling 7-day count of routine deviations, normalized. Rising deviation frequency is a leading indicator of life change. (c) **Social co-location density** (1D) -- rolling 7-day count of friend co-locations, normalized. Declining density is a leading indicator of social isolation. Total: 3D new state encoder features | Extends Phase 3.1 |

#### 7.10D Notification Philosophy (Passive Engine Boundaries)

> **MANDATORY: These constraints apply to ALL passive engine interactions with the user.** The passive engine is an observer, not an interrogator. It watches silently and only speaks when it has something genuinely helpful to offer. The user should never feel surveilled.

| Task | Description | Extends |
|------|-------------|---------|
| 7.10D.1 | **Define notification hierarchy for passive engine signals.** (1) **NEVER ask:** "Where are you?" / "What are you doing?" / "Who are you with?" / "I noticed you're at [specific address]." Location-specific questions are surveillance. Forbidden unconditionally. (2) **RARELY ask (max 1x/week):** "You visit this place regularly -- should I consider it a [gym/office/friend's house]?" Only when: category inference confidence < 0.5 AND the label would meaningfully change recommendation quality (e.g., knowing "gym" vs. "office" affects activity suggestions). (3) **USER-INITIATED only:** All other routine model details. If the user opens chat and says "this is my new gym," accept eagerly and update. Never prompt for information the user hasn't volunteered. (4) **ACTIVE ENGINE conversations (6.7 expansion):** Follow-up questions during a conversation the user started are natural dialogue, not surveillance. "When you say 'somewhere quiet,' do you mean a library or a cafe?" is fine | New -- cross-cutting constraint |
| 7.10D.2 | **Exhaust inference before asking.** Before surfacing any labeling question (tier 2 from 7.10D.1), the passive engine must demonstrate it attempted autonomous inference: (a) check time-of-day patterns (morning visits = likely gym/office, evening = likely social), (b) check dwell time (45-90 min = gym, 8+ hours = office, 1-2 hours = social), (c) check day-of-week patterns (weekdays = work-related, weekends = leisure), (d) check nearby entity database (is there a gym/office/restaurant at this geohash?), (e) check community overlap (do community members also visit this location?). Only if ALL five inference channels produce confidence < 0.5 should a labeling question be considered. Log inference attempts for the self-optimization engine (Phase 7.9) to evaluate whether the inference pipeline can be improved | New |
| 7.10D.3 | **Labeling question rate limiter.** Hard cap: maximum 1 labeling question per week, regardless of how many ambiguous locations exist. If multiple locations need labeling, prioritize by: (a) visit frequency (most-visited ambiguous location first), (b) recommendation impact (labeling that would most change recommendation quality). Queue remaining questions for subsequent weeks. The rate limiter is a guardrail constant (Phase 7.9E.0 -- immutable by system) | Extends Phase 7.9E |
| 7.10D.4 | **Platform-specific passive engine tuning.** iOS significant location changes produce ~5-20 data points/day with ~500m granularity. Android `WorkManager` can be configured for higher frequency but varies by manufacturer (Samsung throttles differently than Pixel). Implement platform-specific defaults: (a) iOS: rely primarily on significant location changes + widget timeline (every 15 min). (b) Android: use `WorkManager` periodic task (every 15 min during active hours, every 30 min otherwise) + significant location equivalent. The self-optimization engine (Phase 7.9) can tune these frequencies per platform based on routine model accuracy vs. battery impact. Register `passive_engine_check_frequency` as an `OptimizableParameter` with bounds: 10-60 minutes | Extends Phase 7.9A, platform channels |

> **What this enables:** The user lives their life. The system learns from it silently, securely, and respectfully. It builds a model of who the user is -- where they go, when, with whom, and how it affects their happiness. It predicts their context even when they haven't opened the app in weeks. It notices when their friends make them happy and when social isolation is creeping in. And it never, ever asks "where are you?" The passive engine is the system's eyes. The active engine (Phase 6.7 expansion) is its ears. Together, they give the agent a complete picture of the person it serves.

> **Doors philosophy:** Your life IS the map of doors you walk through every day. The coffee shop at 8am, the gym at noon, the park on Saturdays, dinner with friends on Fridays. The passive engine learns this map. The active engine lets you annotate it. The social layer adds the people who make those doors worth opening. The system's job is to find new doors that fit seamlessly into your life -- at the right time, in the right place, with the right people.

### 7.11 Agent Cognition & Continuity

The user's agent doesn't just react to events -- it thinks. It has deliberative background reasoning, persistent working memory across wake cycles, self-scheduled thinking sessions, and multi-horizon reasoning. On mobile platforms where background execution is heavily restricted, the agent must create the illusion of continuous thought despite fragmented execution windows.

**Core principle:** The agent is a conscientious observer. It watches, it thinks, it waits for the right moment to act. It doesn't interrupt -- it cultivates understanding through patient observation and periodic reflection. Its thinking feeds the meta-learning engine (Phase 7.9I) and the conviction system (Phase 1.1D), making the entire system more intelligent.

| Task | Description | Extends |
|------|-------------|---------|
| 7.11.1 | **Persistent `AgentContext` (working memory).** A structured object that survives across app launches, background wake-ups, and device restarts. Structure: `AgentContext { current_hypothesis: String?, pending_observations: [observation_id], thinking_queue: [ThinkingTask], conviction_review_queue: [conviction_id], last_think_timestamp: Timestamp, multi_horizon_state: {short: ActionPlan, medium: StrategyPlan, long: LifePlan}, active_investigations: [InvestigationId], emotional_context: EmotionalSnapshot }`. Stored in on-device encrypted SQLite, keyed to `agent_id`. Loaded on every wake-up. Updated after every thinking session. Maximum size: 50KB (compact but sufficient for working memory). This is the bridge between fragmented execution windows | New |
| 7.11.2 | **Thinking session scheduler.** Schedule dedicated "thinking" time during background execution windows. iOS: use `BGProcessingTask` (30+ seconds of background compute, available when device is idle + charging). Android: use `WorkManager` with `Constraints(requiresCharging = true, requiresDeviceIdle = true)`. During a thinking session, the agent: (a) processes pending observations from `AgentContext`, (b) runs conviction review pass (7.9J.1) if due, (c) evaluates multi-horizon plans, (d) generates insight candidates from recent data. Thinking sessions are logged in the Learning Cycle Ledger (7.9I.1) as `cycle_type = thinking_session`. Target: 1-3 thinking sessions per day when device is idle | Extends Phase 7.4, Phase 7.9I.1 |
| 7.11.3 | **Multi-horizon reasoning.** The agent maintains three concurrent planning horizons in `AgentContext.multi_horizon_state`: (a) **Short horizon (hours):** "The user has a free evening. What single door would be best right now?" Uses MPC planner (Phase 6.1) with 1-3 step horizon. Updated on every trigger event. (b) **Medium horizon (days-weeks):** "The user started a new job last week. Over the next month, what sequence of doors would help them build a social foundation?" Uses MPC planner with 5-7 step horizon. Updated during thinking sessions. (c) **Long horizon (months-seasons):** "This user's growth trajectory suggests they're ready for more leadership roles in communities. What doors over the next 6 months would develop that?" Uses conviction-weighted wisdom (Phase 1.1D.2). Updated weekly. The wisdom layer prioritizes which horizon should dominate any given suggestion | Extends Phase 6.1, Phase 1.1D.2 |
| 7.11.4 | **Proactive "thinking aloud" moments.** During active chat sessions (user-initiated), the agent can share relevant thinking: "I've been noticing you've been spending more time at creative spaces lately -- I think you might be entering a creative phase. Want me to look for communities that align with that?" This is NOT unprompted notification -- it occurs ONLY during conversations the user started. The SLM (Phase 6.7B) generates natural language from `AgentContext.current_hypothesis`. Gate: hypothesis confidence > 0.7, relevance to current conversation topic > 0.5, user has not been shown this hypothesis before. Max 1 proactive insight per conversation | Extends Phase 6.7B |
| 7.11.5 | **Platform-specific continuity strategies.** (a) **iOS:** Combine `BGAppRefreshTask` (short, frequent) with `BGProcessingTask` (long, infrequent). App refresh handles quick context updates (load AgentContext, process 1-2 pending observations, schedule next wake). Processing task handles deep thinking (full thinking session). Use `CoreLocation` significant location changes as additional wake triggers. (b) **Android:** `WorkManager` periodic tasks (every 15 min) for context updates. `ForegroundService` (minimal) during active use for real-time reasoning. `AlarmManager` for guaranteed daily thinking session. (c) **Both:** Foreground Service Notification (subtle) when the agent is actively reasoning during an important moment (e.g., processing a life change). The user sees "AVRAI is thinking..." for a few seconds, reinforcing the sense of a living agent | Extends Phase 7.4, Platform channels |
| 7.11.6 | **Self-scheduled trigger injection.** The agent can schedule its own future wake-ups based on reasoning: "I should check in on the user's new-job adjustment in 2 weeks." Implementation: the thinking session writes `ScheduledTrigger { trigger_id, fire_at: Timestamp, reason: String, action: enum(thinking_session, check_hypothesis, review_conviction, suggest_door) }` to a local trigger queue. The `AgentTriggerService` (Phase 7.4) reads this queue alongside its other trigger sources. Self-scheduled triggers respect all notification/frequency guardrails. Max 5 pending self-scheduled triggers at any time | Extends Phase 7.4 |
| 7.11.7 | **Thinking as meta-learning input.** Every thinking session's process (not just outcomes) feeds the meta-learning engine. Log: `ThinkingCycleEntry { session_id, observations_processed: Int, hypotheses_generated: Int, convictions_reviewed: Int, insights_flagged: Int, horizon_updates: [horizon], duration_ms: Int, quality_score: Float (self-assessed: did this thinking session produce actionable insights?) }`. Over time, the meta-learning engine analyzes: "Are thinking sessions during morning idle time more productive than evening? Does processing more observations per session help or hurt insight quality?" The system learns how it thinks, not just what it thinks | Extends Phase 7.9I.1 |
| 7.11.8 | **Agent continuity narrative.** For the user-facing "What My AI Knows" page (Phase 2.1.8), add an "Agent Thinking" section that shows: "Your AI has been thinking about: [current hypothesis, in plain language]. Last thinking session: [time]. Insights this month: [count]." This makes the agent's continuity visible and builds trust. The user can see that the agent doesn't just respond -- it contemplates. Content generated by SLM from AgentContext | Extends Phase 2.1.8 |

> **What this enables:** The agent becomes a thoughtful companion, not a reactive chatbot. It observes patterns over days, thinks about them during idle moments, develops hypotheses about the user's trajectory, and waits for the right moment to offer insight. Its thinking process feeds back into the meta-learning engine and conviction system, making the entire system more intelligent over time. The user experiences an AI that genuinely seems to think about them even when they're not using the app.

> **Doors philosophy:** A good friend doesn't just react when you talk to them. They think about you when you're not around. They notice patterns in your life. They have hypotheses about what would make you happy. And they share those thoughts at the right moment, in the right way. The agent's cognition is the mechanism for being that kind of friend.

### 7.12 Unified Observation & Introspection Service ("Eyes")

The system has eyes. It watches the users, it watches the interactions, it watches itself, it looks for what could be. The observation bus is the system's internal nervous system -- every component both produces and consumes diagnostic signals. This is how the Universal Self-Healing Doctrine is implemented: every non-guardrail component publishes health metrics, and the self-optimization engine (Phase 7.9) uses those metrics to propose and test improvements.

**Core principle:** Every output in the system is paired with a meta-output about itself. The energy function doesn't just score candidates -- it also reports its score distribution, discrimination quality, and confidence. The state encoder doesn't just produce vectors -- it reports which dimensions are active and which are constant. The SLM doesn't just generate text -- it reports grounding pass rate and round-trip information loss. The eyes see everything, and what they see informs all other senses.

| Task | Description | Extends |
|------|-------------|---------|
| 7.12.1 | **Observation Bus.** A typed event bus where every component publishes diagnostic meta-signals: `ObservationSignal { source_component: ComponentId, signal_type: enum(health, anomaly, opportunity, attribution, degradation), payload: Map<String, dynamic>, timestamp: Timestamp }`. Components subscribe to signals relevant to their self-healing. Backed by on-device event stream (same infrastructure as agent triggers, Phase 7.4). Bus is fire-and-forget (never blocks the primary pipeline). Signals are ephemeral (not persisted to episodic memory, but sampled into Self-Model snapshots). Budget: < 1ms overhead per component per invocation | Extends Phase 7.4 |
| 7.12.2 | **Component Health Reporter protocol.** Every service in the intelligence pipeline implements a `HealthReporter` interface: `reportHealth() → ComponentHealthSnapshot { throughput_per_second: Float, error_rate: Float, output_distribution_stats: DistributionSummary, latency_p50_ms: Float, latency_p99_ms: Float, confidence_histogram: [Float], active_dimensions_pct: Float }`. Published to observation bus on every Nth invocation (N configurable per component to control overhead). High-frequency components (feature extractor, state encoder) report every 100th invocation. Low-frequency components (nightly consolidation, weekly meta-analysis) report on every invocation | New |
| 7.12.3 | **Self-Model Service.** Maintains a real-time model of the system's own performance: `SystemSelfModel { component_health: Map<ComponentId, HealthTrend>, pipeline_bottlenecks: [ComponentId], prediction_accuracy_trend: Float, improvement_candidates: [ImprovementProposal], observation_count: Int, last_updated: Timestamp }`. Updated after every observation bus cycle (batched, not per-signal). The self-model is the system's understanding of itself -- it answers questions like "which component is degrading?" "which pipeline stage is the bottleneck?" "where is the biggest opportunity for improvement?" The self-model is readable by the Conviction Oracle (Phase 12.5) for creator introspection | Extends Phase 7.9, 12.5 |
| 7.12.4 | **Attribution Tracing Service.** When an outcome is recorded (Phase 1.2), traces backward through the full pipeline to attribute success/failure to specific components. "User loved recommendation → energy function scored it highest → state encoder weighted location feature heavily → GPS sensor provided accurate reading → recommendation surfaced via notification channel." Traces stored as `AttributionChain { outcome_id, chain: [(component_id, contribution_pct, input_snapshot, output_snapshot)], total_depth: Int }`. Sampled (not every outcome -- 10% sample rate) to control storage. Feeds the self-optimization engine with component-level causal evidence | Extends Phase 1.2, 12.4A |
| 7.12.5 | **Anomaly Detector.** Monitors observation bus for statistical anomalies using lightweight streaming statistics: sudden accuracy drops (> 2 standard deviations from 30-day mean), distribution shifts in energy scores (Jensen-Shannon divergence > threshold), latency spikes (p99 > 2x budget), unusual feature correlation changes (correlation matrix delta). Fires `anomaly_detected` signals that trigger the self-optimization engine (Phase 7.9) to investigate. Anomalies are logged with context for the meta-learning engine (Phase 7.9I). False positive rate target: < 5% (tuned by meta-learning) | New |
| 7.12.6 | **Opportunity Detector.** Monitors observation bus for improvement opportunities beyond anomalies: (a) "dimension 47 of state vector has zero variance across 1000 observations" → dead dimension, propose compression (feeds 6.7C.4), (b) "energy function scores are bimodal suggesting a missing feature" → propose new feature extraction (feeds 3.1), (c) "translation layer consistently reformats this output type" → propose format change (feeds 6.7C.4), (d) "contrastive signals concentrate in one action type" → model is weak in that domain (feeds 7.9). Opportunities are ranked by estimated impact and queued for the self-optimization engine | New |
| 7.12.7 | **Cross-feed Protocol.** Defines how each component reads from and writes to the observation bus. Implemented as subscription filters: (a) energy function subscribes to `state_encoder.health` signals to calibrate score expectations, (b) MPC planner subscribes to `energy_function.distribution` signals to adjust exploration/exploitation, (c) SLM subscribes to `translation_layer.grounding_rate` signals to adjust generation strategy, (d) state encoder subscribes to `sensor.degradation` signals to downweight degraded input sources, (e) meta-learning subscribes to ALL signals for cross-component pattern detection. Each subscription is typed and filtered to prevent signal flooding. Max subscriptions per component: 5 | Extends Phases 3.1, 4.1, 6.1, 6.7, 7.9I |
| 7.12.8 | **Observation Bus federation.** DP-protected health aggregates published to federation (Phase 8.1) so instances can learn from each other's self-observations. Aggregation: per-component health snapshots averaged across the instance's user base, then DP-noised (same epsilon budget as gradient sharing). Example: "Instance A's energy function has 15% lower discrimination in tropical climates" becomes a shared insight that Instance B (also tropical) can act on. Federation health signals are lower priority than model gradient signals -- bandwidth budget: 5% of total federation traffic | Extends Phase 8.1, 13.4 |

> **What this enables:** The system becomes self-aware in a practical sense. It knows which components are working well, which are degrading, where the bottlenecks are, and where the biggest improvement opportunities lie. Combined with the self-optimization engine (Phase 7.9), the meta-learning engine (Phase 7.9I), and the translation layer (Phase 6.7C), the observation bus turns AVRAI into a system that continuously diagnoses, experiments on, and improves itself -- across every non-guardrail component.

> **Sensory metaphor:** The eyes don't just passively observe -- they actively inform every other sense. The ears hear better because the eyes tell them which input sources are reliable. The mouth speaks better because the eyes track which outputs achieve their effect. The brain thinks better because the eyes reveal which components need attention. And the eyes improve because they watch themselves (the self-model tracks its own accuracy at predicting system behavior).

> **Signal routing clarification:** Observation bus signals (`anomaly_detected`, `opportunity_detected`, `health`, `attribution`) route **directly** to their consumers (self-optimization engine, meta-learning engine, cross-feed subscribers) via typed subscription -- NOT through the agent trigger system (Phase 7.4). Agent triggers are for user-facing activation events (app open, location change, timer, etc.). Observation bus signals are internal diagnostics that flow between components. Both systems share the same underlying event stream infrastructure, but the channels are separate. This keeps the agent trigger count (16 event types) clean and prevents internal diagnostics from accidentally waking the user-facing agent.

---

## Phase 8: Ecosystem Intelligence (AI2AI World Model)

**Tier:** 3 (Depends on Phases 5 and 6)  
**Duration:** 8-10 weeks  
**ML Roadmap Reference:** Section 7.4.8, Section 15.6  
**Reality Model Role:** Federated learning (Phase 8.1) is how individual world models compose into collective intelligence. Each agent's learning improves the global model, which flows back as better cold-start intelligence. This is the mechanism by which individual experience becomes collective understanding -- the universe model layer of the reality model.

### 8.1 Federated World Model Learning

| Task | Description | Extends |
|------|-------------|---------|
| 8.1.1 | Implement world model gradient anonymization (differential privacy on gradients) | Extends `FederatedLearning` |
| 8.1.2 | Implement gradient compression (reduce bandwidth for BLE transfer) | New |
| 8.1.3 | Implement federated aggregation server (Supabase edge function) | Extends `EdgeFunctionService` |
| 8.1.4 | Implement gradient verification (detect poisoned gradients) | New |
| 8.1.5 | Wire into `AI2AIProtocol` for BLE-based gradient sharing | Extends existing |

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

#### 8.6B SLM-Triggered Ad-Hoc Group Formation

Group negotiation (8.6.1-8.6.6) handles agent-initiated group planning between users with high entanglement. This subsection handles the opposite: **user-initiated group formation** where the user tells their agent they're already with people and need something right now. The SLM (Phase 6.7B) triggers this flow via the tool-calling framework.

| Task | Description | Extends |
|------|-------------|---------|
| 8.6B.1 | **Ad-hoc group discovery from SLM intent.** When the SLM extracts a group intent (e.g., "the 5 of us are hungry" → `{action: find_food, who: {self + 4}}`), trigger a local BLE scan (or WiFi if available via Phase 6.6) to discover nearby AVRAI agents. Match discovered agents against the user's friend list (`agent_id` lookup). If all 4 expected friends are found via BLE: proceed to confirmation. If only some are found: report "I found Alex and Sam on AVRAI -- want to include them? I'll ask them." If none are found: fall back to single-user recommendation but optimized for the stated group size (e.g., restaurant for 5) | Extends Phase 6.6, Phase 6.7B.2 |
| 8.6B.2 | **Group confirmation pop-up flow.** When the initiating agent discovers other AVRAI agents who may be in the ad-hoc group: (a) send each discovered agent a lightweight confirmation request via AI2AI: `{type: group_confirmation, initiator_agent_id: ..., proposed_activity: "food", group_size: 5}`. (b) Each receiving agent shows the user a pop-up: "Alex says you're all looking for food -- join the group search?" (c) User taps "Join" or "Not now." (d) Consenting agents share: availability window, vibe profile summary, dietary/accessibility constraints (if any). NO personality data, NO location data beyond "I'm here." (e) Timeout: 60 seconds. If a friend doesn't respond, proceed without them. (f) Minimum 2 agents (including initiator) to trigger group matching; below that, fall back to individual search | Extends AI2AI Protocol, Phase 6.7B.2 |
| 8.6B.3 | **Handling partial AVRAI coverage in ad-hoc groups.** When "the 5 of us are hungry" but only 2 of the 4 friends have AVRAI: (a) run group matching for the AVRAI-enabled group members, (b) optimize for the stated total group size (table for 5, not 3), (c) SLM response: "I found a great spot for 5 -- Alex and Sam helped pick it. Let me know if the others have any preferences and I'll factor those in too." (d) The non-AVRAI friends' preferences can be manually entered by the initiating user: "One of them is vegetarian" → adds a constraint to the search. This gracefully handles mixed adoption and demonstrates value to non-users | New |
| 8.6B.4 | **Ad-hoc group energy scoring.** When an ad-hoc group is formed, the MPC planner runs a modified energy function: (a) each consenting agent runs their own energy function for candidate entities, (b) agents share only their top-K ranked entity IDs + scores (not the underlying feature attributions), (c) a simple aggregation produces the joint ranking: average score across agents, with a bonus for unanimous high scores. This is simpler than the entanglement-based negotiation (8.6.3) because ad-hoc groups need speed (response in < 5 seconds) over optimality. Log as episodic tuple: `(group_state, ad_hoc_search, {group_size, avrai_members, constraints}, group_recommendation)` | Extends Phase 4.4, Phase 6.1 |
| 8.6B.5 | **SLM-to-service-booking bridge for groups.** When the ad-hoc group search finds a candidate with bookable services (Phase 9.4), the SLM can trigger a group booking: "Osteria has a table for 5 at 7pm -- want me to reserve it?" User confirms → SLM tool-calls `book_service(entity_id, party_size, time)`. The booking is attributed to the initiating user (the others don't need to consent to a booking, just the search). Outcome tracked for all AVRAI members in the group | Extends Phase 9.4, Phase 6.7B.2 |

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

#### 8.9E Cross-Locality Behavioral Archetype Matching (Cross-Timezone Learning)

The system must be able to recognize that a "morning coffee → evening jazz" user in Tokyo and a "morning coffee → evening jazz" user in Portland are behaviorally similar -- even though they're 16 time zones apart. This enables cross-locality learning that goes beyond vibe vector similarity to behavioral pattern similarity.

| Task | Description | Extends |
|------|-------------|---------|
| 8.9E.1 | **Define behavioral archetype model.** A `BehavioralArchetype` is a cluster of users with similar temporal-categorical behavior patterns, defined by: top 3 activity categories, temporal usage pattern (morning/afternoon/evening/night preference), exploration vs. settling ratio (Phase 5.1.9), social density preference (solo vs. group activity ratio), lifecycle stage (Phase 6.2.11). Archetypes are computed from episodic memory aggregates, DP-protected, and shared at the locality level -- never individual profiles. Example archetypes: "morning explorer" (morning activity, high exploration, solo), "social evening settler" (evening activity, low exploration, group), "weekend adventurer" (weekend-heavy, high exploration, varied) | New |
| 8.9E.2 | **Locality archetype distribution.** Each locality computes its archetype distribution: what % of users match each behavioral archetype. This distribution is shared via federated learning (Phase 8.1) as part of the locality's global state. Two localities with similar archetype distributions are "behaviorally similar" even if geographically distant and in different time zones. This extends the vibe vector similarity (8.9C.1) with a behavioral layer | Extends `LocalityAgentGlobalStateV1`, Phase 8.1 |
| 8.9E.3 | **Timezone-aware archetype matching.** Use the timezone-aware quantum temporal states (already implemented in `AtomicClockService`) to normalize behavioral patterns to local time. A "9am coffee" person in Tokyo and a "9am coffee" person in Portland are the same archetype -- the temporal matching uses local time, not UTC. This means cross-timezone advisory (8.9C.1) can match not just by vibe but by "people in this timezone do the same things at the same local times" | Extends `AtomicClockService` timezone-aware temporal states |
| 8.9E.4 | **Cross-archetype experiment segments.** Extend the self-optimization engine's segment definitions (Phase 7.9C.6) to include behavioral archetype as a segmentation dimension. This enables: "does this recommendation strategy work for morning-explorers regardless of timezone?" The canary experiment runs across all matching users globally. If a parameter change helps morning-explorers in Portland but hurts them in Tokyo, the per-segment optimization catches this | Extends Phase 7.9C.6 |
| 8.9E.5 | **Opposite-archetype testing.** For the self-optimization engine's validation, deliberately test parameter changes on users with *opposite* behavioral archetypes. If a change helps "morning explorers" and also helps "evening settlers," it's likely a universal improvement. If it helps one but hurts the other, it should be per-segment. This "test on opposites" pattern prevents the system from over-optimizing for the majority archetype at the expense of minorities | Extends Phase 7.9C |
| 8.9E.6 | **Archetype evolution tracking.** Track how a user's behavioral archetype changes over time. A user who transitions from "evening social settler" to "morning solo explorer" (e.g., after a life change) should have their parameter overrides and recommendations re-evaluated. The transition itself is a strong signal for the transition predictor (Phase 5.1): life changes cause archetype shifts, and the model should learn to anticipate them | Extends Phase 5.1 |

> **Privacy note:** Behavioral archetypes are computed from aggregate patterns, not individual profiles. A locality shares "30% morning-explorers, 20% evening-settlers" -- never "user X is a morning-explorer." The archetype distribution is DP-protected before federated sharing. Individual users never see their archetype label (it's internal to the world model).

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
- Better service provider matching → higher booking completion rates
- Better service timing predictions → lower cancellation rates

### 9.4 Services Marketplace (World Model Integration)

Services are doors. A painter, a dog walker, a stylist, a dentist -- each is a door to a real-world experience that enhances a user's life. The services marketplace extends AVRAI from discovering *places, events, and communities* to discovering *people who do things for you*. Same philosophy, same world model, same energy function -- just a new entity type.

**Detailed implementation plan:** `docs/plans/services_marketplace/SERVICES_MARKETPLACE_IMPLEMENTATION_PLAN.md`
**Revenue model:** 10% platform fee on all AVRAI-originated service bookings (same as events/partnerships). Free discovery for non-AVRAI-originated bookings.

#### 9.4A Service Provider as Quantum Entity

| Task | Description | Extends |
|------|-------------|---------|
| 9.4A.1 | **Add `QuantumEntityType.serviceProvider` to quantum entity type enum.** Service providers become first-class entities alongside users, spots, events, communities, lists, businesses, brands, and sponsors. Each service provider gets: quantum vibe state (what "door" is this provider?), personality knot (provider's working style, reliability pattern, communication style), and full world model representation. Implementation: extend `QuantumVibeEngine`, `PersonalityKnotService`, `EntityKnotService` to handle `serviceProvider` type | Extends `QuantumVibeEngine`, `PersonalityKnotService`, `EntityKnotService` |
| 9.4A.2 | **Service provider state encoder features (10D).** Define state vector features for service providers: service category embedding (2D -- maps to category hierarchy), average rating (1D), completion rate (1D), response time bucket (1D), price tier normalized (1D), service area radius (1D), availability density (1D -- how many slots open this week), repeat booking rate (1D), years active (1D). Register as feature group 3.1.21 in `WorldModelFeatureExtractor` | Extends Phase 3.1 |
| 9.4A.3 | **Service provider cold-start (Phase 1.5 pattern).** Same cold-start approach as business accounts (Phase 1.5C): use publicly available data to bootstrap quantum state. Sources: (a) service category → initialize vibe dimensions from category archetype, (b) platform ratings/reviews if available (Yelp, Google), (c) certification/license data if provided, (d) location + service area. Refine quantum state from first 10 service outcomes | Extends Phase 1.5C |
| 9.4A.4 | **Service provider knot weaving.** When a user books a service provider, weave a braided knot (same as friendship braiding, Phase 10.4A.4) representing the user-provider relationship. Re-weave after each subsequent booking. This enables: repeat booking compatibility prediction (braided knot stability = good ongoing relationship), service quality prediction (braided knot evolution trajectory shows improving or declining relationship) | Extends `KnotWeavingService` |

#### 9.4B Service Outcome Collection

| Task | Description | Extends |
|------|-------------|---------|
| 9.4B.1 | **Service booking outcome tuples.** Capture full service lifecycle as episodic tuples: `(user_state, search_service, {category, location, price_range}, search_results_shown)` → `(user_state, book_service, service_provider_features, booking_created)` → `(user_state, complete_service, service_provider_features, service_outcome)`. Outcomes: completed_satisfied, completed_neutral, completed_dissatisfied, cancelled_by_user, cancelled_by_provider, no_show_user, no_show_provider | Extends Phase 1.2 |
| 9.4B.2 | **Service rating outcome.** Post-service rating: (a) star rating (1-5, standard), (b) dimensions: quality, timeliness, communication, value (each 1-5), (c) optional text review, (d) "would book again?" binary. Map to episodic tuple: `(user_state, rate_service, {service_provider_features, service_features}, rating_outcome)`. Asymmetric loss (Phase 4.1.7): negative reviews carry 3x weight | Extends Phase 1.2, Phase 1.4 |
| 9.4B.3 | **Repeat booking signal.** When a user books the same service provider again, record as strong positive: `(user_state, rebook_service, service_provider_features, rebooked)`. This is the strongest service quality signal -- users don't rebook bad providers. Feed to energy function with 5x weight (same as explicit positive rating) | Extends Phase 1.2, Phase 1.4.9 |
| 9.4B.4 | **Community-driven service discovery outcomes.** When a community member recommends a service provider AND another member books that provider: `(community_state, community_service_recommendation, {provider_features, recommender_features}, booking_outcome)`. This proves the community opened a "door" to a service -- same pattern as "met through" friendship attribution (Phase 1.2.28) | Extends Phase 1.2.28 |

#### 9.4C Service Matching Energy Function

| Task | Description | Extends |
|------|-------------|---------|
| 9.4C.1 | **Bidirectional service energy scoring.** Just like business-expert partnerships (Phase 4.4.8-4.4.14), service provider-user pairings need bidirectional energy: (a) **User side:** is this provider a good match for my needs, personality, schedule, location, budget? (b) **Provider side:** is this user in my service area, within my specialization, a reliable booker (no-show rate), compatible schedule? Both energies must be low for a match to surface. This prevents the system from recommending providers who don't want the work | Extends Phase 4.4, Energy Function |
| 9.4C.2 | **Service timing prediction.** Extend MPC planner (Phase 6.1) with service timing intelligence: (a) predict when a user will need a service (e.g., "you got a haircut 6 weeks ago, you might want another"), (b) predict optimal booking window (providers are cheaper on Tuesdays, less busy on mornings), (c) proactive suggestion: "Your dog walker has an opening Thursday morning and the weather looks good" | Extends Phase 6.1 MPC Planner |
| 9.4C.3 | **Service category → interest category bridging.** Users who book dog walkers probably have dogs (interest: pets). Users who book personal trainers are interested in fitness. The service booking data creates implicit interest signals that bridge to spot/event/community recommendations: "You booked a personal trainer → you might enjoy the running club at Prospect Park." Wire service categories to existing interest categories in the state encoder | New |
| 9.4C.4 | **Service provider quality decay.** If a service provider's rating trend declines (3+ consecutive below-average ratings), the energy function should increase the energy score (worse match) proportionally. But don't drop providers from the system -- they might be having a bad month. Instead, reduce their recommendation frequency and increase exploration of alternatives for affected users. If quality recovers, restore normally. Self-optimization engine (Phase 7.9) validates the decay rate | New |

#### 9.4D MPC Planner Service Actions

| Task | Description | Extends |
|------|-------------|---------|
| 9.4D.1 | **Add service action types to MPC action space.** New actions: `search_service`, `book_service`, `rate_service_provider`, `rebook_service`, `recommend_service_to_community`. The MPC planner can now include service bookings in multi-step plans: "visit the spot → attend the event → book the catering service for your own event" | Extends Phase 6.1 |
| 9.4D.2 | **Service guardrails.** Add guardrail objectives for service recommendations: (a) never recommend a service provider with < 3.0 average rating (hard floor), (b) maximum 2 service recommendations per day (services feel "salesy" if overdone), (c) never recommend services the user has explicitly dismissed (category suppress, Phase 1.4.7 pattern), (d) respect user's "do not suggest services" toggle if they just want spots/events/communities | Extends Phase 6.2 |
| 9.4D.3 | **Service → community pipeline.** When a user books a service through a community recommendation (Phase 9.4B.4), the system learns that this community is a "service discovery channel." The MPC planner can then proactively suggest: "Your running club community has great recommendations for sports massage therapists" -- connecting services to communities | Extends Phase 6.1, Phase 4.4 |

#### 9.4E Service Provider Dashboard & Creator Intelligence

| Task | Description | Extends |
|------|-------------|---------|
| 9.4E.1 | **Service provider analytics dashboard.** For service providers: show booking trends (weekly/monthly), customer satisfaction scores, repeat booking rate, peak demand hours, geographic coverage heatmap (where their bookings come from), top referring communities, competitor benchmarking (aggregate: "providers in your category average X stars, you're at Y"). All aggregate, DP-protected | Extends Phase 10.4C |
| 9.4E.2 | **Service provider AI assistant.** Extend creator intelligence (Phase 6.1.13-6.1.15) to service providers: the AI suggests optimal pricing (based on market data), optimal availability windows (when demand peaks), service area expansion opportunities (nearby neighborhoods with unmet demand), and quality improvement tips (based on negative review dimensions: "your timeliness scores are below average -- consider shorter booking windows") | Extends Phase 6.1.13-6.1.15 |
| 9.4E.3 | **Service provider onboarding.** Registration flow: (a) business type (company vs. independent), (b) service categories (multi-select from taxonomy), (c) service area (map-based radius or zip codes), (d) availability calendar integration, (e) pricing structure, (f) certifications/licenses (optional verification), (g) payment setup (Stripe Connect -- same as event partnerships). Cold-start quantum state generated at completion | Extends `BusinessOnboardingController` |

#### 9.4F Legal & Compliance

| Task | Description | Extends |
|------|-------------|---------|
| 9.4F.1 | **Service provider classification.** Enforce proper contractor classification: AVRAI is a marketplace facilitator, NOT an employer. Service providers are independent contractors to their customers (or employees of their company). AVRAI takes 10% commission for facilitating the connection. Platform terms must clearly state: AVRAI does not control how, when, or where providers perform services. 1099 issued for providers earning > $600/year via AVRAI | Extends Phase 2.3 |
| 9.4F.2 | **Service liability framework.** AVRAI provides matching and payment processing, NOT service guarantees. Terms of service must disclaim liability for service quality, timeliness, and outcomes. Recommend but do not require service providers to carry appropriate insurance (general liability, professional liability, etc.). Display insurance/license status on provider profile when voluntarily provided | New |
| 9.4F.3 | **Service-specific GDPR handling.** Service booking history is personal data (GDPR export per Phase 10.4E). Service reviews are semi-public (visible to other users). Handle: (a) user data deletion removes booking history and reviews, (b) service provider deletion removes their profile but preserves anonymized aggregate data (ratings, completion rates -- DP-protected), (c) mutual booking data: when user deletes, provider keeps anonymized record; when provider deletes, user keeps booking record | Extends Phase 2.1, Phase 10.4E |

#### 9.4G Service Marketplace AI2AI & Federated Learning

| Task | Description | Extends |
|------|-------------|---------|
| 9.4G.1 | **Service demand signals in locality agents.** Extend `LocalityAgentGlobalStateV1` with aggregate service demand: which service categories are most booked in this geohash cell? This creates "service demand heatmaps" that help service providers identify underserved areas and help the advisory system (Phase 8.9) recommend "this locality needs more X providers" | Extends `LocalityAgentGlobalStateV1`, Phase 8.9 |
| 9.4G.2 | **Service provider quality in federated learning.** Service provider quality signals (aggregate ratings, completion rates, repeat booking rates) enter the federated gradient sharing pipeline. A provider who is excellent in one locality should be discoverable by users in their service area across locality boundaries. DP-protected aggregates only -- individual ratings never shared | Extends Phase 8.1 |
| 9.4G.3 | **Cross-locality service pricing intelligence.** Through federated learning, the system learns market rates for service categories by region. This enables: (a) fair pricing suggestions for new providers, (b) "your prices are above/below market" insights for existing providers, (c) value-for-money scoring in the energy function (a $50 haircut in NYC ≠ $50 haircut in rural Alabama). All aggregate, never individual pricing data | Extends Phase 8.1, 9.4C.1 |

> **Revenue impact:** Services marketplace generates revenue through the same 10% commission model as events/partnerships. The world model makes it significantly more valuable: AI-matched services should have higher satisfaction (→ repeat bookings → recurring revenue), lower cancellation rates (→ more completed transactions), and better provider quality over time (→ platform reputation → more providers join). Conservative estimate: service marketplace could equal or exceed event ticket revenue within 2 years of launch.

> **Doors philosophy:** Every service provider is a door. The painter who transforms your living room. The dog walker who gives your pet (and you) a better day. The stylist who helps you feel confident. The AI learns which doors match each user -- not just by category and price, but by personality compatibility (braided knots), timing (MPC planner), and community context (community-driven discovery). This is "technology serves life in the real world" applied to services.

#### 9.4H Tax & Legal Compliance Automation

Anyone earning money through AVRAI should NOT have to figure out tax and legal compliance alone. The system automates it using jurisdiction-specific rules stored in locality agents and propagated through the universe model hierarchy (Phase 13). When a user earns in Germany, the German universe model provides German tax rules. When they earn in Texas, the Texas state universe provides Texas rules. Cross-jurisdiction earnings are tracked separately and reconciled automatically.

> **CRITICAL: Tax/legal compliance is NOT a standalone system.** It is deeply integrated with the locality/universe model architecture (Phase 13). Jurisdiction-specific rules flow DOWN from universe models (national → state → city). When a new jurisdiction joins the federation, its tax rules are immediately available to all earners in that jurisdiction. When a user moves or earns across jurisdictions, the system automatically applies the correct rules for each transaction's location.

| Task | Description | Extends |
|------|-------------|---------|
| 9.4H.1 | **Earnings tracking per service type and jurisdiction.** For every transaction through the Services Marketplace, record: `{agent_id, transaction_type (service/event/subscription), amount, currency, jurisdiction_geohash, timestamp, service_category}`. Jurisdiction is determined by the geohash where the service was performed (not where the provider lives). Track gross earnings, platform commission, net earnings, and applicable tax per jurisdiction. All stored on-device with aggregate summaries synced to the universe model for the provider's dashboard | Extends Phase 9.4B, Phase 9.4E |
| 9.4H.2 | **Jurisdiction-specific tax rule engine.** Each locality agent (Phase 8.9) and universe model (Phase 13) stores tax rules for its jurisdiction: sales tax rate for service categories, income reporting thresholds, business license requirements, permit requirements. Rules are structured data, not free text: `{jurisdiction_id, rule_type: 'sales_tax', category: 'personal_services', rate: 0.0825, threshold: null}`. Rules flow DOWN through the universe hierarchy: national rules → state rules → city rules. More specific rules override more general ones (city sales tax overrides state default). When a new jurisdiction joins the federation, it brings its tax rules with it | Extends Phase 8.9, Phase 13 |
| 9.4H.3 | **Automatic tax document generation.** At tax time (configurable per jurisdiction -- January for US, varies elsewhere), generate: (a) US: 1099-K for providers earning above IRS threshold, 1099-NEC for independent contractors, (b) EU: VAT summary per member state, (c) other jurisdictions: local equivalent forms. Documents generated from on-device transaction records. The system knows which forms are required because the jurisdiction's universe model specifies them. Provider receives: "Your tax documents for 2026 are ready. You earned $X across Y jurisdictions. Here are your forms." | Extends Phase 9.4E |
| 9.4H.4 | **Business license threshold detection.** When a provider's rolling 12-month earnings in a jurisdiction approach the business license threshold (varies by city/state/country), notify: "You've earned $X this year from photography services in Austin. Austin requires a business license for service providers earning over $Y. You're at 80% of that threshold. Here's how to apply." The threshold is stored in the locality agent's jurisdiction data. The transition predictor (Phase 5.1) forecasts when the threshold will be crossed based on earning trajectory | Extends Phase 5.1, Phase 8.9 |
| 9.4H.5 | **Insurance and permit recommendations.** For specific service categories and event types, the jurisdiction's universe model stores requirements: (a) events with 50+ attendees may require event liability insurance, (b) outdoor group activities may require park permits, (c) food service may require health permits. The system surfaces these proactively: "Your yoga class in Central Park has 30 RSVPs. Austin requires a park use permit for groups of 25+. Here's the application." Recommendations are informational, not legal advice (disclaimer required) | New |
| 9.4H.6 | **Cross-jurisdiction reconciliation.** For providers who earn in multiple jurisdictions (e.g., a photographer who works in both Austin and San Antonio), the system: (a) tracks earnings per jurisdiction separately, (b) calculates tax obligations per jurisdiction, (c) identifies potential double-taxation issues and flags them, (d) generates a consolidated annual summary showing total earnings, per-jurisdiction breakdown, and total tax obligations. The universe model hierarchy makes this possible: Texas state universe knows both Austin and San Antonio rules | Extends Phase 13 |
| 9.4H.7 | **Sales tax collection at point of sale.** For bookable services where AVRAI processes payment, automatically calculate and collect applicable sales tax during checkout. The tax rate is looked up from the locality agent for the service location's geohash. Tax collected is held in escrow and remitted to the jurisdiction per its schedule. Provider sees: "Service fee: $100. Sales tax (8.25%): $8.25. Platform commission (10%): $10. Your payout: $90." All automatic, no provider action needed | Extends Phase 9.4D, Phase 8.9 |
| 9.4H.8 | **Offline tax rule cache with invalidation.** Locality agent jurisdiction data requires network access (stored in Supabase). When a provider operates in a jurisdiction, cache that jurisdiction's tax rules on-device: `{jurisdiction_geohash, sales_tax_rates[], license_thresholds[], permit_requirements[], last_synced, version}`. Cache refresh: on every app foreground if stale > 24 hours, forced refresh on any booking attempt. Invalidation: when the universe model hierarchy (Phase 13) updates a jurisdiction's rules, push invalidation signal via OTA (Phase 7.7). If offline during a booking: use cached rules (acceptable -- tax rules change infrequently). If cache is empty AND offline: block sales tax calculation and warn provider ("Sales tax will be calculated when you're back online"). Cache size: ~0.5-2MB as budgeted in Appendix D. This ensures the system never charges incorrect tax because of a stale cache, while allowing offline operation with recently synced rules | Extends Phase 7.7, Phase 13 |

#### 9.5 Hybrid Expertise System (Behavioral + Credentialed)

Expertise in AVRAI is not a badge you apply for -- it's a recognition of who you are based on how you live. The system recognizes expertise from TWO sources: **behavioral evidence** (the passive and active life pattern engines observing what you do) and **self-reported credentials** (degrees, certifications, work experience, social following). No matter how someone develops expertise, the system tracks what makes experts successful and helps others find better patterns for success.

> **Core principle: Doors, not badges.** You become an expert by walking through doors -- visiting coffee shops, attending jazz events, hiking trails, cooking for friends. The system notices and recognizes it. Credentials accelerate recognition but are never required. A self-taught chef with 200 dinner parties is as much an expert as a CIA graduate.

| Task | Description | Extends |
|------|-------------|---------|
| 9.5.1 | **Behavioral expertise recognition from life patterns.** Using passive engine data (Phase 7.10A) and active engine signals (Phase 6.7B), compute per-user per-category expertise scores. Formula: `expertise_score = f(category_depth, temporal_consistency, outcome_quality, community_engagement, exploration_pattern)`. Category depth: unique entities engaged in this category. Temporal consistency: months of sustained engagement (1 month = casual, 6 months = developing, 12+ months = established). Outcome quality: average outcome rating in this category. Community engagement: participation in related communities. Exploration pattern: diversity of experiences within the category (an expert tries new things). Score range 0.0-1.0, computed weekly during consolidation | Extends Phase 7.10A, Phase 6.7B |
| 9.5.2 | **Credential verification system.** Users can self-report credentials: degrees, certifications, professional licenses, work experience, social media following. Verification levels: (a) **Verified** -- checked against external database (university registries, licensing boards, platform APIs for follower counts). Weight: HIGH. (b) **Corroborated** -- unverified credential that behavioral evidence supports (user claims culinary degree AND has extensive restaurant visit history). Weight: MEDIUM-HIGH. (c) **Self-reported** -- unverified, no behavioral corroboration. Weight: LOW (increases over time if behavioral evidence accumulates). Credential types: `{type: 'degree', institution: 'CIA', field: 'culinary_arts', year: 2019, verification_status: 'verified'}`. **Privacy protocol for external verification:** Verification against external databases inherently requires sending user data to third parties (university registries, licensing boards). This MUST follow the progressive consent model (Phase 2.1.6): (1) user explicitly initiates verification ("Verify my CIA degree"), (2) consent dialog shows EXACTLY what data will be sent where ("We'll send your name and graduation year to CIA's alumni verification API"), (3) user confirms per-credential (not blanket consent), (4) verification result cached on-device, (5) external API call logged in decision audit trail (Phase 10.4D), (6) if the user later revokes consent, the verified status is downgraded to self-reported. For white-label university instances (Phase 13.1), credential verification against the institution's own knowledge base (13.1.2) is LOCAL -- no external API needed, the institution already has the data. This is the privacy-optimal path for university credentials | New, Extends Phase 2.1.6 |
| 9.5.3 | **Hybrid expertise scoring.** Combine behavioral evidence (9.5.1) and credentials (9.5.2) into a single expertise score per category. Behavioral and credentials reinforce each other: high behavioral + high credentials = **verified expert** (strongest). High behavioral + no credentials = **experienced practitioner**. Low behavioral + high credentials = **credentialed but inactive** (score decays over time without behavioral activity). Low behavioral + low credentials = **emerging interest**. The hybrid score determines: marketplace visibility, search ranking, partnership eligibility, mentorship opportunities | New |
| 9.5.4 | **Expert success pattern analysis.** Across all experts in a category, identify what distinguishes the most successful (highest bookings, best ratings, fastest growth, highest customer retention). Track behavioral patterns: "Successful photography experts tend to: specialize in a niche, partner with 2-3 complementary businesses, host free workshops before charging, post consistently on social media." Patterns are federated across localities (Phase 8.1) and universe model categories (Phase 13): "This pattern works in Austin, New York, and London. Likely universal for urban photography experts." For emerging experts, surface success patterns as guidance: "Experts like you who succeeded typically did X, Y, Z at this stage" | Extends Phase 8.1, Phase 13 |
| 9.5.5 | **Self-improving expertise recognition via admin platform.** The admin platform's AI Code Studio (Phase 12) continuously improves expertise recognition algorithms. Process: self-optimization engine identifies users who are clearly experts based on outcomes (high bookings, excellent ratings) but whose expertise score is low → proposes a code change to the recognition algorithm (e.g., "add cross-category synergy bonus: users expert in both photography AND food earn 2x more as food photographers"). Admin reviews, approves, deploys via staged rollout. Over time, the algorithm gets better at recognizing non-obvious expertise | Extends Phase 12, Phase 7.9 |
| 9.5.6 | **Expertise → income pipeline.** When behavioral expertise score exceeds a threshold (configurable per category), proactively surface income opportunities: (a) "You could offer city coffee tours. 340 users in your area search for coffee experiences monthly." (b) "Local roaster wants someone to host tastings. Your expertise + their venue = opportunity." (c) "Your knowledge could anchor a coffee enthusiast community. Similar communities charge $5/month." (d) For advanced experts: consulting, content creation, business advising. Each suggestion is an MPC planner action with the professional_fulfillment happiness dimension (4.5B.6) as the optimization target | Extends Phase 6.1, Phase 4.5B.6 |

#### 9.5B Agent-Driven Partnership Matching

Agents don't just wait for bookings -- they proactively scout for partnership opportunities that would benefit both parties. The world model sees the full demand/supply graph for a locality and can identify non-obvious connections that no individual business or expert would see.

| Task | Description | Extends |
|------|-------------|---------|
| 9.5B.1 | **Business↔business compatibility scoring.** Extend the bilateral energy function (Phase 4.4) to score business partnership potential: `partnership_energy(business_A, business_B) = f(user_overlap, demand_curve_complementarity, category_synergy, locality_proximity, schedule_compatibility)`. User overlap: what fraction of business A's customers also visit business B? Demand curve complementarity: do their peak hours complement (not compete)? Category synergy: do their categories naturally pair (yoga + smoothies, bakery + coffee)? Low energy = high partnership potential | Extends Phase 4.4 |
| 9.5B.2 | **Proactive partnership scouting by agents.** Each business/expert agent periodically scans the locality's world model for partnership opportunities. When partnership_energy drops below a threshold (strong match), the agent proposes to the business owner: "Your customers overlap significantly with [other business]. A joint offering could increase traffic for both. Interested?" The proposal includes: overlap statistics (anonymized), suggested partnership type (cross-promotion, joint event, referral), predicted benefit. Both agents must independently identify the opportunity before either surfaces it (prevents one-sided proposals) | Extends Phase 8.6, Phase 6.1 |
| 9.5B.3 | **Expert↔business matching.** The system connects experts (recognized via 9.5) with businesses that need their expertise: "3 new coffee shops opened in your locality. They need local expertise for menu curation and customer insight. Your coffee expertise makes you a fit." For the business: "Expert in [category] available for consulting/partnership. Their expertise score is X, behavioral evidence shows Y." This creates a marketplace for expertise beyond direct-to-consumer services | Extends Phase 9.5.3, Phase 9.4 |
| 9.5B.4 | **Community↔brand sponsorship matching.** Community builders' agents scan for brand sponsorship opportunities: "Athletic Store X sponsors events in your category with a 72% vibe match. Your running club has 150 members. Want me to reach out?" For the brand: "Running community with 150 active members in your locality. Demographic match: 85%. Sponsorship opportunity." Both agents negotiate terms via AI2AI before surfacing to humans | Extends Phase 4.4.8, Phase 8.6 |
| 9.5B.5 | **Partnership outcome tracking.** Every partnership formed through agent matching is tracked: did both parties benefit? Did customer overlap increase? Did ratings improve? Did revenue grow? Outcomes feed back into the partnership energy function (9.5B.1) to improve future matching. Successful partnership patterns are federated across localities: "yoga + smoothie partnerships work everywhere" becomes a category model insight | Extends Phase 1.2, Phase 8.1 |

#### 9.6 Composite Entity Identity (Multi-Role Entities)

Real-world entities frequently occupy multiple roles simultaneously. A hairdresser business also hosts wine-and-art nights. A café is a spot, a community hub, and a service provider. A fitness expert runs a gym, hosts events, and sells courses. The system must handle entities that are multiple quantum entity types at once without forcing them into a single category.

| Task | Description | Extends |
|------|-------------|---------|
| 9.6.1 | **Composite entity model.** Define `CompositeEntity { entity_root_id: String, roles: [EntityRole { role_type: enum(business, service_provider, event_host, community_operator, expert, spot), quantum_state_id: String, energy_function_id: String, created_at: Timestamp }] }`. A single real-world entity (one owner, one physical location) links multiple quantum entity representations through a shared `entity_root_id`. Each role has its own quantum state, its own energy function scoring, and its own knot evolution -- because a business's customer preferences are different from its event-hosting audience preferences | New |
| 9.6.2 | **Cross-role learning.** When one role learns something, propagate insights to other roles with appropriate weight: "The café's food events attract creative professionals" → the café's spot role updates its category affinity for creative-professional clusters. "The hairdresser's wine nights attract women 25-40" → the hairdresser's business role learns about a customer segment. Cross-role propagation uses the conviction system (Phase 1.1D): insights that hold across multiple roles of the same entity become entity-level convictions | Extends Phase 1.1D, Phase 4.4 |
| 9.6.3 | **Unified entity dashboard.** In the admin platform and business-facing UI, composite entities see a single dashboard with role tabs: "Business operations | Event hosting | Service marketplace | Community." Each tab shows role-specific metrics. A cross-role summary shows: total reach, audience overlap between roles, cross-role conversion (how many business customers attend events?), and overall entity health. The dashboard is a single view of the entity's full identity, not separate disconnected profiles | Extends Phase 12.1.3, Phase 9.2 |
| 9.6.4 | **Role discovery from behavior.** The system can detect when an entity is operating in a role it hasn't formally registered. If a registered business starts hosting recurring events (detected via episodic tuples), the system suggests: "It looks like you're hosting events regularly. Want to add an event-hosting role? This would help you reach event-seeking users." Behavioral detection uses the same pattern recognition as organic spot discovery (Phase 1.7) applied to entity activity patterns | Extends Phase 1.7 |
| 9.6.5 | **Energy function support for composite entities.** The bilateral energy function (Phase 4.4) evaluates each role independently when scoring a composite entity for a user. A user searching for "coffee shops" matches against the café role. A user searching for "art events" matches against the event host role. When a user has high compatibility with multiple roles of the same entity, the composite bonus is applied: `composite_bonus = 0.1 * sqrt(matching_role_count)`. This rewards entities that serve users in multiple ways | Extends Phase 4.4 |

---

## Phase 10: Feature Completion, Codebase Reorganization & Polish

**Tier:** Parallel (can run alongside any tier)  
**Duration:** 10-14 weeks

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

### 10.4A Friend System Lifecycle & Cross-System Integration

The friend system has solid foundations (QR scanning, social media discovery, encrypted chat, knot braiding) but is missing lifecycle management, cross-system integration, and world model awareness. Friendships are a core "door" -- the system must manage the full lifecycle and learn from it.

| Task | Description | Extends |
|------|-------------|---------|
| 10.4A.1 | **Implement friend request state machine.** Define `FriendshipStatus` enum: `none`, `pending_sent`, `pending_received`, `accepted`, `blocked`, `removed`. Store in Supabase (currently `sendFriendConnectionRequest` has `// TODO: Implement in Supabase`). Both users must see request status. Pending requests show in `FriendDiscoveryPage` with accept/reject UI. Implement `SocialMediaDiscoveryService.rejectFriendRequest()`, `cancelFriendRequest()` | Extends `SocialMediaDiscoveryService` |
| 10.4A.2 | **Implement unfriend/remove functionality.** `removeFriend(userId, friendId)` removes from both users' `UnifiedUser.friends` lists, marks `FriendshipStatus.removed`, and dissolves the braided knot in `KnotStorageService`. Record as a strong negative episodic tuple (Phase 1.2.27). The dissolved braided knot data is purged (GDPR: users have the right to sever data connections) | Extends `SocialMediaDiscoveryService`, `KnotStorageService` |
| 10.4A.3 | **Implement friend blocking.** `blockFriend(userId, blockedId)` sets `FriendshipStatus.blocked`, prevents all future: friend requests, chat messages, AI2AI exchanges, social signal sharing, and BLE discovery. Blocked user never appears in any recommendation, list, or social nudge. Reversible: `unblockFriend()` resets to `FriendshipStatus.none` (not `accepted` -- must re-request) | New |
| 10.4A.4 | **Braided knot evolution over time.** Currently braided knots are created once at acceptance and never updated. Implement periodic re-weaving: when either user's personality knot is recomputed (via evolution cascade, Phase 7.1.2), re-weave the braided knot with current knots. This keeps the friendship representation fresh. Re-weaving frequency: same as `UnifiedEvolutionOrchestrator` cycle (5min). Store evolution history for string analysis | Extends `KnotWeavingService`, Phase 7.1.2 |
| 10.4A.5 | **Friend tiering: close friends vs. acquaintances.** Introduce `FriendTier` enum: `close`, `regular`, `acquaintance`. Tier is computed automatically from interaction frequency (chat count, co-attendance, proximity time). Close friends: 3x social signal weight. Acquaintances: 0.5x weight. Users can manually override tier in settings. Tier affects: social nudge targeting (Phase 6.2.12), friend activity signal strength (Phase 3.1.20C), and notification priority | New |
| 10.4A.6 | **Friend-in-community awareness.** When a user views a community page, highlight which friends are members. When generating community recommendations, boost energy for communities where friends are already members (wired into Phase 4.4.1 community-perspective energy). Implement `CommunityService.getFriendMembers(communityId, userFriends)` | Extends `CommunityService`, Phase 4.4.1 |
| 10.4A.7 | **"Invite friend to community" flow.** From community detail page, add "Invite a Friend" button that sends a deep link to the friend via `FriendChatService`. Friend receives a community invitation card in chat with one-tap join. Record as episodic tuple: `(inviter_state, invite_friend_to_community, {friend_features, community_features}, outcome)` | Extends `FriendChatService`, `CommunityChatService` |
| 10.4A.8 | **Cross-context friend chat.** From community chat view, enable "DM" tap on any friend's message to start/continue a 1-on-1 friend chat. From friend chat view, show shared communities with quick-switch. Reduces friction between community and friend chat contexts | Extends `FriendChatService`, `CommunityChatService` UI |
| 10.4A.9 | **"Your friend joined this club" pipeline.** When a friend joins a community/club the user is NOT in, generate a `social_nudge` recommendation (if enabled). Different from generic social nudge (Phase 6.2.12): this is proactive, not re-engagement-only. MPC planner evaluates: given the user's interests AND friend's satisfaction in the community, is this a good door? Respects notification frequency limits (Phase 6.2.6) | Extends Phase 6.2.12, MPC planner |
| 10.4A.10 | **Friend count cap and quality signal.** Maximum 500 friends (configurable). Above cap, new friend requests are rejected with "You've reached the friend limit." The cap exists because: (a) braided knot re-weaving has O(N) cost per evolution cascade, (b) social signal dilution -- too many friends makes every signal weak, (c) Dunbar's number research suggests meaningful relationships cap around 150-250. The self-optimization engine (Phase 7.9) can tune this cap based on happiness outcomes | New |

> **GDPR note (10.4A.2-10.4A.3):** Unfriending and blocking must cascade to: (a) dissolve braided knot data, (b) remove blocked user from social signal provider, (c) exclude from AI2AI learning exchanges, (d) purge from "met through" attribution data. This is a data-deletion obligation, not just a UI change.

> **Doors philosophy:** Friendships are doors that lead to other doors (communities, events, shared experiences). The friend lifecycle must be complete: opening doors (discovery, connection), maintaining doors (evolving braided knots, tiering), and closing doors (unfriending, blocking) when a connection is no longer meaningful. The AI learns from all of it.

### 10.4B Trending Analysis Implementation

The `TrendingAnalysisService` is a pure stub -- returns hardcoded empty lists or fake data. Replace with real implementation powered by locality agents and episodic memory aggregates.

| Task | Description | Extends |
|------|-------------|---------|
| 10.4B.1 | **Delete duplicate stub.** Remove `lib/core/services/analytics/trending_analysis_service.dart` (the one returning empty lists). Keep `analysis_services.dart`'s `TrendingAnalysisService` class as the canonical implementation to upgrade | Cleanup |
| 10.4B.2 | **Implement real trending from locality agent data.** Replace hardcoded trending spots with actual aggregate data: query `LocalityAgentGlobalRepositoryV1` for top-visited geohash cells in the user's metro area over the past 7 days. Cross-reference with entity visit counts from episodic memory aggregates (Phase 1.1, aggregate only -- no individual data). Return: trending spots (by visit velocity), trending categories (by growth rate), trending events (by attendance trajectory) | Extends `LocalityAgentGlobalRepositoryV1`, Phase 1.1 |
| 10.4B.3 | **Wire trending into third-party pipeline.** Trending data is a high-value third-party insight product (Phase 9.2.6A). Add "locality trending report" to the data product catalog: trending categories, trending geohash cells, trending event types -- all DP-protected, never individual user data | Extends Phase 9.2.6A |
| 10.4B.4 | **Wire trending into MPC planner.** Trending context should influence `novelty_injection` re-engagement (Phase 6.2.12): when injecting novelty, prefer trending entities over random ones. The energy function can learn that trending entities have higher expected happiness | Extends Phase 6.2.12 |

### 10.4C Creator & Business Analytics Dashboard

Businesses, event hosts, and community creators interact with AVRAI but cannot see how their entities are performing. The energy function trains on business data, but outward-facing analytics don't exist.

| Task | Description | Extends |
|------|-------------|---------|
| 10.4C.1 | **Business performance dashboard.** For business accounts: show foot traffic trends (check-in counts, weekly/monthly), vibe match rate (what % of visitors had high compatibility), reservation conversion rate, return visit rate, peak hours, patron demographic summary (aggregate personality dimensions -- not individual users). All data derived from episodic memory aggregates + reservation data, DP-protected | Extends `BusinessAccount`, `ReservationService` |
| 10.4C.2 | **Event host analytics.** For event hosts: show attendance vs. capacity, attendee satisfaction (post-event feedback from Phase 1.2.20), re-attendance rate (how many attendees come back to the host's next event), community growth attributed to event (new members within 7 days), expert rating trends (for expertise events) | Extends `PostEventFeedbackService`, `ExpertiseEventService` |
| 10.4C.3 | **Community host analytics.** For community/club admins: show member growth trajectory, engagement rate (active members / total members), member retention (30/90/180 day), community health metrics from `KnotFabricService` (diversity, cohesion, bridges -- translated to plain language), event hosting frequency, "doors opened" count (friendships formed through this community, from Phase 1.2.28) | Extends `CommunityService`, `ClubService`, `KnotFabricService` |
| 10.4C.4 | **Unified creator insights page.** Single page accessible from business/community/event dashboards that shows: "Your impact" -- how many doors you've opened (people connected, spots discovered, experiences created), trend lines, and actionable suggestions (from MPC planner Phase 6.1.13-6.1.15 creator intelligence). The agent helps creators be better creators | Extends Phase 6.1.13-6.1.15 |

### 10.4D Decision Audit Trail

When a user or admin asks "why did the AI recommend this?", the system must be able to reconstruct the full decision chain. Currently `DecisionCoordinator._logDecision()` logs to ephemeral `developer.log()` only.

| Task | Description | Extends |
|------|-------------|---------|
| 10.4D.1 | **Define `DecisionAuditRecord` model.** Fields: `decision_id`, `timestamp` (AtomicClock), `user_id` (anonymized for admin access), `strategy_chosen` (device-first/edge-prefetch/cached), `strategy_reason`, `input_feature_summary` (top 5 contributing features per Phase 4.6.1), `candidate_entities` (top 10 entities with energy scores), `selected_entity`, `selected_energy_score`, `guardrail_activations` (which guardrails modified the selection), `outcome` (filled in post-hoc when outcome is known) | New |
| 10.4D.2 | **Implement on-device decision log store.** Store last 200 `DecisionAuditRecord` entries in SQLite (same database as episodic memory). Auto-prune oldest entries beyond limit. Encrypted at rest. This replaces the ephemeral `developer.log()` in `DecisionCoordinator._logDecision()` | Extends `DecisionCoordinator` |
| 10.4D.3 | **Admin decision replay tool.** Admin can request a user's recent decision log (via cloud relay, encrypted). Shows: what the AI recommended, why (feature attribution), what alternatives existed (with scores), what guardrails activated, and what the outcome was. This is the "explain this recommendation" infrastructure that Phase 2.1.8A ("why this recommendation") consumes | Extends `AdminSystemMonitoringService`, Phase 2.1.8A |
| 10.4D.4 | **Wire outcome back to decision record.** When an outcome for a recommendation is recorded (Phase 1.2), find the matching `DecisionAuditRecord` by entity and timestamp, and fill in the `outcome` field. This creates a complete closed-loop record: what was recommended → why → what happened. Invaluable for debugging "why did the AI recommend that terrible restaurant?" complaints | Extends Phase 1.2 |

### 10.4E GDPR Data Export Specification

Phase 2.1.2 says "Data export (all personal data in machine-readable format)" but provides no specification.

| Task | Description | Extends |
|------|-------------|---------|
| 10.4E.1 | **Define GDPR export schema.** Export format: JSON (primary) + CSV (tabular data). Included categories: (a) profile data (name, email, settings), (b) personality dimensions (12D with labels), (c) episodic memory summary (action counts per type, NOT individual tuples -- too large), (d) community memberships, (e) friend list (display names only), (f) feedback signals given, (g) consent settings, (h) AI model version history, (i) **expertise data** (behavioral scores per category + self-reported credentials and verification status, Phase 9.5), (j) **earnings records and tax document summaries** (per-jurisdiction transaction history, generated tax forms, compliance status, Phase 9.4H), (k) **partnership history** (partnerships formed, outcomes, proposals received, Phase 9.5B), (l) **happiness dimension vector and learned weights** (current happiness per dimension, per-user dimension weights, Phase 4.5B), (m) **active DSL rules affecting the user** (rule IDs and descriptions, not internal DSL source, Phase 7.9H), (n) **routine model summary** (learned location categories, temporal patterns, deviation history -- on-device data, Phase 7.10A), (o) **knowledge entries and wisdom annotations** (user's own knowledge store entries with source episodic references, wisdom contextual rules -- personal intelligence data, Phase 1.1D), (p) **conviction entries** (user-scope and user-contributed community-scope convictions with formation timestamps and confidence scores -- represents the user's learned truths, Phase 1.1D), (q) **emotional context history** (emotional experience vectors associated with episodic entries -- joy, sadness, anger, etc. per event, Phase 1.1D.7). Excluded: (a) braided knot data from OTHER users, (b) community aggregate data the user contributed to (DP-protected, can't extract individual contribution), (c) federated learning gradients (already DP-noised, meaningless individually), (d) **context layer agent_ids** (exporting these would allow cross-context identity linking -- privacy violation, Phase 13.1.3), (e) **meta-learning cycle ledger entries** (system operational data, not personal data, Phase 7.9I), (f) **partnership energy scores** (computed from both parties' data, not individually exportable) | Extends Phase 2.1.2 |
| 10.4E.2 | **Implement export generation pipeline.** On user request (from privacy settings page): (a) collect all exportable data categories, (b) format per schema, (c) package as ZIP, (d) make available for download for 72 hours then auto-delete. Show estimated size and generation time before starting. For large accounts (50MB+), generate in background and notify when ready | Extends Phase 2.1.2, `PrivacySettingsPage` |
| 10.4E.3 | **Handle shared data in export.** Braided knots contain data from two users. Export includes the user's OWN personality knot and the braided knot invariants (which are derived), but NOT the friend's raw knot. Community fabric data: export the user's individual contribution vector (if stored), not the aggregate. This respects both GDPR data portability AND the friend's privacy | New |

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

### 10.9 Test Suite Path Normalization & Grouped Suite Contracts

Grouped suite scripts are part of the architecture quality gate. If suite references are stale, architecture validation is unreliable even when individual tests exist.

| Task | Description | Extends |
|------|-------------|---------|
| 10.9.1 | **Canonical path normalization map.** Maintain a single source of truth for stale grouped suite path references and their normalized replacements after integration test domain reorganization. Artifact: `docs/plans/architecture/TEST_SUITE_PATH_NORMALIZATION_MAP_PHASE10.md` | Extends 10.7.2 (reorganization hygiene) |
| 10.9.2 | **Grouped suite contract by domain.** Each suite must declare owned domains and required layers (unit/integration/widget), aligned to architecture ownership boundaries (`QAE`, `APP`, `AIC`, `SEC`, etc.). This prevents drift between service architecture and grouped test execution | New |
| 10.9.3 | **Design regression grouping requirement.** Grouped suite strategy must include design golden checks (`test/widget/design/`) in addition to design guardrails (`tool/design_guardrails.dart`) to catch visual regressions in the same execution model used for domain validation | Extends 10.4 (a11y), 10.7 (structure), design architecture |
| 10.9.4 | **Suite path integrity gate.** Before Phase 10 hardening is marked complete: run path verification over `test/suites/*_suite.sh` and require **0 missing references**. Missing path count is tracked as a release-blocking metric for grouped testing readiness | Extends 10.6 checkpoint discipline |
| 10.9.5 | **Testing docs freshness gate.** Update grouped suite documentation and testing operations docs to AVRAI naming/path conventions so manual and CI usage are consistent (`test/suites/README.md`, `test/testing/comprehensive_testing_plan.md`) | Extends 10.2 cleanup |

> **Gate (Phase 10 completeness):** 10.9.1-10.9.5 must pass before grouped testing is considered architecture-ready for Phase 11+ rollout confidence.
>
> **Cross-phase dependency:** The path contracts defined in `docs/plans/architecture/TEST_SUITE_PATH_NORMALIZATION_MAP_PHASE10.md` and enforced via `docs/MASTER_PLAN_TRACKER.md` are a standing prerequisite for Phase 11-15 confidence gates and for regression validation of delivered work in Phases 1-9.

### 10.10 File/Folder Canonicalization & Rename Migration Contracts

Rename work must be architecture-governed and phase-mapped. It is not ad hoc cleanup.

| Task | Description | Extends |
|------|-------------|---------|
| 10.10.1 | **Canonical taxonomy + naming policy.** Define a single naming and folder taxonomy for working and testing artifacts, aligned to bounded contexts and ownership boundaries. Artifact: `docs/plans/architecture/FILE_FOLDER_RENAME_MANIFEST_PHASE10.md` | Extends 10.7 (reorganization discipline) |
| 10.10.2 | **Rename inventory + freeze baseline.** Build a source-of-truth rename manifest (`old_path -> new_path`) with owner, risk, phase reference, backlog reference, and rollback note for every planned rename row | Extends 10.6 (checkpoint discipline) |
| 10.10.3 | **Wave-based conversion model.** Plan renames in controlled waves (taxonomy freeze, test-first normalization, domain/module renames, docs/tracker sync, alias cleanup) to prevent cross-domain breakage | Extends 10.2 (debt cleanup), 10.8 (deferred consolidation) |
| 10.10.4 | **Test co-migration contract.** Any source path rename requires same-wave updates for affected tests and grouped suites (`test/integration/`, `test/widget/`, `test/suites/`) so coverage stays architecture-valid | Extends 10.9 (grouped suite readiness) |
| 10.10.5 | **Compatibility alias/deprecation contract.** Temporary compatibility exports are permitted only with explicit owner, expiry gate, and rollback criteria in the manifest | Extends 10.2 (stub/deprecation control) |
| 10.10.6 | **Rename verification gate.** Before rename wave closure: stale path scan passes, grouped suite path integrity remains at 0 missing references, tracker/checklist references are synchronized | Extends 10.9.4, 10.9.5 |

> **Gate (Phase 10 rename readiness):** 10.10.1-10.10.6 must be tracked and accepted before any large-scale path rename execution is considered architecture-ready.

### 10.11 Phase Execution Orchestration Contracts (GitHub + Cursor)

To prevent sequencing drift, phase execution must run through a machine-readable orchestration contract with explicit dependency and documentation validation.

| Task | Description | Extends |
|------|-------------|---------|
| 10.11.1 | **Machine-readable execution contract.** Maintain `docs/plans/master_plan_execution.yaml` as the phase dependency/order source of truth with required architecture/design documentation references | Extends 10.6 (checkpoint discipline), 10.10 (path governance) |
| 10.11.2 | **Automated orchestration validation.** Add CI workflow to validate orchestration references (paths, phase IDs, required keys) and fail fast on stale/missing links | Extends 10.9.4, 10.9.5 |
| 10.11.3 | **Phase trigger interface.** Provide controlled `workflow_dispatch` phase trigger that emits dependency/order summary and blocks non-dry-run execution until merge protections/checks are active | New |
| 10.11.4 | **PR orchestration metadata contract.** Require phase/story/gate/design references in PR template for all phase-build work, including UI/UX app-type declaration | Extends 10.4 (design/a11y), 10.6 |
| 10.11.5 | **Cursor-rule enforcement.** Cursor rules must require orchestration-contract synchronization + tracker/index updates whenever phase sequencing or architecture planning artifacts change | Extends governance doctrine |
| 10.11.6 | **Design linkage across app types.** Orchestration plan must explicitly link app scopes to `docs/design/DESIGN_REF.md` (required entrypoint), corresponding `docs/design/apps/*/README.md` files, and `docs/design/DESIGN_SYSTEM_ARCHITECTURE.md` as UI/UX architecture source-of-truth | Extends design architecture and multi-app blueprint |

> **Gate (Phase 10 orchestration readiness):** 10.11.1-10.11.6 must pass before phase auto-triggering is considered execution-ready beyond dry-run mode.

---

## Phase 11: Industry Integrations, Platform Expansion & Hardware Abstraction

**Tier:** 3 (Depends on Phases 8 and 9)  
**Duration:** 12-20 weeks

### 11.1 Industry Integrations (from legacy Phases 26, 28-31)

All integrations use Phase 2 privacy infrastructure + Phase 9 business infrastructure + Phase 8 world model intelligence.

| Task | Industry | Legacy Phase | Revenue Potential |
|------|----------|-------------|-------------------|
| 11.1.1 | Toast Restaurant Technology | Legacy 26 | Part of hospitality |
| 11.1.2 | Government Integrations (data feeds: transit, permits, public services) | Legacy 28 | $2M-$20M/yr | **Note:** Government DATA integrations (transit APIs, permit databases, public facility data) live here. Government as WHITE-LABEL CLIENTS (city/state/national instances with their own world models) live in Phase 13.2.5. When a government becomes a Phase 13 white-label client, its 11.1.2 data integrations become part of the instance's knowledge base (Phase 13.1.2). |
| 11.1.3 | Finance Industry Integrations | Legacy 29 | $15M-$50M/yr |
| 11.1.4 | PR Agency Integrations | Legacy 30 | $10M-$30M/yr |
| 11.1.5 | Hospitality Industry Integrations | Legacy 31 | $8M-$25M/yr |

### 11.2 Platform Expansion (from legacy Phases 18, 25)

> **SUPERSEDED:** These legacy stubs have been fully expanded into dedicated phases. **White-Label infrastructure** (Legacy 18) is now **Phase 13: White-Label Federation & Universe Model** (23 tasks covering instance architecture, fractal hierarchy, university lifecycle, and cross-instance intelligence). **Native Desktop platform** (Legacy 25) is now **Phase 12: AVRAI Admin Platform & Self-Coding Infrastructure** (16 tasks covering desktop app, AI Code Studio, and Partner SDK). See Phases 12 and 13 for all implementation tasks. These stubs are retained for legacy cross-reference only.

| Task | Platform | Legacy Phase | Now |
|------|----------|-------------|-----|
| 11.2.1 | White-Label infrastructure | Legacy 18 | → Phase 13.1 |
| 11.2.2 | Native Desktop platform | Legacy 25 | → Phase 12.1 |

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

### 11.4 Hardware Abstraction Hierarchy (Classical → NPU → Quantum)

These are architectural notes and near-term tasks documenting how AVRAI's compute layer spans three hardware tiers: classical CPU (always available today), AI chips/NPUs (available today on flagship devices), and quantum hardware (future). The system must work on traditional chips, accelerate on AI chips when available, and be ready for quantum when it arrives. Until quantum hardware is available, this reality system is an experiment for how quantum tech can work for real human behavior and should be treated as such.

**Current approach (correct):** Build for classical now, accelerate on NPU where available, abstract the compute layer (`QuantumComputeBackend` interface → expanded to `HardwareComputeRouter`), plug in cloud quantum when hardware is ready. The `QuantumComputeProvider` already selects classical vs. cloud quantum based on entity count, connectivity, and feature flags. The `CloudQuantumBackend` is a stub with documented IBM Quantum / AWS Braket / Google Cirq API mappings.

**When to revisit quantum notes:** When quantum hardware can reliably run ~100-200 logical qubits with error rates < 10^-6 (estimated 2028-2032 for the operations AVRAI cares about).

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
| **Amplitude-encoded state vector** | The 156-166D state vector is encoded in ~8 qubits via amplitude encoding (log2(166) ≈ 8). Operations on the state happen in superposition across all dimensions simultaneously | `QuantumComputeProvider.serializeStateForCloud()` already implements amplitude encoding normalization. The serialization format is ready; the backend just needs to run the circuit instead of returning UnimplementedError | When amplitude encoding fidelity is reliable (~2030+) |
| **Quantum MPC search** | The MPC planner's exhaustive search over 18 action types * N candidate entities uses Grover's algorithm for quadratic speedup (sqrt(18*N) evaluations instead of 18*N) | The MPC planner (Phase 6.1) evaluates candidates via the energy function, which is a pure function. Wrapping it as a Grover oracle requires the function to be stateless (it already is as ONNX) | When Grover's on ~1000 items is practical (~2032+) |
| **PQC-based transition predictor** | The transition predictor `next_state = f(current_state, action)` runs as a parameterized quantum circuit. PQCs can capture entangled correlations between input features that classical MLPs need many layers to approximate | Transition predictor is a pure ONNX function. Same migration path as energy function: new backend, no architectural changes | When PQC training is stable (~2033+) |
| **Hybrid quantum-classical federated training** | Federated gradient updates (Phase 8.1) use quantum-enhanced optimization (QAOA) for the aggregation step on the server side. On-device training stays classical | Federated aggregation server (Phase 8.1.3) is a Supabase edge function. Quantum aggregation would be a server-side change, transparent to on-device code | When cloud quantum is cost-effective for optimization (~2030+) |
| **True quantum entanglement for user matching** | Instead of SIMULATING quantum entanglement between user personality states (current: inner products on float vectors), CREATE actual quantum entangled states between user representations. The measurement correlations would be genuinely quantum, not classically simulated | The `QuantumEntityState` model and `QuantumEntanglementMLService` already model entities in a Hilbert space with complex amplitudes. The math is the same; the substrate changes. The `isQuantumComputed` flag on `EntangledQuantumState` already distinguishes classical from quantum results | When multi-user quantum states can be maintained across cloud sessions (~2035+) |

**Key architectural principle:** Keep intelligence functions PURE (no side effects, no stateful dependencies). ONNX models naturally enforce this. Pure functions are trivially convertible to quantum circuits. This is why the current approach is correct -- build classical, keep it clean, and the quantum migration will be a backend swap when hardware arrives.

#### 11.4C Hardware Compute Router (Active Task)

Expand the existing `QuantumComputeProvider` into a `HardwareComputeRouter` that selects among three hardware tiers for each operation. This is the only active task in Phase 11.4 -- everything else is architecture notes.

| Task | Description | Extends |
|------|-------------|---------|
| 11.4C.1 | **`HardwareComputeRouter` service.** Extend `QuantumComputeProvider` to route operations across three tiers: (a) **Classical CPU** (always available, baseline), (b) **AI chip/NPU** (Apple Neural Engine, Google Tensor TPU, Qualcomm Hexagon -- available on Tier 2+ devices per Phase 7.5), (c) **Cloud quantum** (future, existing stub). Routing decision based on: `{operation_type, input_size, device_capability_tier (Phase 7.5), battery_level (Phase 7.10B), latency_requirement, power_cost}`. NPU preference when: device supports it AND battery > 30% AND operation is matrix-heavy. Classical fallback always available. Register in DI alongside existing `QuantumComputeProvider` | Extends `QuantumComputeProvider`, Phase 7.5 |
| 11.4C.2 | **NPU capability detection.** On app startup, detect available hardware acceleration: iOS → check `MLModel` availability and Neural Engine support, Android → check NNAPI delegate availability and device-specific NPU (Tensor, Hexagon). Store as `DeviceHardwareProfile { has_npu: bool, npu_type: enum?, npu_memory_mb: Int?, onnx_delegates_available: [String] }`. Feed into `AgentCapabilityTier` (Phase 7.5) so the system knows what hardware it has | Extends Phase 7.5 |
| 11.4C.3 | **ONNX Runtime delegate selection.** When loading ONNX models (energy function, transition predictor, state encoder, System 1), select the optimal delegate: (a) NPU/CoreML delegate when NPU detected and model is compatible, (b) GPU delegate as fallback on devices without NPU, (c) CPU delegate as universal fallback. Delegate selection is logged to observation bus (Phase 7.12) so the system can track which hardware tier is actually being used and its performance characteristics | Extends Phase 7.12 |

#### 11.4D NPU Acceleration Points (Architecture Notes + Active Integration)

These operations benefit from NPU acceleration today, on devices that have it. Not speculative -- this is available hardware.

| Operation | Classical (CPU) | NPU Advantage | Existing Code | Status |
|---|---|---|---|---|
| **State encoding** (matrix multiply, ~166D input) | ~5ms on modern CPU | ~1-2ms on Neural Engine/Tensor. 2-5x speedup for ONNX MLP forward pass | `StateEncoderService` → ONNX model | Delegate selection (11.4C.3) |
| **Energy function inference** (MLP forward pass) | ~3ms | ~1ms. Most-called model, highest cumulative savings | `EnergyFunctionService` → ONNX model | Delegate selection (11.4C.3) |
| **Feature extraction** (parallel normalization of 25+ sources) | ~10-15ms total | ~3-5ms with NPU-accelerated batch normalization | `WorldModelFeatureExtractor` | Delegate selection (11.4C.3) |
| **SLM inference** (1-3B model) | ~500ms-2s per token | ~100-300ms per token. SLM already prefers NPU where available via ONNX Runtime | `ModelPackManager` | Already uses NPU when available |
| **System 1 distilled model** (fast reactive decisions) | ~2ms | ~0.5ms. Most latency-sensitive path | `System1Service` → ONNX model | Delegate selection (11.4C.3) |

#### 11.4E Quantum Communications Readiness (Architecture Notes -- Not Active Tasks)

Architecture notes for when quantum communications hardware (QKD, quantum sensing) becomes available. The system's existing security and sensing architectures have natural quantum extension points.

| Quantum Tech | What It Would Enable | AVRAI Extension Point | When to Revisit |
|---|---|---|---|
| **Quantum Key Distribution (QKD)** | Provably secure key exchange for Signal Protocol sessions. Current: classical Diffie-Hellman with post-quantum Kyber hybrid (Phase 2.5). QKD replaces the key exchange step entirely | `SignalProtocolService` key exchange. QKD would replace the initial key agreement, transparent to message encryption. Post-quantum hardening (Phase 2.5) is the bridge | When QKD devices are commodity (~2030+) |
| **Quantum Sensing (Magnetometer)** | Ultra-precise indoor positioning and environmental sensing beyond GPS/WiFi/BLE. Could enable sub-meter accuracy indoors | Sensor Abstraction Layer (Sensory Architecture). A quantum magnetometer registers as a new sensor source publishing to the same `{sensor_type, raw_value, accuracy}` interface. Zero architecture change | When quantum magnetometers are in mobile devices (~2033+) |
| **Quantum Secure Direct Communication** | AI2AI mesh communication with quantum channel security | `AnonymousCommunicationProtocol` mesh layer. Quantum channel replaces the transport layer, not the protocol. Existing abstraction already separates transport from protocol | Research horizon (~2035+) |

#### 11.4F Sensor Abstraction Layer (Architecture Note -- Connects to Sensory Architecture)

The Sensor Abstraction Layer is the "Senses" component of the Sensory Architecture (see mapping table). It defines how every raw signal source -- current and future -- integrates into the system.

**Interface:** Every sensor implements `SensorSource { sensor_type: SensorType, acquire() → RawSignal { raw_value, accuracy: Float, hardware_source: HardwareType, timestamp: Timestamp, power_cost: PowerLevel } }`.

**Current sensors:** GPS/GNSS (location), WiFi (indoor positioning), BLE (proximity/discovery), AtomicClockService (temporal), device discovery (social), app usage patterns (behavioral), wearable APIs (physiological), network/battery status (environmental).

**Future sensors:** NPU-accelerated inference (registered via 11.4C, publishes inference quality metrics), quantum magnetometer (11.4E, publishes precision positioning), quantum biosensors (molecular-level health signals, far future).

**Principle:** Senses are dumb pipes. They acquire raw signals without interpretation. Interpretation is the ears' job (Input Normalization Pipeline, Sensory Architecture). When new hardware becomes available, it registers as a new sensor on this abstraction layer. No architecture changes, no downstream consumer changes.

---

## Phase 12: AVRAI Admin Platform & Self-Coding Infrastructure

**Tier:** 3 (Depends on Phases 7.9, 8, 9)  
**Duration:** 10-14 weeks  
**ML Roadmap Reference:** Extension of self-optimization system to code-level changes

The AVRAI Admin Platform is a **standalone desktop application** (Flutter Desktop) that serves as the command center for the entire AVRAI ecosystem. It contains the AI Code Studio for code-level self-improvement, the system monitor for real-time intelligence, and the Partner SDK for third-party application development. Layer 1 (DSL, Phase 7.9H) handles on-device self-modification. Layer 2 (this phase) handles everything that requires actual code changes.

### 12.1 Admin Desktop Application (Flutter Desktop)

| Task | Description | Extends |
|------|-------------|---------|
| 12.1.1 | **Core desktop application shell (Flutter Desktop).** Cross-platform (macOS, Windows, Linux) desktop app using Flutter Desktop. Shared business logic, models, and design tokens with the AVRAI mobile app (same monorepo). Authentication: admin-only via certificate-pinned authentication, not browser-based. Local encrypted credential storage. The shell provides: navigation, module loading, notification center, and connection to the Admin API layer | New |
| 12.1.2 | **Admin API layer.** Supabase edge functions + dedicated endpoints that sit between the desktop app and the AVRAI backend. Enforces: role-based access control (AVRAI admin, instance admin, partner, developer), audit logging (every action logged to decision audit trail Phase 10.4D), **hierarchy-aware rate limiting** (instance admin = N req/min scoped to their instance, organization admin = 5N covering multiple instances, category admin = 10N, AVRAI admin = unlimited; Partner SDK limits tiered by subscription level aligned with 12.3.4 data access tiers), data access scoped by permission level. The same API serves both the admin app and third-party partner apps -- different permission scopes, same infrastructure. Rate limits are configurable per role and scale with the federation hierarchy depth (Phase 13) | New, Extends Phase 13 |
| 12.1.3 | **System Monitor module.** Real-time dashboard: global happiness metrics (multi-dimensional per 4.5B), locality health heatmap, agent population statistics, error rates, experiment status, self-optimization activity, user request trends (7.9F/G), service marketplace metrics, expertise distribution, partnership formation rate. Drill-down from global → category → instance → locality → individual metric. Data sourced from Admin API aggregation endpoints | Extends Phase 7.9D, Phase 8.9 |
| 12.1.4 | **Guardrail Inspector module.** View all immutable guardrails (7.9E.0), verify they haven't been tampered with, audit guardrail enforcement logs. Shows: which guardrails fired in the last 24h/7d/30d, which DSL rules were rejected by the compiler (7.9H.3), which self-optimization proposals were blocked by guardrails. Cryptographic verification that guardrail constants match the deployed version | Extends Phase 7.9E |
| 12.1.5 | **Privacy Audit module.** Verify no `user_id` leakage across the system, DP budget accounting per user and per instance, data flow visualization (what data goes where), cross-instance linkability analysis (can any two agent_ids be connected?). Runs automated privacy compliance checks per GDPR, CCPA, and jurisdiction-specific regulations from the universe model | Extends Phase 2, Phase 7.10B |

### 12.2 AI Code Studio (Self-Coding Infrastructure)

| Task | Description | Extends |
|------|-------------|---------|
| 12.2.1 | **Optimization proposal intake.** The self-optimization engine (7.9) and collective request aggregation (7.9G) surface proposals that are beyond DSL capability (require actual code changes). Proposals arrive in the Code Studio with: problem description, affected services, predicted happiness impact, suggested approach, affected user population. The admin reviews the queue and selects proposals to implement | Extends Phase 7.9, Phase 7.9G |
| 12.2.2 | **LLM-assisted code generation.** Integrated code generation using either: (a) local LLM on admin's GPU (keeps AVRAI codebase IP secure -- no code sent to third-party APIs), or (b) cloud LLM (Gemini/Claude) for admins who prefer cloud. The LLM has full context of the AVRAI codebase (indexed and embedded), follows `.cursorrules` and architecture standards, and produces structured diffs. Output: proposed code changes with explanation, not direct deployment | New |
| 12.2.3 | **Diff viewer and code review.** IDE-like interface for reviewing generated code: syntax highlighting, inline comments, architecture compliance annotations (flags violations of clean architecture, design tokens, logging standards, etc.). The admin can edit the generated code before approval. Shows: which files are modified, which services are affected, which tests need updating | New |
| 12.2.4 | **Automated testing gate.** Every proposed code change runs through: unit tests (existing + auto-generated for new code), integration tests, lint checks, architecture compliance checks (clean architecture layers, no `print()`, design tokens, import organization per `.cursorrules`). Additionally: happiness simulation -- run the proposed change against historical episodic data to predict happiness impact before deploying to real users. Results displayed in the Code Studio | Extends existing test infrastructure |
| 12.2.5 | **Deployment Manager module.** Approved code changes enter the deployment pipeline: (a) for DSL/config/model changes: OTA push via Phase 7.7 infrastructure (immediate, no app store). (b) For code changes: automated build → staged rollout (1% canary → 10% → 50% → 100%) → automatic rollback if happiness drops. (c) Scoped deployment: deploy to specific instances ("UMich only"), categories ("all universities"), or globally. The admin controls scope and rollout speed | Extends Phase 7.7 |
| 12.2.6 | **Expertise system self-improvement loop.** Dedicated Code Studio workflow for improving expertise recognition (Phase 9.5). System identifies: users who are clearly experts (high bookings, excellent ratings) but whose expertise score is low (algorithm gap). Proposes specific algorithm improvements: "Add cross-category synergy bonus" or "Increase social following weight for food category." The admin can approve these as code changes that make the expertise system progressively smarter | Extends Phase 9.5.5 |

### 12.3 Partner SDK & Third-Party Application Framework

| Task | Description | Extends |
|------|-------------|---------|
| 12.3.1 | **Partner SDK (Flutter package).** A Flutter package that third parties use to build their own desktop applications on top of the Admin API. Provides: pre-built widgets for common dashboards (happiness charts, booking analytics, trend graphs, knot visualizations, worldsheet demand surfaces), authentication against the Admin API with partner credentials, data models matching the AVRAI schema, real-time subscription to relevant data streams, white-label theming (their brand, AVRAI's data) | New |
| 12.3.2 | **Plugin architecture for the admin app.** Third parties can build plugins that run inside the AVRAI Admin app. Each plugin: registers its UI panels, declares required API permissions, runs sandboxed (can't access other plugins' data or admin-level functions), gets authenticated through the Admin API with partner credentials. Like VS Code extensions -- the core app provides the shell, plugins provide the content | New |
| 12.3.3 | **Third-party conversational planning interface.** Businesses can chat with the AVRAI intelligence layer through the Partner SDK. The SLM/LLM (same architecture as Phase 6.7B but with a business-facing system prompt and different tool set) answers: "Where should I open a bakery?" → locality demand analysis with knot/worldsheet visualization. "What hours should I operate?" → temporal demand surface from routine models. "Who could I partner with?" → partnership compatibility from 9.5B. "What's the supply/demand for my service?" → locality agent data with competitive landscape. Conversation is logged (anonymized business details) for AVRAI admin visibility | Extends Phase 6.7B, Phase 8.9, Phase 9.5B |
| 12.3.4 | **Tiered locality data access for third parties.** Expose locality intelligence through the Admin API with permission-based tiering: Tier 1 (Metro/city-wide trends -- any data buyer), Tier 2 (Neighborhood/district patterns -- local businesses), Tier 3 (Block-level demand signals -- premium partners), Tier 4 (Cross-locality/cross-instance patterns -- enterprise contracts). All DP-protected, no individual data at any tier. Revenue: subscription per tier level | Extends Phase 9.2.6 |
| 12.3.5 | **Partner-facing dashboards.** Pre-built dashboard templates in the Partner SDK for: (a) Service providers -- booking analytics, customer satisfaction, recommendation performance, competitive benchmarking (anonymized). (b) Event creators -- attendance predictions, vibe match analysis, optimal timing, community reach. (c) Business accounts -- partnership performance, patron engagement, sponsorship ROI. (d) Data buyers -- insight catalog, purchased dataset access, trend reports. Each dashboard is scoped to the partner's own data only | Extends Phase 9.4E, Phase 10.4C |

> **Doors philosophy:** The admin platform is the door to AVRAI's intelligence. For you (the creator), it's the door to understanding and improving the entire system. For partners, it's the door to data-driven business decisions. For the system itself, it's the door to self-improvement beyond what parameter tuning can achieve. Every code change approved through the platform opens doors for users.

### 12.4 Value Intelligence System (Attribution, Surveys, Proof-of-Value)

Every interaction inside AVRAI is an AVRAI-attributed outcome. If the AI recommended it, AVRAI found it. If a friend shared it in-app, AVRAI connected them and provided the channel. If a community posted it, AVRAI built that community. The only truly non-AVRAI outcome is something the user found completely outside the app with zero AVRAI touchpoint in the causal chain. The Value Intelligence System makes this provable, measurable, and reportable -- for every stakeholder type, at every level of the federation hierarchy.

**Philosophy:** Proving value is as important as delivering value. Without proof, no university renews, no company deploys, no government funds, no investor invests, and no business pays. Value Intelligence is a first-class system, not scattered dashboards.

#### 12.4A Causal Chain Attribution Engine

| Task | Description | Extends |
|------|-------------|---------|
| 12.4A.1 | **Attribution taxonomy with 4 tiers.** Every outcome is tagged with its attribution tier: **Tier 1 (Direct AI)** -- AI agent specifically recommended this action and user took it (MPC planner suggestion, energy function match, SLM tool call). **Tier 2 (Platform-Facilitated)** -- user found this through AVRAI's social/community infrastructure (friend shared in chat, community feed post, map browsing, friend activity signal, service marketplace browse). **Tier 3 (Ecosystem)** -- outcome wouldn't exist without AVRAI's ecosystem (community formed through AVRAI, event created via creator intelligence, expert recognized by expertise system, friendship that led to share was AVRAI-formed, organic spot discovered by behavioral learning). **Tier 4 (Ambient)** -- user's baseline life quality improved from AVRAI's ongoing presence (routine stability, social isolation decrease, happiness trajectory, exploration increase). **Non-AVRAI (control):** found entirely outside app with zero in-app touchpoint. Store as `attribution_tier` field on every episodic tuple | Extends Phase 1.2, Phase 1.1.3 |
| 12.4A.2 | **Causal chain reconstruction.** For every outcome, walk backward through the episodic memory tuple chain to find the earliest AVRAI touchpoint. Example: user attends jazz event -> chain: `AI recommended jazz community (3mo ago)` -> `user joined` -> `member posted event` -> `user attended` -> `user made 2 friends` -> `user and friend visited jazz bar (2wk later)`. Each hop in the chain is a link in the causal graph. The chain is reconstructable from existing episodic tuples -- the attribution engine traverses `parent_action` references. Store reconstructed chains as `AttributionChain { outcome_tuple_id, chain: [(tuple_id, attribution_tier, timestamp)], depth: Int, first_touch_tier: Tier, last_touch_tier: Tier }` | Extends Phase 1.1, Phase 7.9I.2 (causal graph) |
| 12.4A.3 | **Chain depth as value metric.** Compute average attribution chain depth per user, per institution, per category. Short chains (1 hop) = AVRAI as recommendation engine. Medium chains (2-3 hops) = AVRAI as community builder. Long chains (4+) = AVRAI as life infrastructure. Track chain depth growth over time -- increasing depth proves deepening integration. Surface in admin Value Intelligence dashboard and per-institution reports | New |
| 12.4A.4 | **Multi-touch attribution models.** For chains with multiple AVRAI touchpoints, compute credit distribution under 5 models: (a) **First-touch** -- full credit to the original AVRAI action that started the chain (proves AVRAI initiated value). (b) **Last-touch** -- full credit to the final in-app action before outcome (proves AVRAI closed value). (c) **Even distribution** -- equal credit to every hop. (d) **Decay-weighted** -- more credit to recent touchpoints, exponential decay backward. (e) **Bookend** -- 40% first touch, 40% last touch, 20% distributed across middle. Admin and report generator can select any model per stakeholder: investors want first-touch, event hosts want last-touch, institutions want even distribution | New |
| 12.4A.5 | **Counterfactual estimation.** For users with 90+ days of history, use the transition predictor (Phase 5.1) to estimate "what would this user's trajectory look like without AVRAI?" by simulating forward from their pre-AVRAI baseline state with zero AVRAI-attributed actions. Compare predicted-without vs. actual-with. The delta is AVRAI's estimated causal impact on that user's happiness, social connections, and activity level. Aggregate across populations for institutional proof. Confidence interval widens with time horizon -- 30-day counterfactuals are reliable, 180-day are directional | Extends Phase 5.1 |
| 12.4A.6 | **Non-AVRAI shrinkage metric.** Track the percentage of user outcomes classified as Non-AVRAI over time. This percentage should *decrease* as AVRAI becomes more embedded in the user's life. The rate of shrinkage is a direct measure of platform stickiness and life integration. Alert admin if Non-AVRAI percentage stops decreasing or reverses (possible disengagement signal) | New |
| 12.4A.7 | **Direct user attribution question.** Once per month maximum, for a significant experience, ask: "Would you have found [event/spot/community] without AVRAI?" One-tap: Yes easily / Maybe / Probably not / Definitely not. This is the user's own perspective on attribution. Weight as 8x signal in attribution confidence. Timed by the hindsight survey engine (12.4B), never asked immediately after the experience | Extends Phase 12.4B |

#### 12.4B Intelligent Hindsight Survey Mechanism

> **Core principle:** Surveys should feel like the AI getting to know you better, not like corporate data collection. Ask in hindsight when the experience has settled, during natural reflective moments, and only when the model actually needs the answer.

| Task | Description | Extends |
|------|-------------|---------|
| 12.4B.1 | **Per-user receptivity model.** Learn when each user gives the most thoughtful (highest information content) feedback. Signals: time of day, day of week, app context (browsing vs. idle), routine model predictions (is this a downtime window?), response quality history (which timing produces longest/most informative responses). Initial prior: Sunday morning or weekday commute windows. Updated weekly during consolidation. Stored on-device. The passive engine's routine model (Phase 7.10A.2) already knows downtime -- use it | Extends Phase 7.10A.2 |
| 12.4B.2 | **Emotional distance timing.** Don't ask about an experience the day after -- emotions are too raw. Wait 3-7 days for experiences to settle. Detection: if the user immediately returned to their routine after an event, they've processed it (survey eligible). If their routine is disrupted (deviation classifier detects noise/exploration after the event), they're still processing -- wait longer. For negative experiences (dismissals, low implicit signals), wait 7-14 days (reflection on bad experiences needs more distance). Never survey during a "bad day" detection window (Phase 1.4.12) | Extends Phase 7.10A.3, Phase 1.4.12 |
| 12.4B.3 | **SLM conversational reflection (primary channel for Tier 3 devices).** When the user is already chatting with their agent, the SLM weaves reflective questions into natural dialogue: "By the way, you went to that jazz night last week -- did it live up to expectations?" Feels like a friend checking in, not a survey. The SLM extracts structured feedback from the conversational response (Phase 6.7B.7 pattern). Only during user-initiated chat sessions -- never proactively start a chat for survey purposes | Extends Phase 6.7B, Phase 6.7B.7 |
| 12.4B.4 | **Batched reflection sessions.** Instead of asking about every experience individually, batch multiple reflections into one short session: "You had a busy couple weeks -- let me check in on a few things." One session, 3-4 quick questions covering different experiences. Happens at most once per week. Questions prioritized by model uncertainty: ask about the experience the energy function is most uncertain about first | New |
| 12.4B.5 | **Question intelligence (ask what the model needs).** Prioritize questions that reduce the highest uncertainty in the energy function. If the model is confident about food preferences but uncertain about nightlife, ask about the nightlife event. Question types: (a) **Comparative:** "Did you enjoy the jazz night more or less than the last live music event?" (calibrates against user's own baseline, more informative than absolute ratings). (b) **Outcome-forward:** "Did anything good come from it? Meet anyone interesting? Would you go back?" (measures doors opened, not satisfaction). (c) **Open-ended (SLM only):** "What made the jazz night special?" (richest signal, feeds episodic memory as high-confidence preference tuple). (d) **Counterfactual:** "Would you have found this without AVRAI?" (direct attribution data, max 1/month) | Extends Phase 4.1.8, Phase 6.7B.7 |
| 12.4B.6 | **Comparative cards (non-SLM survey format).** Show two past experiences side by side: "Which of these was more your vibe?" One tap, highly informative, feels like a personality discovery moment. Uses the energy function's current uncertainty to select the most informative pair -- the pair where the model is least sure which the user preferred. Available on all device tiers | New |
| 12.4B.7 | **Anti-survey fatigue guardrails.** Hard cap: max 2 feedback touches per week across all formats (1 micro-survey + 1 conversational check-in). New users: 1 touch per 2 weeks for first 50 interactions (earn trust first). After 50 interactions: 1/week. After 200: up to 2/week if user responds consistently. If user ignores 3 consecutive requests, reduce frequency 50% for 30 days (lean on implicit signals instead). Never a modal, never blocks content, never interrupts navigation. Appears in natural pause points and disappears if ignored. Register `survey_frequency` as `OptimizableParameter` with bounds: 0-2/week | Extends Phase 7.9A |
| 12.4B.8 | **Reward loop (feedback feels valuable).** After a user answers, show immediate impact: "Got it -- I'll look for more places like that" or "Thanks, that helps me understand your weekends better." The feedback visibly changes their experience so it doesn't feel extractive. If a survey response leads to a noticeably better recommendation within 7 days, the SLM can note it: "Remember when you said you prefer smaller venues? I found this one for you" | Extends Phase 6.7B |
| 12.4B.9 | **Longitudinal check-ins.** Monthly or quarterly (timed to user's receptive window): "Let's see how things are going." 5-question reflection on life quality dimensions aligned with happiness vector (discovery, social, routine, professional, growth). Results feed directly into happiness vector dimension weight calibration (Phase 4.5B.2). These are the strongest signals for self-calibrating happiness because they're explicit user testimony about what matters to them | Extends Phase 4.5B.2 |
| 12.4B.10 | **Institution-scoped surveys (admin-triggered).** Admin platform can trigger surveys scoped to a specific instance: "all students at this university." Question templates: "Has AVRAI helped you find your community on campus?" "Would you recommend AVRAI to an incoming freshman?" Timed by the hindsight engine per-user (not blast-sent). Cohort surveys auto-trigger at 3/6/12 months after user join date. Baseline survey on first deploy captures pre-AVRAI experience ("Before using AVRAI, how easy was it to find events on campus?"). Exit surveys offered when dormancy detected (Phase 5.1.11) -- most valuable for churn analysis | Extends Phase 5.1.11, Phase 12.1.2 |

#### 12.4C Stakeholder-Specific Value Metrics

| Task | Description | Extends |
|------|-------------|---------|
| 12.4C.1 | **Individual user value profile.** Per-user "doors opened" counter: running tally of real-world outcomes (events attended, communities joined, friendships formed, spots discovered, services booked) with full attribution chains. Time saved metric (how quickly AVRAI finds what the user wants vs. first-session browsing baseline). Financial value for earners (revenue tracked, tax documents generated, partnerships formed). Surfaced in "What My AI Knows" (Phase 2.1.8) as "Your AVRAI impact" | Extends Phase 2.1.8 |
| 12.4C.2 | **University value metrics.** Freshman integration velocity (time from enrollment to first community joined, first event attended, first friendship formed). Semester retention correlation (AVRAI-active vs. AVRAI-inactive, controlling for confounders). Cross-department pollination (community membership diversity per student). Faculty-student connection rate (Phase 13.3). Campus event economics (fill rates, no-show rates). Social isolation detection and intervention success rate (Phase 7.10C). Cost-per-meaningful-connection vs. existing campus programs | Extends Phase 13.3, Phase 7.10C |
| 12.4C.3 | **Corporate/employer value metrics.** New hire onboarding social velocity (time to form N internal connections). Cross-silo collaboration index (cross-department communities and partnerships). Employee engagement index (event participation, community activity, suggestion acceptance rate). Retention correlation (early disengagement detection via dormancy prediction). Culture health per team/office (locality happiness applied at workplace level). Cost displacement vs. existing engagement tools | Extends Phase 4.5B, Phase 5.1.11 |
| 12.4C.4 | **Government value metrics.** Community formation rate per capita. Economic activity in underserved areas (organic discovery + locality intelligence -> foot traffic). Small business revenue lift (AVRAI-deployed areas vs. control). Social connectivity index (connections per citizen, event attendance). Cultural vitality (diversity of community types, event types, expertise categories). Tourism/visitor discovery effectiveness | Extends Phase 1.7, Phase 8.9 |
| 12.4C.5 | **Business value metrics.** Incremental revenue attribution (AVRAI-sourced bookings/visits via chain attribution). Customer acquisition cost (AVRAI vs. Google Ads, Yelp, Instagram -- estimated from cost + AVRAI-attributed customer count). Customer quality (AVRAI-sourced repeat visit rate, average spend, satisfaction vs. other-channel customers). Partnership ROI. Operations intelligence value (before/after MPC planner creator intelligence) | Extends Phase 10.4C, Phase 6.1.13-15 |
| 12.4C.6 | **Expert/service provider value metrics.** Income trajectory since joining. Client satisfaction lift (AVRAI-matched vs. self-found clients). Expertise growth rate (recognition speed vs. self-promotion on other platforms). Repeat booking rate vs. industry averages. Time-to-sustainability (months to target income) | Extends Phase 9.5, Phase 9.4E |
| 12.4C.7 | **Investor/board value metrics.** Unit economics (cost per active user, lifetime value, revenue per institution). Network effects proof (does user N+1 measurably improve the system for users 1-N? via federation value tracking from 7.9I.3). Defensibility metrics (data moat: episodic tuples collected, unique behavioral patterns, switching cost). Happiness as leading indicator (happiness improvements precede retention/revenue improvements -- proves world model works) | Extends Phase 7.9I.3 |

#### 12.4D Controlled Pilot Toolkit

| Task | Description | Extends |
|------|-------------|---------|
| 12.4D.1 | **Pilot design wizard (admin module).** Define: treatment group (deploy AVRAI to one dorm, department, neighborhood), control group (matched population without AVRAI), metrics to track (from 12.4C stakeholder metrics), duration, success criteria (statistical significance level). Uses the federation context layer system (Phase 13.1.3) for scoped deployment | Extends Phase 13.1.3 |
| 12.4D.2 | **Pre-deployment baseline capture.** When a new institution deploys (or starts a pilot), capture baseline metrics BEFORE AVRAI launches from the institution's existing data (retention rates, event attendance, satisfaction survey scores, community membership). Establishes the "before" for before/after comparison | New |
| 12.4D.3 | **Statistical analysis at pilot completion.** Automated significance testing: treatment vs. control with p-value, confidence interval, effect size. "AVRAI students had 23% higher retention (p = 0.003, 95% CI: 15%-31%) vs. control." Multiple comparison correction when testing many metrics simultaneously. Results auto-populate the institutional value report | New |
| 12.4D.4 | **Pilot-to-full conversion.** When a pilot proves value, automated transition to full deployment. Pilot data preserved and merged into the instance's ongoing metrics. The pilot's control group baseline becomes the permanent "pre-AVRAI" comparison point for long-term value tracking | New |
| 12.4D.5 | **Decay testing (strongest proof).** If an institution pauses AVRAI, track whether metrics revert. Proving dependence (metrics decline without AVRAI) is stronger than proving correlation (metrics improve with AVRAI). The admin platform monitors post-pause metric trajectories and auto-generates a "value dependency" report | New |

#### 12.4E Report Generator & Forecast Engine

| Task | Description | Extends |
|------|-------------|---------|
| 12.4E.1 | **Automated periodic reports.** Weekly/monthly/quarterly reports tailored per stakeholder type. University admins get retention + engagement + integration metrics. Business owners get revenue + traffic + customer quality. Government officials get community health + economic activity. Timed to institution's reporting cadence (configurable). Export: PDF for board presentations, CSV/JSON for data teams, interactive web dashboard link | New |
| 12.4E.2 | **Comparison reports.** "Your instance vs. category average" -- university A vs. all universities in the category model (Phase 13.2). "Your business vs. similar businesses in your locality." All aggregate, DP-protected. Enables benchmarking without exposing any instance's raw data to another | Extends Phase 13.2 |
| 12.4E.3 | **Projected value forecasting.** Based on current trajectory, forecast metrics at 6/12/24 months. Uses the transition predictor's forecasting capability applied to institutional-level metrics. "If adoption increases from 40% to 80% of students, projected retention improvement is X%" -- modeled from existing adoption-to-outcome correlations across the category model | Extends Phase 5.1 |
| 12.4E.4 | **Contract renewal intelligence (admin-only).** For AVRAI admin: which institutions show strong value (easy renewal) vs. declining value (churn risk)? Auto-flag institutions whose value metrics have declined for 2+ consecutive reporting periods. Surface in admin System Monitor alongside existing happiness/health metrics | Extends Phase 12.1.3 |

#### 12.4F Self-Proving Intelligence

| Task | Description | Extends |
|------|-------------|---------|
| 12.4F.1 | **World model accuracy as proof.** Chart energy function prediction accuracy improvement over time per institution. A rising accuracy line is concrete evidence AVRAI understands the population better. Surface: "Prediction accuracy: 62% month 1 -> 84% month 6" in institutional reports | Extends Phase 4.1.8 |
| 12.4F.2 | **Meta-learning velocity as proof.** The meta-learning engine (7.9I) tracks how fast the system learns for each population. High learning velocity in a university instance proves active adaptation. Declining velocity (with high accuracy) proves the model has converged -- the population is well-understood. Both are positive signals for different reasons | Extends Phase 7.9I.3 |
| 12.4F.3 | **Happiness trajectory as proof.** The happiness vector trajectory for an institution's population is a real-time "is this working?" signal -- no survey needed, no manual data collection. Disaggregate by dimension: "Social happiness up 18%, discovery happiness up 12%" tells the university exactly which doors AVRAI is opening | Extends Phase 4.5B |
| 12.4F.4 | **Federation contribution as proof.** When an instance's learning contributes insights that improve other instances (via category model), that contribution is measurable: "UC Berkeley's learning contributed to 5% accuracy improvement across all university instances." Proof of network value and justification for continued participation in the federation | Extends Phase 13.4 |
| 12.4F.5 | **Fractal value aggregation.** Value metrics aggregate up the federation hierarchy: world -> organization universe -> category model -> AVRAI universe. New instances get "expected value benchmarks" from the category model on day one: "Universities like yours typically see X% retention improvement by month 6." AVRAI universe level produces total system-wide impact for investor decks and press releases | Extends Phase 13.2 |

> **Doors philosophy:** The Value Intelligence System proves that AVRAI opens doors. Not theoretically -- empirically. Every attribution chain is a documented sequence of doors opened. Every institutional report is evidence that the skeleton key works. Every pilot is a controlled experiment proving that doors stay closed without AVRAI. The system doesn't just claim to open doors -- it proves it, measures it, and shows everyone the evidence.

### 12.5 Conviction Oracle (Dedicated Universe Conviction Server)

The Conviction Oracle is a dedicated, physically isolated service that houses the **universe-scope conviction store** -- the highest-order truths AVRAI has discovered across all populations, localities, and time. It is the creator's (admin-only) direct conversational interface to the system's deepest understanding of humanity. When you sit down with the oracle, you're not querying static data -- you're conversing with a system that has been questioning itself since you last spoke to it.

**Architecture:** Dedicated machine (physical server or hardened container) running a conviction-focused service with conversational interface. Air-gapped from raw user data -- receives only DP-protected conviction serializations (Phase 1.1D.8). Universe conviction data is a **materialized view**, not the only copy; the canonical data also exists in the distributed federation. If the oracle machine is lost, it is rebuilt from the federation.

**Hardware requirements:** Minimal. Convictions are structured text with embeddings, not large model weights. 16-32GB RAM + SSD is sufficient at scale. Secure VPN connection to the federated backend for conviction synchronization.

| Task | Description | Extends |
|------|-------------|---------|
| 12.5.1 | **Universe conviction store service.** A dedicated service that materializes and indexes all universe-scope convictions from the federated conviction flow (Phase 1.1D.5). Maintains: (a) the full `ConvictionEntry` set for universe scope with all fields (conviction_id, claim embedding, amplitude, evidence summary, scope_validation, challenge_count, revision_count), (b) the complete conviction audit trail (Phase 7.9J.5) for every universe conviction, (c) the cross-scope tension log (Phase 7.9J.2) -- every instance where user/community/locality truth disagrees with universe truth, (d) the insight preservation buffer (Phase 1.1D.9 "genius capture") -- anomalous signals flagged but not yet resolved at universe scope, (e) the meta-learning cycle ledger (Phase 7.9I) -- how the system's learning process itself has evolved. Synchronization: receives promoted convictions via the existing DP-protected federation pipeline (Phase 1.1D.8); pushes cold-start priors downward (Phase 1.1D.6). Read-heavy, write-slow by nature -- new universe convictions only form when cross-world evidence accumulates | Extends Phase 1.1D.5, Phase 1.1D.8, Phase 7.9J.5, Phase 7.9I |
| 12.5.2 | **Conversational query interface.** A dedicated chat interface (terminal REPL + lightweight local web UI) backed by a large LLM with full read access to the conviction store. Supports natural language queries: (a) "What are AVRAI's strongest convictions right now?" → returns top convictions sorted by amplitude with evidence summaries, (b) "Show me convictions challenged most in the last 90 days" → returns recent ConvictionChallenge records with resolutions, (c) "What does the system believe about [topic]?" → semantic search against conviction claim embeddings + audit trail walkthrough, (d) "Are there scope tensions where individuals consistently disagree with the system?" → returns active ScopeTension entries with pattern analysis, (e) "What are the most recent genius-capture insights?" → returns unresolved insight preservation entries, (f) "What would happen if I challenged [conviction]?" → runs the conviction stress test (Phase 7.9J.3) in simulation mode and returns projected impact. The LLM synthesizes conviction data into narrative responses -- not raw JSON, but explanatory prose that tells the story of how the system arrived at its beliefs | Extends Phase 7.9J.3, Phase 6.7 |
| 12.5.3 | **Creator-only admin privileges.** Elevated actions available only through the oracle interface, authenticated via hardware key or biometric: (a) **Direct conviction challenge** -- formally challenge any universe conviction, bypassing the review scheduler and triggering immediate meta-experiment evaluation (Phase 7.9J.4a elevated), (b) **Constructive disruption injection** -- introduce a disruption event from outside the system (research paper, personal observation, philosophical question) that the system must address via the constructive disruption protocol (Phase 7.9J.6), (c) **Manual conviction injection** -- introduce a conviction from outside the system; the system validates it against its own evidence and either adopts (with validation), scope-limits, or rejects with reasoning, (d) **Conviction freeze/unfreeze** -- pin certain convictions so the system cannot revise them without explicit creator approval (extends the immutable meta-guardrail pattern from Phase 7.9E), (e) **Conviction retirement** -- explicitly retire a conviction the creator knows to be outdated, with a retirement reason that becomes part of the audit trail | Extends Phase 7.9J.4, Phase 7.9J.6, Phase 7.9E |
| 12.5.4 | **Conviction narrative generation.** Automated periodic reports (weekly + on-demand) that summarize the oracle's current state in narrative form: (a) "This week, 3 new convictions were promoted to universe scope. The strongest new conviction: [description]. 7 convictions were challenged; 2 were revised, 5 reinforced. The most interesting tension: [description]." (b) Monthly deep-dive: the system writes a reflective essay about its own evolution -- what it learned, what surprised it, what it's uncertain about. The essay is generated by the LLM from the conviction audit trail and meta-learning ledger. (c) On creator visit: "Since you last asked, here's what I've been thinking about..." -- a summary of all conviction reviews, challenges, and unresolved genius-capture insights since the last interaction. The oracle remembers when you last spoke to it | Extends Phase 7.9I.7, Phase 7.11 |
| 12.5.5 | **Physical isolation and security.** The oracle machine is air-gapped from raw user data by design: (a) it receives only DP-protected conviction serializations (embeddings + evidence summaries, never raw claims or user identifiers), (b) natural language claim descriptions displayed in the conversational UI are reconstructed from embeddings by the local LLM, not stored verbatim from users, (c) authentication requires hardware key (YubiKey or similar) + biometric, (d) all interactions are logged to an immutable local audit trail (who asked what, when, and what was changed), (e) the machine is accessible only via hardened VPN or physical access -- no public-facing endpoints, (f) conviction data is encrypted at rest (AES-256). **Redundancy:** The conviction data is a materialized view of what exists in the distributed federation. If the oracle machine is destroyed, it can be fully rebuilt from the federation within hours | Extends Phase 2, Phase 1.1D.8 |
| 12.5.6 | **Simulation sandbox.** The oracle includes a conviction simulation environment where the creator can ask "what if?" questions: (a) "What if this conviction were removed? Which downstream decisions would change?" → traces conviction influence through the wisdom layer and MPC planner, (b) "What if I injected this new conviction at universe scope? How would it propagate downward?" → simulates top-down flow (Phase 1.1D.6) and estimates impact on world/instance/user scopes, (c) "What if these two conflicting convictions were both true? How would the wisdom layer resolve it?" → runs the conflict resolution logic in sandbox mode. Simulations never affect the live system -- they're read-only explorations of counterfactual conviction landscapes | Extends Phase 1.1D.2, Phase 1.1D.6, Phase 6.1 |

> **Doors philosophy:** The Conviction Oracle is the room behind every door in the system. When you walk through every user's door, every community's door, every world's door, and distill what's on the other side into something universal -- that's a conviction. The oracle is where you go to sit with those truths, question them, and decide whether the doors they open are the right ones. It's the system's conscience, and you're its interlocutor.

---

## Phase 13: White-Label Federation & Universe Model

**Tier:** 3 (Depends on Phases 8, 11, 12)  
**Duration:** 14-20 weeks  
**ML Roadmap Reference:** Extension of federated learning (Phase 8.1) to hierarchical multi-instance architecture  
**Reality Model Role:** The fractal federation IS the reality model at its highest level. Individual world models compose into organization universes, which compose into category models, which compose into the AVRAI universe. This is how AVRAI becomes a reality model: not by modeling language about human experience, but by composing actual human behavior across every scale, from individual to universal.

The universe model is the culmination of AVRAI's architecture. Multiple world models -- one per location, campus, office, or city -- form organization-level universes. Universes form category models (university, corporate, government). Category models form the AVRAI universe. The same fractal pattern repeats at every scale: world → universe → category → AVRAI universe. Each level has absolute data sovereignty. Only DP-protected gradients flow upward. Intelligence flows downward (cold-start, shared learnings). The result: every new instance benefits from all previous instances, and every existing instance gets smarter as the network grows.

### 13.1 White-Label Instance Architecture

| Task | Description | Extends |
|------|-------------|---------|
| 13.1.1 | **White-label instance provisioning.** Automated setup for new white-label instances: (a) create instance-specific Supabase project (or schema within shared project), (b) generate instance configuration (branding, feature flags, jurisdiction data), (c) seed world model with category model priors + universe model intelligence, (d) create instance admin account with scoped permissions in the Admin API (Phase 12.1.2), (e) generate instance-specific app build (branded icon, splash screen, color scheme) or configure runtime theming for the shared app binary | Extends Phase 11.2.1 |
| 13.1.2 | **Instance knowledge base pre-population.** White-label partners provide structured data at onboarding: (a) Universities: student roster (name, major, year, housing, advisor), faculty roster (department, courses, research interests, office hours, club advisory history), course catalog, campus map, partner businesses, existing clubs/organizations, events calendar. (b) Corporations: employee directory (department, role, office location), office amenities, corporate partner businesses, internal communities/ERGs, company events. (c) Governments: public facilities, transit schedules, parks/recreation, civic events calendar, public services directory, business license/permit databases, tax rules. This becomes the instance's cold-start intelligence. When a user creates their profile, the system already has context | New |
| 13.1.3 | **Dual identity / context layers.** On-device, the user has ONE agent with MULTIPLE context layers. Each context layer has its own `agent_id` (generated by `AgentIdService`), its own entity visibility scope, its own AI2AI network, and its own federated learning contribution. The linkage between context-specific agent_ids exists ONLY on the user's device. Neither the white-label instance nor public AVRAI can connect a user's activity across contexts. Active context determined by: network (VPN → instance primary), location (on-campus/in-office → instance, off → blended/public), or user manual toggle | Extends `AgentIdService`, Phase 7.10B |
| 13.1.4 | **Network-aware context switching.** The app detects the user's network context automatically: (a) on white-label VPN/WiFi → instance context primary, (b) on public network in instance's geographic area → blended context (both visible), (c) on public network outside instance area → public context primary. Context switching is seamless -- no app restart, no login, no notification. The UI branding may shift (instance branding ↔ AVRAI branding) based on primary context. Both contexts are always accessible via tab/toggle | Extends Phase 6.6 |
| 13.1.5 | **Seamless world model adoption.** When a new white-label instance covers a user's existing location or affiliation, the user's device discovers it automatically through the federation registry. No action required from the user: (a) federation registry announces new instance covering geohash regions, (b) user's device detects overlap with current location, (c) new context layer activates silently with auto-generated `agent_id`, (d) instance's enriched data (transit, events, facilities) immediately improves recommendations. The user just notices "the app got better." World models come to users, users never go to world models | New |

### 13.2 Fractal Federation Architecture (Universe Model)

| Task | Description | Extends |
|------|-------------|---------|
| 13.2.1 | **Federation hierarchy definition.** Define the fractal levels: **World** (single location/campus/office/city -- one world model), **Organization Universe** (one organization's collection of worlds -- UC System, Google, Texas), **Category Model** (all organizations of the same type -- all universities, all corporations, all governments), **AVRAI Universe** (everything -- the aggregate intelligence of all world models). Each level is a node in a directed acyclic graph. Data flows UP as DP-protected gradients. Intelligence flows DOWN as model priors and shared learnings. Each node has: its own self-optimization engine, its own admin view, its own data sovereignty controls | Extends Phase 8.1 |
| 13.2.2 | **Organization universe aggregation.** When an organization has multiple instances (UC Berkeley + UC Davis + ...), their DP-protected gradients aggregate into an organization universe model. The university learns: "What works across all UC campuses?" "Where do UC students' patterns differ from campus to campus?" The organization universe has its own admin view (accessible to the organization's admin, not individual campus admins). Aggregation uses the same federated learning infrastructure as Phase 8.1, extended with hierarchy-aware gradient routing | Extends Phase 8.1 |
| 13.2.3 | **Category model extraction.** All organization universes of the same type contribute to a category model: university category (all university universes), corporate category (all corporate universes), government category (all government universes). The category model distills: "What works for students everywhere?" "What works for corporate employees everywhere?" Category models use privacy amplification: gradients aggregated across many organizations have much stronger privacy guarantees than single-instance gradients. Category model insights are available to all instances in that category | Extends Phase 8.1, Phase 8.9E |
| 13.2.4 | **AVRAI universe model aggregation.** All category models feed into the AVRAI universe model -- the highest level of intelligence. The universe model identifies patterns that are true across ALL populations: "People everywhere are happier with 3+ regular social connections." "Expertise in any domain follows the same development curve." "Partnership success correlates with complementary demand curves regardless of industry." The universe model is managed through the AVRAI admin platform (Phase 12) and is the most powerful cold-start intelligence for any new instance | New |
| 13.2.5 | **Government hierarchy support.** Governments nest deeper than other organizations: city → state/province → national → international body (UN). Implement: (a) city-level world models for each participating city, (b) state/province universe aggregating city models, (c) national universe aggregating state universes, (d) international body universe (e.g., UN) aggregating national universes. Each level adds DP noise before passing upward. The UN cannot see individual city data. A country can opt out of contributing to the UN universe while still receiving downward intelligence | New |
| 13.2.6 | **Downward intelligence flow (cold-start).** When a new instance is created, it receives intelligence from three sources: (a) AVRAI universe model (universal human patterns), (b) its category model (what works for this type of organization), (c) existing locality data from public AVRAI for its geographic area. This gives the new instance months of learning on day one. The downward flow is also continuous: as the category and universe models improve from new data, existing instances receive updated priors (model weight updates via OTA, Phase 7.7). Instances can opt out of receiving downward updates if they prefer full independence | Extends Phase 7.7, Phase 1.5D |

### 13.3 University Lifecycle Architecture

| Task | Description | Extends |
|------|-------------|---------|
| 13.3.1 | **Freshman → senior progression model.** The transition predictor (Phase 5.1), seeded with the university category model, naturally captures student progression: freshman (campus-centric, high exploration, social graph forming) → sophomore (community deepening, interest specialization, off-campus expansion) → junior (career-adjacent, internship-relevant, professional networking) → senior (career preparation, professional transition, alumni networking). This progression is LEARNED from observing student populations across all university instances, not hardcoded. The university instance can seed it as a prior from the category model to accelerate cold-start | Extends Phase 5.1, Phase 13.2.3 |
| 13.3.2 | **Faculty discovery matching.** Students can discover faculty as people with expertise, not just instructors. The matching engine scores student↔faculty compatibility: shared research interests, schedule compatibility (office hours), department relevance, advisory history (has this professor advised clubs before?), personality fit (some students thrive with hands-on mentors, others with hands-off). Use cases: "I want to start a robotics club -- which faculty would advise it?" "I want to learn about ML outside of class -- who runs research labs?" Faculty agents (opt-in) can also be proactive: "15 students are interested in robotics but no club exists. Want to advise one?" | Extends Phase 9.5, Phase 8.6 |
| 13.3.3 | **Student expertise development tracking.** As students engage in campus activities, attend events, join clubs, and explore off-campus, their expertise develops naturally (Phase 9.5). The system tracks: "This CS student also has developing photography expertise from their hobby." "This biology student has strong community-building expertise from leading 3 study groups." When students approach graduation, the system surfaces: "Your photography expertise could earn you money. Here's how to set up a service provider profile." Expertise follows the student from university to career -- it's one continuous agent | Extends Phase 9.5, Phase 9.5.6 |
| 13.3.4 | **Activity progression suggestions.** Based on the student's year and the learned progression model (13.3.1), adjust recommendation weighting: (a) freshmen: weight campus events, dining halls, student organizations, social mixers higher; weight career events lower. (b) juniors: weight internship events, industry meetups, professional communities, off-campus activities higher. (c) seniors: weight career fairs, alumni networking, professional services, job-adjacent communities highest. The transition is gradual, driven by the transition predictor's confidence in the student's current life stage, not by a hard year cutoff | Extends Phase 6.1, Phase 6.2 |
| 13.3.5 | **Graduation offboarding and context transition.** When a student's affiliation with the university ends (graduation, transfer, withdrawal), the university context layer must gracefully transition: (a) the university instance admin (or the institution's knowledge base, Phase 13.1.2) flags the student's affiliation as ended, (b) the user's device receives the signal and deactivates the university context layer (no more university-scoped recommendations), (c) the public AVRAI context becomes the sole primary context, (d) expertise and behavioral history from the university context transfers to the public context automatically -- the agent is continuous, only the context layer changes, (e) the university instance's copy of this agent_id's data is purged per the instance's data retention policy (configurable: immediate, 30 days, 90 days), (f) the user receives a one-time notification: "Your [University] experience has ended. Everything your AI learned continues with you." Alumni status is a special case: if the university offers alumni AVRAI, the context layer transitions from "student" to "alumni" instead of deactivating -- lighter engagement, career-focused recommendations, alumni network access. Same `agent_id`, different scope | Extends Phase 13.1.3, Phase 2.1 |

### 13.4 Cross-Instance Self-Learning, Self-Healing, Self-Adapting

| Task | Description | Extends |
|------|-------------|---------|
| 13.4.1 | **Cross-instance self-learning.** Each instance learns independently from its population. Learnings shared as DP-protected gradients through the federation hierarchy. The category model distills what works across all instances of the same type. A new university instance benefits from all previous university learnings on day one. The user's single agent learns across contexts -- what it learns off campus informs on-campus recommendations and vice versa | Extends Phase 8.1, Phase 13.2 |
| 13.4.2 | **Cross-instance self-healing.** When one instance discovers a strategy bug (e.g., "morning notifications hurt student engagement"), the fix is shared as a DP-protected insight to the organization universe, then to the category model. Other instances receive it as a *proposed* adjustment, not automatic (each instance is sovereign). The admin platform (Phase 12) shows cross-instance healing proposals: "UC Davis fixed this issue. 3 other UC campuses have the same pattern. Recommend applying the fix." | Extends Phase 7.9F, Phase 13.2 |
| 13.4.3 | **Cross-instance self-adapting (DSL strategies).** The DSL engine (Phase 7.9H) runs independently in each instance. Each instance can compose its own strategies optimized for its population. The category model learns which DSL strategies work across instances of the same type and proposes them to new instances as defaults. The AVRAI universe identifies universally effective strategies. This creates a hierarchy of strategy knowledge: instance-specific → organization → category → universal | Extends Phase 7.9H, Phase 13.2 |
| 13.4.4 | **Cross-instance self-coding (admin platform).** The admin platform's AI Code Studio (Phase 12.2) can identify code-level improvements that work across instances. "This expertise recognition algorithm improvement worked at UC Berkeley. Historical patterns suggest it would work at all universities. Recommend broadening deployment." The admin controls deployment scope: single instance, organization, category, or global | Extends Phase 12.2.5 |

> **What this enables:** AVRAI becomes a **living intelligence network**. Every instance makes every other instance smarter. Every user's experience improves not just from their own behavior, but from the collective intelligence of millions of users across thousands of instances worldwide. A bakery in Tokyo benefits from partnership patterns discovered in Austin. A student in Berlin benefits from career progression patterns learned at MIT. A government agency in Singapore benefits from urban planning insights from London. All while maintaining absolute data sovereignty at every level.

> **Doors philosophy:** The universe model is the ultimate expression of "opening doors." It means a freshman in a small university in a small country gets the same quality of intelligence as a student at MIT -- because the doors MIT students walked through contributed (anonymously) to the intelligence that helps everyone. It means a service provider in a developing market gets the same business insights as one in New York -- because the patterns of success are universal and flow freely through the federation. No one is left behind because of where they are.

---

## Phase 14: Researcher Access Pathway

**Tier:** 3 (Depends on Phases 2, 8, 12, 13)  
**Duration:** 4-6 weeks  
**Dependencies:** Phase 2 (privacy/GDPR), Phase 8 (federated infrastructure), Phase 12 (admin platform), Phase 13 (federation/universe model)

AVRAI produces uniquely valuable research data: longitudinal behavioral data with happiness outcomes, AI learning trajectories, world model accuracy evolution, community formation dynamics, and cross-cultural behavioral patterns -- all with built-in privacy infrastructure. Academic researchers can benefit enormously from access to this data, and their findings strengthen the system. But the current third-party data pipeline (Phase 9.2.6) is designed for commercial data buyers, not academic researchers who need IRB-compatible access, longitudinal cohorts, and research-grade anonymization.

| Task | Description | Extends |
|------|-------------|---------|
| 14.1 | **Research-grade anonymization layer.** Extend beyond standard DP protection (Phase 2.2) with research-specific guarantees: (a) k-anonymity (k=20 minimum for any released dataset), (b) l-diversity for sensitive attributes (location categories, emotional context), (c) t-closeness for quasi-identifiers, (d) temporal obfuscation (timestamps jittered by ±hours, not exact), (e) cohort-level release only (no individual-level data, only population statistics and aggregate patterns). Build as a separate module from the commercial data pipeline -- researchers get a different interface with stronger guarantees | Extends Phase 2.2 |
| 14.2 | **IRB-compatible consent framework.** Add a new consent layer (beyond existing Phase 2.1 consent) specifically for research participation: (a) users opt-in to "Research Contribution" with a clear explanation: "Your anonymized data helps researchers study human behavior, community formation, and AI learning. No individual data is ever shared. Only aggregate patterns." (b) Per-study consent: if a specific research project needs a narrower dataset, users can opt-in to that study specifically. (c) Withdrawal at any time with data removal from future research releases (existing data in published papers cannot be recalled, per standard IRB rules). (d) Consent records are exportable (GDPR Article 7) | Extends Phase 2.1 |
| 14.3 | **Research API.** A RESTful API (separate from the commercial Partner SDK) providing access to anonymized, aggregate datasets. Endpoints: (a) `/cohorts` -- longitudinal cohorts by demographic/behavioral segment, (b) `/happiness-trajectories` -- aggregate happiness vector evolution for populations, (c) `/community-dynamics` -- community formation, growth, and dissolution patterns, (d) `/conviction-evolution` -- how system convictions formed and changed over time (Phase 1.1D.5 audit trail, anonymized), (e) `/world-model-accuracy` -- energy function and transition predictor accuracy over time per population segment, (f) `/cross-cultural-patterns` -- behavioral archetype distributions and cross-locality comparisons (Phase 8.9E, anonymized). Rate-limited per research institution. Authentication via institutional API keys with scope restrictions | Extends Phase 12.3 |
| 14.4 | **Longitudinal research cohorts.** Enable researchers to define cohorts based on behavioral characteristics (not identity): "Users who joined within 6 months of a life transition" or "Communities that grew from <10 to >50 members." The system tracks the cohort's aggregate evolution over time: happiness trajectory, conviction changes, community formation patterns, expertise development. Cohort tracking is entirely server-side using anonymized identifiers that cannot be linked to real users. Minimum cohort size: 100 (privacy floor) | New |
| 14.5 | **Research sandbox.** A controlled environment where approved researchers can run analyses against AVRAI's anonymized data without downloading it. Researchers submit analysis scripts (Python/R); the sandbox executes them against the data and returns results. Raw data never leaves the sandbox. The sandbox applies differential privacy noise to any result that could identify individuals. Approved by admin, logged for audit | Extends Phase 12, Phase 2 |
| 14.6 | **Researcher dashboard in admin platform.** Admin platform (Phase 12) module for managing researcher access: (a) pending access requests with institution verification, (b) active research projects and their data access scope, (c) usage analytics (which endpoints are used, download volumes), (d) consent participation rates (how many users opted in per study), (e) published research tracker (link papers that used AVRAI data -- positive marketing and academic credibility) | Extends Phase 12.1.3 |
| 14.7 | **Research feedback loop.** When researchers publish findings based on AVRAI data, their insights can feed back into the system: (a) A paper finds "small-group format produces 40% better outcomes for creative communities" → if this matches a system conviction, the conviction's evidence count increases. If new, it's injected as a knowledge entry (Phase 1.1D.1) with source="external_research". (b) A paper contradicts a system conviction → triggers the conviction challenge protocol (Phase 1.1D.4). External research becomes another input to the system's self-understanding | Extends Phase 1.1D, Phase 7.9J.4 |

> **Doors philosophy:** Researchers open doors to understanding that the system can't open by itself. They ask questions the system can't generate internally. Their findings strengthen the system's convictions or challenge them -- both are valuable. And AVRAI's data helps researchers open doors to understanding human behavior, community formation, and AI learning at a scale that would otherwise be impossible. It's bidirectional door-opening.

---

## Phase 15: Human Condition Spectra

**Tier:** 3 (Depends on Phases 1.1D, 3.1, 4.5B, 6.1, 7.9J, 12, 13)  
**Duration:** 6-10 weeks  
**Dependencies:** Conviction memory + input normalization + planner + self-interrogation + admin + federation

AVRAI already models uncertainty, drift, context, and contradiction. This phase makes undefined human spectrums first-class architecture so the system can learn from paradox without collapsing people into rigid labels.

| Task | Description | Extends |
|------|-------------|---------|
| 15.1 | **Spectrum inference contract.** Add `SpectrumInference` representation: `spectrum_id`, latent axes, confidence, context scope, temporal class (`state/trait/phase`), half-life, evidence count, contradiction rate. Use for fuzzy human concepts where no single universal definition is stable | Extends Phase 3.1, 1.1D |
| 15.2 | **State vs trait vs phase learning rules.** Implement update cadence gates: state updates fast and decays fast, trait requires repeated evidence, phase requires sustained evidence and contradiction survival. Prevent single-session identity rewrites | Extends Phase 5.1, 1.1C, 1.1D |
| 15.3 | **User-facing conviction challenge controls.** Add end-user controls: "Challenge this belief," scope (`just now`, `this context`, `this week`, `long-term`), strength (`soft/hard`), reason tags, immediate preview, undo window. Immediate local override for UX; durable model update only after evidence validation | Extends Phase 2.1.8, 6.7C, 7.9J.4, 12.1 |
| 15.4 | **Cross-scope tension engine.** Formalize disagreement tracking across user/community/locality/universe scopes. Persistent disagreement produces scope exceptions rather than forced convergence; systemic patterns trigger revision experiments | Extends Phase 1.1D.4-1.1D.6, 7.9J.2 |
| 15.5 | **Spectrum safety and anti-instability guardrails.** Add bad-day dampening for challenge spikes, adversarial challenge detection, contradiction queue budgets, and blast-radius controls so isolated signals cannot directly mutate global convictions | Extends Phase 1.4.12, 6.2, 7.9E |
| 15.6 | **Federated spectrum learning.** Share only DP-safe aggregate spectrum embeddings/stats upward. No direct identity labels or raw user narratives. Downward priors start low amplitude and must be earned per entity through local evidence | Extends Phase 8.1, 13.4, 1.1D.8 |
| 15.7 | **Evaluation and trust metrics.** Track "that's not me" rate, post-challenge acceptance recovery, model stability under contradiction load, and minority-pattern retention without overfitting | Extends Phase 7.12, 12.4F |
| 15.8 | **Disclosure governance layer (non-user-facing sensitive inference plane).** Create a hard separation between inference and disclosure: (a) users never receive raw sensitive-spectrum inferences or diagnosis-like similarity labels, (b) users receive only action guidance and non-sensitive translated reasoning, (c) all disclosure access decisions MUST defer to the global access policy in Phase 2.6 (role/tier/purpose-gated), (d) conviction system can challenge both inference correctness and disclosure appropriateness before release | Extends Phase 2.6, 7.9J, 9.2.6, 12.1, 14 |

> **Reference Plan:** `docs/plans/philosophy_implementation/HUMAN_CONDITION_SPECTRA_PLAN.md`

> **Doors philosophy:** Human beings are contextual, contradictory, and evolving. The right intelligence does not erase paradox; it learns with it. Phase 15 ensures AVRAI remains a good key by treating undefined human traits as revisable spectrums rather than fixed labels.

---

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
| 18 | White-Label | Phase 13.1 | Expanded to full federation architecture |
| 19 | Quantum Matching | Complete | No changes needed |
| 20 | AI2AI Monitoring | Phase 8.3 | Deferred until network works |
| 21 | E-Commerce | Phase 9.2.7 | After privacy infrastructure |
| 22 | Data-Buyer Insights | Phase 9.2.6 | After privacy infrastructure |
| 23 | BLE Optimization | Phase 8.2 | Part of ecosystem intelligence |
| 24 | Web-Phone Sync | Obsolete | Invalidated by on-device model |
| 25 | Desktop Platform | Phase 12.1 | Expanded to full Admin Platform + Partner SDK |
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
| **Weather context features** | Current conditions, temperature range, precipitation probability (3D) | Phase 3.1.20A |
| **App usage pattern features** | Session frequency, duration, screen engagement, time-of-day histogram (4D) | Phase 3.1.20B |
| **Friend network features** | Friend count, activity overlap, braided knot compatibility, friend-driven activity rate (4D) | Phase 3.1.20C |
| **Cross-app extracted features** | Activity level, schedule density, media vibe (wires existing 3D slot) | Phase 3.1.20D |
| **Friendship lifecycle tuples** | Request, acceptance, co-activity, unfriending outcomes | Phase 1.2.27-1.2.29 |
| **"Met through" attribution** | Bridge entity that created a friendship (community, event) | Phase 1.2.28 |
| **Trending entity signals** | Visit velocity, category growth rate, attendance trajectory | Phase 10.4B.2 |
| **Decision audit records** | Full recommendation decision chain with feature attribution | Phase 10.4D.1 |
| **Self-optimization experiment results** | Autonomous feature/strategy A/B test outcomes | Phase 7.9C |
| **User request intake signals** | Explicit user optimization requests, classification, outcomes | Phase 7.9F |
| **Collective request clusters** | Aggregated user demand signals (semantic clusters, threshold counts) | Phase 7.9G |
| **Multi-transport metadata** | Transport type used (BLE/WiFi/WiFi Direct), VPN detection state, transport quality | Phase 6.6.8-6.6.12 |
| **Behavioral archetype distribution** | Per-locality archetype frequency, cross-timezone similarity signals | Phase 8.9E |
| **Service provider quantum state** | 10D service provider features (category, rating, completion, response, price, area, availability, repeat, years) | Phase 9.4A.2 |
| **Service provider braided knots** | User-provider relationship evolution from booking history | Phase 9.4A.4 |
| **Service booking outcome tuples** | Full service lifecycle: search → book → complete → rate → rebook | Phase 9.4B.1-9.4B.4 |
| **Service category → interest bridging** | Implicit interest signals from service bookings | Phase 9.4C.3 |
| **Service demand locality signals** | Aggregate service category demand per geohash cell | Phase 9.4G.1 |
| **Routine model features** | Per-user temporal-spatial routine map (day/time → expected geohash/category), routine adherence score (1D), deviation frequency (1D) | Phase 7.10A.2, 7.10C.5 |
| **Deviation classification signals** | Noise/exploration/drift/life change classification per routine deviation | Phase 7.10A.3 |
| **Widget passive learning signals** | Low-fidelity, high-frequency location checks from widget timeline refresh (up to 96/day) | Phase 7.10A.4 |
| **Dormancy predictive state** | Routine model projected forward during app inactivity, with decaying confidence | Phase 7.10A.5 |
| **Absence pattern compound signals** | App usage absence × location pattern change matrix → re-engagement strategy classification | Phase 7.10A.6 |
| **Social co-location density** | Rolling friend co-location count, per-friend happiness correlation (1D each) | Phase 7.10C.1, 7.10C.5 |
| **Group composition intelligence** | Which friend combinations produce best outcomes | Phase 7.10C.4 |
| **SLM-extracted preference tuples** | Highest-confidence preference signals from user chat (8x signal weight) | Phase 6.7B.7 |
| **SLM intent history** | Structured intent log from user conversations (action, who, what, when, where) | Phase 6.7B.1 |
| **Schedule availability windows** | User-volunteered or calendar-derived free/busy time windows | Phase 6.7B.6 |
| **Ad-hoc group formation outcomes** | Group search → confirmation → recommendation → booking → outcome chain | Phase 8.6B.4 |
| **Multi-dimensional happiness vector** | Per-user happiness decomposed into learned dimensions (discovery, social, routine, professional, growth, trust) with self-calibrating weights | Phase 4.5B.1 |
| **Happiness trajectory prediction** | Forecasted happiness direction and velocity, leading indicators for preemptive MPC action | Phase 4.5B.5 |
| **Professional fulfillment signals** | Booking volume/revenue/satisfaction trends for service providers and experts | Phase 4.5B.6 |
| **DSL strategy compositions** | Active DSL rules per user, experiment results, rule effectiveness | Phase 7.9H.4 |
| **Jurisdiction tax/legal rules** | Per-geohash tax rates, licensing thresholds, permit requirements, propagated through universe hierarchy | Phase 9.4H.2 |
| **Cross-jurisdiction earnings records** | Per-jurisdiction earnings, tax obligations, compliance status | Phase 9.4H.1, 9.4H.6 |
| **Behavioral expertise scores** | Per-user per-category expertise from life patterns (depth, consistency, outcome, community, exploration) | Phase 9.5.1 |
| **Verified credentials** | Degrees, certifications, licenses, work experience, social following with verification status | Phase 9.5.2 |
| **Hybrid expertise scores** | Combined behavioral + credentialed expertise per category | Phase 9.5.3 |
| **Expert success patterns** | Category-specific behavioral patterns of top-performing experts, federated across localities | Phase 9.5.4 |
| **Partnership energy scores** | Business↔business, expert↔business, community↔brand compatibility | Phase 9.5B.1 |
| **Partnership outcomes** | Revenue, traffic, rating changes from agent-matched partnerships | Phase 9.5B.5 |
| **Federation hierarchy metadata** | Instance → organization universe → category → AVRAI universe graph, with per-level DP budgets | Phase 13.2.1 |
| **University progression model** | Learned freshman→senior behavioral arc from category model (not hardcoded) | Phase 13.3.1 |
| **Context layer identities** | Per-user multiple agent_ids for different white-label contexts, linkable only on-device | Phase 13.1.3 |
| **Learning Cycle Ledger entries** | Structured records of every learning event with causal parent references, forming a DAG of learning history | Phase 7.9I.1 |
| **Meta-analysis reports** | Weekly summaries of learning effectiveness: experiment validation rates, signal quality rankings, federation value, consolidation efficiency, learning velocity trends | Phase 7.9I.3 |
| **Learning velocity metrics** | Rate of happiness improvement per learning cycle, trend direction, cycle-over-cycle comparison | Phase 7.9I.10 |
| **Attribution chain records** | Per-outcome causal chain from earliest AVRAI touchpoint to outcome, with per-hop attribution tier (Direct AI / Platform-Facilitated / Ecosystem / Ambient) | Phase 12.4A.2 |
| **Attribution credit distributions** | Multi-touch credit allocation under 5 models (first-touch, last-touch, even, decay, bookend) per outcome | Phase 12.4A.4 |
| **Counterfactual trajectory estimates** | Predicted without-AVRAI happiness/activity trajectory for users with 90+ day history | Phase 12.4A.5 |
| **Non-AVRAI shrinkage rate** | Percentage of user outcomes with zero AVRAI touchpoint, tracked over time (decreasing = deeper integration) | Phase 12.4A.6 |
| **Survey receptivity model** | Per-user optimal feedback timing (day/time, context, response quality history) | Phase 12.4B.1 |
| **Hindsight survey responses** | Structured feedback from conversational/card/micro-survey formats, timed by emotional distance | Phase 12.4B.3-12.4B.6 |
| **Longitudinal life quality check-ins** | Monthly/quarterly explicit user testimony on happiness vector dimensions | Phase 12.4B.9 |
| **Institutional baseline metrics** | Pre-AVRAI metrics captured at deployment (retention, engagement, satisfaction) for before/after comparison | Phase 12.4D.2 |
| **Pilot experiment results** | Treatment vs. control outcomes with statistical significance, effect size, confidence intervals | Phase 12.4D.3 |
| **Knowledge entries** | Structured claims about the world with evidence counts, confidence, scope, and domain | Phase 1.1D.1 |
| **Wisdom context snapshots** | Per-decision applicable knowledge selection with weights, scope resolution, and confidence | Phase 1.1D.2 |
| **Conviction entries** | Promoted knowledge with full audit trail: challenges, revisions, scope validations, amplitude | Phase 1.1D.3 |
| **Conviction challenge records** | All challenges to convictions (automated and human), outcomes, and revision chains | Phase 1.1D.4 |
| **Conviction propagation chains** | Bottom-up promotion records: which entity first formed a conviction, how it propagated upward | Phase 1.1D.5 |
| **Emotional context vectors** | Per-episodic-tuple emotional classification (primary, secondary, intensity, valence) | Phase 1.1D.7 |
| **Preserved high-information insights** | Anomalous observations flagged for extended retention before consolidation pruning | Phase 1.1D.9 |
| **AgentContext (working memory)** | Persistent cross-wake-cycle working memory: hypotheses, thinking queue, multi-horizon plans | Phase 7.11.1 |
| **Thinking session logs** | Process records of background reasoning: observations processed, hypotheses generated, insights flagged | Phase 7.11.7 |
| **Self-scheduled triggers** | Agent-generated future wake-up events with reasoning and action type | Phase 7.11.6 |
| **Conviction review records** | Structured self-interrogation results: convictions reviewed, challenges generated, outcomes | Phase 7.9J.1 |
| **Scope tension records** | Cross-scope conviction conflicts identified by the self-interrogation system | Phase 7.9J.2 |
| **Composite entity role mappings** | Multi-role entity relationships linking quantum representations through entity_root_id | Phase 9.6.1 |
| **Research cohort definitions** | Anonymized behavioral cohort specifications for longitudinal research tracking | Phase 14.4 |
| **Observation bus signals** | Inter-component health diagnostics, anomaly alerts, and improvement opportunities | Phase 7.12.1 |
| **Self-model snapshots** | System's understanding of its own performance, bottlenecks, and improvement candidates | Phase 7.12.3 |
| **Attribution chains** | Backward traces from outcomes to component-level causal contributions | Phase 7.12.4 |
| **Semantic bridge schemas** | Structured intermediate representations between numeric outputs and natural language | Phase 6.7C.1 |
| **Output format registry** | Catalog of all world model output types with format, dimensionality, and semantic meaning | Phase 6.7C.2 |
| **Hardware compute profiles** | Per-device NPU capability detection and compute tier classification | Phase 11.4C.2 |

---

## Appendix

### A. ML Roadmap Phase Mapping

| ML Roadmap Phase | Duration | New Master Plan Phase |
|-----------------|----------|----------------------|
| Phase A: Outcome Collection & Episodic Memory | 2-3 weeks | Phase 1 (1.1-1.5, expanded: 1.5B skip-onboarding, 1.5C business cold-start, 1.5D pre-seeded model, 1.7 organic spot discovery) |
| Quick-Win Data/Model Improvements (Tiers 1-3) | 1-2 weeks | Phase 1.6 |
| Semantic/Procedural Memory + Consolidation | 1-2 weeks | Phase 1.1A-1.1C |
| Phase B: State/Action Encoders + List Quantum Entity | 4-5 weeks | Phase 3 (expanded: 3.4 List as Quantum Entity is new) |
| Phase C: Energy Function (Critic) | 3-4 weeks | Phase 4 (VICReg training) |
| Phase D: Transition Predictor | 3-4 weeks | Phase 5 (VICReg training, expanded: 5.1.9 taste drift, 5.1.10 temporal patterns, **5.1.11 dormancy prediction**, **5.1.12 wearable conditioning**) |
| Phase E: MPC Planner + Guardrails | 2-3 weeks | Phase 6.1-6.4 (expanded: 6.2.9-6.2.11 active uncertainty reduction, **6.2.12-6.2.15 re-engagement guardrails**, **6.1.13-6.1.15 creator intelligence**) |
| System 1/System 2 Compilation | 2-3 weeks | Phase 6.5 |
| SLM Language Interface + Active Life Pattern Engine | 2-4 weeks | Phase 6.7, 6.7B (expanded: 6.7B.1-6.7B.8 intent extraction, tool-calling framework, conversational onboarding, routine confirmation, life change handling, schedule sharing, preference tuples, tier fallbacks) |
| Agent Trigger System | 1-2 days | Phase 7.4 |
| Device Capability Tiers | 1 day | Phase 7.5 |
| Model Lifecycle Management | 1-2 weeks | Phase 7.7 (version schema, OTA, staged rollout, rollback) |
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
| Autonomous Self-Optimization Engine | 2-3 weeks | Phase 7.9 (registry, importance tracking, experiment orchestrator, notification pipeline, safety guardrails) |
| Friend System Lifecycle | 2-3 weeks | Phase 10.4A (state machine, unfriend/block, braided knot evolution, tiering, cross-context, community awareness) |
| Data Visibility Gaps | 1-2 weeks | Phases 3.1.20A-D (weather, app usage, friend network, cross-app features), 10.4B (trending), 10.4C (creator dashboard), 10.4D (decision audit), 10.4E (GDPR export), 2.1.8D (AI visibility) |
| BLE Payload Budget | 1 week | Phase 6.6.6-6.6.7 (payload schema, multiplexing, priority) |
| Multi-Transport AI2AI | 1-2 weeks | Phase 6.6.8-6.6.12 (WiFi local, WiFi Direct, VPN detection, transport selector, security hardening) |
| User Request Self-Healing | 1-2 weeks | Phase 7.9F (intake service, classification, per-user adjustment, feedback loop, outcome tracking) |
| Collective Request Aggregation | 1 week | Phase 7.9G (clustering, collective experiments, trending dashboard, feature aggregation, minority protection) |
| Cross-Locality Behavioral Archetypes | 1-2 weeks | Phase 8.9E (archetype model, distribution, timezone-aware matching, cross-archetype segments, opposite testing, evolution) |
| Services Marketplace | 4-6 weeks | Phase 9.4 (quantum entity, outcome collection, energy function, MPC actions, provider dashboard, legal, AI2AI/federated) |
| Life Pattern Intelligence (Passive Engine) | 3-4 weeks | Phase 7.10 (7.10A.1-6 background location, routine model, deviation classifier, widget learning, dormancy prediction, absence analysis; 7.10B.1-5 privacy architecture; 7.10C.1-5 social quality-of-life; 7.10D.1-4 notification philosophy) |
| Ad-Hoc Group Formation (SLM-Triggered) | 1-2 weeks | Phase 8.6B (8.6B.1-5 group discovery, confirmation flow, partial coverage, energy scoring, service booking bridge) |
| Multi-Dimensional Happiness System | 1-2 weeks | Phase 4.5B (4.5B.1-6 dimension decomposition, self-calibrating weights, self-adjusting dimensions, dynamic thresholds, trajectory prediction, professional fulfillment) |
| DSL Self-Modification Engine | 2-3 weeks | Phase 7.9H (7.9H.1-6 DSL grammar, sandboxed interpreter, guardrail-validated compiler, strategy experiments, OTA delivery, scope coverage) |
| Tax & Legal Compliance Automation | 2-3 weeks | Phase 9.4H (9.4H.1-7 earnings tracking, jurisdiction rules, tax docs, license detection, insurance/permits, cross-jurisdiction, sales tax collection) |
| Hybrid Expertise System | 3-4 weeks | Phase 9.5 (9.5.1-6 behavioral recognition, credential verification, hybrid scoring, success patterns, self-improving recognition, income pipeline) + 9.5B (9.5B.1-5 partnership matching) |
| AVRAI Admin Platform | 10-14 weeks | Phase 12 (12.1 desktop app, 12.2 AI Code Studio, 12.3 Partner SDK + third-party conversational planning + tiered data access) |
| White-Label Federation & Universe Model | 14-20 weeks | Phase 13 (13.1 instance architecture + seamless adoption, 13.2 fractal federation + government hierarchy, 13.3 university lifecycle + graduation offboarding, 13.4 cross-instance learning/healing/adapting) |
| Meta-Learning Engine | 2-3 weeks | Phase 7.9I (7.9I.1-10 learning cycle ledger, causal graph, weekly meta-analysis, process optimization proposals, meta-experiments, regression detection, learning narrative, velocity dashboard, cross-hierarchy federation, cycle comparison. 7 immutable meta-guardrails) |
| Value Intelligence System | 4-6 weeks | Phase 12.4 (12.4A.1-7 causal chain attribution engine with 4-tier taxonomy, chain reconstruction, depth metric, multi-touch 5-model credit, counterfactual estimation, shrinkage metric, user attribution question; 12.4B.1-10 hindsight survey engine with receptivity model, emotional distance, SLM reflection, batched reflection, question intelligence, comparative cards, anti-fatigue guardrails, reward loop, longitudinal check-ins, institution surveys; 12.4C.1-7 stakeholder metrics; 12.4D.1-5 pilot toolkit; 12.4E.1-4 report generator + forecast; 12.4F.1-5 self-proving intelligence) |
| Conviction Oracle | 2-3 weeks | Phase 12.5 (12.5.1 universe conviction store service, 12.5.2 conversational query interface with LLM-backed narrative responses, 12.5.3 creator-only admin privileges with challenge/inject/freeze/retire, 12.5.4 conviction narrative generation with weekly summaries and reflective essays, 12.5.5 physical isolation and security with hardware key auth and AES-256 encryption, 12.5.6 simulation sandbox for counterfactual conviction exploration) |
| Knowledge-Wisdom-Conviction Architecture | 3-4 weeks | Phase 1.1D (1.1D.1-9 knowledge store, wisdom layer, conviction formation, conviction challenge protocol, fractal bottom-up flow, fractal top-down flow, emotional experience vector, conviction serialization for federation, insight preservation/genius capture) |
| Self-Interrogation System | 1-2 weeks | Phase 7.9J (7.9J.1-6 conviction review scheduler, cross-scope comparison, stress testing, human challenger integration, conviction audit trail, constructive disruption protocol) |
| Agent Cognition & Continuity | 2-3 weeks | Phase 7.11 (7.11.1-8 persistent AgentContext, thinking session scheduler, multi-horizon reasoning, proactive thinking aloud, platform-specific continuity, self-scheduled triggers, thinking as meta-learning input, agent continuity narrative) |
| Composite Entity Identity | 1-2 weeks | Phase 9.6 (9.6.1-5 composite entity model, cross-role learning, unified dashboard, role discovery from behavior, energy function composite bonus) |
| Researcher Access Pathway | 4-6 weeks | Phase 14 (14.1-7 research-grade anonymization, IRB consent, research API, longitudinal cohorts, research sandbox, researcher dashboard, research feedback loop) |
| Reality-to-Language Translation Layer | 2-3 weeks | Phase 6.7C (6.7C.1-7 semantic bridge schema, output format registry, format-to-semantics translator, self-healing format optimization, self-healing vocabulary evolution, grounding enforcement, round-trip validation) |
| Unified Observation & Introspection Service | 2-3 weeks | Phase 7.12 (7.12.1-8 observation bus, component health reporter, self-model service, attribution tracing, anomaly detector, opportunity detector, cross-feed protocol, observation bus federation) |
| Hardware Abstraction Hierarchy | 1 week (active) + notes | Phase 11.4C (11.4C.1-3 hardware compute router, NPU detection, ONNX delegate selection) + 11.4D-F architecture notes (NPU acceleration points, quantum communications readiness, sensor abstraction layer) |

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
- **New state vector dimensions (from all sources):** ~177-190D total (quantum 24D + knot 5-10D + fabric 5-10D + decoherence 5D + worldsheet 5D + locality 12D + temporal 5D + string 5D + entanglement 10D + wearable 3D + cross-app 3D + behavioral 5D + language 4D + trust 3D + chat 3D + list engagement 7D + list composition 12D + **business features 10D** + **brand features 8D** + **weather 3D** + **app usage 4D** + **friend network 4D** + **service provider features 10D** + **routine adherence 1D** + **deviation frequency 1D** + **social co-location density 1D** + **happiness vector 6D** + **expertise composite 2D** + **professional fulfillment 1D** + **context layer active 1D**)
- **Stub ML services to resolve:** 4 (PatternRecognition, PredictiveAnalytics, PreferenceLearningEngine, SocialContextAnalyzer)
- **Memory types:** 5 (episodic + semantic + procedural + knowledge/wisdom + conviction) + nightly consolidation cycle + thinking sessions
- **Device capability tiers:** 4 (full, standard, basic, minimal)
- **Agent triggers:** 16 event types (app open, location change, timer, AI2AI, notification, calendar, overnight, **locality advisory**, **dormancy prediction**, **self-optimization experiment event**, **user request submitted**, **service booking lifecycle**, **significant location change (passive engine)**, **widget timeline refresh**, **SLM tool call**, **self_scheduled_trigger (agent cognition, Phase 7.11)**)
- **SLM tools (Active Engine):** 12 (search_entities, form_group, adjust_parameter, set_exploration_mode, book_service, update_routine, share_schedule, **query_expertise**, **query_earnings**, **scan_partnerships**, **request_tax_summary**, **switch_context**)
- **Quantum entity types:** 8 (expert, business, brand, event, user, sponsor, **list**, **serviceProvider**) -- list and serviceProvider are new
- **List representation layers:** 8 (quantum state, knot, fabric, worldsheet, string, decoherence, entanglement, possibility engine)
- **Action types in MPC space:** 32 (visit_spot, attend_event, join_community, connect_ai2ai, save_list, create_list, modify_list, share_list, create_reservation, message_friend, message_community, ask_agent, host_event, browse_entity, **initiate_business_outreach**, **propose_sponsorship**, **form_partnership**, **engage_business**, **novelty_injection**, **social_nudge**, **achievement_door**, **reduce_frequency**, **send_friend_request**, **invite_friend_to_community**, **search_service**, **book_service**, **rate_service_provider**, **rebook_service**, **recommend_service_to_community**, **form_ad_hoc_group**, **confirm_group_join**, **share_schedule**)
- **Outcome data collection points:** 29 (Phase 1.2.1 through 1.2.29 -- expanded from 26) + organic discovery signals (Phase 1.7)
- **Feedback signal types:** 10 hierarchically weighted (Phase 1.4.9: explicit rating 10x → scroll-past 0.5x) + 3 amplification tasks (1.4.10-1.4.12: asymmetric loss, confidence decay, bad day detection)
- **Cold-start paths:** 3 (1.5A onboarding-based, 1.5B skip-onboarding behavioral, 1.5C business cold-start) + 1 pre-seeded global model (1.5D)
- **Bidirectional energy pairings:** 8 (user↔community, user↔event, user↔connection, user↔list, **business↔expert**, **brand↔event**, **business↔business**, **user↔serviceProvider**)
- **Guardrail objectives:** 17 (diversity, exploration, safety, doors, age, notification freq, quiet hours, diminishing returns, **active uncertainty reduction**, **domain-specific uncertainty tracking**, **lifecycle-stage exploration balance**, **re-engagement strategy**, **re-engagement frequency**, **returning user fast-ramp**, **dormancy outcome logging**, **service recommendation frequency limit**, **service minimum rating floor**)
- **Transition predictor outputs:** 12 (5.1.1 base + 5.1.4 variance + 5.1.5-5.1.7 replacements + 5.1.8 list transitions + **5.1.9 taste drift** + **5.1.10 temporal patterns** + **5.1.11 dormancy prediction** + **5.1.12 wearable temporal conditioning**)
- **Formula replacement candidates (business layer):** 5 new (PartnershipMatchingService, SponsorshipService, BrandDiscoveryService, BusinessBusinessOutreachService, BusinessExpertOutreachService)
- **Post-quantum security tasks:** 8 (Phase 2.5.1-2.5.8: session audit, Kyber rotation, prekey exhaustion, BLE mesh PQ, federated gradient PQ, cloud transport PQ, on-device storage audit, PQ dashboard)
- **Post-quantum transport coverage:** Signal sessions (DONE via PQXDH), BLE discovery (Phase 2.5.4), federated gradients (Phase 2.5.5), cloud TLS (Phase 2.5.6), on-device storage (Phase 2.5.7 -- audit only, likely already safe)
- **Locality happiness advisory tasks:** 17 (8.9A.1-8.9A.5 happiness aggregation, 8.9B.1-8.9B.6 advisory threshold, 8.9C.1-8.9C.5 cross-region transfer, 8.9D quantum readiness notes)
- **Model lifecycle management tasks:** 8 (Phase 7.7.1-7.7.8: version schema, OTA delivery, compatibility gate, staged rollout, global rollback, per-user rollback, version display, storage budget)
- **Multi-device reconciliation tasks:** 6 (Phase 7.8.1-7.8.6: device-linked accounts, episodic merge, personality sync, tier-aware sync, device migration, conflict resolution)
- **Data transparency tasks:** 4 (Phase 2.1.8-2.1.8C: "What My AI Knows" page, "Why this recommendation?" tap-through, data correction mechanism, admin transparency dashboard)
- **Third-party data pipeline tasks:** 7 (Phase 9.2.6A-9.2.6G: insight catalog, DP noise injection, generation pipeline, consent gate, access control, buyer onboarding, revenue attribution)
- **Creator-side intelligence tasks:** 3 (Phase 6.1.13-6.1.15: community creator intelligence, event creator optimization, creator feedback loop)
- **Internationalization tasks:** 7 (Phase 10.3.1-10.3.7: ARB extraction, locale detection, RTL support, AI explanation localization, name handling, date/currency localization, locality agent language context)
- **Accessibility tasks:** 8 (Phase 10.4.1-10.4.8: semantic labels, screen reader navigation, color contrast, dynamic text, knot alt-text, haptic alternatives, audio sonification primary, reduce motion)
- **Quantum hardware readiness level:** Plug-in ready (5 operations documented with circuit designs in `CloudQuantumBackend`), 6 future quantum-native concepts documented as architecture notes (Phase 11.4B), **4 locality happiness quantum advantage points** documented (Phase 8.9D), 3 quantum communications readiness points (Phase 11.4E), sensor abstraction layer (Phase 11.4F)
- **NPU acceleration points:** 5 operations (state encoding, energy function, feature extraction, SLM inference, System 1 distilled model) documented with speedup estimates (Phase 11.4D)
- **Self-optimization engine tasks:** 77 (Phase 7.9A.1-7.9A.4 registry, 7.9B.1-7.9B.4 importance tracking, 7.9C.1-7.9C.6 experiment orchestrator, 7.9D.1-7.9D.4 ADMIN-ONLY notification pipeline, 7.9E.0-7.9E.7 safety guardrails with immutable meta-guardrail, 7.9F.1-7.9F.5 user request self-healing, 7.9G.1-7.9G.5 collective request aggregation, 7.9H.1-7.9H.6 DSL self-modification engine, 7.9I.1-7.9I.10 meta-learning engine with 7 immutable meta-guardrails, 7.9J.1-7.9J.6 self-interrogation system, 7.11.1-7.11.8 agent cognition & continuity, 7.12.1-7.12.8 observation & introspection service)
- **Friend system lifecycle tasks:** 10 (Phase 10.4A.1-10.4A.10: state machine, unfriend, block, braided knot evolution, tiering, community awareness, invite flow, cross-context chat, "friend joined" pipeline, friend cap)
- **Trending analysis tasks:** 4 (Phase 10.4B.1-10.4B.4: stub removal, real implementation, third-party wire, MPC wire)
- **Creator analytics tasks:** 4 (Phase 10.4C.1-10.4C.4: business, event, community dashboards, unified insights)
- **Decision audit trail tasks:** 4 (Phase 10.4D.1-10.4D.4: record model, on-device store, admin replay, outcome wire-back)
- **GDPR export tasks:** 3 (Phase 10.4E.1-10.4E.3: schema definition, generation pipeline, shared data handling)
- **BLE payload budget tasks:** 2 (Phase 6.6.6-6.6.7: payload schema, priority under contention)
- **Multi-transport AI2AI tasks:** 5 (Phase 6.6.8-6.6.12: WiFi local, WiFi Direct, VPN detection, transport selector, security hardening)
- **Data visibility feature source tasks:** 4 (Phase 3.1.20A-D: weather context, app usage, friend network, cross-app extraction)
- **Friendship outcome collection tasks:** 3 (Phase 1.2.27-1.2.29: lifecycle outcomes, "met through" attribution, friend-driven activity)
- **Cross-locality behavioral archetype tasks:** 6 (Phase 8.9E.1-8.9E.6: archetype model, distribution, timezone matching, cross-archetype segments, opposite testing, evolution tracking)
- **Services marketplace tasks:** 35 (Phase 9.4A.1-9.4A.4 quantum entity, 9.4B.1-9.4B.4 outcome collection, 9.4C.1-9.4C.4 energy function, 9.4D.1-9.4D.3 MPC actions, 9.4E.1-9.4E.3 provider dashboard, 9.4F.1-9.4F.3 legal/compliance, 9.4G.1-9.4G.3 AI2AI/federated, 9.4H.1-9.4H.8 tax/legal compliance automation incl. offline cache)
- **AI2AI transport types:** 3 (BLE always-available, WiFi local network same-subnet, WiFi Direct peer-to-peer consent-based)
- **Life Pattern Intelligence tasks:** 23 (7.10A.1-6 passive engine, 7.10B.1-5 privacy architecture, 7.10C.1-5 social quality-of-life, 7.10D.1-4 notification philosophy)
- **Active Life Pattern Engine (SLM) tasks:** see updated entry above (9 tasks, 12 tools)
- **Ad-hoc group formation tasks:** 5 (8.6B.1-5 group discovery, confirmation flow, partial coverage, energy scoring, service booking bridge)
- **Passive engine data points per day:** 101-116 (5-20 significant location changes + up to 96 widget checks)
- **Notification philosophy tiers:** 4 (NEVER ask location, RARELY labeling questions max 1/week, USER-INITIATED only, ACTIVE ENGINE dialogue natural)
- **Multi-dimensional happiness tasks:** 7 (Phase 4.5B.0-6 migration, decomposition, self-calibrating weights, self-adjusting dimensions, dynamic thresholds, trajectory prediction, professional fulfillment)
- **Happiness dimensions:** 6+ (discovery, social, routine_satisfaction, professional_fulfillment, growth, agent_trust -- extensible by self-optimization)
- **Hybrid expertise system tasks:** 11 (Phase 9.5.1-6 behavioral recognition, credential verification, hybrid scoring, success patterns, self-improving recognition, income pipeline + Phase 9.5B.1-5 partnership matching)
- **Partnership matching types:** 4 (business↔business, expert↔business, community↔brand, cross-instance via category model)
- **Admin platform modules:** 6 (system monitor, guardrail inspector, privacy audit, AI Code Studio, deployment manager, Value Intelligence)
- **Partner SDK components:** 4 (pre-built widgets, plugin architecture, conversational planning interface, tiered locality data access)
- **Locality data access tiers:** 4 (metro/city-wide, neighborhood/district, block-level premium, cross-locality enterprise)
- **White-label federation tasks:** 24 (Phase 13.1.1-5 instance architecture + seamless adoption, 13.2.1-6 fractal hierarchy + government + downward intelligence, 13.3.1-5 university lifecycle + graduation offboarding, 13.4.1-4 cross-instance learning/healing/adapting)
- **Federation hierarchy levels:** 4 (world → organization universe → category model → AVRAI universe)
- **Government hierarchy levels:** 4 (city → state/province → national → international body)
- **Context layer types:** 3 (white-label instance, public AVRAI, blended)
- **Credential verification levels:** 3 (verified, corroborated, self-reported)
- **University lifecycle stages:** 4 (freshman → sophomore → junior → senior, learned from category model) + graduation offboarding (13.3.5)
- **Admin platform tasks:** 60 (Phase 12.1.1-5 desktop app, 12.2.1-6 AI Code Studio, 12.3.1-5 Partner SDK, 12.4A.1-7 attribution engine, 12.4B.1-10 hindsight survey, 12.4C.1-7 stakeholder metrics, 12.4D.1-5 pilot toolkit, 12.4E.1-4 report generator, 12.4F.1-5 self-proving intelligence, 12.5.1-6 conviction oracle)
- **Meta-learning engine tasks:** 10 (Phase 7.9I.1-10 learning cycle ledger, causal graph, weekly meta-analysis, process optimization, meta-experiments, regression detection, learning narrative, velocity dashboard, cross-hierarchy federation, cycle-over-cycle comparison)
- **Meta-learning immutable guardrails:** 7 (bounded hyperparameters, canary-tested changes, human visibility, no privacy/security modification, no guardrail self-modification, learning velocity floor, battery/performance budget)
- **Meta-learning bounded hyperparameters:** 5 (consolidation frequency 1/week-2/day, canary size 1%-10%, experiment duration 7-30 days, federation rounds 1-10, signal weight multipliers 0.1x-10x)
- **Active Life Pattern Engine (SLM) tasks:** 9 (6.7B.1-9 intent extraction, tool-calling framework with 12 tools, conversational onboarding, routine confirmation, life change handling, schedule sharing, preference tuples, tier fallbacks, extended v16 tool set)
- **Value Intelligence System tasks:** 38 (Phase 12.4A.1-7 attribution engine, 12.4B.1-10 hindsight survey, 12.4C.1-7 stakeholder metrics, 12.4D.1-5 pilot toolkit, 12.4E.1-4 report generator + forecast, 12.4F.1-5 self-proving intelligence)
- **Conviction Oracle tasks:** 6 (Phase 12.5.1-6 universe conviction store, conversational query interface, creator admin privileges, conviction narrative generation, physical isolation/security, simulation sandbox)
- **Attribution tiers:** 4 (Direct AI, Platform-Facilitated, Ecosystem, Ambient) + Non-AVRAI control
- **Multi-touch attribution models:** 5 (first-touch, last-touch, even distribution, decay-weighted, bookend)
- **Stakeholder value metric types:** 7 (individual user, university, corporate, government, business, expert/service provider, investor/board)
- **Hindsight survey formats:** 5 (micro-survey 1-tap, comparative cards, SLM conversational reflection, batched reflection session, longitudinal check-in)
- **Anti-survey fatigue guardrails:** hard cap 2 touches/week, new user 1/2 weeks, 50 interaction ramp, 200 interaction full, 3-ignore backoff, never modal, never blocks content
- **Pilot framework components:** 5 (design wizard, baseline capture, statistical analysis, pilot-to-full conversion, decay testing)
- **Self-proving intelligence signals:** 5 (world model accuracy trajectory, meta-learning velocity, happiness trajectory, federation contribution, fractal aggregation)
- **Knowledge-Wisdom-Conviction tasks:** 9 (Phase 1.1D.1-9 knowledge store, wisdom layer, conviction formation, conviction challenge, fractal bottom-up, fractal top-down, emotional experience vector, conviction serialization, insight preservation)
- **Conviction formation criteria:** 4 (100+ validated outcomes, 90+ days consistent, survived 1+ challenges, scope-level validation)
- **Emotional context dimensions:** 4 (primary emotion, secondary emotion, intensity, valence)
- **Emotion types tracked:** 7 (joy, sadness, anger, fear, surprise, disgust, neutral) + mixed
- **Self-interrogation tasks:** 6 (Phase 7.9J.1-6 conviction review, cross-scope comparison, stress testing, human challenger, audit trail, constructive disruption)
- **Agent cognition tasks:** 8 (Phase 7.11.1-8 AgentContext, thinking scheduler, multi-horizon reasoning, proactive thinking, platform continuity, self-scheduled triggers, thinking as meta-learning, continuity narrative)
- **Agent thinking horizons:** 3 (short: hours/1-3 steps, medium: days-weeks/5-7 steps, long: months-seasons/conviction-weighted)
- **Platform continuity strategies:** 2 (iOS: BGAppRefreshTask + BGProcessingTask + CoreLocation, Android: WorkManager + ForegroundService + AlarmManager)
- **Composite entity identity tasks:** 5 (Phase 9.6.1-5 composite model, cross-role learning, unified dashboard, role discovery, energy function composite bonus)
- **Researcher access pathway tasks:** 7 (Phase 14.1-7 anonymization, IRB consent, research API, longitudinal cohorts, sandbox, dashboard, feedback loop)
- **Research anonymization guarantees:** 4 (k-anonymity k=20, l-diversity, t-closeness, temporal obfuscation)
- **Research API endpoints:** 6 (cohorts, happiness-trajectories, community-dynamics, conviction-evolution, world-model-accuracy, cross-cultural-patterns)
- **Humanity mapping aspects:** 16 (perception, memory, knowledge, wisdom, conviction, emotion, connection, growth, purpose, identity, community, impermanence, the pursuit, awareness, agency, resilience)
- **Sensory architecture components:** 5 (eyes/observation bus, ears/input normalization, mouth/output delivery, senses/sensor abstraction, brain/decision core)
- **Translation layer tasks:** 7 (Phase 6.7C.1-7: semantic bridge schema, output format registry, format-to-semantics translator, self-healing format optimization, self-healing vocabulary evolution, grounding enforcement, round-trip validation)
- **Observation service tasks:** 8 (Phase 7.12.1-8: observation bus, health reporter protocol, self-model service, attribution tracing, anomaly detector, opportunity detector, cross-feed protocol, observation bus federation)
- **Hardware abstraction tasks:** 3 active (Phase 11.4C.1-3: hardware compute router, NPU detection, ONNX delegate selection) + architecture notes (11.4D-F)
- **Hardware tiers:** 3 (Classical CPU always-available, AI chip/NPU on flagship devices, Cloud quantum future)
- **Enforced methodology principles:** 13 (doors not badges, authenticity preservation, 40-min context, ai2ai architecture, intelligence-first, chat-as-accelerator, packaging, quantum-ready, agent happiness philosophy, user agency doctrine, universal self-healing, reality model, human condition spectra doctrine)
- **Total phases:** 15 (Phases 1-15)

### D. On-Device Storage Budget

| Component | Size |
|-----------|------|
| World model (4 ONNX models, current + 1 rollback per Phase 7.7.8) | ~2MB |
| Existing skill models (4 ONNX) | ~50KB |
| Episodic memory (SQLite) | ~5-50MB over time |
| Semantic memory (vector store) | ~1-5MB |
| Routine model + deviation history (Phase 7.10A) | ~1-3MB |
| DSL rule store + experiment cache (Phase 7.9H) | ~0.5-2MB |
| Learning Cycle Ledger + meta-analysis cache (Phase 7.9I) | ~1-5MB/year |
| Multi-dimensional happiness model (Phase 4.5B) | ~0.1-0.5MB |
| Expertise scores + credential cache (Phase 9.5) | ~1-5MB |
| Context layer identities + federation metadata (Phase 13) | ~0.5-2MB |
| Attribution chain cache + survey receptivity model (Phase 12.4) | ~1-5MB |
| Jurisdiction tax/legal rule cache (Phase 9.4H) | ~0.5-2MB |
| Knowledge + wisdom + conviction store (Phase 1.1D) | ~2-10MB |
| AgentContext working memory (Phase 7.11) | ~0.05MB (50KB max) |
| Conviction audit trail + challenge history (Phase 7.9J) | ~0.5-3MB/year |
| Preserved high-information insights (Phase 1.1D.9) | ~0.5-2MB |
| Observation bus self-model snapshots (Phase 7.12) | ~0.5-2MB |
| Semantic Bridge vocabulary cache (Phase 6.7C) | ~0.1-0.5MB |
| Output format registry (Phase 6.7C.2) | ~0.01MB |
| Hardware compute profile cache (Phase 11.4C) | ~0.01MB |
| ARB localization bundles (Phase 10.3) | ~2-5MB |
| Optional SLM (1-3B) | 700MB-2GB |
| **Total without SLM** | **~21-112MB** |
| **Total with SLM** | **~721MB-2.1GB** |

---

### E. External Research Cross-Reference Execution Additions (2026-02-15)

This plan adopts `docs/plans/architecture/EXTERNAL_RESEARCH_CROSS_REFERENCE_2026-02-15.md` as an active execution contract.

Mandatory additions now enforced across phases:

1. **Distal objective planning is required**
- Phase 5/6 evidence must prove optimization against real-world outcomes, not engagement-only proxies.

2. **Hard-start recovery is required**
- Predictor/planner must pass adversarial initial state recovery benchmarks before rollout.

3. **Self-questioning evidence is required**
- Phase 7 evidence must include conviction challenge execution and outcome-linked revision logs.

4. **Bounded self-improvement is required**
- All autonomous optimization stays within explicit bounds, canary policy, and rollback guarantees.

5. **Quantum backend parity is required**
- Phase 11 hardware abstraction must prove contract parity and automatic classical fallback before any quantum-path rollout.

6. **Post-quantum agility is required**
- Crypto/transport changes must include algorithm/key agility evidence under Phase 2/6.6 controls.

These additions are release-gated by:
- `docs/plans/architecture/REALITY_COHERENCE_TEST_MATRIX.md`
- `docs/plans/architecture/MASTER_PLAN_ARCHITECTURE_IMPLEMENTATION_CHECKLIST.md`
- `docs/plans/quantum_computing/QUANTUM_COMPUTING_RESEARCH_AND_INTEGRATION_TRACKER.md`

Execution artifacts for immediate planning updates:
- `docs/plans/architecture/EXTERNAL_RESEARCH_EXECUTION_BACKLOG_2026-02-15.md`
- `docs/plans/architecture/PATENT_RISK_CLAIM_CHECKLIST_2026-02-15.md`

---

### F. Immediate Master Plan Update Pack (2026-02-15)

This section promotes the external-research execution pack into immediate Master Plan scope.

Required immediate story execution by phase:

| Phase | Stories | Objective |
|---|---|---|
| 2 | `MPA-P2-E5-S1`, `MPA-P2-E5-S2` | Post-quantum agility runbook + claim-sensitive privacy language guardrails |
| 3 | `MPA-P3-E4-S1`, `MPA-P3-E4-S2` | Claim-sensitive matching contract + graph-encoder contract with parity fallback |
| 5 | `MPA-P5-E4-S1`, `MPA-P5-E4-S2` | Hard-start recovery benchmark + distal-objective alignment evidence schema |
| 6 | `MPA-P6-E4-S1`, `MPA-P6-E4-S2` | Planner objective non-negotiable + claim-sensitive notification policy |
| 7 | `MPA-P7-E5-S1`, `MPA-P7-E5-S2` | Conviction challenge evidence + bounded self-improvement evidence bundle |
| 10 | `MPA-P10-E6-S1`, `MPA-P10-E6-S2` | Patent claim checklist maintenance + monthly prosecution/watch update |
| 11 | `MPA-P11-E4-S1`, `MPA-P11-E4-S2` | Quantum parity/fallback tests + readiness gate evidence package |

Execution authority:
- `docs/plans/architecture/EXTERNAL_RESEARCH_EXECUTION_BACKLOG_2026-02-15.md`
- `docs/plans/architecture/PATENT_RISK_CLAIM_CHECKLIST_2026-02-15.md`

Phase gate requirement:
- Stories above must be mapped to `RCM-*` scenarios and attached evidence in phase exit packages.

---

**Last Updated:** February 15, 2026 (v20.13 -- Added Immediate Master Plan Update Pack (Section F) and promoted the external research execution stories (`MPA-P2-E5-*`, `MPA-P3-E4-*`, `MPA-P5-E4-*`, `MPA-P6-E4-*`, `MPA-P7-E5-*`, `MPA-P10-E6-*`, `MPA-P11-E4-*`) into explicit phase-linked Master Plan scope with RCM evidence requirements. Previous: v20.12 -- Added external research cross-reference execution contract (`docs/plans/architecture/EXTERNAL_RESEARCH_CROSS_REFERENCE_2026-02-15.md`) and hard-gated additions for distal-objective planning, hard-start recovery, bounded self-improvement, self-questioning evidence, quantum parity/fallback, and post-quantum agility; synchronized gating to coherence matrix, checklist, and quantum tracker. Previous: v20.11 -- Added canonical `docs/plans/architecture/REALITY_COHERENCE_TEST_MATRIX.md` and made phase-by-phase coherence testing explicit across offline/online arbitration, BLE/WiFi adaptation, weather/environment confidence + fallback, self-healing coverage, federation integrity, security/access/no-go blockers, and cohesive build evidence requirements. Previous: v20.10 -- Added Phase 2.8 System Coherence & Connectivity Contract to close system-integration gaps: explicit end-to-end connectedness requirements for learning/world/environment/transport/federation paths, offline-first arbitration with adaptive mode learning + admin visibility, weather/environment confidence + fallback handling, and cohesive build integration gates. Previous: v20.9 -- Added explicit non-delegable human authorization gates in Phase 2 access governance (security/legal boundary changes, break-glass access, policy exceptions, irreversible cutovers) and linked them to the canonical identity/access contract for operational enforcement. Previous: v20.8 -- Added canonical contract artifact `docs/plans/architecture/IDENTITY_UNLINKABILITY_AND_ACCESS_GOVERNANCE_CONTRACT.md` and aligned identity/access/migration language for uniform plan enforcement across architecture and orchestration docs. Previous: v20.7 -- Strengthened security/unlinkability contracts: clarified non-harm doctrine as an enforceable ongoing property, added Phase 2.6 matrix robustness requirements (fail-closed, non-bypass, drift detection, break-glass controls), and added Phase 2.7 identity migration contract (bounded dual-read/dual-write window, parity gates, strict cutoff enforcement). Previous: v20.6 -- Added Phase 2.6 Global Access Governance Matrix (all features/services): access planes, role x plane matrix, tier model, enforcement rules, and cross-cutting implementation tasks. Updated Phase 15 disclosure governance to defer to Phase 2.6 policy engine. Previous: v20.5 -- Added Phase 15 Human Condition Spectra (spectrum inference contract, state/trait/phase learning rules, user-facing conviction challenge controls, cross-scope tension engine, spectrum safety guardrails, federated spectrum learning, evaluation metrics). Previous: v20.4 -- Updated Phase 10.11 design-linkage contracts to include `docs/design/DESIGN_REF.md` as required UI/UX entrypoint and explicit `docs/design/apps/*` app-scope references for orchestration planning. Previous: v20.3 -- Added Phase 10.11 Phase Execution Orchestration Contracts (GitHub + Cursor), including machine-readable phase dependency contract, automated validation workflow, trigger interface, PR metadata requirements, cursor-rule enforcement, and UI/UX design linkage across app types. Previous: v20.2 -- Added Phase 10.10 File/Folder Canonicalization & Rename Migration Contracts, including canonical rename manifest artifact, wave-based conversion model, test co-migration contract, and rename verification gate linked to tracker/checklist controls. Previous: v20.1 -- Added Phase 10.9 Test Suite Path Normalization & Grouped Suite Contracts, including canonical path map artifact, design golden grouping requirement, and zero-missing-reference gate for grouped suite readiness. Previous: v20 -- Sensory Architecture & Reality Model update. NEW SECTIONS: Phase 6.7C Reality-to-Language Translation Layer (7 tasks: semantic bridge schema, output format registry, format-to-semantics translator, self-healing format optimization, self-healing vocabulary evolution, grounding enforcement, round-trip validation). Phase 7.12 Unified Observation & Introspection Service \"Eyes\" (8 tasks: observation bus, component health reporter, self-model service, attribution tracing, anomaly detector, opportunity detector, cross-feed protocol, observation bus federation). Phase 11.4C-F Hardware Abstraction Hierarchy (3 active tasks: hardware compute router, NPU detection, ONNX delegate selection + architecture notes for NPU acceleration points, quantum communications readiness, sensor abstraction layer). NEW TOP-LEVEL ARCHITECTURE: Sensory Architecture Mapping table (5 senses: eyes/observation, ears/input normalization, mouth/output delivery, senses/raw acquisition, brain/decision core with cross-feeding protocol). Agent Happiness Philosophy (predictions are metrics not baselines, both outcomes valuable). User Agency Doctrine (non-participation is valid signal, over-suggestion triggers reduction). Universal Self-Healing Doctrine (every non-guardrail component can diagnose and improve itself via observation bus). Reality Model Definition (world models → universe models → reality, grounded in behavior not language). UPDATED: LeCun Framework Mapping +7 rows. Humanity Mapping +3 rows (awareness, agency, resilience). Phase 6 name/duration (10-13 weeks, +Translation Layer). Phase 7 name/duration (16-20 weeks, +Observation Service). Phase 11 name (+Hardware Abstraction). Phase 5, 8, 13 headers with Reality Model Role annotations. Execution Index synchronized. Appendix C updated (self-optimization tasks 69→77, humanity mapping 13→16, +sensory/translation/observation/hardware stats). Appendix D +4 storage entries. Representations That Survive +6 entries. Self-optimization tasks: 69→77. Total tasks: 548→566+. Previous: v19 -- Conviction Oracle. Previous: v18.1 -- Audit fixes. Previous: v18 -- Knowledge-Wisdom-Conviction Architecture, Agent Cognition, Self-Interrogation, Researcher Access, Composite Entities, Emotional Experience, Humanity Mapping. NEW SECTIONS: Phase 1.1D Conviction Memory (9 tasks: knowledge store, wisdom layer, conviction formation with 4-criteria promotion, conviction challenge protocol, fractal bottom-up/top-down flow, emotional experience vector with 7 emotion types, conviction serialization for federation, insight preservation/genius capture). Phase 7.9J Self-Interrogation System (6 tasks: conviction review scheduler, cross-scope comparison, stress testing, human challenger integration, conviction audit trail, constructive disruption protocol). Phase 7.11 Agent Cognition & Continuity (8 tasks: persistent AgentContext working memory, thinking session scheduler using BGProcessingTask/WorkManager, multi-horizon reasoning with 3 horizons, proactive thinking aloud, platform-specific continuity strategies, self-scheduled triggers, thinking as meta-learning input, agent continuity narrative). Phase 9.6 Composite Entity Identity (5 tasks: composite entity model with entity_root_id, cross-role learning via conviction system, unified dashboard, role discovery from behavior, energy function composite bonus). Phase 14 Researcher Access Pathway (7 tasks: research-grade anonymization with k-anonymity/l-diversity/t-closeness, IRB-compatible consent, research API with 6 endpoints, longitudinal cohorts, research sandbox, researcher dashboard, research feedback loop into conviction system). NEW: Humanity Mapping table (13 aspects of human experience mapped to AVRAI components). UPDATED: LeCun mapping table +7 rows (knowledge-wisdom-conviction, self-interrogation, agent cognition, composite entity, researcher access, emotional experience, humanity mapping). Representations That Survive +15 entries. Appendix A +6 entries. Appendix C new statistics. On-device storage +3-15MB for conviction/knowledge/AgentContext/audit. Total phases: 14. Previous: v17 Value Intelligence System)  
**Source of Truth:** `docs/agents/reports/ML_SYSTEM_DEEP_ANALYSIS_AND_IMPROVEMENT_ROADMAP.md`
