class NegativeOutcomeSignal {
  const NegativeOutcomeSignal({
    required this.eventType,
    required this.recommendationId,
    required this.daysAbsent,
    required this.thresholdDays,
    required this.isNegative,
  });

  final String eventType;
  final String recommendationId;
  final int daysAbsent;
  final int thresholdDays;
  final bool isNegative;

  Map<String, dynamic> toInteractionPayload() {
    return {
      'event_type': eventType,
      'parameters': {
        'recommendation_id': recommendationId,
        'days_absent': daysAbsent,
        'threshold_days': thresholdDays,
      },
      'context': {'derived_signal': 'implicit_negative_outcome'},
    };
  }
}

/// Phase 1.4.5 implicit negative outcome detector.
class NegativeOutcomeSignalDetector {
  const NegativeOutcomeSignalDetector({
    this.absenceThresholdDays = 3,
  });

  final int absenceThresholdDays;

  NegativeOutcomeSignal? detect({
    required String recommendationId,
    required DateTime recommendationSeenAt,
    required DateTime? appClosedAt,
    required DateTime? returnedAt,
    required DateTime now,
    int? thresholdDaysOverride,
  }) {
    if (appClosedAt == null) return null;
    final seenAtUtc = recommendationSeenAt.toUtc();
    final closedAtUtc = appClosedAt.toUtc();
    final nowUtc = now.toUtc();
    final returnedAtUtc = returnedAt?.toUtc();

    if (closedAtUtc.isBefore(seenAtUtc)) {
      return null;
    }
    if (closedAtUtc.isAfter(nowUtc)) {
      return null;
    }
    if (returnedAtUtc != null && returnedAtUtc.isBefore(closedAtUtc)) {
      return null;
    }

    final thresholdDays = thresholdDaysOverride ?? absenceThresholdDays;
    final absenceReference = returnedAtUtc ?? nowUtc;
    final daysAbsent = absenceReference.difference(closedAtUtc).inDays;
    final negative = daysAbsent >= thresholdDays;

    return NegativeOutcomeSignal(
      eventType: 'recommendation_post_view_abandonment',
      recommendationId: recommendationId,
      daysAbsent: daysAbsent,
      thresholdDays: thresholdDays,
      isNegative: negative,
    );
  }
}
