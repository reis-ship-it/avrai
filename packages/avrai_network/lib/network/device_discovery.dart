import 'dart:developer' as developer;
import 'dart:async';
import 'package:avrai_network/network/ble_personality_fetcher.dart';
import 'package:avrai_network/network/device_discovery_factory.dart';
import 'package:avrai_network/network/models/anonymized_vibe_data.dart';

/// Device Discovery Service for Phase 6: Physical Layer
/// Discovers nearby SPOTS-enabled devices using WiFi/Bluetooth
/// OUR_GUTS.md: "All device interactions must go through Personality AI Layer"
class DeviceDiscoveryService {
  static const String _logName = 'DeviceDiscoveryService';
  
  // Discovery state
  bool _isScanning = false;
  final Map<String, DiscoveredDevice> _discoveredDevices = {};
  final Map<String, DateTime> _deviceLastSeen = {};

  // Live scan configuration (can be updated while scanning).
  Duration _scanInterval = const Duration(seconds: 5);
  Duration _scanWindow = const Duration(seconds: 4);
  Duration _deviceTimeout = const Duration(minutes: 2);
  
  // Discovery callbacks
  final List<Function(List<DiscoveredDevice>)> _onDevicesDiscovered = [];
  
  // Platform-specific discovery implementations
  final DeviceDiscoveryPlatform? _platform;
  
  DeviceDiscoveryService({DeviceDiscoveryPlatform? platform}) 
      : _platform = platform ?? DeviceDiscoveryFactory.createPlatformDiscovery();
  
  /// Start continuous device discovery.
  ///
  /// If `scanInterval` is `Duration.zero`, scans will run back-to-back (continuous).
  Future<void> startDiscovery({
    Duration scanInterval = const Duration(seconds: 5),
    Duration scanWindow = const Duration(seconds: 4),
    Duration deviceTimeout = const Duration(minutes: 2),
  }) async {
    if (_isScanning) {
      developer.log('Discovery already running', name: _logName);
      return;
    }
    
    _isScanning = true;
    developer.log('Starting device discovery', name: _logName);

    // Initialize live config.
    _scanInterval = scanInterval;
    _scanWindow = scanWindow;
    _deviceTimeout = deviceTimeout;

    unawaited(_runScanLoop());
  }
  
  /// Stop device discovery
  void stopDiscovery() {
    if (!_isScanning) return;
    
    _isScanning = false;
    developer.log('Stopped device discovery', name: _logName);
  }

  /// Update the scan configuration while discovery is running.
  ///
  /// This is used by battery-adaptive scheduling to reduce BLE duty-cycle when
  /// power is low, without fully stopping discovery.
  void updateScanConfig({
    Duration? scanInterval,
    Duration? scanWindow,
    Duration? deviceTimeout,
  }) {
    if (scanInterval != null) _scanInterval = scanInterval;
    if (scanWindow != null) _scanWindow = scanWindow;
    if (deviceTimeout != null) _deviceTimeout = deviceTimeout;

    developer.log(
      'Updated scan config: interval=${_scanInterval.inMilliseconds}ms '
      'window=${_scanWindow.inMilliseconds}ms timeout=${_deviceTimeout.inSeconds}s',
      name: _logName,
    );
  }
  
  Future<void> _runScanLoop() async {
    // Sequential loop (never overlap scans).
    while (_isScanning) {
      // Read live config each iteration so adaptive scheduling can update it.
      final scanInterval = _scanInterval;
      final scanWindow = _scanWindow;
      final deviceTimeout = _deviceTimeout;

      final startedAt = DateTime.now();
      await _performScan(scanWindow: scanWindow);
      _cleanupStaleDevices(deviceTimeout);

      if (!_isScanning) return;

      // Continuous scan mode: ensure a minimum cadence of `scanWindow` to avoid
      // tight loops on stub/unsupported platforms that return instantly.
      if (scanInterval == Duration.zero) {
        final elapsed = DateTime.now().difference(startedAt);
        final remaining = scanWindow - elapsed;
        if (remaining > Duration.zero) {
          await Future<void>.delayed(remaining);
        }
        continue;
      }

      if (scanInterval > Duration.zero) {
        await Future<void>.delayed(scanInterval);
      }
    }
  }

  /// Perform a single discovery scan.
  Future<void> _performScan({required Duration scanWindow}) async {
    try {
      if (_platform == null) {
        developer.log('No platform discovery implementation available', name: _logName);
        return;
      }
      
      // Scan for devices
      final devices = await _platform.scanForDevices(scanWindow: scanWindow);
      
      // Filter for SPOTS-enabled devices
      final spotsDevices = devices.where((device) => 
        device.isSpotsEnabled
      ).toList();
      
      // Update discovered devices
      final now = DateTime.now();
      for (final device in spotsDevices) {
        _discoveredDevices[device.deviceId] = device;
        _deviceLastSeen[device.deviceId] = now;
      }
      
      // Notify listeners
      if (spotsDevices.isNotEmpty) {
        _notifyDevicesDiscovered(spotsDevices);
      }
      
      developer.log('Discovered ${spotsDevices.length} SPOTS devices', name: _logName);
    } catch (e) {
      developer.log('Error during device scan: $e', name: _logName);
    }
  }
  
