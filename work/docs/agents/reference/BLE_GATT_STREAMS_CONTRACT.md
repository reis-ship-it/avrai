# BLE GATT Streams Contract (SPOTS)

**Purpose:** Define the on-wire contract for **SPOTS BLE GATT “streams”** used for offline AI2AI discovery and offline Signal bootstrap.

**Owner:** Phase 14 (Signal) + AI2AI system (BLE background/discovery)

---

## What this is (simple)

- Devices broadcast a BLE service.
- Other devices can **read** “stream payloads” from that service.
- We currently use:
  - **Stream 0**: anonymized vibe payload (discovery)
  - **Stream 1**: Signal prekey payload (offline bootstrap)

This doc defines the rules so sender/receiver don’t drift.

---

## Stream IDs

- **0**: Anonymized vibe payload (discovery)
  - **Decoder**: `PersonalityDataCodec.decodeFromJson(...)`
  - **Code path**: `packages/spots_network/lib/network/ble_personality_fetcher_impl_io.dart`
- **1**: Signal prekey payload (offline bootstrap)
  - **Published by**: `VibeConnectionOrchestrator._publishSignalPreKeyPayloadIfAvailable()`
  - **Consumed by**: `VibeConnectionOrchestrator._primeOfflineSignalPreKeyBundle(...)`

---

## Transport framing (read/write protocol)

### Read (“stream fetch”)

The reader requests chunks by writing a **control frame** (magic `SPTS`) and then reading a characteristic which returns:

- a fixed **header** (currently 16 bytes)
- followed by the requested chunk bytes

See implementation:
- `packages/spots_network/lib/network/ble_gatt_stream_fetcher_impl_io.dart`

### Control frame (write)

- Magic bytes: `SPTS`
- Version: `1`
- Stream ID: `uint8`
- Offset: `uint32 little-endian`

### Read header (response)

- Magic bytes: `SPTS`
- Version: `1`
- Stream ID: `uint8`
- Total length: `uint32 little-endian`
- Offset: `uint32 little-endian`
- Chunk length: `uint16 little-endian`

**Important:** total length must stay stable across chunk reads; receiver aborts on mismatch.

---

## Payload encoding (streams 0 and 1)

Unless stated otherwise, stream payloads are:

- **UTF-8 encoded JSON**
- Treated as **untrusted input** (never trust lengths, types, or missing keys)
- Allowed to add **new keys** without breaking older readers

---

## Stream 0 payload (anonymized vibe)

### Encoding

- UTF-8 JSON string
- Decoded using `PersonalityDataCodec.decodeFromJson(jsonString)`

### Constraints

- Must not contain PII
- Must remain small (BLE read payload target: **a few KB**)

---

## Stream 1 payload (Signal prekey payload)

### JSON shape (v1)

```json
{
  "version": 1,
  "created_at": "2026-01-01T00:00:00.000Z",
  "node_id": "uuid-or-stable-node-id",
  "prekey_bundle": { "..." : "SignalPreKeyBundle JSON" }
}
```

### Field semantics

- **`version`**: integer schema version (currently `1`)
- **`created_at`**: UTC ISO-8601 timestamp string
- **`node_id`**:
  - stable per-run node identifier used for offline addressing (preferred over BLE device UUIDs)
  - receiver may fall back to `device.deviceId` if missing
- **`prekey_bundle`**:
  - JSON representation of `SignalPreKeyBundle`
  - Must be compatible with `SignalPreKeyBundle.fromJson(...)`

### Privacy rules

- No userId, email, phone, location, etc.
- Should not leak anything that identifies a human.
- This is public “handshake material”, not encrypted content.

---

## Backwards/forwards compatibility rules

- **Readers must ignore unknown keys.**
- **Writers must keep existing keys stable.**
- If breaking changes are needed:
  - bump `version`
  - keep supporting old `version` until deprecation is complete

---

## Test-mode safety

BLE reads/writes and inbox polling may not be available under `flutter test`.

Rule of thumb:
- unit/widget tests should avoid real BLE I/O and timers by default
- on-device integration tests can enable BLE behavior explicitly

