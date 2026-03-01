import 'dart:developer' as developer;

import '../models/trigger_decision.dart';

/// Trigger Engine
///
/// Evaluates when to generate new lists based on event-driven triggers.
/// Uses safeguards to prevent over-generation while ensuring timely suggestions.
///
/// Part of Phase 4: Perpetual List Orchestrator

class TriggerEngine {
  static const String _logName = 'TriggerEngine';

  // Safeguard constants
  /// Minimum interval between list generations
  static const Duration minIntervalBetweenGenerations = Duration(hours: 8);

  /// Maximum number of lists that can be generated per day
  static const int maxListsPerDay = 3;

  /// Personality drift threshold that triggers regeneration (15%)
  static const double personalityDriftThreshold = 0.15;

  /// Minimum AI2AI insights needed to trigger generation
  static const int minAI2AIInsightsForTrigger = 3;

  /// Location change threshold in kilometers
  static const double significantLocationChangeKm = 5.0;

  /// Poor engagement threshold (80% dismiss rate)
  static const double poorEngagementThreshold = 0.80;

  // State tracking (per user)
  final Map<String, DateTime> _lastGenerationTime = {};
  final Map<String, int> _todayListCount = {};
  final Map<String, DateTime> _lastDayReset = {};

  /// Evaluate if we should generate new lists for a user
  ///
  /// [userId] - User to evaluate
  /// [context] - Trigger context with current state
  ///
  /// Returns TriggerDecision indicating whether to generate and why
  Future<TriggerDecision> shouldGenerateLists({
    required String userId,
    required TriggerContext context,
  }) async {
    developer.log(
      'Evaluating list generation triggers for user: $userId',
      name: _logName,
    );

    // Reset daily count if needed
    _resetDailyCountIfNeeded(userId);

    // Check safeguards first
    final safeguardCheck = _checkSafeguards(userId, context);
    if (!safeguardCheck.passed) {
      return TriggerDecision.skip(
        reason: safeguardCheck.reason!,
        metadata: {'safeguard': safeguardCheck.safeguardName},
      );
    }

    // Evaluate trigger conditions
    final triggers = <TriggerReason>[];
    final metadata = <String, dynamic>{};

    // 1. Check for cold start (new user)
    if (_isColdStart(context)) {
      triggers.add(TriggerReason.coldStart);
      metadata['isColdStart'] = true;
    }

    // 2. Time-based check-in
    if (_shouldTriggerTimeBasedCheckin(context)) {
      triggers.add(TriggerReason.dailyCheckIn);
      metadata['timeWindow'] =
          context.isInMorningWindow ? 'morning' : 'evening';
    }

    // 3. Location change
    if (_shouldTriggerLocationChange(context)) {
      triggers.add(TriggerReason.significantLocationChange);
      metadata['locationChange'] = {
        'distanceKm': context.locationChange?.distanceKm,
        'isNewLocality': context.locationChange?.isNewLocality,
      };
    }

    // 4. AI2AI network insights
    if (_shouldTriggerAI2AILearning(context)) {
      triggers.add(TriggerReason.ai2aiNetworkLearning);
      metadata['highQualityInsights'] =
          context.recentAI2AIInsights.where((i) => i.isHighQuality).length;
    }

    // 5. Personality drift
    if (_shouldTriggerPersonalityDrift(context)) {
      triggers.add(TriggerReason.personalityEvolution);
      metadata['personalityDrift'] = context.personalityDrift;
    }

    // 6. Poor engagement correction
    if (_shouldTriggerEngagementCorrection(context)) {
      triggers.add(TriggerReason.poorEngagementCorrection);
      metadata['dismissRate'] = context.recentListEngagement.dismissRate;
    }

    // No triggers fired
    if (triggers.isEmpty) {
      return TriggerDecision.skip(
        reason: 'No trigger conditions met',
        metadata: metadata,
      );
    }

    // Calculate priority
    final priority = _calculatePriority(triggers);

    // Calculate suggested list count
    final suggestedListCount = _calculateListCount(triggers, context);

    // Record this generation
    _recordGeneration(userId);

    developer.log(
      'Trigger decision: GENERATE (${triggers.length} reasons, $suggestedListCount lists)',
      name: _logName,
    );

    return TriggerDecision.generate(
      reasons: triggers,
      priority: priority,
      suggestedListCount: suggestedListCount,
      metadata: metadata,
    );
  }

  /// Check all safeguards
  SafeguardResult _checkSafeguards(String userId, TriggerContext context) {
    // Check minimum interval
    final lastGen = _lastGenerationTime[userId];
    if (lastGen != null) {
      final timeSinceLast = DateTime.now().difference(lastGen);
      if (timeSinceLast < minIntervalBetweenGenerations) {
        final remaining = minIntervalBetweenGenerations - timeSinceLast;
        return SafeguardResult.failed(
          'minimum_interval',
          'Too soon since last generation (${remaining.inHours}h ${remaining.inMinutes % 60}m remaining)',
        );
      }
    }

    // Check daily limit
    final todayCount = _todayListCount[userId] ?? 0;
    if (todayCount >= maxListsPerDay) {
      return SafeguardResult.failed(
        'daily_limit',
        'Daily list limit reached ($maxListsPerDay lists)',
      );
    }

    return SafeguardResult.passed();
  }

