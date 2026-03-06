// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'package:avrai_runtime_os/ai2ai/aipersonality_node.dart';
import 'package:avrai_runtime_os/ai2ai/discovery/discovery_fallback_lane.dart';
import 'package:avrai_runtime_os/ai2ai/discovery/discovery_orchestration_lane.dart';
import 'package:avrai_runtime_os/ai2ai/discovery/physical_layer_discovery_lane.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_runtime_os/ai2ai/services/ai2ai_broadcast_service.dart';
import 'package:avrai_network/avra_network.dart';

class AI2AIDiscoveryExecutionLane {
  const AI2AIDiscoveryExecutionLane._();

  static Future<List<AIPersonalityNode>> discover({
    required DeviceDiscoveryService? deviceDiscovery,
    required bool allowBleSideEffects,
    required Future<void> Function({
      required DiscoveredDevice device,
      required BleGattSession session,
    }) primeOfflineSignalPreKeyBundleInSession,
    required AI2AIBroadcastService? realtimeService,
    required AppLogger logger,
    required String logName,
  }) async {
    final DeviceDiscoveryService? discovery = deviceDiscovery;
    return DiscoveryOrchestrationLane.discover(
      hasPhysicalLayer: discovery != null,
      discoverPhysicalLayer: () async {
        if (discovery == null) return const <AIPersonalityNode>[];
        final List<DiscoveredDevice> devices = discovery.getDiscoveredDevices();
        return PhysicalLayerDiscoveryLane.discoverNodes(
          devices: devices,
          allowBleSideEffects: allowBleSideEffects,
          primeOfflineSignalPreKeyBundleInSession: (device, session) =>
              primeOfflineSignalPreKeyBundleInSession(
            device: device,
            session: session,
          ),
          extractPersonalityData: discovery.extractPersonalityData,
          extractDnaPayload: discovery.extractDnaPayload,
          calculateProximity: discovery.calculateProximity,
          logger: logger,
          logName: logName,
        );
      },
      fallbackDiscovery: () => DiscoveryFallbackLane.fallback(
        realtimeService: realtimeService,
        logger: logger,
        logName: logName,
      ),
      logger: logger,
      logName: logName,
    );
  }
}
