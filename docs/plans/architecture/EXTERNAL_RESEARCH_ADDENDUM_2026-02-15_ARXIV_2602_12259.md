# External Research Addendum: arXiv 2602.12259

**Date:** February 15, 2026  
**Status:** Active research reference  
**Source:** https://arxiv.org/abs/2602.12259  
**PDF:** https://arxiv.org/pdf/2602.12259  
**Paper Focus:** Scientist-style agent workflow (hypothesis -> experiment -> analysis -> update)

---

## Summary (Why It Matters to AVRAI)

This work aligns with AVRAI's autonomous research loop design. The key contribution is workflow discipline: structured hypothesis generation, pre-registered experiments, explicit causal analysis, and evidence-gated updates.

It should be used to improve AVRAI's experiment lifecycle rigor, not as a replacement for the world model.

---

## AVRAI Mapping

| Paper Concept | AVRAI Equivalent | Master Plan Touchpoints |
|---|---|---|
| Hypothesis-first loop | `HypothesisMiner` + ranked uncertainty queue | `docs/MASTER_PLAN.md` 7.9.1 |
| Structured experiment contracts | `ExperimentPlanner` with mandatory success/failure criteria and safety bounds | `docs/MASTER_PLAN.md` 7.9.5 |
| Staged execution discipline | replay -> shadow -> limited rollout gates | `docs/MASTER_PLAN.md` 7.9.6, 7.7.4 |
| Explicit causal attribution | `CausalAttributionEngine` with ablations/counterfactuals/subgroup deltas | `docs/MASTER_PLAN.md` 7.9.7 |
| Evidence-bounded update | `ResearchIntegrator` + lifecycle gates + rollback governance | `docs/MASTER_PLAN.md` 7.9.10, 7.9.11, 7.7 |

---

## AVRAI-Native Terminology

- `Scientific cycle` -> `EvidenceLoop`
- `Experiment protocol` -> `ExperimentContract`
- `Causal report` -> `BecauseTrace`
- `Failed replication` -> `ContradictionEvent`

---

## Recommended Additions

1. Make every autonomous experiment pre-registered with pass/fail criteria before execution.
2. Enforce staged execution with no skip-path for high-impact changes.
3. Require `BecauseTrace` output before promotion decisions.

---

## Not Recommended

- Free-form autonomous experiments without pre-registered criteria.
- Promotion decisions based only on aggregate metric movement without causal analysis.

---

## Success Criteria

- Lower rate of ambiguous experiment outcomes.
- Faster rollback/root-cause clarity from explicit causal traces.
- Higher promotion reliability from stronger evidence discipline.
