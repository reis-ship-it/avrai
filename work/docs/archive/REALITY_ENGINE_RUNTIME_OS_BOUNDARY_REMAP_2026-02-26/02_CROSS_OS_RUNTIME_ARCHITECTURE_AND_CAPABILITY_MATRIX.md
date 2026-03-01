# 02 - Cross-OS Runtime Architecture and Capability Matrix

## 1) Cross-OS Principle

Do not force fake parity. Use capability negotiation.

- Same runtime contracts across all OS types.
- Different adapter implementations per OS.
- Engine receives a capability profile and plans within available bounds.

## 2) Runtime Contract Categories

1. Identity + Trust
2. Transport + Discovery (BLE/Wi-Fi/AI2AI)
3. Storage + Key Management
4. Scheduler + Lifecycle
5. Policy + Safety Kernel
6. Telemetry + Observability
7. Recovery + Rollback

## 3) OS Adapter Model

Per-OS adapter modules implement identical interfaces:
- `RuntimeTransportAdapter`
- `RuntimeIdentityAdapter`
- `RuntimeSchedulerAdapter`
- `RuntimeStorageAdapter`
- `RuntimeNotificationAdapter`

Each adapter returns `CapabilityProfile` to runtime core.

## 4) Capability Tiers

- `C0`: Minimal local mode (no mesh transport)
- `C1`: Limited transport mode (foreground-only or constrained background)
- `C2`: Full app-level mesh mode
- `C3`: Enhanced mode (desktop/server-friendly long-running operations)

## 5) Example Capability Matrix

| Capability | iOS | Android | macOS | Windows | Linux |
|---|---|---|---|---|---|
| BLE foreground scan/connect | C2 | C2 | C2 | C1/C2 (adapter-dependent) | C1/C2 (adapter-dependent) |
| BLE background reliability | C1 | C2 | C1 | C0/C1 | C0/C1 |
| Wi-Fi discovery integration | C1 | C2 | C1/C2 | C1/C2 | C1/C2 |
| AI2AI mesh transport persistence | C1 | C2 | C2 | C2 | C2 |
| Long-running scheduler control | C1 | C2 | C2/C3 | C2/C3 | C2/C3 |
| Secure key store maturity | C2 | C2 | C2 | C1/C2 | C1/C2 |
| Operator/system monitoring depth | C2 | C2 | C3 | C3 | C3 |

Notes:
- Final tier values depend on chosen implementation and permission states.
- Runtime must evaluate effective capability at runtime, not static compile-time assumptions.

## 6) Interoperability Rules

1. Wire protocol and message schemas are uniform across OSs.
2. Version negotiation handshake required on every peer session.
3. Conflict resolution must be deterministic and idempotent.
4. Clock drift tolerance and ordering semantics must be explicit.

## 7) Failure-Mode Architecture

When required transport is unavailable:
1. Runtime emits capability downgrade.
2. Engine switches to constrained planning policy.
3. App surfaces explainable behavior change (not silent failure).
4. Recovery loop retries with bounded backoff and policy constraints.

## 8) Test Strategy

Required test lanes:
1. Adapter contract tests per OS.
2. Cross-OS interop tests (`ios<->android`, `macos<->windows`, etc).
3. Capability downgrade tests.
4. Security and key-lifecycle tests.
5. Headless engine with mocked runtime capability profiles.

