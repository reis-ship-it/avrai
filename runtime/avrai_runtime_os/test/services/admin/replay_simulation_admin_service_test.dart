import 'package:avrai_core/models/temporal/replay_simulation_artifacts.dart';
import 'package:avrai_runtime_os/services/admin/replay_simulation_admin_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'default service exposes the BHAM replay environment and snapshot',
    () async {
      final service = ReplaySimulationAdminService(
        nowProvider: () => DateTime.utc(2026, 3, 31, 20),
      );

      final environments = service.listEnvironments();
      expect(environments, hasLength(1));
      expect(environments.single.environmentId, 'bham-replay-world-2023');
      expect(environments.single.cityCode, 'bham');
      expect(environments.single.replayYear, 2023);

      final snapshot = await service.getSnapshot();
      expect(snapshot.environmentId, 'bham-replay-world-2023');
      expect(snapshot.cityCode, 'bham');
      expect(snapshot.replayYear, 2023);
      expect(snapshot.generatedAt, DateTime.utc(2026, 3, 31, 20));
      expect(snapshot.scenarios, isNotEmpty);
      expect(snapshot.receipts, hasLength(snapshot.scenarios.length));
      expect(snapshot.comparisons, hasLength(snapshot.scenarios.length));
    },
  );

  test('selects explicit environment adapters when requested', () async {
    final service = ReplaySimulationAdminService(
      environmentAdapters: <ReplaySimulationAdminEnvironmentAdapter>[
        _FakeReplaySimulationAdminEnvironmentAdapter(
          descriptor: const ReplaySimulationAdminEnvironmentDescriptor(
            environmentId: 'env-a',
            displayName: 'Environment A',
            cityCode: 'bham',
            replayYear: 2023,
          ),
        ),
        _FakeReplaySimulationAdminEnvironmentAdapter(
          descriptor: const ReplaySimulationAdminEnvironmentDescriptor(
            environmentId: 'env-b',
            displayName: 'Environment B',
            cityCode: 'bham',
            replayYear: 2024,
          ),
        ),
      ],
      defaultEnvironmentId: 'env-a',
      nowProvider: () => DateTime.utc(2026, 3, 31, 20),
    );

    final snapshot = await service.getSnapshot(environmentId: 'env-b');
    expect(snapshot.environmentId, 'env-b');
    expect(snapshot.replayYear, 2024);

    final streamed = await service
        .watchSnapshot(
          environmentId: 'env-b',
          refreshInterval: const Duration(minutes: 5),
        )
        .first;
    expect(streamed.environmentId, 'env-b');
    expect(streamed.replayYear, 2024);
  });

  test('fails closed on unknown environments', () async {
    final service = ReplaySimulationAdminService(
      environmentAdapters: <ReplaySimulationAdminEnvironmentAdapter>[
        _FakeReplaySimulationAdminEnvironmentAdapter(
          descriptor: const ReplaySimulationAdminEnvironmentDescriptor(
            environmentId: 'env-a',
            displayName: 'Environment A',
            cityCode: 'bham',
            replayYear: 2023,
          ),
        ),
      ],
    );

    await expectLater(
      service.getSnapshot(environmentId: 'missing-env'),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('Unknown replay simulation environment'),
        ),
      ),
    );
  });

  test('rejects duplicate environment ids at construction time', () {
    expect(
      () => ReplaySimulationAdminService(
        environmentAdapters: <ReplaySimulationAdminEnvironmentAdapter>[
          _FakeReplaySimulationAdminEnvironmentAdapter(
            descriptor: const ReplaySimulationAdminEnvironmentDescriptor(
              environmentId: 'dup-env',
              displayName: 'Environment A',
              cityCode: 'bham',
              replayYear: 2023,
            ),
          ),
          _FakeReplaySimulationAdminEnvironmentAdapter(
            descriptor: const ReplaySimulationAdminEnvironmentDescriptor(
              environmentId: 'dup-env',
              displayName: 'Environment B',
              cityCode: 'bham',
              replayYear: 2024,
            ),
          ),
        ],
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('Duplicate replay simulation environment id'),
        ),
      ),
    );
  });
}

class _FakeReplaySimulationAdminEnvironmentAdapter
    implements ReplaySimulationAdminEnvironmentAdapter {
  const _FakeReplaySimulationAdminEnvironmentAdapter({
    required this.descriptor,
  });

  @override
  final ReplaySimulationAdminEnvironmentDescriptor descriptor;

  @override
  Future<ReplaySimulationAdminSnapshot> buildSnapshot({
    required DateTime generatedAt,
  }) async {
    return ReplaySimulationAdminSnapshot(
      generatedAt: generatedAt,
      environmentId: descriptor.environmentId,
      cityCode: descriptor.cityCode,
      replayYear: descriptor.replayYear,
      scenarios: const <ReplayScenarioPacket>[],
      comparisons: const <ReplayScenarioComparison>[],
      receipts: const <SimulationTruthReceipt>[],
      contradictions: const <ReplayContradictionSnapshot>[],
      localityOverlays: const <ReplayLocalityOverlaySnapshot>[],
    );
  }
}
