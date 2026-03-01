# External Research Addendum: arXiv 2602.11136

**Date:** February 16, 2026  
**Status:** Active research reference  
**Source:** https://arxiv.org/abs/2602.11136  
**PDF:** https://arxiv.org/pdf/2602.11136  
**Paper:** "FormalJudge: AI Oversight with Formal Verification"

---

## Summary (Why It Matters to AVRAI)

This paper is most useful to AVRAI as an oversight layer: convert high-impact policy checks into formally verifiable constraints and use proof-backed validation before promotion.

It should not replace AVRAI's world-model, energy function, or planner logic. It should strengthen hard-gate reliability where false passes are costly.

---

## AVRAI Mapping

| Paper Concept | AVRAI Equivalent | Master Plan Touchpoints |
|---|---|---|
| LLM decomposition into verifiable checks | `IntegrityArbiter` splits policy claims into machine-checkable invariants | `docs/MASTER_PLAN.md` 7.9.21, 7.9.22 |
| Formal solver-backed validation | `ProofBackedGate` for hard safety/compliance constraints before rollout | `docs/MASTER_PLAN.md` 7.7A.8, 7.9.22, 10.9.11 |
| Judge reliability via proofs vs heuristics | Replace "looks good" acceptance on critical lanes with deterministic pass/fail proofs | `docs/MASTER_PLAN.md` 7.9.6, 7.9.13 |
| Weak-to-strong oversight | Smaller deterministic checker supervising higher-capability adaptive components | `docs/MASTER_PLAN.md` 7.5, 7.7, 7.9.23 |

---

## AVRAI-Native Terminology

- `Formal judge` -> `IntegrityArbiter`
- `Verifier/solver check` -> `ProofBackedGate`
- `Specification decomposition` -> `InvariantSplit`
- `Constraint proof obligation` -> `GuardrailProof`
- `Judge failure / deceptive pass` -> `ConvictionIntegrityBreach`

---

## Recommended Additions

1. Add a **formal invariant pack** for non-negotiable guardrails:
   - safety/compliance constraints,
   - quiet-hours and notification policy constraints,
   - immutable consent boundaries.

2. Add a **proof-backed promotion gate**:
   - critical promotions require both metric gates and `GuardrailProof` pass.
   - proof failure blocks rollout even when aggregate metrics look positive.

3. Add an **integrity challenge lane**:
   - adversarially test self-reports/explanations for contradictions,
   - quarantine updates when proof checks and natural-language rationales disagree.

---

## Not Recommended

- Do not formalize every policy path immediately.
- Do not replace statistical validation with formal validation on non-critical heuristics.
- Do not block low-risk exploration with heavyweight proof requirements.

---

## Success Criteria

- Reduced false-positive promotions on hard-constraint lanes.
- Faster, deterministic rejection of policy-unsafe candidates.
- Lower recurrence of rollback causes tied to invariant violations.
- Improved auditability via proof artifacts linked to rollout lineage.
