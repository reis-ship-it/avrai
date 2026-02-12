import 'dart:developer' as developer;
import 'dart:math';

import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai/core/ai/ai2ai_learning.dart';
import 'package:avrai/core/constants/vibe_constants.dart';

/// Generates AI2AI learning recommendations
class LearningRecommendationsGenerator {
  static const String _logName = 'LearningRecommendationsGenerator';

  static double _compatibilityFromDimensions({
    required Map<String, double> a,
    required Map<String, double> b,
  }) {
    final keys = a.keys.toSet().intersection(b.keys.toSet());
    if (keys.isEmpty) {
      return 0.5;
    }

    var totalDiff = 0.0;
    for (final k in keys) {
      totalDiff += (a[k]! - b[k]!).abs();
    }
    final avgDiff = totalDiff / keys.length;
    return (1.0 - avgDiff).clamp(0.0, 1.0);
  }

  /// Identify optimal personality types for learning
  Future<List<OptimalPartner>> identifyOptimalLearningPartners(
    PersonalityProfile currentPersonality,
    List<CrossPersonalityLearningPattern> learningPatterns,
  ) async {
    try {
      developer.log(
          'Identifying optimal learning partners from ${learningPatterns.length} patterns',
          name: _logName);

      final archetypes = VibeConstants.personalityArchetypes.keys.toList();
      final baseline = currentPersonality.dimensions.isNotEmpty
          ? currentPersonality.dimensions
          : (VibeConstants.personalityArchetypes[currentPersonality.archetype] ??
              const <String, double>{});

      final scored = <OptimalPartner>[];
      for (final archetype in archetypes) {
        if (archetype == currentPersonality.archetype) {
          continue;
        }
        final signature = VibeConstants.personalityArchetypes[archetype];
        if (signature == null || signature.isEmpty) {
          continue;
        }
        final compatibility = _compatibilityFromDimensions(
          a: baseline,
          b: signature,
        );
        scored.add(OptimalPartner(archetype, compatibility));
      }

      scored.sort((a, b) => b.compatibility.compareTo(a.compatibility));

      // In early/empty-learning states we still want stable defaults, so ensure we
      // return at least a small set (when archetypes exist).
      final result = scored.take(3).toList(); // UI/tests expect <= 3
      developer.log('Identified ${result.length} optimal learning partners',
          name: _logName);
      return result;
    } catch (e) {
      developer.log('Error identifying optimal partners: $e', name: _logName);
      return [];
    }
  }

  /// Generate conversation topics for maximum learning
  Future<List<LearningTopic>> generateLearningTopics(
    PersonalityProfile currentPersonality,
    List<CrossPersonalityLearningPattern> learningPatterns,
  ) async {
    try {
      developer.log('Generating learning topics from patterns',
          name: _logName);

      final topics = <LearningTopic>[];

      // Prefer pattern-driven topics when available.
      for (final pattern in learningPatterns) {
        if (pattern.patternType == 'knowledge_sharing') {
          final sharingScore = pattern.strength;
          final insightCount =
              pattern.characteristics['total_insights'] as int? ?? 0;

          if (sharingScore >= 0.3 && insightCount > 0) {
            topics.add(LearningTopic(
              'Deepen knowledge sharing',
              sharingScore.clamp(0.0, 1.0),
            ));
          }
        }
      }

      // Fallback: derive topics from "interesting" dimensions (low confidence or
      // extreme values), so recommendations work even with empty chat history.
      if (topics.isEmpty) {
        final dimEntries = currentPersonality.dimensions.entries.toList();
        dimEntries.sort((a, b) {
          final aScore = (a.value - 0.5).abs();
          final bScore = (b.value - 0.5).abs();
          return bScore.compareTo(aScore);
        });

        for (final entry in dimEntries.take(5)) {
          final dim = entry.key;
          final v = entry.value;
          final potential = ((v - 0.5).abs() * 2.0).clamp(0.0, 1.0);
          if (potential < 0.1) {
            continue;
          }
          final desc = VibeConstants.dimensionDescriptions[dim] ?? dim;
          topics.add(LearningTopic('Explore: $desc', potential));
        }
      }

      // Ensure at least one topic is returned (stable behavior for UI/tests).
      if (topics.isEmpty) {
        topics.add(LearningTopic('Explore new learning patterns', 0.5));
      }

      topics.sort((a, b) => b.potential.compareTo(a.potential));

      developer.log('Generated ${topics.length} learning topics', name: _logName);
      return topics.take(5).toList();
    } catch (e) {
      developer.log('Error generating learning topics: $e', name: _logName);
      return [];
    }
  }

