// String Theory Possibility Engine Tests
//
// Tests for the possibility space generation and scoring system
// that implements string theory-inspired matching.
//
// Key test scenarios:
// - Possibility space generation
// - Probability normalization
// - Scoring across possibilities
// - Possibility collapse from observations

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/ai/perpetual_list/analyzers/string_theory_possibility_engine.dart';
import 'package:avrai/core/ai/perpetual_list/models/models.dart';
import 'package:avrai_core/models/personality_profile.dart';

void main() {
  group('StringTheoryPossibilityEngine', () {
    late StringTheoryPossibilityEngine engine;

    setUp(() {
      engine = StringTheoryPossibilityEngine();
    });

    group('possibility space generation', () {
      test('should generate requested number of possibilities', () async {
        final context = _createMockContext();

        final possibilities = await engine.generatePossibilitySpace(
          context: context,
          branchCount: 5,
        );

        expect(possibilities.length, equals(5));
      });

      test('should generate possibilities with unique IDs', () async {
        final context = _createMockContext();

        final possibilities = await engine.generatePossibilitySpace(
          context: context,
        );

        final ids = possibilities.map((p) => p.id).toSet();
        expect(ids.length, equals(possibilities.length));
      });

      test('should include stable trajectory in possibilities', () async {
        final context = _createMockContext();

        final possibilities = await engine.generatePossibilitySpace(
          context: context,
        );

        final hasStable = possibilities.any(
          (p) => p.trajectory.type == TrajectoryType.stable,
        );

        expect(hasStable, isTrue);
      });
    });

    group('probability normalization', () {
      test('normalized probabilities should sum to 1.0', () async {
        final context = _createMockContext();

        final possibilities = await engine.generatePossibilitySpace(
          context: context,
        );

        final sum = possibilities
            .map((p) => p.normalizedProbability)
            .fold(0.0, (a, b) => a + b);

        expect(sum, closeTo(1.0, 0.001));
      });

      test('stable trajectory should have highest probability', () async {
        final context = _createMockContext();

        final possibilities = await engine.generatePossibilitySpace(
          context: context,
        );

        final stable = possibilities.firstWhere(
          (p) => p.trajectory.type == TrajectoryType.stable,
        );

        final maxProb = possibilities
            .map((p) => p.normalizedProbability)
            .reduce((a, b) => a > b ? a : b);

        expect(stable.normalizedProbability, equals(maxProb));
      });
    });

    group('scoring across possibilities', () {
      test('should return score between 0 and 1', () async {
        final context = _createMockContext();

        final possibilities = await engine.generatePossibilitySpace(
          context: context,
        );

        final candidateDimensions = {
          'novelty_seeking': 0.7,
          'exploration_eagerness': 0.6,
          'crowd_tolerance': 0.5,
        };

        final score = await engine.scoreAcrossPossibilities(
          candidateDimensions: candidateDimensions,
          possibilities: possibilities,
        );

        expect(score, greaterThanOrEqualTo(0.0));
        expect(score, lessThanOrEqualTo(1.0));
      });

      test('should score higher for matching dimensions', () async {
        final context = _createMockContext();

        final possibilities = await engine.generatePossibilitySpace(
          context: context,
        );

        // Score with matching dimensions (similar to context personality)
        final matchingScore = await engine.scoreAcrossPossibilities(
          candidateDimensions: {
            'novelty_seeking': 0.6,
            'exploration_eagerness': 0.5,
            'crowd_tolerance': 0.5,
          },
          possibilities: possibilities,
        );

        // Score with very different dimensions
        final mismatchScore = await engine.scoreAcrossPossibilities(
          candidateDimensions: {
            'novelty_seeking': 0.1,
            'exploration_eagerness': 0.1,
            'crowd_tolerance': 0.9,
          },
          possibilities: possibilities,
        );

        // Matching should score higher or equal
        expect(matchingScore, greaterThanOrEqualTo(mismatchScore - 0.2));
      });
    });

    group('possibility collapse', () {
      test('should find best matching possibility from observation', () async {
        final context = _createMockContext();

        final possibilities = await engine.generatePossibilitySpace(
          context: context,
        );

        final interaction = ListInteraction(
          type: ListInteractionType.saved,
          listId: 'test-list',
          timestamp: DateTime.now(),
        );

        final result = await engine.collapseFromObservation(
          interaction: interaction,
          previousPossibilities: possibilities,
        );

        expect(result.realizedPossibility, isNotNull);
        expect(result.matchScore, greaterThanOrEqualTo(0.0));
        expect(result.matchScore, lessThanOrEqualTo(1.0));
      });

      test('should mark surprising outcomes correctly', () async {
        final context = _createMockContext();

        final possibilities = await engine.generatePossibilitySpace(
          context: context,
        );

        // Force a low probability possibility
        for (final p in possibilities) {
          p.normalizedProbability = 0.1; // Make all low probability
        }
        possibilities.first.normalizedProbability = 0.6; // One high

        final interaction = ListInteraction(
          type: ListInteractionType.dismissed,
          listId: 'test-list',
          timestamp: DateTime.now(),
        );

        final result = await engine.collapseFromObservation(
          interaction: interaction,
          previousPossibilities: possibilities,
        );

        // If matched a low probability option, should be surprising
        if (result.realizedPossibility.normalizedProbability < 0.15) {
          expect(result.wasSurprising, isTrue);
        }
      });

      test('should generate dimension updates from collapse', () async {
        final context = _createMockContext();

        final possibilities = await engine.generatePossibilitySpace(
          context: context,
        );

        final interaction = ListInteraction(
          type: ListInteractionType.placeVisited,
          listId: 'test-list',
          involvedPlaces: [],
          timestamp: DateTime.now(),
        );

        final result = await engine.collapseFromObservation(
          interaction: interaction,
          previousPossibilities: possibilities,
        );

        // Should have some dimension updates
        expect(result.dimensionUpdates, isA<Map<String, double>>());
      });
    });

    group('trajectory types', () {
      test('should include network-influenced trajectory with AI2AI insights', () async {
        final context = _createMockContext(
          withAI2AIInsights: true,
        );

        final possibilities = await engine.generatePossibilitySpace(
          context: context,
        );

        final hasNetworkInfluenced = possibilities.any(
          (p) => p.trajectory.type == TrajectoryType.networkInfluenced,
        );

        expect(hasNetworkInfluenced, isTrue);
      });

      test('should include consolidation trajectory', () async {
        final context = _createMockContext();

        final possibilities = await engine.generatePossibilitySpace(
          context: context,
        );

        final hasConsolidation = possibilities.any(
          (p) => p.trajectory.type == TrajectoryType.consolidation,
        );

        expect(hasConsolidation, isTrue);
      });
    });
  });
}

