import 'package:equatable/equatable.dart';

/// Business Member Model
///
/// Represents a user who is a member of a business account.
/// Supports role-based access control.
class BusinessMember extends Equatable {
  final String id;
  final String userId;
  final String businessId;
  final BusinessMemberRole role;
  final DateTime joinedAt;
  final String? invitedBy; // User ID who invited them
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BusinessMember({
    required this.id,
    required this.userId,
    required this.businessId,
    required this.role,
    required this.joinedAt,
    this.invitedBy,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BusinessMember.fromJson(Map<String, dynamic> json) {
    return BusinessMember(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      businessId: json['business_id'] as String,
      role: BusinessMemberRole.values.firstWhere(
        (r) => r.name == (json['role'] as String? ?? 'member'),
        orElse: () => BusinessMemberRole.member,
      ),
      joinedAt: DateTime.parse(json['joined_at'] as String),
      invitedBy: json['invited_by'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'business_id': businessId,
      'role': role.name,
      'joined_at': joinedAt.toIso8601String(),
      'invited_by': invitedBy,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  BusinessMember copyWith({
    String? id,
    String? userId,
    String? businessId,
    BusinessMemberRole? role,
    DateTime? joinedAt,
    String? invitedBy,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BusinessMember(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      businessId: businessId ?? this.businessId,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      invitedBy: invitedBy ?? this.invitedBy,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        businessId,
        role,
        joinedAt,
        invitedBy,
        isActive,
        createdAt,
        updatedAt,
      ];
}

/// Business Member Role
enum BusinessMemberRole {
  owner, // Full access, can delete business, manage all members
  admin, // Can manage members (except owners), settings, content
  member, // Standard access, can contribute to business content
}

/// Extension for role descriptions
extension BusinessMemberRoleExtension on BusinessMemberRole {
  String get description {
    switch (this) {
      case BusinessMemberRole.owner:
        return 'Full access to business account';
      case BusinessMemberRole.admin:
        return 'Can manage members and settings';
      case BusinessMemberRole.member:
        return 'Standard business access';
    }
  }

  bool get canManageMembers {
    switch (this) {
      case BusinessMemberRole.owner:
      case BusinessMemberRole.admin:
        return true;
      case BusinessMemberRole.member:
        return false;
    }
  }

  bool get canDeleteBusiness {
    return this == BusinessMemberRole.owner;
  }
}
