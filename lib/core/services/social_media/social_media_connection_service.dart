import 'dart:async';
import 'dart:convert';
import 'package:avrai/core/models/social_media/social_media_connection.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart';
import 'package:avrai/core/services/infrastructure/logger.dart';
import 'package:avrai/core/services/user/agent_id_service.dart';
import 'package:avrai/core/services/social_media/social_media_insight_service.dart';
import 'package:avrai/core/config/oauth_config.dart';
import 'package:avrai/core/services/infrastructure/oauth_deep_link_handler.dart';
import 'package:avrai/core/services/social_media/social_media_service_factory.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:avrai/core/services/social_media/google_sign_in_bootstrap.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:get_it/get_it.dart';

/// Social Media Connection Service
///
/// Manages OAuth connections to social media platforms and fetches user data.
/// Uses agentId for privacy protection (not userId).
///
/// **Privacy:** All connections are keyed by agentId, not userId.
/// **Security:** OAuth tokens are stored securely (encrypted storage recommended for production).
///
/// **Supported Platforms:**
/// - Google (Places API, Profile, Reviews, Photos)
/// - Instagram (Graph API - Profile, Follows, Posts)
/// - Facebook (Graph API - Profile, Friends, Pages)
/// - Twitter (API v2 - Profile, Follows)
/// - TikTok (API - Profile, Follows)
/// - LinkedIn (API - Profile, Connections)
class SocialMediaConnectionService {
  static const String _logName = 'SocialMediaConnectionService';
  final AppLogger _logger = const AppLogger(defaultTag: 'SPOTS');
  final StorageService _storageService;
  final AgentIdService _agentIdService;
  final OAuthDeepLinkHandler _deepLinkHandler;

  /// Secure storage for OAuth tokens and sensitive data.
  ///
  /// Injected to allow test environments to provide an in-memory implementation
  /// (avoids platform channel dependencies / MissingPluginException).
  final FlutterSecureStorage _secureStorage;
  final SocialMediaServiceFactory? _serviceFactory;

  // Storage keys
  static const String _connectionsKeyPrefix = 'social_media_connections_';
  static const String _tokensKeyPrefix =
      'social_media_tokens_'; // Encrypted in production
  static const String _profileCacheKeyPrefix = 'social_media_profile_cache_';
  static const Duration _profileCacheExpiry =
      Duration(days: 7); // Cache profiles for 7 days

  SocialMediaConnectionService(
    this._storageService,
    this._agentIdService,
    this._deepLinkHandler, {
    SocialMediaServiceFactory? serviceFactory,
    FlutterSecureStorage? secureStorage,
  })  : _serviceFactory = serviceFactory,
        _secureStorage = secureStorage ?? const FlutterSecureStorage() {
    // Start listening for OAuth deep links (for AppAuth flows)
    _deepLinkHandler.startListening();
    // Also check for initial deep link (if app was opened via deep link)
    // Note: getInitialLink is async, but we call it here to start the check
    _deepLinkHandler.getInitialLink().catchError((e) {
      _logger.warn('Failed to get initial deep link: $e', tag: _logName);
      return null;
    });
  }

  /// Connect multiple platforms in batch (for onboarding/agent creation)
  ///
  /// **Flow:**
  /// 1. Show user list of available platforms
  /// 2. User selects platforms to connect
  /// 3. Connect each platform sequentially
  /// 4. Return list of successful connections
  ///
  /// **Parameters:**
  /// - `platforms`: List of platform names to connect
  /// - `agentId`: Privacy-protected agent identifier
  /// - `userId`: User identifier for service lookup
  ///
  /// **Returns:**
  /// List of successfully connected platforms
  ///
  /// **Note:** This is only available during onboarding/agent creation
  Future<List<SocialMediaConnection>> connectPlatformsBatch({
    required List<String> platforms,
    required String agentId,
    required String userId,
  }) async {
    final connections = <SocialMediaConnection>[];

    for (final platform in platforms) {
      try {
        _logger.info('🔗 Batch connecting to $platform...', tag: _logName);
        final connection = await connectPlatform(
          platform: platform,
          agentId: agentId,
          userId: userId,
        );
        connections.add(connection);
        _logger.info('✅ Batch connected to $platform', tag: _logName);
      } catch (e) {
        _logger.warn('⚠️ Failed to batch connect to $platform: $e',
            tag: _logName);
        // Continue with other platforms even if one fails
      }
    }

    // Trigger insight analysis after batch completion (non-blocking)
    if (connections.isNotEmpty) {
      _triggerInsightAnalysis(agentId, userId);
    }

    return connections;
  }

  /// Connect a social media platform (runs OAuth flow and stores tokens)
  ///
  /// **Flow:**
  /// 1. Launch OAuth flow for the platform
  /// 2. Receive access token and refresh token
  /// 3. Store tokens securely (encrypted)
  /// 4. Fetch initial profile data
  /// 5. Create SocialMediaConnection record
  /// 6. Save to storage
  ///
  /// **Parameters:**
  /// - `platform`: Platform name ('google', 'instagram', 'facebook', etc.)
  /// - `agentId`: Privacy-protected agent identifier
  /// - `userId`: User identifier for service lookup (used internally, not stored with connection)
  /// - `customOAuthConfig`: Optional custom OAuth config for generic platforms (Uber Eats, Lyft, etc.)
  ///
  /// **Returns:**
  /// SocialMediaConnection record after successful OAuth
  ///
  /// **Throws:**
  /// Exception if OAuth flow fails or platform is not supported
  Future<SocialMediaConnection> connectPlatform({
    required String platform,
    required String agentId,
    required String userId,
    Map<String, dynamic>? customOAuthConfig,
  }) async {
    try {
      _logger.info(
          '🔗 Connecting to $platform for agent: ${agentId.substring(0, 10)}...',
          tag: _logName);
      _logger.debug(
        'OAuth mode: USE_REAL_OAUTH=${OAuthConfig.useRealOAuth}',
        tag: _logName,
      );

      // Normalize platform name
      final normalizedPlatform = platform.toLowerCase();

      // In widget/integration tests, never attempt real OAuth flows.
      // Plugin-backed auth can hang under `flutter test`, and we only need placeholder
      // connection records to validate data flow + privacy (agentId usage).
      if (_isWidgetTestBinding) {
        return await _connectPlaceholder(agentId, normalizedPlatform);
      }

      // Route to appropriate OAuth flow or placeholder
      SocialMediaConnection connection;

      switch (normalizedPlatform) {
        case 'google':
          if (OAuthConfig.isGoogleConfigured) {
            // Try to use platform service if factory is available
            final platformService = _serviceFactory?.getService('google');
            if (platformService != null) {
              connection = await platformService.connect(
                agentId: agentId,
                userId: userId,
              );
            } else {
              // Fallback to legacy implementation
              connection = await _connectGoogle(agentId, userId);
            }
          } else {
            connection = await _connectPlaceholder(agentId, normalizedPlatform);
          }
          break;
        case 'instagram':
          if (OAuthConfig.isInstagramConfigured) {
            final platformService = _serviceFactory?.getService('instagram');
            if (platformService != null) {
              connection = await platformService.connect(
                agentId: agentId,
                userId: userId,
              );
            } else {
              connection = await _connectInstagram(agentId, userId);
            }
          } else {
            connection = await _connectPlaceholder(agentId, normalizedPlatform);
          }
          break;
        case 'facebook':
          if (OAuthConfig.isFacebookConfigured) {
            final platformService = _serviceFactory?.getService('facebook');
            if (platformService != null) {
              connection = await platformService.connect(
                agentId: agentId,
                userId: userId,
              );
            } else {
              connection = await _connectFacebook(agentId, userId);
            }
          } else {
            connection = await _connectPlaceholder(agentId, normalizedPlatform);
          }
          break;
        case 'twitter':
          if (OAuthConfig.isTwitterConfigured) {
            final platformService = _serviceFactory?.getService('twitter');
            if (platformService != null) {
              connection = await platformService.connect(
                agentId: agentId,
                userId: userId,
              );
            } else {
              connection = await _connectTwitter(agentId, userId);
            }
          } else {
            connection = await _connectPlaceholder(agentId, normalizedPlatform);
          }
          break;
        case 'reddit':
          if (OAuthConfig.isRedditConfigured) {
            connection = await _connectReddit(agentId, userId);
          } else {
            connection = await _connectPlaceholder(agentId, normalizedPlatform);
          }
          break;
        case 'tiktok':
          if (OAuthConfig.isTikTokConfigured) {
            connection = await _connectTikTok(agentId, userId);
          } else {
            connection = await _connectPlaceholder(agentId, normalizedPlatform);
          }
          break;
        case 'tumblr':
          if (OAuthConfig.isTumblrConfigured) {
            connection = await _connectTumblr(agentId, userId);
          } else {
            connection = await _connectPlaceholder(agentId, normalizedPlatform);
          }
          break;
        case 'youtube':
          // YouTube uses Google OAuth
          if (OAuthConfig.isGoogleConfigured) {
            connection = await _connectYouTube(agentId, userId);
          } else {
            connection = await _connectPlaceholder(agentId, normalizedPlatform);
          }
          break;
        case 'pinterest':
          if (OAuthConfig.isPinterestConfigured) {
            connection = await _connectPinterest(agentId, userId);
          } else {
            connection = await _connectPlaceholder(agentId, normalizedPlatform);
          }
          break;
        case 'arena':
        case 'are.na':
          if (OAuthConfig.isArenaConfigured) {
            connection = await _connectArena(agentId, userId);
          } else {
            connection = await _connectPlaceholder(agentId, normalizedPlatform);
          }
          break;
        case 'linkedin':
          if (OAuthConfig.isLinkedInConfigured) {
            final platformService = _serviceFactory?.getService('linkedin');
            if (platformService != null) {
              connection = await platformService.connect(
                agentId: agentId,
                userId: userId,
              );
            } else {
              connection = await _connectLinkedIn(agentId, userId);
            }
          } else {
            connection = await _connectPlaceholder(agentId, normalizedPlatform);
          }
          break;
        default:
          // Generic OAuth for any platform (Uber Eats, Lyft, Airbnb, etc.)
          if (customOAuthConfig != null) {
            connection = await _connectGenericOAuth(
              agentId,
              userId,
              normalizedPlatform,
              customOAuthConfig,
            );
          } else {
            // Use placeholder for unsupported platforms
            connection = await _connectPlaceholder(agentId, normalizedPlatform);
          }
      }

      _logger.info('✅ Connected to $platform successfully', tag: _logName);

      // Trigger automatic insight analysis (non-blocking, fire-and-forget)
      _triggerInsightAnalysis(agentId, userId);

      return connection;
    } catch (e, stackTrace) {
      _logger.error('❌ Failed to connect to $platform',
          error: e, stackTrace: stackTrace, tag: _logName);
      rethrow;
    }
  }

