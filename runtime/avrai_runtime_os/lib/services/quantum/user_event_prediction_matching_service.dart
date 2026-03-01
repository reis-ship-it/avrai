// User Event Prediction Matching Service
//
// Implements user-event prediction matching using quantum entanglement, knot evolution strings,
// fabrics, and worldsheet predictions to predict user interests
// Part of Phase 19 Section 19.11: Hypothetical Matching System
// Patent #29: Multi-Entity Quantum Entanglement Matching System
// Patent #31: Topological Knot Theory for Personality Representation

import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:avrai_core/models/quantum_entity_state.dart';
import 'package:avrai_core/models/quantum_entity_type.dart';
import 'package:avrai_core/models/atomic_timestamp.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_quantum/services/quantum/quantum_entanglement_service.dart';
import 'package:avrai_runtime_os/services/expertise/expertise_event_service.dart';
import 'package:avrai_core/models/user/unified_user.dart';
import 'package:avrai_core/models/expertise/expertise_event.dart';
import 'package:avrai_runtime_os/ai/personality_learning.dart';
import 'package:avrai_knot/services/knot/knot_evolution_string_service.dart';
import 'package:avrai_knot/services/knot/knot_fabric_service.dart';
import 'package:avrai_knot/services/knot/knot_storage_service.dart';
import 'package:avrai_knot/services/knot/knot_worldsheet_service.dart';
import 'package:avrai_runtime_os/services/predictive_outreach/future_compatibility_prediction_service.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'package:avrai_runtime_os/services/security/hybrid_encryption_service.dart';
import 'package:avrai_runtime_os/ai2ai/anonymous_communication.dart';
import 'package:avrai_core/models/personality_knot.dart';

/// User-event prediction matching service for "what-if" scenarios
///
/// **Enhanced Formula (with Knot/String/Fabric Integration):**
/// |ψ_hypothetical_U_E(t_atomic)⟩ = Σ_{s∈S} w_s |ψ_s(t_atomic_s)⟩ ⊗ |ψ_E(t_atomic_E)⟩
///
/// **Enhanced Prediction Formula:**
/// P(user U will like event E) =
///   0.35 * C_hypothetical_quantum +
///   0.25 * C_knot_string_prediction +
///   0.20 * C_fabric_stability +
///   0.15 * overlap_score +
///   0.05 * behavior_similarity
///
/// Where:
/// - C_hypothetical_quantum = Quantum entanglement compatibility
/// - C_knot_string_prediction = Future knot compatibility from string predictions
/// - C_fabric_stability = Group stability if event has group/community
///
/// **Atomic Timing:**
/// All hypothetical state calculations use AtomicClockService for precise temporal tracking
class UserEventPredictionMatchingService {
  static const String _logName = 'UserEventPredictionMatchingService';

  final AtomicClockService _atomicClock;
  final QuantumEntanglementService _entanglementService;
  final ExpertiseEventService _eventService;
  final PersonalityLearning _personalityLearning;
  final KnotEvolutionStringService _stringService;
  final KnotFabricService _fabricService;
  final KnotStorageService _knotStorage;
  final KnotWorldsheetService _worldsheetService;
  final FutureCompatibilityPredictionService _futureCompatService;
  final AgentIdService _agentIdService;
  // Phase 19 Integration Enhancement: AI2AI Mesh + Signal Protocol (reserved for future use)
  // Reserved for sharing predictions with other users' AIs for learning or transmitting results
  // ignore: unused_field
  final HybridEncryptionService? _encryptionService;
  // ignore: unused_field
  final AnonymousCommunicationProtocol? _ai2aiProtocol;

  UserEventPredictionMatchingService({
    required AtomicClockService atomicClock,
    required QuantumEntanglementService entanglementService,
    required ExpertiseEventService eventService,
    required PersonalityLearning personalityLearning,
    required KnotEvolutionStringService stringService,
    required KnotFabricService fabricService,
    required KnotStorageService knotStorage,
    required KnotWorldsheetService worldsheetService,
    required FutureCompatibilityPredictionService futureCompatService,
    required AgentIdService agentIdService,
    HybridEncryptionService? encryptionService,
    AnonymousCommunicationProtocol? ai2aiProtocol,
  })  : _atomicClock = atomicClock,
        _entanglementService = entanglementService,
        _eventService = eventService,
        _personalityLearning = personalityLearning,
        _stringService = stringService,
        _fabricService = fabricService,
        _knotStorage = knotStorage,
        _worldsheetService = worldsheetService,
        _futureCompatService = futureCompatService,
        _agentIdService = agentIdService,
        _encryptionService = encryptionService,
        _ai2aiProtocol = ai2aiProtocol;

