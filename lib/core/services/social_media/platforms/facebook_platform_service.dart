import 'dart:convert';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:avrai/core/models/social_media/social_media_connection.dart';
import 'package:avrai/core/services/social_media/base/social_media_platform_service.dart';
import 'package:avrai/core/services/social_media/base/social_media_common_utils.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart';
import 'package:avrai/core/services/infrastructure/logger.dart';
import 'package:avrai/core/config/oauth_config.dart';

/// Facebook platform-specific social media connection service
///
/// Handles OAuth connection and data fetching for Facebook platform.
/// Uses AppAuth for OAuth 2.0 authentication.
class FacebookPlatformService implements SocialMediaPlatformService {
  static const String _logName = 'FacebookPlatformService';
  final AppLogger _logger = const AppLogger(defaultTag: 'SPOTS');
  final StorageService _storageService;
  final SocialMediaCommonUtils _commonUtils;

  // Storage keys
  static const String _connectionsKeyPrefix = 'social_media_connections_';

  @override
  String get platformName => 'facebook';

  FacebookPlatformService({
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
      final redirectUri = OAuthConfig.getRedirectUri('facebook');

      final result = await appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          OAuthConfig.facebookClientId,
          redirectUri,
          discoveryUrl:
              'https://www.facebook.com/.well-known/openid_configuration',
          scopes: OAuthConfig.facebookScopes,
        ),
      );

      if (result.accessToken == null) {
        throw Exception('Facebook OAuth failed or was cancelled');
      }

      // Fetch user profile
      final profileResponse = await _commonUtils.makeAuthenticatedRequest(
        'https://graph.facebook.com/me?fields=id,name',
        result.accessToken!,
      );

      if (profileResponse == null) {
        throw Exception('Failed to fetch Facebook profile');
      }

      final profileData =
          jsonDecode(profileResponse) as Map<String, dynamic>;
      final now = DateTime.now();
      final connection = SocialMediaConnection(
        agentId: agentId,
        platform: 'facebook',
        platformUserId: profileData['id'] as String,
        platformUsername: profileData['name'] as String?,
        isActive: true,
        createdAt: now,
        lastUpdated: now,
        lastTokenRefresh: now,
        metadata: const {
          'oauth_implemented': true,
        },
      );

      await _saveConnection(agentId, connection);
      await _commonUtils.storeTokens(agentId, 'facebook', {
        'access_token': result.accessToken!,
        'refresh_token': result.refreshToken,
        'id_token': result.idToken,
        'expires_at': result.accessTokenExpirationDateTime?.toIso8601String(),
      });

      return connection;
    } catch (e, stackTrace) {
      _logger.error('❌ Facebook OAuth failed',
          error: e, stackTrace: stackTrace, tag: _logName);
      rethrow;
    }
  }

  @override
  Future<void> disconnect({required String agentId}) async {
    try {
      final connection = await _getConnection(agentId);
      if (connection == null) {
        _logger.warn('⚠️ No connection found for Facebook', tag: _logName);
        return;
      }

      // Mark connection as inactive
      final updatedConnection = connection.copyWith(
        isActive: false,
        lastUpdated: DateTime.now(),
      );

      await _saveConnection(agentId, updatedConnection);
      await _commonUtils.removeTokens(agentId, 'facebook');

      _logger.info('✅ Disconnected from Facebook', tag: _logName);
    } catch (e, stackTrace) {
      _logger.error('❌ Failed to disconnect from Facebook',
          error: e, stackTrace: stackTrace, tag: _logName);
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> fetchProfileData(
    SocialMediaConnection connection,
  ) async {
    try {
      _logger.info('📥 Fetching profile data from Facebook', tag: _logName);

      // Get tokens
      final tokens =
          await _commonUtils.getTokens(connection.agentId, connection.platform);
      if (tokens == null) {
        throw Exception('No tokens found for Facebook');
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

      // Fetch user profile from Facebook Graph API
      final profileResponse = await _commonUtils.makeAuthenticatedRequest(
        'https://graph.facebook.com/me?fields=id,name,email,picture',
        accessToken,
      );

      if (profileResponse == null) {
        _logger.warn('Failed to fetch Facebook profile, using placeholder',
            tag: _logName);
        return _getPlaceholderProfileData(connection);
      }

      final profileData =
          jsonDecode(profileResponse) as Map<String, dynamic>;
      final picture = profileData['picture'] as Map<String, dynamic>?;

      return {
        'profile': {
          'id': profileData['id'],
          'name': profileData['name'] ?? connection.platformUsername,
          'email': profileData['email'],
          'picture': picture?['data']?['url'],
        },
        'friends': [], // Will be fetched separately via fetchFollows
        'pages': [], // Can be fetched if needed
      };
    } catch (e, stackTrace) {
      _logger.error('❌ Failed to fetch profile data from Facebook',
          error: e, stackTrace: stackTrace, tag: _logName);
      return _getPlaceholderProfileData(connection);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchFollows(
    SocialMediaConnection connection,
  ) async {
    try {
      _logger.info('📥 Fetching friends from Facebook', tag: _logName);

      // Get tokens
      final tokens =
          await _commonUtils.getTokens(connection.agentId, connection.platform);
      if (tokens == null) {
        throw Exception('No tokens found for Facebook');
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

      // Note: Facebook Graph API v2.0+ has limited access to friends
      final friendsResponse = await _commonUtils.makeAuthenticatedRequest(
        'https://graph.facebook.com/me/friends',
        accessToken,
      );

      if (friendsResponse == null) {
        _logger.warn(
            'Failed to fetch Facebook friends (may require additional permissions)',
            tag: _logName);
        return [];
      }

      final friendsData = jsonDecode(friendsResponse) as Map<String, dynamic>;
      final friends = friendsData['data'] as List<dynamic>? ?? [];

      return friends
          .map((f) => {
                'id': (f as Map)['id'],
                'name': f['name'],
              })
          .toList();
    } catch (e, stackTrace) {
      _logger.error('❌ Failed to fetch Facebook friends',
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
        _logger.warn('No refresh token available for Facebook', tag: _logName);
        return false;
      }

      // Facebook token refresh endpoint
      final response = await _commonUtils.makeAuthenticatedRequest(
        'https://graph.facebook.com/v18.0/oauth/access_token?grant_type=fb_exchange_token&client_id=${OAuthConfig.facebookClientId}&client_secret=${OAuthConfig.facebookClientSecret}&fb_exchange_token=$refreshToken',
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
            'refresh_token': newAccessToken, // Facebook uses long-lived tokens
            'expires_at': expiresIn != null
                ? DateTime.now()
                    .add(Duration(seconds: expiresIn))
                    .toIso8601String()
                : null,
          });

          _logger.info('✅ Refreshed Facebook token', tag: _logName);
          return true;
        }
      }

      return false;
    } catch (e, stackTrace) {
      _logger.error('Failed to refresh Facebook token',
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
    final key = '$_connectionsKeyPrefix${agentId}_facebook';
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
      'friends': [],
      'pages': [],
    };
  }
}
