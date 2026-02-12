import 'dart:typed_data';

import 'package:avrai_network/network/device_discovery.dart';

/// Stubbed BLE connection pool for unsupported platforms (web/tests).
class BleConnectionPool {
  static final BleConnectionPool instance = BleConnectionPool._();

  BleConnectionPool._();

  Future<BleGattSession> openSession({required DiscoveredDevice device}) async {
    throw UnsupportedError('BLE connection pool is not available on this platform');
  }
}

/// Stubbed session for unsupported platforms.
class BleGattSession {
  Future<Uint8List?> readStreamPayload({required int streamId}) async {
    return null;
  }

  Future<List<bool>> sendPacketsBatch({
    required String senderId,
    required List<Uint8List> packetBytesList,
  }) async {
    return List<bool>.filled(packetBytesList.length, false);
  }

  Future<void> invalidateConnection() async {}

  Future<void> close() async {}
}

