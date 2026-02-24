import 'package:avrai/core/ai/feedback_signal_strength_hierarchy.dart';

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
  static const FeedbackSignalStrengthHierarchy _signalHierarchy =
      FeedbackSignalStrengthHierarchy();

  ImplicitFeedbackObservation? resolve({
    required String eventType,
    required Map<String, dynamic> parameters,
    required Map<String, dynamic> context,
  }) {
    switch (eventType) {
      case 'list_view_duration':
      case 'spot_view_duration':
      case 'entity_detail_duration':
      case 'dwell_time':
        final durationMs = _resolveDurationMs(parameters);
        if (durationMs < 60000) return null;
        return ImplicitFeedbackObservation(
          type: ImplicitFeedbackSignalType.dwellTimeOnEntityListing,
          polarity: ImplicitFeedbackPolarity.positive,
          strength: _signalHierarchy
              .resolveForEvent('entity_detail_long_dwell')!
              .weight,
          metadata: {'duration_ms': durationMs},
        );
      case 'scroll_past_without_tap':
      case 'recommendation_scrolled_past':
        return ImplicitFeedbackObservation(
          type: ImplicitFeedbackSignalType.scrollPastWithoutTap,
          polarity: ImplicitFeedbackPolarity.negative,
          strength: _signalHierarchy
              .resolveForEvent('scroll_past_without_tap')!
              .weight,
        );
      case 'reopen_after_recommendation':
      case 'recommendation_notification_opened':
        return ImplicitFeedbackObservation(
          type: ImplicitFeedbackSignalType.reopenAfterRecommendation,
          polarity: ImplicitFeedbackPolarity.positive,
          strength: _signalHierarchy
              .resolveForEvent('recommendation_notification_opened')!
              .weight,
        );
      case 'save_entity':
      case 'save_event':
      case 'save_community':
      case 'save_spot':
      case 'save_list':
      case 'search_result_save':
        return ImplicitFeedbackObservation(
          type: ImplicitFeedbackSignalType.saveAction,
          polarity: ImplicitFeedbackPolarity.positive,
          strength: _signalHierarchy.resolveForEvent('save_entity')!.weight,
        );
      case 'dismiss_spot':
      case 'spot_dismissed':
      case 'dismiss_entity':
      case 'dismiss_event':
      case 'dismiss_community':
      case 'explicit_rejection':
      case 'recommendation_rejected':
        return ImplicitFeedbackObservation(
          type: ImplicitFeedbackSignalType.dismissAction,
          polarity: ImplicitFeedbackPolarity.negative,
          strength: _signalHierarchy.resolveForEvent('dismiss_entity')!.weight,
        );
      case 'message_friend':
      case 'message_community':
      case 'chat_after_recommendation':
        final isAfterRecommendation =
            parameters['after_recommendation'] == true ||
                context['after_recommendation'] == true ||
                parameters['recommendation_id'] != null ||
                context['recommendation_id'] != null;
        if (!isAfterRecommendation) return null;
        return ImplicitFeedbackObservation(
          type: ImplicitFeedbackSignalType.chatAfterRecommendation,
          polarity: ImplicitFeedbackPolarity.positive,
          strength: 2.5,
        );
      default:
        return null;
    }
  }

  int _resolveDurationMs(Map<String, dynamic> parameters) {
    final durationMs = _toInt(parameters['duration_ms']);
    if (durationMs != null) return durationMs;

    final seconds = _toInt(parameters['duration_seconds']);
    if (seconds != null) return seconds * 1000;

    final duration = parameters['duration'];
    if (duration is Duration) return duration.inMilliseconds;

    return 0;
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
