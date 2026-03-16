enum ReplayScenarioKind {
  eventOps,
  weather,
  venueOverload,
  localityDisruption,
  transitFriction,
  staffingPressure,
}

enum ReplayInterventionKind {
  attendanceSurge,
  venueClosure,
  weatherShift,
  staffingLoss,
  transitDelay,
  localityCaution,
  routeBlock,
}

enum ReplayScopeKind {
  city,
  locality,
  corridor,
  venue,
}

enum ReplayContradictionType {
  movement,
  attendance,
  delivery,
  localityPressure,
  safetyStress,
  routeOutcome,
}

enum ReplayContradictionStatus {
  open,
  decayed,
  resolved,
}

class ReplayScenarioIntervention {
  const ReplayScenarioIntervention({
    required this.interventionId,
    required this.kind,
    required this.targetType,
    required this.targetRef,
    required this.effectiveStart,
    required this.effectiveEnd,
    required this.magnitude,
    this.notes = '',
  });

  final String interventionId;
  final ReplayInterventionKind kind;
  final String targetType;
  final String targetRef;
  final DateTime effectiveStart;
  final DateTime effectiveEnd;
  final double magnitude;
  final String notes;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'interventionId': interventionId,
      'kind': kind.name,
      'targetType': targetType,
      'targetRef': targetRef,
      'effectiveStart': effectiveStart.toUtc().toIso8601String(),
      'effectiveEnd': effectiveEnd.toUtc().toIso8601String(),
      'magnitude': magnitude,
      'notes': _sanitizeText(notes),
    };
  }

  factory ReplayScenarioIntervention.fromJson(Map<String, dynamic> json) {
    return ReplayScenarioIntervention(
      interventionId: json['interventionId'] as String? ?? '',
      kind: ReplayInterventionKind.values.firstWhere(
        (value) => value.name == json['kind'],
        orElse: () => ReplayInterventionKind.localityCaution,
      ),
      targetType: json['targetType'] as String? ?? 'locality',
      targetRef: json['targetRef'] as String? ?? '',
      effectiveStart: DateTime.tryParse(
            json['effectiveStart'] as String? ?? '',
          )?.toUtc() ??
          DateTime.utc(2023, 1, 1),
      effectiveEnd: DateTime.tryParse(
            json['effectiveEnd'] as String? ?? '',
          )?.toUtc() ??
          DateTime.utc(2023, 1, 1),
      magnitude: (json['magnitude'] as num?)?.toDouble() ?? 0.0,
      notes: _sanitizeText(json['notes'] as String? ?? ''),
    );
  }
}

class ReplayScenarioPacket {
  const ReplayScenarioPacket({
    required this.scenarioId,
    required this.name,
    required this.description,
    required this.cityCode,
    required this.baseReplayYear,
    required this.scenarioKind,
    required this.scope,
    required this.seedEntityRefs,
    required this.seedLocalityCodes,
    required this.seedObservationRefs,
    required this.interventions,
    required this.expectedQuestions,
    required this.createdAt,
    required this.createdBy,
    this.isReplayOnly = true,
  });

  static const int requiredBhamReplayYear = 2023;

  final String scenarioId;
  final String name;
  final String description;
  final String cityCode;
  final int baseReplayYear;
  final ReplayScenarioKind scenarioKind;
  final ReplayScopeKind scope;
  final List<String> seedEntityRefs;
  final List<String> seedLocalityCodes;
  final List<String> seedObservationRefs;
  final List<ReplayScenarioIntervention> interventions;
  final List<String> expectedQuestions;
  final DateTime createdAt;
  final String createdBy;
  final bool isReplayOnly;

  bool get isValidForPhase1 =>
      baseReplayYear == requiredBhamReplayYear && isReplayOnly;

  ReplayScenarioPacket normalized() {
    return ReplayScenarioPacket(
      scenarioId: scenarioId,
      name: _sanitizeText(name),
      description: _sanitizeText(description),
      cityCode: cityCode,
      baseReplayYear: requiredBhamReplayYear,
      scenarioKind: scenarioKind,
      scope: scope,
      seedEntityRefs: seedEntityRefs.toList(growable: false),
      seedLocalityCodes: seedLocalityCodes.toList(growable: false),
      seedObservationRefs: seedObservationRefs.toList(growable: false),
      interventions: interventions.toList(growable: false),
      expectedQuestions:
          expectedQuestions.map(_sanitizeText).toList(growable: false),
      createdAt: createdAt.toUtc(),
      createdBy: _sanitizeText(createdBy),
      isReplayOnly: true,
    );
  }

