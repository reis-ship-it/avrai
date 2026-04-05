// Markov Transition Store Tests
//
// Phase 1.5E: Beta Markov Engagement Predictor
//
// Validates that the store correctly accumulates per-agent transition counts,
// blends them with swarm priors, and produces normalized probability matrices.
// Also verifies cold-start behavior (new agent uses pure prior).

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:avrai_runtime_os/services/prediction/engagement_phase_predictor.dart';
import 'package:avrai_runtime_os/services/prediction/markov_transition_store.dart';
import 'package:avrai_runtime_os/services/prediction/swarm_prior_loader.dart';

void main() {
  group('MarkovTransitionStore', () {
    late MarkovTransitionStore store;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      store = MarkovTransitionStore(
        prefs: prefs,
        priorLoader: SwarmPriorLoader(),
      );
    });

    // -------------------------------------------------------------------------
    // Cold-start: new agent sees a valid, normalized prior-only matrix
    // -------------------------------------------------------------------------
    group('cold-start behavior', () {
      test(
        'returns a fully normalized matrix for a brand-new agent',
        () async {
          final matrix = await store.getTransitionMatrix('new-agent');

          // Every from-phase must have a row
          for (final phase in UserEngagementPhase.values) {
            expect(matrix.containsKey(phase), isTrue,
                reason: 'Missing row for ${phase.name}');
          }

          // Every row must sum to 1.0 (allow floating-point tolerance)
          for (final entry in matrix.entries) {
            final rowSum = entry.value.values.fold(0.0, (sum, v) => sum + v);
            expect(
              rowSum,
              closeTo(1.0, 1e-9),
              reason: 'Row for ${entry.key.name} sums to $rowSum, expected 1.0',
            );
          }
        },
      );

      test(
        'reports 0 real observations for a brand-new agent',
        () async {
          final total = await store.totalRealObservations('new-agent');
          expect(total, equals(0));
        },
      );
    });

    // -------------------------------------------------------------------------
    // Transition recording accumulates counts correctly
    // -------------------------------------------------------------------------
    group('recordTransition', () {
      test(
        'increments the count for the recorded (from, to) pair',
        () async {
          const agentId = 'agent-A';
          await store.recordTransition(
            UserEngagementPhase.exploring,
            UserEngagementPhase.connecting,
            agentId,
          );
          await store.recordTransition(
            UserEngagementPhase.exploring,
            UserEngagementPhase.connecting,
            agentId,
          );

          final total = await store.totalRealObservations(agentId);
          expect(total, equals(2));
        },
      );

      test(
        'persists city on first write and ignores subsequent city updates',
        () async {
          const agentId = 'agent-city-test';
          final prefs = await SharedPreferences.getInstance();

          await store.recordTransition(
            UserEngagementPhase.onboarding,
            UserEngagementPhase.exploring,
            agentId,
            city: 'nyc',
          );
          // Second call with different city should NOT overwrite the first
          await store.recordTransition(
            UserEngagementPhase.exploring,
            UserEngagementPhase.connecting,
            agentId,
            city: 'denver',
          );

          final storedCity = prefs.getString('markov_city_$agentId');
          expect(storedCity, equals('nyc'));
        },
      );

      test(
        'accumulating real observations shifts probability mass toward observed transitions',
        () async {
          const agentId = 'agent-B';

          // Record onboarding→exploring many times to dominate the prior
          for (var i = 0; i < 500; i++) {
            await store.recordTransition(
              UserEngagementPhase.onboarding,
              UserEngagementPhase.exploring,
              agentId,
            );
          }

          final matrix = await store.getTransitionMatrix(agentId);
          final onboardingRow = matrix[UserEngagementPhase.onboarding]!;

          // After 500 observations in one direction, that cell should dominate
          expect(
            onboardingRow[UserEngagementPhase.exploring]! > 0.8,
            isTrue,
            reason: 'Expected exploring to dominate after 500 obs, '
                'got ${onboardingRow[UserEngagementPhase.exploring]}',
          );
        },
      );
    });

    // -------------------------------------------------------------------------
    // Matrix always stays normalized regardless of observation count
    // -------------------------------------------------------------------------
    group('matrix normalization invariant', () {
      test(
        'matrix row sums remain 1.0 after mixed observations across phases',
        () async {
          const agentId = 'agent-norm';

          // Record varied transitions across multiple phases
          final transitions = [
            (UserEngagementPhase.onboarding, UserEngagementPhase.exploring),
            (UserEngagementPhase.exploring, UserEngagementPhase.connecting),
            (UserEngagementPhase.connecting, UserEngagementPhase.embedding),
            (UserEngagementPhase.embedding, UserEngagementPhase.quietPeriod),
            (UserEngagementPhase.quietPeriod, UserEngagementPhase.churning),
            (UserEngagementPhase.churning, UserEngagementPhase.exploring),
          ];

          for (final t in transitions) {
            for (var i = 0; i < 10; i++) {
              await store.recordTransition(t.$1, t.$2, agentId);
            }
          }

          final matrix = await store.getTransitionMatrix(agentId);

          for (final entry in matrix.entries) {
            final rowSum = entry.value.values.fold(0.0, (sum, v) => sum + v);
            expect(
              rowSum,
              closeTo(1.0, 1e-9),
              reason: 'Row ${entry.key.name} sums to $rowSum after mixed obs',
            );
          }
        },
      );
    });

    // -------------------------------------------------------------------------
    // Agent isolation: one agent's transitions don't bleed into another's
    // -------------------------------------------------------------------------
    group('agent isolation', () {
      test(
        'observations from agentA do not affect agentB transition matrix',
        () async {
          const agentA = 'isolation-agent-A';
          const agentB = 'isolation-agent-B';

          // Record 300 churning transitions for agentA
          for (var i = 0; i < 300; i++) {
            await store.recordTransition(
              UserEngagementPhase.exploring,
              UserEngagementPhase.churning,
              agentA,
            );
          }

          // agentB should see only the pure prior (no contamination from agentA)
          final totalB = await store.totalRealObservations(agentB);
          expect(totalB, equals(0));
        },
      );
    });
  });
}
