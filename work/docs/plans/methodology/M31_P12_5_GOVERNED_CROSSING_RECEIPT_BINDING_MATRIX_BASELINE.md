# M31-P12-5 Governed Crossing Receipt Binding Matrix Baseline

**Date:** 2026-04-05  
**Status:** Ready for implementation  
**Primary anchors:** `12.4B.8`, `12.4B.9`, `12.4B.10`  
**Purpose:** Turn the remaining fail-closed receipt-binding work in `12.4B.8` into an explicit, hierarchy-aware implementation baseline so governed upward intake, simulation/training promotion, and downward deployment all use the same crossing contract.

Primary authorities:
- `work/docs/MASTER_PLAN.md`
- `work/docs/plans/architecture/REALITY_MODEL_TRAINING_SIMULATION_AND_AI2AI_PERSISTENCE_GOVERNANCE_2026-04-04.md`
- `work/docs/plans/methodology/REALITY_MODEL_TRAINING_SIMULATION_AND_AI2AI_PERSISTENCE_IMPLEMENTATION_MATRIX_2026-04-04.md`
- `work/docs/plans/methodology/M31_P12_4_GOVERNED_ARTIFACT_LIFECYCLE_CONTRACT_BASELINE.md`

---

## 1. What This Baseline Adds

`12.4B.8` already has the first fail-closed slice:

1. caller-issued upward artifacts are required for personal-origin and AI2AI-origin governed intake
2. receipt self-consistency is now validated before durable persistence
3. invalid expiry, destination, next-stage allowance, digest, and attestation all fail closed

What still remains is binding:

1. prove the receipt matches the current governed request, not just itself
2. carry the same discipline through higher crossings in the training/simulation hierarchy
3. prevent upward, training, promotion, or downward state changes from reusing stale or mismatched artifacts

This baseline defines the receipt family and the per-level binding requirements needed to finish that work.

---

## 2. Canonical Rule

Every governed crossing must be backed by a receipt that proves all four of these at once:

1. transport identity: what moved and from where
2. payload identity: which bounded payload the receipt attests to
3. governance identity: which policy lane and next stage are allowed
4. intent identity: which exact request, review, promotion, or deployment action the crossing belongs to

If any of those are missing or mismatched, the crossing must fail closed.

---

## 3. Receipt Family

AVRAI should converge on one receipt family, not one ad hoc payload per lane.

### 3.1 Common base contract

Every governed crossing receipt should eventually carry:

```json
{
  "receiptId": "string",
  "receiptKind": "string",
  "artifactVersion": "string",
  "originPlane": "string",
  "sourceKind": "string",
  "sourceScope": "string",
  "destinationCeiling": "string",
  "issuedAtUtc": "2026-04-05T00:00:00.000Z",
  "expiresAtUtc": "2026-04-12T00:00:00.000Z",
  "allowedNextStages": ["governed_upward_learning_review"],
  "contentSha256": "hex",
  "sanitizedPayload": {},
  "attestation": {},
  "requestRef": "string",
  "artifactRef": "string",
  "reviewRef": "string",
  "runRef": "string",
  "manifestRef": "string",
  "promotionRef": "string",
  "rollbackRef": "string"
}
```

Not every field is required at every level, but every crossing must use the same base vocabulary.

### 3.2 Canonical receipt kinds

| Receipt kind | Crossing | Current or future carrier |
|---|---|---|
| `upward_intake_receipt` | personal/AI2AI/locality/supervisor -> governed upward intake | current `UpwardAirGapArtifact` |
| `review_acceptance_receipt` | governed candidate -> accepted bounded learning artifact | future governed review acceptance model |
| `simulation_export_receipt` | replay/simulation outputs -> accepted export bundle | future replay/training export contract |
| `training_manifest_receipt` | accepted tuple/replay family -> trainable manifest | future manifest binding contract |
| `promotion_receipt` | accepted manifest/eval bundle -> promoted kernel/model state | future promotion contract |
| `downward_deployment_receipt` | promoted higher truth -> lower-layer rollout/config sync | future downward propagation contract |

---

## 4. Hierarchy Binding Matrix

The receipt rule is shared. The fields are level-specific.

