# BLE Background Usage Improvement Plan

**Created:** December 8, 2025, 2:30 PM CST  
**Status:** 📋 Implementation Plan  
**Purpose:** Enable continuous BLE scanning and advertising in the background with minimal battery drain

---

## 🎯 **Executive Summary**

Currently, BLE scanning and advertising only work when the app is in the foreground. This plan implements background BLE operations using foreground services (Android) and background modes (iOS), with adaptive scanning based on battery level and user usage patterns.

**Goal:** Enable 24/7 AI2AI connections with <0.5% daily battery drain through optimized BLE usage.

**Philosophy Alignment:** "Always Learning With You" - AI should learn continuously, even when the app is minimized.

---

## 🔋 **Current State**

### **What Works:**
- ✅ BLE scanning when app is open
- ✅ BLE advertising when app is open
- ✅ Service UUID filtering (`spotsServiceUuid`)
- ✅ Permissions configured (Android & iOS)

### **What's Missing:**
- ❌ Background BLE scanning
- ❌ Background BLE advertising
- ❌ Foreground service implementation (Android)
- ❌ Background modes configuration (iOS)
- ❌ Adaptive scanning based on battery level
- ❌ Adaptive scanning based on usage patterns
- ❌ Intermittent scanning patterns
- ❌ Battery-aware advertising intervals

---

## 🏗️ **Architecture Overview**

### **Two-Layer Approach:**

1. **Foreground Service (Android) / Background Modes (iOS)**
   - Enables BLE operations when app is minimized
   - Shows persistent notification
   - Keeps app process alive

2. **Adaptive BLE Service**
   - Adjusts scan/advertising frequency based on:
     - Battery level
     - Charging status
     - User usage patterns
     - Time of day
     - Movement detection

---

## 📱 **Platform-Specific Implementation**

### **Android: Foreground Service**

#### **1.1 Create Foreground Service**

**File:** `android/app/src/main/java/com/spots/app/services/BLEForegroundService.java`

**Features:**
- Long-running service for BLE operations
- Persistent notification
- BLE scanning in background
- BLE advertising in background
- Battery optimization handling

**Key Methods:**
```java
public class BLEForegroundService extends Service {
    private BluetoothAdapter bluetoothAdapter;
    private BluetoothLeScanner bluetoothLeScanner;
    private BluetoothLeAdvertiser bluetoothLeAdvertiser;
    
    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        // Start foreground service with notification
        // Initialize BLE scanning
        // Initialize BLE advertising
        return START_STICKY;
    }
    
    private void startBLEScanning() {
        // Scan with service UUID filter
        // Use ScanFilter for spotsServiceUuid
    }
    
    private void startBLEAdvertising() {
        // Advertise with personality data
        // Use spotsServiceUuid
    }
}
```

**Tasks:**
- [ ] Create `BLEForegroundService.java`
- [ ] Add service to `AndroidManifest.xml`
- [ ] Create notification channel
- [ ] Implement BLE scanning
- [ ] Implement BLE advertising
- [ ] Handle battery optimization

---

#### **1.2 Update AndroidManifest.xml**

**File:** `android/app/src/main/AndroidManifest.xml`

**Add Service Declaration:**
```xml
<service
    android:name=".services.BLEForegroundService"
    android:enabled="true"
    android:exported="false"
    android:foregroundServiceType="location|dataSync" />
```

**Tasks:**
- [ ] Add service declaration
- [ ] Configure foreground service types
- [ ] Add required permissions

---

#### **1.3 Create Method Channel Bridge**

**File:** `lib/core/network/ble_foreground_service.dart`

**Purpose:** Bridge between Dart and native Android service

**Key Methods:**
```dart
class BLEForegroundService {
  static const MethodChannel _channel = MethodChannel('spots/ble_foreground');
  
  /// Start foreground service and BLE operations
  static Future<bool> startService() async {
    try {
      final result = await _channel.invokeMethod('startService');
      return result as bool;
    } catch (e) {
      developer.log('Error starting BLE foreground service: $e');
      return false;
    }
  }
  
  /// Stop foreground service
  static Future<bool> stopService() async {
    try {
      final result = await _channel.invokeMethod('stopService');
      return result as bool;
    } catch (e) {
      developer.log('Error stopping BLE foreground service: $e');
      return false;
    }
  }
  
  /// Update scan interval based on battery/usage
  static Future<bool> updateScanInterval(int intervalMs) async {
    try {
      final result = await _channel.invokeMethod('updateScanInterval', {
        'intervalMs': intervalMs,
      });
      return result as bool;
    } catch (e) {
      return false;
    }
  }
}
```

