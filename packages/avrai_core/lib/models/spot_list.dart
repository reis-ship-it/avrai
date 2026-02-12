import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import '../enums/list_enums.dart';

part 'spot_list.g.dart';

@JsonSerializable()
class SpotList extends Equatable {
  final String id;
  final String title;
  final String description;
  final ListCategory category;
  final ListType type;
  final String curatorId; // Primary owner/creator
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Visibility and access
  final bool isPublic;
  final ModerationLevel moderationLevel;
  final bool isAgeRestricted;
  final List<String> allowedViewers; // For private lists
  
  // Content
  final List<String> spotIds;
  final String? imageUrl;
  final List<String> tags;
  final Map<String, dynamic> metadata;
  
  // Engagement metrics
  final int respectCount;
  final int viewCount;
  final int shareCount;
  final List<String> respectedBy; // User IDs
  final List<String> followers; // User IDs
  
  // Collaboration
  final List<String> collaboratorIds; // Users who can edit
  final List<String> memberIds; // Users who can contribute
  final Map<String, ListRole> userRoles; // User ID -> Role mapping
  
  const SpotList({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.type,
    required this.curatorId,
    required this.createdAt,
    required this.updatedAt,
    this.isPublic = true,
    this.moderationLevel = ModerationLevel.standard,
    this.isAgeRestricted = false,
    this.allowedViewers = const [],
    this.spotIds = const [],
    this.imageUrl,
    this.tags = const [],
    this.metadata = const {},
    this.respectCount = 0,
    this.viewCount = 0,
    this.shareCount = 0,
    this.respectedBy = const [],
    this.followers = const [],
    this.collaboratorIds = const [],
    this.memberIds = const [],
    this.userRoles = const {},
  });
  
  /// Check if list is publicly visible
  bool get isVisible => isPublic && !isAgeRestricted;
  
  /// Get total engagement score
  double get engagementScore => 
      (viewCount * 0.1) + (respectCount * 1.0) + (shareCount * 2.0) + 
      (followers.length * 0.5);
  
  /// Get total spot count
  int get spotCount => spotIds.length;
  
  /// Check if user has respected this list
  bool isRespectedBy(String userId) => respectedBy.contains(userId);
  
  /// Check if user is following this list
  bool isFollowedBy(String userId) => followers.contains(userId);
  
  /// Get user's role in this list
  ListRole getUserRole(String userId) {
    if (userId == curatorId) return ListRole.curator;
    return userRoles[userId] ?? ListRole.viewer;
  }
  
  /// Check if user can edit this list
  bool canUserEdit(String userId) {
    final role = getUserRole(userId);
    return role.canEdit;
  }
  
  /// Check if user can manage members of this list
  bool canUserManageMembers(String userId) {
    final role = getUserRole(userId);
    return role.canManageMembers;
  }
  
  /// Check if user can view this list
  bool canUserView(String userId) {
    if (isPublic) return true;
    if (userId == curatorId) return true;
    if (collaboratorIds.contains(userId)) return true;
    if (memberIds.contains(userId)) return true;
    if (allowedViewers.contains(userId)) return true;
    return false;
  }
  
  /// Get all users with any role in this list
  List<String> get allUserIds {
    final users = <String>{curatorId};
    users.addAll(collaboratorIds);
    users.addAll(memberIds);
    users.addAll(allowedViewers);
    return users.toList();
  }
  
  /// Check if list allows collaboration
  bool get allowsCollaboration => 
      type == ListType.collaborative || collaboratorIds.isNotEmpty;
  
  factory SpotList.fromJson(Map<String, dynamic> json) => _$SpotListFromJson(json);
  Map<String, dynamic> toJson() => _$SpotListToJson(this);
  
  SpotList copyWith({
    String? id,
    String? title,
    String? description,
    ListCategory? category,
    ListType? type,
    String? curatorId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPublic,
    ModerationLevel? moderationLevel,
    bool? isAgeRestricted,
    List<String>? allowedViewers,
    List<String>? spotIds,
    String? imageUrl,
    List<String>? tags,
    Map<String, dynamic>? metadata,
    int? respectCount,
    int? viewCount,
    int? shareCount,
    List<String>? respectedBy,
    List<String>? followers,
    List<String>? collaboratorIds,
    List<String>? memberIds,
    Map<String, ListRole>? userRoles,
  }) {
    return SpotList(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      type: type ?? this.type,
      curatorId: curatorId ?? this.curatorId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPublic: isPublic ?? this.isPublic,
      moderationLevel: moderationLevel ?? this.moderationLevel,
      isAgeRestricted: isAgeRestricted ?? this.isAgeRestricted,
      allowedViewers: allowedViewers ?? this.allowedViewers,
      spotIds: spotIds ?? this.spotIds,
      imageUrl: imageUrl ?? this.imageUrl,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
      respectCount: respectCount ?? this.respectCount,
      viewCount: viewCount ?? this.viewCount,
      shareCount: shareCount ?? this.shareCount,
      respectedBy: respectedBy ?? this.respectedBy,
      followers: followers ?? this.followers,
      collaboratorIds: collaboratorIds ?? this.collaboratorIds,
      memberIds: memberIds ?? this.memberIds,
      userRoles: userRoles ?? this.userRoles,
    );
  }
  
  @override
  List<Object?> get props => [
    id, title, description, category, type, curatorId, createdAt, updatedAt,
    isPublic, moderationLevel, isAgeRestricted, allowedViewers, spotIds,
    imageUrl, tags, metadata, respectCount, viewCount, shareCount,
    respectedBy, followers, collaboratorIds, memberIds, userRoles,
  ];
}
