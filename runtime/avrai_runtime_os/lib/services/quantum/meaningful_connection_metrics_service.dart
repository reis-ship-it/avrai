// Meaningful Connection Metrics Service
//
// Implements comprehensive metrics for measuring meaningful connections
// Part of Phase 19 Section 19.7: Meaningful Connection Metrics System
// Patent #29: Multi-Entity Quantum Entanglement Matching System

import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:avrai_core/models/atomic_timestamp.dart';
import 'package:avrai_core/models/expertise/expertise_event.dart';
import 'package:avrai_core/models/user.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_quantum/services/quantum/quantum_entanglement_service.dart';
import 'package:avrai_runtime_os/ai/personality_learning.dart';
import 'package:avrai_runtime_os/ai/vibe_analysis_engine.dart';
import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'package:avrai_knot/services/knot/knot_evolution_string_service.dart';
import 'package:avrai_knot/services/knot/knot_worldsheet_service.dart';
import 'package:avrai_knot/services/knot/knot_fabric_service.dart';
import 'package:avrai_knot/services/knot/knot_storage_service.dart';
import 'package:avrai_core/models/personality_knot.dart';

/// Meaningful connection metrics result
class MeaningfulConnectionMetrics {
  /// Repeating interactions rate (0.0 to 1.0)
  final double repeatingInteractionsRate;

  /// Event continuation rate (0.0 to 1.0)
  final double eventContinuationRate;

  /// Vibe evolution score (0.0 to 1.0)
  final double vibeEvolutionScore;

  /// Connection persistence rate (0.0 to 1.0)
  final double connectionPersistenceRate;

  /// Transformative impact score (0.0 to 1.0)
  final double transformativeImpactScore;

  /// Overall meaningful connection score (0.0 to 1.0)
  final double meaningfulConnectionScore;

  /// Atomic timestamp of when metrics were calculated
  final AtomicTimestamp timestamp;

  MeaningfulConnectionMetrics({
    required this.repeatingInteractionsRate,
    required this.eventContinuationRate,
    required this.vibeEvolutionScore,
    required this.connectionPersistenceRate,
    required this.transformativeImpactScore,
    required this.meaningfulConnectionScore,
    required this.timestamp,
  });
}

/// Service for calculating meaningful connection metrics
///
/// **Meaningful Connection Score Formula:**
/// ```
/// meaningful_connection_score = weighted_average(
///   repeating_interactions_rate (weight: 0.30),
///   event_continuation_rate (weight: 0.30),
///   vibe_evolution_score (weight: 0.25),
///   connection_persistence_rate (weight: 0.15)
/// )
/// ```
///
/// **Metrics:**
/// - Repeating interactions: Users who interact with event participants/entities after event
/// - Event continuation: Users who attend similar events after this event
/// - Vibe evolution: User's quantum vibe changing after event (choosing similar experiences)
/// - Connection persistence: Users maintaining connections formed at event
/// - Transformative impact: User behavior changes indicating meaningful experience
class MeaningfulConnectionMetricsService {
  static const String _logName = 'MeaningfulConnectionMetricsService';

  final AtomicClockService _atomicClock;
  // TODO(Phase 19.7): _entanglementService may be needed for event similarity calculation
  // ignore: unused_field
  final QuantumEntanglementService _entanglementService;
  final PersonalityLearning _personalityLearning;
  final UserVibeAnalyzer _vibeAnalyzer;
  final SupabaseService _supabaseService;
  final AgentIdService _agentIdService;
  final KnotEvolutionStringService _stringService;
  final KnotWorldsheetService _worldsheetService;
  final KnotFabricService _fabricService;
  // ignore: unused_field
  final KnotStorageService _knotStorage;

