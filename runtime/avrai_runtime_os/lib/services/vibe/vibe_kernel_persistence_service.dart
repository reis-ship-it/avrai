import 'dart:developer' as developer;

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:reality_engine/reality_engine.dart';

class VibeKernelPersistenceService implements VibeKernelPersistenceBridge {
  VibeKernelPersistenceService({
    required StorageService storage,
    VibeKernel? vibeKernel,
    TrajectoryKernel? trajectoryKernel,
  })  : _storage = storage,
        _vibeKernel = vibeKernel ?? VibeKernel(),
        _trajectoryKernel = trajectoryKernel ?? TrajectoryKernel() {
    VibeKernelRuntimeBindings.persistenceBridge = this;
  }

  static const String box = 'spots_ai';
  static const String _manifestKey = 'vibe_kernel_manifest_v1';
  static const String _snapshotPrefix = 'vibe_kernel_snapshot_v3:';
  static const String _journalPrefix = 'trajectory_kernel_journal_v3:';
  static const String _legacyEnvelopeKey = 'vibe_kernel_snapshot_envelope_v2';
  static const String _legacyJournalKey = 'trajectory_kernel_journal_window_v1';
  static const String _logName = 'VibeKernelPersistenceService';

  final StorageService _storage;
  final VibeKernel _vibeKernel;
  final TrajectoryKernel _trajectoryKernel;

