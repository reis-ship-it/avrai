# Target Codebase Structure Enforcement (Default for All New Work)

**Date:** February 27, 2026  
**Status:** Active enforcement policy  
**Purpose:** Ensure all new code and refactors converge toward the target AVRAI structure: `apps -> runtime -> engine -> shared`.

---

## 1. Default Placement Rule (Applies to All New Files)

1. App/UI/user workflows go in `apps/*`.
2. Runtime execution, endpoint handlers, transport (AI2AI/BLE/WiFi), identity, policy, privacy, security, and governance go in `runtime/avrai_runtime_os/*`.
3. Model truth logic (state/prediction/planning/learning math) goes in `engine/reality_engine/*`.
4. Shared schemas/primitives/enums/errors go in `shared/avrai_core/*`.

Non-negotiable import direction:
1. `apps/* -> runtime/* -> engine/* -> shared/*`
2. `apps/* -> shared/*` is allowed.
3. `runtime/* -> shared/*` is allowed.
4. `engine/* -> shared/*` is allowed.
5. Forbidden: `apps/* -> engine/*` direct imports.
6. Forbidden: `runtime/* -> apps/*` imports.
7. Forbidden: `engine/* -> runtime/*` or `engine/* -> apps/*` imports.

---

## 2. Placement Matrix for New Features

| Feature Type | Required Layer | Example Target |
|---|---|---|
| Page, widget, route, UX flow | `apps` | `apps/avrai_app/lib/presentation/...` |
| Admin/research visual dashboard | `apps` | `apps/avrai_admin_app/lib/pages/...` |
| Endpoint contract/handler (`ingest/plan/commit/...`) | `runtime` | `runtime/avrai_runtime_os/lib/endpoints/...` |
| AI2AI/BLE/WiFi transport | `runtime` | `runtime/avrai_runtime_os/lib/services/transport/...` |
| Policy/privacy/consent/conviction/no-egress | `runtime` | `runtime/avrai_runtime_os/lib/services/policy_kernel/...` |
| Orchestration/incident/recovery/lineage service | `runtime` | `runtime/avrai_runtime_os/lib/services/...` |
| State encoder, energy, predictor, MPC | `engine` | `engine/reality_engine/lib/models/...` |
| Memory tuple generation/learning signals | `engine` (with runtime writer adapter) | `engine/reality_engine/lib/memory/...` |
| Shared request/decision envelopes and enums | `shared` | `shared/avrai_core/lib/schemas/...` |

---

## 3. PR Checklist (Required)

Every architecture-impacting PR must include:

1. Master Plan refs (`10.10.9` and/or `10.10.10` when relevant).
2. Execution Board milestone mapping (`M10-P10-4` and/or `M10-P10-5`).
3. Updated architecture mapping artifacts if file placement changed.
4. Passing boundary checks:
   - `scripts/ci/check_three_prong_boundaries.py`
   - `scripts/ci/check_legacy_path_guard.py`
   - `scripts/validate_architecture_placement.py`
5. Diagram update when endpoint/prong flow changes:
   - `docs/plans/architecture/THREE_PRONG_ARCHITECTURE_VISUALIZATION_GUIDE_2026-02-27.md`

---

## 4. Immediate Build Behavior Policy

Effective immediately for all new work:

1. New folders should be created in target structure first (`apps/`, `runtime/`, `engine/`, `shared/`) and then referenced by adapters/shims from legacy paths as needed.
2. Do not add new business logic directly into legacy monolith paths (`lib/core/**`, `lib/domain/**`, `lib/presentation/**`) unless it is migration glue with a follow-up move ticket.
3. AI2AI/BLE additions must go runtime-side.
4. New model/planning logic must go engine-side.
5. New shared contracts must go shared-side.

Legacy-path exception process:

1. If a legacy-path edit is unavoidable for a migration slice, add a temporary shim marker in the file:
   - `MIGRATION_SHIM: M10-P10-6 REMOVE_BY:<milestone>`
2. If shim marker is not possible, add explicit temporary path exception in:
   - `configs/runtime/legacy_path_guard.json` -> `allowlisted_legacy_paths`
3. Remove shim/allowlist entry in the next migration window.

---

## 5. Authority Links

1. `docs/plans/architecture/IDEAL_CODEBASE_ARCHITECTURE_3_PRONGS.md`
2. `docs/plans/architecture/CODEBASE_MIGRATION_CHECKLIST_3_PRONG_2026-02-27.md`
3. `docs/plans/architecture/THREE_PRONG_ARCHITECTURE_VISUALIZATION_GUIDE_2026-02-27.md`
4. `docs/plans/architecture/MIGRATION_STATUS_RUNTIME_TRANSPORT_2026-02-28.md`
5. `docs/MASTER_PLAN.md` (Phase 10.10)
6. `docs/EXECUTION_BOARD.csv` (`M10-P10-4`, `M10-P10-5`)
7. `scripts/ci/check_legacy_path_guard.py`
8. `.github/workflows/legacy-path-guard.yml`
