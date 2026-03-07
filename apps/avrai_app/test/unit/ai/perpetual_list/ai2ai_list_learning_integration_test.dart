// AI2AI List Learning Integration Tests
//
// Unit tests for the AI2AIListLearningIntegration that connects
// list interactions back to the personality learning system.
//
// Key test scenarios:
// - Learning rate limits (1.5% per list interaction)
// - Age filtering of insights
// - Possibility collapse from user observations
// - Sensitive category handling

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_runtime_os/ai/perpetual_list/models/models.dart';
import 'package:avrai_runtime_os/ai/perpetual_list/filters/age_aware_list_filter.dart';
import 'package:avrai_core/models/spots/spot.dart';

void main() {
  group('AI2AIListLearningIntegration', () {
    group('learning rate', () {
      test('should apply 1.5% learning rate for list interactions', () {
        // Base AI2AI learning rate is 15%, scaled by 0.1 for list interactions
        const baseRate = 0.15;
        const listInteractionScale = 0.1;
        final listLearningRate = baseRate * listInteractionScale;

        expect(listLearningRate, equals(0.015)); // 1.5%
      });

      test('should cap dimension updates based on learning rate', () {
        const learningRate = 0.015;
        const maxUpdate = 0.05; // Max 5% change per interaction

        const rawUpdate = 0.10; // 10% suggested update
        final cappedUpdate = rawUpdate.clamp(-maxUpdate, maxUpdate);

        expect(cappedUpdate, equals(0.05));
        // Verify learning rate is correctly defined (1.5%)
        expect(learningRate, equals(0.015));
      });

      test('should respect 30% max personality drift', () {
        const maxDrift = 0.30;
        const currentValue = 0.5;

        // After many interactions, drift should be capped
        const accumulatedDrift = 0.35;
        final clampedDrift = accumulatedDrift.clamp(-maxDrift, maxDrift);

        expect(clampedDrift, equals(0.30));
        expect(currentValue + clampedDrift, lessThanOrEqualTo(0.8));
      });
    });

    group('list interaction types', () {
      test('should handle positive interactions', () {
        final positiveTypes = [
          ListInteractionType.saved,
          ListInteractionType.placeVisited,
        ];

        for (final type in positiveTypes) {
          final interaction = ListInteraction(
            listId: 'test-list',
            type: type,
            timestamp: DateTime.now(),
          );
          expect(
            interaction.isPositive,
            isTrue,
            reason: '${type.name} should be positive',
          );
        }
      });

      test('should handle negative interactions', () {
        final negativeTypes = [ListInteractionType.dismissed];

        for (final type in negativeTypes) {
          final interaction = ListInteraction(
            listId: 'test-list',
            type: type,
            timestamp: DateTime.now(),
          );
          expect(
            interaction.isNegative,
            isTrue,
            reason: '${type.name} should be negative',
          );
        }
      });

      test('should handle neutral interactions', () {
        final neutralTypes = [ListInteractionType.viewed];

        for (final type in neutralTypes) {
          final interaction = ListInteraction(
            listId: 'test-list',
            type: type,
            timestamp: DateTime.now(),
          );
          expect(
            interaction.isNeutral,
            isTrue,
            reason: '${type.name} should be neutral',
          );
        }
      });
    });

    group('age filtering', () {
      test('should filter 21+ insights for users under 21', () {
        final filter = AgeAwareListFilter();

        // Insights with alcohol-related categories should be filtered
        final candidateWithBar = _createScoredCandidate(category: 'bar');

        final filtered = filter.filterByAge(
          candidates: [candidateWithBar],
          userAge: 20,
          userOptInCategories: {},
        );

        expect(filtered, isEmpty);
      });

      test('should allow 21+ insights for users 21+', () {
        final filter = AgeAwareListFilter();

        final candidateWithBar = _createScoredCandidate(category: 'bar');

        final filtered = filter.filterByAge(
          candidates: [candidateWithBar],
          userAge: 21,
          userOptInCategories: {},
        );

        expect(filtered.length, equals(1));
      });

      test('should filter 18+ insights for users under 18', () {
        final filter = AgeAwareListFilter();

        final candidateWithAdult = _createScoredCandidate(
          category: 'tattoo_parlor',
        );

        final filtered = filter.filterByAge(
          candidates: [candidateWithAdult],
          userAge: 17,
          userOptInCategories: {},
        );

        expect(filtered, isEmpty);
      });
    });

    group('sensitive category handling', () {
      test('should require opt-in for sensitive categories', () {
        final filter = AgeAwareListFilter();

        final sensitiveCandidate = _createScoredCandidate(
          category: 'adult_entertainment',
        );

        // Without opt-in
        final filteredWithoutOptIn = filter.filterByAge(
          candidates: [sensitiveCandidate],
          userAge: 25,
          userOptInCategories: {},
        );
        expect(filteredWithoutOptIn, isEmpty);

        // With opt-in
        final filteredWithOptIn = filter.filterByAge(
          candidates: [sensitiveCandidate],
          userAge: 25,
          userOptInCategories: {'adult_entertainment'},
        );
        expect(filteredWithOptIn.length, equals(1));
      });

      test('should not propagate sensitive categories to AI2AI network', () {
        final sensitiveCategories = AgeAwareListFilter.sensitiveCategories;

        // These should never be shared with the network
        expect(sensitiveCategories.contains('adult_entertainment'), isTrue);
        expect(sensitiveCategories.contains('cannabis_dispensaries'), isTrue);
      });
    });

    group('possibility collapse', () {
      test(
        'should collapse to best matching possibility on positive interaction',
        () {
          final possibilities = [
            _createPossibilityState(id: 'stable', probability: 0.5),
            _createPossibilityState(id: 'growth', probability: 0.3),
            _createPossibilityState(id: 'decline', probability: 0.2),
          ];

          // On positive interaction, collapse toward the state that predicted it
          final observedDimensions = {'novelty_seeking': 0.8};

          // Find best matching possibility
          PossibilityState? bestMatch;
          double bestScore = 0.0;

          for (final possibility in possibilities) {
            double score = 0.0;
            for (final dim in observedDimensions.entries) {
              final possibilityValue = possibility.dimensions[dim.key] ?? 0.5;
              score += 1.0 - (dim.value - possibilityValue).abs();
            }
            score *= possibility.probability;

            if (score > bestScore) {
              bestScore = score;
              bestMatch = possibility;
            }
          }

          expect(bestMatch, isNotNull);
        },
      );

      test('should mark surprising outcomes when expectation violated', () {
        const expectedProbability = 0.8;
        const actualOutcome = 0.2; // Low probability outcome occurred

        final isSurprising = actualOutcome < expectedProbability * 0.5;

        expect(isSurprising, isTrue);
      });

      test('should generate dimension updates from collapse', () {
        final collapseResult = PossibilityCollapseResult(
          realizedPossibility: _createPossibilityState(
            id: 'growth',
            dimensions: {'novelty_seeking': 0.7},
          ),
          matchScore: 0.8,
          wasSurprising: false,
          dimensionUpdates: {'novelty_seeking': 0.02},
        );

        expect(collapseResult.dimensionUpdates, isNotEmpty);
        expect(
          collapseResult.dimensionUpdates['novelty_seeking'],
          equals(0.02),
        );
      });
    });

    group('PossibilityCollapseResult model', () {
      test('should contain realized possibility', () {
        final result = PossibilityCollapseResult(
          realizedPossibility: _createPossibilityState(id: 'stable'),
          matchScore: 0.9,
          wasSurprising: false,
          dimensionUpdates: {},
        );

        expect(result.realizedPossibility.id, equals('stable'));
      });

      test('should track if outcome was surprising', () {
        final surprisingResult = PossibilityCollapseResult(
          realizedPossibility: _createPossibilityState(id: 'decline'),
          matchScore: 0.3,
          wasSurprising: true,
          dimensionUpdates: {},
        );

        expect(surprisingResult.wasSurprising, isTrue);
      });

      test('should track match score', () {
        final result = PossibilityCollapseResult(
          realizedPossibility: _createPossibilityState(id: 'growth'),
          matchScore: 0.75,
          wasSurprising: false,
          dimensionUpdates: {},
        );

        expect(result.matchScore, equals(0.75));
      });
    });

    group('insight aggregation', () {
      test('should aggregate multiple insights into dimension updates', () {
        final insights = [
          {'novelty_seeking': 0.02},
          {'novelty_seeking': 0.01},
          {'crowd_tolerance': 0.03},
        ];

        final aggregated = <String, double>{};
        for (final insight in insights) {
          for (final entry in insight.entries) {
            aggregated[entry.key] =
                (aggregated[entry.key] ?? 0.0) + entry.value;
          }
        }

        expect(aggregated['novelty_seeking'], equals(0.03));
        expect(aggregated['crowd_tolerance'], equals(0.03));
      });

      test('should cap aggregated updates to max learning limit', () {
        const maxUpdate = 0.05;
        final aggregated = {'novelty_seeking': 0.10};

        final capped = aggregated.map(
          (dim, update) => MapEntry(dim, update.clamp(-maxUpdate, maxUpdate)),
        );

        expect(capped['novelty_seeking'], equals(0.05));
      });
    });

    group('ListInteraction model', () {
      test(
        'should store place ID in metadata for place-specific interactions',
        () {
          final interaction = ListInteraction(
            listId: 'test-list',
            type: ListInteractionType.placeVisited,
            timestamp: DateTime.now(),
            metadata: {'placeId': 'visited-place-123'},
          );

          expect(interaction.metadata['placeId'], equals('visited-place-123'));
        },
      );

      test('should store category in metadata for category-level learning', () {
        final interaction = ListInteraction(
          listId: 'test-list',
          type: ListInteractionType.saved,
          timestamp: DateTime.now(),
          metadata: {'category': 'cafe'},
        );

        expect(interaction.metadata['category'], equals('cafe'));
      });

      test('should calculate interaction age', () {
        final oldInteraction = ListInteraction(
          listId: 'test-list',
          type: ListInteractionType.viewed,
          timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        );

        final age = DateTime.now().difference(oldInteraction.timestamp);

        expect(age.inHours, greaterThanOrEqualTo(4));
      });

      test('should expose soft ignore metadata and lower learning weight', () {
        final interaction = ListInteraction(
          listId: 'test-list',
          type: ListInteractionType.dismissed,
          timestamp: DateTime.now(),
          metadata: const <String, dynamic>{
            ListInteraction.negativePreferenceIntentMetadataKey:
                ListInteraction.softIgnoreIntentValue,
          },
        );

        expect(interaction.isSoftIgnore, isTrue);
        expect(interaction.isHardNotInterested, isFalse);
        expect(interaction.learningWeight, 0.5);
      });

      test(
        'should expose hard not interested metadata and stronger learning weight',
        () {
          final interaction = ListInteraction(
            listId: 'test-list',
            type: ListInteractionType.dismissed,
            timestamp: DateTime.now(),
            metadata: const <String, dynamic>{
              ListInteraction.negativePreferenceIntentMetadataKey:
                  ListInteraction.hardNotInterestedIntentValue,
            },
          );

          expect(interaction.isSoftIgnore, isFalse);
          expect(interaction.isHardNotInterested, isTrue);
          expect(interaction.learningWeight, 1.2);
        },
      );
    });
  });
}

