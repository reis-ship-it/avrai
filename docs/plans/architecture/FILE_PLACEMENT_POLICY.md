# File Placement Policy (Build-Enforced)

**Status:** Active rule  
**Effective Date:** February 15, 2026  
**Scope:** All tracked non-doc files under `lib/`, `packages/`, `native/`, `scripts/`, `supabase/`, `test/`, `tool/`, `assets/`, and platform directories.

## Rule

Every file must be placed in an explicit architecture spot.

- A file is valid only if it maps to:
  1. a row in `docs/plans/architecture/generated/codebase_master_plan_mapping_2026-02-15.csv`, and
  2. a registered spot in `docs/plans/architecture/ARCHITECTURE_SPOTS_REGISTRY.csv`.
- If a file does not fit an existing spot, **create a new spot** in `ARCHITECTURE_SPOTS_REGISTRY.csv` before merge.
- No unresolved dispositions are allowed in build validation (`review_required`, `delete_candidate`).

## Required Update Flow for New Files

1. Place the file in the most accurate architecture directory.
2. Run:
   - `python3 scripts/generate_master_plan_file_mapping.py`
   - `python3 scripts/generate_architecture_spots_registry.py`
   - `python3 scripts/validate_architecture_placement.py`
3. If validation fails with “unregistered architecture spot”:
   - add the new spot row in `ARCHITECTURE_SPOTS_REGISTRY.csv` (or move file to an existing spot),
   - regenerate artifacts,
   - commit both code and mapping updates.
4. Ensure CI `Architecture Placement Guard` passes.

## Build Guard

The CI workflow runs the validator and fails if:

- any tracked file is missing from mapping CSV,
- any file has forbidden unresolved disposition,
- any file maps to an unregistered spot,
- generated artifacts are stale vs repository state.

## Governance References

- `docs/MASTER_PLAN.md`
- `docs/plans/architecture/ARCHITECTURE_INDEX.md`
- `docs/plans/architecture/ARCHITECTURE_DOCS_ALIGNMENT_2026-02-15.md`
- `scripts/validate_architecture_placement.py`
