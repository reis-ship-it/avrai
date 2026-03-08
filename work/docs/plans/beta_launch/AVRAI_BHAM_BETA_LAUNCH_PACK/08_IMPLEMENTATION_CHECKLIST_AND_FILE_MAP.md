# Implementation Checklist And File Map

## Purpose

This checklist translates the Birmingham beta launch pack into concrete implementation lanes tied to current repo files.

This document is not a claim that all listed capabilities are complete today. It is a file-aware execution map showing:

- where the current anchors already live
- what must be aligned to the launch pack
- what must be added, tightened, or rewritten before wave 1 is truly launch-ready

## Status Legend

- `Anchor exists`: a relevant implementation surface already exists
- `Adapt`: current surface exists but does not yet match the launch-pack contract
- `Add`: new code, data contract, or wiring likely required

## 1. User App: Onboarding And Identity

### Anchor Files

- `apps/avrai_app/lib/presentation/pages/onboarding/onboarding_page.dart`
- `apps/avrai_app/lib/presentation/pages/onboarding/open_intake_page.dart`
- `apps/avrai_app/lib/presentation/pages/onboarding/combined_permissions_page.dart`
- `apps/avrai_app/lib/presentation/pages/onboarding/legal_acceptance_dialog.dart`
- `apps/avrai_app/lib/presentation/pages/onboarding/social_media_connection_page.dart`
- `apps/avrai_app/lib/presentation/pages/onboarding/data_intake_connection_page.dart`
- `apps/avrai_app/lib/presentation/pages/onboarding/ai_loading_page.dart`
- `apps/avrai_app/lib/presentation/pages/onboarding/knot_birth_page.dart`
- `apps/avrai_app/lib/presentation/pages/onboarding/knot_discovery_page.dart`
- `runtime/avrai_runtime_os/lib/services/onboarding/onboarding_question_bank.dart`
- `runtime/avrai_runtime_os/lib/services/onboarding/onboarding_aggregation_service.dart`
- `runtime/avrai_runtime_os/lib/services/onboarding/initial_dna_synthesis_service.dart`
- `runtime/avrai_runtime_os/lib/controllers/onboarding_flow_controller.dart`

### Checklist

- `Adapt` Replace the current onboarding step order with the beta sequence:
  - account creation
  - mandatory questionnaire
  - privacy/beta consent
  - permissions
  - optional bridges
  - knot/DNA generation
  - walkthrough
  - first daily drop
- `Adapt` Reduce questionnaire to the launch-pack mandatory direct topics and off-limits rules
- `Adapt` Make the final freeform bio the last questionnaire step before DNA/knot creation
- `Adapt` Ensure onboarding completion is tied to first-agent boot and first tuple generation
- `Add` Device-approval gating for wave-1 beta hardware
- `Add` Stronger consent copy and acceptance logging for admin visibility, air-gap strength, and break-glass conditions

## 2. User App: Profile, Settings, And User Controls

### Anchor Files

- `apps/avrai_app/lib/presentation/pages/profile/profile_page.dart`
- `apps/avrai_app/lib/presentation/pages/profile/beta_feedback_page.dart`
- `apps/avrai_app/lib/presentation/pages/settings/privacy_settings_page.dart`
- `apps/avrai_app/lib/presentation/pages/settings/notifications_settings_page.dart`
- `apps/avrai_app/lib/presentation/pages/settings/social_media_settings_page.dart`
- `apps/avrai_app/lib/presentation/pages/settings/discovery_settings_page.dart`
- `apps/avrai_app/lib/presentation/pages/settings/motion_settings_page.dart`
- `apps/avrai_app/lib/presentation/pages/settings/on_device_ai_settings_page.dart`
- `apps/avrai_app/lib/presentation/pages/settings/help_support_page.dart`
- `apps/avrai_app/lib/presentation/widgets/settings/*`

### Checklist

- `Adapt` Add the exact beta settings controls:
  - AI2AI participation
  - BLE discovery
  - background sensing
  - health/calendar/social bridges
  - notification categories
  - direct user matching
  - online vs offline AI preference
  - air-gap strength model
- `Adapt` Keep admin sharing as necessary for beta while allowing stronger air-gap settings
- `Add` Reset actions:
  - reset recommendations
  - reset agent from locality baseline
  - disconnect bridges
  - clear chat history
  - leave clubs/communities
  - delete saved items
