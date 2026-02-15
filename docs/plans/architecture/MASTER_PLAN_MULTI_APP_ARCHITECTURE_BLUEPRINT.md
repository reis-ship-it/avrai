# Master Plan Multi-App Architecture Blueprint

**Date:** February 15, 2026  
**Status:** Proposed v1 (implementation blueprint)  
**Scope:** Master Plan execution architecture across all applications, operators, and external consumers  
**Primary Reference:** `docs/MASTER_PLAN.md`  
**Canonical execution status:** `docs/agents/status/status_tracker.md`
**Execution Backlog:** `docs/plans/architecture/MASTER_PLAN_ARCHITECTURE_EXECUTION_BACKLOG.md`  
**Implementation Checklist:** `docs/plans/architecture/MASTER_PLAN_ARCHITECTURE_IMPLEMENTATION_CHECKLIST.md`
**Identity/Access Contract:** `docs/plans/architecture/IDENTITY_UNLINKABILITY_AND_ACCESS_GOVERNANCE_CONTRACT.md`
**Reality Coherence Matrix Contract:** `docs/plans/architecture/REALITY_COHERENCE_TEST_MATRIX.md`

---

## 1) Executive Summary

This blueprint defines a single architecture for:

- Multiple first-party apps that share the same intelligence and services
- Different experiences and outputs per actor type (users, businesses, admins, researchers, partners)
- Continuous learning and controlled self-healing
- Reuse of the existing codebase through phased migration rather than rewrite

The recommended model is:

- **One shared Intelligence Core**
- **One shared Learning Plane**
- **One controlled Self-Healing Plane**
- **Multiple Experience Adapters** (per app/client type)
- **Strict contract boundaries** for safety, auditability, and maintainability

This keeps the system simple, editable, and clean while preserving current investments.

---

## 2) Architecture Objectives and Non-Goals

### Objectives

- Keep one decision brain across all apps
- Let each app/channel render different outputs from the same decision intent
- Make behavior measurable and debuggable end-to-end
- Allow self-healing only where safe and reversible
- Preserve privacy/compliance constraints as immutable boundaries
- Support offline-first operation and graceful degradation by device tier
- Reuse existing services and packages with minimal disruption

### Non-Goals

- Full rewrite of existing services
- Uncontrolled autonomous code changes in production
- Divergent per-app intelligence forks
- Hidden logic paths outside typed contracts

---

## 3) Stakeholder Outcome Contracts

Architecture decisions must be judged by outcome impact on each actor:

| Actor | Primary Outcome | Architectural Requirement |
|---|---|---|
| End user | Better real-world actions with minimal friction | Fast local inference, transparent rationale, agency-preserving UX |
| Business owner | Better discovery, conversion, retention | Bilateral energy scoring, outcome attribution, operational dashboards |
| Event planner/host | Reliable attendee quality and event success | Group negotiation + intent routing + post-event outcomes |
| Company/brand partner | Trustworthy campaign effectiveness | Audited data products, controlled targeting, compliance and attribution |
| Admin/operator | Safe, observable operations | Global observability, rollback controls, immutable guardrails |
| Researcher | Valid anonymized research access | IRB and anonymization pipeline, reproducible dataset lineage |
| Third-party viewer | Read-only insight consumption | Contracted data views, row-level governance, signed access scopes |
| API caller/integration | Stable predictable interfaces | Versioned APIs/events, deprecation policy, SLA-backed behavior |
| Partner app/SDK consumer | Fast integration without internal coupling | Strong SDK boundary, capability-based APIs, compatibility guarantees |

---

## 4) Canonical System Model

