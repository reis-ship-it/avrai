import 'dart:math' as math;

import 'package:avrai/core/models/user/unified_user.dart';
import 'package:avrai/core/models/expertise/expertise_event.dart';
import 'package:avrai/core/models/expertise/expertise_level.dart';
import 'package:avrai/core/services/expertise/expertise_event_service.dart';
import 'package:avrai/core/services/events/post_event_feedback_service.dart';
import 'package:avrai_knot/services/knot/integrated_knot_recommendation_engine.dart';
import 'package:avrai/core/ai/personality_learning.dart';
import 'package:avrai/core/services/infrastructure/logger.dart';
import 'package:avrai/core/services/social_media/social_media_connection_service.dart';
import 'package:avrai/core/services/infrastructure/supabase_service.dart';
import 'package:avrai/core/services/quantum/quantum_matching_integration_service.dart';
import 'package:avrai/core/services/infrastructure/feature_flag_service.dart';

/// Event Matching Service
///
/// Calculates matching signals (not formal ranking) to help users find likeminded people
/// and events they'll enjoy. This is a matching system, not a competitive ranking.
///
/// **Philosophy:** "Doors, not badges" - Opens doors to likeminded people and events
///
/// **Matching Signals:**
/// - Events hosted count (more events = higher signal)
/// - Event ratings (average rating from attendees)
/// - Followers count (users following the expert)
/// - External social following (if available)
/// - Community recognition (partnerships, collaborations)
/// - Event growth (community building - attendance growth over time)
/// - Active list respects (users adding events to their lists)
///
/// **Locality-Specific Weighting:**
/// - Higher weight for signals in user's locality
/// - Lower weight for signals outside locality
/// - Geographic interaction patterns (where user attends events)
///
/// **What Doors Does This Open?**
/// - Discovery Doors: Users find events from likeminded local experts
/// - Connection Doors: System matches users to events they'll enjoy
/// - Exploration Doors: Users can explore events outside their typical behavior
class EventMatchingService {
  static const String _logName = 'EventMatchingService';
  final AppLogger _logger = const AppLogger(
    defaultTag: 'SPOTS',
    minimumLevel: LogLevel.debug,
  );

  final ExpertiseEventService _eventService;
  final IntegratedKnotRecommendationEngine? _knotRecommendationEngine;
  final PersonalityLearning? _personalityLearning;
  final PostEventFeedbackService? _feedbackService;
  final SocialMediaConnectionService? _socialMediaConnectionService;
  final SupabaseService _supabaseService;
  final QuantumMatchingIntegrationService? _quantumIntegrationService;
  final FeatureFlagService? _featureFlags;

  // Feature flag name for quantum event matching
  static const String _quantumEventMatchingFlag = 'phase19_quantum_event_matching';

  EventMatchingService({
    ExpertiseEventService? eventService,
    IntegratedKnotRecommendationEngine? knotRecommendationEngine,
    PersonalityLearning? personalityLearning,
    PostEventFeedbackService? feedbackService,
    SocialMediaConnectionService? socialMediaConnectionService,
    SupabaseService? supabaseService,
    QuantumMatchingIntegrationService? quantumIntegrationService,
    FeatureFlagService? featureFlags,
  })  : _eventService = eventService ?? ExpertiseEventService(),
        _knotRecommendationEngine = knotRecommendationEngine,
        _personalityLearning = personalityLearning,
        _feedbackService = feedbackService,
        _socialMediaConnectionService = socialMediaConnectionService,
        _supabaseService = supabaseService ?? SupabaseService(),
        _quantumIntegrationService = quantumIntegrationService,
        _featureFlags = featureFlags;

