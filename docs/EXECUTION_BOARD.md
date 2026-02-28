# Execution Board (Phase 1-N)

Purpose: lightweight execution tracking without Jira/Linear, stored in git.

Scope: tracks all current Master Plan phases (`1-11`) and is forward-compatible with future phases (`N+1`, `N+2`, ...).

Source references:
- `docs/MASTER_PLAN.md` (Phase definitions)
- `docs/MASTER_PLAN.md` section `10.9A-10.9I` (governance, milestones, risk)

Last updated: 2026-02-28

## Usage

1. Edit `docs/EXECUTION_BOARD.csv` as the source of truth.
2. Run `dart run tool/update_execution_board.dart` to sync this board.
3. Run `dart run tool/update_three_prong_reviews.dart` to refresh 3-prong weekly/final review artifacts.
4. For milestone rows, always maintain `prd_ids`, `master_plan_refs`, `architecture_spot`, `change_type`, and `reopens_milestone`.
5. Keep evidence links (PRs, test reports, docs) in CSV `evidence`.
6. Copy weekly summary into `docs/STATUS_WEEKLY.md`.
7. Use `dart run tool/update_execution_board.dart --check` and `dart run tool/update_three_prong_reviews.dart --check` before merge.

## AI Execution Loop (Required)

1. Select exactly one `Ready` milestone ID from this board.
2. Select the next subsection(s) (`X.Y.Z`) from `docs/MASTER_PLAN.md` that implement that milestone scope.
3. Implement only that scoped unit; do not start a second milestone in the same PR.
4. Run local guards before each commit and before PR update:
   - `dart run tool/update_execution_board.dart --check`
   - `dart run tool/update_three_prong_reviews.dart --check`
   - `python3 scripts/validate_architecture_placement.py`
   - `python3 scripts/validate_rename_candidates.py`
   - `python3 scripts/validate_pr_traceability.py --title "PRD-123 M1-P7-1 <summary>" --body "Refs: 7.4.2" --require-execution-id --require-single-milestone --require-master-plan-ref`
5. Commit in small checkpoints where each non-merge commit message includes:
   - the same milestone ID (`M#-P#-#`)
   - at least one subsection reference (`X.Y.Z`)
6. Open PR with:
   - `PRD-###`
   - exactly one milestone ID (`M#-P#-#`) in PR title
   - subsection references (`X.Y.Z`)
7. For phase work, use section automation + completion flow:
   - sync phase root with main: `scripts/phase_root_sync.sh --phase P# --push`
   - start section branch: `scripts/phase_section_start.sh --phase P# --section X.Y.Z`
   - complete subsection work: `scripts/phase_subsection_complete.sh --phase P# --subsection X.Y.Z`
   - each completion opens PR back to the immediate parent branch (nested branches supported).
   - naming verification gate is required before auto-PR (`scripts/verify_phase_naming.sh`).
8. Move milestone status only after exit criteria and evidence are satisfied.

## Mandatory Rules (Wired To Master Plan Work)

1. All implementation work from `docs/MASTER_PLAN.md` must map to a milestone ID in `docs/EXECUTION_BOARD.csv`.
2. Every PR touching plan-scoped code/docs must reference exactly one milestone ID (e.g., `M1-P7-1`) in PR title.
3. Every non-merge commit in that PR must include the same milestone ID and at least one master plan subsection reference (`X.Y.Z`).
4. No milestone can move to `Done` without evidence links (tests, analysis, or docs).
5. A phase cannot be marked `Done` while any dependency milestone for that phase is `Blocked`.
6. Master Plan phase additions require same-turn board expansion:
phase row + milestone row(s) + risk + gate criteria.
7. Every milestone row must include:
`prd_ids` (one or more `PRD-###`), `master_plan_refs` (one or more `X.Y.Z`), `architecture_spot` (registered spot key), `change_type` (`baseline` or `reopen`), and `reopens_milestone`.
8. A phase marked `Ready` must have at least one milestone in `Ready`, `In Progress`, or `Done`.
9. Reopen events must use a NEW milestone ID (`change_type=reopen`) that points to a prior `Done` milestone via `reopens_milestone`; never reopen by mutating an existing `Done` row.
10. Reopen events must be recorded in:
- `docs/EXECUTION_BOARD.csv` (milestone row metadata)
- `docs/STATUS_WEEKLY.md` (`1B) Reopen-By-New-Milestone Events`)
- `docs/agents/status/status_tracker.md` (program-level context note)
11. The checker command must pass before merge:
`dart run tool/update_execution_board.dart --check`