  // Time windows for metrics
  static const Duration _postEventInteractionWindow = Duration(days: 30);
  // TODO(Phase 19.7): _eventContinuationWindow may be needed for future enhancements
  // ignore: unused_field
  static const Duration _eventContinuationWindow = Duration(days: 90);
  // TODO(Phase 19.7): _vibeEvolutionWindow may be needed for future enhancements
  // ignore: unused_field
  static const Duration _vibeEvolutionWindow = Duration(days: 60);
  // TODO(Phase 19.7): _connectionPersistenceWindow may be needed for future enhancements
  // ignore: unused_field
  static const Duration _connectionPersistenceWindow = Duration(days: 90);

  MeaningfulConnectionMetricsService({
    required AtomicClockService atomicClock,
    required QuantumEntanglementService entanglementService,
    required PersonalityLearning personalityLearning,
    required UserVibeAnalyzer vibeAnalyzer,
    required AgentIdService agentIdService,
    required SupabaseService supabaseService,
    required KnotEvolutionStringService stringService,
    required KnotWorldsheetService worldsheetService,
    required KnotFabricService fabricService,
    required KnotStorageService knotStorage,
  })  : _atomicClock = atomicClock,
        _entanglementService = entanglementService,
        _personalityLearning = personalityLearning,
        _vibeAnalyzer = vibeAnalyzer,
        _agentIdService = agentIdService,
        _supabaseService = supabaseService,
        _stringService = stringService,
        _worldsheetService = worldsheetService,
        _fabricService = fabricService,
        _knotStorage = knotStorage;

