# Phase 23 — Event Mode (Service Data broadcast + coherence + gated check-ins) — Execution Log

**Date:** 2026-01-02  
**Scope:** Phase 23 execution slice (Event Mode broadcast-first)  
**Status:** ✅ Implemented in repo; ⏳ pending real-device validation (BLE RF/OS variance)

---

## Summary (what changed)

This execution slice adds a **connectionless-first** “Event Mode” path that:
- broadcasts a deterministic **24-byte Frame v1** via **BLE Service Data** under the SPOTS service UUID
- parses that frame on the scanner path (no connects) and computes room coherence + dwell (two-stage)
- gates deep sync to rare **check-in windows** with deterministic initiator + budgets
- exposes a Settings toggle for `event_mode_enabled`

The math, thresholds, and frame contract are specified in:
- `docs/agents/reference/EVENT_MODE_POLICY.md`

---

## Key artifacts (source of truth)

### 23.1 Frame v1 encoder/decoder (single source of truth)
- `packages/spots_network/lib/network/spots_broadcast_frame_v1.dart`
- `packages/spots_network/test/spots_broadcast_frame_v1_test.dart`

### 23.2 Native Service Data advertising (Android + iOS)
- Dart bridge:
  - `packages/spots_network/lib/network/ble_peripheral.dart` (`updateServiceDataFrameV1`)
- Android:
  - `android/app/src/main/kotlin/com/spots/app/services/BLEForegroundService.kt`
  - `android/app/src/main/kotlin/com/spots/app/MainActivity.kt` (MethodChannel plumbing)
- iOS:
  - `ios/Runner/AppDelegate.swift` (Service Data advertising + update hook)

### 23.3 Advertiser emits frame + can update flags without re-anonymizing
- `packages/spots_network/lib/network/personality_advertising_service.dart`
  - emits Frame v1 on start/update
  - `updateServiceDataFrameV1Flags(...)` updates only flags (no re-anonymization)

### 23.4 Scanner parses Service Data frames (no connects)
- `packages/spots_network/lib/network/device_discovery_android.dart`
- `packages/spots_network/lib/network/device_discovery_ios.dart`

### 23.5 Room coherence + two-stage dwell
- `lib/core/ai2ai/room_coherence_engine.dart`
- `test/unit/ai2ai/room_coherence_engine_test.dart`

### 23.6 Orchestrator gating (armed check-ins + deterministic initiator + budgets)
- `lib/core/ai2ai/connection_orchestrator.dart`
  - Event Mode scan window handler (no hot-path connects except check-ins)
  - 5-minute epoch; 30s check-in window; deterministic initiator + tie-break
  - per-node cooldown + per-event cap
  - buffers learning-like insights during Event Mode (no event-time personality writes)

### 23.7 UI toggle
- `lib/presentation/pages/settings/discovery_settings_page.dart` (`event_mode_enabled`)

### 23.8 Bluetooth SIG CID runbook (future Manufacturer Data lane)
- `docs/agents/protocols/BLUETOOTH_SIG_COMPANY_ID_RUNBOOK.md`

---

## Real-device validation note (where this is tracked)

The canonical device checklist lives in:
- `docs/agents/status/status_tracker.md` → **Device validation checklist** → Phase 23 section

