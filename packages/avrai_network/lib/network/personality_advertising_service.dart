import 'dart:developer' as developer;
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:avrai_network/network/personality_data_codec.dart';
import 'package:avrai_network/network/models/anonymized_vibe_data.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:avrai_network/network/ble_peripheral.dart';
import 'package:avrai_network/network/avra_broadcast_frame_v1.dart';

/// Personality Advertising Service
/// Advertises anonymized personality data so other devices can discover this device
/// OUR_GUTS.md: "All device interactions must go through Personality AI Layer"
class PersonalityAdvertisingService {
  static const String _logName = 'PersonalityAdvertisingService';
  
  // SPOTS service UUID for BLE advertisements
  static const String spotsServiceUuid = '0000ff00-0000-1000-8000-00805f9b34fb';
  
  // Advertising state
  bool _isAdvertising = false;
  AnonymizedVibeData? _currentPersonalityData;
  Timer? _refreshTimer;

  // Broadcast frame v1 config (cached so refresh timer preserves flags).
  String? _frameNodeId;
  bool _frameEventModeEnabled = false;
  bool _frameConnectOk = false;
  bool _frameBrownout = false;
  
  // Platform-specific advertising implementations
  // Use dynamic to avoid importing platform-specific classes (which would pull in web code)
  final dynamic _androidDiscovery;
  final dynamic _iosDiscovery;
  final dynamic _webDiscovery;
  
  // BLE advertising (Android/iOS) is handled via `BlePeripheral` (platform channels).
  
  PersonalityAdvertisingService({
    dynamic androidDiscovery,
    dynamic iosDiscovery,
    dynamic webDiscovery,
  }) : _androidDiscovery = androidDiscovery,
       _iosDiscovery = iosDiscovery,
       _webDiscovery = webDiscovery;
  
  /// Start advertising personality data
  /// This makes the device discoverable by other SPOTS devices
  ///
  /// The `personalityData` must already be anonymized by the app/AI layer.
  ///
  /// If `refresh` is provided, this service will periodically refresh the payload
  /// (e.g., every 5 minutes) without needing to understand personality internals.
  Future<bool> startAdvertising({
    required AnonymizedVibeData personalityData,
    String? nodeId,
    bool eventModeEnabled = false,
    bool connectOk = false,
    bool brownout = false,
    Future<AnonymizedVibeData> Function()? refresh,
    Duration refreshInterval = const Duration(minutes: 5),
  }) async {
    if (_isAdvertising) {
      // #region agent log
      developer.log('Already advertising personality data', name: _logName);
      // #endregion
      return true;
    }
    
    try {
      // #region agent log
      developer.log(
        'Starting personality advertising (payload only)',
        name: _logName,
      );
      // #endregion
      
      _currentPersonalityData = personalityData;
      _frameNodeId = nodeId;
      _frameEventModeEnabled = eventModeEnabled;
      _frameConnectOk = connectOk;
      _frameBrownout = brownout;
      
      // #region agent log
      developer.log(
        'Advertising payload set: expiresAt=${personalityData.expiresAt}',
        name: _logName,
      );
      // #endregion
      
      // Start platform-specific advertising
      // #region agent log
      developer.log('Starting platform-specific advertising: kIsWeb=$kIsWeb, platform=${defaultTargetPlatform.name}', name: _logName);
      // #endregion
      
      bool success = false;
      
      if (kIsWeb) {
        success = await _startWebAdvertising(personalityData);
      } else {
        switch (defaultTargetPlatform) {
          case TargetPlatform.android:
            success = await _startAndroidAdvertising(personalityData);
            break;
          case TargetPlatform.iOS:
            success = await _startIOSAdvertising(personalityData);
            break;
          default:
            // #region agent log
            developer.log('Platform not supported for advertising: ${defaultTargetPlatform.name}', name: _logName);
            // #endregion
            return false;
        }
      }
      
      if (success) {
        _isAdvertising = true;
        
        // Set up automatic refresh (optional).
        _startRefreshTimer(
          refresh: refresh,
          refreshInterval: refreshInterval,
        );

        // Best-effort: publish the 24-byte service-data frame for connectionless sensing.
        unawaited(_publishServiceDataFrameV1(
          personalityData: personalityData,
          nodeId: nodeId,
          eventModeEnabled: eventModeEnabled,
          connectOk: connectOk,
          brownout: brownout,
        ));
        
        // #region agent log
        developer.log('Personality advertising started successfully: isAdvertising=$_isAdvertising', name: _logName);
        // #endregion
        return true;
      } else {
        // #region agent log
        developer.log('Failed to start personality advertising', name: _logName);
        // #endregion
        return false;
      }
    } catch (e) {
      // #region agent log
      developer.log('Error starting personality advertising: $e', name: _logName);
      // #endregion
      return false;
    }
  }
  
