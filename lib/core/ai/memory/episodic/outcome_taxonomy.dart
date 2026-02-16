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
        return OutcomeSignal(
          type: eventType,
          category: OutcomeCategory.binary,
          value: 1.0,
          metadata: parameters,
        );
      case 'dismissed':
      case 'recommendation_rejected':
      case 'actual_action_failed':
        return OutcomeSignal(
          type: eventType,
          category: OutcomeCategory.binary,
          value: 0.0,
          metadata: parameters,
        );
      case 'rating_submitted':
      case 'feedback_rating':
      case 'attend_expert_event_feedback':
      case 'sponsorship_outcome_recorded':
      case 'partnership_outcome_recorded':
      case 'event_outcome':
      case 'business_partnership_outcome':
      case 'engagement_outcome':
        return OutcomeSignal(
          type: eventType,
          category: OutcomeCategory.quality,
          value: (parameters['overall_rating'] as num?)?.toDouble() ??
              (parameters['mutual_satisfaction_rating'] as num?)?.toDouble() ??
              (parameters['rating'] as num?)?.toDouble() ??
              0.0,
          metadata: parameters,
        );
      case 'return_visit_within_days':
        return OutcomeSignal(
          type: eventType,
          category: OutcomeCategory.temporal,
          value: (parameters['days'] as num?)?.toDouble() ?? 0.0,
          metadata: parameters,
        );
      case 'single_visit_only':
        return OutcomeSignal(
          type: eventType,
          category: OutcomeCategory.behavioral,
          value: 0.5,
          metadata: parameters,
        );
      case 'no_action':
        return OutcomeSignal(
          type: eventType,
          category: OutcomeCategory.behavioral,
          value: 0.0,
          metadata: parameters,
        );
      case 'browse_entity':
        if (parameters['no_action'] == true) {
          return OutcomeSignal(
            type: 'no_action',
            category: OutcomeCategory.behavioral,
            value: 0.0,
            metadata: parameters,
          );
        }
        return OutcomeSignal(
          type: eventType,
          category: OutcomeCategory.behavioral,
          value: (parameters['shift_magnitude'] as num?)?.toDouble() ?? 0.0,
          metadata: parameters,
        );
      case 'passive_to_active_conversion':
        return OutcomeSignal(
          type: eventType,
          category: OutcomeCategory.behavioral,
          value: 1.0,
          metadata: parameters,
        );
      case 'active_to_passive_regression':
        return OutcomeSignal(
          type: eventType,
          category: OutcomeCategory.behavioral,
          value: -1.0,
          metadata: parameters,
        );
      default:
        return OutcomeSignal(
          type: eventType,
          category: OutcomeCategory.behavioral,
          value: (parameters['shift_magnitude'] as num?)?.toDouble() ?? 0.0,
          metadata: parameters,
        );
    }
  }
}
