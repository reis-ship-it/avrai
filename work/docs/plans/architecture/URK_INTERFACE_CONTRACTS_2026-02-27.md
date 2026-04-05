# URK Interface Contracts (2026-02-27)

**Date:** February 27, 2026  
**Status:** Canonical contract specification  
**Purpose:** Decision-complete interface and governance contract for all URK runtime types and future kernel types.

**Companion Blueprint:** `docs/plans/architecture/UNIFIED_RUNTIME_KERNEL_BLUEPRINT_2026-02-27.md`
**Companion doctrine/spec:** `docs/plans/architecture/AVRAI_COGNITIVE_OS_DOCTRINE_2026-03-06.md`, `docs/plans/architecture/AVRAI_RECURSIVE_GOVERNANCE_ARCHITECTURE_SPEC_2026-03-06.md`

---

## 1. Scope

This document defines:

1. runtime API contracts,
2. trigger and activation contracts,
3. privacy mode enforcement contracts,
4. event/business/expert runtime specialization contracts,
5. required plan/board/documentation alignment updates.

This document is implementation authority for runtime interfaces; `docs/MASTER_PLAN.md` and `docs/EXECUTION_BOARD.csv` remain execution authority.

---

## 2. Runtime Types (Required)

Every runtime instance must declare:

1. `runtime_id` (stable UUID/string)
2. `runtime_type`:
   - `user_runtime`
   - `event_ops_runtime`
   - `business_ops_runtime`
   - `expert_services_runtime`
   - `custom_runtime` (future kernel type)
3. `privacy_mode`:
   - `local_sovereign`
   - `private_mesh`
   - `federated_cloud`
4. `prong_owner` map:
   - `model_core`
   - `runtime_core`
   - `governance_core`
5. `governance_stratum`:
   - `personal`
   - `locality`
   - `world`
   - `universal`

---

## 3. Canonical Envelope Types

## 3.1 `RuntimeRequestEnvelope`

```json
{
  "request_id": "req_...",
  "runtime_id": "event_ops_runtime_main",
  "runtime_type": "event_ops_runtime",
  "privacy_mode": "private_mesh",
  "trigger_type": "in_app_event",
  "trigger_id": "trg_...",
  "consent_scope": ["ai2ai", "calendar_read", "event_ops"],
  "actor_agent_id": "agt_...",
  "entity_refs": [
    {"entity_type": "event", "entity_id": "evt_..."}
  ],
  "atomic_time": {
    "atomic_timestamp": "2026-02-27T20:21:00.123456Z",
    "sync_status": "synchronized",
    "drift_offset_ms": 2,
    "sync_rtt_ms": 18,
    "uncertainty_window_ms": 6
  },
  "semantic_time": "afternoon",
  "payload": {}
}
```

## 3.2 `RuntimeDecisionEnvelope`

```json
{
  "decision_id": "dec_...",
  "request_id": "req_...",
  "runtime_id": "event_ops_runtime_main",
  "runtime_type": "event_ops_runtime",
  "privacy_mode": "private_mesh",
  "decision_type": "plan|commit|recover|override",
  "confidence": 0.82,
  "conviction_tier": "T2",
  "policy_checks": [
    {"name": "consent_gate", "pass": true},
    {"name": "privacy_mode_policy", "pass": true},
    {"name": "conviction_gate", "pass": true}
  ],
  "rollback_path": {
    "available": true,
    "strategy": "revert_commit_v1",
    "ttl_hours": 24
  },
  "provenance_ref": "lin_...",
  "atomic_time": {
    "atomic_timestamp": "2026-02-27T20:21:02.000000Z",
    "sync_status": "synchronized",
    "drift_offset_ms": 2,
    "sync_rtt_ms": 18,
    "uncertainty_window_ms": 6
  }
}
```

---

## 4. Endpoint Contracts (Required for All Runtime Types)

## 4.1 `POST /runtime/{runtime_id}/ingest`

Purpose:

1. Normalize trigger payload to domain graph deltas.

Request:

1. `RuntimeRequestEnvelope`

Response:

1. normalized entity deltas,
2. ingestion status,
3. policy precheck result.

## 4.2 `POST /runtime/{runtime_id}/plan`

Purpose:

1. Build world state,
2. run candidate generation,
3. energy scoring,
4. transition simulation,
5. MPC output.

Response includes:

1. ranked action candidates,
2. expected outcomes,
3. uncertainty summaries,
4. hard-constraint violations.

## 4.3 `POST /runtime/{runtime_id}/commit`

Purpose:

1. Commit selected plan action(s) after governance gates.

Must enforce:

1. `ConsentGate`,
2. `PrivacyModePolicy`,
3. `ConvictionGate`,
4. canary eligibility for high-impact actions.