  /// Clean up devices that haven't been seen recently
  void _cleanupStaleDevices(Duration timeout) {
    final now = DateTime.now();
    final staleDevices = <String>[];
    
    _deviceLastSeen.forEach((deviceId, lastSeen) {
      if (now.difference(lastSeen) > timeout) {
        staleDevices.add(deviceId);
      }
    });
    
    for (final deviceId in staleDevices) {
      _discoveredDevices.remove(deviceId);
      _deviceLastSeen.remove(deviceId);
    }
    
    if (staleDevices.isNotEmpty) {
      developer.log('Removed ${staleDevices.length} stale devices', name: _logName);
    }
  }
  
  /// Get currently discovered devices
  List<DiscoveredDevice> getDiscoveredDevices() {
    return _discoveredDevices.values.toList();
  }
  
  /// Get a specific device by ID
  DiscoveredDevice? getDevice(String deviceId) {
    return _discoveredDevices[deviceId];
  }
  
  /// Register callback for device discovery events
  void onDevicesDiscovered(Function(List<DiscoveredDevice>) callback) {
    _onDevicesDiscovered.add(callback);
  }
  
  /// Notify listeners of discovered devices
  void _notifyDevicesDiscovered(List<DiscoveredDevice> devices) {
    for (final callback in _onDevicesDiscovered) {
      try {
        callback(devices);
      } catch (e) {
        developer.log('Error in discovery callback: $e', name: _logName);
      }
    }
  }
  
  /// Extract personality data from a discovered device
  /// Returns anonymized personality data for AI2AI matching
  Future<AnonymizedVibeData?> extractPersonalityData(DiscoveredDevice device) async {
    try {
      if (!device.isSpotsEnabled) {
        return null;
      }
      
      // The personality data should already be anonymized
      // This method validates and returns it
      if (device.personalityData != null) {
        return device.personalityData;
      }

      // Option B: if not present in the scan payload, try a follow-up BLE GATT read.
      return await fetchPersonalityDataOverBle(device);
    } catch (e) {
      developer.log('Error extracting personality data: $e', name: _logName);
      return null;
    }
  }
  
  /// Calculate proximity score (0.0-1.0) based on signal strength
  double calculateProximity(DiscoveredDevice device) {
    if (device.signalStrength == null) return 0.5; // Unknown proximity
    
    // Normalize signal strength to 0.0-1.0
    // Stronger signal = closer proximity
    // Typical range: -100 dBm (weak) to -30 dBm (strong)
    final normalized = (device.signalStrength! + 100) / 70;
    return normalized.clamp(0.0, 1.0);
  }
}

/// Represents a discovered nearby device
class DiscoveredDevice {
  final String deviceId;
  final String deviceName;
  final DeviceType type;
  final bool isSpotsEnabled;
  final AnonymizedVibeData? personalityData;
  /// Opaque handle used for platform-specific follow-up (e.g. BLE GATT reads).
  ///
  /// This is intentionally untyped so `spots_network` can carry platform objects
  /// (like `BluetoothDevice`) without forcing all consumers to import them.
  final Object? platformHandle;
  final int? signalStrength; // Signal strength in dBm (negative value)
  final DateTime discoveredAt;
  final Map<String, dynamic> metadata;
  
  const DiscoveredDevice({
    required this.deviceId,
    required this.deviceName,
    required this.type,
    required this.isSpotsEnabled,
    this.personalityData,
    this.platformHandle,
    this.signalStrength,
    required this.discoveredAt,
    this.metadata = const {},
  });
  
  /// Check if device is still valid (not stale)
  bool isStale(Duration timeout) {
    return DateTime.now().difference(discoveredAt) > timeout;
  }
  
  /// Get proximity estimate based on signal strength
  double get proximityScore {
    if (signalStrength == null) return 0.5;
    final normalized = (signalStrength! + 100) / 70;
    return normalized.clamp(0.0, 1.0);
  }
}

/// Device discovery types
enum DeviceType {
  wifi,
  bluetooth,
  wifiDirect,
  multpeerConnectivity, // iOS Multipeer Connectivity
  webrtc, // Web platform
}

/// Platform-specific device discovery interface
/// Implementations should be provided for each platform
abstract class DeviceDiscoveryPlatform {
  /// Scan for nearby devices
  Future<List<DiscoveredDevice>> scanForDevices({
    Duration scanWindow = const Duration(seconds: 4),
  });
  
  /// Get platform-specific device info
  Future<Map<String, dynamic>> getDeviceInfo();
  
  /// Check if discovery is supported on this platform
  bool isSupported();
  
  /// Request necessary permissions
  Future<bool> requestPermissions();
}
