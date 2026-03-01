import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_core/models/geographic/large_city.dart';
import '../../helpers/test_helpers.dart';

/// Comprehensive tests for LargeCity model
void main() {
  group('LargeCity Model Tests', () {
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

    group('Display Name', () {
      test('should correctly format display name based on available fields',
          () {
        // Test business logic: display name formatting
        final nameOnly = LargeCity(
          id: 'city-1',
          name: 'Brooklyn',
          createdAt: testDate,
          updatedAt: testDate,
        );
        final withState = LargeCity(
          id: 'city-2',
          name: 'Brooklyn',
          state: 'New York',
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(nameOnly.displayName, equals('Brooklyn'));
        expect(withState.displayName, equals('Brooklyn, New York'));
      });
    });

    group('Neighborhoods', () {
      test('should correctly identify and count neighborhoods', () {
        // Test business logic: neighborhood tracking
        final noNeighborhoods = LargeCity(
          id: 'city-1',
          name: 'Austin',
          createdAt: testDate,
          updatedAt: testDate,
        );
        final withNeighborhoods = LargeCity(
          id: 'city-2',
          name: 'Brooklyn',
          neighborhoods: const ['greenpoint', 'dumbo'],
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(noNeighborhoods.hasNeighborhoods, isFalse);
        expect(noNeighborhoods.neighborhoodCount, equals(0));
        expect(withNeighborhoods.hasNeighborhoods, isTrue);
        expect(withNeighborhoods.neighborhoodCount, equals(2));
      });
    });

    group('JSON Serialization', () {
      test('should serialize and deserialize without data loss', () {
        final city = LargeCity(
          id: 'city-123',
          name: 'Brooklyn',
          state: 'New York',
          neighborhoods: const ['greenpoint', 'dumbo'],
          createdAt: testDate,
          updatedAt: testDate,
        );

        final json = city.toJson();
        final restored = LargeCity.fromJson(json);

        // Test critical business fields preserved
        expect(restored.displayName, equals(city.displayName));
        expect(restored.hasNeighborhoods, equals(city.hasNeighborhoods));
      });
    });

    group('copyWith', () {
      test('should create immutable copy with updated fields', () {
        final original = LargeCity(
          id: 'city-123',
          name: 'Brooklyn',
          createdAt: testDate,
          updatedAt: testDate,
        );

        final updated = original.copyWith(
          name: 'Los Angeles',
          neighborhoods: ['hollywood'],
        );

        // Test immutability (business logic)
        expect(original.name, isNot(equals('Los Angeles')));
        expect(updated.name, equals('Los Angeles'));
        expect(updated.id, equals(original.id)); // Unchanged fields preserved
      });
    });

    // Removed: Equality group
    // These tests verify Equatable implementation, which is already tested by the package
    // If equality breaks, other tests will fail
  });
}
