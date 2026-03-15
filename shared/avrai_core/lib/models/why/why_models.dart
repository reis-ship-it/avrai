enum WhyQueryKind {
  observedOutcome,
  recommendation,
  rejection,
  policyAction,
  behaviorPattern,
  modelUpdate;

  String toWireValue() => switch (this) {
        WhyQueryKind.observedOutcome => 'observed_outcome',
        WhyQueryKind.recommendation => 'recommendation',
        WhyQueryKind.rejection => 'rejection',
        WhyQueryKind.policyAction => 'policy_action',
        WhyQueryKind.behaviorPattern => 'behavior_pattern',
        WhyQueryKind.modelUpdate => 'model_update',
      };

  static WhyQueryKind fromWireValue(String? value) => switch (value) {
        'recommendation' => WhyQueryKind.recommendation,
        'rejection' => WhyQueryKind.rejection,
        'policy_action' => WhyQueryKind.policyAction,
        'behavior_pattern' => WhyQueryKind.behaviorPattern,
        'model_update' => WhyQueryKind.modelUpdate,
        _ => WhyQueryKind.observedOutcome,
      };
}

enum WhyRequestedPerspective {
  system,
  agent,
  userSafe,
  admin,
  governance;

  String toWireValue() => switch (this) {
        WhyRequestedPerspective.system => 'system',
        WhyRequestedPerspective.agent => 'agent',
        WhyRequestedPerspective.userSafe => 'user_safe',
        WhyRequestedPerspective.admin => 'admin',
        WhyRequestedPerspective.governance => 'governance',
      };

  static WhyRequestedPerspective fromWireValue(String? value) =>
      switch (value) {
        'agent' => WhyRequestedPerspective.agent,
        'user_safe' => WhyRequestedPerspective.userSafe,
        'admin' => WhyRequestedPerspective.admin,
        'governance' => WhyRequestedPerspective.governance,
        _ => WhyRequestedPerspective.system,
      };
}

enum WhyRootCauseType {
  traitDriven,
  contextDriven,
  socialDriven,
  temporal,
  locality,
  mechanistic,
  policyDriven,
  pheromone,
  mixed,
  unknown;

  String toWireValue() => switch (this) {
        WhyRootCauseType.traitDriven => 'trait_driven',
        WhyRootCauseType.contextDriven => 'context_driven',
        WhyRootCauseType.socialDriven => 'social_driven',
        WhyRootCauseType.temporal => 'temporal',
        WhyRootCauseType.locality => 'locality',
        WhyRootCauseType.mechanistic => 'mechanistic',
        WhyRootCauseType.policyDriven => 'policy_driven',
        WhyRootCauseType.pheromone => 'pheromone',
        WhyRootCauseType.mixed => 'mixed',
        WhyRootCauseType.unknown => 'unknown',
      };

  static WhyRootCauseType fromWireValue(String? value) => switch (value) {
        'trait_driven' => WhyRootCauseType.traitDriven,
        'context_driven' => WhyRootCauseType.contextDriven,
        'social_driven' => WhyRootCauseType.socialDriven,
        'temporal' => WhyRootCauseType.temporal,
        'locality' => WhyRootCauseType.locality,
        'mechanistic' => WhyRootCauseType.mechanistic,
        'policy_driven' => WhyRootCauseType.policyDriven,
        'pheromone' => WhyRootCauseType.pheromone,
        'mixed' => WhyRootCauseType.mixed,
        _ => WhyRootCauseType.unknown,
      };
}

enum WhyEvidencePolarity {
  positive,
  negative,
  neutral;

  String toWireValue() => switch (this) {
        WhyEvidencePolarity.positive => 'positive',
        WhyEvidencePolarity.negative => 'negative',
        WhyEvidencePolarity.neutral => 'neutral',
      };

  static WhyEvidencePolarity fromWireValue(String? value) => switch (value) {
        'negative' => WhyEvidencePolarity.negative,
        'neutral' => WhyEvidencePolarity.neutral,
        _ => WhyEvidencePolarity.positive,
      };
}

