# AI2AI Sync and Offline Story

**Status:** Active reference  
**Purpose:** Document how AI2AI message sync and offline behavior work so the "always connected" and "constantly learning" story is clear.

---

## Sync Model

1. **In-flight messages (queue)**
   - Stored in Supabase table `ai2ai_message_queue` via [MessageQueueService](lib/core/ai2ai/message_queue_service.dart).
   - Messages in the queue expire after **60 minutes** (TTL) for privacy.
   - Used for multi-hop routing and cloud-assisted delivery when the recipient is not on the mesh. When a message is successfully delivered, it is removed from the queue and written to local storage.

2. **Delivered messages (local persistence)**
   - After decryption and delivery, messages are stored permanently on the device in Sembast store `ai2ai_delivered_messages` (see [AnonymousCommunicationProtocol](lib/core/ai2ai/anonymous_communication.dart)).
   - Stored encrypted-at-rest; decrypted on read via `getDeliveredMessages()` / `getDecryptedMessageContent()`.
   - No TTL: delivered conversation history stays on device until the user or app clears it.

3. **Summary**
   - **Queue** = short-lived, cloud-backed, for delivery.
   - **Sembast** = long-lived, device-only, for delivered content and feed/history.

---

## Offline Behavior

- **BLE / WiFi Direct mesh:** When devices are in range, messages can be sent and received without internet. Orchestrator and protocol use the mesh for learning insights, locality updates, and user chat.
- **When offline:** Queue inserts (e.g. for multi-hop) may fail if Supabase is unreachable; mesh traffic continues. Delivered messages remain in Sembast and are available offline.
- **When back online:** Pending queue operations can succeed; CloudIntelligenceSync and other sync paths can run. No change to the 60-min queue TTL or to local delivered-message retention.

---

## Optional UX: Network Status

A small "network status" or "learning active" indicator can show users that the app is using the private AI2AI network (e.g. "AI network active" when the orchestrator is discovering or the protocol has recent activity). This is UX-only; the sync and offline behavior above do not depend on it.
