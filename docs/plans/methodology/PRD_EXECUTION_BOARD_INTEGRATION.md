# PRD + Execution Board Integration Guide

**Purpose:** Keep board execution synchronized with PRD requirements and eliminate drift.

## Required Metadata per Execution Milestone

- `milestone_id`: `M#-P#-#`
- `prd_ids`: one or more `PRD-###`
- `master_plan_refs`: one or more `X.Y.Z`
- `architecture_spot`: from `docs/plans/architecture/ARCHITECTURE_SPOTS_REGISTRY.csv`

Use template: `docs/agents/status/BOARD_PRD_MAPPING_TEMPLATE.csv`

## Required Metadata per Pull Request

Every PR must include in title/body:

- At least one `PRD-###`
- Exactly one `M#-P#-#`
- At least one `X.Y.Z`

CI enforcement:

- `.github/workflows/prd-traceability-guard.yml`
- `scripts/validate_pr_traceability.py`

## Workflow

1. Create/update execution-board milestone row with `M#-P#-#` ID and PRD IDs.
2. Implement code with Master Plan phase ownership.
3. Open PR containing `PRD-###` + one `M#-P#-#` + `X.Y.Z` tags.
4. Pass CI guards:
   - Execution Board Guard
   - PRD Traceability Guard
5. Move milestone to `Done` only when PR merged and acceptance criteria are met with evidence links.