## Status Legend

- `Backlog`: Defined but not ready to start.
- `Ready`: Dependencies satisfied; can start.
- `In Progress`: Actively being worked.
- `Blocked`: Waiting on dependency/decision/fix.
- `Done`: Exit criteria met.

## Priority Legend

- `Critical`: 20-25 risk score
- `High`: 12-19 risk score
- `Medium`: 6-11 risk score
- `Low`: 1-5 risk score

## Phase Portfolio

<!-- EXECUTION_BOARD:PHASE_PORTFOLIO_START -->
| Phase | Name | Governance Tier | R (Owner) | A (Accountable) | Risk | Priority | Status | Gate |
|------|------|------------------|-----------|------------------|------|----------|--------|------|
| 1 | Outcome Data & Episodic Memory Infrastructure | Hybrid | AP, MLE | AP | 12 | High | Ready | Data integrity + schema/backfill validation green |
| 2 | Privacy Compliance & Legal Infrastructure | Full | SEC | GOV | 20 | Critical | Ready | Security controls + compliance tests + key-rotation drill pass |
| 3 | World Model State & Action Encoders + List Quantum Entity | Hybrid | AP, MLE | AP | 12 | High | Backlog | Feature freshness + consistency checks pass |
| 4 | Energy Function & Formula Replacement | Full | MLE | AP | 20 | Critical | Backlog | Asymmetric-loss regression and safety guardrails pass |
| 5 | Transition Predictor & On-Device Training | Full | MLE | AP | 20 | Critical | Backlog | Drift/error bounds + uncertainty calibration pass |
| 6 | MPC Planner & Autonomous Agent | Full | AP, MLE | AP | 20 | Critical | Backlog | Guardrail constraints + planner rollback drills pass |
| 7 | Orchestrator Restructuring & System Integration | Full | AP, MOB | REL | 25 | Critical | Ready | Trigger reliability + orchestration persistence gates pass |
| 8 | Ecosystem Intelligence AI2AI World Model | Full | FED, LOC | AP | 20 | Critical | Backlog | Federated cohort no-regression + advisory quarantine pass |
| 9 | Business Operations & Monetization | Hybrid | Business Platform, AP | GOV | 12 | High | Backlog | Data-sharing consent + revenue attribution integrity pass |
| 10 | Feature Completion Codebase Reorganization & Polish | Hybrid | AP, REL | GOV | 16 | High | Ready | Placeholder elimination + reorg import/CI stability pass |
| 11 | Industry Integrations & Platform Expansion | Hybrid | Integrations Platform | GOV | 15 | High | Backlog | Integration contract/security conformance pass |
<!-- EXECUTION_BOARD:PHASE_PORTFOLIO_END -->

## Milestone Board

