import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:uuid/uuid.dart';

import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'package:avrai_runtime_os/services/ledgers/ledger_domain_v0.dart';
import 'package:avrai_runtime_os/services/ledgers/ledger_event_v0.dart';
import 'package:avrai_runtime_os/services/ledgers/ledger_op_v0.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';

/// Writes v0 ledger events to Supabase with an offline outbox fallback.
///
/// - Primary sink: `public.ledger_events_v0` (append-only).
/// - Offline fallback: local outbox in `StorageService` that can be flushed later.
///
/// Notes:
/// - RLS requires the authenticated user to insert `owner_user_id = auth.uid()`.
/// - `owner_agent_id` is recorded for privacy-safe ai2ai routing (not used for RLS).
class LedgerRecorderServiceV0 {
  static const String _logName = 'LedgerRecorderServiceV0';
  static const String _outboxKey = 'ledger_outbox_v0';
  static const String _receiptsEdgeFunctionName = 'ledger-receipts-v0';

  final SupabaseService _supabaseService;
  final AgentIdService _agentIdService;
  final StorageService _storage;
  final AppLogger _logger;
  final Uuid _uuid;

  LedgerRecorderServiceV0({
    required SupabaseService supabaseService,
    required AgentIdService agentIdService,
    required StorageService storage,
    AppLogger? logger,
    Uuid? uuid,
  })  : _supabaseService = supabaseService,
        _agentIdService = agentIdService,
        _storage = storage,
        _logger = logger ??
            const AppLogger(
                defaultTag: 'Ledgers', minimumLevel: LogLevel.debug),
        _uuid = uuid ?? const Uuid();

  /// Debug-only: write one row and verify it is readable immediately.
  ///
  /// This is a smoke test for:
  /// - Supabase connectivity
  /// - RLS correctness (owner_user_id = auth.uid)
  /// - Ledger schema existence (`ledger_events_v0`, `ledger_current_v0`)
  ///
  /// Throws in release/profile builds.
  Future<({String logicalId, String? insertedRowId})>
      debugWriteAndVerifyImmediate() async {
    if (!kDebugMode) {
      throw StateError('debugWriteAndVerifyImmediate is debug-only');
    }

    final entityId = 'debug_${DateTime.now().millisecondsSinceEpoch}';
    final ev = await append(
      domain: LedgerDomainV0.security,
      eventType: 'debug_smoke_test',
      occurredAt: DateTime.now(),
      entityType: 'debug',
      entityId: entityId,
      payload: <String, Object?>{
        'notes': 'debug smoke test',
      },
      correlationId: entityId,
      source: 'client_debug',
    );

    if (!_supabaseService.isAvailable) {
      return (logicalId: ev.logicalId, insertedRowId: null);
    }

    // If the insert was queued (offline/outbox), this may be null.
    try {
      final row = await _supabaseService.client
          .from('ledger_events_v0')
          .select('id, logical_id')
          .eq('logical_id', ev.logicalId)
          .eq('revision', 0)
          .maybeSingle();
      final map = (row as Map?)?.cast<String, dynamic>();
      final rowId = map?['id'] as String?;
      return (logicalId: ev.logicalId, insertedRowId: rowId);
    } catch (e, st) {
      developer.log(
        'debugWriteAndVerifyImmediate verification failed',
        error: e,
        stackTrace: st,
        name: _logName,
      );
      return (logicalId: ev.logicalId, insertedRowId: null);
    }
  }

