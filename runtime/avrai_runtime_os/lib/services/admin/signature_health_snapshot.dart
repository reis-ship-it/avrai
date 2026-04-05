import 'package:avrai_core/models/kernel_graph/kernel_graph_models.dart';
import 'package:avrai_core/models/reality/governed_learning_chat_observation_receipt.dart';
import 'package:avrai_runtime_os/services/admin/signature_health_category.dart';

class SignatureHealthRecord {
  final String sourceId;
  final String provider;
  final String entityType;
  final String categoryLabel;
  final String? sourceLabel;
  final String? cityCode;
  final String? localityCode;
  final double confidence;
  final double freshness;
  final double fallbackRate;
  final bool reviewNeeded;
  final DateTime? lastSyncAt;
  final DateTime? lastSignatureRebuildAt;
  final DateTime? updatedAt;
  final String syncState;
  final SignatureHealthCategory healthCategory;
  final String summary;

  const SignatureHealthRecord({
    required this.sourceId,
    required this.provider,
    required this.entityType,
    required this.categoryLabel,
    this.sourceLabel,
    this.cityCode,
    this.localityCode,
    required this.confidence,
    required this.freshness,
    required this.fallbackRate,
    required this.reviewNeeded,
    this.lastSyncAt,
    this.lastSignatureRebuildAt,
    this.updatedAt,
    required this.syncState,
    required this.healthCategory,
    required this.summary,
  });

  bool get isFeedbackTelemetry => provider == 'user_feedback';

  String get metroLabel {
    if (localityCode != null && localityCode!.isNotEmpty) {
      return localityCode!;
    }
    if (cityCode != null && cityCode!.isNotEmpty) {
      return cityCode!;
    }
    return 'unknown';
  }
}

class SignatureHealthReviewQueueItem {
  final String id;
  final String sourceId;
  final String ownerUserId;
  final String targetType;
  final String title;
  final String summary;
  final List<String> missingFields;
  final DateTime createdAt;
  final Map<String, dynamic> payload;

  const SignatureHealthReviewQueueItem({
    required this.id,
    required this.sourceId,
    required this.ownerUserId,
    required this.targetType,
    required this.title,
    required this.summary,
    required this.missingFields,
    required this.createdAt,
    this.payload = const <String, dynamic>{},
  });

  String get environmentId =>
      payload['environmentId']?.toString() ?? 'unknown_environment';

  String get queueKind =>
      payload['status']?.toString() ?? payload['queueKind']?.toString() ?? '';

  String? get sourceKind => payload['sourceKind']?.toString();

  String? get learningDirection => payload['learningDirection']?.toString();

  String? get learningPathway => payload['learningPathway']?.toString();

  String? get convictionTier => payload['convictionTier']?.toString();

  List<String> get hierarchyPath =>
      List<String>.from(payload['hierarchyPath'] ?? const <String>[]);

  List<String> get upwardDomainHints =>
      List<String>.from(payload['upwardDomainHints'] ?? const <String>[]);

  List<String> get upwardReferencedEntities => List<String>.from(
        payload['upwardReferencedEntities'] ?? const <String>[],
      );

  List<String> get upwardQuestions =>
      List<String>.from(payload['upwardQuestions'] ?? const <String>[]);

  List<String> get upwardSignalTags =>
      List<String>.from(payload['upwardSignalTags'] ?? const <String>[]);

  List<Map<String, dynamic>> get upwardPreferenceSignals =>
      (payload['upwardPreferenceSignals'] as List? ?? const <dynamic>[])
          .whereType<Map>()
          .map((value) => Map<String, dynamic>.from(value))
          .toList(growable: false);

  String? get followUpPromptQuestion => payload['promptQuestion']?.toString();

  String? get followUpResponseText => payload['responseText']?.toString();

  String? get followUpCompletionMode => payload['completionMode']?.toString();

  SignatureHealthTemporalLineage? get temporalLineage =>
      payload['temporalLineage'] is Map<String, dynamic>
          ? SignatureHealthTemporalLineage.fromJson(
              Map<String, dynamic>.from(
                payload['temporalLineage'] as Map<String, dynamic>,
              ),
            )
          : payload['temporalLineage'] is Map
              ? SignatureHealthTemporalLineage.fromJson(
                  Map<String, dynamic>.from(payload['temporalLineage'] as Map),
                )
              : null;

  String? get trainingManifestJsonPath =>
      payload['trainingManifestJsonPath']?.toString();

  String? get shareReviewJsonPath => payload['shareReviewJsonPath']?.toString();

  String? get suggestedTrainingUse =>
      payload['suggestedTrainingUse']?.toString();

  List<String> get intakeFlowRefs =>
      List<String>.from(payload['intakeFlowRefs'] ?? const <String>[]);

  List<String> get sidecarRefs =>
      List<String>.from(payload['sidecarRefs'] ?? const <String>[]);

  String? get cityPackStructuralRef =>
      payload['cityPackStructuralRef']?.toString();

  bool get isSimulationTrainingIntake =>
      queueKind == 'queued_for_deeper_training_intake_review' ||
      title.toLowerCase().contains('deeper training intake');

  bool get isUpwardLearningReview =>
      queueKind == 'queued_for_upward_learning_review' ||
      learningDirection == 'upward_personal_agent_to_reality_model';
}

class SignatureHealthTemporalLineage {
  final DateTime? sourceCreatedAt;
  final DateTime? sourceUpdatedAt;
  final DateTime? sourceLastSyncedAt;
  final DateTime? originOccurredAt;
  final DateTime? localStateCapturedAt;
  final DateTime? reviewQueuedAt;
  final DateTime? reviewResolvedAt;
  final DateTime? learningQueuedAt;
  final DateTime? learningIntegratedAt;
  final DateTime? propagationPreparedAt;
  final DateTime? propagationResolvedAt;
  final DateTime? artifactGeneratedAt;
  final String? kernelExchangePhase;

