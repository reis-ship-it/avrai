# Unified Runtime Kernel Blueprint (URK)

**Date:** February 27, 2026  
**Status:** Canonical implementation blueprint  
**Purpose:** Single reference architecture and execution contract for AVRAI runtime systems, including Event Ops, Business Ops, Expert Services, and future kernel/runtime types.

---

## 1. Why This Exists

This blueprint consolidates architecture, policy, and implementation direction discussed across runtime, reality-model, AI2AI, privacy, time, and OS-integration conversations.

It establishes one reusable pattern:

1. for current AVRAI use cases (event ops, business accounts, expert services),
2. for current 3-prong architecture constraints,
3. for future kernel/runtime domains with no redesign of core governance or activation logic.

---

## 2. Core Terms (Canonical)

1. **URK (Unified Runtime Kernel):** AVRAI-internal runtime control plane and execution contract. This is **not** an operating-system kernel.
2. **Reality Model:** Planning + prediction system (state encoder, energy function, transition model, MPC planner) operating on AVRAI domain state.
3. **3-prong system:**
   - **Prong 1:** Model Truth (state, encoding, prediction, planning math)
   - **Prong 2:** Runtime Execution (ingestion, orchestration, adapters, action execution)
   - **Prong 3:** Trust Governance (policy, conviction gates, canary, rollback, lineage, compliance)
4. **Kernel Type / Runtime Type:** A domain instantiation of URK (e.g., `user_runtime`, `event_ops_runtime`, `business_ops_runtime`, `expert_services_runtime`).

---

## 3. Non-Negotiable Product/Policy Decisions

### 3.1 AI2AI defaults and control

1. AI2AI participation is **opt-out by default** at product level.
2. Settings must include a clear top-level toggle: `AI2AI Network (On by default)`.
3. Hard overrides still apply:
   - legal/jurisdiction constraints,
   - age/safety constraints,
   - explicit policy denial conditions.
4. Scope-level access (calendar/messages/etc.) remains controlled by explicit capability/consent boundaries.

### 3.2 Internal planning calendar and temporal intelligence

1. AVRAI maintains an internal planning calendar/graph usable for cross user/business/event planning.
2. Temporal reasoning is dual-representation:
   - **Atomic time:** precise synchronized timestamp + uncertainty metadata.
   - **Semantic time:** human bands (`dawn`, `morning`, `noon`, `afternoon`, `dusk`, `golden_hour`, `night`).
3. Runtime decisions can use either or both depending on confidence and action criticality.

### 3.3 Privacy modes are first-class runtime policy

Every URK action and adapter route must execute under one explicit privacy mode:

1. `local_sovereign`
2. `private_mesh`
3. `federated_cloud`

No action may execute without a resolved privacy mode policy.

---

## 4. System Goal

Deliver one reality-model-driven runtime architecture that is:

1. seamless across app + OS-triggered pathways,
2. replicable to future kernel/runtime types,
3. policy-safe and auditable under autonomous behavior,
4. usable across event, volunteer, business, and expert workflows.

---

## 5. Unified Domain Model (URK Contract)

All runtime types use a shared domain graph contract.

### 5.1 Core entities

1. `Actor`: `User`, `Volunteer`, `Expert`, `BusinessAccount`, `Agent`
2. `EventOps`: `Event`, `Session`, `Role`, `Task`, `Commitment`, `Incident`
3. `BusinessOps`: `ServiceOffering`, `SLA`, `Contract`, `Invoice`, `Payout`, `Attribution`
4. `Context`: `Venue`, `Locality`, `Resource`, `ConsentScope`, `TimeBand`
5. `Outcome`: `KPI`, `QualitySignal`, `Retention`, `Satisfaction`, `Conversion`, `Risk`
6. `Learning`: `MemoryTuple(state_before, action, state_after, outcome, provenance)`

### 5.2 Lifecycle states (minimum)

