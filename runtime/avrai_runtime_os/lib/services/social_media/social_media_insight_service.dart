import 'package:avrai_core/models/social_media/social_media_insights.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_runtime_os/services/social_media/social_media_connection_service.dart';
import 'package:avrai_runtime_os/services/social_media/social_media_vibe_analyzer.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_runtime_os/ai/personality_learning.dart';

/// Social Media Insight Service
///
/// Analyzes social media data and generates personality insights.
/// Updates personality profiles based on social media data.
/// Uses agentId for privacy protection (not userId).
///
/// **Privacy:** All insights are keyed by agentId, not userId.
/// **Atomic Timing:** All timestamps use AtomicClockService.
class SocialMediaInsightService {
  static const String _logName = 'SocialMediaInsightService';
  final AppLogger _logger = const AppLogger(defaultTag: 'SPOTS');
  final StorageService _storageService;
  final SocialMediaConnectionService _connectionService;
  final SocialMediaVibeAnalyzer _vibeAnalyzer;
  final AtomicClockService _atomicClock;

  // Storage keys
  static const String _insightsKeyPrefix = 'social_media_insights_';

  SocialMediaInsightService({
    required StorageService storageService,
    required SocialMediaConnectionService connectionService,
    required SocialMediaVibeAnalyzer vibeAnalyzer,
    required AtomicClockService atomicClock,
  })  : _storageService = storageService,
        _connectionService = connectionService,
        _vibeAnalyzer = vibeAnalyzer,
        _atomicClock = atomicClock;

  /// Analyze all connected social media platforms and generate insights
  ///
  /// **Flow:**
  /// 1. Get all active connections for agent
  /// 2. Fetch profile data from each platform
  /// 3. Analyze each platform's data
  /// 4. Aggregate insights across platforms
  /// 5. Map to personality dimensions
  /// 6. Save insights
  ///
  /// **Parameters:**
  /// - `agentId`: Privacy-protected agent identifier
  /// - `userId`: User identifier for service lookup
  ///
  /// **Returns:**
  /// SocialMediaInsights with aggregated personality dimension updates
  Future<SocialMediaInsights> analyzeAllPlatforms({
    required String agentId,
    required String userId,
  }) async {
    try {
      _logger.info(
          '🔍 Analyzing social media for agent: ${agentId.substring(0, 10)}...',
          tag: _logName);

      // Get all active connections
      final connections = await _connectionService.getActiveConnections(userId);
      if (connections.isEmpty) {
        _logger.info('No social media connections found', tag: _logName);
        return await _createEmptyInsights(agentId);
      }

      // Aggregate insights from all platforms
      final allInterestScores = <String, double>{};
      final allCommunityScores = <String, double>{};
      final allExtractedInterests = <String>{};
      final allExtractedCommunities = <String>{};
      final allDimensionUpdates = <String, double>{};
      int totalPlatforms = 0;
      double totalConfidence = 0.0;

      // Analyze each platform
      for (final connection in connections) {
        try {
          _logger.info('Analyzing ${connection.platform}...', tag: _logName);

          // Fetch profile data
          final profileData =
              await _connectionService.fetchProfileData(connection);
          final follows = await _connectionService.fetchFollows(connection);

          // Analyze for vibe insights
          final platformInsights = await _vibeAnalyzer.analyzeProfileForVibe(
            profileData: profileData,
            follows: follows,
            connections: follows, // Use follows as connections
            platform: connection.platform,
          );

          // Extract interests and communities from profile data
          final interests =
              (profileData['interests'] as List<dynamic>?)?.cast<String>() ??
                  [];
          final communities =
              (profileData['communities'] as List<dynamic>?)?.cast<String>() ??
                  [];

          // Aggregate data
          for (final interest in interests) {
            allExtractedInterests.add(interest);
            allInterestScores[interest] =
                (allInterestScores[interest] ?? 0.0) + 1.0;
          }

          for (final community in communities) {
            allExtractedCommunities.add(community);
            allCommunityScores[community] =
                (allCommunityScores[community] ?? 0.0) + 1.0;
          }

          // Aggregate dimension updates (average across platforms)
          platformInsights.forEach((dimension, value) {
            final currentValue = allDimensionUpdates[dimension] ?? 0.0;
            allDimensionUpdates[dimension] =
                (currentValue + value) / (totalPlatforms + 1);
          });

          totalPlatforms++;
          totalConfidence += 0.3; // Each platform adds confidence
        } catch (e) {
          _logger.warn('Failed to analyze ${connection.platform}: $e',
              tag: _logName);
          // Continue with other platforms
        }
      }

      // Normalize interest and community scores
      final normalizedInterestScores = _normalizeScores(allInterestScores);
      final normalizedCommunityScores = _normalizeScores(allCommunityScores);

      // Calculate final confidence (capped at 1.0)
      final confidenceScore =
          (totalConfidence / totalPlatforms).clamp(0.0, 1.0);

      // Get atomic timestamp (for precise timing)
      final atomicTimestamp = await _atomicClock.getAtomicTimestamp();

      // Create insights
      final insights = SocialMediaInsights(
        agentId: agentId,
        interestScores: normalizedInterestScores,
        communityScores: normalizedCommunityScores,
        extractedInterests: allExtractedInterests.toList(),
        extractedCommunities: allExtractedCommunities.toList(),
        dimensionUpdates: allDimensionUpdates,
        lastAnalyzed:
            atomicTimestamp.serverTime, // Use server time from atomic timestamp
        confidenceScore: confidenceScore,
        metadata: {
          'platforms_analyzed': totalPlatforms,
          'total_interests': allExtractedInterests.length,
          'total_communities': allExtractedCommunities.length,
        },
      );

      // Save insights
      await _saveInsights(agentId, insights);

      _logger.info('✅ Generated insights from $totalPlatforms platform(s)',
          tag: _logName);
      return insights;
    } catch (e, stackTrace) {
      _logger.error('❌ Failed to analyze social media',
          error: e, stackTrace: stackTrace, tag: _logName);
      return await _createEmptyInsights(agentId);
    }
  }

