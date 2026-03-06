import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:avrai_network/network/ble_gatt_stream_fetcher.dart';
import 'package:avrai_network/network/device_discovery.dart';

const _logName = 'BlePersonalityFetcher';

Future<Uint8List?> fetchDnaPayloadOverBle(
  DiscoveredDevice device,
) async {
  try {
    final bytes = await fetchBleGattStreamPayload(device: device, streamId: 0);
    if (bytes == null || bytes.isEmpty) return null;

    return bytes;
  } catch (e, st) {
    developer.log(
      'Error fetching BLE DNA payload',
      name: _logName,
      error: e,
      stackTrace: st,
    );
    return null;
  }
}
