# AVRAI Reality Model Gap Map

**Date:** March 9, 2026  
**Status:** Active assessment  
**Purpose:** Define what the reality model owns now, what is missing, and what is misplaced in `runtime/*` or `apps/*` and must move into `engine/*`.

---

## 1. Terminology Lock

AVRAI is building a **reality model**.

The repo still contains many historical references to **world model**. Those references describe the same prediction/planning substrate, but the canonical term going forward should be:

1. `reality model` for AVRAI's learned truth, prediction, memory, and planning substrate
2. `runtime OS` for orchestration, governance, policy, transport, identity, and execution
3. `apps` for UI and product workflows only

Where legacy documents or file names still say `world model`, interpret that as legacy terminology unless a broader research comparison explicitly requires the phrase.

---

## 2. Canonical Boundary

Per the 3-prong architecture, the reality model must own:

1. state encoding
2. action encoding
3. transition prediction
4. energy scoring
5. planning internals
6. memory systems and learning contracts
7. model-side truth and deterministic interfaces

Runtime OS must own:

1. ingestion and endpoint orchestration
2. transport and AI2AI routing
3. privacy, consent, policy, canary, rollback, lineage
4. host/device adapters
5. scheduling and execution control

Apps must own:

1. UI
2. local product workflows
3. composition of runtime-facing surfaces only

---

## 3. Honest Current State

The repo has a **real mathematical substrate** in `engine/avrai_knot` and `engine/avrai_quantum`, but the actual `engine/reality_engine` package is still tiny.

Current engine reality-model package contents:

1. `engine/reality_engine/lib/memory/air_gap/tuple_extraction_engine.dart`
2. `engine/reality_engine/lib/memory/semantic_knowledge_store.dart`

This means the intended reality-model owner exists structurally, but most prediction, scoring, memory, and learning behavior still lives elsewhere.

At the same time, `runtime/avrai_runtime_os/lib/ml/*`, `runtime/avrai_runtime_os/lib/services/prediction/*`, and several `runtime/avrai_runtime_os/lib/ai/*` files contain reality-model logic or reality-model placeholders.

The current architecture therefore has **doctrine drift**:

1. the docs say reality-model internals belong in `engine/*`
2. the file layout still leaves many of those internals in `runtime/*`
3. app DI still knows too much about engine wiring

---

## 4. What Is Already Real

These are legitimate reality-model inputs and should remain engine-owned:

1. `engine/avrai_knot/lib/services/knot/*`
2. `engine/avrai_quantum/lib/services/quantum/*`
3. `engine/reality_engine/lib/memory/air_gap/*`

These systems are not the finished reality model, but they are real substrate:

1. knot topology and deterministic matching
2. quantum state and entanglement math
3. privacy-preserving tuple extraction boundary
4. worldsheet and fabric representations as future state features

The correct future is to make these inputs to the reality model, not parallel scoring silos.

---

## 5. Missing Core Reality Model Pieces

The critical missing pieces in `engine/reality_engine` are:

1. `StateEncoder`
2. `ActionEncoder`
3. `TransitionPredictor`
4. `EnergyFunction`
5. `MPCPlanner`
6. `EpisodicMemoryStore`
7. `SemanticMemoryStore` backed by durable storage, not only in-memory mock
8. `ProceduralMemory` / learned heuristics
9. model lifecycle contracts colocated with model internals
10. reality-model bootstrap modules that runtime can consume through contracts

Until those exist in `engine/reality_engine`, the architecture remains conceptually correct but materially incomplete.

---

## 6. Misplaced In Runtime: Must Move To Engine

These are not runtime concerns. They are reality-model concerns and should move into `engine/*`.

### 6.1 Prediction And Learned Scoring

Move to `engine/reality_engine/lib/models/` or `engine/reality_engine/lib/inference/`:

1. `runtime/avrai_runtime_os/lib/ml/calling_score_neural_model.dart`
2. `runtime/avrai_runtime_os/lib/ml/outcome_prediction_model.dart`
3. `runtime/avrai_runtime_os/lib/ml/onnx_dimension_scorer.dart`
4. `runtime/avrai_runtime_os/lib/services/prediction/engagement_phase_predictor.dart`
5. `runtime/avrai_runtime_os/lib/services/prediction/markov_engagement_predictor.dart`
6. `runtime/avrai_runtime_os/lib/services/prediction/markov_transition_store.dart`
7. `runtime/avrai_runtime_os/lib/services/prediction/engagement_phase_classifier.dart`
8. `runtime/avrai_runtime_os/lib/services/prediction/swarm_prior_loader.dart`

Reason:

1. these files encode state evolution or learned scoring logic
2. runtime should call them, not own them
3. the Markov bridge is explicitly a temporary transition predictor precursor and therefore belongs in the same prong as the future learned predictor

### 6.2 Personality / Vibe State Construction

Move to `engine/reality_engine/lib/state/` or `engine/avrai_ai/lib/` as engine-owned package modules:

1. `runtime/avrai_runtime_os/lib/ai/personality_learning.dart`
2. `runtime/avrai_runtime_os/lib/ai/vibe_analysis_engine.dart`
3. `runtime/avrai_runtime_os/lib/ml/location_pattern_analyzer.dart`
4. `runtime/avrai_runtime_os/lib/ml/preference_learning.dart`
5. `runtime/avrai_runtime_os/lib/ml/pattern_recognition_system.dart`
6. `runtime/avrai_runtime_os/lib/ml/predictive_analytics.dart`
7. `runtime/avrai_runtime_os/lib/ml/social_context_analyzer.dart`

Reason:

1. personality state construction is part of model truth
2. vibe/state inference is perception, not runtime orchestration
3. preference and pattern learning are reality-model learning loops, not OS policy

### 6.3 Memory And Distillation

Move model-side storage and extraction into `engine/reality_engine/lib/memory/`:

1. `runtime/avrai_runtime_os/lib/ai/facts_index.dart`
2. `runtime/avrai_runtime_os/lib/ai/facts_local_store.dart`
3. `runtime/avrai_runtime_os/lib/ai/structured_facts_extractor.dart`

Reason:

1. facts extraction and semantic memory are model knowledge formation
2. runtime may provide sync adapters, but not own the memory abstraction itself
3. the repo already states episodic and semantic memory belong under engine memory

### 6.4 Quantum / Matching Internals Still Sitting In Runtime

Large parts of `runtime/avrai_runtime_os/lib/ai/quantum/*` and related scoring helpers should migrate into engine-owned quantum or reality-model modules, especially:

1. `runtime/avrai_runtime_os/lib/ai/quantum/quantum_vibe_engine.dart`
2. `runtime/avrai_runtime_os/lib/ai/quantum/quantum_feature_extractor.dart`
3. `runtime/avrai_runtime_os/lib/ai/quantum/quantum_ml_optimizer.dart`
4. `runtime/avrai_runtime_os/lib/ai/quantum/location_compatibility_calculator.dart`
5. `runtime/avrai_runtime_os/lib/ai/quantum/quantum_entanglement_ml_service.dart`

Reason:

1. quantum features are contributors to model truth
2. the URK doctrine explicitly treats quantum outputs as Prong 1 contributors
3. keeping them in runtime creates duplicate ownership between `engine/avrai_quantum` and runtime

---

## 7. Split Cases: Part Engine, Part Runtime

These should not simply stay where they are, but they also should not move as-is.

### 7.1 Inference Orchestration

Split `runtime/avrai_runtime_os/lib/ml/inference_orchestrator.dart` into:

1. engine-owned local inference runner for state/action/energy/transition model execution
2. runtime-owned routing policy for `device_first`, cloud fallback, or external tool expansion

Reason:

1. model execution is reality-model internals
2. transport/fallback strategy is runtime policy