  /// Stop advertising personality data
  Future<void> stopAdvertising() async {
    if (!_isAdvertising) {
      // #region agent log
      developer.log('Not currently advertising, nothing to stop', name: _logName);
      // #endregion
      return;
    }
    
    try {
      // #region agent log
      developer.log('Stopping personality advertising', name: _logName);
      // #endregion
      
      _refreshTimer?.cancel();
      _refreshTimer = null;
      
      // Stop platform-specific advertising
      // #region agent log
      developer.log('Stopping platform-specific advertising: kIsWeb=$kIsWeb, platform=${defaultTargetPlatform.name}', name: _logName);
      // #endregion
      
      if (kIsWeb) {
        await _stopWebAdvertising();
      } else {
        switch (defaultTargetPlatform) {
          case TargetPlatform.android:
            await _stopAndroidAdvertising();
            break;
          case TargetPlatform.iOS:
            await _stopIOSAdvertising();
            break;
          default:
            // #region agent log
            developer.log('Platform not supported for stopping advertising: ${defaultTargetPlatform.name}', name: _logName);
            // #endregion
            break;
        }
      }
      
      _isAdvertising = false;
      _currentPersonalityData = null;
      
      // #region agent log
      developer.log('Personality advertising stopped: isAdvertising=$_isAdvertising', name: _logName);
      // #endregion
    } catch (e) {
      // #region agent log
      developer.log('Error stopping personality advertising: $e', name: _logName);
      // #endregion
    }
  }
  
  /// Update personality data being advertised
  /// Call this when the app's anonymized payload changes (e.g., personality evolves).
  Future<bool> updatePersonalityData({
    required AnonymizedVibeData personalityData,
    String? nodeId,
    bool eventModeEnabled = false,
    bool connectOk = false,
    bool brownout = false,
  }) async {
    if (!_isAdvertising) {
      // #region agent log
      developer.log('Not currently advertising, starting advertising instead', name: _logName);
      // #endregion
      // If not advertising, start advertising
      return await startAdvertising(
        personalityData: personalityData,
        nodeId: nodeId,
        eventModeEnabled: eventModeEnabled,
        connectOk: connectOk,
        brownout: brownout,
      );
    }
    
    try {
      // #region agent log
      developer.log('Updating advertised personality data', name: _logName);
      // #endregion
      
      _currentPersonalityData = personalityData;
      _frameNodeId = nodeId;
      _frameEventModeEnabled = eventModeEnabled;
      _frameConnectOk = connectOk;
      _frameBrownout = brownout;
      
      // Update platform-specific advertising
      // #region agent log
      developer.log('Updating platform-specific advertising: kIsWeb=$kIsWeb, platform=${defaultTargetPlatform.name}', name: _logName);
      // #endregion
      
      bool success = false;
      
      if (kIsWeb) {
        success = await _updateWebAdvertising(personalityData);
      } else {
        switch (defaultTargetPlatform) {
          case TargetPlatform.android:
            success = await _updateAndroidAdvertising(personalityData);
            break;
          case TargetPlatform.iOS:
            success = await _updateIOSAdvertising(personalityData);
            break;
          default:
            // #region agent log
            developer.log('Platform not supported for updating advertising: ${defaultTargetPlatform.name}', name: _logName);
            // #endregion
            return false;
        }
      }
      
      if (success) {
        // #region agent log
        developer.log('Personality data updated successfully', name: _logName);
        // #endregion

        unawaited(_publishServiceDataFrameV1(
          personalityData: personalityData,
          nodeId: nodeId,
          eventModeEnabled: eventModeEnabled,
          connectOk: connectOk,
          brownout: brownout,
        ));
      } else {
        // #region agent log
        developer.log('Failed to update personality data', name: _logName);
        // #endregion
      }
      
      return success;
    } catch (e) {
      developer.log('Error updating personality data: $e', name: _logName);
      return false;
    }
  }
  
