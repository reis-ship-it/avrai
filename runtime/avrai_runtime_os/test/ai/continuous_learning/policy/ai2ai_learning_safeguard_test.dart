import 'package:avrai_core/models/atomic_timestamp.dart';
import 'package:avrai_network/network/rate_limiter.dart';
import 'package:avrai_runtime_os/ai/continuous_learning/policy/ai2ai_learning_safeguard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Ai2AiLearningSafeguard', () {
    test('continues to throttle AI2AI learning through the limiter class',
        () async {
      final rateLimiter = RateLimiter();
      final payload = <String, dynamic>{
        'source': 'ai2ai',
        'peer_id': 'peer-learning',
        'learning_quality': 0.95,
      };
      final lastLearningByPeer = <String, AtomicTimestamp>{};

      for (var index = 0; index < 16; index += 1) {
        final allowed = await Ai2AiLearningSafeguard.passesPreChecks(
          payload: payload,
          lastLearningByPeer: lastLearningByPeer,
          rateLimiter: rateLimiter,
          logName: 'Ai2AiLearningSafeguardTest',
        );
        if (index < 15) {
          expect(allowed, isTrue);
        } else {
          expect(allowed, isFalse);
        }
      }

      expect(lastLearningByPeer, isEmpty);
      rateLimiter.dispose();
    });
  });
}