```text
[Client Apps / Channels]
- Consumer app
- Business app
- Event/creator tools
- Admin desktop
- Research portal
- Partner SDK consumers
- External API clients
        |
        v
[Experience Adapter Layer]
- Channel-specific input normalization
- Intent routing
- Output rendering policies
        |
        v
[Intelligence Core]
- State Encoder
- Energy Function
- Transition Predictor
- MPC Planner
- Guardrail Engine (immutable policies)
- Translation Layer (numeric -> semantic output)
        |
   -------------------------
   |                       |
   v                       v
[Learning Plane]      [Self-Healing Plane]
- Episodic memory      - Observation bus
- Outcome pipeline     - Experiment orchestration
- Semantic memory      - Canary + rollback
- Procedural memory    - DSL strategy runtime
- Consolidation        - Meta-learning governance
        |
        v
[Shared Platform Services]
- Identity, auth, payments, reservations
- Messaging/networking, BLE/mesh
- Sync/storage/compliance/audit
- Existing domain services (wrapped)
```

Core principle: apps and channels do not own decision logic; they own interaction style and constraints.

Cross-app coherence principle: all cross-system behaviors must map to scenario IDs and evidence requirements in `docs/plans/architecture/REALITY_COHERENCE_TEST_MATRIX.md`.

---

## 5) Layer Responsibilities

### 5.1 Experience Adapter Layer

Responsibilities:

- Convert channel inputs to canonical signals
- Enforce channel-specific UX policy (frequency, format, context)
- Map decision intents to channel outputs (card, chat, notification, API JSON)
- Emit user/business outcomes back into the learning plane

Rules:

- No decision scoring logic in adapters
- No direct model-specific branching
- Adapters are stateless where possible, policy-configured where needed

### 5.2 Intelligence Core

Responsibilities:

- Produce action recommendations from normalized state
- Optimize toward meaningful outcomes under guardrails
- Return structured explanation and confidence metadata

Rules:

- Pure deterministic interfaces for reproducibility
- Side effects forbidden inside planning/scoring path
- Guardrail failures are hard stops, never best-effort warnings

### 5.3 Learning Plane

Responsibilities:

- Capture tuples: `(state, action, next_state, outcome, context)`
- Train/update critic/predictor and derived memories
- Build semantic/procedural knowledge artifacts
- Preserve historical lineage for attribution and audits

Rules:

- Append-only event model for source-of-truth learning data
- Separate online inference path from training path
- Version every feature schema and model artifact

### 5.4 Self-Healing Plane

Responsibilities:

- Observe runtime quality and drift
- Propose constrained optimizations
- Validate in shadow/canary before rollout
- Auto-rollback on safety/performance regressions

Rules:

- Self-healing may change strategy/config/weights, not immutable guardrails
- All changes must be explainable, attributable, reversible
- Human override always available

### 5.5 Identity and Access Boundaries (Cross-Layer)

Responsibilities:

- Enforce namespace separation (`account_id`, `agent_id`, `world_id`) across all adapters and services
- Enforce plane-based access policy consistently for user/admin/research/partner/auditor surfaces
- Ensure sharing/export/disclosure paths cannot bypass policy middleware

Rules:

- Any route touching disclosure/export/research/partner/admin scope must satisfy `IDENTITY_UNLINKABILITY_AND_ACCESS_GOVERNANCE_CONTRACT.md`
- Legacy `user_id` compatibility is transitional only and must follow bounded dual-read/dual-write + strict cutoff gates
- Unauthorized linkage paths are blocked by default and treated as security incidents

---

## 6) Multi-App Channel Strategy

One intelligence output, multiple presentation contracts:

| Channel | Input Mode | Output Mode | Additional Constraints |
|---|---|---|---|
| Consumer app | Passive + explicit + conversational | Cards, nudges, optional chat, actions | Agency-first, low interruption, high explainability |
| Business app | Operational + campaign + inventory + staffing | Recommendations, forecasts, partner opportunities | ROI traceability, tax/legal compliance |
| Event planner tools | Scheduling + audience intent + venue constraints | Program suggestions, attendee matching, risk alerts | Time-sensitive orchestration, reliability |
| Admin desktop | System diagnostics + controls | Health dashboards, guardrail violations, rollout controls | Strict auth, audit log, break-glass procedures |
| Research portal | Approved query intents | Cohort analytics and exports | IRB gating, anonymization guarantees |
| Third-party viewers | Read-only metrics queries | Scoped analytics views | Data minimization, no direct PII access |
| API consumers | API requests/webhooks | Contracted JSON | Strong versioning, backward compatibility window |
| Partner SDK apps | SDK calls + callback events | Embedded recommendations/workflows | Capability-based access and sandboxing |

