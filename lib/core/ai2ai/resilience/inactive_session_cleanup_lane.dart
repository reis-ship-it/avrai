import 'package:avrai/core/ai2ai/aipersonality_node.dart';
import 'package:avrai/core/ai2ai/resilience/active_connection_metrics_index.dart';
import 'package:avrai/core/crypto/signal/signal_session_manager.dart';
import 'package:avrai/core/models/quantum/connection_metrics.dart';
import 'package:avrai/core/services/infrastructure/logger.dart';

class InactiveSessionCleanupLane {
  const InactiveSessionCleanupLane._();

  static Future<void> run({
    required SignalSessionManager sessionManager,
    required Iterable<ConnectionMetrics> activeConnections,
    required Iterable<AIPersonalityNode> discoveredNodes,
    Duration inactivityThreshold = const Duration(hours: 24),
    required AppLogger logger,
    required String logName,
  }) async {
    try {
      final now = DateTime.now();
      final metricsByAgentId =
          ActiveConnectionMetricsIndex.byAgentId(activeConnections);

      final sessionsToMaintain =
          sessionManager.getSessionsToMaintain(metricsByAgentId).toSet();

      final activeAgentIds =
          activeConnections.map((c) => c.remoteAISignature).toSet();
      final discoveredAgentIds = discoveredNodes
          .map((n) => n.nodeId)
          .where((id) => id.isNotEmpty)
          .toSet();

      final allAgentIds = {...activeAgentIds, ...discoveredAgentIds};
      for (final agentId in allAgentIds) {
        final hasActiveConnection = activeConnections.any(
          (c) =>
              c.remoteAISignature == agentId &&
              (c.status == ConnectionStatus.active ||
                  c.status == ConnectionStatus.learning),
        );
        if (hasActiveConnection) continue;

        if (sessionsToMaintain.contains(agentId)) {
          logger.debug(
            'Skipping cleanup for maintained session (high-quality): $agentId',
            tag: logName,
          );
          continue;
        }

        final session = await sessionManager.getSession(agentId);
        if (session == null) continue;

        final lastActivity = session.lastUsedAt ?? session.createdAt;
        final timeSinceActivity = now.difference(lastActivity);
        if (timeSinceActivity < inactivityThreshold) continue;

        logger.info(
          'Cleaning up inactive session for agent $agentId: inactive for ${timeSinceActivity.inHours}h',
          tag: logName,
        );
        await sessionManager.deleteSession(agentId);
      }
    } catch (e, st) {
      logger.error(
        'Error cleaning up inactive sessions: $e',
        tag: logName,
        error: e,
        stackTrace: st,
      );
    }
  }
}
