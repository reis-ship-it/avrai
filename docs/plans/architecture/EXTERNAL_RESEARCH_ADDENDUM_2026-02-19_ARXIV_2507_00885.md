# External Research Addendum: arXiv 2507.00885 (Downstream Scaling Reliability)

**Date:** February 19, 2026  
**Status:** Active research reference  
**Primary Source:** https://arxiv.org/abs/2507.00885  
**PDF:** https://arxiv.org/pdf/2507.00885

---

## Why This Matters

The paper reports that predictable downstream scaling appears in a minority of observed cases (39%) and that small experimental changes (validation corpus, task, setup) can qualitatively change scaling behavior.

For AVRAI, this means:
- we cannot assume linear downstream gains from scale,
- scaling behavior must be profiled per task and per context,
- promotion gates must include nonlinearity and inversion checks.

---

## AVRAI Mapping (Where / How / Why)

| Paper Signal | AVRAI Need | Master Plan Phases | Implementation Direction |
|---|---|---|---|
| Predictable scaling is not dominant | Avoid linear-only rollout assumptions | 5.2, 7.7, 10.9 | Add scaling-behavior classifiers and reliability gates before promotion |
| Benign setup changes can flip trends | Robustness to validation/task/setup sensitivity | 7.9, 10.9 | Run sensitivity sweeps as required experiment class and block fragile candidates |
| Multiple failure modes (inverse/nonmonotonic/noisy/trendless/breakthrough) | Explicit failure-mode taxonomy in governance | 7.9, 7.7 | Maintain failure-mode registry and mitigation playbooks per candidate |
| Extrapolation from small scale can mislead | Context-local scaling policy, not universal fit | 8.1, 10.9 | Federated scaling profiles by `locality x model_family`, quarantine cross-cohort inversions |

---

## Concrete Wiring Added

- `5.2.20-5.2.21`: on-device scaling-behavior profiling and multi-setting robustness gates.
- `7.7.14-7.7.15`: manifest-level scaling reliability metadata and no linear-only extrapolation promotion policy.
- `7.9.40-7.9.41`: downstream scaling failure-mode taxonomy and required validation/task/setup sensitivity sweeps.
- `8.1.15-8.1.16`: federated scaling profile registry and inversion quarantine across cohorts.
- `10.9.19`: downstream scaling reliability governance gate.

---

## Constraints

- Scaling evidence from one setup cannot be generalized without cross-setting checks.
- Any candidate with inversion/nonmonotonic behavior in critical lanes requires containment or rollback-ready rollout stages.
- Locality/model-family heterogeneity is expected and must be treated as a first-class policy input.
