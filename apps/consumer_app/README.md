# AVRAI Consumer App

Standalone consumer app shell.

## Apps Lane Boundary + Compatibility Rules

This app is governed by the Apps prong concurrent execution plan:
- `docs/plans/architecture/PRONG_APPS_CONCURRENT_EXECUTION_PLAN_2026-02-28.md`

Required rules:
1. No direct `apps -> engine` imports.
2. Runtime access must be contract-first via runtime/shared interfaces.
3. App lane changes must remain compatible with current and next shared contract versions during prong-overlap windows.

Traceability anchor:
- `M12-P10-2` (`10.10.12`)

## Run

```bash
flutter pub get
flutter run
```
