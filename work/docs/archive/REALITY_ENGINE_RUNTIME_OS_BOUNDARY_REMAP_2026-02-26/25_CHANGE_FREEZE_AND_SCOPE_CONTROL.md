# 25 - Change Freeze and Scope Control During Conversion

## Purpose

Prevent architecture conversion from drifting into uncontrolled refactors that delay Phase 1 delivery.

## 1) Temporary Freeze Rules

For the conversion window:
1. No opportunistic renames unrelated to boundaries.
2. No logic rewrites in boundary-only PRs.
3. No feature expansion inside conversion PRs.

## 2) Allowed Change Types

1. Documentation truth alignment
2. Board/tracker/governance alignment
3. CI guard additions
4. Boundary-preserving module extraction with parity tests

## 3) Disallowed Change Types

1. Product UX redesigns
2. New business feature logic
3. Non-essential package reshuffles
4. Multi-domain mixed PRs

## 4) PR Classification Labels

Use one required label per PR:
- `conversion-docs`
- `conversion-ci-guard`
- `conversion-extraction`
- `phase1-feature`

## 5) Exit Condition for Freeze

Freeze ends when:
1. conversion gates in `23_PHASE1_CONTINUATION_GATE.md` are green,
2. first extraction PR is merged with no parity regressions,
3. boundary guard trend shows no new violations.

Then Phase 1 work continues normally under new architecture policy.

