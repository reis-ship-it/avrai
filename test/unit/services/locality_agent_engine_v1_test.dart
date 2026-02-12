import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/models/spots/visit.dart';
import 'package:avrai/core/services/locality_agents/locality_agent_engine.dart';
import 'package:avrai/core/services/locality_agents/locality_agent_global_repository.dart';
import 'package:avrai/core/services/locality_agents/locality_agent_local_store.dart';
import 'package:avrai/core/services/locality_agents/locality_agent_models_v1.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart';
import 'package:avrai/core/services/infrastructure/supabase_service.dart';

import '../../mocks/mock_storage_service.dart';

class _FakeGlobalRepo extends LocalityAgentGlobalRepositoryV1 {
  final Map<String, LocalityAgentGlobalStateV1> byKey;

  _FakeGlobalRepo({required this.byKey})
      : super(supabaseService: SupabaseService(), storage: StorageService.instance);

  @override
  Future<LocalityAgentGlobalStateV1> getGlobalState(LocalityAgentKeyV1 key) async {
    return byKey[key.stableKey] ?? LocalityAgentGlobalStateV1.empty(key);
  }
}

void main() {
  group('LocalityAgentEngineV1', () {
    setUpAll(() async {
      // Init StorageService with mock boxes for unit tests.
      await StorageService.instance.initForTesting(
        defaultStorage: MockGetStorage.getInstance(boxName: 'spots_default'),
        userStorage: MockGetStorage.getInstance(boxName: 'spots_user'),
        aiStorage: MockGetStorage.getInstance(boxName: 'spots_ai'),
        analyticsStorage: MockGetStorage.getInstance(boxName: 'spots_analytics'),
      );
    });

    test('updateFromVisit increases community-related delta when ai2ai exchange happened', () async {
      const key = LocalityAgentKeyV1(geohashPrefix: 'dr5regw', precision: 7);
      final localStore = LocalityAgentLocalStoreV1(storage: StorageService.instance);
      final globalRepo = _FakeGlobalRepo(byKey: {});
      final engine = LocalityAgentEngineV1(globalRepo: globalRepo, localStore: localStore);

      final visit = Visit(
        id: 'v1',
        userId: 'u1',
        locationId: 'loc1',
        checkInTime: DateTime.now(),
        isAutomatic: true,
        bluetoothData: BluetoothData(
          detectedAt: DateTime.now(),
          ai2aiConnected: true,
          personalityExchanged: true,
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final updated = await engine.updateFromVisit(
        agentId: 'agent_abc',
        key: key,
        visit: visit,
      );

      // Behavior: social dimensions should move positive (somewhere).
      final idxCommunity = LocalityAgentEngineV1.dimensions.indexOf('community_orientation');
      final idxTrust = LocalityAgentEngineV1.dimensions.indexOf('trust_network_reliance');
      expect(updated.delta12[idxCommunity], greaterThan(0));
      expect(updated.delta12[idxTrust], greaterThan(0));
    });

    test('inferVector12 applies personal delta on top of global', () async {
      const key = LocalityAgentKeyV1(geohashPrefix: 'dr5regw', precision: 7);
      final global = LocalityAgentGlobalStateV1(
        key: key,
        vector12: List<double>.filled(12, 0.5),
        sampleCount: 10,
        updatedAtUtc: DateTime.now().toUtc(),
        confidence12: List<double>.filled(12, 0.5),
      );

      final localStore = LocalityAgentLocalStoreV1(storage: StorageService.instance);
      final globalRepo = _FakeGlobalRepo(byKey: {key.stableKey: global});
      final engine = LocalityAgentEngineV1(globalRepo: globalRepo, localStore: localStore);

      await localStore.saveDelta(
        agentId: 'agent_abc',
        delta: LocalityAgentPersonalDeltaV1(
          key: key,
          delta12: [
            0.1,
            ...List<double>.filled(11, 0.0),
          ],
          visitCount: 1,
          updatedAtUtc: DateTime.now().toUtc(),
        ),
      );

      final inferred = await engine.inferVector12(agentId: 'agent_abc', key: key);
      expect(inferred[0], closeTo(0.6, 1e-6)); // 0.5 + 0.1
    });
  });
}

