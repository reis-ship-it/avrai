import 'package:avrai/core/ai2ai/aipersonality_node.dart';
import 'package:avrai/core/ai2ai/discovery/discovery_fallback_lane.dart';
import 'package:avrai/core/ai2ai/discovery/discovery_orchestration_lane.dart';
import 'package:avrai/core/ai2ai/discovery/physical_layer_discovery_lane.dart';
import 'package:avrai/core/services/infrastructure/logger.dart';
import 'package:avrai_ai/services/ai2ai_broadcast_service.dart';
import 'package:avrai_network/avra_network.dart';

class AI2AIDiscoveryExecutionLane {
  const AI2AIDiscoveryExecutionLane._();

  static Future<List<AIPersonalityNode>> discover({
    required DeviceDiscoveryService? deviceDiscovery,
    required bool allowBleSideEffects,
    required Future<void> Function({
      required DiscoveredDevice device,
      required BleGattSession session,
    })
    primeOfflineSignalPreKeyBundleInSession,
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
