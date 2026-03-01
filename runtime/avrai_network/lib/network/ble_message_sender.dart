import 'dart:typed_data';

import 'package:avrai_network/network/ble_message_sender_impl_stub.dart'
    if (dart.library.io) 'package:avrai_network/network/ble_message_sender_impl_io.dart'
    if (dart.library.html) 'package:avrai_network/network/ble_message_sender_impl_web.dart'
    as impl;
import 'package:avrai_network/network/device_discovery.dart';

/// Send an opaque packet to a nearby device by writing to its SPOTS GATT service.
///
/// Packets are chunked and framed as "SPTM" writes to avoid conflicting with the
/// "SPTS" control frames used for chunked reads.
Future<bool> sendBlePacket({
  required DiscoveredDevice device,
  required String senderId,
  required Uint8List packetBytes,
}) {
  return impl.sendBlePacket(
    device: device,
    senderId: senderId,
    packetBytes: packetBytes,
  );
}

/// Send multiple packets in a single BLE connection.
///
/// This is the preferred high-throughput path:
/// - connect once
/// - send N messages (each with its own msgId)
/// - read ACK stream once (with polling) to confirm delivery
///
/// Returns a `List<bool>` aligned with `packetBytesList`.
Future<List<bool>> sendBlePacketsBatch({
  required DiscoveredDevice device,
  required String senderId,
  required List<Uint8List> packetBytesList,
}) {
  return impl.sendBlePacketsBatch(
    device: device,
    senderId: senderId,
    packetBytesList: packetBytesList,
  );
}
