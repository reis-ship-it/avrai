# M0-P10-3 Split-Pass CI Guard/Contract Hardening Baseline

## Objective
Enforce deterministic split-pass CI guard and contract-hardening checks so execution-board governance commands remain present and synchronized as milestone coverage expands.

## Baseline Artifacts
- Split-pass CI guard config: `configs/runtime/split_pass_ci_guard_contract_hardening_controls.json`
- Split-pass CI guard report generator/check: `scripts/runtime/generate_split_pass_ci_guard_contract_hardening_report.py`
- Split-pass CI guard report JSON: `docs/plans/methodology/MASTER_PLAN_SPLIT_PASS_CI_GUARD_CONTRACT_HARDENING_REPORT.json`
- Split-pass CI guard report Markdown: `docs/plans/methodology/MASTER_PLAN_SPLIT_PASS_CI_GUARD_CONTRACT_HARDENING_REPORT.md`

## Pass Contract
1. Config format valid (`version = v1`, deterministic `evaluation_at`).
2. Required execution-board guard commands are present in `.github/workflows/execution-board-guard.yml`.
3. No required command is duplicated or missing.
4. Report `verdict` is `PASS`.

## CI Wiring
- `Execution Board Guard` runs split-pass CI guard report in `--check` mode.

This baseline closes M0-P10-3 with deterministic split-pass guard/contract hardening evidence.
