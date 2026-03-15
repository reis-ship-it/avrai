import 'package:avrai_runtime_os/kernel/locality/locality_cloud_prior_gateway.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_cloud_update_gateway.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_infrastructure_bridge.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_native_sync_payload_builder.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_state.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_token.dart';
import 'package:avrai_runtime_os/services/locality_agents/locality_agent_models_v1.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocalityNativeSyncPayloadBuilder', () {
    test('enriches sync payload with snapshot and global state', () async {
      const key = LocalityAgentKeyV1(
        geohashPrefix: 'dr5ru7k',
        precision: 7,
        cityCode: 'birmingham_alabama',
      );
      final builder = LocalityNativeSyncPayloadBuilder(
        infrastructureBridge: LocalityInfrastructureBridge(
          cloudPriorGateway:
              _FakePriorGateway(LocalityAgentGlobalStateV1.empty(key)),
          cloudUpdateGateway: _FakeUpdateGateway(),
        ),
      );
      final snapshot = LocalityKernelSnapshot(
        agentId: 'agent-1',
        state: LocalityState(
          activeToken: const LocalityToken(
            kind: LocalityTokenKind.geohashCell,
            id: 'gh7:dr5ru7k',
            alias: 'birmingham_alabama',
          ),
          embedding: const <double>[
            0.5,
            0.5,
            0.5,
            0.5,
            0.5,
            0.5,
            0.5,
            0.5,
            0.5,
            0.5,
            0.5,
            0.5,
          ],
          confidence: 0.5,
          boundaryTension: 0.5,
          reliabilityTier: LocalityReliabilityTier.bootstrap,
          freshness: DateTime.utc(2026, 3, 6, 12),
          evidenceCount: 1,
          evolutionRate: 0.0,
          advisoryStatus: LocalityAdvisoryStatus.inactive,
          sourceMix: const LocalitySourceMix.syntheticBootstrap(),
        ),
        savedAtUtc: DateTime.utc(2026, 3, 6, 12),
      );

      final payload = await builder.build(
        const LocalitySyncRequest(
          agentId: 'agent-1',
          allowCloud: true,
          allowMesh: true,
        ),
        snapshot: snapshot,
      );

      expect(payload['snapshot'], isNotNull);
      expect(payload['globalState'], isNotNull);
      expect(payload['neighborMeshUpdates'], isEmpty);
      expect(payload['syncedAtUtc'], isNotNull);
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

class _FakeUpdateGateway implements LocalityCloudUpdateGateway {
  @override
  Future<void> emitObservation({
    required String userId,
    required LocalityAgentUpdateEventV1 event,
  }) async {}
}
