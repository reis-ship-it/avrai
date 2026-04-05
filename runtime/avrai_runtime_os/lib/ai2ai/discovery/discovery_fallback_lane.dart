// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'package:avrai_runtime_os/ai2ai/services/ai2ai_broadcast_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_runtime_os/ai2ai/aipersonality_node.dart';

class DiscoveryFallbackLane {
  const DiscoveryFallbackLane._();

  static Future<List<AIPersonalityNode>> fallback({
    required AI2AIBroadcastService? realtimeService,
    required AppLogger logger,
    required String logName,
  }) async {
    if (realtimeService != null) {
      try {
        logger.info('Using realtime discovery', tag: logName);
        return [];
      } catch (e) {
        logger.error('Error in realtime discovery: $e', tag: logName);
      }
    }

    logger.warn('No discovery method available, returning empty list',
        tag: logName);
    return [];
  }
}
