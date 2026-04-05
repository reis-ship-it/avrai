import 'package:avrai_core/models/why/why_models.dart';

class DefaultWhyKernelSupport {
  const DefaultWhyKernelSupport({
    this.policyGuard = const DefaultWhyPolicyGuard(),
  });

  final DefaultWhyPolicyGuard policyGuard;

  WhySnapshot explain(WhyKernelRequest request) {
    final evidence = request.normalizedEvidence();
    final validationIssues = _validate(request, evidence);
    final drivers = _rankSignals(
      evidence,
      polarity: WhyEvidencePolarity.positive,
    );
    final inhibitors = _rankSignals(
      evidence,
      polarity: WhyEvidencePolarity.negative,
    );
    final rootCauseType = _classifyRootCause(evidence, drivers, inhibitors);
    final confidence = _estimateConfidence(evidence, drivers, inhibitors);
    final ambiguity = _estimateAmbiguity(drivers, inhibitors);
    final counterfactuals = _buildCounterfactuals(
      drivers: drivers,
      inhibitors: inhibitors,
      maxCounterfactuals: request.maxCounterfactuals,
    );
    final conflicts = _buildConflicts(drivers, inhibitors);
    final traceRefs = _buildTraceRefs(evidence, request);
    final primaryHypothesis = _buildPrimaryHypothesis(
      rootCauseType: rootCauseType,
      confidence: confidence,
      drivers: drivers,
      inhibitors: inhibitors,
    );
    final alternateHypotheses = _buildAlternateHypotheses(
      rootCauseType: rootCauseType,
      confidence: confidence,
      drivers: drivers,
      inhibitors: inhibitors,
    );
    final snapshot = WhySnapshot(
      goal: _resolvedGoal(request),
      queryKind: request.queryKind,
      primaryHypothesis: primaryHypothesis,
      alternateHypotheses: alternateHypotheses,
      drivers: drivers,
      inhibitors: inhibitors,
      counterfactuals: counterfactuals,
      confidence: confidence,
      ambiguity: ambiguity,
      rootCauseType: rootCauseType,
      summary: _buildSummary(
        request: request,
        rootCauseType: rootCauseType,
        drivers: drivers,
        inhibitors: inhibitors,
        confidence: confidence,
      ),
      traceRefs: traceRefs,
      conflicts: conflicts,
      governanceEnvelope: _buildGovernanceEnvelope(request, evidence),
      generatedAt: DateTime.now().toUtc(),
      schemaVersion: 2,
      attributionSummary: WhyAttributionSummary(
        driverLabels: drivers.map((entry) => entry.label).toList(),
        inhibitorLabels: inhibitors.map((entry) => entry.label).toList(),
        topKernel: _topKernelLabel(drivers, inhibitors),
      ),
      validationIssues: validationIssues,
    );

    return policyGuard.filterForPerspective(
      snapshot,
      request.requestedPerspective,
    );
  }

  List<WhyValidationIssue> _validate(
    WhyKernelRequest request,
    List<WhyEvidence> evidence,
  ) {
    final issues = <WhyValidationIssue>[];
    if (evidence.isEmpty) {
      issues.add(
        const WhyValidationIssue(
          severity: WhyValidationSeverity.error,
          code: 'empty_evidence',
          message: 'No evidence was provided to explain why.',
          field: 'evidence_bundle',
        ),
      );
    }
    if (request.maxCounterfactuals < 0) {
      issues.add(
        const WhyValidationIssue(
          severity: WhyValidationSeverity.error,
          code: 'invalid_counterfactual_limit',
          message: 'max_counterfactuals must be zero or greater.',
          field: 'max_counterfactuals',
        ),
      );
    }
    for (final entry in evidence) {
      if (entry.weight.isNaN || entry.weight.isInfinite) {
        issues.add(
          WhyValidationIssue(
            severity: WhyValidationSeverity.error,
            code: 'invalid_weight',
            message: 'Evidence weight must be finite.',
            field: 'evidence.${entry.id}.weight',
          ),
        );
      }
      final confidence = entry.confidence;
      if (confidence != null && (confidence < 0 || confidence > 1)) {
        issues.add(
          WhyValidationIssue(
            severity: WhyValidationSeverity.warning,
            code: 'confidence_out_of_range',
            message: 'Evidence confidence should be between 0 and 1.',
            field: 'evidence.${entry.id}.confidence',
          ),
        );
      }
    }
    return issues;
  }