- `Add` Explicit delete-account semantics matching the launch pack
- `Adapt` Profile should surface:
  - knot/DNA avatar
  - behavior timeline
  - pheromone surfaces
  - AI2AI daily success count
  - short self-summary

## 3. User App: Daily Drop, Explore, And Discovery

### Anchor Files

- `apps/avrai_app/lib/presentation/pages/home/home_page.dart`
- `apps/avrai_app/lib/presentation/widgets/map/map_view.dart`
- `apps/avrai_app/lib/presentation/widgets/lists/suggested_lists_section.dart`
- `apps/avrai_app/lib/presentation/widgets/lists/suggested_list_card.dart`
- `apps/avrai_app/lib/presentation/pages/lists/suggested_list_details_page.dart`
- `apps/avrai_app/lib/presentation/pages/events/events_browse_page.dart`
- `apps/avrai_app/lib/presentation/pages/events/create_event_page.dart`
- `apps/avrai_app/lib/presentation/pages/events/event_details_page.dart`
- `apps/avrai_app/lib/presentation/pages/clubs/club_page.dart`
- `apps/avrai_app/lib/presentation/pages/communities/community_page.dart`
- `runtime/avrai_runtime_os/lib/services/recommendations/recommendation_why_explanation_service.dart`
- `runtime/avrai_runtime_os/lib/services/recommendations/recommendation_telemetry_service.dart`
- `runtime/avrai_runtime_os/lib/services/events/event_recommendation_service.dart`
- `runtime/avrai_runtime_os/lib/services/places/organic_spot_discovery_service.dart`

### Checklist

- `Adapt` Daily drop to exactly 5 items, one per category:
  - spot
  - list
  - event
  - club
  - community
- `Adapt` Refresh around the human’s learned start-of-day
- `Add` One-week repetition guard
- `Adapt` Explore to support map/list toggle across all 5 categories
- `Add` Re-select behavior for fast access to saved items by category
- `Adapt` Every recommendation card/detail should show:
  - one-sentence why
  - projected enjoyability percentage
  - save / dismiss / more like this / less like this / why did you show this
- `Add` Queue-safe creation flows for offline-first create-and-sync-later behavior

## 4. User App: Messaging And Chat

### Anchor Files

- `apps/avrai_app/lib/presentation/pages/chat/unified_chat_page.dart`
- `apps/avrai_app/lib/presentation/pages/chat/agent_chat_view.dart`
- `apps/avrai_app/lib/presentation/pages/chat/world_model_ai_page.dart`
- `apps/avrai_app/lib/presentation/pages/chat/friend_chat_view.dart`
- `apps/avrai_app/lib/presentation/pages/chat/community_chat_view.dart`
- `apps/avrai_app/lib/presentation/controllers/human_chat_controller.dart`
- `runtime/avrai_runtime_os/lib/services/user/personality_agent_chat_service.dart`
- `runtime/avrai_runtime_os/lib/services/chat/friend_chat_service.dart`
- `runtime/avrai_runtime_os/lib/services/community/community_chat_service.dart`
- `runtime/avrai_runtime_os/lib/data/database/tables/messages_table.dart`
- `runtime/avrai_runtime_os/lib/ai2ai/chat/*`
- `runtime/avrai_runtime_os/lib/ai2ai/message_queue_service.dart`

### Checklist

- `Adapt` Enforce beta persistence windows:
  - AI chat 4 weeks
  - admin chat 2 weeks
  - matched-user chat 4 weeks
  - club/community chat 4 weeks
  - event chat ephemeral after event
- `Add` Leader announcement path for clubs/communities
- `Adapt` Direct user matching to the double-opt-in, privacy-preserving path only
- `Add` Offline queueing and relay-safe delivery semantics for all human message surfaces
- `Add` Tuple/admin-safe extraction for chat oversight without rendering direct human identity

## 5. Runtime OS: Boot, Kernels, And Offline Continuity

### Anchor Files

- `apps/avrai_app/lib/main.dart`
- `apps/avrai_app/lib/di/registrars/app_service_registrar.dart`
- `runtime/avrai_runtime_os/lib/kernel/os/headless_avrai_os_bootstrap_service.dart`
- `runtime/avrai_runtime_os/lib/services/infrastructure/headless_avrai_os_availability_service.dart`
- `runtime/avrai_runtime_os/lib/kernel/os/functional_kernel_orchestrator.dart`
- `runtime/avrai_runtime_os/lib/kernel/os/kernel_prong_ports.dart`
- `runtime/avrai_runtime_os/lib/kernel/os/kernel_incident_recorder.dart`
- `runtime/avrai_runtime_os/lib/kernel/os/kernel_outcome_attribution_lane.dart`
- `runtime/avrai_runtime_os/lib/kernel/{who,what,when,where,why,how}/*`