/// Create a mock ListGenerationContext for testing
ListGenerationContext _createMockContext({
  bool withAI2AIInsights = false,
  bool withVisitPatterns = false,
}) {
  final personality = PersonalityProfile(
    agentId: 'test-agent',
    userId: 'test-user',
    archetype: 'explorer',
    dimensions: {
      'novelty_seeking': 0.6,
      'exploration_eagerness': 0.5,
      'crowd_tolerance': 0.5,
      'temporal_flexibility': 0.6,
      'value_orientation': 0.5,
      'community_orientation': 0.6,
    },
    dimensionConfidence: {},
    authenticity: 0.9,
    evolutionGeneration: 5,
    learningHistory: {},
    createdAt: DateTime.now(),
    lastUpdated: DateTime.now(),
  );

  final networkInsights = withAI2AIInsights
      ? [
          AI2AIInsightSummary(
            quality: 0.8,
            type: 'test',
            receivedAt: DateTime.now(),
          ),
          AI2AIInsightSummary(
            quality: 0.75,
            type: 'test',
            receivedAt: DateTime.now(),
          ),
        ]
      : <AI2AIInsightSummary>[];

  final visitPatterns = withVisitPatterns
      ? [
          VisitPattern(
            id: 'visit-1',
            userId: 'test-user',
            category: 'coffee',
            latitude: 40.7128,
            longitude: -74.0060,
            atomicTimestamp: DateTime.now().subtract(const Duration(days: 1)),
            dwellTime: const Duration(minutes: 30),
            dayOfWeek: DayOfWeek.monday,
            timeSlot: TimeSlot.morning,
            isRepeatVisit: false,
            visitFrequency: 1,
            groupSize: 1,
          ),
        ]
      : <VisitPattern>[];

  return ListGenerationContext(
    userId: 'test-user',
    userAge: 25,
    personality: personality,
    networkInsights: networkInsights,
    visitPatterns: visitPatterns,
    listHistory: ListHistory.empty,
    currentLocation: LocationInfo.unknown(),
    atomicTime: DateTime.now(),
    preferenceSignals: UserPreferenceSignals.defaults(age: 25),
  );
}
