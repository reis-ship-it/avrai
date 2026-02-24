enum ExplicitFeedbackTriggerType {
  postEventNextAppOpenAfterCheckIn,
  postReservation24hAfter,
  postCommunityJoin7dAfter,
}

class ExplicitFeedbackTriggerDecision {
  const ExplicitFeedbackTriggerDecision({
    required this.type,
    required this.dueAt,
    required this.isDue,
    required this.reason,
  });

  final ExplicitFeedbackTriggerType type;
  final DateTime dueAt;
  final bool isDue;
  final String reason;
}

/// Phase 1.4.2 timing policy for explicit feedback collection.
class ExplicitFeedbackTriggerPolicy {
  const ExplicitFeedbackTriggerPolicy();

  ExplicitFeedbackTriggerDecision postEventTrigger({
    required DateTime checkInAt,
    required DateTime appOpenAt,
    required bool alreadyPrompted,
  }) {
    final dueAt = checkInAt.toUtc();
    if (alreadyPrompted) {
      return ExplicitFeedbackTriggerDecision(
        type: ExplicitFeedbackTriggerType.postEventNextAppOpenAfterCheckIn,
        dueAt: dueAt,
        isDue: false,
        reason: 'already_prompted',
      );
    }
    final due = appOpenAt.toUtc().isAfter(dueAt) ||
        appOpenAt.toUtc().isAtSameMomentAs(dueAt);
    return ExplicitFeedbackTriggerDecision(
      type: ExplicitFeedbackTriggerType.postEventNextAppOpenAfterCheckIn,
      dueAt: dueAt,
      isDue: due,
      reason: due ? 'next_app_open_after_checkin' : 'waiting_for_next_open',
    );
  }

  ExplicitFeedbackTriggerDecision postReservationTrigger({
    required DateTime reservationCompletedAt,
    required DateTime now,
    required bool alreadyPrompted,
  }) {
    final dueAt = reservationCompletedAt.toUtc().add(const Duration(hours: 24));
    if (alreadyPrompted) {
      return ExplicitFeedbackTriggerDecision(
        type: ExplicitFeedbackTriggerType.postReservation24hAfter,
        dueAt: dueAt,
        isDue: false,
        reason: 'already_prompted',
      );
    }
    final due = !now.toUtc().isBefore(dueAt);
    return ExplicitFeedbackTriggerDecision(
      type: ExplicitFeedbackTriggerType.postReservation24hAfter,
      dueAt: dueAt,
      isDue: due,
      reason: due ? '24h_elapsed' : 'awaiting_24h_window',
    );
  }

  ExplicitFeedbackTriggerDecision postCommunityJoinTrigger({
    required DateTime communityJoinedAt,
    required DateTime now,
    required bool alreadyPrompted,
  }) {
    final dueAt = communityJoinedAt.toUtc().add(const Duration(days: 7));
    if (alreadyPrompted) {
      return ExplicitFeedbackTriggerDecision(
        type: ExplicitFeedbackTriggerType.postCommunityJoin7dAfter,
        dueAt: dueAt,
        isDue: false,
        reason: 'already_prompted',
      );
    }
    final due = !now.toUtc().isBefore(dueAt);
    return ExplicitFeedbackTriggerDecision(
      type: ExplicitFeedbackTriggerType.postCommunityJoin7dAfter,
      dueAt: dueAt,
      isDue: due,
      reason: due ? '7d_elapsed' : 'awaiting_7d_window',
    );
  }
}