  const SignatureHealthTemporalLineage({
    this.sourceCreatedAt,
    this.sourceUpdatedAt,
    this.sourceLastSyncedAt,
    this.originOccurredAt,
    this.localStateCapturedAt,
    this.reviewQueuedAt,
    this.reviewResolvedAt,
    this.learningQueuedAt,
    this.learningIntegratedAt,
    this.propagationPreparedAt,
    this.propagationResolvedAt,
    this.artifactGeneratedAt,
    this.kernelExchangePhase,
  });

  factory SignatureHealthTemporalLineage.fromJson(Map<String, dynamic> json) {
    DateTime? parse(String key) {
      final raw = json[key];
      if (raw == null) {
        return null;
      }
      return DateTime.tryParse(raw.toString())?.toUtc();
    }

    return SignatureHealthTemporalLineage(
      sourceCreatedAt: parse('sourceCreatedAt'),
      sourceUpdatedAt: parse('sourceUpdatedAt'),
      sourceLastSyncedAt: parse('sourceLastSyncedAt'),
      originOccurredAt: parse('originOccurredAt'),
      localStateCapturedAt: parse('localStateCapturedAt'),
      reviewQueuedAt: parse('reviewQueuedAt'),
      reviewResolvedAt: parse('reviewResolvedAt'),
      learningQueuedAt: parse('learningQueuedAt'),
      learningIntegratedAt: parse('learningIntegratedAt'),
      propagationPreparedAt: parse('propagationPreparedAt'),
      propagationResolvedAt: parse('propagationResolvedAt'),
      artifactGeneratedAt: parse('artifactGeneratedAt'),
      kernelExchangePhase: json['kernelExchangePhase']?.toString(),
    );
  }

  bool get hasAnyValue =>
      sourceCreatedAt != null ||
      sourceUpdatedAt != null ||
      sourceLastSyncedAt != null ||
      originOccurredAt != null ||
      localStateCapturedAt != null ||
      reviewQueuedAt != null ||
      reviewResolvedAt != null ||
      learningQueuedAt != null ||
      learningIntegratedAt != null ||
      propagationPreparedAt != null ||
      propagationResolvedAt != null ||
      artifactGeneratedAt != null ||
      kernelExchangePhase != null;
}

class SignatureHealthPropagationTarget {
  final String targetId;
  final String propagationKind;
  final String reason;
  final String status;
  final String? receiptJsonPath;
  final String? receiptReadmePath;
  final String? laneArtifactJsonPath;
  final String? laneArtifactReadmePath;
  final SignatureHealthHierarchyDomainDeltaSummary? hierarchyDomainDeltaSummary;
  final SignatureHealthPersonalAgentPersonalizationSummary?
      personalAgentPersonalizationSummary;
  final SignatureHealthTemporalLineage? temporalLineage;

  const SignatureHealthPropagationTarget({
    required this.targetId,
    required this.propagationKind,
    required this.reason,
    required this.status,
    this.receiptJsonPath,
    this.receiptReadmePath,
    this.laneArtifactJsonPath,
    this.laneArtifactReadmePath,
    this.hierarchyDomainDeltaSummary,
    this.personalAgentPersonalizationSummary,
    this.temporalLineage,
  });

  bool get isReadyForReview =>
      status == 'ready_for_governed_downstream_propagation_review';
}

class SignatureHealthHierarchyDomainDeltaSummary {
  final String status;
  final String environmentId;
  final String domainId;
  final String summary;
  final String boundedUse;
  final int requestCount;
  final int recommendationCount;
  final double? averageConfidence;
  final List<String> learningDeltas;
  final SignatureHealthDomainConsumerSummary? downstreamConsumerSummary;
  final String? jsonPath;
  final SignatureHealthTemporalLineage? temporalLineage;

  const SignatureHealthHierarchyDomainDeltaSummary({
    required this.status,
    required this.environmentId,
    required this.domainId,
    required this.summary,
    required this.boundedUse,
    required this.requestCount,
    required this.recommendationCount,
    this.averageConfidence,
    this.learningDeltas = const <String>[],
    this.downstreamConsumerSummary,
    this.jsonPath,
    this.temporalLineage,
  });
}

class SignatureHealthDomainConsumerSummary {
  final String status;
  final String consumerId;
  final String domainId;
  final String summary;
  final String boundedUse;
  final List<String> targetedSystems;
  final String? jsonPath;
  final SignatureHealthTemporalLineage? temporalLineage;

  const SignatureHealthDomainConsumerSummary({
    required this.status,
    required this.consumerId,
    required this.domainId,
    required this.summary,
    required this.boundedUse,
    this.targetedSystems = const <String>[],
    this.jsonPath,
    this.temporalLineage,
  });
}

class SignatureHealthPersonalAgentPersonalizationSummary {
  final String status;
  final String environmentId;
  final String domainId;
  final String summary;
  final String personalizationMode;
  final String boundedUse;
  final int requestCount;
  final int recommendationCount;
  final double? averageConfidence;
  final String? jsonPath;
  final SignatureHealthTemporalLineage? temporalLineage;

  const SignatureHealthPersonalAgentPersonalizationSummary({
    required this.status,
    required this.environmentId,
    required this.domainId,
    required this.summary,
    required this.personalizationMode,
    required this.boundedUse,
    required this.requestCount,
    required this.recommendationCount,
    this.averageConfidence,
    this.jsonPath,
    this.temporalLineage,
  });
}

class SignatureHealthAdminEvidenceRefreshSummary {
  final String status;
  final String environmentId;
  final String? cityCode;
  final String summary;
  final int requestCount;
  final int recommendationCount;
  final double? averageConfidence;
  final Map<String, dynamic> domainCoverage;
  final List<String> learningDeltas;
  final String? jsonPath;
  final SignatureHealthTemporalLineage? temporalLineage;