**Tasks:**
- [ ] Create `BLEForegroundService` class
- [ ] Add method channel methods
- [ ] Add error handling
- [ ] Add unit tests

---

### **iOS: Background Modes**

#### **2.1 Update Info.plist**

**File:** `ios/Runner/Info.plist`

**Add Background Modes:**
```xml
<key>UIBackgroundModes</key>
<array>
    <string>bluetooth-central</string>
    <string>bluetooth-peripheral</string>
    <string>location</string>
</array>
```

**Add Bluetooth Usage Descriptions:**
```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>SPOTS uses Bluetooth for continuous ai2ai learning, enabling your AI to discover compatible personalities even when the app is in the background.</string>

<key>NSBluetoothPeripheralUsageDescription</key>
<string>SPOTS advertises your AI personality via Bluetooth so other devices can discover and learn from your preferences.</string>
```

**Tasks:**
- [ ] Add background modes
- [ ] Add usage descriptions
- [ ] Test background permissions

---

#### **2.2 Implement Background BLE (iOS)**

**File:** `ios/Runner/AppDelegate.swift`

**Add Background BLE Support:**
```swift
import CoreBluetooth

class AppDelegate: FlutterAppDelegate, CBCentralManagerDelegate, CBPeripheralManagerDelegate {
    var centralManager: CBCentralManager?
    var peripheralManager: CBPeripheralManager?
    
    override func application(_ application: UIApplication, 
                           didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Initialize BLE managers
        centralManager = CBCentralManager(delegate: self, queue: nil)
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    // Implement CBCentralManagerDelegate
    // Implement CBPeripheralManagerDelegate
}
```

**Tasks:**
- [ ] Add CoreBluetooth imports
- [ ] Initialize BLE managers
- [ ] Implement delegate methods
- [ ] Handle background state restoration

---

## 🔋 **Adaptive BLE Service**

### **3.1 Battery-Aware Service**

**File:** `lib/core/services/battery_aware_service.dart`

**Purpose:** Monitor battery level and adjust BLE operations

**Key Methods:**
```dart
class BatteryAwareService {
  final Battery battery = Battery();
  
  /// Get optimal scan interval based on battery level
  Future<Duration> getOptimalScanInterval() async {
    final batteryLevel = await battery.batteryLevel;
    final isCharging = await battery.isOnBatteryPower == false;
    
    if (isCharging) {
      // Aggressive scanning when charging
      return Duration(seconds: 2);
    }
    
    if (batteryLevel > 80) {
      return Duration(seconds: 5);
    } else if (batteryLevel > 50) {
      return Duration(seconds: 10);
    } else if (batteryLevel > 20) {
      return Duration(seconds: 20);
    } else {
      // Conservative scanning when battery low
      return Duration(seconds: 60);
    }
  }
  
  /// Get optimal advertising interval
  Future<Duration> getOptimalAdvertisingInterval() async {
    final batteryLevel = await battery.batteryLevel;
    final isCharging = await battery.isOnBatteryPower == false;
    
    if (isCharging) {
      return Duration(milliseconds: 100); // Fast advertising
    }
    
    if (batteryLevel > 50) {
      return Duration(milliseconds: 500); // Standard
    } else {
      return Duration(milliseconds: 1000); // Slow
    }
  }
}
```

**Tasks:**
- [ ] Add `battery_plus` dependency
- [ ] Create `BatteryAwareService` class
- [ ] Implement scan interval calculation
- [ ] Implement advertising interval calculation
- [ ] Add battery level monitoring
- [ ] Add unit tests

---

### **3.2 Usage Pattern Service**

**File:** `lib/core/services/adaptive_ai2ai_service.dart`

**Purpose:** Adjust BLE frequency based on user usage patterns

