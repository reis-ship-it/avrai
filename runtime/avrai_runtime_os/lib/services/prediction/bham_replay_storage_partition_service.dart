import 'dart:convert';
import 'dart:io';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_core/models/reality/artifact_lifecycle.dart';
import 'package:avrai_runtime_os/config/replay_storage_config.dart';

class BhamReplayStoragePartitionService {
  const BhamReplayStoragePartitionService();

  static const List<String> _partitionableArtifacts = <String>[
    '45_BHAM_SINGLE_YEAR_REPLAY_PASS_2023.json',
    '50_BHAM_REPLAY_POPULATION_PROFILE_2023.json',
    '56_BHAM_REPLAY_DAILY_BEHAVIOR_2023.json',
    '59_BHAM_REPLAY_ACTOR_KERNEL_COVERAGE_2023.json',
    '60_BHAM_REPLAY_CONNECTIVITY_PROFILES_2023.json',
    '62_BHAM_REPLAY_EXCHANGE_EVENT_LOG_2023.json',
    '67_BHAM_REPLAY_PHYSICAL_MOVEMENT_2023.json',
    '68_BHAM_REPLAY_TRAINING_SIGNALS_2023.json',
  ];

  ReplayStoragePartitionManifest partitionStagedArtifacts({
    required ReplayStorageExportManifest exportManifest,
    required String partitionRoot,
    int maxRecordsPerChunk = 1000,
  }) {
    final retainedAt = DateTime.now().toUtc();
    final expiresAt = retainedAt.add(
      const Duration(days: ReplayStorageConfig.partitionRetentionTtlDays),
    );
    final entries = <ReplayStoragePartitionEntry>[];
    final partitionRootDir = Directory(partitionRoot)
      ..createSync(recursive: true);
    final citySlug = _citySlugFromEnvironmentId(exportManifest.environmentId);
    final cityDisplayName = _cityDisplayNameFromSlug(citySlug);

    for (final exportEntry in exportManifest.entries) {
      if (!_partitionableArtifacts.contains(exportEntry.artifactRef)) {
        continue;
      }
      final sourceFile = File(
          '${exportManifest.exportRoot}/${exportEntry.bucket}/${exportEntry.objectPath}');
      if (!sourceFile.existsSync()) {
        throw StateError(
            'Staged replay artifact not found: ${sourceFile.path}');
      }
      final decoded = jsonDecode(sourceFile.readAsStringSync());
      if (decoded is List) {
        entries.addAll(
          _writeListChunks(
            artifactRef: exportEntry.artifactRef,
            section: 'items',
            records: decoded,
            partitionRootDir: partitionRootDir,
            maxRecordsPerChunk: maxRecordsPerChunk,
          ),
        );
      } else if (decoded is Map<String, dynamic>) {
        for (final mapEntry in decoded.entries) {
          final value = mapEntry.value;
          if (value is List) {
            entries.addAll(
              _writeListChunks(
                artifactRef: exportEntry.artifactRef,
                section: mapEntry.key,
                records: value,
                partitionRootDir: partitionRootDir,
                maxRecordsPerChunk: maxRecordsPerChunk,
              ),
            );
          }
        }
      }
    }

    return ReplayStoragePartitionManifest(
      environmentId: exportManifest.environmentId,
      replayYear: exportManifest.replayYear,
      partitionRoot: partitionRootDir.path,
      maxRecordsPerChunk: maxRecordsPerChunk,
      entries: entries,
      notes: <String>[
        'Partition files are storage staging outputs for a single-year simulation environment.',
        'Original staged artifacts are retained for provenance and replay reproducibility.',
      ],
      metadata: <String, dynamic>{
        'artifactLifecycle': _partitionLifecycle(
          environmentId: exportManifest.environmentId,
          replayYear: exportManifest.replayYear,
        ).toJson(),
        'storagePartitionManifestRef': _storagePartitionManifestRef(
          environmentId: exportManifest.environmentId,
          replayYear: exportManifest.replayYear,
          maxRecordsPerChunk: maxRecordsPerChunk,
        ),
        'retentionCreatedAtUtc': retainedAt.toIso8601String(),
        'retentionExpiresAtUtc': expiresAt.toIso8601String(),
        'cleanupAfterSuccessfulUpload':
            ReplayStorageConfig.cleanupStagingOnSuccessfulUpload,
        if (_stringMetadata(
                exportManifest.metadata, 'storageExportManifestRef') !=
            null)
          'sourceStorageExportManifestRef': _stringMetadata(
              exportManifest.metadata, 'storageExportManifestRef'),
        if (_stringMetadata(
                exportManifest.metadata, 'sourceTrainingManifestRef') !=
            null)
          'sourceTrainingManifestRef': _stringMetadata(
              exportManifest.metadata, 'sourceTrainingManifestRef'),
        if (_stringMetadata(exportManifest.metadata, 'sourceTrainingRunRef') !=
            null)
          'sourceTrainingRunRef':
              _stringMetadata(exportManifest.metadata, 'sourceTrainingRunRef'),
        'legacyEnvironmentId': exportManifest.environmentId,
        'simulationEnvironmentId':
            '$citySlug-simulation-environment-${exportManifest.replayYear}',
        'simulationEnvironmentNamespace':
            'simulation-world/$citySlug/${exportManifest.replayYear}',
        'simulationLabel':
            '$cityDisplayName Simulation Environment ${exportManifest.replayYear}',
        'citySlug': citySlug,
        'cityDisplayName': cityDisplayName,
        if (exportManifest.metadata['cityCode'] != null)
          'cityCode': exportManifest.metadata['cityCode'],
        if (exportManifest.metadata['cityPackManifestRef'] != null)
          'cityPackManifestRef': exportManifest.metadata['cityPackManifestRef'],
        if (exportManifest.metadata['cityPackId'] != null)
          'cityPackId': exportManifest.metadata['cityPackId'],
        if (exportManifest.metadata['cityPackStructuralRef'] != null)
          'cityPackStructuralRef':
              exportManifest.metadata['cityPackStructuralRef'],
        if (exportManifest.metadata['campaignDefaultsRef'] != null)
          'campaignDefaultsRef': exportManifest.metadata['campaignDefaultsRef'],
        if (exportManifest.metadata['localityExpectationProfileRef'] != null)
          'localityExpectationProfileRef':
              exportManifest.metadata['localityExpectationProfileRef'],
        if (exportManifest.metadata['worldHealthProfileRef'] != null)
          'worldHealthProfileRef':
              exportManifest.metadata['worldHealthProfileRef'],
        'artifactCount': exportManifest.entries.length,
        'partitionedArtifactCount':
            entries.map((entry) => entry.artifactRef).toSet().length,
      },
    );
  }

