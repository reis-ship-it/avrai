# AI2AI Discovery and Feeds Data Flow

**Status:** Active reference  
**Purpose:** Document how discovery (spots, events, locality) and feeds use the private AI2AI learning network so the home and discovery UI can reflect "network wisdom" without leaving the app.

---

## Overview

Discovery and feeds are driven or enriched by AI2AI learning insights. All traffic stays in-app: BLE/WiFi Direct mesh plus Supabase message queue and local Sembast persistence. No new transport is introduced.

---

## Data Sources

1. **Learning insights** – Handled in [ConnectionOrchestrator](lib/core/ai2ai/connection_orchestrator.dart):
   - `_handleIncomingLearningInsight()` processes incoming learning insights (dimension evolution, locality agent updates).
   - Insights are forwarded via mesh policy (`MessageType.learningInsight`), optionally persisted via LedgerAuditV0 when enabled.
   - ContinuousLearningSystem applies insights; locality agent updates are handled by `_handleIncomingLocalityAgentUpdate()`.

2. **Delivered messages** – [AnonymousCommunicationProtocol](lib/core/ai2ai/anonymous_communication.dart):
   - `getDeliveredMessages(senderAgentId, targetAgentId)` returns decrypted, locally stored messages for a conversation (Sembast store `ai2ai_delivered_messages`).
   - Use for chat history and for any feed that surfaces recent AI2AI-derived content (e.g. recommendations, trust updates) keyed by agent pair.

3. **Queue (in-flight)** – [MessageQueueService](lib/core/ai2ai/message_queue_service.dart) + Supabase `ai2ai_message_queue`:
   - Messages expire after 60 minutes. Used for delivery; not the primary source for feed content (delivered messages are).

---

## Feed / Coordination Path

- **Home or discovery UI** can consume "network wisdom" by:
  1. **Learning insights:** Already applied inside the orchestrator (ContinuousLearningSystem, locality agents). Discovery services (spots, events, recommendations) that use personality/vibe/quantum matching implicitly benefit from this learning; no extra feed API is required for the learning itself.
  2. **Delivered messages:** For a feed that shows recent AI2AI-derived items (e.g. "suggestions from the network"), the app can call `AnonymousCommunicationProtocol.getDeliveredMessages(senderAgentId, targetAgentId)` for the local user’s agent and a chosen peer (or aggregate over peers). Decrypted content can drive local trends, event suggestions, or coordination cues.
  3. **Locality agent updates:** Received via `_handleIncomingLocalityAgentUpdate()`; they update locality-level state used for geographic discovery and scope.

- **Implementation note:** To expose a dedicated "network wisdom" feed on home or explore:
  - Add a small service or use-case that (a) optionally calls `getDeliveredMessages` for the current agent and one or more peers, and (b) maps message types (e.g. `recommendationShare`, `learningInsight` metadata) to feed items (trends, event suggestions).
  - Keep all access through existing in-app services (orchestrator, protocol); no external API reads this data.

---

## Flow Diagram (Conceptual)

```
User device (app)
  → ConnectionOrchestrator (discovery, BLE/WiFi Direct, learning handlers)
  → AnonymousCommunicationProtocol (send/receive, encrypt, queue, persist)
  → MessageQueueService (Supabase queue, 60-min TTL)
  → Sembast (delivered messages, permanent)
  → ContinuousLearningSystem / locality agents (apply insights)
  → Discovery UI (spots, events, recommendations) + optional feed (getDeliveredMessages)
```

---

## Key Files

- [lib/core/ai2ai/connection_orchestrator.dart](lib/core/ai2ai/connection_orchestrator.dart) – Learning insight handlers, locality agent updates, mesh send/receive.
- [lib/core/ai2ai/anonymous_communication.dart](lib/core/ai2ai/anonymous_communication.dart) – `getDeliveredMessages()`, `getDecryptedMessageContent()`, queue and Sembast persistence.
- [lib/core/ai2ai/message_queue_service.dart](lib/core/ai2ai/message_queue_service.dart) – Supabase-backed message queue.
