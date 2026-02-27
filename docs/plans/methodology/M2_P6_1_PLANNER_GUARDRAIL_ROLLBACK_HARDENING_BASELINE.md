# M2-P6-1 Planner Guardrail and Rollback-Hardening Baseline

## Objective
Enforce deterministic planner guardrail and rollback-hardening governance so hard-constraint compliance and rollback drill readiness remain within policy.

## Baseline Artifacts
- Planner guardrail/rollback config: `configs/runtime/planner_guardrail_rollback_hardening_controls.json`
- Planner guardrail/rollback report generator/check: `scripts/runtime/generate_planner_guardrail_rollback_hardening_report.py`
- Planner guardrail/rollback report JSON: `docs/plans/methodology/MASTER_PLAN_PLANNER_GUARDRAIL_ROLLBACK_HARDENING_REPORT.json`
- Planner guardrail/rollback report Markdown: `docs/plans/methodology/MASTER_PLAN_PLANNER_GUARDRAIL_ROLLBACK_HARDENING_REPORT.md`
- Planner guardrail/rollback contract: `lib/core/ai/planner_guardrail_rollback_contract.dart`
- Planner guardrail/rollback tests: `test/unit/ai/planner_guardrail_rollback_contract_test.dart`

## Pass Contract
1. Config format valid (`version = v1`, deterministic `evaluation_at`, valid thresholds).
2. Planner hard-constraint violation rate remains within threshold.
3. Rollback drill success and recovery latency remain within threshold.
4. Atomic rollback bundle integrity checks pass.
5. Contract tests pass and report `verdict` is `PASS`.

## CI Wiring
- `Execution Board Guard` runs planner guardrail/rollback report in `--check` mode.

This baseline closes M2-P6-1 with deterministic planner-guardrail and rollback-hardening governance evidence.
