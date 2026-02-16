# ML Training Automation Governance

## Purpose
Define one uniform workflow for all entity models (business, community, spot/place, event, locality, brand/sponsor, list) so:
- training readiness is machine-checkable,
- simulation experiments are staged and recorded,
- failed simulations auto-create improvement follow-up work,
- generated checklist docs stay synchronized for humans and AI agents.

Master authority alignment:
- `docs/MASTER_PLAN.md` -> `Universal Self-Healing Contract (All Reality/Universe Models)` and task `10.9.12` define mandatory break-to-learning behavior for any subsystem failure (not limited to ML).
- This governance doc implements the ML/training/simulation slice of that universal contract.

## Canonical Sources
- `configs/ml/model_training_registry.csv`
- `configs/ml/feature_label_contracts.json`
- `configs/ml/avrai_native_type_contracts.json`
- `configs/ml/simulation_experiment_contracts.json`
- `configs/ml/simulation_experiment_runs.csv`
- `configs/ml/learning_cycle_recovery_queue.csv`

## Generated Artifacts
- `docs/ML_MODEL_TRAINING_CHECKLIST.md`
- `docs/ML_SIMULATION_EXPERIMENT_LOG.md`

## Wiring Map (Human + AI Quick Reference)
Use this table as the canonical end-to-end wiring contract.

| Workflow Step | Source of Truth | Command | Generated/Updated Outputs | CI Gate |
|---|---|---|---|---|
| Register experiment scripts | `configs/experiments/EXPERIMENT_REGISTRY.csv` | `python3 scripts/generate_experiment_registry.py` | `docs/EXPERIMENT_REGISTRY.md` | `Experiment Registry Guard / experiment-registry` |
| Validate experiment registry | `configs/experiments/EXPERIMENT_REGISTRY.csv` | `python3 scripts/validate_experiment_registry.py` | Validation only | `Experiment Registry Guard / experiment-registry` |
| Define feature + label contracts | `configs/ml/feature_label_contracts.json` | N/A (authored) | Consumed by dataset builder + checklist generator | `ML Training Governance Guard / ml-training-governance` |
| Define AVRAI native type contracts | `configs/ml/avrai_native_type_contracts.json` | N/A (authored) | Consumed by dataset builder + checklist generator | `ML Training Governance Guard / ml-training-governance` |
| Build AVRAI-native dataset snapshot | Raw/curated input snapshot file | `python3 scripts/ml/build_training_dataset.py ...` | `data/training/<model_id>/<snapshot_id>/avrai_native_dataset.jsonl`, `manifest.json` | Required by governance policy for training snapshot PRs |
| Record simulation stage result | `configs/ml/simulation_experiment_runs.csv` | `python3 scripts/ml/record_simulation_run.py ...` | Updated simulation registry + regenerated logs | `ML Training Governance Guard / ml-training-governance` |
| Record training completion | `configs/ml/model_training_registry.csv` | `python3 scripts/ml/record_training_run.py ...` | Updated model registry + regenerated checklist/log | `ML Training Governance Guard / ml-training-governance` |
| Detect broken cycles + sync recovery queue | `configs/ml/learning_cycle_recovery_queue.csv` | `python3 scripts/ml/auto_recover_learning_cycles.py` | Open/resolve recovery items across all models/entities | `ML Training Governance Guard / ml-training-governance` |
| Auto-schedule fixes for broken cycles | `configs/ml/learning_cycle_recovery_queue.csv` + `configs/ml/simulation_experiment_runs.csv` | `python3 scripts/ml/auto_recover_learning_cycles.py --apply-fixes` | Schedules pending recovery runs + marks registry `recovering` | operational runbook |
| Regenerate/check canonical docs | ML registry/contract files | `python3 scripts/generate_ml_training_checklist.py` and `--check` | `docs/ML_MODEL_TRAINING_CHECKLIST.md`, `docs/ML_SIMULATION_EXPERIMENT_LOG.md` | `ML Training Governance Guard / ml-training-governance` |

## Operator Runbook (Single Follow Path)
1. Add or update experiment scripts, then run experiment registry generator/validator.
2. Prepare external/raw snapshot and convert it with `scripts/ml/build_training_dataset.py`.
3. Run staged simulation logging (`offline_replay`, then `shadow`, then `limited_rollout`).
4. If simulation gates pass, record training run in model registry.
5. Regenerate docs and run `--check` validation before PR.
6. Ensure PR includes one execution milestone (`M#-P#-#`) and relevant `X.Y.Z` refs.

Regenerate with:

```bash
python3 scripts/generate_ml_training_checklist.py
```

Verify in CI/local:

```bash
python3 scripts/generate_ml_training_checklist.py --check
```

## Uniform Data Logic
All entity models must follow the same training tuple contract:
- state + action + outcome + timestamp + consent + versioning
- required location coverage (`geohash`, `locality_code`, `city_code`, `timezone`)
- required type descriptors (entity taxonomy)
- required event scale descriptors (capacity, attendance, volume bands)
- required outcome labels (conversion, retention, risk)

## AVRAI-Native Continual-Learning Terms

Use AVRAI-native terms in plans/checklists and experiment metadata:
- `AnchorMind`: stable baseline checkpoint for continuity protection.
- `ExplorationMind`: adaptive model lane learning from recent trajectories.
- `ContinuityAlignment`: constraint/objective that keeps new learning compatible with validated prior behavior.
- `LiveTrajectoryLearning`: on-policy updates from AVRAI's own action/outcome streams.
- `DoorLossDrift`: catastrophic forgetting signal (legacy capability regression).
- `DoorContinuityGate`: mandatory no-regression promotion gate.
- `DoorLadderExpansion`: sequential capability-slice training protocol with per-slice gates.

