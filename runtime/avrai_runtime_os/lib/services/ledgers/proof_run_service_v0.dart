import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'package:avrai_runtime_os/services/background/background_wake_execution_run_record_store.dart';
import 'package:avrai_runtime_os/services/ledgers/ledger_domain_v0.dart';
import 'package:avrai_runtime_os/services/ledgers/ledger_recorder_service_v0.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_runtime_os/services/passive_collection/passive_dwell_reality_learning_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';
import 'package:avrai_runtime_os/services/validation/domain_execution_field_scenario_proof_store.dart';

/// Debug-only: Skeptic-proof “proof run” receipts + export.
///
/// This service records run-scoped ledger receipts (`entity_type='proof_run'`,
/// `entity_id=<run_id>`) and can export receipts to files that host scripts can
/// pull from an iOS simulator container.
///
/// **Truth note:** This does not claim BLE transport occurred. If the proof run
/// records an AI2AI encounter on iOS simulator, it must explicitly mark it as
/// simulated in the receipt payload.
class ProofRunServiceV0 {
  static const String _logName = 'ProofRunServiceV0';

  static const String _prefsKeyActiveRunId = 'proof_run_active_id_v1';
  static const String _prefsKeyActiveRunStartedAtMs =
      'proof_run_active_started_at_ms_v1';
  static const String _prefsKeyLastRunId = 'proof_run_last_id_v1';

  final LedgerRecorderServiceV0 _ledger;
  final SupabaseService _supabase;
  final SharedPreferencesCompat _prefs;
  final Uuid _uuid;
  final BackgroundWakeExecutionRunRecordStore? _backgroundWakeRunRecordStore;
  final DomainExecutionFieldScenarioProofStore? _fieldScenarioProofStore;
  final AmbientSocialRealityLearningService? _ambientSocialLearningService;

  ProofRunServiceV0({
    required LedgerRecorderServiceV0 ledger,
    required SupabaseService supabase,
    required SharedPreferencesCompat prefs,
    BackgroundWakeExecutionRunRecordStore? backgroundWakeRunRecordStore,
    DomainExecutionFieldScenarioProofStore? fieldScenarioProofStore,
    AmbientSocialRealityLearningService? ambientSocialLearningService,
    Uuid? uuid,
  })  : _ledger = ledger,
        _supabase = supabase,
        _prefs = prefs,
        _backgroundWakeRunRecordStore = backgroundWakeRunRecordStore,
        _fieldScenarioProofStore = fieldScenarioProofStore,
        _ambientSocialLearningService = ambientSocialLearningService,
        _uuid = uuid ?? const Uuid();

  String? getActiveRunId() => _prefs.getString(_prefsKeyActiveRunId);

  int getActiveRunStartedAtMs() =>
      _prefs.getInt(_prefsKeyActiveRunStartedAtMs) ?? 0;

  /// Start a new proof run and record a ledger receipt.
  ///
  /// Returns the new `runId`.
  Future<String> startRun({
    Map<String, Object?> payload = const <String, Object?>{},
  }) async {
    if (kIsWeb) {
      throw UnsupportedError('Proof run artifacts are not supported on web.');
    }
    if (!kDebugMode) {
      throw StateError('ProofRunServiceV0 is debug-only');
    }

    final runId = _uuid.v4();
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await _prefs.setString(_prefsKeyActiveRunId, runId);
    await _prefs.setInt(_prefsKeyActiveRunStartedAtMs, nowMs);
    await _prefs.setString(_prefsKeyLastRunId, runId);

    await recordMilestone(
      runId: runId,
      eventType: 'proof_run_started',
      payload: <String, Object?>{
        'run_id': runId,
        'started_at_ms': nowMs,
        ...payload,
      },
    );
    return runId;
  }

