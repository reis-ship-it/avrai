// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'package:avrai_runtime_os/services/transport/ble/active_connection_metrics_index.dart';
import 'package:avrai_runtime_os/crypto/signal/signal_session_manager.dart';
import 'package:avrai_core/models/quantum/connection_metrics.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';

class SessionRenewalLane {
  const SessionRenewalLane._();

  static Future<void> run({
    required SignalSessionManager sessionManager,
    required Iterable<ConnectionMetrics> activeConnections,
    required AppLogger logger,
    required String logName,
  }) async {
    try {
      final metricsByAgentId =
          ActiveConnectionMetricsIndex.byAgentId(activeConnections);

      final sessionsToRenew =
          await sessionManager.getSessionsToRenew(metricsByAgentId);

      for (final agentId in sessionsToRenew) {
        logger.info(
          'Renewing session for agent $agentId based on connection quality',
          tag: logName,
        );

        if (await sessionManager.needsRekeying(agentId)) {
          await sessionManager.markRekeyed(agentId);
          logger.debug(
            'Session renewal triggered for agent $agentId',
            tag: logName,
          );
        }
      }
    } catch (e, st) {
      logger.error(
        'Error renewing active sessions: $e',
        tag: logName,
        error: e,
        stackTrace: st,
      );
    }
  }
}
