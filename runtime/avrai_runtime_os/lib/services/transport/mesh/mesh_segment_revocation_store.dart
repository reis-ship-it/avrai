import 'dart:async';

import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';

class MeshSegmentRevocationRecord {
  const MeshSegmentRevocationRecord({
    required this.id,
    required this.kind,
    required this.reason,
    required this.revokedAtUtc,
  });

  final String id;
  final MeshSegmentRevocationKind kind;
  final String reason;
  final DateTime revokedAtUtc;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'kind': kind.name,
        'reason': reason,
        'revoked_at_utc': revokedAtUtc.toUtc().toIso8601String(),
      };

  factory MeshSegmentRevocationRecord.fromJson(Map<String, dynamic> json) {
    return MeshSegmentRevocationRecord(
      id: json['id'] as String? ?? 'unknown',
      kind: MeshSegmentRevocationKind.values.byName(
        json['kind'] as String? ?? MeshSegmentRevocationKind.credential.name,
      ),
      reason: json['reason'] as String? ?? 'unknown',
      revokedAtUtc:
          DateTime.tryParse(json['revoked_at_utc'] as String? ?? '')?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }
}

enum MeshSegmentRevocationKind {
  credential,
  attestation,
}

class MeshSegmentRevocationStore {
  MeshSegmentRevocationStore({
    StorageService? storageService,
    Map<String, MeshSegmentRevocationRecord>? seededRevocations,
  })  : _storageService = storageService,
        _records = Map<String, MeshSegmentRevocationRecord>.from(
          seededRevocations ?? const <String, MeshSegmentRevocationRecord>{},
        );

  static const String _storageKey = 'mesh_segment_revocations_v1';

  final StorageService? _storageService;
  final Map<String, MeshSegmentRevocationRecord> _records;

  void revokeCredential(
    String credentialId, {
    required String reason,
    DateTime? revokedAtUtc,
  }) {
    final records = _readRecords();
    records['credential:$credentialId'] = MeshSegmentRevocationRecord(
      id: credentialId,
      kind: MeshSegmentRevocationKind.credential,
      reason: reason,
      revokedAtUtc: revokedAtUtc?.toUtc() ?? DateTime.now().toUtc(),
    );
    _writeRecords(records);
  }

  void revokeAttestation(
    String attestationId, {
    required String reason,
    DateTime? revokedAtUtc,
  }) {
    final records = _readRecords();
    records['attestation:$attestationId'] = MeshSegmentRevocationRecord(
      id: attestationId,
      kind: MeshSegmentRevocationKind.attestation,
      reason: reason,
      revokedAtUtc: revokedAtUtc?.toUtc() ?? DateTime.now().toUtc(),
    );
    _writeRecords(records);
  }

  bool isCredentialRevoked(String credentialId) =>
      _readRecords().containsKey('credential:$credentialId');

  bool isAttestationRevoked(String attestationId) =>
      _readRecords().containsKey('attestation:$attestationId');

  int credentialRevocationCount() => _readRecords()
      .values
      .where((entry) => entry.kind == MeshSegmentRevocationKind.credential)
      .length;

  int attestationRevocationCount() => _readRecords()
      .values
      .where((entry) => entry.kind == MeshSegmentRevocationKind.attestation)
      .length;

  Map<String, int> reasonCounts() {
    final counts = <String, int>{};
    for (final record in _readRecords().values) {
      counts[record.reason] = (counts[record.reason] ?? 0) + 1;
    }
    return counts;
  }

  List<MeshSegmentRevocationRecord> allRecords() {
    final records = _readRecords().values.toList(growable: false)
      ..sort((left, right) => right.revokedAtUtc.compareTo(left.revokedAtUtc));
    return records;
  }

  Map<String, MeshSegmentRevocationRecord> _readRecords() {
    final storage = _storageService;
    if (storage != null) {
      try {
        final raw = storage.getObject<Map<dynamic, dynamic>>(_storageKey,
            box: 'spots_ai');
        if (raw != null) {
          return raw.map(
            (key, value) => MapEntry(
              key.toString(),
              MeshSegmentRevocationRecord.fromJson(
                Map<String, dynamic>.from(value as Map),
              ),
            ),
          );
        }
      } on StateError {
        // Fall back to in-memory storage until StorageService is initialized.
      }
    }
    return Map<String, MeshSegmentRevocationRecord>.from(_records);
  }

  void _writeRecords(Map<String, MeshSegmentRevocationRecord> records) {
    _records
      ..clear()
      ..addAll(records);
    final storage = _storageService;
    if (storage == null) {
      return;
    }
    try {
      unawaited(storage.setObject(
        _storageKey,
        records.map((key, value) => MapEntry(key, value.toJson())),
        box: 'spots_ai',
      ));
    } on StateError {
      // Fall back to in-memory storage until StorageService is initialized.
    }
  }
}