  /// Recommend personality development areas
  Future<List<DevelopmentArea>> recommendDevelopmentAreas(
    PersonalityProfile currentPersonality,
    List<CrossPersonalityLearningPattern> learningPatterns,
  ) async {
    try {
      developer.log('Recommending development areas from patterns',
          name: _logName);

      final areas = <DevelopmentArea>[];

      // Analyze patterns for development opportunities (when present).
      for (final pattern in learningPatterns) {
        if (pattern.patternType == 'compatibility_evolution' ||
            pattern.patternType == 'learning_acceleration') {
          final evolutionRate =
              pattern.characteristics['evolution_rate'] as double? ??
                  pattern.strength;

          if (evolutionRate >= 0.2) {
            areas.add(DevelopmentArea(
              pattern.patternType.replaceAll('_', ' '),
              evolutionRate.clamp(0.0, 1.0),
            ));
          }
        }
      }

      // Fallback: recommend areas for low-confidence or extreme-value dimensions.
      if (areas.isEmpty) {
        final candidates = <MapEntry<String, double>>[];
        for (final entry in currentPersonality.dimensions.entries) {
          final v = entry.value;
          final confidence = currentPersonality.dimensionConfidence[entry.key] ?? 0.8;
          final isExtreme = v <= 0.2 || v >= 0.8;
          final isLowConfidence = confidence < 0.5;
          if (isExtreme || isLowConfidence) {
            final priority = max(1.0 - confidence, ((v - 0.5).abs() * 2.0))
                .clamp(0.0, 1.0);
            candidates.add(MapEntry(entry.key, priority));
          }
        }

        candidates.sort((a, b) => b.value.compareTo(a.value));
        for (final c in candidates.take(5)) {
          final desc = VibeConstants.dimensionDescriptions[c.key] ?? c.key;
          areas.add(DevelopmentArea(desc, c.value));
        }
      }

      // Sort by priority (highest first) and return top 5
      areas.sort((a, b) => b.priority.compareTo(a.priority));
      developer.log('Recommended ${areas.length} development areas',
          name: _logName);
      return areas.take(5).toList();
    } catch (e) {
      developer.log('Error recommending development areas: $e',
          name: _logName);
      return [];
    }
  }

  /// Suggest optimal interaction timing and frequency
  Future<InteractionStrategy> suggestInteractionStrategy(
    String userId,
    List<CrossPersonalityLearningPattern> patterns,
  ) async {
    // Simplified - returns balanced strategy
    // In production, would analyze patterns to suggest optimal timing
    return InteractionStrategy.balanced();
  }

  /// Calculate expected outcomes from learning recommendations
  Future<List<ExpectedOutcome>> calculateExpectedOutcomes(
    PersonalityProfile personality,
    List<OptimalPartner> partners,
    List<LearningTopic> topics,
  ) async {
    try {
      final outcomes = <ExpectedOutcome>[];

      // Calculate expected outcomes based on partners and topics
      if (partners.isNotEmpty && topics.isNotEmpty) {
        final avgCompatibility = partners
                .map((p) => p.compatibility)
                .reduce((a, b) => a + b) /
            partners.length;

        final avgTopicPotential = topics
                .map((t) => t.potential)
                .reduce((a, b) => a + b) /
            topics.length;

        // Expected personality evolution
        final evolutionProbability =
            (avgCompatibility * 0.6 + avgTopicPotential * 0.4).clamp(0.0, 1.0);
        outcomes.add(ExpectedOutcome(
          id: 'personality_evolution',
          description: 'Personality evolution through AI2AI learning',
          probability: evolutionProbability,
        ));

        // Expected dimension development
        outcomes.add(ExpectedOutcome(
          id: 'dimension_development',
          description: 'Development of personality dimensions',
          probability: avgTopicPotential,
        ));

        // Expected trust building
        outcomes.add(ExpectedOutcome(
          id: 'trust_building',
          description: 'Building trust with AI2AI partners',
          probability: avgCompatibility * 0.8,
        ));
      }

      return outcomes;
    } catch (e) {
      developer.log('Error calculating expected outcomes: $e', name: _logName);
      return [];
    }
  }

  /// Calculate recommendation confidence score
  double calculateRecommendationConfidence(
      List<CrossPersonalityLearningPattern> patterns) =>
      min(1.0, patterns.length / 5.0);
}
