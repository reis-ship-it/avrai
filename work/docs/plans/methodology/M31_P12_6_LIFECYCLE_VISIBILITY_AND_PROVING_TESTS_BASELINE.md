# M31-P12-6 Lifecycle Visibility And Proving Tests Baseline

**Date:** 2026-04-05  
**Primary anchors:** `12.4B.10` with follow-through from `12.4B.8` and `12.4B.9`  
**Status:** Active baseline  
**Purpose:** Turn the remaining lifecycle-visibility and proving-test work into an explicit execution slice so AVRAI can prove that governed training/simulation/AI2AI retention rules are not just implemented in isolated lanes, but visible to operators and enforced end to end.

---

## 1. What Is Already True

The following slices are already materially implemented:

1. governed artifact lifecycle metadata exists as a shared contract and is emitted in intake + replay/training lanes
2. governed upward intake now fails closed on receipt expiry, destination/stage mismatch, and request-binding mismatch
3. replay staging and partition artifacts now carry retention metadata and have cleanup automation
4. DM/community/multi-device transport now persists locally before consume and exposes retention telemetry through the admin runtime surface

This means `12.4B.10` is not starting from zero. The remaining work is cross-surface visibility normalization and proving tests that exercise deletion, expiry, supersession, and non-promotion behavior outside the narrow targeted files.

---

## 2. Broad-Pass Reality Check (2026-04-05)

The post-implementation confidence sweep produced three categories of signal:

### Green in the changed lane

The following targeted surfaces are green and should be treated as the verified baseline for the current slice:

1. runtime retention/admin telemetry:
   - `runtime/avrai_runtime_os/test/services/admin/admin_runtime_governance_service_test.dart`
   - `runtime/avrai_runtime_os/test/services/device_sync/multi_device_message_service_test.dart`
   - `runtime/avrai_runtime_os/test/services/ai_infrastructure/ai2ai_transport_retention_telemetry_store_test.dart`
2. admin UI surfaces:
   - `apps/admin_app/test/ui/widgets/mesh_trust_diagnostics_panel_test.dart`
   - `apps/admin_app/test/widget/pages/admin/ai2ai_admin_dashboard_test.dart`
   - `apps/admin_app/test/widget/pages/admin/ai2ai_admin_dashboard_stream_test.dart`
3. DM/community transport contract surfaces:
   - `apps/avrai_app/test/unit/services/friend_chat_service_test.dart`
   - `apps/avrai_app/test/unit/services/community_chat_service_test.dart`
   - `apps/avrai_app/test/unit/services/chat_signal_transport_contract_test.dart`

### Real follow-on surfaced by stronger fail-closed rules

At least one broader app-unit test is now failing for a reason that belongs to the persistence-governance lane, not to unrelated native-kernel debt:

1. `apps/avrai_app/test/unit/services/recommendation_why_explanation_service_test.dart`
   - failure: `airGapArtifact request binding mismatch ... sanitizedPayload missing required binding chatId`
   - interpretation: some app-side handcrafted or older helper-issued personal-origin receipts still do not satisfy the stricter request-binding contract

This was the first concrete proving-test follow-up item for `12.4B.10`.

### First proving follow-up now closed

The first proving follow-on is now complete:

1. `apps/avrai_app/test/unit/services/recommendation_why_explanation_service_test.dart`
   - fixed by updating the handcrafted personal-origin receipt to include the required request-binding fields for `personal_agent_human_intake`
   - verified green with the focused recommendation-why suite
2. adjacent governed-learning recommendation proof surfaces were rerun and are green:
   - `apps/avrai_app/test/unit/services/event_recommendation_service_test.dart`
   - `apps/avrai_app/test/unit/services/explore_discovery_service_test.dart`
3. one neighboring event-ranking test needed a harness correction unrelated to receipt validation:
   - the Austin event in the governed-domain-consumer-state test now gets a locality-sensitive baseline match score so the test actually exercises governed-state ordering instead of failing below the recommendation threshold floor

### Broad-sweep closeout now green

