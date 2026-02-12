import 'package:equatable/equatable.dart';

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

  factory UserRoleAssignment.fromJson(Map<String, dynamic> json) {
    return UserRoleAssignment(
      id: json['id'] as String,
      userId: json['userId'] as String,
      listId: json['listId'] as String,
      role: UserRole.values.firstWhere(
        (role) => role.name == json['role'],
        orElse: () => UserRole.follower,
      ),
      grantedAt: DateTime.parse(json['grantedAt'] as String),
      grantedBy: json['grantedBy'] as String,
      revokedAt: json['revokedAt'] != null
          ? DateTime.parse(json['revokedAt'] as String)
          : null,
      revokedBy: json['revokedBy'] as String?,
      reason: json['reason'] as String?,
    );
  }

  factory UserRoleAssignment.fromMap(Map<String, dynamic> map) {
    return UserRoleAssignment(
      id: map['id'] as String,
      userId: map['userId'] as String,
      listId: map['listId'] as String,
      role: UserRole.values.firstWhere(
        (role) => role.name == map['role'],
        orElse: () => UserRole.follower,
      ),
      grantedAt: DateTime.parse(map['grantedAt'] as String),
      grantedBy: map['grantedBy'] as String,
      revokedAt: map['revokedAt'] != null
          ? DateTime.parse(map['revokedAt'] as String)
          : null,
      revokedBy: map['revokedBy'] as String?,
      reason: map['reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'listId': listId,
      'role': role.name,
      'grantedAt': grantedAt.toIso8601String(),
      'grantedBy': grantedBy,
      'revokedAt': revokedAt?.toIso8601String(),
      'revokedBy': revokedBy,
      'reason': reason,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'listId': listId,
      'role': role.name,
      'grantedAt': grantedAt.toIso8601String(),
      'grantedBy': grantedBy,
      'revokedAt': revokedAt?.toIso8601String(),
      'revokedBy': revokedBy,
      'reason': reason,
    };
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

  /// Check if this role assignment is currently active
  bool get isActive => revokedAt == null;

  /// Get the duration of this role assignment
  Duration get duration {
    final endDate = revokedAt ?? DateTime.now();
    return endDate.difference(grantedAt);
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

/// User roles in the SPOTS community
enum UserRole {
  curator,      // Can create and manage lists, delete lists, manage permissions
  collaborator, // Can add/remove spots from lists they have access to
  follower,     // Can view and respect lists, basic user
  user,         // Alias for follower for legacy/tests
}

/// Extension to provide role descriptions and permissions
extension UserRoleExtension on UserRole {
  String get description {
    switch (this) {
      case UserRole.curator:
        return 'List creator and manager';
      case UserRole.collaborator:
        return 'Can edit spots in lists';
      case UserRole.follower:
        return 'Basic user';
      case UserRole.user:
        return 'Basic user';
    }
  }

  String get shortName {
    switch (this) {
      case UserRole.curator:
        return 'Curator';
      case UserRole.collaborator:
        return 'Collaborator';
      case UserRole.follower:
      case UserRole.user:
        return 'Follower';
    }
  }

  /// Get the hierarchy level of this role (higher = more permissions)
  int get hierarchyLevel {
    switch (this) {
      case UserRole.curator:
        return 3;
      case UserRole.collaborator:
        return 2;
      case UserRole.follower:
      case UserRole.user:
        return 1;
    }
  }

  /// Check if this role can manage other roles
  bool get canManageRoles {
    switch (this) {
      case UserRole.curator:
        return true;
      case UserRole.collaborator:
      case UserRole.follower:
      case UserRole.user:
        return false;
    }
  }

  /// Check if this role can edit list content
  bool get canEditContent {
    switch (this) {
      case UserRole.curator:
      case UserRole.collaborator:
        return true;
      case UserRole.follower:
      case UserRole.user:
        return false;
    }
  }

  /// Check if this role can delete lists
  bool get canDeleteLists {
    switch (this) {
      case UserRole.curator:
        return true;
      case UserRole.collaborator:
      case UserRole.follower:
      case UserRole.user:
        return false;
    }
  }

  /// Check if this role can view private lists
  bool get canViewPrivateLists {
    switch (this) {
      case UserRole.curator:
      case UserRole.collaborator:
      case UserRole.follower:
      case UserRole.user:
        return true; // All roles can view lists they're part of
    }
  }

  /// Check if this role can create age-restricted content
  bool get canCreateAgeRestrictedContent {
    switch (this) {
      case UserRole.curator:
        return true;
      case UserRole.collaborator:
      case UserRole.follower:
      case UserRole.user:
        return false;
    }
  }
}

/// Role management service interface
abstract class RoleManagementService {
  /// Assign a role to a user for a specific list
  Future<UserRoleAssignment> assignRole({
    required String userId,
    required String listId,
    required UserRole role,
    required String grantedBy,
    String? reason,
  });

  /// Revoke a role from a user
  Future<UserRoleAssignment> revokeRole({
    required String userId,
    required String listId,
    required String revokedBy,
    String? reason,
  });

  /// Get all role assignments for a user
  Future<List<UserRoleAssignment>> getUserRoles(String userId);

  /// Get all role assignments for a list
  Future<List<UserRoleAssignment>> getListRoles(String listId);

  /// Get the current role of a user for a specific list
  Future<UserRole?> getUserRoleForList(String userId, String listId);

  /// Check if a user has a specific permission for a list
  Future<bool> hasPermission({
    required String userId,
    required String listId,
    required UserPermission permission,
  });

  /// Get all users with a specific role for a list
  Future<List<String>> getUsersWithRole(String listId, UserRole role);

  /// Transfer list ownership to another user
  Future<void> transferOwnership({
    required String listId,
    required String newCuratorId,
    required String transferredBy,
  });
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
