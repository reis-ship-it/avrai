// Quantum Matching Controller
//
// Orchestrates multi-entity quantum matching workflow
// Part of Phase 19 Section 19.5: Quantum Matching Controller
// Patent #29: Multi-Entity Quantum Entanglement Matching System

import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:avrai_runtime_os/controllers/base/workflow_controller.dart';
import 'package:avrai_runtime_os/controllers/base/controller_result.dart';
import 'package:avrai_core/models/quantum/matching_result.dart';
import 'package:avrai_core/models/quantum/matching_input.dart';
import 'package:avrai_runtime_os/services/ledgers/ledger_audit_v0.dart';
import 'package:avrai_runtime_os/services/ledgers/ledger_domain_v0.dart';
import 'package:avrai_core/models/quantum_entity_state.dart';
import 'package:avrai_core/models/atomic_timestamp.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_quantum/services/quantum/quantum_entanglement_service.dart';
import 'package:avrai_quantum/services/quantum/location_timing_quantum_state_service.dart';
import 'package:avrai_knot/services/knot/integrated_knot_recommendation_engine.dart';
import 'package:avrai_knot/services/knot/cross_entity_compatibility_service.dart';
import 'package:avrai_runtime_os/ai/personality_learning.dart';
import 'package:avrai_runtime_os/ai/vibe_analysis_engine.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'package:avrai_runtime_os/services/matching/preferences_profile_service.dart';
import 'package:avrai_runtime_os/services/quantum/meaningful_connection_metrics_service.dart';
import 'package:avrai_runtime_os/services/quantum/quantum_matching_ai_learning_service.dart';
import 'package:avrai_runtime_os/services/network/enhanced_connectivity_service.dart';
import 'package:avrai_knot/services/knot/knot_evolution_string_service.dart';
import 'package:avrai_knot/services/knot/knot_fabric_service.dart';
import 'package:avrai_knot/services/knot/knot_worldsheet_service.dart';
import 'package:avrai_runtime_os/services/security/hybrid_encryption_service.dart';
import 'package:avrai_runtime_os/ai2ai/anonymous_communication.dart';
import 'package:avrai_core/models/user/unified_user.dart';
import 'package:avrai_core/models/expertise/expertise_event.dart';
import 'package:avrai_core/models/spots/spot.dart';
import 'package:avrai_core/models/business/business_account.dart';
import 'package:avrai_core/models/quantum_entity_type.dart';
import 'package:avrai_core/models/unified_location_data.dart';
import 'package:geocoding/geocoding.dart' as geocoding;

/// Result class for quantum matching controller
class QuantumMatchingResult extends ControllerResult {
  /// Matching result (null if error)
  final MatchingResult? matchingResult;

  const QuantumMatchingResult({
    required super.success,
    super.error,
    super.errorCode,
    super.metadata,
    this.matchingResult,
  });

  /// Create successful result
  factory QuantumMatchingResult.success({
    required MatchingResult matchingResult,
    Map<String, dynamic>? metadata,
  }) {
    return QuantumMatchingResult(
      success: true,
      matchingResult: matchingResult,
      metadata: metadata,
    );
  }

  /// Create failure result
  factory QuantumMatchingResult.failure({
    required String error,
    String? errorCode,
    Map<String, dynamic>? metadata,
  }) {
    return QuantumMatchingResult(
      success: false,
      error: error,
      errorCode: errorCode,
      metadata: metadata,
    );
  }

  @override
  List<Object?> get props =>
      [success, error, errorCode, metadata, matchingResult];
}

