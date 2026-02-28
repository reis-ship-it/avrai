# M6-P3-2 Lineage Transparency Feed Baseline

## Objective
Track coverage for priority recommendation flows so users/operators can inspect what changed and which claims influenced each high-impact output.

## Baseline Artifacts
- Lineage transparency flow contract: `configs/runtime/lineage_transparency_priority_flows.json`
- Lineage transparency report generator/check: `scripts/runtime/generate_lineage_transparency_priority_flow_report.py`
- Lineage transparency report JSON: `docs/plans/methodology/MASTER_PLAN_3_PRONG_LINEAGE_TRANSPARENCY_PRIORITY_FLOW_REPORT.json`
- Lineage transparency report Markdown: `docs/plans/methodology/MASTER_PLAN_3_PRONG_LINEAGE_TRANSPARENCY_PRIORITY_FLOW_REPORT.md`

## Pass Contract
1. Contract format is valid (`version = v1`, required fields declared).
2. Each priority flow requires all transparency fields:
   - `change_summary`
   - `lineage_ref`
   - `influencing_claims_count`
   - `last_changed_at`
3. At least one priority flow is in `implemented` state.
4. Report `verdict` is `PASS`.

## CI Wiring
- `Execution Board Guard` runs lineage transparency report check in `--check` mode.
- `3-Prong Reviews Automation` regenerates lineage transparency report artifacts.

This baseline moves M6-P3-2 into active implementation with deterministic transparency-feed coverage reporting.