  const SignatureHealthAdminEvidenceRefreshSummary({
    required this.status,
    required this.environmentId,
    this.cityCode,
    required this.summary,
    required this.requestCount,
    required this.recommendationCount,
    this.averageConfidence,
    this.domainCoverage = const <String, dynamic>{},
    this.learningDeltas = const <String>[],
    this.jsonPath,
    this.temporalLineage,
  });
}

class SignatureHealthSupervisorFeedbackSummary {
  final String status;
  final String environmentId;
  final String feedbackSummary;
  final String boundedRecommendation;
  final int requestCount;
  final int recommendationCount;
  final double? averageConfidence;
  final String? jsonPath;
  final SignatureHealthTemporalLineage? temporalLineage;

  const SignatureHealthSupervisorFeedbackSummary({
    required this.status,
    required this.environmentId,
    required this.feedbackSummary,
    required this.boundedRecommendation,
    required this.requestCount,
    required this.recommendationCount,
    this.averageConfidence,
    this.jsonPath,
    this.temporalLineage,
  });
}

class SignatureHealthLabTargetTrendSummary {
  final int completedRerunCount;
  final String runtimeTrendSeverityCode;
  final String runtimeTrendSummary;
  final String runtimeDeltaSummary;
  final String outcomeTrendSummary;

  const SignatureHealthLabTargetTrendSummary({
    required this.completedRerunCount,
    required this.runtimeTrendSeverityCode,
    required this.runtimeTrendSummary,
    required this.runtimeDeltaSummary,
    required this.outcomeTrendSummary,
  });
}

class SignatureHealthLabTargetProvenanceDeltaSummary {
  final String summary;
  final List<String> details;

  const SignatureHealthLabTargetProvenanceDeltaSummary({
    required this.summary,
    this.details = const <String>[],
  });
}

class SignatureHealthLabTargetProvenanceHistoryEntry {
  final String label;
  final List<String> details;

  const SignatureHealthLabTargetProvenanceHistoryEntry({
    required this.label,
    this.details = const <String>[],
  });
}

class SignatureHealthLabTargetProvenanceHistorySummary {
  final int sampleCount;
  final List<SignatureHealthLabTargetProvenanceHistoryEntry> entries;

  const SignatureHealthLabTargetProvenanceHistorySummary({
    required this.sampleCount,
    this.entries = const <SignatureHealthLabTargetProvenanceHistoryEntry>[],
  });
}

class SignatureHealthLabTargetProvenanceEmphasisSummary {
  final String severityCode;
  final String summary;

  const SignatureHealthLabTargetProvenanceEmphasisSummary({
    required this.severityCode,
    required this.summary,
  });
}

class SignatureHealthLabTargetBoundedAlertSummary {
  final String severityCode;
  final String summary;

  const SignatureHealthLabTargetBoundedAlertSummary({
    required this.severityCode,
    required this.summary,
  });
}

class SignatureHealthLabTargetActionItem {
  final String environmentId;
  final String displayName;
  final String cityCode;
  final int replayYear;
  final String suggestedAction;
  final String suggestedReason;
  final String selectedAction;
  final bool acceptedSuggestion;
  final DateTime updatedAt;
  final String? variantId;
  final String? variantLabel;
  final String? cityPackStructuralRef;
  final List<String> sidecarRefs;
  final String? latestOutcomeDisposition;
  final DateTime? latestOutcomeRecordedAt;
  final String? latestOutcomeRationale;
  final String? latestRerunRequestId;
  final String? latestRerunRequestStatus;
  final DateTime? latestRerunRequestedAt;
  final String? latestRerunJobId;
  final String? latestRerunJobStatus;
  final DateTime? latestRerunJobCompletedAt;
  final DateTime? alertAcknowledgedAt;
  final String? alertAcknowledgedSeverityCode;
  final DateTime? alertEscalatedAt;
  final String? alertEscalatedSeverityCode;
  final DateTime? alertSnoozedUntil;
  final String? alertSnoozedSeverityCode;
  final SignatureHealthLabTargetTrendSummary? trendSummary;
  final SignatureHealthLabTargetProvenanceDeltaSummary? provenanceDeltaSummary;
  final SignatureHealthLabTargetProvenanceHistorySummary?
      provenanceHistorySummary;
  final SignatureHealthLabTargetProvenanceEmphasisSummary?
      provenanceEmphasisSummary;
  final SignatureHealthLabTargetBoundedAlertSummary? boundedAlertSummary;

  const SignatureHealthLabTargetActionItem({
    required this.environmentId,
    required this.displayName,
    required this.cityCode,
    required this.replayYear,
    required this.suggestedAction,
    required this.suggestedReason,
    required this.selectedAction,
    required this.acceptedSuggestion,
    required this.updatedAt,
    this.variantId,
    this.variantLabel,
    this.cityPackStructuralRef,
    this.sidecarRefs = const <String>[],
    this.latestOutcomeDisposition,
    this.latestOutcomeRecordedAt,
    this.latestOutcomeRationale,
    this.latestRerunRequestId,
    this.latestRerunRequestStatus,
    this.latestRerunRequestedAt,
    this.latestRerunJobId,
    this.latestRerunJobStatus,
    this.latestRerunJobCompletedAt,
    this.alertAcknowledgedAt,
    this.alertAcknowledgedSeverityCode,
    this.alertEscalatedAt,
    this.alertEscalatedSeverityCode,
    this.alertSnoozedUntil,
    this.alertSnoozedSeverityCode,
    this.trendSummary,
    this.provenanceDeltaSummary,
    this.provenanceHistorySummary,
    this.provenanceEmphasisSummary,
    this.boundedAlertSummary,
  });

  bool get targetsBaseRun => variantId == null || variantId!.trim().isEmpty;

  bool get isBoundedReviewCandidate =>
      selectedAction == 'candidate_for_bounded_review';

