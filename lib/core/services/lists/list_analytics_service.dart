// List Analytics Service
//
// Phase 3.2: Analytics for AI-suggested lists
//
// Purpose: Track user interactions with suggested lists for optimization

import 'dart:developer' as developer;

import 'package:avrai/core/ai/perpetual_list/models/models.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

/// List Analytics Service
///
/// Tracks user interactions with AI-suggested lists:
/// - List views and impressions
/// - List saves and dismissals
/// - Place taps and visits
/// - Trigger reason effectiveness
/// - Quality score correlation
///
/// Part of Phase 3.2: Analytics

class ListAnalyticsService {
  static const String _logName = 'ListAnalyticsService';

  final FirebaseAnalytics _analytics;
  bool _initialized = false;

  ListAnalyticsService({
    FirebaseAnalytics? analytics,
  }) : _analytics = analytics ?? FirebaseAnalytics.instance;

  /// Initialize analytics
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      await _analytics.setAnalyticsCollectionEnabled(true);
      _initialized = true;
      developer.log('ListAnalyticsService initialized', name: _logName);
    } catch (e) {
      developer.log('Error initializing analytics: $e', name: _logName);
    }
  }

  /// Track when a list is shown to the user
  Future<void> trackListImpression({
    required SuggestedList list,
    required String userId,
    String? source,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'suggested_list_impression',
        parameters: {
          'list_id': list.id,
          'theme': list.theme,
          'place_count': list.placeCount,
          'quality_score': (list.qualityScore * 100).toInt(),
          'trigger_reasons': list.triggerReasons.join(','),
          'is_pinned': list.isPinned,
          'source': source ?? 'unknown',
        },
      );
      developer.log('Tracked list impression: ${list.id}', name: _logName);
    } catch (e) {
      developer.log('Error tracking list impression: $e', name: _logName);
    }
  }

  /// Track when a user taps on a list to view details
  Future<void> trackListView({
    required SuggestedList list,
    required String userId,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'suggested_list_view',
        parameters: {
          'list_id': list.id,
          'theme': list.theme,
          'place_count': list.placeCount,
          'quality_score': (list.qualityScore * 100).toInt(),
        },
      );
      developer.log('Tracked list view: ${list.id}', name: _logName);
    } catch (e) {
      developer.log('Error tracking list view: $e', name: _logName);
    }
  }

  /// Track when a user saves a list
  Future<void> trackListSave({
    required SuggestedList list,
    required String userId,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'suggested_list_save',
        parameters: {
          'list_id': list.id,
          'theme': list.theme,
          'place_count': list.placeCount,
          'quality_score': (list.qualityScore * 100).toInt(),
          'trigger_reasons': list.triggerReasons.join(','),
        },
      );
      developer.log('Tracked list save: ${list.id}', name: _logName);
    } catch (e) {
      developer.log('Error tracking list save: $e', name: _logName);
    }
  }

  /// Track when a user dismisses a list
  Future<void> trackListDismiss({
    required SuggestedList list,
    required String userId,
    String? reason,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'suggested_list_dismiss',
        parameters: {
          'list_id': list.id,
          'theme': list.theme,
          'place_count': list.placeCount,
          'quality_score': (list.qualityScore * 100).toInt(),
          'dismiss_reason': reason ?? 'unspecified',
        },
      );
      developer.log('Tracked list dismiss: ${list.id}', name: _logName);
    } catch (e) {
      developer.log('Error tracking list dismiss: $e', name: _logName);
    }
  }

  /// Track when a user pins a list
  Future<void> trackListPin({
    required SuggestedList list,
    required String userId,
    required bool isPinned,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'suggested_list_pin',
        parameters: {
          'list_id': list.id,
          'theme': list.theme,
          'is_pinned': isPinned,
        },
      );
      developer.log('Tracked list pin: ${list.id} pinned=$isPinned', name: _logName);
    } catch (e) {
      developer.log('Error tracking list pin: $e', name: _logName);
    }
  }

  /// Track when a user taps on a place within a list
  Future<void> trackPlaceTap({
    required SuggestedList list,
    required String placeId,
    required String userId,
    int? positionInList,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'suggested_list_place_tap',
        parameters: {
          'list_id': list.id,
          'place_id': placeId,
          'position': positionInList ?? -1,
          'theme': list.theme,
        },
      );
      developer.log('Tracked place tap: $placeId in ${list.id}', name: _logName);
    } catch (e) {
      developer.log('Error tracking place tap: $e', name: _logName);
    }
  }

  /// Track when a user visits a place from a suggested list
  Future<void> trackPlaceVisit({
    required String listId,
    required String placeId,
    required String userId,
    Duration? dwellTime,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'suggested_list_place_visit',
        parameters: {
          'list_id': listId,
          'place_id': placeId,
          'dwell_time_minutes': dwellTime?.inMinutes ?? 0,
        },
      );
      developer.log('Tracked place visit: $placeId from $listId', name: _logName);
    } catch (e) {
      developer.log('Error tracking place visit: $e', name: _logName);
    }
  }

  /// Track "Why this list?" view
  Future<void> trackWhyThisListView({
    required SuggestedList list,
    required String userId,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'suggested_list_why_view',
        parameters: {
          'list_id': list.id,
          'trigger_reasons': list.triggerReasons.join(','),
        },
      );
      developer.log('Tracked why-this-list view: ${list.id}', name: _logName);
    } catch (e) {
      developer.log('Error tracking why-this-list view: $e', name: _logName);
    }
  }

  /// Track list generation metrics
  Future<void> trackListGeneration({
    required int listsGenerated,
    required int totalPlaces,
    required double avgQualityScore,
    required List<String> triggerReasons,
    required Duration generationTime,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'suggested_list_generation',
        parameters: {
          'lists_generated': listsGenerated,
          'total_places': totalPlaces,
          'avg_quality_score': (avgQualityScore * 100).toInt(),
          'trigger_reasons': triggerReasons.join(','),
          'generation_time_ms': generationTime.inMilliseconds,
        },
      );
      developer.log(
        'Tracked list generation: $listsGenerated lists in ${generationTime.inMilliseconds}ms',
        name: _logName,
      );
    } catch (e) {
      developer.log('Error tracking list generation: $e', name: _logName);
    }
  }

  /// Set user properties for segmentation
  Future<void> setUserProperties({
    required String userId,
    int? listsViewed,
    int? listsSaved,
    int? placeVisits,
    String? preferredTheme,
  }) async {
    try {
      await _analytics.setUserId(id: userId);

      if (listsViewed != null) {
        await _analytics.setUserProperty(
          name: 'suggested_lists_viewed',
          value: listsViewed.toString(),
        );
      }
      if (listsSaved != null) {
        await _analytics.setUserProperty(
          name: 'suggested_lists_saved',
          value: listsSaved.toString(),
        );
      }
      if (placeVisits != null) {
        await _analytics.setUserProperty(
          name: 'suggested_place_visits',
          value: placeVisits.toString(),
        );
      }
      if (preferredTheme != null) {
        await _analytics.setUserProperty(
          name: 'preferred_list_theme',
          value: preferredTheme,
        );
      }
    } catch (e) {
      developer.log('Error setting user properties: $e', name: _logName);
    }
  }
}
