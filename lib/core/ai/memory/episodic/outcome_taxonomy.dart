/// Outcome taxonomy for Phase 1.2.12.
///
/// Defines normalized outcome categories used by episodic memory tuples:
/// - binary: did / did not
/// - quality: ordinal feedback scores
/// - behavioral: magnitude of user state shift
/// - temporal: return-window or latency outcomes
enum OutcomeCategory {
  binary,
  quality,
  behavioral,
  temporal,
}

/// Typed outcome payload stored in episodic tuples.
class OutcomeSignal {
  final String type;
  final OutcomeCategory category;
  final double value;
  final Map<String, dynamic> metadata;

  const OutcomeSignal({
    required this.type,
    required this.category,
    required this.value,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'category': category.name,
      'value': value,
      'metadata': metadata,
    };
  }

  factory OutcomeSignal.fromJson(Map<String, dynamic> json) {
    return OutcomeSignal(
      type: json['type'] as String? ?? 'unknown',
      category: _parseCategory(json['category'] as String?),
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }

  static OutcomeCategory _parseCategory(String? raw) {
    return OutcomeCategory.values.firstWhere(
      (c) => c.name == raw,
      orElse: () => OutcomeCategory.behavioral,
    );
  }
}

/// Maps interaction events into outcome taxonomy buckets.
class OutcomeTaxonomy {
  static const String taxonomyVersion = '1.0';

  const OutcomeTaxonomy();

  OutcomeSignal classify({
    required String eventType,
    required Map<String, dynamic> parameters,
  }) {
    switch (eventType) {
      case 'spot_visited':
      case 'event_attended':
      case 'event_attend':
      case 'community_join':
      case 'engage_business':
      case 'create_reservation':
      case 'attend_event':
      case 'create_list':
      case 'modify_list':
      case 'share_list':
      case 'checkin_confirmed':
      case 'actual_action_succeeded':
      case 'sponsor_event':
      case 'form_partnership':
      case 'chat_started':
      case 'partnership_formed':
      case 'message_friend':
      case 'message_community':
      case 'ask_agent':
      case 'chat_to_event_conversion':
      case 'search_result_click':
      case 'search_result_save':
      case 'search_result_check_in':
        return _binaryOutcome(
          type: eventType,
          didOccur: true,
          parameters: parameters,
        );
      case 'dismissed':
      case 'recommendation_rejected':
      case 'actual_action_failed':
      case 'search_result_bounce':
        return _binaryOutcome(
          type: eventType,
          didOccur: false,
          parameters: parameters,
        );
      case 'rating_submitted':
      case 'feedback_rating':
      case 'attend_expert_event_feedback':
      case 'sponsorship_outcome_recorded':
      case 'partnership_outcome_recorded':
      case 'event_outcome':
      case 'business_partnership_outcome':
      case 'engagement_outcome':
      case 'ai2ai_connection_outcome':
        return _qualityOutcome(
          type: eventType,
          parameters: parameters,
        );
      case 'return_visit_within_days':
        return _temporalOutcome(
          type: eventType,
          parameters: parameters,
        );
      case 'single_visit_only':
        return _behavioralOutcome(
          type: eventType,
          value: 0.5,
          parameters: parameters,
        );
      case 'no_action':
      case 'search_result_no_action':
        return _behavioralOutcome(
          type: eventType,
          value: 0.0,
          parameters: parameters,
        );
      case 'browse_entity':
        if (parameters['no_action'] == true) {
          return _behavioralOutcome(
            type: 'no_action',
            value: 0.0,
            parameters: parameters,
          );
        }
        return _behavioralOutcome(
          type: eventType,
          value: (parameters['shift_magnitude'] as num?)?.toDouble() ?? 0.0,
          parameters: parameters,
        );
      case 'passive_to_active_conversion':
        return _behavioralOutcome(
          type: eventType,
          value: 1.0,
          parameters: parameters,
        );
      case 'active_to_passive_regression':
        return _behavioralOutcome(
          type: eventType,
          value: -1.0,
          parameters: parameters,
        );
      default:
        return _behavioralOutcome(
          type: eventType,
          value: (parameters['shift_magnitude'] as num?)?.toDouble() ?? 0.0,
          parameters: parameters,
        );
    }
  }

  OutcomeSignal _binaryOutcome({
    required String type,
    required bool didOccur,
    required Map<String, dynamic> parameters,
  }) {
    return OutcomeSignal(
      type: type,
      category: OutcomeCategory.binary,
      value: didOccur ? 1.0 : 0.0,
      metadata: {
        ...parameters,
        'taxonomy_version': taxonomyVersion,
        'binary_outcome': didOccur,
      },
    );
  }

  OutcomeSignal _qualityOutcome({
    required String type,
    required Map<String, dynamic> parameters,
  }) {
    final connectionQuality =
        (parameters['connection_quality'] as num?)?.toDouble();
    if (connectionQuality != null) {
      return OutcomeSignal(
        type: type,
        category: OutcomeCategory.quality,
        value: connectionQuality.clamp(0.0, 1.0),
        metadata: {
          ...parameters,
          'taxonomy_version': taxonomyVersion,
          'scale_min': 0.0,
          'scale_max': 1.0,
        },
      );
    }

    final learningValue = (parameters['learning_value'] as num?)?.toDouble();
    if (learningValue != null) {
      return OutcomeSignal(
        type: type,
        category: OutcomeCategory.quality,
        value: learningValue.clamp(0.0, 1.0),
        metadata: {
          ...parameters,
          'taxonomy_version': taxonomyVersion,
          'scale_min': 0.0,
          'scale_max': 1.0,
        },
      );
    }

    final rating = (parameters['overall_rating'] as num?)?.toDouble() ??
        (parameters['mutual_satisfaction_rating'] as num?)?.toDouble() ??
        (parameters['rating'] as num?)?.toDouble() ??
        0.0;
    return OutcomeSignal(
      type: type,
      category: OutcomeCategory.quality,
      value: rating.clamp(0.0, 5.0),
      metadata: {
        ...parameters,
        'taxonomy_version': taxonomyVersion,
        'scale_min': 0.0,
        'scale_max': 5.0,
      },
    );
  }

  OutcomeSignal _behavioralOutcome({
    required String type,
    required double value,
    required Map<String, dynamic> parameters,
  }) {
    return OutcomeSignal(
      type: type,
      category: OutcomeCategory.behavioral,
      value: value,
      metadata: {
        ...parameters,
        'taxonomy_version': taxonomyVersion,
      },
    );
  }

  OutcomeSignal _temporalOutcome({
    required String type,
    required Map<String, dynamic> parameters,
  }) {
    final days = (parameters['days'] as num?)?.toDouble() ??
        (parameters['return_days'] as num?)?.toDouble() ??
        0.0;
    final temporalWindowDays =
        (parameters['window_days'] as num?)?.toInt() ?? 30;
    return OutcomeSignal(
      type: type,
      category: OutcomeCategory.temporal,
      value: days < 0 ? 0.0 : days,
      metadata: {
        ...parameters,
        'taxonomy_version': taxonomyVersion,
        'window_days': temporalWindowDays,
      },
    );
  }
}
