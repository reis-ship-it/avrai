# AI2AI + Mesh Kernel Implementation Backlog

**Date:** March 11, 2026  
**Status:** Proposed implementation backlog  
**Purpose:** Define how the new mesh and AI2AI kernel families should connect to the existing kernels, how they should run correctly under URK governance, and how their learnable outputs should flow into the reality-model hierarchy.

---

## Executive Answer

The new mesh and AI2AI kernels should not become side-channel systems.

They should connect through the existing AVRAI kernel doctrine:

`URK activation -> runtime governance kernels -> who/what/when/where/why/how -> reality-model learning intake -> app/admin projection`

That means:

1. runtime owns execution and enforcement
2. reality model learns from governed outcomes
3. apps only project controls and truthful state

The right shape is:

- `urk_mesh_runtime_governance`
- `urk_mesh_learning_intake`
- `urk_ai2ai_runtime_governance`
- `urk_ai2ai_learning_governance`

Those are not four unrelated services.
They are four explicit kernel-governed lanes that plug into:

- `KernelEventEnvelope`
- `TransportRouteReceipt`
- `FunctionalKernelProngPorts`
- `FunctionalKernelOs`
- `UrkKernelRegistryService`
- `UrkRuntimeActivationReceiptDispatcher`
- `UrkKernelControlPlaneService`

---

## Canonical Runtime Wiring

The canonical execution path should be:

1. A runtime event occurs:
   - discovery result
   - message enqueue
   - prekey forward
   - custody transfer
   - delivery/read/learning outcome
2. URK activation evaluates which mesh and AI2AI kernels should be active for the trigger and privacy mode.
3. `urk_mesh_runtime_governance` decides whether the transport action is allowed and how it should execute.
4. `urk_ai2ai_runtime_governance` decides whether the communication or learning action is allowed and how it should execute.
5. Runtime emits a canonical `KernelEventEnvelope` with an enriched `TransportRouteReceipt`.
6. Existing kernel surfaces resolve the event into `who`, `what`, `when`, `where`, `how`, and `why`.
7. `FunctionalKernelProngPorts` build the fused runtime truth for the reality model.
8. `urk_mesh_learning_intake` and `urk_ai2ai_learning_governance` decide whether the outcome becomes learnable model input.
9. The reality model may emit recommendations or priors back toward runtime, but runtime still decides whether and how to apply them.
10. Apps and admin consume projections only.

The architectural rule is:

- no direct app -> mesh transport mutation
- no direct reality-model -> transport mutation
- no direct locality subsystem -> orchestrator bypass

---

## How Mesh Connects To The Existing Kernels

| Existing kernel | Mesh responsibility through that kernel | Why this is the right connection |
| --- | --- | --- |
| `who` | Device continuity, pseudonymous node identity, relay trust provenance, peer continuity binding | Mesh needs identity continuity without exposing raw user identity |
| `what` | Packet class, message class, queue state, custody state, segment state | Transport state becomes queryable system truth instead of logger-only state |
| `when` | Ordering, expiry, replay windows, custody timestamps, route freshness | Store-carry-forward and delayed delivery need monotonic time truth |
| `where` | Locality context, bearer environment, geohash segment, gateway region, mesh-interface policy context | Mesh conditions are spatial and environmental, not just logical |
| `how` | Bearer selection, route candidates, winning route, fallback reason, retry/backoff path | This is where Reticulum-like transport truth belongs |
| `why` | Explanation for route choice, quarantine, relay denial, retry policy, delivery downgrade refusal | Runtime needs auditable reasons for operator review and model learning |

Mesh should also connect to these URK anchors:

- `urk_stage_c_private_mesh_policy_conformance`
- `urk_kernel_promotion_lifecycle`
- `urk_learning_update_governance`
- `urk_reality_world_state_coherence`

Mesh should not bypass `where`.
The existing `WhereKernelContract.observeMeshUpdate()` is already the correct kernel-native opening for locality-aware mesh effects.

---

## How AI2AI Connects To The Existing Kernels

