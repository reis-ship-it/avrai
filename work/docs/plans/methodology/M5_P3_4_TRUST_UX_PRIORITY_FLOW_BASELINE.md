# M5-P3-4 Trust UX v1 Priority Flow Baseline

## Objective
Instrument and track Trust UX coverage so priority high-impact surfaces expose confidence, provenance, and last-validated timestamp.

## Baseline Artifacts
- Trust UX flow contract: `configs/runtime/trust_ux_priority_flows.json`
- Trust UX report generator/check: `scripts/runtime/generate_trust_ux_priority_flow_report.py`
- Trust UX report JSON: `docs/plans/methodology/MASTER_PLAN_3_PRONG_TRUST_UX_PRIORITY_FLOW_REPORT.json`
- Trust UX report Markdown: `docs/plans/methodology/MASTER_PLAN_3_PRONG_TRUST_UX_PRIORITY_FLOW_REPORT.md`

## Pass Contract
1. Contract format valid (`version = v1`, required fields declared).
2. Each priority flow requires all three disclosure fields:
   - `confidence_score`
   - `provenance_ref`
   - `last_validated_at`
3. At least one priority flow is in `implemented` state.
4. Report `verdict` is `PASS`.

## CI Wiring
- `Execution Board Guard` runs trust UX report check in `--check` mode.
- `3-Prong Reviews Automation` regenerates trust UX report artifacts.

This baseline moves M5-P3-4 into active implementation with deterministic coverage reporting.