enum WhyEvidenceSourceKernel {
  who,
  what,
  where,
  when,
  how,
  social,
  policy,
  memory,
  model,
  external;

  String toWireValue() => name;

  static WhyEvidenceSourceKernel fromWireValue(String? value) =>
      switch (value) {
        'who' => WhyEvidenceSourceKernel.who,
        'where' => WhyEvidenceSourceKernel.where,
        'when' => WhyEvidenceSourceKernel.when,
        'how' => WhyEvidenceSourceKernel.how,
        'social' => WhyEvidenceSourceKernel.social,
        'policy' => WhyEvidenceSourceKernel.policy,
        'memory' => WhyEvidenceSourceKernel.memory,
        'model' => WhyEvidenceSourceKernel.model,
        'external' => WhyEvidenceSourceKernel.external,
        _ => WhyEvidenceSourceKernel.what,
      };
}

enum WhyValidationSeverity {
  warning,
  error;

  String toWireValue() => name;

  static WhyValidationSeverity fromWireValue(String? value) => switch (value) {
        'error' => WhyValidationSeverity.error,
        _ => WhyValidationSeverity.warning,
      };
}

class WhyRef {
  const WhyRef({
    required this.id,
    this.label,
    this.kind,
  });

  final String id;
  final String? label;
  final String? kind;

  Map<String, dynamic> toJson() => {
        'id': id,
        if (label != null) 'label': label,
        if (kind != null) 'kind': kind,
      };

  factory WhyRef.fromJson(Map<String, dynamic> json) {
    return WhyRef(
      id: json['id'] as String? ?? 'unknown',
      label: json['label'] as String?,
      kind: json['kind'] as String?,
    );
  }
}

class WhySignal {
  const WhySignal({
    required this.label,
    required this.weight,
    this.source,
    this.durable,
    this.confidence,
    this.evidenceId,
    this.kernel,
  });

  final String label;
  final double weight;
  final String? source;
  final bool? durable;
  final double? confidence;
  final String? evidenceId;
  final WhyEvidenceSourceKernel? kernel;

  Map<String, dynamic> toJson() => {
        'label': label,
        'weight': weight,
        if (source != null) 'source': source,
        if (durable != null) 'durable': durable,
        if (confidence != null) 'confidence': confidence,
        if (evidenceId != null) 'evidence_id': evidenceId,
        if (kernel != null) 'kernel': kernel!.toWireValue(),
      };

  factory WhySignal.fromJson(Map<String, dynamic> json) {
    return WhySignal(
      label: json['label'] as String? ?? 'unknown',
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      source: json['source'] as String?,
      durable: json['durable'] as bool?,
      confidence: (json['confidence'] as num?)?.toDouble(),
      evidenceId: json['evidence_id'] as String?,
      kernel: json['kernel'] == null
          ? null
          : WhyEvidenceSourceKernel.fromWireValue(json['kernel'] as String?),
    );
  }
}

class WhyEvidence {
  const WhyEvidence({
    required this.id,
    required this.label,
    required this.weight,
    required this.polarity,
    required this.sourceKernel,
    this.sourceSubsystem,
    this.durability,
    this.confidence,
    this.observed,
    this.inferred,
    this.provenance,
    this.timeRef,
    this.subjectRef,
    this.scope,
    this.tags = const <String>[],
  });

