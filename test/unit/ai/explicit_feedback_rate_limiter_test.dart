import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/ai/explicit_feedback_rate_limiter.dart';
import 'package:avrai/core/services/predictive_outreach/outreach_preferences_service.dart';

void main() {
  OutreachPreferences prefs({
    String frequency = 'medium',
    bool enabled = true,
  }) {
    return OutreachPreferences(
      userId: 'u1',
      enabled: enabled,
      frequency: frequency,
      allowCommunityInvitations: true,
      allowGroupFormation: true,
      allowEventCalls: enabled,
      allowBusinessOutreach: true,
      allowClubOutreach: true,
      allowExpertOutreach: true,
      allowListSuggestions: true,
      updatedAt: DateTime.utc(2026, 2, 24),
    );
  }

  group('ExplicitFeedbackRateLimiter', () {
    test('allows only one explicit feedback request per session', () async {
      final limiter = ExplicitFeedbackRateLimiter(
        preferenceResolver: (_) async => prefs(),
      );

      final first = await limiter.canRequest(
        userId: 'u1',
        outreachType: 'event_call',
      );
      expect(first.allowed, isTrue);

      limiter.markRequested(userId: 'u1');

      final second = await limiter.canRequest(
        userId: 'u1',
        outreachType: 'event_call',
      );
      expect(second.allowed, isFalse);
      expect(second.reason, 'session_limit_reached');
    });

    test('blocks back-to-back requests across session boundaries', () async {
      final now = DateTime.utc(2026, 2, 24, 12, 0, 0);
      final limiter = ExplicitFeedbackRateLimiter(
        preferenceResolver: (_) async => prefs(frequency: 'high'),
        nowProvider: () => now,
      );

      limiter.markRequested(userId: 'u1', at: now);
      limiter.resetSession(userId: 'u1');

      final decision = await limiter.canRequest(
        userId: 'u1',
        outreachType: 'event_call',
        now: now.add(const Duration(minutes: 5)),
      );
      expect(decision.allowed, isFalse);
      expect(decision.reason, 'back_to_back_blocked');
      expect(decision.nextAllowedAt, now.add(const Duration(minutes: 15)));
    });

    test('respects outreach preference disablement', () async {
      final limiter = ExplicitFeedbackRateLimiter(
        preferenceResolver: (_) async =>
            prefs(enabled: false, frequency: 'off'),
      );

      final decision = await limiter.canRequest(
        userId: 'u1',
        outreachType: 'event_call',
      );
      expect(decision.allowed, isFalse);
      expect(decision.reason, 'outreach_preferences_blocked');
    });

    test('respects low-frequency cooldown windows', () async {
      final start = DateTime.utc(2026, 2, 24, 10, 0, 0);
      final limiter = ExplicitFeedbackRateLimiter(
        preferenceResolver: (_) async => prefs(frequency: 'low'),
      );
      limiter.markRequested(userId: 'u1', at: start);
      limiter.resetSession(userId: 'u1');

      final blocked = await limiter.canRequest(
        userId: 'u1',
        outreachType: 'event_call',
        now: start.add(const Duration(hours: 4)),
      );
      expect(blocked.allowed, isFalse);

      final allowed = await limiter.canRequest(
        userId: 'u1',
        outreachType: 'event_call',
        now: start.add(const Duration(hours: 6)),
      );
      expect(allowed.allowed, isTrue);
    });
  });
}
