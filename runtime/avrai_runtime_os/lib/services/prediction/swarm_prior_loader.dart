// Swarm Prior Loader
//
// Phase 1.5E: Beta Markov Engagement Predictor (Bridge to Phase 5)
//
// Extracts city-stratified Markov transition priors from the Multi-City Swarm
// Simulation archetypes. Maps SimulatedHuman behavioral patterns (RoutineState +
// trustMeter + activationEnergy) to UserEngagementPhase transitions.
//
// These priors seed MarkovTransitionStore as 100 synthetic observations per row
// before any real user data exists. They decay in relative weight as real
// observations accumulate.
//
// Priors are computed once and cached in-memory. No simulation is re-run at
// runtime — this loader encodes the population-level distributions derived
// from swarm analysis of NYC, Denver, and Atlanta archetypes.
//
// See: MASTER_PLAN.md Phase 1.5E, SwarmSimulationEngine, SwarmPopulationGenerator

import 'engagement_phase_predictor.dart';

/// Provides city-stratified Markov transition priors derived from the
/// Multi-City Swarm Simulation (NYC, Denver, Atlanta).
///
/// Priors encode population-level behavioral arcs observed across 4 daily
/// routine archetypes (Standard, Early Bird, Night Owl, Shift Worker) and
/// 3 financial profiles (Tight, Comfortable, Affluent) per city.
///
/// **How priors were derived:** The swarm simulation produces trajectories
/// through RoutineState (sleeping → home → commuting → working → freeTime).
/// trustMeter (-1.0 to +1.0) and currentActivationEnergy map directly to
/// engagement arc transitions:
/// - trustMeter > 0.3 + freeTime state → exploring/connecting
/// - trustMeter > 0.5 + repeated freeTime engagement → embedding
/// - trustMeter declining + reduced freeTime activity → quietPeriod
/// - trustMeter < -0.3 + no freeTime engagement for N ticks → churning
///
/// City differences are encoded in city-level friction (NYC: 0.85, Denver: 0.60,
/// Atlanta: 0.70) and archetype distributions, producing meaningfully different
/// priors per city.
class SwarmPriorLoader {
  /// Returns the transition prior matrix for a given city (or 'default').
  ///
  /// Returns a [Map] of `from → to → synthetic_count` where counts represent
  /// the synthetic prior observations. These are added to the real observation
  /// counts in [MarkovTransitionStore] with a total weight of 100 per row.
  Map<UserEngagementPhase, Map<UserEngagementPhase, int>> getPriorForCity(
      String city) {
    switch (city.toLowerCase()) {
      case 'new york city':
      case 'nyc':
      case 'new york':
        return _nycPrior;
      case 'denver':
        return _denverPrior;
      case 'atlanta':
        return _atlantaPrior;
      default:
        return _defaultPrior;
    }
  }

  // ─── NYC Prior ────────────────────────────────────────────────────────────
  // High friction city (0.85). Archetypes: 60% Standard, 20% Early Bird,
  // 15% Night Owl, 5% Shift Worker. Higher churn risk from high friction.
  // Longer path from onboarding → embedding.
  static final Map<UserEngagementPhase, Map<UserEngagementPhase, int>>
      _nycPrior = {
    UserEngagementPhase.onboarding: {
      UserEngagementPhase.onboarding: 20,
      UserEngagementPhase.exploring: 55,
      UserEngagementPhase.connecting: 10,
      UserEngagementPhase.embedding: 2,
      UserEngagementPhase.quietPeriod: 8,
      UserEngagementPhase.churning: 5,
    },
    UserEngagementPhase.exploring: {
      UserEngagementPhase.onboarding: 2,
      UserEngagementPhase.exploring: 35,
      UserEngagementPhase.connecting: 30,
      UserEngagementPhase.embedding: 10,
      UserEngagementPhase.quietPeriod: 15,
      UserEngagementPhase.churning: 8,
    },
    UserEngagementPhase.connecting: {
      UserEngagementPhase.onboarding: 0,
      UserEngagementPhase.exploring: 10,
      UserEngagementPhase.connecting: 30,
      UserEngagementPhase.embedding: 40,
      UserEngagementPhase.quietPeriod: 12,
      UserEngagementPhase.churning: 8,
    },
    UserEngagementPhase.embedding: {
      UserEngagementPhase.onboarding: 0,
      UserEngagementPhase.exploring: 5,
      UserEngagementPhase.connecting: 10,
      UserEngagementPhase.embedding: 70,
      UserEngagementPhase.quietPeriod: 12,
      UserEngagementPhase.churning: 3,
    },
    UserEngagementPhase.quietPeriod: {
      UserEngagementPhase.onboarding: 0,
      UserEngagementPhase.exploring: 25,
      UserEngagementPhase.connecting: 10,
      UserEngagementPhase.embedding: 5,
      UserEngagementPhase.quietPeriod: 30,
      UserEngagementPhase.churning: 30,
    },
    UserEngagementPhase.churning: {
      UserEngagementPhase.onboarding: 5,
      UserEngagementPhase.exploring: 15,
      UserEngagementPhase.connecting: 5,
      UserEngagementPhase.embedding: 2,
      UserEngagementPhase.quietPeriod: 15,
      UserEngagementPhase.churning: 58,
    },
  };

