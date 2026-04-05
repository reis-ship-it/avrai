# Master Plan 3-Prong Target End State (Overarching Authority)

**Date:** February 28, 2026  
**Status:** Active authority  
**Purpose:** One umbrella plan for concurrent execution across three isolated prongs: `Apps`, `Runtime OS`, and `Reality Model`.

---

## 1. Outcome This Locks In

The codebase and execution workflow are governed by one master plan, but implemented through three independently buildable prongs:

1. **Apps Prong**: product surfaces and UX in `apps/*`
2. **Runtime OS Prong**: orchestration, policy, transport, identity, and endpoint contracts in `runtime/*`
3. **Reality Model Prong**: model truth and learning/planning internals in `engine/*`

`shared/*` remains the contract layer used by all prongs.

---

## 2. Non-Negotiable Boundary Rules

1. Allowed dependency direction: `apps -> runtime -> engine -> shared`
2. Allowed direct shared access: `apps -> shared`, `runtime -> shared`, `engine -> shared`
3. Forbidden: `apps -> engine`, `runtime -> apps`, `engine -> runtime`, `engine -> apps`
4. Cross-prong integration only through versioned contracts in `shared/*` and runtime endpoint/service interfaces.
5. Every prong change must map to exactly one milestone and declared prong lane in the execution board metadata.

---

## 3. Concurrent Build Contract

To prevent prongs from breaking each other while running concurrently:

1. **Ownership isolation:** each PR declares one primary prong owner (`apps`, `runtime_os`, or `reality_model`).
2. **Interface-first integration:** shared contracts land before cross-prong behavior.
3. **Independent quality gates:** each prong has lane-scoped analyze/test checks before merge.
4. **Fail-closed compatibility:** runtime and engine reject unknown or incompatible contract versions.
5. **Reopen-by-new-milestone only:** regressions are fixed through new milestone rows, never by mutating closed history.

---

## 4. Execution Stack (Umbrella + Per-Prong Plans)

This document is the umbrella authority. Per-prong execution plans:

1. `docs/plans/architecture/PRONG_APPS_CONCURRENT_EXECUTION_PLAN_2026-02-28.md`
2. `docs/plans/architecture/PRONG_RUNTIME_OS_CONCURRENT_EXECUTION_PLAN_2026-02-28.md`
3. `docs/plans/architecture/PRONG_REALITY_MODEL_CONCURRENT_EXECUTION_PLAN_2026-02-28.md`

All four documents must be updated together when boundary contracts or ownership rules change.

---

## 5. Required CI/Validation Gate Set

1. `scripts/ci/check_three_prong_boundaries.py`
2. `scripts/validate_architecture_placement.py`
3. `scripts/validate_execution_board_urk_quality.py`
4. `dart run tool/update_execution_board.dart --check`
5. `dart run tool/update_three_prong_reviews.dart --check`

---

## 6. Source-Of-Truth Links

1. `docs/MASTER_PLAN.md` (phase ownership and task sequencing)
2. `docs/EXECUTION_BOARD.csv` (canonical phase/milestone status)
3. `docs/plans/architecture/TARGET_CODEBASE_STRUCTURE_ENFORCEMENT_2026-02-27.md`
4. `docs/plans/architecture/CODEBASE_MIGRATION_CHECKLIST_3_PRONG_2026-02-27.md`
5. `docs/plans/architecture/THREE_PRONG_ARCHITECTURE_VISUALIZATION_GUIDE_2026-02-27.md`
6. `docs/plans/architecture/ADMIN_COMMAND_CENTER_IDEAL_ARCHITECTURE_2026-02-28.md`
7. `docs/plans/architecture/ADMIN_PRIVATE_SERVER_SECURITY_IMPLEMENTATION_CHECKLIST_2026-02-28.md`
8. `docs/plans/architecture/ADMIN_COMMAND_CENTER_FUTURE_REFERENCES_2026-02-28.md`

---

## 7. AVRAI OS North Star (Post-Production Target End State)

**Phase 12 Authority:** `docs/MASTER_PLAN.md#phase-12-avrai-os`  
**Rationale:** `docs/plans/rationale/PHASE_12_OS_RATIONALE.md`

This section defines the ideal end state of the AVRAI OS as a platform — the north star that Phase 12 executes toward. It is an umbrella authority for all OS-tier decisions the same way this document is for the three-prong build.

### 7.1 What AVRAI OS Is

AVRAI OS is a **cognitive operating system**: the mandatory mediation layer for AI cognition on any device. It manages cognitive resources (inference compute, attention budget, behavioral memory, agent identity) the same way a traditional OS manages physical resources (CPU, RAM, storage, I/O).

It is NOT a replacement for iOS, Android, or Linux. It is a layer that runs **on top of** those systems and **provides AI cognitive services** to everything above it — exactly as Android runs on Linux and provides mobile services to apps without replacing Linux.

**The definitional test:** If an AI company, app developer, or research institution wants access to longitudinal behavioral context, real-world ground truth, or agent-to-agent communication — they call AVRAI OS. They do not build it themselves.

### 7.2 Ideal End State Architecture

