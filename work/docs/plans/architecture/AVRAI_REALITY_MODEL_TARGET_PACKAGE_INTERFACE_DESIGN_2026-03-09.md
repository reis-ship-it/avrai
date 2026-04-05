# AVRAI Reality Model Target Package And Interface Design

**Date:** March 9, 2026  
**Status:** Target architecture  
**Purpose:** Define the concrete package boundaries, public interfaces, and app/runtime/engine wiring for the AVRAI reality model.

---

## 1. Design Decision Summary

### 1.1 What the app should depend on

The app should depend directly on:

1. `avrai_core`
2. `avrai_runtime_os`

The app should **not** depend directly on:

1. `reality_engine`
2. `avrai_knot`
3. `avrai_quantum`
4. `avrai_ai`

Those engine packages should be transitively included through `avrai_runtime_os`.

### 1.2 What runtime should depend on

`avrai_runtime_os` should depend directly on:

1. `avrai_core`
2. `reality_engine`
3. engine-owned subpackages such as `avrai_knot`, `avrai_quantum`, `avrai_ai`
4. runtime-owned networking and device packages

Runtime is the composition root.

### 1.3 What the reality model should be

The reality model is:

1. an engine-owned local cognition package
2. on-device by default
3. callable only through runtime-owned ports
4. bundled into the app transitively as code
5. backed by on-device model assets and on-device memory stores

---

## 2. Package Graph

Target package graph:

```text
apps/avrai_app
  depends on:
    - shared/avrai_core
    - runtime/avrai_runtime_os

runtime/avrai_runtime_os
  depends on:
    - shared/avrai_core
    - engine/reality_engine
    - engine/avrai_ai
    - engine/avrai_knot
    - engine/avrai_quantum
    - runtime/avrai_network

engine/reality_engine
  depends on:
    - shared/avrai_core
    - engine/avrai_ai
    - engine/avrai_knot
    - engine/avrai_quantum

engine/avrai_ai
engine/avrai_knot
engine/avrai_quantum
  depend on:
    - shared/avrai_core

shared/avrai_core
  depends on:
    - nothing above it
```

Dependency direction remains:

`apps -> runtime -> engine -> shared`

---

## 3. Where The Reality Model Lives

The reality model should live in `engine/reality_engine`.

It should own:

1. state encoding
2. action encoding
3. reality-state feature fusion
4. transition prediction
5. energy scoring
6. planning
7. episodic memory
8. semantic memory
9. procedural memory
10. local model lifecycle and versioning contracts

Suggested internal layout:

```text
engine/reality_engine/lib/
  reality_engine.dart
  bootstrap/
    reality_model_bootstrap.dart
  contracts/
    reality_model_contract.dart
    reality_model_types.dart
    reality_model_version.dart
  state/
    state_encoder.dart
    action_encoder.dart
    reality_feature_fusion.dart
  memory/
    episodic_memory_store.dart
    semantic_memory_store.dart
    procedural_memory_store.dart
    air_gap/
  models/
    energy_function.dart
    transition_predictor.dart
    planner/
      mpc_planner.dart
      candidate_generator.dart
      guardrail_constraints.dart
  training/
    on_device_training_coordinator.dart
    federated_delta_contract.dart
  adapters/
    knot_feature_adapter.dart
    quantum_feature_adapter.dart
    ai_feature_adapter.dart
```

---

## 4. Public Engine Interface

`reality_engine` should expose one narrow primary contract.

Suggested public API:

```dart
abstract class RealityModelContract {
  Future<RealityModelSnapshot> observe(
    RealityObservationRequest request,
  );

  Future<RealityModelPlan> plan(
    RealityPlanningRequest request,
  );

  Future<RealityModelEvaluation> evaluate(
    RealityEvaluationRequest request,
  );

  Future<void> commitOutcome(
    RealityOutcomeCommit request,
  );

  Future<RealityModelExplanation> explain(
    RealityExplanationRequest request,
  );
}
```

Supporting contract objects should all live in `avrai_core` or `reality_engine/contracts`, depending on whether runtime must consume them directly.

Minimum contract types:

1. `RealityObservationRequest`
2. `RealityPlanningRequest`
3. `RealityEvaluationRequest`
4. `RealityOutcomeCommit`
5. `RealityExplanationRequest`
6. `RealityModelSnapshot`
7. `RealityModelPlan`
8. `RealityModelEvaluation`
9. `RealityModelExplanation`
10. `RealityModelHealthReport`

---

## 5. Runtime Interface To The Reality Model

Runtime should not reach into arbitrary engine services.
It should depend on one adapter/facade.

Suggested runtime-owned adapter:

```dart
abstract class RealityModelPort {
  Future<RealityModelPlan> buildPlan({
    required KernelEventEnvelope envelope,
    required RealityKernelFusionInput fusionInput,
  });

  Future<RealityModelEvaluation> evaluateCandidate({
    required KernelEventEnvelope envelope,
    required RealityKernelFusionInput fusionInput,
    required RealityCandidate candidate,
  });

  Future<void> recordOutcome({
    required KernelEventEnvelope envelope,
    required RealityObservedOutcome outcome,
  });

  Future<RealityModelExplanation> explainDecision({
    required KernelEventEnvelope envelope,
    required RealityDecisionTrace trace,
  });
}
```

Runtime implementation:

```text
runtime/avrai_runtime_os/lib/reality/
  reality_model_runtime_adapter.dart
  reality_model_input_mapper.dart
  reality_model_output_mapper.dart
  reality_model_policy_bridge.dart
```

This adapter should be the only place where runtime knows about `RealityModelContract`.

---

## 6. Kernel Placement

The six kernels:

1. `who`
2. `what`
3. `when`
4. `where`
5. `why`
6. `how`

