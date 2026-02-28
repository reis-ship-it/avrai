// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'package:avrai/core/models/quantum/connection_metrics.dart';

class ConnectionLifecycleLane {
  const ConnectionLifecycleLane._();

  static ConnectionMetrics complete(
    ConnectionMetrics connection, {
    String? reason,
  }) {
    return connection.complete(
      finalStatus: ConnectionStatus.completed,
      completionReason: reason ?? 'natural_completion',
    );
  }

  static ConnectionMetrics maybeApplyLearningUpdate(ConnectionMetrics connection) {
    if (connection.interactionHistory.length >= 10) return connection;

    final learningInteraction = InteractionEvent.success(
      type: InteractionType.learningInsight,
      data: <String, dynamic>{
        'insight_type': 'dimension_evolution',
        'learning_quality': 0.8,
      },
    );

    return connection.updateDuringInteraction(
      newInteraction: learningInteraction,
      learningEffectiveness: 0.7,
      additionalOutcomes: <String, dynamic>{
        'successful_exchanges': 1,
        'insights_gained': 1,
      },
    );
  }

  static ConnectionMetrics applyHealthUpdate({
    required ConnectionMetrics connection,
    required double aiPleasureScore,
  }) {
    return connection.updateDuringInteraction(
      aiPleasureScore: aiPleasureScore,
    );
  }
}
