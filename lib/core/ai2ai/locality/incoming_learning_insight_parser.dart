import 'package:avrai/core/ai2ai/adaptive_mesh_hop_policy.dart' as mesh_policy;
import 'package:avrai/core/ai2ai/adaptive_mesh_networking_service.dart';
import 'package:avrai/core/constants/vibe_constants.dart';

class IncomingLearningInsightParseResult {
  const IncomingLearningInsightParseResult({
    required this.insightId,
    required this.expiresAtMs,
    required this.learningQuality,
    required this.originId,
    required this.hop,
    required this.deltas,
  });

  final String insightId;
  final int expiresAtMs;
  final double learningQuality;
  final String originId;
  final int hop;
  final Map<String, double> deltas;
}

class IncomingLearningInsightParser {
  const IncomingLearningInsightParser._();

  static IncomingLearningInsightParseResult? parse({
    required Map<String, dynamic> payload,
    required String senderId,
    required AdaptiveMeshNetworkingService? adaptiveMeshService,
    required int nowMs,
  }) {
    final schemaVersion = payload['schema_version'] as int?;
    if (schemaVersion != 1) return null;

    final insightId = payload['insight_id'] as String?;
    if (insightId == null || insightId.isEmpty) return null;

    final createdAtStr = payload['created_at'] as String?;
    final ttlMs = (payload['ttl_ms'] as num?)?.toInt() ?? 0;
    if (createdAtStr == null || ttlMs <= 0 || ttlMs > 6 * 60 * 60 * 1000) {
      return null;
    }

    final createdAt = DateTime.tryParse(createdAtStr);
    if (createdAt == null) return null;
    final expiresAtMs = createdAt.millisecondsSinceEpoch + ttlMs;
    if (expiresAtMs <= nowMs) return null;

    final learningQuality = (payload['learning_quality'] as num?)?.toDouble() ?? 0.0;
    if (learningQuality < 0.65) return null;

    final originId = payload['origin_id'] as String? ?? senderId;
    final hop = (payload['hop'] as num?)?.toInt() ?? 0;
    if (hop < 0) return null;

    if (adaptiveMeshService != null) {
      if (!adaptiveMeshService.shouldForwardMessage(
        currentHop: hop,
        priority: mesh_policy.MessagePriority.medium,
        messageType: mesh_policy.MessageType.learningInsight,
      )) {
        return null;
      }
    } else if (hop > 2) {
      return null;
    }

    final insightsRaw = payload['dimension_insights'];
    if (insightsRaw is! Map) return null;
    final deltas = <String, double>{};
    for (final entry in insightsRaw.entries) {
      final k = entry.key;
      final v = entry.value;
      if (k is! String) continue;
      if (!VibeConstants.coreDimensions.contains(k)) continue;
      if (v is! num) continue;
      final dv = v.toDouble();
      if (dv.abs() > 0.35) continue;
      deltas[k] = dv;
    }
    if (deltas.isEmpty) return null;

    return IncomingLearningInsightParseResult(
      insightId: insightId,
      expiresAtMs: expiresAtMs,
      learningQuality: learningQuality,
      originId: originId,
      hop: hop,
      deltas: deltas,
    );
  }
}
