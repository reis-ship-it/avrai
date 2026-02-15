# PRD + Execution Board Integration Guide

**Purpose:** Keep board execution synchronized with PRD requirements and eliminate drift.

## Required Metadata per Board Card

- `card_id`: `CARD-<number>`
- `prd_ids`: one or more `PRD-###`
- `master_plan_refs`: one or more `X.Y` or `X.Y.Z`
- `architecture_spot`: from `docs/plans/architecture/ARCHITECTURE_SPOTS_REGISTRY.csv`

Use template: `docs/agents/status/BOARD_PRD_MAPPING_TEMPLATE.csv`

## Required Metadata per Pull Request

Every PR must include in title/body:

- At least one `PRD-###`
- At least one `CARD-<number>`

CI enforcement:

- `.github/workflows/prd-traceability-guard.yml`
- `scripts/validate_pr_traceability.py`

## Workflow

1. Create/update board card with `CARD-` ID and PRD IDs.
2. Implement code with Master Plan phase ownership.
3. Open PR containing `CARD-` + `PRD-` tags.
4. Pass CI guards:
   - Architecture Placement Guard
   - PRD Traceability Guard
5. Move card to done only when PR merged and acceptance criteria met.
