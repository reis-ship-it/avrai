import 'package:avrai_network/network/device_discovery.dart';
import 'package:avrai_network/network/models/anonymized_vibe_data.dart';

Future<AnonymizedVibeData?> fetchPersonalityDataOverBle(
  DiscoveredDevice device,
) async {
  // Web does not support CoreBluetooth-style BLE GATT operations.
  return null;
}

