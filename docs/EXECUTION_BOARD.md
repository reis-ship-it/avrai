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
3. Run `python3 scripts/validate_execution_board_urk_quality.py` to enforce URK lane quality.
4. Run `dart run tool/update_three_prong_reviews.dart` to refresh 3-prong weekly/final review artifacts.
5. For milestone rows, always maintain `prd_ids`, `master_plan_refs`, `architecture_spot`, `change_type`, `reopens_milestone`, `urk_runtime_type`, `urk_prong`, `privacy_mode_impact`, and `impact_tier_max`.
6. Keep evidence links (PRs, test reports, docs) in CSV `evidence`.
7. Copy weekly summary into `docs/STATUS_WEEKLY.md`.
8. Use `dart run tool/update_execution_board.dart --check`, `python3 scripts/validate_execution_board_urk_quality.py`, and `dart run tool/update_three_prong_reviews.dart --check` before merge.

## 3-Prong Concurrent Execution Policy

For any milestone that is scoped to one primary prong, align implementation and evidence with the canonical prong plans:

1. Umbrella authority: `docs/plans/architecture/MASTER_PLAN_3_PRONG_TARGET_END_STATE.md`
2. Apps prong: `docs/plans/architecture/PRONG_APPS_CONCURRENT_EXECUTION_PLAN_2026-02-28.md`
3. Runtime OS prong: `docs/plans/architecture/PRONG_RUNTIME_OS_CONCURRENT_EXECUTION_PLAN_2026-02-28.md`
4. Reality Model prong: `docs/plans/architecture/PRONG_REALITY_MODEL_CONCURRENT_EXECUTION_PLAN_2026-02-28.md`

Milestones that touch multiple prongs must land shared-contract compatibility evidence before cross-prong behavior changes.

## AI Execution Loop (Required)

