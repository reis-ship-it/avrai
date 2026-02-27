# 09 - Data, Model, Policy, and Lifecycle Architecture

## 1) Data Plane Separation

## 1.1 Data classes

1. Product interaction data (host UX events)
2. Runtime operational data (capabilities, transport, lifecycle)
3. Engine learning data (state/action/outcome tuples)
4. Governance data (kernel manifests, receipts, evidence bundles)

## 1.2 Data ownership

- Product owns UX event semantics.
- Runtime owns operational truth and policy enforcement logs.
- Engine owns learning state and adaptation traces.

## 2) Schema Strategy

1. Shared schema registry with semantic versioning.
2. Backward compatibility target: `N` and `N-1`.
3. Hard fail for unknown required fields in critical paths.
4. Explicit migration playbooks for each layer.

## 3) Learning Lifecycle

1. Ingest approved outcomes.
2. Consolidate memory.
3. Train/adapt candidate.
4. Evaluate calibration/drift/fairness.
5. Runtime policy gate.
6. Staged promotion.
7. Post-promotion monitoring.
8. Rollback/quarantine if degraded.

## 4) Policy Lifecycle

1. Policy pack authored and signed.
2. Runtime validates signature/window/compatibility.
3. Engine receives policy context tokens.
4. Decisions evaluated under policy kernel.
5. Violations are fail-closed and logged.

## 5) Artifact Lifecycle

Artifacts by layer:

- Engine artifacts:
  - model weights
  - planner configs
  - memory snapshots

- Runtime artifacts:
  - transport modules
  - policy kernel rules
  - adapter binaries

- Product artifacts:
  - app binaries
  - UI configuration
  - host adapter mappings

Each needs independent version, compatibility map, and rollback path.

## 6) Rollback Architecture

1. Soft rollback (engine model/config only)
2. Runtime rollback (policy/adapter/runtime module)
3. Host rollback (app/adapter display behavior)
4. Coordinated rollback bundle when compatibility break crosses layers

## 7) Drift and Fault Attribution

All decisions/events should include:
- engine version
- runtime version
- host adapter version
- policy pack version
- capability profile id
- trace/provenance id

Without these fields, cross-layer fault diagnosis is not reliable.

## 8) Data Safety and Privacy

1. Consent-scoped ingestion contracts.
2. Privacy budget governance for shared/federated outputs.
3. Key lifecycle managed by runtime.
4. Product cannot directly access privileged key paths.

## 9) Evaluation Gates

Minimum promotion gates:
1. outcome quality,
2. calibration quality,
3. protected-slice safety,
4. policy conformance,
5. runtime compatibility,
6. rollback readiness.