| Existing kernel | AI2AI responsibility through that kernel | Why this is the right connection |
| --- | --- | --- |
| `who` | Peer identity binding, session continuity, trust posture, key lineage provenance | Secure AI2AI cannot exist without governed identity continuity |
| `what` | Conversation entity state, payload class, delivery state, learning-state transitions | Chat and learning become governed entities instead of ad hoc service output |
| `when` | Send/read ordering, session validity, delayed delivery windows, learning-apply timing | Users only trust statuses that are time-consistent |
| `where` | Spatial relevance, locality-aware routing and learning relevance, nearby-only or broader-scope policy | AI2AI learning quality depends on where and context, not just who |
| `how` | Signal session path, prekey forwarding path, retry strategy, local vs mesh vs cloud execution path | This keeps session behavior auditable and governable |
| `why` | Learning eligibility reasoning, trust downgrade reasoning, message suppression reasoning, recommendation explanation | Runtime and admin need to explain why a message or learning action was or was not allowed |

AI2AI should sit above mesh, not beside it.

The relationship is:

- mesh moves encrypted things
- AI2AI gives those encrypted things meaning, policy, and learning value

---

## Shared Contracts To Add Or Extend

The next implementation phase should add typed contracts rather than growing the current free-form maps indefinitely.

## 1. Extend `TransportRouteReceipt`

Add lifecycle fields so it becomes the canonical delivery truth:

- `custodyAcceptedAtUtc`
- `custodyReleasedAtUtc`
- `recipientDeliveredAtUtc`
- `readAtUtc`
- `learningAppliedAtUtc`
- `deliveryClass`
- `policyOutcome`
- `peerContinuityRef`
- `segmentRef`
- `receiptLineage`

This should remain the single route and delivery object rather than creating a second route-truth model.

## 2. Add `MeshGovernanceContext`

It should carry typed runtime facts such as:

- visible bearers
- path candidates
- interface policy
- queue pressure
- quarantine state
- relay role
- store-carry-forward posture

This becomes part of the `KernelEventEnvelope` runtime context.

## 3. Add `Ai2AiLifecycleContext`

It should carry typed communication facts such as:

- payload class
- session state
- trust posture
- delivery state
- read state
- learning eligibility state
- privacy mode

## 4. Add `Ai2AiLearningOutcomeTuple`

This should become the learnable handoff into the model side:

- peer interaction class
- trust result
- delivery truth
- read truth
- downstream outcome signal
- learning value estimate
- locality scope

## 5. Define `KernelEventEnvelope` conventions for mesh and AI2AI

Do not create a new event bus.

Instead, standardize:

- event types
- action types
- route-receipt usage
- context keys
- policy context keys
- runtime context keys

That keeps the six-kernel system canonical.

---

## URK Registry Additions And Dependencies

The registry additions proposed in the architecture note should be implemented with explicit dependencies.

## 1. `urk_mesh_runtime_governance`

- prong: `runtime_core`
- depends on:
  - `urk_stage_c_private_mesh_policy_conformance`
  - `urk_reality_temporal_truth`
- activation triggers:
  - `mesh_path_update`
  - `custody_event`
  - `queue_expiry`
  - `runtime_health_breach`
  - `locality_mesh_update`

## 2. `urk_mesh_learning_intake`

- prong: `model_core`
- depends on:
  - `urk_mesh_runtime_governance`
  - `urk_learning_update_governance`
  - `urk_reality_world_state_coherence`
- activation triggers:
  - `route_outcome_observed`
  - `delivery_lifecycle_closed`
  - `path_policy_candidate`

## 3. `urk_ai2ai_runtime_governance`

- prong: `governance_core`
- depends on:
  - `urk_mesh_runtime_governance`
  - `urk_reality_temporal_truth`
- activation triggers:
  - `ai2ai_message_candidate`
  - `prekey_forward_candidate`
  - `trust_change`
  - `policy_violation_detected`
  - `learning_apply_candidate`

## 4. `urk_ai2ai_learning_governance`

- prong: `model_core`
- depends on:
  - `urk_ai2ai_runtime_governance`
  - `urk_learning_update_governance`
  - `urk_reality_world_state_coherence`
