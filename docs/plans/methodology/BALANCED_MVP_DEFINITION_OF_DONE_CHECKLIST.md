# Balanced MVP — Definition of Done (DoD) Checklist

**Strategy:** **2 (Offline AI2AI parity first)**  
**Purpose:** A single-page, non-negotiable checklist to declare a “balanced MVP” **done** across *all* core pillars: **doors UX**, **offline-first**, **privacy moat**, **AI learning**, **AI2AI network**, and **expertise/economic enablement**.

---

## Non‑Negotiables (must be true)

- [ ] **Doors philosophy enforced**: every surfaced recommendation/event/community/connection is framed as a “door” and respects timing + autonomy (see `OUR_GUTS.md`, `docs/plans/philosophy_implementation/DOORS.md`).
- [ ] **Offline‑first**: the app remains meaningfully usable with no internet (local data, local inference paths, local UX) and degrades gracefully.
- [ ] **Privacy and control are non‑negotiable**: no personal identifiers leak into AI2AI payloads; explicit user consent for any passive sensing.
- [ ] **ai2ai only**: device‑to‑device interactions are mediated through the AI personality layer (not direct “user to user” data exchange).
- [ ] **No production `print()`**: logging uses `developer.log()` / `AppLogger` per standards.

---

## Track A — Privacy moat (identity separation + encryption)

**Goal:** user identity is never required for AI2AI routing, and mappings are protected end‑to‑end.

- [ ] **AgentID mapping works end‑to‑end** (create, read, cache, rotate): `lib/core/services/agent_id_service.dart`
- [ ] **Mappings are encrypted at rest** using AES‑256‑GCM with secure storage keys: `lib/core/services/secure_mapping_encryption_service.dart`
- [ ] **RLS verified** for mapping tables (user can access only their mapping; audit log cannot deanonymize).
- [ ] **Message encryption works on-device**:
  - [ ] Primary path: **Signal Protocol** (best-case scenarios)
  - [ ] Fallback path: **AES‑256‑GCM** (only when Signal bootstrap/session is unavailable)
  - Evidence: `lib/core/services/signal_protocol_initialization_service.dart`, `lib/core/services/message_encryption_service.dart`, `lib/core/services/hybrid_encryption_service.dart`
- [ ] **“Signal across the app” enforcement**: app messaging uses DI’s `MessageEncryptionService` (no direct defaulting to `AES256GCMEncryptionService()` inside production services; exceptions must be documented).
- [ ] **Anonymous payload validation blocks PII** (deep recursive + pattern scan): `lib/core/ai2ai/anonymous_communication.dart`

---

## Track B — Offline-first core user doors (value without internet)

**Goal:** the user can “get life” from SPOTS without connectivity.

- [ ] **Local persistence is reliable** (Sembast + Storage init, no crash loops): `lib/main.dart`, `lib/injection_container_core.dart`
- [ ] **Offline UX is explicit** (indicator + graceful fallbacks, no “empty mystery” screens):
  - `lib/presentation/widgets/common/offline_indicator_widget.dart` (and related offline UI)
- [ ] **Core actions work offline** (at minimum): browse saved spots/lists, view “your doors,” create/save lists, view recommendations cached/on-device.
- [ ] **Event queue exists for deferred sync** (offline actions don’t vanish): `lib/core/ai/event_queue.dart`, `lib/core/ai/event_logger.dart`

---

## Track C — On-device learning + recommendation loop (doors get better)

**Goal:** a closed loop from user behavior → learning → better doors, without cloud dependency.

- [ ] **On-device vibe compilation works** (deterministic, stable, performant): `lib/core/ai/vibe_analysis_engine.dart`
- [ ] **Personality learning persists + evolves** (with timestamps/temporal support): `lib/core/ai/personality_learning.dart`, `spots_core/services/atomic_clock_service.dart`
- [ ] **Recommendation loop is user-visible and attributable** (“why this door?” at least at a basic level).
- [ ] **No synthetic “fake learning”** in production paths (real signals only; experiments can differ per protocols).

---

## Track D — Offline AI2AI parity (the Strategy 2 core)

**Goal:** nearby devices can discover each other and exchange **anonymized** personality/vibe signals **without internet** on both iOS and Android.

### D1. Physical discovery must be real (not stubbed)

- [ ] **DI wires real platform discovery**, not stub:
  - Current blocker to fix: `DeviceDiscoveryFactory.createPlatformDiscovery()` returns `StubDeviceDiscovery()` unconditionally (`packages/spots_network/lib/network/device_discovery_factory.dart`).
  - DoD requires production wiring to use **Android/iOS/Web** implementations as appropriate.
- [ ] **Device scanning works in foreground** on:
  - [ ] Android: BLE scan (+ whatever WiFi/NSD path you choose)
  - [ ] iOS: NSD/Bonjour and/or BLE within iOS constraints
  - Evidence targets: `packages/spots_network/lib/network/device_discovery_android.dart`, `packages/spots_network/lib/network/device_discovery_ios.dart`

### D2. Advertising must be real (not placeholder)

- [ ] **Personality advertising works** (broadcast anonymized vibe signature):
  - Evidence: `packages/spots_network/lib/network/personality_advertising_service.dart`
  - DoD requires implementing platform-specific advertising (BLE +/or Bonjour/mDNS) and validating payload format/expiry.

