enum ImplicitFeedbackSignalType {
  dwellTimeOnEntityListing,
  scrollPastWithoutTap,
  reopenAfterRecommendation,
  saveAction,
  dismissAction,
  chatAfterRecommendation,
}

enum ImplicitFeedbackPolarity {
  positive,
  negative,
}

class ImplicitFeedbackObservation {
  const ImplicitFeedbackObservation({
    required this.type,
    required this.polarity,
    required this.strength,
    this.metadata = const <String, dynamic>{},
  });

  final ImplicitFeedbackSignalType type;
  final ImplicitFeedbackPolarity polarity;
  final double strength;
  final Map<String, dynamic> metadata;
}

/// Phase 1.4.1 implicit feedback signal definitions.
class ImplicitFeedbackSignals {
  const ImplicitFeedbackSignals();

  ImplicitFeedbackObservation? resolve({
    required String eventType,
    required Map<String, dynamic> parameters,
    required Map<String, dynamic> context,
  }) {
    switch (eventType) {
      case 'list_view_duration':
      case 'spot_view_duration':
      case 'dwell_time':
        final durationMs = (parameters['duration_ms'] as num?)?.toInt() ?? 0;
        if (durationMs < 60000) return null;
        return ImplicitFeedbackObservation(
          type: ImplicitFeedbackSignalType.dwellTimeOnEntityListing,
          polarity: ImplicitFeedbackPolarity.positive,
          strength: 1.5,
          metadata: {'duration_ms': durationMs},
        );
      case 'scroll_past_without_tap':
        return const ImplicitFeedbackObservation(
          type: ImplicitFeedbackSignalType.scrollPastWithoutTap,
          polarity: ImplicitFeedbackPolarity.negative,
          strength: 0.5,
        );
      case 'reopen_after_recommendation':
        return const ImplicitFeedbackObservation(
          type: ImplicitFeedbackSignalType.reopenAfterRecommendation,
          polarity: ImplicitFeedbackPolarity.positive,
          strength: 2.0,
        );
      case 'save_spot':
      case 'save_list':
      case 'search_result_save':
        return const ImplicitFeedbackObservation(
          type: ImplicitFeedbackSignalType.saveAction,
          polarity: ImplicitFeedbackPolarity.positive,
          strength: 3.0,
        );
      case 'dismiss_spot':
      case 'spot_dismissed':
      case 'recommendation_rejected':
        return const ImplicitFeedbackObservation(
          type: ImplicitFeedbackSignalType.dismissAction,
          polarity: ImplicitFeedbackPolarity.negative,
          strength: 5.0,
        );
      case 'message_friend':
      case 'message_community':
        final isAfterRecommendation =
            parameters['after_recommendation'] == true ||
                context['after_recommendation'] == true;
        if (!isAfterRecommendation) return null;
        return const ImplicitFeedbackObservation(
          type: ImplicitFeedbackSignalType.chatAfterRecommendation,
          polarity: ImplicitFeedbackPolarity.positive,
          strength: 2.5,
        );
      default:
        return null;
    }
  }
}
