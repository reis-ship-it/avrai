# 12 - Decision Log and Tradeoffs

## D-001: Engine independence from product, not runtime

Decision:
- Engine remains coupled to runtime contracts.

Why:
- Required capabilities (BLE/Wi-Fi/P2P/AI2AI, policy mediation, lifecycle controls) are runtime concerns.

Tradeoff:
- Less theoretical portability, far better operational correctness.

## D-002: Capability matrix over forced parity

Decision:
- Use capability tiers and negotiation across OSs.

Why:
- Native OS constraints differ materially.

Tradeoff:
- More complexity in planning logic, less hidden runtime failure.

## D-003: No big-bang rewrite

Decision:
- Phased extraction with strict boundary checks.

Why:
- Preserve delivery and reduce migration risk.

Tradeoff:
- Temporary duplicate code paths and adapter overhead during transition.

## D-004: Runtime-mediated privileged operations

Decision:
- Product cannot directly execute privileged transport/security operations.

Why:
- Prevent policy bypass and inconsistent behavior.

Tradeoff:
- Requires robust runtime API and adapter discipline.

## D-005: Independent artifacts by layer

Decision:
- Separate versioning and rollback lanes for engine/runtime/product.

Why:
- Reduces blast radius and improves recovery.

Tradeoff:
- More release-management complexity.

## D-006: Mandatory headless engine validation

Decision:
- Require app-independent smoke and contract tests.

Why:
- Proves boundary is real, not conceptual.

Tradeoff:
- Upfront test infrastructure investment.

## D-007: Observability version tuple requirement

Decision:
- Every adaptive decision carries engine/runtime/host/policy versions.

Why:
- Enables trustworthy fault attribution and postmortems.

Tradeoff:
- Slight telemetry overhead.

## D-008: Product-specific semantics remain adapter-level

Decision:
- Engine contracts stay host-neutral.

Why:
- Keeps cognition reusable and testable.

Tradeoff:
- Requires mapping maintenance as product evolves.

