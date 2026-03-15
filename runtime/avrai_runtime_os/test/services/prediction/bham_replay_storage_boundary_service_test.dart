import 'package:avrai_runtime_os/services/prediction/bham_replay_storage_boundary_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = BhamReplayStorageBoundaryService();

  test('passes when replay uses isolated schema and replay-prefixed buckets', () {
    final report = service.buildReport(
      environmentId: 'env-1',
      replayYear: 2023,
      replaySchema: 'replay_simulation',
      replayBuckets: const <String>[
        'replay-source-packs',
        'replay-normalized-observations',
      ],
      replayMetadataTables: const <String>[
        'replay_runs',
        'replay_artifacts',
      ],
      appBuckets: const <String>[
        'user-avatars',
        'spot-images',
        'paperwork-documents',
      ],
      replayUrl: 'https://replay.example.supabase.co',
      appUrl: 'https://app.example.supabase.co',
    );

    expect(report.passed, isTrue);
    expect(report.projectIsolationMode, 'dedicated_project');
    expect(report.violations, isEmpty);
  });

  test('fails when replay reuses app schema or bucket names', () {
    final report = service.buildReport(
      environmentId: 'env-1',
      replayYear: 2023,
      replaySchema: 'public',
      replayBuckets: const <String>[
        'user-avatars',
        'replay-normalized-observations',
      ],
      replayMetadataTables: const <String>[
        'runs',
        'replay_artifacts',
      ],
      appBuckets: const <String>[
        'user-avatars',
        'spot-images',
      ],
      replayUrl: 'https://app.example.supabase.co',
      appUrl: 'https://app.example.supabase.co',
    );

    expect(report.passed, isFalse);
    expect(
      report.violations,
      contains('Replay schema may not use the live app public schema.'),
    );
    expect(
      report.violations.any((entry) => entry.contains('Replay buckets overlap')),
      isTrue,
    );
    expect(
      report.violations.any(
        (entry) => entry.contains('Replay metadata tables must use the replay_ prefix'),
      ),
      isTrue,
    );
    expect(report.projectIsolationMode, 'shared_project_isolated_namespace');
  });
}
