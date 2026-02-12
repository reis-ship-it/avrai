import 'package:avrai_network/network/message_encryption_service.dart';

/// CommunityChatMessage Model
/// 
/// Represents a message in a community/club group chat conversation.
/// Messages are encrypted with a shared group key before storage.
/// 
/// Phase 2.3: Community Chat Service
class CommunityChatMessage {
  final String messageId;
  final String chatId; // community_chat_${communityId}
  final String communityId; // Community/club ID
  final String senderId; // User ID of sender
  final EncryptedMessage encryptedContent; // Encrypted message (using shared group key)
  final DateTime timestamp;
  final Map<String, dynamic>? metadata; // Additional metadata

  CommunityChatMessage({
    required this.messageId,
    required this.chatId,
    required this.communityId,
    required this.senderId,
    required this.encryptedContent,
    required this.timestamp,
    this.metadata,
  });

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'chatId': chatId,
      'communityId': communityId,
      'senderId': senderId,
      'encryptedContent': encryptedContent.toBase64(),
      'encryptionType': encryptedContent.encryptionType.name,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// Create from JSON storage
  factory CommunityChatMessage.fromJson(Map<String, dynamic> json) {
    final encryptionType = EncryptionType.values.firstWhere(
      (e) => e.name == json['encryptionType'],
      orElse: () => EncryptionType.aes256gcm,
    );

    return CommunityChatMessage(
      messageId: json['messageId'] as String,
      chatId: json['chatId'] as String,
      communityId: json['communityId'] as String,
      senderId: json['senderId'] as String,
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
    return 'CommunityChatMessage(id: $messageId, communityId: $communityId, senderId: $senderId)';
  }
}

/// Community Chat Preview
/// 
/// Represents a preview of a community chat conversation for list display
class CommunityChatPreview {
  final String communityId;
  final String communityName;
  final String? communityDescription;
  final String? lastMessagePreview; // Decrypted preview of last message
  final DateTime? lastMessageTime;
  final String? lastSenderName; // Name of last message sender
  final int memberCount;
  final bool isClub; // Whether this is a club (vs regular community)

  CommunityChatPreview({
    required this.communityId,
    required this.communityName,
    this.communityDescription,
    this.lastMessagePreview,
    this.lastMessageTime,
    this.lastSenderName,
    this.memberCount = 0,
    this.isClub = false,
  });

  @override
  String toString() {
    return 'CommunityChatPreview(communityId: $communityId, name: $communityName)';
  }
}

