import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:avrai_network/network/ble_connection_pool.dart';
import 'package:avrai_network/network/device_discovery.dart';

const _logName = 'BleGattStreamFetcher';
final _pool = BleConnectionPool.instance;

Future<Uint8List?> fetchBleGattStreamPayload({
  required DiscoveredDevice device,
  required int streamId,
}) async {
  if (device.type != DeviceType.bluetooth) return null;

  BleGattSession? session;
  try {
    session = await _pool.openSession(device: device);
    return await session.readStreamPayload(streamId: streamId);
  } catch (e, st) {
    developer.log(
      'Error fetching BLE GATT stream payload',
      name: _logName,
      error: e,
      stackTrace: st,
    );
    try {
      await session?.invalidateConnection();
    } catch (_) {
      // Ignore.
    }
    return null;
  } finally {
    try {
      await session?.close();
    } catch (_) {
      // Ignore.
    }
  }
}
