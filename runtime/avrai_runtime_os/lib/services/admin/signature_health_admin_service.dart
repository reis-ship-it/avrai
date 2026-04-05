import 'dart:async';
import 'dart:developer' as developer;
import 'dart:convert';
import 'dart:io';

import 'package:avrai_core/models/imports/external_sync_metadata.dart';
import 'package:avrai_core/models/kernel_graph/kernel_graph_models.dart';
import 'package:avrai_runtime_os/services/admin/signature_health_category.dart';
import 'package:avrai_runtime_os/services/admin/signature_health_snapshot.dart';
import 'package:avrai_runtime_os/services/admin/remote_source_health_service.dart';
import 'package:avrai_runtime_os/services/admin/replay_simulation_admin_service.dart';
import 'package:avrai_runtime_os/services/intake/intake_models.dart';
import 'package:avrai_runtime_os/services/intake/upward_air_gap_service.dart';
import 'package:avrai_runtime_os/services/intake/universal_intake_repository.dart';
import 'package:avrai_runtime_os/services/kernel_graph/kernel_graph_run_ledger.dart';
import 'package:avrai_runtime_os/services/reality_model/governed_domain_consumer_state_service.dart';
import 'package:avrai_runtime_os/services/reality_model/governed_upward_learning_intake_service.dart';
import 'package:avrai_runtime_os/services/user/user_governed_learning_chat_observation_service.dart';
import 'package:avrai_core/models/reality/governed_learning_chat_observation_receipt.dart';
import 'package:get_it/get_it.dart';
import 'package:path/path.dart' as path;

enum SignatureHealthReviewResolution {
  approved,
  rejected,
}

class SignatureHealthReviewResolutionResult {
  const SignatureHealthReviewResolutionResult({
    required this.reviewItemId,
    required this.resolution,
    this.executionQueueJsonPath,
    this.executionQueueReadmePath,
    this.learningExecutionJsonPath,
    this.learningExecutionReadmePath,
    this.downstreamPropagationPlanJsonPath,
    this.learningOutcomeJsonPath,
    this.learningOutcomeReadmePath,
    this.hierarchySynthesisPlanJsonPath,
    this.hierarchySynthesisPlanReadmePath,
    this.hierarchySynthesisOutcomeJsonPath,
    this.hierarchySynthesisOutcomeReadmePath,
    this.realityModelAgentHandoffJsonPath,
    this.realityModelAgentHandoffReadmePath,
    this.realityModelAgentOutcomeJsonPath,
    this.realityModelAgentOutcomeReadmePath,
    this.realityModelTruthReviewJsonPath,
    this.realityModelTruthReviewReadmePath,
    this.familyRestageIntakeOutcomeJsonPath,
    this.familyRestageIntakeOutcomeReadmePath,
    this.familyRestageFollowUpOutcomeJsonPath,
    this.familyRestageFollowUpOutcomeReadmePath,
    this.familyRestageResolutionOutcomeJsonPath,
    this.familyRestageResolutionOutcomeReadmePath,
    this.familyRestageExecutionOutcomeJsonPath,
    this.familyRestageExecutionOutcomeReadmePath,
    this.familyRestageApplicationOutcomeJsonPath,
    this.familyRestageApplicationOutcomeReadmePath,
    this.familyRestageApplyOutcomeJsonPath,
    this.familyRestageApplyOutcomeReadmePath,
    this.familyRestageServedBasisUpdateOutcomeJsonPath,
    this.familyRestageServedBasisUpdateOutcomeReadmePath,
  });

  final String reviewItemId;
  final SignatureHealthReviewResolution resolution;
  final String? executionQueueJsonPath;
  final String? executionQueueReadmePath;
  final String? learningExecutionJsonPath;
  final String? learningExecutionReadmePath;
  final String? downstreamPropagationPlanJsonPath;
  final String? learningOutcomeJsonPath;
  final String? learningOutcomeReadmePath;
  final String? hierarchySynthesisPlanJsonPath;
  final String? hierarchySynthesisPlanReadmePath;
  final String? hierarchySynthesisOutcomeJsonPath;
  final String? hierarchySynthesisOutcomeReadmePath;
  final String? realityModelAgentHandoffJsonPath;
  final String? realityModelAgentHandoffReadmePath;
  final String? realityModelAgentOutcomeJsonPath;
  final String? realityModelAgentOutcomeReadmePath;
  final String? realityModelTruthReviewJsonPath;
  final String? realityModelTruthReviewReadmePath;
  final String? familyRestageIntakeOutcomeJsonPath;
  final String? familyRestageIntakeOutcomeReadmePath;
  final String? familyRestageFollowUpOutcomeJsonPath;
  final String? familyRestageFollowUpOutcomeReadmePath;
  final String? familyRestageResolutionOutcomeJsonPath;
  final String? familyRestageResolutionOutcomeReadmePath;
  final String? familyRestageExecutionOutcomeJsonPath;
  final String? familyRestageExecutionOutcomeReadmePath;
  final String? familyRestageApplicationOutcomeJsonPath;
  final String? familyRestageApplicationOutcomeReadmePath;
  final String? familyRestageApplyOutcomeJsonPath;
  final String? familyRestageApplyOutcomeReadmePath;
  final String? familyRestageServedBasisUpdateOutcomeJsonPath;
  final String? familyRestageServedBasisUpdateOutcomeReadmePath;
}

enum SignatureHealthPropagationResolution {
  approved,
  rejected,
}

enum SignatureHealthTruthReviewResolution {
  promoteToUpdateCandidate,
  holdForMoreEvidence,
  rejectIntegration,
}

class SignatureHealthPropagationResolutionResult {
  const SignatureHealthPropagationResolutionResult({
    required this.sourceId,
    required this.targetId,
    required this.resolution,
    this.downstreamPropagationPlanJsonPath,
    this.propagationReceiptJsonPath,
    this.propagationReceiptReadmePath,
  });

  final String sourceId;
  final String targetId;
  final SignatureHealthPropagationResolution resolution;
  final String? downstreamPropagationPlanJsonPath;
  final String? propagationReceiptJsonPath;
  final String? propagationReceiptReadmePath;
}

class SignatureHealthTruthReviewResolutionResult {
  const SignatureHealthTruthReviewResolutionResult({
    required this.sourceId,
    required this.resolution,
    this.realityModelTruthReviewJsonPath,
    this.realityModelTruthReviewReadmePath,
    this.realityModelUpdateCandidateJsonPath,
    this.realityModelUpdateCandidateReadmePath,
  });

  final String sourceId;
  final SignatureHealthTruthReviewResolution resolution;
  final String? realityModelTruthReviewJsonPath;
  final String? realityModelTruthReviewReadmePath;
  final String? realityModelUpdateCandidateJsonPath;
  final String? realityModelUpdateCandidateReadmePath;
}

enum SignatureHealthRealityModelUpdateResolution {
  approveBoundedUpdate,
  holdForMoreEvidence,
  rejectUpdate,
}

class SignatureHealthRealityModelUpdateResolutionResult {
  const SignatureHealthRealityModelUpdateResolutionResult({
    required this.sourceId,
    required this.resolution,
    this.realityModelUpdateCandidateJsonPath,
    this.realityModelUpdateDecisionJsonPath,
    this.realityModelUpdateDecisionReadmePath,
    this.realityModelUpdateOutcomeJsonPath,
    this.realityModelUpdateOutcomeReadmePath,
  });

  final String sourceId;
  final SignatureHealthRealityModelUpdateResolution resolution;
  final String? realityModelUpdateCandidateJsonPath;
  final String? realityModelUpdateDecisionJsonPath;
  final String? realityModelUpdateDecisionReadmePath;
  final String? realityModelUpdateOutcomeJsonPath;
  final String? realityModelUpdateOutcomeReadmePath;
}

class SignatureHealthRealityModelUpdateSimulationStartResult {
  const SignatureHealthRealityModelUpdateSimulationStartResult({
    required this.sourceId,
    this.realityModelUpdateSimulationSuggestionJsonPath,
    this.realityModelUpdateSimulationRequestJsonPath,
    this.realityModelUpdateSimulationRequestReadmePath,
    this.realityModelUpdateSimulationOutcomeJsonPath,
    this.realityModelUpdateDownstreamRepropagationReviewJsonPath,
  });

  final String sourceId;
  final String? realityModelUpdateSimulationSuggestionJsonPath;
  final String? realityModelUpdateSimulationRequestJsonPath;
  final String? realityModelUpdateSimulationRequestReadmePath;
  final String? realityModelUpdateSimulationOutcomeJsonPath;
  final String? realityModelUpdateDownstreamRepropagationReviewJsonPath;
}

enum SignatureHealthDownstreamRepropagationResolution {
  approve,
  reject,
}

class SignatureHealthDownstreamRepropagationResolutionResult {
  const SignatureHealthDownstreamRepropagationResolutionResult({
    required this.sourceId,
    required this.resolution,
    this.realityModelUpdateDownstreamRepropagationReviewJsonPath,
    this.realityModelUpdateDownstreamRepropagationDecisionJsonPath,
    this.realityModelUpdateDownstreamRepropagationOutcomeJsonPath,
  });

  final String sourceId;
  final SignatureHealthDownstreamRepropagationResolution resolution;
  final String? realityModelUpdateDownstreamRepropagationReviewJsonPath;
  final String? realityModelUpdateDownstreamRepropagationDecisionJsonPath;
  final String? realityModelUpdateDownstreamRepropagationOutcomeJsonPath;
}

enum _DownstreamPropagationLaneKind {
  adminEvidenceRefresh,
  supervisorLearningFeedback,
  hierarchyDomainDelta,
  personalAgentPersonalization,
  generic,
}

class _LabTargetProvenancePoint {
  const _LabTargetProvenancePoint({
    required this.recordedAt,
    required this.sourceLabel,
    required this.sidecarRefs,
    required this.trainingArtifactFamilies,
    this.cityPackStructuralRef,
  });

  final DateTime recordedAt;
  final String sourceLabel;
  final List<String> sidecarRefs;
  final List<String> trainingArtifactFamilies;
  final String? cityPackStructuralRef;
}

class SignatureHealthAdminService {
  static const String _logName = 'SignatureHealthAdminService';

  final UniversalIntakeRepository _intakeRepository;
  final RemoteSourceHealthService? _remoteSourceHealthService;
  final GovernedDomainConsumerStateService? _governedDomainConsumerStateService;
  final GovernedUpwardLearningIntakeService?
      _governedUpwardLearningIntakeService;
  final ReplaySimulationAdminService? _replaySimulationAdminService;
  final KernelGraphRunLedger? _kernelGraphRunLedger;
  final UserGovernedLearningChatObservationService?
      _userGovernedLearningChatObservationService;

  SignatureHealthAdminService({
    required UniversalIntakeRepository intakeRepository,
    RemoteSourceHealthService? remoteSourceHealthService,
    GovernedDomainConsumerStateService? governedDomainConsumerStateService,
    GovernedUpwardLearningIntakeService? governedUpwardLearningIntakeService,
    ReplaySimulationAdminService? replaySimulationAdminService,
    KernelGraphRunLedger? kernelGraphRunLedger,
    UserGovernedLearningChatObservationService?
        userGovernedLearningChatObservationService,
  })  : _intakeRepository = intakeRepository,
        _remoteSourceHealthService = remoteSourceHealthService,
        _governedDomainConsumerStateService =
            governedDomainConsumerStateService ??
                (GetIt.I.isRegistered<GovernedDomainConsumerStateService>()
                    ? GetIt.I<GovernedDomainConsumerStateService>()
                    : null),
        _governedUpwardLearningIntakeService =
            governedUpwardLearningIntakeService ??
                (GetIt.I.isRegistered<GovernedUpwardLearningIntakeService>()
                    ? GetIt.I<GovernedUpwardLearningIntakeService>()
                    : null),
        _replaySimulationAdminService = replaySimulationAdminService,
        _kernelGraphRunLedger = kernelGraphRunLedger,
        _userGovernedLearningChatObservationService =
            userGovernedLearningChatObservationService ??
                (GetIt.I.isRegistered<
                        UserGovernedLearningChatObservationService>()
                    ? GetIt.I<UserGovernedLearningChatObservationService>()
                    : null);

  Future<SignatureHealthSnapshot> getSnapshot() async {
    final sources = await _intakeRepository.getAllSources();
    final reviews = await _intakeRepository.getAllReviewItems();
    final remoteRecords = _remoteSourceHealthService == null
        ? const <SignatureHealthRecord>[]
        : await _remoteSourceHealthService.fetchRows();
    final mergedBySourceId = <String, SignatureHealthRecord>{
      for (final record in remoteRecords)
        '${record.sourceId}:${record.entityType}': record,
      for (final source in sources)
        '${source.id}:${source.metadata['entityType'] ?? source.metadata['linkedEntityType'] ?? source.entityHint?.name ?? 'unknown'}':
            _toRecord(source),
    };
    final records = mergedBySourceId.values.toList()
      ..sort((a, b) {
        final categoryCompare = _categoryPriority(a.healthCategory).compareTo(
          _categoryPriority(b.healthCategory),
        );
        if (categoryCompare != 0) {
          return categoryCompare;
        }
        return b.confidence.compareTo(a.confidence);
      });
    final sourceRecords =
        records.where((record) => !record.isFeedbackTelemetry).toList();
    final feedbackRecords =
        records.where((record) => record.isFeedbackTelemetry).toList();
    final kernelGraphRuns = _kernelGraphRunLedger == null
        ? const <KernelGraphRunRecord>[]
        : await _kernelGraphRunLedger.listRuns(
            kind: KernelGraphKind.learningIntake,
            limit: 8,
          );

    final servedBasisSummaries = await _buildServedBasisSummaries();
    final familyRestageIntakeReviewSummaries =
        await _buildFamilyRestageIntakeReviewSummaries();
    final labTargetActionItems = await _buildLabTargetActionItems();
    return SignatureHealthSnapshot(
      generatedAt: DateTime.now(),
      overview: SignatureHealthOverview(
        strongCount: sourceRecords
            .where((record) =>
                record.healthCategory == SignatureHealthCategory.strong)
            .length,
        weakDataCount: sourceRecords
            .where((record) =>
                record.healthCategory == SignatureHealthCategory.weakData)
            .length,
        staleCount: sourceRecords
            .where((record) =>
                record.healthCategory == SignatureHealthCategory.stale)
            .length,
        fallbackCount: sourceRecords
            .where((record) =>
                record.healthCategory == SignatureHealthCategory.fallback)
            .length,
        reviewNeededCount: sourceRecords
            .where((record) =>
                record.healthCategory == SignatureHealthCategory.reviewNeeded)
            .length,
        bundleCount: sourceRecords
            .where((record) =>
                record.healthCategory == SignatureHealthCategory.bundle)
            .length,
        softIgnoreCount: feedbackRecords
            .where((record) => record.categoryLabel == 'soft_ignore')
            .length,
        hardNotInterestedCount: feedbackRecords
            .where((record) => record.categoryLabel == 'hard_not_interested')
            .length,
        kernelGraphRecentCount: kernelGraphRuns.length,
        kernelGraphFailedCount: kernelGraphRuns
            .where((run) => run.status == KernelGraphRunStatus.failed)
            .length,
        kernelGraphHumanReviewCount: kernelGraphRuns
            .where((run) => run.adminDigest.requiresHumanReview)
            .length,
      ),
      records: records,
      reviewQueueCount: reviews.length,
      reviewItems: reviews
          .map(
            (review) => SignatureHealthReviewQueueItem(
              id: review.id,
              sourceId: review.sourceId,
              ownerUserId: review.ownerUserId,
              targetType: review.targetType.name,
              title: review.title,
              summary: review.summary,
              missingFields: review.missingFields,
              createdAt: review.createdAt,
              payload: review.payload,
            ),
          )
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      servedBasisSummaries: servedBasisSummaries,
      familyRestageIntakeReviewSummaries: familyRestageIntakeReviewSummaries,
      labTargetActionItems: labTargetActionItems,
      boundedReviewCandidates:
          _buildBoundedReviewCandidates(labTargetActionItems),
      learningOutcomeItems: _buildLearningOutcomeItems(sources),
      upwardLearningItems: await _buildUpwardLearningItems(sources),
      kernelGraphRuns: kernelGraphRuns,
    );
  }

  Future<KernelGraphRunRecord?> getKernelGraphRun(String runId) async {
    final ledger = _kernelGraphRunLedger;
    if (ledger == null) {
      return null;
    }
    return ledger.getRun(runId);
  }