**Key Methods:**
```dart
class AdaptiveAI2AIService {
  final UsagePatternService usagePatternService;
  final BatteryAwareService batteryAwareService;
  
  /// Get optimal BLE frequency based on usage and battery
  Future<BLEFrequency> getOptimalFrequency() async {
    final usagePattern = await usagePatternService.getCurrentPattern();
    final batteryInterval = await batteryAwareService.getOptimalScanInterval();
    
    // Adjust based on user's active times
    final now = DateTime.now();
    final isActiveTime = usagePattern.receptivityByTime[now.hour] ?? 0.5;
    
    if (isActiveTime > 0.7) {
      // User is typically active - more frequent scanning
      return BLEFrequency(
        scanInterval: batteryInterval ~/ 2,
        advertisingInterval: Duration(milliseconds: 250),
      );
    } else if (isActiveTime < 0.3) {
      // User is typically inactive - less frequent scanning
      return BLEFrequency(
        scanInterval: batteryInterval * 2,
        advertisingInterval: Duration(milliseconds: 1000),
      );
    } else {
      // Normal frequency
      return BLEFrequency(
        scanInterval: batteryInterval,
        advertisingInterval: Duration(milliseconds: 500),
      );
    }
  }
}
```

**Tasks:**
- [ ] Create `AdaptiveAI2AIService` class
- [ ] Integrate with `UsagePattern` model
- [ ] Calculate optimal frequency
- [ ] Add time-of-day adjustments
- [ ] Add unit tests

---

### **3.3 Adaptive BLE Service**

**File:** `lib/core/network/adaptive_ble_service.dart`

**Purpose:** Integrate adaptive frequency with BLE operations

**Key Methods:**
```dart
class AdaptiveBLEService {
  final AdaptiveAI2AIService adaptiveService;
  final DeviceDiscoveryService discoveryService;
  final PersonalityAdvertisingService advertisingService;
  
  Timer? _scanTimer;
  Timer? _frequencyUpdateTimer;
  
  /// Start adaptive BLE discovery
  Future<void> startAdaptiveDiscovery() async {
    // Get initial frequency
    final frequency = await adaptiveService.getOptimalFrequency();
    
    // Start scanning with optimal interval
    await _startScanning(frequency.scanInterval);
    
    // Update frequency periodically (every 5 minutes)
    _frequencyUpdateTimer = Timer.periodic(
      Duration(minutes: 5),
      (_) async {
        final newFrequency = await adaptiveService.getOptimalFrequency();
        await _updateScanInterval(newFrequency.scanInterval);
      },
    );
  }
  
  /// Perform optimized BLE scan
  Future<void> _performOptimizedScan() async {
    // Use service UUID filter for hardware-level filtering
    final devices = await discoveryService.scanForDevices(
      serviceUuid: spotsServiceUuid,
      scanWindow: Duration(seconds: 1), // Short scan window
    );
    
    // Process discovered devices
    // ...
  }
}
```

**Tasks:**
- [ ] Create `AdaptiveBLEService` class
- [ ] Integrate adaptive frequency
- [ ] Implement optimized scanning
- [ ] Implement optimized advertising
- [ ] Add frequency updates
- [ ] Add unit tests

---

## ⚡ **Power Optimization Strategies**

### **4.1 Service UUID Filtering**

**Current:** Software-level filtering  
**Improved:** Hardware-level filtering

**Implementation:**
```dart
// Use ScanFilter for hardware-level filtering
final scanFilter = ScanFilter(
  serviceUuid: spotsServiceUuid,
);

await FlutterBluePlus.startScan(
  filters: [scanFilter],
  timeout: Duration(seconds: 1),
);
```

**Benefits:**
- Hardware filters scan results
- Reduces CPU usage
- Reduces battery drain
- Faster discovery

**Tasks:**
- [ ] Implement hardware-level filtering
- [ ] Test filtering effectiveness
- [ ] Measure power savings

---

### **4.2 Intermittent Scanning**

**Strategy:** Scan for 1 second, then sleep for 4 seconds

**Implementation:**
```dart
Future<void> _performIntermittentScan() async {
  // Scan for 1 second
  await FlutterBluePlus.startScan(
    timeout: Duration(seconds: 1),
  );
  
  // Sleep for 4 seconds
  await Future.delayed(Duration(seconds: 4));
  
  // Repeat
}
```

**Benefits:**
- 80% reduction in scan time
- Significant battery savings
- Still discovers devices quickly

**Tasks:**
- [ ] Implement intermittent scanning
- [ ] Test discovery effectiveness
- [ ] Measure power savings