  /// Append a new logical event (`revision=0`, `op=assert`).
  ///
  /// If Supabase is not available or insert fails, the event is queued locally.
  Future<LedgerEventV0> append({
    required LedgerDomainV0 domain,
    required String eventType,
    required DateTime occurredAt,
    required Map<String, Object?> payload,
    String? entityType,
    String? entityId,
    String? category,
    String? cityCode,
    String? localityCode,
    String? atomicTimestampId,
    String source = 'client',
    String? correlationId,
  }) async {
    final user = _supabaseService.currentUser;
    if (user == null) {
      throw StateError('No authenticated user (ledger writes require auth)');
    }

    final ownerUserId = user.id;
    final ownerAgentId = await _agentIdService.getUserAgentId(ownerUserId);

    final logicalId = _uuid.v4();
    final event = LedgerEventV0(
      id: null,
      domain: domain,
      ownerUserId: ownerUserId,
      ownerAgentId: ownerAgentId,
      logicalId: logicalId,
      revision: 0,
      supersedesId: null,
      op: LedgerOpV0.assert_,
      eventType: eventType,
      entityType: entityType,
      entityId: entityId,
      category: category,
      cityCode: cityCode,
      localityCode: localityCode,
      occurredAt: occurredAt,
      atomicTimestampId: atomicTimestampId,
      payload: <String, Object?>{
        'source': source,
        if (correlationId != null) 'correlation_id': correlationId,
        ...payload,
      },
      createdAt: null,
    );

    return _tryInsertOrQueue(event);
  }

  /// Append a revision for an existing logical event.
  ///
  /// This:
  /// - reads the current revision from `ledger_current_v0`
  /// - inserts a new row with `revision = prev + 1` and `supersedes_id = prev.id`
  ///
  /// If Supabase is unavailable or the insert fails, the revision is queued locally.
  Future<LedgerEventV0> appendRevision({
    required LedgerDomainV0 domain,
    required String logicalId,
    required String eventType,
    required LedgerOpV0 op,
    required DateTime occurredAt,
    required Map<String, Object?> payload,
    String source = 'client',
    String? correlationId,
  }) async {
    final user = _supabaseService.currentUser;
    if (user == null) {
      throw StateError('No authenticated user (ledger writes require auth)');
    }

    final ownerUserId = user.id;
    final ownerAgentId = await _agentIdService.getUserAgentId(ownerUserId);

    final current = await _getCurrentByLogicalId(
      domain: domain,
      logicalId: logicalId,
    );

    if (current != null && current.eventType != eventType) {
      throw StateError(
        'Revision event_type mismatch: current=${current.eventType} requested=$eventType',
      );
    }

    final nextRevision = current == null ? 0 : current.revision + 1;
    final supersedesId = current?.id;

    final event = LedgerEventV0(
      id: null,
      domain: domain,
      ownerUserId: ownerUserId,
      ownerAgentId: ownerAgentId,
      logicalId: logicalId,
      revision: nextRevision,
      supersedesId: supersedesId,
      op: op,
      eventType: current?.eventType ?? eventType,
      entityType: current?.entityType,
      entityId: current?.entityId,
      category: current?.category,
      cityCode: current?.cityCode,
      localityCode: current?.localityCode,
      occurredAt: occurredAt,
      atomicTimestampId: current?.atomicTimestampId,
      payload: <String, Object?>{
        'source': source,
        if (correlationId != null) 'correlation_id': correlationId,
        ...payload,
      },
      createdAt: null,
    );

    return _tryInsertOrQueue(event);
  }

  /// Flush locally queued ledger events to Supabase (best-effort).
  ///
  /// Returns the number of events successfully inserted.
  Future<int> flushOutbox() async {
    if (!_supabaseService.isAvailable) return 0;
    if (_supabaseService.currentUser == null) return 0;

    final outbox = _readOutbox();
    if (outbox.isEmpty) return 0;

    final remaining = <Map<String, Object?>>[];
    int inserted = 0;

    for (final queued in outbox) {
      try {
        final insertMap = queued['insert'] as Map<String, Object?>?;
        if (insertMap == null) {
          continue;
        }
        final signedOk = await _tryAppendSignedViaEdge(insertMap);
        if (!signedOk) {
          await _supabaseService.client
              .from('ledger_events_v0')
              .insert(insertMap);
        }
        inserted += 1;
      } catch (e, st) {
        remaining.add(queued);
        _logger.warn(
          'Failed flushing ledger outbox row; keeping queued. error=$e',
          tag: _logName,
        );
        developer.log('Flush error', error: e, stackTrace: st, name: _logName);
      }
    }

    await _writeOutbox(remaining);
    if (inserted > 0) {
      _logger.info('Flushed $inserted ledger rows', tag: _logName);
    }
    return inserted;
  }