The broad confidence sweep that originally surfaced neighboring failures is now green for the current package surfaces that matter to this slice:

1. full admin package test bucket:
   - `flutter test apps/admin_app/test`
2. full app unit-services bucket:
   - `flutter test apps/avrai_app/test/unit/services`
3. the remaining broad-sweep blockers that were initially surfaced and are now closed in or adjacent to this slice:
   - `apps/avrai_app/test/unit/services/recommendation_why_explanation_service_test.dart`
   - `apps/avrai_app/test/unit/services/ai_command_processor_test.dart`
   - `apps/avrai_app/test/unit/services/signatures/signature_layer_test.dart`
   - `apps/avrai_app/test/unit/services/vibe_kernel_persistence_service_test.dart`
   - `apps/avrai_app/test/unit/services/reality_model_checkin_service_test.dart`
   - `apps/admin_app/test/ui/widgets/recommendation_why_preview_card_test.dart`
   - `runtime/avrai_runtime_os/lib/services/admin/signature_health_admin_service.dart`
   - `runtime/avrai_runtime_os/tool/build_bham_replay_calibration.dart`
   - `runtime/avrai_runtime_os/test/services/vibe/vibe_kernel_fallback_state_test.dart`

This means the package-health fallout that was initially separated from `12.4B.10` no longer blocks the current proving/visibility closeout baseline.

---

## 3. `12.4B.10` Scope

`12.4B.10` should be treated as three concrete workstreams:

### A. Operator visibility

Operators must be able to inspect:

1. lifecycle class, state, and retention mode for governed artifacts
2. retention expiry/cleanup outcomes for replay staging and partition outputs
3. AI2AI transport retention outcomes and lingering failures
4. supersession state for hot-path locality/AI2AI cache artifacts

### B. Proving tests

CI must prove:

1. expired staging dies
2. successful upload cleanup deletes only managed replay staging roots
3. superseded hot-path state is marked retired and not reused as current truth
4. raw AI2AI/user-origin content does not silently become durable canonical learning state
5. malformed or under-bound personal-origin receipts fail before durable persistence

### C. Broader consumer normalization

The proving-test sweep must also flush out older app/runtime helpers that still generate incomplete receipts or assume permissive pre-binding behavior.

---

## 4. First Execution Order

### Step 1. Fix the first request-binding proving failure

Target:

1. `apps/avrai_app/test/unit/services/recommendation_why_explanation_service_test.dart`

Goal:

1. update the test helper / staged artifact so the personal-origin receipt includes the required request-binding fields (`chatId` and any adjacent bound keys for that lane)
2. keep the failure-path assertion in place elsewhere so the suite still proves fail-closed behavior rather than weakening the new contract

Status:

1. complete on 2026-04-05
2. focused verification green:
   - `apps/avrai_app/test/unit/services/recommendation_why_explanation_service_test.dart`
   - `apps/avrai_app/test/unit/services/event_recommendation_service_test.dart`
   - `apps/avrai_app/test/unit/services/explore_discovery_service_test.dart`

### Step 2. Normalize operator/admin lifecycle visibility

Targets:

1. `runtime/avrai_runtime_os/lib/services/admin/admin_runtime_governance_service.dart`
2. `apps/admin_app/lib/ui/pages/ai2ai_admin_dashboard.dart`
3. `apps/admin_app/lib/ui/widgets/mesh_trust_diagnostics_panel.dart`
4. replay admin/read surfaces as needed

Goal:

1. expose lifecycle class/state/retention truth consistently, not only AI2AI transport retention telemetry

Status:

1. materially complete on 2026-04-05 for the current admin surface
2. delivered through:
   - `runtime/avrai_runtime_os/lib/services/admin/admin_runtime_governance_service.dart`
   - `apps/admin_app/lib/ui/pages/ai2ai_admin_dashboard.dart`
   - `apps/admin_app/lib/ui/widgets/mesh_trust_diagnostics_panel.dart`
