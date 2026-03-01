# External Research Addendum: Recursive Meta-Learning, Kernel Contracts, and Discoverability Guarantees

**Date:** February 19, 2026  
**Status:** Active research reference  
**Scope:** Latest arXiv batch + AVRAI operating-kernel concerns mapped into master-plan phases

---

## Sources

- https://arxiv.org/abs/2602.03814v1
- https://arxiv.org/abs/2602.16708v1
- https://arxiv.org/abs/2602.13671
- https://arxiv.org/abs/2602.03837
- https://arxiv.org/abs/2602.15799v1
- https://arxiv.org/pdf/2512.14982
- https://arxiv.org/abs/2602.15001v1

---

## Why This Batch Matters to AVRAI

This batch reinforces four architecture directions:

1. Continual learning must resist forgetting and overconfident drift.
2. Inference/runtime policy must be treated as a first-class optimization target.
3. Context and planning quality are governance problems, not only model-size problems.
4. Recursive meta-learning and deterministic kernel constraints are required for self-sustaining autonomy.

---

## Paper-to-Plan Mapping

| Source | Why It Matters | Master Plan Touchpoints | Recommended AVRAI Implementation |
|---|---|---|---|
| arXiv 2602.03814v1 | Continual updates can erase prior knowledge and stability | 5.2, 7.7, 10.9 | Add forgetting-risk gates and legacy no-regression enforcement before promotion |
| arXiv 2602.16708v1 | Inference-time policy quality must be optimized directly | 6.1, 7.9.27, 7.9.28 | Calibrate planning/inference depth and Best-of-N style selection to tier budgets |
| arXiv 2602.13671 | Context engineering quality dominates agent reliability | 1.1D, 6.1, 7.9 | Standardize context contracts (inputs/tools/constraints/stop conditions) |
| arXiv 2602.03837 | Context budget and retrieval structure should be optimized explicitly | 1.1D, 6.1, 7.5 | Add dynamic context-budget policy based on uncertainty/risk/tier |
| arXiv 2602.15799v1 | Confidence calibration failure amplifies bad autonomy decisions | 4.1.8, 1.4.13, 7.9.8 | Add trigger-aware calibration monitoring and conviction decay on calibration drift |
| arXiv 2512.14982 | Self-improvement loops require structured reflection/critique | 5.2, 7.9, 10.9.12 | Add recursive meta-learning cycle scoring with fail-closed escalation |
| arXiv 2602.15001v1 | Structural intelligence emerges from interaction consistency | 3.x, 5.1, 6.1 | Add structure/causal consistency objectives in transition and planning models |

---

## AVRAI Operating Concerns -> Kernelized Mappings

| Concern | Why | Where | How |
|---|---|---|---|
| Hardcoded purposes/goals | Stable self-direction without prompt dependence | 1.1E, 6.2, 7.9, 10.9 | Add immutable `PurposeKernel` + signed `KernelRegistry` manifests |
| Recursive meta-learning | Prevent plan drift/hallucination and low-quality self-updates | 5.2, 7.9, 8.1, 10.9 | Add `MetaLearningSupervisor` and macro-vs-micro alignment gates |
| Federated split by locality + model family | Preserve local truth and model-family specialization | 8.1, 10.9.5 | Federate hyperpolicy deltas by `locality x model_family` (`reality_model`, `universe_model`, `world_model`) |
| Volunteer pathways as first-class positive behavior | Improve community outcomes and meaning metrics | 1.2, 6.1, 8.9 | Add volunteer action taxonomy and planner actions |
| Non-user nearby acquisition path | Expand network growth safely | 1.2, 6.1, 8.4 | Add nearby invite/install telemetry and planner route with platform constraints |
| Never gatekeep discoverability | Preserve user agency and avoid recommendation lock-in | 1.4, 6.1, 6.2 | Add discoverability invariant + unfiltered user-controlled lane |
| Single-observation critical issue response | Faster self-healing and less repeated harm | 1.1E, 6.2, 7.9, 10.9.12 | Add first-occurrence triage protocol with severity/dedupe controls |
| Dwell-time policy for unresolved problems | Prevent infinite loops and force bounded escalation | 1.1E, 6.2, 7.9, 10.9 | Add `DwellBudgetPolicy` + automatic escalation routing |

---

## Net-New Master Plan Wiring (This Update)

- `1.1E.12-1.1E.16`: kernel registry, purpose kernel, first-occurrence ledger, dwell budget policy, model-family namespace.
- `1.2.27-1.2.29`: wearable consented outcome channel, volunteer outcomes, nearby invite/install telemetry.
- `1.4.16-1.4.17`: discoverability non-gate feedback and first-occurrence pain-signal priority.
- `5.2.17-5.2.19`: recursive meta-learning supervisor, macro anti-drift monitor, kernel-compliance training gate.
- `6.1.19-6.1.21`: volunteer planning actions, nearby invite/install actions, unfiltered discoverability lane.
- `6.2.16-6.2.18`: discoverability guarantee, first-occurrence response invariant, dwell-time escalation invariant.
- `6.2.19-6.2.20`: discoverability precedence matrix and measurable dwell exit criteria.
- `7.9.32-7.9.39`: kernel-bound autonomy contract, recursive meta-audit loop, first-occurrence triage, dwell budget controller, purpose expansion governance, storm suppression, objective dwell contracts, high-impact cycle caps.
- `8.1.9-8.1.14`: federated meta-learning split by model family/locality, kernel-drift monitor, first-occurrence mitigation propagation, dwell-budget harmonization, anti-fragmentation shared-core policy, cross-locality reconciliation cadence.
- `10.9.13-10.9.18`: kernel integrity enforcement, recursive anti-drift promotion gate, universal first-occurrence+dwell SLA enforcement, kernel lifecycle governance gate, storm-control SLO, and high-impact oversight SLO.

---

## Constraints and Non-Goals

- "No gatekeeping" does not override legal/safety/compliance constraints.
- Discoverability conflict resolution must follow explicit precedence ordering: legal > safety > privacy/consent > user intent > personalization.
- Nearby acquisition paths must honor platform policies (no prohibited sideload behavior).
- Kernel contracts are immutable at runtime; only governed promotion can update versions.
- Kernel lifecycle actions (upgrade/downgrade/freeze) must satisfy signed lifecycle policy, rollback TTL, and emergency freeze rehearsal requirements.
- Recursive meta-learning is bounded by dwell/compute/resource kernels to prevent runaway loops.