### Checklist

- `Anchor exists` Headless runtime bootstrap and restored/live availability surfaces already exist
- `Adapt` Persist the exact beta-ready local state set on device:
  - Birmingham place graph priors
  - locality priors and DNA baselines
  - kernel state
  - tuples and learning history
  - AI2AI receipts
  - saved objects
  - queued messages/creation state
- `Add` Explicit isolated-single-device mode behavior in runtime contracts and user-facing status
- `Adapt` Separate governance truth and behavior truth in runtime decisioning
- `Add` Downward conviction flow as learned lens without automatic user-facing behavior override unless governance requires it

## 6. Runtime OS: AI2AI, Mesh, Relay, And Locality

### Anchor Files

- `runtime/avrai_runtime_os/lib/services/transport/ble/*`
- `runtime/avrai_runtime_os/lib/services/transport/mesh/*`
- `runtime/avrai_runtime_os/lib/ai2ai/locality/*`
- `runtime/avrai_runtime_os/lib/services/device/wifi_fingerprint_service.dart`
- `runtime/avrai_runtime_os/lib/services/locality_agents/*`
- `runtime/avrai_runtime_os/lib/kernel/locality/*`
- `runtime/avrai_runtime_os/lib/services/security/governance_kernel_service.dart`

### Checklist

- `Anchor exists` BLE and mesh transport lanes already exist in broad form
- `Adapt` Make wave-1 transport contract explicit:
  - BLE
  - local Wi-Fi
  - nearby relay/store-and-forward
  - wormholes as backup
- `Add` Intermediate relay TTL and queue policy
- `Add` Relay quarantine rules for:
  - malicious payloads
  - contradictions
  - spam/duplication
  - safety-risky suspicious payloads
- `Add` Explicit support for relaying user-to-user chat when internet is unavailable
- `Adapt` Locality propagation rules so conflicts rise upward and convictions can flow back downward
- `Add` AI2AI success-time metric aligned with the launch gate definition

## 7. Runtime OS: Local Models, Recommendations, And Outcome Learning

### Anchor Files

- `runtime/avrai_runtime_os/lib/services/local_llm/*`
- `runtime/avrai_runtime_os/lib/services/recommendations/*`
- `runtime/avrai_runtime_os/lib/services/onboarding/*`
- `runtime/avrai_runtime_os/lib/services/passive_collection/*`
- `runtime/avrai_runtime_os/lib/services/events/post_event_feedback_service.dart`
- `runtime/avrai_runtime_os/lib/services/recommendations/agent_happiness_service.dart`

### Checklist

- `Anchor exists` Local model auto-install and provisioning surfaces already exist
- `Adapt` Offline SLM/model pack install to the approved-device beta requirement
- `Add` Recommendation confidence contract:
  - no low-confidence proactive baseline
  - consult locality/above first
  - stay silent when still uncertain
- `Adapt` Outcome-learning weights so real-world attendance and repeat behavior outrank taps
- `Add` direct “meaningful/fun” ask-back loop tied to the recommendation/outcome pipeline
- `Add` recommendation reset semantics from locality baseline

## 8. Runtime OS: Places, Lists, Clubs, Communities, Events

### Anchor Files

- `runtime/avrai_runtime_os/lib/services/places/*`
- `runtime/avrai_runtime_os/lib/services/community/*`
- `runtime/avrai_runtime_os/lib/services/events/*`
- `runtime/avrai_runtime_os/lib/services/signatures/builders/*`
- `runtime/avrai_runtime_os/lib/services/signatures/bundles/*`

### Checklist

- `Adapt` Place graph preload + simulation + live user update path for Birmingham
- `Add` Settled-DNA rule:
  - 2 weeks of consistent real-world behavior, or
  - 3 real events/meetups/outings
- `Adapt` Event/community/club DNA to use online behavior only as initial assistance, not the final truth
- `Add` Immediate-public-create plus moderation-pause workflow
- `Add` Future-note surfaces for business ownership and expert emergence without turning them into beta roles

## 9. Admin App And Runtime Admin Services

### Anchor Files

