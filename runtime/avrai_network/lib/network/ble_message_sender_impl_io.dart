import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:avrai_network/network/ble_connection_pool.dart';
import 'package:avrai_network/network/device_discovery.dart';

const _logName = 'BleMessageSender';
final _pool = BleConnectionPool.instance;

Future<bool> sendBlePacket({
  required DiscoveredDevice device,
  required String senderId,
  required Uint8List packetBytes,
}) async {
  final results = await sendBlePacketsBatch(
    device: device,
    senderId: senderId,
    packetBytesList: <Uint8List>[packetBytes],
  );
  return results.isNotEmpty && results.first;
}

Future<List<bool>> sendBlePacketsBatch({
  required DiscoveredDevice device,
  required String senderId,
  required List<Uint8List> packetBytesList,
}) async {
  if (packetBytesList.isEmpty) return const [];

  for (var attempt = 0; attempt < 3; attempt++) {
    BleGattSession? session;
    try {
      session = await _pool.openSession(device: device);
      final results = await session.sendPacketsBatch(
        senderId: senderId,
        packetBytesList: packetBytesList,
      );
      return results;
    } catch (e, st) {
      developer.log(
        'Error sending BLE batch (attempt=${attempt + 1})',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      try {
        await session?.invalidateConnection();
      } catch (_) {
        // Ignore.
      }
    } finally {
      try {
        await session?.close();
      } catch (_) {
        // Ignore.
      }
    }

    await Future.delayed(Duration(milliseconds: 250 * (1 << attempt)));
  }

  return List<bool>.filled(packetBytesList.length, false);
}
