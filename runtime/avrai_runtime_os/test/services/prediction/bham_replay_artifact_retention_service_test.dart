import 'dart:io';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_artifact_retention_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cleanupAfterSuccessfulUpload deletes managed staging roots', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'bham_replay_artifact_retention_cleanup_test_',
    );
    addTearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    final exportRoot = Directory(
      '${tempDir.path}/runtime_exports/replay_storage_staging/bham_2023',
    )..createSync(recursive: true);
    final partitionRoot = Directory(
      '${tempDir.path}/runtime_exports/replay_storage_partitions/bham_2023',
    )..createSync(recursive: true);

    final exportManifest = ReplayStorageExportManifest(
      environmentId: 'bham-replay-world-2023',
      replayYear: 2023,
      status: 'accepted',
      exportRoot: exportRoot.path,
      projectIsolationMode: 'shared_project_isolated_namespace',
      replaySchema: 'replay_simulation',
      entries: const <ReplayStorageExportEntry>[],
      metadata: const <String, dynamic>{
        'retentionExpiresAtUtc': '2026-05-05T00:00:00.000Z',
      },
    );
    final partitionManifest = ReplayStoragePartitionManifest(
      environmentId: 'bham-replay-world-2023',
      replayYear: 2023,
      partitionRoot: partitionRoot.path,
      maxRecordsPerChunk: 1000,
      entries: const <ReplayStoragePartitionEntry>[],
      metadata: const <String, dynamic>{
        'retentionExpiresAtUtc': '2026-05-05T00:00:00.000Z',
      },
    );

    final result =
        const BhamReplayArtifactRetentionService().cleanupAfterSuccessfulUpload(
      exportManifest: exportManifest,
      partitionManifest: partitionManifest,
    );

    expect(result.attempted, isTrue);
    expect(result.succeeded, isTrue);
    expect(exportRoot.existsSync(), isFalse);
    expect(partitionRoot.existsSync(), isFalse);
    expect(
      result.lifecycleStatesByRole['replay_storage_staging'],
      'expired',
    );
    expect(
      result.lifecycleStatesByRole['replay_storage_partitions'],
      'expired',
    );
  });

  test('cleanupExpiredStagingRoots deletes only expired roots', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'bham_replay_artifact_retention_expiry_test_',
    );
    addTearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    final exportRoot = Directory(
      '${tempDir.path}/runtime_exports/replay_storage_staging/bham_2023',
    )..createSync(recursive: true);
    final partitionRoot = Directory(
      '${tempDir.path}/runtime_exports/replay_storage_partitions/bham_2023',
    )..createSync(recursive: true);

    final exportManifest = ReplayStorageExportManifest(
      environmentId: 'bham-replay-world-2023',
      replayYear: 2023,
      status: 'accepted',
      exportRoot: exportRoot.path,
      projectIsolationMode: 'shared_project_isolated_namespace',
      replaySchema: 'replay_simulation',
      entries: const <ReplayStorageExportEntry>[],
      metadata: const <String, dynamic>{
        'retentionExpiresAtUtc': '2026-04-01T00:00:00.000Z',
      },
    );
    final partitionManifest = ReplayStoragePartitionManifest(
      environmentId: 'bham-replay-world-2023',
      replayYear: 2023,
      partitionRoot: partitionRoot.path,
      maxRecordsPerChunk: 1000,
      entries: const <ReplayStoragePartitionEntry>[],
      metadata: const <String, dynamic>{
        'retentionExpiresAtUtc': '2026-04-10T00:00:00.000Z',
      },
    );

    final result =
        const BhamReplayArtifactRetentionService().cleanupExpiredStagingRoots(
      exportManifest: exportManifest,
      partitionManifest: partitionManifest,
      referenceAt: DateTime.utc(2026, 4, 5),
    );

    expect(result.attempted, isTrue);
    expect(result.succeeded, isTrue);
    expect(exportRoot.existsSync(), isFalse);
    expect(partitionRoot.existsSync(), isTrue);
    expect(
      result.lifecycleStatesByRole['replay_storage_staging'],
      'expired',
    );
    expect(
      result.lifecycleStatesByRole['replay_storage_partitions'],
      'accepted',
    );
  });

  test('cleanupAfterSuccessfulUpload refuses unmanaged roots', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'bham_replay_artifact_retention_unmanaged_test_',
    );
    addTearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    final unmanagedExportRoot = Directory(
      '${tempDir.path}/runtime_exports/not_replay_staging/bham_2023',
    )..createSync(recursive: true);
    final partitionRoot = Directory(
      '${tempDir.path}/runtime_exports/replay_storage_partitions/bham_2023',
    )..createSync(recursive: true);

    final exportManifest = ReplayStorageExportManifest(
      environmentId: 'bham-replay-world-2023',
      replayYear: 2023,
      status: 'accepted',
      exportRoot: unmanagedExportRoot.path,
      projectIsolationMode: 'shared_project_isolated_namespace',
      replaySchema: 'replay_simulation',
      entries: const <ReplayStorageExportEntry>[],
      metadata: const <String, dynamic>{
        'retentionExpiresAtUtc': '2026-05-05T00:00:00.000Z',
      },
    );
    final partitionManifest = ReplayStoragePartitionManifest(
      environmentId: 'bham-replay-world-2023',
      replayYear: 2023,
      partitionRoot: partitionRoot.path,
      maxRecordsPerChunk: 1000,
      entries: const <ReplayStoragePartitionEntry>[],
      metadata: const <String, dynamic>{
        'retentionExpiresAtUtc': '2026-05-05T00:00:00.000Z',
      },
    );

    final result =
        const BhamReplayArtifactRetentionService().cleanupAfterSuccessfulUpload(
      exportManifest: exportManifest,
      partitionManifest: partitionManifest,
    );

    expect(result.attempted, isTrue);
    expect(result.succeeded, isFalse);
    expect(unmanagedExportRoot.existsSync(), isTrue);
    expect(partitionRoot.existsSync(), isFalse);
    expect(
      result.failures.single,
      contains('Refusing to delete unmanaged replay root'),
    );
    expect(
      result.lifecycleStatesByRole['replay_storage_staging'],
      'accepted_pending_cleanup',
    );
    expect(
      result.lifecycleStatesByRole['replay_storage_partitions'],
      'expired',
    );
  });
}
