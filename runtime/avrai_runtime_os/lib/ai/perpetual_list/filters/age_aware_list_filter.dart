import 'dart:developer' as developer;

import 'package:avrai_runtime_os/ai/personality_learning.dart';

import '../models/suggested_list.dart';

/// Age-Aware List Filter
///
/// Filters list candidates based on user age and category restrictions.
/// Ensures age-appropriate content and respects explicit opt-ins for sensitive categories.
///
/// Part of Phase 3: Perpetual List Orchestrator

class AgeAwareListFilter {
  static const String _logName = 'AgeAwareListFilter';

  /// Categories that require explicit opt-in regardless of age
  static const Set<String> sensitiveCategories = {
    'adult_entertainment',
    'sex_shops',
    'kink_venues',
    'cannabis_dispensaries',
    'hookah_lounges',
  };

  /// Categories that require age 21+
  static const Set<String> over21Categories = {
    'bars',
    'bar',
    'wine_bars',
    'wine_bar',
    'cocktail_lounges',
    'cocktail_lounge',
    'breweries',
    'brewery',
    'distilleries',
    'distillery',
    'nightclubs',
    'nightclub',
    'pubs',
    'pub',
    'speakeasy',
    'beer_garden',
    'beer_gardens',
    'wine_tasting',
    'spirits',
  };

  /// Categories that require age 18+
  static const Set<String> over18Categories = {
    'hookah_lounges',
    'hookah_lounge',
    'vape_shops',
    'vape_shop',
    'tattoo_parlors',
    'tattoo_parlor',
    'tattoo',
    'piercing',
    'smoking_lounge',
  };

  /// Filter list candidates by age appropriateness
  ///
  /// [candidates] - List of scored candidates to filter
  /// [userAge] - User's age in years
  /// [userOptInCategories] - Categories user has explicitly opted into
  ///
  /// Returns filtered list of candidates that are age-appropriate
  List<ScoredCandidate> filterByAge({
    required List<ScoredCandidate> candidates,
    required int userAge,
    Set<String>? userOptInCategories,
  }) {
    final filtered = candidates.where((candidate) {
      return isCategoryAllowed(
        category: candidate.category,
        userAge: userAge,
        userOptInCategories: userOptInCategories,
      );
    }).toList();

    if (filtered.length < candidates.length) {
      developer.log(
        'Filtered ${candidates.length - filtered.length} candidates by age (user age: $userAge)',
        name: _logName,
      );
    }

    return filtered;
  }

  /// Check if a category is allowed for a user
  ///
  /// [category] - Category to check
  /// [userAge] - User's age in years
  /// [userOptInCategories] - Categories user has explicitly opted into
  ///
  /// Returns true if category is allowed
  bool isCategoryAllowed({
    required String category,
    required int userAge,
    Set<String>? userOptInCategories,
  }) {
    final normalizedCategory = category.toLowerCase().trim();

    // Check if category requires explicit opt-in
    if (_isSensitiveCategory(normalizedCategory)) {
      // Must be 18+ AND have opted in
      if (userAge < 18) return false;
      if (userOptInCategories == null ||
          !userOptInCategories.contains(normalizedCategory)) {
        return false; // Not opted in
      }
      return true;
    }

    // Check 21+ categories
    if (_isOver21Category(normalizedCategory)) {
      return userAge >= 21;
    }

    // Check 18+ categories
    if (_isOver18Category(normalizedCategory)) {
      return userAge >= 18;
    }

    // Age-appropriate for all
    return true;
  }

