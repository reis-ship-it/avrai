import 'package:equatable/equatable.dart';

/// User roles in the SPOTS community
enum UserRole {
  follower,     // Basic user - can view and respect lists
  collaborator, // Can add/remove spots from lists they have access to  
  curator,      // Can create and manage lists, delete lists, manage permissions
  admin,        // System administrator
}

/// Extension to provide role descriptions and permissions
extension UserRoleExtension on UserRole {
  String get description {
    switch (this) {
      case UserRole.follower:
        return 'Basic user';
      case UserRole.collaborator:
        return 'Can edit spots in lists';
      case UserRole.curator:
        return 'List creator and manager';
      case UserRole.admin:
        return 'System administrator';
    }
  }

  String get shortName {
    switch (this) {
      case UserRole.follower:
        return 'Follower';
      case UserRole.collaborator:
        return 'Collaborator';
      case UserRole.curator:
        return 'Curator';
      case UserRole.admin:
        return 'Admin';
    }
  }

  /// Get the hierarchy level of this role (higher = more permissions)
  int get hierarchyLevel {
    switch (this) {
      case UserRole.follower:
        return 1;
      case UserRole.collaborator:
        return 2;
      case UserRole.curator:
        return 3;
      case UserRole.admin:
        return 4;
    }
  }

  /// Check if this role can manage other roles
  bool get canManageRoles {
    switch (this) {
      case UserRole.curator:
      case UserRole.admin:
        return true;
      case UserRole.collaborator:
      case UserRole.follower:
        return false;
    }
  }

  /// Check if this role can edit list content
  bool get canEditContent {
    switch (this) {
      case UserRole.curator:
      case UserRole.collaborator:
      case UserRole.admin:
        return true;
      case UserRole.follower:
        return false;
    }
  }

  /// Check if this role can delete lists
  bool get canDeleteLists {
    switch (this) {
      case UserRole.curator:
      case UserRole.admin:
        return true;
      case UserRole.collaborator:
      case UserRole.follower:
        return false;
    }
  }

  /// Check if this role can create age-restricted content
  bool get canCreateAgeRestrictedContent {
    switch (this) {
      case UserRole.curator:
      case UserRole.admin:
        return true;
      case UserRole.collaborator:
      case UserRole.follower:
        return false;
    }
  }
}

/// User permissions for specific actions
enum UserPermission {
  viewList,
  editListContent,
  deleteList,
  manageRoles,
  createAgeRestrictedContent,
  reportList,
  respectList,
}

/// Extension to provide permission descriptions
extension UserPermissionExtension on UserPermission {
  String get description {
    switch (this) {
      case UserPermission.viewList:
        return 'View list content';
      case UserPermission.editListContent:
        return 'Add/remove spots from list';
      case UserPermission.deleteList:
        return 'Delete the entire list';
      case UserPermission.manageRoles:
        return 'Assign/revoke roles for other users';
      case UserPermission.createAgeRestrictedContent:
        return 'Create content for users 18+';
      case UserPermission.reportList:
        return 'Report list for moderation';
      case UserPermission.respectList:
        return 'Respect/follow the list';
    }
  }
}

/// User role assignment for a specific list
class UserRoleAssignment extends Equatable {
  final String id;
  final String userId;
  final String listId;
  final UserRole role;
  final DateTime grantedAt;
  final String grantedBy; // User ID who granted this role
  final DateTime? revokedAt;
  final String? revokedBy; // User ID who revoked this role
  final String? reason; // Reason for role assignment/revocation

  const UserRoleAssignment({
    required this.id,
    required this.userId,
    required this.listId,
    required this.role,
    required this.grantedAt,
    required this.grantedBy,
    this.revokedAt,
    this.revokedBy,
    this.reason,
  });

  /// Check if this role assignment is currently active
  bool get isActive => revokedAt == null;

  /// Get the duration of this role assignment
  Duration get duration {
    final endDate = revokedAt ?? DateTime.now();
    return endDate.difference(grantedAt);
  }

  UserRoleAssignment copyWith({
    String? id,
    String? userId,
    String? listId,
    UserRole? role,
    DateTime? grantedAt,
    String? grantedBy,
    DateTime? revokedAt,
    String? revokedBy,
    String? reason,
  }) {
    return UserRoleAssignment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      listId: listId ?? this.listId,
      role: role ?? this.role,
      grantedAt: grantedAt ?? this.grantedAt,
      grantedBy: grantedBy ?? this.grantedBy,
      revokedAt: revokedAt ?? this.revokedAt,
      revokedBy: revokedBy ?? this.revokedBy,
      reason: reason ?? this.reason,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        listId,
        role,
        grantedAt,
        grantedBy,
        revokedAt,
        revokedBy,
        reason,
      ];
}
