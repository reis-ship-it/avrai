import 'package:avrai_network/network/message_encryption_service.dart';

/// FriendChatMessage Model
/// 
/// Represents a message in a 1-on-1 friend chat conversation.
/// Messages are encrypted before storage and decrypted for display.
/// 
/// Phase 2.2: Friend Chat Service
class FriendChatMessage {
  final String messageId;
  final String chatId; // friend_chat_${userId1}_${userId2} (sorted for consistency)
  final String senderId; // userId of sender
  final String recipientId; // userId of recipient
  final EncryptedMessage encryptedContent; // Encrypted message
  final DateTime timestamp;
  final bool isRead; // Whether recipient has read the message
  final Map<String, dynamic>? metadata; // Additional metadata

  FriendChatMessage({
    required this.messageId,
    required this.chatId,
    required this.senderId,
    required this.recipientId,
    required this.encryptedContent,
    required this.timestamp,
    this.isRead = false,
    this.metadata,
  });

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'chatId': chatId,
      'senderId': senderId,
      'recipientId': recipientId,
      'encryptedContent': encryptedContent.toBase64(),
      'encryptionType': encryptedContent.encryptionType.name,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'metadata': metadata,
    };
  }

  /// Create from JSON storage
  factory FriendChatMessage.fromJson(Map<String, dynamic> json) {
    final encryptionType = EncryptionType.values.firstWhere(
      (e) => e.name == json['encryptionType'],
      orElse: () => EncryptionType.aes256gcm,
    );

    return FriendChatMessage(
      messageId: json['messageId'] as String,
      chatId: json['chatId'] as String,
      senderId: json['senderId'] as String,
      recipientId: json['recipientId'] as String,
      encryptedContent: EncryptedMessage.fromBase64(
        json['encryptedContent'] as String,
        encryptionType,
        metadata: json['metadata'] as Map<String, dynamic>?,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['isRead'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Create a copy with updated read status
  FriendChatMessage copyWith({
    String? messageId,
    String? chatId,
    String? senderId,
    String? recipientId,
    EncryptedMessage? encryptedContent,
    DateTime? timestamp,
    bool? isRead,
    Map<String, dynamic>? metadata,
  }) {
    return FriendChatMessage(
      messageId: messageId ?? this.messageId,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      recipientId: recipientId ?? this.recipientId,
      encryptedContent: encryptedContent ?? this.encryptedContent,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'FriendChatMessage(id: $messageId, chatId: $chatId, from: $senderId, to: $recipientId, read: $isRead)';
  }
}

/// Friend Chat Preview
/// 
/// Represents a preview of a friend chat conversation for list display
class FriendChatPreview {
  final String friendId;
  final String friendName;
  final String? friendPhotoUrl;
  final String? lastMessagePreview; // Decrypted preview of last message
  final DateTime? lastMessageTime;
  final int unreadCount;
  final bool isOnline;

  FriendChatPreview({
    required this.friendId,
    required this.friendName,
    this.friendPhotoUrl,
    this.lastMessagePreview,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.isOnline = false,
  });

  @override
  String toString() {
    return 'FriendChatPreview(friendId: $friendId, unread: $unreadCount)';
  }
}

