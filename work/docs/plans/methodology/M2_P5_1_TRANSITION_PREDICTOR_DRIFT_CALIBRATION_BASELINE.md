# M2-P5-1 Transition Predictor Drift/Calibration Controls Baseline

## Objective
Enforce deterministic transition-predictor drift and calibration governance so prediction residual drift and confidence-vs-outcome calibration stay within threshold before rollout.

## Baseline Artifacts
- Transition drift/calibration config: `configs/runtime/transition_predictor_drift_calibration_controls.json`
- Transition drift/calibration report generator/check: `scripts/runtime/generate_transition_predictor_drift_calibration_report.py`
- Transition drift/calibration report JSON: `docs/plans/methodology/MASTER_PLAN_TRANSITION_PREDICTOR_DRIFT_CALIBRATION_REPORT.json`
- Transition drift/calibration report Markdown: `docs/plans/methodology/MASTER_PLAN_TRANSITION_PREDICTOR_DRIFT_CALIBRATION_REPORT.md`
- Transition drift/calibration contract: `lib/core/ml/transition_predictor_drift_calibration_contract.dart`
- Transition drift/calibration contract tests: `test/unit/ml/transition_predictor_drift_calibration_contract_test.dart`

## Pass Contract
1. Config format valid (`version = v1`, deterministic `evaluation_at`, valid thresholds).
2. Residual drift EMA remains within configured threshold.
3. Calibration gap remains within configured threshold.
4. Confidence-vs-outcome divergence gate remains clear.
5. Contract tests pass and report `verdict` is `PASS`.

## CI Wiring
- `Execution Board Guard` runs transition predictor drift/calibration report in `--check` mode.

This baseline closes M2-P5-1 with deterministic drift/error and uncertainty calibration governance evidence.