  final String id;
  final String label;
  final double weight;
  final WhyEvidencePolarity polarity;
  final WhyEvidenceSourceKernel sourceKernel;
  final String? sourceSubsystem;
  final String? durability;
  final double? confidence;
  final bool? observed;
  final bool? inferred;
  final String? provenance;
  final String? timeRef;
  final String? subjectRef;
  final String? scope;
  final List<String> tags;

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'weight': weight,
        'polarity': polarity.toWireValue(),
        'source_kernel': sourceKernel.toWireValue(),
        if (sourceSubsystem != null) 'source_subsystem': sourceSubsystem,
        if (durability != null) 'durability': durability,
        if (confidence != null) 'confidence': confidence,
        if (observed != null) 'observed': observed,
        if (inferred != null) 'inferred': inferred,
        if (provenance != null) 'provenance': provenance,
        if (timeRef != null) 'time_ref': timeRef,
        if (subjectRef != null) 'subject_ref': subjectRef,
        if (scope != null) 'scope': scope,
        'tags': tags,
      };

  factory WhyEvidence.fromJson(Map<String, dynamic> json) {
    return WhyEvidence(
      id: json['id'] as String? ?? 'evidence',
      label: json['label'] as String? ?? 'unknown',
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      polarity: WhyEvidencePolarity.fromWireValue(json['polarity'] as String?),
      sourceKernel: WhyEvidenceSourceKernel.fromWireValue(
        json['source_kernel'] as String?,
      ),
      sourceSubsystem: json['source_subsystem'] as String?,
      durability: json['durability'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble(),
      observed: json['observed'] as bool?,
      inferred: json['inferred'] as bool?,
      provenance: json['provenance'] as String?,
      timeRef: json['time_ref'] as String?,
      subjectRef: json['subject_ref'] as String?,
      scope: json['scope'] as String?,
      tags: ((json['tags'] as List?) ?? const <dynamic>[])
          .map((entry) => entry.toString())
          .toList(),
    );
  }

  WhySignal toSignal() {
    return WhySignal(
      label: label,
      weight: weight,
      source: sourceSubsystem ?? sourceKernel.toWireValue(),
      durable: durability == 'durable',
      confidence: confidence,
      evidenceId: id,
      kernel: sourceKernel,
    );
  }
}

class WhyEvidenceBundle {
  const WhyEvidenceBundle({
    this.entries = const <WhyEvidence>[],
  });

  final List<WhyEvidence> entries;

  Map<String, dynamic> toJson() => {
        'entries': entries.map((entry) => entry.toJson()).toList(),
      };

  factory WhyEvidenceBundle.fromJson(Map<String, dynamic> json) {
    final rawEntries = json['entries'];
    return WhyEvidenceBundle(
      entries: rawEntries is List
          ? rawEntries
              .map(
                (entry) => WhyEvidence.fromJson(
                    Map<String, dynamic>.from(entry as Map)),
              )
              .toList()
          : const <WhyEvidence>[],
    );
  }
}

class WhyCounterfactual {
  const WhyCounterfactual({
    required this.condition,
    required this.expectedEffect,
    required this.confidenceDelta,
    this.speculative = true,
  });

  final String condition;
  final String expectedEffect;
  final double confidenceDelta;
  final bool speculative;

  Map<String, dynamic> toJson() => {
        'condition': condition,
        'expected_effect': expectedEffect,
        'confidence_delta': confidenceDelta,
        'speculative': speculative,
      };

  factory WhyCounterfactual.fromJson(Map<String, dynamic> json) {
    return WhyCounterfactual(
      condition: json['condition'] as String? ?? 'unknown',
      expectedEffect: json['expected_effect'] as String? ?? 'unknown',
      confidenceDelta: (json['confidence_delta'] as num?)?.toDouble() ?? 0.0,
      speculative: json['speculative'] as bool? ?? true,
    );
  }
}

class WhyHypothesis {
  const WhyHypothesis({
    required this.id,
    required this.label,
    required this.rootCauseType,
    required this.confidence,
    this.supportingEvidenceIds = const <String>[],
    this.opposingEvidenceIds = const <String>[],
  });