  bool get hasActiveBoundedAlert => boundedAlertSummary != null;

  bool get isCurrentBoundedAlertAcknowledged =>
      boundedAlertSummary != null &&
      alertAcknowledgedAt != null &&
      alertAcknowledgedSeverityCode == boundedAlertSummary!.severityCode;

  bool get isCurrentBoundedAlertEscalated =>
      boundedAlertSummary != null &&
      alertEscalatedAt != null &&
      alertEscalatedSeverityCode == boundedAlertSummary!.severityCode;

  bool get isCurrentBoundedAlertSnoozed =>
      boundedAlertSummary != null &&
      alertSnoozedUntil != null &&
      alertSnoozedUntil!.isAfter(DateTime.now().toUtc()) &&
      alertSnoozedSeverityCode == boundedAlertSummary!.severityCode;

  String get targetLabel => targetsBaseRun
      ? 'Base run'
      : (variantLabel == null || variantLabel!.trim().isEmpty)
          ? variantId!
          : variantLabel!;
}

class SignatureHealthBoundedReviewCandidate {
  final String environmentId;
  final String displayName;
  final String cityCode;
  final int replayYear;
  final String suggestedAction;
  final String suggestedReason;
  final String selectedAction;
  final bool acceptedSuggestion;
  final DateTime updatedAt;
  final String? variantId;
  final String? variantLabel;
  final String? cityPackStructuralRef;
  final List<String> sidecarRefs;
  final String? latestOutcomeDisposition;
  final DateTime? latestOutcomeRecordedAt;
  final String? latestOutcomeRationale;
  final String? latestRerunRequestId;
  final String? latestRerunRequestStatus;
  final DateTime? latestRerunRequestedAt;
  final String? latestRerunJobId;
  final String? latestRerunJobStatus;
  final DateTime? latestRerunJobCompletedAt;
  final DateTime? alertAcknowledgedAt;
  final String? alertAcknowledgedSeverityCode;
  final DateTime? alertEscalatedAt;
  final String? alertEscalatedSeverityCode;
  final DateTime? alertSnoozedUntil;
  final String? alertSnoozedSeverityCode;
  final SignatureHealthLabTargetTrendSummary? trendSummary;
  final SignatureHealthLabTargetProvenanceDeltaSummary? provenanceDeltaSummary;
  final SignatureHealthLabTargetProvenanceHistorySummary?
      provenanceHistorySummary;
  final SignatureHealthLabTargetProvenanceEmphasisSummary?
      provenanceEmphasisSummary;
  final SignatureHealthLabTargetBoundedAlertSummary? boundedAlertSummary;

  const SignatureHealthBoundedReviewCandidate({
    required this.environmentId,
    required this.displayName,
    required this.cityCode,
    required this.replayYear,
    required this.suggestedAction,
    required this.suggestedReason,
    required this.selectedAction,
    required this.acceptedSuggestion,
    required this.updatedAt,
    this.variantId,
    this.variantLabel,
    this.cityPackStructuralRef,
    this.sidecarRefs = const <String>[],
    this.latestOutcomeDisposition,
    this.latestOutcomeRecordedAt,
    this.latestOutcomeRationale,
    this.latestRerunRequestId,
    this.latestRerunRequestStatus,
    this.latestRerunRequestedAt,
    this.latestRerunJobId,
    this.latestRerunJobStatus,
    this.latestRerunJobCompletedAt,
    this.alertAcknowledgedAt,
    this.alertAcknowledgedSeverityCode,
    this.alertEscalatedAt,
    this.alertEscalatedSeverityCode,
    this.alertSnoozedUntil,
    this.alertSnoozedSeverityCode,
    this.trendSummary,
    this.provenanceDeltaSummary,
    this.provenanceHistorySummary,
    this.provenanceEmphasisSummary,
    this.boundedAlertSummary,
  });

  bool get targetsBaseRun => variantId == null || variantId!.trim().isEmpty;

  bool get hasActiveBoundedAlert => boundedAlertSummary != null;

  bool get isCurrentBoundedAlertAcknowledged =>
      boundedAlertSummary != null &&
      alertAcknowledgedAt != null &&
      alertAcknowledgedSeverityCode == boundedAlertSummary!.severityCode;

  bool get isCurrentBoundedAlertEscalated =>
      boundedAlertSummary != null &&
      alertEscalatedAt != null &&
      alertEscalatedSeverityCode == boundedAlertSummary!.severityCode;

  bool get isCurrentBoundedAlertSnoozed =>
      boundedAlertSummary != null &&
      alertSnoozedUntil != null &&
      alertSnoozedUntil!.isAfter(DateTime.now().toUtc()) &&
      alertSnoozedSeverityCode == boundedAlertSummary!.severityCode;

  String get targetLabel => targetsBaseRun
      ? 'Base run'
      : (variantLabel == null || variantLabel!.trim().isEmpty)
          ? variantId!
          : variantLabel!;
}

class SignatureHealthServedBasisSummary {
  final String environmentId;
  final String displayName;
  final String cityCode;
  final int replayYear;
  final String supportedPlaceRef;
  final String? cityPackStructuralRef;
  final String currentBasisStatus;
  final String latestStateHydrationStatus;
  final String latestStatePromotionReadiness;
  final String latestStateDecisionStatus;
  final String latestStateRevalidationStatus;
  final String latestStateRecoveryDecisionStatus;
  final String hydrationFreshnessPosture;
  final String servedBasisRef;
  final String? priorServedBasisRef;
  final String? latestStateRefreshReceiptRef;
  final String? latestStateRevalidationReceiptRef;
  final String? latestStateRecoveryDecisionArtifactRef;
  final DateTime updatedAt;

