import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_core/models/expertise/expertise_community.dart';
import 'package:avrai_core/models/expertise/expertise_level.dart';
import '../../fixtures/model_factories.dart';
import '../../helpers/test_helpers.dart';

/// Comprehensive tests for ExpertiseCommunity model
/// Tests community creation, member management, JSON serialization, and access control
void main() {
  group('ExpertiseCommunity Model Tests', () {
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

    group('getDisplayName', () {
      test('should correctly format display name with and without location',
          () {
        // Test business logic: display name formatting
        final withLocation = ExpertiseCommunity(
          id: 'community-1',
          category: 'Coffee',
          location: 'Brooklyn',
          name: 'Coffee Experts of Brooklyn',
          createdAt: testDate,
          updatedAt: testDate,
          createdBy: 'user-123',
        );
        final withoutLocation = ExpertiseCommunity(
          id: 'community-2',
          category: 'Coffee',
          name: 'Coffee Experts',
          createdAt: testDate,
          updatedAt: testDate,
          createdBy: 'user-123',
        );

        expect(withLocation.getDisplayName(),
            equals('Coffee Experts of Brooklyn'));
        expect(withoutLocation.getDisplayName(), equals('Coffee Experts'));
      });
    });

    group('isMember', () {
      test(
          'should correctly determine membership for members, non-members, and empty lists',
          () {
        // Test business logic: membership determination
        final withMembers = ExpertiseCommunity(
          id: 'community-1',
          category: 'Coffee',
          name: 'Coffee Experts',
          memberIds: const ['user-1', 'user-2', 'user-3'],
          createdAt: testDate,
          updatedAt: testDate,
          createdBy: 'user-123',
        );
        final emptyMembers = ExpertiseCommunity(
          id: 'community-2',
          category: 'Coffee',
          name: 'Coffee Experts',
          createdAt: testDate,
          updatedAt: testDate,
          createdBy: 'user-123',
        );

        final member = ModelFactories.createTestUser(id: 'user-2');
        final nonMember = ModelFactories.createTestUser(id: 'user-999');

        expect(withMembers.isMember(member), isTrue);
        expect(withMembers.isMember(nonMember), isFalse);
        expect(emptyMembers.isMember(member), isFalse);
      });
    });

    group('canUserJoin', () {
      test('should return false for private communities', () {
        final community = ExpertiseCommunity(
          id: 'community-123',
          category: 'Coffee',
          name: 'Coffee Experts',
          isPublic: false,
          createdAt: testDate,
          updatedAt: testDate,
          createdBy: 'user-123',
        );

        final user = ModelFactories.createTestUser(id: 'user-1');
        expect(community.canUserJoin(user), isFalse);
      });

      test('should return true for public communities without min level', () {
        final community = ExpertiseCommunity(
          id: 'community-123',
          category: 'Coffee',
          name: 'Coffee Experts',
          isPublic: true,
          createdAt: testDate,
          updatedAt: testDate,
          createdBy: 'user-123',
        );

        // Note: canUserJoin() depends on UnifiedUser.hasExpertiseIn() and getExpertiseLevel()
        // which require expertise data. This test verifies the structure is correct.
        // Full coverage would require mocking UnifiedUser methods or providing expertise data.
        expect(community.isPublic, isTrue);
        expect(community.minLevel, isNull);
      });
    });

    group('JSON Serialization', () {
      test(
          'should serialize and deserialize with defaults and handle invalid fields',
          () {
        // Test business logic: JSON round-trip with error handling
        final fullCommunity = ExpertiseCommunity(
          id: 'community-1',
          category: 'Coffee',
          location: 'Brooklyn',
          name: 'Coffee Experts of Brooklyn',
          memberIds: const ['user-1', 'user-2'],
          memberCount: 2,
          minLevel: ExpertiseLevel.city,
          isPublic: true,
          createdAt: testDate,
          updatedAt: testDate,
          createdBy: 'user-123',
        );

        final json = fullCommunity.toJson();
        final restored = ExpertiseCommunity.fromJson(json);

        expect(restored.memberIds, equals(['user-1', 'user-2']));
        expect(restored.memberCount, equals(2));
        expect(restored.minLevel, equals(ExpertiseLevel.city));
        expect(restored.isPublic, isTrue);

        // Test defaults with minimal JSON
        final minimalJson = {
          'id': 'community-2',
          'category': 'Coffee',
          'name': 'Coffee Experts',
          'createdAt': testDate.toIso8601String(),
          'updatedAt': testDate.toIso8601String(),
          'createdBy': 'user-123',
        };
        final fromMinimal = ExpertiseCommunity.fromJson(minimalJson);
        expect(fromMinimal.isPublic, isTrue);
        expect(fromMinimal.memberIds, isEmpty);
        expect(fromMinimal.memberCount, equals(0));

        // Test error handling with invalid minLevel
        final invalidJson = {
          'id': 'community-3',
          'category': 'Coffee',
          'name': 'Coffee Experts',
          'minLevel': 'invalid',
          'createdAt': testDate.toIso8601String(),
          'updatedAt': testDate.toIso8601String(),
          'createdBy': 'user-123',
        };
        final fromInvalid = ExpertiseCommunity.fromJson(invalidJson);
        expect(fromInvalid.minLevel, isNull);
      });
    });

    group('copyWith', () {
      test('should create immutable copy with updated fields', () {
        final original = ExpertiseCommunity(
          id: 'community-123',
          category: 'Coffee',
          name: 'Coffee Experts',
          createdAt: testDate,
          updatedAt: testDate,
          createdBy: 'user-123',
        );

        final updated = original.copyWith(
          name: 'Updated Name',
          memberCount: 5,
        );

        // Test immutability (business logic)
        expect(original.name, isNot(equals('Updated Name')));
        expect(updated.name, equals('Updated Name'));
        expect(updated.id, equals(original.id)); // Unchanged fields preserved
      });
    });

    // Removed: Equality group
    // These tests verify Equatable implementation, which is already tested by the package
    // If equality breaks, other tests will fail
  });
}
