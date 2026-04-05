import 'package:equatable/equatable.dart';
import 'dart:typed_data';
import 'dart:convert';
// Removed runtime/avrai_runtime_os/services/security/message_encryption_service.dart

/// Business-Expert Message Model
///
/// Represents a message between a business and an expert.
/// Signal Protocol ready - includes encrypted_content and encryption_type fields.
class BusinessExpertMessage extends Equatable {
  final String id;
  final String conversationId;
  final MessageSenderType senderType; // business or expert
  final String senderId;
  final MessageRecipientType recipientType;
  final String recipientId;
  final String content; // Plaintext (for AES-256-GCM)
  final Uint8List?
      encryptedContent; // Encrypted content (for Signal Protocol future)
  final String encryptionType; // aes256gcm or signal_protocol
  final MessageType type; // text, partnership_proposal, file
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  const BusinessExpertMessage({
    required this.id,
    required this.conversationId,
    required this.senderType,
    required this.senderId,
    required this.recipientType,
    required this.recipientId,
    required this.content,
    this.encryptedContent,
    this.encryptionType = 'aes256gcm',
    this.type = MessageType.text,
    this.isRead = false,
    this.readAt,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  BusinessExpertMessage copyWith({
    String? id,
    String? conversationId,
    MessageSenderType? senderType,
    String? senderId,
    MessageRecipientType? recipientType,
    String? recipientId,
    String? content,
    Uint8List? encryptedContent,
    String? encryptionType,
    MessageType? type,
    bool? isRead,
    DateTime? readAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return BusinessExpertMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderType: senderType ?? this.senderType,
      senderId: senderId ?? this.senderId,
      recipientType: recipientType ?? this.recipientType,
      recipientId: recipientId ?? this.recipientId,
      content: content ?? this.content,
      encryptedContent: encryptedContent ?? this.encryptedContent,
      encryptionType: encryptionType ?? this.encryptionType,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_type': senderType.name,
      'sender_id': senderId,
      'recipient_type': recipientType.name,
      'recipient_id': recipientId,
      'content': content,
      'encrypted_content':
          encryptedContent != null ? base64Encode(encryptedContent!) : null,
      'encryption_type': encryptionType,
      'message_type': type.name,
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory BusinessExpertMessage.fromJson(Map<String, dynamic> json) {
    return BusinessExpertMessage(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderType: () {
        final senderTypeStr = json['sender_type'] as String? ?? 'business';
        return MessageSenderType.values.firstWhere(
          (e) => e.name == senderTypeStr,
          orElse: () => MessageSenderType.business,
        );
      }(),
      senderId: json['sender_id'] as String,
      recipientType: () {
        final recipientTypeStr = json['recipient_type'] as String? ?? 'expert';
        return MessageRecipientType.values.firstWhere(
          (e) => e.name == recipientTypeStr,
          orElse: () => MessageRecipientType.expert,
        );
      }(),
      recipientId: json['recipient_id'] as String,
      content: json['content'] as String,
      encryptedContent: json['encrypted_content'] != null
          ? base64Decode(json['encrypted_content'] as String)
          : null,
      encryptionType: json['encryption_type'] as String? ?? 'aes256gcm',
      type: () {
        final messageTypeStr = json['message_type'] as String? ?? 'text';
        return MessageType.values.firstWhere(
          (e) => e.name == messageTypeStr,
          orElse: () => MessageType.text,
        );
      }(),
      isRead: json['is_read'] as bool? ?? false,
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        conversationId,
        senderType,
        senderId,
        recipientType,
        recipientId,
        content,
        encryptedContent,
        encryptionType,
        type,
        isRead,
        readAt,
        createdAt,
        updatedAt,
        metadata,
      ];
}

/// Message sender type
enum MessageSenderType {
  business,
  expert,
}

/// Message recipient type
enum MessageRecipientType {
  business,
  expert,
}

/// Message type
enum MessageType {
  text,
  partnershipProposal,
  file,
}
