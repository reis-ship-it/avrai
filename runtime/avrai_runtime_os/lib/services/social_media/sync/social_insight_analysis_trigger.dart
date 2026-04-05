// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'dart:async';

import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_runtime_os/services/social_media/social_media_insight_service.dart';
import 'package:get_it/get_it.dart';

class SocialInsightAnalysisTrigger {
  const SocialInsightAnalysisTrigger._();

  static void trigger({
    required AppLogger logger,
    required String logName,
    required String agentId,
    required String userId,
  }) {
    unawaited(_triggerAsync(
      logger: logger,
      logName: logName,
      agentId: agentId,
      userId: userId,
    ));
  }

  static Future<void> _triggerAsync({
    required AppLogger logger,
    required String logName,
    required String agentId,
    required String userId,
  }) async {
    try {
      if (!GetIt.instance.isRegistered<SocialMediaInsightService>()) {
        logger.debug('Insight service not registered, skipping analysis',
            tag: logName);
        return;
      }

      final insightService = GetIt.instance<SocialMediaInsightService>();

      logger.info(
          '🔍 Triggering automatic insight analysis after connection...',
          tag: logName);
      await insightService.analyzeAllPlatforms(
        agentId: agentId,
        userId: userId,
      );
      logger.info('✅ Automatic insight analysis completed', tag: logName);
    } catch (e) {
      logger.warn('⚠️ Automatic insight analysis failed (non-blocking): $e',
          tag: logName);
    }
  }
}
