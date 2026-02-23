# External Research Addendum: Adaptive Reasoning + Runtime Control Batch

**Date:** February 16, 2026  
**Status:** Active research reference  
**Sources:**  
- https://ouro-llm.github.io  
- https://arxiv.org/abs/2211.04325  
- https://arxiv.org/pdf/2504.13837  
- https://arxiv.org/pdf/2510.25741  
- https://arxiv.org/pdf/1807.03819  
- https://arxiv.org/pdf/2107.05407  
- https://physics.allen-zhu.com  
- https://arxiv.org/pdf/2001.08361

---

## Summary (Why It Matters to AVRAI)

This batch is useful as a runtime-control and training-governance upgrade:
- adaptive-depth reasoning for hard cases,
- bounded compute for mobile tiers,
- stronger promotion gates that separate apparent metric wins from true capability gains,
- compute-optimal training/data budgeting.

It should be applied as a control-plane enhancement around AVRAI's existing world-model core.

---

## AVRAI Mapping

| Source Theme | AVRAI Equivalent | Master Plan Touchpoints |
|---|---|---|
| Latent recurrent reasoning (`ouro`, `2510.25741`) | `AdaptiveDepthPolicy` that allocates extra reasoning loops only when uncertainty/impact is high | `docs/MASTER_PLAN.md` 7.9.27, 7.5 |
| Adaptive computation (`1807.03819`, `2107.05407`) | `PonderBudgetController` with dynamic halting and per-tier compute budgets | `docs/MASTER_PLAN.md` 7.9.28, 7.5, 6.1 |
| RLVR boundary caution (`2504.13837`) | `CapabilityBoundaryGate` to prevent false promotion from reward-hacking/short-horizon metric artifacts | `docs/MASTER_PLAN.md` 7.9.29, 7.7A.3 |
| Scaling-law optimization (`2001.08361`) | `ComputeOptimalTrainingPlanner` for model/data/compute allocation and stop criteria | `docs/MASTER_PLAN.md` 7.9.30, 5.2 |
| Data-quality ceiling + synthetic laws (`2211.04325`, Allen-Zhu physics) | `SyntheticLawStressSuite` + data-tier governance for robust pre-promotion testing | `docs/MASTER_PLAN.md` 7.9.31, 10.9.12 |

---

## AVRAI-Native Terminology

- `Adaptive recurrent reasoning` -> `AdaptiveDepthPolicy`
- `Dynamic halting` -> `PonderBudgetController`
- `Capability overclaim detection` -> `CapabilityBoundaryGate`
- `Scaling-law allocation` -> `ComputeOptimalTrainingPlanner`
- `Controlled synthetic test worlds` -> `SyntheticLawStressSuite`

---

## Recommended Additions

1. Add **adaptive-depth runtime policy**:
   - short path for low-uncertainty requests,
   - extended reasoning path for high-uncertainty/high-impact requests.

2. Add **capability-boundary promotion tests**:
   - require boundary eval suites before promoting RL/VR-trained candidates.

3. Add **compute-optimal training governance**:
   - use scaling-law-informed budget allocation and stopping rules.

4. Add **synthetic-law stress harness**:
   - run controlled, adversarial, and compositional tests before promotion.

---

## Not Recommended

- Always-on deep reasoning on battery-constrained tiers.
- Promotion based on a single metric family (e.g., pass@1 only).
- Treating synthetic eval results as production truth without real-world validation.

---

## Success Criteria

- Lower compute cost per accepted decision on constrained tiers.
- Fewer false promotions from short-horizon metric artifacts.
- Higher robustness under synthetic stress and adversarial shifts.
- Faster convergence of training budgets to compute-optimal settings.
