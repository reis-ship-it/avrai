import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/services.dart';

/// UWB Nearby Interaction service for iOS-exclusive precise proximity detection.
///
/// Provides cm-level accuracy for device proximity (vs BLE meter-level accuracy).
/// Features:
/// - Distance measurement with cm precision
/// - Directional awareness (azimuth/elevation)
/// - Secure peer token exchange
///
/// Falls back to BLE on non-iOS devices or devices without UWB chip (pre-iPhone 11).
class NearbyInteractionService {
  static const String _logName = 'NearbyInteractionService';
  static const MethodChannel _channel =
      MethodChannel('avra/nearby_interaction');
  static const EventChannel _eventChannel =
      EventChannel('avra/nearby_interaction_events');

  StreamSubscription<dynamic>? _eventSubscription;
  final StreamController<NearbyPeerUpdate> _peerUpdatesController =
      StreamController<NearbyPeerUpdate>.broadcast();

  bool _isSessionActive = false;
  final Map<String, NearbyPeer> _peers = {};

  /// Stream of peer updates (distance, direction changes, peer added/removed).
  Stream<NearbyPeerUpdate> get peerUpdates => _peerUpdatesController.stream;

  /// Currently known peers with their last known distance/direction.
  Map<String, NearbyPeer> get peers => Map.unmodifiable(_peers);

  /// Whether UWB session is currently active.
  bool get isSessionActive => _isSessionActive;

  /// Check if UWB Nearby Interaction is supported on this device.
  ///
  /// Only iOS 14.0+ devices with U1/U2 chip (iPhone 11+) support UWB.
  Future<bool> isSupported() async {
    if (!Platform.isIOS) return false;

    try {
      final result = await _channel.invokeMethod<bool>('isSupported');
      return result ?? false;
    } on PlatformException catch (e) {
      developer.log(
        'Error checking UWB support: ${e.code} ${e.message}',
        name: _logName,
      );
      return false;
    } on MissingPluginException {
      // Channel not registered (likely iOS < 14)
      return false;
    }
  }

  /// Start UWB session.
  ///
  /// Must call [getDiscoveryToken] and exchange with peer before proximity works.
  Future<bool> startSession() async {
    if (!Platform.isIOS) {
      developer.log('UWB only available on iOS', name: _logName);
      return false;
    }

    try {
      final result = await _channel.invokeMethod<bool>('startSession');
      if (result == true) {
        _isSessionActive = true;
        _startEventListener();
        developer.log('UWB session started', name: _logName);
      }
      return result ?? false;
    } on PlatformException catch (e) {
      developer.log(
        'Error starting UWB session: ${e.code} ${e.message}',
        name: _logName,
      );
      return false;
    }
  }

  /// Stop UWB session.
  Future<bool> stopSession() async {
    try {
      final result = await _channel.invokeMethod<bool>('stopSession');
      _isSessionActive = false;
      _peers.clear();
      _stopEventListener();
      developer.log('UWB session stopped', name: _logName);
      return result ?? false;
    } on PlatformException catch (e) {
      developer.log(
        'Error stopping UWB session: ${e.code} ${e.message}',
        name: _logName,
      );
      return false;
    }
  }

  /// Get this device's discovery token to share with peers.
  ///
  /// Exchange this token with a peer via BLE/network to enable UWB proximity.
  Future<Uint8List?> getDiscoveryToken() async {
    try {
      final result =
          await _channel.invokeMethod<Uint8List>('getDiscoveryToken');
      return result;
    } on PlatformException catch (e) {
      developer.log(
        'Error getting discovery token: ${e.code} ${e.message}',
        name: _logName,
      );
      return null;
    }
  }

