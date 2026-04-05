# Reality-Model Training, Simulation, And AI2AI Persistence Implementation Matrix

**Date:** 2026-04-04  
**Status:** Active implementation matrix  
**Purpose:** Convert Section 9 of the persistence-governance authority into an explicit execution matrix showing what already exists in code, what is partial, what is missing, and which stable Master Plan anchors now own the remaining work.

Primary authority:
- `work/docs/plans/architecture/REALITY_MODEL_TRAINING_SIMULATION_AND_AI2AI_PERSISTENCE_GOVERNANCE_2026-04-04.md`

Supporting authorities:
- `work/docs/MASTER_PLAN.md`
- `work/docs/MASTER_PLAN_TRACKER.md`
- `work/docs/plans/architecture/REALITY_MODEL_AUTONOMOUS_CONTROL_PLANE_AND_SUPERVISOR_DAEMON_2026-03-30.md`
- `work/docs/plans/architecture/AI2AI_MESH_3_PRONG_GOVERNED_ARCHITECTURE_2026-03-11.md`
- `work/docs/plans/methodology/REALITY_MODEL_SIMULATION_TO_TRAINING_OPERATOR_RUNBOOK_2026-04-01.md`

---

## 1. Status Legend

- `implemented`: materially present and enforceable in code
- `partial`: important primitives exist, but the full contract is not yet enforced
- `missing`: the behavior is still mostly policy intent

---

## 2. Section 9 Execution Matrix

| Section 9 item | Current status | Existing repo evidence | What is still missing | Stable execution anchors |
|---|---|---|---|---|
| `9.1 Add artifact lifecycle metadata everywhere` | `partial` | `UpwardAirGapArtifact` already carries receipt/scope/hash/expiry metadata in `runtime/avrai_runtime_os/lib/services/intake/intake_models.dart`; governed envelopes persist bounded lineage in `runtime/avrai_runtime_os/lib/services/reality_model/governed_upward_learning_intake_service.dart` | no generic `artifactClass`, `artifactState`, or `retentionPolicy` fields across intake records, replay manifests, review items, or training/export artifacts | `12.4B.7`, `10.9.1`, `2.1.5` |
| `9.2 Enforce fail-closed upward intake` | `partial` | caller-issued air-gap artifacts are already required for personal/AI2AI-origin sources in `runtime/avrai_runtime_os/lib/services/reality_model/governed_upward_learning_intake_service.dart`; receipt issuance exists in `runtime/avrai_runtime_os/lib/services/intake/upward_air_gap_service.dart` | presence is enforced more strongly than validity; receipt expiry, destination ceiling, next-stage allowance, and content consistency still need explicit fail-closed validation before persistence | `12.4B.8`, `10.9.1`, `12.4A.7` |
| `9.3 Add automatic expiry for staging layers` | `partial` | AI2AI queue expiry and cleanup already exist in `runtime/avrai_runtime_os/lib/ai2ai/message_queue_service.dart`; replay staging and partition roots are operationally distinguished in the runbook and replay export services | no unified auto-expiry policy for replay staging/partition artifacts after successful upload/index; local generated roots still rely on manual cleanup or scripts | `12.4B.9`, `2.1.5` |
| `9.4 Split AI2AI content persistence from AI2AI learning persistence` | `partial` | queue, delivered messages, and learning insights are already structurally distinct across `runtime/avrai_runtime_os/lib/ai2ai/message_queue_service.dart`, `runtime/avrai_runtime_os/lib/ai2ai/anonymous_communication.dart`, `runtime/avrai_runtime_os/lib/services/chat/dm_message_store.dart`, `runtime/avrai_runtime_os/lib/services/community/community_message_store.dart`, and `runtime/avrai_runtime_os/lib/ai2ai/connection_orchestrator.dart` | delivered content still needs explicit retention-mode policy and stronger guarantees that raw message content never silently becomes central training authority | `12.4B.8`, `12.4B.9`, `3.7A.5` |
| `9.5 Add supersession rules for stateful AI2AI artifacts` | `partial` | `LocalityAgentMeshCache` already uses TTL and stable-key overwrite semantics in `runtime/avrai_runtime_os/lib/services/locality_agents/locality_agent_mesh_cache.dart` | no formal supersession lineage, no explicit accepted/superseded state, and no operator-visible retirement path for locality/stateful AI2AI updates | `12.4B.9`, `3.7A.5` |
| `9.6 Add retention configuration surfaces` | `missing` | some local TTL defaults exist, such as `UpwardAirGapService.defaultTtl` and locality mesh cache TTL | no central retention policy surface for AI2AI message history, replay staging TTL, partition TTL, quarantine duration, or archive-vs-delete behavior | `12.4B.9`, `2.1.5` |
| `9.7 Build admin/operator visibility for lifecycle state` | `partial` | admin/governed-envelope/kernel-graph surfaces already exist and can show bounded review state | admin still lacks normalized lifecycle fields like `artifactClass`, `artifactState`, retention mode, expiry timestamp, and quarantine reason across replay/training/intake artifacts | `12.4B.10`, `10.9.22`, `10.9.23`, `10.9.24`, `10.9.25` |
| `9.8 Add canonical acceptance gates before durability` | `partial` | the replay/training runbook already assumes accepted artifact families and governed review gates; upward-learning packaging already distinguishes candidate-style review from downstream truth | no single durability validator yet enforces provenance, eval refs, raw-content flags, and retention classification before an artifact becomes canonical | `12.4B.7`, `12.4B.8`, `10.9.1` |
| `9.9 Add tests proving death actually happens` | `partial` | tests already exist around governed upward intake, queue behavior, and locality mesh cache behavior | no full test matrix yet proves replay staging deletion, partition expiry, raw AI2AI non-promotion, superseded-state retirement, and rejection/quarantine non-reuse end to end | `12.4B.10`, `10.9.1` |

