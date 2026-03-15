import 'package:avrai_runtime_os/kernel/locality/locality_cloud_prior_gateway.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_cloud_update_gateway.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_infrastructure_bridge.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_memory.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai_runtime_os/services/locality_agents/locality_agent_models_v1.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocalityInfrastructureBridge', () {
    test('provides global state and empty mesh context without locality memory',
        () async {
      const key = LocalityAgentKeyV1(
        geohashPrefix: 'dr5ru7k',
        precision: 7,
        cityCode: 'birmingham_alabama',
      );
      final expected = LocalityAgentGlobalStateV1.empty(key);
      final bridge = LocalityInfrastructureBridge(
        cloudPriorGateway: _FakePriorGateway(expected),
        cloudUpdateGateway: _FakeUpdateGateway(),
      );

      final resolved = await bridge.fetchGlobalState(key);
      final neighborMesh = bridge.readNeighborMeshUpdates(key);

      expect(resolved, expected);
      expect(neighborMesh, isEmpty);
    });

    test('uses cached global state when remote refresh fails offline',
        () async {
      const key = LocalityAgentKeyV1(
        geohashPrefix: 'dr5ru7k',
        precision: 7,
        cityCode: 'birmingham_alabama',
      );
      final memory = LocalityMemory(storage: _FakeStorageService());
      final cached = LocalityAgentGlobalStateV1(
        key: key,
        vector12: const <double>[
          0.8,
          0.7,
          0.6,
          0.5,
          0.4,
          0.3,
          0.2,
          0.1,
          0.9,
          0.8,
          0.7,
          0.6,
        ],
        sampleCount: 12,
        updatedAtUtc: DateTime.utc(2026, 3, 6, 12),
        confidence12: const <double>[
          0.8,
          0.8,
          0.8,
          0.8,
          0.8,
          0.8,
          0.8,
          0.8,
          0.8,
          0.8,
          0.8,
          0.8,
        ],
      );
      await memory.saveGlobalState(state: cached);

      final bridge = LocalityInfrastructureBridge(
        cloudPriorGateway: _ThrowingPriorGateway(),
        cloudUpdateGateway: _FakeUpdateGateway(),
        memory: memory,
      );

      final resolved = await bridge.fetchGlobalState(key);

      expect(resolved.sampleCount, cached.sampleCount);
      expect(resolved.vector12, cached.vector12);
    });
  });
}

class _FakePriorGateway implements LocalityCloudPriorGateway {
  _FakePriorGateway(this.state);

  final LocalityAgentGlobalStateV1 state;

  @override
  Future<LocalityAgentGlobalStateV1> fetchGlobalState(
    LocalityAgentKeyV1 key,
  ) async {
    return state;
  }
}

class _ThrowingPriorGateway implements LocalityCloudPriorGateway {
  @override
  Future<LocalityAgentGlobalStateV1> fetchGlobalState(
    LocalityAgentKeyV1 key,
  ) async {
    throw StateError('offline');
  }
}

class _FakeUpdateGateway implements LocalityCloudUpdateGateway {
  @override
  Future<void> emitObservation({
    required String userId,
    required LocalityAgentUpdateEventV1 event,
  }) async {}
}

class _FakeStorageService implements StorageService {
  final Map<String, Map<String, dynamic>> _objects =
      <String, Map<String, dynamic>>{};

  @override
  T? getObject<T>(String key, {String box = 'spots_default'}) {
    return _objects[key] as T?;
  }

  @override
  Future<bool> setObject(String key, dynamic value,
      {String box = 'spots_default'}) async {
    _objects[key] = value;
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
