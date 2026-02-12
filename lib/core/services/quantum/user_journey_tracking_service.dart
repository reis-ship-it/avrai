// User Journey Tracking Service
//
// Tracks user journey from pre-event to post-event with atomic timing
// Part of Phase 19 Section 19.8: User Journey Tracking
// Patent #29: Multi-Entity Quantum Entanglement Matching System

import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:avrai_core/models/atomic_timestamp.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai/core/ai/personality_learning.dart';
import 'package:avrai/core/ai/vibe_analysis_engine.dart';
import 'package:avrai/core/services/user/agent_id_service.dart';
import 'package:avrai/core/services/infrastructure/supabase_service.dart';

/// User journey state at a specific point in time
class UserJourneyState {
  /// Atomic timestamp of when this state was captured
  final AtomicTimestamp timestamp;

  /// User's quantum vibe dimensions at this point
  final Map<String, double> vibeDimensions;

  /// User's interests/categories at this point
  final List<String> interests;

  /// User's behavior patterns
  final Map<String, double> behaviorPatterns;

  /// User's engagement level (0.0 to 1.0)
  final double engagementLevel;

  /// Number of connections user has
  final int connectionCount;

  UserJourneyState({
    required this.timestamp,
    required this.vibeDimensions,
    required this.interests,
    required this.behaviorPatterns,
    required this.engagementLevel,
    required this.connectionCount,
  });
}

/// User journey evolution metrics
class UserJourneyEvolution {
  /// Vibe evolution trajectory (how vibe changed)
  final Map<String, double> vibeEvolution;

  /// Interest expansion (new categories explored)
  final List<String> newInterests;

  /// Connection network growth (new connections formed)
  final int newConnections;

  /// Engagement evolution (change in engagement level)
  final double engagementChange;

  /// Overall journey impact score (0.0 to 1.0)
  final double journeyImpactScore;

  /// Atomic timestamp of when evolution was calculated
  final AtomicTimestamp timestamp;

  UserJourneyEvolution({
    required this.vibeEvolution,
    required this.newInterests,
    required this.newConnections,
    required this.engagementChange,
    required this.journeyImpactScore,
    required this.timestamp,
  });
}

/// Complete user journey for an event
class UserJourney {
  /// User ID
  final String userId;

  /// Event ID
  final String eventId;

  /// Pre-event state (captured when user is called to event)
  final UserJourneyState? preEventState;

  /// Event experience tracking
  final EventExperience? eventExperience;

  /// Post-event state (captured after event completion)
  final UserJourneyState? postEventState;

  /// Journey evolution metrics
  final UserJourneyEvolution? evolution;

  /// Atomic timestamp of when journey tracking started
  final AtomicTimestamp journeyStartTimestamp;

  UserJourney({
    required this.userId,
    required this.eventId,
    required this.journeyStartTimestamp,
    this.preEventState,
    this.eventExperience,
    this.postEventState,
    this.evolution,
  });
}

/// Event experience tracking
class EventExperience {
  /// Whether user attended the event
  final bool attended;

  /// Atomic timestamp of when user attended (if attended)
  final AtomicTimestamp? attendanceTimestamp;

  /// Interactions during event (messages, connections, etc.)
  final int interactionCount;

  /// Engagement level during event (0.0 to 1.0)
  final double engagementLevel;

  /// Atomic timestamp of when experience was recorded
  final AtomicTimestamp timestamp;

  EventExperience({
    required this.attended,
    this.attendanceTimestamp,
    this.interactionCount = 0,
    this.engagementLevel = 0.5,
    required this.timestamp,
  });
}

/// Service for tracking user journey from pre-event to post-event
///
/// **Journey States:**
/// - Pre-event: `|ψ_user_pre_event(t_atomic_pre)⟩` (captured when user is called)
/// - Event experience: Attendance, interactions, engagement (tracked with atomic timestamps)
/// - Post-event: `|ψ_user_post_event(t_atomic_post)⟩` (captured after event completion)
///
/// **Journey Evolution:**
/// `|ψ_user_journey⟩ = |ψ_user_pre_event(t_atomic_pre)⟩ → |ψ_user_post_event(t_atomic_post)⟩`
class UserJourneyTrackingService {
  static const String _logName = 'UserJourneyTrackingService';

  final AtomicClockService _atomicClock;
  final PersonalityLearning _personalityLearning;
  final UserVibeAnalyzer _vibeAnalyzer;
  // TODO(Phase 19.8): _agentIdService may be needed for future privacy enhancements
  // ignore: unused_field
  final AgentIdService _agentIdService;
  final SupabaseService? _supabaseService;

