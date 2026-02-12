// Real-Time User Calling Service
//
// Implements dynamic real-time user calling based on evolving entangled states
// Part of Phase 19: Multi-Entity Quantum Entanglement Matching System
// Section 19.4: Dynamic Real-Time User Calling System
// Patent #29: Multi-Entity Quantum Entanglement Matching System
//
// NOTE: Some methods are marked as unused but are placeholders for future
// user service integration. They will be used when user service integration is complete.

import 'dart:developer' as developer;
import 'dart:async';
import 'package:avrai_core/models/quantum_entity_state.dart';
import 'package:avrai_core/models/quantum_entity_type.dart';
import 'package:avrai_core/models/atomic_timestamp.dart';
import 'package:avrai_core/models/user.dart';
import 'package:avrai_core/enums/user_enums.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_quantum/services/quantum/quantum_entanglement_service.dart';
import 'package:avrai_quantum/services/quantum/location_timing_quantum_state_service.dart';
import 'package:avrai_knot/services/knot/cross_entity_compatibility_service.dart';
import 'package:avrai/core/ai/personality_learning.dart';
import 'package:avrai/core/ai/vibe_analysis_engine.dart';
import 'package:avrai/core/services/infrastructure/supabase_service.dart';
import 'package:avrai/core/services/matching/preferences_profile_service.dart';
import 'package:avrai/core/services/user/agent_id_service.dart';
import 'package:avrai_knot/services/knot/entity_knot_service.dart';
import 'package:avrai_knot/services/knot/personality_knot_service.dart';
import 'package:avrai_knot/services/knot/knot_evolution_string_service.dart';
import 'package:avrai_knot/services/knot/knot_worldsheet_service.dart';
import 'package:avrai_knot/services/knot/knot_fabric_service.dart';
import 'package:avrai_knot/services/knot/knot_storage_service.dart';
import 'package:avrai_core/models/personality_knot.dart';
import 'package:avrai/core/services/quantum/meaningful_experience_calculator.dart';
import 'package:avrai/core/services/quantum/user_journey_tracking_service.dart';
import 'package:avrai_core/models/unified_location_data.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:avrai/core/ai2ai/anonymous_communication.dart';
import 'package:avrai/core/services/security/hybrid_encryption_service.dart';
import 'dart:math' as math;

/// Real-time user calling service
///
/// **User Calling Formula with Knot Integration and Timing Flexibility:**
/// ```
/// user_entangled_compatibility = 0.5 * F(ρ_user, ρ_entangled) +
///                               0.3 * F(ρ_user_location, ρ_event_location) +
///                               0.2 * timing_flexibility_factor * F(ρ_user_timing, ρ_event_timing) +
///                               0.15 * C_knot_bonus
/// 
/// Where:
/// timing_flexibility_factor = {
///   1.0 if timing_match ≥ 0.7 OR meaningful_experience_score ≥ 0.8,
///   0.5 if meaningful_experience_score ≥ 0.9 (highly meaningful experiences override timing),
///   weighted_combination(EntityTimingQuantumState, QuantumTemporalState) otherwise
/// }
/// ```
///
/// **Dynamic Calling Process:**
/// - Immediate calling upon event creation
/// - Real-time re-evaluation on entity addition
/// - Stop calling if compatibility drops below threshold
class RealTimeUserCallingService {
  static const String _logName = 'RealTimeUserCallingService';

  final AtomicClockService _atomicClock;
  final QuantumEntanglementService _entanglementService;
  final LocationTimingQuantumStateService _locationTimingService;
  final CrossEntityCompatibilityService? _knotCompatibilityService;
  final PersonalityLearning _personalityLearning;
  final UserVibeAnalyzer _vibeAnalyzer;
  final SupabaseService _supabaseService;
  final PreferencesProfileService _preferencesProfileService;
  final AgentIdService _agentIdService;
  final PersonalityKnotService _personalityKnotService;
  final MeaningfulExperienceCalculator _meaningfulExperienceCalculator;
  final UserJourneyTrackingService _journeyTrackingService;
  final KnotEvolutionStringService _stringService;
  final KnotWorldsheetService _worldsheetService;
  final KnotFabricService _fabricService;
  final KnotStorageService _knotStorage;
  final AnonymousCommunicationProtocol? _ai2aiProtocol;
  final HybridEncryptionService? _encryptionService;

  // Performance optimization: Cache for quantum states and compatibility
  final Map<String, CachedQuantumState> _quantumStateCache = {};
  final Map<String, CachedCompatibility> _compatibilityCache = {};
  static const int _maxCacheSize = 1000;

  // Batching configuration
  static const int _batchSize = 100; // Process users in batches of 100

  // Calling threshold
  static const double _callingThreshold = 0.7; // 70% compatibility threshold

  // Event call tracking (in-memory for now, can be replaced with database)
  // Maps: eventId -> Set of userIds who have been called
  final Map<String, Set<String>> _eventCalls = {};
  // Maps: eventId -> userId -> compatibility score
  final Map<String, Map<String, double>> _eventCallScores = {};

  RealTimeUserCallingService({
    required AtomicClockService atomicClock,
    required QuantumEntanglementService entanglementService,
    required LocationTimingQuantumStateService locationTimingService,
    required PersonalityLearning personalityLearning,
    required UserVibeAnalyzer vibeAnalyzer,
    required AgentIdService agentIdService,
    CrossEntityCompatibilityService? knotCompatibilityService,
    required SupabaseService supabaseService,
    required PreferencesProfileService preferencesProfileService,
    EntityKnotService? entityKnotService,
    required PersonalityKnotService personalityKnotService,
    required MeaningfulExperienceCalculator meaningfulExperienceCalculator,
    required UserJourneyTrackingService journeyTrackingService,
    required KnotEvolutionStringService stringService,
    required KnotWorldsheetService worldsheetService,
    required KnotFabricService fabricService,
    required KnotStorageService knotStorage,
    AnonymousCommunicationProtocol? ai2aiProtocol,
    HybridEncryptionService? encryptionService,
  })  : _atomicClock = atomicClock,
        _entanglementService = entanglementService,
        _locationTimingService = locationTimingService,
        _personalityLearning = personalityLearning,
        _vibeAnalyzer = vibeAnalyzer,
        _agentIdService = agentIdService,
        _knotCompatibilityService = knotCompatibilityService,
        _supabaseService = supabaseService,
        _preferencesProfileService = preferencesProfileService,
        _personalityKnotService = personalityKnotService,
        _meaningfulExperienceCalculator = meaningfulExperienceCalculator,
        _journeyTrackingService = journeyTrackingService,
        _stringService = stringService,
        _worldsheetService = worldsheetService,
        _fabricService = fabricService,
        _knotStorage = knotStorage,
        _ai2aiProtocol = ai2aiProtocol,
        _encryptionService = encryptionService;

