import 'dart:developer' as developer;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

/// WebRTC Signaling Server Configuration
/// Manages configuration for WebRTC peer discovery on Web platform
class WebRTCSignalingConfig {
  static const String _logName = 'WebRTCSignalingConfig';
  static const String _signalingServerUrlKey = 'webrtc_signaling_server_url';
  static const String _defaultSignalingServerUrl = 'wss://signaling.avrai.app';

  final SharedPreferences? _prefs;

  WebRTCSignalingConfig({SharedPreferences? prefs}) : _prefs = prefs;

  /// Get the configured signaling server URL
  String getSignalingServerUrl() {
    if (!kIsWeb) {
      developer.log(
        'WebRTC signaling only available on Web platform',
        name: _logName,
      );
      return '';
    }

    try {
      // Try to get from preferences first
      if (_prefs != null) {
        final url = _prefs.getString(_signalingServerUrlKey);
        if (url != null && url.isNotEmpty) {
          return url;
        }
      }

      // Return default URL
      return _defaultSignalingServerUrl;
    } catch (e) {
      developer.log('Error getting signaling server URL: $e', name: _logName);
      return _defaultSignalingServerUrl;
    }
  }

  /// Set the signaling server URL
  Future<bool> setSignalingServerUrl(String url) async {
    if (!kIsWeb) {
      developer.log(
        'WebRTC signaling only available on Web platform',
        name: _logName,
      );
      return false;
    }

    // Validate URL format
    if (!_isValidWebSocketUrl(url)) {
      developer.log('Invalid WebSocket URL: $url', name: _logName);
      return false;
    }

    try {
      if (_prefs != null) {
        await _prefs.setString(_signalingServerUrlKey, url);
        developer.log('Signaling server URL set to: $url', name: _logName);
        return true;
      }

      developer.log(
        'SharedPreferences not available, URL not persisted',
        name: _logName,
      );
      return false;
    } catch (e) {
      developer.log('Error setting signaling server URL: $e', name: _logName);
      return false;
    }
  }

  /// Check if signaling server URL is configured
  bool isConfigured() {
    if (!kIsWeb) return false;

    try {
      if (_prefs != null) {
        final url = _prefs.getString(_signalingServerUrlKey);
        return url != null && url.isNotEmpty;
      }

      // If no prefs, assume default is available
      return true;
    } catch (e) {
      developer.log('Error checking configuration: $e', name: _logName);
      return false;
    }
  }

  /// Reset to default signaling server URL
  Future<bool> resetToDefault() async {
    if (!kIsWeb) return false;

    try {
      if (_prefs != null) {
        await _prefs.remove(_signalingServerUrlKey);
        developer.log('Reset to default signaling server URL', name: _logName);
        return true;
      }

      return false;
    } catch (e) {
      developer.log('Error resetting to default: $e', name: _logName);
      return false;
    }
  }

  /// Validate WebSocket URL format
  bool _isValidWebSocketUrl(String url) {
    // Check for WebSocket protocol
    if (!url.startsWith('ws://') && !url.startsWith('wss://')) {
      return false;
    }

    // Basic URL validation
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && uri.hasAuthority;
    } catch (e) {
      return false;
    }
  }

  /// Get signaling server configuration info
  Map<String, dynamic> getConfigInfo() {
    return {
      'is_web': kIsWeb,
      'is_configured': isConfigured(),
      'signaling_server_url': isConfigured() ? getSignalingServerUrl() : null,
      'default_url': _defaultSignalingServerUrl,
    };
  }
}