  /// Filter AI2AI learning insights by age
  ///
  /// Never learn from age-inappropriate network insights.
  ///
  /// [insights] - Raw AI2AI learning insights
  /// [userAge] - User's age in years
  ///
  /// Returns filtered insights safe for this age
  List<AI2AILearningInsight> filterAI2AIInsightsByAge({
    required List<AI2AILearningInsight> insights,
    required int userAge,
  }) {
    return insights.where((insight) {
      // Check if the source of this insight was age-restricted content
      final sourceCategory = _extractSourceCategory(insight);

      if (sourceCategory != null) {
        if (_isSensitiveCategory(sourceCategory)) {
          // Never learn from sensitive categories via AI2AI
          return false;
        }

        if (_isOver21Category(sourceCategory) && userAge < 21) {
          return false;
        }

        if (_isOver18Category(sourceCategory) && userAge < 18) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// Validate that a suggested list respects age restrictions
  ///
  /// [list] - Suggested list to validate
  /// [userAge] - User's age in years
  ///
  /// Returns validation result with any violations
  AgeValidationResult validateListForAge({
    required SuggestedList list,
    required int userAge,
  }) {
    final violations = <AgeViolation>[];

    for (final place in list.places) {
      final category = place.category.toLowerCase();

      if (_isSensitiveCategory(category)) {
        violations.add(AgeViolation(
          placeName: place.name,
          category: category,
          reason: 'Requires explicit opt-in',
          requiredAge: 18,
        ));
      }

      if (_isOver21Category(category) && userAge < 21) {
        violations.add(AgeViolation(
          placeName: place.name,
          category: category,
          reason: 'Requires age 21+',
          requiredAge: 21,
        ));
      }

      if (_isOver18Category(category) && userAge < 18) {
        violations.add(AgeViolation(
          placeName: place.name,
          category: category,
          reason: 'Requires age 18+',
          requiredAge: 18,
        ));
      }
    }

    return AgeValidationResult(
      isValid: violations.isEmpty,
      violations: violations,
    );
  }

  /// Check if category is sensitive (always requires opt-in)
  bool _isSensitiveCategory(String category) {
    return sensitiveCategories.any(
      (c) => category.contains(c) || c.contains(category),
    );
  }

  /// Check if category requires 21+
  bool _isOver21Category(String category) {
    return over21Categories.any(
      (c) => category.contains(c) || c.contains(category),
    );
  }

  /// Check if category requires 18+
  bool _isOver18Category(String category) {
    return over18Categories.any(
      (c) => category.contains(c) || c.contains(category),
    );
  }

  /// Extract source category from AI2AI insight metadata
  String? _extractSourceCategory(AI2AILearningInsight insight) {
    // The insight type or metadata might contain category info
    // This depends on how insights are structured
    return null; // Will be populated when AI2AI integration is wired
  }

  /// Get age requirement for a category
  ///
  /// Returns null if no age requirement, otherwise the minimum age
  int? getAgeRequirement(String category) {
    final normalizedCategory = category.toLowerCase().trim();

    if (_isSensitiveCategory(normalizedCategory)) return 18;
    if (_isOver21Category(normalizedCategory)) return 21;
    if (_isOver18Category(normalizedCategory)) return 18;

    return null; // No age requirement
  }

  /// Check if user can access alcohol-related venues
  bool canAccessAlcohol(int userAge) => userAge >= 21;

  /// Check if user can access tobacco-related venues
  bool canAccessTobacco(int userAge) => userAge >= 18;

  /// Check if a category requires opt-in
  bool requiresOptIn(String category) {
    return _isSensitiveCategory(category.toLowerCase().trim());
  }
}

/// Result of age validation
class AgeValidationResult {
  /// Whether all places in the list are age-appropriate
  final bool isValid;

  /// List of violations found
  final List<AgeViolation> violations;

  const AgeValidationResult({
    required this.isValid,
    required this.violations,
  });

  /// Get violation messages as strings
  List<String> get violationMessages {
    return violations.map((v) => '${v.placeName}: ${v.reason}').toList();
  }
}

/// A single age violation
class AgeViolation {
  /// Name of the place with the violation
  final String placeName;

  /// Category that caused the violation
  final String category;

  /// Reason for the violation
  final String reason;

  /// Required age for this category
  final int requiredAge;

  const AgeViolation({
    required this.placeName,
    required this.category,
    required this.reason,
    required this.requiredAge,
  });

  @override
  String toString() {
    return 'AgeViolation($placeName: $reason, requires $requiredAge+)';
  }
}
