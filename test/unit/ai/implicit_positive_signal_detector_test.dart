import 'package:flutter_test/flutter_test.dart';

import 'package:avrai/core/ai/implicit_positive_signal_detector.dart';

void main() {
  group('ImplicitPositiveSignalDetector', () {
    const detector = ImplicitPositiveSignalDetector();

    test('detects return visit within 30 days', () {
      final signal = detector.detectReturnVisitSignal(
        spotId: 'spot-1',
        previousVisitAt: DateTime.utc(2026, 2, 1),
        currentVisitAt: DateTime.utc(2026, 2, 20),
      );

      expect(signal, isNotNull);
      expect(signal!.eventType, 'return_visit_within_days');
      expect(signal.metadata['days'], 19);
    });

    test('detects recommendation notification opened within one hour', () {
      final signal = detector.detectNotificationOpenSignal(
        recommendationId: 'rec-1',
        recommendationSentAt: DateTime.utc(2026, 2, 24, 10, 0),
        appOpenedAt: DateTime.utc(2026, 2, 24, 10, 35),
      );

      expect(signal, isNotNull);
      expect(signal!.eventType, 'recommendation_notification_opened');
      expect(signal.metadata['open_latency_minutes'], 35);
    });

    test('detects organic recommendation hit when user did not tap', () {
      final signal = detector.detectOrganicRecommendationHitSignal(
        recommendedEntityId: 'spot-42',
        visitedEntityId: 'spot-42',
        tappedRecommendation: false,
      );

      expect(signal, isNotNull);
      expect(signal!.eventType, 'recommended_entity_visited_organically');
    });

    test('detects long detail dwell over threshold', () {
      final signal = detector.detectDetailDwellSignal(
        entityType: 'spot',
        entityId: 'spot-77',
        durationMs: 61000,
      );

      expect(signal, isNotNull);
      expect(signal!.eventType, 'entity_detail_long_dwell');
      expect(signal.metadata['duration_ms'], 61000);
    });
  });
}
