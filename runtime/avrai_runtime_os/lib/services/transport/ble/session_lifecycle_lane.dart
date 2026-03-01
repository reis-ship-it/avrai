// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'package:avrai_runtime_os/crypto/signal/signal_session_manager.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:get_it/get_it.dart';

class SessionLifecycleLane {
  const SessionLifecycleLane._();

  static Future<void> run({
    required AppLogger logger,
    required String logName,
    required Future<void> Function(SignalSessionManager sessionManager)
        expireSessionsBasedOnQuality,
    required Future<void> Function(SignalSessionManager sessionManager)
        cleanupInactiveSessions,
    required Future<void> Function(SignalSessionManager sessionManager)
        renewActiveSessions,
    required Future<void> Function(SignalSessionManager sessionManager)
        rotateKeysBasedOnQualityChanges,
  }) async {
    try {
      final sl = GetIt.instance;
      if (!sl.isRegistered<SignalSessionManager>()) {
        return;
      }

      final sessionManager = sl<SignalSessionManager>();

      logger.debug('Managing Signal Protocol session lifecycle', tag: logName);

      await expireSessionsBasedOnQuality(sessionManager);
      await cleanupInactiveSessions(sessionManager);
      await renewActiveSessions(sessionManager);
      await rotateKeysBasedOnQualityChanges(sessionManager);
    } catch (e, st) {
      logger.error(
        'Error managing session lifecycle: $e',
        tag: logName,
        error: e,
        stackTrace: st,
      );
    }
  }
}
