# Ledger Event Catalog (v0)

**Date:** 2026-01-02  
**Status:** DRAFT (ready for implementation)  
**Purpose:** Define the v0 event types (“receipts”) for each ledger domain  

---

## Shared conventions

Every event written to `public.ledger_events_v0` includes:
- `domain`: one of the supported domains (see migration)
- `event_type`: a stable string
- `entity_type` / `entity_id`: what the event is about
- `payload`: JSONB with `schema_version`, `source`, optional `correlation_id`

### Recommended payload keys
- `schema_version` (int)
- `source` (string): `client|edge_function|service_role_pipeline`
- `correlation_id` (string, optional)
- `notes` (string, optional)

---

## 1) Expertise / Events / Communities / Clubs / Partnerships (domain: `expertise`)

### v0 “bridge” (to avoid breaking)
- **`expertise_level_asserted`**
  - **Why:** ledger-first gating is possible immediately without waiting for full contribution backfill.
  - **Entity:** `expertise:{userId}:{category}`
  - **Payload (min):** `{ "level": "local|city|regional|national|global|universal", "source": "expertiseMap|derived|admin_override" }`

### Matching / recommendations (Phase 19 integration receipts)
- **`quantum_matching_executed`**
  - **Why:** makes “why did I get called / matched?” explainable with a concrete receipt.
  - **Entity:** `user:{userId}`
  - **Payload (min):** `{ "atomic_timestamp_id", "entity_count", "compatibility", "quantum_compatibility", "location_compatibility", "timing_compatibility", "knot_compatibility"?, "meaningful_connection_score"? }`
- **`quantum_matching_failed`**
  - **Entity:** `user:{userId}`
  - **Payload (min):** `{ "atomic_timestamp_id"?, "error_code"?, "error" }`

### Expert events
- **`expert_event_created`**
  - Entity: `event:{eventId}`
  - Payload: `{ "category", "eventType", "startTime", "endTime", "isPaid", "price"?, "cityCode"?, "localityCode"?, "location"?, "visibility": "public|private" }`
- **`expert_event_completed`**
  - Entity: `event:{eventId}`
  - Payload: `{ "attendeeCount", "avgRating"?, "outcome": "success|cancelled|no_show|incident" }`

### Community events
- **`community_event_completed`**
  - Entity: `event:{eventId}`
  - Payload: `{ "attendeeCount", "repeatAttendeesCount", "engagementScore", "diversityMetrics", "timesHosted" }`

### Communities / clubs
- **`community_created_from_event`**
  - Entity: `community:{communityId}`
  - Payload: `{ "originatingEventId", "originatingEventType": "expertiseEvent|communityEvent" }`
- **`community_joined`**, **`community_left`**
  - Entity: `community:{communityId}`
  - Payload: `{ "role": "member" }`
- **`community_upgraded_to_club`**
  - Entity: `club:{clubId}`
  - Payload: `{ "communityId", "minMembers", "minEvents", "trigger": "manual|auto" }`
- **`club_role_granted`**, **`club_role_revoked`**
  - Entity: `club:{clubId}`
  - Payload: `{ "role": "leader|admin|moderator" }`

### Partnerships
- **`partnership_proposed`**
  - Entity: `partnership:{partnershipId}`
  - Payload: `{ "eventId", "businessId", "vibeCompatibilityScore", "type": "eventBased|ongoing|exclusive" }`
- **`partnership_locked`**
  - Entity: `partnership:{partnershipId}`
  - Payload: `{ "eventId", "termsVersion", "revenueSplitId"?, "revenueSplit"?: {} }`
- **`partnership_completed`**
  - Entity: `partnership:{partnershipId}`
  - Payload: `{ "eventId", "grossRevenue"?, "netRevenue"?, "wasDisputed": false }`
- **`partnership_disputed`**, **`partnership_resolved`**
  - Entity: `partnership:{partnershipId}`
  - Payload: `{ "eventId", "reasonCode", "resolutionCode"?, "resolutionNotes"? }`

