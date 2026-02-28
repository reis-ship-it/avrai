// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'dart:async';

import 'package:avrai/runtime/avrai_runtime_os/services/transport/ble/battery_adaptive_ble_scheduler.dart';
import 'package:avrai/core/ai2ai/discovery/event_mode_candidate.dart';
import 'package:avrai/core/ai2ai/room_coherence_engine.dart';
import 'package:avrai/runtime/avrai_runtime_os/services/transport/ble/ble_node_identity.dart';
import 'package:avrai_network/avra_network.dart';

class EventModeScanWindowLane {
  const EventModeScanWindowLane._();

  static Future<void> handle({
    required bool allowBleSideEffects,
    required String? currentUserId,
    required bool hasCurrentPersonality,
    required bool lastAdvertisedEventModeEnabled,
    required void Function() onEventModeReset,
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
    required bool Function({required int epoch}) eventModeMayInitiate,
    required EventModeCandidate? Function({
      required List<EventModeCandidate> candidates,
      required int nowMs,
      required int epoch,
    })
    pickEventModeTarget,
    required int eventEpochMs,
    required int eventCheckInWindowMs,
    required int eventMaxDeepSyncPerEvent,
    required int eventModeDeepSyncCount,
    required int eventModeLastEpochAttempted,
    required bool eventModeCheckInRunning,
    required void Function(int epoch) setEventModeLastEpochAttempted,
    required void Function(bool running) setEventModeCheckInRunning,
    required void Function() incrementEventModeDeepSyncCount,
    required Map<String, int> eventModeLastDeepSyncAtMsByNodeTag,
    required Future<void> Function({required int epoch}) waitInitiatorJitter,
    required Future<void> Function(DiscoveredDevice device) processHotDevice,
  }) async {
    if (!allowBleSideEffects) return;
    if (currentUserId == null || !hasCurrentPersonality) return;

    final DateTime now = DateTime.now();
    final int nowMs = now.millisecondsSinceEpoch;

    if (!lastAdvertisedEventModeEnabled) {
      onEventModeReset();
    }

    final List<RoomCoherenceFrame> frames = <RoomCoherenceFrame>[];
    final List<EventModeCandidate> candidates = <EventModeCandidate>[];

    bool sawHotCandidate = false;
    for (final DiscoveredDevice device in devices) {
      if (device.type != DeviceType.bluetooth) continue;

      final int? rssi = device.signalStrength;
      if (rssi != null && rssi >= hotRssiThresholdDbm) {
        sawHotCandidate = true;
      }

      final dynamic frameMeta = device.metadata['spots_frame_v1'];
      if (frameMeta is! Map) continue;

      final dynamic nodeTagRaw = frameMeta['node_tag'];
      final dynamic dimsQRaw = frameMeta['dims_q'];
      if (nodeTagRaw is! List || dimsQRaw is! List) continue;

      final List<int> nodeTag = nodeTagRaw.map((e) => (e as num).toInt()).toList();
      final List<int> dimsQ = dimsQRaw.map((e) => (e as num).toInt()).toList();
      if (nodeTag.length != 4 || dimsQ.length != 12) continue;

      final String nodeTagKey = BleNodeIdentity.nodeTagKeyFromBytes(nodeTag);
      final bool remoteConnectOk = frameMeta['connect_ok'] == true;

      frames.add(RoomCoherenceFrame(nodeTag: nodeTag, dimsQ: dimsQ));
      candidates.add(EventModeCandidate(
        device: device,
        nodeTagKey: nodeTagKey,
        remoteConnectOk: remoteConnectOk,
      ));

      final int prev = familiarityByNodeTag[nodeTagKey] ?? 0;
      familiarityByNodeTag[nodeTagKey] = (prev + 1).clamp(0, 10000);
    }

    batteryScheduler?.notifyDiscoverySample(
      discoveredCount: devices.length,
      sawHotCandidate: sawHotCandidate,
    );
    if (sawHotCandidate) {
      batteryScheduler?.notifyHotOpportunity();
    }

    final room = roomCoherenceEngine.observeWindowFrames(
      observedAt: now,
      frames: frames,
    );

    final bool brownout = room.densityClass == RoomDensityClass.ambientDense;
    final bool inCheckInWindow = (nowMs % eventEpochMs) < eventCheckInWindowMs;
    final bool connectOk = inCheckInWindow &&
        room.linger &&
        !brownout &&
        eventModeDeepSyncCount < eventMaxDeepSyncPerEvent;

    await maybeUpdateEventModeBroadcastFlags(
      eventModeEnabled: true,
      connectOk: connectOk,
      brownout: brownout,
    );

    if (!connectOk || brownout) return;

    final int epoch = nowMs ~/ eventEpochMs;
    if (eventModeLastEpochAttempted == epoch) return;
    if (eventModeCheckInRunning) return;
    if (!eventModeMayInitiate(epoch: epoch)) return;

    final EventModeCandidate? target = pickEventModeTarget(
      candidates: candidates,
      nowMs: nowMs,
      epoch: epoch,
    );
    if (target == null) return;

    setEventModeLastEpochAttempted(epoch);
    setEventModeCheckInRunning(true);
    try {
      await waitInitiatorJitter(epoch: epoch);

      final int postJitterMs = DateTime.now().millisecondsSinceEpoch;
      if ((postJitterMs % eventEpochMs) >= eventCheckInWindowMs) {
        return;
      }

      await processHotDevice(target.device);
      incrementEventModeDeepSyncCount();
      eventModeLastDeepSyncAtMsByNodeTag[target.nodeTagKey] = postJitterMs;
    } finally {
      setEventModeCheckInRunning(false);
    }
  }
}