  const SignatureHealthServedBasisSummary({
    required this.environmentId,
    required this.displayName,
    required this.cityCode,
    required this.replayYear,
    required this.supportedPlaceRef,
    this.cityPackStructuralRef,
    required this.currentBasisStatus,
    required this.latestStateHydrationStatus,
    required this.latestStatePromotionReadiness,
    required this.latestStateDecisionStatus,
    required this.latestStateRevalidationStatus,
    required this.latestStateRecoveryDecisionStatus,
    required this.hydrationFreshnessPosture,
    required this.servedBasisRef,
    this.priorServedBasisRef,
    this.latestStateRefreshReceiptRef,
    this.latestStateRevalidationReceiptRef,
    this.latestStateRecoveryDecisionArtifactRef,
    required this.updatedAt,
  });
}

class SignatureHealthFamilyRestageIntakeReviewSummary {
  final String environmentId;
  final String displayName;
  final String cityCode;
  final int replayYear;
  final String supportedPlaceRef;
  final String evidenceFamily;
  final String restageTarget;
  final String restageTargetSummary;
  final String policyAction;
  final String policyActionSummary;
  final String queueStatus;
  final String itemJsonPath;
  final String? queueDecisionArtifactRef;
  final String? queueDecisionRationale;
  final String? restageIntakeQueueJsonPath;
  final String? restageIntakeReadmePath;
  final String? restageIntakeSourceId;
  final String? restageIntakeJobId;
  final String? restageIntakeReviewItemId;
  final String? restageIntakeResolutionStatus;
  final String? restageIntakeResolutionArtifactRef;
  final String? restageIntakeResolutionRationale;
  final String? followUpQueueStatus;
  final String? followUpQueueJsonPath;
  final String? followUpReadmePath;
  final String? followUpSourceId;
  final String? followUpJobId;
  final String? followUpReviewItemId;
  final String? followUpResolutionStatus;
  final String? followUpResolutionArtifactRef;
  final String? followUpResolutionRationale;
  final String? restageResolutionQueueStatus;
  final String? restageResolutionQueueJsonPath;
  final String? restageResolutionReadmePath;
  final String? restageResolutionSourceId;
  final String? restageResolutionJobId;
  final String? restageResolutionReviewItemId;
  final String? restageResolutionResolutionStatus;
  final String? restageResolutionResolutionArtifactRef;
  final String? restageResolutionResolutionRationale;
  final String? restageExecutionQueueStatus;
  final String? restageExecutionQueueJsonPath;
  final String? restageExecutionReadmePath;
  final String? restageExecutionSourceId;
  final String? restageExecutionJobId;
  final String? restageExecutionReviewItemId;
  final String? restageExecutionResolutionStatus;
  final String? restageExecutionResolutionArtifactRef;
  final String? restageExecutionResolutionRationale;
  final String? restageApplicationQueueStatus;
  final String? restageApplicationQueueJsonPath;
  final String? restageApplicationReadmePath;
  final String? restageApplicationSourceId;
  final String? restageApplicationJobId;
  final String? restageApplicationReviewItemId;
  final String? restageApplicationResolutionStatus;
  final String? restageApplicationResolutionArtifactRef;
  final String? restageApplicationResolutionRationale;
  final String? restageApplyQueueStatus;
  final String? restageApplyQueueJsonPath;
  final String? restageApplyReadmePath;
  final String? restageApplySourceId;
  final String? restageApplyJobId;
  final String? restageApplyReviewItemId;
  final String? restageApplyResolutionStatus;
  final String? restageApplyResolutionArtifactRef;
  final String? restageApplyResolutionRationale;
  final String? restageServedBasisUpdateQueueStatus;
  final String? restageServedBasisUpdateQueueJsonPath;
  final String? restageServedBasisUpdateReadmePath;
  final String? restageServedBasisUpdateSourceId;
  final String? restageServedBasisUpdateJobId;
  final String? restageServedBasisUpdateReviewItemId;
  final String? restageServedBasisUpdateResolutionStatus;
  final String? restageServedBasisUpdateResolutionArtifactRef;
  final String? restageServedBasisUpdateResolutionRationale;
  final String? cityPackStructuralRef;
  final DateTime updatedAt;

  const SignatureHealthFamilyRestageIntakeReviewSummary({
    required this.environmentId,
    required this.displayName,
    required this.cityCode,
    required this.replayYear,
    required this.supportedPlaceRef,
    required this.evidenceFamily,
    required this.restageTarget,
    required this.restageTargetSummary,
    required this.policyAction,
    required this.policyActionSummary,
    required this.queueStatus,
    required this.itemJsonPath,
    this.queueDecisionArtifactRef,
    this.queueDecisionRationale,
    this.restageIntakeQueueJsonPath,
    this.restageIntakeReadmePath,
    this.restageIntakeSourceId,
    this.restageIntakeJobId,
    this.restageIntakeReviewItemId,
    this.restageIntakeResolutionStatus,
    this.restageIntakeResolutionArtifactRef,
    this.restageIntakeResolutionRationale,
    this.followUpQueueStatus,
    this.followUpQueueJsonPath,
    this.followUpReadmePath,
    this.followUpSourceId,
    this.followUpJobId,
    this.followUpReviewItemId,
    this.followUpResolutionStatus,
    this.followUpResolutionArtifactRef,
    this.followUpResolutionRationale,
    this.restageResolutionQueueStatus,
    this.restageResolutionQueueJsonPath,
    this.restageResolutionReadmePath,
    this.restageResolutionSourceId,
    this.restageResolutionJobId,
    this.restageResolutionReviewItemId,
    this.restageResolutionResolutionStatus,
    this.restageResolutionResolutionArtifactRef,
    this.restageResolutionResolutionRationale,
    this.restageExecutionQueueStatus,
    this.restageExecutionQueueJsonPath,
    this.restageExecutionReadmePath,
    this.restageExecutionSourceId,
    this.restageExecutionJobId,
    this.restageExecutionReviewItemId,
    this.restageExecutionResolutionStatus,
    this.restageExecutionResolutionArtifactRef,
    this.restageExecutionResolutionRationale,
    this.restageApplicationQueueStatus,
    this.restageApplicationQueueJsonPath,
    this.restageApplicationReadmePath,
    this.restageApplicationSourceId,
    this.restageApplicationJobId,
    this.restageApplicationReviewItemId,
    this.restageApplicationResolutionStatus,
    this.restageApplicationResolutionArtifactRef,
    this.restageApplicationResolutionRationale,
    this.restageApplyQueueStatus,
    this.restageApplyQueueJsonPath,
    this.restageApplyReadmePath,
    this.restageApplySourceId,
    this.restageApplyJobId,
    this.restageApplyReviewItemId,
    this.restageApplyResolutionStatus,
    this.restageApplyResolutionArtifactRef,
    this.restageApplyResolutionRationale,
    this.restageServedBasisUpdateQueueStatus,
    this.restageServedBasisUpdateQueueJsonPath,
    this.restageServedBasisUpdateReadmePath,
    this.restageServedBasisUpdateSourceId,
    this.restageServedBasisUpdateJobId,
    this.restageServedBasisUpdateReviewItemId,
    this.restageServedBasisUpdateResolutionStatus,
    this.restageServedBasisUpdateResolutionArtifactRef,
    this.restageServedBasisUpdateResolutionRationale,
    this.cityPackStructuralRef,
    required this.updatedAt,
  });
}

