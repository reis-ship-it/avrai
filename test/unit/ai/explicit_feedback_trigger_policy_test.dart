import 'package:flutter_test/flutter_test.dart';

import 'package:avrai/core/ai/explicit_feedback_trigger_policy.dart';

void main() {
  group('ExplicitFeedbackTriggerPolicy', () {
    const policy = ExplicitFeedbackTriggerPolicy();

    test('post-event trigger is due on next app open after check-in', () {
      final checkInAt = DateTime.utc(2026, 2, 24, 12);
      final appOpenAt = DateTime.utc(2026, 2, 24, 12, 5);

      final decision = policy.postEventTrigger(
        checkInAt: checkInAt,
        appOpenAt: appOpenAt,
        alreadyPrompted: false,
      );

      expect(
        decision.type,
        ExplicitFeedbackTriggerType.postEventNextAppOpenAfterCheckIn,
      );
      expect(decision.isDue, isTrue);
      expect(decision.reason, 'next_app_open_after_checkin');
    });

    test('post-reservation trigger waits for 24-hour window', () {
      final completedAt = DateTime.utc(2026, 2, 24, 8);
      final now = DateTime.utc(2026, 2, 25, 7, 59);

      final decision = policy.postReservationTrigger(
        reservationCompletedAt: completedAt,
        now: now,
        alreadyPrompted: false,
      );

      expect(
          decision.type, ExplicitFeedbackTriggerType.postReservation24hAfter);
      expect(decision.isDue, isFalse);
      expect(decision.reason, 'awaiting_24h_window');
    });

    test('post-community-join trigger is due after seven days', () {
      final joinedAt = DateTime.utc(2026, 2, 1, 10);
      final now = DateTime.utc(2026, 2, 8, 10);

      final decision = policy.postCommunityJoinTrigger(
        communityJoinedAt: joinedAt,
        now: now,
        alreadyPrompted: false,
      );

      expect(
        decision.type,
        ExplicitFeedbackTriggerType.postCommunityJoin7dAfter,
      );
      expect(decision.isDue, isTrue);
      expect(decision.reason, '7d_elapsed');
    });

    test('already prompted gate suppresses trigger regardless of timing', () {
      final decision = policy.postReservationTrigger(
        reservationCompletedAt: DateTime.utc(2026, 2, 20, 8),
        now: DateTime.utc(2026, 2, 24, 8),
        alreadyPrompted: true,
      );

      expect(decision.isDue, isFalse);
      expect(decision.reason, 'already_prompted');
    });
  });
}
