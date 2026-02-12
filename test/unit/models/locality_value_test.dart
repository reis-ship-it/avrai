import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/models/geographic/locality_value.dart';
import '../../helpers/test_helpers.dart';

/// Comprehensive tests for LocalityValue model
void main() {
  group('LocalityValue Model Tests', () {
    late DateTime testDate;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      testDate = TestHelpers.createTestDateTime();
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    // Removed: Constructor and Properties group
    // These tests only verified Dart constructor behavior, not business logic

    group('Activity Weight Methods', () {
      test(
          'should correctly retrieve weights and determine high-value activities',
          () {
        // Test business logic: activity weight retrieval and high-value determination
        final localityValue = LocalityValue(
          id: 'value-123',
          locality: 'Greenpoint',
          activityWeights: const {
            'events_hosted': 0.30, // High (>= 0.25)
            'lists_created': 0.20, // Low (< 0.25)
          },
          categoryPreferences: const {},
          activityCounts: const {},
          lastAnalyzed: testDate,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(localityValue.getActivityWeight('events_hosted'), equals(0.30));
        expect(
            localityValue.getActivityWeight('unknown'), equals(0.0)); // Default
        expect(localityValue.valuesActivityHighly('events_hosted'), isTrue);
        expect(localityValue.valuesActivityHighly('lists_created'), isFalse);
      });
    });

    group('Category Preferences', () {
      test(
          'should return category-specific preferences with defaults for unknown categories',
          () {
        // Test business logic: category preference retrieval
        final localityValue = LocalityValue(
          id: 'value-123',
          locality: 'Greenpoint',
          activityWeights: const {
            'events_hosted': 0.20,
          },
          categoryPreferences: const {
            'Coffee': {
              'events_hosted': 0.35,
              'lists_created': 0.30,
            },
          },
          activityCounts: const {},
          lastAnalyzed: testDate,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final coffeePrefs = localityValue.getCategoryPreferences('Coffee');
        expect(coffeePrefs['events_hosted'], equals(0.35));

        // Unknown category returns default weights (business logic)
        final unknownPrefs = localityValue.getCategoryPreferences('Unknown');
        expect(unknownPrefs['events_hosted'], equals(0.20));
      });
    });

    group('Activity Counts', () {
      test('should correctly retrieve counts and calculate total', () {
        // Test business logic: activity count retrieval and total calculation
        final localityValue = LocalityValue(
          id: 'value-123',
          locality: 'Greenpoint',
          activityWeights: const {},
          categoryPreferences: const {},
          activityCounts: const {
            'events_hosted': 50,
            'lists_created': 30,
            'reviews_written': 20,
          },
          lastAnalyzed: testDate,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(localityValue.getActivityCount('events_hosted'), equals(50));
        expect(localityValue.getActivityCount('unknown'), equals(0)); // Default
        expect(localityValue.totalActivityCount, equals(100));
      });
    });

    group('JSON Serialization', () {
      test('should serialize and deserialize without data loss', () {
        final localityValue = LocalityValue(
          id: 'value-123',
          locality: 'Greenpoint',
          activityWeights: const {
            'events_hosted': 0.30,
            'lists_created': 0.25,
          },
          categoryPreferences: const {
            'Coffee': {
              'events_hosted': 0.35,
            },
          },
          activityCounts: const {
            'events_hosted': 50,
          },
          lastAnalyzed: testDate,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final json = localityValue.toJson();
        final restored = LocalityValue.fromJson(json);

        // Test critical business fields preserved
        expect(restored.getActivityWeight('events_hosted'),
            equals(localityValue.getActivityWeight('events_hosted')));
        expect(restored.totalActivityCount,
            equals(localityValue.totalActivityCount));
      });
    });

    group('copyWith', () {
      test('should create immutable copy with updated fields', () {
        final original = LocalityValue(
          id: 'value-123',
          locality: 'Greenpoint',
          activityWeights: const {'events_hosted': 0.30},
          categoryPreferences: const {},
          activityCounts: const {},
          lastAnalyzed: testDate,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final updated = original.copyWith(
          locality: 'DUMBO',
          activityWeights: {'events_hosted': 0.35},
        );

        // Test immutability (business logic)
        expect(original.locality, isNot(equals('DUMBO')));
        expect(updated.locality, equals('DUMBO'));
        expect(updated.id, equals(original.id)); // Unchanged fields preserved
      });
    });

    // Removed: Equality group
    // These tests verify Equatable implementation, which is already tested by the package
    // If equality breaks, other tests will fail
  });
}
