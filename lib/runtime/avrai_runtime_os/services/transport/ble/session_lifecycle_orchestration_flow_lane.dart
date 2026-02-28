import 'package:avrai/core/ai2ai/aipersonality_node.dart';
import 'package:avrai/runtime/avrai_runtime_os/services/transport/ble/inactive_session_cleanup_lane.dart';
import 'package:avrai/runtime/avrai_runtime_os/services/transport/ble/quality_change_key_rotation_lane.dart';
import 'package:avrai/runtime/avrai_runtime_os/services/transport/ble/session_expiry_lane.dart';
import 'package:avrai/runtime/avrai_runtime_os/services/transport/ble/session_lifecycle_lane.dart';
import 'package:avrai/runtime/avrai_runtime_os/services/transport/ble/session_renewal_lane.dart';
import 'package:avrai/core/models/quantum/connection_metrics.dart';
import 'package:avrai/core/services/infrastructure/logger.dart';

class SessionLifecycleOrchestrationFlowLane {
  const SessionLifecycleOrchestrationFlowLane._();

  static Future<void> run({
    required Map<String, ConnectionMetrics> activeConnectionsById,
    required Iterable<AIPersonalityNode> discoveredNodes,
    required Future<ConnectionMetrics?> Function(
      ConnectionMetrics connection,
      {String? reason}
    ) completeConnection,
    required Map<String, double> previousQualityScores,
    required double qualityChangeThreshold,
    required AppLogger logger,
    required String logName,
  }) async {
    await SessionLifecycleLane.run(
      logger: logger,
      logName: logName,
      expireSessionsBasedOnQuality: (sessionManager) {
        return SessionExpiryLane.run(
          sessionManager: sessionManager,
          activeConnectionsById: activeConnectionsById,
          completeConnection: (connection, {reason = 'session_expired'}) async {
            await completeConnection(
              connection,
              reason: reason,
            );
          },
          logger: logger,
          logName: logName,
        );
      },
      cleanupInactiveSessions: (sessionManager) {
        return InactiveSessionCleanupLane.run(
          sessionManager: sessionManager,
          activeConnections: activeConnectionsById.values,
          discoveredNodes: discoveredNodes,
          logger: logger,
          logName: logName,
        );
      },
      renewActiveSessions: (sessionManager) {
        return SessionRenewalLane.run(
          sessionManager: sessionManager,
          activeConnections: activeConnectionsById.values,
          logger: logger,
          logName: logName,
        );
      },
      rotateKeysBasedOnQualityChanges: (sessionManager) {
        return QualityChangeKeyRotationLane.run(
          sessionManager: sessionManager,
          activeConnections: activeConnectionsById.values,
          previousQualityScores: previousQualityScores,
          qualityChangeThreshold: qualityChangeThreshold,
          logger: logger,
          logName: logName,
        );
      },
    );
  }
}
