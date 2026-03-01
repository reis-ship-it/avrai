# M9-P5-2 URK Reality Kernel: Temporal Truth Baseline

## Objective
Enforce temporal truth alignment between atomic and semantic time so timezone normalization is deterministic and timeline contradictions are blocked.

## Baseline Artifacts
- Controls config: `configs/runtime/urk_reality_temporal_truth_controls.json`
- Report generator/check: `scripts/runtime/generate_urk_reality_temporal_truth_report.py`
- Report JSON: `docs/plans/methodology/MASTER_PLAN_URK_REALITY_TEMPORAL_TRUTH_REPORT.json`
- Report Markdown: `docs/plans/methodology/MASTER_PLAN_URK_REALITY_TEMPORAL_TRUTH_REPORT.md`
- Contract: `lib/core/services/quantum/urk_reality_temporal_truth_contract.dart`
- Tests: `test/unit/services/urk_reality_temporal_truth_contract_test.dart`

## Pass Contract
1. Atomic/semantic alignment and timezone normalization coverage meet required thresholds.
2. Temporal contradiction and clock regression events remain within threshold bounds.
3. Contract tests pass and report `verdict` is `PASS`.

## CI Wiring
- `Execution Board Guard` runs this report in `--check` mode.
