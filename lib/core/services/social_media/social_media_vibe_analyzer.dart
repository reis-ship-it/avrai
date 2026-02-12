import 'dart:developer' as developer;

/// SocialMediaVibeAnalyzer
/// 
/// Analyzes social media profiles, follows, and connections to extract personality insights.
/// Converts social media data into personality dimension values.
/// 
/// Supports multiple platforms: Google, Instagram, Facebook, Twitter
class SocialMediaVibeAnalyzer {
  static const String _logName = 'SocialMediaVibeAnalyzer';
  
  /// Analyze social media profile for personality insights
  /// 
  /// [profileData] - User's profile data from the platform
  /// [follows] - List of accounts the user follows
  /// [connections] - List of user's connections/friends
  /// [platform] - Platform name (google, instagram, facebook, twitter)
  /// 
  /// Returns a map of personality dimension names to values (0.0-1.0)
  Future<Map<String, double>> analyzeProfileForVibe({
    required Map<String, dynamic> profileData,
    required List<Map<String, dynamic>> follows,
    required List<Map<String, dynamic>> connections,
    required String platform,
  }) async {
    try {
      developer.log(
        'Analyzing $platform profile for vibe insights',
        name: _logName,
      );
      
      final insights = <String, double>{};
      
      // Platform-specific analysis
      switch (platform.toLowerCase()) {
        case 'google':
          insights.addAll(await analyzeGoogleProfileForVibe(
            profileData: profileData,
            savedPlaces: profileData['savedPlaces'] as List<Map<String, dynamic>>? ?? [],
            reviews: profileData['reviews'] as List<Map<String, dynamic>>? ?? [],
            photos: profileData['photos'] as List<Map<String, dynamic>>? ?? [],
            locationHistory: profileData['locationHistory'] as String?,
          ));
          break;
        case 'instagram':
          insights.addAll(await analyzeInstagramProfileForVibe(
            profileData: profileData,
            follows: follows,
            connections: connections,
          ));
          break;
        case 'facebook':
        case 'twitter':
          insights.addAll(_analyzeGenericSocialProfile(
            profileData: profileData,
            follows: follows,
            connections: connections,
            platform: platform,
          ));
          break;
        default:
          developer.log(
            'Unknown platform: $platform, using generic analysis',
            name: _logName,
          );
          insights.addAll(_analyzeGenericSocialProfile(
            profileData: profileData,
            follows: follows,
            connections: connections,
            platform: platform,
          ));
      }
      
      developer.log(
        '✅ Extracted ${insights.length} personality insights from $platform',
        name: _logName,
      );
      
      return insights;
    } catch (e, stackTrace) {
      developer.log(
        'Error analyzing $platform profile: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return {};
    }
  }
  
  /// Analyze Google profile specifically (saved places, reviews, photos)
  /// 
  /// [profileData] - Google profile data
  /// [savedPlaces] - List of saved places from Google Maps
  /// [reviews] - List of Google reviews
  /// [photos] - List of Google photos with location/tags
  /// [locationHistory] - Optional location history data
  /// 
  /// Returns personality insights based on Google-specific data
  Future<Map<String, double>> analyzeGoogleProfileForVibe({
    required Map<String, dynamic> profileData,
    required List<Map<String, dynamic>> savedPlaces,
    required List<Map<String, dynamic>> reviews,
    required List<Map<String, dynamic>> photos,
    String? locationHistory,
  }) async {
    final insights = <String, double>{};
    
    // Analyze saved places
    if (savedPlaces.isNotEmpty) {
      final placeTypes = savedPlaces
          .map((p) => p['type'] as String? ?? '')
          .where((t) => t.isNotEmpty)
          .toList();
      
      // Parks and outdoor places → location adventurousness, exploration
      if (placeTypes.any((t) => t.toLowerCase().contains('park') ||
          t.toLowerCase().contains('hiking') ||
          t.toLowerCase().contains('outdoor'))) {
        insights['location_adventurousness'] = 
            (insights['location_adventurousness'] ?? 0.0) + 0.15;
        insights['exploration_eagerness'] = 
            (insights['exploration_eagerness'] ?? 0.0) + 0.12;
      }
      
      // Cafes and restaurants → curation tendency, authenticity
      if (placeTypes.any((t) => t.toLowerCase().contains('cafe') ||
          t.toLowerCase().contains('restaurant') ||
          t.toLowerCase().contains('food'))) {
        insights['curation_tendency'] = 
            (insights['curation_tendency'] ?? 0.0) + 0.10;
        insights['authenticity_preference'] = 
            (insights['authenticity_preference'] ?? 0.0) + 0.08;
      }
      
      // Multiple saved places → exploration
      if (savedPlaces.length > 5) {
        insights['exploration_eagerness'] = 
            (insights['exploration_eagerness'] ?? 0.0) + 0.10;
        insights['location_adventurousness'] = 
            (insights['location_adventurousness'] ?? 0.0) + 0.08;
      }
    }
    
    // Analyze reviews
    if (reviews.isNotEmpty) {
      final reviewTexts = reviews
          .map((r) => (r['text'] as String? ?? '').toLowerCase())
          .join(' ');
      
      // Authentic experiences → authenticity preference
      if (reviewTexts.contains('authentic') ||
          reviewTexts.contains('genuine') ||
          reviewTexts.contains('local')) {
        insights['authenticity_preference'] = 
            (insights['authenticity_preference'] ?? 0.0) + 0.15;
      }
      
      // High ratings → curation tendency
      final avgRating = reviews
          .map((r) => (r['rating'] as num?)?.toDouble() ?? 0.0)
          .reduce((a, b) => a + b) / reviews.length;
      if (avgRating >= 4.5) {
        insights['curation_tendency'] = 
            (insights['curation_tendency'] ?? 0.0) + 0.10;
      }
    }
    
    // Analyze photos
    if (photos.isNotEmpty) {
      final photoTags = photos
          .expand((p) => (p['tags'] as List?)?.cast<String>() ?? [])
          .map((t) => t.toLowerCase())
          .toList();
      
      // Nature/hiking tags → exploration, location adventurousness
      if (photoTags.contains('nature') || photoTags.contains('hiking')) {
        insights['exploration_eagerness'] = 
            (insights['exploration_eagerness'] ?? 0.0) + 0.12;
        insights['location_adventurousness'] = 
            (insights['location_adventurousness'] ?? 0.0) + 0.10;
      }
      
      // Travel tags → exploration, temporal flexibility
      if (photoTags.contains('travel') || photoTags.contains('adventure')) {
        insights['exploration_eagerness'] = 
            (insights['exploration_eagerness'] ?? 0.0) + 0.15;
        insights['temporal_flexibility'] = 
            (insights['temporal_flexibility'] ?? 0.0) + 0.10;
      }
    }
    
    // Normalize all values to 0.0-1.0 range
    return insights.map((key, value) => MapEntry(key, value.clamp(0.0, 1.0)));
  }
  
  /// Analyze Instagram profile specifically (posts, interests, communities)
  /// 
  /// [profileData] - Instagram profile data
  /// [follows] - Accounts followed
  /// [connections] - Connections/friends
  /// 
  /// Returns personality insights
  Future<Map<String, double>> analyzeInstagramProfileForVibe({
    required Map<String, dynamic> profileData,
    required List<Map<String, dynamic>> follows,
    required List<Map<String, dynamic>> connections,
  }) async {
    final insights = <String, double>{};
    
    // Get profile info
    final profile = profileData['profile'] as Map<String, dynamic>? ?? {};
    // Some integrations provide `bio` at the root; accept either shape.
    final bio = ((profile['bio'] as String?) ?? (profileData['bio'] as String?) ?? '')
        .toLowerCase();
    final posts = profileData['posts'] as List<dynamic>? ?? [];
    final interests = profileData['interests'] as List<dynamic>? ?? [];
    final communities = profileData['communities'] as List<dynamic>? ?? [];
    
    // Analyze media count → curation tendency, exploration
    final mediaCount = (profile['media_count'] as num?)?.toInt() ?? 0;
    if (mediaCount > 100) {
      insights['curation_tendency'] = 0.15;
      insights['exploration_eagerness'] = 0.12;
    } else if (mediaCount > 50) {
      insights['curation_tendency'] = 0.10;
      insights['exploration_eagerness'] = 0.08;
    }
    
    // Analyze interests from parsed data
    if (interests.contains('travel') || interests.contains('adventure')) {
      insights['exploration_eagerness'] = (insights['exploration_eagerness'] ?? 0.0) + 0.15;
      insights['location_adventurousness'] = (insights['location_adventurousness'] ?? 0.0) + 0.12;
      insights['temporal_flexibility'] = (insights['temporal_flexibility'] ?? 0.0) + 0.10;
    }
    
    if (interests.contains('food') || interests.contains('culinary')) {
      insights['curation_tendency'] = (insights['curation_tendency'] ?? 0.0) + 0.12;
      insights['authenticity_preference'] = (insights['authenticity_preference'] ?? 0.0) + 0.10;
    }
    
    if (interests.contains('art') || interests.contains('photography')) {
      insights['curation_tendency'] = (insights['curation_tendency'] ?? 0.0) + 0.10;
      insights['authenticity_preference'] = (insights['authenticity_preference'] ?? 0.0) + 0.08;
    }
    
    if (interests.contains('nature') || interests.contains('outdoor')) {
      insights['location_adventurousness'] = (insights['location_adventurousness'] ?? 0.0) + 0.12;
      insights['exploration_eagerness'] = (insights['exploration_eagerness'] ?? 0.0) + 0.10;
    }

    // Bio keyword fallback (supports lightweight / partial profile payloads).
    if (bio.isNotEmpty) {
      if (bio.contains('explorer') || bio.contains('adventure')) {
        insights['exploration_eagerness'] =
            (insights['exploration_eagerness'] ?? 0.0) + 0.10;
      }
      if (bio.contains('foodie') ||
          bio.contains('coffee') ||
          bio.contains('restaurant') ||
          bio.contains('cafe')) {
        insights['curation_tendency'] =
            (insights['curation_tendency'] ?? 0.0) + 0.10;
      }
    }
    
    // Analyze communities (hashtags) → community orientation
    if (communities.length > 20) {
      insights['community_orientation'] = (insights['community_orientation'] ?? 0.0) + 0.12;
      insights['trust_network_reliance'] = (insights['trust_network_reliance'] ?? 0.0) + 0.10;
    }
    
    // Analyze follows count → social discovery style
    if (follows.length > 500) {
      insights['social_discovery_style'] = (insights['social_discovery_style'] ?? 0.0) + 0.15;
    } else if (follows.length > 200) {
      insights['social_discovery_style'] = (insights['social_discovery_style'] ?? 0.0) + 0.10;
    }
    
    // Analyze post captions for keywords
    for (final post in posts) {
      final caption = (post['caption'] as String? ?? '').toLowerCase();
      if (caption.contains('authentic') || caption.contains('local') || caption.contains('hidden gem')) {
        insights['authenticity_preference'] = (insights['authenticity_preference'] ?? 0.0) + 0.05;
      }
      if (caption.contains('explore') || caption.contains('discover') || caption.contains('adventure')) {
        insights['exploration_eagerness'] = (insights['exploration_eagerness'] ?? 0.0) + 0.05;
      }
    }
    
    // Normalize all values to 0.0-1.0 range
    return insights.map((key, value) => MapEntry(key, value.clamp(0.0, 1.0)));
  }
  
  /// Analyze generic social media profile (Facebook, Twitter)
  /// 
  /// [profileData] - Profile data
  /// [follows] - Accounts followed
  /// [connections] - Connections/friends
  /// [platform] - Platform name
  /// 
  /// Returns personality insights
  Map<String, double> _analyzeGenericSocialProfile({
    required Map<String, dynamic> profileData,
    required List<Map<String, dynamic>> follows,
    required List<Map<String, dynamic>> connections,
    required String platform,
  }) {
    final insights = <String, double>{};
    
    // Analyze follows count → social discovery style
    if (follows.length > 500) {
      insights['social_discovery_style'] = 0.15;
    } else if (follows.length > 200) {
      insights['social_discovery_style'] = 0.10;
    }
    
    // Analyze connections count → community orientation
    if (connections.length > 300) {
      insights['community_orientation'] = 0.12;
      insights['trust_network_reliance'] = 0.10;
    } else if (connections.length > 100) {
      insights['community_orientation'] = 0.08;
    }
    
    // Analyze profile bio/content for keywords
    final bio = (profileData['bio'] as String? ?? '').toLowerCase();
    if (bio.contains('explorer') || bio.contains('adventure')) {
      insights['exploration_eagerness'] = 0.12;
    }
    if (bio.contains('foodie') || bio.contains('coffee')) {
      insights['curation_tendency'] = 0.10;
    }
    
    // Normalize all values to 0.0-1.0 range
    return insights.map((key, value) => MapEntry(key, value.clamp(0.0, 1.0)));
  }
}

