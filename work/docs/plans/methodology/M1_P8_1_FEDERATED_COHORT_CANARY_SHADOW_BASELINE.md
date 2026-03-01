# M1-P8-1 Federated Cohort Canary/Shadow Baseline

## Objective
Enforce deterministic cohort-level canary/shadow promotion checks for federated updates before progression beyond canary.

## Baseline Artifacts
- Federated cohort pipeline config: `configs/runtime/federated_cohort_canary_shadow_pipeline.json`
- Federated cohort report generator/check: `scripts/runtime/generate_federated_cohort_canary_shadow_report.py`
- Federated cohort report JSON: `docs/plans/methodology/MASTER_PLAN_FEDERATED_COHORT_CANARY_SHADOW_REPORT.json`
- Federated cohort report Markdown: `docs/plans/methodology/MASTER_PLAN_FEDERATED_COHORT_CANARY_SHADOW_REPORT.md`

## Pass Contract
1. Config format valid (`version = v1`, deterministic `evaluation_at`, required policy/canary settings).
2. Required rollout stages (`shadow`, `canary`) are represented in cohort data.
3. Every cohort meets minimum sample thresholds.
4. Every cohort remains within max regression threshold and is not promotion-blocked.
5. Report `promotion_policy_enforced = true` and `verdict = PASS`.

## CI Wiring
- `Execution Board Guard` runs federated cohort report in `--check` mode.

This baseline moves M1-P8-1 into active execution with deterministic cohort no-regression + promotion policy evidence.