### D3. Offline handshake + exchange is implemented and verified

- [ ] **A transport exists** for exchanging protocol packets offline (BLE GATT / local socket / Bonjour service resolution / WiFi direct, etc.).
- [ ] **Protocol layer is used** for payload correctness + encryption: `packages/spots_network/lib/network/ai2ai_protocol.dart`
- [ ] **Orchestrator can run offline** (no “skip discovery when offline” behavior):
  - Current behavior to change/verify: connectivity gate in `lib/core/ai2ai/connection_orchestrator.dart`
- [ ] **Mode 2 (offline Signal bootstrap) works**:
  - [ ] Devices can exchange **Signal prekey bundles locally** during the offline handshake (no key-server dependency for first contact).
  - Evidence targets: `lib/core/crypto/signal/signal_key_manager.dart`, `lib/core/crypto/signal/signal_protocol_service.dart`
- [ ] **Anti-tracking constraint**: offline advertising/discovery does **not** broadcast stable identifiers (no `user_id`, `agent_id`, `ai_signature`); uses **ephemeral rotating nearby IDs** and minimal capability flags.
- [ ] **End-to-end offline scenario passes**:
  - Two devices, airplane mode (or no WAN), same physical space
  - Discover each other
  - Exchange anonymized vibe signature
  - Compute compatibility locally
  - Record learning/connection metrics locally

### D4. Safety, UX, and power constraints

- [ ] **User consent** for nearby discovery/advertising is explicit and revocable.
- [ ] **Battery guardrails**: scan cadence, backoff, and “only when appropriate” rules are implemented and documented.
- [ ] **iOS/Android permission flows** are correct and tested on real devices.

---

## Track E — Expertise + economic enablement (the “life” becomes sustainable)

**Goal:** expertise unlocks real capabilities and the economic flows don’t break trust.

- [ ] **Expertise progression is functional** (not just UI): see DI wiring in `lib/injection_container_core.dart` and expertise services.
- [ ] **At least one end-to-end monetizable flow works** (even if gated/limited):
  - example: expertise → host event → revenue split → receipts/audit logs
- [ ] **Revenue split / locking rules are enforced** (no post-facto edits after lock).
- [ ] **Audit trail exists** (without deanonymizing users).

---

## Track F — Outside data-buyer insights (safe-to-sell monetization)

**Goal:** SPOTS can sell *market-level* insights without exposing personal data or enabling surveillance.

- [ ] **Outside-buyer contract implemented** (aggregate-only, delayed, coarse, DP, k-min, query budgeting):
  - Contract: `docs/plans/architecture/OUTSIDE_DATA_BUYER_INSIGHTS_DATA_CONTRACT_V1.md`
- [ ] **Hard guarantee:** exported datasets contain **no** `user_id`, `agent_id`, `ai_signature`, device identifiers, raw text, embeddings, or location history.
- [ ] **Do not reuse admin export paths** for outside buyers (admin tooling currently allows stable IDs; outside-buyer export must be stricter).
- [ ] **DP + suppression enforced** (k-min threshold + dominance rules + 72h+ delay).
- [ ] **Auditable export logs** exist (who/when/what slice) without leaking user-level data.

---

## MVP Exit Criteria (must be demonstrable)

- [ ] **Demo A (Doors):** “Find me a spot” → user goes → it becomes a recurring door → community door suggested at the right time.
- [ ] **Demo B (Offline):** same experience works **offline** using local data + on-device inference + cached doors.
- [ ] **Demo C (Offline AI2AI):** two nearby devices discover + exchange anonymized vibe signatures offline and produce a local compatibility/connection.
- [ ] **Demo D (Privacy):** prove (via logs/tests) no PII fields can cross AI2AI boundaries; payload validator blocks violations.
- [ ] **Demo E (Economic):** at least one expertise-based action unlocks a real flow and produces a verifiable outcome.
- [ ] **Demo F (Outside buyer):** generate/export one sample `spots_insights_v1` slice that satisfies the outside-buyer contract (DP metadata present; k-min enforced; 72h+ delay; no stable IDs).

---

## Minimum Test/Verification Set (must be green)

- [ ] **Unit tests** for encryption + payload validation + anonymization.
- [ ] **Integration tests** for agent mapping (create/read/rotate) and offline persistence.
- [ ] **Real-device test run** (documented) for Android + iOS offline discovery + advertising + exchange.
- [ ] **Privacy contract tests** for outside-buyer export (deny-list scan + k-min + DP metadata + delay enforcement).
- [ ] **Regression check**: app boots cleanly; no crash loops in `lib/main.dart` init path.

---

## Known Strategy-2 Blocking Gaps (as of now, from codebase)

- **Stub discovery is wired by default** via `DeviceDiscoveryFactory.createPlatformDiscovery()` → `StubDeviceDiscovery()`.
- **Advertising calls out “placeholder” for BLE advertising** and needs platform implementation.
- **Orchestrator currently treats no connectivity as “skip discovery”** which contradicts offline AI2AI parity.
- **Admin export tooling currently treats stable IDs as allowed** (e.g., `user_id` in admin exports) — outside-buyer exports must be stricter by contract.
- **Outside-buyer export pipeline is not yet implemented** (must be a separate path from admin/business tooling).

