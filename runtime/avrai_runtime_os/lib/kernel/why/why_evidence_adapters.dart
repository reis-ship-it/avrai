import 'package:avrai_core/avra_core.dart';
import 'package:avrai_core/models/why/why_models.dart';

class TemporalWhyEvidenceAdapter {
  const TemporalWhyEvidenceAdapter({
    this.sourceSubsystem = 'temporal_kernel',
  });

  final String sourceSubsystem;

  WhyEvidence toWhyEvidence(TemporalSnapshot snapshot) {
    final timeLabel = snapshot.semanticBand.name;
    final confidence =
        snapshot.observedAt.uncertainty.confidence.clamp(0.0, 1.0);
    return WhyEvidence(
      id: snapshot.lineageRef ??
          'temporal_${snapshot.observedAt.referenceTime.toIso8601String()}',
      label: 'temporal alignment: $timeLabel',
      weight: confidence == 0 ? 0.5 : confidence,
      polarity: WhyEvidencePolarity.positive,
      sourceKernel: WhyEvidenceSourceKernel.when,
      sourceSubsystem: sourceSubsystem,
      durability: snapshot.cadence == null ? 'transient' : 'durable',
      confidence: confidence,
      observed: true,
      inferred: false,
      provenance: snapshot.observedAt.provenance.source,
      timeRef: snapshot.observedAt.referenceTime.toIso8601String(),
      subjectRef: snapshot.lineageRef,
      scope: snapshot.semanticBand.name,
      tags: <String>[
        snapshot.semanticBand.name,
        if (snapshot.cadence != null) 'cadence',
      ],
    );
  }
}

class HowMechanismContext {
  const HowMechanismContext({
    required this.executionPath,
    required this.workflowStage,
    this.failureMechanism,
    this.mechanismConfidence,
    this.interventionChain = const <String>[],
    this.modelFamily,
  });

  final String executionPath;
  final String workflowStage;
  final String? failureMechanism;
  final double? mechanismConfidence;
  final List<String> interventionChain;
  final String? modelFamily;
}

class HowMechanismWhyEvidenceAdapter {
  const HowMechanismWhyEvidenceAdapter({
    this.sourceSubsystem = 'governance_gate',
  });

  final String sourceSubsystem;

  WhyEvidence toWhyEvidence(HowMechanismContext source) {
    final failureMechanism = source.failureMechanism ?? 'none';
    final isFailure = failureMechanism != 'none';
    final confidence = (source.mechanismConfidence ?? 0.72).clamp(0.0, 1.0);
    return WhyEvidence(
      id: 'how_${source.executionPath}_${source.workflowStage}',
      label: isFailure
          ? 'mechanism blocked at ${source.workflowStage}: $failureMechanism'
          : 'mechanism flowed via ${source.executionPath}',
      weight: confidence,
      polarity: isFailure
          ? WhyEvidencePolarity.negative
          : WhyEvidencePolarity.positive,
      sourceKernel: WhyEvidenceSourceKernel.how,
      sourceSubsystem: sourceSubsystem,
      durability: 'transient',
      confidence: confidence,
      observed: true,
      inferred: false,
      provenance: source.modelFamily ?? 'runtime',
      scope: source.workflowStage,
      tags: <String>[
        source.executionPath,
        source.workflowStage,
        ...source.interventionChain,
      ],
    );
  }
}