---

## 2) Payments / Refunds / Payouts / Revenue Splits (domain: `payments`)

**Ledger purpose:** financial truth. No silent rewrites.

- **`payment_intent_created`**
  - Entity: `payment_intent:{id}` or `event:{eventId}`
  - Payload: `{ "eventId", "amount", "currency", "payerUserId", "provider": "stripe|other" }`
- **`payment_captured`**
  - Payload: `{ "amount", "providerChargeId" }`
- **`payment_failed`**
  - Payload: `{ "errorCode", "providerError"?, "amount" }`

- **`revenue_split_defined`**
  - Entity: `revenue_split:{id}`
  - Payload: `{ "eventId", "partners": [{ "partyId", "partyType", "percent" }], "platformFeePercent": 10.0 }`
- **`revenue_split_locked`**
  - Payload: `{ "lockedAt", "lockedBy": "system|service_role" }`

- **`payout_scheduled`**
  - Entity: `payout:{id}`
  - Payload: `{ "eventId", "payeeId", "payeeType", "amount", "scheduledFor" }`
- **`payout_completed`**, **`payout_failed`**
  - Payload: `{ "providerPayoutId"?, "errorCode"? }`

- **`refund_requested`**
  - Entity: `refund:{id}`
  - Payload: `{ "paymentIntentId", "requestedByUserId", "reasonCode" }`
- **`refund_approved`**, **`refund_denied`**
  - Payload: `{ "approvedBy": "policy|admin|service_role", "policyRule"?, "notes"? }`
- **`refund_completed`**, **`refund_failed`**
  - Payload: `{ "providerRefundId"?, "errorCode"? }`

---

## 3) Moderation / Safety (domain: `moderation`)

**Ledger purpose:** safety actions must be auditable and reversible only by explicit revision.

- **`report_created`**
  - Entity: `report:{id}`
  - Payload: `{ "reporterUserId", "targetType", "targetId", "reasonCode", "details" }`
- **`report_triaged`**
  - Payload: `{ "triageResult": "dismiss|investigate|urgent", "triagedBy": "admin|service_role" }`

- **`moderation_action_applied`**
  - Entity: `moderation_action:{id}`
  - Payload: `{ "action": "warn|mute|ban|suspend|content_remove", "targetType", "targetId", "durationSeconds"?, "policyRule" }`
- **`moderation_action_lifted`**
  - Payload: `{ "liftReasonCode", "liftedBy": "admin|service_role" }`

- **`safety_incident_logged`**
  - Entity: `event:{eventId}` or `incident:{id}`
  - Payload: `{ "eventId"?, "severity": "low|medium|high", "details", "resolved": false }`
- **`safety_incident_resolved`**
  - Payload: `{ "resolutionCode", "resolvedBy": "admin|service_role" }`

---

## 4) Identity / Verification (domain: `identity`)

**Ledger purpose:** “verified/unverified” status must have receipts.

- **`age_verification_submitted`**
  - Entity: `user:{userId}`
  - Payload: `{ "method": "document|provider", "provider"?, "version" }`
- **`age_verification_approved`**, **`age_verification_denied`**
  - Payload: `{ "reasonCode"?, "reviewedBy": "provider|admin|service_role" }`

- **`business_verification_submitted`**
  - Entity: `business:{businessId}`
  - Payload: `{ "documents": ["license","tax_id",...], "submittedByUserId" }`
- **`business_verification_approved`**, **`business_verification_denied`**
  - Payload: `{ "reasonCode"?, "reviewedBy": "admin|service_role|provider" }`

---

## 5) Security / Key Rotations / Policy Blocks (domain: `security`)

**Ledger purpose:** security-critical operations need append-only receipts.

- **`agent_mapping_key_rotated`**
  - Entity: `user:{userId}`
  - Payload: `{ "oldKeyId"?, "newKeyId", "rotationCount"?, "rotationBatchId"? }`
