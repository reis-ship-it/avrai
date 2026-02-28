// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'package:avrai/runtime/avrai_runtime_os/services/transport/ble/orchestration_bootstrap_lane.dart';
import 'package:avrai/runtime/avrai_runtime_os/services/transport/ble/learning_insight_seen_ids_persistence_lane.dart';
import 'package:avrai/runtime/avrai_runtime_os/services/transport/ble/orchestration_init_ledger_lane.dart';
import 'package:avrai/runtime/avrai_runtime_os/services/transport/ble/orchestration_initialization_lane.dart';
import 'package:avrai/core/services/infrastructure/logger.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai/runtime/avrai_runtime_os/services/transport/ble/ble_node_identity.dart';

class OrchestrationInitFlowLane {
  const OrchestrationInitFlowLane._();

  static Future<void> runForOrchestrator({
    required bool isInitialized,
    required String userId,
    required PersonalityProfile personality,
    required SharedPreferencesCompat prefs,
    required String prefsKeyNodeId,
    required String prefsKeyNodeIdExpiresAtMs,
    required String prefsKeySeenLearningInsightIds,
    required Map<String, int> seenLearningInsightIds,
    required void Function() loadSeenBleHashes,
    required void Function(String userId, PersonalityProfile personality)
        setCurrentContext,
    required void Function(String nodeId, String nodeTagKey) setBleIdentity,
    required bool allowBleSideEffects,
    required bool isTestBinding,
    required bool isWeb,
    required String platform,
    required bool isAndroid,
    required Future<bool> Function() startBleForegroundService,
    required Future<void> Function() publishPrekeyPayload,
    required Future<bool> Function()? initializeRealtime,
    required Future<void> Function() setupRealtimeListeners,
    required Future<void> Function() startAdvertising,
    required Future<void> Function() startDiscovery,
    required Future<void> Function() startAi2AiDiscovery,
    required void Function() startBleInboxProcessing,
    required void Function() startFederatedCloudSync,
    required Future<void> Function() startConnectionMaintenance,
    required void Function() onAlreadyInitialized,
    required void Function() onMarkInitialized,
    required AppLogger logger,
    required String logName,
  }) async {
    await OrchestrationInitializationLane.run(
      isInitialized: isInitialized,
      userId: userId,
      personality: personality,
      readDiscoveryEnabled: () => prefs.getBool('discovery_enabled') ?? false,
      onAlreadyInitialized: onAlreadyInitialized,
      onDiscoveryDisabled: () {
        OrchestrationInitLedgerLane.appendInitSkipped(userId);
      },
      setCurrentContext: setCurrentContext,
      prepareIdentityAndCaches: () async {
        final identity = await BleNodeIdentity.ensure(
          prefs: prefs,
          prefsKeyNodeId: prefsKeyNodeId,
          prefsKeyNodeIdExpiresAtMs: prefsKeyNodeIdExpiresAtMs,
        );
        setBleIdentity(identity.nodeId, identity.nodeTagKey);
        loadSeenBleHashes();
        LearningInsightSeenIdsPersistenceLane.load(
          prefs: prefs,
          prefsKey: prefsKeySeenLearningInsightIds,
          seenLearningInsightIds: seenLearningInsightIds,
        );
        return identity.nodeId;
      },
      onInitStarted: (bleNodeId) {
        OrchestrationInitLedgerLane.appendInitStarted(
          userId: userId,
          bleNodeId: bleNodeId,
          allowBleSideEffects: allowBleSideEffects,
          isTestBinding: isTestBinding,
          isWeb: isWeb,
          platform: platform,
        );
      },
      bootstrap: () async {
        return OrchestrationBootstrapLane.bootstrap(
          allowBleSideEffects: allowBleSideEffects,
          isWeb: isWeb,
          isAndroid: isAndroid,
          startBleForegroundService: startBleForegroundService,
          onBleForegroundServiceStarted: () {
            OrchestrationInitLedgerLane.appendBleForegroundServiceStarted();
          },
          onBleForegroundServiceFailed: () {
            OrchestrationInitLedgerLane.appendBleForegroundServiceFailed();
          },
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
      onInitCompleted: () {
        OrchestrationInitLedgerLane.appendInitCompleted(userId);
      },
      onInitFailed: (error) {
        OrchestrationInitLedgerLane.appendInitFailed(userId, error);
      },
      logger: logger,
      logName: logName,
    );
  }

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
