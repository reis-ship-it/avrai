# M31-P12-4 Baseline: Governed Artifact Lifecycle Contract Across Replay, Intake, And Training

Date: 2026-04-04  
Milestone: M31-P12-4  
Master Plan refs:
- `12.4B.7`
- `10.9.1`
- `2.1.5`

Primary authorities:
- `work/docs/plans/architecture/REALITY_MODEL_TRAINING_SIMULATION_AND_AI2AI_PERSISTENCE_GOVERNANCE_2026-04-04.md`
- `work/docs/plans/methodology/REALITY_MODEL_TRAINING_SIMULATION_AND_AI2AI_PERSISTENCE_IMPLEMENTATION_MATRIX_2026-04-04.md`

## Scope

Implement the first executable slice of the persistence-governance authority by adding one governed artifact lifecycle contract across:

1. replay/training manifests
2. governed upward intake records
3. admin-visible review artifacts

This milestone does not yet implement full receipt validation, TTL deletion, or admin retention dashboards. Those belong to follow-on anchors:

1. `12.4B.8`
2. `12.4B.9`
3. `12.4B.10`

`M31-P12-4` is specifically the metadata-and-acceptance layer that makes the later work unambiguous.

## Deliverables

1. Baseline doc:
   - `work/docs/plans/methodology/M31_P12_4_GOVERNED_ARTIFACT_LIFECYCLE_CONTRACT_BASELINE.md`
2. Lifecycle contract models and enums:
   - `runtime/avrai_runtime_os/lib/services/intake/intake_models.dart`
   - if needed, a new shared lifecycle contract model under `shared/avrai_core/lib/models/reality/` or `shared/avrai_core/lib/contracts/`
3. Intake repository persistence wiring:
   - `runtime/avrai_runtime_os/lib/services/intake/universal_intake_repository.dart`
4. Governed upward envelope and intake wiring:
   - `runtime/avrai_runtime_os/lib/services/reality_model/governed_upward_learning_intake_service.dart`
5. Replay/training artifact family ownership:
   - `runtime/avrai_runtime_os/lib/services/prediction/bham_replay_training_export_manifest_service.dart`
   - `runtime/avrai_runtime_os/lib/services/prediction/bham_replay_storage_export_service.dart`
   - `runtime/avrai_runtime_os/lib/services/prediction/bham_replay_storage_partition_service.dart`
   - `runtime/avrai_runtime_os/lib/services/prediction/bham_replay_supabase_upload_index_service.dart`
6. Focused verification:
   - governed-upward intake tests
   - replay/training manifest tests
   - any new lifecycle serialization tests

## Explicit Objectives

1. define one canonical lifecycle schema for AVRAI artifacts:
   - `artifactClass`
   - `artifactState`
   - `retentionPolicy`
2. ensure new governed upward artifacts persist with explicit lifecycle classification rather than implicit meaning
3. ensure replay/training manifest-producing services tag artifacts as `canonical`, `staging`, `archive`, `temporary`, or `quarantine` where appropriate
4. establish the minimum acceptance semantics required before an artifact can be treated as durable learning input
5. keep the schema additive and backward-compatible where possible so existing stored items can still be read

## Non-Goals

This slice does not:

1. enforce receipt expiry or content-hash validation against caller-issued air-gap artifacts
2. add automatic staging-root deletion
3. add configurable AI2AI chat retention UI or policy settings
4. add full admin retention dashboards
5. add quarantine execution or archive migrations

Those belong to later follow-on anchors and should not be mixed into this milestone.

## Canonical Lifecycle Contract

Every durable artifact touched by this slice must support:

### 1. Artifact class

Allowed values:

1. `canonical`
2. `archive`
3. `staging`
4. `temporary`
5. `quarantine`

### 2. Artifact state

Allowed values:

1. `candidate`
2. `accepted`
3. `rejected`
4. `superseded`
5. `expired`

### 3. Retention policy

Minimum fields:

1. `mode`
   - `keep_forever`
   - `archive`
   - `ttl_delete`
   - `user_controlled`
2. `ttlDays`
3. `deleteWhenSuperseded`

### 4. Minimum acceptance metadata

The lifecycle contract should be able to attach:

1. provenance refs
2. evaluation refs
3. promotion refs
4. flags for raw personal payload and raw message content when relevant

`M31-P12-4` may store some of these as optional placeholders if the producing service cannot yet fully populate them, but the fields and contract must exist.

## Exact Implementation Order

## Step 1. Define the lifecycle enums and models

Primary files:

1. `runtime/avrai_runtime_os/lib/services/intake/intake_models.dart`
2. optional shared contract file if cross-package reuse is cleaner

Required changes:

1. add `ArtifactLifecycleClass` enum
2. add `ArtifactLifecycleState` enum
3. add `ArtifactRetentionMode` enum
4. add a serializable `ArtifactRetentionPolicy` model
5. add a serializable `ArtifactLifecycleMetadata` model

Guardrail:

- prefer additive models over invasive rewrites to minimize breakage

## Step 2. Extend intake persistence models to carry lifecycle metadata

Primary files:

1. `runtime/avrai_runtime_os/lib/services/intake/intake_models.dart`
2. `runtime/avrai_runtime_os/lib/services/intake/universal_intake_repository.dart`

Required changes:

