# M31-P10-3 Baseline: Admin Command Center Wave 31 Oversight Cockpit + AI2AI Mesh Health + Temporal Replay

Date: 2026-03-31
Milestone: M31-P10-3
Master Plan refs: 10.9.22, 10.9.23, 10.9.24, 10.9.25

## Scope

Deliver the wave-31 admin command-center package as an operator cockpit rather than a route index. Extend the command center with a shared needs-attention queue, bounded top-level actions, kernel and sandbox-research visibility, and context-carrying deep links into launch safety, AI2AI, URK, research, and reality oversight surfaces.

## Deliverables

1. Command center baseline:
   - `docs/plans/methodology/M31_P10_3_ADMIN_COMMAND_CENTER_WAVE31_OVERSIGHT_COCKPIT_AI2AI_MESH_TEMPORAL_REPLAY_BASELINE.md`
2. Command center controls:
   - `configs/runtime/admin_command_center_wave31_oversight_cockpit_ai2ai_mesh_temporal_replay_controls.json`
3. Command center report package:
   - `docs/plans/methodology/MASTER_PLAN_ADMIN_COMMAND_CENTER_WAVE31_OVERSIGHT_COCKPIT_AI2AI_MESH_TEMPORAL_REPLAY_REPORT.json`
   - `docs/plans/methodology/MASTER_PLAN_ADMIN_COMMAND_CENTER_WAVE31_OVERSIGHT_COCKPIT_AI2AI_MESH_TEMPORAL_REPLAY_REPORT.md`

## Guardrails

1. Admin surfaces expose agent identity only; user PII remains redacted.
2. Top-level command-center actions remain bounded and policy-safe.
3. Deep links carry operator context, but they do not bypass page-level or runtime-level governance.
4. Needs-attention synthesis must reuse runtime-backed state rather than page-local heuristics scattered across multiple surfaces.

## Exit Criteria

1. Command center exposes the oversight cockpit, replay/mesh/kernel/research cards, needs-attention queue, bounded actions, and direct-lane deep links.
2. Route helpers and destination pages support carried focus/attention context.
3. Board evidence row is updated and milestone is closed.
4. Analyze, widget-test, board-sync, URK quality, and legacy-name checks pass.
