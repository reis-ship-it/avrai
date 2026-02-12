import 'dart:async';
import 'dart:developer' as developer;

import 'package:avrai/core/services/infrastructure/supabase_service.dart';
import 'package:avrai/core/services/ledgers/ledger_audit_v0.dart';
import 'package:avrai/core/services/ledgers/ledger_domain_v0.dart';
import 'package:avrai/core/services/security/message_encryption_service.dart';

/// Minimal DM blob store used by the "payloadless realtime" chat transport.
///
/// Realtime events only notify `messageId`; the ciphertext is fetched by messageId.
class DmMessageStore {
  static const String _logName = 'DmMessageStore';

  final SupabaseService _supabase;

  DmMessageStore({
    SupabaseService? supabase,
  }) : _supabase = supabase ?? SupabaseService();

  Future<void> putDmBlob({
    required String messageId,
    required String fromUserId,
    required String toUserId,
    required String senderAgentId,
    required String recipientAgentId,
    required EncryptedMessage encrypted,
    required DateTime sentAt,
  }) async {
    if (!_supabase.isAvailable) {
      throw Exception('Supabase not available');
    }

    try {
      await _supabase.client.from('dm_message_blobs').insert({
        'message_id': messageId,
        'from_user_id': fromUserId,
        'to_user_id': toUserId,
        'sender_agent_id': senderAgentId,
        'recipient_agent_id': recipientAgentId,
        'encryption_type': encrypted.encryptionType.name,
        'ciphertext_base64': encrypted.toBase64(),
        'sent_at': sentAt.toIso8601String(),
      });
      if (LedgerAuditV0.isEnabled) {
        unawaited(LedgerAuditV0.tryAppend(
          domain: LedgerDomainV0.security,
          eventType: 'signal_dm_blob_written',
          occurredAt: sentAt,
          entityType: 'dm_message',
          entityId: messageId,
          payload: <String, Object?>{
            'message_id': messageId,
            'to_user_id': toUserId,
            'from_user_id': fromUserId,
            'sender_agent_id': senderAgentId,
            'recipient_agent_id': recipientAgentId,
            'encryption_type': encrypted.encryptionType.name,
            'ciphertext_base64_len': encrypted.toBase64().length,
          },
        ));
      }
    } catch (e, st) {
      developer.log(
        'Failed to put DM blob',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      if (LedgerAuditV0.isEnabled) {
        unawaited(LedgerAuditV0.tryAppend(
          domain: LedgerDomainV0.security,
          eventType: 'signal_dm_blob_write_failed',
          occurredAt: DateTime.now(),
          entityType: 'dm_message',
          entityId: messageId,
          payload: <String, Object?>{
            'message_id': messageId,
            'to_user_id': toUserId,
            'from_user_id': fromUserId,
            'error': e.toString(),
          },
        ));
      }
      rethrow;
    }
  }

  Future<DmMessageBlob?> getDmBlob(String messageId) async {
    if (!_supabase.isAvailable) {
      throw Exception('Supabase not available');
    }

    try {
      final row = await _supabase.client
          .from('dm_message_blobs')
          .select()
          .eq('message_id', messageId)
          .maybeSingle();

      if (row == null) return null;
      if (LedgerAuditV0.isEnabled) {
        unawaited(LedgerAuditV0.tryAppend(
          domain: LedgerDomainV0.security,
          eventType: 'signal_dm_blob_read',
          occurredAt: DateTime.now(),
          entityType: 'dm_message',
          entityId: messageId,
          payload: <String, Object?>{
            'message_id': messageId,
          },
        ));
      }
      return DmMessageBlob.fromJson(row);
    } catch (e, st) {
      developer.log(
        'Failed to get DM blob',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      if (LedgerAuditV0.isEnabled) {
        unawaited(LedgerAuditV0.tryAppend(
          domain: LedgerDomainV0.security,
          eventType: 'signal_dm_blob_read_failed',
          occurredAt: DateTime.now(),
          entityType: 'dm_message',
          entityId: messageId,
          payload: <String, Object?>{
            'message_id': messageId,
            'error': e.toString(),
          },
        ));
      }
      rethrow;
    }
  }
}

class DmMessageBlob {
  final String messageId;
  final String fromUserId;
  final String toUserId;
  final String senderAgentId;
  final String recipientAgentId;
  final EncryptionType encryptionType;
  final String ciphertextBase64;
  final DateTime sentAt;

  const DmMessageBlob({
    required this.messageId,
    required this.fromUserId,
    required this.toUserId,
    required this.senderAgentId,
    required this.recipientAgentId,
    required this.encryptionType,
    required this.ciphertextBase64,
    required this.sentAt,
  });

  factory DmMessageBlob.fromJson(Map<String, dynamic> json) {
    final encryptionTypeStr = (json['encryption_type'] as String?) ?? 'aes256gcm';
    final encryptionType = EncryptionType.values.firstWhere(
      (e) => e.name == encryptionTypeStr,
      orElse: () => EncryptionType.aes256gcm,
    );

    return DmMessageBlob(
      messageId: json['message_id'] as String,
      fromUserId: json['from_user_id'] as String,
      toUserId: json['to_user_id'] as String,
      senderAgentId: json['sender_agent_id'] as String,
      recipientAgentId: json['recipient_agent_id'] as String,
      encryptionType: encryptionType,
      ciphertextBase64: json['ciphertext_base64'] as String,
      sentAt: DateTime.parse(json['sent_at'] as String),
    );
  }

  EncryptedMessage toEncryptedMessage() {
    return EncryptedMessage.fromBase64(ciphertextBase64, encryptionType);
  }
}

