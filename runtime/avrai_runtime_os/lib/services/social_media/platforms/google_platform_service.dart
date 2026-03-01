import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:avrai_core/models/social_media/social_media_connection.dart';
import 'package:avrai_runtime_os/services/social_media/base/social_media_platform_service.dart';
import 'package:avrai_runtime_os/services/social_media/base/social_media_common_utils.dart';
import 'package:avrai_runtime_os/services/social_media/google_sign_in_bootstrap.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_runtime_os/config/oauth_config.dart';

/// Google platform-specific social media connection service
///
/// Handles OAuth connection and data fetching for Google platform.
/// Uses Google Sign-In SDK for authentication.
class GooglePlatformService implements SocialMediaPlatformService {
  static const String _logName = 'GooglePlatformService';
  final AppLogger _logger = const AppLogger(defaultTag: 'SPOTS');
  final StorageService _storageService;
  final SocialMediaCommonUtils _commonUtils;

  // Storage keys
  static const String _connectionsKeyPrefix = 'social_media_connections_';

  @override
  String get platformName => 'google';

  GooglePlatformService({
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
      await GoogleSignInBootstrap.ensureInitialized(
        clientId: OAuthConfig.googleClientId,
      );

      late final GoogleSignInAccount account;
      try {
        account = await GoogleSignIn.instance.authenticate(
          scopeHint: OAuthConfig.googleScopes,
        );
      } on GoogleSignInException catch (e) {
        if (e.code == GoogleSignInExceptionCode.canceled) {
          throw Exception('Google sign-in cancelled by user');
        }
        rethrow;
      }

      final GoogleSignInAuthentication auth = account.authentication;
      final authz = await account.authorizationClient.authorizeScopes(
        OAuthConfig.googleScopes,
      );

      final now = DateTime.now();
      final connection = SocialMediaConnection(
        agentId: agentId,
        platform: 'google',
        platformUserId: account.id,
        platformUsername: account.displayName ?? account.email,
        isActive: true,
        createdAt: now,
        lastUpdated: now,
        lastTokenRefresh: now,
        metadata: {
          'oauth_implemented': true,
          'email': account.email,
          'photo_url': account.photoUrl,
        },
      );

      await _saveConnection(agentId, connection);
      await _commonUtils.storeTokens(agentId, 'google', {
        'access_token': authz.accessToken,
        'id_token': auth.idToken,
        'refresh_token': null, // Google Sign-In handles refresh internally
        'expires_at': null, // Google Sign-In handles expiration
      });

      return connection;
    } catch (e, stackTrace) {
      _logger.error('❌ Google OAuth failed',
          error: e, stackTrace: stackTrace, tag: _logName);
      rethrow;
    }
  }

  @override
  Future<void> disconnect({required String agentId}) async {
    try {
      final connection = await _getConnection(agentId);
      if (connection == null) {
        _logger.warn('⚠️ No connection found for Google', tag: _logName);
        return;
      }

      // Mark connection as inactive
      final updatedConnection = connection.copyWith(
        isActive: false,
        lastUpdated: DateTime.now(),
      );

      await _saveConnection(agentId, updatedConnection);
      await _commonUtils.removeTokens(agentId, 'google');

      _logger.info('✅ Disconnected from Google', tag: _logName);
    } catch (e, stackTrace) {
      _logger.error('❌ Failed to disconnect from Google',
          error: e, stackTrace: stackTrace, tag: _logName);
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> fetchProfileData(
    SocialMediaConnection connection,
  ) async {
    try {
      _logger.info('📥 Fetching profile data from Google', tag: _logName);

      // Get tokens
      final tokens =
          await _commonUtils.getTokens(connection.agentId, connection.platform);
      if (tokens == null) {
        throw Exception('No tokens found for Google');
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

      // Fetch user profile from Google People API
      final profileResponse = await _commonUtils.makeAuthenticatedRequest(
        'https://people.googleapis.com/v1/people/me?personFields=names,emailAddresses,photos',
        accessToken,
      );

      if (profileResponse == null) {
        _logger.warn('Failed to fetch Google profile, using placeholder',
            tag: _logName);
        return _getPlaceholderProfileData(connection);
      }

      final profileData = jsonDecode(profileResponse) as Map<String, dynamic>;
      final names = profileData['names'] as List<dynamic>?;
      final emails = profileData['emailAddresses'] as List<dynamic>?;
      final photos = profileData['photos'] as List<dynamic>?;

      return {
        'profile': {
          'name': names?.isNotEmpty == true
              ? (names![0] as Map)['displayName']
              : connection.platformUsername,
          'email':
              emails?.isNotEmpty == true ? (emails![0] as Map)['value'] : null,
          'photo':
              photos?.isNotEmpty == true ? (photos![0] as Map)['url'] : null,
        },
        'savedPlaces':
            [], // Will be fetched separately via fetchGooglePlacesData
        'reviews': [], // Will be fetched separately via fetchGooglePlacesData
        'photos': [], // Will be fetched separately via fetchGooglePlacesData
        'locationHistory': null, // Requires additional permissions
      };
    } catch (e, stackTrace) {
      _logger.error('❌ Failed to fetch profile data from Google',
          error: e, stackTrace: stackTrace, tag: _logName);
      return _getPlaceholderProfileData(connection);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchFollows(
    SocialMediaConnection connection,
  ) async {
    // Google doesn't have a "follows" concept like social media platforms
    return [];
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
        _logger.warn('No refresh token available for Google', tag: _logName);
        return false;
      }

      // Google token refresh endpoint
      final response = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': OAuthConfig.googleClientId,
          'refresh_token': refreshToken,
          'grant_type': 'refresh_token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final newAccessToken = data['access_token'] as String?;
        final expiresIn = data['expires_in'] as int?;

        if (newAccessToken != null) {
          // Update tokens
          await _commonUtils
              .storeTokens(connection.agentId, connection.platform, {
            'access_token': newAccessToken,
            'refresh_token': refreshToken, // Refresh token doesn't change
            'expires_at': expiresIn != null
                ? DateTime.now()
                    .add(Duration(seconds: expiresIn))
                    .toIso8601String()
                : null,
          });

          _logger.info('✅ Refreshed Google token', tag: _logName);
          return true;
        }
      }

      return false;
    } catch (e, stackTrace) {
      _logger.error('Failed to refresh Google token',
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
    final key = '$_connectionsKeyPrefix${agentId}_google';
    final data = _storageService.getObject<Map<String, dynamic>>(key);
    if (data == null) return null;
    return SocialMediaConnection.fromJson(data);
  }

  /// Get placeholder profile data (for development/testing)
  Map<String, dynamic> _getPlaceholderProfileData(
      SocialMediaConnection connection) {
    return {
      'profile': {
        'name': connection.platformUsername ?? 'Google User',
        'email': 'user@example.com',
      },
      'savedPlaces': [],
      'reviews': [],
      'photos': [],
      'locationHistory': null,
    };
  }
}
