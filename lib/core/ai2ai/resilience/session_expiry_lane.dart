import 'package:avrai/core/ai2ai/resilience/active_connection_metrics_index.dart';
import 'package:avrai/core/crypto/signal/signal_session_manager.dart';
import 'package:avrai/core/models/quantum/connection_metrics.dart';
import 'package:avrai/core/services/infrastructure/logger.dart';

class SessionExpiryLane {
  const SessionExpiryLane._();

  static Future<void> run({
    required SignalSessionManager sessionManager,
    required Map<String, ConnectionMetrics> activeConnectionsById,
    required Future<void> Function(
      ConnectionMetrics connection, {
      String reason,
    }) completeConnection,
    required AppLogger logger,
    required String logName,
  }) async {
    try {
      final metricsByAgentId = ActiveConnectionMetricsIndex.byAgentId(
        activeConnectionsById.values,
      );

      final sessionsToClose = sessionManager.getSessionsToClose(metricsByAgentId);
      for (final agentId in sessionsToClose) {
        final connection = activeConnectionsById.values.firstWhere(
          (c) => c.remoteAISignature == agentId,
          orElse: () => throw StateError('Connection not found for agent'),
        );

        logger.info(
          'Expiring session for agent $agentId due to poor connection quality',
          tag: logName,
        );

        await sessionManager.deleteSession(agentId);
        activeConnectionsById.remove(connection.connectionId);
        await completeConnection(
          connection,
          reason: 'poor_connection_quality',
        );
      }
    } catch (e, st) {
      logger.error(
        'Error expiring sessions based on quality: $e',
        tag: logName,
        error: e,
        stackTrace: st,
      );
    }
  }
}
