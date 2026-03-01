import 'dart:async';
import 'dart:developer' as developer;

import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';
import 'package:avrai_runtime_os/services/ledgers/ledger_audit_v0.dart';
import 'package:avrai_runtime_os/services/ledgers/ledger_domain_v0.dart';

class CommunityMessageStore {
  static const String _logName = 'CommunityMessageStore';

  final SupabaseService _supabase;

  CommunityMessageStore({SupabaseService? supabase})
      : _supabase = supabase ?? SupabaseService();

  Future<void> putMessageBlob({
    required String messageId,
    required String communityId,
    required String senderUserId,
    required String senderAgentId,
    required String keyId,
    required String algorithm,
    required String ciphertextBase64,
    required DateTime sentAt,
  }) async {
    if (!_supabase.isAvailable) throw Exception('Supabase not available');
    try {
      await _supabase.client.from('community_message_blobs').insert({
        'message_id': messageId,
        'community_id': communityId,
        'sender_user_id': senderUserId,
        'sender_agent_id': senderAgentId,
        'key_id': keyId,
        'algorithm': algorithm,
        'ciphertext_base64': ciphertextBase64,
        'sent_at': sentAt.toIso8601String(),
      });
      if (LedgerAuditV0.isEnabled) {
        unawaited(LedgerAuditV0.tryAppend(
          domain: LedgerDomainV0.security,
          eventType: 'signal_community_blob_written',
          occurredAt: sentAt,
          entityType: 'community_message',
          entityId: messageId,
          payload: <String, Object?>{
            'message_id': messageId,
            'community_id': communityId,
            'sender_user_id': senderUserId,
            'sender_agent_id': senderAgentId,
            'key_id': keyId,
            'algorithm': algorithm,
            'ciphertext_base64_len': ciphertextBase64.length,
          },
        ));
      }
    } catch (e, st) {
      developer.log('Failed to put community message blob',
          name: _logName, error: e, stackTrace: st);
      if (LedgerAuditV0.isEnabled) {
        unawaited(LedgerAuditV0.tryAppend(
          domain: LedgerDomainV0.security,
          eventType: 'signal_community_blob_write_failed',
          occurredAt: DateTime.now(),
          entityType: 'community_message',
          entityId: messageId,
          payload: <String, Object?>{
            'message_id': messageId,
            'community_id': communityId,
            'sender_user_id': senderUserId,
            'error': e.toString(),
          },
        ));
      }
      rethrow;
    }
  }

  Future<CommunityMessageBlob?> getMessageBlob(String messageId) async {
    if (!_supabase.isAvailable) throw Exception('Supabase not available');
    try {
      final row = await _supabase.client
          .from('community_message_blobs')
          .select()
          .eq('message_id', messageId)
          .maybeSingle();
      if (row == null) return null;
      if (LedgerAuditV0.isEnabled) {
        unawaited(LedgerAuditV0.tryAppend(
          domain: LedgerDomainV0.security,
          eventType: 'signal_community_blob_read',
          occurredAt: DateTime.now(),
          entityType: 'community_message',
          entityId: messageId,
          payload: <String, Object?>{
            'message_id': messageId,
          },
        ));
      }
      return CommunityMessageBlob.fromJson(row);
    } catch (e, st) {
      developer.log('Failed to get community message blob',
          name: _logName, error: e, stackTrace: st);
      if (LedgerAuditV0.isEnabled) {
        unawaited(LedgerAuditV0.tryAppend(
          domain: LedgerDomainV0.security,
          eventType: 'signal_community_blob_read_failed',
          occurredAt: DateTime.now(),
          entityType: 'community_message',
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

class CommunityMessageBlob {
  final String messageId;
  final String communityId;
  final String senderUserId;
  final String senderAgentId;
  final String keyId;
  final String algorithm;
  final String ciphertextBase64;
  final DateTime sentAt;

  const CommunityMessageBlob({
    required this.messageId,
    required this.communityId,
    required this.senderUserId,
    required this.senderAgentId,
    required this.keyId,
    required this.algorithm,
    required this.ciphertextBase64,
    required this.sentAt,
  });

  factory CommunityMessageBlob.fromJson(Map<String, dynamic> json) {
    return CommunityMessageBlob(
      messageId: json['message_id'] as String,
      communityId: json['community_id'] as String,
      senderUserId: json['sender_user_id'] as String,
      senderAgentId: json['sender_agent_id'] as String,
      keyId: json['key_id'] as String,
      algorithm: json['algorithm'] as String,
      ciphertextBase64: json['ciphertext_base64'] as String,
      sentAt: DateTime.parse(json['sent_at'] as String),
    );
  }
}
