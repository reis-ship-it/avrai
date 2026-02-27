import 'package:avrai/core/models/user/anonymous_user.dart';
import 'package:avrai/core/models/user/unified_user.dart';
import 'package:avrai/core/services/infrastructure/logger.dart';
import 'package:avrai/core/services/user/user_anonymization_service.dart';
import 'package:avrai_core/models/personality_profile.dart';

class PayloadAnonymizationLane {
  const PayloadAnonymizationLane._();

  static Future<AnonymousUser> anonymizeUserForTransmission({
    required UserAnonymizationService? anonymizationService,
    required UnifiedUser user,
    required String agentId,
    required PersonalityProfile? personalityProfile,
    required bool isAdmin,
    required AppLogger logger,
    required String logName,
  }) async {
    if (anonymizationService == null) {
      throw Exception(
        'UserAnonymizationService not available. Cannot anonymize user for transmission.',
      );
    }

    logger.info(
      'Anonymizing user for AI2AI transmission: ${user.id} -> $agentId',
      tag: logName,
    );

    try {
      final AnonymousUser anonymousUser = await anonymizationService.anonymizeUser(
        user,
        agentId,
        personalityProfile,
        isAdmin: isAdmin,
      );

      logger.info('User anonymized successfully for transmission', tag: logName);
      return anonymousUser;
    } catch (e) {
      logger.error(
        'Failed to anonymize user for transmission',
        error: e,
        tag: logName,
      );
      rethrow;
    }
  }

  static void validateNoUnifiedUserInPayload(Map<String, dynamic> payload) {
    const List<String> forbiddenFields = <String>[
      'id',
      'email',
      'displayName',
      'photoUrl',
      'userId',
    ];

    for (final String field in forbiddenFields) {
      if (payload.containsKey(field)) {
        throw Exception(
          'CRITICAL: UnifiedUser field "$field" detected in AI2AI payload. '
          'All user data must be converted to AnonymousUser before transmission. '
          'Use anonymizeUserForTransmission() method.',
        );
      }
    }

    for (final dynamic value in payload.values) {
      if (value is Map<String, dynamic>) {
        validateNoUnifiedUserInPayload(value);
      } else if (value is List) {
        for (final dynamic item in value) {
          if (item is Map<String, dynamic>) {
            validateNoUnifiedUserInPayload(item);
          }
        }
      }
    }
  }
}
