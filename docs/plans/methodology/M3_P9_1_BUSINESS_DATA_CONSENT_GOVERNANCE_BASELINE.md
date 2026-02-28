# M3-P9-1 Business Data/Consent Governance Hardening Baseline

## Objective
Enforce deterministic business data/consent governance so consent coverage, DP enforcement, and audit-log completeness remain within policy.

## Baseline Artifacts
- Business consent governance config: `configs/runtime/business_data_consent_governance_controls.json`
- Business consent governance report generator/check: `scripts/runtime/generate_business_data_consent_governance_report.py`
- Business consent governance report JSON: `docs/plans/methodology/MASTER_PLAN_BUSINESS_DATA_CONSENT_GOVERNANCE_REPORT.json`
- Business consent governance report Markdown: `docs/plans/methodology/MASTER_PLAN_BUSINESS_DATA_CONSENT_GOVERNANCE_REPORT.md`
- Business consent governance contract: `lib/core/services/business/business_data_consent_governance_contract.dart`
- Business consent governance tests: `test/unit/services/business_data_consent_governance_contract_test.dart`

## Pass Contract
1. Config format valid (`version = v1`, deterministic `evaluation_at`, valid thresholds).
2. Consent coverage is within threshold with no unauthorized processing.
3. DP budget usage remains within threshold.
4. Audit-log completeness and retention checks pass.
5. Contract tests pass and report `verdict` is `PASS`.

## CI Wiring
- `Execution Board Guard` runs business data/consent governance report in `--check` mode.

This baseline closes M3-P9-1 with deterministic consent/DP/audit governance evidence.
