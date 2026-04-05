# M31-P10-8 Baseline: World Simulation Lab + Supervisor Daemon All-Outcome Feedback Learning

Date: 2026-04-01
Milestone: M31-P10-8
Master Plan refs: 10.9.12, 10.9.22, 10.9.23, 10.9.24, 10.9.25

## Scope

Follow `M31-P10-7` with an admin/runtime slice that adds a first-class `World Simulation Lab` pre-training workflow and teaches the supervisor daemon from all lab outcomes, including denied ones, while preserving explicit disposition lineage and keeping promotion/training authority fail-closed.

## Deliverables

1. Follow-on baseline:
   - `docs/plans/methodology/M31_P10_8_WORLD_SIMULATION_LAB_SUPERVISOR_DAEMON_ALL_OUTCOME_FEEDBACK_BASELINE.md`
2. Follow-on controls:
   - `apps/avrai_app/configs/runtime/world_simulation_lab_supervisor_daemon_all_outcome_feedback_controls.json`
3. Architecture authority:
   - `docs/plans/architecture/REALITY_MODEL_AUTONOMOUS_CONTROL_PLANE_AND_SUPERVISOR_DAEMON_2026-03-30.md`
4. Admin reference authority:
   - `docs/plans/architecture/ADMIN_COMMAND_CENTER_FUTURE_REFERENCES_2026-02-28.md`
5. Board/tracker wiring:
   - `docs/EXECUTION_BOARD.csv`
   - `docs/EXECUTION_BOARD.md`
   - `docs/agents/status/status_tracker.md`

## Explicit Objectives

1. add a dedicated `World Simulation Lab` admin surface for booting, rerunning, comparing, and annotating any registered replay environment or city-pack simulation before any training-intake action
2. make simulation iteration first-class in admin: scenario templates, interventions, comparisons, contradiction clusters, truth receipts, locality overlays, and operator notes should be treated as lab artifacts rather than hidden pre-training plumbing
3. preserve accepted and denied dispositions with rationale, environment identity, city-pack semantics, scenario/intervention lineage, kernel state, and operator context
4. ensure the supervisor daemon learns from all lab outcomes, including denied ones, as labeled evidence for rejection memory, contradiction priors, routing heuristics, review policy refinement, and anti-pattern detection
5. keep a hard boundary where only accepted lab outcomes may become explicit reality-model learning candidates or downstream propagation inputs
6. add operator-facing introspection for synthetic-human kernel coverage and higher-agent/locality-hierarchy behavior, so simulation realism can be improved before training by inspecting which kernels are attached, active, sparse, or distorting locality truth

## Tracked Operator Introspection Sub-Slices

1. `Synthetic Human Kernel Explorer`
   - expose per-actor attached kernels, ready kernels, activation counts, and higher-agent guidance density so operators can see which synthetic humans are under-modeled or over-steered
2. `Locality Hierarchy Health`
   - expose locality pressure quality, overlay stability, boundary risk, fallback reliance, and handoff quality across locality and city hierarchy layers
3. `Higher-Agent Handoff View`
   - expose what higher agents are aggregating, escalating, and routing downward so the lab can distinguish healthy hierarchy synthesis from distortion or overreach
4. `Realism Provenance Panel`
   - expose population-model kind, synthetic batch assumptions, sidecar influence, and realism-pack provenance so operators can see exactly what shaped a simulation environment
5. `Weak Spots Before Training Summary`
   - expose the highest-risk kernels, unstable localities, sparse actor lanes, and over-guided higher-agent traces as a compact pre-training realism audit

## Execution Note