  /// Start proximity detection with a peer using their discovery token.
  ///
  /// [token] - The peer's discovery token obtained via BLE/network exchange.
  /// [peerId] - A unique identifier for this peer (e.g., device ID, agent ID).
  Future<bool> runWithPeerToken({
    required Uint8List token,
    required String peerId,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>('runWithPeerToken', {
        'token': token,
        'peerId': peerId,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      developer.log(
        'Error running with peer token: ${e.code} ${e.message}',
        name: _logName,
      );
      return false;
    }
  }

  /// Get distance to a specific peer in meters.
  Future<double?> getDistance(String peerId) async {
    try {
      final result = await _channel
          .invokeMethod<double>('getDistance', {'peerId': peerId});
      return result;
    } on PlatformException {
      return null;
    }
  }

  /// Get direction to a specific peer as a 3D vector.
  Future<Direction3D?> getDirection(String peerId) async {
    try {
      final result =
          await _channel.invokeMethod<Map>('getDirection', {'peerId': peerId});
      if (result == null) return null;
      return Direction3D(
        x: (result['x'] as num?)?.toDouble() ?? 0.0,
        y: (result['y'] as num?)?.toDouble() ?? 0.0,
        z: (result['z'] as num?)?.toDouble() ?? 0.0,
      );
    } on PlatformException {
      return null;
    }
  }

  /// Get all currently tracked peers with distance/direction.
  Future<List<NearbyPeer>> getAllPeers() async {
    try {
      final result = await _channel.invokeMethod<List>('getAllPeers');
      if (result == null) return [];
      return result.map((e) {
        final map = e as Map;
        Direction3D? direction;
        if (map['direction'] != null) {
          final d = map['direction'] as Map;
          direction = Direction3D(
            x: (d['x'] as num?)?.toDouble() ?? 0.0,
            y: (d['y'] as num?)?.toDouble() ?? 0.0,
            z: (d['z'] as num?)?.toDouble() ?? 0.0,
          );
        }
        return NearbyPeer(
          peerId: map['peerId'] as String,
          distance: (map['distance'] as num?)?.toDouble(),
          direction: direction,
        );
      }).toList();
    } on PlatformException {
      return [];
    }
  }

  void _startEventListener() {
    _eventSubscription ??= _eventChannel.receiveBroadcastStream().listen(
      _handleEvent,
      onError: (error) {
        developer.log('UWB event error: $error', name: _logName);
      },
    );
  }

  void _stopEventListener() {
    _eventSubscription?.cancel();
    _eventSubscription = null;
  }

  void _handleEvent(dynamic event) {
    if (event is! Map) return;

    final type = event['type'] as String?;
    switch (type) {
      case 'peerUpdate':
        final peerId = event['peerId'] as String?;
        if (peerId == null) return;

        final distance = (event['distance'] as num?)?.toDouble();
        Direction3D? direction;
        if (event['direction'] != null) {
          final d = event['direction'] as Map;
          direction = Direction3D(
            x: (d['x'] as num?)?.toDouble() ?? 0.0,
            y: (d['y'] as num?)?.toDouble() ?? 0.0,
            z: (d['z'] as num?)?.toDouble() ?? 0.0,
          );
        }

        final peer = NearbyPeer(
          peerId: peerId,
          distance: distance,
          direction: direction,
        );
        _peers[peerId] = peer;

        _peerUpdatesController.add(NearbyPeerUpdate(
          type: NearbyUpdateType.updated,
          peer: peer,
        ));
        break;

      case 'peerRemoved':
        final peerId = event['peerId'] as String?;
        if (peerId == null) return;

        final peer = _peers.remove(peerId);
        if (peer != null) {
          _peerUpdatesController.add(NearbyPeerUpdate(
            type: NearbyUpdateType.removed,
            peer: peer,
          ));
        }
        break;

      case 'sessionInvalidated':
        _isSessionActive = false;
        _peers.clear();
        developer.log(
          'UWB session invalidated: ${event['error']}',
          name: _logName,
        );
        break;

      case 'sessionSuspended':
        developer.log('UWB session suspended', name: _logName);
        break;

      case 'sessionResumed':
        developer.log('UWB session resumed', name: _logName);
        break;
    }
  }

  /// Dispose of resources.
  void dispose() {
    _stopEventListener();
    _peerUpdatesController.close();
  }
}

/// A nearby peer detected via UWB.
class NearbyPeer {
  /// Unique identifier for this peer.
  final String peerId;

  /// Distance to peer in meters (cm-level precision).
  final double? distance;

  /// 3D direction to peer (azimuth/elevation).
  final Direction3D? direction;

  NearbyPeer({
    required this.peerId,
    this.distance,
    this.direction,
  });

  @override
  String toString() =>
      'NearbyPeer(peerId: $peerId, distance: ${distance?.toStringAsFixed(2)}m, direction: $direction)';
}

/// 3D direction vector for UWB directional awareness.
class Direction3D {
  final double x;
  final double y;
  final double z;

  Direction3D({required this.x, required this.y, required this.z});

  @override
  String toString() =>
      'Direction3D(x: ${x.toStringAsFixed(2)}, y: ${y.toStringAsFixed(2)}, z: ${z.toStringAsFixed(2)})';
}

/// Type of nearby peer update.
enum NearbyUpdateType { updated, removed }

/// A peer update event.
class NearbyPeerUpdate {
  final NearbyUpdateType type;
  final NearbyPeer peer;

  NearbyPeerUpdate({required this.type, required this.peer});
}
