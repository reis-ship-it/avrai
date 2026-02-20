# Autonomous Research and Experimentation Engine

**Date:** February 19, 2026  
**Status:** Active architecture spec  
**Purpose:** Enable AVRAI to continuously generate hypotheses, run bounded experiments, explain outcomes, and integrate new/old research with safety and governance.

---

## Objective

Design a closed-loop intelligence subsystem where AVRAI can:
- Identify uncertainty or weak assumptions in its current reasoning.
- Search external research relevant to those uncertainty areas.
- Search interdisciplinary sources (science, engineering, social science, humanities, arts) for alternative frames.
- Propose and execute bounded experiments.
- Explain why experiments worked or failed.
- Update model behavior and planning rules from validated evidence.

This is not unconstrained autonomy. It is autonomy under hard validation and rollback gates.

---

## Core Loop (Always-On, Bounded)

1. **Self-Questioning Trigger**
   - Inputs: high prediction error, confidence collapse, contradiction signals, stale assumptions, degraded long-horizon outcomes.
   - Output: machine-readable hypothesis candidates.

2. **Research Retrieval**
   - Query trusted sources by hypothesis topic.
   - Run dual-track retrieval:
     - `Analytic Track`: quantitative, technical, scientific sources.
     - `Creative Track`: humanities, art history, design practice, narrative theory, ethics, creative writing.
   - Run adaptive retrieval expansion:
     - identify underexplored domains in prior cycles,
     - propose new research lenses/tags,
     - schedule exploratory pulls outside the current dominant frame.
   - Prioritize papers, official docs, benchmark artifacts, reproducible code.
   - Build a normalized evidence bundle: claim, assumptions, method class, evidence quality, recency.

3. **Experiment Planning**
   - Convert hypotheses into testable plans:
     - expected effect,
     - failure criteria,
     - minimum detectable effect,
     - affected cohorts/features,
     - safety and privacy constraints.
   - Require pre-registered success/failure definitions before execution.

4. **Experiment Execution**
   - Run in sandboxed lanes first: replay/offline simulation -> shadow mode -> limited rollout.
   - Never skip stages for high-impact changes.

5. **Causal Analysis and Explainability**
   - Compute why results changed:
     - ablation,
     - counterfactual replay,
     - subgroup deltas,
     - pre/post distribution checks.
   - Emit explicit "worked because / failed because" traces tied to evidence IDs.
   - Include a "frame contribution" report: which analytic vs creative frames changed decision quality.

6. **Belief and Policy Update**
   - Update the belief graph (confidence up/down, contradiction tags).
   - Update research-definition graph (new domains, lenses, and hypothesis classes discovered from outcomes).
   - Promote only if regression and safety gates pass.
   - Record full provenance in append-only evidence ledger.

7. **Self-Healing**
   - If post-promotion metrics degrade, auto-rollback and mark failed path.
   - Feed failure into next research and hypothesis cycle.

---

## Required Components

| Component | Responsibility | Notes |
|---|---|---|
| `HypothesisMiner` | Convert model errors and uncertainty to candidate hypotheses | Reads episodic memory and planner diagnostics |
| `ExternalResearchAgent` | Retrieve and normalize external evidence | Trusted-source allowlist + provenance |
| `InterdisciplinaryRetrievalPolicy` | Enforce balanced domain coverage across STEM + humanities | Prevents narrow technical-only evidence |
| `ResearchDefinitionExpander` | Learn and propose new research categories/lenses from observed blind spots | Expands how AVRAI defines "relevant research" over time |
| `ExperimentPlanner` | Build executable experiment plans | Must define stop/go criteria up front |
| `CreativeHypothesisGenerator` | Propose non-obvious hypotheses using metaphor, analogy, and narrative reframing | Outputs must still be testable |
| `ExperimentOrchestrator` | Execute staged experiments safely | Replay -> shadow -> limited rollout |
| `CausalAttributionEngine` | Explain observed outcomes and failure modes | Counterfactual + ablation support |
| `BeliefGraphService` | Track claims, confidence, contradictions, conviction scores | Append-only evidence links |
| `CrossReferenceGraphService` | Link external claims to internal evidence (episodic tuples, outcomes, failures, planner traces) | Supports external/internal agreement and conflict scoring |
| `ResearchIntegrator` | Convert validated findings into model/plan updates | Feature-flagged promotions |
| `RollbackGuardian` | Enforce self-healing and auto-recovery | Mandatory for high-risk promotions |
| `KernelRegistryService` | Serve immutable runtime kernels (`Purpose/Safety/Truth/Recovery/Learning/Exploration/Federation/Resource/HumanOverride`) | Signed manifests + versioned policy precedence |
| `KernelLifecycleGuard` | Enforce kernel upgrade/downgrade protocol, rollback TTL, and emergency freeze controls | Blocks runtime drift from lifecycle policy |
| `MetaLearningSupervisor` | Evaluate planned-vs-actual learning cycle quality and auto-adjust subsequent cycle policy | Macro guard over micro adaptation |
| `ScalingReliabilityProfiler` | Classify downstream scaling regimes and compute setup sensitivity indices | Blocks linear-only extrapolation promotion paths |
| `DreamEnvOrchestrator` | Run bounded dream simulation/counterfactual episodes and emit speculative candidates | Cannot produce direct production promotions |
| `DreamConvictionGate` | Enforce belief-tier precedence and dual-key evidence requirements for dream-derived updates | Fail-closed on hierarchy violations |
| `DwellBudgetController` | Enforce time/attempt ceilings per issue/hypothesis class and trigger escalation routes | Prevents infinite autonomous loops |
| `FirstOccurrenceGovernor` | Enforce first-occurrence rate limits, dedupe horizon, and incident bundling | Prevents triage storm overload |
| `HighImpactOversightGate` | Enforce max autonomous cycles before mandatory human review in high-impact domains | Signed review disposition required |

