import 'package:avrai_runtime_os/ai2ai/locality/incoming_learning_insight_side_effects.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IncomingLearningInsightSideEffects', () {
    test('emitSuccess reports applied learning and forwards gossip', () {
      var forwardedCount = 0;

      final eventType = IncomingLearningInsightSideEffects.emitSuccess(
        insightId: 'insight-1',
        sender: 'peer-a',
        originId: 'origin-a',
        hop: 1,
        applied: true,
        learningQuality: 0.91,
        deltaDimensionsCount: 3,
        forwardGossip: () {
          forwardedCount++;
        },
      );

      expect(eventType, 'ai2ai_learning_applied');
      expect(forwardedCount, 1);
    });

    test('emitSuccess reports buffered intake and forwards gossip', () {
      var forwardedCount = 0;

      final eventType = IncomingLearningInsightSideEffects.emitSuccess(
        insightId: 'insight-2',
        sender: 'peer-b',
        originId: 'origin-b',
        hop: 2,
        applied: false,
        learningQuality: 0.67,
        deltaDimensionsCount: 2,
        forwardGossip: () {
          forwardedCount++;
        },
      );

      expect(eventType, 'ai2ai_learning_buffered');
      expect(forwardedCount, 1);
    });
  });
}
