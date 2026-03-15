import 'dart:convert';
import 'dart:io';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_storage_partition_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = BhamReplayStoragePartitionService();

  test('partitions large replay list sections into NDJSON chunks', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'bham_replay_storage_partition_test',
    );
    addTearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    final exportRoot = Directory('${tempDir.path}/export')..createSync();
    final worldRoot = Directory(
      '${exportRoot.path}/replay-world-snapshots/2023/world',
    )..createSync(recursive: true);
    File('${worldRoot.path}/50_BHAM_REPLAY_POPULATION_PROFILE_2023.json')
        .writeAsStringSync(
      jsonEncode(<String, dynamic>{
        'replayYear': 2023,
        'actors': List.generate(3, (index) => <String, dynamic>{'id': index}),
        'eligibilityRecords': List.generate(
          3,
          (index) => <String, dynamic>{'eligibility': index},
        ),
      }),
    );
    File('${worldRoot.path}/60_BHAM_REPLAY_CONNECTIVITY_PROFILES_2023.json')
        .writeAsStringSync(
      jsonEncode(
        List.generate(3, (index) => <String, dynamic>{'actorId': '$index'}),
      ),
    );

    final exportManifest = ReplayStorageExportManifest(
      environmentId: 'env-1',
      replayYear: 2023,
      status: 'accepted',
      exportRoot: exportRoot.path,
      projectIsolationMode: 'shared_project_isolated_namespace',
      replaySchema: 'replay_simulation',
      entries: <ReplayStorageExportEntry>[
        ReplayStorageExportEntry(
          artifactRef: '50_BHAM_REPLAY_POPULATION_PROFILE_2023.json',
          sourcePath: 'unused',
          bucket: 'replay-world-snapshots',
          objectPath: '2023/world/50_BHAM_REPLAY_POPULATION_PROFILE_2023.json',
          byteSize: 1,
        ),
        ReplayStorageExportEntry(
          artifactRef: '60_BHAM_REPLAY_CONNECTIVITY_PROFILES_2023.json',
          sourcePath: 'unused',
          bucket: 'replay-world-snapshots',
          objectPath:
              '2023/world/60_BHAM_REPLAY_CONNECTIVITY_PROFILES_2023.json',
          byteSize: 1,
        ),
      ],
    );

    final partitionManifest = service.partitionStagedArtifacts(
      exportManifest: exportManifest,
      partitionRoot: '${tempDir.path}/partitions',
      maxRecordsPerChunk: 2,
    );

    expect(partitionManifest.entries, isNotEmpty);
    expect(
      File(
        '${tempDir.path}/partitions/50_BHAM_REPLAY_POPULATION_PROFILE_2023.json/actors/chunk-0000.ndjson',
      ).existsSync(),
      isTrue,
    );
    expect(
      File(
        '${tempDir.path}/partitions/60_BHAM_REPLAY_CONNECTIVITY_PROFILES_2023.json/items/chunk-0001.ndjson',
      ).existsSync(),
      isTrue,
    );
  });
}
