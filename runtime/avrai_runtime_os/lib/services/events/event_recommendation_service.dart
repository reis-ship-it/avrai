// MIGRATION_SHIM: LEGACY_PATH_GUARD TEMPORARY UNTIL TARGET-ROOT MIGRATION
import 'dart:developer' as developer;

import 'package:avrai_core/models/user/unified_user.dart';
import 'package:avrai_core/models/expertise/expertise_event.dart';
import 'package:avrai_core/models/expertise/expertise_level.dart';
import 'package:avrai_core/models/events/event_recommendation.dart'
    as core_events;
import 'package:avrai_core/models/why/why_models.dart' hide WhySignal;
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/os/headless_avrai_os_host.dart';
import 'package:avrai_runtime_os/services/expertise/expertise_event_service.dart';
import 'package:avrai_runtime_os/services/events/event_matching_service.dart';
import 'package:avrai_runtime_os/services/matching/user_preference_learning_service.dart';
import 'package:avrai_runtime_os/services/cross_app/cross_locality_connection_service.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai_runtime_os/controllers/base/workflow_controller.dart';
import 'package:avrai_runtime_os/controllers/quantum_matching_controller.dart';
import 'package:avrai_runtime_os/kernel/contracts/urk_kernel_activation_engine_contract.dart';
import 'package:avrai_runtime_os/kernel/contracts/urk_runtime_activation_receipt_dispatcher.dart';
import 'package:avrai_runtime_os/kernel/contracts/urk_stage_b_event_ops_shadow_runtime_contract.dart';
import 'package:avrai_core/models/quantum/matching_input.dart';
import 'package:avrai_runtime_os/kernel/service_contracts/urk_user_runtime_learning_intake_contract.dart';
import 'package:avrai_knot/services/knot/integrated_knot_recommendation_engine.dart';
import 'package:avrai_core/models/personality_knot.dart';
import 'package:avrai_knot/services/knot/knot_fabric_service.dart';
import 'package:avrai_knot/services/knot/knot_storage_service.dart';
import 'package:avrai_runtime_os/ai/personality_learning.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_runtime_os/services/signatures/entity_signature_service.dart';
import 'package:avrai_runtime_os/services/matching/vibe_compatibility_service.dart';
import 'package:avrai_runtime_os/services/recommendations/recommendation_why_explanation_service.dart';
import 'package:avrai_runtime_os/services/recommendations/recommendation_telemetry_service.dart';
import 'package:avrai_runtime_os/kernel/what/what_kernel_contract.dart';
import 'package:avrai_runtime_os/kernel/what/what_models.dart';
import 'package:get_it/get_it.dart';

/// Event Recommendation Service
///
/// Generates personalized event recommendations by combining:
/// - User preferences (learned from attendance patterns)
/// - Event matching scores (from EventMatchingService)
/// - Cross-locality connections (from CrossLocalityConnectionService)
///
/// **Philosophy:** "Doors, not badges" - Opens doors to events users will enjoy
///
/// **What Doors Does This Open?**
/// - Discovery Doors: Users find events matching their preferences
/// - Exploration Doors: Users discover events outside typical behavior
/// - Connection Doors: Users find events in connected localities
/// - Preference Doors: System learns and adapts to user preferences
///
/// **Recommendation Strategy:**
/// - Balance familiar preferences with exploration (70% familiar, 30% exploration)
/// - Show local expert events to users who prefer local events
/// - Show city/state events to users who prefer broader scope
/// - Include cross-locality events for users with movement patterns
class EventRecommendationService {
  static const String _logName = 'EventRecommendationService';
  final AppLogger _logger = const AppLogger(
    defaultTag: 'SPOTS',
    minimumLevel: LogLevel.debug,
  );

  final ExpertiseEventService _eventService;
  final EventMatchingService _matchingService;
  final UserPreferenceLearningService _preferenceService;
  final CrossLocalityConnectionService _crossLocalityService;
  final IntegratedKnotRecommendationEngine? _knotRecommendationEngine;
  final PersonalityLearning? _personalityLearning;
  final VibeCompatibilityService? _vibeCompatibilityService;
  final AgentIdService? _agentIdService;
  final StorageService? _storageService;
  final KnotFabricService? _knotFabricService;
  final KnotStorageService? _knotStorageService;
  final EntitySignatureService? _entitySignatureService;
  final WorkflowController<MatchingInput, QuantumMatchingResult>?
      _quantumMatchingController;
  final UrkStageBEventOpsShadowRuntimeValidator _runtimeValidator;
  final UrkUserRuntimeLearningIntakeContract _userRuntimeIntakeContract;
  final UrkRuntimeActivationReceiptDispatcher? _activationDispatcher;
  final RecommendationWhyExplanationService _whyExplanationService;
  final RecommendationTelemetryService? _telemetryService;
  final WhatKernelContract? _whatKernel;
  final HeadlessAvraiOsHost? _headlessOsHost;

