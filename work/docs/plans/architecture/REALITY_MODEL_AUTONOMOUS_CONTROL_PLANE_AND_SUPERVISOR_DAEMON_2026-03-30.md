# Reality-Model Autonomous Control Plane And Supervisor Daemon

**Date:** March 30, 2026  
**Status:** Active architecture authority  
**Purpose:** Define the authoritative runtime/admin split for autonomous simulation and training, record what is already complete, and lock the next implementation anchor for simulation/training quality.

---

## 1. Canonical Boundary

The reality-model autonomous system is split into three roles:

1. **Runtime/backend authority**
   - owns jobs, evidence packages, promotion lineage, policy profiles, and supervisor execution decisions
   - hosts the supervisor daemon and control-plane services
2. **Admin app**
   - is the command center and human-oversight surface
   - renders state, evidence, alerts, queues, and bounded operator actions
   - must not become the authoritative executor or policy source
3. **Human operator**
   - remains the only approval authority for promotion, rejection, rollback, and autonomy-scope changes

Rule:
- the supervisor daemon is the autonomous operator behind the admin assistant, but it is not the same thing as the assistant UI

Canonical learning direction:
1. simulations are reviewed and learned by the reality model first
2. lower hierarchical agents do not train directly from raw simulation outputs as peer authorities
3. the reality model is the learning integrator that decides what learned outcomes are valid for downstream use
4. each hierarchy tier must synthesize the governed outcome it receives from the tier above into its own context before passing any bounded delta to the tier below
5. pertinent lower-tier agents only receive governed propagated outcomes such as updated priors, constraints, policy deltas, explanations, or domain-specific guidance
6. convictions must exist at every hierarchy tier in a bounded form appropriate to that tier's scope; each tier synthesizes the convictions and knowledge received from above before producing its own lower-tier delta
7. bounded convictions must be technically lifecycle-managed at every tier: agents must be able to create, challenge, corroborate, refine, strengthen, weaken, redact, supersede, and retire scoped convictions as more user activity, AI2AI signals, simulations, and real-world outcomes pass through the system
8. lower-tier convictions are authoritative only within their own scope, lineage, and temporal window; they may influence upper tiers through governed upward synthesis, but they must not directly mutate broader cross-hierarchy truth outside their bounded scope
9. sufficiently strong lower-tier convictions may propagate upward as governed candidates for broader review and may eventually contribute to reality-model updates, but only after hierarchy synthesis, truth review, corroboration/validation, and explicit governed integration
10. the reality model remains the top-level truth integrator, not the only conviction holder: it reconciles lower-tier scoped convictions, simulation-derived candidates, and real-world evidence into broader truth-review and propagation decisions
11. the personal agent is the final personalization layer: it receives already-governed reality-model knowledge through the intervening hierarchy and contextualizes that knowledge to the specific person rather than learning directly from raw simulation bundles
12. every downstream propagation path must preserve lineage back to the simulation basis, operator review, kernel state, reality-model learning outcome, and the scoped convictions synthesized at each intermediate tier
13. every intake, output, knowledge exchange, conviction update, and propagation step must carry precise temporal metadata rooted in the atomic/temporal kernel layer so offline events can later be reconciled with original event time, local-state time, sync time, and model-integration time
14. the same architecture must support the reverse learning loop: bounded personal-agent intake from human, AI2AI, and future sources must synthesize upward through the hierarchy into the reality-model agent, where real-world outcomes can validate or overturn simulation-derived convictions and feed future simulation/training
15. retrieval must be authority-first and vector-second: temporal lineage, hierarchy stage, locality/environment identity, conviction state, kernel phase, evidence refs, and review/learning/propagation status must remain the primary retrieval/filter surface, while embeddings may be used only as a bounded semantic-assist layer for fuzzy recall and related-case discovery rather than as the source of truth, lineage, or promotion authority
16. the reverse loop must treat reality intake as an explicit catalog, not an ad hoc future bucket: chat, AI2AI, onboarding, recommendation feedback, saved/discovery curation behavior, explicit corrections, check-ins, visits, locality observations, post-event feedback, event creation/planning changes, business/operator input, community moderation/coordination actions, reservation/calendar/sharing/recurrence signals, external confirmations/imports, supervisor or assistant bounded observations, and kernel/offline evidence must all be representable as governed upward intake classes even if they land in phases
17. recommendation feedback widening must not stop at storing feedback artifacts; a bounded feedback-prompt planner must sit directly on top of structured feedback items so the reality-model agent can ask intelligent follow-up questions grounded in what happened, why it was shown, how it was produced, when it happened, where it happened, and who was involved in scoped or pseudonymous form
18. the reality-model agent is not only a passive recipient of intake; it must be able to respond to governed intake by issuing clarifying questions, requesting corroborating evidence, generating bounded feedback/explanation tasks for admin or supervisor review, and proposing stronger simulation scenarios/hypotheses derived from the intake before any broader truth or propagation decision is made
19. onboarding counts as real-world reality intake, but as declared baseline preference/identity input rather than already-validated behavioral truth; it should seed scoped convictions and simulation priors, then later be corroborated or revised by observed behavior and outcomes
20. any signal that crosses off a personal device or exits a personal agent on its way to a higher hierarchy tier must first cross a mandatory air-gap-governed export boundary; governed upward intake must consume only air-gap-issued artifacts rather than direct raw personal-runtime payloads
21. personal-origin upward artifacts must be minimized, pseudonymized where possible, scope-bound, signed or attested, receipt-backed, replay-protected, and temporally lineage-aware; if those invariants are missing, the reverse loop must fail closed
22. the reverse loop is an evidence plane, not a self-authorizing control plane: personal-origin artifacts may challenge or support convictions, but they must never become executable authority, and any downstream return path must be centrally re-issued after review/simulation/approval rather than reflecting user-origin content back as trusted instruction

