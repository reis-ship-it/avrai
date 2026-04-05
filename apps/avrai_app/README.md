# AVRAI Consumer App

Primary consumer-facing Flutter shell for AVRAI.

## Apps Lane Boundary

This app is governed by the Apps prong concurrent execution plan:
- `work/docs/plans/architecture/PRONG_APPS_CONCURRENT_EXECUTION_PLAN_2026-02-28.md`

Required rules:
1. No direct `apps -> engine` imports.
2. Runtime and model capabilities must be consumed through runtime/shared contracts only.
3. Consumer routes must not expose internal admin controls, break-glass paths, or privileged operational telemetry.
4. Shell-layer changes must stay compatible with concurrent lane work in runtime and shared packages.

Traceability anchors:
- `M31-P10-2`
- `10.1.6`
- `10.10.9`
- `10.10.11`
- `10.10.12`

## Contract-Consumer Adapters

The consumer app should behave like a shell over contracts, not a second runtime.

Use adapters in the app layer when:
- translating runtime/shared contract models into presentation state
- binding route or widget expectations to runtime service responses
- normalizing nullable or fail-closed contract outputs for UX rendering

Do not use adapters to:
- reimplement runtime policy logic
- duplicate governance checks already owned by runtime
- import engine modules directly to avoid contract boundaries

## Consumer/Admin Separation

Consumer app:
- user-facing routes
- consumer-safe telemetry and diagnostics
- presentation adapters over runtime/shared contracts

Admin app:
- internal operator controls
- privileged governance and oversight surfaces
- policy-linked intervention workflows

Rule:
- if a workflow requires operator authority, internal-use agreements, or privileged inspection, it belongs in `apps/admin_app`, not here

## Run

```bash
flutter pub get
flutter run
```

## Verify

```bash
flutter analyze
flutter test
```
