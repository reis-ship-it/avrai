# 13 - Risks, Anti-Patterns, and Readiness Checklist

## 1) Common Anti-Patterns

1. Engine imports app DI/service locator directly.
2. Product bypasses runtime for transport/policy operations.
3. Runtime adapters expose OS-specific behavior into engine contracts.
4. No capability negotiation; engine assumes full runtime.
5. Mixed observability with no layer attribution.
6. Rollback policy is app-only while runtime/engine drift.
7. “Temporary” direct imports becoming permanent coupling.

## 2) Architecture Risk Checklist

- [ ] Engine has zero app imports in protected paths.
- [ ] Runtime contracts are versioned.
- [ ] Capability profile exists and is consumed by planner.
- [ ] Cross-OS adapter tests pass.
- [ ] Runtime and app rollback policies are documented and tested.
- [ ] Decision logs include version tuples.
- [ ] Red-team lanes include runtime adapter attack surfaces.

## 3) Operational Risk Checklist

- [ ] Incident runbooks map failure to layer ownership.
- [ ] Alerting distinguishes engine/runtime/product failures.
- [ ] Quality gates include degraded capability modes.
- [ ] Release process enforces contract compatibility checks.

## 4) Governance Risk Checklist

- [ ] PR template enforces layer impact declaration.
- [ ] Branch protection includes new boundary checks.
- [ ] Milestones include explicit boundary acceptance criteria.
- [ ] Architecture docs use consistent engine/runtime/product terminology.

