# 01 - Architecture Remap and Target Structure

## 1) Boundary Model

Use a 3-layer architecture:

1. Reality Engine
- Learns, predicts, plans, calibrates, and self-heals under kernel constraints.
- No direct UI or product workflow dependencies.

2. AVRAI Runtime OS
- Provides runtime substrate: transport, identity, policy, security, scheduling, storage, capability negotiation.
- Bridges native OS constraints to engine contracts.

3. AVRAI Product App
- UX, product journeys, domain features (users, businesses, third-party surfaces).
- Consumes runtime + engine outputs through adapters.

## 2) Target Dependency Direction

Allowed:
- App -> Runtime OS -> Engine
- App -> Runtime OS
- Runtime OS -> Engine

Forbidden:
- Engine -> App
- Engine -> App composition roots
- Product layers bypassing runtime for privileged capabilities

## 3) Optimized Working File/Package Structure

```text
/Users/reisgordon/AVRAI
  /apps
    /avrai_app
      /lib
        /presentation
        /product_workflows
          /user
          /business
          /third_party
        /host_adapters
          /engine_event_mapper
          /engine_action_executor
          /runtime_capability_bridge
        /monitoring_surfaces
          /admin
          /operator

  /runtime
    /avrai_runtime_os
      /lib
        /bootstrap
        /contracts
          /identity
          /transport
          /policy
          /storage
          /scheduler
          /telemetry
          /capabilities
        /services
          /mesh
            /ble
            /wifi
            /ai2ai
          /security
          /policy_kernel
          /sync_and_recovery
          /device_lifecycle
        /adapters
          /ios
          /android
          /macos
          /windows
          /linux
        /interop
          /protocol
          /versioning

  /engine
    /reality_engine
      /lib
        /bootstrap
        /contracts
          /state
          /events
          /actions
          /outcomes
        /memory
          /episodic
          /semantic
          /procedural
          /deterministic_journal
        /models
          /state_encoder
          /energy_function
          /transition_predictor
          /planner
        /governance
          /kernel_rules
          /belief_tiers
          /rollback_policies
        /evaluation
          /calibration
          /drift
          /counterfactual

  /shared
    /avrai_core
      /lib
        /primitives
        /schemas
        /clock
        /common_errors

  /ops
    /ci
      /boundary_guards
      /contract_tests
      /cross_os_matrix
      /headless_engine_checks

  /docs
    /plans
    /architecture
    /runtime
```

## 4) Main Functional Responsibilities by Stakeholder Surface

### Users
- App owns UX and intent capture.
- Runtime owns secure execution context and capability state.
- Engine owns recommendation/planning logic.

### Third Party
- App exposes consented data products and external APIs.
- Runtime enforces policy/security contracts.
- Engine contributes aggregate intelligence outputs only via approved contracts.

### Internal Research
- Research lane writes to deterministic journals/evidence bundles.
- Runtime controls experiment safety gates.
- Engine consumes approved evidence through lifecycle gates.

### System Monitoring
- Runtime emits infrastructure health + capability telemetry.
- Engine emits model health + drift + calibration telemetry.
- App emits UX/adoption telemetry.
- Monitoring dashboards must separate these three channels.

## 5) Non-Negotiable Boundary Rules

1. Engine modules must not import app DI/composition roots.
2. Runtime is the only layer allowed to directly manage transport and device-OS capability state.
3. Product-specific event names are adapter concerns, not engine primitives.
4. All cross-layer calls go through versioned contracts.

