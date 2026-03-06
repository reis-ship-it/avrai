# AVRAI Philosophy and Architecture

**Last Updated:** February 23, 2026  
**Status:** ACTIVE - Master Philosophy Document

## 1. Core Philosophy: Doors

There is no secret to life. There are doors not yet opened.
AVRAI exists to help people discover and open those doors in real life.

Core implications:
- AVRAI shows possibilities, not commandments.
- Users keep agency over choices.
- Real-world outcomes matter more than app engagement.

## 2. Purpose: Meaningful Connection and Opportunity

AVRAI is designed to improve:
- connection,
- belonging,
- discovery,
- practical opportunity,
- and long-term life quality.

The platform supports both:
- personal discovery ("find me a place"), and
- community discovery ("find my people, events, and networks").

## 3. Social Philosophy: Live and Let Live

AVRAI assumes pluralism:
- People may hold different values and tastes.
- Coexistence does not require total agreement.
- Systems should widen access, not enforce social sameness.

This philosophy permits useful structure and expertise systems, while prohibiting value hierarchies about people.

## 4. Dignity and Bias Boundary

Non-negotiable:
- No ranking of human worth.
- No exclusion optimization by protected trait or proxy.
- No release that improves global metrics while materially harming vulnerable cohorts.

Operational details live in:
- [`BIAS_AND_DIGNITY_GUARDRAILS.md`](./BIAS_AND_DIGNITY_GUARDRAILS.md)

## 5. Data Philosophy: Agent-First, Human-Origin Aware

AVRAI is primarily agent-data driven.

Data layers:
- Human-origin signals (source reality)
- Agent-state abstractions (learning substrate)
- World-state entities (places, events, contexts)

Design goals:
- de-identification by default,
- limited identity persistence,
- privacy-preserving cross-agent learning,
- no direct person-level centralization requirement for core intelligence.

### 5.1 The Air Gap: Privacy as a Law of Physics

The Air Gap is AVRAI's primary privacy mechanism. It is not a policy — it is an architectural invariant enforced at the data ingestion boundary. Every piece of raw external data (app signals, location, wearable readings, environmental context) that enters the reality model must pass through the `TupleExtractionEngine`, which:

1. Accepts the raw payload into an isolated execution context
2. Runs the on-device LLM to extract abstract behavioral meaning
3. Returns only semantic tuples (mathematical artifacts: subject, predicate, object, confidence, timestamp)
4. Destroys the raw payload from memory — it is never persisted, never stored, never sent

This is the physics of AVRAI's privacy: raw reality is "radioactive" and cannot survive contact with the storage layer. Only the half-life-free mathematical abstraction survives.

### 5.2 Gas / Liquid / Solid — Air Gap Permeability Model

The Air Gap's permeability is user-controlled through three states, analogous to the states of matter:

**Gas (default):** The Air Gap is maximally permeable. Behavioral signals flow freely from external apps and environment into the reality model through the TupleExtractionEngine's standard pipeline. This is the default state because it provides the best AI personalization experience. The gas state does NOT bypass privacy protections — raw data still cannot persist. It simply means the extraction pipeline runs without additional filtering.

**Liquid:** The Air Gap is partially permeable. User or app-category-level filters control which signal sources are allowed to contribute. Example: "let health apps contribute, but block social media signals." The liquid state is for users who want AVRAI's benefits but want explicit control over which domains of their life the agent learns from.

**Solid:** The Air Gap is opaque to that domain. No signals from the blocked domain reach the reality model at all — the TupleExtractionEngine rejects those payloads before extraction. Users who want complete separation between their AVRAI agent and a specific life domain (work, relationships, health) can solidify the Air Gap for that domain. The solid state for physical identity (Phase 12.8) means no proximity or face matching of any kind.

**The analogy clarifies the invariant:** In all three states, the Air Gap is still present and the TupleExtractionEngine is still the only crossing point. The difference is HOW MUCH passes through, not WHETHER the gap exists. There is no state of matter that bypasses the gap — not even for the user themselves.

### 5.3 Physical Identity Privacy (Long-Term Opt-In)

If users choose to opt into physical-to-digital identity matching (Phase 12.8), the following privacy rules apply and cannot be overridden:

- The biometric embedding (face vector) is computed on-device only, stored in the device's secure enclave, and never uploaded
- No raw image ever crosses the Air Gap — only the mathematical embedding, which cannot reconstruct the face
- The Air Gap permeability for physical identity is independently controllable from other domains (per 5.2)
- Revocation is immediate and irreversible: embedding deleted, derived signals purged, match records cleared
- Matching uses cryptographic commitment schemes — neither device learns the other's embedding during a proximity check, only whether a match occurred above threshold

## 6. Architecture Direction

### 6.1 On-Device First
- Personal world modeling runs locally where possible.
- Private context stays local.
- Models adapt from behavior, not only explicit prompts.

### 6.2 Federated/Network Learning
- Network intelligence is additive, not mandatory.
- Shared improvements use privacy-preserving aggregation.
- User-level traceability is minimized.

### 6.3 Governance Gates
- Bias and fairness evaluation before release.
- Uncertainty and calibration checks across cohorts.
- Staged rollout and rollback readiness.

## 7. Collective Reality Stewardship

After release, everyone contributes to improving the reality model through aggregate participation.

Principles:
- No single person or group can unilaterally control model direction.
- Influence on the shared model must be distributed, measured, and bounded.
- Local users and communities can still change real outcomes by what they choose to do in life.
- The model should help people improve personal and shared reality without granting capture power over everyone else.

