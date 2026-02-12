import 'package:equatable/equatable.dart';

/// Social Media Connection Model
///
/// Represents a user's connection to a social media platform.
/// Uses agentId for privacy protection (not userId).
///
/// **Privacy:** All connections are keyed by agentId, not userId.
class SocialMediaConnection extends Equatable {
  /// Privacy-protected identifier (not userId)
  final String agentId;
  
  /// Platform name (lowercase): 'google', 'instagram', 'facebook', 'twitter', 'tiktok', 'linkedin'
  final String platform;
  
  /// Platform user ID (from the social media platform)
  final String? platformUserId;
  
  /// Platform username/display name
  final String? platformUsername;
  
  /// Connection status
  final bool isActive;
  
  /// When the connection was created
  final DateTime createdAt;
  
  /// When the connection was last updated
  final DateTime lastUpdated;
  
  /// When tokens were last refreshed
  final DateTime? lastTokenRefresh;
  
  /// Connection metadata (platform-specific data)
  final Map<String, dynamic> metadata;

  const SocialMediaConnection({
    required this.agentId,
    required this.platform,
    this.platformUserId,
    this.platformUsername,
    this.isActive = true,
    required this.createdAt,
    required this.lastUpdated,
    this.lastTokenRefresh,
    this.metadata = const {},
  });

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'agentId': agentId,
      'platform': platform,
      'platformUserId': platformUserId,
      'platformUsername': platformUsername,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'lastTokenRefresh': lastTokenRefresh?.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory SocialMediaConnection.fromJson(Map<String, dynamic> json) {
    return SocialMediaConnection(
      agentId: json['agentId'] as String,
      platform: json['platform'] as String,
      platformUserId: json['platformUserId'] as String?,
      platformUsername: json['platformUsername'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      lastTokenRefresh: json['lastTokenRefresh'] != null
          ? DateTime.parse(json['lastTokenRefresh'] as String)
          : null,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
    );
  }

  /// Copy with method
  SocialMediaConnection copyWith({
    String? agentId,
    String? platform,
    String? platformUserId,
    String? platformUsername,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastUpdated,
    DateTime? lastTokenRefresh,
    Map<String, dynamic>? metadata,
  }) {
    return SocialMediaConnection(
      agentId: agentId ?? this.agentId,
      platform: platform ?? this.platform,
      platformUserId: platformUserId ?? this.platformUserId,
      platformUsername: platformUsername ?? this.platformUsername,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      lastTokenRefresh: lastTokenRefresh ?? this.lastTokenRefresh,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        agentId,
        platform,
        platformUserId,
        platformUsername,
        isActive,
        createdAt,
        lastUpdated,
        lastTokenRefresh,
        metadata,
      ];
}

