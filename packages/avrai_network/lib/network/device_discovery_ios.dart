import 'dart:developer' as developer;
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_nsd/flutter_nsd.dart';
import 'package:avrai_network/network/device_discovery.dart';
import 'package:avrai_network/network/personality_data_codec.dart';
import 'package:avrai_network/network/models/anonymized_vibe_data.dart';
import 'package:avrai_network/network/avra_broadcast_frame_v1.dart';

/// iOS-specific device discovery implementation
/// Uses Multipeer Connectivity framework and Bluetooth for device discovery
class IOSDeviceDiscovery extends DeviceDiscoveryPlatform {
  static const String _logName = 'IOSDeviceDiscovery';
  
  bool _hasPermissions = false;
  
  @override
  bool isSupported() {
    return defaultTargetPlatform == TargetPlatform.iOS;
  }
  
  @override
  Future<bool> requestPermissions() async {
    try {
      developer.log('Requesting iOS device discovery permissions', name: _logName);
      
      // iOS Multipeer Connectivity doesn't require explicit permissions
      // but Bluetooth usage requires permission in Info.plist
      // The permission is requested automatically when using Multipeer Connectivity
      
      // For Bluetooth, we check if it's available
      // Note: iOS doesn't expose Bluetooth permission API like Android
      // Permissions are handled via Info.plist entries:
      // - NSBluetoothAlwaysUsageDescription
      // - NSBluetoothPeripheralUsageDescription
      
      _hasPermissions = true; // Multipeer Connectivity handles permissions internally
      
      developer.log('iOS permissions configured via Info.plist', name: _logName);
      return _hasPermissions;
    } catch (e) {
      developer.log('Error requesting iOS permissions: $e', name: _logName);
      return false;
    }
  }
  
  @override
  Future<List<DiscoveredDevice>> scanForDevices({
    Duration scanWindow = const Duration(seconds: 4),
  }) async {
    if (!isSupported()) {
      developer.log('iOS discovery not supported on this platform', name: _logName);
      return [];
    }
    
    try {
      developer.log('Scanning for devices on iOS', name: _logName);
      
      final devices = <DiscoveredDevice>[];
      
      // Scan using Network Service Discovery (mDNS/Bonjour)
      try {
        final nsdDevices = await _scanNetworkServiceDiscovery(
          scanWindow: scanWindow,
        );
        devices.addAll(nsdDevices);
        developer.log('Found ${nsdDevices.length} NSD devices', name: _logName);
      } catch (e) {
        developer.log('Error scanning NSD: $e', name: _logName);
      }
      
      // Scan for Bluetooth devices (limited on iOS)
      try {
        final bleDevices = await _scanBluetooth(scanWindow: scanWindow);
        devices.addAll(bleDevices);
        developer.log('Found ${bleDevices.length} BLE devices', name: _logName);
      } catch (e) {
        developer.log('Error scanning BLE: $e', name: _logName);
      }
      
      developer.log('Total devices discovered: ${devices.length}', name: _logName);
      return devices;
    } catch (e) {
      developer.log('Error scanning for iOS devices: $e', name: _logName);
      return [];
    }
  }
  
  @override
  Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      // TODO: Get iOS device information
      // This could include:
      // - Device model
      // - iOS version
      // - Multipeer Connectivity capabilities
      // - Bluetooth capabilities
      // - Device identifier (anonymized)
      
