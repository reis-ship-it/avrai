# Reality Model + AVRAI Separation Recommendation Report

**Date:** February 26, 2026  
**Status:** Architecture Recommendation (Implementation-Guiding)  
**Scope:** Clarify, harden, and operationalize separation between:
- **Reality Model** (independent intelligence runtime)
- **AVRAI App** (product host/interface)

---

## 1) Executive Summary

The current codebase and plan are **directionally correct** for separation, but not yet structurally complete.

What is already right:
- Clear intelligence-first philosophy and hardcoded-invariant boundaries in `docs/MASTER_PLAN.md`.
- Explicit world-model architecture targets (state encoder, energy function, transition predictor, planner).
- Governance primitives for autonomous systems (kernel manifests, lifecycle policy, fail-closed gates, rollback).
- Existing package workspace (`packages/*`) and architecture guard infrastructure.

What is not yet separated enough:
- Core learning/runtime classes still import app composition roots (`package:avrai/injection_container.dart`) and resolve dependencies globally (`di.sl`, `GetIt.instance`).
- App composition and model/runtime composition are still effectively one graph.
- Package split exists, but an independent, production-grade reality runtime package is not yet implemented.
- Architecture CI checks enforce only part of desired boundaries.

Recommendation:
- Continue Master Plan execution, but add an explicit separation lane with enforceable boundaries, package migration, runtime extraction, and CI policy upgrades.
- Treat this as a **cross-cutting architecture hardening track** aligned with existing milestones (especially Phases 1, 7, 8, 10).

---

## 2) Review Basis (Source Authority)

This report is based on:
- `docs/MASTER_PLAN.md`
- `docs/EXECUTION_BOARD.md` / `docs/EXECUTION_BOARD.csv`
- `docs/plans/philosophy_implementation/AVRAI_PHILOSOPHY_AND_ARCHITECTURE.md`
- `docs/plans/philosophy_implementation/BIAS_AND_DIGNITY_GUARDRAILS.md`
- `docs/plans/architecture/ARCHITECTURE_INDEX.md`
- `docs/plans/architecture/REPO_HYGIENE_AND_ARCHITECTURE_RULES.md`
- `scripts/ci/check_architecture.dart`
- Current runtime composition and AI code in `lib/`
- Current package state in `packages/`
- Build/governance docs: `docs/GITHUB_ENFORCEMENT_SETUP.md`, `melos.yaml`

---

## 3) Separation Definitions (Canonical)

## 3.1 Reality Model (Independent System)

The Reality Model is the independent intelligence runtime responsible for:
- state observation/encoding,
- memory and recall,
- transition prediction,
- energy/cost evaluation,
- policy/planning,
- uncertainty and calibration,
- autonomous adaptation under immutable policy contracts.

It must run with:
- no AVRAI UI dependency,
- no AVRAI app composition dependency,
- pluggable host adapters for identity/storage/network/policy.

## 3.2 AVRAI (Host Product)

AVRAI is a host application responsible for:
- product UX/UI,
- product workflows (onboarding, search, lists, communities, etc.),
- platform integrations and product surfaces,
- policy packaging and operator workflows,
- host adapter implementation for reality runtime ports.

## 3.3 Contract Between Them

The boundary should be:
- **Reality Model** consumes typed host-neutral events/state snapshots and returns ranked plans/actions/explanations.
- **AVRAI Host** maps product events to model contracts and maps model outputs to UI/workflow actions.

---

## 4) Current State Assessment

## 4.1 What Is Right (Keep and Strengthen)

1. `MASTER_PLAN` already codifies immutable-vs-learned boundaries and non-self-modifying constraints.
2. Universal self-healing contract and release-gated robustness architecture are well-specified.
3. Deterministic governance primitives exist in code:
   - kernel registry/signature validation,
   - lifecycle policy,
   - belief-tier contract,
   - model-family namespacing (`reality_model`, `universe_model`, `world_model`).
4. Discoverability and anti-overblocking principles are explicit and aligned with dignity/agency docs.
5. Workspace and package infrastructure already exists (`melos`, package modules, architecture scripts).

## 4.2 What Is Acceptable but Incomplete

1. World-model folders in `lib/core/ai/world_model/*` define intent, but migration from product-heavy services remains incomplete.
2. `ContinuousLearningSystem` decomposition is planned (1.4.24-1.4.29) and is the right direction, but still backlog.
3. Execution board already has relevant milestones, but separation is implicit rather than a named architecture track.
4. Package boundaries are partially enforced, but primarily as package->app anti-leak, not full runtime isolation.

## 4.3 What Must Improve (Primary Gaps)

1. **Core runtime coupling to app DI**  
   Multiple `lib/core` and `lib/data` components import `package:avrai/injection_container.dart` and resolve dependencies globally.