class SignatureHealthLearningOutcomeItem {
  final String sourceId;
  final String environmentId;
  final String cityCode;
  final String learningPathway;
  final String outcomeStatus;
  final String summary;
  final String? learningOutcomeJsonPath;
  final String? downstreamPropagationPlanJsonPath;
  final String? adminEvidenceRefreshSnapshotJsonPath;
  final String? supervisorLearningFeedbackStateJsonPath;
  final SignatureHealthAdminEvidenceRefreshSummary? adminEvidenceRefreshSummary;
  final SignatureHealthSupervisorFeedbackSummary? supervisorFeedbackSummary;
  final DateTime? updatedAt;
  final List<SignatureHealthPropagationTarget> propagationTargets;
  final SignatureHealthTemporalLineage? temporalLineage;

  const SignatureHealthLearningOutcomeItem({
    required this.sourceId,
    required this.environmentId,
    required this.cityCode,
    required this.learningPathway,
    required this.outcomeStatus,
    required this.summary,
    this.learningOutcomeJsonPath,
    this.downstreamPropagationPlanJsonPath,
    this.adminEvidenceRefreshSnapshotJsonPath,
    this.supervisorLearningFeedbackStateJsonPath,
    this.adminEvidenceRefreshSummary,
    this.supervisorFeedbackSummary,
    this.updatedAt,
    this.propagationTargets = const <SignatureHealthPropagationTarget>[],
    this.temporalLineage,
  });

  bool get hasReadyTargets =>
      propagationTargets.any((target) => target.isReadyForReview);
}

class SignatureHealthUpwardLearningItem {
  final String sourceId;
  final String sourceKind;
  final String learningDirection;
  final String learningPathway;
  final String convictionTier;
  final String status;
  final String summary;
  final String environmentId;
  final String cityCode;
  final List<String> hierarchyPath;
  final String? hierarchySynthesisPlanJsonPath;
  final String? hierarchySynthesisOutcomeJsonPath;
  final String? realityModelAgentHandoffJsonPath;
  final String? realityModelAgentOutcomeJsonPath;
  final String? realityModelTruthReviewJsonPath;
  final String? truthIntegrationStatus;
  final String? realityModelUpdateCandidateJsonPath;
  final String? truthReviewResolution;
  final String? realityModelUpdateDecisionJsonPath;
  final String? realityModelUpdateOutcomeJsonPath;
  final String? updateCandidateResolution;
  final String? realityModelUpdateAdminBriefJsonPath;
  final String? realityModelUpdateSupervisorBriefJsonPath;
  final String? realityModelUpdateSimulationSuggestionJsonPath;
  final String? realityModelUpdateSimulationRequestJsonPath;
  final String? realityModelUpdateSimulationOutcomeJsonPath;
  final String? realityModelUpdateDownstreamRepropagationReviewJsonPath;
  final String? realityModelUpdateDownstreamRepropagationDecisionJsonPath;
  final String? realityModelUpdateDownstreamRepropagationOutcomeJsonPath;
  final String? realityModelUpdateDownstreamRepropagationPlanJsonPath;
  final String? downstreamRepropagationResolution;
  final List<String> downstreamRepropagationReleasedTargetIds;
  final List<String> upwardDomainHints;
  final List<String> upwardReferencedEntities;
  final List<String> upwardQuestions;
  final List<String> upwardSignalTags;
  final List<Map<String, dynamic>> upwardPreferenceSignals;
  final String? followUpPromptQuestion;
  final String? followUpResponseText;
  final String? followUpCompletionMode;
  final SignatureHealthChatObservationSummary? chatObservationSummary;
  final DateTime? updatedAt;
  final SignatureHealthTemporalLineage? temporalLineage;

