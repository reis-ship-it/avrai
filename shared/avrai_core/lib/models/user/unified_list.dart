import 'package:equatable/equatable.dart';

/// Unified List model that supports independent node architecture
/// Lists are independent content nodes that users can connect to
class UnifiedList extends Equatable {
  // Core list information
  final String id;
  final String title;
  final String? description;
  final String category;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? lastModified;

  // Independent node architecture
  final String curatorId; // Original creator/owner
  final List<String> collaboratorIds; // Users with edit permissions
  final List<String> followerIds; // Users who respect/follow
  final List<String> spotIds; // Spots in this list

  // Visibility and access control
  final bool isPublic;
  final bool isAgeRestricted; // Requires age verification for 18+ content
  final ListPermissions permissions;

  // Social metrics
  final int respectCount;
  final int viewCount;
  final bool isStarter;
  final String? starterType;

  // Moderation and reporting
  final int reportCount;
  final bool isSuspended;
  final DateTime? suspensionEndDate;
  final String? suspensionReason;

  const UnifiedList({
    required this.id,
    required this.title,
    this.description,
    required this.category,
    required this.createdAt,
    this.updatedAt,
    this.lastModified,
    required this.curatorId,
    this.collaboratorIds = const [],
    this.followerIds = const [],
    this.spotIds = const [],
    this.isPublic = true,
    this.isAgeRestricted = false,
    this.permissions = const ListPermissions(),
    this.respectCount = 0,
    this.viewCount = 0,
    this.isStarter = false,
    this.starterType,
    this.reportCount = 0,
    this.isSuspended = false,
    this.suspensionEndDate,
    this.suspensionReason,
  });

  factory UnifiedList.fromJson(Map<String, dynamic> json) {
    return UnifiedList(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? json['name'] as String? ?? '',
      description: json['description'] as String?,
      category: json['category'] as String? ?? 'General',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
      lastModified: json['lastModified'] != null
          ? DateTime.tryParse(json['lastModified'])
          : null,
      curatorId: json['curatorId'] as String? ??
          json['userId'] as String? ??
          json['createdBy'] as String? ??
          '',
      collaboratorIds: List<String>.from(json['collaboratorIds'] ?? []),
      followerIds: List<String>.from(json['followerIds'] ?? []),
      spotIds: json['spotIds'] is List
          ? (json['spotIds'] as List).map((e) => e.toString()).toList()
          : json['spotIds'] is String
              ? [json['spotIds'].toString()]
              : [],
      isPublic: json['isPublic'] is bool ? json['isPublic'] : true,
      isAgeRestricted:
          json['isAgeRestricted'] is bool ? json['isAgeRestricted'] : false,
      permissions: json['permissions'] != null
          ? ListPermissions.fromJson(json['permissions'])
          : const ListPermissions(),
      respectCount: json['respectCount'] is int ? json['respectCount'] : 0,
      viewCount: json['viewCount'] is int ? json['viewCount'] : 0,
      isStarter: json['isStarter'] is bool ? json['isStarter'] : false,
      starterType: json['starterType'] as String?,
      reportCount: json['reportCount'] is int ? json['reportCount'] : 0,
      isSuspended: json['isSuspended'] is bool ? json['isSuspended'] : false,
      suspensionEndDate: json['suspensionEndDate'] != null
          ? DateTime.tryParse(json['suspensionEndDate'])
          : null,
      suspensionReason: json['suspensionReason'] as String?,
    );
  }

