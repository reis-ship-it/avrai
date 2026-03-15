import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/why/why_kernel_contract.dart';

class DartWhyFallbackKernel extends WhyKernelFallbackSurface {
  const DartWhyFallbackKernel();

  @override
  WhyKernelSnapshot explainWhy(KernelWhyRequest request) {
    final signals = <WhySignal>[
      ...request.coreSignals.map(
        (signal) => WhySignal(
          label: signal.label,
          weight: signal.weight,
          source: signal.source ?? 'core',
          durable: signal.durable ?? true,
        ),
      ),
      ...request.pheromoneSignals.map(
        (signal) => WhySignal(
          label: signal.label,
          weight: signal.weight,
          source: signal.source ?? 'pheromone',
          durable: signal.durable ?? false,
        ),
      ),
      ...request.policySignals.map(
        (signal) => WhySignal(
          label: signal.label,
          weight: signal.weight,
          source: signal.source ?? 'policy',
          durable: signal.durable ?? false,
        ),
      ),
      if (request.bundle.who != null)
        WhySignal(
          label: 'identity_confidence',
          weight: request.bundle.who!.identityConfidence - 0.5,
          source: 'who',
          durable: false,
        ),
      if (request.bundle.what != null)
        WhySignal(
          label: 'taxonomy_confidence',
          weight: request.bundle.what!.taxonomyConfidence - 0.5,
          source: 'what',
          durable: false,
        ),
      if (request.bundle.when != null) ...[
        WhySignal(
          label: 'temporal_freshness',
          weight: request.bundle.when!.freshness - 0.5,
          source: 'when',
          durable: false,
        ),
        ...request.bundle.when!.timingConflictFlags.map(
          (flag) => WhySignal(
            label: flag,
            weight: -0.55,
            source: 'when',
            durable: false,
          ),
        ),
      ],
      if (request.bundle.where != null) ...[
        WhySignal(
          label: 'spatial_confidence',
          weight: request.bundle.where!.spatialConfidence - 0.5,
          source: 'where',
          durable: false,
        ),
        WhySignal(
          label: 'boundary_tension',
          weight: -request.bundle.where!.boundaryTension,
          source: 'where',
          durable: false,
        ),
        WhySignal(
          label: 'travel_friction',
          weight: -request.bundle.where!.travelFriction,
          source: 'where',
          durable: false,
        ),
      ],
      if (request.bundle.how != null) ...[
        WhySignal(
          label: 'mechanism_confidence',
          weight: request.bundle.how!.mechanismConfidence - 0.5,
          source: 'how',
          durable: false,
        ),
        if (request.bundle.how!.failureMechanism != 'none')
          WhySignal(
            label: request.bundle.how!.failureMechanism,
            weight: -0.62,
            source: 'how',
            durable: false,
          ),
      ],
    ];
    final drivers = signals.where((signal) => signal.weight > 0).toList()
      ..sort(_sortByWeight);
    final inhibitors = signals
        .where((signal) => signal.weight < 0)
        .map(
          (signal) => WhySignal(
            label: signal.label,
            weight: signal.weight.abs(),
            source: signal.source,
            durable: signal.durable,
          ),
        )
        .toList()
      ..sort(_sortByWeight);
    final topDrivers = drivers.take(3).toList();
    final topInhibitors = inhibitors.take(3).toList();
    final rootCauseType = _rootCauseType(signals);
    final negativeOutcome = (request.actualOutcomeScore ?? 0) < 0 ||
        const <String>{
          'rejected',
          'dismissed',
          'failed',
          'negative',
          'incident'
        }.contains(request.actualOutcome);

    return WhyKernelSnapshot(
      goal: request.goal ?? 'explain_outcome',
      summary:
          '${request.goal ?? 'explain_outcome'} led to ${request.actualOutcome ?? 'observed_outcome'} due to ${rootCauseType.toWireValue()}, driven by ${topDrivers.isEmpty ? 'limited positive evidence' : topDrivers.first.label} and constrained by ${topInhibitors.isEmpty ? 'limited opposing evidence' : topInhibitors.first.label}.',
      rootCauseType: rootCauseType,
      confidence: _confidence(signals),
      drivers: topDrivers,
      inhibitors: topInhibitors,
      counterfactuals: <WhyCounterfactual>[
        if (topInhibitors.isNotEmpty)
          WhyCounterfactual(
            condition: 'Reduce ${topInhibitors.first.label}',
            expectedEffect: 'Outcome is more likely to improve',
            confidenceDelta:
                (topInhibitors.first.weight * 0.35).clamp(0.0, 0.35),
          ),
        if (topDrivers.isNotEmpty)
          WhyCounterfactual(
            condition: 'Increase ${topDrivers.first.label}',
            expectedEffect: 'Outcome is more likely to repeat',
            confidenceDelta: (topDrivers.first.weight * 0.25).clamp(0.0, 0.25),
          ),
      ],
      failureSignature: negativeOutcome
          ? WhyFailureSignature(
              signatureId:
                  '${topInhibitors.isEmpty ? 'unknown_failure' : topInhibitors.first.source}:${request.goal ?? 'goal'}:${request.actualOutcome ?? 'outcome'}',
              signatureFamily: switch (
                  topInhibitors.isEmpty ? null : topInhibitors.first.source) {
                'pheromone' => 'pheromone_mismatch',
                'when' => 'temporal_misalignment',
                'where' => 'locality_conflict',
                'how' => 'execution_path_failure',
                'policy' => 'policy_conflict',
                _ => 'unknown_failure',
              },
              novelty: 'new',
              replayRisk: 'medium',
              recommendedGuardrail: topInhibitors.isNotEmpty &&
                      topInhibitors.first.source == 'pheromone'
                  ? 'retry_after_pheromone_decay'
                  : 'adjust_confidence',
            )
          : null,
      recommendationAction: !negativeOutcome
          ? 'rerank_entity'
          : (topInhibitors.isNotEmpty &&
                  topInhibitors.first.source == 'pheromone')
              ? 'retry_after_pheromone_decay'
              : 'adjust_confidence',
      createdAtUtc: DateTime.now().toUtc(),
    );
  }

