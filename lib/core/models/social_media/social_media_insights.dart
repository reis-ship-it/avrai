import 'package:equatable/equatable.dart';

/// Social Media Insights Model
///
/// Represents analyzed insights extracted from social media data.
/// Uses agentId for privacy protection (not userId).
///
/// **Privacy:** All insights are keyed by agentId, not userId.
/// **Purpose:** Derived insights only (not raw social media data).
class SocialMediaInsights extends Equatable {
  /// Privacy-protected identifier (not userId)
  final String agentId;
  
  /// Interest scores (interest name → score 0.0-1.0)
  final Map<String, double> interestScores;
  
  /// Community scores (community name → score 0.0-1.0)
  final Map<String, double> communityScores;
  
  /// Extracted interests (from posts, follows, etc.)
  final List<String> extractedInterests;
  
  /// Extracted communities (groups, pages, etc.)
  final List<String> extractedCommunities;
  
  /// Personality dimension updates (dimension → value change)
  /// This is how social media insights affect personality dimensions
  final Map<String, double> dimensionUpdates;
  
  /// When insights were last analyzed
  final DateTime lastAnalyzed;
  
  /// Confidence score in insights (0.0-1.0)
  final double confidenceScore;
  
  /// Analysis metadata
  final Map<String, dynamic> metadata;

  const SocialMediaInsights({
    required this.agentId,
    this.interestScores = const {},
    this.communityScores = const {},
    this.extractedInterests = const [],
    this.extractedCommunities = const [],
    this.dimensionUpdates = const {},
    required this.lastAnalyzed,
    this.confidenceScore = 0.0,
    this.metadata = const {},
  });

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'agentId': agentId,
      'interestScores': interestScores,
      'communityScores': communityScores,
      'extractedInterests': extractedInterests,
      'extractedCommunities': extractedCommunities,
      'dimensionUpdates': dimensionUpdates,
      'lastAnalyzed': lastAnalyzed.toIso8601String(),
      'confidenceScore': confidenceScore,
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory SocialMediaInsights.fromJson(Map<String, dynamic> json) {
    return SocialMediaInsights(
      agentId: json['agentId'] as String,
      interestScores: (json['interestScores'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ??
          const {},
      communityScores: (json['communityScores'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ??
          const {},
      extractedInterests: (json['extractedInterests'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      extractedCommunities: (json['extractedCommunities'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      dimensionUpdates: (json['dimensionUpdates'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ??
          const {},
      lastAnalyzed: DateTime.parse(json['lastAnalyzed'] as String),
      confidenceScore: (json['confidenceScore'] as num?)?.toDouble() ?? 0.0,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
    );
  }

  /// Copy with method
  SocialMediaInsights copyWith({
    String? agentId,
    Map<String, double>? interestScores,
    Map<String, double>? communityScores,
    List<String>? extractedInterests,
    List<String>? extractedCommunities,
    Map<String, double>? dimensionUpdates,
    DateTime? lastAnalyzed,
    double? confidenceScore,
    Map<String, dynamic>? metadata,
  }) {
    return SocialMediaInsights(
      agentId: agentId ?? this.agentId,
      interestScores: interestScores ?? this.interestScores,
      communityScores: communityScores ?? this.communityScores,
      extractedInterests: extractedInterests ?? this.extractedInterests,
      extractedCommunities: extractedCommunities ?? this.extractedCommunities,
      dimensionUpdates: dimensionUpdates ?? this.dimensionUpdates,
      lastAnalyzed: lastAnalyzed ?? this.lastAnalyzed,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        agentId,
        interestScores,
        communityScores,
        extractedInterests,
        extractedCommunities,
        dimensionUpdates,
        lastAnalyzed,
        confidenceScore,
        metadata,
      ];
}