  factory UnifiedList.fromMap(Map<String, dynamic> map) {
    return UnifiedList(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? map['name'] as String? ?? '',
      description: map['description'] as String?,
      category: map['category'] as String? ?? 'General',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt:
          map['updatedAt'] != null ? DateTime.tryParse(map['updatedAt']) : null,
      lastModified: map['lastModified'] != null
          ? DateTime.tryParse(map['lastModified'])
          : null,
      curatorId: map['curatorId'] as String? ??
          map['userId'] as String? ??
          map['createdBy'] as String? ??
          '',
      collaboratorIds: List<String>.from(map['collaboratorIds'] ?? []),
      followerIds: List<String>.from(map['followerIds'] ?? []),
      spotIds: map['spotIds'] is List
          ? (map['spotIds'] as List).map((e) => e.toString()).toList()
          : map['spotIds'] is String
              ? [map['spotIds'].toString()]
              : [],
      isPublic: map['isPublic'] is bool ? map['isPublic'] : true,
      isAgeRestricted:
          map['isAgeRestricted'] is bool ? map['isAgeRestricted'] : false,
      permissions: map['permissions'] != null
          ? ListPermissions.fromJson(map['permissions'])
          : const ListPermissions(),
      respectCount: map['respectCount'] is int ? map['respectCount'] : 0,
      viewCount: map['viewCount'] is int ? map['viewCount'] : 0,
      isStarter: map['isStarter'] is bool ? map['isStarter'] : false,
      starterType: map['starterType'] as String?,
      reportCount: map['reportCount'] is int ? map['reportCount'] : 0,
      isSuspended: map['isSuspended'] is bool ? map['isSuspended'] : false,
      suspensionEndDate: map['suspensionEndDate'] != null
          ? DateTime.tryParse(map['suspensionEndDate'])
          : null,
      suspensionReason: map['suspensionReason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'lastModified': lastModified?.toIso8601String(),
      'curatorId': curatorId,
      'collaboratorIds': collaboratorIds,
      'followerIds': followerIds,
      'spotIds': spotIds,
      'isPublic': isPublic,
      'isAgeRestricted': isAgeRestricted,
      'permissions': permissions.toJson(),
      'respectCount': respectCount,
      'viewCount': viewCount,
      'isStarter': isStarter,
      'starterType': starterType,
      'reportCount': reportCount,
      'isSuspended': isSuspended,
      'suspensionEndDate': suspensionEndDate?.toIso8601String(),
      'suspensionReason': suspensionReason,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'lastModified': lastModified?.toIso8601String(),
      'curatorId': curatorId,
      'collaboratorIds': collaboratorIds,
      'followerIds': followerIds,
      'spotIds': spotIds,
      'isPublic': isPublic,
      'isAgeRestricted': isAgeRestricted,
      'permissions': permissions.toMap(),
      'respectCount': respectCount,
      'viewCount': viewCount,
      'isStarter': isStarter,
      'starterType': starterType,
      'reportCount': reportCount,
      'isSuspended': isSuspended,
      'suspensionEndDate': suspensionEndDate?.toIso8601String(),
      'suspensionReason': suspensionReason,
    };
  }

  UnifiedList copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastModified,
    String? curatorId,
    List<String>? collaboratorIds,
    List<String>? followerIds,
    List<String>? spotIds,
    bool? isPublic,
    bool? isAgeRestricted,
    ListPermissions? permissions,
    int? respectCount,
    int? viewCount,
    bool? isStarter,
    String? starterType,
    int? reportCount,
    bool? isSuspended,
    DateTime? suspensionEndDate,
    String? suspensionReason,
  }) {
    return UnifiedList(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastModified: lastModified ?? this.lastModified,
      curatorId: curatorId ?? this.curatorId,
      collaboratorIds: collaboratorIds ?? this.collaboratorIds,
      followerIds: followerIds ?? this.followerIds,
      spotIds: spotIds ?? this.spotIds,
      isPublic: isPublic ?? this.isPublic,
      isAgeRestricted: isAgeRestricted ?? this.isAgeRestricted,
      permissions: permissions ?? this.permissions,
      respectCount: respectCount ?? this.respectCount,
      viewCount: viewCount ?? this.viewCount,
      isStarter: isStarter ?? this.isStarter,
      starterType: starterType ?? this.starterType,
      reportCount: reportCount ?? this.reportCount,
      isSuspended: isSuspended ?? this.isSuspended,
      suspensionEndDate: suspensionEndDate ?? this.suspensionEndDate,
      suspensionReason: suspensionReason ?? this.suspensionReason,
    );
  }

  /// Check if list is currently suspended
  bool get isCurrentlySuspended {
    if (!isSuspended) return false;
    if (suspensionEndDate == null) return true;
    return DateTime.now().isBefore(suspensionEndDate!);
  }

  /// Check if list meets criteria for suspension (5+ reports by 3+ users in <3 weeks)
  bool get meetsSuspensionCriteria {
    return reportCount >= 5 && respectCount >= 3;
  }

  /// Get total number of users involved with this list
  int get totalUserInvolvement =>
      1 + collaboratorIds.length + followerIds.length;

  /// Check if a user has curator permissions
  bool isCurator(String userId) => curatorId == userId;

  /// Check if a user has collaborator permissions
  bool isCollaborator(String userId) => collaboratorIds.contains(userId);

  /// Check if a user is a follower
  bool isFollower(String userId) => followerIds.contains(userId);

  /// Check if a user can edit this list
  bool canEdit(String userId) => isCurator(userId) || isCollaborator(userId);

  /// Check if a user can delete this list
  bool canDelete(String userId) => isCurator(userId);

  /// Check if a user can view this list
  bool canView(String userId) =>
      isPublic ||
      isCurator(userId) ||
      isCollaborator(userId) ||
      isFollower(userId);

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        category,
        createdAt,
        updatedAt,
        lastModified,
        curatorId,
        collaboratorIds,
        followerIds,
        spotIds,
        isPublic,
        isAgeRestricted,
        permissions,
        respectCount,
        viewCount,
        isStarter,
        starterType,
        reportCount,
        isSuspended,
        suspensionEndDate,
        suspensionReason,
      ];
}

