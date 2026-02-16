# ML Training Automation Governance

## Purpose
Define one uniform workflow for all entity models (business, community, spot/place, event, locality, brand/sponsor, list) so:
- training readiness is machine-checkable,
- simulation experiments are staged and recorded,
- failed simulations auto-create improvement follow-up work,
- generated checklist docs stay synchronized for humans and AI agents.

## Canonical Sources
- `configs/ml/model_training_registry.csv`
- `configs/ml/feature_label_contracts.json`
- `configs/ml/avrai_native_type_contracts.json`
- `configs/ml/simulation_experiment_contracts.json`
- `configs/ml/simulation_experiment_runs.csv`

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
3. Record training completion with `scripts/ml/record_training_run.py`.
4. Regenerate/check docs with `scripts/generate_ml_training_checklist.py --check`.

## Writing Pattern Standard
All stage decisions must use this exact line format for consistency:

`<model_id> <stage> <pass_or_fail> <metric>=<value> threshold=<threshold> action=<next_action>`

This keeps logs concise, parseable, and reviewable by both humans and AI agents.
