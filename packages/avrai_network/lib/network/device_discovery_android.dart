import 'dart:developer' as developer;
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'package:avrai_network/network/device_discovery.dart';
import 'package:avrai_network/network/personality_data_codec.dart';
import 'package:avrai_network/network/models/anonymized_vibe_data.dart';
import 'package:avrai_network/network/avra_broadcast_frame_v1.dart';

/// Android-specific device discovery implementation
/// Uses WiFi Direct and Bluetooth Low Energy (BLE) for device discovery
class AndroidDeviceDiscovery extends DeviceDiscoveryPlatform {
  static const String _logName = 'AndroidDeviceDiscovery';
  
  bool _hasPermissions = false;
  
  @override
  bool isSupported() {
    return defaultTargetPlatform == TargetPlatform.android;
  }
  
  @override
  Future<bool> requestPermissions() async {
    try {
      developer.log('Requesting Android device discovery permissions', name: _logName);
      
      // Request location permission (required for BLE scanning on Android)
      final locationStatus = await Permission.location.request();
      
      // Request Bluetooth permission (Android 12+)
      final bluetoothStatus = await Permission.bluetoothScan.request();
      final bluetoothConnectStatus = await Permission.bluetoothConnect.request();
      
      // Request nearby devices permission (Android 12+)
      final nearbyDevicesStatus = await Permission.nearbyWifiDevices.request();
      
      _hasPermissions = locationStatus.isGranted && 
                      bluetoothStatus.isGranted && 
                      bluetoothConnectStatus.isGranted &&
                      nearbyDevicesStatus.isGranted;
      
      if (!_hasPermissions) {
        developer.log('Android permissions not granted', name: _logName);
        developer.log('Location: $locationStatus, Bluetooth: $bluetoothStatus, Nearby: $nearbyDevicesStatus', name: _logName);
      }
      
      return _hasPermissions;
    } catch (e) {
      developer.log('Error requesting Android permissions: $e', name: _logName);
      return false;
    }
  }
  
  @override
  Future<List<DiscoveredDevice>> scanForDevices({
    Duration scanWindow = const Duration(seconds: 4),
  }) async {
    if (!isSupported()) {
      developer.log('Android discovery not supported on this platform', name: _logName);
      return [];
    }
    
    if (!_hasPermissions) {
      final granted = await requestPermissions();
      if (!granted) {
        developer.log('Permissions not granted, cannot scan for devices', name: _logName);
        return [];
      }
    }
    
    try {
      developer.log('Scanning for devices on Android', name: _logName);
      
      final devices = <DiscoveredDevice>[];
      
      // Scan for Bluetooth Low Energy devices
      try {
        final bleDevices = await _scanBluetooth(scanWindow: scanWindow);
        devices.addAll(bleDevices);
        developer.log('Found ${bleDevices.length} BLE devices', name: _logName);
      } catch (e) {
        developer.log('Error scanning BLE: $e', name: _logName);
      }
      
      // Scan for WiFi Direct devices
      try {
        final wifiDevices = await _scanWiFiDirect();
        devices.addAll(wifiDevices);
        developer.log('Found ${wifiDevices.length} WiFi Direct devices', name: _logName);
      } catch (e) {
        developer.log('Error scanning WiFi Direct: $e', name: _logName);
      }
      
      developer.log('Total devices discovered: ${devices.length}', name: _logName);
      return devices;
    } catch (e) {
      developer.log('Error scanning for Android devices: $e', name: _logName);
      return [];
    }
  }
  
  @override
  Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      // TODO: Get Android device information
      // This could include:
      // - Device model
      // - Android version
      // - WiFi Direct capabilities
      // - Bluetooth capabilities
      // - MAC address (anonymized)
      
