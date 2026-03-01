# External Research Addendum: arXiv 2602.17632 (Offline/Online Transfer Continuity)

**Date:** February 20, 2026  
**Status:** Reference addendum (explicitly wired into core phases)  
**Source:** `https://arxiv.org/pdf/2602.17632v1`

---

## Why This Matters For AVRAI

The paper reinforces a practical risk AVRAI already faces in adaptive intelligence: a model can look strong in offline training but lose quality immediately after online exposure. AVRAI should treat this "handoff valley" as a release-blocking reliability problem, not a post-release tuning issue.

This is directly relevant to:
- `5.2` on-device training and update shaping,
- `7.7` model lifecycle promotion/rollback,
- `7.9` autonomous stress experimentation,
- `8.1` federated cross-cohort rollout governance,
- `10.9` global reliability and promotion policy.

---

## AVRAI-Native Mapping

Translate the paper's offline/online relationship into AVRAI's stack:

- **Offline lane:** replay/simulated updates from local and federated history.
- **Semi-online bridge lane:** bounded adaptation with strict trust-region and canary constraints.
- **Online lane:** full live adaptation with cohort-protected rollout.

Required policy invariant:
- **Offline-only wins cannot promote.**
- Promotion requires passing bridge and early-online stability gates.

---

## Explicit Metrics To Add

Per cohort and model family, compute and retain:

- `handoff_dip`: immediate quality drop at offline->online handoff.
- `initial_online_regret`: first-window regret versus protected baseline.
- `recovery_steps`: adaptation steps needed to recover to baseline.
- `worst_cohort_handoff_delta`: max adverse cohort-specific handoff gap.

Promotion outcome is fail-closed if any required threshold is missed.

---

## Phase-Level Integration

| Phase | Required Integration |
|---|---|
| `5.2` | Add continuity shaping objective and bridge-stage adaptation lane (`offline -> shadow_online -> canary_online`) |
| `7.7` | Add transfer-valley probe and early-online stability blocker before promotion |
| `7.9` | Add transfer stress protocol and static-vs-semi-online ablation experiments |
| `8.1` | Add federated early-online stability registry and bridge quorum gate |
| `10.9` | Add release-blocking continuity gate with explicit metric thresholds |

---

## Governance Constraints

- No release path may bypass bridge-stage validation for high-impact model changes.
- Cross-cohort safety remains mandatory: aggregate metrics are insufficient if a protected cohort fails.
- Evidence provenance must include checkpoint lineage + experiment IDs for rollback and forensic reconstruction.

---

## Immediate Execution Hooks

Wire to canonical tasks:
- `5.2.27`, `5.2.28`, `5.2.29`
- `7.7.19`, `7.7.20`
- `7.9.46`, `7.9.47`
- `8.1.20`, `8.1.21`
- `10.9.22`

This addendum is planning authority for offline/online continuity hardening and should be treated as a required companion to dream/conviction governance when evaluating promotion readiness.
