# Governed Autoresearch Kernel Architecture

**Date:** March 14, 2026  
**Status:** Active companion architecture spec  
**Purpose:** Define how AVRAI should implement `autoresearch`-style autonomous research as a governed kernel family with continuous admin human-in-the-loop oversight, full explainability, and staged rollout requirements for beta, post-beta, and true v1 launch.
**Companion authorities:** `AUTONOMOUS_RESEARCH_EXPERIMENTATION_ENGINE.md`, `ADMIN_COMMAND_CENTER_IDEAL_ARCHITECTURE_2026-02-28.md`, `AUTONOMOUS_SECURITY_IMMUNE_SYSTEM_2026-03-13.md`, `AVRAI_COGNITIVE_OS_DOCTRINE_2026-03-06.md`

---

## 1. Core Position

AVRAI should adopt the useful inner-loop idea from `autoresearch`:

- propose a bounded hypothesis,
- run a measurable experiment,
- inspect the result,
- keep or discard the candidate,
- and explain what happened.

But AVRAI should **not** adopt the raw form of `autoresearch` as the system-wide authority.

AVRAI is a governed three-prong platform, not a single mutable research repo. Therefore the implementation target is:

**Governed Autoresearch = autonomous research generation inside the Reality Model, supervised by Runtime OS, continuously inspectable and interruptible from Admin.**

This means:

1. the research loop may be autonomous,
2. production promotion may not be autonomous in beta,
3. human oversight must remain available at all times,
4. every run must be explainable, replayable, and stoppable,
5. and all authority must flow through prong-correct contracts.

---

## 2. Why AVRAI Needs A Governed Form

Raw `autoresearch` is strong at:

- rapid iteration,
- hypothesis mutation,
- fixed-metric optimization,
- and code-level experimentation.

Raw `autoresearch` is weak for AVRAI because AVRAI also requires:

- immutable guardrails,
- promotion gates,
- rollback bundles,
- privacy-safe admin visibility,
- contract-first prong boundaries,
- and human final oversight.

Therefore the AVRAI variant must replace:

- "single mutable loop"

with:

- "sandboxed research worker + immutable supervisor + admin oversight cockpit"

This is consistent with the AVRAI doctrine that early launch systems may give humans broader visibility for safety validation, but that visibility must remain explicit, audited, and policy-governed.

---

## 3. Outcome This Locks In

AVRAI's governed autoresearch kernel is successful when:

1. research runs can start, pause, resume, stop, redirect, and explain through canonical runtime controls,
2. admin can inspect the full current research state at any time without relying on local-only UI state,
3. reality-model experimentation is isolated from production promotion,
4. every research action writes append-only provenance and checkpoint data,
5. redirecting a run creates a new revision instead of mutating prior history,
6. the system can explain why it is researching, what changed, what evidence it used, and what it plans to do next,
7. and launch tiers enforce progressively broader autonomy only after the earlier governance capabilities are proven.

---

## 4. Canonical Three-Prong Split

### 4.1 Apps Prong

The admin app and any future operator surfaces own:

- research dashboard rendering,
- timeline and checkpoint inspection,
- operator controls,
- explanation surfaces,
- approval and disposition UI,
- and privacy-safe visualization of run state.

Apps do **not** own:

- experiment execution,
- policy enforcement,
- promotion logic,
- or mutable model internals.

### 4.2 Runtime OS Prong

Runtime OS is the authoritative supervisor.

It owns:

- run scheduling,
- sandbox creation,
- checkpointing,
- operator command handling,
- policy enforcement,
- budget ceilings,
- kill switches,
- evidence capture,
- replay/shadow/canary transitions,
- and promotion routing.

Runtime OS is the layer that makes "pause now", "stop now", and "hold for review" real.

### 4.3 Reality Model Prong

The reality model owns:

- hypothesis generation,
- experiment-plan generation,
- result interpretation,
- ranking of next candidate moves,
- evidence-weight adjustment,
- and research explanation synthesis over model-side reasoning.

The reality model may propose. It may not silently self-authorize production mutation.

---

## 5. Hard Invariants

These are non-self-modifying:

1. Research runs execute in sandbox, replay, shadow, or canary lanes only until promotion gates explicitly allow more.
2. No research worker may directly flip production behavior in beta.
3. Human override always wins over autonomous continuation.
4. Every run must have a charter, budget, and stop condition before execution begins.
5. Every run must emit append-only provenance, checkpoints, and artifacts.
6. Pause, stop, resume, redirect, and explain are runtime capabilities, not optional UI features.
7. Redirect never rewrites history. It creates a new charter revision linked to the prior run.
8. All admin visibility must be privacy-safe and policy-scoped.
9. High-impact promotions require explicit human disposition.
10. If explanation provenance is missing, the run is not promotable.