/// Quantum Matching Controller
///
/// Orchestrates the complete multi-entity quantum matching workflow:
/// 1. Convert entities to quantum states
/// 2. Calculate N-way entanglement
/// 3. Apply location/timing factors
/// 4. Calculate knot compatibility (optional)
/// 5. Calculate meaningful connection metrics (optional)
/// 6. Apply privacy protection
/// 7. Return unified matching results
///
/// **Architecture Pattern:**
/// ```
/// UI → BLoC → QuantumMatchingController → Multiple Services → Repository
/// ```
class QuantumMatchingController
    implements WorkflowController<MatchingInput, QuantumMatchingResult> {
  static const String _logName = 'QuantumMatchingController';

  final AtomicClockService _atomicClock;
  final QuantumEntanglementService _entanglementService;
  final LocationTimingQuantumStateService _locationTimingService;
  // TODO(Phase 19.7): Use QuantumVibeEngine for enhanced vibe compilation
  // final QuantumVibeEngine? _quantumVibeEngine;
  final PersonalityLearning _personalityLearning;
  final UserVibeAnalyzer _vibeAnalyzer;
  final AgentIdService _agentIdService;
  final PreferencesProfileService? _preferencesProfileService;
  final IntegratedKnotRecommendationEngine? _knotEngine;
  final CrossEntityCompatibilityService? _knotCompatibilityService;
  final MeaningfulConnectionMetricsService? _meaningfulConnectionMetricsService;
  // TODO(Phase 19.4): Use RealTimeUserCallingService for user calling integration
  // final RealTimeUserCallingService? _userCallingService;
  // Phase 19.16: AI2AI Integration
  final QuantumMatchingAILearningService? _aiLearningService;
  final EnhancedConnectivityService? _connectivityService;
  // Phase 19 Integration Enhancement: String/Fabric/Worldsheet + Signal Protocol
  final KnotEvolutionStringService? _stringService;
  final KnotFabricService? _fabricService;
  final KnotWorldsheetService? _worldsheetService;
  // Reserved for future use: encrypting matching results when transmitting via AI2AI mesh
  // ignore: unused_field
  final HybridEncryptionService? _encryptionService;
  // Reserved for future use: transmitting matching results via AI2AI mesh
  // ignore: unused_field
  final AnonymousCommunicationProtocol? _ai2aiProtocol;

  QuantumMatchingController({
    required AtomicClockService atomicClock,
    required QuantumEntanglementService entanglementService,
    required LocationTimingQuantumStateService locationTimingService,
    required PersonalityLearning personalityLearning,
    required UserVibeAnalyzer vibeAnalyzer,
    required AgentIdService agentIdService,
    PreferencesProfileService? preferencesProfileService,
    IntegratedKnotRecommendationEngine? knotEngine,
    CrossEntityCompatibilityService? knotCompatibilityService,
    MeaningfulConnectionMetricsService? meaningfulConnectionMetricsService,
    QuantumMatchingAILearningService? aiLearningService,
    EnhancedConnectivityService? connectivityService,
    KnotEvolutionStringService? stringService,
    KnotFabricService? fabricService,
    KnotWorldsheetService? worldsheetService,
    HybridEncryptionService? encryptionService,
    AnonymousCommunicationProtocol? ai2aiProtocol,
  })  : _atomicClock = atomicClock,
        _entanglementService = entanglementService,
        _locationTimingService = locationTimingService,
        _personalityLearning = personalityLearning,
        _vibeAnalyzer = vibeAnalyzer,
        _agentIdService = agentIdService,
        _preferencesProfileService = preferencesProfileService,
        _knotEngine = knotEngine,
        _knotCompatibilityService = knotCompatibilityService,
        _meaningfulConnectionMetricsService =
            meaningfulConnectionMetricsService,
        _aiLearningService = aiLearningService,
        _connectivityService = connectivityService,
        _stringService = stringService,
        _fabricService = fabricService,
        _worldsheetService = worldsheetService,
        _encryptionService = encryptionService,
        _ai2aiProtocol = ai2aiProtocol;

  @override
  Future<QuantumMatchingResult> execute(MatchingInput input) async {
    try {
      developer.log(
        '🎯 Starting multi-entity quantum matching for user ${input.user.id}',
        name: _logName,
      );

      // Validate input
      final validation = validate(input);
      if (!validation.isValid) {
        await LedgerAuditV0.tryAppend(
          domain: LedgerDomainV0.expertise,
          eventType: 'quantum_matching_failed',
          occurredAt: DateTime.now(),
          entityType: 'user',
          entityId: input.user.id,
          payload: <String, Object?>{
            'schema_version': 0,
            'error_code': 'VALIDATION_ERROR',
            'error': validation.firstError ?? 'Invalid input',
            'validation_errors': validation.allErrors,
          },
        );
        return QuantumMatchingResult.failure(
          error: validation.firstError ?? 'Invalid input',
          errorCode: 'VALIDATION_ERROR',
          metadata: {'validationErrors': validation.allErrors},
        );
      }

      // STEP 1: Get atomic timestamp for matching operation
      final tAtomic = await _atomicClock.getAtomicTimestamp();

      // STEP 2: Check connectivity and use offline matching if offline
      final isOffline = _connectivityService != null &&
          !(await _connectivityService.hasInternetAccess());

      if (isOffline && _aiLearningService != null) {
        // Convert entities to quantum states for offline matching
        final quantumStates = await _convertEntitiesToQuantumStates(
          input.user,
          input.allEntities,
          tAtomic,
        );

        if (quantumStates.isNotEmpty) {
          // Try offline matching using cached quantum states
          final offlineResult = await _aiLearningService.performOfflineMatching(
            userId: input.user.id,
            entities: quantumStates,
          );

          if (offlineResult != null) {
            developer.log(
              '✅ Offline quantum matching complete: compatibility=${offlineResult.compatibility.toStringAsFixed(3)}',
              name: _logName,
            );

            // Learn from offline match (will be queued for sync)
            unawaited(_aiLearningService.learnFromSuccessfulMatch(
              userId: input.user.id,
              matchingResult: offlineResult,
              event: input.event,
              isOffline: true,
            ));

            return QuantumMatchingResult.success(
              matchingResult: offlineResult,
              metadata: {'offline': true},
            );
          }
        }
      }

      // STEP 3: Convert entities to quantum states (for online matching)
      final quantumStates = await _convertEntitiesToQuantumStates(
        input.user,
        input.allEntities,
        tAtomic,
      );

      if (quantumStates.isEmpty) {
        await LedgerAuditV0.tryAppend(
          domain: LedgerDomainV0.expertise,
          eventType: 'quantum_matching_failed',
          occurredAt: tAtomic.serverTime,
          entityType: 'user',
          entityId: input.user.id,
          payload: <String, Object?>{
            'schema_version': 0,
            'atomic_timestamp_id': tAtomic.timestampId,
            'error_code': 'QUANTUM_STATE_CONVERSION_ERROR',
            'error': 'Failed to convert entities to quantum states',
          },
        );
        return QuantumMatchingResult.failure(
          error: 'Failed to convert entities to quantum states',
          errorCode: 'QUANTUM_STATE_CONVERSION_ERROR',
        );
      }

      // STEP 3: Calculate N-way entanglement
      final entangledState = await _entanglementService.createEntangledState(
        entityStates: quantumStates,
      );

      // STEP 4: Calculate quantum compatibility from entangled state
      // Based on Patent #29: Multi-Entity Quantum Entanglement Matching
      // Formula: F(|ψ_entangled⟩, |ψ_user⟩) = |⟨ψ_entangled_projected|ψ_user⟩|²
      // The entangled state lives in a tensor-product space, so we project it
      // to the user's dimension and calculate quantum fidelity.
      final userState = quantumStates.firstWhere(
        (s) => s.entityType == QuantumEntityType.user,
      );
      final quantumFidelity = _calculateQuantumFidelityFromEntangledState(
        entangledState: entangledState,
        userState: userState,
        allStates: quantumStates,
      );

      // STEP 5: Apply location/timing factors
      final locationTimingFactors = await _calculateLocationTimingFactors(
        userState,
        quantumStates,
      );

      // STEP 6: Calculate knot compatibility (optional)
      double? knotCompatibility;
      if (_knotCompatibilityService != null && _knotEngine != null) {
        try {
          knotCompatibility = await _calculateKnotCompatibility(
            userState,
            quantumStates,
          );
        } catch (e) {
          developer.log(
            'Error calculating knot compatibility: $e, continuing without it',
            name: _logName,
          );
        }
      }

      // STEP 7: Calculate meaningful connection metrics (optional, Section 19.7)
      double? meaningfulConnectionScore;
      if (_meaningfulConnectionMetricsService != null) {
        try {
          // For matching, we use a predictive meaningful connection score
          // based on the matching compatibility (since event hasn't happened yet)
          // The actual meaningful connection metrics are calculated after events occur
          meaningfulConnectionScore = await _calculatePredictiveMeaningfulScore(
            userState: userState,
            quantumStates: quantumStates,
            tAtomic: tAtomic,
          );
        } catch (e) {
          developer.log(
            'Error calculating meaningful connection score: $e, continuing without it',
            name: _logName,
          );
        }
      }

      // STEP 8: Combine all compatibility factors
      final combinedCompatibility = _combineCompatibilityFactors(
        quantumFidelity: quantumFidelity,
        locationCompatibility: locationTimingFactors.locationCompatibility,
        timingCompatibility: locationTimingFactors.timingCompatibility,
        knotCompatibility: knotCompatibility,
      );

      // STEP 9: Apply privacy protection (agentId-only for third-party data)
      final agentId = await _agentIdService.getUserAgentId(input.user.id);

      // STEP 10: Create unified matching result
      final matchingResult = MatchingResult.success(
        compatibility: combinedCompatibility,
        quantumCompatibility: quantumFidelity,
        knotCompatibility: knotCompatibility,
        locationCompatibility: locationTimingFactors.locationCompatibility,
        timingCompatibility: locationTimingFactors.timingCompatibility,
        meaningfulConnectionScore: meaningfulConnectionScore,
        timestamp: tAtomic,
        entities: quantumStates,
        metadata: {
          'agentId': agentId, // Privacy-protected identifier
          'entityCount': quantumStates.length,
          'hasKnotCompatibility': knotCompatibility != null,
          'hasMeaningfulMetrics': meaningfulConnectionScore != null,
        },
      );

      await LedgerAuditV0.tryAppend(
        domain: LedgerDomainV0.expertise,
        eventType: 'quantum_matching_executed',
        occurredAt: tAtomic.serverTime,
        entityType: 'user',
        entityId: input.user.id,
        payload: <String, Object?>{
          'schema_version': 0,
          'atomic_timestamp_id': tAtomic.timestampId,
          'entity_count': quantumStates.length,
          'compatibility': combinedCompatibility,
          'quantum_compatibility': quantumFidelity,
          'location_compatibility': locationTimingFactors.locationCompatibility,
          'timing_compatibility': locationTimingFactors.timingCompatibility,
          if (knotCompatibility != null)
            'knot_compatibility': knotCompatibility,
          if (meaningfulConnectionScore != null)
            'meaningful_connection_score': meaningfulConnectionScore,
        },
      );

      developer.log(
        '✅ Multi-entity quantum matching complete: compatibility=${combinedCompatibility.toStringAsFixed(3)}',
        name: _logName,
      );

      // Phase 19.16: Learn from successful match (fire-and-forget)
      if (_aiLearningService != null && combinedCompatibility >= 0.5) {
        // Only learn from matches with reasonable compatibility (>= 0.5)
        unawaited(_aiLearningService.learnFromSuccessfulMatch(
          userId: input.user.id,
          matchingResult: matchingResult,
          event: input.event,
          isOffline: false, // Controller assumes online matching
        ));
      }

      return QuantumMatchingResult.success(
        matchingResult: matchingResult,
        metadata: {
          'executionTime':
              DateTime.now().difference(tAtomic.serverTime).inMilliseconds,
        },
      );
    } catch (e, stackTrace) {
      await LedgerAuditV0.tryAppend(
        domain: LedgerDomainV0.expertise,
        eventType: 'quantum_matching_failed',
        occurredAt: DateTime.now(),
        entityType: 'user',
        entityId: input.user.id,
        payload: <String, Object?>{
          'schema_version': 0,
          'error_code': 'MATCHING_ERROR',
          'error': e.toString(),
        },
      );
      developer.log(
        '❌ Error in multi-entity quantum matching: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );

      return QuantumMatchingResult.failure(
        error: 'Matching failed: ${e.toString()}',
        errorCode: 'MATCHING_ERROR',
        metadata: {
          'errorType': e.runtimeType.toString(),
          'stackTrace': stackTrace.toString(),
        },
      );
    }
  }

  @override
  Future<void> rollback(QuantumMatchingResult result) async {
    // No rollback needed - matching is read-only
  }

  @override
  ValidationResult validate(MatchingInput input) {
    final errors = <String>[];

    // Validate user
    if (input.user.id.isEmpty) {
      errors.add('User ID is required');
    }

    // Validate at least one entity
    if (!input.isValid) {
      errors
          .add('At least one entity (event, spot, business, etc.) is required');
    }

    if (errors.isNotEmpty) {
      return ValidationResult.invalid(generalErrors: errors);
    }

    return ValidationResult.valid();
  }

  /// Convert entities to quantum states
  Future<List<QuantumEntityState>> _convertEntitiesToQuantumStates(
    UnifiedUser user,
    List<dynamic> entities,
    AtomicTimestamp tAtomic,
  ) async {
    final quantumStates = <QuantumEntityState>[];

    try {
      // Convert user to quantum state
      final userState = await _convertUserToQuantumState(user, tAtomic);
      quantumStates.add(userState);

      // Convert other entities to quantum states
      for (final entity in entities) {
        try {
          QuantumEntityState? entityState;
          if (entity is ExpertiseEvent) {
            entityState = await _convertEventToQuantumState(entity, tAtomic);
          } else if (entity is Spot) {
            entityState = await _convertSpotToQuantumState(entity, tAtomic);
          } else if (entity is BusinessAccount) {
            entityState = await _convertBusinessToQuantumState(entity, tAtomic);
          }

          if (entityState != null) {
            quantumStates.add(entityState);
          }
        } catch (e) {
          developer.log(
            'Error converting entity to quantum state: $e',
            name: _logName,
          );
          // Continue with other entities
        }
      }
    } catch (e) {
      developer.log(
        'Error converting entities to quantum states: $e',
        name: _logName,
      );
    }

    return quantumStates;
  }

  /// Convert user to quantum state
  Future<QuantumEntityState> _convertUserToQuantumState(
    UnifiedUser user,
    AtomicTimestamp tAtomic,
  ) async {
    // Get personality profile
    final personalityProfile =
        await _personalityLearning.getCurrentPersonality(user.id);
    final personalityDimensions = personalityProfile?.dimensions ?? {};

    // Get quantum vibe analysis
    final quantumVibeAnalysis = <String, double>{};
    if (personalityProfile != null) {
      final userVibe =
          await _vibeAnalyzer.compileUserVibe(user.id, personalityProfile);
      quantumVibeAnalysis.addAll(userVibe.anonymizedDimensions);
    }

    // Get location quantum state (if available)
    EntityLocationQuantumState? locationState;
    if (user.location != null) {
      try {
        // Parse location string to UnifiedLocation
        final unifiedLocation = await _parseLocationString(user.location!);
        if (unifiedLocation != null) {
          locationState =
              await _locationTimingService.createLocationQuantumState(
            location: unifiedLocation,
          );
        }
      } catch (e) {
        developer.log('Error parsing user location: $e', name: _logName);
      }
    }

    // Get timing quantum state from preferences
    EntityTimingQuantumState? timingState;
    try {
      final agentId = await _agentIdService.getUserAgentId(user.id);
      final preferencesProfile =
          await _preferencesProfileService?.getPreferencesProfile(agentId);

      if (preferencesProfile != null) {
        final explorationWillingness =
            preferencesProfile.explorationWillingness;
        final timeOfDayPreference = 0.3 + (explorationWillingness * 0.4);
        final timeOfDayHour = (timeOfDayPreference * 24).round().clamp(0, 23);
        final dayOfWeekPreference = 0.3 + (explorationWillingness * 0.4);
        final dayOfWeek = (dayOfWeekPreference * 7).round().clamp(0, 6);
        final frequencyPreference = 0.4 + (explorationWillingness * 0.3);
        final durationPreference = 0.5 + (explorationWillingness * 0.2);

        timingState =
            await _locationTimingService.createTimingQuantumStateFromIntuitive(
          timeOfDayHour: timeOfDayHour,
          dayOfWeek: dayOfWeek,
          frequencyPreference: frequencyPreference,
          durationPreference: durationPreference,
        );
      } else {
        // Default timing preferences
        timingState =
            await _locationTimingService.createTimingQuantumStateFromIntuitive(
          timeOfDayHour: 19,
          dayOfWeek: 6,
          frequencyPreference: 0.5,
          durationPreference: 0.5,
        );
      }
    } catch (e) {
      developer.log('Error getting user timing preferences: $e',
          name: _logName);
    }

    return QuantumEntityState(
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
  }

  /// Convert event to quantum state
  Future<QuantumEntityState> _convertEventToQuantumState(
    ExpertiseEvent event,
    AtomicTimestamp tAtomic,
  ) async {
    // Get event host personality (if available)
    final hostPersonality =
        await _personalityLearning.getCurrentPersonality(event.host.id);
    final personalityDimensions = hostPersonality?.dimensions ?? {};

    // Get quantum vibe for event (from host or event characteristics)
    final quantumVibeAnalysis = <String, double>{};
    if (hostPersonality != null) {
      final hostVibe =
          await _vibeAnalyzer.compileUserVibe(event.host.id, hostPersonality);
      quantumVibeAnalysis.addAll(hostVibe.anonymizedDimensions);
    }

    // Get location quantum state
    EntityLocationQuantumState? locationState;
    if (event.location != null) {
      try {
        final unifiedLocation = await _parseLocationString(event.location!);
        if (unifiedLocation != null) {
          locationState =
              await _locationTimingService.createLocationQuantumState(
            location: unifiedLocation,
          );
        }
      } catch (e) {
        developer.log('Error parsing event location: $e', name: _logName);
      }
    }

    // Get timing quantum state from event DateTime
    EntityTimingQuantumState? timingState;
    try {
      timingState =
          await _locationTimingService.createTimingQuantumStateFromDateTime(
        preferredTime: event.startTime,
        frequencyPreference: 0.5, // Default frequency
        durationPreference: 0.5, // Default duration
      );
    } catch (e) {
      developer.log('Error creating event timing state: $e', name: _logName);
    }

    return QuantumEntityState(
      entityId: event.id,
      entityType: QuantumEntityType.event,
      personalityState: personalityDimensions,
      quantumVibeAnalysis: quantumVibeAnalysis,
      entityCharacteristics: {
        'type': 'event',
        'category': event.category,
        'eventType': event.eventType.name,
        'hostId': event.host.id,
        'title': event.title,
      },
      location: locationState,
      timing: timingState,
      tAtomic: tAtomic,
    );
  }

  /// Convert spot to quantum state
  Future<QuantumEntityState> _convertSpotToQuantumState(
    Spot spot,
    AtomicTimestamp tAtomic,
  ) async {
    // Get spot vibe (if available)
    final quantumVibeAnalysis = <String, double>{};

    // Get location quantum state
    EntityLocationQuantumState? locationState;
    try {
      final unifiedLocation = UnifiedLocationData(
        latitude: spot.latitude,
        longitude: spot.longitude,
        city: spot.address ?? spot.name,
        timestamp: DateTime.now(),
      );
      locationState = await _locationTimingService.createLocationQuantumState(
        location: unifiedLocation,
      );
    } catch (e) {
      developer.log('Error creating spot location state: $e', name: _logName);
    }

    return QuantumEntityState(
      entityId: spot.id,
      entityType: QuantumEntityType.business, // Spots are business entities
      personalityState: {},
      quantumVibeAnalysis: quantumVibeAnalysis,
      entityCharacteristics: {
        'type': 'spot',
        'name': spot.name,
        'category': spot.category,
      },
      location: locationState,
      timing: null, // Spots don't have timing
      tAtomic: tAtomic,
    );
  }

  /// Convert business to quantum state
  Future<QuantumEntityState> _convertBusinessToQuantumState(
    BusinessAccount business,
    AtomicTimestamp tAtomic,
  ) async {
    // Get business vibe (if available)
    final quantumVibeAnalysis = <String, double>{};

    // Get location quantum state
    EntityLocationQuantumState? locationState;
    if (business.location != null) {
      try {
        final unifiedLocation = await _parseLocationString(business.location!);
        if (unifiedLocation != null) {
          locationState =
              await _locationTimingService.createLocationQuantumState(
            location: unifiedLocation,
          );
        }
      } catch (e) {
        developer.log('Error creating business location state: $e',
            name: _logName);
      }
    }

    return QuantumEntityState(
      entityId: business.id,
      entityType: QuantumEntityType.business,
      personalityState: {},
      quantumVibeAnalysis: quantumVibeAnalysis,
      entityCharacteristics: {
        'type': 'business',
        'name': business.name,
        'businessType': business.businessType,
      },
      location: locationState,
      timing: null, // Businesses don't have timing
      tAtomic: tAtomic,
    );
  }

  /// Calculate location and timing compatibility factors
  Future<LocationTimingFactors> _calculateLocationTimingFactors(
    QuantumEntityState userState,
    List<QuantumEntityState> entities,
  ) async {
    double locationCompatibility = 0.0;
    double timingCompatibility = 0.0;

    if (userState.location != null) {
      // Find event location from entities
      for (final entity in entities) {
        if (entity.entityType == QuantumEntityType.event &&
            entity.location != null) {
          locationCompatibility =
              LocationCompatibilityCalculator.calculateLocationCompatibility(
            userState.location!,
            entity.location!,
          );
          break;
        }
      }
    }

    if (userState.timing != null) {
      // Find event timing from entities
      for (final entity in entities) {
        if (entity.entityType == QuantumEntityType.event &&
            entity.timing != null) {
          timingCompatibility =
              TimingCompatibilityCalculator.calculateTimingCompatibility(
            userState.timing!,
            entity.timing!,
          );
          break;
        }
      }
    }

    return LocationTimingFactors(
      locationCompatibility: locationCompatibility,
      timingCompatibility: timingCompatibility,
    );
  }

  /// Calculate knot compatibility (enhanced with string/fabric/worldsheet)
  ///
  /// **Enhanced Formula (with String/Fabric Integration):**
  /// C_knot = hybrid_combination(
  ///   C_knot_base,           // Base knot compatibility (via entanglement service)
  ///   C_string_evolution,    // String evolution predictions (if available)
  ///   C_fabric_stability,    // Fabric stability (if 3+ entities)
  ///   C_worldsheet_evolution // Worldsheet evolution (if available)
  /// )
  ///
  /// **Process:**
  /// 1. Use entanglement service's calculateKnotCompatibilityBonus (includes string/fabric integration)
  /// 2. If string service available and event time available, enhance with string evolution
  /// 3. If fabric service available and 3+ entities, enhance with fabric stability
  /// 4. If worldsheet service available, enhance with worldsheet evolution predictions
  Future<double?> _calculateKnotCompatibility(
    QuantumEntityState userState,
    List<QuantumEntityState> entities,
  ) async {
    if (_knotCompatibilityService == null && _knotEngine == null) {
      return null;
    }

    try {
      // Get event start time from entities (for string evolution predictions)
      DateTime? eventStartTime;
      for (final entity in entities) {
        if (entity.entityType == QuantumEntityType.event &&
            entity.timing != null) {
          // Extract event time from timing quantum state if available
          // For now, use current time as placeholder (timing state doesn't expose DateTime directly)
          eventStartTime = DateTime.now();
          break;
        }
      }

      // Use entanglement service's calculateKnotCompatibilityBonus which includes
      // string/fabric/worldsheet integration when available
      final knotBonus =
          await _entanglementService.calculateKnotCompatibilityBonus(
        entities,
        targetTime: eventStartTime,
      );

      // If string/fabric/worldsheet services are available, further enhance
      if (_stringService != null ||
          _fabricService != null ||
          _worldsheetService != null) {
        // Additional enhancements can be added here if needed
        // The entanglement service already handles string/fabric integration
        // This is a placeholder for future enhancements specific to the controller
      }

      return knotBonus.clamp(0.0, 1.0);
    } catch (e) {
      developer.log('Error calculating knot compatibility: $e', name: _logName);
      return null;
    }
  }

  /// Calculate vibe similarity between two quantum vibe analyses
  double _calculateVibeSimilarity(
    Map<String, double> vibeA,
    Map<String, double> vibeB,
  ) {
    if (vibeA.isEmpty || vibeB.isEmpty) {
      return 0.0;
    }

    // Calculate cosine similarity
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

    final similarity = dotProduct / (math.sqrt(normA) * math.sqrt(normB));
    return similarity.clamp(0.0, 1.0);
  }

  List<double> _quantumEntityStateToVector(QuantumEntityState state) {
    final vector = <double>[];

    // Use sorted keys for stable ordering across entities.
    final personalityKeys = state.personalityState.keys.toList()..sort();
    for (final k in personalityKeys) {
      vector.add(state.personalityState[k] ?? 0.0);
    }

    final vibeKeys = state.quantumVibeAnalysis.keys.toList()..sort();
    for (final k in vibeKeys) {
      vector.add(state.quantumVibeAnalysis[k] ?? 0.0);
    }

    if (state.location != null) {
      vector.add(state.location!.latitudeQuantumState);
      vector.add(state.location!.longitudeQuantumState);
      vector.add(state.location!.accessibilityScore);
      vector.add(state.location!.vibeLocationMatch);
    }

    if (state.timing != null) {
      vector.add(state.timing!.timeOfDayPreference);
      vector.add(state.timing!.dayOfWeekPreference);
      vector.add(state.timing!.frequencyPreference);
      vector.add(state.timing!.durationPreference);
      vector.add(state.timing!.timingVibeMatch);
    }

    return vector;
  }

  double _cosineSimilarity(List<double> a, List<double> b) {
    final maxLen = math.max(a.length, b.length);
    if (maxLen == 0) return 0.5;

    var dot = 0.0;
    var normA = 0.0;
    var normB = 0.0;
    for (var i = 0; i < maxLen; i++) {
      final av = i < a.length ? a[i] : 0.0;
      final bv = i < b.length ? b[i] : 0.0;
      dot += av * bv;
      normA += av * av;
      normB += bv * bv;
    }

    if (normA == 0.0 || normB == 0.0) {
      return 0.5;
    }

    final sim = dot / (math.sqrt(normA) * math.sqrt(normB));
    if (sim.isNaN || sim.isInfinite) return 0.5;
    return sim.clamp(0.0, 1.0);
  }

  /// Calculate quantum fidelity from entangled state
  ///
  /// Based on Patent #29: Multi-Entity Quantum Entanglement Matching
  /// Formula: F(|ψ_entangled⟩, |ψ_user⟩) = |⟨ψ_entangled_projected|ψ_user⟩|²
  ///
  /// **Approach:**
  /// 1. Project high-dimensional entangled state to user's dimension
  /// 2. Calculate quantum inner product: ⟨ψ_entangled_projected|ψ_user⟩
  /// 3. Quantum fidelity: |inner_product|²
  ///
  /// **Fallback:**
  /// If projection fails or dimensions don't match, falls back to
  /// weighted average using entanglement coefficients.
  double _calculateQuantumFidelityFromEntangledState({
    required EntangledQuantumState entangledState,
    required QuantumEntityState userState,
    required List<QuantumEntityState> allStates,
  }) {
    try {
      final userVector = _quantumEntityStateToVector(userState);
      final userDimension = userVector.length;
      final entangledVector = entangledState.entangledVector;
      final entangledDimension = entangledVector.length;

      // Case 1: Same dimension - direct inner product
      if (entangledDimension == userDimension) {
        var innerProduct = 0.0;
        for (var i = 0; i < userDimension; i++) {
          innerProduct += entangledVector[i] * userVector[i];
        }
        // Quantum fidelity: |⟨ψ_entangled|ψ_user⟩|²
        final fidelity = (innerProduct * innerProduct).abs();
        developer.log(
          'Quantum fidelity (direct): ${fidelity.toStringAsFixed(4)}',
          name: _logName,
        );
        return fidelity.clamp(0.0, 1.0);
      }

      // Case 2: Entangled state is higher dimension - project to user dimension
      if (entangledDimension > userDimension) {
        // Project by reshaping and averaging chunks (patent experiment method)
        if (entangledDimension % userDimension == 0) {
          // Perfect division: reshape and average
          final chunks = entangledDimension ~/ userDimension;
          final projected = List<double>.filled(userDimension, 0.0);

          for (var chunk = 0; chunk < chunks; chunk++) {
            for (var i = 0; i < userDimension; i++) {
              final idx = chunk * userDimension + i;
              projected[i] += entangledVector[idx];
            }
          }

          // Average
          for (var i = 0; i < userDimension; i++) {
            projected[i] /= chunks;
          }

          // Normalize projection
          final norm = math.sqrt(
            projected.fold<double>(0.0, (sum, v) => sum + v * v),
          );
          if (norm > 0.0001) {
            for (var i = 0; i < userDimension; i++) {
              projected[i] /= norm;
            }
          }

          // Calculate inner product: ⟨ψ_entangled_projected|ψ_user⟩
          var innerProduct = 0.0;
          for (var i = 0; i < userDimension; i++) {
            innerProduct += projected[i] * userVector[i];
          }

          // Quantum fidelity: |⟨ψ_entangled_projected|ψ_user⟩|²
          final fidelity = (innerProduct * innerProduct).abs();
          developer.log(
            'Quantum fidelity (projected, chunks=$chunks): ${fidelity.toStringAsFixed(4)}',
            name: _logName,
          );
          return fidelity.clamp(0.0, 1.0);
        } else {
          // Not perfect division: take first userDimension elements and normalize
          final projected = entangledVector.sublist(0, userDimension);
          final norm = math.sqrt(
            projected.fold<double>(0.0, (sum, v) => sum + v * v),
          );

          if (norm > 0.0001) {
            for (var i = 0; i < userDimension; i++) {
              projected[i] /= norm;
            }
          }

          // Calculate inner product
          var innerProduct = 0.0;
          for (var i = 0; i < userDimension; i++) {
            innerProduct += projected[i] * userVector[i];
          }

          // Quantum fidelity: |⟨ψ_entangled_projected|ψ_user⟩|²
          final fidelity = (innerProduct * innerProduct).abs();
          developer.log(
            'Quantum fidelity (projected, first N): ${fidelity.toStringAsFixed(4)}',
            name: _logName,
          );
          return fidelity.clamp(0.0, 1.0);
        }
      }

      // Case 3: Entangled state is lower dimension - pad or use coefficient-weighted fallback
      // This shouldn't happen in normal operation, but handle gracefully
      developer.log(
        '⚠️ Entangled dimension ($entangledDimension) < user dimension ($userDimension), using coefficient-weighted fallback',
        name: _logName,
      );
      return _calculateCoefficientWeightedFidelity(
        entangledState: entangledState,
        userState: userState,
        allStates: allStates,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error calculating quantum fidelity from entangled state: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      // Fallback to original method
      return _calculateUserToTargetsFidelity(
        userState: userState,
        allStates: allStates,
      );
    }
  }

  /// Calculate fidelity using entanglement coefficients as weights
  ///
  /// Fallback method when direct projection isn't possible.
  /// Uses entanglement coefficients to weight entity compatibility.
  double _calculateCoefficientWeightedFidelity({
    required EntangledQuantumState entangledState,
    required QuantumEntityState userState,
    required List<QuantumEntityState> allStates,
  }) {
    final userIndex = allStates.indexOf(userState);
    if (userIndex < 0) {
      return _calculateUserToTargetsFidelity(
        userState: userState,
        allStates: allStates,
      );
    }

    final userVector = _quantumEntityStateToVector(userState);
    double totalWeightedCompatibility = 0.0;
    double totalWeight = 0.0;

    for (var i = 0; i < allStates.length; i++) {
      if (i != userIndex && allStates[i].entityType != QuantumEntityType.user) {
        // Coefficient squared = probability/strength of entanglement
        final coefficient = i < entangledState.coefficients.length
            ? entangledState.coefficients[i]
            : 1.0 / allStates.length;
        final weight = coefficient * coefficient;

        // Calculate state similarity
        final targetVector = _quantumEntityStateToVector(allStates[i]);
        final similarity = _cosineSimilarity(userVector, targetVector);

        // Weighted combination: entanglement strength × state similarity
        totalWeightedCompatibility += weight * similarity;
        totalWeight += weight;
      }
    }

    if (totalWeight > 0.0001) {
      final fidelity =
          (totalWeightedCompatibility / totalWeight).clamp(0.0, 1.0);
      developer.log(
        'Quantum fidelity (coefficient-weighted): ${fidelity.toStringAsFixed(4)}',
        name: _logName,
      );
      return fidelity;
    }

    // Final fallback
    return _calculateUserToTargetsFidelity(
      userState: userState,
      allStates: allStates,
    );
  }

  double _calculateUserToTargetsFidelity({
    required QuantumEntityState userState,
    required List<QuantumEntityState> allStates,
  }) {
    final userVector = _quantumEntityStateToVector(userState);
    var total = 0.0;
    var count = 0;

    for (final state in allStates) {
      if (identical(state, userState) ||
          state.entityType == QuantumEntityType.user) {
        continue;
      }
      final targetVector = _quantumEntityStateToVector(state);
      total += _cosineSimilarity(userVector, targetVector);
      count++;
    }

    if (count == 0) {
      // Should not happen (input validation requires at least one entity),
      // but keep a neutral fallback.
      return 0.5;
    }
    return (total / count).clamp(0.0, 1.0);
  }

  /// Combine all compatibility factors using hybrid approach
  ///
  /// **Hybrid Approach:**
  /// - Core factors (quantum, knot): Geometric mean (catches critical failures)
  /// - Modifiers (location, timing): Weighted average (enhance good matches)
  /// - Final: core * modifiers (multiplicative combination)
  double _combineCompatibilityFactors({
    required double quantumFidelity,
    required double locationCompatibility,
    required double timingCompatibility,
    double? knotCompatibility,
  }) {
    // Core factors: quantum (critical) and knot (if available)
    final coreFactors = <double>[quantumFidelity];
    if (knotCompatibility != null) {
      coreFactors.add(knotCompatibility);
    }
    final coreScore = _geometricMean(coreFactors);

    // Modifiers: location and timing (enhance good matches)
    final modifierScore =
        0.6 * locationCompatibility + 0.4 * timingCompatibility;

    // Hybrid combination: core * modifiers
    final compatibility = coreScore * modifierScore;

    return compatibility.clamp(0.0, 1.0);
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

  /// Calculate predictive meaningful connection score
  ///
  /// For matching (before event occurs), we predict meaningful connection score
  /// based on matching compatibility. The actual meaningful connection metrics
  /// are calculated after events occur using MeaningfulConnectionMetricsService.
  Future<double> _calculatePredictiveMeaningfulScore({
    required QuantumEntityState userState,
    required List<QuantumEntityState> quantumStates,
    required AtomicTimestamp tAtomic,
  }) async {
    try {
      // Use matching compatibility as a proxy for predictive meaningful connection score
      // Higher compatibility = higher likelihood of meaningful connection
      // This is a simplified prediction - actual metrics require post-event data

      // Hybrid approach: Core factors (geometric mean) + Modifiers (weighted average)

      // 1. Core factors: Quantum entanglement compatibility (critical)
      final quantumFidelity = _calculateUserToTargetsFidelity(
        userState: userState,
        allStates: quantumStates,
      );

      // 2. Vibe alignment (core factor - critical for meaningful connection)
      double totalVibeSimilarity = 0.0;
      int entityCount = 0;
      for (final entityState in quantumStates) {
        final similarity = _calculateVibeSimilarity(
          userState.quantumVibeAnalysis,
          entityState.quantumVibeAnalysis,
        );
        totalVibeSimilarity += similarity;
        entityCount++;
      }
      final vibeAlignment =
          entityCount > 0 ? totalVibeSimilarity / entityCount : 0.0;

      // Core factors: geometric mean (catches critical failures)
      final coreFactors = [quantumFidelity, vibeAlignment];
      final coreScore = _geometricMean(coreFactors);

      // 3. Modifiers: Location/timing compatibility (enhance good matches)
      double locationTimingCompat = 0.0;
      if (userState.location != null) {
        final eventLocation = _findEventLocation(quantumStates);
        if (eventLocation != null) {
          locationTimingCompat += 0.5; // Location match
        }
      }
      if (userState.timing != null) {
        final eventTiming = _findEventTiming(quantumStates);
        if (eventTiming != null) {
          locationTimingCompat += 0.5; // Timing match
        }
      }

      // 4. Interest alignment (modifier)
      final interestAlignment = _calculateInterestAlignment(
        userState,
        quantumStates,
      );

      // Modifiers: weighted average (enhance good matches)
      final modifierScore =
          0.7 * locationTimingCompat + 0.3 * interestAlignment;

      // Hybrid combination: core * modifiers
      final compatibility = coreScore * modifierScore;

      // Predictive meaningful connection score = compatibility
      return compatibility.clamp(0.0, 1.0);
    } catch (e) {
      developer.log(
        'Error calculating predictive meaningful score: $e',
        name: _logName,
      );
      return 0.0;
    }
  }

  /// Find event location from quantum states
  EntityLocationQuantumState? _findEventLocation(
      List<QuantumEntityState> quantumStates) {
    for (final state in quantumStates) {
      if (state.location != null) {
        return state.location;
      }
    }
    return null;
  }

  /// Find event timing from quantum states
  EntityTimingQuantumState? _findEventTiming(
      List<QuantumEntityState> quantumStates) {
    for (final state in quantumStates) {
      if (state.timing != null) {
        return state.timing;
      }
    }
    return null;
  }

  /// Calculate interest alignment between user and entities
  double _calculateInterestAlignment(
    QuantumEntityState userState,
    List<QuantumEntityState> quantumStates,
  ) {
    // Extract user interests from entity characteristics
    final userInterests =
        userState.entityCharacteristics['interests'] as List<String>? ?? [];
    if (userInterests.isEmpty) {
      return 0.5; // Default moderate alignment
    }

    // Extract entity categories
    final entityCategories = <String>{};
    for (final state in quantumStates) {
      final category = state.entityCharacteristics['category'] as String?;
      if (category != null) {
        entityCategories.add(category);
      }
    }

    if (entityCategories.isEmpty) {
      return 0.5; // Default moderate alignment
    }

    // Calculate overlap
    final matchingInterests = userInterests
        .where((interest) => entityCategories.contains(interest))
        .length;
    final alignment = matchingInterests /
        math.max(userInterests.length, entityCategories.length);

    return alignment.clamp(0.0, 1.0);
  }

  /// Parse location string to UnifiedLocationData
  Future<UnifiedLocationData?> _parseLocationString(
      String locationString) async {
    try {
      // Use geocoding to parse location string
      final placemarks = await geocoding.locationFromAddress(locationString);
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        return UnifiedLocationData(
          latitude: placemark.latitude,
          longitude: placemark.longitude,
          city: locationString,
          timestamp: DateTime.now(),
        );
      }
    } catch (e) {
      developer.log('Error geocoding location string "$locationString": $e',
          name: _logName);
    }

    return null;
  }
}

/// Location and timing compatibility factors
class LocationTimingFactors {
  final double locationCompatibility;
  final double timingCompatibility;

  const LocationTimingFactors({
    required this.locationCompatibility,
    required this.timingCompatibility,
  });
}
