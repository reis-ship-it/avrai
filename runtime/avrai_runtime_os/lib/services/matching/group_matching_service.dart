// Group Matching Service
//
// Implements quantum group matching with knot/string/fabric/worldsheet integration
// Part of Phase 19.18: Quantum Group Matching System
// Section GM.1: Core Group Matching Service
// Patent #29: Multi-Entity Quantum Entanglement Matching System
// Patent #31: Topological Knot Theory for Personality Representation
//
// **Enhanced Formula (Hybrid Approach):**
// ```
// C_core = (C_quantum * C_knot * C_string)^(1/3)  // Geometric mean
// C_modifiers = 0.4 * C_location + 0.3 * C_timing + 0.2 * C_fabric + 0.1 * C_worldsheet
// C_group = C_core * (1.0 + 0.3 * C_modifiers)  // Multiplicative combination
// ```

import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:avrai_core/models/quantum_entity_state.dart';
import 'package:avrai_core/models/quantum_entity_type.dart';
import 'package:avrai_core/models/atomic_timestamp.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_core/models/personality_knot.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_quantum/services/quantum/quantum_entanglement_service.dart';
import 'package:avrai_quantum/services/quantum/location_timing_quantum_state_service.dart';
import 'package:avrai_knot/services/knot/knot_evolution_string_service.dart';
import 'package:avrai_knot/services/knot/knot_fabric_service.dart';
import 'package:avrai_knot/services/knot/knot_worldsheet_service.dart';
import 'package:avrai_knot/services/knot/knot_storage_service.dart';
import 'package:avrai_knot/services/knot/cross_entity_compatibility_service.dart';
import 'package:avrai_knot/models/knot/knot_fabric.dart';
import 'package:avrai_runtime_os/ai/personality_learning.dart';
import 'package:avrai_runtime_os/ai/vibe_analysis_engine.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';
import 'package:avrai_core/models/spots/spot.dart';
import 'package:avrai_core/models/spots/spot_vibe.dart';
import 'package:avrai_core/models/quantum/group_matching_result.dart';
import 'package:avrai_core/models/quantum/group_session.dart';
import 'package:avrai_core/models/unified_location_data.dart';
import 'package:avrai_core/models/user/unified_models.dart';
import 'package:avrai_runtime_os/ai/quantum/location_compatibility_calculator.dart'
    as location_calc;
import 'package:avrai_quantum/services/quantum/location_timing_quantum_state_service.dart'
    as timing_calc;

/// Core group matching service
///
/// **Purpose:**
/// - Creates quantum entangled group states from multiple users
/// - Matches group against spots using hybrid compatibility calculation
/// - Integrates knot/string/fabric/worldsheet predictions
/// - Uses vectorless schema for caching
/// - Privacy-protected (agentId-only)
class GroupMatchingService {
  static const String _logName = 'GroupMatchingService';

  final AtomicClockService _atomicClock;
  final QuantumEntanglementService _entanglementService;
  final LocationTimingQuantumStateService _locationTimingService;
  final KnotEvolutionStringService _stringService;
  final KnotFabricService _fabricService;
  // ignore: unused_field
  final KnotWorldsheetService _worldsheetService;
  final KnotStorageService _knotStorage;
  // ignore: unused_field
  final CrossEntityCompatibilityService? _knotCompatibilityService;
  final PersonalityLearning _personalityLearning;
  // ignore: unused_field
  final UserVibeAnalyzer _vibeAnalyzer;
  // ignore: unused_field
  final AgentIdService _agentIdService;
  // ignore: unused_field
  final SupabaseService _supabaseService;

  GroupMatchingService({
    required AtomicClockService atomicClock,
    required QuantumEntanglementService entanglementService,
    required LocationTimingQuantumStateService locationTimingService,
    required KnotEvolutionStringService stringService,
    required KnotFabricService fabricService,
    required KnotWorldsheetService worldsheetService,
    required KnotStorageService knotStorage,
    CrossEntityCompatibilityService? knotCompatibilityService,
    required PersonalityLearning personalityLearning,
    required UserVibeAnalyzer vibeAnalyzer,
    required AgentIdService agentIdService,
    required SupabaseService supabaseService,
  })  : _atomicClock = atomicClock,
        _entanglementService = entanglementService,
        _locationTimingService = locationTimingService,
        _stringService = stringService,
        _fabricService = fabricService,
        _worldsheetService = worldsheetService,
        _knotStorage = knotStorage,
        _knotCompatibilityService = knotCompatibilityService,
        _personalityLearning = personalityLearning,
        _vibeAnalyzer = vibeAnalyzer,
        _agentIdService = agentIdService,
        _supabaseService = supabaseService;

