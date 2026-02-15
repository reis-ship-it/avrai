# File & Folder Rename Manifest (Phase 10)

**Date:** February 13, 2026  
**Status:** Active prep artifact (planning only, no implementation/scaffolding)  
**Master Plan Mapping:** Phase 10 (`10.10`)  
**Backlog Mapping:** `MPA-P10-E4-S1` to `MPA-P10-E4-S6`  
**Tracker Mapping:** `docs/MASTER_PLAN_TRACKER.md` (Phase-Specific Plans)

---

## Purpose

Define a single canonical source of truth for renaming code and test paths so structure aligns with the Master Plan architecture, ownership boundaries, and grouped test strategy.

---

## Canonical Target Taxonomy

Use this taxonomy for all rename decisions:

| Layer | Canonical Path Pattern | Notes |
|---|---|---|
| Domain contracts | `lib/domain/<bounded_context>/` | Stable business semantics only |
| Application orchestration | `lib/application/<bounded_context>/` | Use-case orchestration and workflows |
| Infrastructure/adapters | `lib/infrastructure/<capability>/` | SDK, storage, transport, external integrations |
| Shared core services | `lib/core/<capability>/` | Cross-domain reusable primitives |
| Presentation surfaces | `lib/presentation/<surface>/` | App and UI modules |
| Unit tests | `test/unit/<layer>/<bounded_context>/` | Layer + domain aligned |
| Integration tests | `test/integration/<bounded_context>/` | Domainized integration structure |
| Widget/design tests | `test/widget/<surface_or_design>/` | Includes `test/widget/design/` |
| Grouped suite scripts | `test/suites/` | Must reference canonical test paths only |

---

## Naming Standard

| Artifact | Rule | Example |
|---|---|---|
| Dart files | `snake_case.dart` | `payment_flow_service.dart` |
| Unit tests | `<subject>_test.dart` | `payment_flow_service_test.dart` |
| Integration tests | `<subject>_integration_test.dart` | `payment_flow_integration_test.dart` |
| Widget tests | `<subject>_widget_test.dart` | `event_card_widget_test.dart` |
| Golden tests | `<subject>_golden_test.dart` | `design_playground_golden_test.dart` |
| Ambiguous names | Disallow generic names unless scoped | Avoid `service.dart`, use `tax_service.dart` |

---

## Rename Manifest Schema (Required Fields)

Each rename row must include all fields below.

| Field | Description |
|---|---|
| `rename_id` | Stable ID: `REN-P10-<wave>-<seq>` |
| `old_path` | Current path in repository |
| `new_path` | Canonical target path |
| `artifact_type` | `working_code` or `test_code` or `suite_script` or `doc_ref` |
| `bounded_context` | `ai`, `payments`, `events`, `expertise`, etc. |
| `layer` | `domain`, `application`, `infrastructure`, `core`, `presentation`, `test` |
| `owner` | `ARC/AIC/APP/QAE/PMO/SEC/...` |
| `master_plan_ref` | Exact phase/task (example: `10.10.3`) |
| `backlog_ref` | Exact story ID (example: `MPA-P10-E4-S3`) |
| `tracker_ref` | Tracker row name for sync |
| `dependency_refs` | Related paths/docs/suites |
| `risk_level` | `low/medium/high` |
| `status` | `planned/in_progress/blocked/verified` |
| `verification` | Validation command/check (example: stale path scan) |
| `rollback_note` | Planned rollback method for rename |

---

## Rename Manifest Template

Copy this template for execution planning:

| rename_id | old_path | new_path | artifact_type | bounded_context | layer | owner | master_plan_ref | backlog_ref | tracker_ref | dependency_refs | risk_level | status | verification | rollback_note |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| REN-P10-A-001 | `lib/core/services/payment_flow.dart` | `lib/core/payments/payment_flow_service.dart` | `working_code` | `payments` | `core` | `ARC` | `10.10.3` | `MPA-P10-E4-S3` | `Phase 10 Canonical Rename Manifest` | `test/integration/payments/payment_flow_integration_test.dart` | medium | planned | `rg -n \"payment_flow.dart|payment_flow_service.dart\" lib test` | restore via manifest inverse map |
| REN-P10-A-002 | `test/integration/payment_flow_integration_test.dart` | `test/integration/payments/payment_flow_integration_test.dart` | `test_code` | `payments` | `test` | `QAE` | `10.10.3` | `MPA-P10-E4-S3` | `Phase 10 Canonical Rename Manifest` | `test/suites/payment_suite.sh` | medium | planned | `rg -n \"test/integration/payment_flow_integration_test.dart\" test/suites` | restore old path and suite refs from manifest |

---

## Conversion Model (Wave-Based)

Execute renames in waves so risk is isolated.

| Wave | Scope | Primary Owner | Exit Gate |
|---|---|---|---|
| Wave A | Taxonomy + naming dictionary + inventory freeze | `ARC + PMO` | Approved canonical map and freeze timestamp |
| Wave B | Test-first path normalization (`test/integration`, `test/widget`, `test/suites`) | `QAE` | 0 missing suite references |
| Wave C | Core/service and feature-module path renames by bounded context | `ARC + APP + AIC` | No stale imports for renamed domains |
| Wave D | Documentation/tracker/cursor-rules path updates | `PMO` | Tracker and docs path references synchronized |
| Wave E | Compatibility alias cleanup and final verification | `QAE + ARC` | Alias debt = 0; verification checks pass |

---

## Architecture Constraints

1. Do not rename across ownership boundaries without joint owner sign-off.
2. Rename tests and suite references in the same wave as source files.
3. Every rename must be traceable to Master Plan + backlog + tracker IDs.
4. Any temporary compatibility export must have expiration criteria and owner.
5. Phase 11-15 entry readiness depends on Phase 10 rename-contract freshness in tracker.

---

## Required Verification Checks

1. Stale path scan: no references to deprecated paths in `lib/`, `test/`, `docs/`.
2. Grouped suites integrity: 0 missing references from `test/suites/`.
3. Naming policy compliance scan: non-canonical filenames flagged.
4. Tracker sync: all active rename waves represented in `docs/MASTER_PLAN_TRACKER.md`.
5. Checklist sync: Phase 10/11+ gate references remain current.

---

## Definition Of Done (Prep Layer)

This prep artifact is complete when:

1. Canonical taxonomy and naming rules are approved and published.
2. Rename manifest template is adopted for all rename planning rows.
3. Backlog stories and tracker rows directly reference this document.
4. Phase gates include rename readiness checks tied to this manifest.
5. No implementation/scaffolding has been performed as part of this prep document.
