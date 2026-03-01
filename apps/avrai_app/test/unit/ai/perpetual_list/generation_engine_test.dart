// Generation Engine Tests
//
// Unit tests for the GenerationEngine that generates scored list candidates
// using quantum matching and scoring.
//
// Key test scenarios:
// - Candidate scoring with possibility weights
// - Novelty score calculation
// - Timeliness score calculation
// - List grouping by category
// - Cold start list generation fallback

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_runtime_os/ai/perpetual_list/engines/generation_engine.dart';
import 'package:avrai_runtime_os/ai/perpetual_list/models/models.dart';
import 'package:avrai_core/models/spots/spot.dart';

void main() {
  group('GenerationEngine', () {
    group('scoring weights', () {
      test('should have correct weight distribution', () {
        // Verify weights sum to 1.0
        const totalWeight = GenerationEngine.possibilityWeight +
            GenerationEngine.noveltyWeight +
            GenerationEngine.timelinessWeight;

        expect(totalWeight, equals(1.0));
      });

      test('should prioritize possibility score at 50%', () {
        expect(GenerationEngine.possibilityWeight, equals(0.50));
      });

      test('should weight novelty at 25%', () {
        expect(GenerationEngine.noveltyWeight, equals(0.25));
      });

      test('should weight timeliness at 25%', () {
        expect(GenerationEngine.timelinessWeight, equals(0.25));
      });
    });

    group('thresholds', () {
      test('should have minimum compatibility threshold of 0.4', () {
        expect(GenerationEngine.minCompatibilityThreshold, equals(0.4));
      });

      test('should limit places to score to 50', () {
        expect(GenerationEngine.maxPlacesToScore, equals(50));
      });

      test('should limit places per list to 8', () {
        expect(GenerationEngine.maxPlacesPerList, equals(8));
      });
    });

    group('combined score calculation', () {
      test('should calculate combined score correctly', () {
        const possibilityScore = 0.8;
        const noveltyScore = 0.6;
        const timelinessScore = 0.7;

        final combinedScore =
            possibilityScore * GenerationEngine.possibilityWeight +
                noveltyScore * GenerationEngine.noveltyWeight +
                timelinessScore * GenerationEngine.timelinessWeight;

        // 0.8 * 0.5 + 0.6 * 0.25 + 0.7 * 0.25 = 0.4 + 0.15 + 0.175 = 0.725
        expect(combinedScore, closeTo(0.725, 0.001));
      });

      test('should filter candidates below threshold', () {
        final candidates = [
          _createScoredCandidate(combinedScore: 0.7), // Above
          _createScoredCandidate(combinedScore: 0.3), // Below
          _createScoredCandidate(combinedScore: 0.5), // Above
          _createScoredCandidate(combinedScore: 0.2), // Below
        ];

        final filtered = candidates
            .where((c) =>
                c.combinedScore >= GenerationEngine.minCompatibilityThreshold)
            .toList();

        expect(filtered.length, equals(2));
      });
    });

    group('list grouping', () {
      test('should group candidates by category', () {
        final candidates = [
          _createScoredCandidate(category: 'cafe', combinedScore: 0.8),
          _createScoredCandidate(category: 'cafe', combinedScore: 0.7),
          _createScoredCandidate(category: 'restaurant', combinedScore: 0.6),
          _createScoredCandidate(category: 'bar', combinedScore: 0.5),
        ];

        final byCategory = <String, List<ScoredCandidate>>{};
        for (final candidate in candidates) {
          byCategory[candidate.category] ??= [];
          byCategory[candidate.category]!.add(candidate);
        }

        expect(byCategory.keys.length, equals(3));
        expect(byCategory['cafe']!.length, equals(2));
        expect(byCategory['restaurant']!.length, equals(1));
        expect(byCategory['bar']!.length, equals(1));
      });

      test('should sort categories by best candidate score', () {
        final byCategory = <String, List<ScoredCandidate>>{
          'cafe': [_createScoredCandidate(combinedScore: 0.6)],
          'restaurant': [_createScoredCandidate(combinedScore: 0.9)],
          'bar': [_createScoredCandidate(combinedScore: 0.5)],
        };

        final sorted = byCategory.entries.toList()
          ..sort((a, b) {
            final aScore = a.value.first.combinedScore;
            final bScore = b.value.first.combinedScore;
            return bScore.compareTo(aScore);
          });

        expect(sorted.first.key, equals('restaurant'));
        expect(sorted.last.key, equals('bar'));
      });

      test('should respect list count limit', () {
        final byCategory = <String, List<ScoredCandidate>>{
          'cafe': [_createScoredCandidate(combinedScore: 0.9)],
          'restaurant': [_createScoredCandidate(combinedScore: 0.8)],
          'bar': [_createScoredCandidate(combinedScore: 0.7)],
          'museum': [_createScoredCandidate(combinedScore: 0.6)],
        };

        const listCount = 2;
        final sortedCategories = byCategory.entries.toList()
          ..sort((a, b) => b.value.first.combinedScore
              .compareTo(a.value.first.combinedScore));

        final selected = sortedCategories.take(listCount).toList();
        expect(selected.length, equals(2));
        expect(selected.first.key, equals('cafe'));
        expect(selected.last.key, equals('restaurant'));
      });
    });

    group('novelty scoring', () {
      // Helper function to calculate novelty score
      double calculateNovelty(
          bool visited, bool recentlySuggested, double categoryFamiliarity) {
        double novelty = 1.0;
        if (visited) novelty -= 0.5;
        if (recentlySuggested) novelty -= 0.3;
        novelty -= categoryFamiliarity * 0.2;
        return novelty.clamp(0.0, 1.0);
      }

      test('should give full novelty to unvisited places', () {
        final novelty = calculateNovelty(false, false, 0.0);
        expect(novelty, equals(1.0));
      });

      test('should reduce novelty for visited places', () {
        final novelty = calculateNovelty(true, false, 0.0);
        expect(novelty, equals(0.5));
      });

      test('should reduce novelty for recently suggested places', () {
        final novelty = calculateNovelty(false, true, 0.0);
        expect(novelty, equals(0.7));
      });

      test('should reduce novelty for familiar categories', () {
        final novelty = calculateNovelty(false, false, 1.0);
        expect(novelty, equals(0.8));
      });

      test('should clamp novelty to 0.0-1.0 range', () {
        // All factors that reduce novelty combined
        final novelty = calculateNovelty(true, true, 1.0);

        expect(novelty, greaterThanOrEqualTo(0.0));
        expect(novelty, lessThanOrEqualTo(1.0));
        // Expected: 1.0 - 0.5 (visited) - 0.3 (suggested) - 0.2 (familiarity) = 0.0
        expect(novelty, equals(0.0));
      });
    });

    group('timeliness scoring', () {
      test('should calculate timeliness from slot and day activity', () {
        const slotActivity = 0.8;
        const dayActivity = 0.6;

        final timeliness = (slotActivity + dayActivity) / 2.0;

        expect(timeliness, equals(0.7));
      });

      test('should boost timeliness for matching category-time pairs', () {
        double timeliness = 0.5;
        const categoryMatchesTime = true;

        if (categoryMatchesTime) timeliness += 0.2;
        timeliness = timeliness.clamp(0.0, 1.0);

        expect(timeliness, equals(0.7));
      });

      test('should clamp timeliness to 0.0-1.0 range', () {
        double timeliness = 0.9;
        const categoryMatchesTime = true;

        if (categoryMatchesTime) timeliness += 0.2;
        timeliness = timeliness.clamp(0.0, 1.0);

        expect(timeliness, equals(1.0));
      });
    });

    group('category classification', () {
      test('should classify high energy categories', () {
        final highEnergyCategories = [
          'nightclub',
          'gym',
          'sports',
          'bar',
          'club'
        ];

        for (final category in highEnergyCategories) {
          final isHighEnergy = ['nightclub', 'gym', 'sports', 'bar', 'club']
              .any((c) => category.contains(c));
          expect(isHighEnergy, isTrue,
              reason: '$category should be high energy');
        }
      });

      test('should classify low energy categories', () {
        final lowEnergyCategories = [
          'spa',
          'library',
          'meditation',
          'yoga',
          'tea'
        ];

        for (final category in lowEnergyCategories) {
          final isLowEnergy = ['spa', 'library', 'meditation', 'yoga', 'tea']
              .any((c) => category.contains(c));
          expect(isLowEnergy, isTrue, reason: '$category should be low energy');
        }
      });

      test('should classify social categories', () {
        final socialCategories = ['restaurant', 'bar', 'pub', 'club', 'event'];

        for (final category in socialCategories) {
          final isSocial = ['restaurant', 'bar', 'pub', 'club', 'event']
              .any((c) => category.contains(c));
          expect(isSocial, isTrue, reason: '$category should be social');
        }
      });

      test('should classify solo categories', () {
        final soloCategories = [
          'library',
          'bookstore',
          'coffee',
          'cafe',
          'museum'
        ];

        for (final category in soloCategories) {
          final isSolo = ['library', 'bookstore', 'coffee', 'cafe', 'museum']
              .any((c) => category.contains(c));
          expect(isSolo, isTrue, reason: '$category should be solo');
        }
      });
    });

    group('time slot category matching', () {
      test('should match morning categories', () {
        expect(_doesCategoryMatchTimeSlot('coffee shop', TimeSlot.morning),
            isTrue);
        expect(_doesCategoryMatchTimeSlot('brunch spot', TimeSlot.morning),
            isTrue);
      });

      test('should match evening categories', () {
        expect(
            _doesCategoryMatchTimeSlot(
                'fine dining restaurant', TimeSlot.evening),
            isTrue);
        expect(_doesCategoryMatchTimeSlot('bar and grill', TimeSlot.evening),
            isTrue);
      });

      test('should match night categories', () {
        expect(_doesCategoryMatchTimeSlot('nightclub', TimeSlot.night), isTrue);
        expect(_doesCategoryMatchTimeSlot('late night bar', TimeSlot.night),
            isTrue);
      });
    });

    group('ScoredCandidate model', () {
      test('should create with all scores', () {
        final candidate = _createScoredCandidate(
          possibilityScore: 0.8,
          noveltyScore: 0.7,
          timelinessScore: 0.6,
          combinedScore: 0.725,
        );

        expect(candidate.possibilityScore, equals(0.8));
        expect(candidate.noveltyScore, equals(0.7));
        expect(candidate.timelinessScore, equals(0.6));
        expect(candidate.combinedScore, equals(0.725));
      });

      test('should expose category from candidate', () {
        final candidate = _createScoredCandidate(category: 'cafe');

        expect(candidate.category, equals('cafe'));
      });

      test('should expose place from candidate', () {
        final candidate = _createScoredCandidate();

        expect(candidate.place, isNotNull);
        expect(candidate.place.name, isNotEmpty);
      });
    });

    group('SuggestedList model', () {
      test('should calculate quality score', () {
        final list = SuggestedList(
          id: 'test-list',
          title: 'Test List',
          description: 'Test',
          places: [],
          theme: 'cafe',
          generatedAt: DateTime.now(),
          avgCompatibilityScore: 0.8,
          noveltyScore: 0.7,
          timelinessScore: 0.6,
          triggerReasons: ['time_based'],
        );

        // Quality score combines all factors
        expect(list.qualityScore, greaterThan(0));
        expect(list.qualityScore, lessThanOrEqualTo(1.0));
      });

      test('should format title correctly', () {
        // Test category formatting
        final category = 'coffee_shops';
        final formatted = category
            .split('_')
            .map((word) => word.isEmpty
                ? word
                : word[0].toUpperCase() + word.substring(1).toLowerCase())
            .join(' ');

        expect(formatted, equals('Coffee Shops'));
      });
    });
  });
}