  final String id;
  final String label;
  final WhyRootCauseType rootCauseType;
  final double confidence;
  final List<String> supportingEvidenceIds;
  final List<String> opposingEvidenceIds;

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'root_cause_type': rootCauseType.toWireValue(),
        'confidence': confidence,
        'supporting_evidence_ids': supportingEvidenceIds,
        'opposing_evidence_ids': opposingEvidenceIds,
      };

  factory WhyHypothesis.fromJson(Map<String, dynamic> json) {
    return WhyHypothesis(
      id: json['id'] as String? ?? 'hypothesis',
      label: json['label'] as String? ?? 'unknown',
      rootCauseType: WhyRootCauseType.fromWireValue(
        json['root_cause_type'] as String?,
      ),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      supportingEvidenceIds:
          ((json['supporting_evidence_ids'] as List?) ?? const <dynamic>[])
              .map((entry) => entry.toString())
              .toList(),
      opposingEvidenceIds:
          ((json['opposing_evidence_ids'] as List?) ?? const <dynamic>[])
              .map((entry) => entry.toString())
              .toList(),
    );
  }
}

class WhyTraceRef {
  const WhyTraceRef({
    required this.traceType,
    required this.kernel,
    this.entityId,
    this.eventId,
    this.timeRef,
    this.explanationRef,
  });

  final String traceType;
  final WhyEvidenceSourceKernel kernel;
  final String? entityId;
  final String? eventId;
  final String? timeRef;
  final String? explanationRef;

  Map<String, dynamic> toJson() => {
        'trace_type': traceType,
        'kernel': kernel.toWireValue(),
        if (entityId != null) 'entity_id': entityId,
        if (eventId != null) 'event_id': eventId,
        if (timeRef != null) 'time_ref': timeRef,
        if (explanationRef != null) 'explanation_ref': explanationRef,
      };

  factory WhyTraceRef.fromJson(Map<String, dynamic> json) {
    return WhyTraceRef(
      traceType: json['trace_type'] as String? ?? 'evidence',
      kernel: WhyEvidenceSourceKernel.fromWireValue(json['kernel'] as String?),
      entityId: json['entity_id'] as String?,
      eventId: json['event_id'] as String?,
      timeRef: json['time_ref'] as String?,
      explanationRef: json['explanation_ref'] as String?,
    );
  }
}

class WhyConflict {
  const WhyConflict({
    required this.label,
    required this.message,
    this.evidenceIds = const <String>[],
  });

  final String label;
  final String message;
  final List<String> evidenceIds;

  Map<String, dynamic> toJson() => {
        'label': label,
        'message': message,
        'evidence_ids': evidenceIds,
      };

  factory WhyConflict.fromJson(Map<String, dynamic> json) {
    return WhyConflict(
      label: json['label'] as String? ?? 'conflict',
      message: json['message'] as String? ?? 'unknown',
      evidenceIds: ((json['evidence_ids'] as List?) ?? const <dynamic>[])
          .map((entry) => entry.toString())
          .toList(),
    );
  }
}

class WhyGovernanceEnvelope {
  const WhyGovernanceEnvelope({
    this.redacted = false,
    this.redactionReason,
    this.policyRefs = const <String>[],
    this.escalationThresholds = const <String>[],
  });

  final bool redacted;
  final String? redactionReason;
  final List<String> policyRefs;
  final List<String> escalationThresholds;

  Map<String, dynamic> toJson() => {
        'redacted': redacted,
        if (redactionReason != null) 'redaction_reason': redactionReason,
        'policy_refs': policyRefs,
        'escalation_thresholds': escalationThresholds,
      };

  factory WhyGovernanceEnvelope.fromJson(Map<String, dynamic> json) {
    return WhyGovernanceEnvelope(
      redacted: json['redacted'] as bool? ?? false,
      redactionReason: json['redaction_reason'] as String?,
      policyRefs: ((json['policy_refs'] as List?) ?? const <dynamic>[])
          .map((entry) => entry.toString())
          .toList(),
      escalationThresholds:
          ((json['escalation_thresholds'] as List?) ?? const <dynamic>[])
              .map((entry) => entry.toString())
              .toList(),
    );
  }
}

class WhyAttributionSummary {
  const WhyAttributionSummary({
    required this.driverLabels,
    required this.inhibitorLabels,
    required this.topKernel,
  });

