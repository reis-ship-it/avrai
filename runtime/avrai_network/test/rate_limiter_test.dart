import 'package:avrai_network/network/rate_limiter.dart';
import 'package:test/test.dart';

void main() {
  group('RateLimiter', () {
    test(
      'uses protocol-independent message classes for AI2AI-aware limits',
      () async {
        final learningLimiter = RateLimiter();
        final personalityLimiter = RateLimiter();

        for (var index = 0; index < 7; index += 1) {
          expect(
            await personalityLimiter.checkRateLimit(
              peerAgentId: 'peer-personality',
              limitType: RateLimitType.message,
              messageClass: RateLimitedMessageClass.personalityExchange,
            ),
            isTrue,
          );
        }
        expect(
          await personalityLimiter.checkRateLimit(
            peerAgentId: 'peer-personality',
            limitType: RateLimitType.message,
            messageClass: RateLimitedMessageClass.personalityExchange,
          ),
          isFalse,
        );

        for (var index = 0; index < 8; index += 1) {
          expect(
            await learningLimiter.checkRateLimit(
              peerAgentId: 'peer-learning',
              limitType: RateLimitType.message,
              messageClass: RateLimitedMessageClass.learningInsight,
            ),
            isTrue,
          );
        }

        learningLimiter.dispose();
        personalityLimiter.dispose();
      },
    );
  });
}
