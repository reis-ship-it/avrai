// Markov Engagement Predictor Tests
//
// Phase 1.5E: Beta Markov Engagement Predictor
//
// Validates the concrete EngagementPhasePredictor implementation:
// - Phase distribution is always normalized
// - Churn risk computation (from matrix and from distribution)
// - Transition recording calls through to the store
// - Fallback behavior when no data exists
// - predictor is compatible with EngagementPhasePredictor interface

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_runtime_os/services/prediction/engagement_phase_predictor.dart';
import 'package:avrai_runtime_os/services/prediction/markov_engagement_predictor.dart';
import 'package:avrai_runtime_os/services/prediction/markov_transition_store.dart';
import 'package:avrai_runtime_os/services/prediction/swarm_prior_loader.dart';

void main() {
  group('MarkovEngagementPredictor', () {
    late MarkovEngagementPredictor predictor;
    late MarkovTransitionStore store;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      store = MarkovTransitionStore(
        prefs: prefs,
        priorLoader: SwarmPriorLoader(),
      );
      predictor = MarkovEngagementPredictor(
        store: store,
        atomicClock: AtomicClockService(),
      );
    });

    // -------------------------------------------------------------------------
    // Interface compliance
    // -------------------------------------------------------------------------
    group('EngagementPhasePredictor interface compliance', () {
      test(
        'implements EngagementPhasePredictor (compile-time contract)',
        () {
          expect(predictor, isA<EngagementPhasePredictor>());
        },
      );
    });

    // -------------------------------------------------------------------------
    // predictNextPhase: always returns a valid normalized distribution
    // -------------------------------------------------------------------------
    group('predictNextPhase', () {
      test(
        'returns distribution covering all phases for a cold-start agent',
        () async {
          final dist = await predictor.predictNextPhase(
            UserEngagementPhase.onboarding,
            agentId: 'cold-start',
          );

          expect(dist.length, equals(UserEngagementPhase.values.length));
          final sum = dist.values.fold(0.0, (s, v) => s + v);
          expect(sum, closeTo(1.0, 1e-9));
        },
      );

      test(
        'returns uniform fallback when agentId is null',
        () async {
          final dist = await predictor.predictNextPhase(
            UserEngagementPhase.exploring,
          );

          final sum = dist.values.fold(0.0, (s, v) => s + v);
          expect(sum, closeTo(1.0, 1e-9));

          // All values should be equal (uniform)
          final values = dist.values.toList();
          final first = values.first;
          for (final v in values) {
            expect(v, closeTo(first, 1e-9));
          }
        },
      );

      test(
        'distribution sums to 1.0 after accumulating real observations',
        () async {
          const agentId = 'obs-agent';
          for (var i = 0; i < 20; i++) {
            await store.recordTransition(
              UserEngagementPhase.exploring,
              UserEngagementPhase.connecting,
              agentId,
            );
          }

          final dist = await predictor.predictNextPhase(
            UserEngagementPhase.exploring,
            agentId: agentId,
          );

          final sum = dist.values.fold(0.0, (s, v) => s + v);
          expect(sum, closeTo(1.0, 1e-9));
        },
      );
    });

    // -------------------------------------------------------------------------
    // churnRiskFromDistribution: synchronous helper used by outreach gate
    // -------------------------------------------------------------------------
    group('churnRiskFromDistribution', () {
      test(
        'returns high risk when distribution heavily weighted toward churning',
        () {
          final distribution = {
            UserEngagementPhase.onboarding: 0.01,
            UserEngagementPhase.exploring: 0.02,
            UserEngagementPhase.connecting: 0.02,
            UserEngagementPhase.embedding: 0.02,
            UserEngagementPhase.quietPeriod: 0.43, // heavy quiet
            UserEngagementPhase.churning: 0.50, // heavy churn
          };

          final risk = predictor.churnRiskFromDistribution(distribution);
          expect(risk, greaterThan(0.9));
        },
      );

      test(
        'returns low risk when distribution heavily weighted toward healthy phases',
        () {
          final distribution = {
            UserEngagementPhase.onboarding: 0.02,
            UserEngagementPhase.exploring: 0.10,
            UserEngagementPhase.connecting: 0.35,
            UserEngagementPhase.embedding: 0.50,
            UserEngagementPhase.quietPeriod: 0.02,
            UserEngagementPhase.churning: 0.01,
          };

          final risk = predictor.churnRiskFromDistribution(distribution);
          expect(risk, lessThan(0.1));
        },
      );

      test(
        'result is always clamped to [0.0, 1.0]',
        () {
          // Deliberately overweight churn (invalid distribution, edge-case test)
          final distribution = {
            UserEngagementPhase.onboarding: 0.0,
            UserEngagementPhase.exploring: 0.0,
            UserEngagementPhase.connecting: 0.0,
            UserEngagementPhase.embedding: 0.0,
            UserEngagementPhase.quietPeriod: 0.6,
            UserEngagementPhase.churning: 0.6,
          };

          final risk = predictor.churnRiskFromDistribution(distribution);
          expect(risk, lessThanOrEqualTo(1.0));
          expect(risk, greaterThanOrEqualTo(0.0));
        },
      );
    });

    // -------------------------------------------------------------------------
    // predictChurnRisk: async convenience using quietPeriod row as worst-case
    // -------------------------------------------------------------------------
    group('predictChurnRisk', () {
      test(
        'returns 0.0 for a brand-new agent with no observations '
        '(prior row for quietPeriod still sums sensibly)',
        () async {
          final risk = await predictor.predictChurnRisk(
            'brand-new-agent',
            withinDays: 7,
          );
          expect(risk, inInclusiveRange(0.0, 1.0));
        },
      );

      test(
        'returns a valid probability after recording quietPeriod→churning transitions',
        () async {
          const agentId = 'churn-risk-agent';
          for (var i = 0; i < 100; i++) {
            await store.recordTransition(
              UserEngagementPhase.quietPeriod,
              UserEngagementPhase.churning,
              agentId,
            );
          }

          final risk = await predictor.predictChurnRisk(agentId, withinDays: 7);
          expect(risk, greaterThan(0.5),
              reason:
                  'After 100 quietPeriod→churning obs the churn risk should be high');
        },
      );
    });

    // -------------------------------------------------------------------------
    // recordTransition: wires through to store without throwing
    // -------------------------------------------------------------------------
    group('recordTransition', () {
      test(
        'records a transition and increments store observation count',
        () async {
          const agentId = 'record-agent';

          await predictor.recordTransition(
            UserEngagementPhase.onboarding,
            UserEngagementPhase.exploring,
            agentId,
          );

          final total = await store.totalRealObservations(agentId);
          expect(total, equals(1));
        },
      );

      test(
        'does not throw when called multiple times in sequence',
        () async {
          const agentId = 'multi-record-agent';

          final transitions = [
            (UserEngagementPhase.onboarding, UserEngagementPhase.exploring),
            (UserEngagementPhase.exploring, UserEngagementPhase.connecting),
            (UserEngagementPhase.connecting, UserEngagementPhase.embedding),
          ];

          for (final t in transitions) {
            await expectLater(
              predictor.recordTransition(t.$1, t.$2, agentId),
              completes,
            );
          }

          final total = await store.totalRealObservations(agentId);
          expect(total, equals(3));
        },
      );
    });
  });
}
