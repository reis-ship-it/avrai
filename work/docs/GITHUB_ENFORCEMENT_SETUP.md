# GitHub Enforcement Setup (Execution Board + Traceability)

Purpose: make execution-governance rules automatic for all plan-derived work.

Primary workflow runbook (human + AI): `docs/plans/methodology/ML_TRAINING_AUTOMATION_GOVERNANCE.md` (`Wiring Map` + `Operator Runbook` sections).
Canonical cross-doc wiring map: `docs/plans/methodology/BUILD_DOCS_WIRING_INDEX.md`.

Universal resilience authority:
- `docs/MASTER_PLAN.md` -> `Universal Self-Healing Contract (All Reality/Universe Models)` + task `10.9.12`
- Any break across perception/ingest/reasoning/memory/planner/federated-sync/advisory/rollout/communication must enter break-to-learning remediation flow before merge closure.
- Red-team security authority: `docs/security/RED_TEAM_TEST_MATRIX.md` + task `10.9.20` (critical lanes are release-blocking for autonomous scope expansion).

Applies to:
- `docs/MASTER_PLAN.md`
- `docs/EXECUTION_BOARD.csv`
- `docs/EXECUTION_BOARD.md`
- `docs/STATUS_WEEKLY.md`
- `docs/plans/architecture/UNIFIED_RUNTIME_KERNEL_BLUEPRINT_2026-02-27.md`
- `docs/plans/architecture/URK_INTERFACE_CONTRACTS_2026-02-27.md`
- `docs/plans/methodology/BUILD_DOCS_WIRING_INDEX.md`
- `configs/runtime/kernel_registry.json`
- `docs/admin/URK_KERNEL_CATALOG.md`
- `docs/EXPERIMENT_REGISTRY.md`
- `docs/ML_MODEL_TRAINING_CHECKLIST.md`
- `docs/ML_SIMULATION_EXPERIMENT_LOG.md`

## 1) Required Workflows

Ensure these workflows exist and are green on pull requests:

1. `Execution Board Guard`
   - File: `.github/workflows/execution-board-guard.yml`
   - Check name: `Execution Board Guard / execution-board-check`
   - Enforces:
     - board sync validity (`dart run tool/update_execution_board.dart --check`)
     - URK board metadata quality (`python3 scripts/validate_execution_board_urk_quality.py`)
     - URK Stage A trigger/privacy/no-egress baseline report check (`python3 scripts/runtime/generate_urk_stage_a_trigger_privacy_no_egress_report.py --check`)
     - URK Stage B Event Ops shadow runtime report check (`python3 scripts/runtime/generate_urk_stage_b_event_ops_shadow_runtime_report.py --check`)
     - URK Stage C private-mesh policy conformance report check (`python3 scripts/runtime/generate_urk_stage_c_private_mesh_policy_conformance_report.py --check`)
     - URK Stage D business runtime replication report check (`python3 scripts/runtime/generate_urk_stage_d_business_runtime_replication_report.py --check`)
     - URK Stage D expert runtime replication report check (`python3 scripts/runtime/generate_urk_stage_d_expert_runtime_replication_report.py --check`)
     - URK Stage E cross-runtime conformance report check (`python3 scripts/runtime/generate_urk_stage_e_cross_runtime_conformance_report.py --check`)
     - URK kernel promotion lifecycle report check (`python3 scripts/runtime/generate_urk_kernel_promotion_lifecycle_report.py --check`)
     - URK learning update governance report check (`python3 scripts/runtime/generate_urk_learning_update_governance_report.py --check`)
     - URK reality world-state coherence report check (`python3 scripts/runtime/generate_urk_reality_world_state_coherence_report.py --check`)
     - URK reality temporal truth report check (`python3 scripts/runtime/generate_urk_reality_temporal_truth_report.py --check`)
     - URK self-learning governance report check (`python3 scripts/runtime/generate_urk_self_learning_governance_report.py --check`)
     - URK self-healing recovery report check (`python3 scripts/runtime/generate_urk_self_healing_recovery_report.py --check`)
     - URK learning-healing bridge report check (`python3 scripts/runtime/generate_urk_learning_healing_bridge_report.py --check`)
     - URK kernel activation engine report check (`python3 scripts/runtime/generate_urk_kernel_activation_engine_report.py --check`)
     - URK kernel control-plane report check (`python3 scripts/runtime/generate_urk_kernel_control_plane_report.py --check`)
     - URK runtime activation receipt dispatch report check (`python3 scripts/runtime/generate_urk_runtime_activation_receipt_dispatch_report.py --check`)
     - URK kernel registry completeness check (`python3 scripts/runtime/check_urk_kernel_registry.py`)
     - URK kernel catalog sync check (`python3 scripts/runtime/generate_urk_kernel_catalog.py --check`)
     - phase coverage parity with `docs/MASTER_PLAN.md`
     - architecture mapping + spot registry validity (`scripts/validate_architecture_placement.py`)
     - generated architecture artifacts are committed

