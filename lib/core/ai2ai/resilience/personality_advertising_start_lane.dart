import 'package:avrai/core/ai/privacy_protection.dart';
import 'package:avrai/core/ai/vibe_analysis_engine.dart';
import 'package:avrai/core/services/infrastructure/logger.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_network/avra_network.dart';

class PersonalityAdvertisingStartLane {
  const PersonalityAdvertisingStartLane._();

  static Future<void> startIfAllowed({
    required bool allowBleSideEffects,
    required PersonalityAdvertisingService? advertisingService,
    required UserVibeAnalyzer vibeAnalyzer,
    required String userId,
    required PersonalityProfile personality,
    required String localBleNodeId,
    required bool eventModeEnabled,
    required AppLogger logger,
    required String logName,
  }) async {
    if (!allowBleSideEffects || advertisingService == null) return;

    final vibe = await vibeAnalyzer.compileUserVibe(userId, personality);
    final anonymized = await PrivacyProtection.anonymizeUserVibe(vibe);

    final bool advertisingStarted = await advertisingService.startAdvertising(
      personalityData: anonymized,
      nodeId: localBleNodeId,
      eventModeEnabled: eventModeEnabled,
      connectOk: false,
      brownout: false,
    );
    if (advertisingStarted) {
      logger.info('Personality advertising started', tag: logName);
    } else {
      logger.warn('Personality advertising failed to start', tag: logName);
    }
  }
}
