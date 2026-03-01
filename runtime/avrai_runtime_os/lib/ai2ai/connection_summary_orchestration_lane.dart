// MIGRATION_SHIM: LEGACY_PATH_GUARD TEMPORARY UNTIL TARGET-ROOT MIGRATION
import 'package:avrai_runtime_os/ai2ai/connection_summary.dart';
import 'package:avrai_core/models/quantum/connection_metrics.dart';

class ConnectionSummaryOrchestrationLane {
  const ConnectionSummaryOrchestrationLane._();

  static List<ConnectionSummary> fromActiveConnections(
    Iterable<ConnectionMetrics> activeConnections,
  ) {
    return activeConnections.map((connection) {
      return ConnectionSummary(
        connectionId: connection.connectionId,
        duration: connection.connectionDuration,
        compatibility: connection.currentCompatibility,
        learningEffectiveness: connection.learningEffectiveness,
        aiPleasureScore: connection.aiPleasureScore,
        qualityRating: connection.qualityRating,
        status: connection.status,
        interactionCount: connection.interactionHistory.length,
        dimensionsEvolved: connection.dimensionEvolution.keys.length,
      );
    }).toList();
  }
}