2. `PRD Traceability Guard`
   - File: `.github/workflows/prd-traceability-guard.yml`
   - Check name: `PRD Traceability Guard / traceability`
   - Enforces PR metadata includes:
     - `PRD-###`
     - exactly one execution milestone ID format `M#-P#-#` in the PR title
     - at least one master plan subsection reference `X.Y.Z`
     - every non-merge PR commit includes the same milestone ID + at least one `X.Y.Z` reference

3. `Experiment Registry Guard`
   - File: `.github/workflows/experiment-registry-guard.yml`
   - Check name: `Experiment Registry Guard / experiment-registry`
   - Enforces:
     - canonical experiment inventory generation is current (`python3 scripts/generate_experiment_registry.py --check`)
     - every tracked experiment has canonical naming and stage-contract metadata (`python3 scripts/validate_experiment_registry.py`)
     - legacy-to-canonical path migration mappings stay deterministic

4. `ML Training Governance Guard`
   - File: `.github/workflows/ml-training-governance-guard.yml`
   - Check name: `ML Training Governance Guard / ml-training-governance`
   - Enforces:
     - model/simulation registries stay synced with generated docs (`python3 scripts/generate_ml_training_checklist.py --check`)
     - training/simulation run records are append-only and traceable

5. `Legacy Path Guard`
   - File: `.github/workflows/legacy-path-guard.yml`
   - Check name: `Legacy Path Guard / legacy-path-guard`
   - Enforces:
     - new/changed legacy-path files (`lib/core/**`, `lib/domain/**`, `lib/data/**`, `lib/di/**`, `lib/presentation/**`) must either:
       - move to target roots (`apps/`, `runtime/`, `engine/`, `shared/`), or
       - include temporary shim marker (`MIGRATION_SHIM:`), or
       - be explicitly listed in `configs/runtime/legacy_path_guard.json` allowlist.

6. `Consumer App CI/CD`
   - File: `.github/workflows/consumer-app-ci-cd.yml`
   - Check name: `Consumer App CI/CD / Consumer Quality`
   - Enforces:
     - `apps/consumer_app` dependency resolution
     - `flutter analyze`
     - `flutter test`

7. `Admin App CI/CD`
   - File: `.github/workflows/admin-app-ci-cd.yml`
   - Check name: `Admin App CI/CD / Admin Quality`
   - Enforces:
     - `apps/admin_app` dependency resolution
     - `flutter analyze`
     - `flutter test`

Execution board schema expectations (enforced by `tool/update_execution_board.dart`):
- Milestone rows must include:
  - `prd_ids` (one or more `PRD-###`)
  - `master_plan_refs` (one or more `X.Y.Z`)
  - `architecture_spot` (registered spot key)
  - `change_type` (`baseline` or `reopen`)
  - `reopens_milestone` (`none` for baseline; required milestone ID for reopen)
  - `urk_runtime_type` (`user_runtime|event_ops_runtime|business_ops_runtime|expert_services_runtime|shared`)
  - `urk_prong` (`model_core|runtime_core|governance_core|cross_prong`)
  - `privacy_mode_impact` (`local_sovereign|private_mesh|federated_cloud|multi_mode`)
  - `impact_tier_max` (`L1|L2|L3|L4`)
