import 'dart:async';
import 'dart:convert';
import 'package:avrai/core/services/infrastructure/storage_service.dart';
import 'package:avrai/core/services/infrastructure/logger.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

/// Common utilities for social media platform services
///
/// Provides shared functionality for:
/// - Token storage and retrieval
/// - Rate limiting
/// - HTTP request handling
/// - Profile data caching
class SocialMediaCommonUtils {
  static const String _logName = 'SocialMediaCommonUtils';
  final AppLogger _logger = const AppLogger(defaultTag: 'SPOTS');
  final StorageService _storageService;
  /// Secure storage for OAuth tokens and sensitive data.
  ///
  /// Injected to allow test environments to provide an in-memory implementation
  /// (avoids platform channel dependencies / MissingPluginException).
  final FlutterSecureStorage _secureStorage;

  // Storage keys
  static const String _tokensKeyPrefix = 'social_media_tokens_';
  static const String _profileCacheKeyPrefix = 'social_media_profile_cache_';
  static const Duration _profileCacheExpiry = Duration(days: 7);

  // Rate limiting
  final Map<String, DateTime> _lastRequestTime = {};
  final Map<String, int> _requestCount = {};
  static const Duration _rateLimitWindow = Duration(minutes: 1);
  static const int _maxRequestsPerWindow = 60;
  static const Duration _minRequestDelay = Duration(milliseconds: 100);

  SocialMediaCommonUtils(
    this._storageService, {
    FlutterSecureStorage? secureStorage,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Store OAuth tokens (encrypted using flutter_secure_storage)
  Future<void> storeTokens(
    String agentId,
    String platform,
    Map<String, dynamic> tokens,
  ) async {
    final key = '$_tokensKeyPrefix${agentId}_$platform';
    final tokensJson = jsonEncode(tokens);
    await _secureStorage.write(key: key, value: tokensJson);
  }

  /// Get OAuth tokens (decrypted from flutter_secure_storage)
  Future<Map<String, dynamic>?> getTokens(
    String agentId,
    String platform,
  ) async {
    final key = '$_tokensKeyPrefix${agentId}_$platform';
    final tokensJson = await _secureStorage.read(key: key);
    if (tokensJson == null) return null;
    return jsonDecode(tokensJson) as Map<String, dynamic>;
  }

  /// Remove OAuth tokens
  Future<void> removeTokens(String agentId, String platform) async {
    final key = '$_tokensKeyPrefix${agentId}_$platform';
    await _secureStorage.delete(key: key);
  }

  /// Cache profile data locally
  Future<void> cacheProfileData(
    String cacheKey,
    Map<String, dynamic> data,
  ) async {
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
  Future<Map<String, dynamic>?> getCachedProfileData(String cacheKey) async {
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

  /// Get cache key for a platform
  String getCacheKey(String agentId, String platform) {
    return '$_profileCacheKeyPrefix${agentId}_$platform';
  }

  /// Make authenticated HTTP request with rate limiting and retry logic
  Future<String?> makeAuthenticatedRequest(
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
          // Token expired or invalid
          _logger.warn('Token expired for $platform', tag: _logName);
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
    if (lastRequest == null ||
        now.difference(lastRequest) > _rateLimitWindow) {
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
    if (url.contains('twitter.com')) return 'twitter';
    if (url.contains('linkedin.com')) return 'linkedin';
    return 'unknown';
  }

  /// Parse Retry-After header
  Duration _parseRetryAfter(String? retryAfter) {
    if (retryAfter == null) return const Duration(seconds: 60);
    final seconds = int.tryParse(retryAfter);
    if (seconds != null) return Duration(seconds: seconds);
    return const Duration(seconds: 60);
  }
}