- activation triggers:
  - `learning_update_candidate`
  - `learning_applied`
  - `peer_quality_drift`
  - `low_value_loop_detected`

These kernel records should appear in:

- `kernel_registry.json`
- control-plane listings
- lineage
- activation receipts

If they are missing there, they are not fully real.

---

## Runtime Decomposition Targets

The largest cleanup target is `VibeConnectionOrchestrator`.

It should stop being the effective home for the entire AI2AI and mesh system.

Recommended decomposition:

## Mesh runtime side

- `MeshBearerDiscoveryCoordinator`
  - BLE, nearby, and other bearer visibility
- `MeshReachabilitySupervisor`
  - destination/path memory, route freshness, segment policy
- `MeshCustodyQueueService`
  - durable encrypted outbox, custody transfer, expiry
- `MeshRouteReceiptEmitter`
  - canonical route receipt updates
- `MeshRuntimeGovernanceBridge`
  - emits mesh runtime events into URK + six-kernel flow

## AI2AI runtime side

- `Ai2AiSessionSupervisor`
  - Signal session bootstrap, prekey forwarding, continuity
- `Ai2AiDeliveryLifecycleService`
  - sending, delivered, read, learning-applied lifecycle
- `Ai2AiTrustAndEligibilityService`
  - trust posture, payload eligibility, learning policy
- `Ai2AiRuntimeGovernanceBridge`
  - emits AI2AI runtime events into URK + six-kernel flow
- `Ai2AiProjectionService`
  - user/admin-friendly state built from canonical receipts

## Transitional rule

`VibeConnectionOrchestrator` may remain temporarily as a bootstrap facade, but new behavior should move out of it.

If new transport or learning logic continues to land there, the cleanup fails.

---

## Locality And Reality-Model Wiring

Mesh and AI2AI should become explicitly learnable, but the learning must stay bounded.

The existing rule remains correct:

1. reality model learns human reality
2. runtime OS learns execution reality

That means the new kernels should feed two different kinds of learning.

## Mesh learning

`urk_mesh_learning_intake` should learn:

- path reliability by context
- queue success/failure patterns
- custody success patterns
- bearer reliability by device and environment
- locality-scoped transport priors

This should feed runtime suggestions such as:

- preferred bearer order
- retry/backoff tuning
- store-carry-forward aggressiveness
- gateway eligibility

## AI2AI learning

`urk_ai2ai_learning_governance` should learn:

- which interaction classes improve downstream outcomes
- which peer classes generate low-value or noisy learning
- which trust patterns correlate with healthy exchange
- which locality scopes create useful network wisdom

This should feed runtime suggestions such as:

- learning eligibility thresholds
- peer-quality priors
- trust review triggers
- rate limits for low-value loops

## Locality path

`LocalityTransportSupport` should stop treating the orchestrator as the canonical mesh entry.

The long-run path should become:

`locality event -> mesh runtime governance -> route receipt + kernel envelope -> where kernel ingestion -> model intake`

That preserves kernel authority and makes locality mesh learning observable.

---

## How These Kernels Will Run Correctly

These kernels will run correctly only if they are made observable, activatable, and fail-closed.

## 1. Activation correctness

Every kernel must have:

- registry record
- explicit triggers
- explicit privacy modes
- explicit dependencies
- control-plane state
- activation receipt lineage

If activation does not show up in the control plane, the kernel is not governable enough.

## 2. Dependency correctness

Mesh and AI2AI runtime governance must refuse activation when dependencies are missing.

Examples:

- no AI2AI runtime governance without mesh runtime governance
- no model-side learning intake without runtime-side governed outcome truth
- no learning application without learning-update governance

## 3. Privacy correctness

Privacy mode must gate behavior at activation time and runtime decision time.

Examples:

- `local_sovereign` can allow local-only learning but block mesh propagation
- `private_mesh` can allow encrypted relay/custody without cloud fallback
- `federated_cloud` can allow wider coordination while preserving route and policy lineage

## 4. Temporal correctness

