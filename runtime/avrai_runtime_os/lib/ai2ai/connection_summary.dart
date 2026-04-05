// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'package:avrai_core/models/quantum/connection_metrics.dart';

class ConnectionSummary {
  final String connectionId;
  final Duration duration;
  final double compatibility;
  final double learningEffectiveness;
  final double aiPleasureScore;
  final String qualityRating;
  final ConnectionStatus status;
  final int interactionCount;
  final int dimensionsEvolved;
  final List<String> canonicalReasonCodes;
  final double? peerConfidence;
  final double? peerFreshnessHours;
  final List<String> sharedGeographicLevels;
  final List<String> sharedScopedContextIds;
  final String? peerWhySummary;

  ConnectionSummary({
    required this.connectionId,
    required this.duration,
    required this.compatibility,
    required this.learningEffectiveness,
    required this.aiPleasureScore,
    required this.qualityRating,
    required this.status,
    required this.interactionCount,
    required this.dimensionsEvolved,
    this.canonicalReasonCodes = const <String>[],
    this.peerConfidence,
    this.peerFreshnessHours,
    this.sharedGeographicLevels = const <String>[],
    this.sharedScopedContextIds = const <String>[],
    this.peerWhySummary,
  });

  Map<String, dynamic> toJson() {
    return {
      'connection_id': connectionId.substring(0, 8),
      'duration_seconds': duration.inSeconds,
      'compatibility': (compatibility * 100).round(),
      'learning_effectiveness': (learningEffectiveness * 100).round(),
      'ai_pleasure_score': (aiPleasureScore * 100).round(),
      'quality_rating': qualityRating,
      'status': status.toString().split('.').last,
      'interaction_count': interactionCount,
      'dimensions_evolved': dimensionsEvolved,
      if (canonicalReasonCodes.isNotEmpty)
        'canonical_reason_codes': canonicalReasonCodes,
      if (peerConfidence != null) 'peer_confidence': peerConfidence,
      if (peerFreshnessHours != null)
        'peer_freshness_hours': peerFreshnessHours,
      if (sharedGeographicLevels.isNotEmpty)
        'shared_geographic_levels': sharedGeographicLevels,
      if (sharedScopedContextIds.isNotEmpty)
        'shared_scoped_context_ids': sharedScopedContextIds,
      if (peerWhySummary != null) 'peer_why_summary': peerWhySummary,
    };
  }
}
