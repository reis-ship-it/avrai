# External Research Addendum: arXiv 2601.19897

**Date:** February 15, 2026  
**Status:** Active research reference  
**Source:** https://arxiv.org/abs/2601.19897  
**Paper:** "Self-Distillation Enables Continual Learning"

---

## Summary (Why It Matters to AVRAI)

This paper proposes Self-Distillation Fine-Tuning (SDFT), an on-policy distillation method that improves continual learning while reducing catastrophic forgetting. For AVRAI, the key value is a practical template for continuous model improvement that preserves prior capabilities while adding new behaviors.

---

## AVRAI Mapping

| Paper Concept | AVRAI Equivalent | Master Plan Touchpoints |
|---|---|---|
| Continual learning without catastrophic forgetting | Ongoing world-model updates without degrading existing recommendation quality | `docs/MASTER_PLAN.md` Phase 5.2, Phase 7.7 |
| On-policy learning from demonstrations/signals | Learning from AVRAI episodic trajectories and action/outcome tuples | `docs/MASTER_PLAN.md` Phase 1.1, Phase 1.2, Phase 1.4 |
| Self-distillation teacher/student loop | Stable teacher checkpoint guiding iterative on-device or server-assisted updates | `docs/MASTER_PLAN.md` Phase 5.2, Phase 8.1 |

---

## Recommended Additions

1. Add a **teacher-student continual update loop**:
   - Keep a stable teacher model snapshot.
   - Distill updated student behavior against both new data and teacher consistency constraints.

2. Add **catastrophic forgetting guard metrics**:
   - Track regression on prior behavior cohorts before any rollout.
   - Block deployment if legacy capability deltas exceed thresholds.

3. Add **sequential-skill accumulation protocol**:
   - Stage training by capability slices (recommendation, scheduling, community matching, business matching).
   - Require no-regression checks after each slice.

4. Add **rollback-aware model lifecycle integration**:
   - Attach forgetting-risk scores to rollout decisions.
   - Auto-rollback when forgetting metrics breach guardrails.

---

## Relation to AVRAI Core Reality Model

- **Self-learning:** continuous capability acquisition from fresh episodic data.
- **Self-questioning:** monitor confidence and regression signals during updates.
- **Self-improving:** iterative distillation improves quality while preserving historical competence.
- **Self-healing:** rollback plus no-regression gates recover from failed updates.

---

## Quantum-Readiness Fit

This aligns with AVRAI's quantum-ready design:
- Continual-learning control logic stays model-agnostic.
- Distillation and gating interfaces remain pure/stateless.
- Quantum acceleration, if used later, can target training/optimization substeps without changing safety/lifecycle governance.

---

## Implementation Notes

- Start with offline replay evaluation on historical AVRAI trajectories.
- Deploy behind feature flags with phased rollout and cohort-based regression checks.
- Success criteria: improved new-skill performance with non-inferior legacy capability metrics.
