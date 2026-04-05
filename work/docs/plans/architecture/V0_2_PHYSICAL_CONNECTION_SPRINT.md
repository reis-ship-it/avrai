# v0.2 Physical Connection & Digestion Sprint

*Date: March 2026*
*Context: We have built the mathematical and architectural foundation for the Reality Check pivot (DNA math strings, deterministic matching, passive collection, and the Serendipity Drop). This sprint is about wiring those isolated mathematical engines directly into the physical hardware (BLE, Sensors), ensuring the data is persisted locally, and building the "Nightly Digestion" cycle that generates the user's daily insights.*

## Sprint Goals

### 1. The Legacy Teardown (New)
* **Goal:** Remove the architectural debt of the pre-pivot era to prevent confusing collisions, while carefully preserving Signal Protocol for intended human communication.
* **Execution:**
  * [x] Deprecate/Remove the old active `AI2AI_Protocol` that attempted to negotiate Signal/X3DH during passive walk-bys.
  * [x] Remove active NLP Chat endpoints from the background services (we no longer chat autonomously during walk-bys).
  * [x] Clean up any background services attempting real-time LLM inference during active state.
  * **CRITICAL:** Ensure the `SignalProtocolService` and `MessageEncryptionService` remain intact and functional for intentional user-to-user and user-to-community human chats across the mesh network.

### 2. The BLE Math Exchange (Wiring Pillar 2)
* **Goal:** Replace the legacy NLP/heavy payload BLE handshake with the new 2KB `DNAEncoderService` payload.
* **Execution:** 
  * [x] Modify `AnonymousCommunicationProtocol` (and underlying `PersonalityAdvertisingService`) to broadcast and receive the `Uint8List` DNA String instead of JSON chat messages.
  * [x] Ensure the payload fits perfectly into standard BLE advertisement packets or a fast GATT characteristic read/write cycle (< 5 seconds).
  * [x] Integrate `DeterministicMatcherService` to instantly score the incoming DNA string on the receiving device.

### 3. Physical Dwell Activation (Wiring Pillar 1 & 4)
* **Goal:** Connect the `SmartPassiveCollectionService` to the real OS location and motion sensors.
* **Execution:**
  * [x] Hook up the physical geofencing/location stream to feed `PassivePing`s into the collector.
  * [x] Modify the BLE scanning cycle to wake up based on accelerometer data (Activity-Aware scanning), maximizing the chance of finding matches when sitting still at a cafe, without draining battery while driving on a highway.

### 4. Pheromone Mesh Routing (Wiring Pillar 4)
* **Goal:** Allow the devices to silently pass `KnowledgeVector`s using Epidemic Routing.
* **Execution:**
  * [x] Create a local inbox/outbox queue for vectors.
  * [x] When a high-compatibility BLE match occurs, securely swap pending outbox vectors that pass the `GovernanceKernelService` checks.

### 5. Local Persistence Layer (New)
* **Goal:** Ensure all gathered physical data survives app restarts and OS background kills, and securely syncs across devices.
* **Execution:**
  * [x] Wire the `SemanticKnowledgeStore` to the local ObjectBox/SQLite database (Added Drift tables).
  * [x] Ensure `DwellEvents`, `KnowledgeVector`s (Pheromones), and `LearnedArchetype`s are securely stored on-device, entirely offline.
  * [x] Create `SecureVaultSyncService` to allow users logging into a new device to securely E2EE sync their Soul, DNA, and Pheromones.

### 6. The "Nightly Digestion" Cycle (New)
* **Goal:** Actually process the raw data into user-facing value when conditions are right.
* **Execution:**
  * [x] Build the actual local LLM prompt chain that runs inside the `BatteryAdaptiveBatchScheduler`'s `ProcessDwellEventsJob` (Now `NightlyDigestionJob`).
  * [x] The cycle will: 1) Read the day's DwellEvents and Pheromones, 2) Run the TupleExtractionEngine (Air Gap), 3) Update the Archetype Pattern Learner, and 4) Generate tomorrow's `DailySerendipityDrop`.

### 7. Locality Agent Sync (New)
* **Goal:** Bridge the offline swarm with the global federated network.
* **Execution:**
  * [x] Add a job to the `BatteryAdaptiveBatchScheduler` that triggers the `LocalityFederatedExchangeService`.
  * [x] When on unmetered Wi-Fi and charging, upload the obfuscated, anonymous mathematical gradients to Supabase and download the latest global Locality Model.

### 8. The Trojan Horse UI (Wiring Pillar 6)
* **Goal:** Bring the `DailySerendipityDropFeed` to the forefront of the app.
* **Execution:**
  * [x] Hook the feed widget into the app's main navigation or home screen (Tab 0).
  * [x] Connect the UI to the local database so it loads the real `DailySerendipityDrop` outputted by the Nightly Digestion cycle (via SharedPreferences).
  * [x] Wire the "Sync" button on the `KnotEncounterCard` to trigger a secure Pheromone exchange or reveal the encounter details.

## Outcome
By the end of this sprint, the end-to-end loop will be closed: 
1. Legacy systems blocking performance are removed.
2. Devices gather encounters/dwells passively during the day.
3. At night (when plugged in), the local AI digests the math and syncs with the region.
4. The next morning, the user wakes up to a beautiful, personalized serendipity feed generated entirely offline.