  /// Calculate matching score for an expert hosting events
  ///
  /// **Parameters:**
  /// - `expert`: Expert user to calculate score for
  /// - `user`: User looking for events (for locality-specific weighting)
  /// - `category`: Expertise category
  /// - `locality`: Target locality for matching
  ///
  /// **Returns:**
  /// Matching score (0.0 to 1.0) - higher means better match
  ///
  /// **Philosophy:**
  /// This is NOT a competitive ranking. It's a matching signal to help users
  /// find likeminded people and events they'll enjoy.
  ///
  /// **Phase 19.15 Integration:**
  /// - Uses quantum entanglement matching if enabled via feature flag
  /// - Falls back to classical method if quantum matching is disabled or fails
  /// - Maintains backward compatibility
  Future<double> calculateMatchingScore({
    required UnifiedUser expert,
    required UnifiedUser user,
    required String category,
    required String locality,
  }) async {
    try {
      _logger.info(
        'Calculating matching score: expert=${expert.id}, user=${user.id}, category=$category, locality=$locality',
        tag: _logName,
      );

      // Phase 19.15: Try quantum matching first (if enabled)
      if (_quantumIntegrationService != null && _featureFlags != null) {
        final isQuantumEnabled = await _featureFlags.isEnabled(
          _quantumEventMatchingFlag,
          userId: user.id,
          defaultValue: false,
        );

        if (isQuantumEnabled) {
          try {
            // Get expert's events for quantum matching context
            final expertEvents = await _eventService.getEventsByHost(expert);
            if (expertEvents.isNotEmpty) {
              // Use the most recent or upcoming event for quantum matching
              final eventForMatching = expertEvents.first;

              final quantumResult = await _quantumIntegrationService
                  .calculateUserEventCompatibility(
                user: user,
                event: eventForMatching,
              );

              if (quantumResult != null) {
                // Quantum matching successful - use it as base score
                // Combine with classical signals for locality-specific weighting
                final classicalScore = await _calculateClassicalMatchingScore(
                  expert: expert,
                  user: user,
                  category: category,
                  locality: locality,
                );

                // Hybrid approach: 60% quantum, 40% classical (maintains locality weighting)
                final hybridScore = 0.6 * quantumResult.compatibility +
                    0.4 * classicalScore;

                _logger.info(
                  'Quantum matching used: quantum=${quantumResult.compatibility.toStringAsFixed(3)}, classical=${classicalScore.toStringAsFixed(3)}, hybrid=${hybridScore.toStringAsFixed(3)}',
                  tag: _logName,
                );

                return hybridScore.clamp(0.0, 1.0);
              }
            }
          } catch (e) {
            _logger.warn(
              'Quantum matching failed, falling back to classical: $e',
              tag: _logName,
            );
            // Fall through to classical method
          }
        }
      }

      // Classical method (backward compatibility)
      return await _calculateClassicalMatchingScore(
        expert: expert,
        user: user,
        category: category,
        locality: locality,
      );
    } catch (e) {
      _logger.error('Error calculating matching score',
          error: e, tag: _logName);
      return 0.0;
    }
  }

  /// Calculate classical matching score (original implementation)
  ///
  /// **Phase 19.15:** Extracted to separate method for backward compatibility
  Future<double> _calculateClassicalMatchingScore({
    required UnifiedUser expert,
    required UnifiedUser user,
    required String category,
    required String locality,
  }) async {
    // Get matching signals
    final signals = await getMatchingSignals(
      expert: expert,
      user: user,
      category: category,
      locality: locality,
    );

    // If we couldn't compute any signals (e.g., event service failure),
    // don't apply optional knot compatibility. Return 0.0 for a clear
    // "no match signal available" result.
    if (signals.localityWeight == 0.0) {
      return 0.0;
    }

    // Calculate weighted score based on locality-specific weighting
    double score = 0.0;

    // Events hosted (28% weight, reduced from 30% to make room for knot compatibility)
    score += signals.eventsHostedScore * 0.28;

    // Event ratings (23% weight, reduced from 25%)
    // Normalize 1-5 star rating to 0-1 score.
    score += ((signals.averageRating / 5.0).clamp(0.0, 1.0)) * 0.23;

    // Followers count (14% weight, reduced from 15%)
    score += signals.followersScore * 0.14;

    // External social following (5% weight - if available)
    score += signals.externalSocialScore * 0.05;

    // Community recognition (9% weight, reduced from 10%)
    score += signals.communityRecognitionScore * 0.09;

    // Event growth (9% weight, reduced from 10%)
    score += signals.eventGrowthScore * 0.09;

    // Active list respects (5% weight)
    score += signals.activeListRespectsScore * 0.05;

    // Knot compatibility (7% weight - optional enhancement)
    final knotScore = await _calculateKnotCompatibilityScore(
      expert: expert,
      user: user,
    );
    score += knotScore * 0.07;

    return score.clamp(0.0, 1.0);
  }