---

## Conviction Model (Evidence-Bound)

AVRAI may strengthen convictions only when:
- at least one external evidence source is methodologically strong,
- internal experiment results reproduce expected directionality,
- no safety/privacy/legal regressions are observed.

Conviction must decrease when:
- replication fails,
- contradictory evidence is stronger,
- subgroup harms appear.

No conviction updates are allowed without provenance and reproducibility metadata.

---

## Interdisciplinary Evidence Policy (Required)

For non-trivial hypothesis classes (behavior change, motivation, social trust, identity, belonging, community formation), retrieval must include:
- at least one quantitative/technical source, and
- at least one humanities/qualitative source.

Humanities source families include:
- art/design history,
- philosophy and ethics,
- cultural studies,
- creative writing/narrative theory,
- anthropology/sociology (qualitative methods),
- media and communication theory.

These sources are used to widen hypothesis generation, not to bypass empirical validation.

---

## External/Internal Cross-Reference Protocol (Required)

Every external claim considered for adoption must be cross-referenced against internal AVRAI sources:
- episodic memory tuples,
- outcome pipeline metrics,
- planner decision traces,
- prior failed experiment records,
- subgroup and safety diagnostics.

Each claim receives:
- `agreement_score` (supports current internal evidence),
- `conflict_score` (contradicts internal observations),
- `coverage_score` (how many internal contexts were tested),
- `novelty_score` (new lens/value beyond existing assumptions).

Claims with high novelty but low coverage are routed to exploratory experiments, not direct promotion.

---

## Self-Expanding Research Definition Protocol

AVRAI must continuously evolve how it defines research relevance:
- Mine failed/weak experiments for "missing lens" indicators.
- Infer new research tags (conceptual, methodological, domain, narrative).
- Add candidate tags to a probation pool.
- Promote tags to active retrieval policy only after they improve experiment yield or explanatory power.

This creates a self-growing research ontology instead of a static topic list.

---

## Integration to Existing Master Plan Phases

| Existing Phase | Integration |
|---|---|
| Phase 1 (Outcome + Memory) | Add hypothesis trigger signals and evidence-linked episodic tuples |
| Phase 1.2 (Outcome taxonomy) | Add volunteer outcomes and nearby invite/install conversion telemetry as first-class learning signals |
| Phase 1.4 (Feedback collection) | Add conviction feedback signals, delayed validation windows, and source-utility feedback loops |
| Phase 2 (Privacy + Compliance) | Enforce data-use/legal gates on research ingestion and experiments |
| Phase 4 (Energy Function) | Use experiment outcomes to adjust objective components safely |
| Phase 5.1 (Transition predictor) | Condition transition forecasts on evidence quality, source agreement, and third-party drift risk |
| Phase 5.2 (On-device training loop) | Use evidence-tiered curricula, conviction-gated optimizer controls, and source-family reliability weighting |
| Phase 5.2 (Offline/online transfer continuity) | Enforce continuity shaping, bridge-stage adaptation, and early-online regret/recovery thresholds before full promotion |
| Phase 5.2 (Dream lane controls) | Add bounded DreamEnv lane, mismatch gating, OOD/leakage/spec-gaming checks, and no recursive self-confirmation policy |
| Phase 6.1 (MPC Planner) | Inject validated policy changes, evidence-backed priors, data-route selection, and conviction-aware horizon tuning |
| Phase 6.2 (Guardrail objectives) | Enforce discoverability guarantee, first-occurrence triage invariant, and dwell-time escalation invariant |
| Phase 7.9 (Autonomous Research Lane) | Run always-on loop orchestration, rollout gates, rollback |
| Phase 8 (Federated AI2AI) | Share DP-safe research deltas and validated improvements |
| Phase 8.1 (Federated split governance) | Enforce anti-fragmentation shared core and cross-locality reconciliation cadence |
| Phase 8.1 (Dream federation controls) | Quarantine raw dream outputs, share only vetted tiered candidates, and enforce cross-family belief-tier consistency |
| Phase 8.1 (Scaling reliability governance) | Track downstream scaling regimes per `locality x model_family` and quarantine cross-cohort inversion risk |
| Phase 1.1E (Deterministic Memory Core) | Persist facts/history journals for fallback retrieval and forensic recovery |
| Phase 10.9 (Reliability governance) | Enforce kernel lifecycle gates, first-occurrence storm SLOs, and high-impact oversight SLOs |
| Phase 11.4 (Quantum Readiness) | Keep interfaces backend-agnostic for future acceleration |