- First operator-introspection slice landed on April 2, 2026: runtime/admin snapshots now materialize bounded synthetic-human kernel coverage, locality hierarchy health, higher-agent handoff posture, realism provenance, and weak-spot summaries, and World Simulation Lab renders those as first-class operator cards before bounded review or training.
- Drill-down expansion landed the same day: synthetic-human lanes now expose explicit attached/ready/missing kernel bundles plus bundle trace, locality hierarchy tiles now expose hierarchy trace, higher-agent handoff tiles now expose trace context, realism provenance now surfaces scenario/overlay/artifact-family counts, and weak spots now preserve trace anchors for the failing lane.
- Persisted lane-history expansion landed the same day: recorded lab outcomes and executed rerun jobs now retain synthetic-human kernel lane snapshots, and World Simulation Lab uses those artifacts to render per-lane kernel activation history over time instead of relying only on the current snapshot.
- Persisted higher-agent handoff lineage landed the same day: recorded lab outcomes and executed rerun jobs now also retain higher-agent handoff items, and World Simulation Lab uses those artifacts to render locality-to-city handoff posture over time instead of relying only on the current handoff summary.
- Persisted locality hierarchy history landed the same day: recorded lab outcomes and executed rerun jobs now also retain locality hierarchy node summaries, and World Simulation Lab uses those artifacts to render per-locality hierarchy posture over time instead of relying only on the current locality health snapshot.
- Persisted realism provenance history landed the same day: recorded lab outcomes and executed rerun jobs now also retain realism provenance summaries, and World Simulation Lab uses those artifacts to render provenance history over time instead of relying only on the current pack/sidecar snapshot.
- Provenance-delta emphasis landed the same day: World Simulation Lab now highlights the latest added/removed sidecars, artifact-family changes, and any city-pack identity shift between the last two persisted provenance samples instead of forcing operators to diff provenance history manually.
- Shared-review provenance-delta surfacing landed the same day: World Model and Signature + Source Health now preserve that same latest provenance delta per target lane, so the shared bounded-review queues can show pack/sidecar and city-pack-identity changes without forcing operators to reopen World Simulation Lab for provenance-only context.
- Shared-review provenance-history surfacing landed the same day: World Model and Signature + Source Health now also preserve compact provenance history over time per target lane, so the shared bounded-review queues can show persisted-sample counts plus recent provenance-change entries instead of treating shared review as a latest-delta-only surface.
- Shared-review provenance-churn emphasis landed the same day: World Model and Signature + Source Health now derive a bounded provenance-churn severity per target lane and use it for card-level review emphasis plus `Priority` queue ranking, so recent realism-pack churn can raise operator attention alongside runtime severity without introducing a separate provenance-only queue mode.
- Shared-review provenance-aware sort mode landed the same day: World Model and Signature + Source Health now expose a dedicated `Provenance churn` queue mode, so operators can intentionally rank simulation lanes by recent realism-pack churn instead of relying only on blended priority ordering.
- Shared-review bounded runtime/provenance alerting landed the same day: World Model and Signature + Source Health now derive a combined bounded-alert signal when runtime instability and realism-pack churn spike together, surface that alert directly on shared review cards, and fold it into default priority ordering so operators do not have to mentally reconcile two separate risk signals before triaging a lane.
- Shared-review bounded-alert sort mode landed the same day: World Model and Signature + Source Health now expose a dedicated `Bounded alerts` queue mode, so operators can intentionally rank simulation lanes by the combined runtime-instability-plus-provenance-churn alert signal instead of relying only on blended priority ordering.
- Shared-review alert acknowledgment landed the same day: World Model and Signature + Source Health now let operators mark a combined bounded alert as seen without mutating routing posture, and that acknowledgment persists against the current alert severity so the shared review snapshot can distinguish unseen alerts from acknowledged-but-still-active lanes.
- Shared-review bulk alert acknowledgment landed the same day: World Model and Signature + Source Health now let operators mark the currently visible combined bounded alerts as seen in one step under the active environment and target filters, so multi-lane queue review can clear acknowledged alert noise without changing routing posture or losing queue focus.
- Shared-review alert escalation/snooze landed the same day: World Model and Signature + Source Health now let operators escalate a lane-level bounded alert or snooze it for 24 hours per environment/target lane, and that operator state persists without mutating the underlying bounded-review routing posture or losing the alert lineage.
- Shared-review bulk alert escalation/snooze landed the same day: World Model and Signature + Source Health now let operators bulk-escalate or bulk-snooze the currently visible bounded-alert lanes under the active environment and target filters, so multiple visible lanes can be raised or temporarily quieted together without mutating their underlying bounded-review routing posture.
- Shared-review bulk alert de-escalation/unsnooze landed the same day: World Model and Signature + Source Health now let operators bulk-clear escalation or bulk-unsnooze the currently visible bounded-alert lanes under the active environment and target filters, so previously applied alert-state management can be reversed in one step without mutating the underlying bounded-review routing posture.
- Shared-review managed-alert visibility polish landed the same day: World Model and Signature + Source Health now surface explicit filter-scoped escalated/snoozed lane counts beside those bulk controls and keep the bulk clear-escalation/unsnooze actions visible even when the current filter only contains already-managed lanes, so operators can reverse alert-state management without relying on inference from the remaining button set alone.
- Shared-review snooze-expiry visibility landed the same day: World Model and Signature + Source Health now surface the earliest visible snooze expiry as `Next unsnooze` under the active environment and target filters, so operators can see when a snoozed lane will naturally re-enter the active queue before deciding whether to bulk unsnooze it manually.
- Shared-review relative alert-age visibility landed the same day: World Model and Signature + Source Health now render escalated and snoozed alert timing relative to the current snapshot, so managed lanes read as windows like `6h before this snapshot` and `7d+ after this snapshot` instead of forcing operators to infer urgency from raw UTC stamps alone.

## Guardrails

1. this follow-on starts only after `M31-P10-7` closeout
2. admin remains the command surface and human-oversight UI, not the authoritative executor or policy source
3. denied lab outcomes must never silently self-promote training, propagation, or serving changes
4. every lab run must preserve environment identity, structural refs, scenario/intervention lineage, operator disposition, and rationale
5. the `World Simulation Lab` is a pre-training iteration surface, not a bypass around existing promotion, rollback, or approval gates

## Exit Criteria

1. a canonical queued milestone exists for the post-`M31-P10-7` simulation-lab lane
2. the execution board explicitly records `M31-P10-8` as the next tracked follow-on after `M31-P10-7`
3. the architecture authority and status tracker both state that the supervisor daemon should learn from accepted and denied lab outcomes with preserved disposition tags
4. later implementation proves operators can iterate on non-BHAM and non-Savannah replay environments in admin before training-intake decisions
5. later implementation proves denied outcomes are retained as learning evidence without becoming implicit promotion candidates

## Locked Follow-On

After `M31-P10-8`, queue `M31-P10-9` to treat city packs as living versioned simulation substrates whose latest-state basis is refreshed from app, runtime/OS, and governed reality-model evidence for any supported place while preserving freshness receipts and rollback-safe lineage.
