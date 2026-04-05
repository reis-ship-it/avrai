import 'dart:typed_data';
import 'package:avrai_network/network/device_discovery.dart';

Future<Uint8List?> fetchDnaPayloadOverBle(DiscoveredDevice device) async {
  // Web does not support CoreBluetooth-style BLE GATT operations.
  return null;
}