  final List<String> driverLabels;
  final List<String> inhibitorLabels;
  final String topKernel;

  Map<String, dynamic> toJson() => {
        'driver_labels': driverLabels,
        'inhibitor_labels': inhibitorLabels,
        'top_kernel': topKernel,
      };

  factory WhyAttributionSummary.fromJson(Map<String, dynamic> json) {
    return WhyAttributionSummary(
      driverLabels: ((json['driver_labels'] as List?) ?? const <dynamic>[])
          .map((entry) => entry.toString())
          .toList(),
      inhibitorLabels:
          ((json['inhibitor_labels'] as List?) ?? const <dynamic>[])
              .map((entry) => entry.toString())
              .toList(),
      topKernel: json['top_kernel'] as String? ?? 'unknown',
    );
  }
}

class WhyValidationIssue {
  const WhyValidationIssue({
    required this.severity,
    required this.code,
    required this.message,
    this.field,
  });

  final WhyValidationSeverity severity;
  final String code;
  final String message;
  final String? field;

  Map<String, dynamic> toJson() => {
        'severity': severity.toWireValue(),
        'code': code,
        'message': message,
        if (field != null) 'field': field,
      };

  factory WhyValidationIssue.fromJson(Map<String, dynamic> json) {
    return WhyValidationIssue(
      severity: WhyValidationSeverity.fromWireValue(
        json['severity'] as String?,
      ),
      code: json['code'] as String? ?? 'unknown',
      message: json['message'] as String? ?? 'unknown',
      field: json['field'] as String?,
    );
  }
}

class WhyKernelRequest {
  const WhyKernelRequest({
    this.goal,
    this.subjectRef,
    this.actionRef,
    this.outcomeRef,
    this.queryKind = WhyQueryKind.observedOutcome,
    this.evidenceBundle = const WhyEvidenceBundle(),
    this.linkedWhoRefs = const <WhyRef>[],
    this.linkedWhatRefs = const <WhyRef>[],
    this.linkedWhereRefs = const <WhyRef>[],
    this.linkedWhenRefs = const <WhyRef>[],
    this.linkedHowRefs = const <WhyRef>[],
    this.policyContext = const <String, dynamic>{},
    this.requestedPerspective = WhyRequestedPerspective.system,
    this.maxCounterfactuals = 2,
    this.explanationDepth = 2,
    this.action,
    this.outcome,
    this.entityId,
    this.coreSignals = const <WhySignal>[],
    this.pheromoneSignals = const <WhySignal>[],
    this.temporalSignals = const <WhySignal>[],
    this.localitySignals = const <WhySignal>[],
    this.socialSignals = const <WhySignal>[],
  });

  final String? goal;
  final WhyRef? subjectRef;
  final WhyRef? actionRef;
  final WhyRef? outcomeRef;
  final WhyQueryKind queryKind;
  final WhyEvidenceBundle evidenceBundle;
  final List<WhyRef> linkedWhoRefs;
  final List<WhyRef> linkedWhatRefs;
  final List<WhyRef> linkedWhereRefs;
  final List<WhyRef> linkedWhenRefs;
  final List<WhyRef> linkedHowRefs;
  final Map<String, dynamic> policyContext;
  final WhyRequestedPerspective requestedPerspective;
  final int maxCounterfactuals;
  final int explanationDepth;

  // Legacy compatibility fields.
  final String? action;
  final String? outcome;
  final String? entityId;
  final List<WhySignal> coreSignals;
  final List<WhySignal> pheromoneSignals;
  final List<WhySignal> temporalSignals;
  final List<WhySignal> localitySignals;
  final List<WhySignal> socialSignals;