### 7.2 Continuous Learning / Federated Updates

Split:

1. `runtime/avrai_runtime_os/lib/ai/continuous_learning_system.dart`
2. `runtime/avrai_runtime_os/lib/ai/federated/*`
3. `runtime/avrai_runtime_os/lib/ai2ai/federated_learning_hooks.dart`

Into:

1. engine-owned learning-update logic, delta application semantics, and parameter mutation rules
2. runtime-owned scheduling, networking, privacy mode enforcement, DP/noise application, and delivery plumbing

### 7.3 Facts Sync

Split `FactsIndex` into:

1. engine-owned semantic memory interface and local store
2. runtime-owned remote sync adapter and connectivity-aware sync job

---

## 8. What Should Stay In Runtime

These belong in runtime and should not move:

1. AI2AI transport and anonymous communication
2. policy, consent, no-egress, canary, rollback, lineage, human override
3. device capability gates and host adapters
4. endpoint handlers and trigger services
5. scheduling jobs and background wake pathways
6. remote sync plumbing and external service adapters

Runtime should ask the reality model for predictions and plans, then govern and execute them.

---

## 9. What Is Misplaced In Apps

### 9.1 Engine Composition In App DI

These app-side files currently know too much about engine/runtime internals:

1. `apps/avrai_app/lib/bootstrap/engine_bootstrap.dart`
2. `apps/avrai_app/lib/di/registrars/engine_service_registrar.dart`
3. `apps/avrai_app/lib/di/registrars/injection_container_knot.dart`
4. `apps/avrai_app/lib/di/registrars/injection_container_quantum.dart`
5. `apps/avrai_app/lib/di/registrars/injection_container_ai.dart`

This is not necessarily "engine logic in app", but it is **engine ownership leakage into app composition**.

Target:

1. apps compose runtime-facing bootstrap only
2. runtime composes engine contracts
3. engine packages expose registration/bootstrap hooks from engine-owned modules, not app-owned registrars

### 9.2 Terminology Drift In App Surface

`apps/avrai_app/lib/presentation/pages/chat/world_model_ai_page.dart` should be renamed to a reality-model-consistent surface, for example:

1. `reality_model_ai_page.dart`
2. `agent_reality_page.dart`
3. `reality_chat_page.dart`

This is naming, not ownership, but it matters because it encodes the wrong conceptual boundary in the product surface.

---

## 10. Required Terminology Normalization

The following should be normalized from `world model` to `reality model` over time:

1. app page names and visible UI copy
2. execution board phase names
3. runtime README scaffolds under `runtime/.../ai/world_model/*`
4. training and planning docs that refer to the internal AVRAI stack rather than external research comparison

Exception:

1. external research comparisons may still mention "world model" when discussing LeCun or other outside frameworks

---

## 11. Recommended Move Order

### Wave 1: Boundary Correction

1. Move prediction interfaces and Markov bridge from runtime to engine
2. Move `OnnxDimensionScorer` into engine
3. move facts extraction/local semantic memory interfaces into engine
4. rename app `world_model` page and product copy to `reality model`

### Wave 2: State Ownership

1. move `PersonalityLearning` into engine
2. move `UserVibeAnalyzer` into engine
3. move quantum feature extraction and compatibility internals into engine-owned modules

### Wave 3: Execution Split

1. split inference orchestration into engine execution vs runtime routing
2. split continuous learning into engine update logic vs runtime transport/scheduling
3. leave runtime with only governance, routing, and action control

---

## 12. Bottom Line

AVRAI's architecture is directionally correct, but the current implementation still places too much reality-model logic in runtime and too much engine wiring in the app layer.

The most important correction is simple:

1. **Reality model owns truth, memory, prediction, and planning**
2. **Runtime OS owns orchestration, policy, and execution**
3. **Apps own UI only**

Until that move happens, AVRAI will keep carrying reality-model logic in the wrong prong and will keep paying integration complexity for it.