  /// Check if this is a cold start (new user with no data)
  bool _isColdStart(TriggerContext context) {
    // No previous generation
    if (context.timeSinceLastGeneration == null) {
      return true;
    }
    // Very long time since last generation (over 30 days)
    if (context.timeSinceLastGeneration! > const Duration(days: 30)) {
      return true;
    }
    return false;
  }

  /// Check if time-based check-in should trigger
  bool _shouldTriggerTimeBasedCheckin(TriggerContext context) {
    // Must be in morning or evening window
    if (!context.isInMorningWindow && !context.isInEveningWindow) {
      return false;
    }

    // Must have no recent lists (within 1 day)
    if (context.timeSinceLastGeneration != null &&
        context.timeSinceLastGeneration! < const Duration(days: 1)) {
      return false;
    }

    return true;
  }

  /// Check if location change should trigger
  bool _shouldTriggerLocationChange(TriggerContext context) {
    if (context.locationChange == null) return false;
    return context.locationChange!.isSignificant;
  }

  /// Check if AI2AI network learning should trigger
  bool _shouldTriggerAI2AILearning(TriggerContext context) {
    if (context.recentAI2AIInsights.isEmpty) return false;

    final highQualityCount =
        context.recentAI2AIInsights.where((i) => i.isHighQuality).length;

    return highQualityCount >= minAI2AIInsightsForTrigger;
  }

  /// Check if personality drift should trigger
  bool _shouldTriggerPersonalityDrift(TriggerContext context) {
    return context.personalityDrift >= personalityDriftThreshold;
  }

  /// Check if poor engagement should trigger correction
  bool _shouldTriggerEngagementCorrection(TriggerContext context) {
    // Need at least 3 suggestions to evaluate engagement
    if (context.recentListEngagement.totalSuggested < 3) return false;

    return context.recentListEngagement.dismissRate >= poorEngagementThreshold;
  }

  /// Calculate trigger priority based on reasons
  TriggerPriority _calculatePriority(List<TriggerReason> triggers) {
    // Critical priority for corrections
    if (triggers.contains(TriggerReason.poorEngagementCorrection)) {
      return TriggerPriority.critical;
    }

    // High priority for significant events
    if (triggers.contains(TriggerReason.significantLocationChange) ||
        triggers.contains(TriggerReason.coldStart)) {
      return TriggerPriority.high;
    }

    // Medium priority for learning triggers
    if (triggers.contains(TriggerReason.ai2aiNetworkLearning) ||
        triggers.contains(TriggerReason.personalityEvolution)) {
      return TriggerPriority.medium;
    }

    return TriggerPriority.low;
  }

  /// Calculate suggested list count based on triggers
  int _calculateListCount(
      List<TriggerReason> triggers, TriggerContext context) {
    // Cold start or location change: 3 lists
    if (triggers.contains(TriggerReason.coldStart) ||
        triggers.contains(TriggerReason.significantLocationChange)) {
      return 3;
    }

    // AI2AI learning or personality evolution: 2 lists
    if (triggers.contains(TriggerReason.ai2aiNetworkLearning) ||
        triggers.contains(TriggerReason.personalityEvolution)) {
      return 2;
    }

    // Engagement correction: 2 lists (different approach)
    if (triggers.contains(TriggerReason.poorEngagementCorrection)) {
      return 2;
    }

    // Default: 1 list
    return 1;
  }

  /// Record that a generation was made
  void _recordGeneration(String userId) {
    _lastGenerationTime[userId] = DateTime.now();
    _todayListCount[userId] = (_todayListCount[userId] ?? 0) + 1;
  }

  /// Reset daily count if we're in a new day
  void _resetDailyCountIfNeeded(String userId) {
    final lastReset = _lastDayReset[userId];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (lastReset == null || lastReset.isBefore(today)) {
      _todayListCount[userId] = 0;
      _lastDayReset[userId] = today;
    }
  }

  /// Get time until next generation is allowed
  Duration? getTimeUntilNextGeneration(String userId) {
    final lastGen = _lastGenerationTime[userId];
    if (lastGen == null) return null;

    final timeSinceLast = DateTime.now().difference(lastGen);
    if (timeSinceLast >= minIntervalBetweenGenerations) return Duration.zero;

    return minIntervalBetweenGenerations - timeSinceLast;
  }

  /// Get remaining lists for today
  int getRemainingListsToday(String userId) {
    _resetDailyCountIfNeeded(userId);
    final todayCount = _todayListCount[userId] ?? 0;
    return maxListsPerDay - todayCount;
  }

  /// Clear state for a user (for testing or reset)
  void clearUserState(String userId) {
    _lastGenerationTime.remove(userId);
    _todayListCount.remove(userId);
    _lastDayReset.remove(userId);
  }
}

/// Result of safeguard check
class SafeguardResult {
  final bool passed;
  final String? safeguardName;
  final String? reason;

  const SafeguardResult._({
    required this.passed,
    this.safeguardName,
    this.reason,
  });

  factory SafeguardResult.passed() {
    return const SafeguardResult._(passed: true);
  }

  factory SafeguardResult.failed(String safeguardName, String reason) {
    return SafeguardResult._(
      passed: false,
      safeguardName: safeguardName,
      reason: reason,
    );
  }
}