---

## 6. Required Research Artifacts

Every governed autoresearch run must bind to the following artifacts:

### 6.1 Research Charter

Canonical fields:

- `charter_id`
- `objective`
- `scope`
- `allowed_surfaces`
- `forbidden_surfaces`
- `success_metrics`
- `failure_metrics`
- `risk_class`
- `budget_limits`
- `required_review_level`
- `stop_conditions`
- `privacy_constraints`

This is the contract for what the run is allowed to try.

### 6.2 Operator Directives

Operator directives are additive constraints or redirects layered onto an approved charter.

Examples:

- "stay within recommendation ranking only"
- "do not use external research this run"
- "retest against Birmingham replay pack before proceeding"
- "stop exploring dream-lane hypotheses"

### 6.3 Experiment Ledger

Append-only record of:

- hypotheses,
- prompts/plans,
- code or policy diffs,
- dataset or evidence references,
- metrics,
- checkpoints,
- explanations,
- operator commands,
- and final disposition.

### 6.4 Promotion Manifest

Separate artifact for any candidate that graduates from research into rollout review.

It must include:

- candidate identifier,
- tested lanes,
- measured lift,
- regressions,
- contradictions,
- privacy review result,
- rollback target,
- approving humans,
- and rollout scope.

---

## 7. Runtime State Machine

The run lifecycle is:

1. `draft`
2. `approved`
3. `queued`
4. `running`
5. `pausing`
6. `paused`
7. `redirect_pending`
8. `redirected`
9. `stopped`
10. `review`
11. `promoted`
12. `archived`

Rules:

1. Only `approved` runs may enter `queued`.
2. `running -> pausing -> paused` is the normal cooperative pause path.
3. `running -> stopped` is the break-glass termination path.
4. `running -> redirect_pending -> redirected` requires a new charter revision.
5. `review -> promoted` requires promotion evidence, not just model preference.
6. `stopped` and `archived` are immutable terminal states.

---

## 8. Control Semantics

### 8.1 Pause

`Pause` means:

- capture operator intent immediately,
- stop admitting new experiments,
- checkpoint current work,
- and halt at the next safe boundary.

Normal pause is cooperative and integrity-preserving.

### 8.2 Stop

`Stop` means:

- terminate active work immediately or at the fastest safe kill path,
- freeze the current run state,
- preserve logs, artifacts, and branch state,
- and block automatic restart.

This is the break-glass operator control.

### 8.3 Resume

`Resume` means:

- restart from the latest valid checkpoint,
- under the same charter revision and directive set,
- unless the operator explicitly rebinds the run to a new revision.

### 8.4 Redirect

`Redirect` means:

- create a new revision of the research charter,
- attach operator rationale,
- preserve linkage to the prior run,
- and fork future work from the new revision only.

Redirect is not silent live-editing.

### 8.5 Explain

`Explain` must be available:

- while queued,
- while running,
- while paused,
- during review,
- and after archival.

The system must be able to answer:

1. why this research was started,
2. what it is trying now,
3. what changed recently,
4. what evidence supports the current direction,
5. what risks or blockers exist,
6. and what will happen next if not interrupted.

---

## 9. Admin HiTL Cockpit Requirements

The admin app must expose a dedicated governed autoresearch cockpit with:

1. active run list,
2. queued run list,
3. paused run list,
4. promotion review queue,
5. charter and directive viewer,
6. experiment timeline with atomic timestamps,
7. live metrics and budget consumption,
8. checkpoint browser,
9. current diff/artifact view,
10. operator command history,
11. explanation panel,
12. replay/shadow/canary evidence tabs,
13. rollback target visibility,
14. privacy and policy gate status,
15. scoped `pause`, `stop`, `resume`, and `redirect` controls,
16. explicit `approve for review` and `reject` disposition controls.

The cockpit must read from canonical runtime state services, not a local-only mirror.

---

## 10. Explanation Contract

Every run must produce two explainability layers:

### 10.1 Operator Summary

Short-form human-readable explanation:

- current objective,
- current hypothesis,
- last completed experiment,
- latest outcome,
- current risk level,
- next planned step.

### 10.2 Forensic Trace

Machine-linked evidence chain:

- charter revision,
- evidence bundle IDs,
- experiment plan IDs,
- sandbox or replay lane IDs,
- metric deltas,
- contradiction flags,
- applied policy gates,
- operator commands,
- and resulting disposition.

Without the forensic trace, operator summaries are not sufficient.

---

## 11. Beta / Post-Beta / True V1 Requirements

### 11.1 Beta Must-Haves

Beta is the proving ground for governed research control, not production autonomy.

Required in beta:

