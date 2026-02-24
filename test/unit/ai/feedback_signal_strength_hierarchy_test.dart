import 'package:flutter_test/flutter_test.dart';

import 'package:avrai/core/ai/feedback_signal_strength_hierarchy.dart';

void main() {
  group('FeedbackSignalStrengthHierarchy', () {
    const hierarchy = FeedbackSignalStrengthHierarchy();

    test('defines the planned phase 1.4.9 ordering and weights', () {
      final specs = FeedbackSignalStrengthHierarchy.specs;
      expect(specs.length, 10);

      expect(specs[FeedbackSignalClass.explicitRating]!.rank, 1);
      expect(specs[FeedbackSignalClass.explicitRating]!.weight, 10.0);

      expect(specs[FeedbackSignalClass.returnVisit]!.rank, 2);
      expect(specs[FeedbackSignalClass.returnVisit]!.weight, 8.0);

      expect(specs[FeedbackSignalClass.oneTapDismiss]!.rank, 3);
      expect(specs[FeedbackSignalClass.oneTapDismiss]!.weight, 5.0);
      expect(specs[FeedbackSignalClass.oneTapDismiss]!.isNegative, isTrue);

      expect(specs[FeedbackSignalClass.categorySuppress]!.rank, 4);
      expect(specs[FeedbackSignalClass.categorySuppress]!.weight, 10.0);
      expect(specs[FeedbackSignalClass.categorySuppress]!.isNegative, isTrue);

      expect(specs[FeedbackSignalClass.reservationOrAttendance]!.rank, 5);
      expect(specs[FeedbackSignalClass.reservationOrAttendance]!.weight, 4.0);

      expect(specs[FeedbackSignalClass.saveBookmark]!.rank, 6);
      expect(specs[FeedbackSignalClass.saveBookmark]!.weight, 3.0);

      expect(specs[FeedbackSignalClass.notificationOpened]!.rank, 7);
      expect(specs[FeedbackSignalClass.notificationOpened]!.weight, 2.0);

      expect(specs[FeedbackSignalClass.longDetailDwell]!.rank, 8);
      expect(specs[FeedbackSignalClass.longDetailDwell]!.weight, 1.5);

      expect(specs[FeedbackSignalClass.browseAndLeave]!.rank, 9);
      expect(specs[FeedbackSignalClass.browseAndLeave]!.weight, 1.0);

      expect(specs[FeedbackSignalClass.scrollPastWithoutTap]!.rank, 10);
      expect(specs[FeedbackSignalClass.scrollPastWithoutTap]!.weight, 0.5);
      expect(
        specs[FeedbackSignalClass.scrollPastWithoutTap]!.isNegative,
        isTrue,
      );
    });

    test('resolves canonical event aliases', () {
      expect(
        hierarchy.resolveForEvent('rating_submitted')!.signalClass,
        FeedbackSignalClass.explicitRating,
      );
      expect(
        hierarchy.resolveForEvent('return_visit_within_days')!.signalClass,
        FeedbackSignalClass.returnVisit,
      );
      expect(
        hierarchy.resolveForEvent('explicit_rejection')!.signalClass,
        FeedbackSignalClass.oneTapDismiss,
      );
      expect(
        hierarchy.resolveForEvent('explicit_preference')!.signalClass,
        FeedbackSignalClass.categorySuppress,
      );
      expect(
        hierarchy
            .resolveForEvent('recommendation_notification_opened')!
            .signalClass,
        FeedbackSignalClass.notificationOpened,
      );
      expect(
        hierarchy.resolveForEvent('entity_detail_long_dwell')!.signalClass,
        FeedbackSignalClass.longDetailDwell,
      );
      expect(
        hierarchy.resolveForEvent('recommendation_scrolled_past')!.signalClass,
        FeedbackSignalClass.scrollPastWithoutTap,
      );
    });
  });
}