  /// Get stored insights for an agent
  Future<SocialMediaInsights?> getInsights(String agentId) async {
    try {
      final key = '$_insightsKeyPrefix$agentId';
      final data = _storageService.getObject<Map<String, dynamic>>(key);
      if (data == null) return null;
      return SocialMediaInsights.fromJson(data);
    } catch (e) {
      _logger.warn('Failed to get insights: $e', tag: _logName);
      return null;
    }
  }

  /// Update personality profile with social media insights
  ///
  /// **Flow:**
  /// 1. Get current insights
  /// 2. Get current personality profile
  /// 3. Apply dimension updates (blended with existing)
  /// 4. Update confidence scores
  /// 5. Save updated profile
  ///
  /// **Parameters:**
  /// - `agentId`: Privacy-protected agent identifier
  /// - `userId`: User identifier for service lookup
  /// - `personalityLearning`: PersonalityLearning service instance
  ///
  /// **Returns:**
  /// Updated PersonalityProfile
  Future<PersonalityProfile> updatePersonalityFromInsights({
    required String agentId,
    required String userId,
    required PersonalityLearning personalityLearning,
  }) async {
    try {
      _logger.info('🔄 Updating personality from social media insights',
          tag: _logName);

      // Get insights
      final insights = await getInsights(agentId);
      if (insights == null || insights.dimensionUpdates.isEmpty) {
        _logger.info('No insights available to apply', tag: _logName);
        // Return current profile if available
        final currentProfile =
            await personalityLearning.getCurrentPersonality(userId);
        return currentProfile ??
            PersonalityProfile.initial(agentId, userId: userId);
      }

      // Get current personality profile
      final currentProfile =
          await personalityLearning.getCurrentPersonality(userId);
      if (currentProfile == null) {
        _logger.warn('No personality profile found, creating initial profile',
            tag: _logName);
        return PersonalityProfile.initial(agentId, userId: userId);
      }

      // Apply dimension updates (blend: 70% existing, 30% social media)
      final blendedDimensions = <String, double>{};
      final blendedConfidence = <String, double>{};

      for (final dimension in currentProfile.dimensions.keys) {
        final existingValue = currentProfile.dimensions[dimension] ?? 0.5;
        final socialValue =
            insights.dimensionUpdates[dimension] ?? existingValue;

        // Blend: 70% existing, 30% social media
        blendedDimensions[dimension] =
            (existingValue * 0.7 + socialValue * 0.3).clamp(0.0, 1.0);

        // Increase confidence based on insights confidence
        final existingConfidence =
            currentProfile.dimensionConfidence[dimension] ?? 0.0;
        final confidenceBoost = insights.confidenceScore * 0.2; // Max 20% boost
        blendedConfidence[dimension] =
            (existingConfidence + confidenceBoost).clamp(0.0, 1.0);
      }

      // Use evolveFromAI2AILearning for social media insights (more appropriate)
      // Create AI2AI learning insight from social media data
      final ai2aiInsight = AI2AILearningInsight(
        type: AI2AIInsightType
            .communityInsight, // Social media is community-based
        dimensionInsights: blendedDimensions,
        learningQuality: insights.confidenceScore,
        timestamp: insights.lastAnalyzed,
      );

      final evolvedProfile = await personalityLearning.evolveFromAI2AILearning(
        userId,
        ai2aiInsight,
      );

      _logger.info('✅ Updated personality from social media insights',
          tag: _logName);
      return evolvedProfile;
    } catch (e, stackTrace) {
      _logger.error('❌ Failed to update personality from insights',
          error: e, stackTrace: stackTrace, tag: _logName);
      // Return current profile or initial profile
      final currentProfile =
          await personalityLearning.getCurrentPersonality(userId);
      return currentProfile ??
          PersonalityProfile.initial(agentId, userId: userId);
    }
  }

