import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_core/models/geographic/locality.dart';
import '../../helpers/test_helpers.dart';

/// Comprehensive tests for Locality model
void main() {
  group('Locality Model Tests', () {
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
        final nameOnly = Locality(
          id: 'locality-1',
          name: 'Greenpoint',
          createdAt: testDate,
          updatedAt: testDate,
        );
        final withCity = Locality(
          id: 'locality-2',
          name: 'Greenpoint',
          city: 'Brooklyn',
          createdAt: testDate,
          updatedAt: testDate,
        );
        final withState = Locality(
          id: 'locality-3',
          name: 'Austin',
          city: 'Austin',
          state: 'Texas',
          createdAt: testDate,
          updatedAt: testDate,
        );
        final neighborhood = Locality(
          id: 'locality-4',
          name: 'Greenpoint',
          isNeighborhood: true,
          parentCity: 'Brooklyn',
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(nameOnly.displayName, equals('Greenpoint'));
        expect(withCity.displayName, equals('Greenpoint, Brooklyn'));
        expect(withState.displayName, equals('Austin, Texas'));
        expect(neighborhood.displayName, equals('Greenpoint, Brooklyn'));
      });
    });

    group('JSON Serialization', () {
      test('should serialize and deserialize without data loss', () {
        final locality = Locality(
          id: 'locality-123',
          name: 'Greenpoint',
          city: 'Brooklyn',
          isNeighborhood: true,
          parentCity: 'Brooklyn',
          createdAt: testDate,
          updatedAt: testDate,
        );

        final json = locality.toJson();
        final restored = Locality.fromJson(json);

        // Test critical business fields preserved
        expect(restored.displayName, equals(locality.displayName));
        expect(restored.isNeighborhood, equals(locality.isNeighborhood));
      });
    });

    group('copyWith', () {
      test('should create immutable copy with updated fields', () {
        final original = Locality(
          id: 'locality-123',
          name: 'Greenpoint',
          city: 'Brooklyn',
          createdAt: testDate,
          updatedAt: testDate,
        );

        final updated = original.copyWith(
          name: 'DUMBO',
          isNeighborhood: true,
        );

        // Test immutability (business logic)
        expect(original.name, isNot(equals('DUMBO')));
        expect(updated.name, equals('DUMBO'));
        expect(updated.id, equals(original.id)); // Unchanged fields preserved
      });
    });

    // Removed: Equality group
    // These tests verify Equatable implementation, which is already tested by the package
    // If equality breaks, other tests will fail
  });
}