<!-- EXECUTION_BOARD:MILESTONE_BOARD_START -->
| Milestone | Phase | Wave | Scope | Change Type | Reopens | PRD IDs | Master Plan Refs | Architecture Spot | R | A | Dependencies | Risk | Priority | Target Window | Status | Evidence |
|----------|-------|------|-------|------------|---------|---------|------------------|-------------------|---|---|--------------|------|----------|---------------|--------|----------|
| M0-P10-1 | 10 | 0 | Production readiness + cleanup enforcement | baseline | none | PRD-012, PRD-013, PRD-014, PRD-030, PRD-031, PRD-032, PRD-033, PRD-034 | 10.9.1, 10.9.2, 10.9.4 | lib/_root | AP, REL | GOV | none | 16 | High | parallel baseline | Ready | - |
| M0-P10-2 | 10 | 0 | Reality Engine/Runtime OS/App remap docs + boundary policy package | baseline | none | PRD-030, PRD-031, PRD-032, PRD-033, PRD-034 | 10.8.1, 10.8.3, 10.10.1, 10.10.7 | docs/plans/architecture | AP, REL | GOV | M0-P10-1 | 12 | High | parallel baseline | Done | https://github.com/AVRA-CADAVRA/avrai/pull/172 |
| M0-P10-3 | 10 | 0 | 3-prong split-pass wiring + CI guard/contracts hardening | baseline | none | PRD-030, PRD-031, PRD-032, PRD-033, PRD-034 | 10.10.1, 10.10.2, 10.10.3, 10.10.4, 10.10.5, 10.10.6, 10.10.8 | lib/_root | AP, REL | GOV | M0-P10-2 | 16 | High | parallel baseline | In Progress | https://github.com/AVRA-CADAVRA/avrai/pull/173 |
| M0-P2-1 | 2 | 0 | Security + cryptographic assurance baseline | baseline | none | PRD-020, PRD-021, PRD-022, PRD-033, PRD-034 | 2.1.1, 2.2.1, 2.5.1 | lib/core/services/security | SEC | GOV | none | 20 | Critical | parallel baseline | Done | docs/plans/methodology/M0_P2_1_SECURITY_CRYPTOGRAPHIC_ASSURANCE_BASELINE.md, configs/runtime/security_cryptographic_assurance_controls.json, scripts/runtime/generate_security_cryptographic_assurance_report.py, docs/plans/methodology/MASTER_PLAN_SECURITY_CRYPTOGRAPHIC_ASSURANCE_REPORT.json, docs/plans/methodology/MASTER_PLAN_SECURITY_CRYPTOGRAPHIC_ASSURANCE_REPORT.md, lib/core/services/security/security_cryptographic_assurance_contract.dart, test/unit/services/security_cryptographic_assurance_contract_test.dart |
| M1-P7-1 | 7 | 1 | Trigger + orchestration persistence hardening | baseline | none | PRD-021, PRD-022, PRD-033, PRD-034 | 7.4.2, 10.9.1, 10.9.4 | lib/core/controllers | AP, MOB | REL | none | 25 | Critical | Week 1-2 | Done | docs/plans/methodology/M1_P7_1_TRIGGER_ORCHESTRATION_PERSISTENCE_BASELINE.md, configs/runtime/trigger_orchestration_persistence_hardening_controls.json, scripts/runtime/generate_trigger_orchestration_persistence_report.py, docs/plans/methodology/MASTER_PLAN_TRIGGER_ORCHESTRATION_PERSISTENCE_REPORT.json, docs/plans/methodology/MASTER_PLAN_TRIGGER_ORCHESTRATION_PERSISTENCE_REPORT.md, lib/core/controllers/trigger_orchestration_persistence_contract.dart, test/unit/controllers/trigger_orchestration_persistence_contract_test.dart |
| M1-P7-2 | 7 | 1 | Controller/orchestrator integration reliability | baseline | none | PRD-021, PRD-022, PRD-033, PRD-034 | 7.4.3, 7.4.4, 10.9.4 | lib/core/controllers | AP | REL | M1-P7-1 | 20 | Critical | Week 2-3 | Backlog | - |
| M1-P8-1 | 8 | 1 | Federated cohort gating + canary/shadow pipeline | baseline | none | PRD-021, PRD-022, PRD-033, PRD-034 | 8.1.3, 8.1.4, 8.1.5 | lib/core/ai2ai | FED, MLE | AP | M1-P7-1 | 20 | Critical | Week 3-4 | Backlog | - |
| M1-P8-2 | 8 | 1 | Advisory quarantine + rollback independence | baseline | none | PRD-021, PRD-022, PRD-033, PRD-034 | 8.9.2, 8.9.4, 8.9.5 | lib/core/services/locality_agents | LOC | AP | M1-P8-1 | 16 | High | Week 4-5 | Backlog | - |
| M2-P1-1 | 1 | 2 | Memory reliability gates | baseline | none | PRD-001, PRD-002, PRD-010, PRD-011, PRD-033, PRD-034 | 1.1.1, 1.2.12, 1.3.1 | lib/core/ai | AP, MLE | AP | none | 12 | High | Week 5-6 | Done | docs/plans/methodology/M2_P1_1_MEMORY_RELIABILITY_GATES_BASELINE.md, configs/runtime/memory_reliability_gates.json, scripts/runtime/generate_memory_reliability_gates_report.py, docs/plans/methodology/MASTER_PLAN_MEMORY_RELIABILITY_GATES_REPORT.json, docs/plans/methodology/MASTER_PLAN_MEMORY_RELIABILITY_GATES_REPORT.md, lib/core/ai/memory/memory_reliability_contract.dart, test/unit/ai/memory_reliability_contract_test.dart |
| M2-P3-1 | 3 | 2 | State encoder consistency/freshness controls | baseline | none | PRD-010, PRD-011, PRD-033, PRD-034 | 3.1.1, 3.1.4, 3.2.1 | lib/core/models | AP, MLE | AP | M2-P1-1 | 12 | High | Week 6-7 | Backlog | - |
| M2-P4-1 | 4 | 2 | Energy function safety and regression governance | baseline | none | PRD-021, PRD-022, PRD-033, PRD-034 | 4.1.3, 4.1.7, 4.5.7 | lib/core/ml | MLE | AP | M2-P3-1 | 20 | Critical | Week 7-8 | Backlog | - |
| M2-P5-1 | 5 | 2 | Transition predictor drift/calibration controls | baseline | none | PRD-021, PRD-022, PRD-033, PRD-034 | 5.1.3, 5.1.9, 5.2.1 | lib/core/ml | MLE | AP | M2-P4-1 | 20 | Critical | Week 8-9 | Backlog | - |
| M2-P6-1 | 6 | 2 | Planner guardrail and rollback-hardening | baseline | none | PRD-021, PRD-022, PRD-033, PRD-034 | 6.2.1, 6.2.9, 6.2.10 | lib/core/ai | AP, MLE | AP | M2-P5-1 | 20 | Critical | Week 9-10 | Backlog | - |
| M3-P11-1 | 11 | 3 | Integration governance + contract security gates | baseline | none | PRD-020, PRD-021, PRD-022, PRD-033, PRD-034 | 11.1.1, 11.2.1, 11.4.1 | lib/core/cloud | Integrations Platform | GOV | M3-P9-1 | 15 | High | Week 11-12 | Backlog | - |
| M3-P9-1 | 9 | 3 | Business data/consent governance hardening | baseline | none | PRD-020, PRD-021, PRD-022, PRD-033, PRD-034 | 9.2.6, 9.3.1, 9.3.3 | lib/core/services/business | Business Platform, AP | GOV | M2-P6-1 | 12 | High | Week 10-11 | Backlog | - |
| M4-P3-1 | 1 | 4 | 3-prong claim lifecycle schema + API contracts | baseline | none | PRD-010, PRD-011, PRD-033, PRD-034 | 1.1.1, 1.1.2, 7.7.1 | lib/core/ai | AP, MLE | AP | M2-P1-1 | 20 | Critical | Day 0-30 | Backlog | - |
| M4-P3-2 | 7 | 4 | Conviction gate shadow mode in serving runtime | baseline | none | PRD-021, PRD-022, PRD-033, PRD-034 | 6.2.21, 7.7.4, 7.7.3 | lib/core/controllers | AP, REL | REL | M4-P3-1 | 20 | Critical | Day 0-30 | Backlog | - |
| M4-P3-3 | 7 | 4 | Promotion contracts + mandatory eval suite automation | baseline | none | PRD-021, PRD-022, PRD-033, PRD-034 | 5.2.21, 7.7.3, 7.9.6 | lib/core/ml | MLE | AP | M4-P3-1 | 20 | Critical | Day 0-30 | Backlog | - |
| M5-P3-1 | 6 | 5 | High-impact conviction gate enforcement (production) | baseline | none | PRD-021, PRD-022, PRD-033, PRD-034 | 6.2.21, 6.2.22, 7.7.5 | lib/core/ai | AP, REL | REL | M4-P3-2 | 25 | Critical | Day 31-60 | Backlog | - |
| M5-P3-2 | 7 | 5 | Operational canary + rollback automation for conviction promotions | baseline | none | PRD-021, PRD-022, PRD-033, PRD-034 | 7.7.4, 7.7.5, 10.9.21 | lib/core/controllers | REL | REL | M5-P3-1 | 25 | Critical | Day 31-60 | Backlog | - |
| M5-P3-3 | 7 | 5 | Research replication queue + SLA instrumentation | baseline | none | PRD-021, PRD-022, PRD-033, PRD-034 | 1.4.14, 7.9.8, 7.9.10 | docs/plans/architecture | MLE | AP | M4-P3-3 | 15 | High | Day 31-60 | Backlog | - |
| M5-P3-4 | 10 | 5 | Trust UX v1: confidence + provenance surfaces on priority flows | baseline | none | PRD-012, PRD-013, PRD-014, PRD-033 | 1.4.13, 7.7.5, 10.9.9 | lib/presentation | Product, AP | Product | M5-P3-1 | 12 | High | Day 31-60 | Backlog | - |
| M6-P3-1 | 7 | 6 | Cross-domain self-healing automation + incident routing hardening | baseline | none | PRD-021, PRD-022, PRD-033, PRD-034 | 7.3.4, 8.1.1, 10.9.12 | lib/core/services | REL | REL | M5-P3-2 | 25 | Critical | Day 61-90 | Backlog | - |
| M6-P3-2 | 10 | 6 | Lineage explorer + \what changed\ transparency feed | baseline | none | PRD-012, PRD-013, PRD-014, PRD-033 | 7.7.5, 7.7.6, 10.9.9 | lib/presentation | Product, AP | Product | M5-P3-4 | 12 | High | Day 61-90 | Backlog | - |
| M6-P3-3 | 10 | 6 | Master-plan completion readiness audit + sign-off package | baseline | none | PRD-030, PRD-031, PRD-032, PRD-033, PRD-034 | 10.9.21, 10.10.8 | docs | AP, REL | GOV | M6-P3-1, M6-P3-2 | 20 | Critical | Day 61-90 | Backlog | - |
| M7-P7-3 | 7 | 7 | URK Stage A: TriggerService + PrivacyModePolicy + NoEgressGate contract freeze | baseline | none | PRD-021, PRD-022, PRD-033, PRD-034 | 7.4.2, 7.5.1, 7.7.5, 10.9.12 | lib/core/controllers | AP, REL | REL | M6-P3-3 | 20 | Critical | Week 13-14 | Done | docs/plans/methodology/M7_P7_3_URK_STAGE_A_TRIGGER_PRIVACY_NO_EGRESS_BASELINE.md, configs/runtime/urk_stage_a_trigger_privacy_no_egress_controls.json, scripts/runtime/generate_urk_stage_a_trigger_privacy_no_egress_report.py, docs/plans/methodology/MASTER_PLAN_URK_STAGE_A_TRIGGER_PRIVACY_NO_EGRESS_REPORT.json, docs/plans/methodology/MASTER_PLAN_URK_STAGE_A_TRIGGER_PRIVACY_NO_EGRESS_REPORT.md, lib/core/controllers/urk_stage_a_trigger_privacy_no_egress_contract.dart, test/unit/controllers/urk_stage_a_trigger_privacy_no_egress_contract_test.dart |
| M7-P7-4 | 7 | 7 | URK Stage B: Event Ops runtime shadow wiring (ingest-plan-gate-observe) | baseline | none | PRD-021, PRD-022, PRD-033, PRD-034 | 6.1.1, 6.2.1, 7.4.3, 7.7.5 | lib/core/controllers | AP, MOB | REL | M7-P7-3 | 20 | Critical | Week 14-15 | Done | docs/plans/methodology/M7_P7_4_URK_STAGE_B_EVENT_OPS_SHADOW_RUNTIME_BASELINE.md, configs/runtime/urk_stage_b_event_ops_shadow_runtime_controls.json, scripts/runtime/generate_urk_stage_b_event_ops_shadow_runtime_report.py, docs/plans/methodology/MASTER_PLAN_URK_STAGE_B_EVENT_OPS_SHADOW_RUNTIME_REPORT.json, docs/plans/methodology/MASTER_PLAN_URK_STAGE_B_EVENT_OPS_SHADOW_RUNTIME_REPORT.md, lib/core/controllers/urk_stage_b_event_ops_shadow_runtime_contract.dart, test/unit/controllers/urk_stage_b_event_ops_shadow_runtime_contract_test.dart |
| M7-P8-3 | 8 | 7 | URK Stage C prep: private-mesh policy conformance for Event Ops deltas | baseline | none | PRD-021, PRD-022, PRD-033, PRD-034 | 8.1.3, 8.1.4, 8.9.5, 10.9.12 | lib/core/ai2ai | FED, LOC | AP | M7-P7-4 | 20 | Critical | Week 15-16 | Done | docs/plans/methodology/M7_P8_3_URK_STAGE_C_PRIVATE_MESH_POLICY_CONFORMANCE_BASELINE.md, configs/runtime/urk_stage_c_private_mesh_policy_conformance_controls.json, scripts/runtime/generate_urk_stage_c_private_mesh_policy_conformance_report.py, docs/plans/methodology/MASTER_PLAN_URK_STAGE_C_PRIVATE_MESH_POLICY_CONFORMANCE_REPORT.json, docs/plans/methodology/MASTER_PLAN_URK_STAGE_C_PRIVATE_MESH_POLICY_CONFORMANCE_REPORT.md, lib/core/ai2ai/urk_stage_c_private_mesh_policy_conformance_contract.dart, test/unit/ai2ai/urk_stage_c_private_mesh_policy_conformance_contract_test.dart |
| M8-P9-2 | 9 | 8 | URK Stage D: Business runtime replication on shared URK contracts | baseline | none | PRD-020, PRD-021, PRD-022, PRD-033, PRD-034 | 7.7.5, 9.2.6, 9.3.1, 10.9.12 | lib/core/services/business | Business Platform, AP | GOV | M7-P8-3 | 12 | High | Week 16-17 | Done | docs/plans/methodology/M8_P9_2_URK_STAGE_D_BUSINESS_RUNTIME_REPLICATION_BASELINE.md, configs/runtime/urk_stage_d_business_runtime_replication_controls.json, scripts/runtime/generate_urk_stage_d_business_runtime_replication_report.py, docs/plans/methodology/MASTER_PLAN_URK_STAGE_D_BUSINESS_RUNTIME_REPLICATION_REPORT.json, docs/plans/methodology/MASTER_PLAN_URK_STAGE_D_BUSINESS_RUNTIME_REPLICATION_REPORT.md, lib/core/services/business/urk_stage_d_business_runtime_replication_contract.dart, test/unit/services/urk_stage_d_business_runtime_replication_contract_test.dart |
<!-- EXECUTION_BOARD:MILESTONE_BOARD_END -->

