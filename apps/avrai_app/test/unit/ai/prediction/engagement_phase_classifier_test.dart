// Engagement Phase Classifier Tests
//
// Phase 1.5E: Beta Markov Engagement Predictor
//
// Validates the rule-based classification logic that maps PersonalityProfile
// signals into UserEngagementPhase macro-states. These phases gate the Markov
// chain and are the primary input to proactive outreach decisions.

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_runtime_os/services/prediction/engagement_phase_classifier.dart';
import 'package:avrai_runtime_os/services/prediction/engagement_phase_predictor.dart';

// ignore: avoid_relative_lib_imports
import '../../../helpers/personality_profile_test_factory.dart';

void main() {
  group('EngagementPhaseClassifier', () {
    late EngagementPhaseClassifier classifier;
    late PersonalityProfile baseProfile;

    setUp(() {
      classifier = EngagementPhaseClassifier();
      baseProfile = PersonalityProfileTestFactory.minimal();
    });

    // -------------------------------------------------------------------------
    // Churning detection (7+ days inactive) — must fire before quiet period
    // -------------------------------------------------------------------------
    group('churning classification', () {
      test(
        'classifies as churning when inactive for exactly 7 days',
        () {
          final phase = classifier.classify(
            baseProfile,
            totalInteractions: 50,
            daysSinceLastActivity: 7,
          );
          expect(phase, equals(UserEngagementPhase.churning));
        },
      );

      test(
        'classifies as churning even when engagement ratio is high (inactivity wins)',
        () {
          final phase = classifier.classify(
            baseProfile,
            totalInteractions: 100,
            communitiesJoined: 5,
            connectionCount: 10,
            daysSinceLastActivity: 14,
            recentEngagementRatio: 1.5,
          );
          expect(phase, equals(UserEngagementPhase.churning));
        },
      );

      test(
        'does NOT classify as churning when inactive for only 6 days',
        () {
          final phase = classifier.classify(
            baseProfile,
            totalInteractions: 50,
            daysSinceLastActivity: 6,
          );
          expect(phase, isNot(equals(UserEngagementPhase.churning)));
        },
      );
    });

    // -------------------------------------------------------------------------
    // Onboarding detection (< 5 interactions)
    // -------------------------------------------------------------------------
    group('onboarding classification', () {
      test(
        'classifies as onboarding with 0 interactions',
        () {
          final phase = classifier.classify(
            baseProfile,
            totalInteractions: 0,
          );
          expect(phase, equals(UserEngagementPhase.onboarding));
        },
      );

      test(
        'classifies as onboarding with 4 interactions (threshold is 5)',
        () {
          final phase = classifier.classify(
            baseProfile,
            totalInteractions: 4,
          );
          expect(phase, equals(UserEngagementPhase.onboarding));
        },
      );

      test(
        'does NOT classify as onboarding with 5 or more interactions',
        () {
          final phase = classifier.classify(
            baseProfile,
            totalInteractions: 5,
          );
          expect(phase, isNot(equals(UserEngagementPhase.onboarding)));
        },
      );
    });

    // -------------------------------------------------------------------------
    // Quiet period (engagement ratio dropped below 30% of baseline)
    // -------------------------------------------------------------------------
    group('quietPeriod classification', () {
      test(
        'classifies as quietPeriod when engagement ratio < 0.3 for established user',
        () {
          final phase = classifier.classify(
            baseProfile,
            totalInteractions: 20,
            recentEngagementRatio: 0.2,
          );
          expect(phase, equals(UserEngagementPhase.quietPeriod));
        },
      );

      test(
        'does NOT classify as quietPeriod for onboarding users even if ratio drops',
        () {
          // Only 3 interactions → still onboarding, quiet period gate doesn't apply
          final phase = classifier.classify(
            baseProfile,
            totalInteractions: 3,
            recentEngagementRatio: 0.1,
          );
          expect(phase, equals(UserEngagementPhase.onboarding));
        },
      );
    });

    // -------------------------------------------------------------------------
    // Embedding (deep returning engagement)
    // -------------------------------------------------------------------------
    group('embedding classification', () {
      test(
        'classifies as embedding when user has communities, connections, '
        'high confidence, and strong recent engagement',
        () {
          final highConfidenceProfile =
              PersonalityProfileTestFactory.withConfidence(0.8);
          final phase = classifier.classify(
            highConfidenceProfile,
            totalInteractions: 50,
            communitiesJoined: 3,
            connectionCount: 2,
            recentEngagementRatio: 0.9,
          );
          expect(phase, equals(UserEngagementPhase.embedding));
        },
      );

      test(
        'does NOT classify as embedding without connections even if other signals pass',
        () {
          final highConfidenceProfile =
              PersonalityProfileTestFactory.withConfidence(0.8);
          final phase = classifier.classify(
            highConfidenceProfile,
            totalInteractions: 50,
            communitiesJoined: 3,
            connectionCount: 0, // no connections
            recentEngagementRatio: 0.9,
          );
          expect(phase, isNot(equals(UserEngagementPhase.embedding)));
        },
      );
    });

    // -------------------------------------------------------------------------
    // Connecting (joined communities or made connections but not embedding)
    // -------------------------------------------------------------------------
    group('connecting classification', () {
      test(
        'classifies as connecting when 2+ communities joined with sufficient interactions',
        () {
          final phase = classifier.classify(
            baseProfile,
            totalInteractions: 20,
            communitiesJoined: 2,
            connectionCount: 0,
            recentEngagementRatio: 0.8,
          );
          expect(phase, equals(UserEngagementPhase.connecting));
        },
      );

      test(
        'classifies as connecting when at least one AI2AI connection formed',
        () {
          final phase = classifier.classify(
            baseProfile,
            totalInteractions: 10,
            communitiesJoined: 0,
            connectionCount: 1,
            recentEngagementRatio: 1.0,
          );
          expect(phase, equals(UserEngagementPhase.connecting));
        },
      );
    });

    // -------------------------------------------------------------------------
    // Exploring (sufficient interactions, but not yet committing)
    // -------------------------------------------------------------------------
    group('exploring classification', () {
      test(
        'classifies as exploring when sufficient interactions but no communities or connections',
        () {
          final phase = classifier.classify(
            baseProfile,
            totalInteractions: 10,
            communitiesJoined: 0,
            connectionCount: 0,
            recentEngagementRatio: 1.0,
          );
          expect(phase, equals(UserEngagementPhase.exploring));
        },
      );
    });

    // -------------------------------------------------------------------------
    // Signal extraction from PersonalityProfile.learningHistory
    // -------------------------------------------------------------------------
    group('extractSignals', () {
      test(
        'extracts all fields from learningHistory correctly',
        () {
          final profile = PersonalityProfileTestFactory.withLearningHistory({
            'total_interactions': 42,
            'communities_joined': 3,
            'connection_count': 7,
            'days_since_last_activity': 2,
            'recent_engagement_ratio': 0.85,
          });

          final signals = classifier.extractSignals(profile);

          expect(signals.totalInteractions, equals(42));
          expect(signals.communitiesJoined, equals(3));
          expect(signals.connectionCount, equals(7));
          expect(signals.daysSinceLastActivity, equals(2));
          expect(signals.recentEngagementRatio, closeTo(0.85, 0.001));
        },
      );

      test(
        'falls back to safe defaults when learningHistory is empty',
        () {
          final signals = classifier.extractSignals(baseProfile);

          expect(signals.totalInteractions, equals(0));
          expect(signals.communitiesJoined, equals(0));
          expect(signals.connectionCount, equals(0));
          expect(signals.daysSinceLastActivity, equals(0));
          expect(signals.recentEngagementRatio, equals(1.0));
        },
      );

      test(
        'classifyFromProfile produces same result as classify with extracted signals',
        () {
          final profile = PersonalityProfileTestFactory.withLearningHistory({
            'total_interactions': 20,
            'communities_joined': 2,
            'connection_count': 1,
            'days_since_last_activity': 0,
            'recent_engagement_ratio': 0.9,
          });

          final fromProfile = classifier.classifyFromProfile(profile);
          final signals = classifier.extractSignals(profile);
          final fromSignals = classifier.classify(
            profile,
            totalInteractions: signals.totalInteractions,
            communitiesJoined: signals.communitiesJoined,
            connectionCount: signals.connectionCount,
            daysSinceLastActivity: signals.daysSinceLastActivity,
            recentEngagementRatio: signals.recentEngagementRatio,
          );

          expect(fromProfile, equals(fromSignals));
        },
      );
    });
  });
}