---

## 7) Contract-First Architecture (Human + AI Editable)

### 7.1 Canonical Input Contract

```dart
class NormalizedSignal {
  String signalId;
  String actorId;
  String actorType; // user, business, admin, api_client, partner_app
  String source; // app, sensor, api, adapter
  String signalType; // behavioral, explicit_intent, system_event, etc.
  Map<String, dynamic> payload;
  double confidence; // 0.0 - 1.0
  DateTime observedAt;
  Duration freshnessTtl;
  Map<String, dynamic> privacyTags; // pii_level, consent_scope, residency
}
```

### 7.2 Canonical Decision Contract

```dart
class DecisionIntent {
  String intentId;
  String actorId;
  String objective; // discovery, social, business_growth, etc.
  List<ActionCandidate> rankedActions;
  Map<String, double> energyBreakdown;
  String explanationKey; // key into translation layer
  double confidence;
  Map<String, dynamic> guardrailEvaluation;
  String modelVersion;
}
```

### 7.3 Canonical Outcome Contract

```dart
class OutcomeEvent {
  String outcomeId;
  String intentId;
  String actorId;
  String actionId;
  String outcomeType; // accepted, ignored, completed, failed, delayed
  Map<String, dynamic> outcomeMetrics;
  DateTime occurredAt;
  Map<String, dynamic> context;
}
```

### 7.4 Contract Governance

- Schema registry with semantic versioning
- Compatibility tests for every schema change
- Deprecation windows and adapters for old clients
- Contract review required for self-healing format changes

---

## 8) Mutability Model (What AI Can and Cannot Edit)

| Layer | Human Editable | Self-Healing Editable | Notes |
|---|---|---|---|
| Guardrails and legal constraints | Yes | No | Immutable at runtime except human-approved releases |
| Privacy policies and consent rules | Yes | No | Compliance boundary |
| Output wording templates and semantic mappings | Yes | Yes (controlled) | Must pass grounding/quality checks |
| Ranking strategy parameters | Yes | Yes | DSL/config based; canary required |
| Model weights and thresholds | Yes | Yes (gated) | Only through experiment pipeline |
| Feature extraction code paths | Yes | Limited | Prefer config-first feature pipelines |
| Core architecture/package boundaries | Yes | No | Structural changes remain human-owned |

This model keeps the system simple and safe while enabling targeted autonomous improvement.

---

## 9) Data and Storage Architecture

### 9.1 Event-Sourced Core

- `signal_log` append-only
- `decision_log` append-only
- `outcome_log` append-only
- `experiment_log` append-only
- `audit_log` append-only

### 9.2 Materialized Views (read models)

- User timeline and recommendation history
- Business opportunity and conversion dashboards
- Event quality and attendance health views
- Admin health and guardrail incident dashboards
- Research cohort extracts (anonymized)

### 9.3 Partitioning and Residency

- Partition by `tenant_scope`, `locality`, and time
- Apply residency controls before federation export
- Enforce minimum-anonymity thresholds for research views

---

## 10) Learning System Architecture

### 10.1 Training Flow

1. Collect normalized signals and outcomes
2. Build episodic tuples
3. Train/update critic and transition predictor
4. Validate against holdout and counterfactual checks
5. Stage model with shadow traffic
6. Promote via canary then full rollout

### 10.2 Memory Hierarchy

- Episodic memory: raw experiences
- Semantic memory: compressed facts and embeddings
- Procedural memory: reusable strategies and policies
- Conviction memory: high-confidence truths with challenge protocol

### 10.3 Cross-Entity Learning

