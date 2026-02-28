# AVRAI Admin App

Standalone admin app shell.

## Internal-Only Usage Policy

This app is for internal operators only.

Why:
- It exposes privileged runtime governance controls (kernel state/mode changes).
- It surfaces sensitive operational telemetry and decision traces.
- It can trigger administrative actions that are not safe for consumer distribution.

Policy:
- Do not distribute this app to public app stores.
- Access must remain role-gated (`admin`) and restricted to trusted internal networks/devices.
- Every login requires explicit re-acceptance of internal-use terms.

## Apps Lane Boundary + Compatibility Rules

This app is governed by the Apps prong concurrent execution plan:
- `docs/plans/architecture/PRONG_APPS_CONCURRENT_EXECUTION_PLAN_2026-02-28.md`

Required rules:
1. No direct `apps -> engine` imports.
2. Runtime/admin controls must be consumed through runtime/shared contracts only.
3. Internal-only controls must never be surfaced through consumer app routes.

Traceability anchor:
- `M12-P10-2` (`10.10.12`)

## Run

```bash
flutter pub get
flutter run
```
