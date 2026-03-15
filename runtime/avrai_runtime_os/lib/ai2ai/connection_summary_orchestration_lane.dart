// MIGRATION_SHIM: LEGACY_PATH_GUARD TEMPORARY UNTIL TARGET-ROOT MIGRATION
import 'package:avrai_runtime_os/ai2ai/connection_summary.dart';
import 'package:avrai_core/models/quantum/connection_metrics.dart';

class ConnectionSummaryOrchestrationLane {
  const ConnectionSummaryOrchestrationLane._();

  static List<ConnectionSummary> fromActiveConnections(
    Iterable<ConnectionMetrics> activeConnections,
  ) {
    return activeConnections.map((connection) {
      final canonicalReasonCodes =
          ((connection.learningOutcomes['canonical_reason_codes'] as List?) ??
                  const <dynamic>[])
              .map((entry) => entry.toString())
              .toList(growable: false);
      final sharedGeographicLevels =
          ((connection.learningOutcomes['shared_geographic_levels'] as List?) ??
                  const <dynamic>[])
              .map((entry) => entry.toString())
              .toList(growable: false);
      final sharedScopedContextIds =
          ((connection.learningOutcomes['shared_scoped_context_ids'] as List?) ??
                  const <dynamic>[])
              .map((entry) => entry.toString())
              .toList(growable: false);
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
        canonicalReasonCodes: canonicalReasonCodes,
        peerConfidence:
            (connection.learningOutcomes['peer_confidence'] as num?)
                ?.toDouble(),
        peerFreshnessHours:
            (connection.learningOutcomes['peer_freshness_hours'] as num?)
                ?.toDouble(),
        sharedGeographicLevels: sharedGeographicLevels,
        sharedScopedContextIds: sharedScopedContextIds,
        peerWhySummary:
            connection.learningOutcomes['peer_why_summary'] as String?,
      );
    }).toList();
  }
}
