import 'dart:typed_data';

import 'package:avrai_network/network/device_discovery.dart';

Future<bool> sendBlePacket({
  required DiscoveredDevice device,
  required String senderId,
  required Uint8List packetBytes,
}) async {
  return false;
}

Future<List<bool>> sendBlePacketsBatch({
  required DiscoveredDevice device,
  required String senderId,
  required List<Uint8List> packetBytesList,
}) async {
  return List<bool>.filled(packetBytesList.length, false);
}