- Support user, list, community, event, business, brand, and service-provider entities
- Use shared representation contracts with entity-type extensions
- Preserve entity-specific guardrails in bilateral scoring scenarios

---

## 11) Self-Healing Architecture

### 11.1 Closed-Loop Lifecycle

1. Observe anomalies/opportunities
2. Generate bounded optimization proposal
3. Simulate on historical replay
4. Run shadow evaluation
5. Canary rollout with hard stop thresholds
6. Auto-promote or auto-rollback
7. Record causal impact and lessons

### 11.2 Required Safety Gates

- Guardrail compliance gate
- Privacy/compliance gate
- Performance/SLO gate
- Outcome quality gate
- Minority-impact gate (no silent regressions on smaller cohorts)

### 11.3 Human Governance

- Admin approval required for high-impact classes
- Break-glass rollback available globally
- Every autonomous change emits explainable changelog entries

---

## 12) Security, Privacy, and Compliance by Design

### Controls

- Agent-bound identity and scoped tokens
- Field-level encryption for sensitive data
- Differential privacy for federation and external insights
- Strict role and capability-based access control
- Signed immutable audit events for all operator and AI actions

### Compliance Paths

- GDPR/consent export and deletion workflows
- Jurisdiction-aware tax/legal automation for monetization flows
- IRB-compatible research isolation pathways

---

## 13) UX Architecture Across Products

### 13.1 Shared UX Contracts

- Every recommendation must include: `why`, `confidence`, `actionability`
- Users can dismiss/defer/accept every recommendation
- Passive learning must not require chat participation

### 13.2 Role-Specific UX Variations

- Consumer: low-friction suggestions and minimal cognitive load
- Business/event: operational control, forecast confidence, risk signals
- Admin: diagnosis-first, rollout control, anomaly triage
- Research: reproducible query lineage and consent visibility
- API/SDK: deterministic machine-readable responses and error contracts

### 13.3 Quality Guardrails

- Notification fatigue budget
- Over-suggestion suppression when acceptance drops
- Explainability fallback when confidence is low

---

## 14) Platform and Repository Architecture

Target shape aligned to existing repository investment:

```text
packages/contracts
packages/intelligence_core
packages/learning_plane
packages/self_healing
packages/platform_adapters
packages/channel_adapters
apps/consumer
apps/business
apps/admin_desktop
apps/research_portal
apps/partner_sdk_examples
```

### Mapping to current codebase (reuse-first)

| Existing Area | Blueprint Role | Action |
|---|---|---|
| `packages/avrai_core` | Base contracts and infrastructure utilities | Extract stable contracts; retain utilities |
| `packages/avrai_ai` | Intelligence core services | Separate pure inference interfaces from app concerns |
| `packages/avrai_ml` | Learning plane components | Standardize model registry and training pipelines |
| `packages/avrai_network` | Platform adapter for network/sync | Keep as adapter boundary, not decision owner |
| `lib/core/services/*` | Domain/platform adapters | Wrap and classify as adapter/plugin modules |
| `lib/presentation/*` | Experience adapters and UIs | Remove embedded scoring logic, keep rendering/routing |

---

## 15) API and Integration Model

### API Surface Types

- Decision APIs (online/offline supported where possible)
- Outcome ingestion APIs
- Explainability APIs
- Admin control APIs
- Research query APIs
- Partner SDK capability APIs

### Integration Standards

- OpenAPI + protobuf event contracts
- Idempotency keys for action and outcome submission
- Signed webhooks with replay protection
- Typed error taxonomy and remediation metadata

---

## 16) Reliability, SLOs, and Operations

### SLO Targets (initial)

- Local decision latency p95: <= 120 ms (full tier), <= 250 ms (standard tier)
- Online decision API p95: <= 400 ms
- Critical path availability: >= 99.9%
- Data loss tolerance for event logs: 0 in append-only path
- Auto-rollback time after severe regression: <= 5 minutes

### Operational Planes

