import 'dart:convert';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:avrai/core/models/social_media/social_media_connection.dart';
import 'package:avrai/core/services/social_media/base/social_media_platform_service.dart';
import 'package:avrai/core/services/social_media/base/social_media_common_utils.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart';
import 'package:avrai/core/services/infrastructure/logger.dart';
import 'package:avrai/core/config/oauth_config.dart';

/// Twitter/X platform-specific social media connection service
///
/// Handles OAuth connection and data fetching for Twitter platform.
/// Uses AppAuth for OAuth 2.0 authentication with PKCE flow.
class TwitterPlatformService implements SocialMediaPlatformService {
  static const String _logName = 'TwitterPlatformService';
  final AppLogger _logger = const AppLogger(defaultTag: 'SPOTS');
  final StorageService _storageService;
  final SocialMediaCommonUtils _commonUtils;

  // Storage keys
  static const String _connectionsKeyPrefix = 'social_media_connections_';

  @override
  String get platformName => 'twitter';

  TwitterPlatformService({
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
      final redirectUri = OAuthConfig.getRedirectUri('twitter');

      // Twitter OAuth 2.0 uses PKCE flow
      final result = await appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          OAuthConfig.twitterClientId,
          redirectUri,
          discoveryUrl:
              'https://twitter.com/i/oauth2/.well-known/oauth-authorization-server',
          scopes: OAuthConfig.twitterScopes,
        ),
      );

      if (result.accessToken == null) {
        throw Exception('Twitter OAuth failed or was cancelled');
      }

      // Fetch user profile from Twitter API v2
      final profileResponse = await _commonUtils.makeAuthenticatedRequest(
        'https://api.twitter.com/2/users/me?user.fields=id,name,username,profile_image_url',
        result.accessToken!,
      );

      if (profileResponse == null) {
        throw Exception('Failed to fetch Twitter profile');
      }

      final profileData =
          jsonDecode(profileResponse) as Map<String, dynamic>;
      final userData = profileData['data'] as Map<String, dynamic>?;

      if (userData == null) {
        throw Exception('Invalid Twitter profile response');
      }

      final now = DateTime.now();
      final connection = SocialMediaConnection(
        agentId: agentId,
        platform: 'twitter',
        platformUserId: userData['id'] as String?,
        platformUsername: userData['username'] as String?,
        isActive: true,
        createdAt: now,
        lastUpdated: now,
        lastTokenRefresh: now,
        metadata: const {
          'oauth_implemented': true,
        },
      );

      await _saveConnection(agentId, connection);
      await _commonUtils.storeTokens(agentId, 'twitter', {
        'access_token': result.accessToken!,
        'refresh_token': result.refreshToken,
        'id_token': result.idToken,
        'expires_at': result.accessTokenExpirationDateTime?.toIso8601String(),
      });

      return connection;
    } catch (e, stackTrace) {
      _logger.error('❌ Twitter OAuth failed',
          error: e, stackTrace: stackTrace, tag: _logName);
      rethrow;
    }
  }

  @override
  Future<void> disconnect({required String agentId}) async {
    try {
      final connection = await _getConnection(agentId);
      if (connection == null) {
        _logger.warn('⚠️ No connection found for Twitter', tag: _logName);
        return;
      }

      // Mark connection as inactive
      final updatedConnection = connection.copyWith(
        isActive: false,
        lastUpdated: DateTime.now(),
      );

      await _saveConnection(agentId, updatedConnection);
      await _commonUtils.removeTokens(agentId, 'twitter');

      _logger.info('✅ Disconnected from Twitter', tag: _logName);
    } catch (e, stackTrace) {
      _logger.error('❌ Failed to disconnect from Twitter',
          error: e, stackTrace: stackTrace, tag: _logName);
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> fetchProfileData(
    SocialMediaConnection connection,
  ) async {
    try {
      _logger.info('📥 Fetching profile data from Twitter', tag: _logName);

      // Get tokens
      final tokens =
          await _commonUtils.getTokens(connection.agentId, connection.platform);
      if (tokens == null) {
        throw Exception('No tokens found for Twitter');
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

      // Fetch user profile from Twitter API v2
      final profileResponse = await _commonUtils.makeAuthenticatedRequest(
        'https://api.twitter.com/2/users/me?user.fields=id,name,username,profile_image_url,description',
        accessToken,
      );

      if (profileResponse == null) {
        _logger.warn('Failed to fetch Twitter profile, using placeholder',
            tag: _logName);
        return _getPlaceholderProfileData(connection);
      }

      final profileData =
          jsonDecode(profileResponse) as Map<String, dynamic>;
      final userData = profileData['data'] as Map<String, dynamic>?;

      if (userData == null) {
        return _getPlaceholderProfileData(connection);
      }

      return {
        'profile': {
          'id': userData['id'],
          'name': userData['name'] ?? connection.platformUsername,
          'username': userData['username'],
          'profile_image_url': userData['profile_image_url'],
          'description': userData['description'],
        },
        'follows': [], // Will be fetched separately via fetchFollows
        'tweets': [], // Can be fetched if needed for vibe analysis
      };
    } catch (e, stackTrace) {
      _logger.error('❌ Failed to fetch profile data from Twitter',
          error: e, stackTrace: stackTrace, tag: _logName);
      return _getPlaceholderProfileData(connection);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchFollows(
    SocialMediaConnection connection,
  ) async {
    try {
      _logger.info('📥 Fetching follows from Twitter', tag: _logName);

      // Get tokens
      final tokens =
          await _commonUtils.getTokens(connection.agentId, connection.platform);
      if (tokens == null) {
        throw Exception('No tokens found for Twitter');
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

      // Fetch user follows from Twitter API v2
      // Note: This requires 'follows.read' scope
      final followsResponse = await _commonUtils.makeAuthenticatedRequest(
        'https://api.twitter.com/2/users/${connection.platformUserId}/following?max_results=100&user.fields=id,name,username',
        accessToken,
      );

      if (followsResponse == null) {
        _logger.warn(
            'Failed to fetch Twitter follows (may require additional permissions)',
            tag: _logName);
        return [];
      }

      final followsData = jsonDecode(followsResponse) as Map<String, dynamic>;
      final follows = followsData['data'] as List<dynamic>? ?? [];

      return follows.map((f) {
        final follow = f as Map<String, dynamic>;
        return {
          'id': follow['id'],
          'name': follow['name'],
          'username': follow['username'],
        };
      }).toList();
    } catch (e, stackTrace) {
      _logger.error('❌ Failed to fetch follows from Twitter',
          error: e, stackTrace: stackTrace, tag: _logName);
      return [];
    }
  }

  @override
  Future<bool> refreshToken(SocialMediaConnection connection) async {
    // Twitter OAuth 2.0 tokens don't typically need refresh
    // They are long-lived tokens
    _logger.debug('Twitter tokens are long-lived, no refresh needed',
        tag: _logName);
    return false;
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
    final key = '$_connectionsKeyPrefix${agentId}_twitter';
    final data = _storageService.getObject<Map<String, dynamic>>(key);
    if (data == null) return null;
    return SocialMediaConnection.fromJson(data);
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
      'tweets': [],
    };
  }
}
