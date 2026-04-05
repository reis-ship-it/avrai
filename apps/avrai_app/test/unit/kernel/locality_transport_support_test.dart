import 'package:avrai_runtime_os/kernel/locality/locality_cloud_prior_gateway.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_cloud_update_gateway.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_infrastructure_bridge.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_state.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_transport_support.dart';
import 'package:avrai_runtime_os/services/locality_agents/locality_agent_models_v1.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocalityTransportSupport', () {
    test(
        'operates without Dart locality memory when running legacy fallback off',
        () async {
      const key = LocalityAgentKeyV1(
        geohashPrefix: 'dr5ru7k',
        precision: 7,
        cityCode: 'birmingham_alabama',
      );
      final updateGateway = _FakeUpdateGateway();
      final support = LocalityTransportSupport(
        infrastructureBridge: LocalityInfrastructureBridge(
          cloudPriorGateway: _FakePriorGateway(),
          cloudUpdateGateway: updateGateway,
        ),
      );

      final emitted = await support.emitObservation(
        LocalityObservation(
          userId: 'user-1',
          agentId: 'agent-1',
          type: LocalityObservationType.visitComplete,
          key: key,
          occurredAtUtc: DateTime.utc(2026, 3, 6, 12),
          localStateCapturedAtUtc: DateTime.utc(2026, 3, 6, 12, 5),
          source: 'test',
          kernelExchangePhase: 'locality_observation_emit',
        ),
      );
      final imported = await support.ingestMeshUpdate(
        key: key,
        delta12: const <double>[
          0.1,
          0.2,
          0.0,
          0.1,
          0.0,
          0.0,
          0.1,
          0.0,
          0.2,
          0.0,
          0.1,
          0.0,
        ],
        ttlMs: 60000,
        hop: 0,
      );
      final syncResult = await support.sync(
        const LocalitySyncRequest(
          agentId: 'agent-1',
          allowCloud: true,
          allowMesh: true,
        ),
      );

      expect(emitted, isTrue);
      expect(updateGateway.lastEvent, isNotNull);
      expect(
        updateGateway.lastEvent!.occurredAtUtc,
        DateTime.utc(2026, 3, 6, 12),
      );
      expect(
        updateGateway.lastEvent!.localStateCapturedAtUtc,
        DateTime.utc(2026, 3, 6, 12, 5),
      );
      expect(updateGateway.lastEvent!.emittedAtUtc, isNotNull);
      expect(
        updateGateway.lastEvent!.kernelExchangePhase,
        'locality_observation_emit',
      );
      expect(imported, isFalse);
      expect(syncResult.synced, isTrue);
    });
  });
}

class _FakePriorGateway implements LocalityCloudPriorGateway {
  @override
  Future<LocalityAgentGlobalStateV1> fetchGlobalState(
    LocalityAgentKeyV1 key,
  ) async {
    return LocalityAgentGlobalStateV1.empty(key);
  }
}

class _FakeUpdateGateway implements LocalityCloudUpdateGateway {
  LocalityAgentUpdateEventV1? lastEvent;

  @override
  Future<void> emitObservation({
    required String userId,
    required LocalityAgentUpdateEventV1 event,
  }) async {
    lastEvent = event;
  }
}
