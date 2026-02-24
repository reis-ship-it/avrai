import 'package:flutter_test/flutter_test.dart';

import 'package:avrai/core/ai/negative_outcome_signal_detector.dart';

void main() {
  group('NegativeOutcomeSignalDetector', () {
    const detector = NegativeOutcomeSignalDetector(absenceThresholdDays: 3);

    test('emits negative outcome when user does not return beyond threshold',
        () {
      final signal = detector.detect(
        recommendationId: 'rec-1',
        recommendationSeenAt: DateTime.utc(2026, 2, 20, 10),
        appClosedAt: DateTime.utc(2026, 2, 20, 10, 1),
        returnedAt: null,
        now: DateTime.utc(2026, 2, 24, 12),
      );

      expect(signal, isNotNull);
      expect(signal!.eventType, 'recommendation_post_view_abandonment');
      expect(signal.isNegative, isTrue);
      expect(signal.daysAbsent, greaterThanOrEqualTo(3));
    });

    test('does not mark as negative when user returns quickly', () {
      final signal = detector.detect(
        recommendationId: 'rec-2',
        recommendationSeenAt: DateTime.utc(2026, 2, 20, 10),
        appClosedAt: DateTime.utc(2026, 2, 20, 10, 1),
        returnedAt: DateTime.utc(2026, 2, 21, 8),
        now: DateTime.utc(2026, 2, 25),
      );

      expect(signal, isNotNull);
      expect(signal!.isNegative, isFalse);
      expect(signal.daysAbsent, lessThan(3));
    });

    test('returns null when close signal is missing', () {
      final signal = detector.detect(
        recommendationId: 'rec-3',
        recommendationSeenAt: DateTime.utc(2026, 2, 20, 10),
        appClosedAt: null,
        returnedAt: null,
        now: DateTime.utc(2026, 2, 24),
      );

      expect(signal, isNull);
    });

    test('returns null for invalid ordering and future timestamps', () {
      final closedBeforeSeen = detector.detect(
        recommendationId: 'rec-4',
        recommendationSeenAt: DateTime.utc(2026, 2, 20, 10),
        appClosedAt: DateTime.utc(2026, 2, 20, 9),
        returnedAt: null,
        now: DateTime.utc(2026, 2, 24),
      );
      expect(closedBeforeSeen, isNull);

      final closedInFuture = detector.detect(
        recommendationId: 'rec-5',
        recommendationSeenAt: DateTime.utc(2026, 2, 20, 10),
        appClosedAt: DateTime.utc(2026, 2, 25, 10),
        returnedAt: null,
        now: DateTime.utc(2026, 2, 24),
      );
      expect(closedInFuture, isNull);
    });

    test('supports per-call threshold override', () {
      final signal = detector.detect(
        recommendationId: 'rec-6',
        recommendationSeenAt: DateTime.utc(2026, 2, 20, 10),
        appClosedAt: DateTime.utc(2026, 2, 20, 10, 1),
        returnedAt: null,
        now: DateTime.utc(2026, 2, 22, 12),
        thresholdDaysOverride: 2,
      );
      expect(signal, isNotNull);
      expect(signal!.thresholdDays, 2);
      expect(signal.isNegative, isTrue);
    });
  });
}
