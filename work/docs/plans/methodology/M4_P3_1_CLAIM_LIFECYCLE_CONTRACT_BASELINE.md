# M4-P3-1 Claim Lifecycle Contract Baseline

Date: 2026-02-27  
Milestone: `M4-P3-1`  
Status: In progress baseline artifact

## Lifecycle States

1. `hypothesis`
2. `observed`
3. `reproduced`
4. `operational`
5. `canonical`
6. `deprecated`

## Transition Rules

1. Promotion is adjacent-only (`from -> next`).
2. Promotion requires `promote` decision type and target-state evidence thresholds.
3. Demotion/containment requires one of `demote|quarantine|rollback` plus evidence.
4. `deprecated` is terminal.

## API Contract Surface (v0)

1. `POST /claims`
2. `GET /claims/{claim_id}`
3. `POST /claims/{claim_id}/evidence`
4. `POST /claims/{claim_id}/transitions`
5. `GET /claims/{claim_id}/audit`

## Code Baseline

1. `lib/core/ai/knowledge_lifecycle/claim_lifecycle_contract.dart`
2. `test/unit/ai/claim_lifecycle_contract_test.dart`
