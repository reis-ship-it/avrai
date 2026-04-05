# Phase 14 (Long-Term): Signal Core + Messaging (DM + Community Sender Keys)

**Date:** January 1, 2026  
**Status:** 📋 Plan (no-shortcuts, production-grade)  
**Scope:** Direct messages + community sender-key distribution (group chat) across iOS/Android, including cross-platform and multi-device  
**Non‑Negotiable:** **Group messaging must continue to work** while Signal is upgraded (no regressions; no “rejoin” UX)

---

## 🎯 Goal

Deliver a **single, durable cryptographic core** so that:

- **DMs work**: iOS↔iOS, Android↔Android, iOS↔Android (and vice versa)
- **Community chat continues** to work:
  - Message encryption remains **O(1)** per message using **AES sender keys**
  - Sender keys are **distributed/rotated via Signal-encrypted shares**
  - Silent rekey stays seamless (no user-visible “rejoin”)
- **No “fallback” transport**: DM transport and sender-key shares must be **Signal-only** in production.

---

## ✅ Current State (Relevant)

### Community chat (group) design (keep this)

- **Message ciphertext**: `public.community_message_blobs` encrypted once with shared AES sender key.
- **Stream/event delivery**: `public.community_message_events` (payloadless notify) + RLS gating.
- **Sender keys**:
  - State: `public.community_sender_key_state`
  - Shares: `public.community_sender_key_shares` (**Signal-encrypted**)
  - Client: `lib/core/services/community_sender_key_service.dart`
    - Enforces `EncryptionType.signalProtocol` for shares (no downgrade).

### DM transport (Signal-only policy already enforced in app)

- `FriendChatService.sendMessageOverNetwork()` throws unless encryption type is `signalProtocol`.

### Known hard blocker (must be fixed for long-term)

`signal_prekey_bundles` schema/RLS must correctly support **AgentIdService-generated agent IDs**.

- Agent IDs are **not** `auth.uid()` (see `lib/core/services/agent_id_service.dart`).
- Current `supabase/migrations/022_signal_prekey_bundles.sql` uses:
  - `agent_id TEXT`
  - RLS checks `auth.uid()::text = agent_id`
  - This is incompatible with the current agent-id design and will prevent real-world Signal session establishment (DMs and sender-key shares).

---

## 🧭 Target Architecture (No-Shortcuts)

### Principle: one crypto core, one behavior everywhere

Implement Signal once and reuse it for:
- **DM encryption/decryption**
- **Community sender-key share encryption/decryption** (wrapping the AES sender key payload)
- (Optional later) AI2AI message envelope encryption

### Recommended implementation choice

**Rust core + Flutter binding generator** (e.g., `flutter_rust_bridge`):

- Rust implements:
  - identity key generation/storage hooks
  - session store + ratchet state
  - prekey generation + rotation
  - encrypt/decrypt APIs
  - multi-device addressing `(agentId, deviceId)`
- Flutter calls Rust via generated bindings (no manual Dart callback gymnastics).

This avoids long-term fragility around Dart FFI callback limitations and keeps “one crypto truth” across iOS/Android.

---

## 📦 Packaging (iOS + Android) — Production-Grade

### iOS

- Ship an **XCFramework** (or embedded framework) via a Flutter plugin:
  - embedded into the Runner target automatically
  - available via `DynamicLibrary.process()` or direct plugin init
- Ensure build steps are deterministic (CI builds the artifact).

### Android

- Ship `.so` binaries for all ABIs (arm64-v8a, armeabi-v7a, x86_64, x86) via:
  - plugin `jniLibs/`, or
  - AAR artifact included by Gradle.

### Remove ambiguity

Do not rely on “it happens to be in process” for iOS or “some libs exist” for Android. Packaging is part of the feature definition.

---

## 🗄️ Supabase “Key Server” Schema (Required for DM + Group)

### V2 schema (required)

Create a new, correct schema that separates:
- **ownership** (user_id / auth.uid)
- **routing address** (agent_id, device_id)

Proposed table (example):

`public.signal_prekey_bundles_v2`
- `user_id uuid not null references auth.users(id)`
- `agent_id text not null`
- `device_id int not null`
- `bundle_json jsonb not null`
- `created_at timestamptz not null default now()`
- `expires_at timestamptz not null`
- `consumed bool not null default false`
- `consumed_at timestamptz`
- primary key: `(agent_id, device_id, created_at)` or a surrogate `id` + unique `(agent_id, device_id, consumed=false)`

