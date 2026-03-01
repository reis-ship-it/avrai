/// User Name Resolution Service
///
/// Resolves user IDs to display names and photo URLs
/// Caches results for performance
///
/// Phase 3 Enhancement: Name Resolution
/// Date: December 2025
library;

import 'dart:developer' as developer;
import 'package:get_it/get_it.dart';
import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';

class UserNameResolutionService {
  static const String _logName = 'UserNameResolutionService';

  // Cache for user info
  final Map<String, _UserInfo> _cache = {};
  final SupabaseService _supabaseService = GetIt.instance<SupabaseService>();

  /// Get user display name
  Future<String> getUserDisplayName(String userId) async {
    try {
      // Check cache first
      if (_cache.containsKey(userId)) {
        return _cache[userId]!.displayName;
      }

      // Fetch from service
      final profile = await _supabaseService.getUserProfile(userId);
      if (profile != null) {
        final displayName = profile['display_name'] as String? ??
            profile['name'] as String? ??
            profile['email'] as String? ??
            userId;
        final photoUrl = profile['avatar_url'] as String?;

        // Cache result
        _cache[userId] = _UserInfo(
          displayName: displayName,
          photoUrl: photoUrl,
        );

        return displayName;
      }

      // Fallback to userId if not found
      return userId;
    } catch (e) {
      developer.log(
        'Error getting user display name: $e',
        name: _logName,
        error: e,
      );
      return userId;
    }
  }

  /// Get user photo URL
  Future<String?> getUserPhotoUrl(String userId) async {
    try {
      // Check cache first
      if (_cache.containsKey(userId)) {
        return _cache[userId]!.photoUrl;
      }

      // Fetch from service
      final profile = await _supabaseService.getUserProfile(userId);
      if (profile != null) {
        final displayName = profile['display_name'] as String? ??
            profile['name'] as String? ??
            profile['email'] as String? ??
            userId;
        final photoUrl = profile['avatar_url'] as String?;

        // Cache result
        _cache[userId] = _UserInfo(
          displayName: displayName,
          photoUrl: photoUrl,
        );

        return photoUrl;
      }

      return null;
    } catch (e) {
      developer.log(
        'Error getting user photo URL: $e',
        name: _logName,
        error: e,
      );
      return null;
    }
  }

  /// Get multiple user info at once
  // ignore: library_private_types_in_public_api - Internal helper type for caching
  Future<Map<String, _UserInfo>> getUsersInfo(List<String> userIds) async {
    final results = <String, _UserInfo>{};

    // Get cached results first
    final uncachedIds = <String>[];
    for (final userId in userIds) {
      if (_cache.containsKey(userId)) {
        results[userId] = _cache[userId]!;
      } else {
        uncachedIds.add(userId);
      }
    }

    // Fetch uncached users
    for (final userId in uncachedIds) {
      try {
        final profile = await _supabaseService.getUserProfile(userId);
        if (profile != null) {
          final displayName = profile['display_name'] as String? ??
              profile['name'] as String? ??
              profile['email'] as String? ??
              userId;
          final photoUrl = profile['avatar_url'] as String?;

          final info = _UserInfo(
            displayName: displayName,
            photoUrl: photoUrl,
          );

          _cache[userId] = info;
          results[userId] = info;
        } else {
          // Fallback
          final info = _UserInfo(displayName: userId, photoUrl: null);
          _cache[userId] = info;
          results[userId] = info;
        }
      } catch (e) {
        // Fallback on error
        final info = _UserInfo(displayName: userId, photoUrl: null);
        _cache[userId] = info;
        results[userId] = info;
      }
    }

    return results;
  }

  /// Clear cache for a specific user
  void clearCache(String userId) {
    _cache.remove(userId);
  }

  /// Clear all cache
  void clearAllCache() {
    _cache.clear();
  }
}

class _UserInfo {
  final String displayName;
  final String? photoUrl;

  _UserInfo({
    required this.displayName,
    this.photoUrl,
  });
}
