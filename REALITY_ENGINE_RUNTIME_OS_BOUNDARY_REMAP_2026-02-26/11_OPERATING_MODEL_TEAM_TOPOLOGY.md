# 11 - Operating Model and Team Topology

## 1) Team Topology

1. Reality Engine Team
- owns engine contracts, planning, memory, calibration, model lifecycle.

2. Runtime OS Team
- owns transport, identity, policy kernel, cross-OS adapters, runtime reliability.

3. AVRAI Product Team
- owns UX/workflows, host adapters, market and operator experience.

4. Reliability + Security Team (cross-cut)
- owns gates, incident policy, red-team lane, rollback governance.

## 2) RACI (High Level)

### Engine contract changes
- R: Engine
- A: Engine Lead
- C: Runtime, Product, Security
- I: Ops

### Runtime contract changes
- R: Runtime
- A: Runtime Lead
- C: Engine, Product, Security
- I: Ops

### Product adapter changes
- R: Product
- A: Product Lead
- C: Engine, Runtime
- I: Ops

## 3) Change Classes

1. Contract-breaking change
- requires version bump, compatibility matrix update, staged rollout.

2. Runtime capability change
- requires cross-OS matrix update and degraded-mode tests.

3. Engine behavioral change
- requires calibration/fairness/rollback gating.

4. Product-only UX change
- no engine/runtime bump unless mapping contracts change.

## 4) Ownership Artifacts

1. CODEOWNERS by layer.
2. Layer-specific runbooks.
3. Incident playbooks for cross-layer failures.
4. PR template fields enforcing layer-impact disclosure.

## 5) Operational Cadence

Weekly:
- boundary violation review,
- capability matrix drift review,
- incident and rollback summary.

Monthly:
- cross-OS adapter conformance audit,
- contract debt and migration debt review.

Quarterly:
- architecture guard strictness ratchet,
- hardening milestone retrospective.

