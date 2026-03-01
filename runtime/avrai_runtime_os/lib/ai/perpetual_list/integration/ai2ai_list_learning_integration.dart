import 'dart:developer' as developer;

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:avrai_runtime_os/ai/personality_learning.dart'
    show PersonalityLearning, AI2AILearningInsight, AI2AIInsightType;
import 'package:avrai_core/utils/vibe_constants.dart';

import '../models/models.dart';
import '../analyzers/string_theory_possibility_engine.dart';
import '../filters/age_aware_list_filter.dart';

/// AI2AI List Learning Integration
///
/// Wires list interactions back into personality learning and AI2AI network.
/// Respects all existing safeguards (drift limits, learning rates, intervals).
///
/// Part of Phase 8: Perpetual List Orchestrator

class AI2AIListLearningIntegration {
  static const String _logName = 'AI2AIListLearningIntegration';

  /// Learning rate for list interactions (50% of AI2AI rate)
  /// AI2AI rate is 0.03, so list rate is 0.015
  static const double listInteractionLearningRate = 0.015;

  /// Minimum interaction quality to learn from
  static const double minInteractionQuality = 0.4;

  /// Rate limiting: Maximum learning events per user per hour
  static const int maxLearningEventsPerHour = 10;

  /// Rate limiting: Maximum learning events per user per day
  static const int maxLearningEventsPerDay = 50;

  /// Rate limiting: Cooldown between learning events (in seconds)
  static const int minSecondsBetweenEvents = 30;

  /// Never propagate learnings from these categories to network
  static final Set<String> neverPropagateCategoriesRaw = {
    'adult_entertainment',
    'sex_shops',
    'kink_venues',
    'cannabis_dispensaries',
    'hookah_lounges',
    'vape_shops',
  };

  final PersonalityLearning _personalityLearning;
  final StringTheoryPossibilityEngine _possibilityEngine;
  final AgeAwareListFilter _ageFilter;

  /// Track recent possibilities for collapse
  final Map<String, List<PossibilityState>> _recentPossibilities = {};

  /// Rate limiting: Track learning events per user
  /// Key: userId, Value: List of event timestamps
  final Map<String, List<DateTime>> _learningEventTimestamps = {};

  AI2AIListLearningIntegration({
    required PersonalityLearning personalityLearning,
    required StringTheoryPossibilityEngine possibilityEngine,
    required AgeAwareListFilter ageFilter,
  })  : _personalityLearning = personalityLearning,
        _possibilityEngine = possibilityEngine,
        _ageFilter = ageFilter;

  /// Store possibilities for a user (for later collapse)
  void recordPossibilities({
    required String userId,
    required List<PossibilityState> possibilities,
  }) {
    _recentPossibilities[userId] = possibilities;
  }

  /// Maximum users to track before cleanup
  static const int _maxTrackedUsers = 1000;

  /// Cleanup inactive users after this duration
  static const Duration _userInactivityThreshold = Duration(days: 7);

  /// Check if rate limit allows learning for this user
  ///
  /// Returns true if learning is allowed, false if rate limited
  bool _isRateLimitAllowed(String userId) {
    final now = DateTime.now();
    final oneHourAgo = now.subtract(const Duration(hours: 1));
    final oneDayAgo = now.subtract(const Duration(days: 1));

    // Cleanup inactive users if map is getting large
    if (_learningEventTimestamps.length > _maxTrackedUsers) {
      _cleanupInactiveUsers();
    }

    // Get or create timestamp list for user
    _learningEventTimestamps[userId] ??= [];
    final timestamps = _learningEventTimestamps[userId]!;

    // Clean old entries (older than 24 hours)
    timestamps.removeWhere((t) => t.isBefore(oneDayAgo));

    // Check cooldown between events
    if (timestamps.isNotEmpty) {
      final lastEvent = timestamps.last;
      final secondsSinceLastEvent = now.difference(lastEvent).inSeconds;
      if (secondsSinceLastEvent < minSecondsBetweenEvents) {
        developer.log(
          'Rate limited: cooldown not elapsed (${minSecondsBetweenEvents - secondsSinceLastEvent}s remaining)',
          name: _logName,
        );
        return false;
      }
    }

    // Check hourly limit
    final eventsInLastHour =
        timestamps.where((t) => t.isAfter(oneHourAgo)).length;
    if (eventsInLastHour >= maxLearningEventsPerHour) {
      developer.log(
        'Rate limited: hourly limit reached ($eventsInLastHour/$maxLearningEventsPerHour)',
        name: _logName,
      );
      return false;
    }

    // Check daily limit
    final eventsInLastDay =
        timestamps.where((t) => t.isAfter(oneDayAgo)).length;
    if (eventsInLastDay >= maxLearningEventsPerDay) {
      developer.log(
        'Rate limited: daily limit reached ($eventsInLastDay/$maxLearningEventsPerDay)',
        name: _logName,
      );
      return false;
    }

    return true;
  }

