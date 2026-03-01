// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'dart:convert';

import 'package:avrai_runtime_os/ai2ai/embedding_delta_collector.dart';
import 'package:avrai_runtime_os/ml/onnx_dimension_scorer.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';

class FederatedCloudSyncLane {
  const FederatedCloudSyncLane._();

  static Future<int> run({
    required bool federatedLearningParticipationEnabled,
    required int lastFederatedCloudSyncAttemptMs,
    required SharedPreferencesCompat prefs,
    required String prefsKeyQueue,
    required AppLogger logger,
    required String logName,
    int minAttemptIntervalMs = 30 * 1000,
  }) async {
    if (!federatedLearningParticipationEnabled) {
      return lastFederatedCloudSyncAttemptMs;
    }

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (nowMs - lastFederatedCloudSyncAttemptMs < minAttemptIntervalMs) {
      return lastFederatedCloudSyncAttemptMs;
    }

    final supabase = SupabaseService();
    if (!supabase.isAvailable || supabase.currentUser == null) {
      return nowMs;
    }

    final list = prefs.getStringList(prefsKeyQueue) ?? const [];
    if (list.isEmpty) return nowMs;

    final batch = <Map<String, dynamic>>[];
    final remaining = <String>[];
    for (final s in list) {
      if (batch.length >= 50) {
        remaining.add(s);
        continue;
      }
      try {
        batch.add(jsonDecode(s) as Map<String, dynamic>);
      } catch (_) {
        // Drop malformed entries.
      }
    }

    if (batch.isEmpty) {
      await prefs.setStringList(prefsKeyQueue, remaining);
      return nowMs;
    }

    try {
      final res = await supabase.client.functions.invoke(
        'federated-sync',
        body: <String, dynamic>{
          'schema_version': 1,
          'source': 'ai2ai_ble',
          'deltas': batch,
        },
      );

      final status = res.status;
      if (status != 200) {
        logger.debug('Federated sync failed: HTTP $status', tag: logName);
        return nowMs;
      }

      try {
        final decoded =
            res.data is String ? jsonDecode(res.data as String) : res.data;
        if (decoded is Map) {
          final global = decoded['global_average_deltas'];
          if (global is Map) {
            final priors = <EmbeddingDelta>[];
            for (final entry in global.entries) {
              final category = entry.key?.toString() ?? 'general';
              final value = entry.value;
              if (value is! List) continue;
              final vec = value
                  .whereType<num>()
                  .map((n) => n.toDouble().clamp(-0.35, 0.35))
                  .toList();
              if (vec.isEmpty) continue;
              priors.add(EmbeddingDelta(
                delta: vec,
                timestamp: DateTime.now(),
                category: category,
              ));
            }
            if (priors.isNotEmpty) {
              await OnnxDimensionScorer().updateWithDeltas(priors);
            }
          }
        }
      } catch (e) {
        logger.debug(
          'Federated priors apply failed (non-blocking): $e',
          tag: logName,
        );
      }

      await prefs.setStringList(prefsKeyQueue, remaining);
    } catch (e) {
      logger.debug('Federated sync exception: $e', tag: logName);
    }

    return nowMs;
  }
}