1. `planned`
2. `staffed`
3. `live`
4. `closed`
5. `learned`

State transitions must be auditable and policy-validated.

---

## 6. URK Architecture: 3-Prong Wiring

## 6.1 Prong 1: Model Truth

Mandatory components:

1. `StateEncoder`
2. `QuantumUncertaintyHead`
3. `KnotTopologyAnalyzer`
4. `PlaneCoherenceProjector`
5. `EnergyFunction`
6. `TransitionPredictor`
7. `MPCPlanner`

Interpretation rule:

1. Quantum/knot/plane outputs are contributors to one planning graph.
2. They are not standalone recommendation silos.

## 6.2 Prong 2: Runtime Execution

Mandatory components:

1. `TriggerService`
2. `SignalIngestor`
3. `AdapterGateway`
4. `ActionOrchestrator`
5. `ExecutionEngine`
6. `IncidentRouter`
7. `MemoryWriter`

## 6.3 Prong 3: Trust Governance

Mandatory components:

1. `PolicyKernel`
2. `PrivacyModePolicy`
3. `ConsentGate`
4. `ConvictionGate`
5. `CanaryRollbackController`
6. `LineageAudit`
7. `HumanOverride`
8. `NoEgressGate` (required for `local_sovereign`)

No prong may bypass Prong 3 for production-affecting actions.

---

## 7. Runtime Loop (All Kernel Types)

Every kernel type must implement this loop:

1. `ingestSignal(signal)`
2. `normalizeToDomainGraph(delta)`
3. `buildWorldState(snapshot)`
4. `generateCandidates()`
5. `scoreWithEnergy()`
6. `simulateWithTransitionPredictor()`
7. `planWithMPC()`
8. `applyPolicyAndConvictionGates()`
9. `commitAction()`
10. `observeOutcome()`
11. `writeMemoryTuple()`
12. `lineageAndAuditRecord()`
13. `promotionPipelineIfApplicable()`

---

## 8. Trigger Matrix + Activation Policy

## 8.1 Trigger classes

1. `in_app_event`
   - RSVP changes, staffing updates, incident reports, payment failures, organizer actions.
2. `os_background`
   - Scheduled windows (`T-24h`, `T-2h`, `live`, `post+24h`).
3. `external_webhook`
   - Calendar updates, ticketing callbacks, payment callbacks, business system updates.
4. `risk_anomaly`
   - SLA breach risk, no-show spike, response latency risk, budget drift.
5. `governance_event`
   - policy updates, consent changes, key rotation, model promotion events.

## 8.2 Activation pipeline

1. Resolve runtime type and privacy mode.
2. Run `ConsentGate` for required scope.
3. Run `PolicyKernel` constraints.
4. Run `DeviceTierGate` (battery/network/thermal/capability).
5. Route to immediate execution or queued execution.
6. For high-impact actions, require conviction + canary eligibility.
7. Commit action or safe-fail/rollback.
8. Record lineage and outcome.

## 8.3 Always-on interpretation

AI2AI must be **always available** but not permanently high-frequency active. Use event-driven wake + bounded background scheduling.

---

## 9. Temporal Model (Atomic + Semantic)

## 9.1 Atomic time contract

Use synchronized atomic timestamps as canonical ordering and replay basis.

Required fields:

1. `atomic_timestamp`
2. `time_precision`
3. `sync_status`
4. `drift_offset_ms`
5. `sync_rtt_ms`
6. `uncertainty_window_ms`

## 9.2 Semantic time contract

Required enum (minimum):

1. `dawn`
2. `morning`
3. `noon`
4. `afternoon`
5. `dusk`
6. `golden_hour`
7. `night`

## 9.3 Usage rule

1. High-criticality sequencing uses atomic time.
2. User-facing planning and low-confidence scheduling can use semantic bands.
3. Both can be stored per action for explainability and replay.

---

## 10. Privacy Operating Modes (and 3-Prong Behavior)

## 10.1 `local_sovereign`