  List<WhyEvidence> normalizedEvidence() {
    return <WhyEvidence>[
      ...evidenceBundle.entries,
      ..._legacySignalsToEvidence(
        coreSignals,
        kernel: WhyEvidenceSourceKernel.who,
        subsystem: 'core',
        durability: 'durable',
      ),
      ..._legacySignalsToEvidence(
        pheromoneSignals,
        kernel: WhyEvidenceSourceKernel.social,
        subsystem: 'pheromone',
        durability: 'transient',
      ),
      ..._legacySignalsToEvidence(
        temporalSignals,
        kernel: WhyEvidenceSourceKernel.when,
        subsystem: 'temporal',
        durability: 'transient',
      ),
      ..._legacySignalsToEvidence(
        localitySignals,
        kernel: WhyEvidenceSourceKernel.where,
        subsystem: 'locality',
        durability: 'transient',
      ),
      ..._legacySignalsToEvidence(
        socialSignals,
        kernel: WhyEvidenceSourceKernel.social,
        subsystem: 'social',
        durability: 'transient',
      ),
    ];
  }

  Map<String, dynamic> toJson() => {
        if (goal != null) 'goal': goal,
        if (subjectRef != null) 'subject_ref': subjectRef!.toJson(),
        if (actionRef != null) 'action_ref': actionRef!.toJson(),
        if (outcomeRef != null) 'outcome_ref': outcomeRef!.toJson(),
        'query_kind': queryKind.toWireValue(),
        'evidence_bundle': evidenceBundle.toJson(),
        'linked_who_refs':
            linkedWhoRefs.map((entry) => entry.toJson()).toList(),
        'linked_what_refs':
            linkedWhatRefs.map((entry) => entry.toJson()).toList(),
        'linked_where_refs':
            linkedWhereRefs.map((entry) => entry.toJson()).toList(),
        'linked_when_refs':
            linkedWhenRefs.map((entry) => entry.toJson()).toList(),
        'linked_how_refs':
            linkedHowRefs.map((entry) => entry.toJson()).toList(),
        'policy_context': policyContext,
        'requested_perspective': requestedPerspective.toWireValue(),
        'max_counterfactuals': maxCounterfactuals,
        'explanation_depth': explanationDepth,
        if (action != null) 'action': action,
        if (outcome != null) 'outcome': outcome,
        if (entityId != null) 'entity_id': entityId,
        'core_signals': coreSignals.map((entry) => entry.toJson()).toList(),
        'pheromone_signals':
            pheromoneSignals.map((entry) => entry.toJson()).toList(),
        'temporal_signals':
            temporalSignals.map((entry) => entry.toJson()).toList(),
        'locality_signals':
            localitySignals.map((entry) => entry.toJson()).toList(),
        'social_signals': socialSignals.map((entry) => entry.toJson()).toList(),
      };

  factory WhyKernelRequest.fromJson(Map<String, dynamic> json) {
    return WhyKernelRequest(
      goal: json['goal'] as String?,
      subjectRef: _refFromUnknown(json['subject_ref']),
      actionRef: _refFromUnknown(json['action_ref']),
      outcomeRef: _refFromUnknown(json['outcome_ref']),
      queryKind: WhyQueryKind.fromWireValue(json['query_kind'] as String?),
      evidenceBundle: json['evidence_bundle'] is Map
          ? WhyEvidenceBundle.fromJson(
              Map<String, dynamic>.from(json['evidence_bundle'] as Map),
            )
          : const WhyEvidenceBundle(),
      linkedWhoRefs: _refsFromUnknown(json['linked_who_refs']),
      linkedWhatRefs: _refsFromUnknown(json['linked_what_refs']),
      linkedWhereRefs: _refsFromUnknown(json['linked_where_refs']),
      linkedWhenRefs: _refsFromUnknown(json['linked_when_refs']),
      linkedHowRefs: _refsFromUnknown(json['linked_how_refs']),
      policyContext: Map<String, dynamic>.from(
        json['policy_context'] as Map? ?? const <String, dynamic>{},
      ),
      requestedPerspective: WhyRequestedPerspective.fromWireValue(
        json['requested_perspective'] as String?,
      ),
      maxCounterfactuals: (json['max_counterfactuals'] as num?)?.toInt() ?? 2,
      explanationDepth: (json['explanation_depth'] as num?)?.toInt() ?? 2,
      action: json['action'] as String?,
      outcome: json['outcome'] as String?,
      entityId: json['entity_id'] as String?,
      coreSignals: _signalsFromUnknown(json['core_signals']),
      pheromoneSignals: _signalsFromUnknown(json['pheromone_signals']),
      temporalSignals: _signalsFromUnknown(json['temporal_signals']),
      localitySignals: _signalsFromUnknown(json['locality_signals']),
      socialSignals: _signalsFromUnknown(json['social_signals']),
    );
  }
}