  static int _sortByWeight(WhySignal left, WhySignal right) =>
      right.weight.compareTo(left.weight);

  WhyRootCauseType _rootCauseType(List<WhySignal> signals) {
    if (signals.isEmpty) {
      return WhyRootCauseType.unknown;
    }
    final totals = <String, double>{};
    for (final signal in signals) {
      totals.update(
        signal.source ?? 'unknown',
        (current) => current + signal.weight.abs(),
        ifAbsent: () => signal.weight.abs(),
      );
    }
    final entries = totals.entries.toList()
      ..sort((left, right) => right.value.compareTo(left.value));
    if (entries.first.value < 0.30) {
      return WhyRootCauseType.unknown;
    }
    if (entries.length > 1 && entries[1].value / entries.first.value >= 0.25) {
      return WhyRootCauseType.mixed;
    }
    return switch (entries.first.key) {
      'core' => WhyRootCauseType.traitDriven,
      'pheromone' => WhyRootCauseType.pheromone,
      'policy' => WhyRootCauseType.policy,
      'who' => WhyRootCauseType.socialDriven,
      'what' => WhyRootCauseType.contextDriven,
      'when' => WhyRootCauseType.temporal,
      'where' => WhyRootCauseType.locality,
      'how' => WhyRootCauseType.mechanism,
      _ => WhyRootCauseType.unknown,
    };
  }

  double _confidence(List<WhySignal> signals) {
    if (signals.isEmpty) {
      return 0.0;
    }
    final strongest = signals
        .map((signal) => signal.weight.abs())
        .fold<double>(0.0, (current, next) => current > next ? current : next)
        .clamp(0.0, 1.0);
    final coverage = (signals.length / 8).clamp(0.0, 1.0);
    return ((strongest * 0.7) + (coverage * 0.3)).clamp(0.0, 1.0);
  }
}