1. sandbox-only execution for autoresearch runs,
2. approved research charter before any run starts,
3. one canonical admin cockpit with live read access,
4. append-only experiment ledger,
5. checkpointing plus cooperative pause/resume,
6. immediate stop/kill path,
7. redirect as new charter revision,
8. explain endpoint and UI panel,
9. privacy-safe admin rendering,
10. per-run budget ceilings for time, compute, and data access,
11. promotion blocked from direct production mutation,
12. explicit human review required before any candidate leaves the research lane.

Beta scope should stay narrow:

- one or two research domains,
- replay or sandbox data first,
- no federated propagation,
- no self-authorized charter creation,
- and no silent production edits.

### 11.2 Right After Beta Must-Haves

This stage broadens governance quality, not autonomy recklessness.

Required immediately after beta:

1. replay and shadow comparison reports attached automatically to review packs,
2. signed operator dispositions on promotion candidates,
3. multi-role admin permissions for observe vs control vs approve,
4. temporal replay of run history in admin,
5. contradiction-triggered automatic pause,
6. dual approval for high-impact promotions,
7. external research allowlists and source-family tagging in the ledger,
8. structured rollback manifests for every promotable candidate,
9. canary-only promotion path for low-impact classes,
10. operator-authored redirect templates and saved directives.

At this stage AVRAI may begin promoting low-impact candidates into canary under governance, but must still fail closed on missing evidence or missing explanation.

### 11.3 True V1 Launch Must-Haves

True v1 is when governed autoresearch becomes a real operational subsystem instead of an experimental cockpit.

Required for v1:

1. full three-prong contract implementation,
2. canonical runtime supervisor with durable state and restart recovery,
3. complete admin oversight with live status, temporal replay, and forensic explanations,
4. automatic pause on drift, contradiction, budget breach, or policy breach,
5. signed promotion manifests and rollback bundles,
6. replay -> shadow -> canary -> governed production path,
7. cohort-aware evaluation and no-regression gates,
8. durable provenance tied to model version, policy version, and schema version,
9. role-based admin intervention with full audit,
10. support for multiple concurrent research runs with explicit budgets,
11. low-impact autonomous continuation within approved charters,
12. mandatory HiTL for high-impact domains,
13. operator-visible research ontology and source-family weighting,
14. explanation coverage as a release gate,
15. production-readiness checks that fail closed on TODO or log-only adaptive paths.

At v1, AVRAI may autonomously continue approved low-impact research programs, but only inside pre-authorized envelopes and only while admin retains continuous intervention authority.

---

## 12. What Is Explicitly Out Of Scope For Beta

Beta must not include:

- unrestricted production mutation,
- automatic high-impact promotions,
- hidden operator backdoors outside audited controls,
- raw-payload centralization for convenience,
- silent rewrite of run history,
- or unconstrained multi-agent research swarms.

If beta includes any of these, the system has skipped governance maturity.

---

## 13. Implementation Backbone

Suggested contract families:

1. `ResearchCharterContract`
2. `ResearchDirectiveContract`
3. `ResearchRunStateContract`
4. `ResearchCheckpointContract`
5. `ResearchExplanationContract`
6. `ResearchDispositionContract`
7. `ResearchPromotionManifestContract`
8. `ResearchRollbackBundleContract`
9. `AdminResearchControlContract`

Suggested runtime services:

1. `GovernedAutoresearchSupervisor`
2. `ResearchSandboxOrchestrator`
3. `ResearchCheckpointStore`
4. `ResearchLedgerService`
5. `ResearchExplanationService`
6. `ResearchDispositionGate`
7. `ResearchKillSwitchService`

Suggested admin surfaces:

1. `AutoresearchOverviewPage`
2. `AutoresearchRunDetailPage`
3. `AutoresearchPromotionQueuePage`
4. `AutoresearchReplayPage`

---

## 14. Relationship To Existing Authorities

This document does not replace `AUTONOMOUS_RESEARCH_EXPERIMENTATION_ENGINE.md`.

Instead:

1. `AUTONOMOUS_RESEARCH_EXPERIMENTATION_ENGINE.md` remains the broad research-loop doctrine,
2. this document defines the governed implementation shape inspired by `autoresearch`,
3. `ADMIN_COMMAND_CENTER_IDEAL_ARCHITECTURE_2026-02-28.md` remains the authority for admin oversight surfaces,
4. `AUTONOMOUS_SECURITY_IMMUNE_SYSTEM_2026-03-13.md` remains the pattern authority for sandbox + HiTL + promotion-gate rigor,
5. and the 3-prong master documents remain the placement authority.

---

## 15. Final Rule

If a human operator cannot:

- see the research,
- understand the research,
- interrupt the research,
- redirect the research,
- and approve or reject the research outcome,

then AVRAI has not implemented governed autoresearch. It has only implemented hidden autonomous mutation.
