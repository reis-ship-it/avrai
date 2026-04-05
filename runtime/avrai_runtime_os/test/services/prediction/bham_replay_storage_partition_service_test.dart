import 'dart:convert';
import 'dart:io';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_core/models/reality/artifact_lifecycle.dart';
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
      environmentId: 'sav-replay-world-2024',
      replayYear: 2024,
      status: 'accepted',
      exportRoot: exportRoot.path,
      projectIsolationMode: 'shared_project_isolated_namespace',
      replaySchema: 'replay_simulation',
      metadata: const <String, dynamic>{
        'storageExportManifestRef':
            'replay_storage_export_manifest:sav-replay-world-2024:2024',
        'sourceTrainingManifestRef':
            'replay_training_export_manifest:sav-replay-world-2024:2024:run-1',
        'sourceTrainingRunRef': 'run-1',
        'cityCode': 'sav',
        'cityPackId': 'savannah_core_2024',
        'cityPackManifestRef': 'city_packs/sav/2024_manifest.json',
        'cityPackStructuralRef': 'city_pack:savannah_core_2024',
      },
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
    expect(
      partitionManifest.metadata['legacyEnvironmentId'],
      'sav-replay-world-2024',
    );
    expect(
      partitionManifest.metadata['simulationEnvironmentId'],
      'sav-simulation-environment-2024',
    );
    expect(
      partitionManifest.metadata['simulationEnvironmentNamespace'],
      'simulation-world/sav/2024',
    );
    expect(
      partitionManifest.metadata['simulationLabel'],
      'Sav Simulation Environment 2024',
    );
    expect(
      partitionManifest.metadata['cityPackStructuralRef'],
      'city_pack:savannah_core_2024',
    );
    expect(
      partitionManifest.metadata['storagePartitionManifestRef'],
      'replay_storage_partition_manifest:sav-replay-world-2024:2024:2',
    );
    expect(
      partitionManifest.metadata['sourceStorageExportManifestRef'],
      'replay_storage_export_manifest:sav-replay-world-2024:2024',
    );
    expect(
      partitionManifest.metadata['sourceTrainingManifestRef'],
      'replay_training_export_manifest:sav-replay-world-2024:2024:run-1',
    );
    expect(partitionManifest.metadata['sourceTrainingRunRef'], 'run-1');
    expect(partitionManifest.metadata['retentionCreatedAtUtc'], isA<String>());
    expect(partitionManifest.metadata['retentionExpiresAtUtc'], isA<String>());
    expect(partitionManifest.metadata['cleanupAfterSuccessfulUpload'], isTrue);
    final lifecycle = ArtifactLifecycleMetadata.fromJson(
      Map<String, dynamic>.from(
        partitionManifest.metadata['artifactLifecycle'] as Map,
      ),
    );
    expect(lifecycle.artifactClass, ArtifactLifecycleClass.staging);
    expect(lifecycle.artifactState, ArtifactLifecycleState.accepted);
    expect(lifecycle.retentionPolicy.mode, ArtifactRetentionMode.ttlDelete);
  });
}