  /// Predict if user will like an event using enhanced matching with knots/strings/fabrics
  ///
  /// **Enhanced Formula:**
  /// P(user U will like event E) =
  ///   0.35 * C_hypothetical_quantum +
  ///   0.25 * C_knot_string_prediction +
  ///   0.20 * C_fabric_stability +
  ///   0.15 * overlap_score +
  ///   0.05 * behavior_similarity
  ///
  /// **Returns:**
  /// UserEventPrediction with prediction score and reasoning
  Future<UserEventPrediction> predictUserEventCompatibility({
    required String userId,
    required String eventId,
  }) async {
    developer.log(
      'Predicting compatibility for user $userId and event $eventId (with knot/string/fabric integration)',
      name: _logName,
    );

    try {
      // Get atomic timestamp for prediction
      final tAtomic = await _atomicClock.getAtomicTimestamp();

      // Create minimal user object for querying
      final now = DateTime.now();
      final user = UnifiedUser(
        id: userId,
        email: '$userId@temp.local', // Temporary email for querying
        createdAt: now,
        updatedAt: now,
      );

      final event = await _eventService.getEventById(eventId);
      if (event == null) {
        throw ArgumentError('Event not found: $eventId');
      }

      // Check if user has already attended this event
      final userEvents = await _eventService.getEventsByAttendee(user);
      if (userEvents.any((e) => e.id == eventId)) {
        // User has already attended, return high compatibility
        return UserEventPrediction(
          userId: userId,
          eventId: eventId,
          predictionScore: 1.0,
          quantumCompatibility: 1.0,
          knotStringPrediction: 1.0,
          fabricStability: 1.0,
          overlapScore: 1.0,
          behaviorSimilarity: 1.0,
          reasoning: 'User has already attended this event',
          tAtomic: tAtomic,
        );
      }

      // 1. Calculate event overlap score
      final overlapScore = await _calculateEventOverlap(event);

      // 2. Find similar users who attended the event
      final similarUsers = await _findSimilarUsers(user, event);

      // 3. Create hypothetical quantum state
      final quantumCompatibility = await _createHypotheticalQuantumState(
        user: user,
        event: event,
        similarUsers: similarUsers,
      );

      // 4. Calculate knot string prediction (future compatibility)
      final knotStringPrediction = await _calculateKnotStringPrediction(
        userId: userId,
        event: event,
        similarUsers: similarUsers,
      );

      // 5. Calculate fabric stability (if event has group/community)
      final fabricStability = await _calculateFabricStability(
        userId: userId,
        event: event,
      );

      // 6. Calculate behavior similarity
      final behaviorSimilarity = await _calculateBehaviorSimilarity(
        user: user,
        similarUsers: similarUsers,
      );

      // 7. Calculate final prediction score with enhanced formula
      // Formula: P = 0.35 * C_quantum + 0.25 * C_knot_string + 0.20 * C_fabric + 0.15 * overlap + 0.05 * behavior
      final predictionScore = 0.35 * quantumCompatibility +
          0.25 * knotStringPrediction +
          0.20 * fabricStability +
          0.15 * overlapScore +
          0.05 * behaviorSimilarity;

      developer.log(
        '✅ Enhanced prediction complete: score=${predictionScore.toStringAsFixed(4)}, '
        'quantum=${quantumCompatibility.toStringAsFixed(4)}, '
        'knot_string=${knotStringPrediction.toStringAsFixed(4)}, '
        'fabric=${fabricStability.toStringAsFixed(4)}, '
        'overlap=${overlapScore.toStringAsFixed(4)}, '
        'behavior=${behaviorSimilarity.toStringAsFixed(4)}',
        name: _logName,
      );

      return UserEventPrediction(
        userId: userId,
        eventId: eventId,
        predictionScore: predictionScore.clamp(0.0, 1.0),
        quantumCompatibility: quantumCompatibility,
        knotStringPrediction: knotStringPrediction,
        fabricStability: fabricStability,
        overlapScore: overlapScore,
        behaviorSimilarity: behaviorSimilarity,
        reasoning:
            'Based on quantum entanglement, knot string predictions, fabric stability, and similar users',
        tAtomic: tAtomic,
      );
    } catch (e, stackTrace) {
      developer.log(
        '❌ Error predicting compatibility: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }

  /// Calculate knot string prediction (future compatibility from string evolution)
  ///
  /// **Process:**
  /// 1. Get predicted future knots for user and similar users at event time
  /// 2. Calculate future compatibility trajectory
  /// 3. Use peak or target-time compatibility as prediction
  Future<double> _calculateKnotStringPrediction({
    required String userId,
    required ExpertiseEvent event,
    required List<SimilarUser> similarUsers,
  }) async {
    try {
      // Get agentId for user
      final agentId = await _agentIdService.getUserAgentId(userId);

      // Get predicted future knot for user at event time
      final futureKnot = await _stringService.predictFutureKnot(
        agentId,
        event.startTime,
      );

      if (futureKnot == null) {
        developer.log(
          '⚠️ Could not predict future knot for user, using current knot compatibility',
          name: _logName,
        );
        // Fallback: Use current knot if future prediction unavailable
        final currentKnot = await _knotStorage.loadKnot(agentId);
        if (currentKnot == null) {
          return 0.0;
        }
        // Calculate compatibility with similar users' knots
        return await _calculateKnotCompatibilityFromSimilarUsers(
          userKnot: currentKnot,
          similarUsers: similarUsers,
          eventTime: event.startTime,
        );
      }

      // Calculate compatibility trajectory with similar users
      var totalCompatibility = 0.0;
      var count = 0;

      for (final similarUser in similarUsers) {
        try {
          final similarAgentId =
              await _agentIdService.getUserAgentId(similarUser.userId);
          final similarFutureKnot = await _stringService.predictFutureKnot(
            similarAgentId,
            event.startTime,
          );

          if (similarFutureKnot != null) {
            // Calculate topological compatibility between knots
            final compatibility = _calculateTopologicalCompatibility(
              knotA: futureKnot,
              knotB: similarFutureKnot,
            );
            totalCompatibility += compatibility * similarUser.similarityWeight;
            count++;
          }
        } catch (e) {
          developer.log(
            'Error calculating knot compatibility for similar user ${similarUser.userId}: $e',
            name: _logName,
          );
          continue;
        }
      }

      if (count == 0) {
        return 0.0;
      }

      // Use future compatibility prediction service for trajectory
      if (similarUsers.isNotEmpty) {
        try {
          final similarAgentId =
              await _agentIdService.getUserAgentId(similarUsers.first.userId);
          final trajectory =
              await _futureCompatService.predictFutureCompatibility(
            userAId: agentId,
            userBId: similarAgentId,
            targetTime: event.startTime,
            predictionPoints: 5,
          );

          if (trajectory.isImproving &&
              trajectory.predictedCompatibility > 0.0) {
            // Use predicted future compatibility if improving
            return trajectory.predictedCompatibility;
          }
        } catch (e) {
          developer.log(
            'Error getting future compatibility trajectory: $e',
            name: _logName,
          );
        }
      }

      return (totalCompatibility / count).clamp(0.0, 1.0);
    } catch (e, stackTrace) {
      developer.log(
        'Error calculating knot string prediction: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      return 0.0;
    }
  }

  /// Calculate personalized fabric suitability prediction
  ///
  /// **4D Quantum Worldsheet Structure:**
  /// Ψ_A(σ_A, τ_A, φ, t) where:
  /// - σ_A = position along User A's knot string (evolution parameter)
  /// - τ_A = which fabric composition (which set of other users)
  /// - φ = fabric composition parameter (which combination of other users)
  /// - t = time (event time)
  ///
  /// **Process:**
  /// 1. Get User A's knot (current and predicted future at event time)
  /// 2. Get all potential attendees (confirmed + similar users)
  /// 3. For different fabric compositions, evaluate:
  ///    - Would User A's knot be better suited in this fabric?
  ///    - Quantum entanglement compatibility
  ///    - Knot compatibility (using quantum states)
  ///    - Global fabric stability
  /// 4. Return the best fabric suitability score
  ///
  /// **Personalized Perspective:**
  /// Each user is evaluated from their own perspective: "Would MY knot be better
  /// suited (more stable, more compatible) in a fabric that includes certain other knots?"
  Future<double> _calculateFabricStability({
    required String userId,
    required ExpertiseEvent event,
  }) async {
    return _calculatePersonalizedFabricSuitability(
      userId: userId,
      event: event,
    );
  }

  /// Calculate personalized fabric suitability from User A's perspective
  ///
  /// **Formula:**
  /// S_A(φ, t) = max_{φ} [α·C_quantum(A, F_φ) + β·C_knot(A, F_φ) + γ·S_global(F_φ)]
  ///
  /// Where:
  /// - S_A = Suitability score for User A
  /// - φ = Fabric composition (which combination of other users)
  /// - t = Event time
  /// - C_quantum = Quantum entanglement compatibility between User A and fabric F_φ
  /// - C_knot = Knot compatibility (topological + quantum)
  /// - S_global = Global fabric stability based on event characteristics
  Future<double> _calculatePersonalizedFabricSuitability({
    required String userId,
    required ExpertiseEvent event,
  }) async {
    try {
      developer.log(
        'Calculating personalized fabric suitability for user $userId at event ${event.id}',
        name: _logName,
      );

      // Get agentId for user
      final agentId = await _agentIdService.getUserAgentId(userId);

      // Get User A's knot (current and predicted future at event time)
      final userKnot = await _knotStorage.loadKnot(agentId);
      if (userKnot == null) {
        developer.log(
          '⚠️ User knot not found, using neutral score',
          name: _logName,
        );
        return 0.5;
      }

      // Get predicted future knot at event time (using knot evolution string)
      final futureKnot = await _stringService.predictFutureKnot(
        agentId,
        event.startTime,
      );
      final knotToUse = futureKnot ?? userKnot;

      // Get all potential attendees (confirmed attendees + similar users)
      final potentialAttendees = await _getPotentialAttendees(
        userId: userId,
        event: event,
      );

      if (potentialAttendees.isEmpty) {
        developer.log(
          'No potential attendees found, using neutral score',
          name: _logName,
        );
        return 0.5;
      }

      // Get User A's quantum state (for quantum entanglement calculations)
      final userPersonality =
          await _personalityLearning.getCurrentPersonality(userId);
      if (userPersonality == null) {
        return 0.5;
      }
      final tAtomic = await _atomicClock.getAtomicTimestamp();
      final userQuantumState = QuantumEntityState(
        entityId: userId,
        entityType: QuantumEntityType.user,
        personalityState: userPersonality.dimensions,
        quantumVibeAnalysis: userPersonality.dimensions,
        entityCharacteristics: {
          'archetype': userPersonality.archetype,
          'authenticity': userPersonality.authenticity,
        },
        tAtomic: tAtomic,
      );

      // Evaluate different fabric compositions
      // For performance, limit to top N similar users and confirmed attendees
      final topPotentialAttendees = potentialAttendees.take(8).toList();
      final maxCompositions = 5; // Limit combinations for performance

      var bestSuitability = 0.0;
      var evaluatedCompositions = 0;

      // Evaluate fabric compositions (combinations of other users)
      for (final composition in _generateFabricCompositions(
        potentialAttendees: topPotentialAttendees,
        maxCompositions: maxCompositions,
      )) {
        if (evaluatedCompositions >= maxCompositions) break;

        try {
          // Get knots for this fabric composition
          final compositionKnots = <PersonalityKnot>[];
          final compositionQuantumStates = <QuantumEntityState>[];

          for (final attendeeId in composition) {
            try {
              final attendeeAgentId =
                  await _agentIdService.getUserAgentId(attendeeId);
              final attendeeKnot = await _knotStorage.loadKnot(attendeeAgentId);
              if (attendeeKnot == null) continue;

              // Get predicted future knot at event time
              final attendeeFutureKnot = await _stringService.predictFutureKnot(
                attendeeAgentId,
                event.startTime,
              );
              final attendeeKnotToUse = attendeeFutureKnot ?? attendeeKnot;
              compositionKnots.add(attendeeKnotToUse);

              // Get quantum state for entanglement calculations
              final attendeePersonality =
                  await _personalityLearning.getCurrentPersonality(attendeeId);
              if (attendeePersonality != null) {
                compositionQuantumStates.add(QuantumEntityState(
                  entityId: attendeeId,
                  entityType: QuantumEntityType.user,
                  personalityState: attendeePersonality.dimensions,
                  quantumVibeAnalysis: attendeePersonality.dimensions,
                  entityCharacteristics: {
                    'archetype': attendeePersonality.archetype,
                    'authenticity': attendeePersonality.authenticity,
                  },
                  tAtomic: tAtomic,
                ));
              }
            } catch (e) {
              developer.log(
                'Error processing attendee $attendeeId: $e',
                name: _logName,
              );
              continue;
            }
          }

          if (compositionKnots.isEmpty) continue;

          // 1. Calculate quantum entanglement compatibility
          // C_quantum(A, F_φ) = F(|ψ_A⟩, |ψ_F_φ⟩)
          final fabricQuantumStates = [
            userQuantumState,
            ...compositionQuantumStates
          ];
          final fabricEntangledState =
              await _entanglementService.createEntangledState(
            entityStates: fabricQuantumStates,
          );
          final userEntangledState =
              await _entanglementService.createEntangledState(
            entityStates: [userQuantumState],
          );
          final quantumCompatibility =
              await _entanglementService.calculateFidelity(
            userEntangledState,
            fabricEntangledState,
          );

          // 2. Calculate knot compatibility (topological + quantum)
          // C_knot(A, F_φ) = knot_compatibility_bonus from quantum entanglement service
          final knotCompatibility =
              await _entanglementService.calculateKnotCompatibilityBonus(
            fabricQuantumStates,
          );

          // 3. Calculate global fabric stability
          // S_global(F_φ) = fabric stability based on event characteristics
          final fabric = await _fabricService.generateMultiStrandBraidFabric(
            userKnots: [knotToUse, ...compositionKnots],
          );
          final globalStability =
              await _fabricService.measureFabricStability(fabric);

          // 4. Calculate worldsheet evolution compatibility (NEW)
          // Predict how fabric will evolve over time using worldsheet
          double worldsheetEvolutionScore = 0.5; // Default: neutral
          try {
            final compositionAgentIds = <String>[];
            final userAgentId = await _agentIdService.getUserAgentId(userId);
            compositionAgentIds.add(userAgentId);
            for (final attendeeId in composition) {
              final attendeeAgentId =
                  await _agentIdService.getUserAgentId(attendeeId);
              compositionAgentIds.add(attendeeAgentId);
            }

            // Create worldsheet for this fabric composition
            final worldsheet = await _worldsheetService.createWorldsheet(
              groupId: '${event.id}_${composition.join('_')}',
              userIds: compositionAgentIds,
              startTime: event.startTime.subtract(const Duration(days: 30)),
              endTime: event.endTime.add(const Duration(days: 30)),
            );

            if (worldsheet != null) {
              // Get fabric at event time
              final fabricAtEventTime =
                  worldsheet.getFabricAtTime(event.startTime);
              if (fabricAtEventTime != null) {
                // Calculate fabric stability evolution
                final preEventFabric = worldsheet.getFabricAtTime(
                  event.startTime.subtract(const Duration(days: 1)),
                );
                final postEventFabric = worldsheet.getFabricAtTime(
                  event.endTime.add(const Duration(days: 1)),
                );

                if (preEventFabric != null && postEventFabric != null) {
                  final preStability =
                      await _fabricService.measureFabricStability(
                    preEventFabric,
                  );
                  final postStability =
                      await _fabricService.measureFabricStability(
                    postEventFabric,
                  );
                  // Evolution score: positive change = fabric improves = better suitability
                  final stabilityChange = postStability - preStability;
                  worldsheetEvolutionScore =
                      (0.5 + stabilityChange).clamp(0.0, 1.0);
                }
              }
            }
          } catch (e) {
            developer.log(
              'Error calculating worldsheet evolution: $e, using neutral score',
              name: _logName,
            );
          }

          // 5. Combined suitability score using hybrid approach
          // Core factors (geometric mean): quantum, knot, global stability
          // Modifiers (weighted average): worldsheet evolution

          final coreFactors = [
            quantumCompatibility.clamp(0.0, 1.0),
            knotCompatibility.clamp(0.0, 1.0),
            globalStability.clamp(0.0, 1.0),
          ];
          final coreSuitability = _geometricMean(coreFactors);

          // Modifiers: worldsheet evolution can enhance but not break
          final modifiers = worldsheetEvolutionScore.clamp(0.0, 1.0);

          // Final: core * (base + modifier_boost)
          final suitability = coreSuitability * (0.85 + 0.15 * modifiers);

          if (suitability > bestSuitability) {
            bestSuitability = suitability;
          }

          evaluatedCompositions++;
        } catch (e) {
          developer.log(
            'Error evaluating fabric composition: $e',
            name: _logName,
          );
          continue;
        }
      }

      developer.log(
        '✅ Personalized fabric suitability: ${bestSuitability.toStringAsFixed(4)} '
        '(evaluated $evaluatedCompositions compositions)',
        name: _logName,
      );

      return bestSuitability.clamp(0.0, 1.0);
    } catch (e, stackTrace) {
      developer.log(
        'Error calculating personalized fabric suitability: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      return 0.5; // Neutral on error
    }
  }

  /// Get all potential attendees (confirmed + similar users)
  Future<List<String>> _getPotentialAttendees({
    required String userId,
    required ExpertiseEvent event,
  }) async {
    final potentialAttendees = <String>{};

    // Add confirmed attendees
    potentialAttendees.addAll(event.attendeeIds);

    // Add similar users (who might attend)
    try {
      final now = DateTime.now();
      final user = UnifiedUser(
        id: userId,
        email: '$userId@temp.local',
        createdAt: now,
        updatedAt: now,
      );
      final similarUsers = await _findSimilarUsers(user, event);
      for (final similarUser in similarUsers) {
        potentialAttendees.add(similarUser.userId);
      }
    } catch (e) {
      developer.log(
        'Error finding similar users: $e',
        name: _logName,
      );
    }

    // Remove self
    potentialAttendees.remove(userId);

    return potentialAttendees.toList();
  }

  /// Generate fabric compositions (combinations of potential attendees)
  ///
  /// **Strategy:**
  /// - Include confirmed attendees in all compositions
  /// - Add similar users in different combinations
  /// - Limit combinations for performance
  Iterable<List<String>> _generateFabricCompositions({
    required List<String> potentialAttendees,
    required int maxCompositions,
  }) sync* {
    if (potentialAttendees.isEmpty) return;

    // Strategy: Generate compositions with increasing sizes
    // Start with smaller compositions (more focused), then larger ones
    final confirmedAttendees = potentialAttendees.take(3).toList();
    final similarUsers = potentialAttendees.skip(3).take(5).toList();

    var count = 0;

    // Composition 1: Just confirmed attendees
    if (confirmedAttendees.isNotEmpty && count < maxCompositions) {
      yield confirmedAttendees;
      count++;
    }

    // Compositions 2-N: Add similar users in different combinations
    for (var size = 1;
        size <= similarUsers.length && count < maxCompositions;
        size++) {
      for (var i = 0; i < similarUsers.length && count < maxCompositions; i++) {
        final composition = [
          ...confirmedAttendees,
          ...similarUsers.skip(i).take(size),
        ];
        if (composition.isNotEmpty) {
          yield composition;
          count++;
        }
      }
    }
  }

  /// Calculate knot compatibility from similar users
  Future<double> _calculateKnotCompatibilityFromSimilarUsers({
    required PersonalityKnot userKnot,
    required List<SimilarUser> similarUsers,
    required DateTime eventTime,
  }) async {
    try {
      var totalCompatibility = 0.0;
      var count = 0;

      for (final similarUser in similarUsers) {
        try {
          final similarAgentId =
              await _agentIdService.getUserAgentId(similarUser.userId);
          final similarKnot = await _knotStorage.loadKnot(similarAgentId);
          if (similarKnot != null) {
            final compatibility = _calculateTopologicalCompatibility(
              knotA: userKnot,
              knotB: similarKnot,
            );
            totalCompatibility += compatibility * similarUser.similarityWeight;
            count++;
          }
        } catch (e) {
          continue;
        }
      }

      return count > 0 ? (totalCompatibility / count).clamp(0.0, 1.0) : 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  /// Calculate topological compatibility between two knots
  ///
  /// **Formula:**
  /// Uses Jones polynomial similarity and other knot invariants
  double _calculateTopologicalCompatibility({
    required PersonalityKnot knotA,
    required PersonalityKnot knotB,
  }) {
    try {
      // Use knot invariants for compatibility
      final jonesA = knotA.invariants.jonesPolynomial;
      final jonesB = knotB.invariants.jonesPolynomial;

      // Calculate polynomial similarity (simplified)
      if (jonesA.isEmpty || jonesB.isEmpty) {
        return 0.5; // Neutral if no polynomial data
      }

      // Use crossing number similarity
      final crossingDiff =
          (knotA.invariants.crossingNumber - knotB.invariants.crossingNumber)
              .abs();
      final maxCrossings =
          knotA.invariants.crossingNumber + knotB.invariants.crossingNumber;
      final crossingSimilarity = maxCrossings > 0
          ? 1.0 - (crossingDiff / maxCrossings).clamp(0.0, 1.0)
          : 0.5;

      // Use writhe similarity
      final writheDiff =
          (knotA.invariants.writhe - knotB.invariants.writhe).abs();
      final writheSimilarity =
          writheDiff < 0.1 ? 1.0 : (1.0 - writheDiff.clamp(0.0, 1.0));

      // Combined compatibility
      return (0.6 * crossingSimilarity + 0.4 * writheSimilarity)
          .clamp(0.0, 1.0);
    } catch (e) {
      developer.log(
        'Error calculating topological compatibility: $e',
        name: _logName,
      );
      return 0.5; // Neutral on error
    }
  }

  /// Calculate event overlap score
  ///
  /// **Formula:**
  /// overlap(A, B) = |users_attended_both(A, B)| / |users_attended_either(A, B)|
  Future<double> _calculateEventOverlap(ExpertiseEvent targetEvent) async {
    try {
      // Get all events (simplified - would need proper query in production)
      // For now, get events from the same host and check overlap
      final now = DateTime.now();
      final host = UnifiedUser(
        id: targetEvent.host.id,
        email: '${targetEvent.host.id}@temp.local',
        createdAt: now,
        updatedAt: now,
      );
      final hostEvents = await _eventService.getEventsByHost(host);
      final allEventsList = <ExpertiseEvent>[];
      allEventsList.addAll(hostEvents);
      allEventsList.add(targetEvent); // Ensure target event is included

      // Find events with significant user overlap
      var maxOverlap = 0.0;
      for (final otherEvent in allEventsList) {
        if (otherEvent.id == targetEvent.id) continue;

        // Get attendees for both events
        final targetAttendees = targetEvent.attendeeIds.toSet();
        final otherAttendees = otherEvent.attendeeIds.toSet();

        if (targetAttendees.isEmpty && otherAttendees.isEmpty) continue;

        // Calculate overlap
        final bothAttended =
            targetAttendees.intersection(otherAttendees).length;
        final eitherAttended = targetAttendees.union(otherAttendees).length;

        if (eitherAttended > 0) {
          final overlap = bothAttended / eitherAttended;
          if (overlap > maxOverlap) {
            maxOverlap = overlap;
          }
        }
      }

      return maxOverlap.clamp(0.0, 1.0);
    } catch (e) {
      developer.log(
        'Error calculating event overlap: $e, using 0.0',
        name: _logName,
      );
      return 0.0;
    }
  }

  /// Find similar users who attended the target event
  ///
  /// **Criteria:**
  /// - Users who attended the target event
  /// - Users with similar behavior patterns to the target user
  /// - Weighted by location and timing preferences
  Future<List<SimilarUser>> _findSimilarUsers(
    UnifiedUser targetUser,
    ExpertiseEvent targetEvent,
  ) async {
    try {
      final similarUsers = <SimilarUser>[];

      // Get all users who attended the target event
      final eventAttendees = targetEvent.attendeeIds;
      if (eventAttendees.isEmpty) {
        return similarUsers;
      }

      // Get target user's attended events
      final targetUserEvents =
          await _eventService.getEventsByAttendee(targetUser);
      final targetEventIds = targetUserEvents.map((e) => e.id).toSet();

      // For each attendee, calculate similarity
      for (final attendeeId in eventAttendees) {
        if (attendeeId == targetUser.id) continue; // Skip self

        try {
          // Create minimal user object for querying
          final now = DateTime.now();
          final attendee = UnifiedUser(
            id: attendeeId,
            email: '$attendeeId@temp.local',
            createdAt: now,
            updatedAt: now,
          );

          // Get attendee's attended events
          final attendeeEvents =
              await _eventService.getEventsByAttendee(attendee);
          final attendeeEventIds = attendeeEvents.map((e) => e.id).toSet();

          // Calculate behavior pattern similarity (event overlap)
          final commonEvents =
              targetEventIds.intersection(attendeeEventIds).length;
          final totalEvents = targetEventIds.union(attendeeEventIds).length;
          final behaviorSimilarity =
              totalEvents > 0 ? commonEvents / totalEvents : 0.0;

          // Calculate location similarity (simplified - check if same locality)
          final locationSimilarity = _calculateLocationSimilarity(
            targetUser: targetUser,
            otherUser: attendee,
          );

          // Calculate timing similarity (simplified - check event timing patterns)
          final timingSimilarity = _calculateTimingSimilarity(
            targetEvents: targetUserEvents,
            otherEvents: attendeeEvents,
          );

          // Combined similarity weight
          // w_s = 0.4 * behavior + 0.35 * location + 0.25 * timing
          final similarityWeight = 0.4 * behaviorSimilarity +
              0.35 * locationSimilarity +
              0.25 * timingSimilarity;

          if (similarityWeight > 0.1) {
            // Only include users with meaningful similarity
            similarUsers.add(SimilarUser(
              userId: attendeeId,
              similarityWeight: similarityWeight,
              behaviorSimilarity: behaviorSimilarity,
              locationSimilarity: locationSimilarity,
              timingSimilarity: timingSimilarity,
            ));
          }
        } catch (e) {
          developer.log(
            'Error processing attendee $attendeeId: $e',
            name: _logName,
          );
          continue;
        }
      }

      // Sort by similarity weight (descending)
      similarUsers
          .sort((a, b) => b.similarityWeight.compareTo(a.similarityWeight));

      // Return top 10 similar users
      return similarUsers.take(10).toList();
    } catch (e, stackTrace) {
      developer.log(
        'Error finding similar users: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      return [];
    }
  }

  /// Create hypothetical quantum state
  ///
  /// **Formula:**
  /// |ψ_hypothetical_U_E(t_atomic)⟩ = Σ_{s∈S} w_s |ψ_s(t_atomic_s)⟩ ⊗ |ψ_E(t_atomic_E)⟩
  Future<double> _createHypotheticalQuantumState({
    required UnifiedUser user,
    required ExpertiseEvent event,
    required List<SimilarUser> similarUsers,
  }) async {
    try {
      if (similarUsers.isEmpty) {
        return 0.0;
      }

      // Get atomic timestamp
      final tAtomic = await _atomicClock.getAtomicTimestamp();

      // Get target user's quantum state
      final userPersonality =
          await _personalityLearning.getCurrentPersonality(user.id);
      if (userPersonality == null) {
        developer.log(
            'User personality not found for ${user.id}, using defaults',
            name: _logName);
        return 0.0;
      }
      final userState = QuantumEntityState(
        entityId: user.id,
        entityType: QuantumEntityType.user,
        personalityState: userPersonality.dimensions,
        quantumVibeAnalysis: userPersonality.dimensions,
        entityCharacteristics: {
          'archetype': userPersonality.archetype,
          'authenticity': userPersonality.authenticity,
          'engagement_level': 0.5, // Default
        },
        tAtomic: tAtomic,
      );

      // Get event's quantum state (simplified - would need event state creation)
      // For now, use a placeholder state
      final eventState = QuantumEntityState(
        entityId: event.id,
        entityType: QuantumEntityType.event,
        personalityState: {}, // Would need event personality
        quantumVibeAnalysis: {}, // Would need event vibe
        entityCharacteristics: {
          'category': event.category,
          'event_type': event.eventType,
          'host_id': event.host.id,
        },
        tAtomic: tAtomic,
      );

      // Create entangled states for each similar user
      final entangledStates = <EntangledQuantumState>[];
      final weights = <double>[];

      for (final similarUser in similarUsers) {
        try {
          final similarPersonality =
              await _personalityLearning.getCurrentPersonality(
            similarUser.userId,
          );
          if (similarPersonality == null) {
            developer.log(
                'Personality not found for ${similarUser.userId}, skipping',
                name: _logName);
            continue;
          }
          final similarState = QuantumEntityState(
            entityId: similarUser.userId,
            entityType: QuantumEntityType.user,
            personalityState: similarPersonality.dimensions,
            quantumVibeAnalysis: similarPersonality.dimensions,
            entityCharacteristics: {
              'archetype': similarPersonality.archetype,
              'authenticity': similarPersonality.authenticity,
              'engagement_level': 0.5,
            },
            tAtomic: tAtomic,
          );

          // Create entangled state: |ψ_similar⟩ ⊗ |ψ_event⟩
          final entangled = await _entanglementService.createEntangledState(
            entityStates: [similarState, eventState],
          );

          entangledStates.add(entangled);
          weights.add(similarUser.similarityWeight);
        } catch (e) {
          developer.log(
            'Error creating entangled state for similar user ${similarUser.userId}: $e',
            name: _logName,
          );
          continue;
        }
      }

      if (entangledStates.isEmpty) {
        return 0.0;
      }

      // Normalize weights: Σ w_s = 1
      final weightSum = weights.fold<double>(0.0, (sum, w) => sum + w);
      if (weightSum < 0.0001) {
        return 0.0;
      }
      final normalizedWeights = weights.map((w) => w / weightSum).toList();

      // Calculate hypothetical compatibility
      // C_hypothetical = 0.4 * F(ρ_hypothetical_user, ρ_target_event) +
      //                 0.35 * F(ρ_location_user, ρ_location_event) +
      //                 0.25 * F(ρ_timing_user, ρ_timing_event)
      var hypotheticalCompatibility = 0.0;

      // For simplicity, use weighted average of entangled state fidelities
      for (int i = 0; i < entangledStates.length; i++) {
        // Calculate fidelity between user state and entangled state
        final userEntangled = await _entanglementService.createEntangledState(
          entityStates: [userState, eventState],
        );
        final fidelity = await _entanglementService.calculateFidelity(
          userEntangled,
          entangledStates[i],
        );
        hypotheticalCompatibility += normalizedWeights[i] * fidelity;
      }

      return hypotheticalCompatibility.clamp(0.0, 1.0);
    } catch (e, stackTrace) {
      developer.log(
        'Error creating hypothetical quantum state: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      return 0.0;
    }
  }

  /// Calculate behavior similarity between target user and similar users
  Future<double> _calculateBehaviorSimilarity({
    required UnifiedUser user,
    required List<SimilarUser> similarUsers,
  }) async {
    if (similarUsers.isEmpty) {
      return 0.0;
    }

    // Average similarity weight of similar users
    final avgSimilarity = similarUsers.fold<double>(
          0.0,
          (sum, u) => sum + u.behaviorSimilarity,
        ) /
        similarUsers.length;

    return avgSimilarity.clamp(0.0, 1.0);
  }

  /// Calculate location similarity between two users
  double _calculateLocationSimilarity({
    required UnifiedUser targetUser,
    required UnifiedUser otherUser,
  }) {
    // Simplified: Check if users are in same location
    // In production, would use more sophisticated location matching
    final targetLocation = targetUser.location;
    final otherLocation = otherUser.location;

    if (targetLocation != null && otherLocation != null) {
      // Simple string comparison (in production, would parse and compare coordinates)
      return targetLocation == otherLocation
          ? 1.0
          : 0.3; // Same location = 1.0, different = 0.3
    }

    return 0.5; // Unknown location = neutral
  }

  /// Calculate timing similarity between two users' event patterns
  double _calculateTimingSimilarity({
    required List<ExpertiseEvent> targetEvents,
    required List<ExpertiseEvent> otherEvents,
  }) {
    if (targetEvents.isEmpty || otherEvents.isEmpty) {
      return 0.5; // Neutral if no events
    }

    // Calculate average time of day preference
    double targetAvgHour = 0.0;
    for (final event in targetEvents) {
      targetAvgHour += event.startTime.hour;
    }
    targetAvgHour /= targetEvents.length;

    double otherAvgHour = 0.0;
    for (final event in otherEvents) {
      otherAvgHour += event.startTime.hour;
    }
    otherAvgHour /= otherEvents.length;

    // Similarity based on hour difference (0-12 hours = 1.0, 12-24 hours = 0.0)
    final hourDiff = (targetAvgHour - otherAvgHour).abs();
    final normalizedDiff = hourDiff > 12 ? 24 - hourDiff : hourDiff;
    return 1.0 - (normalizedDiff / 12.0);
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
}

/// Similar user with similarity metrics
class SimilarUser {
  final String userId;
  final double similarityWeight;
  final double behaviorSimilarity;
  final double locationSimilarity;
  final double timingSimilarity;

  SimilarUser({
    required this.userId,
    required this.similarityWeight,
    required this.behaviorSimilarity,
    required this.locationSimilarity,
    required this.timingSimilarity,
  });
}

/// User-event prediction result
class UserEventPrediction {
  final String userId;
  final String eventId;
  final double predictionScore;
  final double quantumCompatibility;
  final double knotStringPrediction;
  final double fabricStability;
  final double overlapScore;
  final double behaviorSimilarity;
  final String reasoning;
  final AtomicTimestamp tAtomic;

  UserEventPrediction({
    required this.userId,
    required this.eventId,
    required this.predictionScore,
    required this.quantumCompatibility,
    required this.knotStringPrediction,
    required this.fabricStability,
    required this.overlapScore,
    required this.behaviorSimilarity,
    required this.reasoning,
    required this.tAtomic,
  });

  @override
  String toString() {
    return 'UserEventPrediction(userId: $userId, eventId: $eventId, '
        'score: ${predictionScore.toStringAsFixed(4)}, '
        'quantum: ${quantumCompatibility.toStringAsFixed(4)}, '
        'knot_string: ${knotStringPrediction.toStringAsFixed(4)}, '
        'fabric: ${fabricStability.toStringAsFixed(4)}, '
        'overlap: ${overlapScore.toStringAsFixed(4)}, '
        'behavior: ${behaviorSimilarity.toStringAsFixed(4)})';
  }
}
