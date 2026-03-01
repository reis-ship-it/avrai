// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'package:avrai_network/avra_network.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;

class HotQueueWorkerLane {
  const HotQueueWorkerLane._();

  static Future<void> run({
    required List<DiscoveredDevice> hotQueue,
    required Set<String> hotQueuedDeviceIds,
    required Map<String, int> lastHotProcessedAtMsByDeviceId,
    required Map<String, int> hotEnqueuedAtMsByDeviceId,
    required void Function(int waitMs) onQueueWaitMs,
    required SharedPreferencesCompat prefs,
    required Future<void> Function(DiscoveredDevice device) processHotDevice,
  }) async {
    while (hotQueue.isNotEmpty) {
      final bool discoveryEnabled = prefs.getBool('discovery_enabled') ?? false;
      if (!discoveryEnabled) return;

      final DiscoveredDevice device = hotQueue.removeAt(0);
      hotQueuedDeviceIds.remove(device.deviceId);
      lastHotProcessedAtMsByDeviceId[device.deviceId] =
          DateTime.now().millisecondsSinceEpoch;

      final int? enqMs = hotEnqueuedAtMsByDeviceId.remove(device.deviceId);
      if (enqMs != null) {
        final int waitMs = DateTime.now().millisecondsSinceEpoch - enqMs;
        onQueueWaitMs(waitMs);
      }

      await processHotDevice(device);
    }
  }
}
