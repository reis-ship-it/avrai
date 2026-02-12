import 'package:equatable/equatable.dart';

/// Social Media Profile Model
///
/// Represents parsed profile data from a social media platform.
/// Uses agentId for privacy protection (not userId).
///
/// **Privacy:** All profiles are keyed by agentId, not userId.
/// **Storage:** Raw data is encrypted and stored locally only.
class SocialMediaProfile extends Equatable {
  /// Connection ID (references SocialMediaConnection)
  final String connectionId;
  
  /// Privacy-protected identifier (not userId)
  final String agentId;
  
  /// Platform name (lowercase): 'instagram', 'facebook', 'twitter', etc.
  final String platform;
  
  /// Platform username
  final String? username;
  
  /// Display name
  final String? displayName;
  
  /// Profile image URL
  final String? profileImageUrl;
  
  /// Extracted interests (from posts, follows, etc.)
  final List<String> interests;
  
  /// Communities (groups, pages, etc.)
  final List<String> communities;
  
  /// Friend IDs (hashed with SHA-256 for privacy)
  final List<String> friends;
  
  /// When profile was last updated
  final DateTime lastUpdated;
  
  /// Raw platform data (encrypted, local only)
  final Map<String, dynamic> rawData;

  const SocialMediaProfile({
    required this.connectionId,
    required this.agentId,
    required this.platform,
    this.username,
    this.displayName,
    this.profileImageUrl,
    this.interests = const [],
    this.communities = const [],
    this.friends = const [],
    required this.lastUpdated,
    this.rawData = const {},
  });

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'connectionId': connectionId,
      'agentId': agentId,
      'platform': platform,
      'username': username,
      'displayName': displayName,
      'profileImageUrl': profileImageUrl,
      'interests': interests,
      'communities': communities,
      'friends': friends,
      'lastUpdated': lastUpdated.toIso8601String(),
      'rawData': rawData,
    };
  }

  /// Create from JSON
  factory SocialMediaProfile.fromJson(Map<String, dynamic> json) {
    return SocialMediaProfile(
      connectionId: json['connectionId'] as String,
      agentId: json['agentId'] as String,
      platform: json['platform'] as String,
      username: json['username'] as String?,
      displayName: json['displayName'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
      interests: (json['interests'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      communities: (json['communities'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      friends: (json['friends'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      rawData: Map<String, dynamic>.from(json['rawData'] as Map? ?? {}),
    );
  }

  /// Copy with method
  SocialMediaProfile copyWith({
    String? connectionId,
    String? agentId,
    String? platform,
    String? username,
    String? displayName,
    String? profileImageUrl,
    List<String>? interests,
    List<String>? communities,
    List<String>? friends,
    DateTime? lastUpdated,
    Map<String, dynamic>? rawData,
  }) {
    return SocialMediaProfile(
      connectionId: connectionId ?? this.connectionId,
      agentId: agentId ?? this.agentId,
      platform: platform ?? this.platform,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      interests: interests ?? this.interests,
      communities: communities ?? this.communities,
      friends: friends ?? this.friends,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      rawData: rawData ?? this.rawData,
    );
  }

  @override
  List<Object?> get props => [
        connectionId,
        agentId,
        platform,
        username,
        displayName,
        profileImageUrl,
        interests,
        communities,
        friends,
        lastUpdated,
        rawData,
      ];
}
