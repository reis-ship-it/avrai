// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'dart:async';

import 'package:avrai_runtime_os/services/transport/ble/adaptive_mesh_networking_service.dart';
import 'package:avrai_runtime_os/services/transport/ble/battery_adaptive_ble_scheduler.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:avrai_network/avra_network.dart';

class OrchestrationShutdownLane {
  const OrchestrationShutdownLane._();

  static Future<void> stopRuntime({
    required Timer? discoveryTimer,
    required Timer? connectionMaintenanceTimer,
    required Timer? bleInboxPoller,
    required Timer? federatedCloudSyncTimer,
    required StreamSubscription<List<ConnectivityResult>>?
        federatedCloudConnectivitySub,
    required BatteryAdaptiveBleScheduler? batteryScheduler,
    required AdaptiveMeshNetworkingService? adaptiveMeshService,
    required DeviceDiscoveryService? deviceDiscovery,
    required PersonalityAdvertisingService? advertisingService,
    required bool allowBleSideEffects,
    required bool isWeb,
    required bool isAndroid,
    required Future<void> Function() stopBleForegroundService,
    required AppLogger logger,
    required String logName,
  }) async {
    discoveryTimer?.cancel();
    connectionMaintenanceTimer?.cancel();
    bleInboxPoller?.cancel();
    federatedCloudSyncTimer?.cancel();
    await federatedCloudConnectivitySub?.cancel();
    await batteryScheduler?.stop();
    await adaptiveMeshService?.stop();

    try {
      deviceDiscovery?.stopDiscovery();
    } catch (e) {
      logger.debug('Error stopping device discovery: $e', tag: logName);
    }
    try {
      await advertisingService?.stopAdvertising();
    } catch (e) {
      logger.debug('Error stopping personality advertising: $e', tag: logName);
    }

    if (allowBleSideEffects && !isWeb && isAndroid) {
      try {
        await stopBleForegroundService();
      } catch (e) {
        logger.debug('Error stopping Android BLE foreground service: $e',
            tag: logName);
      }
    }
  }
}
