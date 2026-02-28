import 'dart:convert';
import 'dart:developer' as developer;

import 'package:avrai/core/services/admin/audit_log_service.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai/core/services/infrastructure/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminInternalUseAgreementRecord {
  const AdminInternalUseAgreementRecord({
    required this.timestamp,
    required this.userId,
    required this.sessionNonce,
    required this.appId,
    required this.agreementVersion,
    required this.serverAccepted,
    this.failureReason,
  });

  final DateTime timestamp;
  final String userId;
  final String sessionNonce;
  final String appId;
  final String agreementVersion;
  final bool serverAccepted;
  final String? failureReason;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'ts': timestamp.toUtc().toIso8601String(),
        'user_id': userId,
        'session_nonce': sessionNonce,
        'app_id': appId,
        'agreement_version': agreementVersion,
        'server_accepted': serverAccepted,
        if (failureReason != null) 'failure_reason': failureReason,
      };

  factory AdminInternalUseAgreementRecord.fromJson(Map<String, dynamic> json) {
    return AdminInternalUseAgreementRecord(
      timestamp: DateTime.tryParse(json['ts'] as String? ?? '')?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      userId: json['user_id'] as String? ?? 'unknown',
      sessionNonce: json['session_nonce'] as String? ?? '',
      appId: json['app_id'] as String? ?? 'admin_app',
      agreementVersion: json['agreement_version'] as String? ?? 'v1',
      serverAccepted: json['server_accepted'] as bool? ?? false,
      failureReason: json['failure_reason'] as String?,
    );
  }
}

class AdminInternalUseAgreementService {
  AdminInternalUseAgreementService({
    required SharedPreferencesCompat prefs,
    required SupabaseService supabaseService,
    AuditLogService? auditLogService,
  })  : _prefs = prefs,
        _supabaseService = supabaseService,
        _auditLogService = auditLogService ?? AuditLogService();

  static const String _logName = 'AdminInternalUseAgreementService';
  static const String _eventsKey = 'admin_internal_use_agreement_events_v1';
  static const String _sessionNonceKey =
      'admin_internal_use_agreement_session_nonce_v1';
  static const int _maxEvents = 500;

  final SharedPreferencesCompat _prefs;
  final SupabaseService _supabaseService;
  final AuditLogService _auditLogService;

  Future<bool> recordAndVerifyCurrentLogin({
    required String userId,
    required String sessionNonce,
    String appId = 'admin_app',
    String agreementVersion = 'v1',
    String agreementText = '',
  }) async {
    bool serverAccepted = false;
    String? failureReason;
    try {
      final client = _supabaseService.tryGetClient();
      if (client == null) {
        throw Exception('supabase_unavailable');
      }

      final now = DateTime.now().toUtc().toIso8601String();
      await client.auth.updateUser(
        UserAttributes(
          data: <String, dynamic>{
            'admin_internal_use_accepted_at': now,
            'admin_internal_use_nonce': sessionNonce,
            'admin_internal_use_app': appId,
            'admin_internal_use_agreement_version': agreementVersion,
          },
        ),
      );

      serverAccepted = await verifyCurrentSessionAgreement(
        expectedSessionNonce: sessionNonce,
        appId: appId,
      );
      if (!serverAccepted) {
        failureReason = 'server_metadata_verification_failed';
      }
    } catch (error) {
      failureReason = error.toString();
      developer.log(
        'Failed to persist/verify admin internal-use agreement: $error',
        name: _logName,
      );
    }

    final record = AdminInternalUseAgreementRecord(
      timestamp: DateTime.now().toUtc(),
      userId: userId,
      sessionNonce: sessionNonce,
      appId: appId,
      agreementVersion: agreementVersion,
      serverAccepted: serverAccepted,
      failureReason: failureReason,
    );
    await _appendRecord(record);

    await _prefs.setString(_sessionNonceKey, sessionNonce);
    await _auditLogService.logSecurityEvent(
      'admin_internal_use_agreement',
      userId,
      serverAccepted ? 'success' : 'failure',
      metadata: <String, dynamic>{
        'app_id': appId,
        'session_nonce': sessionNonce,
        'agreement_version': agreementVersion,
        if (agreementText.isNotEmpty) 'agreement_text': agreementText,
        if (failureReason != null) 'failure_reason': failureReason,
      },
    );

    return serverAccepted;
  }

  Future<bool> verifyCurrentSessionAgreement({
    String? expectedSessionNonce,
    String appId = 'admin_app',
  }) async {
    try {
      final client = _supabaseService.tryGetClient();
      if (client == null) {
        return false;
      }
      final user = client.auth.currentUser;
      if (user == null) {
        return false;
      }

      final metadata = user.userMetadata ?? const <String, dynamic>{};
      final acceptedAtRaw = metadata['admin_internal_use_accepted_at'];
      final nonce = metadata['admin_internal_use_nonce'] as String?;
      final app = metadata['admin_internal_use_app'] as String?;
      final acceptedAt = acceptedAtRaw is String
          ? DateTime.tryParse(acceptedAtRaw)?.toUtc()
          : null;
      if (acceptedAt == null) {
        return false;
      }
      if (app != appId) {
        return false;
      }

      final localExpectedNonce =
          expectedSessionNonce ?? _prefs.getString(_sessionNonceKey);
      if (localExpectedNonce == null || localExpectedNonce.isEmpty) {
        return false;
      }
      return nonce == localExpectedNonce;
    } catch (_) {
      return false;
    }
  }

  Future<void> clearSessionAgreementState() async {
    await _prefs.remove(_sessionNonceKey);
  }

  List<AdminInternalUseAgreementRecord> listRecent({int? limit}) {
    final raw = _prefs.getStringList(_eventsKey) ?? const <String>[];
    final out = <AdminInternalUseAgreementRecord>[];
    for (final row in raw) {
      try {
        out.add(
          AdminInternalUseAgreementRecord.fromJson(
            jsonDecode(row) as Map<String, dynamic>,
          ),
        );
      } catch (_) {
        // Ignore malformed entries.
      }
    }
    out.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    if (limit == null || out.length <= limit) {
      return out;
    }
    return out.sublist(0, limit);
  }

  String exportJson(List<AdminInternalUseAgreementRecord> events) {
    return const JsonEncoder.withIndent('  ')
        .convert(events.map((event) => event.toJson()).toList());
  }

  Future<void> _appendRecord(AdminInternalUseAgreementRecord record) async {
    final existing = _prefs.getStringList(_eventsKey) ?? const <String>[];
    final next = <String>[...existing, jsonEncode(record.toJson())];
    final capped = next.length <= _maxEvents
        ? next
        : next.sublist(next.length - _maxEvents);
    await _prefs.setStringList(_eventsKey, capped);
  }
}