  // ===========================================================================
  // Internal helpers
  // ===========================================================================

  Future<LedgerEventV0?> _getCurrentByLogicalId({
    required LedgerDomainV0 domain,
    required String logicalId,
  }) async {
    try {
      if (!_supabaseService.isAvailable) return null;
      final client = _supabaseService.client;
      final row = await client
          .from('ledger_current_v0')
          .select('*')
          .eq('domain', domain.wireName)
          .eq('logical_id', logicalId)
          .maybeSingle();
      if (row == null) return null;
      return LedgerEventV0.fromSupabaseRow(
          (row as Map).cast<String, dynamic>());
    } catch (e, st) {
      developer.log('Failed reading ledger_current_v0',
          error: e, stackTrace: st, name: _logName);
      return null;
    }
  }

  Future<LedgerEventV0> _tryInsertOrQueue(LedgerEventV0 event) async {
    final insertMap = event.toInsertMap();
    if (!_supabaseService.isAvailable) {
      await _queue(insertMap);
      return event;
    }

    try {
      // Prefer a signed receipt write-path. If it fails (e.g., function not deployed),
      // fall back to a direct insert (still append-only; can be signed later via sign_existing).
      final signedOk = await _tryAppendSignedViaEdge(insertMap);
      if (!signedOk) {
        await _supabaseService.client
            .from('ledger_events_v0')
            .insert(insertMap);
      }
      return event;
    } catch (e, st) {
      _logger.warn(
        'Ledger insert failed; queued locally. domain=${event.domain.wireName} type=${event.eventType} error=$e',
        tag: _logName,
      );
      developer.log('Ledger insert failed',
          error: e, stackTrace: st, name: _logName);
      await _queue(insertMap);
      return event;
    }
  }

  Future<bool> _tryAppendSignedViaEdge(Map<String, Object?> insertMap) async {
    try {
      final res = await _supabaseService.client.functions.invoke(
        _receiptsEdgeFunctionName,
        body: jsonEncode(<String, Object?>{
          'action': 'append_signed',
          'insert': insertMap,
        }),
      );

      if (res.status != 200) {
        _logger.warn(
          'Signed ledger append failed: status=${res.status} data=${res.data}',
          tag: _logName,
        );
        return false;
      }

      // Best-effort parse; we only need to know success.
      final data =
          (res.data is String) ? jsonDecode(res.data as String) : res.data;
      if (data is Map && data['ok'] == true) return true;
      return true;
    } catch (e, st) {
      developer.log(
        'Signed ledger append via edge function failed',
        error: e,
        stackTrace: st,
        name: _logName,
      );
      return false;
    }
  }

  List<Map<String, Object?>> _readOutbox() {
    try {
      final stored =
          _storage.getObject<List<dynamic>>(_outboxKey, box: 'spots_user');
      if (stored == null) return const [];
      return stored
          .whereType<Map>()
          .map((e) => e.cast<String, Object?>())
          .toList(growable: true);
    } catch (_) {
      return const [];
    }
  }

  Future<void> _writeOutbox(List<Map<String, Object?>> outbox) async {
    try {
      await _storage.setObject(_outboxKey, outbox, box: 'spots_user');
    } catch (e, st) {
      // Storage might not be initialized yet; never fail the calling flow.
      developer.log('Failed writing ledger outbox',
          error: e, stackTrace: st, name: _logName);
    }
  }

  Future<void> _queue(Map<String, Object?> insertMap) async {
    try {
      final outbox = _readOutbox().toList(growable: true);
      outbox.add(<String, Object?>{
        'queued_at': DateTime.now().toIso8601String(),
        'insert': insertMap,
      });
      await _writeOutbox(outbox);
    } catch (e, st) {
      developer.log('Failed queueing ledger outbox',
          error: e, stackTrace: st, name: _logName);
    }
  }
}
