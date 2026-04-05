import 'package:avrai_runtime_os/services/transport/ble/active_connection_management_lane.dart';
import 'package:avrai_runtime_os/services/transport/ble/connection_lifecycle_lane.dart';
import 'package:avrai_core/models/quantum/connection_metrics.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';

class ConnectionManagementOrchestrationLane {
  const ConnectionManagementOrchestrationLane._();

  static void schedule({
    required ConnectionMetrics connection,
    required AppLogger logger,
    required String logName,
  }) {
    logger.debug(
      'Scheduled management for connection: ${connection.connectionId}',
      tag: logName,
    );
  }

  static void applyLearningUpdate({
    required Map<String, ConnectionMetrics> activeConnections,
    required ConnectionMetrics connection,
  }) {
    activeConnections[connection.connectionId] =
        ConnectionLifecycleLane.maybeApplyLearningUpdate(connection);
  }

  static void applyHealthUpdate({
    required Map<String, ConnectionMetrics> activeConnections,
    required ConnectionMetrics connection,
    required double aiPleasureScore,
  }) {
    activeConnections[connection.connectionId] =
        ConnectionLifecycleLane.applyHealthUpdate(
      connection: connection,
      aiPleasureScore: aiPleasureScore,
    );
  }

  static Future<void> runActiveManagement({
    required Map<String, ConnectionMetrics> activeConnections,
    required Future<ConnectionMetrics?> Function(ConnectionMetrics connection)
        completeConnection,
    required Future<double> Function(ConnectionMetrics connection)
        calculateAIPleasureScore,
    required AppLogger logger,
    required String logName,
  }) {
    return ActiveConnectionManagementLane.run(
      activeConnections: activeConnections,
      completeConnection: completeConnection,
      updateConnectionLearning: (connection) async {
        applyLearningUpdate(
          activeConnections: activeConnections,
          connection: connection,
        );
      },
      monitorConnectionHealth: (connection) async {
        final currentPleasure = await calculateAIPleasureScore(connection);
        applyHealthUpdate(
          activeConnections: activeConnections,
          connection: connection,
          aiPleasureScore: currentPleasure,
        );
      },
      logger: logger,
      logName: logName,
    );
  }
}