1. Select exactly one `Ready` milestone ID from this board.
2. Select the next subsection(s) (`X.Y.Z`) from `docs/MASTER_PLAN.md` that implement that milestone scope.
3. Implement only that scoped unit; do not start a second milestone in the same PR.
4. Run local guards before each commit and before PR update:
   - `dart run tool/update_execution_board.dart --check`
   - `dart run tool/update_three_prong_reviews.dart --check`
   - `python3 scripts/validate_architecture_placement.py`
   - `python3 scripts/validate_rename_candidates.py`
   - `python3 scripts/validate_pr_traceability.py --title "PRD-123 M1-P7-1 <summary>" --body "Refs: 7.4.2 URK-RUNTIME:shared URK-PRONG:cross_prong URK-MODE:multi_mode URK-IMPACT:L2" --require-execution-id --require-single-milestone --require-master-plan-ref --require-urk-tags`
   - `python3 scripts/validate_execution_board_urk_quality.py`
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
`prd_ids` (one or more `PRD-###`), `master_plan_refs` (one or more `X.Y.Z`), `architecture_spot` (registered spot key), `change_type` (`baseline` or `reopen`), `reopens_milestone`, `urk_runtime_type`, `urk_prong`, `privacy_mode_impact`, and `impact_tier_max`.
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
| Milestone | Phase | Wave | Scope | Change Type | Reopens | URK Runtime | URK Prong | Mode Impact | Impact Tier | PRD IDs | Master Plan Refs | Architecture Spot | R | A | Dependencies | Risk | Priority | Target Window | Status | Evidence |
|----------|-------|------|-------|------------|---------|-------------|-----------|-------------|-------------|---------|------------------|-------------------|---|---|--------------|------|----------|---------------|--------|----------|
| M0-P10-1 | 10 | 0 | Production readiness + cleanup enforcement | baseline | none | shared | cross_prong | multi_mode | L2 | PRD-012, PRD-013, PRD-014, PRD-030, PRD-031, PRD-032, PRD-033, PRD-034 | 10.9.1, 10.9.2, 10.9.4 | lib/_root | AP, REL | GOV | none | 16 | High | parallel baseline | Done | docs/plans/methodology/M0_P10_1_PRODUCTION_READINESS_CLEANUP_BASELINE.md, configs/runtime/production_readiness_cleanup_enforcement_controls.json, scripts/runtime/generate_production_readiness_cleanup_report.py, docs/plans/methodology/MASTER_PLAN_PRODUCTION_READINESS_CLEANUP_REPORT.json, docs/plans/methodology/MASTER_PLAN_PRODUCTION_READINESS_CLEANUP_REPORT.md |
| M0-P10-2 | 10 | 0 | Reality Engine/Runtime OS/App remap docs + boundary policy package | baseline | none | shared | cross_prong | multi_mode | L2 | PRD-030, PRD-031, PRD-032, PRD-033, PRD-034 | 10.8.1, 10.8.3, 10.10.1, 10.10.7 | docs/plans/architecture | AP, REL | GOV | M0-P10-1 | 12 | High | parallel baseline | Done | https://github.com/AVRA-CADAVRA/avrai/pull/172 |
| M0-P10-3 | 10 | 0 | 3-prong split-pass wiring + CI guard/contracts hardening | baseline | none | shared | cross_prong | multi_mode | L3 | PRD-030, PRD-031, PRD-032, PRD-033, PRD-034 | 10.10.1, 10.10.2, 10.10.3, 10.10.4, 10.10.5, 10.10.6, 10.10.8 | lib/_root | AP, REL | GOV | M0-P10-2 | 16 | High | parallel baseline | Done | docs/plans/methodology/M0_P10_3_SPLIT_PASS_CI_GUARD_CONTRACT_HARDENING_BASELINE.md, configs/runtime/split_pass_ci_guard_contract_hardening_controls.json, scripts/runtime/generate_split_pass_ci_guard_contract_hardening_report.py, docs/plans/methodology/MASTER_PLAN_SPLIT_PASS_CI_GUARD_CONTRACT_HARDENING_REPORT.json, docs/plans/methodology/MASTER_PLAN_SPLIT_PASS_CI_GUARD_CONTRACT_HARDENING_REPORT.md, https://github.com/AVRA-CADAVRA/avrai/pull/173 |
| M0-P2-1 | 2 | 0 | Security + cryptographic assurance baseline | baseline | none | shared | governance_core | multi_mode | L4 | PRD-020, PRD-021, PRD-022, PRD-033, PRD-034 | 2.1.1, 2.2.1, 2.5.1 | lib/core/services/security | SEC | GOV | none | 20 | Critical | parallel baseline | Done | docs/plans/methodology/M0_P2_1_SECURITY_CRYPTOGRAPHIC_ASSURANCE_BASELINE.md, configs/runtime/security_cryptographic_assurance_controls.json, scripts/runtime/generate_security_cryptographic_assurance_report.py, docs/plans/methodology/MASTER_PLAN_SECURITY_CRYPTOGRAPHIC_ASSURANCE_REPORT.json, docs/plans/methodology/MASTER_PLAN_SECURITY_CRYPTOGRAPHIC_ASSURANCE_REPORT.md, lib/core/services/security/security_cryptographic_assurance_contract.dart, test/unit/services/security_cryptographic_assurance_contract_test.dart |
| M1-P7-1 | 7 | 1 | Trigger + orchestration persistence hardening | baseline | none | event_ops_runtime | runtime_core | multi_mode | L3 | PRD-021, PRD-022, PRD-033, PRD-034 | 7.4.2, 10.9.1, 10.9.4 | lib/core/controllers | AP, MOB | REL | none | 25 | Critical | Week 1-2 | Done | docs/plans/methodology/M1_P7_1_TRIGGER_ORCHESTRATION_PERSISTENCE_BASELINE.md, configs/runtime/trigger_orchestration_persistence_hardening_controls.json, scripts/runtime/generate_trigger_orchestration_persistence_report.py, docs/plans/methodology/MASTER_PLAN_TRIGGER_ORCHESTRATION_PERSISTENCE_REPORT.json, docs/plans/methodology/MASTER_PLAN_TRIGGER_ORCHESTRATION_PERSISTENCE_REPORT.md, lib/core/controllers/trigger_orchestration_persistence_contract.dart, test/unit/controllers/trigger_orchestration_persistence_contract_test.dart |
| M1-P7-2 | 7 | 1 | Controller/orchestrator integration reliability | baseline | none | event_ops_runtime | runtime_core | multi_mode | L3 | PRD-021, PRD-022, PRD-033, PRD-034 | 7.4.3, 7.4.4, 10.9.4 | lib/core/controllers | AP | REL | M1-P7-1 | 20 | Critical | Week 2-3 | Done | docs/plans/methodology/M1_P7_2_CONTROLLER_ORCHESTRATOR_RELIABILITY_BASELINE.md, configs/runtime/controller_orchestrator_reliability_canary.json, scripts/runtime/generate_controller_orchestrator_reliability_report.py, docs/plans/methodology/MASTER_PLAN_CONTROLLER_ORCHESTRATOR_RELIABILITY_REPORT.json, docs/plans/methodology/MASTER_PLAN_CONTROLLER_ORCHESTRATOR_RELIABILITY_REPORT.md |
| M1-P8-1 | 8 | 1 | Federated cohort gating + canary/shadow pipeline | baseline | none | shared | governance_core | private_mesh | L3 | PRD-021, PRD-022, PRD-033, PRD-034 | 8.1.3, 8.1.4, 8.1.5 | lib/core/ai2ai | FED, MLE | AP | M1-P7-1 | 20 | Critical | Week 3-4 | Done | docs/plans/methodology/M1_P8_1_FEDERATED_COHORT_CANARY_SHADOW_BASELINE.md, configs/runtime/federated_cohort_canary_shadow_pipeline.json, scripts/runtime/generate_federated_cohort_canary_shadow_report.py, docs/plans/methodology/MASTER_PLAN_FEDERATED_COHORT_CANARY_SHADOW_REPORT.json, docs/plans/methodology/MASTER_PLAN_FEDERATED_COHORT_CANARY_SHADOW_REPORT.md |
| M1-P8-2 | 8 | 1 | Advisory quarantine + rollback independence | baseline | none | shared | governance_core | federated_cloud | L3 | PRD-021, PRD-022, PRD-033, PRD-034 | 8.9.2, 8.9.4, 8.9.5 | lib/core/services/locality_agents | LOC | AP | M1-P8-1 | 16 | High | Week 4-5 | Done | docs/plans/methodology/M1_P8_2_ADVISORY_QUARANTINE_ROLLBACK_BASELINE.md, configs/runtime/advisory_quarantine_rollback_independence.json, scripts/runtime/generate_advisory_quarantine_rollback_report.py, docs/plans/methodology/MASTER_PLAN_ADVISORY_QUARANTINE_ROLLBACK_REPORT.json, docs/plans/methodology/MASTER_PLAN_ADVISORY_QUARANTINE_ROLLBACK_REPORT.md |
| M10-P10-3 | 10 | 10 | URK Universal Kernel: learning-healing bridge | baseline | none | shared | cross_prong | multi_mode | L4 | PRD-021, PRD-022, PRD-033, PRD-034 | 7.7.6, 10.9.12, 10.10.8 | lib/core/controllers | AP, REL, MLE | GOV | M10-P3-1, M10-P6-1 | 20 | Critical | Week 22-23 | Done | docs/plans/methodology/M10_P10_3_URK_LEARNING_HEALING_BRIDGE_KERNEL_BASELINE.md, configs/runtime/urk_learning_healing_bridge_controls.json, scripts/runtime/generate_urk_learning_healing_bridge_report.py, docs/plans/methodology/MASTER_PLAN_URK_LEARNING_HEALING_BRIDGE_REPORT.json, docs/plans/methodology/MASTER_PLAN_URK_LEARNING_HEALING_BRIDGE_REPORT.md, lib/core/controllers/urk_learning_healing_bridge_contract.dart, test/unit/controllers/urk_learning_healing_bridge_contract_test.dart |
| M10-P10-4 | 10 | 10 | 3-prong folder migration execution (`apps -> runtime -> engine -> shared`) | baseline | none | shared | cross_prong | multi_mode | L3 | PRD-012, PRD-013, PRD-014, PRD-030, PRD-031, PRD-032, PRD-033, PRD-034 | 10.10.9 | lib/_root | AP, REL | GOV | M10-P10-3 | 16 | High | Week 23-26 | Ready | docs/plans/architecture/CODEBASE_MIGRATION_CHECKLIST_3_PRONG_2026-02-27.md |
| M10-P10-5 | 10 | 10 | 3-prong canonical visualization governance (external/internal flow maps) | baseline | none | shared | cross_prong | multi_mode | L2 | PRD-012, PRD-013, PRD-014, PRD-030, PRD-031, PRD-032, PRD-033, PRD-034 | 10.10.10 | docs/plans/architecture | AP, REL | GOV | M10-P10-4 | 12 | High | Week 23-26 | Ready | docs/plans/architecture/THREE_PRONG_ARCHITECTURE_VISUALIZATION_GUIDE_2026-02-27.md, docs/plans/architecture/ARCHITECTURE_INDEX.md, docs/MASTER_PLAN.md |
| M10-P10-6 | 10 | 10 | 3-prong target structure default placement enforcement for all new code | baseline | none | shared | cross_prong | multi_mode | L3 | PRD-012, PRD-013, PRD-014, PRD-030, PRD-031, PRD-032, PRD-033, PRD-034 | 10.10.11 | docs/plans/architecture | AP, REL | GOV | M10-P10-5 | 16 | High | Week 23-26 | Ready | docs/plans/architecture/TARGET_CODEBASE_STRUCTURE_ENFORCEMENT_2026-02-27.md, docs/plans/architecture/FILE_PLACEMENT_POLICY.md, docs/MASTER_PLAN.md |
| M10-P11-1 | 11 | 10 | URK Universal Kernel: control plane APIs + admin runtime wiring | baseline | none | shared | governance_core | multi_mode | L4 | PRD-021, PRD-022, PRD-033, PRD-034 | 7.7.6, 10.9.12, 11.1.1 | lib/core/services/admin | AP, REL, Product | GOV | M10-P7-1 | 20 | Critical | Week 23-24 | Done | docs/plans/methodology/M10_P11_1_URK_KERNEL_CONTROL_PLANE_BASELINE.md, configs/runtime/urk_kernel_control_plane_controls.json, scripts/runtime/generate_urk_kernel_control_plane_report.py, docs/plans/methodology/MASTER_PLAN_URK_KERNEL_CONTROL_PLANE_REPORT.json, docs/plans/methodology/MASTER_PLAN_URK_KERNEL_CONTROL_PLANE_REPORT.md, lib/core/services/admin/urk_kernel_control_plane_service.dart, test/unit/services/admin/urk_kernel_control_plane_service_test.dart, lib/presentation/pages/admin/urk_kernel_console_page.dart |
| M10-P11-2 | 11 | 10 | URK Universal Kernel: runtime activation receipt dispatch wiring | baseline | none | shared | runtime_core | multi_mode | L4 | PRD-021, PRD-022, PRD-033, PRD-034 | 7.7.5, 7.7.6, 10.9.12, 11.1.1 | lib/core/controllers | AP, REL, MLE | GOV | M10-P11-1 | 20 | Critical | Week 23-24 | Done | docs/plans/methodology/M10_P11_2_URK_RUNTIME_ACTIVATION_RECEIPT_DISPATCH_BASELINE.md, configs/runtime/urk_runtime_activation_receipt_dispatch_controls.json, scripts/runtime/generate_urk_runtime_activation_receipt_dispatch_report.py, docs/plans/methodology/MASTER_PLAN_URK_RUNTIME_ACTIVATION_RECEIPT_DISPATCH_REPORT.json, docs/plans/methodology/MASTER_PLAN_URK_RUNTIME_ACTIVATION_RECEIPT_DISPATCH_REPORT.md, lib/core/controllers/urk_runtime_activation_receipt_dispatcher.dart, test/unit/controllers/urk_runtime_activation_receipt_dispatcher_test.dart, lib/core/controllers/conviction_shadow_gate.dart, lib/core/services/ai_infrastructure/online_learning_service.dart, lib/core/ai2ai/connection_orchestrator.dart, lib/core/services/admin/urk_kernel_control_plane_service.dart, test/unit/services/admin/urk_kernel_control_plane_service_test.dart, lib/core/services/business/urk_stage_d_business_runtime_replication_contract.dart, test/unit/services/urk_stage_d_business_runtime_replication_contract_test.dart, lib/core/services/expertise/urk_stage_d_expert_runtime_replication_contract.dart, test/unit/services/urk_stage_d_expert_runtime_replication_contract_test.dart, lib/core/services/business/business_service.dart, lib/core/services/expertise/expert_recommendations_service.dart, test/unit/services/business_service_urk_runtime_dispatch_test.dart, test/unit/services/expert_recommendations_service_test.dart, lib/core/controllers/urk_stage_b_event_ops_shadow_runtime_contract.dart, test/unit/controllers/urk_stage_b_event_ops_shadow_runtime_contract_test.dart, lib/core/services/events/event_recommendation_service.dart, test/unit/services/event_recommendation_urk_runtime_dispatch_test.dart |
| M10-P3-1 | 3 | 10 | URK Universal Kernel: self-learning governance | baseline | none | shared | model_core | multi_mode | L4 | PRD-021, PRD-022, PRD-033, PRD-034 | 3.2.1, 7.9.6, 10.9.12 | lib/core/ai | AP, MLE | AP | M9-P3-2 | 20 | Critical | Week 21-22 | Done | docs/plans/methodology/M10_P3_1_URK_SELF_LEARNING_GOVERNANCE_KERNEL_BASELINE.md, configs/runtime/urk_self_learning_governance_controls.json, scripts/runtime/generate_urk_self_learning_governance_report.py, docs/plans/methodology/MASTER_PLAN_URK_SELF_LEARNING_GOVERNANCE_REPORT.json, docs/plans/methodology/MASTER_PLAN_URK_SELF_LEARNING_GOVERNANCE_REPORT.md, lib/core/ai/urk_self_learning_governance_contract.dart, test/unit/ai/urk_self_learning_governance_contract_test.dart |
| M10-P6-1 | 6 | 10 | URK Universal Kernel: self-healing recovery | baseline | none | shared | runtime_core | multi_mode | L4 | PRD-021, PRD-022, PRD-033, PRD-034 | 6.2.10, 7.3.4, 10.9.12 | lib/core/services | REL, AP | GOV | M6-P3-1 | 25 | Critical | Week 21-22 | Done | docs/plans/methodology/M10_P6_1_URK_SELF_HEALING_RECOVERY_KERNEL_BASELINE.md, configs/runtime/urk_self_healing_recovery_controls.json, scripts/runtime/generate_urk_self_healing_recovery_report.py, docs/plans/methodology/MASTER_PLAN_URK_SELF_HEALING_RECOVERY_REPORT.json, docs/plans/methodology/MASTER_PLAN_URK_SELF_HEALING_RECOVERY_REPORT.md, lib/core/services/urk_self_healing_recovery_contract.dart, test/unit/services/urk_self_healing_recovery_contract_test.dart |
| M10-P7-1 | 7 | 10 | URK Universal Kernel: activation engine (trigger routing + policy gates + receipts) | baseline | none | shared | runtime_core | multi_mode | L4 | PRD-021, PRD-022, PRD-033, PRD-034 | 7.4.2, 7.7.5, 10.9.12 | lib/core/controllers | AP, REL, MLE | GOV | M10-P10-3 | 20 | Critical | Week 22-23 | Done | docs/plans/methodology/M10_P10_4_URK_KERNEL_ACTIVATION_ENGINE_BASELINE.md, configs/runtime/urk_kernel_activation_engine_controls.json, scripts/runtime/generate_urk_kernel_activation_engine_report.py, docs/plans/methodology/MASTER_PLAN_URK_KERNEL_ACTIVATION_ENGINE_REPORT.json, docs/plans/methodology/MASTER_PLAN_URK_KERNEL_ACTIVATION_ENGINE_REPORT.md, lib/core/controllers/urk_kernel_activation_engine_contract.dart, test/unit/controllers/urk_kernel_activation_engine_contract_test.dart |
| M11-P3-1 | 3 | 11 | URK User Runtime Kernel: realtime learning intake governance | baseline | none | user_runtime | model_core | local_sovereign | L3 | PRD-021, PRD-022, PRD-033, PRD-034 | 3.2.1, 7.7.5, 10.9.12 | lib/core/services/user | AP, MLE | AP | M10-P11-2, M10-P3-1 | 16 | High | Week 24-25 | Ready | docs/plans/methodology/M11_P3_1_URK_USER_RUNTIME_LEARNING_INTAKE_KERNEL_BASELINE.md, configs/runtime/urk_user_runtime_learning_intake_controls.json, configs/runtime/urk_user_runtime_observability_thresholds.json, scripts/runtime/generate_urk_user_runtime_learning_intake_report.py, docs/plans/methodology/MASTER_PLAN_URK_USER_RUNTIME_LEARNING_INTAKE_REPORT.json, docs/plans/methodology/MASTER_PLAN_URK_USER_RUNTIME_LEARNING_INTAKE_REPORT.md, lib/core/services/user/urk_user_runtime_learning_intake_contract.dart, test/unit/services/urk_user_runtime_learning_intake_contract_test.dart, lib/core/services/events/event_recommendation_service.dart, test/unit/services/event_recommendation_urk_runtime_dispatch_test.dart, lib/presentation/pages/settings/privacy_settings_page.dart, lib/presentation/pages/admin/urk_kernel_console_page.dart, lib/core/services/admin/urk_user_runtime_observability_threshold_service.dart, test/unit/services/admin/urk_user_runtime_observability_threshold_service_test.dart, lib/core/services/admin/urk_kernel_control_plane_service.dart, test/unit/services/admin/urk_kernel_control_plane_service_test.dart |
| M12-P10-1 | 10 | 12 | 3-prong umbrella synchronization governance and anti-collision gate | baseline | none | shared | cross_prong | multi_mode | L3 | PRD-030, PRD-031, PRD-032, PRD-033, PRD-034 | 10.10.12 | docs/plans/architecture | AP, REL | GOV | M10-P10-6 | 12 | High | Week 26-27 | Done | docs/plans/methodology/M12_P10_1_3_PRONG_UMBRELLA_SYNC_ANTI_COLLISION_BASELINE.md, configs/runtime/three_prong_umbrella_sync_anti_collision_controls.json, docs/plans/methodology/MASTER_PLAN_3_PRONG_UMBRELLA_SYNC_ANTI_COLLISION_REPORT.json, docs/plans/methodology/MASTER_PLAN_3_PRONG_UMBRELLA_SYNC_ANTI_COLLISION_REPORT.md, docs/plans/architecture/MASTER_PLAN_3_PRONG_TARGET_END_STATE.md, docs/EXECUTION_BOARD.md, docs/MASTER_PLAN.md, docs/MASTER_PLAN_TRACKER.md |
| M12-P10-2 | 10 | 12 | Apps prong concurrent lane execution and contract-consumer compatibility | baseline | none | user_runtime | cross_prong | multi_mode | L2 | PRD-012, PRD-013, PRD-014, PRD-033 | 10.10.12 | apps/consumer_app | AP, Product | Product | M12-P10-1 | 12 | High | Week 26-28 | Done | docs/plans/methodology/M12_P10_2_APPS_PRONG_CONCURRENT_EXECUTION_CONTRACT_COMPATIBILITY_BASELINE.md, configs/runtime/apps_prong_concurrent_execution_contract_compatibility_controls.json, docs/plans/methodology/MASTER_PLAN_APPS_PRONG_CONCURRENT_EXECUTION_CONTRACT_COMPATIBILITY_REPORT.json, docs/plans/methodology/MASTER_PLAN_APPS_PRONG_CONCURRENT_EXECUTION_CONTRACT_COMPATIBILITY_REPORT.md, docs/plans/architecture/PRONG_APPS_CONCURRENT_EXECUTION_PLAN_2026-02-28.md, apps/consumer_app/README.md, apps/admin_app/README.md, python3 scripts/ci/check_three_prong_boundaries.py |
| M12-P10-3 | 10 | 12 | Runtime OS prong concurrent lane execution and policy-orchestration isolation | baseline | none | event_ops_runtime | runtime_core | multi_mode | L3 | PRD-021, PRD-022, PRD-033, PRD-034 | 10.10.12 | runtime/avrai_runtime_os | AP, REL | REL | M12-P10-1 | 16 | High | Week 26-28 | Ready | docs/plans/architecture/PRONG_RUNTIME_OS_CONCURRENT_EXECUTION_PLAN_2026-02-28.md, scripts/ci/check_three_prong_boundaries.py, scripts/validate_architecture_placement.py |
| M12-P10-4 | 10 | 12 | Reality Model prong concurrent lane execution and deterministic model contract isolation | baseline | none | shared | model_core | multi_mode | L4 | PRD-021, PRD-022, PRD-033, PRD-034 | 10.10.12 | engine/reality_engine | AP, MLE | AP | M12-P10-1 | 20 | Critical | Week 26-29 | Ready | docs/plans/architecture/PRONG_REALITY_MODEL_CONCURRENT_EXECUTION_PLAN_2026-02-28.md, docs/MASTER_PLAN.md, docs/EXECUTION_BOARD.md |
| M2-P1-1 | 1 | 2 | Memory reliability gates | baseline | none | shared | model_core | multi_mode | L3 | PRD-001, PRD-002, PRD-010, PRD-011, PRD-033, PRD-034 | 1.1.1, 1.2.12, 1.3.1 | lib/core/ai | AP, MLE | AP | none | 12 | High | Week 5-6 | Done | docs/plans/methodology/M2_P1_1_MEMORY_RELIABILITY_GATES_BASELINE.md, configs/runtime/memory_reliability_gates.json, scripts/runtime/generate_memory_reliability_gates_report.py, docs/plans/methodology/MASTER_PLAN_MEMORY_RELIABILITY_GATES_REPORT.json, docs/plans/methodology/MASTER_PLAN_MEMORY_RELIABILITY_GATES_REPORT.md, lib/core/ai/memory/memory_reliability_contract.dart, test/unit/ai/memory_reliability_contract_test.dart |
| M2-P3-1 | 3 | 2 | State encoder consistency/freshness controls | baseline | none | event_ops_runtime | model_core | multi_mode | L3 | PRD-010, PRD-011, PRD-033, PRD-034 | 3.1.1, 3.1.4, 3.2.1 | lib/core/models | AP, MLE | AP | M2-P1-1 | 12 | High | Week 6-7 | Done | docs/plans/methodology/M2_P3_1_STATE_ENCODER_CONSISTENCY_FRESHNESS_BASELINE.md, configs/runtime/state_encoder_consistency_freshness_controls.json, scripts/runtime/generate_state_encoder_consistency_freshness_report.py, docs/plans/methodology/MASTER_PLAN_STATE_ENCODER_CONSISTENCY_FRESHNESS_REPORT.json, docs/plans/methodology/MASTER_PLAN_STATE_ENCODER_CONSISTENCY_FRESHNESS_REPORT.md, lib/core/models/state_encoder_consistency_contract.dart, test/unit/models/state_encoder_consistency_contract_test.dart |
| M2-P4-1 | 4 | 2 | Energy function safety and regression governance | baseline | none | event_ops_runtime | model_core | multi_mode | L4 | PRD-021, PRD-022, PRD-033, PRD-034 | 4.1.3, 4.1.7, 4.5.7 | lib/core/ml | MLE | AP | M2-P3-1 | 20 | Critical | Week 7-8 | Done | docs/plans/methodology/M2_P4_1_ENERGY_FUNCTION_SAFETY_REGRESSION_BASELINE.md, configs/runtime/energy_function_safety_regression_controls.json, scripts/runtime/generate_energy_function_safety_regression_report.py, docs/plans/methodology/MASTER_PLAN_ENERGY_FUNCTION_SAFETY_REGRESSION_REPORT.json, docs/plans/methodology/MASTER_PLAN_ENERGY_FUNCTION_SAFETY_REGRESSION_REPORT.md, lib/core/ml/energy_function_safety_contract.dart, test/unit/ml/energy_function_safety_contract_test.dart |
| M2-P5-1 | 5 | 2 | Transition predictor drift/calibration controls | baseline | none | event_ops_runtime | model_core | multi_mode | L4 | PRD-021, PRD-022, PRD-033, PRD-034 | 5.1.3, 5.1.9, 5.2.1 | lib/core/ml | MLE | AP | M2-P4-1 | 20 | Critical | Week 8-9 | Done | docs/plans/methodology/M2_P5_1_TRANSITION_PREDICTOR_DRIFT_CALIBRATION_BASELINE.md, configs/runtime/transition_predictor_drift_calibration_controls.json, scripts/runtime/generate_transition_predictor_drift_calibration_report.py, docs/plans/methodology/MASTER_PLAN_TRANSITION_PREDICTOR_DRIFT_CALIBRATION_REPORT.json, docs/plans/methodology/MASTER_PLAN_TRANSITION_PREDICTOR_DRIFT_CALIBRATION_REPORT.md, lib/core/ml/transition_predictor_drift_calibration_contract.dart, test/unit/ml/transition_predictor_drift_calibration_contract_test.dart |
| M2-P6-1 | 6 | 2 | Planner guardrail and rollback-hardening | baseline | none | event_ops_runtime | governance_core | multi_mode | L4 | PRD-021, PRD-022, PRD-033, PRD-034 | 6.2.1, 6.2.9, 6.2.10 | lib/core/ai | AP, MLE | AP | M2-P5-1 | 20 | Critical | Week 9-10 | Done | docs/plans/methodology/M2_P6_1_PLANNER_GUARDRAIL_ROLLBACK_HARDENING_BASELINE.md, configs/runtime/planner_guardrail_rollback_hardening_controls.json, scripts/runtime/generate_planner_guardrail_rollback_hardening_report.py, docs/plans/methodology/MASTER_PLAN_PLANNER_GUARDRAIL_ROLLBACK_HARDENING_REPORT.json, docs/plans/methodology/MASTER_PLAN_PLANNER_GUARDRAIL_ROLLBACK_HARDENING_REPORT.md, lib/core/ai/planner_guardrail_rollback_contract.dart, test/unit/ai/planner_guardrail_rollback_contract_test.dart |
| M3-P11-1 | 11 | 3 | Integration governance + contract security gates | baseline | none | shared | governance_core | federated_cloud | L4 | PRD-020, PRD-021, PRD-022, PRD-033, PRD-034 | 11.1.1, 11.2.1, 11.4.1 | lib/core/cloud | Integrations Platform | GOV | M3-P9-1 | 15 | High | Week 11-12 | Done | docs/plans/methodology/M3_P11_1_INTEGRATION_GOVERNANCE_CONTRACT_SECURITY_BASELINE.md, configs/runtime/integration_governance_contract_security_controls.json, scripts/runtime/generate_integration_governance_contract_security_report.py, docs/plans/methodology/MASTER_PLAN_INTEGRATION_GOVERNANCE_CONTRACT_SECURITY_REPORT.json, docs/plans/methodology/MASTER_PLAN_INTEGRATION_GOVERNANCE_CONTRACT_SECURITY_REPORT.md, lib/core/cloud/integration_governance_contract_security_contract.dart, test/unit/cloud/integration_governance_contract_security_contract_test.dart |
| M3-P9-1 | 9 | 3 | Business data/consent governance hardening | baseline | none | business_ops_runtime | governance_core | federated_cloud | L4 | PRD-020, PRD-021, PRD-022, PRD-033, PRD-034 | 9.2.6, 9.3.1, 9.3.3 | lib/core/services/business | Business Platform, AP | GOV | M2-P6-1 | 12 | High | Week 10-11 | Done | docs/plans/methodology/M3_P9_1_BUSINESS_DATA_CONSENT_GOVERNANCE_BASELINE.md, configs/runtime/business_data_consent_governance_controls.json, scripts/runtime/generate_business_data_consent_governance_report.py, docs/plans/methodology/MASTER_PLAN_BUSINESS_DATA_CONSENT_GOVERNANCE_REPORT.json, docs/plans/methodology/MASTER_PLAN_BUSINESS_DATA_CONSENT_GOVERNANCE_REPORT.md, lib/core/services/business/business_data_consent_governance_contract.dart, test/unit/services/business_data_consent_governance_contract_test.dart |
| M4-P3-1 | 1 | 4 | 3-prong claim lifecycle schema + API contracts | baseline | none | shared | governance_core | multi_mode | L4 | PRD-010, PRD-011, PRD-033, PRD-034 | 1.1.1, 1.1.2, 7.7.1 | lib/core/ai | AP, MLE | AP | M2-P1-1 | 20 | Critical | Day 0-30 | Done | docs/plans/methodology/M4_P3_1_CLAIM_LIFECYCLE_CONTRACT_BASELINE.md, lib/core/ai/knowledge_lifecycle/claim_lifecycle_contract.dart, test/unit/ai/claim_lifecycle_contract_test.dart |
| M4-P3-2 | 7 | 4 | Conviction gate shadow mode in serving runtime | baseline | none | event_ops_runtime | governance_core | multi_mode | L4 | PRD-021, PRD-022, PRD-033, PRD-034 | 6.2.21, 7.7.4, 7.7.3 | lib/core/controllers | AP, REL | REL | M4-P3-1 | 20 | Critical | Day 0-30 | Done | docs/plans/methodology/M4_P3_2_CONVICTION_GATE_SHADOW_BASELINE.md, lib/core/controllers/conviction_shadow_gate.dart, lib/core/controllers/list_creation_controller.dart, lib/core/controllers/event_creation_controller.dart, lib/core/controllers/ai_recommendation_controller.dart, lib/core/controllers/checkout_controller.dart, lib/core/controllers/payment_processing_controller.dart, test/unit/controllers/conviction_shadow_gate_test.dart, test/unit/controllers/conviction_shadow_gate_persistence_test.dart |
| M4-P3-3 | 7 | 4 | Promotion contracts + mandatory eval suite automation | baseline | none | shared | governance_core | multi_mode | L4 | PRD-021, PRD-022, PRD-033, PRD-034 | 5.2.21, 7.7.3, 7.9.6 | lib/core/ml | MLE | AP | M4-P3-1 | 20 | Critical | Day 0-30 | Done | docs/plans/methodology/M4_P3_3_PROMOTION_EVAL_AUTOMATION_BASELINE.md, lib/core/ml/promotion_eval_contract.dart, test/unit/ml/promotion_eval_contract_test.dart, configs/ml/promotion_eval_manifest.json, scripts/ml/check_promotion_eval_manifest.py, docs/plans/methodology/MASTER_PLAN_3_PRONG_PROMOTION_EVAL_CHECK.json |
| M5-P3-1 | 6 | 5 | High-impact conviction gate enforcement (production) | baseline | none | event_ops_runtime | governance_core | multi_mode | L4 | PRD-021, PRD-022, PRD-033, PRD-034 | 6.2.21, 6.2.22, 7.7.5 | lib/core/ai | AP, REL | REL | M4-P3-2 | 25 | Critical | Day 31-60 | Done | docs/plans/methodology/M5_P3_1_HIGH_IMPACT_ENFORCEMENT_FLAGGED_BASELINE.md, lib/core/controllers/conviction_shadow_gate.dart, lib/core/controllers/checkout_controller.dart, lib/core/controllers/payment_processing_controller.dart, test/unit/controllers/conviction_shadow_gate_test.dart, configs/runtime/conviction_gate_canary_rollout.json, scripts/runtime/check_conviction_canary_rollout_config.py, configs/runtime/conviction_gate_canary_dry_run_fixture.json, scripts/runtime/check_conviction_canary_dry_run_fixture.py, docs/plans/methodology/MASTER_PLAN_3_PRONG_SHADOW_GATE_TELEMETRY_CANARY_DRY_RUN.md, docs/plans/methodology/MASTER_PLAN_3_PRONG_SHADOW_GATE_TELEMETRY_CANARY_DRY_RUN.json |
| M5-P3-2 | 7 | 5 | Operational canary + rollback automation for conviction promotions | baseline | none | shared | governance_core | multi_mode | L4 | PRD-021, PRD-022, PRD-033, PRD-034 | 7.7.4, 7.7.5, 10.9.21 | lib/core/controllers | REL | REL | M5-P3-1 | 25 | Critical | Day 31-60 | Done | docs/plans/methodology/M5_P3_2_CANARY_ROLLBACK_AUTOMATION_BASELINE.md, configs/runtime/conviction_gate_canary_rollback_drill_fixture.json, scripts/runtime/generate_conviction_canary_rollback_drill_report.py, docs/plans/methodology/MASTER_PLAN_3_PRONG_CANARY_ROLLBACK_DRILL_REPORT.json, docs/plans/methodology/MASTER_PLAN_3_PRONG_CANARY_ROLLBACK_DRILL_REPORT.md |
| M5-P3-3 | 7 | 5 | Research replication queue + SLA instrumentation | baseline | none | shared | governance_core | multi_mode | L3 | PRD-021, PRD-022, PRD-033, PRD-034 | 1.4.14, 7.9.8, 7.9.10 | docs/plans/architecture | MLE | AP | M4-P3-3 | 15 | High | Day 31-60 | Done | docs/plans/methodology/M5_P3_3_RESEARCH_REPLICATION_SLA_BASELINE.md, configs/runtime/research_replication_queue.json, scripts/runtime/generate_research_replication_sla_report.py, docs/plans/methodology/MASTER_PLAN_3_PRONG_RESEARCH_REPLICATION_SLA_REPORT.json, docs/plans/methodology/MASTER_PLAN_3_PRONG_RESEARCH_REPLICATION_SLA_REPORT.md |
| M5-P3-4 | 10 | 5 | Trust UX v1: confidence + provenance surfaces on priority flows | baseline | none | user_runtime | runtime_core | multi_mode | L2 | PRD-012, PRD-013, PRD-014, PRD-033 | 1.4.13, 7.7.5, 10.9.9 | lib/presentation | Product, AP | Product | M5-P3-1 | 12 | High | Day 31-60 | Done | docs/plans/methodology/M5_P3_4_TRUST_UX_PRIORITY_FLOW_BASELINE.md, configs/runtime/trust_ux_priority_flows.json, scripts/runtime/generate_trust_ux_priority_flow_report.py, docs/plans/methodology/MASTER_PLAN_3_PRONG_TRUST_UX_PRIORITY_FLOW_REPORT.json, docs/plans/methodology/MASTER_PLAN_3_PRONG_TRUST_UX_PRIORITY_FLOW_REPORT.md |
| M6-P3-1 | 7 | 6 | Cross-domain self-healing automation + incident routing hardening | baseline | none | shared | runtime_core | multi_mode | L4 | PRD-021, PRD-022, PRD-033, PRD-034 | 7.3.4, 8.1.1, 10.9.12 | lib/core/services | REL | REL | M5-P3-2 | 25 | Critical | Day 61-90 | Done | docs/plans/methodology/M6_P3_1_SELF_HEALING_INCIDENT_ROUTING_BASELINE.md, configs/runtime/self_healing_incident_routing_queue.json, scripts/runtime/generate_self_healing_incident_routing_report.py, docs/plans/methodology/MASTER_PLAN_3_PRONG_SELF_HEALING_INCIDENT_ROUTING_REPORT.json, docs/plans/methodology/MASTER_PLAN_3_PRONG_SELF_HEALING_INCIDENT_ROUTING_REPORT.md |
| M6-P3-2 | 10 | 6 | Lineage explorer + \"what changed\" transparency feed | baseline | none | user_runtime | runtime_core | multi_mode | L2 | PRD-012, PRD-013, PRD-014, PRD-033 | 7.7.5, 7.7.6, 10.9.9 | lib/presentation | Product, AP | Product | M5-P3-4 | 12 | High | Day 61-90 | Done | docs/plans/methodology/M6_P3_2_LINEAGE_TRANSPARENCY_FEED_BASELINE.md, configs/runtime/lineage_transparency_priority_flows.json, scripts/runtime/generate_lineage_transparency_priority_flow_report.py, docs/plans/methodology/MASTER_PLAN_3_PRONG_LINEAGE_TRANSPARENCY_PRIORITY_FLOW_REPORT.json, docs/plans/methodology/MASTER_PLAN_3_PRONG_LINEAGE_TRANSPARENCY_PRIORITY_FLOW_REPORT.md |
| M6-P3-3 | 10 | 6 | Master-plan completion readiness audit + sign-off package | baseline | none | shared | governance_core | multi_mode | L4 | PRD-030, PRD-031, PRD-032, PRD-033, PRD-034 | 10.9.21, 10.10.8 | docs | AP, REL | GOV | M6-P3-1, M6-P3-2 | 20 | Critical | Day 61-90 | Done | docs/plans/methodology/M6_P3_3_COMPLETION_AUDIT_SIGNOFF_BASELINE.md, configs/runtime/master_plan_completion_audit_package.json, configs/runtime/master_plan_signoff_registry.json, scripts/runtime/check_master_plan_signoff_registry.py, scripts/runtime/update_master_plan_signoff_registry.py, scripts/runtime/generate_master_plan_completion_audit_package.py, docs/plans/methodology/MASTER_PLAN_3_PRONG_COMPLETION_AUDIT_PACKAGE.json, docs/plans/methodology/MASTER_PLAN_3_PRONG_COMPLETION_AUDIT_PACKAGE.md |
| M7-P7-3 | 7 | 7 | URK Stage A: TriggerService + PrivacyModePolicy + NoEgressGate contract freeze | baseline | none | event_ops_runtime | runtime_core | multi_mode | L3 | PRD-021, PRD-022, PRD-033, PRD-034 | 7.4.2, 7.5.1, 7.7.5, 10.9.12 | lib/core/controllers | AP, REL | REL | M6-P3-3 | 20 | Critical | Week 13-14 | Done | docs/plans/methodology/M7_P7_3_URK_STAGE_A_TRIGGER_PRIVACY_NO_EGRESS_BASELINE.md, configs/runtime/urk_stage_a_trigger_privacy_no_egress_controls.json, scripts/runtime/generate_urk_stage_a_trigger_privacy_no_egress_report.py, docs/plans/methodology/MASTER_PLAN_URK_STAGE_A_TRIGGER_PRIVACY_NO_EGRESS_REPORT.json, docs/plans/methodology/MASTER_PLAN_URK_STAGE_A_TRIGGER_PRIVACY_NO_EGRESS_REPORT.md, lib/core/controllers/urk_stage_a_trigger_privacy_no_egress_contract.dart, test/unit/controllers/urk_stage_a_trigger_privacy_no_egress_contract_test.dart |
| M7-P7-4 | 7 | 7 | URK Stage B: Event Ops runtime shadow wiring (ingest-plan-gate-observe) | baseline | none | event_ops_runtime | runtime_core | multi_mode | L3 | PRD-021, PRD-022, PRD-033, PRD-034 | 6.1.1, 6.2.1, 7.4.3, 7.7.5 | lib/core/controllers | AP, MOB | REL | M7-P7-3 | 20 | Critical | Week 14-15 | Done | docs/plans/methodology/M7_P7_4_URK_STAGE_B_EVENT_OPS_SHADOW_RUNTIME_BASELINE.md, configs/runtime/urk_stage_b_event_ops_shadow_runtime_controls.json, scripts/runtime/generate_urk_stage_b_event_ops_shadow_runtime_report.py, docs/plans/methodology/MASTER_PLAN_URK_STAGE_B_EVENT_OPS_SHADOW_RUNTIME_REPORT.json, docs/plans/methodology/MASTER_PLAN_URK_STAGE_B_EVENT_OPS_SHADOW_RUNTIME_REPORT.md, lib/core/controllers/urk_stage_b_event_ops_shadow_runtime_contract.dart, test/unit/controllers/urk_stage_b_event_ops_shadow_runtime_contract_test.dart |
| M7-P8-3 | 8 | 7 | URK Stage C prep: private-mesh policy conformance for Event Ops deltas | baseline | none | event_ops_runtime | governance_core | private_mesh | L3 | PRD-021, PRD-022, PRD-033, PRD-034 | 8.1.3, 8.1.4, 8.9.5, 10.9.12 | lib/core/ai2ai | FED, LOC | AP | M7-P7-4 | 20 | Critical | Week 15-16 | Done | docs/plans/methodology/M7_P8_3_URK_STAGE_C_PRIVATE_MESH_POLICY_CONFORMANCE_BASELINE.md, configs/runtime/urk_stage_c_private_mesh_policy_conformance_controls.json, scripts/runtime/generate_urk_stage_c_private_mesh_policy_conformance_report.py, docs/plans/methodology/MASTER_PLAN_URK_STAGE_C_PRIVATE_MESH_POLICY_CONFORMANCE_REPORT.json, docs/plans/methodology/MASTER_PLAN_URK_STAGE_C_PRIVATE_MESH_POLICY_CONFORMANCE_REPORT.md, lib/core/ai2ai/urk_stage_c_private_mesh_policy_conformance_contract.dart, test/unit/ai2ai/urk_stage_c_private_mesh_policy_conformance_contract_test.dart |
| M8-P10-4 | 10 | 8 | URK Stage E: Cross-runtime conformance matrix + replay harness | baseline | none | shared | cross_prong | multi_mode | L3 | PRD-021, PRD-022, PRD-033, PRD-034 | 7.7.5, 8.1.4, 10.9.12, 10.10.8 | lib/core/controllers | AP, REL | GOV | M8-P11-2 | 15 | High | Week 18-19 | Done | docs/plans/methodology/M8_P10_4_URK_STAGE_E_CROSS_RUNTIME_CONFORMANCE_BASELINE.md, configs/runtime/urk_stage_e_cross_runtime_conformance_controls.json, scripts/runtime/generate_urk_stage_e_cross_runtime_conformance_report.py, docs/plans/methodology/MASTER_PLAN_URK_STAGE_E_CROSS_RUNTIME_CONFORMANCE_REPORT.json, docs/plans/methodology/MASTER_PLAN_URK_STAGE_E_CROSS_RUNTIME_CONFORMANCE_REPORT.md, lib/core/controllers/urk_stage_e_cross_runtime_conformance_contract.dart, test/unit/controllers/urk_stage_e_cross_runtime_conformance_contract_test.dart |
| M8-P11-2 | 11 | 8 | URK Stage D: Expert runtime replication on shared URK contracts | baseline | none | expert_services_runtime | runtime_core | private_mesh | L3 | PRD-021, PRD-022, PRD-033, PRD-034 | 8.4.2, 11.1.1, 11.2.1, 10.9.12 | lib/core/services/expertise | Integrations Platform, AP | GOV | M8-P9-2 | 15 | High | Week 17-18 | Done | docs/plans/methodology/M8_P11_2_URK_STAGE_D_EXPERT_RUNTIME_REPLICATION_BASELINE.md, configs/runtime/urk_stage_d_expert_runtime_replication_controls.json, scripts/runtime/generate_urk_stage_d_expert_runtime_replication_report.py, docs/plans/methodology/MASTER_PLAN_URK_STAGE_D_EXPERT_RUNTIME_REPLICATION_REPORT.json, docs/plans/methodology/MASTER_PLAN_URK_STAGE_D_EXPERT_RUNTIME_REPLICATION_REPORT.md, lib/core/services/expertise/urk_stage_d_expert_runtime_replication_contract.dart, test/unit/services/urk_stage_d_expert_runtime_replication_contract_test.dart |
| M8-P9-2 | 9 | 8 | URK Stage D: Business runtime replication on shared URK contracts | baseline | none | business_ops_runtime | runtime_core | federated_cloud | L3 | PRD-020, PRD-021, PRD-022, PRD-033, PRD-034 | 7.7.5, 9.2.6, 9.3.1, 10.9.12 | lib/core/services/business | Business Platform, AP | GOV | M7-P8-3 | 12 | High | Week 16-17 | Done | docs/plans/methodology/M8_P9_2_URK_STAGE_D_BUSINESS_RUNTIME_REPLICATION_BASELINE.md, configs/runtime/urk_stage_d_business_runtime_replication_controls.json, scripts/runtime/generate_urk_stage_d_business_runtime_replication_report.py, docs/plans/methodology/MASTER_PLAN_URK_STAGE_D_BUSINESS_RUNTIME_REPLICATION_REPORT.json, docs/plans/methodology/MASTER_PLAN_URK_STAGE_D_BUSINESS_RUNTIME_REPLICATION_REPORT.md, lib/core/services/business/urk_stage_d_business_runtime_replication_contract.dart, test/unit/services/urk_stage_d_business_runtime_replication_contract_test.dart |
| M9-P10-1 | 10 | 9 | URK Universal Kernel: promotion lifecycle governance | baseline | none | shared | governance_core | multi_mode | L3 | PRD-021, PRD-022, PRD-033, PRD-034 | 10.9.12, 10.10.8 | lib/core/controllers | AP, REL | GOV | M8-P10-4 | 15 | High | Week 19-20 | Done | docs/plans/methodology/M9_P10_1_URK_KERNEL_PROMOTION_LIFECYCLE_BASELINE.md, configs/runtime/urk_kernel_promotion_lifecycle_controls.json, scripts/runtime/generate_urk_kernel_promotion_lifecycle_report.py, docs/plans/methodology/MASTER_PLAN_URK_KERNEL_PROMOTION_LIFECYCLE_REPORT.json, docs/plans/methodology/MASTER_PLAN_URK_KERNEL_PROMOTION_LIFECYCLE_REPORT.md, lib/core/controllers/urk_kernel_promotion_lifecycle_contract.dart, test/unit/controllers/urk_kernel_promotion_lifecycle_contract_test.dart |
| M9-P10-2 | 10 | 9 | URK Universal Kernel: registry completeness + admin catalog | baseline | none | shared | cross_prong | multi_mode | L3 | PRD-021, PRD-022, PRD-033, PRD-034 | 7.7.6, 10.9.12, 10.10.8 | docs | AP, REL | GOV | M9-P10-1, M9-P3-2 | 12 | High | Week 20-21 | Done | docs/plans/methodology/M9_P10_2_URK_KERNEL_REGISTRY_AND_ADMIN_CATALOG_BASELINE.md, configs/runtime/kernel_registry.json, scripts/runtime/check_urk_kernel_registry.py, scripts/runtime/generate_urk_kernel_catalog.py, docs/admin/URK_KERNEL_CATALOG.md |
| M9-P3-2 | 3 | 9 | URK Universal Kernel: learning update governance | baseline | none | shared | model_core | multi_mode | L4 | PRD-021, PRD-022, PRD-033, PRD-034 | 3.2.1, 7.9.6, 10.9.12 | lib/core/ai | AP, MLE | AP | M8-P10-4 | 20 | Critical | Week 19-20 | Done | docs/plans/methodology/M9_P3_2_URK_LEARNING_UPDATE_GOVERNANCE_BASELINE.md, configs/runtime/urk_learning_update_governance_controls.json, scripts/runtime/generate_urk_learning_update_governance_report.py, docs/plans/methodology/MASTER_PLAN_URK_LEARNING_UPDATE_GOVERNANCE_REPORT.json, docs/plans/methodology/MASTER_PLAN_URK_LEARNING_UPDATE_GOVERNANCE_REPORT.md, lib/core/ai/urk_learning_update_governance_contract.dart, test/unit/ai/urk_learning_update_governance_contract_test.dart |
| M9-P3-3 | 3 | 9 | URK Reality Kernel: world-state coherence | baseline | none | shared | model_core | multi_mode | L4 | PRD-021, PRD-022, PRD-033, PRD-034 | 3.1.1, 3.4.4, 10.9.12 | lib/core/models | AP, MLE | AP | M9-P3-2 | 20 | Critical | Week 20-21 | Done | docs/plans/methodology/M9_P3_3_URK_REALITY_WORLD_STATE_COHERENCE_BASELINE.md, configs/runtime/urk_reality_world_state_coherence_controls.json, scripts/runtime/generate_urk_reality_world_state_coherence_report.py, docs/plans/methodology/MASTER_PLAN_URK_REALITY_WORLD_STATE_COHERENCE_REPORT.json, docs/plans/methodology/MASTER_PLAN_URK_REALITY_WORLD_STATE_COHERENCE_REPORT.md, lib/core/models/urk_reality_world_state_coherence_contract.dart, test/unit/models/urk_reality_world_state_coherence_contract_test.dart |
| M9-P5-2 | 5 | 9 | URK Reality Kernel: temporal truth alignment | baseline | none | shared | runtime_core | multi_mode | L4 | PRD-021, PRD-022, PRD-033, PRD-034 | 5.1.9, 7.7.5, 10.9.12 | lib/core/services/quantum | AP, MLE | AP | M9-P3-3 | 20 | Critical | Week 20-21 | Done | docs/plans/methodology/M9_P5_2_URK_REALITY_TEMPORAL_TRUTH_BASELINE.md, configs/runtime/urk_reality_temporal_truth_controls.json, scripts/runtime/generate_urk_reality_temporal_truth_report.py, docs/plans/methodology/MASTER_PLAN_URK_REALITY_TEMPORAL_TRUTH_REPORT.json, docs/plans/methodology/MASTER_PLAN_URK_REALITY_TEMPORAL_TRUTH_REPORT.md, lib/core/services/quantum/urk_reality_temporal_truth_contract.dart, test/unit/services/urk_reality_temporal_truth_contract_test.dart |
<!-- EXECUTION_BOARD:MILESTONE_BOARD_END -->

