import 'package:avrai/core/models/quantum/connection_metrics.dart';

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
    };
  }
}