```
┌──────────────────────────────────────────────────────────┐
│  Shells / Frontends (any, replaceable)                   │
│  Flutter App │ Web Shell │ CLI │ Third-Party Apps         │
├──────────────────────────────────────────────────────────┤
│  External Integrators (via authenticated API)            │
│  OpenAI │ Anthropic │ Perplexity │ Healthcare │ EdTech   │
├──────────────────────────────────────────────────────────┤
│  Cognitive Syscall API (v1, stable, versioned)           │
│  perceive │ plan │ commit │ observe │ recover             │
│  + Context Enrichment │ Reality Model │ Action Grounding  │
│    Inference Routing APIs (external-facing)              │
├──────────────────────────────────────────────────────────┤
│  Permission Model (user-controlled capability grants)    │
│  Per-app consent │ capability classes │ enforcement      │
├──────────────────────────────────────────────────────────┤
│  Cognitive Kernel (Rust, headless, any device)           │
│  Agent Registry │ AI2AI IPC │ Cognitive Resource Sched.  │
│  Episodic/Semantic/Procedural Memory │ Evolution Cascade │
├──────────────────────────────────────────────────────────┤
│  Intelligence Layer (engine/)                            │
│  Quantum/Knot/Fabric/Worldsheet │ Energy Function        │
│  Transition Predictor │ MPC Planner │ On-Device LLM      │
├──────────────────────────────────────────────────────────┤
│  Network Layer (runtime/)                                │
│  BLE Mesh │ Signal Protocol │ Federated Learning         │
│  AI2AI Discovery │ Anonymous Communication               │
├──────────────────────────────────────────────────────────┤
│  Platform Adapters (thin, per-device)                    │
│  Android :avrai_runtime │ iOS XPC │ Linux daemon │ WASM  │
├──────────────────────────────────────────────────────────┤
│  Host OS (iOS / Android / Linux — delegates to above)    │
└──────────────────────────────────────────────────────────┘
```

### 7.3 Packaging & Distribution Formats (North Star)

Every format below must be available at Phase 12 complete. These are the channels through which AVRAI OS becomes infrastructure others depend on.

| Format | Target Audience | Distribution Channel | Status |
|--------|----------------|---------------------|--------|
| **Dart package** | Flutter/Dart app developers | pub.dev | Phase 12.7.1 |
| **Kotlin/Android AAR** | Android-native developers | Maven Central | Phase 12.7.1 |
| **Swift Package** | iOS/macOS native developers | Swift Package Manager | Phase 12.7.1 |
| **Rust crate** | Systems/server developers | crates.io | Phase 12.7.2 |
| **Python bindings** | AI company ML teams (most common) | PyPI | Phase 12.7.2 |
| **gRPC .proto definitions** | Any language (language-agnostic) | GitHub + docs portal | Phase 12.7.3 |
| **npm/WASM module** | Browser / JavaScript / TypeScript | npm | Phase 12.7.4 |
| **Docker OCI container** | Cloud/enterprise, CI/CD, self-hosted | Docker Hub + GHCR | Phase 12.7.5 |
| **systemd service + install script** | Linux home server / Raspberry Pi | GitHub releases + apt/brew | Phase 12.6.2 |
| **Open-source community edition** | Developers, researchers, civic apps | GitHub (Apache 2.0) | Phase 12.7.6 |

### 7.4 Five Gates Before External Sharing

The OS cannot be shared until all five gates pass (Phase 12 prerequisite summary):

| Gate | Section | What It Unlocks |
|------|---------|----------------|
| Kernel runs headless | 12.1.6 | OS-tier process isolation — not an app anymore |
| Stable syscall API | 12.3.1 | External callers have a contract they can depend on |
| Permission model enforced | 12.3.4 | Privacy and consent requirements satisfied |
| Reality model has baseline | 12.4.2-12.4.3 | API returns meaningful (not garbage) output |
| Packaging published | 12.7.1-12.7.5 | Developer can use AVRAI OS without cloning the repo |

### 7.5 Who AVRAI OS Serves (Beneficiary Map)

**Tier 1 — AI Companies (direct integration, largest commercial value)**
- OpenAI, Anthropic, Perplexity, Google — solve their statelessness and local hallucination problems via Context Enrichment + Reality Model APIs
- Value: personalization without surveillance; local ground truth; last-mile execution

**Tier 2 — Platform / Infrastructure Players**
- Healthcare / mental health apps — longitudinal behavioral context with HIPAA-safe privacy guarantees
- EdTech — persistent learner model across all educational apps
- Enterprise SaaS (Slack, Notion, Linear) — ambient intelligence without each tool surveilling independently
- Wearable / health tech — physical signals + life context integration
- Smart home / IoT — behavioral intelligence layer for device coordination

**Tier 3 — Civic / Research**
- Urban planners / city government — anonymized community formation data
- Public health researchers — longitudinal social connection data, privacy-preserved
- Social scientists — community formation, personality evolution, place-behavior mapping

**Note:** Beta users are Tier 0. The OS opens doors for all tiers above. Beta is not an OS play; it's the proof-of-concept that makes the OS valuable.