  /// Calculate knot compatibility score for event matching
  ///
  /// Uses IntegratedKnotRecommendationEngine to calculate compatibility
  /// between user and expert personalities.
  ///
  /// **Returns:** Compatibility score (0.0 to 1.0), or 0.0 if unavailable
  Future<double> _calculateKnotCompatibilityScore({
    required UnifiedUser expert,
    required UnifiedUser user,
  }) async {
    // If knot services not available, return neutral score
    if (_knotRecommendationEngine == null || _personalityLearning == null) {
      // Optional enhancement: if not wired, don't influence scores.
      return 0.0;
    }

    try {
      // Get personality profiles for user and expert
      final userProfile =
          await _personalityLearning.initializePersonality(user.id);
      final expertProfile =
          await _personalityLearning.initializePersonality(expert.id);

      // Calculate integrated compatibility (quantum + knot topology)
      final compatibility =
          await _knotRecommendationEngine.calculateIntegratedCompatibility(
        profileA: userProfile,
        profileB: expertProfile,
      );

      _logger.debug(
        'Knot compatibility for expert ${expert.id}: ${(compatibility.combined * 100).toStringAsFixed(1)}% '
        '(quantum: ${(compatibility.quantum * 100).toStringAsFixed(1)}%, '
        'knot: ${(compatibility.knot * 100).toStringAsFixed(1)}%)',
        tag: _logName,
      );

      return compatibility.combined;
    } catch (e) {
      _logger.warn(
        'Error calculating knot compatibility: $e, using neutral score',
        tag: _logName,
      );
      // Don't influence scores on error (don't break matching).
      return 0.0;
    }
  }

  /// Get detailed matching signals breakdown
  ///
  /// **Returns:**
  /// MatchingSignals object with all signal components
  /// Useful for debugging and UI display
  Future<MatchingSignals> getMatchingSignals({
    required UnifiedUser expert,
    required UnifiedUser user,
    required String category,
    required String locality,
  }) async {
    try {
      // Get events hosted by expert
      final events = await _eventService.getEventsByHost(expert);
      final categoryEvents =
          events.where((e) => e.category == category).toList();

      // Calculate locality-specific weighting
      final localityWeight = _calculateLocalityWeight(
        expert: expert,
        user: user,
        locality: locality,
        events: categoryEvents,
      );

      // Events hosted count (more events = higher signal)
      final eventsHostedCount = categoryEvents.length;
      final eventsHostedScore =
          _normalizeEventsHosted(eventsHostedCount) * localityWeight;

      // Event ratings (average rating from attendees)
      final averageRating = await _calculateAverageRating(categoryEvents);
      // Note: ratingScore calculated but used directly in signals.averageRating

      // Followers count (users following the expert)
      final followersCount =
          expert.friends.length; // Using friends as proxy for followers
      final followersScore =
          _normalizeFollowers(followersCount) * localityWeight;

      // External social following (if available)
      final externalSocialScore =
          (await _getExternalSocialScore(expert)) * localityWeight;

      // Community recognition (partnerships, collaborations)
      final communityRecognitionScore = await _calculateCommunityRecognition(
            expert: expert,
            category: category,
            locality: locality,
          ) *
          localityWeight;

      // Event growth (community building - attendance growth over time)
      final eventGrowthScore =
          _calculateEventGrowth(categoryEvents) * localityWeight;

      // Active list respects (users adding events to their lists)
      final activeListRespectsScore = await _calculateActiveListRespects(
            expert: expert,
            category: category,
          ) *
          localityWeight;

      return MatchingSignals(
        eventsHostedCount: eventsHostedCount,
        eventsHostedScore: eventsHostedScore,
        averageRating: averageRating,
        followersCount: followersCount,
        followersScore: followersScore,
        externalSocialScore: externalSocialScore,
        communityRecognitionScore: communityRecognitionScore,
        eventGrowthScore: eventGrowthScore,
        activeListRespectsScore: activeListRespectsScore,
        localityWeight: localityWeight,
      );
    } catch (e) {
      _logger.error('Error getting matching signals', error: e, tag: _logName);
      return MatchingSignals.empty();
    }
  }