## URK Lane Snapshot

<!-- EXECUTION_BOARD:URK_LANES_START -->
### URK Runtime Type Lanes

| Lane | Total | Backlog | Ready | In Progress | Blocked | Done |
|------|------:|--------:|------:|------------:|--------:|-----:|
| `user_runtime` | 4 | 0 | 1 | 0 | 0 | 3 |
| `event_ops_runtime` | 12 | 0 | 1 | 0 | 0 | 11 |
| `business_ops_runtime` | 2 | 0 | 0 | 0 | 0 | 2 |
| `expert_services_runtime` | 1 | 0 | 0 | 0 | 0 | 1 |
| `shared` | 31 | 0 | 4 | 0 | 0 | 27 |

### URK Prong Lanes

| Lane | Total | Backlog | Ready | In Progress | Blocked | Done |
|------|------:|--------:|------:|------------:|--------:|-----:|
| `model_core` | 9 | 0 | 2 | 0 | 0 | 7 |
| `runtime_core` | 14 | 0 | 1 | 0 | 0 | 13 |
| `governance_core` | 16 | 0 | 0 | 0 | 0 | 16 |
| `cross_prong` | 11 | 0 | 3 | 0 | 0 | 8 |

### Privacy Mode Impact Lanes

| Lane | Total | Backlog | Ready | In Progress | Blocked | Done |
|------|------:|--------:|------:|------------:|--------:|-----:|
| `local_sovereign` | 1 | 0 | 1 | 0 | 0 | 0 |
| `private_mesh` | 3 | 0 | 0 | 0 | 0 | 3 |
| `federated_cloud` | 4 | 0 | 0 | 0 | 0 | 4 |
| `multi_mode` | 42 | 0 | 5 | 0 | 0 | 37 |