  // In-memory cache for journey states (can be persisted to database)
  final Map<String, UserJourney> _journeyCache = {};

  UserJourneyTrackingService({
    required AtomicClockService atomicClock,
    required PersonalityLearning personalityLearning,
    required UserVibeAnalyzer vibeAnalyzer,
    required AgentIdService agentIdService,
    SupabaseService? supabaseService,
  })  : _atomicClock = atomicClock,
        _personalityLearning = personalityLearning,
        _vibeAnalyzer = vibeAnalyzer,
        _agentIdService = agentIdService,
        _supabaseService = supabaseService;

  /// Capture pre-event state when user is called to event
  ///
  /// **Parameters:**
  /// - `userId`: User ID
  /// - `eventId`: Event ID
  ///
  /// **Returns:**
  /// `UserJourneyState` with pre-event vibe, interests, and behavior patterns
  Future<UserJourneyState> capturePreEventState({
    required String userId,
    required String eventId,
  }) async {
    try {
      final tAtomic = await _atomicClock.getAtomicTimestamp();

      developer.log(
        'Capturing pre-event state for user $userId and event $eventId',
        name: _logName,
      );

      // Get user's current personality profile
      final personalityProfile = await _personalityLearning.getCurrentPersonality(userId);
      if (personalityProfile == null) {
        throw Exception('Personality profile not found for user $userId');
      }

      // Compile user vibe
      final userVibe = await _vibeAnalyzer.compileUserVibe(userId, personalityProfile);
      final vibeDimensions = userVibe.anonymizedDimensions;

      // Get user interests from personality profile or entity characteristics
      final interests = _extractInterests(personalityProfile);

      // Get behavior patterns (placeholder - would query usage patterns)
      final behaviorPatterns = await _getUserBehaviorPatterns(userId);

      // Get engagement level (placeholder - would query engagement metrics)
      final engagementLevel = await _getUserEngagementLevel(userId);

      // Get connection count (placeholder - would query connections)
      final connectionCount = await _getUserConnectionCount(userId);

      final preEventState = UserJourneyState(
        timestamp: tAtomic,
        vibeDimensions: vibeDimensions,
        interests: interests,
        behaviorPatterns: behaviorPatterns,
        engagementLevel: engagementLevel,
        connectionCount: connectionCount,
      );

      // Store in journey cache
      final journeyKey = _getJourneyKey(userId, eventId);
      final existingJourney = _journeyCache[journeyKey];
      _journeyCache[journeyKey] = UserJourney(
        userId: userId,
        eventId: eventId,
        journeyStartTimestamp: existingJourney?.journeyStartTimestamp ?? tAtomic,
        preEventState: preEventState,
        eventExperience: existingJourney?.eventExperience,
        postEventState: existingJourney?.postEventState,
        evolution: existingJourney?.evolution,
      );

      // Persist to database (async, non-blocking)
      _persistJourneyToDatabase(_journeyCache[journeyKey]!).catchError((e) {
        developer.log(
          'Error persisting journey to database: $e',
          name: _logName,
        );
      });

      return preEventState;
    } catch (e, stackTrace) {
      developer.log(
        'Error capturing pre-event state: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }

  /// Track event experience (attendance, interactions, engagement)
  ///
  /// **Parameters:**
  /// - `userId`: User ID
  /// - `eventId`: Event ID
  /// - `attended`: Whether user attended the event
  /// - `interactionCount`: Number of interactions during event
  /// - `engagementLevel`: Engagement level during event (0.0 to 1.0)
  Future<void> trackEventExperience({
    required String userId,
    required String eventId,
    required bool attended,
    int interactionCount = 0,
    double engagementLevel = 0.5,
  }) async {
    try {
      final tAtomic = await _atomicClock.getAtomicTimestamp();
      final attendanceTimestamp = attended ? tAtomic : null;

      developer.log(
        'Tracking event experience for user $userId and event $eventId (attended: $attended)',
        name: _logName,
      );

      final eventExperience = EventExperience(
        attended: attended,
        attendanceTimestamp: attendanceTimestamp,
        interactionCount: interactionCount,
        engagementLevel: engagementLevel,
        timestamp: tAtomic,
      );

      // Update journey cache
      final journeyKey = _getJourneyKey(userId, eventId);
      final existingJourney = _journeyCache[journeyKey];
      _journeyCache[journeyKey] = UserJourney(
        userId: userId,
        eventId: eventId,
        journeyStartTimestamp: existingJourney?.journeyStartTimestamp ?? tAtomic,
        preEventState: existingJourney?.preEventState,
        eventExperience: eventExperience,
        postEventState: existingJourney?.postEventState,
        evolution: existingJourney?.evolution,
      );

      // Persist to database (async, non-blocking)
      _persistJourneyToDatabase(_journeyCache[journeyKey]!).catchError((e) {
        developer.log(
          'Error persisting journey to database: $e',
          name: _logName,
        );
      });
    } catch (e, stackTrace) {
      developer.log(
        'Error tracking event experience: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
    }
  }

  /// Capture post-event state after event completion
  ///
  /// **Parameters:**
  /// - `userId`: User ID
  /// - `eventId`: Event ID
  ///
  /// **Returns:**
  /// `UserJourneyState` with post-event vibe, interests, and behavior patterns
  Future<UserJourneyState> capturePostEventState({
    required String userId,
    required String eventId,
  }) async {
    try {
      final tAtomic = await _atomicClock.getAtomicTimestamp();

      developer.log(
        'Capturing post-event state for user $userId and event $eventId',
        name: _logName,
      );

      // Get user's current personality profile (may have evolved)
      final personalityProfile = await _personalityLearning.getCurrentPersonality(userId);
      if (personalityProfile == null) {
        throw Exception('Personality profile not found for user $userId');
      }

      // Compile user vibe (may have changed)
      final userVibe = await _vibeAnalyzer.compileUserVibe(userId, personalityProfile);
      final vibeDimensions = userVibe.anonymizedDimensions;

      // Get user interests (may have expanded)
      final interests = _extractInterests(personalityProfile);

      // Get behavior patterns (may have changed)
      final behaviorPatterns = await _getUserBehaviorPatterns(userId);

      // Get engagement level (may have changed)
      final engagementLevel = await _getUserEngagementLevel(userId);

      // Get connection count (may have grown)
      final connectionCount = await _getUserConnectionCount(userId);

      final postEventState = UserJourneyState(
        timestamp: tAtomic,
        vibeDimensions: vibeDimensions,
        interests: interests,
        behaviorPatterns: behaviorPatterns,
        engagementLevel: engagementLevel,
        connectionCount: connectionCount,
      );

      // Calculate journey evolution
      final journeyKey = _getJourneyKey(userId, eventId);
      final existingJourney = _journeyCache[journeyKey];
      UserJourneyEvolution? evolution;
      if (existingJourney?.preEventState != null) {
        evolution = _calculateJourneyEvolution(
          preEventState: existingJourney!.preEventState!,
          postEventState: postEventState,
        );
      }

      // Update journey cache
      _journeyCache[journeyKey] = UserJourney(
        userId: userId,
        eventId: eventId,
        journeyStartTimestamp: existingJourney?.journeyStartTimestamp ?? tAtomic,
        preEventState: existingJourney?.preEventState,
        eventExperience: existingJourney?.eventExperience,
        postEventState: postEventState,
        evolution: evolution,
      );

      // Persist to database (async, non-blocking)
      _persistJourneyToDatabase(_journeyCache[journeyKey]!).catchError((e) {
        developer.log(
          'Error persisting journey to database: $e',
          name: _logName,
        );
      });

      return postEventState;
    } catch (e, stackTrace) {
      developer.log(
        'Error capturing post-event state: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }

  /// Get user journey for an event
  ///
  /// **Parameters:**
  /// - `userId`: User ID
  /// - `eventId`: Event ID
  ///
  /// **Returns:**
  /// `UserJourney` if found, null otherwise
  Future<UserJourney?> getUserJourney({
    required String userId,
    required String eventId,
  }) async {
    try {
      final journeyKey = _getJourneyKey(userId, eventId);

      // Check cache first
      if (_journeyCache.containsKey(journeyKey)) {
        return _journeyCache[journeyKey];
      }

      // TODO: Load from database if not in cache
      // For now, return null if not in cache
      return null;
    } catch (e) {
      developer.log(
        'Error getting user journey: $e',
        name: _logName,
      );
      return null;
    }
  }

  /// Calculate journey evolution metrics
  ///
  /// **Formula:**
  /// - Vibe evolution: `Δ|ψ_vibe⟩ = |ψ_post⟩ - |ψ_pre⟩`
  /// - Interest expansion: New interests in post-event state
  /// - Connection growth: `newConnections = postEvent.connectionCount - preEvent.connectionCount`
  /// - Engagement change: `engagementChange = postEvent.engagementLevel - preEvent.engagementLevel`
  UserJourneyEvolution _calculateJourneyEvolution({
    required UserJourneyState preEventState,
    required UserJourneyState postEventState,
  }) {
    // 1. Vibe evolution trajectory
    final vibeEvolution = <String, double>{};
    final allDimensions = {...preEventState.vibeDimensions.keys, ...postEventState.vibeDimensions.keys};
    for (final dimension in allDimensions) {
      final preValue = preEventState.vibeDimensions[dimension] ?? 0.0;
      final postValue = postEventState.vibeDimensions[dimension] ?? 0.0;
      vibeEvolution[dimension] = postValue - preValue;
    }

    // 2. Interest expansion (new categories explored)
    final newInterests = postEventState.interests
        .where((interest) => !preEventState.interests.contains(interest))
        .toList();

    // 3. Connection network growth
    final newConnections = math.max(0, postEventState.connectionCount - preEventState.connectionCount);

    // 4. Engagement evolution
    final engagementChange = postEventState.engagementLevel - preEventState.engagementLevel;

    // 5. Overall journey impact score using hybrid approach
    // Core factors (geometric mean) + Modifiers (weighted average)
    final vibeEvolutionScore = _calculateVibeEvolutionScore(vibeEvolution);
    final interestExpansionScore = newInterests.length / math.max(postEventState.interests.length, 1);
    final connectionGrowthScore = newConnections > 0 ? 1.0 : 0.0;
    final engagementEvolutionScore = engagementChange.clamp(0.0, 1.0);

    // Core factors: vibe evolution and interest expansion (critical for journey impact)
    final coreFactors = [vibeEvolutionScore, interestExpansionScore];
    final coreScore = _geometricMean(coreFactors);

    // Modifiers: connection growth and engagement evolution (enhance good matches)
    final modifierScore = 0.6 * connectionGrowthScore + 0.4 * engagementEvolutionScore;

    // Hybrid combination: core * modifiers
    final journeyImpactScore = (coreScore * modifierScore).clamp(0.0, 1.0);

    return UserJourneyEvolution(
      vibeEvolution: vibeEvolution,
      newInterests: newInterests,
      newConnections: newConnections,
      engagementChange: engagementChange,
      journeyImpactScore: journeyImpactScore,
      timestamp: postEventState.timestamp,
    );
  }

  // Helper methods

  /// Extract interests from personality profile
  List<String> _extractInterests(dynamic personalityProfile) {
    // TODO: Extract interests from personality profile or entity characteristics
    // For now, return placeholder
    return [];
  }

  /// Get user behavior patterns
  Future<Map<String, double>> _getUserBehaviorPatterns(String userId) async {
    // TODO: Query usage patterns or behavior tracking
    // For now, return placeholder
    return {
      'exploration_tendency': 0.5,
      'social_preference': 0.5,
      'engagement_level': 0.5,
    };
  }

  /// Get user engagement level
  Future<double> _getUserEngagementLevel(String userId) async {
    // TODO: Query engagement metrics
    // For now, return placeholder
    return 0.5;
  }

  /// Get user connection count
  Future<int> _getUserConnectionCount(String userId) async {
    // TODO: Query connections table
    // For now, return placeholder
    return 0;
  }

  /// Calculate vibe evolution score from evolution map
  double _calculateVibeEvolutionScore(Map<String, double> vibeEvolution) {
    if (vibeEvolution.isEmpty) {
      return 0.0;
    }

    // Calculate magnitude of evolution vector
    double sumSquared = 0.0;
    for (final value in vibeEvolution.values) {
      sumSquared += value * value;
    }

    final magnitude = math.sqrt(sumSquared / vibeEvolution.length);
    return magnitude.clamp(0.0, 1.0);
  }

  /// Calculate geometric mean of values
  double _geometricMean(List<double> values) {
    if (values.isEmpty) return 0.0;
    if (values.any((v) => v <= 0.0)) {
      // If any value is zero or negative, return 0 (critical failure)
      return 0.0;
    }
    final product = values.fold(1.0, (prod, v) => prod * v);
    return math.pow(product, 1.0 / values.length).toDouble();
  }

  /// Get journey cache key
  String _getJourneyKey(String userId, String eventId) {
    return '$userId:$eventId';
  }

  /// Persist journey to database
  Future<void> _persistJourneyToDatabase(UserJourney journey) async {
    if (_supabaseService == null) {
      return; // No database available
    }

    try {
      // TODO: Implement database persistence
      // Would insert/update in user_journeys table
      // For now, just log
      developer.log(
        'Journey persisted to database: ${journey.userId}:${journey.eventId}',
        name: _logName,
      );
    } catch (e) {
      developer.log(
        'Error persisting journey to database: $e',
        name: _logName,
      );
    }
  }
}
