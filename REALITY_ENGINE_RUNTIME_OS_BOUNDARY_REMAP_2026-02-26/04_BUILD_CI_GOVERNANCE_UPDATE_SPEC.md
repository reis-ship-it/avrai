# 04 - Build, CI, and Governance Update Spec

## 1) New Required CI Checks

1. `engine-product-boundary-check`
- Fails if engine paths import app composition roots or presentation modules.

2. `runtime-contract-conformance-check`
- Ensures runtime adapters implement required interfaces and versioned contracts.

3. `cross-os-capability-matrix-check`
- Ensures supported OS adapters have declared capability profiles and test evidence.

4. `headless-engine-smoke-check`
- Executes core perceive->plan->learn loop without app bootstrap.

5. `host-adapter-mapping-check`
- Validates AVRAI host mappings to runtime/engine contracts.

## 2) Existing Guardrail Enhancements

Enhance `scripts/ci/check_architecture.dart` with:
1. forbidden import matrix for engine/runtime/app layers.
2. baseline mode for incremental adoption.
3. strict mode target date and phase gate.

## 3) Branch Protection Additions

Add required checks for `main`:
- `engine-product-boundary-check`
- `runtime-contract-conformance-check`
- `headless-engine-smoke-check`

Recommended optional checks:
- `cross-os-capability-matrix-check`
- `host-adapter-mapping-check`

## 4) Build and Release Separation

1. Runtime artifact lane:
- Build runtime bundle
- Sign
- Publish with version manifest

2. App artifact lane:
- Build app binaries
- Pin compatible runtime version range

3. Rollback policy:
- Runtime rollback independent from app where compatible
- App rollback independent from runtime where compatible
- Hard incompatibility triggers coordinated rollback bundle

## 5) Governance and PR Template Updates

Add required PR fields:
1. Layer impact (`engine`, `runtime`, `app`, `cross-layer`)
2. Contract change? (`yes/no`, version bump)
3. Capability impact by OS
4. Rollback impact (`runtime`, `app`, `both`)

## 6) Observability Governance

Require every adaptive decision log include:
- engine version
- runtime version
- host adapter version
- policy pack version
- trace id / provenance id

This is required for failure attribution and trustworthy separation claims.

