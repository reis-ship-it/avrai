# M0-P2-1 Security + Cryptographic Assurance Baseline

## Objective
Enforce deterministic security and cryptographic assurance checks so post-quantum hardening, attestation integrity, and scoped kill-switch readiness remain within policy bounds.

## Baseline Artifacts
- Security/cryptographic assurance config: `configs/runtime/security_cryptographic_assurance_controls.json`
- Security/cryptographic assurance report generator/check: `scripts/runtime/generate_security_cryptographic_assurance_report.py`
- Security/cryptographic assurance report JSON: `docs/plans/methodology/MASTER_PLAN_SECURITY_CRYPTOGRAPHIC_ASSURANCE_REPORT.json`
- Security/cryptographic assurance report Markdown: `docs/plans/methodology/MASTER_PLAN_SECURITY_CRYPTOGRAPHIC_ASSURANCE_REPORT.md`
- Security/cryptographic assurance contract: `lib/core/services/security/security_cryptographic_assurance_contract.dart`
- Security/cryptographic assurance tests: `test/unit/services/security_cryptographic_assurance_contract_test.dart`

## Pass Contract
1. Config format valid (`version = v1`, deterministic `evaluation_at`, valid thresholds).
2. Post-quantum hardening coverage for critical paths meets configured threshold.
3. Attestation channel coverage meets threshold with zero unsigned updates.
4. Kill-switch drills pass threshold and activation latency stays within configured maximum.
5. Contract tests pass and report `verdict` is `PASS`.

## CI Wiring
- `Execution Board Guard` runs security/cryptographic assurance report in `--check` mode.

This baseline closes M0-P2-1 with deterministic PQ hardening + attestation + kill-switch governance evidence.
