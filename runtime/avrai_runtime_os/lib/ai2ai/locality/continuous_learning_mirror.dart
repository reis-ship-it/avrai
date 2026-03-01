// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'dart:async';

import 'package:avrai_runtime_os/ai/continuous_learning_system.dart';
import 'package:avrai_runtime_os/ai/personality_learning.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:get_it/get_it.dart';

class ContinuousLearningMirror {
  const ContinuousLearningMirror._();

  static void mirrorInsight({
    required String userId,
    required AI2AILearningInsight insight,
    required String peerId,
    required AppLogger logger,
    required String logTag,
  }) {
    if (!GetIt.instance.isRegistered<ContinuousLearningSystem>()) return;

    try {
      final continuousLearningSystem =
          GetIt.instance<ContinuousLearningSystem>();
      unawaited(continuousLearningSystem.processAI2AILearningInsight(
        userId: userId,
        insight: insight,
        peerId: peerId,
      ));
    } catch (e) {
      logger.debug(
        'Failed to process AI2AI learning insight in ContinuousLearningSystem: $e',
        tag: logTag,
      );
    }
  }
}
