import 'package:avrai/core/ai2ai/resilience/ble_replay_hash_cache.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;

class BleSeenHashesPersistenceLane {
  const BleSeenHashesPersistenceLane._();

  static void load({
    required SharedPreferencesCompat prefs,
    required String prefsKey,
    required Map<String, int> seenBleMessageHashes,
  }) {
    BleReplayHashCache.load(
      prefs: prefs,
      prefsKey: prefsKey,
      seenBleMessageHashes: seenBleMessageHashes,
      nowMs: DateTime.now().millisecondsSinceEpoch,
    );
  }

  static Future<int> persistIfNeeded({
    required SharedPreferencesCompat prefs,
    required String prefsKey,
    required Map<String, int> seenBleMessageHashes,
    required int lastPersistMs,
  }) async {
    final int nowMs = DateTime.now().millisecondsSinceEpoch;
    return BleReplayHashCache.persistIfNeeded(
      prefs: prefs,
      prefsKey: prefsKey,
      seenBleMessageHashes: seenBleMessageHashes,
      nowMs: nowMs,
      lastPersistMs: lastPersistMs,
    );
  }
}
