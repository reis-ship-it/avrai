# Dream Training and Conviction Governance

**Date:** February 20, 2026  
**Status:** Active architecture spec  
**Purpose:** Define how AVRAI uses dream-style internal training as a bounded learning lane without allowing dream drift or dream-only delusion paths to override proven reality.

---

## Operating Principle

Dreams are useful for exploration, not authority.

AVRAI belief tiers are immutable and ordered:

`dream < hypothesis < candidate_conviction < proven_conviction`

Dream outputs can propose hypotheses and training candidates, but cannot directly mutate production truth, hard policy, or high-impact action routes.

---

## Hard Invariants (Fail-Closed)

1. **No dream override:** `dream` tier cannot override or down-rank `proven_conviction`.
2. **Monotonic promotion:** tier jumps are invalid; promotion must follow each intermediate tier.
3. **Dual-key evidence:** no tier elevation above `hypothesis` without both internal validation and real/external outcome evidence receipts.
4. **High-impact authority lock:** high-impact planner actions read `proven_conviction` only.
5. **No recursive self-confirmation:** dream-generated labels cannot self-promote policy-critical updates without later real-world confirmation.
6. **Simulator mismatch containment:** sustained dream-vs-reality divergence triggers quarantine and rollback.
7. **Signed provenance required:** every dream episode must be tied to deterministic provenance and contradiction state.

---

## Dream -> Conviction Pipeline

1. **Dream (speculative)**
   - Produced in DreamEnv simulation/counterfactual lane.
   - Logged in `DreamLedger` with assumptions and falsification plan.
   - Can affect exploration policy ordering only.

2. **Hypothesis (internally tested)**
   - Must pass falsification probes, contradiction checks, and leakage/OOD/spec-gaming checks.
   - Still non-authoritative for high-impact routes.

3. **Candidate Conviction (shadow/canary)**
   - Requires dual-key evidence receipts.
   - Must pass cohort robustness, policy/safety gates, and rollback readiness.

4. **Proven Conviction (authoritative)**
   - Requires delayed validation windows (7/30/90-day where applicable).
   - Eligible for high-impact planner and runtime policy influence.

Demotion path is explicit:
`proven_conviction -> candidate_conviction (reopen) -> hypothesis or archived_negative`.

---

## Metrics and Decision Gates

Dream-derived candidates are scored on:

- **Outcome delta:** lift/regression in real shadow/canary outcomes.
- **Calibration quality:** predicted vs observed error and confidence reliability.
- **Contradiction density:** conflict rate vs deterministic journals and proven beliefs.
- **Safety/policy integrity:** hard-boundary violations are automatic fail.
- **Cohort robustness:** worst-cohort checks across locality/tier/language/time.
- **Stability/recoverability:** rollback frequency, time-to-detect, time-to-heal, recurrence.
- **Resource discipline:** compute/latency/battery/privacy budget compliance.

Promotion is blocked if any hard gate fails, even when average metrics improve.

---

## Anti-Drift and Anti-Delusion Controls

- **Dream/reality divergence monitor** throttles dream influence when mismatch rises.
- **Negative Dream Archive** stores failed dream paths with cause taxonomy and anti-repeat suppression.
- **First-occurrence + dwell rules** force bounded triage/escalation for dream-induced incidents.
- **Federated quarantine** prevents propagation of speculative dream updates across cohorts.
- **Kernel boundary enforcement** ensures dream adaptation never mutates immutable policy/kernel contracts.

---

## Cross-Phase Wiring (Master Plan)

| Area | Master Plan Anchors | Required Control |
|---|---|---|
| Deterministic memory + belief contracts | `1.1E.19` - `1.1E.22` | Dream ledger, tier precedence, dual-key evidence bridge, negative archive |
| On-device training | `5.2.22` - `5.2.26` | DreamEnv lane, mismatch gate, OOD/leakage/spec-gaming checks, no recursive self-confirmation |
| Planner guardrails | `6.2.21` - `6.2.23` | High-impact authority lock, contradiction dampener, discoverability-safe dream behavior |
| Model lifecycle | `7.7.16` - `7.7.18` | Tiered promotion chain enforcement, dream conflict fail-closed, rollback bundle requirement |
| Autonomous research | `7.9.42` - `7.9.45` | Dream falsification contracts, negative archive governance, divergence monitoring, tier-audit dashboard |
| Federated learning | `8.1.17` - `8.1.19` | Dream-policy quarantine, cross-locality divergence exchange, belief-tier consistency checks |
| Global robustness gate | `10.9.21` | CI/runtime dream-conviction hierarchy enforcement |

---

## Implementation Notes

- This spec does not replace `AUTONOMOUS_RESEARCH_EXPERIMENTATION_ENGINE.md`; it constrains dream-style learning within that architecture.
- Runtime behavior must remain explainable via deterministic journals and belief-tier transitions.
- Any attempt to bypass tier precedence is treated as a governance violation and must fail closed.
