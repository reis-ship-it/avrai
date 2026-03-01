# Bluetooth SIG Company Identifier (CID) Runbook

**Purpose:** Get an official Bluetooth SIG Company Identifier (CID) and prepare SPOTS to optionally use **Manufacturer Specific Data** in BLE advertisements in addition to the current **Service Data** approach.

---

## Why we want a CID

- **Manufacturer Specific Data** is a standard BLE advertising container that is keyed by a **Bluetooth SIG Company Identifier**.
- A CID gives SPOTS a recognizable “channel” for manufacturer data so scanners can filter fast and avoid ambiguous payloads.
- **Current shipped path** (recommended): **Service Data** under the SPOTS service UUID (no CID required).
- **Future upgrade**: advertise Frame v1 as both:
  - **Service Data** (always)
  - **Manufacturer Data** (when CID is available)

---

## Getting a Bluetooth SIG Company Identifier

Bluetooth SIG assigns CIDs. The process is business/account driven (not engineering-driven), but engineering can prepare everything so the CID drop-in is low-risk.

### Steps

- **Create/verify Bluetooth SIG organization account**
  - Ensure the legal entity name and contact email are correct.
- **Choose membership level / eligibility**
  - CID allocation is tied to SIG processes; confirm your org can request one under your membership.
- **Request a Company Identifier (CID)**
  - Submit the request via the SIG portal for your org.
- **Record and store the assigned CID**
  - Treat it as a public constant (not secret), but keep it documented and consistent across platforms.
- **Confirm encoding expectations**
  - Manufacturer Data payloads are associated with the CID, which is encoded/handled differently per platform API (see below).

### What engineering needs from ops/legal

- **The numeric CID** (e.g., `0x1234`) once assigned.
- Confirmation of **allowed brand naming** (“SPOTS”) in Bluetooth contexts.

---

## How we’ll use the CID in SPOTS (migration plan)

### 1) Keep Service Data as the primary container (already implemented)

- Service UUID: `0000FF00-0000-1000-8000-00805F9B34FB`
- Payload: **Frame v1 (24 bytes)** (“SPTS”, ver=1, flags, epoch, node_tag, dims_q)

### 2) Add Manufacturer Data as an additional container (future)

- Manufacturer payload should carry **the same Frame v1 bytes** (24 bytes), for identical cross-platform parsing.
- Scanners should prefer:
  1) Service Data frame v1 (UUID-keyed)
  2) Manufacturer Data frame v1 (CID-keyed)

### 3) Cross-platform API notes (important)

- **Android**
  - Advertising: `AdvertiseData.Builder().addManufacturerData(companyId, payloadBytes)`
  - Scanning: `ScanRecord.getManufacturerSpecificData(companyId)`
- **iOS**
  - Advertising: `CBAdvertisementDataManufacturerDataKey: Data(...)`
    - Apple expects the manufacturer data blob to include the company identifier bytes in the correct format for CoreBluetooth (verify endianness in a small on-device test).
  - Scanning: `CBAdvertisementDataManufacturerDataKey` returns raw `Data`

### 4) Versioning + compatibility

- Manufacturer data should embed the same **magic+ver** as Service Data (`"SPTS"`, `ver=1`).
- Receivers must:
  - ignore unknown versions
  - ignore invalid lengths
  - treat manufacturer data as **optional** (never required for correctness)

---

## Where to wire this in code (when CID is available)

### Android

- `android/app/src/main/kotlin/com/spots/app/services/BLEForegroundService.kt`
  - Add manufacturer data alongside service UUID/service data:
    - `.addManufacturerData(SPOTS_COMPANY_ID, frameV1Bytes)`

### iOS

- `ios/Runner/AppDelegate.swift`
  - Extend advertising dictionary to include manufacturer data:
    - `CBAdvertisementDataManufacturerDataKey: manufacturerBlob`

### Dart (shared)

- Keep **one** source of truth for Frame v1 bytes:
  - `packages/spots_network/lib/network/spots_broadcast_frame_v1.dart`
- Do **not** fork the frame format for manufacturer data; reuse Frame v1 as-is.

---

## Release checklist for CID enablement

- [ ] CID assigned and documented
- [ ] Android advertises manufacturer data with CID
- [ ] iOS advertises manufacturer data with CID (validated with a real device scan)
- [ ] Scanners prefer Service Data, fall back to Manufacturer Data
- [ ] No behavior change when CID is absent (Service Data continues to work)