  Map<String, dynamic> toJson() {
    final normalizedPacket = normalized();
    return <String, dynamic>{
      'scenarioId': normalizedPacket.scenarioId,
      'name': normalizedPacket.name,
      'description': normalizedPacket.description,
      'cityCode': normalizedPacket.cityCode,
      'baseReplayYear': requiredBhamReplayYear,
      'scenarioKind': normalizedPacket.scenarioKind.name,
      'scope': normalizedPacket.scope.name,
      'seedEntityRefs': normalizedPacket.seedEntityRefs,
      'seedLocalityCodes': normalizedPacket.seedLocalityCodes,
      'seedObservationRefs': normalizedPacket.seedObservationRefs,
      'interventions': normalizedPacket.interventions
          .map((entry) => entry.toJson())
          .toList(),
      'expectedQuestions': normalizedPacket.expectedQuestions,
      'createdAt': normalizedPacket.createdAt.toIso8601String(),
      'createdBy': normalizedPacket.createdBy,
      'isReplayOnly': true,
    };
  }

  factory ReplayScenarioPacket.fromJson(Map<String, dynamic> json) {
    return ReplayScenarioPacket(
      scenarioId: json['scenarioId'] as String? ?? '',
      name: _sanitizeText(json['name'] as String? ?? ''),
      description: _sanitizeText(json['description'] as String? ?? ''),
      cityCode: json['cityCode'] as String? ?? 'bham',
      baseReplayYear: requiredBhamReplayYear,
      scenarioKind: ReplayScenarioKind.values.firstWhere(
        (value) => value.name == json['scenarioKind'],
        orElse: () => ReplayScenarioKind.eventOps,
      ),
      scope: ReplayScopeKind.values.firstWhere(
        (value) => value.name == json['scope'],
        orElse: () => ReplayScopeKind.city,
      ),
      seedEntityRefs: _stringList(json['seedEntityRefs']),
      seedLocalityCodes: _stringList(json['seedLocalityCodes']),
      seedObservationRefs: _stringList(json['seedObservationRefs']),
      interventions: (json['interventions'] as List?)
              ?.whereType<Map>()
              .map(
                (entry) => ReplayScenarioIntervention.fromJson(
                  Map<String, dynamic>.from(entry),
                ),
              )
              .toList(growable: false) ??
          const <ReplayScenarioIntervention>[],
      expectedQuestions: _stringList(json['expectedQuestions']),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '')?.toUtc() ??
              DateTime.utc(2023, 1, 1),
      createdBy: _sanitizeText(json['createdBy'] as String? ?? 'internal'),
      isReplayOnly: true,
    );
  }
}

class ReplayScenarioBranchDiff {
  const ReplayScenarioBranchDiff({
    required this.branchRunId,
    required this.attendanceDelta,
    required this.movementDelta,
    required this.deliveryDelta,
    required this.safetyStressDelta,
    required this.localityPressureDeltas,
    required this.keyNarrativeLines,
  });

  final String branchRunId;
  final double attendanceDelta;
  final double movementDelta;
  final double deliveryDelta;
  final double safetyStressDelta;
  final Map<String, double> localityPressureDeltas;
  final List<String> keyNarrativeLines;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'branchRunId': branchRunId,
      'attendanceDelta': attendanceDelta,
      'movementDelta': movementDelta,
      'deliveryDelta': deliveryDelta,
      'safetyStressDelta': safetyStressDelta,
      'localityPressureDeltas': localityPressureDeltas,
      'keyNarrativeLines': keyNarrativeLines.map(_sanitizeText).toList(),
    };
  }

  factory ReplayScenarioBranchDiff.fromJson(Map<String, dynamic> json) {
    return ReplayScenarioBranchDiff(
      branchRunId: json['branchRunId'] as String? ?? '',
      attendanceDelta: (json['attendanceDelta'] as num?)?.toDouble() ?? 0.0,
      movementDelta: (json['movementDelta'] as num?)?.toDouble() ?? 0.0,
      deliveryDelta: (json['deliveryDelta'] as num?)?.toDouble() ?? 0.0,
      safetyStressDelta: (json['safetyStressDelta'] as num?)?.toDouble() ?? 0.0,
      localityPressureDeltas: (json['localityPressureDeltas'] as Map?)?.map(
            (key, value) => MapEntry(
              key.toString(),
              (value as num?)?.toDouble() ?? 0.0,
            ),
          ) ??
          const <String, double>{},
      keyNarrativeLines: _stringList(json['keyNarrativeLines']),
    );
  }
}

class ReplayScenarioComparison {
  const ReplayScenarioComparison({
    required this.scenarioId,
    required this.baselineRunId,
    required this.branchRunIds,
    required this.branchDiffs,
    required this.summary,
    required this.generatedAt,
  });

