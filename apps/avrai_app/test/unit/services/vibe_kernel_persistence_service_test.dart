// ignore_for_file: avoid_relative_lib_imports

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai_runtime_os/services/vibe/vibe_kernel_persistence_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../mocks/mock_storage_service.dart';
import '../../../../../engine/reality_engine/lib/reality_engine.dart';

void main() {
  group('VibeKernelPersistenceService', () {
    setUpAll(() async {
      await StorageService.instance.initForTesting(
        defaultStorage: MockGetStorage.getInstance(boxName: 'spots_default'),
        userStorage: MockGetStorage.getInstance(boxName: 'spots_user'),
        aiStorage: MockGetStorage.getInstance(boxName: 'spots_ai'),
        analyticsStorage:
            MockGetStorage.getInstance(boxName: 'spots_analytics'),
      );
    });

    setUp(() async {
      MockGetStorage.clear(boxName: 'spots_default');
      MockGetStorage.clear(boxName: 'spots_user');
      MockGetStorage.clear(boxName: 'spots_ai');
      MockGetStorage.clear(boxName: 'spots_analytics');
      final vibeKernel = VibeKernel();
      final trajectoryKernel = TrajectoryKernel();
      vibeKernel.importSnapshotEnvelope(
        VibeSnapshotEnvelope(
          exportedAtUtc: DateTime.utc(2026, 3, 12),
        ),
      );
      trajectoryKernel.importJournalWindow(
        records: const <TrajectoryMutationRecord>[],
      );
    });

    test('restores canonical snapshot and journal window from storage',
        () async {
      final service = VibeKernelPersistenceService(
        storage: StorageService.instance,
      );
      final vibeKernel = VibeKernel();
      final trajectoryKernel = TrajectoryKernel();
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

      vibeKernel.importSnapshotEnvelope(
        VibeSnapshotEnvelope(
          exportedAtUtc: DateTime.utc(2026, 3, 12),
        ),
      );
      trajectoryKernel.importJournalWindow(
        records: const <TrajectoryMutationRecord>[],
      );

      final cleared = vibeKernel.getUserSnapshot(agentId);
      expect(cleared.coreDna.dimensions['energy_preference'], 0.5);

      await service.restore();

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
    });
  });
}
