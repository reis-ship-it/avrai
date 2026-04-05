# Refactor Fast-Lane Playbook (3-Prong Target Structure)

**Date:** February 27, 2026  
**Status:** Active  
**Purpose:** Make refactors easy and safe while converging to `apps -> runtime -> engine -> shared`.

---

## 1. Move Pattern (Use This Every Time)

1. Pick one bounded slice (one feature, one service family, or one endpoint flow).
2. Move contracts first (`shared`), then implementation (`engine`/`runtime`), then app adapters (`apps`).
3. Keep temporary shim imports for one release window max.
4. Add tests for old path and new path during shim period.
5. Remove shim and close milestone evidence.

---

## 2. Standard Refactor Slice Types

1. **UI slice:** `lib/presentation/*` -> `apps/avrai_app/lib/presentation/*`
2. **Runtime slice:** `lib/core/controllers|services/device|services/network|services/security` -> `runtime/avrai_runtime_os/lib/services/*`
3. **Engine slice:** `lib/core/ai|services/quantum|services/matching|services/recommendations` -> `engine/reality_engine/lib/models/*`
4. **Shared contracts slice:** `lib/core/models|constants|utils` -> `shared/avrai_core/lib/*`

---

## 3. Shim Template (Temporary)

Use temporary forwarding files to keep compile stability:

1. Old path file becomes a thin wrapper that delegates to the new path.
2. Add both markers:
   - `MIGRATION_SHIM: M10-P10-6 REMOVE_BY:<milestone>`
   - `TODO(remove): milestone-id`
3. Add a unit test proving wrapper parity and mark deletion criteria.

---

## 4. Required Checks Per Slice

1. `python3 scripts/validate_architecture_placement.py`
2. `python3 scripts/ci/check_three_prong_boundaries.py`
3. `python3 scripts/ci/check_legacy_path_guard.py --base-ref main`
4. runtime capability contract check when runtime files change:
   - `python3 scripts/ci/check_runtime_capability_contracts.py`
5. relevant unit/integration tests for moved module.

---

## 5. PR Checklist (Copy/Paste)

1. Milestone ID: `M10-P10-4` / `M10-P10-5` / `M10-P10-6` (as applicable)
2. Master Plan refs: `10.10.9` / `10.10.10` / `10.10.11`
3. Old path(s):
4. New path(s):
5. Shim added? (Y/N, with removal milestone)
6. Boundary checks passed? (Y/N)
7. Mapping artifacts regenerated? (Y/N)
8. Diagram update required? (Y/N, link if yes)

---

## 6. Anti-Patterns (Do Not Do)

1. Add new business logic to legacy `lib/core/*` without migration-shim note.
2. Add direct app -> engine imports.
3. Mix transport/policy logic into app widgets/pages.
4. Keep shims indefinitely past one release window.