### RLS policy intent

- **Insert/Update**: only owner can write
  - `auth.uid() = user_id`
- **Select (self)**: owner can read their own rows
- **Select (others)**: **NOT an open directory** (must be gated by SPOTS relationship policy)
  - Do **not** allow “any authenticated user can fetch any prekey bundle” in production.
  - Use a **Security Definer RPC** (or similarly controlled server boundary) to apply eligibility rules
    derived from SPOTS (see “SPOTS Tie‑In Layer”).

### Compatibility window

Keep existing `signal_prekey_bundles` temporarily, but migrate all clients to V2 and then retire V1.

---

## 🛡️ Threat Model + Security Goals (What “complete” means here)

This plan needs an explicit threat model so “done” is unambiguous.

### Security goals (must hold)

- **Message confidentiality**: server/transport never sees plaintext.
- **Forward secrecy**:
  - DMs: via Double Ratchet.
  - Community: via sender-key ratchet (extra credit) + epoch rotation.
- **Post-compromise safety**: recover over time after key compromise (DMs via ratchet; community via new epoch + fresh chain seeds).
- **Fail-closed**: if Signal isn’t ready, DM transport and sender-key share distribution must not silently downgrade.
- **Minimal metadata**:
  - Supabase still sees unavoidable routing + timing + table access.
  - Content/“doors”/list ids/etc. must live **inside ciphertext**, not in DB columns.

### Non-goals (explicitly)

- “Perfect metadata privacy” at the database layer is not achievable with Supabase tables alone.
  The focus is **content + key secrecy** and **eligibility minimization** (who can fetch keys / see streams).

---

## 🔐 Trust Establishment (Identity + Key Change Safety)

To tie messaging into real-world trust (and avoid silent MITM risks), we need:

- **Safety number / fingerprint UX** per relationship:
  - show “verify in person” for DMs and for community admin-to-member trust boundaries
  - store verification state locally (not server-visible)
- **Key change warnings**:
  - if a contact’s identity key changes, require user confirmation before continuing (or mark as “unverified”)
- **TOFU policy** (trust on first use) defined explicitly for:
  - first DM
  - first sender-key share received for a community

This is the “doors, not badges” version of trust: verification is a door you can open, not a forced ritual.

---

## 🧾 Key Server Hardening (Anti-enumeration + Rate Limits + Cleanup)

Beyond schema, we need operational protections:

### Anti-enumeration

- Do not allow raw “lookup by agent_id” without eligibility checks.
- Prefer an RPC like `get_prekey_bundle_for_contact_v1(...)` that:
  - validates eligibility (AI2AI entanglement threshold, shared community membership, invite token, etc.)
  - returns the minimum bundle needed
  - does not reveal whether a random agent_id exists when caller is ineligible

### Rate limits + abuse controls

- Per-user limits on:
  - prekey fetch attempts
  - failed decrypt/session attempts
  - DM send attempts (spam)
- Blocklist / report system hooks (can be minimal at first):
  - user-level block should prevent:
    - DM delivery
    - prekey fetch via eligibility
    - community key shares from that sender (optional)

### Cleanup / retention

- Cron cleanup for:
  - expired prekey bundles
  - consumed bundles past a retention window
- Explicit storage limits to avoid “unbounded table growth”

---

## 🧩 App Interfaces (Keep Group Working While Upgrading Signal)

### Split “encryption responsibilities” (avoid conflating concerns)

- **Transport / E2E encryption (Signal-only):**
  - DM transport
  - community sender-key shares
- **At-rest / local encryption (AES):**
  - local Sembast storage
  - community message ciphertext (sender key AES)

Concrete recommendation:

1) Introduce `SignalTransportService` (or equivalent) with APIs:
- `encryptToAgent(recipientAgentId, recipientDeviceId, bytes|string) -> ciphertext`
- `decryptFromAgent(senderAgentId, senderDeviceId, ciphertext) -> plaintext`
- `ensureReadyForUser(userId)` (initialize, publish prekeys, etc.)