  // ─── Denver Prior ─────────────────────────────────────────────────────────
  // Lower friction city (0.60). More outdoor/active culture. Higher outdoor
  // spots engagement. Faster path to embedding, lower churn risk.
  static final Map<UserEngagementPhase, Map<UserEngagementPhase, int>>
      _denverPrior = {
    UserEngagementPhase.onboarding: {
      UserEngagementPhase.onboarding: 15,
      UserEngagementPhase.exploring: 60,
      UserEngagementPhase.connecting: 12,
      UserEngagementPhase.embedding: 5,
      UserEngagementPhase.quietPeriod: 5,
      UserEngagementPhase.churning: 3,
    },
    UserEngagementPhase.exploring: {
      UserEngagementPhase.onboarding: 2,
      UserEngagementPhase.exploring: 28,
      UserEngagementPhase.connecting: 38,
      UserEngagementPhase.embedding: 18,
      UserEngagementPhase.quietPeriod: 10,
      UserEngagementPhase.churning: 4,
    },
    UserEngagementPhase.connecting: {
      UserEngagementPhase.onboarding: 0,
      UserEngagementPhase.exploring: 8,
      UserEngagementPhase.connecting: 25,
      UserEngagementPhase.embedding: 52,
      UserEngagementPhase.quietPeriod: 10,
      UserEngagementPhase.churning: 5,
    },
    UserEngagementPhase.embedding: {
      UserEngagementPhase.onboarding: 0,
      UserEngagementPhase.exploring: 4,
      UserEngagementPhase.connecting: 8,
      UserEngagementPhase.embedding: 78,
      UserEngagementPhase.quietPeriod: 8,
      UserEngagementPhase.churning: 2,
    },
    UserEngagementPhase.quietPeriod: {
      UserEngagementPhase.onboarding: 0,
      UserEngagementPhase.exploring: 35,
      UserEngagementPhase.connecting: 15,
      UserEngagementPhase.embedding: 8,
      UserEngagementPhase.quietPeriod: 25,
      UserEngagementPhase.churning: 17,
    },
    UserEngagementPhase.churning: {
      UserEngagementPhase.onboarding: 5,
      UserEngagementPhase.exploring: 20,
      UserEngagementPhase.connecting: 8,
      UserEngagementPhase.embedding: 5,
      UserEngagementPhase.quietPeriod: 12,
      UserEngagementPhase.churning: 50,
    },
  };

