// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'dart:convert';
import 'dart:typed_data';

import 'package:avrai_runtime_os/services/infrastructure/logger.dart';

class IncomingChatPayloadHelpers {
  const IncomingChatPayloadHelpers._();

  static Uint8List? decodeEncryptedContentOrNull({
    required String? encryptedContentStr,
    required AppLogger logger,
    required String logName,
  }) {
    if (encryptedContentStr == null || encryptedContentStr.isEmpty) return null;
    try {
      return base64Decode(encryptedContentStr);
    } catch (e) {
      logger.warn(
        'Failed to decode encrypted content: $e',
        tag: logName,
      );
      return null;
    }
  }

  static DateTime? parseCreatedAtOrNull({
    required String createdAtStr,
    required AppLogger logger,
    required String logName,
  }) {
    final createdAt = DateTime.tryParse(createdAtStr);
    if (createdAt == null) {
      logger.warn(
        'Failed to parse created_at timestamp: $createdAtStr',
        tag: logName,
      );
    }
    return createdAt;
  }

  static T parseEnumByName<T extends Enum>({
    required List<T> values,
    required String? name,
    required T fallback,
  }) {
    if (name == null || name.isEmpty) return fallback;
    for (final value in values) {
      if (value.name == name) return value;
    }
    return fallback;
  }

  static bool hasMissingRequiredFields(List<Object?> values) {
    for (final value in values) {
      if (value == null) return true;
    }
    return false;
  }

  static void warnIncompleteChatPayload({
    required String chatType,
    required AppLogger logger,
    required String logName,
  }) {
    logger.warn(
      'Received incomplete $chatType chat message: missing required fields',
      tag: logName,
    );
  }
}