  final String scenarioId;
  final String baselineRunId;
  final List<String> branchRunIds;
  final List<ReplayScenarioBranchDiff> branchDiffs;
  final String summary;
  final DateTime generatedAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'scenarioId': scenarioId,
      'baselineRunId': baselineRunId,
      'branchRunIds': branchRunIds,
      'branchDiffs': branchDiffs.map((entry) => entry.toJson()).toList(),
      'summary': _sanitizeText(summary),
      'generatedAt': generatedAt.toUtc().toIso8601String(),
    };
  }

  factory ReplayScenarioComparison.fromJson(Map<String, dynamic> json) {
    return ReplayScenarioComparison(
      scenarioId: json['scenarioId'] as String? ?? '',
      baselineRunId: json['baselineRunId'] as String? ?? '',
      branchRunIds: _stringList(json['branchRunIds']),
      branchDiffs: (json['branchDiffs'] as List?)
              ?.whereType<Map>()
              .map(
                (entry) => ReplayScenarioBranchDiff.fromJson(
                  Map<String, dynamic>.from(entry),
                ),
              )
              .toList(growable: false) ??
          const <ReplayScenarioBranchDiff>[],
      summary: _sanitizeText(json['summary'] as String? ?? ''),
      generatedAt:
          DateTime.tryParse(json['generatedAt'] as String? ?? '')?.toUtc() ??
              DateTime.utc(2023, 1, 1),
    );
  }
}

class SimulationTruthSummaryBlock {
  const SimulationTruthSummaryBlock({
    required this.title,
    required this.lines,
    this.metadata = const <String, dynamic>{},
  });

  final String title;
  final List<String> lines;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'title': _sanitizeText(title),
      'lines': lines.map(_sanitizeText).toList(),
      'metadata': metadata,
    };
  }

  factory SimulationTruthSummaryBlock.fromJson(Map<String, dynamic> json) {
    return SimulationTruthSummaryBlock(
      title: _sanitizeText(json['title'] as String? ?? ''),
      lines: _stringList(json['lines']),
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}

class SimulationTruthReceipt {
  const SimulationTruthReceipt({
    required this.receiptId,
    required this.runId,
    required this.scenarioId,
    required this.forecastTraceRefs,
    required this.replayPriorSummary,
    required this.liveEvidenceSummary,
    required this.localityConsensusSummary,
    required this.adminCorrectionSummary,
    required this.contradictionSummary,
    required this.generatedAt,
  });

  final String receiptId;
  final String runId;
  final String scenarioId;
  final List<String> forecastTraceRefs;
  final SimulationTruthSummaryBlock replayPriorSummary;
  final SimulationTruthSummaryBlock liveEvidenceSummary;
  final SimulationTruthSummaryBlock localityConsensusSummary;
  final SimulationTruthSummaryBlock adminCorrectionSummary;
  final SimulationTruthSummaryBlock contradictionSummary;
  final DateTime generatedAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'receiptId': receiptId,
      'runId': runId,
      'scenarioId': scenarioId,
      'forecastTraceRefs': forecastTraceRefs,
      'replayPriorSummary': replayPriorSummary.toJson(),
      'liveEvidenceSummary': liveEvidenceSummary.toJson(),
      'localityConsensusSummary': localityConsensusSummary.toJson(),
      'adminCorrectionSummary': adminCorrectionSummary.toJson(),
      'contradictionSummary': contradictionSummary.toJson(),
      'generatedAt': generatedAt.toUtc().toIso8601String(),
    };
  }

  factory SimulationTruthReceipt.fromJson(Map<String, dynamic> json) {
    return SimulationTruthReceipt(
      receiptId: json['receiptId'] as String? ?? '',
      runId: json['runId'] as String? ?? '',
      scenarioId: json['scenarioId'] as String? ?? '',
      forecastTraceRefs: _stringList(json['forecastTraceRefs']),
      replayPriorSummary: SimulationTruthSummaryBlock.fromJson(
        Map<String, dynamic>.from(
          json['replayPriorSummary'] as Map? ?? const {},
        ),
      ),
      liveEvidenceSummary: SimulationTruthSummaryBlock.fromJson(
        Map<String, dynamic>.from(
          json['liveEvidenceSummary'] as Map? ?? const {},
        ),
      ),
      localityConsensusSummary: SimulationTruthSummaryBlock.fromJson(
        Map<String, dynamic>.from(
          json['localityConsensusSummary'] as Map? ?? const {},
        ),
      ),
      adminCorrectionSummary: SimulationTruthSummaryBlock.fromJson(
        Map<String, dynamic>.from(
          json['adminCorrectionSummary'] as Map? ?? const {},
        ),
      ),
      contradictionSummary: SimulationTruthSummaryBlock.fromJson(
        Map<String, dynamic>.from(
          json['contradictionSummary'] as Map? ?? const {},
        ),
      ),
      generatedAt:
          DateTime.tryParse(json['generatedAt'] as String? ?? '')?.toUtc() ??
              DateTime.utc(2023, 1, 1),
    );
  }
}

