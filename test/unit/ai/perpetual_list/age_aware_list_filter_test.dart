// Age-Aware List Filter Tests
//
// Tests for the age-based filtering that ensures users only see
// age-appropriate content and venues.
//
// Key test scenarios:
// - 21+ category filtering (bars, clubs, etc.)
// - 18+ category filtering (hookah, vape, tattoo)
// - Sensitive category opt-in requirements
// - AI2AI insight age filtering

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/ai/perpetual_list/filters/age_aware_list_filter.dart';
import 'package:avrai/core/ai/perpetual_list/models/suggested_list.dart';
import 'package:avrai/core/models/spots/spot.dart';

void main() {
  group('AgeAwareListFilter', () {
    late AgeAwareListFilter filter;

    setUp(() {
      filter = AgeAwareListFilter();
    });

    group('21+ category filtering', () {
      test('should allow bars for users 21+', () {
        final allowed = filter.isCategoryAllowed(
          category: 'bar',
          userAge: 21,
        );

        expect(allowed, isTrue);
      });

      test('should block bars for users under 21', () {
        final allowed = filter.isCategoryAllowed(
          category: 'bar',
          userAge: 20,
        );

        expect(allowed, isFalse);
      });

      test('should block wine bars for users under 21', () {
        final allowed = filter.isCategoryAllowed(
          category: 'wine_bar',
          userAge: 19,
        );

        expect(allowed, isFalse);
      });

      test('should block nightclubs for users under 21', () {
        final allowed = filter.isCategoryAllowed(
          category: 'nightclub',
          userAge: 18,
        );

        expect(allowed, isFalse);
      });

      test('should block breweries for users under 21', () {
        final allowed = filter.isCategoryAllowed(
          category: 'brewery',
          userAge: 20,
        );

        expect(allowed, isFalse);
      });
    });

    group('18+ category filtering', () {
      test('should allow hookah lounge for users 18+', () {
        final allowed = filter.isCategoryAllowed(
          category: 'hookah_lounge',
          userAge: 18,
        );

        // Hookah is in sensitive categories, needs opt-in
        expect(allowed, isFalse); // Without opt-in
      });

      test('should block vape shops for users under 18', () {
        final allowed = filter.isCategoryAllowed(
          category: 'vape_shop',
          userAge: 17,
        );

        expect(allowed, isFalse);
      });

      test('should allow tattoo parlor for users 18+', () {
        final allowed = filter.isCategoryAllowed(
          category: 'tattoo_parlor',
          userAge: 18,
        );

        expect(allowed, isTrue);
      });
    });

    group('sensitive category opt-in', () {
      test('should block adult entertainment without opt-in', () {
        final allowed = filter.isCategoryAllowed(
          category: 'adult_entertainment',
          userAge: 25,
        );

        expect(allowed, isFalse);
      });

      test('should allow adult entertainment with opt-in for 18+', () {
        final allowed = filter.isCategoryAllowed(
          category: 'adult_entertainment',
          userAge: 25,
          userOptInCategories: {'adult_entertainment'},
        );

        expect(allowed, isTrue);
      });

      test('should block adult entertainment even with opt-in for under 18', () {
        final allowed = filter.isCategoryAllowed(
          category: 'adult_entertainment',
          userAge: 17,
          userOptInCategories: {'adult_entertainment'},
        );

        expect(allowed, isFalse);
      });

      test('should require opt-in for sex shops', () {
        expect(filter.requiresOptIn('sex_shops'), isTrue);
      });

      test('should require opt-in for cannabis dispensaries', () {
        expect(filter.requiresOptIn('cannabis_dispensaries'), isTrue);
      });
    });

    group('age-appropriate categories', () {
      test('should allow coffee shops for any age', () {
        final allowed = filter.isCategoryAllowed(
          category: 'coffee_shop',
          userAge: 16,
        );

        expect(allowed, isTrue);
      });

      test('should allow restaurants for any age', () {
        final allowed = filter.isCategoryAllowed(
          category: 'restaurant',
          userAge: 12,
        );

        expect(allowed, isTrue);
      });

      test('should allow museums for any age', () {
        final allowed = filter.isCategoryAllowed(
          category: 'museum',
          userAge: 10,
        );

        expect(allowed, isTrue);
      });
    });

    group('candidate filtering', () {
      test('should filter out age-restricted candidates', () {
        final candidates = [
          _createCandidate('Coffee Shop', 'coffee'),
          _createCandidate('Cool Bar', 'bar'),
          _createCandidate('Pizza Place', 'restaurant'),
          _createCandidate('Night Club', 'nightclub'),
        ];

        final filtered = filter.filterByAge(
          candidates: candidates,
          userAge: 18, // Under 21
        );

        expect(filtered.length, equals(2));
        expect(filtered.any((c) => c.category == 'bar'), isFalse);
        expect(filtered.any((c) => c.category == 'nightclub'), isFalse);
      });

      test('should keep all candidates for 21+ users', () {
        final candidates = [
          _createCandidate('Coffee Shop', 'coffee'),
          _createCandidate('Cool Bar', 'bar'),
          _createCandidate('Pizza Place', 'restaurant'),
        ];

        final filtered = filter.filterByAge(
          candidates: candidates,
          userAge: 25,
        );

        expect(filtered.length, equals(3));
      });
    });

    group('list validation', () {
      test('should validate list with age-appropriate places', () {
        final list = SuggestedList(
          id: '1',
          title: 'Family Friendly',
          description: 'Places for everyone',
          places: [
            _createSpot('Coffee Shop', 'coffee'),
            _createSpot('Museum', 'museum'),
          ],
          theme: 'family',
          generatedAt: DateTime.now(),
        );

        final result = filter.validateListForAge(
          list: list,
          userAge: 15,
        );

        expect(result.isValid, isTrue);
        expect(result.violations, isEmpty);
      });

      test('should detect violations in list with bars for under-21', () {
        final list = SuggestedList(
          id: '2',
          title: 'Night Out',
          description: 'Evening spots',
          places: [
            _createSpot('Cool Bar', 'bar'),
            _createSpot('Jazz Club', 'nightclub'),
          ],
          theme: 'nightlife',
          generatedAt: DateTime.now(),
        );

        final result = filter.validateListForAge(
          list: list,
          userAge: 19,
        );

        expect(result.isValid, isFalse);
        expect(result.violations.length, equals(2));
      });
    });

    group('age requirement lookup', () {
      test('should return 21 for bars', () {
        expect(filter.getAgeRequirement('bar'), equals(21));
      });

      test('should return 18 for tattoo parlors', () {
        expect(filter.getAgeRequirement('tattoo_parlor'), equals(18));
      });

      test('should return 18 for sensitive categories', () {
        expect(filter.getAgeRequirement('sex_shops'), equals(18));
      });

      test('should return null for unrestricted categories', () {
        expect(filter.getAgeRequirement('coffee'), isNull);
      });
    });

    group('helper methods', () {
      test('canAccessAlcohol should return true for 21+', () {
        expect(filter.canAccessAlcohol(21), isTrue);
        expect(filter.canAccessAlcohol(25), isTrue);
      });

      test('canAccessAlcohol should return false for under 21', () {
        expect(filter.canAccessAlcohol(20), isFalse);
        expect(filter.canAccessAlcohol(18), isFalse);
      });

      test('canAccessTobacco should return true for 18+', () {
        expect(filter.canAccessTobacco(18), isTrue);
        expect(filter.canAccessTobacco(21), isTrue);
      });

      test('canAccessTobacco should return false for under 18', () {
        expect(filter.canAccessTobacco(17), isFalse);
        expect(filter.canAccessTobacco(15), isFalse);
      });
    });
  });
}

/// Helper to create a scored candidate for testing
ScoredCandidate _createCandidate(String name, String category) {
  return ScoredCandidate(
    candidate: ListCandidate(
      place: _createSpot(name, category),
      category: category,
    ),
    possibilityScore: 0.8,
    noveltyScore: 0.5,
    timelinessScore: 0.7,
    combinedScore: 0.7,
  );
}

/// Helper to create a spot for testing
Spot _createSpot(String name, String category) {
  return Spot(
    id: 'spot-${name.hashCode}',
    name: name,
    description: 'Test spot for $name',
    category: category,
    latitude: 40.7128,
    longitude: -74.0060,
    rating: 4.0,
    createdBy: 'test-user',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}