2. **Single app-centric composition root**  
   `main.dart` + `injection_container.dart` still compose product + runtime as one dependency graph.

3. **No independent reality-runtime package implementation**  
   `packages/avrai_ml` is mostly scaffold; independent runtime is not yet operational there.

4. **Boundary checks are one-directional**  
   Current architecture guard prevents package->app leaks, but does not prevent app-composition leakage into runtime/core.

5. **Ontology still product-embedded**  
   Many core event/action contracts are AVRAI-specific; adapters are not yet first-class.

6. **Docs and naming drift reduce clarity**  
   Some architecture docs still contain stale `spots` naming or mixed terminology, which blurs the separation goal.

---

## 5) Target Architecture (Recommended End-State)

## 5.1 Four-Layer Model

1. **Reality Kernel (immutable policy core)**  
   Kernel manifests, belief tiers, lifecycle policy, freeze/rollback controls.

2. **Reality Runtime (learnable system)**  
   Memory, state encoding, predictors, planner, adaptation, observability; no app imports.

3. **Host Adapter Layer**  
   Ports for identity, storage, event stream, policy pack, transport, scheduling, and action executors.

4. **AVRAI Host Product**  
   UI/workflows, product orchestration, platform integration, and adapter implementations.

## 5.2 Required Technical Rules

1. `Reality Runtime` code must not import:
   - `package:avrai/...`
   - presentation modules
   - app composition roots
2. Runtime dependencies are constructor-injected via ports/interfaces only.
3. Host-specific event semantics must pass through adapter translators.
4. Runtime artifacts version independently from app artifacts.

---

## 6) Recommended Workstreams (Aligned to Master Plan)

## 6.1 Workstream A: Boundary Enforcement (Immediate)

Aligns to:
- 10.7 / 10.8 (reorg + architecture cleanup),
- 10.9.1 (production readiness gate),
- 10.9.11 / 10.9.13 (change-control + kernel integrity).

Actions:
1. Extend architecture CI checks:
   - forbid app composition imports in reality runtime paths.
2. Add runtime isolation lint/check script:
   - fail on `lib/core/ai/**` importing `injection_container.dart` (or equivalent forbidden roots).
3. Promote strict boundary policy from recommendation to required check in branch protection.

## 6.2 Workstream B: Runtime Extraction to Package

Aligns to:
- Phase 1 memory and learning tracks,
- Phase 3/4/5/6 world-model stack,
- 1.4.24-1.4.29 modular decomposition.

Actions:
1. Finish `ContinuousLearningSystem` facade decomposition first.
2. Move extracted runtime modules into package runtime target (recommended `packages/avrai_ml` or new `packages/avrai_reality`).
3. Introduce `RealityRuntimeBootstrap` in package scope (not app scope).
4. Keep AVRAI-side adapters in app code until host-neutral adapter package is mature.

## 6.3 Workstream C: Contract and Ontology Hardening

Aligns to:
- 1.1D unified retrieval contracts,
- 1.1E deterministic memory/governance contracts,
- 5.1/6.1/6.2 planning + guardrails.

Actions:
1. Define host-neutral `State/Event/Action/Outcome` contract set.
2. Build AVRAI-specific translator adapters:
   - AVRAI event -> runtime event
   - runtime action -> AVRAI action executor
3. Mark AVRAI-specific actions as adapter-resolved aliases, not runtime-native primitives.

## 6.4 Workstream D: Independent Runtime Operations

Aligns to:
- 7.7 model lifecycle,
- 10.9.4 rollback bundles,
- 10.9.9 observability.

Actions:
1. Separate runtime versioning from app versioning.
2. Define runtime artifact manifest and compatibility matrix.
3. Add headless runtime test harness in CI:
   - run perceive -> plan -> learn loop without Flutter/app boot.

---

## 7) Concrete Improvements to Master Plan / Architecture / Build Docs

## 7.1 `docs/MASTER_PLAN.md` (Recommended Additions)

Add a dedicated subsection under Phase 10 (or cross-phase architecture lane):
- **Reality Model / Host Separation Contract**
  - forbidden dependency rules,
  - package ownership target,
  - adapter contract requirements,
  - independent release artifact requirements.

Add explicit acceptance criteria:
1. No app composition imports in runtime paths.
2. Runtime can execute headless integration loop.
3. Host adapters are the only location where AVRAI semantics enter runtime.
4. Rollback/version checks support runtime/app decoupled updates.

## 7.2 `docs/EXECUTION_BOARD.csv` and `docs/EXECUTION_BOARD.md`

Add milestones for separation track (example placement, to be finalized by owners):
1. Boundary CI hardening milestone.
2. Continuous learning decomposition + extraction milestone.
3. Runtime package bootstrap milestone.
4. Host adapter contract and translator milestone.
5. Headless runtime validation + non-AVRAI harness milestone.