1. No network egress of runtime data (`NoEgressGate = hard fail`).
2. All reasoning, memory, and model updates local.
3. App/OS adapters run local-only paths.
4. Audit/log/lineage stored locally with tamper-evident protections.

## 10.2 `private_mesh`

1. Share only approved anonymized encrypted deltas.
2. No raw message/calendar/body content leaves device.
3. Strong identity separation (`agent_id`/rotating pseudonyms) and key rotation.
4. Differential privacy + payload validation required.

## 10.3 `federated_cloud`

1. Cloud-assisted orchestration and federated learning allowed.
2. Only contract-allowed features/outcomes can leave device.
3. Full policy, compliance, canary, rollback, and audit enforcement.

---

## 11. Security, Encryption, and Anti-Trace Requirements

## 11.1 Minimum cryptographic stack

1. App-layer encryption:
   - Signal Protocol preferred,
   - AES-256-GCM fallback where explicitly allowed.
2. Transport-layer TLS.
3. Hardware-backed key storage where platform supports it.
4. Key rotation and secure mapping enforcement.

## 11.2 Anonymization and privacy hygiene

1. Data minimization by default.
2. Payload anonymization before network sharing.
3. Differential privacy for shared derived signals.
4. Location obfuscation as policy requires.
5. Consent scope attached to processing and data contracts.

## 11.3 Anti-trace hardening (required enhancement)

Encryption is not enough for anti-correlation. Add:

1. metadata minimization,
2. batching windows,
3. randomized send jitter,
4. optional relay/mix routing for sensitive mesh scenarios,
5. rotating pseudonymous routing identifiers.

---

## 12. Public Interfaces (Kernel-Agnostic)

Each runtime type must expose the same internal API surface:

1. `POST /runtime/{runtime_id}/ingest`
2. `POST /runtime/{runtime_id}/plan`
3. `POST /runtime/{runtime_id}/commit`
4. `POST /runtime/{runtime_id}/observe`
5. `POST /runtime/{runtime_id}/recover`
6. `GET  /runtime/{runtime_id}/lineage/{decision_id}`
7. `POST /runtime/{runtime_id}/override`

Each response must include:

1. `decision_id`
2. `privacy_mode`
3. `policy_checks`
4. `conviction_tier`
5. `confidence`
6. `rollback_path`
7. `provenance_ref`

---

## 13. Settings + User Controls Specification

## 13.1 Required settings

1. `AI2AI Network` (default ON, user can turn OFF).
2. `Privacy Mode` selector:
   - Local Sovereign,
   - Private Mesh,
   - Federated Cloud.
3. Capability scopes:
   - calendar,
   - messaging,
   - location,
   - business integrations,
   - background activity.
4. `Data Export`, `Delete Data`, `Pause Learning` controls.

## 13.2 UX clarity requirement

Privacy claims must be mode-true and explicit. Avoid blanket claims unless enforced by active mode policy (for example, only claim "nothing leaves this device" when `local_sovereign` is active and `NoEgressGate` passes).

---

## 14. Event/Business/Expert Runtime Integration

## 14.1 Event Ops runtime

Primary orchestration domain for staffing, scheduling, incidents, and post-event learning.

## 14.2 Business Accounts integration

Business entities remain first-class in the same graph, including commercial and SLA control planes.

## 14.3 Expert Services integration

Experts are assignable by role type:

1. primary operator,
2. fallback operator,
3. micro-service provider.

Matching and assignment must be bilateral-scored (business fit + expert fit) and policy-gated.

---

## 15. Mapping to Current Active Plan and Milestones

This blueprint overlays existing plan artifacts; it does not replace them.

1. **Governance foundation already active/complete** in execution board milestones for reliability, safety, conviction, rollback, lineage, and self-healing.
2. **Runtime orchestration foundation active** via orchestrator/autopilot and trigger restructuring tracks.
3. **Model-core completion required** for full URK behavior:
   - state encoders,
   - energy function rollout,
   - transition predictor,
   - MPC planner,
   - ecosystem world-model integration.

