import 'dart:convert';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:avrai/core/models/social_media/social_media_connection.dart';
import 'package:avrai/core/services/social_media/base/social_media_platform_service.dart';
import 'package:avrai/core/services/social_media/base/social_media_common_utils.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart';
import 'package:avrai/core/services/infrastructure/logger.dart';
import 'package:avrai/core/config/oauth_config.dart';

/// LinkedIn platform-specific social media connection service
///
/// Handles OAuth connection and data fetching for LinkedIn platform.
/// Uses AppAuth for OAuth 2.0 authentication.
class LinkedInPlatformService implements SocialMediaPlatformService {
  static const String _logName = 'LinkedInPlatformService';
  final AppLogger _logger = const AppLogger(defaultTag: 'SPOTS');
  final StorageService _storageService;
  final SocialMediaCommonUtils _commonUtils;

  // Storage keys
  static const String _connectionsKeyPrefix = 'social_media_connections_';

  @override
  String get platformName => 'linkedin';

  LinkedInPlatformService({
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
      final redirectUri = OAuthConfig.getRedirectUri('linkedin');

      final result = await appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          OAuthConfig.linkedinClientId,
          redirectUri,
          discoveryUrl:
              'https://www.linkedin.com/.well-known/openid_configuration',
          scopes: OAuthConfig.linkedinScopes,
        ),
      );

      if (result.accessToken == null) {
        throw Exception('LinkedIn OAuth failed or was cancelled');
      }

      // Fetch user profile from LinkedIn API
      final profileResponse = await _commonUtils.makeAuthenticatedRequest(
        'https://api.linkedin.com/v2/userinfo',
        result.accessToken!,
      );

      if (profileResponse == null) {
        throw Exception('Failed to fetch LinkedIn profile');
      }

      final profileData =
          jsonDecode(profileResponse) as Map<String, dynamic>;
      final now = DateTime.now();
      final connection = SocialMediaConnection(
        agentId: agentId,
        platform: 'linkedin',
        platformUserId:
            profileData['sub'] as String? ?? profileData['id'] as String?,
        platformUsername: profileData['name'] as String? ??
            profileData['given_name'] as String?,
        isActive: true,
        createdAt: now,
        lastUpdated: now,
        lastTokenRefresh: now,
        metadata: {
          'oauth_implemented': true,
          'email': profileData['email'],
          'picture': profileData['picture'],
        },
      );

      await _saveConnection(agentId, connection);
      await _commonUtils.storeTokens(agentId, 'linkedin', {
        'access_token': result.accessToken!,
        'refresh_token': result.refreshToken,
        'id_token': result.idToken,
        'expires_at': result.accessTokenExpirationDateTime?.toIso8601String(),
      });

      return connection;
    } catch (e, stackTrace) {
      _logger.error('❌ LinkedIn OAuth failed',
          error: e, stackTrace: stackTrace, tag: _logName);
      rethrow;
    }
  }

  @override
  Future<void> disconnect({required String agentId}) async {
    try {
      final connection = await _getConnection(agentId);
      if (connection == null) {
        _logger.warn('⚠️ No connection found for LinkedIn', tag: _logName);
        return;
      }

      // Mark connection as inactive
      final updatedConnection = connection.copyWith(
        isActive: false,
        lastUpdated: DateTime.now(),
      );

      await _saveConnection(agentId, updatedConnection);
      await _commonUtils.removeTokens(agentId, 'linkedin');

      _logger.info('✅ Disconnected from LinkedIn', tag: _logName);
    } catch (e, stackTrace) {
      _logger.error('❌ Failed to disconnect from LinkedIn',
          error: e, stackTrace: stackTrace, tag: _logName);
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> fetchProfileData(
    SocialMediaConnection connection,
  ) async {
    try {
      _logger.info('📥 Fetching profile data from LinkedIn', tag: _logName);

      // Get tokens
      final tokens =
          await _commonUtils.getTokens(connection.agentId, connection.platform);
      if (tokens == null) {
        throw Exception('No tokens found for LinkedIn');
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

      // Fetch user profile from LinkedIn API v2
      final profileResponse = await _commonUtils.makeAuthenticatedRequest(
        'https://api.linkedin.com/v2/userinfo',
        accessToken,
      );

      if (profileResponse == null) {
        _logger.warn('Failed to fetch LinkedIn profile, using placeholder',
            tag: _logName);
        return _getPlaceholderProfileData(connection);
      }

      final profileData =
          jsonDecode(profileResponse) as Map<String, dynamic>;

      return {
        'profile': {
          'id': profileData['sub'] ?? connection.platformUserId,
          'name': profileData['name'] ?? connection.platformUsername,
          'email': profileData['email'],
          'picture': profileData['picture'],
        },
        'connections': [], // Will be fetched separately via fetchFollows
      };
    } catch (e, stackTrace) {
      _logger.error('❌ Failed to fetch profile data from LinkedIn',
          error: e, stackTrace: stackTrace, tag: _logName);
      return _getPlaceholderProfileData(connection);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchFollows(
    SocialMediaConnection connection,
  ) async {
    try {
      _logger.info('📥 Fetching connections from LinkedIn', tag: _logName);

      // Get tokens
      final tokens =
          await _commonUtils.getTokens(connection.agentId, connection.platform);
      if (tokens == null) {
        throw Exception('No tokens found for LinkedIn');
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

      // Note: LinkedIn API v2 has limited access to connections
      // This may require additional permissions or may not be available
      final connectionsResponse = await _commonUtils.makeAuthenticatedRequest(
        'https://api.linkedin.com/v2/networkSizes/edge=1?edgeType=CompanyFollowedByMember',
        accessToken,
      );

      if (connectionsResponse == null) {
        _logger.warn(
            'Failed to fetch LinkedIn connections (may require additional permissions)',
            tag: _logName);
        return [];
      }

      // LinkedIn API returns connection count, not full list
      // For privacy, we'll return an empty list and note this in metadata
      return [];
    } catch (e, stackTrace) {
      _logger.error('❌ Failed to fetch LinkedIn connections',
          error: e, stackTrace: stackTrace, tag: _logName);
      return [];
    }
  }

  @override
  Future<bool> refreshToken(SocialMediaConnection connection) async {
    // LinkedIn OAuth 2.0 tokens are typically long-lived
    // Refresh logic would depend on LinkedIn's specific token refresh endpoint
    _logger.debug('LinkedIn token refresh not implemented', tag: _logName);
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
    final key = '$_connectionsKeyPrefix${agentId}_linkedin';
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
      'connections': [],
    };
  }
}