- Milestone dependencies must be milestone IDs (`M#-P#-#`) or `none`
- A phase marked `Ready` must have at least one active milestone (`Ready`/`In Progress`/`Done`)
- Reopen milestones must reference a prior `Done` milestone and be recorded in `docs/STATUS_WEEKLY.md`

Optional PR quality workflow:
6. `Quick Tests`
   - File: `.github/workflows/quick-tests.yml`
   - Use as required check only if you want stricter merge quality gates.

## 1.1 Noise-Controlled Workflow Policy (Recommended)

To avoid CI email spam and non-actionable failures, this repo is configured with:
- PR-focused automatic workflows for governance and quality.
- Manual-only (`workflow_dispatch`) for heavy/legacy/operational workflows.

Manual-only workflows (intentionally not automatic):
- `SPOTS Background Testing`
- `SPOTS Background Testing (Optimized)`
- `Auto-Apply Background Agent Fixes`
- `Storage health`
- `Deploy SPOTS`

PR-triggered workflows (automatic):
- `Execution Board Guard`
- `PRD Traceability Guard`
- `Experiment Registry Guard`
- `ML Training Governance Guard`
- `Legacy Path Guard`
- `Consumer App CI/CD`
- `Admin App CI/CD`
- `Architecture Placement Guard`
- `Quick Tests` (PR path-filtered + manual)
- `Test Coverage Report` (PR path-filtered + manual)
- `Test Quality Check` (PR path-filtered + manual)

## 2) Branch Protection (GitHub UI)

Repository settings:
1. `Settings` -> `Branches` -> `Add branch protection rule`
2. Branch name pattern: `main`
3. Enable:
   - `Require a pull request before merging`
   - `Require status checks to pass before merging`
   - `Require branches to be up to date before merging`
4. In required checks, add:
   - `Execution Board Guard / execution-board-check`
   - `PRD Traceability Guard / traceability`
   - `Experiment Registry Guard / experiment-registry`
   - `ML Training Governance Guard / ml-training-governance`
   - `Legacy Path Guard / legacy-path-guard`
   - `Consumer App CI/CD / Consumer Quality`
   - `Admin App CI/CD / Admin Quality`
5. Optional required checks:
   - `Quick Tests / quick-unit-tests`
6. Optional but recommended:
   - `Require conversation resolution before merging`
   - `Include administrators`
   - `Restrict who can push to matching branches`

Notes:
- You do not need to add `Architecture Placement Guard / architecture-placement` as a separate required check if `execution-board-check` is required, because architecture placement validation is now part of `execution-board-check`.
- Keeping `Architecture Placement Guard` enabled is still useful for standalone troubleshooting visibility.
- Admin app is internal-use only because it exposes privileged governance controls, sensitive telemetry/decision traces, and administrative mutation paths that are not consumer-safe; keep external distribution/release checks optional unless internal policy changes.

## 3) PR Author Checklist

Every PR touching plan-derived work must:
1. Reference PRD IDs (`PRD-###`)
2. Reference exactly one execution milestone ID (`M#-P#-#`) in the PR title
3. Reference master plan subsection IDs (`X.Y.Z`)
4. Include URK tags in title/body:
   - `URK-RUNTIME:<user_runtime|event_ops_runtime|business_ops_runtime|expert_services_runtime|shared>`
   - `URK-PRONG:<model_core|runtime_core|governance_core|cross_prong>`
   - `URK-MODE:<local_sovereign|private_mesh|federated_cloud|multi_mode>`
   - `URK-IMPACT:<L1|L2|L3|L4>`
