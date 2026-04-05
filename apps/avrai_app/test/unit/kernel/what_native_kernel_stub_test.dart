import 'package:avrai_runtime_os/kernel/what/what_kernel_contract.dart';
import 'package:avrai_runtime_os/kernel/what/what_models.dart';
import 'package:avrai_runtime_os/kernel/what/what_native_kernel_stub.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart'
    show KernelAuthorityLevel;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WhatNativeKernelStub', () {
    test('round-trips in-process what syscalls', () async {
      final delegate = _FakeWhatKernel();
      final stub = WhatNativeKernelStub(
        transport: InProcessWhatSyscallTransport(delegate: delegate),
      );

      final resolved = await stub.resolveWhat(
        WhatPerceptionInput(
          agentId: 'agent-1',
          observedAtUtc: DateTime.utc(2026, 3, 6),
          source: 'test',
          entityRef: 'spot:cafe',
          candidateLabels: const <String>['coffee shop'],
        ),
      );
      final receipt = await stub.observeWhat(
        WhatObservation(
          agentId: 'agent-1',
          observedAtUtc: DateTime.utc(2026, 3, 6, 1),
          source: 'test',
          entityRef: 'spot:cafe',
          observationKind: WhatObservationKind.visit,
          activityContext: 'deep_work',
        ),
      );
      final projection = stub.projectWhat(
        const WhatProjectionRequest(
          agentId: 'agent-1',
          entityRef: 'spot:cafe',
        ),
      );
      final snapshot = stub.snapshotWhat('agent-1');
      final reality = await stub.projectForRealityModel(
        const WhatProjectionRequest(
          agentId: 'agent-1',
          entityRef: 'spot:cafe',
        ),
      );
      final governance = await stub.projectForGovernance(
        const WhatProjectionRequest(
          agentId: 'agent-1',
          entityRef: 'spot:cafe',
        ),
      );
      final health = await stub.diagnoseWhat();

      expect(resolved.canonicalType, 'cafe');
      expect(receipt.state.activityTypes, contains('deep_work'));
      expect(projection.projectedTypes, contains('third_place'));
      expect(snapshot, isNotNull);
      expect(snapshot!.states.first.entityRef, 'spot:cafe');
      expect(reality.summary, contains('spot:cafe'));
      expect(
        reality.features['projected_types'],
        contains('third_place'),
      );
      expect(governance.summary, contains('spot:cafe'));
      expect(governance.highlights, contains('third_place'));
      expect(health.nativeBacked, isTrue);
      expect(health.authorityLevel, KernelAuthorityLevel.authoritative);
    });
  });
}

class _FakeWhatKernel extends WhatKernelFallbackSurface {
  final WhatState _state = WhatState(
    entityRef: 'spot:cafe',
    canonicalType: 'cafe',
    subtypes: const <String>['third_place'],
    aliases: const <String>['coffee shop'],
    placeType: 'cafe',
    activityTypes: const <String>['deep_work'],
    socialContexts: const <String>['solo'],
    affordanceVector: const <String, double>{'focus': 0.82},
    vibeSignature: const <String, double>{'calm': 0.76},
    userRelation: WhatUserRelation.prefers,
    lifecycleState: WhatLifecycleState.trusted,
    novelty: 0.42,
    familiarity: 0.78,
    trust: 0.84,
    saturation: 0.21,
    confidence: 0.88,
    evidenceCount: 4,
    firstObservedAtUtc: DateTime.utc(2026, 3, 1),
    lastObservedAtUtc: DateTime.utc(2026, 3, 6),
    sourceMix: const WhatSourceMix(tuple: 0.6, structured: 0.4),
    lineageRefs: const <String>['seed'],
  );

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
  Future<WhatState> resolveWhat(WhatPerceptionInput input) async => _state;

  @override
  Future<WhatUpdateReceipt> observeWhat(WhatObservation observation) async {
    return WhatUpdateReceipt(state: _state);
  }

  @override
  WhatProjection projectWhat(WhatProjectionRequest request) {
    return const WhatProjection(
      baseEntityRef: 'spot:cafe',
      projectedTypes: <String>['third_place'],
      adjacentOpportunities: <String>['solo work refuge'],
      confidence: 0.73,
      basis: 'test',
    );
  }

  @override
  WhatKernelSnapshot? snapshotWhat(String agentId) {
    return WhatKernelSnapshot(
      agentId: agentId,
      savedAtUtc: DateTime.utc(2026, 3, 6),
      states: <WhatState>[_state],
    );
  }

  @override
  Future<WhatSyncResult> syncWhat(WhatSyncRequest request) async {
    return WhatSyncResult(
      acceptedCount: request.deltas.length,
      rejectedCount: 0,
      mergedEntityRefs: request.deltas.map((e) => e.entityRef).toList(),
      savedAtUtc: DateTime.utc(2026, 3, 6),
    );
  }
}
