import 'package:avrai_core/schemas/semantic_tuple.dart';
import 'package:avrai_runtime_os/kernel/what/what_kernel_contract.dart';
import 'package:avrai_runtime_os/kernel/what/what_models.dart';
import 'package:avrai_runtime_os/kernel/what/what_observation_intake_service.dart';
import 'package:avrai_runtime_os/kernel/what/what_runtime_ingestion_service.dart';
import 'package:avrai_runtime_os/kernel/what/what_runtime_recovery_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('What runtime activation services', () {
    test('ingestion service converts tuples into what observations', () async {
      final kernel = _FakeWhatKernel();
      final service = DefaultWhatRuntimeIngestionService(
        kernel: kernel,
        intake: const WhatObservationIntakeService(),
      );

      final receipt = await service.ingestSemanticTuples(
        source: 'test_source',
        entityRef: 'spot:cafe',
        agentId: 'agent-1',
        tuples: <SemanticTuple>[
          SemanticTuple(
            id: 'tuple-1',
            category: 'place',
            subject: 'user',
            predicate: 'prefers',
            object: 'coffee shop',
            confidence: 0.9,
            extractedAt: DateTime.utc(2026, 3, 6),
          ),
        ],
      );

      expect(receipt, isNotNull);
      expect(kernel.observations.single.entityRef, 'spot:cafe');
      expect(
        kernel.observations.single.observationKind,
        WhatObservationKind.tupleIntake,
      );
    });

    test('ambient social ingestion converts evidence into ambient social events',
        () async {
      final kernel = _FakeWhatKernel();
      final service = DefaultWhatRuntimeIngestionService(
        kernel: kernel,
        intake: const WhatObservationIntakeService(),
      );

      final receipt = await service.ingestAmbientSocialObservation(
        entityRef: 'ambient_social_scene:locality=bham-downtown',
        observedAtUtc: DateTime.utc(2026, 3, 14, 1),
        agentId: 'agent-1',
        socialContext: 'small_group',
        activityContext: 'ambient_socializing',
        structuredSignals: const <String, dynamic>{
          'discoveredPeerCount': 3,
          'confirmedInteractivePeerCount': 1,
          'localityStableKey': 'bham-downtown',
        },
        semanticTuples: <SemanticTuple>[
          SemanticTuple(
            id: 'ambient-1',
            category: 'social_context',
            subject: 'ambient_social_scene',
            predicate: 'recognized_social_density',
            object: 'small_group',
            confidence: 0.9,
            extractedAt: DateTime.utc(2026, 3, 14, 1),
          ),
        ],
      );

      expect(receipt, isNotNull);
      expect(kernel.observations.single.entityRef,
          'ambient_social_scene:locality=bham-downtown');
      expect(
        kernel.observations.single.observationKind,
        WhatObservationKind.ambientSocialEvent,
      );
      expect(kernel.observations.single.socialContext, 'small_group');
      expect(
        kernel.observations.single.activityContext,
        'ambient_socializing',
      );
    });

    test('recovery service persists snapshots after recovery', () async {
      SharedPreferences.setMockInitialValues(const <String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      final kernel = _FakeWhatKernel();
      final recovery = WhatRuntimeRecoveryService(
        kernel: kernel,
        prefs: prefs,
      );

      final result = await recovery.recoverForAgent('agent-1');

      expect(result, isNull);
      expect(
        prefs.getString('avrai_what_kernel_persisted_envelope_v1'),
        isNotNull,
      );
    });
  });
}

class _FakeWhatKernel extends WhatKernelContract {
  final List<WhatObservation> observations = <WhatObservation>[];

  @override
  Future<WhatRecoveryResult> recoverWhat(WhatRecoveryRequest request) async {
    return WhatRecoveryResult(
      restoredCount: 1,
      droppedCount: 0,
      schemaVersion: 1,
      savedAtUtc: DateTime.utc(2026, 3, 6),
    );
  }

  @override
  Future<WhatState> resolveWhat(WhatPerceptionInput input) async {
    throw UnimplementedError();
  }

  @override
  Future<WhatUpdateReceipt> observeWhat(WhatObservation observation) async {
    observations.add(observation);
    return WhatUpdateReceipt(state: _state(observation.entityRef));
  }

  @override
  WhatProjection projectWhat(WhatProjectionRequest request) {
    throw UnimplementedError();
  }

  @override
  WhatKernelSnapshot? snapshotWhat(String agentId) {
    return WhatKernelSnapshot(
      agentId: agentId,
      savedAtUtc: DateTime.utc(2026, 3, 6),
      states: <WhatState>[_state('spot:cafe')],
    );
  }

  @override
  Future<WhatSyncResult> syncWhat(WhatSyncRequest request) async {
    throw UnimplementedError();
  }

  WhatState _state(String entityRef) {
    return WhatState(
      entityRef: entityRef,
      canonicalType: 'cafe',
      subtypes: const <String>['third_place'],
      aliases: const <String>['coffee shop'],
      placeType: 'cafe',
      activityTypes: const <String>['deep_work'],
      socialContexts: const <String>['solo'],
      affordanceVector: const <String, double>{'focus': 0.8},
      vibeSignature: const <String, double>{'calm': 0.7},
      userRelation: WhatUserRelation.prefers,
      lifecycleState: WhatLifecycleState.trusted,
      novelty: 0.4,
      familiarity: 0.8,
      trust: 0.85,
      saturation: 0.2,
      confidence: 0.88,
      evidenceCount: 5,
      firstObservedAtUtc: DateTime.utc(2026, 3, 1),
      lastObservedAtUtc: DateTime.utc(2026, 3, 6),
      sourceMix: const WhatSourceMix(tuple: 0.7, structured: 0.3),
      lineageRefs: const <String>['seed'],
    );
  }
}
