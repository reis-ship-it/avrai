import 'package:avrai/core/services/infrastructure/logger.dart';

enum IncomingUserChatRoute {
  businessExpert,
  businessBusiness,
  unknown,
}

class IncomingUserChatRouter {
  const IncomingUserChatRouter._();

  static IncomingUserChatRoute resolveRoute({
    required Map<String, dynamic> payload,
    required AppLogger logger,
    required String logName,
  }) {
    final messageCategory = payload['message_category'] as String?;
    if (messageCategory != null && messageCategory != 'user_chat') {
      logger.warn(
        'Received userChat message with mismatched category: $messageCategory',
        tag: logName,
      );
    }

    final hasBusinessExpertFields = payload.containsKey('sender_type') &&
        (payload.containsKey('business_id') || payload.containsKey('expert_id'));
    if (hasBusinessExpertFields) {
      return IncomingUserChatRoute.businessExpert;
    }

    final hasBusinessBusinessFields = payload.containsKey('sender_business_id') &&
        payload.containsKey('recipient_business_id');
    if (hasBusinessBusinessFields) {
      return IncomingUserChatRoute.businessBusiness;
    }

    logger.warn(
      'Received userChat message with unrecognized payload structure: ${payload.keys}',
      tag: logName,
    );
    return IncomingUserChatRoute.unknown;
  }
}
