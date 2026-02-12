import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/models/user/unified_list.dart';
import '../../fixtures/model_factories.dart';
import '../../helpers/test_helpers.dart';

/// Comprehensive tests for UnifiedList model
/// Tests independent node architecture, role-based permissions, and moderation
void main() {
  group('UnifiedList Model Tests', () {
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

    group('Independent Node Architecture', () {
      test(
          'should correctly calculate total user involvement and identify user relationships',
          () {
        // Test business logic: involvement calculation and relationship identification
        final list = ModelFactories.createTestList(
          curatorId: 'curator-123',
          collaboratorIds: ['user-1', 'user-2'],
          followerIds: ['user-3', 'user-4', 'user-5'],
        );

        // 1 curator + 2 collaborators + 3 followers = 6
        expect(list.totalUserInvolvement, equals(6));
        expect(list.isCurator('curator-123'), isTrue);
        expect(list.isCollaborator('user-1'), isTrue);
        expect(list.isFollower('user-3'), isTrue);
        expect(list.isCurator('other-user'), isFalse);
      });
    });

    group('Permission System', () {
      test(
          'should correctly enforce role-based permissions and allow public viewing for public lists',
          () {
        // Test business logic: permission enforcement and public access
        final list = ModelFactories.createTestList(
          curatorId: 'curator-123',
          collaboratorIds: ['collab-1'],
          followerIds: ['follower-1'],
          isPublic: false,
        );

        // Edit permissions
        expect(list.canEdit('curator-123'), isTrue);
        expect(list.canEdit('collab-1'), isTrue);
        expect(list.canEdit('other-user'), isFalse);

        // Delete permissions (curator only)
        expect(list.canDelete('curator-123'), isTrue);
        expect(list.canDelete('collab-1'), isFalse);

        // View permissions
        expect(list.canView('curator-123'), isTrue);
        expect(list.canView('follower-1'), isTrue);
        expect(list.canView('random-user'), isFalse);

        // Public access
        final publicList = ModelFactories.createTestList(
          curatorId: 'curator-123',
          isPublic: true,
        );
        expect(publicList.canView('random-user'), isTrue);
      });
    });

    group('Moderation and Reporting System', () {
      test(
          'should correctly determine suspension criteria and identify current suspension status',
          () {
        // Test business logic: suspension criteria and status checking
        final meetsCriteria = UnifiedList(
          id: 'test-list',
          title: 'Test List',
          category: 'General',
          createdAt: testDate,
          curatorId: 'curator-123',
          reportCount: 5,
          respectCount: 3,
        );
        final insufficientReports = UnifiedList(
          id: 'test-list-2',
          title: 'Test List',
          category: 'General',
          createdAt: testDate,
          curatorId: 'curator-123',
          reportCount: 3,
          respectCount: 3,
        );

        expect(meetsCriteria.meetsSuspensionCriteria, isTrue);
        expect(insufficientReports.meetsSuspensionCriteria, isFalse);

        // Test suspension status
        final permanent = ModelFactories.createSuspendedList(
          suspensionEndDate: null,
        );
        final temporaryActive = ModelFactories.createSuspendedList(
          suspensionEndDate: DateTime.now().add(const Duration(days: 1)),
        );
        final expired = ModelFactories.createSuspendedList(
          suspensionEndDate:
              TestHelpers.createTimestampWithOffset(const Duration(days: -1)),
        );
        final notSuspended = ModelFactories.createTestList(isSuspended: false);

        expect(permanent.isCurrentlySuspended, isTrue);
        expect(temporaryActive.isCurrentlySuspended, isTrue);
        expect(expired.isCurrentlySuspended, isFalse);
        expect(notSuspended.isCurrentlySuspended, isFalse);
      });
    });

    // Removed: Age Restriction Enforcement group
    // These tests only verified boolean property, not business logic

    group('JSON Serialization', () {
      test(
          'should serialize and deserialize with defaults and handle missing and alternative fields',
          () {
        // Test business logic: JSON round-trip with default and alternative field handling
        final list = ModelFactories.createTestList(
          collaboratorIds: ['collab-1'],
          followerIds: ['follower-1'],
          spotIds: ['spot-1'],
        );

        TestHelpers.validateJsonRoundtrip(
          list,
          (l) => l.toJson(),
          (json) => UnifiedList.fromJson(json),
        );

        // Test defaults and alternative fields
        final minimalJson = {
          'id': '',
          'title': '',
          'category': 'General',
          'createdAt': testDate.toIso8601String(),
          'curatorId': '',
        };
        final alternativeJson = {
          'id': 'list-123',
          'name': 'Test List', // Alternative to 'title'
          'category': 'Food',
          'createdAt': testDate.toIso8601String(),
          'userId': 'curator-123', // Alternative to 'curatorId'
        };

        final minimal = UnifiedList.fromJson(minimalJson);
        final alternative = UnifiedList.fromJson(alternativeJson);

        expect(minimal.isPublic, isTrue); // Default
        expect(alternative.title, equals('Test List'));
        expect(alternative.curatorId, equals('curator-123'));
      });
    });

    // Removed: Map Serialization Testing group
    // Map serialization is tested through JSON round-trip tests above

    group('copyWith', () {
      test('should create immutable copy with updated fields', () {
        final original = ModelFactories.createTestList();
        final updated = original.copyWith(
          title: 'New Title',
          respectCount: 10,
        );

        // Test immutability (business logic)
        expect(original.title, isNot(equals('New Title')));
        expect(updated.title, equals('New Title'));
        expect(updated.id, equals(original.id)); // Unchanged fields preserved
      });
    });

    // Removed: Equatable Implementation group
    // These tests verify Equatable implementation, which is already tested by the package
    // If equality breaks, other tests will fail
  });

  group('ListPermissions Model Tests', () {
    test('should serialize and deserialize permissions correctly', () {
      const permissions = ListPermissions(
        allowCollaborators: false,
        requireApproval: true,
        minRespectsForCollaboration: 5,
      );

      final json = permissions.toJson();
      final restored = ListPermissions.fromJson(json);

      // Test critical business fields preserved
      expect(restored.allowCollaborators, isFalse);
      expect(restored.requireApproval, isTrue);
      expect(restored.minRespectsForCollaboration, equals(5));
    });

    test('should create immutable copy with updated permissions', () {
      const original = ListPermissions();
      final updated = original.copyWith(
        allowCollaborators: false,
        requireApproval: true,
      );

      // Test immutability (business logic)
      expect(original.allowCollaborators, isTrue);
      expect(updated.allowCollaborators, isFalse);
    });
  });
}
