// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'package:avrai/core/ai/privacy_protection.dart';
import 'package:avrai/core/ai/vibe_analysis_engine.dart';
import 'package:avrai/core/services/infrastructure/logger.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_network/avra_network.dart';

class PersonalityAdvertisingUpdateLane {
  const PersonalityAdvertisingUpdateLane._();

  static Future<void> update({
    required String userId,
    required PersonalityProfile updatedPersonality,
    required PersonalityAdvertisingService? advertisingService,
    required SharedPreferencesCompat prefs,
    required UserVibeAnalyzer vibeAnalyzer,
    required String Function() localBleNodeId,
    required bool eventModeEnabled,
    required bool lastAdvertisedConnectOk,
    required bool lastAdvertisedBrownout,
    required void Function(PersonalityProfile profile) setCurrentPersonality,
    required AppLogger logger,
    required String logName,
  }) async {
    if (advertisingService == null) {
      return;
    }

    final bool discoveryEnabled = prefs.getBool('discovery_enabled') ?? false;
    if (!discoveryEnabled) return;

    setCurrentPersonality(updatedPersonality);

    try {
      logger.info(
        'Updating personality advertising after evolution (generation ${updatedPersonality.evolutionGeneration})',
        tag: logName,
      );

      final vibe =
          await vibeAnalyzer.compileUserVibe(userId, updatedPersonality);
      final anonymized = await PrivacyProtection.anonymizeUserVibe(vibe);

      final bool success = await advertisingService.updatePersonalityData(
        personalityData: anonymized,
        nodeId: localBleNodeId(),
        eventModeEnabled: eventModeEnabled,
        connectOk: lastAdvertisedConnectOk,
        brownout: lastAdvertisedBrownout,
      );

      if (success) {
        logger.info('Personality advertising updated successfully', tag: logName);
      } else {
        logger.warn('Failed to update personality advertising', tag: logName);
      }
    } catch (e) {
      logger.error('Error updating personality advertising',
          error: e, tag: logName);
    }
  }
}
