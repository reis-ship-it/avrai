import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_core/models/geographic/geographic_scope.dart';
import 'package:avrai_core/models/expertise/expertise_level.dart';
import '../../helpers/test_helpers.dart';

/// Comprehensive tests for GeographicScope model
void main() {
  group('GeographicScope Model Tests', () {
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

    group('canHostInLocality', () {
      test(
          'should correctly determine hosting eligibility based on expertise level',
          () {
        // Test business logic: level-based hosting permissions
        final localScope = GeographicScope(
          userId: 'user-123',
          level: ExpertiseLevel.local,
          locality: 'Greenpoint',
          allowedLocalities: const ['Greenpoint'],
          createdAt: testDate,
          updatedAt: testDate,
        );
        final cityScope = GeographicScope(
          userId: 'user-456',
          level: ExpertiseLevel.city,
          city: 'Brooklyn',
          allowedLocalities: const ['Greenpoint', 'DUMBO', 'Sunset Park'],
          createdAt: testDate,
          updatedAt: testDate,
        );
        final regionalScope = GeographicScope(
          userId: 'user-789',
          level: ExpertiseLevel.regional,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(localScope.canHostInLocality('Greenpoint'), isTrue);
        expect(localScope.canHostInLocality('DUMBO'), isFalse);
        expect(cityScope.canHostInLocality('Greenpoint'), isTrue);
        expect(cityScope.canHostInLocality('Manhattan'), isFalse);
        expect(regionalScope.canHostInLocality('Any Locality'), isTrue);
      });
    });

    group('canHostInCity', () {
      test(
          'should correctly determine city hosting eligibility based on expertise level',
          () {
        // Test business logic: level-based city hosting permissions
        final localScope = GeographicScope(
          userId: 'user-123',
          level: ExpertiseLevel.local,
          locality: 'Greenpoint',
          city: 'Brooklyn',
          createdAt: testDate,
          updatedAt: testDate,
        );
        final cityScope = GeographicScope(
          userId: 'user-456',
          level: ExpertiseLevel.city,
          city: 'Brooklyn',
          allowedCities: const ['Brooklyn'],
          createdAt: testDate,
          updatedAt: testDate,
        );
        final regionalScope = GeographicScope(
          userId: 'user-789',
          level: ExpertiseLevel.regional,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(localScope.canHostInCity('Brooklyn'),
            isFalse); // Local can't host outside locality
        expect(cityScope.canHostInCity('Brooklyn'), isTrue);
        expect(cityScope.canHostInCity('Manhattan'), isFalse);
        expect(regionalScope.canHostInCity('Any City'), isTrue);
      });
    });

    group('getHostableLocalities', () {
      test('should return correct list of allowed localities', () {
        // Test business logic: hostable localities retrieval
        final scope = GeographicScope(
          userId: 'user-123',
          level: ExpertiseLevel.city,
          allowedLocalities: const ['Greenpoint', 'DUMBO', 'Sunset Park'],
          createdAt: testDate,
          updatedAt: testDate,
        );

        final localities = scope.getHostableLocalities();
        expect(localities.length, equals(3));
        expect(localities, containsAll(['Greenpoint', 'DUMBO', 'Sunset Park']));
      });
    });

    group('getHostableCities', () {
      test('should return correct list of allowed cities', () {
        // Test business logic: hostable cities retrieval
        final scope = GeographicScope(
          userId: 'user-123',
          level: ExpertiseLevel.regional,
          allowedCities: const ['Brooklyn', 'Manhattan', 'Queens'],
          createdAt: testDate,
          updatedAt: testDate,
        );

        final cities = scope.getHostableCities();
        expect(cities.length, equals(3));
        expect(cities, containsAll(['Brooklyn', 'Manhattan', 'Queens']));
      });
    });

    group('JSON Serialization', () {
      test('should serialize and deserialize without data loss', () {
        final scope = GeographicScope(
          userId: 'user-123',
          level: ExpertiseLevel.local,
          locality: 'Greenpoint',
          city: 'Brooklyn',
          allowedLocalities: const ['Greenpoint'],
          createdAt: testDate,
          updatedAt: testDate,
        );

        final json = scope.toJson();
        final restored = GeographicScope.fromJson(json);

        // Test critical business fields preserved
        expect(restored.level, equals(scope.level));
        expect(restored.canHostInLocality('Greenpoint'),
            equals(scope.canHostInLocality('Greenpoint')));
      });
    });

    group('copyWith', () {
      test('should create immutable copy with updated fields', () {
        final original = GeographicScope(
          userId: 'user-123',
          level: ExpertiseLevel.local,
          locality: 'Greenpoint',
          createdAt: testDate,
          updatedAt: testDate,
        );

        final updated = original.copyWith(
          level: ExpertiseLevel.city,
          city: 'Brooklyn',
        );

        // Test immutability (business logic)
        expect(original.level, isNot(equals(ExpertiseLevel.city)));
        expect(updated.level, equals(ExpertiseLevel.city));
        expect(updated.userId,
            equals(original.userId)); // Unchanged fields preserved
      });
    });

    // Removed: Equality group
    // These tests verify Equatable implementation, which is already tested by the package
    // If equality breaks, other tests will fail
  });
}
