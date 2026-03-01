import 'package:avrai_core/models/social_media/social_media_connection.dart';
import 'package:avrai_runtime_os/services/social_media/social_media_connection_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Social Media Sharing Service
///
/// Handles sharing places, lists, and experiences to social media platforms.
/// Uses agentId for privacy protection (not userId).
///
/// **Privacy:** All sharing operations are keyed by agentId, not userId.
/// **User Control:** User chooses what to share and to which platforms.
class SocialMediaSharingService {
  static const String _logName = 'SocialMediaSharingService';
  final AppLogger _logger = const AppLogger(defaultTag: 'SPOTS');
  final SocialMediaConnectionService _connectionService;

  SocialMediaSharingService({
    required SocialMediaConnectionService connectionService,
  }) : _connectionService = connectionService;

  /// Share a place to social media platforms
  ///
  /// **Flow:**
  /// 1. Get active connections for selected platforms
  /// 2. Format place data for each platform
  /// 3. Post to each platform's API
  /// 4. Track sharing success/failure
  ///
  /// **Parameters:**
  /// - `agentId`: Privacy-protected agent identifier
  /// - `userId`: User identifier for service lookup
  /// - `placeId`: Place/Spot ID to share
  /// - `placeName`: Place name
  /// - `placeDescription`: Place description
  /// - `placeLocation`: Place location (address or coordinates)
  /// - `placeImageUrl`: Optional place image URL
  /// - `platforms`: List of platform names to share to
  ///
  /// **Returns:**
  /// Map of platform → success status
  Future<Map<String, bool>> sharePlace({
    required String agentId,
    required String userId,
    required String placeId,
    required String placeName,
    String? placeDescription,
    String? placeLocation,
    String? placeImageUrl,
    required List<String> platforms,
  }) async {
    final results = <String, bool>{};

    try {
      _logger.info('📤 Sharing place to ${platforms.length} platform(s)',
          tag: _logName);

      // Get active connections for requested platforms
      final connections = await _connectionService.getActiveConnections(userId);
      final activeConnections =
          connections.where((c) => platforms.contains(c.platform)).toList();

      if (activeConnections.isEmpty) {
        _logger.warn('No active connections for requested platforms',
            tag: _logName);
        return results;
      }

      // Share to each platform
      for (final connection in activeConnections) {
        try {
          final success = await _sharePlaceToPlatform(
            connection: connection,
            placeId: placeId,
            placeName: placeName,
            placeDescription: placeDescription,
            placeLocation: placeLocation,
            placeImageUrl: placeImageUrl,
          );
          results[connection.platform] = success;
        } catch (e) {
          _logger.warn('Failed to share to ${connection.platform}: $e',
              tag: _logName);
          results[connection.platform] = false;
        }
      }

      _logger.info(
          '✅ Shared place to ${results.values.where((v) => v).length}/${results.length} platform(s)',
          tag: _logName);
      return results;
    } catch (e, stackTrace) {
      _logger.error('❌ Failed to share place',
          error: e, stackTrace: stackTrace, tag: _logName);
      return results;
    }
  }

  /// Share a list to social media platforms
  ///
  /// **Parameters:**
  /// - `agentId`: Privacy-protected agent identifier
  /// - `userId`: User identifier for service lookup
  /// - `listId`: List ID to share
  /// - `listName`: List name
  /// - `listDescription`: List description
  /// - `spotCount`: Number of spots in list
  /// - `platforms`: List of platform names to share to
  ///
  /// **Returns:**
  /// Map of platform → success status
  Future<Map<String, bool>> shareList({
    required String agentId,
    required String userId,
    required String listId,
    required String listName,
    String? listDescription,
    int? spotCount,
    required List<String> platforms,
  }) async {
    final results = <String, bool>{};

    try {
      _logger.info('📤 Sharing list to ${platforms.length} platform(s)',
          tag: _logName);

      // Get active connections for requested platforms
      final connections = await _connectionService.getActiveConnections(userId);
      final activeConnections =
          connections.where((c) => platforms.contains(c.platform)).toList();

      if (activeConnections.isEmpty) {
        _logger.warn('No active connections for requested platforms',
            tag: _logName);
        return results;
      }

      // Share to each platform
      for (final connection in activeConnections) {
        try {
          final success = await _shareListToPlatform(
            connection: connection,
            listId: listId,
            listName: listName,
            listDescription: listDescription,
            spotCount: spotCount,
          );
          results[connection.platform] = success;
        } catch (e) {
          _logger.warn('Failed to share to ${connection.platform}: $e',
              tag: _logName);
          results[connection.platform] = false;
        }
      }

      _logger.info(
          '✅ Shared list to ${results.values.where((v) => v).length}/${results.length} platform(s)',
          tag: _logName);
      return results;
    } catch (e, stackTrace) {
      _logger.error('❌ Failed to share list',
          error: e, stackTrace: stackTrace, tag: _logName);
      return results;
    }
  }