      return {
        'platform': 'android',
        'supported': isSupported(),
        'has_permissions': _hasPermissions,
        'note': 'Device info collection requires platform-specific implementation',
      };
    } catch (e) {
      developer.log('Error getting Android device info: $e', name: _logName);
      return {'platform': 'android', 'error': e.toString()};
    }
  }
  
  /// Scan for Bluetooth Low Energy devices
  Future<List<DiscoveredDevice>> _scanBluetooth({
    required Duration scanWindow,
  }) async {
    final devices = <DiscoveredDevice>[];
    
    try {
      // Check if Bluetooth is available
      if (!await FlutterBluePlus.isSupported) {
        developer.log('Bluetooth not supported on this device', name: _logName);
        return [];
      }
      
      // Check if Bluetooth is on
      if (await FlutterBluePlus.adapterState.first == BluetoothAdapterState.off) {
        developer.log('Bluetooth is off', name: _logName);
        return [];
      }
      
      final seenDeviceIds = <String>{};
      StreamSubscription<List<ScanResult>>? sub;
      try {
        // Start scanning and collect results for the full scan window.
        sub = FlutterBluePlus.scanResults.listen((results) {
          for (final scanResult in results) {
            final isSpotsDevice = _isSpotsDevice(scanResult);
            if (!isSpotsDevice) continue;

            final deviceId = scanResult.device.remoteId.str;
            if (!seenDeviceIds.add(deviceId)) continue;

            final personalityData =
                _extractPersonalityFromAdvertisement(scanResult);

            devices.add(DiscoveredDevice(
              deviceId: deviceId,
              deviceName: scanResult.device.platformName.isNotEmpty
                  ? scanResult.device.platformName
                  : 'SPOTS Device',
              type: DeviceType.bluetooth,
              isSpotsEnabled: true,
              personalityData: personalityData,
              platformHandle: scanResult.device,
              signalStrength: scanResult.rssi,
              discoveredAt: DateTime.now(),
              metadata: {
                'advertisement_data': scanResult.advertisementData.toString(),
                'manufacturer_data':
                    scanResult.advertisementData.manufacturerData.toString(),
                'service_data': scanResult.advertisementData.serviceData.toString(),
                if (_extractFrameV1FromServiceData(scanResult) != null)
                  'spots_frame_v1': () {
                    final frame = _extractFrameV1FromServiceData(scanResult)!;
                    return <String, Object?>{
                      'ver': SpotsBroadcastFrameV1.version,
                      'flags': frame.flags,
                      'epoch': frame.epoch,
                      'node_tag': frame.nodeTag.toList(),
                      'dims_q': frame.dimsQ.toList(),
                      'event_mode_enabled': frame.eventModeEnabled,
                      'connect_ok': frame.connectOk,
                      'brownout': frame.brownout,
                    };
                  }(),
              },
            ));
          }
        });

        await FlutterBluePlus.startScan(
          timeout: scanWindow,
          androidUsesFineLocation: false,
        );

        // Ensure we don't return early on a quick first event; give the scan
        // window time to capture walk-bys.
        await Future<void>.delayed(scanWindow);
      } finally {
        try {
          await sub?.cancel();
        } catch (_) {}
        try {
          await FlutterBluePlus.stopScan();
        } catch (_) {}
      }
      
    } catch (e) {
      developer.log('Error in BLE scan: $e', name: _logName);
      // Ensure scanning stops even on error
      try {
        await FlutterBluePlus.stopScan();
      } catch (_) {}
    }
    
    return devices;
  }
  
  /// Scan for WiFi Direct devices
  Future<List<DiscoveredDevice>> _scanWiFiDirect() async {
    final devices = <DiscoveredDevice>[];
    
    try {
      // Check if WiFi is enabled
      if (!await WiFiForIoTPlugin.isEnabled()) {
        developer.log('WiFi is not enabled', name: _logName);
        return [];
      }
      
      // Note: wifi_iot plugin has limited WiFi Direct support
      // For full WiFi Direct discovery, you may need platform channels
      // This implementation uses available WiFi scanning as a fallback
      
      // Get current WiFi network info (as a proxy for WiFi Direct capability)
      final currentSSID = await WiFiForIoTPlugin.getSSID();
      final currentBSSID = await WiFiForIoTPlugin.getBSSID();
      
      if (currentSSID != null && currentBSSID != null) {
        developer.log('Current WiFi network: $currentSSID', name: _logName);
        
        // In a real implementation, you would:
        // 1. Use WiFi Direct API to discover peers
        // 2. Filter for SPOTS-enabled devices
        // 3. Extract personality data from discovered peers
        
        // For now, this is a placeholder that shows the structure
        // Full WiFi Direct requires native Android code via platform channels
      }
      
    } catch (e) {
      developer.log('Error in WiFi Direct scan: $e', name: _logName);
    }
    
    return devices;
  }
  
  /// Check if a BLE device is a SPOTS device
  bool _isSpotsDevice(ScanResult scanResult) {
    // SPOTS devices should advertise a specific service UUID
    // Example: '0000ff00-0000-1000-8000-00805f9b34fb' (custom UUID)
    const spotsServiceUuid = '0000ff00-0000-1000-8000-00805f9b34fb';
    
    // Check service UUIDs in advertisement
    final serviceUuids = scanResult.advertisementData.serviceUuids;
    if (serviceUuids.any((g) => _normalizeUuid(g.toString()) == spotsServiceUuid)) {
      return true;
    }
    
    // Check manufacturer data for SPOTS identifier
    final manufacturerData = scanResult.advertisementData.manufacturerData;
    if (manufacturerData.isNotEmpty) {
      final dataBytes = manufacturerData.values.first;
      if (PersonalityDataCodec.isSpotsPersonalityData(dataBytes)) {
        return true;
      }
    }
    
    // Check device name for SPOTS identifier
    if (scanResult.device.platformName.toLowerCase().contains('spots')) {
      return true;
    }
    
    return false;
  }

  SpotsBroadcastFrameV1Decoded? _extractFrameV1FromServiceData(
    ScanResult scanResult,
  ) {
    const spotsServiceUuid = '0000ff00-0000-1000-8000-00805f9b34fb';
    final serviceData = scanResult.advertisementData.serviceData;
    if (serviceData.isEmpty) return null;

    for (final entry in serviceData.entries) {
      final uuid = _normalizeUuid(entry.key.toString());
      if (uuid != spotsServiceUuid) continue;
      final bytes = Uint8List.fromList(entry.value);
      return SpotsBroadcastFrameV1.decode(bytes);
    }
    return null;
  }

  String _normalizeUuid(String raw) {
    return raw
        .toLowerCase()
        .replaceAll('{', '')
        .replaceAll('}', '')
        .trim();
  }
  
  /// Extract personality data from BLE advertisement
  AnonymizedVibeData? _extractPersonalityFromAdvertisement(ScanResult scanResult) {
    try {
      // Extract personality data from advertisement manufacturer data
      final manufacturerData = scanResult.advertisementData.manufacturerData;
      
      if (manufacturerData.isEmpty) {
        return null;
      }
      
      // Get manufacturer data bytes
      final dataBytes = manufacturerData.values.first;
      
      // Check if it's SPOTS personality data
      if (!PersonalityDataCodec.isSpotsPersonalityData(dataBytes)) {
        developer.log('Manufacturer data does not contain SPOTS personality data', name: _logName);
        return null;
      }
      
      // Decode binary personality data
      final personalityData = PersonalityDataCodec.decodeFromBinary(dataBytes);
      
      if (personalityData == null) {
        developer.log('Failed to decode personality data from manufacturer data', name: _logName);
        return null;
      }
      
      // Validate data hasn't expired
      if (personalityData.isExpired) {
        developer.log('Personality data has expired', name: _logName);
        return null;
      }
      
      developer.log('Successfully extracted personality data from BLE advertisement', name: _logName);
      return personalityData;
      
    } catch (e) {
      developer.log('Error extracting personality data: $e', name: _logName);
      return null;
    }
  }
}
