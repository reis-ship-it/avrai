// MIGRATION_SHIM: LEGACY_PATH_GUARD TEMPORARY UNTIL TARGET-ROOT MIGRATION
import 'package:avrai_runtime_os/ai/vibe_analysis_engine.dart';
import 'package:avrai_runtime_os/ai2ai/aipersonality_node.dart';
import 'package:avrai_runtime_os/ai2ai/telemetry/hot_device_processing_lane.dart';
import 'package:avrai_runtime_os/ai2ai/telemetry/hot_latency_window.dart';
import 'package:avrai_runtime_os/services/transport/ble/hot_path_metrics_orchestration_lane.dart';
import 'package:avrai_runtime_os/ai2ai/telemetry/hot_queue_worker_lane.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_network/avra_network.dart';

class HotPathOrchestrationFlowLane {
  const HotPathOrchestrationFlowLane._();

  static Future<void> runWorker({
    required List<DiscoveredDevice> hotQueue,
    required Set<String> hotQueuedDeviceIds,
    required Map<String, int> lastHotProcessedAtMsByDeviceId,
    required Map<String, int> hotEnqueuedAtMsByDeviceId,
    required void Function(int value) onQueueWaitMs,
    required SharedPreferencesCompat prefs,
    required Future<void> Function(DiscoveredDevice device) processHotDevice,
    required void Function() onFinally,
  }) async {
    try {
      await HotQueueWorkerLane.run(
        hotQueue: hotQueue,
        hotQueuedDeviceIds: hotQueuedDeviceIds,
        lastHotProcessedAtMsByDeviceId: lastHotProcessedAtMsByDeviceId,
        hotEnqueuedAtMsByDeviceId: hotEnqueuedAtMsByDeviceId,
        onQueueWaitMs: onQueueWaitMs,
        prefs: prefs,
        processHotDevice: processHotDevice,
      );
    } finally {
      onFinally();
    }
  }

  static Future<void> processHotDevice({
    required DiscoveredDevice device,
    required String? currentUserId,
    required PersonalityProfile? currentPersonality,
    required UserVibeAnalyzer vibeAnalyzer,
    required bool allowBleSideEffects,
    required DeviceDiscoveryService? deviceDiscovery,
    required Future<void> Function({
      required DiscoveredDevice device,
      required BleGattSession session,
    }) primeOfflineSignalPreKeyBundleInSession,
    required bool Function(VibeCompatibilityResult compatibility)
        isConnectionWorthy,
    required void Function(List<AIPersonalityNode> nodes) updateDiscoveredNodes,
    required Future<void> Function({
      required String userId,
      required PersonalityProfile localPersonality,
      required List<AIPersonalityNode> nodes,
      required Map<String, VibeCompatibilityResult> compatibilityByNodeId,
    }) maybeApplyPassiveAi2AiLearning,
    Future<void> Function({
      required DiscoveredDevice device,
      required BleGattSession? session,
      required VibeCompatibilityResult compatibility,
    })? maybeSwapPheromones,
    required AppLogger logger,
    required String logName,
    required void Function(int value) onSessionOpenMs,
    required void Function(int value) onVibeReadMs,
    required void Function(int value) onCompatMs,
    required void Function(int value) onTotalMs,
    required void Function() maybeLogHotMetrics,
  }) {
    return HotDeviceProcessingLane.process(
      device: device,
      currentUserId: currentUserId,
      currentPersonality: currentPersonality,
      vibeAnalyzer: vibeAnalyzer,
      allowBleSideEffects: allowBleSideEffects,
      deviceDiscovery: deviceDiscovery,
      primeOfflineSignalPreKeyBundleInSession:
          primeOfflineSignalPreKeyBundleInSession,
      isConnectionWorthy: isConnectionWorthy,
      updateDiscoveredNodes: updateDiscoveredNodes,
      maybeApplyPassiveAi2AiLearning: maybeApplyPassiveAi2AiLearning,
      maybeSwapPheromones: maybeSwapPheromones,
      logger: logger,
      logName: logName,
      onSessionOpenMs: onSessionOpenMs,
      onVibeReadMs: onVibeReadMs,
      onCompatMs: onCompatMs,
      onTotalMs: onTotalMs,
      maybeLogHotMetrics: maybeLogHotMetrics,
    );
  }

