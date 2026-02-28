import 'package:avrai/core/ai2ai/resilience/orchestration_bootstrap_lane.dart';
import 'package:avrai/core/ai2ai/resilience/orchestration_initialization_lane.dart';
import 'package:avrai/core/services/infrastructure/logger.dart';
import 'package:avrai_core/models/personality_profile.dart';

class OrchestrationInitFlowLane {
  const OrchestrationInitFlowLane._();

  static Future<void> run({
    required bool isInitialized,
    required String userId,
    required PersonalityProfile personality,
    required bool Function() readDiscoveryEnabled,
    required void Function() onAlreadyInitialized,
    required void Function() onDiscoveryDisabled,
    required void Function(String userId, PersonalityProfile personality)
        setCurrentContext,
    required Future<String> Function() prepareIdentityAndCaches,
    required void Function(String bleNodeId) onInitStarted,
    required void Function() onMarkInitialized,
    required void Function() onInitCompleted,
    required void Function(Object error) onInitFailed,
    required bool allowBleSideEffects,
    required bool isWeb,
    required bool isAndroid,
    required Future<bool> Function() startBleForegroundService,
    required void Function() onBleForegroundServiceStarted,
    required void Function() onBleForegroundServiceFailed,
    required Future<void> Function() publishPrekeyPayload,
    required Future<bool> Function()? initializeRealtime,
    required Future<void> Function() setupRealtimeListeners,
    required Future<void> Function() startAdvertising,
    required Future<void> Function() startDiscovery,
    required Future<void> Function() startAi2AiDiscovery,
    required void Function() startBleInboxProcessing,
    required void Function() startFederatedCloudSync,
    required Future<void> Function() startConnectionMaintenance,
    required AppLogger logger,
    required String logName,
  }) async {
    await OrchestrationInitializationLane.run(
      isInitialized: isInitialized,
      userId: userId,
      personality: personality,
      readDiscoveryEnabled: readDiscoveryEnabled,
      onAlreadyInitialized: onAlreadyInitialized,
      onDiscoveryDisabled: onDiscoveryDisabled,
      prepareIdentityAndCaches: prepareIdentityAndCaches,
      setCurrentContext: setCurrentContext,
      onInitStarted: onInitStarted,
      bootstrap: () {
        return OrchestrationBootstrapLane.bootstrap(
          allowBleSideEffects: allowBleSideEffects,
          isWeb: isWeb,
          isAndroid: isAndroid,
          startBleForegroundService: startBleForegroundService,
          onBleForegroundServiceStarted: onBleForegroundServiceStarted,
          onBleForegroundServiceFailed: onBleForegroundServiceFailed,
          publishPrekeyPayload: publishPrekeyPayload,
          initializeRealtime: initializeRealtime,
          setupRealtimeListeners: setupRealtimeListeners,
          startAdvertising: startAdvertising,
          startDiscovery: startDiscovery,
          startAi2AiDiscovery: startAi2AiDiscovery,
          startBleInboxProcessing: startBleInboxProcessing,
          startFederatedCloudSync: startFederatedCloudSync,
          startConnectionMaintenance: startConnectionMaintenance,
          logger: logger,
          logName: logName,
        );
      },
      onMarkInitialized: onMarkInitialized,
      onInitCompleted: onInitCompleted,
      onInitFailed: onInitFailed,
      logger: logger,
      logName: logName,
    );
  }
}
