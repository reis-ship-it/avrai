import 'dart:convert';
import 'dart:io';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_core/models/reality/artifact_lifecycle.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_storage_export_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = BhamReplayStorageExportService();

  test('stages replay artifacts into isolated replay buckets', () async {
    final tempDir = await Directory.systemTemp
        .createTemp('bham_replay_storage_export_test');
    addTearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    final sourceRoot = Directory('${tempDir.path}/source')..createSync();
    File('${sourceRoot.path}/36_BHAM_CONSOLIDATED_REPLAY_NORMALIZED_OBSERVATIONS_2023.json')
        .writeAsStringSync(jsonEncode(<String, dynamic>{'ok': true}));
    File('${sourceRoot.path}/45_BHAM_SINGLE_YEAR_REPLAY_PASS_2023.json')
        .writeAsStringSync(jsonEncode(<String, dynamic>{'pass': true}));
    File('${sourceRoot.path}/58_BHAM_REPLAY_TRAINING_EXPORT_MANIFEST_2023.json')
        .writeAsStringSync(jsonEncode(<String, dynamic>{'manifest': true}));
    File('${sourceRoot.path}/62_BHAM_REPLAY_EXCHANGE_EVENT_LOG_2023.json')
        .writeAsStringSync(jsonEncode(<String, dynamic>{
      'events': <int>[1, 2]
    }));

    final exportRoot = '${tempDir.path}/runtime_exports/replay_storage_staging';
    final manifest = const ReplayTrainingExportManifest(
      environmentId: 'bham-replay-world-2023',
      replayYear: 2023,
      status: 'accepted_as_monte_carlo_base_year',
      artifactRefs: <String>[
        '36_BHAM_CONSOLIDATED_REPLAY_NORMALIZED_OBSERVATIONS_2023.json',
        '45_BHAM_SINGLE_YEAR_REPLAY_PASS_2023.json',
        '58_BHAM_REPLAY_TRAINING_EXPORT_MANIFEST_2023.json',
        '62_BHAM_REPLAY_EXCHANGE_EVENT_LOG_2023.json',
      ],
      metrics: <String, dynamic>{},
      metadata: <String, dynamic>{
        'trainingManifestRef':
            'replay_training_export_manifest:bham-replay-world-2023:2023:run-1',
        'replayRunRef': 'run-1',
        'cityCode': 'atx',
        'citySlug': 'atx',
        'cityDisplayName': 'Austin',
        'simulationEnvironmentId': 'atx-simulation-environment-2023',
        'simulationEnvironmentNamespace': 'simulation-world/atx/2023/run-1',
        'simulationLabel': 'Austin Simulation Environment 2023',
        'cityPackId': 'austin_core_2024',
        'cityPackManifestRef': 'city_packs/atx/2024_manifest.json',
        'cityPackStructuralRef': 'city_pack:austin_core_2024',
      },
    );

    final exportManifest = service.exportToStaging(
      trainingManifest: manifest,
      sourceRoot: sourceRoot.path,
      exportRoot: exportRoot,
    );

    expect(exportManifest.entries, hasLength(4));
    expect(
      File(
        '$exportRoot/replay-normalized-observations/2023/normalized/36_BHAM_CONSOLIDATED_REPLAY_NORMALIZED_OBSERVATIONS_2023.json',
      ).existsSync(),
      isTrue,
    );
    expect(
      File(
        '$exportRoot/replay-world-snapshots/2023/world/45_BHAM_SINGLE_YEAR_REPLAY_PASS_2023.json',
      ).existsSync(),
      isTrue,
    );
    expect(
      File(
        '$exportRoot/replay-training-exports/2023/training/58_BHAM_REPLAY_TRAINING_EXPORT_MANIFEST_2023.json',
      ).existsSync(),
      isTrue,
    );
    expect(
      File(
        '$exportRoot/replay-exchange-logs/2023/exchange/62_BHAM_REPLAY_EXCHANGE_EVENT_LOG_2023.json',
      ).existsSync(),
      isTrue,
    );
    expect(exportManifest.metadata['cityPackId'], 'austin_core_2024');
    expect(
      exportManifest.metadata['cityPackStructuralRef'],
      'city_pack:austin_core_2024',
    );
    expect(
      exportManifest.metadata['simulationEnvironmentId'],
      'atx-simulation-environment-2023',
    );
    expect(
      exportManifest.metadata['storageExportManifestRef'],
      'replay_storage_export_manifest:bham-replay-world-2023:2023',
    );
    expect(
      exportManifest.metadata['sourceTrainingManifestRef'],
      'replay_training_export_manifest:bham-replay-world-2023:2023:run-1',
    );
    expect(exportManifest.metadata['sourceTrainingRunRef'], 'run-1');
    expect(exportManifest.metadata['retentionCreatedAtUtc'], isA<String>());
    expect(exportManifest.metadata['retentionExpiresAtUtc'], isA<String>());
    expect(exportManifest.metadata['cleanupAfterSuccessfulUpload'], isTrue);
    final lifecycle = ArtifactLifecycleMetadata.fromJson(
      Map<String, dynamic>.from(
        exportManifest.metadata['artifactLifecycle'] as Map,
      ),
    );
    expect(lifecycle.artifactClass, ArtifactLifecycleClass.staging);
    expect(lifecycle.artifactState, ArtifactLifecycleState.accepted);
    expect(lifecycle.retentionPolicy.mode, ArtifactRetentionMode.ttlDelete);
  });
}