  const SignatureHealthUpwardLearningItem({
    required this.sourceId,
    required this.sourceKind,
    required this.learningDirection,
    required this.learningPathway,
    required this.convictionTier,
    required this.status,
    required this.summary,
    required this.environmentId,
    required this.cityCode,
    this.hierarchyPath = const <String>[],
    this.hierarchySynthesisPlanJsonPath,
    this.hierarchySynthesisOutcomeJsonPath,
    this.realityModelAgentHandoffJsonPath,
    this.realityModelAgentOutcomeJsonPath,
    this.realityModelTruthReviewJsonPath,
    this.truthIntegrationStatus,
    this.realityModelUpdateCandidateJsonPath,
    this.truthReviewResolution,
    this.realityModelUpdateDecisionJsonPath,
    this.realityModelUpdateOutcomeJsonPath,
    this.updateCandidateResolution,
    this.realityModelUpdateAdminBriefJsonPath,
    this.realityModelUpdateSupervisorBriefJsonPath,
    this.realityModelUpdateSimulationSuggestionJsonPath,
    this.realityModelUpdateSimulationRequestJsonPath,
    this.realityModelUpdateSimulationOutcomeJsonPath,
    this.realityModelUpdateDownstreamRepropagationReviewJsonPath,
    this.realityModelUpdateDownstreamRepropagationDecisionJsonPath,
    this.realityModelUpdateDownstreamRepropagationOutcomeJsonPath,
    this.realityModelUpdateDownstreamRepropagationPlanJsonPath,
    this.downstreamRepropagationResolution,
    this.downstreamRepropagationReleasedTargetIds = const <String>[],
    this.upwardDomainHints = const <String>[],
    this.upwardReferencedEntities = const <String>[],
    this.upwardQuestions = const <String>[],
    this.upwardSignalTags = const <String>[],
    this.upwardPreferenceSignals = const <Map<String, dynamic>>[],
    this.followUpPromptQuestion,
    this.followUpResponseText,
    this.followUpCompletionMode,
    this.chatObservationSummary,
    this.updatedAt,
    this.temporalLineage,
  });

  bool get isReadyForTruthReview =>
      status == 'ready_for_governed_truth_conviction_review' &&
      realityModelUpdateCandidateJsonPath == null;

  bool get isReadyForUpdateDecision =>
      realityModelUpdateCandidateJsonPath != null &&
      realityModelUpdateDecisionJsonPath == null;

  bool get isReadyForValidationSimulationStart =>
      realityModelUpdateOutcomeJsonPath != null &&
      realityModelUpdateSimulationSuggestionJsonPath != null &&
      realityModelUpdateSimulationRequestJsonPath == null;

  bool get isReadyForDownstreamRepropagationDecision =>
      realityModelUpdateDownstreamRepropagationReviewJsonPath != null &&
      realityModelUpdateDownstreamRepropagationDecisionJsonPath == null;

  int get chatAttentionScore => chatObservationSummary == null
      ? 0
      : chatObservationSummary!.openPressureScore +
          (chatObservationSummary!.acknowledgedCount * 1);

  bool get needsChatAttention =>
      (chatObservationSummary?.openPressureScore ?? 0) > 0;
}

class SignatureHealthChatObservationSummary {
  final int totalCount;
  final int acknowledgedCount;
  final int requestedFollowUpCount;
  final int correctedCount;
  final int forgotCount;
  final int stoppedUsingCount;
  final int openRequestedFollowUpCount;
  final int openCorrectedCount;
  final int openForgotCount;
  final int openStoppedUsingCount;
  final GovernedLearningChatObservationOutcome? latestOutcome;
  final GovernedLearningChatObservationValidationStatus? latestValidationStatus;
  final GovernedLearningChatObservationGovernanceStatus? latestGovernanceStatus;
  final GovernedLearningChatObservationAttentionStatus? latestAttentionStatus;
  final DateTime? latestRecordedAt;
  final String? latestFocus;
  final String? latestQuestion;
  final String? latestGovernanceStage;
  final String? latestGovernanceReason;
  final String? latestAttentionDispositionSummary;

  const SignatureHealthChatObservationSummary({
    required this.totalCount,
    required this.acknowledgedCount,
    required this.requestedFollowUpCount,
    required this.correctedCount,
    required this.forgotCount,
    required this.stoppedUsingCount,
    required this.openRequestedFollowUpCount,
    required this.openCorrectedCount,
    required this.openForgotCount,
    required this.openStoppedUsingCount,
    this.latestOutcome,
    this.latestValidationStatus,
    this.latestGovernanceStatus,
    this.latestAttentionStatus,
    this.latestRecordedAt,
    this.latestFocus,
    this.latestQuestion,
    this.latestGovernanceStage,
    this.latestGovernanceReason,
    this.latestAttentionDispositionSummary,
  });

  bool get hasFollowUpPressure => openRequestedFollowUpCount > 0;

  int get openPressureScore =>
      (openRequestedFollowUpCount * 10) +
      (openCorrectedCount * 8) +
      (openStoppedUsingCount * 6) +
      (openForgotCount * 4);
}

class FeedbackTrendWindow {
  final String label;
  final Duration duration;

  const FeedbackTrendWindow({
    required this.label,
    required this.duration,
  });
}

class FeedbackTrendCount {
  final int softIgnoreCount;
  final int hardNotInterestedCount;

  const FeedbackTrendCount({
    required this.softIgnoreCount,
    required this.hardNotInterestedCount,
  });

  int get totalCount => softIgnoreCount + hardNotInterestedCount;
}

class FeedbackTrendRow {
  final String entityType;
  final Map<String, FeedbackTrendCount> countsByWindow;

  const FeedbackTrendRow({
    required this.entityType,
    required this.countsByWindow,
  });

  int get totalCount =>
      countsByWindow.values.fold(0, (sum, count) => sum + count.totalCount);
}

class SignatureHealthOverview {
  final int strongCount;
  final int weakDataCount;
  final int staleCount;
  final int fallbackCount;
  final int reviewNeededCount;
  final int bundleCount;
  final int softIgnoreCount;
  final int hardNotInterestedCount;
  final int kernelGraphRecentCount;
  final int kernelGraphFailedCount;
  final int kernelGraphHumanReviewCount;

  const SignatureHealthOverview({
    required this.strongCount,
    required this.weakDataCount,
    required this.staleCount,
    required this.fallbackCount,
    required this.reviewNeededCount,
    required this.bundleCount,
    required this.softIgnoreCount,
    required this.hardNotInterestedCount,
    this.kernelGraphRecentCount = 0,
    this.kernelGraphFailedCount = 0,
    this.kernelGraphHumanReviewCount = 0,
  });
}

