// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'package:avrai/core/models/quantum/connection_metrics.dart';
import 'package:avrai/core/services/infrastructure/logger.dart';

class ActiveConnectionManagementLane {
  const ActiveConnectionManagementLane._();

  static Future<void> run({
    required Map<String, ConnectionMetrics> activeConnections,
    required Future<ConnectionMetrics?> Function(ConnectionMetrics connection)
        completeConnection,
    required Future<void> Function(ConnectionMetrics connection)
        updateConnectionLearning,
    required Future<void> Function(ConnectionMetrics connection)
        monitorConnectionHealth,
    required AppLogger logger,
    required String logName,
  }) async {
    if (activeConnections.isEmpty) return;

    logger.debug(
      'Managing ${activeConnections.length} active connections',
      tag: logName,
    );

    final List<String> completedConnections = <String>[];

    for (final ConnectionMetrics connection in activeConnections.values) {
      try {
        if (!connection.shouldContinue || connection.hasReachedMaxDuration) {
          final ConnectionMetrics? completedConnection =
              await completeConnection(connection);
          if (completedConnection != null) {
            completedConnections.add(completedConnection.connectionId);
          }
          continue;
        }

        await updateConnectionLearning(connection);
        await monitorConnectionHealth(connection);
      } catch (e) {
        logger.error(
          'Error managing connection ${connection.connectionId}',
          error: e,
          tag: logName,
        );
        completedConnections.add(connection.connectionId);
      }
    }

    for (final String connectionId in completedConnections) {
      activeConnections.remove(connectionId);
    }

    logger.debug(
      'Connection management completed. Active: ${activeConnections.length}',
      tag: logName,
    );
  }
}
