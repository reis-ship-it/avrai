# M2-P1-1 Memory Reliability Gates Baseline

## Objective
Enforce deterministic memory reliability gates so schema consistency, dedupe, and replay integrity remain within policy before broader rollout.

## Baseline Artifacts
- Memory reliability config: `configs/runtime/memory_reliability_gates.json`
- Memory reliability report generator/check: `scripts/runtime/generate_memory_reliability_gates_report.py`
- Memory reliability report JSON: `docs/plans/methodology/MASTER_PLAN_MEMORY_RELIABILITY_GATES_REPORT.json`
- Memory reliability report Markdown: `docs/plans/methodology/MASTER_PLAN_MEMORY_RELIABILITY_GATES_REPORT.md`
- Memory reliability validator contract: `lib/core/ai/memory/memory_reliability_contract.dart`
- Memory reliability unit tests: `test/unit/ai/memory_reliability_contract_test.dart`

## Pass Contract
1. Config format valid (`version = v1`, deterministic `evaluation_at`, valid metric values).
2. Schema consistency missing-field rate is within threshold.
3. Dedupe duplicate rate is within threshold and counts reconcile.
4. Replay validation has zero failed deterministic scenarios.
5. Report `verdict` is `PASS`.

## CI Wiring
- `Execution Board Guard` runs memory reliability report in `--check` mode.

This baseline moves M2-P1-1 into active execution with deterministic schema/dedupe/replay governance evidence.
