// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'package:avrai/runtime/avrai_runtime_os/services/transport/ble/battery_adaptive_ble_scheduler.dart';
import 'package:avrai/core/ai2ai/discovery/event_mode_candidate.dart';
import 'package:avrai/core/ai2ai/room_coherence_engine.dart';
import 'package:avrai/runtime/avrai_runtime_os/services/transport/ble/event_mode_initiator_policy.dart';
import 'package:avrai/runtime/avrai_runtime_os/services/transport/ble/event_mode_scan_window_lane.dart';
import 'package:avrai/runtime/avrai_runtime_os/services/transport/ble/event_mode_target_selector.dart';
import 'package:avrai_network/avra_network.dart';

class EventModeScanWindowOrchestrationLane {
  const EventModeScanWindowOrchestrationLane._();

  static Future<EventModeScanWindowState> handleForOrchestrator({
    required bool allowBleSideEffects,
    required String? currentUserId,
    required bool hasCurrentPersonality,
    required bool lastAdvertisedEventModeEnabled,
    required List<DiscoveredDevice> devices,
    required int hotRssiThresholdDbm,
    required Map<String, int> familiarityByNodeTag,
    required BatteryAdaptiveBleScheduler? batteryScheduler,
    required RoomCoherenceEngine roomCoherenceEngine,
    required Future<void> Function({
      required bool eventModeEnabled,
      required bool connectOk,
      required bool brownout,
    })
    maybeUpdateEventModeBroadcastFlags,
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
    required Future<void> Function(DiscoveredDevice device) processHotDevice,
  }) async {
    var nextDeepSyncCount = eventModeDeepSyncCount;
    var nextLastEpochAttempted = eventModeLastEpochAttempted;
    var nextCheckInRunning = eventModeCheckInRunning;

    await handle(
      allowBleSideEffects: allowBleSideEffects,
      currentUserId: currentUserId,
      hasCurrentPersonality: hasCurrentPersonality,
      lastAdvertisedEventModeEnabled: lastAdvertisedEventModeEnabled,
      devices: devices,
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
      eventModeDeepSyncCount: nextDeepSyncCount,
      eventModeLastEpochAttempted: nextLastEpochAttempted,
      eventModeCheckInRunning: nextCheckInRunning,
      onEventModeReset: () {
        nextDeepSyncCount = 0;
        eventModeLastDeepSyncAtMsByNodeTag.clear();
        nextLastEpochAttempted = -1;
        nextCheckInRunning = false;
      },
      setEventModeLastEpochAttempted: (epoch) {
        nextLastEpochAttempted = epoch;
      },
      setEventModeCheckInRunning: (running) {
        nextCheckInRunning = running;
      },
      incrementEventModeDeepSyncCount: () {
        nextDeepSyncCount += 1;
      },
      processHotDevice: processHotDevice,
    );

    return EventModeScanWindowState(
      deepSyncCount: nextDeepSyncCount,
      lastEpochAttempted: nextLastEpochAttempted,
      checkInRunning: nextCheckInRunning,
    );
  }

  static Future<void> handle({
    required bool allowBleSideEffects,
    required String? currentUserId,
    required bool hasCurrentPersonality,
    required bool lastAdvertisedEventModeEnabled,
    required List<DiscoveredDevice> devices,
    required int hotRssiThresholdDbm,
    required Map<String, int> familiarityByNodeTag,
    required BatteryAdaptiveBleScheduler? batteryScheduler,
    required RoomCoherenceEngine roomCoherenceEngine,
    required Future<void> Function({
      required bool eventModeEnabled,
      required bool connectOk,
      required bool brownout,
    })
    maybeUpdateEventModeBroadcastFlags,
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
    required void Function() onEventModeReset,
    required void Function(int epoch) setEventModeLastEpochAttempted,
    required void Function(bool running) setEventModeCheckInRunning,
    required void Function() incrementEventModeDeepSyncCount,
    required Future<void> Function(DiscoveredDevice device) processHotDevice,
  }) async {
    await EventModeScanWindowLane.handle(
      allowBleSideEffects: allowBleSideEffects,
      currentUserId: currentUserId,
      hasCurrentPersonality: hasCurrentPersonality,
      lastAdvertisedEventModeEnabled: lastAdvertisedEventModeEnabled,
      onEventModeReset: onEventModeReset,
      devices: devices,
      hotRssiThresholdDbm: hotRssiThresholdDbm,
      familiarityByNodeTag: familiarityByNodeTag,
      batteryScheduler: batteryScheduler,
      roomCoherenceEngine: roomCoherenceEngine,
      maybeUpdateEventModeBroadcastFlags: maybeUpdateEventModeBroadcastFlags,
      eventModeMayInitiate: ({required int epoch}) {
        return EventModeInitiatorPolicy.mayInitiate(
          localBleNodeId: localBleNodeId,
          epoch: epoch,
          eligibilityPercent: eventInitiatorEligibilityPct,
        );
      },
      pickEventModeTarget: ({
        required List<EventModeCandidate> candidates,
        required int nowMs,
        required int epoch,
      }) {
        return EventModeTargetSelector.select(
          candidates: candidates,
          nowMs: nowMs,
          epoch: epoch,
          localNodeTagKey: localNodeTagKey,
          lastDeepSyncAtMsByNodeTag: eventModeLastDeepSyncAtMsByNodeTag,
          familiarityByNodeTag: familiarityByNodeTag,
          perNodeDeepSyncCooldownMs: eventPerNodeDeepSyncCooldownMs,
        );
      },
      eventEpochMs: eventEpochMs,
      eventCheckInWindowMs: eventCheckInWindowMs,
      eventMaxDeepSyncPerEvent: eventMaxDeepSyncPerEvent,
      eventModeDeepSyncCount: eventModeDeepSyncCount,
      eventModeLastEpochAttempted: eventModeLastEpochAttempted,
      eventModeCheckInRunning: eventModeCheckInRunning,
      setEventModeLastEpochAttempted: setEventModeLastEpochAttempted,
      setEventModeCheckInRunning: setEventModeCheckInRunning,
      incrementEventModeDeepSyncCount: incrementEventModeDeepSyncCount,
      eventModeLastDeepSyncAtMsByNodeTag: eventModeLastDeepSyncAtMsByNodeTag,
      waitInitiatorJitter: ({required int epoch}) async {
        final jitterMs = EventModeInitiatorPolicy.jitterMs(
          localBleNodeId: localBleNodeId,
          epoch: epoch,
        );
        if (jitterMs > 0) {
          await Future<void>.delayed(Duration(milliseconds: jitterMs));
        }
      },
      processHotDevice: processHotDevice,
    );
  }
}

class EventModeScanWindowState {
  const EventModeScanWindowState({
    required this.deepSyncCount,
    required this.lastEpochAttempted,
    required this.checkInRunning,
  });

  final int deepSyncCount;
  final int lastEpochAttempted;
  final bool checkInRunning;
}
