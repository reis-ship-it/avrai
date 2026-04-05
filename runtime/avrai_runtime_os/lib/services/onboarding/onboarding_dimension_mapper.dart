import 'dart:developer' as developer;

import 'package:avrai_core/models/user/dimension_question.dart';
import 'package:avrai_core/utils/vibe_constants.dart';

/// Maps raw onboarding answers into initial values for the 12 avrai dimensions.
///
/// **Source of truth:** on-device.
///
/// This intentionally mirrors the logic used by `PersonalityLearning` so the app
/// can derive dimensions without any network dependency.
///
/// Supports two modes:
/// 1. **Legacy mode:** Infers dimensions from preferences/places (indirect)
/// 2. **Direct mode:** Uses explicit dimension answers from questions (new flow)
///
/// Notes:
/// - Direct mode produces complete values for all 12 dimensions.
/// - Legacy mode produces *initial insights* for a subset of dimensions.
/// - Values are clamped to 0.0–1.0.
final class OnboardingDimensionMapper {
  static const String _logName = 'OnboardingDimensionMapper';

  /// Compute all 12 dimensions from direct question answers.
  ///
  /// This is the preferred method for the new onboarding flow that uses
  /// explicit dimension questions instead of inferring from preferences.
  ///
  /// Returns a map of dimension name to value (0.0-1.0) with all 12 dimensions.
  Map<String, double> computeDimensionsFromAnswers(
    List<QuestionAnswer> answers,
  ) {
    final dimensions = <String, double>{};
    final weights = <String, double>{};

    // Initialize all dimensions with default value
    for (final dim in VibeConstants.coreDimensions) {
      dimensions[dim] = VibeConstants.defaultDimensionValue;
      weights[dim] = 0.0;
    }

    try {
      // Process each answer
      for (final answer in answers) {
        final dimensionValues = answer.dimensionValues;

        for (final impact in answer.question.impacts) {
          final dim = impact.dimension;
          final value = dimensionValues[dim];

          if (value == null) continue;

          final weight = impact.weight;
          final currentWeight = weights[dim]!;
          final newWeight = currentWeight + weight;

          // Weighted average calculation
          dimensions[dim] =
              (dimensions[dim]! * currentWeight + value * weight) / newWeight;
          weights[dim] = newWeight;
        }

        // Handle secondary dimension values (from multi-choice options)
        for (final entry in dimensionValues.entries) {
          final dim = entry.key;
          final value = entry.value;

          // Skip if already processed as primary impact
          if (answer.question.impacts.any((i) => i.dimension == dim)) continue;

          // Check if this is a valid dimension
          if (!VibeConstants.coreDimensions.contains(dim)) continue;

          const secondaryWeight = 0.3;
          final currentWeight = weights[dim]!;
          final newWeight = currentWeight + secondaryWeight;

          dimensions[dim] =
              (dimensions[dim]! * currentWeight + value * secondaryWeight) /
                  newWeight;
          weights[dim] = newWeight;
        }
      }

      // Clamp all values to valid range
      dimensions.forEach((key, value) {
        dimensions[key] = value.clamp(0.0, 1.0);
      });

      developer.log(
        'Computed ${dimensions.length} dimensions from ${answers.length} answers',
        name: _logName,
      );

      return dimensions;
    } catch (e, st) {
      developer.log(
        'Error computing dimensions from answers: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return dimensions; // Return defaults on error
    }
  }

  /// Compute confidence levels for each dimension based on answers.
  Map<String, double> computeConfidenceFromAnswers(
    List<QuestionAnswer> answers,
  ) {
    final confidence = <String, double>{};
    final questionCounts = <String, int>{};

    // Initialize all dimensions with minimum confidence
    for (final dim in VibeConstants.coreDimensions) {
      confidence[dim] = 0.3;
      questionCounts[dim] = 0;
    }

    for (final answer in answers) {
      for (final impact in answer.question.impacts) {
        final dim = impact.dimension;
        questionCounts[dim] = questionCounts[dim]! + 1;

        // Base confidence boost per question
        confidence[dim] = confidence[dim]! + 0.15 * impact.weight;

        // Bonus for clear answers (slider not in the middle)
        if (answer.question.type == QuestionType.slider) {
          final sliderValue = answer.value as double;
          final clarity = (sliderValue - 0.5).abs() * 2;
          confidence[dim] = confidence[dim]! + 0.1 * clarity;
        }
      }
    }

    // Clamp confidence values
    confidence.forEach((key, value) {
      confidence[key] = value.clamp(0.3, 0.95);
    });

    return confidence;
  }

  /// Derive initial dimension insights from onboarding data.
  ///
  /// `onboardingData` is expected to contain keys like:
  /// - `age` (int)
  /// - `homebase` (String)
  /// - `favoritePlaces` (List)
  /// - `preferences` (Map&lt;String, dynamic&gt;)
  /// - `respectedFriends` (List)
  Map<String, double> mapOnboardingToDimensions(
    Map<String, dynamic> onboardingData,
  ) {
    final insights = <String, double>{};

    try {
      // Age adjustments
      final age = onboardingData['age'] as int?;
      if (age != null) {
        if (age < 25) {
          insights['exploration_eagerness'] = 0.6;
          insights['temporal_flexibility'] = 0.65;
        } else if (age > 45) {
          insights['authenticity_preference'] = 0.65;
          insights['trust_network_reliance'] = 0.6;
        }
      }

      // Homebase → location dimensions
      final homebase = onboardingData['homebase'] as String?;
      if (homebase != null && _isUrbanArea(homebase)) {
        insights['location_adventurousness'] =
            (insights['location_adventurousness'] ?? 0.5) + 0.1;
      }

      // Favorite places → exploration, location adventurousness
      final favoritePlaces =
          onboardingData['favoritePlaces'] as List<dynamic>? ??
              const <dynamic>[];
      if (favoritePlaces.length > 5) {
        insights['exploration_eagerness'] =
            (insights['exploration_eagerness'] ?? 0.5) + 0.1;
        insights['location_adventurousness'] =
            (insights['location_adventurousness'] ?? 0.5) + 0.12;
      }

      // Preferences mapping
      final preferences =
          onboardingData['preferences'] as Map<String, dynamic>? ??
              const <String, dynamic>{};

      // Food & Drink → curation, authenticity
      if (preferences.containsKey('Food & Drink')) {
        final foodPrefs =
            preferences['Food & Drink'] as List<dynamic>? ?? const <dynamic>[];
        if (foodPrefs.isNotEmpty) {
          insights['curation_tendency'] =
              (insights['curation_tendency'] ?? 0.5) + 0.05;
          insights['authenticity_preference'] =
              (insights['authenticity_preference'] ?? 0.5) + 0.03;
        }
      }

      // Activities → exploration, social
      if (preferences.containsKey('Activities')) {
        final activityPrefs =
            preferences['Activities'] as List<dynamic>? ?? const <dynamic>[];
        if (activityPrefs.isNotEmpty) {
          insights['exploration_eagerness'] =
              (insights['exploration_eagerness'] ?? 0.5) + 0.08;
          insights['social_discovery_style'] =
              (insights['social_discovery_style'] ?? 0.5) + 0.05;
        }
      }

      // Outdoor & Nature → location adventurousness, exploration
      if (preferences.containsKey('Outdoor & Nature')) {
        final outdoorPrefs =
            preferences['Outdoor & Nature'] as List<dynamic>? ??
                const <dynamic>[];
        if (outdoorPrefs.isNotEmpty) {
          insights['location_adventurousness'] =
              (insights['location_adventurousness'] ?? 0.5) + 0.1;
          insights['exploration_eagerness'] =
              (insights['exploration_eagerness'] ?? 0.5) + 0.08;
        }
      }

      // Social preferences → community orientation, social discovery
      if (preferences.containsKey('Social')) {
        final socialPrefs =
            preferences['Social'] as List<dynamic>? ?? const <dynamic>[];
        if (socialPrefs.isNotEmpty) {
          insights['community_orientation'] =
              (insights['community_orientation'] ?? 0.5) + 0.1;
          insights['social_discovery_style'] =
              (insights['social_discovery_style'] ?? 0.5) + 0.08;
        }
      }

      // Friends/Respected Lists → community orientation, trust network
      final respectedFriends =
          onboardingData['respectedFriends'] as List<dynamic>? ??
              const <dynamic>[];
      if (respectedFriends.isNotEmpty) {
        insights['community_orientation'] =
            (insights['community_orientation'] ?? 0.5) + 0.08;
        insights['trust_network_reliance'] =
            (insights['trust_network_reliance'] ?? 0.5) + 0.06;
      }

      // Clamp all values to valid range
      insights.forEach((key, value) {
        insights[key] = value.clamp(0.0, 1.0);
      });

      return insights;
    } catch (e, st) {
      developer.log(
        'Error mapping onboarding data to dimensions: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return const <String, double>{};
    }
  }

  bool _isUrbanArea(String homebase) {
    // Simple heuristic: check for common urban indicators
    final lowerHomebase = homebase.toLowerCase();
    return lowerHomebase.contains('city') ||
        lowerHomebase.contains('san francisco') ||
        lowerHomebase.contains('new york') ||
        lowerHomebase.contains('los angeles') ||
        lowerHomebase.contains('chicago') ||
        lowerHomebase.contains('boston') ||
        lowerHomebase.contains('seattle') ||
        lowerHomebase.contains('portland') ||
        lowerHomebase.contains('austin') ||
        lowerHomebase.contains('miami') ||
        lowerHomebase.contains('denver');
  }
}
