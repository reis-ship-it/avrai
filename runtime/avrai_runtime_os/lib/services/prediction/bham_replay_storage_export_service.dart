import 'dart:io';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/config/replay_storage_config.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_storage_boundary_service.dart';

class BhamReplayStorageExportService {
  const BhamReplayStorageExportService();

  ReplayStorageExportManifest exportToStaging({
    required ReplayTrainingExportManifest trainingManifest,
    required String sourceRoot,
    required String exportRoot,
  }) {
    final boundaryReport = const BhamReplayStorageBoundaryService().buildReport(
      environmentId: trainingManifest.environmentId,
      replayYear: trainingManifest.replayYear,
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
      final destinationFile =
          File('${exportRootDir.path}/$bucket/$objectPath')
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
        'bucketCounts': _bucketCounts(entries),
        'totalBytes': entries.fold<int>(0, (sum, entry) => sum + entry.byteSize),
        'sourceRoot': sourceRootDir.path,
      },
    );
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
}
