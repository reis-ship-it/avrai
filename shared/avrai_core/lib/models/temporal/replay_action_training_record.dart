enum ReplayActionTrainingRecordKind {
  dailyAction,
  exchange,
  ai2aiRoute,
  movement,
}

class ReplayCounterfactualChoice {
  const ReplayCounterfactualChoice({
    required this.candidateId,
    required this.candidateType,
    required this.score,
    required this.confidence,
    required this.rejectionReason,
    this.blockingLane,
    this.metadata = const <String, dynamic>{},
  });

  final String candidateId;
  final String candidateType;
  final double score;
  final double confidence;
  final String rejectionReason;
  final String? blockingLane;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'candidateId': candidateId,
      'candidateType': candidateType,
      'score': score,
      'confidence': confidence,
      'rejectionReason': rejectionReason,
      'blockingLane': blockingLane,
      'metadata': metadata,
    };
  }

  factory ReplayCounterfactualChoice.fromJson(Map<String, dynamic> json) {
    return ReplayCounterfactualChoice(
      candidateId: json['candidateId'] as String? ?? '',
      candidateType: json['candidateType'] as String? ?? 'unknown',
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      rejectionReason: json['rejectionReason'] as String? ?? '',
      blockingLane: json['blockingLane'] as String?,
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}

class ReplayActionTrainingRecord {
  const ReplayActionTrainingRecord({
    required this.recordId,
    required this.actorId,
    required this.kind,
    required this.contextWindow,
    required this.contextId,
    required this.monthKey,
    required this.localityAnchor,
    required this.chosenId,
    required this.chosenType,
    required this.outcomeRef,
    required this.sourceProvenanceRefs,
    required this.confidence,
    required this.uncertainty,
    required this.activeKernelIds,
    required this.higherAgentGuidanceIds,
    required this.governanceDisposition,
    required this.counterfactuals,
    this.metadata = const <String, dynamic>{},
  });

  final String recordId;
  final String actorId;
  final ReplayActionTrainingRecordKind kind;
  final String contextWindow;
  final String contextId;
  final String monthKey;
  final String localityAnchor;
  final String chosenId;
  final String chosenType;
  final String outcomeRef;
  final List<String> sourceProvenanceRefs;
  final double confidence;
  final double uncertainty;
  final List<String> activeKernelIds;
  final List<String> higherAgentGuidanceIds;
  final String governanceDisposition;
  final List<ReplayCounterfactualChoice> counterfactuals;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'recordId': recordId,
      'actorId': actorId,
      'kind': kind.name,
      'contextWindow': contextWindow,
      'contextId': contextId,
      'monthKey': monthKey,
      'localityAnchor': localityAnchor,
      'chosenId': chosenId,
      'chosenType': chosenType,
      'outcomeRef': outcomeRef,
      'sourceProvenanceRefs': sourceProvenanceRefs,
      'confidence': confidence,
      'uncertainty': uncertainty,
      'activeKernelIds': activeKernelIds,
      'higherAgentGuidanceIds': higherAgentGuidanceIds,
      'governanceDisposition': governanceDisposition,
      'counterfactuals': counterfactuals.map((entry) => entry.toJson()).toList(),
      'metadata': metadata,
    };
  }

  factory ReplayActionTrainingRecord.fromJson(Map<String, dynamic> json) {
    return ReplayActionTrainingRecord(
      recordId: json['recordId'] as String? ?? '',
      actorId: json['actorId'] as String? ?? '',
      kind: ReplayActionTrainingRecordKind.values.firstWhere(
        (value) => value.name == json['kind'],
        orElse: () => ReplayActionTrainingRecordKind.dailyAction,
      ),
      contextWindow: json['contextWindow'] as String? ?? '',
      contextId: json['contextId'] as String? ?? '',
      monthKey: json['monthKey'] as String? ?? '',
      localityAnchor: json['localityAnchor'] as String? ?? '',
      chosenId: json['chosenId'] as String? ?? '',
      chosenType: json['chosenType'] as String? ?? 'unknown',
      outcomeRef: json['outcomeRef'] as String? ?? '',
      sourceProvenanceRefs: (json['sourceProvenanceRefs'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      uncertainty: (json['uncertainty'] as num?)?.toDouble() ?? 0.0,
      activeKernelIds: (json['activeKernelIds'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      higherAgentGuidanceIds: (json['higherAgentGuidanceIds'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      governanceDisposition:
          json['governanceDisposition'] as String? ?? 'admitted',
      counterfactuals: (json['counterfactuals'] as List?)
              ?.whereType<Map>()
              .map(
                (entry) => ReplayCounterfactualChoice.fromJson(
                  Map<String, dynamic>.from(entry),
                ),
              )
              .toList() ??
          const <ReplayCounterfactualChoice>[],
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}
