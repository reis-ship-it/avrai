import 'package:avrai_network/network/message_encryption_service.dart';

/// PersonalityChatMessage Model
/// 
/// Represents a message in the personality agent chat conversation.
/// Messages are encrypted before storage and decrypted for display.
/// 
/// Phase 2.1: Personality Agent Chat Service
class PersonalityChatMessage {
  final String messageId;
  final String chatId; // chat_${agentId}_${userId}
  final String senderId; // userId or agentId
  final bool isFromUser; // true if from user, false if from agent
  final EncryptedMessage encryptedContent; // Encrypted message
  final DateTime timestamp;
  final Map<String, dynamic>? metadata; // Language learning data, search results, etc.

  PersonalityChatMessage({
    required this.messageId,
    required this.chatId,
    required this.senderId,
    required this.isFromUser,
    required this.encryptedContent,
    required this.timestamp,
    this.metadata,
  });

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'chatId': chatId,
      'senderId': senderId,
      'isFromUser': isFromUser,
      'encryptedContent': encryptedContent.toBase64(),
      'encryptionType': encryptedContent.encryptionType.name,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// Create from JSON storage
  factory PersonalityChatMessage.fromJson(Map<String, dynamic> json) {
    final encryptionType = EncryptionType.values.firstWhere(
      (e) => e.name == json['encryptionType'],
      orElse: () => EncryptionType.aes256gcm,
    );

    return PersonalityChatMessage(
      messageId: json['messageId'] as String,
      chatId: json['chatId'] as String,
      senderId: json['senderId'] as String,
      isFromUser: json['isFromUser'] as bool,
      encryptedContent: EncryptedMessage.fromBase64(
        json['encryptedContent'] as String,
        encryptionType,
        metadata: json['metadata'] as Map<String, dynamic>?,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  String toString() {
    return 'PersonalityChatMessage(id: $messageId, chatId: $chatId, fromUser: $isFromUser, timestamp: $timestamp)';
  }
}

