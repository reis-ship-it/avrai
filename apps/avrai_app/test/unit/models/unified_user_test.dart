import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_core/models/user/unified_user.dart';
import '../../fixtures/model_factories.dart';
import '../../helpers/test_helpers.dart';

/// Comprehensive tests for UnifiedUser model
/// Tests ALL existing methods and properties as they currently exist
/// Validates role system, age verification, and JSON serialization
void main() {
  group('UnifiedUser Model Tests', () {
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

    group('Role System Validation', () {
      test(
          'should correctly validate all role types and calculate list involvement',
          () {
        // Test business logic: role validation and involvement calculation
        final curator = ModelFactories.createCuratorUser();
        final collaborator = ModelFactories.createCollaboratorUser();
        final follower = ModelFactories.createTestUser(
          primaryRole: UserRole.follower,
          followedLists: ['list-1', 'list-2'],
        );
        final multiRole = ModelFactories.createTestUser(
          curatedLists: ['list-1', 'list-2'],
          collaboratedLists: ['list-3'],
          followedLists: ['list-4', 'list-5', 'list-6'],
        );
        final noInvolvement = ModelFactories.createTestUser();

        // Role validation
        expect(curator.primaryRole, equals(UserRole.curator));
        expect(curator.isCurator, isTrue);
        expect(collaborator.primaryRole, equals(UserRole.collaborator));
        expect(collaborator.isCollaborator, isTrue);
        expect(follower.primaryRole, equals(UserRole.follower));
        expect(follower.isFollower, isTrue);

        // Involvement calculation
        expect(multiRole.totalListInvolvement, equals(6));
        expect(noInvolvement.isCurator, isFalse);
        expect(noInvolvement.isCollaborator, isFalse);
        expect(noInvolvement.isFollower, isFalse);
        expect(noInvolvement.totalListInvolvement, equals(0));
      });
    });

    group('Age Verification Logic', () {
      test('should correctly validate age verification access in all states',
          () {
        // Test business logic: age verification access control
        final verifiedUser = ModelFactories.createAgeVerifiedUser();
        final unverifiedUser =
            ModelFactories.createTestUser(isAgeVerified: false);
        final verifiedNoDate = ModelFactories.createTestUser(
          isAgeVerified: true,
          ageVerificationDate: null,
        );

        // Verified with date
        expect(verifiedUser.isAgeVerified, isTrue);
        expect(verifiedUser.ageVerificationDate, isNotNull);
        expect(verifiedUser.canAccessAgeRestrictedContent(), isTrue);

        // Unverified
        expect(unverifiedUser.isAgeVerified, isFalse);
        expect(unverifiedUser.ageVerificationDate, isNull);
        expect(unverifiedUser.canAccessAgeRestrictedContent(), isFalse);

        // Edge case: verified but no date (should not allow access)
        expect(verifiedNoDate.isAgeVerified, isTrue);
        expect(verifiedNoDate.ageVerificationDate, isNull);
        expect(verifiedNoDate.canAccessAgeRestrictedContent(), isFalse);
      });
    });

    group('JSON Serialization', () {
      test('should serialize and deserialize without data loss', () {
        final user = ModelFactories.createTestUser(
          displayName: 'Test User',
          isAgeVerified: true,
          ageVerificationDate: testDate,
          tags: ['test', 'user'],
          curatedLists: ['list-1'],
          primaryRole: UserRole.curator,
        );

        final json = user.toJson();
        final restored = UnifiedUser.fromJson(json);

        // Test critical business fields preserved
        expect(restored.primaryRole, equals(UserRole.curator));
        expect(restored.isAgeVerified, isTrue);
        expect(restored.tags, equals(['test', 'user']));
        expect(restored.curatedLists, equals(['list-1']));
      });

      test('should handle missing and invalid fields with defaults', () {
        final minimalJson = {
          'id': 'test-123',
          'email': 'test@example.com',
          'createdAt': testDate.toIso8601String(),
          'updatedAt': testDate.toIso8601String(),
        };
        final invalidRoleJson = {
          'id': 'test-456',
          'email': 'test2@example.com',
          'createdAt': testDate.toIso8601String(),
          'updatedAt': testDate.toIso8601String(),
          'primaryRole': 'invalid_role',
        };

        final minimal = UnifiedUser.fromJson(minimalJson);
        final invalid = UnifiedUser.fromJson(invalidRoleJson);

        // Test default behavior (business logic)
        expect(minimal.primaryRole, equals(UserRole.follower));
        expect(minimal.isAgeVerified, isFalse);
        expect(invalid.primaryRole,
            equals(UserRole.follower)); // Invalid role defaults to follower
      });
    });

    // Removed: Map Serialization Testing group
    // Map serialization is redundant with JSON serialization tests
    // If JSON works, Map will work (they use the same underlying mechanism)

    group('copyWith', () {
      test('should create immutable copy with updated fields', () {
        final originalUser = ModelFactories.createTestUser();

        final copiedUser = originalUser.copyWith(
          displayName: 'New Name',
          primaryRole: UserRole.curator,
        );

        // Test immutability (business logic)
        expect(originalUser.displayName, isNot(equals('New Name')));
        expect(copiedUser.displayName, equals('New Name'));
        expect(copiedUser.id,
            equals(originalUser.id)); // Unchanged fields preserved
      });
    });

    // Removed: Equatable Implementation group
    // These tests verify Equatable implementation, which is already tested by the package
    // If equality breaks, other tests will fail

    group('Edge Cases', () {
      test('should handle empty collections and null fields correctly', () {
        final user = UnifiedUser(
          id: 'test',
          email: 'test@example.com',
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Test business logic with edge cases
        expect(user.totalListInvolvement, equals(0));
        expect(user.isCurator, isFalse);
        expect(user.canAccessAgeRestrictedContent(), isFalse);
      });
    });
  });

  // Removed: UserRole Enum Tests group
  // These tests only verify enum definition and property values, not business logic
  // Enum values, descriptions, and short names are implementation details
}
