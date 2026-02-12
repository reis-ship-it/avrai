import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/ai2ai/federated_learning_codec.dart';
import 'package:avrai/core/constants/vibe_constants.dart';

void main() {
  test('buildDeltaVectorFromDimensionInsights returns stable 12-dim vector', () {
    final insights = <String, Object>{
      VibeConstants.coreDimensions.first: 0.2,
      'not_a_real_dim': 999,
    };

    final vec = buildDeltaVectorFromDimensionInsights(insights);
    expect(vec, hasLength(VibeConstants.coreDimensions.length));
    expect(vec.first, 0.2);
  });

  test('buildCloudDeltaEntryFromLearningInsightPayload validates schema and clamps', () {
    final payload = <String, dynamic>{
      'schema_version': 1,
      'insight_id': 'ins_1',
      'created_at': DateTime(2026, 1, 1).toUtc().toIso8601String(),
      'ttl_ms': 3600 * 1000,
      'learning_quality': 0.9,
      'insight_type': 'dimensionDiscovery',
      'origin_id': 'node_a',
      'hop': 0,
      'dimension_insights': <String, dynamic>{
        VibeConstants.coreDimensions.first: 9.0, // should clamp
      },
    };

    final entry = buildCloudDeltaEntryFromLearningInsightPayload(payload: payload);
    expect(entry, isNotNull);
    expect(entry!['id'], 'ins_1');
    expect(entry['category'], 'ai2ai_dimensionDiscovery');
    final delta = entry['delta'] as List<dynamic>;
    expect(delta.first, 0.35);
  });
}