  static Future<void> runWorkerForOrchestrator({
    required List<DiscoveredDevice> hotQueue,
    required Set<String> hotQueuedDeviceIds,
    required Map<String, int> lastHotProcessedAtMsByDeviceId,
    required Map<String, int> hotEnqueuedAtMsByDeviceId,
    required SharedPreferencesCompat prefs,
    required Future<void> Function(DiscoveredDevice device) processHotDevice,
    required void Function() onWorkerStopped,
  }) {
    return runWorker(
      hotQueue: hotQueue,
      hotQueuedDeviceIds: hotQueuedDeviceIds,
      lastHotProcessedAtMsByDeviceId: lastHotProcessedAtMsByDeviceId,
      hotEnqueuedAtMsByDeviceId: hotEnqueuedAtMsByDeviceId,
      onQueueWaitMs: (_) {},
      prefs: prefs,
      processHotDevice: processHotDevice,
      onFinally: onWorkerStopped,
    );
  }

  static Future<void> runWorkerForOrchestratorWithMetrics({
    required List<DiscoveredDevice> hotQueue,
    required Set<String> hotQueuedDeviceIds,
    required Map<String, int> lastHotProcessedAtMsByDeviceId,
    required Map<String, int> hotEnqueuedAtMsByDeviceId,
    required SharedPreferencesCompat prefs,
    required void Function(int value) onQueueWaitMs,
    required Future<void> Function(DiscoveredDevice device) processHotDevice,
    required void Function() onWorkerStopped,
  }) {
    return runWorker(
      hotQueue: hotQueue,
      hotQueuedDeviceIds: hotQueuedDeviceIds,
      lastHotProcessedAtMsByDeviceId: lastHotProcessedAtMsByDeviceId,
      hotEnqueuedAtMsByDeviceId: hotEnqueuedAtMsByDeviceId,
      onQueueWaitMs: onQueueWaitMs,
      prefs: prefs,
      processHotDevice: processHotDevice,
      onFinally: onWorkerStopped,
    );
  }

  static Future<void> processHotDeviceForOrchestrator({
    required DiscoveredDevice device,
    required String? currentUserId,
    required PersonalityProfile? currentPersonality,
    required UserVibeAnalyzer vibeAnalyzer,
    required bool allowBleSideEffects,
    required DeviceDiscoveryService? deviceDiscovery,
    required Future<void> Function({
      required DiscoveredDevice device,
      required BleGattSession session,
    }) primeOfflineSignalPreKeyBundleInSession,
    required bool Function(VibeCompatibilityResult compatibility)
        isConnectionWorthy,
    required void Function(List<AIPersonalityNode> nodes) updateDiscoveredNodes,
    required Future<void> Function({
      required String userId,
      required PersonalityProfile localPersonality,
      required List<AIPersonalityNode> nodes,
      required Map<String, VibeCompatibilityResult> compatibilityByNodeId,
    }) maybeApplyPassiveAi2AiLearning,
    Future<void> Function({
      required DiscoveredDevice device,
      required BleGattSession? session,
      required VibeCompatibilityResult compatibility,
    })? maybeSwapPheromones,
    required HotLatencyWindow hotSessionOpenMs,
    required HotLatencyWindow hotVibeReadMs,
    required HotLatencyWindow hotCompatMs,
    required HotLatencyWindow hotTotalMs,
    required HotLatencyWindow hotQueueWaitMs,
    required int lastHotMetricsLogAtMs,
    required Duration hotMetricsLogInterval,
    required void Function(int value) setLastHotMetricsLogAtMs,
    required AppLogger logger,
    required String logName,
  }) {
    return processHotDevice(
      device: device,
      currentUserId: currentUserId,
      currentPersonality: currentPersonality,
      vibeAnalyzer: vibeAnalyzer,
      allowBleSideEffects: allowBleSideEffects,
      deviceDiscovery: deviceDiscovery,
      primeOfflineSignalPreKeyBundleInSession:
          primeOfflineSignalPreKeyBundleInSession,
      isConnectionWorthy: isConnectionWorthy,
      updateDiscoveredNodes: updateDiscoveredNodes,
      maybeApplyPassiveAi2AiLearning: maybeApplyPassiveAi2AiLearning,
      maybeSwapPheromones: maybeSwapPheromones,
      logger: logger,
      logName: logName,
      onSessionOpenMs: hotSessionOpenMs.add,
      onVibeReadMs: hotVibeReadMs.add,
      onCompatMs: hotCompatMs.add,
      onTotalMs: hotTotalMs.add,
      maybeLogHotMetrics: () {
        setLastHotMetricsLogAtMs(
          HotPathMetricsOrchestrationLane.maybeLog(
            lastLogAtMs: lastHotMetricsLogAtMs,
            minInterval: hotMetricsLogInterval,
            queueWait: hotQueueWaitMs,
            sessionOpen: hotSessionOpenMs,
            vibeRead: hotVibeReadMs,
            compatibility: hotCompatMs,
            total: hotTotalMs,
            logger: logger,
            logName: logName,
          ),
        );
      },
    );
  }
}
