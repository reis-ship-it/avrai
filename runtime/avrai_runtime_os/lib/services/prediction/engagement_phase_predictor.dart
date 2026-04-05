// Engagement Phase Predictor — Abstract Interface
//
// Phase 1.5E: Beta Markov Engagement Predictor (Bridge to Phase 5)
//
// This interface is the migration contract between the beta Markov implementation
// and the Phase 5 NeuralTransitionPredictor. Both satisfy this contract exactly.
// Callers never depend on the concrete implementation — only this interface.
//
// Swap path: FeatureFlagService.neural_transition_predictor_enabled = true
// → DI serves NeuralTransitionPredictor instead of MarkovEngagementPredictor.
// All callers (PredictionAPIService, PersonalityLearning hook, proactive outreach
// services) are unchanged.
//
// See: MASTER_PLAN.md Phase 1.5E, PHASE_5_RATIONALE.md (Beta Bridge section)

/// Discrete macro-states representing a user's behavioral engagement arc.
///
/// Classified from PersonalityProfile + interaction history by
/// [EngagementPhaseClassifier]. Used as Markov chain states during beta
/// and as labeled training targets for Phase 5 TransitionPredictor.
enum UserEngagementPhase {
  /// < 5 meaningful interactions. World model uses population priors.
  onboarding,

  /// Actively visiting spots, low commitment (< 2 communities joined).
  /// High novelty-seeking. Personal Markov matrix still forming.
  exploring,

  /// Joining communities, making AI2AI connections. Reciprocal engagement rising.
  connecting,

  /// Regular return visits, attending events, stable personality dimensions.
  /// Most valuable phase — recommend depth over breadth.
  embedding,

  /// Engagement dropped below 30% of 30-day rolling average.
  /// AI agent may be failing this user. Strategy shift required.
  quietPeriod,

  /// No meaningful activity for 7+ days. Re-engagement window closing.
  /// NOT a spam trigger — trigger strategy change, not volume increase.
  churning,
}

/// Abstract interface for engagement trajectory prediction.
///
/// **Beta implementation:** [MarkovEngagementPredictor] — discrete Markov chain
/// seeded from Multi-City Swarm Simulation priors, personalizes from real
/// observations.
///
/// **Phase 5 implementation:** NeuralTransitionPredictor — 150K-param MLP
/// trained on the transition tuples collected by the beta Markov chain.
///
/// All callers depend on this interface. The concrete implementation is
/// resolved via GetIt + FeatureFlagService. Zero caller changes on swap.
abstract class EngagementPhasePredictor {
  /// Returns a probability distribution over the next [UserEngagementPhase]
  /// given the user's current phase. Probabilities sum to 1.0.
  ///
  /// **Parameters:**
  /// - [current]: The user's current engagement phase
  /// - [agentId]: Optional agent ID for personalized prediction (falls back
  ///   to city-level population prior if null or insufficient observations)
  ///
  /// **Returns:**
  /// Map of phase → probability (0.0–1.0, sums to 1.0)
  Future<Map<UserEngagementPhase, double>> predictNextPhase(
    UserEngagementPhase current, {
    String? agentId,
  });

  /// Returns the probability that this user will disengage within [withinDays].
  ///
  /// Computed as P(quietPeriod) + P(churning) from the next-phase distribution.
  /// Values > 0.6 trigger re-engagement strategy in proactive outreach services.
  ///
  /// This is NOT a spam signal — it signals that the AI agent strategy should
  /// change (explore different categories, shift tone, reduce frequency).
  Future<double> predictChurnRisk(
    String agentId, {
    int withinDays = 7,
  });

  /// Records an observed phase transition for this user.
  ///
  /// Called by [PersonalityLearning.evolveFromUserAction] when the classified
  /// phase changes after personality evolution. This serves dual purpose:
  /// 1. Updates the personal Markov matrix (immediate prediction improvement)
  /// 2. Writes a (state, action, next_state) episodic tuple for Phase 5
  ///    TransitionPredictor training data collection.
  Future<void> recordTransition(
    UserEngagementPhase from,
    UserEngagementPhase to,
    String agentId, {
    String? city,
  });
}