---

## Execution Backlog (New Tasks)

1. `ARE-1` Build hypothesis schema and uncertainty trigger rules.
2. `ARE-2` Implement trusted-source retrieval policy and evidence normalizer.
3. `ARE-3` Build experiment-plan DSL with mandatory success/failure contracts.
4. `ARE-4` Implement staged experiment executor with hard gate transitions.
5. `ARE-5` Implement causal attribution reports and subgroup safety checks.
6. `ARE-6` Build belief graph + append-only evidence ledger links.
7. `ARE-7` Implement auto-rollback guardian and failed-path suppression.
8. `ARE-8` Integrate research-validated updates into model lifecycle promotion.
9. `ARE-9` Add dashboard: hypothesis queue, active experiments, conviction deltas, rollback events.
10. `ARE-10` Add quarterly red-team falsification pass on top convictions.
11. `ARE-11` Build cross-reference scoring between external claims and internal evidence.
12. `ARE-12` Build research-definition expander (new tags/lenses discovery + probation/promotion flow).
13. `ARE-13` Add retrieval diversity KPIs (domain breadth, lens novelty, replication lift).
14. `ARE-14` Require deterministic experiment journaling (`FactsJournal`/`HistoryJournal`) before promotion decisions.
15. `ARE-15` Add fallback-memory validation path when semantic retrieval confidence is low/conflicting.
16. `ARE-16` Add federated DP-safe summary channel + contradiction quarantine for self-healing updates.
17. `ARE-17` Add profile-gated systems-optimization policy: no custom hash-table internals without proven benchmark wins on AVRAI workloads.
18. `ARE-18` Add memory-bounded simulation/replay algorithms: checkpoint-rematerialization + tree-reduction evaluation for long-horizon experiments under tight RAM budgets.
19. `ARE-19` Add tier-aware dual-model runtime (`full_state_model` vs `compressed_state_model`) with online agreement checks and deterministic fallback gates.
20. `ARE-20` Add atomic-time checkpoint lineage and replay IDs so rollback/self-healing decisions are fully reconstructable and safe for federated mitigation transfer.
21. `ARE-21` Add `IntegrityArbiter` invariant-split pipeline: convert hard guardrails into machine-checkable clauses for promotion-time verification.
22. `ARE-22` Add `ProofBackedGate` for critical rollout lanes: metric pass is insufficient without formal guardrail proof pass.
23. `ARE-23` Add `ConvictionIntegrityBreach` challenge lane: adversarially test rationale/proof consistency and quarantine candidates on contradiction.
24. `ARE-24` Add `DelegationContract` engine: every delegated subtask must define acceptance tests, required evidence, and fallback route before execution.
25. `ARE-25` Add `DelegationTrustLedger`: calibrate delegation trust by observed outcomes/contradictions per task family and cohort, with automatic lane demotion on trust collapse.
26. `ARE-26` Add `AuthorityScopeToken` + `HumanOverrideRoute`: bound delegated permissions (time/budget/data/action scope) and escalate on scope breach.
27. `ARE-27` Add `AdaptiveDepthPolicy`: allocate recurrent reasoning depth only when uncertainty/impact thresholds justify extra compute.
28. `ARE-28` Add `PonderBudgetController` with dynamic halting and tier-aware latency/battery budgets.
29. `ARE-29` Add `CapabilityBoundaryGate`: require boundary evaluations to prevent promotion of overfit/overclaim candidates.
30. `ARE-30` Add `ComputeOptimalTrainingPlanner`: enforce scaling-law-informed model/data/compute allocation and stopping rules.
31. `ARE-31` Add `SyntheticLawStressSuite` + data-tier governance for controlled compositional/adversarial stress before production promotion.
32. `ARE-32` Add signed `KernelRegistry` runtime contract and immutable kernel precedence policy.
33. `ARE-33` Add recursive `MetaLearningSupervisor` scoring over each completed learning cycle.
34. `ARE-34` Add first-occurrence critical-issue triage protocol with deterministic routing.
35. `ARE-35` Add universal `DwellBudgetController` with forced escalation routes.
36. `ARE-36` Add federated meta-learning split policy by `locality x model_family` (`reality_model`, `universe_model`, `world_model`).
37. `ARE-37` Add first-occurrence storm suppression controls (global rate limits, dedupe horizon, incident bundling).
38. `ARE-38` Add hypothesis-class dwell objective contracts with measurable stop criteria and forced escalation on miss.
39. `ARE-39` Add high-impact autonomy cycle caps with mandatory human review SLO and signed disposition.
40. `ARE-40` Add kernel lifecycle governance enforcement (upgrade/downgrade protocol, rollback TTL, emergency freeze rehearsals).
41. `ARE-41` Add federated anti-fragmentation shared-core governance with periodic cross-locality reconciliation checks.
42. `ARE-42` Add downstream scaling regime classifier (`predictable/inverse/nonmonotonic/trendless/breakthrough`) for every candidate update.
43. `ARE-43` Add required validation/task/setup sensitivity sweeps and block promotion when benign setup changes flip downstream conclusions.
44. `ARE-44` Add federated scaling reliability registry and cross-cohort inversion quarantine policy before global promotion.
45. `ARE-45` Add DreamEnv bounded simulation lane with deterministic provenance (`DreamLedger`) and falsification contract enforcement.
46. `ARE-46` Add dream-conviction hierarchy gate and dual-key evidence validator; block any direct dream-to-proven promotion path.
47. `ARE-47` Add negative-dream archive with anti-repeat suppression tags and automatic contradiction-prior reuse.
48. `ARE-48` Add dream/reality divergence monitor with auto-throttle, quarantine, and rollback hooks.
49. `ARE-49` Add belief-tier audit dashboard (promotion/demotion counts, hierarchy-violation rejects, delayed-validation outcomes).
50. `ARE-50` Add transfer-valley stress protocol (`offline -> shadow_online -> canary_online -> full_online`) with controlled perturbation sweeps.
51. `ARE-51` Add static-vs-semi-online-vs-online ablation lane and retain cohort-level handoff failure traces.
52. `ARE-52` Add early-online regret dashboard (`handoff_dip`, `initial_online_regret`, `recovery_steps`, `worst_cohort_handoff_delta`) as release-blocking evidence.
53. `ARE-53` Add transfer mitigation playbook registry so failed handoff patterns auto-map to tested remediation recipes.
54. `ARE-54` Add topology-policy candidate lane with two-level routing (`local` runtime + `federated` threshold governance) for DAG/coupling-aware orchestration choice.
55. `ARE-55` Add controlled causality suite: `model-fixed/topology-varied` and `topology-fixed/model-varied` ablations before any topology policy promotion.
56. `ARE-56` Add offline-calibration/online-approximation protocol for topology features (`width/depth/coupling`) with strict latency and energy budgets.
57. `ARE-57` Add fail-closed reroute ceilings with deterministic fallback topology and human escalation route when synthesis conflict persists.