1. `ExternalSourceDescriptor` gets optional lifecycle metadata
2. `ExternalSyncJob` gets optional lifecycle metadata
3. `OrganizerReviewItem` gets optional lifecycle metadata
4. repository hydration and persistence remain backward-compatible when older rows lack lifecycle fields

Acceptance:

- old objects deserialize cleanly
- new objects serialize lifecycle metadata deterministically

## Step 3. Tag governed upward artifacts at creation time

Primary file:

1. `runtime/avrai_runtime_os/lib/services/reality_model/governed_upward_learning_intake_service.dart`

Required changes:

1. every staged upward artifact must declare lifecycle metadata
2. default classification for governed upward review artifacts should be:
   - `artifactClass = canonical`
   - `artifactState = candidate`
   - `retentionPolicy.mode = keep_forever`
3. signal-suppressed artifacts should still record lifecycle state explicitly rather than relying on implicit semantics
4. persisted governed envelopes should include lifecycle metadata in the shared payload and persisted envelope metadata

Acceptance:

- all personal/AI2AI/upward staging paths write lifecycle metadata
- review items and source descriptors expose the same classification

## Step 4. Tag replay/training manifest-producing services

Primary files:

1. `runtime/avrai_runtime_os/lib/services/prediction/bham_replay_training_export_manifest_service.dart`
2. `runtime/avrai_runtime_os/lib/services/prediction/bham_replay_storage_export_service.dart`
3. `runtime/avrai_runtime_os/lib/services/prediction/bham_replay_storage_partition_service.dart`
4. `runtime/avrai_runtime_os/lib/services/prediction/bham_replay_supabase_upload_index_service.dart`

Required classifications:

1. training export manifest:
   - `artifactClass = canonical`
   - `artifactState = accepted`
2. replay storage export summary:
   - `artifactClass = staging`
   - `artifactState = accepted`
3. replay storage partition summary:
   - `artifactClass = staging`
   - `artifactState = accepted`
4. upload/index summary:
   - `artifactClass = archive` or `canonical` depending on whether it is treated as durable audit proof
   - this choice must be explicit in code and doc comments

Acceptance:

- replay/training outputs no longer rely on folder path alone to indicate lifecycle meaning

## Step 5. Add minimum acceptance gate helpers

Primary files:

1. `runtime/avrai_runtime_os/lib/services/intake/intake_models.dart`
2. `runtime/avrai_runtime_os/lib/services/reality_model/governed_upward_learning_intake_service.dart`
3. replay/training manifest services as needed

Required changes:

1. add helper(s) that validate lifecycle completeness before marking an artifact durable
2. at minimum, durable artifacts must have:
   - lifecycle class
   - lifecycle state
   - retention policy
3. if an artifact lacks these, it must fail closed or remain unclassified local-only output

Guardrail:

- this milestone validates lifecycle presence, not the full receipt/eval/provenance gate from `12.4B.8`

## Step 6. Add focused tests

Primary tests:

1. new lifecycle serialization/deserialization unit tests
2. governed upward intake tests asserting lifecycle fields are written
3. replay/training manifest tests asserting classification is present and correct

Minimum test assertions:

1. missing lifecycle fields on older stored objects do not break hydration
2. newly produced governed upward records include lifecycle metadata
3. training export manifests are marked `canonical`
4. replay staging/partition outputs are marked `staging`

## Exact File Ownership

### Core lifecycle contract

1. `runtime/avrai_runtime_os/lib/services/intake/intake_models.dart`
2. optional shared contract file if promoted across packages

### Intake persistence

1. `runtime/avrai_runtime_os/lib/services/intake/universal_intake_repository.dart`

### Governed upward intake

1. `runtime/avrai_runtime_os/lib/services/reality_model/governed_upward_learning_intake_service.dart`

### Replay/training lifecycle tagging

1. `runtime/avrai_runtime_os/lib/services/prediction/bham_replay_training_export_manifest_service.dart`
2. `runtime/avrai_runtime_os/lib/services/prediction/bham_replay_storage_export_service.dart`
3. `runtime/avrai_runtime_os/lib/services/prediction/bham_replay_storage_partition_service.dart`
4. `runtime/avrai_runtime_os/lib/services/prediction/bham_replay_supabase_upload_index_service.dart`

### Verification

1. governed upward intake tests under `apps/avrai_app/test/unit/services/`
2. replay/prediction tests under `runtime/avrai_runtime_os/test/services/prediction/`

## Exit Criteria

`M31-P12-4` is complete when:

1. AVRAI has one serializable lifecycle contract with explicit class, state, and retention policy
2. governed upward intake records persist with lifecycle metadata
3. replay/training artifact manifests and summaries persist with lifecycle metadata
4. backward compatibility for previously persisted intake records is preserved
5. focused tests prove lifecycle tagging is present and stable in the governed upward and replay/training paths

## Follow-On Mapping

After `M31-P12-4`:

1. `12.4B.8`
   - validate air-gap receipt correctness and fail closed on invalid upward durability
2. `12.4B.9`
   - enforce TTL/retention automation and supersession
3. `12.4B.10`
   - surface lifecycle truth in admin and prove deletion/non-promotion with end-to-end tests

## Closeout

This milestone is the contract-establishment step.

Without it:

1. retention automation is ambiguous
2. admin visibility is inconsistent
3. tests cannot reliably prove whether an artifact should survive or die

With it:

1. every later persistence-governance rule can operate on explicit lifecycle truth instead of path names, ad hoc conventions, or operator memory