5. Ensure every non-merge commit message includes the same milestone ID + at least one `X.Y.Z` reference
6. Update evidence links for milestones moved to `Done`
7. Pass `Execution Board Guard` and `PRD Traceability Guard`
8. If the PR touches experiments or model training docs/scripts, pass `Experiment Registry Guard` and `ML Training Governance Guard`
9. If the PR touches legacy paths, pass `Legacy Path Guard` using migration shim markers or target-path moves

Template:
- `.github/pull_request_template.md` already includes these fields.

## 4) Local Pre-PR Commands

Run before opening or updating a PR:

```bash
dart run tool/update_execution_board.dart
dart run tool/update_execution_board.dart --check
python3 scripts/generate_master_plan_file_mapping.py
python3 scripts/generate_architecture_spots_registry.py
python3 scripts/validate_architecture_placement.py
python3 scripts/validate_execution_board_urk_quality.py
python3 scripts/ci/check_legacy_path_guard.py --base-ref main
python3 scripts/runtime/generate_urk_stage_a_trigger_privacy_no_egress_report.py --check
python3 scripts/runtime/generate_urk_stage_b_event_ops_shadow_runtime_report.py --check
python3 scripts/runtime/generate_urk_stage_c_private_mesh_policy_conformance_report.py --check
python3 scripts/runtime/generate_urk_stage_d_business_runtime_replication_report.py --check
python3 scripts/runtime/generate_urk_stage_d_expert_runtime_replication_report.py --check
python3 scripts/runtime/generate_urk_stage_e_cross_runtime_conformance_report.py --check
python3 scripts/runtime/generate_urk_kernel_promotion_lifecycle_report.py --check
python3 scripts/runtime/generate_urk_learning_update_governance_report.py --check
python3 scripts/runtime/generate_urk_reality_world_state_coherence_report.py --check
python3 scripts/runtime/generate_urk_reality_temporal_truth_report.py --check
python3 scripts/runtime/generate_urk_self_learning_governance_report.py --check
python3 scripts/runtime/generate_urk_self_healing_recovery_report.py --check
python3 scripts/runtime/generate_urk_learning_healing_bridge_report.py --check
python3 scripts/runtime/generate_urk_kernel_activation_engine_report.py --check
python3 scripts/runtime/generate_urk_kernel_control_plane_report.py --check
python3 scripts/runtime/generate_urk_runtime_activation_receipt_dispatch_report.py --check
python3 scripts/runtime/generate_urk_user_runtime_learning_intake_report.py --check
python3 scripts/runtime/check_urk_kernel_registry.py
python3 scripts/runtime/generate_urk_kernel_catalog.py --check
python3 scripts/generate_experiment_registry.py
python3 scripts/generate_experiment_registry.py --check
python3 scripts/validate_experiment_registry.py
python3 scripts/generate_ml_training_checklist.py
python3 scripts/generate_ml_training_checklist.py --check
python3 scripts/ml/auto_recover_learning_cycles.py
python3 scripts/ml/auto_recover_learning_cycles.py --check
# Per-model dataset build (run for PRs that add/update training snapshots):
python3 scripts/ml/build_training_dataset.py \
  --model-id <model_id> \
  --snapshot-id <snapshot_id> \
  --input-path <dataset.jsonl_or_csv> \
  --input-format <jsonl|csv> \
  --source-id <source_tag>
python3 scripts/validate_pr_traceability.py \
  --title "PRD-123 M1-P7-1" \
  --body "phase/task refs: 7.4.2, 10.9.1 URK-RUNTIME:shared URK-PRONG:cross_prong URK-MODE:multi_mode URK-IMPACT:L2" \
  --require-execution-id \
  --require-single-milestone \
  --require-master-plan-ref \
  --require-urk-tags

# Optional full boundary check against current branch:
python3 scripts/validate_pr_traceability.py \
  --title "PRD-123 M1-P7-1" \
  --body "phase/task refs: 7.4.2, 10.9.1 URK-RUNTIME:shared URK-PRONG:cross_prong URK-MODE:multi_mode URK-IMPACT:L2" \
  --require-execution-id \
  --require-single-milestone \
  --require-master-plan-ref \
  --require-urk-tags \
  --validate-commit-boundaries \
  --base-sha origin/main \
  --head-sha HEAD
```

