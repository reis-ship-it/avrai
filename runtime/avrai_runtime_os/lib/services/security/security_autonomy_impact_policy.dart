import 'package:avrai_core/avra_core.dart';

class SecurityAutonomyImpactDecision {
  const SecurityAutonomyImpactDecision({
    required this.disposition,
    required this.freezePromotion,
    required this.budgetMultiplier,
    required this.shouldKill,
    required this.rationale,
    this.redirectEnvironment,
  });

  final SecurityInterventionDisposition disposition;
  final bool freezePromotion;
  final double budgetMultiplier;
  final bool shouldKill;
  final String rationale;
  final GovernedRunEnvironment? redirectEnvironment;
}

class SecurityAutonomyImpactPolicy {
  const SecurityAutonomyImpactPolicy();

  SecurityAutonomyImpactDecision evaluate({
    required SecurityInterventionDisposition disposition,
    required GovernedRunEnvironment currentEnvironment,
  }) {
    switch (disposition) {
      case SecurityInterventionDisposition.observe:
        return const SecurityAutonomyImpactDecision(
          disposition: SecurityInterventionDisposition.observe,
          freezePromotion: false,
          budgetMultiplier: 1.0,
          shouldKill: false,
          rationale:
              'Observe only. Add evidence and continue autonomy unchanged.',
        );
      case SecurityInterventionDisposition.boundedDegrade:
        return SecurityAutonomyImpactDecision(
          disposition: SecurityInterventionDisposition.boundedDegrade,
          freezePromotion: true,
          budgetMultiplier: 0.5,
          shouldKill: false,
          redirectEnvironment:
              currentEnvironment == GovernedRunEnvironment.sandbox ||
                      currentEnvironment == GovernedRunEnvironment.replay
                  ? GovernedRunEnvironment.replay
                  : GovernedRunEnvironment.shadow,
          rationale:
              'Freeze promotion, redirect to shadow/replay, and narrow budgets.',
        );
      case SecurityInterventionDisposition.hardStop:
        return const SecurityAutonomyImpactDecision(
          disposition: SecurityInterventionDisposition.hardStop,
          freezePromotion: true,
          budgetMultiplier: 0.0,
          shouldKill: true,
          rationale:
              'Invariant breach. Kill the run and require explicit review.',
        );
    }
  }
}
