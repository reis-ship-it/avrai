# Geographic DTN & Wormhole Routing Architecture

**Date:** March 2, 2026  
**Status:** Planned / Architecture Phase  
**Purpose:** Define the routing mechanics for long-distance multi-hop mesh (Carrier Pigeon) and cloud-bridged DTN (Wormhole).

---

## 1. Architectural Placement

This system lives entirely in the **Runtime layer**, specifically bridging:
1. `runtime/avrai_network`: The physical transport layer (BLE, WiFi Direct, Supabase APIs).
2. `runtime/avrai_runtime_os`: The intelligent routing logic, queues, and policies.

*Note: The App layer only sees the final decrypted messages. The Engine layer only provides the math for whether two nodes are compatible enough to swap. The Runtime does the heavy lifting of moving the data.*

---

## 2. Core Concepts

### A. The "Carrier Pigeon" (Pure Offline DTN)
Messages travel physically via user movement. To prevent the network from collapsing under infinite message propagation, we enforce **Spatial Decay** and **Expertise-Based Hop Scaling**.

### B. The "Wormhole" (Proxy Cloud Bridging)
If Node A has no internet, but passes Node B (which has internet), Node B acts as a Wormhole. It takes Node A's encrypted outbox blob and uploads it to the ephemeral cloud queue on Node A's behalf, instantly bridging the geographic gap to the recipient.

---

## 3. Data Structures

### `RoutingEnvelope` (Unencrypted Header)
Because the payload is encrypted (Signal Protocol), intermediate nodes cannot read the message to know if they should drop it. We need an unencrypted routing header attached to the blob:
*   `originGeohash`: Where the message started (e.g., NYC).
*   `geographicScope`: Enum (`locality`, `city`, `region`, `global`).
*   `currentHops`: Integer tracking how many phones have carried it.
*   `maxHops`: Integer derived from the sender's expertise level.
*   `expirationEpoch`: When the message self-destructs.
*   `isWormholeEligible`: Boolean. Private DMs are eligible; local pheromones are NOT.
*   `scentVibe`: Lightweight 12D unencrypted math array. Used to route pheromones efficiently to compatible carriers so cheap-tier pheromones aren't wasted on incompatible users. Also helps AI agents share frequent spots and events more accurately over the mesh.

---

## 4. Required Services & Implementation Steps

### Step 1: Upgrade `KnowledgeVector` & `MessagePayload`
- **Action:** Add the `RoutingEnvelope` header to all mesh payloads.
- **Location:** `runtime/avrai_runtime_os/lib/ai2ai/models/`

### Step 2: Implement `SpatialDecayEnforcer` (Cultural Seed Dispersal)
- **Action:** Compares the device's current Geohash to the envelope's `originGeohash`. If it exceeds the `geographicScope`, the payload is NOT forwarded to the new local mesh (preventing spam). HOWEVER, instead of just deleting it, the system extracts the 12D Quantum Vibe of the pheromone. 
  - **Personal Benefit (Contextual Personas):** Feeds into the user's `ContextEngine` to recommend similar "scented" spots in the new city. The AI evaluates an **Exploration Note** on the user's behavior (e.g., are they a "replicator" who wants NYC jazz in LA, or an "escapee" who leaves their home life behind when traveling and wants totally different vibes?).
  - **Community Benefit:** Feeds anonymously into the new city's `LocalityAgent` as a "Foreign Influence" vector, allowing cities to organically pick up trends and cultural scents brought by travelers.
- **Location:** `runtime/avrai_runtime_os/lib/services/transport/mesh/spatial_decay_enforcer.dart`

### Step 3: Build the `WormholeRelayService`
- **Action:** A background service that monitors the local BLE mesh. When it receives a message flagged as `isWormholeEligible = true`, it checks its own internet connection. If online, it anonymously pushes the blob to the Supabase `ai2ai_message_queue`.
- **Location:** `runtime/avrai_runtime_os/lib/services/transport/mesh/wormhole_relay_service.dart`

### Step 4: The Cloud Queue & Delivery Receipts
- **Action:** 
  - **Instant Deletion:** The message is deleted from the Supabase `ai2ai_message_queue` the *exact millisecond* it is downloaded to the recipient's phone. 
  - **Hard TTL Backstop:** The 60-minute pg_cron job is merely a backstop for messages where the recipient never connects to the internet.
  - **Delivery / Read Receipts:** When the message reaches the destination device, the recipient's node generates a lightweight "Delivery Confirmation" (one check mark) and routes it back to the sender via DTN/Wormhole. When the user physically opens the chat, a "Read Receipt" (second check mark / symbol) is routed back.
- **Location:** Database migration script and `MessageQueueService`.

### Step 5: Sembast Garbage Collection
- **Action:** Add a routine to `NightlyDigestionJob` that sweeps the local Sembast outbox/inbox and purges any envelopes where `DateTime.now() > expirationEpoch`.
- **Location:** `runtime/avrai_runtime_os/lib/services/passive_collection/nightly_digestion_job.dart`

---

## 5. Security & Privacy Considerations

1. **Traffic Analysis:** Wormhole uploads must strip IP addresses so the server cannot correlate the original sender's location with the proxy's IP.
2. **Hop Tampering & Replay Attacks:** A malicious user on a jailbroken phone could alter `currentHops` back to 0 to make a message bounce around forever (DDoS attack). Because `currentHops` must be mutable by carriers, the ultimate unhackable backstop is the `expirationEpoch` (Time-To-Live). The expiration time is cryptographically signed by the original sender's private key. If an attacker tries to extend the time, the signature breaks and the network instantly drops the message.
