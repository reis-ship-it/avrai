class ImplicitPositiveSignal {
  const ImplicitPositiveSignal({
    required this.eventType,
    required this.metadata,
  });

  final String eventType;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toInteractionPayload() {
    return {
      'event_type': eventType,
      'parameters': metadata,
      'context': const {'derived_signal': 'implicit_positive_outcome'},
    };
  }
}

/// Phase 1.4.8 implicit positive signal detector.
class ImplicitPositiveSignalDetector {
  const ImplicitPositiveSignalDetector({
    this.returnVisitWindowDays = 30,
    this.notificationOpenWindowHours = 1,
    this.detailDwellThresholdMs = 60000,
  });

  final int returnVisitWindowDays;
  final int notificationOpenWindowHours;
  final int detailDwellThresholdMs;

  ImplicitPositiveSignal? detectReturnVisitSignal({
    required String spotId,
    required DateTime previousVisitAt,
    required DateTime currentVisitAt,
  }) {
    final previousUtc = previousVisitAt.toUtc();
    final currentUtc = currentVisitAt.toUtc();
    if (!currentUtc.isAfter(previousUtc)) return null;

    final days = currentUtc.difference(previousUtc).inDays;
    if (days > returnVisitWindowDays) return null;
    return ImplicitPositiveSignal(
      eventType: 'return_visit_within_days',
      metadata: {
        'spot_id': spotId,
        'days': days,
        'window_days': returnVisitWindowDays,
      },
    );
  }

  ImplicitPositiveSignal? detectNotificationOpenSignal({
    required String recommendationId,
    required DateTime recommendationSentAt,
    required DateTime appOpenedAt,
  }) {
    final sentUtc = recommendationSentAt.toUtc();
    final openUtc = appOpenedAt.toUtc();
    if (openUtc.isBefore(sentUtc)) return null;

    final delta = openUtc.difference(sentUtc);
    if (delta > Duration(hours: notificationOpenWindowHours)) return null;
    return ImplicitPositiveSignal(
      eventType: 'recommendation_notification_opened',
      metadata: {
        'recommendation_id': recommendationId,
        'open_latency_minutes': delta.inMinutes,
        'window_hours': notificationOpenWindowHours,
      },
    );
  }

  ImplicitPositiveSignal? detectOrganicRecommendationHitSignal({
    required String recommendedEntityId,
    required String visitedEntityId,
    required bool tappedRecommendation,
  }) {
    if (tappedRecommendation) return null;
    if (recommendedEntityId.isEmpty || visitedEntityId.isEmpty) return null;
    if (recommendedEntityId != visitedEntityId) return null;

    return ImplicitPositiveSignal(
      eventType: 'recommended_entity_visited_organically',
      metadata: {
        'recommended_entity_id': recommendedEntityId,
        'visited_entity_id': visitedEntityId,
        'tapped_recommendation': false,
      },
    );
  }

  ImplicitPositiveSignal? detectDetailDwellSignal({
    required String entityType,
    required String entityId,
    required int durationMs,
  }) {
    if (durationMs < detailDwellThresholdMs) return null;
    return ImplicitPositiveSignal(
      eventType: 'entity_detail_long_dwell',
      metadata: {
        'entity_type': entityType,
        'entity_id': entityId,
        'duration_ms': durationMs,
        'threshold_ms': detailDwellThresholdMs,
      },
    );
  }
}
