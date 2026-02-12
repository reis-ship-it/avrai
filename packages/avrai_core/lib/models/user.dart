import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import '../enums/user_enums.dart';

part 'user.g.dart';

@JsonSerializable()
class User extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? displayName;
  final UserRole role;
  final bool isAgeVerified;
  final List<String> followedLists;
  final List<String> curatedLists;
  final List<String> collaboratedLists;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Optional profile fields
  final String? avatarUrl;
  final String? bio;
  final String? location;
  final List<String> tags;
  final Map<String, String> expertise; // category -> level
  final List<String> friends;
  final bool? isOnline;
  
  const User({
    required this.id,
    required this.email,
    required this.name,
    this.displayName,
    required this.role,
    this.isAgeVerified = false,
    this.followedLists = const [],
    this.curatedLists = const [],
    this.collaboratedLists = const [],
    required this.createdAt,
    required this.updatedAt,
    this.avatarUrl,
    this.bio,
    this.location,
    this.tags = const [],
    this.expertise = const {},
    this.friends = const [],
    this.isOnline,
  });
  
  /// Calculate total list involvement for user engagement metrics
  int get totalListInvolvement => 
      followedLists.length + curatedLists.length + collaboratedLists.length;
  
  /// Check if user can access age-restricted content
  bool canAccessAgeRestrictedContent() => 
      isAgeVerified && role != UserRole.follower;
  
  /// Check if user has any administrative privileges
  bool get hasAdminPrivileges => 
      role == UserRole.admin || role == UserRole.curator;
  
  /// Get user's effective display name
  String get effectiveDisplayName => displayName ?? name;
  
  /// Check if user profile is complete
  bool get isProfileComplete => 
      name.isNotEmpty && email.isNotEmpty && bio != null && location != null;
  
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
  
  User copyWith({
    String? id,
    String? email,
    String? name,
    String? displayName,
    UserRole? role,
    bool? isAgeVerified,
    List<String>? followedLists,
    List<String>? curatedLists,
    List<String>? collaboratedLists,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? avatarUrl,
    String? bio,
    String? location,
    List<String>? tags,
    Map<String, String>? expertise,
    List<String>? friends,
    bool? isOnline,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      isAgeVerified: isAgeVerified ?? this.isAgeVerified,
      followedLists: followedLists ?? this.followedLists,
      curatedLists: curatedLists ?? this.curatedLists,
      collaboratedLists: collaboratedLists ?? this.collaboratedLists,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      tags: tags ?? this.tags,
      expertise: expertise ?? this.expertise,
      friends: friends ?? this.friends,
      isOnline: isOnline ?? this.isOnline,
    );
  }
  
  @override
  List<Object?> get props => [
    id, email, name, displayName, role, isAgeVerified,
    followedLists, curatedLists, collaboratedLists,
    createdAt, updatedAt, avatarUrl, bio, location,
    tags, expertise, friends, isOnline,
  ];
}