| Crossing | Minimum binding refs | Minimum payload identity | Must fail when |
|---|---|---|---|
| personal -> governed upward intake | `requestRef` or source message/event ID | bounded source IDs and bounded metadata for the current request | receipt is valid but points to a different message/event/request |
| AI2AI -> governed upward intake | `requestRef`, `messageId`, `remoteRef` | local agent, remote ref, direction, scope | a different AI2AI exchange reuses the receipt |
| locality/domain -> governed upward intake | locality key, observation kind, lineage ref when present | locality identity plus bounded observation fields | observation receipt does not match the current locality packet |
| supervisor/admin -> governed upward intake | observation kind, summary, environment/city/locality scope | bounded metadata and review lane | a valid supervisor receipt is replayed for a different observation |
| replay/simulation -> accepted export | `runRef`, environment ID, variant ID when present | exported artifact refs and run metadata | a different run’s outputs are attached to the current export |
| accepted export -> training manifest | `manifestRef`, split ref, eval ref | exact dataset members or canonical refs | manifest references an export family not proven by the receipt |
| training manifest -> promoted kernel/model | `promotionRef`, manifest ref, eval ref, rollback ref | promoted checkpoint/state ID and training digest | model promotion is not tied to one accepted manifest + eval bundle |
| promoted higher state -> downward rollout | rollout/deployment ref and promoted state ref | target layer, target scope, effective config/state version | lower layer receives an update that cannot be tied to one promoted source |

---

## 5. Current Code Interpretation

### 5.1 What already exists

Today AVRAI already has one real receipt type:

- `runtime/avrai_runtime_os/lib/services/intake/intake_models.dart`
  - `UpwardAirGapArtifact`
- `runtime/avrai_runtime_os/lib/services/intake/upward_air_gap_service.dart`
  - issuance + self-consistency validation
- `runtime/avrai_runtime_os/lib/services/reality_model/governed_upward_learning_intake_service.dart`
  - required caller-issued artifacts for governed personal/AI2AI-style intake

That means the first receipt family member is no longer theoretical. The gap is that current validation still needs request-binding checks and the higher crossings still need the same family language.

### 5.2 What counts as complete for the upward slice

The upward slice of `12.4B.8` should only count as complete when:

1. every caller-issued governed intake lane provides an explicit request-binding map
2. the intake service rejects receipts whose bounded payload no longer matches the current request
3. the failure occurs before durable source/review persistence
4. tests prove self-consistent but mismatched receipts are rejected

---

## 6. Immediate Implementation Order

### Slice 1: request-bound governed upward intake

Scope:

- `runtime/avrai_runtime_os/lib/services/reality_model/governed_upward_learning_intake_service.dart`
- `runtime/avrai_runtime_os/lib/services/intake/upward_air_gap_service.dart`
- governed upward intake tests

Required behavior:

1. `_stage()` accepts an explicit request-binding contract for caller-issued lanes
2. validation compares the current request binding against `sanitizedPayload`
3. some keys may be optional, but each lane must declare minimum required identity fields
4. mismatch throws before persistence

### Slice 2: replay/training binding metadata

Scope:

- replay export service
- partition service
- upload/index service
- training manifest service

Required behavior:

1. replay and training manifests carry binding refs such as `runRef`, `manifestRef`, `evaluationRefs`, and `promotionRefs`
2. staging and archive manifests cannot silently stand in for canonical promotion inputs

### Slice 3: promotion and downward receipt models

Scope:

- promotion/published-kernel services
- hierarchy propagation services
- admin inspection surfaces

Required behavior:

1. promoted state records identify the accepted manifest/eval bundle that produced them
2. downward propagation carries a deployment receipt tying lower-layer rollout to one promoted source

---

## 7. File Ownership For The Remaining `12.4B.8` Work

### Upward request binding

- `runtime/avrai_runtime_os/lib/services/reality_model/governed_upward_learning_intake_service.dart`
- `runtime/avrai_runtime_os/lib/services/intake/upward_air_gap_service.dart`
- relevant producers under:
  - `runtime/avrai_runtime_os/lib/services/user/`
  - `runtime/avrai_runtime_os/lib/services/ai_infrastructure/`
  - `runtime/avrai_runtime_os/lib/services/recommendations/`
  - `runtime/avrai_runtime_os/lib/services/events/`
  - `runtime/avrai_runtime_os/lib/services/community/`
  - `runtime/avrai_runtime_os/lib/services/reservation/`
  - `runtime/avrai_runtime_os/lib/services/business/`
  - `runtime/avrai_runtime_os/lib/services/admin/`
  - `runtime/avrai_runtime_os/lib/kernel/`

### Training/promotion/downward follow-ons

- replay/training services under `runtime/avrai_runtime_os/lib/services/prediction/`
- future promotion and propagation services once the upward slice is stable

---

## 8. Acceptance Criteria

This baseline is satisfied only when all of these are true:

1. a receipt that is self-consistent but bound to the wrong request is rejected
2. governed upward intake cannot persist raw personal or AI2AI content without a request-matching receipt
3. replay/training promotion work uses binding refs rather than loose metadata alone
4. higher-layer rollout/downward propagation can be traced back to one promoted source state
5. the plan registry and master plan both point to this baseline as the execution surface for the remaining receipt-binding work

Until then, AVRAI has receipt validation, but not full receipt-bound hierarchy governance.
