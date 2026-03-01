// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_core/models/personality_profile.dart';

class OrchestrationInitializationLane {
  const OrchestrationInitializationLane._();

  static Future<void> run({
    required bool isInitialized,
    required String userId,
    required PersonalityProfile personality,
    required bool Function() readDiscoveryEnabled,
    required void Function() onAlreadyInitialized,
    required void Function() onDiscoveryDisabled,
    required Future<String> Function() prepareIdentityAndCaches,
    required void Function(String userId, PersonalityProfile personality)
        setCurrentContext,
    required void Function(String bleNodeId) onInitStarted,
    required Future<void> Function() bootstrap,
    required void Function() onMarkInitialized,
    required void Function() onInitCompleted,
    required void Function(Object error) onInitFailed,
    required AppLogger logger,
    required String logName,
  }) async {
    if (isInitialized) {
      onAlreadyInitialized();
      return;
    }

    try {
      logger.info('Initializing orchestration for user: $userId', tag: logName);

      if (!readDiscoveryEnabled()) {
        logger.info(
          'AI2AI discovery is disabled by user setting; skipping orchestration init',
          tag: logName,
        );
        onDiscoveryDisabled();
        return;
      }

      setCurrentContext(userId, personality);
      final String bleNodeId = await prepareIdentityAndCaches();
      onInitStarted(bleNodeId);

      await bootstrap();

      onMarkInitialized();
      onInitCompleted();
      logger.info('Orchestration initialized successfully', tag: logName);
    } catch (e) {
      logger.error('Error initializing AI2AI orchestration',
          error: e, tag: logName);
      onInitFailed(e);
      rethrow;
    }
  }
}