### Canonical Reality Intake Catalog

Every item below must be considered part of the explicit reality-intake surface for the reverse learning loop, even if individual connectors are staged later:

1. personal-agent human chat
2. AI2AI direct chat
3. AI2AI community chat
4. onboarding answers, dimensions, declared preferences, and baseline lists
5. recommendation feedback actions, including opens, saves, dismissals, and less-like-this signals
6. saved-list creation, editing, sharing, and curation behavior
7. explicit human corrections, contradictions, and redactions
8. automatic check-ins, check-outs, visit dwell, and locality/homebase observations
9. locality kernel observations, mesh locality exchanges, and offline locality evidence
10. post-event feedback, partner ratings, and attendance outcomes
11. event creation, planning, cancellation, rescheduling, and organizer refinements
12. business/operator-side edits, corrections, operational updates, and bounded business intelligence feedback
13. community moderation, approvals, declines, invitations, and coordination actions
14. reservation, calendar, sharing, recurrence, and similar lifecycle signals
15. search/query/reformulation behavior and high-signal abandonment or repetition patterns
16. external confirmations/imports such as calendar confirmations, reservations, receipts, RSVPs, or future linked-source evidence
17. supervisor-daemon or assistant bounded observations about repeated failure/success patterns
18. kernel-native or offline-first evidence receipts, including future knowledge/conviction-kernel exchanges

### Reality-Model Agent Duties Over Intake

For any governed upward intake class, the reality-model agent must be able to:

1. synthesize the intake into scoped convictions and broader truth candidates
2. ask bounded clarifying questions back through admin, supervisor, assistant, or personal-agent lanes when evidence is insufficient
3. request corroborating signals from other hierarchy tiers or intake families
4. generate feedback/explanation artifacts so operators understand what was learned, challenged, or held
5. propose stronger follow-on simulations that explicitly encode the intake as a new or revised hypothesis
6. compare those simulation outcomes against later real-world evidence before approving broader downstream propagation

### Reverse-Loop Air-Gap And Anti-Poisoning Invariants

The reverse loop must be hardened against privacy breach, poisoning, replay, and authority-escalation attacks.

Required invariants:
1. `GovernedUpwardLearningIntakeService` should evolve toward consuming only air-gap-issued upward artifacts for personal-origin signals
2. direct personal-runtime service-to-upward-staging calls are an interim implementation state, not the target architecture
3. every personal-origin upward artifact must carry an air-gap receipt or equivalent attestation, content hash, source scope, destination ceiling, issued-at time, and expiry or replay budget
4. higher tiers must treat those artifacts as evidence candidates only, never as privileged commands
5. downward artifacts returned to personal tiers must be newly issued, signed, scope-bound, and replay-protected rather than being raw or lightly transformed reflections of the original personal-origin payload
6. widening the reverse loop is subordinate to preserving these invariants; privacy/security hardening may block further intake expansion until the mandatory air-gap boundary is universal

