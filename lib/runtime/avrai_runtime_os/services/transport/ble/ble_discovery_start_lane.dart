import 'package:avrai/runtime/avrai_runtime_os/services/transport/ble/adaptive_mesh_networking_service.dart';
import 'package:avrai/runtime/avrai_runtime_os/services/transport/ble/battery_adaptive_ble_scheduler.dart';
import 'package:avrai/core/services/infrastructure/logger.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_network/avra_network.dart';

class BleDiscoveryStartResult {
  final BatteryAdaptiveBleScheduler? batteryScheduler;
  final AdaptiveMeshNetworkingService? adaptiveMeshService;

  const BleDiscoveryStartResult({
    required this.batteryScheduler,
    required this.adaptiveMeshService,
  });
}

class BleDiscoveryStartLane {
  const BleDiscoveryStartLane._();

  static Future<BleDiscoveryStartResult> startIfAllowed({
    required bool allowBleSideEffects,
    required DeviceDiscoveryService? deviceDiscovery,
    required SharedPreferencesCompat prefs,
    required Duration hotScanWindow,
    required Duration hotDeviceTimeout,
    required void Function(List<DiscoveredDevice> devices)
        onDevicesDiscoveredHotPath,
    required BatteryAdaptiveBleScheduler? existingBatteryScheduler,
    required AdaptiveMeshNetworkingService? existingAdaptiveMeshService,
    required AppLogger logger,
    required String logName,
  }) async {
    if (!allowBleSideEffects || deviceDiscovery == null) {
      return BleDiscoveryStartResult(
        batteryScheduler: existingBatteryScheduler,
        adaptiveMeshService: existingAdaptiveMeshService,
      );
    }

    deviceDiscovery.onDevicesDiscovered(onDevicesDiscoveredHotPath);
    await deviceDiscovery.startDiscovery(
      scanInterval: Duration.zero,
      scanWindow: hotScanWindow,
      deviceTimeout: hotDeviceTimeout,
    );
    logger.info('Device discovery started', tag: logName);

    await Future<void>.delayed(const Duration(milliseconds: 300));

    await existingBatteryScheduler?.stop();
    final batteryScheduler = BatteryAdaptiveBleScheduler(
      discovery: deviceDiscovery,
      prefs: prefs,
    );
    await batteryScheduler.start();

    await Future<void>.delayed(const Duration(milliseconds: 200));

    await existingAdaptiveMeshService?.stop();
    final adaptiveMeshService = AdaptiveMeshNetworkingService(
      batteryScheduler: batteryScheduler,
      discovery: deviceDiscovery,
    );
    await adaptiveMeshService.start();

    return BleDiscoveryStartResult(
      batteryScheduler: batteryScheduler,
      adaptiveMeshService: adaptiveMeshService,
    );
  }
}
