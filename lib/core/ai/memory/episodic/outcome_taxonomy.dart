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
  static const double negativeOutcomeAmplificationFactor = 2.0;

  static const Map<String, double> _defaultSignalWeightByEventType = {
    'rating_submitted': 10.0,
    'feedback_rating': 10.0,
    'attend_expert_event_feedback': 10.0,
    'return_visit_within_days': 8.0,
    'recommendation_rejected': 5.0,
    'explicit_rejection': 5.0,
    'dismissed': 5.0,
    'explicit_preference': 10.0,
    'create_reservation': 4.0,
    'attend_event': 4.0,
    'event_attended': 4.0,
    'event_attend': 4.0,
    'save_entity': 3.0,
    'save_event': 3.0,
    'save_community': 3.0,
    'save_spot': 3.0,
    'save_list': 3.0,
    'search_result_save': 3.0,
    'recommendation_notification_opened': 2.0,
    'dwell_time': 1.5,
    'entity_detail_long_dwell': 1.5,
    'no_action': 1.0,
    'search_result_no_action': 1.0,
    'browse_entity': 1.0,
    'scroll_past_without_tap': 0.5,
    'recommendation_scrolled_past': 0.5,
  };

  const OutcomeTaxonomy();

  OutcomeSignal classify({
    required String eventType,
    required Map<String, dynamic> parameters,
  }) {
    late final OutcomeSignal baseSignal;
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
      case 'volunteer_signup':
      case 'volunteer_attend':
      case 'nearby_discovered_non_member':
      case 'invite_sent':
      case 'install_started':
      case 'install_completed':
      case 'first_action_after_install':
      case 'recommendation_notification_opened':
      case 'recommended_entity_visited_organically':
      case 'entity_detail_long_dwell':
      case 'explicit_preference':
        baseSignal = _binaryOutcome(
          type: eventType,
          didOccur: true,
          parameters: parameters,
        );
        break;
      case 'dismissed':
      case 'recommendation_rejected':
      case 'explicit_rejection':
      case 'recommendation_post_view_abandonment':
      case 'actual_action_failed':
      case 'search_result_bounce':
        baseSignal = _binaryOutcome(
          type: eventType,
          didOccur: false,
          parameters: parameters,
        );
        break;
      case 'rating_submitted':
      case 'feedback_rating':
      case 'attend_expert_event_feedback':
      case 'sponsorship_outcome_recorded':
      case 'partnership_outcome_recorded':
      case 'event_outcome':
      case 'business_partnership_outcome':
      case 'engagement_outcome':
      case 'ai2ai_connection_outcome':
        baseSignal = _qualityOutcome(
          type: eventType,
          parameters: parameters,
        );
        break;
      case 'return_visit_within_days':
        baseSignal = _temporalOutcome(
          type: eventType,
          parameters: parameters,
        );
        break;
      case 'single_visit_only':
        baseSignal = _behavioralOutcome(
          type: eventType,
          value: 0.5,
          parameters: parameters,
        );
        break;
      case 'no_action':
      case 'search_result_no_action':
        baseSignal = _behavioralOutcome(
          type: eventType,
          value: 0.0,
          parameters: parameters,
        );
        break;
      case 'volunteer_retention':
        baseSignal = _temporalOutcome(
          type: eventType,
          parameters: {
            ...parameters,
            'window_days':
                (parameters['impact_window_days'] as num?)?.toInt() ??
                    (parameters['window_days'] as num?)?.toInt() ??
                    30,
          },
        );
        break;
      case 'volunteer_dropoff':
        baseSignal = _behavioralOutcome(
          type: eventType,
          value: -1.0,
          parameters: {
            ...parameters,
            'window_days':
                (parameters['impact_window_days'] as num?)?.toInt() ??
                    (parameters['window_days'] as num?)?.toInt() ??
                    30,
          },
        );
        break;
      case 'browse_entity':
        if (parameters['no_action'] == true) {
          baseSignal = _behavioralOutcome(
            type: 'no_action',
            value: 0.0,
            parameters: parameters,
          );
          break;
        }
        baseSignal = _behavioralOutcome(
          type: eventType,
          value: (parameters['shift_magnitude'] as num?)?.toDouble() ?? 0.0,
          parameters: parameters,
        );
        break;
      case 'passive_to_active_conversion':
        baseSignal = _behavioralOutcome(
          type: eventType,
          value: 1.0,
          parameters: parameters,
        );
        break;
      case 'active_to_passive_regression':
        baseSignal = _behavioralOutcome(
          type: eventType,
          value: -1.0,
          parameters: parameters,
        );
        break;
      default:
        baseSignal = _behavioralOutcome(
          type: eventType,
          value: (parameters['shift_magnitude'] as num?)?.toDouble() ?? 0.0,
          parameters: parameters,
        );
        break;
    }

    return _applyNegativeOutcomeAmplification(
      eventType: eventType,
      parameters: parameters,
      signal: baseSignal,
    );
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

  OutcomeSignal _applyNegativeOutcomeAmplification({
    required String eventType,
    required Map<String, dynamic> parameters,
    required OutcomeSignal signal,
  }) {
    final baseSignalWeight = _resolveBaseSignalWeight(
      eventType: eventType,
      parameters: parameters,
    );
    final isNegative = _isNegativeOutcome(signal);
    final effectiveTrainingWeight = isNegative
        ? baseSignalWeight * negativeOutcomeAmplificationFactor
        : baseSignalWeight;

    return OutcomeSignal(
      type: signal.type,
      category: signal.category,
      value: signal.value,
      metadata: {
        ...signal.metadata,
        'base_signal_weight': baseSignalWeight,
        'asymmetric_loss_factor': negativeOutcomeAmplificationFactor,
        'negative_outcome_amplified': isNegative,
        'effective_training_weight': effectiveTrainingWeight,
        'amplification_phase_ref': '1.4.10',
      },
    );
  }

  double _resolveBaseSignalWeight({
    required String eventType,
    required Map<String, dynamic> parameters,
  }) {
    final explicitSignalWeight = _toDouble(parameters['signal_weight']);
    if (explicitSignalWeight != null && explicitSignalWeight > 0) {
      return explicitSignalWeight;
    }

    final implicitStrength =
        _toDouble(parameters['implicit_feedback_strength']);
    if (implicitStrength != null && implicitStrength > 0) {
      return implicitStrength;
    }

    return _defaultSignalWeightByEventType[eventType] ?? 1.0;
  }

  bool _isNegativeOutcome(OutcomeSignal signal) {
    final binaryOutcome = signal.metadata['binary_outcome'];
    if (binaryOutcome is bool) {
      return !binaryOutcome;
    }

    switch (signal.category) {
      case OutcomeCategory.binary:
        return signal.value <= 0.0;
      case OutcomeCategory.quality:
        final scaleMax = _toDouble(signal.metadata['scale_max']) ?? 5.0;
        if (scaleMax <= 1.0) {
          return signal.value < 0.5;
        }
        return signal.value <= 2.0;
      case OutcomeCategory.behavioral:
        return signal.value < 0.0;
      case OutcomeCategory.temporal:
        return signal.metadata['negative_outcome'] == true;
    }
  }

  double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
