// MIGRATION_SHIM: LEGACY_PATH_GUARD TEMPORARY UNTIL TARGET-ROOT MIGRATION
import 'package:avrai_runtime_os/ai2ai/orchestrator_components.dart';
import 'package:avrai_runtime_os/ai2ai/trust/payload_anonymization_lane.dart';
import 'package:avrai_core/models/user/anonymous_user.dart';
import 'package:avrai_core/models/user/unified_user.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_runtime_os/services/user/user_anonymization_service.dart';
import 'package:avrai_runtime_os/services/transport/ble/realtime_listener_callbacks_lane.dart';
import 'package:avrai_core/models/personality_profile.dart';

class PayloadRealtimeOrchestrationLane {
  const PayloadRealtimeOrchestrationLane._();

  static Future<AnonymousUser> anonymizeUserForTransmission({
    required UserAnonymizationService? anonymizationService,
    required UnifiedUser user,
    required String agentId,
    required PersonalityProfile? personalityProfile,
    required bool isAdmin,
    required AppLogger logger,
    required String logName,
  }) {
    return PayloadAnonymizationLane.anonymizeUserForTransmission(
      anonymizationService: anonymizationService,
      user: user,
      agentId: agentId,
      personalityProfile: personalityProfile,
      isAdmin: isAdmin,
      logger: logger,
      logName: logName,
    );
  }

  static Future<void> setupRealtimeListeners({
    required RealtimeCoordinator? coordinator,
    required AppLogger logger,
    required String logName,
  }) {
    return RealtimeListenerCallbacksLane.setup(
      coordinator: coordinator,
      validateNoUnifiedUserInPayload: (payload) {
        PayloadAnonymizationLane.validateNoUnifiedUserInPayload(payload);
      },
      logger: logger,
      logName: logName,
    );
  }
}
