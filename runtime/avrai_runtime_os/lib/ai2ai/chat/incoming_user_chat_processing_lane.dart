// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'package:avrai_runtime_os/ai2ai/chat/incoming_user_chat_router.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_network/avra_network.dart';

class IncomingUserChatProcessingLane {
  const IncomingUserChatProcessingLane._();

  static Future<void> handle({
    required ProtocolMessage message,
    required Future<void> Function(
      ProtocolMessage message,
      Map<String, dynamic> payload,
    ) handleIncomingBusinessExpertChat,
    required Future<void> Function(
      ProtocolMessage message,
      Map<String, dynamic> payload,
    ) handleIncomingBusinessBusinessChat,
    required AppLogger logger,
    required String logName,
  }) async {
    try {
      final Map<String, dynamic> payload = message.payload;
      switch (IncomingUserChatRouter.resolveRoute(
        payload: payload,
        logger: logger,
        logName: logName,
      )) {
        case IncomingUserChatRoute.businessExpert:
          await handleIncomingBusinessExpertChat(message, payload);
          break;
        case IncomingUserChatRoute.businessBusiness:
          await handleIncomingBusinessBusinessChat(message, payload);
          break;
        case IncomingUserChatRoute.unknown:
          break;
      }
    } catch (e, st) {
      logger.error(
        'Error handling incoming user chat message: $e',
        tag: logName,
        error: e,
        stackTrace: st,
      );
    }
  }
}