/// Permissions for list access and management
class ListPermissions extends Equatable {
  final bool allowCollaborators;
  final bool allowPublicViewing;
  final bool requireApproval;
  final int minRespectsForCollaboration;
  final bool allowAgeRestrictedContent;
  final bool allowReporting;

  const ListPermissions({
    this.allowCollaborators = true,
    this.allowPublicViewing = true,
    this.requireApproval = false,
    this.minRespectsForCollaboration = 0,
    this.allowAgeRestrictedContent = false,
    this.allowReporting = true,
  });

  factory ListPermissions.fromJson(Map<String, dynamic> json) {
    return ListPermissions(
      allowCollaborators: json['allowCollaborators'] as bool? ?? true,
      allowPublicViewing: json['allowPublicViewing'] as bool? ?? true,
      requireApproval: json['requireApproval'] as bool? ?? false,
      minRespectsForCollaboration:
          json['minRespectsForCollaboration'] as int? ?? 0,
      allowAgeRestrictedContent:
          json['allowAgeRestrictedContent'] as bool? ?? false,
      allowReporting: json['allowReporting'] as bool? ?? true,
    );
  }

  factory ListPermissions.fromMap(Map<String, dynamic> map) {
    return ListPermissions(
      allowCollaborators: map['allowCollaborators'] as bool? ?? true,
      allowPublicViewing: map['allowPublicViewing'] as bool? ?? true,
      requireApproval: map['requireApproval'] as bool? ?? false,
      minRespectsForCollaboration:
          map['minRespectsForCollaboration'] as int? ?? 0,
      allowAgeRestrictedContent:
          map['allowAgeRestrictedContent'] as bool? ?? false,
      allowReporting: map['allowReporting'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'allowCollaborators': allowCollaborators,
      'allowPublicViewing': allowPublicViewing,
      'requireApproval': requireApproval,
      'minRespectsForCollaboration': minRespectsForCollaboration,
      'allowAgeRestrictedContent': allowAgeRestrictedContent,
      'allowReporting': allowReporting,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'allowCollaborators': allowCollaborators,
      'allowPublicViewing': allowPublicViewing,
      'requireApproval': requireApproval,
      'minRespectsForCollaboration': minRespectsForCollaboration,
      'allowAgeRestrictedContent': allowAgeRestrictedContent,
      'allowReporting': allowReporting,
    };
  }

  ListPermissions copyWith({
    bool? allowCollaborators,
    bool? allowPublicViewing,
    bool? requireApproval,
    int? minRespectsForCollaboration,
    bool? allowAgeRestrictedContent,
    bool? allowReporting,
  }) {
    return ListPermissions(
      allowCollaborators: allowCollaborators ?? this.allowCollaborators,
      allowPublicViewing: allowPublicViewing ?? this.allowPublicViewing,
      requireApproval: requireApproval ?? this.requireApproval,
      minRespectsForCollaboration:
          minRespectsForCollaboration ?? this.minRespectsForCollaboration,
      allowAgeRestrictedContent:
          allowAgeRestrictedContent ?? this.allowAgeRestrictedContent,
      allowReporting: allowReporting ?? this.allowReporting,
    );
  }

  @override
  List<Object?> get props => [
        allowCollaborators,
        allowPublicViewing,
        requireApproval,
        minRespectsForCollaboration,
        allowAgeRestrictedContent,
        allowReporting,
      ];
}
