class LearningDimensionPolicy {
  static const List<String> learningDimensions = <String>[
    'user_preference_understanding',
    'location_intelligence',
    'temporal_patterns',
    'social_dynamics',
    'authenticity_detection',
    'community_evolution',
    'recommendation_accuracy',
    'personalization_depth',
    'trend_prediction',
    'collaboration_effectiveness',
  ];

  static const List<String> dataSources = <String>[
    'user_actions',
    'location_data',
    'weather_conditions',
    'time_patterns',
    'social_connections',
    'age_demographics',
    'app_usage_patterns',
    'community_interactions',
    'ai2ai_communications',
    'external_context',
  ];

  static const Map<String, double> learningRates = <String, double>{
    'user_preference_understanding': 0.15,
    'location_intelligence': 0.12,
    'temporal_patterns': 0.10,
    'social_dynamics': 0.13,
    'authenticity_detection': 0.20,
    'community_evolution': 0.11,
    'recommendation_accuracy': 0.18,
    'personalization_depth': 0.16,
    'trend_prediction': 0.14,
    'collaboration_effectiveness': 0.17,
  };

  static Map<String, double> applyLearningRates(
    Map<String, double> rawUpdates,
  ) {
    final weighted = <String, double>{};
    for (final entry in rawUpdates.entries) {
      final rate = learningRates[entry.key] ?? 0.1;
      weighted[entry.key] = entry.value * rate;
    }
    return weighted;
  }
}
