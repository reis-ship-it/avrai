# Reality-Model Training, Simulation, And AI2AI Persistence Governance

**Date:** April 4, 2026  
**Status:** Proposed technical authority  
**Purpose:** Define the exact persistence, retention, expiry, and governance rules required for AVRAI's training loop, simulation loop, and AI2AI exchanges so the system keeps canonical learning state without turning every intermediate or raw artifact into permanent storage.

---

## 1. Why This Document Exists

AVRAI currently has the right high-level doctrine:

- raw personal-origin data must cross an air gap before it can influence higher learning
- the reality model is the top-level learning integrator
- replay/simulation outputs are governed before they influence training or propagation
- AI2AI is a learnable domain, but it is not allowed to become an uncontrolled backchannel

What is still missing is one explicit technical retention and persistence contract that answers:

1. which artifacts survive the simulation-to-training loop
2. which artifacts are staging only
3. which artifacts must be archived but not kept hot
4. which AI2AI exchanges persist locally, centrally, both, or neither
5. when an exchange or artifact must die
6. what code and storage changes are required so these rules are actually enforced

This document defines that contract.

---

## 2. Canonical Authorities This Extends

This document must be interpreted together with:

1. `work/docs/plans/architecture/REALITY_MODEL_AUTONOMOUS_CONTROL_PLANE_AND_SUPERVISOR_DAEMON_2026-03-30.md`
2. `work/docs/plans/architecture/AI2AI_MESH_3_PRONG_GOVERNED_ARCHITECTURE_2026-03-11.md`
3. `work/docs/plans/philosophy_implementation/AVRAI_PHILOSOPHY_AND_ARCHITECTURE.md`
4. `work/docs/plans/methodology/REALITY_MODEL_SIMULATION_TO_TRAINING_OPERATOR_RUNBOOK_2026-04-01.md`
5. `work/docs/plans/ai2ai_system/AI2AI_NETWORK_BOUNDARY.md`
6. `work/docs/plans/ai2ai_system/AI2AI_SYNC_AND_OFFLINE.md`

This document does not replace those authorities. It makes their storage and lifecycle implications explicit.

---

## 3. Canonical Persistence Doctrine

AVRAI must not persist all data equally.

The system must preserve:

1. canonical learning state
2. lineage
3. evaluation proof
4. rollbackability
5. governance decisions

The system must not preserve by default:

1. raw lower-level payloads after normalization
2. duplicate derived artifacts
3. temporary staging exports
4. partition chunks
5. unreviewed upward candidates
6. transport-delivery intermediates after their delivery window ends

The core rule is:

**AVRAI keeps meaning, lineage, and reproducibility. It does not keep every raw byte.**

---

## 4. Required Artifact Model

Every persisted artifact in the training/simulation/governance loop must carry an explicit lifecycle classification.

### 4.1 Required fields

Every artifact manifest, queue item, export summary, intake item, or upward envelope must eventually carry at least:

```json
{
  "artifactId": "string",
  "artifactFamily": "string",
  "artifactClass": "canonical|archive|staging|temporary|quarantine",
  "artifactState": "candidate|accepted|rejected|superseded|expired",
  "sourceScope": "personal|locality|world|universal|admin|supervisor|kernel|simulation|ai2ai",
  "containsRawPersonalPayload": false,
  "containsMessageContent": false,
  "lineageRefs": [],
  "evaluationRefs": [],
  "promotionRefs": [],
  "retentionPolicy": {
    "mode": "keep_forever|archive|ttl_delete|user_controlled",
    "ttlDays": 30,
    "deleteWhenSuperseded": true
  }
}
```

### 4.2 Required semantics

- `artifactClass` answers what kind of storage treatment the artifact gets.
- `artifactState` answers whether it is trusted and whether it may influence training or higher truth.
- `retentionPolicy` answers whether the system should preserve, archive, expire, or user-manage the artifact.
- `containsRawPersonalPayload` and `containsMessageContent` exist so policy can fail closed before upward promotion or central persistence.

### 4.3 Canonical classes

`canonical`
- trusted durable source of truth
- allowed to participate in retraining, rollback, and audit

`archive`
- not hot
- retained for recovery, audit, or expensive regeneration avoidance

`staging`
- temporary operational artifact
- may be required for an in-progress workflow
- must not become the source of truth

`temporary`
- scratch or local convenience artifact
- never reference as canonical

`quarantine`
- isolated due to policy, quality, poisoning, or contradiction risk
- never reused silently

