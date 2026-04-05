# PRD + Execution Board Integration Guide

**Purpose:** Keep board execution synchronized with PRD requirements and eliminate drift.

Primary workflow runbook for experiment/training operations:
- `docs/plans/methodology/ML_TRAINING_AUTOMATION_GOVERNANCE.md` (`Wiring Map` + `Operator Runbook`)
Cross-doc synchronization authority:
- `docs/plans/methodology/BUILD_DOCS_WIRING_INDEX.md`

## Required Metadata per Execution Milestone

- `milestone_id`: `M#-P#-#`
- `prd_ids`: one or more `PRD-###`
- `master_plan_refs`: one or more `X.Y.Z`
- `architecture_spot`: from `docs/plans/architecture/ARCHITECTURE_SPOTS_REGISTRY.csv`
  - active phases and new milestones should prefer current 3-prong spots such as `apps/avrai_app`, `runtime/avrai_runtime_os`, `engine/reality_engine`, `shared/avrai_core`, or `docs/plans/architecture`
  - completed historical milestones may intentionally retain legacy aliases such as `lib/core/...` when those aliases are preserved in the registry for backward-compatible execution-board history
- `change_type`: `baseline` or `reopen`
- `reopens_milestone`: `none` for baseline; required `M#-P#-#` for reopen
- `urk_runtime_type`: `user_runtime|event_ops_runtime|business_ops_runtime|expert_services_runtime|shared`
- `urk_prong`: `model_core|runtime_core|governance_core|cross_prong`
- `privacy_mode_impact`: `local_sovereign|private_mesh|federated_cloud|multi_mode`
- `impact_tier_max`: `L1|L2|L3|L4`

Store this metadata directly in `docs/EXECUTION_BOARD.csv` milestone rows (`prd_ids`, `master_plan_refs`, `architecture_spot`, `urk_runtime_type`, `urk_prong`, `privacy_mode_impact`, `impact_tier_max`).
Use `docs/agents/status/BOARD_PRD_MAPPING_TEMPLATE.csv` only as an optional working scratchpad.

Reference authority:
- `docs/plans/architecture/UNIFIED_RUNTIME_KERNEL_BLUEPRINT_2026-02-27.md`
- `docs/plans/architecture/URK_INTERFACE_CONTRACTS_2026-02-27.md`

Reopen-by-new-milestone protocol:
- Never mutate a `Done` milestone back to active.
- Create a new milestone row with `change_type=reopen` and `reopens_milestone=<done milestone id>`.
- Log the event in `docs/STATUS_WEEKLY.md` under `1B) Reopen-By-New-Milestone Events`.
- Add program-level context in `docs/agents/status/status_tracker.md`.

## Required Metadata per Pull Request

Every PR must include in title/body:

- At least one `PRD-###`
- Exactly one `M#-P#-#`
- At least one `X.Y.Z`

Every PR must include URK tags (use `shared/cross_prong/multi_mode` when not specific):

- `URK-RUNTIME:<runtime_type>`
- `URK-PRONG:<prong>`
- `URK-MODE:<privacy_mode or multi_mode>`
- `URK-IMPACT:<L1|L2|L3|L4>`

CI enforcement:

- `.github/workflows/prd-traceability-guard.yml`
- `scripts/validate_pr_traceability.py`
- `.github/workflows/experiment-registry-guard.yml`
- `scripts/validate_experiment_registry.py`
- `.github/workflows/ml-training-governance-guard.yml`
- `scripts/generate_ml_training_checklist.py --check`

PR traceability guard now enforces URK tags in addition to PRD/milestone/master-plan refs.

Universal self-healing authority:
- `docs/MASTER_PLAN.md` -> `Universal Self-Healing Contract (All Reality/Universe Models)` and task `10.9.12`.
- PRs that modify adaptive/federated/reasoning/training/simulation behavior must preserve break-to-learning coverage (`what`, `where`, `when`, `how`, `why`) and auto-remediation traceability.

## Workflow

1. Create/update execution-board milestone row with `M#-P#-#` ID and PRD IDs.
2. Implement code with Master Plan phase ownership.
3. Open PR containing `PRD-###` + one `M#-P#-#` + `X.Y.Z` + URK tags.
4. Pass CI guards:
   - Execution Board Guard
   - PRD Traceability Guard
   - Experiment Registry Guard (when experiment files/docs are touched)
   - ML Training Governance Guard (when model-training or simulation files/docs are touched)
   - Execution board URK quality guard (`python3 scripts/validate_execution_board_urk_quality.py`)
5. Move milestone to `Done` only when PR merged and acceptance criteria are met with evidence links.

## Experiment + Training Linkage Rules

1. Every experiment script must be tracked in `configs/experiments/EXPERIMENT_REGISTRY.csv` and rendered in `docs/EXPERIMENT_REGISTRY.md`.
2. Renames must preserve lineage by keeping `legacy_path` and moving users to canonical execution through `scripts/experiments/run_experiment.py`.
3. Every model training run must be appended to `configs/ml/model_training_registry.csv` and surfaced through `docs/ML_MODEL_TRAINING_CHECKLIST.md`.
4. Every simulation run must be appended to `configs/ml/simulation_experiment_runs.csv` and surfaced through `docs/ML_SIMULATION_EXPERIMENT_LOG.md`.
5. Training datasets for all entities must be converted to AVRAI-native type envelopes via `scripts/ml/build_training_dataset.py`, using `configs/ml/avrai_native_type_contracts.json` and `configs/ml/feature_label_contracts.json` as authority.
6. Break/reopen remediation milestones must remain traceable through execution-board metadata and weekly status logs; if a completed milestone is reopened by new research, use `change_type=reopen` + `reopens_milestone=<done milestone>` and link the healing/remediation evidence path.
