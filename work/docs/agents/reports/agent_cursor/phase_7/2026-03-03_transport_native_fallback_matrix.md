# Transport-native Lane Status and Fallback Matrix

## Scope
This matrix documents current lane behavior after the `transport-native` transport hardening pass. It is intended to replace implicit assumptions with explicit behavior/failure expectations for Android BLE, Android WiFi Direct, and WebRTC/WebSocket transport paths.

## Lane Summary

### 1) Android BLE peripheral + GATT (Primary)
- **Implementation status**: Implemented in `BLEForegroundService` + `MainActivity` method channel handlers.
- **Discovery source**: `AndroidDeviceDiscovery._scanBluetooth()` (BLE scan, service UUID + service data frame parsing).
- **Advertising source**: `PersonalityAdvertisingService._startAndroidAdvertising()` -> `BlePeripheral.startPeripheral()` -> native `ava/ble_peripheral`.
- **Expected behavior**:
  - If Bluetooth is unavailable/disabled, scan returns zero and logs clear reason.
  - If native channel methods are unavailable, advertising start returns `false` and remains recoverable.
  - Service-data frame updates are propagated through `BleForegroundService` flow.
- **Fallback mode**:
  - Use WebRTC/WebSocket lanes where configured.
  - Continue discovery loop and only suppress BLE-only side effects.

### 2) Android WiFi Direct (Secondary fallback lane)
- **Implementation status**: Android Kotlin channel now exists (`avra/wifi_direct`) and performs real peer discovery via `WifiP2pManager` when hardware support is present, with timeout-based completion.
- **Discovery source**: `AndroidDeviceDiscovery._scanWiFiDirect()` with `MethodChannel` probe to `avra/wifi_direct`.
- **Expected behavior**:
  - Method channel returns:
    - `status: ok` with discovered peers when WiFi Direct peers are returned.
    - `status: empty` when WiFi Direct is available but no matching peers appear.
    - `status: timeout`/`error`/`unsupported` for platform limitations or failures.
  - Discovery does not fail hard; logs reason and falls back immediately.
  - Returned peers are parsed only when peer list is explicitly present and `spots_enabled == true`.
- **Fallback mode**:
  - BLE becomes primary transport for same scan window.
  - No UI hard-stop; this is a deterministic fallback path.

### 3) WebRTC/WebSocket signaling lane (Web)
- **Implementation status**: Advertising lifecycle now attempts signaling registration/unregistration on web.
- **Advertising source**: `PersonalityAdvertisingService._startWebAdvertising()`.
- **Expected behavior**:
  - Sends registration payload to signaling URL (via `WebDeviceDiscovery.registerAdvertisingPeer`).
  - Registration stores a runtime peer id on success and emits explicit logs on failure.
  - Unregister is called during stop and will clear local peer tracking.
- **Fallback mode**:
  - If signaling URL is missing/unreachable, web advertising start/update returns `false` and does not block app bootstrap.
  - Discovery remains available for other lanes where platform supports them.

### 4) iOS BLE bridge compatibility
- **Implementation status**: Native channel handlers now defined for:
  - `avra/ble_peripheral`
  - `avra/ble_foreground`
  - `avra/ble_inbox`
- **Expected behavior**:
  - Calls do not throw `MissingPluginException`.
  - BLE peripheral/foreground actions return explicit `false`.
  - BLE inbox calls return `[]`/`true` to keep behavior recoverable.
- **Fallback mode**:
  - iOS currently degrades cleanly into non-native BLE transport paths.

## Test/Observation Notes
- `AndroidDeviceDiscovery._scanWiFiDirect` intentionally logs unsupported-state transitions to prevent silent blind spots.
- `ava/wi fi_direct` channel currently acts as a compatibility boundary rather than a full P2P transport implementation.
- Next pass should replace the WiFi Direct transport status placeholder with richer discovery payloads and transport metadata.

