# V0.5 Beta Launch Gate Matrix (Release Freeze v1)

## Scope and Freeze Authority

This document is the Day 1 baseline gate freeze for `plan-baseline` in
`/Users/reisgordon/.cursor/plans/v0.5_beta_launch_readiness_64691f7d.plan.md`.
It locks the launch acceptance gates and prevents scope expansion until the remaining
Day 1–14 work blocks are complete.

## Sources Used

- `work/docs/agents/tasks/phase_7/week_51_52_task_assignments.md`
- `work/docs/ai2ai/10_status_gaps/READINESS_ASSESSMENT.md`
- `work/docs/ai2ai/10_status_gaps/CURRENT_STATUS.md`
- `work/docs/agents/reports/agent_3/phase_7/week_51_52_test_execution_report.md`
- `work/docs/agents/reports/agent_3/phase_7/week_51_52_test_coverage_validation_report.md`

## Scope Lock (No Scope Drift)

- In scope for this v0.5 baseline:
  - Test/quality gates and hardening.
  - AI2AI transport confidence (BLE/WebRTC/WiFi paths and fallback behavior).
  - Trust/privacy/UX visibility and release readiness controls.
- Explicitly out of scope:
  - New feature launches not already planned in this sequence.
  - New model/algorithm experiments or benchmark changes.
  - Visual redesigns unrelated to production readiness, trust, or transport reliability.

## Accepted Launch Gates (Must Be Green)

All gates below are required for go/no-go and are copied from existing Phase 7 success criteria.

### 1) Core Quality Gates

| Gate | Target | Required Evidence | Pass Condition |
| --- | --- | --- | --- |
| Unit test coverage (services) | 90%+ | Test execution with coverage output | ≥ 90% |
| Unit test coverage (repositories) | 85%+ | Test execution with coverage output | ≥ 85% |
| Unit test coverage (models) | 80%+ | Test execution with coverage output | ≥ 80% |
| Integration test coverage | 85%+ | Test execution with coverage output | ≥ 85% |
| Widget test coverage | 80%+ | Test execution with coverage output | ≥ 80% |
| E2E coverage | 70%+ | Test execution with coverage output | ≥ 70% |
| All-test pass rate | 99%+ | Full suite run | ≥ 99% passing |
| Flutter analyze errors | 0 | CI and local analyze | 0 errors |
| Security validation | Complete | Security checklist + results | Must be complete |
| Production readiness checklist | Complete | Backend checklist artifact | Must be complete |

### 2) User-Facing and Delivery Gates

| Gate | Target | Required Evidence | Pass Condition |
| --- | --- | --- | --- |
| Design token compliance | 100% | Design audit for AppColors/AppTheme usage | 100% |
| Accessibility compliance | WCAG 2.1 AA | Accessibility audit | All critical flows compliant |
| Production-facing privacy controls | Visible and actionable | UI review + screenshots/checklist | All critical privacy controls discoverable |
| Transport user feedback | Clear error and state messaging | UI copy + interaction walkthrough | No silent transport failure states |

### 3) Transport & Operational Gates

| Gate | Target | Required Evidence | Pass Condition |
| --- | --- | --- | --- |
| BLE walk-by + discovery/session setup path | Primary transport confidence | 2-device real-device matrix run | Stable discovery and session establishment |
| WebRTC signaling behavior | Configured path + fallback | Signaling check + offline/online behavior | No hard-stop when cloud-assisted path is unavailable |
| Android WiFi Direct | Lower-priority fallback lane | Runtime validation notes | Predictable fallback to BLE/other lane |
| Device-pair smoke matrix | Discovery + setup + learning exchange | Test matrix completion | All required combinations covered |

## Baseline Evidence Snapshot (Date-Stamped)

### Current Reported Test State

- `agent_3` execution report currently shows:
  - 2,582 tests passing
  - 558 tests failed
  - 82.2% pass rate
  - 261 KB `coverage/lcov.info` generated
- Failure profile is dominated by platform channel gaps (`GetStorage` / `path_provider`) and compilation issues.
- Interpretation: **Launch gates are currently blocked by unresolved test execution debt.**

### Current Readiness Snapshot from AI2AI Assessment

- Readiness document classifies core AI and privacy systems as implemented, while:
  - UI integration has residual work.
  - Testing validation still needs verification.
  - Physical layer integration is the highest blocking technical gap in the transport surface.
- Current status report lists platform-specific completion as medium-priority in:
  - Android BLE advertising (native channel needs)
  - WebRTC signaling deployment on non-simulator paths
  - Android WiFi Direct (not primary but expected fallback)

## Reproducibility and Dependency Locks

- Flutter baseline observed in CI workflows: **3.32.6**.
- Required runtime/build/test secrets (minimum for meaningful baseline runs):
  - `SUPABASE_URL`
  - `SUPABASE_ANON_KEY`
- Test/runtime transport flags used by smoke tooling:
  - `RUN_SIGNAL_NATIVE_TESTS=true` (when native transport artifacts are available)
  - `SIGNAL_SMOKE_COMMUNITY_ID` (optional, for community stream path)
- `pubspec.lock` files are not present in tracked working trees in current snapshot; baseline lock artifacts must be generated and checked in for reproducible reruns before release gate freeze.

## Baseline Freeze Decision

With the current evidence, this gate matrix is published as **incomplete** and remains the active target baseline.

### Day 1 Hard Stop Conditions

- Do not claim v0.5 ready until every row in the gate matrix above is green.
- Any new task added must be explicitly tagged as unblocker and approved against these gates.
- All subsequent plan tasks must update these gates with measured evidence, not assumptions.

## Recommended Baseline Commands

1. `flutter analyze`
2. `flutter test --coverage`
3. `flutter test --coverage -j 1` while stabilizing individual suites
4. Transport and UI smoke evidence collection per transport/UX tasks

## Day 12-14 Execution Snapshot (2026-03-04)

### Runbook Checks Executed

- `flutter analyze` -> **PASS** (`No issues found`).
- `flutter test apps/avrai_app/test/widget/pages/settings/privacy_settings_page_test.dart` -> **PASS**.
- Two-device DM smoke (`work/scripts/smoke/run_signal_two_device_transport_smoke.sh`) -> **PASS** with `RUN_ID=ea092c0f-07c1-4226-a8ed-37539f283636` (`Role A/B exit: 0`).
- `supabase migration list --linked` -> **PASS** (local/remote parity through `20260304201000`).
- `supabase functions list --project-ref nfzlwgbvezwwrutqpedy` -> **PASS** (`dm-transport-enqueue-v1`, `dm-enqueue-v1` active).
- `flutter build apk --release` -> **PASS** (`build/app/outputs/flutter-apk/app-release.apk`, 226.5MB).
- `flutter test --coverage` -> **IN PROGRESS / BLOCKED** for go/no-go baseline due existing suite failures (observed running tally reached `+1795 ... -145` before termination).

### Current Gate Status Delta

- **Green now:** analyzer gate, targeted privacy widget gate, transport smoke gate, Supabase migration/state gate, release APK build gate.
- **Blocked now:** full-suite pass-rate/coverage gates.

### Immediate Unblockers

1. Re-run full `flutter test --coverage` and publish final pass-rate/coverage numbers for go/no-go.
2. Triage and fix the currently failing suite set (`+1795 ... -145`) until pass-rate reaches gate threshold.

