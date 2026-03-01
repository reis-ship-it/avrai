# 17 - Master Plan Patch Blueprint

## 1) Where to Patch

Insert new section after `10.9`:
- `10.10 Reality Engine / Runtime OS / Host Separation Contract`

## 2) Section Skeleton

1. Definitions
- engine
- runtime os
- product host
- device os

2. Boundary rules
- dependency direction
- forbidden imports
- contract-only integration

3. Required contracts
- engine input/output envelopes
- runtime capability profile
- host adapter contracts

4. Cross-OS requirements
- adapter conformance matrix
- capability negotiation obligations

5. Lifecycle and rollback
- independent artifact versioning
- coordinated rollback on incompatibility

6. Acceptance criteria
- zero forbidden imports in protected paths
- headless engine smoke pass
- capability degraded-mode regression pass
- contract compatibility matrix green

## 3) New Tasks (Proposed IDs)

- 10.10.1 Boundary rule codification and CI enforcement
- 10.10.2 Runtime contract registry and version policy
- 10.10.3 Engine host-neutral schema contract
- 10.10.4 Capability-profile aware planner gating
- 10.10.5 Cross-OS adapter conformance suite
- 10.10.6 Runtime/app artifact lifecycle split
- 10.10.7 Headless engine validation gate
- 10.10.8 Host adapter conformance gate

## 4) Existing Task Re-anchor Notes

- 1.4.24-1.4.29: extraction path into engine/runtime separation
- 7.7.*: include runtime/app independent lifecycle handling
- 10.9.10: include runtime transport security attestation lanes
- 10.9.11/10.9.13: enforce boundary at runtime-engine policy layer

## 5) Gate Language (Recommended)

No new autonomy scope expansion when:
1. runtime-engine boundary checks are red
2. capability degraded-mode tests are red
3. adapter contract conformance is red