  /// Calculate locality-specific weighting
  ///
  /// **Rules:**
  /// - Higher weight (1.0) for signals in user's locality
  /// - Lower weight (0.5-0.7) for signals outside locality
  /// - Considers geographic interaction patterns (where user attends events)
  ///
  /// **Returns:**
  /// Weight multiplier (0.0 to 1.0)
  double _calculateLocalityWeight({
    required UnifiedUser expert,
    required UnifiedUser user,
    required String locality,
    required List<ExpertiseEvent> events,
  }) {
    // Extract user's locality from location string
    final userLocality = _extractLocality(user.location);
    final expertLocality = _extractLocality(expert.location);

    // If expert is in same locality as target locality, full weight
    if (expertLocality != null &&
        expertLocality.toLowerCase() == locality.toLowerCase()) {
      return 1.0;
    }

    // If user's locality matches target locality, higher weight for expert in same locality
    if (userLocality != null &&
        userLocality.toLowerCase() == locality.toLowerCase() &&
        expertLocality != null &&
        expertLocality.toLowerCase() == locality.toLowerCase()) {
      return 1.0;
    }

    // Check if user has attended events in this locality (geographic interaction patterns)
    final userAttendedInLocality = events.any((e) {
      final eventLocality = _extractLocality(e.location);
      return eventLocality != null &&
          eventLocality.toLowerCase() == locality.toLowerCase();
    });

    if (userAttendedInLocality) {
      return 0.8; // Higher weight if user has attended events in this locality
    }

    // Default: lower weight for signals outside locality
    return 0.6;
  }

  /// Extract locality from location string
  /// Location format: "Locality, City, State, Country" or "Locality, City"
  String? _extractLocality(String? location) {
    if (location == null || location.isEmpty) return null;
    return location.split(',').first.trim();
  }

  /// Normalize events hosted count to 0-1 scale
  /// More events = higher score (logarithmic scale)
  double _normalizeEventsHosted(int count) {
    if (count == 0) return 0.0;
    // Logarithmic scale: 1 event = 0.3, 5 events = 0.7, 10+ events = 1.0
    return (1.0 - (1.0 / (1.0 + count * 0.2))).clamp(0.0, 1.0);
  }

  /// Calculate average rating from event feedback
  ///
  /// Returns the **1-5** average rating across events, when feedback is available.
  ///
  /// If feedback isn’t available, we fall back to an **honest neutral** signal:
  /// - 0.0 if there’s no data at all
  /// - otherwise a small engagement-based proxy (occupancy), mapped to ~3.0-5.0
  Future<double> _calculateAverageRating(List<ExpertiseEvent> events) async {
    if (events.isEmpty) return 0.0;

    if (_feedbackService != null) {
      double sum = 0.0;
      int count = 0;

      for (final event in events) {
        try {
          final feedback = await _feedbackService.getEventFeedback(event.id);
          if (feedback.isEmpty) continue;
          final avgForEvent =
              feedback.map((f) => f.overallRating).reduce((a, b) => a + b) /
                  feedback.length;
          // Clamp to the expected 1-5 star range (defensive; don't explode scoring).
          sum += avgForEvent.clamp(1.0, 5.0);
          count++;
        } catch (e) {
          // Don't fail the whole matching computation if feedback lookup fails.
          _logger.warn('Failed to read feedback for event ${event.id}: $e',
              tag: _logName);
        }
      }

      if (count > 0) {
        return (sum / count).clamp(1.0, 5.0);
      }
    }

    // No feedback available: use a lightweight occupancy proxy (honest but not a rating).
    return _occupancyProxyRating(events);
  }

