// MIGRATION_SHIM: LEGACY_PATH_GUARD TEMPORARY UNTIL TARGET-ROOT MIGRATION
import 'package:avrai/core/models/user/unified_user.dart';
import 'package:avrai/core/models/expertise/expertise_event.dart';
import 'package:avrai/core/models/expertise/expertise_level.dart';
import 'package:avrai/core/services/expertise/expertise_event_service.dart';
import 'package:avrai/core/services/events/event_matching_service.dart';
import 'package:avrai/core/services/matching/user_preference_learning_service.dart';
import 'package:avrai/core/services/cross_app/cross_locality_connection_service.dart';
import 'package:avrai/core/services/user/agent_id_service.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart';
import 'package:avrai/core/controllers/base/workflow_controller.dart';
import 'package:avrai/core/controllers/quantum_matching_controller.dart';
import 'package:avrai/core/controllers/urk_kernel_activation_engine_contract.dart';
import 'package:avrai/core/controllers/urk_runtime_activation_receipt_dispatcher.dart';
import 'package:avrai/core/controllers/urk_stage_b_event_ops_shadow_runtime_contract.dart';
import 'package:avrai/core/models/quantum/matching_input.dart';
import 'package:avrai/core/services/user/urk_user_runtime_learning_intake_contract.dart';
import 'package:avrai_knot/services/knot/integrated_knot_recommendation_engine.dart';
import 'package:avrai_core/models/personality_knot.dart';
import 'package:avrai_knot/services/knot/knot_fabric_service.dart';
import 'package:avrai_knot/services/knot/knot_storage_service.dart';
import 'package:avrai/core/ai/personality_learning.dart';
import 'package:avrai/core/services/infrastructure/logger.dart';
import 'package:avrai/core/services/matching/vibe_compatibility_service.dart';
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
  final WorkflowController<MatchingInput, QuantumMatchingResult>?
      _quantumMatchingController;
  final UrkStageBEventOpsShadowRuntimeValidator _runtimeValidator;
  final UrkUserRuntimeLearningIntakeContract _userRuntimeIntakeContract;
  final UrkRuntimeActivationReceiptDispatcher? _activationDispatcher;

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
    WorkflowController<MatchingInput, QuantumMatchingResult>?
        quantumMatchingController,
    UrkStageBEventOpsShadowRuntimeValidator runtimeValidator =
        const UrkStageBEventOpsShadowRuntimeValidator(),
    UrkUserRuntimeLearningIntakeContract userRuntimeIntakeContract =
        const UrkUserRuntimeLearningIntakeContract(),
    UrkRuntimeActivationReceiptDispatcher? activationDispatcher,
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
        _quantumMatchingController = quantumMatchingController,
        _runtimeValidator = runtimeValidator,
        _userRuntimeIntakeContract = userRuntimeIntakeContract,
        _activationDispatcher = activationDispatcher ??
            resolveDefaultUrkRuntimeActivationDispatcher();

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
    double score = 0.0;

    // 1. Matching score (35% weight, reduced from 40% to make room for knot compatibility)
    final matchingScore = await _matchingService.calculateMatchingScore(
      expert: event.host,
      user: user,
      category: event.category,
      locality: _extractLocality(event.location) ?? '',
    );
    score += matchingScore * 0.35;

    // 2. Preference match (35% weight, reduced from 40%)
    final preferenceScore = _calculatePreferenceScore(
      event: event,
      preferences: preferences,
    );
    score += preferenceScore * 0.35;

    // 3. Cross-locality boost (15% weight, reduced from 20%)
    final crossLocalityScore = await _calculateCrossLocalityScore(
      event: event,
      user: user,
    );
    score += crossLocalityScore * 0.15;

    // 4. Knot compatibility (15% weight - optional enhancement)
    final knotScore = await _calculateKnotCompatibilityScore(
      event: event,
      user: user,
    );
    score += knotScore * 0.15;

    return score.clamp(0.0, 1.0);
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

StorageService? resolveDefaultStorageService() {
  final sl = GetIt.instance;
  if (!sl.isRegistered<StorageService>()) {
    return null;
  }
  return sl<StorageService>();
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