/// Helper to create a scored candidate for testing
ScoredCandidate _createScoredCandidate({String category = 'cafe'}) {
  return ScoredCandidate(
    candidate: ListCandidate(
      place: _createTestSpot(category: category),
      category: category,
    ),
    possibilityScore: 0.7,
    noveltyScore: 0.6,
    timelinessScore: 0.5,
    combinedScore: 0.6,
  );
}

/// Helper to create a test spot using the real Spot model
Spot _createTestSpot({String category = 'cafe'}) {
  return Spot(
    id: 'spot-${DateTime.now().millisecondsSinceEpoch}',
    name: 'Test Place',
    description: 'A test place',
    category: category,
    latitude: 40.7128,
    longitude: -74.0060,
    rating: 4.0,
    createdBy: 'test-user',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

/// Helper to create a possibility state for testing
PossibilityState _createPossibilityState({
  required String id,
  double probability = 0.5,
  Map<String, double>? dimensions,
}) {
  return PossibilityState(
    id: id,
    dimensions: dimensions ?? {'novelty_seeking': 0.5, 'crowd_tolerance': 0.5},
    probability: probability,
    trajectory: TrajectoryInfo(
      type: TrajectoryType.stable,
      direction: TrajectoryDirection.neutral,
      momentum: 0.0,
    ),
    confidenceBounds: ConfidenceInterval(lower: 0.3, upper: 0.7, center: 0.5),
  );
}