2) Keep `CommunitySenderKeyService`’s public behavior unchanged:
- It still produces AES sender keys.
- It still stores locally in secure storage.
- It still writes `community_sender_key_shares` where `encryption_type == signalProtocol`.

3) Keep `CommunityChatService` message path unchanged:
- encrypt message with sender key AES
- insert blob + event
- receiver fetches blob by message id and decrypts using sender key AES

Signal upgrade should **not** change:
- `community_sender_key_state` semantics
- grace-window + silent refresh behavior
- RLS gating logic already deployed

---

## 🔗 SPOTS Tie-In Layer (Doors, Lists, Knots, Quantum) — What Was Missing

This plan intentionally focuses on **crypto + transport**, but to “tie it to the rest of SPOTS”
without polluting cryptography with product logic, we need a thin **domain/policy layer** above
Signal that aligns messaging with:

- **Doors philosophy** (meaningful connections)
- **Lists/Spots/Events** (core user workflows)
- **Knots + quantum entanglement** (how SPOTS decides who should connect)

### 1) “Who is allowed to message / fetch prekeys?” must be driven by SPOTS relationships

**Why:** A production Signal key server should not be an open directory. “Anyone authenticated can
read anyone’s prekeys” is simple but doesn’t match SPOTS’ privacy posture.

**Add a policy gate for `signal_prekey_bundles_v2` reads** that is derived from SPOTS’ existing
relationship primitives, e.g.:
- **AI2AI entanglement/connection** (compatibility/entanglement threshold)
- **Shared community membership** (members may exchange keys for sender-key distribution)
- **Explicit user intent** (invite/handshake token)

This is where **quantum entanglement** and **knot matching** belong: they decide *eligibility*,
not encryption.

### 2) “Doors inside messages” need a stable, encrypted message-envelope schema

Today chat message models have `metadata`, but there’s no canonical schema for linking chat to:
- spot discovery
- list making
- events
- “open this door” actions

Add a versioned, in-ciphertext envelope (so Supabase never sees it) such as:
- `kind: door_ref_v1` with `{spotId?, listId?, eventId?, communityId?, doorType}`
- `kind: action_intent_v1` with `{actionType, parameters}` (used by Action Execution UI)
- `kind: knot_context_v1` with `{knotClusterId?, vibeTags?}` (optional)

This ties messaging to the rest of the app without changing the crypto core.

### 3) Messaging must feed SPOTS learning (locally) without leaking content

To connect chat to “knots/quantum/list making” safely:
- Extract **local-only** features from decrypted messages (door type, sentiment category, topic tags),
  and feed them into learning systems (personality learning, knot fabric evolution, entanglement metrics).
- Store only minimal, privacy-safe telemetry (or none) server-side.

This creates the “SPOTS is the key → doors opened → learning improves” feedback loop without
turning Supabase into a content database.

---

## 🧬 Multi-Device (Required for “long term”)

### DM

Address messages to `(agentId, deviceId)`; for “user-level DM”, fan-out to all active devices.

### Community sender keys

To avoid “chat works on phone but not on tablet”:

- Either:
  - share the community AES sender key to **each device** (preferred)
  - or implement a per-user local key escrow (not recommended; adds complexity and risk)

Schema evolution (planned):
- Add `to_device_id int` to `community_sender_key_shares`
- Primary key becomes `(key_id, to_user_id, to_device_id)` (or agent-based)
- Maintain backward compatibility by treating `NULL` as `device_id = 1` during migration window.

---

## ⭐ Extra Credit: Signal-Style Sender-Key Ratchet for Community Chat (O(1) messages + stronger FS)

**Intent:** Keep the current scalable “single ciphertext per community message” design, but upgrade from
“one shared AES key per community epoch” to a **Signal Sender Keys–style ratchet** so compromise of a
current sender key doesn’t retroactively decrypt long histories (stronger forward secrecy properties).

### What changes (conceptually)

- **Before (current):**
  - One AES sender key per community epoch (`community_sender_key_state.key_id` maps to a 32-byte AES key)
  - Messages include `key_id` and AES-GCM ciphertext.

