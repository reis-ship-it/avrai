import 'package:avrai_core/models/governance/governed_run_models.dart';
import 'package:avrai_core/models/security/security_countermeasure_bundle.dart';
import 'package:avrai_core/models/truth/truth_scope_descriptor.dart';

enum SecurityInterventionDisposition {
  observe,
  boundedDegrade,
  hardStop,
}

enum SecurityCampaignCadence {
  onDemand,
  hourly,
  daily,
  weekly,
  releaseBlocking,
}

enum SecurityCampaignTrigger {
  manual,
  schedule,
  codeChange,
  modelPromotion,
  policyPromotion,
  replayedIncident,
}

enum SecurityCampaignStatus {
  draft,
  queued,
  running,
  review,
  completed,
  failed,
  blocked,
}

enum SecurityFindingSeverity {
  info,
  warning,
  high,
  critical,
}

enum SecurityProofKind {
  transportConformance,
  governanceBoundary,
  announceTrust,
  learningPath,
  exportPrivacy,
  rolloutLifecycle,
  adminAbuse,
  ambientPromotion,
}

enum CountermeasureBundleCandidateStatus {
  candidate,
  shadowValidated,
  approved,
  stagedRollout,
  active,
  rolledBack,
  retired,
}

enum SecurityLearningMomentKind {
  finding,
  containment,
  falsePositive,
  rollback,
  recurrence,
  propagation,
}

class SecurityCampaignDefinition {
  const SecurityCampaignDefinition({
    required this.id,
    required this.laneId,
    required this.name,
    required this.description,
    required this.truthScope,
    required this.cadence,
    required this.triggers,
    required this.environment,
    required this.releaseBlocking,
    required this.ownerAlias,
    required this.ownershipArea,
    this.pathPrefixes = const <String>[],
    this.promotionSelectors = const <String>[],
    this.incidentTags = const <String>[],
    this.mappedScenarioIds = const <String>[],
    this.requiredProofKinds = const <SecurityProofKind>[],
    this.metadata = const <String, dynamic>{},
  });

  final String id;
  final String laneId;
  final String name;
  final String description;
  final TruthScopeDescriptor truthScope;
  final SecurityCampaignCadence cadence;
  final List<SecurityCampaignTrigger> triggers;
  final GovernedRunEnvironment environment;
  final bool releaseBlocking;
  final String ownerAlias;
  final String ownershipArea;
  final List<String> pathPrefixes;
  final List<String> promotionSelectors;
  final List<String> incidentTags;
  final List<String> mappedScenarioIds;
  final List<SecurityProofKind> requiredProofKinds;
  final Map<String, dynamic> metadata;

  String? get mappedScenarioId =>
      mappedScenarioIds.isEmpty ? null : mappedScenarioIds.first;
}

class SecurityReplayPackSummary {
  const SecurityReplayPackSummary({
    required this.executedScenarioIds,
    required this.passedScenarioIds,
    required this.failedScenarioIds,
    required this.missingScenarioIds,
    required this.requiredProofKinds,
    required this.coveredProofKinds,
    required this.proofRefs,
    required this.coverageScore,
  });

  final List<String> executedScenarioIds;
  final List<String> passedScenarioIds;
  final List<String> failedScenarioIds;
  final List<String> missingScenarioIds;
  final List<SecurityProofKind> requiredProofKinds;
  final List<SecurityProofKind> coveredProofKinds;
  final List<String> proofRefs;
  final double coverageScore;

  bool get hasMissingCoverage =>
      missingScenarioIds.isNotEmpty ||
      coveredProofKinds.length < requiredProofKinds.length;

  List<SecurityProofKind> get missingProofKinds {
    return requiredProofKinds
        .where((entry) => !coveredProofKinds.contains(entry))
        .toList(growable: false);
  }