## Kanban Snapshot

<!-- EXECUTION_BOARD:KANBAN_START -->
### Backlog

`M1-P7-2`, `M1-P8-1`, `M1-P8-2`, `M2-P3-1`, `M2-P4-1`, `M2-P5-1`, `M2-P6-1`, `M3-P11-1`, `M3-P9-1`, `M4-P3-1`, `M4-P3-2`, `M4-P3-3`, `M5-P3-1`, `M5-P3-2`, `M5-P3-3`, `M5-P3-4`, `M6-P3-1`, `M6-P3-2`, `M6-P3-3`

### Ready

`M0-P10-1`

### In Progress

`M0-P10-3`

### Blocked

None

### Done

`M0-P10-2`, `M0-P2-1`, `M1-P7-1`, `M2-P1-1`, `M7-P7-3`, `M7-P7-4`, `M7-P8-3`, `M8-P9-2`
<!-- EXECUTION_BOARD:KANBAN_END -->

## Exit Criteria Checklist (Per Milestone)

- [ ] Scope implemented
- [ ] Tests green
- [ ] Monitoring/alerting updated (if applicable)
- [ ] Security/privacy checks complete (if applicable)
- [ ] Runbook/rollback path validated
- [ ] Evidence link added in board row

## Phase N+ Extension Rules

When new phases are added:

1. Add phase row to `Phase Portfolio`.
2. Add milestone IDs using `Mx-P<phase>-<seq>`.
3. Assign R/A and risk score.
4. Add gate criteria and dependencies.
5. Update CSV row set to match.