  /// Share an experience (photo, story, check-in) to social media platforms
  ///
  /// **Parameters:**
  /// - `agentId`: Privacy-protected agent identifier
  /// - `userId`: User identifier for service lookup
  /// - `experienceId`: Experience ID
  /// - `experienceText`: Experience text/caption
  /// - `experienceImageUrl`: Experience image URL
  /// - `spotName`: Optional spot name where experience occurred
  /// - `platforms`: List of platform names to share to
  ///
  /// **Returns:**
  /// Map of platform → success status
  Future<Map<String, bool>> shareExperience({
    required String agentId,
    required String userId,
    required String experienceId,
    required String experienceText,
    String? experienceImageUrl,
    String? spotName,
    required List<String> platforms,
  }) async {
    final results = <String, bool>{};

    try {
      _logger.info('📤 Sharing experience to ${platforms.length} platform(s)',
          tag: _logName);

      // Get active connections for requested platforms
      final connections = await _connectionService.getActiveConnections(userId);
      final activeConnections =
          connections.where((c) => platforms.contains(c.platform)).toList();

      if (activeConnections.isEmpty) {
        _logger.warn('No active connections for requested platforms',
            tag: _logName);
        return results;
      }

      // Share to each platform
      for (final connection in activeConnections) {
        try {
          final success = await _shareExperienceToPlatform(
            connection: connection,
            experienceId: experienceId,
            experienceText: experienceText,
            experienceImageUrl: experienceImageUrl,
            spotName: spotName,
          );
          results[connection.platform] = success;
        } catch (e) {
          _logger.warn('Failed to share to ${connection.platform}: $e',
              tag: _logName);
          results[connection.platform] = false;
        }
      }

      _logger.info(
          '✅ Shared experience to ${results.values.where((v) => v).length}/${results.length} platform(s)',
          tag: _logName);
      return results;
    } catch (e, stackTrace) {
      _logger.error('❌ Failed to share experience',
          error: e, stackTrace: stackTrace, tag: _logName);
      return results;
    }
  }

  /// Get available platforms for sharing (connected platforms)
  ///
  /// **Parameters:**
  /// - `userId`: User identifier for service lookup
  ///
  /// **Returns:**
  /// List of platform names that are connected and can be used for sharing
  Future<List<String>> getAvailablePlatforms(String userId) async {
    try {
      final connections = await _connectionService.getActiveConnections(userId);
      return connections.map((c) => c.platform).toList();
    } catch (e) {
      _logger.warn('Failed to get available platforms: $e', tag: _logName);
      return [];
    }
  }

  // Private helper methods for platform-specific sharing

  /// Share place to a specific platform
  Future<bool> _sharePlaceToPlatform({
    required SocialMediaConnection connection,
    required String placeId,
    required String placeName,
    String? placeDescription,
    String? placeLocation,
    String? placeImageUrl,
  }) async {
    try {
      // Get access token
      final tokens = await _getTokensForConnection(connection);
      if (tokens == null) {
        throw Exception('No tokens found for ${connection.platform}');
      }

      final accessToken = tokens['access_token'] as String?;
      if (accessToken == null) {
        throw Exception('No access token found');
      }

      // Format message for platform
      final message = _formatPlaceMessage(
        platform: connection.platform,
        placeName: placeName,
        placeDescription: placeDescription,
        placeLocation: placeLocation,
      );

      // Platform-specific sharing
      switch (connection.platform) {
        case 'instagram':
          return await _shareToInstagram(accessToken, message, placeImageUrl);
        case 'facebook':
          return await _shareToFacebook(accessToken, message, placeImageUrl);
        case 'twitter':
          return await _shareToTwitter(accessToken, message, placeImageUrl);
        case 'reddit':
          return await _shareToReddit(accessToken, message, placeImageUrl);
        case 'tumblr':
          return await _shareToTumblr(accessToken, message, placeImageUrl,
              username: connection.platformUsername);
        case 'pinterest':
          return await _shareToPinterest(
              accessToken, message, placeImageUrl, placeName);
        default:
          _logger.warn('Sharing not yet implemented for ${connection.platform}',
              tag: _logName);
          return false;
      }
    } catch (e) {
      _logger.error('Error sharing place to ${connection.platform}: $e',
          tag: _logName);
      return false;
    }
  }