- **`security_policy_blocked`**
  - Entity: `operation:{name}`
  - Payload: `{ "reasonCode", "details"?, "actor": "system|admin" }`
- **`security_policy_unblocked`**
  - Payload: `{ "reasonCode", "actor": "admin|service_role" }`

### Signal / encrypted transport receipts (Phase 14 / device smokes)
- **`signal_prekey_bundle_rotate_started`**
  - Entity: `user:{userId}`
  - Payload: `{ "bundle_version": 2 }`
- **`signal_prekey_bundle_uploaded`**, **`signal_prekey_bundle_upload_failed`**
  - Entity: `user:{userId}`
  - Payload: `{ "ok": true|false, "device_id", "expires_at"?, "error"?, "bundle_version": 2 }`
- **`signal_prekey_bundle_fetch_started`**, **`signal_prekey_bundle_fetch_succeeded`**, **`signal_prekey_bundle_fetch_failed`**
  - Entity: `user:{recipientUserId}`
  - Payload: `{ "recipient_id", "source"?: "test_storage|offline_cache|supabase_rpc", "has_one_time_prekey"?, "error"?, "bundle_version": 2 }`

- **`signal_dm_blob_written`**, **`signal_dm_blob_write_failed`**
  - Entity: `dm_message:{messageId}`
  - Payload: `{ "message_id", "to_user_id", "from_user_id", "encryption_type", "ciphertext_base64_len"?, "error"? }`
- **`signal_dm_notification_written`**
  - Entity: `dm_message:{messageId}`
  - Payload: `{ "message_id", "to_user_id" }`
- **`signal_dm_blob_read`**, **`signal_dm_blob_read_failed`**
  - Entity: `dm_message:{messageId}`
  - Payload: `{ "message_id", "error"? }`
- **`signal_dm_decrypt_succeeded`**
  - Entity: `dm_message:{messageId}`
  - Payload: `{ "message_id", "from_user_id", "to_user_id", "encryption_type", "plaintext_len" }`

- **`signal_community_blob_written`**, **`signal_community_blob_write_failed`**
  - Entity: `community_message:{messageId}`
  - Payload: `{ "message_id", "community_id", "sender_user_id", "key_id", "algorithm", "ciphertext_base64_len"?, "error"? }`
- **`signal_community_blob_read`**, **`signal_community_blob_read_failed`**
  - Entity: `community_message:{messageId}`
  - Payload: `{ "message_id", "error"? }`

---

## 6) Geo Expansion (domain: `geo_expansion`)

**Ledger purpose:** expansion is a “door” that should be reproducible from receipts.

- **`entity_expanded_to_locality`**
  - Entity: `community:{id}` or `club:{id}`
  - Payload: `{ "eventId", "localityCode", "cityCode"?, "trigger": "event_hosted" }`
- **`entity_expanded_to_city`**
  - Payload: `{ "eventId", "cityCode", "coveragePercent" }`
- **`expansion_threshold_reached`**
  - Payload: `{ "scope": "locality|city|state|nation|global|universal", "coveragePercent" }`

---

## 7) Model lifecycle (domain: `model_lifecycle`)

**Ledger purpose:** model installs and safety gating must be auditable.

- **`model_pack_download_started`**
  - Entity: `model_pack:{packId}`
  - Payload: `{ "packId", "version", "bytesTotal"?, "source": "auto|manual" }`
- **`model_pack_installed`**
  - Payload: `{ "packId", "version", "deviceProfile"?, "success": true }`
- **`model_pack_install_failed`**
  - Payload: `{ "errorCode", "details" }`
- **`local_llm_bootstrap_applied`**
  - Entity: `user:{userId}`
  - Payload: `{ "promptVersion", "signalsUsed": ["onboarding_events", ...] }`
- **`model_safety_blocked`**
  - Payload: `{ "reasonCode", "policyVersion" }`

---

## 8) Admin export + outside-buyer ops (domain: `data_export`)

