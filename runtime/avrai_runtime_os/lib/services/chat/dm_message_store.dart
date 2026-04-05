import 'dart:async';
import 'dart:developer' as developer;

import 'package:avrai_runtime_os/config/ai2ai_retention_config.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_transport_retention_telemetry_store.dart';
import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';
import 'package:avrai_runtime_os/services/ledgers/ledger_audit_v0.dart';
import 'package:avrai_runtime_os/services/ledgers/ledger_domain_v0.dart';
import 'package:avrai_runtime_os/services/security/message_encryption_service.dart';

/// Minimal DM blob store used by the "payloadless realtime" chat transport.
///
/// Realtime events only notify `messageId`; the ciphertext is fetched by messageId.
class DmMessageStore {
  static const String _logName = 'DmMessageStore';
  static const String _dmTransportBlobsTable = 'dm_transport_blobs';
  static const String _dmTransportEdgeFunction = 'dm-transport-enqueue-v1';
  static const String _dmTransportEnqueueRpc = 'dm_transport_enqueue_v1';
  static const String _dmTransportConsumeRpc = 'dm_transport_consume_v1';

  final SupabaseService _supabase;
  final Ai2AiTransportRetentionTelemetryStore _retentionTelemetryStore;

  DmMessageStore({
    SupabaseService? supabase,
    Ai2AiTransportRetentionTelemetryStore? retentionTelemetryStore,
  })  : _supabase = supabase ?? SupabaseService(),
        _retentionTelemetryStore =
            retentionTelemetryStore ?? Ai2AiTransportRetentionTelemetryStore();

