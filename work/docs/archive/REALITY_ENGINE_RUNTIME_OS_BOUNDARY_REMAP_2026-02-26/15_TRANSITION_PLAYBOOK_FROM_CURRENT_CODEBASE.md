# 15 - Transition Playbook from Current Codebase

## 1) Current-State Observations (Practical)

1. Core intelligence code remains in `lib/core/ai/*` and is partially coupled to app DI.
2. Runtime-like services are spread across `lib/core/services/*` and `lib/core/ai2ai/*`.
3. Package workspace exists but engine/runtime separation is not yet implemented as runtime truth.

## 2) Phase-by-Phase Migration Map

## Phase A - Boundary Freeze

Actions:
1. Add forbidden import checks for protected engine paths.
2. Mark protected paths in architecture spots registry.
3. Keep behavior unchanged while enforcing boundaries for new code.

## Phase B - Engine Decomposition

Actions:
1. Complete `ContinuousLearningSystem` modular split.
2. Extract memory/learning/planning modules behind contracts.
3. Keep adapters in app layer temporarily.

## Phase C - Runtime Consolidation

Actions:
1. Consolidate runtime concerns into explicit runtime modules:
   - mesh transport
   - identity/security
   - policy kernel
   - scheduler/lifecycle
2. Add capability profile publication service.

## Phase D - Packaging and Bootstrap Split

Actions:
1. Move extracted engine modules into `engine/reality_engine` package target.
2. Move runtime modules into `runtime/avrai_runtime_os` package target.
3. App keeps host adapters and product UX flows.

## Phase E - Cross-OS Hardening

Actions:
1. Implement/validate adapters for iOS/Android/macOS/Windows/Linux.
2. Add cross-OS interop tests and degraded mode tests.
3. Add release and rollback separation lanes.

## 3) Suggested Current Path Mappings

### Candidate moves (conceptual)

- `lib/core/ai/world_model/*` -> `engine/reality_engine/lib/models/*`
- `lib/core/ai/memory/*` -> `engine/reality_engine/lib/memory/*`
- `lib/core/ai2ai/*` transport/runtime concerns -> `runtime/avrai_runtime_os/lib/services/mesh/*`
- `lib/core/services/security/*` runtime-governed pieces -> `runtime/avrai_runtime_os/lib/services/security/*`
- `lib/presentation/*` stays in app host layer

### Candidate adapter boundaries

- Product event mapping in app:
  - `app/host_adapters/engine_event_mapper`
- Runtime capability bridge in app:
  - `app/host_adapters/runtime_capability_bridge`

## 4) Transitional Safety Rules

1. Do not change behavior while moving boundaries (first).
2. Keep adapter shims for one migration cycle.
3. Add parity tests before deleting old call paths.
4. Avoid mixed ownership files after cutover.

## 5) Exit Signals for Completion

1. Engine paths compile and test without app imports.
2. Runtime publishes capability profile consumed by planner.
3. App executes all primary user/business flows via host adapters.
4. CI boundary checks prevent regression.

