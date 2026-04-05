# M1-P7-2 Controller/Orchestrator Reliability Baseline

## Objective
Enforce deterministic controller/orchestrator reliability checks so no dead orchestration paths are shipped and canary error budget remains within threshold.

## Baseline Artifacts
- Reliability canary config: `configs/runtime/controller_orchestrator_reliability_canary.json`
- Reliability report generator/check: `scripts/runtime/generate_controller_orchestrator_reliability_report.py`
- Reliability report JSON: `docs/plans/methodology/MASTER_PLAN_CONTROLLER_ORCHESTRATOR_RELIABILITY_REPORT.json`
- Reliability report Markdown: `docs/plans/methodology/MASTER_PLAN_CONTROLLER_ORCHESTRATOR_RELIABILITY_REPORT.md`

## Pass Contract
1. Config format valid (`version = v1`, deterministic `evaluation_at`, valid error budget values).
2. All listed controller/orchestrator assertions specify primary + fallback routing paths.
3. `dead_paths_detected = 0`.
4. Observed canary error rate remains within configured error budget threshold.
5. Report `verdict` is `PASS`.

## CI Wiring
- `Execution Board Guard` runs controller/orchestrator reliability report in `--check` mode.

This baseline moves M1-P7-2 into active execution with deterministic dead-path + canary-budget governance evidence.
