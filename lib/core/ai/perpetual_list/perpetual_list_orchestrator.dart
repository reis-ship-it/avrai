import 'dart:developer' as developer;

import 'package:avrai/core/ai/memory/episodic/episodic_memory_store.dart';
import 'package:avrai/core/ai/memory/episodic/episodic_tuple.dart';
import 'package:avrai/core/ai/memory/episodic/outcome_taxonomy.dart';
import 'package:avrai/core/services/user/agent_id_service.dart';

import 'models/models.dart';
import 'engines/trigger_engine.dart';
import 'engines/context_engine.dart';
import 'engines/generation_engine.dart';
import 'analyzers/location_pattern_analyzer.dart';
import 'analyzers/string_theory_possibility_engine.dart';
import 'filters/age_aware_list_filter.dart';
import 'integration/ai2ai_list_learning_integration.dart';

/// Perpetual List Orchestrator
///
/// Main coordinator that ties all components together to generate
/// personalized list suggestions for users.
///
/// Generates 1-3 lists per day based on:
/// - User personality and preferences
/// - AI2AI network insights
/// - Visit patterns with atomic timing
/// - String theory possibility matching
///
/// Respects all safeguards:
/// - 8-hour minimum interval between generations
/// - Max 3 lists per day
/// - Age-appropriate filtering
/// - AI2AI learning rate limits
/// - 30% max personality drift
///
/// Part of Phase 9: Perpetual List Orchestrator

class PerpetualListOrchestrator {
  static const String _logName = 'PerpetualListOrchestrator';

  // Engines
  final TriggerEngine _triggerEngine;
  final ContextEngine _contextEngine;
  final GenerationEngine _generationEngine;

  // Analyzers
  final LocationPatternAnalyzer _locationAnalyzer;
  final StringTheoryPossibilityEngine _possibilityEngine;

  // Filters
  final AgeAwareListFilter _ageFilter;

  // Integration
  final AI2AIListLearningIntegration _ai2aiIntegration;
  final EpisodicMemoryStore? _episodicMemoryStore;
  final AgentIdService? _agentIdService;
  final OutcomeTaxonomy _outcomeTaxonomy;

  // State tracking
  final Map<String, List<SuggestedList>> _recentSuggestions = {};
  final Map<String, DateTime> _lastGenerationTime = {};

  PerpetualListOrchestrator({
    required TriggerEngine triggerEngine,
    required ContextEngine contextEngine,
    required GenerationEngine generationEngine,
    required LocationPatternAnalyzer locationAnalyzer,
    required StringTheoryPossibilityEngine possibilityEngine,
    required AgeAwareListFilter ageFilter,
    required AI2AIListLearningIntegration ai2aiIntegration,
    EpisodicMemoryStore? episodicMemoryStore,
    AgentIdService? agentIdService,
  })  : _triggerEngine = triggerEngine,
        _contextEngine = contextEngine,
        _generationEngine = generationEngine,
        _locationAnalyzer = locationAnalyzer,
        _possibilityEngine = possibilityEngine,
        _ageFilter = ageFilter,
        _ai2aiIntegration = ai2aiIntegration,
        _episodicMemoryStore = episodicMemoryStore,
        _agentIdService = agentIdService,
        _outcomeTaxonomy = const OutcomeTaxonomy();

