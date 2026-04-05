# 07 - System Direction Manifesto

## 1) The Strategic Direction

AVRAI should be built as a 3-layer intelligence system:

1. Reality Engine (cognitive core)
2. AVRAI Runtime OS (operational substrate)
3. AVRAI Product App (human and business interface)

This is not branding. It is an execution constraint.

## 2) Why This Direction Is Correct

### 2.1 It aligns with your actual requirements

You require:
- real-time adaptation,
- mesh-aware behavior,
- cross-device/cross-locality coordination,
- strict safety/governance,
- evolving UX surfaces,
- monetization and third-party lanes,
- internal autonomous research.

A single app-centric architecture cannot hold this without repeated coupling debt.

### 2.2 It preserves what is unique

Your differentiation is not generic chat.
It is runtime-governed, outcome-grounded real-world planning with adaptation.
That value lives in engine + runtime, not in a single UI shell.

### 2.3 It avoids a false dichotomy

The wrong dichotomy is:
- either fully standalone model independent of AVRAI,
- or fully product-coupled app logic.

Correct framing:
- Engine is independent from product workflows,
- Engine is intentionally coupled to runtime contracts.

## 3) Core Architectural Doctrine

1. Reality Engine computes under declared capabilities.
2. Runtime OS owns capability truth and policy enforcement.
3. Product app owns experience and intent capture.
4. No layer may impersonate another layer’s authority.

## 4) Layer Authorities

### 4.1 Reality Engine authority

- learns from outcome evidence,
- predicts state transitions,
- evaluates energy/cost,
- plans action sequences,
- calibrates confidence,
- recommends adaptive policy adjustments within immutable bounds.

### 4.2 Runtime OS authority

- transport/discovery/session orchestration,
- identity and key lifecycle,
- policy kernel execution,
- scheduling and lifecycle mode handling,
- secure storage and attestation,
- rollback control and health containment,
- capability profile publication.

### 4.3 Product App authority

- UX and interaction design,
- domain workflows (user/business/third-party),
- interpretation surfaces and recourse pathways,
- host-level operational dashboards,
- product packaging and onboarding.

## 5) Separation Invariants

1. Engine cannot import product code.
2. Engine does not call native OS APIs directly.
3. Runtime is the sole bridge to native OS constraints.
4. Product does not bypass runtime for privileged operations.
5. Cross-layer interactions occur through versioned contracts.

## 6) Capability Truth Principle

Engine behavior must be capability-aware.
If BLE/Wi-Fi/P2P/AI2AI degrade, engine must degrade policy safely and explicitly.
No silent assumption of full runtime capability.

## 7) Quality Targets by Layer

### Engine
- prediction quality,
- planning efficacy,
- calibration quality,
- adaptation reliability,
- drift handling quality.

### Runtime
- transport reliability,
- security correctness,
- policy conformance,
- lifecycle resilience,
- cross-OS consistency.

### Product
- adoption quality,
- recourse quality,
- transparency/comprehension,
- operational usability,
- business outcome fit.

## 8) Long-Term Vision

- AVRAI Product is a leading host.
- AVRAI Runtime OS is the required operational layer.
- Reality Engine is the durable cognition core.

This design allows continuous product expansion without continually rewriting the intelligence substrate.