  /// Check if currently advertising
  bool get isAdvertising => _isAdvertising;

  /// Update only the 24-byte service-data broadcast frame (v1) flags.
  ///
  /// This does **not** recompute/anonymize personality data, so it can be called
  /// frequently (e.g., to toggle `connect_ok` during a short check-in window).
  Future<void> updateServiceDataFrameV1Flags({
    String? nodeId,
    required bool eventModeEnabled,
    required bool connectOk,
    required bool brownout,
  }) async {
    final personalityData = _currentPersonalityData;
    if (personalityData == null) return;

    if (nodeId != null && nodeId.isNotEmpty) {
      _frameNodeId = nodeId;
    }
    _frameEventModeEnabled = eventModeEnabled;
    _frameConnectOk = connectOk;
    _frameBrownout = brownout;

    await _publishServiceDataFrameV1(
      personalityData: personalityData,
      nodeId: _frameNodeId,
      eventModeEnabled: eventModeEnabled,
      connectOk: connectOk,
      brownout: brownout,
    );
  }

  Future<void> _publishServiceDataFrameV1({
    required AnonymizedVibeData personalityData,
    required String? nodeId,
    required bool eventModeEnabled,
    required bool connectOk,
    required bool brownout,
  }) async {
    if (kIsWeb) return;

    // Default to the privacy-preserving vibe signature if a stable node id was not provided.
    // The orchestrator should pass a rotating-but-stable node id for deterministic initiation
    // and repeated-encounter tracking.
    final effectiveNodeId = (nodeId == null || nodeId.isEmpty)
        ? personalityData.vibeSignature
        : nodeId;

    try {
      final frame = SpotsBroadcastFrameV1.encode(
        utcMillis: DateTime.now().toUtc().millisecondsSinceEpoch,
        nodeId: effectiveNodeId,
        dims: personalityData.noisyDimensions,
        eventModeEnabled: eventModeEnabled,
        connectOk: connectOk,
        brownout: brownout,
      );
      await BlePeripheral.updateServiceDataFrameV1(frame: frame);
    } catch (e) {
      // Best-effort only; avoid breaking advertising due to frame failures.
      developer.log('Failed to publish service data frame v1: $e', name: _logName);
    }
  }
  
  /// Get current advertised personality data
  AnonymizedVibeData? get currentPersonalityData => _currentPersonalityData;
  
  // Platform-specific advertising implementations
  
  /// Start Android BLE advertising
  Future<bool> _startAndroidAdvertising(AnonymizedVibeData personalityData) async {
    try {
      // #region agent log
      developer.log('Starting Android advertising: hasAndroidDiscovery=${_androidDiscovery != null}', name: _logName);
      // #endregion
      
      // Use injected discovery object if available for validation
      if (_androidDiscovery != null) {
        // #region agent log
        developer.log('Using injected Android discovery object for validation', name: _logName);
        // #endregion
        final isSupported = await _androidDiscovery.isSupported();
        if (!isSupported) {
          // #region agent log
          developer.log('Android discovery reports platform not supported', name: _logName);
          // #endregion
          return false;
        }
        
        // Request permissions if needed
        final hasPermissions = await _androidDiscovery.requestPermissions();
        if (!hasPermissions) {
          // #region agent log
          developer.log('Android discovery permissions not granted', name: _logName);
          // #endregion
          return false;
        }
      }
      
      // Check if Bluetooth is available
      if (!await FlutterBluePlus.isSupported) {
        // #region agent log
        developer.log('Bluetooth not supported on Android', name: _logName);
        // #endregion
        return false;
      }
      
      // Check if Bluetooth is on
      if (await FlutterBluePlus.adapterState.first == BluetoothAdapterState.off) {
        // #region agent log
        developer.log('Bluetooth is off, cannot advertise', name: _logName);
        // #endregion
        return false;
      }
      
      // Option B: BLE peripheral (native) so nearby devices can read a payload via GATT.
      final jsonPayload = PersonalityDataCodec.encodeToJson(personalityData);
      if (jsonPayload.isEmpty) {
        developer.log('Failed to encode personality data JSON payload',
            name: _logName);
        return false;
      }

      final payloadBytes = Uint8List.fromList(utf8.encode(jsonPayload));
      final started = await BlePeripheral.startPeripheral(payload: payloadBytes);
      if (!started) {
        developer.log('Failed to start BLE peripheral advertising',
            name: _logName);
        return false;
      }

      developer.log(
        'Android BLE peripheral started (payloadBytes=${payloadBytes.length})',
        name: _logName,
      );
      return true;
      
    } catch (e) {
      developer.log('Error starting Android advertising: $e', name: _logName);
      return false;
    }
  }
  
