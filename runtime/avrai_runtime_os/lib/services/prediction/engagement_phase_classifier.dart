// Engagement Phase Classifier
//
// Phase 1.5E: Beta Markov Engagement Predictor (Bridge to Phase 5)
//
// Classifies a PersonalityProfile + interaction signals into a UserEngagementPhase.
// Rule-based over fields already present in PersonalityProfile and learning history.
// No ML required — the classifier feeds the Markov chain, which learns from it.
//
// See: MASTER_PLAN.md Phase 1.5E

import 'dart:developer' as developer;

import 'package:avrai_core/models/personality_profile.dart';

import 'engagement_phase_predictor.dart';

/// Classifies a [PersonalityProfile] and associated interaction signals
/// into a [UserEngagementPhase] macro-state.
///
/// Uses rule-based thresholds over fields already present in [PersonalityProfile]
/// and its [learningHistory]. Designed to be fast (synchronous, no I/O) so it
/// can be called inline inside [PersonalityLearning.evolveFromUserAction].
class EngagementPhaseClassifier {
  static const String _logName = 'EngagementPhaseClassifier';

  // Thresholds — calibrated to the swarm simulation archetype distributions.
  // These are conservative starting values; behavior from beta users will
  // reveal whether they need adjustment.
  static const int _onboardingInteractionThreshold = 5;
  static const int _exploringCommunityThreshold = 2;
  static const double _quietPeriodEngagementDrop = 0.3;
  static const int _churningInactiveDays = 7;

  /// Classifies the user's current engagement phase from their personality
  /// profile and optional supplementary signals.
  ///
  /// **Parameters:**
  /// - [profile]: Current personality profile
  /// - [totalInteractions]: Total meaningful interactions (from learning history)
  /// - [communitiesJoined]: Number of communities joined
  /// - [connectionCount]: AI2AI connections established
  /// - [daysSinceLastActivity]: Days since any meaningful activity
  /// - [recentEngagementRatio]: Ratio of recent to average engagement (0.0–1.0+)
  UserEngagementPhase classify(
    PersonalityProfile profile, {
    int totalInteractions = 0,
    int communitiesJoined = 0,
    int connectionCount = 0,
    int daysSinceLastActivity = 0,
    double recentEngagementRatio = 1.0,
  }) {
    developer.log(
      'Classifying engagement phase: interactions=$totalInteractions, '
      'communities=$communitiesJoined, connections=$connectionCount, '
      'daysSince=$daysSinceLastActivity, engagementRatio=$recentEngagementRatio',
      name: _logName,
    );

    // Churning: no meaningful activity for 7+ days (most urgent — check first)
    if (daysSinceLastActivity >= _churningInactiveDays) {
      return UserEngagementPhase.churning;
    }

    // Quiet period: engagement dropped significantly below their own baseline
    if (recentEngagementRatio < _quietPeriodEngagementDrop &&
        totalInteractions > _onboardingInteractionThreshold) {
      return UserEngagementPhase.quietPeriod;
    }

    // Onboarding: too few interactions to have a meaningful personal model
    if (totalInteractions < _onboardingInteractionThreshold) {
      return UserEngagementPhase.onboarding;
    }

    // Embedding: deep recurring engagement — return visits + stable personality
    // Profile is "stable" when evolution generation has slowed (high confidence,
    // low recent changes) and community/connection engagement is strong.
    final avgConfidence = _averageConfidence(profile);
    if (communitiesJoined >= _exploringCommunityThreshold &&
        avgConfidence > 0.6 &&
        connectionCount > 0 &&
        recentEngagementRatio >= 0.8) {
      return UserEngagementPhase.embedding;
    }

    // Connecting: building communities and connections, active engagement
    if (communitiesJoined >= _exploringCommunityThreshold ||
        connectionCount > 0) {
      return UserEngagementPhase.connecting;
    }

    // Exploring: sufficient interactions, actively using the app but not yet
    // committing to communities or connections
    return UserEngagementPhase.exploring;
  }

  /// Extracts classification signals from [PersonalityProfile.learningHistory].
  ///
  /// Returns a [_LearningSignals] struct with all fields the classifier needs.
  /// Falls back gracefully when learning history fields are absent (new users,
  /// migration from older profile versions).
  LearningSignals extractSignals(PersonalityProfile profile) {
    final history = profile.learningHistory;

    final totalInteractions = (history['total_interactions'] as int?) ?? 0;
    final communitiesJoined = (history['communities_joined'] as int?) ?? 0;
    final connectionCount = (history['connection_count'] as int?) ?? 0;
    final daysSinceLastActivity =
        (history['days_since_last_activity'] as int?) ?? 0;
    final recentEngagementRatio =
        (history['recent_engagement_ratio'] as double?) ?? 1.0;

    return LearningSignals(
      totalInteractions: totalInteractions,
      communitiesJoined: communitiesJoined,
      connectionCount: connectionCount,
      daysSinceLastActivity: daysSinceLastActivity,
      recentEngagementRatio: recentEngagementRatio,
    );
  }

  /// Convenience method: classify directly from a profile using embedded
  /// learning history signals. Used when no external signals are available.
  UserEngagementPhase classifyFromProfile(PersonalityProfile profile) {
    final signals = extractSignals(profile);
    return classify(
      profile,
      totalInteractions: signals.totalInteractions,
      communitiesJoined: signals.communitiesJoined,
      connectionCount: signals.connectionCount,
      daysSinceLastActivity: signals.daysSinceLastActivity,
      recentEngagementRatio: signals.recentEngagementRatio,
    );
  }

  double _averageConfidence(PersonalityProfile profile) {
    if (profile.dimensionConfidence.isEmpty) return 0.0;
    final total = profile.dimensionConfidence.values
        .fold<double>(0.0, (sum, v) => sum + v);
    return total / profile.dimensionConfidence.length;
  }
}

/// Engagement signals extracted from a personality profile's learning history.
class LearningSignals {
  final int totalInteractions;
  final int communitiesJoined;
  final int connectionCount;
  final int daysSinceLastActivity;
  final double recentEngagementRatio;

  const LearningSignals({
    required this.totalInteractions,
    required this.communitiesJoined,
    required this.connectionCount,
    required this.daysSinceLastActivity,
    required this.recentEngagementRatio,
  });
}
