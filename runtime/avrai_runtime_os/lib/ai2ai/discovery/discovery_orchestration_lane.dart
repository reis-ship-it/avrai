// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'package:avrai_runtime_os/ai2ai/aipersonality_node.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';

class DiscoveryOrchestrationLane {
  const DiscoveryOrchestrationLane._();

  static Future<List<AIPersonalityNode>> discover({
    required bool hasPhysicalLayer,
    required Future<List<AIPersonalityNode>> Function() discoverPhysicalLayer,
    required Future<List<AIPersonalityNode>> Function() fallbackDiscovery,
    required AppLogger logger,
    required String logName,
  }) async {
    if (hasPhysicalLayer) {
      try {
        logger.info('Using physical layer device discovery', tag: logName);
        final nodes = await discoverPhysicalLayer();
        if (nodes.isNotEmpty) {
          logger.info(
            'Discovered ${nodes.length} AI personalities via physical layer',
            tag: logName,
          );
          return nodes;
        }
      } catch (e) {
        logger.error('Error in physical layer discovery: $e', tag: logName);
      }
    }

    return fallbackDiscovery();
  }
}