  double _occupancyProxyRating(List<ExpertiseEvent> events) {
    // Map occupancy (0-1) to a conservative ~3.0-5.0 range.
    final occupancies = <double>[];
    for (final e in events) {
      if (e.maxAttendees <= 0) continue;
      occupancies.add((e.attendeeCount / e.maxAttendees).clamp(0.0, 1.0));
    }
    if (occupancies.isEmpty) return 0.0;
    final avg = occupancies.reduce((a, b) => a + b) / occupancies.length;
    return (3.0 + avg * 2.0).clamp(1.0, 5.0);
  }

  /// Normalize followers count to 0-1 scale
  /// More followers = higher score (logarithmic scale)
  double _normalizeFollowers(int count) {
    if (count == 0) return 0.0;
    // Logarithmic scale: 10 followers = 0.3, 50 followers = 0.7, 100+ followers = 1.0
    return (1.0 - (1.0 / (1.0 + count * 0.05))).clamp(0.0, 1.0);
  }

  /// Get external social following score
  ///
  /// Returns a 0-1 score based on follower counts across connected platforms.
  ///
  /// If no social connections exist (or service isn't wired), returns 0.0 (no signal).
  Future<double> _getExternalSocialScore(UnifiedUser expert) async {
    final svc = _socialMediaConnectionService;
    if (svc == null) return 0.0;

    try {
      final connections = await svc.getActiveConnections(expert.id);
      if (connections.isEmpty) return 0.0;

      int maxFollowers = 0;
      for (final c in connections) {
        final profile = await svc.fetchProfileData(c);
        final followers = _extractFollowerCount(profile);
        if (followers != null && followers > maxFollowers) {
          maxFollowers = followers;
        }
      }

      if (maxFollowers <= 0) return 0.0;

      // Log-scaled normalization: ~1M followers maps near 1.0.
      final denom = math.log(1000000.0 + 1.0);
      final score = (math.log(maxFollowers.toDouble() + 1.0) / denom)
          .clamp(0.0, 1.0);
      return score;
    } catch (e) {
      _logger.warn('Failed to compute external social score: $e', tag: _logName);
      return 0.0;
    }
  }

