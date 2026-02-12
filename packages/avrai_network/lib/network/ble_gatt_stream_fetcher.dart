import 'dart:typed_data';

import 'package:avrai_network/network/ble_gatt_stream_fetcher_impl_stub.dart'
    if (dart.library.io) 'package:avrai_network/network/ble_gatt_stream_fetcher_impl_io.dart'
    if (dart.library.html) 'package:avrai_network/network/ble_gatt_stream_fetcher_impl_web.dart'
    as impl;
import 'package:avrai_network/network/device_discovery.dart';

/// Fetch a stream payload over BLE GATT using the SPOTS read/write characteristics.
///
/// `streamId`:
/// - 0: anonymized vibe payload (discovery)
/// - 1: Signal prekey payload (offline bootstrap)
Future<Uint8List?> fetchBleGattStreamPayload({
  required DiscoveredDevice device,
  required int streamId,
}) {
  return impl.fetchBleGattStreamPayload(device: device, streamId: streamId);
}