All delivery and learning states must be monotonic.

The allowed user-visible order is:

`sending -> custody accepted -> delivered -> read -> AI learning updated`

No later state may appear before an earlier one.

## 5. Failure correctness

The system should fail closed in these cases:

- encryption/session failure
- missing trust binding
- missing dependency kernel
- policy denial
- stale route beyond allowed policy

It should not silently downgrade into weak or plaintext behavior for sensitive payloads.

## 6. Observability correctness

Admin and control plane should be able to inspect:

- active kernel states
- activation lineage
- route receipts
- queue pressure
- quarantine reasons
- learning acceptance or rejection reasons

Without this, the system will become hard to govern as it grows.

---

## Required Test And Replay Gates

Implementation should be considered incomplete until these exist.

## Unit tests

- activation rule coverage for the four new kernels
- `TransportRouteReceipt` lifecycle monotonicity
- privacy-mode gating for mesh and AI2AI actions
- fail-closed behavior on missing crypto or trust state
- learning-intake acceptance and rejection reasons

## Integration tests

- offline send -> delayed custody -> delayed delivery
- locality mesh update -> `where` ingestion -> model intake
- prekey forward over mesh -> Signal session open -> message delivery
- admin control plane reflects kernel activation and state transitions

## Replay tests

- route receipt reconstruction from event history
- queue expiry and retry replay
- duplicate/replay packet suppression
- deterministic projection from `KernelEventEnvelope` to six-kernel outputs

---

## Hierarchical Agents And Neural Networks

The personal-to-reality hierarchy should not be defined as "a stack of neural networks."

That would be too narrow and will make the system harder to govern.

The better rule is:

- an **agent** is a governed cognitive system at a stratum
- a **neural network** is one possible learned component inside that system

So the answer is:

- each hierarchical agent may contain one or more neural networks
- but each hierarchical agent should not be treated as identical to a single neural network

## Recommended implementation posture by layer

| Layer | What it should be treated as | Neural role |
| --- | --- | --- |
| Personal agent | Local cognitive runtime with memory, learned user state, planner/evaluator, and mouth constraints | Likely multiple small learned models plus memory and policy |
| Locality agent | Aggregate locality-state learner and anomaly/coherence governor | Learned aggregators and anomaly models are appropriate, but not sufficient alone |
| City or world agent | Cross-locality coherence and reconciliation system | Likely summary models plus explicit governance logic |
| Top-level reality agent | Abstract conviction and coherence governor | Likely learned abstraction models plus strong symbolic and policy structure |

## Why this distinction matters

If AVRAI defines each agent as a single monolithic neural network:

- governance becomes opaque
- memory boundaries get blurry
- policy enforcement becomes weaker
- explanation quality drops
- kernel integration gets harder

If AVRAI defines each agent as a governed composite system:

- neural components can improve over time
- memory remains explicit
- kernel authority remains intact
- higher-agent oversight stays auditable

That is the stronger long-run architecture.

---

## Immediate Implementation Order

1. Extend `TransportRouteReceipt` and standardize mesh/AI2AI envelope conventions.
2. Add the four kernel records to the URK registry and wire them into activation/control-plane flow.
3. Decompose `VibeConnectionOrchestrator` into mesh runtime, AI2AI runtime, and projection bridges.
4. Move locality mesh forwarding to the mesh runtime governance path.
5. Add model-side learning tuples and bounded learning-governance gates.
6. Rewire app/admin surfaces to canonical receipts and kernel projections.

---

## Best Next Step For Beta + Simulation Training

Given the current program state, the next best step is narrower than the whole kernel rollout.

It should be:

**Implement canonical mesh + AI2AI outcome contracts first, then feed them into simulation and training.**

That means doing these three things before the larger runtime decomposition:

1. Extend `TransportRouteReceipt` and `KernelEventEnvelope` so every AI2AI exchange can produce one governed lifecycle truth:
   - `sending`
   - `custody accepted`
   - `delivered`
   - `read`
   - `AI learning updated`
