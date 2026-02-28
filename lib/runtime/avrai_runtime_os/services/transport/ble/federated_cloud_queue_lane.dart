// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'dart:convert';

import 'package:avrai/core/ai2ai/federated_learning_codec.dart';
import 'package:avrai/core/services/infrastructure/logger.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;

class FederatedCloudQueueLane {
  const FederatedCloudQueueLane._();

  static Future<void> enqueueFromLearningInsightPayload({
    required SharedPreferencesCompat prefs,
    required String prefsKeyQueue,
    required Map<String, dynamic> payload,
    required AppLogger logger,
    required String logName,
    int maxEntries = 200,
  }) async {
    try {
      final entry =
          buildCloudDeltaEntryFromLearningInsightPayload(payload: payload);
      if (entry == null) return;
      final insightId = entry['id'] as String?;
      if (insightId == null || insightId.isEmpty) return;

      final existing = prefs.getStringList(prefsKeyQueue) ?? const [];
      final next = <String>[];
      var seenId = false;
      for (final s in existing) {
        if (cloudDeltaEntryContainsId(jsonString: s, id: insightId)) {
          seenId = true;
        }
        next.add(s);
      }
      if (!seenId) {
        next.add(jsonEncode(entry));
      }

      final capped =
          next.length <= maxEntries ? next : next.sublist(next.length - maxEntries);
      await prefs.setStringList(prefsKeyQueue, capped);
    } catch (e) {
      logger.debug(
        'Failed to enqueue federated delta for cloud: $e',
        tag: logName,
      );
    }
  }
}
