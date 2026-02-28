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