  /// Generate lists if appropriate based on current context
  ///
  /// This is the main entry point for list generation.
  /// Evaluates triggers and generates personalized lists.
  ///
  /// [userId] - User to generate lists for
  /// [userAge] - User's age for filtering
  /// [triggerContext] - Current trigger context
  ///
  /// Returns list of suggested lists (may be empty if triggers not met)
  Future<List<SuggestedList>> generateListsIfAppropriate({
    required String userId,
    required int userAge,
    required TriggerContext triggerContext,
  }) async {
    developer.log(
      'Evaluating list generation for user: $userId',
      name: _logName,
    );

    // 1. Check triggers
    final decision = await _triggerEngine.shouldGenerateLists(
      userId: userId,
      context: triggerContext,
    );

    if (!decision.shouldGenerate) {
      developer.log(
        'Skipping generation: ${decision.skipReason}',
        name: _logName,
      );
      return [];
    }

    developer.log(
      'Trigger decision: generate ${decision.suggestedListCount} lists',
      name: _logName,
    );

    // 2. Build context
    final context = await _contextEngine.buildContext(
      userId: userId,
      userAge: userAge,
    );

    // 3. Generate possibility space
    final possibilities = await _possibilityEngine.generatePossibilitySpace(
      context: context,
    );

    // Store possibilities for later collapse
    _ai2aiIntegration.recordPossibilities(
      userId: userId,
      possibilities: possibilities,
    );

    // 4. Generate and score candidates
    List<SuggestedList> lists;

    if (context.isColdStart) {
      // Cold start: use simpler generation
      developer.log(
        'Cold start detected, using simplified generation',
        name: _logName,
      );

      lists = await _generationEngine.generateColdStartLists(
        context: context,
        listCount: decision.suggestedListCount,
        triggerReasons: decision.reasons.map((r) => r.name).toList(),
      );
    } else {
      // Full generation with quantum matching
      final candidates = await _generationEngine.generateCandidates(
        context: context,
        possibilities: possibilities,
      );

      // 5. Filter by age
      final filteredCandidates = _ageFilter.filterByAge(
        candidates: candidates,
        userAge: userAge,
        userOptInCategories: context.userOptInCategories,
      );

      // 6. Group into lists
      lists = _generationEngine.groupIntoLists(
        candidates: filteredCandidates,
        listCount: decision.suggestedListCount,
        triggerReasons: decision.reasons.map((r) => r.name).toList(),
      );
    }

    // 7. Validate lists for age restrictions
    final validatedLists = <SuggestedList>[];
    for (final list in lists) {
      final validation = _ageFilter.validateListForAge(
        list: list,
        userAge: userAge,
      );

      if (validation.isValid) {
        validatedLists.add(list);
      } else {
        developer.log(
          'List "${list.title}" failed validation: ${validation.violationMessages}',
          name: _logName,
        );
      }
    }

    // 8. Record this generation
    _recordGeneration(userId, validatedLists);

    developer.log(
      'Generated ${validatedLists.length} lists for user: $userId',
      name: _logName,
    );

    return validatedLists;
  }

  /// Record a visit for a user (delegates to location analyzer)
  ///
  /// [userId] - User who visited
  /// [latitude] - Latitude of visit
  /// [longitude] - Longitude of visit
  /// [dwellTime] - How long they stayed
  /// [groupSize] - Estimated group size
  Future<VisitPattern> recordVisit({
    required String userId,
    required double latitude,
    required double longitude,
    required Duration dwellTime,
    int? groupSize,
  }) async {
    return await _locationAnalyzer.recordVisit(
      userId: userId,
      latitude: latitude,
      longitude: longitude,
      dwellTime: dwellTime,
      groupSize: groupSize,
    );
  }

  /// Process a list interaction
  ///
  /// Feeds interaction back into learning system.
  ///
  /// [userId] - User who interacted
  /// [userAge] - User's age
  /// [interaction] - The interaction
  Future<void> processListInteraction({
    required String userId,
    required int userAge,
    required ListInteraction interaction,
  }) async {
    await _ai2aiIntegration.learnFromListInteraction(
      userId: userId,
      userAge: userAge,
      interaction: interaction,
    );

    await _recordListInteractionEpisode(
      userId: userId,
      userAge: userAge,
      interaction: interaction,
    );
  }

  /// Get recent suggestions for a user
  List<SuggestedList> getRecentSuggestions(String userId) {
    return _recentSuggestions[userId] ?? [];
  }

  /// Get time until next generation is allowed
  Duration? getTimeUntilNextGeneration(String userId) {
    return _triggerEngine.getTimeUntilNextGeneration(userId);
  }

  /// Get remaining lists for today
  int getRemainingListsToday(String userId) {
    return _triggerEngine.getRemainingListsToday(userId);
  }

