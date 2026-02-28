import 'package:avrai/core/ai2ai/room_coherence_engine.dart';
import 'package:avrai/core/ai2ai/telemetry/hot_discovery_enqueue_lane.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai/runtime/avrai_runtime_os/services/transport/ble/battery_adaptive_ble_scheduler.dart';
import 'package:avrai/runtime/avrai_runtime_os/services/transport/ble/event_mode_scan_window_orchestration_lane.dart';
import 'package:avrai_network/avra_network.dart';

class EventModeHotPathOrchestrationLane {
  const EventModeHotPathOrchestrationLane._();

  static void onDevicesDiscoveredHotPath({
    required bool allowBleSideEffects,
    required SharedPreferencesCompat prefs,
    required bool eventModeEnabled,
    required bool lastAdvertisedEventModeEnabled,
    required Future<void> Function({
      required bool eventModeEnabled,
      required bool connectOk,
      required bool brownout,
    })
    maybeUpdateEventModeBroadcastFlags,
    required List<DiscoveredDevice> devices,
    required int hotRssiThresholdDbm,
    required Duration hotDeviceCooldown,
    required Map<String, int> lastHotProcessedAtMsByDeviceId,
    required Set<String> hotQueuedDeviceIds,
    required List<DiscoveredDevice> hotQueue,
    required Map<String, int> hotEnqueuedAtMsByDeviceId,
    required String? currentUserId,
    required bool hasCurrentPersonality,
    required Map<String, int> familiarityByNodeTag,
    required RoomCoherenceEngine roomCoherenceEngine,
    required String localBleNodeId,
    required int eventInitiatorEligibilityPct,
    required String localNodeTagKey,
    required Map<String, int> eventModeLastDeepSyncAtMsByNodeTag,
    required int eventPerNodeDeepSyncCooldownMs,
    required int eventEpochMs,
    required int eventCheckInWindowMs,
    required int eventMaxDeepSyncPerEvent,
    required int eventModeDeepSyncCount,
    required int eventModeLastEpochAttempted,
    required bool eventModeCheckInRunning,
    required void Function(int value) setEventModeDeepSyncCount,
    required void Function(int value) setEventModeLastEpochAttempted,
    required void Function(bool value) setEventModeCheckInRunning,
    required Future<void> Function(DiscoveredDevice device) processHotDevice,
    required BatteryAdaptiveBleScheduler? batteryScheduler,
    required bool hotWorkerRunning,
    required void Function() startHotWorker,
  }) {
    HotDiscoveryEnqueueLane.handle(
      allowBleSideEffects: allowBleSideEffects,
      prefs: prefs,
      eventModeEnabled: eventModeEnabled,
      lastAdvertisedEventModeEnabled: lastAdvertisedEventModeEnabled,
      maybeUpdateEventModeBroadcastFlags: maybeUpdateEventModeBroadcastFlags,
      handleEventModeScanWindow: (scanDevices) async {
        final state = await EventModeScanWindowOrchestrationLane
            .handleForOrchestrator(
          allowBleSideEffects: allowBleSideEffects,
          currentUserId: currentUserId,
          hasCurrentPersonality: hasCurrentPersonality,
          lastAdvertisedEventModeEnabled: lastAdvertisedEventModeEnabled,
          devices: scanDevices,
          hotRssiThresholdDbm: hotRssiThresholdDbm,
          familiarityByNodeTag: familiarityByNodeTag,
          batteryScheduler: batteryScheduler,
          roomCoherenceEngine: roomCoherenceEngine,
          maybeUpdateEventModeBroadcastFlags: maybeUpdateEventModeBroadcastFlags,
          localBleNodeId: localBleNodeId,
          eventInitiatorEligibilityPct: eventInitiatorEligibilityPct,
          localNodeTagKey: localNodeTagKey,
          eventModeLastDeepSyncAtMsByNodeTag: eventModeLastDeepSyncAtMsByNodeTag,
          eventPerNodeDeepSyncCooldownMs: eventPerNodeDeepSyncCooldownMs,
          eventEpochMs: eventEpochMs,
          eventCheckInWindowMs: eventCheckInWindowMs,
          eventMaxDeepSyncPerEvent: eventMaxDeepSyncPerEvent,
          eventModeDeepSyncCount: eventModeDeepSyncCount,
          eventModeLastEpochAttempted: eventModeLastEpochAttempted,
          eventModeCheckInRunning: eventModeCheckInRunning,
          processHotDevice: processHotDevice,
        );
        setEventModeDeepSyncCount(state.deepSyncCount);
        setEventModeLastEpochAttempted(state.lastEpochAttempted);
        setEventModeCheckInRunning(state.checkInRunning);
      },
      devices: devices,
      hotRssiThresholdDbm: hotRssiThresholdDbm,
      hotDeviceCooldown: hotDeviceCooldown,
      lastHotProcessedAtMsByDeviceId: lastHotProcessedAtMsByDeviceId,
      hotQueuedDeviceIds: hotQueuedDeviceIds,
      hotQueue: hotQueue,
      hotEnqueuedAtMsByDeviceId: hotEnqueuedAtMsByDeviceId,
      batteryScheduler: batteryScheduler,
      hotWorkerRunning: hotWorkerRunning,
      startHotWorker: startHotWorker,
    );
  }
}
