import 'package:avrai/runtime/avrai_runtime_os/services/transport/ble/connection_lifecycle_lane.dart';
import 'package:avrai/core/models/quantum/connection_metrics.dart';
import 'package:avrai/core/services/infrastructure/logger.dart';

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
}
