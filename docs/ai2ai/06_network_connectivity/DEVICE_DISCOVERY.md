# Device Discovery System

**Created:** December 8, 2025, 5:25 PM CST  
**Purpose:** Documentation for device discovery system

---

## 🎯 **Overview**

The device discovery system discovers nearby SPOTS-enabled devices using WiFi/Bluetooth. All device interactions route through the Personality AI Layer.

**Key Principle:** All device connections route through Personality AI Layer, NOT direct peer-to-peer.

---

## 🏗️ **Architecture**

### **Device Discovery Service**

**Purpose:** Discovers nearby SPOTS-enabled devices

**Platform Support:**
- **Android:** BLE (Bluetooth Low Energy) + WiFi Direct
- **iOS:** Multipeer Connectivity + mDNS
- **Web:** WebRTC + WebSocket

**Code Reference:**
- `packages/spots_network/lib/network/device_discovery.dart` - Main discovery service (continuous loop + callbacks)
- `packages/spots_network/lib/network/device_discovery_android.dart` - Android implementation
- `packages/spots_network/lib/network/device_discovery_ios.dart` - iOS implementation
- `packages/spots_network/lib/network/device_discovery_web.dart` - Web implementation

---

## 🔄 **Discovery Flow**

1. **Start Discovery**
   - Service starts continuous scanning
   - Scans at regular intervals (default: 5 seconds)
   - Filters for SPOTS-enabled devices

2. **Device Detection**
   - Platform-specific discovery (BLE/WiFi)
   - Filter by SPOTS service UUID
   - Extract personality data from advertisements

3. **Personality AI Layer Processing**
   - Extract anonymized personality data
   - Calculate compatibility scores
   - Prioritize connections

4. **Connection Establishment**
   - Route through Personality AI Layer
   - Anonymize all data before transmission
   - Establish connection based on compatibility

---

## 📋 **Key Methods**

### **Start Discovery**

```dart
Future<void> startDiscovery({
  Duration scanInterval = const Duration(seconds: 5),
  Duration scanWindow = const Duration(seconds: 4),
  Duration deviceTimeout = const Duration(minutes: 2),
}) async
```

**Notes:**
- **Continuous scan mode:** pass `scanInterval: Duration.zero` (back-to-back scan windows).
- `scanWindow` controls how long each scan runs (better walk-by capture vs battery).

**Code Reference:**
```27:48:packages/spots_network/lib/network/device_discovery.dart
```

### **Stop Discovery**

```dart
void stopDiscovery()
```

**Code Reference:**
```50:56:packages/spots_network/lib/network/device_discovery.dart
```

---

## 🔗 **Related Documentation**

- **BLE Implementation:** [`BLE_IMPLEMENTATION.md`](./BLE_IMPLEMENTATION.md)
- **Protocols:** [`PROTOCOLS.md`](./PROTOCOLS.md)
- **Offline AI2AI:** [`OFFLINE_AI2AI_PLAN.md`](./OFFLINE_AI2AI_PLAN.md)
- **Architecture:** [`../02_architecture/ARCHITECTURE_LAYERS.md`](../02_architecture/ARCHITECTURE_LAYERS.md)

---

**Last Updated:** December 8, 2025, 5:25 PM CST  
**Status:** Device Discovery Documentation Complete