  /// Calculate meaningful connection metrics for an event
  ///
  /// **Parameters:**
  /// - `event`: The event to calculate metrics for
  /// - `attendees`: List of users who attended the event
  ///
  /// **Returns:**
  /// `MeaningfulConnectionMetrics` with all calculated metrics
  Future<MeaningfulConnectionMetrics> calculateMetrics({
    required ExpertiseEvent event,
    required List<User> attendees,
  }) async {
    try {
      final tAtomic = await _atomicClock.getAtomicTimestamp();

      developer.log(
        'Calculating meaningful connection metrics for event ${event.id} with ${attendees.length} attendees',
        name: _logName,
      );

      // 1. Repeating interactions rate (30% weight)
      final repeatingInteractionsRate =
          await _calculateRepeatingInteractionsRate(
        event: event,
        attendees: attendees,
        tAtomic: tAtomic,
      );

      // 2. Event continuation rate (30% weight)
      final eventContinuationRate = await _calculateEventContinuationRate(
        event: event,
        attendees: attendees,
        tAtomic: tAtomic,
      );

      // 3. Vibe evolution score (25% weight) - Enhanced with knot evolution strings
      final vibeEvolutionScore = await _calculateVibeEvolutionScore(
        event: event,
        attendees: attendees,
        tAtomic: tAtomic,
      );

      // 4. Connection persistence rate (15% weight)
      final connectionPersistenceRate =
          await _calculateConnectionPersistenceRate(
        event: event,
        attendees: attendees,
        tAtomic: tAtomic,
      );

      // 5. Fabric evolution score (NEW) - Using worldsheets
      final fabricEvolutionScore = await _calculateFabricEvolutionScore(
        event: event,
        attendees: attendees,
        tAtomic: tAtomic,
      );

      // 6. Transformative impact score (calculated separately, not in weighted average)
      final transformativeImpactScore =
          await _calculateTransformativeImpactScore(
        event: event,
        attendees: attendees,
        tAtomic: tAtomic,
      );

      // Calculate overall meaningful connection score using hybrid approach
      // Core factors (must all be reasonable): vibe evolution, connection persistence
      // Modifiers (can enhance): repeating interactions, event continuation, fabric evolution

      // Core factors: geometric mean
      final coreFactors = [
        vibeEvolutionScore.clamp(0.0, 1.0),
        connectionPersistenceRate.clamp(0.0, 1.0),
      ];
      final coreScore = _geometricMean(coreFactors);

      // Modifiers: weighted average
      final modifiers = (0.35 * repeatingInteractionsRate +
              0.35 * eventContinuationRate +
              0.30 * fabricEvolutionScore)
          .clamp(0.0, 1.0);

      // Final: core * (base + modifier_boost)
      final meaningfulConnectionScore = coreScore * (0.7 + 0.3 * modifiers);

      developer.log(
        'Meaningful connection metrics calculated: score=${meaningfulConnectionScore.toStringAsFixed(3)}',
        name: _logName,
      );

      return MeaningfulConnectionMetrics(
        repeatingInteractionsRate: repeatingInteractionsRate,
        eventContinuationRate: eventContinuationRate,
        vibeEvolutionScore: vibeEvolutionScore,
        connectionPersistenceRate: connectionPersistenceRate,
        transformativeImpactScore: transformativeImpactScore,
        meaningfulConnectionScore: meaningfulConnectionScore,
        timestamp: tAtomic,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error calculating meaningful connection metrics: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      // Return default metrics on error
      final tAtomic = await _atomicClock.getAtomicTimestamp();
      return MeaningfulConnectionMetrics(
        repeatingInteractionsRate: 0.0,
        eventContinuationRate: 0.0,
        vibeEvolutionScore: 0.0,
        connectionPersistenceRate: 0.0,
        transformativeImpactScore: 0.0,
        meaningfulConnectionScore: 0.0,
        timestamp: tAtomic,
      );
    }
  }

  /// Calculate repeating interactions rate
  ///
  /// **Formula:**
  /// `repeating_interactions_rate = |users_with_post_event_interactions| / |total_attendees|`
  ///
  /// **Interaction Types:**
  /// - Messages between attendees
  /// - Follow-ups (users viewing profiles of other attendees)
  /// - Collaborations (users working together on projects)
  /// - Continued engagement (users interacting with event-related content)
  Future<double> _calculateRepeatingInteractionsRate({
    required ExpertiseEvent event,
    required List<User> attendees,
    required AtomicTimestamp tAtomic,
  }) async {
    if (attendees.isEmpty) {
      return 0.0;
    }

    try {
      // Get post-event interactions from database
      final eventEndTime = event.endTime;
      final interactionWindowEnd =
          eventEndTime.add(_postEventInteractionWindow);

      // Query interaction_events table for post-event interactions
      // Interaction types: message_sent, profile_viewed, collaboration_started, event_content_engaged
      int usersWithInteractions = 0;

      try {
        // Get agent IDs for all attendees
        final attendeeAgentIds = <String>{};
        for (final attendee in attendees) {
          final agentId = await _agentIdService.getUserAgentId(attendee.id);
          attendeeAgentIds.add(agentId);
        }

        // Query for interactions within the window
        // Filter by event types using OR conditions
        final response = await _supabaseService.client
            .from('interaction_events')
            .select('agent_id, event_type')
            .gte('timestamp', eventEndTime.toIso8601String())
            .lte('timestamp', interactionWindowEnd.toIso8601String())
            .or('event_type.eq.message_sent,event_type.eq.profile_viewed,event_type.eq.collaboration_started,event_type.eq.event_content_engaged');

        // Count unique users with interactions
        final usersWithInteractionsSet = <String>{};
        // Supabase returns a List directly, not a response object with .data
        final data = response as List<dynamic>? ?? [];
        for (final row in data) {
          final rowMap = row as Map<String, dynamic>;
          final agentId = rowMap['agent_id'] as String?;
          if (agentId != null && attendeeAgentIds.contains(agentId)) {
            usersWithInteractionsSet.add(agentId);
          }
        }
        usersWithInteractions = usersWithInteractionsSet.length;
      } catch (e) {
        developer.log(
          'Error querying post-event interactions: $e, using placeholder',
          name: _logName,
        );
        // Placeholder: assume 20% of attendees have interactions
        usersWithInteractions = (attendees.length * 0.2).round();
      }

      final rate = usersWithInteractions / attendees.length;
      return rate.clamp(0.0, 1.0);
    } catch (e) {
      developer.log(
        'Error calculating repeating interactions rate: $e',
        name: _logName,
      );
      return 0.0;
    }
  }

  /// Calculate event continuation rate
  ///
  /// **Formula:**
  /// `event_continuation_rate = |users_attending_similar_events| / |total_attendees|`
  ///
  /// **Event Similarity:**
  /// Events are similar if `F(ρ_event_1, ρ_event_2) ≥ 0.7`
  Future<double> _calculateEventContinuationRate({
    required ExpertiseEvent event,
    required List<User> attendees,
    required AtomicTimestamp tAtomic,
  }) async {
    if (attendees.isEmpty) {
      return 0.0;
    }

    try {
      // Get similar events within continuation window
      // TODO(Phase 19.7): Query similar events after eventEndTime within continuation window
      // final eventEndTime = event.endTime;
      // final continuationWindowEnd = eventEndTime.add(_eventContinuationWindow);

      // TODO: Query events table for similar events
      // For now, use placeholder: assume 15% of attendees attend similar events
      // In production, this would:
      // 1. Query events table for events after eventEndTime
      // 2. Calculate event similarity using QuantumEntanglementService
      // 3. Count attendees who registered for similar events

      int usersAttendingSimilarEvents = 0;

      try {
        // Get agent IDs for all attendees
        final attendeeAgentIds = <String>{};
        for (final attendee in attendees) {
          final agentId = await _agentIdService.getUserAgentId(attendee.id);
          attendeeAgentIds.add(agentId);
        }

        // Query for event registrations within the window
        // TODO: This would require an event_registrations table or similar
        // For now, use placeholder
        usersAttendingSimilarEvents = (attendees.length * 0.15).round();
      } catch (e) {
        developer.log(
          'Error querying event continuation: $e, using placeholder',
          name: _logName,
        );
        usersAttendingSimilarEvents = (attendees.length * 0.15).round();
      }

      final rate = usersAttendingSimilarEvents / attendees.length;
      return rate.clamp(0.0, 1.0);
    } catch (e) {
      developer.log(
        'Error calculating event continuation rate: $e',
        name: _logName,
      );
      return 0.0;
    }
  }

  /// Calculate vibe evolution score
  ///
  /// **Formula:**
  /// ```
  /// vibe_evolution_score = average(|⟨Δ|ψ_vibe_i(t_atomic_i)|ψ_event_type⟩|²) for all attendees
  ///
  /// Where:
  /// Δ|ψ_vibe⟩ = |ψ_user_post_event(t_atomic_post)⟩ - |ψ_user_pre_event(t_atomic_pre)⟩
  /// ```
  ///
  /// **Positive Evolution:**
  /// User's vibe moving toward event type = Meaningful impact
  /// Calculate vibe evolution score using knot evolution strings
  ///
  /// **Enhanced Process:**
  /// 1. Get pre-event knot (1 day before event)
  /// 2. Get post-event knot (30 days after event, or predicted if not available)
  /// 3. Calculate knot evolution: how much the knot changed
  /// 4. Higher evolution = more meaningful impact
  Future<double> _calculateVibeEvolutionScore({
    required ExpertiseEvent event,
    required List<User> attendees,
    required AtomicTimestamp tAtomic,
  }) async {
    if (attendees.isEmpty) {
      return 0.0;
    }

    try {
      // Pre-event time (1 day before)
      final preEventTime = event.startTime.subtract(const Duration(days: 1));
      // Post-event time (30 days after)
      final postEventTime = event.endTime.add(const Duration(days: 30));

      double totalEvolutionScore = 0.0;
      int validAttendees = 0;

      for (final attendee in attendees) {
        try {
          final agentId = await _agentIdService.getUserAgentId(attendee.id);

          // Get knot evolution string
          final string = await _stringService.createStringFromHistory(agentId);
          if (string == null) {
            continue;
          }

          // Get pre-event knot
          final preEventKnot = string.getKnotAtTime(preEventTime);
          if (preEventKnot == null) {
            continue;
          }

          // Get post-event knot (or predicted if not available)
          final postEventKnot = string.getKnotAtTime(postEventTime);
          PersonalityKnot? knotToUse;
          if (postEventKnot != null) {
            knotToUse = postEventKnot;
          } else {
            // Use predicted future knot if actual knot not available
            final predictedKnot = await _stringService.predictFutureKnot(
              agentId,
              postEventTime,
            );
            if (predictedKnot == null) {
              continue;
            }
            knotToUse = predictedKnot;
          }

          // Calculate knot evolution: how much the knot changed
          final evolution = _calculateKnotEvolution(
            preKnot: preEventKnot,
            postKnot: knotToUse,
          );

          totalEvolutionScore += evolution;
          validAttendees++;
        } catch (e) {
          developer.log(
            'Error calculating vibe evolution for user ${attendee.id}: $e',
            name: _logName,
          );
          continue;
        }
      }

      if (validAttendees == 0) {
        return 0.0;
      }

      final averageEvolutionScore = totalEvolutionScore / validAttendees;
      return averageEvolutionScore.clamp(0.0, 1.0);
    } catch (e, stackTrace) {
      developer.log(
        'Error calculating vibe evolution score: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      return 0.0;
    }
  }

  /// Calculate knot evolution between two knots
  ///
  /// **Formula:**
  /// evolution = f(crossing_diff, writhe_diff, complexity_change)
  ///
  /// Higher evolution = more meaningful impact
  double _calculateKnotEvolution({
    required PersonalityKnot preKnot,
    required PersonalityKnot postKnot,
  }) {
    try {
      // Calculate differences in knot invariants
      final crossingDiff = (postKnot.invariants.crossingNumber -
              preKnot.invariants.crossingNumber)
          .abs();
      final writheDiff =
          (postKnot.invariants.writhe - preKnot.invariants.writhe).abs();

      // Evolution score: normalized difference
      // Higher difference = more evolution = more meaningful impact
      final maxCrossings = math.max(
        preKnot.invariants.crossingNumber,
        postKnot.invariants.crossingNumber,
      );
      final crossingEvolution = maxCrossings > 0
          ? (crossingDiff / maxCrossings).clamp(0.0, 1.0)
          : 0.0;

      final writheEvolution = writheDiff.clamp(0.0, 1.0);

      // Combined: 60% crossing evolution + 40% writhe evolution
      return (0.6 * crossingEvolution + 0.4 * writheEvolution).clamp(0.0, 1.0);
    } catch (e) {
      developer.log(
        'Error calculating knot evolution: $e',
        name: _logName,
      );
      return 0.0;
    }
  }

  /// Calculate fabric evolution score using worldsheet
  ///
  /// **Process:**
  /// 1. Create worldsheet for event group
  /// 2. Get fabric at pre-event time
  /// 3. Get fabric at post-event time
  /// 4. Calculate fabric stability evolution
  /// 5. Positive change = fabric improved = meaningful connection
  Future<double> _calculateFabricEvolutionScore({
    required ExpertiseEvent event,
    required List<User> attendees,
    required AtomicTimestamp tAtomic,
  }) async {
    if (attendees.length < 2) {
      return 0.0; // Need at least 2 users for fabric
    }

    try {
      final attendeeIds = attendees.map((a) => a.id).toList();
      final agentIds = <String>[];
      for (final userId in attendeeIds) {
        final agentId = await _agentIdService.getUserAgentId(userId);
        agentIds.add(agentId);
      }

      // Create worldsheet for event group
      final worldsheet = await _worldsheetService.createWorldsheet(
        groupId: event.id,
        userIds: agentIds,
        startTime: event.startTime.subtract(const Duration(days: 30)),
        endTime: event.endTime.add(const Duration(days: 30)),
      );

      if (worldsheet == null) {
        return 0.0;
      }

      // Get fabric at pre-event time
      final preEventFabric = worldsheet.getFabricAtTime(
        event.startTime.subtract(const Duration(days: 1)),
      );
      if (preEventFabric == null) {
        return 0.0;
      }

      // Get fabric at post-event time
      final postEventFabric = worldsheet.getFabricAtTime(
        event.endTime.add(const Duration(days: 30)),
      );
      if (postEventFabric == null) {
        return 0.0;
      }

      // Calculate fabric stability evolution
      final preStability = await _fabricService.measureFabricStability(
        preEventFabric,
      );
      final postStability = await _fabricService.measureFabricStability(
        postEventFabric,
      );

      // Evolution score: how much fabric stability changed
      // Positive change = fabric improved = meaningful connection
      final stabilityChange = postStability - preStability;
      return stabilityChange.clamp(0.0, 1.0);
    } catch (e, stackTrace) {
      developer.log(
        'Error calculating fabric evolution score: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      return 0.0;
    }
  }

  /// Calculate connection persistence rate
  ///
  /// **Formula:**
  /// `connection_persistence_rate = |persistent_connections| / |total_connections_formed|`
  ///
  /// **Persistent Connection:**
  /// Connection that remains active for at least 30 days after event
  Future<double> _calculateConnectionPersistenceRate({
    required ExpertiseEvent event,
    required List<User> attendees,
    required AtomicTimestamp tAtomic,
  }) async {
    if (attendees.isEmpty) {
      return 0.0;
    }

    try {
      // TODO: Query connections table for connections formed at event
      // For now, use placeholder: assume 10% of possible connections are persistent
      // In production, this would:
      // 1. Query connections table for connections formed around event time
      // 2. Check which connections are still active after persistence window
      // 3. Calculate persistence rate

      // Estimate total possible connections (n choose 2)
      final totalPossibleConnections =
          (attendees.length * (attendees.length - 1)) ~/ 2;
      if (totalPossibleConnections == 0) {
        return 0.0;
      }

      // Placeholder: assume 10% of possible connections are persistent
      final persistentConnections = (totalPossibleConnections * 0.10).round();

      final rate = persistentConnections / totalPossibleConnections;
      return rate.clamp(0.0, 1.0);
    } catch (e) {
      developer.log(
        'Error calculating connection persistence rate: $e',
        name: _logName,
      );
      return 0.0;
    }
  }

  /// Calculate transformative impact score
  ///
  /// **Transformative Impact Indicators:**
  /// - User exploring new categories
  /// - User attending different event types
  /// - User's personality dimensions evolving
  /// - User engagement level changing
  Future<double> _calculateTransformativeImpactScore({
    required ExpertiseEvent event,
    required List<User> attendees,
    required AtomicTimestamp tAtomic,
  }) async {
    if (attendees.isEmpty) {
      return 0.0;
    }

    try {
      // Calculate transformative impact for each attendee
      double totalImpactScore = 0.0;
      int validAttendees = 0;

      for (final attendee in attendees) {
        try {
          // Get pre-event behavior patterns
          final preEventBehavior = await _getUserBehaviorPattern(
            userId: attendee.id,
            timestamp: event.startTime,
            eventCategory: event.category,
          );

          // Get post-event behavior patterns
          final postEventBehavior = await _getUserBehaviorPattern(
            userId: attendee.id,
            timestamp: event.endTime
                .add(const Duration(days: 30)), // 30 days after event
            eventCategory: event.category,
          );

          if (preEventBehavior != null && postEventBehavior != null) {
            // Calculate transformative impact
            final impactScore = _calculateBehaviorTransformativeImpact(
              preBehavior: preEventBehavior,
              postBehavior: postEventBehavior,
            );

            totalImpactScore += impactScore;
            validAttendees++;
          }
        } catch (e) {
          developer.log(
            'Error calculating transformative impact for user ${attendee.id}: $e',
            name: _logName,
          );
          // Continue with next attendee
        }
      }

      if (validAttendees == 0) {
        return 0.0;
      }

      final averageImpactScore = totalImpactScore / validAttendees;
      return averageImpactScore.clamp(0.0, 1.0);
    } catch (e) {
      developer.log(
        'Error calculating transformative impact score: $e',
        name: _logName,
      );
      return 0.0;
    }
  }

  // Helper methods

  /// Get event type vibe (from event category/characteristics)
  // ignore: unused_element
  Map<String, double> _getEventTypeVibe(ExpertiseEvent event) {
    // Create a vibe representation based on event category
    // This is a simplified version - in production, would use actual event quantum state
    final eventCategory = event.category.toLowerCase();
    final vibe = <String, double>{};

    // Map event categories to vibe dimensions
    // This is a placeholder - in production, would use actual quantum vibe calculation
    if (eventCategory.contains('coffee')) {
      vibe['social'] = 0.7;
      vibe['exploration'] = 0.6;
      vibe['creativity'] = 0.5;
    } else if (eventCategory.contains('book')) {
      vibe['intellectual'] = 0.8;
      vibe['reflection'] = 0.7;
      vibe['social'] = 0.5;
    } else {
      // Default vibe
      vibe['social'] = 0.6;
      vibe['exploration'] = 0.5;
    }

    return vibe;
  }

  /// Get user vibe at a specific time
  // ignore: unused_element
  Future<Map<String, double>?> _getUserVibeAtTime({
    required String userId,
    required DateTime timestamp,
  }) async {
    try {
      // Get personality profile at that time
      // For now, use current personality profile as approximation
      // In production, would query historical personality profiles
      final personalityProfile =
          await _personalityLearning.getCurrentPersonality(userId);
      if (personalityProfile == null) {
        return null;
      }

      // Compile user vibe from personality profile
      final userVibe =
          await _vibeAnalyzer.compileUserVibe(userId, personalityProfile);
      return userVibe.anonymizedDimensions;
    } catch (e) {
      developer.log(
        'Error getting user vibe at time: $e',
        name: _logName,
      );
      return null;
    }
  }

  /// Calculate vibe difference: Δ|ψ_vibe⟩ = |ψ_post⟩ - |ψ_pre⟩
  // ignore: unused_element
  Map<String, double> _calculateVibeDifference({
    required Map<String, double> preVibe,
    required Map<String, double> postVibe,
  }) {
    final evolution = <String, double>{};
    final allDimensions = {...preVibe.keys, ...postVibe.keys};

    for (final dimension in allDimensions) {
      final preValue = preVibe[dimension] ?? 0.0;
      final postValue = postVibe[dimension] ?? 0.0;
      evolution[dimension] = postValue - preValue;
    }

    return evolution;
  }

  /// Calculate vibe evolution score: |⟨Δ|ψ_vibe⟩|ψ_event_type⟩|²
  // ignore: unused_element
  double _calculateVibeEvolutionInnerProduct({
    required Map<String, double> vibeEvolution,
    required Map<String, double> eventTypeVibe,
  }) {
    if (vibeEvolution.isEmpty || eventTypeVibe.isEmpty) {
      return 0.0;
    }

    // Calculate inner product: ⟨Δ|ψ_vibe⟩|ψ_event_type⟩
    double innerProduct = 0.0;
    double normEvolution = 0.0;
    double normEventType = 0.0;

    final allDimensions = {...vibeEvolution.keys, ...eventTypeVibe.keys};
    for (final dimension in allDimensions) {
      final evolutionValue = vibeEvolution[dimension] ?? 0.0;
      final eventTypeValue = eventTypeVibe[dimension] ?? 0.0;
      innerProduct += evolutionValue * eventTypeValue;
      normEvolution += evolutionValue * evolutionValue;
      normEventType += eventTypeValue * eventTypeValue;
    }

    if (normEvolution == 0.0 || normEventType == 0.0) {
      return 0.0;
    }

    // Normalize inner product
    final normalizedInnerProduct =
        innerProduct / (math.sqrt(normEvolution) * math.sqrt(normEventType));

    // Evolution score: |⟨Δ|ψ_vibe⟩|ψ_event_type⟩|²
    final evolutionScore = normalizedInnerProduct * normalizedInnerProduct;

    // Positive evolution (moving toward event type) = higher score
    return evolutionScore.clamp(0.0, 1.0);
  }

  /// Calculate geometric mean of values
  ///
  /// **Formula:** (x₁ * x₂ * ... * xₙ)^(1/n)
  ///
  /// **Properties:**
  /// - If any value is 0, result is 0 (critical failure)
  /// - More sensitive to low values than arithmetic mean
  /// - Appropriate for multiplicative relationships
  double _geometricMean(List<double> values) {
    if (values.isEmpty) return 0.0;

    // Filter out zeros (if any core factor is 0, score is 0)
    final nonZeroValues = values.where((v) => v > 0.0).toList();
    if (nonZeroValues.length < values.length) {
      return 0.0; // At least one core factor is 0
    }

    // Calculate product
    double product = 1.0;
    for (final value in nonZeroValues) {
      product *= value.clamp(0.0, 1.0);
    }

    // Calculate geometric mean: (product)^(1/n)
    final n = nonZeroValues.length.toDouble();
    return math.pow(product, 1.0 / n).toDouble();
  }

  /// Get user behavior pattern at a specific time
  Future<Map<String, dynamic>?> _getUserBehaviorPattern({
    required String userId,
    required DateTime timestamp,
    String? eventCategory,
  }) async {
    try {
      // TODO: Query usage patterns or behavior tracking
      // For now, return placeholder
      return {
        'event_categories': eventCategory != null ? [eventCategory] : [],
        'engagement_level': 0.5,
        'exploration_tendency': 0.5,
      };
    } catch (e) {
      developer.log(
        'Error getting user behavior pattern: $e',
        name: _logName,
      );
      return null;
    }
  }

  /// Calculate behavior transformative impact
  double _calculateBehaviorTransformativeImpact({
    required Map<String, dynamic> preBehavior,
    required Map<String, dynamic> postBehavior,
  }) {
    // Calculate impact based on behavior changes
    double impactScore = 0.0;

    // 1. Category exploration (user exploring new categories)
    final preCategories =
        (preBehavior['event_categories'] as List<dynamic>?) ?? [];
    final postCategories =
        (postBehavior['event_categories'] as List<dynamic>?) ?? [];
    final newCategories =
        postCategories.where((cat) => !preCategories.contains(cat)).length;
    if (newCategories > 0) {
      impactScore += 0.3 *
          (newCategories / math.max(postCategories.length, 1)).clamp(0.0, 1.0);
    }

    // 2. Engagement level change
    final preEngagement =
        (preBehavior['engagement_level'] as num?)?.toDouble() ?? 0.5;
    final postEngagement =
        (postBehavior['engagement_level'] as num?)?.toDouble() ?? 0.5;
    final engagementChange = (postEngagement - preEngagement).abs();
    impactScore += 0.2 * engagementChange;

    // 3. Exploration tendency change
    final preExploration =
        (preBehavior['exploration_tendency'] as num?)?.toDouble() ?? 0.5;
    final postExploration =
        (postBehavior['exploration_tendency'] as num?)?.toDouble() ?? 0.5;
    final explorationChange = (postExploration - preExploration).abs();
    impactScore += 0.2 * explorationChange;

    return impactScore.clamp(0.0, 1.0);
  }
}