      return {
        'platform': 'ios',
        'supported': isSupported(),
        'has_permissions': _hasPermissions,
        'note': 'Device info collection requires platform-specific implementation',
      };
    } catch (e) {
      developer.log('Error getting iOS device info: $e', name: _logName);
      return {'platform': 'ios', 'error': e.toString()};
    }
  }
  
  /// Scan using Network Service Discovery (mDNS/Bonjour)
  /// This provides Multipeer Connectivity-like functionality
  Future<List<DiscoveredDevice>> _scanNetworkServiceDiscovery({
    required Duration scanWindow,
  }) async {
    final devices = <DiscoveredDevice>[];
    
    try {
      // SPOTS service type (e.g., "_spots._tcp")
      const serviceType = '_spots._tcp';
      const domain = 'local.';
      
      // Discover services on the local network
      final nsd = FlutterNsd();
      
      // Start discovery - FlutterNsd API uses stream-based discovery
      // Listen for discovered services
      final subscription = nsd.stream.listen((serviceInfo) {
        try {
          // Check if service is SPOTS-enabled
          if (_isSpotsService(serviceInfo)) {
            // Extract personality data from service TXT record
            final personalityData = _extractPersonalityFromService(serviceInfo);
            
            devices.add(DiscoveredDevice(
              deviceId: serviceInfo.name ?? 'unknown',
              deviceName: serviceInfo.name ?? 'SPOTS Device',
              type: DeviceType.multpeerConnectivity,
              isSpotsEnabled: true,
              personalityData: personalityData,
              discoveredAt: DateTime.now(),
              metadata: {
                'service_type': serviceType,
                'domain': domain,
              },
            ));
          }
        } catch (e) {
          developer.log('Error processing NSD service: $e', name: _logName);
        }
      });
      
      // Start discovery with service type
      await nsd.discoverServices(serviceType);
      
      // Wait for discovery timeout
      await Future.delayed(scanWindow);
      
      // Cancel subscription and stop discovery
      await subscription.cancel();
      await nsd.stopDiscovery();
      
    } catch (e) {
      developer.log('Error in NSD scan: $e', name: _logName);
    }
    
    return devices;
  }
  
  /// Scan for Bluetooth devices (limited on iOS)
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
      
      // Note: iOS has restrictions on Bluetooth scanning
      // - Can only scan for connected devices
      // - Background scanning requires specific entitlements
      // - May need to use Core Bluetooth directly for full functionality
      
      // Start scanning (iOS will handle permissions automatically)
      final seenDeviceIds = <String>{};
      StreamSubscription<List<ScanResult>>? sub;
      try {
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

        await FlutterBluePlus.startScan(timeout: scanWindow);
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
      try {
        await FlutterBluePlus.stopScan();
      } catch (_) {}
    }
    
    return devices;
  }
  
  /// Check if a network service is a SPOTS service
  bool _isSpotsService(NsdServiceInfo service) {
    // Check service name (nullable)
    final serviceName = service.name?.toLowerCase() ?? '';
    if (serviceName.contains('spots')) {
      return true;
    }
    
    // Note: NsdServiceInfo may require service resolution to access TXT record
    // For now, we'll rely on service name matching
    // TXT record access would require resolving the service first
    
    return false;
  }
  
  /// Extract personality data from network service TXT record
  AnonymizedVibeData? _extractPersonalityFromService(NsdServiceInfo service) {
    try {
      // Note: NsdServiceInfo requires service resolution to access TXT record
      // The flutter_nsd package may need resolveService() call first
      // For now, return null - TXT record extraction requires service resolution
      // TODO: Implement service resolution to access TXT records
      developer.log('TXT record extraction requires service resolution - not implemented yet', name: _logName);
      return null;
    } catch (e) {
      developer.log('Error extracting personality from service: $e', name: _logName);
      return null;
    }
  }
  
  /// Check if a BLE device is a SPOTS device
  bool _isSpotsDevice(ScanResult scanResult) {
    const spotsServiceUuid = '0000ff00-0000-1000-8000-00805f9b34fb';
    
    final serviceUuids = scanResult.advertisementData.serviceUuids;
    if (serviceUuids.any((g) => _normalizeUuid(g.toString()) == spotsServiceUuid)) {
      return true;
    }
    
    // Check manufacturer data for SPOTS magic bytes
    final manufacturerData = scanResult.advertisementData.manufacturerData;
    if (manufacturerData.isNotEmpty) {
      final dataBytes = manufacturerData.values.first;
      if (PersonalityDataCodec.isSpotsPersonalityData(dataBytes)) {
        return true;
      }
    }
    
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
      final manufacturerData = scanResult.advertisementData.manufacturerData;
      if (manufacturerData.isEmpty) {
        return null;
      }
      
      // Get manufacturer data bytes
      final dataBytes = manufacturerData.values.first;
      
      // Check if it's SPOTS personality data
      if (!PersonalityDataCodec.isSpotsPersonalityData(dataBytes)) {
        return null;
      }
      
      // Decode binary personality data
      final personalityData = PersonalityDataCodec.decodeFromBinary(dataBytes);
      
      if (personalityData == null) {
        return null;
      }
      
      // Validate data hasn't expired
      if (personalityData.isExpired) {
        developer.log('Personality data has expired', name: _logName);
        return null;
      }
      
      return personalityData;
    } catch (e) {
      developer.log('Error extracting personality data: $e', name: _logName);
      return null;
    }
  }
}