---

## Non-Negotiable Safety Rules

- Falsification-first: every high-confidence claim must have an active disproof attempt.
- Interdisciplinary-by-default: for human-centered decisions, no single-domain evidence mono-culture is allowed.
- No auto-promotion for legal/privacy-sensitive changes.
- No removal of rollback paths.
- No opaque conviction changes.
- No single-source external claim can directly change production behavior.
- No static research taxonomy: retrieval policy must support auditable growth and pruning of research categories.
- No unbounded first-occurrence alerting: all critical alert lanes must honor rate-limit + dedupe + incident-bundle policy.
- No unlimited autonomous loops in high-impact domains: mandatory human-review SLO is required once cycle cap is reached.
- No linear-only downstream scaling assumptions: promotion requires cross-setting scaling robustness evidence.
- No offline-only promotion claims: bridge-stage and early-online continuity gates must pass before production rollout.
- No topology-policy promotion without model-fixed and topology-fixed ablation evidence.
- No unbounded topology reroute loops: enforce retry ceilings and deterministic fallback/escalation.
- No dream-tier override of proven convictions: belief-tier precedence is immutable and enforced in runtime + CI.
- No dream-only policy truth: dream evidence must pass dual-key validation before tier elevation above `hypothesis`.

---

## Success Criteria

- Reduced repeated failure patterns in recommendation/planning loops.
- Increased long-horizon outcome quality without short-term trust degradation.
- Measurable reduction in unresolved high-uncertainty hypotheses.
- Faster recovery from bad updates due to automatic rollback and failure learning.
