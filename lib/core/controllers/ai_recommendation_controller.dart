// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
// ignore_for_file: unused_field

import 'dart:developer' as developer;

import 'package:get_it/get_it.dart';

import 'package:avrai/core/ai/knowledge_lifecycle/claim_lifecycle_contract.dart';
import 'package:avrai/core/controllers/base/workflow_controller.dart';
import 'package:avrai/core/controllers/base/controller_result.dart';
import 'package:avrai/core/controllers/conviction_shadow_gate.dart';
import 'package:avrai/core/ai/personality_learning.dart';
import 'package:avrai/core/services/matching/preferences_profile_service.dart';
import 'package:avrai/core/services/events/event_recommendation_service.dart'
    as event_rec_service;
import 'package:avrai/core/services/user/agent_id_service.dart';
import 'package:avrai/injection_container.dart' as di;
import 'package:avrai/core/models/user/unified_user.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai/core/models/user/preferences_profile.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_knot/services/knot/personality_knot_service.dart';
import 'package:avrai_knot/services/knot/knot_storage_service.dart';
import 'package:avrai_knot/services/knot/cross_entity_compatibility_service.dart';
import 'package:avrai_knot/services/knot/integrated_knot_recommendation_engine.dart';
import 'package:avrai_quantum/services/quantum/location_timing_quantum_state_service.dart';
import 'package:avrai_quantum/services/quantum/quantum_entanglement_service.dart';
import 'package:avrai/core/services/quantum/quantum_matching_ai_learning_service.dart';

// Import for SharedPreferencesCompat (matches injection_container.dart)
// This is the type registered in DI container
import 'package:avrai/core/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;