---

### **4.3 Adaptive Advertising Intervals**

**Strategy:** Adjust advertising interval based on battery and activity

**Implementation:**
```dart
Future<void> _updateAdvertisingInterval() async {
  final frequency = await adaptiveService.getOptimalFrequency();
  
  // Update advertising interval
  await advertisingService.setAdvertisingInterval(
    frequency.advertisingInterval,
  );
}
```

**Benefits:**
- Lower battery drain when inactive
- Faster discovery when active
- Adaptive to user patterns

**Tasks:**
- [ ] Implement adaptive advertising
- [ ] Test discovery effectiveness
- [ ] Measure power savings

---

## 📊 **Expected Battery Impact**

### **Optimized BLE (Target: <0.5% daily drain)**

**Baseline (Continuous Scanning):**
- Scan: 100% duty cycle
- Advertising: 100% duty cycle
- Estimated drain: 2-3% per day

**Optimized (Intermittent + Adaptive):**
- Scan: 20% duty cycle (1s scan, 4s sleep)
- Advertising: Adaptive (250-1000ms intervals)
- Service UUID filtering: Hardware-level
- Estimated drain: 0.3-0.5% per day

**Factors:**
- Battery level adjustments
- Usage pattern adjustments
- Charging status
- Time of day

---

## 🧪 **Testing Strategy**

### **5.1 Unit Tests**

**Files:**
- `test/unit/services/battery_aware_service_test.dart`
- `test/unit/services/adaptive_ai2ai_service_test.dart`
- `test/unit/network/adaptive_ble_service_test.dart`

**Test Cases:**
- Battery level calculations
- Usage pattern adjustments
- Frequency calculations
- Adaptive interval updates

---

### **5.2 Integration Tests**

**File:** `test/integration/ble_background_integration_test.dart`

**Test Scenarios:**
1. Foreground service starts correctly
2. BLE scanning works in background
3. BLE advertising works in background
4. Adaptive frequency updates
5. Battery-aware adjustments
6. Usage pattern adjustments

---

### **5.3 Manual Testing**

**Test Cases:**
1. Start app, minimize, verify BLE continues
2. Check battery drain over 24 hours
3. Verify discovery still works
4. Test with different battery levels
5. Test with different usage patterns

---

## 📅 **Implementation Timeline**

### **Phase 1: Android Foreground Service** (3-4 days)
- Day 1: Create foreground service
- Day 2: Implement BLE scanning
- Day 3: Implement BLE advertising
- Day 4: Testing and debugging

### **Phase 2: iOS Background Modes** (2-3 days)
- Day 1: Update Info.plist
- Day 2: Implement background BLE
- Day 3: Testing and debugging

### **Phase 3: Adaptive BLE Service** (3-4 days)
- Day 1: Battery-aware service
- Day 2: Usage pattern service
- Day 3: Adaptive BLE service
- Day 4: Integration and testing

### **Phase 4: Power Optimization** (2-3 days)
- Day 1: Service UUID filtering
- Day 2: Intermittent scanning
- Day 3: Adaptive advertising

### **Phase 5: Testing & Validation** (2-3 days)
- Day 1: Unit tests
- Day 2: Integration tests
- Day 3: Battery drain validation

**Total Estimated Time:** 12-17 days

---

## ✅ **Success Criteria**

- [ ] BLE scanning works in background (Android & iOS)
- [ ] BLE advertising works in background (Android & iOS)
- [ ] Foreground service shows persistent notification
- [ ] Adaptive frequency based on battery level
- [ ] Adaptive frequency based on usage patterns
- [ ] Battery drain <0.5% per day
- [ ] Device discovery still effective
- [ ] All tests passing
- [ ] Documentation complete

---

## 🔗 **Related Documentation**

- **Offline AI2AI Plan:** `docs/plans/offline_ai2ai/OFFLINE_AI2AI_IMPLEMENTATION_PLAN.md`
- **Asymmetric Connections:** `docs/plans/ai2ai_system/ASYMMETRIC_CONNECTION_IMPROVEMENT.md`
- **Platform Plugins:** `docs/plans/general_docs/PLATFORM_PLUGINS_IMPLEMENTATION_COMPLETE.md`

---

**Last Updated:** December 8, 2025, 2:30 PM CST  
**Status:** Ready for Implementation

