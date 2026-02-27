# 20 - Build and Release Conversion Playbook

## 1) Release Lanes

1. Engine lane
- build model/runtime logic package
- run model-quality gates
- publish engine artifacts

2. Runtime lane
- build runtime adapters and policy kernel
- run cross-os and security gates
- publish runtime artifacts

3. App lane
- build product app binaries
- run UX and host adapter conformance tests
- publish app artifacts

## 2) Versioning Policy

Track tuple:
- `engine_version`
- `runtime_version`
- `host_adapter_version`
- `policy_pack_version`

Compatibility matrix governs allowed tuples.

## 3) Rollback Playbook

1. Engine-only rollback
2. Runtime-only rollback
3. App-only rollback
4. Coordinated rollback for incompatibility break

Every rollback action requires traceable evidence and postmortem linkage.

## 4) Artifact Registry Requirements

For each release:
1. artifact id
2. semantic version
3. compatibility range
4. build provenance
5. security attestation
6. rollback target mapping

## 5) Promotion Gates

No promotion when:
1. boundary checks fail
2. compatibility matrix is incomplete
3. degraded mode tests fail
4. security critical lanes are red