  // ─── Atlanta Prior ────────────────────────────────────────────────────────
  // Medium friction city (0.70). Mix of urban and suburban patterns.
  // Strong community engagement, moderate path to embedding.
  static final Map<UserEngagementPhase, Map<UserEngagementPhase, int>>
      _atlantaPrior = {
    UserEngagementPhase.onboarding: {
      UserEngagementPhase.onboarding: 18,
      UserEngagementPhase.exploring: 57,
      UserEngagementPhase.connecting: 11,
      UserEngagementPhase.embedding: 3,
      UserEngagementPhase.quietPeriod: 7,
      UserEngagementPhase.churning: 4,
    },
    UserEngagementPhase.exploring: {
      UserEngagementPhase.onboarding: 2,
      UserEngagementPhase.exploring: 30,
      UserEngagementPhase.connecting: 35,
      UserEngagementPhase.embedding: 15,
      UserEngagementPhase.quietPeriod: 12,
      UserEngagementPhase.churning: 6,
    },
    UserEngagementPhase.connecting: {
      UserEngagementPhase.onboarding: 0,
      UserEngagementPhase.exploring: 9,
      UserEngagementPhase.connecting: 28,
      UserEngagementPhase.embedding: 46,
      UserEngagementPhase.quietPeriod: 11,
      UserEngagementPhase.churning: 6,
    },
    UserEngagementPhase.embedding: {
      UserEngagementPhase.onboarding: 0,
      UserEngagementPhase.exploring: 4,
      UserEngagementPhase.connecting: 9,
      UserEngagementPhase.embedding: 74,
      UserEngagementPhase.quietPeriod: 10,
      UserEngagementPhase.churning: 3,
    },
    UserEngagementPhase.quietPeriod: {
      UserEngagementPhase.onboarding: 0,
      UserEngagementPhase.exploring: 30,
      UserEngagementPhase.connecting: 12,
      UserEngagementPhase.embedding: 6,
      UserEngagementPhase.quietPeriod: 28,
      UserEngagementPhase.churning: 24,
    },
    UserEngagementPhase.churning: {
      UserEngagementPhase.onboarding: 5,
      UserEngagementPhase.exploring: 18,
      UserEngagementPhase.connecting: 6,
      UserEngagementPhase.embedding: 3,
      UserEngagementPhase.quietPeriod: 13,
      UserEngagementPhase.churning: 55,
    },
  };

  // ─── Default Prior (blended average) ─────────────────────────────────────
  // Used when city is unknown. Weighted average of NYC/Denver/Atlanta.
  static final Map<UserEngagementPhase, Map<UserEngagementPhase, int>>
      _defaultPrior = {
    UserEngagementPhase.onboarding: {
      UserEngagementPhase.onboarding: 18,
      UserEngagementPhase.exploring: 57,
      UserEngagementPhase.connecting: 11,
      UserEngagementPhase.embedding: 3,
      UserEngagementPhase.quietPeriod: 7,
      UserEngagementPhase.churning: 4,
    },
    UserEngagementPhase.exploring: {
      UserEngagementPhase.onboarding: 2,
      UserEngagementPhase.exploring: 31,
      UserEngagementPhase.connecting: 34,
      UserEngagementPhase.embedding: 14,
      UserEngagementPhase.quietPeriod: 12,
      UserEngagementPhase.churning: 6,
    },
    UserEngagementPhase.connecting: {
      UserEngagementPhase.onboarding: 0,
      UserEngagementPhase.exploring: 9,
      UserEngagementPhase.connecting: 28,
      UserEngagementPhase.embedding: 46,
      UserEngagementPhase.quietPeriod: 11,
      UserEngagementPhase.churning: 6,
    },
    UserEngagementPhase.embedding: {
      UserEngagementPhase.onboarding: 0,
      UserEngagementPhase.exploring: 4,
      UserEngagementPhase.connecting: 9,
      UserEngagementPhase.embedding: 74,
      UserEngagementPhase.quietPeriod: 10,
      UserEngagementPhase.churning: 3,
    },
    UserEngagementPhase.quietPeriod: {
      UserEngagementPhase.onboarding: 0,
      UserEngagementPhase.exploring: 30,
      UserEngagementPhase.connecting: 12,
      UserEngagementPhase.embedding: 6,
      UserEngagementPhase.quietPeriod: 28,
      UserEngagementPhase.churning: 24,
    },
    UserEngagementPhase.churning: {
      UserEngagementPhase.onboarding: 5,
      UserEngagementPhase.exploring: 18,
      UserEngagementPhase.connecting: 6,
      UserEngagementPhase.embedding: 3,
      UserEngagementPhase.quietPeriod: 13,
      UserEngagementPhase.churning: 55,
    },
  };
}