## 5) Operating Rules (Phase 1-N)

1. `docs/EXECUTION_BOARD.csv` is the canonical execution state.
2. `docs/EXECUTION_BOARD.md` is generated/synced output.
3. No plan-derived work merges without exactly one milestone mapping per PR.
4. Every non-merge commit must include milestone ID + `X.Y.Z` subsection reference.
5. No milestone transitions to `Done` without evidence.
6. Milestone metadata columns are mandatory: `prd_ids`, `master_plan_refs`, `architecture_spot`, `urk_runtime_type`, `urk_prong`, `privacy_mode_impact`, `impact_tier_max`.
7. Reopen tracking columns are mandatory: `change_type`, `reopens_milestone`.
8. Reopen events must create a new milestone (`change_type=reopen`) and reference a prior `Done` milestone.
9. Reopen events must be logged in `docs/STATUS_WEEKLY.md` (`1B) Reopen-By-New-Milestone Events`) and reflected in `docs/agents/status/status_tracker.md`.
10. Milestone dependencies must be milestone IDs (`M#-P#-#`) or `none`.
11. A phase marked `Ready` must have at least one active milestone (`Ready`/`In Progress`/`Done`).
12. New plan phases require same-PR board expansion:
phase row + milestone row(s) + risk + gate criteria.
13. New/renamed experiments must be reflected in `configs/experiments/EXPERIMENT_REGISTRY.csv` and `docs/EXPERIMENT_REGISTRY.md` in the same PR.
14. Model training/simulation changes must update `configs/ml/model_training_registry.csv`, `configs/ml/simulation_experiment_runs.csv`, and regenerated checklist/log docs in the same PR.
15. Training snapshot PRs must include AVRAI-native conversion outputs (`data/training/<model_id>/<snapshot_id>/avrai_native_dataset.jsonl` + `manifest.json`) generated by `scripts/ml/build_training_dataset.py`.
16. Any PR that touches adaptive, federated, world-model, experiment, or training logic must satisfy Universal Self-Healing Contract behavior (`docs/MASTER_PLAN.md`, `10.9.12`) by ensuring break classes are detectable, recoverable, and fed back into learning metrics.
17. Break-to-learning queue integrity must pass (`python3 scripts/ml/auto_recover_learning_cycles.py --check`) with no unresolved schema or deterministic-linkage errors.
18. Security/privacy/autonomy-critical PRs must update or reference `docs/security/RED_TEAM_TEST_MATRIX.md` evidence lanes and must not merge when any mapped critical lane is red without explicit governance override.

## 6) Troubleshooting

1. Check fails with "board out of sync":
   - Run: `dart run tool/update_execution_board.dart`
   - Commit regenerated `docs/EXECUTION_BOARD.md`

2. Check fails with "missing phase row":
   - Add missing phase row to `docs/EXECUTION_BOARD.csv`
   - Re-run sync/check commands

3. Traceability check fails:
   - Add `PRD-###` and exactly one `M#-P#-#` ID to PR title/body
   - Add at least one `X.Y.Z` reference to PR title/body
   - Add URK tags: `URK-RUNTIME`, `URK-PRONG`, `URK-MODE`, `URK-IMPACT`
   - Ensure each non-merge commit message contains the same milestone + an `X.Y.Z` reference
   - Keep formatting exact

4. Local `dart run tool/update_execution_board.dart --check` fails in sandboxed environments:
   - Symptom: permission error writing Flutter/Dart cache files (for example `engine.stamp`).
   - Why: some local sandbox/runner setups block writes outside the repo.
   - Impact: local-only environment issue; CI on GitHub Actions is unaffected.
   - Workaround:
     - Run the same command with sufficient local permissions.
     - If your environment enforces sandboxing, allow this command prefix in your runner policy.