## 4.4 `POST /runtime/{runtime_id}/observe`

Purpose:

1. Capture outcomes,
2. append memory tuple,
3. update lineage,
4. emit learning signals.

## 4.5 `POST /runtime/{runtime_id}/recover`

Purpose:

1. Route incident to recover path,
2. run rollback/fix playbook,
3. update incident state machine.

Required states:

1. `open`
2. `scheduled`
3. `recovering`
4. `resolved`

## 4.6 `GET /runtime/{runtime_id}/lineage/{decision_id}`

Purpose:

1. Return explainability and provenance chain.

Must include:

1. trigger source,
2. model/policy versions,
3. gates passed/failed,
4. action result,
5. related rollback events.

## 4.7 `POST /runtime/{runtime_id}/override`

Purpose:

1. Human override and escalation handling.

Must include:

1. override actor,
2. reason,
3. scope,
4. expiry,
5. follow-up review requirements.

## 4.8 `GET /runtime/{runtime_id}/governance-inspect`

Purpose:

1. Explicit human and authorized higher-stratum inspection of an individual agent/runtime,
2. return convictions, anomaly summaries, provenance references, policy state, and optionally deeper traces under break-glass rules,
3. maintain auditable observation of personal, locality, world, and universal strata without hidden backdoors.

Must include:

1. inspection actor,
2. inspection scope,
3. visibility tier (`summary|triggered_detail|break_glass_detail`),
4. justification,
5. immutable audit reference.

---

## 5. Trigger Contract

Allowed `trigger_type` values:

1. `in_app_event`
2. `os_background`
3. `external_webhook`
4. `risk_anomaly`
5. `governance_event`

Each trigger must declare:

1. `required_consent_scopes`,
2. `allowed_privacy_modes`,
3. `max_action_impact_tier`,
4. `cooldown_policy`.

`governance_event` triggers must additionally declare:

1. whether they are normal governance or break-glass,
2. affected governance strata,
3. rollback path,
4. quantum-time validity window.

---

## 6. Privacy Mode Policy Contract

## 6.1 `local_sovereign`

Hard requirements:

1. `NoEgressGate` enforced before any outbound transport.
2. Network adapters disabled for runtime data paths.
3. Model updates local-only.
4. Lineage/audit local-only (tamper-evident).

## 6.2 `private_mesh`

Hard requirements:

1. payloads anonymized and encrypted,
2. no raw calendar/message body egress,
3. differential privacy where applicable,
4. metadata minimization + pseudonymous routing.

## 6.3 `federated_cloud`

Hard requirements:

1. outbound data must match feature/label contracts,
2. policy + compliance checks pass,
3. lineage and audit persisted for cloud-path actions,
4. rollout guardrails (canary/rollback) enforced.

---

## 7. Governance Observation Contract

Governance observation is defined across six kernel surfaces:

1. `who`
2. `what`
3. `when`
4. `where`
5. `why`
6. `how`

### 7.1 Normal observation

Normal observation may return:

1. conviction summaries,
2. anomaly scores,
3. provenance references,
4. policy state,
5. quantum-time-ordered event summaries,
6. compressed `who/what/when/where/why/how` kernel views.

### 7.2 Triggered detail

Triggered detail may return additional reasoning traces and state detail only when:

1. anomaly thresholds are breached,
2. attack or disruption conditions are detected,
3. a higher governance stratum requests review under policy,
4. an authorized human initiates an audited investigation.

Triggered detail should still preserve the six-kernel shape rather than collapsing into unstructured dumps.

### 7.3 Break-glass detail

Break-glass detail requires:

1. explicit authorization,
2. reason code,
3. expiry,
4. immutable audit record,
5. follow-up review.

Break-glass detail must declare which kernel surfaces are being expanded and why.

### 7.4 Forbidden implementation style

The following are contract violations:

1. hidden unrestricted live-inspection paths,
2. unaudited research access,
3. governance control tunneled through ordinary learning or inference channels.

---

## 8. Quantum Atomic Time Contract

All request, decision, observe, recover, override, and governance-inspect flows must carry authoritative temporal metadata sufficient for:

1. event ordering,
2. replay,
3. causality validation,
4. cross-node conflict resolution,
5. escalation timing,
6. coherence enforcement across governance strata.

If the uncertainty window violates policy for the requested action, the runtime must fail closed or downgrade to a lower-impact path.

---

## 7. Time Contract

Every runtime write event must include both:

1. `atomic_time` object,
2. `semantic_time` enum.

`atomic_time.sync_status` allowed values:

1. `synchronized`
2. `degraded`
3. `unsynchronized`

If `unsynchronized`, high-impact commits must either:

1. fail closed,
2. or require explicit override policy.

---

## 8. Specialization Contracts