  bool get _isWidgetTestBinding {
    try {
      final bindingType = WidgetsBinding.instance.runtimeType.toString();
      return bindingType.contains('TestWidgetsFlutterBinding') ||
          bindingType.contains('AutomatedTestWidgetsFlutterBinding');
    } catch (_) {
      return false;
    }
  }

  /// Trigger insight analysis after connection (non-blocking)
  ///
  /// This method triggers insight analysis in the background without blocking
  /// the connection flow. Errors are logged but do not affect the connection.
  /// Uses GetIt lazy access to avoid circular dependency.
  void _triggerInsightAnalysis(String agentId, String userId) {
    // Use unawaited to fire-and-forget
    unawaited(_triggerInsightAnalysisAsync(agentId, userId));
  }

  Future<void> _triggerInsightAnalysisAsync(
      String agentId, String userId) async {
    try {
      // Lazy-load insight service via GetIt to avoid circular dependency
      // SocialMediaInsightService depends on SocialMediaConnectionService,
      // so we can't inject it in constructor, but we can access it lazily here
      if (!GetIt.instance.isRegistered<SocialMediaInsightService>()) {
        _logger.debug('Insight service not registered, skipping analysis',
            tag: _logName);
        return;
      }

      final insightService = GetIt.instance<SocialMediaInsightService>();

      _logger.info(
          '🔍 Triggering automatic insight analysis after connection...',
          tag: _logName);
      await insightService.analyzeAllPlatforms(
        agentId: agentId,
        userId: userId,
      );
      _logger.info('✅ Automatic insight analysis completed', tag: _logName);
    } catch (e) {
      _logger.warn('⚠️ Automatic insight analysis failed (non-blocking): $e',
          tag: _logName);
      // Non-blocking - don't throw
    }
  }