- Real-time health telemetry for core and adapters
- Drift dashboards by actor type and region
- Model lineage and active-version visibility
- Rollout ring management (shadow -> canary -> region -> global)

---

## 17) Testing Strategy

Required suites:

- Contract compatibility tests
- Deterministic planner tests
- Guardrail violation tests (must fail hard)
- Replay tests on historical episodes
- Canary comparison tests (control vs candidate)
- Multi-app UX consistency tests for same intent
- Privacy leakage and access-control penetration tests

---

## 18) Migration Plan (Simple Reuse Path)

### Phase A: Foundation (Weeks 1-3)

- Establish schema registry for canonical contracts
- Add adapter boundaries around existing services
- Implement event logs for signals/decisions/outcomes

### Phase B: Shadow Intelligence (Weeks 4-8)

- Introduce energy function in shadow mode
- Keep current production formulas as control path
- Compare outcomes and drift without user-visible changes

### Phase C: Controlled Cutover (Weeks 9-14)

- Promote selected domains to learned scoring
- Keep per-domain rollback toggles
- Begin self-healing for DSL/config class only

### Phase D: Expansion (Weeks 15+)

- Expand to multi-entity and bilateral energy domains
- Enable broader planner-driven actions
- Scale federation and external access paths

This reuses existing capabilities while reducing risk.

---

## 19) Master Plan Phase Alignment

| Blueprint Capability | Master Plan Phase |
|---|---|
| Event contracts, episodic/outcome logging | 1 |
| Privacy, compliance, cryptographic constraints | 2 |
| Input normalization, state/action encoders | 3 |
| Energy function replacement | 4 |
| Transition predictor and latent futures | 5 |
| MPC planning and language translation layer | 6 |
| Triggering, tiers, self-healing, observation bus | 7 |
| AI2AI ecosystem intelligence and locality learning | 8 |
| Business monetization and service provider intelligence | 9 |
| Feature cleanup, reorg, and hardening | 10 |
| Hardware abstraction and industry integrations | 11 |
| Admin platform, value intelligence, conviction oracle | 12 |
| Federation and universe model | 13 |
| Researcher pathway and IRB-compatible data | 14 |

---

## 20) Decision Framework for Future Changes

Any change proposal must pass:

1. Does it improve real-world outcomes for at least one actor without hidden regressions?
2. Does it preserve contract boundaries and avoid app-specific intelligence forks?
3. Is it observable, attributable, and reversible?
4. Is it compliant with immutable guardrails and privacy rules?
5. Can it be rolled out incrementally with safe fallback?

If any answer is no, the change is not production-ready.

---

## 21) First Deliverables to Build Immediately

1. `packages/contracts` with canonical signal/decision/outcome schemas  
2. `DecisionGateway` interface used by all apps/channels  
3. `ObservationBus` and append-only logs with lineage IDs  
4. `Adapter wrappers` around top existing high-impact services  
5. Shadow evaluator comparing legacy formulas vs energy function outputs  
6. Admin rollout controls for canary and rollback

These six items create the minimum viable backbone for the new architecture while reusing existing code.

---

## 22) Risks and Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| App teams implement local scoring shortcuts | Fragmented behavior and drift | Enforce DecisionGateway-only policy and lint/CI rules |
| Self-healing changes cause silent regressions | User trust and quality loss | Canary, minority-impact checks, automatic rollback |
| Contract churn breaks integrations | Operational instability | Schema registry, compatibility tests, deprecation windows |
| Over-centralization slows feature delivery | Team bottlenecks | Stable extension points in adapter and DSL layers |
| Privacy compliance gaps in external data flows | Legal risk | Policy engine gates, anonymization checks, signed audits |

---

## 23) Summary Architecture Decision

The best engineering path for the master plan is:

- **Shared intelligence, separated experiences**
- **Contract-first boundaries**
- **Event-sourced learning**
- **Constrained self-healing with immutable guardrails**
- **Strangler migration to reuse existing services**

This architecture is simple to reason about, easy to evolve, safe for autonomous improvement, and clean across all actor types and applications.