### Reverse-Loop Emitter Map

The reverse loop now has an explicit emitter map for non-human governed observations.

Current canonical intake contracts:
1. `supervisor_bounded_observation_intake`
2. `assistant_bounded_observation_intake`
3. `kernel_offline_evidence_receipt_intake`

Current and planned service wiring:
1. `runtime/avrai_runtime_os/lib/services/admin/signature_health_admin_service.dart`
   - first real supervisor emitter
   - emits bounded supervisor observations from:
     - `reality_model_update_supervisor_brief.json`
     - `reality_model_update_validation_simulation_outcome.json`
     - `reality_model_update_downstream_repropagation_decision.json`
2. `runtime/avrai_runtime_os/lib/services/admin/replay_simulation_admin_service.dart`
   - second real supervisor emitter
   - should emit bounded simulation-supervisor observations from repeated accepted/denied/draft lab outcomes and replay-memory patterns
3. assistant backend/service lane
   - third emitter family
   - should emit bounded assistant observations from service/orchestration logic after the supervisor patterns are stable
4. `runtime/avrai_runtime_os/lib/kernel/service_contracts/urk_kernel_control_plane_service.dart`
   - future kernel/offline receipt emitter
   - should export kernel-native evidence through `kernel_offline_evidence_receipt_intake`, not through supervisor observation
5. `runtime/avrai_runtime_os/lib/kernel/contracts/urk_runtime_activation_receipt_dispatcher.dart`
   - future activation/offline receipt emitter
   - should also use `kernel_offline_evidence_receipt_intake`
6. `runtime/avrai_runtime_os/lib/services/ai_infrastructure/model_safety_supervisor.dart`
   - later optional supervisor emitter for repeated safety drift, rollback pressure, or bounded promotion hesitation patterns
7. `runtime/avrai_runtime_os/lib/services/admin/governed_run_kernel_service.dart`
   - later optional governed-execution emitter for bounded run-kernel supervision signals

Non-emitter rule:
- admin UI pages such as command center, reality oversight, world model, and world simulation lab are display surfaces only; they must consume the governed observation state but must not originate those observations directly.

---

## 2. What Is Complete

The following baseline is already implemented and should be treated as architecture, not future intent:

1. Backend-authoritative control-plane contracts for jobs, evidence, promotion decisions, policy, and supervisor learning
2. Runtime control-plane facade and authority-store seam
3. Supervisor daemon plus governed bootstrap startup
4. Policy-backed actor capability enforcement and fail-closed human judgment gates
5. End-to-end autonomy coverage for pause/resume, waiting-human materialization, approval lineage, rollback lineage, remote-authority degradation, and restart rehydration
6. Admin command-center, training, and oversight surfaces consuming the control-plane facade
7. Shared recommendation and attention surfaces in admin, including bounded operator actions and command-center handoff deep links

Completed execution anchors:
1. `M31-P10-5`
2. `M31-P10-3`
3. `M31-P7-1`
4. `M31-P3-1`

---

## 3. Current Boundary

The control plane is governed and durable, but simulation/training quality is not yet fully generic underneath it.

Current limitation:
1. The underlying replay/training executors are still BHAM-first beneath the now-generic contract layer
2. City-pack structural semantics are propagated far deeper than before, but not yet with full multi-environment execution parity
3. Admin can govern and inspect multi-environment work more generically than the deepest executor stack can currently execute it

This means the architecture is correct, but execution quality parity is still incomplete.

Temporal boundary still to be completed after the current live-consumer slice:
1. once propagated learning affects the relevant live runtime/app consumers, the full downward chain must be reviewed for atomic timing correctness and kernel-state lineage at every hop
2. only after that downward timing pass should the reverse, upward learning lane be implemented from personal-agent intake through hierarchy synthesis into the reality-model agent

Remaining preferred downward live-consumer order before the timing pass:
1. `venue` should be the next live runtime/app consumer because it completes the strongest remaining place-event behavior seam before temporal review
2. `business` should follow `venue` so governed business intelligence can later support bounded business-intelligence API surfaces and sales-facing productization without bypassing reality-model governance
3. after `venue` and `business`, additional live consumers for `place`, `community`, `locality`, `event`, and `list` may continue to broaden runtime/app behavior where useful, but they are lower priority than finishing the timing/kernel pass
4. direct `personal_agent` behavior from propagated deltas is intentionally deferred until after the downward timing/kernel audit because that layer is the most timing-sensitive and offline-sensitive endpoint in the hierarchy

