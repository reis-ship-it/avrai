# M31-P10-2 Baseline: Apps Wave 31 Shell Hardening + Contract-Consumer Adapters

Date: 2026-03-31
Milestone: M31-P10-2
Master Plan refs: 10.1.6, 10.10.9, 10.10.11, 10.10.12

## Scope

Close the remaining wave-31 Apps lane governance package after the umbrella dependency lock by hardening consumer/admin shell boundary documentation and codifying contract-consumer adapter expectations for app-layer routing and presentation surfaces.

## Deliverables

1. Apps lane baseline:
   - `docs/plans/methodology/M31_P10_2_APPS_WAVE31_SHELL_HARDENING_CONTRACT_CONSUMER_ADAPTERS_BASELINE.md`
2. Apps lane controls:
   - `configs/runtime/apps_wave31_shell_hardening_contract_consumer_adapters_controls.json`
3. Apps lane report package:
   - `docs/plans/methodology/MASTER_PLAN_APPS_WAVE31_SHELL_HARDENING_CONTRACT_CONSUMER_ADAPTERS_REPORT.json`
   - `docs/plans/methodology/MASTER_PLAN_APPS_WAVE31_SHELL_HARDENING_CONTRACT_CONSUMER_ADAPTERS_REPORT.md`

## Guardrails

1. No direct `apps -> engine` imports.
2. Runtime/admin capabilities are consumed only via runtime/shared contracts.
3. Consumer app shell remains cleanly separated from internal admin workflows.
4. Shell/adapters documentation must reflect concurrent lane rules for both consumer and admin app packages.

## Exit Criteria

1. Apps wave-31 controls and report artifacts are complete.
2. Consumer and admin app README boundary docs are aligned to the apps-lane shell/adapters rules.
3. Board evidence row is updated and milestone is closed.
4. Board sync, URK quality, architecture checks, and legacy-name checks pass.