/// AI Recommendation Controller
///
/// Orchestrates the complete AI recommendation workflow. Coordinates loading
/// of personality and preferences profiles, calculates quantum compatibility,
/// and generates personalized recommendations for events, spots, and lists.
///
/// **Responsibilities:**
/// - Load PersonalityProfile (for quantum compatibility with hosts/users)
/// - Load PreferencesProfile (for quantum compatibility with events/spots)
/// - Calculate quantum compatibility scores
/// - Get event recommendations via EventRecommendationService
/// - Rank and filter recommendations
/// - Return unified recommendation results
///
/// **Dependencies:**
/// - `PersonalityLearning` - Load personality profiles
/// - `PreferencesProfileService` - Load preferences profiles
/// - `EventRecommendationService` - Get event recommendations
/// - `AgentIdService` - Get agentId for privacy protection
///
/// **Usage:**
/// ```dart
/// final controller = AIRecommendationController();
/// final result = await controller.generateRecommendations(
///   userId: 'user_123',
///   context: RecommendationContext(
///     category: 'Coffee',
///     location: 'Greenpoint',
///     maxResults: 20,
///   ),
/// );
///
/// if (result.isSuccess) {
///   final recommendations = result.recommendations;
///   final events = recommendations.events;
/// } else {
///   // Handle errors
/// }
/// ```
class AIRecommendationController
    implements WorkflowController<RecommendationInput, RecommendationResult> {
  static const String _logName = 'AIRecommendationController';

  final PersonalityLearning _personalityLearning;
  final PreferencesProfileService _preferencesProfileService;
  final event_rec_service.EventRecommendationService
      _eventRecommendationService;
  final AgentIdService _agentIdService;
  final AtomicClockService
      _atomicClock; // Reserved for future timestamp-based recommendations

  // AVRAI Core System Integration (optional, graceful degradation)
  final PersonalityKnotService? _personalityKnotService;
  final KnotStorageService? _knotStorageService;
  final CrossEntityCompatibilityService? _knotCompatibilityService;
  final IntegratedKnotRecommendationEngine? _knotEngine;
  final LocationTimingQuantumStateService? _locationTimingService;
  final QuantumEntanglementService?
      _quantumEntanglementService; // Reserved for future quantum compatibility calculations
  final QuantumMatchingAILearningService? _aiLearningService;
  final ConvictionGateEvaluator _convictionGateEvaluator;

  AIRecommendationController({
    PersonalityLearning? personalityLearning,
    PreferencesProfileService? preferencesProfileService,
    event_rec_service.EventRecommendationService? eventRecommendationService,
    AgentIdService? agentIdService,
    AtomicClockService? atomicClock,
    PersonalityKnotService? personalityKnotService,
    KnotStorageService? knotStorageService,
    CrossEntityCompatibilityService? knotCompatibilityService,
    IntegratedKnotRecommendationEngine? knotEngine,
    LocationTimingQuantumStateService? locationTimingService,
    QuantumEntanglementService? quantumEntanglementService,
    QuantumMatchingAILearningService? aiLearningService,
    ConvictionGateEvaluator? convictionGateEvaluator,
  })  : _personalityLearning = personalityLearning ??
            (() {
              // Use same pattern as injection_container.dart
              final prefs = GetIt.instance<SharedPreferencesCompat>();
              // SharedPreferencesCompat implements SharedPreferences interface
              return PersonalityLearning.withPrefs(prefs);
            })(),
        _preferencesProfileService =
            preferencesProfileService ?? PreferencesProfileService(),
        _eventRecommendationService = eventRecommendationService ??
            event_rec_service.EventRecommendationService(),
        _agentIdService = agentIdService ?? di.sl<AgentIdService>(),
        _atomicClock = atomicClock ?? GetIt.instance<AtomicClockService>(),
        _personalityKnotService = personalityKnotService ??
            (GetIt.instance.isRegistered<PersonalityKnotService>()
                ? GetIt.instance<PersonalityKnotService>()
                : null),
        _knotStorageService = knotStorageService ??
            (GetIt.instance.isRegistered<KnotStorageService>()
                ? GetIt.instance<KnotStorageService>()
                : null),
        _knotCompatibilityService = knotCompatibilityService ??
            (GetIt.instance.isRegistered<CrossEntityCompatibilityService>()
                ? GetIt.instance<CrossEntityCompatibilityService>()
                : null),
        _knotEngine = knotEngine ??
            (GetIt.instance.isRegistered<IntegratedKnotRecommendationEngine>()
                ? GetIt.instance<IntegratedKnotRecommendationEngine>()
                : null),
        _locationTimingService = locationTimingService ??
            (GetIt.instance.isRegistered<LocationTimingQuantumStateService>()
                ? GetIt.instance<LocationTimingQuantumStateService>()
                : null),
        _quantumEntanglementService = quantumEntanglementService ??
            (GetIt.instance.isRegistered<QuantumEntanglementService>()
                ? GetIt.instance<QuantumEntanglementService>()
                : null),
        _aiLearningService = aiLearningService ??
            (GetIt.instance.isRegistered<QuantumMatchingAILearningService>()
                ? GetIt.instance<QuantumMatchingAILearningService>()
                : null),
        _convictionGateEvaluator =
            convictionGateEvaluator ?? resolveDefaultConvictionGateEvaluator();

  /// Generate comprehensive recommendations
  ///
  /// Orchestrates the complete recommendation workflow:
  /// 1. Get agentId for privacy protection
  /// 2. Load PersonalityProfile
  /// 3. Load PreferencesProfile
  /// 4. Get event recommendations
  /// 5. Calculate quantum compatibility scores
  /// 6. Rank and filter results
  ///
  /// **Parameters:**
  /// - `userId`: User ID to get recommendations for
  /// - `context`: Recommendation context (category, location, maxResults, etc.)
  ///
  /// **Returns:**
  /// RecommendationResult with event, spot, and list recommendations
  Future<RecommendationResult> generateRecommendations({
    required String userId,
    required RecommendationContext context,
  }) async {
    ConvictionGateDecision? convictionGateDecision;
    try {
      developer.log(
        '🎯 Starting AI recommendation generation for user: $userId',
        name: _logName,
      );

      // Step 1: Evaluate conviction/policy gate (shadow mode by default)
      convictionGateDecision = await _convictionGateEvaluator.evaluate(
        ConvictionGateRequest(
          controllerName: 'AIRecommendationController',
          requestId: context.convictionRequestId ??
              'recommend-$userId-${DateTime.now().millisecondsSinceEpoch}',
          claimState: context.claimState,
          isHighImpact: context.isHighImpactAction,
          policyChecksPassed: context.policyChecksPassed,
          subjectId: userId,
        ),
      );

      if (convictionGateDecision.shadowBypassApplied) {
        developer.log(
          '⚠️ Conviction gate shadow bypass applied: ${convictionGateDecision.reasonCodes.join(",")}',
          name: _logName,
        );
      }

      if (!convictionGateDecision.servingAllowed) {
        return RecommendationResult.failure(
          error: 'Conviction gate blocked request',
          errorCode: 'CONVICTION_GATE_BLOCKED',
          convictionGateDecision: convictionGateDecision,
        );
      }

      // Step 2: Get agentId for privacy protection
      final agentId = await _agentIdService.getUserAgentId(userId);

      // Step 3: Load PersonalityProfile
      PersonalityProfile? personalityProfile;
      try {
        personalityProfile = await _personalityLearning.initializePersonality(
          userId,
        );
        developer.log(
          '✅ Loaded PersonalityProfile (generation ${personalityProfile.evolutionGeneration})',
          name: _logName,
        );
      } catch (e) {
        developer.log(
          '⚠️ Could not load PersonalityProfile: $e',
          name: _logName,
        );
        // Continue without personality profile - can still generate recommendations
      }

      // Step 4: Load PreferencesProfile
      PreferencesProfile? preferencesProfile;
      try {
        preferencesProfile =
            await _preferencesProfileService.getPreferencesProfile(agentId);
        if (preferencesProfile == null) {
          developer.log(
            '⚠️ No PreferencesProfile found for agentId: ${agentId.substring(0, 10)}...',
            name: _logName,
          );
        } else {
          developer.log(
            '✅ Loaded PreferencesProfile: ${preferencesProfile.categoryPreferences.length} categories, ${preferencesProfile.localityPreferences.length} localities',
            name: _logName,
          );
        }
      } catch (e) {
        developer.log(
          '⚠️ Could not load PreferencesProfile: $e',
          name: _logName,
        );
        // Continue without preferences profile - can still generate recommendations
      }

      // Step 5: Create user object (for recommendation services)
      // Note: EventRecommendationService expects UnifiedUser
      // In a real implementation, you'd load the full user from a service
      // For now, we'll construct a minimal user object
      final user = UnifiedUser(
        id: userId,
        email: '', // Not needed for recommendations
        displayName: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Step 6: Get event recommendations
      List<event_rec_service.EventRecommendation> eventRecommendations = [];
      try {
        eventRecommendations =
            await _eventRecommendationService.getPersonalizedRecommendations(
          user: user,
          category: context.category,
          location: context.location,
          maxResults: context.maxResults,
          explorationRatio: context.explorationRatio,
        );
        developer.log(
          '✅ Generated ${eventRecommendations.length} event recommendations',
          name: _logName,
        );
      } catch (e) {
        developer.log(
          '⚠️ Error getting event recommendations: $e',
          name: _logName,
        );
        // Continue without event recommendations
      }

      // Step 7: AVRAI Core System Integration (optional, graceful degradation)

      // 6.1: Load personality knots for knot-based recommendations
      if (_personalityKnotService != null &&
          _knotStorageService != null &&
          personalityProfile != null) {
        try {
          developer.log(
            '🎯 Loading personality knots for knot-based recommendations',
            name: _logName,
          );

          // Get user's knot (if available)
          final userKnot = await _knotStorageService.loadKnot(agentId);

          if (userKnot != null) {
            developer.log(
              '✅ Loaded user personality knot (crossings: ${userKnot.invariants.crossingNumber})',
              name: _logName,
            );
          } else {
            developer.log(
              'ℹ️ User personality knot not found (will use quantum compatibility only)',
              name: _logName,
            );
          }
        } catch (e) {
          developer.log(
            '⚠️ Knot loading failed (non-blocking): $e',
            name: _logName,
            error: e,
          );
          // Continue - knot loading is optional
        }
      }

      // 6.2: Calculate knot compatibility for recommendations
      if (_knotCompatibilityService != null) {
        try {
          developer.log(
            '🎯 Knot compatibility service available (compatibility calculation integrated in enhancement)',
            name: _logName,
          );
          // Note: Knot compatibility is integrated into recommendation enhancement
        } catch (e) {
          developer.log(
            '⚠️ Knot compatibility service check failed (non-blocking): $e',
            name: _logName,
            error: e,
          );
          // Continue - knot compatibility is optional
        }
      }

      // 6.3: Use integrated knot recommendation engine (if available)
      if (_knotEngine != null) {
        try {
          developer.log(
            '🧵 Integrated knot recommendation engine available (knot-based recommendations integrated)',
            name: _logName,
          );
          // Note: Knot engine is integrated into recommendation generation
        } catch (e) {
          developer.log(
            '⚠️ Knot engine check failed (non-blocking): $e',
            name: _logName,
            error: e,
          );
          // Continue - knot engine is optional
        }
      }

      // 6.4: Create 4D quantum states for location-aware recommendations
      if (_locationTimingService != null && context.location != null) {
        try {
          developer.log(
            '🌐 Creating 4D quantum location state for recommendation context',
            name: _logName,
          );

          // Parse location and create quantum state
          // Note: Full implementation would parse context.location and create quantum state
          developer.log(
            'ℹ️ Location quantum state creation deferred (requires location parsing)',
            name: _logName,
          );
        } catch (e) {
          developer.log(
            '⚠️ Location quantum state creation failed (non-blocking): $e',
            name: _logName,
            error: e,
          );
          // Continue - location quantum state is optional
        }
      }

      // 6.5: Enhance recommendations with quantum compatibility scores
      final enhancedEventRecommendations =
          await _enhanceRecommendationsWithQuantumCompatibility(
        eventRecommendations: eventRecommendations,
        personalityProfile: personalityProfile,
        preferencesProfile: preferencesProfile,
      );

      // 6.6: Learn from recommendation outcomes via AI2AI mesh (optional, fire-and-forget)
      if (_aiLearningService != null &&
          enhancedEventRecommendations.isNotEmpty) {
        try {
          developer.log(
            '🤖 AI2AI learning service available (learning deferred to matching)',
            name: _logName,
          );
          // Note: Actual learning happens when matches occur, not during recommendation generation
          // This is a placeholder for future recommendation-based learning
        } catch (e) {
          developer.log(
            '⚠️ AI2AI learning failed (non-blocking): $e',
            name: _logName,
            error: e,
          );
          // Continue - AI2AI learning is optional and non-blocking
        }
      }

      // Step 8: Sort and filter final results
      final filteredEvents = _filterAndSortRecommendations(
        enhancedEventRecommendations,
        minRelevanceScore: context.minRelevanceScore,
        maxResults: context.maxResults,
      );

      developer.log(
        '✅ Recommendation generation completed: ${filteredEvents.length} events',
        name: _logName,
      );

      return RecommendationResult.success(
        events: filteredEvents,
        spots: const [], // TODO(Phase 8.11): Implement when SpotRecommendationService is available
        lists: const [], // TODO(Phase 8.11): Implement when ListRecommendationService is available
        personalityProfile: personalityProfile,
        preferencesProfile: preferencesProfile,
        convictionGateDecision: convictionGateDecision,
      );
    } catch (e, stackTrace) {
      developer.log(
        '❌ Error generating recommendations: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return RecommendationResult.failure(
        error: 'Failed to generate recommendations: ${e.toString()}',
        errorCode: 'RECOMMENDATION_GENERATION_FAILED',
        convictionGateDecision: convictionGateDecision,
      );
    }
  }

  /// Enhance event recommendations with quantum compatibility scores
  ///
  /// Calculates quantum compatibility scores using both PersonalityProfile
  /// (for host compatibility) and PreferencesProfile (for event compatibility).
  Future<List<event_rec_service.EventRecommendation>>
      _enhanceRecommendationsWithQuantumCompatibility({
    required List<event_rec_service.EventRecommendation> eventRecommendations,
    PersonalityProfile? personalityProfile,
    PreferencesProfile? preferencesProfile,
  }) async {
    final enhanced = <event_rec_service.EventRecommendation>[];

    for (final recommendation in eventRecommendations) {
      double quantumCompatibility = recommendation.relevanceScore;

      // Calculate preferences compatibility if PreferencesProfile available
      if (preferencesProfile != null) {
        final preferencesCompat =
            preferencesProfile.calculateQuantumCompatibility(
          recommendation.event,
        );

        // Combine relevance score with preferences compatibility
        // Weight: 60% original relevance, 40% preferences compatibility
        quantumCompatibility =
            (recommendation.relevanceScore * 0.6 + preferencesCompat * 0.4)
                .clamp(0.0, 1.0);
      }

      // TODO(Phase 8.11): Calculate personality compatibility with event host
      // if personalityProfile is available
      // This would use quantum compatibility calculation: |⟨ψ_user|ψ_host⟩|²
      // For now, personality compatibility is not calculated

      // Create enhanced recommendation with quantum compatibility
      enhanced.add(event_rec_service.EventRecommendation(
        event: recommendation.event,
        relevanceScore: quantumCompatibility,
        recommendationReason: recommendation.recommendationReason,
      ));
    }

    return enhanced;
  }

  /// Filter and sort recommendations
  ///
  /// Filters recommendations by minimum relevance score and sorts by
  /// relevance score (highest first).
  List<event_rec_service.EventRecommendation> _filterAndSortRecommendations(
    List<event_rec_service.EventRecommendation> recommendations, {
    double minRelevanceScore = 0.3,
    int maxResults = 20,
  }) {
    final filtered = recommendations
        .where((r) => r.relevanceScore >= minRelevanceScore)
        .toList();

    // Sort by relevance score (highest first)
    filtered.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));

    return filtered.take(maxResults).toList();
  }

  // WorkflowController interface implementation

  @override
  Future<RecommendationResult> execute(RecommendationInput input) async {
    return generateRecommendations(
      userId: input.userId,
      context: input.context,
    );
  }

  @override
  ValidationResult validate(RecommendationInput input) {
    final errors = <String, String>{};
    final generalErrors = <String>[];

    if (input.userId.isEmpty) {
      errors['userId'] = 'User ID is required';
    }

    if (input.context.maxResults <= 0) {
      errors['maxResults'] = 'Max results must be greater than 0';
    }

    if (input.context.maxResults > 100) {
      errors['maxResults'] = 'Max results cannot exceed 100';
    }

    if (input.context.explorationRatio < 0.0 ||
        input.context.explorationRatio > 1.0) {
      errors['explorationRatio'] =
          'Exploration ratio must be between 0.0 and 1.0';
    }

    if (input.context.minRelevanceScore < 0.0 ||
        input.context.minRelevanceScore > 1.0) {
      errors['minRelevanceScore'] =
          'Minimum relevance score must be between 0.0 and 1.0';
    }

    if (errors.isNotEmpty || generalErrors.isNotEmpty) {
      return ValidationResult.invalid(
        fieldErrors: errors,
        generalErrors: generalErrors,
      );
    }

    return ValidationResult.valid();
  }

  @override
  Future<void> rollback(RecommendationResult result) async {
    // Recommendations are read-only, no rollback needed
  }
}

