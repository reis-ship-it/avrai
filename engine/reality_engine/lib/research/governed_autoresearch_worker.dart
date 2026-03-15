import 'package:avrai_core/avra_core.dart';

class GovernedAutoresearchPlan {
  const GovernedAutoresearchPlan({
    required this.runId,
    required this.evidenceOrder,
    required this.requestBrokeredOpenWeb,
    required this.summary,
  });

  final String runId;
  final List<String> evidenceOrder;
  final bool requestBrokeredOpenWeb;
  final String summary;
}

/// Bounded worker used by the Reality Model inside sandbox/replay lanes only.
class GovernedAutoresearchWorker {
  const GovernedAutoresearchWorker();

  bool get productionWritesEnabled => false;

  bool canConsumeProjection(ResearchSandboxResultProjection projection) {
    return projection.safeForModelConsumption;
  }

  GovernedAutoresearchPlan buildInternalEvidenceFirstPlan(
    ResearchRunState run,
  ) {
    final evidenceOrder = <String>[
      'replay_holdouts',
      'internal_ledgers',
      'historical_outcomes',
      'approved_local_artifacts',
    ];
    final requestBrokeredOpenWeb = !run.hasApprovedOpenWebAccess &&
        (run.metrics['promotionReadiness'] ?? 0) < 0.7;
    if (run.hasApprovedOpenWebAccess) {
      evidenceOrder.add('brokered_open_web');
    }
    return GovernedAutoresearchPlan(
      runId: run.id,
      evidenceOrder: evidenceOrder,
      requestBrokeredOpenWeb: requestBrokeredOpenWeb,
      summary: requestBrokeredOpenWeb
          ? 'Internal evidence exhausted; brokered open-web access may be requested.'
          : 'Continue with internal evidence only.',
    );
  }

  ResearchExplanation explain(ResearchRunState run) {
    final plan = buildInternalEvidenceFirstPlan(run);
    return ResearchExplanation(
      id: 'reality_worker_explain_${run.id}',
      runId: run.id,
      summary:
          'Reality Model remains sandbox-bound and cannot mutate production.',
      currentStep: 'Evaluating ${plan.evidenceOrder.first} first.',
      rationale: plan.summary,
      nextStep: plan.requestBrokeredOpenWeb
          ? 'Ask Runtime OS for brokered open-web approval.'
          : 'Continue replay and ledger comparisons.',
      evidenceSummary: 'Evidence order: ${plan.evidenceOrder.join(', ')}.',
      createdAt: DateTime.now().toUtc(),
      checkpointId: run.activeCheckpointId,
    );
  }
}
