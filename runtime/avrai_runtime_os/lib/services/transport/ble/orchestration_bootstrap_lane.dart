// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'dart:async';

import 'package:avrai_runtime_os/services/infrastructure/logger.dart';

class OrchestrationBootstrapLane {
  const OrchestrationBootstrapLane._();

  static Future<void> bootstrap({
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
    if (allowBleSideEffects && !isWeb && isAndroid) {
      final bool started = await startBleForegroundService();
      if (started) {
        logger.info('Android BLE foreground service started', tag: logName);
        onBleForegroundServiceStarted();
      } else {
        logger.warn('Android BLE foreground service failed to start',
            tag: logName);
        onBleForegroundServiceFailed();
      }
    }

    if (allowBleSideEffects) {
      await publishPrekeyPayload();
    }

    if (initializeRealtime != null) {
      final bool realtimeInitialized = await initializeRealtime();
      if (realtimeInitialized) {
        logger.info('Realtime Service initialized', tag: logName);
        await setupRealtimeListeners();
      } else {
        logger.warn('Realtime Service failed to initialize', tag: logName);
      }
    }

    await startAdvertising();
    await startDiscovery();

    if (allowBleSideEffects) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await startAi2AiDiscovery();
      startBleInboxProcessing();
    } else {
      logger.info(
        'BLE side-effects disabled; skipping AI2AI discovery timers',
        tag: logName,
      );
    }

    startFederatedCloudSync();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await startConnectionMaintenance();
  }
}