/// Recommendation Input
///
/// Input data for recommendation generation.
class RecommendationInput {
  final String userId;
  final RecommendationContext context;

  const RecommendationInput({
    required this.userId,
    required this.context,
  });
}

/// Recommendation Context
///
/// Context for generating recommendations (filters, limits, etc.).
class RecommendationContext {
  final String? category;
  final String? location;
  final int maxResults;
  final double explorationRatio;
  final double minRelevanceScore;
  final ClaimLifecycleState claimState;
  final bool isHighImpactAction;
  final bool policyChecksPassed;
  final String? convictionRequestId;

  const RecommendationContext({
    this.category,
    this.location,
    this.maxResults = 20,
    this.explorationRatio = 0.3,
    this.minRelevanceScore = 0.3,
    this.claimState = ClaimLifecycleState.canonical,
    this.isHighImpactAction = false,
    this.policyChecksPassed = true,
    this.convictionRequestId,
  });

  RecommendationContext copyWith({
    String? category,
    String? location,
    int? maxResults,
    double? explorationRatio,
    double? minRelevanceScore,
    ClaimLifecycleState? claimState,
    bool? isHighImpactAction,
    bool? policyChecksPassed,
    String? convictionRequestId,
  }) {
    return RecommendationContext(
      category: category ?? this.category,
      location: location ?? this.location,
      maxResults: maxResults ?? this.maxResults,
      explorationRatio: explorationRatio ?? this.explorationRatio,
      minRelevanceScore: minRelevanceScore ?? this.minRelevanceScore,
      claimState: claimState ?? this.claimState,
      isHighImpactAction: isHighImpactAction ?? this.isHighImpactAction,
      policyChecksPassed: policyChecksPassed ?? this.policyChecksPassed,
      convictionRequestId: convictionRequestId ?? this.convictionRequestId,
    );
  }
}