  List<WhySignal> _rankSignals(
    List<WhyEvidence> evidence, {
    required WhyEvidencePolarity polarity,
  }) {
    final ranked = evidence
        .where((entry) => entry.polarity == polarity)
        .map((entry) => entry.toSignal())
        .toList();
    ranked.sort((left, right) => right.weight.compareTo(left.weight));
    return ranked.take(3).toList();
  }

  WhyRootCauseType _classifyRootCause(
    List<WhyEvidence> evidence,
    List<WhySignal> drivers,
    List<WhySignal> inhibitors,
  ) {
    final activeKernels =
        evidence.map((entry) => entry.sourceKernel).toSet().length;
    if (activeKernels > 1) {
      return WhyRootCauseType.mixed;
    }

    final dominantKernel = _topKernel(drivers, inhibitors);
    return switch (dominantKernel) {
      WhyEvidenceSourceKernel.who => WhyRootCauseType.traitDriven,
      WhyEvidenceSourceKernel.where => WhyRootCauseType.locality,
      WhyEvidenceSourceKernel.when => WhyRootCauseType.temporal,
      WhyEvidenceSourceKernel.how => WhyRootCauseType.mechanistic,
      WhyEvidenceSourceKernel.policy => WhyRootCauseType.policyDriven,
      WhyEvidenceSourceKernel.social => WhyRootCauseType.socialDriven,
      WhyEvidenceSourceKernel.memory ||
      WhyEvidenceSourceKernel.model ||
      WhyEvidenceSourceKernel.what ||
      WhyEvidenceSourceKernel.external =>
        WhyRootCauseType.contextDriven,
      null => WhyRootCauseType.unknown,
    };
  }

  double _estimateConfidence(
    List<WhyEvidence> evidence,
    List<WhySignal> drivers,
    List<WhySignal> inhibitors,
  ) {
    if (evidence.isEmpty) {
      return 0.0;
    }
    final topDriver = drivers.isEmpty ? 0.0 : drivers.first.weight;
    final topInhibitor = inhibitors.isEmpty ? 0.0 : inhibitors.first.weight;
    final dominant = topDriver > topInhibitor ? topDriver : topInhibitor;
    final coverage = (evidence.length / 8.0).clamp(0.0, 1.0);
    final explicitConfidence = evidence
            .map((entry) => entry.confidence ?? 0.5)
            .fold<double>(0.0, (sum, value) => sum + value) /
        evidence.length;
    return ((dominant.clamp(0.0, 1.0) * 0.55) +
            (coverage * 0.2) +
            (explicitConfidence.clamp(0.0, 1.0) * 0.25))
        .clamp(0.0, 1.0);
  }

  double _estimateAmbiguity(
    List<WhySignal> drivers,
    List<WhySignal> inhibitors,
  ) {
    if (drivers.isEmpty || inhibitors.isEmpty) {
      return drivers.isEmpty && inhibitors.isEmpty ? 1.0 : 0.15;
    }
    final delta = (drivers.first.weight - inhibitors.first.weight).abs();
    return (1.0 - delta.clamp(0.0, 1.0)).clamp(0.0, 1.0);
  }

  List<WhyCounterfactual> _buildCounterfactuals({
    required List<WhySignal> drivers,
    required List<WhySignal> inhibitors,
    required int maxCounterfactuals,
  }) {
    final counterfactuals = <WhyCounterfactual>[];
    if (maxCounterfactuals <= 0) {
      return counterfactuals;
    }
    if (inhibitors.isNotEmpty) {
      counterfactuals.add(
        WhyCounterfactual(
          condition: 'Reduce ${inhibitors.first.label}',
          expectedEffect: 'Outcome is more likely to improve',
          confidenceDelta: (inhibitors.first.weight * 0.35).clamp(0.0, 0.35),
        ),
      );
    }
    if (counterfactuals.length < maxCounterfactuals && drivers.isNotEmpty) {
      counterfactuals.add(
        WhyCounterfactual(
          condition: 'Increase ${drivers.first.label}',
          expectedEffect: 'Outcome is more likely to repeat',
          confidenceDelta: (drivers.first.weight * 0.25).clamp(0.0, 0.25),
        ),
      );
    }
    return counterfactuals.take(maxCounterfactuals).toList();
  }

