import 'dart:convert';

import 'package:avrai/core/constants/vibe_constants.dart';

/// Helpers for representing AI2AI learning insights as federated-learning deltas.
///
/// These are pure functions so they can be unit-tested without BLE/Supabase.
Map<String, dynamic>? buildCloudDeltaEntryFromLearningInsightPayload({
  required Map<String, dynamic> payload,
}) {
  final schemaVersion = payload['schema_version'] as int?;
  if (schemaVersion != 1) return null;

  final insightId = payload['insight_id'] as String?;
  if (insightId == null || insightId.isEmpty) return null;

  final createdAtStr = payload['created_at'] as String?;
  final createdAt = createdAtStr != null ? DateTime.tryParse(createdAtStr) : null;
  if (createdAt == null) return null;

  final learningQuality = (payload['learning_quality'] as num?)?.toDouble() ?? 0.0;
  final insightType = payload['insight_type'] as String? ?? 'unknown';

  final insightsRaw = payload['dimension_insights'];
  if (insightsRaw is! Map) return null;

  final deltaVector = buildDeltaVectorFromDimensionInsights(insightsRaw);

  // Store as an EmbeddingDelta-shaped object for the federated-sync edge function.
  return <String, dynamic>{
    'id': insightId,
    'category': 'ai2ai_$insightType',
    'delta': deltaVector,
    'timestamp': createdAt.toUtc().toIso8601String(),
    'metadata': <String, dynamic>{
      'learning_quality': learningQuality,
      'origin_id': payload['origin_id'] as String?,
      'hop': (payload['hop'] as num?)?.toInt(),
    },
  };
}

List<double> buildDeltaVectorFromDimensionInsights(Map insightsRaw) {
  final deltaVector = <double>[];
  for (final d in VibeConstants.coreDimensions) {
    final v = insightsRaw[d];
    if (v is num) {
      deltaVector.add(v.toDouble().clamp(-0.35, 0.35));
    } else {
      deltaVector.add(0.0);
    }
  }
  return deltaVector;
}

/// Fast check used for queue dedupe.
bool cloudDeltaEntryContainsId({
  required String jsonString,
  required String id,
}) {
  // Prefer parsing, but do a cheap substring check first to avoid JSON decode
  // overhead for large queues.
  if (!jsonString.contains('"id":"$id"')) return false;
  try {
    final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
    return decoded['id'] == id;
  } catch (_) {
    return false;
  }
}

