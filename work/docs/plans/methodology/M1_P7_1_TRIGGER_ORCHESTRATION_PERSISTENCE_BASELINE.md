# M1-P7-1 Trigger + Orchestration Persistence Hardening Baseline

## Objective
Enforce deterministic trigger reliability and orchestration persistence checks so dropped-trigger rate, duplicate handling, and state persistence recovery stay within SLO.

## Baseline Artifacts
- Trigger/orchestration persistence config: `configs/runtime/trigger_orchestration_persistence_hardening_controls.json`
- Trigger/orchestration persistence report generator/check: `scripts/runtime/generate_trigger_orchestration_persistence_report.py`
- Trigger/orchestration persistence report JSON: `docs/plans/methodology/MASTER_PLAN_TRIGGER_ORCHESTRATION_PERSISTENCE_REPORT.json`
- Trigger/orchestration persistence report Markdown: `docs/plans/methodology/MASTER_PLAN_TRIGGER_ORCHESTRATION_PERSISTENCE_REPORT.md`
- Trigger/orchestration persistence contract: `lib/core/controllers/trigger_orchestration_persistence_contract.dart`
- Trigger/orchestration persistence tests: `test/unit/controllers/trigger_orchestration_persistence_contract_test.dart`

## Pass Contract
1. Config format valid (`version = v1`, deterministic `evaluation_at`, valid thresholds).
2. Dropped-trigger and duplicate-trigger rates stay within configured SLO thresholds.
3. Idempotency/replay-on-restart checks pass with no unrecovered persistent state records.
4. Trigger-to-action latency p95 stays within configured threshold.
5. Contract tests pass and report `verdict` is `PASS`.

## CI Wiring
- `Execution Board Guard` runs trigger/orchestration persistence report in `--check` mode.

This baseline closes M1-P7-1 with deterministic trigger reliability and orchestration persistence governance evidence.
