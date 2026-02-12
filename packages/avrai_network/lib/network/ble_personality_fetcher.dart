import 'package:avrai_network/network/ble_personality_fetcher_impl_stub.dart'
    if (dart.library.io) 'package:avrai_network/network/ble_personality_fetcher_impl_io.dart'
    if (dart.library.html) 'package:avrai_network/network/ble_personality_fetcher_impl_web.dart'
    as impl;
import 'package:avrai_network/network/device_discovery.dart';
import 'package:avrai_network/network/models/anonymized_vibe_data.dart';

/// Best-effort fetch of a remote device's advertised personality payload via BLE GATT.
///
/// - Returns `null` if the platform/transport doesn't support BLE GATT reads.
/// - Returns `null` if the remote device doesn't expose the SPOTS GATT service.
Future<AnonymizedVibeData?> fetchPersonalityDataOverBle(
  DiscoveredDevice device,
) {
  return impl.fetchPersonalityDataOverBle(device);
}

