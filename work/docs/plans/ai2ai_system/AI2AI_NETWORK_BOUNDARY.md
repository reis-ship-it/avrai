# AI2AI Network Boundary

**Status:** Active reference  
**Purpose:** One-page definition of what runs in-app vs. cloud, and how third-party API access is bounded so the AI2AI network operates only inside the app and is protected by design.

---

## In-App Only (What Runs Where)

### In-App (Client)

- **ConnectionOrchestrator** – BLE/WiFi Direct discovery, mesh join/leave, connection lifecycle, learning insight send/receive, locality agent updates.
- **AnonymousCommunicationProtocol** – Encrypt/decrypt, route, queue (via MessageQueueService), persist delivered messages (Sembast).
- **MessageQueueService** – Writes/reads in-flight messages to/from Supabase `ai2ai_message_queue` (60-min TTL).
- **Device discovery, mesh, local persistence** – All mesh traffic and local Sembast stores (`ai2ai_delivered_messages`, etc.) are only accessible from the app process.

### Cloud (Backend)

- **Supabase `ai2ai_message_queue`** – Short-lived queue for multi-hop delivery; not exposed to third-party API. Only the app (via MessageQueueService) and backend delivery logic use it.
- **Aggregation pipeline** – Builds anonymous, locality-based insights (e.g. spots_insights_v1) from interaction events and other non-AI2AI raw sources. No AI2AI message content or mesh data is fed into this pipeline.
- **Outside-buyer cache** – Precomputed tables/views (e.g. `outside_buyer_insights_v1_cache`) that the third-party Edge Function reads. Third-party API reads **only** from this cache with strict contract (no PII, k-min, DP, delay).

### Third-Party API

- **outside-buyer-insights Edge Function** – Serves anonymous, aggregated insights. It does **not** read the mesh, the message queue, or the delivered-message store. It reads only from the pre-aggregated cache.

---

## Boundary Rules

1. **No direct mesh access from outside.** Only the app (ConnectionOrchestrator + AnonymousCommunicationProtocol) joins the BLE/WiFi Direct mesh. Edge Functions and third parties never see mesh or queue contents.
2. **Third-party API reads only from cache.** All outside-buyer responses come from the cache; the contract (no PII, no stable IDs, k-min, DP, delay) is enforced in the pipeline and in the Edge Function.
3. **AI2AI message content and raw identifiers** are never written to tables/views that the outside-buyer pipeline reads. The aggregation pipeline uses interaction events and other product data, not AI2AI message payloads.

---

## Protection Checklist (Implementation)

- **Encryption:** Signal + hybrid in AnonymousCommunicationProtocol; no change required.
- **Auth:** Admin god-mode via AdminAuthService; third-party via API keys only. No anonymous access to admin or to raw network data.
- **Audit:** Admin actions and AI2AI security events (Network Activity Monitor) are logged; third-party API calls are logged (api_request_logs + audit). Logs are retained and access-controlled.
- **Validation:** No AI2AI message content or raw identifiers in outside-buyer outputs; deny-list and structural checks (e.g. OutsideBuyerInsightsV1Validator) enforced. Optional: automated test that outside-buyer response passes deny-list and locality k-min.

See [OUTSIDE_DATA_BUYER_INSIGHTS_DATA_CONTRACT_V1.md](../architecture/OUTSIDE_DATA_BUYER_INSIGHTS_DATA_CONTRACT_V1.md) for the data contract.
