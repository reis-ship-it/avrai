import 'package:avrai_core/models/spots/visit.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_cloud_prior_gateway.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_cloud_update_gateway.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_inference_head.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_infrastructure_bridge.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_memory.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai_runtime_os/services/locality_agents/locality_agent_models_v1.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/platform_channel_helper.dart';
import '../../mocks/mock_storage_service.dart';

void main() {
  group('LocalityInferenceHead', () {
    late LocalityMemory memory;
    late LocalityInferenceHead head;

    setUp(() async {
      MockGetStorage.reset();
      await StorageService.instance.initForTesting(
        defaultStorage: MockGetStorage.getInstance(boxName: 'spots_default'),
        userStorage: MockGetStorage.getInstance(boxName: 'spots_user'),
        aiStorage: MockGetStorage.getInstance(boxName: 'spots_ai'),
        analyticsStorage:
            MockGetStorage.getInstance(boxName: 'spots_analytics'),
      );
      memory = LocalityMemory(storage: StorageService.instance);
      head = LocalityInferenceHead(
        memory: memory,
        infrastructureBridge: LocalityInfrastructureBridge(
          cloudPriorGateway: _FixedPriorGateway(),
          cloudUpdateGateway: _NoopUpdateGateway(),
          memory: memory,
        ),
      );
    });

    test('preserves origin and local capture timing in resolved locality state',
        () async {
      const key = LocalityAgentKeyV1(
        geohashPrefix: 'dr5ru7k',
        precision: 7,
        cityCode: 'birmingham_alabama',
      );
      final visit = Visit(
        id: 'visit-1',
        userId: 'user-1',
        locationId: 'spot-1',
        checkInTime: DateTime.utc(2026, 4, 1, 12),
        checkOutTime: DateTime.utc(2026, 4, 1, 12, 45),
        dwellTime: const Duration(minutes: 45),
        qualityScore: 1.0,
        createdAt: DateTime.utc(2026, 4, 1, 12),
        updatedAt: DateTime.utc(2026, 4, 1, 12, 45),
      );

      final computation = await head.observeVisit(
        agentId: 'agent-1',
        key: key,
        visit: visit,
        topAlias: 'Birmingham',
      );

      expect(computation.delta.originOccurredAtUtc, visit.checkInTime.toUtc());
      expect(computation.delta.localStateCapturedAtUtc, isNotNull);
      expect(
        computation.delta.kernelExchangePhase,
        'locality_personal_visit_captured',
      );
      expect(
        computation.state.originOccurredAtUtc,
        computation.delta.originOccurredAtUtc,
      );
      expect(
        computation.state.localStateCapturedAtUtc,
        computation.delta.localStateCapturedAtUtc,
      );
      expect(computation.state.lastSyncAtUtc, isNotNull);
      expect(
        computation.state.effectiveTemporalFreshnessAt,
        computation.state.localStateCapturedAtUtc,
      );
      expect(
        computation.state.freshness.isAfter(DateTime.utc(2026, 4, 1, 9)),
        isTrue,
      );
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });
  });
}

class _FixedPriorGateway implements LocalityCloudPriorGateway {
  @override
  Future<LocalityAgentGlobalStateV1> fetchGlobalState(
    LocalityAgentKeyV1 key,
  ) async {
    return LocalityAgentGlobalStateV1(
      key: key,
      vector12: List<double>.filled(12, 0.5),
      sampleCount: 6,
      confidence12: List<double>.filled(12, 0.7),
      updatedAtUtc: DateTime.utc(2026, 4, 1, 9),
      syncedAtUtc: DateTime.utc(2026, 4, 2, 8),
    );
  }
}

class _NoopUpdateGateway implements LocalityCloudUpdateGateway {
  @override
  Future<void> emitObservation({
    required String userId,
    required LocalityAgentUpdateEventV1 event,
  }) async {}
}