  /// Clean up inactive users to prevent memory leak
  void _cleanupInactiveUsers() {
    final cutoff = DateTime.now().subtract(_userInactivityThreshold);
    final usersToRemove = <String>[];

    for (final entry in _learningEventTimestamps.entries) {
      if (entry.value.isEmpty || entry.value.last.isBefore(cutoff)) {
        usersToRemove.add(entry.key);
      }
    }

    for (final userId in usersToRemove) {
      _learningEventTimestamps.remove(userId);
    }

    if (usersToRemove.isNotEmpty) {
      developer.log(
        'Cleaned up ${usersToRemove.length} inactive users from rate limit tracking',
        name: _logName,
      );
    }
  }

  /// Record a learning event for rate limiting
  void _recordLearningEvent(String userId) {
    _learningEventTimestamps[userId] ??= [];
    _learningEventTimestamps[userId]!.add(DateTime.now());
  }

  /// Get rate limit status for a user (for debugging/UI)
  @visibleForTesting
  Map<String, dynamic> getRateLimitStatus(String userId) {
    final now = DateTime.now();
    final oneHourAgo = now.subtract(const Duration(hours: 1));
    final oneDayAgo = now.subtract(const Duration(days: 1));

    final timestamps = _learningEventTimestamps[userId] ?? [];
    final eventsInLastHour =
        timestamps.where((t) => t.isAfter(oneHourAgo)).length;
    final eventsInLastDay =
        timestamps.where((t) => t.isAfter(oneDayAgo)).length;

    return {
      'eventsInLastHour': eventsInLastHour,
      'maxEventsPerHour': maxLearningEventsPerHour,
      'eventsInLastDay': eventsInLastDay,
      'maxEventsPerDay': maxLearningEventsPerDay,
      'isAllowed': _isRateLimitAllowed(userId),
    };
  }

  /// Learn from a list interaction
  ///
  /// Updates personality based on user's interaction with suggested lists.
  /// Respects drift limits, learning safeguards, and rate limits.
  ///
  /// [userId] - User who interacted
  /// [userAge] - User's age for filtering
  /// [interaction] - The interaction to learn from
  ///
  /// Returns whether learning was applied
  Future<bool> learnFromListInteraction({
    required String userId,
    required int userAge,
    required ListInteraction interaction,
  }) async {
    developer.log(
      'Learning from list interaction: ${interaction.type}',
      name: _logName,
    );

    // 0. Check rate limiting first
    if (!_isRateLimitAllowed(userId)) {
      developer.log(
        'Skipping learning: rate limited for user $userId',
        name: _logName,
      );
      return false;
    }

    // 1. Check if we should learn from this interaction
    if (!_shouldLearnFromInteraction(interaction, userAge)) {
      developer.log(
        'Skipping learning: interaction filtered',
        name: _logName,
      );
      return false;
    }

    // 2. Get recent possibilities for this user
    final possibilities = _recentPossibilities[userId];
    if (possibilities == null || possibilities.isEmpty) {
      developer.log(
        'Skipping learning: no possibilities recorded',
        name: _logName,
      );
      return false;
    }

    // 3. Collapse possibility space based on observation
    final collapseResult = await _possibilityEngine.collapseFromObservation(
      interaction: interaction,
      previousPossibilities: possibilities,
    );

    // 4. Check if interaction quality is sufficient
    if (collapseResult.matchScore < minInteractionQuality) {
      developer.log(
        'Skipping learning: match score too low (${collapseResult.matchScore})',
        name: _logName,
      );
      return false;
    }

    // 5. Apply dimension updates to personality (with reduced learning rate)
    final scaledUpdates =
        _scaleLearningUpdates(collapseResult.dimensionUpdates);

    if (scaledUpdates.isNotEmpty) {
      // Use evolveFromAI2AILearning for learning from list interactions
      final insight = AI2AILearningInsight(
        type: _interactionToInsightType(interaction),
        dimensionInsights: scaledUpdates,
        learningQuality: collapseResult.matchScore * 0.5, // 50% reduced quality
        timestamp: DateTime.now(),
      );

      await _personalityLearning.evolveFromAI2AILearning(userId, insight);

      developer.log(
        'Applied personality updates: ${scaledUpdates.keys.toList()}',
        name: _logName,
      );
    }

    // 6. Propagate to AI2AI network (if appropriate)
    await _propagateToNetwork(
      userId: userId,
      userAge: userAge,
      interaction: interaction,
      collapseResult: collapseResult,
    );

    // 7. Record learning event for rate limiting
    _recordLearningEvent(userId);

    return true;
  }

