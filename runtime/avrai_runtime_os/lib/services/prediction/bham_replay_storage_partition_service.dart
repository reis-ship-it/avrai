import 'dart:convert';
import 'dart:io';

import 'package:avrai_core/avra_core.dart';

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
    final entries = <ReplayStoragePartitionEntry>[];
    final partitionRootDir = Directory(partitionRoot)..createSync(recursive: true);

    for (final exportEntry in exportManifest.entries) {
      if (!_partitionableArtifacts.contains(exportEntry.artifactRef)) {
        continue;
      }
      final sourceFile = File('${exportManifest.exportRoot}/${exportEntry.bucket}/${exportEntry.objectPath}');
      if (!sourceFile.existsSync()) {
        throw StateError('Staged replay artifact not found: ${sourceFile.path}');
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
      notes: const <String>[
        'Partition files are replay-only storage staging outputs.',
        'Original staged artifacts are retained for provenance and replay reproducibility.',
      ],
      metadata: <String, dynamic>{
        'artifactCount': exportManifest.entries.length,
        'partitionedArtifactCount': entries.map((entry) => entry.artifactRef).toSet().length,
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
}