  /// Map interests to personality dimensions
  ///
  /// **Mapping Rules:**
  /// - Travel/Adventure → exploration_eagerness, location_adventurousness, temporal_flexibility
  /// - Food/Culinary → curation_tendency, authenticity_preference
  /// - Art/Photography → curation_tendency, authenticity_preference
  /// - Nature/Outdoor → location_adventurousness, exploration_eagerness
  /// - Music → social_discovery_style, community_orientation
  /// - Fitness → energy_preference, location_adventurousness
  Map<String, double> mapInterestsToDimensions(List<String> interests) {
    final dimensionUpdates = <String, double>{};

    for (final interest in interests) {
      final normalized = interest.toLowerCase();

      if (normalized.contains('travel') || normalized.contains('adventure')) {
        dimensionUpdates['exploration_eagerness'] =
            (dimensionUpdates['exploration_eagerness'] ?? 0.0) + 0.15;
        dimensionUpdates['location_adventurousness'] =
            (dimensionUpdates['location_adventurousness'] ?? 0.0) + 0.12;
        dimensionUpdates['temporal_flexibility'] =
            (dimensionUpdates['temporal_flexibility'] ?? 0.0) + 0.10;
      }

      if (normalized.contains('food') ||
          normalized.contains('culinary') ||
          normalized.contains('restaurant')) {
        dimensionUpdates['curation_tendency'] =
            (dimensionUpdates['curation_tendency'] ?? 0.0) + 0.12;
        dimensionUpdates['authenticity_preference'] =
            (dimensionUpdates['authenticity_preference'] ?? 0.0) + 0.10;
      }

      if (normalized.contains('art') ||
          normalized.contains('photography') ||
          normalized.contains('design')) {
        dimensionUpdates['curation_tendency'] =
            (dimensionUpdates['curation_tendency'] ?? 0.0) + 0.10;
        dimensionUpdates['authenticity_preference'] =
            (dimensionUpdates['authenticity_preference'] ?? 0.0) + 0.08;
      }

      if (normalized.contains('nature') ||
          normalized.contains('outdoor') ||
          normalized.contains('hiking')) {
        dimensionUpdates['location_adventurousness'] =
            (dimensionUpdates['location_adventurousness'] ?? 0.0) + 0.12;
        dimensionUpdates['exploration_eagerness'] =
            (dimensionUpdates['exploration_eagerness'] ?? 0.0) + 0.10;
      }

      if (normalized.contains('music') ||
          normalized.contains('concert') ||
          normalized.contains('festival')) {
        dimensionUpdates['social_discovery_style'] =
            (dimensionUpdates['social_discovery_style'] ?? 0.0) + 0.10;
        dimensionUpdates['community_orientation'] =
            (dimensionUpdates['community_orientation'] ?? 0.0) + 0.08;
      }

      if (normalized.contains('fitness') ||
          normalized.contains('gym') ||
          normalized.contains('workout')) {
        dimensionUpdates['energy_preference'] =
            (dimensionUpdates['energy_preference'] ?? 0.0) + 0.10;
        dimensionUpdates['location_adventurousness'] =
            (dimensionUpdates['location_adventurousness'] ?? 0.0) + 0.08;
      }
    }

    // Normalize all values to 0.0-1.0 range
    return dimensionUpdates
        .map((key, value) => MapEntry(key, value.clamp(0.0, 1.0)));
  }

