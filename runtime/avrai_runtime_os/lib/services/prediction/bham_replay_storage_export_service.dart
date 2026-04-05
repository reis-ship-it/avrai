import 'dart:io';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_core/models/reality/artifact_lifecycle.dart';
import 'package:avrai_runtime_os/config/replay_storage_config.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_storage_boundary_service.dart';

class BhamReplayStorageExportService {
  const BhamReplayStorageExportService();

  ReplayStorageExportManifest exportToStaging({
    required ReplayTrainingExportManifest trainingManifest,
    required String sourceRoot,
    required String exportRoot,
  }) {
    final retainedAt = DateTime.now().toUtc();
    final expiresAt = retainedAt.add(
      const Duration(days: ReplayStorageConfig.stagingRetentionTtlDays),
    );
    final boundaryReport = const BhamReplayStorageBoundaryService().buildReport(
      environmentId: trainingManifest.environmentId,
      replayYear: trainingManifest.replayYear,
      artifactMetadata: trainingManifest.metadata,
    );
    if (!boundaryReport.passed) {
      throw StateError(
        'Replay storage boundary failed: ${boundaryReport.violations.join(' | ')}',
      );
    }

    final sourceRootDir = Directory(sourceRoot);
    if (!sourceRootDir.existsSync()) {
      throw StateError('Replay source root does not exist: $sourceRoot');
    }

    final exportRootDir = Directory(exportRoot)..createSync(recursive: true);
    final entries = <ReplayStorageExportEntry>[];

    for (final artifactRef in trainingManifest.artifactRefs) {
      final sourceFile = File('${sourceRootDir.path}/$artifactRef');
      if (!sourceFile.existsSync()) {
        throw StateError('Replay artifact not found: ${sourceFile.path}');
      }
      final bucket = _bucketForArtifact(artifactRef);
      final objectPath = _objectPathForArtifact(
        replayYear: trainingManifest.replayYear,
        artifactRef: artifactRef,
      );
      final destinationFile = File('${exportRootDir.path}/$bucket/$objectPath')
        ..parent.createSync(recursive: true);
      sourceFile.copySync(destinationFile.path);

      entries.add(
        ReplayStorageExportEntry(
          artifactRef: artifactRef,
          sourcePath: sourceFile.path,
          bucket: bucket,
          objectPath: objectPath,
          byteSize: destinationFile.lengthSync(),
        ),
      );
    }

    return ReplayStorageExportManifest(
      environmentId: trainingManifest.environmentId,
      replayYear: trainingManifest.replayYear,
      status: trainingManifest.status,
      exportRoot: exportRootDir.path,
      projectIsolationMode: boundaryReport.projectIsolationMode,
      replaySchema: boundaryReport.replaySchema,
      entries: entries,
      notes: <String>[
        'This is a local replay-storage staging export only.',
        'No live app Supabase buckets or public-schema tables were written.',
      ],
      metadata: <String, dynamic>{
        'artifactLifecycle': _stagingExportLifecycle(
          environmentId: trainingManifest.environmentId,
          replayYear: trainingManifest.replayYear,
        ).toJson(),
        'storageExportManifestRef': _storageExportManifestRef(
          environmentId: trainingManifest.environmentId,
          replayYear: trainingManifest.replayYear,
        ),
        'retentionCreatedAtUtc': retainedAt.toIso8601String(),
        'retentionExpiresAtUtc': expiresAt.toIso8601String(),
        'cleanupAfterSuccessfulUpload':
            ReplayStorageConfig.cleanupStagingOnSuccessfulUpload,
        if (_stringMetadata(trainingManifest.metadata, 'trainingManifestRef') !=
            null)
          'sourceTrainingManifestRef':
              _stringMetadata(trainingManifest.metadata, 'trainingManifestRef'),
        if (_stringMetadata(trainingManifest.metadata, 'replayRunRef') != null)
          'sourceTrainingRunRef':
              _stringMetadata(trainingManifest.metadata, 'replayRunRef'),
        'sourceTrainingStatus': trainingManifest.status,
        'bucketCounts': _bucketCounts(entries),
        'totalBytes':
            entries.fold<int>(0, (sum, entry) => sum + entry.byteSize),
        'sourceRoot': sourceRootDir.path,
        ..._selectedArtifactMetadata(trainingManifest.metadata),
      },
    );
  }

