import 'dart:developer' as developer;

import 'package:get_it/get_it.dart';

import 'package:avrai/core/services/user/agent_id_service.dart';
import 'package:avrai/core/services/ledgers/ledger_domain_v0.dart';
import 'package:avrai/core/services/ledgers/ledger_recorder_service_v0.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart';
import 'package:avrai/core/services/infrastructure/supabase_service.dart';

/// Gated Ledgers v0 “receipts” emitter for device runs and smoke tests.
///
/// This is intentionally **best-effort**:
/// - Disabled by default (no production spam).
/// - Never throws to callers.
/// - Requires an explicit correlation id so receipts can be queried as a run.
///
/// Enable with:
/// - `--dart-define=SPOTS_LEDGER_AUDIT=true`
/// - `--dart-define=SPOTS_LEDGER_AUDIT_CORRELATION_ID=<runId>`
class LedgerAuditV0 {
  static const bool _enabled =
      bool.fromEnvironment('SPOTS_LEDGER_AUDIT', defaultValue: false);
  static const String _correlationId = String.fromEnvironment(
    'SPOTS_LEDGER_AUDIT_CORRELATION_ID',
    defaultValue: '',
  );

  static const String _logName = 'LedgerAuditV0';
  static LedgerRecorderServiceV0? _fallbackLedger;

  /// True only when audit is enabled *and* a correlation id was provided.
  static bool get isEnabled => _enabled && _correlationId.isNotEmpty;

  /// Correlation id used for all emitted receipts.
  static String get correlationId => _correlationId;

  /// Append a v0 ledger receipt, best-effort.
  ///
  /// Notes:
  /// - Requires DI to have `LedgerRecorderServiceV0` registered.
  /// - Requires authenticated user (RLS); otherwise this is a no-op.
  static Future<void> tryAppend({
    required LedgerDomainV0 domain,
    required String eventType,
    required DateTime occurredAt,
    required Map<String, Object?> payload,
    String? entityType,
    String? entityId,
    String? category,
    String? cityCode,
    String? localityCode,
    String source = 'client_audit',
  }) async {
    if (!isEnabled) return;

    final ledger = _tryResolveLedger();
    if (ledger == null) return;

    try {
      await ledger.append(
        domain: domain,
        eventType: eventType,
        occurredAt: occurredAt,
        payload: payload,
        entityType: entityType,
        entityId: entityId,
        category: category,
        cityCode: cityCode,
        localityCode: localityCode,
        source: source,
        correlationId: _correlationId,
      );
    } catch (e, st) {
      // This must never block the caller flow.
      developer.log(
        'Ledger audit append skipped/failed for $eventType: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
    }
  }

  static LedgerRecorderServiceV0? _tryResolveLedger() {
    try {
      final sl = GetIt.instance;
      if (sl.isRegistered<LedgerRecorderServiceV0>()) {
        return sl<LedgerRecorderServiceV0>();
      }
    } catch (_) {
      // Fall through to best-effort local construction.
    }

    // Fallback: construct a local ledger writer for tests/smoke tools that
    // don't initialize GetIt. This is best-effort and should still be a no-op
    // if the user isn't authenticated.
    _fallbackLedger ??= LedgerRecorderServiceV0(
      supabaseService: SupabaseService(),
      agentIdService: AgentIdService(),
      storage: StorageService.instance,
    );
    return _fallbackLedger;
  }
}