  /// Call users to event immediately upon event creation
  ///
  /// **Called when:**
  /// - Event is created (initial entanglement: |ψ_event⟩ ⊗ |ψ_creator⟩)
  ///
  /// **Process:**
  /// 1. Get atomic timestamp
  /// 2. Create entangled state from event entities
  /// 3. Evaluate all users
  /// 4. Call users with compatibility >= threshold
  Future<void> callUsersOnEventCreation({
    required String eventId,
    required List<QuantumEntityState> eventEntities,
  }) async {
    developer.log(
      'Calling users on event creation: eventId=$eventId, entities=${eventEntities.length}',
      name: _logName,
    );

    try {
      final tAtomic = await _atomicClock.getAtomicTimestamp();

      // Create entangled state from event entities
      final entangledState = await _entanglementService.createEntangledState(
        entityStates: eventEntities,
      );

      // Evaluate and call users
      await _evaluateAndCallUsers(
        eventId: eventId,
        entangledState: entangledState,
        eventEntities: eventEntities,
        tAtomic: tAtomic,
      );

      developer.log(
        '✅ Completed user calling on event creation: eventId=$eventId',
        name: _logName,
      );
    } catch (e, stackTrace) {
      developer.log(
        '❌ Error calling users on event creation: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }

  /// Re-evaluate users when entity is added to event
  ///
  /// **Called when:**
  /// - Business added to event
  /// - Brand added to event
  /// - Expert added to event
  /// - Any entity addition
  ///
  /// **Process:**
  /// 1. Get atomic timestamp
  /// 2. Recreate entangled state with new entity
  /// 3. Re-evaluate all users (incremental optimization: only affected users)
  /// 4. Call new users if compatibility >= threshold
  /// 5. Stop calling users if compatibility drops below threshold
  Future<void> reEvaluateUsersOnEntityAddition({
    required String eventId,
    required List<QuantumEntityState> eventEntities,
    required QuantumEntityState newEntity,
  }) async {
    developer.log(
      'Re-evaluating users on entity addition: eventId=$eventId, newEntity=${newEntity.entityId}',
      name: _logName,
    );

    try {
      final tAtomic = await _atomicClock.getAtomicTimestamp();

      // Create updated entangled state with new entity
      final updatedEntities = [...eventEntities, newEntity];
      final updatedEntangledState = await _entanglementService.createEntangledState(
        entityStates: updatedEntities,
      );

      // Re-evaluate and update user calls
      await _evaluateAndCallUsers(
        eventId: eventId,
        entangledState: updatedEntangledState,
        eventEntities: updatedEntities,
        tAtomic: tAtomic,
      );

      developer.log(
        '✅ Completed user re-evaluation on entity addition: eventId=$eventId',
        name: _logName,
      );
    } catch (e, stackTrace) {
      developer.log(
        '❌ Error re-evaluating users on entity addition: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }

  /// Evaluate users and call/update/stop calling based on compatibility
  ///
  /// **Formula:**
  /// ```
  /// user_entangled_compatibility = 0.5 * F(ρ_user, ρ_entangled) +
  ///                               0.3 * F(ρ_user_location, ρ_event_location) +
  ///                               0.2 * F(ρ_user_timing, ρ_event_timing) +
  ///                               0.15 * C_knot_bonus
  /// ```
  Future<void> _evaluateAndCallUsers({
    required String eventId,
    required EntangledQuantumState entangledState,
    required List<QuantumEntityState> eventEntities,
    required AtomicTimestamp tAtomic,
  }) async {
    try {
      // Get all users (with pagination for scalability)
      final users = await _getAllUsers();

      if (users.isEmpty) {
        developer.log(
          'No users found for event calling: eventId=$eventId',
          name: _logName,
        );
        return;
      }

      developer.log(
        'Evaluating ${users.length} users for event: eventId=$eventId',
        name: _logName,
      );

      // Process users in batches for scalability
      for (int i = 0; i < users.length; i += _batchSize) {
        final batch = users.skip(i).take(_batchSize).toList();
        await _processUserBatch(
          eventId: eventId,
          batch: batch,
          entangledState: entangledState,
          eventEntities: eventEntities,
          tAtomic: tAtomic,
        );
      }

      developer.log(
        '✅ User evaluation complete: eventId=$eventId, users=${users.length}',
        name: _logName,
      );
    } catch (e, stackTrace) {
      developer.log(
        '❌ Error evaluating users: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }

  /// Process a batch of users in parallel
  Future<void> _processUserBatch({
    required String eventId,
    required List<User> batch,
    required EntangledQuantumState entangledState,
    required List<QuantumEntityState> eventEntities,
    required AtomicTimestamp tAtomic,
  }) async {
    // Process batch in parallel
    final futures = batch.map((user) async {
      try {
        // Get or create user quantum state (with caching)
        final userState = await _getUserQuantumState(user);

        // Calculate compatibility
        final compatibility = await _calculateUserCompatibility(
          userState: userState,
          entangledState: entangledState,
          eventEntities: eventEntities,
        );

        // Check if user was previously called
        final wasPreviouslyCalled = await _wasUserCalledToEvent(user.id, eventId);

        // Decide on calling action
        if (compatibility >= _callingThreshold) {
          if (!wasPreviouslyCalled) {
            // New user - call them
            await _callUserToEvent(user.id, eventId, compatibility, tAtomic);
          } else {
            // Update existing call
            await _updateUserCall(user.id, eventId, compatibility, tAtomic);
          }
        } else {
          if (wasPreviouslyCalled) {
            // Stop calling this user
            await _stopCallingUserToEvent(user.id, eventId, tAtomic);
          }
        }
      } catch (e) {
        developer.log(
          'Error processing user ${user.id}: $e',
          name: _logName,
        );
        // Continue processing other users
      }
    });

    await Future.wait(futures);
  }

  /// Calculate user compatibility with entangled state
  ///
  /// **Hybrid Formula (Geometric Mean for Core + Weighted Average for Modifiers):**
  /// ```
  /// core_compatibility = (quantum * knot * string_evolution)^(1/3)  // Geometric mean
  /// modifiers = 0.4 * location + 0.35 * timing + 0.25 * worldsheet  // Weighted average
  /// final_compatibility = core_compatibility * (0.7 + 0.3 * modifiers)
  /// ```
  ///
  /// **Why Hybrid:**
  /// - Core factors (quantum, knot, string) must ALL be reasonable (multiplicative)
  /// - Modifiers (location, timing, worldsheet) can enhance but not break (additive)
  /// - Mathematically aligned with quantum operations (multiplicative for entanglement)
  Future<double> _calculateUserCompatibility({
    required QuantumEntityState userState,
    required EntangledQuantumState entangledState,
    required List<QuantumEntityState> eventEntities,
  }) async {
    // Get event start time from event entities
    final eventStartTime = _extractEventStartTime(eventEntities);

    // ===== CORE FACTORS (Geometric Mean) =====
    // These must ALL be reasonable - if any is 0, overall compatibility is 0

    // 1. Quantum entanglement compatibility
    final quantumFidelity = await _entanglementService.calculateFidelity(
      await _entanglementService.createEntangledState(
        entityStates: [userState],
      ),
      entangledState,
    );
    final quantumCompatibility = quantumFidelity.clamp(0.0, 1.0);

    // 2. Knot compatibility bonus
    double knotCompatibility = 0.5; // Default: neutral if not available
    if (_knotCompatibilityService != null) {
      try {
        final knotBonus = await _calculateKnotCompatibilityBonus(
          userState: userState,
          eventEntities: eventEntities,
        );
        knotCompatibility = knotBonus.clamp(0.0, 1.0);
      } catch (e) {
        developer.log(
          'Error calculating knot compatibility: $e, using neutral 0.5',
          name: _logName,
        );
      }
    }

    // 3. String evolution compatibility
    double stringEvolutionCompatibility = 0.5; // Default: neutral if not available
    if (eventStartTime != null) {
      try {
        final agentId = await _agentIdService.getUserAgentId(userState.entityId);
        final futureKnot = await _stringService.predictFutureKnot(
          agentId,
          eventStartTime,
        );

        if (futureKnot != null) {
          final currentKnot = await _knotStorage.loadKnot(agentId);
          if (currentKnot != null) {
            final evolutionScore = _calculateKnotEvolutionScore(
              currentKnot: currentKnot,
              futureKnot: futureKnot,
            );
            stringEvolutionCompatibility = evolutionScore.clamp(0.0, 1.0);
          }
        }
      } catch (e) {
        developer.log(
          'Error calculating string evolution compatibility: $e, using neutral 0.5',
          name: _logName,
        );
      }
    }

    // Calculate core compatibility using geometric mean
    // If any core factor is 0, overall is 0 (critical failure)
    final coreCompatibility = _geometricMean([
      quantumCompatibility,
      knotCompatibility,
      stringEvolutionCompatibility,
    ]);

    // ===== MODIFIERS (Weighted Average) =====
    // These can enhance but not break - additive contribution

    // 1. Location compatibility
    double locationCompatibility = 0.5; // Default: neutral
    if (userState.location != null) {
      final eventLocation = _findEventLocation(eventEntities);
      if (eventLocation != null) {
        locationCompatibility = LocationCompatibilityCalculator.calculateLocationCompatibility(
          userState.location!,
          eventLocation,
        ).clamp(0.0, 1.0);
      }
    }

    // 2. Timing compatibility with flexibility factor
    double timingCompatibility = 0.5; // Default: neutral
    if (userState.timing != null) {
      final eventTiming = _findEventTiming(eventEntities);
      if (eventTiming != null) {
        final baseTiming = TimingCompatibilityCalculator.calculateTimingCompatibility(
          userState.timing!,
          eventTiming,
        ).clamp(0.0, 1.0);

        double timingFlexibilityFactor = 1.0;
        try {
          final meaningfulScore =
              await _meaningfulExperienceCalculator.calculateMeaningfulExperienceScore(
            userState: userState,
            entangledState: entangledState,
            eventEntities: eventEntities,
          );
          timingFlexibilityFactor =
              await _meaningfulExperienceCalculator.calculateTimingFlexibilityFactor(
            userState: userState,
            eventEntities: eventEntities,
            meaningfulExperienceScore: meaningfulScore,
          );
        } catch (e) {
          developer.log(
            'Error calculating timing flexibility factor: $e, using default 1.0',
            name: _logName,
          );
        }
        timingCompatibility = (baseTiming * timingFlexibilityFactor).clamp(0.0, 1.0);
        }
      }

    // 3. Group evolution compatibility (worldsheet)
    double worldsheetCompatibility = 0.5; // Default: neutral
    if (eventStartTime != null) {
      try {
        final eventId = _extractEventId(eventEntities);
        if (eventId != null) {
          final groupEvolution = await _calculateGroupEvolutionCompatibility(
            eventId: eventId,
            userId: userState.entityId,
            eventTime: eventStartTime,
          eventEntities: eventEntities,
        );
          worldsheetCompatibility = groupEvolution.clamp(0.0, 1.0);
        }
      } catch (e) {
        developer.log(
          'Error calculating group evolution compatibility: $e, using neutral 0.5',
          name: _logName,
        );
      }
    }

    // Calculate modifiers using weighted average
    // Weights: 40% location, 35% timing, 25% worldsheet
    final modifiers = (0.40 * locationCompatibility +
            0.35 * timingCompatibility +
            0.25 * worldsheetCompatibility)
        .clamp(0.0, 1.0);

    // ===== FINAL COMBINATION =====
    // core * (base + modifier_boost)
    // Base of 0.7 means core compatibility is 70% of final score
    // Modifiers can boost up to 30% (0.7 + 0.3 = 1.0)
    final finalCompatibility = coreCompatibility * (0.7 + 0.3 * modifiers);

    return finalCompatibility.clamp(0.0, 1.0);
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
    
    // Filter out zeros (if any core factor is 0, compatibility is 0)
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

  /// Calculate compatibility based on group evolution (worldsheet)
  ///
  /// **Process:**
  /// 1. Create worldsheet for event group
  /// 2. Get fabric at event time
  /// 3. Calculate how well user's knot fits in fabric
  /// 4. Return compatibility score
  Future<double> _calculateGroupEvolutionCompatibility({
    required String eventId,
    required String userId,
    required DateTime eventTime,
    required List<QuantumEntityState> eventEntities,
  }) async {
    try {
      // Get attendee IDs from event entities
      final attendeeIds = <String>[];
      for (final entity in eventEntities) {
        if (entity.entityType == QuantumEntityType.user) {
          attendeeIds.add(entity.entityId);
        }
      }

      // Add current user if not already in list
      if (!attendeeIds.contains(userId)) {
        attendeeIds.add(userId);
      }

      if (attendeeIds.length < 2) {
        return 0.5; // Need at least 2 users for fabric
      }

      // Convert user IDs to agent IDs
      final agentIds = <String>[];
      for (final userId in attendeeIds) {
        final agentId = await _agentIdService.getUserAgentId(userId);
        agentIds.add(agentId);
      }

      // Create worldsheet for event group
      final worldsheet = await _worldsheetService.createWorldsheet(
        groupId: eventId,
        userIds: agentIds,
        startTime: eventTime.subtract(const Duration(days: 30)),
        endTime: eventTime.add(const Duration(days: 30)),
      );

      if (worldsheet == null) {
        return 0.5; // Neutral if no worldsheet available
      }

      // Get fabric at event time
      final fabricAtEventTime = worldsheet.getFabricAtTime(eventTime);
      if (fabricAtEventTime == null) {
        return 0.5;
      }

      // Get user's predicted future knot at event time
      final userAgentId = await _agentIdService.getUserAgentId(userId);
      final userFutureKnot = await _stringService.predictFutureKnot(
        userAgentId,
        eventTime,
      );

      if (userFutureKnot == null) {
        return 0.5;
      }

      // Calculate fabric stability with user's future knot
      final fabricStability = await _fabricService.measureFabricStability(
        fabricAtEventTime,
      );

      // Calculate knot compatibility with fabric
      // Get all knots from fabric
      final fabricKnots = fabricAtEventTime.userKnots;
      if (fabricKnots.isEmpty) {
        return 0.5;
      }

      // Calculate average compatibility with fabric knots
      var totalCompatibility = 0.0;
      var count = 0;
      for (final fabricKnot in fabricKnots) {
        final compatibility = _calculateTopologicalCompatibility(
          knotA: userFutureKnot,
          knotB: fabricKnot,
        );
        totalCompatibility += compatibility;
        count++;
      }

      final knotCompatibility = count > 0 ? totalCompatibility / count : 0.5;

      // Combined: 60% fabric stability + 40% knot compatibility
      return (0.6 * fabricStability + 0.4 * knotCompatibility).clamp(0.0, 1.0);
    } catch (e, stackTrace) {
      developer.log(
        'Error calculating group evolution compatibility: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      return 0.5; // Neutral on error
    }
  }

  /// Calculate topological compatibility between two knots
  double _calculateTopologicalCompatibility({
    required PersonalityKnot knotA,
    required PersonalityKnot knotB,
  }) {
    try {
      // Use knot invariants for compatibility
      final crossingDiff = (knotA.invariants.crossingNumber - 
                           knotB.invariants.crossingNumber).abs();
      final writheDiff = (knotA.invariants.writhe - 
                         knotB.invariants.writhe).abs();

      final maxCrossings = math.max(
        knotA.invariants.crossingNumber,
        knotB.invariants.crossingNumber,
      );
      final crossingSimilarity = maxCrossings > 0
          ? 1.0 - (crossingDiff / maxCrossings).clamp(0.0, 1.0)
          : 0.5;

      final writheSimilarity = writheDiff < 0.1 
          ? 1.0 
          : (1.0 - writheDiff.clamp(0.0, 1.0));

      // Combined: 60% crossing similarity + 40% writhe similarity
      return (0.6 * crossingSimilarity + 0.4 * writheSimilarity).clamp(0.0, 1.0);
    } catch (e) {
      developer.log(
        'Error calculating topological compatibility: $e',
        name: _logName,
      );
      return 0.5;
    }
  }

  /// Extract event ID from event entities
  String? _extractEventId(List<QuantumEntityState> eventEntities) {
    for (final entity in eventEntities) {
      if (entity.entityType == QuantumEntityType.event) {
        return entity.entityId;
      }
    }
    return null;
  }

  /// Extract event start time from event entities
  DateTime? _extractEventStartTime(List<QuantumEntityState> eventEntities) {
    for (final entity in eventEntities) {
      if (entity.entityType == QuantumEntityType.event) {
        // Try to extract start time from entity characteristics
        final characteristics = entity.entityCharacteristics;
        if (characteristics.containsKey('startTime')) {
          final startTime = characteristics['startTime'];
          if (startTime is DateTime) {
            return startTime;
          } else if (startTime is String) {
            try {
              return DateTime.parse(startTime);
            } catch (e) {
              // Continue to next entity
            }
          }
        }
        // Fallback: use timing quantum state if available
        if (entity.timing != null) {
          // Extract from timing state (simplified - would need actual implementation)
          // For now, return null and let caller handle
        }
      }
    }
    return null;
  }

  /// Calculate knot evolution score between current and future knot
  ///
  /// **Formula:**
  /// evolution_score = f(crossing_diff, writhe_diff, complexity_change)
  ///
  /// Higher evolution = more meaningful match (user is growing/changing)
  double _calculateKnotEvolutionScore({
    required PersonalityKnot currentKnot,
    required PersonalityKnot futureKnot,
  }) {
    try {
      // Calculate differences in knot invariants
      final crossingDiff = (futureKnot.invariants.crossingNumber - 
                           currentKnot.invariants.crossingNumber).abs();
      final writheDiff = (futureKnot.invariants.writhe - 
                         currentKnot.invariants.writhe).abs();

      // Evolution score: normalized difference
      // Higher difference = more evolution = more meaningful
      final maxCrossings = math.max(
        currentKnot.invariants.crossingNumber,
        futureKnot.invariants.crossingNumber,
      );
      final crossingEvolution = maxCrossings > 0 
          ? (crossingDiff / maxCrossings).clamp(0.0, 1.0)
          : 0.0;

      final writheEvolution = writheDiff.clamp(0.0, 1.0);

      // Combined: 60% crossing evolution + 40% writhe evolution
      return (0.6 * crossingEvolution + 0.4 * writheEvolution).clamp(0.0, 1.0);
    } catch (e) {
      developer.log(
        'Error calculating knot evolution score: $e',
        name: _logName,
      );
      return 0.0;
    }
  }

  /// Get user quantum state (with caching)
  Future<QuantumEntityState> _getUserQuantumState(User user) async {
    // Check cache
    final cacheKey = 'user_${user.id}';
    final cached = _quantumStateCache[cacheKey];
    if (cached != null && !cached.isExpired) {
      return cached.state;
    }

    try {
      final tAtomic = await _atomicClock.getAtomicTimestamp();

      // Get personality profile
      final personalityProfile = await _personalityLearning.getCurrentPersonality(user.id);
      final personalityDimensions = personalityProfile?.dimensions ?? {};

      // Get quantum vibe analysis
      final quantumVibeAnalysis = <String, double>{};
      if (personalityProfile != null) {
        // Use UserVibeAnalyzer to compile user vibe, then extract anonymized dimensions
        final userVibe = await _vibeAnalyzer.compileUserVibe(user.id, personalityProfile);
        // UserVibe has anonymizedDimensions that we can use
        quantumVibeAnalysis.addAll(userVibe.anonymizedDimensions);
      }

      // Get location quantum state (if user has location)
      EntityLocationQuantumState? locationState;
      if (user.location != null) {
        try {
          // Parse location string to UnifiedLocationData
          final unifiedLocation = await _parseLocationString(user.location!);
          if (unifiedLocation != null) {
            locationState = await _locationTimingService.createLocationQuantumState(
              location: unifiedLocation,
            );
          }
        } catch (e) {
          developer.log(
            'Error parsing user location: $e',
            name: _logName,
          );
        }
      }

      // Get timing quantum state from user preferences
      EntityTimingQuantumState? timingState;
      try {
        timingState = await _getUserTimingPreferences(user.id);
      } catch (e) {
        developer.log(
          'Error getting user timing preferences: $e',
          name: _logName,
        );
      }

      final userState = QuantumEntityState(
        entityId: user.id,
        entityType: QuantumEntityType.user,
        personalityState: personalityDimensions,
        quantumVibeAnalysis: quantumVibeAnalysis,
        entityCharacteristics: {
          'type': 'user',
          'email': user.email,
          'displayName': user.displayName,
        },
        location: locationState,
        timing: timingState,
        tAtomic: tAtomic,
      );

      // Cache the state
      _quantumStateCache[cacheKey] = CachedQuantumState(
        state: userState,
        timestamp: tAtomic,
      );

      // Clean cache if too large
      _cleanCacheIfNeeded();

      return userState;
    } catch (e, stackTrace) {
      developer.log(
        'Error getting user quantum state for ${user.id}: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      // Return fallback state
      final tAtomic = await _atomicClock.getAtomicTimestamp();
      return QuantumEntityState(
        entityId: user.id,
        entityType: QuantumEntityType.user,
        personalityState: {},
        quantumVibeAnalysis: {},
        entityCharacteristics: {'type': 'user'},
        tAtomic: tAtomic,
      );
    }
  }

  /// Get all users (with pagination support)
  Future<List<User>> _getAllUsers({int limit = 1000}) async {
    try {
      // Try to get users from Supabase if available
      if (_supabaseService.isAvailable) {
        try {
          final client = _supabaseService.client;
          final response = await client
              .from('users')
              .select('id, email, display_name, photo_url, location, created_at, updated_at, is_online, has_completed_onboarding')
              .limit(limit);

          final users = (response as List).map((json) {
            return User(
              id: json['id'] as String,
              email: json['email'] as String? ?? '',
              name: json['display_name'] as String? ?? json['name'] as String? ?? 'User',
              displayName: json['display_name'] as String?,
              role: UserRole.follower, // Default role - could be parsed from json if available
              avatarUrl: json['photo_url'] as String?,
              location: json['location'] as String?,
              createdAt: DateTime.parse(json['created_at'] as String),
              updatedAt: DateTime.parse(json['updated_at'] as String),
              isOnline: json['is_online'] as bool? ?? false,
            );
          }).toList();

          developer.log(
            'Retrieved ${users.length} users from Supabase',
            name: _logName,
          );
          return users;
        } catch (e) {
          developer.log(
            'Error getting users from Supabase: $e',
            name: _logName,
          );
          // Fall through to return empty list
        }
      }

      // Fallback: Return empty list if no user service available
      developer.log(
        'No user service available, returning empty user list',
        name: _logName,
      );
      return [];
    } catch (e, stackTrace) {
      developer.log(
        'Error getting users: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      return [];
    }
  }

  /// Find event location from event entities
  EntityLocationQuantumState? _findEventLocation(List<QuantumEntityState> entities) {
    for (final entity in entities) {
      if (entity.entityType == QuantumEntityType.event && entity.location != null) {
        return entity.location;
      }
    }
    return null;
  }

  /// Find event timing from event entities
  EntityTimingQuantumState? _findEventTiming(List<QuantumEntityState> entities) {
    for (final entity in entities) {
      if (entity.entityType == QuantumEntityType.event && entity.timing != null) {
        return entity.timing;
      }
    }
    return null;
  }

  /// Check if user was previously called to event
  Future<bool> _wasUserCalledToEvent(String userId, String eventId) async {
    // 1. Check in-memory cache first (fast)
    final calledUsers = _eventCalls[eventId];
    if (calledUsers != null && calledUsers.contains(userId)) {
      return true;
    }

    // 2. Check database for persistent tracking (slower but persistent)
    if (_supabaseService.isAvailable) {
      try {
        final client = _supabaseService.client;
        final result = await client
            .from('event_user_calls')
            .select('id')
            .eq('event_id', eventId)
            .eq('user_id', userId)
            .eq('status', 'active')
            .maybeSingle();

        if (result != null) {
          // Update cache for future lookups
          _eventCalls.putIfAbsent(eventId, () => <String>{}).add(userId);
          return true;
        }
      } catch (e) {
        developer.log(
          'Error checking database for event call: $e',
          name: _logName,
        );
      }
    }

    return false;
  }

  /// Call user to event
  Future<void> _callUserToEvent(
    String userId,
    String eventId,
    double compatibility,
    AtomicTimestamp tAtomic,
  ) async {
    developer.log(
      'Calling user $userId to event $eventId (compatibility: ${compatibility.toStringAsFixed(3)})',
      name: _logName,
    );

    try {
      // 1. Update in-memory cache (fast, immediate)
      _eventCalls.putIfAbsent(eventId, () => <String>{}).add(userId);
      _eventCallScores.putIfAbsent(eventId, () => {})[userId] = compatibility;

      // 2. Persist to database (async, can be batched)
      await _persistEventCallToDatabase(
        userId: userId,
        eventId: eventId,
        compatibility: compatibility,
        tAtomic: tAtomic,
        status: 'active',
      );

      // 3. Capture pre-event state for journey tracking
      try {
        await _journeyTrackingService.capturePreEventState(
          userId: userId,
          eventId: eventId,
        );
      } catch (e) {
        developer.log(
          'Error capturing pre-event state: $e, continuing',
          name: _logName,
        );
        // Don't fail calling if journey tracking fails.
      }

      // 4. Send notification to user
      await _sendEventCallNotification(
        userId: userId,
        eventId: eventId,
        compatibility: compatibility,
      );

      developer.log(
        '✅ User $userId called to event $eventId',
        name: _logName,
      );
    } catch (e, stackTrace) {
      developer.log(
        '❌ Error calling user $userId to event $eventId: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      // Don't rethrow - notification/database failure shouldn't block calling
    }
  }

  /// Update existing user call
  Future<void> _updateUserCall(
    String userId,
    String eventId,
    double compatibility,
    AtomicTimestamp tAtomic,
  ) async {
    developer.log(
      'Updating call for user $userId to event $eventId (compatibility: ${compatibility.toStringAsFixed(3)})',
      name: _logName,
    );

    try {
      // 1. Update in-memory cache
      _eventCallScores.putIfAbsent(eventId, () => {})[userId] = compatibility;

      // 2. Update database record
      await _persistEventCallToDatabase(
        userId: userId,
        eventId: eventId,
        compatibility: compatibility,
        tAtomic: tAtomic,
        status: 'active',
      );

      // 3. Send updated notification if compatibility changed significantly
      final previousScore = _eventCallScores[eventId]?[userId] ?? 0.0;
      if ((compatibility - previousScore).abs() > 0.1) {
        // Significant change - notify user
        await _sendEventCallNotification(
          userId: userId,
          eventId: eventId,
          compatibility: compatibility,
          isUpdate: true,
        );
      }

      developer.log(
        '✅ Updated call for user $userId to event $eventId',
        name: _logName,
      );
    } catch (e, stackTrace) {
      developer.log(
        '❌ Error updating call for user $userId to event $eventId: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
    }
  }

  /// Stop calling user to event
  Future<void> _stopCallingUserToEvent(
    String userId,
    String eventId,
    AtomicTimestamp tAtomic,
  ) async {
    developer.log(
      'Stopping call for user $userId to event $eventId',
      name: _logName,
    );

    try {
      // 1. Remove from in-memory cache
      _eventCalls[eventId]?.remove(userId);
      _eventCallScores[eventId]?.remove(userId);

      // 2. Update database record (mark as stopped)
      if (_supabaseService.isAvailable) {
        try {
          final client = _supabaseService.client;
          await client
              .from('event_user_calls')
              .update({
                'status': 'stopped',
                'stopped_at': tAtomic.serverTime.toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('event_id', eventId)
              .eq('user_id', userId);
        } catch (e) {
          developer.log(
            'Error updating database for stopped call: $e',
            name: _logName,
          );
        }
      }

      developer.log(
        '✅ Stopped calling user $userId to event $eventId',
        name: _logName,
      );
    } catch (e, stackTrace) {
      developer.log(
        '❌ Error stopping call for user $userId to event $eventId: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
    }
  }

  /// Clean cache if it exceeds max size
  void _cleanCacheIfNeeded() {
    if (_quantumStateCache.length > _maxCacheSize) {
      // Remove oldest entries
      final sorted = _quantumStateCache.entries.toList()
        ..sort((a, b) => a.value.cachedAt.compareTo(b.value.cachedAt));
      final toRemove = sorted.take(_quantumStateCache.length - _maxCacheSize);
      for (final entry in toRemove) {
        _quantumStateCache.remove(entry.key);
      }
    }

    if (_compatibilityCache.length > _maxCacheSize) {
      final sorted = _compatibilityCache.entries.toList()
        ..sort((a, b) => a.value.cachedAt.compareTo(b.value.cachedAt));
      final toRemove = sorted.take(_compatibilityCache.length - _maxCacheSize);
      for (final entry in toRemove) {
        _compatibilityCache.remove(entry.key);
      }
    }
  }

  /// Parse location string to UnifiedLocationData
  ///
  /// Attempts to geocode the location string to get coordinates
  Future<UnifiedLocationData?> _parseLocationString(String locationString) async {
    try {
      // Try to geocode the location string
      final placemarks = await geocoding.locationFromAddress(locationString);
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        return UnifiedLocationData(
          latitude: placemark.latitude,
          longitude: placemark.longitude,
          city: locationString, // Use original string as city fallback
          timestamp: DateTime.now(),
        );
      }
    } catch (e) {
      developer.log(
        'Error geocoding location string "$locationString": $e',
        name: _logName,
      );
    }

    // Fallback: Try to parse as "City, State" or "City, State, Country"
    // This is a simple parser for common formats
    final parts = locationString.split(',').map((s) => s.trim()).toList();
    if (parts.length >= 2) {
      // Assume format: "City, State" or "City, State, Country"
      // For now, return null as we need coordinates for UnifiedLocationData
      // In production, could use a geocoding service or database lookup
      return null;
    }

    return null;
  }

  /// Get user timing preferences from PreferencesProfile
  ///
  /// Infers timing preferences from user behavior or uses defaults
  Future<EntityTimingQuantumState?> _getUserTimingPreferences(String userId) async {
    try {
      // Get agentId for privacy protection
      final agentId = await _agentIdService.getUserAgentId(userId);

      // Get PreferencesProfile if available
      final preferencesProfile =
          await _preferencesProfileService.getPreferencesProfile(agentId);

      // Infer timing preferences from PreferencesProfile
      if (preferencesProfile != null) {
        final explorationWillingness = preferencesProfile.explorationWillingness;
        
        // Time of day: More exploration = later in day (evening/night preference)
        final timeOfDayPreference = 0.3 + (explorationWillingness * 0.4);
        final timeOfDayHour = (timeOfDayPreference * 24).round().clamp(0, 23);
        
        // Day of week: More exploration = weekend preference
        final dayOfWeekPreference = 0.3 + (explorationWillingness * 0.4);
        final dayOfWeek = (dayOfWeekPreference * 7).round().clamp(0, 6);
        
        // Frequency: Based on exploration (more exploration = more frequent)
        final frequencyPreference = 0.4 + (explorationWillingness * 0.3);
        
        // Duration: Based on exploration (more exploration = longer events)
        final durationPreference = 0.5 + (explorationWillingness * 0.2);
        
        return await _locationTimingService.createTimingQuantumStateFromIntuitive(
          timeOfDayHour: timeOfDayHour,
          dayOfWeek: dayOfWeek,
          frequencyPreference: frequencyPreference,
          durationPreference: durationPreference,
        );
      }

      // Default preferences if no PreferencesProfile
      const defaultTimeOfDayHour = 19; // 7 PM
      const defaultDayOfWeek = 6; // Saturday (weekend)
      const defaultFrequency = 0.5; // Moderate
      const defaultDuration = 0.5; // Medium

      return await _locationTimingService.createTimingQuantumStateFromIntuitive(
        timeOfDayHour: defaultTimeOfDayHour,
        dayOfWeek: defaultDayOfWeek,
        frequencyPreference: defaultFrequency,
        durationPreference: defaultDuration,
      );
    } catch (e) {
      developer.log(
        'Error getting user timing preferences: $e',
        name: _logName,
      );
      return null;
    }
  }

  /// Calculate knot compatibility bonus
  ///
  /// Uses CrossEntityCompatibilityService to calculate compatibility between
  /// user's personality knot and event entity knots
  Future<double> _calculateKnotCompatibilityBonus({
    required QuantumEntityState userState,
    required List<QuantumEntityState> eventEntities,
  }) async {
    if (_knotCompatibilityService == null) {
      return 0.0;
    }

    try {
      // Get user's personality profile to generate knot
      final personalityProfile = await _personalityLearning.getCurrentPersonality(userState.entityId);
      if (personalityProfile == null) {
        return 0.0;
      }

      // Generate user's personality knot (for future use in full knot compatibility)
      // TODO: In production, use EntityKnotService to generate knots for all entity types
      // and use CrossEntityCompatibilityService for full knot compatibility
      // For now, we'll use quantum vibe similarity as a proxy for knot compatibility
      await _personalityKnotService.generateKnot(personalityProfile);

      // Calculate compatibility with each event entity
      double totalCompatibility = 0.0;
      int entityCount = 0;

      for (final eventEntity in eventEntities) {
        try {
          // For now, use quantum vibe similarity as compatibility proxy
          // TODO: In production, generate EntityKnot for event entities using EntityKnotService
          // and use CrossEntityCompatibilityService for full knot compatibility
          final vibeSimilarity = _calculateVibeSimilarity(
            userState.quantumVibeAnalysis,
            eventEntity.quantumVibeAnalysis,
          );
          totalCompatibility += vibeSimilarity;
          entityCount++;
        } catch (e) {
          developer.log(
            'Error calculating compatibility for entity ${eventEntity.entityId}: $e',
            name: _logName,
          );
          // Continue with next entity
        }
      }

      if (entityCount == 0) {
        return 0.0;
      }

      // Average compatibility across all entities
      final averageCompatibility = totalCompatibility / entityCount;
      return averageCompatibility.clamp(0.0, 1.0);
    } catch (e) {
      developer.log(
        'Error calculating knot compatibility bonus: $e',
        name: _logName,
      );
      return 0.0;
    }
  }

  /// Calculate vibe similarity between two quantum vibe analyses
  ///
  /// Uses cosine similarity or dot product of vibe dimensions
  double _calculateVibeSimilarity(
    Map<String, double> vibeA,
    Map<String, double> vibeB,
  ) {
    if (vibeA.isEmpty || vibeB.isEmpty) {
      return 0.0;
    }

    // Calculate dot product (cosine similarity when normalized)
    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    final allDimensions = {...vibeA.keys, ...vibeB.keys};
    for (final dimension in allDimensions) {
      final valueA = vibeA[dimension] ?? 0.0;
      final valueB = vibeB[dimension] ?? 0.0;
      dotProduct += valueA * valueB;
      normA += valueA * valueA;
      normB += valueB * valueB;
    }

    if (normA == 0.0 || normB == 0.0) {
      return 0.0;
    }

    // Cosine similarity
    final similarity = dotProduct / (math.sqrt(normA) * math.sqrt(normB));
    return similarity.clamp(0.0, 1.0);
  }

  /// Persist event call to database
  ///
  /// Uses hybrid approach: in-memory cache + database persistence
  Future<void> _persistEventCallToDatabase({
    required String userId,
    required String eventId,
    required double compatibility,
    required AtomicTimestamp tAtomic,
    required String status,
  }) async {
    if (!_supabaseService.isAvailable) {
      return; // Graceful degradation - cache still works
    }

    try {
      final client = _supabaseService.client;
      await client
          .from('event_user_calls')
          .upsert({
            'event_id': eventId,
            'user_id': userId,
            'compatibility_score': compatibility,
            'called_at': tAtomic.serverTime.toIso8601String(),
            'atomic_timestamp_id': tAtomic.timestampId,
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'event_id,user_id');
    } catch (e) {
      developer.log(
        'Error persisting event call to database: $e',
        name: _logName,
      );
      // Don't rethrow - database failure shouldn't block calling
    }
  }

  /// Send event call notification to user
  ///
  /// Sends push notification when user is called to an event
  /// Send event call notification via AI2AI mesh with Signal Protocol encryption
  ///
  /// **Enhanced with AI2AI Mesh + Signal Protocol:**
  /// 1. Creates anonymous notification payload (privacy-preserving)
  /// 2. Encrypts using Signal Protocol (via HybridEncryptionService)
  /// 3. Routes through AI2AI mesh (via AnonymousCommunicationProtocol)
  /// 4. Falls back to database storage if AI2AI services unavailable
  Future<void> _sendEventCallNotification({
    required String userId,
    required String eventId,
    required double compatibility,
    bool isUpdate = false,
  }) async {
    try {
      developer.log(
        'Sending ${isUpdate ? "update" : "call"} notification to user $userId for event $eventId (compatibility: ${compatibility.toStringAsFixed(3)})',
        name: _logName,
      );

      // 1. Try AI2AI mesh + Signal Protocol (if available)
      final ai2aiProtocol = _ai2aiProtocol;
      final encryptionService = _encryptionService;
      if (ai2aiProtocol != null && encryptionService != null) {
        try {
          // Get agent ID for recipient (user)
          final recipientAgentId = await _agentIdService.getUserAgentId(userId);

          // Create anonymous notification payload (no user data, just event info)
          final notificationPayload = {
            'type': isUpdate ? 'event_call_updated' : 'event_call',
            'eventId': eventId, // Event ID is public, no privacy concern
            'compatibility': compatibility, // Compatibility score (0.0-1.0)
            'timestamp': DateTime.now().toIso8601String(),
          };

          // Route through AI2AI mesh with Signal Protocol encryption
          // sendEncryptedMessage handles encryption internally via MessageEncryptionService
          // Parameters are positional: targetAgentId, messageType, anonymousPayload
          await ai2aiProtocol.sendEncryptedMessage(
            recipientAgentId, // targetAgentId (positional)
            MessageType.recommendationShare, // messageType (positional) - Use recommendationShare for event recommendations
            notificationPayload, // anonymousPayload (positional)
          );

          developer.log(
            '✅ Notification sent via AI2AI mesh + Signal Protocol to user $userId',
            name: _logName,
          );

          // Still store in database for in-app notifications (fallback)
          await _storeNotificationInDatabase(
            userId: userId,
            eventId: eventId,
            compatibility: compatibility,
            isUpdate: isUpdate,
          );

          return; // Successfully sent via AI2AI mesh
        } catch (e) {
          developer.log(
            'Error sending notification via AI2AI mesh: $e, falling back to database',
            name: _logName,
          );
          // Fall through to database storage
        }
      }

      // 2. Fallback: Store notification in database for in-app notifications
      await _storeNotificationInDatabase(
        userId: userId,
        eventId: eventId,
        compatibility: compatibility,
        isUpdate: isUpdate,
      );
    } catch (e) {
      developer.log(
        'Error sending event call notification: $e',
        name: _logName,
      );
      // Don't rethrow - notification failure shouldn't block calling
    }
  }

  /// Store notification in database (helper method)
  Future<void> _storeNotificationInDatabase({
    required String userId,
    required String eventId,
    required double compatibility,
    required bool isUpdate,
  }) async {
    if (_supabaseService.isAvailable) {
      try {
        final client = _supabaseService.client;
        await client.from('notifications').insert({
          'user_id': userId,
          'type': isUpdate ? 'event_call_updated' : 'event_call',
          'title': isUpdate ? 'Event Match Updated' : 'New Event Match',
          'body': 'You have a ${(compatibility * 100).round()}% match with an event!',
          'data': {
            'eventId': eventId,
            'compatibility': compatibility,
          },
          'created_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        developer.log(
          'Error storing notification in database: $e',
          name: _logName,
        );
      }
    }
  }
}

/// Cached quantum state
class CachedQuantumState {
  final QuantumEntityState state;
  final AtomicTimestamp timestamp;
  final DateTime cachedAt;

  CachedQuantumState({
    required this.state,
    required this.timestamp,
  }) : cachedAt = DateTime.now();

  bool get isExpired {
    // Check if cache is expired using DateTime comparison
    final now = DateTime.now();
    final age = now.difference(cachedAt);
    // TTL is 5 minutes
    return age > const Duration(minutes: 5);
  }
}

/// Cached compatibility
class CachedCompatibility {
  final double compatibility;
  final AtomicTimestamp timestamp;
  final DateTime cachedAt;

  CachedCompatibility({
    required this.compatibility,
    required this.timestamp,
  }) : cachedAt = DateTime.now();

  bool get isExpired {
    // Check if cache is expired using DateTime comparison
    final now = DateTime.now();
    final age = now.difference(cachedAt);
    // TTL is 5 minutes
    return age > const Duration(minutes: 5);
  }
}