  /// Build trigger context for evaluation
  ///
  /// Helper method to build TriggerContext from current state.
  Future<TriggerContext> buildTriggerContext({
    required String userId,
    LocationChange? locationChange,
  }) async {
    // Get recent engagement metrics
    final recentSuggestions = _recentSuggestions[userId] ?? [];
    final recentInteractions =
        <ListInteraction>[]; // Would be populated from storage

    final engagement = ListHistory(
      recentSuggestions: recentSuggestions,
      recentInteractions: recentInteractions,
    ).calculateEngagement();

    // Get AI2AI insights
    final insights = await _ai2aiIntegration.getFilteredInsights(
      userId: userId,
      userAge: 18, // Minimum age assumption
    );

    final insightSummaries = insights
        .map((i) => AI2AIInsightSummary(
              quality: i.learningQuality,
              type: i.type.name,
              receivedAt: i.timestamp,
            ))
        .toList();

    // Calculate time since last generation
    Duration? timeSinceLastGeneration;
    final lastGen = _lastGenerationTime[userId];
    if (lastGen != null) {
      timeSinceLastGeneration = DateTime.now().difference(lastGen);
    }

    // Get lists generated today
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final listsGeneratedToday = recentSuggestions
        .where((l) => l.generatedAt.isAfter(todayStart))
        .length;

    return TriggerContext(
      localTime: DateTime.now(),
      locationChange: locationChange,
      recentAI2AIInsights: insightSummaries,
      personalityDrift: 0.0, // Would be calculated from personality service
      recentListEngagement: engagement,
      timeSinceLastGeneration: timeSinceLastGeneration,
      listsGeneratedToday: listsGeneratedToday,
    );
  }

  /// Record a generation
  void _recordGeneration(String userId, List<SuggestedList> lists) {
    _recentSuggestions[userId] = [
      ...lists,
      ...(_recentSuggestions[userId] ?? []).take(10), // Keep last 10
    ];
    _lastGenerationTime[userId] = DateTime.now();
  }

  /// Clear state for a user (for testing or reset)
  void clearUserState(String userId) {
    _recentSuggestions.remove(userId);
    _lastGenerationTime.remove(userId);
    _triggerEngine.clearUserState(userId);
    _ai2aiIntegration.clearPossibilities(userId);
  }

  Future<void> _recordListInteractionEpisode({
    required String userId,
    required int userAge,
    required ListInteraction interaction,
  }) async {
    final episodicStore = _episodicMemoryStore;
    if (episodicStore == null) return;

    try {
      final agentResolution = await _resolveAgentId(userId);
      final agentId = agentResolution.agentId;
      final interactionPayload = interaction.toJson();
      final outcomeSignal = _outcomeTaxonomy.classify(
        eventType: 'list_${interaction.type.name}',
        parameters: {
          ...interactionPayload,
          'is_positive': interaction.isPositive,
          'is_negative': interaction.isNegative,
        },
      );

      final tuple = EpisodicTuple(
        agentId: agentId,
        stateBefore: {
          'user_id': userId,
          'agent_id': agentId,
          'user_age': userAge,
          'list_id': interaction.listId,
          'interaction_type': interaction.type.name,
        },
        actionType: 'list_${interaction.type.name}',
        actionPayload: interactionPayload,
        nextState: {
          'user_id': userId,
          'agent_id': agentId,
          'user_age': userAge,
          'list_id': interaction.listId,
          'interaction_type': interaction.type.name,
          'is_positive': interaction.isPositive,
          'is_negative': interaction.isNegative,
          'involved_place_count': interaction.involvedPlaces.length,
        },
        outcome: outcomeSignal,
        recordedAt: interaction.timestamp.toUtc(),
        metadata: {
          'pipeline': 'perpetual_list_orchestrator',
          'phase_ref': '1.2.7',
          'agent_id_source': agentResolution.source,
        },
      );
      await episodicStore.writeTuple(tuple);
    } catch (e) {
      developer.log(
        'Failed to persist list interaction episodic tuple: $e',
        name: _logName,
      );
    }
  }

  Future<({String agentId, String source})> _resolveAgentId(
      String userId) async {
    final agentIdService = _agentIdService;
    if (agentIdService == null) {
      return (agentId: userId, source: 'user_id_fallback');
    }

    try {
      final agentId = await agentIdService.getUserAgentId(userId);
      return (agentId: agentId, source: 'agent_id_service');
    } catch (e) {
      developer.log(
        'AgentIdService failed for user $userId, falling back to userId: $e',
        name: _logName,
      );
      return (agentId: userId, source: 'user_id_fallback');
    }
  }
}