- **After (extra credit):**
  - The **community stream key_id becomes an epoch identifier**, not “the AES key itself”.
  - Each sender maintains a **per-sender chain key** per community epoch:
    - `chain_key_seed` (distributed once to each member via Signal)
    - `iteration` increments per message
    - per-message AES key is derived from chain key + iteration (HKDF / KDF)
  - Each message stays **O(1)**: one ciphertext blob, but with a tiny header `{epoch_key_id, sender_agent_id, iteration}`.

### Minimal data model (repo-aligned)

**Local (device):**
- Store sender-chain state keyed by:
  - `(community_id, epoch_key_id, sender_agent_id)` → `{chain_key_seed, next_iteration, cache}`

**Server (Supabase):**
- Reuse `community_sender_key_state.key_id` as **epoch id**.
- Extend `community_sender_key_shares` to support per-sender chains:
  - Add `from_device_id` / `to_device_id` (for multi-device)
  - Add `share_kind` (e.g. `epoch_sender_chain_seed_v1`)
  - Store encrypted payload (already `encrypted_key_base64`)

**Message blobs:**
- Keep ciphertext storage in `community_message_blobs`
- Add columns (or embed into ciphertext metadata if you prefer) for:
  - `sender_agent_id` (already present)
  - `key_id` (epoch id, already present)
  - `sender_chain_iteration int not null`
  - `sender_chain_id uuid/text` (optional; helps rotation/reset)

### Distribution flow (per epoch)

1. Admin rotates epoch (`community_sender_key_state.key_id`), using existing soft/hard rotation semantics.
2. Each sender device:
   - generates a fresh `chain_key_seed`
   - sends a **Signal-encrypted share** of that seed to every member device
3. Members cache sender chain seeds as they arrive (silent).

### Message send/decrypt flow

- **Send:** derive message key from `(chain_key_seed, iteration)`; encrypt payload; increment iteration.
- **Receive:** lookup sender’s chain seed for `(community_id, epoch_key_id, sender_agent_id)`, derive key for `iteration`, decrypt.
- **Out-of-order:** keep a small bounded cache of skipped message keys (Signal Sender Keys pattern).

### Missing-but-required details for “complete”

- **Out-of-order window size** (e.g., max skipped keys per sender per epoch) and eviction strategy.
- **Re-share / repair flow**:
  - if receiver misses chain seed, client triggers a “request seed” path (Signal-encrypted) rather than failing permanently.
- **Sender chain reset**:
  - define how a sender rotates their chain seed within an epoch (e.g., on suspicion/compromise) without forcing community-wide epoch rotation.

### Security & revocation notes

- **Hard rotation** remains the immediate revocation tool (no grace, no new seed shares to removed members).
- This upgrade improves content FS but does **not** remove DB-level metadata (community_id/timing).

---

## 🔄 Migration Strategy (No Regressions)

### Stage 0 — lock in contracts (tests + invariants)

Add tests that assert:
- DM transport fails closed (no AES transport)
- community sender-key shares are Signal-encrypted
- community message path remains AES sender-key (O(1) ciphertext) and decryptable
- silent rekey path still works (grace window + membership upsert)

### Stage 1 — Supabase schema fix (prekeys V2)

- Add `signal_prekey_bundles_v2`
- Add correct RLS (ownership by `user_id`)
- Add indexes for lookup by `(agent_id, device_id, consumed, expires_at)`

### Stage 2 — client publishing/lookup (dual-read, then cutover)

- Write prekeys to V2
- Read prekeys from V2 (fallback to V1 only during migration if needed)
- Once stable, remove V1 usage

### Stage 3 — packaging hardening

- iOS: embed XCFramework via plugin
- Android: ship all required `.so` per ABI via plugin/AAR

### Stage 4 — “group continuity” verification gates

Before any rollout:
- run DM + community E2E tests on:
  - iOS simulator ↔ iOS simulator
  - Android emulator ↔ Android emulator
  - iOS simulator ↔ Android emulator
- run community key rotation smoke:
  - message send/receive before rotation
  - rotate (soft) + message send/receive after rotation
  - ensure silent refresh

---

## ✅ Short Implementation Checklist (Tailored to This Repo)

### Key-server (Supabase) correctness (blocks DM + community shares)
- [ ] Add new migration: `supabase/migrations/0xx_signal_prekey_bundles_v2.sql`
  - Create `public.signal_prekey_bundles_v2(user_id, agent_id, device_id, bundle_json, …)`
  - RLS write: `auth.uid() = user_id`
  - Do **not** ship open-directory read; add RPC gating for “read-other”