  /// Share list to a specific platform
  Future<bool> _shareListToPlatform({
    required SocialMediaConnection connection,
    required String listId,
    required String listName,
    String? listDescription,
    int? spotCount,
  }) async {
    try {
      // Get access token
      final tokens = await _getTokensForConnection(connection);
      if (tokens == null) {
        throw Exception('No tokens found for ${connection.platform}');
      }

      final accessToken = tokens['access_token'] as String?;
      if (accessToken == null) {
        throw Exception('No access token found');
      }

      // Format message for platform
      final message = _formatListMessage(
        platform: connection.platform,
        listName: listName,
        listDescription: listDescription,
        spotCount: spotCount,
      );

      // Platform-specific sharing
      switch (connection.platform) {
        case 'instagram':
          return await _shareToInstagram(accessToken, message, null);
        case 'facebook':
          return await _shareToFacebook(accessToken, message, null);
        case 'twitter':
          return await _shareToTwitter(accessToken, message, null);
        case 'reddit':
          return await _shareToReddit(accessToken, message, null);
        case 'tumblr':
          return await _shareToTumblr(accessToken, message, null,
              username: connection.platformUsername);
        default:
          _logger.warn('Sharing not yet implemented for ${connection.platform}',
              tag: _logName);
          return false;
      }
    } catch (e) {
      _logger.error('Error sharing list to ${connection.platform}: $e',
          tag: _logName);
      return false;
    }
  }

  /// Share experience to a specific platform
  Future<bool> _shareExperienceToPlatform({
    required SocialMediaConnection connection,
    required String experienceId,
    required String experienceText,
    String? experienceImageUrl,
    String? spotName,
  }) async {
    try {
      // Get access token
      final tokens = await _getTokensForConnection(connection);
      if (tokens == null) {
        throw Exception('No tokens found for ${connection.platform}');
      }

      final accessToken = tokens['access_token'] as String?;
      if (accessToken == null) {
        throw Exception('No access token found');
      }

      // Format message for platform
      final message = _formatExperienceMessage(
        platform: connection.platform,
        experienceText: experienceText,
        spotName: spotName,
      );

      // Platform-specific sharing
      switch (connection.platform) {
        case 'instagram':
          return await _shareToInstagram(
              accessToken, message, experienceImageUrl);
        case 'facebook':
          return await _shareToFacebook(
              accessToken, message, experienceImageUrl);
        case 'twitter':
          return await _shareToTwitter(
              accessToken, message, experienceImageUrl);
        case 'reddit':
          return await _shareToReddit(accessToken, message, experienceImageUrl);
        case 'tumblr':
          return await _shareToTumblr(accessToken, message, experienceImageUrl,
              username: connection.platformUsername);
        default:
          _logger.warn('Sharing not yet implemented for ${connection.platform}',
              tag: _logName);
          return false;
      }
    } catch (e) {
      _logger.error('Error sharing experience to ${connection.platform}: $e',
          tag: _logName);
      return false;
    }
  }

  // Platform-specific sharing implementations

  /// Share to Instagram
  Future<bool> _shareToInstagram(
      String accessToken, String message, String? imageUrl) async {
    try {
      // Instagram Graph API - create media container
      if (imageUrl != null) {
        // Create media container
        final containerResponse = await http.post(
          Uri.parse('https://graph.instagram.com/me/media'),
          headers: {'Authorization': 'Bearer $accessToken'},
          body: {
            'image_url': imageUrl,
            'caption': message,
            'access_token': accessToken,
          },
        );

        if (containerResponse.statusCode != 200) {
          throw Exception('Failed to create Instagram media container');
        }

        final containerData =
            jsonDecode(containerResponse.body) as Map<String, dynamic>;
        final containerId = containerData['id'] as String;

        // Publish media
        final publishResponse = await http.post(
          Uri.parse('https://graph.instagram.com/me/media_publish'),
          headers: {'Authorization': 'Bearer $accessToken'},
          body: {
            'creation_id': containerId,
            'access_token': accessToken,
          },
        );

        return publishResponse.statusCode == 200;
      } else {
        // Text-only post (Instagram Stories or Feed post without image)
        // Note: Instagram API requires images for most posts
        _logger.warn('Instagram sharing requires an image', tag: _logName);
        return false;
      }
    } catch (e) {
      _logger.error('Error sharing to Instagram: $e', tag: _logName);
      return false;
    }
  }

  /// Share to Facebook
  Future<bool> _shareToFacebook(
      String accessToken, String message, String? imageUrl) async {
    try {
      final body = <String, String>{
        'message': message,
        'access_token': accessToken,
      };

      if (imageUrl != null) {
        body['link'] = imageUrl;
      }

      final response = await http.post(
        Uri.parse('https://graph.facebook.com/me/feed'),
        headers: {'Authorization': 'Bearer $accessToken'},
        body: body,
      );

      return response.statusCode == 200;
    } catch (e) {
      _logger.error('Error sharing to Facebook: $e', tag: _logName);
      return false;
    }
  }

