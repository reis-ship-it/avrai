enum FeedbackSignalClass {
  explicitRating,
  returnVisit,
  oneTapDismiss,
  categorySuppress,
  reservationOrAttendance,
  saveBookmark,
  notificationOpened,
  longDetailDwell,
  browseAndLeave,
  scrollPastWithoutTap,
}

class FeedbackSignalSpec {
  const FeedbackSignalSpec({
    required this.signalClass,
    required this.weight,
    required this.rank,
    required this.label,
    this.isNegative = false,
  });

  final FeedbackSignalClass signalClass;
  final double weight;
  final int rank;
  final String label;
  final bool isNegative;
}

/// Phase 1.4.9 signal strength hierarchy.
class FeedbackSignalStrengthHierarchy {
  const FeedbackSignalStrengthHierarchy();

  static const Map<FeedbackSignalClass, FeedbackSignalSpec> specs = {
    FeedbackSignalClass.explicitRating: FeedbackSignalSpec(
      signalClass: FeedbackSignalClass.explicitRating,
      weight: 10.0,
      rank: 1,
      label: 'explicit_rating',
    ),
    FeedbackSignalClass.returnVisit: FeedbackSignalSpec(
      signalClass: FeedbackSignalClass.returnVisit,
      weight: 8.0,
      rank: 2,
      label: 'return_visit_repeat_action',
    ),
    FeedbackSignalClass.oneTapDismiss: FeedbackSignalSpec(
      signalClass: FeedbackSignalClass.oneTapDismiss,
      weight: 5.0,
      rank: 3,
      label: 'one_tap_dismiss',
      isNegative: true,
    ),
    FeedbackSignalClass.categorySuppress: FeedbackSignalSpec(
      signalClass: FeedbackSignalClass.categorySuppress,
      weight: 10.0,
      rank: 4,
      label: 'category_suppress',
      isNegative: true,
    ),
    FeedbackSignalClass.reservationOrAttendance: FeedbackSignalSpec(
      signalClass: FeedbackSignalClass.reservationOrAttendance,
      weight: 4.0,
      rank: 5,
      label: 'reservation_or_attendance',
    ),
    FeedbackSignalClass.saveBookmark: FeedbackSignalSpec(
      signalClass: FeedbackSignalClass.saveBookmark,
      weight: 3.0,
      rank: 6,
      label: 'save_or_bookmark',
    ),
    FeedbackSignalClass.notificationOpened: FeedbackSignalSpec(
      signalClass: FeedbackSignalClass.notificationOpened,
      weight: 2.0,
      rank: 7,
      label: 'notification_opened',
    ),
    FeedbackSignalClass.longDetailDwell: FeedbackSignalSpec(
      signalClass: FeedbackSignalClass.longDetailDwell,
      weight: 1.5,
      rank: 8,
      label: 'detail_page_long_dwell',
    ),
    FeedbackSignalClass.browseAndLeave: FeedbackSignalSpec(
      signalClass: FeedbackSignalClass.browseAndLeave,
      weight: 1.0,
      rank: 9,
      label: 'browse_and_leave',
    ),
    FeedbackSignalClass.scrollPastWithoutTap: FeedbackSignalSpec(
      signalClass: FeedbackSignalClass.scrollPastWithoutTap,
      weight: 0.5,
      rank: 10,
      label: 'scroll_past_without_tap',
      isNegative: true,
    ),
  };

  FeedbackSignalSpec? resolveForEvent(String eventType) {
    switch (eventType) {
      case 'rating_submitted':
      case 'feedback_rating':
      case 'attend_expert_event_feedback':
        return specs[FeedbackSignalClass.explicitRating];
      case 'explicit_preference':
      case 'suppress_category':
        return specs[FeedbackSignalClass.categorySuppress];
      case 'return_visit_within_days':
        return specs[FeedbackSignalClass.returnVisit];
      case 'explicit_rejection':
      case 'dismiss_entity':
      case 'dismiss_spot':
      case 'spot_dismissed':
      case 'recommendation_rejected':
        return specs[FeedbackSignalClass.oneTapDismiss];
      case 'create_reservation':
      case 'attend_event':
      case 'event_attended':
      case 'event_attend':
        return specs[FeedbackSignalClass.reservationOrAttendance];
      case 'save_entity':
      case 'save_event':
      case 'save_community':
      case 'save_spot':
      case 'save_list':
      case 'search_result_save':
        return specs[FeedbackSignalClass.saveBookmark];
      case 'recommendation_notification_opened':
        return specs[FeedbackSignalClass.notificationOpened];
      case 'entity_detail_long_dwell':
      case 'dwell_time':
        return specs[FeedbackSignalClass.longDetailDwell];
      case 'browse_entity':
      case 'no_action':
        return specs[FeedbackSignalClass.browseAndLeave];
      case 'scroll_past_without_tap':
      case 'recommendation_scrolled_past':
        return specs[FeedbackSignalClass.scrollPastWithoutTap];
      default:
        return null;
    }
  }
}