## 8.1 Event Ops runtime

Required entities:

1. `Event`, `Session`, `Role`, `Task`, `Commitment`, `Incident`

Required outputs:

1. staffing plan,
2. schedule adjustments,
3. risk alerts,
4. post-event learning summary.

## 8.2 Business Ops runtime

Required entities:

1. `BusinessAccount`, `SLA`, `Contract`, `Invoice`, `Payout`, `Attribution`

Required outputs:

1. SLA risk forecasts,
2. contract/action recommendations,
3. business outcome attribution metrics.

## 8.3 Expert Services runtime

Required entities:

1. `ExpertProfile`, `ServiceOffering`, `Capacity`, `Assignment`

Required outputs:

1. assignment ranking,
2. fallback routing,
3. performance and fit outcomes.

---

## 9. Governance and Safety Contract

High-impact action tiers (`impact_tier`):

1. `L1` informational only,
2. `L2` low-impact execution,
3. `L3` high-impact execution,
4. `L4` restricted/financial/legal critical.

Rules:

1. `L3` and `L4` require conviction + canary eligibility + rollback path.
2. Any failed gate must produce deterministic deny reason code.
3. Runtime must preserve immutable policy precedence from master governance docs.

---

## 10. Acceptance Test Contract

## 10.1 Privacy tests

1. `local_sovereign`: assert zero runtime egress events.
2. `private_mesh`: assert only approved anonymized encrypted classes are transmitted.
3. `federated_cloud`: assert outbound payload schema and consent conformance.

## 10.2 Runtime tests

1. Trigger-to-plan and plan-to-commit latency by device tier.
2. No dead/orphan action states.
3. Incident lifecycle transitions complete and auditable.

## 10.3 Governance tests

1. Conviction gate blocks ineligible high-impact actions.
2. Canary rollback triggers under breach fixture.
3. Lineage reconstruction completeness per sampled decision set.

---

## 11. Master Plan + Execution Board + Build Docs Alignment

## 11.1 Does this need to be integrated with master plan and board?

Yes. URK is architecture-level unification and must be linked to execution tracking; otherwise plan/board drift is guaranteed.

## 11.2 What must be updated (required)

1. `docs/MASTER_PLAN.md`
   - add URK as explicit cross-phase architecture authority for phases 3-8 and runtime/governance sections.
2. `docs/EXECUTION_BOARD.csv`
   - add URK alignment metadata for milestone rows (recommended new columns below).
3. `docs/plans/methodology/PRD_EXECUTION_BOARD_INTEGRATION.md`
   - add URK traceability requirements for PRs and milestones.
4. CI guards
   - extend traceability validation to require URK reference tags for runtime-affecting PRs.

## 11.3 What should be updated (strongly recommended)

1. `docs/plans/architecture/ARCHITECTURE_SPOTS_REGISTRY.csv`
   - include spots for `model_core`, `runtime_core`, `governance_core` URK boundaries.
2. status tracker docs
   - add URK lane dashboard per prong and per runtime type.
3. privacy/security docs
   - explicitly define mode-true claims and no-egress validation for local sovereign mode.

## 11.4 What does not require immediate reorganization

1. Existing phase numbering and ownership model.
2. Existing completed milestone evidence.

Use overlay strategy:

1. Keep existing structure.
2. Add URK mapping layer.
3. Incrementally migrate milestones and docs.

## 11.5 Recommended `EXECUTION_BOARD.csv` metadata additions

1. `urk_runtime_type` (`user_runtime|event_ops_runtime|business_ops_runtime|expert_services_runtime|shared`)
2. `urk_prong` (`model_core|runtime_core|governance_core|cross_prong`)
3. `privacy_mode_impact` (`local_sovereign|private_mesh|federated_cloud|multi_mode`)
4. `trigger_classes` (CSV subset of trigger contract)
5. `impact_tier_max` (`L1|L2|L3|L4`)

---

## 12. Rollout Contract

1. Stage A: interface freeze + policy freeze.
2. Stage B: event ops runtime shadow mode.
3. Stage C: low-impact auto actions.
4. Stage D: high-impact gated autonomy.
5. Stage E: replicate to business and expert runtimes.
6. Stage F: publish runtime template for future kernel types.

Every stage must attach evidence in board metadata and status logs.

---

## 13. Canonical Dependencies

1. `docs/MASTER_PLAN.md`
2. `docs/EXECUTION_BOARD.csv`
3. `docs/plans/architecture/UNIFIED_RUNTIME_KERNEL_BLUEPRINT_2026-02-27.md`
4. `docs/plans/methodology/PRD_EXECUTION_BOARD_INTEGRATION.md`
5. `configs/ml/feature_label_contracts.json`
6. `configs/ml/avrai_native_type_contracts.json`
