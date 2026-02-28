// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'package:avrai/runtime/avrai_runtime_os/services/transport/ble/learning_insight_seen_cache.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;

class LearningInsightSeenIdsPersistenceLane {
  const LearningInsightSeenIdsPersistenceLane._();

  static void load({
    required SharedPreferencesCompat prefs,
    required String prefsKey,
    required Map<String, int> seenLearningInsightIds,
  }) {
    LearningInsightSeenCache.load(
      prefs: prefs,
      prefsKey: prefsKey,
      seenLearningInsightIds: seenLearningInsightIds,
      nowMs: DateTime.now().millisecondsSinceEpoch,
    );
  }

  static Future<int> persistIfNeeded({
    required SharedPreferencesCompat prefs,
    required String prefsKey,
    required Map<String, int> seenLearningInsightIds,
    required int lastPersistMs,
  }) async {
    final int nowMs = DateTime.now().millisecondsSinceEpoch;
    return LearningInsightSeenCache.persistIfNeeded(
      prefs: prefs,
      prefsKey: prefsKey,
      seenLearningInsightIds: seenLearningInsightIds,
      nowMs: nowMs,
      lastPersistMs: lastPersistMs,
    );
  }
}
