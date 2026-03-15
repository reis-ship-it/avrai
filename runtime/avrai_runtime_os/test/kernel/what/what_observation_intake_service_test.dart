import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_core/schemas/semantic_tuple.dart';
import 'package:avrai_runtime_os/kernel/what/what_models.dart';
import 'package:avrai_runtime_os/kernel/what/what_observation_intake_service.dart';

void main() {
  group('WhatObservationIntakeService', () {
    test('converts semantic tuples into a typed what observation', () {
      const service = WhatObservationIntakeService();
      final tuple = SemanticTuple(
        id: 'tuple_1',
        category: 'routine',
        subject: 'user_self',
        predicate: 'dwelled_at',
        object: 'location_category_cafe',
        confidence: 0.85,
        extractedAt: DateTime.utc(2026, 3, 7, 12),
      );

      final observation = service.fromSemanticTuples(
        agentId: 'agent_1',
        source: 'air_gap',
        entityRef: 'spot:cafe',
        tuples: [tuple],
      );

      expect(observation.observationKind, WhatObservationKind.tupleIntake);
      expect(observation.entityRef, 'spot:cafe');
      expect(
          observation.semanticTuples.single.object, 'location_category_cafe');
      expect(observation.confidence, closeTo(0.85, 0.0001));
    });
  });
}