---

## 3. What Already Exists And Should Be Treated As Real

These primitives are already materially present and should not be redescribed as future invention:

1. Receipt-backed upward artifacts with source scope, destination ceiling, expiry, content hash, and attestation:
   - `runtime/avrai_runtime_os/lib/services/intake/intake_models.dart`
   - `runtime/avrai_runtime_os/lib/services/intake/upward_air_gap_service.dart`
2. Caller-issued air-gap requirement for personal/AI2AI-style upward sources:
   - `runtime/avrai_runtime_os/lib/services/reality_model/governed_upward_learning_intake_service.dart`
3. Persisted governed learning envelopes and review queue lineage:
   - `runtime/avrai_runtime_os/lib/services/reality_model/governed_upward_learning_intake_service.dart`
   - `runtime/avrai_runtime_os/lib/services/intake/universal_intake_repository.dart`
4. AI2AI queue expiry behavior:
   - `runtime/avrai_runtime_os/lib/ai2ai/message_queue_service.dart`
5. Temporary locality mesh cache with TTL:
   - `runtime/avrai_runtime_os/lib/services/locality_agents/locality_agent_mesh_cache.dart`
6. Replay export, staging, partition, and upload/index seams:
   - `runtime/avrai_runtime_os/lib/services/prediction/bham_replay_storage_export_service.dart`
   - `runtime/avrai_runtime_os/lib/services/prediction/bham_replay_storage_partition_service.dart`
   - `runtime/avrai_runtime_os/lib/services/prediction/bham_replay_supabase_upload_index_service.dart`

These existing pieces are the implementation base for Section 9. They are not the completed end state.

---

## 4. What Is Still Missing In Concrete Terms

The largest remaining gaps are:

1. one normalized lifecycle schema across replay/training/intake/admin surfaces
2. hard fail-closed validation of caller-issued air-gap receipts before persistence
3. automatic TTL or archive/delete enforcement for replay staging and partition outputs
4. configurable AI2AI message-retention policy instead of implicit permanent local retention
5. explicit supersession and retirement rules for stateful AI2AI artifacts
6. admin visibility into lifecycle/retention state
7. tests that prove deletion, expiry, and non-promotion of raw content

---

## 5. Recommended Execution Order

The safest build order is:

1. `12.4B.7`
   - add lifecycle metadata and acceptance semantics first
2. `12.4B.8`
   - enforce fail-closed upward durability rules second
3. `12.4B.9`
   - add retention configuration and expiry/supersession automation third
4. `12.4B.10`
   - finish with admin visibility and the proving-test matrix

This order matters because expiry and admin visibility become ambiguous if lifecycle class/state does not exist first.

---

## 6. File Ownership Slice

Initial implementation ownership should be treated as:

### Lifecycle metadata + durability

- `runtime/avrai_runtime_os/lib/services/intake/intake_models.dart`
- `runtime/avrai_runtime_os/lib/services/intake/universal_intake_repository.dart`
- `runtime/avrai_runtime_os/lib/services/reality_model/governed_upward_learning_intake_service.dart`
- `runtime/avrai_runtime_os/lib/services/prediction/bham_replay_training_export_manifest_service.dart`
- `runtime/avrai_runtime_os/lib/services/prediction/bham_replay_storage_export_service.dart`
- `runtime/avrai_runtime_os/lib/services/prediction/bham_replay_storage_partition_service.dart`
- `runtime/avrai_runtime_os/lib/services/prediction/bham_replay_supabase_upload_index_service.dart`

### AI2AI retention + supersession

- `runtime/avrai_runtime_os/lib/ai2ai/message_queue_service.dart`
- `runtime/avrai_runtime_os/lib/ai2ai/anonymous_communication.dart`
- `runtime/avrai_runtime_os/lib/services/chat/dm_message_store.dart`
- `runtime/avrai_runtime_os/lib/services/community/community_message_store.dart`
- `runtime/avrai_runtime_os/lib/services/locality_agents/locality_agent_mesh_cache.dart`
- `runtime/avrai_runtime_os/lib/ai2ai/locality/incoming_locality_agent_update_processor.dart`

### Admin visibility

- `apps/admin_app/lib/ui/pages/admin_command_center_page.dart`
- `apps/admin_app/lib/ui/pages/reality_system_oversight_page.dart`
- any world-model/training/replay admin state services that surface lifecycle state

### Tests

- governed upward intake tests
- replay export/partition/upload tests
- AI2AI queue tests
- locality mesh cache tests
- new end-to-end lifecycle deletion/non-promotion tests

---

## 7. Acceptance Meaning

Section 9 should only be considered complete when:

1. artifacts can be classified as canonical/archive/staging/temporary/quarantine
2. upward durability fails closed on invalid or unsafe air-gap artifacts
3. replay staging and partition layers expire automatically
4. AI2AI raw content remains local UX state unless separately governed
5. superseded stateful AI2AI artifacts are retired from hot paths
6. operators can inspect lifecycle and retention truth in admin
7. tests prove expiry, deletion, non-promotion, and quarantine behavior

Until then, AVRAI has persistence primitives and partial hygiene, not full governed persistence.
