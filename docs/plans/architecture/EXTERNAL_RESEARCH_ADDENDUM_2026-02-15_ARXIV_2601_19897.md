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
| Self-distillation teacher/student loop | `AnchorMind` (stable baseline) + `ExplorationMind` (adaptive learner) with `ContinuityAlignment` constraints | `docs/MASTER_PLAN.md` Phase 5.2, Phase 8.1 |

### AVRAI-Native Terminology (Canonical)

- `Teacher` -> `AnchorMind`
- `Student` -> `ExplorationMind`
- `Distillation objective` -> `ContinuityAlignment`
- `On-policy fine-tuning` -> `LiveTrajectoryLearning`
- `Catastrophic forgetting` -> `DoorLossDrift`
- `No-regression gate` -> `DoorContinuityGate`
- `Sequential skill accumulation` -> `DoorLadderExpansion`

---

## Recommended Additions

1. Add an **AnchorMind-ExplorationMind continual update loop**:
   - Keep a stable `AnchorMind` model snapshot.
   - Train `ExplorationMind` on fresh trajectories with `ContinuityAlignment` constraints against anchor behavior.

2. Add **DoorLossDrift guard metrics**:
   - Track regression on prior behavior cohorts before any rollout.
   - Block deployment when `DoorContinuityGate` thresholds are breached.

3. Add **DoorLadderExpansion protocol**:
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
