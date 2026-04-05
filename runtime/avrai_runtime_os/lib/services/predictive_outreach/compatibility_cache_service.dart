// ignore: dangling_library_doc_comments
/// Compatibility Cache Service
///
/// Caches compatibility calculations for performance.
/// Part of Predictive Proactive Outreach System - Phase 6.1
///
/// Features:
/// - Caches compatibility scores
/// - Implements cache invalidation
/// - Uses compatibility_cache table
/// - Reduces redundant calculations

import 'dart:developer' as developer;
import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';

/// Cached compatibility entry
class CachedCompatibility {
  final String userAId;
  final String userBId;
  final double compatibilityScore;
  final double? knotCompatibility;
  final double? quantumCompatibility;
  final double? locationCompatibility;
  final double? timingCompatibility;
  final DateTime calculatedAt;
  final DateTime expiresAt;

  CachedCompatibility({
    required this.userAId,
    required this.userBId,
    required this.compatibilityScore,
    this.knotCompatibility,
    this.quantumCompatibility,
    this.locationCompatibility,
    this.timingCompatibility,
    required this.calculatedAt,
    required this.expiresAt,
  });

  /// Check if cache entry is still valid
  bool get isValid => DateTime.now().isBefore(expiresAt);
}

/// Service for caching compatibility calculations
class CompatibilityCacheService {
  static const String _logName = 'CompatibilityCacheService';

  final SupabaseService _supabaseService;

  // Cache expiration (7 days)
  static const Duration _cacheExpiration = Duration(days: 7);

  CompatibilityCacheService({
    required SupabaseService supabaseService,
  }) : _supabaseService = supabaseService;

  /// Get cached compatibility
  ///
  /// Returns cached score if available and valid, null otherwise.
  Future<CachedCompatibility?> getCachedCompatibility({
    required String userAId,
    required String userBId,
  }) async {
    try {
      final response = await _supabaseService.client
          .from('compatibility_cache')
          .select()
          .or('(user_a_id.eq.$userAId,user_b_id.eq.$userBId),(user_a_id.eq.$userBId,user_b_id.eq.$userAId)')
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('calculated_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return CachedCompatibility(
        userAId: response['user_a_id'] as String,
        userBId: response['user_b_id'] as String,
        compatibilityScore: (response['compatibility_score'] as num).toDouble(),
        knotCompatibility: (response['knot_compatibility'] as num?)?.toDouble(),
        quantumCompatibility:
            (response['quantum_compatibility'] as num?)?.toDouble(),
        locationCompatibility:
            (response['location_compatibility'] as num?)?.toDouble(),
        timingCompatibility:
            (response['timing_compatibility'] as num?)?.toDouble(),
        calculatedAt: DateTime.parse(response['calculated_at'] as String),
        expiresAt: DateTime.parse(response['expires_at'] as String),
      );
    } catch (e) {
      developer.log('Error getting cached compatibility: $e', name: _logName);
      return null;
    }
  }

  /// Cache compatibility calculation
  ///
  /// Stores calculated compatibility for future use.
  Future<bool> cacheCompatibility({
    required String userAId,
    required String userBId,
    required double compatibilityScore,
    double? knotCompatibility,
    double? quantumCompatibility,
    double? locationCompatibility,
    double? timingCompatibility,
  }) async {
    try {
      final expiresAt = DateTime.now().add(_cacheExpiration);

      await _supabaseService.client.from('compatibility_cache').upsert({
        'user_a_id': userAId,
        'user_b_id': userBId,
        'compatibility_score': compatibilityScore,
        'knot_compatibility': knotCompatibility,
        'quantum_compatibility': quantumCompatibility,
        'location_compatibility': locationCompatibility,
        'timing_compatibility': timingCompatibility,
        'calculated_at': DateTime.now().toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
      });

      developer.log(
        '✅ Compatibility cached: $userAId <-> $userBId (score: ${compatibilityScore.toStringAsFixed(2)})',
        name: _logName,
      );

      return true;
    } catch (e) {
      developer.log('Error caching compatibility: $e', name: _logName);
      return false;
    }
  }

  /// Invalidate cache entry
  ///
  /// Removes cached compatibility (e.g., when user profile changes).
  Future<bool> invalidateCache({
    required String userAId,
    String? userBId,
  }) async {
    try {
      if (userBId != null) {
        // Invalidate specific pair
        await _supabaseService.client.from('compatibility_cache').delete().or(
            '(user_a_id.eq.$userAId,user_b_id.eq.$userBId),(user_a_id.eq.$userBId,user_b_id.eq.$userAId)');
      } else {
        // Invalidate all entries involving userAId
        await _supabaseService.client
            .from('compatibility_cache')
            .delete()
            .or('user_a_id.eq.$userAId,user_b_id.eq.$userAId');
      }

      developer.log(
        '✅ Cache invalidated: $userAId${userBId != null ? ' <-> $userBId' : ''}',
        name: _logName,
      );

      return true;
    } catch (e) {
      developer.log('Error invalidating cache: $e', name: _logName);
      return false;
    }
  }

  /// Clean expired cache entries
  ///
  /// Removes expired cache entries (should be run periodically).
  Future<int> cleanExpiredEntries() async {
    try {
      final response = await _supabaseService.client
          .from('compatibility_cache')
          .delete()
          .lte('expires_at', DateTime.now().toIso8601String())
          .select();

      final deletedCount = (response as List).length;

      developer.log(
        '✅ Cleaned $deletedCount expired cache entries',
        name: _logName,
      );

      return deletedCount;
    } catch (e) {
      developer.log('Error cleaning expired entries: $e', name: _logName);
      return 0;
    }
  }
}
