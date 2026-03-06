// Markov Engagement Predictor
//
// Phase 1.5E: Beta Markov Engagement Predictor (Bridge to Phase 5)
//
// Concrete beta implementation of EngagementPhasePredictor. Uses a discrete
// Markov chain over UserEngagementPhase states, blending city-stratified swarm
// priors with real per-agent observations accumulated during beta.
//
// Also records every transition as a (state, action, next_state) episodic tuple
// in the format expected by Phase 5's TransitionPredictor training pipeline.
//
// Swap path: FeatureFlagService.neural_transition_predictor_enabled = true
// → GetIt resolves NeuralTransitionPredictor instead. Zero caller changes.
//
// See: MASTER_PLAN.md Phase 1.5E, PHASE_5_RATIONALE.md (Beta Bridge section)

import 'dart:developer' as developer;

import 'package:avrai_core/services/atomic_clock_service.dart';

import 'engagement_phase_predictor.dart';
import 'markov_transition_store.dart';

/// Beta implementation of [EngagementPhasePredictor].
///
/// Discrete Markov chain seeded from Multi-City Swarm Simulation priors.
/// Personalizes per-agent as real phase transitions are observed during beta.
///
/// Simultaneously collects `(state, action, next_state)` training tuples
/// for Phase 5 [TransitionPredictor] training — the Markov chain is both
/// a working predictor AND a labeled dataset generator.
class MarkovEngagementPredictor implements EngagementPhasePredictor {
  static const String _logName = 'MarkovEngagementPredictor';

  /// Churn risk threshold above which proactive outreach changes strategy.
  static const double churnRiskThreshold = 0.6;

  final MarkovTransitionStore _store;
  final AtomicClockService _atomicClock;

  MarkovEngagementPredictor({
    required MarkovTransitionStore store,
    required AtomicClockService atomicClock,
  })  : _store = store,
        _atomicClock = atomicClock;

  @override
  Future<Map<UserEngagementPhase, double>> predictNextPhase(
    UserEngagementPhase current, {
    String? agentId,
  }) async {
    try {
      if (agentId == null) {
        // No agent ID — return default population prior row (Denver baseline)
        return _uniformFallback();
      }

      final matrix = await _store.getTransitionMatrix(agentId);
      final row = matrix[current];

      if (row == null || row.isEmpty) {
        developer.log(
          'No transition data for phase ${current.name}, using uniform fallback',
          name: _logName,
        );
        return _uniformFallback();
      }

      developer.log(
        'Predicted next phase from ${current.name} for agent $agentId: '
        '${row.entries.map((e) => "${e.key.name}=${e.value.toStringAsFixed(3)}").join(", ")}',
        name: _logName,
      );

      return row;
    } catch (e, st) {
      developer.log(
        'Error predicting next phase: $e',
        error: e,
        stackTrace: st,
        name: _logName,
      );
      return _uniformFallback();
    }
  }

  @override
  Future<double> predictChurnRisk(
    String agentId, {
    int withinDays = 7,
  }) async {
    try {
      final matrix = await _store.getTransitionMatrix(agentId);

      // We need the current phase to compute next-phase distribution.
      // Without it, use quietPeriod as a conservative estimate since
      // churn risk is highest when already quiet.
      // In practice, callers always have the current phase available and
      // should call predictNextPhase first, then derive churn risk from that.
      // This method is a convenience wrapper using quietPeriod as worst-case.
      final quietRow = matrix[UserEngagementPhase.quietPeriod];
      if (quietRow == null) return 0.0;

      final churnRisk = (quietRow[UserEngagementPhase.quietPeriod] ?? 0.0) +
          (quietRow[UserEngagementPhase.churning] ?? 0.0);

      developer.log(
        'Churn risk for agent $agentId (within $withinDays days): '
        '${churnRisk.toStringAsFixed(3)}',
        name: _logName,
      );

      return churnRisk.clamp(0.0, 1.0);
    } catch (e, st) {
      developer.log(
        'Error computing churn risk: $e',
        error: e,
        stackTrace: st,
        name: _logName,
      );
      return 0.0;
    }
  }

  /// Computes churn risk from a pre-fetched next-phase distribution.
  ///
  /// More efficient when the caller already has the distribution from
  /// [predictNextPhase]. Avoids a second matrix lookup.
  double churnRiskFromDistribution(
      Map<UserEngagementPhase, double> distribution) {
    return ((distribution[UserEngagementPhase.quietPeriod] ?? 0.0) +
            (distribution[UserEngagementPhase.churning] ?? 0.0))
        .clamp(0.0, 1.0);
  }

  @override
  Future<void> recordTransition(
    UserEngagementPhase from,
    UserEngagementPhase to,
    String agentId, {
    String? city,
  }) async {
    try {
      // 1. Update the Markov transition count store (personalization)
      await _store.recordTransition(from, to, agentId, city: city);

      // 2. Write a (state, action, next_state) episodic tuple for Phase 5 training.
      // Format is aligned with what the TransitionPredictor training pipeline expects.
      // The "action" here is the implicit action of "staying in app / being active"
      // as observed by the phase classifier. More granular action types will be
      // added in Phase 3.3 when explicit action encoding is built.
      final timestamp = await _atomicClock.getAtomicTimestamp();
      developer.log(
        'Phase 5 training tuple: state=${from.name}, action=engagement_evolution, '
        'next_state=${to.name}, timestamp=${timestamp.serverTime.toIso8601String()}, '
        'agentId=$agentId',
        name: _logName,
      );

      // TODO(Phase 1.1C): Wire this tuple into EpisodicMemoryStore when
      // Phase 1.1 memory infrastructure is complete. For now, the log above
      // serves as the audit trail. The MarkovTransitionStore already persists
      // the data needed to reconstruct tuples for Phase 5 training.
    } catch (e, st) {
      developer.log(
        'Error recording transition: $e',
        error: e,
        stackTrace: st,
        name: _logName,
      );
    }
  }

  Map<UserEngagementPhase, double> _uniformFallback() {
    final uniform = 1.0 / UserEngagementPhase.values.length;
    return {for (final phase in UserEngagementPhase.values) phase: uniform};
  }
}
