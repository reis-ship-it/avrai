# AI2AI In-App-Only Guarantee (User-Facing)

**Status:** Active reference  
**Purpose:** User-facing and architecture documentation: discovery, feeds, and sync use only in-app services; no external third-party access to the mesh or raw messages.

---

## User-Facing Promise

- **All discovery, feeds, and sync** for the AI2AI network run **only inside the AVRAI app**.
- **No external party** (including third-party apps or data buyers) has access to the live mesh, your raw messages, or your identity on the network.
- **Third parties** that use AVRAI’s paid API receive only **anonymous, aggregated, locality-level insights** (e.g. trends by neighborhood), never raw data or identifiers. See the [Outside Data-Buyer Insights contract](docs/plans/architecture/OUTSIDE_DATA_BUYER_INSIGHTS_DATA_CONTRACT_V1.md).

---

## Technical Guarantee

- **In-app:** Only the app process (ConnectionOrchestrator, AnonymousCommunicationProtocol, MessageQueueService, BLE/WiFi Direct stack) joins the mesh, reads/writes the Supabase queue, and reads/writes local Sembast delivered-message store.
- **Cloud:** The message queue (Supabase) is used only for in-flight delivery; its contents are not exposed to third-party API endpoints.
- **Third-party API:** Serves only pre-aggregated, anonymized datasets (e.g. spots_insights_v1) from a separate cache; it does not read the mesh, the queue, or the delivered-message store.

For the full boundary and protection checklist, see [AI2AI_NETWORK_BOUNDARY.md](AI2AI_NETWORK_BOUNDARY.md).