  List<ReplayStoragePartitionEntry> _writeListChunks({
    required String artifactRef,
    required String section,
    required List<dynamic> records,
    required Directory partitionRootDir,
    required int maxRecordsPerChunk,
  }) {
    final entries = <ReplayStoragePartitionEntry>[];
    for (var start = 0; start < records.length; start += maxRecordsPerChunk) {
      final chunkIndex = start ~/ maxRecordsPerChunk;
      final chunk = records.skip(start).take(maxRecordsPerChunk).toList();
      final file = File(
        '${partitionRootDir.path}/$artifactRef/$section/chunk-${chunkIndex.toString().padLeft(4, '0')}.ndjson',
      )..parent.createSync(recursive: true);
      final buffer = StringBuffer();
      for (final record in chunk) {
        buffer.writeln(jsonEncode(record));
      }
      file.writeAsStringSync(buffer.toString());
      entries.add(
        ReplayStoragePartitionEntry(
          artifactRef: artifactRef,
          section: section,
          chunkIndex: chunkIndex,
          recordCount: chunk.length,
          objectPath:
              '$artifactRef/$section/chunk-${chunkIndex.toString().padLeft(4, '0')}.ndjson',
          byteSize: file.lengthSync(),
        ),
      );
    }
    return entries;
  }

  String _citySlugFromEnvironmentId(String environmentId) {
    final trimmed = environmentId.trim();
    final replaySuffix = RegExp(r'-replay-world-\d+$');
    if (replaySuffix.hasMatch(trimmed)) {
      return trimmed.replaceFirst(replaySuffix, '');
    }
    final parts = trimmed
        .split(RegExp(r'[^a-zA-Z0-9]+'))
        .where((part) => part.trim().isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return 'simulation';
    }
    return parts.first.toLowerCase();
  }

  String _cityDisplayNameFromSlug(String citySlug) {
    if (citySlug.trim().isEmpty) {
      return 'Simulation';
    }
    return citySlug
        .split('-')
        .where((segment) => segment.trim().isNotEmpty)
        .map(
          (segment) =>
              '${segment[0].toUpperCase()}${segment.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  ArtifactLifecycleMetadata _partitionLifecycle({
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
      artifactFamily: 'replay_storage_partition_manifest',
      sourceScope: 'replay_storage_partitions',
      provenanceRefs: <String>[environmentId, 'replay_year:$replayYear'],
      evaluationRefs: const <String>['replay_storage_export_manifest'],
      containsRawPersonalPayload: false,
      containsMessageContent: false,
    );
  }

  String _storagePartitionManifestRef({
    required String environmentId,
    required int replayYear,
    required int maxRecordsPerChunk,
  }) {
    return 'replay_storage_partition_manifest:'
        '$environmentId:$replayYear:$maxRecordsPerChunk';
  }

  String? _stringMetadata(Map<String, dynamic> metadata, String key) {
    final rawValue = metadata[key]?.toString().trim();
    if (rawValue == null || rawValue.isEmpty) {
      return null;
    }
    return rawValue;
  }
}