  /// Start iOS mDNS/Bonjour advertising
  Future<bool> _startIOSAdvertising(AnonymizedVibeData personalityData) async {
    try {
      // #region agent log
      developer.log('Starting iOS advertising: hasIOSDiscovery=${_iosDiscovery != null}', name: _logName);
      // #endregion
      
      // Use injected discovery object if available for validation
      if (_iosDiscovery != null) {
        // #region agent log
        developer.log('Using injected iOS discovery object for validation', name: _logName);
        // #endregion
        final isSupported = await _iosDiscovery.isSupported();
        if (!isSupported) {
          // #region agent log
          developer.log('iOS discovery reports platform not supported', name: _logName);
          // #endregion
          return false;
        }
        
        // Request permissions if needed
        final hasPermissions = await _iosDiscovery.requestPermissions();
        if (!hasPermissions) {
          // #region agent log
          developer.log('iOS discovery permissions not granted', name: _logName);
          // #endregion
          return false;
        }
      }
      
      // Option B: BLE peripheral advertising (native) for offline AI2AI.
      final jsonPayload = PersonalityDataCodec.encodeToJson(personalityData);
      if (jsonPayload.isEmpty) {
        developer.log('Failed to encode personality data JSON payload',
            name: _logName);
        return false;
      }

      final payloadBytes = Uint8List.fromList(utf8.encode(jsonPayload));
      final started = await BlePeripheral.startPeripheral(payload: payloadBytes);
      if (!started) {
        developer.log('Failed to start BLE peripheral advertising',
            name: _logName);
        return false;
      }

      developer.log(
        'iOS BLE peripheral started (payloadBytes=${payloadBytes.length})',
        name: _logName,
      );
      return true;
      
    } catch (e) {
      developer.log('Error starting iOS advertising: $e', name: _logName);
      return false;
    }
  }
  
  /// Start Web WebRTC/WebSocket advertising
  Future<bool> _startWebAdvertising(AnonymizedVibeData personalityData) async {
    try {
      // #region agent log
      developer.log('Starting Web advertising: hasWebDiscovery=${_webDiscovery != null}', name: _logName);
      // #endregion
      
      // Use injected discovery object if available for validation
      if (_webDiscovery != null) {
        // #region agent log
        developer.log('Using injected Web discovery object for validation', name: _logName);
        // #endregion
        final isSupported = await _webDiscovery.isSupported();
        if (!isSupported) {
          // #region agent log
          developer.log('Web discovery reports platform not supported', name: _logName);
          // #endregion
          return false;
        }
        
        // Request permissions if needed
        final hasPermissions = await _webDiscovery.requestPermissions();
        if (!hasPermissions) {
          // #region agent log
          developer.log('Web discovery permissions not granted', name: _logName);
          // #endregion
          return false;
        }
      }
      
      // Encode personality data to JSON for WebRTC
      final jsonData = PersonalityDataCodec.encodeToJson(personalityData);
      if (jsonData.isEmpty) {
        // #region agent log
        developer.log('Failed to encode personality data', name: _logName);
        // #endregion
        return false;
      }
      
      // TODO: Register with WebRTC signaling server
      // This requires:
      // 1. Connect to signaling server
      // 2. Register device with personality data
      // 3. Keep connection alive for discovery
      
      // Note: This would be handled by the signaling server
      // The WebDeviceDiscovery already has the structure for this
      
      developer.log('Web advertising requires signaling server registration', name: _logName);
      developer.log('Would register with personality data: ${jsonData.length} bytes', name: _logName);
      
      // Placeholder: return true to indicate structure is ready
      return true;
      
    } catch (e) {
      developer.log('Error starting Web advertising: $e', name: _logName);
      return false;
    }
  }
  
