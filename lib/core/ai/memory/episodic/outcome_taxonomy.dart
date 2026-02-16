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
      case 'create_list':
      case 'modify_list':
      case 'share_list':
      case 'checkin_confirmed':
      case 'actual_action_succeeded':
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
        return OutcomeSignal(
          type: eventType,
          category: OutcomeCategory.quality,
          value: (parameters['rating'] as num?)?.toDouble() ?? 0.0,
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
