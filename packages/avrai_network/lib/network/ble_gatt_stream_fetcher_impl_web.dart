import 'dart:typed_data';

import 'package:avrai_network/network/device_discovery.dart';

Future<Uint8List?> fetchBleGattStreamPayload({
  required DiscoveredDevice device,
  required int streamId,
}) async {
  // Web does not support CoreBluetooth-style GATT reads.
  return null;
}

