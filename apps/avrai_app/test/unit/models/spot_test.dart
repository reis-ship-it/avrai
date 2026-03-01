import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_core/models/spots/spot.dart';
import '../../fixtures/model_factories.dart';
import '../../helpers/test_helpers.dart';

/// Comprehensive tests for Spot model
/// Tests location validation, geospatial logic, and category constraints
void main() {
  group('Spot Model Tests', () {
    // ignore: unused_local_variable
    // ignore: unused_local_variable - May be used in callback or assertion
    late Spot testSpot;
    late DateTime testDate;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      testDate = TestHelpers.createTestDateTime();
      testSpot = ModelFactories.createTestSpot();
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    // Removed: Constructor and Properties group
    // These tests only verified Dart constructor behavior, not business logic

    group('Location Validation and Geospatial Logic', () {
      test('should accept valid coordinate ranges and edge cases', () {
        // Test various valid coordinate scenarios
        // ignore: unused_local_variable
        final validNorth = ModelFactories.createSpotAtLocation(89.9, 0);
        final validSouth = ModelFactories.createSpotAtLocation(-89.9, 0);
        // ignore: unused_local_variable
        // ignore: unused_local_variable - May be used in callback or assertion
        final validEast = ModelFactories.createSpotAtLocation(0, 179.9);
        // ignore: unused_local_variable
        // ignore: unused_local_variable - May be used in callback or assertion
        final validWest = ModelFactories.createSpotAtLocation(0, -179.9);
        final edgeCase = ModelFactories.createSpotAtLocation(90.0, 180.0);
        final precise =
            ModelFactories.createSpotAtLocation(40.748817, -73.985428);

        // Assert coordinates are stored correctly (business logic)
        expect(validNorth.latitude, greaterThanOrEqualTo(-90.0));
        expect(validNorth.latitude, lessThanOrEqualTo(90.0));
        expect(validSouth.latitude, greaterThanOrEqualTo(-90.0));
        expect(validSouth.latitude, lessThanOrEqualTo(90.0));
        expect(edgeCase.latitude, equals(90.0));
        expect(precise.latitude, closeTo(40.748817, 0.000001));
      });
    });

    group('Category Validation and Constraints', () {
      test('should preserve category values including case and empty strings',
          () {
        final restaurant =
            ModelFactories.createTestSpot(category: 'Restaurant');
        final empty = ModelFactories.createTestSpot(category: '');
        final upperCase = ModelFactories.createTestSpot(category: 'RESTAURANT');

        // Test that category is preserved as-is (business logic: no normalization)
        expect(restaurant.category, equals('Restaurant'));
        expect(empty.category, isEmpty);
        expect(upperCase.category, equals('RESTAURANT'));
      });
    });

    group('Rating Validation', () {
      test('should accept any numeric rating value without bounds enforcement',
          () {
        // Test that model doesn't enforce rating bounds (business logic)
        final minRating = ModelFactories.createTestSpot().copyWith(rating: 0.0);
        final maxRating = ModelFactories.createTestSpot().copyWith(rating: 5.0);
        final negativeRating =
            ModelFactories.createTestSpot().copyWith(rating: -1.0);
        final highRating =
            ModelFactories.createTestSpot().copyWith(rating: 10.0);

        expect(minRating.rating, equals(0.0));
        expect(maxRating.rating, equals(5.0));
        expect(negativeRating.rating, equals(-1.0)); // No bounds enforcement
        expect(highRating.rating, equals(10.0)); // No bounds enforcement
      });
    });

    group('Tags System', () {
      test('should preserve tag order and allow duplicates', () {
        // Test business logic: tags preserve order and duplicates
        final orderedTags = ['first', 'second', 'third'];
        final duplicateTags = ['food', 'italian', 'food'];
        final emptyTags = <String>[];
        final singleTag = ['vegetarian'];

        final spotOrdered = ModelFactories.createTestSpot(tags: orderedTags);
        final spotDuplicates =
            ModelFactories.createTestSpot(tags: duplicateTags);
        final spotEmpty = ModelFactories.createTestSpot(tags: emptyTags);
        final spotSingle = ModelFactories.createTestSpot(tags: singleTag);

        expect(spotOrdered.tags, equals(orderedTags),
            reason: 'Order should be preserved');
        expect(spotDuplicates.tags, equals(duplicateTags),
            reason: 'Duplicates should be preserved');
        expect(spotEmpty.tags, isEmpty);
        expect(spotSingle.tags, equals(singleTag));
      });
    });

    // Removed: Relationship with Lists and Users group
    // These tests only verified property assignment, not relationship behavior

    group('Address and Location Details', () {
      test('should handle address variations including null and empty', () {
        final fullAddress = ModelFactories.createTestSpot()
            .copyWith(address: '123 Main Street, New York, NY 10001, USA');
        final partialAddress = ModelFactories.createTestSpot()
            .copyWith(address: 'Central Park, NYC');
        final nullAddress =
            ModelFactories.createTestSpot().copyWith(address: null);
        final emptyAddress =
            ModelFactories.createTestSpot().copyWith(address: '');

        expect(fullAddress.address,
            equals('123 Main Street, New York, NY 10001, USA'));
        expect(partialAddress.address, equals('Central Park, NYC'));
        expect(nullAddress.address, isNull);
        expect(emptyAddress.address, isEmpty);
      });
    });

    group('JSON Serialization Testing', () {
      test('should serialize and deserialize without data loss (round-trip)',
          () {
        final originalSpot = ModelFactories.createTestSpot(
          name: 'Test Spot',
          category: 'Restaurant',
          tags: ['italian', 'romantic'],
        ).copyWith(address: '123 Main St');

        // Serialize and deserialize
        final json = originalSpot.toJson();
        final reconstructed = Spot.fromJson(json);

        // Test business logic: round-trip preserves all critical data
        // (Spot doesn't implement Equatable, so we verify key fields)
        expect(reconstructed.id, equals(originalSpot.id));
        expect(reconstructed.name, equals(originalSpot.name));
        expect(reconstructed.latitude, equals(originalSpot.latitude));
        expect(reconstructed.longitude, equals(originalSpot.longitude));
        expect(reconstructed.category, equals(originalSpot.category));
        expect(reconstructed.tags, equals(originalSpot.tags));
        expect(reconstructed.address, equals(originalSpot.address));
        // Verify JSON structure is correct for storage/transmission
        expect(json, isA<Map<String, dynamic>>());
        expect(json.containsKey('id'), isTrue);
        expect(json.containsKey('latitude'), isTrue);
        expect(json.containsKey('longitude'), isTrue);
      });

      test('should handle missing and null fields with sensible defaults', () {
        final minimalJson = {
          'id': '',
          'name': '',
          'description': '',
          'latitude': 0.0,
          'longitude': 0.0,
          'category': '',
          'rating': 0.0,
          'createdBy': '',
          'createdAt': testDate.toIso8601String(),
          'updatedAt': testDate.toIso8601String(),
        };
        final jsonWithNulls = {
          'id': null,
          'name': null,
          'latitude': null,
          'longitude': null,
          'createdAt': null,
          'updatedAt': null,
        };

        final spotMinimal = Spot.fromJson(minimalJson);
        final spotNulls = Spot.fromJson(jsonWithNulls);

        // Test that defaults are applied (business logic)
        expect(spotMinimal.address, isNull);
        expect(spotMinimal.tags, isEmpty);
        expect(spotNulls.id, equals(''));
        expect(spotNulls.latitude, equals(0.0));
      });
    });

    group('CopyWith Method Testing', () {
      test('should create immutable copy with updated fields', () {
        final originalSpot = ModelFactories.createTestSpot();
        final copiedSpot = originalSpot.copyWith(
          name: 'New Name',
          rating: 5.0,
        );

        // Test immutability (business logic)
        expect(originalSpot.name, isNot(equals('New Name')));
        expect(copiedSpot.name, equals('New Name'));
        expect(copiedSpot.id,
            equals(originalSpot.id)); // Unchanged fields preserved
        expect(copiedSpot.rating, equals(5.0)); // Changed field updated
      });
    });

    group('Edge Cases and Error Handling', () {
      test(
          'should handle extreme coordinate values and preserve them in JSON round-trip',
          () {
        // Test business logic: extreme values are preserved through serialization
        final spot = ModelFactories.createSpotAtLocation(
          double.maxFinite,
          double.maxFinite,
        );

        // Test that extreme values are preserved in JSON round-trip
        final json = spot.toJson();
        final reconstructed = Spot.fromJson(json);

        expect(reconstructed.latitude, equals(double.maxFinite));
        expect(reconstructed.longitude, equals(double.maxFinite));
        // Verify JSON can handle extreme values
        expect(json['latitude'], equals(double.maxFinite));
        expect(json['longitude'], equals(double.maxFinite));
      });

      test('should handle very long strings', () {
        final longString = 'A' * 1000;
        final spot = ModelFactories.createTestSpot(
          name: longString,
        ).copyWith(
          description: longString,
          address: longString,
        );

        expect(spot.name.length, equals(1000));
        expect(spot.description.length, equals(1000));
        expect(spot.address?.length, equals(1000));
      });

      test('should handle many tags', () {
        final manyTags = List.generate(100, (index) => 'tag$index');
        final spot = ModelFactories.createTestSpot(tags: manyTags);

        expect(spot.tags.length, equals(100));
        expect(spot.tags.first, equals('tag0'));
        expect(spot.tags.last, equals('tag99'));
      });

      test('should handle special characters in strings', () {
        final spot = ModelFactories.createTestSpot(
          name: 'Café Münchën 北京烤鸭 🍜',
        ).copyWith(
          description: r'Special chars: @#$%^&*()_+-=[]{}|;:,.<>?',
          address: '123 Main St. ñ é ü ß',
        );

        expect(spot.name, equals('Café Münchën 北京烤鸭 🍜'));
        expect(spot.description, contains('Special chars'));
        expect(spot.address, contains('123 Main St'));
      });
    });

    group('Privacy and Security Considerations', () {
      test('should not expose sensitive location data unintentionally', () {
        final spot = ModelFactories.createTestSpot();
        final json = spot.toJson();

        // Ensure coordinates are explicitly included (not hidden)
        expect(json.containsKey('latitude'), isTrue);
        expect(json.containsKey('longitude'), isTrue);

        // Ensure no unexpected fields are exposed
        expect(json.containsKey('internalId'), isFalse);
        expect(json.containsKey('privateNotes'), isFalse);
      });

      test('should maintain creator attribution', () {
        final spot = ModelFactories.createTestSpot(createdBy: 'user-123');
        final json = spot.toJson();
        final reconstructed = Spot.fromJson(json);

        expect(reconstructed.createdBy, equals('user-123'));
      });
    });
  });
}