- [ ] Update client prekey code:
  - `lib/core/crypto/signal/signal_key_manager.dart` write/read to V2
  - Stop relying on V1’s invalid `auth.uid()::text = agent_id`
  - Wire eligibility calls to the RPC boundary (not direct table reads) once implemented

### Native packaging (make Signal “for real” on iOS/Android)
- [ ] iOS: embed Signal native artifacts in the Runner build (via plugin/pod)
  - Ensure the library symbols are present for `DynamicLibrary.process()` paths
- [ ] Android: ship required native libs for all ABIs (plugin/AAR)
  - Current repo already includes `native/signal_ffi/android/*/libsignal_jni.so`
  - Ensure any required wrapper/bridge libs are also shipped if still used

### DM transport readiness
- [ ] Publish prekey bundle after auth (not just on cold-start with a restored session)
  - Wire into auth lifecycle (e.g., after successful sign-in)
  - Ensure `FriendChatService.sendMessageOverNetwork` stays Signal-only (fail closed)
 - [ ] Add identity verification + key-change warning UX (safety numbers)

### Community chat continuity (do not regress)
- [ ] Keep current community chat message path (AES sender key, O(1) ciphertext) unchanged.
- [ ] Keep existing deployed migrations for community stream gating + grace window.
- [ ] Extra credit (Sender Keys ratchet):
  - Add new share kind + per-sender chain seed distribution
  - Add `sender_chain_iteration` to message blobs (or equivalent metadata)
  - Keep RLS gating tied to epoch id + membership eligibility.
  - Define bounded out-of-order window + repair flow

---

## 🚦 Rollout Gates (Tailored to This Repo)

### Gate 1 — Supabase schema + RLS
- ✅ V2 prekey table exists and can be:
  - written by the owner (`user_id = auth.uid()`)
  - read by other authenticated users for session establishment
- ✅ No regression to community RLS (events/blobs/membership + grace window)

### Gate 2 — Packaging
- ✅ iOS build loads Signal successfully (no missing symbols at runtime)
- ✅ Android build loads Signal successfully for at least arm64-v8a + x86_64

### Gate 3 — Crypto E2E (device-matrix)
- ✅ DM E2E:
  - iOS↔iOS, Android↔Android, iOS↔Android
- ✅ Community E2E:
  - member receives events + can fetch blob + decrypt
  - soft rotation: member continues receiving during grace + silently refreshes + decrypts new epoch

### Gate 4 — Extra credit (Sender Keys ratchet)
- ✅ Mixed-version tolerance window (if needed): old clients still decrypt epoch messages until cutoff
- ✅ Out-of-order delivery handled (bounded skipped-key cache)

### Gate 5 — Abuse/ops readiness
- ✅ Rate limits in place for prekey fetch + DM send
- ✅ Monitoring for prekey exhaustion + repeated failures + message decrypt error spikes
- ✅ Cleanup jobs for expired/consumed bundles

## ✅ Definition of Done (Long-Term)

- **DMs**: reliable Signal E2E across all platform pairs
- **Community chat**:
  - AES sender-key message encryption remains the per-message scheme
  - Signal is used only for sender-key distribution/rotation (shares)
  - silent rekey works with zero user-visible disruption
- **Multi-device**: supported for DMs and community key distribution
- **Key server**: correct schema/RLS aligned with AgentIdService
- **Tests**: enforce regressions can’t slip in

---

## 🔗 References (Existing Implementation Artifacts)

- Agent IDs: `lib/core/services/agent_id_service.dart`
- Community sender keys: `lib/core/services/community_sender_key_service.dart`
- Community chat: `lib/core/services/community_chat_service.dart`
- DM transport: `lib/core/services/friend_chat_service.dart`
- Current (V1) prekey table: `supabase/migrations/022_signal_prekey_bundles.sql`
- Community sender key schema: `supabase/migrations/028_community_sender_keys_and_notifications.sql`
- Community stream gating: `supabase/migrations/029_community_stream_membership_gating.sql`
- Rotation + grace window: `supabase/migrations/032_community_sender_key_rotation_grace_window.sql`
- Blob RLS for stream design: `supabase/migrations/033_community_message_blobs_member_rls.sql`

