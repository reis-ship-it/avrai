# External Research Addendum: arXiv 2602.16873 (Task-Adaptive Orchestration Topology)

**Date:** February 20, 2026  
**Status:** Reference addendum (caution-gated integration)  
**Source:** `https://arxiv.org/pdf/2602.16873`

---

## Why This Matters For AVRAI

The paper argues that when base model quality converges, system-level orchestration topology becomes a larger performance lever than model choice alone. That is directly relevant to AVRAI because AVRAI already operates in mixed online/offline lanes and ai2ai federated coordination.

For AVRAI, the key value is not copying a centralized multi-agent stack. The value is adopting topology selection as a governed policy input for:
- online/offline world-model transitions,
- planning decomposition and execution mode selection,
- lifecycle promotion/rollback readiness,
- federated ai2ai topology-policy exchange.

---

## AVRAI-Native Mapping

Map the paper's topology families to AVRAI execution modes:

- **Parallel topology:** low-coupling subtasks, locality-safe branches, retrieval fan-out.
- **Sequential topology:** high-coupling reasoning, strict dependency chains, conviction-sensitive updates.
- **Hierarchical topology:** lead/arbiter-controlled high-risk lanes requiring conflict resolution.
- **Hybrid topology:** most AVRAI real workloads (fan-out/fan-in with staged constraints).

Required adaptation:
- AVRAI must run topology routing as a **two-level policy**:
  - local (device/runtime) topology choice,
  - federated (ai2ai) topology-threshold governance by `locality x model_family`.

---

## Caution-Gated Adoption Rules

To use this safely in AVRAI:

- **No direct global default switch.** Topology routing starts as policy-candidate lane only.
- **Model-fixed ablations required.** Compare topology choices while model is held constant.
- **Topology-fixed ablations required.** Compare model choices while topology is held constant.
- **Offline calibration, online approximation.** Full DAG metrics offline; bounded low-latency proxies online.
- **Fail-closed reroute budget.** If synthesis conflict exceeds bounded retries, fall back to safe topology and/or human gate.
- **Federated quarantine rule.** Contradictory locality policies are quarantined before cross-locality propagation.

---

## Phase-Level Integration

| Phase | Required Integration |
|---|---|
| `5.2` | Add topology-policy lane for training/execution mode selection with offline-calibrated thresholds and online bounded heuristics |
| `6.1` | Route planner subgraphs by coupling/parallelism signals; expose topology choice as planner telemetry |
| `7.7` | Add topology-fit evidence to promotion/rollback decisions (not accuracy-only) |
| `7.9` | Add controlled ablations: `model-fixed/topology-varied` and `topology-fixed/model-varied` |
| `8.1` | Add DP-safe federated topology-policy exchange and contradiction quarantine across localities |
| `10.9` | Add fail-closed governance for reroute ceilings, fallback topology, and escalation invariants |

---

## AVRAI vs Paper (Important Difference)

The paper mostly evaluates centralized orchestration. AVRAI must preserve ai2ai constraints:
- decentralized locality behavior,
- federated aggregation under privacy constraints,
- bounded online latency and energy budgets,
- conviction-tier and safety-tier precedence over orchestration preferences.

Therefore, AVRAI should treat this work as an orchestration-policy input under governance, not a direct architecture replacement.

---

## Immediate Execution Hooks

Map this addendum to existing governance lanes:
- `5.2` training/runtime policy shaping
- `6.1` planner decomposition/routing controls
- `7.7` lifecycle promotion evidence
- `7.9` autonomous experimentation protocol
- `8.1` federated ai2ai policy exchange
- `10.9` reliability gates and fail-closed escalation policy

This addendum should be used with the transfer-continuity addendum (`2602.17632`) as a paired policy set:
- `2602.17632` governs offline->online continuity safety,
- `2602.16873` governs topology-choice effectiveness under that safety envelope.
