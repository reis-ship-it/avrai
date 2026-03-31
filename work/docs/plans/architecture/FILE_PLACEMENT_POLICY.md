# File Placement Policy (Build-Enforced)

**Status:** Active rule  
**Effective Date:** February 15, 2026  
**Scope:** All tracked files in the build-enforced placement scope under `apps/`, `runtime/`, `engine/`, `shared/`, `work/scripts/`, `work/tools/`, and `work/supabase/`.

Human-facing command aliases such as `scripts/`, `docs/`, and `configs/` remain valid because they are repository symlinks into `work/`, but the underlying tracked roots remain the `work/*` paths listed above for tooling.

## Rule

Every file must be placed in an explicit architecture spot.

Default target placement direction for all new code:

1. `apps/*` -> product surfaces and UI workflows.
2. `runtime/*` -> endpoint handling, AI2AI/BLE transport, orchestration, security, policy, privacy.
3. `engine/*` -> model-truth logic (state/prediction/planning/learning).
4. `shared/*` -> contracts, schemas, primitives.
5. Import direction must converge to `apps -> runtime -> engine -> shared`.

- A file is valid only if it maps to:
  1. a deterministic mapping row produced on demand by `scripts/generate_master_plan_file_mapping.py` / `scripts/validate_architecture_placement.py`, and
  2. a registered spot in `docs/plans/architecture/ARCHITECTURE_SPOTS_REGISTRY.csv`.
- Every mapping row must include a strict per-file dependency payload in `dependency_graph`:
  - valid JSON with `graph_version=v1`
  - deterministic `node_id=file:<path>`
  - explicit `order` and `depends_on` entries for move/refactor sequencing
  - explicit `injections` block (`mode`, `roots`, `provides`, `consumes`, `required_validation`) so DI impacts are tracked per file
- If a file does not fit an existing spot, **create a new spot** in `ARCHITECTURE_SPOTS_REGISTRY.csv` before merge.
- No unresolved dispositions are allowed in build validation (`review_required`, `delete_candidate`).
- `keep_review` remains valid for tracked tooling or legacy package surfaces that are intentionally retained but still need explicit human review over time.

Runtime transport canonicalization note:
- AI2AI transport implementation files must be placed under:
  - `runtime/avrai_runtime_os/lib/services/transport/ble/`
  - `runtime/avrai_runtime_os/lib/services/transport/mesh/`
  - `runtime/avrai_runtime_os/lib/services/transport/compatibility/`
- New transport logic must not be added under `lib/core/ai2ai/resilience/` or `lib/core/ai2ai/routing/`.
- `lib/core/ai2ai/resilience/` and `lib/core/ai2ai/routing/` are strict blocked legacy roots: they may remain referenced by historical docs/board aliases, but they are not active placement targets for new code.

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

## Build Execution Runbook (Modify / New / Delete)

Every build change must start from Master Plan ownership and end in validated file placement artifacts.

### 1) Modify Existing File

1. Confirm target phase/subsection in `docs/MASTER_PLAN.md`.
2. Link the work to an execution milestone (`M#-P#-#`) in `docs/EXECUTION_BOARD.csv`.
3. Modify file in-place if architecture spot remains correct.
4. Regenerate + validate:
   - `python3 scripts/generate_master_plan_file_mapping.py`
   - `python3 scripts/generate_architecture_spots_registry.py`
   - `python3 scripts/validate_architecture_placement.py`
5. Merge only when dependency graph + placement checks are green.

### 2) Build From Scratch (New File)

1. Confirm Master Plan ownership (`X.Y.Z`) and milestone mapping.
2. Add file in the correct architecture spot path.
3. If spot is new, register it in `docs/plans/architecture/ARCHITECTURE_SPOTS_REGISTRY.csv`.
4. Regenerate + validate mapping artifacts (same commands as above).
5. Ensure `dependency_graph` is generated for the new row and CI passes.

### 3) Delete File

1. Confirm deletion is allowed by current phase plan and milestone scope.
2. Verify runtime/test/DI dependencies before deletion (`rg`, DI registrations, imports, tests).
3. Delete file and regenerate mapping + spots artifacts.
4. Validate no forbidden unresolved states remain and placement guard passes.
5. Record deletion evidence in PR notes/milestone evidence fields.

### Non-Negotiable Rule

No file lifecycle change (`modify`, `new`, `delete`) can merge without:
- Master Plan subsection linkage (`X.Y.Z`)
- execution milestone linkage (`M#-P#-#`)
- fresh mapping artifacts with valid per-file `dependency_graph` payloads
- passing architecture placement validation

## Build Guard

The CI workflow runs the validator and fails if:

- any tracked file is missing from mapping CSV,
- any file has forbidden unresolved disposition,
- any file has missing/invalid `dependency_graph` metadata,
- any `refactor_planned` row lacks explicit dependency ordering (`order > 0` + non-empty `depends_on`),
- any file maps to an unregistered spot,
- generated artifacts are stale vs repository state.

## Governance References

- `docs/MASTER_PLAN.md`
- `docs/plans/architecture/ARCHITECTURE_INDEX.md`
- `docs/plans/architecture/ARCHITECTURE_DOCS_ALIGNMENT_2026-02-15.md`
- `scripts/validate_architecture_placement.py`