  /// Stop Android advertising
  Future<void> _stopAndroidAdvertising() async {
    try {
      // #region agent log
      developer.log('Stopping Android BLE advertising: hasAndroidDiscovery=${_androidDiscovery != null}', name: _logName);
      // #endregion
      await BlePeripheral.stopPeripheral();
      // #region agent log
      developer.log('Android BLE advertising stopped', name: _logName);
      // #endregion
    } catch (e) {
      // #region agent log
      developer.log('Error stopping Android advertising: $e', name: _logName);
      // #endregion
    }
  }
  
  /// Stop iOS advertising
  Future<void> _stopIOSAdvertising() async {
    try {
      // #region agent log
      developer.log('Stopping iOS BLE advertising: hasIOSDiscovery=${_iosDiscovery != null}', name: _logName);
      // #endregion
      await BlePeripheral.stopPeripheral();
      developer.log('Stopped iOS BLE advertising', name: _logName);
    } catch (e) {
      // #region agent log
      developer.log('Error stopping iOS advertising: $e', name: _logName);
      // #endregion
    }
  }
  
  /// Stop Web advertising
  Future<void> _stopWebAdvertising() async {
    try {
      // #region agent log
      developer.log('Stopping Web advertising: hasWebDiscovery=${_webDiscovery != null}', name: _logName);
      // #endregion
      // TODO: Unregister from signaling server
      // #region agent log
      developer.log('Web advertising stopped', name: _logName);
      // #endregion
    } catch (e) {
      // #region agent log
      developer.log('Error stopping Web advertising: $e', name: _logName);
      // #endregion
    }
  }
  
  /// Update Android advertising
  Future<bool> _updateAndroidAdvertising(AnonymizedVibeData personalityData) async {
    // Stop and restart with new data
    await _stopAndroidAdvertising();
    return await _startAndroidAdvertising(personalityData);
  }
  
  /// Update iOS advertising
  Future<bool> _updateIOSAdvertising(AnonymizedVibeData personalityData) async {
    // Stop and restart with new data
    await _stopIOSAdvertising();
    return await _startIOSAdvertising(personalityData);
  }
  
  /// Update Web advertising
  Future<bool> _updateWebAdvertising(AnonymizedVibeData personalityData) async {
    // Update registration with new data
    // This would update the signaling server registration
    developer.log('Updating Web advertising with new personality data', name: _logName);
    return true;
  }
  
  /// Start automatic refresh timer
  void _startRefreshTimer({
    required Future<AnonymizedVibeData> Function()? refresh,
    required Duration refreshInterval,
  }) {
    _refreshTimer?.cancel();
    _refreshTimer = null;

    if (refresh == null) {
      return;
    }

    developer.log(
      'Starting refresh timer: refreshInterval=${refreshInterval.inMinutes} minutes',
      name: _logName,
    );

    _refreshTimer = Timer.periodic(refreshInterval, (timer) async {
      final currentData = _currentPersonalityData;
      if (currentData == null) {
        developer.log('No current personality data to refresh', name: _logName);
        return;
      }

      final timeUntilExpiry = currentData.expiresAt.difference(DateTime.now());
      developer.log(
        'Refresh timer tick: timeUntilExpiry=${timeUntilExpiry.inMinutes} minutes',
        name: _logName,
      );

      // Refresh if expired or expiring within 1 minute.
      if (timeUntilExpiry.inMinutes >= 1) return;

      try {
        developer.log(
          'Personality data expiring soon, refreshing advertisement',
          name: _logName,
        );

        final updated = await refresh();
        await updatePersonalityData(
          personalityData: updated,
          nodeId: _frameNodeId,
          eventModeEnabled: _frameEventModeEnabled,
          connectOk: _frameConnectOk,
          brownout: _frameBrownout,
        );
      } catch (e) {
        developer.log('Error refreshing advertised data: $e', name: _logName);
      }
    });
  }
}

