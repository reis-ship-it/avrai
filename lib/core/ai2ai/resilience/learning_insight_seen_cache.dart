import 'package:avrai/core/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;

class LearningInsightSeenCache {
  const LearningInsightSeenCache._();

  static void load({
    required SharedPreferencesCompat prefs,
    required String prefsKey,
    required Map<String, int> seenLearningInsightIds,
    required int nowMs,
  }) {
    if (seenLearningInsightIds.isNotEmpty) return;
    final list = prefs.getStringList(prefsKey) ?? const [];
    for (final item in list) {
      final parts = item.split(':');
      if (parts.length != 2) continue;
      final id = parts[0];
      final expiresAt = int.tryParse(parts[1]) ?? 0;
      if (id.isEmpty || expiresAt <= nowMs) continue;
      seenLearningInsightIds[id] = expiresAt;
    }
  }

  static Future<int> persistIfNeeded({
    required SharedPreferencesCompat prefs,
    required String prefsKey,
    required Map<String, int> seenLearningInsightIds,
    required int nowMs,
    required int lastPersistMs,
    int persistIntervalMs = 15 * 1000,
    int maxEntries = 200,
  }) async {
    if (nowMs - lastPersistMs < persistIntervalMs) return lastPersistMs;

    seenLearningInsightIds.removeWhere((_, exp) => exp <= nowMs);
    final entries = seenLearningInsightIds.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final capped = entries.take(maxEntries).toList();
    final list = capped.map((e) => '${e.key}:${e.value}').toList();
    await prefs.setStringList(prefsKey, list);
    return nowMs;
  }
}
