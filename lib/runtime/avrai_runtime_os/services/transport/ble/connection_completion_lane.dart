// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'package:avrai/runtime/avrai_runtime_os/services/transport/ble/connection_lifecycle_lane.dart';
import 'package:avrai/core/models/quantum/connection_metrics.dart';
import 'package:avrai/core/services/infrastructure/logger.dart';

class ConnectionCompletionLane {
  const ConnectionCompletionLane._();

  static Future<ConnectionMetrics?> complete({
    required ConnectionMetrics connection,
    required String? reason,
    required AppLogger logger,
    required String logName,
  }) async {
    try {
      logger.info(
        'Completing AI2AI connection: ${connection.connectionId}',
        tag: logName,
      );

      final completedConnection =
          ConnectionLifecycleLane.complete(connection, reason: reason);

      final summary = completedConnection.getSummary();
      logger.info('Connection completed: $summary', tag: logName);
      return completedConnection;
    } catch (e) {
      logger.error('Error completing connection', error: e, tag: logName);
      return null;
    }
  }
}