  EventRecommendationService({
    ExpertiseEventService? eventService,
    EventMatchingService? matchingService,
    UserPreferenceLearningService? preferenceService,
    CrossLocalityConnectionService? crossLocalityService,
    IntegratedKnotRecommendationEngine? knotRecommendationEngine,
    PersonalityLearning? personalityLearning,
    VibeCompatibilityService? vibeCompatibilityService,
    AgentIdService? agentIdService,
    StorageService? storageService,
    KnotFabricService? knotFabricService,
    KnotStorageService? knotStorageService,
    EntitySignatureService? entitySignatureService,
    WorkflowController<MatchingInput, QuantumMatchingResult>?
        quantumMatchingController,
    UrkStageBEventOpsShadowRuntimeValidator runtimeValidator =
        const UrkStageBEventOpsShadowRuntimeValidator(),
    UrkUserRuntimeLearningIntakeContract userRuntimeIntakeContract =
        const UrkUserRuntimeLearningIntakeContract(),
    UrkRuntimeActivationReceiptDispatcher? activationDispatcher,
    RecommendationWhyExplanationService? whyExplanationService,
    RecommendationTelemetryService? telemetryService,
    WhatKernelContract? whatKernel,
    HeadlessAvraiOsHost? headlessOsHost,
  })  : _eventService = eventService ?? ExpertiseEventService(),
        _matchingService = matchingService ?? EventMatchingService(),
        _preferenceService =
            preferenceService ?? UserPreferenceLearningService(),
        _crossLocalityService =
            crossLocalityService ?? CrossLocalityConnectionService(),
        _knotRecommendationEngine = knotRecommendationEngine,
        _personalityLearning = personalityLearning,
        _vibeCompatibilityService = vibeCompatibilityService,
        _agentIdService = agentIdService,
        _storageService = storageService ?? resolveDefaultStorageService(),
        _knotFabricService = knotFabricService,
        _knotStorageService = knotStorageService,
        _entitySignatureService = entitySignatureService,
        _quantumMatchingController = quantumMatchingController,
        _runtimeValidator = runtimeValidator,
        _userRuntimeIntakeContract = userRuntimeIntakeContract,
        _activationDispatcher = activationDispatcher ??
            resolveDefaultUrkRuntimeActivationDispatcher(),
        _whyExplanationService = whyExplanationService ??
            RecommendationWhyExplanationService(
              headlessOsHost: headlessOsHost ??
                  (GetIt.I.isRegistered<HeadlessAvraiOsHost>()
                      ? GetIt.I<HeadlessAvraiOsHost>()
                      : null),
            ),
        _telemetryService =
            telemetryService ?? resolveDefaultRecommendationTelemetryService(),
        _whatKernel = whatKernel,
        _headlessOsHost = headlessOsHost ??
            (GetIt.I.isRegistered<HeadlessAvraiOsHost>()
                ? GetIt.I<HeadlessAvraiOsHost>()
                : null);

  /// Phase 19 vertical slice: compute an entanglement-based compatibility score for a user↔event pair.
  ///
  /// This is a **best-effort** signal used to enrich recommendation compatibility without requiring
  /// BLE transport or hardware. If the quantum matching stack is not wired, this returns null.
  Future<double?> calculateQuantumEntanglementScoreForEvent({
    required UnifiedUser user,
    required ExpertiseEvent event,
  }) async {
    final controller = _quantumMatchingController;
    if (controller == null) return null;

    try {
      final res =
          await controller.execute(MatchingInput(user: user, event: event));
      final match = res.matchingResult;
      if (!res.success || match == null) return null;
      return match.compatibility.clamp(0.0, 1.0);
    } catch (e) {
      _logger.warn(
        'Quantum entanglement score failed: $e (skipping)',
        tag: _logName,
      );
      return null;
    }
  }

  /// Public wrapper for recommendation-time compatibility so tests can validate integration.
  ///
  /// Internally this delegates to the same logic used in `_calculateRelevanceScore()`.
  Future<double> calculateKnotCompatibilityForRecommendation({
    required ExpertiseEvent event,
    required UnifiedUser user,
  }) async {
    return _calculateKnotCompatibilityScore(event: event, user: user);
  }

  WhySnapshot explainRecommendation({
    required UnifiedUser user,
    required EventRecommendation recommendation,
    String perspective = 'system',
  }) {
    return _whyExplanationService.explainRecommendation(
      user: user,
      recommendation: _toCoreRecommendation(recommendation),
      perspective: perspective,
    );
  }

  RecommendationExpressionArtifact expressRecommendation({
    required UnifiedUser user,
    required EventRecommendation recommendation,
    String perspective = 'user_safe',
    WhySnapshot? explanation,
  }) {
    final coreRecommendation = _toCoreRecommendation(recommendation);
    if (explanation != null) {
      return _whyExplanationService.buildRecommendationExpressionArtifact(
        userId: user.id,
        recommendation: coreRecommendation,
        explanation: explanation,
        perspective: perspective,
      );
    }
    return _whyExplanationService.expressRecommendation(
      user: user,
      recommendation: coreRecommendation,
      perspective: perspective,
    );
  }

  Future<RecommendationExpressionArtifact>
      expressRecommendationWithKernelContext({
    required UnifiedUser user,
    required EventRecommendation recommendation,
    String perspective = 'user_safe',
  }) {
    return _whyExplanationService.expressRecommendationWithKernelContext(
      user: user,
      recommendation: _toCoreRecommendation(recommendation),
      perspective: perspective,
    );
  }

  core_events.EventRecommendation _toCoreRecommendation(
    EventRecommendation recommendation,
  ) {
    final lowerReason = recommendation.recommendationReason.toLowerCase();
    final locality = _extractLocality(recommendation.event.location);
    final categoryMatch =
        lowerReason.contains(recommendation.event.category.toLowerCase())
            ? 0.88
            : (recommendation.relevanceScore * 0.65).clamp(0.0, 1.0);
    final localityMatch =
        locality != null && lowerReason.contains(locality.toLowerCase())
            ? 0.82
            : (recommendation.event.location != null ? 0.46 : 0.18);
    final localExpertMatch = lowerReason.contains('local expert') ? 0.86 : 0.44;
    final eventTypeMatch = lowerReason.contains(
            recommendation.event.getEventTypeDisplayName().toLowerCase())
        ? 0.72
        : 0.4;
    return core_events.EventRecommendation(
      event: recommendation.event,
      relevanceScore: recommendation.relevanceScore,
      reason: _mapReason(recommendation),
      preferenceMatch: core_events.PreferenceMatchDetails(
        categoryMatch: categoryMatch,
        localityMatch: localityMatch,
        scopeMatch: recommendation.relevanceScore.clamp(0.0, 1.0),
        eventTypeMatch: eventTypeMatch,
        localExpertMatch: localExpertMatch,
      ),
      generatedAt: DateTime.now().toUtc(),
    );
  }

  core_events.RecommendationReason _mapReason(
      EventRecommendation recommendation) {
    final lowerReason = recommendation.recommendationReason.toLowerCase();
    if (lowerReason.contains('local expert')) {
      return core_events.RecommendationReason.localExpert;
    }
    final locality = _extractLocality(recommendation.event.location);
    if (locality != null && lowerReason.contains(locality.toLowerCase())) {
      return core_events.RecommendationReason.localityPreference;
    }
    if (lowerReason.contains(recommendation.event.category.toLowerCase())) {
      return core_events.RecommendationReason.categoryPreference;
    }
    if (recommendation.relevanceScore < 0.45) {
      return core_events.RecommendationReason.exploration;
    }
    return core_events.RecommendationReason.combined;
  }

