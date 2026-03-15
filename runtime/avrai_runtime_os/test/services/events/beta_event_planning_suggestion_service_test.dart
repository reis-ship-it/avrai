import 'package:avrai_core/models/events/event_planning.dart';
import 'package:avrai_core/models/expertise/expertise_event.dart';
import 'package:avrai_runtime_os/services/events/beta_event_planning_suggestion_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BetaEventPlanningSuggestionService', () {
    const service = BetaEventPlanningSuggestionService();

    EventAirGapProvenance buildProvenance() {
      return EventAirGapProvenance(
        crossingId: 'evtplan_123456_human_host0001',
        crossedAt: DateTime.utc(2026, 3, 14, 12),
        sourceKind: EventPlanningSourceKind.human,
        tupleRefs: <String>['tuple-1'],
        confidence: EventPlanningConfidence.medium,
      );
    }

    test('returns conservative low-confidence suggestion when truth is sparse',
        () {
      final suggestion = service.suggest(
        docket: EventDocketLite(
          intentTags: const <String>['spring'],
          hostGoal: EventHostGoal.community,
          priceIntent: EventPriceIntent.lowCost,
          airGapProvenance: buildProvenance(),
        ),
        eventType: ExpertiseEventType.tour,
        currentStartTime: DateTime.utc(2026, 3, 21, 17, 30),
        defaultDuration: const Duration(hours: 2),
        currentMaxAttendees: 28,
        currentPrice: 18,
      );

      expect(suggestion.confidence, EventPlanningConfidence.low);
      expect(suggestion.suggestedStartTime, DateTime.utc(2026, 3, 21, 17, 30));
      expect(suggestion.suggestedMaxAttendees, 28);
      expect(
          suggestion.predictedAttendanceFillBand, EventAttendanceFillBand.low);
      expect(
        suggestion.explanation,
        contains('keeping this close to your current plan'),
      );
    });

    test('returns stronger guidance when event truth is richer', () {
      final suggestion = service.suggest(
        docket: EventDocketLite(
          intentTags: const <String>['spring', 'music'],
          vibeTags: const <String>['joyful', 'outdoor'],
          audienceTags: const <String>['families', 'neighbors'],
          candidateLocalityLabel: 'Avondale',
          hostGoal: EventHostGoal.celebration,
          sizeIntent: EventSizeIntent.large,
          priceIntent: EventPriceIntent.lowCost,
          airGapProvenance: buildProvenance(),
        ),
        eventType: ExpertiseEventType.meetup,
        currentStartTime: DateTime.utc(2026, 3, 21, 14),
        defaultDuration: const Duration(hours: 3),
        currentMaxAttendees: 20,
        currentPrice: 12,
      );

      expect(suggestion.confidence, isNot(EventPlanningConfidence.low));
      expect(suggestion.suggestedStartTime.hour, 19);
      expect(suggestion.suggestedMaxAttendees, 40);
      expect(
        suggestion.explanation,
        contains('best current fit'),
      );
    });
  });
}