**Ledger purpose:** exports are sensitive; must be immutable receipts.

- **`admin_export_requested`**
  - Entity: `export:{id}`
  - Payload: `{ "requestedByAdminId", "exportType", "filters", "purpose" }`
- **`admin_export_generated`**
  - Payload: `{ "exportId", "rowCount", "sha256"?, "storagePath" }`
- **`admin_export_downloaded`**
  - Payload: `{ "exportId", "downloadedByAdminId" }`

- **`outside_buyer_export_run_started`**
  - Entity: `outside_buyer_run:{id}`
  - Payload: `{ "contractVersion", "cityCode"?, "timeWindow" }`
- **`outside_buyer_export_run_completed`**
  - Payload: `{ "rowCount", "sha256"?, "deliveryPath" }`

---

## 9) Device capability changes (domain: `device_capability`)

**Ledger purpose:** capabilities should be explainable and time-stamped (especially for on-device AI features).

- **`device_capability_snapshot_recorded`**
  - Entity: `user:{userId}`
  - Payload: `{ "deviceClass", "ramGb"?, "hasNeuralEngine"?, "supportsOnDeviceLlm"?, "batteryMode" }`
- **`device_capability_changed`**
  - Payload: `{ "field", "from", "to", "reason": "os_update|battery|user_setting" }`

### AI2AI network monitoring receipts (Phase 20)
- **`ai2ai_network_health_report_generated`**
  - **Why:** admins/devs can correlate health-score changes to deploys, policy toggles, and AI2AI runtime changes.
  - **Entity:** `network:ai2ai`
  - **Payload (min):** `{ "overall_health_score", "total_active_connections", "network_utilization", "ai_pleasure_average"? }`

### AI2AI walk-by + offline bootstrap receipts (Phase 23 / Phase 14)
- **`ai2ai_orchestration_init_started`**, **`ai2ai_orchestration_init_completed`**, **`ai2ai_orchestration_init_failed`**, **`ai2ai_orchestration_init_skipped`**
  - Entity: `user:{userId}`
  - Payload: `{ "ok"?, "reason"?, "allow_ble_side_effects"?, "is_test_binding"?, "is_web"?, "platform"?, "ble_node_id"?, "error"? }`
- **`ai2ai_ble_foreground_service_started`**, **`ai2ai_ble_foreground_service_failed`**
  - Payload: `{ "platform": "android" }`
- **`ai2ai_ble_prekey_payload_published`**, **`ai2ai_ble_prekey_payload_publish_failed`**, **`ai2ai_ble_prekey_payload_publish_error`**
  - Payload: `{ "ok": true|false, "bytes_len"?, "schema_version"?, "error"? }`
- **`ai2ai_signal_prekey_cached_from_peer`**
  - Payload: `{ "device_id", "peer_node_id"?, "recipient_id", "stream_id": 1, "bytes_len"? }`
- **`ai2ai_silent_bootstrap_sent`**
  - Payload: `{ "ok": true|false, "device_id", "recipient_id", "message_type": "heartbeat", "kind": "silent_signal_bootstrap" }`
- **`ai2ai_offline_signal_prime_failed`**
  - Payload: `{ "device_id", "error" }`
- **`ai2ai_learning_insight_sent`**, **`ai2ai_learning_insight_send_failed`**
  - Payload: `{ "ok"?, "peer_id", "recipient_id", "insight_id", "learning_quality"?, "delta_dimensions_count"?, "error"? }`
- **`ai2ai_learning_insight_received`**, **`ai2ai_learning_insight_receive_failed`**
  - Payload: `{ "insight_id"?, "sender_device_id", "origin_id"?, "hop"?, "learning_quality"?, "delta_dimensions_count"?, "error"? }`
- **`ai2ai_hotpath_latency_summary`**
  - Payload: `{ "count", "queue": {"p50_ms","p95_ms"}, "open": {...}, "vibe": {...}, "compat": {...}, "total": {...} }`

