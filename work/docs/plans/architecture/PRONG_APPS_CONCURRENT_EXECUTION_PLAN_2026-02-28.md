# Apps Prong Concurrent Execution Plan

**Date:** February 28, 2026  
**Prong:** Apps (`apps/*`)  
**Status:** Active

---

## Scope

Owns product-facing surfaces:

1. Consumer app UX/UI
2. Admin app UX/UI (internal-only)
3. Routing, page composition, and presentation-layer state wiring

---

## Boundaries

1. No direct `apps -> engine` imports.
2. Runtime interactions only through runtime interfaces/endpoints and shared contracts.
3. No business/domain logic that belongs in runtime or engine.

---

## Concurrent Safety Rules

1. App changes must tolerate forward-compatible shared contract additions.
2. Feature flags must guard behavior that depends on runtime/engine capabilities not yet merged.
3. Admin-only features must preserve internal-use-only controls and login-time agreement gates.

---

## Build/Test Gates

1. App-scoped static analysis and tests per app package.
2. Route and auth-gate regression coverage for admin and consumer entrypoints.
3. Any contract-consuming UI change requires compatibility verification against current shared schema version.

---

## Integration Points

1. Runtime OS plan: `docs/plans/architecture/PRONG_RUNTIME_OS_CONCURRENT_EXECUTION_PLAN_2026-02-28.md`
2. Reality Model plan: `docs/plans/architecture/PRONG_REALITY_MODEL_CONCURRENT_EXECUTION_PLAN_2026-02-28.md`
3. Umbrella authority: `docs/plans/architecture/MASTER_PLAN_3_PRONG_TARGET_END_STATE.md`
