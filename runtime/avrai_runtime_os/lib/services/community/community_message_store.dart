import 'dart:async';
import 'dart:developer' as developer;

import 'package:avrai_runtime_os/config/ai2ai_retention_config.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_transport_retention_telemetry_store.dart';
import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';
import 'package:avrai_runtime_os/services/ledgers/ledger_audit_v0.dart';
import 'package:avrai_runtime_os/services/ledgers/ledger_domain_v0.dart';

class CommunityMessageStore {
  static const String _logName = 'CommunityMessageStore';
  static const String _consumeMessageBlobRpc = 'community_message_consume_v1';

  final SupabaseService _supabase;
  final Ai2AiTransportRetentionTelemetryStore _retentionTelemetryStore;

  CommunityMessageStore({
    SupabaseService? supabase,
    Ai2AiTransportRetentionTelemetryStore? retentionTelemetryStore,
  })  : _supabase = supabase ?? SupabaseService(),
        _retentionTelemetryStore =
            retentionTelemetryStore ?? Ai2AiTransportRetentionTelemetryStore();

  Ai2AiRetentionPolicy get blobRetentionPolicy =>
      Ai2AiRetentionConfig.communityTransportBlob;

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

  Future<CommunityMessageConsumeResult> consumeMessageBlob({
    required String messageId,
    required String recipientUserId,
  }) async {
    if (!_supabase.isAvailable) throw Exception('Supabase not available');
    try {
      final response = await _supabase.client.rpc(
        _consumeMessageBlobRpc,
        params: <String, dynamic>{
          'p_message_id': messageId,
          'p_to_user_id': recipientUserId,
        },
      );
      final payload = Map<String, dynamic>.from(
        response as Map<dynamic, dynamic>,
      );
      final result = CommunityMessageConsumeResult.fromJson(payload);
      await _retentionTelemetryStore.recordCommunityConsumeSuccess(
        messageId: messageId,
        recipientUserId: recipientUserId,
        deletedTransportCount:
            result.deletedBlobCount + result.deletedNotificationCount,
        remainingTransportCount: result.remainingNotificationCount,
      );
      if (LedgerAuditV0.isEnabled) {
        unawaited(LedgerAuditV0.tryAppend(
          domain: LedgerDomainV0.security,
          eventType: 'signal_community_blob_consumed',
          occurredAt: DateTime.now(),
          entityType: 'community_message',
          entityId: messageId,
          payload: <String, Object?>{
            'message_id': messageId,
            'recipient_user_id': recipientUserId,
            'deleted_notification_count': result.deletedNotificationCount,
            'deleted_blob_count': result.deletedBlobCount,
            'remaining_notification_count': result.remainingNotificationCount,
          },
        ));
      }
      return result;
    } catch (e, st) {
      developer.log(
        'Failed to consume community message blob',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      await _retentionTelemetryStore.recordCommunityConsumeFailure(
        messageId: messageId,
        recipientUserId: recipientUserId,
        errorSummary: e.toString(),
      );
      if (LedgerAuditV0.isEnabled) {
        unawaited(LedgerAuditV0.tryAppend(
          domain: LedgerDomainV0.security,
          eventType: 'signal_community_blob_consume_failed',
          occurredAt: DateTime.now(),
          entityType: 'community_message',
          entityId: messageId,
          payload: <String, Object?>{
            'message_id': messageId,
            'recipient_user_id': recipientUserId,
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

class CommunityMessageConsumeResult {
  final bool ok;
  final int deletedNotificationCount;
  final int deletedBlobCount;
  final int remainingNotificationCount;

  const CommunityMessageConsumeResult({
    required this.ok,
    required this.deletedNotificationCount,
    required this.deletedBlobCount,
    required this.remainingNotificationCount,
  });

  factory CommunityMessageConsumeResult.fromJson(Map<String, dynamic> json) {
    return CommunityMessageConsumeResult(
      ok: json['ok'] as bool? ?? false,
      deletedNotificationCount:
          (json['deleted_notification_count'] as num?)?.toInt() ?? 0,
      deletedBlobCount: (json['deleted_blob_count'] as num?)?.toInt() ?? 0,
      remainingNotificationCount:
          (json['remaining_notification_count'] as num?)?.toInt() ?? 0,
    );
  }
}
