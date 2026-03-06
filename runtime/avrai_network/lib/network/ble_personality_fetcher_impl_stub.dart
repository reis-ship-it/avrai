import 'dart:typed_data';
import 'package:avrai_network/network/device_discovery.dart';

Future<Uint8List?> fetchDnaPayloadOverBle(
  DiscoveredDevice device,
) async {
  // Non-IO / unsupported platforms.
  return null;
}