  /// Process batch of interactions for a user
  Future<int> processInteractions({
    required String userId,
    required int userAge,
    required List<ListInteraction> interactions,
  }) async {
    int processedCount = 0;

    for (final interaction in interactions) {
      final learned = await learnFromListInteraction(
        userId: userId,
        userAge: userAge,
        interaction: interaction,
      );

      if (learned) processedCount++;
    }

    developer.log(
      'Processed $processedCount/${interactions.length} interactions',
      name: _logName,
    );

    return processedCount;
  }

  /// Get AI2AI insights filtered by age
  ///
  /// Returns insights that are appropriate for the user's age.
  /// Note: Currently returns empty list as AI2AI insights are processed
  /// through the main AI2AI learning pipeline.
  Future<List<AI2AILearningInsight>> getFilteredInsights({
    required String userId,
    required int userAge,
  }) async {
    // AI2AI insights are now processed through the main AI2AI learning system
    // List interactions are fed back through personality learning directly
    return [];
  }

  /// Check if we should learn from this interaction
  bool _shouldLearnFromInteraction(ListInteraction interaction, int userAge) {
    // Skip neutral interactions
    if (interaction.isNeutral) return false;

    // Check if involved places have age-restricted categories
    for (final place in interaction.involvedPlaces) {
      final category = place.category.toLowerCase();

      // Never learn from sensitive categories
      if (_ageFilter.requiresOptIn(category)) {
        return false;
      }

      // Check age restrictions
      final ageRequirement = _ageFilter.getAgeRequirement(category);
      if (ageRequirement != null && userAge < ageRequirement) {
        return false;
      }
    }

    return true;
  }

  /// Scale learning updates by our reduced rate
  Map<String, double> _scaleLearningUpdates(Map<String, double> updates) {
    // Apply our 50% reduced rate
    return updates.map(
      (key, value) => MapEntry(
          key,
          value *
              (listInteractionLearningRate / VibeConstants.ai2aiLearningRate)),
    );
  }

  /// Convert interaction to AI2AI insight type for personality learning
  AI2AIInsightType _interactionToInsightType(ListInteraction interaction) {
    switch (interaction.type) {
      case ListInteractionType.saved:
      case ListInteractionType.placeVisited:
      case ListInteractionType.addedToCollection:
        return AI2AIInsightType.patternRecognition;
      case ListInteractionType.dismissed:
        return AI2AIInsightType.dimensionDiscovery;
      case ListInteractionType.shared:
        return AI2AIInsightType.communityInsight;
      case ListInteractionType.viewed:
        return AI2AIInsightType.compatibilityLearning;
    }
  }

  /// Propagate learning to AI2AI network (if appropriate)
  Future<void> _propagateToNetwork({
    required String userId,
    required int userAge,
    required ListInteraction interaction,
    required PossibilityCollapseResult collapseResult,
  }) async {
    // Never propagate sensitive category learnings
    for (final place in interaction.involvedPlaces) {
      final category = place.category.toLowerCase();
      if (neverPropagateCategoriesRaw.any((c) => category.contains(c))) {
        developer.log(
          'Not propagating to network: sensitive category',
          name: _logName,
        );
        return;
      }
    }

    // Only propagate high-quality interactions
    if (collapseResult.matchScore < 0.6) {
      return;
    }

    // Note: AI2AI network propagation is handled through the existing
    // AI2AILearningOrchestrator's chat event processing.
    // For list interactions, we log the intent but actual propagation
    // happens through the mesh connection when users interact.
    developer.log(
      'List interaction ready for AI2AI propagation (via mesh)',
      name: _logName,
    );
  }

  /// Clear stored possibilities for a user
  void clearPossibilities(String userId) {
    _recentPossibilities.remove(userId);
  }
}