  Map<String, dynamic> _selectedArtifactMetadata(
      Map<String, dynamic> metadata) {
    const keys = <String>[
      'cityCode',
      'citySlug',
      'cityDisplayName',
      'legacyEnvironmentId',
      'legacyEnvironmentNamespace',
      'simulationEnvironmentId',
      'simulationEnvironmentNamespace',
      'simulationLabel',
      'cityPackManifestRef',
      'cityPackId',
      'cityPackStructuralRef',
      'campaignDefaultsRef',
      'localityExpectationProfileRef',
      'worldHealthProfileRef',
    ];
    final selected = <String, dynamic>{};
    for (final key in keys) {
      final value = metadata[key];
      if (value != null) {
        selected[key] = value;
      }
    }
    return selected;
  }

  String _bucketForArtifact(String artifactRef) {
    if (artifactRef.contains('EXCHANGE_EVENT_LOG')) {
      return ReplayStorageConfig.exchangeLogsBucket;
    }
    if (artifactRef.contains('TRAINING_EXPORT_MANIFEST') ||
        artifactRef.contains('TRAINING_SIGNALS') ||
        artifactRef.contains('HOLDOUT_EVALUATION')) {
      return ReplayStorageConfig.trainingExportsBucket;
    }
    if (artifactRef.contains('NORMALIZED_OBSERVATIONS')) {
      return ReplayStorageConfig.normalizedObservationsBucket;
    }
    return ReplayStorageConfig.worldSnapshotsBucket;
  }

  String _objectPathForArtifact({
    required int replayYear,
    required String artifactRef,
  }) {
    final category = artifactRef.contains('NORMALIZED_OBSERVATIONS')
        ? 'normalized'
        : artifactRef.contains('EXCHANGE_EVENT_LOG')
            ? 'exchange'
            : artifactRef.contains('TRAINING_EXPORT_MANIFEST') ||
                    artifactRef.contains('TRAINING_SIGNALS') ||
                    artifactRef.contains('HOLDOUT_EVALUATION')
                ? 'training'
                : 'world';
    return '$replayYear/$category/$artifactRef';
  }

  Map<String, int> _bucketCounts(List<ReplayStorageExportEntry> entries) {
    final counts = <String, int>{};
    for (final entry in entries) {
      counts.update(entry.bucket, (value) => value + 1, ifAbsent: () => 1);
    }
    return counts;
  }

  ArtifactLifecycleMetadata _stagingExportLifecycle({
    required String environmentId,
    required int replayYear,
  }) {
    return ArtifactLifecycleMetadata(
      artifactClass: ArtifactLifecycleClass.staging,
      artifactState: ArtifactLifecycleState.accepted,
      retentionPolicy: const ArtifactRetentionPolicy(
        mode: ArtifactRetentionMode.ttlDelete,
        ttlDays: 30,
        deleteWhenSuperseded: true,
      ),
      artifactFamily: 'replay_storage_export_manifest',
      sourceScope: 'replay_storage_staging',
      provenanceRefs: <String>[environmentId, 'replay_year:$replayYear'],
      evaluationRefs: const <String>['replay_storage_boundary_report'],
      containsRawPersonalPayload: false,
      containsMessageContent: false,
    );
  }

  String _storageExportManifestRef({
    required String environmentId,
    required int replayYear,
  }) {
    return 'replay_storage_export_manifest:$environmentId:$replayYear';
  }

  String? _stringMetadata(Map<String, dynamic> metadata, String key) {
    final rawValue = metadata[key]?.toString().trim();
    if (rawValue == null || rawValue.isEmpty) {
      return null;
    }
    return rawValue;
  }
}