class SignatureHealthSnapshot {
  final DateTime generatedAt;
  final SignatureHealthOverview overview;
  final List<SignatureHealthRecord> records;
  final int reviewQueueCount;
  final List<SignatureHealthReviewQueueItem> reviewItems;
  final List<SignatureHealthServedBasisSummary> servedBasisSummaries;
  final List<SignatureHealthFamilyRestageIntakeReviewSummary>
      familyRestageIntakeReviewSummaries;
  final List<SignatureHealthLabTargetActionItem> labTargetActionItems;
  final List<SignatureHealthBoundedReviewCandidate> boundedReviewCandidates;
  final List<SignatureHealthLearningOutcomeItem> learningOutcomeItems;
  final List<SignatureHealthUpwardLearningItem> upwardLearningItems;
  final List<KernelGraphRunRecord> kernelGraphRuns;

  const SignatureHealthSnapshot({
    required this.generatedAt,
    required this.overview,
    required this.records,
    required this.reviewQueueCount,
    this.reviewItems = const <SignatureHealthReviewQueueItem>[],
    this.servedBasisSummaries = const <SignatureHealthServedBasisSummary>[],
    this.familyRestageIntakeReviewSummaries =
        const <SignatureHealthFamilyRestageIntakeReviewSummary>[],
    this.labTargetActionItems = const <SignatureHealthLabTargetActionItem>[],
    this.boundedReviewCandidates =
        const <SignatureHealthBoundedReviewCandidate>[],
    this.learningOutcomeItems = const <SignatureHealthLearningOutcomeItem>[],
    this.upwardLearningItems = const <SignatureHealthUpwardLearningItem>[],
    this.kernelGraphRuns = const <KernelGraphRunRecord>[],
  });

  List<SignatureHealthRecord> get sourceRecords =>
      records.where((record) => !record.isFeedbackTelemetry).toList();

  List<SignatureHealthRecord> get feedbackRecords =>
      records.where((record) => record.isFeedbackTelemetry).toList();

  Map<SignatureHealthCategory, List<SignatureHealthRecord>> get byCategory {
    final grouped = <SignatureHealthCategory, List<SignatureHealthRecord>>{};
    for (final record in sourceRecords) {
      grouped.putIfAbsent(
          record.healthCategory, () => <SignatureHealthRecord>[]);
      grouped[record.healthCategory]!.add(record);
    }
    return grouped;
  }

  Map<String, List<SignatureHealthRecord>> get byEntityType {
    final grouped = <String, List<SignatureHealthRecord>>{};
    for (final record in sourceRecords) {
      grouped.putIfAbsent(record.entityType, () => <SignatureHealthRecord>[]);
      grouped[record.entityType]!.add(record);
    }
    return grouped;
  }

  Map<String, List<SignatureHealthRecord>> get byProvider {
    final grouped = <String, List<SignatureHealthRecord>>{};
    for (final record in sourceRecords) {
      grouped.putIfAbsent(record.provider, () => <SignatureHealthRecord>[]);
      grouped[record.provider]!.add(record);
    }
    return grouped;
  }

  Map<String, List<SignatureHealthRecord>> get byMetro {
    final grouped = <String, List<SignatureHealthRecord>>{};
    for (final record in sourceRecords) {
      grouped.putIfAbsent(record.metroLabel, () => <SignatureHealthRecord>[]);
      grouped[record.metroLabel]!.add(record);
    }
    return grouped;
  }

  Map<String, List<SignatureHealthRecord>> get feedbackByIntent {
    final grouped = <String, List<SignatureHealthRecord>>{};
    for (final record in feedbackRecords) {
      grouped.putIfAbsent(
          record.categoryLabel, () => <SignatureHealthRecord>[]);
      grouped[record.categoryLabel]!.add(record);
    }
    return grouped;
  }

  static const List<FeedbackTrendWindow> feedbackTrendWindows =
      <FeedbackTrendWindow>[
    FeedbackTrendWindow(label: '24h', duration: Duration(hours: 24)),
    FeedbackTrendWindow(label: '7d', duration: Duration(days: 7)),
    FeedbackTrendWindow(label: '30d', duration: Duration(days: 30)),
  ];

  List<FeedbackTrendRow> buildFeedbackTrendRows({
    DateTime? now,
  }) {
    final effectiveNow = now ?? generatedAt;
    final grouped = <String, Map<String, FeedbackTrendCount>>{};
    for (final record in feedbackRecords) {
      final recordedAt = record.updatedAt ??
          record.lastSignatureRebuildAt ??
          record.lastSyncAt;
      if (recordedAt == null) {
        continue;
      }
      final entityCounts = grouped.putIfAbsent(
        record.entityType,
        () => <String, FeedbackTrendCount>{
          for (final window in feedbackTrendWindows)
            window.label: const FeedbackTrendCount(
                softIgnoreCount: 0, hardNotInterestedCount: 0),
        },
      );
      for (final window in feedbackTrendWindows) {
        if (effectiveNow.difference(recordedAt) > window.duration) {
          continue;
        }
        final current = entityCounts[window.label]!;
        entityCounts[window.label] = FeedbackTrendCount(
          softIgnoreCount: current.softIgnoreCount +
              (record.categoryLabel == 'soft_ignore' ? 1 : 0),
          hardNotInterestedCount: current.hardNotInterestedCount +
              (record.categoryLabel == 'hard_not_interested' ? 1 : 0),
        );
      }
    }

    final rows = grouped.entries
        .map(
          (entry) => FeedbackTrendRow(
            entityType: entry.key,
            countsByWindow: entry.value,
          ),
        )
        .where((row) => row.totalCount > 0)
        .toList()
      ..sort((a, b) => b.totalCount.compareTo(a.totalCount));
    return rows;
  }
}
