# Reality Model And OS Build Audit

**Date:** March 9, 2026  
**Status:** Explicit audit of what exists versus what Birmingham beta now requires  
**Scope:** Reality model, runtime OS, app boundary, admin surfaces, and higher-agent readiness

## 1. What Comes Next

The next step after locking requirements is a contract-to-code audit.

That means:

1. compare the explicit beta contract to the current repo
2. identify what already exists
3. identify what is misplaced
4. identify what is missing
5. turn the result into a build queue

This document is that first audit.

## 2. High-Level Audit Result

The repo already has useful substrate for the Birmingham beta build, but not the final required shape.

Current state can be summarized as:

1. strong runtime/OS scaffolding exists
2. strong knot/quantum math substrate exists
3. transport, BLE, locality, and device-capability surfaces already exist in broad form
4. the actual `reality_engine` package is still thin
5. too much engine-owned cognition still lives in `runtime`
6. app/runtime boundaries are still leaky
7. admin has useful runtime visibility surfaces, but not yet the explicit direct OS operations chat

## 3. What Already Exists And Can Be Reused

### 3.1 Runtime OS scaffolding exists

Already present:

1. `HeadlessAvraiOsHost`
2. `ModelTruthPort`
3. kernel fusion / attribution surfaces
4. incident recording
5. outcome attribution
6. device capability sensing
7. offline-LLM capability gating
8. BLE and mesh transport lanes
9. locality-agent-related surfaces

This means the repo already has a meaningful runtime OS skeleton for the beta direction.

### 3.2 Knot and quantum substrate exists

Already present:

1. large `avrai_knot` package
2. large `avrai_quantum` package
3. Rust-backed knot math bridge
4. DNA encoder service
5. cross-entity compatibility and knot services

This means knot/DNA/topology substrate is not the immediate missing piece.

### 3.3 Admin visibility exists broadly

Already present:

1. admin app
2. headless OS host usage in admin
3. recommendation why previews
4. AI2AI admin dashboard surfaces
5. device capability usage in admin

This means admin is not starting from zero.

## 4. What Is Clearly Missing

### 4.1 A real reality-model core

`engine/reality_engine` is still very thin.

Current visible implementation is basically:

1. `tuple_extraction_engine.dart`
2. `semantic_knowledge_store.dart`

Missing engine-owned reality-model internals include:

1. state encoder
2. action encoder
3. persistent local user-state core
4. episodic / semantic / procedural memory interfaces as a coherent package surface
5. transition predictor
6. energy function
7. evaluator-first public API
8. candidate-list planner support
9. explanation packet contract
10. runtime-facing reality-model adapter

### 4.2 Brain-to-mouth contract

Still missing:

1. `RealityModelEvaluation`
2. `RealityDecisionTrace`
3. `ExplanationPacket`
4. explicit renderer interface for:
   - template
   - offline SLM
   - online AI

### 4.3 Direct admin-to-OS chat implementation

Now required in docs, but not yet implemented as an explicit surface.

### 4.4 City and top-level reality-agent implementation contract

The hierarchy is explicit now, but code still appears strongest around:

1. personal-agent surfaces
2. locality-related surfaces

The Birmingham city agent and top-level reality-agent execution shape are not yet clearly implemented as first-class runtime/build surfaces.

## 5. What Is Misplaced

### 5.1 Engine-owned cognition still living in runtime

These areas remain runtime-heavy and should move toward engine ownership:

1. prediction services
2. ONNX scoring logic
3. personality learning
4. vibe analysis
5. facts and structured-facts extraction

This is the same architectural problem identified earlier:

`runtime` still contains too much of the future reality-model brain.

### 5.2 Boundary leakage into app and admin

Boundary problems still visible:

1. app direct dependency on `avrai_knot`
2. `runtime_api.dart` re-exporting engine internals
3. remaining `world_model` naming in app chat surfaces
4. admin also depending on broad runtime API exports rather than narrower facades

## 6. What Must Be Built Next

### Wave 1: Reality-model contract and package boundary

Build next:

1. `RealityModelContract`
2. `RealityModelEvaluation`
3. `RealityDecisionTrace`
4. `RealityModelExplanation`
5. runtime `RealityModelPort`
6. narrowed runtime-safe DTO/export boundary

This is the most important next step.

### Wave 2: Evaluator-first engine core

Build next:

1. state encoder
2. action encoder
3. persistent local user-state core
4. evaluator-first fit API across place/event/group/list/business/locality
5. confidence and uncertainty output
6. memory update path for explicit and passive signals

### Wave 3: Mouth contract and renderers

Build next:

1. template explanation renderer
2. offline SLM renderer
3. online AI renderer
4. explicit “never bluff” uncertainty contract
5. follow-up question policy

### Wave 4: Runtime OS operational learning

Build next:

1. explicit OS operational-learning lane
2. failure-signature persistence
3. recovery-outcome learning
4. resource-budget adaptation contract
5. bounded feedback into core OS

### Wave 5: Admin operational surfaces

Build next:

1. direct OS operations chat
2. drift/reliability chat context
3. recovery explanation surfaces
4. admin audit trail for OS conversation

### Wave 6: Higher-agent hierarchy

Build next:

1. locality-agent hardening
2. Birmingham city-agent implementation
3. top-level reality-agent implementation
4. upward and downward bounded knowledge flow contracts

## 7. What Should Not Be Built First

Do not prioritize these before the evaluator-first core is working:

1. direct person-to-person suggestion authority
2. broad planner autonomy
3. rich proactive messaging
4. upper-layer agent sophistication beyond what beta needs
5. deep business-account collaboration flows

## 8. Beta-Critical Audit Findings

These are the repo issues most directly tied to the beta contract:

1. `world_model_ai_page.dart` naming and conceptual drift remain
2. `runtime_api.dart` is too leaky
3. app direct engine dependency still exists
4. `reality_engine` is not yet the real cognition center
5. admin-to-OS direct chat is a new requirement and currently missing
6. city-agent and top-level reality-agent contract needs implementation

## 9. Recommended Immediate Build Order

If building starts now, the order should be:

1. lock the public reality-model contracts
2. narrow runtime exports and app dependencies
3. move evaluator/prediction/memory ownership toward engine
4. implement explanation packet and mouth renderers
5. implement OS operational-learning contract
6. implement admin-to-OS chat
7. harden locality -> city -> reality flows

## 10. Audit Conclusion

What comes next is not more philosophy work.

What comes next is:

1. contract definition
2. boundary cleanup
3. evaluator-core implementation
4. renderer contract
5. operational-learning lane
6. admin OS chat

That is the build queue implied by the beta requirements now written down.
