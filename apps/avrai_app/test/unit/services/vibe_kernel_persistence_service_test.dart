// ignore_for_file: depend_on_referenced_packages

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai_runtime_os/services/vibe/vibe_kernel_persistence_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reality_engine/reality_engine.dart';

import '../../helpers/fake_vibe_kernel.dart';
import '../../mocks/mock_storage_service.dart';

void main() {
  group('VibeKernelPersistenceService', () {
    late TestVibeKernel vibeKernel;
    late TrajectoryKernel trajectoryKernel;

    setUpAll(() async {
      await StorageService.instance.initForTesting(
        defaultStorage: MockGetStorage.getInstance(boxName: 'spots_default'),
        userStorage: MockGetStorage.getInstance(boxName: 'spots_user'),
        aiStorage: MockGetStorage.getInstance(boxName: 'spots_ai'),
        analyticsStorage: MockGetStorage.getInstance(
          boxName: 'spots_analytics',
        ),
      );
    });

    setUp(() async {
      MockGetStorage.clear(boxName: 'spots_default');
      MockGetStorage.clear(boxName: 'spots_user');
      MockGetStorage.clear(boxName: 'spots_ai');
      MockGetStorage.clear(boxName: 'spots_analytics');
      TrajectoryKernel.resetFallbackStateForTesting();
      trajectoryKernel = TrajectoryKernel(allowFallback: true);
      vibeKernel = TestVibeKernel(trajectoryKernel: trajectoryKernel);
    });

    test(
      'restores canonical snapshot and journal window from storage',
      () async {
        final service = VibeKernelPersistenceService(
          storage: StorageService.instance,
          vibeKernel: vibeKernel,
          trajectoryKernel: trajectoryKernel,
        );
        const agentId = 'agt_vibe_persistence_test';

        vibeKernel.seedUserStateFromOnboarding(
          subjectId: agentId,
          dimensions: const <String, double>{
            'energy_preference': 0.18,
            'community_orientation': 0.71,
          },
        );
        await service.persistCanonicalState(
          envelope: vibeKernel.exportSnapshotEnvelope(),
          journalWindow: trajectoryKernel.exportJournalWindow(limit: 64),
        );

        final manifest = service.loadManifest();
        expect(manifest, isNotNull);
        expect(manifest!.subjects, isNotEmpty);

        TrajectoryKernel.resetFallbackStateForTesting();
        trajectoryKernel = TrajectoryKernel(allowFallback: true);
        vibeKernel = TestVibeKernel(trajectoryKernel: trajectoryKernel);

        final cleared = vibeKernel.getUserSnapshot(agentId);
        expect(cleared.coreDna.dimensions['energy_preference'], 0.5);

        final restoredService = VibeKernelPersistenceService(
          storage: StorageService.instance,
          vibeKernel: vibeKernel,
          trajectoryKernel: trajectoryKernel,
        );

        await restoredService.restore();

        final restored = vibeKernel.getUserSnapshot(agentId);
        final restoredJournal = trajectoryKernel.replaySubject(
          subjectRef: VibeSubjectRef.personal(agentId),
        );

        expect(restored.coreDna.dimensions['energy_preference'], lessThan(0.5));
        expect(
          restored.coreDna.dimensions['community_orientation'],
          greaterThan(0.5),
        );
        expect(restoredJournal, isNotEmpty);
        expect(
          StorageService.instance.getObject<Map<String, dynamic>>(
            'vibe_kernel_snapshot_envelope_v2',
            box: VibeKernelPersistenceService.box,
          ),
          isNull,
        );
        expect(
          StorageService.instance.getObject<List<dynamic>>(
            'trajectory_kernel_journal_window_v1',
            box: VibeKernelPersistenceService.box,
          ),
          isNull,
        );
      },
    );
  });
}