---

## 5. Canonical Governance States

Every artifact in the replay/training and upward-learning loop must pass through one of these states:

1. `candidate`
2. `accepted`
3. `rejected`
4. `superseded`
5. `expired`

Rules:

- only `accepted` canonical artifacts may train or propagate upward
- `candidate` artifacts may be reviewed but must not silently influence broader truth
- `rejected` artifacts may remain in quarantine for audit, but not in active reuse paths
- `superseded` artifacts may be retained for rollback or historical comparison
- `expired` artifacts must be physically deleted or archived outside hot paths

---

## 6. Simulation And Training Loop Persistence Contract

## 6.1 Stage A: Raw source intake and simulation generation

Examples:

- source registries
- raw imports
- raw simulation outputs
- transient execution traces

Required treatment:

- classify as `candidate`
- preserve provenance and schema version
- do not promote raw payloads directly into training
- do not keep raw material hot after canonical normalization succeeds unless legal or audit obligations require it

Keep:

- source identity
- timestamps
- transform version
- integrity hash

Archive or delete:

- raw bulk payloads after successful normalization
- duplicate execution dumps
- retry artifacts

## 6.2 Stage B: Canonical normalization

Examples:

- normalized observations
- canonical tuples
- canonical episodes

Required treatment:

- this is the first major persistence boundary
- normalized tuples/episodes become the durable substrate, not the raw feed
- every canonical tuple set must link to source provenance and transform version

Keep:

- canonical tuples/episodes
- normalization manifest
- source lineage
- validation results

Delete or archive:

- raw source payloads once normalization is accepted

## 6.3 Stage C: Replay family assembly

Examples from the current BHAM lane:

- `45_BHAM_SINGLE_YEAR_REPLAY_PASS_2023.*`
- `50_BHAM_REPLAY_POPULATION_PROFILE_2023.*`
- `56_BHAM_REPLAY_DAILY_BEHAVIOR_2023.*`
- `59_BHAM_REPLAY_ACTOR_KERNEL_COVERAGE_2023.*`
- `60_BHAM_REPLAY_CONNECTIVITY_PROFILES_2023.*`
- `67_BHAM_REPLAY_PHYSICAL_MOVEMENT_2023.*`
- `68_BHAM_REPLAY_TRAINING_SIGNALS_2023.*`
- `69_BHAM_REPLAY_HOLDOUT_EVALUATION_2023.*`

Required treatment:

- accepted replay artifacts may be `canonical` if they are directly referenced by accepted manifests
- replay artifacts not referenced by an accepted manifest must not persist as hot truth by default

Keep hot:

- accepted replay artifacts referenced by training/eval manifests

Archive:

- large accepted replay artifacts that are expensive to rebuild but not actively consumed

Expire:

- failed replay runs
- duplicate replay outputs
- exploratory reruns with no acceptance decision

## 6.4 Stage D: Training-set assembly

Examples:

- training export manifest
- split definitions
- holdout definitions
- exclusion manifests

Required treatment:

- every training run must be manifest-driven
- ad hoc tuple subsets are not durable learning artifacts
- the manifest is part of the canonical learning record

Keep:

- dataset manifest
- split manifest
- tuple references or canonical tuple snapshot
- exclusion rationale
- evaluation prerequisites

## 6.5 Stage E: Staging and partitioning

Examples:

- `runtime_exports/replay_storage_staging/...`
- `runtime_exports/replay_storage_partitions/...`

Required treatment:

- these are `staging`, never `canonical`
- they may exist only to support upload/indexing or operator inspection
- after accepted upload/index confirmation, they must expire automatically

Keep only while needed:

- staging export summaries
- partition manifests
- upload receipts

Delete after success:

- local staged files
- local partition chunks
- duplicate chunk summaries

## 6.6 Stage F: Evaluation, grading, and promotion

Examples:

- holdout evaluation
- promotion decision
- training kernel state
- rollback pointer

Required treatment:

- evaluation and promotion lineage are canonical
- no model or kernel promotion without durable evaluation proof

Keep:

- evaluation bundle
- grading decision
- promotion decision
- promoted state
- rollback predecessor

## 6.7 Stage G: Upward governed learning integration

Examples:

- governed envelopes
- review items
- intake jobs
- kernel graph runs

Required treatment:

- anything leaving personal scope or simulation review scope must cross a governance boundary
- higher tiers keep the bounded abstraction, not the raw originating payload

Keep:

- governed envelope
- review decision
- bounded summary
- temporal lineage
- source scope
- promotion/rejection rationale

Never keep centrally:

- raw personal-origin payloads
- full AI2AI message content as training authority

---

## 7. AI2AI Exchange Persistence Contract

AI2AI exchanges must not be governed under the same persistence rule as replay artifacts. They are transport and interaction events first, and only sometimes become learning artifacts.

The system must distinguish at least seven AI2AI exchange classes.

## 7.1 Session bootstrap and prekey exchange

Examples:

- session prime events
- prekey publish/forward
- trust/bootstrap receipts

Keep:

- security receipts
- audit events
- trust state transitions

Do not keep as content history:

- raw bootstrap payloads after session establishment

Retention:

- short-lived runtime state
- durable security/audit receipt if required

## 7.2 In-flight queue messages

Current reference:

- `runtime/avrai_runtime_os/lib/ai2ai/message_queue_service.dart`
- `work/docs/plans/ai2ai_system/AI2AI_NETWORK_BOUNDARY.md`
- `work/docs/plans/ai2ai_system/AI2AI_SYNC_AND_OFFLINE.md`

Rules:

- in-flight queue entries are `staging`
- they are delivery artifacts, not learning artifacts
- they must remain short-lived

Retention:

- cloud queue TTL only
- current reference is 60 minutes

Delete when:

- delivered
- expired
- revoked
- quarantined by policy

## 7.3 Delivered direct or community messages

Current reference:

- `runtime/avrai_runtime_os/lib/ai2ai/anonymous_communication.dart`
- `runtime/avrai_runtime_os/lib/services/chat/dm_message_store.dart`
- `runtime/avrai_runtime_os/lib/services/community/community_message_store.dart`

Rules:

- delivered message content may persist locally for user experience
- delivered content is not automatically canonical training data
- raw conversation content must not become a higher-tier truth artifact without air-gap extraction and governed packaging

Retention:

- local only
- user-controlled or app-policy-controlled
- not centrally promoted as raw content

Required future rule:

- delivered AI2AI message history must support configurable retention modes:
  1. keep until user clears
  2. rolling TTL
  3. domain-specific no-retention mode

## 7.4 Learning insight exchanges

Current references:

- `runtime/avrai_runtime_os/lib/ai2ai/connection_orchestrator.dart`
- `runtime/avrai_runtime_os/lib/ai2ai/locality/incoming_learning_insight_side_effects.dart`
- `runtime/avrai_runtime_os/lib/services/ledgers/ledger_audit_v0.dart`

Rules:

- the exchange packet is transport-level and may die after delivery
- the local effect may persist as bounded learning state
- the training-relevant representation must be an extracted bounded insight or tuple, not the raw packet

Keep:

- bounded local learning delta
- audit receipt if enabled
- dedupe/replay guard metadata

Delete or expire:

- raw learningInsight packet body after successful application and optional bounded receipt

## 7.5 Locality agent updates

Current references:

- `runtime/avrai_runtime_os/lib/services/locality_agents/locality_agent_mesh_cache.dart`
- `runtime/avrai_runtime_os/lib/ai2ai/locality/incoming_locality_agent_update_processor.dart`

Rules:

- locality updates should persist as scoped state, not as infinite message history
- newer accepted state should supersede older point-in-time updates unless historical lineage is specifically required

Keep:

- latest accepted scoped locality state
- bounded lineage ref

Expire:

- obsolete update payloads once superseded

## 7.6 Trust, transport, and security events

Current references:

- `runtime/avrai_runtime_os/lib/monitoring/network_activity_monitor.dart`
- `runtime/avrai_runtime_os/lib/monitoring/ai2ai_network_activity_event.dart`
- `runtime/avrai_runtime_os/lib/services/ledgers/ledger_audit_v0.dart`

Rules:

- keep security and governance receipts
- do not keep message content for this purpose

Retention:

- durable audit retention
- independent of message-content retention

## 7.7 AI2AI-derived upward learning candidates

Current references:

- `runtime/avrai_runtime_os/lib/services/ai_infrastructure/ai2ai_chat_event_intake_service.dart`
- `runtime/avrai_runtime_os/lib/services/reality_model/governed_upward_learning_intake_service.dart`
- `runtime/avrai_runtime_os/lib/services/intake/upward_air_gap_service.dart`

Rules:

- no raw AI2AI message may directly become higher truth
- only air-gap-issued bounded artifacts may enter governed upward review
- accepted upward envelopes may persist durably
- rejected candidates must enter quarantine or expire