class ReplayContradictionSnapshot {
  const ReplayContradictionSnapshot({
    required this.snapshotId,
    required this.runId,
    required this.entityRef,
    required this.localityCode,
    required this.contradictionType,
    required this.replayExpectation,
    required this.liveObserved,
    required this.severity,
    required this.status,
    required this.capturedAt,
  });

  final String snapshotId;
  final String runId;
  final String entityRef;
  final String localityCode;
  final ReplayContradictionType contradictionType;
  final String replayExpectation;
  final String liveObserved;
  final double severity;
  final ReplayContradictionStatus status;
  final DateTime capturedAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'snapshotId': snapshotId,
      'runId': runId,
      'entityRef': entityRef,
      'localityCode': localityCode,
      'contradictionType': contradictionType.name,
      'replayExpectation': _sanitizeText(replayExpectation),
      'liveObserved': _sanitizeText(liveObserved),
      'severity': severity,
      'status': status.name,
      'capturedAt': capturedAt.toUtc().toIso8601String(),
    };
  }

  factory ReplayContradictionSnapshot.fromJson(Map<String, dynamic> json) {
    return ReplayContradictionSnapshot(
      snapshotId: json['snapshotId'] as String? ?? '',
      runId: json['runId'] as String? ?? '',
      entityRef: json['entityRef'] as String? ?? '',
      localityCode: json['localityCode'] as String? ?? '',
      contradictionType: ReplayContradictionType.values.firstWhere(
        (value) => value.name == json['contradictionType'],
        orElse: () => ReplayContradictionType.localityPressure,
      ),
      replayExpectation: _sanitizeText(
        json['replayExpectation'] as String? ?? '',
      ),
      liveObserved: _sanitizeText(json['liveObserved'] as String? ?? ''),
      severity: (json['severity'] as num?)?.toDouble() ?? 0.0,
      status: ReplayContradictionStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => ReplayContradictionStatus.open,
      ),
      capturedAt:
          DateTime.tryParse(json['capturedAt'] as String? ?? '')?.toUtc() ??
              DateTime.utc(2023, 1, 1),
    );
  }
}

class ReplayLocalityOverlaySnapshot {
  const ReplayLocalityOverlaySnapshot({
    required this.localityCode,
    required this.displayName,
    required this.pressureBand,
    required this.attentionBand,
    required this.primarySignals,
    required this.branchSensitivity,
    required this.contradictionCount,
    required this.updatedAt,
  });

  final String localityCode;
  final String displayName;
  final String pressureBand;
  final String attentionBand;
  final List<String> primarySignals;
  final double branchSensitivity;
  final int contradictionCount;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'localityCode': localityCode,
      'displayName': _sanitizeText(displayName),
      'pressureBand': pressureBand,
      'attentionBand': attentionBand,
      'primarySignals': primarySignals.map(_sanitizeText).toList(),
      'branchSensitivity': branchSensitivity,
      'contradictionCount': contradictionCount,
      'updatedAt': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory ReplayLocalityOverlaySnapshot.fromJson(Map<String, dynamic> json) {
    return ReplayLocalityOverlaySnapshot(
      localityCode: json['localityCode'] as String? ?? '',
      displayName: _sanitizeText(json['displayName'] as String? ?? ''),
      pressureBand: json['pressureBand'] as String? ?? 'moderate',
      attentionBand: json['attentionBand'] as String? ?? 'watch',
      primarySignals: _stringList(json['primarySignals']),
      branchSensitivity: (json['branchSensitivity'] as num?)?.toDouble() ?? 0.0,
      contradictionCount: (json['contradictionCount'] as num?)?.toInt() ?? 0,
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '')?.toUtc() ??
              DateTime.utc(2023, 1, 1),
    );
  }
}

List<String> _stringList(Object? raw) {
  return (raw as List?)?.map((entry) => _sanitizeText(entry.toString())).toList(
            growable: false,
          ) ??
      const <String>[];
}

String _sanitizeText(String value) {
  return value.replaceAll(RegExp(r'\s+'), ' ').replaceAll('\n', ' ').trim();
}