  /// Record a milestone receipt.
  ///
  /// This writes to the shared v0 ledger and also stores a local receipt copy
  /// so exports still work when offline (or before outbox flush).
  Future<void> recordMilestone({
    required String runId,
    required String eventType,
    Map<String, Object?> payload = const <String, Object?>{},
  }) async {
    if (kIsWeb) {
      throw UnsupportedError('Proof run artifacts are not supported on web.');
    }
    if (!kDebugMode) {
      throw StateError('ProofRunServiceV0 is debug-only');
    }

    final occurredAt = DateTime.now().toUtc();
    final mergedPayload = <String, Object?>{
      'run_id': runId,
      'client_utc': occurredAt.toIso8601String(),
      ...payload,
    };

    String logicalId = _uuid.v4();
    bool ledgerWriteOk = false;
    try {
      final ev = await _ledger.append(
        domain: LedgerDomainV0.security,
        eventType: eventType,
        occurredAt: occurredAt,
        entityType: 'proof_run',
        entityId: runId,
        payload: mergedPayload,
        source: 'client_proof_run',
        correlationId: runId,
      );
      logicalId = ev.logicalId;
      ledgerWriteOk = true;
    } catch (e, st) {
      developer.log(
        'Ledger write failed for proof run milestone; keeping local receipt',
        name: _logName,
        error: e,
        stackTrace: st,
      );
    }

    await _appendLocalReceipt(
      runId: runId,
      receipt: <String, Object?>{
        'event_type': eventType,
        'occurred_at': occurredAt.toIso8601String(),
        'logical_id': logicalId,
        'ledger_write_ok': ledgerWriteOk,
        'payload': mergedPayload,
      },
    );
  }

  /// Finish the active run (records a receipt and clears active run id).
  Future<void> finishActiveRun(
      {Map<String, Object?> payload = const {}}) async {
    final runId = getActiveRunId();
    if (runId == null || runId.isEmpty) return;

    await recordMilestone(
      runId: runId,
      eventType: 'proof_run_finished',
      payload: payload,
    );

    await _prefs.remove(_prefsKeyActiveRunId);
    await _prefs.remove(_prefsKeyActiveRunStartedAtMs);
  }

  /// Export receipts for a run into app Documents:
  /// `<Documents>/proof_runs/<runId>/ledger_rows.jsonl` + `.csv`.
  ///
  /// Returns the created directory.
  Future<Directory> exportRunReceipts({required String runId}) async {
    if (kIsWeb) {
      throw UnsupportedError('Proof run artifacts are not supported on web.');
    }
    if (!kDebugMode) {
      throw StateError('ProofRunServiceV0 is debug-only');
    }

    final local = await _readLocalReceipts(runId: runId);
    final remote = await _tryFetchRemoteLedgerRows(runId: runId);

    // Build an index from remote rows so we can attach DB row IDs to local receipts.
    final remoteByLogical = <String, Map<String, Object?>>{};
    for (final row in remote) {
      final logical = row['logical_id'] as String?;
      if (logical == null || logical.isEmpty) continue;
      remoteByLogical[logical] = row;
    }

    final combined = <Map<String, Object?>>[];
    for (final r in local) {
      final logical = r['logical_id'] as String?;
      final remoteRow = (logical != null) ? remoteByLogical[logical] : null;
      combined.add(<String, Object?>{
        ...r,
        if (remoteRow != null) 'row_id': remoteRow['id'],
      });
    }

    // If we have remote rows that weren’t locally tracked (should be rare), append them.
    for (final row in remote) {
      final logical = row['logical_id'] as String?;
      if (logical == null || logical.isEmpty) continue;
      final already =
          combined.any((e) => (e['logical_id'] as String?) == logical);
      if (already) continue;
      combined.add(<String, Object?>{
        'event_type': row['event_type'],
        'occurred_at': row['occurred_at'],
        'logical_id': logical,
        'row_id': row['id'],
        'ledger_write_ok': true,
        'payload': row['payload'],
      });
    }

    combined.sort((a, b) {
      final at = a['occurred_at']?.toString() ?? '';
      final bt = b['occurred_at']?.toString() ?? '';
      return at.compareTo(bt);
    });

    final docsDir = await getApplicationDocumentsDirectory();
    final outDir = Directory(p.join(docsDir.path, 'proof_runs', runId));
    if (!await outDir.exists()) {
      await outDir.create(recursive: true);
    }

    final jsonl = File(p.join(outDir.path, 'ledger_rows.jsonl'));
    final csv = File(p.join(outDir.path, 'ledger_rows.csv'));
    final backgroundRunsJson =
        File(p.join(outDir.path, 'background_wake_runs.json'));
    final fieldProofsJson =
        File(p.join(outDir.path, 'field_validation_proofs.json'));
    final ambientDiagnosticsJson =
        File(p.join(outDir.path, 'ambient_social_diagnostics.json'));

    final sink = jsonl.openWrite();
    try {
      for (final row in combined) {
        sink.writeln(jsonEncode(row));
      }
    } finally {
      await sink.flush();
      await sink.close();
    }

    final csvLines = <String>[
      'occurred_at,event_type,logical_id,row_id,ledger_write_ok',
      ...combined.map((row) {
        String esc(String? v) {
          final s = (v ?? '').replaceAll('"', '""');
          return '"$s"';
        }

        final occurredAt = row['occurred_at']?.toString();
        final eventType = row['event_type']?.toString();
        final logicalId = row['logical_id']?.toString();
        final rowId = row['row_id']?.toString();
        final ok = row['ledger_write_ok']?.toString();
        return [
          esc(occurredAt),
          esc(eventType),
          esc(logicalId),
          esc(rowId),
          esc(ok),
        ].join(',');
      }),
    ];
    await csv.writeAsString(csvLines.join('\n'), flush: true);
    await backgroundRunsJson.writeAsString(
      _backgroundWakeRunRecordStore?.exportRecentRuns(limit: 12) ??
          '{"exported_at_utc":"${DateTime.now().toUtc().toIso8601String()}","runs":[]}',
      flush: true,
    );
    await fieldProofsJson.writeAsString(
      _fieldScenarioProofStore?.exportRecentProofBundles(limit: 12) ??
          '{"exported_at_utc":"${DateTime.now().toUtc().toIso8601String()}","proofs":[]}',
      flush: true,
    );
    await ambientDiagnosticsJson.writeAsString(
      const JsonEncoder.withIndent('  ').convert(
        (_ambientSocialLearningService
                    ?.snapshot(capturedAtUtc: DateTime.now().toUtc())
                    .toJson() ??
                <String, dynamic>{
                  'captured_at_utc': DateTime.now().toUtc().toIso8601String(),
                  'normalized_observation_count': 0,
                  'candidate_copresence_observation_count': 0,
                  'confirmed_interaction_promotion_count': 0,
                  'duplicate_merge_count': 0,
                  'rejected_interaction_promotion_count': 0,
                  'crowd_upgrade_count': 0,
                  'what_ingestion_count': 0,
                  'locality_vibe_update_count': 0,
                  'personal_dna_authorized_count': 0,
                  'personal_dna_applied_count': 0,
                  'latest_nearby_peer_count': 0,
                  'latest_confirmed_interactive_peer_count': 0,
                  'recent_promotion_traces': const <dynamic>[],
                }),
      ),
      flush: true,
    );

    developer.log(
      'Exported proof run receipts for runId=$runId to ${outDir.path}',
      name: _logName,
    );
    return outDir;
  }