---

## 4. Canonical Next Anchor

The next milestone for this lane is:

1. **`M31-P10-6`**
   - **Title:** Reality-model autonomous control plane stage 2: multi-environment executor parity + admin simulation/training quality

Purpose of `M31-P10-6`:
1. complete multi-environment execution parity beneath the generic control-plane contract
2. remove remaining BHAM-first assumptions from replay/training executors where generic environment contracts already exist
3. improve admin simulation/training quality surfaces so evidence, contradictions, overlays, and operator recommendations remain environment-correct across city packs
4. make the simulation-to-learning lane explicit: strong simulations must feed governed reality-model learning outcomes before any downstream agent propagation
5. keep all runtime approval gates, policy controls, and fail-closed behavior intact during the quality/generalization work
6. finish the downward propagation lane as live runtime/app behavior before opening the upward learning lane
7. after the downward lane is behaviorally complete, add a timing/kernel pass over the whole chain before implementing the upward personal-agent-to-reality-model learning path
8. keep retrieval architecture aligned with the same rule set: structured temporal/hierarchy/locality/conviction retrieval is authoritative, and any vector search remains subordinate semantic assistance rather than replacing kernel-governed evidence lookup

`M31-P10-6` is the canonical tracking anchor for autonomous simulation/training quality work until it is closed and replaced by a later milestone.

Ordered build sequence inside `M31-P10-6`:
1. make admin consume the post-learning `admin_evidence_refresh_snapshot_*.json` artifacts as the preferred evidence source
2. make the supervisor/admin-assistant lane consume `supervisor_learning_feedback_state_*.json` as bounded feedback for recommendation posture and retry heuristics
3. add the first real hierarchy/domain propagation consumer as a governed local domain-delta artifact
4. present the resulting chain coherently in admin as:
   - `simulation -> reality-model learning outcome -> admin evidence refresh -> supervisor feedback -> domain propagation delta`
5. finish the downward learning chain as live runtime/app behavior with this preferred remaining order:
   - `venue` first
   - `business` second
   - then any additional high-value `place` / `community` / `locality` / `event` / `list` consumers
6. only after that breadth is sufficient should the lane switch to the downward timing/kernel pass
7. direct `personal_agent` behavior remains deferred until after the timing/kernel audit

Locked follow-on after `M31-P10-6` closes:

1. **`M31-P10-7`**
   - **Title:** Reality-model environment/city-pack structural-ref parity + artifact-boundary hardening

Purpose of `M31-P10-7`:
1. lock environment identity, city-pack semantics, and structural refs through runtime environment registry, export-manifest, boundary, and partition seams
2. prevent post-stage-2 drift where multi-environment execution technically works but downstream artifacts, storage paths, or admin evidence fall back to BHAM-era assumptions
3. keep this follow-on scoped to runtime artifact correctness and storage-boundary reuse rather than reopening control-plane authority or admin-UI ownership

Queued follow-on after `M31-P10-7` closes:

1. **`M31-P10-8`**
   - **Title:** World Simulation Lab + supervisor daemon all-outcome feedback learning

Purpose of `M31-P10-8`:
1. add a first-class admin `World Simulation Lab` surface for booting, iterating, comparing, and annotating any registered replay environment or city-pack simulation before training-intake decisions
2. preserve operator dispositions for both accepted and denied lab outcomes with simulation basis, environment identity, structural refs, kernel state, and rationale lineage
3. let the supervisor daemon learn from all lab outcomes, including denied ones, as labeled evidence for rejection memory, contradiction priors, routing heuristics, review policy refinement, and anti-pattern detection
4. keep the hard boundary where only accepted lab outcomes may become explicit reality-model learning candidates or downstream propagation inputs
5. keep admin non-authoritative and fail closed on promotion, rollback, and approval authority
6. expose synthetic-human kernel coverage, higher-agent behavior, and locality-hierarchy effectiveness in the lab so operators can improve simulation realism before any training handoff