class WhySnapshot {
  const WhySnapshot({
    required this.goal,
    required this.drivers,
    required this.inhibitors,
    required this.confidence,
    required this.rootCauseType,
    required this.summary,
    required this.counterfactuals,
    this.queryKind = WhyQueryKind.observedOutcome,
    this.primaryHypothesis,
    this.alternateHypotheses = const <WhyHypothesis>[],
    this.ambiguity = 0.0,
    this.traceRefs = const <WhyTraceRef>[],
    this.conflicts = const <WhyConflict>[],
    this.governanceEnvelope = const WhyGovernanceEnvelope(),
    this.generatedAt,
    this.schemaVersion = 2,
    this.attributionSummary,
    this.validationIssues = const <WhyValidationIssue>[],
  });

  final String goal;
  final WhyQueryKind queryKind;
  final WhyHypothesis? primaryHypothesis;
  final List<WhyHypothesis> alternateHypotheses;
  final List<WhySignal> drivers;
  final List<WhySignal> inhibitors;
  final List<WhyCounterfactual> counterfactuals;
  final double confidence;
  final double ambiguity;
  final WhyRootCauseType rootCauseType;
  final String summary;
  final List<WhyTraceRef> traceRefs;
  final List<WhyConflict> conflicts;
  final WhyGovernanceEnvelope governanceEnvelope;
  final DateTime? generatedAt;
  final int schemaVersion;
  final WhyAttributionSummary? attributionSummary;
  final List<WhyValidationIssue> validationIssues;

  Map<String, dynamic> toJson() => {
        'goal': goal,
        'query_kind': queryKind.toWireValue(),
        if (primaryHypothesis != null)
          'primary_hypothesis': primaryHypothesis!.toJson(),
        'alternate_hypotheses':
            alternateHypotheses.map((entry) => entry.toJson()).toList(),
        'drivers': drivers.map((entry) => entry.toJson()).toList(),
        'inhibitors': inhibitors.map((entry) => entry.toJson()).toList(),
        'counterfactuals':
            counterfactuals.map((entry) => entry.toJson()).toList(),
        'confidence': confidence,
        'ambiguity': ambiguity,
        'root_cause_type': rootCauseType.toWireValue(),
        'summary': summary,
        'trace_refs': traceRefs.map((entry) => entry.toJson()).toList(),
        'conflicts': conflicts.map((entry) => entry.toJson()).toList(),
        'governance_envelope': governanceEnvelope.toJson(),
        'generated_at':
            (generatedAt ?? DateTime.now().toUtc()).toIso8601String(),
        'schema_version': schemaVersion,
        if (attributionSummary != null)
          'attribution_summary': attributionSummary!.toJson(),
        'validation_issues':
            validationIssues.map((entry) => entry.toJson()).toList(),
      };

