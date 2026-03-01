import 'package:equatable/equatable.dart';
import 'dart:typed_data';
import 'dart:convert';
// Removed runtime/avrai_runtime_os/services/security/message_encryption_service.dart

/// Business-Business Message Model
///
/// Represents a message between two businesses.
/// Signal Protocol ready - includes encrypted_content and encryption_type fields.
class BusinessBusinessMessage extends Equatable {
  final String id;
  final String conversationId;
  final String senderBusinessId;
  final String recipientBusinessId;
  final String content; // Plaintext (for AES-256-GCM)
  final Uint8List?
      encryptedContent; // Encrypted content (for Signal Protocol future)
  final String encryptionType; // aes256gcm or signal_protocol
  final BusinessBusinessMessageType
      type; // text, event_partnership_proposal, file
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BusinessBusinessMessage({
    required this.id,
    required this.conversationId,
    required this.senderBusinessId,
    required this.recipientBusinessId,
    required this.content,
    this.encryptedContent,
    this.encryptionType = 'aes256gcm',
    this.type = BusinessBusinessMessageType.text,
    this.isRead = false,
    this.readAt,
    required this.createdAt,
    required this.updatedAt,
  });

  BusinessBusinessMessage copyWith({
    String? id,
    String? conversationId,
    String? senderBusinessId,
    String? recipientBusinessId,
    String? content,
    Uint8List? encryptedContent,
    String? encryptionType,
    BusinessBusinessMessageType? type,
    bool? isRead,
    DateTime? readAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BusinessBusinessMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderBusinessId: senderBusinessId ?? this.senderBusinessId,
      recipientBusinessId: recipientBusinessId ?? this.recipientBusinessId,
      content: content ?? this.content,
      encryptedContent: encryptedContent ?? this.encryptedContent,
      encryptionType: encryptionType ?? this.encryptionType,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_business_id': senderBusinessId,
      'recipient_business_id': recipientBusinessId,
      'content': content,
      'encrypted_content':
          encryptedContent != null ? base64Encode(encryptedContent!) : null,
      'encryption_type': encryptionType,
      'message_type': type.name,
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory BusinessBusinessMessage.fromJson(Map<String, dynamic> json) {
    return BusinessBusinessMessage(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderBusinessId: json['sender_business_id'] as String,
      recipientBusinessId: json['recipient_business_id'] as String,
      content: json['content'] as String,
      encryptedContent: json['encrypted_content'] != null
          ? base64Decode(json['encrypted_content'] as String)
          : null,
      encryptionType: json['encryption_type'] as String? ?? 'aes256gcm',
      type: () {
        final messageTypeStr = json['message_type'] as String? ?? 'text';
        return BusinessBusinessMessageType.values.firstWhere(
          (e) => e.name == messageTypeStr,
          orElse: () => BusinessBusinessMessageType.text,
        );
      }(),
      isRead: json['is_read'] as bool? ?? false,
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  @override
  List<Object?> get props => [
        id,
        conversationId,
        senderBusinessId,
        recipientBusinessId,
        content,
        encryptedContent,
        encryptionType,
        type,
        isRead,
        readAt,
        createdAt,
        updatedAt,
      ];
}

/// Message type for business-business messages
enum BusinessBusinessMessageType {
  text,
  eventPartnershipProposal,
  file,
}