2. Add one AVRAI-native outcome tuple/frame for mesh + AI2AI learning intake so replay, walk-by simulation, and future BHAM replay all emit the same training contract.
3. Run that contract first in shadow/instrumentation mode through:
   - existing walk-by simulation
   - existing BHAM replay intake
   - current beta transport/runtime paths

This is the best next step because it aligns with all of the active work already underway:

- beta gate is already passing, so the safest move is instrumentation and truth unification before a major runtime refactor
- `Transport Backend Interface + Subsystem Isolation + Connection Capability Model` is active, and this contract work supports it directly instead of competing with it
- `v0.3 Synthetic Swarm Sprint` needs governed, replayable transport and AI2AI outcome data rather than more undocumented runtime behavior
- `ML Training Automation Governance` already requires AVRAI-native dataset contracts and staged replay/shadow/limited-rollout discipline

It is also the best training move because it gives AVRAI a new tuple class that simulation and reality can both share:

`transport_state + ai2ai_action + outcome + locality_scope + timestamp + privacy_mode + policy_lineage`

That should become the canonical training primitive for:

- runtime execution learning
- peer-quality learning
- route-policy learning
- admin replay and diagnostics

## Why this is better than starting with the full kernel split

Starting with a full orchestrator breakup first would be high-risk for beta.

Starting with outcome contracts first is better because it:

- improves user-visible delivery truth immediately
- gives the admin app real transport and AI2AI history
- creates simulation-ready data without waiting for the whole refactor
- lets the new kernels start in shadow mode against stable evidence
- reduces the risk of breaking the current beta transport path while major beta and simulation lanes are active

## Concrete beta-first execution slice

1. Add the new receipt lifecycle fields and envelope conventions.
2. Emit those receipts from the current AI2AI path without changing the full orchestrator topology yet.
3. Add one AVRAI-native training/export frame for mesh + AI2AI outcomes.
4. Update walk-by simulation and BHAM replay tooling to emit that frame.
5. Only then promote the new runtime kernels into explicit activation/control-plane roles.

This is the fastest path to making the architecture cleaner without disrupting beta and simulation work.

---

## If AVRAI Chooses Native Mesh + AI2AI Kernels Now

If the goal is "train and simulate with the real thing," then native-backed mesh and AI2AI kernels are a valid direction.

The key distinction is:

- **good:** native-backed domain kernels under the current runtime architecture
- **bad:** prematurely forcing the entire Phase 12 OS/process extraction before beta is ready

As of March 11, 2026, the repo's explicit Phase 12 posture is still post-beta.
So the correct move is:

- build **native-backed mesh and AI2AI execution kernels now**
- keep them under current runtime governance and contracts
- do **not** treat that as full Phase 12 kernel/process extraction yet

## Why Rust-native can work well

Rust-native mesh and AI2AI kernels are a strong fit for:

- deterministic replay
- Monte Carlo simulation
- headless execution
- store-carry-forward queues
- route/path state machines
- bounded concurrency
- long-run portability to desktop, server, Pi, and device-hosted nodes

The repo already has this pattern in smaller form:

- native-backed surface kernels with fallback stubs
- native-backed temporal paths
- native forecast kernel paths
- Rust-backed Signal integration/wrappers

So this is not a foreign architecture move.
It is an extension of an existing direction.

## What "real stuff in simulation" should mean

Simulation should not mean "pretend Dart logic."

It should also not mean "literal BLE hardware in the loop."

It should mean:

- the **same mesh kernel code**
- the **same AI2AI kernel code**
- the **same delivery/custody/session state machines**
- the **same route receipt logic**

running against a **simulated transport backend** instead of live radios.

That is the right meaning of "use the real stuff" for Monte Carlo and replay.

## Required adapter split

To make this work, native mesh and AI2AI kernels should depend on abstract backends:

- `SimulatedTransportBackend`
- `BleTransportBackend`
- `LocalLoopTransportBackend`
- `CloudRelayTransportBackend`

The kernel logic stays the same.
Only the transport adapter changes.

That is how training and live runtime stay aligned.

## Recommended native kernel split

