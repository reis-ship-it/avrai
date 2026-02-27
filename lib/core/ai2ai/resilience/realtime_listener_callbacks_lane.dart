import 'package:avrai/core/ai2ai/orchestrator_components.dart';
import 'package:avrai/core/ai2ai/resilience/realtime_listeners_setup_lane.dart';
import 'package:avrai/core/services/infrastructure/logger.dart';

class RealtimeListenerCallbacksLane {
  const RealtimeListenerCallbacksLane._();

  static Future<void> setup({
    required RealtimeCoordinator? coordinator,
    required void Function(Map<String, dynamic> payload)
        validateNoUnifiedUserInPayload,
    required AppLogger logger,
    required String logName,
  }) async {
    await RealtimeListenersSetupLane.setup(
      coordinator: coordinator,
      onPersonality: (message) {
        logger.debug(
          'Received personality discovery message: ${message.type}, nodeId: ${message.metadata['node_id']}',
          tag: logName,
        );
        if (message.metadata.containsKey('node_id')) {
          // Placeholder for node update from realtime payload.
        }
      },
      onLearning: (message) {
        logger.debug(
          'Received vibe learning message: ${message.type}, dimensions: ${message.metadata['dimension_updates']?.keys.length ?? 0}',
          tag: logName,
        );
        if (message.metadata.containsKey('dimension_updates')) {
          // Placeholder for learning insight ingestion from realtime payload.
        }
      },
      onAnonymous: (message) {
        logger.debug(
          'Received anonymous communication message: ${message.type}, payload_size: ${message.metadata.length}',
          tag: logName,
        );
        validateNoUnifiedUserInPayload(message.metadata);
      },
      logger: logger,
      logName: logName,
    );
  }
}
