// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'package:avrai/core/ai2ai/orchestrator_components.dart';
import 'package:avrai/core/services/infrastructure/logger.dart';

class RealtimeListenersSetupLane {
  const RealtimeListenersSetupLane._();

  static Future<void> setup({
    required RealtimeCoordinator? coordinator,
    required void Function(dynamic message) onPersonality,
    required void Function(dynamic message) onLearning,
    required void Function(dynamic message) onAnonymous,
    required AppLogger logger,
    required String logName,
  }) async {
    if (coordinator == null) return;
    try {
      coordinator.setup(
        onPersonality: onPersonality,
        onLearning: onLearning,
        onAnonymous: onAnonymous,
      );
      logger.debug(
        'Realtime listeners setup with active subscriptions',
        tag: logName,
      );
    } catch (e) {
      logger.warn('Failed to setup realtime listeners: $e', tag: logName);
    }
  }
}