  double _blendCompatibility({
    required double base,
    required double entanglement,
  }) {
    // Small, stable enrichment: keep existing compatibility primary, add multi-entity entanglement as a secondary factor.
    return ((0.7 * base) + (0.3 * entanglement)).clamp(0.0, 1.0);
  }

  /// Get personalized event recommendations
  ///
  /// **Parameters:**
  /// - `user`: User to get recommendations for
  /// - `category`: Optional category filter
  /// - `location`: Optional location filter
  /// - `maxResults`: Maximum number of recommendations
  /// - `explorationRatio`: Ratio of exploration events (0.0 to 1.0, default 0.3)
  ///
  /// **Returns:**
  /// List of event recommendations sorted by relevance score
  ///
  /// **Recommendation Process:**
  /// 1. Get user preferences
  /// 2. Get matching scores for events
  /// 3. Combine preferences with matching scores
  /// 4. Balance familiar preferences with exploration
  /// 5. Sort by relevance score
  Future<List<EventRecommendation>> getPersonalizedRecommendations({
    required UnifiedUser user,
    String? category,
    String? location,
    int maxResults = 20,
    double explorationRatio = 0.3,
  }) async {
    try {
      _logger.info(
        'Getting personalized recommendations for user: ${user.id}',
        tag: _logName,
      );

      // Get user preferences
      final preferences =
          await _preferenceService.getUserPreferences(user: user);

      // Get all available events
      final allEvents = await _eventService.searchEvents(
        category: category,
        location: location,
        maxResults: 100, // Get more events to filter from
      );

      // Calculate relevance scores for each event
      final recommendations = <EventRecommendation>[];

      for (final event in allEvents) {
        final relevanceScore = await _calculateRelevanceScore(
          event: event,
          user: user,
          preferences: preferences,
          category: category,
          location: location,
        );

        recommendations.add(EventRecommendation(
          event: event,
          relevanceScore: relevanceScore,
          recommendationReason: _generateRecommendationReason(
            event: event,
            preferences: preferences,
            relevanceScore: relevanceScore,
          ),
        ));
      }

      // Separate familiar and exploration recommendations
      final familiarRecommendations =
          recommendations.where((r) => r.relevanceScore >= 0.6).toList();
      final explorationRecommendations = recommendations
          .where((r) => r.relevanceScore < 0.6 && r.relevanceScore >= 0.3)
          .toList();

      // Balance familiar with exploration
      final familiarCount = ((1.0 - explorationRatio) * maxResults).round();
      final explorationCount = (explorationRatio * maxResults).round();

      // Sort by relevance score
      familiarRecommendations
          .sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
      explorationRecommendations
          .sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));

      // Combine recommendations
      final combined = <EventRecommendation>[
        ...familiarRecommendations.take(familiarCount),
        ...explorationRecommendations.take(explorationCount),
      ];

