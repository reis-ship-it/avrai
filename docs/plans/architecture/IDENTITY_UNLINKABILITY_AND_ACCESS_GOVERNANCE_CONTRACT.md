# Identity Unlinkability and Access Governance Contract

**Date:** February 15, 2026  
**Status:** Active canonical contract  
**Primary references:** `docs/MASTER_PLAN.md` (2.6, 2.7, 15.8), `docs/MASTER_PLAN_TRACKER.md`

---

## 1) Purpose

Define one enforceable contract for:

- identity namespace separation (`account_id`, `agent_id`, `world_id`)
- unlinkability requirements (no practical retrace path from shared agent data to person)
- service/visibility matrix enforcement
- migration from legacy `user_id` paths with strict cutoff

If any other plan doc conflicts with this contract, this contract wins until the conflict is resolved.

---

## 2) Identity Namespace Contract

| Namespace | Allowed Use |
|---|---|
| `account_id` | Auth, legal, billing, consent |
| `agent_id` | Learning and interaction pseudonym |
| `world_id` | Context/scope boundary for model behavior and sharing |

Hard rules:

1. Runtime world-model paths must not consume `account_id`.
2. `account_id ↔ agent_id` mapping is isolated in secure mapping services only.
3. Cross-world linking defaults to deny unless explicit approved purpose exists.

---

## 3) Access Matrix Robustness Contract

1. Fail closed by default for unknown role/plane/service combinations.
2. P3/P4/P5 access requires role+tier eligibility and active purpose grant.
3. No user-facing P3 rendering.
4. Policy middleware is mandatory on all export/disclosure/admin/research/partner routes.
5. Drift detection runs continuously and blocks mismatched policy/code routes.
6. Break-glass is dual-approved, time-boxed, plane-scoped, immutable-audited, auto-revoked.
7. Any policy middleware bypass is a P0 incident.

---

## 4) Migration Contract (Dual-Read/Dual-Write + Strict Cutoff)

| Stage | Requirement |
|---|---|
| A: Introduce | Add new namespace fields and compatibility adapters |
| B: Dual-read/dual-write | Bounded window only: target 14 days, hard max 30 days |
| C: Parity validation | Validate parity + join-audit + policy coverage before cutoff |
| D: Strict cutoff | Reject legacy `user_id` read/write paths after cutoff (no silent fallback) |
| E: Removal | Remove compatibility adapters and verify no residual dependencies |

Cutoff gates (all required):

1. 100% policy middleware coverage on scoped services.
2. Zero critical join-audit findings.
3. Dual-write parity checks green for the full window.
4. Alerting configured for any post-cutoff legacy payload attempt.

---

## 5) Verification and Release Gates

1. Matrix conformance tests pass in CI.
2. Non-bypass tests pass for policy middleware.
3. Reidentification red-team suite has no blocking findings.
4. Post-cutoff smoke tests confirm legacy payload rejection.

---

## 6) Linked Execution Artifacts

- `docs/plans/architecture/MASTER_PLAN_ARCHITECTURE_EXECUTION_BACKLOG.md` (`MPA-P15-E3-S1/S2`)
- `docs/plans/architecture/MASTER_PLAN_ARCHITECTURE_IMPLEMENTATION_CHECKLIST.md` (Phase 15 exit gates)
- `docs/plans/master_plan_execution.yaml` (required global docs)
- `docs/plans/architecture/REALITY_COHERENCE_TEST_MATRIX.md` (cross-phase coherence/no-go gates)
- `supabase/functions/README.md` (endpoint migration behavior)

---

## 7) Human Authorization Gates (Required Intervention Points)

The system is agent-autonomous by default, except for these mandatory human gates:

1. Security/legal boundary approvals:
   - Any policy-plane access expansion, consent-basis change, jurisdictional legal interpretation, or disclosure-policy change.
2. Break-glass authorization:
   - Emergency elevated access requires dual human approval, explicit scope, and expiry.
3. Policy exceptions:
   - Any override to default matrix policy behavior requires documented risk acceptance and expiry.
4. Irreversible/high-risk cutovers:
   - Strict-cutoff activation, destructive compatibility removal, or migration step with material blast radius requires explicit go/no-go signoff.

Minimum evidence package for each gate:

- risk summary and affected planes/services
- rollback plan
- monitoring/alert plan
- approver identities and timestamped decision record

---

## 8) What Can Be Preplanned Now (Agent-Executable)

These are intended for low-intervention autonomous execution:

1. Build and maintain migration parity dashboards + alerts.
2. Run scheduled join-audit scans and policy drift checks.
3. Generate strict-cutoff readiness reports and blocker lists.
4. Execute dual-read/dual-write parity validation runs.
5. Run matrix conformance/non-bypass CI suites on every policy change.
6. Prepare release checklists and evidence bundles for human gate decisions.
