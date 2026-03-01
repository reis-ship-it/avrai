# 03 - Master Plan Improvement Proposal

## 1) Required Framing Update

Update `docs/MASTER_PLAN.md` to explicitly state the 3-layer architecture:

- Reality Engine (independent cognition system)
- AVRAI Runtime OS (downloadable coexisting runtime)
- AVRAI Product App (host application)

Replace any implied binary framing that suggests engine must be independent from runtime substrate.

## 2) New Master Plan Subsection (Recommended)

Add section:

`10.10 Reality Engine / Runtime OS / Host Separation Contract`

Include:
1. Boundary definitions
2. Dependency direction rules
3. Contract versioning policy
4. Capability-tier planning requirements
5. Cross-OS adapter obligations

## 3) Master Plan Tasks to Add

### 10.10.1 Boundary Rule Codification
- Define forbidden import matrix for engine/runtime/app layers.

### 10.10.2 Runtime Contract Surface
- Publish stable runtime contracts (identity, transport, policy, scheduler, storage, telemetry).

### 10.10.3 Engine Contract Surface
- Publish host-neutral event/state/action/outcome schemas.

### 10.10.4 Capability-Negotiated Planning
- Require planner behavior to condition on runtime capability profile.

### 10.10.5 Cross-OS Adapter Completion
- Implement and certify adapter contract conformance on iOS/Android/macOS/Windows/Linux.

### 10.10.6 Independent Runtime Artifact Lifecycle
- Separate runtime artifact versioning and rollback from app releases.

### 10.10.7 Headless Engine Validation Gate
- CI must prove engine loop runs without app boot using mocked runtime.

### 10.10.8 Host Adapter Conformance Gate
- AVRAI app mappings to engine/runtime contracts must pass contract tests.

## 4) Existing Tasks to Re-anchor

- 1.4.24-1.4.29 (ContinuousLearningSystem decomposition)
  - re-anchor as extraction path into engine/runtime boundaries.
- 7.7 and 10.9.4 (model lifecycle and rollback bundles)
  - extend to runtime/app split artifact policy.
- 10.9.10 (adversarial hardening)
  - require runtime transport lane attestation and scoped kill switches across OS adapters.
- 10.9.11/10.9.13
  - enforce kernel and policy invariants at engine-runtime boundary.

## 5) New Acceptance Criteria to Add

1. Engine has zero app-composition imports.
2. Runtime transport/security/policy services are available via contract interfaces only.
3. Planner passes capability-degraded regression suites.
4. Runtime and app release/rollback can execute independently where contract-compatible.
5. Cross-OS adapter conformance matrix is green for supported platforms.

## 6) Documentation Improvements Needed

1. Add canonical terminology section in Master Plan:
- `engine`, `runtime`, `host app`, `device OS`.

2. Add architecture figure in plan docs showing 4 strata:
- Device OS
- AVRAI Runtime OS
- Reality Engine
- AVRAI Product UX

3. Add explicit statement:
- BLE/Wi-Fi/P2P/AI2AI may be runtime requirements for target behavior quality.
- Independence is from product UX, not from runtime substrate.