Keep:

- air-gap artifact
- governed envelope
- review decision
- temporal lineage

Never keep in higher tiers:

- raw AI2AI message transcript as authority-bearing truth

---

## 8. Required Storage Topology

AVRAI must use different storage treatment for different artifact classes.

## 8.1 Personal hot storage

Purpose:

- user-local history
- user-local delivered messages
- user-local rich memory

Allowed:

- delivered AI2AI messages
- local memory
- raw personal context before air-gap extraction, only within local runtime boundaries

Not allowed:

- direct off-device export of raw personal-origin payloads

## 8.2 Governed intake storage

Purpose:

- bounded upward learning artifacts
- review queue
- governed envelopes

Allowed:

- air-gap-issued bounded artifacts
- review decisions
- lineage

Not allowed:

- raw personal-origin domain objects
- direct service-owned runtime payloads crossing upward without receipts

## 8.3 Replay/training canonical storage

Purpose:

- canonical tuples
- canonical manifests
- promoted kernel/model state
- evaluation bundles

Allowed:

- accepted canonical training artifacts

Not allowed:

- raw staging directories treated as canonical storage

## 8.4 Replay/training staging storage

Purpose:

- export
- partition
- upload/index work

Retention:

- TTL only

## 8.5 Cold archive storage

Purpose:

- large replay bundles
- raw imports retained for audit
- expensive-to-regenerate accepted artifacts

Retention:

- archive, not hot

---

## 9. What Must Be Implemented For This To Be True

The doctrine above is not true just because it is written down. The following technical work is required.

## 9.1 Add artifact lifecycle metadata everywhere it matters

Target files and seams:

1. `runtime/avrai_runtime_os/lib/services/intake/intake_models.dart`
2. `runtime/avrai_runtime_os/lib/services/intake/universal_intake_repository.dart`
3. `runtime/avrai_runtime_os/lib/services/reality_model/governed_upward_learning_intake_service.dart`
4. `runtime/avrai_runtime_os/lib/services/admin/replay_simulation_admin_service.dart`
5. `runtime/avrai_runtime_os/lib/services/prediction/bham_replay_training_export_manifest_service.dart`
6. `runtime/avrai_runtime_os/lib/services/prediction/bham_replay_storage_export_service.dart`
7. `runtime/avrai_runtime_os/lib/services/prediction/bham_replay_storage_partition_service.dart`
8. `runtime/avrai_runtime_os/lib/services/prediction/bham_replay_supabase_upload_index_service.dart`

Required result:

- manifests and queue items explicitly declare `artifactClass`, `artifactState`, and `retentionPolicy`

## 9.2 Enforce fail-closed upward intake

Target files:

1. `runtime/avrai_runtime_os/lib/services/intake/upward_air_gap_service.dart`
2. `runtime/avrai_runtime_os/lib/services/reality_model/governed_upward_learning_intake_service.dart`
3. `runtime/avrai_runtime_os/lib/services/ai_infrastructure/ai2ai_chat_event_intake_service.dart`

Required result:

- no personal-origin or AI2AI-origin upward learning item is accepted without a valid air-gap receipt
- receipt must declare scope, expiry, lineage hash, and destination ceiling
- missing receipt means no queue item, no review item, no higher-tier persistence

## 9.3 Add automatic expiry for staging layers

Target areas:

1. `runtime_exports/replay_storage_staging`
2. `runtime_exports/replay_storage_partitions`
3. Supabase replay upload temporary workspaces
4. AI2AI delivery queue cleanup

Required result:

- successful upload/index automatically expires local staging and partition artifacts
- stale staging roots are deleted by policy
- queue entries older than TTL are purged without manual cleanup

## 9.4 Split AI2AI content persistence from AI2AI learning persistence

Target files:

1. `runtime/avrai_runtime_os/lib/ai2ai/anonymous_communication.dart`
2. `runtime/avrai_runtime_os/lib/services/chat/dm_message_store.dart`
3. `runtime/avrai_runtime_os/lib/services/community/community_message_store.dart`
4. `runtime/avrai_runtime_os/lib/ai2ai/connection_orchestrator.dart`

Required result:

- message content retention is local UX policy
- learning-derived abstractions are separate bounded artifacts
- raw delivered messages do not silently double as central training artifacts

## 9.5 Add supersession rules for stateful AI2AI artifacts

Target files:

1. `runtime/avrai_runtime_os/lib/services/locality_agents/locality_agent_mesh_cache.dart`
2. `runtime/avrai_runtime_os/lib/ai2ai/locality/incoming_locality_agent_update_processor.dart`

Required result:

- locality updates become replaceable state snapshots with lineage
- stale update payloads expire once a newer accepted state supersedes them

## 9.6 Add retention configuration surfaces

Required configuration families:

1. personal AI2AI message retention policy
2. replay staging TTL
3. partition TTL
4. quarantine retention duration
5. archive-on-success vs delete-on-success policy

Required result:

- retention is policy-controlled, not hardcoded per service

## 9.7 Build admin/operator visibility for lifecycle state

Admin must show:

1. artifact class
2. artifact state
3. retention mode
4. expiry time
5. archival location if moved
6. promotion lineage
7. quarantine reason if blocked

Without this, operators cannot tell whether a training artifact is canonical, staging, or already expired.

## 9.8 Add canonical acceptance gates before durability

Before an artifact becomes durable `canonical`, the system must verify:

1. provenance exists
2. transform version exists
3. evaluation refs exist where required
4. policy classification exists
5. personal raw payload flag is false for higher-tier artifacts
6. AI2AI raw content flag is false for higher-tier artifacts

If any of these checks fail, the artifact must remain `candidate` or move to `quarantine`.

## 9.9 Add tests that prove death actually happens

Required test categories:

1. staging export expires after upload success
2. partition artifacts expire after index success
3. upward intake fails without air-gap receipt
4. AI2AI queue rows expire on TTL
5. AI2AI delivered content remains local and is not promoted raw
6. learning insight packets do not persist as canonical message history
7. superseded locality updates are retired
8. rejected upward candidates do not silently re-enter training

If there are no tests proving deletion, expiry, and fail-closed behavior, the policy is not operational.

---

## 10. Folder-Level Retention Contract

This is the operational interpretation for the current repo.

### 10.1 Keep as canonical

1. `runtime_exports/training_kernel/*.json`
2. `runtime_exports/training_kernel/*.jsonl`
3. accepted BHAM replay JSON artifacts referenced by accepted training manifests
4. governed intake records in the universal intake repository

### 10.2 Treat as staging only

1. `runtime_exports/replay_storage_staging/**`
2. `runtime_exports/replay_storage_partitions/**`

### 10.3 Treat as temporary or archive-only

1. `runtime_exports/local/**`
2. dry-run recovery summaries
3. duplicate markdown mirrors where JSON is authoritative

### 10.4 Keep local-only by policy

1. delivered AI2AI message content
2. local user-specific rich memory
3. local device-derived raw context before air-gap extraction

### 10.5 Never persist upward raw

1. raw personal chat payloads
2. raw AI2AI message content
3. raw personal device domain objects
4. unreviewed transport payloads

---

## 11. Canonical Meaning Of "Persist" Versus "Die"

For AVRAI, an exchange or artifact "persists" only if it survives as one of:

1. canonical state
2. archive copy
3. user-local history
4. audit/security lineage

An exchange or artifact "dies" when:

1. the raw payload is deleted after normalization
2. the queue item expires after delivery window
3. the staging export is deleted after successful upload/index
4. the superseded state is removed from hot storage
5. the rejected candidate is quarantined and blocked from reuse

This means:

- a raw AI2AI message may die while its bounded learning effect survives
- a replay partition may die while the training manifest survives
- a personal-origin raw event may die while its governed upward envelope survives

That is the intended design.

---

## 12. Acceptance Criteria

This policy is only true when all of the following are true in code and operations:

1. no higher-tier learning artifact can be created from raw personal-origin or raw AI2AI-origin payloads without an air-gap receipt
2. replay staging and partition artifacts are never treated as canonical sources of truth
3. accepted training runs always retain canonical tuples, manifests, evals, and promoted state
4. AI2AI queue entries expire automatically
5. delivered AI2AI content remains local UX state unless separately extracted and governed
6. bounded learning abstractions are stored separately from raw transport/message payloads
7. superseded stateful AI2AI artifacts are retired
8. operators can inspect artifact lifecycle class and retention state in admin
9. deletion and fail-closed behavior are covered by tests

If these criteria are not met, AVRAI does not yet have governed persistence. It only has partial storage hygiene.

---

## 13. Final Rule

The training/simulation loop and the AI2AI loop must not be storage funnels.

They must be governance funnels.

Most artifacts should die.
Only bounded, validated, lineage-bearing artifacts should survive.
