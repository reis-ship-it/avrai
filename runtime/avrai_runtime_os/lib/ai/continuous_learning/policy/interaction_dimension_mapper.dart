class InteractionDimensionMapper {
  const InteractionDimensionMapper._();

  static Map<String, double> mapBaseUpdates({
    required String eventType,
    required Map<String, dynamic> parameters,
  }) {
    final updates = <String, double>{};

    switch (eventType) {
      case 'respect_tap':
        final targetType = parameters['target_type'] as String?;
        if (targetType == 'list') {
          final category = parameters['category'] as String?;
          updates['community_evolution'] = 0.05;
          updates['personalization_depth'] = 0.03;
          if (category != null) {
            updates['user_preference_understanding'] = 0.02;
          }
        } else if (targetType == 'spot') {
          updates['recommendation_accuracy'] = 0.03;
          updates['location_intelligence'] = 0.02;
        }
        break;

      case 'list_view_duration':
      case 'spot_view_duration':
        final duration = parameters['duration_ms'] as int? ?? 0;
        if (duration > 30000) {
          updates['user_preference_understanding'] = 0.04;
          updates['recommendation_accuracy'] = 0.02;
        }
        break;

      case 'scroll_depth':
        final depth = parameters['depth_percentage'] as double? ?? 0.0;
        if (depth > 0.8) {
          updates['user_preference_understanding'] = 0.03;
        }
        break;

      case 'spot_visited':
      case 'spot_tap':
        updates['recommendation_accuracy'] = 0.05;
        updates['location_intelligence'] = 0.03;
        break;

      case 'dwell_time':
        final duration = parameters['duration_ms'] as int? ?? 0;
        if (duration > 60000) {
          updates['user_preference_understanding'] = 0.04;
          updates['recommendation_accuracy'] = 0.03;
        }
        break;

      case 'search_performed':
        final resultsCount = parameters['results_count'] as int? ?? 0;
        if (resultsCount > 0) {
          updates['user_preference_understanding'] = 0.02;
        }
        break;

      case 'event_attended':
        updates['community_evolution'] = 0.08;
        updates['social_dynamics'] = 0.05;
        break;

      case 'event_planning_created':
        updates['community_evolution'] = 0.05;
        updates['location_intelligence'] = 0.03;
        updates['personalization_depth'] = 0.03;
        break;

      case 'event_planning_outcome_recorded':
        updates['community_evolution'] = 0.06;
        updates['recommendation_accuracy'] = 0.04;
        updates['location_intelligence'] = 0.03;
        break;

      case 'organic_spot_discovered':
        updates['location_intelligence'] = 0.08;
        updates['user_preference_understanding'] = 0.05;
        updates['personalization_depth'] = 0.04;
        break;

      case 'organic_spot_created':
        updates['location_intelligence'] = 0.10;
        updates['recommendation_accuracy'] = 0.08;
        updates['community_evolution'] = 0.06;
        updates['personalization_depth'] = 0.05;
        break;

      case 'organic_spot_dismissed':
        updates['recommendation_accuracy'] = -0.02;
        break;
    }

    return updates;
  }

  static void applyContextModifiers({
    required Map<String, double> updates,
    required String eventType,
    required Map<String, dynamic> context,
  }) {
    final timeOfDay = context['time_of_day'] as String?;
    final location = context['location'] as Map<String, dynamic>?;
    final weather = context['weather'] as Map<String, dynamic>?;

    if (timeOfDay == 'morning' &&
        (eventType == 'spot_visited' || eventType == 'spot_tap')) {
      updates['temporal_patterns'] =
          (updates['temporal_patterns'] ?? 0.0) + 0.02;
    }

    if (location != null) {
      updates['location_intelligence'] =
          (updates['location_intelligence'] ?? 0.0) + 0.01;
    }

    if (weather != null) {
      final conditions = weather['conditions'] as String?;
      if (conditions == 'Rain' &&
          (eventType == 'spot_visited' || eventType == 'spot_tap')) {
        updates['temporal_patterns'] =
            (updates['temporal_patterns'] ?? 0.0) + 0.01;
      }
    }
  }

  static bool enforceAi2AiDeltaThreshold(
    Map<String, double> updates, {
    double minimumDelta = 0.22,
  }) {
    updates.removeWhere((_, value) => value.abs() < minimumDelta);
    return updates.isNotEmpty;
  }
}
