// ignore: dangling_library_doc_comments
/// Predictive Signals Cache Service
///
/// Caches predictive signals (knot, quantum, fabric predictions).
/// Part of Predictive Proactive Outreach System - Phase 6.2
///
/// Features:
/// - Caches knot evolution predictions
/// - Caches quantum trajectory predictions
/// - Caches fabric stability predictions
/// - Time-based expiration

import 'dart:developer' as developer;
import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';

/// Predictive signal type
enum PredictiveSignalType {
  stringPrediction,
  quantumTrajectory,
  fabricStability,
  evolutionPattern,
}

/// Cached predictive signal
class CachedPredictiveSignal {
  final String signalId;
  final String userId;
  final String? targetId;
  final PredictiveSignalType signalType;
  final Map<String, dynamic> signalData;
  final DateTime targetTime;
  final DateTime calculatedAt;
  final DateTime expiresAt;

  CachedPredictiveSignal({
    required this.signalId,
    required this.userId,
    this.targetId,
    required this.signalType,
    required this.signalData,
    required this.targetTime,
    required this.calculatedAt,
    required this.expiresAt,
  });

  /// Check if cache entry is still valid
  bool get isValid => DateTime.now().isBefore(expiresAt);
}

/// Service for caching predictive signals
class PredictiveSignalsCacheService {
  static const String _logName = 'PredictiveSignalsCacheService';

  final SupabaseService _supabaseService;

  // Default cache expiration (3 days)
  static const Duration _defaultCacheExpiration = Duration(days: 3);

  PredictiveSignalsCacheService({
    required SupabaseService supabaseService,
  }) : _supabaseService = supabaseService;

  /// Get cached predictive signal
  ///
  /// Returns cached signal if available and valid, null otherwise.
  Future<CachedPredictiveSignal?> getCachedSignal({
    required String userId,
    String? targetId,
    required PredictiveSignalType signalType,
    required DateTime targetTime,
  }) async {
    try {
      var query = _supabaseService.client
          .from('predictive_signals_cache')
          .select()
          .eq('user_id', userId)
          .eq('signal_type', signalType.name)
          .eq('target_time', targetTime.toIso8601String())
          .gt('expires_at', DateTime.now().toIso8601String());

      if (targetId != null) {
        query = query.eq('target_id', targetId);
      }

      final response = await query
          .order('calculated_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return CachedPredictiveSignal(
        signalId: response['id'] as String,
        userId: response['user_id'] as String,
        targetId: response['target_id'] as String?,
        signalType: PredictiveSignalType.values.firstWhere(
          (t) => t.name == response['signal_type'] as String,
        ),
        signalData: response['signal_data'] as Map<String, dynamic>,
        targetTime: DateTime.parse(response['target_time'] as String),
        calculatedAt: DateTime.parse(response['calculated_at'] as String),
        expiresAt: DateTime.parse(response['expires_at'] as String),
      );
    } catch (e) {
      developer.log('Error getting cached signal: $e', name: _logName);
      return null;
    }
  }

  /// Cache predictive signal
  ///
  /// Stores calculated signal for future use.
  Future<bool> cacheSignal({
    required String userId,
    String? targetId,
    required PredictiveSignalType signalType,
    required Map<String, dynamic> signalData,
    required DateTime targetTime,
    Duration? expiration,
  }) async {
    try {
      final expiresAt =
          DateTime.now().add(expiration ?? _defaultCacheExpiration);

      await _supabaseService.client.from('predictive_signals_cache').upsert({
        'user_id': userId,
        'target_id': targetId,
        'signal_type': signalType.name,
        'signal_data': signalData,
        'target_time': targetTime.toIso8601String(),
        'calculated_at': DateTime.now().toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
      });

      developer.log(
        '✅ Predictive signal cached: $userId -> ${targetId ?? 'N/A'} '
        '(type: ${signalType.name}, target: ${targetTime.toIso8601String()})',
        name: _logName,
      );

      return true;
    } catch (e) {
      developer.log('Error caching signal: $e', name: _logName);
      return false;
    }
  }

  /// Invalidate cache entries
  ///
  /// Removes cached signals (e.g., when user profile changes).
  Future<bool> invalidateCache({
    required String userId,
    PredictiveSignalType? signalType,
  }) async {
    try {
      var query = _supabaseService.client
          .from('predictive_signals_cache')
          .delete()
          .eq('user_id', userId);

      if (signalType != null) {
        query = query.eq('signal_type', signalType.name);
      }

      await query;

      developer.log(
        '✅ Cache invalidated: $userId${signalType != null ? ' (type: ${signalType.name})' : ''}',
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
          .from('predictive_signals_cache')
          .delete()
          .lte('expires_at', DateTime.now().toIso8601String())
          .select();

      final deletedCount = (response as List).length;

      developer.log(
        '✅ Cleaned $deletedCount expired signal cache entries',
        name: _logName,
      );

      return deletedCount;
    } catch (e) {
      developer.log('Error cleaning expired entries: $e', name: _logName);
      return 0;
    }
  }
}