  /// Map communities to community orientation
  ///
  /// **Mapping:**
  /// - Many communities → high community_orientation, trust_network_reliance
  /// - Few communities → lower community_orientation
  Map<String, double> mapCommunitiesToDimensions(List<String> communities) {
    final dimensionUpdates = <String, double>{};

    if (communities.length > 20) {
      dimensionUpdates['community_orientation'] = 0.15;
      dimensionUpdates['trust_network_reliance'] = 0.12;
    } else if (communities.length > 10) {
      dimensionUpdates['community_orientation'] = 0.10;
      dimensionUpdates['trust_network_reliance'] = 0.08;
    } else if (communities.length > 5) {
      dimensionUpdates['community_orientation'] = 0.08;
    }

    return dimensionUpdates;
  }

  /// Map friends/follows to social discovery style
  ///
  /// **Mapping:**
  /// - Many follows → high social_discovery_style
  /// - Few follows → lower social_discovery_style
  Map<String, double> mapFriendsToDimensions(int friendCount) {
    final dimensionUpdates = <String, double>{};

    if (friendCount > 500) {
      dimensionUpdates['social_discovery_style'] = 0.15;
    } else if (friendCount > 200) {
      dimensionUpdates['social_discovery_style'] = 0.10;
    } else if (friendCount > 100) {
      dimensionUpdates['social_discovery_style'] = 0.08;
    }

    return dimensionUpdates;
  }

  // Private helper methods

  /// Normalize scores to 0.0-1.0 range
  Map<String, double> _normalizeScores(Map<String, double> scores) {
    if (scores.isEmpty) return {};

    final maxScore = scores.values.reduce((a, b) => a > b ? a : b);
    if (maxScore == 0.0) return scores;

    return scores
        .map((key, value) => MapEntry(key, (value / maxScore).clamp(0.0, 1.0)));
  }

  /// Create empty insights
  Future<SocialMediaInsights> _createEmptyInsights(String agentId) async {
    final atomicTimestamp = await _atomicClock.getAtomicTimestamp();
    return SocialMediaInsights(
      agentId: agentId,
      lastAnalyzed: atomicTimestamp.serverTime,
      confidenceScore: 0.0,
    );
  }

  /// Save insights to storage
  Future<void> _saveInsights(
      String agentId, SocialMediaInsights insights) async {
    try {
      final key = '$_insightsKeyPrefix$agentId';
      await _storageService.setObject(key, insights.toJson());
    } catch (e) {
      _logger.warn('Failed to save insights: $e', tag: _logName);
    }
  }
}
