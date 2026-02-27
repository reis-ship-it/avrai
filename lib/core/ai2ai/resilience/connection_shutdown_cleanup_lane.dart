import 'package:avrai/core/ai2ai/aipersonality_node.dart';
import 'package:avrai/core/models/quantum/connection_metrics.dart';
import 'package:avrai/core/models/user/user_vibe.dart';
import 'package:avrai/core/services/infrastructure/logger.dart';

class ConnectionShutdownCleanupLane {
  const ConnectionShutdownCleanupLane._();

  static Future<void> run({
    required Map<String, ConnectionMetrics> activeConnections,
    required Map<String, DateTime> connectionCooldowns,
    required List<Object> pendingConnections,
    required Map<String, UserVibe> nearbyVibes,
    required Map<String, AIPersonalityNode> discoveredNodes,
    required Future<ConnectionMetrics?> Function(
      ConnectionMetrics connection, {
      String? reason,
    }) completeConnection,
    required void Function() onResetNetworkDensity,
    required void Function() onClearCurrentUser,
    required AppLogger logger,
    required String logName,
  }) async {
    final List<String> activeConnectionIds = activeConnections.keys.toList();
    for (final String connectionId in activeConnectionIds) {
      final ConnectionMetrics? connection = activeConnections[connectionId];
      if (connection == null) continue;
      await completeConnection(connection, reason: 'system_shutdown');
    }

    activeConnections.clear();
    connectionCooldowns.clear();
    pendingConnections.clear();
    nearbyVibes.clear();
    discoveredNodes.clear();
    onResetNetworkDensity();
    onClearCurrentUser();

    logger.info('Shutdown completed', tag: logName);
  }
}
