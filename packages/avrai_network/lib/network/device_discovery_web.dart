import 'dart:developer' as developer;
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;

// This file is only imported when dart.library.html is available (web platform)
// Conditional import ensures this code is never analyzed on mobile platforms
// Migrated from dart:html to package:web for modern web API bindings
import 'package:web/web.dart';
import 'dart:js_interop';
// Note: flutter_nsd may not be fully supported on web
// Using conditional imports would be ideal, but for now we'll use dynamic typing
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:avrai_network/network/device_discovery.dart';
import 'package:avrai_network/network/webrtc_signaling_config.dart';
import 'package:avrai_network/network/personality_data_codec.dart';
import 'package:avrai_network/network/models/anonymized_vibe_data.dart';
import 'package:avrai_network/network/device_discovery_stub.dart' as stub;

/// Expose the stub implementation on Web so that
/// `device_discovery_factory.dart` can compile (it references `StubDeviceDiscovery`
/// regardless of platform).
typedef StubDeviceDiscovery = stub.StubDeviceDiscovery;

/// Android/iOS discovery is not available on Web, but the symbols must exist
/// for compilation because they are referenced by the factory.
DeviceDiscoveryPlatform createAndroidDeviceDiscovery() =>
    stub.createAndroidDeviceDiscovery();
DeviceDiscoveryPlatform createIOSDeviceDiscovery() =>
    stub.createIOSDeviceDiscovery();

/// Web-specific device discovery implementation
/// Uses WebRTC peer discovery and WebSocket fallback for device discovery
class WebDeviceDiscovery extends DeviceDiscoveryPlatform {
  static const String _logName = 'WebDeviceDiscovery';
  
  // WebRTC signaling server configuration
  final WebRTCSignalingConfig _signalingConfig;
  
  WebDeviceDiscovery({WebRTCSignalingConfig? signalingConfig}) 
      : _signalingConfig = signalingConfig ?? WebRTCSignalingConfig();
  
  @override
  bool isSupported() {
    return kIsWeb;
  }
  
  @override
  Future<bool> requestPermissions() async {
    try {
      developer.log('Requesting Web device discovery permissions', name: _logName);
      
      // Web doesn't require explicit permissions for WebRTC/WebSocket
      // However, HTTPS is required for WebRTC to work
      
      // Check if we're on HTTPS
      final isSecure = _isSecureContext();
      
      if (!isSecure) {
        developer.log('WebRTC requires HTTPS context', name: _logName);
        return false;
      }
      
      developer.log('Web permissions OK (HTTPS context)', name: _logName);
      return true;
    } catch (e) {
      developer.log('Error checking Web permissions: $e', name: _logName);
      return false;
    }
  }
  
  @override
  Future<List<DiscoveredDevice>> scanForDevices({
    Duration scanWindow = const Duration(seconds: 4),
  }) async {
    if (!isSupported()) {
      developer.log('Web discovery not supported on this platform', name: _logName);
      return [];
    }
    
    try {
      developer.log('Scanning for devices on Web', name: _logName);
      
      final devices = <DiscoveredDevice>[];
      
      // Scan using Network Service Discovery (mDNS) if available
      try {
        final nsdDevices = await _scanNetworkServiceDiscovery();
        devices.addAll(nsdDevices);
        developer.log('Found ${nsdDevices.length} NSD devices', name: _logName);
      } catch (e) {
        developer.log('Error scanning NSD: $e', name: _logName);
      }
      
      // Scan using WebRTC peer discovery (if signaling server configured)
      if (_signalingConfig.isConfigured()) {
        try {
          final webrtcDevices = await _scanWebRTC();
          devices.addAll(webrtcDevices);
          developer.log('Found ${webrtcDevices.length} WebRTC devices', name: _logName);
        } catch (e) {
          developer.log('Error scanning WebRTC: $e', name: _logName);
        }
      }
      
      // Scan using WebSocket fallback (if signaling server configured)
      if (_signalingConfig.isConfigured()) {
        try {
          final websocketDevices = await _scanWebSocket();
          devices.addAll(websocketDevices);
          developer.log('Found ${websocketDevices.length} WebSocket devices', name: _logName);
        } catch (e) {
          developer.log('Error scanning WebSocket: $e', name: _logName);
        }
      }
      
      developer.log('Total devices discovered: ${devices.length}', name: _logName);
      return devices;
    } catch (e) {
      developer.log('Error scanning for Web devices: $e', name: _logName);
      return [];
    }
  }
  
  @override
  Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      // Get Web browser information
      // This could include:
      // - User agent
      // - Browser capabilities
      // - WebRTC support
      // - WebSocket support
      