### `avrai_mesh_kernel`

Owns:

- destination/path memory
- route selection
- custody queue
- expiry and retry
- replay suppression
- route receipts
- interface/segment policy

### `avrai_ai2ai_kernel`

Owns:

- session lifecycle
- prekey forwarding policy
- delivery/read/learning lifecycle
- trust and eligibility state
- payload class policy
- learning outcome emission

### Shared native contract crate

Owns:

- `KernelEventEnvelope` contract subset used by mesh/AI2AI
- `TransportRouteReceipt`
- atomic time fields
- privacy-mode contract
- common error/fallback enums

## Signal and Rust

AI2AI should stay Signal-anchored for cryptography.

So the right native direction is:

- Rust-native AI2AI lifecycle and session governance
- Signal/libsignal-backed cryptography inside that path

Do not replace Signal with a custom mesh crypto design.
Use Rust to make the session and lifecycle implementation stronger and more portable.

## Do mesh and AI2AI use `who/what/when/where/why/how` kernel data?

Yes.

They should absolutely use the six-kernel data.

More precisely:

- they should **consume** six-kernel truth where needed
- they should **emit** domain facts that become six-kernel truth
- they should **not** bypass the six-kernel system with a parallel truth model

The clean rule is:

- mesh and AI2AI are **domain execution kernels**
- `who/what/when/where/why/how` are **canonical governance surfaces**

So mesh and AI2AI run through them, not around them.

## Practical mapping

### Mesh -> six surfaces

- `who`: node continuity, relay identity, trust scope
- `what`: packet class, queue state, custody state, route state
- `when`: TTL, replay window, route freshness, delivery ordering
- `where`: bearer environment, locality segment, gateway scope
- `why`: route-choice reason, quarantine reason, denial reason
- `how`: bearer path, winning route, retry path, fallback path

### AI2AI -> six surfaces

- `who`: peer identity binding, session continuity, trust lineage
- `what`: message class, conversation state, learning state
- `when`: send/read/apply ordering, session validity window
- `where`: locality relevance, nearby-only or wider-scope policy
- `why`: eligibility reasoning, suppression reasoning, trust downgrade reason
- `how`: Signal session path, prekey path, execution lane, retry lane

## Are mesh and AI2AI a different kernel class?

Yes, but not in the sense of becoming a second kernel doctrine.

They should be a different **kernel class within URK**:

1. **Surface kernels**
   - `who`
   - `what`
   - `when`
   - `where`
   - `why`
   - `how`
   - These are AVRAI's canonical governance and observation surfaces.

2. **Domain runtime kernels**
   - `mesh_runtime_governance`
   - `ai2ai_runtime_governance`
   - These execute domain behavior and feed the six surfaces.

3. **Domain learning kernels**
   - `mesh_learning_intake`
   - `ai2ai_learning_governance`
   - These learn from governed outcomes and feed model-side adaptation.

So yes, mesh and AI2AI are a different kernel class than `who/what/when/where/why/how`.

But they are not a different architecture.

They are domain kernel families that must obey the same activation, privacy, lineage, replay, and governance rules as everything else.

## Best native-first sequence if this path is chosen

1. Define `MeshKernelContract` and `Ai2AiKernelContract` in runtime.
2. Define shared native contract payloads for receipts, lifecycle, time, and privacy mode.
3. Build native-backed mesh kernel with simulated + live transport adapters.
4. Build native-backed AI2AI kernel on top of mesh + Signal.
5. Run Monte Carlo, walk-by simulation, and BHAM replay against those native kernels first.
6. Keep Dart fallback/shadow paths until parity and replay determinism pass.

That is the cleanest way to make simulation and production converge on the same system.

---

## Bottom Line

Mesh and AI2AI should become first-class kernel-governed domains by extending AVRAI's current doctrine, not by escaping it.

The clean architecture is:

- runtime kernels execute and enforce
- existing six kernels explain and project
- model kernels learn from governed outcomes
- apps stay simple

And the reality-model hierarchy should treat agents as governed cognitive systems that may use neural networks, not as neural networks in themselves.
