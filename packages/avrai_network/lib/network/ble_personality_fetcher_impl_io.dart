import 'dart:convert';
import 'dart:developer' as developer;

import 'package:avrai_network/network/ble_gatt_stream_fetcher.dart';
import 'package:avrai_network/network/device_discovery.dart';
import 'package:avrai_network/network/models/anonymized_vibe_data.dart';
import 'package:avrai_network/network/personality_data_codec.dart';

const _logName = 'BlePersonalityFetcher';

Future<AnonymizedVibeData?> fetchPersonalityDataOverBle(
  DiscoveredDevice device,
) async {
  try {
    final bytes = await fetchBleGattStreamPayload(device: device, streamId: 0);
    if (bytes == null || bytes.isEmpty) return null;

    final jsonString = utf8.decode(bytes);
    final vibe = PersonalityDataCodec.decodeFromJson(jsonString);
    return vibe;
  } catch (e, st) {
    developer.log('Error fetching BLE personality payload',
        name: _logName, error: e, stackTrace: st);
    return null;
  }
}

