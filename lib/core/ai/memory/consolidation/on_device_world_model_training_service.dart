import 'dart:developer' as developer;

import 'package:avrai/core/services/ai_infrastructure/online_learning_service.dart';

typedef WorldModelTrainingTrigger = Future<bool> Function({
  required bool requireStrictLocalFirst,
});

enum OnDeviceWorldModelTrainingStatus {
  triggered,
  skipped,
}

class OnDeviceWorldModelTrainingResult {
  final OnDeviceWorldModelTrainingStatus status;
  final bool strictLocalFirst;

  const OnDeviceWorldModelTrainingResult({
    required this.status,
    required this.strictLocalFirst,
  });
}

/// Phase 1.1C.6 hook: run on-device world model training after consolidation.
///
/// This uses the strict local-first retraining path to avoid remote fallback.
class OnDeviceWorldModelTrainingService {
  static const String _logName = 'OnDeviceWorldModelTrainingService';

  const OnDeviceWorldModelTrainingService({
    required WorldModelTrainingTrigger trigger,
  }) : _trigger = trigger;

  factory OnDeviceWorldModelTrainingService.fromOnlineLearning({
    required OnlineLearningService onlineLearningService,
  }) {
    return OnDeviceWorldModelTrainingService(
      trigger: ({
        required bool requireStrictLocalFirst,
      }) {
        return onlineLearningService.triggerRetraining(
          modelType: 'outcome',
          reason: 'scheduled',
          requireStrictLocalFirst: requireStrictLocalFirst,
        );
      },
    );
  }

  final WorldModelTrainingTrigger _trigger;

  Future<OnDeviceWorldModelTrainingResult> runAfterConsolidation() async {
    const strictLocalFirst = true;
    final didTrigger = await _trigger(
      requireStrictLocalFirst: strictLocalFirst,
    );

    if (!didTrigger) {
      developer.log(
        'Skipped on-device world model training in consolidation window.',
        name: _logName,
      );
      return const OnDeviceWorldModelTrainingResult(
        status: OnDeviceWorldModelTrainingStatus.skipped,
        strictLocalFirst: strictLocalFirst,
      );
    }

    developer.log(
      'Triggered on-device world model training in consolidation window.',
      name: _logName,
    );
    return const OnDeviceWorldModelTrainingResult(
      status: OnDeviceWorldModelTrainingStatus.triggered,
      strictLocalFirst: strictLocalFirst,
    );
  }
}