  /// Match group against spots
  ///
  /// **Flow:**
  /// 1. Get atomic timestamp
  /// 2. Load all group members' profiles and knots
  /// 3. Create quantum entangled group state
  /// 4. Generate/load group fabric
  /// 5. For each spot:
  ///    - Calculate quantum compatibility
  ///    - Calculate knot compatibility
  ///    - Predict string evolution
  ///    - Measure fabric stability
  ///    - Calculate worldsheet evolution
  ///    - Calculate location/timing compatibility
  ///    - Combine using hybrid approach
  /// 6. Sort by group compatibility
  /// 7. Return results
  ///
  /// **Parameters:**
  /// - `session`: Group session with member agentIds
  /// - `candidateSpots`: Spots to match against
  /// - `matchingStrategy`: Strategy to use (default: 'hybrid')
  ///
  /// **Returns:**
  /// GroupMatchingResult with matched spots sorted by compatibility
  Future<GroupMatchingResult> matchGroupAgainstSpots({
    required GroupSession session,
    required List<Spot> candidateSpots,
    String matchingStrategy = 'hybrid',
  }) async {
    developer.log(
      'Matching group ${session.groupId} (${session.memberCount} members) against ${candidateSpots.length} spots',
      name: _logName,
    );

    try {
      final tAtomic = await _atomicClock.getAtomicTimestamp();

      // Validate session
      if (session.isExpired) {
        throw ArgumentError('Group session expired: ${session.sessionId}');
      }

      if (session.memberCount < 2) {
        throw ArgumentError('Group must have at least 2 members');
      }

      // Step 1: Load all group members' profiles and knots
      final memberProfiles = <String, PersonalityProfile>{};
      final memberKnots = <String, PersonalityKnot>{};
      final memberQuantumStates = <QuantumEntityState>[];

      for (final agentId in session.memberAgentIds) {
        try {
          // Load personality profile
          // Note: We need userId from agentId - this is a limitation
          // For now, we'll need to get userId from agentId mapping
          // TODO: Add method to get userId from agentId if needed
          final profile = await _loadProfileForAgent(agentId);
          if (profile == null) {
            developer.log(
              '⚠️ No profile found for agentId: ${agentId.substring(0, 10)}...',
              name: _logName,
            );
            continue;
          }
          memberProfiles[agentId] = profile;

          // Load personality knot
          final knot = await _knotStorage.loadKnot(agentId);
          if (knot != null) {
            memberKnots[agentId] = knot;
          }

          // Create quantum state
          final quantumState = QuantumEntityState(
            entityId: agentId, // Use agentId for privacy
            entityType: QuantumEntityType.user,
            personalityState: profile.dimensions,
            quantumVibeAnalysis: profile.dimensions,
            entityCharacteristics: {
              'archetype': profile.archetype,
              'authenticity': profile.authenticity,
            },
            tAtomic: tAtomic,
          );
          memberQuantumStates.add(quantumState);
        } catch (e) {
          developer.log(
            'Error loading profile/knot for agentId ${agentId.substring(0, 10)}...: $e',
            name: _logName,
          );
          continue;
        }
      }

      if (memberQuantumStates.length < 2) {
        throw ArgumentError('Need at least 2 valid group members');
      }

      developer.log(
        'Loaded ${memberQuantumStates.length} group members',
        name: _logName,
      );

      // Step 2: Create quantum entangled group state
      final groupEntangledState =
          await _entanglementService.createEntangledState(
        entityStates: memberQuantumStates,
      );

      // Step 3: Generate/load group fabric
      final groupFabric = await _getOrCreateGroupFabric(
        session: session,
        memberKnots: memberKnots.values.toList(),
      );

      // Step 4: Match against spots
      final matchedSpots = <GroupMatchedSpot>[];

      for (final spot in candidateSpots) {
        try {
          final compatibility = await _calculateGroupSpotCompatibility(
            groupEntangledState: groupEntangledState,
            memberQuantumStates: memberQuantumStates,
            memberKnots: memberKnots,
            memberProfiles: memberProfiles,
            spot: spot,
            groupFabric: groupFabric,
            tAtomic: tAtomic,
            matchingStrategy: matchingStrategy,
          );

          if (compatibility != null) {
            matchedSpots.add(compatibility);
          }
        } catch (e) {
          developer.log(
            'Error matching spot ${spot.id}: $e',
            name: _logName,
          );
          continue;
        }
      }

      // Step 5: Sort by group compatibility (highest first)
      matchedSpots
          .sort((a, b) => b.groupCompatibility.compareTo(a.groupCompatibility));

      developer.log(
        '✅ Matched ${matchedSpots.length} spots for group ${session.groupId}',
        name: _logName,
      );

      return GroupMatchingResult(
        groupId: session.groupId,
        matchedSpots: matchedSpots,
        groupSize: session.memberCount,
        timestamp: tAtomic,
        matchingStrategy: matchingStrategy,
      );
    } catch (e, stackTrace) {
      developer.log(
        '❌ Error matching group against spots: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }

  /// Calculate group-spot compatibility using hybrid approach
  Future<GroupMatchedSpot?> _calculateGroupSpotCompatibility({
    required EntangledQuantumState groupEntangledState,
    required List<QuantumEntityState> memberQuantumStates,
    required Map<String, PersonalityKnot> memberKnots,
    required Map<String, PersonalityProfile> memberProfiles,
    required Spot spot,
    required KnotFabric? groupFabric,
    required AtomicTimestamp tAtomic,
    required String matchingStrategy,
  }) async {
    try {
      // Create spot quantum state
      final spotQuantumState = await _createSpotQuantumState(spot, tAtomic);

      // ===== CORE FACTORS (Geometric Mean) =====

      // 1. Quantum compatibility
      final quantumCompatibility = await _calculateQuantumCompatibility(
        groupEntangledState: groupEntangledState,
        spotQuantumState: spotQuantumState,
      );

      // 2. Knot compatibility
      // Note: Spots don't have personality knots, so we skip knot compatibility for spots
      // For group-group matching, we would use knot compatibility
      double knotCompatibility =
          0.5; // Default: neutral (spots don't have knots)

      // 3. String evolution compatibility
      double stringEvolutionCompatibility = 0.5; // Default: neutral
      try {
        final stringScores = <double>[];
        for (final agentId in memberKnots.keys) {
          try {
            // Predict future knot at spot visit time (use current time as proxy)
            final futureKnot = await _stringService.predictFutureKnot(
              agentId,
              DateTime.now()
                  .add(const Duration(hours: 2)), // Assume visit in 2 hours
            );
            if (futureKnot != null) {
              final currentKnot = memberKnots[agentId];
              if (currentKnot != null) {
                final evolutionScore = _calculateKnotEvolutionScore(
                  currentKnot: currentKnot,
                  futureKnot: futureKnot,
                );
                stringScores.add(evolutionScore.clamp(0.0, 1.0));
              }
            }
          } catch (e) {
            // Skip this member
            continue;
          }
        }
        if (stringScores.isNotEmpty) {
          stringEvolutionCompatibility =
              stringScores.reduce((a, b) => a + b) / stringScores.length;
        }
      } catch (e) {
        developer.log(
          'Error calculating string evolution: $e, using neutral 0.5',
          name: _logName,
        );
      }

      // Calculate core compatibility using geometric mean
      final coreCompatibility = _geometricMean([
        quantumCompatibility,
        knotCompatibility,
        stringEvolutionCompatibility,
      ]);

      // ===== MODIFIERS (Weighted Average) =====

      // 1. Location compatibility
      double locationCompatibility = 0.5; // Default: neutral
      try {
        final locationScores = <double>[];
        final spotLocation = UnifiedLocation(
          latitude: spot.latitude,
          longitude: spot.longitude,
        );
        for (final memberState in memberQuantumStates) {
          if (memberState.location != null) {
            // Convert EntityLocationQuantumState to UnifiedLocation for compatibility calculation
            final memberLocation = UnifiedLocation(
              latitude: memberState.location!.latitudeQuantumState * 180.0 -
                  90.0, // Denormalize
              longitude: memberState.location!.longitudeQuantumState * 360.0 -
                  180.0, // Denormalize
            );
            final score = location_calc.LocationCompatibilityCalculator
                .calculateLocationCompatibility(
              locationA: memberLocation,
              locationB: spotLocation,
            );
            locationScores.add(score.clamp(0.0, 1.0));
          }
        }
        if (locationScores.isNotEmpty) {
          locationCompatibility =
              locationScores.reduce((a, b) => a + b) / locationScores.length;
        }
      } catch (e) {
        developer.log(
          'Error calculating location compatibility: $e, using neutral 0.5',
          name: _logName,
        );
      }

      // 2. Timing compatibility
      double timingCompatibility = 0.5; // Default: neutral
      try {
        final timingScores = <double>[];
        // Create default spot timing (use current time as proxy)
        final now = DateTime.now();
        final spotTiming = EntityTimingQuantumState(
          timeOfDayPreference: (now.hour / 24.0).clamp(0.0, 1.0),
          dayOfWeekPreference: now.weekday >= 6 ? 1.0 : 0.0, // Weekend = 1.0
          frequencyPreference: 0.5, // Neutral
          durationPreference: 0.5, // Neutral
          timingVibeMatch: 0.5, // Neutral
        );
        for (final memberState in memberQuantumStates) {
          if (memberState.timing != null) {
            final score = timing_calc.TimingCompatibilityCalculator
                .calculateTimingCompatibility(
              memberState.timing!,
              spotTiming,
            );
            timingScores.add(score.clamp(0.0, 1.0));
          }
        }
        if (timingScores.isNotEmpty) {
          timingCompatibility =
              timingScores.reduce((a, b) => a + b) / timingScores.length;
        }
      } catch (e) {
        developer.log(
          'Error calculating timing compatibility: $e, using neutral 0.5',
          name: _logName,
        );
      }

      // 3. Fabric stability
      double fabricStability = 0.5; // Default: neutral
      if (groupFabric != null) {
        try {
          fabricStability = await _fabricService.measureFabricStability(
            groupFabric,
          );
        } catch (e) {
          developer.log(
            'Error measuring fabric stability: $e, using neutral 0.5',
            name: _logName,
          );
        }
      }

      // 4. Worldsheet evolution compatibility
      double worldsheetCompatibility = 0.5; // Default: neutral
      // TODO: Implement worldsheet evolution calculation
      // This would require creating a worldsheet for the group and predicting evolution

      // Calculate modifiers using weighted average
      final modifiers = (0.4 * locationCompatibility +
              0.3 * timingCompatibility +
              0.2 * fabricStability +
              0.1 * worldsheetCompatibility)
          .clamp(0.0, 1.0);

      // ===== FINAL COMBINATION =====
      // C_group = C_core * (1.0 + 0.3 * C_modifiers)
      final groupCompatibility = coreCompatibility * (1.0 + 0.3 * modifiers);

      // Calculate individual member compatibility scores
      final memberCompatibilityScores = <String, double>{};
      for (final memberState in memberQuantumStates) {
        try {
          final memberCompatibility = await _calculateMemberSpotCompatibility(
            memberState: memberState,
            spotQuantumState: spotQuantumState,
          );
          memberCompatibilityScores[memberState.entityId] =
              memberCompatibility.clamp(0.0, 1.0);
        } catch (e) {
          // Skip this member
          continue;
        }
      }

      return GroupMatchedSpot(
        spot: spot,
        groupCompatibility: groupCompatibility.clamp(0.0, 1.0),
        quantumCompatibility: quantumCompatibility,
        knotCompatibility: knotCompatibility,
        stringEvolutionCompatibility: stringEvolutionCompatibility,
        fabricStability: fabricStability,
        worldsheetCompatibility: worldsheetCompatibility,
        locationCompatibility: locationCompatibility,
        timingCompatibility: timingCompatibility,
        memberCompatibilityScores: memberCompatibilityScores,
        timestamp: tAtomic,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error calculating group-spot compatibility: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      return null;
    }
  }

  /// Load profile for agentId
  /// TODO: This is a placeholder - need proper agentId -> userId mapping
  Future<PersonalityProfile?> _loadProfileForAgent(String agentId) async {
    // For now, try to use agentId directly
    // In production, we'd need a mapping service
    try {
      return await _personalityLearning.getCurrentPersonality(agentId);
    } catch (e) {
      return null;
    }
  }

  /// Get or create group fabric
  Future<KnotFabric?> _getOrCreateGroupFabric({
    required GroupSession session,
    required List<PersonalityKnot> memberKnots,
  }) async {
    try {
      // Try to load existing fabric
      if (session.fabricId != null) {
        final fabric = await _knotStorage.loadFabric(session.fabricId!);
        if (fabric != null) {
          return fabric;
        }
      }

      // Generate fabric on-the-fly
      if (memberKnots.length >= 2) {
        return await _fabricService.generateMultiStrandBraidFabric(
          userKnots: memberKnots,
        );
      }

      return null;
    } catch (e) {
      developer.log(
        'Error getting/creating group fabric: $e',
        name: _logName,
      );
      return null;
    }
  }

  /// Calculate quantum compatibility between group and spot
  Future<double> _calculateQuantumCompatibility({
    required EntangledQuantumState groupEntangledState,
    required QuantumEntityState spotQuantumState,
  }) async {
    try {
      // Create entangled state for spot
      final spotEntangledState =
          await _entanglementService.createEntangledState(
        entityStates: [spotQuantumState],
      );

      // Calculate fidelity
      return await _entanglementService.calculateFidelity(
        groupEntangledState,
        spotEntangledState,
      );
    } catch (e) {
      developer.log(
        'Error calculating quantum compatibility: $e',
        name: _logName,
      );
      return 0.5; // Neutral
    }
  }

  /// Calculate individual member-spot compatibility
  Future<double> _calculateMemberSpotCompatibility({
    required QuantumEntityState memberState,
    required QuantumEntityState spotQuantumState,
  }) async {
    try {
      final memberEntangledState =
          await _entanglementService.createEntangledState(
        entityStates: [memberState],
      );
      final spotEntangledState =
          await _entanglementService.createEntangledState(
        entityStates: [spotQuantumState],
      );

      return await _entanglementService.calculateFidelity(
        memberEntangledState,
        spotEntangledState,
      );
    } catch (e) {
      return 0.5; // Neutral
    }
  }

  /// Create spot quantum state
  Future<QuantumEntityState> _createSpotQuantumState(
    Spot spot,
    AtomicTimestamp tAtomic,
  ) async {
    // Infer spot vibe from spot characteristics
    final spotVibe = SpotVibe.fromSpotCharacteristics(
      spotId: spot.id,
      category: spot.category,
      tags: spot.tags,
      description: spot.description,
      rating: spot.rating,
    );

    // Create location quantum state
    final locationData = UnifiedLocationData(
      latitude: spot.latitude,
      longitude: spot.longitude,
      address: spot.address,
    );
    final locationState =
        await _locationTimingService.createLocationQuantumState(
      location: locationData,
    );

    return QuantumEntityState(
      entityId: spot.id,
      entityType: QuantumEntityType.business, // Spots are businesses
      personalityState: spotVibe.vibeDimensions,
      quantumVibeAnalysis: spotVibe.vibeDimensions,
      entityCharacteristics: {
        'category': spot.category,
        'rating': spot.rating,
        'name': spot.name,
      },
      location: locationState,
      tAtomic: tAtomic,
    );
  }

  /// Calculate knot evolution score
  double _calculateKnotEvolutionScore({
    required PersonalityKnot currentKnot,
    required PersonalityKnot futureKnot,
  }) {
    // Simple compatibility: compare knot invariants
    // More sophisticated: calculate topological distance
    try {
      final currentInvariants = currentKnot.invariants;
      final futureInvariants = futureKnot.invariants;

      // Compare Jones polynomial (simplified)
      // In production, use proper topological distance
      if (currentInvariants.jonesPolynomial.length ==
          futureInvariants.jonesPolynomial.length) {
        // Similar structure = high compatibility
        return 0.8;
      }
      return 0.5; // Neutral
    } catch (e) {
      return 0.5; // Neutral
    }
  }

  /// Calculate geometric mean
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
}