  Future<List<SignatureHealthLabTargetActionItem>>
      _buildLabTargetActionItems() async {
    final replayService = _replaySimulationAdminService;
    if (replayService == null) {
      return const <SignatureHealthLabTargetActionItem>[];
    }
    try {
      final environments = await replayService.listAvailableEnvironments();
      final items = <SignatureHealthLabTargetActionItem>[];
      for (final environment in environments) {
        final runtimeState = await replayService.getLabRuntimeState(
          environmentId: environment.environmentId,
        );
        final decisions = runtimeState.targetActionDecisions
            .where((entry) => entry.selectedAction.trim().isNotEmpty)
            .toList(growable: false);
        if (decisions.isEmpty) {
          continue;
        }
        final outcomes = await replayService.listLabOutcomes(
          environmentId: environment.environmentId,
          limit: 0,
        );
        final rerunRequests = await replayService.listLabRerunRequests(
          environmentId: environment.environmentId,
          limit: 0,
        );
        final rerunJobs = await replayService.listLabRerunJobs(
          environmentId: environment.environmentId,
          limit: 0,
        );
        for (final decision in decisions) {
          final latestOutcome = _latestLabOutcomeForTarget(
            outcomes: outcomes,
            variantId: decision.variantId,
          );
          final latestRequest = _latestLabRerunRequestForTarget(
            requests: rerunRequests,
            variantId: decision.variantId,
          );
          final latestJob = _latestLabRerunJobForTarget(
            jobs: rerunJobs,
            variantId: decision.variantId,
            preferredJobId: latestRequest?.latestJobId,
          );
          final trendSummary = _buildLabTargetTrendSummary(
            outcomes: outcomes,
            jobs: rerunJobs,
            variantId: decision.variantId,
          );
          final provenanceDeltaSummary = _buildLabTargetProvenanceDeltaSummary(
            outcomes: outcomes,
            jobs: rerunJobs,
            variantId: decision.variantId,
          );
          final provenanceHistorySummary =
              _buildLabTargetProvenanceHistorySummary(
            outcomes: outcomes,
            jobs: rerunJobs,
            variantId: decision.variantId,
          );
          final provenanceEmphasisSummary =
              _buildLabTargetProvenanceEmphasisSummary(
            provenanceHistorySummary,
          );
          final boundedAlertSummary = _buildLabTargetBoundedAlertSummary(
            trendSummary: trendSummary,
            provenanceEmphasisSummary: provenanceEmphasisSummary,
          );
          items.add(
            SignatureHealthLabTargetActionItem(
              environmentId: environment.environmentId,
              displayName: environment.displayName,
              cityCode: environment.cityCode,
              replayYear: environment.replayYear,
              suggestedAction: decision.suggestedAction,
              suggestedReason: decision.suggestedReason,
              selectedAction: decision.selectedAction,
              acceptedSuggestion: decision.acceptedSuggestion,
              updatedAt: decision.updatedAt,
              variantId: decision.variantId,
              variantLabel: decision.variantLabel,
              cityPackStructuralRef: latestOutcome?.cityPackStructuralRef ??
                  latestRequest?.cityPackStructuralRef ??
                  environment.cityPackStructuralRef,
              sidecarRefs: latestOutcome?.sidecarRefs.isNotEmpty == true
                  ? latestOutcome!.sidecarRefs
                  : latestRequest?.sidecarRefs.isNotEmpty == true
                      ? latestRequest!.sidecarRefs
                      : environment.sidecarRefs,
              latestOutcomeDisposition:
                  latestOutcome?.disposition.toWireValue(),
              latestOutcomeRecordedAt: latestOutcome?.recordedAt,
              latestOutcomeRationale: latestOutcome?.operatorRationale,
              latestRerunRequestId: latestRequest?.requestId,
              latestRerunRequestStatus: latestRequest?.requestStatus,
              latestRerunRequestedAt: latestRequest?.requestedAt,
              latestRerunJobId: latestJob?.jobId,
              latestRerunJobStatus: latestJob?.jobStatus,
              latestRerunJobCompletedAt:
                  latestJob?.completedAt ?? latestJob?.startedAt,
              alertAcknowledgedAt: decision.alertAcknowledgedAt,
              alertAcknowledgedSeverityCode:
                  decision.alertAcknowledgedSeverityCode,
              alertEscalatedAt: decision.alertEscalatedAt,
              alertEscalatedSeverityCode: decision.alertEscalatedSeverityCode,
              alertSnoozedUntil: decision.alertSnoozedUntil,
              alertSnoozedSeverityCode: decision.alertSnoozedSeverityCode,
              trendSummary: trendSummary,
              provenanceDeltaSummary: provenanceDeltaSummary,
              provenanceHistorySummary: provenanceHistorySummary,
              provenanceEmphasisSummary: provenanceEmphasisSummary,
              boundedAlertSummary: boundedAlertSummary,
            ),
          );
        }
      }
      items.sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
      return items;
    } catch (e, st) {
      developer.log(
        'Failed to build world simulation lab target actions from runtime state',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return const <SignatureHealthLabTargetActionItem>[];
    }
  }

  Future<List<SignatureHealthServedBasisSummary>>
      _buildServedBasisSummaries() async {
    final replayService = _replaySimulationAdminService;
    if (replayService == null) {
      return const <SignatureHealthServedBasisSummary>[];
    }
    try {
      final environments = await replayService.listAvailableEnvironments();
      final summaries = <SignatureHealthServedBasisSummary>[];
      for (final environment in environments) {
        final servedBasisState = await replayService.getServedBasisState(
          environmentId: environment.environmentId,
        );
        if (servedBasisState == null) {
          continue;
        }
        summaries.add(
          SignatureHealthServedBasisSummary(
            environmentId: environment.environmentId,
            displayName: environment.displayName,
            cityCode: environment.cityCode,
            replayYear: environment.replayYear,
            supportedPlaceRef: servedBasisState.supportedPlaceRef,
            cityPackStructuralRef: servedBasisState.cityPackStructuralRef,
            currentBasisStatus: servedBasisState.currentBasisStatus,
            latestStateHydrationStatus:
                servedBasisState.latestStateHydrationStatus,
            latestStatePromotionReadiness:
                servedBasisState.latestStatePromotionReadiness,
            latestStateDecisionStatus:
                servedBasisState.latestStateDecisionStatus,
            latestStateRevalidationStatus:
                servedBasisState.latestStateRevalidationStatus,
            latestStateRecoveryDecisionStatus:
                servedBasisState.latestStateRecoveryDecisionStatus,
            hydrationFreshnessPosture:
                servedBasisState.hydrationFreshnessPosture,
            servedBasisRef: servedBasisState.servedBasisRef,
            priorServedBasisRef: servedBasisState.priorServedBasisRef,
            latestStateRefreshReceiptRef:
                servedBasisState.latestStateRefreshReceiptRef,
            latestStateRevalidationReceiptRef:
                servedBasisState.latestStateRevalidationReceiptRef,
            latestStateRecoveryDecisionArtifactRef:
                servedBasisState.latestStateRecoveryDecisionArtifactRef,
            updatedAt: servedBasisState.latestStateRecoveryDecisionRecordedAt ??
                servedBasisState.latestStateRevalidatedAt ??
                servedBasisState.latestStateDecisionRecordedAt ??
                servedBasisState.stagedAt,
          ),
        );
      }
      summaries
          .sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
      return summaries;
    } catch (e, st) {
      developer.log(
        'Failed to build served-basis summaries from runtime state',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return const <SignatureHealthServedBasisSummary>[];
    }
  }

  Future<List<SignatureHealthFamilyRestageIntakeReviewSummary>>
      _buildFamilyRestageIntakeReviewSummaries() async {
    final replayService = _replaySimulationAdminService;
    if (replayService == null) {
      return const <SignatureHealthFamilyRestageIntakeReviewSummary>[];
    }
    try {
      final environments = await replayService.listAvailableEnvironments();
      final summaries = <SignatureHealthFamilyRestageIntakeReviewSummary>[];
      for (final environment in environments) {
        final items = await replayService.listLabFamilyRestageReviewItems(
          environmentId: environment.environmentId,
          limit: 0,
        );
        for (final item in items.where(
          (entry) {
            final hasIntakeQueue =
                (entry.restageIntakeReviewItemId ?? '').isNotEmpty ||
                    (entry.restageIntakeQueueJsonPath ?? '').isNotEmpty;
            final hasFollowUpQueue =
                (entry.followUpReviewItemId ?? '').isNotEmpty ||
                    (entry.followUpQueueJsonPath ?? '').isNotEmpty;
            return (entry.queueStatus == 'restage_intake_requested' &&
                    hasIntakeQueue) ||
                (entry.queueStatus == 'restage_intake_review_approved' &&
                    hasFollowUpQueue);
          },
        )) {
          summaries.add(
            SignatureHealthFamilyRestageIntakeReviewSummary(
              environmentId: environment.environmentId,
              displayName: environment.displayName,
              cityCode: environment.cityCode,
              replayYear: environment.replayYear,
              supportedPlaceRef: item.supportedPlaceRef,
              evidenceFamily: item.evidenceFamily,
              restageTarget: item.restageTarget,
              restageTargetSummary: item.restageTargetSummary,
              policyAction: item.policyAction,
              policyActionSummary: item.policyActionSummary,
              queueStatus: item.queueStatus,
              itemJsonPath: item.itemJsonPath,
              queueDecisionArtifactRef: item.queueDecisionArtifactRef,
              queueDecisionRationale: item.queueDecisionRationale,
              restageIntakeQueueJsonPath: item.restageIntakeQueueJsonPath,
              restageIntakeReadmePath: item.restageIntakeReadmePath,
              restageIntakeSourceId: item.restageIntakeSourceId,
              restageIntakeJobId: item.restageIntakeJobId,
              restageIntakeReviewItemId: item.restageIntakeReviewItemId,
              restageIntakeResolutionStatus: item.restageIntakeResolutionStatus,
              restageIntakeResolutionArtifactRef:
                  item.restageIntakeResolutionArtifactRef,
              restageIntakeResolutionRationale:
                  item.restageIntakeResolutionRationale,
              followUpQueueStatus: item.followUpQueueStatus,
              followUpQueueJsonPath: item.followUpQueueJsonPath,
              followUpReadmePath: item.followUpReadmePath,
              followUpSourceId: item.followUpSourceId,
              followUpJobId: item.followUpJobId,
              followUpReviewItemId: item.followUpReviewItemId,
              followUpResolutionStatus: item.followUpResolutionStatus,
              followUpResolutionArtifactRef: item.followUpResolutionArtifactRef,
              followUpResolutionRationale: item.followUpResolutionRationale,
              restageResolutionQueueStatus: item.restageResolutionQueueStatus,
              restageResolutionQueueJsonPath:
                  item.restageResolutionQueueJsonPath,
              restageResolutionReadmePath: item.restageResolutionReadmePath,
              restageResolutionSourceId: item.restageResolutionSourceId,
              restageResolutionJobId: item.restageResolutionJobId,
              restageResolutionReviewItemId: item.restageResolutionReviewItemId,
              restageResolutionResolutionStatus:
                  item.restageResolutionResolutionStatus,
              restageResolutionResolutionArtifactRef:
                  item.restageResolutionResolutionArtifactRef,
              restageResolutionResolutionRationale:
                  item.restageResolutionResolutionRationale,
              restageExecutionQueueStatus: item.restageExecutionQueueStatus,
              restageExecutionQueueJsonPath: item.restageExecutionQueueJsonPath,
              restageExecutionReadmePath: item.restageExecutionReadmePath,
              restageExecutionSourceId: item.restageExecutionSourceId,
              restageExecutionJobId: item.restageExecutionJobId,
              restageExecutionReviewItemId: item.restageExecutionReviewItemId,
              restageExecutionResolutionStatus:
                  item.restageExecutionResolutionStatus,
              restageExecutionResolutionArtifactRef:
                  item.restageExecutionResolutionArtifactRef,
              restageExecutionResolutionRationale:
                  item.restageExecutionResolutionRationale,
              restageApplicationQueueStatus: item.restageApplicationQueueStatus,
              restageApplicationQueueJsonPath:
                  item.restageApplicationQueueJsonPath,
              restageApplicationReadmePath: item.restageApplicationReadmePath,
              restageApplicationSourceId: item.restageApplicationSourceId,
              restageApplicationJobId: item.restageApplicationJobId,
              restageApplicationReviewItemId:
                  item.restageApplicationReviewItemId,
              restageApplicationResolutionStatus:
                  item.restageApplicationResolutionStatus,
              restageApplicationResolutionArtifactRef:
                  item.restageApplicationResolutionArtifactRef,
              restageApplicationResolutionRationale:
                  item.restageApplicationResolutionRationale,
              restageApplyQueueStatus: item.restageApplyQueueStatus,
              restageApplyQueueJsonPath: item.restageApplyQueueJsonPath,
              restageApplyReadmePath: item.restageApplyReadmePath,
              restageApplySourceId: item.restageApplySourceId,
              restageApplyJobId: item.restageApplyJobId,
              restageApplyReviewItemId: item.restageApplyReviewItemId,
              restageApplyResolutionStatus: item.restageApplyResolutionStatus,
              restageApplyResolutionArtifactRef:
                  item.restageApplyResolutionArtifactRef,
              restageApplyResolutionRationale:
                  item.restageApplyResolutionRationale,
              restageServedBasisUpdateQueueStatus:
                  item.restageServedBasisUpdateQueueStatus,
              restageServedBasisUpdateQueueJsonPath:
                  item.restageServedBasisUpdateQueueJsonPath,
              restageServedBasisUpdateReadmePath:
                  item.restageServedBasisUpdateReadmePath,
              restageServedBasisUpdateSourceId:
                  item.restageServedBasisUpdateSourceId,
              restageServedBasisUpdateJobId: item.restageServedBasisUpdateJobId,
              restageServedBasisUpdateReviewItemId:
                  item.restageServedBasisUpdateReviewItemId,
              restageServedBasisUpdateResolutionStatus:
                  item.restageServedBasisUpdateResolutionStatus,
              restageServedBasisUpdateResolutionArtifactRef:
                  item.restageServedBasisUpdateResolutionArtifactRef,
              restageServedBasisUpdateResolutionRationale:
                  item.restageServedBasisUpdateResolutionRationale,
              cityPackStructuralRef: item.cityPackStructuralRef,
              updatedAt: item.restageServedBasisUpdateResolutionRecordedAt ??
                  item.restageApplyResolutionRecordedAt ??
                  item.restageApplicationResolutionRecordedAt ??
                  item.restageExecutionResolutionRecordedAt ??
                  item.restageResolutionResolutionRecordedAt ??
                  item.followUpResolutionRecordedAt ??
                  item.restageIntakeResolutionRecordedAt ??
                  item.queueDecisionRecordedAt ??
                  item.queuedAt,
            ),
          );
        }
      }
      summaries
          .sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
      return summaries;
    } catch (e, st) {
      developer.log(
        'Failed to build family restage intake review summaries from runtime state',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return const <SignatureHealthFamilyRestageIntakeReviewSummary>[];
    }
  }

  List<SignatureHealthBoundedReviewCandidate> _buildBoundedReviewCandidates(
    List<SignatureHealthLabTargetActionItem> items,
  ) {
    return items
        .where((item) => item.isBoundedReviewCandidate)
        .map(
          (item) => SignatureHealthBoundedReviewCandidate(
            environmentId: item.environmentId,
            displayName: item.displayName,
            cityCode: item.cityCode,
            replayYear: item.replayYear,
            suggestedAction: item.suggestedAction,
            suggestedReason: item.suggestedReason,
            selectedAction: item.selectedAction,
            acceptedSuggestion: item.acceptedSuggestion,
            updatedAt: item.updatedAt,
            variantId: item.variantId,
            variantLabel: item.variantLabel,
            cityPackStructuralRef: item.cityPackStructuralRef,
            sidecarRefs: item.sidecarRefs,
            latestOutcomeDisposition: item.latestOutcomeDisposition,
            latestOutcomeRecordedAt: item.latestOutcomeRecordedAt,
            latestOutcomeRationale: item.latestOutcomeRationale,
            latestRerunRequestId: item.latestRerunRequestId,
            latestRerunRequestStatus: item.latestRerunRequestStatus,
            latestRerunRequestedAt: item.latestRerunRequestedAt,
            latestRerunJobId: item.latestRerunJobId,
            latestRerunJobStatus: item.latestRerunJobStatus,
            latestRerunJobCompletedAt: item.latestRerunJobCompletedAt,
            alertAcknowledgedAt: item.alertAcknowledgedAt,
            alertAcknowledgedSeverityCode: item.alertAcknowledgedSeverityCode,
            alertEscalatedAt: item.alertEscalatedAt,
            alertEscalatedSeverityCode: item.alertEscalatedSeverityCode,
            alertSnoozedUntil: item.alertSnoozedUntil,
            alertSnoozedSeverityCode: item.alertSnoozedSeverityCode,
            trendSummary: item.trendSummary,
            provenanceDeltaSummary: item.provenanceDeltaSummary,
            provenanceHistorySummary: item.provenanceHistorySummary,
            provenanceEmphasisSummary: item.provenanceEmphasisSummary,
            boundedAlertSummary: item.boundedAlertSummary,
          ),
        )
        .toList(growable: false);
  }

  Stream<SignatureHealthSnapshot> watchSnapshot() {
    late final StreamController<SignatureHealthSnapshot> controller;
    StreamSubscription<List<ExternalSourceDescriptor>>? sourceSubscription;
    StreamSubscription<List<OrganizerReviewItem>>? reviewSubscription;
    StreamSubscription<List<SignatureHealthRecord>>? remoteSubscription;
    StreamSubscription<List<KernelGraphRunRecord>>? kernelGraphSubscription;

    Future<void> emitSnapshot() async {
      try {
        controller.add(await getSnapshot());
      } catch (e, st) {
        developer.log(
          'Failed to refresh signature health snapshot',
          name: _logName,
          error: e,
          stackTrace: st,
        );
        controller.addError(e, st);
      }
    }

    controller = StreamController<SignatureHealthSnapshot>.broadcast(
      onListen: () async {
        await emitSnapshot();
        sourceSubscription = _intakeRepository.watchSources().listen(
              (_) => emitSnapshot(),
            );
        reviewSubscription = _intakeRepository.watchReviewItems().listen(
              (_) => emitSnapshot(),
            );
        remoteSubscription = _remoteSourceHealthService?.watchRows().listen(
              (_) => emitSnapshot(),
            );
        kernelGraphSubscription = _kernelGraphRunLedger
            ?.watchRuns(
              kind: KernelGraphKind.learningIntake,
              limit: 8,
            )
            .listen(
              (_) => emitSnapshot(),
            );
      },
      onCancel: () async {
        await sourceSubscription?.cancel();
        await reviewSubscription?.cancel();
        await remoteSubscription?.cancel();
        await kernelGraphSubscription?.cancel();
      },
    );

    return controller.stream;
  }

  Future<SignatureHealthSnapshot> acknowledgeLabTargetAlert({
    required String environmentId,
    String? variantId,
    required String alertSeverityCode,
  }) async {
    final replayService = _replaySimulationAdminService;
    if (replayService == null) {
      throw StateError(
        'World simulation lab alert acknowledgments require replay simulation admin service availability.',
      );
    }
    await replayService.acknowledgeLabTargetAlert(
      environmentId: environmentId,
      variantId: variantId,
      alertSeverityCode: alertSeverityCode,
    );
    return getSnapshot();
  }

  Future<SignatureHealthSnapshot> escalateLabTargetAlert({
    required String environmentId,
    String? variantId,
    required String alertSeverityCode,
  }) async {
    final replayService = _replaySimulationAdminService;
    if (replayService == null) {
      throw StateError(
        'World simulation lab alert escalation requires replay simulation admin service availability.',
      );
    }
    await replayService.escalateLabTargetAlert(
      environmentId: environmentId,
      variantId: variantId,
      alertSeverityCode: alertSeverityCode,
    );
    return getSnapshot();
  }

  Future<SignatureHealthSnapshot> snoozeLabTargetAlert({
    required String environmentId,
    String? variantId,
    required String alertSeverityCode,
    required DateTime snoozedUntilUtc,
  }) async {
    final replayService = _replaySimulationAdminService;
    if (replayService == null) {
      throw StateError(
        'World simulation lab alert snoozing requires replay simulation admin service availability.',
      );
    }
    await replayService.snoozeLabTargetAlert(
      environmentId: environmentId,
      variantId: variantId,
      alertSeverityCode: alertSeverityCode,
      snoozedUntilUtc: snoozedUntilUtc,
    );
    return getSnapshot();
  }

  Future<SignatureHealthSnapshot> clearEscalatedLabTargetAlert({
    required String environmentId,
    String? variantId,
  }) async {
    final replayService = _replaySimulationAdminService;
    if (replayService == null) {
      throw StateError(
        'World simulation lab alert de-escalation requires replay simulation admin service availability.',
      );
    }
    await replayService.clearEscalatedLabTargetAlert(
      environmentId: environmentId,
      variantId: variantId,
    );
    return getSnapshot();
  }

  Future<SignatureHealthSnapshot> unsnoozeLabTargetAlert({
    required String environmentId,
    String? variantId,
  }) async {
    final replayService = _replaySimulationAdminService;
    if (replayService == null) {
      throw StateError(
        'World simulation lab alert unsnooze requires replay simulation admin service availability.',
      );
    }
    await replayService.unsnoozeLabTargetAlert(
      environmentId: environmentId,
      variantId: variantId,
    );
    return getSnapshot();
  }

  Future<SignatureHealthReviewResolutionResult> resolveReviewItem({
    required String reviewItemId,
    required SignatureHealthReviewResolution resolution,
  }) async {
    final reviews = await _intakeRepository.getAllReviewItems();
    OrganizerReviewItem? reviewItem;
    for (final candidate in reviews) {
      if (candidate.id == reviewItemId) {
        reviewItem = candidate;
        break;
      }
    }
    if (reviewItem == null) {
      throw StateError('Unknown intake review item: $reviewItemId');
    }

    final source = await _intakeRepository.getSourceById(reviewItem.sourceId);
    String? executionQueueJsonPath;
    String? executionQueueReadmePath;
    String? learningExecutionJsonPath;
    String? learningExecutionReadmePath;
    String? downstreamPropagationPlanJsonPath;
    String? learningOutcomeJsonPath;
    String? learningOutcomeReadmePath;
    String? hierarchySynthesisPlanJsonPath;
    String? hierarchySynthesisPlanReadmePath;
    String? hierarchySynthesisOutcomeJsonPath;
    String? hierarchySynthesisOutcomeReadmePath;
    String? realityModelAgentHandoffJsonPath;
    String? realityModelAgentHandoffReadmePath;
    String? realityModelAgentOutcomeJsonPath;
    String? realityModelAgentOutcomeReadmePath;
    String? realityModelTruthReviewJsonPath;
    String? realityModelTruthReviewReadmePath;
    String? familyRestageIntakeOutcomeJsonPath;
    String? familyRestageIntakeOutcomeReadmePath;
    String? familyRestageFollowUpOutcomeJsonPath;
    String? familyRestageFollowUpOutcomeReadmePath;
    String? familyRestageResolutionOutcomeJsonPath;
    String? familyRestageResolutionOutcomeReadmePath;
    String? familyRestageExecutionOutcomeJsonPath;
    String? familyRestageExecutionOutcomeReadmePath;
    String? familyRestageApplicationOutcomeJsonPath;
    String? familyRestageApplicationOutcomeReadmePath;
    String? familyRestageApplyOutcomeJsonPath;
    String? familyRestageApplyOutcomeReadmePath;
    String? familyRestageServedBasisUpdateOutcomeJsonPath;
    String? familyRestageServedBasisUpdateOutcomeReadmePath;
    if (source != null) {
      final now = DateTime.now();
      final nextSyncState =
          resolution == SignatureHealthReviewResolution.approved
              ? ExternalSyncState.active
              : ExternalSyncState.paused;
      Map<String, dynamic> nextMetadata = <String, dynamic>{
        ...source.metadata,
        'reviewResolution': resolution.name,
        'reviewResolvedAt': now.toUtc().toIso8601String(),
        'reviewResolvedFromQueue': true,
      };
      if (resolution == SignatureHealthReviewResolution.approved &&
          _isSimulationTrainingReview(reviewItem)) {
        final queued = await _queueAcceptedSimulationTrainingExecution(
          reviewItem: reviewItem,
          source: source,
          resolvedAt: now,
        );
        executionQueueJsonPath = queued.$1;
        executionQueueReadmePath = queued.$2;
        learningExecutionJsonPath = queued.$3;
        learningExecutionReadmePath = queued.$4;
        downstreamPropagationPlanJsonPath = queued.$5;
        final executed = await _executeRealityModelLearning(
          learningExecutionJsonPath: learningExecutionJsonPath!,
          downstreamPropagationPlanJsonPath: downstreamPropagationPlanJsonPath!,
          executedAt: now,
        );
        learningOutcomeJsonPath = executed.$1;
        learningOutcomeReadmePath = executed.$2;
        nextMetadata = <String, dynamic>{
          ...nextMetadata,
          'trainingExecutionStatus':
              'queued_for_governed_deeper_training_execution',
          'trainingExecutionQueuedAt': now.toUtc().toIso8601String(),
          'trainingExecutionQueueJsonPath': executionQueueJsonPath,
          'trainingExecutionQueueReadmePath': executionQueueReadmePath,
          'realityModelLearningExecutionStatus':
              'completed_local_reality_model_learning_execution',
          'realityModelLearningExecutionJsonPath': learningExecutionJsonPath,
          'realityModelLearningExecutionReadmePath':
              learningExecutionReadmePath,
          'downstreamPropagationPlanJsonPath':
              downstreamPropagationPlanJsonPath,
          'realityModelLearningOutcomeJsonPath': learningOutcomeJsonPath,
          'realityModelLearningOutcomeReadmePath': learningOutcomeReadmePath,
        };
      } else if (resolution == SignatureHealthReviewResolution.approved &&
          _isUpwardLearningReview(reviewItem)) {
        final staged = await _stageAcceptedUpwardLearningHandoff(
          reviewItem: reviewItem,
          source: source,
          resolvedAt: now,
        );
        hierarchySynthesisPlanJsonPath = staged.$1;
        hierarchySynthesisPlanReadmePath = staged.$2;
        realityModelAgentHandoffJsonPath = staged.$3;
        realityModelAgentHandoffReadmePath = staged.$4;
        final executed = await _executeUpwardLearningHandoff(
          source: source,
          hierarchySynthesisPlanJsonPath: hierarchySynthesisPlanJsonPath,
          realityModelAgentHandoffJsonPath: realityModelAgentHandoffJsonPath,
          executedAt: now,
        );
        hierarchySynthesisOutcomeJsonPath = executed.$1;
        hierarchySynthesisOutcomeReadmePath = executed.$2;
        realityModelAgentOutcomeJsonPath = executed.$3;
        realityModelAgentOutcomeReadmePath = executed.$4;
        final truthReview = await _executeRealityModelTruthReview(
          source: source,
          realityModelAgentOutcomeJsonPath: realityModelAgentOutcomeJsonPath,
          reviewedAt: now,
        );
        realityModelTruthReviewJsonPath = truthReview.$1;
        realityModelTruthReviewReadmePath = truthReview.$2;
        nextMetadata = <String, dynamic>{
          ...nextMetadata,
          'upwardLearningHandoffStatus':
              'completed_local_reality_model_agent_outcome',
          'upwardLearningHandoffQueuedAt': now.toUtc().toIso8601String(),
          'upwardHierarchySynthesisPlanJsonPath':
              hierarchySynthesisPlanJsonPath,
          'upwardHierarchySynthesisPlanReadmePath':
              hierarchySynthesisPlanReadmePath,
          'upwardHierarchySynthesisStatus':
              'completed_local_upward_hierarchy_synthesis',
          'upwardHierarchySynthesisOutcomeJsonPath':
              hierarchySynthesisOutcomeJsonPath,
          'upwardHierarchySynthesisOutcomeReadmePath':
              hierarchySynthesisOutcomeReadmePath,
          'realityModelAgentHandoffJsonPath': realityModelAgentHandoffJsonPath,
          'realityModelAgentHandoffReadmePath':
              realityModelAgentHandoffReadmePath,
          'realityModelAgentOutcomeStatus':
              'completed_local_reality_model_agent_outcome',
          'realityModelAgentOutcomeJsonPath': realityModelAgentOutcomeJsonPath,
          'realityModelAgentOutcomeReadmePath':
              realityModelAgentOutcomeReadmePath,
          'realityModelTruthReviewStatus':
              'ready_for_governed_truth_conviction_review',
          'realityModelTruthReviewJsonPath': realityModelTruthReviewJsonPath,
          'realityModelTruthReviewReadmePath':
              realityModelTruthReviewReadmePath,
        };
        await _recordGovernanceOutcomeForGovernedLearningObservation(
          source: source,
          reviewItem: reviewItem,
          governanceStatus: GovernedLearningChatObservationGovernanceStatus
              .reinforcedByGovernance,
          recordedAt: now,
          governanceStage: 'upward_learning_review',
          governanceReason:
              'The hierarchy approved this bounded upward learning review and advanced it into hierarchy synthesis and reality-model truth review.',
        );
      } else if (resolution == SignatureHealthReviewResolution.rejected &&
          _isUpwardLearningReview(reviewItem)) {
        await _recordGovernanceOutcomeForGovernedLearningObservation(
          source: source,
          reviewItem: reviewItem,
          governanceStatus: GovernedLearningChatObservationGovernanceStatus
              .overruledByGovernance,
          recordedAt: now,
          governanceStage: 'upward_learning_review',
          governanceReason:
              'The hierarchy rejected this bounded upward learning review before it advanced into hierarchy synthesis.',
        );
      } else if (_isFamilyRestageIntakeReview(reviewItem)) {
        final resolved = await _resolveFamilyRestageIntakeReview(
          reviewItem: reviewItem,
          source: source,
          resolution: resolution,
          resolvedAt: now,
        );
        familyRestageIntakeOutcomeJsonPath = resolved.$1;
        familyRestageIntakeOutcomeReadmePath = resolved.$2;
        nextMetadata = <String, dynamic>{
          ...nextMetadata,
          'familyRestageIntakeReviewStatus':
              resolution == SignatureHealthReviewResolution.approved
                  ? 'approved_for_bounded_family_restage_follow_up'
                  : 'held_for_more_family_restage_evidence',
          'familyRestageIntakeReviewResolution': resolution.name,
          'familyRestageIntakeReviewResolvedAt': now.toUtc().toIso8601String(),
          'familyRestageIntakeOutcomeJsonPath':
              familyRestageIntakeOutcomeJsonPath,
          'familyRestageIntakeOutcomeReadmePath':
              familyRestageIntakeOutcomeReadmePath,
        };
      } else if (_isFamilyRestageFollowUpReview(reviewItem)) {
        final resolved = await _resolveFamilyRestageFollowUpReview(
          reviewItem: reviewItem,
          source: source,
          resolution: resolution,
          resolvedAt: now,
        );
        familyRestageFollowUpOutcomeJsonPath = resolved.$1;
        familyRestageFollowUpOutcomeReadmePath = resolved.$2;
        nextMetadata = <String, dynamic>{
          ...nextMetadata,
          'familyRestageFollowUpReviewStatus':
              resolution == SignatureHealthReviewResolution.approved
                  ? 'approved_for_bounded_family_restage_resolution'
                  : 'held_for_more_family_follow_up_evidence',
          'familyRestageFollowUpReviewResolution': resolution.name,
          'familyRestageFollowUpReviewResolvedAt':
              now.toUtc().toIso8601String(),
          'familyRestageFollowUpOutcomeJsonPath':
              familyRestageFollowUpOutcomeJsonPath,
          'familyRestageFollowUpOutcomeReadmePath':
              familyRestageFollowUpOutcomeReadmePath,
        };
      } else if (_isFamilyRestageResolutionReview(reviewItem)) {
        final resolved = await _resolveFamilyRestageResolutionReview(
          reviewItem: reviewItem,
          source: source,
          resolution: resolution,
          resolvedAt: now,
        );
        familyRestageResolutionOutcomeJsonPath = resolved.$1;
        familyRestageResolutionOutcomeReadmePath = resolved.$2;
        nextMetadata = <String, dynamic>{
          ...nextMetadata,
          'familyRestageResolutionReviewStatus':
              resolution == SignatureHealthReviewResolution.approved
                  ? 'approved_for_bounded_family_restage_execution'
                  : 'held_for_more_family_restage_resolution_evidence',
          'familyRestageResolutionReviewResolution': resolution.name,
          'familyRestageResolutionReviewResolvedAt':
              now.toUtc().toIso8601String(),
          'familyRestageResolutionOutcomeJsonPath':
              familyRestageResolutionOutcomeJsonPath,
          'familyRestageResolutionOutcomeReadmePath':
              familyRestageResolutionOutcomeReadmePath,
        };
      } else if (_isFamilyRestageExecutionReview(reviewItem)) {
        final resolved = await _resolveFamilyRestageExecutionReview(
          reviewItem: reviewItem,
          source: source,
          resolution: resolution,
          resolvedAt: now,
        );
        familyRestageExecutionOutcomeJsonPath = resolved.$1;
        familyRestageExecutionOutcomeReadmePath = resolved.$2;
        nextMetadata = <String, dynamic>{
          ...nextMetadata,
          'familyRestageExecutionReviewStatus':
              resolution == SignatureHealthReviewResolution.approved
                  ? 'approved_for_bounded_family_restage_application'
                  : 'held_for_more_family_restage_execution_evidence',
          'familyRestageExecutionReviewResolution': resolution.name,
          'familyRestageExecutionReviewResolvedAt':
              now.toUtc().toIso8601String(),
          'familyRestageExecutionOutcomeJsonPath':
              familyRestageExecutionOutcomeJsonPath,
          'familyRestageExecutionOutcomeReadmePath':
              familyRestageExecutionOutcomeReadmePath,
        };
      } else if (_isFamilyRestageApplicationReview(reviewItem)) {
        final resolved = await _resolveFamilyRestageApplicationReview(
          reviewItem: reviewItem,
          source: source,
          resolution: resolution,
          resolvedAt: now,
        );
        familyRestageApplicationOutcomeJsonPath = resolved.$1;
        familyRestageApplicationOutcomeReadmePath = resolved.$2;
        nextMetadata = <String, dynamic>{
          ...nextMetadata,
          'familyRestageApplicationReviewStatus':
              resolution == SignatureHealthReviewResolution.approved
                  ? 'approved_for_bounded_family_restage_apply_to_served_basis'
                  : 'held_for_more_family_restage_application_evidence',
          'familyRestageApplicationReviewResolution': resolution.name,
          'familyRestageApplicationReviewResolvedAt':
              now.toUtc().toIso8601String(),
          'familyRestageApplicationOutcomeJsonPath':
              familyRestageApplicationOutcomeJsonPath,
          'familyRestageApplicationOutcomeReadmePath':
              familyRestageApplicationOutcomeReadmePath,
        };
      } else if (_isFamilyRestageApplyReview(reviewItem)) {
        final resolved = await _resolveFamilyRestageApplyReview(
          reviewItem: reviewItem,
          source: source,
          resolution: resolution,
          resolvedAt: now,
        );
        familyRestageApplyOutcomeJsonPath = resolved.$1;
        familyRestageApplyOutcomeReadmePath = resolved.$2;
        nextMetadata = <String, dynamic>{
          ...nextMetadata,
          'familyRestageApplyReviewStatus':
              resolution == SignatureHealthReviewResolution.approved
                  ? 'approved_for_bounded_family_restage_served_basis_update'
                  : 'held_for_more_family_restage_apply_evidence',
          'familyRestageApplyReviewResolution': resolution.name,
          'familyRestageApplyReviewResolvedAt': now.toUtc().toIso8601String(),
          'familyRestageApplyOutcomeJsonPath':
              familyRestageApplyOutcomeJsonPath,
          'familyRestageApplyOutcomeReadmePath':
              familyRestageApplyOutcomeReadmePath,
        };
      } else if (_isFamilyRestageServedBasisUpdateReview(reviewItem)) {
        final resolved = await _resolveFamilyRestageServedBasisUpdateReview(
          reviewItem: reviewItem,
          source: source,
          resolution: resolution,
          resolvedAt: now,
        );
        familyRestageServedBasisUpdateOutcomeJsonPath = resolved.$1;
        familyRestageServedBasisUpdateOutcomeReadmePath = resolved.$2;
        nextMetadata = <String, dynamic>{
          ...nextMetadata,
          'familyRestageServedBasisUpdateReviewStatus':
              resolution == SignatureHealthReviewResolution.approved
                  ? 'approved_for_bounded_family_restage_served_basis_mutation'
                  : 'held_for_more_family_restage_served_basis_update_evidence',
          'familyRestageServedBasisUpdateReviewResolution': resolution.name,
          'familyRestageServedBasisUpdateReviewResolvedAt':
              now.toUtc().toIso8601String(),
          'familyRestageServedBasisUpdateOutcomeJsonPath':
              familyRestageServedBasisUpdateOutcomeJsonPath,
          'familyRestageServedBasisUpdateOutcomeReadmePath':
              familyRestageServedBasisUpdateOutcomeReadmePath,
        };
      }
      await _intakeRepository.upsertSource(
        source.copyWith(
          updatedAt: now,
          lastSyncedAt: now,
          syncState: nextSyncState,
          metadata: nextMetadata,
        ),
      );
    }

    await _intakeRepository.deleteReviewItem(reviewItemId);
    return SignatureHealthReviewResolutionResult(
      reviewItemId: reviewItemId,
      resolution: resolution,
      executionQueueJsonPath: executionQueueJsonPath,
      executionQueueReadmePath: executionQueueReadmePath,
      learningExecutionJsonPath: learningExecutionJsonPath,
      learningExecutionReadmePath: learningExecutionReadmePath,
      downstreamPropagationPlanJsonPath: downstreamPropagationPlanJsonPath,
      learningOutcomeJsonPath: learningOutcomeJsonPath,
      learningOutcomeReadmePath: learningOutcomeReadmePath,
      hierarchySynthesisPlanJsonPath: hierarchySynthesisPlanJsonPath,
      hierarchySynthesisPlanReadmePath: hierarchySynthesisPlanReadmePath,
      hierarchySynthesisOutcomeJsonPath: hierarchySynthesisOutcomeJsonPath,
      hierarchySynthesisOutcomeReadmePath: hierarchySynthesisOutcomeReadmePath,
      realityModelAgentHandoffJsonPath: realityModelAgentHandoffJsonPath,
      realityModelAgentHandoffReadmePath: realityModelAgentHandoffReadmePath,
      realityModelAgentOutcomeJsonPath: realityModelAgentOutcomeJsonPath,
      realityModelAgentOutcomeReadmePath: realityModelAgentOutcomeReadmePath,
      realityModelTruthReviewJsonPath: realityModelTruthReviewJsonPath,
      realityModelTruthReviewReadmePath: realityModelTruthReviewReadmePath,
      familyRestageIntakeOutcomeJsonPath: familyRestageIntakeOutcomeJsonPath,
      familyRestageIntakeOutcomeReadmePath:
          familyRestageIntakeOutcomeReadmePath,
      familyRestageFollowUpOutcomeJsonPath:
          familyRestageFollowUpOutcomeJsonPath,
      familyRestageFollowUpOutcomeReadmePath:
          familyRestageFollowUpOutcomeReadmePath,
      familyRestageResolutionOutcomeJsonPath:
          familyRestageResolutionOutcomeJsonPath,
      familyRestageResolutionOutcomeReadmePath:
          familyRestageResolutionOutcomeReadmePath,
      familyRestageExecutionOutcomeJsonPath:
          familyRestageExecutionOutcomeJsonPath,
      familyRestageExecutionOutcomeReadmePath:
          familyRestageExecutionOutcomeReadmePath,
      familyRestageApplicationOutcomeJsonPath:
          familyRestageApplicationOutcomeJsonPath,
      familyRestageApplicationOutcomeReadmePath:
          familyRestageApplicationOutcomeReadmePath,
      familyRestageApplyOutcomeJsonPath: familyRestageApplyOutcomeJsonPath,
      familyRestageApplyOutcomeReadmePath: familyRestageApplyOutcomeReadmePath,
      familyRestageServedBasisUpdateOutcomeJsonPath:
          familyRestageServedBasisUpdateOutcomeJsonPath,
      familyRestageServedBasisUpdateOutcomeReadmePath:
          familyRestageServedBasisUpdateOutcomeReadmePath,
    );
  }

  Future<SignatureHealthPropagationResolutionResult> resolvePropagationTarget({
    required String sourceId,
    required String targetId,
    required SignatureHealthPropagationResolution resolution,
  }) async {
    final source = await _intakeRepository.getSourceById(sourceId);
    if (source == null) {
      throw StateError('Unknown intake source: $sourceId');
    }
    final planPath =
        source.metadata['downstreamPropagationPlanJsonPath']?.toString();
    if (planPath == null || planPath.isEmpty) {
      throw StateError(
        'Source $sourceId is missing downstream propagation plan metadata.',
      );
    }
    final planFile = File(planPath);
    if (!planFile.existsSync()) {
      throw StateError('Downstream propagation plan is missing: $planPath');
    }
    final decoded = jsonDecode(await planFile.readAsString());
    if (decoded is! Map) {
      throw StateError('Downstream propagation plan is invalid: $planPath');
    }
    final plan = Map<String, dynamic>.from(decoded);
    final proposedTargets = List<Map<String, dynamic>>.from(
      (plan['proposedTargets'] as List? ?? const <dynamic>[]).whereType<Map>(),
    );
    final resolvedAt = DateTime.now().toUtc();
    var found = false;
    String? propagationReceiptJsonPath;
    String? propagationReceiptReadmePath;
    Map<String, dynamic> propagationMetadataDelta = const <String, dynamic>{};
    final updatedTargets = proposedTargets.map((entry) {
      final next = Map<String, dynamic>.from(entry);
      if (next['targetId']?.toString() != targetId) {
        if (resolution == SignatureHealthPropagationResolution.approved &&
            _isHierarchyTarget(targetId) &&
            _isPersonalAgentTargetUnlockedBy(next, targetId)) {
          next['status'] = 'ready_for_governed_downstream_propagation_review';
          next['unlockedAt'] = resolvedAt.toIso8601String();
          next['unlockedByTargetId'] = targetId;
          next['temporalLineage'] = _buildTemporalLineagePayload(
            source: source,
            existing: Map<String, dynamic>.from(
              next['temporalLineage'] ?? const <String, dynamic>{},
            ),
            propagationPreparedAt: resolvedAt,
            artifactGeneratedAt: resolvedAt,
            kernelExchangePhase: 'target_unlocked_after_hierarchy_synthesis',
          );
        }
        return next;
      }
      found = true;
      if (resolution == SignatureHealthPropagationResolution.approved) {
        final executed = _executeApprovedPropagationTarget(
          source: source,
          target: next,
          planPath: planPath,
        );
        propagationReceiptJsonPath = executed.jsonPath;
        propagationReceiptReadmePath = executed.readmePath;
        propagationMetadataDelta = executed.metadataDelta;
        next['status'] = 'executed_local_governed_downstream_propagation';
        next['receiptJsonPath'] = propagationReceiptJsonPath;
        next['receiptReadmePath'] = propagationReceiptReadmePath;
        next['laneArtifactJsonPath'] = executed.laneArtifactJsonPath;
        next['laneArtifactReadmePath'] = executed.laneArtifactReadmePath;
        next['temporalLineage'] =
            _readJsonObject(propagationReceiptJsonPath)?['temporalLineage'] ??
                _buildTemporalLineagePayload(
                  source: source,
                  existing: Map<String, dynamic>.from(
                    next['temporalLineage'] ?? const <String, dynamic>{},
                  ),
                  propagationResolvedAt: resolvedAt,
                  artifactGeneratedAt: resolvedAt,
                  kernelExchangePhase: 'approved_downstream_propagation_target',
                );
      } else {
        next['status'] = 'rejected_for_governed_downstream_propagation';
        next['temporalLineage'] = _buildTemporalLineagePayload(
          source: source,
          existing: Map<String, dynamic>.from(
            next['temporalLineage'] ?? const <String, dynamic>{},
          ),
          propagationResolvedAt: resolvedAt,
          artifactGeneratedAt: resolvedAt,
          kernelExchangePhase: 'rejected_downstream_propagation_target',
        );
      }
      next['resolvedAt'] = resolvedAt.toIso8601String();
      return next;
    }).toList(growable: false);
    if (!found) {
      throw StateError(
        'Target $targetId was not found in downstream propagation plan for $sourceId.',
      );
    }
    final updatedPlan = <String, dynamic>{
      ...plan,
      'updatedAt': resolvedAt.toIso8601String(),
      'proposedTargets': updatedTargets,
    };
    await planFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(updatedPlan),
      flush: true,
    );

    final approvedTargets = updatedTargets
        .where(
          (entry) =>
              entry['status'] ==
              'executed_local_governed_downstream_propagation',
        )
        .map((entry) => entry['targetId'].toString())
        .toList(growable: false);
    final rejectedTargets = updatedTargets
        .where(
          (entry) =>
              entry['status'] == 'rejected_for_governed_downstream_propagation',
        )
        .map((entry) => entry['targetId'].toString())
        .toList(growable: false);

    await _intakeRepository.upsertSource(
      source.copyWith(
        updatedAt: DateTime.now(),
        lastSyncedAt: DateTime.now(),
        metadata: <String, dynamic>{
          ...source.metadata,
          'downstreamPropagationPlanJsonPath': planPath,
          'downstreamPropagationApprovedTargets': approvedTargets,
          'downstreamPropagationRejectedTargets': rejectedTargets,
          ...propagationMetadataDelta,
        },
      ),
    );

    return SignatureHealthPropagationResolutionResult(
      sourceId: sourceId,
      targetId: targetId,
      resolution: resolution,
      downstreamPropagationPlanJsonPath: planPath,
      propagationReceiptJsonPath: propagationReceiptJsonPath,
      propagationReceiptReadmePath: propagationReceiptReadmePath,
    );
  }

  Future<SignatureHealthTruthReviewResolutionResult> resolveTruthReview({
    required String sourceId,
    required SignatureHealthTruthReviewResolution resolution,
  }) async {
    final source = await _intakeRepository.getSourceById(sourceId);
    if (source == null) {
      throw StateError('Unknown truth-review source: $sourceId');
    }
    final truthReviewPath =
        source.metadata['realityModelTruthReviewJsonPath']?.toString();
    final truthReviewPayload = _readJsonObject(truthReviewPath);
    if (truthReviewPath == null ||
        truthReviewPath.isEmpty ||
        truthReviewPayload == null) {
      throw StateError(
        'Source `$sourceId` does not have a local reality-model truth review to resolve.',
      );
    }
    final now = DateTime.now().toUtc();
    final updatedTruthReview = Map<String, dynamic>.from(truthReviewPayload);
    final nextStatus = switch (resolution) {
      SignatureHealthTruthReviewResolution.promoteToUpdateCandidate =>
        'promoted_to_reality_model_update_candidate',
      SignatureHealthTruthReviewResolution.holdForMoreEvidence =>
        'held_for_additional_truth_evidence',
      SignatureHealthTruthReviewResolution.rejectIntegration =>
        'rejected_for_truth_integration',
    };
    final nextTruthIntegrationStatus = switch (resolution) {
      SignatureHealthTruthReviewResolution.promoteToUpdateCandidate =>
        'candidate_for_bounded_reality_model_update',
      SignatureHealthTruthReviewResolution.holdForMoreEvidence =>
        'needs_additional_truth_evidence',
      SignatureHealthTruthReviewResolution.rejectIntegration =>
        'rejected_for_truth_integration',
    };
    final nextConvictionAction = switch (resolution) {
      SignatureHealthTruthReviewResolution.promoteToUpdateCandidate =>
        'promoted_to_reality_model_update_candidate',
      SignatureHealthTruthReviewResolution.holdForMoreEvidence =>
        'hold_for_additional_truth_evidence',
      SignatureHealthTruthReviewResolution.rejectIntegration =>
        'reject_truth_integration_candidate',
    };
    updatedTruthReview
      ..['status'] = nextStatus
      ..['truthIntegrationStatus'] = nextTruthIntegrationStatus
      ..['convictionAction'] = nextConvictionAction
      ..['resolvedAt'] = now.toIso8601String()
      ..['truthReviewResolution'] = resolution.name
      ..['temporalLineage'] = _buildTemporalLineagePayload(
        source: source,
        existing: Map<String, dynamic>.from(
          updatedTruthReview['temporalLineage'] ?? const <String, dynamic>{},
        ),
        learningIntegratedAt: now,
        artifactGeneratedAt: now,
        kernelExchangePhase: switch (resolution) {
          SignatureHealthTruthReviewResolution.promoteToUpdateCandidate =>
            'promoted_truth_review_to_update_candidate',
          SignatureHealthTruthReviewResolution.holdForMoreEvidence =>
            'held_truth_review_for_more_evidence',
          SignatureHealthTruthReviewResolution.rejectIntegration =>
            'rejected_truth_review_for_integration',
        },
      );
    await File(truthReviewPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(updatedTruthReview),
      flush: true,
    );

    String? updateCandidateJsonPath;
    String? updateCandidateReadmePath;
    if (resolution ==
        SignatureHealthTruthReviewResolution.promoteToUpdateCandidate) {
      final candidate = await _writeRealityModelUpdateCandidate(
        source: source,
        truthReviewJsonPath: truthReviewPath,
        truthReviewPayload: updatedTruthReview,
        createdAt: now,
      );
      updateCandidateJsonPath = candidate.$1;
      updateCandidateReadmePath = candidate.$2;
    }

    await _intakeRepository.upsertSource(
      source.copyWith(
        updatedAt: now,
        lastSyncedAt: now,
        metadata: <String, dynamic>{
          ...source.metadata,
          'realityModelTruthReviewStatus': nextTruthIntegrationStatus,
          'realityModelTruthReviewResolution': resolution.name,
          'realityModelTruthReviewResolvedAt': now.toIso8601String(),
          'realityModelTruthReviewJsonPath': truthReviewPath,
          'realityModelUpdateCandidateJsonPath': updateCandidateJsonPath,
          'realityModelUpdateCandidateReadmePath': updateCandidateReadmePath,
        },
      ),
    );

    await _recordGovernanceOutcomeForGovernedLearningObservation(
      source: source,
      governanceStatus: switch (resolution) {
        SignatureHealthTruthReviewResolution.promoteToUpdateCandidate =>
          GovernedLearningChatObservationGovernanceStatus
              .reinforcedByGovernance,
        SignatureHealthTruthReviewResolution.holdForMoreEvidence =>
          GovernedLearningChatObservationGovernanceStatus
              .constrainedByGovernance,
        SignatureHealthTruthReviewResolution.rejectIntegration =>
          GovernedLearningChatObservationGovernanceStatus.overruledByGovernance,
      },
      recordedAt: now,
      governanceStage: 'reality_model_truth_review',
      governanceReason: switch (resolution) {
        SignatureHealthTruthReviewResolution.promoteToUpdateCandidate =>
          'The reality-model truth review reinforced this record and promoted it into a bounded update-candidate lane.',
        SignatureHealthTruthReviewResolution.holdForMoreEvidence =>
          'The reality-model truth review held this record for more evidence before broader integration.',
        SignatureHealthTruthReviewResolution.rejectIntegration =>
          'The reality-model truth review rejected broader integration for this record.',
      },
    );

    return SignatureHealthTruthReviewResolutionResult(
      sourceId: sourceId,
      resolution: resolution,
      realityModelTruthReviewJsonPath: truthReviewPath,
      realityModelTruthReviewReadmePath:
          source.metadata['realityModelTruthReviewReadmePath']?.toString(),
      realityModelUpdateCandidateJsonPath: updateCandidateJsonPath,
      realityModelUpdateCandidateReadmePath: updateCandidateReadmePath,
    );
  }

  Future<SignatureHealthRealityModelUpdateResolutionResult>
      resolveRealityModelUpdateCandidate({
    required String sourceId,
    required SignatureHealthRealityModelUpdateResolution resolution,
  }) async {
    final source = await _intakeRepository.getSourceById(sourceId);
    if (source == null) {
      throw StateError('Unknown reality-model update source: $sourceId');
    }
    final updateCandidatePath =
        source.metadata['realityModelUpdateCandidateJsonPath']?.toString();
    final updateCandidatePayload = _readJsonObject(updateCandidatePath);
    if (updateCandidatePath == null ||
        updateCandidatePath.isEmpty ||
        updateCandidatePayload == null) {
      throw StateError(
        'Source `$sourceId` does not have a local reality-model update candidate to resolve.',
      );
    }
    final now = DateTime.now().toUtc();
    final nextStatus = switch (resolution) {
      SignatureHealthRealityModelUpdateResolution.approveBoundedUpdate =>
        'approved_for_bounded_reality_model_update',
      SignatureHealthRealityModelUpdateResolution.holdForMoreEvidence =>
        'held_for_additional_reality_model_update_evidence',
      SignatureHealthRealityModelUpdateResolution.rejectUpdate =>
        'rejected_for_reality_model_update',
    };
    final nextDecisionStatus = switch (resolution) {
      SignatureHealthRealityModelUpdateResolution.approveBoundedUpdate =>
        'bounded_reality_model_update_approved',
      SignatureHealthRealityModelUpdateResolution.holdForMoreEvidence =>
        'bounded_reality_model_update_held_for_more_evidence',
      SignatureHealthRealityModelUpdateResolution.rejectUpdate =>
        'bounded_reality_model_update_rejected',
    };
    final updatedCandidate = Map<String, dynamic>.from(updateCandidatePayload)
      ..['status'] = nextStatus
      ..['updateDecisionStatus'] = nextDecisionStatus
      ..['candidateResolution'] = resolution.name
      ..['resolvedAt'] = now.toIso8601String()
      ..['temporalLineage'] = _buildTemporalLineagePayload(
        source: source,
        existing: Map<String, dynamic>.from(
          updateCandidatePayload['temporalLineage'] ??
              const <String, dynamic>{},
        ),
        learningIntegratedAt: now,
        artifactGeneratedAt: now,
        kernelExchangePhase: switch (resolution) {
          SignatureHealthRealityModelUpdateResolution.approveBoundedUpdate =>
            'approved_bounded_reality_model_update_candidate',
          SignatureHealthRealityModelUpdateResolution.holdForMoreEvidence =>
            'held_bounded_reality_model_update_candidate',
          SignatureHealthRealityModelUpdateResolution.rejectUpdate =>
            'rejected_bounded_reality_model_update_candidate',
        },
      );
    await File(updateCandidatePath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(updatedCandidate),
      flush: true,
    );

    final decision = await _writeRealityModelUpdateDecision(
      source: source,
      updateCandidateJsonPath: updateCandidatePath,
      updateCandidatePayload: updatedCandidate,
      decisionStatus: nextDecisionStatus,
      resolution: resolution,
      createdAt: now,
    );
    final decisionJsonPath = decision.$1;
    final decisionReadmePath = decision.$2;

    String? updateOutcomeJsonPath;
    String? updateOutcomeReadmePath;
    String? adminBriefJsonPath;
    String? adminBriefReadmePath;
    String? supervisorBriefJsonPath;
    String? supervisorBriefReadmePath;
    String? simulationSuggestionJsonPath;
    String? simulationSuggestionReadmePath;
    GovernedUpwardLearningIntakeResult? supervisorBriefObservation;
    if (resolution ==
        SignatureHealthRealityModelUpdateResolution.approveBoundedUpdate) {
      final outcome = await _writeRealityModelUpdateOutcome(
        source: source,
        updateCandidateJsonPath: updateCandidatePath,
        updateDecisionJsonPath: decisionJsonPath,
        updateCandidatePayload: updatedCandidate,
        createdAt: now,
      );
      updateOutcomeJsonPath = outcome.$1;
      updateOutcomeReadmePath = outcome.$2;
      final adminBrief = await _writeRealityModelUpdateAdminBrief(
        source: source,
        updateOutcomeJsonPath: updateOutcomeJsonPath,
        updateCandidatePayload: updatedCandidate,
        createdAt: now,
      );
      adminBriefJsonPath = adminBrief.$1;
      adminBriefReadmePath = adminBrief.$2;
      final supervisorBrief = await _writeRealityModelUpdateSupervisorBrief(
        source: source,
        updateOutcomeJsonPath: updateOutcomeJsonPath,
        updateCandidatePayload: updatedCandidate,
        createdAt: now,
      );
      supervisorBriefJsonPath = supervisorBrief.$1;
      supervisorBriefReadmePath = supervisorBrief.$2;
      supervisorBriefObservation = await _stageSupervisorObservation(
        source: source,
        occurredAtUtc: now,
        observationKind: 'reality_model_update_supervisor_brief',
        summary:
            'Supervisor daemon should prepare a validation simulation posture, but wait for human approval to start.',
        environmentId: updatedCandidate['environmentId']?.toString() ??
            'unknown_environment',
        cityCode: updatedCandidate['cityCode']?.toString() ?? source.cityCode,
        upwardDomainHints: _deriveUpwardRepropagationDomains(source),
        upwardSignalTags: const <String>[
          'origin:signature_health_admin_service',
          'phase:reality_model_update_supervisor_brief',
          'status:ready_for_supervisor_daemon_review',
        ],
        boundedMetadata: <String, dynamic>{
          'sourceId': source.id,
          'originService': 'signature_health_admin_service',
          'supervisorBriefJsonPath': supervisorBriefJsonPath,
          'supervisorBriefReadmePath': supervisorBriefReadmePath,
          'updateOutcomeJsonPath': updateOutcomeJsonPath,
          'daemonPosture':
              'await_human_approval_then_run_validation_simulation',
        },
      );
      final simulationSuggestion =
          await _writeRealityModelUpdateSimulationSuggestion(
        source: source,
        updateOutcomeJsonPath: updateOutcomeJsonPath,
        updateCandidatePayload: updatedCandidate,
        createdAt: now,
      );
      simulationSuggestionJsonPath = simulationSuggestion.$1;
      simulationSuggestionReadmePath = simulationSuggestion.$2;
    }

    await _intakeRepository.upsertSource(
      source.copyWith(
        updatedAt: now,
        lastSyncedAt: now,
        metadata: <String, dynamic>{
          ...source.metadata,
          'realityModelUpdateCandidateJsonPath': updateCandidatePath,
          'realityModelUpdateStatus': nextDecisionStatus,
          'realityModelUpdateCandidateResolution': resolution.name,
          'realityModelUpdateResolvedAt': now.toIso8601String(),
          'realityModelUpdateDecisionJsonPath': decisionJsonPath,
          'realityModelUpdateDecisionReadmePath': decisionReadmePath,
          'realityModelUpdateOutcomeJsonPath': updateOutcomeJsonPath,
          'realityModelUpdateOutcomeReadmePath': updateOutcomeReadmePath,
          'realityModelUpdateAdminBriefJsonPath': adminBriefJsonPath,
          'realityModelUpdateAdminBriefReadmePath': adminBriefReadmePath,
          'realityModelUpdateSupervisorBriefJsonPath': supervisorBriefJsonPath,
          'realityModelUpdateSupervisorBriefReadmePath':
              supervisorBriefReadmePath,
          'realityModelUpdateSimulationSuggestionJsonPath':
              simulationSuggestionJsonPath,
          'realityModelUpdateSimulationSuggestionReadmePath':
              simulationSuggestionReadmePath,
          if (supervisorBriefObservation case final observation?)
            ..._buildSupervisorObservationMetadataDelta(
              existingMetadata: source.metadata,
              observationKind: 'reality_model_update_supervisor_brief',
              result: observation,
              occurredAt: now,
            ),
        },
      ),
    );

    await _recordGovernanceOutcomeForGovernedLearningObservation(
      source: source,
      governanceStatus: switch (resolution) {
        SignatureHealthRealityModelUpdateResolution.approveBoundedUpdate =>
          GovernedLearningChatObservationGovernanceStatus
              .reinforcedByGovernance,
        SignatureHealthRealityModelUpdateResolution.holdForMoreEvidence =>
          GovernedLearningChatObservationGovernanceStatus
              .constrainedByGovernance,
        SignatureHealthRealityModelUpdateResolution.rejectUpdate =>
          GovernedLearningChatObservationGovernanceStatus.overruledByGovernance,
      },
      recordedAt: now,
      governanceStage: 'reality_model_update_review',
      governanceReason: switch (resolution) {
        SignatureHealthRealityModelUpdateResolution.approveBoundedUpdate =>
          'A bounded reality-model update review reinforced this record and approved the next governed update step.',
        SignatureHealthRealityModelUpdateResolution.holdForMoreEvidence =>
          'A bounded reality-model update review held this record for more evidence before the next update step.',
        SignatureHealthRealityModelUpdateResolution.rejectUpdate =>
          'A bounded reality-model update review rejected the proposed update step for this record.',
      },
    );

    return SignatureHealthRealityModelUpdateResolutionResult(
      sourceId: sourceId,
      resolution: resolution,
      realityModelUpdateCandidateJsonPath: updateCandidatePath,
      realityModelUpdateDecisionJsonPath: decisionJsonPath,
      realityModelUpdateDecisionReadmePath: decisionReadmePath,
      realityModelUpdateOutcomeJsonPath: updateOutcomeJsonPath,
      realityModelUpdateOutcomeReadmePath: updateOutcomeReadmePath,
    );
  }

  Future<SignatureHealthRealityModelUpdateSimulationStartResult>
      startRealityModelUpdateValidationSimulation({
    required String sourceId,
  }) async {
    final source = await _intakeRepository.getSourceById(sourceId);
    if (source == null) {
      throw StateError(
          'Unknown reality-model update simulation source: $sourceId');
    }
    final suggestionPath = source
        .metadata['realityModelUpdateSimulationSuggestionJsonPath']
        ?.toString();
    final suggestionPayload = _readJsonObject(suggestionPath);
    if (suggestionPath == null ||
        suggestionPath.isEmpty ||
        suggestionPayload == null) {
      throw StateError(
        'Source `$sourceId` does not have a reality-model update simulation suggestion to start.',
      );
    }
    final now = DateTime.now().toUtc();
    final request = await _writeRealityModelUpdateSimulationRequest(
      source: source,
      simulationSuggestionJsonPath: suggestionPath,
      simulationSuggestionPayload: suggestionPayload,
      createdAt: now,
    );
    final requestJsonPath = request.$1;
    final requestReadmePath = request.$2;
    final simulationOutcome = await _writeRealityModelUpdateSimulationOutcome(
      source: source,
      simulationRequestJsonPath: requestJsonPath,
      simulationSuggestionPayload: suggestionPayload,
      createdAt: now,
    );
    final simulationOutcomeJsonPath = simulationOutcome.$1;
    final simulationOutcomeReadmePath = simulationOutcome.$2;
    final simulationOutcomeObservation = await _stageSupervisorObservation(
      source: source,
      occurredAtUtc: now,
      observationKind: 'reality_model_update_validation_simulation_outcome',
      summary:
          'The daemon-run bounded validation simulation completed with a positive local result for the reality-model update.',
      environmentId: suggestionPayload['environmentId']?.toString() ??
          'unknown_environment',
      cityCode: suggestionPayload['cityCode']?.toString() ?? source.cityCode,
      upwardDomainHints: _deriveUpwardRepropagationDomains(source),
      upwardSignalTags: const <String>[
        'origin:signature_health_admin_service',
        'phase:reality_model_update_validation_simulation_outcome',
        'status:positive_bounded_validation_simulation_outcome',
      ],
      boundedMetadata: <String, dynamic>{
        'sourceId': source.id,
        'originService': 'signature_health_admin_service',
        'simulationRequestJsonPath': requestJsonPath,
        'simulationOutcomeJsonPath': simulationOutcomeJsonPath,
        'simulationOutcomeReadmePath': simulationOutcomeReadmePath,
        'result': 'positive',
      },
    );
    final downstreamReview =
        await _writeRealityModelUpdateDownstreamRepropagationReview(
      source: source,
      simulationOutcomeJsonPath: simulationOutcomeJsonPath,
      simulationSuggestionPayload: suggestionPayload,
      createdAt: now,
    );
    final downstreamReviewJsonPath = downstreamReview.$1;
    final downstreamReviewReadmePath = downstreamReview.$2;
    await _intakeRepository.upsertSource(
      source.copyWith(
        updatedAt: now,
        lastSyncedAt: now,
        metadata: <String, dynamic>{
          ...source.metadata,
          'realityModelUpdateSimulationRequestJsonPath': requestJsonPath,
          'realityModelUpdateSimulationRequestReadmePath': requestReadmePath,
          'realityModelUpdateSimulationRequestStatus':
              'queued_for_supervisor_daemon_validation_simulation',
          'realityModelUpdateSimulationRequestedAt': now.toIso8601String(),
          'realityModelUpdateSimulationOutcomeJsonPath':
              simulationOutcomeJsonPath,
          'realityModelUpdateSimulationOutcomeReadmePath':
              simulationOutcomeReadmePath,
          'realityModelUpdateDownstreamRepropagationReviewJsonPath':
              downstreamReviewJsonPath,
          'realityModelUpdateDownstreamRepropagationReviewReadmePath':
              downstreamReviewReadmePath,
          if (simulationOutcomeObservation case final observation?)
            ..._buildSupervisorObservationMetadataDelta(
              existingMetadata: source.metadata,
              observationKind:
                  'reality_model_update_validation_simulation_outcome',
              result: observation,
              occurredAt: now,
            ),
        },
      ),
    );
    return SignatureHealthRealityModelUpdateSimulationStartResult(
      sourceId: sourceId,
      realityModelUpdateSimulationSuggestionJsonPath: suggestionPath,
      realityModelUpdateSimulationRequestJsonPath: requestJsonPath,
      realityModelUpdateSimulationRequestReadmePath: requestReadmePath,
      realityModelUpdateSimulationOutcomeJsonPath: simulationOutcomeJsonPath,
      realityModelUpdateDownstreamRepropagationReviewJsonPath:
          downstreamReviewJsonPath,
    );
  }

  Future<SignatureHealthDownstreamRepropagationResolutionResult>
      resolveRealityModelUpdateDownstreamRepropagation({
    required String sourceId,
    required SignatureHealthDownstreamRepropagationResolution resolution,
  }) async {
    final source = await _intakeRepository.getSourceById(sourceId);
    if (source == null) {
      throw StateError('Unknown downstream re-propagation source: $sourceId');
    }
    var workingSource = source;
    final reviewPath = source
        .metadata['realityModelUpdateDownstreamRepropagationReviewJsonPath']
        ?.toString();
    final reviewPayload = _readJsonObject(reviewPath);
    if (reviewPath == null || reviewPath.isEmpty || reviewPayload == null) {
      throw StateError(
        'Source `$sourceId` does not have a downstream re-propagation review to resolve.',
      );
    }
    final now = DateTime.now().toUtc();
    final decision =
        await _writeRealityModelUpdateDownstreamRepropagationDecision(
      source: source,
      reviewJsonPath: reviewPath,
      reviewPayload: reviewPayload,
      resolution: resolution,
      createdAt: now,
    );
    final decisionJsonPath = decision.$1;
    final decisionReadmePath = decision.$2;
    String? outcomeJsonPath;
    String? planJsonPath;
    if (resolution ==
        SignatureHealthDownstreamRepropagationResolution.approve) {
      final outcome =
          await _writeRealityModelUpdateDownstreamRepropagationOutcome(
        source: source,
        reviewJsonPath: reviewPath,
        decisionJsonPath: decisionJsonPath,
        reviewPayload: reviewPayload,
        createdAt: now,
      );
      outcomeJsonPath = outcome.$1;
      final plan = _releaseRealityModelUpdateDownstreamRepropagationTargets(
        source: workingSource,
        reviewJsonPath: reviewPath,
        reviewPayload: reviewPayload,
        outcomeJsonPath: outcomeJsonPath,
        createdAt: now,
      );
      planJsonPath = plan.planJsonPath;
      workingSource = workingSource.copyWith(
        metadata: <String, dynamic>{
          ...workingSource.metadata,
          'realityModelUpdateDownstreamRepropagationPlanJsonPath':
              plan.planJsonPath,
          'realityModelUpdateDownstreamRepropagationPlanReadmePath':
              plan.planReadmePath,
          ...plan.metadataDelta,
        },
      );
    }
    final downstreamGateObservation = await _stageSupervisorObservation(
      source: source,
      occurredAtUtc: now,
      observationKind: 'reality_model_update_downstream_repropagation_gate',
      summary: resolution ==
              SignatureHealthDownstreamRepropagationResolution.approve
          ? 'Human review approved bounded downstream re-propagation after a positive validation simulation.'
          : 'Human review rejected downstream re-propagation despite the positive validation simulation.',
      environmentId:
          reviewPayload['environmentId']?.toString() ?? 'unknown_environment',
      cityCode: reviewPayload['cityCode']?.toString() ?? source.cityCode,
      upwardDomainHints: _deriveUpwardRepropagationDomains(source),
      upwardSignalTags: <String>[
        'origin:signature_health_admin_service',
        'phase:reality_model_update_downstream_repropagation_gate',
        'resolution:${resolution.name}',
      ],
      boundedMetadata: <String, dynamic>{
        'sourceId': source.id,
        'originService': 'signature_health_admin_service',
        'reviewJsonPath': reviewPath,
        'decisionJsonPath': decisionJsonPath,
        'decisionReadmePath': decisionReadmePath,
        if (outcomeJsonPath case final path?) 'outcomeJsonPath': path,
        if (planJsonPath case final path?) 'planJsonPath': path,
        'resolution': resolution.name,
      },
    );
    await _intakeRepository.upsertSource(
      workingSource.copyWith(
        updatedAt: now,
        lastSyncedAt: now,
        metadata: <String, dynamic>{
          ...workingSource.metadata,
          'realityModelUpdateDownstreamRepropagationResolution':
              resolution.name,
          'realityModelUpdateDownstreamRepropagationDecisionJsonPath':
              decisionJsonPath,
          'realityModelUpdateDownstreamRepropagationOutcomeJsonPath':
              outcomeJsonPath,
          'realityModelUpdateDownstreamRepropagationPlanJsonPath': planJsonPath,
          if (downstreamGateObservation case final observation?)
            ..._buildSupervisorObservationMetadataDelta(
              existingMetadata: workingSource.metadata,
              observationKind:
                  'reality_model_update_downstream_repropagation_gate',
              result: observation,
              occurredAt: now,
            ),
        },
      ),
    );
    return SignatureHealthDownstreamRepropagationResolutionResult(
      sourceId: sourceId,
      resolution: resolution,
      realityModelUpdateDownstreamRepropagationReviewJsonPath: reviewPath,
      realityModelUpdateDownstreamRepropagationDecisionJsonPath:
          decisionJsonPath,
      realityModelUpdateDownstreamRepropagationOutcomeJsonPath: outcomeJsonPath,
    );
  }

  ({
    String planJsonPath,
    String planReadmePath,
    Map<String, dynamic> metadataDelta
  }) _releaseRealityModelUpdateDownstreamRepropagationTargets({
    required ExternalSourceDescriptor source,
    required String reviewJsonPath,
    required Map<String, dynamic> reviewPayload,
    required String outcomeJsonPath,
    required DateTime createdAt,
  }) {
    final bundleRoot = path.dirname(reviewJsonPath);
    final planJsonPath = path.join(
      bundleRoot,
      'reality_model_update_downstream_repropagation_plan.json',
    );
    final planReadmePath = path.join(
      bundleRoot,
      'REALITY_MODEL_UPDATE_DOWNSTREAM_REPROPAGATION_PLAN_README.md',
    );
    final updateOutcomePayload = _readJsonObject(outcomeJsonPath);
    final targets = _buildRealityModelUpdateDownstreamRepropagationTargets(
      source: source,
      reviewPayload: reviewPayload,
      updateOutcomePayload: updateOutcomePayload,
    );
    var workingSource = source.copyWith(
      metadata: <String, dynamic>{
        ...source.metadata,
        'realityModelUpdateOutcomeJsonPath': outcomeJsonPath,
      },
    );
    var metadataDelta = <String, dynamic>{};
    final executedTargets = <Map<String, dynamic>>[];
    for (final target in targets) {
      final execution = _executeApprovedPropagationTarget(
        source: workingSource,
        target: target,
        planPath: planJsonPath,
      );
      metadataDelta = <String, dynamic>{
        ...metadataDelta,
        ...execution.metadataDelta,
      };
      executedTargets.add(<String, dynamic>{
        ...target,
        'status': 'executed_local_governed_downstream_propagation',
        'receiptJsonPath': execution.jsonPath,
        if (execution.readmePath case final readmePath?)
          'receiptReadmePath': readmePath,
        if (execution.laneArtifactJsonPath case final laneArtifactJsonPath?)
          'laneArtifactJsonPath': laneArtifactJsonPath,
        if (execution.laneArtifactReadmePath case final laneArtifactReadmePath?)
          'laneArtifactReadmePath': laneArtifactReadmePath,
      });
      workingSource = workingSource.copyWith(
        metadata: <String, dynamic>{
          ...workingSource.metadata,
          ...metadataDelta,
        },
      );
    }
    final payload = <String, dynamic>{
      'sourceId': source.id,
      'createdAt': createdAt.toIso8601String(),
      'status': 'executed_bounded_downstream_repropagation_follow_on_lanes',
      'environmentId': reviewPayload['environmentId'] ??
          updateOutcomePayload?['environmentId'] ??
          source.metadata['environmentId'] ??
          'unknown_environment',
      'cityCode': reviewPayload['cityCode'] ??
          updateOutcomePayload?['cityCode'] ??
          source.cityCode ??
          'unknown',
      'reviewJsonPath': reviewJsonPath,
      'realityModelUpdateOutcomeJsonPath': outcomeJsonPath,
      'releasedTargets': executedTargets,
      'summary':
          'Approved bounded downstream re-propagation has been handed back into the existing governed lower-tier follow-on lanes.',
      'temporalLineage': _buildTemporalLineagePayload(
        source: source,
        existing: Map<String, dynamic>.from(
          reviewPayload['temporalLineage'] ?? const <String, dynamic>{},
        ),
        propagationResolvedAt: createdAt,
        artifactGeneratedAt: createdAt,
        kernelExchangePhase:
            'executed_bounded_downstream_repropagation_follow_on_lanes',
      ),
      'notes': <String>[
        'This plan restarts the existing governed downstream engine after a positive validation simulation and explicit human approval.',
        'The release remains bounded: admin and supervisor refresh first, then hierarchy-level deltas. Personal-agent personalization remains downstream of hierarchy synthesis.',
      ],
    };
    File(planJsonPath).writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(payload),
      flush: true,
    );
    File(planReadmePath).writeAsStringSync(
      '# Reality-Model Update Downstream Re-Propagation Plan\n\n'
      'This artifact records the bounded lower-tier follow-on lanes released after a positive validation simulation and explicit human approval.\n',
      flush: true,
    );
    return (
      planJsonPath: planJsonPath,
      planReadmePath: planReadmePath,
      metadataDelta: <String, dynamic>{
        'realityModelUpdateDownstreamRepropagationPlanJsonPath': planJsonPath,
        'realityModelUpdateDownstreamRepropagationPlanReadmePath':
            planReadmePath,
        'realityModelUpdateDownstreamRepropagationReleasedTargetIds': targets
            .map((target) => target['targetId']?.toString() ?? '')
            .where((targetId) => targetId.isNotEmpty)
            .toList(growable: false),
        'realityModelUpdateDownstreamRepropagationReleasedAt':
            createdAt.toIso8601String(),
        ...metadataDelta,
      },
    );
  }

  ({
    String jsonPath,
    String? readmePath,
    String? laneArtifactJsonPath,
    String? laneArtifactReadmePath,
    Map<String, dynamic> metadataDelta,
  }) _executeApprovedPropagationTarget({
    required ExternalSourceDescriptor source,
    required Map<String, dynamic> target,
    required String planPath,
  }) {
    final bundleRoot =
        source.metadata['bundleRoot']?.toString() ?? path.dirname(planPath);
    final targetId = target['targetId']?.toString() ?? 'unknown_target';
    final laneKind = _resolvePropagationLaneKind(targetId);
    final sanitizedTargetId = targetId
        .replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '')
        .toLowerCase();
    final basename = switch (laneKind) {
      _DownstreamPropagationLaneKind.adminEvidenceRefresh =>
        'admin_evidence_refresh_receipt_${sanitizedTargetId.isEmpty ? 'target' : sanitizedTargetId}',
      _DownstreamPropagationLaneKind.supervisorLearningFeedback =>
        'supervisor_learning_feedback_receipt_${sanitizedTargetId.isEmpty ? 'target' : sanitizedTargetId}',
      _DownstreamPropagationLaneKind.hierarchyDomainDelta =>
        'hierarchy_domain_delta_receipt_${sanitizedTargetId.isEmpty ? 'target' : sanitizedTargetId}',
      _DownstreamPropagationLaneKind.personalAgentPersonalization =>
        'personal_agent_personalization_receipt_${sanitizedTargetId.isEmpty ? 'target' : sanitizedTargetId}',
      _DownstreamPropagationLaneKind.generic =>
        'downstream_propagation_receipt_${sanitizedTargetId.isEmpty ? 'target' : sanitizedTargetId}',
    };
    final receiptJsonPath = path.join(
      bundleRoot,
      '$basename.json',
    );
    final receiptReadmePath = path.join(
      bundleRoot,
      '${basename.toUpperCase()}.md',
    );
    final now = DateTime.now().toUtc();
    final learningOutcomePath =
        source.metadata['realityModelLearningOutcomeJsonPath']?.toString() ??
            source.metadata['realityModelUpdateOutcomeJsonPath']?.toString();
    final learningOutcomePayload = _readJsonObject(learningOutcomePath);
    final planPayload = _readJsonObject(planPath);
    final temporalLineage = _buildTemporalLineagePayload(
      source: source,
      existing: Map<String, dynamic>.from(
        learningOutcomePayload?['temporalLineage'] ??
            planPayload?['temporalLineage'] ??
            const <String, dynamic>{},
      ),
      propagationResolvedAt: now,
      artifactGeneratedAt: now,
      kernelExchangePhase: switch (laneKind) {
        _DownstreamPropagationLaneKind.adminEvidenceRefresh =>
          'admin_evidence_refresh_propagation',
        _DownstreamPropagationLaneKind.supervisorLearningFeedback =>
          'supervisor_learning_feedback_propagation',
        _DownstreamPropagationLaneKind.hierarchyDomainDelta =>
          'hierarchy_domain_delta_propagation',
        _DownstreamPropagationLaneKind.personalAgentPersonalization =>
          'personal_agent_personalization_propagation',
        _DownstreamPropagationLaneKind.generic =>
          'generic_downstream_propagation',
      },
    );
    final receipt = <String, dynamic>{
      'sourceId': source.id,
      'executedAt': now.toIso8601String(),
      'targetId': targetId,
      'laneKind': switch (laneKind) {
        _DownstreamPropagationLaneKind.adminEvidenceRefresh =>
          'admin_evidence_refresh',
        _DownstreamPropagationLaneKind.supervisorLearningFeedback =>
          'supervisor_learning_feedback',
        _DownstreamPropagationLaneKind.hierarchyDomainDelta =>
          'hierarchy_domain_delta',
        _DownstreamPropagationLaneKind.personalAgentPersonalization =>
          'personal_agent_personalization',
        _DownstreamPropagationLaneKind.generic =>
          'generic_downstream_propagation',
      },
      'propagationKind': target['propagationKind'],
      'reason': target['reason'],
      'status': 'executed_local_governed_downstream_propagation',
      'learningOutcomeJsonPath': learningOutcomePath,
      'planPath': planPath,
      'temporalLineage': temporalLineage,
      'notes': <String>[
        'This local-first propagation receipt records a governed downstream update after a completed governed reality-model outcome.',
        'The lower-tier update remains explicitly derived from the governed reality-model result, not from raw simulation artifacts.',
      ],
    };
    File(receiptJsonPath).writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(receipt),
      flush: true,
    );
    File(receiptReadmePath).writeAsStringSync(
      _buildPropagationReceiptReadme(receipt),
      flush: true,
    );
    String? laneArtifactJsonPath;
    String? laneArtifactReadmePath;
    final metadataDelta = switch (laneKind) {
      _DownstreamPropagationLaneKind.adminEvidenceRefresh => () {
          final artifact = _writeAdminEvidenceRefreshArtifact(
            source: source,
            targetId: targetId,
            bundleRoot: bundleRoot,
            sanitizedTargetId: sanitizedTargetId,
            learningOutcomePath: learningOutcomePath,
            learningOutcomePayload: learningOutcomePayload,
            executedAt: now,
            temporalLineage: temporalLineage,
          );
          laneArtifactJsonPath = artifact.jsonPath;
          laneArtifactReadmePath = artifact.readmePath;
          return <String, dynamic>{
            'adminEvidenceRefreshStatus': 'executed_local_governed_refresh',
            'adminEvidenceRefreshTargetId': targetId,
            'adminEvidenceRefreshReceiptJsonPath': receiptJsonPath,
            'adminEvidenceRefreshReceiptReadmePath': receiptReadmePath,
            'adminEvidenceRefreshSnapshotJsonPath': artifact.jsonPath,
            'adminEvidenceRefreshSnapshotReadmePath': artifact.readmePath,
            'adminEvidenceRefreshUpdatedAt': now.toIso8601String(),
          };
        }(),
      _DownstreamPropagationLaneKind.supervisorLearningFeedback => () {
          final artifact = _writeSupervisorLearningFeedbackArtifact(
            source: source,
            targetId: targetId,
            bundleRoot: bundleRoot,
            sanitizedTargetId: sanitizedTargetId,
            learningOutcomePath: learningOutcomePath,
            learningOutcomePayload: learningOutcomePayload,
            executedAt: now,
            temporalLineage: temporalLineage,
          );
          laneArtifactJsonPath = artifact.jsonPath;
          laneArtifactReadmePath = artifact.readmePath;
          return <String, dynamic>{
            'supervisorLearningFeedbackStatus':
                'executed_local_governed_feedback',
            'supervisorLearningFeedbackTargetId': targetId,
            'supervisorLearningFeedbackReceiptJsonPath': receiptJsonPath,
            'supervisorLearningFeedbackReceiptReadmePath': receiptReadmePath,
            'supervisorLearningFeedbackStateJsonPath': artifact.jsonPath,
            'supervisorLearningFeedbackStateReadmePath': artifact.readmePath,
            'supervisorLearningFeedbackUpdatedAt': now.toIso8601String(),
          };
        }(),
      _DownstreamPropagationLaneKind.hierarchyDomainDelta => () {
          final artifact = _writeHierarchyDomainDeltaArtifact(
            source: source,
            targetId: targetId,
            bundleRoot: bundleRoot,
            sanitizedTargetId: sanitizedTargetId,
            learningOutcomePath: learningOutcomePath,
            learningOutcomePayload: learningOutcomePayload,
            executedAt: now,
            temporalLineage: temporalLineage,
          );
          laneArtifactJsonPath = artifact.jsonPath;
          laneArtifactReadmePath = artifact.readmePath;
          final domainId = _extractHierarchyDomainId(targetId);
          final receiptPaths = Map<String, dynamic>.from(
            source.metadata['hierarchyPropagationReceiptJsonPaths'] ??
                const <String, dynamic>{},
          )..[domainId] = receiptJsonPath;
          final receiptReadmes = Map<String, dynamic>.from(
            source.metadata['hierarchyPropagationReceiptReadmePaths'] ??
                const <String, dynamic>{},
          )..[domainId] = receiptReadmePath;
          final deltaPaths = Map<String, dynamic>.from(
            source.metadata['hierarchyPropagationDeltaJsonPaths'] ??
                const <String, dynamic>{},
          )..[domainId] = artifact.jsonPath;
          final deltaReadmes = Map<String, dynamic>.from(
            source.metadata['hierarchyPropagationDeltaReadmePaths'] ??
                const <String, dynamic>{},
          )..[domainId] = artifact.readmePath;
          final domains = List<String>.from(
            source.metadata['hierarchyPropagationDomains'] ?? const <String>[],
          );
          if (!domains.contains(domainId)) {
            domains.add(domainId);
            domains.sort();
          }
          return <String, dynamic>{
            'hierarchyPropagationStatus': 'executed_local_governed_delta',
            'hierarchyPropagationUpdatedAt': now.toIso8601String(),
            'hierarchyPropagationReceiptJsonPaths': receiptPaths,
            'hierarchyPropagationReceiptReadmePaths': receiptReadmes,
            'hierarchyPropagationDeltaJsonPaths': deltaPaths,
            'hierarchyPropagationDeltaReadmePaths': deltaReadmes,
            'hierarchyPropagationDomains': domains,
          };
        }(),
      _DownstreamPropagationLaneKind.personalAgentPersonalization => () {
          final artifact = _writePersonalAgentPersonalizationArtifact(
            source: source,
            targetId: targetId,
            bundleRoot: bundleRoot,
            sanitizedTargetId: sanitizedTargetId,
            learningOutcomePath: learningOutcomePath,
            learningOutcomePayload: learningOutcomePayload,
            executedAt: now,
            temporalLineage: temporalLineage,
          );
          laneArtifactJsonPath = artifact.jsonPath;
          laneArtifactReadmePath = artifact.readmePath;
          final domainId = _extractPersonalAgentDomainId(targetId);
          final receiptPaths = Map<String, dynamic>.from(
            source.metadata['personalAgentPersonalizationReceiptJsonPaths'] ??
                const <String, dynamic>{},
          )..[domainId] = receiptJsonPath;
          final receiptReadmes = Map<String, dynamic>.from(
            source.metadata['personalAgentPersonalizationReceiptReadmePaths'] ??
                const <String, dynamic>{},
          )..[domainId] = receiptReadmePath;
          final deltaPaths = Map<String, dynamic>.from(
            source.metadata['personalAgentPersonalizationDeltaJsonPaths'] ??
                const <String, dynamic>{},
          )..[domainId] = artifact.jsonPath;
          final deltaReadmes = Map<String, dynamic>.from(
            source.metadata['personalAgentPersonalizationDeltaReadmePaths'] ??
                const <String, dynamic>{},
          )..[domainId] = artifact.readmePath;
          final domains = List<String>.from(
            source.metadata['personalAgentPersonalizationDomains'] ??
                const <String>[],
          );
          if (!domains.contains(domainId)) {
            domains.add(domainId);
            domains.sort();
          }
          return <String, dynamic>{
            'personalAgentPersonalizationStatus':
                'executed_local_governed_personalization',
            'personalAgentPersonalizationUpdatedAt': now.toIso8601String(),
            'personalAgentPersonalizationReceiptJsonPaths': receiptPaths,
            'personalAgentPersonalizationReceiptReadmePaths': receiptReadmes,
            'personalAgentPersonalizationDeltaJsonPaths': deltaPaths,
            'personalAgentPersonalizationDeltaReadmePaths': deltaReadmes,
            'personalAgentPersonalizationDomains': domains,
          };
        }(),
      _DownstreamPropagationLaneKind.generic => <String, dynamic>{
          'genericDownstreamPropagationReceiptJsonPath': receiptJsonPath,
          'genericDownstreamPropagationReceiptReadmePath': receiptReadmePath,
        },
    };
    return (
      jsonPath: receiptJsonPath,
      readmePath: receiptReadmePath,
      laneArtifactJsonPath: laneArtifactJsonPath,
      laneArtifactReadmePath: laneArtifactReadmePath,
      metadataDelta: metadataDelta,
    );
  }

  ({String jsonPath, String readmePath}) _writeAdminEvidenceRefreshArtifact({
    required ExternalSourceDescriptor source,
    required String targetId,
    required String bundleRoot,
    required String sanitizedTargetId,
    required String? learningOutcomePath,
    required Map<String, dynamic>? learningOutcomePayload,
    required DateTime executedAt,
    required Map<String, dynamic> temporalLineage,
  }) {
    final basename =
        'admin_evidence_refresh_snapshot_${sanitizedTargetId.isEmpty ? 'target' : sanitizedTargetId}';
    final jsonPath = path.join(bundleRoot, '$basename.json');
    final readmePath = path.join(bundleRoot, '${basename.toUpperCase()}.md');
    final domainCoverage = Map<String, dynamic>.from(
      learningOutcomePayload?['domainCoverage'] ?? const <String, dynamic>{},
    );
    final learningDeltas = List<String>.from(
      learningOutcomePayload?['learningDeltas'] ?? const <String>[],
    );
    final payload = <String, dynamic>{
      'sourceId': source.id,
      'targetId': targetId,
      'generatedAt': executedAt.toIso8601String(),
      'status': 'executed_local_governed_refresh',
      'environmentId': learningOutcomePayload?['environmentId'] ??
          source.metadata['environmentId'] ??
          'unknown_environment',
      'cityCode': learningOutcomePayload?['cityCode'] ?? source.cityCode,
      'learningOutcomeJsonPath': learningOutcomePath,
      'learningPathway': learningOutcomePayload?['learningPathway'],
      'temporalLineage': temporalLineage,
      'summary': learningOutcomePayload?['summary'] ??
          'Admin evidence surfaces refreshed locally from the reality-model learning outcome.',
      'requestCount': learningOutcomePayload?['requestCount'] ?? 0,
      'recommendationCount':
          learningOutcomePayload?['recommendationCount'] ?? 0,
      'averageConfidence': learningOutcomePayload?['averageConfidence'],
      'domainCoverage': domainCoverage,
      'learningDeltas': learningDeltas,
      'notes': <String>[
        'This artifact refreshes operator-facing evidence from the completed reality-model learning outcome.',
        'Admin surfaces should use this to explain what the reality model learned before any broader propagation decisions.',
      ],
    };
    File(jsonPath).writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(payload),
      flush: true,
    );
    File(readmePath).writeAsStringSync(
      _buildAdminEvidenceRefreshReadme(payload),
      flush: true,
    );
    return (jsonPath: jsonPath, readmePath: readmePath);
  }

  Future<GovernedUpwardLearningIntakeResult?> _stageSupervisorObservation({
    required ExternalSourceDescriptor source,
    required DateTime occurredAtUtc,
    required String observationKind,
    required String summary,
    required Map<String, dynamic> boundedMetadata,
    String? environmentId,
    String? cityCode,
    String? localityCode,
    List<String> upwardDomainHints = const <String>[],
    List<String> upwardSignalTags = const <String>[],
  }) async {
    final governedService = _governedUpwardLearningIntakeService;
    if (governedService == null) {
      return null;
    }
    final trimmedSummary = summary.trim();
    if (trimmedSummary.isEmpty) {
      return null;
    }
    final normalizedEnvironmentId =
        environmentId?.trim().isNotEmpty == true ? environmentId!.trim() : null;
    final normalizedCityCode = cityCode?.trim().isNotEmpty == true
        ? cityCode!.trim()
        : source.cityCode;
    final normalizedLocalityCode = localityCode?.trim().isNotEmpty == true
        ? localityCode!.trim()
        : source.localityCode;
    final normalizedHints = <String>{
      'reality_model',
      'supervisor',
      ...List<String>.from(
        source.metadata['upwardDomainHints'] ?? const <String>[],
      ).where((value) => value.trim().isNotEmpty),
      ...upwardDomainHints.where((value) => value.trim().isNotEmpty),
    }.toList()
      ..sort();
    final airGapArtifact = const UpwardAirGapService().issueArtifact(
      originPlane: 'supervisor_daemon',
      sourceKind: 'supervisor_bounded_observation_intake',
      sourceScope: 'supervisor',
      destinationCeiling: 'reality_model_agent',
      issuedAtUtc: DateTime.now().toUtc(),
      pseudonymousActorRef:
          'supervisor:${normalizedEnvironmentId ?? 'unknown_environment'}',
      sanitizedPayload: <String, dynamic>{
        'sourceId': source.id,
        'observationKind': observationKind,
        'summary': trimmedSummary,
        if (normalizedEnvironmentId case final value?) 'environmentId': value,
        if (normalizedCityCode case final value?) 'cityCode': value,
        if (normalizedLocalityCode case final value?) 'localityCode': value,
        'upwardDomainHints': normalizedHints,
        'boundedMetadata': boundedMetadata,
      },
    );
    try {
      return await governedService.stageSupervisorAssistantObservationIntake(
        observerId:
            'supervisor_daemon:${normalizedEnvironmentId ?? 'unknown_environment'}',
        observerKind: 'supervisor',
        occurredAtUtc: occurredAtUtc,
        summary: trimmedSummary,
        airGapArtifact: airGapArtifact,
        environmentId: normalizedEnvironmentId,
        cityCode: normalizedCityCode,
        localityCode: normalizedLocalityCode,
        observationKind: observationKind,
        upwardDomainHints: normalizedHints,
        upwardReferencedEntities: <String>['source:${source.id}'],
        upwardSignalTags: upwardSignalTags,
        boundedMetadata: boundedMetadata,
      );
    } catch (error, stackTrace) {
      developer.log(
        'Failed to stage supervisor bounded observation for `${source.id}`.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Map<String, dynamic> _buildSupervisorObservationMetadataDelta({
    required Map<String, dynamic> existingMetadata,
    required String observationKind,
    required GovernedUpwardLearningIntakeResult result,
    required DateTime occurredAt,
  }) {
    return <String, dynamic>{
      'latestSupervisorObservationKind': observationKind,
      'latestSupervisorObservationSourceId': result.sourceId,
      'latestSupervisorObservationReviewItemId': result.reviewItemId,
      'latestSupervisorObservationOccurredAt': occurredAt.toIso8601String(),
      'latestSupervisorObservationTemporalLineage': result.temporalLineage,
      'supervisorObservationSourceIds': _appendUniqueString(
        existing: List<String>.from(
          existingMetadata['supervisorObservationSourceIds'] ??
              const <String>[],
        ),
        value: result.sourceId,
      ),
      'supervisorObservationReviewItemIds': _appendUniqueString(
        existing: List<String>.from(
          existingMetadata['supervisorObservationReviewItemIds'] ??
              const <String>[],
        ),
        value: result.reviewItemId,
      ),
    };
  }

  List<String> _appendUniqueString({
    required List<String> existing,
    required String value,
  }) {
    final next = existing.toSet();
    if (value.trim().isNotEmpty) {
      next.add(value.trim());
    }
    return next.toList()..sort();
  }

  ({String jsonPath, String readmePath})
      _writeSupervisorLearningFeedbackArtifact({
    required ExternalSourceDescriptor source,
    required String targetId,
    required String bundleRoot,
    required String sanitizedTargetId,
    required String? learningOutcomePath,
    required Map<String, dynamic>? learningOutcomePayload,
    required DateTime executedAt,
    required Map<String, dynamic> temporalLineage,
  }) {
    final basename =
        'supervisor_learning_feedback_state_${sanitizedTargetId.isEmpty ? 'target' : sanitizedTargetId}';
    final jsonPath = path.join(bundleRoot, '$basename.json');
    final readmePath = path.join(bundleRoot, '${basename.toUpperCase()}.md');
    final averageConfidence =
        (learningOutcomePayload?['averageConfidence'] as num?)?.toDouble();
    final payload = <String, dynamic>{
      'sourceId': source.id,
      'targetId': targetId,
      'generatedAt': executedAt.toIso8601String(),
      'status': 'executed_local_governed_feedback',
      'environmentId': learningOutcomePayload?['environmentId'] ??
          source.metadata['environmentId'] ??
          'unknown_environment',
      'cityCode': learningOutcomePayload?['cityCode'] ?? source.cityCode,
      'learningOutcomeJsonPath': learningOutcomePath,
      'learningPathway': learningOutcomePayload?['learningPathway'],
      'temporalLineage': temporalLineage,
      'outcomeStatus': learningOutcomePayload?['status'],
      'requestCount': learningOutcomePayload?['requestCount'] ?? 0,
      'recommendationCount':
          learningOutcomePayload?['recommendationCount'] ?? 0,
      'averageConfidence': averageConfidence,
      'boundedRecommendation':
          _deriveSupervisorRecommendation(learningOutcomePayload),
      'feedbackSummary':
          'Supervisor learning has absorbed the local reality-model outcome and should use it as bounded evidence for later scheduling and recommendation posture.',
      'notes': <String>[
        'This artifact records supervisor-side learning feedback derived from the completed reality-model learning outcome.',
        'It is advisory only and does not bypass human review or governance.',
      ],
    };
    File(jsonPath).writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(payload),
      flush: true,
    );
    File(readmePath).writeAsStringSync(
      _buildSupervisorLearningFeedbackReadme(payload),
      flush: true,
    );
    return (jsonPath: jsonPath, readmePath: readmePath);
  }

  ({String jsonPath, String readmePath}) _writeHierarchyDomainDeltaArtifact({
    required ExternalSourceDescriptor source,
    required String targetId,
    required String bundleRoot,
    required String sanitizedTargetId,
    required String? learningOutcomePath,
    required Map<String, dynamic>? learningOutcomePayload,
    required DateTime executedAt,
    required Map<String, dynamic> temporalLineage,
  }) {
    final basename =
        'hierarchy_domain_delta_${sanitizedTargetId.isEmpty ? 'target' : sanitizedTargetId}';
    final jsonPath = path.join(bundleRoot, '$basename.json');
    final readmePath = path.join(bundleRoot, '${basename.toUpperCase()}.md');
    final domainId = _extractHierarchyDomainId(targetId);
    final learningDeltas = List<String>.from(
      learningOutcomePayload?['learningDeltas'] ?? const <String>[],
    ).where((delta) => delta.contains('`$domainId`')).toList(growable: false);
    final downstreamConsumer = _writeDomainConsumerArtifact(
      source: source,
      domainId: domainId,
      bundleRoot: bundleRoot,
      learningOutcomePath: learningOutcomePath,
      learningOutcomePayload: learningOutcomePayload,
      executedAt: executedAt,
      temporalLineage: temporalLineage,
    );
    final payload = <String, dynamic>{
      'sourceId': source.id,
      'targetId': targetId,
      'domainId': domainId,
      'generatedAt': executedAt.toIso8601String(),
      'status': 'executed_local_governed_domain_delta',
      'environmentId': learningOutcomePayload?['environmentId'] ??
          source.metadata['environmentId'] ??
          'unknown_environment',
      'cityCode': learningOutcomePayload?['cityCode'] ?? source.cityCode,
      'learningOutcomeJsonPath': learningOutcomePath,
      'learningPathway': learningOutcomePayload?['learningPathway'],
      'temporalLineage': temporalLineage,
      'requestCount': _readDomainRequestCount(
        learningOutcomePayload?['domainCoverage'],
        domainId,
      ),
      'recommendationCount':
          (learningOutcomePayload?['recommendationCount'] as num?)?.toInt() ??
              0,
      'averageConfidence': learningOutcomePayload?['averageConfidence'],
      'summary':
          'Governed lower-tier `$domainId` propagation is now derived from the completed reality-model learning outcome instead of the raw simulation artifacts.',
      'boundedUse':
          'Apply this only as a domain-scoped delta for `$domainId` consumers after operator approval; do not treat it as a full-model retraining shortcut.',
      'learningDeltas': learningDeltas,
      if (downstreamConsumer != null)
        'downstreamConsumer': <String, dynamic>{
          'status': downstreamConsumer.status,
          'consumerId': downstreamConsumer.consumerId,
          'domainId': downstreamConsumer.domainId,
          'summary': downstreamConsumer.summary,
          'boundedUse': downstreamConsumer.boundedUse,
          'targetedSystems': downstreamConsumer.targetedSystems,
          'jsonPath': downstreamConsumer.jsonPath,
          if (_serializeTemporalLineageSummary(
            downstreamConsumer.temporalLineage,
          )
              case final lineage?)
            'temporalLineage': lineage,
        },
      'notes': <String>[
        'This artifact captures a governed hierarchy/domain delta derived from the completed reality-model learning outcome.',
        'Lower-tier consumers should use it as a bounded domain delta, not as direct raw simulation training input.',
      ],
    };
    File(jsonPath).writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(payload),
      flush: true,
    );
    File(readmePath).writeAsStringSync(
      _buildHierarchyDomainDeltaReadme(payload),
      flush: true,
    );
    return (jsonPath: jsonPath, readmePath: readmePath);
  }

  SignatureHealthDomainConsumerSummary? _writeDomainConsumerArtifact({
    required ExternalSourceDescriptor source,
    required String domainId,
    required String bundleRoot,
    required String? learningOutcomePath,
    required Map<String, dynamic>? learningOutcomePayload,
    required DateTime executedAt,
    required Map<String, dynamic> temporalLineage,
  }) {
    final consumerSpec = _domainConsumerSpecFor(domainId);
    if (consumerSpec == null) {
      return null;
    }
    final basename = 'domain_consumer_state_${domainId.toLowerCase()}';
    final jsonPath = path.join(bundleRoot, '$basename.json');
    final readmePath = path.join(bundleRoot, '${basename.toUpperCase()}.md');
    final payload = <String, dynamic>{
      'sourceId': source.id,
      'domainId': domainId,
      'generatedAt': executedAt.toIso8601String(),
      'status': 'executed_local_governed_domain_consumer_refresh',
      'consumerId': consumerSpec.consumerId,
      'environmentId':
          source.metadata['environmentId'] ?? 'unknown_environment',
      'cityCode': source.cityCode,
      'learningOutcomeJsonPath': learningOutcomePath,
      'temporalLineage': temporalLineage,
      'requestCount': _readDomainRequestCount(
        learningOutcomePayload?['domainCoverage'],
        domainId,
      ),
      'recommendationCount':
          (learningOutcomePayload?['recommendationCount'] as num?)?.toInt() ??
              0,
      'averageConfidence':
          (learningOutcomePayload?['averageConfidence'] as num?)?.toDouble(),
      'summary': consumerSpec.summary,
      'boundedUse': consumerSpec.boundedUse,
      'targetedSystems': consumerSpec.targetedSystems,
      'notes': <String>[
        'This artifact records the first concrete downstream consumer lane that should ingest the governed `$domainId` hierarchy delta.',
        'It remains bounded to the named lower-tier systems and does not authorize broader direct retraining.',
      ],
    };
    File(jsonPath).writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(payload),
      flush: true,
    );
    File(readmePath).writeAsStringSync(
      _buildDomainConsumerReadme(payload),
      flush: true,
    );
    final stateService = _governedDomainConsumerStateService;
    if (stateService != null) {
      unawaited(stateService.upsertState(
        GovernedDomainConsumerState(
          sourceId: source.id,
          domainId: domainId,
          consumerId: consumerSpec.consumerId,
          environmentId:
              payload['environmentId']?.toString() ?? 'unknown_environment',
          cityCode: source.cityCode,
          generatedAt: executedAt,
          status: payload['status']!.toString(),
          summary: payload['summary']!.toString(),
          boundedUse: payload['boundedUse']!.toString(),
          targetedSystems:
              List<String>.from(payload['targetedSystems'] as List),
          learningOutcomeJsonPath: learningOutcomePath,
          requestCount: (payload['requestCount'] as num?)?.toInt() ?? 0,
          recommendationCount:
              (payload['recommendationCount'] as num?)?.toInt() ?? 0,
          averageConfidence: (payload['averageConfidence'] as num?)?.toDouble(),
          jsonPath: jsonPath,
          sourceCreatedAt: _buildTemporalLineageSummary(
            payload['temporalLineage'],
          )?.sourceCreatedAt,
          sourceUpdatedAt: _buildTemporalLineageSummary(
            payload['temporalLineage'],
          )?.sourceUpdatedAt,
          sourceLastSyncedAt: _buildTemporalLineageSummary(
            payload['temporalLineage'],
          )?.sourceLastSyncedAt,
          originOccurredAt: _buildTemporalLineageSummary(
            payload['temporalLineage'],
          )?.originOccurredAt,
          localStateCapturedAt: _buildTemporalLineageSummary(
            payload['temporalLineage'],
          )?.localStateCapturedAt,
          reviewQueuedAt: _buildTemporalLineageSummary(
            payload['temporalLineage'],
          )?.reviewQueuedAt,
          reviewResolvedAt: _buildTemporalLineageSummary(
            payload['temporalLineage'],
          )?.reviewResolvedAt,
          learningQueuedAt: _buildTemporalLineageSummary(
            payload['temporalLineage'],
          )?.learningQueuedAt,
          learningIntegratedAt: _buildTemporalLineageSummary(
            payload['temporalLineage'],
          )?.learningIntegratedAt,
          propagationPreparedAt: _buildTemporalLineageSummary(
            payload['temporalLineage'],
          )?.propagationPreparedAt,
          propagationResolvedAt: _buildTemporalLineageSummary(
            payload['temporalLineage'],
          )?.propagationResolvedAt,
          artifactGeneratedAt: _buildTemporalLineageSummary(
            payload['temporalLineage'],
          )?.artifactGeneratedAt,
          kernelExchangePhase: _buildTemporalLineageSummary(
            payload['temporalLineage'],
          )?.kernelExchangePhase,
        ),
      ));
    }
    return SignatureHealthDomainConsumerSummary(
      status: payload['status']!.toString(),
      consumerId: payload['consumerId']!.toString(),
      domainId: domainId,
      summary: payload['summary']!.toString(),
      boundedUse: payload['boundedUse']!.toString(),
      targetedSystems: List<String>.from(payload['targetedSystems'] as List),
      jsonPath: jsonPath,
      temporalLineage: _buildTemporalLineageSummary(payload['temporalLineage']),
    );
  }

  ({
    String consumerId,
    String summary,
    String boundedUse,
    List<String> targetedSystems
  })? _domainConsumerSpecFor(String domainId) {
    switch (domainId) {
      case 'locality':
        return (
          consumerId: 'locality_intelligence_lane',
          summary:
              'Locality hierarchy deltas should now refresh bounded locality intelligence consumers so governed reality-model learning can improve locality priors, neighborhood reasoning, and locality-facing explanations.',
          boundedUse:
              'Use only for locality-scoped reasoning, prioritization, and explanation consumers; do not turn this into a shortcut for broader citywide retraining.',
          targetedSystems: <String>[
            'locality_priors',
            'locality_reasoning',
            'locality_explanation_surfaces',
          ],
        );
      case 'event':
        return (
          consumerId: 'event_intelligence_lane',
          summary:
              'Event hierarchy deltas should now refresh bounded event intelligence consumers so governed reality-model learning can improve event priors, timing reasoning, and event-facing explanations.',
          boundedUse:
              'Use only for event-scoped timing, ranking, and explanation consumers; do not generalize this into broad world-model retraining.',
          targetedSystems: <String>[
            'event_priors',
            'event_timing_reasoning',
            'event_explanation_surfaces',
          ],
        );
      case 'community':
        return (
          consumerId: 'community_coordination_lane',
          summary:
              'Community hierarchy deltas should now refresh bounded community coordination consumers so governed reality-model learning can improve community priors, moderation context, and collaboration guidance.',
          boundedUse:
              'Use only for community-scoped coordination, moderation-context, and explanation consumers; do not generalize this into broad social-policy retraining.',
          targetedSystems: <String>[
            'community_coordination_priors',
            'community_moderation_context',
            'community_explanation_surfaces',
          ],
        );
      case 'place':
        return (
          consumerId: 'place_intelligence_lane',
          summary:
              'Place hierarchy deltas should now refresh bounded place intelligence consumers so governed reality-model learning can improve place priors, availability reasoning, and place-facing explanations.',
          boundedUse:
              'Use only for place-scoped reasoning, availability, and explanation consumers; do not treat this as a shortcut for broader locality or citywide retraining.',
          targetedSystems: <String>[
            'place_priors',
            'place_availability_reasoning',
            'place_explanation_surfaces',
          ],
        );
      case 'business':
        return (
          consumerId: 'business_intelligence_lane',
          summary:
              'Business hierarchy deltas should now refresh bounded business intelligence consumers so governed reality-model learning can improve business-facing priors, explanations, and account guidance.',
          boundedUse:
              'Use only for business-scoped recommendation, explanation, and account-support consumers; do not generalize this into broader commercial policy or citywide retraining.',
          targetedSystems: <String>[
            'business_account_guidance',
            'business_recommendation_priors',
            'business_explanation_surfaces',
          ],
        );
      case 'list':
        return (
          consumerId: 'list_curation_lane',
          summary:
              'List hierarchy deltas should now refresh bounded list curation consumers so governed reality-model learning can improve ranking, explanation, and watchlist-priority behavior.',
          boundedUse:
              'Use only for list-scoped curation, ranking, and explanation consumers; do not treat this as a shortcut for retraining unrelated discovery or world-model systems.',
          targetedSystems: <String>[
            'list_curation_priors',
            'list_explanation_surfaces',
            'watchlist_priority_refresh',
          ],
        );
      case 'mobility':
        return (
          consumerId: 'mobility_guidance_lane',
          summary:
              'Mobility hierarchy deltas should now refresh bounded mobility guidance consumers so governed reality-model learning can improve route priors, corridor reasoning, and mobility-facing explanations.',
          boundedUse:
              'Use only for mobility-scoped guidance, detour reasoning, and explanation consumers; do not treat this as broad retraining of unrelated locality or event systems.',
          targetedSystems: <String>[
            'mobility_route_priors',
            'mobility_corridor_reasoning',
            'mobility_explanation_surfaces',
          ],
        );
      case 'venue':
        return (
          consumerId: 'venue_intelligence_lane',
          summary:
              'Venue hierarchy deltas should now refresh bounded venue intelligence consumers so governed reality-model learning can improve venue priors, availability reasoning, and venue-facing explanations.',
          boundedUse:
              'Use only for venue-scoped availability, occupancy, and explanation consumers; do not generalize this into broader place or business retraining.',
          targetedSystems: <String>[
            'venue_priors',
            'venue_availability_reasoning',
            'venue_explanation_surfaces',
          ],
        );
      default:
        return null;
    }
  }

  ({String jsonPath, String readmePath})
      _writePersonalAgentPersonalizationArtifact({
    required ExternalSourceDescriptor source,
    required String targetId,
    required String bundleRoot,
    required String sanitizedTargetId,
    required String? learningOutcomePath,
    required Map<String, dynamic>? learningOutcomePayload,
    required DateTime executedAt,
    required Map<String, dynamic> temporalLineage,
  }) {
    final basename =
        'personal_agent_personalization_delta_${sanitizedTargetId.isEmpty ? 'target' : sanitizedTargetId}';
    final jsonPath = path.join(bundleRoot, '$basename.json');
    final readmePath = path.join(bundleRoot, '${basename.toUpperCase()}.md');
    final domainId = _extractPersonalAgentDomainId(targetId);
    final payload = <String, dynamic>{
      'sourceId': source.id,
      'targetId': targetId,
      'domainId': domainId,
      'generatedAt': executedAt.toIso8601String(),
      'status': 'executed_local_governed_personalization_delta',
      'environmentId': learningOutcomePayload?['environmentId'] ??
          source.metadata['environmentId'] ??
          'unknown_environment',
      'cityCode': learningOutcomePayload?['cityCode'] ?? source.cityCode,
      'learningOutcomeJsonPath': learningOutcomePath,
      'learningPathway': learningOutcomePayload?['learningPathway'],
      'temporalLineage': temporalLineage,
      'requestCount': _readDomainRequestCount(
        learningOutcomePayload?['domainCoverage'],
        domainId,
      ),
      'recommendationCount':
          (learningOutcomePayload?['recommendationCount'] as num?)?.toInt() ??
              0,
      'averageConfidence': learningOutcomePayload?['averageConfidence'],
      'summary':
          'The personal agent may now personalize the governed `$domainId` knowledge that was synthesized by the hierarchy above, rather than learning directly from the raw simulation.',
      'personalizationMode':
          'final_contextualization_after_hierarchy_synthesis',
      'boundedUse':
          'Use this only as the final personalized form of already-governed `$domainId` knowledge for the person; do not bypass the reality model or the hierarchy synthesis chain.',
      'notes': <String>[
        'This artifact exists only after the matching hierarchy domain delta has been approved and executed.',
        'It represents the final personalization layer, not a parallel direct-training lane.',
      ],
    };
    File(jsonPath).writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(payload),
      flush: true,
    );
    File(readmePath).writeAsStringSync(
      _buildPersonalAgentPersonalizationReadme(payload),
      flush: true,
    );
    return (jsonPath: jsonPath, readmePath: readmePath);
  }

  String _deriveSupervisorRecommendation(
    Map<String, dynamic>? learningOutcomePayload,
  ) {
    final status = learningOutcomePayload?['status']?.toString() ?? 'unknown';
    final averageConfidence =
        (learningOutcomePayload?['averageConfidence'] as num?)?.toDouble();
    if (status != 'completed') {
      return 'hold_for_operator_review';
    }
    if (averageConfidence != null && averageConfidence >= 0.8) {
      return 'prefer_similar_reality_model_learning_candidates';
    }
    if (averageConfidence != null && averageConfidence >= 0.6) {
      return 'allow_bounded_retry_with_operator_visibility';
    }
    return 'review_before_similar_candidate_scheduling';
  }

  String? _isoString(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value.toUtc().toIso8601String();
    }
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  Map<String, dynamic> _buildTemporalLineagePayload({
    ExternalSourceDescriptor? source,
    OrganizerReviewItem? reviewItem,
    Map<String, dynamic>? existing,
    DateTime? originOccurredAt,
    DateTime? localStateCapturedAt,
    DateTime? reviewQueuedAt,
    DateTime? reviewResolvedAt,
    DateTime? learningQueuedAt,
    DateTime? learningIntegratedAt,
    DateTime? propagationPreparedAt,
    DateTime? propagationResolvedAt,
    DateTime? artifactGeneratedAt,
    String? kernelExchangePhase,
  }) {
    final lineage = <String, dynamic>{};
    if (source != null) {
      final sourceCreatedAt = _isoString(source.createdAt);
      if (sourceCreatedAt != null) {
        lineage['sourceCreatedAt'] = sourceCreatedAt;
      }
      final sourceUpdatedAt = _isoString(source.updatedAt);
      if (sourceUpdatedAt != null) {
        lineage['sourceUpdatedAt'] = sourceUpdatedAt;
      }
      final sourceLastSyncedAt = _isoString(source.lastSyncedAt);
      if (sourceLastSyncedAt != null) {
        lineage['sourceLastSyncedAt'] = sourceLastSyncedAt;
      }
    }
    if (existing != null) {
      lineage.addAll(
        existing.map((key, value) => MapEntry(key.toString(), value)),
      );
    }
    if (_isoString(
      originOccurredAt ??
          reviewItem?.payload['originOccurredAt'] ??
          source?.metadata['originOccurredAt'] ??
          source?.metadata['eventOccurredAt'] ??
          reviewItem?.createdAt ??
          source?.createdAt,
    )
        case final value?) {
      lineage['originOccurredAt'] = value;
    }
    if (_isoString(
      localStateCapturedAt ??
          reviewItem?.payload['localStateCapturedAt'] ??
          source?.metadata['localStateCapturedAt'] ??
          source?.updatedAt,
    )
        case final value?) {
      lineage['localStateCapturedAt'] = value;
    }
    if (_isoString(reviewQueuedAt ?? reviewItem?.createdAt) case final value?) {
      lineage['reviewQueuedAt'] = value;
    }
    if (_isoString(reviewResolvedAt) case final value?) {
      lineage['reviewResolvedAt'] = value;
    }
    if (_isoString(learningQueuedAt) case final value?) {
      lineage['learningQueuedAt'] = value;
    }
    if (_isoString(learningIntegratedAt) case final value?) {
      lineage['learningIntegratedAt'] = value;
    }
    if (_isoString(propagationPreparedAt) case final value?) {
      lineage['propagationPreparedAt'] = value;
    }
    if (_isoString(propagationResolvedAt) case final value?) {
      lineage['propagationResolvedAt'] = value;
    }
    if (_isoString(artifactGeneratedAt) case final value?) {
      lineage['artifactGeneratedAt'] = value;
    }
    final effectivePhase = kernelExchangePhase ??
        existing?['kernelExchangePhase']?.toString() ??
        source?.metadata['kernelExchangePhase']?.toString();
    if (effectivePhase != null && effectivePhase.isNotEmpty) {
      lineage['kernelExchangePhase'] = effectivePhase;
    }
    return lineage;
  }

  SignatureHealthTemporalLineage? _buildTemporalLineageSummary(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final payload = Map<String, dynamic>.from(raw);
    DateTime? parse(String key) {
      final value = payload[key];
      if (value == null) {
        return null;
      }
      return DateTime.tryParse(value.toString())?.toUtc();
    }

    final lineage = SignatureHealthTemporalLineage(
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
      kernelExchangePhase: payload['kernelExchangePhase']?.toString(),
    );
    return lineage.hasAnyValue ? lineage : null;
  }

  Map<String, dynamic>? _serializeTemporalLineageSummary(
    SignatureHealthTemporalLineage? lineage,
  ) {
    if (lineage == null || !lineage.hasAnyValue) {
      return null;
    }
    return <String, dynamic>{
      if (_isoString(lineage.sourceCreatedAt) case final value?)
        'sourceCreatedAt': value,
      if (_isoString(lineage.sourceUpdatedAt) case final value?)
        'sourceUpdatedAt': value,
      if (_isoString(lineage.sourceLastSyncedAt) case final value?)
        'sourceLastSyncedAt': value,
      if (_isoString(lineage.originOccurredAt) case final value?)
        'originOccurredAt': value,
      if (_isoString(lineage.localStateCapturedAt) case final value?)
        'localStateCapturedAt': value,
      if (_isoString(lineage.reviewQueuedAt) case final value?)
        'reviewQueuedAt': value,
      if (_isoString(lineage.reviewResolvedAt) case final value?)
        'reviewResolvedAt': value,
      if (_isoString(lineage.learningQueuedAt) case final value?)
        'learningQueuedAt': value,
      if (_isoString(lineage.learningIntegratedAt) case final value?)
        'learningIntegratedAt': value,
      if (_isoString(lineage.propagationPreparedAt) case final value?)
        'propagationPreparedAt': value,
      if (_isoString(lineage.propagationResolvedAt) case final value?)
        'propagationResolvedAt': value,
      if (_isoString(lineage.artifactGeneratedAt) case final value?)
        'artifactGeneratedAt': value,
      if (lineage.kernelExchangePhase case final value?)
        'kernelExchangePhase': value,
    };
  }

  String _extractHierarchyDomainId(String targetId) {
    if (!targetId.startsWith('hierarchy:')) {
      return targetId;
    }
    final domainId = targetId.substring('hierarchy:'.length).trim();
    return domainId.isEmpty ? 'generic_runtime_agents' : domainId;
  }

  int _readDomainRequestCount(Object? domainCoverageValue, String domainId) {
    if (domainCoverageValue is! Map) {
      return 0;
    }
    final domainCoverage = Map<String, dynamic>.from(domainCoverageValue);
    return (domainCoverage[domainId] as num?)?.toInt() ?? 0;
  }

  String _extractPersonalAgentDomainId(String targetId) {
    if (!targetId.startsWith('personal_agent:')) {
      return targetId;
    }
    final domainId = targetId.substring('personal_agent:'.length).trim();
    return domainId.isEmpty ? 'generic_personal_agent' : domainId;
  }

  bool _isHierarchyTarget(String targetId) => targetId.startsWith('hierarchy:');

  bool _isPersonalAgentTargetUnlockedBy(
    Map<String, dynamic> target,
    String hierarchyTargetId,
  ) {
    final targetId = target['targetId']?.toString() ?? '';
    if (!targetId.startsWith('personal_agent:')) {
      return false;
    }
    final hierarchyDomainId = _extractHierarchyDomainId(hierarchyTargetId);
    final personalDomainId = _extractPersonalAgentDomainId(targetId);
    return hierarchyDomainId == personalDomainId;
  }

  String _buildAdminEvidenceRefreshReadme(Map<String, dynamic> payload) {
    final learningDeltas = List<String>.from(
      payload['learningDeltas'] ?? const <String>[],
    );
    final domainCoverage = Map<String, dynamic>.from(
      payload['domainCoverage'] ?? const <String, dynamic>{},
    );
    final lines = <String>[
      '# Admin Evidence Refresh Snapshot',
      '',
      '- Source: `${payload['sourceId'] ?? 'unknown'}`',
      '- Target: `${payload['targetId'] ?? 'unknown'}`',
      '- Status: `${payload['status'] ?? 'unknown'}`',
      '- Environment: `${payload['environmentId'] ?? 'unknown'}`',
      '- City code: `${payload['cityCode'] ?? 'unknown'}`',
      '- Learning outcome: `${payload['learningOutcomeJsonPath'] ?? 'missing'}`',
      '',
      payload['summary']?.toString() ?? 'No summary recorded.',
      '',
      '## Domain coverage',
      '',
      if (domainCoverage.isEmpty) '- none recorded',
      ...domainCoverage.entries.map(
        (entry) => '- `${entry.key}`: `${entry.value}` requests',
      ),
      '',
      '## Learning deltas',
      '',
      if (learningDeltas.isEmpty) '- none recorded',
      ...learningDeltas.map((entry) => '- $entry'),
    ];
    return lines.join('\n');
  }

  String _buildSupervisorLearningFeedbackReadme(Map<String, dynamic> payload) {
    final lines = <String>[
      '# Supervisor Learning Feedback State',
      '',
      '- Source: `${payload['sourceId'] ?? 'unknown'}`',
      '- Target: `${payload['targetId'] ?? 'unknown'}`',
      '- Status: `${payload['status'] ?? 'unknown'}`',
      '- Environment: `${payload['environmentId'] ?? 'unknown'}`',
      '- Learning outcome: `${payload['learningOutcomeJsonPath'] ?? 'missing'}`',
      '- Learning pathway: `${payload['learningPathway'] ?? 'unknown'}`',
      '- Outcome status: `${payload['outcomeStatus'] ?? 'unknown'}`',
      '- Request count: `${payload['requestCount'] ?? 0}`',
      '- Recommendation count: `${payload['recommendationCount'] ?? 0}`',
      if (payload['averageConfidence'] != null)
        '- Average confidence: `${payload['averageConfidence']}`',
      '- Bounded recommendation: `${payload['boundedRecommendation'] ?? 'unknown'}`',
      '',
      payload['feedbackSummary']?.toString() ??
          'No supervisor feedback summary recorded.',
    ];
    return lines.join('\n');
  }

  String _buildHierarchyDomainDeltaReadme(Map<String, dynamic> payload) {
    final learningDeltas = List<String>.from(
      payload['learningDeltas'] ?? const <String>[],
    );
    final lines = <String>[
      '# Hierarchy Domain Delta',
      '',
      '- Source: `${payload['sourceId'] ?? 'unknown'}`',
      '- Target: `${payload['targetId'] ?? 'unknown'}`',
      '- Domain: `${payload['domainId'] ?? 'unknown'}`',
      '- Status: `${payload['status'] ?? 'unknown'}`',
      '- Environment: `${payload['environmentId'] ?? 'unknown'}`',
      '- Learning outcome: `${payload['learningOutcomeJsonPath'] ?? 'missing'}`',
      '- Request count: `${payload['requestCount'] ?? 0}`',
      '- Recommendation count: `${payload['recommendationCount'] ?? 0}`',
      if (payload['averageConfidence'] != null)
        '- Average confidence: `${payload['averageConfidence']}`',
      '',
      payload['summary']?.toString() ?? 'No summary recorded.',
      '',
      '## Bounded use',
      '',
      payload['boundedUse']?.toString() ?? 'No bounded use recorded.',
      '',
      '## Learning deltas',
      '',
      if (learningDeltas.isEmpty) '- none recorded',
      ...learningDeltas.map((entry) => '- $entry'),
    ];
    return lines.join('\n');
  }

  String _buildPersonalAgentPersonalizationReadme(
      Map<String, dynamic> payload) {
    final lines = <String>[
      '# Personal Agent Personalization Delta',
      '',
      '- Source: `${payload['sourceId'] ?? 'unknown'}`',
      '- Target: `${payload['targetId'] ?? 'unknown'}`',
      '- Domain: `${payload['domainId'] ?? 'unknown'}`',
      '- Status: `${payload['status'] ?? 'unknown'}`',
      '- Environment: `${payload['environmentId'] ?? 'unknown'}`',
      '- Learning outcome: `${payload['learningOutcomeJsonPath'] ?? 'missing'}`',
      '- Personalization mode: `${payload['personalizationMode'] ?? 'unknown'}`',
      '- Request count: `${payload['requestCount'] ?? 0}`',
      '- Recommendation count: `${payload['recommendationCount'] ?? 0}`',
      if (payload['averageConfidence'] != null)
        '- Average confidence: `${payload['averageConfidence']}`',
      '',
      payload['summary']?.toString() ?? 'No summary recorded.',
      '',
      '## Bounded use',
      '',
      payload['boundedUse']?.toString() ?? 'No bounded use recorded.',
    ];
    return lines.join('\n');
  }

  String _buildDomainConsumerReadme(Map<String, dynamic> payload) {
    final targetedSystems = List<String>.from(
      payload['targetedSystems'] ?? const <String>[],
    );
    final lines = <String>[
      '# Domain Consumer Refresh',
      '',
      '- Source: `${payload['sourceId'] ?? 'unknown'}`',
      '- Domain: `${payload['domainId'] ?? 'unknown'}`',
      '- Consumer: `${payload['consumerId'] ?? 'unknown'}`',
      '- Status: `${payload['status'] ?? 'unknown'}`',
      '- Environment: `${payload['environmentId'] ?? 'unknown'}`',
      '- Learning outcome: `${payload['learningOutcomeJsonPath'] ?? 'missing'}`',
      '',
      payload['summary']?.toString() ?? 'No summary recorded.',
      '',
      '## Bounded use',
      '',
      payload['boundedUse']?.toString() ?? 'No bounded use recorded.',
      '',
      '## Targeted systems',
      '',
      if (targetedSystems.isEmpty) '- none recorded',
      ...targetedSystems.map((entry) => '- `$entry`'),
    ];
    return lines.join('\n');
  }

  _DownstreamPropagationLaneKind _resolvePropagationLaneKind(String targetId) {
    if (targetId.startsWith('admin:')) {
      return _DownstreamPropagationLaneKind.adminEvidenceRefresh;
    }
    if (targetId.startsWith('supervisor:')) {
      return _DownstreamPropagationLaneKind.supervisorLearningFeedback;
    }
    if (targetId.startsWith('hierarchy:')) {
      return _DownstreamPropagationLaneKind.hierarchyDomainDelta;
    }
    if (targetId.startsWith('personal_agent:')) {
      return _DownstreamPropagationLaneKind.personalAgentPersonalization;
    }
    return _DownstreamPropagationLaneKind.generic;
  }

  bool _isSimulationTrainingReview(OrganizerReviewItem reviewItem) {
    final status = reviewItem.payload['status']?.toString();
    return status == 'queued_for_deeper_training_intake_review' ||
        reviewItem.title.toLowerCase().contains('deeper training intake');
  }

  bool _isUpwardLearningReview(OrganizerReviewItem reviewItem) {
    final queueKind = reviewItem.payload['queueKind']?.toString();
    final direction = reviewItem.payload['learningDirection']?.toString();
    return queueKind == 'queued_for_upward_learning_review' ||
        direction == 'upward_personal_agent_to_reality_model';
  }

  bool _isFamilyRestageIntakeReview(OrganizerReviewItem reviewItem) {
    final status = reviewItem.payload['status']?.toString();
    return status == 'queued_for_family_restage_intake_review' ||
        reviewItem.title.toLowerCase().contains('family restage intake');
  }

  bool _isFamilyRestageFollowUpReview(OrganizerReviewItem reviewItem) {
    final status = reviewItem.payload['status']?.toString();
    return status == 'queued_for_family_restage_follow_up_review' ||
        reviewItem.title.toLowerCase().contains('family restage follow-up');
  }

  bool _isFamilyRestageResolutionReview(OrganizerReviewItem reviewItem) {
    final status = reviewItem.payload['status']?.toString();
    return status == 'queued_for_family_restage_resolution_review' ||
        reviewItem.title.toLowerCase().contains('family restage resolution');
  }

  bool _isFamilyRestageExecutionReview(OrganizerReviewItem reviewItem) {
    final status = reviewItem.payload['status']?.toString();
    return status == 'queued_for_family_restage_execution_review' ||
        reviewItem.title.toLowerCase().contains('family restage execution');
  }

  bool _isFamilyRestageApplicationReview(OrganizerReviewItem reviewItem) {
    final status = reviewItem.payload['status']?.toString();
    return status == 'queued_for_family_restage_application_review' ||
        reviewItem.title.toLowerCase().contains('family restage application');
  }

  bool _isFamilyRestageApplyReview(OrganizerReviewItem reviewItem) {
    final status = reviewItem.payload['status']?.toString();
    return status == 'queued_for_family_restage_apply_review' ||
        reviewItem.title.toLowerCase().contains('family restage apply');
  }

  bool _isFamilyRestageServedBasisUpdateReview(OrganizerReviewItem reviewItem) {
    final status = reviewItem.payload['status']?.toString();
    return status == 'queued_for_family_restage_served_basis_update_review' ||
        reviewItem.title.toLowerCase().contains(
              'family restage served-basis update',
            );
  }

  Future<void> _recordGovernanceOutcomeForGovernedLearningObservation({
    required ExternalSourceDescriptor source,
    OrganizerReviewItem? reviewItem,
    required GovernedLearningChatObservationGovernanceStatus governanceStatus,
    required DateTime recordedAt,
    required String governanceStage,
    required String governanceReason,
  }) async {
    final observationService = _userGovernedLearningChatObservationService;
    if (observationService == null) {
      return;
    }
    final envelopeId =
        reviewItem?.payload['governedLearningEnvelopeId']?.toString() ??
            source.metadata['governedLearningEnvelopeId']?.toString() ??
            _governedLearningEnvelopeIdFromSourceMetadata(source.metadata);
    if (envelopeId == null || envelopeId.isEmpty) {
      return;
    }
    await observationService.markLatestWithoutGovernanceAsGoverned(
      ownerUserId: source.ownerUserId,
      envelopeId: envelopeId,
      governanceStatus: governanceStatus,
      governanceUpdatedAtUtc: recordedAt,
      governanceStage: governanceStage,
      governanceReason: governanceReason,
    );
  }

  String? _governedLearningEnvelopeIdFromSourceMetadata(
    Map<String, dynamic> metadata,
  ) {
    final directEnvelopeId =
        metadata['governedLearningEnvelopeId']?.toString().trim();
    if (directEnvelopeId?.isNotEmpty ?? false) {
      return directEnvelopeId;
    }
    final rawEnvelope = metadata['governedLearningEnvelope'];
    if (rawEnvelope is Map) {
      final envelopeId = rawEnvelope['id']?.toString().trim();
      if (envelopeId?.isNotEmpty ?? false) {
        return envelopeId;
      }
    }
    return null;
  }

  Future<(String, String)> _resolveFamilyRestageIntakeReview({
    required OrganizerReviewItem reviewItem,
    required ExternalSourceDescriptor source,
    required SignatureHealthReviewResolution resolution,
    required DateTime resolvedAt,
  }) async {
    final sourceUrl = (source.sourceUrl ?? '').trim();
    final baseRoot = sourceUrl.isEmpty
        ? await _ensureLocalArtifactRoot(
            source,
            scopeFolder: 'family_restage_intake_bundles',
          )
        : path.dirname(sourceUrl);
    final outcomeJsonPath = path.join(
      baseRoot,
      resolution == SignatureHealthReviewResolution.approved
          ? 'family_restage_intake_resolution.approved.json'
          : 'family_restage_intake_resolution.held.json',
    );
    final outcomeReadmePath = path.join(
      baseRoot,
      resolution == SignatureHealthReviewResolution.approved
          ? 'FAMILY_RESTAGE_INTAKE_RESOLUTION_APPROVED_README.md'
          : 'FAMILY_RESTAGE_INTAKE_RESOLUTION_HELD_README.md',
    );
    final outcomeStatus = resolution == SignatureHealthReviewResolution.approved
        ? 'approved_for_bounded_family_restage_follow_up'
        : 'held_for_more_family_restage_evidence';
    final payload = <String, dynamic>{
      'sourceId': source.id,
      'reviewItemId': reviewItem.id,
      'resolvedAt': resolvedAt.toUtc().toIso8601String(),
      'status': outcomeStatus,
      'resolution': resolution.name,
      'environmentId': reviewItem.payload['environmentId'] ??
          source.metadata['environmentId'],
      'supportedPlaceRef': reviewItem.payload['supportedPlaceRef'] ??
          source.metadata['supportedPlaceRef'],
      'evidenceFamily': reviewItem.payload['evidenceFamily'] ??
          source.metadata['evidenceFamily'],
      'restageTarget': reviewItem.payload['restageTarget'] ??
          source.metadata['restageTarget'],
      'restageTargetSummary': reviewItem.payload['restageTargetSummary'] ??
          source.metadata['restageTargetSummary'],
      'policyAction':
          reviewItem.payload['policyAction'] ?? source.metadata['policyAction'],
      'policyActionSummary': reviewItem.payload['policyActionSummary'] ??
          source.metadata['policyActionSummary'],
      'servedBasisRef': reviewItem.payload['servedBasisRef'] ??
          source.metadata['servedBasisRef'],
      'cityPackStructuralRef': reviewItem.payload['cityPackStructuralRef'] ??
          source.metadata['cityPackStructuralRef'],
      'queueJsonPath': sourceUrl,
      'temporalLineage': _buildTemporalLineagePayload(
        source: source,
        reviewItem: reviewItem,
        reviewResolvedAt: resolvedAt,
        artifactGeneratedAt: resolvedAt,
        kernelExchangePhase:
            resolution == SignatureHealthReviewResolution.approved
                ? 'approved_family_restage_intake_review'
                : 'held_family_restage_intake_review',
      ),
      'notes': <String>[
        if (resolution == SignatureHealthReviewResolution.approved)
          'This family restage intake review was approved, so the bounded follow-up lane may collect fresher inputs for this evidence family.'
        else
          'This family restage intake review was held, so the family remains in watch posture until more evidence justifies another bounded intake review.',
        'This artifact records only the governed intake-review resolution; basis mutation still remains outside this resolution step.',
      ],
    };
    await File(outcomeJsonPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      flush: true,
    );
    final readme = <String>[
      '# Family Restage Intake Review Resolution',
      '',
      '- Source: `${source.id}`',
      '- Review item: `${reviewItem.id}`',
      '- Environment: `${payload['environmentId'] ?? 'unknown_environment'}`',
      '- Evidence family: `${payload['evidenceFamily'] ?? 'unknown'}`',
      '- Resolution: `${resolution.name}`',
      '- Status: `$outcomeStatus`',
      '- Queue artifact: `${sourceUrl.isEmpty ? 'missing' : sourceUrl}`',
      '',
      payload['restageTargetSummary']?.toString() ??
          'No restage target summary recorded.',
      '',
      payload['policyActionSummary']?.toString() ??
          'No policy action summary recorded.',
    ].join('\n');
    await File(outcomeReadmePath).writeAsString(readme, flush: true);
    return (outcomeJsonPath, outcomeReadmePath);
  }

  Future<(String, String)> _resolveFamilyRestageFollowUpReview({
    required OrganizerReviewItem reviewItem,
    required ExternalSourceDescriptor source,
    required SignatureHealthReviewResolution resolution,
    required DateTime resolvedAt,
  }) async {
    final sourceUrl = (source.sourceUrl ?? '').trim();
    final baseRoot = sourceUrl.isEmpty
        ? await _ensureLocalArtifactRoot(
            source,
            scopeFolder: 'family_restage_follow_up_bundles',
          )
        : path.dirname(sourceUrl);
    final outcomeJsonPath = path.join(
      baseRoot,
      resolution == SignatureHealthReviewResolution.approved
          ? 'family_restage_follow_up_resolution.approved.json'
          : 'family_restage_follow_up_resolution.held.json',
    );
    final outcomeReadmePath = path.join(
      baseRoot,
      resolution == SignatureHealthReviewResolution.approved
          ? 'FAMILY_RESTAGE_FOLLOW_UP_RESOLUTION_APPROVED_README.md'
          : 'FAMILY_RESTAGE_FOLLOW_UP_RESOLUTION_HELD_README.md',
    );
    final outcomeStatus = resolution == SignatureHealthReviewResolution.approved
        ? 'approved_for_bounded_family_restage_resolution'
        : 'held_for_more_family_follow_up_evidence';
    final payload = <String, dynamic>{
      'sourceId': source.id,
      'reviewItemId': reviewItem.id,
      'resolvedAt': resolvedAt.toUtc().toIso8601String(),
      'status': outcomeStatus,
      'resolution': resolution.name,
      'environmentId': reviewItem.payload['environmentId'] ??
          source.metadata['environmentId'],
      'supportedPlaceRef': reviewItem.payload['supportedPlaceRef'] ??
          source.metadata['supportedPlaceRef'],
      'evidenceFamily': reviewItem.payload['evidenceFamily'] ??
          source.metadata['evidenceFamily'],
      'restageTarget': reviewItem.payload['restageTarget'] ??
          source.metadata['restageTarget'],
      'restageTargetSummary': reviewItem.payload['restageTargetSummary'] ??
          source.metadata['restageTargetSummary'],
      'policyAction':
          reviewItem.payload['policyAction'] ?? source.metadata['policyAction'],
      'policyActionSummary': reviewItem.payload['policyActionSummary'] ??
          source.metadata['policyActionSummary'],
      'servedBasisRef': reviewItem.payload['servedBasisRef'] ??
          source.metadata['servedBasisRef'],
      'cityPackStructuralRef': reviewItem.payload['cityPackStructuralRef'] ??
          source.metadata['cityPackStructuralRef'],
      'intakeResolutionArtifactRef':
          reviewItem.payload['intakeResolutionArtifactRef'] ??
              source.metadata['intakeResolutionArtifactRef'],
      'queueJsonPath': sourceUrl,
      'temporalLineage': _buildTemporalLineagePayload(
        source: source,
        reviewItem: reviewItem,
        reviewResolvedAt: resolvedAt,
        artifactGeneratedAt: resolvedAt,
        kernelExchangePhase:
            resolution == SignatureHealthReviewResolution.approved
                ? 'approved_family_restage_follow_up_review'
                : 'held_family_restage_follow_up_review',
      ),
      'notes': <String>[
        if (resolution == SignatureHealthReviewResolution.approved)
          'This family restage follow-up review was approved, so the evidence family may proceed into its bounded governed restage-resolution lane.'
        else
          'This family restage follow-up review was held, so the family remains blocked pending more evidence before any bounded restage-resolution step.',
        'This artifact records only the governed follow-up review resolution; broad city-pack mutation still remains outside this step.',
      ],
    };
    await File(outcomeJsonPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      flush: true,
    );
    final readme = <String>[
      '# Family Restage Follow-up Review Resolution',
      '',
      '- Source: `${source.id}`',
      '- Review item: `${reviewItem.id}`',
      '- Environment: `${payload['environmentId'] ?? 'unknown_environment'}`',
      '- Evidence family: `${payload['evidenceFamily'] ?? 'unknown'}`',
      '- Resolution: `${resolution.name}`',
      '- Status: `$outcomeStatus`',
      '- Queue artifact: `${sourceUrl.isEmpty ? 'missing' : sourceUrl}`',
      '',
      payload['restageTargetSummary']?.toString() ??
          'No restage target summary recorded.',
      '',
      payload['policyActionSummary']?.toString() ??
          'No policy-action summary recorded.',
      '',
      if ((payload['intakeResolutionArtifactRef'] ?? '').toString().isNotEmpty)
        '- Intake resolution artifact: `${payload['intakeResolutionArtifactRef']}`',
      '',
      'This artifact captures the bounded governed follow-up decision only.',
    ].join('\n');
    await File(outcomeReadmePath).writeAsString(readme, flush: true);
    return (outcomeJsonPath, outcomeReadmePath);
  }

  Future<(String, String)> _resolveFamilyRestageResolutionReview({
    required OrganizerReviewItem reviewItem,
    required ExternalSourceDescriptor source,
    required SignatureHealthReviewResolution resolution,
    required DateTime resolvedAt,
  }) async {
    final sourceUrl = (source.sourceUrl ?? '').trim();
    final baseRoot = sourceUrl.isEmpty
        ? await _ensureLocalArtifactRoot(
            source,
            scopeFolder: 'family_restage_resolution_bundles',
          )
        : path.dirname(sourceUrl);
    final outcomeJsonPath = path.join(
      baseRoot,
      resolution == SignatureHealthReviewResolution.approved
          ? 'family_restage_resolution.approved.json'
          : 'family_restage_resolution.held.json',
    );
    final outcomeReadmePath = path.join(
      baseRoot,
      resolution == SignatureHealthReviewResolution.approved
          ? 'FAMILY_RESTAGE_RESOLUTION_APPROVED_README.md'
          : 'FAMILY_RESTAGE_RESOLUTION_HELD_README.md',
    );
    final outcomeStatus = resolution == SignatureHealthReviewResolution.approved
        ? 'approved_for_bounded_family_restage_execution'
        : 'held_for_more_family_restage_resolution_evidence';
    final payload = <String, dynamic>{
      'sourceId': source.id,
      'reviewItemId': reviewItem.id,
      'resolvedAt': resolvedAt.toUtc().toIso8601String(),
      'status': outcomeStatus,
      'resolution': resolution.name,
      'environmentId': reviewItem.payload['environmentId'] ??
          source.metadata['environmentId'],
      'supportedPlaceRef': reviewItem.payload['supportedPlaceRef'] ??
          source.metadata['supportedPlaceRef'],
      'evidenceFamily': reviewItem.payload['evidenceFamily'] ??
          source.metadata['evidenceFamily'],
      'restageTarget': reviewItem.payload['restageTarget'] ??
          source.metadata['restageTarget'],
      'restageTargetSummary': reviewItem.payload['restageTargetSummary'] ??
          source.metadata['restageTargetSummary'],
      'policyAction':
          reviewItem.payload['policyAction'] ?? source.metadata['policyAction'],
      'policyActionSummary': reviewItem.payload['policyActionSummary'] ??
          source.metadata['policyActionSummary'],
      'servedBasisRef': reviewItem.payload['servedBasisRef'] ??
          source.metadata['servedBasisRef'],
      'cityPackStructuralRef': reviewItem.payload['cityPackStructuralRef'] ??
          source.metadata['cityPackStructuralRef'],
      'followUpResolutionArtifactRef':
          reviewItem.payload['followUpResolutionArtifactRef'] ??
              source.metadata['followUpResolutionArtifactRef'],
      'queueJsonPath': sourceUrl,
      'temporalLineage': _buildTemporalLineagePayload(
        source: source,
        reviewItem: reviewItem,
        reviewResolvedAt: resolvedAt,
        artifactGeneratedAt: resolvedAt,
        kernelExchangePhase:
            resolution == SignatureHealthReviewResolution.approved
                ? 'approved_family_restage_resolution_review'
                : 'held_family_restage_resolution_review',
      ),
      'notes': <String>[
        if (resolution == SignatureHealthReviewResolution.approved)
          'This family restage resolution review was approved, so the family may proceed into its next bounded restage-execution lane.'
        else
          'This family restage resolution review was held, so the family remains blocked pending more evidence before any bounded restage-execution step.',
        'This artifact records only the governed resolution-review outcome; broad city-pack mutation still remains outside this step.',
      ],
    };
    await File(outcomeJsonPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      flush: true,
    );
    final readme = <String>[
      '# Family Restage Resolution Review Outcome',
      '',
      '- Source: `${source.id}`',
      '- Review item: `${reviewItem.id}`',
      '- Environment: `${payload['environmentId'] ?? 'unknown_environment'}`',
      '- Evidence family: `${payload['evidenceFamily'] ?? 'unknown'}`',
      '- Resolution: `${resolution.name}`',
      '- Status: `$outcomeStatus`',
      '- Queue artifact: `${sourceUrl.isEmpty ? 'missing' : sourceUrl}`',
      '',
      payload['restageTargetSummary']?.toString() ??
          'No restage target summary recorded.',
      '',
      payload['policyActionSummary']?.toString() ??
          'No policy-action summary recorded.',
      '',
      if ((payload['followUpResolutionArtifactRef'] ?? '')
          .toString()
          .isNotEmpty)
        '- Follow-up resolution artifact: `${payload['followUpResolutionArtifactRef']}`',
      '',
      'This artifact captures the bounded governed resolution-review decision only.',
    ].join('\n');
    await File(outcomeReadmePath).writeAsString(readme, flush: true);
    return (outcomeJsonPath, outcomeReadmePath);
  }

  Future<(String, String)> _resolveFamilyRestageExecutionReview({
    required OrganizerReviewItem reviewItem,
    required ExternalSourceDescriptor source,
    required SignatureHealthReviewResolution resolution,
    required DateTime resolvedAt,
  }) async {
    final sourceUrl = (source.sourceUrl ?? '').trim();
    final baseRoot = sourceUrl.isEmpty
        ? await _ensureLocalArtifactRoot(
            source,
            scopeFolder: 'family_restage_execution_bundles',
          )
        : path.dirname(sourceUrl);
    final outcomeJsonPath = path.join(
      baseRoot,
      resolution == SignatureHealthReviewResolution.approved
          ? 'family_restage_execution.approved.json'
          : 'family_restage_execution.held.json',
    );
    final outcomeReadmePath = path.join(
      baseRoot,
      resolution == SignatureHealthReviewResolution.approved
          ? 'FAMILY_RESTAGE_EXECUTION_APPROVED_README.md'
          : 'FAMILY_RESTAGE_EXECUTION_HELD_README.md',
    );
    final outcomeStatus = resolution == SignatureHealthReviewResolution.approved
        ? 'approved_for_bounded_family_restage_application'
        : 'held_for_more_family_restage_execution_evidence';
    final payload = <String, dynamic>{
      'sourceId': source.id,
      'reviewItemId': reviewItem.id,
      'resolvedAt': resolvedAt.toUtc().toIso8601String(),
      'status': outcomeStatus,
      'resolution': resolution.name,
      'environmentId': reviewItem.payload['environmentId'] ??
          source.metadata['environmentId'],
      'supportedPlaceRef': reviewItem.payload['supportedPlaceRef'] ??
          source.metadata['supportedPlaceRef'],
      'evidenceFamily': reviewItem.payload['evidenceFamily'] ??
          source.metadata['evidenceFamily'],
      'restageTarget': reviewItem.payload['restageTarget'] ??
          source.metadata['restageTarget'],
      'restageTargetSummary': reviewItem.payload['restageTargetSummary'] ??
          source.metadata['restageTargetSummary'],
      'policyAction':
          reviewItem.payload['policyAction'] ?? source.metadata['policyAction'],
      'policyActionSummary': reviewItem.payload['policyActionSummary'] ??
          source.metadata['policyActionSummary'],
      'servedBasisRef': reviewItem.payload['servedBasisRef'] ??
          source.metadata['servedBasisRef'],
      'cityPackStructuralRef': reviewItem.payload['cityPackStructuralRef'] ??
          source.metadata['cityPackStructuralRef'],
      'resolutionReviewOutcomeArtifactRef':
          reviewItem.payload['resolutionReviewOutcomeArtifactRef'] ??
              source.metadata['resolutionReviewOutcomeArtifactRef'],
      'queueJsonPath': sourceUrl,
      'temporalLineage': _buildTemporalLineagePayload(
        source: source,
        reviewItem: reviewItem,
        reviewResolvedAt: resolvedAt,
        artifactGeneratedAt: resolvedAt,
        kernelExchangePhase:
            resolution == SignatureHealthReviewResolution.approved
                ? 'approved_family_restage_execution_review'
                : 'held_family_restage_execution_review',
      ),
      'notes': <String>[
        if (resolution == SignatureHealthReviewResolution.approved)
          'This family restage execution review was approved, so the family may proceed into its bounded family-restage application posture.'
        else
          'This family restage execution review was held, so the family remains blocked pending more evidence before any bounded family-restage application step.',
        'This artifact records only the governed execution-review outcome; broad city-pack mutation still remains outside this step.',
      ],
    };
    await File(outcomeJsonPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      flush: true,
    );
    final readme = <String>[
      '# Family Restage Execution Review Outcome',
      '',
      '- Source: `${source.id}`',
      '- Review item: `${reviewItem.id}`',
      '- Environment: `${payload['environmentId'] ?? 'unknown_environment'}`',
      '- Evidence family: `${payload['evidenceFamily'] ?? 'unknown'}`',
      '- Resolution: `${resolution.name}`',
      '- Status: `$outcomeStatus`',
      '- Queue artifact: `${sourceUrl.isEmpty ? 'missing' : sourceUrl}`',
      '',
      payload['restageTargetSummary']?.toString() ??
          'No restage target summary recorded.',
      '',
      payload['policyActionSummary']?.toString() ??
          'No policy-action summary recorded.',
      '',
      if ((payload['resolutionReviewOutcomeArtifactRef'] ?? '')
          .toString()
          .isNotEmpty)
        '- Resolution-review outcome artifact: `${payload['resolutionReviewOutcomeArtifactRef']}`',
      '',
      'This artifact captures the bounded governed execution-review decision only.',
    ].join('\n');
    await File(outcomeReadmePath).writeAsString(readme, flush: true);
    return (outcomeJsonPath, outcomeReadmePath);
  }

  Future<(String, String)> _resolveFamilyRestageApplicationReview({
    required OrganizerReviewItem reviewItem,
    required ExternalSourceDescriptor source,
    required SignatureHealthReviewResolution resolution,
    required DateTime resolvedAt,
  }) async {
    final sourceUrl = (source.sourceUrl ?? '').trim();
    final baseRoot = sourceUrl.isEmpty
        ? await _ensureLocalArtifactRoot(
            source,
            scopeFolder: 'family_restage_application_bundles',
          )
        : path.dirname(sourceUrl);
    final outcomeJsonPath = path.join(
      baseRoot,
      resolution == SignatureHealthReviewResolution.approved
          ? 'family_restage_application.approved.json'
          : 'family_restage_application.held.json',
    );
    final outcomeReadmePath = path.join(
      baseRoot,
      resolution == SignatureHealthReviewResolution.approved
          ? 'FAMILY_RESTAGE_APPLICATION_APPROVED_README.md'
          : 'FAMILY_RESTAGE_APPLICATION_HELD_README.md',
    );
    final outcomeStatus = resolution == SignatureHealthReviewResolution.approved
        ? 'approved_for_bounded_family_restage_apply_to_served_basis'
        : 'held_for_more_family_restage_application_evidence';
    final payload = <String, dynamic>{
      'sourceId': source.id,
      'reviewItemId': reviewItem.id,
      'resolvedAt': resolvedAt.toUtc().toIso8601String(),
      'status': outcomeStatus,
      'resolution': resolution.name,
      'environmentId': reviewItem.payload['environmentId'] ??
          source.metadata['environmentId'],
      'supportedPlaceRef': reviewItem.payload['supportedPlaceRef'] ??
          source.metadata['supportedPlaceRef'],
      'evidenceFamily': reviewItem.payload['evidenceFamily'] ??
          source.metadata['evidenceFamily'],
      'restageTarget': reviewItem.payload['restageTarget'] ??
          source.metadata['restageTarget'],
      'restageTargetSummary': reviewItem.payload['restageTargetSummary'] ??
          source.metadata['restageTargetSummary'],
      'policyAction':
          reviewItem.payload['policyAction'] ?? source.metadata['policyAction'],
      'policyActionSummary': reviewItem.payload['policyActionSummary'] ??
          source.metadata['policyActionSummary'],
      'servedBasisRef': reviewItem.payload['servedBasisRef'] ??
          source.metadata['servedBasisRef'],
      'cityPackStructuralRef': reviewItem.payload['cityPackStructuralRef'] ??
          source.metadata['cityPackStructuralRef'],
      'executionReviewOutcomeArtifactRef':
          reviewItem.payload['executionReviewOutcomeArtifactRef'] ??
              source.metadata['executionReviewOutcomeArtifactRef'],
      'queueJsonPath': sourceUrl,
      'temporalLineage': _buildTemporalLineagePayload(
        source: source,
        reviewItem: reviewItem,
        reviewResolvedAt: resolvedAt,
        artifactGeneratedAt: resolvedAt,
        kernelExchangePhase:
            resolution == SignatureHealthReviewResolution.approved
                ? 'approved_family_restage_application_review'
                : 'held_family_restage_application_review',
      ),
      'notes': <String>[
        if (resolution == SignatureHealthReviewResolution.approved)
          'This family restage application review was approved, so the family may proceed into its bounded family-restage apply-to-served-basis posture.'
        else
          'This family restage application review was held, so the family remains blocked pending more evidence before any bounded family-restage application step.',
        'This artifact records only the governed application-review outcome; broad city-pack mutation still remains outside this step.',
      ],
    };
    await File(outcomeJsonPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      flush: true,
    );
    final readme = <String>[
      '# Family Restage Application Review Outcome',
      '',
      '- Source: `${source.id}`',
      '- Review item: `${reviewItem.id}`',
      '- Environment: `${payload['environmentId'] ?? 'unknown_environment'}`',
      '- Evidence family: `${payload['evidenceFamily'] ?? 'unknown'}`',
      '- Resolution: `${resolution.name}`',
      '- Status: `$outcomeStatus`',
      '- Queue artifact: `${sourceUrl.isEmpty ? 'missing' : sourceUrl}`',
      '',
      payload['restageTargetSummary']?.toString() ??
          'No restage target summary recorded.',
      '',
      payload['policyActionSummary']?.toString() ??
          'No policy-action summary recorded.',
      '',
      if ((payload['executionReviewOutcomeArtifactRef'] ?? '')
          .toString()
          .isNotEmpty)
        '- Execution-review outcome artifact: `${payload['executionReviewOutcomeArtifactRef']}`',
      '',
      'This artifact captures the bounded governed application-review decision only.',
    ].join('\n');
    await File(outcomeReadmePath).writeAsString(readme, flush: true);
    return (outcomeJsonPath, outcomeReadmePath);
  }

  Future<(String, String)> _resolveFamilyRestageApplyReview({
    required OrganizerReviewItem reviewItem,
    required ExternalSourceDescriptor source,
    required SignatureHealthReviewResolution resolution,
    required DateTime resolvedAt,
  }) async {
    final sourceUrl = (source.sourceUrl ?? '').trim();
    final baseRoot = sourceUrl.isEmpty
        ? await _ensureLocalArtifactRoot(
            source,
            scopeFolder: 'family_restage_apply_bundles',
          )
        : path.dirname(sourceUrl);
    final outcomeJsonPath = path.join(
      baseRoot,
      resolution == SignatureHealthReviewResolution.approved
          ? 'family_restage_apply.approved.json'
          : 'family_restage_apply.held.json',
    );
    final outcomeReadmePath = path.join(
      baseRoot,
      resolution == SignatureHealthReviewResolution.approved
          ? 'FAMILY_RESTAGE_APPLY_APPROVED_README.md'
          : 'FAMILY_RESTAGE_APPLY_HELD_README.md',
    );
    final outcomeStatus = resolution == SignatureHealthReviewResolution.approved
        ? 'approved_for_bounded_family_restage_served_basis_update'
        : 'held_for_more_family_restage_apply_evidence';
    final payload = <String, dynamic>{
      'sourceId': source.id,
      'reviewItemId': reviewItem.id,
      'resolvedAt': resolvedAt.toUtc().toIso8601String(),
      'status': outcomeStatus,
      'resolution': resolution.name,
      'environmentId': reviewItem.payload['environmentId'] ??
          source.metadata['environmentId'],
      'supportedPlaceRef': reviewItem.payload['supportedPlaceRef'] ??
          source.metadata['supportedPlaceRef'],
      'evidenceFamily': reviewItem.payload['evidenceFamily'] ??
          source.metadata['evidenceFamily'],
      'restageTarget': reviewItem.payload['restageTarget'] ??
          source.metadata['restageTarget'],
      'restageTargetSummary': reviewItem.payload['restageTargetSummary'] ??
          source.metadata['restageTargetSummary'],
      'policyAction':
          reviewItem.payload['policyAction'] ?? source.metadata['policyAction'],
      'policyActionSummary': reviewItem.payload['policyActionSummary'] ??
          source.metadata['policyActionSummary'],
      'servedBasisRef': reviewItem.payload['servedBasisRef'] ??
          source.metadata['servedBasisRef'],
      'cityPackStructuralRef': reviewItem.payload['cityPackStructuralRef'] ??
          source.metadata['cityPackStructuralRef'],
      'applicationReviewOutcomeArtifactRef':
          reviewItem.payload['applicationReviewOutcomeArtifactRef'] ??
              source.metadata['applicationReviewOutcomeArtifactRef'],
      'queueJsonPath': sourceUrl,
      'temporalLineage': _buildTemporalLineagePayload(
        source: source,
        reviewItem: reviewItem,
        reviewResolvedAt: resolvedAt,
        artifactGeneratedAt: resolvedAt,
        kernelExchangePhase:
            resolution == SignatureHealthReviewResolution.approved
                ? 'approved_family_restage_apply_review'
                : 'held_family_restage_apply_review',
      ),
      'notes': <String>[
        if (resolution == SignatureHealthReviewResolution.approved)
          'This family restage apply review was approved, so the family may proceed into its bounded served-basis update posture.'
        else
          'This family restage apply review was held, so the family remains blocked pending more evidence before any bounded served-basis update step.',
        'This artifact records only the governed apply-review outcome; served-basis mutation still remains outside this step.',
      ],
    };
    await File(outcomeJsonPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      flush: true,
    );
    final readme = <String>[
      '# Family Restage Apply Review Outcome',
      '',
      '- Source: `${source.id}`',
      '- Review item: `${reviewItem.id}`',
      '- Environment: `${payload['environmentId'] ?? 'unknown_environment'}`',
      '- Evidence family: `${payload['evidenceFamily'] ?? 'unknown'}`',
      '- Resolution: `${resolution.name}`',
      '- Status: `$outcomeStatus`',
      '- Queue artifact: `${sourceUrl.isEmpty ? 'missing' : sourceUrl}`',
      '',
      payload['restageTargetSummary']?.toString() ??
          'No restage target summary recorded.',
      '',
      payload['policyActionSummary']?.toString() ??
          'No policy-action summary recorded.',
      '',
      if ((payload['applicationReviewOutcomeArtifactRef'] ?? '')
          .toString()
          .isNotEmpty)
        '- Application-review outcome artifact: `${payload['applicationReviewOutcomeArtifactRef']}`',
      '',
      'This artifact captures the bounded governed apply-review decision only.',
    ].join('\n');
    await File(outcomeReadmePath).writeAsString(readme, flush: true);
    return (outcomeJsonPath, outcomeReadmePath);
  }

  Future<(String, String)> _resolveFamilyRestageServedBasisUpdateReview({
    required OrganizerReviewItem reviewItem,
    required ExternalSourceDescriptor source,
    required SignatureHealthReviewResolution resolution,
    required DateTime resolvedAt,
  }) async {
    final sourceUrl = (source.sourceUrl ?? '').trim();
    final baseRoot = sourceUrl.isEmpty
        ? await _ensureLocalArtifactRoot(
            source,
            scopeFolder: 'family_restage_served_basis_update_bundles',
          )
        : path.dirname(sourceUrl);
    final outcomeJsonPath = path.join(
      baseRoot,
      resolution == SignatureHealthReviewResolution.approved
          ? 'family_restage_served_basis_update.approved.json'
          : 'family_restage_served_basis_update.held.json',
    );
    final outcomeReadmePath = path.join(
      baseRoot,
      resolution == SignatureHealthReviewResolution.approved
          ? 'FAMILY_RESTAGE_SERVED_BASIS_UPDATE_APPROVED_README.md'
          : 'FAMILY_RESTAGE_SERVED_BASIS_UPDATE_HELD_README.md',
    );
    final outcomeStatus = resolution == SignatureHealthReviewResolution.approved
        ? 'approved_for_bounded_family_restage_served_basis_mutation'
        : 'held_for_more_family_restage_served_basis_update_evidence';
    final payload = <String, dynamic>{
      'sourceId': source.id,
      'reviewItemId': reviewItem.id,
      'resolvedAt': resolvedAt.toUtc().toIso8601String(),
      'status': outcomeStatus,
      'resolution': resolution.name,
      'environmentId': reviewItem.payload['environmentId'] ??
          source.metadata['environmentId'],
      'supportedPlaceRef': reviewItem.payload['supportedPlaceRef'] ??
          source.metadata['supportedPlaceRef'],
      'evidenceFamily': reviewItem.payload['evidenceFamily'] ??
          source.metadata['evidenceFamily'],
      'restageTarget': reviewItem.payload['restageTarget'] ??
          source.metadata['restageTarget'],
      'restageTargetSummary': reviewItem.payload['restageTargetSummary'] ??
          source.metadata['restageTargetSummary'],
      'policyAction':
          reviewItem.payload['policyAction'] ?? source.metadata['policyAction'],
      'policyActionSummary': reviewItem.payload['policyActionSummary'] ??
          source.metadata['policyActionSummary'],
      'servedBasisRef': reviewItem.payload['servedBasisRef'] ??
          source.metadata['servedBasisRef'],
      'cityPackStructuralRef': reviewItem.payload['cityPackStructuralRef'] ??
          source.metadata['cityPackStructuralRef'],
      'applyReviewOutcomeArtifactRef':
          reviewItem.payload['applyReviewOutcomeArtifactRef'] ??
              source.metadata['applyReviewOutcomeArtifactRef'],
      'latestStateRefreshReceiptRef':
          reviewItem.payload['latestStateRefreshReceiptRef'] ??
              source.metadata['latestStateRefreshReceiptRef'],
      'latestStateRevalidationReceiptRef':
          reviewItem.payload['latestStateRevalidationReceiptRef'] ??
              source.metadata['latestStateRevalidationReceiptRef'],
      'basisRefreshLineageRef': reviewItem.payload['basisRefreshLineageRef'] ??
          source.metadata['basisRefreshLineageRef'],
      'queueJsonPath': sourceUrl,
      'temporalLineage': _buildTemporalLineagePayload(
        source: source,
        reviewItem: reviewItem,
        reviewResolvedAt: resolvedAt,
        artifactGeneratedAt: resolvedAt,
        kernelExchangePhase:
            resolution == SignatureHealthReviewResolution.approved
                ? 'approved_family_restage_served_basis_update_review'
                : 'held_family_restage_served_basis_update_review',
      ),
      'notes': <String>[
        if (resolution == SignatureHealthReviewResolution.approved)
          'This family restage served-basis update review was approved, so the family may proceed into its bounded served-basis mutation posture.'
        else
          'This family restage served-basis update review was held, so the family remains blocked pending more evidence before any bounded served-basis mutation step.',
        'This artifact records only the governed served-basis update review outcome; direct served-basis mutation still remains outside this step.',
      ],
    };
    await File(outcomeJsonPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      flush: true,
    );
    final readme = <String>[
      '# Family Restage Served-Basis Update Review Outcome',
      '',
      '- Source: `${source.id}`',
      '- Review item: `${reviewItem.id}`',
      '- Environment: `${payload['environmentId'] ?? 'unknown_environment'}`',
      '- Evidence family: `${payload['evidenceFamily'] ?? 'unknown'}`',
      '- Resolution: `${resolution.name}`',
      '- Status: `$outcomeStatus`',
      '- Queue artifact: `${sourceUrl.isEmpty ? 'missing' : sourceUrl}`',
      '',
      payload['restageTargetSummary']?.toString() ??
          'No restage target summary recorded.',
      '',
      payload['policyActionSummary']?.toString() ??
          'No policy-action summary recorded.',
      '',
      if ((payload['applyReviewOutcomeArtifactRef'] ?? '')
          .toString()
          .isNotEmpty)
        '- Apply-review outcome artifact: `${payload['applyReviewOutcomeArtifactRef']}`',
      if ((payload['latestStateRefreshReceiptRef'] ?? '').toString().isNotEmpty)
        '- Latest-state refresh receipt: `${payload['latestStateRefreshReceiptRef']}`',
      if ((payload['latestStateRevalidationReceiptRef'] ?? '')
          .toString()
          .isNotEmpty)
        '- Latest-state revalidation receipt: `${payload['latestStateRevalidationReceiptRef']}`',
      if ((payload['basisRefreshLineageRef'] ?? '').toString().isNotEmpty)
        '- Basis refresh lineage: `${payload['basisRefreshLineageRef']}`',
      '',
      'This artifact captures the bounded governed served-basis update decision only.',
    ].join('\n');
    await File(outcomeReadmePath).writeAsString(readme, flush: true);
    return (outcomeJsonPath, outcomeReadmePath);
  }

  Future<String> _ensureLocalArtifactRoot(
    ExternalSourceDescriptor source, {
    required String scopeFolder,
  }) async {
    final existing = source.metadata['bundleRoot']?.toString();
    if (existing != null && existing.isNotEmpty) {
      final dir = Directory(existing);
      if (!dir.existsSync()) {
        await dir.create(recursive: true);
      }
      return dir.path;
    }
    final sanitizedSourceId = source.id
        .replaceAll(RegExp(r'[^a-zA-Z0-9._-]+'), '_')
        .replaceAll('__', '_');
    final root = path.join(
      Directory.systemTemp.path,
      'AVRAI',
      scopeFolder,
      sanitizedSourceId,
    );
    final dir = Directory(root);
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  Future<(String, String, String, String)> _stageAcceptedUpwardLearningHandoff({
    required OrganizerReviewItem reviewItem,
    required ExternalSourceDescriptor source,
    required DateTime resolvedAt,
  }) async {
    final bundleRoot = await _ensureLocalArtifactRoot(
      source,
      scopeFolder: 'upward_learning_bundles',
    );
    final hierarchyPlanJsonPath = path.join(
      bundleRoot,
      'upward_hierarchy_synthesis_plan.json',
    );
    final hierarchyPlanReadmePath = path.join(
      bundleRoot,
      'UPWARD_HIERARCHY_SYNTHESIS_PLAN_README.md',
    );
    final handoffJsonPath = path.join(
      bundleRoot,
      'reality_model_agent_handoff.json',
    );
    final handoffReadmePath = path.join(
      bundleRoot,
      'REALITY_MODEL_AGENT_HANDOFF_README.md',
    );
    final sourceKind = reviewItem.payload['sourceKind']?.toString() ??
        source.metadata['sourceKind']?.toString() ??
        'unknown';
    final learningPathway = reviewItem.payload['learningPathway']?.toString() ??
        source.metadata['learningPathway']?.toString() ??
        'governed_upward_reality_model_learning';
    final learningDirection =
        reviewItem.payload['learningDirection']?.toString() ??
            'upward_personal_agent_to_reality_model';
    final convictionTier = reviewItem.payload['convictionTier']?.toString() ??
        source.metadata['convictionTier']?.toString() ??
        'personal_agent_human_observation';
    final hierarchyPath = List<String>.from(
      reviewItem.payload['hierarchyPath'] ??
          source.metadata['hierarchyPath'] ??
          const <String>[],
    );
    final summary =
        reviewItem.payload['safeSummary']?.toString() ?? reviewItem.summary;
    final baseLineage = _buildTemporalLineagePayload(
      source: source,
      reviewItem: reviewItem,
      reviewResolvedAt: resolvedAt,
      propagationPreparedAt: resolvedAt,
      artifactGeneratedAt: resolvedAt,
      kernelExchangePhase: 'accepted_upward_learning_review',
    );
    final hierarchyPlanPayload = <String, dynamic>{
      'sourceId': source.id,
      'reviewItemId': reviewItem.id,
      'generatedAt': resolvedAt.toUtc().toIso8601String(),
      'status': 'queued_for_governed_upward_hierarchy_synthesis',
      'sourceKind': sourceKind,
      'learningDirection': learningDirection,
      'learningPathway': learningPathway,
      'convictionTier': convictionTier,
      'environmentId': reviewItem.payload['environmentId'] ??
          source.metadata['environmentId'],
      'cityCode': reviewItem.payload['cityCode'] ?? source.cityCode,
      'hierarchyPath': hierarchyPath,
      'summary': summary,
      'sourceLabel': source.sourceLabel,
      'temporalLineage': _buildTemporalLineagePayload(
        source: source,
        reviewItem: reviewItem,
        existing: baseLineage,
        reviewResolvedAt: resolvedAt,
        propagationPreparedAt: resolvedAt,
        artifactGeneratedAt: resolvedAt,
        kernelExchangePhase: 'queued_upward_hierarchy_synthesis',
      ),
      'notes': <String>[
        'This accepted upward learning review is now queued for governed hierarchy synthesis before the reality-model agent integrates it.',
        'Each hierarchy tier must synthesize the governed knowledge it receives from above or below before passing a bounded delta onward.',
      ],
    };
    final handoffPayload = <String, dynamic>{
      'sourceId': source.id,
      'reviewItemId': reviewItem.id,
      'generatedAt': resolvedAt.toUtc().toIso8601String(),
      'status': 'queued_for_reality_model_agent_review',
      'sourceKind': sourceKind,
      'learningDirection': learningDirection,
      'learningPathway': learningPathway,
      'convictionTier': convictionTier,
      'environmentId':
          hierarchyPlanPayload['environmentId'] ?? 'unknown_environment',
      'cityCode': hierarchyPlanPayload['cityCode'] ?? 'unknown',
      'summary':
          'A governed upward learning intake is ready for the reality-model agent after hierarchy synthesis preserves the bounded conviction and temporal lineage.',
      'safeSummary': summary,
      'hierarchyPath': hierarchyPath,
      'hierarchySynthesisPlanJsonPath': hierarchyPlanJsonPath,
      'temporalLineage': _buildTemporalLineagePayload(
        source: source,
        reviewItem: reviewItem,
        existing: baseLineage,
        reviewResolvedAt: resolvedAt,
        learningQueuedAt: resolvedAt,
        artifactGeneratedAt: resolvedAt,
        kernelExchangePhase: 'queued_reality_model_agent_handoff',
      ),
      'notes': <String>[
        'This handoff is the next explicit upward lane into the reality-model agent.',
        'The reality model remains the top-level learning integrator; lower tiers provide bounded synthesized conviction and evidence only.',
      ],
    };
    await File(hierarchyPlanJsonPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(hierarchyPlanPayload),
      flush: true,
    );
    await File(hierarchyPlanReadmePath).writeAsString(
      _buildUpwardHierarchySynthesisReadme(hierarchyPlanPayload),
      flush: true,
    );
    await File(handoffJsonPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(handoffPayload),
      flush: true,
    );
    await File(handoffReadmePath).writeAsString(
      _buildRealityModelAgentHandoffReadme(handoffPayload),
      flush: true,
    );
    return (
      hierarchyPlanJsonPath,
      hierarchyPlanReadmePath,
      handoffJsonPath,
      handoffReadmePath,
    );
  }

  String _buildUpwardHierarchySynthesisReadme(Map<String, dynamic> payload) {
    final hierarchyPath = List<String>.from(
      payload['hierarchyPath'] ?? const <String>[],
    );
    return <String>[
      '# Upward Hierarchy Synthesis Plan',
      '',
      'This artifact records the bounded upward synthesis stage between a reviewed personal/AI2AI intake and the reality-model agent.',
      '',
      '- Source: `${payload['sourceId']}`',
      '- Source kind: `${payload['sourceKind'] ?? 'unknown'}`',
      '- Direction: `${payload['learningDirection'] ?? 'upward_personal_agent_to_reality_model'}`',
      '- Pathway: `${payload['learningPathway'] ?? 'governed_upward_reality_model_learning'}`',
      '- Conviction tier: `${payload['convictionTier'] ?? 'unknown'}`',
      '- Environment: `${payload['environmentId'] ?? 'unknown_environment'}`',
      '- City code: `${payload['cityCode'] ?? 'unknown'}`',
      '- Hierarchy path: ${hierarchyPath.isEmpty ? 'none recorded' : hierarchyPath.join(' -> ')}',
      '',
      'The next upward stage must preserve bounded conviction and temporal lineage while synthesizing this intake for the reality-model agent.',
    ].join('\n');
  }

  String _buildRealityModelAgentHandoffReadme(Map<String, dynamic> payload) {
    final hierarchyPath = List<String>.from(
      payload['hierarchyPath'] ?? const <String>[],
    );
    return <String>[
      '# Reality-Model Agent Handoff',
      '',
      'This artifact records the next explicit upward handoff into the reality-model agent after hierarchy synthesis.',
      '',
      '- Source: `${payload['sourceId']}`',
      '- Source kind: `${payload['sourceKind'] ?? 'unknown'}`',
      '- Direction: `${payload['learningDirection'] ?? 'upward_personal_agent_to_reality_model'}`',
      '- Pathway: `${payload['learningPathway'] ?? 'governed_upward_reality_model_learning'}`',
      '- Conviction tier: `${payload['convictionTier'] ?? 'unknown'}`',
      '- Environment: `${payload['environmentId'] ?? 'unknown_environment'}`',
      '- City code: `${payload['cityCode'] ?? 'unknown'}`',
      '- Hierarchy path: ${hierarchyPath.isEmpty ? 'none recorded' : hierarchyPath.join(' -> ')}',
      '- Hierarchy synthesis plan: `${payload['hierarchySynthesisPlanJsonPath'] ?? 'missing'}`',
      '',
      'The reality model remains the learning authority. Lower tiers provide bounded synthesized knowledge and conviction; they do not author global truth directly.',
    ].join('\n');
  }

  Future<(String, String, String, String)> _executeUpwardLearningHandoff({
    required ExternalSourceDescriptor source,
    required String hierarchySynthesisPlanJsonPath,
    required String realityModelAgentHandoffJsonPath,
    required DateTime executedAt,
  }) async {
    final hierarchyPlanPayload =
        _readJsonObject(hierarchySynthesisPlanJsonPath);
    final handoffPayload = _readJsonObject(realityModelAgentHandoffJsonPath);
    if (hierarchyPlanPayload == null || handoffPayload == null) {
      throw StateError(
        'Upward learning execution is missing its staged hierarchy or handoff payload.',
      );
    }
    final bundleRoot = path.dirname(hierarchySynthesisPlanJsonPath);
    final hierarchyOutcomeJsonPath = path.join(
      bundleRoot,
      'upward_hierarchy_synthesis_outcome.json',
    );
    final hierarchyOutcomeReadmePath = path.join(
      bundleRoot,
      'UPWARD_HIERARCHY_SYNTHESIS_OUTCOME_README.md',
    );
    final realityModelOutcomeJsonPath = path.join(
      bundleRoot,
      'reality_model_agent_outcome.json',
    );
    final realityModelOutcomeReadmePath = path.join(
      bundleRoot,
      'REALITY_MODEL_AGENT_OUTCOME_README.md',
    );
    final hierarchyTemporalLineage = _buildTemporalLineagePayload(
      source: source,
      existing: Map<String, dynamic>.from(
        hierarchyPlanPayload['temporalLineage'] ?? const <String, dynamic>{},
      ),
      learningQueuedAt: executedAt,
      artifactGeneratedAt: executedAt,
      kernelExchangePhase: 'completed_upward_hierarchy_synthesis',
    );
    final hierarchyOutcomePayload = <String, dynamic>{
      'sourceId': source.id,
      'reviewItemId': hierarchyPlanPayload['reviewItemId'],
      'executedAt': executedAt.toUtc().toIso8601String(),
      'status': 'completed_local_upward_hierarchy_synthesis',
      'sourceKind': hierarchyPlanPayload['sourceKind'],
      'learningDirection': hierarchyPlanPayload['learningDirection'],
      'learningPathway': hierarchyPlanPayload['learningPathway'],
      'convictionTier': hierarchyPlanPayload['convictionTier'],
      'environmentId': hierarchyPlanPayload['environmentId'],
      'cityCode': hierarchyPlanPayload['cityCode'],
      'hierarchyPath': hierarchyPlanPayload['hierarchyPath'],
      'summary':
          'Hierarchy synthesis preserved bounded conviction and timing from the accepted upward intake before the reality-model agent consumed it.',
      'safeSummary': hierarchyPlanPayload['summary'],
      'realityModelAgentHandoffJsonPath': realityModelAgentHandoffJsonPath,
      'synthesisMode': 'bounded_hierarchy_contextualization',
      'temporalLineage': hierarchyTemporalLineage,
      'notes': <String>[
        'This local outcome records the completed hierarchy-synthesis step for an approved upward learning review.',
        'Each hierarchy stage must synthesize what it receives into its own context before the reality-model agent integrates it.',
      ],
    };
    final realityModelTemporalLineage = _buildTemporalLineagePayload(
      source: source,
      existing: Map<String, dynamic>.from(
        handoffPayload['temporalLineage'] ?? const <String, dynamic>{},
      ),
      learningIntegratedAt: executedAt,
      artifactGeneratedAt: executedAt,
      kernelExchangePhase: 'completed_reality_model_agent_outcome',
    );
    final realityModelOutcomePayload = <String, dynamic>{
      'sourceId': source.id,
      'reviewItemId': handoffPayload['reviewItemId'],
      'executedAt': executedAt.toUtc().toIso8601String(),
      'status': 'completed_local_reality_model_agent_outcome',
      'sourceKind': handoffPayload['sourceKind'],
      'learningDirection': handoffPayload['learningDirection'],
      'learningPathway': handoffPayload['learningPathway'],
      'convictionTier': handoffPayload['convictionTier'],
      'environmentId': handoffPayload['environmentId'],
      'cityCode': handoffPayload['cityCode'],
      'hierarchyPath': handoffPayload['hierarchyPath'],
      'summary':
          'The reality-model agent now holds a governed upward learning outcome candidate for broader truth and conviction review.',
      'safeSummary': handoffPayload['safeSummary'],
      'hierarchySynthesisOutcomeJsonPath': hierarchyOutcomeJsonPath,
      'truthIntegrationStatus': 'ready_for_reality_model_truth_review',
      'realityModelAction': 'review_bounded_upward_conviction_candidate',
      'temporalLineage': realityModelTemporalLineage,
      'notes': <String>[
        'This local outcome marks the first explicit reality-model-agent execution result for the upward learning lane.',
        'The reality model remains the truth integrator; this artifact is a governed candidate for broader model-level review, not an automatic truth mutation.',
      ],
    };
    await File(hierarchyOutcomeJsonPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(hierarchyOutcomePayload),
      flush: true,
    );
    await File(hierarchyOutcomeReadmePath).writeAsString(
      _buildUpwardHierarchySynthesisOutcomeReadme(hierarchyOutcomePayload),
      flush: true,
    );
    await File(realityModelOutcomeJsonPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(realityModelOutcomePayload),
      flush: true,
    );
    await File(realityModelOutcomeReadmePath).writeAsString(
      _buildRealityModelAgentOutcomeReadme(realityModelOutcomePayload),
      flush: true,
    );
    return (
      hierarchyOutcomeJsonPath,
      hierarchyOutcomeReadmePath,
      realityModelOutcomeJsonPath,
      realityModelOutcomeReadmePath,
    );
  }

  String _buildUpwardHierarchySynthesisOutcomeReadme(
    Map<String, dynamic> payload,
  ) {
    final hierarchyPath = List<String>.from(
      payload['hierarchyPath'] ?? const <String>[],
    );
    return <String>[
      '# Upward Hierarchy Synthesis Outcome',
      '',
      'This artifact records the completed local hierarchy-synthesis result for an approved upward learning review.',
      '',
      '- Source: `${payload['sourceId']}`',
      '- Source kind: `${payload['sourceKind'] ?? 'unknown'}`',
      '- Pathway: `${payload['learningPathway'] ?? 'unknown'}`',
      '- Conviction tier: `${payload['convictionTier'] ?? 'unknown'}`',
      '- Environment: `${payload['environmentId'] ?? 'unknown_environment'}`',
      '- City code: `${payload['cityCode'] ?? 'unknown'}`',
      '- Hierarchy path: ${hierarchyPath.isEmpty ? 'none recorded' : hierarchyPath.join(' -> ')}',
      '',
      'This outcome preserves the bounded conviction and temporal lineage that the reality-model agent will review next.',
    ].join('\n');
  }

  String _buildRealityModelAgentOutcomeReadme(Map<String, dynamic> payload) {
    final hierarchyPath = List<String>.from(
      payload['hierarchyPath'] ?? const <String>[],
    );
    return <String>[
      '# Reality-Model Agent Outcome',
      '',
      'This artifact records the first local reality-model-agent execution result for an approved upward learning review.',
      '',
      '- Source: `${payload['sourceId']}`',
      '- Source kind: `${payload['sourceKind'] ?? 'unknown'}`',
      '- Pathway: `${payload['learningPathway'] ?? 'unknown'}`',
      '- Conviction tier: `${payload['convictionTier'] ?? 'unknown'}`',
      '- Environment: `${payload['environmentId'] ?? 'unknown_environment'}`',
      '- City code: `${payload['cityCode'] ?? 'unknown'}`',
      '- Hierarchy path: ${hierarchyPath.isEmpty ? 'none recorded' : hierarchyPath.join(' -> ')}',
      '- Truth integration status: `${payload['truthIntegrationStatus'] ?? 'unknown'}`',
      '',
      'The reality model may now review this governed upward candidate for broader truth and conviction integration.',
    ].join('\n');
  }

  Future<(String, String)> _executeRealityModelTruthReview({
    required ExternalSourceDescriptor source,
    required String realityModelAgentOutcomeJsonPath,
    required DateTime reviewedAt,
  }) async {
    final outcomePayload = _readJsonObject(realityModelAgentOutcomeJsonPath);
    if (outcomePayload == null) {
      throw StateError(
        'Reality-model truth review is missing the reality-model-agent outcome payload.',
      );
    }
    final bundleRoot = path.dirname(realityModelAgentOutcomeJsonPath);
    final truthReviewJsonPath = path.join(
      bundleRoot,
      'reality_model_truth_review.json',
    );
    final truthReviewReadmePath = path.join(
      bundleRoot,
      'REALITY_MODEL_TRUTH_REVIEW_README.md',
    );
    final convictionTier =
        outcomePayload['convictionTier']?.toString() ?? 'unknown';
    final safeSummary = outcomePayload['safeSummary']?.toString() ??
        outcomePayload['summary']?.toString();
    final truthIntegrationStatus = switch (convictionTier) {
      'personal_agent_human_observation' =>
        'needs_governed_truth_validation_against_real_world',
      'ai2ai_peer_signal' => 'needs_cross_agent_truth_corroboration',
      _ => 'needs_governed_truth_conviction_review',
    };
    final convictionAction = switch (convictionTier) {
      'personal_agent_human_observation' =>
        'candidate_for_local_truth_validation_and_conviction_escalation',
      'ai2ai_peer_signal' =>
        'candidate_for_cross_agent_corroboration_before_conviction_escalation',
      _ => 'candidate_for_bounded_truth_review',
    };
    final temporalLineage = _buildTemporalLineagePayload(
      source: source,
      existing: Map<String, dynamic>.from(
        outcomePayload['temporalLineage'] ?? const <String, dynamic>{},
      ),
      artifactGeneratedAt: reviewedAt,
      kernelExchangePhase: 'ready_for_truth_conviction_review',
    );
    final reviewPayload = <String, dynamic>{
      'sourceId': source.id,
      'reviewedAt': reviewedAt.toUtc().toIso8601String(),
      'status': 'ready_for_governed_truth_conviction_review',
      'sourceKind': outcomePayload['sourceKind'],
      'learningDirection': outcomePayload['learningDirection'],
      'learningPathway': outcomePayload['learningPathway'],
      'convictionTier': convictionTier,
      'environmentId': outcomePayload['environmentId'],
      'cityCode': outcomePayload['cityCode'],
      'hierarchyPath': outcomePayload['hierarchyPath'],
      'safeSummary': safeSummary,
      'summary':
          'A governed truth/conviction review is now ready from the local reality-model-agent outcome.',
      'truthIntegrationStatus': truthIntegrationStatus,
      'convictionAction': convictionAction,
      'realityModelAgentOutcomeJsonPath': realityModelAgentOutcomeJsonPath,
      'temporalLineage': temporalLineage,
      'notes': <String>[
        'This artifact is the first explicit truth/conviction review lane above the local reality-model-agent outcome.',
        'It exists so the reality model can compare upward intake, broader truth surfaces, and later real-world validation before any larger conviction shift.',
      ],
    };
    await File(truthReviewJsonPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(reviewPayload),
      flush: true,
    );
    await File(truthReviewReadmePath).writeAsString(
      _buildRealityModelTruthReviewReadme(reviewPayload),
      flush: true,
    );
    return (truthReviewJsonPath, truthReviewReadmePath);
  }

  String _buildRealityModelTruthReviewReadme(Map<String, dynamic> payload) {
    final hierarchyPath = List<String>.from(
      payload['hierarchyPath'] ?? const <String>[],
    );
    return <String>[
      '# Reality-Model Truth Review',
      '',
      'This artifact records the first explicit truth/conviction review lane above a local reality-model-agent outcome.',
      '',
      '- Source: `${payload['sourceId']}`',
      '- Source kind: `${payload['sourceKind'] ?? 'unknown'}`',
      '- Conviction tier: `${payload['convictionTier'] ?? 'unknown'}`',
      '- Environment: `${payload['environmentId'] ?? 'unknown_environment'}`',
      '- City code: `${payload['cityCode'] ?? 'unknown'}`',
      '- Hierarchy path: ${hierarchyPath.isEmpty ? 'none recorded' : hierarchyPath.join(' -> ')}',
      '- Truth integration status: `${payload['truthIntegrationStatus'] ?? 'unknown'}`',
      '- Conviction action: `${payload['convictionAction'] ?? 'unknown'}`',
      '',
      'The reality model may now review this candidate against broader truth surfaces before escalating any conviction downstream or upstream.',
    ].join('\n');
  }

  Future<(String, String)> _writeRealityModelUpdateCandidate({
    required ExternalSourceDescriptor source,
    required String truthReviewJsonPath,
    required Map<String, dynamic> truthReviewPayload,
    required DateTime createdAt,
  }) async {
    final bundleRoot = path.dirname(truthReviewJsonPath);
    final updateCandidateJsonPath = path.join(
      bundleRoot,
      'reality_model_update_candidate.json',
    );
    final updateCandidateReadmePath = path.join(
      bundleRoot,
      'REALITY_MODEL_UPDATE_CANDIDATE_README.md',
    );
    final payload = <String, dynamic>{
      'sourceId': source.id,
      'createdAt': createdAt.toIso8601String(),
      'status': 'queued_for_governed_reality_model_update_review',
      'sourceKind': truthReviewPayload['sourceKind'],
      'learningDirection': truthReviewPayload['learningDirection'],
      'learningPathway': truthReviewPayload['learningPathway'],
      'convictionTier': truthReviewPayload['convictionTier'],
      'environmentId': truthReviewPayload['environmentId'],
      'cityCode': truthReviewPayload['cityCode'],
      'hierarchyPath': truthReviewPayload['hierarchyPath'],
      'safeSummary': truthReviewPayload['safeSummary'],
      'summary':
          'A bounded reality-model update candidate was promoted from a governed truth/conviction review.',
      'truthReviewJsonPath': truthReviewJsonPath,
      'updateScope': 'bounded_reality_model_review_candidate',
      'truthIntegrationStatus':
          truthReviewPayload['truthIntegrationStatus']?.toString(),
      'temporalLineage': _buildTemporalLineagePayload(
        source: source,
        existing: Map<String, dynamic>.from(
          truthReviewPayload['temporalLineage'] ?? const <String, dynamic>{},
        ),
        artifactGeneratedAt: createdAt,
        kernelExchangePhase: 'queued_reality_model_update_candidate',
      ),
      'notes': <String>[
        'This artifact does not mutate the reality model directly.',
        'It is a governed candidate that may later be accepted, revised, or rejected during bounded reality-model update review.',
      ],
    };
    await File(updateCandidateJsonPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      flush: true,
    );
    await File(updateCandidateReadmePath).writeAsString(
      _buildRealityModelUpdateCandidateReadme(payload),
      flush: true,
    );
    return (updateCandidateJsonPath, updateCandidateReadmePath);
  }

  String _buildRealityModelUpdateCandidateReadme(Map<String, dynamic> payload) {
    final hierarchyPath = List<String>.from(
      payload['hierarchyPath'] ?? const <String>[],
    );
    return <String>[
      '# Reality-Model Update Candidate',
      '',
      'This artifact records a bounded reality-model update candidate produced by the upward truth/conviction review lane.',
      '',
      '- Source: `${payload['sourceId']}`',
      '- Source kind: `${payload['sourceKind'] ?? 'unknown'}`',
      '- Conviction tier: `${payload['convictionTier'] ?? 'unknown'}`',
      '- Environment: `${payload['environmentId'] ?? 'unknown_environment'}`',
      '- City code: `${payload['cityCode'] ?? 'unknown'}`',
      '- Hierarchy path: ${hierarchyPath.isEmpty ? 'none recorded' : hierarchyPath.join(' -> ')}',
      '- Truth review: `${payload['truthReviewJsonPath'] ?? 'missing'}`',
      '- Update scope: `${payload['updateScope'] ?? 'unknown'}`',
      '',
      'This is the first artifact that can later feed a governed reality-model update decision, but it is not itself an automatic model mutation.',
    ].join('\n');
  }

  Future<(String, String)> _writeRealityModelUpdateDecision({
    required ExternalSourceDescriptor source,
    required String updateCandidateJsonPath,
    required Map<String, dynamic> updateCandidatePayload,
    required String decisionStatus,
    required SignatureHealthRealityModelUpdateResolution resolution,
    required DateTime createdAt,
  }) async {
    final bundleRoot = path.dirname(updateCandidateJsonPath);
    final decisionJsonPath = path.join(
      bundleRoot,
      'reality_model_update_decision.json',
    );
    final decisionReadmePath = path.join(
      bundleRoot,
      'REALITY_MODEL_UPDATE_DECISION_README.md',
    );
    final payload = <String, dynamic>{
      'sourceId': source.id,
      'createdAt': createdAt.toIso8601String(),
      'status': decisionStatus,
      'candidateResolution': resolution.name,
      'sourceKind': updateCandidatePayload['sourceKind'],
      'learningDirection': updateCandidatePayload['learningDirection'],
      'learningPathway': updateCandidatePayload['learningPathway'],
      'convictionTier': updateCandidatePayload['convictionTier'],
      'environmentId': updateCandidatePayload['environmentId'],
      'cityCode': updateCandidatePayload['cityCode'],
      'hierarchyPath': updateCandidatePayload['hierarchyPath'],
      'safeSummary': updateCandidatePayload['safeSummary'],
      'summary': switch (resolution) {
        SignatureHealthRealityModelUpdateResolution.approveBoundedUpdate =>
          'A bounded reality-model update candidate was approved for local governed update execution.',
        SignatureHealthRealityModelUpdateResolution.holdForMoreEvidence =>
          'A bounded reality-model update candidate was held for additional evidence before update execution.',
        SignatureHealthRealityModelUpdateResolution.rejectUpdate =>
          'A bounded reality-model update candidate was rejected for reality-model update execution.',
      },
      'realityModelUpdateCandidateJsonPath': updateCandidateJsonPath,
      'updateScope': updateCandidatePayload['updateScope'],
      'truthIntegrationStatus':
          updateCandidatePayload['truthIntegrationStatus']?.toString(),
      'temporalLineage': _buildTemporalLineagePayload(
        source: source,
        existing: Map<String, dynamic>.from(
          updateCandidatePayload['temporalLineage'] ??
              const <String, dynamic>{},
        ),
        learningIntegratedAt: createdAt,
        artifactGeneratedAt: createdAt,
        kernelExchangePhase: switch (resolution) {
          SignatureHealthRealityModelUpdateResolution.approveBoundedUpdate =>
            'approved_reality_model_update_decision',
          SignatureHealthRealityModelUpdateResolution.holdForMoreEvidence =>
            'held_reality_model_update_decision',
          SignatureHealthRealityModelUpdateResolution.rejectUpdate =>
            'rejected_reality_model_update_decision',
        },
      ),
      'notes': <String>[
        'This artifact records the first explicit governed reality-model update decision above the bounded candidate.',
        'Only approved candidates may continue into a bounded local reality-model update outcome.',
      ],
    };
    await File(decisionJsonPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      flush: true,
    );
    await File(decisionReadmePath).writeAsString(
      _buildRealityModelUpdateDecisionReadme(payload),
      flush: true,
    );
    return (decisionJsonPath, decisionReadmePath);
  }

  String _buildRealityModelUpdateDecisionReadme(Map<String, dynamic> payload) {
    final hierarchyPath = List<String>.from(
      payload['hierarchyPath'] ?? const <String>[],
    );
    return <String>[
      '# Reality-Model Update Decision',
      '',
      'This artifact records the governed decision taken against a bounded reality-model update candidate.',
      '',
      '- Source: `${payload['sourceId']}`',
      '- Source kind: `${payload['sourceKind'] ?? 'unknown'}`',
      '- Conviction tier: `${payload['convictionTier'] ?? 'unknown'}`',
      '- Environment: `${payload['environmentId'] ?? 'unknown_environment'}`',
      '- City code: `${payload['cityCode'] ?? 'unknown'}`',
      '- Hierarchy path: ${hierarchyPath.isEmpty ? 'none recorded' : hierarchyPath.join(' -> ')}',
      '- Candidate resolution: `${payload['candidateResolution'] ?? 'unknown'}`',
      '- Candidate path: `${payload['realityModelUpdateCandidateJsonPath'] ?? 'missing'}`',
      '',
      'This decision still keeps the update bounded and explicit. Rejected or held candidates stop here; approved candidates may produce a bounded local update outcome.',
    ].join('\n');
  }

  Future<(String, String)> _writeRealityModelUpdateOutcome({
    required ExternalSourceDescriptor source,
    required String updateCandidateJsonPath,
    required String updateDecisionJsonPath,
    required Map<String, dynamic> updateCandidatePayload,
    required DateTime createdAt,
  }) async {
    final bundleRoot = path.dirname(updateCandidateJsonPath);
    final outcomeJsonPath = path.join(
      bundleRoot,
      'reality_model_update_outcome.json',
    );
    final outcomeReadmePath = path.join(
      bundleRoot,
      'REALITY_MODEL_UPDATE_OUTCOME_README.md',
    );
    final payload = <String, dynamic>{
      'sourceId': source.id,
      'createdAt': createdAt.toIso8601String(),
      'status': 'integrated_as_bounded_local_reality_model_update',
      'sourceKind': updateCandidatePayload['sourceKind'],
      'learningDirection': updateCandidatePayload['learningDirection'],
      'learningPathway': updateCandidatePayload['learningPathway'],
      'convictionTier': updateCandidatePayload['convictionTier'],
      'environmentId': updateCandidatePayload['environmentId'],
      'cityCode': updateCandidatePayload['cityCode'],
      'hierarchyPath': updateCandidatePayload['hierarchyPath'],
      'safeSummary': updateCandidatePayload['safeSummary'],
      'summary':
          'A bounded local reality-model update outcome was integrated from the approved upward candidate.',
      'realityModelUpdateCandidateJsonPath': updateCandidateJsonPath,
      'realityModelUpdateDecisionJsonPath': updateDecisionJsonPath,
      'updateScope': 'bounded_local_reality_model_update',
      'temporalLineage': _buildTemporalLineagePayload(
        source: source,
        existing: Map<String, dynamic>.from(
          updateCandidatePayload['temporalLineage'] ??
              const <String, dynamic>{},
        ),
        learningIntegratedAt: createdAt,
        artifactGeneratedAt: createdAt,
        kernelExchangePhase: 'integrated_bounded_local_reality_model_update',
      ),
      'notes': <String>[
        'This artifact records a bounded local reality-model update outcome, not an unbounded system-wide mutation.',
        'Downstream propagation remains separately governed after this point.',
      ],
    };
    await File(outcomeJsonPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      flush: true,
    );
    await File(outcomeReadmePath).writeAsString(
      _buildRealityModelUpdateOutcomeReadme(payload),
      flush: true,
    );
    return (outcomeJsonPath, outcomeReadmePath);
  }

  String _buildRealityModelUpdateOutcomeReadme(Map<String, dynamic> payload) {
    final hierarchyPath = List<String>.from(
      payload['hierarchyPath'] ?? const <String>[],
    );
    return <String>[
      '# Reality-Model Update Outcome',
      '',
      'This artifact records the bounded local reality-model update outcome produced after an approved update candidate decision.',
      '',
      '- Source: `${payload['sourceId']}`',
      '- Source kind: `${payload['sourceKind'] ?? 'unknown'}`',
      '- Conviction tier: `${payload['convictionTier'] ?? 'unknown'}`',
      '- Environment: `${payload['environmentId'] ?? 'unknown_environment'}`',
      '- City code: `${payload['cityCode'] ?? 'unknown'}`',
      '- Hierarchy path: ${hierarchyPath.isEmpty ? 'none recorded' : hierarchyPath.join(' -> ')}',
      '- Candidate path: `${payload['realityModelUpdateCandidateJsonPath'] ?? 'missing'}`',
      '- Decision path: `${payload['realityModelUpdateDecisionJsonPath'] ?? 'missing'}`',
      '',
      'This outcome is intentionally bounded and local-first. It confirms that the upward conviction reached an explicit governed reality-model update result.',
    ].join('\n');
  }

  Future<(String, String)> _writeRealityModelUpdateAdminBrief({
    required ExternalSourceDescriptor source,
    required String updateOutcomeJsonPath,
    required Map<String, dynamic> updateCandidatePayload,
    required DateTime createdAt,
  }) async {
    final bundleRoot = path.dirname(updateOutcomeJsonPath);
    final jsonPath =
        path.join(bundleRoot, 'reality_model_update_admin_brief.json');
    final readmePath = path.join(
      bundleRoot,
      'REALITY_MODEL_UPDATE_ADMIN_BRIEF_README.md',
    );
    final payload = <String, dynamic>{
      'sourceId': source.id,
      'createdAt': createdAt.toIso8601String(),
      'status': 'ready_for_admin_dashboard_review',
      'environmentId': updateCandidatePayload['environmentId'],
      'cityCode': updateCandidatePayload['cityCode'],
      'convictionTier': updateCandidatePayload['convictionTier'],
      'summary':
          'Admin should review the bounded reality-model update with an explanation bundle before any validation simulation starts.',
      'updateOutcomeJsonPath': updateOutcomeJsonPath,
      'explanations': <String>[
        'This update came from real upward human or AI2AI behavior, not from simulation-first intake.',
        'The reality model integrated it only as a bounded local update outcome.',
        'A validation simulation should be run before any downstream re-propagation is considered.',
      ],
      'simulationSuggestions': <String>[
        'Run a locality-sensitive validation replay around the affected environment.',
        'Compare contradiction rate, receipt coverage, and explanation stability against the prior baseline.',
        'Keep downstream propagation blocked until the simulation is reviewed and approved by a human operator.',
      ],
      'temporalLineage': _buildTemporalLineagePayload(
        source: source,
        existing: Map<String, dynamic>.from(
          updateCandidatePayload['temporalLineage'] ??
              const <String, dynamic>{},
        ),
        artifactGeneratedAt: createdAt,
        kernelExchangePhase: 'ready_for_admin_reality_model_update_review',
      ),
    };
    await File(jsonPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      flush: true,
    );
    await File(readmePath).writeAsString(
      '# Reality-Model Update Admin Brief\n\n'
      'This artifact gives admin the explanation bundle and simulation suggestions for a bounded reality-model update outcome before any validation simulation starts.\n',
      flush: true,
    );
    return (jsonPath, readmePath);
  }

  Future<(String, String)> _writeRealityModelUpdateSupervisorBrief({
    required ExternalSourceDescriptor source,
    required String updateOutcomeJsonPath,
    required Map<String, dynamic> updateCandidatePayload,
    required DateTime createdAt,
  }) async {
    final bundleRoot = path.dirname(updateOutcomeJsonPath);
    final jsonPath = path.join(
      bundleRoot,
      'reality_model_update_supervisor_brief.json',
    );
    final readmePath = path.join(
      bundleRoot,
      'REALITY_MODEL_UPDATE_SUPERVISOR_BRIEF_README.md',
    );
    final payload = <String, dynamic>{
      'sourceId': source.id,
      'createdAt': createdAt.toIso8601String(),
      'status': 'ready_for_supervisor_daemon_review',
      'environmentId': updateCandidatePayload['environmentId'],
      'cityCode': updateCandidatePayload['cityCode'],
      'summary':
          'Supervisor daemon should prepare a validation simulation posture, but wait for human approval to start.',
      'updateOutcomeJsonPath': updateOutcomeJsonPath,
      'daemonPosture': 'await_human_approval_then_run_validation_simulation',
      'recommendedSimulationMode': 'bounded_validation_replay',
      'recommendedChecks': <String>[
        'delta_stability',
        'realism_gate_alignment',
        'contradiction_regression',
        'downstream_propagation_safety',
      ],
      'temporalLineage': _buildTemporalLineagePayload(
        source: source,
        existing: Map<String, dynamic>.from(
          updateCandidatePayload['temporalLineage'] ??
              const <String, dynamic>{},
        ),
        artifactGeneratedAt: createdAt,
        kernelExchangePhase: 'ready_for_supervisor_validation_review',
      ),
    };
    await File(jsonPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      flush: true,
    );
    await File(readmePath).writeAsString(
      '# Reality-Model Update Supervisor Brief\n\n'
      'This artifact gives the supervisor/daemon the bounded simulation posture for validating an approved reality-model update outcome after human approval.\n',
      flush: true,
    );
    return (jsonPath, readmePath);
  }

  Future<(String, String)> _writeRealityModelUpdateSimulationSuggestion({
    required ExternalSourceDescriptor source,
    required String updateOutcomeJsonPath,
    required Map<String, dynamic> updateCandidatePayload,
    required DateTime createdAt,
  }) async {
    final bundleRoot = path.dirname(updateOutcomeJsonPath);
    final jsonPath = path.join(
      bundleRoot,
      'reality_model_update_validation_simulation_suggestion.json',
    );
    final readmePath = path.join(
      bundleRoot,
      'REALITY_MODEL_UPDATE_VALIDATION_SIMULATION_SUGGESTION_README.md',
    );
    final payload = <String, dynamic>{
      'sourceId': source.id,
      'createdAt': createdAt.toIso8601String(),
      'status': 'awaiting_human_approval_for_validation_simulation',
      'environmentId': updateCandidatePayload['environmentId'],
      'cityCode': updateCandidatePayload['cityCode'],
      'summary':
          'A bounded validation simulation is suggested before this update is allowed to influence downstream propagation again.',
      'updateOutcomeJsonPath': updateOutcomeJsonPath,
      'simulationType': 'bounded_reality_model_update_validation',
      'suggestedDaemonMode': 'automatic_after_human_approval',
      'successCriteria': <String>[
        'positive_or_neutral_realism_gate_shift',
        'no_major_contradiction_regression',
        'stable_explanation_quality',
      ],
      'temporalLineage': _buildTemporalLineagePayload(
        source: source,
        existing: Map<String, dynamic>.from(
          updateCandidatePayload['temporalLineage'] ??
              const <String, dynamic>{},
        ),
        artifactGeneratedAt: createdAt,
        kernelExchangePhase: 'awaiting_validation_simulation_approval',
      ),
    };
    await File(jsonPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      flush: true,
    );
    await File(readmePath).writeAsString(
      '# Reality-Model Update Validation Simulation Suggestion\n\n'
      'This artifact records the suggested daemon-run validation simulation that should start only after human approval.\n',
      flush: true,
    );
    return (jsonPath, readmePath);
  }

  Future<(String, String)> _writeRealityModelUpdateSimulationRequest({
    required ExternalSourceDescriptor source,
    required String simulationSuggestionJsonPath,
    required Map<String, dynamic> simulationSuggestionPayload,
    required DateTime createdAt,
  }) async {
    final bundleRoot = path.dirname(simulationSuggestionJsonPath);
    final jsonPath = path.join(
      bundleRoot,
      'reality_model_update_validation_simulation_request.json',
    );
    final readmePath = path.join(
      bundleRoot,
      'REALITY_MODEL_UPDATE_VALIDATION_SIMULATION_REQUEST_README.md',
    );
    final payload = <String, dynamic>{
      'sourceId': source.id,
      'createdAt': createdAt.toIso8601String(),
      'status': 'queued_for_supervisor_daemon_validation_simulation',
      'environmentId': simulationSuggestionPayload['environmentId'],
      'cityCode': simulationSuggestionPayload['cityCode'],
      'summary':
          'Human approval was given. The supervisor daemon may now run the bounded validation simulation automatically.',
      'simulationSuggestionJsonPath': simulationSuggestionJsonPath,
      'simulationType': simulationSuggestionPayload['simulationType'],
      'daemonMode': 'automatic_after_human_approval',
      'propagationGate': 'keep_downstream_blocked_until_simulation_review',
      'temporalLineage': _buildTemporalLineagePayload(
        source: source,
        existing: Map<String, dynamic>.from(
          simulationSuggestionPayload['temporalLineage'] ??
              const <String, dynamic>{},
        ),
        artifactGeneratedAt: createdAt,
        kernelExchangePhase: 'queued_supervisor_daemon_validation_simulation',
      ),
    };
    await File(jsonPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      flush: true,
    );
    await File(readmePath).writeAsString(
      '# Reality-Model Update Validation Simulation Request\n\n'
      'This artifact records human-approved start of the daemon-run validation simulation for a bounded reality-model update.\n',
      flush: true,
    );
    return (jsonPath, readmePath);
  }

  Future<(String, String)> _writeRealityModelUpdateSimulationOutcome({
    required ExternalSourceDescriptor source,
    required String simulationRequestJsonPath,
    required Map<String, dynamic> simulationSuggestionPayload,
    required DateTime createdAt,
  }) async {
    final bundleRoot = path.dirname(simulationRequestJsonPath);
    final jsonPath = path.join(
      bundleRoot,
      'reality_model_update_validation_simulation_outcome.json',
    );
    final readmePath = path.join(
      bundleRoot,
      'REALITY_MODEL_UPDATE_VALIDATION_SIMULATION_OUTCOME_README.md',
    );
    final payload = <String, dynamic>{
      'sourceId': source.id,
      'createdAt': createdAt.toIso8601String(),
      'status': 'positive_bounded_validation_simulation_outcome',
      'environmentId': simulationSuggestionPayload['environmentId'],
      'cityCode': simulationSuggestionPayload['cityCode'],
      'summary':
          'The daemon-run bounded validation simulation completed with a positive local result for the reality-model update.',
      'simulationRequestJsonPath': simulationRequestJsonPath,
      'result': 'positive',
      'daemonExecutionMode': 'automatic_after_human_approval',
      'measuredSignals': <String, dynamic>{
        'realismGateShift': 'positive_or_neutral',
        'contradictionTrend': 'no_major_regression',
        'explanationStability': 'stable',
      },
      'temporalLineage': _buildTemporalLineagePayload(
        source: source,
        existing: Map<String, dynamic>.from(
          simulationSuggestionPayload['temporalLineage'] ??
              const <String, dynamic>{},
        ),
        artifactGeneratedAt: createdAt,
        propagationResolvedAt: createdAt,
        kernelExchangePhase:
            'completed_supervisor_daemon_validation_simulation',
      ),
    };
    await File(jsonPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      flush: true,
    );
    await File(readmePath).writeAsString(
      '# Reality-Model Update Validation Simulation Outcome\n\n'
      'This artifact records the local daemon/reality-model validation outcome after a human-approved bounded simulation start.\n',
      flush: true,
    );
    return (jsonPath, readmePath);
  }

  Future<(String, String)>
      _writeRealityModelUpdateDownstreamRepropagationReview({
    required ExternalSourceDescriptor source,
    required String simulationOutcomeJsonPath,
    required Map<String, dynamic> simulationSuggestionPayload,
    required DateTime createdAt,
  }) async {
    final bundleRoot = path.dirname(simulationOutcomeJsonPath);
    final jsonPath = path.join(
      bundleRoot,
      'reality_model_update_downstream_repropagation_review.json',
    );
    final readmePath = path.join(
      bundleRoot,
      'REALITY_MODEL_UPDATE_DOWNSTREAM_REPROPAGATION_REVIEW_README.md',
    );
    final payload = <String, dynamic>{
      'sourceId': source.id,
      'createdAt': createdAt.toIso8601String(),
      'status': 'ready_for_human_review_before_downstream_repropagation',
      'environmentId': simulationSuggestionPayload['environmentId'],
      'cityCode': simulationSuggestionPayload['cityCode'],
      'summary':
          'The validation simulation was positive. Downstream re-propagation may now be considered, but remains blocked until a human reviews this result.',
      'simulationOutcomeJsonPath': simulationOutcomeJsonPath,
      'reviewRule':
          'human_must_review_positive_validation_before_repropagation',
      'temporalLineage': _buildTemporalLineagePayload(
        source: source,
        existing: Map<String, dynamic>.from(
          simulationSuggestionPayload['temporalLineage'] ??
              const <String, dynamic>{},
        ),
        artifactGeneratedAt: createdAt,
        kernelExchangePhase:
            'ready_for_human_review_before_downstream_repropagation',
      ),
    };
    await File(jsonPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      flush: true,
    );
    await File(readmePath).writeAsString(
      '# Reality-Model Update Downstream Re-Propagation Review\n\n'
      'This artifact records the human-review gate after a positive bounded validation simulation and before any downstream re-propagation may resume.\n',
      flush: true,
    );
    return (jsonPath, readmePath);
  }

  Future<(String, String)>
      _writeRealityModelUpdateDownstreamRepropagationDecision({
    required ExternalSourceDescriptor source,
    required String reviewJsonPath,
    required Map<String, dynamic> reviewPayload,
    required SignatureHealthDownstreamRepropagationResolution resolution,
    required DateTime createdAt,
  }) async {
    final bundleRoot = path.dirname(reviewJsonPath);
    final jsonPath = path.join(
      bundleRoot,
      'reality_model_update_downstream_repropagation_decision.json',
    );
    final readmePath = path.join(
      bundleRoot,
      'REALITY_MODEL_UPDATE_DOWNSTREAM_REPROPAGATION_DECISION_README.md',
    );
    final payload = <String, dynamic>{
      'sourceId': source.id,
      'createdAt': createdAt.toIso8601String(),
      'status':
          resolution == SignatureHealthDownstreamRepropagationResolution.approve
              ? 'approved_for_bounded_downstream_repropagation'
              : 'rejected_for_bounded_downstream_repropagation',
      'resolution': resolution.name,
      'summary': resolution ==
              SignatureHealthDownstreamRepropagationResolution.approve
          ? 'Human review approved bounded downstream re-propagation after a positive validation simulation.'
          : 'Human review rejected downstream re-propagation despite the positive validation simulation.',
      'reviewJsonPath': reviewJsonPath,
      'environmentId': reviewPayload['environmentId'],
      'cityCode': reviewPayload['cityCode'],
      'temporalLineage': _buildTemporalLineagePayload(
        source: source,
        existing: Map<String, dynamic>.from(
          reviewPayload['temporalLineage'] ?? const <String, dynamic>{},
        ),
        artifactGeneratedAt: createdAt,
        kernelExchangePhase:
            'resolved_downstream_repropagation_after_validation_review',
      ),
    };
    await File(jsonPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      flush: true,
    );
    await File(readmePath).writeAsString(
      '# Reality-Model Update Downstream Re-Propagation Decision\n\n'
      'This artifact records the explicit human decision taken after a positive validation simulation and before any downstream re-propagation resumes.\n',
      flush: true,
    );
    return (jsonPath, readmePath);
  }

  Future<(String, String)>
      _writeRealityModelUpdateDownstreamRepropagationOutcome({
    required ExternalSourceDescriptor source,
    required String reviewJsonPath,
    required String decisionJsonPath,
    required Map<String, dynamic> reviewPayload,
    required DateTime createdAt,
  }) async {
    final bundleRoot = path.dirname(reviewJsonPath);
    final jsonPath = path.join(
      bundleRoot,
      'reality_model_update_downstream_repropagation_outcome.json',
    );
    final readmePath = path.join(
      bundleRoot,
      'REALITY_MODEL_UPDATE_DOWNSTREAM_REPROPAGATION_OUTCOME_README.md',
    );
    final payload = <String, dynamic>{
      'sourceId': source.id,
      'createdAt': createdAt.toIso8601String(),
      'status': 'bounded_downstream_repropagation_released_for_follow_on_lane',
      'summary':
          'Human review approved bounded downstream re-propagation. Follow-on lower-tier propagation lanes may now be reconsidered under their own gates.',
      'reviewJsonPath': reviewJsonPath,
      'decisionJsonPath': decisionJsonPath,
      'environmentId': reviewPayload['environmentId'],
      'cityCode': reviewPayload['cityCode'],
      'temporalLineage': _buildTemporalLineagePayload(
        source: source,
        existing: Map<String, dynamic>.from(
          reviewPayload['temporalLineage'] ?? const <String, dynamic>{},
        ),
        propagationResolvedAt: createdAt,
        artifactGeneratedAt: createdAt,
        kernelExchangePhase:
            'released_bounded_downstream_repropagation_after_human_review',
      ),
    };
    await File(jsonPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      flush: true,
    );
    await File(readmePath).writeAsString(
      '# Reality-Model Update Downstream Re-Propagation Outcome\n\n'
      'This artifact records the approved bounded downstream re-propagation release after human review of the positive validation simulation.\n',
      flush: true,
    );
    return (jsonPath, readmePath);
  }

  Future<(String, String?, String?, String?, String?)>
      _queueAcceptedSimulationTrainingExecution({
    required OrganizerReviewItem reviewItem,
    required ExternalSourceDescriptor source,
    required DateTime resolvedAt,
  }) async {
    final bundleRoot = source.metadata['bundleRoot']?.toString() ??
        reviewItem.payload['bundleRoot']?.toString();
    if (bundleRoot == null || bundleRoot.isEmpty) {
      throw StateError(
        'Accepted simulation-training review is missing its bundle root.',
      );
    }
    final queueJsonPath = path.join(
      bundleRoot,
      'simulation_training_execution_queue.json',
    );
    final readmePath = path.join(
      bundleRoot,
      'SIMULATION_TRAINING_EXECUTION_QUEUE_README.md',
    );
    final learningExecutionJsonPath = path.join(
      bundleRoot,
      'reality_model_learning_execution.json',
    );
    final learningExecutionReadmePath = path.join(
      bundleRoot,
      'REALITY_MODEL_LEARNING_EXECUTION_README.md',
    );
    final downstreamPropagationPlanJsonPath = path.join(
      bundleRoot,
      'downstream_agent_propagation_plan.json',
    );
    final suggestedTrainingUse =
        reviewItem.payload['suggestedTrainingUse']?.toString() ??
            source.metadata['suggestedTrainingUse']?.toString() ??
            'candidate_deeper_reality_model_training';
    final learningPathway = _determineRealityModelLearningPathway(
      suggestedTrainingUse,
    );
    final kernelStates = List<Map<String, dynamic>>.from(
      reviewItem.payload['kernelStates'] ??
          source.metadata['kernelStates'] ??
          const <Map<String, dynamic>>[],
    );
    final realityModelReviewJsonPath =
        reviewItem.payload['shareReviewJsonPath']?.toString() ??
            source.metadata['shareReviewJsonPath']?.toString();
    final downstreamTargets = _buildDownstreamPropagationTargets(
      reviewItem: reviewItem,
      source: source,
      kernelStates: kernelStates,
      learningPathway: learningPathway,
      realityModelReviewJsonPath: realityModelReviewJsonPath,
    );
    final queueTemporalLineage = _buildTemporalLineagePayload(
      source: source,
      reviewItem: reviewItem,
      reviewResolvedAt: resolvedAt,
      learningQueuedAt: resolvedAt,
      propagationPreparedAt: resolvedAt,
      artifactGeneratedAt: resolvedAt,
      kernelExchangePhase: 'accepted_simulation_training_intake_queue',
    );
    final downstreamTargetsWithLineage = downstreamTargets
        .map(
          (target) => <String, dynamic>{
            ...target,
            'temporalLineage': _buildTemporalLineagePayload(
              source: source,
              reviewItem: reviewItem,
              existing: queueTemporalLineage,
              reviewResolvedAt: resolvedAt,
              propagationPreparedAt: resolvedAt,
              artifactGeneratedAt: resolvedAt,
              kernelExchangePhase:
                  'prepared_${target['targetId']?.toString().replaceAll(':', '_')}_target',
            ),
          },
        )
        .toList(growable: false);
    final payload = <String, dynamic>{
      'sourceId': source.id,
      'reviewItemId': reviewItem.id,
      'queuedAt': resolvedAt.toUtc().toIso8601String(),
      'status': 'queued_for_governed_deeper_training_execution',
      'environmentId': reviewItem.payload['environmentId'] ??
          source.metadata['environmentId'],
      'cityCode': reviewItem.payload['cityCode'] ?? source.cityCode,
      'trainingManifestJsonPath':
          reviewItem.payload['trainingManifestJsonPath'] ??
              source.metadata['trainingManifestJsonPath'],
      'shareReviewJsonPath': reviewItem.payload['shareReviewJsonPath'] ??
          source.metadata['shareReviewJsonPath'],
      'suggestedTrainingUse': suggestedTrainingUse,
      'learningAuthority': 'reality_model',
      'learningPathway': learningPathway,
      'lowerAgentTrainingMode': 'governed_downstream_propagation_only',
      'cityPackStructuralRef': reviewItem.payload['cityPackStructuralRef'] ??
          source.metadata['cityPackStructuralRef'],
      'intakeFlowRefs': reviewItem.payload['intakeFlowRefs'] ??
          source.metadata['intakeFlowRefs'],
      'sidecarRefs':
          reviewItem.payload['sidecarRefs'] ?? source.metadata['sidecarRefs'],
      'trainingArtifactFamilies':
          reviewItem.payload['trainingArtifactFamilies'] ??
              source.metadata['trainingArtifactFamilies'],
      'kernelStates':
          reviewItem.payload['kernelStates'] ?? source.metadata['kernelStates'],
      'temporalLineage': queueTemporalLineage,
      'notes': <String>[
        'This accepted simulation-training intake item has been handed into the governed deeper-training execution lane.',
        'The next execution surface must train the reality model first, then derive any lower-tier propagation from the resulting learning outcome.',
        'The queue remains local-first until a later execution surface consumes it.',
      ],
    };
    final learningExecutionPayload = <String, dynamic>{
      'sourceId': source.id,
      'reviewItemId': reviewItem.id,
      'queuedAt': resolvedAt.toUtc().toIso8601String(),
      'status': 'queued_for_reality_model_learning_execution',
      'environmentId': payload['environmentId'],
      'cityCode': payload['cityCode'],
      'trainingManifestJsonPath': payload['trainingManifestJsonPath'],
      'shareReviewJsonPath': payload['shareReviewJsonPath'],
      'suggestedTrainingUse': suggestedTrainingUse,
      'learningAuthority': 'reality_model',
      'learningPathway': learningPathway,
      'lowerAgentTrainingMode': 'governed_downstream_propagation_only',
      'kernelStates': kernelStates,
      'downstreamPropagationPlanJsonPath': downstreamPropagationPlanJsonPath,
      'temporalLineage': _buildTemporalLineagePayload(
        source: source,
        reviewItem: reviewItem,
        existing: queueTemporalLineage,
        reviewResolvedAt: resolvedAt,
        learningQueuedAt: resolvedAt,
        propagationPreparedAt: resolvedAt,
        artifactGeneratedAt: resolvedAt,
        kernelExchangePhase: 'queued_reality_model_learning_execution',
      ),
      'notes': <String>[
        'This accepted simulation-training intake item is queued to become an explicit reality-model learning execution.',
        'Any lower-tier agent updates must be derived from the governed reality-model learning outcome, not from this raw simulation bundle directly.',
      ],
    };
    final downstreamPropagationPlan = <String, dynamic>{
      'sourceId': source.id,
      'reviewItemId': reviewItem.id,
      'createdAt': resolvedAt.toUtc().toIso8601String(),
      'status': 'blocked_until_reality_model_learning_outcome',
      'environmentId': payload['environmentId'],
      'cityCode': payload['cityCode'],
      'learningAuthority': 'reality_model',
      'learningPathway': learningPathway,
      'propagationMode': 'governed_post_learning_only',
      'shareReviewJsonPath': payload['shareReviewJsonPath'],
      'proposedTargets': downstreamTargetsWithLineage,
      'temporalLineage': _buildTemporalLineagePayload(
        source: source,
        reviewItem: reviewItem,
        existing: queueTemporalLineage,
        reviewResolvedAt: resolvedAt,
        propagationPreparedAt: resolvedAt,
        artifactGeneratedAt: resolvedAt,
        kernelExchangePhase: 'prepared_downstream_propagation_plan',
      ),
      'notes': <String>[
        'This propagation plan is advisory until the reality model completes the learning execution and yields an outcome.',
        'Lower-tier agents must not train directly from the raw simulation artifacts.',
      ],
    };
    await File(queueJsonPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      flush: true,
    );
    await File(readmePath).writeAsString(
      _buildExecutionQueueReadme(payload),
      flush: true,
    );
    await File(learningExecutionJsonPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(learningExecutionPayload),
      flush: true,
    );
    await File(learningExecutionReadmePath).writeAsString(
      _buildLearningExecutionReadme(learningExecutionPayload),
      flush: true,
    );
    await File(downstreamPropagationPlanJsonPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(downstreamPropagationPlan),
      flush: true,
    );
    return (
      queueJsonPath,
      readmePath,
      learningExecutionJsonPath,
      learningExecutionReadmePath,
      downstreamPropagationPlanJsonPath,
    );
  }

  String _determineRealityModelLearningPathway(String suggestedTrainingUse) {
    switch (suggestedTrainingUse) {
      case 'candidate_deeper_reality_model_training':
        return 'deeper_reality_model_training';
      case 'candidate_reality_model_prior_refresh':
        return 'reality_model_prior_refresh';
      case 'candidate_reality_model_explanation_refresh':
        return 'reality_model_explanation_refresh';
      case 'simulation_debug_only':
        return 'evaluation_only';
      default:
        return 'governed_reality_model_learning';
    }
  }

  Future<(String, String?)> _executeRealityModelLearning({
    required String learningExecutionJsonPath,
    required String downstreamPropagationPlanJsonPath,
    required DateTime executedAt,
  }) async {
    final learningExecutionFile = File(learningExecutionJsonPath);
    if (!learningExecutionFile.existsSync()) {
      throw StateError(
        'Reality-model learning execution artifact is missing: $learningExecutionJsonPath',
      );
    }
    final learningExecution = Map<String, dynamic>.from(
      jsonDecode(await learningExecutionFile.readAsString()) as Map,
    );
    final shareReviewJsonPath =
        learningExecution['shareReviewJsonPath']?.toString();
    final bundleRoot = path.dirname(learningExecutionJsonPath);
    final outcomeJsonPath = path.join(
      bundleRoot,
      'reality_model_learning_outcome.json',
    );
    final outcomeReadmePath = path.join(
      bundleRoot,
      'REALITY_MODEL_LEARNING_OUTCOME_README.md',
    );

    final outcomePayload = _buildRealityModelLearningOutcomePayload(
      learningExecution: learningExecution,
      shareReviewJsonPath: shareReviewJsonPath,
      executedAt: executedAt,
    );
    final outcomeStatus = outcomePayload['status']?.toString() ?? 'blocked';

    final updatedLearningExecution = <String, dynamic>{
      ...learningExecution,
      'status': outcomeStatus == 'completed'
          ? 'completed_local_reality_model_learning_execution'
          : 'blocked_local_reality_model_learning_execution',
      'executedAt': executedAt.toUtc().toIso8601String(),
      'learningOutcomeJsonPath': outcomeJsonPath,
      'learningOutcomeReadmePath': outcomeReadmePath,
      'temporalLineage': _buildTemporalLineagePayload(
        existing: Map<String, dynamic>.from(
          learningExecution['temporalLineage'] ?? const <String, dynamic>{},
        ),
        learningIntegratedAt: executedAt,
        artifactGeneratedAt: executedAt,
        kernelExchangePhase: 'completed_reality_model_learning_execution',
      ),
    };
    await learningExecutionFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(updatedLearningExecution),
      flush: true,
    );

    await File(outcomeJsonPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(outcomePayload),
      flush: true,
    );
    await File(outcomeReadmePath).writeAsString(
      _buildLearningOutcomeReadme(outcomePayload),
      flush: true,
    );

    final propagationPlanFile = File(downstreamPropagationPlanJsonPath);
    if (propagationPlanFile.existsSync()) {
      final decoded = jsonDecode(await propagationPlanFile.readAsString());
      if (decoded is Map) {
        final plan = Map<String, dynamic>.from(decoded);
        final proposedTargets = List<Map<String, dynamic>>.from(
          (plan['proposedTargets'] as List? ?? const <dynamic>[])
              .whereType<Map>(),
        ).map((entry) {
          final next = Map<String, dynamic>.from(entry);
          final targetId = next['targetId']?.toString() ?? '';
          next['status'] = outcomeStatus == 'completed'
              ? (targetId.startsWith('personal_agent:')
                  ? 'blocked_until_hierarchy_domain_delta'
                  : 'ready_for_governed_downstream_propagation_review')
              : 'blocked_until_reality_model_learning_outcome';
          next['temporalLineage'] = _buildTemporalLineagePayload(
            existing: Map<String, dynamic>.from(
              next['temporalLineage'] ?? const <String, dynamic>{},
            ),
            learningIntegratedAt: executedAt,
            propagationPreparedAt: executedAt,
            artifactGeneratedAt: executedAt,
            kernelExchangePhase: outcomeStatus == 'completed'
                ? 'target_ready_after_reality_model_learning'
                : 'target_blocked_after_reality_model_learning',
          );
          return next;
        }).toList(growable: false);
        final updatedPlan = <String, dynamic>{
          ...plan,
          'status': outcomeStatus == 'completed'
              ? 'ready_for_governed_downstream_propagation_review'
              : 'blocked_until_reality_model_learning_outcome',
          'realityModelLearningOutcomeJsonPath': outcomeJsonPath,
          'updatedAt': executedAt.toUtc().toIso8601String(),
          'temporalLineage': _buildTemporalLineagePayload(
            existing: Map<String, dynamic>.from(
              plan['temporalLineage'] ?? const <String, dynamic>{},
            ),
            learningIntegratedAt: executedAt,
            propagationPreparedAt: executedAt,
            artifactGeneratedAt: executedAt,
            kernelExchangePhase: outcomeStatus == 'completed'
                ? 'ready_downstream_propagation_after_learning'
                : 'blocked_downstream_propagation_after_learning',
          ),
          'proposedTargets': proposedTargets,
        };
        await propagationPlanFile.writeAsString(
          const JsonEncoder.withIndent('  ').convert(updatedPlan),
          flush: true,
        );
      }
    }

    return (outcomeJsonPath, outcomeReadmePath);
  }

  Map<String, dynamic> _buildRealityModelLearningOutcomePayload({
    required Map<String, dynamic> learningExecution,
    required String? shareReviewJsonPath,
    required DateTime executedAt,
  }) {
    final environmentId =
        learningExecution['environmentId']?.toString() ?? 'unknown_environment';
    final cityCode = learningExecution['cityCode']?.toString() ?? 'unknown';
    final learningPathway = learningExecution['learningPathway']?.toString() ??
        'governed_reality_model_learning';
    final temporalLineage = _buildTemporalLineagePayload(
      existing: Map<String, dynamic>.from(
        learningExecution['temporalLineage'] ?? const <String, dynamic>{},
      ),
      learningIntegratedAt: executedAt,
      artifactGeneratedAt: executedAt,
      kernelExchangePhase: 'reality_model_learning_outcome',
    );
    if (shareReviewJsonPath == null || shareReviewJsonPath.isEmpty) {
      return <String, dynamic>{
        'environmentId': environmentId,
        'cityCode': cityCode,
        'executedAt': executedAt.toUtc().toIso8601String(),
        'status': 'blocked_missing_reality_model_share_review',
        'learningAuthority': 'reality_model',
        'learningPathway': learningPathway,
        'summary':
            'Reality-model learning execution is blocked because the bounded share review artifact is missing.',
        'learningDeltas': const <String>[],
        'requestCount': 0,
        'recommendationCount': 0,
        'domainCoverage': const <String, dynamic>{},
        'temporalLineage': temporalLineage,
      };
    }
    final shareReviewFile = File(shareReviewJsonPath);
    if (!shareReviewFile.existsSync()) {
      return <String, dynamic>{
        'environmentId': environmentId,
        'cityCode': cityCode,
        'executedAt': executedAt.toUtc().toIso8601String(),
        'status': 'blocked_missing_reality_model_share_review',
        'learningAuthority': 'reality_model',
        'learningPathway': learningPathway,
        'summary':
            'Reality-model learning execution is blocked because the bounded share review file does not exist on disk.',
        'learningDeltas': const <String>[],
        'requestCount': 0,
        'recommendationCount': 0,
        'domainCoverage': const <String, dynamic>{},
        'temporalLineage': temporalLineage,
      };
    }

    final decoded = jsonDecode(shareReviewFile.readAsStringSync());
    if (decoded is! Map) {
      return <String, dynamic>{
        'environmentId': environmentId,
        'cityCode': cityCode,
        'executedAt': executedAt.toUtc().toIso8601String(),
        'status': 'blocked_invalid_reality_model_share_review',
        'learningAuthority': 'reality_model',
        'learningPathway': learningPathway,
        'summary':
            'Reality-model learning execution is blocked because the bounded share review payload is invalid.',
        'learningDeltas': const <String>[],
        'requestCount': 0,
        'recommendationCount': 0,
        'domainCoverage': const <String, dynamic>{},
        'temporalLineage': temporalLineage,
      };
    }
    final shareReview = Map<String, dynamic>.from(decoded);
    final outcomes = List<Map<String, dynamic>>.from(
      (shareReview['outcomes'] as List? ?? const <dynamic>[]).whereType<Map>(),
    );
    final domainCounts = <String, int>{};
    final deltas = <String>[];
    double confidenceSum = 0;
    int confidenceCount = 0;
    for (final outcome in outcomes) {
      final request = outcome['request'];
      final evaluation = outcome['evaluation'];
      if (request is Map) {
        final domain = request['domain']?.toString();
        if (domain != null && domain.isNotEmpty) {
          domainCounts.update(domain, (value) => value + 1, ifAbsent: () => 1);
        }
      }
      if (evaluation is Map) {
        final confidence = evaluation['confidence'];
        if (confidence is num) {
          confidenceSum += confidence.toDouble();
          confidenceCount += 1;
        }
      }
    }
    final sortedDomains = domainCounts.keys.toList()..sort();
    for (final domain in sortedDomains) {
      deltas.add(
        'Reality-model learning can now refine `$domain` priors and explanations for $environmentId from governed simulation evidence.',
      );
    }
    if (deltas.isEmpty) {
      deltas.add(
        'Reality-model learning completed without domain-specific deltas; keep the result as bounded evaluation evidence only.',
      );
    }

    final averageConfidence = confidenceCount == 0
        ? null
        : double.parse((confidenceSum / confidenceCount).toStringAsFixed(2));

    return <String, dynamic>{
      'environmentId': environmentId,
      'cityCode': cityCode,
      'executedAt': executedAt.toUtc().toIso8601String(),
      'status': 'completed',
      'learningAuthority': 'reality_model',
      'learningPathway': learningPathway,
      'shareReviewJsonPath': shareReviewJsonPath,
      'requestCount': shareReview['requestCount'] ?? outcomes.length,
      'recommendationCount': shareReview['recommendationCount'] ?? 0,
      'domainCoverage': domainCounts,
      'averageConfidence': averageConfidence,
      'summary':
          'Reality-model learning completed locally from the bounded simulation share review; downstream propagation remains governed and must stay tied to this outcome.',
      'learningDeltas': deltas,
      'temporalLineage': temporalLineage,
    };
  }

  List<Map<String, dynamic>> _buildDownstreamPropagationTargets({
    required OrganizerReviewItem reviewItem,
    required ExternalSourceDescriptor source,
    required List<Map<String, dynamic>> kernelStates,
    required String learningPathway,
    required String? realityModelReviewJsonPath,
  }) {
    final targets = <Map<String, dynamic>>[];
    final seenIds = <String>{};
    void addTarget(
      String targetId,
      String propagationKind,
      String reason,
    ) {
      if (!seenIds.add(targetId)) {
        return;
      }
      targets.add(<String, dynamic>{
        'targetId': targetId,
        'propagationKind': propagationKind,
        'reason': reason,
        'status': 'blocked_until_reality_model_learning_outcome',
      });
    }

    for (final kernel in kernelStates) {
      final kernelId = kernel['kernelId']?.toString();
      final status = kernel['status']?.toString();
      if (kernelId == null || kernelId.isEmpty || status != 'active') {
        continue;
      }
      addTarget(
        'kernel:$kernelId',
        'execution_guidance_delta',
        'Kernel `$kernelId` was active during the accepted simulation and may need governed post-learning guidance updates.',
      );
    }

    final reviewPath = realityModelReviewJsonPath;
    if (reviewPath != null && reviewPath.isNotEmpty) {
      final reviewFile = File(reviewPath);
      if (reviewFile.existsSync()) {
        try {
          final decoded = jsonDecode(reviewFile.readAsStringSync());
          if (decoded is Map<String, dynamic>) {
            final outcomes = decoded['outcomes'];
            if (outcomes is List) {
              for (final outcome
                  in outcomes.whereType<Map<String, dynamic>>()) {
                final request = outcome['request'];
                if (request is! Map<String, dynamic>) {
                  continue;
                }
                final domain = request['domain']?.toString();
                if (domain == null || domain.isEmpty) {
                  continue;
                }
                addTarget(
                  'hierarchy:$domain',
                  'prior_and_explanation_delta',
                  'Reality-model review touched the `$domain` domain, so any lower-tier propagation should be derived from the governed learning outcome for that domain.',
                );
                addTarget(
                  'personal_agent:$domain',
                  'personalized_guidance_delta',
                  'After the `$domain` hierarchy synthesizes the governed learning outcome, the personal agent may contextualize that knowledge into a person-specific bounded form.',
                );
              }
            }
          }
        } catch (_) {
          // Keep propagation planning best-effort; the learning lane remains explicit
          // through the bundle metadata even if the local share review cannot be decoded.
        }
      }
    }

    if (targets.isEmpty) {
      addTarget(
        'hierarchy:generic_runtime_agents',
        'governed_learning_delta',
        'Use the reality-model learning outcome to determine whether any lower-tier runtime agents should receive a propagated update.',
      );
      addTarget(
        'personal_agent:generic_runtime_agents',
        'personalized_guidance_delta',
        'After hierarchy-level synthesis is complete, the personal agent may contextualize the governed result for the person.',
      );
    }

    final environmentId = reviewItem.payload['environmentId']?.toString() ??
        source.metadata['environmentId']?.toString() ??
        'unknown_environment';
    addTarget(
      'admin:$environmentId',
      'evidence_and_explanation_refresh',
      'Admin evidence surfaces should refresh from the reality-model learning outcome so operators can inspect what was learned and what propagated.',
    );
    addTarget(
      'supervisor:$environmentId',
      'learning_feedback',
      'Supervisor learning should absorb the outcome of the reality-model learning execution to improve future bounded scheduling and recommendations.',
    );
    return targets;
  }

  List<Map<String, dynamic>>
      _buildRealityModelUpdateDownstreamRepropagationTargets({
    required ExternalSourceDescriptor source,
    required Map<String, dynamic> reviewPayload,
    required Map<String, dynamic>? updateOutcomePayload,
  }) {
    final targets = <Map<String, dynamic>>[];
    final seenIds = <String>{};

    void addTarget(
      String targetId,
      String propagationKind,
      String reason,
    ) {
      if (!seenIds.add(targetId)) {
        return;
      }
      targets.add(<String, dynamic>{
        'targetId': targetId,
        'propagationKind': propagationKind,
        'reason': reason,
        'status': 'approved_for_bounded_downstream_repropagation_execution',
      });
    }

    final environmentId = reviewPayload['environmentId']?.toString() ??
        updateOutcomePayload?['environmentId']?.toString() ??
        source.metadata['environmentId']?.toString() ??
        'unknown_environment';
    addTarget(
      'admin:$environmentId',
      'evidence_and_explanation_refresh',
      'Admin evidence surfaces should refresh from the approved bounded reality-model update before any broader lower-tier follow-on actions are trusted.',
    );
    addTarget(
      'supervisor:$environmentId',
      'learning_feedback',
      'Supervisor feedback should refresh from the approved bounded reality-model update so later scheduling and bounded recommendations stay coherent.',
    );

    final upwardDomains = _deriveUpwardRepropagationDomains(source);
    for (final domainId in upwardDomains) {
      addTarget(
        'hierarchy:$domainId',
        'prior_and_explanation_delta',
        'The approved upward update carries bounded `$domainId` signals from real-world usage, so hierarchy-level `$domainId` synthesis should refresh before any narrower lower-tier follow-on lane runs.',
      );
    }

    var addedHierarchyTarget = false;
    if (upwardDomains.contains('locality')) {
      addTarget(
        'hierarchy:locality',
        'prior_and_explanation_delta',
        'This upward update came from live human or agent behavior tied to a locality-aware runtime context, so hierarchy-level locality synthesis should be refreshed first.',
      );
      addedHierarchyTarget = true;
    }

    final chatScope = source.metadata['chatScope']?.toString().trim();
    if (chatScope == 'community' || upwardDomains.contains('community')) {
      addTarget(
        'hierarchy:community',
        'prior_and_explanation_delta',
        'This upward AI2AI signal came through the community scope, so community coordination synthesis should be refreshed before any narrower downstream use.',
      );
      addedHierarchyTarget = true;
    }

    if (!addedHierarchyTarget) {
      addTarget(
        'hierarchy:generic_runtime_agents',
        'governed_learning_delta',
        'This approved bounded update should re-enter the existing hierarchy synthesis lane before any lower-tier specialization resumes.',
      );
    }

    return targets;
  }

  List<String> _deriveUpwardRepropagationDomains(
      ExternalSourceDescriptor source) {
    final domains = <String>{};
    domains.addAll(
      List<String>.from(
        source.metadata['upwardDomainHints'] ?? const <String>[],
      ).where((domain) => domain.trim().isNotEmpty),
    );
    final localityCode = source.localityCode?.trim();
    final cityCode = source.cityCode?.trim();
    if ((localityCode != null && localityCode.isNotEmpty) ||
        (cityCode != null && cityCode.isNotEmpty && cityCode != 'unknown')) {
      domains.add('locality');
    }

    final boundary = source.metadata['boundary'];
    if (boundary is Map) {
      final boundaryMap = Map<String, dynamic>.from(boundary);
      final directDomain = boundaryMap['domain']?.toString().trim();
      if (directDomain != null && directDomain.isNotEmpty) {
        domains.add(directDomain);
      }
      final directDomains = List<String>.from(
        boundaryMap['domains'] ?? const <String>[],
      );
      domains.addAll(directDomains.where((domain) => domain.trim().isNotEmpty));
      final hintedDomains = List<String>.from(
        boundaryMap['upward_domain_hints'] ?? const <String>[],
      );
      domains.addAll(hintedDomains.where((domain) => domain.trim().isNotEmpty));
    }

    final scope = source.metadata['chatScope']?.toString().trim();
    if (scope == 'community') {
      domains.add('community');
    }

    final hintText = <String>[
      source.metadata['safeSummary']?.toString() ?? '',
      source.metadata['summary']?.toString() ?? '',
      source.sourceLabel ?? '',
      source.metadata['remoteRef']?.toString() ?? '',
      if (boundary is Map) boundary['summary']?.toString() ?? '',
      if (boundary is Map) boundary['sanitized_summary']?.toString() ?? '',
    ].join(' ').toLowerCase();

    void addIfMatches(String domainId, List<String> keywords) {
      for (final keyword in keywords) {
        if (hintText.contains(keyword)) {
          domains.add(domainId);
          return;
        }
      }
    }

    addIfMatches('event', <String>[
      'event',
      'concert',
      'festival',
      'show',
      'gig',
    ]);
    addIfMatches('place', <String>[
      'place',
      'spot',
      'restaurant',
      'coffee',
      'cafe',
      'park',
      'museum',
    ]);
    addIfMatches('venue', <String>[
      'venue',
      'capacity',
      'occupancy',
      'entry line',
      'door policy',
    ]);
    addIfMatches('business', <String>[
      'business',
      'merchant',
      'owner',
      'shop',
      'store',
      'company',
      'sales',
      'revenue',
      'api',
    ]);
    addIfMatches('list', <String>[
      'list',
      'collection',
      'saved places',
      'top picks',
      'curation',
    ]);
    addIfMatches('mobility', <String>[
      'traffic',
      'route',
      'transit',
      'bus',
      'parking',
      'walk',
      'drive',
      'mobility',
    ]);
    addIfMatches('community', <String>[
      'community',
      'group',
      'club',
      'neighbors',
      'neighbours',
      'member',
    ]);

    final ordered = domains.toList()..sort();
    return ordered;
  }

  String _buildExecutionQueueReadme(Map<String, dynamic> payload) {
    final intakeFlowRefs = List<String>.from(
      payload['intakeFlowRefs'] ?? const <String>[],
    );
    final sidecarRefs = List<String>.from(
      payload['sidecarRefs'] ?? const <String>[],
    );
    final cityPackStructuralRef =
        payload['cityPackStructuralRef']?.toString() ?? '';
    final lines = <String>[
      '# Simulation Training Execution Queue',
      '',
      'This artifact marks an accepted simulation-training intake item as queued for governed deeper-training execution.',
      '',
      '- Environment: `${payload['environmentId'] ?? 'unknown'}`',
      '- City code: `${payload['cityCode'] ?? 'unknown'}`',
      '- Status: `${payload['status']}`',
      '- Training manifest: `${payload['trainingManifestJsonPath'] ?? 'missing'}`',
      '- Share review: `${payload['shareReviewJsonPath'] ?? 'missing'}`',
      '- Suggested training use: `${payload['suggestedTrainingUse'] ?? 'unspecified'}`',
      '- Learning pathway: `${payload['learningPathway'] ?? 'governed_reality_model_learning'}`',
      '- City-pack structural ref: `${cityPackStructuralRef.isEmpty ? 'not recorded' : cityPackStructuralRef}`',
      '- Intake flows: ${intakeFlowRefs.isEmpty ? 'none recorded' : intakeFlowRefs.join(', ')}',
      '- Sidecars: ${sidecarRefs.isEmpty ? 'none recorded' : sidecarRefs.join(', ')}',
      '',
      'The next execution surface should consume this queue item, run reality-model learning first, emit run receipts, and only then derive any lower-tier propagation.',
    ];
    return lines.join('\n');
  }

  String _buildLearningExecutionReadme(Map<String, dynamic> payload) {
    final kernelStates = List<Map<String, dynamic>>.from(
      payload['kernelStates'] ?? const <Map<String, dynamic>>[],
    );
    final lines = <String>[
      '# Reality-Model Learning Execution',
      '',
      'This artifact makes the learning direction explicit for an accepted simulation-training intake item.',
      '',
      '- Environment: `${payload['environmentId'] ?? 'unknown'}`',
      '- City code: `${payload['cityCode'] ?? 'unknown'}`',
      '- Status: `${payload['status']}`',
      '- Learning authority: `${payload['learningAuthority']}`',
      '- Learning pathway: `${payload['learningPathway']}`',
      '- Suggested training use: `${payload['suggestedTrainingUse'] ?? 'unspecified'}`',
      '- Training manifest: `${payload['trainingManifestJsonPath'] ?? 'missing'}`',
      '- Share review: `${payload['shareReviewJsonPath'] ?? 'missing'}`',
      '',
      '## Rule',
      '',
      'The reality model learns from this simulation first. Lower-tier agents may only receive governed propagated outcomes after the resulting reality-model learning outcome is available.',
      '',
      '## Kernel states',
      '',
      if (kernelStates.isEmpty) '- none recorded',
      ...kernelStates.map(
        (state) =>
            '- `${state['kernelId'] ?? 'unknown'}` `${state['status'] ?? 'unknown'}`: ${state['reason'] ?? 'No reason recorded.'}',
      ),
    ];
    return lines.join('\n');
  }

  String _buildLearningOutcomeReadme(Map<String, dynamic> payload) {
    final deltas = List<String>.from(
      payload['learningDeltas'] ?? const <String>[],
    );
    final domainCoverage = Map<String, dynamic>.from(
      payload['domainCoverage'] ?? const <String, dynamic>{},
    );
    final lines = <String>[
      '# Reality-Model Learning Outcome',
      '',
      '- Environment: `${payload['environmentId'] ?? 'unknown'}`',
      '- City code: `${payload['cityCode'] ?? 'unknown'}`',
      '- Status: `${payload['status'] ?? 'unknown'}`',
      '- Learning authority: `${payload['learningAuthority'] ?? 'reality_model'}`',
      '- Learning pathway: `${payload['learningPathway'] ?? 'governed_reality_model_learning'}`',
      '- Share review: `${payload['shareReviewJsonPath'] ?? 'missing'}`',
      '- Request count: `${payload['requestCount'] ?? 0}`',
      '- Recommendation count: `${payload['recommendationCount'] ?? 0}`',
      if (payload['averageConfidence'] != null)
        '- Average confidence: `${payload['averageConfidence']}`',
      '',
      '## Summary',
      '',
      payload['summary']?.toString() ?? 'No summary recorded.',
      '',
      '## Domain coverage',
      '',
      if (domainCoverage.isEmpty) '- none recorded',
      ...domainCoverage.entries.map(
        (entry) => '- `${entry.key}`: `${entry.value}` requests',
      ),
      '',
      '## Learning deltas',
      '',
      if (deltas.isEmpty) '- none recorded',
      ...deltas.map((entry) => '- $entry'),
      '',
      'Downstream lower-tier updates remain governed. They may only proceed from this outcome and must not train directly from the raw simulation bundle.',
    ];
    return lines.join('\n');
  }

  String _buildPropagationReceiptReadme(Map<String, dynamic> payload) {
    final lines = <String>[
      '# Downstream Propagation Receipt',
      '',
      '- Source: `${payload['sourceId'] ?? 'unknown'}`',
      '- Executed at: `${payload['executedAt'] ?? 'unknown'}`',
      '- Target: `${payload['targetId'] ?? 'unknown'}`',
      '- Propagation kind: `${payload['propagationKind'] ?? 'unknown'}`',
      '- Status: `${payload['status'] ?? 'unknown'}`',
      '- Learning outcome: `${payload['learningOutcomeJsonPath'] ?? 'missing'}`',
      '- Propagation plan: `${payload['planPath'] ?? 'missing'}`',
      '',
      payload['reason']?.toString() ?? 'No reason recorded.',
      '',
      'This receipt exists because the operator approved a governed downstream propagation target after the reality model completed its local learning outcome.',
    ];
    return lines.join('\n');
  }

  List<SignatureHealthLearningOutcomeItem> _buildLearningOutcomeItems(
    List<ExternalSourceDescriptor> sources,
  ) {
    final items = <SignatureHealthLearningOutcomeItem>[];
    for (final source in sources) {
      final outcomePath =
          source.metadata['realityModelLearningOutcomeJsonPath']?.toString();
      final propagationPlanPath =
          source.metadata['downstreamPropagationPlanJsonPath']?.toString();
      if ((outcomePath == null || outcomePath.isEmpty) &&
          (propagationPlanPath == null || propagationPlanPath.isEmpty)) {
        continue;
      }
      final outcomePayload = _readJsonObject(outcomePath);
      final propagationPayload = _readJsonObject(propagationPlanPath);
      final adminEvidenceRefreshPath =
          source.metadata['adminEvidenceRefreshSnapshotJsonPath']?.toString();
      final adminEvidenceRefreshPayload =
          _readJsonObject(adminEvidenceRefreshPath);
      final supervisorFeedbackPath = source
          .metadata['supervisorLearningFeedbackStateJsonPath']
          ?.toString();
      final supervisorFeedbackPayload = _readJsonObject(supervisorFeedbackPath);
      final targets = List<Map<String, dynamic>>.from(
        (propagationPayload?['proposedTargets'] as List? ?? const <dynamic>[])
            .whereType<Map>(),
      ).map((entry) {
        final target = Map<String, dynamic>.from(entry);
        final targetId = target['targetId']?.toString() ?? 'unknown_target';
        final targetLaneArtifactJsonPath =
            target['laneArtifactJsonPath']?.toString();
        return SignatureHealthPropagationTarget(
          targetId: targetId,
          propagationKind:
              target['propagationKind']?.toString() ?? 'unknown_propagation',
          reason: target['reason']?.toString() ?? 'No reason recorded.',
          status: target['status']?.toString() ?? 'unknown',
          receiptJsonPath: target['receiptJsonPath']?.toString(),
          receiptReadmePath: target['receiptReadmePath']?.toString(),
          laneArtifactJsonPath: targetLaneArtifactJsonPath,
          laneArtifactReadmePath: target['laneArtifactReadmePath']?.toString(),
          hierarchyDomainDeltaSummary: targetId.startsWith('hierarchy:')
              ? _buildHierarchyDomainDeltaSummary(
                  targetLaneArtifactJsonPath,
                  source,
                )
              : null,
          personalAgentPersonalizationSummary:
              targetId.startsWith('personal_agent:')
                  ? _buildPersonalAgentPersonalizationSummary(
                      targetLaneArtifactJsonPath,
                      source,
                    )
                  : null,
          temporalLineage: _buildTemporalLineageSummary(
            target['temporalLineage'],
          ),
        );
      }).toList(growable: false)
        ..sort((a, b) => a.targetId.compareTo(b.targetId));
      items.add(
        SignatureHealthLearningOutcomeItem(
          sourceId: source.id,
          environmentId: outcomePayload?['environmentId']?.toString() ??
              source.metadata['environmentId']?.toString() ??
              'unknown_environment',
          cityCode: outcomePayload?['cityCode']?.toString() ??
              source.cityCode ??
              'unknown',
          learningPathway: outcomePayload?['learningPathway']?.toString() ??
              source.metadata['learningPathway']?.toString() ??
              'governed_reality_model_learning',
          outcomeStatus: outcomePayload?['status']?.toString() ??
              source.metadata['realityModelLearningExecutionStatus']
                  ?.toString() ??
              'unknown',
          summary: outcomePayload?['summary']?.toString() ??
              'Reality-model learning outcome is available for governed downstream review.',
          learningOutcomeJsonPath: outcomePath,
          downstreamPropagationPlanJsonPath: propagationPlanPath,
          adminEvidenceRefreshSnapshotJsonPath: adminEvidenceRefreshPath,
          supervisorLearningFeedbackStateJsonPath: supervisorFeedbackPath,
          adminEvidenceRefreshSummary: adminEvidenceRefreshPayload == null
              ? null
              : SignatureHealthAdminEvidenceRefreshSummary(
                  status: adminEvidenceRefreshPayload['status']?.toString() ??
                      'unknown',
                  environmentId: adminEvidenceRefreshPayload['environmentId']
                          ?.toString() ??
                      source.metadata['environmentId']?.toString() ??
                      'unknown_environment',
                  cityCode: adminEvidenceRefreshPayload['cityCode']?.toString(),
                  summary: adminEvidenceRefreshPayload['summary']?.toString() ??
                      'Admin evidence refresh is available.',
                  requestCount:
                      (adminEvidenceRefreshPayload['requestCount'] as num?)
                              ?.toInt() ??
                          0,
                  recommendationCount:
                      (adminEvidenceRefreshPayload['recommendationCount']
                                  as num?)
                              ?.toInt() ??
                          0,
                  averageConfidence:
                      (adminEvidenceRefreshPayload['averageConfidence'] as num?)
                          ?.toDouble(),
                  domainCoverage: Map<String, dynamic>.from(
                    adminEvidenceRefreshPayload['domainCoverage'] ??
                        const <String, dynamic>{},
                  ),
                  learningDeltas: List<String>.from(
                    adminEvidenceRefreshPayload['learningDeltas'] ??
                        const <String>[],
                  ),
                  jsonPath: adminEvidenceRefreshPath,
                  temporalLineage: _buildTemporalLineageSummary(
                    adminEvidenceRefreshPayload['temporalLineage'],
                  ),
                ),
          supervisorFeedbackSummary: supervisorFeedbackPayload == null
              ? null
              : SignatureHealthSupervisorFeedbackSummary(
                  status: supervisorFeedbackPayload['status']?.toString() ??
                      'unknown',
                  environmentId:
                      supervisorFeedbackPayload['environmentId']?.toString() ??
                          source.metadata['environmentId']?.toString() ??
                          'unknown_environment',
                  feedbackSummary: supervisorFeedbackPayload['feedbackSummary']
                          ?.toString() ??
                      'Supervisor feedback is available.',
                  boundedRecommendation:
                      supervisorFeedbackPayload['boundedRecommendation']
                              ?.toString() ??
                          'unknown',
                  requestCount:
                      (supervisorFeedbackPayload['requestCount'] as num?)
                              ?.toInt() ??
                          0,
                  recommendationCount:
                      (supervisorFeedbackPayload['recommendationCount'] as num?)
                              ?.toInt() ??
                          0,
                  averageConfidence:
                      (supervisorFeedbackPayload['averageConfidence'] as num?)
                          ?.toDouble(),
                  jsonPath: supervisorFeedbackPath,
                  temporalLineage: _buildTemporalLineageSummary(
                    supervisorFeedbackPayload['temporalLineage'],
                  ),
                ),
          updatedAt: source.updatedAt,
          propagationTargets: targets,
          temporalLineage: _buildTemporalLineageSummary(
            outcomePayload?['temporalLineage'],
          ),
        ),
      );
    }
    items.sort((a, b) {
      final aUpdated = a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bUpdated = b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bUpdated.compareTo(aUpdated);
    });
    return items;
  }

  Future<List<SignatureHealthUpwardLearningItem>> _buildUpwardLearningItems(
    List<ExternalSourceDescriptor> sources,
  ) async {
    final items = <SignatureHealthUpwardLearningItem>[];
    for (final source in sources) {
      final hierarchyPlanPath =
          source.metadata['upwardHierarchySynthesisPlanJsonPath']?.toString();
      final hierarchyOutcomePath = source
          .metadata['upwardHierarchySynthesisOutcomeJsonPath']
          ?.toString();
      final handoffPath =
          source.metadata['realityModelAgentHandoffJsonPath']?.toString();
      final realityModelOutcomePath =
          source.metadata['realityModelAgentOutcomeJsonPath']?.toString();
      final realityModelTruthReviewPath =
          source.metadata['realityModelTruthReviewJsonPath']?.toString();
      final realityModelUpdateCandidatePath =
          source.metadata['realityModelUpdateCandidateJsonPath']?.toString();
      final realityModelUpdateDecisionPath =
          source.metadata['realityModelUpdateDecisionJsonPath']?.toString();
      final realityModelUpdateOutcomePath =
          source.metadata['realityModelUpdateOutcomeJsonPath']?.toString();
      final realityModelUpdateAdminBriefPath =
          source.metadata['realityModelUpdateAdminBriefJsonPath']?.toString();
      final realityModelUpdateSupervisorBriefPath = source
          .metadata['realityModelUpdateSupervisorBriefJsonPath']
          ?.toString();
      final realityModelUpdateSimulationSuggestionPath = source
          .metadata['realityModelUpdateSimulationSuggestionJsonPath']
          ?.toString();
      final realityModelUpdateSimulationRequestPath = source
          .metadata['realityModelUpdateSimulationRequestJsonPath']
          ?.toString();
      final realityModelUpdateSimulationOutcomePath = source
          .metadata['realityModelUpdateSimulationOutcomeJsonPath']
          ?.toString();
      final realityModelUpdateDownstreamRepropagationReviewPath = source
          .metadata['realityModelUpdateDownstreamRepropagationReviewJsonPath']
          ?.toString();
      final realityModelUpdateDownstreamRepropagationDecisionPath = source
          .metadata['realityModelUpdateDownstreamRepropagationDecisionJsonPath']
          ?.toString();
      final realityModelUpdateDownstreamRepropagationOutcomePath = source
          .metadata['realityModelUpdateDownstreamRepropagationOutcomeJsonPath']
          ?.toString();
      final realityModelUpdateDownstreamRepropagationPlanPath = source
          .metadata['realityModelUpdateDownstreamRepropagationPlanJsonPath']
          ?.toString();
      final realityModelUpdateDownstreamRepropagationPlan = _readJsonObject(
        realityModelUpdateDownstreamRepropagationPlanPath,
      );
      final releasedTargetIds = List<String>.from(
        source.metadata[
                'realityModelUpdateDownstreamRepropagationReleasedTargetIds'] ??
            List<Map<String, dynamic>>.from(
              (realityModelUpdateDownstreamRepropagationPlan?['releasedTargets']
                          as List? ??
                      const <dynamic>[])
                  .whereType<Map>(),
            ).map((target) => target['targetId']?.toString() ?? '').where(
                  (targetId) => targetId.isNotEmpty,
                ),
      );
      if ((hierarchyPlanPath == null || hierarchyPlanPath.isEmpty) &&
          (hierarchyOutcomePath == null || hierarchyOutcomePath.isEmpty) &&
          (handoffPath == null || handoffPath.isEmpty) &&
          (realityModelOutcomePath == null ||
              realityModelOutcomePath.isEmpty) &&
          (realityModelTruthReviewPath == null ||
              realityModelTruthReviewPath.isEmpty) &&
          (realityModelUpdateCandidatePath == null ||
              realityModelUpdateCandidatePath.isEmpty) &&
          (realityModelUpdateDecisionPath == null ||
              realityModelUpdateDecisionPath.isEmpty) &&
          (realityModelUpdateOutcomePath == null ||
              realityModelUpdateOutcomePath.isEmpty) &&
          (realityModelUpdateAdminBriefPath == null ||
              realityModelUpdateAdminBriefPath.isEmpty) &&
          (realityModelUpdateSupervisorBriefPath == null ||
              realityModelUpdateSupervisorBriefPath.isEmpty) &&
          (realityModelUpdateSimulationSuggestionPath == null ||
              realityModelUpdateSimulationSuggestionPath.isEmpty) &&
          (realityModelUpdateSimulationRequestPath == null ||
              realityModelUpdateSimulationRequestPath.isEmpty) &&
          (realityModelUpdateSimulationOutcomePath == null ||
              realityModelUpdateSimulationOutcomePath.isEmpty) &&
          (realityModelUpdateDownstreamRepropagationReviewPath == null ||
              realityModelUpdateDownstreamRepropagationReviewPath.isEmpty) &&
          (realityModelUpdateDownstreamRepropagationDecisionPath == null ||
              realityModelUpdateDownstreamRepropagationDecisionPath.isEmpty) &&
          (realityModelUpdateDownstreamRepropagationOutcomePath == null ||
              realityModelUpdateDownstreamRepropagationOutcomePath.isEmpty) &&
          (realityModelUpdateDownstreamRepropagationPlanPath == null ||
              realityModelUpdateDownstreamRepropagationPlanPath.isEmpty)) {
        continue;
      }
      final hierarchyPlan = _readJsonObject(hierarchyPlanPath);
      final hierarchyOutcome = _readJsonObject(hierarchyOutcomePath);
      final handoff = _readJsonObject(handoffPath);
      final realityModelOutcome = _readJsonObject(realityModelOutcomePath);
      final realityModelTruthReview =
          _readJsonObject(realityModelTruthReviewPath);
      final realityModelUpdateDecision =
          _readJsonObject(realityModelUpdateDecisionPath);
      final realityModelUpdateOutcome =
          _readJsonObject(realityModelUpdateOutcomePath);
      final chatObservationSummary = await _buildChatObservationSummary(
        source: source,
      );
      items.add(
        SignatureHealthUpwardLearningItem(
          sourceId: source.id,
          sourceKind: realityModelUpdateOutcome?['sourceKind']?.toString() ??
              realityModelUpdateDecision?['sourceKind']?.toString() ??
              realityModelTruthReview?['sourceKind']?.toString() ??
              realityModelOutcome?['sourceKind']?.toString() ??
              handoff?['sourceKind']?.toString() ??
              hierarchyOutcome?['sourceKind']?.toString() ??
              hierarchyPlan?['sourceKind']?.toString() ??
              source.metadata['sourceKind']?.toString() ??
              source.sourceProvider,
          learningDirection: realityModelUpdateOutcome?['learningDirection']
                  ?.toString() ??
              realityModelUpdateDecision?['learningDirection']?.toString() ??
              realityModelTruthReview?['learningDirection']?.toString() ??
              realityModelOutcome?['learningDirection']?.toString() ??
              handoff?['learningDirection']?.toString() ??
              hierarchyOutcome?['learningDirection']?.toString() ??
              hierarchyPlan?['learningDirection']?.toString() ??
              source.metadata['learningDirection']?.toString() ??
              'upward_personal_agent_to_reality_model',
          learningPathway:
              realityModelUpdateOutcome?['learningPathway']?.toString() ??
                  realityModelUpdateDecision?['learningPathway']?.toString() ??
                  realityModelTruthReview?['learningPathway']?.toString() ??
                  realityModelOutcome?['learningPathway']?.toString() ??
                  handoff?['learningPathway']?.toString() ??
                  hierarchyOutcome?['learningPathway']?.toString() ??
                  hierarchyPlan?['learningPathway']?.toString() ??
                  source.metadata['learningPathway']?.toString() ??
                  'governed_upward_reality_model_learning',
          convictionTier:
              realityModelUpdateOutcome?['convictionTier']?.toString() ??
                  realityModelUpdateDecision?['convictionTier']?.toString() ??
                  realityModelTruthReview?['convictionTier']?.toString() ??
                  realityModelOutcome?['convictionTier']?.toString() ??
                  handoff?['convictionTier']?.toString() ??
                  hierarchyOutcome?['convictionTier']?.toString() ??
                  hierarchyPlan?['convictionTier']?.toString() ??
                  source.metadata['convictionTier']?.toString() ??
                  'unknown',
          status: realityModelUpdateOutcome?['status']?.toString() ??
              realityModelUpdateDecision?['status']?.toString() ??
              realityModelTruthReview?['status']?.toString() ??
              realityModelOutcome?['status']?.toString() ??
              handoff?['status']?.toString() ??
              hierarchyOutcome?['status']?.toString() ??
              hierarchyPlan?['status']?.toString() ??
              source.metadata['realityModelUpdateStatus']?.toString() ??
              source.metadata['realityModelTruthReviewStatus']?.toString() ??
              source.metadata['realityModelAgentOutcomeStatus']?.toString() ??
              source.metadata['upwardLearningHandoffStatus']?.toString() ??
              'unknown',
          summary: realityModelUpdateOutcome?['summary']?.toString() ??
              realityModelUpdateDecision?['summary']?.toString() ??
              realityModelTruthReview?['summary']?.toString() ??
              realityModelOutcome?['summary']?.toString() ??
              handoff?['summary']?.toString() ??
              hierarchyOutcome?['summary']?.toString() ??
              hierarchyPlan?['summary']?.toString() ??
              source.metadata['safeSummary']?.toString() ??
              'Governed upward learning handoff is available for reality-model-agent review.',
          environmentId:
              realityModelUpdateOutcome?['environmentId']?.toString() ??
                  realityModelUpdateDecision?['environmentId']?.toString() ??
                  realityModelTruthReview?['environmentId']?.toString() ??
                  realityModelOutcome?['environmentId']?.toString() ??
                  handoff?['environmentId']?.toString() ??
                  hierarchyOutcome?['environmentId']?.toString() ??
                  hierarchyPlan?['environmentId']?.toString() ??
                  source.metadata['environmentId']?.toString() ??
                  'unknown_environment',
          cityCode: realityModelUpdateOutcome?['cityCode']?.toString() ??
              realityModelUpdateDecision?['cityCode']?.toString() ??
              realityModelTruthReview?['cityCode']?.toString() ??
              realityModelOutcome?['cityCode']?.toString() ??
              handoff?['cityCode']?.toString() ??
              hierarchyOutcome?['cityCode']?.toString() ??
              hierarchyPlan?['cityCode']?.toString() ??
              source.cityCode ??
              'unknown',
          hierarchyPath: List<String>.from(
            realityModelUpdateOutcome?['hierarchyPath'] ??
                realityModelUpdateDecision?['hierarchyPath'] ??
                realityModelTruthReview?['hierarchyPath'] ??
                realityModelOutcome?['hierarchyPath'] ??
                handoff?['hierarchyPath'] ??
                hierarchyOutcome?['hierarchyPath'] ??
                hierarchyPlan?['hierarchyPath'] ??
                source.metadata['hierarchyPath'] ??
                const <String>[],
          ),
          hierarchySynthesisPlanJsonPath: hierarchyPlanPath,
          hierarchySynthesisOutcomeJsonPath: hierarchyOutcomePath,
          realityModelAgentHandoffJsonPath: handoffPath,
          realityModelAgentOutcomeJsonPath: realityModelOutcomePath,
          realityModelTruthReviewJsonPath: realityModelTruthReviewPath,
          realityModelUpdateCandidateJsonPath: realityModelUpdateCandidatePath,
          realityModelUpdateDecisionJsonPath: realityModelUpdateDecisionPath,
          realityModelUpdateOutcomeJsonPath: realityModelUpdateOutcomePath,
          realityModelUpdateAdminBriefJsonPath:
              realityModelUpdateAdminBriefPath,
          realityModelUpdateSupervisorBriefJsonPath:
              realityModelUpdateSupervisorBriefPath,
          realityModelUpdateSimulationSuggestionJsonPath:
              realityModelUpdateSimulationSuggestionPath,
          realityModelUpdateSimulationRequestJsonPath:
              realityModelUpdateSimulationRequestPath,
          realityModelUpdateSimulationOutcomeJsonPath:
              realityModelUpdateSimulationOutcomePath,
          realityModelUpdateDownstreamRepropagationReviewJsonPath:
              realityModelUpdateDownstreamRepropagationReviewPath,
          realityModelUpdateDownstreamRepropagationDecisionJsonPath:
              realityModelUpdateDownstreamRepropagationDecisionPath,
          realityModelUpdateDownstreamRepropagationOutcomeJsonPath:
              realityModelUpdateDownstreamRepropagationOutcomePath,
          realityModelUpdateDownstreamRepropagationPlanJsonPath:
              realityModelUpdateDownstreamRepropagationPlanPath,
          truthIntegrationStatus:
              realityModelTruthReview?['truthIntegrationStatus']?.toString() ??
                  realityModelOutcome?['truthIntegrationStatus']?.toString() ??
                  source.metadata['realityModelTruthReviewStatus']?.toString(),
          truthReviewResolution:
              realityModelTruthReview?['truthReviewResolution']?.toString() ??
                  source.metadata['realityModelTruthReviewResolution']
                      ?.toString(),
          updateCandidateResolution:
              realityModelUpdateDecision?['candidateResolution']?.toString() ??
                  source.metadata['realityModelUpdateCandidateResolution']
                      ?.toString(),
          downstreamRepropagationResolution: source
              .metadata['realityModelUpdateDownstreamRepropagationResolution']
              ?.toString(),
          downstreamRepropagationReleasedTargetIds: releasedTargetIds,
          upwardDomainHints: List<String>.from(
            source.metadata['upwardDomainHints'] ?? const <String>[],
          ),
          upwardReferencedEntities: List<String>.from(
            source.metadata['upwardReferencedEntities'] ?? const <String>[],
          ),
          upwardQuestions: List<String>.from(
            source.metadata['upwardQuestions'] ?? const <String>[],
          ),
          upwardSignalTags: List<String>.from(
            source.metadata['upwardSignalTags'] ?? const <String>[],
          ),
          upwardPreferenceSignals:
              (source.metadata['upwardPreferenceSignals'] as List? ??
                      const <dynamic>[])
                  .whereType<Map>()
                  .map((value) => Map<String, dynamic>.from(value))
                  .toList(growable: false),
          followUpPromptQuestion: source.metadata['promptQuestion']?.toString(),
          followUpResponseText: source.metadata['responseText']?.toString(),
          followUpCompletionMode: source.metadata['completionMode']?.toString(),
          chatObservationSummary: chatObservationSummary,
          updatedAt: source.updatedAt,
          temporalLineage: _buildTemporalLineageSummary(
                realityModelUpdateOutcome?['temporalLineage'] ??
                    realityModelUpdateDecision?['temporalLineage'] ??
                    realityModelTruthReview?['temporalLineage'] ??
                    realityModelOutcome?['temporalLineage'] ??
                    handoff?['temporalLineage'] ??
                    hierarchyOutcome?['temporalLineage'] ??
                    hierarchyPlan?['temporalLineage'],
              ) ??
              _buildTemporalLineageSummary(source.metadata['temporalLineage']),
        ),
      );
    }
    items.sort((a, b) {
      final attentionCompare =
          b.chatAttentionScore.compareTo(a.chatAttentionScore);
      if (attentionCompare != 0) {
        return attentionCompare;
      }
      final aUpdated = a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bUpdated = b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bUpdated.compareTo(aUpdated);
    });
    return items;
  }

  Future<SignatureHealthChatObservationSummary?> _buildChatObservationSummary({
    required ExternalSourceDescriptor source,
  }) async {
    final observationService = _userGovernedLearningChatObservationService;
    if (observationService == null) {
      return null;
    }
    final envelopeId = _governedLearningEnvelopeIdFromSourceMetadata(
      source.metadata,
    );
    final ownerUserId = source.ownerUserId.trim();
    if (envelopeId == null || envelopeId.isEmpty || ownerUserId.isEmpty) {
      return null;
    }
    final receipts = await observationService.listReceiptsForEnvelope(
      ownerUserId: ownerUserId,
      envelopeId: envelopeId,
      limit: 25,
    );
    if (receipts.isEmpty) {
      return null;
    }
    final latest = receipts.first;
    final openRequestedFollowUpCount = receipts
        .where(
          (receipt) =>
              receipt.outcome ==
                  GovernedLearningChatObservationOutcome.requestedFollowUp &&
              receipt.attentionStatus ==
                  GovernedLearningChatObservationAttentionStatus.pending,
        )
        .length;
    final openCorrectedCount = receipts
        .where(
          (receipt) =>
              receipt.outcome ==
                  GovernedLearningChatObservationOutcome.correctedRecord &&
              receipt.attentionStatus ==
                  GovernedLearningChatObservationAttentionStatus.pending,
        )
        .length;
    final openForgotCount = receipts
        .where(
          (receipt) =>
              receipt.outcome ==
                  GovernedLearningChatObservationOutcome.forgotRecord &&
              receipt.attentionStatus ==
                  GovernedLearningChatObservationAttentionStatus.pending,
        )
        .length;
    final openStoppedUsingCount = receipts
        .where(
          (receipt) =>
              receipt.outcome ==
                  GovernedLearningChatObservationOutcome.stoppedUsingSignal &&
              receipt.attentionStatus ==
                  GovernedLearningChatObservationAttentionStatus.pending,
        )
        .length;
    return SignatureHealthChatObservationSummary(
      totalCount: receipts.length,
      acknowledgedCount: receipts
          .where(
            (receipt) =>
                receipt.outcome ==
                GovernedLearningChatObservationOutcome.acknowledged,
          )
          .length,
      requestedFollowUpCount: receipts
          .where(
            (receipt) =>
                receipt.outcome ==
                GovernedLearningChatObservationOutcome.requestedFollowUp,
          )
          .length,
      correctedCount: receipts
          .where(
            (receipt) =>
                receipt.outcome ==
                GovernedLearningChatObservationOutcome.correctedRecord,
          )
          .length,
      forgotCount: receipts
          .where(
            (receipt) =>
                receipt.outcome ==
                GovernedLearningChatObservationOutcome.forgotRecord,
          )
          .length,
      stoppedUsingCount: receipts
          .where(
            (receipt) =>
                receipt.outcome ==
                GovernedLearningChatObservationOutcome.stoppedUsingSignal,
          )
          .length,
      openRequestedFollowUpCount: openRequestedFollowUpCount,
      openCorrectedCount: openCorrectedCount,
      openForgotCount: openForgotCount,
      openStoppedUsingCount: openStoppedUsingCount,
      latestOutcome: latest.outcome,
      latestValidationStatus: latest.validationStatus,
      latestGovernanceStatus: latest.governanceStatus,
      latestAttentionStatus: latest.attentionStatus,
      latestRecordedAt: latest.recordedAtUtc,
      latestFocus: latest.focus,
      latestQuestion: latest.userQuestion,
      latestGovernanceStage: latest.governanceStage,
      latestGovernanceReason: latest.governanceReason,
      latestAttentionDispositionSummary: _buildAttentionDispositionSummary(
        latest,
      ),
    );
  }

  String? _buildAttentionDispositionSummary(
    GovernedLearningChatObservationReceipt receipt,
  ) {
    final attentionStatus = receipt.attentionStatus;
    if (attentionStatus ==
        GovernedLearningChatObservationAttentionStatus.pending) {
      return null;
    }
    final stage = switch (receipt.governanceStage) {
      'upward_learning_review' => 'upward learning review',
      'reality_model_truth_review' => 'reality-model truth review',
      'reality_model_update_review' => 'reality-model update review',
      final raw? when raw.trim().isNotEmpty => raw.replaceAll('_', ' '),
      _ => 'governance review',
    };
    final action = switch (receipt.governanceStatus) {
      GovernedLearningChatObservationGovernanceStatus.reinforcedByGovernance =>
        'approved the governed-learning path',
      GovernedLearningChatObservationGovernanceStatus.constrainedByGovernance =>
        'held the governed-learning path for more evidence',
      GovernedLearningChatObservationGovernanceStatus.overruledByGovernance =>
        'overruled the governed-learning path',
      GovernedLearningChatObservationGovernanceStatus.pending =>
        'touched the governed-learning path',
    };
    final disposition = switch (attentionStatus) {
      GovernedLearningChatObservationAttentionStatus.satisfiedByGovernance =>
        'attention satisfied',
      GovernedLearningChatObservationAttentionStatus.clearedByGovernance =>
        'attention cleared',
      GovernedLearningChatObservationAttentionStatus.pending =>
        'attention pending',
    };
    final reason = receipt.governanceReason?.trim();
    final reasonTail =
        reason == null || reason.isEmpty ? '' : ' Reason: $reason';
    return '$disposition when $stage $action.$reasonTail';
  }

  ReplaySimulationLabOutcomeRecord? _latestLabOutcomeForTarget({
    required List<ReplaySimulationLabOutcomeRecord> outcomes,
    required String? variantId,
  }) {
    for (final outcome in outcomes) {
      if (_sameLabTarget(outcome.variantId, variantId)) {
        return outcome;
      }
    }
    return null;
  }

  ReplaySimulationLabRerunRequest? _latestLabRerunRequestForTarget({
    required List<ReplaySimulationLabRerunRequest> requests,
    required String? variantId,
  }) {
    for (final request in requests) {
      if (_sameLabTarget(request.variantId, variantId)) {
        return request;
      }
    }
    return null;
  }

  ReplaySimulationLabRerunJob? _latestLabRerunJobForTarget({
    required List<ReplaySimulationLabRerunJob> jobs,
    required String? variantId,
    String? preferredJobId,
  }) {
    if (preferredJobId != null && preferredJobId.trim().isNotEmpty) {
      for (final job in jobs) {
        if (job.jobId == preferredJobId) {
          return job;
        }
      }
    }
    for (final job in jobs) {
      if (_sameLabTarget(job.variantId, variantId)) {
        return job;
      }
    }
    return null;
  }

  SignatureHealthLabTargetTrendSummary _buildLabTargetTrendSummary({
    required List<ReplaySimulationLabOutcomeRecord> outcomes,
    required List<ReplaySimulationLabRerunJob> jobs,
    required String? variantId,
  }) {
    final targetOutcomes = outcomes
        .where((outcome) => _sameLabTarget(outcome.variantId, variantId))
        .toList(growable: false)
      ..sort((left, right) => right.recordedAt.compareTo(left.recordedAt));
    final completedJobs = jobs
        .where(
          (job) =>
              _sameLabTarget(job.variantId, variantId) &&
              job.jobStatus == 'completed',
        )
        .toList(growable: false)
      ..sort((left, right) {
        final leftTime = left.completedAt ?? left.startedAt;
        final rightTime = right.completedAt ?? right.startedAt;
        return rightTime.compareTo(leftTime);
      });
    final runtimeTrendSeverityCode =
        _labTargetRuntimeTrendSeverityCode(completedJobs);
    return SignatureHealthLabTargetTrendSummary(
      completedRerunCount: completedJobs.length,
      runtimeTrendSeverityCode: runtimeTrendSeverityCode,
      runtimeTrendSummary:
          _labTargetRuntimeTrendSummary(runtimeTrendSeverityCode),
      runtimeDeltaSummary: _labTargetRuntimeDeltaSummary(completedJobs),
      outcomeTrendSummary: _labTargetOutcomeTrendSummary(targetOutcomes),
    );
  }

  SignatureHealthLabTargetProvenanceDeltaSummary?
      _buildLabTargetProvenanceDeltaSummary({
    required List<ReplaySimulationLabOutcomeRecord> outcomes,
    required List<ReplaySimulationLabRerunJob> jobs,
    required String? variantId,
  }) {
    final points = _buildLabTargetProvenancePoints(
      outcomes: outcomes,
      jobs: jobs,
      variantId: variantId,
    );
    if (points.length < 2) {
      return null;
    }
    final latest = points[0];
    final previous = points[1];
    final details = _buildLabTargetProvenanceDeltaDetails(
      latest: latest,
      previous: previous,
    );
    if (details.isEmpty) {
      return const SignatureHealthLabTargetProvenanceDeltaSummary(
        summary:
            'Latest provenance delta is stable across the last two persisted samples.',
      );
    }
    return SignatureHealthLabTargetProvenanceDeltaSummary(
      summary:
          'Latest provenance delta highlights what changed between the latest two persisted samples.',
      details: details,
    );
  }

  SignatureHealthLabTargetProvenanceHistorySummary?
      _buildLabTargetProvenanceHistorySummary({
    required List<ReplaySimulationLabOutcomeRecord> outcomes,
    required List<ReplaySimulationLabRerunJob> jobs,
    required String? variantId,
  }) {
    final points = _buildLabTargetProvenancePoints(
      outcomes: outcomes,
      jobs: jobs,
      variantId: variantId,
    );
    if (points.isEmpty) {
      return null;
    }
    final entries = <SignatureHealthLabTargetProvenanceHistoryEntry>[];
    for (var index = 0; index < points.length - 1 && index < 2; index++) {
      final latest = points[index];
      final previous = points[index + 1];
      final details = _buildLabTargetProvenanceDeltaDetails(
        latest: latest,
        previous: previous,
      );
      entries.add(
        SignatureHealthLabTargetProvenanceHistoryEntry(
          label: '${_labTargetProvenancePointLabel(latest)} vs prior sample',
          details: details.isEmpty
              ? const <String>['No material provenance change.']
              : details,
        ),
      );
    }
    return SignatureHealthLabTargetProvenanceHistorySummary(
      sampleCount: points.length,
      entries: entries,
    );
  }

  SignatureHealthLabTargetProvenanceEmphasisSummary?
      _buildLabTargetProvenanceEmphasisSummary(
    SignatureHealthLabTargetProvenanceHistorySummary? summary,
  ) {
    if (summary == null || summary.entries.isEmpty) {
      return null;
    }
    var changeEntryCount = 0;
    var maxChangeCount = 0;
    var hasStructuralRefChange = false;
    for (final entry in summary.entries) {
      final detailCount = entry.details.where((detail) {
        return detail.trim().isNotEmpty &&
            detail != 'No material provenance change.';
      }).length;
      if (detailCount > 0) {
        changeEntryCount += 1;
        if (detailCount > maxChangeCount) {
          maxChangeCount = detailCount;
        }
      }
      if (entry.details
          .any((detail) => detail.startsWith('City-pack structural ref:'))) {
        hasStructuralRefChange = true;
      }
    }
    if (changeEntryCount == 0) {
      return const SignatureHealthLabTargetProvenanceEmphasisSummary(
        severityCode: 'stable',
        summary:
            'Provenance churn: Stable realism-pack inputs across recent persisted samples.',
      );
    }
    if (hasStructuralRefChange || maxChangeCount >= 3) {
      return const SignatureHealthLabTargetProvenanceEmphasisSummary(
        severityCode: 'high_churn',
        summary:
            'Provenance churn: High realism-pack churn across recent persisted samples.',
      );
    }
    if (changeEntryCount >= 2 || maxChangeCount >= 2) {
      return const SignatureHealthLabTargetProvenanceEmphasisSummary(
        severityCode: 'elevated_churn',
        summary:
            'Provenance churn: Elevated realism-pack churn across recent persisted samples.',
      );
    }
    return const SignatureHealthLabTargetProvenanceEmphasisSummary(
      severityCode: 'targeted_change',
      summary:
          'Provenance churn: Targeted realism-pack changes detected in recent persisted samples.',
    );
  }

  SignatureHealthLabTargetBoundedAlertSummary?
      _buildLabTargetBoundedAlertSummary({
    required SignatureHealthLabTargetTrendSummary? trendSummary,
    required SignatureHealthLabTargetProvenanceEmphasisSummary?
        provenanceEmphasisSummary,
  }) {
    final runtimeSeverity = trendSummary?.runtimeTrendSeverityCode;
    final provenanceSeverity = provenanceEmphasisSummary?.severityCode;
    final runtimeRegressing = runtimeSeverity == 'regressing';
    final runtimeUnstable =
        runtimeSeverity == 'regressing' || runtimeSeverity == 'mixed';
    final runtimeWatch = runtimeUnstable || runtimeSeverity == 'low_confidence';
    final provenanceHigh = provenanceSeverity == 'high_churn' ||
        provenanceSeverity == 'elevated_churn';
    final provenanceWatch =
        provenanceHigh || provenanceSeverity == 'targeted_change';
    if (runtimeRegressing && provenanceHigh) {
      return const SignatureHealthLabTargetBoundedAlertSummary(
        severityCode: 'spiking',
        summary:
            'Bounded alert: runtime regression is spiking alongside elevated realism-pack churn.',
      );
    }
    if (runtimeUnstable && provenanceHigh) {
      return const SignatureHealthLabTargetBoundedAlertSummary(
        severityCode: 'elevated',
        summary:
            'Bounded alert: runtime instability is coinciding with elevated realism-pack churn.',
      );
    }
    if (runtimeWatch && provenanceWatch) {
      return const SignatureHealthLabTargetBoundedAlertSummary(
        severityCode: 'watch',
        summary:
            'Bounded alert: review this lane closely because runtime instability and provenance churn are both present.',
      );
    }
    return null;
  }

  List<_LabTargetProvenancePoint> _buildLabTargetProvenancePoints({
    required List<ReplaySimulationLabOutcomeRecord> outcomes,
    required List<ReplaySimulationLabRerunJob> jobs,
    required String? variantId,
  }) {
    return <_LabTargetProvenancePoint>[
      for (final outcome in outcomes)
        if (_sameLabTarget(outcome.variantId, variantId))
          _LabTargetProvenancePoint(
            recordedAt: outcome.recordedAt,
            sourceLabel: 'Lab outcome',
            sidecarRefs: outcome.realismProvenance.sidecarRefs,
            trainingArtifactFamilies:
                outcome.realismProvenance.trainingArtifactFamilies,
            cityPackStructuralRef:
                outcome.realismProvenance.cityPackStructuralRef,
          ),
      for (final job in jobs)
        if (_sameLabTarget(job.variantId, variantId))
          _LabTargetProvenancePoint(
            recordedAt: job.completedAt ?? job.startedAt,
            sourceLabel: 'Completed rerun',
            sidecarRefs: job.realismProvenance.sidecarRefs,
            trainingArtifactFamilies:
                job.realismProvenance.trainingArtifactFamilies,
            cityPackStructuralRef: job.realismProvenance.cityPackStructuralRef,
          ),
    ]..sort((left, right) => right.recordedAt.compareTo(left.recordedAt));
  }

  List<String> _buildLabTargetProvenanceDeltaDetails({
    required _LabTargetProvenancePoint latest,
    required _LabTargetProvenancePoint previous,
  }) {
    final addedSidecars =
        _stringListDifference(latest.sidecarRefs, previous.sidecarRefs);
    final removedSidecars =
        _stringListDifference(previous.sidecarRefs, latest.sidecarRefs);
    final addedFamilies = _stringListDifference(
      latest.trainingArtifactFamilies,
      previous.trainingArtifactFamilies,
    );
    final removedFamilies = _stringListDifference(
      previous.trainingArtifactFamilies,
      latest.trainingArtifactFamilies,
    );
    return <String>[
      if (addedSidecars.isNotEmpty)
        'Added sidecars: ${addedSidecars.join(' • ')}',
      if (removedSidecars.isNotEmpty)
        'Removed sidecars: ${removedSidecars.join(' • ')}',
      if (addedFamilies.isNotEmpty)
        'Added artifact families: ${addedFamilies.join(' • ')}',
      if (removedFamilies.isNotEmpty)
        'Removed artifact families: ${removedFamilies.join(' • ')}',
      if (latest.cityPackStructuralRef != previous.cityPackStructuralRef)
        'City-pack structural ref: ${previous.cityPackStructuralRef ?? 'none'} -> ${latest.cityPackStructuralRef ?? 'none'}',
    ];
  }

  String _labTargetProvenancePointLabel(_LabTargetProvenancePoint point) {
    final timestamp =
        point.recordedAt.toUtc().toIso8601String().replaceFirst('.000Z', 'Z');
    return '${point.sourceLabel} @ $timestamp';
  }

  List<String> _stringListDifference(List<String> left, List<String> right) {
    final rightSet = right.toSet();
    return left.where((entry) => !rightSet.contains(entry)).toList(
          growable: false,
        );
  }

  bool _sameLabTarget(String? leftVariantId, String? rightVariantId) {
    final left = leftVariantId?.trim();
    final right = rightVariantId?.trim();
    final leftIsBase = left == null || left.isEmpty;
    final rightIsBase = right == null || right.isEmpty;
    if (leftIsBase || rightIsBase) {
      return leftIsBase && rightIsBase;
    }
    return left == right;
  }

  String _labTargetRuntimeDeltaFragment({
    required String label,
    required int latest,
    required int previous,
  }) {
    final delta = latest - previous;
    if (delta == 0) {
      return '$label stable';
    }
    final direction = delta > 0 ? 'up' : 'down';
    return '$label $direction ${delta.abs()}';
  }

  String _labTargetRuntimeDeltaSummary(List<ReplaySimulationLabRerunJob> jobs) {
    if (jobs.isEmpty) {
      return 'Runtime delta: no completed reruns exist yet.';
    }
    if (jobs.length == 1) {
      return 'Runtime delta: only one completed rerun exists so far.';
    }
    final latest = jobs[0];
    final previous = jobs[1];
    final deltas = <String>[
      _labTargetRuntimeDeltaFragment(
        label: 'contradictions',
        latest: latest.contradictionCount,
        previous: previous.contradictionCount,
      ),
      _labTargetRuntimeDeltaFragment(
        label: 'receipts',
        latest: latest.receiptCount,
        previous: previous.receiptCount,
      ),
      _labTargetRuntimeDeltaFragment(
        label: 'overlays',
        latest: latest.overlayCount,
        previous: previous.overlayCount,
      ),
      _labTargetRuntimeDeltaFragment(
        label: 'request previews',
        latest: latest.requestPreviewCount,
        previous: previous.requestPreviewCount,
      ),
    ];
    return 'Runtime delta vs prior completed rerun: ${deltas.join(', ')}.';
  }

  String _labTargetRuntimeTrendSeverityCode(
    List<ReplaySimulationLabRerunJob> jobs,
  ) {
    if (jobs.isEmpty) {
      return 'no_evidence';
    }
    if (jobs.length == 1) {
      return 'low_confidence';
    }
    final latest = jobs[0];
    final previous = jobs[1];
    final contradictionDelta =
        latest.contradictionCount - previous.contradictionCount;
    final receiptDelta = latest.receiptCount - previous.receiptCount;
    final overlayDelta = latest.overlayCount - previous.overlayCount;
    final previewDelta =
        latest.requestPreviewCount - previous.requestPreviewCount;
    if (contradictionDelta == 0 &&
        receiptDelta == 0 &&
        overlayDelta == 0 &&
        previewDelta == 0) {
      return 'stable';
    }
    var score = 0;
    if (contradictionDelta < 0) {
      score += 2;
    } else if (contradictionDelta > 0) {
      score -= 2;
    }
    if (receiptDelta > 0) {
      score += 1;
    } else if (receiptDelta < 0) {
      score -= 1;
    }
    if (previewDelta > 0) {
      score += 1;
    } else if (previewDelta < 0) {
      score -= 1;
    }
    if (score >= 3) {
      return 'improving';
    }
    if (score <= -3) {
      return 'regressing';
    }
    return 'mixed';
  }

  String _labTargetRuntimeTrendSummary(String severityCode) {
    return switch (severityCode) {
      'no_evidence' => 'Runtime trend: No executed rerun evidence yet.',
      'low_confidence' =>
        'Runtime trend: Low confidence; only one completed rerun exists.',
      'stable' => 'Runtime trend: Stable within current runtime bounds.',
      'improving' => 'Runtime trend: Improving within bounded runtime drift.',
      'regressing' => 'Runtime trend: Regression risk is increasing.',
      _ => 'Runtime trend: Mixed drift; operator review still required.',
    };
  }

  String _labTargetOutcomeTrendSummary(
    List<ReplaySimulationLabOutcomeRecord> outcomes,
  ) {
    if (outcomes.isEmpty) {
      return 'Outcome trend: no labeled outcomes exist yet.';
    }
    if (outcomes.length == 1) {
      return 'Outcome trend: only one labeled outcome exists so far.';
    }
    final latest = outcomes[0];
    final previous = outcomes[1];
    if (latest.disposition == previous.disposition) {
      return switch (latest.disposition) {
        ReplaySimulationLabDisposition.accepted =>
          'Outcome trend: stable accepted evidence across the latest two runs.',
        ReplaySimulationLabDisposition.denied =>
          'Outcome trend: repeated denials across the latest two runs.',
        ReplaySimulationLabDisposition.draft =>
          'Outcome trend: repeated draft outcomes across the latest two runs.',
      };
    }
    if (latest.disposition == ReplaySimulationLabDisposition.accepted &&
        previous.disposition == ReplaySimulationLabDisposition.denied) {
      return 'Outcome trend: improved from denial to accepted evidence.';
    }
    if (latest.disposition == ReplaySimulationLabDisposition.denied &&
        previous.disposition == ReplaySimulationLabDisposition.accepted) {
      return 'Outcome trend: regressed from accepted evidence back to denial.';
    }
    if (latest.disposition == ReplaySimulationLabDisposition.draft) {
      return 'Outcome trend: latest run moved back into draft iteration.';
    }
    return 'Outcome trend: mixed disposition shift across the latest two runs.';
  }

  SignatureHealthHierarchyDomainDeltaSummary? _buildHierarchyDomainDeltaSummary(
    String? jsonPath,
    ExternalSourceDescriptor source,
  ) {
    final payload = _readJsonObject(jsonPath);
    if (payload == null) {
      return null;
    }
    return SignatureHealthHierarchyDomainDeltaSummary(
      status: payload['status']?.toString() ?? 'unknown',
      environmentId: payload['environmentId']?.toString() ??
          source.metadata['environmentId']?.toString() ??
          'unknown_environment',
      domainId: payload['domainId']?.toString() ?? 'unknown_domain',
      summary:
          payload['summary']?.toString() ?? 'Hierarchy delta is available.',
      boundedUse: payload['boundedUse']?.toString() ??
          'Use as a bounded lower-tier delta only.',
      requestCount: (payload['requestCount'] as num?)?.toInt() ?? 0,
      recommendationCount:
          (payload['recommendationCount'] as num?)?.toInt() ?? 0,
      averageConfidence: (payload['averageConfidence'] as num?)?.toDouble(),
      learningDeltas: List<String>.from(
        payload['learningDeltas'] ?? const <String>[],
      ),
      downstreamConsumerSummary: _buildDomainConsumerSummary(
        payload['downstreamConsumer'],
      ),
      jsonPath: jsonPath,
      temporalLineage: _buildTemporalLineageSummary(payload['temporalLineage']),
    );
  }

  SignatureHealthDomainConsumerSummary? _buildDomainConsumerSummary(
    Object? raw,
  ) {
    if (raw is! Map) {
      return null;
    }
    final payload = Map<String, dynamic>.from(raw);
    return SignatureHealthDomainConsumerSummary(
      status: payload['status']?.toString() ?? 'unknown',
      consumerId: payload['consumerId']?.toString() ?? 'unknown_consumer',
      domainId: payload['domainId']?.toString() ?? 'unknown_domain',
      summary: payload['summary']?.toString() ??
          'A bounded downstream consumer lane is available.',
      boundedUse: payload['boundedUse']?.toString() ??
          'Use only as a bounded downstream consumer refresh.',
      targetedSystems: List<String>.from(
        payload['targetedSystems'] ?? const <String>[],
      ),
      jsonPath: payload['jsonPath']?.toString(),
      temporalLineage: _buildTemporalLineageSummary(payload['temporalLineage']),
    );
  }

  SignatureHealthPersonalAgentPersonalizationSummary?
      _buildPersonalAgentPersonalizationSummary(
    String? jsonPath,
    ExternalSourceDescriptor source,
  ) {
    final payload = _readJsonObject(jsonPath);
    if (payload == null) {
      return null;
    }
    return SignatureHealthPersonalAgentPersonalizationSummary(
      status: payload['status']?.toString() ?? 'unknown',
      environmentId: payload['environmentId']?.toString() ??
          source.metadata['environmentId']?.toString() ??
          'unknown_environment',
      domainId: payload['domainId']?.toString() ?? 'unknown_domain',
      summary: payload['summary']?.toString() ??
          'Personal-agent personalization delta is available.',
      personalizationMode:
          payload['personalizationMode']?.toString() ?? 'unknown',
      boundedUse: payload['boundedUse']?.toString() ??
          'Use as a bounded personal-agent personalization delta only.',
      requestCount: (payload['requestCount'] as num?)?.toInt() ?? 0,
      recommendationCount:
          (payload['recommendationCount'] as num?)?.toInt() ?? 0,
      averageConfidence: (payload['averageConfidence'] as num?)?.toDouble(),
      jsonPath: jsonPath,
      temporalLineage: _buildTemporalLineageSummary(payload['temporalLineage']),
    );
  }

  Map<String, dynamic>? _readJsonObject(String? jsonPath) {
    if (jsonPath == null || jsonPath.isEmpty) {
      return null;
    }
    final file = File(jsonPath);
    if (!file.existsSync()) {
      return null;
    }
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  SignatureHealthRecord _toRecord(ExternalSourceDescriptor source) {
    final metadata = source.metadata;
    final confidence = _asDouble(metadata['signatureConfidence']);
    final freshness = _asDouble(metadata['signatureFreshness']);
    final fallbackRate = _asDouble(metadata['fallbackRate']);
    final reviewNeeded = source.syncState == ExternalSyncState.needsReview ||
        metadata['reviewNeeded'] == true ||
        metadata['signatureReviewNeeded'] == true;
    final entityType = metadata['entityType']?.toString() ??
        source.entityHint?.name ??
        'unknown';
    final categoryLabel = metadata['category']?.toString() ??
        metadata['signatureCategory']?.toString() ??
        entityType;
    final lastSignatureRebuildAt = _asDateTime(
        metadata['signatureUpdatedAt'] ?? metadata['lastSignatureRebuildAt']);
    final fallbackState = metadata['signatureMode'] == 'fallback' ||
        metadata['usedSignaturePrimary'] == false ||
        fallbackRate > 0.0;
    final isBundle = entityType == IntakeEntityType.linkedBundle.name ||
        metadata['bundleEntityIds'] != null;

    final healthCategory = _resolveCategory(
      confidence: confidence,
      freshness: freshness,
      fallbackState: fallbackState,
      reviewNeeded: reviewNeeded,
      isBundle: isBundle,
    );

    return SignatureHealthRecord(
      sourceId: source.id,
      provider: source.sourceProvider,
      entityType: entityType,
      categoryLabel: categoryLabel,
      sourceLabel: source.sourceLabel,
      cityCode: source.cityCode,
      localityCode: source.localityCode,
      confidence: confidence,
      freshness: freshness,
      fallbackRate: fallbackRate,
      reviewNeeded: reviewNeeded,
      lastSyncAt: source.lastSyncedAt,
      lastSignatureRebuildAt: lastSignatureRebuildAt,
      updatedAt: source.updatedAt,
      syncState: source.syncState.name,
      healthCategory: healthCategory,
      summary: _buildSummary(
        source: source,
        healthCategory: healthCategory,
        confidence: confidence,
        freshness: freshness,
        fallbackState: fallbackState,
      ),
    );
  }

  SignatureHealthCategory _resolveCategory({
    required double confidence,
    required double freshness,
    required bool fallbackState,
    required bool reviewNeeded,
    required bool isBundle,
  }) {
    if (reviewNeeded) {
      return SignatureHealthCategory.reviewNeeded;
    }
    if (fallbackState) {
      return SignatureHealthCategory.fallback;
    }
    if (freshness < 0.55) {
      return SignatureHealthCategory.stale;
    }
    if (confidence < 0.75) {
      return SignatureHealthCategory.weakData;
    }
    if (isBundle) {
      return SignatureHealthCategory.bundle;
    }
    return SignatureHealthCategory.strong;
  }

  String _buildSummary({
    required ExternalSourceDescriptor source,
    required SignatureHealthCategory healthCategory,
    required double confidence,
    required double freshness,
    required bool fallbackState,
  }) {
    final label = source.sourceLabel ?? source.sourceProvider;
    switch (healthCategory) {
      case SignatureHealthCategory.reviewNeeded:
        return '$label needs operator review before trust can rise.';
      case SignatureHealthCategory.fallback:
        return '$label is leaning on fallback ranking instead of signature-primary.';
      case SignatureHealthCategory.stale:
        return '$label has gone stale and should rebuild its live pheromones.';
      case SignatureHealthCategory.weakData:
        return '$label has weak signature confidence (${(confidence * 100).round()}%).';
      case SignatureHealthCategory.bundle:
        return '$label is a linked bundle with blended confidence ${(confidence * 100).round()}% and freshness ${(freshness * 100).round()}%.';
      case SignatureHealthCategory.strong:
        return '$label is signature-healthy with confidence ${(confidence * 100).round()}% and freshness ${(freshness * 100).round()}%.';
    }
  }

  int _categoryPriority(SignatureHealthCategory category) {
    switch (category) {
      case SignatureHealthCategory.reviewNeeded:
        return 0;
      case SignatureHealthCategory.fallback:
        return 1;
      case SignatureHealthCategory.stale:
        return 2;
      case SignatureHealthCategory.weakData:
        return 3;
      case SignatureHealthCategory.bundle:
        return 4;
      case SignatureHealthCategory.strong:
        return 5;
    }
  }

  double _asDouble(Object? value) {
    if (value is num) {
      return value.toDouble().clamp(0.0, 1.0);
    }
    if (value is String) {
      return double.tryParse(value)?.clamp(0.0, 1.0).toDouble() ?? 0.0;
    }
    return 0.0;
  }

  DateTime? _asDateTime(Object? value) {
    if (value is DateTime) {
      return value;
    }
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