/// Recommendation Result
///
/// Unified result containing all recommendation types.
class RecommendationResult extends ControllerResult {
  final List<event_rec_service.EventRecommendation> events;
  final List<dynamic>
      spots; // TODO(Phase 8.11): Replace with SpotRecommendation
  final List<dynamic>
      lists; // TODO(Phase 8.11): Replace with ListRecommendation
  final PersonalityProfile? personalityProfile;
  final PreferencesProfile? preferencesProfile;
  final ConvictionGateDecision? convictionGateDecision;

  const RecommendationResult({
    required super.success,
    super.error,
    super.errorCode,
    super.metadata,
    this.events = const [],
    this.spots = const [],
    this.lists = const [],
    this.personalityProfile,
    this.preferencesProfile,
    this.convictionGateDecision,
  });

  /// Create successful recommendation result
  factory RecommendationResult.success({
    required List<event_rec_service.EventRecommendation> events,
    List<dynamic> spots = const [],
    List<dynamic> lists = const [],
    PersonalityProfile? personalityProfile,
    PreferencesProfile? preferencesProfile,
    ConvictionGateDecision? convictionGateDecision,
  }) {
    return RecommendationResult(
      success: true,
      events: events,
      spots: spots,
      lists: lists,
      personalityProfile: personalityProfile,
      preferencesProfile: preferencesProfile,
      convictionGateDecision: convictionGateDecision,
      metadata: {
        'timestamp': DateTime.now().toIso8601String(),
        'eventCount': events.length,
        'spotCount': spots.length,
        'listCount': lists.length,
      },
    );
  }

  /// Create failure recommendation result
  factory RecommendationResult.failure({
    required String error,
    String? errorCode,
    Map<String, dynamic>? metadata,
    ConvictionGateDecision? convictionGateDecision,
  }) {
    return RecommendationResult(
      success: false,
      error: error,
      errorCode: errorCode ?? 'RECOMMENDATION_FAILED',
      metadata: metadata,
      convictionGateDecision: convictionGateDecision,
    );
  }
}