Execution authority remains:

1. `docs/MASTER_PLAN.md`
2. `docs/EXECUTION_BOARD.csv`

URK provides cross-phase architectural binding and repeatable runtime template.

---

## 16. Implementation Order (Decision Complete)

## 16.1 Stage A: Contract freeze

1. Freeze URK core interfaces and domain schema.
2. Freeze privacy mode policy enums and gates.
3. Freeze dual-time schema.

## 16.2 Stage B: Event Ops reference runtime (shadow)

1. Route existing event ops through URK APIs in shadow mode.
2. Enable lineage, policy checks, conviction telemetry only.
3. Do not auto-commit high-impact actions yet.

## 16.3 Stage C: Controlled autonomy

1. Enable low-impact autonomous actions.
2. Canary with rollback automation.
3. Enforce acceptance SLOs and incident routing.

## 16.4 Stage D: Expand to Business + Expert runtimes

1. Reuse same URK skeleton.
2. Add domain action libraries and bilateral scoring.
3. Maintain identical governance and privacy mode contract.

## 16.5 Stage E: Template for future kernel types

Publish runtime template package:

1. `/runtime_template/domain_contracts`
2. `/runtime_template/model_core`
3. `/runtime_template/runtime_core`
4. `/runtime_template/governance_core`
5. `/runtime_template/adapters`
6. `/runtime_template/tests`

No new kernel type may bypass template guardrails.

---

## 17. Test and Acceptance Matrix

## 17.1 Privacy mode acceptance

1. `local_sovereign`: zero runtime egress events.
2. `private_mesh`: only approved anonymized encrypted payload classes.
3. `federated_cloud`: only contract-compliant aggregates/features with audit trace.

## 17.2 Governance acceptance

1. High-impact actions blocked without conviction/policy thresholds.
2. Canary rollback triggers deterministically under threshold breach.
3. Lineage reconstructs full decision chain for sampled production actions.

## 17.3 Temporal acceptance

1. Atomic timestamp ordering stable under replay.
2. Drift/uncertainty recorded and bounded by policy thresholds.
3. Semantic band routing produces consistent planning outcomes.

## 17.4 Runtime acceptance

1. Trigger-to-action latency SLOs by device tier.
2. No orphan action states after failure.
3. Incident lifecycle transitions (`open -> scheduled -> recovering -> resolved`) are complete and auditable.

---

## 18. Risks and Mitigations

1. **Risk:** Overstated privacy claims.
   - **Mitigation:** mode-locked claims + no-egress verification tests.
2. **Risk:** Metadata re-identification in mesh/cloud modes.
   - **Mitigation:** anti-trace hardening controls in Section 11.3.
3. **Risk:** Runtime fragmentation across domains.
   - **Mitigation:** mandatory URK API + template conformance checks.
4. **Risk:** Autonomy before model maturity.
   - **Mitigation:** staged rollout + conviction/canary gates + shadow phases.

---

## 19. What Future Kernel Types Must Reuse

Every future kernel/runtime type must reuse:

1. 3-prong wiring,
2. runtime loop contract,
3. privacy mode policy and no-egress semantics,
4. dual-time schema,
5. policy/conviction/canary/lineage stack,
6. acceptance matrix.

Only domain entities and action libraries may vary.

---

## 20. Canonical References

1. `docs/MASTER_PLAN.md`
2. `docs/EXECUTION_BOARD.csv`
3. `docs/plans/architecture/ARCHITECTURE_INDEX.md`
4. `docs/plans/architecture/DREAM_TRAINING_CONVICTION_GOVERNANCE.md`
5. `autopilot/README.md`
6. `configs/runtime/memory_reliability_gates.json`
7. `configs/ml/feature_label_contracts.json`
8. `configs/ml/avrai_native_type_contracts.json`
