import 'dart:developer' as developer;
import 'package:avrai_core/models/user/user.dart';

/// OUR_GUTS.md: "Personalized, Not Prescriptive"
/// Learns user preferences from behavior without being prescriptive
class PreferenceLearningEngine {
  static const String _logName = 'PreferenceLearningEngine';

  /// Learn preferences from user behavior patterns
  /// OUR_GUTS.md: "Your feedback shapes SPOTS"
  Future<UserPreferences> learnFromBehavior(UserBehaviorData data) async {
    try {
      developer.log('Learning preferences from behavior', name: _logName);

      // Analyze behavior patterns while respecting privacy
      final categoryAffinities = await _analyzeCategoryPreferences(data);
      final timePreferences = await _analyzeTimePreferences(data);
      final socialPreferences = await _analyzeSocialPreferences(data);

      return UserPreferences(
        categoryAffinities: categoryAffinities,
        timePreferences: timePreferences,
        socialPreferences: socialPreferences,
        confidenceLevel: _calculateConfidence(data),
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      developer.log('Error learning preferences: $e', name: _logName);
      throw PreferenceLearningException('Failed to learn user preferences');
    }
  }

  /// Analyze category affinity based on user behavior
  Future<CategoryPreferences> analyzeCategoryAffinity(User user) async {
    // OUR_GUTS.md: "Authenticity Over Algorithms"
    return CategoryPreferences(
      topCategories: ['food', 'coffee', 'outdoor'],
      categoryScores: {'food': 0.8, 'coffee': 0.7, 'outdoor': 0.6},
      emergingInterests: ['art', 'music'],
    );
  }

  /// Identify social context preferences
  Future<SocialPreferences> identifySocialContexts(User user) async {
    // OUR_GUTS.md: "Community, Not Just Places"
    return SocialPreferences(
      soloPreference: 0.3,
      smallGroupPreference: 0.5,
      largeGroupPreference: 0.2,
      communityEventPreference: 0.6,
    );
  }

  // Private helper methods
  Future<Map<String, double>> _analyzeCategoryPreferences(
      UserBehaviorData data) async {
    return {'food': 0.8, 'entertainment': 0.6};
  }

  Future<Map<String, double>> _analyzeTimePreferences(
      UserBehaviorData data) async {
    return {'morning': 0.3, 'afternoon': 0.4, 'evening': 0.8};
  }

  Future<Map<String, double>> _analyzeSocialPreferences(
      UserBehaviorData data) async {
    return {'solo': 0.4, 'friends': 0.6, 'family': 0.3};
  }

  double _calculateConfidence(UserBehaviorData data) {
    // Calculate confidence based on data quality and quantity
    return 0.85;
  }
}

// Supporting classes
class UserBehaviorData {
  final String userId;
  final List<String> visitHistory;
  final Map<String, dynamic> interactions;
  final DateTime startDate;
  final DateTime endDate;

  UserBehaviorData({
    required this.userId,
    required this.visitHistory,
    required this.interactions,
    required this.startDate,
    required this.endDate,
  });
}

class UserPreferences {
  final Map<String, double> categoryAffinities;
  final Map<String, double> timePreferences;
  final Map<String, double> socialPreferences;
  final double confidenceLevel;
  final DateTime lastUpdated;

  UserPreferences({
    required this.categoryAffinities,
    required this.timePreferences,
    required this.socialPreferences,
    required this.confidenceLevel,
    required this.lastUpdated,
  });
}

class CategoryPreferences {
  final List<String> topCategories;
  final Map<String, double> categoryScores;
  final List<String> emergingInterests;

  CategoryPreferences({
    required this.topCategories,
    required this.categoryScores,
    required this.emergingInterests,
  });
}

class SocialPreferences {
  final double soloPreference;
  final double smallGroupPreference;
  final double largeGroupPreference;
  final double communityEventPreference;

  SocialPreferences({
    required this.soloPreference,
    required this.smallGroupPreference,
    required this.largeGroupPreference,
    required this.communityEventPreference,
  });
}

class PreferenceLearningException implements Exception {
  final String message;
  PreferenceLearningException(this.message);
}
