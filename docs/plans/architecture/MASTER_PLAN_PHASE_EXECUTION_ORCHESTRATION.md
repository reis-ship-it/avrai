# Master Plan Phase Execution Orchestration

**Date:** February 15, 2026  
**Status:** Active prep artifact (automation-ready, no product scaffolding)  
**Machine Contract:** `docs/plans/master_plan_execution.yaml`  
**Validation Script:** `scripts/validate_master_plan_execution_refs.sh`  
**Dry-Run Script:** `scripts/phase_orchestration_dry_run.sh`

---

## Purpose

Define how Master Plan phase execution is automatically orchestrated with GitHub + Cursor while preserving architecture ordering, checklist gates, tracker synchronization, and UI/UX design contracts across app types.

---

## Orchestration Flow

1. Trigger phase run via GitHub Actions (`workflow_dispatch`) with `phase_id`.
2. Validate machine contract and referenced docs.
3. Resolve phase dependencies from `docs/plans/master_plan_execution.yaml`.
4. Generate dry-run execution summary (phase, deps, backlog scope, gate).
5. Block non-dry-run execution until branch protection + required checks are active.
6. Execute story builds in controlled PR flow (`story/*` branches) once enabled.

---

## Document Link Contract

The following references are mandatory in orchestration:

- `docs/MASTER_PLAN.md`
- `docs/MASTER_PLAN_TRACKER.md`
- `docs/plans/architecture/MASTER_PLAN_ARCHITECTURE_EXECUTION_BACKLOG.md`
- `docs/plans/architecture/MASTER_PLAN_ARCHITECTURE_IMPLEMENTATION_CHECKLIST.md`
- `docs/plans/architecture/ARCHITECTURE_INDEX.md`
- `docs/plans/architecture/MASTER_PLAN_MULTI_APP_ARCHITECTURE_BLUEPRINT.md`
- `docs/plans/architecture/IDENTITY_UNLINKABILITY_AND_ACCESS_GOVERNANCE_CONTRACT.md`
- `docs/plans/architecture/REALITY_COHERENCE_TEST_MATRIX.md`
- `docs/plans/architecture/TEST_SUITE_PATH_NORMALIZATION_MAP_PHASE10.md`
- `docs/plans/architecture/FILE_FOLDER_RENAME_MANIFEST_PHASE10.md`
- `docs/design/DESIGN_REF.md`
- `docs/design/DESIGN_SYSTEM_ARCHITECTURE.md`
- `docs/design/MASTER_PLAN_DESIGN_LINKAGE.md`
- `docs/design/DESIGN_COVERAGE_MATRIX.md`
- `docs/design/ACCESSIBILITY_DESIGN_CONTRACT.md`
- `docs/design/SENSORY_FEEDBACK_GUIDELINES.md`
- `docs/design/README.md`
- `docs/design/apps/README.md`
- `docs/plans/methodology/DEVELOPMENT_METHODOLOGY.md`
- `docs/plans/methodology/SESSION_START_CHECKLIST.md`
- `docs/plans/methodology/START_HERE_NEW_TASK.md`
- `docs/plans/methodology/PHASE_SECTION_SUBSECTION_FORMAT.md`

Missing references fail orchestration validation.

Identity and access governance rule:
- Any phase touching identity, sharing, disclosure, admin, research, partner exports, or Supabase payload contracts must reference `docs/plans/architecture/IDENTITY_UNLINKABILITY_AND_ACCESS_GOVERNANCE_CONTRACT.md` in PR metadata and validation notes.

Reality coherence rule:
- Any phase touching cross-system behavior (learning, world/environment, transport, federation, offline/online arbitration, self-healing, or degraded/recovery UX) must map story scope to scenario IDs in `docs/plans/architecture/REALITY_COHERENCE_TEST_MATRIX.md` with evidence links.

---

## UI/UX Design Contract (All App Types)

Every phase story touching UI/UX must reference `docs/design/DESIGN_REF.md` (required entry point), `docs/design/DESIGN_SYSTEM_ARCHITECTURE.md`, and `docs/design/MASTER_PLAN_DESIGN_LINKAGE.md`, and indicate applicable app type(s):

- `consumer_app` -> `docs/design/apps/consumer_app/README.md`
- `business_app` -> `docs/design/apps/business_app/README.md`
- `admin_desktop_app` -> `docs/design/apps/admin_desktop_app/README.md`
- `research_portal` -> `docs/design/apps/research_portal/README.md`
- `partner_sdk_examples` -> `docs/design/apps/partner_sdk_examples/README.md`
- `api_caller_surface` -> maps to partner/API-facing contracts in `docs/design/apps/partner_sdk_examples/README.md`

Design-principles docs required for UI/UX scope:
- `docs/design/DESIGN_COVERAGE_MATRIX.md`
- `docs/design/ACCESSIBILITY_DESIGN_CONTRACT.md`
- `docs/design/SENSORY_FEEDBACK_GUIDELINES.md`

Working-methodology docs required for orchestration updates:
- `docs/plans/methodology/DEVELOPMENT_METHODOLOGY.md`
- `docs/plans/methodology/SESSION_START_CHECKLIST.md`
- `docs/plans/methodology/START_HERE_NEW_TASK.md`
- `docs/plans/methodology/PHASE_SECTION_SUBSECTION_FORMAT.md`

Design-linked stories are invalid if no design reference is present in PR metadata/checklist.

---

## GitHub Workflow Model

### Validation Workflow

File: `.github/workflows/master-plan-orchestration-validate.yml`

Responsibilities:
- Validate orchestration YAML path references.
- Validate phase IDs and required phase keys.
- Run on PR and manual dispatch.

### Trigger Workflow

File: `.github/workflows/master-plan-phase-trigger.yml`

Responsibilities:
- Trigger phase dry run for `phase_id`.
- Output dependency/order summary.
- Block non-dry-run execution in prep layer.

---

## Cursor Rule Integration

Cursor rules must enforce:

1. If phase orchestration artifacts change, tracker is updated in same task.
2. If UI/UX scope is touched, design contract doc reference is mandatory.
3. If Master Plan execution ordering changes, update orchestration YAML and re-run validation.

---

## Failure Handling Model

If orchestration validation fails:

1. Stop execution immediately (no phase progression).
2. Report missing/broken references and phase contract violations.
3. Create follow-up task/PR to repair contract before rerun.

If build checks fail during execution mode (future):

1. Block downstream dependent stories.
2. Mark story state as `blocked`.
3. Re-run from last green checkpoint after fix.

---

## Definition Of Done (Prep Layer)

1. Orchestration YAML exists and validates.
2. GitHub validation + trigger workflows are present.
3. Tracker/index include orchestration artifact references.
4. Cursor rules include orchestration and design reference enforcement.
5. No product implementation/scaffolding is performed as part of this artifact.