Entity-specific required fields and minimum training gates are defined in:
- `configs/ml/feature_label_contracts.json`

## AVRAI-Native Conversion Standard
All training datasets must be converted into AVRAI-native records before simulation/training:
- one JSONL record per event tuple,
- stable `avrai_type` envelope per entity model,
- explicit blocks for knot/quantum/atomic states where applicable,
- gate manifest generated with null-rate and minimum-volume checks.

Canonical native type mappings:
- `business` -> `avrai.entity.business.frame.v1`
- `community` -> `avrai.entity.community.frame.v1`
- `spot` -> `avrai.entity.spot.frame.v1`
- `event` -> `avrai.entity.event.frame.v1`
- `locality` -> `avrai.entity.locality.frame.v1`
- `brand` -> `avrai.entity.brand.frame.v1`
- `list` -> `avrai.entity.list.frame.v1`
- `quantum_entanglement` -> `avrai.quantum.entanglement.frame.v1`
- `quantum_optimization` -> `avrai.quantum.optimization.frame.v1`
- `knot_string_worldsheet` -> `avrai.knot.worldsheet.frame.v1`
- `atomic_temporal` -> `avrai.quantum.atomic_temporal.frame.v1`

Conversion command:

```bash
python3 scripts/ml/build_training_dataset.py \
  --model-id mdl-knot-string-worldsheet-v1 \
  --snapshot-id ds_knot_worldsheet_20260216 \
  --input-path data/raw/knot_worldsheet_snapshot.jsonl \
  --input-format jsonl \
  --source-id overture_plus_internal
```

This produces:
- `data/training/<model_id>/<snapshot_id>/avrai_native_dataset.jsonl`
- `data/training/<model_id>/<snapshot_id>/manifest.json`

## Uniform Simulation Logic
Every model uses `sim-standard-v1` staged simulation policy:
1. `offline_replay`
2. `shadow`
3. `limited_rollout`

Each stage has explicit metrics, threshold direction, and gate values in:
- `configs/ml/simulation_experiment_contracts.json`

## Universal Break + Auto-Fix Logic
Learning cycles are expected to be interruptible (for any entity, model, or purpose) without manual workflow breakage.

Break detection is universal across all models in `configs/ml/model_training_registry.csv`:
- latest stage failure (`stage_fail`)
- registry degraded state (`needs_improvement`, `failed`, `broken`)
- active model missing required stage evidence (`missing_stage`)

Break telemetry expectations (must be inferable from run records + recovery queue):
- `what_broke`: stage, metric, threshold, and status transition
- `where_broke`: model id, entity type, stage lane
- `when_broke`: deterministic timestamp/run lineage
- `how_broke`: failure mode (`stage_fail`, `missing_stage`, degraded state)
- `why_broke`: notes + metric deltas + contract threshold mismatch

Recovery operations:
- detect/sync queue: `python3 scripts/ml/auto_recover_learning_cycles.py`
- schedule fixes automatically: `python3 scripts/ml/auto_recover_learning_cycles.py --apply-fixes`

Automatic hooks (default behavior):
- `scripts/ml/record_simulation_run.py` runs auto-recovery with `--apply-fixes` after each simulation update.
- `scripts/ml/record_training_run.py` runs auto-recovery sync after each training update.
- Use `--skip-auto-recovery` only for controlled/manual maintenance.

Auto-fix scheduling behavior:
- creates/updates deterministic recovery rows in `configs/ml/learning_cycle_recovery_queue.csv`
- appends pending simulation runs for affected stages in `configs/ml/simulation_experiment_runs.csv`
- marks affected model status as `recovering` in `configs/ml/model_training_registry.csv`
- auto-resolves queue rows when break conditions clear

## Auto-Recorded Operations
Record a completed training run:

```bash
python3 scripts/ml/record_training_run.py \
  --model-id mdl-business-energy-v1 \
  --dataset-snapshot-id ds_business_20260216 \
  --run-id run_business_20260216_001 \
  --metrics-json '{"auc":0.81,"calibration_error":0.05}' \
  --artifact-uri 'supabase://models/business/v1/model.onnx' \
  --rollback-artifact-uri 'supabase://models/business/v1/model_prev.onnx'
```

Record a simulation stage:

```bash
python3 scripts/ml/record_simulation_run.py \
  --model-id mdl-business-energy-v1 \
  --stage offline_replay \
  --status pass \
  --metric-name auc \
  --metric-value 0.81 \
  --threshold 0.72 \
  --direction gte \
  --notes 'Replay gate passed on latest snapshot'
```

If `--status fail`, the recorder will:
- auto-create a follow-up id,
- mark registry status as `needs_improvement`,
- surface the item in `docs/ML_SIMULATION_EXPERIMENT_LOG.md` under auto-improvement backlog.

Recommended end-to-end sequence:
1. Build AVRAI-native dataset with `scripts/ml/build_training_dataset.py`.
2. Record simulation stage(s) with `scripts/ml/record_simulation_run.py`.
3. Detect/sync recovery queue with `scripts/ml/auto_recover_learning_cycles.py`.
4. If broken cycles exist, schedule fixes with `scripts/ml/auto_recover_learning_cycles.py --apply-fixes`.
5. Record training completion with `scripts/ml/record_training_run.py`.
6. Regenerate/check docs with `scripts/generate_ml_training_checklist.py --check`.

## Writing Pattern Standard
All stage decisions must use this exact line format for consistency:

`<model_id> <stage> <pass_or_fail> <metric>=<value> threshold=<threshold> action=<next_action>`

This keeps logs concise, parseable, and reviewable by both humans and AI agents.
