import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_runtime_os/kernel/what/legacy/dart_what_fallback_kernel.dart';
import 'package:avrai_runtime_os/kernel/what/what_models.dart';

void main() {
  group('DartWhatFallbackKernel', () {
    test('promotes repeated cafe visits into trusted semantic state', () async {
      final kernel = DartWhatFallbackKernel();
      const agentId = 'agent_1';
      const entityRef = 'spot:cafe';

      await kernel.resolveWhat(
        WhatPerceptionInput(
          agentId: agentId,
          observedAtUtc: DateTime.utc(2026, 3, 7, 9),
          source: 'seed',
          entityRef: entityRef,
          candidateLabels: ['coffee shop'],
        ),
      );

      for (var i = 0; i < 7; i++) {
        await kernel.observeWhat(
          WhatObservation(
            agentId: agentId,
            observedAtUtc: DateTime.utc(2026, 3, 7, 10 + i),
            source: 'visit',
            entityRef: entityRef,
            observationKind: WhatObservationKind.visit,
            activityContext: 'deep_work',
          ),
        );
      }

      final snapshot = kernel.snapshotWhat(agentId);
      expect(snapshot, isNotNull);
      final state = snapshot!.states.single;
      expect(state.canonicalType, 'cafe');
      expect(state.lifecycleState, WhatLifecycleState.trusted);
      expect(state.userRelation, WhatUserRelation.prefers);
      expect(state.affordanceVector.containsKey('focus'), isTrue);
    });
  });
}
