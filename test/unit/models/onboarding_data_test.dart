/// SPOTS OnboardingData Model Tests
/// Date: December 15, 2025
/// Purpose: Test OnboardingData model functionality
/// 
/// Test Coverage:
/// - JSON Serialization: toJson and fromJson
/// - Validation: isValid property
/// - CopyWith: Creating modified copies
/// - AgentId Format: Privacy protection validation
/// - Edge Cases: Null values, empty collections, invalid data
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/models/user/onboarding_data.dart';

void main() {
  group('OnboardingData Model Tests', () {
    late DateTime testDate;
    const String testAgentId = 'agent_abc123def456ghi789jkl012mno345pqr678';

    setUp(() {
      testDate = DateTime.now();
    });

    // Removed: Constructor and Properties group
    // These tests only verified Dart constructor behavior, not business logic
    // If constructor breaks, compilation fails - no need to test language features

    group('JSON Serialization', () {
      test('should serialize and deserialize correctly (round-trip) with all fields, null values, and missing collections', () {
        // Test comprehensive round-trip with all fields
        final originalFull = OnboardingData(
          agentId: testAgentId,
          age: 28,
          birthday: DateTime(1995, 1, 1),
          homebase: 'San Francisco, CA',
          favoritePlaces: ['Golden Gate Park', 'Mission District'],
          preferences: {'Food & Drink': ['Coffee', 'Craft Beer']},
          baselineLists: ['My Favorites'],
          respectedFriends: ['friend1', 'friend2'],
          socialMediaConnected: {'google': true, 'instagram': false},
          completedAt: testDate,
        );

        final restoredFull = OnboardingData.fromJson(originalFull.toJson());
        
        // Test business logic: restored data is valid and equal
        expect(restoredFull, equals(originalFull));
        expect(restoredFull.isValid, isTrue);

        // Test round-trip with minimal fields (nulls and empty collections)
        final originalMinimal = OnboardingData(
          agentId: testAgentId,
          completedAt: testDate,
        );

        final restoredMinimal = OnboardingData.fromJson(originalMinimal.toJson());
        
        // Test business logic: restored minimal data is valid and usable
        expect(restoredMinimal, equals(originalMinimal));
        expect(restoredMinimal.isValid, isTrue);
        expect(restoredMinimal.favoritePlaces, isEmpty);
        expect(restoredMinimal.preferences, isEmpty);
      });
    });

    group('Validation', () {
      test('should validate agentId format, dates, and age constraints correctly', () {
        // Valid cases
        final validData = OnboardingData(
          agentId: testAgentId,
          age: 28,
          birthday: DateTime(1995, 1, 1),
          completedAt: testDate,
        );
        expect(validData.isValid, isTrue);

        // Valid with tolerance (1 day future)
        final validTolerance = OnboardingData(
          agentId: testAgentId,
          completedAt: DateTime.now().add(const Duration(days: 1)),
        );
        expect(validTolerance.isValid, isTrue);

        // Invalid: empty agentId
        final invalidEmptyAgentId = OnboardingData(
          agentId: '',
          completedAt: testDate,
        );
        expect(invalidEmptyAgentId.isValid, isFalse);

        // Invalid: wrong agentId format
        final invalidAgentIdFormat = OnboardingData(
          agentId: 'user_123',
          completedAt: testDate,
        );
        expect(invalidAgentIdFormat.isValid, isFalse);

        // Invalid: future completedAt (beyond tolerance)
        final invalidFutureDate = OnboardingData(
          agentId: testAgentId,
          completedAt: DateTime.now().add(const Duration(days: 2)),
        );
        expect(invalidFutureDate.isValid, isFalse);

        // Invalid: age too young
        final invalidAgeYoung = OnboardingData(
          agentId: testAgentId,
          age: 12,
          completedAt: testDate,
        );
        expect(invalidAgeYoung.isValid, isFalse);

        // Invalid: age too old
        final invalidAgeOld = OnboardingData(
          agentId: testAgentId,
          age: 121,
          completedAt: testDate,
        );
        expect(invalidAgeOld.isValid, isFalse);

        // Invalid: future birthday
        final invalidFutureBirthday = OnboardingData(
          agentId: testAgentId,
          birthday: DateTime.now().add(const Duration(days: 1)),
          completedAt: testDate,
        );
        expect(invalidFutureBirthday.isValid, isFalse);
      });
    });

    group('CopyWith', () {
      test('should create immutable copy with updated fields, null handling, and preserve unchanged fields', () {
        final original = OnboardingData(
          agentId: testAgentId,
          age: 28,
          homebase: 'San Francisco, CA',
          completedAt: testDate,
        );

        // Test immutability: original unchanged
        final updated = original.copyWith(
          age: 29,
          homebase: 'New York, NY',
        );
        expect(original.homebase, equals('San Francisco, CA')); // Original preserved
        expect(updated.homebase, equals('New York, NY')); // Copy updated

        // Test null handling: can set nullable field to null
        final nulled = original.copyWith(homebase: null);
        expect(nulled.homebase, isNull);
        expect(original.homebase, equals('San Francisco, CA')); // Original still preserved

        // Test preservation: unchanged fields preserved
        final copy = original.copyWith();
        expect(copy, equals(original)); // All fields preserved
      });
    });

    group('toAgentInitializationMap', () {
      test('should convert OnboardingData to agent initialization map excluding privacy fields', () {
        final data = OnboardingData(
          agentId: testAgentId,
          age: 28,
          birthday: DateTime(1995, 1, 1),
          homebase: 'San Francisco, CA',
          favoritePlaces: ['Golden Gate Park'],
          preferences: {'Food & Drink': ['Coffee']},
          baselineLists: ['My Favorites'],
          respectedFriends: ['friend1'],
          socialMediaConnected: {'google': true},
          completedAt: testDate,
        );

        final map = data.toAgentInitializationMap();

        // Test business logic: privacy-protected fields excluded
        expect(map, isNot(contains('agentId'))); // Privacy: agentId excluded
        expect(map, isNot(contains('completedAt'))); // Metadata excluded
        
        // Test business logic: required fields present for agent initialization
        expect(map['age'], equals(28));
        expect(map['homebase'], equals('San Francisco, CA'));
        expect(map['favoritePlaces'], isA<List>());
        expect(map['preferences'], isA<Map>());
      });
    });

    group('Equality and HashCode', () {
      test('should correctly identify equal and unequal OnboardingData instances', () {
        final data1 = OnboardingData(
          agentId: testAgentId,
          age: 28,
          homebase: 'San Francisco, CA',
          completedAt: testDate,
        );

        final data2 = OnboardingData(
          agentId: testAgentId,
          age: 28,
          homebase: 'San Francisco, CA',
          completedAt: testDate,
        );

        final data3 = OnboardingData(
          agentId: 'agent_different123',
          completedAt: testDate,
        );

        // Test equality behavior
        expect(data1, equals(data2));
        expect(data1.hashCode, equals(data2.hashCode));
        expect(data1, isNot(equals(data3))); // Different agentId = different instance
      });
    });

    group('Edge Cases', () {
      test('should handle large collections, complex data structures, and remain valid', () {
        // Large favoritePlaces list
        final longList = List.generate(100, (i) => 'Place $i');
        final dataWithLongList = OnboardingData(
          agentId: testAgentId,
          favoritePlaces: longList,
          completedAt: testDate,
        );
        expect(dataWithLongList.isValid, isTrue); // Business logic: still valid

        // Complex preferences map
        final complexPreferences = {
          'Food & Drink': ['Coffee', 'Craft Beer', 'Wine'],
          'Activities': ['Hiking', 'Live Music', 'Art Galleries'],
          'Outdoor & Nature': ['Parks', 'Beaches', 'Mountains'],
        };
        final dataWithComplexPrefs = OnboardingData(
          agentId: testAgentId,
          preferences: complexPreferences,
          completedAt: testDate,
        );
        expect(dataWithComplexPrefs.isValid, isTrue); // Business logic: still valid

        // All social media platforms
        final allConnected = {
          'google': true,
          'instagram': true,
          'facebook': true,
          'twitter': true,
        };
        final dataWithAllSocial = OnboardingData(
          agentId: testAgentId,
          socialMediaConnected: allConnected,
          completedAt: testDate,
        );
        expect(dataWithAllSocial.isValid, isTrue); // Business logic: still valid
      });
    });
  });
}