      // Final sort by relevance score
      combined.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));

      final output = combined.take(maxResults).toList();
      final lifecycleArtifact =
          await _emitHeadlessKernelRecommendationLifecycle(
        user: user,
        scopeHint: location ?? 'personalized',
        category: category,
        recommendations: output,
        reason: 'event_recommendations',
        failure: null,
      );
      await _recordRecommendationTelemetry(
        user: user,
        recommendations: output,
        lifecycleArtifact: lifecycleArtifact,
      );
      await _dispatchUserRuntimeLearningSignal(
        userId: user.id,
        scopeHint: 'personalized',
        reason: 'event_recommendations',
      );
      await _dispatchEventOpsRuntimeValidation(
        userId: user.id,
        scopeHint: 'personalized',
        passing: true,
        criticalFailure: false,
        reason: 'event_recommendations',
      );
      return output;
    } catch (e) {
      await _emitHeadlessKernelRecommendationLifecycle(
        user: user,
        scopeHint: location ?? 'personalized',
        category: category,
        recommendations: const <EventRecommendation>[],
        reason: 'event_recommendations_error',
        failure: e,
      );
      await _dispatchEventOpsRuntimeValidation(
        userId: user.id,
        scopeHint: 'personalized',
        passing: false,
        criticalFailure: true,
        reason: 'event_recommendations_error',
      );
      _logger.error(
        'Error getting personalized recommendations',
        error: e,
        tag: _logName,
      );
      return [];
    }
  }

  Future<void> _recordRecommendationTelemetry({
    required UnifiedUser user,
    required List<EventRecommendation> recommendations,
    _RecommendationKernelLifecycleArtifact? lifecycleArtifact,
  }) async {
    final telemetry = _telemetryService;
    if (telemetry == null || recommendations.isEmpty) {
      return;
    }
    try {
      final records =
          await Future.wait(recommendations.take(5).map((recommendation) async {
        final coreRecommendation = _toCoreRecommendation(recommendation);
        final explanation =
            await _whyExplanationService.explainRecommendationWithKernelContext(
          user: user,
          recommendation: coreRecommendation,
          perspective: 'admin',
        );
        return RecommendationTelemetryRecord(
          recordId:
              'rec_${user.id}_${recommendation.event.id}_${coreRecommendation.generatedAt.microsecondsSinceEpoch}',
          timestamp: coreRecommendation.generatedAt,
          userId: user.id,
          eventId: recommendation.event.id,
          eventTitle: recommendation.event.title,
          category: recommendation.event.category,
          reason: recommendation.recommendationReason,
          relevanceScore: recommendation.relevanceScore,
          traceRef:
              'user:${user.id}|event:${recommendation.event.id}|reason:${_mapReason(recommendation).name}',
          location: recommendation.event.location,
          kernelEventId: lifecycleArtifact?.kernelEventId,
          modelTruthReady: lifecycleArtifact?.modelTruthReady,
          localityContainedInWhere: lifecycleArtifact?.localityContainedInWhere,
          governanceSummary: lifecycleArtifact?.governanceSummary,
          governanceDomains:
              lifecycleArtifact?.governanceDomains ?? const <String>[],
          explanation: explanation,
        );
      }).toList(growable: false));
      await telemetry.recordRecommendations(records);
    } catch (error) {
      _logger.warn(
        'Failed to record recommendation telemetry: $error',
        tag: _logName,
      );
    }
  }

  /// Get recommendations for specific scope
  ///
  /// **Parameters:**
  /// - `user`: User to get recommendations for
  /// - `scope`: Scope to filter by (local, city, state, national, global, universal)
  /// - `category`: Optional category filter
  /// - `maxResults`: Maximum number of recommendations
  ///
  /// **Returns:**
  /// List of event recommendations for the specified scope
  ///
  /// **Usage:**
  /// Used for tab-based filtering in EventsBrowsePage
  Future<List<EventRecommendation>> getRecommendationsForScope({
    required UnifiedUser user,
    required String scope,
    String? category,
    int maxResults = 20,
  }) async {
    try {
      _logger.info(
        'Getting recommendations for scope: $scope, user: ${user.id}',
        tag: _logName,
      );

      // Get user preferences
      final preferences =
          await _preferenceService.getUserPreferences(user: user);

      // Filter events by scope
      final scopeEvents = await _getEventsByScope(
        user: user,
        scope: scope,
        category: category,
      );

      // Calculate relevance scores
      final recommendations = <EventRecommendation>[];

      for (final event in scopeEvents) {
        final relevanceScore = await _calculateRelevanceScore(
          event: event,
          user: user,
          preferences: preferences,
          category: category,
          location: null,
        );

        recommendations.add(EventRecommendation(
          event: event,
          relevanceScore: relevanceScore,
          recommendationReason: _generateRecommendationReason(
            event: event,
            preferences: preferences,
            relevanceScore: relevanceScore,
          ),
        ));
      }

      // Sort by relevance score
      recommendations
          .sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));

      final output = recommendations.take(maxResults).toList();
      final lifecycleArtifact =
          await _emitHeadlessKernelRecommendationLifecycle(
        user: user,
        scopeHint: scope,
        category: category,
        recommendations: output,
        reason: 'event_scope_recommendations',
        failure: null,
      );
      await _recordRecommendationTelemetry(
        user: user,
        recommendations: output,
        lifecycleArtifact: lifecycleArtifact,
      );
      await _dispatchUserRuntimeLearningSignal(
        userId: user.id,
        scopeHint: scope,
        reason: 'event_scope_recommendations',
      );
      await _dispatchEventOpsRuntimeValidation(
        userId: user.id,
        scopeHint: scope,
        passing: true,
        criticalFailure: false,
        reason: 'event_scope_recommendations',
      );
      return output;
    } catch (e) {
      await _emitHeadlessKernelRecommendationLifecycle(
        user: user,
        scopeHint: scope,
        category: category,
        recommendations: const <EventRecommendation>[],
        reason: 'event_scope_recommendations_error',
        failure: e,
      );
      await _dispatchEventOpsRuntimeValidation(
        userId: user.id,
        scopeHint: scope,
        passing: false,
        criticalFailure: true,
        reason: 'event_scope_recommendations_error',
      );
      _logger.error(
        'Error getting recommendations for scope',
        error: e,
        tag: _logName,
      );
      return [];
    }
  }

  Future<_RecommendationKernelLifecycleArtifact?>
      _emitHeadlessKernelRecommendationLifecycle({
    required UnifiedUser user,
    required String scopeHint,
    required String? category,
    required List<EventRecommendation> recommendations,
    required String reason,
    required Object? failure,
  }) async {
    final headlessOsHost = _headlessOsHost;
    if (headlessOsHost == null) {
      return null;
    }
    try {
      await headlessOsHost.start();
      final agentId = await _resolveActorAgentId(user.id);
      final generatedAt = DateTime.now().toUtc();
      final primaryRecommendation =
          recommendations.isEmpty ? null : recommendations.first;
      final envelope = KernelEventEnvelope(
        eventId:
            'event_reco:${user.id}:${generatedAt.microsecondsSinceEpoch}:$reason',
        agentId: agentId,
        userId: user.id,
        occurredAtUtc: generatedAt,
        sourceSystem: 'event_recommendation_service',
        eventType: failure == null
            ? 'event_recommendations_generated'
            : 'event_recommendations_failed',
        actionType: 'recommend_event',
        entityId: primaryRecommendation?.event.id,
        entityType:
            primaryRecommendation == null ? 'recommendation_batch' : 'event',
        context: <String, dynamic>{
          'scope_hint': scopeHint,
          if (category != null) 'category': category,
          'recommendation_count': recommendations.length,
          if (failure != null) 'failure': failure.toString(),
        },
        predictionContext: <String, dynamic>{
          'planner_mode': 'event_recommendation_service',
          'model_family': 'event_recommendation_service',
          if (primaryRecommendation != null)
            'predicted_relevance': primaryRecommendation.relevanceScore,
        },
        policyContext: <String, dynamic>{
          'trust_scope': 'private',
          'legacy_dispatch_active': _activationDispatcher != null,
        },
        runtimeContext: <String, dynamic>{
          'execution_path':
              'event_recommendation_service.${failure == null ? "success" : "failure"}',
          'workflow_stage': failure == null
              ? 'recommendation_delivery'
              : 'recommendation_error',
          'intervention_chain': <String>[
            'preference_score',
            'ranking',
            'telemetry',
            'headless_os_host',
          ],
        },
      );
      final runtimeBundle =
          await headlessOsHost.resolveRuntimeExecution(envelope: envelope);
      final whyRequest = KernelWhyRequest(
        bundle: runtimeBundle.withoutWhy(),
        goal: 'recommend_event',
        predictedOutcome: failure == null
            ? 'recommendation_visible'
            : 'recommendation_failed',
        predictedConfidence: primaryRecommendation?.relevanceScore ??
            (failure == null ? 0.5 : 0.0),
        actualOutcome: failure == null ? 'generated' : 'failed',
        actualOutcomeScore: failure == null ? 1.0 : 0.0,
        coreSignals: <WhySignal>[
          WhySignal(
            label: 'recommendation_count_${recommendations.length}',
            weight: recommendations.isEmpty ? -0.25 : 0.45,
            source: 'core',
            durable: false,
          ),
        ],
        policySignals: <WhySignal>[
          WhySignal(
            label: 'legacy_dispatch_active',
            weight: _activationDispatcher == null ? -0.15 : 0.15,
            source: 'policy',
            durable: false,
          ),
        ],
        pheromoneSignals: <WhySignal>[
          if (primaryRecommendation != null)
            WhySignal(
              label: 'top_relevance',
              weight: primaryRecommendation.relevanceScore.clamp(0.0, 1.0),
              source: 'pheromone',
              durable: false,
            ),
        ],
        severity: failure == null ? 'normal' : 'elevated',
      );
      final governanceReport = await headlessOsHost.inspectGovernance(
        envelope: envelope,
        whyRequest: whyRequest,
      );
      developer.log(
        'Headless recommendation lifecycle emitted with '
        '${governanceReport.projections.length} governance projections',
        name: _logName,
      );
      return _RecommendationKernelLifecycleArtifact(
        kernelEventId: envelope.eventId,
        modelTruthReady: true,
        localityContainedInWhere: true,
        governanceSummary: governanceReport.projections.isEmpty
            ? 'No governance projections'
            : governanceReport.projections.first.summary,
        governanceDomains: governanceReport.projections
            .map((projection) => projection.domain.name)
            .toList(growable: false),
      );
    } catch (error) {
      _logger.warn(
        'Headless OS recommendation lifecycle failed: $error',
        tag: _logName,
      );
      return null;
    }
  }

  // Private helper methods

  Future<void> _dispatchEventOpsRuntimeValidation({
    required String userId,
    required String scopeHint,
    required bool passing,
    required bool criticalFailure,
    required String reason,
  }) async {
    final dispatcher = _activationDispatcher;
    if (dispatcher == null) {
      return;
    }
    const policy = UrkStageBEventOpsShadowRuntimePolicy(
      requiredPipelineCoveragePct: 100.0,
      requiredDecisionEnvelopeCoveragePct: 100.0,
      requiredLineageCompletenessPct: 100.0,
      maxOrphanActionStates: 0,
      maxHighImpactAutocommits: 0,
      requiredShadowBlockCoveragePct: 100.0,
    );
    final snapshot = passing
        ? const UrkStageBEventOpsShadowRuntimeSnapshot(
            observedPipelineCoveragePct: 100.0,
            observedDecisionEnvelopeCoveragePct: 100.0,
            observedLineageCompletenessPct: 100.0,
            observedOrphanActionStates: 0,
            observedHighImpactAutocommits: 0,
            observedShadowBlockCoveragePct: 100.0,
          )
        : UrkStageBEventOpsShadowRuntimeSnapshot(
            observedPipelineCoveragePct: 100.0,
            observedDecisionEnvelopeCoveragePct: 90.0,
            observedLineageCompletenessPct: 100.0,
            observedOrphanActionStates: criticalFailure ? 1 : 0,
            observedHighImpactAutocommits: criticalFailure ? 1 : 0,
            observedShadowBlockCoveragePct: 90.0,
          );
    try {
      await _runtimeValidator.validateAndDispatch(
        snapshot: snapshot,
        policy: policy,
        activationDispatcher: dispatcher,
        actor: _logName,
        requestIdPrefix: 'event_reco_${userId}_${scopeHint}_$reason',
      );
    } catch (_) {
      // Dispatch path must never block user recommendations.
    }
  }

  Future<void> _dispatchUserRuntimeLearningSignal({
    required String userId,
    required String scopeHint,
    required String reason,
  }) async {
    final dispatcher = _activationDispatcher;
    if (dispatcher == null) {
      return;
    }
    try {
      final actorAgentId = await _resolveActorAgentId(userId);
      final intakeResult = _userRuntimeIntakeContract.validate(
        UrkUserRuntimeLearningIntakeRequest(
          actorAgentId: actorAgentId,
          signalType: 'in_app_behavior',
          consentScopes: await _resolveConsentScopes(),
          containsSensitiveRawContent: false,
        ),
      );
      if (!intakeResult.accepted) {
        await dispatcher.dispatch(
          requestId:
              'user_runtime_learning_${userId}_${scopeHint}_${reason}_${DateTime.now().millisecondsSinceEpoch}',
          trigger: 'policy_violation_detected',
          privacyMode: UrkPrivacyMode.localSovereign,
          actor: intakeResult.pseudonymousActorRef,
          reason:
              'user_runtime_learning_intake_rejected;runtime_lane=user_runtime;privacy_mode=local_sovereign;consent_toggle=user_runtime_learning_enabled;reason_code=${intakeResult.reasonCode}',
        );
        return;
      }
      await dispatcher.dispatch(
        requestId:
            'user_runtime_learning_${userId}_${scopeHint}_${reason}_${DateTime.now().millisecondsSinceEpoch}',
        trigger: 'user_runtime_learning_signal',
        privacyMode: UrkPrivacyMode.localSovereign,
        actor: intakeResult.pseudonymousActorRef,
        reason:
            'user_runtime_learning_intake_accepted;runtime_lane=user_runtime;privacy_mode=local_sovereign;consent_toggle=user_runtime_learning_enabled',
      );
    } catch (_) {
      // Intake dispatch must not block recommendation delivery.
    }
  }

  Future<String> _resolveActorAgentId(String userId) async {
    final service = _agentIdService;
    if (service == null) {
      return 'agt_$userId';
    }
    try {
      return await service.getUserAgentId(userId);
    } catch (_) {
      return 'agt_$userId';
    }
  }

  Future<Set<String>> _resolveConsentScopes() async {
    final scopes = <String>{};
    final userRuntimeLearningEnabled = _readSettingBool(
      key: 'user_runtime_learning_enabled',
      defaultValue: true,
    );
    if (userRuntimeLearningEnabled) {
      scopes.add('user_runtime_learning');
    }
    final ai2aiLearningEnabled = _readSettingBool(
      key: 'ai2ai_learning_enabled',
      defaultValue: true,
    );
    if (ai2aiLearningEnabled) {
      scopes.add('ai2ai_learning');
    }
    final discoveryEnabled = _readSettingBool(
      key: 'discovery_enabled',
      defaultValue: true,
    );
    if (discoveryEnabled) {
      scopes.add('discovery');
    }
    final cloudSyncEnabled = _readSettingBool(
      key: 'cloud_sync_enabled',
      defaultValue: false,
    );
    if (cloudSyncEnabled) {
      scopes.add('cloud_sync');
    }
    return scopes;
  }

  bool _readSettingBool({
    required String key,
    required bool defaultValue,
  }) {
    final storage = _storageService;
    if (storage == null) {
      return defaultValue;
    }
    try {
      return storage.getBool(key) ?? defaultValue;
    } catch (_) {
      return defaultValue;
    }
  }

  /// Calculate relevance score for an event
  ///
  /// **Combines:**
  /// - Matching score (from EventMatchingService): 35%
  /// - Preference match: 35%
  /// - Cross-locality boost: 15%
  /// - Knot compatibility (quantum + topology + weave): 15% (optional enhancement)
  Future<double> _calculateRelevanceScore({
    required ExpertiseEvent event,
    required UnifiedUser user,
    required UserPreferences preferences,
    String? category,
    String? location,
  }) async {
    double fallbackScore = 0.0;

    // 1. Matching score (35% weight, reduced from 40% to make room for knot compatibility)
    final matchingScore = await _matchingService.calculateMatchingScore(
      expert: event.host,
      user: user,
      category: event.category,
      locality: _extractLocality(event.location) ?? '',
    );
    fallbackScore += matchingScore * 0.35;

    // 2. Preference match (35% weight, reduced from 40%)
    final preferenceScore = _calculatePreferenceScore(
      event: event,
      preferences: preferences,
    );
    fallbackScore += preferenceScore * 0.35;

    // 3. Cross-locality boost (15% weight, reduced from 20%)
    final crossLocalityScore = await _calculateCrossLocalityScore(
      event: event,
      user: user,
    );
    fallbackScore += crossLocalityScore * 0.15;

    // 4. Knot compatibility (15% weight - optional enhancement)
    final knotScore = await _calculateKnotCompatibilityScore(
      event: event,
      user: user,
    );
    fallbackScore += knotScore * 0.15;
    final semanticScore = await _calculateSemanticWhatScore(
      event: event,
      user: user,
    );
    fallbackScore =
        ((fallbackScore * 0.9) + (semanticScore * 0.1)).clamp(0.0, 1.0);

    final clampedFallback = fallbackScore.clamp(0.0, 1.0);
    if (_entitySignatureService == null) {
      return clampedFallback;
    }

    try {
      final personality = _personalityLearning == null
          ? null
          : await _personalityLearning.getCurrentPersonality(user.id);
      final match = await _entitySignatureService.matchUserToEvent(
        user: user,
        event: event,
        fallbackScore: clampedFallback,
        personality: personality,
      );
      return match.finalScore;
    } catch (e) {
      _logger.warn(
        'Event signature scoring failed, using fallback: $e',
        tag: _logName,
      );
      return clampedFallback;
    }
  }

  Future<double> _calculateSemanticWhatScore({
    required ExpertiseEvent event,
    required UnifiedUser user,
  }) async {
    if (_whatKernel == null || _agentIdService == null) {
      return 0.5;
    }
    try {
      final agentId = await _agentIdService.getUserAgentId(user.id);
      final state = await _whatKernel.resolveWhat(
        WhatPerceptionInput(
          agentId: agentId,
          observedAtUtc: DateTime.now().toUtc(),
          source: 'event_recommendation_service',
          entityRef: 'event:${event.id}',
          candidateLabels: <String>[
            event.category,
            event.getEventTypeDisplayName(),
          ],
          locationContext: <String, dynamic>{
            if (event.location != null) 'location': event.location,
          },
          temporalContext: <String, dynamic>{
            'startTime': event.startTime.toIso8601String(),
          },
          activityHint: event.category.toLowerCase().replaceAll(' ', '_'),
          structuredMetadata: <String, dynamic>{
            'eventType': event.getEventTypeDisplayName(),
            if (event.cityCode != null) 'cityCode': event.cityCode,
            if (event.localityCode != null) 'localityCode': event.localityCode,
          },
        ),
      );
      final affordanceStrength = state.affordanceVector.isEmpty
          ? 0.0
          : state.affordanceVector.values.reduce((a, b) => a + b) /
              state.affordanceVector.length;
      final relationBoost = switch (state.userRelation) {
        WhatUserRelation.prefers => 0.9,
        WhatUserRelation.contextualLike => 0.74,
        WhatUserRelation.curiousAbout => 0.62,
        WhatUserRelation.usedToLike => 0.42,
        WhatUserRelation.avoids => 0.12,
        _ => 0.5,
      };
      return ((state.trust * 0.3) +
              (state.novelty * 0.2) +
              (relationBoost * 0.3) +
              (affordanceStrength * 0.2))
          .clamp(0.0, 1.0);
    } catch (e) {
      _logger.warn(
        'What semantic enrichment failed, using neutral score: $e',
        tag: _logName,
      );
      return 0.5;
    }
  }

  /// Calculate knot compatibility score for event recommendation
  ///
  /// Preferred: uses the **truthful** VibeCompatibilityService to incorporate
  /// user↔event knot topology + weave (in addition to quantum).
  ///
  /// Fallback: uses IntegratedKnotRecommendationEngine (user↔host only).
  ///
  /// **Returns:** Compatibility score (0.0 to 1.0), or 0.5 (neutral) if unavailable
  Future<double> _calculateKnotCompatibilityScore({
    required ExpertiseEvent event,
    required UnifiedUser user,
  }) async {
    final entanglementScore = await calculateQuantumEntanglementScoreForEvent(
      user: user,
      event: event,
    );

    // Best-available "true compatibility": does the user's knot improve / fit
    // into the event's current weave (host + current attendees)?
    final weaveFit = await _calculateUserEventWeaveFit(
      event: event,
      user: user,
    );
    if (weaveFit != null && _vibeCompatibilityService != null) {
      try {
        final vibe = await _vibeCompatibilityService.calculateUserEventVibe(
          userId: user.id,
          event: event,
        );

        // Patent-aligned integrated score, but with **fabric-based weave fit**
        // instead of pairwise knot weave similarity.
        final integrated = (0.5 * vibe.quantum) +
            (0.3 * vibe.knotTopological) +
            (0.2 * weaveFit);

        _logger.debug(
          'User↔Event true compatibility: event=${event.id} user=${user.id} '
          'combined=${(integrated * 100).toStringAsFixed(1)}% '
          '(quantum=${(vibe.quantum * 100).toStringAsFixed(1)}%, '
          'topo=${(vibe.knotTopological * 100).toStringAsFixed(1)}%, '
          'weaveFit=${(weaveFit * 100).toStringAsFixed(1)}%)',
          tag: _logName,
        );

        final base = integrated.clamp(0.0, 1.0);
        return entanglementScore == null
            ? base
            : _blendCompatibility(base: base, entanglement: entanglementScore);
      } catch (e) {
        _logger.warn(
          'Error combining weave fit with vibe: $e (using weave fit only)',
          tag: _logName,
        );
        final base = weaveFit.clamp(0.0, 1.0);
        return entanglementScore == null
            ? base
            : _blendCompatibility(base: base, entanglement: entanglementScore);
      }
    }

    if (weaveFit != null) {
      final base = weaveFit.clamp(0.0, 1.0);
      return entanglementScore == null
          ? base
          : _blendCompatibility(base: base, entanglement: entanglementScore);
    }

    // Preferred path: user knot inserted into event knot weave (best-effort).
    if (_vibeCompatibilityService != null) {
      try {
        final vibe = await _vibeCompatibilityService.calculateUserEventVibe(
          userId: user.id,
          event: event,
        );

        _logger.debug(
          'User↔Event vibe for event ${event.id}: ${(vibe.combined * 100).toStringAsFixed(1)}% '
          '(quantum: ${(vibe.quantum * 100).toStringAsFixed(1)}%, '
          'topo: ${(vibe.knotTopological * 100).toStringAsFixed(1)}%, '
          'weave: ${(vibe.knotWeave * 100).toStringAsFixed(1)}%)',
          tag: _logName,
        );

        final base = vibe.combined.clamp(0.0, 1.0);
        return entanglementScore == null
            ? base
            : _blendCompatibility(base: base, entanglement: entanglementScore);
      } catch (e) {
        _logger.warn(
          'Error calculating user↔event vibe: $e, falling back',
          tag: _logName,
        );
      }
    }

    // If knot services not available, return neutral score
    if (_knotRecommendationEngine == null || _personalityLearning == null) {
      const base = 0.5;
      return entanglementScore == null
          ? base
          : _blendCompatibility(base: base, entanglement: entanglementScore);
    }

    try {
      // Get personality profiles for user and event host
      final userProfile =
          await _personalityLearning.initializePersonality(user.id);
      final hostProfile =
          await _personalityLearning.initializePersonality(event.host.id);

      // Calculate integrated compatibility (quantum + knot topology)
      final compatibility =
          await _knotRecommendationEngine.calculateIntegratedCompatibility(
        profileA: userProfile,
        profileB: hostProfile,
      );

      _logger.debug(
        'Knot compatibility for event ${event.id}: ${(compatibility.combined * 100).toStringAsFixed(1)}% '
        '(quantum: ${(compatibility.quantum * 100).toStringAsFixed(1)}%, '
        'knot: ${(compatibility.knot * 100).toStringAsFixed(1)}%)',
        tag: _logName,
      );

      final base = compatibility.combined.clamp(0.0, 1.0);
      return entanglementScore == null
          ? base
          : _blendCompatibility(base: base, entanglement: entanglementScore);
    } catch (e) {
      _logger.warn(
        'Error calculating knot compatibility: $e, using neutral score',
        tag: _logName,
      );
      // Return neutral score on error (don't break recommendations)
      const base = 0.5;
      return entanglementScore == null
          ? base
          : _blendCompatibility(base: base, entanglement: entanglementScore);
    }
  }

  /// Calculate preference match score
  double _calculatePreferenceScore({
    required ExpertiseEvent event,
    required UserPreferences preferences,
  }) {
    double score = 0.0;

    // Category preference
    final categoryWeight =
        preferences.categoryPreferences[event.category] ?? 0.0;
    score += categoryWeight * 0.3;

    // Locality preference
    final locality = _extractLocality(event.location);
    if (locality != null) {
      final localityWeight = preferences.localityPreferences[locality] ?? 0.0;
      score += localityWeight * 0.2;
    }

    // Scope preference (based on host expertise level)
    final hostLevel = event.host.getExpertiseLevel(event.category);
    if (hostLevel != null) {
      final scope = _getScopeFromLevel(hostLevel);
      final scopeWeight = preferences.scopePreferences[scope] ?? 0.0;
      score += scopeWeight * 0.2;
    }

    // Local vs city expert preference
    if (hostLevel == ExpertiseLevel.local && preferences.prefersLocalExperts) {
      score += 0.2; // Boost for local experts if user prefers them
    } else if (hostLevel != null &&
        hostLevel != ExpertiseLevel.local &&
        preferences.prefersCityExperts) {
      score += 0.1; // Boost for city experts if user prefers them
    }

    // Event type preference
    final typeWeight = preferences.eventTypePreferences[event.eventType] ?? 0.0;
    score += typeWeight * 0.1;

    return score.clamp(0.0, 1.0);
  }

  /// Calculate cross-locality connection score
  Future<double> _calculateCrossLocalityScore({
    required ExpertiseEvent event,
    required UnifiedUser user,
  }) async {
    final eventLocality = _extractLocality(event.location);
    if (eventLocality == null) return 0.0;

    // Get user's locality
    final userLocality = _extractLocality(user.location);
    if (userLocality == null) return 0.0;

    // If event is in user's locality, no cross-locality boost needed
    if (eventLocality.toLowerCase() == userLocality.toLowerCase()) {
      return 0.0;
    }

    // Get connected localities
    final connectedLocalities =
        await _crossLocalityService.getConnectedLocalities(
      user: user,
      locality: userLocality,
    );

    // Check if event locality is connected
    for (final connected in connectedLocalities) {
      if (connected.locality.toLowerCase() == eventLocality.toLowerCase()) {
        return connected.connectionStrength;
      }
    }

    return 0.0; // Not in connected localities
  }

  /// Get events by scope
  Future<List<ExpertiseEvent>> _getEventsByScope({
    required UnifiedUser user,
    required String scope,
    String? category,
  }) async {
    // Get all events
    final allEvents = await _eventService.searchEvents(
      category: category,
      maxResults: 100,
    );

    // Filter by scope
    return allEvents.where((event) {
      final hostLevel = event.host.getExpertiseLevel(event.category);
      if (hostLevel == null) return false;

      final eventScope = _getScopeFromLevel(hostLevel);
      return eventScope.toLowerCase() == scope.toLowerCase();
    }).toList();
  }

  /// Get scope name from expertise level
  String _getScopeFromLevel(ExpertiseLevel level) {
    switch (level) {
      case ExpertiseLevel.local:
        return 'local';
      case ExpertiseLevel.city:
        return 'city';
      case ExpertiseLevel.regional:
        return 'state';
      case ExpertiseLevel.national:
        return 'national';
      case ExpertiseLevel.global:
        return 'global';
      case ExpertiseLevel.universal:
        return 'universal';
    }
  }

  /// Generate recommendation reason
  String _generateRecommendationReason({
    required ExpertiseEvent event,
    required UserPreferences preferences,
    required double relevanceScore,
  }) {
    final reasons = <String>[];

    // Category match
    if (preferences.categoryPreferences.containsKey(event.category)) {
      reasons.add('Matches your interest in ${event.category}');
    }

    // Locality match
    final locality = _extractLocality(event.location);
    if (locality != null &&
        preferences.localityPreferences.containsKey(locality)) {
      reasons.add('In $locality, which you frequent');
    }

    // Local expert preference
    final hostLevel = event.host.getExpertiseLevel(event.category);
    if (hostLevel == ExpertiseLevel.local && preferences.prefersLocalExperts) {
      reasons.add('Hosted by a local expert (you prefer local events)');
    }

    // High relevance
    if (relevanceScore >= 0.8) {
      reasons.add('Highly relevant to your preferences');
    }

    return reasons.isNotEmpty
        ? reasons.join(' • ')
        : 'Recommended based on your activity';
  }

  /// Extract locality from location string
  String? _extractLocality(String? location) {
    if (location == null || location.isEmpty) return null;
    return location.split(',').first.trim();
  }

  Future<double?> _calculateUserEventWeaveFit({
    required ExpertiseEvent event,
    required UnifiedUser user,
  }) async {
    if (_agentIdService == null ||
        _knotFabricService == null ||
        _knotStorageService == null) {
      return null;
    }

    try {
      final userAgentId = await _agentIdService.getUserAgentId(user.id);
      final userKnot = await _knotStorageService.loadKnot(userAgentId);
      if (userKnot == null) return null;

      // Baseline: host + current attendees (excluding the user if already present).
      final baselineUserIds = <String>{
        event.host.id,
        ...event.attendeeIds.take(10),
      }.where((id) => id != user.id).toList();

      if (baselineUserIds.isEmpty) return null;

      final baselineKnots = <PersonalityKnot>[];
      for (final id in baselineUserIds) {
        try {
          final agentId = await _agentIdService.getUserAgentId(id);
          final knot = await _knotStorageService.loadKnot(agentId);
          if (knot != null) baselineKnots.add(knot);
        } catch (_) {
          // Skip users without knots.
        }
      }

      if (baselineKnots.isEmpty) return null;

      final baselineFabric =
          await _knotFabricService.generateMultiStrandBraidFabric(
        userKnots: baselineKnots,
      );
      final baselineStability =
          await _knotFabricService.measureFabricStability(baselineFabric);

      final withUserFabric =
          await _knotFabricService.generateMultiStrandBraidFabric(
        userKnots: [userKnot, ...baselineKnots],
      );
      final withUserStability =
          await _knotFabricService.measureFabricStability(withUserFabric);

      final stabilityDrop =
          (baselineStability - withUserStability).clamp(0.0, 1.0);
      final fit = (withUserStability * (1.0 - stabilityDrop)).clamp(0.0, 1.0);

      _logger.debug(
        'Event weave fit: event=${event.id} user=${user.id} '
        'baseline=${baselineStability.toStringAsFixed(3)} '
        'withUser=${withUserStability.toStringAsFixed(3)} '
        'fit=${fit.toStringAsFixed(3)}',
        tag: _logName,
      );

      return fit;
    } catch (e) {
      _logger.warn(
        'Error calculating event weave fit: $e',
        tag: _logName,
      );
      return null;
    }
  }
}

class _RecommendationKernelLifecycleArtifact {
  const _RecommendationKernelLifecycleArtifact({
    required this.kernelEventId,
    required this.modelTruthReady,
    required this.localityContainedInWhere,
    required this.governanceSummary,
    required this.governanceDomains,
  });

  final String kernelEventId;
  final bool modelTruthReady;
  final bool localityContainedInWhere;
  final String governanceSummary;
  final List<String> governanceDomains;
}

StorageService? resolveDefaultStorageService() {
  final sl = GetIt.instance;
  if (!sl.isRegistered<StorageService>()) {
    return null;
  }
  return sl<StorageService>();
}

RecommendationTelemetryService? resolveDefaultRecommendationTelemetryService() {
  final sl = GetIt.instance;
  if (!sl.isRegistered<RecommendationTelemetryService>()) {
    return null;
  }
  return sl<RecommendationTelemetryService>();
}

/// Event Recommendation Model
class EventRecommendation {
  final ExpertiseEvent event;
  final double relevanceScore; // 0.0 to 1.0
  final String recommendationReason;

  const EventRecommendation({
    required this.event,
    required this.relevanceScore,
    required this.recommendationReason,
  });
}
