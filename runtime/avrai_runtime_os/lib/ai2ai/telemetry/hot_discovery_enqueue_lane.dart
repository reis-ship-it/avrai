// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'dart:async';

import 'package:avrai_runtime_os/services/transport/ble/battery_adaptive_ble_scheduler.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_network/avra_network.dart';

class HotDiscoveryEnqueueLane {
  const HotDiscoveryEnqueueLane._();

  static void handle({
    required bool allowBleSideEffects,
    required SharedPreferencesCompat prefs,
    required bool eventModeEnabled,
    required bool lastAdvertisedEventModeEnabled,
    required Future<void> Function({
      required bool eventModeEnabled,
      required bool connectOk,
      required bool brownout,
    }) maybeUpdateEventModeBroadcastFlags,
    required Future<void> Function(List<DiscoveredDevice> devices)
        handleEventModeScanWindow,
    required List<DiscoveredDevice> devices,
    required int hotRssiThresholdDbm,
    required Duration hotDeviceCooldown,
    required Map<String, int> lastHotProcessedAtMsByDeviceId,
    required Set<String> hotQueuedDeviceIds,
    required List<DiscoveredDevice> hotQueue,
    required Map<String, int> hotEnqueuedAtMsByDeviceId,
    required BatteryAdaptiveBleScheduler? batteryScheduler,
    required bool hotWorkerRunning,
    required void Function() startHotWorker,
  }) {
    if (!allowBleSideEffects) return;

    final bool discoveryEnabled = prefs.getBool('discovery_enabled') ?? false;
    if (!discoveryEnabled) return;

    if (!eventModeEnabled && lastAdvertisedEventModeEnabled) {
      unawaited(maybeUpdateEventModeBroadcastFlags(
        eventModeEnabled: false,
        connectOk: false,
        brownout: false,
      ));
    }

    if (eventModeEnabled) {
      unawaited(handleEventModeScanWindow(devices));
      return;
    }

    final int nowMs = DateTime.now().millisecondsSinceEpoch;
    bool sawHotCandidate = false;
    for (final DiscoveredDevice device in devices) {
      if (device.type != DeviceType.bluetooth) continue;

      final int? rssi = device.signalStrength;
      if (rssi == null || rssi < hotRssiThresholdDbm) continue;
      sawHotCandidate = true;

      final int? lastMs = lastHotProcessedAtMsByDeviceId[device.deviceId];
      if (lastMs != null && nowMs - lastMs < hotDeviceCooldown.inMilliseconds) {
        continue;
      }

      if (hotQueuedDeviceIds.add(device.deviceId)) {
        hotQueue.add(device);
        hotEnqueuedAtMsByDeviceId[device.deviceId] = nowMs;
      }
    }

    if (sawHotCandidate) {
      batteryScheduler?.notifyHotOpportunity();
    }
    batteryScheduler?.notifyDiscoverySample(
      discoveredCount: devices.length,
      sawHotCandidate: sawHotCandidate,
    );

    if (hotWorkerRunning || hotQueue.isEmpty) return;
    startHotWorker();
  }
}
