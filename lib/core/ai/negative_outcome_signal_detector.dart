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
  }) {
    if (appClosedAt == null) return null;
    if (appClosedAt.isBefore(recommendationSeenAt)) return null;

    final absenceReference = returnedAt ?? now;
    final daysAbsent =
        absenceReference.toUtc().difference(appClosedAt.toUtc()).inDays;
    final negative = daysAbsent >= absenceThresholdDays;

    return NegativeOutcomeSignal(
      eventType: 'recommendation_post_view_abandonment',
      recommendationId: recommendationId,
      daysAbsent: daysAbsent,
      thresholdDays: absenceThresholdDays,
      isNegative: negative,
    );
  }
}
