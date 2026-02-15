# Autonomous Research and Experimentation Engine

**Date:** February 15, 2026  
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
| Phase 2 (Privacy + Compliance) | Enforce data-use/legal gates on research ingestion and experiments |
| Phase 4 (Energy Function) | Use experiment outcomes to adjust objective components safely |
| Phase 5 (Transition + Training) | Add continual-learning updates from validated experiments |
| Phase 6 (MPC Planner) | Inject validated policy changes and horizon tuning |
| Phase 7.9 (Autonomous Research Lane) | Run always-on loop orchestration, rollout gates, rollback |
| Phase 8 (Federated AI2AI) | Share DP-safe research deltas and validated improvements |
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

---

## Non-Negotiable Safety Rules

- Falsification-first: every high-confidence claim must have an active disproof attempt.
- Interdisciplinary-by-default: for human-centered decisions, no single-domain evidence mono-culture is allowed.
- No auto-promotion for legal/privacy-sensitive changes.
- No removal of rollback paths.
- No opaque conviction changes.
- No single-source external claim can directly change production behavior.
- No static research taxonomy: retrieval policy must support auditable growth and pruning of research categories.

---

## Success Criteria

- Reduced repeated failure patterns in recommendation/planning loops.
- Increased long-horizon outcome quality without short-term trust degradation.
- Measurable reduction in unresolved high-uncertainty hypotheses.
- Faster recovery from bad updates due to automatic rollback and failure learning.