Map each milestone to:
- PRD IDs,
- specific `MASTER_PLAN` refs,
- architecture spot,
- measurable exit criteria.

## 7.3 `docs/plans/architecture/REPO_HYGIENE_AND_ARCHITECTURE_RULES.md`

Improve:
1. Replace stale naming (`spots`) with current project naming (`avrai`) consistently.
2. Add reciprocal boundary rule:
   - runtime/core cannot import app composition roots.
3. Add explicit forbidden-import matrix by directory.

## 7.4 `scripts/ci/check_architecture.dart`

Enhance:
1. Keep existing package->app rule.
2. Add runtime isolation rule set:
   - e.g., `lib/core/ai/**`, `lib/core/ml/**` cannot import app container/presentation roots.
3. Add per-rule baseline support with goal to retire baseline over time.

## 7.5 `docs/GITHUB_ENFORCEMENT_SETUP.md`

Add required check recommendation:
- `Reality Runtime Boundary Guard / reality-runtime-boundary`

Add PR checklist fields:
1. `Runtime boundary impacted?`
2. `Host adapter changes?`
3. `Headless runtime test status`

## 7.6 `docs/plans/architecture/ARCHITECTURE_INDEX.md`

Add this separation report to canonical guardrail references and cross-link from:
- Core guardrails section,
- AI2AI/offline/runtime architecture section.

## 7.7 `docs/MASTER_PLAN_TRACKER.md`

Add this document as active architecture recommendation plan to keep traceability and avoid drift.

---

## 8) Recommended Codebase Boundary Policy (Implementation Policy)

## 8.1 Directory Ownership Intent

1. `packages/avrai_ml` (or `packages/avrai_reality`)  
   - reality runtime, model contracts, model bootstrap, headless runtime harness.

2. `lib/core/services/...` + `lib/presentation/...`  
   - AVRAI host workflows, UI, app adapters, product orchestration.

3. `packages/avrai_core`  
   - shared neutral primitives only.

## 8.2 Dependency Direction (Required)

Allowed:
- Host -> Runtime package
- Runtime -> shared primitives/interfaces

Disallowed:
- Runtime -> Host app modules
- Runtime -> Host composition root

---

## 9) Risk Register for Separation Program

1. **Risk:** Decomposition stalls due to monolith complexity  
   **Mitigation:** Enforce module-by-module extraction with facade parity tests (already aligned to 1.4.24-1.4.29).

2. **Risk:** Runtime behavior drift during extraction  
   **Mitigation:** contract tests + replay tests + no-drift acceptance gate before migration completion.

3. **Risk:** CI fatigue from new checks  
   **Mitigation:** staged rollout with baseline, explicit sunset date, and clear ownership.

4. **Risk:** Terminology confusion (`reality`, `world`, `universe`)  
   **Mitigation:** publish canonical terminology table and require use in docs/PR templates.

5. **Risk:** Product velocity slowdown  
   **Mitigation:** run separation as parallel hardening lane with milestone-gated increments, not big-bang rewrite.

---

## 10) Definition of Done (Separation v1)

Separation v1 is complete when all are true:

1. Runtime boundary CI check is required and green.
2. Runtime modules have zero app composition imports.
3. `ContinuousLearningSystem` responsibilities are modularized and extracted behind ports.
4. Runtime package has a documented bootstrap API and headless integration test.
5. AVRAI host uses adapters/translators for runtime contract ingress/egress.
6. Runtime versioning + rollback artifacts are managed independently from app binaries.
7. Docs are aligned:
   - Master plan section,
   - execution board milestones,
   - architecture guardrails,
   - CI enforcement setup.

---

## 11) 30/60/90-Day Practical Rollout (Recommended)

## Day 0-30

1. Add boundary rules + CI guard.
2. Finalize `ContinuousLearningSystem` decomposition plan implementation start.
3. Publish canonical host/runtime contract draft.
4. Update architecture docs/index/tracker for separation lane.

## Day 31-60

1. Extract first runtime modules into package.
2. Implement AVRAI adapter translators for extracted modules.
3. Add headless runtime integration harness in CI.
4. Add runtime artifact manifest + compatibility checks.

## Day 61-90

1. Migrate planner/memory adapters through package boundary.
2. Enforce strict boundary mode (reduce baseline allowances).
3. Validate one non-AVRAI host harness path (minimal reference host).
4. Promote separation lane milestones to `Done` with evidence.

---

## 12) Final Recommendation

Proceed with Master Plan as-is for intelligence capability, but add explicit separation governance now.

The right strategy is:
- **No rewrite**
- **No pause in delivery**
- **Hard boundary enforcement + modular extraction in parallel**

This preserves current momentum while making the Reality Model genuinely independent and reusable, with AVRAI as a first-class host rather than the only viable runtime container.

