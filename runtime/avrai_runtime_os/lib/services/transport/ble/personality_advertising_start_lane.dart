// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'package:avrai_runtime_os/ai/privacy_protection.dart';
import 'package:avrai_runtime_os/ai/vibe_analysis_engine.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_network/avra_network.dart';
import 'package:avrai_knot/services/knot/personality_knot_service.dart';
import 'package:avrai_knot/services/knot/dna_encoder_service.dart';
import 'package:get_it/get_it.dart';

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

    // V0.1 Pivot: Generate DNA math string payload for BLE
    // We try to get the PersonalityKnotService from GetIt, fallback to creating it.
    final knotService = GetIt.instance.isRegistered<PersonalityKnotService>()
        ? GetIt.instance<PersonalityKnotService>()
        : PersonalityKnotService();
    final dnaEncoder = DnaEncoderService();

    final knot = await knotService.generateKnot(personality);
    final dnaPayload = dnaEncoder.encode(knot);

    final bool advertisingStarted = await advertisingService.startAdvertising(
      payload: dnaPayload,
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