  factory WhySnapshot.fromJson(Map<String, dynamic> json) {
    return WhySnapshot(
      goal: json['goal'] as String? ?? 'explain_outcome',
      queryKind: WhyQueryKind.fromWireValue(json['query_kind'] as String?),
      primaryHypothesis: json['primary_hypothesis'] is Map
          ? WhyHypothesis.fromJson(
              Map<String, dynamic>.from(json['primary_hypothesis'] as Map),
            )
          : null,
      alternateHypotheses: ((json['alternate_hypotheses'] as List?) ??
              const <dynamic>[])
          .map(
            (entry) =>
                WhyHypothesis.fromJson(Map<String, dynamic>.from(entry as Map)),
          )
          .toList(),
      drivers: _signalsFromUnknown(json['drivers']),
      inhibitors: _signalsFromUnknown(json['inhibitors']),
      counterfactuals: ((json['counterfactuals'] as List?) ?? const <dynamic>[])
          .map(
            (entry) => WhyCounterfactual.fromJson(
              Map<String, dynamic>.from(entry as Map),
            ),
          )
          .toList(),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      ambiguity: (json['ambiguity'] as num?)?.toDouble() ?? 0.0,
      rootCauseType: WhyRootCauseType.fromWireValue(
        json['root_cause_type'] as String?,
      ),
      summary: json['summary'] as String? ?? 'No causal attribution available.',
      traceRefs: ((json['trace_refs'] as List?) ?? const <dynamic>[])
          .map(
            (entry) =>
                WhyTraceRef.fromJson(Map<String, dynamic>.from(entry as Map)),
          )
          .toList(),
      conflicts: ((json['conflicts'] as List?) ?? const <dynamic>[])
          .map(
            (entry) =>
                WhyConflict.fromJson(Map<String, dynamic>.from(entry as Map)),
          )
          .toList(),
      governanceEnvelope: json['governance_envelope'] is Map
          ? WhyGovernanceEnvelope.fromJson(
              Map<String, dynamic>.from(json['governance_envelope'] as Map),
            )
          : const WhyGovernanceEnvelope(),
      generatedAt: json['generated_at'] is String
          ? DateTime.tryParse(json['generated_at'] as String)
          : null,
      schemaVersion: (json['schema_version'] as num?)?.toInt() ?? 1,
      attributionSummary: json['attribution_summary'] is Map
          ? WhyAttributionSummary.fromJson(
              Map<String, dynamic>.from(json['attribution_summary'] as Map),
            )
          : null,
      validationIssues:
          ((json['validation_issues'] as List?) ?? const <dynamic>[])
              .map(
                (entry) => WhyValidationIssue.fromJson(
                  Map<String, dynamic>.from(entry as Map),
                ),
              )
              .toList(),
    );
  }
}

List<WhyEvidence> _legacySignalsToEvidence(
  List<WhySignal> signals, {
  required WhyEvidenceSourceKernel kernel,
  required String subsystem,
  required String durability,
}) {
  return signals
      .map(
        (signal) => WhyEvidence(
          id: signal.evidenceId ?? '${subsystem}_${signal.label}',
          label: signal.label,
          weight: signal.weight.abs(),
          polarity: signal.weight < 0
              ? WhyEvidencePolarity.negative
              : WhyEvidencePolarity.positive,
          sourceKernel: signal.kernel ?? kernel,
          sourceSubsystem: signal.source ?? subsystem,
          durability: signal.durable == true ? 'durable' : durability,
          confidence: signal.confidence,
          observed: true,
          inferred: false,
          subjectRef: null,
          scope: subsystem,
          tags: <String>[subsystem],
        ),
      )
      .toList();
}

List<WhySignal> _signalsFromUnknown(Object? rawSignals) {
  return rawSignals is List
      ? rawSignals
          .map(
            (entry) =>
                WhySignal.fromJson(Map<String, dynamic>.from(entry as Map)),
          )
          .toList()
      : const <WhySignal>[];
}

WhyRef? _refFromUnknown(Object? rawRef) {
  if (rawRef is Map) {
    return WhyRef.fromJson(Map<String, dynamic>.from(rawRef));
  }
  return null;
}

List<WhyRef> _refsFromUnknown(Object? rawRefs) {
  return rawRefs is List
      ? rawRefs
          .map((entry) =>
              WhyRef.fromJson(Map<String, dynamic>.from(entry as Map)))
          .toList()
      : const <WhyRef>[];
}