Tracked `M31-P10-8` operator-introspection sub-slices:
1. `Synthetic Human Kernel Explorer`
2. `Locality Hierarchy Health`
3. `Higher-Agent Handoff View`
4. `Realism Provenance Panel`
5. `Weak Spots Before Training Summary`

Queued follow-on after `M31-P10-8` closes:

1. **`M31-P10-9`**
   - **Title:** Living city-pack refresh loop + latest-state simulation hydration

Purpose of `M31-P10-9`:
1. treat city packs as versioned structural identities with continuously refreshed sidecars and latest-state simulation inputs rather than one-off seed bundles
2. hydrate simulations for any supported operator-selected place from the latest available AVRAI evidence across app, runtime/OS, and governed reality-model outputs
3. preserve explicit lineage, freshness receipts, and rollback-safe historical versions so the served city-pack basis never mutates invisibly
4. let `World Simulation Lab` boot against the newest supported state while still allowing replay against earlier versioned baselines
5. carry atomic-time or quantum-time validity metadata where available as coherence/freshness context without redefining the current classical/native execution boundary

Queued follow-on after `M31-P10-9` closes:

1. **`M31-P10-10`**
   - **Title:** Simulation/training temporal backbone + atomic/When-kernel lineage authority

Purpose of `M31-P10-10`:
1. make the temporal-kernel layer authoritative for simulation-to-training timing rather than leaving snapshots outcomes reruns reviews and exports on scattered UTC-only `DateTime` fields
2. move the lane onto the existing `AtomicClockService -> AtomicClockTemporalAdapter -> TemporalKernel -> When/native kernel` backbone, with system-kernel fallback preserved and audited
3. add additive temporal receipts and envelopes across simulation snapshots, lab outcomes, rerun requests/jobs, bounded-review handoffs, and training exports without breaking compatibility during migration
4. record the simulation-lab and training-handoff lifecycle as kernel-backed runtime temporal events so freshness, ordering, and replay lineage can be queried and audited end to end
5. make downstream review/training gating depend on temporal freshness and ordering policy instead of ad hoc timestamp comparisons while keeping current classical/native execution and governance boundaries fail closed

---

## 5. Required Scope For `M31-P10-6`

The stage-2 executor-parity lane must explicitly cover:

1. **Generic executor parity**
   - replay/training execution paths consume `ReplayTrainingEnvironmentConfig` and city-pack semantics without BHAM-only branching as the default assumption
2. **Artifact parity**
   - generated environments, corpora, manifests, reports, and downstream runtime artifacts preserve and use environment-specific structural refs consistently
3. **Admin quality parity**
   - admin surfaces remain evidence-correct across environments and do not regress into BHAM-specific interpretation logic
4. **Reality-model-first learning lane**
   - accepted simulations become explicit reality-model learning candidates with clear targeted learning pathways, not generic “retrain everything” artifacts
   - downstream lower-agent propagation must be governed as a post-learning consequence of reality-model outcomes, not a direct read of raw simulation bundles
   - denied simulation-lab outcomes must still be retained as labeled learning evidence for the supervisor daemon, but not as implicit promotion candidates
5. **Governance preservation**
   - promotion, rejection, rollback, supervisor policy, and evidence gates remain runtime-governed and fail closed
6. **Verification**
   - runtime and admin tests prove non-BHAM environments work through the real execution path, not just through synthesis or metadata preservation
7. **Temporal/kernel correctness**
   - every accepted learning handoff, downstream propagation step, and later upward synthesis path must be capable of carrying atomic-timing metadata and kernel-state lineage, including offline personal-agent events

---

## 6. Out Of Scope

The following are not part of `M31-P10-6` unless explicitly added later:

1. new promotion authorities
2. self-approving supervisor behavior
3. moving model logic into admin
4. broad UI redesign unrelated to simulation/training quality
5. unrelated command-center or consumer-shell work already closed under other milestones

---

## 7. Update Rules

If work changes this lane:

1. update `docs/agents/status/status_tracker.md`
2. update `docs/EXECUTION_BOARD.csv`
3. keep this architecture file aligned with the current execution anchor
4. if admin simulation/training surfaces change materially, also update:
   - `apps/admin_app/README.md`
   - `docs/plans/architecture/ADMIN_COMMAND_CENTER_FUTURE_REFERENCES_2026-02-28.md`
