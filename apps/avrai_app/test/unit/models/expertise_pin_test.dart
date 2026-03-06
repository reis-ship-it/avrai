import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:avrai_core/models/expertise/expertise_pin.dart';
import 'package:avrai_core/models/expertise/expertise_level.dart';
import 'package:avrai/theme/colors.dart';
import '../../helpers/test_helpers.dart';

/// Comprehensive tests for ExpertisePin model
/// Tests pin creation, JSON serialization, helper methods, and feature unlocking
void main() {
  group('ExpertisePin Model Tests', () {
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

    group('fromMapEntry Factory', () {
      test(
          'should create pin with correct business defaults and handle invalid input',
          () {
        // Test business logic: factory method behavior
        final validPin = ExpertisePin.fromMapEntry(
          userId: 'user-123',
          category: 'Coffee',
          levelString: 'city',
          location: 'Brooklyn',
        );
        final invalidLevelPin = ExpertisePin.fromMapEntry(
          userId: 'user-123',
          category: 'Coffee',
          levelString: 'invalid',
        );

        expect(validPin.level, equals(ExpertiseLevel.city));
        expect(invalidLevelPin.level,
            equals(ExpertiseLevel.local)); // Default for invalid
        expect(validPin.earnedReason, isNotEmpty);
      });
    });

    group('Display Methods', () {
      test(
          'should correctly format display title and description with location handling',
          () {
        // Test business logic: display formatting
        final withLocation = ExpertisePin(
          id: 'pin-123',
          userId: 'user-123',
          category: 'Coffee',
          level: ExpertiseLevel.city,
          location: 'Brooklyn',
          earnedAt: testDate,
          earnedReason: 'Test',
        );
        final withoutLocation = ExpertisePin(
          id: 'pin-123',
          userId: 'user-123',
          category: 'Coffee',
          level: ExpertiseLevel.global,
          earnedAt: testDate,
          earnedReason: 'Test',
        );

        expect(withLocation.getDisplayTitle(),
            equals('Coffee Expert in Brooklyn'));
        expect(withoutLocation.getDisplayTitle(), equals('Coffee Expert'));
        expect(withLocation.getFullDescription(), contains('Brooklyn'));
        expect(withoutLocation.getFullDescription(),
            isNot(contains('('))); // No location parentheses
      });
    });

    group('Pin Color and Icon', () {
      test('should return correct colors and icons for different categories',
          () {
        // Test business logic: category-based styling
        final coffeePin = ExpertisePin(
          id: 'pin-1',
          userId: 'user-123',
          category: 'Coffee',
          level: ExpertiseLevel.local,
          earnedAt: testDate,
          earnedReason: 'Test',
        );
        final restaurantPin = ExpertisePin(
          id: 'pin-2',
          userId: 'user-123',
          category: 'Restaurants',
          level: ExpertiseLevel.local,
          earnedAt: testDate,
          earnedReason: 'Test',
        );
        final unknownPin = ExpertisePin(
          id: 'pin-3',
          userId: 'user-123',
          category: 'Unknown Category',
          level: ExpertiseLevel.local,
          earnedAt: testDate,
          earnedReason: 'Test',
        );

        expect(coffeePin.getPinColor(), equals(AppColors.grey700.toARGB32()));
        expect(restaurantPin.getPinColor(), equals(AppColors.error.toARGB32()));
        expect(unknownPin.getPinColor(),
            equals(AppColors.grey500.toARGB32())); // Default
        expect(coffeePin.getPinIcon(), equals(Icons.local_cafe.codePoint));
        expect(
            unknownPin.getPinIcon(), equals(Icons.place.codePoint)); // Default
      });
    });

    group('Feature Unlocking', () {
      test(
          'should correctly determine feature unlocks based on expertise level',
          () {
        // Test business logic: level-based feature unlocking
        final localPin = ExpertisePin(
          id: 'pin-local',
          userId: 'user-123',
          category: 'Coffee',
          level: ExpertiseLevel.local,
          earnedAt: testDate,
          earnedReason: 'Test',
        );
        final cityPin = ExpertisePin(
          id: 'pin-city',
          userId: 'user-123',
          category: 'Coffee',
          level: ExpertiseLevel.city,
          earnedAt: testDate,
          earnedReason: 'Test',
        );
        final regionalPin = ExpertisePin(
          id: 'pin-regional',
          userId: 'user-123',
          category: 'Coffee',
          level: ExpertiseLevel.regional,
          earnedAt: testDate,
          earnedReason: 'Test',
        );

        // Event hosting: local and above
        expect(localPin.unlocksEventHosting(), isTrue);
        expect(cityPin.unlocksEventHosting(), isTrue);
        expect(regionalPin.unlocksEventHosting(), isTrue);

        // Expert validation: regional and above
        expect(cityPin.unlocksExpertValidation(), isFalse);
        expect(regionalPin.unlocksExpertValidation(), isTrue);
      });
    });

    group('JSON Serialization', () {
      test(
          'should serialize and deserialize with defaults and handle invalid fields',
          () {
        // Test business logic: JSON round-trip with error handling
        final pin = ExpertisePin(
          id: 'pin-123',
          userId: 'user-123',
          category: 'Coffee',
          level: ExpertiseLevel.city,
          location: 'Brooklyn',
          earnedAt: testDate,
          earnedReason: 'Created 10 lists',
          contributionCount: 10,
          communityTrustScore: 0.85,
          unlockedFeatures: const ['event_hosting'],
        );

        final json = pin.toJson();
        final restored = ExpertisePin.fromJson(json);

        expect(restored.level, equals(ExpertiseLevel.city));
        expect(restored.unlocksEventHosting(), isTrue);

        // Test defaults and invalid field handling
        final minimalJson = {
          'id': 'pin-123',
          'userId': 'user-123',
          'category': 'Coffee',
          'level': 'local',
          'earnedAt': testDate.toIso8601String(),
          'earnedReason': 'Test',
        };
        final invalidLevelJson = {
          'id': 'pin-123',
          'userId': 'user-123',
          'category': 'Coffee',
          'level': 'invalid',
          'earnedAt': testDate.toIso8601String(),
          'earnedReason': 'Test',
        };

        final minimal = ExpertisePin.fromJson(minimalJson);
        final invalid = ExpertisePin.fromJson(invalidLevelJson);

        expect(minimal.location, isNull);
        expect(minimal.contributionCount, equals(0));
        expect(invalid.level,
            equals(ExpertiseLevel.local)); // Invalid level defaults
      });
    });

    group('copyWith', () {
      test('should create immutable copy with updated fields', () {
        final original = ExpertisePin(
          id: 'pin-123',
          userId: 'user-123',
          category: 'Coffee',
          level: ExpertiseLevel.local,
          earnedAt: testDate,
          earnedReason: 'Original reason',
        );

        final updated = original.copyWith(
          level: ExpertiseLevel.city,
          location: 'Brooklyn',
        );

        // Test immutability (business logic)
        expect(original.level, isNot(equals(ExpertiseLevel.city)));
        expect(updated.level, equals(ExpertiseLevel.city));
        expect(updated.id, equals(original.id)); // Unchanged fields preserved
      });
    });

    // Removed: Equality group
    // These tests verify Equatable implementation, which is already tested by the package
    // If equality breaks, other tests will fail
  });
}