### Impact Tier Lanes

| Lane | Total | Backlog | Ready | In Progress | Blocked | Done |
|------|------:|--------:|------:|------------:|--------:|-----:|
| `L1` | 0 | 0 | 0 | 0 | 0 | 0 |
| `L2` | 6 | 0 | 1 | 0 | 0 | 5 |
| `L3` | 21 | 0 | 4 | 0 | 0 | 17 |
| `L4` | 23 | 0 | 1 | 0 | 0 | 22 |
<!-- EXECUTION_BOARD:URK_LANES_END -->

## Kanban Snapshot

<!-- EXECUTION_BOARD:KANBAN_START -->
### Backlog

None

### Ready

`M10-P10-4`, `M10-P10-5`, `M10-P10-6`, `M11-P3-1`, `M12-P10-3`, `M12-P10-4`

### In Progress

None

### Blocked

None

### Done

`M0-P10-1`, `M0-P10-2`, `M0-P10-3`, `M0-P2-1`, `M1-P7-1`, `M1-P7-2`, `M1-P8-1`, `M1-P8-2`, `M10-P10-3`, `M10-P11-1`, `M10-P11-2`, `M10-P3-1`, `M10-P6-1`, `M10-P7-1`, `M12-P10-1`, `M12-P10-2`, `M2-P1-1`, `M2-P3-1`, `M2-P4-1`, `M2-P5-1`, `M2-P6-1`, `M3-P11-1`, `M3-P9-1`, `M4-P3-1`, `M4-P3-2`, `M4-P3-3`, `M5-P3-1`, `M5-P3-2`, `M5-P3-3`, `M5-P3-4`, `M6-P3-1`, `M6-P3-2`, `M6-P3-3`, `M7-P7-3`, `M7-P7-4`, `M7-P8-3`, `M8-P10-4`, `M8-P11-2`, `M8-P9-2`, `M9-P10-1`, `M9-P10-2`, `M9-P3-2`, `M9-P3-3`, `M9-P5-2`
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
