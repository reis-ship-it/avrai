# M31-P10-6 Baseline: Reality-Model Autonomous Control Plane Stage 2 Multi-Environment Executor Parity

Date: 2026-03-31
Milestone: M31-P10-6
Master Plan refs: 10.9.12, 10.9.22, 10.9.23, 10.9.24, 10.9.25

## Scope

Advance the reality-model autonomous control plane from stage-1 authority/governance completion into stage-2 execution quality by making replay/training execution parity truly multi-environment beneath the generic contract layer, by improving admin simulation/training quality surfaces accordingly, and by making the learning direction explicit: simulations train the reality model first, then governed learned outcomes propagate to pertinent lower-tier agents through contextual synthesis and bounded conviction at each hierarchy tier until the personal agent receives the final personalized form.

## Deliverables

1. Stage-2 baseline:
   - `docs/plans/methodology/M31_P10_6_REALITY_MODEL_AUTONOMOUS_CONTROL_PLANE_STAGE2_MULTI_ENVIRONMENT_EXECUTOR_PARITY_BASELINE.md`
2. Stage-2 controls:
   - `configs/runtime/reality_model_autonomous_control_plane_stage2_multi_environment_executor_parity_controls.json`
3. Architecture authority:
   - `docs/plans/architecture/REALITY_MODEL_AUTONOMOUS_CONTROL_PLANE_AND_SUPERVISOR_DAEMON_2026-03-30.md`
4. Board/tracker wiring:
   - `docs/EXECUTION_BOARD.csv`
   - `docs/EXECUTION_BOARD.md`
   - `docs/agents/status/status_tracker.md`

## Explicit Objectives

1. eliminate remaining BHAM-first executor assumptions where generic environment contracts already exist
2. ensure structural refs and city-pack semantics are not just preserved but actively used by the execution path across environments
3. keep admin simulation/training evidence, contradictions, overlays, and recommendations environment-correct across city packs
4. make accepted simulation outputs produce explicit reality-model learning candidates, outcomes, and lineage before any lower-agent propagation
5. preserve fail-closed runtime governance, policy, and human-approval boundaries while improving execution quality

## Guardrails

1. admin remains the command center, not the authoritative executor
2. runtime/backend remains the authority for jobs, evidence, lineage, policy, and supervisor decisions
3. no new path may bypass promotion/rollback evidence gates
4. lower hierarchical agents must not train directly from raw simulation bundles as peer authorities to the reality model
5. downstream propagation must be derived from governed reality-model learning outcomes with preserved simulation and kernel-state lineage
6. each hierarchy tier must synthesize the governed knowledge received from the tier above into its own bounded contextual form before propagating to the next lower tier; the personal agent is the final personalization layer, not a direct raw-simulation trainee
7. convictions must exist and evolve at every hierarchy tier, not only in the reality model; each tier must be able to create, challenge, corroborate, refine, redact, supersede, and retire scoped convictions as more evidence and scenarios flow through the system
8. lower-tier convictions remain scoped and lineage-bound; they may influence the reality model only through governed upward synthesis, and sufficiently strong/corroborated convictions may become candidates for later reality-model updates, while the reality model remains the sole integrator of broader cross-tier truth decisions
9. each intake, output, knowledge exchange, conviction update, and propagation step must be able to carry atomic/temporal kernel timing so offline events can later be reconciled with exact event-time and state-time lineage
10. multi-environment parity must be proved through runtime and admin tests, not only through documentation or metadata propagation
11. retrieval for this lane must stay kernelized and authority-first: temporal lineage, hierarchy stage, locality/environment identity, conviction state, evidence refs, and governed status are the primary retrieval surface; vector or embedding lookup may exist only as a bounded semantic-assist layer for fuzzy recall and related-case discovery
12. the reverse learning lane must be modeled against an explicit reality-intake catalog, not an implied future bucket; onboarding, recommendation feedback, saved-list curation, explicit corrections, check-ins, visits, locality observations, post-event feedback, event planning changes, business/operator input, community coordination/moderation actions, reservation/calendar/sharing/recurrence signals, external confirmations/imports, supervisor/assistant bounded observations, and kernel/offline evidence are all in-scope intake families for later governed upward integration
13. recommendation feedback widening must include a bounded feedback-prompt planner that is directly connected to structured feedback items, so the runtime can generate follow-up prompts using explicit event, attribution, timing, locality, and scoped actor context rather than relying on raw text reconstruction
13. the reality-model agent must be able to ask bounded clarifying questions, generate bounded feedback/explanation artifacts, and propose stronger simulation candidates from governed intake before broader truth mutation or downstream propagation is approved
14. onboarding is explicitly part of real-world reality intake for hierarchy propagation, but as declared baseline preference/identity input rather than already-validated behavioral truth

## Active Build Order

While `M31-P10-6` is open, build the stage-2 lane in this order so functionality is reused instead of re-derived independently across pages or targets:

1. consume `admin_evidence_refresh_snapshot_*.json` in admin surfaces as the preferred post-learning evidence source for what the reality model learned, what changed, and what propagated
2. consume `supervisor_learning_feedback_state_*.json` in the supervisor/admin-assistant lane as bounded feedback for recommendation wording, retry posture, and attention priority
3. add the first concrete hierarchy/domain propagation consumer as a real local domain-delta artifact, not a generic propagation receipt
4. surface the full chain in admin as one inspectable flow:
   - `simulation -> reality-model learning outcome -> admin evidence refresh -> supervisor feedback -> governed domain propagation delta`
5. finish the downward learning chain as actual live runtime/app behavior, not only artifacts or summaries
6. prioritize the remaining live-consumer breadth in this order:
   - `venue`
   - `business`
   - then additional `place` / `community` / `locality` / `event` / `list` consumers as needed
7. keep direct `personal_agent` runtime behavior deferred until after the downward timing/kernel pass even if its propagation artifacts already exist
8. after the downward lane is behaviorally complete, run a temporal/kernel correctness pass over the whole chain before starting the reverse personal-agent-to-reality-model learning lane
9. keep retrieval implementation aligned while building: structured temporal/hierarchy/locality/conviction retrieval should be reused as the canonical evidence path across admin, runtime, and later upward learning, while vector search stays optional and subordinate
10. when the reverse learning lane widens, widen it in explicit intake-family order rather than ad hoc page-by-page:
   - onboarding
   - recommendation feedback
   - check-ins / visits / locality observations
   - post-event feedback and event outcomes
   - explicit corrections
   - saved/discovery curation behavior
   - business/operator input
   - community coordination/moderation actions
   - reservation / calendar / sharing / recurrence signals
   - external confirmations/imports
   - supervisor/assistant bounded observations
   - kernel/offline evidence receipts

## Exit Criteria

1. a canonical milestone anchor exists for post-stage-1 autonomy quality work
2. the execution board points to `M31-P10-6` as the active next lane for this autonomy track
3. the architecture authority and tracker both explicitly reference `M31-P10-6`
4. later implementation under this milestone demonstrates true multi-environment executor parity and admin quality parity before closeout
5. the implemented lane clearly records that simulations feed the reality model first and that lower-tier agent propagation is governed downstream of reality-model learning outcomes
6. the completed lane leaves the architecture ready for a later reverse learning path from personal-agent intake upward into the reality-model agent, with atomic timing and conviction lineage preserved at every hierarchy tier
7. the completed lane also leaves retrieval direction unambiguous: AVRAI uses structured temporal/kernel retrieval as the authority and may only use vectors as a bounded semantic helper
