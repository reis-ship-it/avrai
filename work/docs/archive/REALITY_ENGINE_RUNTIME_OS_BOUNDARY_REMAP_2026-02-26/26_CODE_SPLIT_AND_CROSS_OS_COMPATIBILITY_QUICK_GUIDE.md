# 26 - Code Split and Cross-OS Compatibility Quick Guide

Date: 2026-02-26
Purpose: fast execution guide for code decomposition with 3-prong clarity.

## 1) 3-Prong Split Rule

- Reality Engine:
  - Scope: cognition, learning, planning, world-state transitions.
  - Must not depend on presentation, app routes/blocs, or native platform APIs.
  - Allowed dependencies: engine contracts + runtime contracts.

- AVRAI Runtime OS:
  - Scope: transport, identity, storage adapters, policy/safety enforcement, scheduler, capability detection.
  - May depend on native platform APIs and network stacks.
  - Must not depend on app presentation composition.

- AVRAI App:
  - Scope: UX, pages, widgets, BLoCs, user workflows.
  - Calls runtime and engine through contracts only.
  - Must not reach engine internals directly.

## 2) Priority File Splits

1. `lib/core/ai/continuous_learning_system.dart` (~3500 LOC)
   - Split into:
     - `lib/core/ai/continuous_learning/ingestion/`
     - `lib/core/ai/continuous_learning/outcomes/`
     - `lib/core/ai/continuous_learning/episodic/`
     - `lib/core/ai/continuous_learning/policy/`
     - `lib/core/ai/continuous_learning/runtime_adapters/`
   - Keep a thin compatibility facade at current path.
   - Ownership: Reality Engine (+ runtime adapter edge only).

2. `lib/core/ai2ai/connection_orchestrator.dart` (~4600 LOC)
   - Split into:
     - `.../discovery/`
     - `.../routing/`
     - `.../trust/`
     - `.../resilience/`
     - `.../telemetry/`
   - Ownership: Runtime OS.

3. `lib/injection_container.dart` (~2000 LOC)
   - Split into:
     - `lib/bootstrap/runtime_bootstrap.dart`
     - `lib/bootstrap/engine_bootstrap.dart`
     - `lib/bootstrap/app_bootstrap.dart`
   - Keep a single entrypoint that composes all three.
   - Ownership: bootstrap boundary layer.

4. `lib/core/services/social_media/social_media_connection_service.dart` (~2700 LOC)
   - Split into:
     - `.../oauth/`
     - `.../sync/`
     - `.../mapping/`
     - `.../fallbacks/`
   - Ownership: Runtime OS.

5. `lib/core/services/reservation/reservation_service.dart` (~1700 LOC)
   - Split orchestration from domain policy and persistence:
     - `.../reservation_orchestrator.dart`
     - `.../reservation_policy.dart`
     - `.../reservation_repository_adapter.dart`
   - Ownership: app-domain orchestration with runtime adapters.

## 3) Split Execution Pattern (for each large file)

1. Add target folders + new classes.
2. Move one concern at a time (no behavior changes).
3. Keep old file as facade delegating to new modules.
4. Run unit tests and boundary checks.
5. Remove facade only when all callsites migrate.

## 4) Cross-OS / Non-AVRAI-OS Compatibility Rules

AVRAI Runtime OS is a coexisting runtime over device-native OS. To stay cross-compatible:

- Runtime contract is authority:
  - Identity, Transport, Policy, Scheduler, Storage, Telemetry, Capabilities.
- Native adapters are per host:
  - iOS/macOS adapter
  - Android adapter
  - Windows adapter
  - Linux adapter
  - Web adapter (degraded capability profile)
- Capability-profile-first behavior:
  - Engine/planner must degrade by runtime capability profile.
  - Never assume BLE/Wi-Fi/P2P/AI2AI availability.
- N/N-1 compatibility:
  - Host adapter contract versions must remain compatible with runtime registry.

## 5) Required CI Gates During Split Work

- `Engine Runtime Boundary Guard / engine-runtime-boundary`
- `Headless Engine Smoke Guard / headless-engine-smoke`
- `PRD Traceability Guard / traceability`
- `Execution Board Guard / execution-board-check`

## 6) Immediate Next Milestones

1. Complete `continuous_learning_system.dart` decomposition with facade preservation.
2. Wire runtime-bootstrap contract validation before app boot (done; keep enforced).
3. Add per-host adapter contract manifests and per-host conformance tests.
4. Decompose `connection_orchestrator.dart` into runtime submodules.