3. focused verification green:
   - `runtime/avrai_runtime_os/test/services/admin/admin_runtime_governance_service_test.dart`
   - `apps/admin_app/test/ui/widgets/mesh_trust_diagnostics_panel_test.dart`
   - `apps/admin_app/test/widget/pages/admin/ai2ai_admin_dashboard_test.dart`
   - `apps/admin_app/test/widget/pages/admin/ai2ai_admin_dashboard_stream_test.dart`

### Step 3. Add proving-test matrix beyond narrow targeted files

Targets:

1. app-unit surfaces that handcraft governed receipts
2. replay retention cleanup tests
3. locality supersession tests
4. negative tests for raw-content non-promotion

Goal:

1. convert the current targeted green lane into a broader proving matrix that catches drift in helper-issued receipts and stale permissive assumptions

Status:

1. materially in progress on 2026-04-05 with the first broad proof tranche landed
2. explicit proofs now cover:
   - replay cleanup refusing unmanaged roots
   - locality hot-cache supersession using only the latest mesh state
   - AI2AI queue/transport/history/cache artifacts remaining non-training-eligible
   - governed upward review artifacts staying `canonical/candidate` with bounded raw/message-content flags instead of being misread as accepted training state
   - malformed personal-agent human receipts failing before source/review persistence
3. focused verification green:
   - `runtime/avrai_runtime_os/test/services/prediction/bham_replay_artifact_retention_service_test.dart`
   - `runtime/avrai_runtime_os/test/services/locality_agents/locality_agent_mesh_cache_test.dart`
   - `runtime/avrai_runtime_os/test/config/ai2ai_retention_config_test.dart`
   - `runtime/avrai_runtime_os/test/services/admin/admin_runtime_governance_service_test.dart`
   - `apps/admin_app/test/ui/widgets/mesh_trust_diagnostics_panel_test.dart`
   - `apps/avrai_app/test/unit/services/governed_upward_learning_intake_service_test.dart`
   - broader neighboring governed-receipt surfaces:
     - `apps/avrai_app/test/unit/services/user_governed_learning_projection_service_test.dart`
     - `apps/avrai_app/test/unit/services/user_governed_learning_control_service_test.dart`
     - `apps/avrai_app/test/unit/services/recommendation_why_explanation_service_test.dart`
     - `apps/avrai_app/test/unit/services/personality_agent_chat_governed_learning_projection_test.dart`
     - `apps/avrai_app/test/widget/pages/profile/data_center_page_test.dart`
4. one unrelated compile blocker surfaced during the wider sweep and is now closed:
   - `runtime/avrai_runtime_os/lib/services/admin/signature_health_admin_service.dart` had a stray `resolvedAt` / `sourceMetadata` typo in the family-restage-apply branch
   - fixed and verified with focused `dart analyze`, after which the broader neighboring governed-receipt sweep ran green
5. the broader confidence pass is now green, not just the targeted lane:
   - `flutter test apps/admin_app/test`
   - `flutter test apps/avrai_app/test/unit/services`

---

## 5. Acceptance Criteria

`12.4B.10` should only count as materially complete when:

1. admin/operator surfaces expose lifecycle/retention truth beyond isolated transport telemetry
2. the known request-binding proving failure is fixed without weakening fail-closed behavior
3. CI has explicit expiry/deletion/non-promotion assertions across replay, AI2AI, and governed-upward paths
4. older handcrafted receipt helpers in app/runtime tests are normalized or explicitly fail for the right reason
5. the broader admin-app and app unit-services package sweeps are green after the persistence-governance hardening changes

---

## 6. Out Of Scope For This Slice

The following broad-pass failures are real, but they do not belong inside this lifecycle-visibility slice:

1. native governance-kernel and trajectory-kernel availability gaps in unrelated runtime suites
2. stale generated mocks for admin auth contract drift
3. expression-kernel-native failures in unrelated app command processing tests
4. unrelated admin widget regressions outside lifecycle/retention/operator-visibility surfaces

Those should be tracked separately so `12.4B.10` remains focused on persistence-governance truth and proofs.
