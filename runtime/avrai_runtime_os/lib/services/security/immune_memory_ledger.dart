import 'dart:convert';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;

class ImmuneMemoryLedger {
  ImmuneMemoryLedger({
    SharedPreferencesCompat? prefs,
    DateTime Function()? nowProvider,
  })  : _prefs = prefs,
        _nowProvider = nowProvider ?? (() => DateTime.now().toUtc());

  static const String _findingsKey = 'security.immune.findings.v1';
  static const String _memoryKey = 'security.immune.memory.v1';
  static const String _learningMomentsKey = 'security.immune.learning.v1';
  static const String _bundleCandidatesKey =
      'security.immune.bundle_candidates.v1';
  static const String _propagationReceiptsKey =
      'security.immune.propagation_receipts.v1';
  static const int _maxStoredEntries = 128;

  final SharedPreferencesCompat? _prefs;
  final DateTime Function() _nowProvider;

  List<SecurityFinding> recentFindings({int limit = 20}) =>
      _take(_readList(_findingsKey, SecurityFinding.fromJson), limit);

  List<ImmuneMemoryRecord> recentMemory({int limit = 20}) =>
      _take(_readList(_memoryKey, ImmuneMemoryRecord.fromJson), limit);

  List<SecurityLearningMoment> recentLearningMoments({int limit = 20}) => _take(
        _readList(_learningMomentsKey, SecurityLearningMoment.fromJson),
        limit,
      );

  List<CountermeasureBundleCandidate> bundleCandidates({int limit = 20}) =>
      _take(
        _readList(
          _bundleCandidatesKey,
          CountermeasureBundleCandidate.fromJson,
        ),
        limit,
      );

  CountermeasureBundleCandidate? bundleCandidateByBundleId(String bundleId) {
    for (final candidate in _readList(
      _bundleCandidatesKey,
      CountermeasureBundleCandidate.fromJson,
    )) {
      if (candidate.bundle.bundleId == bundleId) {
        return candidate;
      }
    }
    return null;
  }

  List<CountermeasurePropagationReceipt> propagationReceipts({
    int limit = 20,
  }) =>
      _take(
        _readList(
          _propagationReceiptsKey,
          CountermeasurePropagationReceipt.fromJson,
        ),
        limit,
      );

  CountermeasurePropagationReceipt? propagationReceiptById(String receiptId) {
    for (final receipt in _readList(
      _propagationReceiptsKey,
      CountermeasurePropagationReceipt.fromJson,
    )) {
      if (receipt.receiptId == receiptId) {
        return receipt;
      }
    }
    return null;
  }

  List<CountermeasurePropagationReceipt> propagationReceiptsForBundle(
    String bundleId,
  ) {
    return _readList(
      _propagationReceiptsKey,
      CountermeasurePropagationReceipt.fromJson,
    ).where((entry) => entry.bundleId == bundleId).toList(growable: false);
  }

  Future<void> recordFinding(SecurityFinding finding) async {
    await _writeEntry(_findingsKey, finding.toJson(), identity: finding.id);
  }

  Future<void> recordImmuneMemory(ImmuneMemoryRecord record) async {
    await _writeEntry(_memoryKey, record.toJson(), identity: record.id);
  }

  Future<void> recordLearningMoment(SecurityLearningMoment moment) async {
    await _writeEntry(
      _learningMomentsKey,
      moment.toJson(),
      identity: moment.id,
    );
  }

  Future<void> upsertBundleCandidate(
    CountermeasureBundleCandidate candidate,
  ) async {
    await _writeEntry(
      _bundleCandidatesKey,
      candidate.toJson(),
      identity: candidate.candidateId,
    );
  }

  Future<void> recordPropagationReceipt(
    CountermeasurePropagationReceipt receipt,
  ) async {
    await _writeEntry(
      _propagationReceiptsKey,
      receipt.toJson(),
      identity: receipt.receiptId,
    );
  }

  Future<SecurityLearningMoment> recordLearningMomentForFinding({
    required SecurityFinding finding,
    required SecurityLearningMomentKind kind,
    bool falsePositive = false,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) async {
    final moment = SecurityLearningMoment(
      id: 'learn_${finding.id}_${_nowProvider().millisecondsSinceEpoch}',
      truthScope: finding.truthScope,
      runId: finding.campaignRunId,
      kind: kind,
      disposition: finding.disposition,
      summary: finding.summary,
      createdAt: _nowProvider(),
      evidenceTraceIds: finding.evidenceTraceIds,
      recurrenceCount: finding.recurrenceCount,
      falsePositive: falsePositive,
      metadata: <String, dynamic>{
        'finding_id': finding.id,
        ...metadata,
      },
    );
    await recordLearningMoment(moment);
    return moment;
  }

  Future<void> captureFindingAsImmuneMemory(SecurityFinding finding) async {
    final memory = ImmuneMemoryRecord(
      id: 'memory_${finding.id}',
      truthScope: finding.truthScope,
      createdAt: _nowProvider(),
      signature: '${finding.truthScope.scopeKey}:${finding.title}',
      preconditions: _stringListFromMetadata(finding.metadata['preconditions']),
      affectedSurfaces: <String>[
        finding.truthScope.sphereId,
        ..._stringListFromMetadata(finding.metadata['affected_surfaces']),
      ],
      containmentActions: _stringListFromMetadata(
        finding.metadata['containment_actions'],
      ),
      falsePositive: false,
      recurrenceRiskTag: finding.recurrenceCount > 1 ? 'elevated' : 'new',
      evidenceTraceIds: finding.evidenceTraceIds,
      metadata: <String, dynamic>{
        'finding_id': finding.id,
        'severity': finding.severity.name,
        'invariant_breach': finding.invariantBreach,
        ...finding.metadata,
      },
    );
    await recordImmuneMemory(memory);
  }

  List<T> _readList<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    return _readEncodedList(key).map(fromJson).toList(growable: false);
  }

  Future<void> _writeEntry(
    String key,
    Map<String, dynamic> payload, {
    required String identity,
  }) async {
    final prefs = _prefs;
    if (prefs == null) {
      return;
    }
    final encoded = _readEncodedList(key).toList(growable: true);
    encoded.removeWhere((entry) => entry['identity'] == identity);
    encoded.insert(
      0,
      <String, dynamic>{
        'identity': identity,
        'payload': payload,
      },
    );
    if (encoded.length > _maxStoredEntries) {
      encoded.removeRange(_maxStoredEntries, encoded.length);
    }
    await prefs.setString(key, jsonEncode(encoded));
  }

  List<Map<String, dynamic>> _readEncodedList(String key) {
    final prefs = _prefs;
    if (prefs == null) {
      return const <Map<String, dynamic>>[];
    }
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) {
      return const <Map<String, dynamic>>[];
    }
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const <Map<String, dynamic>>[];
    }
    return decoded.whereType<Map>().map((entry) {
      final typed = Map<String, dynamic>.from(entry);
      final payload = Map<String, dynamic>.from(
        typed['payload'] is Map ? typed['payload'] as Map : typed,
      );
      return <String, dynamic>{
        'identity': typed['identity'] ?? payload['identity'],
        ...payload,
      };
    }).toList(growable: false);
  }

  List<T> _take<T>(List<T> values, int limit) {
    final normalizedLimit = limit.clamp(0, values.length);
    if (normalizedLimit == 0) {
      return <T>[];
    }
    return values.take(normalizedLimit).toList(growable: false);
  }

  List<String> _stringListFromMetadata(dynamic value) {
    if (value is List) {
      return value.map((entry) => entry.toString()).toList(growable: false);
    }
    return const <String>[];
  }
}