  // ---------------------------------------------------------------------------
  // Local receipt storage helpers (so exports work even offline)
  // ---------------------------------------------------------------------------

  String _receiptsKey(String runId) => 'proof_run_receipts_v1_$runId';

  Future<void> _appendLocalReceipt({
    required String runId,
    required Map<String, Object?> receipt,
  }) async {
    try {
      final key = _receiptsKey(runId);
      final existing = _prefs.getStringList(key) ?? const <String>[];
      final next = <String>[...existing, jsonEncode(receipt)];
      await _prefs.setStringList(key, next);
    } catch (e, st) {
      developer.log(
        'Failed writing local proof run receipt',
        name: _logName,
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<List<Map<String, Object?>>> _readLocalReceipts({
    required String runId,
  }) async {
    final key = _receiptsKey(runId);
    final list = _prefs.getStringList(key) ?? const <String>[];
    final out = <Map<String, Object?>>[];
    for (final s in list) {
      try {
        final decoded = jsonDecode(s);
        if (decoded is Map) {
          out.add(decoded.cast<String, Object?>());
        }
      } catch (_) {
        // Skip malformed entries.
      }
    }
    return out;
  }

  Future<List<Map<String, Object?>>> _tryFetchRemoteLedgerRows({
    required String runId,
  }) async {
    try {
      if (!_supabase.isAvailable) return const [];
      final user = _supabase.currentUser;
      if (user == null) return const [];

      final rows = await _supabase.client
          .from('ledger_events_v0')
          .select('id, logical_id, occurred_at, event_type, payload')
          .eq('owner_user_id', user.id)
          .eq('entity_type', 'proof_run')
          .eq('entity_id', runId)
          .order('occurred_at', ascending: true);

      return rows
          .whereType<Map>()
          .map((e) => e.cast<String, Object?>())
          .toList(growable: false);
    } catch (e, st) {
      developer.log(
        'Remote proof run ledger query failed (non-fatal)',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return const [];
    }
  }
}