  Future<void> restore() async {
    try {
      final manifest = loadManifest();
      if (manifest != null) {
        final subjectSnapshots = <VibeStateSnapshot>[];
        final entitySnapshots = <EntityVibeSnapshot>[];
        final journalRecords = <TrajectoryMutationRecord>[];

        for (final subject in manifest.subjects) {
          final rawSnapshot = _storage.getObject<Map<String, dynamic>>(
            subject.snapshotStorageKey,
            box: box,
          );
          if (rawSnapshot != null) {
            if (subject.isEntitySnapshot) {
              entitySnapshots.add(EntityVibeSnapshot.fromJson(rawSnapshot));
            } else {
              subjectSnapshots.add(VibeStateSnapshot.fromJson(rawSnapshot));
            }
          }

          final rawJournal = _storage.getObject<List<dynamic>>(
            subject.journalStorageKey,
            box: box,
          );
          if (rawJournal != null) {
            journalRecords.addAll(
              rawJournal.map(
                (entry) => TrajectoryMutationRecord.fromJson(
                  Map<String, dynamic>.from(entry as Map),
                ),
              ),
            );
          }
        }

        _vibeKernel.importSnapshotEnvelope(
          VibeSnapshotEnvelope(
            exportedAtUtc: manifest.exportedAtUtc,
            subjectSnapshots: subjectSnapshots,
            entitySnapshots: entitySnapshots,
            migrationReceipts: manifest.migrationReceipts,
            metadata: <String, dynamic>{
              ...manifest.metadata,
              'migration_version': manifest.migrationVersion,
            },
            schemaVersion: manifest.schemaVersion,
          ),
        );
        _trajectoryKernel.importJournalWindow(
          records: _dedupeJournalRecords(journalRecords),
        );
        return;
      }

      final rawEnvelope = _storage.getObject<Map<String, dynamic>>(
        _legacyEnvelopeKey,
        box: box,
      );
      if (rawEnvelope != null) {
        _vibeKernel.importSnapshotEnvelope(
          VibeSnapshotEnvelope.fromJson(rawEnvelope),
        );
      }

      final rawJournal = _storage.getObject<List<dynamic>>(
        _legacyJournalKey,
        box: box,
      );
      if (rawJournal != null) {
        _trajectoryKernel.importJournalWindow(
          records: rawJournal
              .map(
                (entry) => TrajectoryMutationRecord.fromJson(
                  Map<String, dynamic>.from(entry as Map),
                ),
              )
              .toList(),
        );
      }
    } catch (error, stackTrace) {
      developer.log(
        'Failed to restore canonical vibe state: $error',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  VibeKernelManifest? loadManifest() {
    final rawManifest = _storage.getObject<Map<String, dynamic>>(
      _manifestKey,
      box: box,
    );
    if (rawManifest == null) {
      return null;
    }
    return VibeKernelManifest.fromJson(rawManifest);
  }

  Future<void> persistMigrationReceipt({
    required String receipt,
    required int migrationVersion,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) async {
    final current = loadManifest();
    final updatedReceipts = <String>{
      ...(current?.migrationReceipts ?? const <String>[]),
      receipt,
    }.toList()
      ..sort();
    final manifest = VibeKernelManifest(
      exportedAtUtc: DateTime.now().toUtc(),
      subjects: current?.subjects ?? const <VibeKernelManifestSubject>[],
      migrationVersion: migrationVersion,
      migrationReceipts: updatedReceipts,
      metadata: <String, dynamic>{
        ...(current?.metadata ?? const <String, dynamic>{}),
        ...metadata,
      },
      schemaVersion: current?.schemaVersion ?? 1,
    );
    await _storage.setObject(_manifestKey, manifest.toJson(), box: box);
  }

  @override
  Future<void> persistCanonicalState({
    required VibeSnapshotEnvelope envelope,
    required List<TrajectoryMutationRecord> journalWindow,
  }) async {
    try {
      final existingManifest = loadManifest();
      final manifest = _buildManifest(
        envelope: envelope,
        journalWindow: journalWindow,
        existingManifest: existingManifest,
      );

      for (final subject in manifest.subjects) {
        if (subject.isEntitySnapshot) {
          final snapshot = envelope.entitySnapshots.firstWhere(
            (entry) => _subjectMatches(entry.subjectRef, subject.subjectRef),
          );
          await _storage.setObject(
            subject.snapshotStorageKey,
            snapshot.toJson(),
            box: box,
          );
        } else {
          final snapshot = envelope.subjectSnapshots.firstWhere(
            (entry) => _subjectMatches(entry.subjectRef, subject.subjectRef),
          );
          await _storage.setObject(
            subject.snapshotStorageKey,
            snapshot.toJson(),
            box: box,
          );
        }

        final subjectJournal = journalWindow
            .where((entry) =>
                _subjectMatches(entry.subjectRef, subject.subjectRef))
            .map((entry) => entry.toJson())
            .toList();
        await _storage.setObject(
          subject.journalStorageKey,
          subjectJournal,
          box: box,
        );
      }

      await _storage.setObject(_manifestKey, manifest.toJson(), box: box);
    } catch (error, stackTrace) {
      developer.log(
        'Failed to persist canonical vibe state: $error',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  VibeKernelManifest _buildManifest({
    required VibeSnapshotEnvelope envelope,
    required List<TrajectoryMutationRecord> journalWindow,
    VibeKernelManifest? existingManifest,
  }) {
    final subjectRecords = <VibeKernelManifestSubject>[
      ...envelope.subjectSnapshots.map(
        (snapshot) => VibeKernelManifestSubject(
          subjectRef: snapshot.subjectRef,
          snapshotStorageKey: _snapshotStorageKey(snapshot.subjectRef),
          journalStorageKey: _journalStorageKey(snapshot.subjectRef),
        ),
      ),
      ...envelope.entitySnapshots.map(
        (snapshot) => VibeKernelManifestSubject(
          subjectRef: snapshot.subjectRef,
          snapshotStorageKey: _snapshotStorageKey(snapshot.subjectRef),
          journalStorageKey: _journalStorageKey(snapshot.subjectRef),
          isEntitySnapshot: true,
        ),
      ),
    ];

    final uniqueSubjects = <String, VibeKernelManifestSubject>{
      for (final subject in subjectRecords)
        '${subject.subjectRef.kind.toWireValue()}:${subject.subjectRef.subjectId}':
            subject,
    };

    return VibeKernelManifest(
      exportedAtUtc: envelope.exportedAtUtc,
      subjects: uniqueSubjects.values.toList()
        ..sort(
          (a, b) => a.subjectRef.subjectId.compareTo(b.subjectRef.subjectId),
        ),
      migrationVersion: existingManifest?.migrationVersion ??
          (envelope.metadata['migration_version'] as num?)?.toInt() ??
          0,
      migrationReceipts: <String>{
        ...(existingManifest?.migrationReceipts ?? const <String>[]),
        ...envelope.migrationReceipts,
      }.toList()
        ..sort(),
      metadata: <String, dynamic>{
        ...(existingManifest?.metadata ?? const <String, dynamic>{}),
        ...envelope.metadata,
        'subject_count': uniqueSubjects.length,
        'journal_record_count': journalWindow.length,
      },
      schemaVersion: envelope.schemaVersion,
    );
  }

  List<TrajectoryMutationRecord> _dedupeJournalRecords(
    List<TrajectoryMutationRecord> records,
  ) {
    final unique = <String, TrajectoryMutationRecord>{
      for (final record in records) record.recordId: record,
    };
    return unique.values.toList()
      ..sort((a, b) => a.occurredAtUtc.compareTo(b.occurredAtUtc));
  }

  String _snapshotStorageKey(VibeSubjectRef subjectRef) {
    return '$_snapshotPrefix${subjectRef.kind.toWireValue()}:${Uri.encodeComponent(subjectRef.subjectId)}';
  }

  String _journalStorageKey(VibeSubjectRef subjectRef) {
    return '$_journalPrefix${subjectRef.kind.toWireValue()}:${Uri.encodeComponent(subjectRef.subjectId)}';
  }

  bool _subjectMatches(VibeSubjectRef a, VibeSubjectRef b) {
    return a.subjectId == b.subjectId &&
        a.kind.canonicalKind == b.kind.canonicalKind &&
        a.effectiveGeographicLevel == b.effectiveGeographicLevel &&
        a.scopedKind == b.scopedKind &&
        a.entityType == b.entityType;
  }
}