  List<WhyConflict> _buildConflicts(
    List<WhySignal> drivers,
    List<WhySignal> inhibitors,
  ) {
    if (drivers.isEmpty || inhibitors.isEmpty) {
      return const <WhyConflict>[];
    }
    return <WhyConflict>[
      WhyConflict(
        label: 'dominant_tension',
        message:
            '${drivers.first.label} is being opposed by ${inhibitors.first.label}.',
        evidenceIds: <String>[
          if (drivers.first.evidenceId != null) drivers.first.evidenceId!,
          if (inhibitors.first.evidenceId != null) inhibitors.first.evidenceId!,
        ],
      ),
    ];
  }

  List<WhyTraceRef> _buildTraceRefs(
    List<WhyEvidence> evidence,
    WhyKernelRequest request,
  ) {
    return evidence.take(4).map((entry) {
      return WhyTraceRef(
        traceType: 'evidence',
        kernel: entry.sourceKernel,
        entityId:
            entry.subjectRef ?? request.entityId ?? request.subjectRef?.id,
        eventId: entry.id,
        timeRef: entry.timeRef,
        explanationRef: request.goal,
      );
    }).toList();
  }

  WhyHypothesis _buildPrimaryHypothesis({
    required WhyRootCauseType rootCauseType,
    required double confidence,
    required List<WhySignal> drivers,
    required List<WhySignal> inhibitors,
  }) {
    return WhyHypothesis(
      id: 'primary',
      label: _topHypothesisLabel(rootCauseType, drivers, inhibitors),
      rootCauseType: rootCauseType,
      confidence: confidence,
      supportingEvidenceIds: drivers
          .map((entry) => entry.evidenceId)
          .whereType<String>()
          .take(3)
          .toList(),
      opposingEvidenceIds: inhibitors
          .map((entry) => entry.evidenceId)
          .whereType<String>()
          .take(3)
          .toList(),
    );
  }

  List<WhyHypothesis> _buildAlternateHypotheses({
    required WhyRootCauseType rootCauseType,
    required double confidence,
    required List<WhySignal> drivers,
    required List<WhySignal> inhibitors,
  }) {
    if (drivers.length < 2 && inhibitors.length < 2) {
      return const <WhyHypothesis>[];
    }
    final alternateLabel = drivers.length > 1
        ? 'Alternate driver ${drivers[1].label}'
        : 'Alternate inhibitor ${inhibitors[1].label}';
    return <WhyHypothesis>[
      WhyHypothesis(
        id: 'alternate_1',
        label: alternateLabel,
        rootCauseType: rootCauseType,
        confidence: (confidence * 0.82).clamp(0.0, 1.0),
        supportingEvidenceIds: drivers
            .skip(1)
            .map((entry) => entry.evidenceId)
            .whereType<String>()
            .take(2)
            .toList(),
        opposingEvidenceIds: inhibitors
            .skip(1)
            .map((entry) => entry.evidenceId)
            .whereType<String>()
            .take(2)
            .toList(),
      ),
    ];
  }

  WhyGovernanceEnvelope _buildGovernanceEnvelope(
    WhyKernelRequest request,
    List<WhyEvidence> evidence,
  ) {
    final policyRefs = <String>[
      ...((request.policyContext['policyRefs'] as List?) ?? const <dynamic>[])
          .map((entry) => entry.toString()),
      ...evidence
          .where(
              (entry) => entry.sourceKernel == WhyEvidenceSourceKernel.policy)
          .map((entry) => entry.id),
    ];
    final escalationThresholds =
        ((request.policyContext['escalationThresholds'] as List?) ??
                const <dynamic>[])
            .map((entry) => entry.toString())
            .toList();
    return WhyGovernanceEnvelope(
      redacted: false,
      policyRefs: policyRefs,
      escalationThresholds: escalationThresholds,
    );
  }