  /// Share to Twitter/X
  Future<bool> _shareToTwitter(
      String accessToken, String message, String? imageUrl) async {
    try {
      // Twitter API v2 - create tweet
      final body = <String, dynamic>{
        'text': message,
      };

      if (imageUrl != null) {
        // Note: Twitter requires media upload first, then attach media_id to tweet
        // For now, just include image URL in text
        body['text'] = '$message\n\n$imageUrl';
      }

      final response = await http.post(
        Uri.parse('https://api.twitter.com/2/tweets'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      return response.statusCode == 201;
    } catch (e) {
      _logger.error('Error sharing to Twitter: $e', tag: _logName);
      return false;
    }
  }

  /// Share to Reddit
  Future<bool> _shareToReddit(
      String accessToken, String message, String? imageUrl) async {
    try {
      // Reddit API - submit link or text post
      final body = <String, String>{
        'title': message.split('\n').first, // Use first line as title
        'text': message,
        'kind': imageUrl != null ? 'link' : 'self',
        'sr': 'user', // Post to user's profile
      };

      if (imageUrl != null) {
        body['url'] = imageUrl;
      }

      final response = await http.post(
        Uri.parse('https://oauth.reddit.com/api/submit'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'User-Agent': 'SPOTS/1.0',
        },
        body: body,
      );

      return response.statusCode == 200;
    } catch (e) {
      _logger.error('Error sharing to Reddit: $e', tag: _logName);
      return false;
    }
  }

  /// Share to Tumblr
  Future<bool> _shareToTumblr(
      String accessToken, String message, String? imageUrl,
      {String? username}) async {
    try {
      final body = <String, dynamic>{
        'type': imageUrl != null ? 'photo' : 'text',
        'caption': message,
      };

      if (imageUrl != null) {
        body['source'] = imageUrl;
      }

      // Get username from parameter or use default
      final blogName = username ?? 'default';
      final response = await http.post(
        Uri.parse('https://api.tumblr.com/v2/blog/$blogName/post'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      return response.statusCode == 201;
    } catch (e) {
      _logger.error('Error sharing to Tumblr: $e', tag: _logName);
      return false;
    }
  }

  /// Share to Pinterest
  Future<bool> _shareToPinterest(String accessToken, String message,
      String? imageUrl, String? title) async {
    try {
      if (imageUrl == null) {
        _logger.warn('Pinterest sharing requires an image', tag: _logName);
        return false;
      }

      final body = <String, dynamic>{
        'board_id': 'default', // User's default board
        'note': message,
        'media': {
          'image': {
            'url': imageUrl,
          },
        },
      };

      if (title != null) {
        body['title'] = title;
      }

      final response = await http.post(
        Uri.parse('https://api.pinterest.com/v5/pins'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      return response.statusCode == 201;
    } catch (e) {
      _logger.error('Error sharing to Pinterest: $e', tag: _logName);
      return false;
    }
  }

  // Message formatting helpers

  String _formatPlaceMessage({
    required String platform,
    required String placeName,
    String? placeDescription,
    String? placeLocation,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('📍 $placeName');

    if (placeDescription != null && placeDescription.isNotEmpty) {
      buffer.writeln(placeDescription);
    }

    if (placeLocation != null && placeLocation.isNotEmpty) {
      buffer.writeln('📍 $placeLocation');
    }

    buffer.writeln('\nShared from SPOTS - know you belong.');

    return buffer.toString();
  }

  String _formatListMessage({
    required String platform,
    required String listName,
    String? listDescription,
    int? spotCount,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('📝 $listName');

    if (listDescription != null && listDescription.isNotEmpty) {
      buffer.writeln(listDescription);
    }

    if (spotCount != null) {
      buffer.writeln('$spotCount ${spotCount == 1 ? 'spot' : 'spots'}');
    }

    buffer.writeln('\nShared from SPOTS - know you belong.');

    return buffer.toString();
  }

  String _formatExperienceMessage({
    required String platform,
    required String experienceText,
    String? spotName,
  }) {
    final buffer = StringBuffer();

    if (spotName != null) {
      buffer.writeln('📍 $spotName');
    }

    buffer.writeln(experienceText);
    buffer.writeln('\nShared from SPOTS - know you belong.');

    return buffer.toString();
  }

  /// Get tokens for a connection (helper method)
  /// Uses the connection service's public getAccessTokens method
  Future<Map<String, dynamic>?> _getTokensForConnection(
      SocialMediaConnection connection) async {
    try {
      return await _connectionService.getAccessTokens(
          connection.agentId, connection.platform);
    } catch (e) {
      _logger.error('Error getting tokens: $e', tag: _logName);
      return null;
    }
  }
}