## 8. Product Behavior Rules

AVRAI should:
- surface relevant doors,
- explain core rationale,
- support user correction,
- and preserve variety of paths.
- preserve reflective agency when AI confidence is high but uncertainty remains.
- treat "too good to be true" skepticism as valid feedback, not user resistance to optimize away.
- provide reversible pilot paths for high-upside, high-impact recommendations when trust is low.

AVRAI should not:
- force narrow recommendation funnels,
- penalize minority patterns as "wrong",
- hide tradeoffs behind opaque optimization,
- or train users into uncritical acceptance of AI output.
- use certainty theater or hype framing to pressure high-impact acceptance.

## 8.1 Tri-System Agency Boundary

AVRAI treats external AI assistance as a third cognition lane (outside user intuition and deliberation).

Operational constraints:
- External assistance may supplement judgment, never silently replace it for high-impact actions.
- High-impact recommendations must expose uncertainty and provide an easy counter-view.
- Confidence is not authority: confidence must stay calibrated to realized outcomes over delayed windows.
- When confidence/accuracy diverges, autonomy is automatically throttled and reflective checkpoints increase.
- High-impact claims must include a plausibility translation (`claim`, `why_now`, `assumptions`, `what would disprove`, `safe test step`).
- Adoption realism is explicit: `model_confidence` and `adoption_confidence` are tracked separately, and high-gap lanes are routed to pilot mode.

## 9. Access and Hierarchy

AVRAI allows expertise layers when they are:
- transparent,
- opt-in,
- and reachable by all users.

This keeps quality and specialization without creating closed status classes.

## 10. Success Condition

A change is successful only if it improves real-world utility while preserving:
- dignity,
- fairness,
- privacy,
- user agency,
- and recourse.
- trust calibration and recoverability after overconfident or overhyped failures.

Implementation pointer:
- Canonical failure/contradiction handling and self-healing integrity controls are maintained in `docs/MASTER_PLAN.md` under **10.9J System Failure + Self-Healing Integrity Matrix (Canonical)**.

---

## 11. AVRAI as Cognitive Operating System

**Phase:** Post-production (Phase 12). **NOT required for beta.**  
**Implementation:** `docs/MASTER_PLAN.md#phase-12`, `docs/plans/rationale/PHASE_12_OS_RATIONALE.md`

After beta validates that users want AVRAI's product, the architecture evolves from "a sophisticated Flutter app" to "cognitive infrastructure that other software depends on."

### 11.1 The OS Philosophy

A traditional OS manages physical resources — CPU, RAM, storage, I/O — so that every program above it doesn't have to. AVRAI OS manages **cognitive resources** — behavioral memory, inference compute, agent identity, attention budget, AI-to-AI communication — so that every AI company and application above it doesn't have to.

The parallel is exact. iOS doesn't own ARM silicon — it delegates through hardware. Android runs on Linux. JVM runs on any OS. All of these are OS-like without owning bare metal. AVRAI OS doesn't own iOS/Android hardware. It becomes the mandatory mediation layer for AI cognition on those platforms — which is authority over a new resource domain.

### 11.2 Philosophical Boundaries for the OS

The OS vision does NOT change any existing philosophy. The same rules apply, extended to external integrators:

- **Doors, not badges** — the OS opens doors for AI companies to build things they couldn't build alone, not badges they collect for being "AVRAI certified." Integration must serve users' real-world outcomes.
- **Privacy is non-negotiable** — the Context Enrichment API and all external-facing APIs must be consent-gated. The OS never egresses raw behavioral data. DP-anonymized vectors only. User controls what each external app can see.
- **Agency preservation** — external AI companies calling AVRAI's APIs cannot override user agency. The OS enforces this at the permission model boundary: external callers can enrich responses; they cannot make decisions that bypass the user.
- **Real-world enhancement, never replacement** — OS integrations must make real-world experiences better. An AI company using AVRAI's Reality Model API to improve restaurant recommendations is OS-aligned. An AI company using AVRAI's behavioral data to optimize engagement metrics is not.
- **Authenticity preservation** — the OS must not become a homogenization engine. External callers cannot use the OS to make everyone's AI converge toward the same recommendations. The energy function's individuation mandate applies to external API outputs as well as internal ones.

### 11.3 Who the OS Serves

The OS creates a three-tier beneficiary structure:

1. **End users** — primary. OS always serves users first. No external integrator can exploit user data or override user agency.
2. **Builders** — AI companies, developers, researchers who build better products because they can access the cognitive infrastructure. They benefit because AVRAI's OS solves problems (statelessness, local hallucination, last-mile execution) they cannot solve alone.
3. **Society** — anonymized aggregate signal from the OS contributes to civic intelligence (urban planning, public health, social science) in ways that individual apps cannot.

This three-tier structure is governed by the same dignity and bias guardrails that apply to the consumer product (`BIAS_AND_DIGNITY_GUARDRAILS.md`).

### 11.4 Collective Reality Stewardship at OS Scale

Section 7 of this document establishes that no single person or group can unilaterally control model direction. At OS scale, this becomes more critical:

- No external integrator can influence the shared reality model beyond their proportional contribution of real behavioral outcomes.
- External API calls are read-only from the model's perspective — they query, they do not train.
- Only real user behavioral outcomes (via the OS's own observation pipeline) train the reality model. External callers cannot inject training data.
- The OS must publish transparency reports on how many external integrators exist, what capability classes they hold, and aggregate API usage patterns — subject to the same data governance as all other AVRAI data.
