import 'package:avrai/core/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;

class BleReplayHashCache {
  const BleReplayHashCache._();

  static void load({
    required SharedPreferencesCompat prefs,
    required String prefsKey,
    required Map<String, int> seenBleMessageHashes,
    required int nowMs,
  }) {
    if (seenBleMessageHashes.isNotEmpty) return;
    final list = prefs.getStringList(prefsKey) ?? const [];
    for (final item in list) {
      final parts = item.split(':');
      if (parts.length != 2) continue;
      final hash = parts[0];
      final expiresAt = int.tryParse(parts[1]) ?? 0;
      if (hash.isEmpty || expiresAt <= nowMs) continue;
      seenBleMessageHashes[hash] = expiresAt;
    }
  }

  static Future<int> persistIfNeeded({
    required SharedPreferencesCompat prefs,
    required String prefsKey,
    required Map<String, int> seenBleMessageHashes,
    required int nowMs,
    required int lastPersistMs,
    int persistIntervalMs = 15 * 1000,
    int maxEntries = 200,
  }) async {
    if (nowMs - lastPersistMs < persistIntervalMs) return lastPersistMs;

    seenBleMessageHashes.removeWhere((_, exp) => exp <= nowMs);
    final entries = seenBleMessageHashes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final capped = entries.take(maxEntries).toList();
    final list = capped.map((e) => '${e.key}:${e.value}').toList();
    await prefs.setStringList(prefsKey, list);
    return nowMs;
  }
}
