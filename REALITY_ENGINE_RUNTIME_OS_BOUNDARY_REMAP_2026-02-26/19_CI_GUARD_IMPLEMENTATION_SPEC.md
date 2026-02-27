# 19 - CI Guard Implementation Spec

## 1) New Guard Scripts

1. `scripts/ci/check_engine_runtime_boundaries.dart`
- enforce forbidden import matrix by path scope.

2. `scripts/ci/check_runtime_contract_conformance.dart`
- verify interface implementations and contract versions.

3. `scripts/ci/check_headless_engine_smoke.dart`
- run minimal engine loop test with mocked runtime.

4. `scripts/ci/check_cross_os_capability_matrix.dart`
- verify adapter declarations and evidence entries.

## 2) Forbidden Import Matrix (Example)

- Engine paths cannot import:
  - `package:avrai/injection_container.dart`
  - `package:avrai/presentation/...`
  - app-specific workflow modules

- Runtime paths cannot import:
  - app presentation modules

- Product app can import runtime and engine public APIs only.

## 3) Workflow Additions

Add workflows:
1. `.github/workflows/engine-runtime-boundary-guard.yml`
2. `.github/workflows/runtime-contract-conformance-guard.yml`
3. `.github/workflows/headless-engine-smoke-guard.yml`
4. `.github/workflows/cross-os-capability-guard.yml`

## 4) Branch Protection Recommendations

Required checks:
1. engine-runtime boundary guard
2. runtime contract conformance guard
3. headless engine smoke guard

Optional required checks (mature stage):
4. cross-os capability guard

## 5) Baseline and Ratchet Strategy

1. Start with baseline allowlist for violations.
2. Block all new violations immediately.
3. Burn down baseline weekly.
4. Remove baseline and enforce strict mode by milestone gate.

