// MIGRATION_SHIM: LEGACY_PATH_GUARD TEMPORARY UNTIL TARGET-ROOT MIGRATION
import 'package:avrai/core/ai/personality_learning.dart';
import 'package:avrai/core/ai2ai/locality/continuous_learning_mirror.dart';
import 'package:avrai/core/ai2ai/locality/learning_insight_application_lane.dart';
import 'package:avrai/runtime/avrai_runtime_os/services/transport/ble/event_mode_buffered_learning_insight.dart';
import 'package:avrai/runtime/avrai_runtime_os/services/transport/ble/event_mode_learning_buffer_lane.dart';
import 'package:avrai/runtime/avrai_runtime_os/kernel/contracts/urk_kernel_activation_engine_contract.dart';
import 'package:avrai/runtime/avrai_runtime_os/kernel/contracts/urk_runtime_activation_receipt_dispatcher.dart';
import 'package:avrai/core/services/infrastructure/logger.dart';

class LearningInsightApplyOrchestrationLane {
  const LearningInsightApplyOrchestrationLane._();

  static Future<bool> applyForPeer({
    required bool eventModeEnabled,
    required String userId,
    required PersonalityLearning personalityLearning,
    required String peerId,
    required AI2AILearningInsight insight,
    required DateTime now,
    required String source,
    required String? insightId,
    required double learningQuality,
    required Map<String, double> deltas,
    required List<EventModeBufferedLearningInsight> eventModeLearningBuffer,
    required Map<String, DateTime> lastAi2AiLearningAtByPeerId,
    required UrkRuntimeActivationReceiptDispatcher? urkActivationDispatcher,
    required AppLogger logger,
    required String logName,
  }) async {
    final applied = await LearningInsightApplicationLane.apply(
      eventModeEnabled: eventModeEnabled,
      evolveFromAi2AiLearning: () =>
          personalityLearning.evolveFromAI2AILearning(userId, insight),
      onEventModeBuffer: () {
        EventModeLearningBufferLane.buffer(
          buffer: eventModeLearningBuffer,
          insight: EventModeBufferedLearningInsight(
            source: source,
            insightId: insightId,
            senderDeviceId: peerId,
            receivedAt: now,
            learningQuality: learningQuality,
            deltas: deltas,
          ),
        );
        lastAi2AiLearningAtByPeerId[peerId] = now;
      },
      onApplied: () {
        lastAi2AiLearningAtByPeerId[peerId] = now;
        ContinuousLearningMirror.mirrorInsight(
          userId: userId,
          insight: insight,
          peerId: peerId,
          logger: logger,
          logTag: logName,
        );
      },
    );
    if (applied) {
      await urkActivationDispatcher?.dispatch(
        requestId: 'ai2ai_${peerId}_${now.millisecondsSinceEpoch}',
        trigger: 'ai2ai_private_mesh_sync',
        privacyMode: UrkPrivacyMode.privateMesh,
        actor: logName,
        reason: 'learning_insight_applied:$source',
      );
    }
    return applied;
  }
}