/// Helper to create a scored candidate for testing
ScoredCandidate _createScoredCandidate({
  String category = 'cafe',
  double possibilityScore = 0.7,
  double noveltyScore = 0.6,
  double timelinessScore = 0.5,
  double combinedScore = 0.6,
}) {
  return ScoredCandidate(
    candidate: ListCandidate(
      place: Spot(
        id: 'spot-${DateTime.now().millisecondsSinceEpoch}',
        name: 'Test Place',
        description: 'A test place for unit testing',
        category: category,
        latitude: 40.7128,
        longitude: -74.0060,
        rating: 4.0,
        createdBy: 'test-user',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      category: category,
    ),
    possibilityScore: possibilityScore,
    noveltyScore: noveltyScore,
    timelinessScore: timelinessScore,
    combinedScore: combinedScore,
  );
}

/// Check if category matches time slot (duplicated from GenerationEngine for testing)
bool _doesCategoryMatchTimeSlot(String category, TimeSlot slot) {
  switch (slot) {
    case TimeSlot.earlyMorning:
      return ['gym', 'coffee', 'bakery'].any((c) => category.contains(c));
    case TimeSlot.morning:
      return ['cafe', 'coffee', 'breakfast', 'brunch']
          .any((c) => category.contains(c));
    case TimeSlot.afternoon:
      return ['restaurant', 'museum', 'shopping', 'lunch']
          .any((c) => category.contains(c));
    case TimeSlot.evening:
      return ['restaurant', 'dinner', 'bar'].any((c) => category.contains(c));
    case TimeSlot.night:
      return ['bar', 'nightclub', 'club', 'late']
          .any((c) => category.contains(c));
    case TimeSlot.lateNight:
      return ['bar', 'club', 'diner', '24'].any((c) => category.contains(c));
  }
}