      return {
        'platform': 'web',
        'supported': isSupported(),
        'is_secure_context': _isSecureContext(),
        'user_agent': _getUserAgent(),
        'note': 'Device info collection requires browser API access',
      };
    } catch (e) {
      developer.log('Error getting Web device info: $e', name: _logName);
      return {'platform': 'web', 'error': e.toString()};
    }
  }
  
  /// Check if we're in a secure context (HTTPS)
  bool _isSecureContext() {
    try {
      // Check if we're in a secure context (HTTPS)
      return window.isSecureContext;
    } catch (e) {
      developer.log('Error checking secure context: $e', name: _logName);
      // Fallback: check if URL is HTTPS
      try {
        return window.location.protocol == 'https:';
      } catch (_) {
        return false;
      }
    }
  }
  
  /// Get user agent string
  String _getUserAgent() {
    try {
      // userAgent is non-nullable in package:web, but wrap in try-catch for safety
      return window.navigator.userAgent;
    } catch (e) {
      developer.log('Error getting user agent: $e', name: _logName);
      return 'Unknown Browser';
    }
  }
  
  /// Scan using Network Service Discovery (mDNS) on Web
  Future<List<DiscoveredDevice>> _scanNetworkServiceDiscovery() async {
    final devices = <DiscoveredDevice>[];
    
    try {
      // Note: mDNS/Bonjour on Web is limited
      // Most browsers don't support mDNS directly
      // This would require a browser extension or server-side proxy
      // For now, skip mDNS discovery on Web and rely on WebRTC/WebSocket
      developer.log('mDNS discovery not available on Web platform - using WebRTC/WebSocket instead', name: _logName);
      // Return empty list - WebRTC/WebSocket discovery will be used instead
      return devices;
    } catch (e) {
      developer.log('Error in NSD scan: $e', name: _logName);
      return devices;
    }
  }
  
  /// Scan using WebRTC peer discovery
  Future<List<DiscoveredDevice>> _scanWebRTC() async {
    final devices = <DiscoveredDevice>[];
    
    final signalingUrl = _signalingConfig.getSignalingServerUrl();
    if (signalingUrl.isEmpty) {
      developer.log('No signaling server URL configured', name: _logName);
      return [];
    }
    
    try {
      // Connect to signaling server via WebSocket
      final ws = WebSocket(signalingUrl);
      
      // Wait for connection
      final openCompleter = Completer<void>();
      ws.addEventListener('open', (Event event) {
        openCompleter.complete();
      }.toJS);
      await openCompleter.future;
      
      // Register this device and request peer list
      final messageJson = '{"type": "discover", "device_id": "${_generateDeviceId()}"}';
      final messageBytes = utf8.encode(messageJson);
      final messageBase64 = base64Encode(messageBytes);
      ws.send(messageBase64.toJS);
      
      // Listen for peer list response
      final completer = Completer<List<DiscoveredDevice>>();
      final timer = Timer(const Duration(seconds: 5), () {
        if (!completer.isCompleted) {
          completer.complete(devices);
        }
      });
      
      ws.addEventListener('message', ((Event event) {
        try {
          final messageEvent = event as MessageEvent;
          final dataString = (messageEvent.data as JSString).toDart;
          final dataBytes = base64Decode(dataString);
          final data = utf8.decode(dataBytes);
          final json = jsonDecode(data) as Map<String, dynamic>;
          
          if (json['type'] == 'peers') {
            final peers = json['peers'] as List;
            for (final peer in peers) {
              final peerData = peer as Map<String, dynamic>;
              
              if (peerData['spots_enabled'] == true) {
                final personalityData = _extractPersonalityFromPeer(peerData);
                
                devices.add(DiscoveredDevice(
                  deviceId: peerData['device_id'] as String,
                  deviceName: peerData['device_name'] as String? ?? 'SPOTS Device',
                  type: DeviceType.webrtc,
                  isSpotsEnabled: true,
                  personalityData: personalityData,
                  discoveredAt: DateTime.now(),
                  metadata: {
                    'peer_connection_id': peerData['peer_id'] as String?,
                    'signaling_server': signalingUrl,
                  },
                ));
              }
            }
            
            if (!completer.isCompleted) {
              timer.cancel();
              completer.complete(devices);
            }
          }
        } catch (e) {
          developer.log('Error parsing WebRTC message: $e', name: _logName);
        }
      }).toJS);
      
      ws.addEventListener('error', ((Event error) {
        developer.log('WebSocket error: $error', name: _logName);
        if (!completer.isCompleted) {
          timer.cancel();
          completer.complete(devices);
        }
      }).toJS);
      
      await completer.future;
      ws.close();
      
    } catch (e) {
      developer.log('Error in WebRTC scan: $e', name: _logName);
    }
    
    return devices;
  }
  
  /// Scan using WebSocket fallback
  Future<List<DiscoveredDevice>> _scanWebSocket() async {
    final devices = <DiscoveredDevice>[];
    
    final signalingUrl = _signalingConfig.getSignalingServerUrl();
    if (signalingUrl.isEmpty) {
      return [];
    }
    
    try {
      // Use same signaling server but simpler protocol
      final ws = WebSocket(signalingUrl);
      final openCompleter = Completer<void>();
      ws.addEventListener('open', (Event event) {
        openCompleter.complete();
      }.toJS);
      await openCompleter.future;
      
      // Request device list
      const messageJson = '{"action": "discover"}';
      final messageBytes = utf8.encode(messageJson);
      final messageBase64 = base64Encode(messageBytes);
      ws.send(messageBase64.toJS);
      
      final completer = Completer<List<DiscoveredDevice>>();
      final timer = Timer(const Duration(seconds: 3), () {
        if (!completer.isCompleted) {
          completer.complete(devices);
        }
      });
      
      ws.addEventListener('message', ((Event event) {
        try {
          final messageEvent = event as MessageEvent;
          final dataString = (messageEvent.data as JSString).toDart;
          final dataBytes = base64Decode(dataString);
          final data = utf8.decode(dataBytes);
          final json = jsonDecode(data) as Map<String, dynamic>;
          
          if (json['action'] == 'devices') {
            final deviceList = json['devices'] as List;
            for (final deviceData in deviceList) {
              final d = deviceData as Map<String, dynamic>;
              
              devices.add(DiscoveredDevice(
                deviceId: d['id'] as String,
                deviceName: d['name'] as String? ?? 'SPOTS Device',
                type: DeviceType.webrtc,
                isSpotsEnabled: d['spots_enabled'] == true,
                discoveredAt: DateTime.now(),
                metadata: d,
              ));
            }
            
            if (!completer.isCompleted) {
              timer.cancel();
              completer.complete(devices);
            }
          }
        } catch (e) {
          developer.log('Error parsing WebSocket message: $e', name: _logName);
        }
      }).toJS);
      
      await completer.future;
      ws.close();
      
    } catch (e) {
      developer.log('Error in WebSocket scan: $e', name: _logName);
    }
    
    return devices;
  }
  
  /// Generate a unique device ID for Web
  String _generateDeviceId() {
    // Use browser fingerprinting or generate UUID
    // For now, use a simple hash of user agent
    return _getUserAgent().hashCode.toString();
  }
  
  /// Check if a network service is a SPOTS service
  /// Reserved for future mDNS/NSD implementation on Web
  // ignore: unused_element
  bool _isSpotsService(dynamic service) {
    if (service.name.toLowerCase().contains('spots')) {
      return true;
    }
    
    final txtRecord = service.txtRecord;
    if (txtRecord != null && txtRecord.containsKey('spots')) {
      return true;
    }
    
    return false;
  }
  
  /// Extract personality data from network service
  /// Reserved for future mDNS/NSD implementation on Web
  // ignore: unused_element
  AnonymizedVibeData? _extractPersonalityFromService(dynamic service) {
    try {
      final txtRecord = service.txtRecord;
      if (txtRecord == null) return null;
      
      // Try base64 encoded personality data
      final personalityDataStr = txtRecord['personality_data'] as String?;
      if (personalityDataStr != null && personalityDataStr.isNotEmpty) {
        return PersonalityDataCodec.decodeFromBase64(personalityDataStr);
      }
      
      // Try JSON encoded personality data
      final personalityDataJson = txtRecord['personality_data_json'] as String?;
      if (personalityDataJson != null && personalityDataJson.isNotEmpty) {
        return PersonalityDataCodec.decodeFromJson(personalityDataJson);
      }
      
      return null;
    } catch (e) {
      developer.log('Error extracting personality from service: $e', name: _logName);
      return null;
    }
  }
  
  /// Extract personality data from WebRTC peer data
  AnonymizedVibeData? _extractPersonalityFromPeer(Map<String, dynamic> peerData) {
    try {
      // Try base64 encoded personality data
      final personalityDataBase64 = peerData['personality_data'] as String?;
      if (personalityDataBase64 != null && personalityDataBase64.isNotEmpty) {
        return PersonalityDataCodec.decodeFromBase64(personalityDataBase64);
      }
      
      // Try JSON encoded personality data
      final personalityDataJson = peerData['personality_data_json'];
      if (personalityDataJson != null) {
        if (personalityDataJson is String) {
          return PersonalityDataCodec.decodeFromJson(personalityDataJson);
        } else if (personalityDataJson is Map) {
          // Already decoded JSON, convert directly
          return PersonalityDataCodec.decodeFromJson(
            jsonEncode(personalityDataJson),
          );
        }
      }
      
      return null;
    } catch (e) {
      developer.log('Error extracting personality from peer: $e', name: _logName);
      return null;
    }
  }
  
  /// Set signaling server URL for WebRTC discovery
  Future<bool> setSignalingServerUrl(String url) async {
    return await _signalingConfig.setSignalingServerUrl(url);
  }
}

/// Create Web device discovery implementation
/// This function is called from device_discovery_factory.dart via conditional import
DeviceDiscoveryPlatform createWebDeviceDiscovery() {
  try {
    final getIt = GetIt.instance;
    final prefs = getIt.get<SharedPreferences>();
    final signalingConfig = WebRTCSignalingConfig(prefs: prefs);
    return WebDeviceDiscovery(signalingConfig: signalingConfig);
  } catch (e) {
    // Fallback if SharedPreferences not available
    return WebDeviceDiscovery();
  }
}