  /// Connect to Google using Google Sign-In
  Future<SocialMediaConnection> _connectGoogle(
      String agentId, String userId) async {
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

      await _saveConnection(agentId, 'google', connection);
      await _storeTokens(agentId, 'google', {
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

  /// Connect to Instagram using AppAuth
  Future<SocialMediaConnection> _connectInstagram(
      String agentId, String userId) async {
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
      final profileResponse = await http.get(
        Uri.parse(
            'https://graph.instagram.com/me?fields=id,username&access_token=${result.accessToken}'),
      );

      if (profileResponse.statusCode != 200) {
        throw Exception('Failed to fetch Instagram profile');
      }

      final profileData =
          jsonDecode(profileResponse.body) as Map<String, dynamic>;
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

      await _saveConnection(agentId, 'instagram', connection);
      await _storeTokens(agentId, 'instagram', {
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

  /// Connect to Twitter/X using OAuth 2.0
  Future<SocialMediaConnection> _connectTwitter(
      String agentId, String userId) async {
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
      final profileResponse = await http.get(
        Uri.parse(
            'https://api.twitter.com/2/users/me?user.fields=id,name,username,profile_image_url'),
        headers: {'Authorization': 'Bearer ${result.accessToken}'},
      );

      if (profileResponse.statusCode != 200) {
        throw Exception('Failed to fetch Twitter profile');
      }

      final profileData =
          jsonDecode(profileResponse.body) as Map<String, dynamic>;
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

      await _saveConnection(agentId, 'twitter', connection);
      await _storeTokens(agentId, 'twitter', {
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

  /// Connect to Facebook using AppAuth
  Future<SocialMediaConnection> _connectFacebook(
      String agentId, String userId) async {
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
      final profileResponse = await http.get(
        Uri.parse(
            'https://graph.facebook.com/me?fields=id,name&access_token=${result.accessToken}'),
      );

      if (profileResponse.statusCode != 200) {
        throw Exception('Failed to fetch Facebook profile');
      }

      final profileData =
          jsonDecode(profileResponse.body) as Map<String, dynamic>;
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

      await _saveConnection(agentId, 'facebook', connection);
      await _storeTokens(agentId, 'facebook', {
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

  /// Connect to Reddit using OAuth 2.0
  Future<SocialMediaConnection> _connectReddit(
      String agentId, String userId) async {
    try {
      const appAuth = FlutterAppAuth();
      final redirectUri = OAuthConfig.getRedirectUri('reddit');

      final result = await appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          OAuthConfig.redditClientId,
          redirectUri,
          discoveryUrl:
              'https://www.reddit.com/.well-known/openid_configuration',
          scopes: OAuthConfig.redditScopes,
        ),
      );

      if (result.accessToken == null) {
        throw Exception('Reddit OAuth failed or was cancelled');
      }

      // Fetch user profile from Reddit API
      final profileResponse = await http.get(
        Uri.parse('https://oauth.reddit.com/api/v1/me'),
        headers: {'Authorization': 'Bearer ${result.accessToken}'},
      );

      if (profileResponse.statusCode != 200) {
        throw Exception('Failed to fetch Reddit profile');
      }

      final profileData =
          jsonDecode(profileResponse.body) as Map<String, dynamic>;
      final now = DateTime.now();
      final connection = SocialMediaConnection(
        agentId: agentId,
        platform: 'reddit',
        platformUserId: profileData['id'] as String?,
        platformUsername: profileData['name'] as String?,
        isActive: true,
        createdAt: now,
        lastUpdated: now,
        lastTokenRefresh: now,
        metadata: const {
          'oauth_implemented': true,
        },
      );

      await _saveConnection(agentId, 'reddit', connection);
      await _storeTokens(agentId, 'reddit', {
        'access_token': result.accessToken!,
        'refresh_token': result.refreshToken,
        'id_token': result.idToken,
        'expires_at': result.accessTokenExpirationDateTime?.toIso8601String(),
      });

      return connection;
    } catch (e, stackTrace) {
      _logger.error('❌ Reddit OAuth failed',
          error: e, stackTrace: stackTrace, tag: _logName);
      rethrow;
    }
  }

  /// Connect to TikTok using OAuth 2.0
  Future<SocialMediaConnection> _connectTikTok(
      String agentId, String userId) async {
    try {
      const appAuth = FlutterAppAuth();
      final redirectUri = OAuthConfig.getRedirectUri('tiktok');

      final result = await appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          OAuthConfig.tiktokClientId,
          redirectUri,
          discoveryUrl:
              'https://www.tiktok.com/.well-known/openid_configuration',
          scopes: OAuthConfig.tiktokScopes,
        ),
      );

      if (result.accessToken == null) {
        throw Exception('TikTok OAuth failed or was cancelled');
      }

      // Fetch user profile from TikTok API
      final profileResponse = await http.get(
        Uri.parse(
            'https://open.tiktokapis.com/v2/user/info/?fields=open_id,union_id,avatar_url,display_name'),
        headers: {'Authorization': 'Bearer ${result.accessToken}'},
      );

      if (profileResponse.statusCode != 200) {
        throw Exception('Failed to fetch TikTok profile');
      }

      final profileData =
          jsonDecode(profileResponse.body) as Map<String, dynamic>;
      final userData = profileData['data']?['user'] as Map<String, dynamic>?;

      if (userData == null) {
        throw Exception('Invalid TikTok profile response');
      }

      final now = DateTime.now();
      final connection = SocialMediaConnection(
        agentId: agentId,
        platform: 'tiktok',
        platformUserId: userData['open_id'] as String?,
        platformUsername: userData['display_name'] as String?,
        isActive: true,
        createdAt: now,
        lastUpdated: now,
        lastTokenRefresh: now,
        metadata: const {
          'oauth_implemented': true,
        },
      );

      await _saveConnection(agentId, 'tiktok', connection);
      await _storeTokens(agentId, 'tiktok', {
        'access_token': result.accessToken!,
        'refresh_token': result.refreshToken,
        'id_token': result.idToken,
        'expires_at': result.accessTokenExpirationDateTime?.toIso8601String(),
      });

      return connection;
    } catch (e, stackTrace) {
      _logger.error('❌ TikTok OAuth failed',
          error: e, stackTrace: stackTrace, tag: _logName);
      rethrow;
    }
  }

  /// Connect to Tumblr using OAuth 2.0
  Future<SocialMediaConnection> _connectTumblr(
      String agentId, String userId) async {
    try {
      const appAuth = FlutterAppAuth();
      final redirectUri = OAuthConfig.getRedirectUri('tumblr');

      final result = await appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          OAuthConfig.tumblrClientId,
          redirectUri,
          discoveryUrl:
              'https://www.tumblr.com/.well-known/openid_configuration',
          scopes: OAuthConfig.tumblrScopes,
        ),
      );

      if (result.accessToken == null) {
        throw Exception('Tumblr OAuth failed or was cancelled');
      }

      // Fetch user profile from Tumblr API
      final profileResponse = await http.get(
        Uri.parse('https://api.tumblr.com/v2/user/info'),
        headers: {'Authorization': 'Bearer ${result.accessToken}'},
      );

      if (profileResponse.statusCode != 200) {
        throw Exception('Failed to fetch Tumblr profile');
      }

      final profileData =
          jsonDecode(profileResponse.body) as Map<String, dynamic>;
      final userData =
          profileData['response']?['user'] as Map<String, dynamic>?;

      if (userData == null) {
        throw Exception('Invalid Tumblr profile response');
      }

      final now = DateTime.now();
      final connection = SocialMediaConnection(
        agentId: agentId,
        platform: 'tumblr',
        platformUserId: userData['name'] as String?,
        platformUsername: userData['name'] as String?,
        isActive: true,
        createdAt: now,
        lastUpdated: now,
        lastTokenRefresh: now,
        metadata: const {
          'oauth_implemented': true,
        },
      );

      await _saveConnection(agentId, 'tumblr', connection);
      await _storeTokens(agentId, 'tumblr', {
        'access_token': result.accessToken!,
        'refresh_token': result.refreshToken,
        'id_token': result.idToken,
        'expires_at': result.accessTokenExpirationDateTime?.toIso8601String(),
      });

      return connection;
    } catch (e, stackTrace) {
      _logger.error('❌ Tumblr OAuth failed',
          error: e, stackTrace: stackTrace, tag: _logName);
      rethrow;
    }
  }

  /// Connect to YouTube (uses Google OAuth)
  Future<SocialMediaConnection> _connectYouTube(
      String agentId, String userId) async {
    try {
      // YouTube uses Google OAuth with YouTube-specific scopes
      await GoogleSignInBootstrap.ensureInitialized(
        clientId: OAuthConfig.googleClientId,
      );

      final scopes = <String>[
        ...OAuthConfig.googleScopes,
        'https://www.googleapis.com/auth/youtube.readonly',
      ];

      late final GoogleSignInAccount account;
      try {
        account = await GoogleSignIn.instance.authenticate(scopeHint: scopes);
      } on GoogleSignInException catch (e) {
        if (e.code == GoogleSignInExceptionCode.canceled) {
          throw Exception('YouTube OAuth cancelled');
        }
        rethrow;
      }

      final auth = account.authentication;
      final authz = await account.authorizationClient.authorizeScopes(scopes);

      // Fetch YouTube channel info
      final channelResponse = await http.get(
        Uri.parse(
            'https://www.googleapis.com/youtube/v3/channels?part=snippet&mine=true'),
        headers: {'Authorization': 'Bearer ${authz.accessToken}'},
      );

      String? channelId;
      String? channelTitle;
      if (channelResponse.statusCode == 200) {
        final channelData =
            jsonDecode(channelResponse.body) as Map<String, dynamic>;
        final items = channelData['items'] as List<dynamic>?;
        if (items != null && items.isNotEmpty) {
          final channel = items[0] as Map<String, dynamic>;
          channelId = channel['id'] as String?;
          final snippet = channel['snippet'] as Map<String, dynamic>?;
          channelTitle = snippet?['title'] as String?;
        }
      }

      final now = DateTime.now();
      final connection = SocialMediaConnection(
        agentId: agentId,
        platform: 'youtube',
        platformUserId: channelId ?? account.id,
        platformUsername: channelTitle ?? account.displayName,
        isActive: true,
        createdAt: now,
        lastUpdated: now,
        lastTokenRefresh: now,
        metadata: const {
          'oauth_implemented': true,
        },
      );

      await _saveConnection(agentId, 'youtube', connection);
      await _storeTokens(agentId, 'youtube', {
        'access_token': authz.accessToken,
        'id_token': auth.idToken,
        'expires_at': null, // Google tokens don't expire easily
      });

      return connection;
    } catch (e, stackTrace) {
      _logger.error('❌ YouTube OAuth failed',
          error: e, stackTrace: stackTrace, tag: _logName);
      rethrow;
    }
  }

  /// Connect to Pinterest using OAuth 2.0
  Future<SocialMediaConnection> _connectPinterest(
      String agentId, String userId) async {
    try {
      const appAuth = FlutterAppAuth();
      final redirectUri = OAuthConfig.getRedirectUri('pinterest');

      final result = await appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          OAuthConfig.pinterestClientId,
          redirectUri,
          discoveryUrl:
              'https://www.pinterest.com/.well-known/openid_configuration',
          scopes: OAuthConfig.pinterestScopes,
        ),
      );

      if (result.accessToken == null) {
        throw Exception('Pinterest OAuth failed or was cancelled');
      }

      // Fetch user profile from Pinterest API
      final profileResponse = await http.get(
        Uri.parse('https://api.pinterest.com/v5/user_account'),
        headers: {'Authorization': 'Bearer ${result.accessToken}'},
      );

      if (profileResponse.statusCode != 200) {
        throw Exception('Failed to fetch Pinterest profile');
      }

      final profileData =
          jsonDecode(profileResponse.body) as Map<String, dynamic>;
      final now = DateTime.now();
      final connection = SocialMediaConnection(
        agentId: agentId,
        platform: 'pinterest',
        platformUserId: profileData['id'] as String?,
        platformUsername: profileData['username'] as String?,
        isActive: true,
        createdAt: now,
        lastUpdated: now,
        lastTokenRefresh: now,
        metadata: const {
          'oauth_implemented': true,
        },
      );

      await _saveConnection(agentId, 'pinterest', connection);
      await _storeTokens(agentId, 'pinterest', {
        'access_token': result.accessToken!,
        'refresh_token': result.refreshToken,
        'id_token': result.idToken,
        'expires_at': result.accessTokenExpirationDateTime?.toIso8601String(),
      });

      return connection;
    } catch (e, stackTrace) {
      _logger.error('❌ Pinterest OAuth failed',
          error: e, stackTrace: stackTrace, tag: _logName);
      rethrow;
    }
  }

  /// Connect to LinkedIn using OAuth 2.0
  Future<SocialMediaConnection> _connectLinkedIn(
      String agentId, String userId) async {
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
      final profileResponse = await http.get(
        Uri.parse('https://api.linkedin.com/v2/userinfo'),
        headers: {'Authorization': 'Bearer ${result.accessToken}'},
      );

      if (profileResponse.statusCode != 200) {
        throw Exception('Failed to fetch LinkedIn profile');
      }

      final profileData =
          jsonDecode(profileResponse.body) as Map<String, dynamic>;
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

      await _saveConnection(agentId, 'linkedin', connection);
      await _storeTokens(agentId, 'linkedin', {
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

  /// Connect to Are.na using OAuth 2.0
  Future<SocialMediaConnection> _connectArena(
      String agentId, String userId) async {
    try {
      const appAuth = FlutterAppAuth();
      final redirectUri = OAuthConfig.getRedirectUri('arena');

      final result = await appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          OAuthConfig.arenaClientId,
          redirectUri,
          discoveryUrl: 'https://www.are.na/.well-known/openid_configuration',
          scopes: OAuthConfig.arenaScopes,
        ),
      );

      if (result.accessToken == null) {
        throw Exception('Are.na OAuth failed or was cancelled');
      }

      // Fetch user profile from Are.na API
      final profileResponse = await http.get(
        Uri.parse('https://api.are.na/v2/me'),
        headers: {'Authorization': 'Bearer ${result.accessToken}'},
      );

      if (profileResponse.statusCode != 200) {
        throw Exception('Failed to fetch Are.na profile');
      }

      final profileData =
          jsonDecode(profileResponse.body) as Map<String, dynamic>;
      final now = DateTime.now();
      final connection = SocialMediaConnection(
        agentId: agentId,
        platform: 'arena',
        platformUserId: profileData['id']?.toString(),
        platformUsername: profileData['username'] as String?,
        isActive: true,
        createdAt: now,
        lastUpdated: now,
        lastTokenRefresh: now,
        metadata: const {
          'oauth_implemented': true,
        },
      );

      await _saveConnection(agentId, 'arena', connection);
      await _storeTokens(agentId, 'arena', {
        'access_token': result.accessToken!,
        'refresh_token': result.refreshToken,
        'id_token': result.idToken,
        'expires_at': result.accessTokenExpirationDateTime?.toIso8601String(),
      });

      return connection;
    } catch (e, stackTrace) {
      _logger.error('❌ Are.na OAuth failed',
          error: e, stackTrace: stackTrace, tag: _logName);
      rethrow;
    }
  }

  /// Connect to any platform using generic OAuth 2.0
  /// For platforms like Uber Eats, Lyft, Airbnb, etc. that support OAuth 2.0
  Future<SocialMediaConnection> _connectGenericOAuth(
    String agentId,
    String userId,
    String platform,
    Map<String, dynamic> oauthConfig,
  ) async {
    try {
      const appAuth = FlutterAppAuth();

      // Extract OAuth config
      final clientId = oauthConfig['client_id'] as String? ?? '';
      final redirectUri = oauthConfig['redirect_uri'] as String? ??
          OAuthConfig.getRedirectUri(platform);
      final discoveryUrl = oauthConfig['discovery_url'] as String?;
      final scopes =
          (oauthConfig['scopes'] as List<dynamic>?)?.cast<String>() ??
              OAuthConfig.getDefaultScopes(platform);

      if (clientId.isEmpty) {
        throw Exception('Generic OAuth requires client_id in config');
      }

      if (discoveryUrl == null || discoveryUrl.isEmpty) {
        throw Exception('Generic OAuth requires discovery_url in config');
      }

      final result = await appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          clientId,
          redirectUri,
          discoveryUrl: discoveryUrl,
          scopes: scopes,
        ),
      );

      if (result.accessToken == null) {
        throw Exception('Generic OAuth failed or was cancelled');
      }

      // Try to fetch user profile if profile endpoint is provided
      String? platformUserId;
      String? platformUsername;

      final profileEndpoint = oauthConfig['profile_endpoint'] as String?;
      if (profileEndpoint != null && profileEndpoint.isNotEmpty) {
        try {
          final profileResponse = await http.get(
            Uri.parse(profileEndpoint),
            headers: {'Authorization': 'Bearer ${result.accessToken}'},
          );

          if (profileResponse.statusCode == 200) {
            final profileData =
                jsonDecode(profileResponse.body) as Map<String, dynamic>;
            // Try common field names for user ID and username
            platformUserId = profileData['id']?.toString() ??
                profileData['user_id']?.toString() ??
                profileData['sub']?.toString();
            platformUsername = profileData['username'] as String? ??
                profileData['name'] as String? ??
                profileData['display_name'] as String?;
          }
        } catch (e) {
          _logger.warn('Could not fetch profile from $profileEndpoint: $e',
              tag: _logName);
        }
      }

      final now = DateTime.now();
      final connection = SocialMediaConnection(
        agentId: agentId,
        platform: platform,
        platformUserId: platformUserId,
        platformUsername: platformUsername,
        isActive: true,
        createdAt: now,
        lastUpdated: now,
        lastTokenRefresh: now,
        metadata: const {
          'oauth_implemented': true,
          'generic_oauth': true,
          'custom_config': true,
        },
      );

      await _saveConnection(agentId, platform, connection);
      await _storeTokens(agentId, platform, {
        'access_token': result.accessToken!,
        'refresh_token': result.refreshToken,
        'id_token': result.idToken,
        'expires_at': result.accessTokenExpirationDateTime?.toIso8601String(),
      });

      return connection;
    } catch (e, stackTrace) {
      _logger.error('❌ Generic OAuth failed for $platform',
          error: e, stackTrace: stackTrace, tag: _logName);
      rethrow;
    }
  }

  /// Create placeholder connection (for development/testing)
  Future<SocialMediaConnection> _connectPlaceholder(
      String agentId, String platform) async {
    // Placeholder connections should be immediate and deterministic. Avoid artificial
    // delays here: `testWidgets` runs in a fake-async zone where `Future.delayed`
    // requires pumping time and can deadlock service-only tests.

    final now = DateTime.now();
    final connection = SocialMediaConnection(
      agentId: agentId,
      platform: platform,
      platformUserId: 'placeholder_${platform}_user_id',
      platformUsername: 'placeholder_${platform}_username',
      isActive: true,
      createdAt: now,
      lastUpdated: now,
      lastTokenRefresh: now,
      metadata: const {
        'oauth_implemented': false,
        'placeholder': true,
      },
    );

    await _saveConnection(agentId, platform, connection);
    await _storeTokens(agentId, platform, {
      'access_token': 'placeholder_access_token',
      'refresh_token': 'placeholder_refresh_token',
      'expires_at': now.add(const Duration(days: 30)).toIso8601String(),
    });

    return connection;
  }

  /// Disconnect a social media platform (removes tokens and connection)
  ///
  /// **Flow:**
  /// 1. Revoke OAuth tokens (if platform supports it)
  /// 2. Remove tokens from storage
  /// 3. Mark connection as inactive
  /// 4. Update storage
  ///
  /// **Parameters:**
  /// - `platform`: Platform name
  /// - `agentId`: Privacy-protected agent identifier
  ///
  /// **Throws:**
  /// Exception if disconnection fails
  Future<void> disconnectPlatform({
    required String platform,
    required String agentId,
  }) async {
    try {
      _logger.info(
          '🔌 Disconnecting from $platform for agent: ${agentId.substring(0, 10)}...',
          tag: _logName);

      final normalizedPlatform = platform.toLowerCase();

      // Only use the platform service when real OAuth is configured.
      //
      // In placeholder mode (default), platform services may rely on timers/platform
      // channels and can deadlock widget/integration tests.
      const isFlutterTest = bool.fromEnvironment('FLUTTER_TEST');
      final isOAuthConfigured = (normalizedPlatform == 'google' &&
              OAuthConfig.isGoogleConfigured) ||
          (normalizedPlatform == 'instagram' &&
              OAuthConfig.isInstagramConfigured) ||
          (normalizedPlatform == 'facebook' &&
              OAuthConfig.isFacebookConfigured) ||
          (normalizedPlatform == 'twitter' && OAuthConfig.isTwitterConfigured);

      if (!isFlutterTest && isOAuthConfigured) {
        final platformService = _serviceFactory?.getService(normalizedPlatform);
        if (platformService != null) {
          await platformService.disconnect(agentId: agentId);
          _logger.info('✅ Disconnected from $platform', tag: _logName);
          return;
        }
      }

      // Fallback to legacy implementation
      // Get existing connection
      final connection = await _getConnection(agentId, normalizedPlatform);
      if (connection == null) {
        _logger.warn('⚠️ No connection found for $platform', tag: _logName);
        return;
      }

      // TODO(Phase 8.2): Revoke OAuth tokens if platform supports it
      // For now, just mark as inactive

      // Mark connection as inactive
      final updatedConnection = connection.copyWith(
        isActive: false,
        lastUpdated: DateTime.now(),
      );

      // Update storage
      await _saveConnection(agentId, normalizedPlatform, updatedConnection);

      // Remove tokens
      await _removeTokens(agentId, normalizedPlatform);

      _logger.info('✅ Disconnected from $platform', tag: _logName);
    } catch (e, stackTrace) {
      _logger.error('❌ Failed to disconnect from $platform',
          error: e, stackTrace: stackTrace, tag: _logName);
      rethrow;
    }
  }

  /// Get active social media connections for a user
  ///
  /// **Parameters:**
  /// - `userId`: User identifier (used to get agentId)
  ///
  /// **Returns:**
  /// List of active SocialMediaConnection records
  Future<List<SocialMediaConnection>> getActiveConnections(
      String userId) async {
    try {
      // Get agentId from userId (via AgentIdService)
      final agentId = await _agentIdService.getUserAgentId(userId);

      // Get all connections for this agent
      final connections = await _getAllConnections(agentId);

      // Filter to active connections only
      return connections.where((conn) => conn.isActive).toList();
    } catch (e, stackTrace) {
      _logger.error('❌ Failed to get active connections',
          error: e, stackTrace: stackTrace, tag: _logName);
      return [];
    }
  }

  /// Fetch profile data from platform
  ///
  /// **Flow:**
  /// 1. Get connection and tokens
  /// 2. Make API call to platform
  /// 3. Parse and return structured data
  ///
  /// **Parameters:**
  /// - `connection`: SocialMediaConnection record
  ///
  /// **Returns:**
  /// Map with profile data (platform-specific structure)
  ///
  /// **Platform-Specific Data:**
  /// - Google: profile, savedPlaces, reviews, photos, locationHistory
  /// - Instagram: profile, follows, posts
  /// - Facebook: profile, friends, pages
  /// - Twitter: profile, follows, tweets
  /// - TikTok: profile, follows, videos
  /// - LinkedIn: profile, connections, posts
  Future<Map<String, dynamic>> fetchProfileData(
    SocialMediaConnection connection,
  ) async {
    try {
      _logger.info('📥 Fetching profile data from ${connection.platform}',
          tag: _logName);

      // Get tokens
      final tokens = await _getTokens(connection.agentId, connection.platform);
      if (tokens == null) {
        throw Exception('No tokens found for ${connection.platform}');
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

      // Route to platform-specific API implementation
      // Try to use platform service if factory is available
      final platformService = _serviceFactory?.getService(connection.platform);
      if (platformService != null) {
        return await platformService.fetchProfileData(connection);
      }

      // Fallback to legacy implementation
      switch (connection.platform) {
        case 'google':
          return await _fetchGoogleProfileData(accessToken, connection);
        case 'instagram':
          return await _fetchInstagramProfileData(accessToken, connection);
        case 'facebook':
          return await _fetchFacebookProfileData(accessToken, connection);
        case 'twitter':
          return await _fetchTwitterProfileData(accessToken, connection);
        case 'linkedin':
          return await _fetchLinkedInProfileData(accessToken, connection);
        default:
          return _getPlaceholderProfileData(connection);
      }
    } catch (e, stackTrace) {
      _logger.error(
          '❌ Failed to fetch profile data from ${connection.platform}',
          error: e,
          stackTrace: stackTrace,
          tag: _logName);
      return {};
    }
  }

  /// Fetch follows/connections from platform
  ///
  /// **Parameters:**
  /// - `connection`: SocialMediaConnection record
  ///
  /// **Returns:**
  /// List of follow/connection data
  Future<List<Map<String, dynamic>>> fetchFollows(
    SocialMediaConnection connection,
  ) async {
    try {
      _logger.info('📥 Fetching follows from ${connection.platform}',
          tag: _logName);

      // Get tokens
      final tokens = await _getTokens(connection.agentId, connection.platform);
      if (tokens == null) {
        throw Exception('No tokens found for ${connection.platform}');
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

      // Route to platform-specific API implementation
      // Try to use platform service if factory is available
      final platformService = _serviceFactory?.getService(connection.platform);
      if (platformService != null) {
        return await platformService.fetchFollows(connection);
      }

      // Fallback to legacy implementation
      switch (connection.platform) {
        case 'instagram':
          return await _fetchInstagramFollows(accessToken, connection);
        case 'facebook':
          return await _fetchFacebookFriends(accessToken, connection);
        case 'twitter':
          return await _fetchTwitterFollows(accessToken, connection);
        case 'linkedin':
          return await _fetchLinkedInConnections(accessToken, connection);
        default:
          return [];
      }
    } catch (e, stackTrace) {
      _logger.error('❌ Failed to fetch follows from ${connection.platform}',
          error: e, stackTrace: stackTrace, tag: _logName);
      return [];
    }
  }

  /// Fetch places/reviews/photos (Google-specific)
  ///
  /// **Parameters:**
  /// - `connection`: SocialMediaConnection record (must be 'google')
  ///
  /// **Returns:**
  /// Map with Google Places data: places, reviews, photos
  Future<Map<String, dynamic>> fetchGooglePlacesData(
    SocialMediaConnection connection,
  ) async {
    try {
      if (connection.platform != 'google') {
        throw Exception('fetchGooglePlacesData only supports Google platform');
      }

      _logger.info('📥 Fetching Google Places data', tag: _logName);

      // Get tokens
      final tokens = await _getTokens(connection.agentId, connection.platform);
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
        return {
          'places': [],
          'reviews': [],
          'photos': [],
        };
      }

      // Fetch real Google Places data
      return await _fetchGooglePlacesDataReal(accessToken, connection);
    } catch (e, stackTrace) {
      _logger.error('❌ Failed to fetch Google Places data',
          error: e, stackTrace: stackTrace, tag: _logName);
      return {
        'places': [],
        'reviews': [],
        'photos': [],
      };
    }
  }

  // Platform-specific API implementations

  /// Fetch Google profile data from Google APIs
  Future<Map<String, dynamic>> _fetchGoogleProfileData(
    String accessToken,
    SocialMediaConnection connection,
  ) async {
    try {
      // Fetch user profile from Google People API
      final profileResponse = await http.get(
        Uri.parse(
            'https://people.googleapis.com/v1/people/me?personFields=names,emailAddresses,photos'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (profileResponse.statusCode != 200) {
        _logger.warn('Failed to fetch Google profile, using placeholder',
            tag: _logName);
        return _getPlaceholderProfileData(connection);
      }

      final profileData =
          jsonDecode(profileResponse.body) as Map<String, dynamic>;
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
      _logger.error('Error fetching Google profile data',
          error: e, stackTrace: stackTrace, tag: _logName);
      return _getPlaceholderProfileData(connection);
    }
  }

  /// Fetch Instagram profile data from Instagram Graph API
  /// Enhanced with caching and more fields
  Future<Map<String, dynamic>> _fetchInstagramProfileData(
    String accessToken,
    SocialMediaConnection connection,
  ) async {
    try {
      // Check cache first
      final cacheKey = '$_profileCacheKeyPrefix${connection.agentId}_instagram';
      final cachedData = await _getCachedProfileData(cacheKey);
      if (cachedData != null) {
        _logger.info('📦 Using cached Instagram profile data', tag: _logName);
        return cachedData;
      }

      // Fetch user profile from Instagram Graph API with extended fields
      // Note: Instagram Graph API fields vary by permissions
      final profileResponse = await http.get(
        Uri.parse(
            'https://graph.instagram.com/me?fields=id,username,account_type,media_count,followers_count,follows_count&access_token=$accessToken'),
      );

      if (profileResponse.statusCode != 200) {
        _logger.warn('Failed to fetch Instagram profile, using placeholder',
            tag: _logName);
        return _getPlaceholderProfileData(connection);
      }

      final profileData =
          jsonDecode(profileResponse.body) as Map<String, dynamic>;

      // Fetch recent media for interest extraction (if available)
      List<Map<String, dynamic>> recentMedia = [];
      try {
        final mediaResponse = await http.get(
          Uri.parse(
              'https://graph.instagram.com/me/media?fields=id,caption,media_type,permalink&limit=25&access_token=$accessToken'),
        );
        if (mediaResponse.statusCode == 200) {
          final mediaData =
              jsonDecode(mediaResponse.body) as Map<String, dynamic>;
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
      await _cacheProfileData(cacheKey, result);

      return result;
    } catch (e, stackTrace) {
      _logger.error('Error fetching Instagram profile data',
          error: e, stackTrace: stackTrace, tag: _logName);
      return _getPlaceholderProfileData(connection);
    }
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

  /// Fetch Facebook profile data from Facebook Graph API
  Future<Map<String, dynamic>> _fetchFacebookProfileData(
    String accessToken,
    SocialMediaConnection connection,
  ) async {
    try {
      // Fetch user profile from Facebook Graph API
      final profileResponse = await http.get(
        Uri.parse(
            'https://graph.facebook.com/me?fields=id,name,email,picture&access_token=$accessToken'),
      );

      if (profileResponse.statusCode != 200) {
        _logger.warn('Failed to fetch Facebook profile, using placeholder',
            tag: _logName);
        return _getPlaceholderProfileData(connection);
      }

      final profileData =
          jsonDecode(profileResponse.body) as Map<String, dynamic>;
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
      _logger.error('Error fetching Facebook profile data',
          error: e, stackTrace: stackTrace, tag: _logName);
      return _getPlaceholderProfileData(connection);
    }
  }

  /// Fetch Twitter profile data from Twitter API v2
  Future<Map<String, dynamic>> _fetchTwitterProfileData(
    String accessToken,
    SocialMediaConnection connection,
  ) async {
    try {
      // Fetch user profile from Twitter API v2
      final profileResponse = await http.get(
        Uri.parse(
            'https://api.twitter.com/2/users/me?user.fields=id,name,username,profile_image_url,description'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (profileResponse.statusCode != 200) {
        _logger.warn('Failed to fetch Twitter profile, using placeholder',
            tag: _logName);
        return _getPlaceholderProfileData(connection);
      }

      final profileData =
          jsonDecode(profileResponse.body) as Map<String, dynamic>;
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
      _logger.error('Error fetching Twitter profile data',
          error: e, stackTrace: stackTrace, tag: _logName);
      return _getPlaceholderProfileData(connection);
    }
  }

  /// Fetch Instagram follows from Instagram Graph API
  Future<List<Map<String, dynamic>>> _fetchInstagramFollows(
    String accessToken,
    SocialMediaConnection connection,
  ) async {
    try {
      // Note: Instagram Graph API has limited access to follows
      // This may require additional permissions or may not be available
      final followsResponse = await http.get(
        Uri.parse(
            'https://graph.instagram.com/me/follows?access_token=$accessToken'),
      );

      if (followsResponse.statusCode != 200) {
        _logger.warn(
            'Failed to fetch Instagram follows (may require additional permissions)',
            tag: _logName);
        return [];
      }

      final followsData =
          jsonDecode(followsResponse.body) as Map<String, dynamic>;
      final follows = followsData['data'] as List<dynamic>? ?? [];

      return follows
          .map((f) => {
                'id': (f as Map)['id'],
                'username': f['username'],
              })
          .toList();
    } catch (e, stackTrace) {
      _logger.error('Error fetching Instagram follows',
          error: e, stackTrace: stackTrace, tag: _logName);
      return [];
    }
  }

  /// Fetch Twitter follows from Twitter API v2
  Future<List<Map<String, dynamic>>> _fetchTwitterFollows(
    String accessToken,
    SocialMediaConnection connection,
  ) async {
    try {
      // Fetch user follows from Twitter API v2
      // Note: This requires 'follows.read' scope
      final followsResponse = await http.get(
        Uri.parse(
            'https://api.twitter.com/2/users/${connection.platformUserId}/following?max_results=100&user.fields=id,name,username'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (followsResponse.statusCode != 200) {
        _logger.warn(
            'Failed to fetch Twitter follows (may require additional permissions)',
            tag: _logName);
        return [];
      }

      final followsData =
          jsonDecode(followsResponse.body) as Map<String, dynamic>;
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
      _logger.error('Error fetching Twitter follows',
          error: e, stackTrace: stackTrace, tag: _logName);
      return [];
    }
  }

  /// Fetch Facebook friends from Facebook Graph API
  Future<List<Map<String, dynamic>>> _fetchFacebookFriends(
    String accessToken,
    SocialMediaConnection connection,
  ) async {
    try {
      // Note: Facebook Graph API v2.0+ has limited access to friends
      // This may require additional permissions or may not be available
      final friendsResponse = await http.get(
        Uri.parse(
            'https://graph.facebook.com/me/friends?access_token=$accessToken'),
      );

      if (friendsResponse.statusCode != 200) {
        _logger.warn(
            'Failed to fetch Facebook friends (may require additional permissions)',
            tag: _logName);
        return [];
      }

      final friendsData =
          jsonDecode(friendsResponse.body) as Map<String, dynamic>;
      final friends = friendsData['data'] as List<dynamic>? ?? [];

      return friends
          .map((f) => {
                'id': (f as Map)['id'],
                'name': f['name'],
              })
          .toList();
    } catch (e, stackTrace) {
      _logger.error('Error fetching Facebook friends',
          error: e, stackTrace: stackTrace, tag: _logName);
      return [];
    }
  }

  /// Fetch LinkedIn profile data from LinkedIn API
  Future<Map<String, dynamic>> _fetchLinkedInProfileData(
    String accessToken,
    SocialMediaConnection connection,
  ) async {
    try {
      // Fetch user profile from LinkedIn API v2
      final profileResponse = await http.get(
        Uri.parse('https://api.linkedin.com/v2/userinfo'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (profileResponse.statusCode != 200) {
        _logger.warn('Failed to fetch LinkedIn profile, using placeholder',
            tag: _logName);
        return _getPlaceholderProfileData(connection);
      }

      final profileData =
          jsonDecode(profileResponse.body) as Map<String, dynamic>;

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
      _logger.error('Error fetching LinkedIn profile data',
          error: e, stackTrace: stackTrace, tag: _logName);
      return _getPlaceholderProfileData(connection);
    }
  }

  /// Fetch LinkedIn connections from LinkedIn API
  Future<List<Map<String, dynamic>>> _fetchLinkedInConnections(
    String accessToken,
    SocialMediaConnection connection,
  ) async {
    try {
      // Note: LinkedIn API v2 has limited access to connections
      // This may require additional permissions or may not be available
      final connectionsResponse = await http.get(
        Uri.parse(
            'https://api.linkedin.com/v2/networkSizes/edge=1?edgeType=CompanyFollowedByMember'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (connectionsResponse.statusCode != 200) {
        _logger.warn(
            'Failed to fetch LinkedIn connections (may require additional permissions)',
            tag: _logName);
        return [];
      }

      // LinkedIn API returns connection count, not full list
      // For privacy, we'll return an empty list and note this in metadata
      return [];
    } catch (e, stackTrace) {
      _logger.error('Error fetching LinkedIn connections',
          error: e, stackTrace: stackTrace, tag: _logName);
      return [];
    }
  }

  /// Fetch Google Places data (saved places, reviews, photos)
  Future<Map<String, dynamic>> _fetchGooglePlacesDataReal(
    String accessToken,
    SocialMediaConnection connection,
  ) async {
    try {
      _logger.info(
          '📥 Fetching Google Places data (saved places, reviews, photos)',
          tag: _logName);

      // Fetch saved places from Google Maps (if available via API)
      final savedPlaces = await _fetchGoogleSavedPlaces(accessToken);

      // Fetch user's reviews from Google Maps
      final reviews = await _fetchGoogleReviews(accessToken);

      // Fetch photos with location data from Google Photos
      final photos = await _fetchGooglePhotosWithLocation(accessToken);

      _logger.info(
        '✅ Fetched Google Places data: ${savedPlaces.length} places, ${reviews.length} reviews, ${photos.length} photos',
        tag: _logName,
      );

      return {
        'places': savedPlaces,
        'reviews': reviews,
        'photos': photos,
      };
    } catch (e, stackTrace) {
      _logger.error('Error fetching Google Places data',
          error: e, stackTrace: stackTrace, tag: _logName);
      return {
        'places': [],
        'reviews': [],
        'photos': [],
      };
    }
  }

  /// Fetch saved places from Google Maps
  /// Note: This requires Google Maps Platform API access to user's saved places
  Future<List<Map<String, dynamic>>> _fetchGoogleSavedPlaces(
      String accessToken) async {
    try {
      // Google Maps Platform API endpoint for saved places
      // Note: This endpoint may require additional scopes and API access
      final response = await _makeAuthenticatedRequest(
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json',
        accessToken,
        queryParams: {
          'type': 'establishment',
          'radius': '50000', // Large radius to get user's saved places
        },
      );

      if (response == null) {
        return [];
      }

      final data = jsonDecode(response) as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>? ?? [];

      return results.map((place) {
        final geometry = (place as Map)['geometry'] as Map<String, dynamic>?;
        final location = geometry?['location'] as Map<String, dynamic>?;

        return {
          'place_id': place['place_id'],
          'name': place['name'],
          'type': (place['types'] as List<dynamic>?)?.firstOrNull ??
              'establishment',
          'rating': place['rating']?.toDouble(),
          'latitude': location?['lat']?.toDouble(),
          'longitude': location?['lng']?.toDouble(),
          'address': place['vicinity'] ?? place['formatted_address'],
        };
      }).toList();
    } catch (e) {
      _logger.warn(
        'Could not fetch Google saved places (may require additional API access): $e',
        tag: _logName,
      );
      return [];
    }
  }

  /// Fetch user's Google reviews
  /// Note: This requires Google Maps Platform API or Google My Business API access
  Future<List<Map<String, dynamic>>> _fetchGoogleReviews(
      String accessToken) async {
    try {
      // Google Maps Platform API endpoint for user reviews
      // Note: This endpoint may require additional scopes
      // Alternative: Use Google My Business API if user has business account
      final response = await _makeAuthenticatedRequest(
        'https://maps.googleapis.com/maps/api/place/details/json',
        accessToken,
        queryParams: {
          'fields': 'reviews',
        },
      );

      if (response == null) {
        return [];
      }

      final data = jsonDecode(response) as Map<String, dynamic>;
      final result = data['result'] as Map<String, dynamic>?;
      final reviews = result?['reviews'] as List<dynamic>? ?? [];

      return reviews.map((review) {
        return {
          'place_id': result?['place_id'],
          'place_name': result?['name'],
          'rating': (review as Map)['rating']?.toInt(),
          'text': review['text'],
          'time': review['time'],
        };
      }).toList();
    } catch (e) {
      _logger.warn(
        'Could not fetch Google reviews (may require additional API access): $e',
        tag: _logName,
      );
      return [];
    }
  }

  /// Fetch photos with location data from Google Photos
  Future<List<Map<String, dynamic>>> _fetchGooglePhotosWithLocation(
      String accessToken) async {
    try {
      // Google Photos API endpoint
      final response = await _makeAuthenticatedRequest(
        'https://photoslibrary.googleapis.com/v1/mediaItems:search',
        accessToken,
        method: 'POST',
        body: jsonEncode({
          'filters': {
            'mediaTypeFilter': {
              'mediaTypes': ['PHOTO'],
            },
          },
          'pageSize': 50, // Limit to 50 photos
        }),
      );

      if (response == null) {
        return [];
      }

      final data = jsonDecode(response) as Map<String, dynamic>;
      final mediaItems = data['mediaItems'] as List<dynamic>? ?? [];

      return mediaItems.map((item) {
        final mediaMetadata =
            (item as Map)['mediaMetadata'] as Map<String, dynamic>?;
        final location = mediaMetadata?['location'] as Map<String, dynamic>?;

        return {
          'id': item['id'],
          'baseUrl': item['baseUrl'],
          'mimeType': item['mimeType'],
          'latitude': location?['latitude']?.toDouble(),
          'longitude': location?['longitude']?.toDouble(),
          'creationTime': mediaMetadata?['creationTime'],
        };
      }).toList();
    } catch (e) {
      _logger.warn(
        'Could not fetch Google Photos (may require additional scopes): $e',
        tag: _logName,
      );
      return [];
    }
  }

  /// Get placeholder profile data (for development/testing)
  Map<String, dynamic> _getPlaceholderProfileData(
      SocialMediaConnection connection) {
    switch (connection.platform) {
      case 'google':
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
      case 'instagram':
      case 'facebook':
      case 'twitter':
      case 'tiktok':
      case 'linkedin':
      default:
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

  // Rate limiting and error handling

  /// Rate limit tracking per platform
  final Map<String, DateTime> _lastRequestTime = {};
  final Map<String, int> _requestCount = {};
  static const Duration _rateLimitWindow = Duration(minutes: 1);
  static const int _maxRequestsPerWindow = 60; // Conservative limit
  static const Duration _minRequestDelay = Duration(milliseconds: 100);

  /// Make authenticated HTTP request with rate limiting and retry logic
  Future<String?> _makeAuthenticatedRequest(
    String url,
    String accessToken, {
    Map<String, String>? queryParams,
    String method = 'GET',
    String? body,
    int maxRetries = 3,
  }) async {
    final platform = _extractPlatformFromUrl(url);

    // Rate limiting check
    await _checkRateLimit(platform);

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        // Build URI with query parameters
        var uri = Uri.parse(url);
        if (queryParams != null) {
          uri = uri.replace(queryParameters: {
            ...uri.queryParameters,
            ...queryParams,
          });
        }

        // Make request
        http.Response response;
        if (method == 'POST') {
          response = await http.post(
            uri,
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
            body: body,
          );
        } else {
          response = await http.get(
            uri,
            headers: {'Authorization': 'Bearer $accessToken'},
          );
        }

        // Update rate limit tracking
        _updateRateLimitTracking(platform);

        // Handle response
        if (response.statusCode == 200) {
          return response.body;
        } else if (response.statusCode == 401) {
          // Token expired or invalid - try to refresh
          _logger.warn('Token expired, attempting refresh', tag: _logName);
          final refreshed = await _refreshTokenIfNeeded(platform, accessToken);
          if (refreshed && attempt < maxRetries - 1) {
            // Retry with new token
            final newTokens = await _getTokens(
              _getAgentIdFromConnection(platform),
              platform,
            );
            if (newTokens != null) {
              accessToken = newTokens['access_token'] as String? ?? accessToken;
              continue;
            }
          }
          throw Exception('Authentication failed: ${response.statusCode}');
        } else if (response.statusCode == 429) {
          // Rate limited - wait and retry
          final retryAfter = _parseRetryAfter(response.headers['retry-after']);
          _logger.warn(
            'Rate limited, waiting ${retryAfter.inSeconds}s before retry',
            tag: _logName,
          );
          if (attempt < maxRetries - 1) {
            await Future.delayed(retryAfter);
            continue;
          }
          throw Exception('Rate limit exceeded');
        } else if (response.statusCode >= 500 && attempt < maxRetries - 1) {
          // Server error - retry with exponential backoff
          final backoff = Duration(seconds: 1 << attempt); // 1s, 2s, 4s
          _logger.warn(
            'Server error ${response.statusCode}, retrying after ${backoff.inSeconds}s',
            tag: _logName,
          );
          await Future.delayed(backoff);
          continue;
        } else {
          throw Exception(
              'Request failed: ${response.statusCode} - ${response.body}');
        }
      } catch (e, stackTrace) {
        if (attempt == maxRetries - 1) {
          _logger.error(
            'Request failed after $maxRetries attempts',
            error: e,
            stackTrace: stackTrace,
            tag: _logName,
          );
          return null;
        }
        // Wait before retry
        await Future.delayed(Duration(seconds: 1 << attempt));
      }
    }

    return null;
  }

  /// Check and enforce rate limits
  Future<void> _checkRateLimit(String platform) async {
    final now = DateTime.now();
    final lastRequest = _lastRequestTime[platform];
    final requestCount = _requestCount[platform] ?? 0;

    // Reset counter if window expired
    if (lastRequest == null || now.difference(lastRequest) > _rateLimitWindow) {
      _requestCount[platform] = 0;
      _lastRequestTime[platform] = now;
      return;
    }

    // Check if we've exceeded the limit
    if (requestCount >= _maxRequestsPerWindow) {
      final waitTime = _rateLimitWindow - now.difference(lastRequest);
      _logger.warn(
        'Rate limit reached for $platform, waiting ${waitTime.inSeconds}s',
        tag: _logName,
      );
      await Future.delayed(waitTime);
      _requestCount[platform] = 0;
      _lastRequestTime[platform] = DateTime.now();
      return;
    }

    // Enforce minimum delay between requests
    final timeSinceLastRequest = now.difference(lastRequest);
    if (timeSinceLastRequest < _minRequestDelay) {
      await Future.delayed(_minRequestDelay - timeSinceLastRequest);
    }
  }

  /// Update rate limit tracking
  void _updateRateLimitTracking(String platform) {
    final now = DateTime.now();
    _lastRequestTime[platform] = now;
    _requestCount[platform] = (_requestCount[platform] ?? 0) + 1;
  }

  /// Extract platform from URL
  String _extractPlatformFromUrl(String url) {
    if (url.contains('googleapis.com')) return 'google';
    if (url.contains('instagram.com')) return 'instagram';
    if (url.contains('facebook.com')) return 'facebook';
    return 'unknown';
  }

  /// Parse Retry-After header
  Duration _parseRetryAfter(String? retryAfter) {
    if (retryAfter == null) return const Duration(seconds: 60);
    final seconds = int.tryParse(retryAfter);
    if (seconds != null) return Duration(seconds: seconds);
    return const Duration(seconds: 60);
  }

  /// Refresh token if needed
  Future<bool> _refreshTokenIfNeeded(
      String platform, String currentToken) async {
    try {
      // Get all connections to find the one for this platform
      // Note: This is a simplified implementation - in production, we'd cache the agentId
      final platforms = ['google', 'instagram', 'facebook'];
      for (final p in platforms) {
        // Try to find connection - this is a simplified approach
        // In production, we'd have a better way to map platform to agentId
        final connections = await _getAllConnectionsForPlatform(p);
        for (final connection in connections) {
          if (connection.platform == platform && connection.isActive) {
            return await _refreshTokenForConnection(connection);
          }
        }
      }

      return false;
    } catch (e) {
      _logger.error('Failed to refresh token: $e', tag: _logName);
      return false;
    }
  }

  /// Refresh token for a specific connection
  Future<bool> _refreshTokenForConnection(
      SocialMediaConnection connection) async {
    try {
      final tokens = await _getTokens(connection.agentId, connection.platform);
      if (tokens == null) {
        return false;
      }

      final refreshToken = tokens['refresh_token'] as String?;
      if (refreshToken == null) {
        _logger.warn('No refresh token available for ${connection.platform}',
            tag: _logName);
        return false;
      }

      // Check if token is expired or about to expire (within 5 minutes)
      final expiresAtStr = tokens['expires_at'] as String?;
      if (expiresAtStr != null) {
        try {
          final expiresAt = DateTime.parse(expiresAtStr);
          final now = DateTime.now();
          final timeUntilExpiry = expiresAt.difference(now);

          // Only refresh if expired or expiring within 5 minutes
          if (timeUntilExpiry.inMinutes > 5) {
            return false; // Token still valid
          }
        } catch (e) {
          // If we can't parse expiration, assume it needs refresh
        }
      }

      // Refresh token based on platform
      switch (connection.platform) {
        case 'google':
          return await _refreshGoogleToken(connection, refreshToken);
        case 'instagram':
          return await _refreshInstagramToken(connection, refreshToken);
        case 'facebook':
          return await _refreshFacebookToken(connection, refreshToken);
        default:
          return false;
      }
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to refresh token for connection',
        error: e,
        stackTrace: stackTrace,
        tag: _logName,
      );
      return false;
    }
  }

  /// Refresh Google token
  Future<bool> _refreshGoogleToken(
    SocialMediaConnection connection,
    String refreshToken,
  ) async {
    try {
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
          await _storeTokens(connection.agentId, connection.platform, {
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

  /// Refresh Instagram token
  Future<bool> _refreshInstagramToken(
    SocialMediaConnection connection,
    String refreshToken,
  ) async {
    try {
      // Instagram token refresh endpoint
      final response = await http.get(
        Uri.parse(
          'https://graph.instagram.com/refresh_access_token?'
          'grant_type=ig_refresh_token&'
          'access_token=$refreshToken',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final newAccessToken = data['access_token'] as String?;
        final expiresIn = data['expires_in'] as int?;

        if (newAccessToken != null) {
          // Update tokens
          await _storeTokens(connection.agentId, connection.platform, {
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

  /// Refresh Facebook token
  Future<bool> _refreshFacebookToken(
    SocialMediaConnection connection,
    String refreshToken,
  ) async {
    try {
      // Facebook token refresh endpoint
      final response = await http.get(
        Uri.parse(
          'https://graph.facebook.com/v18.0/oauth/access_token?'
          'grant_type=fb_exchange_token&'
          'client_id=${OAuthConfig.facebookClientId}&'
          'client_secret=${OAuthConfig.facebookClientSecret}&'
          'fb_exchange_token=$refreshToken',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final newAccessToken = data['access_token'] as String?;
        final expiresIn = data['expires_in'] as int?;

        if (newAccessToken != null) {
          // Update tokens
          await _storeTokens(connection.agentId, connection.platform, {
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

  /// Get all connections for a platform (helper for token refresh)
  Future<List<SocialMediaConnection>> _getAllConnectionsForPlatform(
      String platform) async {
    // This is a simplified implementation - in production, we'd have better indexing
    final connections = <SocialMediaConnection>[];

    // We need agentId to get connections, but we don't have it here
    // This is a limitation of the current implementation
    // In production, we'd maintain a reverse index: platform -> agentId -> connection
    return connections;
  }

  /// Get agentId from connection (helper for token refresh)
  String _getAgentIdFromConnection(String platform) {
    // This would need to be implemented to get agentId from stored connections
    // For now, return empty string (will be handled by caller)
    return '';
  }

  // Private helper methods

  /// Save connection to storage
  Future<void> _saveConnection(
      String agentId, String platform, SocialMediaConnection connection) async {
    final key = '$_connectionsKeyPrefix${agentId}_$platform';
    await _storageService.setObject(key, connection.toJson());
  }

  /// Get connection from storage
  Future<SocialMediaConnection?> _getConnection(
      String agentId, String platform) async {
    final key = '$_connectionsKeyPrefix${agentId}_$platform';
    final data = _storageService.getObject<Map<String, dynamic>>(key);
    if (data == null) return null;
    return SocialMediaConnection.fromJson(data);
  }

  /// Get all connections for an agent
  Future<List<SocialMediaConnection>> _getAllConnections(String agentId) async {
    // TODO: Implement efficient storage query
    // For now, we'll need to know all possible platforms
    final platforms = [
      'google',
      'instagram',
      'facebook',
      'twitter',
      'tiktok',
      'linkedin'
    ];
    final connections = <SocialMediaConnection>[];

    for (final platform in platforms) {
      final connection = await _getConnection(agentId, platform);
      if (connection != null) {
        connections.add(connection);
      }
    }

    return connections;
  }

  /// Store OAuth tokens (encrypted using flutter_secure_storage)
  Future<void> _storeTokens(
      String agentId, String platform, Map<String, dynamic> tokens) async {
    final key = '$_tokensKeyPrefix${agentId}_$platform';
    final tokensJson = jsonEncode(tokens);
    // In widget tests, platform channels for FlutterSecureStorage are not available and
    // can hang tests. Fall back to normal StorageService for deterministic testing.
    if (_isWidgetTestBinding) {
      await _storageService.setString(key, tokensJson);
      return;
    }
    try {
      await _secureStorage
          .write(key: key, value: tokensJson)
          .timeout(const Duration(seconds: 2));
    } catch (e) {
      // MissingPluginException or other storage failures: fall back to StorageService.
      await _storageService.setString(key, tokensJson);
    }
  }

  /// Cache profile data locally
  Future<void> _cacheProfileData(
      String cacheKey, Map<String, dynamic> data) async {
    try {
      final cacheData = {
        'data': data,
        'cached_at': DateTime.now().toIso8601String(),
        'expires_at': DateTime.now().add(_profileCacheExpiry).toIso8601String(),
      };
      await _storageService.setObject(cacheKey, cacheData);
    } catch (e) {
      _logger.warn('Failed to cache profile data: $e', tag: _logName);
    }
  }

  /// Get cached profile data if still valid
  Future<Map<String, dynamic>?> _getCachedProfileData(String cacheKey) async {
    try {
      final cacheData =
          _storageService.getObject<Map<String, dynamic>>(cacheKey);
      if (cacheData == null) return null;

      final expiresAt = DateTime.parse(cacheData['expires_at'] as String);
      if (DateTime.now().isAfter(expiresAt)) {
        // Cache expired, remove it
        await _storageService.remove(cacheKey);
        return null;
      }

      return cacheData['data'] as Map<String, dynamic>?;
    } catch (e) {
      _logger.warn('Failed to get cached profile data: $e', tag: _logName);
      return null;
    }
  }

  /// Get OAuth tokens (decrypted from flutter_secure_storage)
  /// Public method for sharing service to access tokens
  Future<Map<String, dynamic>?> getAccessTokens(
      String agentId, String platform) async {
    return await _getTokens(agentId, platform);
  }

  /// Get OAuth tokens (decrypted from flutter_secure_storage)
  Future<Map<String, dynamic>?> _getTokens(
      String agentId, String platform) async {
    final key = '$_tokensKeyPrefix${agentId}_$platform';
    String? tokensJson;
    if (_isWidgetTestBinding) {
      tokensJson = _storageService.getString(key);
    } else {
      try {
        tokensJson = await _secureStorage
            .read(key: key)
            .timeout(const Duration(seconds: 2));
      } catch (e) {
        tokensJson = _storageService.getString(key);
      }
    }
    if (tokensJson == null) return null;
    return jsonDecode(tokensJson) as Map<String, dynamic>;
  }

  /// Remove OAuth tokens
  Future<void> _removeTokens(String agentId, String platform) async {
    final key = '$_tokensKeyPrefix${agentId}_$platform';
    if (_isWidgetTestBinding) {
      await _storageService.remove(key);
      return;
    }
    try {
      await _secureStorage.delete(key: key).timeout(const Duration(seconds: 2));
    } catch (e) {
      await _storageService.remove(key);
    }
  }
}
