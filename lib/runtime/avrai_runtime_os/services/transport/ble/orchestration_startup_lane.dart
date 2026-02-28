// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'dart:async';

import 'package:avrai/core/ai2ai/aipersonality_node.dart';
import 'package:avrai/core/crypto/signal/signal_key_manager.dart';
import 'package:avrai/core/models/quantum/connection_metrics.dart';
import 'package:avrai/runtime/avrai_runtime_os/services/transport/ble/connection_maintenance_loop.dart';
import 'package:avrai/runtime/avrai_runtime_os/services/transport/ble/discovery_loop.dart';
import 'package:avrai/runtime/avrai_runtime_os/services/transport/ble/prekey_bundle_rotation_lane.dart';
import 'package:avrai/runtime/avrai_runtime_os/services/transport/ble/session_lifecycle_orchestration_flow_lane.dart';
import 'package:avrai/core/services/infrastructure/logger.dart';

class OrchestrationStartupLane {
  const OrchestrationStartupLane._();

  static Future<Timer> startDiscovery<T>({
    required Future<List<T>> Function() discoverNearby,
    required AppLogger logger,
    required String logName,
  }) async {
    logger.info('Starting AI2AI discovery process', tag: logName);

    final Timer timer = DiscoveryLoop.start(
      discoverNearby: discoverNearby,
      onError: (error) => logger.error(
        'Error in periodic discovery',
        error: error,
        tag: logName,
      ),
    );

    await discoverNearby();
    return timer;
  }

  static Timer startConnectionMaintenance({
    required Future<void> Function() manageActiveConnections,
    required Future<void> Function() manageSessionLifecycle,
    required Future<void> Function() managePreKeyBundleRotation,
    required AppLogger logger,
    required String logName,
  }) {
    logger.info('Starting connection maintenance process', tag: logName);

    return ConnectionMaintenanceLoop.start(
      manageActiveConnections: manageActiveConnections,
      manageSessionLifecycle: manageSessionLifecycle,
      managePreKeyBundleRotation: managePreKeyBundleRotation,
      onError: (error) => logger.error(
        'Error in connection maintenance',
        error: error,
        tag: logName,
      ),
    );
  }

  static Timer startConnectionMaintenanceForOrchestrator({
    required Future<void> Function() manageActiveConnections,
    required Map<String, ConnectionMetrics> activeConnectionsById,
    required Iterable<AIPersonalityNode> discoveredNodes,
    required Future<ConnectionMetrics?> Function(
      ConnectionMetrics connection, {
      String? reason,
    })
    completeConnection,
    required Map<String, double> previousQualityScores,
    required double qualityChangeThreshold,
    required SignalKeyManager? signalKeyManager,
    required AppLogger logger,
    required String logName,
  }) {
    return startConnectionMaintenance(
      manageActiveConnections: manageActiveConnections,
      manageSessionLifecycle: () async {
        await SessionLifecycleOrchestrationFlowLane.run(
          activeConnectionsById: activeConnectionsById,
          discoveredNodes: discoveredNodes,
          completeConnection: completeConnection,
          previousQualityScores: previousQualityScores,
          qualityChangeThreshold: qualityChangeThreshold,
          logger: logger,
          logName: logName,
        );
      },
      managePreKeyBundleRotation: () async {
        await PrekeyBundleRotationLane.run(
          signalKeyManager: signalKeyManager,
          activeConnections: activeConnectionsById.values,
          logger: logger,
          logName: logName,
        );
      },
      logger: logger,
      logName: logName,
    );
  }
}