  String _buildSummary({
    required WhyKernelRequest request,
    required WhyRootCauseType rootCauseType,
    required List<WhySignal> drivers,
    required List<WhySignal> inhibitors,
    required double confidence,
  }) {
    final actionLabel =
        request.actionRef?.label ?? request.action ?? 'decision';
    final outcomeLabel =
        request.outcomeRef?.label ?? request.outcome ?? 'observed outcome';
    final leadDriver =
        drivers.isEmpty ? 'limited positive evidence' : drivers.first.label;
    final leadInhibitor = inhibitors.isEmpty
        ? 'limited opposing evidence'
        : inhibitors.first.label;
    return '$actionLabel produced $outcomeLabel primarily due to '
        '${rootCauseType.toWireValue()} signals, led by $leadDriver, '
        'with $leadInhibitor as the main inhibitor. '
        'Confidence ${confidence.toStringAsFixed(2)}.';
  }

  String _resolvedGoal(WhyKernelRequest request) {
    if (request.goal != null && request.goal!.trim().isNotEmpty) {
      return request.goal!;
    }
    final actionLabel = request.actionRef?.label ?? request.action;
    if (actionLabel != null && actionLabel.trim().isNotEmpty) {
      return 'optimize_$actionLabel';
    }
    return 'explain_outcome';
  }

  WhyEvidenceSourceKernel? _topKernel(
    List<WhySignal> drivers,
    List<WhySignal> inhibitors,
  ) {
    final ranked = <WhySignal>[...drivers, ...inhibitors];
    ranked.sort((left, right) => right.weight.compareTo(left.weight));
    return ranked.isEmpty ? null : ranked.first.kernel;
  }

  String _topKernelLabel(
    List<WhySignal> drivers,
    List<WhySignal> inhibitors,
  ) {
    return _topKernel(drivers, inhibitors)?.toWireValue() ?? 'unknown';
  }

  String _topHypothesisLabel(
    WhyRootCauseType rootCauseType,
    List<WhySignal> drivers,
    List<WhySignal> inhibitors,
  ) {
    final leadDriver = drivers.isEmpty ? 'weak support' : drivers.first.label;
    final leadInhibitor =
        inhibitors.isEmpty ? 'weak opposition' : inhibitors.first.label;
    return '${rootCauseType.toWireValue()} attribution driven by '
        '$leadDriver and opposed by $leadInhibitor';
  }
}

class DefaultWhyPolicyGuard {
  const DefaultWhyPolicyGuard();

  WhySnapshot filterForPerspective(
    WhySnapshot snapshot,
    WhyRequestedPerspective perspective,
  ) {
    return switch (perspective) {
      WhyRequestedPerspective.system => snapshot,
      WhyRequestedPerspective.governance => snapshot,
      WhyRequestedPerspective.admin => snapshot,
      WhyRequestedPerspective.agent => _limited(snapshot, 'agent_redaction'),
      WhyRequestedPerspective.userSafe =>
        _limited(snapshot, 'user_safe_redaction'),
    };
  }

  WhySnapshot _limited(WhySnapshot snapshot, String reason) {
    return WhySnapshot(
      goal: snapshot.goal,
      queryKind: snapshot.queryKind,
      primaryHypothesis: snapshot.primaryHypothesis,
      alternateHypotheses: snapshot.alternateHypotheses,
      drivers: snapshot.drivers,
      inhibitors: snapshot.inhibitors,
      counterfactuals: snapshot.counterfactuals,
      confidence: snapshot.confidence,
      ambiguity: snapshot.ambiguity,
      rootCauseType: snapshot.rootCauseType,
      summary: snapshot.summary,
      traceRefs: const <WhyTraceRef>[],
      conflicts: const <WhyConflict>[],
      governanceEnvelope: WhyGovernanceEnvelope(
        redacted: true,
        redactionReason: reason,
      ),
      generatedAt: snapshot.generatedAt,
      schemaVersion: snapshot.schemaVersion,
      attributionSummary: snapshot.attributionSummary,
      validationIssues: snapshot.validationIssues,
    );
  }
}
