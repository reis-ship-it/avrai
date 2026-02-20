import 'package:flutter_test/flutter_test.dart';

import 'package:avrai/core/ai/memory/consolidation/on_device_world_model_training_service.dart';

void main() {
  group('OnDeviceWorldModelTrainingService', () {
    test('triggers strict local-first world-model training', () async {
      bool? strictParam;
      final service = OnDeviceWorldModelTrainingService(
        trigger: ({required bool requireStrictLocalFirst}) async {
          strictParam = requireStrictLocalFirst;
          return true;
        },
      );

      final result = await service.runAfterConsolidation();
      expect(strictParam, isTrue);
      expect(result.strictLocalFirst, isTrue);
      expect(result.status, OnDeviceWorldModelTrainingStatus.triggered);
    });

    test('returns skipped when retraining trigger does not fire', () async {
      final service = OnDeviceWorldModelTrainingService(
        trigger: ({required bool requireStrictLocalFirst}) async => false,
      );

      final result = await service.runAfterConsolidation();
      expect(result.strictLocalFirst, isTrue);
      expect(result.status, OnDeviceWorldModelTrainingStatus.skipped);
    });
  });
}