should stay in `runtime/*`, not `engine/*`.

Reason:

1. they are kernel-grade mediation and governance surfaces
2. they provide observation, projection, execution, inspectability, and policy pathways
3. they are constitutional runtime surfaces, not learned model internals

The reality model should consume their outputs, not own them.

Correct relationship:

```text
app event
  -> runtime kernels resolve who/what/when/where/why/how
  -> runtime builds RealityKernelFusionInput
  -> runtime calls reality model
  -> reality model returns evaluation/plan
  -> runtime governs and executes
  -> app renders
```

This means:

1. kernel contracts stay in runtime
2. kernel projections become structured inputs to the reality model
3. the reality model stays engine-owned

---

## 7. App Wiring

The app should talk to runtime-owned facades and hosts only.

Suggested app-visible entry points:

1. `HeadlessAvraiOsHost`
2. `RecommendationFacade`
3. `AgentConversationFacade`
4. `RealityInspectionFacade`

The app should never construct engine classes directly.

Suggested app usage pattern:

```dart
final plan = await headlessOsHost.buildModelTruth(
  envelope: envelope,
  whyRequest: whyRequest,
);
```

Then app-facing controllers should sit above that and convert to UI state.

Suggested app folder rule:

```text
apps/avrai_app/lib/
  presentation/
  product_workflows/
  host_adapters/
```

No app widget/page/controller should import `reality_engine`, `avrai_knot`, or `avrai_quantum`.

---

## 8. Runtime API Rule

`runtime_api.dart` should be drastically narrowed.

It should export:

1. runtime-safe DTOs
2. runtime-owned facades
3. shared contracts
4. app-safe enums and value types

It should **not** export:

1. raw knot services
2. raw quantum services
3. raw reality-engine services
4. raw engine internals used only for model composition

If an app feature needs knot data or quantum-derived values, runtime should provide a dedicated facade or DTO.

---

## 9. Should The Reality Model Be On Device?

Yes.

The target architecture says the reality model should be on-device for core operation.

That includes:

1. state encoding
2. action encoding
3. energy scoring
4. transition prediction
5. MPC planning
6. local memory formation

This is not just your intuition; it is already the repo's design direction.

Why:

1. privacy
2. latency
3. offline usefulness
4. local-first cognitive authority

Cloud may still be used for:

1. model pack delivery
2. federated aggregation
3. optional cloud explanation fallback on lower-tier devices
4. backup and sync

But cloud should not be required for core reality-model cognition.

---

## 10. Should The Offline SLM Also Be On Device?

Yes, but with an important distinction:

1. the reality model is the brain
2. the SLM is the mouth

The SLM should also be on-device where device tier allows it.

Target rule:

1. Tier 3 devices: on-device SLM available
2. Tier 2 devices: no local SLM required; use template explanations
3. Tier 1 or below: template explanations offline, optional cloud LLM online

The SLM should not be required for the reality model to function.

The SLM's role is:

1. explanation generation
2. conversational translation of model outputs
3. optional summary generation during memory consolidation
4. optional onboarding/open-response parsing

The SLM should not own planning, scoring, or truth.

---

## 11. Packaging Rule For On-Device Deployment

There are two different things to package:

1. code
2. model assets

### 11.1 Code packaging

The app binary should include:

1. app code
2. runtime code
3. reality-engine code
4. kernel code

Because Flutter packages are linked into one app product.

### 11.2 Model asset packaging

Reality-model ONNX assets:

1. may ship bundled for baseline functionality
2. may also be updated via signed model pack delivery

SLM assets:

1. should generally be downloaded on demand on capable devices
2. should not be required for first-run usefulness
3. should be cached locally after install

This gives:

1. guaranteed local cognition
2. smaller initial install
3. optional richer local language later

---

## 12. Recommended Concrete Interfaces

### 12.1 Shared contracts in `avrai_core`

Put these in `shared/avrai_core`:

1. `KernelEventEnvelope`
2. `RealityKernelFusionInput`
3. `RealityCandidate`
4. `RealityObservedOutcome`
5. `RealityDecisionTrace`
6. `RealityModelHealthReport`
7. stable request/response DTOs consumed by both runtime and engine

### 12.2 Engine contracts in `reality_engine`

Put these in `engine/reality_engine/contracts`:

1. `RealityModelContract`
2. `RealityModelBootstrap`
3. `StateEncoderContract`
4. `TransitionPredictorContract`
5. `EnergyFunctionContract`
6. `PlannerContract`
7. `MemoryStoresContract`

### 12.3 Runtime facades in `avrai_runtime_os`

Put these in runtime:

1. `RealityModelPort`
2. `RealityModelRuntimeAdapter`
3. `RecommendationFacade`
4. `ConversationFacade`
5. `GovernedPlanningService`
6. `RealityInspectionFacade`

---

## 13. Migration Targets From Current Repo

### 13.1 Remove direct app engine dependencies

Target:

1. remove direct `avrai_knot` dependency from `apps/avrai_app/pubspec.yaml`
2. stop importing engine internals through app DI modules

### 13.2 Narrow runtime proxy surface

Target:

1. replace broad engine re-exports in `runtime_api.dart`
2. expose only facades and DTOs

### 13.3 Fill `engine/reality_engine`

Target:

1. move prediction, memory, and scoring ownership from runtime into engine
2. keep runtime as orchestrator and governor

---

## 14. Final Rule

If a component answers:

1. what is true now,
2. what will happen next,
3. how good is this option,
4. what should happen after simulating futures,

it belongs in the reality model.

If a component answers:

1. is this allowed,
2. who is acting,
3. when did this happen,
4. how do we route/execute/rollback/govern it,

it belongs in runtime.
