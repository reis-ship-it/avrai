// List Preloading Service
//
// Phase 5.5: Predictive caching for suggested lists
//
// Purpose: Pre-fetch lists before they're needed

import 'dart:developer' as developer;
import 'dart:async';

import 'package:avrai/core/ai/perpetual_list/models/models.dart';
import 'package:avrai/core/ai/perpetual_list/perpetual_list_orchestrator.dart';
import 'package:get_it/get_it.dart';

/// List Preloading Service
///
/// Predictively pre-fetches suggested lists to reduce latency.
/// Uses time-based and location-based predictions.
///
/// Part of Phase 5.5: Predictive Caching

class ListPreloadingService {
  static const String _logName = 'ListPreloadingService';

  /// How far in advance to preload (in minutes)
  static const int preloadWindowMinutes = 30;

  /// Maximum cached lists per user
  static const int maxCachedListsPerUser = 5;

  /// Cache expiration time
  static const Duration cacheExpiration = Duration(hours: 2);

  PerpetualListOrchestrator? _orchestrator;
  Timer? _preloadTimer;

  /// Cached preloaded lists per user
  final Map<String, List<CachedList>> _cache = {};

  ListPreloadingService() {
    _initializeOrchestrator();
  }

  void _initializeOrchestrator() {
    try {
      if (GetIt.instance.isRegistered<PerpetualListOrchestrator>()) {
        _orchestrator = GetIt.instance<PerpetualListOrchestrator>();
      }
    } catch (e) {
      developer.log('Orchestrator not available: $e', name: _logName);
    }
  }

  /// Start preloading for a user
  void startPreloading({
    required String userId,
    required int userAge,
  }) {
    developer.log('Starting preloading for user: $userId', name: _logName);

    // Cancel existing timer
    _preloadTimer?.cancel();

    // Schedule periodic preloading
    _preloadTimer = Timer.periodic(
      Duration(minutes: preloadWindowMinutes),
      (_) => _preloadForUser(userId, userAge),
    );

    // Immediate preload
    _preloadForUser(userId, userAge);
  }

  /// Stop preloading
  void stopPreloading() {
    _preloadTimer?.cancel();
    _preloadTimer = null;
    developer.log('Stopped preloading', name: _logName);
  }

  /// Get cached lists for a user
  List<SuggestedList> getCachedLists(String userId) {
    _cleanExpiredCache(userId);

    final cached = _cache[userId];
    if (cached == null || cached.isEmpty) {
      return [];
    }

    return cached.map((c) => c.list).toList();
  }

  /// Check if there are cached lists available
  bool hasCachedLists(String userId) {
    _cleanExpiredCache(userId);
    return _cache[userId]?.isNotEmpty ?? false;
  }

  /// Invalidate cache for a user
  void invalidateCache(String userId) {
    _cache.remove(userId);
    developer.log('Invalidated cache for user: $userId', name: _logName);
  }

  /// Preload lists for a user
  Future<void> _preloadForUser(String userId, int userAge) async {
    if (_orchestrator == null) {
      developer.log('Orchestrator not available, skipping preload', name: _logName);
      return;
    }

    try {
      developer.log('Preloading lists for user: $userId', name: _logName);

      // Get predicted time slots that might need lists
      final predictedSlots = _predictNextSlots();

      for (var i = 0; i < predictedSlots.length; i++) {
        // Build trigger context for predicted time
        final context = await _orchestrator!.buildTriggerContext(
          userId: userId,
          locationChange: null, // Use last known location
        );

        // Generate lists (but don't trigger notifications)
        final lists = await _orchestrator!.generateListsIfAppropriate(
          userId: userId,
          userAge: userAge,
          triggerContext: context,
        );

        if (lists.isNotEmpty) {
          _addToCache(userId, lists);
        }
      }
    } catch (e) {
      developer.log('Error preloading lists: $e', name: _logName);
    }
  }

  /// Predict next time slots that might need lists
  List<TimeSlot> _predictNextSlots() {
    final now = DateTime.now();
    final slots = <TimeSlot>[];

    // Add next few time slots based on current time
    final currentHour = now.hour;

    if (currentHour < 8) {
      slots.add(TimeSlot.morning);
    } else if (currentHour < 12) {
      slots.add(TimeSlot.afternoon);
    } else if (currentHour < 17) {
      slots.add(TimeSlot.evening);
    } else if (currentHour < 21) {
      slots.add(TimeSlot.night);
    }

    return slots;
  }

  /// Add lists to cache
  void _addToCache(String userId, List<SuggestedList> lists) {
    _cache[userId] ??= [];

    for (final list in lists) {
      _cache[userId]!.add(CachedList(
        list: list,
        cachedAt: DateTime.now(),
      ));
    }

    // Trim cache if too large
    while (_cache[userId]!.length > maxCachedListsPerUser) {
      _cache[userId]!.removeAt(0);
    }

    developer.log(
      'Cached ${lists.length} lists for user: $userId (total: ${_cache[userId]!.length})',
      name: _logName,
    );
  }

  /// Clean expired cache entries
  void _cleanExpiredCache(String userId) {
    final cached = _cache[userId];
    if (cached == null) return;

    final now = DateTime.now();
    cached.removeWhere((c) => now.difference(c.cachedAt) > cacheExpiration);
  }

  /// Dispose resources
  void dispose() {
    stopPreloading();
    _cache.clear();
  }
}

/// Cached list entry
class CachedList {
  final SuggestedList list;
  final DateTime cachedAt;

  const CachedList({
    required this.list,
    required this.cachedAt,
  });

  bool get isExpired {
    return DateTime.now().difference(cachedAt) >
        ListPreloadingService.cacheExpiration;
  }
}