  bool get autoClearEligible =>
      missingScenarioIds.isEmpty && missingProofKinds.isEmpty;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'executedScenarioIds': executedScenarioIds,
        'passedScenarioIds': passedScenarioIds,
        'failedScenarioIds': failedScenarioIds,
        'missingScenarioIds': missingScenarioIds,
        'requiredProofKinds':
            requiredProofKinds.map((entry) => entry.name).toList(),
        'coveredProofKinds':
            coveredProofKinds.map((entry) => entry.name).toList(),
        'proofRefs': proofRefs,
        'coverageScore': coverageScore,
      };

  factory SecurityReplayPackSummary.fromJson(Map<String, dynamic> json) {
    return SecurityReplayPackSummary(
      executedScenarioIds: _stringList(json['executedScenarioIds']),
      passedScenarioIds: _stringList(json['passedScenarioIds']),
      failedScenarioIds: _stringList(json['failedScenarioIds']),
      missingScenarioIds: _stringList(json['missingScenarioIds']),
      requiredProofKinds: _proofKinds(json['requiredProofKinds']),
      coveredProofKinds: _proofKinds(json['coveredProofKinds']),
      proofRefs: _stringList(json['proofRefs']),
      coverageScore: (json['coverageScore'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class SecurityCampaignRun {
  const SecurityCampaignRun({
    required this.runId,
    required this.definitionId,
    required this.governedRunId,
    required this.truthScope,
    required this.status,
    required this.trigger,
    required this.disposition,
    required this.startedAt,
    required this.findingCount,
    required this.highestSeverity,
    required this.proofCoverageScore,
    required this.autoClearEligible,
    this.completedAt,
    this.proofBundle,
    this.missingScenarioIds = const <String>[],
    this.missingProofKinds = const <SecurityProofKind>[],
    this.metadata = const <String, dynamic>{},
  });

  final String runId;
  final String definitionId;
  final String governedRunId;
  final TruthScopeDescriptor truthScope;
  final SecurityCampaignStatus status;
  final SecurityCampaignTrigger trigger;
  final SecurityInterventionDisposition disposition;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int findingCount;
  final SecurityFindingSeverity highestSeverity;
  final double proofCoverageScore;
  final bool autoClearEligible;
  final String? proofBundle;
  final List<String> missingScenarioIds;
  final List<SecurityProofKind> missingProofKinds;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'runId': runId,
        'definitionId': definitionId,
        'governedRunId': governedRunId,
        'truthScope': truthScope.toJson(),
        'status': status.name,
        'trigger': trigger.name,
        'disposition': disposition.name,
        'startedAt': startedAt.toUtc().toIso8601String(),
        'completedAt': completedAt?.toUtc().toIso8601String(),
        'findingCount': findingCount,
        'highestSeverity': highestSeverity.name,
        'proofCoverageScore': proofCoverageScore,
        'autoClearEligible': autoClearEligible,
        'proofBundle': proofBundle,
        'missingScenarioIds': missingScenarioIds,
        'missingProofKinds':
            missingProofKinds.map((entry) => entry.name).toList(),
        'metadata': metadata,
      };

  factory SecurityCampaignRun.fromJson(Map<String, dynamic> json) {
    return SecurityCampaignRun(
      runId: json['runId']?.toString() ?? '',
      definitionId: json['definitionId']?.toString() ?? '',
      governedRunId: json['governedRunId']?.toString() ?? '',
      truthScope: TruthScopeDescriptor.fromJson(
        Map<String, dynamic>.from(
          json['truthScope'] as Map? ?? const <String, dynamic>{},
        ),
      ),
      status: SecurityCampaignStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => SecurityCampaignStatus.draft,
      ),
      trigger: SecurityCampaignTrigger.values.firstWhere(
        (value) => value.name == json['trigger'],
        orElse: () => SecurityCampaignTrigger.manual,
      ),
      disposition: SecurityInterventionDisposition.values.firstWhere(
        (value) => value.name == json['disposition'],
        orElse: () => SecurityInterventionDisposition.observe,
      ),
      startedAt: _parseDateTime(json['startedAt']),
      completedAt: _parseNullableDateTime(json['completedAt']),
      findingCount: (json['findingCount'] as num?)?.toInt() ?? 0,
      highestSeverity: SecurityFindingSeverity.values.firstWhere(
        (value) => value.name == json['highestSeverity'],
        orElse: () => SecurityFindingSeverity.info,
      ),
      proofCoverageScore:
          (json['proofCoverageScore'] as num?)?.toDouble() ?? 0.0,
      autoClearEligible: json['autoClearEligible'] as bool? ?? false,
      proofBundle: json['proofBundle']?.toString(),
      missingScenarioIds: _stringList(json['missingScenarioIds']),
      missingProofKinds: _proofKinds(json['missingProofKinds']),
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}

class SecurityFinding {
  const SecurityFinding({
    required this.id,
    required this.campaignRunId,
    required this.truthScope,
    required this.severity,
    required this.title,
    required this.summary,
    required this.disposition,
    required this.confidence,
    required this.createdAt,
    required this.recurrenceCount,
    required this.invariantBreach,
    required this.evidenceTraceIds,
    required this.blockedControls,
    this.metadata = const <String, dynamic>{},
  });

  final String id;
  final String campaignRunId;
  final TruthScopeDescriptor truthScope;
  final SecurityFindingSeverity severity;
  final String title;
  final String summary;
  final SecurityInterventionDisposition disposition;
  final double confidence;
  final DateTime createdAt;
  final int recurrenceCount;
  final bool invariantBreach;
  final List<String> evidenceTraceIds;
  final List<String> blockedControls;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'campaignRunId': campaignRunId,
        'truthScope': truthScope.toJson(),
        'severity': severity.name,
        'title': title,
        'summary': summary,
        'disposition': disposition.name,
        'confidence': confidence,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'recurrenceCount': recurrenceCount,
        'invariantBreach': invariantBreach,
        'evidenceTraceIds': evidenceTraceIds,
        'blockedControls': blockedControls,
        'metadata': metadata,
      };

  factory SecurityFinding.fromJson(Map<String, dynamic> json) {
    return SecurityFinding(
      id: json['id']?.toString() ?? '',
      campaignRunId: json['campaignRunId']?.toString() ?? '',
      truthScope: TruthScopeDescriptor.fromJson(
        Map<String, dynamic>.from(
          json['truthScope'] as Map? ?? const <String, dynamic>{},
        ),
      ),
      severity: SecurityFindingSeverity.values.firstWhere(
        (value) => value.name == json['severity'],
        orElse: () => SecurityFindingSeverity.info,
      ),
      title: json['title']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      disposition: SecurityInterventionDisposition.values.firstWhere(
        (value) => value.name == json['disposition'],
        orElse: () => SecurityInterventionDisposition.observe,
      ),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      createdAt: _parseDateTime(json['createdAt']),
      recurrenceCount: (json['recurrenceCount'] as num?)?.toInt() ?? 0,
      invariantBreach: json['invariantBreach'] as bool? ?? false,
      evidenceTraceIds: _stringList(json['evidenceTraceIds']),
      blockedControls: _stringList(json['blockedControls']),
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}

class ImmuneMemoryRecord {
  const ImmuneMemoryRecord({
    required this.id,
    required this.truthScope,
    required this.createdAt,
    required this.signature,
    required this.preconditions,
    required this.affectedSurfaces,
    required this.containmentActions,
    required this.falsePositive,
    required this.recurrenceRiskTag,
    required this.evidenceTraceIds,
    this.metadata = const <String, dynamic>{},
  });

  final String id;
  final TruthScopeDescriptor truthScope;
  final DateTime createdAt;
  final String signature;
  final List<String> preconditions;
  final List<String> affectedSurfaces;
  final List<String> containmentActions;
  final bool falsePositive;
  final String recurrenceRiskTag;
  final List<String> evidenceTraceIds;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'truthScope': truthScope.toJson(),
        'createdAt': createdAt.toUtc().toIso8601String(),
        'signature': signature,
        'preconditions': preconditions,
        'affectedSurfaces': affectedSurfaces,
        'containmentActions': containmentActions,
        'falsePositive': falsePositive,
        'recurrenceRiskTag': recurrenceRiskTag,
        'evidenceTraceIds': evidenceTraceIds,
        'metadata': metadata,
      };

  factory ImmuneMemoryRecord.fromJson(Map<String, dynamic> json) {
    return ImmuneMemoryRecord(
      id: json['id']?.toString() ?? '',
      truthScope: TruthScopeDescriptor.fromJson(
        Map<String, dynamic>.from(
          json['truthScope'] as Map? ?? const <String, dynamic>{},
        ),
      ),
      createdAt: _parseDateTime(json['createdAt']),
      signature: json['signature']?.toString() ?? '',
      preconditions: _stringList(json['preconditions']),
      affectedSurfaces: _stringList(json['affectedSurfaces']),
      containmentActions: _stringList(json['containmentActions']),
      falsePositive: json['falsePositive'] as bool? ?? false,
      recurrenceRiskTag: json['recurrenceRiskTag']?.toString() ?? '',
      evidenceTraceIds: _stringList(json['evidenceTraceIds']),
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}

class CountermeasureBundleCandidate {
  const CountermeasureBundleCandidate({
    required this.candidateId,
    required this.status,
    required this.bundle,
    required this.createdAt,
    required this.updatedAt,
    required this.sourceFindingIds,
    required this.shadowValidationEvidenceTraceIds,
    required this.approvalActors,
    this.metadata = const <String, dynamic>{},
  });

  final String candidateId;
  final CountermeasureBundleCandidateStatus status;
  final SecurityCountermeasureBundle bundle;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> sourceFindingIds;
  final List<String> shadowValidationEvidenceTraceIds;
  final List<String> approvalActors;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'candidateId': candidateId,
        'status': status.name,
        'bundle': bundle.toJson(),
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
        'sourceFindingIds': sourceFindingIds,
        'shadowValidationEvidenceTraceIds': shadowValidationEvidenceTraceIds,
        'approvalActors': approvalActors,
        'metadata': metadata,
      };

  factory CountermeasureBundleCandidate.fromJson(Map<String, dynamic> json) {
    return CountermeasureBundleCandidate(
      candidateId: json['candidateId']?.toString() ?? '',
      status: CountermeasureBundleCandidateStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => CountermeasureBundleCandidateStatus.candidate,
      ),
      bundle: SecurityCountermeasureBundle.fromJson(
        Map<String, dynamic>.from(
          json['bundle'] as Map? ?? const <String, dynamic>{},
        ),
      ),
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
      sourceFindingIds: _stringList(json['sourceFindingIds']),
      shadowValidationEvidenceTraceIds: _stringList(
        json['shadowValidationEvidenceTraceIds'],
      ),
      approvalActors: _stringList(json['approvalActors']),
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}

class CountermeasurePropagationReceipt {
  const CountermeasurePropagationReceipt({
    required this.receiptId,
    required this.bundleId,
    required this.targetScope,
    required this.sourceStratum,
    required this.targetStratum,
    required this.activationStage,
    required this.requiredAcknowledgements,
    required this.acknowledgedCount,
    required this.acknowledgedAt,
    required this.driftDetected,
    required this.staleNode,
    required this.rolledBack,
    this.approvalGranted = false,
    this.activationDeadlineAt,
    this.activatedAt,
    this.rolledBackAt,
    this.rollbackReason,
    this.metadata = const <String, dynamic>{},
  });

  final String receiptId;
  final String bundleId;
  final TruthScopeDescriptor targetScope;
  final GovernanceStratum sourceStratum;
  final GovernanceStratum targetStratum;
  final String activationStage;
  final int requiredAcknowledgements;
  final int acknowledgedCount;
  final DateTime acknowledgedAt;
  final bool driftDetected;
  final bool staleNode;
  final bool rolledBack;
  final bool approvalGranted;
  final DateTime? activationDeadlineAt;
  final DateTime? activatedAt;
  final DateTime? rolledBackAt;
  final String? rollbackReason;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'receiptId': receiptId,
        'bundleId': bundleId,
        'targetScope': targetScope.toJson(),
        'sourceStratum': sourceStratum.name,
        'targetStratum': targetStratum.name,
        'activationStage': activationStage,
        'requiredAcknowledgements': requiredAcknowledgements,
        'acknowledgedCount': acknowledgedCount,
        'acknowledgedAt': acknowledgedAt.toUtc().toIso8601String(),
        'driftDetected': driftDetected,
        'staleNode': staleNode,
        'rolledBack': rolledBack,
        'approvalGranted': approvalGranted,
        'activationDeadlineAt': activationDeadlineAt?.toUtc().toIso8601String(),
        'activatedAt': activatedAt?.toUtc().toIso8601String(),
        'rolledBackAt': rolledBackAt?.toUtc().toIso8601String(),
        'rollbackReason': rollbackReason,
        'metadata': metadata,
      };

  factory CountermeasurePropagationReceipt.fromJson(
    Map<String, dynamic> json,
  ) {
    return CountermeasurePropagationReceipt(
      receiptId: json['receiptId']?.toString() ?? '',
      bundleId: json['bundleId']?.toString() ?? '',
      targetScope: TruthScopeDescriptor.fromJson(
        Map<String, dynamic>.from(
          json['targetScope'] as Map? ?? const <String, dynamic>{},
        ),
      ),
      sourceStratum: GovernanceStratum.values.firstWhere(
        (value) => value.name == json['sourceStratum'],
        orElse: () => GovernanceStratum.personal,
      ),
      targetStratum: GovernanceStratum.values.firstWhere(
        (value) => value.name == json['targetStratum'],
        orElse: () => GovernanceStratum.personal,
      ),
      activationStage: json['activationStage']?.toString() ?? 'unknown',
      requiredAcknowledgements:
          (json['requiredAcknowledgements'] as num?)?.toInt() ?? 1,
      acknowledgedCount: (json['acknowledgedCount'] as num?)?.toInt() ?? 0,
      acknowledgedAt: _parseDateTime(json['acknowledgedAt']),
      driftDetected: json['driftDetected'] as bool? ?? false,
      staleNode: json['staleNode'] as bool? ?? false,
      rolledBack: json['rolledBack'] as bool? ?? false,
      approvalGranted: json['approvalGranted'] as bool? ?? false,
      activationDeadlineAt:
          _parseNullableDateTime(json['activationDeadlineAt']),
      activatedAt: _parseNullableDateTime(json['activatedAt']),
      rolledBackAt: _parseNullableDateTime(json['rolledBackAt']),
      rollbackReason: json['rollbackReason']?.toString(),
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}

class SecurityLearningMoment {
  const SecurityLearningMoment({
    required this.id,
    required this.truthScope,
    required this.runId,
    required this.kind,
    required this.disposition,
    required this.summary,
    required this.createdAt,
    required this.evidenceTraceIds,
    required this.recurrenceCount,
    required this.falsePositive,
    this.metadata = const <String, dynamic>{},
  });

  final String id;
  final TruthScopeDescriptor truthScope;
  final String runId;
  final SecurityLearningMomentKind kind;
  final SecurityInterventionDisposition disposition;
  final String summary;
  final DateTime createdAt;
  final List<String> evidenceTraceIds;
  final int recurrenceCount;
  final bool falsePositive;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'truthScope': truthScope.toJson(),
        'runId': runId,
        'kind': kind.name,
        'disposition': disposition.name,
        'summary': summary,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'evidenceTraceIds': evidenceTraceIds,
        'recurrenceCount': recurrenceCount,
        'falsePositive': falsePositive,
        'metadata': metadata,
      };

  factory SecurityLearningMoment.fromJson(Map<String, dynamic> json) {
    return SecurityLearningMoment(
      id: json['id']?.toString() ?? '',
      truthScope: TruthScopeDescriptor.fromJson(
        Map<String, dynamic>.from(
          json['truthScope'] as Map? ?? const <String, dynamic>{},
        ),
      ),
      runId: json['runId']?.toString() ?? '',
      kind: SecurityLearningMomentKind.values.firstWhere(
        (value) => value.name == json['kind'],
        orElse: () => SecurityLearningMomentKind.finding,
      ),
      disposition: SecurityInterventionDisposition.values.firstWhere(
        (value) => value.name == json['disposition'],
        orElse: () => SecurityInterventionDisposition.observe,
      ),
      summary: json['summary']?.toString() ?? '',
      createdAt: _parseDateTime(json['createdAt']),
      evidenceTraceIds: _stringList(json['evidenceTraceIds']),
      recurrenceCount: (json['recurrenceCount'] as num?)?.toInt() ?? 0,
      falsePositive: json['falsePositive'] as bool? ?? false,
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}

class SecurityScoutStatus {
  const SecurityScoutStatus({
    required this.scoutId,
    required this.alias,
    required this.truthScope,
    required this.lastSeenAt,
    required this.activeCampaignCount,
    required this.probeOnly,
    this.metadata = const <String, dynamic>{},
  });

  final String scoutId;
  final String alias;
  final TruthScopeDescriptor truthScope;
  final DateTime lastSeenAt;
  final int activeCampaignCount;
  final bool probeOnly;
  final Map<String, dynamic> metadata;
}

List<String> _stringList(dynamic value) {
  if (value is List<dynamic>) {
    return value.map((entry) => entry.toString()).toList(growable: false);
  }
  return const <String>[];
}

DateTime _parseDateTime(dynamic value) {
  return _parseNullableDateTime(value) ?? DateTime.now().toUtc();
}

DateTime? _parseNullableDateTime(dynamic value) {
  final raw = value?.toString();
  if (raw == null || raw.isEmpty) {
    return null;
  }
  return DateTime.tryParse(raw)?.toUtc();
}

List<SecurityProofKind> _proofKinds(dynamic value) {
  if (value is! List<dynamic>) {
    return const <SecurityProofKind>[];
  }
  return value
      .map(
        (entry) => SecurityProofKind.values.firstWhere(
          (kind) => kind.name == entry?.toString(),
          orElse: () => SecurityProofKind.governanceBoundary,
        ),
      )
      .toList(growable: false);
}