- `apps/avrai_app/lib/apps/admin_app/navigation/admin_router.dart`
- `apps/avrai_app/lib/apps/admin_app/ui/pages/admin_command_center_page.dart`
- `apps/avrai_app/lib/apps/admin_app/ui/pages/ai_live_map_page.dart`
- `apps/avrai_app/lib/apps/admin_app/ui/pages/ai2ai_admin_dashboard.dart`
- `apps/avrai_app/lib/apps/admin_app/ui/pages/reality_system_oversight_page.dart`
- `apps/avrai_app/lib/apps/admin_app/ui/pages/governance_audit_page.dart`
- `apps/avrai_app/lib/apps/admin_app/ui/pages/beta_feedback_viewer_page.dart`
- `apps/avrai_app/lib/apps/admin_app/ui/pages/signature_source_health_page.dart`
- `apps/avrai_app/lib/apps/admin_app/ui/pages/urk_kernel_console_page.dart`
- `runtime/avrai_runtime_os/lib/services/admin/*`
- `runtime/avrai_runtime_os/lib/kernel/service_contracts/urk_governance_inspection_service.dart`
- `runtime/avrai_runtime_os/lib/kernel/contracts/urk_break_glass_governance_contract.dart`
- `runtime/avrai_runtime_os/lib/kernel/contracts/urk_governance_inspection_contract.dart`

### Checklist

- `Anchor exists` Separate secure admin app and governance surfaces already exist in the repo
- `Adapt` Ensure the required day-1 views are continuously available:
  - live Birmingham map
  - AI2AI layer
  - single-agent and locality-agent detail
  - kernel health
  - feedback inbox
  - moderation queue
  - incidents center
  - reality-model chat
- `Adapt` Enforce pseudonymous-by-default rendering across admin surfaces
- `Add` Explicit break-glass audit workflow and UI affordance for dangerous/malicious cases
- `Add` Falsity/contradiction workflow:
  - peer/locality quarantine
  - admin rollback/reset
  - failed-state preservation for study
- `Add` Expansion-gate dashboards matching the launch-pack metrics

## 10. Legal, Consent, And Beta Policy

### Anchor Files

- `runtime/avrai_runtime_os/lib/legal/privacy_policy.dart`
- `runtime/avrai_runtime_os/lib/services/misc/legal_document_service.dart`
- `apps/avrai_app/lib/presentation/pages/legal/privacy_policy_page.dart`
- `apps/avrai_app/lib/presentation/pages/legal/terms_of_service_page.dart`

### Checklist

- `Adapt` Replace or extend the current privacy policy text to reflect:
  - air-gap model
  - admin agent-level visibility
  - break-glass conditions
  - offline-first AI2AI exchange
  - one-device beta model
- `Add` Birmingham beta consent language distinct from general production legal text
- `Add` versioned consent receipt tied to the specific beta policy set

## 11. Testing, Readiness, And Evidence

### Anchor Files

- `work/scripts/run_beta_gate_tests.sh`
- `apps/avrai_app/test/unit/*`
- `apps/avrai_app/test/widget/*`
- `apps/avrai_app/test/integration/*`
- `apps/avrai_app/test/unit/kernel/*`
- `apps/avrai_app/test/unit/services/headless_avrai_os_availability_service_test.dart`
- `apps/avrai_app/test/widget/widgets/common/headless_os_status_banner_test.dart`

### Checklist

- `Adapt` Add tests for the launch-pack onboarding path and mandatory questionnaire logic
- `Add` Add tests for settings toggles and their runtime adaptation behavior
- `Add` Add tests for direct-match double-opt-in gating
- `Add` Add tests for offline queueing and later relay/sync conflict handling
- `Add` Add tests for relay quarantine and falsity thresholds
- `Add` Add admin-surface smoke tests aligned to the launch-pack must-have views
- `Add` Add metrics/evidence collection for:
  - offline-first flow completion
  - AI2AI success-time percentage
  - continuous admin-view uptime
  - recommendation action rates
  - locality stability

## Suggested Execution Order

1. onboarding + consent + permissions alignment
2. profile/settings control surface alignment
3. daily drop + explore + object behavior alignment
4. offline persistence + isolated-device contract
5. AI2AI relay + locality propagation + quarantine rules
6. admin pseudonymous oversight + falsity workflow
7. expansion-gate telemetry and tests

## Exit Condition For This Checklist

This checklist is complete only when each lane has:

- user-facing behavior aligned to the launch pack
- runtime behavior aligned to the launch pack
- admin visibility aligned to the launch pack
- explicit tests or gate evidence for the lane’s critical promises
