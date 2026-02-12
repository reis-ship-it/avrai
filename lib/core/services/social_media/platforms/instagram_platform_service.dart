import 'dart:convert';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:avrai/core/models/social_media/social_media_connection.dart';
import 'package:avrai/core/services/social_media/base/social_media_platform_service.dart';
import 'package:avrai/core/services/social_media/base/social_media_common_utils.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart';
import 'package:avrai/core/services/infrastructure/logger.dart';
import 'package:avrai/core/config/oauth_config.dart';

/// Instagram platform-specific social media connection service
///
/// Handles OAuth connection and data fetching for Instagram platform.
/// Uses AppAuth for OAuth 2.0 authentication.
class InstagramPlatformService implements SocialMediaPlatformService {
  static const String _logName = 'InstagramPlatformService';
  final AppLogger _logger = const AppLogger(defaultTag: 'SPOTS');
  final StorageService _storageService;
  final SocialMediaCommonUtils _commonUtils;

  // Storage keys
  static const String _connectionsKeyPrefix = 'social_media_connections_';

  @override
  String get platformName => 'instagram';

  InstagramPlatformService({
    required StorageService storageService,
    required SocialMediaCommonUtils commonUtils,
  })  : _storageService = storageService,
        _commonUtils = commonUtils;

  @override
  Future<SocialMediaConnection> connect({
    required String agentId,
    required String userId,
  }) async {
    try {
      const appAuth = FlutterAppAuth();
      final redirectUri = OAuthConfig.getRedirectUri('instagram');

      final result = await appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          OAuthConfig.instagramClientId,
          redirectUri,
          discoveryUrl:
              'https://www.instagram.com/.well-known/openid_configuration',
          scopes: OAuthConfig.instagramScopes,
        ),
      );

      if (result.accessToken == null) {
        throw Exception('Instagram OAuth failed or was cancelled');
      }

      // Fetch user profile
      final profileResponse = await _commonUtils.makeAuthenticatedRequest(
        'https://graph.instagram.com/me?fields=id,username',
        result.accessToken!,
      );

      if (profileResponse == null) {
        throw Exception('Failed to fetch Instagram profile');
      }

      final profileData =
          jsonDecode(profileResponse) as Map<String, dynamic>;
      final now = DateTime.now();
      final connection = SocialMediaConnection(
        agentId: agentId,
        platform: 'instagram',
        platformUserId: profileData['id'] as String,
        platformUsername: profileData['username'] as String?,
        isActive: true,
        createdAt: now,
        lastUpdated: now,
        lastTokenRefresh: now,
        metadata: const {
          'oauth_implemented': true,
        },
      );

      await _saveConnection(agentId, connection);
      await _commonUtils.storeTokens(agentId, 'instagram', {
        'access_token': result.accessToken!,
        'refresh_token': result.refreshToken,
        'id_token': result.idToken,
        'expires_at': result.accessTokenExpirationDateTime?.toIso8601String(),
      });