  int? _extractFollowerCount(Map<String, dynamic> profileData) {
    // Accept a handful of common keys across platforms/placeholder payloads.
    final candidates = <dynamic>[
      profileData['followers_count'],
      profileData['followersCount'],
      profileData['followers'],
      profileData['followersCountTotal'],
      profileData['connections_count'],
      profileData['connectionsCount'],
      (profileData['profile'] is Map ? (profileData['profile'] as Map)['followers_count'] : null),
      (profileData['profile'] is Map ? (profileData['profile'] as Map)['followersCount'] : null),
      (profileData['profile'] is Map ? (profileData['profile'] as Map)['connectionsCount'] : null),
    ];

    for (final v in candidates) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) {
        final parsed = int.tryParse(v);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  /// Calculate community recognition score
  ///
  /// **Note:** In production, this would query partnerships, collaborations, etc.
  /// For now, returns placeholder based on expertise level
  Future<double> _calculateCommunityRecognition({
    required UnifiedUser expert,
    required String category,
    required String locality,
  }) async {
    // Placeholder: Use expertise level as proxy for community recognition
    final level = expert.getExpertiseLevel(category);
    if (level == null) return 0.0;

    // Higher expertise levels = more community recognition
    return (level.index + 1) / ExpertiseLevel.values.length;
  }

  /// Calculate event growth score
  ///
  /// Measures community building - attendance growth over time
  /// Events that grow in size show community value
  double _calculateEventGrowth(List<ExpertiseEvent> events) {
    if (events.length < 2) {
      return 0.5; // Need at least 2 events to measure growth
    }

    // Sort events by start time
    final sortedEvents = List<ExpertiseEvent>.from(events)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    // Calculate growth trend
    double growthSum = 0.0;
    int growthCount = 0;

    for (int i = 1; i < sortedEvents.length; i++) {
      final previous = sortedEvents[i - 1];
      final current = sortedEvents[i];

      if (previous.attendeeCount > 0) {
        final growth = (current.attendeeCount - previous.attendeeCount) /
            previous.attendeeCount;
        growthSum += growth;
        growthCount++;
      }
    }

    if (growthCount == 0) return 0.5;

    final averageGrowth = growthSum / growthCount;
    // Normalize: positive growth = higher score, negative growth = lower score
    return (0.5 + (averageGrowth * 0.5)).clamp(0.0, 1.0);
  }

  /// Calculate active list respects score
  ///
  /// Returns a 0-1 score based on how much the community “respects” this expert’s
  /// curated lists in the given category.
  ///
  /// If Supabase isn’t available, returns 0.0 (no signal) instead of inventing a score.
  Future<double> _calculateActiveListRespects({
    required UnifiedUser expert,
    required String category,
  }) async {
    final client = _supabaseService.tryGetClient();
    if (client == null) return 0.0;

    try {
      // Primary: use list aggregates (cheap and available offline when synced).
      final lists = await client
          .from('spot_lists')
          .select('id, respect_count, category, created_by')
          .eq('created_by', expert.id)
          .eq('category', category);

      final rows = (lists as List).cast<Map<String, dynamic>>();
      if (rows.isEmpty) return 0.0;

      final totalRespects = rows.fold<int>(0, (sum, r) {
        final v = r['respect_count'];
        if (v is int) return sum + v;
        if (v is num) return sum + v.toInt();
        return sum;
      });

      // Optional: recency signal (last 30 days respects) if available.
      int recentRespects = 0;
      try {
        final cutoff = DateTime.now().subtract(const Duration(days: 30));
        final respects = await client
            .from('user_respects')
            .select('id, created_at, list_id, spot_lists!inner(created_by, category)')
            .eq('spot_lists.created_by', expert.id)
            .eq('spot_lists.category', category)
            .gte('created_at', cutoff.toIso8601String());
        recentRespects = (respects as List).length;
      } catch (e) {
        // Ignore: schema/relationship may vary; we still have aggregate counts.
        _logger.debug('Recent respects query unavailable: $e', tag: _logName);
      }

      final totalScore = _logNormalize(totalRespects, pivot: 100);
      final recentScore = (recentRespects / 20.0).clamp(0.0, 1.0);

      // Combine: total respect matters more, but recency boosts activity.
      return (totalScore * 0.65 + recentScore * 0.35).clamp(0.0, 1.0);
    } catch (e) {
      _logger.warn('Failed to compute list respects: $e', tag: _logName);
      return 0.0;
    }
  }

  double _logNormalize(int value, {required int pivot}) {
    if (value <= 0) return 0.0;
    final denom = math.log(pivot.toDouble() + 1.0);
    if (denom == 0.0) return 0.0;
    return (math.log(value.toDouble() + 1.0) / denom).clamp(0.0, 1.0);
  }
}

/// Matching Signals Model
///
/// Contains all matching signal components for debugging and UI display
class MatchingSignals {
  final int eventsHostedCount;
  final double eventsHostedScore;
  final double averageRating;
  final int followersCount;
  final double followersScore;
  final double externalSocialScore;
  final double communityRecognitionScore;
  final double eventGrowthScore;
  final double activeListRespectsScore;
  final double localityWeight;

  const MatchingSignals({
    required this.eventsHostedCount,
    required this.eventsHostedScore,
    required this.averageRating,
    required this.followersCount,
    required this.followersScore,
    required this.externalSocialScore,
    required this.communityRecognitionScore,
    required this.eventGrowthScore,
    required this.activeListRespectsScore,
    required this.localityWeight,
  });

  factory MatchingSignals.empty() {
    return const MatchingSignals(
      eventsHostedCount: 0,
      eventsHostedScore: 0.0,
      averageRating: 0.0,
      followersCount: 0,
      followersScore: 0.0,
      externalSocialScore: 0.0,
      communityRecognitionScore: 0.0,
      eventGrowthScore: 0.0,
      activeListRespectsScore: 0.0,
      localityWeight: 0.0,
    );
  }
}
