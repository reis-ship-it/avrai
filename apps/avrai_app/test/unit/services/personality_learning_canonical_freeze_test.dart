// ignore_for_file: depend_on_referenced_packages

import 'package:avrai_core/models/vibe/vibe_models.dart';
import 'package:avrai_runtime_os/ai/personality_learning.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat, StorageService;
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reality_engine/reality_engine.dart';

import '../../mocks/mock_storage_service.dart';

class _FakePersistenceBridge implements VibeKernelPersistenceBridge {
  @override
  Future<void> persistCanonicalState({
    required VibeSnapshotEnvelope envelope,
    required List<TrajectoryMutationRecord> journalWindow,
  }) async {}
}

void main() {
  group('PersonalityLearning canonical freeze', () {
    setUpAll(() async {
      await StorageService.instance.initForTesting(
        defaultStorage: MockGetStorage.getInstance(boxName: 'spots_default'),
        userStorage: MockGetStorage.getInstance(boxName: 'spots_user'),
        aiStorage: MockGetStorage.getInstance(boxName: 'spots_ai'),
        analyticsStorage:
            MockGetStorage.getInstance(boxName: 'spots_analytics'),
      );
    });

    setUp(() {
      MockGetStorage.clear(boxName: 'spots_default');
      MockGetStorage.clear(boxName: 'spots_user');
      MockGetStorage.clear(boxName: 'spots_ai');
      MockGetStorage.clear(boxName: 'spots_analytics');
      VibeKernelRuntimeBindings.persistenceBridge = _FakePersistenceBridge();
      VibeKernel().importSnapshotEnvelope(
        VibeSnapshotEnvelope(exportedAtUtc: DateTime.utc(2026, 3, 12)),
      );
      TrajectoryKernel().importJournalWindow(
        records: const <TrajectoryMutationRecord>[],
      );
    });

    tearDown(() {
      VibeKernelRuntimeBindings.persistenceBridge = null;
    });

    test(
        'projects canonical personal vibe without writing legacy personality storage keys',
        () async {
      const userId = 'user-freeze-user';
      final defaultStorage = MockGetStorage.getInstance(boxName: 'spots_default');
      final prefs = await SharedPreferencesCompat.getInstance(
        storage: defaultStorage,
      );
      final learning = PersonalityLearning.withPrefs(prefs);
      final agentId = await AgentIdService().getUserAgentId(userId);

      final profile = await learning.initializePersonality(userId);

      expect(profile.agentId, agentId);
      expect(
        defaultStorage.hasData('personality_profile_$agentId'),
        isFalse,
      );
      expect(
        defaultStorage.hasData('personality_profile_$userId'),
        isFalse,
      );
      expect(
        defaultStorage.hasData('personality_learning_history_$agentId'),
        isFalse,
      );
      expect(
        defaultStorage.hasData('dimension_confidence_$agentId'),
        isFalse,
      );
    });
  });
}