      return connection;
    } catch (e, stackTrace) {
      _logger.error('❌ Instagram OAuth failed',
          error: e, stackTrace: stackTrace, tag: _logName);
      rethrow;
    }
  }

  @override
  Future<void> disconnect({required String agentId}) async {
    try {
      final connection = await _getConnection(agentId);
      if (connection == null) {
        _logger.warn('⚠️ No connection found for Instagram', tag: _logName);
        return;
      }

      // Mark connection as inactive
      final updatedConnection = connection.copyWith(
        isActive: false,
        lastUpdated: DateTime.now(),
      );

      await _saveConnection(agentId, updatedConnection);
      await _commonUtils.removeTokens(agentId, 'instagram');

      _logger.info('✅ Disconnected from Instagram', tag: _logName);
    } catch (e, stackTrace) {
      _logger.error('❌ Failed to disconnect from Instagram',
          error: e, stackTrace: stackTrace, tag: _logName);
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> fetchProfileData(
    SocialMediaConnection connection,
  ) async {
    try {
      _logger.info('📥 Fetching profile data from Instagram', tag: _logName);

      // Get tokens
      final tokens =
          await _commonUtils.getTokens(connection.agentId, connection.platform);
      if (tokens == null) {
        throw Exception('No tokens found for Instagram');
      }

      final accessToken = tokens['access_token'] as String?;
      if (accessToken == null) {
        throw Exception('No access token found');
      }

      // Check if this is a placeholder connection
      final isPlaceholder = connection.metadata['placeholder'] == true;
      if (isPlaceholder || !OAuthConfig.useRealOAuth) {
        return _getPlaceholderProfileData(connection);
      }

      // Check cache first
      final cacheKey = _commonUtils.getCacheKey(connection.agentId, 'instagram');
      final cachedData = await _commonUtils.getCachedProfileData(cacheKey);
      if (cachedData != null) {
        _logger.info('📦 Using cached Instagram profile data', tag: _logName);
        return cachedData;
      }

      // Fetch user profile from Instagram Graph API with extended fields
      final profileResponse = await _commonUtils.makeAuthenticatedRequest(
        'https://graph.instagram.com/me?fields=id,username,account_type,media_count,followers_count,follows_count',
        accessToken,
      );

      if (profileResponse == null) {
        _logger.warn('Failed to fetch Instagram profile, using placeholder',
            tag: _logName);
        return _getPlaceholderProfileData(connection);
      }

      final profileData =
          jsonDecode(profileResponse) as Map<String, dynamic>;

      // Fetch recent media for interest extraction (if available)
      List<Map<String, dynamic>> recentMedia = [];
      try {
        final mediaResponse = await _commonUtils.makeAuthenticatedRequest(
          'https://graph.instagram.com/me/media?fields=id,caption,media_type,permalink&limit=25',
          accessToken,
        );
        if (mediaResponse != null) {
          final mediaData = jsonDecode(mediaResponse) as Map<String, dynamic>;
          final mediaList = mediaData['data'] as List<dynamic>? ?? [];
          recentMedia =
              mediaList.map((m) => m as Map<String, dynamic>).toList();
        }
      } catch (e) {
        _logger.warn(
            'Could not fetch Instagram media (may require additional permissions): $e',
            tag: _logName);
      }

      // Parse interests from captions and media
      final interests = _parseInstagramInterests(recentMedia);
      final communities = _parseInstagramCommunities(recentMedia);

      final result = {
        'profile': {
          'id': profileData['id'],
          'username': profileData['username'] ?? connection.platformUsername,
          'account_type': profileData['account_type'],
          'media_count': profileData['media_count'],
          'followers_count': profileData['followers_count'],
          'follows_count': profileData['follows_count'],
        },
        'follows': [], // Will be fetched separately via fetchFollows
        'posts': recentMedia,
        'interests': interests,
        'communities': communities,
      };

      // Cache the result
      await _commonUtils.cacheProfileData(cacheKey, result);

      return result;
    } catch (e, stackTrace) {
      _logger.error('❌ Failed to fetch profile data from Instagram',
          error: e, stackTrace: stackTrace, tag: _logName);
      return _getPlaceholderProfileData(connection);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchFollows(
    SocialMediaConnection connection,
  ) async {
    try {
      _logger.info('📥 Fetching follows from Instagram', tag: _logName);

      // Get tokens
      final tokens =
          await _commonUtils.getTokens(connection.agentId, connection.platform);
      if (tokens == null) {
        throw Exception('No tokens found for Instagram');
      }

      final accessToken = tokens['access_token'] as String?;
      if (accessToken == null) {
        throw Exception('No access token found');
      }

      // Check if this is a placeholder connection
      final isPlaceholder = connection.metadata['placeholder'] == true;
      if (isPlaceholder || !OAuthConfig.useRealOAuth) {
        return [];
      }

      // Note: Instagram Graph API has limited access to follows
      final followsResponse = await _commonUtils.makeAuthenticatedRequest(
        'https://graph.instagram.com/me/follows',
        accessToken,
      );

      if (followsResponse == null) {
        _logger.warn(
            'Failed to fetch Instagram follows (may require additional permissions)',
            tag: _logName);
        return [];
      }

      final followsData = jsonDecode(followsResponse) as Map<String, dynamic>;
      final follows = followsData['data'] as List<dynamic>? ?? [];

      return follows
          .map((f) => {
                'id': (f as Map)['id'],
                'username': f['username'],
              })
          .toList();
    } catch (e, stackTrace) {
      _logger.error('❌ Failed to fetch follows from Instagram',
          error: e, stackTrace: stackTrace, tag: _logName);
      return [];
    }
  }

  @override
  Future<bool> refreshToken(SocialMediaConnection connection) async {
    try {
      final tokens =
          await _commonUtils.getTokens(connection.agentId, connection.platform);
      if (tokens == null) {
        return false;
      }

      final refreshToken = tokens['refresh_token'] as String?;
      if (refreshToken == null) {
        _logger.warn('No refresh token available for Instagram', tag: _logName);
        return false;
      }

      // Instagram token refresh endpoint
      final response = await _commonUtils.makeAuthenticatedRequest(
        'https://graph.instagram.com/refresh_access_token?grant_type=ig_refresh_token&access_token=$refreshToken',
        refreshToken,
      );

      if (response != null) {
        final data = jsonDecode(response) as Map<String, dynamic>;
        final newAccessToken = data['access_token'] as String?;
        final expiresIn = data['expires_in'] as int?;

        if (newAccessToken != null) {
          // Update tokens
          await _commonUtils.storeTokens(connection.agentId, connection.platform, {
            'access_token': newAccessToken,
            'refresh_token': refreshToken,
            'expires_at': expiresIn != null
                ? DateTime.now()
                    .add(Duration(seconds: expiresIn))
                    .toIso8601String()
                : null,
          });

          _logger.info('✅ Refreshed Instagram token', tag: _logName);
          return true;
        }
      }

      return false;
    } catch (e, stackTrace) {
      _logger.error('Failed to refresh Instagram token',
          error: e, stackTrace: stackTrace, tag: _logName);
      return false;
    }
  }

  // Private helper methods

  /// Save connection to storage
  Future<void> _saveConnection(
      String agentId, SocialMediaConnection connection) async {
    final key = '$_connectionsKeyPrefix${agentId}_${connection.platform}';
    await _storageService.setObject(key, connection.toJson());
  }

  /// Get connection from storage
  Future<SocialMediaConnection?> _getConnection(String agentId) async {
    final key = '$_connectionsKeyPrefix${agentId}_instagram';
    final data = _storageService.getObject<Map<String, dynamic>>(key);
    if (data == null) return null;
    return SocialMediaConnection.fromJson(data);
  }

  /// Parse interests from Instagram media captions
  List<String> _parseInstagramInterests(List<Map<String, dynamic>> media) {
    final interests = <String>{};
    final interestKeywords = {
      'food': [
        'food',
        'restaurant',
        'cafe',
        'coffee',
        'brunch',
        'dinner',
        'lunch',
        'foodie',
        'culinary'
      ],
      'travel': [
        'travel',
        'trip',
        'vacation',
        'explore',
        'adventure',
        'wanderlust',
        'journey'
      ],
      'art': [
        'art',
        'gallery',
        'museum',
        'exhibition',
        'artist',
        'creative',
        'design'
      ],
      'music': ['music', 'concert', 'live', 'gig', 'festival', 'dj', 'band'],
      'fitness': [
        'fitness',
        'gym',
        'workout',
        'yoga',
        'running',
        'exercise',
        'health'
      ],
      'nature': [
        'nature',
        'outdoor',
        'hiking',
        'camping',
        'park',
        'beach',
        'mountain'
      ],
      'fashion': [
        'fashion',
        'style',
        'outfit',
        'clothing',
        'shopping',
        'boutique'
      ],
      'photography': [
        'photography',
        'photo',
        'camera',
        'shot',
        'picture',
        'photographer'
      ],
    };

    for (final item in media) {
      final caption = (item['caption'] as String? ?? '').toLowerCase();
      for (final entry in interestKeywords.entries) {
        if (entry.value.any((keyword) => caption.contains(keyword))) {
          interests.add(entry.key);
        }
      }
    }

    return interests.toList();
  }

  /// Parse communities from Instagram follows and media
  List<String> _parseInstagramCommunities(List<Map<String, dynamic>> media) {
    final communities = <String>{};
    // Extract hashtags from captions as communities
    for (final item in media) {
      final caption = item['caption'] as String? ?? '';
      final hashtags = RegExp(r'#(\w+)').allMatches(caption);
      for (final match in hashtags) {
        communities.add(match.group(1)!.toLowerCase());
      }
    }
    return communities.toList();
  }

  /// Get placeholder profile data (for development/testing)
  Map<String, dynamic> _getPlaceholderProfileData(
      SocialMediaConnection connection) {
    return {
      'profile': {
        'name':
            connection.platformUsername ?? '${connection.platform} User',
        'username': connection.platformUsername,
      },
      'follows': [],
      'posts': [],
    };
  }
}
