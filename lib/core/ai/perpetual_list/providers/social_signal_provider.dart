// Social Signal Provider
//
// Phase 4.6: Social signals for list suggestions
//
// Purpose: Incorporate friend activity and community trends

import 'dart:developer' as developer;

/// Social Signal Provider
///
/// Provides social context for list generation.
/// Incorporates friend activity, community trends, and social recommendations.
///
/// Part of Phase 4.6: Social Signal Integration

class SocialSignalProvider {
  static const String _logName = 'SocialSignalProvider';

  /// Cached social signals
  SocialContext? _cachedContext;
  DateTime? _cacheTime;
  static const Duration _cacheDuration = Duration(minutes: 15);

  SocialSignalProvider();

  /// Get social context for a user
  /// 
  /// Fetches social signals including friend activity, community trends,
  /// and friend recommendations. Results are cached for 15 minutes.
  /// 
  /// **Parameters:**
  /// - [userId]: The user's unique identifier
  /// - [latitude]: Optional current latitude for nearby friend detection
  /// - [longitude]: Optional current longitude for nearby friend detection
  /// 
  /// **Returns:**
  /// [SocialContext] with friend activity and trends, or null on error.
  Future<SocialContext?> getSocialContext({
    required String userId,
    double? latitude,
    double? longitude,
  }) async {
    try {
      // Check cache
      if (_cachedContext != null &&
          _cacheTime != null &&
          DateTime.now().difference(_cacheTime!) < _cacheDuration) {
        return _cachedContext;
      }

      // Fetch social signals
      final signals = await _fetchSocialSignals(userId, latitude, longitude);
      _cachedContext = signals;
      _cacheTime = DateTime.now();

      return signals;
    } catch (e) {
      developer.log('Error getting social context: $e', name: _logName);
      return null;
    }
  }

  /// Fetch social signals (stub - integrates with AI2AI network)
  Future<SocialContext> _fetchSocialSignals(
    String userId,
    double? latitude,
    double? longitude,
  ) async {
    // TODO(Phase 4.6): Integrate with AI2AI network for real signals
    developer.log(
      'Fetching social signals for user: $userId',
      name: _logName,
    );

    // Return empty context for now (will be populated by AI2AI integration)
    return const SocialContext(
      friendRecentPlaces: [],
      communityTrending: [],
      friendRecommendations: [],
      nearbyFriendCount: 0,
      groupActivityLevel: 0.0,
    );
  }

  /// Get category adjustments based on social context
  /// 
  /// Returns a map of category names to score adjustments.
  /// Boosts categories that friends have visited or are trending.
  /// 
  /// **Adjustment factors:**
  /// - Friend recent visits: +0.1 per friend
  /// - Community trending: up to +0.15 based on trend score
  /// - Nearby friends: +0.15 for bars, +0.1 for restaurants/entertainment
  Map<String, double> getCategoryAdjustments(SocialContext context) {
    final adjustments = <String, double>{};

    // Boost categories that friends have visited recently
    for (final place in context.friendRecentPlaces) {
      final category = place.category;
      adjustments[category] = (adjustments[category] ?? 0) + 0.1;
    }

    // Boost trending categories in the community
    for (final trend in context.communityTrending) {
      adjustments[trend.category] = (adjustments[trend.category] ?? 0) + 
          (trend.trendScore * 0.15);
    }

    // If friends are nearby, boost social places
    if (context.nearbyFriendCount > 0) {
      adjustments['bars'] = (adjustments['bars'] ?? 0) + 0.15;
      adjustments['restaurants'] = (adjustments['restaurants'] ?? 0) + 0.1;
      adjustments['entertainment'] = (adjustments['entertainment'] ?? 0) + 0.1;
    }

    return adjustments;
  }

  /// Get place score boost based on friend activity
  double getFriendActivityBoost(String placeId, SocialContext context) {
    // Check if friends have visited this place recently
    final friendVisit = context.friendRecentPlaces.where(
      (p) => p.placeId == placeId,
    );

    if (friendVisit.isEmpty) return 0.0;

    // More friends = higher boost (capped at 0.3)
    return (friendVisit.length * 0.1).clamp(0.0, 0.3);
  }

  /// Check if a place has friend recommendations
  bool hasFriendRecommendation(String placeId, SocialContext context) {
    return context.friendRecommendations.any((r) => r.placeId == placeId);
  }
}

/// Social context for list generation
class SocialContext {
  /// Places recently visited by friends
  final List<FriendPlaceActivity> friendRecentPlaces;

  /// Trending categories in the community
  final List<CommunityTrend> communityTrending;

  /// Explicit recommendations from friends
  final List<FriendRecommendation> friendRecommendations;

  /// Number of friends currently nearby
  final int nearbyFriendCount;

  /// Overall group activity level (0.0 = low, 1.0 = high)
  final double groupActivityLevel;

  const SocialContext({
    required this.friendRecentPlaces,
    required this.communityTrending,
    required this.friendRecommendations,
    required this.nearbyFriendCount,
    required this.groupActivityLevel,
  });
}

/// Friend's recent place activity
class FriendPlaceActivity {
  final String friendId;
  final String friendName;
  final String placeId;
  final String placeName;
  final String category;
  final DateTime visitTime;
  final double? rating;

  const FriendPlaceActivity({
    required this.friendId,
    required this.friendName,
    required this.placeId,
    required this.placeName,
    required this.category,
    required this.visitTime,
    this.rating,
  });
}

/// Community trend data
class CommunityTrend {
  final String category;
  final double trendScore;
  final int visitCount;
  final String? topPlaceId;
  final String? topPlaceName;

  const CommunityTrend({
    required this.category,
    required this.trendScore,
    required this.visitCount,
    this.topPlaceId,
    this.topPlaceName,
  });
}

/// Friend recommendation
class FriendRecommendation {
  final String friendId;
  final String friendName;
  final String placeId;
  final String placeName;
  final String? message;
  final DateTime recommendedAt;

  const FriendRecommendation({
    required this.friendId,
    required this.friendName,
    required this.placeId,
    required this.placeName,
    this.message,
    required this.recommendedAt,
  });
}
