import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_core/models/geographic/geographic_expansion.dart';
import '../../helpers/test_helpers.dart';

/// Comprehensive tests for GeographicExpansion Model
/// Tests expansion tracking, coverage calculation, expansion history
///
/// **Philosophy Alignment:**
/// - Clubs/communities can expand naturally (doors open through growth)
/// - 75% coverage rule (fair expertise gain thresholds)
/// - Geographic expansion enabled (locality → universe)
void main() {
  group('GeographicExpansion Model Tests', () {
    late DateTime testDate;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      testDate = TestHelpers.createTestDateTime();
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    // Removed: Model Creation group
    // These tests only verified Dart constructor behavior, not business logic

    group('Expansion Tracking', () {
      test('should correctly identify expansion state and thresholds', () {
        // Test business logic: expansion detection
        final expanded = GeographicExpansion(
          id: 'expansion-1',
          clubId: 'club-1',
          isClub: true,
          originalLocality: 'Mission District, San Francisco',
          expandedLocalities: const ['Williamsburg, Brooklyn'],
          createdAt: testDate,
          updatedAt: testDate,
        );
        final notExpanded = GeographicExpansion(
          id: 'expansion-2',
          clubId: 'club-1',
          isClub: true,
          originalLocality: 'Mission District, San Francisco',
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(expanded.hasReachedLocalityThreshold(), isTrue);
        expect(notExpanded.hasReachedLocalityThreshold(), isFalse);
      });
    });

    group('Coverage Calculation', () {
      test(
          'should correctly check 75% threshold for different geographic levels',
          () {
        // Test business logic: threshold checking (75% rule)
        final expansion = GeographicExpansion(
          id: 'expansion-1',
          clubId: 'club-1',
          isClub: true,
          originalLocality: 'Mission District, San Francisco',
          cityCoverage: const {
            'Brooklyn': 0.8, // Above 75%
            'Queens': 0.6, // Below 75%
          },
          stateCoverage: const {
            'New York': 0.8, // Above 75%
            'California': 0.6, // Below 75%
          },
          nationCoverage: const {
            'United States': 0.8, // Above 75%
          },
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(expansion.hasReachedCityThreshold('Brooklyn'), isTrue);
        expect(expansion.hasReachedCityThreshold('Queens'), isFalse);
        expect(expansion.hasReachedStateThreshold('New York'), isTrue);
        expect(expansion.hasReachedStateThreshold('California'), isFalse);
        expect(expansion.hasReachedNationThreshold('United States'), isTrue);
      });
    });

    // Removed: Coverage Methods group
    // These tests only verified map/list storage, not business logic

    group('Expansion History', () {
      test('should track expansion history and timestamps correctly', () {
        // Test business logic: history tracking
        final firstExpansion = testDate.subtract(const Duration(days: 30));
        final lastExpansion = testDate;

        final withHistory = GeographicExpansion(
          id: 'expansion-1',
          clubId: 'club-1',
          isClub: true,
          originalLocality: 'Mission District, San Francisco',
          expansionHistory: [
            ExpansionEvent(
              timestamp: firstExpansion,
              location: 'Williamsburg, Brooklyn',
              geographicLevel: 'locality',
              expansionMethod: 'event_hosting',
              eventId: 'event-1',
              coveragePercentage: 0.5,
            ),
          ],
          firstExpansionAt: firstExpansion,
          lastExpansionAt: lastExpansion,
          createdAt: testDate,
          updatedAt: testDate,
        );
        final withoutHistory = GeographicExpansion(
          id: 'expansion-2',
          clubId: 'club-1',
          isClub: true,
          originalLocality: 'Mission District, San Francisco',
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(withHistory.expansionHistory, hasLength(1));
        expect(withHistory.firstExpansionAt, isNotNull);
        expect(withoutHistory.firstExpansionAt, isNull);
      });
    });

    group('JSON Serialization', () {
      test(
          'should serialize and deserialize with nested coverage data correctly',
          () {
        final expansion = GeographicExpansion(
          id: 'expansion-1',
          clubId: 'club-1',
          isClub: true,
          originalLocality: 'Mission District, San Francisco',
          expandedLocalities: const ['Williamsburg, Brooklyn'],
          cityCoverage: const {
            'Brooklyn': 0.8,
          },
          createdAt: testDate,
          updatedAt: testDate,
        );

        final json = expansion.toJson();
        final restored = GeographicExpansion.fromJson(json);

        // Test nested structures preserved (business logic)
        expect(restored.expandedLocalities, contains('Williamsburg, Brooklyn'));
        expect(restored.cityCoverage['Brooklyn'], equals(0.8));
        expect(restored.hasReachedCityThreshold('Brooklyn'), isTrue);
      });
    });

    group('copyWith', () {
      test('should create immutable copy with updated fields', () {
        final original = GeographicExpansion(
          id: 'expansion-1',
          clubId: 'club-1',
          isClub: true,
          originalLocality: 'Mission District, San Francisco',
          createdAt: testDate,
          updatedAt: testDate,
        );

        final updated = original.copyWith(
          expandedLocalities: ['Williamsburg, Brooklyn'],
          cityCoverage: {'Brooklyn': 0.8},
        );

        // Test immutability (business logic)
        expect(original.expandedLocalities, isEmpty);
        expect(updated.expandedLocalities, contains('Williamsburg, Brooklyn'));
        expect(updated.id, equals(original.id)); // Unchanged fields preserved
      });
    });

    // Removed: Equatable Implementation group
    // These tests verify Equatable implementation, which is already tested by the package
    // If equality breaks, other tests will fail
  });
}
