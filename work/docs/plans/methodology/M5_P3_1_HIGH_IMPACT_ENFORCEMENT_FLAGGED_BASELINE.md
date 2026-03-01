# M5-P3-1 High-Impact Conviction Enforcement (Flagged) Baseline

## Objective
Enable production enforcement path for high-impact actions while preserving a safe shadow fallback.

## Runtime Contract
- Default mode remains `shadow`.
- Enforcement mode is activated only when both flags are enabled:
  - `conviction_gate_production_enforcement`
  - `conviction_gate_high_impact_enforcement`
- Flag checks are evaluated with gate `subjectId` for cohort-targeting support.
- Non-high-impact requests remain in shadow mode.

## Wiring
- Gate resolver + evaluator defaults: `lib/core/controllers/conviction_shadow_gate.dart`
- High-impact controller paths:
  - `lib/core/controllers/checkout_controller.dart`
  - `lib/core/controllers/payment_processing_controller.dart`

## Validation
- Unit tests: `test/unit/controllers/conviction_shadow_gate_test.dart`
- Telemetry sink remains active for all decisions.
- Canary rollout config contract: `configs/runtime/conviction_gate_canary_rollout.json`
- Canary rollout config guard: `scripts/runtime/check_conviction_canary_rollout_config.py`
- Canary dry-run fixture: `configs/runtime/conviction_gate_canary_dry_run_fixture.json`
- Canary dry-run fixture guard: `scripts/runtime/check_conviction_canary_dry_run_fixture.py`
- Canary dry-run runner: `scripts/runtime/run_conviction_canary_dry_run.sh`
- Canary dry-run telemetry output: `docs/plans/methodology/MASTER_PLAN_3_PRONG_SHADOW_GATE_TELEMETRY_CANARY_DRY_RUN.md`

## Canary Rollout Contract
Use `FeatureFlagService.updateRemoteConfig` with targeted users:

```dart
await featureFlags.updateRemoteConfig({
  'conviction_gate_production_enforcement': FeatureFlagConfig(
    enabled: true,
    rolloutPercentage: 100,
    targetUsers: <String>['user-canary-1', 'user-canary-2'],
  ),
  'conviction_gate_high_impact_enforcement': FeatureFlagConfig(
    enabled: true,
    rolloutPercentage: 100,
    targetUsers: <String>['user-canary-1', 'user-canary-2'],
  ),
});
```

Control users not in `targetUsers` continue in shadow mode.

This milestone state is `In Progress` and ready for staged flag rollout.
