import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/models/community/club_hierarchy.dart';

/// Comprehensive tests for ClubHierarchy Model
/// Tests roles enum, permissions system, role hierarchy
///
/// **Philosophy Alignment:**
/// - Communities can organize as clubs when structure is needed
/// - Club leaders gain expertise recognition
/// - Organizational structure enables community growth
void main() {
  group('ClubRole Enum Tests', () {
    // Removed: Enum values test - tests enum definition, not business logic
    // Removed: Display names test - tests property values, not business logic
    // Removed: Hierarchy levels test - tests property values, not business logic

    test('should correctly determine if role can manage another role', () {
      // Leader can manage all other roles
      expect(ClubRole.leader.canManageRole(ClubRole.admin), isTrue);
      expect(ClubRole.leader.canManageRole(ClubRole.moderator), isTrue);
      expect(ClubRole.leader.canManageRole(ClubRole.member), isTrue);
      expect(ClubRole.leader.canManageRole(ClubRole.leader), isFalse);

      // Admin can manage moderator and member
      expect(ClubRole.admin.canManageRole(ClubRole.moderator), isTrue);
      expect(ClubRole.admin.canManageRole(ClubRole.member), isTrue);
      expect(ClubRole.admin.canManageRole(ClubRole.admin), isFalse);
      expect(ClubRole.admin.canManageRole(ClubRole.leader), isFalse);

      // Moderator can manage member
      expect(ClubRole.moderator.canManageRole(ClubRole.member), isTrue);
      expect(ClubRole.moderator.canManageRole(ClubRole.moderator), isFalse);
      expect(ClubRole.moderator.canManageRole(ClubRole.admin), isFalse);
      expect(ClubRole.moderator.canManageRole(ClubRole.leader), isFalse);

      // Member cannot manage any role
      expect(ClubRole.member.canManageRole(ClubRole.member), isFalse);
      expect(ClubRole.member.canManageRole(ClubRole.moderator), isFalse);
      expect(ClubRole.member.canManageRole(ClubRole.admin), isFalse);
      expect(ClubRole.member.canManageRole(ClubRole.leader), isFalse);
    });
  });

  group('ClubPermissions Tests', () {
    test('should return correct permissions for each role', () {
      // Test business logic: role-based permissions
      final leader = ClubPermissions.forRole(ClubRole.leader);
      final admin = ClubPermissions.forRole(ClubRole.admin);
      final moderator = ClubPermissions.forRole(ClubRole.moderator);
      final member = ClubPermissions.forRole(ClubRole.member);

      expect(leader.canManageLeaders, isTrue);
      expect(admin.canManageAdmins, isFalse);
      expect(moderator.canModerateContent, isTrue);
      expect(moderator.canManageMembers, isFalse);
      expect(member.canCreateEvents, isTrue);
      expect(member.canManageMembers, isFalse);
    });

    test('should check permissions by string name correctly', () {
      final permissions = ClubPermissions.forRole(ClubRole.leader);

      // Test business logic: permission lookup
      expect(permissions.hasPermission('createEvents'), isTrue);
      expect(permissions.hasPermission('manageLeaders'), isTrue);
      expect(permissions.hasPermission('unknownPermission'), isFalse);
    });

    test(
        'should serialize and deserialize with defaults and create immutable copies',
        () {
      // Test business logic: JSON serialization and immutability
      final permissions = ClubPermissions.forRole(ClubRole.admin);
      final json = permissions.toJson();
      final restored = ClubPermissions.fromJson(json);

      // Test critical business fields preserved
      expect(restored.canManageMembers, equals(permissions.canManageMembers));
      expect(restored.canViewAnalytics, equals(permissions.canViewAnalytics));

      // Test default behavior with minimal JSON
      final minimalJson = {'canCreateEvents': true};
      final fromMinimal = ClubPermissions.fromJson(minimalJson);
      expect(fromMinimal.canCreateEvents, isTrue);
      expect(fromMinimal.canManageMembers, isFalse);

      // Test immutability
      const original = ClubPermissions();
      final updated = original.copyWith(
        canCreateEvents: true,
        canManageMembers: true,
      );
      expect(original.canCreateEvents, isFalse);
      expect(updated.canCreateEvents, isTrue);
    });
  });

  group('ClubHierarchy Tests', () {
    test('should provide correct permissions for each role', () {
      // Test business logic: role-based permission lookup
      final hierarchy = ClubHierarchy();

      final leaderPerms = hierarchy.getPermissionsForRole(ClubRole.leader);
      final adminPerms = hierarchy.getPermissionsForRole(ClubRole.admin);
      final memberPerms = hierarchy.getPermissionsForRole(ClubRole.member);

      expect(leaderPerms.canManageLeaders, isTrue);
      expect(adminPerms.canManageAdmins, isFalse);
      expect(memberPerms.canCreateEvents, isTrue);
      expect(memberPerms.canManageMembers, isFalse);
    });

    test('should check role permissions correctly', () {
      final hierarchy = ClubHierarchy();

      // Test business logic: permission checking
      expect(
          hierarchy.roleHasPermission(ClubRole.leader, 'createEvents'), isTrue);
      expect(hierarchy.roleHasPermission(ClubRole.leader, 'manageLeaders'),
          isTrue);
      expect(
          hierarchy.roleHasPermission(ClubRole.admin, 'manageAdmins'), isFalse);
      expect(hierarchy.roleHasPermission(ClubRole.member, 'manageMembers'),
          isFalse);
    });

    test(
        'should serialize and deserialize with defaults and create immutable copies',
        () {
      // Test business logic: JSON serialization with nested structure and immutability
      final hierarchy = ClubHierarchy();
      final json = hierarchy.toJson();
      final restored = ClubHierarchy.fromJson(json);

      // Test nested structure preserved
      expect(restored.rolePermissions.length,
          equals(hierarchy.rolePermissions.length));
      expect(restored.getPermissionsForRole(ClubRole.leader).canManageLeaders,
          isTrue);

      // Test default behavior with minimal JSON
      final minimalJson = {
        'rolePermissions': {
          'leader': {
            'canCreateEvents': true,
            'canManageMembers': true,
            'canManageAdmins': true,
            'canManageLeaders': true,
            'canModerateContent': true,
            'canViewAnalytics': true,
          },
        },
      };
      final fromMinimal = ClubHierarchy.fromJson(minimalJson);
      expect(fromMinimal.rolePermissions, contains(ClubRole.leader));
      expect(fromMinimal.rolePermissions,
          contains(ClubRole.member)); // Default added

      // Test immutability
      final original = ClubHierarchy();
      final customPermissions = {
        ...original.rolePermissions,
        ClubRole.member: const ClubPermissions(
          canCreateEvents: true,
          canManageMembers: true,
        ),
      };
      final updated = original.copyWith(rolePermissions: customPermissions);
      expect(
          updated.rolePermissions[ClubRole.member]?.canManageMembers, isTrue);
      expect(
          original.rolePermissions[ClubRole.member]?.canManageMembers, isFalse);
    });
  });
}