  Ai2AiRetentionPolicy get blobRetentionPolicy =>
      Ai2AiRetentionConfig.dmTransportBlob;

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
      await _supabase.client.from(_dmTransportBlobsTable).insert({
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

  /// Server-authoritative DM enqueue.
  ///
  /// Writes ciphertext + payloadless notification atomically via RPC.
  Future<void> enqueueDm({
    required String messageId,
    required String fromUserId,
    required String toUserId,
    required String senderAgentId,
    required String recipientAgentId,
    required EncryptedMessage encrypted,
    required DateTime sentAt,
    String recipientDeviceId = 'legacy',
  }) async {
    if (!_supabase.isAvailable) {
      throw Exception('Supabase not available');
    }

    try {
      // Preferred path: edge function centralizes DM enqueue in one server-owned API.
      var edgeOk = false;
      try {
        final edgeRes = await _supabase.client.functions.invoke(
          _dmTransportEdgeFunction,
          body: <String, Object?>{
            'message_id': messageId,
            'from_user_id': fromUserId,
            'to_user_id': toUserId,
            'sender_agent_id': senderAgentId,
            'recipient_agent_id': recipientAgentId,
            'encryption_type': encrypted.encryptionType.name,
            'ciphertext_base64': encrypted.toBase64(),
            'sent_at': sentAt.toUtc().toIso8601String(),
            'recipient_device_id': recipientDeviceId,
          },
        );

        final edgeData = edgeRes.data;
        edgeOk = edgeRes.status == 200 &&
            ((edgeData is Map && edgeData['ok'] == true) ||
                (edgeData is String && edgeData.contains('"ok":true')));
      } catch (_) {
        edgeOk = false;
      }

      if (!edgeOk) {
        await _supabase.client.rpc(
          _dmTransportEnqueueRpc,
          params: <String, dynamic>{
            'p_message_id': messageId,
            'p_from_user_id': fromUserId,
            'p_to_user_id': toUserId,
            'p_sender_agent_id': senderAgentId,
            'p_recipient_agent_id': recipientAgentId,
            'p_encryption_type': encrypted.encryptionType.name,
            'p_ciphertext_base64': encrypted.toBase64(),
            'p_sent_at': sentAt.toUtc().toIso8601String(),
            'p_recipient_device_id': recipientDeviceId,
          },
        );
      }
      if (LedgerAuditV0.isEnabled) {
        unawaited(LedgerAuditV0.tryAppend(
          domain: LedgerDomainV0.security,
          eventType: 'signal_dm_enqueued_server_authoritative',
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
            'recipient_device_id': recipientDeviceId,
          },
        ));
      }
    } catch (e, st) {
      developer.log(
        'Failed to enqueue DM server-authoritative',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      if (LedgerAuditV0.isEnabled) {
        unawaited(LedgerAuditV0.tryAppend(
          domain: LedgerDomainV0.security,
          eventType: 'signal_dm_enqueue_server_authoritative_failed',
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
          .from(_dmTransportBlobsTable)
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

  Future<DmTransportConsumeResult> consumeDmBlob({
    required String messageId,
    required String toUserId,
    String? recipientDeviceId,
  }) async {
    if (!_supabase.isAvailable) {
      throw Exception('Supabase not available');
    }

    try {
      final response = await _supabase.client.rpc(
        _dmTransportConsumeRpc,
        params: <String, dynamic>{
          'p_message_id': messageId,
          'p_to_user_id': toUserId,
          'p_recipient_device_id': recipientDeviceId,
        },
      );
      final payload = Map<String, dynamic>.from(
        response as Map<dynamic, dynamic>,
      );
      final result = DmTransportConsumeResult.fromJson(payload);
      await _retentionTelemetryStore.recordDmConsumeSuccess(
        messageId: messageId,
        recipientUserId: toUserId,
        recipientDeviceId: recipientDeviceId,
        deletedTransportCount:
            result.deletedBlobCount + result.deletedNotificationCount,
        remainingTransportCount: result.remainingBlobCount,
      );
      if (LedgerAuditV0.isEnabled) {
        unawaited(LedgerAuditV0.tryAppend(
          domain: LedgerDomainV0.security,
          eventType: 'signal_dm_blob_consumed',
          occurredAt: DateTime.now(),
          entityType: 'dm_message',
          entityId: messageId,
          payload: <String, Object?>{
            'message_id': messageId,
            'to_user_id': toUserId,
            'recipient_device_id': recipientDeviceId,
            'deleted_blob_count': result.deletedBlobCount,
            'deleted_notification_count': result.deletedNotificationCount,
            'remaining_blob_count': result.remainingBlobCount,
          },
        ));
      }
      return result;
    } catch (e, st) {
      developer.log(
        'Failed to consume DM blob',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      await _retentionTelemetryStore.recordDmConsumeFailure(
        messageId: messageId,
        recipientUserId: toUserId,
        recipientDeviceId: recipientDeviceId,
        errorSummary: e.toString(),
      );
      if (LedgerAuditV0.isEnabled) {
        unawaited(LedgerAuditV0.tryAppend(
          domain: LedgerDomainV0.security,
          eventType: 'signal_dm_blob_consume_failed',
          occurredAt: DateTime.now(),
          entityType: 'dm_message',
          entityId: messageId,
          payload: <String, Object?>{
            'message_id': messageId,
            'to_user_id': toUserId,
            'recipient_device_id': recipientDeviceId,
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
    final encryptionTypeStr =
        (json['encryption_type'] as String?) ?? 'aes256gcm';
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

class DmTransportConsumeResult {
  final bool ok;
  final int deletedBlobCount;
  final int deletedNotificationCount;
  final int remainingBlobCount;

  const DmTransportConsumeResult({
    required this.ok,
    required this.deletedBlobCount,
    required this.deletedNotificationCount,
    required this.remainingBlobCount,
  });

  factory DmTransportConsumeResult.fromJson(Map<String, dynamic> json) {
    return DmTransportConsumeResult(
      ok: json['ok'] as bool? ?? false,
      deletedBlobCount: (json['deleted_blob_count'] as num?)?.toInt() ?? 0,
      deletedNotificationCount:
          (json['deleted_notification_count'] as num?)?.toInt() ?? 0,
      remainingBlobCount: (json['remaining_blob_count'] as num?)?.toInt() ?? 0,
    );
  }
}
