import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:avrai_core/models/imports/external_sync_metadata.dart';
import 'package:avrai_core/models/temporal/replay_simulation_artifacts.dart';
import 'package:avrai_core/models/temporal/replay_training_export_manifest.dart';
import 'package:avrai_core/models/reality/reality_model_contracts.dart';
import 'package:avrai_runtime_os/services/prediction/bham_event_scenario_pack_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_contradiction_dashboard_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_constants.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_locality_overlay_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_scenario_comparison_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_scenario_packet_service.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_truth_receipt_service.dart';
import 'package:avrai_runtime_os/services/intake/intake_models.dart';
import 'package:avrai_runtime_os/services/intake/upward_air_gap_service.dart';
import 'package:avrai_runtime_os/services/intake/universal_intake_repository.dart';
import 'package:avrai_runtime_os/services/reality_model/governed_upward_learning_intake_service.dart';
import 'package:avrai_runtime_os/services/reality_model/default_reality_model_port.dart';
import 'package:avrai_runtime_os/services/reality_model/reality_model_port.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class ReplaySimulationAdminEnvironmentDescriptor {
  const ReplaySimulationAdminEnvironmentDescriptor({
    required this.environmentId,
    required this.displayName,
    required this.cityCode,
    required this.replayYear,
    this.description = '',
    this.simulationMode = 'generic_city_pack',
    this.cityPackManifestRef,
    this.cityPackStructuralRef,
    this.campaignDefaultsRef,
    this.localityExpectationProfileRef,
    this.worldHealthProfileRef,
    this.intakeFlowRefs = const <String>[],
    this.sidecarRefs = const <String>[],
  });

  final String environmentId;
  final String displayName;
  final String cityCode;
  final int replayYear;
  final String description;
  final String simulationMode;
  final String? cityPackManifestRef;
  final String? cityPackStructuralRef;
  final String? campaignDefaultsRef;
  final String? localityExpectationProfileRef;
  final String? worldHealthProfileRef;
  final List<String> intakeFlowRefs;
  final List<String> sidecarRefs;
}

class ReplaySimulationLabEnvironmentRegistration {
  const ReplaySimulationLabEnvironmentRegistration({
    required this.environmentId,
    required this.displayName,
    required this.cityCode,
    required this.replayYear,
    required this.description,
    required this.localityDisplayNames,
    required this.createdAt,
    this.simulationMode = 'generic_city_pack',
    this.cityPackManifestRef,
    this.cityPackStructuralRef,
    this.campaignDefaultsRef,
    this.localityExpectationProfileRef,
    this.worldHealthProfileRef,
    this.intakeFlowRefs = const <String>[],
    this.sidecarRefs = const <String>[],
  });

  final String environmentId;
  final String displayName;
  final String cityCode;
  final int replayYear;
  final String description;
  final Map<String, String> localityDisplayNames;
  final DateTime createdAt;
  final String simulationMode;
  final String? cityPackManifestRef;
  final String? cityPackStructuralRef;
  final String? campaignDefaultsRef;
  final String? localityExpectationProfileRef;
  final String? worldHealthProfileRef;
  final List<String> intakeFlowRefs;
  final List<String> sidecarRefs;

  ReplaySimulationAdminEnvironmentDescriptor get descriptor =>
      ReplaySimulationAdminEnvironmentDescriptor(
        environmentId: environmentId,
        displayName: displayName,
        cityCode: cityCode,
        replayYear: replayYear,
        description: description,
        simulationMode: simulationMode,
        cityPackManifestRef: cityPackManifestRef,
        cityPackStructuralRef: cityPackStructuralRef,
        campaignDefaultsRef: campaignDefaultsRef,
        localityExpectationProfileRef: localityExpectationProfileRef,
        worldHealthProfileRef: worldHealthProfileRef,
        intakeFlowRefs: intakeFlowRefs,
        sidecarRefs: sidecarRefs,
      );

  SyntheticReplaySimulationAdminEnvironmentAdapter toAdapter() =>
      SyntheticReplaySimulationAdminEnvironmentAdapter(
        descriptor: descriptor,
        localityDisplayNames: localityDisplayNames,
        createdBy: 'world_simulation_lab',
      );

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'environmentId': environmentId,
      'displayName': displayName,
      'cityCode': cityCode,
      'replayYear': replayYear,
      'description': description,
      'localityDisplayNames': localityDisplayNames,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'simulationMode': simulationMode,
      'cityPackManifestRef': cityPackManifestRef,
      'cityPackStructuralRef': cityPackStructuralRef,
      'campaignDefaultsRef': campaignDefaultsRef,
      'localityExpectationProfileRef': localityExpectationProfileRef,
      'worldHealthProfileRef': worldHealthProfileRef,
      'intakeFlowRefs': intakeFlowRefs,
      'sidecarRefs': sidecarRefs,
    };
  }

  factory ReplaySimulationLabEnvironmentRegistration.fromJson(
    Map<String, dynamic> json,
  ) {
    final localityJson =
        Map<String, dynamic>.from(json['localityDisplayNames'] as Map? ?? {});
    return ReplaySimulationLabEnvironmentRegistration(
      environmentId: (json['environmentId'] ?? '').toString(),
      displayName: (json['displayName'] ?? '').toString(),
      cityCode: (json['cityCode'] ?? '').toString(),
      replayYear: (json['replayYear'] as num?)?.toInt() ?? 0,
      description: (json['description'] ?? '').toString(),
      localityDisplayNames: localityJson.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      simulationMode:
          (json['simulationMode'] ?? 'generic_city_pack').toString(),
      cityPackManifestRef:
          (json['cityPackManifestRef'] as String?)?.trim().isEmpty == true
              ? null
              : (json['cityPackManifestRef'] as String?),
      cityPackStructuralRef:
          (json['cityPackStructuralRef'] as String?)?.trim().isEmpty == true
              ? _deriveReplaySimulationCityPackStructuralRef(
                  cityCode: (json['cityCode'] ?? '').toString(),
                  replayYear: (json['replayYear'] as num?)?.toInt() ?? 0,
                )
              : (json['cityPackStructuralRef'] as String?),
      campaignDefaultsRef:
          (json['campaignDefaultsRef'] as String?)?.trim().isEmpty == true
              ? null
              : (json['campaignDefaultsRef'] as String?),
      localityExpectationProfileRef:
          (json['localityExpectationProfileRef'] as String?)?.trim().isEmpty ==
                  true
              ? null
              : (json['localityExpectationProfileRef'] as String?),
      worldHealthProfileRef:
          (json['worldHealthProfileRef'] as String?)?.trim().isEmpty == true
              ? null
              : (json['worldHealthProfileRef'] as String?),
      intakeFlowRefs: (json['intakeFlowRefs'] as List<dynamic>? ?? const [])
          .map((entry) => entry.toString())
          .toList(growable: false),
      sidecarRefs: (json['sidecarRefs'] as List<dynamic>? ?? const [])
          .map((entry) => entry.toString())
          .toList(growable: false),
    );
  }
}

class ReplaySimulationLabVariantDraft {
  const ReplaySimulationLabVariantDraft({
    required this.environmentId,
    required this.variantId,
    required this.label,
    required this.hypothesis,
    required this.localityCodes,
    required this.operatorNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String environmentId;
  final String variantId;
  final String label;
  final String hypothesis;
  final List<String> localityCodes;
  final List<String> operatorNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'environmentId': environmentId,
      'variantId': variantId,
      'label': label,
      'hypothesis': hypothesis,
      'localityCodes': localityCodes,
      'operatorNotes': operatorNotes,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory ReplaySimulationLabVariantDraft.fromJson(Map<String, dynamic> json) {
    return ReplaySimulationLabVariantDraft(
      environmentId: (json['environmentId'] ?? '').toString(),
      variantId: (json['variantId'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      hypothesis: (json['hypothesis'] ?? '').toString(),
      localityCodes: (json['localityCodes'] as List<dynamic>? ?? const [])
          .map((entry) => entry.toString())
          .toList(growable: false),
      operatorNotes: (json['operatorNotes'] as List<dynamic>? ?? const [])
          .map((entry) => entry.toString())
          .toList(growable: false),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      updatedAt: DateTime.tryParse((json['updatedAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }
}

class ReplaySimulationLabTargetActionDecision {
  const ReplaySimulationLabTargetActionDecision({
    required this.environmentId,
    required this.updatedAt,
    required this.suggestedAction,
    required this.suggestedReason,
    required this.selectedAction,
    required this.acceptedSuggestion,
    this.alertAcknowledgedAt,
    this.alertAcknowledgedSeverityCode,
    this.alertEscalatedAt,
    this.alertEscalatedSeverityCode,
    this.alertSnoozedUntil,
    this.alertSnoozedSeverityCode,
    this.variantId,
    this.variantLabel,
  });

  final String environmentId;
  final DateTime updatedAt;
  final String suggestedAction;
  final String suggestedReason;
  final String selectedAction;
  final bool acceptedSuggestion;
  final DateTime? alertAcknowledgedAt;
  final String? alertAcknowledgedSeverityCode;
  final DateTime? alertEscalatedAt;
  final String? alertEscalatedSeverityCode;
  final DateTime? alertSnoozedUntil;
  final String? alertSnoozedSeverityCode;
  final String? variantId;
  final String? variantLabel;

  bool get targetsBaseRun => variantId == null || variantId!.trim().isEmpty;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'environmentId': environmentId,
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'suggestedAction': suggestedAction,
      'suggestedReason': suggestedReason,
      'selectedAction': selectedAction,
      'acceptedSuggestion': acceptedSuggestion,
      'alertAcknowledgedAt': alertAcknowledgedAt?.toUtc().toIso8601String(),
      'alertAcknowledgedSeverityCode': alertAcknowledgedSeverityCode,
      'alertEscalatedAt': alertEscalatedAt?.toUtc().toIso8601String(),
      'alertEscalatedSeverityCode': alertEscalatedSeverityCode,
      'alertSnoozedUntil': alertSnoozedUntil?.toUtc().toIso8601String(),
      'alertSnoozedSeverityCode': alertSnoozedSeverityCode,
      'variantId': variantId,
      'variantLabel': variantLabel,
    };
  }

  factory ReplaySimulationLabTargetActionDecision.fromJson(
    Map<String, dynamic> json,
  ) {
    return ReplaySimulationLabTargetActionDecision(
      environmentId: (json['environmentId'] ?? '').toString(),
      updatedAt: DateTime.tryParse((json['updatedAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      suggestedAction: ReplaySimulationAdminService._normalizeLabTargetAction(
        (json['suggestedAction'] ?? 'watch_closely').toString(),
      ),
      suggestedReason: (json['suggestedReason'] ?? '').toString(),
      selectedAction: ReplaySimulationAdminService._normalizeLabTargetAction(
        (json['selectedAction'] ?? 'watch_closely').toString(),
      ),
      acceptedSuggestion: json['acceptedSuggestion'] == true,
      alertAcknowledgedAt: DateTime.tryParse(
        (json['alertAcknowledgedAt'] ?? '').toString(),
      ),
      alertAcknowledgedSeverityCode:
          (json['alertAcknowledgedSeverityCode'] as String?)?.trim().isEmpty ==
                  true
              ? null
              : (json['alertAcknowledgedSeverityCode'] as String?),
      alertEscalatedAt: DateTime.tryParse(
        (json['alertEscalatedAt'] ?? '').toString(),
      ),
      alertEscalatedSeverityCode:
          (json['alertEscalatedSeverityCode'] as String?)?.trim().isEmpty ==
                  true
              ? null
              : (json['alertEscalatedSeverityCode'] as String?),
      alertSnoozedUntil: DateTime.tryParse(
        (json['alertSnoozedUntil'] ?? '').toString(),
      ),
      alertSnoozedSeverityCode:
          (json['alertSnoozedSeverityCode'] as String?)?.trim().isEmpty == true
              ? null
              : (json['alertSnoozedSeverityCode'] as String?),
      variantId: (json['variantId'] as String?)?.trim().isEmpty == true
          ? null
          : (json['variantId'] as String?),
      variantLabel: (json['variantLabel'] as String?)?.trim().isEmpty == true
          ? null
          : (json['variantLabel'] as String?),
    );
  }
}

class ReplaySimulationLabRuntimeState {
  const ReplaySimulationLabRuntimeState({
    required this.environmentId,
    required this.updatedAt,
    this.activeVariantId,
    this.activeVariantLabel,
    this.targetActionDecisions =
        const <ReplaySimulationLabTargetActionDecision>[],
  });

  final String environmentId;
  final DateTime updatedAt;
  final String? activeVariantId;
  final String? activeVariantLabel;
  final List<ReplaySimulationLabTargetActionDecision> targetActionDecisions;

  bool get usesBaseRun =>
      activeVariantId == null || activeVariantId!.trim().isEmpty;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'environmentId': environmentId,
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'activeVariantId': activeVariantId,
      'activeVariantLabel': activeVariantLabel,
      'targetActionDecisions': targetActionDecisions
          .map((entry) => entry.toJson())
          .toList(growable: false),
    };
  }

  factory ReplaySimulationLabRuntimeState.fromJson(Map<String, dynamic> json) {
    return ReplaySimulationLabRuntimeState(
      environmentId: (json['environmentId'] ?? '').toString(),
      updatedAt: DateTime.tryParse((json['updatedAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      activeVariantId:
          (json['activeVariantId'] as String?)?.trim().isEmpty == true
              ? null
              : (json['activeVariantId'] as String?),
      activeVariantLabel:
          (json['activeVariantLabel'] as String?)?.trim().isEmpty == true
              ? null
              : (json['activeVariantLabel'] as String?),
      targetActionDecisions:
          (json['targetActionDecisions'] as List<dynamic>? ?? const [])
              .map(
                (entry) => ReplaySimulationLabTargetActionDecision.fromJson(
                  Map<String, dynamic>.from(entry as Map),
                ),
              )
              .toList(growable: false),
    );
  }
}

class ReplaySimulationLabServedBasisState {
  const ReplaySimulationLabServedBasisState({
    required this.environmentId,
    required this.supportedPlaceRef,
    required this.stagedAt,
    required this.servedBasisRef,
    required this.latestStateEvidenceRefsByFamily,
    this.latestStateEvidenceSelectionSummariesByFamily =
        const <String, String>{},
    this.latestStateEvidenceAgingStatusesByFamily = const <String, String>{},
    this.latestStateEvidenceAgingSummariesByFamily = const <String, String>{},
    this.latestStateEvidenceAgingTransitionsByFamily = const <String, String>{},
    this.latestStateEvidenceAgingTrendsByFamily = const <String, String>{},
    this.latestStateEvidenceAgingTrendSummariesByFamily =
        const <String, String>{},
    this.latestStateEvidencePolicyActionsByFamily = const <String, String>{},
    this.latestStateEvidencePolicyActionSummariesByFamily =
        const <String, String>{},
    this.latestStateEvidenceRestageTargetsByFamily = const <String, String>{},
    this.latestStateEvidenceRestageTargetSummariesByFamily =
        const <String, String>{},
    this.cityPackStructuralRef,
    this.priorServedBasisRef,
    this.basisRefreshLineageRef,
    this.latestStateRefreshReceiptRef,
    this.latestStatePromotionReceiptRef,
    this.latestStateDecisionStatus = 'not_reviewed',
    this.latestStateDecisionArtifactRef,
    this.latestStateDecisionRationale,
    this.latestStateDecisionRecordedAt,
    this.latestStateRevalidationStatus = 'not_revalidated',
    this.latestStateRevalidationReceiptRef,
    this.latestStateRevalidationArtifactRef,
    this.latestStateRevalidatedAt,
    this.latestStateRecoveryDecisionStatus = 'not_reviewed',
    this.latestStateRecoveryDecisionArtifactRef,
    this.latestStateRecoveryDecisionRationale,
    this.latestStateRecoveryDecisionRecordedAt,
    this.latestStateDeploymentReceiptRef,
    this.currentBasisStatus = 'replay_grounded_seed_basis',
    this.latestStateHydrationStatus = 'awaiting_latest_avrai_evidence_refresh',
    this.latestStatePromotionReadiness =
        'blocked_pending_latest_state_evidence',
    this.latestStatePromotionBlockedReasons = const <String>[],
    this.hydrationFreshnessPosture =
        'refresh_receipts_required_before_served_basis_change',
    this.latestStateRefreshCadenceHours = 24,
    this.latestStateRefreshCadenceStatus = 'awaiting_first_refresh_receipts',
    this.latestStateRefreshReferenceAt,
    this.latestStateRefreshPolicySummaries = const <String>[],
    this.latestStateRefreshExecutionStatus = 'not_checked',
    this.latestStateRefreshExecutionReceiptRef,
    this.latestStateRefreshExecutionCheckedAt,
  });

  final String environmentId;
  final String supportedPlaceRef;
  final DateTime stagedAt;
  final String servedBasisRef;
  final String? cityPackStructuralRef;
  final String? priorServedBasisRef;
  final String? basisRefreshLineageRef;
  final String? latestStateRefreshReceiptRef;
  final String? latestStatePromotionReceiptRef;
  final String latestStateDecisionStatus;
  final String? latestStateDecisionArtifactRef;
  final String? latestStateDecisionRationale;
  final DateTime? latestStateDecisionRecordedAt;
  final String latestStateRevalidationStatus;
  final String? latestStateRevalidationReceiptRef;
  final String? latestStateRevalidationArtifactRef;
  final DateTime? latestStateRevalidatedAt;
  final String latestStateRecoveryDecisionStatus;
  final String? latestStateRecoveryDecisionArtifactRef;
  final String? latestStateRecoveryDecisionRationale;
  final DateTime? latestStateRecoveryDecisionRecordedAt;
  final String? latestStateDeploymentReceiptRef;
  final String currentBasisStatus;
  final String latestStateHydrationStatus;
  final String latestStatePromotionReadiness;
  final List<String> latestStatePromotionBlockedReasons;
  final String hydrationFreshnessPosture;
  final int latestStateRefreshCadenceHours;
  final String latestStateRefreshCadenceStatus;
  final DateTime? latestStateRefreshReferenceAt;
  final List<String> latestStateRefreshPolicySummaries;
  final String latestStateRefreshExecutionStatus;
  final String? latestStateRefreshExecutionReceiptRef;
  final DateTime? latestStateRefreshExecutionCheckedAt;
  final Map<String, String> latestStateEvidenceRefsByFamily;
  final Map<String, String> latestStateEvidenceSelectionSummariesByFamily;
  final Map<String, String> latestStateEvidenceAgingStatusesByFamily;
  final Map<String, String> latestStateEvidenceAgingSummariesByFamily;
  final Map<String, String> latestStateEvidenceAgingTransitionsByFamily;
  final Map<String, String> latestStateEvidenceAgingTrendsByFamily;
  final Map<String, String> latestStateEvidenceAgingTrendSummariesByFamily;
  final Map<String, String> latestStateEvidencePolicyActionsByFamily;
  final Map<String, String> latestStateEvidencePolicyActionSummariesByFamily;
  final Map<String, String> latestStateEvidenceRestageTargetsByFamily;
  final Map<String, String> latestStateEvidenceRestageTargetSummariesByFamily;

  List<String> get latestStateEvidenceRefs =>
      latestStateEvidenceRefsByFamily.values
          .map((entry) => entry.trim())
          .where((entry) => entry.isNotEmpty)
          .toList(growable: false);

  List<String> get latestStateEvidenceSelectionSummaries =>
      latestStateEvidenceSelectionSummariesByFamily.values
          .map((entry) => entry.trim())
          .where((entry) => entry.isNotEmpty)
          .toList(growable: false);

  List<String> get latestStateEvidenceAgingSummaries =>
      latestStateEvidenceAgingSummariesByFamily.values
          .map((entry) => entry.trim())
          .where((entry) => entry.isNotEmpty)
          .toList(growable: false);

  List<String> get latestStateEvidenceAgingTrendSummaries =>
      latestStateEvidenceAgingTrendSummariesByFamily.values
          .map((entry) => entry.trim())
          .where((entry) => entry.isNotEmpty)
          .toList(growable: false);

  List<String> get latestStateEvidencePolicyActionSummaries =>
      latestStateEvidencePolicyActionSummariesByFamily.values
          .map((entry) => entry.trim())
          .where((entry) => entry.isNotEmpty)
          .toList(growable: false);

  List<String> get latestStateEvidenceRestageTargetSummaries =>
      latestStateEvidenceRestageTargetSummariesByFamily.values
          .map((entry) => entry.trim())
          .where((entry) => entry.isNotEmpty)
          .toList(growable: false);

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'environmentId': environmentId,
      'supportedPlaceRef': supportedPlaceRef,
      'stagedAt': stagedAt.toUtc().toIso8601String(),
      'servedBasisRef': servedBasisRef,
      'cityPackStructuralRef': cityPackStructuralRef,
      'priorServedBasisRef': priorServedBasisRef,
      'basisRefreshLineageRef': basisRefreshLineageRef,
      'latestStateRefreshReceiptRef': latestStateRefreshReceiptRef,
      'latestStatePromotionReceiptRef': latestStatePromotionReceiptRef,
      'latestStateDecisionStatus': latestStateDecisionStatus,
      'latestStateDecisionArtifactRef': latestStateDecisionArtifactRef,
      'latestStateDecisionRationale': latestStateDecisionRationale,
      'latestStateDecisionRecordedAt':
          latestStateDecisionRecordedAt?.toUtc().toIso8601String(),
      'latestStateRevalidationStatus': latestStateRevalidationStatus,
      'latestStateRevalidationReceiptRef': latestStateRevalidationReceiptRef,
      'latestStateRevalidationArtifactRef': latestStateRevalidationArtifactRef,
      'latestStateRevalidatedAt':
          latestStateRevalidatedAt?.toUtc().toIso8601String(),
      'latestStateRecoveryDecisionStatus': latestStateRecoveryDecisionStatus,
      'latestStateRecoveryDecisionArtifactRef':
          latestStateRecoveryDecisionArtifactRef,
      'latestStateRecoveryDecisionRationale':
          latestStateRecoveryDecisionRationale,
      'latestStateRecoveryDecisionRecordedAt':
          latestStateRecoveryDecisionRecordedAt?.toUtc().toIso8601String(),
      'latestStateDeploymentReceiptRef': latestStateDeploymentReceiptRef,
      'currentBasisStatus': currentBasisStatus,
      'latestStateHydrationStatus': latestStateHydrationStatus,
      'latestStatePromotionReadiness': latestStatePromotionReadiness,
      'latestStatePromotionBlockedReasons': latestStatePromotionBlockedReasons,
      'hydrationFreshnessPosture': hydrationFreshnessPosture,
      'latestStateRefreshCadenceHours': latestStateRefreshCadenceHours,
      'latestStateRefreshCadenceStatus': latestStateRefreshCadenceStatus,
      'latestStateRefreshReferenceAt':
          latestStateRefreshReferenceAt?.toUtc().toIso8601String(),
      'latestStateRefreshPolicySummaries': latestStateRefreshPolicySummaries,
      'latestStateRefreshExecutionStatus': latestStateRefreshExecutionStatus,
      'latestStateRefreshExecutionReceiptRef':
          latestStateRefreshExecutionReceiptRef,
      'latestStateRefreshExecutionCheckedAt':
          latestStateRefreshExecutionCheckedAt?.toUtc().toIso8601String(),
      'latestStateEvidenceRefsByFamily': latestStateEvidenceRefsByFamily,
      'latestStateEvidenceSelectionSummariesByFamily':
          latestStateEvidenceSelectionSummariesByFamily,
      'latestStateEvidenceAgingStatusesByFamily':
          latestStateEvidenceAgingStatusesByFamily,
      'latestStateEvidenceAgingSummariesByFamily':
          latestStateEvidenceAgingSummariesByFamily,
      'latestStateEvidenceAgingTransitionsByFamily':
          latestStateEvidenceAgingTransitionsByFamily,
      'latestStateEvidenceAgingTrendsByFamily':
          latestStateEvidenceAgingTrendsByFamily,
      'latestStateEvidenceAgingTrendSummariesByFamily':
          latestStateEvidenceAgingTrendSummariesByFamily,
      'latestStateEvidencePolicyActionsByFamily':
          latestStateEvidencePolicyActionsByFamily,
      'latestStateEvidencePolicyActionSummariesByFamily':
          latestStateEvidencePolicyActionSummariesByFamily,
      'latestStateEvidenceRestageTargetsByFamily':
          latestStateEvidenceRestageTargetsByFamily,
      'latestStateEvidenceRestageTargetSummariesByFamily':
          latestStateEvidenceRestageTargetSummariesByFamily,
    };
  }

  factory ReplaySimulationLabServedBasisState.fromJson(
    Map<String, dynamic> json,
  ) {
    final refsByFamily = Map<String, dynamic>.from(
      json['latestStateEvidenceRefsByFamily'] as Map? ??
          const <String, dynamic>{},
    ).map(
      (key, value) => MapEntry(key, value.toString()),
    );
    final selectionSummariesByFamily = Map<String, dynamic>.from(
      json['latestStateEvidenceSelectionSummariesByFamily'] as Map? ??
          const <String, dynamic>{},
    ).map(
      (key, value) => MapEntry(key, value.toString()),
    );
    final agingStatusesByFamily = Map<String, dynamic>.from(
      json['latestStateEvidenceAgingStatusesByFamily'] as Map? ??
          const <String, dynamic>{},
    ).map(
      (key, value) => MapEntry(key, value.toString()),
    );
    final agingSummariesByFamily = Map<String, dynamic>.from(
      json['latestStateEvidenceAgingSummariesByFamily'] as Map? ??
          const <String, dynamic>{},
    ).map(
      (key, value) => MapEntry(key, value.toString()),
    );
    final agingTransitionsByFamily = Map<String, dynamic>.from(
      json['latestStateEvidenceAgingTransitionsByFamily'] as Map? ??
          const <String, dynamic>{},
    ).map(
      (key, value) => MapEntry(key, value.toString()),
    );
    final agingTrendsByFamily = Map<String, dynamic>.from(
      json['latestStateEvidenceAgingTrendsByFamily'] as Map? ??
          const <String, dynamic>{},
    ).map(
      (key, value) => MapEntry(key, value.toString()),
    );
    final agingTrendSummariesByFamily = Map<String, dynamic>.from(
      json['latestStateEvidenceAgingTrendSummariesByFamily'] as Map? ??
          const <String, dynamic>{},
    ).map(
      (key, value) => MapEntry(key, value.toString()),
    );
    final policyActionsByFamily = Map<String, dynamic>.from(
      json['latestStateEvidencePolicyActionsByFamily'] as Map? ??
          const <String, dynamic>{},
    ).map(
      (key, value) => MapEntry(key, value.toString()),
    );
    final policyActionSummariesByFamily = Map<String, dynamic>.from(
      json['latestStateEvidencePolicyActionSummariesByFamily'] as Map? ??
          const <String, dynamic>{},
    ).map(
      (key, value) => MapEntry(key, value.toString()),
    );
    final restageTargetsByFamily = Map<String, dynamic>.from(
      json['latestStateEvidenceRestageTargetsByFamily'] as Map? ??
          const <String, dynamic>{},
    ).map(
      (key, value) => MapEntry(key, value.toString()),
    );
    final restageTargetSummariesByFamily = Map<String, dynamic>.from(
      json['latestStateEvidenceRestageTargetSummariesByFamily'] as Map? ??
          const <String, dynamic>{},
    ).map(
      (key, value) => MapEntry(key, value.toString()),
    );
    return ReplaySimulationLabServedBasisState(
      environmentId: (json['environmentId'] ?? '').toString(),
      supportedPlaceRef: (json['supportedPlaceRef'] ?? '').toString(),
      stagedAt: DateTime.tryParse((json['stagedAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      servedBasisRef: (json['servedBasisRef'] ?? '').toString(),
      cityPackStructuralRef:
          (json['cityPackStructuralRef'] as String?)?.trim().isEmpty == true
              ? null
              : (json['cityPackStructuralRef'] as String?),
      priorServedBasisRef:
          (json['priorServedBasisRef'] as String?)?.trim().isEmpty == true
              ? null
              : (json['priorServedBasisRef'] as String?),
      basisRefreshLineageRef:
          (json['basisRefreshLineageRef'] as String?)?.trim().isEmpty == true
              ? null
              : (json['basisRefreshLineageRef'] as String?),
      latestStateRefreshReceiptRef:
          (json['latestStateRefreshReceiptRef'] as String?)?.trim().isEmpty ==
                  true
              ? null
              : (json['latestStateRefreshReceiptRef'] as String?),
      latestStatePromotionReceiptRef:
          (json['latestStatePromotionReceiptRef'] as String?)?.trim().isEmpty ==
                  true
              ? null
              : (json['latestStatePromotionReceiptRef'] as String?),
      latestStateDecisionStatus:
          (json['latestStateDecisionStatus'] ?? 'not_reviewed').toString(),
      latestStateDecisionArtifactRef:
          (json['latestStateDecisionArtifactRef'] as String?)?.trim().isEmpty ==
                  true
              ? null
              : (json['latestStateDecisionArtifactRef'] as String?),
      latestStateDecisionRationale:
          (json['latestStateDecisionRationale'] as String?)?.trim().isEmpty ==
                  true
              ? null
              : (json['latestStateDecisionRationale'] as String?),
      latestStateDecisionRecordedAt:
          (json['latestStateDecisionRecordedAt'] as String?)?.trim().isEmpty ==
                  true
              ? null
              : DateTime.tryParse(
                  (json['latestStateDecisionRecordedAt'] ?? '').toString(),
                )?.toUtc(),
      latestStateRevalidationStatus:
          (json['latestStateRevalidationStatus'] ?? 'not_revalidated')
              .toString(),
      latestStateRevalidationReceiptRef:
          (json['latestStateRevalidationReceiptRef'] as String?)
                      ?.trim()
                      .isEmpty ==
                  true
              ? null
              : (json['latestStateRevalidationReceiptRef'] as String?),
      latestStateRevalidationArtifactRef:
          (json['latestStateRevalidationArtifactRef'] as String?)
                      ?.trim()
                      .isEmpty ==
                  true
              ? null
              : (json['latestStateRevalidationArtifactRef'] as String?),
      latestStateRevalidatedAt:
          (json['latestStateRevalidatedAt'] as String?)?.trim().isEmpty == true
              ? null
              : DateTime.tryParse(
                  (json['latestStateRevalidatedAt'] ?? '').toString(),
                )?.toUtc(),
      latestStateRecoveryDecisionStatus:
          (json['latestStateRecoveryDecisionStatus'] ?? 'not_reviewed')
              .toString(),
      latestStateRecoveryDecisionArtifactRef:
          (json['latestStateRecoveryDecisionArtifactRef'] as String?)
                      ?.trim()
                      .isEmpty ==
                  true
              ? null
              : (json['latestStateRecoveryDecisionArtifactRef'] as String?),
      latestStateRecoveryDecisionRationale:
          (json['latestStateRecoveryDecisionRationale'] as String?)
                      ?.trim()
                      .isEmpty ==
                  true
              ? null
              : (json['latestStateRecoveryDecisionRationale'] as String?),
      latestStateRecoveryDecisionRecordedAt:
          (json['latestStateRecoveryDecisionRecordedAt'] as String?)
                      ?.trim()
                      .isEmpty ==
                  true
              ? null
              : DateTime.tryParse(
                  (json['latestStateRecoveryDecisionRecordedAt'] ?? '')
                      .toString(),
                )?.toUtc(),
      latestStateDeploymentReceiptRef:
          (json['latestStateDeploymentReceiptRef'] as String?)
                      ?.trim()
                      .isEmpty ==
                  true
              ? null
              : (json['latestStateDeploymentReceiptRef'] as String?),
      currentBasisStatus:
          (json['currentBasisStatus'] ?? 'replay_grounded_seed_basis')
              .toString(),
      latestStateHydrationStatus: (json['latestStateHydrationStatus'] ??
              'awaiting_latest_avrai_evidence_refresh')
          .toString(),
      latestStatePromotionReadiness: (json['latestStatePromotionReadiness'] ??
              'blocked_pending_latest_state_evidence')
          .toString(),
      latestStatePromotionBlockedReasons:
          (json['latestStatePromotionBlockedReasons'] as List<dynamic>? ??
                  const <dynamic>[])
              .map((entry) => entry.toString().trim())
              .where((entry) => entry.isNotEmpty)
              .toList(growable: false),
      hydrationFreshnessPosture: (json['hydrationFreshnessPosture'] ??
              'refresh_receipts_required_before_served_basis_change')
          .toString(),
      latestStateRefreshCadenceHours:
          (json['latestStateRefreshCadenceHours'] as num?)?.toInt() ?? 24,
      latestStateRefreshCadenceStatus:
          (json['latestStateRefreshCadenceStatus'] ??
                  'awaiting_first_refresh_receipts')
              .toString(),
      latestStateRefreshReferenceAt: DateTime.tryParse(
        (json['latestStateRefreshReferenceAt'] ?? '').toString(),
      )?.toUtc(),
      latestStateRefreshPolicySummaries:
          (json['latestStateRefreshPolicySummaries'] as List<dynamic>? ??
                  const <dynamic>[])
              .map((entry) => entry.toString().trim())
              .where((entry) => entry.isNotEmpty)
              .toList(growable: false),
      latestStateRefreshExecutionStatus:
          (json['latestStateRefreshExecutionStatus'] ?? 'not_checked')
              .toString(),
      latestStateRefreshExecutionReceiptRef:
          (json['latestStateRefreshExecutionReceiptRef'] as String?)
                      ?.trim()
                      .isEmpty ==
                  true
              ? null
              : (json['latestStateRefreshExecutionReceiptRef'] as String?),
      latestStateRefreshExecutionCheckedAt:
          (json['latestStateRefreshExecutionCheckedAt'] as String?)
                      ?.trim()
                      .isEmpty ==
                  true
              ? null
              : DateTime.tryParse(
                  (json['latestStateRefreshExecutionCheckedAt'] ?? '')
                      .toString(),
                )?.toUtc(),
      latestStateEvidenceRefsByFamily: refsByFamily,
      latestStateEvidenceSelectionSummariesByFamily: selectionSummariesByFamily,
      latestStateEvidenceAgingStatusesByFamily: agingStatusesByFamily,
      latestStateEvidenceAgingSummariesByFamily: agingSummariesByFamily,
      latestStateEvidenceAgingTransitionsByFamily: agingTransitionsByFamily,
      latestStateEvidenceAgingTrendsByFamily: agingTrendsByFamily,
      latestStateEvidenceAgingTrendSummariesByFamily:
          agingTrendSummariesByFamily,
      latestStateEvidencePolicyActionsByFamily: policyActionsByFamily,
      latestStateEvidencePolicyActionSummariesByFamily:
          policyActionSummariesByFamily,
      latestStateEvidenceRestageTargetsByFamily: restageTargetsByFamily,
      latestStateEvidenceRestageTargetSummariesByFamily:
          restageTargetSummariesByFamily,
    );
  }
}

class _ReplaySimulationLatestStateEvidenceSelection {
  const _ReplaySimulationLatestStateEvidenceSelection({
    required this.family,
    required this.selectedRef,
    required this.selectionStatus,
    required this.freshnessHours,
    required this.strengthScore,
    required this.receiptBacked,
    required this.policyFreshnessThresholdHours,
    required this.policyStrengthThreshold,
  });

  final String family;
  final String selectedRef;
  final String selectionStatus;
  final double freshnessHours;
  final double strengthScore;
  final bool receiptBacked;
  final double policyFreshnessThresholdHours;
  final double policyStrengthThreshold;

  String get summary {
    final freshnessLabel = freshnessHours.isFinite
        ? '${freshnessHours.toStringAsFixed(freshnessHours >= 100 ? 0 : 1)}h'
        : 'unknown freshness';
    final strengthLabel = '${(strengthScore.clamp(0.0, 1.0) * 100).round()}%';
    final policyFreshnessLabel =
        '${policyFreshnessThresholdHours.toStringAsFixed(0)}h';
    final policyStrengthLabel =
        '${(policyStrengthThreshold.clamp(0.0, 1.0) * 100).round()}%';
    final receiptLabel =
        receiptBacked ? 'receipt-backed' : 'not receipt-backed';
    return '${_describeHydrationEvidenceFamily(family)} -> $selectedRef (${_describeLivingCityPackMetadata(selectionStatus)}, $freshnessLabel, $strengthLabel strength, $receiptLabel, policy <= $policyFreshnessLabel and >= $policyStrengthLabel)';
  }
}

class _ReplaySimulationLatestStateEvidenceSelectionBundle {
  const _ReplaySimulationLatestStateEvidenceSelectionBundle({
    required this.refsByFamily,
    required this.selectionSummariesByFamily,
    required this.agingStatusesByFamily,
    required this.agingSummariesByFamily,
    required this.promotionReadiness,
    required this.promotionBlockedReasons,
    required this.hydrationStatus,
    required this.hydrationFreshnessPosture,
    required this.refreshPolicy,
  });

  final Map<String, String> refsByFamily;
  final Map<String, String> selectionSummariesByFamily;
  final Map<String, String> agingStatusesByFamily;
  final Map<String, String> agingSummariesByFamily;
  final String promotionReadiness;
  final List<String> promotionBlockedReasons;
  final String hydrationStatus;
  final String hydrationFreshnessPosture;
  final _ReplaySimulationLatestStateRefreshPolicy refreshPolicy;
}

class _ReplaySimulationLatestStateRefreshMaterialization {
  const _ReplaySimulationLatestStateRefreshMaterialization({
    required this.payloadByFamily,
    required this.agingTransitionsByFamily,
  });

  final Map<String, Map<String, dynamic>> payloadByFamily;
  final Map<String, String> agingTransitionsByFamily;
}

class _ReplaySimulationLatestStateRefreshPolicy {
  const _ReplaySimulationLatestStateRefreshPolicy({
    required this.supportedPlaceRef,
    required this.refreshCadenceHours,
    required this.freshnessThresholdHoursByFamily,
    required this.strengthThresholdByFamily,
  });

  final String supportedPlaceRef;
  final int refreshCadenceHours;
  final Map<String, double> freshnessThresholdHoursByFamily;
  final Map<String, double> strengthThresholdByFamily;

  double freshnessThresholdHoursFor(String family) =>
      freshnessThresholdHoursByFamily[family] ?? 24.0;

  double strengthThresholdFor(String family) =>
      strengthThresholdByFamily[family] ?? 0.70;

  List<String> get summaries {
    return freshnessThresholdHoursByFamily.keys.map((family) {
      final freshness = freshnessThresholdHoursFor(family).toStringAsFixed(0);
      final strength = (strengthThresholdFor(family) * 100).round();
      return '${_describeHydrationEvidenceFamily(family)} <= $freshness'
          'h, >= $strength% strength for $supportedPlaceRef';
    }).toList(growable: false);
  }
}

String _describeHydrationEvidenceFamily(String code) {
  switch (code.trim()) {
    case 'app_observations':
      return 'app observations';
    case 'runtime_os_locality_state':
      return 'runtime/OS locality state';
    case 'governed_reality_model_outputs':
      return 'governed reality-model outputs';
    default:
      return code.replaceAll('_', ' ').trim();
  }
}

String _describeLatestStateEvidenceAgingStatus(String value) {
  switch (value.trim()) {
    case 'seed_placeholder_active':
      return 'seed placeholder active';
    case 'within_policy_window':
      return 'within policy window';
    case 'within_policy_window_not_receipt_backed':
      return 'within policy window, not receipt-backed';
    case 'approaching_policy_edge':
      return 'approaching policy edge';
    case 'approaching_policy_edge_not_receipt_backed':
      return 'approaching policy edge, not receipt-backed';
    case 'past_policy_window_receipt_backed':
      return 'past policy window, receipt-backed';
    case 'past_policy_window_not_receipt_backed':
      return 'past policy window, not receipt-backed';
    default:
      return value.replaceAll('_', ' ').trim();
  }
}

String _describeLatestStateEvidenceAgingTrend(String value) {
  switch (value.trim()) {
    case 'stable_with_recent_refresh':
      return 'stable with recent refresh';
    case 'stable_but_carried_forward':
      return 'stable but carried forward';
    case 'degrading_without_newer_evidence':
      return 'degrading without newer evidence';
    case 'repeatedly_degrading':
      return 'repeatedly degrading';
    case 'recovered_after_degradation':
      return 'recovered after degradation';
    case 'awaiting_first_refresh_transition':
      return 'awaiting first refresh transition';
    default:
      return value.replaceAll('_', ' ').trim();
  }
}

String _describeLatestStateEvidencePolicyAction(String value) {
  switch (value.trim()) {
    case 'no_action_family_stable':
      return 'no action, family stable';
    case 'watch_family_closely':
      return 'watch family closely';
    case 'force_restaged_family_inputs':
      return 'force restaged family inputs';
    case 'block_served_basis_recovery_for_family':
      return 'block served-basis recovery for family';
    default:
      return value.replaceAll('_', ' ').trim();
  }
}

String _describeLatestStateEvidenceRestageTarget(String value) {
  if (value.startsWith('restage_input_family:')) {
    final family = value.substring('restage_input_family:'.length).trim();
    return 'restage input family `${_describeHydrationEvidenceFamily(family)}`';
  }
  return value.replaceAll('_', ' ').trim();
}

String _describeLivingCityPackMetadata(String value) {
  switch (value.trim()) {
    case 'versioned_living_city_pack':
      return 'versioned living city-pack';
    case 'replay_grounded_seed_basis':
      return 'replay-grounded seed basis';
    case 'awaiting_latest_avrai_evidence_refresh':
      return 'awaiting latest AVRAI evidence refresh';
    case 'staged_latest_avrai_evidence_refresh':
      return 'staged latest AVRAI evidence refresh';
    case 'staged_latest_avrai_evidence_refresh_blocked':
      return 'staged latest AVRAI evidence refresh blocked';
    case 'staged_latest_avrai_evidence_refresh_ready_for_review':
      return 'staged latest AVRAI evidence refresh ready for review';
    case 'blocked_pending_latest_state_evidence':
      return 'blocked pending latest-state evidence';
    case 'family_policy_requires_restaged_inputs_before_review':
      return 'family policy requires restaged inputs before review';
    case 'family_policy_action_blocks_served_basis_recovery':
      return 'family policy action blocks served-basis recovery';
    case 'family_policy_restage_targets_required':
      return 'family policy restage targets required';
    case 'queued_for_family_restage_review':
      return 'queued for family restage review';
    case 'restage_intake_requested':
      return 'restage intake requested';
    case 'watch_family_before_restage':
      return 'watch family before restage';
    case 'restage_intake_review_approved':
      return 'restage intake review approved';
    case 'restage_intake_review_held':
      return 'restage intake review held';
    case 'queued_for_family_restage_follow_up_review':
      return 'queued for family restage follow-up review';
    case 'queued_for_family_restage_resolution_review':
      return 'queued for family restage resolution review';
    case 'queued_for_family_restage_execution_review':
      return 'queued for family restage execution review';
    case 'queued_for_family_restage_application_review':
      return 'queued for family restage application review';
    case 'queued_for_family_restage_apply_review':
      return 'queued for family restage apply review';
    case 'queued_for_family_restage_served_basis_update_review':
      return 'queued for family restage served basis update review';
    case 'approved_for_bounded_family_restage_execution':
      return 'approved for bounded family restage execution';
    case 'approved_for_bounded_family_restage_application':
      return 'approved for bounded family restage application';
    case 'approved_for_bounded_family_restage_apply_to_served_basis':
      return 'approved for bounded family restage apply to served basis';
    case 'approved_for_bounded_family_restage_served_basis_update':
      return 'approved for bounded family restage served basis update';
    case 'approved_for_bounded_family_restage_served_basis_mutation':
      return 'approved for bounded family restage served basis mutation';
    case 'held_for_more_family_restage_resolution_evidence':
      return 'held for more family restage resolution evidence';
    case 'held_for_more_family_restage_execution_evidence':
      return 'held for more family restage execution evidence';
    case 'held_for_more_family_restage_application_evidence':
      return 'held for more family restage application evidence';
    case 'held_for_more_family_restage_apply_evidence':
      return 'held for more family restage apply evidence';
    case 'held_for_more_family_restage_served_basis_update_evidence':
      return 'held for more family restage served basis update evidence';
    case 'ready_for_bounded_basis_review':
      return 'ready for bounded basis review';
    case 'promoted_to_served_basis':
      return 'promoted to served basis';
    case 'served_basis_revalidated_current':
      return 'served basis revalidated current';
    case 'restage_required_before_served_basis_reuse':
      return 'restage required before served-basis reuse';
    case 'ready_for_bounded_served_basis_restore':
      return 'ready for bounded served-basis restore';
    case 'restored_to_served_basis_after_review':
      return 'restored to served basis after review';
    case 'awaiting_basis_review_decision':
      return 'awaiting basis review decision';
    case 'promoted':
      return 'promoted';
    case 'rejected':
      return 'rejected';
    case 'not_reviewed':
      return 'not reviewed';
    case 'restage_required_confirmed':
      return 'restage required confirmed';
    case 'restored_after_review':
      return 'restored after review';
    case 'not_revalidated':
      return 'not revalidated';
    case 'current':
      return 'current';
    case 'expired':
      return 'expired';
    case 'latest_state_basis_served':
      return 'latest-state basis served';
    case 'latest_state_basis_served_revalidated':
      return 'latest-state basis served and revalidated';
    case 'latest_state_basis_served_expired':
      return 'latest-state served basis expired';
    case 'expired_basis_ready_for_restore_review':
      return 'expired basis ready for restore review';
    case 'latest_state_basis_restored_after_review':
      return 'latest-state basis restored after review';
    case 'expired_basis_restage_required_confirmed':
      return 'expired basis restage required confirmed';
    case 'latest_state_basis_rejected':
      return 'latest-state basis rejected';
    case 'expired_latest_state_served_basis':
      return 'expired latest-state served basis';
    case 'served_basis_updated_from_latest_state_receipts':
      return 'served basis updated from latest-state receipts';
    case 'served_basis_still_supported_by_current_receipts':
      return 'served basis still supported by current receipts';
    case 'promoted_served_basis_expired_pending_restage':
      return 'promoted served basis expired pending restage';
    case 'expired_basis_supported_by_current_receipts_pending_restore_review':
      return 'expired basis supported by current receipts pending restore review';
    case 'served_basis_restored_from_revalidated_receipts':
      return 'served basis restored from revalidated receipts';
    case 'prior_served_basis_restored_after_rejection':
      return 'prior served basis restored after rejection';
    case 'refresh_receipts_required_before_served_basis_change':
      return 'refresh receipts required before served basis changes';
    case 'ready_for_served_basis_review_with_receipts':
      return 'ready for served-basis review with receipts';
    case 'awaiting_first_refresh_receipts':
      return 'awaiting first refresh receipts';
    case 'within_refresh_window':
      return 'within refresh window';
    case 'due_for_refresh':
      return 'due for refresh';
    case 'overdue_for_refresh':
      return 'overdue for refresh';
    case 'not_checked':
      return 'not checked';
    case 'executed_initial_refresh':
      return 'executed initial refresh';
    case 'executed_due_refresh':
      return 'executed due refresh';
    case 'executed_overdue_refresh':
      return 'executed overdue refresh';
    case 'skipped_within_refresh_window':
      return 'skipped within refresh window';
    case 'selected_current_evidence':
      return 'selected current evidence';
    case 'seed_placeholder':
      return 'seed placeholder';
    default:
      return value.replaceAll('_', ' ').trim();
  }
}

DateTime? _parseNullableDateTime(Object? raw) {
  final text = raw?.toString().trim() ?? '';
  if (text.isEmpty) {
    return null;
  }
  return DateTime.tryParse(text)?.toUtc();
}

class ReplaySimulationLabFamilyRestageReviewItem {
  const ReplaySimulationLabFamilyRestageReviewItem({
    required this.itemId,
    required this.environmentId,
    required this.supportedPlaceRef,
    required this.evidenceFamily,
    required this.restageTarget,
    required this.restageTargetSummary,
    required this.policyAction,
    required this.policyActionSummary,
    required this.queuedAt,
    required this.queueStatus,
    required this.itemRoot,
    required this.itemJsonPath,
    required this.readmePath,
    required this.servedBasisRef,
    required this.currentBasisStatus,
    this.queueDecisionArtifactRef,
    this.queueDecisionRationale,
    this.queueDecisionRecordedAt,
    this.restageIntakeQueueJsonPath,
    this.restageIntakeReadmePath,
    this.restageIntakeSourceId,
    this.restageIntakeJobId,
    this.restageIntakeReviewItemId,
    this.restageIntakeResolutionStatus,
    this.restageIntakeResolutionArtifactRef,
    this.restageIntakeResolutionRationale,
    this.restageIntakeResolutionRecordedAt,
    this.followUpQueueStatus,
    this.followUpQueueJsonPath,
    this.followUpReadmePath,
    this.followUpSourceId,
    this.followUpJobId,
    this.followUpReviewItemId,
    this.followUpResolutionStatus,
    this.followUpResolutionArtifactRef,
    this.followUpResolutionRationale,
    this.followUpResolutionRecordedAt,
    this.restageResolutionQueueStatus,
    this.restageResolutionQueueJsonPath,
    this.restageResolutionReadmePath,
    this.restageResolutionSourceId,
    this.restageResolutionJobId,
    this.restageResolutionReviewItemId,
    this.restageResolutionResolutionStatus,
    this.restageResolutionResolutionArtifactRef,
    this.restageResolutionResolutionRationale,
    this.restageResolutionResolutionRecordedAt,
    this.restageExecutionQueueStatus,
    this.restageExecutionQueueJsonPath,
    this.restageExecutionReadmePath,
    this.restageExecutionSourceId,
    this.restageExecutionJobId,
    this.restageExecutionReviewItemId,
    this.restageExecutionResolutionStatus,
    this.restageExecutionResolutionArtifactRef,
    this.restageExecutionResolutionRationale,
    this.restageExecutionResolutionRecordedAt,
    this.restageApplicationQueueStatus,
    this.restageApplicationQueueJsonPath,
    this.restageApplicationReadmePath,
    this.restageApplicationSourceId,
    this.restageApplicationJobId,
    this.restageApplicationReviewItemId,
    this.restageApplicationResolutionStatus,
    this.restageApplicationResolutionArtifactRef,
    this.restageApplicationResolutionRationale,
    this.restageApplicationResolutionRecordedAt,
    this.restageApplyQueueStatus,
    this.restageApplyQueueJsonPath,
    this.restageApplyReadmePath,
    this.restageApplySourceId,
    this.restageApplyJobId,
    this.restageApplyReviewItemId,
    this.restageApplyResolutionStatus,
    this.restageApplyResolutionArtifactRef,
    this.restageApplyResolutionRationale,
    this.restageApplyResolutionRecordedAt,
    this.restageServedBasisUpdateQueueStatus,
    this.restageServedBasisUpdateQueueJsonPath,
    this.restageServedBasisUpdateReadmePath,
    this.restageServedBasisUpdateSourceId,
    this.restageServedBasisUpdateJobId,
    this.restageServedBasisUpdateReviewItemId,
    this.restageServedBasisUpdateResolutionStatus,
    this.restageServedBasisUpdateResolutionArtifactRef,
    this.restageServedBasisUpdateResolutionRationale,
    this.restageServedBasisUpdateResolutionRecordedAt,
    this.cityPackStructuralRef,
    this.latestStateRefreshReceiptRef,
    this.latestStateRevalidationReceiptRef,
    this.basisRefreshLineageRef,
  });

  final String itemId;
  final String environmentId;
  final String supportedPlaceRef;
  final String evidenceFamily;
  final String restageTarget;
  final String restageTargetSummary;
  final String policyAction;
  final String policyActionSummary;
  final DateTime queuedAt;
  final String queueStatus;
  final String itemRoot;
  final String itemJsonPath;
  final String readmePath;
  final String servedBasisRef;
  final String currentBasisStatus;
  final String? queueDecisionArtifactRef;
  final String? queueDecisionRationale;
  final DateTime? queueDecisionRecordedAt;
  final String? restageIntakeQueueJsonPath;
  final String? restageIntakeReadmePath;
  final String? restageIntakeSourceId;
  final String? restageIntakeJobId;
  final String? restageIntakeReviewItemId;
  final String? restageIntakeResolutionStatus;
  final String? restageIntakeResolutionArtifactRef;
  final String? restageIntakeResolutionRationale;
  final DateTime? restageIntakeResolutionRecordedAt;
  final String? followUpQueueStatus;
  final String? followUpQueueJsonPath;
  final String? followUpReadmePath;
  final String? followUpSourceId;
  final String? followUpJobId;
  final String? followUpReviewItemId;
  final String? followUpResolutionStatus;
  final String? followUpResolutionArtifactRef;
  final String? followUpResolutionRationale;
  final DateTime? followUpResolutionRecordedAt;
  final String? restageResolutionQueueStatus;
  final String? restageResolutionQueueJsonPath;
  final String? restageResolutionReadmePath;
  final String? restageResolutionSourceId;
  final String? restageResolutionJobId;
  final String? restageResolutionReviewItemId;
  final String? restageResolutionResolutionStatus;
  final String? restageResolutionResolutionArtifactRef;
  final String? restageResolutionResolutionRationale;
  final DateTime? restageResolutionResolutionRecordedAt;
  final String? restageExecutionQueueStatus;
  final String? restageExecutionQueueJsonPath;
  final String? restageExecutionReadmePath;
  final String? restageExecutionSourceId;
  final String? restageExecutionJobId;
  final String? restageExecutionReviewItemId;
  final String? restageExecutionResolutionStatus;
  final String? restageExecutionResolutionArtifactRef;
  final String? restageExecutionResolutionRationale;
  final DateTime? restageExecutionResolutionRecordedAt;
  final String? restageApplicationQueueStatus;
  final String? restageApplicationQueueJsonPath;
  final String? restageApplicationReadmePath;
  final String? restageApplicationSourceId;
  final String? restageApplicationJobId;
  final String? restageApplicationReviewItemId;
  final String? restageApplicationResolutionStatus;
  final String? restageApplicationResolutionArtifactRef;
  final String? restageApplicationResolutionRationale;
  final DateTime? restageApplicationResolutionRecordedAt;
  final String? restageApplyQueueStatus;
  final String? restageApplyQueueJsonPath;
  final String? restageApplyReadmePath;
  final String? restageApplySourceId;
  final String? restageApplyJobId;
  final String? restageApplyReviewItemId;
  final String? restageApplyResolutionStatus;
  final String? restageApplyResolutionArtifactRef;
  final String? restageApplyResolutionRationale;
  final DateTime? restageApplyResolutionRecordedAt;
  final String? restageServedBasisUpdateQueueStatus;
  final String? restageServedBasisUpdateQueueJsonPath;
  final String? restageServedBasisUpdateReadmePath;
  final String? restageServedBasisUpdateSourceId;
  final String? restageServedBasisUpdateJobId;
  final String? restageServedBasisUpdateReviewItemId;
  final String? restageServedBasisUpdateResolutionStatus;
  final String? restageServedBasisUpdateResolutionArtifactRef;
  final String? restageServedBasisUpdateResolutionRationale;
  final DateTime? restageServedBasisUpdateResolutionRecordedAt;
  final String? cityPackStructuralRef;
  final String? latestStateRefreshReceiptRef;
  final String? latestStateRevalidationReceiptRef;
  final String? basisRefreshLineageRef;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'itemId': itemId,
      'environmentId': environmentId,
      'supportedPlaceRef': supportedPlaceRef,
      'evidenceFamily': evidenceFamily,
      'restageTarget': restageTarget,
      'restageTargetSummary': restageTargetSummary,
      'policyAction': policyAction,
      'policyActionSummary': policyActionSummary,
      'queuedAt': queuedAt.toUtc().toIso8601String(),
      'queueStatus': queueStatus,
      'itemRoot': itemRoot,
      'itemJsonPath': itemJsonPath,
      'readmePath': readmePath,
      'servedBasisRef': servedBasisRef,
      'currentBasisStatus': currentBasisStatus,
      'queueDecisionArtifactRef': queueDecisionArtifactRef,
      'queueDecisionRationale': queueDecisionRationale,
      'queueDecisionRecordedAt':
          queueDecisionRecordedAt?.toUtc().toIso8601String(),
      'restageIntakeQueueJsonPath': restageIntakeQueueJsonPath,
      'restageIntakeReadmePath': restageIntakeReadmePath,
      'restageIntakeSourceId': restageIntakeSourceId,
      'restageIntakeJobId': restageIntakeJobId,
      'restageIntakeReviewItemId': restageIntakeReviewItemId,
      'restageIntakeResolutionStatus': restageIntakeResolutionStatus,
      'restageIntakeResolutionArtifactRef': restageIntakeResolutionArtifactRef,
      'restageIntakeResolutionRationale': restageIntakeResolutionRationale,
      'restageIntakeResolutionRecordedAt':
          restageIntakeResolutionRecordedAt?.toUtc().toIso8601String(),
      'followUpQueueStatus': followUpQueueStatus,
      'followUpQueueJsonPath': followUpQueueJsonPath,
      'followUpReadmePath': followUpReadmePath,
      'followUpSourceId': followUpSourceId,
      'followUpJobId': followUpJobId,
      'followUpReviewItemId': followUpReviewItemId,
      'followUpResolutionStatus': followUpResolutionStatus,
      'followUpResolutionArtifactRef': followUpResolutionArtifactRef,
      'followUpResolutionRationale': followUpResolutionRationale,
      'followUpResolutionRecordedAt':
          followUpResolutionRecordedAt?.toUtc().toIso8601String(),
      'restageResolutionQueueStatus': restageResolutionQueueStatus,
      'restageResolutionQueueJsonPath': restageResolutionQueueJsonPath,
      'restageResolutionReadmePath': restageResolutionReadmePath,
      'restageResolutionSourceId': restageResolutionSourceId,
      'restageResolutionJobId': restageResolutionJobId,
      'restageResolutionReviewItemId': restageResolutionReviewItemId,
      'restageResolutionResolutionStatus': restageResolutionResolutionStatus,
      'restageResolutionResolutionArtifactRef':
          restageResolutionResolutionArtifactRef,
      'restageResolutionResolutionRationale':
          restageResolutionResolutionRationale,
      'restageResolutionResolutionRecordedAt':
          restageResolutionResolutionRecordedAt?.toUtc().toIso8601String(),
      'restageExecutionQueueStatus': restageExecutionQueueStatus,
      'restageExecutionQueueJsonPath': restageExecutionQueueJsonPath,
      'restageExecutionReadmePath': restageExecutionReadmePath,
      'restageExecutionSourceId': restageExecutionSourceId,
      'restageExecutionJobId': restageExecutionJobId,
      'restageExecutionReviewItemId': restageExecutionReviewItemId,
      'restageExecutionResolutionStatus': restageExecutionResolutionStatus,
      'restageExecutionResolutionArtifactRef':
          restageExecutionResolutionArtifactRef,
      'restageExecutionResolutionRationale':
          restageExecutionResolutionRationale,
      'restageExecutionResolutionRecordedAt':
          restageExecutionResolutionRecordedAt?.toUtc().toIso8601String(),
      'restageApplicationQueueStatus': restageApplicationQueueStatus,
      'restageApplicationQueueJsonPath': restageApplicationQueueJsonPath,
      'restageApplicationReadmePath': restageApplicationReadmePath,
      'restageApplicationSourceId': restageApplicationSourceId,
      'restageApplicationJobId': restageApplicationJobId,
      'restageApplicationReviewItemId': restageApplicationReviewItemId,
      'restageApplicationResolutionStatus': restageApplicationResolutionStatus,
      'restageApplicationResolutionArtifactRef':
          restageApplicationResolutionArtifactRef,
      'restageApplicationResolutionRationale':
          restageApplicationResolutionRationale,
      'restageApplicationResolutionRecordedAt':
          restageApplicationResolutionRecordedAt?.toUtc().toIso8601String(),
      'restageApplyQueueStatus': restageApplyQueueStatus,
      'restageApplyQueueJsonPath': restageApplyQueueJsonPath,
      'restageApplyReadmePath': restageApplyReadmePath,
      'restageApplySourceId': restageApplySourceId,
      'restageApplyJobId': restageApplyJobId,
      'restageApplyReviewItemId': restageApplyReviewItemId,
      'restageApplyResolutionStatus': restageApplyResolutionStatus,
      'restageApplyResolutionArtifactRef': restageApplyResolutionArtifactRef,
      'restageApplyResolutionRationale': restageApplyResolutionRationale,
      'restageApplyResolutionRecordedAt':
          restageApplyResolutionRecordedAt?.toUtc().toIso8601String(),
      'restageServedBasisUpdateQueueStatus':
          restageServedBasisUpdateQueueStatus,
      'restageServedBasisUpdateQueueJsonPath':
          restageServedBasisUpdateQueueJsonPath,
      'restageServedBasisUpdateReadmePath': restageServedBasisUpdateReadmePath,
      'restageServedBasisUpdateSourceId': restageServedBasisUpdateSourceId,
      'restageServedBasisUpdateJobId': restageServedBasisUpdateJobId,
      'restageServedBasisUpdateReviewItemId':
          restageServedBasisUpdateReviewItemId,
      'restageServedBasisUpdateResolutionStatus':
          restageServedBasisUpdateResolutionStatus,
      'restageServedBasisUpdateResolutionArtifactRef':
          restageServedBasisUpdateResolutionArtifactRef,
      'restageServedBasisUpdateResolutionRationale':
          restageServedBasisUpdateResolutionRationale,
      'restageServedBasisUpdateResolutionRecordedAt':
          restageServedBasisUpdateResolutionRecordedAt
              ?.toUtc()
              .toIso8601String(),
      'cityPackStructuralRef': cityPackStructuralRef,
      'latestStateRefreshReceiptRef': latestStateRefreshReceiptRef,
      'latestStateRevalidationReceiptRef': latestStateRevalidationReceiptRef,
      'basisRefreshLineageRef': basisRefreshLineageRef,
    };
  }

  factory ReplaySimulationLabFamilyRestageReviewItem.fromJson(
    Map<String, dynamic> json,
  ) {
    return ReplaySimulationLabFamilyRestageReviewItem(
      itemId: (json['itemId'] ?? '').toString(),
      environmentId: (json['environmentId'] ?? '').toString(),
      supportedPlaceRef: (json['supportedPlaceRef'] ?? '').toString(),
      evidenceFamily: (json['evidenceFamily'] ?? '').toString(),
      restageTarget: (json['restageTarget'] ?? '').toString(),
      restageTargetSummary: (json['restageTargetSummary'] ?? '').toString(),
      policyAction: (json['policyAction'] ?? '').toString(),
      policyActionSummary: (json['policyActionSummary'] ?? '').toString(),
      queuedAt: DateTime.tryParse((json['queuedAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      queueStatus: (json['queueStatus'] ?? 'queued_for_family_restage_review')
          .toString(),
      itemRoot: (json['itemRoot'] ?? '').toString(),
      itemJsonPath: (json['itemJsonPath'] ?? '').toString(),
      readmePath: (json['readmePath'] ?? '').toString(),
      servedBasisRef: (json['servedBasisRef'] ?? '').toString(),
      currentBasisStatus: (json['currentBasisStatus'] ?? '').toString(),
      queueDecisionArtifactRef:
          (json['queueDecisionArtifactRef'] as String?)?.trim().isEmpty == true
              ? null
              : (json['queueDecisionArtifactRef'] as String?),
      queueDecisionRationale:
          (json['queueDecisionRationale'] as String?)?.trim().isEmpty == true
              ? null
              : (json['queueDecisionRationale'] as String?),
      queueDecisionRecordedAt:
          (json['queueDecisionRecordedAt'] as String?)?.trim().isEmpty == true
              ? null
              : DateTime.tryParse(
                  (json['queueDecisionRecordedAt'] ?? '').toString(),
                )?.toUtc(),
      restageIntakeQueueJsonPath:
          (json['restageIntakeQueueJsonPath'] as String?)?.trim().isEmpty ==
                  true
              ? null
              : (json['restageIntakeQueueJsonPath'] as String?),
      restageIntakeReadmePath:
          (json['restageIntakeReadmePath'] as String?)?.trim().isEmpty == true
              ? null
              : (json['restageIntakeReadmePath'] as String?),
      restageIntakeSourceId:
          (json['restageIntakeSourceId'] as String?)?.trim().isEmpty == true
              ? null
              : (json['restageIntakeSourceId'] as String?),
      restageIntakeJobId:
          (json['restageIntakeJobId'] as String?)?.trim().isEmpty == true
              ? null
              : (json['restageIntakeJobId'] as String?),
      restageIntakeReviewItemId:
          (json['restageIntakeReviewItemId'] as String?)?.trim().isEmpty == true
              ? null
              : (json['restageIntakeReviewItemId'] as String?),
      restageIntakeResolutionStatus:
          (json['restageIntakeResolutionStatus'] as String?)?.trim().isEmpty ==
                  true
              ? null
              : (json['restageIntakeResolutionStatus'] as String?),
      restageIntakeResolutionArtifactRef:
          (json['restageIntakeResolutionArtifactRef'] as String?)
                      ?.trim()
                      .isEmpty ==
                  true
              ? null
              : (json['restageIntakeResolutionArtifactRef'] as String?),
      restageIntakeResolutionRationale:
          (json['restageIntakeResolutionRationale'] as String?)
                      ?.trim()
                      .isEmpty ==
                  true
              ? null
              : (json['restageIntakeResolutionRationale'] as String?),
      restageIntakeResolutionRecordedAt:
          (json['restageIntakeResolutionRecordedAt'] as String?)
                      ?.trim()
                      .isEmpty ==
                  true
              ? null
              : DateTime.tryParse(
                  (json['restageIntakeResolutionRecordedAt'] ?? '').toString(),
                )?.toUtc(),
      followUpQueueStatus:
          (json['followUpQueueStatus'] as String?)?.trim().isEmpty == true
              ? null
              : (json['followUpQueueStatus'] as String?),
      followUpQueueJsonPath:
          (json['followUpQueueJsonPath'] as String?)?.trim().isEmpty == true
              ? null
              : (json['followUpQueueJsonPath'] as String?),
      followUpReadmePath:
          (json['followUpReadmePath'] as String?)?.trim().isEmpty == true
              ? null
              : (json['followUpReadmePath'] as String?),
      followUpSourceId:
          (json['followUpSourceId'] as String?)?.trim().isEmpty == true
              ? null
              : (json['followUpSourceId'] as String?),
      followUpJobId: (json['followUpJobId'] as String?)?.trim().isEmpty == true
          ? null
          : (json['followUpJobId'] as String?),
      followUpReviewItemId:
          (json['followUpReviewItemId'] as String?)?.trim().isEmpty == true
              ? null
              : (json['followUpReviewItemId'] as String?),
      followUpResolutionStatus:
          (json['followUpResolutionStatus'] as String?)?.trim().isEmpty == true
              ? null
              : (json['followUpResolutionStatus'] as String?),
      followUpResolutionArtifactRef:
          (json['followUpResolutionArtifactRef'] as String?)?.trim().isEmpty ==
                  true
              ? null
              : (json['followUpResolutionArtifactRef'] as String?),
      followUpResolutionRationale:
          (json['followUpResolutionRationale'] as String?)?.trim().isEmpty ==
                  true
              ? null
              : (json['followUpResolutionRationale'] as String?),
      followUpResolutionRecordedAt: _parseNullableDateTime(
        json['followUpResolutionRecordedAt'],
      ),
      restageResolutionQueueStatus:
          (json['restageResolutionQueueStatus'] as String?)?.trim().isEmpty ==
                  true
              ? null
              : (json['restageResolutionQueueStatus'] as String?),
      restageResolutionQueueJsonPath:
          (json['restageResolutionQueueJsonPath'] as String?)?.trim().isEmpty ==
                  true
              ? null
              : (json['restageResolutionQueueJsonPath'] as String?),
      restageResolutionReadmePath:
          (json['restageResolutionReadmePath'] as String?)?.trim().isEmpty ==
                  true
              ? null
              : (json['restageResolutionReadmePath'] as String?),
      restageResolutionSourceId:
          (json['restageResolutionSourceId'] as String?)?.trim().isEmpty == true
              ? null
              : (json['restageResolutionSourceId'] as String?),
      restageResolutionJobId:
          (json['restageResolutionJobId'] as String?)?.trim().isEmpty == true
              ? null
              : (json['restageResolutionJobId'] as String?),
      restageResolutionReviewItemId:
          (json['restageResolutionReviewItemId'] as String?)?.trim().isEmpty ==
                  true
              ? null
              : (json['restageResolutionReviewItemId'] as String?),
      restageResolutionResolutionStatus:
          (json['restageResolutionResolutionStatus'] as String?)
                      ?.trim()
                      .isEmpty ==
                  true
              ? null
              : (json['restageResolutionResolutionStatus'] as String?),
      restageResolutionResolutionArtifactRef:
          (json['restageResolutionResolutionArtifactRef'] as String?)
                      ?.trim()
                      .isEmpty ==
                  true
              ? null
              : (json['restageResolutionResolutionArtifactRef'] as String?),
      restageResolutionResolutionRationale:
          (json['restageResolutionResolutionRationale'] as String?)
                      ?.trim()
                      .isEmpty ==
                  true
              ? null
              : (json['restageResolutionResolutionRationale'] as String?),
      restageResolutionResolutionRecordedAt: _parseNullableDateTime(
        json['restageResolutionResolutionRecordedAt'],
      ),
      restageExecutionQueueStatus:
          (json['restageExecutionQueueStatus'] as String?)?.trim().isEmpty ==
                  true
              ? null
              : (json['restageExecutionQueueStatus'] as String?),
      restageExecutionQueueJsonPath:
          (json['restageExecutionQueueJsonPath'] as String?)?.trim().isEmpty ==
                  true
              ? null
              : (json['restageExecutionQueueJsonPath'] as String?),
      restageExecutionReadmePath:
          (json['restageExecutionReadmePath'] as String?)?.trim().isEmpty ==
                  true
              ? null
              : (json['restageExecutionReadmePath'] as String?),
      restageExecutionSourceId:
          (json['restageExecutionSourceId'] as String?)?.trim().isEmpty == true
              ? null
              : (json['restageExecutionSourceId'] as String?),
      restageExecutionJobId:
          (json['restageExecutionJobId'] as String?)?.trim().isEmpty == true
              ? null
              : (json['restageExecutionJobId'] as String?),
      restageExecutionReviewItemId:
          (json['restageExecutionReviewItemId'] as String?)?.trim().isEmpty ==
                  true
              ? null
              : (json['restageExecutionReviewItemId'] as String?),
      restageExecutionResolutionStatus:
          (json['restageExecutionResolutionStatus'] as String?)
                      ?.trim()
                      .isEmpty ==
                  true
              ? null
              : (json['restageExecutionResolutionStatus'] as String?),
      restageExecutionResolutionArtifactRef:
          (json['restageExecutionResolutionArtifactRef'] as String?)
                      ?.trim()
                      .isEmpty ==
                  true
              ? null
              : (json['restageExecutionResolutionArtifactRef'] as String?),
      restageExecutionResolutionRationale:
          (json['restageExecutionResolutionRationale'] as String?)
                      ?.trim()
                      .isEmpty ==
                  true
              ? null
              : (json['restageExecutionResolutionRationale'] as String?),
      restageExecutionResolutionRecordedAt: _parseNullableDateTime(
        json['restageExecutionResolutionRecordedAt'],
      ),
      restageApplicationQueueStatus:
          (json['restageApplicationQueueStatus'] as String?)?.trim().isEmpty ==
                  true
              ? null
              : (json['restageApplicationQueueStatus'] as String?),
      restageApplicationQueueJsonPath:
          (json['restageApplicationQueueJsonPath'] as String?)
                      ?.trim()
                      .isEmpty ==
                  true
              ? null
              : (json['restageApplicationQueueJsonPath'] as String?),
      restageApplicationReadmePath:
          (json['restageApplicationReadmePath'] as String?)?.trim().isEmpty ==
                  true
              ? null
              : (json['restageApplicationReadmePath'] as String?),
      restageApplicationSourceId:
          (json['restageApplicationSourceId'] as String?)?.trim().isEmpty ==
                  true
              ? null
              : (json['restageApplicationSourceId'] as String?),
      restageApplicationJobId:
          (json['restageApplicationJobId'] as String?)?.trim().isEmpty == true
              ? null
              : (json['restageApplicationJobId'] as String?),
      restageApplicationReviewItemId:
          (json['restageApplicationReviewItemId'] as String?)?.trim().isEmpty ==
                  true
              ? null
              : (json['restageApplicationReviewItemId'] as String?),
      restageApplicationResolutionStatus:
          (json['restageApplicationResolutionStatus'] as String?)
                      ?.trim()
                      .isEmpty ==
                  true
              ? null
              : (json['restageApplicationResolutionStatus'] as String?),
      restageApplicationResolutionArtifactRef:
          (json['restageApplicationResolutionArtifactRef'] as String?)
                      ?.trim()
                      .isEmpty ==
                  true
              ? null
              : (json['restageApplicationResolutionArtifactRef'] as String?),
      restageApplicationResolutionRationale:
          (json['restageApplicationResolutionRationale'] as String?)
                      ?.trim()
                      .isEmpty ==
                  true
              ? null
              : (json['restageApplicationResolutionRationale'] as String?),
      restageApplicationResolutionRecordedAt: _parseNullableDateTime(
        json['restageApplicationResolutionRecordedAt'],
      ),
      restageApplyQueueStatus:
          (json['restageApplyQueueStatus'] as String?)?.trim().isEmpty == true
              ? null
              : (json['restageApplyQueueStatus'] as String?),
      restageApplyQueueJsonPath:
          (json['restageApplyQueueJsonPath'] as String?)?.trim().isEmpty == true
              ? null
              : (json['restageApplyQueueJsonPath'] as String?),
      restageApplyReadmePath:
          (json['restageApplyReadmePath'] as String?)?.trim().isEmpty == true
              ? null
              : (json['restageApplyReadmePath'] as String?),
      restageApplySourceId:
          (json['restageApplySourceId'] as String?)?.trim().isEmpty == true
              ? null
              : (json['restageApplySourceId'] as String?),
      restageApplyJobId:
          (json['restageApplyJobId'] as String?)?.trim().isEmpty == true
              ? null
              : (json['restageApplyJobId'] as String?),
      restageApplyReviewItemId:
          (json['restageApplyReviewItemId'] as String?)?.trim().isEmpty == true
              ? null
              : (json['restageApplyReviewItemId'] as String?),
      restageApplyResolutionStatus:
          (json['restageApplyResolutionStatus'] as String?)?.trim().isEmpty ==
                  true
              ? null
              : (json['restageApplyResolutionStatus'] as String?),
      restageApplyResolutionArtifactRef:
          (json['restageApplyResolutionArtifactRef'] as String?)
                      ?.trim()
                      .isEmpty ==
                  true
              ? null
              : (json['restageApplyResolutionArtifactRef'] as String?),
      restageApplyResolutionRationale:
          (json['restageApplyResolutionRationale'] as String?)
                      ?.trim()
                      .isEmpty ==
                  true
              ? null
              : (json['restageApplyResolutionRationale'] as String?),
      restageApplyResolutionRecordedAt: _parseNullableDateTime(
        json['restageApplyResolutionRecordedAt'],
      ),
      restageServedBasisUpdateQueueStatus:
          (json['restageServedBasisUpdateQueueStatus'] as String?)
                      ?.trim()
                      .isEmpty ==
                  true
              ? null
              : (json['restageServedBasisUpdateQueueStatus'] as String?),
      restageServedBasisUpdateQueueJsonPath:
          (json['restageServedBasisUpdateQueueJsonPath'] as String?)
                      ?.trim()
                      .isEmpty ==
                  true
              ? null
              : (json['restageServedBasisUpdateQueueJsonPath'] as String?),
      restageServedBasisUpdateReadmePath:
          (json['restageServedBasisUpdateReadmePath'] as String?)
                      ?.trim()
                      .isEmpty ==
                  true
              ? null
              : (json['restageServedBasisUpdateReadmePath'] as String?),
      restageServedBasisUpdateSourceId:
          (json['restageServedBasisUpdateSourceId'] as String?)
                      ?.trim()
                      .isEmpty ==
                  true
              ? null
              : (json['restageServedBasisUpdateSourceId'] as String?),
      restageServedBasisUpdateJobId:
          (json['restageServedBasisUpdateJobId'] as String?)?.trim().isEmpty ==
                  true
              ? null
              : (json['restageServedBasisUpdateJobId'] as String?),
      restageServedBasisUpdateReviewItemId:
          (json['restageServedBasisUpdateReviewItemId'] as String?)
                      ?.trim()
                      .isEmpty ==
                  true
              ? null
              : (json['restageServedBasisUpdateReviewItemId'] as String?),
      restageServedBasisUpdateResolutionStatus:
          (json['restageServedBasisUpdateResolutionStatus'] as String?)
                      ?.trim()
                      .isEmpty ==
                  true
              ? null
              : (json['restageServedBasisUpdateResolutionStatus'] as String?),
      restageServedBasisUpdateResolutionArtifactRef:
          (json['restageServedBasisUpdateResolutionArtifactRef'] as String?)
                      ?.trim()
                      .isEmpty ==
                  true
              ? null
              : (json['restageServedBasisUpdateResolutionArtifactRef']
                  as String?),
      restageServedBasisUpdateResolutionRationale:
          (json['restageServedBasisUpdateResolutionRationale'] as String?)
                      ?.trim()
                      .isEmpty ==
                  true
              ? null
              : (json['restageServedBasisUpdateResolutionRationale']
                  as String?),
      restageServedBasisUpdateResolutionRecordedAt:
          (json['restageServedBasisUpdateResolutionRecordedAt'] as String?)
                      ?.trim()
                      .isEmpty ==
                  true
              ? null
              : DateTime.tryParse(
                  (json['restageServedBasisUpdateResolutionRecordedAt'] ?? '')
                      .toString(),
                )?.toUtc(),
      cityPackStructuralRef:
          (json['cityPackStructuralRef'] as String?)?.trim().isEmpty == true
              ? null
              : (json['cityPackStructuralRef'] as String?),
      latestStateRefreshReceiptRef:
          (json['latestStateRefreshReceiptRef'] as String?)?.trim().isEmpty ==
                  true
              ? null
              : (json['latestStateRefreshReceiptRef'] as String?),
      latestStateRevalidationReceiptRef:
          (json['latestStateRevalidationReceiptRef'] as String?)
                      ?.trim()
                      .isEmpty ==
                  true
              ? null
              : (json['latestStateRevalidationReceiptRef'] as String?),
      basisRefreshLineageRef:
          (json['basisRefreshLineageRef'] as String?)?.trim().isEmpty == true
              ? null
              : (json['basisRefreshLineageRef'] as String?),
    );
  }
}

class ReplaySimulationLabRerunRequest {
  const ReplaySimulationLabRerunRequest({
    required this.requestId,
    required this.environmentId,
    required this.cityCode,
    required this.replayYear,
    required this.requestedAt,
    required this.requestStatus,
    required this.requestRoot,
    required this.requestJsonPath,
    required this.readmePath,
    required this.requestNotes,
    required this.sidecarRefs,
    this.cityPackStructuralRef,
    this.variantId,
    this.variantLabel,
    this.startedAt,
    this.completedAt,
    this.latestJobId,
    this.latestJobJsonPath,
    this.latestJobStatus,
    this.latestJobStartedAt,
    this.latestJobCompletedAt,
    this.latestJobSnapshotJsonPath,
    this.lineageOutcomeJsonPath,
    this.lineageDisposition,
    this.lineageRecordedAt,
    this.targetActionSuggested,
    this.targetActionSuggestedReason,
    this.targetActionSelected,
    this.targetActionAcceptedSuggestion,
    this.targetActionUpdatedAt,
  });

  final String requestId;
  final String environmentId;
  final String cityCode;
  final int replayYear;
  final DateTime requestedAt;
  final String requestStatus;
  final String requestRoot;
  final String requestJsonPath;
  final String readmePath;
  final List<String> requestNotes;
  final List<String> sidecarRefs;
  final String? cityPackStructuralRef;
  final String? variantId;
  final String? variantLabel;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? latestJobId;
  final String? latestJobJsonPath;
  final String? latestJobStatus;
  final DateTime? latestJobStartedAt;
  final DateTime? latestJobCompletedAt;
  final String? latestJobSnapshotJsonPath;
  final String? lineageOutcomeJsonPath;
  final String? lineageDisposition;
  final DateTime? lineageRecordedAt;
  final String? targetActionSuggested;
  final String? targetActionSuggestedReason;
  final String? targetActionSelected;
  final bool? targetActionAcceptedSuggestion;
  final DateTime? targetActionUpdatedAt;

  bool get targetsBaseRun => variantId == null || variantId!.trim().isEmpty;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'requestId': requestId,
      'environmentId': environmentId,
      'cityCode': cityCode,
      'replayYear': replayYear,
      'requestedAt': requestedAt.toUtc().toIso8601String(),
      'requestStatus': requestStatus,
      'requestRoot': requestRoot,
      'requestJsonPath': requestJsonPath,
      'readmePath': readmePath,
      'requestNotes': requestNotes,
      'sidecarRefs': sidecarRefs,
      'cityPackStructuralRef': cityPackStructuralRef,
      'variantId': variantId,
      'variantLabel': variantLabel,
      'startedAt': startedAt?.toUtc().toIso8601String(),
      'completedAt': completedAt?.toUtc().toIso8601String(),
      'latestJobId': latestJobId,
      'latestJobJsonPath': latestJobJsonPath,
      'latestJobStatus': latestJobStatus,
      'latestJobStartedAt': latestJobStartedAt?.toUtc().toIso8601String(),
      'latestJobCompletedAt': latestJobCompletedAt?.toUtc().toIso8601String(),
      'latestJobSnapshotJsonPath': latestJobSnapshotJsonPath,
      'lineageOutcomeJsonPath': lineageOutcomeJsonPath,
      'lineageDisposition': lineageDisposition,
      'lineageRecordedAt': lineageRecordedAt?.toUtc().toIso8601String(),
      'targetActionSuggested': targetActionSuggested,
      'targetActionSuggestedReason': targetActionSuggestedReason,
      'targetActionSelected': targetActionSelected,
      'targetActionAcceptedSuggestion': targetActionAcceptedSuggestion,
      'targetActionUpdatedAt': targetActionUpdatedAt?.toUtc().toIso8601String(),
    };
  }

  factory ReplaySimulationLabRerunRequest.fromJson(Map<String, dynamic> json) {
    return ReplaySimulationLabRerunRequest(
      requestId: (json['requestId'] ?? '').toString(),
      environmentId: (json['environmentId'] ?? '').toString(),
      cityCode: (json['cityCode'] ?? '').toString(),
      replayYear: (json['replayYear'] as num?)?.toInt() ?? 0,
      requestedAt: DateTime.tryParse((json['requestedAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      requestStatus:
          ReplaySimulationAdminService._normalizeLabRerunRequestStatus(
        (json['requestStatus'] ?? 'queued').toString(),
      ),
      requestRoot: (json['requestRoot'] ?? '').toString(),
      requestJsonPath: (json['requestJsonPath'] ?? '').toString(),
      readmePath: (json['readmePath'] ?? '').toString(),
      requestNotes: (json['requestNotes'] as List<dynamic>? ?? const [])
          .map((entry) => entry.toString())
          .toList(growable: false),
      sidecarRefs: (json['sidecarRefs'] as List<dynamic>? ?? const [])
          .map((entry) => entry.toString())
          .toList(growable: false),
      cityPackStructuralRef:
          (json['cityPackStructuralRef'] as String?)?.trim().isEmpty == true
              ? null
              : (json['cityPackStructuralRef'] as String?),
      variantId: (json['variantId'] as String?)?.trim().isEmpty == true
          ? null
          : (json['variantId'] as String?),
      variantLabel: (json['variantLabel'] as String?)?.trim().isEmpty == true
          ? null
          : (json['variantLabel'] as String?),
      startedAt: ((json['startedAt'] ?? '').toString().trim().isEmpty)
          ? null
          : DateTime.tryParse((json['startedAt'] ?? '').toString().trim()),
      completedAt: ((json['completedAt'] ?? '').toString().trim().isEmpty)
          ? null
          : DateTime.tryParse((json['completedAt'] ?? '').toString().trim()),
      latestJobId: (json['latestJobId'] as String?)?.trim().isEmpty == true
          ? null
          : (json['latestJobId'] as String?),
      latestJobJsonPath:
          (json['latestJobJsonPath'] as String?)?.trim().isEmpty == true
              ? null
              : (json['latestJobJsonPath'] as String?),
      latestJobStatus:
          ((json['latestJobStatus'] ?? '').toString().trim().isEmpty)
              ? null
              : ReplaySimulationAdminService._normalizeLabRerunJobStatus(
                  (json['latestJobStatus'] ?? '').toString(),
                ),
      latestJobStartedAt:
          ((json['latestJobStartedAt'] ?? '').toString().trim().isEmpty)
              ? null
              : DateTime.tryParse(
                  (json['latestJobStartedAt'] ?? '').toString().trim(),
                ),
      latestJobCompletedAt:
          ((json['latestJobCompletedAt'] ?? '').toString().trim().isEmpty)
              ? null
              : DateTime.tryParse(
                  (json['latestJobCompletedAt'] ?? '').toString().trim(),
                ),
      latestJobSnapshotJsonPath:
          (json['latestJobSnapshotJsonPath'] as String?)?.trim().isEmpty == true
              ? null
              : (json['latestJobSnapshotJsonPath'] as String?),
      lineageOutcomeJsonPath:
          (json['lineageOutcomeJsonPath'] as String?)?.trim().isEmpty == true
              ? null
              : (json['lineageOutcomeJsonPath'] as String?),
      lineageDisposition:
          (json['lineageDisposition'] as String?)?.trim().isEmpty == true
              ? null
              : (json['lineageDisposition'] as String?),
      lineageRecordedAt:
          ((json['lineageRecordedAt'] ?? '').toString().trim().isEmpty)
              ? null
              : DateTime.tryParse(
                  (json['lineageRecordedAt'] ?? '').toString().trim(),
                ),
      targetActionSuggested:
          (json['targetActionSuggested'] as String?)?.trim().isEmpty == true
              ? null
              : ReplaySimulationAdminService._normalizeLabTargetAction(
                  (json['targetActionSuggested'] ?? '').toString(),
                ),
      targetActionSuggestedReason:
          (json['targetActionSuggestedReason'] as String?)?.trim().isEmpty ==
                  true
              ? null
              : (json['targetActionSuggestedReason'] as String?),
      targetActionSelected:
          (json['targetActionSelected'] as String?)?.trim().isEmpty == true
              ? null
              : ReplaySimulationAdminService._normalizeLabTargetAction(
                  (json['targetActionSelected'] ?? '').toString(),
                ),
      targetActionAcceptedSuggestion:
          json['targetActionAcceptedSuggestion'] is bool
              ? json['targetActionAcceptedSuggestion'] as bool
              : null,
      targetActionUpdatedAt:
          ((json['targetActionUpdatedAt'] ?? '').toString().trim().isEmpty)
              ? null
              : DateTime.tryParse(
                  (json['targetActionUpdatedAt'] ?? '').toString().trim(),
                ),
    );
  }

  ReplaySimulationLabRerunRequest copyWith({
    String? requestStatus,
    DateTime? startedAt,
    DateTime? completedAt,
    String? latestJobId,
    String? latestJobJsonPath,
    String? latestJobStatus,
    DateTime? latestJobStartedAt,
    DateTime? latestJobCompletedAt,
    String? latestJobSnapshotJsonPath,
    String? targetActionSuggested,
    String? targetActionSuggestedReason,
    String? targetActionSelected,
    bool? targetActionAcceptedSuggestion,
    DateTime? targetActionUpdatedAt,
  }) {
    return ReplaySimulationLabRerunRequest(
      requestId: requestId,
      environmentId: environmentId,
      cityCode: cityCode,
      replayYear: replayYear,
      requestedAt: requestedAt,
      requestStatus: requestStatus ?? this.requestStatus,
      requestRoot: requestRoot,
      requestJsonPath: requestJsonPath,
      readmePath: readmePath,
      requestNotes: requestNotes,
      sidecarRefs: sidecarRefs,
      cityPackStructuralRef: cityPackStructuralRef,
      variantId: variantId,
      variantLabel: variantLabel,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      latestJobId: latestJobId ?? this.latestJobId,
      latestJobJsonPath: latestJobJsonPath ?? this.latestJobJsonPath,
      latestJobStatus: latestJobStatus ?? this.latestJobStatus,
      latestJobStartedAt: latestJobStartedAt ?? this.latestJobStartedAt,
      latestJobCompletedAt: latestJobCompletedAt ?? this.latestJobCompletedAt,
      latestJobSnapshotJsonPath:
          latestJobSnapshotJsonPath ?? this.latestJobSnapshotJsonPath,
      lineageOutcomeJsonPath: lineageOutcomeJsonPath,
      lineageDisposition: lineageDisposition,
      lineageRecordedAt: lineageRecordedAt,
      targetActionSuggested:
          targetActionSuggested ?? this.targetActionSuggested,
      targetActionSuggestedReason:
          targetActionSuggestedReason ?? this.targetActionSuggestedReason,
      targetActionSelected: targetActionSelected ?? this.targetActionSelected,
      targetActionAcceptedSuggestion:
          targetActionAcceptedSuggestion ?? this.targetActionAcceptedSuggestion,
      targetActionUpdatedAt:
          targetActionUpdatedAt ?? this.targetActionUpdatedAt,
    );
  }
}

class ReplaySimulationLabRerunJob {
  const ReplaySimulationLabRerunJob({
    required this.jobId,
    required this.requestId,
    required this.environmentId,
    required this.cityCode,
    required this.replayYear,
    required this.jobStatus,
    required this.jobRoot,
    required this.jobJsonPath,
    required this.readmePath,
    required this.startedAt,
    this.variantId,
    this.variantLabel,
    this.cityPackStructuralRef,
    this.snapshotJsonPath,
    this.learningBundleJsonPath,
    this.realityModelRequestJsonPath,
    this.completedAt,
    this.failureSummary,
    this.scenarioCount = 0,
    this.comparisonCount = 0,
    this.receiptCount = 0,
    this.contradictionCount = 0,
    this.overlayCount = 0,
    this.requestPreviewCount = 0,
    this.syntheticHumanKernelEntries =
        const <ReplaySimulationSyntheticHumanKernelEntry>[],
    this.localityHierarchyNodes =
        const <ReplaySimulationLocalityHierarchyNodeSummary>[],
    this.higherAgentHandoffItems =
        const <ReplaySimulationHigherAgentHandoffItem>[],
    this.realismProvenance = const ReplaySimulationRealismProvenanceSummary(),
  });

  final String jobId;
  final String requestId;
  final String environmentId;
  final String cityCode;
  final int replayYear;
  final String jobStatus;
  final String jobRoot;
  final String jobJsonPath;
  final String readmePath;
  final DateTime startedAt;
  final String? variantId;
  final String? variantLabel;
  final String? cityPackStructuralRef;
  final String? snapshotJsonPath;
  final String? learningBundleJsonPath;
  final String? realityModelRequestJsonPath;
  final DateTime? completedAt;
  final String? failureSummary;
  final int scenarioCount;
  final int comparisonCount;
  final int receiptCount;
  final int contradictionCount;
  final int overlayCount;
  final int requestPreviewCount;
  final List<ReplaySimulationSyntheticHumanKernelEntry>
      syntheticHumanKernelEntries;
  final List<ReplaySimulationLocalityHierarchyNodeSummary>
      localityHierarchyNodes;
  final List<ReplaySimulationHigherAgentHandoffItem> higherAgentHandoffItems;
  final ReplaySimulationRealismProvenanceSummary realismProvenance;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'jobId': jobId,
      'requestId': requestId,
      'environmentId': environmentId,
      'cityCode': cityCode,
      'replayYear': replayYear,
      'jobStatus': jobStatus,
      'jobRoot': jobRoot,
      'jobJsonPath': jobJsonPath,
      'readmePath': readmePath,
      'startedAt': startedAt.toUtc().toIso8601String(),
      'variantId': variantId,
      'variantLabel': variantLabel,
      'cityPackStructuralRef': cityPackStructuralRef,
      'snapshotJsonPath': snapshotJsonPath,
      'learningBundleJsonPath': learningBundleJsonPath,
      'realityModelRequestJsonPath': realityModelRequestJsonPath,
      'completedAt': completedAt?.toUtc().toIso8601String(),
      'failureSummary': failureSummary,
      'scenarioCount': scenarioCount,
      'comparisonCount': comparisonCount,
      'receiptCount': receiptCount,
      'contradictionCount': contradictionCount,
      'overlayCount': overlayCount,
      'requestPreviewCount': requestPreviewCount,
      'syntheticHumanKernelEntries':
          syntheticHumanKernelEntries.map((entry) => entry.toJson()).toList(),
      'localityHierarchyNodes':
          localityHierarchyNodes.map((entry) => entry.toJson()).toList(),
      'higherAgentHandoffItems':
          higherAgentHandoffItems.map((entry) => entry.toJson()).toList(),
      'realismProvenance': realismProvenance.toJson(),
    };
  }

  factory ReplaySimulationLabRerunJob.fromJson(Map<String, dynamic> json) {
    return ReplaySimulationLabRerunJob(
      jobId: (json['jobId'] ?? '').toString(),
      requestId: (json['requestId'] ?? '').toString(),
      environmentId: (json['environmentId'] ?? '').toString(),
      cityCode: (json['cityCode'] ?? '').toString(),
      replayYear: (json['replayYear'] as num?)?.toInt() ?? 0,
      jobStatus: ReplaySimulationAdminService._normalizeLabRerunJobStatus(
        (json['jobStatus'] ?? 'queued').toString(),
      ),
      jobRoot: (json['jobRoot'] ?? '').toString(),
      jobJsonPath: (json['jobJsonPath'] ?? '').toString(),
      readmePath: (json['readmePath'] ?? '').toString(),
      startedAt: DateTime.tryParse((json['startedAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      variantId: (json['variantId'] as String?)?.trim().isEmpty == true
          ? null
          : (json['variantId'] as String?),
      variantLabel: (json['variantLabel'] as String?)?.trim().isEmpty == true
          ? null
          : (json['variantLabel'] as String?),
      cityPackStructuralRef:
          (json['cityPackStructuralRef'] as String?)?.trim().isEmpty == true
              ? null
              : (json['cityPackStructuralRef'] as String?),
      snapshotJsonPath:
          (json['snapshotJsonPath'] as String?)?.trim().isEmpty == true
              ? null
              : (json['snapshotJsonPath'] as String?),
      learningBundleJsonPath:
          (json['learningBundleJsonPath'] as String?)?.trim().isEmpty == true
              ? null
              : (json['learningBundleJsonPath'] as String?),
      realityModelRequestJsonPath:
          (json['realityModelRequestJsonPath'] as String?)?.trim().isEmpty ==
                  true
              ? null
              : (json['realityModelRequestJsonPath'] as String?),
      completedAt: ((json['completedAt'] ?? '').toString().trim().isEmpty)
          ? null
          : DateTime.tryParse((json['completedAt'] ?? '').toString().trim()),
      failureSummary:
          (json['failureSummary'] as String?)?.trim().isEmpty == true
              ? null
              : (json['failureSummary'] as String?),
      scenarioCount: (json['scenarioCount'] as num?)?.toInt() ?? 0,
      comparisonCount: (json['comparisonCount'] as num?)?.toInt() ?? 0,
      receiptCount: (json['receiptCount'] as num?)?.toInt() ?? 0,
      contradictionCount: (json['contradictionCount'] as num?)?.toInt() ?? 0,
      overlayCount: (json['overlayCount'] as num?)?.toInt() ?? 0,
      requestPreviewCount: (json['requestPreviewCount'] as num?)?.toInt() ?? 0,
      syntheticHumanKernelEntries:
          (json['syntheticHumanKernelEntries'] as List<dynamic>? ?? const [])
              .whereType<Map<dynamic, dynamic>>()
              .map(
                (entry) => ReplaySimulationSyntheticHumanKernelEntry.fromJson(
                  Map<String, dynamic>.from(entry),
                ),
              )
              .toList(growable: false),
      localityHierarchyNodes:
          (json['localityHierarchyNodes'] as List<dynamic>? ?? const [])
              .whereType<Map<dynamic, dynamic>>()
              .map(
                (entry) =>
                    ReplaySimulationLocalityHierarchyNodeSummary.fromJson(
                  Map<String, dynamic>.from(entry),
                ),
              )
              .toList(growable: false),
      higherAgentHandoffItems:
          (json['higherAgentHandoffItems'] as List<dynamic>? ?? const [])
              .whereType<Map<dynamic, dynamic>>()
              .map(
                (entry) => ReplaySimulationHigherAgentHandoffItem.fromJson(
                  Map<String, dynamic>.from(entry),
                ),
              )
              .toList(growable: false),
      realismProvenance: json['realismProvenance'] is Map<dynamic, dynamic>
          ? ReplaySimulationRealismProvenanceSummary.fromJson(
              Map<String, dynamic>.from(
                json['realismProvenance'] as Map<dynamic, dynamic>,
              ),
            )
          : const ReplaySimulationRealismProvenanceSummary(),
    );
  }

  ReplaySimulationLabRerunJob copyWith({
    String? jobStatus,
    String? snapshotJsonPath,
    String? learningBundleJsonPath,
    String? realityModelRequestJsonPath,
    DateTime? completedAt,
    String? failureSummary,
    int? scenarioCount,
    int? comparisonCount,
    int? receiptCount,
    int? contradictionCount,
    int? overlayCount,
    int? requestPreviewCount,
    List<ReplaySimulationSyntheticHumanKernelEntry>?
        syntheticHumanKernelEntries,
    List<ReplaySimulationLocalityHierarchyNodeSummary>? localityHierarchyNodes,
    List<ReplaySimulationHigherAgentHandoffItem>? higherAgentHandoffItems,
    ReplaySimulationRealismProvenanceSummary? realismProvenance,
  }) {
    return ReplaySimulationLabRerunJob(
      jobId: jobId,
      requestId: requestId,
      environmentId: environmentId,
      cityCode: cityCode,
      replayYear: replayYear,
      jobStatus: jobStatus ?? this.jobStatus,
      jobRoot: jobRoot,
      jobJsonPath: jobJsonPath,
      readmePath: readmePath,
      startedAt: startedAt,
      variantId: variantId,
      variantLabel: variantLabel,
      cityPackStructuralRef: cityPackStructuralRef,
      snapshotJsonPath: snapshotJsonPath ?? this.snapshotJsonPath,
      learningBundleJsonPath:
          learningBundleJsonPath ?? this.learningBundleJsonPath,
      realityModelRequestJsonPath:
          realityModelRequestJsonPath ?? this.realityModelRequestJsonPath,
      completedAt: completedAt ?? this.completedAt,
      failureSummary: failureSummary ?? this.failureSummary,
      scenarioCount: scenarioCount ?? this.scenarioCount,
      comparisonCount: comparisonCount ?? this.comparisonCount,
      receiptCount: receiptCount ?? this.receiptCount,
      contradictionCount: contradictionCount ?? this.contradictionCount,
      overlayCount: overlayCount ?? this.overlayCount,
      requestPreviewCount: requestPreviewCount ?? this.requestPreviewCount,
      syntheticHumanKernelEntries:
          syntheticHumanKernelEntries ?? this.syntheticHumanKernelEntries,
      localityHierarchyNodes:
          localityHierarchyNodes ?? this.localityHierarchyNodes,
      higherAgentHandoffItems:
          higherAgentHandoffItems ?? this.higherAgentHandoffItems,
      realismProvenance: realismProvenance ?? this.realismProvenance,
    );
  }
}

class ReplaySimulationKernelState {
  const ReplaySimulationKernelState({
    required this.kernelId,
    required this.status,
    required this.reason,
  });

  final String kernelId;
  final String status;
  final String reason;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'kernelId': kernelId,
      'status': status,
      'reason': reason,
    };
  }
}

class ReplaySimulationAdminFoundationSummary {
  const ReplaySimulationAdminFoundationSummary({
    this.simulationMode = 'unknown',
    this.intakeFlowRefs = const <String>[],
    this.sidecarRefs = const <String>[],
    this.trainingArtifactFamilies = const <String>[],
    this.kernelStates = const <ReplaySimulationKernelState>[],
    this.notes = const <String>[],
    this.metadata = const <String, dynamic>{},
  });

  final String simulationMode;
  final List<String> intakeFlowRefs;
  final List<String> sidecarRefs;
  final List<String> trainingArtifactFamilies;
  final List<ReplaySimulationKernelState> kernelStates;
  final List<String> notes;
  final Map<String, dynamic> metadata;

  int get activeKernelCount =>
      kernelStates.where((entry) => entry.status == 'active').length;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'simulationMode': simulationMode,
      'intakeFlowRefs': intakeFlowRefs,
      'sidecarRefs': sidecarRefs,
      'trainingArtifactFamilies': trainingArtifactFamilies,
      'kernelStates': kernelStates.map((entry) => entry.toJson()).toList(),
      'notes': notes,
      'metadata': metadata,
    };
  }
}

class ReplaySimulationRealityModelRequestPreview {
  const ReplaySimulationRealityModelRequestPreview({
    required this.request,
    required this.rationale,
  });

  final RealityModelEvaluationRequest request;
  final String rationale;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'request': request.toJson(),
      'rationale': rationale,
    };
  }
}

class ReplaySimulationLearningReadiness {
  const ReplaySimulationLearningReadiness({
    this.trainingGrade = 'insufficient',
    this.shareWithRealityModelAllowed = false,
    this.reasons = const <String>[],
    this.suggestedTrainingUse = 'simulation_debug_only',
    this.requestPreviews = const <ReplaySimulationRealityModelRequestPreview>[],
    this.metadata = const <String, dynamic>{},
  });

  final String trainingGrade;
  final bool shareWithRealityModelAllowed;
  final List<String> reasons;
  final String suggestedTrainingUse;
  final List<ReplaySimulationRealityModelRequestPreview> requestPreviews;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'trainingGrade': trainingGrade,
      'shareWithRealityModelAllowed': shareWithRealityModelAllowed,
      'reasons': reasons,
      'suggestedTrainingUse': suggestedTrainingUse,
      'requestPreviews':
          requestPreviews.map((entry) => entry.toJson()).toList(),
      'metadata': metadata,
    };
  }
}

class ReplaySimulationSyntheticHumanKernelEntry {
  const ReplaySimulationSyntheticHumanKernelEntry({
    required this.actorId,
    required this.displayName,
    required this.localityAnchor,
    this.attachedKernelIds = const <String>[],
    this.readyKernelIds = const <String>[],
    this.missingKernelIds = const <String>[],
    this.notReadyKernelIds = const <String>[],
    this.activationCountByKernel = const <String, int>{},
    this.higherAgentGuidanceCount = 0,
    this.summary = '',
    this.traceSummary = const <String>[],
    this.metadata = const <String, dynamic>{},
  });

  final String actorId;
  final String displayName;
  final String localityAnchor;
  final List<String> attachedKernelIds;
  final List<String> readyKernelIds;
  final List<String> missingKernelIds;
  final List<String> notReadyKernelIds;
  final Map<String, int> activationCountByKernel;
  final int higherAgentGuidanceCount;
  final String summary;
  final List<String> traceSummary;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'actorId': actorId,
      'displayName': displayName,
      'localityAnchor': localityAnchor,
      'attachedKernelIds': attachedKernelIds,
      'readyKernelIds': readyKernelIds,
      'missingKernelIds': missingKernelIds,
      'notReadyKernelIds': notReadyKernelIds,
      'activationCountByKernel': activationCountByKernel,
      'higherAgentGuidanceCount': higherAgentGuidanceCount,
      'summary': summary,
      'traceSummary': traceSummary,
      'metadata': metadata,
    };
  }

  factory ReplaySimulationSyntheticHumanKernelEntry.fromJson(
    Map<String, dynamic> json,
  ) {
    return ReplaySimulationSyntheticHumanKernelEntry(
      actorId: (json['actorId'] ?? '').toString(),
      displayName: (json['displayName'] ?? '').toString(),
      localityAnchor: (json['localityAnchor'] ?? '').toString(),
      attachedKernelIds:
          (json['attachedKernelIds'] as List<dynamic>? ?? const [])
              .map((entry) => entry.toString())
              .toList(growable: false),
      readyKernelIds: (json['readyKernelIds'] as List<dynamic>? ?? const [])
          .map((entry) => entry.toString())
          .toList(growable: false),
      missingKernelIds: (json['missingKernelIds'] as List<dynamic>? ?? const [])
          .map((entry) => entry.toString())
          .toList(growable: false),
      notReadyKernelIds:
          (json['notReadyKernelIds'] as List<dynamic>? ?? const [])
              .map((entry) => entry.toString())
              .toList(growable: false),
      activationCountByKernel:
          (json['activationCountByKernel'] as Map<dynamic, dynamic>? ??
                  const <dynamic, dynamic>{})
              .map(
        (key, value) => MapEntry(key.toString(), (value as num?)?.toInt() ?? 0),
      ),
      higherAgentGuidanceCount:
          (json['higherAgentGuidanceCount'] as num?)?.toInt() ?? 0,
      summary: (json['summary'] ?? '').toString(),
      traceSummary: (json['traceSummary'] as List<dynamic>? ?? const [])
          .map((entry) => entry.toString())
          .toList(growable: false),
      metadata: (json['metadata'] as Map<dynamic, dynamic>? ??
              const <dynamic, dynamic>{})
          .map((key, value) => MapEntry(key.toString(), value)),
    );
  }
}

class ReplaySimulationSyntheticHumanKernelExplorer {
  const ReplaySimulationSyntheticHumanKernelExplorer({
    this.requiredKernelIds = const <String>[],
    this.modeledActorCount = 0,
    this.actorsWithFullBundle = 0,
    this.summary = '',
    this.entries = const <ReplaySimulationSyntheticHumanKernelEntry>[],
  });

  final List<String> requiredKernelIds;
  final int modeledActorCount;
  final int actorsWithFullBundle;
  final String summary;
  final List<ReplaySimulationSyntheticHumanKernelEntry> entries;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'requiredKernelIds': requiredKernelIds,
      'modeledActorCount': modeledActorCount,
      'actorsWithFullBundle': actorsWithFullBundle,
      'summary': summary,
      'entries': entries.map((entry) => entry.toJson()).toList(),
    };
  }
}

class ReplaySimulationLocalityHierarchyNodeSummary {
  const ReplaySimulationLocalityHierarchyNodeSummary({
    required this.localityCode,
    required this.displayName,
    required this.pressureBand,
    required this.attentionBand,
    required this.primarySignals,
    required this.branchSensitivity,
    required this.contradictionCount,
    required this.effectiveness,
    required this.risk,
    required this.summary,
    this.traceSummary = const <String>[],
  });

  final String localityCode;
  final String displayName;
  final String pressureBand;
  final String attentionBand;
  final List<String> primarySignals;
  final double branchSensitivity;
  final int contradictionCount;
  final String effectiveness;
  final String risk;
  final String summary;
  final List<String> traceSummary;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'localityCode': localityCode,
      'displayName': displayName,
      'pressureBand': pressureBand,
      'attentionBand': attentionBand,
      'primarySignals': primarySignals,
      'branchSensitivity': branchSensitivity,
      'contradictionCount': contradictionCount,
      'effectiveness': effectiveness,
      'risk': risk,
      'summary': summary,
      'traceSummary': traceSummary,
    };
  }

  factory ReplaySimulationLocalityHierarchyNodeSummary.fromJson(
    Map<String, dynamic> json,
  ) {
    return ReplaySimulationLocalityHierarchyNodeSummary(
      localityCode: (json['localityCode'] ?? '').toString(),
      displayName: (json['displayName'] ?? '').toString(),
      pressureBand: (json['pressureBand'] ?? '').toString(),
      attentionBand: (json['attentionBand'] ?? '').toString(),
      primarySignals: (json['primarySignals'] as List<dynamic>? ?? const [])
          .map((entry) => entry.toString())
          .toList(growable: false),
      branchSensitivity: (json['branchSensitivity'] as num?)?.toDouble() ?? 0,
      contradictionCount: (json['contradictionCount'] as num?)?.toInt() ?? 0,
      effectiveness: (json['effectiveness'] ?? '').toString(),
      risk: (json['risk'] ?? '').toString(),
      summary: (json['summary'] ?? '').toString(),
      traceSummary: (json['traceSummary'] as List<dynamic>? ?? const [])
          .map((entry) => entry.toString())
          .toList(growable: false),
    );
  }
}

class ReplaySimulationLocalityHierarchyHealth {
  const ReplaySimulationLocalityHierarchyHealth({
    this.summary = '',
    this.strongestLocalityLabel,
    this.stressedLocalityLabel,
    this.stableLocalityCount = 0,
    this.escalatingLocalityCount = 0,
    this.nodes = const <ReplaySimulationLocalityHierarchyNodeSummary>[],
  });

  final String summary;
  final String? strongestLocalityLabel;
  final String? stressedLocalityLabel;
  final int stableLocalityCount;
  final int escalatingLocalityCount;
  final List<ReplaySimulationLocalityHierarchyNodeSummary> nodes;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'summary': summary,
      'strongestLocalityLabel': strongestLocalityLabel,
      'stressedLocalityLabel': stressedLocalityLabel,
      'stableLocalityCount': stableLocalityCount,
      'escalatingLocalityCount': escalatingLocalityCount,
      'nodes': nodes.map((entry) => entry.toJson()).toList(),
    };
  }
}

class ReplaySimulationHigherAgentHandoffItem {
  const ReplaySimulationHigherAgentHandoffItem({
    required this.scope,
    required this.targetLabel,
    required this.status,
    required this.summary,
    this.guidance = const <String>[],
    this.traceSummary = const <String>[],
    this.metadata = const <String, dynamic>{},
  });

  final String scope;
  final String targetLabel;
  final String status;
  final String summary;
  final List<String> guidance;
  final List<String> traceSummary;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'scope': scope,
      'targetLabel': targetLabel,
      'status': status,
      'summary': summary,
      'guidance': guidance,
      'traceSummary': traceSummary,
      'metadata': metadata,
    };
  }

  factory ReplaySimulationHigherAgentHandoffItem.fromJson(
    Map<String, dynamic> json,
  ) {
    return ReplaySimulationHigherAgentHandoffItem(
      scope: (json['scope'] ?? '').toString(),
      targetLabel: (json['targetLabel'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      summary: (json['summary'] ?? '').toString(),
      guidance: (json['guidance'] as List<dynamic>? ?? const [])
          .map((entry) => entry.toString())
          .toList(growable: false),
      traceSummary: (json['traceSummary'] as List<dynamic>? ?? const [])
          .map((entry) => entry.toString())
          .toList(growable: false),
      metadata: (json['metadata'] as Map<dynamic, dynamic>? ??
              const <dynamic, dynamic>{})
          .map((key, value) => MapEntry(key.toString(), value)),
    );
  }
}

class ReplaySimulationHigherAgentHandoffView {
  const ReplaySimulationHigherAgentHandoffView({
    this.summary = '',
    this.items = const <ReplaySimulationHigherAgentHandoffItem>[],
  });

  final String summary;
  final List<ReplaySimulationHigherAgentHandoffItem> items;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'summary': summary,
      'items': items.map((entry) => entry.toJson()).toList(),
    };
  }
}

class ReplaySimulationRealismProvenanceSummary {
  const ReplaySimulationRealismProvenanceSummary({
    this.simulationMode = 'unknown',
    this.cityPackStructuralRef,
    this.populationModelKind,
    this.modeledUserLayerKind,
    this.campaignDefaultsRef,
    this.localityExpectationProfileRef,
    this.worldHealthProfileRef,
    this.intakeFlowRefs = const <String>[],
    this.sidecarRefs = const <String>[],
    this.trainingArtifactFamilies = const <String>[],
    this.metadata = const <String, dynamic>{},
  });

  final String simulationMode;
  final String? cityPackStructuralRef;
  final String? populationModelKind;
  final String? modeledUserLayerKind;
  final String? campaignDefaultsRef;
  final String? localityExpectationProfileRef;
  final String? worldHealthProfileRef;
  final List<String> intakeFlowRefs;
  final List<String> sidecarRefs;
  final List<String> trainingArtifactFamilies;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'simulationMode': simulationMode,
      'cityPackStructuralRef': cityPackStructuralRef,
      'populationModelKind': populationModelKind,
      'modeledUserLayerKind': modeledUserLayerKind,
      'campaignDefaultsRef': campaignDefaultsRef,
      'localityExpectationProfileRef': localityExpectationProfileRef,
      'worldHealthProfileRef': worldHealthProfileRef,
      'intakeFlowRefs': intakeFlowRefs,
      'sidecarRefs': sidecarRefs,
      'trainingArtifactFamilies': trainingArtifactFamilies,
      'metadata': metadata,
    };
  }

  factory ReplaySimulationRealismProvenanceSummary.fromJson(
    Map<String, dynamic> json,
  ) {
    return ReplaySimulationRealismProvenanceSummary(
      simulationMode: (json['simulationMode'] ?? 'unknown').toString(),
      cityPackStructuralRef:
          (json['cityPackStructuralRef'] as String?)?.trim().isEmpty == true
              ? null
              : (json['cityPackStructuralRef'] as String?),
      populationModelKind:
          (json['populationModelKind'] as String?)?.trim().isEmpty == true
              ? null
              : (json['populationModelKind'] as String?),
      modeledUserLayerKind:
          (json['modeledUserLayerKind'] as String?)?.trim().isEmpty == true
              ? null
              : (json['modeledUserLayerKind'] as String?),
      campaignDefaultsRef:
          (json['campaignDefaultsRef'] as String?)?.trim().isEmpty == true
              ? null
              : (json['campaignDefaultsRef'] as String?),
      localityExpectationProfileRef:
          (json['localityExpectationProfileRef'] as String?)?.trim().isEmpty ==
                  true
              ? null
              : (json['localityExpectationProfileRef'] as String?),
      worldHealthProfileRef:
          (json['worldHealthProfileRef'] as String?)?.trim().isEmpty == true
              ? null
              : (json['worldHealthProfileRef'] as String?),
      intakeFlowRefs: (json['intakeFlowRefs'] as List<dynamic>? ?? const [])
          .map((entry) => entry.toString())
          .toList(growable: false),
      sidecarRefs: (json['sidecarRefs'] as List<dynamic>? ?? const [])
          .map((entry) => entry.toString())
          .toList(growable: false),
      trainingArtifactFamilies:
          (json['trainingArtifactFamilies'] as List<dynamic>? ?? const [])
              .map((entry) => entry.toString())
              .toList(growable: false),
      metadata: (json['metadata'] as Map<dynamic, dynamic>? ??
              const <dynamic, dynamic>{})
          .map((key, value) => MapEntry(key.toString(), value)),
    );
  }
}

class ReplaySimulationWeakSpotSummary {
  const ReplaySimulationWeakSpotSummary({
    required this.title,
    required this.severity,
    required this.summary,
    required this.recommendedAction,
    this.metadata = const <String, dynamic>{},
  });

  final String title;
  final String severity;
  final String summary;
  final String recommendedAction;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'title': title,
      'severity': severity,
      'summary': summary,
      'recommendedAction': recommendedAction,
      'metadata': metadata,
    };
  }
}

class ReplaySimulationLearningBundleExport {
  const ReplaySimulationLearningBundleExport({
    required this.environmentId,
    required this.bundleRoot,
    required this.snapshotJsonPath,
    required this.learningBundleJsonPath,
    required this.realityModelRequestJsonPath,
    required this.readmePath,
    required this.exportedAt,
    required this.shareWithRealityModelAllowed,
  });

  final String environmentId;
  final String bundleRoot;
  final String snapshotJsonPath;
  final String learningBundleJsonPath;
  final String realityModelRequestJsonPath;
  final String readmePath;
  final DateTime exportedAt;
  final bool shareWithRealityModelAllowed;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'environmentId': environmentId,
      'bundleRoot': bundleRoot,
      'snapshotJsonPath': snapshotJsonPath,
      'learningBundleJsonPath': learningBundleJsonPath,
      'realityModelRequestJsonPath': realityModelRequestJsonPath,
      'readmePath': readmePath,
      'exportedAt': exportedAt.toUtc().toIso8601String(),
      'shareWithRealityModelAllowed': shareWithRealityModelAllowed,
    };
  }
}

class ReplaySimulationRealityModelShareOutcome {
  const ReplaySimulationRealityModelShareOutcome({
    required this.request,
    required this.rationale,
    required this.evaluation,
    required this.trace,
    required this.explanation,
  });

  final RealityModelEvaluationRequest request;
  final String rationale;
  final RealityModelEvaluation evaluation;
  final RealityDecisionTrace trace;
  final RealityModelExplanation explanation;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'request': request.toJson(),
      'rationale': rationale,
      'evaluation': evaluation.toJson(),
      'trace': trace.toJson(),
      'explanation': explanation.toJson(),
    };
  }
}

class ReplaySimulationRealityModelShareReport {
  const ReplaySimulationRealityModelShareReport({
    required this.environmentId,
    required this.bundleRoot,
    required this.reviewJsonPath,
    required this.sharedAt,
    required this.contractId,
    required this.contractVersion,
    required this.requestCount,
    required this.recommendationCount,
    required this.outcomes,
  });

  final String environmentId;
  final String bundleRoot;
  final String reviewJsonPath;
  final DateTime sharedAt;
  final String contractId;
  final String contractVersion;
  final int requestCount;
  final int recommendationCount;
  final List<ReplaySimulationRealityModelShareOutcome> outcomes;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'environmentId': environmentId,
      'bundleRoot': bundleRoot,
      'reviewJsonPath': reviewJsonPath,
      'sharedAt': sharedAt.toUtc().toIso8601String(),
      'contractId': contractId,
      'contractVersion': contractVersion,
      'requestCount': requestCount,
      'recommendationCount': recommendationCount,
      'outcomes': outcomes.map((entry) => entry.toJson()).toList(),
    };
  }
}

class ReplaySimulationTrainingCandidateExport {
  const ReplaySimulationTrainingCandidateExport({
    required this.environmentId,
    required this.bundleRoot,
    required this.trainingManifestJsonPath,
    required this.readmePath,
    required this.stagedAt,
    required this.shareReviewJsonPath,
    required this.status,
  });

  final String environmentId;
  final String bundleRoot;
  final String trainingManifestJsonPath;
  final String readmePath;
  final DateTime stagedAt;
  final String shareReviewJsonPath;
  final String status;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'environmentId': environmentId,
      'bundleRoot': bundleRoot,
      'trainingManifestJsonPath': trainingManifestJsonPath,
      'readmePath': readmePath,
      'stagedAt': stagedAt.toUtc().toIso8601String(),
      'shareReviewJsonPath': shareReviewJsonPath,
      'status': status,
    };
  }
}

class ReplaySimulationTrainingIntakeQueueExport {
  const ReplaySimulationTrainingIntakeQueueExport({
    required this.environmentId,
    required this.bundleRoot,
    required this.queueJsonPath,
    required this.readmePath,
    required this.trainingManifestJsonPath,
    required this.shareReviewJsonPath,
    required this.queuedAt,
    required this.status,
    this.sourceId,
    this.jobId,
    this.reviewItemId,
  });

  final String environmentId;
  final String bundleRoot;
  final String queueJsonPath;
  final String readmePath;
  final String trainingManifestJsonPath;
  final String shareReviewJsonPath;
  final DateTime queuedAt;
  final String status;
  final String? sourceId;
  final String? jobId;
  final String? reviewItemId;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'environmentId': environmentId,
      'bundleRoot': bundleRoot,
      'queueJsonPath': queueJsonPath,
      'readmePath': readmePath,
      'trainingManifestJsonPath': trainingManifestJsonPath,
      'shareReviewJsonPath': shareReviewJsonPath,
      'queuedAt': queuedAt.toUtc().toIso8601String(),
      'status': status,
      'sourceId': sourceId,
      'jobId': jobId,
      'reviewItemId': reviewItemId,
    };
  }
}

class ReplaySimulationFamilyRestageIntakeQueueExport {
  const ReplaySimulationFamilyRestageIntakeQueueExport({
    required this.environmentId,
    required this.evidenceFamily,
    required this.queueJsonPath,
    required this.readmePath,
    required this.queuedAt,
    required this.status,
    this.sourceId,
    this.jobId,
    this.reviewItemId,
  });

  final String environmentId;
  final String evidenceFamily;
  final String queueJsonPath;
  final String readmePath;
  final DateTime queuedAt;
  final String status;
  final String? sourceId;
  final String? jobId;
  final String? reviewItemId;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'environmentId': environmentId,
      'evidenceFamily': evidenceFamily,
      'queueJsonPath': queueJsonPath,
      'readmePath': readmePath,
      'queuedAt': queuedAt.toUtc().toIso8601String(),
      'status': status,
      'sourceId': sourceId,
      'jobId': jobId,
      'reviewItemId': reviewItemId,
    };
  }
}

class ReplaySimulationFamilyRestageFollowUpQueueExport {
  const ReplaySimulationFamilyRestageFollowUpQueueExport({
    required this.environmentId,
    required this.evidenceFamily,
    required this.queueJsonPath,
    required this.readmePath,
    required this.queuedAt,
    required this.status,
    this.sourceId,
    this.jobId,
    this.reviewItemId,
  });

  final String environmentId;
  final String evidenceFamily;
  final String queueJsonPath;
  final String readmePath;
  final DateTime queuedAt;
  final String status;
  final String? sourceId;
  final String? jobId;
  final String? reviewItemId;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'environmentId': environmentId,
      'evidenceFamily': evidenceFamily,
      'queueJsonPath': queueJsonPath,
      'readmePath': readmePath,
      'queuedAt': queuedAt.toUtc().toIso8601String(),
      'status': status,
      'sourceId': sourceId,
      'jobId': jobId,
      'reviewItemId': reviewItemId,
    };
  }
}

class ReplaySimulationFamilyRestageResolutionQueueExport {
  const ReplaySimulationFamilyRestageResolutionQueueExport({
    required this.environmentId,
    required this.evidenceFamily,
    required this.queueJsonPath,
    required this.readmePath,
    required this.queuedAt,
    required this.status,
    this.sourceId,
    this.jobId,
    this.reviewItemId,
  });

  final String environmentId;
  final String evidenceFamily;
  final String queueJsonPath;
  final String readmePath;
  final DateTime queuedAt;
  final String status;
  final String? sourceId;
  final String? jobId;
  final String? reviewItemId;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'environmentId': environmentId,
      'evidenceFamily': evidenceFamily,
      'queueJsonPath': queueJsonPath,
      'readmePath': readmePath,
      'queuedAt': queuedAt.toUtc().toIso8601String(),
      'status': status,
      'sourceId': sourceId,
      'jobId': jobId,
      'reviewItemId': reviewItemId,
    };
  }
}

class ReplaySimulationFamilyRestageExecutionQueueExport {
  const ReplaySimulationFamilyRestageExecutionQueueExport({
    required this.environmentId,
    required this.evidenceFamily,
    required this.queueJsonPath,
    required this.readmePath,
    required this.queuedAt,
    required this.status,
    this.sourceId,
    this.jobId,
    this.reviewItemId,
  });

  final String environmentId;
  final String evidenceFamily;
  final String queueJsonPath;
  final String readmePath;
  final DateTime queuedAt;
  final String status;
  final String? sourceId;
  final String? jobId;
  final String? reviewItemId;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'environmentId': environmentId,
      'evidenceFamily': evidenceFamily,
      'queueJsonPath': queueJsonPath,
      'readmePath': readmePath,
      'queuedAt': queuedAt.toUtc().toIso8601String(),
      'status': status,
      'sourceId': sourceId,
      'jobId': jobId,
      'reviewItemId': reviewItemId,
    };
  }
}

class ReplaySimulationFamilyRestageApplicationQueueExport {
  const ReplaySimulationFamilyRestageApplicationQueueExport({
    required this.environmentId,
    required this.evidenceFamily,
    required this.queueJsonPath,
    required this.readmePath,
    required this.queuedAt,
    required this.status,
    this.sourceId,
    this.jobId,
    this.reviewItemId,
  });

  final String environmentId;
  final String evidenceFamily;
  final String queueJsonPath;
  final String readmePath;
  final DateTime queuedAt;
  final String status;
  final String? sourceId;
  final String? jobId;
  final String? reviewItemId;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'environmentId': environmentId,
      'evidenceFamily': evidenceFamily,
      'queueJsonPath': queueJsonPath,
      'readmePath': readmePath,
      'queuedAt': queuedAt.toUtc().toIso8601String(),
      'status': status,
      'sourceId': sourceId,
      'jobId': jobId,
      'reviewItemId': reviewItemId,
    };
  }
}

class ReplaySimulationFamilyRestageApplyQueueExport {
  const ReplaySimulationFamilyRestageApplyQueueExport({
    required this.environmentId,
    required this.evidenceFamily,
    required this.queueJsonPath,
    required this.readmePath,
    required this.queuedAt,
    required this.status,
    this.sourceId,
    this.jobId,
    this.reviewItemId,
  });

  final String environmentId;
  final String evidenceFamily;
  final String queueJsonPath;
  final String readmePath;
  final DateTime queuedAt;
  final String status;
  final String? sourceId;
  final String? jobId;
  final String? reviewItemId;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'environmentId': environmentId,
      'evidenceFamily': evidenceFamily,
      'queueJsonPath': queueJsonPath,
      'readmePath': readmePath,
      'queuedAt': queuedAt.toUtc().toIso8601String(),
      'status': status,
      'sourceId': sourceId,
      'jobId': jobId,
      'reviewItemId': reviewItemId,
    };
  }
}

class ReplaySimulationFamilyRestageServedBasisUpdateQueueExport {
  const ReplaySimulationFamilyRestageServedBasisUpdateQueueExport({
    required this.environmentId,
    required this.evidenceFamily,
    required this.queueJsonPath,
    required this.readmePath,
    required this.queuedAt,
    required this.status,
    this.sourceId,
    this.jobId,
    this.reviewItemId,
  });

  final String environmentId;
  final String evidenceFamily;
  final String queueJsonPath;
  final String readmePath;
  final DateTime queuedAt;
  final String status;
  final String? sourceId;
  final String? jobId;
  final String? reviewItemId;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'environmentId': environmentId,
      'evidenceFamily': evidenceFamily,
      'queueJsonPath': queueJsonPath,
      'readmePath': readmePath,
      'queuedAt': queuedAt.toUtc().toIso8601String(),
      'status': status,
      'sourceId': sourceId,
      'jobId': jobId,
      'reviewItemId': reviewItemId,
    };
  }
}

enum ReplaySimulationLabDisposition {
  draft,
  accepted,
  denied,
}

extension ReplaySimulationLabDispositionWire on ReplaySimulationLabDisposition {
  String toWireValue() {
    switch (this) {
      case ReplaySimulationLabDisposition.draft:
        return 'draft';
      case ReplaySimulationLabDisposition.accepted:
        return 'accepted';
      case ReplaySimulationLabDisposition.denied:
        return 'denied';
    }
  }

  String get displayLabel {
    switch (this) {
      case ReplaySimulationLabDisposition.draft:
        return 'Draft';
      case ReplaySimulationLabDisposition.accepted:
        return 'Accepted For Learning';
      case ReplaySimulationLabDisposition.denied:
        return 'Denied';
    }
  }
}

ReplaySimulationLabDisposition _replaySimulationLabDispositionFromWireValue(
  String value,
) {
  switch (value.trim()) {
    case 'accepted':
      return ReplaySimulationLabDisposition.accepted;
    case 'denied':
      return ReplaySimulationLabDisposition.denied;
    case 'draft':
    default:
      return ReplaySimulationLabDisposition.draft;
  }
}

class ReplaySimulationLabOutcomeRecord {
  const ReplaySimulationLabOutcomeRecord({
    required this.environmentId,
    required this.cityCode,
    required this.replayYear,
    required this.labRoot,
    required this.snapshotJsonPath,
    required this.learningBundleJsonPath,
    required this.realityModelRequestJsonPath,
    required this.outcomeJsonPath,
    required this.readmePath,
    required this.recordedAt,
    required this.disposition,
    required this.operatorRationale,
    required this.operatorNotes,
    required this.trainingGrade,
    required this.suggestedTrainingUse,
    required this.shareWithRealityModelAllowed,
    required this.scenarioCount,
    required this.comparisonCount,
    required this.receiptCount,
    required this.contradictionCount,
    required this.overlayCount,
    required this.requestPreviewCount,
    required this.simulationMode,
    this.syntheticHumanKernelEntries =
        const <ReplaySimulationSyntheticHumanKernelEntry>[],
    this.localityHierarchyNodes =
        const <ReplaySimulationLocalityHierarchyNodeSummary>[],
    this.higherAgentHandoffItems =
        const <ReplaySimulationHigherAgentHandoffItem>[],
    this.realismProvenance = const ReplaySimulationRealismProvenanceSummary(),
    required this.intakeFlowRefs,
    required this.sidecarRefs,
    this.cityPackStructuralRef,
    required this.trainingArtifactFamilies,
    this.variantId,
    this.variantLabel,
  });

  final String environmentId;
  final String cityCode;
  final int replayYear;
  final String labRoot;
  final String snapshotJsonPath;
  final String learningBundleJsonPath;
  final String realityModelRequestJsonPath;
  final String outcomeJsonPath;
  final String readmePath;
  final DateTime recordedAt;
  final ReplaySimulationLabDisposition disposition;
  final String operatorRationale;
  final List<String> operatorNotes;
  final String trainingGrade;
  final String suggestedTrainingUse;
  final bool shareWithRealityModelAllowed;
  final int scenarioCount;
  final int comparisonCount;
  final int receiptCount;
  final int contradictionCount;
  final int overlayCount;
  final int requestPreviewCount;
  final String simulationMode;
  final List<ReplaySimulationSyntheticHumanKernelEntry>
      syntheticHumanKernelEntries;
  final List<ReplaySimulationLocalityHierarchyNodeSummary>
      localityHierarchyNodes;
  final List<ReplaySimulationHigherAgentHandoffItem> higherAgentHandoffItems;
  final ReplaySimulationRealismProvenanceSummary realismProvenance;
  final List<String> intakeFlowRefs;
  final List<String> sidecarRefs;
  final String? cityPackStructuralRef;
  final List<String> trainingArtifactFamilies;
  final String? variantId;
  final String? variantLabel;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'environmentId': environmentId,
      'cityCode': cityCode,
      'replayYear': replayYear,
      'labRoot': labRoot,
      'snapshotJsonPath': snapshotJsonPath,
      'learningBundleJsonPath': learningBundleJsonPath,
      'realityModelRequestJsonPath': realityModelRequestJsonPath,
      'outcomeJsonPath': outcomeJsonPath,
      'readmePath': readmePath,
      'recordedAt': recordedAt.toUtc().toIso8601String(),
      'disposition': disposition.toWireValue(),
      'operatorRationale': operatorRationale,
      'operatorNotes': operatorNotes,
      'trainingGrade': trainingGrade,
      'suggestedTrainingUse': suggestedTrainingUse,
      'shareWithRealityModelAllowed': shareWithRealityModelAllowed,
      'scenarioCount': scenarioCount,
      'comparisonCount': comparisonCount,
      'receiptCount': receiptCount,
      'contradictionCount': contradictionCount,
      'overlayCount': overlayCount,
      'requestPreviewCount': requestPreviewCount,
      'simulationMode': simulationMode,
      'syntheticHumanKernelEntries':
          syntheticHumanKernelEntries.map((entry) => entry.toJson()).toList(),
      'localityHierarchyNodes':
          localityHierarchyNodes.map((entry) => entry.toJson()).toList(),
      'higherAgentHandoffItems':
          higherAgentHandoffItems.map((entry) => entry.toJson()).toList(),
      'realismProvenance': realismProvenance.toJson(),
      'intakeFlowRefs': intakeFlowRefs,
      'sidecarRefs': sidecarRefs,
      'cityPackStructuralRef': cityPackStructuralRef,
      'trainingArtifactFamilies': trainingArtifactFamilies,
      'variantId': variantId,
      'variantLabel': variantLabel,
    };
  }

  factory ReplaySimulationLabOutcomeRecord.fromJson(Map<String, dynamic> json) {
    return ReplaySimulationLabOutcomeRecord(
      environmentId: (json['environmentId'] ?? '').toString(),
      cityCode: (json['cityCode'] ?? '').toString(),
      replayYear: (json['replayYear'] as num?)?.toInt() ?? 0,
      labRoot: (json['labRoot'] ?? '').toString(),
      snapshotJsonPath: (json['snapshotJsonPath'] ?? '').toString(),
      learningBundleJsonPath: (json['learningBundleJsonPath'] ?? '').toString(),
      realityModelRequestJsonPath:
          (json['realityModelRequestJsonPath'] ?? '').toString(),
      outcomeJsonPath: (json['outcomeJsonPath'] ?? '').toString(),
      readmePath: (json['readmePath'] ?? '').toString(),
      recordedAt: DateTime.tryParse((json['recordedAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      disposition: _replaySimulationLabDispositionFromWireValue(
        (json['disposition'] ?? 'draft').toString(),
      ),
      operatorRationale: (json['operatorRationale'] ?? '').toString(),
      operatorNotes: (json['operatorNotes'] as List<dynamic>? ?? const [])
          .map((entry) => entry.toString())
          .toList(growable: false),
      trainingGrade: (json['trainingGrade'] ?? '').toString(),
      suggestedTrainingUse: (json['suggestedTrainingUse'] ?? '').toString(),
      shareWithRealityModelAllowed:
          json['shareWithRealityModelAllowed'] == true,
      scenarioCount: (json['scenarioCount'] as num?)?.toInt() ?? 0,
      comparisonCount: (json['comparisonCount'] as num?)?.toInt() ?? 0,
      receiptCount: (json['receiptCount'] as num?)?.toInt() ?? 0,
      contradictionCount: (json['contradictionCount'] as num?)?.toInt() ?? 0,
      overlayCount: (json['overlayCount'] as num?)?.toInt() ?? 0,
      requestPreviewCount: (json['requestPreviewCount'] as num?)?.toInt() ?? 0,
      simulationMode: (json['simulationMode'] ?? '').toString(),
      syntheticHumanKernelEntries:
          (json['syntheticHumanKernelEntries'] as List<dynamic>? ?? const [])
              .whereType<Map<dynamic, dynamic>>()
              .map(
                (entry) => ReplaySimulationSyntheticHumanKernelEntry.fromJson(
                  Map<String, dynamic>.from(entry),
                ),
              )
              .toList(growable: false),
      localityHierarchyNodes:
          (json['localityHierarchyNodes'] as List<dynamic>? ?? const [])
              .whereType<Map<dynamic, dynamic>>()
              .map(
                (entry) =>
                    ReplaySimulationLocalityHierarchyNodeSummary.fromJson(
                  Map<String, dynamic>.from(entry),
                ),
              )
              .toList(growable: false),
      higherAgentHandoffItems:
          (json['higherAgentHandoffItems'] as List<dynamic>? ?? const [])
              .whereType<Map<dynamic, dynamic>>()
              .map(
                (entry) => ReplaySimulationHigherAgentHandoffItem.fromJson(
                  Map<String, dynamic>.from(entry),
                ),
              )
              .toList(growable: false),
      realismProvenance: json['realismProvenance'] is Map<dynamic, dynamic>
          ? ReplaySimulationRealismProvenanceSummary.fromJson(
              Map<String, dynamic>.from(
                json['realismProvenance'] as Map<dynamic, dynamic>,
              ),
            )
          : const ReplaySimulationRealismProvenanceSummary(),
      intakeFlowRefs: (json['intakeFlowRefs'] as List<dynamic>? ?? const [])
          .map((entry) => entry.toString())
          .toList(growable: false),
      sidecarRefs: (json['sidecarRefs'] as List<dynamic>? ?? const [])
          .map((entry) => entry.toString())
          .toList(growable: false),
      cityPackStructuralRef:
          (json['cityPackStructuralRef'] as String?)?.trim().isEmpty == true
              ? null
              : (json['cityPackStructuralRef'] as String?),
      trainingArtifactFamilies:
          (json['trainingArtifactFamilies'] as List<dynamic>? ?? const [])
              .map((entry) => entry.toString())
              .toList(growable: false),
      variantId: (json['variantId'] as String?)?.trim().isEmpty == true
          ? null
          : (json['variantId'] as String?),
      variantLabel: (json['variantLabel'] as String?)?.trim().isEmpty == true
          ? null
          : (json['variantLabel'] as String?),
    );
  }
}

class ReplaySimulationAdminSnapshot {
  const ReplaySimulationAdminSnapshot({
    required this.generatedAt,
    required this.environmentId,
    required this.cityCode,
    required this.replayYear,
    required this.scenarios,
    required this.comparisons,
    required this.receipts,
    required this.contradictions,
    required this.localityOverlays,
    this.foundation = const ReplaySimulationAdminFoundationSummary(),
    this.learningReadiness = const ReplaySimulationLearningReadiness(),
    this.syntheticHumanKernelExplorer =
        const ReplaySimulationSyntheticHumanKernelExplorer(),
    this.localityHierarchyHealth =
        const ReplaySimulationLocalityHierarchyHealth(),
    this.higherAgentHandoffView =
        const ReplaySimulationHigherAgentHandoffView(),
    this.realismProvenance = const ReplaySimulationRealismProvenanceSummary(),
    this.weakSpots = const <ReplaySimulationWeakSpotSummary>[],
  });

  final DateTime generatedAt;
  final String environmentId;
  final String cityCode;
  final int replayYear;
  final List<ReplayScenarioPacket> scenarios;
  final List<ReplayScenarioComparison> comparisons;
  final List<SimulationTruthReceipt> receipts;
  final List<ReplayContradictionSnapshot> contradictions;
  final List<ReplayLocalityOverlaySnapshot> localityOverlays;
  final ReplaySimulationAdminFoundationSummary foundation;
  final ReplaySimulationLearningReadiness learningReadiness;
  final ReplaySimulationSyntheticHumanKernelExplorer
      syntheticHumanKernelExplorer;
  final ReplaySimulationLocalityHierarchyHealth localityHierarchyHealth;
  final ReplaySimulationHigherAgentHandoffView higherAgentHandoffView;
  final ReplaySimulationRealismProvenanceSummary realismProvenance;
  final List<ReplaySimulationWeakSpotSummary> weakSpots;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'generatedAt': generatedAt.toUtc().toIso8601String(),
      'environmentId': environmentId,
      'cityCode': cityCode,
      'replayYear': replayYear,
      'scenarios': scenarios.map((entry) => entry.toJson()).toList(),
      'comparisons': comparisons.map((entry) => entry.toJson()).toList(),
      'receipts': receipts.map((entry) => entry.toJson()).toList(),
      'contradictions': contradictions.map((entry) => entry.toJson()).toList(),
      'localityOverlays':
          localityOverlays.map((entry) => entry.toJson()).toList(),
      'foundation': foundation.toJson(),
      'learningReadiness': learningReadiness.toJson(),
      'syntheticHumanKernelExplorer': syntheticHumanKernelExplorer.toJson(),
      'localityHierarchyHealth': localityHierarchyHealth.toJson(),
      'higherAgentHandoffView': higherAgentHandoffView.toJson(),
      'realismProvenance': realismProvenance.toJson(),
      'weakSpots': weakSpots.map((entry) => entry.toJson()).toList(),
    };
  }
}

class ReplaySimulationAdminScenarioTemplate {
  const ReplaySimulationAdminScenarioTemplate({
    required this.scenarioId,
    required this.name,
    required this.description,
    required this.scenarioKind,
    required this.scope,
    required this.seedEntityRefs,
    required this.seedLocalityCodes,
    this.seedObservationRefs = const <String>[],
    this.interventions = const <ReplayScenarioIntervention>[],
    this.expectedQuestions = const <String>[],
  });

  final String scenarioId;
  final String name;
  final String description;
  final ReplayScenarioKind scenarioKind;
  final ReplayScopeKind scope;
  final List<String> seedEntityRefs;
  final List<String> seedLocalityCodes;
  final List<String> seedObservationRefs;
  final List<ReplayScenarioIntervention> interventions;
  final List<String> expectedQuestions;
}

abstract class ReplaySimulationAdminEnvironmentAdapter {
  const ReplaySimulationAdminEnvironmentAdapter();

  ReplaySimulationAdminEnvironmentDescriptor get descriptor;

  Future<ReplaySimulationAdminSnapshot> buildSnapshot({
    required DateTime generatedAt,
  });
}

class BhamReplaySimulationAdminEnvironmentAdapter
    implements ReplaySimulationAdminEnvironmentAdapter {
  const BhamReplaySimulationAdminEnvironmentAdapter({
    BhamEventScenarioPackService? scenarioPackService,
    BhamReplayScenarioPacketService? scenarioPacketService,
    BhamReplayScenarioComparisonService? scenarioComparisonService,
    BhamReplayTruthReceiptService? truthReceiptService,
    BhamReplayContradictionDashboardService? contradictionDashboardService,
    BhamReplayLocalityOverlayService? localityOverlayService,
    this.environmentId = 'bham-replay-world-2023',
    this.displayName = 'Birmingham Simulation Environment 2023',
    this.description =
        'Default Birmingham simulation environment for admin oversight.',
    this.replayYear = bhamReplayBaseYear,
  })  : _scenarioPackService =
            scenarioPackService ?? const BhamEventScenarioPackService(),
        _scenarioPacketService =
            scenarioPacketService ?? const BhamReplayScenarioPacketService(),
        _scenarioComparisonService = scenarioComparisonService ??
            const BhamReplayScenarioComparisonService(),
        _truthReceiptService =
            truthReceiptService ?? const BhamReplayTruthReceiptService(),
        _contradictionDashboardService = contradictionDashboardService ??
            const BhamReplayContradictionDashboardService(),
        _localityOverlayService =
            localityOverlayService ?? const BhamReplayLocalityOverlayService();

  final BhamEventScenarioPackService _scenarioPackService;
  final BhamReplayScenarioPacketService _scenarioPacketService;
  final BhamReplayScenarioComparisonService _scenarioComparisonService;
  final BhamReplayTruthReceiptService _truthReceiptService;
  final BhamReplayContradictionDashboardService _contradictionDashboardService;
  final BhamReplayLocalityOverlayService _localityOverlayService;

  final String environmentId;
  final String displayName;
  final String description;
  final int replayYear;

  @override
  ReplaySimulationAdminEnvironmentDescriptor get descriptor =>
      ReplaySimulationAdminEnvironmentDescriptor(
        environmentId: environmentId,
        displayName: displayName,
        cityCode: bhamReplayCityCode,
        replayYear: replayYear,
        description: description,
        simulationMode: 'bham_native',
        cityPackStructuralRef: _deriveReplaySimulationCityPackStructuralRef(
          cityCode: bhamReplayCityCode,
          replayYear: replayYear,
        ),
      );

  @override
  Future<ReplaySimulationAdminSnapshot> buildSnapshot({
    required DateTime generatedAt,
  }) async {
    final scenarios = _scenarioPackService.buildScenarioPack(
      createdAt: generatedAt,
    );
    final comparisons = <ReplayScenarioComparison>[];
    final receipts = <SimulationTruthReceipt>[];
    final contradictions = <ReplayContradictionSnapshot>[];
    final overlays = <ReplayLocalityOverlaySnapshot>[];

    for (final scenario in scenarios) {
      final batchItems = _scenarioPacketService.materializeScenarioBatchItems(
        scenario,
      );
      final comparison = _scenarioComparisonService.compareScenarioRuns(
        packet: scenario,
        items: batchItems,
      );
      final scenarioContradictions = _contradictionDashboardService
          .buildSnapshot(packet: scenario, comparison: comparison);
      comparisons.add(comparison);
      contradictions.addAll(scenarioContradictions);
      receipts.add(
        _truthReceiptService.buildReceipt(
          packet: scenario,
          comparison: comparison,
          contradictions: scenarioContradictions,
        ),
      );
      overlays.addAll(
        _localityOverlayService.buildOverlaySnapshots(
          packet: scenario,
          comparison: comparison,
          contradictions: scenarioContradictions,
        ),
      );
    }

    final dedupedOverlays = <String, ReplayLocalityOverlaySnapshot>{};
    for (final overlay in overlays) {
      final current = dedupedOverlays[overlay.localityCode];
      if (current == null ||
          overlay.branchSensitivity > current.branchSensitivity ||
          overlay.contradictionCount > current.contradictionCount) {
        dedupedOverlays[overlay.localityCode] = overlay;
      }
    }

    final localityOverlays = dedupedOverlays.values.toList(growable: false)
      ..sort(
        (left, right) =>
            right.branchSensitivity.compareTo(left.branchSensitivity),
      );
    final foundation = _buildFoundationSummary(
      descriptor: descriptor,
      scenarios: scenarios,
      comparisons: comparisons,
      receipts: receipts,
      contradictions: contradictions,
      localityOverlays: localityOverlays,
    );
    final learningReadiness = _buildLearningReadiness(
      snapshotEnvironmentId: environmentId,
      cityCode: bhamReplayCityCode,
      replayYear: replayYear,
      scenarios: scenarios,
      comparisons: comparisons,
      receipts: receipts,
      contradictions: contradictions,
      localityOverlays: localityOverlays,
      foundation: foundation,
    );
    final syntheticHumanKernelExplorer = _buildSyntheticHumanKernelExplorer(
      descriptor: descriptor,
      scenarios: scenarios,
      comparisons: comparisons,
      receipts: receipts,
      contradictions: contradictions,
      localityOverlays: localityOverlays,
      foundation: foundation,
    );
    final localityHierarchyHealth = _buildLocalityHierarchyHealth(
      descriptor: descriptor,
      scenarios: scenarios,
      localityOverlays: localityOverlays,
    );
    final higherAgentHandoffView = _buildHigherAgentHandoffView(
      descriptor: descriptor,
      localityHierarchyHealth: localityHierarchyHealth,
      learningReadiness: learningReadiness,
    );
    final realismProvenance = _buildRealismProvenanceSummary(
      descriptor: descriptor,
      foundation: foundation,
      scenarios: scenarios,
      localityOverlays: localityOverlays,
    );
    final weakSpots = _buildWeakSpotsBeforeTraining(
      foundation: foundation,
      learningReadiness: learningReadiness,
      localityHierarchyHealth: localityHierarchyHealth,
      realismProvenance: realismProvenance,
    );
    return ReplaySimulationAdminSnapshot(
      generatedAt: generatedAt,
      environmentId: environmentId,
      cityCode: bhamReplayCityCode,
      replayYear: replayYear,
      scenarios: scenarios,
      comparisons: comparisons,
      receipts: receipts,
      contradictions: contradictions,
      localityOverlays: localityOverlays,
      foundation: foundation,
      learningReadiness: learningReadiness,
      syntheticHumanKernelExplorer: syntheticHumanKernelExplorer,
      localityHierarchyHealth: localityHierarchyHealth,
      higherAgentHandoffView: higherAgentHandoffView,
      realismProvenance: realismProvenance,
      weakSpots: weakSpots,
    );
  }
}

class SyntheticReplaySimulationAdminEnvironmentAdapter
    implements ReplaySimulationAdminEnvironmentAdapter {
  const SyntheticReplaySimulationAdminEnvironmentAdapter({
    required this.descriptor,
    required this.localityDisplayNames,
    this.scenarioTemplates = const <ReplaySimulationAdminScenarioTemplate>[],
    this.createdBy = 'internal_stage2_pack',
  });

  @override
  final ReplaySimulationAdminEnvironmentDescriptor descriptor;

  final Map<String, String> localityDisplayNames;
  final List<ReplaySimulationAdminScenarioTemplate> scenarioTemplates;
  final String createdBy;

  @override
  Future<ReplaySimulationAdminSnapshot> buildSnapshot({
    required DateTime generatedAt,
  }) async {
    final scenarios = _buildScenarioPack(generatedAt);
    final comparisons = <ReplayScenarioComparison>[];
    final receipts = <SimulationTruthReceipt>[];
    final contradictions = <ReplayContradictionSnapshot>[];
    final overlays = <ReplayLocalityOverlaySnapshot>[];

    for (final scenario in scenarios) {
      final batchItems = _materializeScenarioBatchItems(scenario);
      final comparison = _compareScenarioRuns(
        packet: scenario,
        items: batchItems,
      );
      final scenarioContradictions = _buildContradictions(
        packet: scenario,
        comparison: comparison,
      );
      comparisons.add(comparison);
      contradictions.addAll(scenarioContradictions);
      receipts.add(
        _buildReceipt(
          packet: scenario,
          comparison: comparison,
          contradictions: scenarioContradictions,
        ),
      );
      overlays.addAll(
        _buildOverlaySnapshots(
          packet: scenario,
          comparison: comparison,
          contradictions: scenarioContradictions,
        ),
      );
    }

    final dedupedOverlays = <String, ReplayLocalityOverlaySnapshot>{};
    for (final overlay in overlays) {
      final current = dedupedOverlays[overlay.localityCode];
      if (current == null ||
          overlay.branchSensitivity > current.branchSensitivity ||
          overlay.contradictionCount > current.contradictionCount) {
        dedupedOverlays[overlay.localityCode] = overlay;
      }
    }

    final localityOverlays = dedupedOverlays.values.toList(growable: false)
      ..sort(
        (left, right) =>
            right.branchSensitivity.compareTo(left.branchSensitivity),
      );
    final foundation = _buildFoundationSummary(
      descriptor: descriptor,
      scenarios: scenarios,
      comparisons: comparisons,
      receipts: receipts,
      contradictions: contradictions,
      localityOverlays: localityOverlays,
    );
    final learningReadiness = _buildLearningReadiness(
      snapshotEnvironmentId: descriptor.environmentId,
      cityCode: descriptor.cityCode,
      replayYear: descriptor.replayYear,
      scenarios: scenarios,
      comparisons: comparisons,
      receipts: receipts,
      contradictions: contradictions,
      localityOverlays: localityOverlays,
      foundation: foundation,
    );
    final syntheticHumanKernelExplorer = _buildSyntheticHumanKernelExplorer(
      descriptor: descriptor,
      scenarios: scenarios,
      comparisons: comparisons,
      receipts: receipts,
      contradictions: contradictions,
      localityOverlays: localityOverlays,
      foundation: foundation,
    );
    final localityHierarchyHealth = _buildLocalityHierarchyHealth(
      descriptor: descriptor,
      scenarios: scenarios,
      localityOverlays: localityOverlays,
    );
    final higherAgentHandoffView = _buildHigherAgentHandoffView(
      descriptor: descriptor,
      localityHierarchyHealth: localityHierarchyHealth,
      learningReadiness: learningReadiness,
    );
    final realismProvenance = _buildRealismProvenanceSummary(
      descriptor: descriptor,
      foundation: foundation,
      scenarios: scenarios,
      localityOverlays: localityOverlays,
    );
    final weakSpots = _buildWeakSpotsBeforeTraining(
      foundation: foundation,
      learningReadiness: learningReadiness,
      localityHierarchyHealth: localityHierarchyHealth,
      realismProvenance: realismProvenance,
    );
    return ReplaySimulationAdminSnapshot(
      generatedAt: generatedAt,
      environmentId: descriptor.environmentId,
      cityCode: descriptor.cityCode,
      replayYear: descriptor.replayYear,
      scenarios: scenarios,
      comparisons: comparisons,
      receipts: receipts,
      contradictions: contradictions,
      localityOverlays: localityOverlays,
      foundation: foundation,
      learningReadiness: learningReadiness,
      syntheticHumanKernelExplorer: syntheticHumanKernelExplorer,
      localityHierarchyHealth: localityHierarchyHealth,
      higherAgentHandoffView: higherAgentHandoffView,
      realismProvenance: realismProvenance,
      weakSpots: weakSpots,
    );
  }

  List<ReplayScenarioPacket> _buildScenarioPack(DateTime generatedAt) {
    final templates = scenarioTemplates.isEmpty
        ? _defaultScenarioTemplates(generatedAt)
        : scenarioTemplates;
    return templates
        .map(
          (template) => ReplayScenarioPacket(
            scenarioId: template.scenarioId,
            name: template.name,
            description: template.description,
            cityCode: descriptor.cityCode,
            baseReplayYear: descriptor.replayYear,
            scenarioKind: template.scenarioKind,
            scope: template.scope,
            seedEntityRefs: template.seedEntityRefs,
            seedLocalityCodes: template.seedLocalityCodes,
            seedObservationRefs: template.seedObservationRefs,
            interventions: template.interventions,
            expectedQuestions: template.expectedQuestions,
            createdAt: generatedAt,
            createdBy: createdBy,
          ).normalized(),
        )
        .toList(growable: false);
  }

  List<ReplaySimulationAdminScenarioTemplate> _defaultScenarioTemplates(
    DateTime generatedAt,
  ) {
    final localities = localityDisplayNames.keys.toList(growable: false)
      ..sort();
    final primary =
        localities.isEmpty ? '${descriptor.cityCode}_core' : localities.first;
    final secondary = localities.length >= 2 ? localities[1] : primary;
    final tertiary = localities.length >= 3 ? localities[2] : secondary;
    final year = descriptor.replayYear;
    return <ReplaySimulationAdminScenarioTemplate>[
      ReplaySimulationAdminScenarioTemplate(
        scenarioId: '${descriptor.cityCode}_city_coordination_load',
        name: '${descriptor.displayName} coordination load',
        description:
            'Tests coordinated attendance and reroute pressure across the highest-signal localities in ${descriptor.displayName}.',
        scenarioKind: ReplayScenarioKind.eventOps,
        scope: ReplayScopeKind.city,
        seedEntityRefs: <String>[
          'event:${descriptor.cityCode}_coordination_day'
        ],
        seedLocalityCodes:
            {primary, secondary, tertiary}.toList(growable: false),
        seedObservationRefs: <String>[
          'obs:${descriptor.cityCode}_coordination_seed'
        ],
        interventions: <ReplayScenarioIntervention>[
          ReplayScenarioIntervention(
            interventionId: 'attendance_surge_primary',
            kind: ReplayInterventionKind.attendanceSurge,
            targetType: 'locality',
            targetRef: primary,
            effectiveStart: DateTime.utc(year, 4, 12, 17),
            effectiveEnd: DateTime.utc(year, 4, 12, 23),
            magnitude: 0.28,
            notes: 'Primary locality takes the first coordinated surge.',
          ),
          ReplayScenarioIntervention(
            interventionId: 'route_block_secondary',
            kind: ReplayInterventionKind.routeBlock,
            targetType: 'locality',
            targetRef: secondary,
            effectiveStart: DateTime.utc(year, 4, 12, 18),
            effectiveEnd: DateTime.utc(year, 4, 12, 22),
            magnitude: 0.18,
            notes:
                'Route friction compounds spillover into adjacent localities.',
          ),
        ],
        expectedQuestions: <String>[
          'Which locality absorbs overflow most cleanly?',
          'Where does route friction become a contradiction first?',
        ],
      ),
      ReplaySimulationAdminScenarioTemplate(
        scenarioId: '${descriptor.cityCode}_weather_resilience',
        name: '${descriptor.displayName} weather resilience',
        description:
            'Tests weather shock plus staffing pressure across a multi-locality replay baseline.',
        scenarioKind: ReplayScenarioKind.weather,
        scope: ReplayScopeKind.city,
        seedEntityRefs: <String>['event:${descriptor.cityCode}_outdoor_series'],
        seedLocalityCodes: {primary, secondary}.toList(growable: false),
        seedObservationRefs: <String>[
          'obs:${descriptor.cityCode}_weather_seed'
        ],
        interventions: <ReplayScenarioIntervention>[
          ReplayScenarioIntervention(
            interventionId: 'weather_shift_city',
            kind: ReplayInterventionKind.weatherShift,
            targetType: 'city',
            targetRef: descriptor.cityCode,
            effectiveStart: DateTime.utc(year, 5, 19, 17),
            effectiveEnd: DateTime.utc(year, 5, 19, 23),
            magnitude: 0.33,
            notes: 'Fast weather degradation pushes contingency behavior.',
          ),
          ReplayScenarioIntervention(
            interventionId: 'staffing_loss_weather',
            kind: ReplayInterventionKind.staffingLoss,
            targetType: 'event',
            targetRef: 'event:${descriptor.cityCode}_outdoor_series',
            effectiveStart: DateTime.utc(year, 5, 19, 18),
            effectiveEnd: DateTime.utc(year, 5, 19, 22),
            magnitude: 0.17,
            notes:
                'Weather shock compounds staffing pressure during peak hours.',
          ),
        ],
        expectedQuestions: <String>[
          'How quickly does weather pressure convert into locality stress?',
          'Which seeded localities remain stable under coupled staffing loss?',
        ],
      ),
      ReplaySimulationAdminScenarioTemplate(
        scenarioId: '${descriptor.cityCode}_locality_resilience',
        name: '${descriptor.displayName} locality resilience',
        description:
            'Tests localized caution and transit friction for the most fragile-seeming locality pair in ${descriptor.displayName}.',
        scenarioKind: ReplayScenarioKind.transitFriction,
        scope: ReplayScopeKind.locality,
        seedEntityRefs: <String>['corridor:${descriptor.cityCode}_link_axis'],
        seedLocalityCodes: {secondary, tertiary}.toList(growable: false),
        seedObservationRefs: <String>[
          'obs:${descriptor.cityCode}_resilience_seed'
        ],
        interventions: <ReplayScenarioIntervention>[
          ReplayScenarioIntervention(
            interventionId: 'transit_delay_axis',
            kind: ReplayInterventionKind.transitDelay,
            targetType: 'corridor',
            targetRef: 'corridor:${descriptor.cityCode}_link_axis',
            effectiveStart: DateTime.utc(year, 7, 20, 17),
            effectiveEnd: DateTime.utc(year, 7, 20, 22),
            magnitude: 0.22,
            notes:
                'Transit delay tests pathflow resilience between seeded localities.',
          ),
          ReplayScenarioIntervention(
            interventionId: 'locality_caution_target',
            kind: ReplayInterventionKind.localityCaution,
            targetType: 'locality',
            targetRef: tertiary,
            effectiveStart: DateTime.utc(year, 7, 20, 18),
            effectiveEnd: DateTime.utc(year, 7, 20, 21),
            magnitude: 0.19,
            notes:
                'Localized caution raises contradiction pressure for the trailing locality.',
          ),
        ],
        expectedQuestions: <String>[
          'Does transit friction or locality caution dominate first?',
          'Which locality becomes the contradiction hotspot under coupled friction?',
        ],
      ),
    ];
  }

  List<_ReplayScenarioBatchItem> _materializeScenarioBatchItems(
    ReplayScenarioPacket packet,
  ) {
    final baseline = _ReplayScenarioBatchItem(
      runId: '${packet.scenarioId}:baseline',
      branchLabel: 'baseline',
      packet: packet,
      attendanceScore: 0.72,
      movementScore: 0.68,
      deliveryScore: 0.76,
      safetyStress: 0.28,
      localityPressures: _baselineLocalityPressures(packet),
    );
    final branches = packet.interventions.map((intervention) {
      final basePressure = _baselineLocalityPressures(packet);
      final targetLocality = intervention.targetType == 'locality'
          ? intervention.targetRef
          : packet.seedLocalityCodes.first;
      final pressureMagnitude = (intervention.magnitude * 0.55).clamp(0.0, 1.0);
      final attendancePenalty =
          intervention.kind == ReplayInterventionKind.attendanceSurge
              ? -intervention.magnitude * 0.10
              : -intervention.magnitude * 0.18;
      final movementPenalty =
          intervention.kind == ReplayInterventionKind.transitDelay ||
                  intervention.kind == ReplayInterventionKind.routeBlock
              ? intervention.magnitude * 0.22
              : intervention.magnitude * 0.12;
      final deliveryPenalty =
          intervention.kind == ReplayInterventionKind.staffingLoss
              ? intervention.magnitude * 0.24
              : intervention.magnitude * 0.14;
      final safetyStress =
          (baseline.safetyStress + intervention.magnitude * 0.35)
              .clamp(0.0, 1.0);
      return _ReplayScenarioBatchItem(
        runId: '${packet.scenarioId}:${intervention.interventionId}',
        branchLabel: intervention.kind.name,
        packet: packet,
        attendanceScore:
            (baseline.attendanceScore + attendancePenalty).clamp(0.0, 1.0),
        movementScore:
            (baseline.movementScore - movementPenalty).clamp(0.0, 1.0),
        deliveryScore:
            (baseline.deliveryScore - deliveryPenalty).clamp(0.0, 1.0),
        safetyStress: safetyStress,
        localityPressures: <String, double>{
          for (final entry in basePressure.entries)
            entry.key: entry.key == targetLocality
                ? (entry.value + pressureMagnitude).clamp(0.0, 1.0)
                : entry.value,
        },
      );
    });
    return <_ReplayScenarioBatchItem>[baseline, ...branches];
  }

  Map<String, double> _baselineLocalityPressures(ReplayScenarioPacket packet) {
    final pressures = <String, double>{};
    for (final locality in packet.seedLocalityCodes) {
      pressures[locality] = 0.32 + (pressures.length * 0.05);
    }
    if (pressures.isEmpty) {
      pressures['${descriptor.cityCode}_unanchored'] = 0.32;
    }
    return pressures;
  }

  ReplayScenarioComparison _compareScenarioRuns({
    required ReplayScenarioPacket packet,
    required List<_ReplayScenarioBatchItem> items,
  }) {
    if (items.isEmpty) {
      throw ArgumentError(
          'Scenario comparison requires at least one batch item.');
    }
    final baseline = items.first;
    final branchItems = items.skip(1).toList(growable: false);
    final branchDiffs = branchItems.map((item) {
      return ReplayScenarioBranchDiff(
        branchRunId: item.runId,
        attendanceDelta: item.attendanceScore - baseline.attendanceScore,
        movementDelta: item.movementScore - baseline.movementScore,
        deliveryDelta: item.deliveryScore - baseline.deliveryScore,
        safetyStressDelta: item.safetyStress - baseline.safetyStress,
        localityPressureDeltas: <String, double>{
          for (final locality in {
            ...baseline.localityPressures.keys,
            ...item.localityPressures.keys,
          })
            locality: (item.localityPressures[locality] ?? 0.0) -
                (baseline.localityPressures[locality] ?? 0.0),
        },
        keyNarrativeLines: _summarizeBranchDiffs(
          baseline: baseline,
          branch: item,
        ),
      );
    }).toList(growable: false);

    final dominantLocality = _dominantLocality(branchDiffs);
    return ReplayScenarioComparison(
      scenarioId: packet.scenarioId,
      baselineRunId: baseline.runId,
      branchRunIds:
          branchItems.map((item) => item.runId).toList(growable: false),
      branchDiffs: branchDiffs,
      summary:
          '${packet.name} shifts most strongly around ${_displayNameForLocality(dominantLocality)} with ${branchDiffs.length} intervention branches.',
      generatedAt: DateTime.now().toUtc(),
    );
  }

  List<String> _summarizeBranchDiffs({
    required _ReplayScenarioBatchItem baseline,
    required _ReplayScenarioBatchItem branch,
  }) {
    final dominantLocality = _dominantPressureLocality(
      baseline.localityPressures,
      branch.localityPressures,
    );
    return <String>[
      '${branch.branchLabel} shifts attendance by ${_signedPct(branch.attendanceScore - baseline.attendanceScore)} against baseline.',
      'Movement changes by ${_signedPct(branch.movementScore - baseline.movementScore)} and delivery changes by ${_signedPct(branch.deliveryScore - baseline.deliveryScore)}.',
      'The largest locality pressure change lands in ${_displayNameForLocality(dominantLocality)}.',
    ];
  }

  List<ReplayContradictionSnapshot> _buildContradictions({
    required ReplayScenarioPacket packet,
    required ReplayScenarioComparison comparison,
  }) {
    return comparison.branchDiffs.map((diff) {
      return ReplayContradictionSnapshot(
        snapshotId: '${diff.branchRunId}:contradiction',
        runId: diff.branchRunId,
        entityRef: packet.seedEntityRefs.isEmpty
            ? packet.scenarioId
            : packet.seedEntityRefs.first,
        localityCode: _dominantLocality(<ReplayScenarioBranchDiff>[diff]),
        contradictionType: _typeForDiff(diff),
        replayExpectation:
            'Replay prior remains inside ordinary ${descriptor.displayName} pressure for ${packet.name}.',
        liveObserved:
            'Intervention branch diverges from the replay prior under ${diff.branchRunId}.',
        severity: _severityForDiff(diff),
        status: ReplayContradictionStatus.open,
        capturedAt: DateTime.now().toUtc(),
      );
    }).toList(growable: false);
  }

  SimulationTruthReceipt _buildReceipt({
    required ReplayScenarioPacket packet,
    required ReplayScenarioComparison comparison,
    required List<ReplayContradictionSnapshot> contradictions,
  }) {
    final dominantDiff = comparison.branchDiffs.isEmpty
        ? null
        : comparison.branchDiffs.reduce(
            (left, right) =>
                left.safetyStressDelta.abs() >= right.safetyStressDelta.abs()
                    ? left
                    : right,
          );
    return SimulationTruthReceipt(
      receiptId: '${packet.scenarioId}:receipt',
      runId: comparison.baselineRunId,
      scenarioId: packet.scenarioId,
      forecastTraceRefs: comparison.branchRunIds
          .map((runId) => '$runId:trace')
          .toList(growable: false),
      replayPriorSummary: SimulationTruthSummaryBlock(
        title: 'Replay Prior',
        lines: <String>[
          'Replay receipt remains an internal prior for ${descriptor.displayName}.',
          '${packet.name} started from ${packet.seedLocalityCodes.length} seeded localities.',
        ],
        metadata: <String, dynamic>{
          'baseReplayYear': packet.baseReplayYear,
          'cityCode': packet.cityCode,
          'scope': packet.scope.name,
        },
      ),
      liveEvidenceSummary: SimulationTruthSummaryBlock(
        title: 'Live Evidence',
        lines: <String>[
          'No live user data is promoted here; this receipt remains an internal simulation artifact.',
          if (dominantDiff != null)
            'Most volatile branch was ${dominantDiff.branchRunId} with safety delta ${dominantDiff.safetyStressDelta.toStringAsFixed(2)}.',
        ],
        metadata: const <String, dynamic>{
          'liveEvidencePromoted': false,
        },
      ),
      localityConsensusSummary: SimulationTruthSummaryBlock(
        title: 'Locality Consensus',
        lines: <String>[
          'Comparison synthesized locality pressure deltas across all seeded localities in the selected simulation environment.',
          'Branch sensitivity remains bounded and admin-visible only.',
        ],
      ),
      adminCorrectionSummary: SimulationTruthSummaryBlock(
        title: 'Admin Correction',
        lines: <String>[
          'No admin correction is auto-applied in this simulation surface.',
          'Receipts remain for operator inspection and calibration only.',
        ],
      ),
      contradictionSummary: SimulationTruthSummaryBlock(
        title: 'Contradiction Summary',
        lines: <String>[
          '${contradictions.length} contradiction snapshots were generated from branch deltas.',
          if (contradictions.isNotEmpty)
            'Highest contradiction severity is ${contradictions.map((entry) => entry.severity).reduce((left, right) => left >= right ? left : right).toStringAsFixed(2)}.',
        ],
      ),
      generatedAt: DateTime.now().toUtc(),
    );
  }

  List<ReplayLocalityOverlaySnapshot> _buildOverlaySnapshots({
    required ReplayScenarioPacket packet,
    required ReplayScenarioComparison comparison,
    required List<ReplayContradictionSnapshot> contradictions,
  }) {
    final contradictionCounts = <String, int>{};
    for (final snapshot in contradictions) {
      contradictionCounts[snapshot.localityCode] =
          (contradictionCounts[snapshot.localityCode] ?? 0) + 1;
    }

    final localitySensitivity = <String, double>{};
    for (final diff in comparison.branchDiffs) {
      for (final entry in diff.localityPressureDeltas.entries) {
        localitySensitivity[entry.key] =
            (localitySensitivity[entry.key] ?? 0.0) + entry.value.abs();
      }
    }

    final codes = {
      ...packet.seedLocalityCodes,
      ...localitySensitivity.keys,
      ...contradictionCounts.keys,
    }.toList(growable: false)
      ..sort();

    return codes.map((localityCode) {
      final sensitivity = localitySensitivity[localityCode] ?? 0.0;
      final contradictionCount = contradictionCounts[localityCode] ?? 0;
      return ReplayLocalityOverlaySnapshot(
        localityCode: localityCode,
        displayName: _displayNameForLocality(localityCode),
        pressureBand: _pressureBand(sensitivity),
        attentionBand: contradictionCount >= 2 ? 'escalate' : 'watch',
        primarySignals: <String>[
          if (packet.seedLocalityCodes.contains(localityCode)) 'scenario_seed',
          if (sensitivity > 0.10) 'branch_sensitive',
          if (contradictionCount > 0) 'contradiction_present',
        ],
        branchSensitivity: sensitivity.clamp(0.0, 1.0),
        contradictionCount: contradictionCount,
        updatedAt: DateTime.now().toUtc(),
      );
    }).toList(growable: false);
  }

  ReplayContradictionType _typeForDiff(ReplayScenarioBranchDiff diff) {
    if (diff.safetyStressDelta.abs() >= 0.15) {
      return ReplayContradictionType.safetyStress;
    }
    if (diff.deliveryDelta.abs() >= 0.12) {
      return ReplayContradictionType.delivery;
    }
    if (diff.movementDelta.abs() >= 0.12) {
      return ReplayContradictionType.movement;
    }
    return ReplayContradictionType.localityPressure;
  }

  double _severityForDiff(ReplayScenarioBranchDiff diff) {
    return (diff.safetyStressDelta.abs() * 0.45 +
            diff.deliveryDelta.abs() * 0.25 +
            diff.movementDelta.abs() * 0.20 +
            diff.attendanceDelta.abs() * 0.10)
        .clamp(0.0, 1.0);
  }

  String _dominantLocality(List<ReplayScenarioBranchDiff> diffs) {
    final accumulator = <String, double>{};
    for (final diff in diffs) {
      for (final entry in diff.localityPressureDeltas.entries) {
        accumulator[entry.key] =
            (accumulator[entry.key] ?? 0.0) + entry.value.abs();
      }
    }
    if (accumulator.isEmpty) {
      if (localityDisplayNames.isNotEmpty) {
        return localityDisplayNames.keys.first;
      }
      return '${descriptor.cityCode}_unanchored';
    }
    return accumulator.entries
        .reduce(
          (left, right) => left.value >= right.value ? left : right,
        )
        .key;
  }

  String _dominantPressureLocality(
    Map<String, double> baseline,
    Map<String, double> branch,
  ) {
    final codes = {...baseline.keys, ...branch.keys};
    if (codes.isEmpty) {
      return localityDisplayNames.isEmpty
          ? '${descriptor.cityCode}_unanchored'
          : localityDisplayNames.keys.first;
    }
    var bestCode = codes.first;
    var bestMagnitude = -1.0;
    for (final code in codes) {
      final magnitude = ((branch[code] ?? 0.0) - (baseline[code] ?? 0.0)).abs();
      if (magnitude > bestMagnitude) {
        bestMagnitude = magnitude;
        bestCode = code;
      }
    }
    return bestCode;
  }

  String _signedPct(double value) {
    final pct = (value * 100).toStringAsFixed(1);
    return value >= 0 ? '+$pct%' : '$pct%';
  }

  String _displayNameForLocality(String localityCode) {
    return localityDisplayNames[localityCode] ?? localityCode;
  }

  String _pressureBand(double sensitivity) {
    if (sensitivity >= 0.35) {
      return 'high';
    }
    if (sensitivity >= 0.18) {
      return 'moderate';
    }
    return 'low';
  }
}

class _ReplayScenarioBatchItem {
  const _ReplayScenarioBatchItem({
    required this.runId,
    required this.branchLabel,
    required this.packet,
    required this.attendanceScore,
    required this.movementScore,
    required this.deliveryScore,
    required this.safetyStress,
    required this.localityPressures,
  });

  final String runId;
  final String branchLabel;
  final ReplayScenarioPacket packet;
  final double attendanceScore;
  final double movementScore;
  final double deliveryScore;
  final double safetyStress;
  final Map<String, double> localityPressures;
}

const List<String> _defaultSimulationTrainingArtifactFamilies = <String>[
  'scenario_packets',
  'scenario_comparisons',
  'truth_receipts',
  'contradiction_snapshots',
  'locality_overlays',
  'population_profile',
  'place_graph',
  'daily_behavior',
  'kernel_participation',
  'higher_agent_behavior',
  'action_training',
  'holdout_evaluation',
  'training_export_manifest',
  'storage_export',
];

const List<String> _defaultGenericSimulationIntakeFlowRefs = <String>[
  'source_intake_orchestrator',
  'air_gap_normalizer',
  'entity_fit_router',
  'universal_intake_repository',
];

ReplaySimulationAdminFoundationSummary _buildFoundationSummary({
  required ReplaySimulationAdminEnvironmentDescriptor descriptor,
  required List<ReplayScenarioPacket> scenarios,
  required List<ReplayScenarioComparison> comparisons,
  required List<SimulationTruthReceipt> receipts,
  required List<ReplayContradictionSnapshot> contradictions,
  required List<ReplayLocalityOverlaySnapshot> localityOverlays,
}) {
  final kernelStates = <ReplaySimulationKernelState>[
    ReplaySimulationKernelState(
      kernelId: 'when',
      status: receipts.isNotEmpty ? 'active' : 'derived',
      reason: receipts.isNotEmpty
          ? 'Truth receipts preserve replay timing and scenario chronology.'
          : 'Scenario packets exist, but no receipt timing was materialized.',
    ),
    ReplaySimulationKernelState(
      kernelId: 'where',
      status: localityOverlays.isNotEmpty ? 'active' : 'derived',
      reason: localityOverlays.isNotEmpty
          ? 'Locality overlays and scenario seeds ground spatial pressure.'
          : 'Seeded locality codes are present but no overlay layer exists yet.',
    ),
    ReplaySimulationKernelState(
      kernelId: 'what',
      status: scenarios.any((entry) => entry.seedEntityRefs.isNotEmpty)
          ? 'active'
          : 'derived',
      reason: scenarios.any((entry) => entry.seedEntityRefs.isNotEmpty)
          ? 'Scenario packets carry explicit entity refs for replay grounding.'
          : 'Scenario packets exist, but entity refs are sparse.',
    ),
    ReplaySimulationKernelState(
      kernelId: 'who',
      status: scenarios.any((entry) => entry.expectedQuestions.isNotEmpty)
          ? 'derived'
          : 'missing',
      reason:
          'Generic admin simulation reflects actor/community questions, but not a full actor-world execution pass.',
    ),
    ReplaySimulationKernelState(
      kernelId: 'why',
      status: receipts.isNotEmpty ? 'derived' : 'missing',
      reason:
          'Receipts carry replay-prior and contradiction rationale for operator review.',
    ),
    ReplaySimulationKernelState(
      kernelId: 'how',
      status: comparisons.isNotEmpty ? 'derived' : 'missing',
      reason:
          'Scenario comparisons expose intervention pathways and branch deltas.',
    ),
    ReplaySimulationKernelState(
      kernelId: 'forecast',
      status: comparisons.isNotEmpty ? 'active' : 'missing',
      reason:
          'Branch comparisons and forecast trace refs are present for replay simulation.',
    ),
    ReplaySimulationKernelState(
      kernelId: 'governance',
      status: receipts.isNotEmpty && contradictions.isNotEmpty
          ? 'active'
          : 'derived',
      reason:
          'Truth receipts and contradiction snapshots keep simulation bounded and admin-visible.',
    ),
    ReplaySimulationKernelState(
      kernelId: 'higher_agent_truth',
      status: localityOverlays.isNotEmpty ? 'active' : 'derived',
      reason:
          'Locality overlays and contradiction pressure provide upward/downward replay truth signals.',
    ),
  ];

  final sidecarRefs = <String>[
    if (descriptor.cityPackManifestRef?.isNotEmpty ?? false)
      descriptor.cityPackManifestRef!,
    if (descriptor.campaignDefaultsRef?.isNotEmpty ?? false)
      descriptor.campaignDefaultsRef!,
    if (descriptor.localityExpectationProfileRef?.isNotEmpty ?? false)
      descriptor.localityExpectationProfileRef!,
    if (descriptor.worldHealthProfileRef?.isNotEmpty ?? false)
      descriptor.worldHealthProfileRef!,
    ...descriptor.sidecarRefs,
  ];
  final intakeFlowRefs = descriptor.intakeFlowRefs.isNotEmpty
      ? descriptor.intakeFlowRefs
      : descriptor.simulationMode == 'generic_city_pack'
          ? _defaultGenericSimulationIntakeFlowRefs
          : const <String>[];
  final cityPackStructuralRef = descriptor.cityPackStructuralRef ??
      _deriveReplaySimulationCityPackStructuralRef(
        cityCode: descriptor.cityCode,
        replayYear: descriptor.replayYear,
      );
  const hydrationEvidenceFamilies = <String>[
    'app_observations',
    'runtime_os_locality_state',
    'governed_reality_model_outputs',
  ];

  return ReplaySimulationAdminFoundationSummary(
    simulationMode: descriptor.simulationMode,
    intakeFlowRefs: intakeFlowRefs,
    sidecarRefs: sidecarRefs,
    trainingArtifactFamilies: _defaultSimulationTrainingArtifactFamilies,
    kernelStates: kernelStates,
    notes: <String>[
      'Admin simulation stays grounded in replay packets, contradiction receipts, and locality overlays rather than ad hoc widget logic.',
      if (intakeFlowRefs.isNotEmpty)
        'Generic-city intake is expected to flow through ${intakeFlowRefs.join(', ')}.',
      if (sidecarRefs.isNotEmpty)
        'City-pack sidecars are visible so operators can see which structural refs shaped the simulation.',
      if (descriptor.simulationMode == 'generic_city_pack')
        'Generic-city simulation is staged as a local learning package candidate before any reality-model sharing.',
      'Latest-state hydration is tracked as a versioned living city-pack lane for place:${descriptor.cityCode}, but the currently served basis stays explicit until refreshed AVRAI evidence is promoted with receipts.',
      'Freshness receipts and rollback-safe lineage are required before a newer served basis can replace the current city-pack basis.',
    ],
    metadata: <String, dynamic>{
      'scenarioCount': scenarios.length,
      'comparisonCount': comparisons.length,
      'receiptCount': receipts.length,
      'contradictionCount': contradictions.length,
      'overlayCount': localityOverlays.length,
      'cityPackManifestRef': descriptor.cityPackManifestRef,
      'cityPackStructuralRef': cityPackStructuralRef,
      'campaignDefaultsRef': descriptor.campaignDefaultsRef,
      'localityExpectationProfileRef': descriptor.localityExpectationProfileRef,
      'worldHealthProfileRef': descriptor.worldHealthProfileRef,
      'supportedPlaceRef': 'place:${descriptor.cityCode}',
      'cityPackRefreshMode': 'versioned_living_city_pack',
      'currentBasisStatus': 'replay_grounded_seed_basis',
      'latestStateHydrationStatus': 'awaiting_latest_avrai_evidence_refresh',
      'hydrationEvidenceFamilies': hydrationEvidenceFamilies,
      'hydrationFreshnessPosture':
          'refresh_receipts_required_before_served_basis_change',
    },
  );
}

ReplaySimulationLearningReadiness _buildLearningReadiness({
  required String snapshotEnvironmentId,
  required String cityCode,
  required int replayYear,
  required List<ReplayScenarioPacket> scenarios,
  required List<ReplayScenarioComparison> comparisons,
  required List<SimulationTruthReceipt> receipts,
  required List<ReplayContradictionSnapshot> contradictions,
  required List<ReplayLocalityOverlaySnapshot> localityOverlays,
  required ReplaySimulationAdminFoundationSummary foundation,
}) {
  final hasReceiptsWithTraces = receipts.any(
    (entry) => entry.forecastTraceRefs.isNotEmpty,
  );
  final maxSeverity = contradictions.isEmpty
      ? 0.0
      : contradictions
          .map((entry) => entry.severity)
          .reduce((left, right) => left >= right ? left : right);
  final leadOverlay = localityOverlays.isEmpty ? null : localityOverlays.first;

  final ready = scenarios.isNotEmpty &&
      comparisons.isNotEmpty &&
      hasReceiptsWithTraces &&
      leadOverlay != null &&
      maxSeverity < 0.90;
  final reviewOnly = scenarios.isNotEmpty &&
      comparisons.isNotEmpty &&
      receipts.isNotEmpty &&
      localityOverlays.isNotEmpty;

  final reasons = <String>[
    if (foundation.intakeFlowRefs.isNotEmpty)
      'Simulation basis includes generic intake/orchestration refs: ${foundation.intakeFlowRefs.join(', ')}.',
    if (foundation.sidecarRefs.isNotEmpty)
      'Sidecars shaping this simulation: ${foundation.sidecarRefs.join(', ')}.',
    if (hasReceiptsWithTraces)
      'Truth receipts carry forecast trace refs and bounded contradiction summaries.'
    else
      'Truth receipts are present but forecast trace coverage is incomplete.',
    if (leadOverlay != null)
      'Highest-attention locality is ${leadOverlay.displayName} with ${leadOverlay.contradictionCount} contradictions and sensitivity ${leadOverlay.branchSensitivity.toStringAsFixed(2)}.',
    if (maxSeverity >= 0.90)
      'At least one contradiction remains too severe for direct reality-model sharing.'
    else if (contradictions.isNotEmpty)
      'Contradictions are bounded enough to package as admin-reviewed evidence.',
  ];

  final requestPreviews = _buildRealityModelRequestPreviews(
    environmentId: snapshotEnvironmentId,
    cityCode: cityCode,
    replayYear: replayYear,
    scenarios: scenarios,
    receipts: receipts,
    localityOverlays: localityOverlays,
  );

  return ReplaySimulationLearningReadiness(
    trainingGrade: ready
        ? 'strong'
        : reviewOnly
            ? 'review'
            : 'insufficient',
    shareWithRealityModelAllowed: ready,
    reasons: reasons,
    suggestedTrainingUse: ready
        ? 'candidate_deeper_reality_model_training'
        : reviewOnly
            ? 'evaluation_and_kernel_gap_review'
            : 'simulation_debug_only',
    requestPreviews: requestPreviews,
    metadata: <String, dynamic>{
      'maxContradictionSeverity': maxSeverity,
      'receiptCount': receipts.length,
      'activeKernelCount': foundation.activeKernelCount,
      'scenarioCount': scenarios.length,
    },
  );
}

ReplaySimulationSyntheticHumanKernelExplorer
    _buildSyntheticHumanKernelExplorer({
  required ReplaySimulationAdminEnvironmentDescriptor descriptor,
  required List<ReplayScenarioPacket> scenarios,
  required List<ReplayScenarioComparison> comparisons,
  required List<SimulationTruthReceipt> receipts,
  required List<ReplayContradictionSnapshot> contradictions,
  required List<ReplayLocalityOverlaySnapshot> localityOverlays,
  required ReplaySimulationAdminFoundationSummary foundation,
}) {
  final requiredKernelIds = foundation.kernelStates
      .map((entry) => entry.kernelId)
      .toList(growable: false);
  final attachedKernelIds = foundation.kernelStates
      .where((entry) => entry.status != 'missing')
      .map((entry) => entry.kernelId)
      .toList(growable: false);
  final readyKernelIds = foundation.kernelStates
      .where((entry) => entry.status == 'active')
      .map((entry) => entry.kernelId)
      .toList(growable: false);
  final comparisonsByScenarioId = <String, ReplayScenarioComparison>{
    for (final comparison in comparisons) comparison.scenarioId: comparison,
  };
  final contradictionsByLocality =
      <String, List<ReplayContradictionSnapshot>>{};
  for (final contradiction in contradictions) {
    contradictionsByLocality.putIfAbsent(
      contradiction.localityCode,
      () => <ReplayContradictionSnapshot>[],
    );
    contradictionsByLocality[contradiction.localityCode]!.add(contradiction);
  }
  final overlaysByLocality = <String, ReplayLocalityOverlaySnapshot>{
    for (final overlay in localityOverlays) overlay.localityCode: overlay,
  };
  final localityCodes = <String>{
    ...localityOverlays.map((entry) => entry.localityCode),
    for (final scenario in scenarios) ...scenario.seedLocalityCodes,
  }.toList(growable: false)
    ..sort();
  final effectiveLocalities = localityCodes.isEmpty
      ? <String>['${descriptor.cityCode}_core']
      : localityCodes.take(5).toList(growable: false);

  final entries = effectiveLocalities.map((localityCode) {
    final overlay = overlaysByLocality[localityCode];
    final localityScenarios = scenarios
        .where((scenario) => scenario.seedLocalityCodes.contains(localityCode))
        .toList(growable: false);
    final localityComparisons = localityScenarios
        .map((scenario) => comparisonsByScenarioId[scenario.scenarioId])
        .whereType<ReplayScenarioComparison>()
        .toList(growable: false);
    final localityContradictions = contradictionsByLocality[localityCode] ??
        const <ReplayContradictionSnapshot>[];
    final expectedQuestionCount = localityScenarios.fold<int>(
      0,
      (sum, scenario) => sum + scenario.expectedQuestions.length,
    );
    final entityRefCount = localityScenarios.fold<int>(
      0,
      (sum, scenario) => sum + scenario.seedEntityRefs.length,
    );
    final branchCount = localityComparisons.fold<int>(
      0,
      (sum, comparison) => sum + comparison.branchDiffs.length,
    );
    final localityScenarioNames = localityScenarios
        .map((scenario) => scenario.name)
        .take(2)
        .toList(growable: false);
    final whereCount = ((overlay?.branchSensitivity ?? 0.0) * 10).round() +
        (overlay?.primarySignals.length ?? 0) +
        (localityScenarios.isEmpty ? 0 : 1);
    final whyCount = localityContradictions.length + (receipts.isEmpty ? 0 : 1);
    final governanceCount = localityContradictions.length + receipts.length;
    final higherAgentGuidanceCount = localityContradictions.length +
        ((overlay?.attentionBand == 'escalate') ? 2 : 1);
    final activationCountByKernel = <String, int>{
      'when': localityScenarios.isEmpty ? 0 : receipts.length,
      'where': whereCount <= 0 ? 1 : whereCount,
      'what': entityRefCount <= 0 ? localityScenarios.length : entityRefCount,
      'who': expectedQuestionCount,
      'why': whyCount,
      'how': branchCount,
      'forecast': localityScenarios.isEmpty
          ? 0
          : (branchCount <= 0 ? localityScenarios.length : branchCount),
      'governance': governanceCount,
      'higher_agent_truth': higherAgentGuidanceCount,
    };
    final displayName = overlay?.displayName ?? localityCode;
    final missingKernelIds = requiredKernelIds
        .where((kernelId) => !attachedKernelIds.contains(kernelId))
        .toList(growable: false);
    final notReadyKernelIds = attachedKernelIds
        .where((kernelId) => !readyKernelIds.contains(kernelId))
        .toList(growable: false);
    final summary = localityContradictions.isEmpty &&
            (overlay?.branchSensitivity ?? 0.0) < 0.25
        ? '$displayName is a relatively stable representative synthetic-human lane.'
        : '$displayName still carries bounded locality distortion or contradiction pressure.';
    return ReplaySimulationSyntheticHumanKernelEntry(
      actorId: 'synthetic-human:${descriptor.cityCode}:$localityCode',
      displayName: 'Representative $displayName lane',
      localityAnchor: localityCode,
      attachedKernelIds: attachedKernelIds,
      readyKernelIds: readyKernelIds,
      missingKernelIds: missingKernelIds,
      notReadyKernelIds: notReadyKernelIds,
      activationCountByKernel: activationCountByKernel,
      higherAgentGuidanceCount: higherAgentGuidanceCount,
      summary: summary,
      traceSummary: <String>[
        if (localityScenarioNames.isNotEmpty)
          'Scenario seeds: ${localityScenarioNames.join(' • ')}',
        'Contradictions: ${localityContradictions.length} • Receipts: ${receipts.length} • Branch diffs: $branchCount',
        'Branch sensitivity: ${((overlay?.branchSensitivity ?? 0.0) * 100).toStringAsFixed(0)}% • Attention: ${overlay?.attentionBand ?? 'watch'}',
      ],
      metadata: <String, dynamic>{
        'displayLocalityName': displayName,
        'pressureBand': overlay?.pressureBand ?? 'unknown',
        'attentionBand': overlay?.attentionBand ?? 'watch',
        'representedPopulationKind': 'representative_synthetic_human_lane',
      },
    );
  }).toList(growable: false);

  final actorsWithFullBundle = entries
      .where(
        (entry) => entry.readyKernelIds.toSet().containsAll(requiredKernelIds),
      )
      .length;

  return ReplaySimulationSyntheticHumanKernelExplorer(
    requiredKernelIds: requiredKernelIds,
    modeledActorCount: entries.length,
    actorsWithFullBundle: actorsWithFullBundle,
    summary:
        'Representative synthetic-human lanes are derived from current simulation locality, contradiction, and kernel-participation signals so realism gaps are visible before any training handoff.',
    entries: entries,
  );
}

ReplaySimulationLocalityHierarchyHealth _buildLocalityHierarchyHealth({
  required ReplaySimulationAdminEnvironmentDescriptor descriptor,
  required List<ReplayScenarioPacket> scenarios,
  required List<ReplayLocalityOverlaySnapshot> localityOverlays,
}) {
  final nodes = localityOverlays.map((overlay) {
    final localityScenarios = scenarios
        .where((scenario) =>
            scenario.seedLocalityCodes.contains(overlay.localityCode))
        .toList(growable: false);
    final scenarioNames = localityScenarios
        .map((scenario) => scenario.name)
        .take(2)
        .toList(growable: false);
    final effectiveness = overlay.contradictionCount == 0 &&
            overlay.branchSensitivity < 0.18
        ? 'stable'
        : overlay.contradictionCount <= 1 && overlay.branchSensitivity < 0.32
            ? 'bounded'
            : overlay.attentionBand == 'escalate' ||
                    overlay.contradictionCount >= 2 ||
                    overlay.branchSensitivity >= 0.40
                ? 'stressed'
                : 'mixed';
    final risk = overlay.attentionBand == 'escalate' ||
            overlay.branchSensitivity >= 0.45
        ? 'high'
        : overlay.contradictionCount > 0 || overlay.branchSensitivity >= 0.25
            ? 'medium'
            : 'low';
    final summary =
        '${overlay.displayName} is ${effectiveness == 'stressed' ? 'pushing too much hierarchy caution' : 'currently functioning'} with ${overlay.contradictionCount} contradiction(s) and ${overlay.attentionBand} attention.';
    return ReplaySimulationLocalityHierarchyNodeSummary(
      localityCode: overlay.localityCode,
      displayName: overlay.displayName,
      pressureBand: overlay.pressureBand,
      attentionBand: overlay.attentionBand,
      primarySignals: overlay.primarySignals,
      branchSensitivity: overlay.branchSensitivity,
      contradictionCount: overlay.contradictionCount,
      effectiveness: effectiveness,
      risk: risk,
      summary: summary,
      traceSummary: <String>[
        'Branch sensitivity: ${(overlay.branchSensitivity * 100).toStringAsFixed(0)}%',
        'Primary signal count: ${overlay.primarySignals.length}',
        if (scenarioNames.isNotEmpty)
          'Scenario seeds: ${scenarioNames.join(' • ')}',
        'Hierarchy posture: ${risk == 'high' ? 'review-first' : effectiveness == 'stable' ? 'bounded handoff' : 'watch closely'}',
      ],
    );
  }).toList(growable: false)
    ..sort((left, right) {
      final riskDelta = _simulationSeverityRank(right.risk) -
          _simulationSeverityRank(left.risk);
      if (riskDelta != 0) {
        return riskDelta;
      }
      final contradictionDelta =
          right.contradictionCount - left.contradictionCount;
      if (contradictionDelta != 0) {
        return contradictionDelta;
      }
      return right.branchSensitivity.compareTo(left.branchSensitivity);
    });

  if (nodes.isEmpty) {
    return ReplaySimulationLocalityHierarchyHealth(
      summary:
          'No locality hierarchy overlays are recorded yet for ${descriptor.displayName}.',
      nodes: const <ReplaySimulationLocalityHierarchyNodeSummary>[],
    );
  }

  final strongestNode = List<ReplaySimulationLocalityHierarchyNodeSummary>.from(
    nodes,
  )..sort((left, right) {
      final contradictionDelta =
          left.contradictionCount - right.contradictionCount;
      if (contradictionDelta != 0) {
        return contradictionDelta;
      }
      return left.branchSensitivity.compareTo(right.branchSensitivity);
    });
  final stableCount =
      nodes.where((entry) => entry.effectiveness == 'stable').length;
  final escalatingCount = nodes
      .where(
          (entry) => entry.attentionBand == 'escalate' || entry.risk == 'high')
      .length;

  return ReplaySimulationLocalityHierarchyHealth(
    summary:
        '${strongestNode.first.displayName} is currently the cleanest locality lane, while ${nodes.first.displayName} needs the most hierarchy attention.',
    strongestLocalityLabel: strongestNode.first.displayName,
    stressedLocalityLabel: nodes.first.displayName,
    stableLocalityCount: stableCount,
    escalatingLocalityCount: escalatingCount,
    nodes: nodes,
  );
}

ReplaySimulationHigherAgentHandoffView _buildHigherAgentHandoffView({
  required ReplaySimulationAdminEnvironmentDescriptor descriptor,
  required ReplaySimulationLocalityHierarchyHealth localityHierarchyHealth,
  required ReplaySimulationLearningReadiness learningReadiness,
}) {
  if (localityHierarchyHealth.nodes.isEmpty) {
    return ReplaySimulationHigherAgentHandoffView(
      summary:
          'No higher-agent handoff summary is available yet because locality hierarchy signals have not been materialized.',
    );
  }

  final localityItems = localityHierarchyHealth.nodes.take(3).map((node) {
    final status = node.risk == 'high'
        ? 'review_only'
        : node.effectiveness == 'stable'
            ? 'bounded_downward_guidance'
            : 'watch';
    return ReplaySimulationHigherAgentHandoffItem(
      scope: 'locality',
      targetLabel: node.displayName,
      status: status,
      summary: node.risk == 'high'
          ? 'Keep ${node.displayName} inside bounded review until locality contradictions and branch sensitivity fall.'
          : 'Locality handoff for ${node.displayName} is bounded enough to remain visible in higher-agent guidance without treating it as settled truth.',
      guidance: <String>[
        'Primary signals: ${node.primarySignals.isEmpty ? 'none recorded' : node.primarySignals.join(', ')}',
        'Attention band: ${node.attentionBand}',
      ],
      traceSummary: <String>[
        'Locality code: ${node.localityCode}',
        'Risk: ${node.risk} • Effectiveness: ${node.effectiveness}',
        'Contradictions: ${node.contradictionCount} • Branch sensitivity: ${(node.branchSensitivity * 100).toStringAsFixed(0)}%',
      ],
      metadata: <String, dynamic>{
        'localityCode': node.localityCode,
      },
    );
  }).toList(growable: false);

  final cityStatus = localityHierarchyHealth.escalatingLocalityCount > 0
      ? 'bounded_review_before_downward_guidance'
      : 'bounded_downward_guidance';
  return ReplaySimulationHigherAgentHandoffView(
    summary:
        'Higher-agent synthesis for ${descriptor.displayName} is currently ${cityStatus == 'bounded_review_before_downward_guidance' ? 'review-first' : 'bounded and reusable'} based on locality-level pressure and contradiction signals.',
    items: <ReplaySimulationHigherAgentHandoffItem>[
      ...localityItems,
      ReplaySimulationHigherAgentHandoffItem(
        scope: 'city',
        targetLabel: '${descriptor.displayName} city synthesis',
        status: cityStatus,
        summary:
            'The city layer is aggregating ${localityHierarchyHealth.nodes.length} locality lanes, with ${localityHierarchyHealth.escalatingLocalityCount} still demanding explicit review-first handling.',
        guidance: <String>[
          if (localityHierarchyHealth.strongestLocalityLabel != null)
            'Strongest locality lane: ${localityHierarchyHealth.strongestLocalityLabel}',
          if (localityHierarchyHealth.stressedLocalityLabel != null)
            'Most stressed locality lane: ${localityHierarchyHealth.stressedLocalityLabel}',
          'Share-ready posture: ${learningReadiness.shareWithRealityModelAllowed ? 'candidate for bounded review' : 'iteration only'}',
        ],
        traceSummary: <String>[
          'Tracked locality lanes: ${localityHierarchyHealth.nodes.length}',
          'Escalating localities: ${localityHierarchyHealth.escalatingLocalityCount}',
          'Stable localities: ${localityHierarchyHealth.stableLocalityCount}',
        ],
      ),
    ],
  );
}

ReplaySimulationRealismProvenanceSummary _buildRealismProvenanceSummary({
  required ReplaySimulationAdminEnvironmentDescriptor descriptor,
  required ReplaySimulationAdminFoundationSummary foundation,
  required List<ReplayScenarioPacket> scenarios,
  required List<ReplayLocalityOverlaySnapshot> localityOverlays,
}) {
  return ReplaySimulationRealismProvenanceSummary(
    simulationMode: foundation.simulationMode,
    cityPackStructuralRef:
        foundation.metadata['cityPackStructuralRef']?.toString(),
    populationModelKind:
        foundation.metadata['populationModelKind']?.toString() ??
            (descriptor.simulationMode == 'generic_city_pack'
                ? 'scenario_seeded_synthetic_city'
                : 'replay_native_city'),
    modeledUserLayerKind:
        foundation.metadata['modeledUserLayerKind']?.toString() ??
            'representative_synthetic_human_lanes',
    campaignDefaultsRef: foundation.metadata['campaignDefaultsRef']?.toString(),
    localityExpectationProfileRef:
        foundation.metadata['localityExpectationProfileRef']?.toString(),
    worldHealthProfileRef:
        foundation.metadata['worldHealthProfileRef']?.toString(),
    intakeFlowRefs: foundation.intakeFlowRefs,
    sidecarRefs: foundation.sidecarRefs,
    trainingArtifactFamilies: foundation.trainingArtifactFamilies,
    metadata: <String, dynamic>{
      'scenarioCount': scenarios.length,
      'overlayCount': localityOverlays.length,
    },
  );
}

List<ReplaySimulationWeakSpotSummary> _buildWeakSpotsBeforeTraining({
  required ReplaySimulationAdminFoundationSummary foundation,
  required ReplaySimulationLearningReadiness learningReadiness,
  required ReplaySimulationLocalityHierarchyHealth localityHierarchyHealth,
  required ReplaySimulationRealismProvenanceSummary realismProvenance,
}) {
  final spots = <ReplaySimulationWeakSpotSummary>[];
  for (final kernel in foundation.kernelStates) {
    if (kernel.status == 'active') {
      continue;
    }
    spots.add(
      ReplaySimulationWeakSpotSummary(
        title: 'Kernel gap: ${kernel.kernelId}',
        severity: kernel.status == 'missing' ? 'high' : 'medium',
        summary: kernel.reason,
        recommendedAction: kernel.status == 'missing'
            ? 'Add scenario or sidecar evidence that exercises `${kernel.kernelId}` before bounded review.'
            : 'Promote `${kernel.kernelId}` from derived to active with clearer evidence and operator-visible receipts.',
        metadata: <String, dynamic>{
          'kernelId': kernel.kernelId,
          'status': kernel.status,
        },
      ),
    );
  }
  for (final node in localityHierarchyHealth.nodes.take(2)) {
    if (node.risk == 'low') {
      continue;
    }
    spots.add(
      ReplaySimulationWeakSpotSummary(
        title: 'Locality stress: ${node.displayName}',
        severity: node.risk == 'high' ? 'high' : 'medium',
        summary:
            '${node.displayName} has ${node.contradictionCount} contradiction(s), ${node.attentionBand} attention, and ${node.pressureBand} pressure.',
        recommendedAction:
            'Iterate ${node.displayName} again before training and reduce hierarchy distortion or contradiction pressure.',
        metadata: <String, dynamic>{
          'localityCode': node.localityCode,
        },
      ),
    );
  }
  if (realismProvenance.sidecarRefs.isEmpty) {
    spots.add(
      const ReplaySimulationWeakSpotSummary(
        title: 'Realism provenance gap',
        severity: 'medium',
        summary:
            'No sidecar refs are recorded for this simulation basis, so realism provenance is incomplete.',
        recommendedAction:
            'Attach and preserve realism-pack or city-pack sidecars before bounded review.',
      ),
    );
  }
  if (!learningReadiness.shareWithRealityModelAllowed &&
      learningReadiness.reasons.isNotEmpty) {
    spots.add(
      ReplaySimulationWeakSpotSummary(
        title: 'Training gate still closed',
        severity: 'high',
        summary: learningReadiness.reasons.first,
        recommendedAction:
            'Resolve the strongest readiness blocker before promoting this lane toward bounded review or training.',
      ),
    );
  }

  spots.sort((left, right) {
    final severityDelta = _simulationSeverityRank(right.severity) -
        _simulationSeverityRank(left.severity);
    if (severityDelta != 0) {
      return severityDelta;
    }
    return left.title.compareTo(right.title);
  });
  return spots.take(6).toList(growable: false);
}

int _simulationSeverityRank(String severity) {
  return switch (severity) {
    'critical' => 4,
    'high' => 3,
    'medium' => 2,
    'low' => 1,
    _ => 0,
  };
}

List<ReplaySimulationRealityModelRequestPreview>
    _buildRealityModelRequestPreviews({
  required String environmentId,
  required String cityCode,
  required int replayYear,
  required List<ReplayScenarioPacket> scenarios,
  required List<SimulationTruthReceipt> receipts,
  required List<ReplayLocalityOverlaySnapshot> localityOverlays,
}) {
  final previews = <ReplaySimulationRealityModelRequestPreview>[];
  final seenRequestIds = <String>{};
  final leadScenario = scenarios.isEmpty ? null : scenarios.first;
  final leadReceipt = receipts.isEmpty ? null : receipts.first;
  final leadOverlay = localityOverlays.isEmpty ? null : localityOverlays.first;
  final strongestScenario = scenarios.isEmpty
      ? null
      : (scenarios.toList(growable: false)
            ..sort(
              (left, right) => right.seedEntityRefs.length.compareTo(
                left.seedEntityRefs.length,
              ),
            ))
          .first;
  final primaryLocalityCode = leadOverlay?.localityCode ??
      (leadScenario?.seedLocalityCodes.isNotEmpty == true
          ? leadScenario!.seedLocalityCodes.first
          : '');

  void addPreview({
    required String requestId,
    required String subjectId,
    required RealityModelDomain domain,
    required String candidateRef,
    required List<String> signalTags,
    required List<String> evidenceRefs,
    required String rationale,
    String localityCode = '',
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    if (!seenRequestIds.add(requestId)) {
      return;
    }
    previews.add(
      ReplaySimulationRealityModelRequestPreview(
        request: RealityModelEvaluationRequest(
          requestId: requestId,
          subjectId: subjectId,
          domain: domain,
          candidateRef: candidateRef,
          localityCode: localityCode,
          cityCode: cityCode,
          signalTags: signalTags,
          evidenceRefs: evidenceRefs,
          requestedAtUtc: DateTime.now().toUtc(),
          metadata: <String, dynamic>{
            'sourceEnvironmentId': environmentId,
            ...metadata,
          },
        ),
        rationale: rationale,
      ),
    );
  }

  if (leadOverlay != null) {
    addPreview(
      requestId:
          'sim-share:$environmentId:locality:${leadOverlay.localityCode}',
      subjectId: 'simulation:${leadOverlay.localityCode}',
      domain: RealityModelDomain.locality,
      candidateRef: 'locality:${leadOverlay.localityCode}',
      localityCode: leadOverlay.localityCode,
      signalTags: <String>[
        'simulation_bundle',
        'locality_overlay',
        'replay_$replayYear',
        leadOverlay.attentionBand,
      ],
      evidenceRefs: <String>[
        'simulation_snapshot.json#overlay:${leadOverlay.localityCode}',
        if (leadReceipt != null)
          'simulation_snapshot.json#receipt:${leadReceipt.receiptId}',
      ],
      metadata: const <String, dynamic>{
        'suggestedUse': 'locality_prior_review',
      },
      rationale:
          'Uses the highest-attention locality overlay as a bounded reality-model evidence candidate.',
    );
    addPreview(
      requestId: 'sim-share:$environmentId:place:${leadOverlay.localityCode}',
      subjectId: 'simulation_place:${leadOverlay.localityCode}',
      domain: RealityModelDomain.place,
      candidateRef: 'place:${leadOverlay.localityCode}_anchor',
      localityCode: leadOverlay.localityCode,
      signalTags: <String>[
        'simulation_bundle',
        'place_anchor',
        'locality_overlay',
        'replay_$replayYear',
      ],
      evidenceRefs: <String>[
        'simulation_snapshot.json#overlay:${leadOverlay.localityCode}',
        if (leadScenario != null)
          'simulation_snapshot.json#scenario:${leadScenario.scenarioId}',
      ],
      metadata: const <String, dynamic>{
        'suggestedUse': 'place_context_review',
      },
      rationale:
          'Derives a place-level review seed from the highest-attention locality so the reality model can learn place context before lower-tier propagation.',
    );
  }

  if (leadScenario != null) {
    final candidateRef = leadScenario.seedEntityRefs.isNotEmpty
        ? leadScenario.seedEntityRefs.first
        : 'scenario:${leadScenario.scenarioId}';
    final domain = candidateRef.startsWith('event:')
        ? RealityModelDomain.event
        : candidateRef.startsWith('community:')
            ? RealityModelDomain.community
            : candidateRef.startsWith('business:')
                ? RealityModelDomain.business
                : candidateRef.startsWith('locality:')
                    ? RealityModelDomain.locality
                    : RealityModelDomain.place;
    addPreview(
      requestId: 'sim-share:$environmentId:scenario:${leadScenario.scenarioId}',
      subjectId: candidateRef,
      domain: domain,
      candidateRef: candidateRef,
      localityCode: leadScenario.seedLocalityCodes.isEmpty
          ? ''
          : leadScenario.seedLocalityCodes.first,
      signalTags: <String>[
        'simulation_bundle',
        'scenario_packet',
        leadScenario.scenarioKind.name,
        'replay_$replayYear',
      ],
      evidenceRefs: <String>[
        'simulation_snapshot.json#scenario:${leadScenario.scenarioId}',
        if (leadReceipt != null)
          'simulation_snapshot.json#receipt:${leadReceipt.receiptId}',
      ],
      metadata: const <String, dynamic>{
        'suggestedUse': 'simulation_candidate_training',
      },
      rationale:
          'Packages the lead scenario as a bounded candidate for reality-model comparison or training review.',
    );
  }

  if (strongestScenario != null) {
    addPreview(
      requestId: 'sim-share:$environmentId:community:$cityCode',
      subjectId: 'simulation_community:$cityCode',
      domain: RealityModelDomain.community,
      candidateRef: 'community:${cityCode}_coordination_mesh',
      localityCode: primaryLocalityCode,
      signalTags: <String>[
        'simulation_bundle',
        'community_coordination',
        strongestScenario.scenarioKind.name,
        'replay_$replayYear',
      ],
      evidenceRefs: <String>[
        'simulation_snapshot.json#scenario:${strongestScenario.scenarioId}',
        if (leadReceipt != null)
          'simulation_snapshot.json#receipt:${leadReceipt.receiptId}',
      ],
      metadata: const <String, dynamic>{
        'suggestedUse': 'community_synthesis_review',
      },
      rationale:
          'Turns the strongest multi-locality scenario into a governed community-level review seed so the reality model can synthesize shared coordination behavior.',
    );
    addPreview(
      requestId: 'sim-share:$environmentId:business:$cityCode',
      subjectId: 'simulation_business:$cityCode',
      domain: RealityModelDomain.business,
      candidateRef: 'business:${cityCode}_economic_corridor',
      localityCode: primaryLocalityCode,
      signalTags: <String>[
        'simulation_bundle',
        'business_corridor',
        strongestScenario.scenarioKind.name,
        'replay_$replayYear',
      ],
      evidenceRefs: <String>[
        'simulation_snapshot.json#scenario:${strongestScenario.scenarioId}',
        if (leadOverlay != null)
          'simulation_snapshot.json#overlay:${leadOverlay.localityCode}',
      ],
      metadata: const <String, dynamic>{
        'suggestedUse': 'business_pressure_review',
      },
      rationale:
          'Uses the strongest scenario to create a bounded business-level review seed for corridor pressure, operator demand, and downstream economic reasoning.',
    );
    addPreview(
      requestId: 'sim-share:$environmentId:list:$cityCode',
      subjectId: 'simulation_list:$cityCode',
      domain: RealityModelDomain.list,
      candidateRef: 'list:${cityCode}_priority_watchlist',
      localityCode: primaryLocalityCode,
      signalTags: <String>[
        'simulation_bundle',
        'priority_watchlist',
        'replay_$replayYear',
      ],
      evidenceRefs: <String>[
        'simulation_snapshot.json#scenario:${strongestScenario.scenarioId}',
        if (leadReceipt != null)
          'simulation_snapshot.json#receipt:${leadReceipt.receiptId}',
      ],
      metadata: const <String, dynamic>{
        'suggestedUse': 'list_priority_review',
      },
      rationale:
          'Packages the strongest simulation evidence into a bounded list-level review seed so prioritized downstream candidate sets stay tied to the reality-model outcome.',
    );
  }

  return previews;
}

class ReplaySimulationAdminService {
  ReplaySimulationAdminService({
    Iterable<ReplaySimulationAdminEnvironmentAdapter>? environmentAdapters,
    String? defaultEnvironmentId,
    BhamEventScenarioPackService? scenarioPackService,
    BhamReplayScenarioPacketService? scenarioPacketService,
    BhamReplayScenarioComparisonService? scenarioComparisonService,
    BhamReplayTruthReceiptService? truthReceiptService,
    BhamReplayContradictionDashboardService? contradictionDashboardService,
    BhamReplayLocalityOverlayService? localityOverlayService,
    RealityModelPort? realityModelPort,
    UniversalIntakeRepository? intakeRepository,
    GovernedUpwardLearningIntakeService? governedUpwardLearningIntakeService,
    DateTime Function()? nowProvider,
    Future<Directory> Function()? documentsDirectoryProvider,
  })  : _environmentAdapters = _buildEnvironmentAdapterMap(
          environmentAdapters ??
              <ReplaySimulationAdminEnvironmentAdapter>[
                BhamReplaySimulationAdminEnvironmentAdapter(
                  scenarioPackService: scenarioPackService,
                  scenarioPacketService: scenarioPacketService,
                  scenarioComparisonService: scenarioComparisonService,
                  truthReceiptService: truthReceiptService,
                  contradictionDashboardService: contradictionDashboardService,
                  localityOverlayService: localityOverlayService,
                ),
              ],
        ),
        _defaultEnvironmentId = defaultEnvironmentId,
        _realityModelPort = realityModelPort ?? DefaultRealityModelPort(),
        _intakeRepository = intakeRepository,
        _governedUpwardLearningIntakeService =
            governedUpwardLearningIntakeService ??
                (GetIt.I.isRegistered<GovernedUpwardLearningIntakeService>()
                    ? GetIt.I<GovernedUpwardLearningIntakeService>()
                    : null),
        _nowProvider = nowProvider ?? (() => DateTime.now().toUtc()),
        _documentsDirectoryProvider =
            documentsDirectoryProvider ?? getApplicationDocumentsDirectory;

  final Map<String, ReplaySimulationAdminEnvironmentAdapter>
      _environmentAdapters;
  final String? _defaultEnvironmentId;
  final RealityModelPort _realityModelPort;
  final UniversalIntakeRepository? _intakeRepository;
  final GovernedUpwardLearningIntakeService?
      _governedUpwardLearningIntakeService;
  final DateTime Function() _nowProvider;
  final Future<Directory> Function() _documentsDirectoryProvider;

  List<ReplaySimulationAdminEnvironmentDescriptor> listEnvironments() {
    final descriptors = _environmentAdapters.values
        .map((adapter) => adapter.descriptor)
        .toList(growable: false)
      ..sort(
        (left, right) => left.environmentId.compareTo(right.environmentId),
      );
    return descriptors;
  }

  Future<List<ReplaySimulationAdminEnvironmentDescriptor>>
      listAvailableEnvironments() async {
    final descriptors = <String, ReplaySimulationAdminEnvironmentDescriptor>{
      for (final descriptor in listEnvironments())
        descriptor.environmentId: descriptor,
    };
    for (final registration in await listRegisteredLabEnvironments()) {
      descriptors.putIfAbsent(
        registration.environmentId,
        () => registration.descriptor,
      );
    }
    final merged = descriptors.values.toList(growable: false)
      ..sort(
        (left, right) => left.environmentId.compareTo(right.environmentId),
      );
    return merged;
  }

  Future<List<ReplaySimulationLabEnvironmentRegistration>>
      listRegisteredLabEnvironments() async {
    final root = await _registeredEnvironmentParentDirectory();
    if (!root.existsSync()) {
      return const <ReplaySimulationLabEnvironmentRegistration>[];
    }
    final registrations = <ReplaySimulationLabEnvironmentRegistration>[];
    for (final entry in root.listSync(followLinks: false)) {
      if (entry is! Directory) {
        continue;
      }
      final file = File(path.join(entry.path, 'environment_registration.json'));
      if (!file.existsSync()) {
        continue;
      }
      try {
        final raw = file.readAsStringSync().trim();
        if (raw.isEmpty) {
          continue;
        }
        registrations.add(
          ReplaySimulationLabEnvironmentRegistration.fromJson(
            Map<String, dynamic>.from(jsonDecode(raw) as Map<String, dynamic>),
          ),
        );
      } on FormatException {
        continue;
      }
    }
    registrations.sort(
      (left, right) => left.environmentId.compareTo(right.environmentId),
    );
    return registrations;
  }

  Map<String, String> _defaultLatestStateEvidenceRefsByFamily(
    String relativeRoot,
  ) {
    return <String, String>{
      'app_observations':
          '$relativeRoot/latest_state/app_observations.seed.json',
      'runtime_os_locality_state':
          '$relativeRoot/latest_state/runtime_os_locality_state.seed.json',
      'governed_reality_model_outputs':
          '$relativeRoot/latest_state/governed_reality_model_outputs.seed.json',
    };
  }

  String _latestStateEvidenceSeedFileName(String family) {
    switch (family) {
      case 'app_observations':
        return 'app_observations.seed.json';
      case 'runtime_os_locality_state':
        return 'runtime_os_locality_state.seed.json';
      case 'governed_reality_model_outputs':
        return 'governed_reality_model_outputs.seed.json';
      default:
        return '${family.trim()}.seed.json';
    }
  }

  String _latestStateEvidenceCurrentFileName(String family) {
    switch (family) {
      case 'app_observations':
        return 'app_observations.current.json';
      case 'runtime_os_locality_state':
        return 'runtime_os_locality_state.current.json';
      case 'governed_reality_model_outputs':
        return 'governed_reality_model_outputs.current.json';
      default:
        return '${family.trim()}.current.json';
    }
  }

  double _latestStateEvidenceFreshnessHours(
    Map<String, dynamic> payload,
  ) {
    final numeric = payload['freshnessHours'];
    if (numeric is num) {
      return numeric.toDouble();
    }
    final parsed =
        double.tryParse((payload['freshnessHours'] ?? '').toString());
    if (parsed != null) {
      return parsed;
    }
    return double.infinity;
  }

  double _latestStateEvidenceStrengthScore(
    Map<String, dynamic> payload,
  ) {
    final numeric = payload['strengthScore'];
    if (numeric is num) {
      return numeric.toDouble().clamp(0.0, 1.0);
    }
    final parsed = double.tryParse((payload['strengthScore'] ?? '').toString());
    if (parsed != null) {
      return parsed.clamp(0.0, 1.0);
    }
    return 0.0;
  }

  _ReplaySimulationLatestStateRefreshPolicy
      _latestStateRefreshPolicyForSupportedPlace(
    String supportedPlaceRef,
  ) {
    switch (supportedPlaceRef.trim()) {
      case 'place:atx':
        return const _ReplaySimulationLatestStateRefreshPolicy(
          supportedPlaceRef: 'place:atx',
          refreshCadenceHours: 12,
          freshnessThresholdHoursByFamily: <String, double>{
            'app_observations': 8,
            'runtime_os_locality_state': 8,
            'governed_reality_model_outputs': 18,
          },
          strengthThresholdByFamily: <String, double>{
            'app_observations': 0.74,
            'runtime_os_locality_state': 0.80,
            'governed_reality_model_outputs': 0.72,
          },
        );
      case 'place:sav':
        return const _ReplaySimulationLatestStateRefreshPolicy(
          supportedPlaceRef: 'place:sav',
          refreshCadenceHours: 18,
          freshnessThresholdHoursByFamily: <String, double>{
            'app_observations': 12,
            'runtime_os_locality_state': 10,
            'governed_reality_model_outputs': 24,
          },
          strengthThresholdByFamily: <String, double>{
            'app_observations': 0.72,
            'runtime_os_locality_state': 0.78,
            'governed_reality_model_outputs': 0.70,
          },
        );
      default:
        return _ReplaySimulationLatestStateRefreshPolicy(
          supportedPlaceRef: supportedPlaceRef,
          refreshCadenceHours: 24,
          freshnessThresholdHoursByFamily: const <String, double>{
            'app_observations': 18,
            'runtime_os_locality_state': 12,
            'governed_reality_model_outputs': 30,
          },
          strengthThresholdByFamily: const <String, double>{
            'app_observations': 0.70,
            'runtime_os_locality_state': 0.75,
            'governed_reality_model_outputs': 0.68,
          },
        );
    }
  }

  String _latestStateRefreshCadenceStatus({
    required int refreshCadenceHours,
    required DateTime? referenceAt,
  }) {
    if (referenceAt == null) {
      return 'awaiting_first_refresh_receipts';
    }
    final elapsedHours =
        _nowProvider().toUtc().difference(referenceAt.toUtc()).inMinutes / 60.0;
    if (elapsedHours > refreshCadenceHours * 2) {
      return 'overdue_for_refresh';
    }
    if (elapsedHours > refreshCadenceHours) {
      return 'due_for_refresh';
    }
    return 'within_refresh_window';
  }

  String _latestStateEvidenceAgingStatus({
    required String selectionStatus,
    required double freshnessHours,
    required double policyFreshnessThresholdHours,
    required bool receiptBacked,
  }) {
    if (selectionStatus == 'seed_placeholder') {
      return 'seed_placeholder_active';
    }
    final effectiveThreshold = policyFreshnessThresholdHours <= 0
        ? 1.0
        : policyFreshnessThresholdHours;
    final freshnessRatio = freshnessHours.isFinite
        ? freshnessHours / effectiveThreshold
        : double.infinity;
    if (freshnessRatio <= 0.5) {
      return receiptBacked
          ? 'within_policy_window'
          : 'within_policy_window_not_receipt_backed';
    }
    if (freshnessRatio <= 1.0) {
      return receiptBacked
          ? 'approaching_policy_edge'
          : 'approaching_policy_edge_not_receipt_backed';
    }
    return receiptBacked
        ? 'past_policy_window_receipt_backed'
        : 'past_policy_window_not_receipt_backed';
  }

  String _latestStateEvidenceAgingSummary({
    required String family,
    required String status,
    required double freshnessHours,
    required double policyFreshnessThresholdHours,
    required bool receiptBacked,
    required String supportedPlaceRef,
  }) {
    final familyLabel = _describeHydrationEvidenceFamily(family);
    final freshnessLabel = freshnessHours.isFinite
        ? '${freshnessHours.toStringAsFixed(freshnessHours >= 100 ? 0 : 1)}h'
        : 'unknown freshness';
    final policyFreshnessLabel =
        '${policyFreshnessThresholdHours.toStringAsFixed(0)}h';
    switch (status) {
      case 'seed_placeholder_active':
        return '$familyLabel: seed placeholder still active against the $policyFreshnessLabel policy window for $supportedPlaceRef.';
      case 'within_policy_window':
        return '$familyLabel: within policy window at $freshnessLabel of $policyFreshnessLabel and receipt-backed.';
      case 'within_policy_window_not_receipt_backed':
        return '$familyLabel: within policy window at $freshnessLabel of $policyFreshnessLabel but not receipt-backed yet.';
      case 'approaching_policy_edge':
        return '$familyLabel: approaching the $policyFreshnessLabel policy edge at $freshnessLabel and still receipt-backed.';
      case 'approaching_policy_edge_not_receipt_backed':
        return '$familyLabel: approaching the $policyFreshnessLabel policy edge at $freshnessLabel and not receipt-backed.';
      case 'past_policy_window_receipt_backed':
        return '$familyLabel: past the $policyFreshnessLabel policy window at $freshnessLabel, but still receipt-backed.';
      case 'past_policy_window_not_receipt_backed':
        return '$familyLabel: past the $policyFreshnessLabel policy window at $freshnessLabel and not receipt-backed.';
      default:
        final receiptLabel =
            receiptBacked ? 'receipt-backed' : 'not receipt-backed';
        return '$familyLabel: ${_describeLatestStateEvidenceAgingStatus(status)} at $freshnessLabel of $policyFreshnessLabel ($receiptLabel).';
    }
  }

  String _latestStateEvidenceAgingTrend({
    required String? previousTrend,
    required String transition,
    required String agingStatus,
  }) {
    final degraded = transition == 'aged_beyond_policy_window' ||
        transition == 'degraded_from_receipt_backed_current';
    final refreshed = transition == 'refreshed_with_newer_evidence';
    final carried = transition == 'carried_forward_without_improvement';
    final stable = agingStatus == 'within_policy_window' ||
        agingStatus == 'within_policy_window_not_receipt_backed';
    final nearEdge = agingStatus == 'approaching_policy_edge' ||
        agingStatus == 'approaching_policy_edge_not_receipt_backed';

    if (refreshed && stable) {
      if (previousTrend == 'degrading_without_newer_evidence' ||
          previousTrend == 'repeatedly_degrading') {
        return 'recovered_after_degradation';
      }
      return 'stable_with_recent_refresh';
    }
    if (degraded ||
        (carried &&
            (nearEdge ||
                agingStatus == 'past_policy_window_receipt_backed' ||
                agingStatus == 'past_policy_window_not_receipt_backed'))) {
      if (previousTrend == 'degrading_without_newer_evidence' ||
          previousTrend == 'repeatedly_degrading') {
        return 'repeatedly_degrading';
      }
      return 'degrading_without_newer_evidence';
    }
    if (carried && stable) {
      return 'stable_but_carried_forward';
    }
    if (refreshed) {
      return 'stable_with_recent_refresh';
    }
    return previousTrend ?? 'awaiting_first_refresh_transition';
  }

  String _latestStateEvidenceAgingTrendSummary({
    required String family,
    required String trend,
    required String transition,
    required String agingStatus,
  }) {
    final familyLabel = _describeHydrationEvidenceFamily(family);
    switch (trend) {
      case 'stable_with_recent_refresh':
        return '$familyLabel: recent cadence checks refreshed this family and it remains ${_describeLatestStateEvidenceAgingStatus(agingStatus)}.';
      case 'stable_but_carried_forward':
        return '$familyLabel: recent cadence checks kept carrying this family forward without newer evidence, but it is still ${_describeLatestStateEvidenceAgingStatus(agingStatus)}.';
      case 'degrading_without_newer_evidence':
        return '$familyLabel: this family is drifting under cadence checks because it last ${_describeLivingCityPackMetadata(transition)} and is now ${_describeLatestStateEvidenceAgingStatus(agingStatus)}.';
      case 'repeatedly_degrading':
        return '$familyLabel: this family has repeatedly degraded across cadence checks and is now ${_describeLatestStateEvidenceAgingStatus(agingStatus)}.';
      case 'recovered_after_degradation':
        return '$familyLabel: this family recovered after degradation because newer evidence arrived and it is now ${_describeLatestStateEvidenceAgingStatus(agingStatus)}.';
      default:
        return '$familyLabel: ${_describeLatestStateEvidenceAgingTrend(trend)} after ${_describeLivingCityPackMetadata(transition)}.';
    }
  }

  String _latestStateEvidencePolicyAction({
    required String trend,
    required String agingStatus,
  }) {
    if (trend == 'repeatedly_degrading' ||
        agingStatus == 'past_policy_window_not_receipt_backed') {
      return 'block_served_basis_recovery_for_family';
    }
    if (agingStatus == 'seed_placeholder_active' ||
        agingStatus == 'past_policy_window_receipt_backed') {
      return 'force_restaged_family_inputs';
    }
    if (trend == 'degrading_without_newer_evidence' ||
        trend == 'recovered_after_degradation' ||
        agingStatus == 'approaching_policy_edge' ||
        agingStatus == 'approaching_policy_edge_not_receipt_backed') {
      return 'watch_family_closely';
    }
    return 'no_action_family_stable';
  }

  String _latestStateEvidencePolicyActionSummary({
    required String family,
    required String action,
    required String trend,
    required String agingStatus,
  }) {
    final familyLabel = _describeHydrationEvidenceFamily(family);
    switch (action) {
      case 'no_action_family_stable':
        return '$familyLabel: no policy action required because this family is ${_describeLatestStateEvidenceAgingTrend(trend)} and remains ${_describeLatestStateEvidenceAgingStatus(agingStatus)}.';
      case 'watch_family_closely':
        return '$familyLabel: watch this family closely because it is ${_describeLatestStateEvidenceAgingTrend(trend)} and is now ${_describeLatestStateEvidenceAgingStatus(agingStatus)}.';
      case 'force_restaged_family_inputs':
        return '$familyLabel: force restaged inputs for this family before the next promotion review because it is ${_describeLatestStateEvidenceAgingStatus(agingStatus)}.';
      case 'block_served_basis_recovery_for_family':
        return '$familyLabel: block served-basis recovery until this family is restaged because it is ${_describeLatestStateEvidenceAgingTrend(trend)} and now ${_describeLatestStateEvidenceAgingStatus(agingStatus)}.';
      default:
        return '$familyLabel: ${_describeLatestStateEvidencePolicyAction(action)} because it is ${_describeLatestStateEvidenceAgingTrend(trend)}.';
    }
  }

  List<String> _latestStatePolicyActionBlockedReasons({
    required Map<String, String> actionsByFamily,
  }) {
    final reasons = <String>[];
    for (final entry in actionsByFamily.entries) {
      final familyLabel = _describeHydrationEvidenceFamily(entry.key);
      switch (entry.value) {
        case 'force_restaged_family_inputs':
          reasons.add(
            '$familyLabel requires restaged family inputs before served-basis review can proceed.',
          );
        case 'block_served_basis_recovery_for_family':
          reasons.add(
            '$familyLabel is repeatedly degrading and blocks served-basis recovery until fresher family inputs are restaged.',
          );
      }
    }
    return reasons;
  }

  String? _latestStateEvidenceRestageTarget({
    required String family,
    required String action,
  }) {
    switch (action) {
      case 'force_restaged_family_inputs':
      case 'block_served_basis_recovery_for_family':
        return 'restage_input_family:$family';
      default:
        return null;
    }
  }

  String _latestStateEvidenceRestageTargetSummary({
    required String family,
    required String target,
    required String action,
    required String trend,
    required String agingStatus,
  }) {
    final familyLabel = _describeHydrationEvidenceFamily(family);
    final targetLabel = _describeLatestStateEvidenceRestageTarget(target);
    switch (action) {
      case 'force_restaged_family_inputs':
        return '$familyLabel: route to $targetLabel because this family must be restaged before the next served-basis review while it is ${_describeLatestStateEvidenceAgingStatus(agingStatus)}.';
      case 'block_served_basis_recovery_for_family':
        return '$familyLabel: route to $targetLabel because this family is ${_describeLatestStateEvidenceAgingTrend(trend)} and blocks served-basis recovery until fresher inputs are staged.';
      default:
        return '$familyLabel: route to $targetLabel.';
    }
  }

  Map<String, String> _latestStateEvidenceRestageTargetsForActions({
    required Map<String, String> actionsByFamily,
  }) {
    final targets = <String, String>{};
    for (final entry in actionsByFamily.entries) {
      final target = _latestStateEvidenceRestageTarget(
        family: entry.key,
        action: entry.value,
      );
      if (target != null) {
        targets[entry.key] = target;
      }
    }
    return targets;
  }

  Map<String, String> _latestStateEvidenceRestageTargetSummariesForActions({
    required Map<String, String> actionsByFamily,
    required Map<String, String> trendsByFamily,
    required Map<String, String> agingStatusesByFamily,
  }) {
    final summaries = <String, String>{};
    for (final entry in actionsByFamily.entries) {
      final target = _latestStateEvidenceRestageTarget(
        family: entry.key,
        action: entry.value,
      );
      if (target == null) {
        continue;
      }
      summaries[entry.key] = _latestStateEvidenceRestageTargetSummary(
        family: entry.key,
        target: target,
        action: entry.value,
        trend: trendsByFamily[entry.key] ?? 'awaiting_first_refresh_transition',
        agingStatus: agingStatusesByFamily[entry.key] ??
            'awaiting_first_refresh_transition',
      );
    }
    return summaries;
  }

  String _latestStateFreshnessPostureForPolicyActions({
    required String fallbackPosture,
    required Map<String, String> actionsByFamily,
  }) {
    if (actionsByFamily.values.contains(
      'block_served_basis_recovery_for_family',
    )) {
      return 'family_policy_action_blocks_served_basis_recovery';
    }
    if (actionsByFamily.values.contains('force_restaged_family_inputs')) {
      return 'family_policy_restage_targets_required';
    }
    return fallbackPosture;
  }

  String _latestStateHydrationStatusAfterEvidenceRefresh({
    required String currentBasisStatus,
    required bool readyForReview,
  }) {
    if (currentBasisStatus == 'staged_latest_state_basis') {
      return readyForReview
          ? 'staged_latest_avrai_evidence_refresh_ready_for_review'
          : 'staged_latest_avrai_evidence_refresh_blocked';
    }
    return readyForReview
        ? 'latest_avrai_evidence_refreshed_ready_for_staging'
        : 'latest_avrai_evidence_refreshed_blocked';
  }

  ReplaySimulationLabServedBasisState _servedBasisStateWith(
    ReplaySimulationLabServedBasisState state,
    Map<String, dynamic> updates,
  ) {
    final json = state.toJson()..addAll(updates);
    return ReplaySimulationLabServedBasisState.fromJson(json);
  }

  String _latestStateAgingTransition({
    required Map<String, dynamic> previousPayload,
    required bool receiptBacked,
    required double freshnessHours,
    required double freshnessThresholdHours,
  }) {
    if (previousPayload.isEmpty) {
      return 'first_refresh_materialized';
    }
    final previousReceiptBacked = previousPayload['receiptBacked'] == true;
    final previousFreshness = _latestStateEvidenceFreshnessHours(
      previousPayload,
    );
    if (previousReceiptBacked && !receiptBacked) {
      return 'degraded_from_receipt_backed_current';
    }
    if (previousFreshness <= freshnessThresholdHours &&
        freshnessHours > freshnessThresholdHours) {
      return 'aged_beyond_policy_window';
    }
    if (freshnessHours < previousFreshness) {
      return 'refreshed_with_newer_evidence';
    }
    return 'carried_forward_without_improvement';
  }

  List<String> _latestStateRefreshSourceEvidenceRefs({
    required String family,
    required ReplaySimulationAdminSnapshot snapshot,
  }) {
    switch (family) {
      case 'app_observations':
        final refs = snapshot.foundation.intakeFlowRefs
            .map((flow) => 'simulation_snapshot.json#intake_flow:$flow')
            .toList(growable: true);
        if (snapshot.realismProvenance.intakeFlowRefs.isNotEmpty) {
          refs.add('simulation_snapshot.json#realism_provenance:intake_flows');
        }
        return refs;
      case 'runtime_os_locality_state':
        final refs = <String>[];
        if (snapshot.localityOverlays.isNotEmpty) {
          refs.add('simulation_snapshot.json#locality_overlays');
        }
        if (snapshot.localityHierarchyHealth.nodes.isNotEmpty) {
          refs.add('simulation_snapshot.json#locality_hierarchy');
        }
        return refs;
      case 'governed_reality_model_outputs':
        final refs = <String>[];
        if (snapshot.learningReadiness.requestPreviews.isNotEmpty) {
          refs.add('simulation_snapshot.json#reality_model_request_previews');
        }
        if (snapshot.learningReadiness.shareWithRealityModelAllowed) {
          refs.add('simulation_snapshot.json#share_ready_learning_posture');
        }
        return refs;
      default:
        return const <String>[];
    }
  }

  double _latestStateRefreshStrengthScore({
    required String family,
    required ReplaySimulationAdminSnapshot snapshot,
    required bool hasSourceRefs,
  }) {
    final receiptsBonus = snapshot.receipts.isNotEmpty ? 0.10 : 0.0;
    switch (family) {
      case 'app_observations':
        return (hasSourceRefs ? 0.68 : 0.42) +
            (snapshot.foundation.intakeFlowRefs.length.clamp(0, 3) * 0.05) +
            receiptsBonus +
            (snapshot.foundation.sidecarRefs.isNotEmpty ? 0.04 : 0.0);
      case 'runtime_os_locality_state':
        return (hasSourceRefs ? 0.70 : 0.44) +
            (snapshot.localityOverlays.length.clamp(0, 3) * 0.04) +
            (snapshot.localityHierarchyHealth.nodes.length.clamp(0, 3) * 0.03) +
            receiptsBonus;
      case 'governed_reality_model_outputs':
        return (hasSourceRefs ? 0.66 : 0.40) +
            (snapshot.learningReadiness.requestPreviews.length.clamp(0, 3) *
                0.05) +
            (snapshot.learningReadiness.shareWithRealityModelAllowed
                ? 0.10
                : 0.0) +
            (snapshot.contradictions.length <= 2 ? 0.04 : 0.0);
      default:
        return hasSourceRefs ? 0.72 : 0.35;
    }
  }

  bool _latestStateRefreshReceiptBacked({
    required String family,
    required ReplaySimulationAdminSnapshot snapshot,
    required bool hasSourceRefs,
  }) {
    if (!hasSourceRefs) {
      return false;
    }
    switch (family) {
      case 'app_observations':
        return snapshot.foundation.intakeFlowRefs.isNotEmpty &&
            snapshot.receipts.isNotEmpty;
      case 'runtime_os_locality_state':
        return snapshot.localityOverlays.isNotEmpty &&
            snapshot.localityHierarchyHealth.nodes.isNotEmpty;
      case 'governed_reality_model_outputs':
        return snapshot.learningReadiness.requestPreviews.isNotEmpty;
      default:
        return false;
    }
  }

  Future<_ReplaySimulationLatestStateRefreshMaterialization>
      _materializeLatestStateEvidenceRefresh({
    required ReplaySimulationAdminSnapshot snapshot,
    required String supportedPlaceRef,
    required String relativeRoot,
    required Directory latestStateDirectory,
    required DateTime refreshedAt,
  }) async {
    final refreshPolicy =
        _latestStateRefreshPolicyForSupportedPlace(supportedPlaceRef);
    final payloadByFamily = <String, Map<String, dynamic>>{};
    final agingTransitionsByFamily = <String, String>{};
    final evidenceFamilies = _defaultLatestStateEvidenceRefsByFamily(
      relativeRoot,
    ).keys;

    for (final family in evidenceFamilies) {
      final currentFile = File(
        path.join(
          latestStateDirectory.path,
          _latestStateEvidenceCurrentFileName(family),
        ),
      );
      final seedFile = File(
        path.join(
          latestStateDirectory.path,
          _latestStateEvidenceSeedFileName(family),
        ),
      );
      Map<String, dynamic> previousPayload = const <String, dynamic>{};
      final previousFile = currentFile.existsSync() ? currentFile : seedFile;
      if (previousFile.existsSync()) {
        try {
          final raw = previousFile.readAsStringSync().trim();
          if (raw.isNotEmpty) {
            previousPayload = Map<String, dynamic>.from(
              jsonDecode(raw) as Map<String, dynamic>,
            );
          }
        } on FormatException {
          previousPayload = const <String, dynamic>{};
        }
      }

      final sourceEvidenceRefs = _latestStateRefreshSourceEvidenceRefs(
        family: family,
        snapshot: snapshot,
      );
      final hasSourceRefs = sourceEvidenceRefs.isNotEmpty;
      final receiptBacked = _latestStateRefreshReceiptBacked(
        family: family,
        snapshot: snapshot,
        hasSourceRefs: hasSourceRefs,
      );
      final freshnessHours =
          refreshedAt.difference(snapshot.generatedAt.toUtc()).inMinutes / 60.0;
      final strengthScore = _latestStateRefreshStrengthScore(
        family: family,
        snapshot: snapshot,
        hasSourceRefs: hasSourceRefs,
      ).clamp(0.0, 0.99);
      final agingTransition = _latestStateAgingTransition(
        previousPayload: previousPayload,
        receiptBacked: receiptBacked,
        freshnessHours: freshnessHours,
        freshnessThresholdHours: refreshPolicy.freshnessThresholdHoursFor(
          family,
        ),
      );
      agingTransitionsByFamily[family] = agingTransition;
      payloadByFamily[family] = <String, dynamic>{
        'environmentId': snapshot.environmentId,
        'supportedPlaceRef': supportedPlaceRef,
        'evidenceFamily': family,
        'selectionStatus': hasSourceRefs
            ? 'selected_current_evidence'
            : 'selected_current_evidence_degraded',
        'selectionPolicy': 'governed_supported_place_refresh',
        'refreshedAt': refreshedAt.toIso8601String(),
        'snapshotGeneratedAt': snapshot.generatedAt.toUtc().toIso8601String(),
        'freshnessHours': freshnessHours,
        'strengthScore': strengthScore,
        'receiptBacked': receiptBacked,
        'sourceEvidenceRefs': sourceEvidenceRefs,
        'agingTransition': agingTransition,
      };
    }

    return _ReplaySimulationLatestStateRefreshMaterialization(
      payloadByFamily: payloadByFamily,
      agingTransitionsByFamily: agingTransitionsByFamily,
    );
  }

  Future<ReplaySimulationLabServedBasisState>
      _refreshLatestStateEvidenceBundleInternal({
    required String environmentId,
    String latestStateRefreshExecutionStatus = 'not_checked',
    String? latestStateRefreshExecutionReceiptRef,
    DateTime? latestStateRefreshExecutionCheckedAt,
  }) async {
    final normalizedEnvironmentId = environmentId.trim();
    final environments = await listAvailableEnvironments();
    final descriptor = environments.where(
      (entry) => entry.environmentId == normalizedEnvironmentId,
    );
    if (descriptor.isEmpty) {
      throw StateError('Unknown simulation environment: $environmentId');
    }
    final currentDescriptor = descriptor.first;
    final currentState = await getServedBasisState(
      environmentId: normalizedEnvironmentId,
    );
    final snapshot = await getSnapshot(environmentId: normalizedEnvironmentId);
    final now = _nowProvider().toUtc();
    final root = await _registeredEnvironmentDirectory(normalizedEnvironmentId);
    final latestStateDir = Directory(path.join(root.path, 'latest_state'))
      ..createSync(recursive: true);
    final relativeRoot = _worldSimulationLabRelativePath(
      'registered_environments',
      normalizedEnvironmentId,
    );
    final supportedPlaceRef = 'place:${currentDescriptor.cityCode}';
    final refreshMaterialization = await _materializeLatestStateEvidenceRefresh(
      snapshot: snapshot,
      supportedPlaceRef: supportedPlaceRef,
      relativeRoot: relativeRoot,
      latestStateDirectory: latestStateDir,
      refreshedAt: now,
    );
    for (final entry in refreshMaterialization.payloadByFamily.entries) {
      await _writePrettyJson(
        File(
          path.join(
            latestStateDir.path,
            _latestStateEvidenceCurrentFileName(entry.key),
          ),
        ),
        entry.value,
      );
    }

    final latestStateSelection = await _selectLatestStateEvidenceBundle(
      environmentId: normalizedEnvironmentId,
      supportedPlaceRef: supportedPlaceRef,
      relativeRoot: relativeRoot,
      latestStateDirectory: latestStateDir,
    );
    final archivedReceiptName =
        'latest_state_refresh.${now.millisecondsSinceEpoch}.json';
    final archivedReceiptRef =
        '$relativeRoot/latest_state/$archivedReceiptName';
    final currentReceiptRef =
        '$relativeRoot/latest_state/latest_state_refresh.current.json';
    final currentBasisStatus =
        currentState?.currentBasisStatus ?? 'replay_grounded_seed_basis';
    final canMutateReadiness =
        currentBasisStatus != 'latest_state_served_basis' &&
            currentBasisStatus != 'expired_latest_state_served_basis';
    final agingTransitionsByFamily = Map<String, String>.from(
      refreshMaterialization.agingTransitionsByFamily,
    );
    final agingTrendsByFamily = <String, String>{};
    final agingTrendSummariesByFamily = <String, String>{};
    final policyActionsByFamily = <String, String>{};
    final policyActionSummariesByFamily = <String, String>{};
    for (final family in latestStateSelection.refsByFamily.keys) {
      final transition = agingTransitionsByFamily[family] ??
          'carried_forward_without_improvement';
      final agingStatus = latestStateSelection.agingStatusesByFamily[family] ??
          'awaiting_first_refresh_transition';
      final trend = _latestStateEvidenceAgingTrend(
        previousTrend:
            currentState?.latestStateEvidenceAgingTrendsByFamily[family],
        transition: transition,
        agingStatus: agingStatus,
      );
      agingTrendsByFamily[family] = trend;
      agingTrendSummariesByFamily[family] =
          _latestStateEvidenceAgingTrendSummary(
        family: family,
        trend: trend,
        transition: transition,
        agingStatus: agingStatus,
      );
      final policyAction = _latestStateEvidencePolicyAction(
        trend: trend,
        agingStatus: agingStatus,
      );
      policyActionsByFamily[family] = policyAction;
      policyActionSummariesByFamily[family] =
          _latestStateEvidencePolicyActionSummary(
        family: family,
        action: policyAction,
        trend: trend,
        agingStatus: agingStatus,
      );
    }
    final restageTargetsByFamily = _latestStateEvidenceRestageTargetsForActions(
      actionsByFamily: policyActionsByFamily,
    );
    final restageTargetSummariesByFamily =
        _latestStateEvidenceRestageTargetSummariesForActions(
      actionsByFamily: policyActionsByFamily,
      trendsByFamily: agingTrendsByFamily,
      agingStatusesByFamily: latestStateSelection.agingStatusesByFamily,
    );
    final actionBlockedReasons = _latestStatePolicyActionBlockedReasons(
      actionsByFamily: policyActionsByFamily,
    );
    final effectiveBlockedReasons = <String>[
      ...latestStateSelection.promotionBlockedReasons,
      ...actionBlockedReasons,
    ];
    final effectivePromotionReadiness = effectiveBlockedReasons.isEmpty
        ? latestStateSelection.promotionReadiness
        : 'blocked_pending_latest_state_evidence';
    final effectiveHydrationFreshnessPosture = effectiveBlockedReasons.isEmpty
        ? latestStateSelection.hydrationFreshnessPosture
        : _latestStateFreshnessPostureForPolicyActions(
            fallbackPosture: latestStateSelection.hydrationFreshnessPosture,
            actionsByFamily: policyActionsByFamily,
          );
    final readyForReview =
        effectivePromotionReadiness == 'ready_for_bounded_basis_review';
    final nextHydrationStatus = canMutateReadiness
        ? _latestStateHydrationStatusAfterEvidenceRefresh(
            currentBasisStatus: currentBasisStatus,
            readyForReview: readyForReview,
          )
        : (currentState?.latestStateHydrationStatus ??
            'awaiting_latest_avrai_evidence_refresh');
    final refreshedState = ReplaySimulationLabServedBasisState(
      environmentId: normalizedEnvironmentId,
      supportedPlaceRef: supportedPlaceRef,
      stagedAt: now,
      servedBasisRef: currentState?.servedBasisRef ??
          '$relativeRoot/served_city_pack_basis.seed.json',
      cityPackStructuralRef: currentState?.cityPackStructuralRef ??
          currentDescriptor.cityPackStructuralRef,
      priorServedBasisRef: currentState?.priorServedBasisRef,
      basisRefreshLineageRef: currentState?.basisRefreshLineageRef,
      latestStateRefreshReceiptRef: currentReceiptRef,
      latestStateDecisionStatus: currentBasisStatus ==
              'staged_latest_state_basis'
          ? (readyForReview ? 'awaiting_basis_review_decision' : 'not_reviewed')
          : (currentState?.latestStateDecisionStatus ?? 'not_reviewed'),
      latestStateDecisionArtifactRef:
          currentState?.latestStateDecisionArtifactRef,
      latestStateDecisionRationale: currentState?.latestStateDecisionRationale,
      latestStateDecisionRecordedAt:
          currentState?.latestStateDecisionRecordedAt,
      latestStateRevalidationStatus:
          currentState?.latestStateRevalidationStatus ?? 'not_revalidated',
      latestStateRevalidationReceiptRef:
          currentState?.latestStateRevalidationReceiptRef,
      latestStateRevalidationArtifactRef:
          currentState?.latestStateRevalidationArtifactRef,
      latestStateRevalidatedAt: currentState?.latestStateRevalidatedAt,
      latestStateRecoveryDecisionStatus:
          currentState?.latestStateRecoveryDecisionStatus ?? 'not_reviewed',
      latestStateRecoveryDecisionArtifactRef:
          currentState?.latestStateRecoveryDecisionArtifactRef,
      latestStateRecoveryDecisionRationale:
          currentState?.latestStateRecoveryDecisionRationale,
      latestStateRecoveryDecisionRecordedAt:
          currentState?.latestStateRecoveryDecisionRecordedAt,
      currentBasisStatus: currentBasisStatus,
      latestStateHydrationStatus: nextHydrationStatus,
      latestStatePromotionReadiness: canMutateReadiness
          ? effectivePromotionReadiness
          : (currentState?.latestStatePromotionReadiness ??
              'blocked_pending_latest_state_evidence'),
      latestStatePromotionBlockedReasons: canMutateReadiness
          ? effectiveBlockedReasons
          : (currentState?.latestStatePromotionBlockedReasons ??
              const <String>[]),
      hydrationFreshnessPosture: canMutateReadiness
          ? effectiveHydrationFreshnessPosture
          : (currentState?.hydrationFreshnessPosture ??
              'refresh_receipts_required_before_served_basis_change'),
      latestStateRefreshCadenceHours:
          latestStateSelection.refreshPolicy.refreshCadenceHours,
      latestStateRefreshCadenceStatus: _latestStateRefreshCadenceStatus(
        refreshCadenceHours:
            latestStateSelection.refreshPolicy.refreshCadenceHours,
        referenceAt: now,
      ),
      latestStateRefreshReferenceAt: now,
      latestStateRefreshPolicySummaries:
          latestStateSelection.refreshPolicy.summaries,
      latestStateRefreshExecutionStatus: latestStateRefreshExecutionStatus,
      latestStateRefreshExecutionReceiptRef:
          latestStateRefreshExecutionReceiptRef,
      latestStateRefreshExecutionCheckedAt:
          latestStateRefreshExecutionCheckedAt,
      latestStateEvidenceRefsByFamily: latestStateSelection.refsByFamily,
      latestStateEvidenceSelectionSummariesByFamily:
          latestStateSelection.selectionSummariesByFamily,
      latestStateEvidenceAgingStatusesByFamily:
          latestStateSelection.agingStatusesByFamily,
      latestStateEvidenceAgingSummariesByFamily:
          latestStateSelection.agingSummariesByFamily,
      latestStateEvidenceAgingTransitionsByFamily: agingTransitionsByFamily,
      latestStateEvidenceAgingTrendsByFamily: agingTrendsByFamily,
      latestStateEvidenceAgingTrendSummariesByFamily:
          agingTrendSummariesByFamily,
      latestStateEvidencePolicyActionsByFamily: policyActionsByFamily,
      latestStateEvidencePolicyActionSummariesByFamily:
          policyActionSummariesByFamily,
      latestStateEvidenceRestageTargetsByFamily: restageTargetsByFamily,
      latestStateEvidenceRestageTargetSummariesByFamily:
          restageTargetSummariesByFamily,
    );

    final refreshReceiptPayload = <String, dynamic>{
      'environmentId': normalizedEnvironmentId,
      'supportedPlaceRef': supportedPlaceRef,
      'refreshedAt': now.toIso8601String(),
      'currentBasisStatus': currentBasisStatus,
      'servedBasisRef': refreshedState.servedBasisRef,
      'latestStateRefreshReceiptRef': currentReceiptRef,
      'archivedRefreshReceiptRef': archivedReceiptRef,
      'latestStateEvidenceRefsByFamily': latestStateSelection.refsByFamily,
      'latestStateEvidenceSelectionSummariesByFamily':
          latestStateSelection.selectionSummariesByFamily,
      'latestStateEvidenceAgingStatusesByFamily':
          latestStateSelection.agingStatusesByFamily,
      'latestStateEvidenceAgingSummariesByFamily':
          latestStateSelection.agingSummariesByFamily,
      'latestStateEvidenceAgingTransitionsByFamily': agingTransitionsByFamily,
      'latestStateEvidenceAgingTrendsByFamily': agingTrendsByFamily,
      'latestStateEvidenceAgingTrendSummariesByFamily':
          agingTrendSummariesByFamily,
      'latestStateEvidencePolicyActionsByFamily': policyActionsByFamily,
      'latestStateEvidencePolicyActionSummariesByFamily':
          policyActionSummariesByFamily,
      'latestStateEvidenceRestageTargetsByFamily': restageTargetsByFamily,
      'latestStateEvidenceRestageTargetSummariesByFamily':
          restageTargetSummariesByFamily,
      'agingTransitionsByFamily':
          refreshMaterialization.agingTransitionsByFamily,
      'promotionReadiness': refreshedState.latestStatePromotionReadiness,
      'promotionBlockedReasons':
          refreshedState.latestStatePromotionBlockedReasons,
      'hydrationStatus': nextHydrationStatus,
      'hydrationFreshnessPosture': refreshedState.hydrationFreshnessPosture,
      'refreshCadenceHours':
          latestStateSelection.refreshPolicy.refreshCadenceHours,
      'refreshPolicySummaries': latestStateSelection.refreshPolicy.summaries,
    };
    await _writePrettyJson(
      File(path.join(latestStateDir.path, archivedReceiptName)),
      refreshReceiptPayload,
    );
    await _writePrettyJson(
      File(path.join(latestStateDir.path, 'latest_state_refresh.current.json')),
      refreshReceiptPayload,
    );
    await _writePrettyJson(
      File(path.join(root.path, 'served_city_pack_basis.current.json')),
      refreshedState.toJson(),
    );
    return refreshedState;
  }

  Future<ReplaySimulationLabServedBasisState> refreshLatestStateEvidenceBundle({
    required String environmentId,
  }) {
    return _refreshLatestStateEvidenceBundleInternal(
      environmentId: environmentId,
    );
  }

  Future<ReplaySimulationLabServedBasisState>
      runScheduledLatestStateRefreshCheck({
    required String environmentId,
  }) async {
    final normalizedEnvironmentId = environmentId.trim();
    final currentState = await getServedBasisState(
      environmentId: normalizedEnvironmentId,
    );
    if (currentState == null) {
      throw StateError('No served-basis state exists for $environmentId.');
    }
    final now = _nowProvider().toUtc();
    final root = await _registeredEnvironmentDirectory(normalizedEnvironmentId);
    final latestStateDir = Directory(path.join(root.path, 'latest_state'))
      ..createSync(recursive: true);
    final relativeRoot = _worldSimulationLabRelativePath(
      'registered_environments',
      normalizedEnvironmentId,
    );
    final cadenceStatusBefore = _latestStateRefreshCadenceStatus(
      refreshCadenceHours: currentState.latestStateRefreshCadenceHours,
      referenceAt: currentState.latestStateRefreshReferenceAt,
    );
    final archivedExecutionName =
        'latest_state_refresh_cadence.${now.millisecondsSinceEpoch}.json';
    final currentExecutionReceiptRef =
        '$relativeRoot/latest_state/latest_state_refresh_cadence.current.json';
    final shouldExecute =
        cadenceStatusBefore == 'awaiting_first_refresh_receipts' ||
            cadenceStatusBefore == 'due_for_refresh' ||
            cadenceStatusBefore == 'overdue_for_refresh';
    final executionStatus = switch (cadenceStatusBefore) {
      'awaiting_first_refresh_receipts' => 'executed_initial_refresh',
      'due_for_refresh' => 'executed_due_refresh',
      'overdue_for_refresh' => 'executed_overdue_refresh',
      _ => 'skipped_within_refresh_window',
    };

    if (shouldExecute) {
      final refreshedState = await _refreshLatestStateEvidenceBundleInternal(
        environmentId: normalizedEnvironmentId,
        latestStateRefreshExecutionStatus: executionStatus,
        latestStateRefreshExecutionReceiptRef: currentExecutionReceiptRef,
        latestStateRefreshExecutionCheckedAt: now,
      );
      final executionReceipt = <String, dynamic>{
        'environmentId': normalizedEnvironmentId,
        'checkedAt': now.toIso8601String(),
        'cadenceStatusBefore': cadenceStatusBefore,
        'executionStatus': executionStatus,
        'supportedPlaceRef': refreshedState.supportedPlaceRef,
        'servedBasisRef': refreshedState.servedBasisRef,
        'latestStateRefreshReceiptRef':
            refreshedState.latestStateRefreshReceiptRef,
        'latestStateRefreshReferenceAt':
            refreshedState.latestStateRefreshReferenceAt?.toIso8601String(),
        'latestStateRefreshCadenceStatus':
            refreshedState.latestStateRefreshCadenceStatus,
        'promotionReadiness': refreshedState.latestStatePromotionReadiness,
      };
      await _writePrettyJson(
        File(path.join(latestStateDir.path, archivedExecutionName)),
        executionReceipt,
      );
      await _writePrettyJson(
        File(
          path.join(
            latestStateDir.path,
            'latest_state_refresh_cadence.current.json',
          ),
        ),
        executionReceipt,
      );
      return refreshedState;
    }

    final skippedState = _servedBasisStateWith(
      currentState,
      <String, dynamic>{
        'latestStateRefreshCadenceStatus': cadenceStatusBefore,
        'latestStateRefreshExecutionStatus': executionStatus,
        'latestStateRefreshExecutionReceiptRef': currentExecutionReceiptRef,
        'latestStateRefreshExecutionCheckedAt': now.toIso8601String(),
      },
    );
    final executionReceipt = <String, dynamic>{
      'environmentId': normalizedEnvironmentId,
      'checkedAt': now.toIso8601String(),
      'cadenceStatusBefore': cadenceStatusBefore,
      'executionStatus': executionStatus,
      'supportedPlaceRef': skippedState.supportedPlaceRef,
      'servedBasisRef': skippedState.servedBasisRef,
      'latestStateRefreshReceiptRef': skippedState.latestStateRefreshReceiptRef,
      'latestStateRefreshReferenceAt':
          skippedState.latestStateRefreshReferenceAt?.toIso8601String(),
      'latestStateRefreshCadenceStatus':
          skippedState.latestStateRefreshCadenceStatus,
    };
    await _writePrettyJson(
      File(path.join(latestStateDir.path, archivedExecutionName)),
      executionReceipt,
    );
    await _writePrettyJson(
      File(
        path.join(
          latestStateDir.path,
          'latest_state_refresh_cadence.current.json',
        ),
      ),
      executionReceipt,
    );
    await _writePrettyJson(
      File(path.join(root.path, 'served_city_pack_basis.current.json')),
      skippedState.toJson(),
    );
    return skippedState;
  }

  Future<_ReplaySimulationLatestStateEvidenceSelectionBundle>
      _selectLatestStateEvidenceBundle({
    required String environmentId,
    required String supportedPlaceRef,
    required String relativeRoot,
    required Directory latestStateDirectory,
  }) async {
    final refreshPolicy =
        _latestStateRefreshPolicyForSupportedPlace(supportedPlaceRef);
    final selections = <_ReplaySimulationLatestStateEvidenceSelection>[];
    final agingStatusesByFamily = <String, String>{};
    final agingSummariesByFamily = <String, String>{};

    for (final family
        in _defaultLatestStateEvidenceRefsByFamily(relativeRoot).keys) {
      final currentFile = File(
        path.join(
          latestStateDirectory.path,
          _latestStateEvidenceCurrentFileName(family),
        ),
      );
      final seedFile = File(
        path.join(
          latestStateDirectory.path,
          _latestStateEvidenceSeedFileName(family),
        ),
      );
      final selectedFile = currentFile.existsSync() ? currentFile : seedFile;
      final selectedRef = path.join(
        _worldSimulationLabRelativePath(
          'registered_environments',
          environmentId,
          'latest_state',
        ),
        path.basename(selectedFile.path),
      );

      Map<String, dynamic> payload = const <String, dynamic>{};
      try {
        final raw = selectedFile.readAsStringSync().trim();
        if (raw.isNotEmpty) {
          payload = Map<String, dynamic>.from(
            jsonDecode(raw) as Map<String, dynamic>,
          );
        }
      } on FormatException {
        payload = const <String, dynamic>{};
      }

      final defaultStatus = currentFile.existsSync()
          ? 'selected_current_evidence'
          : 'seed_placeholder';
      selections.add(
        _ReplaySimulationLatestStateEvidenceSelection(
          family: family,
          selectedRef: selectedRef,
          selectionStatus:
              (payload['selectionStatus'] ?? defaultStatus).toString().trim(),
          freshnessHours: _latestStateEvidenceFreshnessHours(payload),
          strengthScore: _latestStateEvidenceStrengthScore(payload),
          receiptBacked: payload['receiptBacked'] as bool? ?? false,
          policyFreshnessThresholdHours:
              refreshPolicy.freshnessThresholdHoursFor(family),
          policyStrengthThreshold: refreshPolicy.strengthThresholdFor(family),
        ),
      );
      final agingStatus = _latestStateEvidenceAgingStatus(
        selectionStatus:
            (payload['selectionStatus'] ?? defaultStatus).toString().trim(),
        freshnessHours: _latestStateEvidenceFreshnessHours(payload),
        policyFreshnessThresholdHours:
            refreshPolicy.freshnessThresholdHoursFor(family),
        receiptBacked: payload['receiptBacked'] as bool? ?? false,
      );
      agingStatusesByFamily[family] = agingStatus;
      agingSummariesByFamily[family] = _latestStateEvidenceAgingSummary(
        family: family,
        status: agingStatus,
        freshnessHours: _latestStateEvidenceFreshnessHours(payload),
        policyFreshnessThresholdHours:
            refreshPolicy.freshnessThresholdHoursFor(family),
        receiptBacked: payload['receiptBacked'] as bool? ?? false,
        supportedPlaceRef: supportedPlaceRef,
      );
    }

    final blockedReasons = <String>[];
    for (final selection in selections) {
      if (selection.selectionStatus == 'seed_placeholder') {
        blockedReasons.add(
          '${_describeHydrationEvidenceFamily(selection.family)} is still using seed placeholder evidence.',
        );
      }
      if (!selection.receiptBacked) {
        blockedReasons.add(
          '${_describeHydrationEvidenceFamily(selection.family)} is not receipt-backed yet.',
        );
      }
      if (selection.freshnessHours > selection.policyFreshnessThresholdHours) {
        blockedReasons.add(
          '${_describeHydrationEvidenceFamily(selection.family)} freshness exceeds the ${selection.policyFreshnessThresholdHours.toStringAsFixed(0)}h policy for $supportedPlaceRef.',
        );
      }
      if (selection.strengthScore < selection.policyStrengthThreshold) {
        blockedReasons.add(
          '${_describeHydrationEvidenceFamily(selection.family)} strength is below the ${(selection.policyStrengthThreshold * 100).round()}% policy for $supportedPlaceRef.',
        );
      }
    }

    final readiness = blockedReasons.isEmpty
        ? 'ready_for_bounded_basis_review'
        : 'blocked_pending_latest_state_evidence';
    final hydrationStatus = blockedReasons.isEmpty
        ? 'staged_latest_avrai_evidence_refresh_ready_for_review'
        : 'staged_latest_avrai_evidence_refresh_blocked';
    final freshnessPosture = blockedReasons.isEmpty
        ? 'ready_for_served_basis_review_with_receipts'
        : 'refresh_receipts_required_before_served_basis_change';

    return _ReplaySimulationLatestStateEvidenceSelectionBundle(
      refsByFamily: <String, String>{
        for (final selection in selections)
          selection.family: selection.selectedRef,
      },
      selectionSummariesByFamily: <String, String>{
        for (final selection in selections) selection.family: selection.summary,
      },
      agingStatusesByFamily: agingStatusesByFamily,
      agingSummariesByFamily: agingSummariesByFamily,
      promotionReadiness: readiness,
      promotionBlockedReasons: blockedReasons,
      hydrationStatus: hydrationStatus,
      hydrationFreshnessPosture: freshnessPosture,
      refreshPolicy: refreshPolicy,
    );
  }

  Future<ReplaySimulationLabEnvironmentRegistration> registerLabEnvironment({
    required String displayName,
    required String cityCode,
    required int replayYear,
    required Map<String, String> localityDisplayNames,
    String description = '',
    String? environmentId,
  }) async {
    final normalizedCityCode = _normalizeToken(cityCode, separator: '_');
    final normalizedDisplayName = displayName.trim();
    if (normalizedDisplayName.isEmpty) {
      throw StateError(
          'World simulation lab environments need a display name.');
    }
    if (normalizedCityCode.isEmpty) {
      throw StateError('World simulation lab environments need a city code.');
    }
    if (replayYear <= 0) {
      throw StateError('World simulation lab environments need a replay year.');
    }
    final normalizedLocalities = <String, String>{};
    for (final entry in localityDisplayNames.entries) {
      final code = _normalizeToken(entry.key, separator: '_');
      final name = entry.value.trim();
      if (code.isEmpty || name.isEmpty) {
        continue;
      }
      normalizedLocalities[code] = name;
    }
    if (normalizedLocalities.isEmpty) {
      throw StateError(
        'World simulation lab environments need at least one locality.',
      );
    }

    final resolvedEnvironmentId = (environmentId == null ||
            environmentId.trim().isEmpty)
        ? '${normalizedCityCode.replaceAll('_', '-')}-replay-world-$replayYear'
        : _normalizeToken(environmentId, separator: '-');

    if (_environmentAdapters.containsKey(resolvedEnvironmentId)) {
      throw StateError(
        'A simulation environment already exists for $resolvedEnvironmentId.',
      );
    }
    final existingRegistrations = await listRegisteredLabEnvironments();
    if (existingRegistrations.any(
      (entry) => entry.environmentId == resolvedEnvironmentId,
    )) {
      throw StateError(
        'A world simulation lab environment is already registered for $resolvedEnvironmentId.',
      );
    }

    final root = await _registeredEnvironmentDirectory(resolvedEnvironmentId);
    root.createSync(recursive: true);
    final relativeRoot = _worldSimulationLabRelativePath(
      'registered_environments',
      resolvedEnvironmentId,
    );
    final registration = ReplaySimulationLabEnvironmentRegistration(
      environmentId: resolvedEnvironmentId,
      displayName: normalizedDisplayName,
      cityCode: normalizedCityCode,
      replayYear: replayYear,
      description: description.trim(),
      localityDisplayNames: normalizedLocalities,
      createdAt: _nowProvider().toUtc(),
      cityPackManifestRef: '$relativeRoot/city_pack_manifest.seed.json',
      cityPackStructuralRef: _deriveReplaySimulationCityPackStructuralRef(
        cityCode: normalizedCityCode,
        replayYear: replayYear,
      ),
      campaignDefaultsRef: '$relativeRoot/campaign_defaults.seed.json',
      localityExpectationProfileRef:
          '$relativeRoot/locality_expectations.seed.json',
      worldHealthProfileRef: '$relativeRoot/world_health.seed.json',
      sidecarRefs: <String>['$relativeRoot/environment_registration.json'],
    );

    await _writePrettyJson(
      File(path.join(root.path, 'environment_registration.json')),
      registration.toJson(),
    );
    await _writePrettyJson(
      File(path.join(root.path, 'city_pack_manifest.seed.json')),
      <String, dynamic>{
        'environmentId': registration.environmentId,
        'displayName': registration.displayName,
        'cityCode': registration.cityCode,
        'replayYear': registration.replayYear,
        'cityPackStructuralRef': registration.cityPackStructuralRef,
        'localityCodes': normalizedLocalities.keys.toList(growable: false),
      },
    );
    await _writePrettyJson(
      File(path.join(root.path, 'campaign_defaults.seed.json')),
      <String, dynamic>{
        'environmentId': registration.environmentId,
        'defaultScenarioMode': 'generic_city_pack',
        'operatorIntent': 'world_simulation_lab_bootstrap',
      },
    );
    await _writePrettyJson(
      File(path.join(root.path, 'locality_expectations.seed.json')),
      <String, dynamic>{
        'environmentId': registration.environmentId,
        'localities': normalizedLocalities,
      },
    );
    await _writePrettyJson(
      File(path.join(root.path, 'world_health.seed.json')),
      <String, dynamic>{
        'environmentId': registration.environmentId,
        'healthProfile': 'seeded_generic_city_pack',
        'notes': <String>[
          'Generated by World Simulation Lab registration.',
        ],
      },
    );
    final latestStateDir = Directory(path.join(root.path, 'latest_state'))
      ..createSync(recursive: true);
    await _writePrettyJson(
      File(path.join(latestStateDir.path, 'app_observations.seed.json')),
      <String, dynamic>{
        'environmentId': registration.environmentId,
        'supportedPlaceRef': 'place:${registration.cityCode}',
        'evidenceFamily': 'app_observations',
        'selectionStatus': 'seed_placeholder',
        'selectionPolicy': 'supported_place_latest_known_seed',
        'freshnessHours': 9999,
        'strengthScore': 0.0,
        'receiptBacked': false,
      },
    );
    await _writePrettyJson(
      File(
        path.join(latestStateDir.path, 'runtime_os_locality_state.seed.json'),
      ),
      <String, dynamic>{
        'environmentId': registration.environmentId,
        'supportedPlaceRef': 'place:${registration.cityCode}',
        'evidenceFamily': 'runtime_os_locality_state',
        'selectionStatus': 'seed_placeholder',
        'selectionPolicy': 'supported_place_latest_known_seed',
        'freshnessHours': 9999,
        'strengthScore': 0.0,
        'receiptBacked': false,
      },
    );
    await _writePrettyJson(
      File(
        path.join(
          latestStateDir.path,
          'governed_reality_model_outputs.seed.json',
        ),
      ),
      <String, dynamic>{
        'environmentId': registration.environmentId,
        'supportedPlaceRef': 'place:${registration.cityCode}',
        'evidenceFamily': 'governed_reality_model_outputs',
        'selectionStatus': 'seed_placeholder',
        'selectionPolicy': 'supported_place_latest_known_seed',
        'freshnessHours': 9999,
        'strengthScore': 0.0,
        'receiptBacked': false,
      },
    );
    final latestStateSelection = await _selectLatestStateEvidenceBundle(
      environmentId: registration.environmentId,
      supportedPlaceRef: 'place:${registration.cityCode}',
      relativeRoot: relativeRoot,
      latestStateDirectory: latestStateDir,
    );
    final initialServedBasisState = ReplaySimulationLabServedBasisState(
      environmentId: registration.environmentId,
      supportedPlaceRef: 'place:${registration.cityCode}',
      stagedAt: _nowProvider().toUtc(),
      servedBasisRef: '$relativeRoot/served_city_pack_basis.seed.json',
      cityPackStructuralRef: registration.cityPackStructuralRef,
      latestStateEvidenceRefsByFamily: latestStateSelection.refsByFamily,
      latestStateEvidenceSelectionSummariesByFamily:
          latestStateSelection.selectionSummariesByFamily,
      latestStateEvidenceAgingStatusesByFamily:
          latestStateSelection.agingStatusesByFamily,
      latestStateEvidenceAgingSummariesByFamily:
          latestStateSelection.agingSummariesByFamily,
      latestStateEvidenceAgingTransitionsByFamily: const <String, String>{},
      latestStateEvidenceAgingTrendsByFamily: const <String, String>{},
      latestStateEvidenceAgingTrendSummariesByFamily: const <String, String>{},
      latestStateEvidencePolicyActionsByFamily: const <String, String>{},
      latestStateEvidencePolicyActionSummariesByFamily: const <String,
          String>{},
      latestStateEvidenceRestageTargetsByFamily: const <String, String>{},
      latestStateEvidenceRestageTargetSummariesByFamily: const <String,
          String>{},
      latestStatePromotionReadiness: latestStateSelection.promotionReadiness,
      latestStatePromotionBlockedReasons:
          latestStateSelection.promotionBlockedReasons,
      latestStateRefreshCadenceHours:
          latestStateSelection.refreshPolicy.refreshCadenceHours,
      latestStateRefreshCadenceStatus: _latestStateRefreshCadenceStatus(
        refreshCadenceHours:
            latestStateSelection.refreshPolicy.refreshCadenceHours,
        referenceAt: null,
      ),
      latestStateRefreshPolicySummaries:
          latestStateSelection.refreshPolicy.summaries,
    );
    await _writePrettyJson(
      File(path.join(root.path, 'served_city_pack_basis.seed.json')),
      initialServedBasisState.toJson(),
    );
    await _writePrettyJson(
      File(path.join(root.path, 'served_city_pack_basis.current.json')),
      initialServedBasisState.toJson(),
    );
    return registration;
  }

  Future<List<ReplaySimulationLabVariantDraft>> listLabVariants({
    String? environmentId,
  }) async {
    final variants = <ReplaySimulationLabVariantDraft>[];
    final environmentIds = <String>[];
    if (environmentId != null && environmentId.trim().isNotEmpty) {
      environmentIds.add(environmentId.trim());
    } else {
      environmentIds.addAll(
        (await listAvailableEnvironments()).map((entry) => entry.environmentId),
      );
    }
    for (final id in environmentIds) {
      final root = await _registeredEnvironmentDirectory(id);
      final variantDir = Directory(path.join(root.path, 'variants'));
      if (!variantDir.existsSync()) {
        continue;
      }
      for (final entry in variantDir.listSync(followLinks: false)) {
        if (entry is! File || path.extension(entry.path) != '.json') {
          continue;
        }
        try {
          final raw = entry.readAsStringSync().trim();
          if (raw.isEmpty) {
            continue;
          }
          variants.add(
            ReplaySimulationLabVariantDraft.fromJson(
              Map<String, dynamic>.from(
                jsonDecode(raw) as Map<String, dynamic>,
              ),
            ),
          );
        } on FormatException {
          continue;
        }
      }
    }
    variants.sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
    return variants;
  }

  Future<ReplaySimulationLabVariantDraft> saveLabVariant({
    required String environmentId,
    required String label,
    String hypothesis = '',
    List<String> localityCodes = const <String>[],
    List<String> operatorNotes = const <String>[],
  }) async {
    final environments = await listAvailableEnvironments();
    final descriptor = environments.where(
      (entry) => entry.environmentId == environmentId.trim(),
    );
    if (descriptor.isEmpty) {
      throw StateError('Unknown simulation environment: $environmentId');
    }
    final normalizedLabel = label.trim();
    if (normalizedLabel.isEmpty) {
      throw StateError('World simulation lab variants need a label.');
    }
    final normalizedLocalities = localityCodes
        .map((entry) => _normalizeToken(entry, separator: '_'))
        .where((entry) => entry.isNotEmpty)
        .toSet()
        .toList(growable: false);
    final notes = operatorNotes
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
    final now = _nowProvider().toUtc();
    final variantId =
        '${_normalizeToken(environmentId, separator: '-')}-${_normalizeToken(normalizedLabel, separator: '-')}-${now.millisecondsSinceEpoch}';
    final draft = ReplaySimulationLabVariantDraft(
      environmentId: environmentId.trim(),
      variantId: variantId,
      label: normalizedLabel,
      hypothesis: hypothesis.trim(),
      localityCodes: normalizedLocalities,
      operatorNotes: notes,
      createdAt: now,
      updatedAt: now,
    );
    final root = await _registeredEnvironmentDirectory(draft.environmentId);
    final variantDir = Directory(path.join(root.path, 'variants'))
      ..createSync(recursive: true);
    await _writePrettyJson(
      File(path.join(variantDir.path, '$variantId.json')),
      draft.toJson(),
    );
    return draft;
  }

  Future<ReplaySimulationLabRuntimeState> getLabRuntimeState({
    required String environmentId,
  }) async {
    final root = await _registeredEnvironmentDirectory(environmentId.trim());
    final stateFile =
        File(path.join(root.path, 'world_simulation_lab_state.json'));
    if (!stateFile.existsSync()) {
      return ReplaySimulationLabRuntimeState(
        environmentId: environmentId.trim(),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );
    }
    try {
      final raw = stateFile.readAsStringSync().trim();
      if (raw.isEmpty) {
        return ReplaySimulationLabRuntimeState(
          environmentId: environmentId.trim(),
          updatedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        );
      }
      return ReplaySimulationLabRuntimeState.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map<String, dynamic>),
      );
    } on FormatException {
      return ReplaySimulationLabRuntimeState(
        environmentId: environmentId.trim(),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );
    }
  }

  Future<ReplaySimulationLabServedBasisState?> getServedBasisState({
    required String environmentId,
  }) async {
    Directory root;
    try {
      root = await _registeredEnvironmentDirectory(environmentId.trim());
    } on MissingPluginException {
      return null;
    }
    final stateFile =
        File(path.join(root.path, 'served_city_pack_basis.current.json'));
    if (!stateFile.existsSync()) {
      return null;
    }
    try {
      final raw = stateFile.readAsStringSync().trim();
      if (raw.isEmpty) {
        return null;
      }
      return ReplaySimulationLabServedBasisState.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map<String, dynamic>),
      );
    } on FormatException {
      return null;
    }
  }

  Future<List<ReplaySimulationLabFamilyRestageReviewItem>>
      listLabFamilyRestageReviewItems({
    required String environmentId,
    int limit = 12,
  }) async {
    final normalizedEnvironmentId = environmentId.trim();
    if (normalizedEnvironmentId.isEmpty) {
      return const <ReplaySimulationLabFamilyRestageReviewItem>[];
    }
    final servedBasisState = await getServedBasisState(
      environmentId: normalizedEnvironmentId,
    );
    if (servedBasisState == null) {
      return const <ReplaySimulationLabFamilyRestageReviewItem>[];
    }
    final root = await _registeredEnvironmentDirectory(normalizedEnvironmentId);
    final items = await _syncLabFamilyRestageReviewItems(
      root: root,
      servedBasisState: servedBasisState,
    );
    if (limit <= 0 || items.length <= limit) {
      return items;
    }
    return items.take(limit).toList(growable: false);
  }

  Future<List<ReplaySimulationLabFamilyRestageReviewItem>>
      _syncLabFamilyRestageReviewItems({
    required Directory root,
    required ReplaySimulationLabServedBasisState servedBasisState,
  }) async {
    final queueRoot = Directory(path.join(root.path, 'family_restage_review'))
      ..createSync(recursive: true);
    final activeFamilies = servedBasisState
        .latestStateEvidenceRestageTargetsByFamily.entries
        .where((entry) => entry.value.trim().isNotEmpty)
        .map((entry) => entry.key.trim())
        .where((entry) => entry.isNotEmpty)
        .toSet();

    if (queueRoot.existsSync()) {
      for (final entry in queueRoot.listSync()) {
        if (entry is! Directory) {
          continue;
        }
        final familyCode = path.basename(entry.path).trim();
        if (familyCode.isEmpty || activeFamilies.contains(familyCode)) {
          continue;
        }
        entry.deleteSync(recursive: true);
      }
    }

    final items = <ReplaySimulationLabFamilyRestageReviewItem>[];
    for (final family in activeFamilies) {
      final restageTarget = servedBasisState
              .latestStateEvidenceRestageTargetsByFamily[family]
              ?.trim() ??
          '';
      if (restageTarget.isEmpty) {
        continue;
      }
      final familyRoot = Directory(path.join(queueRoot.path, family))
        ..createSync(recursive: true);
      final itemJsonPath = path.join(
        familyRoot.path,
        'family_restage_review_item.current.json',
      );
      final readmePath = path.join(
        familyRoot.path,
        'FAMILY_RESTAGE_REVIEW_ITEM_README.md',
      );
      DateTime queuedAt = _nowProvider().toUtc();
      String queueStatus = 'queued_for_family_restage_review';
      String? queueDecisionArtifactRef;
      String? queueDecisionRationale;
      DateTime? queueDecisionRecordedAt;
      String? restageIntakeQueueJsonPath;
      String? restageIntakeReadmePath;
      String? restageIntakeSourceId;
      String? restageIntakeJobId;
      String? restageIntakeReviewItemId;
      String? restageIntakeResolutionStatus;
      String? restageIntakeResolutionArtifactRef;
      String? restageIntakeResolutionRationale;
      DateTime? restageIntakeResolutionRecordedAt;
      String? followUpQueueStatus;
      String? followUpQueueJsonPath;
      String? followUpReadmePath;
      String? followUpSourceId;
      String? followUpJobId;
      String? followUpReviewItemId;
      String? followUpResolutionStatus;
      String? followUpResolutionArtifactRef;
      String? followUpResolutionRationale;
      DateTime? followUpResolutionRecordedAt;
      String? restageResolutionQueueStatus;
      String? restageResolutionQueueJsonPath;
      String? restageResolutionReadmePath;
      String? restageResolutionSourceId;
      String? restageResolutionJobId;
      String? restageResolutionReviewItemId;
      String? restageResolutionResolutionStatus;
      String? restageResolutionResolutionArtifactRef;
      String? restageResolutionResolutionRationale;
      DateTime? restageResolutionResolutionRecordedAt;
      String? restageExecutionQueueStatus;
      String? restageExecutionQueueJsonPath;
      String? restageExecutionReadmePath;
      String? restageExecutionSourceId;
      String? restageExecutionJobId;
      String? restageExecutionReviewItemId;
      String? restageExecutionResolutionStatus;
      String? restageExecutionResolutionArtifactRef;
      String? restageExecutionResolutionRationale;
      DateTime? restageExecutionResolutionRecordedAt;
      String? restageApplicationQueueStatus;
      String? restageApplicationQueueJsonPath;
      String? restageApplicationReadmePath;
      String? restageApplicationSourceId;
      String? restageApplicationJobId;
      String? restageApplicationReviewItemId;
      String? restageApplicationResolutionStatus;
      String? restageApplicationResolutionArtifactRef;
      String? restageApplicationResolutionRationale;
      DateTime? restageApplicationResolutionRecordedAt;
      String? restageApplyQueueStatus;
      String? restageApplyQueueJsonPath;
      String? restageApplyReadmePath;
      String? restageApplySourceId;
      String? restageApplyJobId;
      String? restageApplyReviewItemId;
      String? restageApplyResolutionStatus;
      String? restageApplyResolutionArtifactRef;
      String? restageApplyResolutionRationale;
      DateTime? restageApplyResolutionRecordedAt;
      String? restageServedBasisUpdateQueueStatus;
      String? restageServedBasisUpdateQueueJsonPath;
      String? restageServedBasisUpdateReadmePath;
      String? restageServedBasisUpdateSourceId;
      String? restageServedBasisUpdateJobId;
      String? restageServedBasisUpdateReviewItemId;
      String? restageServedBasisUpdateResolutionStatus;
      String? restageServedBasisUpdateResolutionArtifactRef;
      String? restageServedBasisUpdateResolutionRationale;
      DateTime? restageServedBasisUpdateResolutionRecordedAt;
      final existingFile = File(itemJsonPath);
      if (existingFile.existsSync()) {
        try {
          final raw = existingFile.readAsStringSync().trim();
          if (raw.isNotEmpty) {
            final existing =
                ReplaySimulationLabFamilyRestageReviewItem.fromJson(
              Map<String, dynamic>.from(
                jsonDecode(raw) as Map<String, dynamic>,
              ),
            );
            queuedAt = existing.queuedAt;
            queueStatus = existing.queueStatus.trim().isEmpty
                ? 'queued_for_family_restage_review'
                : existing.queueStatus;
            queueDecisionArtifactRef = existing.queueDecisionArtifactRef;
            queueDecisionRationale = existing.queueDecisionRationale;
            queueDecisionRecordedAt = existing.queueDecisionRecordedAt;
            restageIntakeQueueJsonPath = existing.restageIntakeQueueJsonPath;
            restageIntakeReadmePath = existing.restageIntakeReadmePath;
            restageIntakeSourceId = existing.restageIntakeSourceId;
            restageIntakeJobId = existing.restageIntakeJobId;
            restageIntakeReviewItemId = existing.restageIntakeReviewItemId;
            restageIntakeResolutionStatus =
                existing.restageIntakeResolutionStatus;
            restageIntakeResolutionArtifactRef =
                existing.restageIntakeResolutionArtifactRef;
            restageIntakeResolutionRationale =
                existing.restageIntakeResolutionRationale;
            restageIntakeResolutionRecordedAt =
                existing.restageIntakeResolutionRecordedAt;
            followUpQueueStatus = existing.followUpQueueStatus;
            followUpQueueJsonPath = existing.followUpQueueJsonPath;
            followUpReadmePath = existing.followUpReadmePath;
            followUpSourceId = existing.followUpSourceId;
            followUpJobId = existing.followUpJobId;
            followUpReviewItemId = existing.followUpReviewItemId;
            followUpResolutionStatus = existing.followUpResolutionStatus;
            followUpResolutionArtifactRef =
                existing.followUpResolutionArtifactRef;
            followUpResolutionRationale = existing.followUpResolutionRationale;
            followUpResolutionRecordedAt =
                existing.followUpResolutionRecordedAt;
            restageResolutionQueueStatus =
                existing.restageResolutionQueueStatus;
            restageResolutionQueueJsonPath =
                existing.restageResolutionQueueJsonPath;
            restageResolutionReadmePath = existing.restageResolutionReadmePath;
            restageResolutionSourceId = existing.restageResolutionSourceId;
            restageResolutionJobId = existing.restageResolutionJobId;
            restageResolutionReviewItemId =
                existing.restageResolutionReviewItemId;
            restageResolutionResolutionStatus =
                existing.restageResolutionResolutionStatus;
            restageResolutionResolutionArtifactRef =
                existing.restageResolutionResolutionArtifactRef;
            restageResolutionResolutionRationale =
                existing.restageResolutionResolutionRationale;
            restageResolutionResolutionRecordedAt =
                existing.restageResolutionResolutionRecordedAt;
            restageExecutionQueueStatus = existing.restageExecutionQueueStatus;
            restageExecutionQueueJsonPath =
                existing.restageExecutionQueueJsonPath;
            restageExecutionReadmePath = existing.restageExecutionReadmePath;
            restageExecutionSourceId = existing.restageExecutionSourceId;
            restageExecutionJobId = existing.restageExecutionJobId;
            restageExecutionReviewItemId =
                existing.restageExecutionReviewItemId;
            restageExecutionResolutionStatus =
                existing.restageExecutionResolutionStatus;
            restageExecutionResolutionArtifactRef =
                existing.restageExecutionResolutionArtifactRef;
            restageExecutionResolutionRationale =
                existing.restageExecutionResolutionRationale;
            restageExecutionResolutionRecordedAt =
                existing.restageExecutionResolutionRecordedAt;
            restageApplicationQueueStatus =
                existing.restageApplicationQueueStatus;
            restageApplicationQueueJsonPath =
                existing.restageApplicationQueueJsonPath;
            restageApplicationReadmePath =
                existing.restageApplicationReadmePath;
            restageApplicationSourceId = existing.restageApplicationSourceId;
            restageApplicationJobId = existing.restageApplicationJobId;
            restageApplicationReviewItemId =
                existing.restageApplicationReviewItemId;
            restageApplicationResolutionStatus =
                existing.restageApplicationResolutionStatus;
            restageApplicationResolutionArtifactRef =
                existing.restageApplicationResolutionArtifactRef;
            restageApplicationResolutionRationale =
                existing.restageApplicationResolutionRationale;
            restageApplicationResolutionRecordedAt =
                existing.restageApplicationResolutionRecordedAt;
            restageApplyQueueStatus = existing.restageApplyQueueStatus;
            restageApplyQueueJsonPath = existing.restageApplyQueueJsonPath;
            restageApplyReadmePath = existing.restageApplyReadmePath;
            restageApplySourceId = existing.restageApplySourceId;
            restageApplyJobId = existing.restageApplyJobId;
            restageApplyReviewItemId = existing.restageApplyReviewItemId;
            restageApplyResolutionStatus =
                existing.restageApplyResolutionStatus;
            restageApplyResolutionArtifactRef =
                existing.restageApplyResolutionArtifactRef;
            restageApplyResolutionRationale =
                existing.restageApplyResolutionRationale;
            restageApplyResolutionRecordedAt =
                existing.restageApplyResolutionRecordedAt;
            restageServedBasisUpdateQueueStatus =
                existing.restageServedBasisUpdateQueueStatus;
            restageServedBasisUpdateQueueJsonPath =
                existing.restageServedBasisUpdateQueueJsonPath;
            restageServedBasisUpdateReadmePath =
                existing.restageServedBasisUpdateReadmePath;
            restageServedBasisUpdateSourceId =
                existing.restageServedBasisUpdateSourceId;
            restageServedBasisUpdateJobId =
                existing.restageServedBasisUpdateJobId;
            restageServedBasisUpdateReviewItemId =
                existing.restageServedBasisUpdateReviewItemId;
            restageServedBasisUpdateResolutionStatus =
                existing.restageServedBasisUpdateResolutionStatus;
            restageServedBasisUpdateResolutionArtifactRef =
                existing.restageServedBasisUpdateResolutionArtifactRef;
            restageServedBasisUpdateResolutionRationale =
                existing.restageServedBasisUpdateResolutionRationale;
            restageServedBasisUpdateResolutionRecordedAt =
                existing.restageServedBasisUpdateResolutionRecordedAt;
          }
        } on FormatException {
          queuedAt = _nowProvider().toUtc();
        }
      }
      final itemId =
          '${_normalizeToken(servedBasisState.environmentId, separator: '-')}-family-restage-${_normalizeToken(family, separator: '-')}';
      final item = ReplaySimulationLabFamilyRestageReviewItem(
        itemId: itemId,
        environmentId: servedBasisState.environmentId,
        supportedPlaceRef: servedBasisState.supportedPlaceRef,
        evidenceFamily: family,
        restageTarget: restageTarget,
        restageTargetSummary: servedBasisState
                .latestStateEvidenceRestageTargetSummariesByFamily[family]
                ?.trim() ??
            '',
        policyAction: servedBasisState
                .latestStateEvidencePolicyActionsByFamily[family]
                ?.trim() ??
            '',
        policyActionSummary: servedBasisState
                .latestStateEvidencePolicyActionSummariesByFamily[family]
                ?.trim() ??
            '',
        queuedAt: queuedAt,
        queueStatus: queueStatus,
        itemRoot: familyRoot.path,
        itemJsonPath: itemJsonPath,
        readmePath: readmePath,
        servedBasisRef: servedBasisState.servedBasisRef,
        currentBasisStatus: servedBasisState.currentBasisStatus,
        queueDecisionArtifactRef: queueDecisionArtifactRef,
        queueDecisionRationale: queueDecisionRationale,
        queueDecisionRecordedAt: queueDecisionRecordedAt,
        restageIntakeQueueJsonPath: restageIntakeQueueJsonPath,
        restageIntakeReadmePath: restageIntakeReadmePath,
        restageIntakeSourceId: restageIntakeSourceId,
        restageIntakeJobId: restageIntakeJobId,
        restageIntakeReviewItemId: restageIntakeReviewItemId,
        restageIntakeResolutionStatus: restageIntakeResolutionStatus,
        restageIntakeResolutionArtifactRef: restageIntakeResolutionArtifactRef,
        restageIntakeResolutionRationale: restageIntakeResolutionRationale,
        restageIntakeResolutionRecordedAt: restageIntakeResolutionRecordedAt,
        followUpQueueStatus: followUpQueueStatus,
        followUpQueueJsonPath: followUpQueueJsonPath,
        followUpReadmePath: followUpReadmePath,
        followUpSourceId: followUpSourceId,
        followUpJobId: followUpJobId,
        followUpReviewItemId: followUpReviewItemId,
        followUpResolutionStatus: followUpResolutionStatus,
        followUpResolutionArtifactRef: followUpResolutionArtifactRef,
        followUpResolutionRationale: followUpResolutionRationale,
        followUpResolutionRecordedAt: followUpResolutionRecordedAt,
        restageResolutionQueueStatus: restageResolutionQueueStatus,
        restageResolutionQueueJsonPath: restageResolutionQueueJsonPath,
        restageResolutionReadmePath: restageResolutionReadmePath,
        restageResolutionSourceId: restageResolutionSourceId,
        restageResolutionJobId: restageResolutionJobId,
        restageResolutionReviewItemId: restageResolutionReviewItemId,
        restageResolutionResolutionStatus: restageResolutionResolutionStatus,
        restageResolutionResolutionArtifactRef:
            restageResolutionResolutionArtifactRef,
        restageResolutionResolutionRationale:
            restageResolutionResolutionRationale,
        restageResolutionResolutionRecordedAt:
            restageResolutionResolutionRecordedAt,
        restageExecutionQueueStatus: restageExecutionQueueStatus,
        restageExecutionQueueJsonPath: restageExecutionQueueJsonPath,
        restageExecutionReadmePath: restageExecutionReadmePath,
        restageExecutionSourceId: restageExecutionSourceId,
        restageExecutionJobId: restageExecutionJobId,
        restageExecutionReviewItemId: restageExecutionReviewItemId,
        restageExecutionResolutionStatus: restageExecutionResolutionStatus,
        restageExecutionResolutionArtifactRef:
            restageExecutionResolutionArtifactRef,
        restageExecutionResolutionRationale:
            restageExecutionResolutionRationale,
        restageExecutionResolutionRecordedAt:
            restageExecutionResolutionRecordedAt,
        restageApplicationQueueStatus: restageApplicationQueueStatus,
        restageApplicationQueueJsonPath: restageApplicationQueueJsonPath,
        restageApplicationReadmePath: restageApplicationReadmePath,
        restageApplicationSourceId: restageApplicationSourceId,
        restageApplicationJobId: restageApplicationJobId,
        restageApplicationReviewItemId: restageApplicationReviewItemId,
        restageApplicationResolutionStatus: restageApplicationResolutionStatus,
        restageApplicationResolutionArtifactRef:
            restageApplicationResolutionArtifactRef,
        restageApplicationResolutionRationale:
            restageApplicationResolutionRationale,
        restageApplicationResolutionRecordedAt:
            restageApplicationResolutionRecordedAt,
        restageApplyQueueStatus: restageApplyQueueStatus,
        restageApplyQueueJsonPath: restageApplyQueueJsonPath,
        restageApplyReadmePath: restageApplyReadmePath,
        restageApplySourceId: restageApplySourceId,
        restageApplyJobId: restageApplyJobId,
        restageApplyReviewItemId: restageApplyReviewItemId,
        restageApplyResolutionStatus: restageApplyResolutionStatus,
        restageApplyResolutionArtifactRef: restageApplyResolutionArtifactRef,
        restageApplyResolutionRationale: restageApplyResolutionRationale,
        restageApplyResolutionRecordedAt: restageApplyResolutionRecordedAt,
        restageServedBasisUpdateQueueStatus:
            restageServedBasisUpdateQueueStatus,
        restageServedBasisUpdateQueueJsonPath:
            restageServedBasisUpdateQueueJsonPath,
        restageServedBasisUpdateReadmePath: restageServedBasisUpdateReadmePath,
        restageServedBasisUpdateSourceId: restageServedBasisUpdateSourceId,
        restageServedBasisUpdateJobId: restageServedBasisUpdateJobId,
        restageServedBasisUpdateReviewItemId:
            restageServedBasisUpdateReviewItemId,
        restageServedBasisUpdateResolutionStatus:
            restageServedBasisUpdateResolutionStatus,
        restageServedBasisUpdateResolutionArtifactRef:
            restageServedBasisUpdateResolutionArtifactRef,
        restageServedBasisUpdateResolutionRationale:
            restageServedBasisUpdateResolutionRationale,
        restageServedBasisUpdateResolutionRecordedAt:
            restageServedBasisUpdateResolutionRecordedAt,
        cityPackStructuralRef: servedBasisState.cityPackStructuralRef,
        latestStateRefreshReceiptRef:
            servedBasisState.latestStateRefreshReceiptRef,
        latestStateRevalidationReceiptRef:
            servedBasisState.latestStateRevalidationReceiptRef,
        basisRefreshLineageRef: servedBasisState.basisRefreshLineageRef,
      );
      await _writePrettyJson(existingFile, item.toJson());
      await File(readmePath).writeAsString(
        _buildFamilyRestageReviewItemReadme(item),
        flush: true,
      );
      items.add(item);
    }
    items.sort((left, right) => right.queuedAt.compareTo(left.queuedAt));
    return items;
  }

  Future<ReplaySimulationLabFamilyRestageReviewItem>
      requestLabFamilyRestageIntake({
    required String environmentId,
    required String evidenceFamily,
    String rationale = '',
    String ownerUserId = 'admin_operator',
  }) async {
    return _updateLabFamilyRestageReviewItem(
      environmentId: environmentId,
      evidenceFamily: evidenceFamily,
      nextStatus: 'restage_intake_requested',
      rationale: rationale,
      ownerUserId: ownerUserId,
    );
  }

  Future<ReplaySimulationLabFamilyRestageReviewItem>
      deferLabFamilyRestageReview({
    required String environmentId,
    required String evidenceFamily,
    String rationale = '',
  }) async {
    return _updateLabFamilyRestageReviewItem(
      environmentId: environmentId,
      evidenceFamily: evidenceFamily,
      nextStatus: 'watch_family_before_restage',
      rationale: rationale,
    );
  }

  Future<ReplaySimulationLabFamilyRestageReviewItem>
      recordLabFamilyRestageIntakeReviewResolution({
    required String environmentId,
    required String evidenceFamily,
    required String resolutionStatus,
    required String resolutionArtifactRef,
    String rationale = '',
  }) async {
    final normalizedEnvironmentId = environmentId.trim();
    final normalizedFamily = evidenceFamily.trim();
    if (normalizedEnvironmentId.isEmpty || normalizedFamily.isEmpty) {
      throw StateError('Environment id and evidence family are required.');
    }
    final root = await _registeredEnvironmentDirectory(normalizedEnvironmentId);
    final servedBasisState = await getServedBasisState(
      environmentId: normalizedEnvironmentId,
    );
    if (servedBasisState == null) {
      throw StateError(
        'No served-basis state exists for `$normalizedEnvironmentId`.',
      );
    }
    final items = await _syncLabFamilyRestageReviewItems(
      root: root,
      servedBasisState: servedBasisState,
    );
    final matching =
        items.where((entry) => entry.evidenceFamily == normalizedFamily);
    if (matching.isEmpty) {
      throw StateError(
        'No family restage review item exists for `$normalizedFamily` in `$normalizedEnvironmentId`.',
      );
    }
    final existing = matching.first;
    final now = _nowProvider().toUtc();
    final nextStatus = switch (resolutionStatus.trim()) {
      'approved' => 'restage_intake_review_approved',
      'held' => 'restage_intake_review_held',
      _ => throw StateError(
          'Unknown family restage intake resolution `$resolutionStatus`.',
        ),
    };
    ReplaySimulationFamilyRestageFollowUpQueueExport? followUpQueue;
    if (nextStatus == 'restage_intake_review_approved') {
      followUpQueue = await _queueFamilyRestageFollowUpReview(
        item: existing,
        intakeResolutionArtifactRef: resolutionArtifactRef.trim(),
        ownerUserId: 'admin_operator',
      );
    }
    final updated = ReplaySimulationLabFamilyRestageReviewItem(
      itemId: existing.itemId,
      environmentId: existing.environmentId,
      supportedPlaceRef: existing.supportedPlaceRef,
      evidenceFamily: existing.evidenceFamily,
      restageTarget: existing.restageTarget,
      restageTargetSummary: existing.restageTargetSummary,
      policyAction: existing.policyAction,
      policyActionSummary: existing.policyActionSummary,
      queuedAt: existing.queuedAt,
      queueStatus: nextStatus,
      itemRoot: existing.itemRoot,
      itemJsonPath: existing.itemJsonPath,
      readmePath: existing.readmePath,
      servedBasisRef: existing.servedBasisRef,
      currentBasisStatus: existing.currentBasisStatus,
      queueDecisionArtifactRef: existing.queueDecisionArtifactRef,
      queueDecisionRationale: existing.queueDecisionRationale,
      queueDecisionRecordedAt: existing.queueDecisionRecordedAt,
      restageIntakeQueueJsonPath: existing.restageIntakeQueueJsonPath,
      restageIntakeReadmePath: existing.restageIntakeReadmePath,
      restageIntakeSourceId: existing.restageIntakeSourceId,
      restageIntakeJobId: existing.restageIntakeJobId,
      restageIntakeReviewItemId: existing.restageIntakeReviewItemId,
      restageIntakeResolutionStatus: resolutionStatus.trim(),
      restageIntakeResolutionArtifactRef: resolutionArtifactRef.trim(),
      restageIntakeResolutionRationale: rationale.trim().isEmpty
          ? resolutionStatus.trim() == 'approved'
              ? 'Approved bounded family restage intake review for this evidence family.'
              : 'Held bounded family restage intake review pending more evidence.'
          : rationale.trim(),
      restageIntakeResolutionRecordedAt: now,
      followUpQueueStatus:
          followUpQueue?.status ?? existing.followUpQueueStatus,
      followUpQueueJsonPath:
          followUpQueue?.queueJsonPath ?? existing.followUpQueueJsonPath,
      followUpReadmePath:
          followUpQueue?.readmePath ?? existing.followUpReadmePath,
      followUpSourceId: followUpQueue?.sourceId ?? existing.followUpSourceId,
      followUpJobId: followUpQueue?.jobId ?? existing.followUpJobId,
      followUpReviewItemId:
          followUpQueue?.reviewItemId ?? existing.followUpReviewItemId,
      followUpResolutionStatus: existing.followUpResolutionStatus,
      followUpResolutionArtifactRef: existing.followUpResolutionArtifactRef,
      followUpResolutionRationale: existing.followUpResolutionRationale,
      followUpResolutionRecordedAt: existing.followUpResolutionRecordedAt,
      restageResolutionQueueStatus: existing.restageResolutionQueueStatus,
      restageResolutionQueueJsonPath: existing.restageResolutionQueueJsonPath,
      restageResolutionReadmePath: existing.restageResolutionReadmePath,
      restageResolutionSourceId: existing.restageResolutionSourceId,
      restageResolutionJobId: existing.restageResolutionJobId,
      restageResolutionReviewItemId: existing.restageResolutionReviewItemId,
      restageResolutionResolutionStatus:
          existing.restageResolutionResolutionStatus,
      restageResolutionResolutionArtifactRef:
          existing.restageResolutionResolutionArtifactRef,
      restageResolutionResolutionRationale:
          existing.restageResolutionResolutionRationale,
      restageResolutionResolutionRecordedAt:
          existing.restageResolutionResolutionRecordedAt,
      restageExecutionQueueStatus: existing.restageExecutionQueueStatus,
      restageExecutionQueueJsonPath: existing.restageExecutionQueueJsonPath,
      restageExecutionReadmePath: existing.restageExecutionReadmePath,
      restageExecutionSourceId: existing.restageExecutionSourceId,
      restageExecutionJobId: existing.restageExecutionJobId,
      restageExecutionReviewItemId: existing.restageExecutionReviewItemId,
      restageExecutionResolutionStatus:
          existing.restageExecutionResolutionStatus,
      restageExecutionResolutionArtifactRef:
          existing.restageExecutionResolutionArtifactRef,
      restageExecutionResolutionRationale:
          existing.restageExecutionResolutionRationale,
      restageExecutionResolutionRecordedAt:
          existing.restageExecutionResolutionRecordedAt,
      restageApplicationQueueStatus: existing.restageApplicationQueueStatus,
      restageApplicationQueueJsonPath: existing.restageApplicationQueueJsonPath,
      restageApplicationReadmePath: existing.restageApplicationReadmePath,
      restageApplicationSourceId: existing.restageApplicationSourceId,
      restageApplicationJobId: existing.restageApplicationJobId,
      restageApplicationReviewItemId: existing.restageApplicationReviewItemId,
      restageApplicationResolutionStatus:
          existing.restageApplicationResolutionStatus,
      restageApplicationResolutionArtifactRef:
          existing.restageApplicationResolutionArtifactRef,
      restageApplicationResolutionRationale:
          existing.restageApplicationResolutionRationale,
      restageApplicationResolutionRecordedAt:
          existing.restageApplicationResolutionRecordedAt,
      restageApplyQueueStatus: existing.restageApplyQueueStatus,
      restageApplyQueueJsonPath: existing.restageApplyQueueJsonPath,
      restageApplyReadmePath: existing.restageApplyReadmePath,
      restageApplySourceId: existing.restageApplySourceId,
      restageApplyJobId: existing.restageApplyJobId,
      restageApplyReviewItemId: existing.restageApplyReviewItemId,
      restageApplyResolutionStatus: existing.restageApplyResolutionStatus,
      restageApplyResolutionArtifactRef:
          existing.restageApplyResolutionArtifactRef,
      restageApplyResolutionRationale: existing.restageApplyResolutionRationale,
      restageApplyResolutionRecordedAt:
          existing.restageApplyResolutionRecordedAt,
      restageServedBasisUpdateQueueStatus:
          existing.restageServedBasisUpdateQueueStatus,
      restageServedBasisUpdateQueueJsonPath:
          existing.restageServedBasisUpdateQueueJsonPath,
      restageServedBasisUpdateReadmePath:
          existing.restageServedBasisUpdateReadmePath,
      restageServedBasisUpdateSourceId:
          existing.restageServedBasisUpdateSourceId,
      restageServedBasisUpdateJobId: existing.restageServedBasisUpdateJobId,
      restageServedBasisUpdateReviewItemId:
          existing.restageServedBasisUpdateReviewItemId,
      restageServedBasisUpdateResolutionStatus:
          existing.restageServedBasisUpdateResolutionStatus,
      restageServedBasisUpdateResolutionArtifactRef:
          existing.restageServedBasisUpdateResolutionArtifactRef,
      restageServedBasisUpdateResolutionRationale:
          existing.restageServedBasisUpdateResolutionRationale,
      restageServedBasisUpdateResolutionRecordedAt:
          existing.restageServedBasisUpdateResolutionRecordedAt,
      cityPackStructuralRef: existing.cityPackStructuralRef,
      latestStateRefreshReceiptRef: existing.latestStateRefreshReceiptRef,
      latestStateRevalidationReceiptRef:
          existing.latestStateRevalidationReceiptRef,
      basisRefreshLineageRef: existing.basisRefreshLineageRef,
    );
    await _writePrettyJson(File(updated.itemJsonPath), updated.toJson());
    await File(updated.readmePath).writeAsString(
      _buildFamilyRestageReviewItemReadme(updated),
      flush: true,
    );
    return updated;
  }

  Future<ReplaySimulationLabFamilyRestageReviewItem>
      recordLabFamilyRestageFollowUpReviewResolution({
    required String environmentId,
    required String evidenceFamily,
    required String resolutionStatus,
    required String resolutionArtifactRef,
    String rationale = '',
  }) async {
    final normalizedEnvironmentId = environmentId.trim();
    final normalizedFamily = evidenceFamily.trim();
    if (normalizedEnvironmentId.isEmpty || normalizedFamily.isEmpty) {
      throw StateError('Environment id and evidence family are required.');
    }
    final root = await _registeredEnvironmentDirectory(normalizedEnvironmentId);
    final servedBasisState = await getServedBasisState(
      environmentId: normalizedEnvironmentId,
    );
    if (servedBasisState == null) {
      throw StateError(
        'No served-basis state exists for `$normalizedEnvironmentId`.',
      );
    }
    final items = await _syncLabFamilyRestageReviewItems(
      root: root,
      servedBasisState: servedBasisState,
    );
    final matching =
        items.where((entry) => entry.evidenceFamily == normalizedFamily);
    if (matching.isEmpty) {
      throw StateError(
        'No family restage review item exists for `$normalizedFamily` in `$normalizedEnvironmentId`.',
      );
    }
    final existing = matching.first;
    final reviewItemId = existing.followUpReviewItemId?.trim() ?? '';
    if (reviewItemId.isEmpty) {
      throw StateError(
        'No family follow-up review item exists for `$normalizedFamily` in `$normalizedEnvironmentId`.',
      );
    }
    final now = _nowProvider().toUtc();
    final normalizedResolution = switch (resolutionStatus.trim()) {
      'approved' => 'approved',
      'held' => 'held',
      _ => throw StateError(
          'Unknown family restage follow-up resolution `$resolutionStatus`.',
        ),
    };
    ReplaySimulationFamilyRestageResolutionQueueExport? resolutionQueue;
    if (normalizedResolution == 'approved') {
      resolutionQueue = await _queueFamilyRestageResolutionReview(
        item: existing,
        followUpResolutionArtifactRef: resolutionArtifactRef.trim(),
        ownerUserId: 'admin_operator',
      );
    }
    final updated = ReplaySimulationLabFamilyRestageReviewItem(
      itemId: existing.itemId,
      environmentId: existing.environmentId,
      supportedPlaceRef: existing.supportedPlaceRef,
      evidenceFamily: existing.evidenceFamily,
      restageTarget: existing.restageTarget,
      restageTargetSummary: existing.restageTargetSummary,
      policyAction: existing.policyAction,
      policyActionSummary: existing.policyActionSummary,
      queuedAt: existing.queuedAt,
      queueStatus: existing.queueStatus,
      itemRoot: existing.itemRoot,
      itemJsonPath: existing.itemJsonPath,
      readmePath: existing.readmePath,
      servedBasisRef: existing.servedBasisRef,
      currentBasisStatus: existing.currentBasisStatus,
      queueDecisionArtifactRef: existing.queueDecisionArtifactRef,
      queueDecisionRationale: existing.queueDecisionRationale,
      queueDecisionRecordedAt: existing.queueDecisionRecordedAt,
      restageIntakeQueueJsonPath: existing.restageIntakeQueueJsonPath,
      restageIntakeReadmePath: existing.restageIntakeReadmePath,
      restageIntakeSourceId: existing.restageIntakeSourceId,
      restageIntakeJobId: existing.restageIntakeJobId,
      restageIntakeReviewItemId: existing.restageIntakeReviewItemId,
      restageIntakeResolutionStatus: existing.restageIntakeResolutionStatus,
      restageIntakeResolutionArtifactRef:
          existing.restageIntakeResolutionArtifactRef,
      restageIntakeResolutionRationale:
          existing.restageIntakeResolutionRationale,
      restageIntakeResolutionRecordedAt:
          existing.restageIntakeResolutionRecordedAt,
      followUpQueueStatus: existing.followUpQueueStatus,
      followUpQueueJsonPath: existing.followUpQueueJsonPath,
      followUpReadmePath: existing.followUpReadmePath,
      followUpSourceId: existing.followUpSourceId,
      followUpJobId: existing.followUpJobId,
      followUpReviewItemId: existing.followUpReviewItemId,
      followUpResolutionStatus: normalizedResolution,
      followUpResolutionArtifactRef: resolutionArtifactRef.trim(),
      followUpResolutionRationale: rationale.trim().isEmpty
          ? normalizedResolution == 'approved'
              ? 'Approved bounded family restage follow-up review for this evidence family.'
              : 'Held bounded family restage follow-up review pending more evidence.'
          : rationale.trim(),
      followUpResolutionRecordedAt: now,
      restageResolutionQueueStatus:
          resolutionQueue?.status ?? existing.restageResolutionQueueStatus,
      restageResolutionQueueJsonPath: resolutionQueue?.queueJsonPath ??
          existing.restageResolutionQueueJsonPath,
      restageResolutionReadmePath:
          resolutionQueue?.readmePath ?? existing.restageResolutionReadmePath,
      restageResolutionSourceId:
          resolutionQueue?.sourceId ?? existing.restageResolutionSourceId,
      restageResolutionJobId:
          resolutionQueue?.jobId ?? existing.restageResolutionJobId,
      restageResolutionReviewItemId: resolutionQueue?.reviewItemId ??
          existing.restageResolutionReviewItemId,
      restageResolutionResolutionStatus:
          existing.restageResolutionResolutionStatus,
      restageResolutionResolutionArtifactRef:
          existing.restageResolutionResolutionArtifactRef,
      restageResolutionResolutionRationale:
          existing.restageResolutionResolutionRationale,
      restageResolutionResolutionRecordedAt:
          existing.restageResolutionResolutionRecordedAt,
      restageExecutionQueueStatus: existing.restageExecutionQueueStatus,
      restageExecutionQueueJsonPath: existing.restageExecutionQueueJsonPath,
      restageExecutionReadmePath: existing.restageExecutionReadmePath,
      restageExecutionSourceId: existing.restageExecutionSourceId,
      restageExecutionJobId: existing.restageExecutionJobId,
      restageExecutionReviewItemId: existing.restageExecutionReviewItemId,
      restageExecutionResolutionStatus:
          existing.restageExecutionResolutionStatus,
      restageExecutionResolutionArtifactRef:
          existing.restageExecutionResolutionArtifactRef,
      restageExecutionResolutionRationale:
          existing.restageExecutionResolutionRationale,
      restageExecutionResolutionRecordedAt:
          existing.restageExecutionResolutionRecordedAt,
      restageApplicationQueueStatus: existing.restageApplicationQueueStatus,
      restageApplicationQueueJsonPath: existing.restageApplicationQueueJsonPath,
      restageApplicationReadmePath: existing.restageApplicationReadmePath,
      restageApplicationSourceId: existing.restageApplicationSourceId,
      restageApplicationJobId: existing.restageApplicationJobId,
      restageApplicationReviewItemId: existing.restageApplicationReviewItemId,
      restageApplicationResolutionStatus:
          existing.restageApplicationResolutionStatus,
      restageApplicationResolutionArtifactRef:
          existing.restageApplicationResolutionArtifactRef,
      restageApplicationResolutionRationale:
          existing.restageApplicationResolutionRationale,
      restageApplicationResolutionRecordedAt:
          existing.restageApplicationResolutionRecordedAt,
      restageApplyQueueStatus: existing.restageApplyQueueStatus,
      restageApplyQueueJsonPath: existing.restageApplyQueueJsonPath,
      restageApplyReadmePath: existing.restageApplyReadmePath,
      restageApplySourceId: existing.restageApplySourceId,
      restageApplyJobId: existing.restageApplyJobId,
      restageApplyReviewItemId: existing.restageApplyReviewItemId,
      restageApplyResolutionStatus: existing.restageApplyResolutionStatus,
      restageApplyResolutionArtifactRef:
          existing.restageApplyResolutionArtifactRef,
      restageApplyResolutionRationale: existing.restageApplyResolutionRationale,
      restageApplyResolutionRecordedAt:
          existing.restageApplyResolutionRecordedAt,
      restageServedBasisUpdateQueueStatus:
          existing.restageServedBasisUpdateQueueStatus,
      restageServedBasisUpdateQueueJsonPath:
          existing.restageServedBasisUpdateQueueJsonPath,
      restageServedBasisUpdateReadmePath:
          existing.restageServedBasisUpdateReadmePath,
      restageServedBasisUpdateSourceId:
          existing.restageServedBasisUpdateSourceId,
      restageServedBasisUpdateJobId: existing.restageServedBasisUpdateJobId,
      restageServedBasisUpdateReviewItemId:
          existing.restageServedBasisUpdateReviewItemId,
      restageServedBasisUpdateResolutionStatus:
          existing.restageServedBasisUpdateResolutionStatus,
      restageServedBasisUpdateResolutionArtifactRef:
          existing.restageServedBasisUpdateResolutionArtifactRef,
      restageServedBasisUpdateResolutionRationale:
          existing.restageServedBasisUpdateResolutionRationale,
      restageServedBasisUpdateResolutionRecordedAt:
          existing.restageServedBasisUpdateResolutionRecordedAt,
      cityPackStructuralRef: existing.cityPackStructuralRef,
      latestStateRefreshReceiptRef: existing.latestStateRefreshReceiptRef,
      latestStateRevalidationReceiptRef:
          existing.latestStateRevalidationReceiptRef,
      basisRefreshLineageRef: existing.basisRefreshLineageRef,
    );
    await _writePrettyJson(File(updated.itemJsonPath), updated.toJson());
    await File(updated.readmePath).writeAsString(
      _buildFamilyRestageReviewItemReadme(updated),
      flush: true,
    );
    return updated;
  }

  Future<ReplaySimulationLabFamilyRestageReviewItem>
      recordLabFamilyRestageResolutionReviewResolution({
    required String environmentId,
    required String evidenceFamily,
    required String resolutionStatus,
    required String resolutionArtifactRef,
    String rationale = '',
  }) async {
    final normalizedEnvironmentId = environmentId.trim();
    final normalizedFamily = evidenceFamily.trim();
    if (normalizedEnvironmentId.isEmpty || normalizedFamily.isEmpty) {
      throw StateError('Environment id and evidence family are required.');
    }
    final root = await _registeredEnvironmentDirectory(normalizedEnvironmentId);
    final servedBasisState = await getServedBasisState(
      environmentId: normalizedEnvironmentId,
    );
    if (servedBasisState == null) {
      throw StateError(
        'No served-basis state exists for `$normalizedEnvironmentId`.',
      );
    }
    final items = await _syncLabFamilyRestageReviewItems(
      root: root,
      servedBasisState: servedBasisState,
    );
    final matching =
        items.where((entry) => entry.evidenceFamily == normalizedFamily);
    if (matching.isEmpty) {
      throw StateError(
        'No family restage review item exists for `$normalizedFamily` in `$normalizedEnvironmentId`.',
      );
    }
    final existing = matching.first;
    final reviewItemId = existing.restageResolutionReviewItemId?.trim() ?? '';
    if (reviewItemId.isEmpty) {
      throw StateError(
        'No family resolution review item exists for `$normalizedFamily` in `$normalizedEnvironmentId`.',
      );
    }
    final now = _nowProvider().toUtc();
    final normalizedResolutionStatus = resolutionStatus.trim();
    late final String normalizedResolution;
    if (normalizedResolutionStatus == 'approved') {
      normalizedResolution = 'approved_for_bounded_family_restage_execution';
    } else if (normalizedResolutionStatus == 'held') {
      normalizedResolution = 'held_for_more_family_restage_resolution_evidence';
    } else {
      throw StateError(
        'Unknown family restage resolution `$resolutionStatus`.',
      );
    }
    ReplaySimulationFamilyRestageExecutionQueueExport? executionQueue;
    if (normalizedResolution ==
        'approved_for_bounded_family_restage_execution') {
      executionQueue = await _queueFamilyRestageExecutionReview(
        item: existing,
        resolutionReviewOutcomeArtifactRef: resolutionArtifactRef.trim(),
        ownerUserId: 'admin_operator',
      );
    }
    final resolutionRationaleText = rationale.trim().isEmpty
        ? normalizedResolution ==
                'approved_for_bounded_family_restage_execution'
            ? 'Approved bounded family restage resolution review for this evidence family.'
            : 'Held bounded family restage resolution review pending more evidence.'
        : rationale.trim();
    final restageExecutionQueueStatus =
        executionQueue?.status ?? existing.restageExecutionQueueStatus;
    final restageExecutionQueueJsonPath =
        executionQueue?.queueJsonPath ?? existing.restageExecutionQueueJsonPath;
    final restageExecutionReadmePath =
        executionQueue?.readmePath ?? existing.restageExecutionReadmePath;
    final restageExecutionSourceId =
        executionQueue?.sourceId ?? existing.restageExecutionSourceId;
    final restageExecutionJobId =
        executionQueue?.jobId ?? existing.restageExecutionJobId;
    final restageExecutionReviewItemId =
        executionQueue?.reviewItemId ?? existing.restageExecutionReviewItemId;
    final updated = ReplaySimulationLabFamilyRestageReviewItem(
      itemId: existing.itemId,
      environmentId: existing.environmentId,
      supportedPlaceRef: existing.supportedPlaceRef,
      evidenceFamily: existing.evidenceFamily,
      restageTarget: existing.restageTarget,
      restageTargetSummary: existing.restageTargetSummary,
      policyAction: existing.policyAction,
      policyActionSummary: existing.policyActionSummary,
      queuedAt: existing.queuedAt,
      queueStatus: existing.queueStatus,
      itemRoot: existing.itemRoot,
      itemJsonPath: existing.itemJsonPath,
      readmePath: existing.readmePath,
      servedBasisRef: existing.servedBasisRef,
      currentBasisStatus: existing.currentBasisStatus,
      queueDecisionArtifactRef: existing.queueDecisionArtifactRef,
      queueDecisionRationale: existing.queueDecisionRationale,
      queueDecisionRecordedAt: existing.queueDecisionRecordedAt,
      restageIntakeQueueJsonPath: existing.restageIntakeQueueJsonPath,
      restageIntakeReadmePath: existing.restageIntakeReadmePath,
      restageIntakeSourceId: existing.restageIntakeSourceId,
      restageIntakeJobId: existing.restageIntakeJobId,
      restageIntakeReviewItemId: existing.restageIntakeReviewItemId,
      restageIntakeResolutionStatus: existing.restageIntakeResolutionStatus,
      restageIntakeResolutionArtifactRef:
          existing.restageIntakeResolutionArtifactRef,
      restageIntakeResolutionRationale:
          existing.restageIntakeResolutionRationale,
      restageIntakeResolutionRecordedAt:
          existing.restageIntakeResolutionRecordedAt,
      followUpQueueStatus: existing.followUpQueueStatus,
      followUpQueueJsonPath: existing.followUpQueueJsonPath,
      followUpReadmePath: existing.followUpReadmePath,
      followUpSourceId: existing.followUpSourceId,
      followUpJobId: existing.followUpJobId,
      followUpReviewItemId: existing.followUpReviewItemId,
      followUpResolutionStatus: existing.followUpResolutionStatus,
      followUpResolutionArtifactRef: existing.followUpResolutionArtifactRef,
      followUpResolutionRationale: existing.followUpResolutionRationale,
      followUpResolutionRecordedAt: existing.followUpResolutionRecordedAt,
      restageResolutionQueueStatus: existing.restageResolutionQueueStatus,
      restageResolutionQueueJsonPath: existing.restageResolutionQueueJsonPath,
      restageResolutionReadmePath: existing.restageResolutionReadmePath,
      restageResolutionSourceId: existing.restageResolutionSourceId,
      restageResolutionJobId: existing.restageResolutionJobId,
      restageResolutionReviewItemId: existing.restageResolutionReviewItemId,
      restageResolutionResolutionStatus: normalizedResolution,
      restageResolutionResolutionArtifactRef: resolutionArtifactRef.trim(),
      restageResolutionResolutionRationale: resolutionRationaleText,
      restageResolutionResolutionRecordedAt: now,
      restageExecutionQueueStatus: restageExecutionQueueStatus,
      restageExecutionQueueJsonPath: restageExecutionQueueJsonPath,
      restageExecutionReadmePath: restageExecutionReadmePath,
      restageExecutionSourceId: restageExecutionSourceId,
      restageExecutionJobId: restageExecutionJobId,
      restageExecutionReviewItemId: restageExecutionReviewItemId,
      restageExecutionResolutionStatus:
          existing.restageExecutionResolutionStatus,
      restageExecutionResolutionArtifactRef:
          existing.restageExecutionResolutionArtifactRef,
      restageExecutionResolutionRationale:
          existing.restageExecutionResolutionRationale,
      restageExecutionResolutionRecordedAt:
          existing.restageExecutionResolutionRecordedAt,
      cityPackStructuralRef: existing.cityPackStructuralRef,
      latestStateRefreshReceiptRef: existing.latestStateRefreshReceiptRef,
      latestStateRevalidationReceiptRef:
          existing.latestStateRevalidationReceiptRef,
      basisRefreshLineageRef: existing.basisRefreshLineageRef,
    );
    await _writePrettyJson(File(updated.itemJsonPath), updated.toJson());
    await File(updated.readmePath).writeAsString(
      _buildFamilyRestageReviewItemReadme(updated),
      flush: true,
    );
    return updated;
  }

  Future<ReplaySimulationLabFamilyRestageReviewItem>
      recordLabFamilyRestageExecutionReviewResolution({
    required String environmentId,
    required String evidenceFamily,
    required String resolutionStatus,
    required String resolutionArtifactRef,
    String rationale = '',
  }) async {
    final normalizedEnvironmentId = environmentId.trim();
    final normalizedFamily = evidenceFamily.trim();
    if (normalizedEnvironmentId.isEmpty || normalizedFamily.isEmpty) {
      throw StateError('Environment id and evidence family are required.');
    }
    final root = await _registeredEnvironmentDirectory(normalizedEnvironmentId);
    final servedBasisState = await getServedBasisState(
      environmentId: normalizedEnvironmentId,
    );
    if (servedBasisState == null) {
      throw StateError(
        'No served-basis state exists for `$normalizedEnvironmentId`.',
      );
    }
    final items = await _syncLabFamilyRestageReviewItems(
      root: root,
      servedBasisState: servedBasisState,
    );
    final matching =
        items.where((entry) => entry.evidenceFamily == normalizedFamily);
    if (matching.isEmpty) {
      throw StateError(
        'No family restage review item exists for `$normalizedFamily` in `$normalizedEnvironmentId`.',
      );
    }
    final existing = matching.first;
    final reviewItemId = existing.restageExecutionReviewItemId?.trim() ?? '';
    if (reviewItemId.isEmpty) {
      throw StateError(
        'No family execution review item exists for `$normalizedFamily` in `$normalizedEnvironmentId`.',
      );
    }
    final now = _nowProvider().toUtc();
    final normalizedResolution = switch (resolutionStatus.trim()) {
      'approved' => 'approved_for_bounded_family_restage_application',
      'held' => 'held_for_more_family_restage_execution_evidence',
      _ => throw StateError(
          'Unknown family restage execution `$resolutionStatus`.',
        ),
    };
    ReplaySimulationFamilyRestageApplicationQueueExport? applicationQueue;
    if (normalizedResolution ==
        'approved_for_bounded_family_restage_application') {
      applicationQueue = await _queueFamilyRestageApplicationReview(
        item: existing,
        executionReviewOutcomeArtifactRef: resolutionArtifactRef.trim(),
        ownerUserId: 'admin_operator',
      );
    }
    final updated = ReplaySimulationLabFamilyRestageReviewItem(
      itemId: existing.itemId,
      environmentId: existing.environmentId,
      supportedPlaceRef: existing.supportedPlaceRef,
      evidenceFamily: existing.evidenceFamily,
      restageTarget: existing.restageTarget,
      restageTargetSummary: existing.restageTargetSummary,
      policyAction: existing.policyAction,
      policyActionSummary: existing.policyActionSummary,
      queuedAt: existing.queuedAt,
      queueStatus: existing.queueStatus,
      itemRoot: existing.itemRoot,
      itemJsonPath: existing.itemJsonPath,
      readmePath: existing.readmePath,
      servedBasisRef: existing.servedBasisRef,
      currentBasisStatus: existing.currentBasisStatus,
      queueDecisionArtifactRef: existing.queueDecisionArtifactRef,
      queueDecisionRationale: existing.queueDecisionRationale,
      queueDecisionRecordedAt: existing.queueDecisionRecordedAt,
      restageIntakeQueueJsonPath: existing.restageIntakeQueueJsonPath,
      restageIntakeReadmePath: existing.restageIntakeReadmePath,
      restageIntakeSourceId: existing.restageIntakeSourceId,
      restageIntakeJobId: existing.restageIntakeJobId,
      restageIntakeReviewItemId: existing.restageIntakeReviewItemId,
      restageIntakeResolutionStatus: existing.restageIntakeResolutionStatus,
      restageIntakeResolutionArtifactRef:
          existing.restageIntakeResolutionArtifactRef,
      restageIntakeResolutionRationale:
          existing.restageIntakeResolutionRationale,
      restageIntakeResolutionRecordedAt:
          existing.restageIntakeResolutionRecordedAt,
      followUpQueueStatus: existing.followUpQueueStatus,
      followUpQueueJsonPath: existing.followUpQueueJsonPath,
      followUpReadmePath: existing.followUpReadmePath,
      followUpSourceId: existing.followUpSourceId,
      followUpJobId: existing.followUpJobId,
      followUpReviewItemId: existing.followUpReviewItemId,
      followUpResolutionStatus: existing.followUpResolutionStatus,
      followUpResolutionArtifactRef: existing.followUpResolutionArtifactRef,
      followUpResolutionRationale: existing.followUpResolutionRationale,
      followUpResolutionRecordedAt: existing.followUpResolutionRecordedAt,
      restageResolutionQueueStatus: existing.restageResolutionQueueStatus,
      restageResolutionQueueJsonPath: existing.restageResolutionQueueJsonPath,
      restageResolutionReadmePath: existing.restageResolutionReadmePath,
      restageResolutionSourceId: existing.restageResolutionSourceId,
      restageResolutionJobId: existing.restageResolutionJobId,
      restageResolutionReviewItemId: existing.restageResolutionReviewItemId,
      restageResolutionResolutionStatus:
          existing.restageResolutionResolutionStatus,
      restageResolutionResolutionArtifactRef:
          existing.restageResolutionResolutionArtifactRef,
      restageResolutionResolutionRationale:
          existing.restageResolutionResolutionRationale,
      restageResolutionResolutionRecordedAt:
          existing.restageResolutionResolutionRecordedAt,
      restageExecutionQueueStatus: existing.restageExecutionQueueStatus,
      restageExecutionQueueJsonPath: existing.restageExecutionQueueJsonPath,
      restageExecutionReadmePath: existing.restageExecutionReadmePath,
      restageExecutionSourceId: existing.restageExecutionSourceId,
      restageExecutionJobId: existing.restageExecutionJobId,
      restageExecutionReviewItemId: existing.restageExecutionReviewItemId,
      restageExecutionResolutionStatus: normalizedResolution,
      restageExecutionResolutionArtifactRef: resolutionArtifactRef.trim(),
      restageExecutionResolutionRationale: rationale.trim().isEmpty
          ? normalizedResolution ==
                  'approved_for_bounded_family_restage_application'
              ? 'Approved bounded family restage execution review for this evidence family.'
              : 'Held bounded family restage execution review pending more evidence.'
          : rationale.trim(),
      restageExecutionResolutionRecordedAt: now,
      restageApplicationQueueStatus:
          applicationQueue?.status ?? existing.restageApplicationQueueStatus,
      restageApplicationQueueJsonPath: applicationQueue?.queueJsonPath ??
          existing.restageApplicationQueueJsonPath,
      restageApplicationReadmePath:
          applicationQueue?.readmePath ?? existing.restageApplicationReadmePath,
      restageApplicationSourceId:
          applicationQueue?.sourceId ?? existing.restageApplicationSourceId,
      restageApplicationJobId:
          applicationQueue?.jobId ?? existing.restageApplicationJobId,
      restageApplicationReviewItemId: applicationQueue?.reviewItemId ??
          existing.restageApplicationReviewItemId,
      restageApplicationResolutionStatus:
          existing.restageApplicationResolutionStatus,
      restageApplicationResolutionArtifactRef:
          existing.restageApplicationResolutionArtifactRef,
      restageApplicationResolutionRationale:
          existing.restageApplicationResolutionRationale,
      restageApplicationResolutionRecordedAt:
          existing.restageApplicationResolutionRecordedAt,
      cityPackStructuralRef: existing.cityPackStructuralRef,
      latestStateRefreshReceiptRef: existing.latestStateRefreshReceiptRef,
      latestStateRevalidationReceiptRef:
          existing.latestStateRevalidationReceiptRef,
      basisRefreshLineageRef: existing.basisRefreshLineageRef,
    );
    await _writePrettyJson(File(updated.itemJsonPath), updated.toJson());
    await File(updated.readmePath).writeAsString(
      _buildFamilyRestageReviewItemReadme(updated),
      flush: true,
    );
    return updated;
  }

  Future<ReplaySimulationLabFamilyRestageReviewItem>
      recordLabFamilyRestageApplicationReviewResolution({
    required String environmentId,
    required String evidenceFamily,
    required String resolutionStatus,
    required String resolutionArtifactRef,
    String rationale = '',
  }) async {
    final normalizedEnvironmentId = environmentId.trim();
    final normalizedFamily = evidenceFamily.trim();
    if (normalizedEnvironmentId.isEmpty || normalizedFamily.isEmpty) {
      throw StateError('Environment id and evidence family are required.');
    }
    final root = await _registeredEnvironmentDirectory(normalizedEnvironmentId);
    final servedBasisState = await getServedBasisState(
      environmentId: normalizedEnvironmentId,
    );
    if (servedBasisState == null) {
      throw StateError(
        'No served-basis state exists for `$normalizedEnvironmentId`.',
      );
    }
    final items = await _syncLabFamilyRestageReviewItems(
      root: root,
      servedBasisState: servedBasisState,
    );
    final matching =
        items.where((entry) => entry.evidenceFamily == normalizedFamily);
    if (matching.isEmpty) {
      throw StateError(
        'No family restage review item exists for `$normalizedFamily` in `$normalizedEnvironmentId`.',
      );
    }
    final existing = matching.first;
    final reviewItemId = existing.restageApplicationReviewItemId?.trim() ?? '';
    if (reviewItemId.isEmpty) {
      throw StateError(
        'No family application review item exists for `$normalizedFamily` in `$normalizedEnvironmentId`.',
      );
    }
    final now = _nowProvider().toUtc();
    final normalizedResolution = switch (resolutionStatus.trim()) {
      'approved' => 'approved_for_bounded_family_restage_apply_to_served_basis',
      'held' => 'held_for_more_family_restage_application_evidence',
      _ => throw StateError(
          'Unknown family restage application `$resolutionStatus`.',
        ),
    };
    ReplaySimulationFamilyRestageApplyQueueExport? applyQueue;
    if (normalizedResolution ==
        'approved_for_bounded_family_restage_apply_to_served_basis') {
      applyQueue = await _queueFamilyRestageApplyReview(
        item: existing,
        applicationReviewOutcomeArtifactRef: resolutionArtifactRef.trim(),
        ownerUserId: 'admin_operator',
      );
    }
    final updated = ReplaySimulationLabFamilyRestageReviewItem(
      itemId: existing.itemId,
      environmentId: existing.environmentId,
      supportedPlaceRef: existing.supportedPlaceRef,
      evidenceFamily: existing.evidenceFamily,
      restageTarget: existing.restageTarget,
      restageTargetSummary: existing.restageTargetSummary,
      policyAction: existing.policyAction,
      policyActionSummary: existing.policyActionSummary,
      queuedAt: existing.queuedAt,
      queueStatus: existing.queueStatus,
      itemRoot: existing.itemRoot,
      itemJsonPath: existing.itemJsonPath,
      readmePath: existing.readmePath,
      servedBasisRef: existing.servedBasisRef,
      currentBasisStatus: existing.currentBasisStatus,
      queueDecisionArtifactRef: existing.queueDecisionArtifactRef,
      queueDecisionRationale: existing.queueDecisionRationale,
      queueDecisionRecordedAt: existing.queueDecisionRecordedAt,
      restageIntakeQueueJsonPath: existing.restageIntakeQueueJsonPath,
      restageIntakeReadmePath: existing.restageIntakeReadmePath,
      restageIntakeSourceId: existing.restageIntakeSourceId,
      restageIntakeJobId: existing.restageIntakeJobId,
      restageIntakeReviewItemId: existing.restageIntakeReviewItemId,
      restageIntakeResolutionStatus: existing.restageIntakeResolutionStatus,
      restageIntakeResolutionArtifactRef:
          existing.restageIntakeResolutionArtifactRef,
      restageIntakeResolutionRationale:
          existing.restageIntakeResolutionRationale,
      restageIntakeResolutionRecordedAt:
          existing.restageIntakeResolutionRecordedAt,
      followUpQueueStatus: existing.followUpQueueStatus,
      followUpQueueJsonPath: existing.followUpQueueJsonPath,
      followUpReadmePath: existing.followUpReadmePath,
      followUpSourceId: existing.followUpSourceId,
      followUpJobId: existing.followUpJobId,
      followUpReviewItemId: existing.followUpReviewItemId,
      followUpResolutionStatus: existing.followUpResolutionStatus,
      followUpResolutionArtifactRef: existing.followUpResolutionArtifactRef,
      followUpResolutionRationale: existing.followUpResolutionRationale,
      followUpResolutionRecordedAt: existing.followUpResolutionRecordedAt,
      restageResolutionQueueStatus: existing.restageResolutionQueueStatus,
      restageResolutionQueueJsonPath: existing.restageResolutionQueueJsonPath,
      restageResolutionReadmePath: existing.restageResolutionReadmePath,
      restageResolutionSourceId: existing.restageResolutionSourceId,
      restageResolutionJobId: existing.restageResolutionJobId,
      restageResolutionReviewItemId: existing.restageResolutionReviewItemId,
      restageResolutionResolutionStatus:
          existing.restageResolutionResolutionStatus,
      restageResolutionResolutionArtifactRef:
          existing.restageResolutionResolutionArtifactRef,
      restageResolutionResolutionRationale:
          existing.restageResolutionResolutionRationale,
      restageResolutionResolutionRecordedAt:
          existing.restageResolutionResolutionRecordedAt,
      restageExecutionQueueStatus: existing.restageExecutionQueueStatus,
      restageExecutionQueueJsonPath: existing.restageExecutionQueueJsonPath,
      restageExecutionReadmePath: existing.restageExecutionReadmePath,
      restageExecutionSourceId: existing.restageExecutionSourceId,
      restageExecutionJobId: existing.restageExecutionJobId,
      restageExecutionReviewItemId: existing.restageExecutionReviewItemId,
      restageExecutionResolutionStatus:
          existing.restageExecutionResolutionStatus,
      restageExecutionResolutionArtifactRef:
          existing.restageExecutionResolutionArtifactRef,
      restageExecutionResolutionRationale:
          existing.restageExecutionResolutionRationale,
      restageExecutionResolutionRecordedAt:
          existing.restageExecutionResolutionRecordedAt,
      restageApplicationQueueStatus: existing.restageApplicationQueueStatus,
      restageApplicationQueueJsonPath: existing.restageApplicationQueueJsonPath,
      restageApplicationReadmePath: existing.restageApplicationReadmePath,
      restageApplicationSourceId: existing.restageApplicationSourceId,
      restageApplicationJobId: existing.restageApplicationJobId,
      restageApplicationReviewItemId: existing.restageApplicationReviewItemId,
      restageApplicationResolutionStatus: normalizedResolution,
      restageApplicationResolutionArtifactRef: resolutionArtifactRef.trim(),
      restageApplicationResolutionRationale: rationale.trim().isEmpty
          ? normalizedResolution ==
                  'approved_for_bounded_family_restage_apply_to_served_basis'
              ? 'Approved bounded family restage application review for this evidence family.'
              : 'Held bounded family restage application review pending more evidence.'
          : rationale.trim(),
      restageApplicationResolutionRecordedAt: now,
      restageApplyQueueStatus:
          applyQueue?.status ?? existing.restageApplyQueueStatus,
      restageApplyQueueJsonPath:
          applyQueue?.queueJsonPath ?? existing.restageApplyQueueJsonPath,
      restageApplyReadmePath:
          applyQueue?.readmePath ?? existing.restageApplyReadmePath,
      restageApplySourceId:
          applyQueue?.sourceId ?? existing.restageApplySourceId,
      restageApplyJobId: applyQueue?.jobId ?? existing.restageApplyJobId,
      restageApplyReviewItemId:
          applyQueue?.reviewItemId ?? existing.restageApplyReviewItemId,
      restageApplyResolutionStatus: existing.restageApplyResolutionStatus,
      restageApplyResolutionArtifactRef:
          existing.restageApplyResolutionArtifactRef,
      restageApplyResolutionRationale: existing.restageApplyResolutionRationale,
      restageApplyResolutionRecordedAt:
          existing.restageApplyResolutionRecordedAt,
      restageServedBasisUpdateQueueStatus:
          existing.restageServedBasisUpdateQueueStatus,
      restageServedBasisUpdateQueueJsonPath:
          existing.restageServedBasisUpdateQueueJsonPath,
      restageServedBasisUpdateReadmePath:
          existing.restageServedBasisUpdateReadmePath,
      restageServedBasisUpdateSourceId:
          existing.restageServedBasisUpdateSourceId,
      restageServedBasisUpdateJobId: existing.restageServedBasisUpdateJobId,
      restageServedBasisUpdateReviewItemId:
          existing.restageServedBasisUpdateReviewItemId,
      restageServedBasisUpdateResolutionStatus:
          existing.restageServedBasisUpdateResolutionStatus,
      restageServedBasisUpdateResolutionArtifactRef:
          existing.restageServedBasisUpdateResolutionArtifactRef,
      restageServedBasisUpdateResolutionRationale:
          existing.restageServedBasisUpdateResolutionRationale,
      restageServedBasisUpdateResolutionRecordedAt:
          existing.restageServedBasisUpdateResolutionRecordedAt,
      cityPackStructuralRef: existing.cityPackStructuralRef,
      latestStateRefreshReceiptRef: existing.latestStateRefreshReceiptRef,
      latestStateRevalidationReceiptRef:
          existing.latestStateRevalidationReceiptRef,
      basisRefreshLineageRef: existing.basisRefreshLineageRef,
    );
    await _writePrettyJson(File(updated.itemJsonPath), updated.toJson());
    await File(updated.readmePath).writeAsString(
      _buildFamilyRestageReviewItemReadme(updated),
      flush: true,
    );
    return updated;
  }

  Future<ReplaySimulationLabFamilyRestageReviewItem>
      recordLabFamilyRestageApplyReviewResolution({
    required String environmentId,
    required String evidenceFamily,
    required String resolutionStatus,
    required String resolutionArtifactRef,
    String rationale = '',
  }) async {
    final normalizedEnvironmentId = environmentId.trim();
    final normalizedFamily = evidenceFamily.trim();
    if (normalizedEnvironmentId.isEmpty || normalizedFamily.isEmpty) {
      throw StateError('Environment id and evidence family are required.');
    }
    final root = await _registeredEnvironmentDirectory(normalizedEnvironmentId);
    final servedBasisState = await getServedBasisState(
      environmentId: normalizedEnvironmentId,
    );
    if (servedBasisState == null) {
      throw StateError(
        'No served-basis state exists for `$normalizedEnvironmentId`.',
      );
    }
    final items = await _syncLabFamilyRestageReviewItems(
      root: root,
      servedBasisState: servedBasisState,
    );
    final matching =
        items.where((entry) => entry.evidenceFamily == normalizedFamily);
    if (matching.isEmpty) {
      throw StateError(
        'No family restage review item exists for `$normalizedFamily` in `$normalizedEnvironmentId`.',
      );
    }
    final existing = matching.first;
    final reviewItemId = existing.restageApplyReviewItemId?.trim() ?? '';
    if (reviewItemId.isEmpty) {
      throw StateError(
        'No family apply review item exists for `$normalizedFamily` in `$normalizedEnvironmentId`.',
      );
    }
    final now = _nowProvider().toUtc();
    final normalizedResolution = switch (resolutionStatus.trim()) {
      'approved' => 'approved_for_bounded_family_restage_served_basis_update',
      'held' => 'held_for_more_family_restage_apply_evidence',
      _ => throw StateError(
          'Unknown family restage apply `$resolutionStatus`.',
        ),
    };
    ReplaySimulationFamilyRestageServedBasisUpdateQueueExport?
        servedBasisUpdateQueue;
    if (normalizedResolution ==
        'approved_for_bounded_family_restage_served_basis_update') {
      servedBasisUpdateQueue = await _queueFamilyRestageServedBasisUpdateReview(
        item: existing,
        applyReviewOutcomeArtifactRef: resolutionArtifactRef.trim(),
        ownerUserId: 'admin_operator',
      );
    }
    final updated = ReplaySimulationLabFamilyRestageReviewItem(
      itemId: existing.itemId,
      environmentId: existing.environmentId,
      supportedPlaceRef: existing.supportedPlaceRef,
      evidenceFamily: existing.evidenceFamily,
      restageTarget: existing.restageTarget,
      restageTargetSummary: existing.restageTargetSummary,
      policyAction: existing.policyAction,
      policyActionSummary: existing.policyActionSummary,
      queuedAt: existing.queuedAt,
      queueStatus: existing.queueStatus,
      itemRoot: existing.itemRoot,
      itemJsonPath: existing.itemJsonPath,
      readmePath: existing.readmePath,
      servedBasisRef: existing.servedBasisRef,
      currentBasisStatus: existing.currentBasisStatus,
      queueDecisionArtifactRef: existing.queueDecisionArtifactRef,
      queueDecisionRationale: existing.queueDecisionRationale,
      queueDecisionRecordedAt: existing.queueDecisionRecordedAt,
      restageIntakeQueueJsonPath: existing.restageIntakeQueueJsonPath,
      restageIntakeReadmePath: existing.restageIntakeReadmePath,
      restageIntakeSourceId: existing.restageIntakeSourceId,
      restageIntakeJobId: existing.restageIntakeJobId,
      restageIntakeReviewItemId: existing.restageIntakeReviewItemId,
      restageIntakeResolutionStatus: existing.restageIntakeResolutionStatus,
      restageIntakeResolutionArtifactRef:
          existing.restageIntakeResolutionArtifactRef,
      restageIntakeResolutionRationale:
          existing.restageIntakeResolutionRationale,
      restageIntakeResolutionRecordedAt:
          existing.restageIntakeResolutionRecordedAt,
      followUpQueueStatus: existing.followUpQueueStatus,
      followUpQueueJsonPath: existing.followUpQueueJsonPath,
      followUpReadmePath: existing.followUpReadmePath,
      followUpSourceId: existing.followUpSourceId,
      followUpJobId: existing.followUpJobId,
      followUpReviewItemId: existing.followUpReviewItemId,
      followUpResolutionStatus: existing.followUpResolutionStatus,
      followUpResolutionArtifactRef: existing.followUpResolutionArtifactRef,
      followUpResolutionRationale: existing.followUpResolutionRationale,
      followUpResolutionRecordedAt: existing.followUpResolutionRecordedAt,
      restageResolutionQueueStatus: existing.restageResolutionQueueStatus,
      restageResolutionQueueJsonPath: existing.restageResolutionQueueJsonPath,
      restageResolutionReadmePath: existing.restageResolutionReadmePath,
      restageResolutionSourceId: existing.restageResolutionSourceId,
      restageResolutionJobId: existing.restageResolutionJobId,
      restageResolutionReviewItemId: existing.restageResolutionReviewItemId,
      restageResolutionResolutionStatus:
          existing.restageResolutionResolutionStatus,
      restageResolutionResolutionArtifactRef:
          existing.restageResolutionResolutionArtifactRef,
      restageResolutionResolutionRationale:
          existing.restageResolutionResolutionRationale,
      restageResolutionResolutionRecordedAt:
          existing.restageResolutionResolutionRecordedAt,
      restageExecutionQueueStatus: existing.restageExecutionQueueStatus,
      restageExecutionQueueJsonPath: existing.restageExecutionQueueJsonPath,
      restageExecutionReadmePath: existing.restageExecutionReadmePath,
      restageExecutionSourceId: existing.restageExecutionSourceId,
      restageExecutionJobId: existing.restageExecutionJobId,
      restageExecutionReviewItemId: existing.restageExecutionReviewItemId,
      restageExecutionResolutionStatus:
          existing.restageExecutionResolutionStatus,
      restageExecutionResolutionArtifactRef:
          existing.restageExecutionResolutionArtifactRef,
      restageExecutionResolutionRationale:
          existing.restageExecutionResolutionRationale,
      restageExecutionResolutionRecordedAt:
          existing.restageExecutionResolutionRecordedAt,
      restageApplicationQueueStatus: existing.restageApplicationQueueStatus,
      restageApplicationQueueJsonPath: existing.restageApplicationQueueJsonPath,
      restageApplicationReadmePath: existing.restageApplicationReadmePath,
      restageApplicationSourceId: existing.restageApplicationSourceId,
      restageApplicationJobId: existing.restageApplicationJobId,
      restageApplicationReviewItemId: existing.restageApplicationReviewItemId,
      restageApplicationResolutionStatus:
          existing.restageApplicationResolutionStatus,
      restageApplicationResolutionArtifactRef:
          existing.restageApplicationResolutionArtifactRef,
      restageApplicationResolutionRationale:
          existing.restageApplicationResolutionRationale,
      restageApplicationResolutionRecordedAt:
          existing.restageApplicationResolutionRecordedAt,
      restageApplyQueueStatus: existing.restageApplyQueueStatus,
      restageApplyQueueJsonPath: existing.restageApplyQueueJsonPath,
      restageApplyReadmePath: existing.restageApplyReadmePath,
      restageApplySourceId: existing.restageApplySourceId,
      restageApplyJobId: existing.restageApplyJobId,
      restageApplyReviewItemId: existing.restageApplyReviewItemId,
      restageApplyResolutionStatus: normalizedResolution,
      restageApplyResolutionArtifactRef: resolutionArtifactRef.trim(),
      restageApplyResolutionRationale: rationale.trim().isEmpty
          ? normalizedResolution ==
                  'approved_for_bounded_family_restage_served_basis_update'
              ? 'Approved bounded family restage apply review for this evidence family.'
              : 'Held bounded family restage apply review pending more evidence.'
          : rationale.trim(),
      restageApplyResolutionRecordedAt: now,
      restageServedBasisUpdateQueueStatus: servedBasisUpdateQueue?.status ??
          existing.restageServedBasisUpdateQueueStatus,
      restageServedBasisUpdateQueueJsonPath:
          servedBasisUpdateQueue?.queueJsonPath ??
              existing.restageServedBasisUpdateQueueJsonPath,
      restageServedBasisUpdateReadmePath: servedBasisUpdateQueue?.readmePath ??
          existing.restageServedBasisUpdateReadmePath,
      restageServedBasisUpdateSourceId: servedBasisUpdateQueue?.sourceId ??
          existing.restageServedBasisUpdateSourceId,
      restageServedBasisUpdateJobId: servedBasisUpdateQueue?.jobId ??
          existing.restageServedBasisUpdateJobId,
      restageServedBasisUpdateReviewItemId:
          servedBasisUpdateQueue?.reviewItemId ??
              existing.restageServedBasisUpdateReviewItemId,
      cityPackStructuralRef: existing.cityPackStructuralRef,
      latestStateRefreshReceiptRef: existing.latestStateRefreshReceiptRef,
      latestStateRevalidationReceiptRef:
          existing.latestStateRevalidationReceiptRef,
      basisRefreshLineageRef: existing.basisRefreshLineageRef,
    );
    await _writePrettyJson(File(updated.itemJsonPath), updated.toJson());
    await File(updated.readmePath).writeAsString(
      _buildFamilyRestageReviewItemReadme(updated),
      flush: true,
    );
    return updated;
  }

  Future<ReplaySimulationLabFamilyRestageReviewItem>
      recordLabFamilyRestageServedBasisUpdateReviewResolution({
    required String environmentId,
    required String evidenceFamily,
    required String resolutionStatus,
    required String resolutionArtifactRef,
    String rationale = '',
  }) async {
    final normalizedEnvironmentId = environmentId.trim();
    final normalizedFamily = evidenceFamily.trim();
    if (normalizedEnvironmentId.isEmpty || normalizedFamily.isEmpty) {
      throw StateError('Environment id and evidence family are required.');
    }
    final root = await _registeredEnvironmentDirectory(normalizedEnvironmentId);
    final servedBasisState = await getServedBasisState(
      environmentId: normalizedEnvironmentId,
    );
    if (servedBasisState == null) {
      throw StateError(
        'No served-basis state exists for `$normalizedEnvironmentId`.',
      );
    }
    final items = await _syncLabFamilyRestageReviewItems(
      root: root,
      servedBasisState: servedBasisState,
    );
    final matching =
        items.where((entry) => entry.evidenceFamily == normalizedFamily);
    if (matching.isEmpty) {
      throw StateError(
        'No family restage review item exists for `$normalizedFamily` in `$normalizedEnvironmentId`.',
      );
    }
    final existing = matching.first;
    final reviewItemId =
        existing.restageServedBasisUpdateReviewItemId?.trim() ?? '';
    if (reviewItemId.isEmpty) {
      throw StateError(
        'No family served-basis update review item exists for `$normalizedFamily` in `$normalizedEnvironmentId`.',
      );
    }
    final now = _nowProvider().toUtc();
    final normalizedResolution = switch (resolutionStatus.trim()) {
      'approved' => 'approved_for_bounded_family_restage_served_basis_mutation',
      'held' => 'held_for_more_family_restage_served_basis_update_evidence',
      _ => throw StateError(
          'Unknown family restage served-basis update `$resolutionStatus`.',
        ),
    };
    final updated = ReplaySimulationLabFamilyRestageReviewItem(
      itemId: existing.itemId,
      environmentId: existing.environmentId,
      supportedPlaceRef: existing.supportedPlaceRef,
      evidenceFamily: existing.evidenceFamily,
      restageTarget: existing.restageTarget,
      restageTargetSummary: existing.restageTargetSummary,
      policyAction: existing.policyAction,
      policyActionSummary: existing.policyActionSummary,
      queuedAt: existing.queuedAt,
      queueStatus: existing.queueStatus,
      itemRoot: existing.itemRoot,
      itemJsonPath: existing.itemJsonPath,
      readmePath: existing.readmePath,
      servedBasisRef: existing.servedBasisRef,
      currentBasisStatus: existing.currentBasisStatus,
      queueDecisionArtifactRef: existing.queueDecisionArtifactRef,
      queueDecisionRationale: existing.queueDecisionRationale,
      queueDecisionRecordedAt: existing.queueDecisionRecordedAt,
      restageIntakeQueueJsonPath: existing.restageIntakeQueueJsonPath,
      restageIntakeReadmePath: existing.restageIntakeReadmePath,
      restageIntakeSourceId: existing.restageIntakeSourceId,
      restageIntakeJobId: existing.restageIntakeJobId,
      restageIntakeReviewItemId: existing.restageIntakeReviewItemId,
      restageIntakeResolutionStatus: existing.restageIntakeResolutionStatus,
      restageIntakeResolutionArtifactRef:
          existing.restageIntakeResolutionArtifactRef,
      restageIntakeResolutionRationale:
          existing.restageIntakeResolutionRationale,
      restageIntakeResolutionRecordedAt:
          existing.restageIntakeResolutionRecordedAt,
      followUpQueueStatus: existing.followUpQueueStatus,
      followUpQueueJsonPath: existing.followUpQueueJsonPath,
      followUpReadmePath: existing.followUpReadmePath,
      followUpSourceId: existing.followUpSourceId,
      followUpJobId: existing.followUpJobId,
      followUpReviewItemId: existing.followUpReviewItemId,
      followUpResolutionStatus: existing.followUpResolutionStatus,
      followUpResolutionArtifactRef: existing.followUpResolutionArtifactRef,
      followUpResolutionRationale: existing.followUpResolutionRationale,
      followUpResolutionRecordedAt: existing.followUpResolutionRecordedAt,
      restageResolutionQueueStatus: existing.restageResolutionQueueStatus,
      restageResolutionQueueJsonPath: existing.restageResolutionQueueJsonPath,
      restageResolutionReadmePath: existing.restageResolutionReadmePath,
      restageResolutionSourceId: existing.restageResolutionSourceId,
      restageResolutionJobId: existing.restageResolutionJobId,
      restageResolutionReviewItemId: existing.restageResolutionReviewItemId,
      restageResolutionResolutionStatus:
          existing.restageResolutionResolutionStatus,
      restageResolutionResolutionArtifactRef:
          existing.restageResolutionResolutionArtifactRef,
      restageResolutionResolutionRationale:
          existing.restageResolutionResolutionRationale,
      restageResolutionResolutionRecordedAt:
          existing.restageResolutionResolutionRecordedAt,
      restageExecutionQueueStatus: existing.restageExecutionQueueStatus,
      restageExecutionQueueJsonPath: existing.restageExecutionQueueJsonPath,
      restageExecutionReadmePath: existing.restageExecutionReadmePath,
      restageExecutionSourceId: existing.restageExecutionSourceId,
      restageExecutionJobId: existing.restageExecutionJobId,
      restageExecutionReviewItemId: existing.restageExecutionReviewItemId,
      restageExecutionResolutionStatus:
          existing.restageExecutionResolutionStatus,
      restageExecutionResolutionArtifactRef:
          existing.restageExecutionResolutionArtifactRef,
      restageExecutionResolutionRationale:
          existing.restageExecutionResolutionRationale,
      restageExecutionResolutionRecordedAt:
          existing.restageExecutionResolutionRecordedAt,
      restageApplicationQueueStatus: existing.restageApplicationQueueStatus,
      restageApplicationQueueJsonPath: existing.restageApplicationQueueJsonPath,
      restageApplicationReadmePath: existing.restageApplicationReadmePath,
      restageApplicationSourceId: existing.restageApplicationSourceId,
      restageApplicationJobId: existing.restageApplicationJobId,
      restageApplicationReviewItemId: existing.restageApplicationReviewItemId,
      restageApplicationResolutionStatus:
          existing.restageApplicationResolutionStatus,
      restageApplicationResolutionArtifactRef:
          existing.restageApplicationResolutionArtifactRef,
      restageApplicationResolutionRationale:
          existing.restageApplicationResolutionRationale,
      restageApplicationResolutionRecordedAt:
          existing.restageApplicationResolutionRecordedAt,
      restageApplyQueueStatus: existing.restageApplyQueueStatus,
      restageApplyQueueJsonPath: existing.restageApplyQueueJsonPath,
      restageApplyReadmePath: existing.restageApplyReadmePath,
      restageApplySourceId: existing.restageApplySourceId,
      restageApplyJobId: existing.restageApplyJobId,
      restageApplyReviewItemId: existing.restageApplyReviewItemId,
      restageApplyResolutionStatus: existing.restageApplyResolutionStatus,
      restageApplyResolutionArtifactRef:
          existing.restageApplyResolutionArtifactRef,
      restageApplyResolutionRationale: existing.restageApplyResolutionRationale,
      restageApplyResolutionRecordedAt:
          existing.restageApplyResolutionRecordedAt,
      restageServedBasisUpdateQueueStatus:
          existing.restageServedBasisUpdateQueueStatus,
      restageServedBasisUpdateQueueJsonPath:
          existing.restageServedBasisUpdateQueueJsonPath,
      restageServedBasisUpdateReadmePath:
          existing.restageServedBasisUpdateReadmePath,
      restageServedBasisUpdateSourceId:
          existing.restageServedBasisUpdateSourceId,
      restageServedBasisUpdateJobId: existing.restageServedBasisUpdateJobId,
      restageServedBasisUpdateReviewItemId:
          existing.restageServedBasisUpdateReviewItemId,
      restageServedBasisUpdateResolutionStatus: normalizedResolution,
      restageServedBasisUpdateResolutionArtifactRef:
          resolutionArtifactRef.trim(),
      restageServedBasisUpdateResolutionRationale: rationale.trim().isEmpty
          ? normalizedResolution ==
                  'approved_for_bounded_family_restage_served_basis_mutation'
              ? 'Approved bounded family restage served-basis update review for this evidence family.'
              : 'Held bounded family restage served-basis update review pending more evidence.'
          : rationale.trim(),
      restageServedBasisUpdateResolutionRecordedAt: now,
      cityPackStructuralRef: existing.cityPackStructuralRef,
      latestStateRefreshReceiptRef: existing.latestStateRefreshReceiptRef,
      latestStateRevalidationReceiptRef:
          existing.latestStateRevalidationReceiptRef,
      basisRefreshLineageRef: existing.basisRefreshLineageRef,
    );
    await _writePrettyJson(File(updated.itemJsonPath), updated.toJson());
    await File(updated.readmePath).writeAsString(
      _buildFamilyRestageReviewItemReadme(updated),
      flush: true,
    );
    return updated;
  }

  Future<ReplaySimulationLabFamilyRestageReviewItem>
      _updateLabFamilyRestageReviewItem({
    required String environmentId,
    required String evidenceFamily,
    required String nextStatus,
    required String rationale,
    String ownerUserId = 'admin_operator',
  }) async {
    final normalizedEnvironmentId = environmentId.trim();
    final normalizedFamily = evidenceFamily.trim();
    if (normalizedEnvironmentId.isEmpty || normalizedFamily.isEmpty) {
      throw StateError('Environment id and evidence family are required.');
    }
    final root = await _registeredEnvironmentDirectory(normalizedEnvironmentId);
    final servedBasisState = await getServedBasisState(
      environmentId: normalizedEnvironmentId,
    );
    if (servedBasisState == null) {
      throw StateError(
        'No served-basis state exists for `$normalizedEnvironmentId`.',
      );
    }
    final items = await _syncLabFamilyRestageReviewItems(
      root: root,
      servedBasisState: servedBasisState,
    );
    final matching =
        items.where((entry) => entry.evidenceFamily == normalizedFamily);
    if (matching.isEmpty) {
      throw StateError(
        'No family restage review item exists for `$normalizedFamily` in `$normalizedEnvironmentId`.',
      );
    }
    final existing = matching.first;
    final now = _nowProvider().toUtc();
    final decisionFileName = switch (nextStatus) {
      'restage_intake_requested' =>
        'family_restage_review_decision.restage_intake_requested.json',
      'watch_family_before_restage' =>
        'family_restage_review_decision.watch_family_before_restage.json',
      _ =>
        throw StateError('Unknown family restage review status `$nextStatus`.'),
    };
    final relativeRoot = _worldSimulationLabRelativePath(
      'registered_environments',
      normalizedEnvironmentId,
    );
    final artifactRef =
        '$relativeRoot/family_restage_review/$normalizedFamily/$decisionFileName';
    final updated = ReplaySimulationLabFamilyRestageReviewItem(
      itemId: existing.itemId,
      environmentId: existing.environmentId,
      supportedPlaceRef: existing.supportedPlaceRef,
      evidenceFamily: existing.evidenceFamily,
      restageTarget: existing.restageTarget,
      restageTargetSummary: existing.restageTargetSummary,
      policyAction: existing.policyAction,
      policyActionSummary: existing.policyActionSummary,
      queuedAt: existing.queuedAt,
      queueStatus: nextStatus,
      itemRoot: existing.itemRoot,
      itemJsonPath: existing.itemJsonPath,
      readmePath: existing.readmePath,
      servedBasisRef: existing.servedBasisRef,
      currentBasisStatus: existing.currentBasisStatus,
      queueDecisionArtifactRef: artifactRef,
      queueDecisionRationale: rationale.trim().isEmpty
          ? nextStatus == 'restage_intake_requested'
              ? 'Requested bounded restage intake review for this evidence family from World Simulation Lab.'
              : 'Deferred this evidence family into watch posture before requesting bounded restage intake.'
          : rationale.trim(),
      queueDecisionRecordedAt: now,
      restageIntakeResolutionStatus: existing.restageIntakeResolutionStatus,
      restageIntakeResolutionArtifactRef:
          existing.restageIntakeResolutionArtifactRef,
      restageIntakeResolutionRationale:
          existing.restageIntakeResolutionRationale,
      restageIntakeResolutionRecordedAt:
          existing.restageIntakeResolutionRecordedAt,
      followUpQueueStatus: existing.followUpQueueStatus,
      followUpQueueJsonPath: existing.followUpQueueJsonPath,
      followUpReadmePath: existing.followUpReadmePath,
      followUpSourceId: existing.followUpSourceId,
      followUpJobId: existing.followUpJobId,
      followUpReviewItemId: existing.followUpReviewItemId,
      followUpResolutionStatus: existing.followUpResolutionStatus,
      followUpResolutionArtifactRef: existing.followUpResolutionArtifactRef,
      followUpResolutionRationale: existing.followUpResolutionRationale,
      followUpResolutionRecordedAt: existing.followUpResolutionRecordedAt,
      restageResolutionQueueStatus: existing.restageResolutionQueueStatus,
      restageResolutionQueueJsonPath: existing.restageResolutionQueueJsonPath,
      restageResolutionReadmePath: existing.restageResolutionReadmePath,
      restageResolutionSourceId: existing.restageResolutionSourceId,
      restageResolutionJobId: existing.restageResolutionJobId,
      restageResolutionReviewItemId: existing.restageResolutionReviewItemId,
      restageResolutionResolutionStatus:
          existing.restageResolutionResolutionStatus,
      restageResolutionResolutionArtifactRef:
          existing.restageResolutionResolutionArtifactRef,
      restageResolutionResolutionRationale:
          existing.restageResolutionResolutionRationale,
      restageResolutionResolutionRecordedAt:
          existing.restageResolutionResolutionRecordedAt,
      restageExecutionQueueStatus: existing.restageExecutionQueueStatus,
      restageExecutionQueueJsonPath: existing.restageExecutionQueueJsonPath,
      restageExecutionReadmePath: existing.restageExecutionReadmePath,
      restageExecutionSourceId: existing.restageExecutionSourceId,
      restageExecutionJobId: existing.restageExecutionJobId,
      restageExecutionReviewItemId: existing.restageExecutionReviewItemId,
      restageExecutionResolutionStatus:
          existing.restageExecutionResolutionStatus,
      restageExecutionResolutionArtifactRef:
          existing.restageExecutionResolutionArtifactRef,
      restageExecutionResolutionRationale:
          existing.restageExecutionResolutionRationale,
      restageExecutionResolutionRecordedAt:
          existing.restageExecutionResolutionRecordedAt,
      cityPackStructuralRef: existing.cityPackStructuralRef,
      latestStateRefreshReceiptRef: existing.latestStateRefreshReceiptRef,
      latestStateRevalidationReceiptRef:
          existing.latestStateRevalidationReceiptRef,
      basisRefreshLineageRef: existing.basisRefreshLineageRef,
    );
    ReplaySimulationFamilyRestageIntakeQueueExport? intakeQueue;
    if (nextStatus == 'restage_intake_requested') {
      intakeQueue = await _queueFamilyRestageIntakeReview(
        item: updated,
        ownerUserId: ownerUserId,
      );
    }
    final persisted = ReplaySimulationLabFamilyRestageReviewItem(
      itemId: updated.itemId,
      environmentId: updated.environmentId,
      supportedPlaceRef: updated.supportedPlaceRef,
      evidenceFamily: updated.evidenceFamily,
      restageTarget: updated.restageTarget,
      restageTargetSummary: updated.restageTargetSummary,
      policyAction: updated.policyAction,
      policyActionSummary: updated.policyActionSummary,
      queuedAt: updated.queuedAt,
      queueStatus: updated.queueStatus,
      itemRoot: updated.itemRoot,
      itemJsonPath: updated.itemJsonPath,
      readmePath: updated.readmePath,
      servedBasisRef: updated.servedBasisRef,
      currentBasisStatus: updated.currentBasisStatus,
      queueDecisionArtifactRef: updated.queueDecisionArtifactRef,
      queueDecisionRationale: updated.queueDecisionRationale,
      queueDecisionRecordedAt: updated.queueDecisionRecordedAt,
      restageIntakeQueueJsonPath:
          intakeQueue?.queueJsonPath ?? existing.restageIntakeQueueJsonPath,
      restageIntakeReadmePath:
          intakeQueue?.readmePath ?? existing.restageIntakeReadmePath,
      restageIntakeSourceId:
          intakeQueue?.sourceId ?? existing.restageIntakeSourceId,
      restageIntakeJobId: intakeQueue?.jobId ?? existing.restageIntakeJobId,
      restageIntakeReviewItemId:
          intakeQueue?.reviewItemId ?? existing.restageIntakeReviewItemId,
      restageIntakeResolutionStatus: existing.restageIntakeResolutionStatus,
      restageIntakeResolutionArtifactRef:
          existing.restageIntakeResolutionArtifactRef,
      restageIntakeResolutionRationale:
          existing.restageIntakeResolutionRationale,
      restageIntakeResolutionRecordedAt:
          existing.restageIntakeResolutionRecordedAt,
      followUpQueueStatus: existing.followUpQueueStatus,
      followUpQueueJsonPath: existing.followUpQueueJsonPath,
      followUpReadmePath: existing.followUpReadmePath,
      followUpSourceId: existing.followUpSourceId,
      followUpJobId: existing.followUpJobId,
      followUpReviewItemId: existing.followUpReviewItemId,
      followUpResolutionStatus: existing.followUpResolutionStatus,
      followUpResolutionArtifactRef: existing.followUpResolutionArtifactRef,
      followUpResolutionRationale: existing.followUpResolutionRationale,
      followUpResolutionRecordedAt: existing.followUpResolutionRecordedAt,
      restageResolutionQueueStatus: existing.restageResolutionQueueStatus,
      restageResolutionQueueJsonPath: existing.restageResolutionQueueJsonPath,
      restageResolutionReadmePath: existing.restageResolutionReadmePath,
      restageResolutionSourceId: existing.restageResolutionSourceId,
      restageResolutionJobId: existing.restageResolutionJobId,
      restageResolutionReviewItemId: existing.restageResolutionReviewItemId,
      restageResolutionResolutionStatus:
          existing.restageResolutionResolutionStatus,
      restageResolutionResolutionArtifactRef:
          existing.restageResolutionResolutionArtifactRef,
      restageResolutionResolutionRationale:
          existing.restageResolutionResolutionRationale,
      restageResolutionResolutionRecordedAt:
          existing.restageResolutionResolutionRecordedAt,
      restageExecutionQueueStatus: existing.restageExecutionQueueStatus,
      restageExecutionQueueJsonPath: existing.restageExecutionQueueJsonPath,
      restageExecutionReadmePath: existing.restageExecutionReadmePath,
      restageExecutionSourceId: existing.restageExecutionSourceId,
      restageExecutionJobId: existing.restageExecutionJobId,
      restageExecutionReviewItemId: existing.restageExecutionReviewItemId,
      restageExecutionResolutionStatus:
          existing.restageExecutionResolutionStatus,
      restageExecutionResolutionArtifactRef:
          existing.restageExecutionResolutionArtifactRef,
      restageExecutionResolutionRationale:
          existing.restageExecutionResolutionRationale,
      restageExecutionResolutionRecordedAt:
          existing.restageExecutionResolutionRecordedAt,
      restageApplicationQueueStatus: existing.restageApplicationQueueStatus,
      restageApplicationQueueJsonPath: existing.restageApplicationQueueJsonPath,
      restageApplicationReadmePath: existing.restageApplicationReadmePath,
      restageApplicationSourceId: existing.restageApplicationSourceId,
      restageApplicationJobId: existing.restageApplicationJobId,
      restageApplicationReviewItemId: existing.restageApplicationReviewItemId,
      restageApplicationResolutionStatus:
          existing.restageApplicationResolutionStatus,
      restageApplicationResolutionArtifactRef:
          existing.restageApplicationResolutionArtifactRef,
      restageApplicationResolutionRationale:
          existing.restageApplicationResolutionRationale,
      restageApplicationResolutionRecordedAt:
          existing.restageApplicationResolutionRecordedAt,
      restageApplyQueueStatus: existing.restageApplyQueueStatus,
      restageApplyQueueJsonPath: existing.restageApplyQueueJsonPath,
      restageApplyReadmePath: existing.restageApplyReadmePath,
      restageApplySourceId: existing.restageApplySourceId,
      restageApplyJobId: existing.restageApplyJobId,
      restageApplyReviewItemId: existing.restageApplyReviewItemId,
      restageApplyResolutionStatus: existing.restageApplyResolutionStatus,
      restageApplyResolutionArtifactRef:
          existing.restageApplyResolutionArtifactRef,
      restageApplyResolutionRationale: existing.restageApplyResolutionRationale,
      restageApplyResolutionRecordedAt:
          existing.restageApplyResolutionRecordedAt,
      restageServedBasisUpdateQueueStatus:
          existing.restageServedBasisUpdateQueueStatus,
      restageServedBasisUpdateQueueJsonPath:
          existing.restageServedBasisUpdateQueueJsonPath,
      restageServedBasisUpdateReadmePath:
          existing.restageServedBasisUpdateReadmePath,
      restageServedBasisUpdateSourceId:
          existing.restageServedBasisUpdateSourceId,
      restageServedBasisUpdateJobId: existing.restageServedBasisUpdateJobId,
      restageServedBasisUpdateReviewItemId:
          existing.restageServedBasisUpdateReviewItemId,
      restageServedBasisUpdateResolutionStatus:
          existing.restageServedBasisUpdateResolutionStatus,
      restageServedBasisUpdateResolutionArtifactRef:
          existing.restageServedBasisUpdateResolutionArtifactRef,
      restageServedBasisUpdateResolutionRationale:
          existing.restageServedBasisUpdateResolutionRationale,
      restageServedBasisUpdateResolutionRecordedAt:
          existing.restageServedBasisUpdateResolutionRecordedAt,
      cityPackStructuralRef: updated.cityPackStructuralRef,
      latestStateRefreshReceiptRef: updated.latestStateRefreshReceiptRef,
      latestStateRevalidationReceiptRef:
          updated.latestStateRevalidationReceiptRef,
      basisRefreshLineageRef: updated.basisRefreshLineageRef,
    );
    await _writePrettyJson(
      File(path.join(existing.itemRoot, decisionFileName)),
      <String, dynamic>{
        'itemId': persisted.itemId,
        'environmentId': persisted.environmentId,
        'evidenceFamily': persisted.evidenceFamily,
        'queueStatus': persisted.queueStatus,
        'recordedAt': now.toIso8601String(),
        'rationale': persisted.queueDecisionRationale,
        'restageTarget': persisted.restageTarget,
        'restageTargetSummary': persisted.restageTargetSummary,
        'policyAction': persisted.policyAction,
        'policyActionSummary': persisted.policyActionSummary,
        'servedBasisRef': persisted.servedBasisRef,
        if (intakeQueue != null) 'restageIntakeQueue': intakeQueue.toJson(),
      },
    );
    await _writePrettyJson(File(persisted.itemJsonPath), persisted.toJson());
    await File(persisted.readmePath).writeAsString(
      _buildFamilyRestageReviewItemReadme(persisted),
      flush: true,
    );
    return persisted;
  }

  Future<ReplaySimulationFamilyRestageIntakeQueueExport>
      _queueFamilyRestageIntakeReview({
    required ReplaySimulationLabFamilyRestageReviewItem item,
    required String ownerUserId,
  }) async {
    final queuedAt = _nowProvider().toUtc();
    final status = 'queued_for_family_restage_intake_review';
    final queueJsonPath = path.join(
      item.itemRoot,
      'family_restage_intake_review.current.json',
    );
    final readmePath = path.join(
      item.itemRoot,
      'FAMILY_RESTAGE_INTAKE_REVIEW_README.md',
    );
    final stamp = queuedAt.toIso8601String().replaceAll(':', '-');
    final sourceId =
        'family_restage_source_${item.environmentId}_${item.evidenceFamily}_$stamp';
    final jobId =
        'family_restage_job_${item.environmentId}_${item.evidenceFamily}_$stamp';
    final reviewItemId =
        'family_restage_review_${item.environmentId}_${item.evidenceFamily}_$stamp';

    ExternalSourceDescriptor? sourceDescriptor;
    ExternalSyncJob? job;
    OrganizerReviewItem? reviewItem;
    final intakeRepository = _intakeRepository;
    if (intakeRepository != null) {
      sourceDescriptor = ExternalSourceDescriptor(
        id: sourceId,
        ownerUserId: ownerUserId,
        sourceProvider: 'replay_simulation_family_restage_intake',
        sourceUrl: queueJsonPath,
        connectionMode: ExternalConnectionMode.manual,
        entityHint: IntakeEntityType.review,
        sourceLabel:
            '${item.environmentId} ${_describeHydrationEvidenceFamily(item.evidenceFamily)} family restage intake',
        cityCode: item.supportedPlaceRef.replaceFirst('place:', ''),
        isOneWaySync: true,
        isClaimable: false,
        createdAt: queuedAt,
        updatedAt: queuedAt,
        lastSyncedAt: queuedAt,
        syncState: ExternalSyncState.needsReview,
        metadata: <String, dynamic>{
          'environmentId': item.environmentId,
          'supportedPlaceRef': item.supportedPlaceRef,
          'evidenceFamily': item.evidenceFamily,
          'restageTarget': item.restageTarget,
          'restageTargetSummary': item.restageTargetSummary,
          'policyAction': item.policyAction,
          'policyActionSummary': item.policyActionSummary,
          'servedBasisRef': item.servedBasisRef,
          'currentBasisStatus': item.currentBasisStatus,
          'cityPackStructuralRef': item.cityPackStructuralRef,
          'status': status,
          'localOnly': true,
        },
      );
      await intakeRepository.upsertSource(sourceDescriptor);

      job = ExternalSyncJob(
        id: jobId,
        sourceId: sourceId,
        startedAt: queuedAt,
        updatedAt: queuedAt,
        state: ExternalSyncState.needsReview,
        importedCount: 1,
        reviewCount: 1,
      );
      await intakeRepository.upsertJob(job);

      reviewItem = OrganizerReviewItem(
        id: reviewItemId,
        sourceId: sourceId,
        ownerUserId: ownerUserId,
        targetType: IntakeEntityType.review,
        title:
            'Family restage intake review for ${item.environmentId} / ${_describeHydrationEvidenceFamily(item.evidenceFamily)}',
        summary:
            'Evidence family requires bounded restage intake review before the served basis can safely recover.',
        missingFields: const <String>[],
        createdAt: queuedAt,
        payload: <String, dynamic>{
          'environmentId': item.environmentId,
          'supportedPlaceRef': item.supportedPlaceRef,
          'evidenceFamily': item.evidenceFamily,
          'restageTarget': item.restageTarget,
          'restageTargetSummary': item.restageTargetSummary,
          'policyAction': item.policyAction,
          'policyActionSummary': item.policyActionSummary,
          'servedBasisRef': item.servedBasisRef,
          'currentBasisStatus': item.currentBasisStatus,
          'cityPackStructuralRef': item.cityPackStructuralRef,
          'latestStateRefreshReceiptRef': item.latestStateRefreshReceiptRef,
          'latestStateRevalidationReceiptRef':
              item.latestStateRevalidationReceiptRef,
          'basisRefreshLineageRef': item.basisRefreshLineageRef,
          'status': status,
          'localOnly': true,
        },
      );
      await intakeRepository.upsertReviewItem(reviewItem);
    }

    final export = ReplaySimulationFamilyRestageIntakeQueueExport(
      environmentId: item.environmentId,
      evidenceFamily: item.evidenceFamily,
      queueJsonPath: queueJsonPath,
      readmePath: readmePath,
      queuedAt: queuedAt,
      status: status,
      sourceId: sourceDescriptor?.id,
      jobId: job?.id,
      reviewItemId: reviewItem?.id,
    );
    await _writePrettyJson(
      File(queueJsonPath),
      <String, dynamic>{
        'environmentId': item.environmentId,
        'supportedPlaceRef': item.supportedPlaceRef,
        'evidenceFamily': item.evidenceFamily,
        'restageTarget': item.restageTarget,
        'restageTargetSummary': item.restageTargetSummary,
        'policyAction': item.policyAction,
        'policyActionSummary': item.policyActionSummary,
        'servedBasisRef': item.servedBasisRef,
        'currentBasisStatus': item.currentBasisStatus,
        'queuedAt': queuedAt.toIso8601String(),
        'status': status,
        'cityPackStructuralRef': item.cityPackStructuralRef,
        'latestStateRefreshReceiptRef': item.latestStateRefreshReceiptRef,
        'latestStateRevalidationReceiptRef':
            item.latestStateRevalidationReceiptRef,
        'basisRefreshLineageRef': item.basisRefreshLineageRef,
        'sourceDescriptor': sourceDescriptor?.toJson(),
        'job': job?.toJson(),
        'reviewItem': reviewItem?.toJson(),
        'notes': <String>[
          'This bounded intake artifact routes a degraded evidence family into explicit restage review without mutating served-basis state directly.',
        ],
      },
    );
    await File(readmePath).writeAsString(
      _buildFamilyRestageIntakeQueueReadme(
        item: item,
        export: export,
      ),
      flush: true,
    );
    return export;
  }

  Future<ReplaySimulationFamilyRestageFollowUpQueueExport>
      _queueFamilyRestageFollowUpReview({
    required ReplaySimulationLabFamilyRestageReviewItem item,
    required String intakeResolutionArtifactRef,
    required String ownerUserId,
  }) async {
    final queuedAt = _nowProvider().toUtc();
    final status = 'queued_for_family_restage_follow_up_review';
    final queueJsonPath = path.join(
      item.itemRoot,
      'family_restage_follow_up_review.current.json',
    );
    final readmePath = path.join(
      item.itemRoot,
      'FAMILY_RESTAGE_FOLLOW_UP_REVIEW_README.md',
    );
    final stamp = queuedAt.toIso8601String().replaceAll(':', '-');
    final sourceId =
        'family_restage_follow_up_source_${item.environmentId}_${item.evidenceFamily}_$stamp';
    final jobId =
        'family_restage_follow_up_job_${item.environmentId}_${item.evidenceFamily}_$stamp';
    final reviewItemId =
        'family_restage_follow_up_review_${item.environmentId}_${item.evidenceFamily}_$stamp';

    ExternalSourceDescriptor? sourceDescriptor;
    ExternalSyncJob? job;
    OrganizerReviewItem? reviewItem;
    final intakeRepository = _intakeRepository;
    if (intakeRepository != null) {
      sourceDescriptor = ExternalSourceDescriptor(
        id: sourceId,
        ownerUserId: ownerUserId,
        sourceProvider: 'replay_simulation_family_restage_follow_up',
        sourceUrl: queueJsonPath,
        connectionMode: ExternalConnectionMode.manual,
        entityHint: IntakeEntityType.review,
        sourceLabel:
            '${item.environmentId} ${_describeHydrationEvidenceFamily(item.evidenceFamily)} family restage follow-up',
        cityCode: item.supportedPlaceRef.replaceFirst('place:', ''),
        isOneWaySync: true,
        isClaimable: false,
        createdAt: queuedAt,
        updatedAt: queuedAt,
        lastSyncedAt: queuedAt,
        syncState: ExternalSyncState.needsReview,
        metadata: <String, dynamic>{
          'environmentId': item.environmentId,
          'supportedPlaceRef': item.supportedPlaceRef,
          'evidenceFamily': item.evidenceFamily,
          'restageTarget': item.restageTarget,
          'restageTargetSummary': item.restageTargetSummary,
          'policyAction': item.policyAction,
          'policyActionSummary': item.policyActionSummary,
          'servedBasisRef': item.servedBasisRef,
          'currentBasisStatus': item.currentBasisStatus,
          'cityPackStructuralRef': item.cityPackStructuralRef,
          'intakeResolutionArtifactRef': intakeResolutionArtifactRef,
          'status': status,
          'localOnly': true,
        },
      );
      await intakeRepository.upsertSource(sourceDescriptor);

      job = ExternalSyncJob(
        id: jobId,
        sourceId: sourceId,
        startedAt: queuedAt,
        updatedAt: queuedAt,
        state: ExternalSyncState.needsReview,
        importedCount: 1,
        reviewCount: 1,
      );
      await intakeRepository.upsertJob(job);

      reviewItem = OrganizerReviewItem(
        id: reviewItemId,
        sourceId: sourceId,
        ownerUserId: ownerUserId,
        targetType: IntakeEntityType.review,
        title:
            'Family restage follow-up review for ${item.environmentId} / ${_describeHydrationEvidenceFamily(item.evidenceFamily)}',
        summary:
            'Approved family restage intake now needs bounded governed follow-up review before the served basis can recover.',
        missingFields: const <String>[],
        createdAt: queuedAt,
        payload: <String, dynamic>{
          'environmentId': item.environmentId,
          'supportedPlaceRef': item.supportedPlaceRef,
          'evidenceFamily': item.evidenceFamily,
          'restageTarget': item.restageTarget,
          'restageTargetSummary': item.restageTargetSummary,
          'policyAction': item.policyAction,
          'policyActionSummary': item.policyActionSummary,
          'servedBasisRef': item.servedBasisRef,
          'currentBasisStatus': item.currentBasisStatus,
          'cityPackStructuralRef': item.cityPackStructuralRef,
          'latestStateRefreshReceiptRef': item.latestStateRefreshReceiptRef,
          'latestStateRevalidationReceiptRef':
              item.latestStateRevalidationReceiptRef,
          'basisRefreshLineageRef': item.basisRefreshLineageRef,
          'intakeResolutionArtifactRef': intakeResolutionArtifactRef,
          'status': status,
          'localOnly': true,
        },
      );
      await intakeRepository.upsertReviewItem(reviewItem);
    }

    final export = ReplaySimulationFamilyRestageFollowUpQueueExport(
      environmentId: item.environmentId,
      evidenceFamily: item.evidenceFamily,
      queueJsonPath: queueJsonPath,
      readmePath: readmePath,
      queuedAt: queuedAt,
      status: status,
      sourceId: sourceDescriptor?.id,
      jobId: job?.id,
      reviewItemId: reviewItem?.id,
    );
    await _writePrettyJson(
      File(queueJsonPath),
      <String, dynamic>{
        'environmentId': item.environmentId,
        'supportedPlaceRef': item.supportedPlaceRef,
        'evidenceFamily': item.evidenceFamily,
        'restageTarget': item.restageTarget,
        'restageTargetSummary': item.restageTargetSummary,
        'policyAction': item.policyAction,
        'policyActionSummary': item.policyActionSummary,
        'servedBasisRef': item.servedBasisRef,
        'currentBasisStatus': item.currentBasisStatus,
        'queuedAt': queuedAt.toIso8601String(),
        'status': status,
        'cityPackStructuralRef': item.cityPackStructuralRef,
        'latestStateRefreshReceiptRef': item.latestStateRefreshReceiptRef,
        'latestStateRevalidationReceiptRef':
            item.latestStateRevalidationReceiptRef,
        'basisRefreshLineageRef': item.basisRefreshLineageRef,
        'intakeResolutionArtifactRef': intakeResolutionArtifactRef,
        'sourceDescriptor': sourceDescriptor?.toJson(),
        'job': job?.toJson(),
        'reviewItem': reviewItem?.toJson(),
        'notes': <String>[
          'This bounded follow-up artifact exists because the family restage intake review was approved and now requires a canonical governed follow-up review lane.',
        ],
      },
    );
    await File(readmePath).writeAsString(
      _buildFamilyRestageFollowUpQueueReadme(
        item: item,
        export: export,
        intakeResolutionArtifactRef: intakeResolutionArtifactRef,
      ),
      flush: true,
    );
    return export;
  }

  Future<ReplaySimulationFamilyRestageResolutionQueueExport>
      _queueFamilyRestageResolutionReview({
    required ReplaySimulationLabFamilyRestageReviewItem item,
    required String followUpResolutionArtifactRef,
    required String ownerUserId,
  }) async {
    final queuedAt = _nowProvider().toUtc();
    final status = 'queued_for_family_restage_resolution_review';
    final queueJsonPath = path.join(
      item.itemRoot,
      'family_restage_resolution_review.current.json',
    );
    final readmePath = path.join(
      item.itemRoot,
      'FAMILY_RESTAGE_RESOLUTION_REVIEW_README.md',
    );
    final stamp = queuedAt.toIso8601String().replaceAll(':', '-');
    final sourceId =
        'family_restage_resolution_source_${item.environmentId}_${item.evidenceFamily}_$stamp';
    final jobId =
        'family_restage_resolution_job_${item.environmentId}_${item.evidenceFamily}_$stamp';
    final reviewItemId =
        'family_restage_resolution_review_${item.environmentId}_${item.evidenceFamily}_$stamp';

    ExternalSourceDescriptor? sourceDescriptor;
    ExternalSyncJob? job;
    OrganizerReviewItem? reviewItem;
    final intakeRepository = _intakeRepository;
    if (intakeRepository != null) {
      sourceDescriptor = ExternalSourceDescriptor(
        id: sourceId,
        ownerUserId: ownerUserId,
        sourceProvider: 'replay_simulation_family_restage_resolution',
        sourceUrl: queueJsonPath,
        connectionMode: ExternalConnectionMode.manual,
        entityHint: IntakeEntityType.review,
        sourceLabel:
            '${item.environmentId} ${_describeHydrationEvidenceFamily(item.evidenceFamily)} family restage resolution',
        cityCode: item.supportedPlaceRef.replaceFirst('place:', ''),
        isOneWaySync: true,
        isClaimable: false,
        createdAt: queuedAt,
        updatedAt: queuedAt,
        lastSyncedAt: queuedAt,
        syncState: ExternalSyncState.needsReview,
        metadata: <String, dynamic>{
          'environmentId': item.environmentId,
          'supportedPlaceRef': item.supportedPlaceRef,
          'evidenceFamily': item.evidenceFamily,
          'restageTarget': item.restageTarget,
          'restageTargetSummary': item.restageTargetSummary,
          'policyAction': item.policyAction,
          'policyActionSummary': item.policyActionSummary,
          'servedBasisRef': item.servedBasisRef,
          'currentBasisStatus': item.currentBasisStatus,
          'cityPackStructuralRef': item.cityPackStructuralRef,
          'followUpResolutionArtifactRef': followUpResolutionArtifactRef,
          'status': status,
          'localOnly': true,
        },
      );
      await intakeRepository.upsertSource(sourceDescriptor);

      job = ExternalSyncJob(
        id: jobId,
        sourceId: sourceId,
        startedAt: queuedAt,
        updatedAt: queuedAt,
        state: ExternalSyncState.needsReview,
        importedCount: 1,
        reviewCount: 1,
      );
      await intakeRepository.upsertJob(job);

      reviewItem = OrganizerReviewItem(
        id: reviewItemId,
        sourceId: sourceId,
        ownerUserId: ownerUserId,
        targetType: IntakeEntityType.review,
        title:
            'Family restage resolution review for ${item.environmentId} / ${_describeHydrationEvidenceFamily(item.evidenceFamily)}',
        summary:
            'Approved family restage follow-up now needs bounded governed restage-resolution review before any later served-basis recovery step.',
        missingFields: const <String>[],
        createdAt: queuedAt,
        payload: <String, dynamic>{
          'environmentId': item.environmentId,
          'supportedPlaceRef': item.supportedPlaceRef,
          'evidenceFamily': item.evidenceFamily,
          'restageTarget': item.restageTarget,
          'restageTargetSummary': item.restageTargetSummary,
          'policyAction': item.policyAction,
          'policyActionSummary': item.policyActionSummary,
          'servedBasisRef': item.servedBasisRef,
          'currentBasisStatus': item.currentBasisStatus,
          'cityPackStructuralRef': item.cityPackStructuralRef,
          'latestStateRefreshReceiptRef': item.latestStateRefreshReceiptRef,
          'latestStateRevalidationReceiptRef':
              item.latestStateRevalidationReceiptRef,
          'basisRefreshLineageRef': item.basisRefreshLineageRef,
          'followUpResolutionArtifactRef': followUpResolutionArtifactRef,
          'status': status,
          'localOnly': true,
        },
      );
      await intakeRepository.upsertReviewItem(reviewItem);
    }

    final export = ReplaySimulationFamilyRestageResolutionQueueExport(
      environmentId: item.environmentId,
      evidenceFamily: item.evidenceFamily,
      queueJsonPath: queueJsonPath,
      readmePath: readmePath,
      queuedAt: queuedAt,
      status: status,
      sourceId: sourceDescriptor?.id,
      jobId: job?.id,
      reviewItemId: reviewItem?.id,
    );
    await _writePrettyJson(
      File(queueJsonPath),
      <String, dynamic>{
        'environmentId': item.environmentId,
        'supportedPlaceRef': item.supportedPlaceRef,
        'evidenceFamily': item.evidenceFamily,
        'restageTarget': item.restageTarget,
        'restageTargetSummary': item.restageTargetSummary,
        'policyAction': item.policyAction,
        'policyActionSummary': item.policyActionSummary,
        'servedBasisRef': item.servedBasisRef,
        'currentBasisStatus': item.currentBasisStatus,
        'queuedAt': queuedAt.toIso8601String(),
        'status': status,
        'cityPackStructuralRef': item.cityPackStructuralRef,
        'latestStateRefreshReceiptRef': item.latestStateRefreshReceiptRef,
        'latestStateRevalidationReceiptRef':
            item.latestStateRevalidationReceiptRef,
        'basisRefreshLineageRef': item.basisRefreshLineageRef,
        'followUpResolutionArtifactRef': followUpResolutionArtifactRef,
        'sourceDescriptor': sourceDescriptor?.toJson(),
        'job': job?.toJson(),
        'reviewItem': reviewItem?.toJson(),
        'notes': <String>[
          'This bounded resolution artifact exists because the family restage follow-up review was approved and now requires a canonical governed restage-resolution lane.',
        ],
      },
    );
    await File(readmePath).writeAsString(
      _buildFamilyRestageResolutionQueueReadme(
        item: item,
        export: export,
        followUpResolutionArtifactRef: followUpResolutionArtifactRef,
      ),
      flush: true,
    );
    return export;
  }

  Future<ReplaySimulationFamilyRestageExecutionQueueExport>
      _queueFamilyRestageExecutionReview({
    required ReplaySimulationLabFamilyRestageReviewItem item,
    required String resolutionReviewOutcomeArtifactRef,
    required String ownerUserId,
  }) async {
    final queuedAt = _nowProvider().toUtc();
    final status = 'queued_for_family_restage_execution_review';
    final queueJsonPath = path.join(
      item.itemRoot,
      'family_restage_execution_review.current.json',
    );
    final readmePath = path.join(
      item.itemRoot,
      'FAMILY_RESTAGE_EXECUTION_REVIEW_README.md',
    );
    final stamp = queuedAt.toIso8601String().replaceAll(':', '-');
    final sourceId =
        'family_restage_execution_source_${item.environmentId}_${item.evidenceFamily}_$stamp';
    final jobId =
        'family_restage_execution_job_${item.environmentId}_${item.evidenceFamily}_$stamp';
    final reviewItemId =
        'family_restage_execution_review_${item.environmentId}_${item.evidenceFamily}_$stamp';

    ExternalSourceDescriptor? sourceDescriptor;
    ExternalSyncJob? job;
    OrganizerReviewItem? reviewItem;
    final intakeRepository = _intakeRepository;
    if (intakeRepository != null) {
      sourceDescriptor = ExternalSourceDescriptor(
        id: sourceId,
        ownerUserId: ownerUserId,
        sourceProvider: 'replay_simulation_family_restage_execution',
        sourceUrl: queueJsonPath,
        connectionMode: ExternalConnectionMode.manual,
        entityHint: IntakeEntityType.review,
        sourceLabel:
            '${item.environmentId} ${_describeHydrationEvidenceFamily(item.evidenceFamily)} family restage execution',
        cityCode: item.supportedPlaceRef.replaceFirst('place:', ''),
        isOneWaySync: true,
        isClaimable: false,
        createdAt: queuedAt,
        updatedAt: queuedAt,
        lastSyncedAt: queuedAt,
        syncState: ExternalSyncState.needsReview,
        metadata: <String, dynamic>{
          'environmentId': item.environmentId,
          'supportedPlaceRef': item.supportedPlaceRef,
          'evidenceFamily': item.evidenceFamily,
          'restageTarget': item.restageTarget,
          'restageTargetSummary': item.restageTargetSummary,
          'policyAction': item.policyAction,
          'policyActionSummary': item.policyActionSummary,
          'servedBasisRef': item.servedBasisRef,
          'currentBasisStatus': item.currentBasisStatus,
          'cityPackStructuralRef': item.cityPackStructuralRef,
          'resolutionReviewOutcomeArtifactRef':
              resolutionReviewOutcomeArtifactRef,
          'status': status,
          'localOnly': true,
        },
      );
      await intakeRepository.upsertSource(sourceDescriptor);

      job = ExternalSyncJob(
        id: jobId,
        sourceId: sourceId,
        startedAt: queuedAt,
        updatedAt: queuedAt,
        state: ExternalSyncState.needsReview,
        importedCount: 1,
        reviewCount: 1,
      );
      await intakeRepository.upsertJob(job);

      reviewItem = OrganizerReviewItem(
        id: reviewItemId,
        sourceId: sourceId,
        ownerUserId: ownerUserId,
        targetType: IntakeEntityType.review,
        title:
            'Family restage execution review for ${item.environmentId} / ${_describeHydrationEvidenceFamily(item.evidenceFamily)}',
        summary:
            'Approved family restage resolution now needs bounded governed restage-execution review before any later mutation step.',
        missingFields: const <String>[],
        createdAt: queuedAt,
        payload: <String, dynamic>{
          'environmentId': item.environmentId,
          'supportedPlaceRef': item.supportedPlaceRef,
          'evidenceFamily': item.evidenceFamily,
          'restageTarget': item.restageTarget,
          'restageTargetSummary': item.restageTargetSummary,
          'policyAction': item.policyAction,
          'policyActionSummary': item.policyActionSummary,
          'servedBasisRef': item.servedBasisRef,
          'currentBasisStatus': item.currentBasisStatus,
          'cityPackStructuralRef': item.cityPackStructuralRef,
          'latestStateRefreshReceiptRef': item.latestStateRefreshReceiptRef,
          'latestStateRevalidationReceiptRef':
              item.latestStateRevalidationReceiptRef,
          'basisRefreshLineageRef': item.basisRefreshLineageRef,
          'resolutionReviewOutcomeArtifactRef':
              resolutionReviewOutcomeArtifactRef,
          'status': status,
          'localOnly': true,
        },
      );
      await intakeRepository.upsertReviewItem(reviewItem);
    }

    final export = ReplaySimulationFamilyRestageExecutionQueueExport(
      environmentId: item.environmentId,
      evidenceFamily: item.evidenceFamily,
      queueJsonPath: queueJsonPath,
      readmePath: readmePath,
      queuedAt: queuedAt,
      status: status,
      sourceId: sourceDescriptor?.id,
      jobId: job?.id,
      reviewItemId: reviewItem?.id,
    );
    await _writePrettyJson(
      File(queueJsonPath),
      <String, dynamic>{
        'environmentId': item.environmentId,
        'supportedPlaceRef': item.supportedPlaceRef,
        'evidenceFamily': item.evidenceFamily,
        'restageTarget': item.restageTarget,
        'restageTargetSummary': item.restageTargetSummary,
        'policyAction': item.policyAction,
        'policyActionSummary': item.policyActionSummary,
        'servedBasisRef': item.servedBasisRef,
        'currentBasisStatus': item.currentBasisStatus,
        'queuedAt': queuedAt.toIso8601String(),
        'status': status,
        'cityPackStructuralRef': item.cityPackStructuralRef,
        'latestStateRefreshReceiptRef': item.latestStateRefreshReceiptRef,
        'latestStateRevalidationReceiptRef':
            item.latestStateRevalidationReceiptRef,
        'basisRefreshLineageRef': item.basisRefreshLineageRef,
        'resolutionReviewOutcomeArtifactRef':
            resolutionReviewOutcomeArtifactRef,
        'sourceDescriptor': sourceDescriptor?.toJson(),
        'job': job?.toJson(),
        'reviewItem': reviewItem?.toJson(),
        'notes': <String>[
          'This bounded execution artifact exists because the family restage resolution review was approved and the family may now proceed into its explicit governed restage-execution lane.',
        ],
      },
    );
    await File(readmePath).writeAsString(
      _buildFamilyRestageExecutionQueueReadme(
        item: item,
        export: export,
        resolutionReviewOutcomeArtifactRef: resolutionReviewOutcomeArtifactRef,
      ),
      flush: true,
    );
    return export;
  }

  Future<ReplaySimulationFamilyRestageApplicationQueueExport>
      _queueFamilyRestageApplicationReview({
    required ReplaySimulationLabFamilyRestageReviewItem item,
    required String executionReviewOutcomeArtifactRef,
    required String ownerUserId,
  }) async {
    final queuedAt = _nowProvider().toUtc();
    final status = 'queued_for_family_restage_application_review';
    final queueJsonPath = path.join(
      item.itemRoot,
      'family_restage_application_review.current.json',
    );
    final readmePath = path.join(
      item.itemRoot,
      'FAMILY_RESTAGE_APPLICATION_REVIEW_README.md',
    );
    final stamp = queuedAt.toIso8601String().replaceAll(':', '-');
    final sourceId =
        'family_restage_application_source_${item.environmentId}_${item.evidenceFamily}_$stamp';
    final jobId =
        'family_restage_application_job_${item.environmentId}_${item.evidenceFamily}_$stamp';
    final reviewItemId =
        'family_restage_application_review_${item.environmentId}_${item.evidenceFamily}_$stamp';

    ExternalSourceDescriptor? sourceDescriptor;
    ExternalSyncJob? job;
    OrganizerReviewItem? reviewItem;
    final intakeRepository = _intakeRepository;
    if (intakeRepository != null) {
      sourceDescriptor = ExternalSourceDescriptor(
        id: sourceId,
        ownerUserId: ownerUserId,
        sourceProvider: 'replay_simulation_family_restage_application',
        sourceUrl: queueJsonPath,
        connectionMode: ExternalConnectionMode.manual,
        entityHint: IntakeEntityType.review,
        sourceLabel:
            '${item.environmentId} ${_describeHydrationEvidenceFamily(item.evidenceFamily)} family restage application',
        cityCode: item.supportedPlaceRef.replaceFirst('place:', ''),
        isOneWaySync: true,
        isClaimable: false,
        createdAt: queuedAt,
        updatedAt: queuedAt,
        lastSyncedAt: queuedAt,
        syncState: ExternalSyncState.needsReview,
        metadata: <String, dynamic>{
          'environmentId': item.environmentId,
          'supportedPlaceRef': item.supportedPlaceRef,
          'evidenceFamily': item.evidenceFamily,
          'restageTarget': item.restageTarget,
          'restageTargetSummary': item.restageTargetSummary,
          'policyAction': item.policyAction,
          'policyActionSummary': item.policyActionSummary,
          'servedBasisRef': item.servedBasisRef,
          'currentBasisStatus': item.currentBasisStatus,
          'cityPackStructuralRef': item.cityPackStructuralRef,
          'executionReviewOutcomeArtifactRef':
              executionReviewOutcomeArtifactRef,
          'status': status,
          'localOnly': true,
        },
      );
      await intakeRepository.upsertSource(sourceDescriptor);

      job = ExternalSyncJob(
        id: jobId,
        sourceId: sourceId,
        startedAt: queuedAt,
        updatedAt: queuedAt,
        state: ExternalSyncState.needsReview,
        importedCount: 1,
        reviewCount: 1,
      );
      await intakeRepository.upsertJob(job);

      reviewItem = OrganizerReviewItem(
        id: reviewItemId,
        sourceId: sourceId,
        ownerUserId: ownerUserId,
        targetType: IntakeEntityType.review,
        title:
            'Family restage application review for ${item.environmentId} / ${_describeHydrationEvidenceFamily(item.evidenceFamily)}',
        summary:
            'Approved family restage execution now needs bounded governed restage-application review before any later mutation step.',
        missingFields: const <String>[],
        createdAt: queuedAt,
        payload: <String, dynamic>{
          'environmentId': item.environmentId,
          'supportedPlaceRef': item.supportedPlaceRef,
          'evidenceFamily': item.evidenceFamily,
          'restageTarget': item.restageTarget,
          'restageTargetSummary': item.restageTargetSummary,
          'policyAction': item.policyAction,
          'policyActionSummary': item.policyActionSummary,
          'servedBasisRef': item.servedBasisRef,
          'currentBasisStatus': item.currentBasisStatus,
          'cityPackStructuralRef': item.cityPackStructuralRef,
          'latestStateRefreshReceiptRef': item.latestStateRefreshReceiptRef,
          'latestStateRevalidationReceiptRef':
              item.latestStateRevalidationReceiptRef,
          'basisRefreshLineageRef': item.basisRefreshLineageRef,
          'executionReviewOutcomeArtifactRef':
              executionReviewOutcomeArtifactRef,
          'status': status,
          'localOnly': true,
        },
      );
      await intakeRepository.upsertReviewItem(reviewItem);
    }

    final export = ReplaySimulationFamilyRestageApplicationQueueExport(
      environmentId: item.environmentId,
      evidenceFamily: item.evidenceFamily,
      queueJsonPath: queueJsonPath,
      readmePath: readmePath,
      queuedAt: queuedAt,
      status: status,
      sourceId: sourceDescriptor?.id,
      jobId: job?.id,
      reviewItemId: reviewItem?.id,
    );
    await _writePrettyJson(
      File(queueJsonPath),
      <String, dynamic>{
        'environmentId': item.environmentId,
        'supportedPlaceRef': item.supportedPlaceRef,
        'evidenceFamily': item.evidenceFamily,
        'restageTarget': item.restageTarget,
        'restageTargetSummary': item.restageTargetSummary,
        'policyAction': item.policyAction,
        'policyActionSummary': item.policyActionSummary,
        'servedBasisRef': item.servedBasisRef,
        'currentBasisStatus': item.currentBasisStatus,
        'queuedAt': queuedAt.toIso8601String(),
        'status': status,
        'cityPackStructuralRef': item.cityPackStructuralRef,
        'latestStateRefreshReceiptRef': item.latestStateRefreshReceiptRef,
        'latestStateRevalidationReceiptRef':
            item.latestStateRevalidationReceiptRef,
        'basisRefreshLineageRef': item.basisRefreshLineageRef,
        'executionReviewOutcomeArtifactRef': executionReviewOutcomeArtifactRef,
        'sourceDescriptor': sourceDescriptor?.toJson(),
        'job': job?.toJson(),
        'reviewItem': reviewItem?.toJson(),
        'notes': <String>[
          'This bounded application artifact exists because the family restage execution review was approved and the family may now proceed into its explicit governed restage-application lane.',
        ],
      },
    );
    await File(readmePath).writeAsString(
      _buildFamilyRestageApplicationQueueReadme(
        item: item,
        export: export,
        executionReviewOutcomeArtifactRef: executionReviewOutcomeArtifactRef,
      ),
      flush: true,
    );
    return export;
  }

  Future<ReplaySimulationFamilyRestageApplyQueueExport>
      _queueFamilyRestageApplyReview({
    required ReplaySimulationLabFamilyRestageReviewItem item,
    required String applicationReviewOutcomeArtifactRef,
    required String ownerUserId,
  }) async {
    final queuedAt = _nowProvider().toUtc();
    final status = 'queued_for_family_restage_apply_review';
    final queueJsonPath = path.join(
      item.itemRoot,
      'family_restage_apply_review.current.json',
    );
    final readmePath = path.join(
      item.itemRoot,
      'FAMILY_RESTAGE_APPLY_REVIEW_README.md',
    );
    final stamp = queuedAt.toIso8601String().replaceAll(':', '-');
    final sourceId =
        'family_restage_apply_source_${item.environmentId}_${item.evidenceFamily}_$stamp';
    final jobId =
        'family_restage_apply_job_${item.environmentId}_${item.evidenceFamily}_$stamp';
    final reviewItemId =
        'family_restage_apply_review_${item.environmentId}_${item.evidenceFamily}_$stamp';

    ExternalSourceDescriptor? sourceDescriptor;
    ExternalSyncJob? job;
    OrganizerReviewItem? reviewItem;
    final intakeRepository = _intakeRepository;
    if (intakeRepository != null) {
      sourceDescriptor = ExternalSourceDescriptor(
        id: sourceId,
        ownerUserId: ownerUserId,
        sourceProvider: 'replay_simulation_family_restage_apply',
        sourceUrl: queueJsonPath,
        connectionMode: ExternalConnectionMode.manual,
        entityHint: IntakeEntityType.review,
        sourceLabel:
            '${item.environmentId} ${_describeHydrationEvidenceFamily(item.evidenceFamily)} family restage apply',
        cityCode: item.supportedPlaceRef.replaceFirst('place:', ''),
        isOneWaySync: true,
        isClaimable: false,
        createdAt: queuedAt,
        updatedAt: queuedAt,
        lastSyncedAt: queuedAt,
        syncState: ExternalSyncState.needsReview,
        metadata: <String, dynamic>{
          'environmentId': item.environmentId,
          'supportedPlaceRef': item.supportedPlaceRef,
          'evidenceFamily': item.evidenceFamily,
          'restageTarget': item.restageTarget,
          'restageTargetSummary': item.restageTargetSummary,
          'policyAction': item.policyAction,
          'policyActionSummary': item.policyActionSummary,
          'servedBasisRef': item.servedBasisRef,
          'currentBasisStatus': item.currentBasisStatus,
          'cityPackStructuralRef': item.cityPackStructuralRef,
          'applicationReviewOutcomeArtifactRef':
              applicationReviewOutcomeArtifactRef,
          'status': status,
          'localOnly': true,
        },
      );
      await intakeRepository.upsertSource(sourceDescriptor);

      job = ExternalSyncJob(
        id: jobId,
        sourceId: sourceId,
        startedAt: queuedAt,
        updatedAt: queuedAt,
        state: ExternalSyncState.needsReview,
        importedCount: 1,
        reviewCount: 1,
      );
      await intakeRepository.upsertJob(job);

      reviewItem = OrganizerReviewItem(
        id: reviewItemId,
        sourceId: sourceId,
        ownerUserId: ownerUserId,
        targetType: IntakeEntityType.review,
        title:
            'Family restage apply review for ${item.environmentId} / ${_describeHydrationEvidenceFamily(item.evidenceFamily)}',
        summary:
            'Approved family restage application now needs bounded governed restage-apply review before any later served-basis mutation step.',
        missingFields: const <String>[],
        createdAt: queuedAt,
        payload: <String, dynamic>{
          'environmentId': item.environmentId,
          'supportedPlaceRef': item.supportedPlaceRef,
          'evidenceFamily': item.evidenceFamily,
          'restageTarget': item.restageTarget,
          'restageTargetSummary': item.restageTargetSummary,
          'policyAction': item.policyAction,
          'policyActionSummary': item.policyActionSummary,
          'servedBasisRef': item.servedBasisRef,
          'currentBasisStatus': item.currentBasisStatus,
          'cityPackStructuralRef': item.cityPackStructuralRef,
          'latestStateRefreshReceiptRef': item.latestStateRefreshReceiptRef,
          'latestStateRevalidationReceiptRef':
              item.latestStateRevalidationReceiptRef,
          'basisRefreshLineageRef': item.basisRefreshLineageRef,
          'applicationReviewOutcomeArtifactRef':
              applicationReviewOutcomeArtifactRef,
          'status': status,
          'localOnly': true,
        },
      );
      await intakeRepository.upsertReviewItem(reviewItem);
    }

    final export = ReplaySimulationFamilyRestageApplyQueueExport(
      environmentId: item.environmentId,
      evidenceFamily: item.evidenceFamily,
      queueJsonPath: queueJsonPath,
      readmePath: readmePath,
      queuedAt: queuedAt,
      status: status,
      sourceId: sourceDescriptor?.id,
      jobId: job?.id,
      reviewItemId: reviewItem?.id,
    );
    await _writePrettyJson(
      File(queueJsonPath),
      <String, dynamic>{
        'environmentId': item.environmentId,
        'supportedPlaceRef': item.supportedPlaceRef,
        'evidenceFamily': item.evidenceFamily,
        'restageTarget': item.restageTarget,
        'restageTargetSummary': item.restageTargetSummary,
        'policyAction': item.policyAction,
        'policyActionSummary': item.policyActionSummary,
        'servedBasisRef': item.servedBasisRef,
        'currentBasisStatus': item.currentBasisStatus,
        'queuedAt': queuedAt.toIso8601String(),
        'status': status,
        'cityPackStructuralRef': item.cityPackStructuralRef,
        'latestStateRefreshReceiptRef': item.latestStateRefreshReceiptRef,
        'latestStateRevalidationReceiptRef':
            item.latestStateRevalidationReceiptRef,
        'basisRefreshLineageRef': item.basisRefreshLineageRef,
        'applicationReviewOutcomeArtifactRef':
            applicationReviewOutcomeArtifactRef,
        'sourceDescriptor': sourceDescriptor?.toJson(),
        'job': job?.toJson(),
        'reviewItem': reviewItem?.toJson(),
        'notes': <String>[
          'This bounded apply artifact exists because the family restage application review was approved and the family may now proceed into its explicit governed restage-apply lane.',
        ],
      },
    );
    await File(readmePath).writeAsString(
      _buildFamilyRestageApplyQueueReadme(
        item: item,
        export: export,
        applicationReviewOutcomeArtifactRef:
            applicationReviewOutcomeArtifactRef,
      ),
      flush: true,
    );
    return export;
  }

  Future<ReplaySimulationFamilyRestageServedBasisUpdateQueueExport>
      _queueFamilyRestageServedBasisUpdateReview({
    required ReplaySimulationLabFamilyRestageReviewItem item,
    required String applyReviewOutcomeArtifactRef,
    required String ownerUserId,
  }) async {
    final queuedAt = _nowProvider().toUtc();
    final status = 'queued_for_family_restage_served_basis_update_review';
    final queueJsonPath = path.join(
      item.itemRoot,
      'family_restage_served_basis_update_review.current.json',
    );
    final readmePath = path.join(
      item.itemRoot,
      'FAMILY_RESTAGE_SERVED_BASIS_UPDATE_REVIEW_README.md',
    );
    final stamp = queuedAt.toIso8601String().replaceAll(':', '-');
    final sourceId =
        'family_restage_served_basis_update_source_${item.environmentId}_${item.evidenceFamily}_$stamp';
    final jobId =
        'family_restage_served_basis_update_job_${item.environmentId}_${item.evidenceFamily}_$stamp';
    final reviewItemId =
        'family_restage_served_basis_update_review_${item.environmentId}_${item.evidenceFamily}_$stamp';

    ExternalSourceDescriptor? sourceDescriptor;
    ExternalSyncJob? job;
    OrganizerReviewItem? reviewItem;
    final intakeRepository = _intakeRepository;
    if (intakeRepository != null) {
      sourceDescriptor = ExternalSourceDescriptor(
        id: sourceId,
        ownerUserId: ownerUserId,
        sourceProvider: 'replay_simulation_family_restage_served_basis_update',
        sourceUrl: queueJsonPath,
        connectionMode: ExternalConnectionMode.manual,
        entityHint: IntakeEntityType.review,
        sourceLabel:
            '${item.environmentId} ${_describeHydrationEvidenceFamily(item.evidenceFamily)} family restage served basis update',
        cityCode: item.supportedPlaceRef.replaceFirst('place:', ''),
        isOneWaySync: true,
        isClaimable: false,
        createdAt: queuedAt,
        updatedAt: queuedAt,
        lastSyncedAt: queuedAt,
        syncState: ExternalSyncState.needsReview,
        metadata: <String, dynamic>{
          'environmentId': item.environmentId,
          'supportedPlaceRef': item.supportedPlaceRef,
          'evidenceFamily': item.evidenceFamily,
          'restageTarget': item.restageTarget,
          'restageTargetSummary': item.restageTargetSummary,
          'policyAction': item.policyAction,
          'policyActionSummary': item.policyActionSummary,
          'servedBasisRef': item.servedBasisRef,
          'currentBasisStatus': item.currentBasisStatus,
          'cityPackStructuralRef': item.cityPackStructuralRef,
          'latestStateRefreshReceiptRef': item.latestStateRefreshReceiptRef,
          'latestStateRevalidationReceiptRef':
              item.latestStateRevalidationReceiptRef,
          'basisRefreshLineageRef': item.basisRefreshLineageRef,
          'applyReviewOutcomeArtifactRef': applyReviewOutcomeArtifactRef,
          'status': status,
          'localOnly': true,
        },
      );
      await intakeRepository.upsertSource(sourceDescriptor);

      job = ExternalSyncJob(
        id: jobId,
        sourceId: sourceId,
        startedAt: queuedAt,
        updatedAt: queuedAt,
        state: ExternalSyncState.needsReview,
        importedCount: 1,
        reviewCount: 1,
      );
      await intakeRepository.upsertJob(job);

      reviewItem = OrganizerReviewItem(
        id: reviewItemId,
        sourceId: sourceId,
        ownerUserId: ownerUserId,
        targetType: IntakeEntityType.review,
        title:
            'Family restage served-basis update review for ${item.environmentId} / ${_describeHydrationEvidenceFamily(item.evidenceFamily)}',
        summary:
            'Approved family restage apply review now needs bounded governed served-basis update review before any later basis mutation step.',
        missingFields: const <String>[],
        createdAt: queuedAt,
        payload: <String, dynamic>{
          'environmentId': item.environmentId,
          'supportedPlaceRef': item.supportedPlaceRef,
          'evidenceFamily': item.evidenceFamily,
          'restageTarget': item.restageTarget,
          'restageTargetSummary': item.restageTargetSummary,
          'policyAction': item.policyAction,
          'policyActionSummary': item.policyActionSummary,
          'servedBasisRef': item.servedBasisRef,
          'currentBasisStatus': item.currentBasisStatus,
          'cityPackStructuralRef': item.cityPackStructuralRef,
          'latestStateRefreshReceiptRef': item.latestStateRefreshReceiptRef,
          'latestStateRevalidationReceiptRef':
              item.latestStateRevalidationReceiptRef,
          'basisRefreshLineageRef': item.basisRefreshLineageRef,
          'applyReviewOutcomeArtifactRef': applyReviewOutcomeArtifactRef,
          'status': status,
          'localOnly': true,
        },
      );
      await intakeRepository.upsertReviewItem(reviewItem);
    }

    final export = ReplaySimulationFamilyRestageServedBasisUpdateQueueExport(
      environmentId: item.environmentId,
      evidenceFamily: item.evidenceFamily,
      queueJsonPath: queueJsonPath,
      readmePath: readmePath,
      queuedAt: queuedAt,
      status: status,
      sourceId: sourceDescriptor?.id,
      jobId: job?.id,
      reviewItemId: reviewItem?.id,
    );
    await _writePrettyJson(
      File(queueJsonPath),
      <String, dynamic>{
        'environmentId': item.environmentId,
        'supportedPlaceRef': item.supportedPlaceRef,
        'evidenceFamily': item.evidenceFamily,
        'restageTarget': item.restageTarget,
        'restageTargetSummary': item.restageTargetSummary,
        'policyAction': item.policyAction,
        'policyActionSummary': item.policyActionSummary,
        'servedBasisRef': item.servedBasisRef,
        'currentBasisStatus': item.currentBasisStatus,
        'queuedAt': queuedAt.toIso8601String(),
        'status': status,
        'cityPackStructuralRef': item.cityPackStructuralRef,
        'latestStateRefreshReceiptRef': item.latestStateRefreshReceiptRef,
        'latestStateRevalidationReceiptRef':
            item.latestStateRevalidationReceiptRef,
        'basisRefreshLineageRef': item.basisRefreshLineageRef,
        'applyReviewOutcomeArtifactRef': applyReviewOutcomeArtifactRef,
        'sourceDescriptor': sourceDescriptor?.toJson(),
        'job': job?.toJson(),
        'reviewItem': reviewItem?.toJson(),
        'notes': <String>[
          'This bounded served-basis update artifact exists because the family restage apply review was approved and the family may now proceed into its explicit governed served-basis update lane.',
        ],
      },
    );
    await File(readmePath).writeAsString(
      _buildFamilyRestageServedBasisUpdateQueueReadme(
        item: item,
        export: export,
        applyReviewOutcomeArtifactRef: applyReviewOutcomeArtifactRef,
      ),
      flush: true,
    );
    return export;
  }

  Future<ReplaySimulationLabServedBasisState> stageLatestStateHydrationBasis({
    required String environmentId,
  }) async {
    final normalizedEnvironmentId = environmentId.trim();
    final environments = await listAvailableEnvironments();
    final descriptor = environments.where(
      (entry) => entry.environmentId == normalizedEnvironmentId,
    );
    if (descriptor.isEmpty) {
      throw StateError('Unknown simulation environment: $environmentId');
    }
    final currentState = await getServedBasisState(
      environmentId: normalizedEnvironmentId,
    );
    final currentDescriptor = descriptor.first;
    final now = _nowProvider().toUtc();
    final root = await _registeredEnvironmentDirectory(normalizedEnvironmentId);
    final refreshId = 'basis_refresh_${now.millisecondsSinceEpoch}';
    final refreshDir =
        Directory(path.join(root.path, 'basis_refreshes', refreshId))
          ..createSync(recursive: true);
    final latestStateDir = Directory(path.join(root.path, 'latest_state'))
      ..createSync(recursive: true);
    final relativeRoot = _worldSimulationLabRelativePath(
      'registered_environments',
      normalizedEnvironmentId,
    );
    final latestStateSelection = await _selectLatestStateEvidenceBundle(
      environmentId: normalizedEnvironmentId,
      supportedPlaceRef: 'place:${currentDescriptor.cityCode}',
      relativeRoot: relativeRoot,
      latestStateDirectory: latestStateDir,
    );
    final refreshReceiptRef =
        '$relativeRoot/basis_refreshes/$refreshId/basis_refresh_receipts.refresh.json';
    final servedBasisRef =
        '$relativeRoot/basis_refreshes/$refreshId/served_city_pack_basis.refresh.json';
    final basisRefreshLineageRef =
        '$relativeRoot/basis_refreshes/$refreshId/basis_refresh_lineage.refresh.json';
    final stagedState = ReplaySimulationLabServedBasisState(
      environmentId: normalizedEnvironmentId,
      supportedPlaceRef: 'place:${currentDescriptor.cityCode}',
      stagedAt: now,
      servedBasisRef: servedBasisRef,
      cityPackStructuralRef: currentDescriptor.cityPackStructuralRef,
      priorServedBasisRef: currentState?.servedBasisRef,
      basisRefreshLineageRef: basisRefreshLineageRef,
      latestStateRefreshReceiptRef: refreshReceiptRef,
      latestStateDecisionStatus: latestStateSelection.promotionReadiness ==
              'ready_for_bounded_basis_review'
          ? 'awaiting_basis_review_decision'
          : 'not_reviewed',
      currentBasisStatus: 'staged_latest_state_basis',
      latestStateHydrationStatus: latestStateSelection.hydrationStatus,
      latestStatePromotionReadiness: latestStateSelection.promotionReadiness,
      latestStatePromotionBlockedReasons:
          latestStateSelection.promotionBlockedReasons,
      hydrationFreshnessPosture: latestStateSelection.hydrationFreshnessPosture,
      latestStateRefreshCadenceHours:
          latestStateSelection.refreshPolicy.refreshCadenceHours,
      latestStateRefreshCadenceStatus: _latestStateRefreshCadenceStatus(
        refreshCadenceHours:
            latestStateSelection.refreshPolicy.refreshCadenceHours,
        referenceAt: now,
      ),
      latestStateRefreshReferenceAt: now,
      latestStateRefreshPolicySummaries:
          latestStateSelection.refreshPolicy.summaries,
      latestStateEvidenceRefsByFamily: latestStateSelection.refsByFamily,
      latestStateEvidenceSelectionSummariesByFamily:
          latestStateSelection.selectionSummariesByFamily,
      latestStateEvidenceAgingStatusesByFamily:
          latestStateSelection.agingStatusesByFamily,
      latestStateEvidenceAgingSummariesByFamily:
          latestStateSelection.agingSummariesByFamily,
      latestStateEvidencePolicyActionsByFamily:
          currentState?.latestStateEvidencePolicyActionsByFamily ??
              const <String, String>{},
      latestStateEvidencePolicyActionSummariesByFamily:
          currentState?.latestStateEvidencePolicyActionSummariesByFamily ??
              const <String, String>{},
      latestStateEvidenceRestageTargetsByFamily:
          currentState?.latestStateEvidenceRestageTargetsByFamily ??
              const <String, String>{},
      latestStateEvidenceRestageTargetSummariesByFamily:
          currentState?.latestStateEvidenceRestageTargetSummariesByFamily ??
              const <String, String>{},
    );
    await _writePrettyJson(
      File(path.join(refreshDir.path, 'served_city_pack_basis.refresh.json')),
      stagedState.toJson(),
    );
    await _writePrettyJson(
      File(path.join(refreshDir.path, 'basis_refresh_receipts.refresh.json')),
      <String, dynamic>{
        'environmentId': normalizedEnvironmentId,
        'supportedPlaceRef': stagedState.supportedPlaceRef,
        'stagedAt': now.toIso8601String(),
        'selectionSummariesByFamily':
            latestStateSelection.selectionSummariesByFamily,
        'agingStatusesByFamily': latestStateSelection.agingStatusesByFamily,
        'agingSummariesByFamily': latestStateSelection.agingSummariesByFamily,
        'promotionReadiness': latestStateSelection.promotionReadiness,
        'promotionBlockedReasons': latestStateSelection.promotionBlockedReasons,
        'hydrationStatus': latestStateSelection.hydrationStatus,
        'hydrationFreshnessPosture':
            latestStateSelection.hydrationFreshnessPosture,
        'refreshCadenceHours':
            latestStateSelection.refreshPolicy.refreshCadenceHours,
        'refreshPolicySummaries': latestStateSelection.refreshPolicy.summaries,
      },
    );
    await _writePrettyJson(
      File(path.join(refreshDir.path, 'basis_refresh_lineage.refresh.json')),
      <String, dynamic>{
        'environmentId': normalizedEnvironmentId,
        'supportedPlaceRef': stagedState.supportedPlaceRef,
        'stagedAt': now.toIso8601String(),
        'servedBasisRef': stagedState.servedBasisRef,
        'priorServedBasisRef': stagedState.priorServedBasisRef,
        'latestStateRefreshReceiptRef': refreshReceiptRef,
        'latestStateEvidenceRefsByFamily': latestStateSelection.refsByFamily,
        'latestStateEvidenceSelectionSummariesByFamily':
            latestStateSelection.selectionSummariesByFamily,
        'latestStateEvidenceAgingStatusesByFamily':
            latestStateSelection.agingStatusesByFamily,
        'latestStateEvidenceAgingSummariesByFamily':
            latestStateSelection.agingSummariesByFamily,
        'latestStateEvidenceAgingTransitionsByFamily':
            currentState?.latestStateEvidenceAgingTransitionsByFamily ??
                const <String, String>{},
        'latestStateEvidenceAgingTrendsByFamily':
            currentState?.latestStateEvidenceAgingTrendsByFamily ??
                const <String, String>{},
        'latestStateEvidenceAgingTrendSummariesByFamily':
            currentState?.latestStateEvidenceAgingTrendSummariesByFamily ??
                const <String, String>{},
        'latestStateEvidencePolicyActionsByFamily':
            currentState?.latestStateEvidencePolicyActionsByFamily ??
                const <String, String>{},
        'latestStateEvidencePolicyActionSummariesByFamily':
            currentState?.latestStateEvidencePolicyActionSummariesByFamily ??
                const <String, String>{},
        'latestStateEvidenceRestageTargetsByFamily':
            currentState?.latestStateEvidenceRestageTargetsByFamily ??
                const <String, String>{},
        'latestStateEvidenceRestageTargetSummariesByFamily':
            currentState?.latestStateEvidenceRestageTargetSummariesByFamily ??
                const <String, String>{},
        'latestStatePromotionReadiness':
            latestStateSelection.promotionReadiness,
        'latestStatePromotionBlockedReasons':
            latestStateSelection.promotionBlockedReasons,
        'latestStateRefreshCadenceHours':
            latestStateSelection.refreshPolicy.refreshCadenceHours,
        'latestStateRefreshPolicySummaries':
            latestStateSelection.refreshPolicy.summaries,
      },
    );
    await _writePrettyJson(
      File(path.join(root.path, 'served_city_pack_basis.current.json')),
      stagedState.toJson(),
    );
    return stagedState;
  }

  String? _extractBasisRefreshId(String? basisRef) {
    if (basisRef == null || basisRef.trim().isEmpty) {
      return null;
    }
    final match = RegExp(r'basis_refreshes/([^/]+)/').firstMatch(basisRef);
    if (match == null) {
      return null;
    }
    final refreshId = match.group(1)?.trim();
    if (refreshId == null || refreshId.isEmpty) {
      return null;
    }
    return refreshId;
  }

  String _basisPromotionReceiptRef({
    required String relativeRoot,
    required String refreshId,
    required String decision,
  }) {
    return '$relativeRoot/basis_refreshes/$refreshId/'
        'basis_promotion_receipts.$decision.json';
  }

  String _servedBasisDeploymentReceiptRef({
    required String relativeRoot,
    required String refreshId,
    required String deploymentMode,
  }) {
    return '$relativeRoot/basis_refreshes/$refreshId/'
        'served_basis_deployment_receipts.$deploymentMode.json';
  }

  void _requirePromotionSourceBindings({
    required ReplaySimulationLabServedBasisState state,
    required String action,
  }) {
    final violations = <String>[];
    if ((state.latestStateRefreshReceiptRef ?? '').trim().isEmpty) {
      violations.add('latestStateRefreshReceiptRef');
    }
    if ((state.basisRefreshLineageRef ?? '').trim().isEmpty) {
      violations.add('basisRefreshLineageRef');
    }
    if (violations.isEmpty) {
      return;
    }
    throw StateError(
      'Cannot $action served basis `${state.environmentId}` without '
      'refresh-bound receipt lineage: ${violations.join(', ')}.',
    );
  }

  void _requireRestoreSourceBindings({
    required ReplaySimulationLabServedBasisState state,
    required String action,
  }) {
    final violations = <String>[];
    if ((state.latestStateRevalidationReceiptRef ?? '').trim().isEmpty) {
      violations.add('latestStateRevalidationReceiptRef');
    }
    if ((state.latestStateRevalidationArtifactRef ?? '').trim().isEmpty) {
      violations.add('latestStateRevalidationArtifactRef');
    }
    if ((state.latestStatePromotionReceiptRef ?? '').trim().isEmpty) {
      violations.add('latestStatePromotionReceiptRef');
    }
    if (violations.isEmpty) {
      return;
    }
    throw StateError(
      'Cannot $action served basis `${state.environmentId}` without '
      'revalidation/promotion receipt lineage: ${violations.join(', ')}.',
    );
  }

  Future<ReplaySimulationLabServedBasisState> promoteStagedLatestStateBasis({
    required String environmentId,
    String rationale = '',
  }) async {
    final normalizedEnvironmentId = environmentId.trim();
    final currentState = await getServedBasisState(
      environmentId: normalizedEnvironmentId,
    );
    if (currentState == null) {
      throw StateError('No served-basis state exists for $environmentId.');
    }
    if (currentState.currentBasisStatus != 'staged_latest_state_basis') {
      throw StateError(
        'Only a staged latest-state basis can be promoted. Current status is `${currentState.currentBasisStatus}`.',
      );
    }
    if (currentState.latestStatePromotionReadiness !=
        'ready_for_bounded_basis_review') {
      throw StateError(
        'The staged latest-state basis is not promotable yet. Current readiness is `${currentState.latestStatePromotionReadiness}`.',
      );
    }
    final refreshId = _extractBasisRefreshId(currentState.servedBasisRef);
    if (refreshId == null) {
      throw StateError(
        'Unable to resolve the staged basis refresh lineage for `${currentState.servedBasisRef}`.',
      );
    }
    _requirePromotionSourceBindings(
      state: currentState,
      action: 'promote',
    );
    final now = _nowProvider().toUtc();
    final root = await _registeredEnvironmentDirectory(normalizedEnvironmentId);
    final refreshDir =
        Directory(path.join(root.path, 'basis_refreshes', refreshId))
          ..createSync(recursive: true);
    final relativeRoot = _worldSimulationLabRelativePath(
      'registered_environments',
      normalizedEnvironmentId,
    );
    final decisionArtifactRef =
        '$relativeRoot/basis_refreshes/$refreshId/basis_promotion_decision.promoted.json';
    final promotionReceiptRef = _basisPromotionReceiptRef(
      relativeRoot: relativeRoot,
      refreshId: refreshId,
      decision: 'promoted',
    );
    final deploymentReceiptRef = _servedBasisDeploymentReceiptRef(
      relativeRoot: relativeRoot,
      refreshId: refreshId,
      deploymentMode: 'promoted',
    );
    final promotedState = ReplaySimulationLabServedBasisState(
      environmentId: currentState.environmentId,
      supportedPlaceRef: currentState.supportedPlaceRef,
      stagedAt: now,
      servedBasisRef: currentState.servedBasisRef,
      latestStateEvidenceRefsByFamily:
          currentState.latestStateEvidenceRefsByFamily,
      latestStateEvidenceSelectionSummariesByFamily:
          currentState.latestStateEvidenceSelectionSummariesByFamily,
      latestStateEvidenceAgingStatusesByFamily:
          currentState.latestStateEvidenceAgingStatusesByFamily,
      latestStateEvidenceAgingSummariesByFamily:
          currentState.latestStateEvidenceAgingSummariesByFamily,
      latestStateEvidenceAgingTransitionsByFamily:
          currentState.latestStateEvidenceAgingTransitionsByFamily,
      latestStateEvidenceAgingTrendsByFamily:
          currentState.latestStateEvidenceAgingTrendsByFamily,
      latestStateEvidenceAgingTrendSummariesByFamily:
          currentState.latestStateEvidenceAgingTrendSummariesByFamily,
      latestStateEvidencePolicyActionsByFamily:
          currentState.latestStateEvidencePolicyActionsByFamily,
      latestStateEvidencePolicyActionSummariesByFamily:
          currentState.latestStateEvidencePolicyActionSummariesByFamily,
      latestStateEvidenceRestageTargetsByFamily:
          currentState.latestStateEvidenceRestageTargetsByFamily,
      latestStateEvidenceRestageTargetSummariesByFamily:
          currentState.latestStateEvidenceRestageTargetSummariesByFamily,
      cityPackStructuralRef: currentState.cityPackStructuralRef,
      priorServedBasisRef: currentState.priorServedBasisRef,
      basisRefreshLineageRef: currentState.basisRefreshLineageRef,
      latestStateRefreshReceiptRef: currentState.latestStateRefreshReceiptRef,
      latestStatePromotionReceiptRef: promotionReceiptRef,
      latestStateDecisionStatus: 'promoted',
      latestStateDecisionArtifactRef: decisionArtifactRef,
      latestStateDecisionRationale: rationale.trim().isEmpty
          ? 'Promoted after bounded latest-state basis review.'
          : rationale.trim(),
      latestStateDecisionRecordedAt: now,
      currentBasisStatus: 'latest_state_served_basis',
      latestStateHydrationStatus: 'latest_state_basis_served',
      latestStatePromotionReadiness: 'promoted_to_served_basis',
      latestStatePromotionBlockedReasons: const <String>[],
      hydrationFreshnessPosture:
          'served_basis_updated_from_latest_state_receipts',
      latestStateRefreshCadenceHours:
          currentState.latestStateRefreshCadenceHours,
      latestStateRefreshCadenceStatus: _latestStateRefreshCadenceStatus(
        refreshCadenceHours: currentState.latestStateRefreshCadenceHours,
        referenceAt: now,
      ),
      latestStateRefreshReferenceAt: now,
      latestStateRefreshPolicySummaries:
          currentState.latestStateRefreshPolicySummaries,
      latestStateDeploymentReceiptRef: deploymentReceiptRef,
    );
    await _writePrettyJson(
      File(
        path.join(
          refreshDir.path,
          'basis_promotion_receipts.promoted.json',
        ),
      ),
      <String, dynamic>{
        'environmentId': normalizedEnvironmentId,
        'supportedPlaceRef': promotedState.supportedPlaceRef,
        'receiptKind': 'promotion_receipt',
        'decision': 'promoted',
        'issuedAt': now.toIso8601String(),
        'promotionRef': promotionReceiptRef,
        'servedBasisRef': promotedState.servedBasisRef,
        'priorServedBasisRef': promotedState.priorServedBasisRef,
        'basisRefreshLineageRef': promotedState.basisRefreshLineageRef,
        'latestStateRefreshReceiptRef':
            promotedState.latestStateRefreshReceiptRef,
        'sourceEvidenceRefsByFamily':
            promotedState.latestStateEvidenceRefsByFamily,
        'rationale': promotedState.latestStateDecisionRationale,
      },
    );
    await _writePrettyJson(
      File(
          path.join(refreshDir.path, 'basis_promotion_decision.promoted.json')),
      <String, dynamic>{
        'environmentId': normalizedEnvironmentId,
        'supportedPlaceRef': promotedState.supportedPlaceRef,
        'decision': 'promoted',
        'decidedAt': now.toIso8601String(),
        'servedBasisRef': promotedState.servedBasisRef,
        'priorServedBasisRef': promotedState.priorServedBasisRef,
        'latestStateRefreshReceiptRef':
            promotedState.latestStateRefreshReceiptRef,
        'rationale': promotedState.latestStateDecisionRationale,
      },
    );
    await _writePrettyJson(
      File(
        path.join(
          refreshDir.path,
          'served_basis_deployment_receipts.promoted.json',
        ),
      ),
      <String, dynamic>{
        'environmentId': normalizedEnvironmentId,
        'supportedPlaceRef': promotedState.supportedPlaceRef,
        'receiptKind': 'downward_deployment_receipt',
        'deploymentMode': 'promoted',
        'deployedAt': now.toIso8601String(),
        'deploymentRef': deploymentReceiptRef,
        'promotionRef': promotionReceiptRef,
        'targetStateRef': '$relativeRoot/served_city_pack_basis.current.json',
        'servedBasisRef': promotedState.servedBasisRef,
        'targetBasisStatus': promotedState.currentBasisStatus,
      },
    );
    await _writePrettyJson(
      File(path.join(root.path, 'served_city_pack_basis.current.json')),
      promotedState.toJson(),
    );
    return promotedState;
  }

  Future<ReplaySimulationLabServedBasisState> rejectStagedLatestStateBasis({
    required String environmentId,
    String rationale = '',
  }) async {
    final normalizedEnvironmentId = environmentId.trim();
    final currentState = await getServedBasisState(
      environmentId: normalizedEnvironmentId,
    );
    if (currentState == null) {
      throw StateError('No served-basis state exists for $environmentId.');
    }
    if (currentState.currentBasisStatus != 'staged_latest_state_basis') {
      throw StateError(
        'Only a staged latest-state basis can be rejected. Current status is `${currentState.currentBasisStatus}`.',
      );
    }
    final refreshId = _extractBasisRefreshId(currentState.servedBasisRef);
    if (refreshId == null) {
      throw StateError(
        'Unable to resolve the staged basis refresh lineage for `${currentState.servedBasisRef}`.',
      );
    }
    _requirePromotionSourceBindings(
      state: currentState,
      action: 'reject',
    );
    final now = _nowProvider().toUtc();
    final root = await _registeredEnvironmentDirectory(normalizedEnvironmentId);
    final refreshDir =
        Directory(path.join(root.path, 'basis_refreshes', refreshId))
          ..createSync(recursive: true);
    final relativeRoot = _worldSimulationLabRelativePath(
      'registered_environments',
      normalizedEnvironmentId,
    );
    final decisionArtifactRef =
        '$relativeRoot/basis_refreshes/$refreshId/basis_promotion_decision.rejected.json';
    final promotionReceiptRef = _basisPromotionReceiptRef(
      relativeRoot: relativeRoot,
      refreshId: refreshId,
      decision: 'rejected',
    );
    final restoredServedBasisRef =
        currentState.priorServedBasisRef ?? currentState.servedBasisRef;
    final rejectedState = ReplaySimulationLabServedBasisState(
      environmentId: currentState.environmentId,
      supportedPlaceRef: currentState.supportedPlaceRef,
      stagedAt: now,
      servedBasisRef: restoredServedBasisRef,
      latestStateEvidenceRefsByFamily:
          currentState.latestStateEvidenceRefsByFamily,
      latestStateEvidenceSelectionSummariesByFamily:
          currentState.latestStateEvidenceSelectionSummariesByFamily,
      latestStateEvidenceAgingStatusesByFamily:
          currentState.latestStateEvidenceAgingStatusesByFamily,
      latestStateEvidenceAgingSummariesByFamily:
          currentState.latestStateEvidenceAgingSummariesByFamily,
      latestStateEvidenceAgingTransitionsByFamily:
          currentState.latestStateEvidenceAgingTransitionsByFamily,
      latestStateEvidenceAgingTrendsByFamily:
          currentState.latestStateEvidenceAgingTrendsByFamily,
      latestStateEvidenceAgingTrendSummariesByFamily:
          currentState.latestStateEvidenceAgingTrendSummariesByFamily,
      latestStateEvidencePolicyActionsByFamily:
          currentState.latestStateEvidencePolicyActionsByFamily,
      latestStateEvidencePolicyActionSummariesByFamily:
          currentState.latestStateEvidencePolicyActionSummariesByFamily,
      latestStateEvidenceRestageTargetsByFamily:
          currentState.latestStateEvidenceRestageTargetsByFamily,
      latestStateEvidenceRestageTargetSummariesByFamily:
          currentState.latestStateEvidenceRestageTargetSummariesByFamily,
      cityPackStructuralRef: currentState.cityPackStructuralRef,
      priorServedBasisRef: currentState.priorServedBasisRef,
      basisRefreshLineageRef: currentState.basisRefreshLineageRef,
      latestStateRefreshReceiptRef: currentState.latestStateRefreshReceiptRef,
      latestStatePromotionReceiptRef: promotionReceiptRef,
      latestStateDecisionStatus: 'rejected',
      latestStateDecisionArtifactRef: decisionArtifactRef,
      latestStateDecisionRationale: rationale.trim().isEmpty
          ? 'Rejected after bounded latest-state basis review.'
          : rationale.trim(),
      latestStateDecisionRecordedAt: now,
      currentBasisStatus:
          restoredServedBasisRef == currentState.priorServedBasisRef
              ? 'replay_grounded_seed_basis'
              : 'replay_grounded_seed_basis',
      latestStateHydrationStatus: 'latest_state_basis_rejected',
      latestStatePromotionReadiness: 'blocked_pending_latest_state_evidence',
      latestStatePromotionBlockedReasons:
          currentState.latestStatePromotionBlockedReasons.isEmpty
              ? <String>[
                  'The previously staged latest-state basis was rejected during bounded review.'
                ]
              : <String>[
                  ...currentState.latestStatePromotionBlockedReasons,
                  'The previously staged latest-state basis was rejected during bounded review.',
                ],
      hydrationFreshnessPosture: 'prior_served_basis_restored_after_rejection',
      latestStateRefreshCadenceHours:
          currentState.latestStateRefreshCadenceHours,
      latestStateRefreshCadenceStatus: _latestStateRefreshCadenceStatus(
        refreshCadenceHours: currentState.latestStateRefreshCadenceHours,
        referenceAt: currentState.latestStateRefreshReferenceAt,
      ),
      latestStateRefreshReferenceAt: currentState.latestStateRefreshReferenceAt,
      latestStateRefreshPolicySummaries:
          currentState.latestStateRefreshPolicySummaries,
    );
    await _writePrettyJson(
      File(
        path.join(
          refreshDir.path,
          'basis_promotion_receipts.rejected.json',
        ),
      ),
      <String, dynamic>{
        'environmentId': normalizedEnvironmentId,
        'supportedPlaceRef': rejectedState.supportedPlaceRef,
        'receiptKind': 'promotion_receipt',
        'decision': 'rejected',
        'issuedAt': now.toIso8601String(),
        'promotionRef': promotionReceiptRef,
        'candidateServedBasisRef': currentState.servedBasisRef,
        'restoredServedBasisRef': restoredServedBasisRef,
        'basisRefreshLineageRef': rejectedState.basisRefreshLineageRef,
        'latestStateRefreshReceiptRef':
            rejectedState.latestStateRefreshReceiptRef,
        'rollbackRef': rejectedState.priorServedBasisRef,
        'rationale': rejectedState.latestStateDecisionRationale,
      },
    );
    await _writePrettyJson(
      File(
          path.join(refreshDir.path, 'basis_promotion_decision.rejected.json')),
      <String, dynamic>{
        'environmentId': normalizedEnvironmentId,
        'supportedPlaceRef': rejectedState.supportedPlaceRef,
        'decision': 'rejected',
        'decidedAt': now.toIso8601String(),
        'candidateServedBasisRef': currentState.servedBasisRef,
        'restoredServedBasisRef': restoredServedBasisRef,
        'latestStateRefreshReceiptRef':
            rejectedState.latestStateRefreshReceiptRef,
        'rationale': rejectedState.latestStateDecisionRationale,
      },
    );
    await _writePrettyJson(
      File(path.join(root.path, 'served_city_pack_basis.current.json')),
      rejectedState.toJson(),
    );
    return rejectedState;
  }

  Future<ReplaySimulationLabServedBasisState> revalidatePromotedServedBasis({
    required String environmentId,
  }) async {
    final normalizedEnvironmentId = environmentId.trim();
    final currentState = await getServedBasisState(
      environmentId: normalizedEnvironmentId,
    );
    if (currentState == null) {
      throw StateError('No served-basis state exists for $environmentId.');
    }
    if (currentState.currentBasisStatus != 'latest_state_served_basis' &&
        currentState.currentBasisStatus !=
            'expired_latest_state_served_basis') {
      throw StateError(
        'Only a promoted or expired latest-state served basis can be revalidated. Current status is `${currentState.currentBasisStatus}`.',
      );
    }
    final refreshId = _extractBasisRefreshId(currentState.servedBasisRef);
    if (refreshId == null) {
      throw StateError(
        'Unable to resolve the served basis refresh lineage for `${currentState.servedBasisRef}`.',
      );
    }
    final now = _nowProvider().toUtc();
    final root = await _registeredEnvironmentDirectory(normalizedEnvironmentId);
    final refreshDir =
        Directory(path.join(root.path, 'basis_refreshes', refreshId))
          ..createSync(recursive: true);
    final latestStateDir = Directory(path.join(root.path, 'latest_state'))
      ..createSync(recursive: true);
    final relativeRoot = _worldSimulationLabRelativePath(
      'registered_environments',
      normalizedEnvironmentId,
    );
    final latestStateSelection = await _selectLatestStateEvidenceBundle(
      environmentId: normalizedEnvironmentId,
      supportedPlaceRef: currentState.supportedPlaceRef,
      relativeRoot: relativeRoot,
      latestStateDirectory: latestStateDir,
    );
    final actionBlockedReasons = _latestStatePolicyActionBlockedReasons(
      actionsByFamily: currentState.latestStateEvidencePolicyActionsByFamily,
    );
    final restageTargetsByFamily =
        currentState.latestStateEvidenceRestageTargetsByFamily.isNotEmpty
            ? currentState.latestStateEvidenceRestageTargetsByFamily
            : _latestStateEvidenceRestageTargetsForActions(
                actionsByFamily:
                    currentState.latestStateEvidencePolicyActionsByFamily,
              );
    final restageTargetSummariesByFamily = currentState
            .latestStateEvidenceRestageTargetSummariesByFamily.isNotEmpty
        ? currentState.latestStateEvidenceRestageTargetSummariesByFamily
        : _latestStateEvidenceRestageTargetSummariesForActions(
            actionsByFamily:
                currentState.latestStateEvidencePolicyActionsByFamily,
            trendsByFamily: currentState.latestStateEvidenceAgingTrendsByFamily,
            agingStatusesByFamily:
                currentState.latestStateEvidenceAgingStatusesByFamily,
          );
    final isCurrent = latestStateSelection.promotionReadiness ==
            'ready_for_bounded_basis_review' &&
        actionBlockedReasons.isEmpty;
    final isExpiredBasis =
        currentState.currentBasisStatus == 'expired_latest_state_served_basis';
    final revalidationReceiptRef =
        '$relativeRoot/basis_refreshes/$refreshId/basis_revalidation_receipts.revalidation.json';
    final revalidationArtifactRef =
        '$relativeRoot/basis_refreshes/$refreshId/basis_revalidation.${isCurrent ? 'current' : 'expired'}.json';
    final nextBlockedReasons = isCurrent && isExpiredBasis
        ? const <String>[]
        : isCurrent
            ? const <String>[]
            : <String>[
                ...latestStateSelection.promotionBlockedReasons,
                ...actionBlockedReasons,
                'The promoted served basis no longer satisfies latest-state evidence freshness and must be restaged before reuse.',
              ];
    final revalidatedState = ReplaySimulationLabServedBasisState(
      environmentId: currentState.environmentId,
      supportedPlaceRef: currentState.supportedPlaceRef,
      stagedAt: now,
      servedBasisRef: currentState.servedBasisRef,
      latestStateEvidenceRefsByFamily: latestStateSelection.refsByFamily,
      latestStateEvidenceSelectionSummariesByFamily:
          latestStateSelection.selectionSummariesByFamily,
      latestStateEvidenceAgingStatusesByFamily:
          latestStateSelection.agingStatusesByFamily,
      latestStateEvidenceAgingSummariesByFamily:
          latestStateSelection.agingSummariesByFamily,
      latestStateEvidenceAgingTransitionsByFamily:
          currentState.latestStateEvidenceAgingTransitionsByFamily,
      latestStateEvidenceAgingTrendsByFamily:
          currentState.latestStateEvidenceAgingTrendsByFamily,
      latestStateEvidenceAgingTrendSummariesByFamily:
          currentState.latestStateEvidenceAgingTrendSummariesByFamily,
      latestStateEvidencePolicyActionsByFamily:
          currentState.latestStateEvidencePolicyActionsByFamily,
      latestStateEvidencePolicyActionSummariesByFamily:
          currentState.latestStateEvidencePolicyActionSummariesByFamily,
      latestStateEvidenceRestageTargetsByFamily: restageTargetsByFamily,
      latestStateEvidenceRestageTargetSummariesByFamily:
          restageTargetSummariesByFamily,
      cityPackStructuralRef: currentState.cityPackStructuralRef,
      priorServedBasisRef: currentState.priorServedBasisRef,
      basisRefreshLineageRef: currentState.basisRefreshLineageRef,
      latestStateRefreshReceiptRef: currentState.latestStateRefreshReceiptRef,
      latestStatePromotionReceiptRef:
          currentState.latestStatePromotionReceiptRef,
      latestStateDecisionStatus: currentState.latestStateDecisionStatus,
      latestStateDecisionArtifactRef:
          currentState.latestStateDecisionArtifactRef,
      latestStateDecisionRationale: currentState.latestStateDecisionRationale,
      latestStateDecisionRecordedAt: currentState.latestStateDecisionRecordedAt,
      latestStateRecoveryDecisionStatus: isCurrent && isExpiredBasis
          ? 'not_reviewed'
          : currentState.latestStateRecoveryDecisionStatus,
      latestStateRecoveryDecisionArtifactRef: isCurrent && isExpiredBasis
          ? null
          : currentState.latestStateRecoveryDecisionArtifactRef,
      latestStateRecoveryDecisionRationale: isCurrent && isExpiredBasis
          ? null
          : currentState.latestStateRecoveryDecisionRationale,
      latestStateRecoveryDecisionRecordedAt: isCurrent && isExpiredBasis
          ? null
          : currentState.latestStateRecoveryDecisionRecordedAt,
      latestStateRevalidationStatus: isCurrent ? 'current' : 'expired',
      latestStateRevalidationReceiptRef: revalidationReceiptRef,
      latestStateRevalidationArtifactRef: revalidationArtifactRef,
      latestStateRevalidatedAt: now,
      currentBasisStatus: isCurrent && isExpiredBasis
          ? 'expired_latest_state_served_basis'
          : isCurrent
              ? 'latest_state_served_basis'
              : 'expired_latest_state_served_basis',
      latestStateHydrationStatus: isCurrent && isExpiredBasis
          ? 'expired_basis_ready_for_restore_review'
          : isCurrent
              ? 'latest_state_basis_served_revalidated'
              : 'latest_state_basis_served_expired',
      latestStatePromotionReadiness: isCurrent && isExpiredBasis
          ? 'ready_for_bounded_served_basis_restore'
          : isCurrent
              ? 'served_basis_revalidated_current'
              : 'restage_required_before_served_basis_reuse',
      latestStatePromotionBlockedReasons: nextBlockedReasons,
      hydrationFreshnessPosture: isCurrent && isExpiredBasis
          ? 'expired_basis_supported_by_current_receipts_pending_restore_review'
          : isCurrent
              ? 'served_basis_still_supported_by_current_receipts'
              : _latestStateFreshnessPostureForPolicyActions(
                  fallbackPosture:
                      'promoted_served_basis_expired_pending_restage',
                  actionsByFamily:
                      currentState.latestStateEvidencePolicyActionsByFamily,
                ),
      latestStateRefreshCadenceHours:
          latestStateSelection.refreshPolicy.refreshCadenceHours,
      latestStateRefreshCadenceStatus: _latestStateRefreshCadenceStatus(
        refreshCadenceHours:
            latestStateSelection.refreshPolicy.refreshCadenceHours,
        referenceAt: now,
      ),
      latestStateRefreshReferenceAt: now,
      latestStateRefreshPolicySummaries:
          latestStateSelection.refreshPolicy.summaries,
      latestStateDeploymentReceiptRef:
          currentState.latestStateDeploymentReceiptRef,
    );
    await _writePrettyJson(
      File(
        path.join(
          refreshDir.path,
          'basis_revalidation_receipts.revalidation.json',
        ),
      ),
      <String, dynamic>{
        'environmentId': normalizedEnvironmentId,
        'supportedPlaceRef': revalidatedState.supportedPlaceRef,
        'revalidatedAt': now.toIso8601String(),
        'servedBasisRef': revalidatedState.servedBasisRef,
        'revalidationStatus': revalidatedState.latestStateRevalidationStatus,
        'latestStateEvidenceRefsByFamily': latestStateSelection.refsByFamily,
        'latestStateEvidenceSelectionSummariesByFamily':
            latestStateSelection.selectionSummariesByFamily,
        'latestStateEvidenceAgingStatusesByFamily':
            latestStateSelection.agingStatusesByFamily,
        'latestStateEvidenceAgingSummariesByFamily':
            latestStateSelection.agingSummariesByFamily,
        'latestStateEvidenceAgingTransitionsByFamily':
            currentState.latestStateEvidenceAgingTransitionsByFamily,
        'latestStateEvidenceAgingTrendsByFamily':
            currentState.latestStateEvidenceAgingTrendsByFamily,
        'latestStateEvidenceAgingTrendSummariesByFamily':
            currentState.latestStateEvidenceAgingTrendSummariesByFamily,
        'latestStateEvidencePolicyActionsByFamily':
            currentState.latestStateEvidencePolicyActionsByFamily,
        'latestStateEvidencePolicyActionSummariesByFamily':
            currentState.latestStateEvidencePolicyActionSummariesByFamily,
        'latestStateEvidenceRestageTargetsByFamily': restageTargetsByFamily,
        'latestStateEvidenceRestageTargetSummariesByFamily':
            restageTargetSummariesByFamily,
        'promotionReadiness': revalidatedState.latestStatePromotionReadiness,
        'promotionBlockedReasons': nextBlockedReasons,
        'hydrationStatus': revalidatedState.latestStateHydrationStatus,
        'hydrationFreshnessPosture': revalidatedState.hydrationFreshnessPosture,
        'refreshCadenceHours':
            latestStateSelection.refreshPolicy.refreshCadenceHours,
        'refreshPolicySummaries': latestStateSelection.refreshPolicy.summaries,
      },
    );
    await _writePrettyJson(
      File(
        path.join(
          refreshDir.path,
          'basis_revalidation.${isCurrent ? 'current' : 'expired'}.json',
        ),
      ),
      <String, dynamic>{
        'environmentId': normalizedEnvironmentId,
        'supportedPlaceRef': revalidatedState.supportedPlaceRef,
        'revalidatedAt': now.toIso8601String(),
        'servedBasisRef': revalidatedState.servedBasisRef,
        'decisionStatus': revalidatedState.latestStateDecisionStatus,
        'revalidationStatus': revalidatedState.latestStateRevalidationStatus,
        'currentBasisStatus': revalidatedState.currentBasisStatus,
        'latestStateHydrationStatus':
            revalidatedState.latestStateHydrationStatus,
        'latestStatePromotionReadiness':
            revalidatedState.latestStatePromotionReadiness,
        'latestStatePromotionBlockedReasons':
            revalidatedState.latestStatePromotionBlockedReasons,
        'hydrationFreshnessPosture': revalidatedState.hydrationFreshnessPosture,
        'latestStateRefreshReceiptRef':
            revalidatedState.latestStateRefreshReceiptRef,
        'latestStateRevalidationReceiptRef':
            revalidatedState.latestStateRevalidationReceiptRef,
      },
    );
    await _writePrettyJson(
      File(path.join(root.path, 'served_city_pack_basis.current.json')),
      revalidatedState.toJson(),
    );
    return revalidatedState;
  }

  Future<ReplaySimulationLabServedBasisState>
      confirmExpiredServedBasisRestageRequired({
    required String environmentId,
    String rationale = '',
  }) async {
    final normalizedEnvironmentId = environmentId.trim();
    final currentState = await getServedBasisState(
      environmentId: normalizedEnvironmentId,
    );
    if (currentState == null) {
      throw StateError('No served-basis state exists for $environmentId.');
    }
    if (currentState.currentBasisStatus !=
        'expired_latest_state_served_basis') {
      throw StateError(
        'Only an expired latest-state served basis can be marked restage required. Current status is `${currentState.currentBasisStatus}`.',
      );
    }
    final refreshId = _extractBasisRefreshId(currentState.servedBasisRef);
    if (refreshId == null) {
      throw StateError(
        'Unable to resolve the served basis refresh lineage for `${currentState.servedBasisRef}`.',
      );
    }
    final now = _nowProvider().toUtc();
    final root = await _registeredEnvironmentDirectory(normalizedEnvironmentId);
    final refreshDir =
        Directory(path.join(root.path, 'basis_refreshes', refreshId))
          ..createSync(recursive: true);
    final relativeRoot = _worldSimulationLabRelativePath(
      'registered_environments',
      normalizedEnvironmentId,
    );
    final recoveryArtifactRef =
        '$relativeRoot/basis_refreshes/$refreshId/basis_restore_decision.restage_required.json';
    final nextBlockedReasons =
        currentState.latestStatePromotionBlockedReasons.contains(
      'The expired served basis was explicitly kept out of service pending a new staged refresh.',
    )
            ? currentState.latestStatePromotionBlockedReasons
            : <String>[
                ...currentState.latestStatePromotionBlockedReasons,
                'The expired served basis was explicitly kept out of service pending a new staged refresh.',
              ];
    final decidedState = ReplaySimulationLabServedBasisState(
      environmentId: currentState.environmentId,
      supportedPlaceRef: currentState.supportedPlaceRef,
      stagedAt: now,
      servedBasisRef: currentState.servedBasisRef,
      latestStateEvidenceRefsByFamily:
          currentState.latestStateEvidenceRefsByFamily,
      latestStateEvidenceSelectionSummariesByFamily:
          currentState.latestStateEvidenceSelectionSummariesByFamily,
      latestStateEvidenceAgingStatusesByFamily:
          currentState.latestStateEvidenceAgingStatusesByFamily,
      latestStateEvidenceAgingSummariesByFamily:
          currentState.latestStateEvidenceAgingSummariesByFamily,
      latestStateEvidenceAgingTransitionsByFamily:
          currentState.latestStateEvidenceAgingTransitionsByFamily,
      latestStateEvidenceAgingTrendsByFamily:
          currentState.latestStateEvidenceAgingTrendsByFamily,
      latestStateEvidenceAgingTrendSummariesByFamily:
          currentState.latestStateEvidenceAgingTrendSummariesByFamily,
      latestStateEvidencePolicyActionsByFamily:
          currentState.latestStateEvidencePolicyActionsByFamily,
      latestStateEvidencePolicyActionSummariesByFamily:
          currentState.latestStateEvidencePolicyActionSummariesByFamily,
      latestStateEvidenceRestageTargetsByFamily:
          currentState.latestStateEvidenceRestageTargetsByFamily,
      latestStateEvidenceRestageTargetSummariesByFamily:
          currentState.latestStateEvidenceRestageTargetSummariesByFamily,
      cityPackStructuralRef: currentState.cityPackStructuralRef,
      priorServedBasisRef: currentState.priorServedBasisRef,
      basisRefreshLineageRef: currentState.basisRefreshLineageRef,
      latestStateRefreshReceiptRef: currentState.latestStateRefreshReceiptRef,
      latestStatePromotionReceiptRef:
          currentState.latestStatePromotionReceiptRef,
      latestStateDecisionStatus: currentState.latestStateDecisionStatus,
      latestStateDecisionArtifactRef:
          currentState.latestStateDecisionArtifactRef,
      latestStateDecisionRationale: currentState.latestStateDecisionRationale,
      latestStateDecisionRecordedAt: currentState.latestStateDecisionRecordedAt,
      latestStateRevalidationStatus: currentState.latestStateRevalidationStatus,
      latestStateRevalidationReceiptRef:
          currentState.latestStateRevalidationReceiptRef,
      latestStateRevalidationArtifactRef:
          currentState.latestStateRevalidationArtifactRef,
      latestStateRevalidatedAt: currentState.latestStateRevalidatedAt,
      latestStateRecoveryDecisionStatus: 'restage_required_confirmed',
      latestStateRecoveryDecisionArtifactRef: recoveryArtifactRef,
      latestStateRecoveryDecisionRationale: rationale.trim().isEmpty
          ? 'The expired served basis must remain out of service until a new staged refresh is reviewed.'
          : rationale.trim(),
      latestStateRecoveryDecisionRecordedAt: now,
      currentBasisStatus: 'expired_latest_state_served_basis',
      latestStateHydrationStatus: 'expired_basis_restage_required_confirmed',
      latestStatePromotionReadiness:
          'restage_required_before_served_basis_reuse',
      latestStatePromotionBlockedReasons: nextBlockedReasons,
      hydrationFreshnessPosture: 'expired_basis_restage_required_confirmed',
      latestStateRefreshCadenceHours:
          currentState.latestStateRefreshCadenceHours,
      latestStateRefreshCadenceStatus:
          currentState.latestStateRefreshCadenceStatus,
      latestStateRefreshReferenceAt: currentState.latestStateRefreshReferenceAt,
      latestStateRefreshPolicySummaries:
          currentState.latestStateRefreshPolicySummaries,
      latestStateDeploymentReceiptRef:
          currentState.latestStateDeploymentReceiptRef,
    );
    await _writePrettyJson(
      File(
        path.join(
            refreshDir.path, 'basis_restore_decision.restage_required.json'),
      ),
      <String, dynamic>{
        'environmentId': normalizedEnvironmentId,
        'supportedPlaceRef': decidedState.supportedPlaceRef,
        'decision': 'restage_required_confirmed',
        'decidedAt': now.toIso8601String(),
        'servedBasisRef': decidedState.servedBasisRef,
        'latestStateRevalidationReceiptRef':
            decidedState.latestStateRevalidationReceiptRef,
        'rationale': decidedState.latestStateRecoveryDecisionRationale,
      },
    );
    await _writePrettyJson(
      File(path.join(root.path, 'served_city_pack_basis.current.json')),
      decidedState.toJson(),
    );
    return decidedState;
  }

  Future<ReplaySimulationLabServedBasisState> restoreExpiredServedBasis({
    required String environmentId,
    String rationale = '',
  }) async {
    final normalizedEnvironmentId = environmentId.trim();
    final currentState = await getServedBasisState(
      environmentId: normalizedEnvironmentId,
    );
    if (currentState == null) {
      throw StateError('No served-basis state exists for $environmentId.');
    }
    if (currentState.currentBasisStatus !=
        'expired_latest_state_served_basis') {
      throw StateError(
        'Only an expired latest-state served basis can be restored after review. Current status is `${currentState.currentBasisStatus}`.',
      );
    }
    if (currentState.latestStatePromotionReadiness !=
        'ready_for_bounded_served_basis_restore') {
      throw StateError(
        'The expired served basis is not ready for restore review. Current readiness is `${currentState.latestStatePromotionReadiness}`.',
      );
    }
    final refreshId = _extractBasisRefreshId(currentState.servedBasisRef);
    if (refreshId == null) {
      throw StateError(
        'Unable to resolve the served basis refresh lineage for `${currentState.servedBasisRef}`.',
      );
    }
    _requireRestoreSourceBindings(
      state: currentState,
      action: 'restore',
    );
    final now = _nowProvider().toUtc();
    final root = await _registeredEnvironmentDirectory(normalizedEnvironmentId);
    final refreshDir =
        Directory(path.join(root.path, 'basis_refreshes', refreshId))
          ..createSync(recursive: true);
    final relativeRoot = _worldSimulationLabRelativePath(
      'registered_environments',
      normalizedEnvironmentId,
    );
    final recoveryArtifactRef =
        '$relativeRoot/basis_refreshes/$refreshId/basis_restore_decision.restored.json';
    final deploymentReceiptRef = _servedBasisDeploymentReceiptRef(
      relativeRoot: relativeRoot,
      refreshId: refreshId,
      deploymentMode: 'restored',
    );
    final restoredState = ReplaySimulationLabServedBasisState(
      environmentId: currentState.environmentId,
      supportedPlaceRef: currentState.supportedPlaceRef,
      stagedAt: now,
      servedBasisRef: currentState.servedBasisRef,
      latestStateEvidenceRefsByFamily:
          currentState.latestStateEvidenceRefsByFamily,
      latestStateEvidenceSelectionSummariesByFamily:
          currentState.latestStateEvidenceSelectionSummariesByFamily,
      latestStateEvidenceAgingStatusesByFamily:
          currentState.latestStateEvidenceAgingStatusesByFamily,
      latestStateEvidenceAgingSummariesByFamily:
          currentState.latestStateEvidenceAgingSummariesByFamily,
      latestStateEvidenceAgingTransitionsByFamily:
          currentState.latestStateEvidenceAgingTransitionsByFamily,
      latestStateEvidenceAgingTrendsByFamily:
          currentState.latestStateEvidenceAgingTrendsByFamily,
      latestStateEvidenceAgingTrendSummariesByFamily:
          currentState.latestStateEvidenceAgingTrendSummariesByFamily,
      latestStateEvidencePolicyActionsByFamily:
          currentState.latestStateEvidencePolicyActionsByFamily,
      latestStateEvidencePolicyActionSummariesByFamily:
          currentState.latestStateEvidencePolicyActionSummariesByFamily,
      latestStateEvidenceRestageTargetsByFamily:
          currentState.latestStateEvidenceRestageTargetsByFamily,
      latestStateEvidenceRestageTargetSummariesByFamily:
          currentState.latestStateEvidenceRestageTargetSummariesByFamily,
      cityPackStructuralRef: currentState.cityPackStructuralRef,
      priorServedBasisRef: currentState.priorServedBasisRef,
      basisRefreshLineageRef: currentState.basisRefreshLineageRef,
      latestStateRefreshReceiptRef: currentState.latestStateRefreshReceiptRef,
      latestStatePromotionReceiptRef:
          currentState.latestStatePromotionReceiptRef,
      latestStateDecisionStatus: currentState.latestStateDecisionStatus,
      latestStateDecisionArtifactRef:
          currentState.latestStateDecisionArtifactRef,
      latestStateDecisionRationale: currentState.latestStateDecisionRationale,
      latestStateDecisionRecordedAt: currentState.latestStateDecisionRecordedAt,
      latestStateRevalidationStatus: currentState.latestStateRevalidationStatus,
      latestStateRevalidationReceiptRef:
          currentState.latestStateRevalidationReceiptRef,
      latestStateRevalidationArtifactRef:
          currentState.latestStateRevalidationArtifactRef,
      latestStateRevalidatedAt: currentState.latestStateRevalidatedAt,
      latestStateRecoveryDecisionStatus: 'restored_after_review',
      latestStateRecoveryDecisionArtifactRef: recoveryArtifactRef,
      latestStateRecoveryDecisionRationale: rationale.trim().isEmpty
          ? 'Restored after bounded review confirmed current latest-state evidence is strong enough to serve again.'
          : rationale.trim(),
      latestStateRecoveryDecisionRecordedAt: now,
      currentBasisStatus: 'latest_state_served_basis',
      latestStateHydrationStatus: 'latest_state_basis_restored_after_review',
      latestStatePromotionReadiness: 'restored_to_served_basis_after_review',
      latestStatePromotionBlockedReasons: const <String>[],
      hydrationFreshnessPosture:
          'served_basis_restored_from_revalidated_receipts',
      latestStateRefreshCadenceHours:
          currentState.latestStateRefreshCadenceHours,
      latestStateRefreshCadenceStatus: _latestStateRefreshCadenceStatus(
        refreshCadenceHours: currentState.latestStateRefreshCadenceHours,
        referenceAt: now,
      ),
      latestStateRefreshReferenceAt: now,
      latestStateRefreshPolicySummaries:
          currentState.latestStateRefreshPolicySummaries,
      latestStateDeploymentReceiptRef: deploymentReceiptRef,
    );
    await _writePrettyJson(
      File(path.join(refreshDir.path, 'basis_restore_decision.restored.json')),
      <String, dynamic>{
        'environmentId': normalizedEnvironmentId,
        'supportedPlaceRef': restoredState.supportedPlaceRef,
        'decision': 'restored_after_review',
        'decidedAt': now.toIso8601String(),
        'servedBasisRef': restoredState.servedBasisRef,
        'latestStateRevalidationReceiptRef':
            restoredState.latestStateRevalidationReceiptRef,
        'rationale': restoredState.latestStateRecoveryDecisionRationale,
      },
    );
    await _writePrettyJson(
      File(
        path.join(
          refreshDir.path,
          'served_basis_deployment_receipts.restored.json',
        ),
      ),
      <String, dynamic>{
        'environmentId': normalizedEnvironmentId,
        'supportedPlaceRef': restoredState.supportedPlaceRef,
        'receiptKind': 'downward_deployment_receipt',
        'deploymentMode': 'restored',
        'deployedAt': now.toIso8601String(),
        'deploymentRef': deploymentReceiptRef,
        'promotionRef': restoredState.latestStatePromotionReceiptRef,
        'revalidationRef': restoredState.latestStateRevalidationReceiptRef,
        'targetStateRef': '$relativeRoot/served_city_pack_basis.current.json',
        'servedBasisRef': restoredState.servedBasisRef,
        'targetBasisStatus': restoredState.currentBasisStatus,
      },
    );
    await _writePrettyJson(
      File(path.join(root.path, 'served_city_pack_basis.current.json')),
      restoredState.toJson(),
    );
    return restoredState;
  }

  Future<ReplaySimulationLabRuntimeState> setActiveLabVariantTarget({
    required String environmentId,
    String? variantId,
  }) async {
    final normalizedEnvironmentId = environmentId.trim();
    final environments = await listAvailableEnvironments();
    final descriptor = environments.where(
      (entry) => entry.environmentId == normalizedEnvironmentId,
    );
    if (descriptor.isEmpty) {
      throw StateError('Unknown simulation environment: $environmentId');
    }
    String? resolvedVariantId;
    String? resolvedVariantLabel;
    final normalizedVariantId = variantId?.trim();
    if (normalizedVariantId != null && normalizedVariantId.isNotEmpty) {
      final variants =
          await listLabVariants(environmentId: normalizedEnvironmentId);
      final matching = variants.where(
        (entry) => entry.variantId == normalizedVariantId,
      );
      if (matching.isEmpty) {
        throw StateError(
          'Unknown simulation variant `$normalizedVariantId` for environment `$normalizedEnvironmentId`.',
        );
      }
      final selected = matching.first;
      resolvedVariantId = selected.variantId;
      resolvedVariantLabel = selected.label;
    }
    final existingState =
        await getLabRuntimeState(environmentId: normalizedEnvironmentId);
    final state = ReplaySimulationLabRuntimeState(
      environmentId: normalizedEnvironmentId,
      updatedAt: _nowProvider().toUtc(),
      activeVariantId: resolvedVariantId,
      activeVariantLabel: resolvedVariantLabel,
      targetActionDecisions: existingState.targetActionDecisions,
    );
    final root = await _registeredEnvironmentDirectory(normalizedEnvironmentId);
    await _writePrettyJson(
      File(path.join(root.path, 'world_simulation_lab_state.json')),
      state.toJson(),
    );
    await _stageReplaySupervisorObservation(
      environmentId: normalizedEnvironmentId,
      cityCode: descriptor.first.cityCode,
      occurredAtUtc: state.updatedAt,
      observationKind: 'replay_simulation_lab_variant_target',
      summary: resolvedVariantId == null
          ? 'Replay simulation lab next-run target was set to `base_run` for `$normalizedEnvironmentId`.'
          : 'Replay simulation lab next-run target was set to `${resolvedVariantLabel ?? resolvedVariantId}` for `$normalizedEnvironmentId`.',
      upwardDomainHints: const <String>[
        'simulation',
        'replay',
        'supervision',
      ],
      upwardReferencedEntities: <String>[
        'environment:$normalizedEnvironmentId',
        if ((resolvedVariantId ?? '').isNotEmpty) 'variant:$resolvedVariantId',
      ],
      upwardQuestions: const <String>[
        'Should the next-run target remain on this lane, or is a different variant needed to improve supervision quality?',
      ],
      upwardSignalTags: <String>[
        'origin:replay_simulation_admin_service',
        'phase:world_simulation_lab_variant_target',
        'next_run_target:${resolvedVariantId ?? 'base_run'}',
      ],
      boundedMetadata: <String, dynamic>{
        'environmentId': normalizedEnvironmentId,
        'activeVariantId': resolvedVariantId,
        if ((resolvedVariantId ?? '').isNotEmpty)
          'variantId': resolvedVariantId,
        if ((resolvedVariantLabel ?? '').isNotEmpty)
          'variantLabel': resolvedVariantLabel,
      },
    );
    return state;
  }

  Future<ReplaySimulationLabRuntimeState> recordLabTargetActionDecision({
    required String environmentId,
    String? variantId,
    required String suggestedAction,
    required String suggestedReason,
    required String selectedAction,
  }) async {
    final normalizedEnvironmentId = environmentId.trim();
    final environments = await listAvailableEnvironments();
    final descriptor = environments.where(
      (entry) => entry.environmentId == normalizedEnvironmentId,
    );
    if (descriptor.isEmpty) {
      throw StateError('Unknown simulation environment: $environmentId');
    }
    final normalizedVariantId = variantId?.trim();
    String? resolvedVariantId;
    String? resolvedVariantLabel;
    if (normalizedVariantId != null && normalizedVariantId.isNotEmpty) {
      final variants =
          await listLabVariants(environmentId: normalizedEnvironmentId);
      final matching = variants.where(
        (entry) => entry.variantId == normalizedVariantId,
      );
      if (matching.isEmpty) {
        throw StateError(
          'Unknown simulation variant `$normalizedVariantId` for environment `$normalizedEnvironmentId`.',
        );
      }
      final selected = matching.first;
      resolvedVariantId = selected.variantId;
      resolvedVariantLabel = selected.label;
    }
    final normalizedSuggestedAction =
        _normalizeLabTargetAction(suggestedAction);
    final normalizedSelectedAction = _normalizeLabTargetAction(selectedAction);
    final existingState =
        await getLabRuntimeState(environmentId: normalizedEnvironmentId);
    ReplaySimulationLabTargetActionDecision? existingDecision;
    for (final entry in existingState.targetActionDecisions) {
      if (_sameSimulationLabTarget(entry.variantId, resolvedVariantId)) {
        existingDecision = entry;
        break;
      }
    }
    final decision = ReplaySimulationLabTargetActionDecision(
      environmentId: normalizedEnvironmentId,
      updatedAt: _nowProvider().toUtc(),
      suggestedAction: normalizedSuggestedAction,
      suggestedReason: suggestedReason.trim(),
      selectedAction: normalizedSelectedAction,
      acceptedSuggestion: normalizedSuggestedAction == normalizedSelectedAction,
      alertAcknowledgedAt: existingDecision?.alertAcknowledgedAt,
      alertAcknowledgedSeverityCode:
          existingDecision?.alertAcknowledgedSeverityCode,
      alertEscalatedAt: existingDecision?.alertEscalatedAt,
      alertEscalatedSeverityCode: existingDecision?.alertEscalatedSeverityCode,
      alertSnoozedUntil: existingDecision?.alertSnoozedUntil,
      alertSnoozedSeverityCode: existingDecision?.alertSnoozedSeverityCode,
      variantId: resolvedVariantId,
      variantLabel: resolvedVariantLabel,
    );
    final updatedDecisions = existingState.targetActionDecisions
        .where(
          (entry) =>
              !_sameSimulationLabTarget(entry.variantId, resolvedVariantId),
        )
        .toList(growable: true)
      ..insert(0, decision);
    final state = ReplaySimulationLabRuntimeState(
      environmentId: normalizedEnvironmentId,
      updatedAt: decision.updatedAt,
      activeVariantId: existingState.activeVariantId,
      activeVariantLabel: existingState.activeVariantLabel,
      targetActionDecisions: updatedDecisions,
    );
    final root = await _registeredEnvironmentDirectory(normalizedEnvironmentId);
    await _writePrettyJson(
      File(path.join(root.path, 'world_simulation_lab_state.json')),
      state.toJson(),
    );
    await _stageReplaySupervisorObservation(
      environmentId: normalizedEnvironmentId,
      cityCode: descriptor.first.cityCode,
      occurredAtUtc: decision.updatedAt,
      observationKind: 'replay_simulation_lab_target_action_decision',
      summary: decision.acceptedSuggestion
          ? 'Replay simulation lab target action accepted the suggested `${decision.suggestedAction}` posture for `${resolvedVariantId ?? 'base_run'}`.'
          : 'Replay simulation lab target action overrode the suggested `${decision.suggestedAction}` posture with `${decision.selectedAction}` for `${resolvedVariantId ?? 'base_run'}`.',
      upwardDomainHints: const <String>[
        'simulation',
        'replay',
        'supervision',
      ],
      upwardReferencedEntities: <String>[
        'environment:$normalizedEnvironmentId',
        if ((resolvedVariantId ?? '').isNotEmpty) 'variant:$resolvedVariantId',
      ],
      upwardQuestions: decision.acceptedSuggestion
          ? const <String>[
              'Does repeated agreement with suggested simulation actions indicate a stable supervisory heuristic worth preserving?',
            ]
          : const <String>[
              'Why is the suggested simulation action being overridden, and should the supervisory heuristic be refined?',
            ],
      upwardSignalTags: <String>[
        'origin:replay_simulation_admin_service',
        'phase:world_simulation_lab_target_action_decision',
        'suggested_action:${decision.suggestedAction}',
        'selected_action:${decision.selectedAction}',
        'accepted_suggestion:${decision.acceptedSuggestion}',
      ],
      boundedMetadata: <String, dynamic>{
        'environmentId': normalizedEnvironmentId,
        'suggestedAction': decision.suggestedAction,
        'selectedAction': decision.selectedAction,
        'acceptedSuggestion': decision.acceptedSuggestion,
        'suggestedReason': decision.suggestedReason,
        if ((resolvedVariantId ?? '').isNotEmpty)
          'variantId': resolvedVariantId,
        if ((resolvedVariantLabel ?? '').isNotEmpty)
          'variantLabel': resolvedVariantLabel,
      },
    );
    return state;
  }

  Future<ReplaySimulationLabRuntimeState> acknowledgeLabTargetAlert({
    required String environmentId,
    String? variantId,
    required String alertSeverityCode,
  }) async {
    final normalizedEnvironmentId = environmentId.trim();
    final normalizedVariantId = variantId?.trim();
    final existingState =
        await getLabRuntimeState(environmentId: normalizedEnvironmentId);
    ReplaySimulationLabTargetActionDecision? existingDecision;
    for (final entry in existingState.targetActionDecisions) {
      if (_sameSimulationLabTarget(entry.variantId, normalizedVariantId)) {
        existingDecision = entry;
        break;
      }
    }
    if (existingDecision == null) {
      throw StateError(
        'No world simulation lab target action exists for `${normalizedVariantId ?? 'base_run'}` in `$normalizedEnvironmentId`.',
      );
    }
    final acknowledgedDecision = ReplaySimulationLabTargetActionDecision(
      environmentId: existingDecision.environmentId,
      updatedAt: existingDecision.updatedAt,
      suggestedAction: existingDecision.suggestedAction,
      suggestedReason: existingDecision.suggestedReason,
      selectedAction: existingDecision.selectedAction,
      acceptedSuggestion: existingDecision.acceptedSuggestion,
      alertAcknowledgedAt: _nowProvider().toUtc(),
      alertAcknowledgedSeverityCode: alertSeverityCode.trim(),
      alertEscalatedAt: existingDecision.alertEscalatedAt,
      alertEscalatedSeverityCode: existingDecision.alertEscalatedSeverityCode,
      alertSnoozedUntil: existingDecision.alertSnoozedUntil,
      alertSnoozedSeverityCode: existingDecision.alertSnoozedSeverityCode,
      variantId: existingDecision.variantId,
      variantLabel: existingDecision.variantLabel,
    );
    final updatedDecisions = existingState.targetActionDecisions
        .where(
          (entry) =>
              !_sameSimulationLabTarget(entry.variantId, normalizedVariantId),
        )
        .toList(growable: true)
      ..insert(0, acknowledgedDecision);
    final state = ReplaySimulationLabRuntimeState(
      environmentId: normalizedEnvironmentId,
      updatedAt: _nowProvider().toUtc(),
      activeVariantId: existingState.activeVariantId,
      activeVariantLabel: existingState.activeVariantLabel,
      targetActionDecisions: updatedDecisions,
    );
    final root = await _registeredEnvironmentDirectory(normalizedEnvironmentId);
    await _writePrettyJson(
      File(path.join(root.path, 'world_simulation_lab_state.json')),
      state.toJson(),
    );
    return state;
  }

  Future<GovernedUpwardLearningIntakeResult?>
      _stageReplaySupervisorObservation({
    required String environmentId,
    required String cityCode,
    required DateTime occurredAtUtc,
    required String observationKind,
    required String summary,
    required Map<String, dynamic> boundedMetadata,
    List<String> upwardDomainHints = const <String>[],
    List<String> upwardReferencedEntities = const <String>[],
    List<String> upwardQuestions = const <String>[],
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
    final normalizedDomainHints = <String>{
      'simulation',
      'replay',
      ...upwardDomainHints.map((value) => value.trim()).where(
            (value) => value.isNotEmpty,
          ),
    }.toList()
      ..sort();
    final requestBoundDomainHints = <String>{
      'supervisor',
      ...normalizedDomainHints,
    }.toList()
      ..sort();
    final normalizedReferencedEntities = upwardReferencedEntities
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final normalizedQuestions = upwardQuestions
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final normalizedSignalTags = <String>{
      'source:supervisor',
      'observation_kind:${observationKind.trim()}',
      ...upwardSignalTags.map((value) => value.trim()).where(
            (value) => value.isNotEmpty,
          ),
      ...requestBoundDomainHints.map((domainId) => 'domain:$domainId'),
    }.toList()
      ..sort();
    final airGapArtifact = const UpwardAirGapService().issueArtifact(
      originPlane: 'supervisor_daemon',
      sourceKind: 'supervisor_bounded_observation_intake',
      sourceScope: 'supervisor',
      destinationCeiling: 'reality_model_agent',
      issuedAtUtc: DateTime.now().toUtc(),
      pseudonymousActorRef: 'replay_supervisor:$environmentId',
      sanitizedPayload: <String, dynamic>{
        'environmentId': environmentId,
        'cityCode': cityCode,
        'observationKind': observationKind,
        'summary': trimmedSummary,
        'upwardDomainHints': requestBoundDomainHints,
        'upwardReferencedEntities': normalizedReferencedEntities,
        'upwardQuestions': normalizedQuestions,
        'upwardSignalTags': normalizedSignalTags,
        'boundedMetadata': boundedMetadata,
      },
    );
    return governedService.stageSupervisorAssistantObservationIntake(
      observerId: 'replay_supervisor:$environmentId',
      observerKind: 'supervisor',
      occurredAtUtc: occurredAtUtc,
      summary: trimmedSummary,
      airGapArtifact: airGapArtifact,
      environmentId: environmentId,
      cityCode: cityCode,
      observationKind: observationKind,
      upwardDomainHints: normalizedDomainHints,
      upwardReferencedEntities: normalizedReferencedEntities,
      upwardQuestions: normalizedQuestions,
      upwardSignalTags: normalizedSignalTags,
      boundedMetadata: boundedMetadata,
    );
  }

  Future<ReplaySimulationLabRuntimeState> escalateLabTargetAlert({
    required String environmentId,
    String? variantId,
    required String alertSeverityCode,
  }) async {
    final normalizedEnvironmentId = environmentId.trim();
    final normalizedVariantId = variantId?.trim();
    final existingState =
        await getLabRuntimeState(environmentId: normalizedEnvironmentId);
    ReplaySimulationLabTargetActionDecision? existingDecision;
    for (final entry in existingState.targetActionDecisions) {
      if (_sameSimulationLabTarget(entry.variantId, normalizedVariantId)) {
        existingDecision = entry;
        break;
      }
    }
    if (existingDecision == null) {
      throw StateError(
        'No world simulation lab target action exists for `${normalizedVariantId ?? 'base_run'}` in `$normalizedEnvironmentId`.',
      );
    }
    final escalatedDecision = ReplaySimulationLabTargetActionDecision(
      environmentId: existingDecision.environmentId,
      updatedAt: existingDecision.updatedAt,
      suggestedAction: existingDecision.suggestedAction,
      suggestedReason: existingDecision.suggestedReason,
      selectedAction: existingDecision.selectedAction,
      acceptedSuggestion: existingDecision.acceptedSuggestion,
      alertAcknowledgedAt: existingDecision.alertAcknowledgedAt,
      alertAcknowledgedSeverityCode:
          existingDecision.alertAcknowledgedSeverityCode,
      alertEscalatedAt: _nowProvider().toUtc(),
      alertEscalatedSeverityCode: alertSeverityCode.trim(),
      alertSnoozedUntil: null,
      alertSnoozedSeverityCode: null,
      variantId: existingDecision.variantId,
      variantLabel: existingDecision.variantLabel,
    );
    final updatedDecisions = existingState.targetActionDecisions
        .where(
          (entry) =>
              !_sameSimulationLabTarget(entry.variantId, normalizedVariantId),
        )
        .toList(growable: true)
      ..insert(0, escalatedDecision);
    final state = ReplaySimulationLabRuntimeState(
      environmentId: normalizedEnvironmentId,
      updatedAt: _nowProvider().toUtc(),
      activeVariantId: existingState.activeVariantId,
      activeVariantLabel: existingState.activeVariantLabel,
      targetActionDecisions: updatedDecisions,
    );
    final root = await _registeredEnvironmentDirectory(normalizedEnvironmentId);
    await _writePrettyJson(
      File(path.join(root.path, 'world_simulation_lab_state.json')),
      state.toJson(),
    );
    return state;
  }

  Future<ReplaySimulationLabRuntimeState> snoozeLabTargetAlert({
    required String environmentId,
    String? variantId,
    required String alertSeverityCode,
    required DateTime snoozedUntilUtc,
  }) async {
    final normalizedEnvironmentId = environmentId.trim();
    final normalizedVariantId = variantId?.trim();
    final existingState =
        await getLabRuntimeState(environmentId: normalizedEnvironmentId);
    ReplaySimulationLabTargetActionDecision? existingDecision;
    for (final entry in existingState.targetActionDecisions) {
      if (_sameSimulationLabTarget(entry.variantId, normalizedVariantId)) {
        existingDecision = entry;
        break;
      }
    }
    if (existingDecision == null) {
      throw StateError(
        'No world simulation lab target action exists for `${normalizedVariantId ?? 'base_run'}` in `$normalizedEnvironmentId`.',
      );
    }
    final snoozedDecision = ReplaySimulationLabTargetActionDecision(
      environmentId: existingDecision.environmentId,
      updatedAt: existingDecision.updatedAt,
      suggestedAction: existingDecision.suggestedAction,
      suggestedReason: existingDecision.suggestedReason,
      selectedAction: existingDecision.selectedAction,
      acceptedSuggestion: existingDecision.acceptedSuggestion,
      alertAcknowledgedAt: existingDecision.alertAcknowledgedAt,
      alertAcknowledgedSeverityCode:
          existingDecision.alertAcknowledgedSeverityCode,
      alertEscalatedAt: null,
      alertEscalatedSeverityCode: null,
      alertSnoozedUntil: snoozedUntilUtc.toUtc(),
      alertSnoozedSeverityCode: alertSeverityCode.trim(),
      variantId: existingDecision.variantId,
      variantLabel: existingDecision.variantLabel,
    );
    final updatedDecisions = existingState.targetActionDecisions
        .where(
          (entry) =>
              !_sameSimulationLabTarget(entry.variantId, normalizedVariantId),
        )
        .toList(growable: true)
      ..insert(0, snoozedDecision);
    final state = ReplaySimulationLabRuntimeState(
      environmentId: normalizedEnvironmentId,
      updatedAt: _nowProvider().toUtc(),
      activeVariantId: existingState.activeVariantId,
      activeVariantLabel: existingState.activeVariantLabel,
      targetActionDecisions: updatedDecisions,
    );
    final root = await _registeredEnvironmentDirectory(normalizedEnvironmentId);
    await _writePrettyJson(
      File(path.join(root.path, 'world_simulation_lab_state.json')),
      state.toJson(),
    );
    return state;
  }

  Future<ReplaySimulationLabRuntimeState> clearEscalatedLabTargetAlert({
    required String environmentId,
    String? variantId,
  }) async {
    final normalizedEnvironmentId = environmentId.trim();
    final normalizedVariantId = variantId?.trim();
    final existingState =
        await getLabRuntimeState(environmentId: normalizedEnvironmentId);
    ReplaySimulationLabTargetActionDecision? existingDecision;
    for (final entry in existingState.targetActionDecisions) {
      if (_sameSimulationLabTarget(entry.variantId, normalizedVariantId)) {
        existingDecision = entry;
        break;
      }
    }
    if (existingDecision == null) {
      throw StateError(
        'No world simulation lab target action exists for `${normalizedVariantId ?? 'base_run'}` in `$normalizedEnvironmentId`.',
      );
    }
    final clearedDecision = ReplaySimulationLabTargetActionDecision(
      environmentId: existingDecision.environmentId,
      updatedAt: existingDecision.updatedAt,
      suggestedAction: existingDecision.suggestedAction,
      suggestedReason: existingDecision.suggestedReason,
      selectedAction: existingDecision.selectedAction,
      acceptedSuggestion: existingDecision.acceptedSuggestion,
      alertAcknowledgedAt: existingDecision.alertAcknowledgedAt,
      alertAcknowledgedSeverityCode:
          existingDecision.alertAcknowledgedSeverityCode,
      alertEscalatedAt: null,
      alertEscalatedSeverityCode: null,
      alertSnoozedUntil: existingDecision.alertSnoozedUntil,
      alertSnoozedSeverityCode: existingDecision.alertSnoozedSeverityCode,
      variantId: existingDecision.variantId,
      variantLabel: existingDecision.variantLabel,
    );
    final updatedDecisions = existingState.targetActionDecisions
        .where(
          (entry) =>
              !_sameSimulationLabTarget(entry.variantId, normalizedVariantId),
        )
        .toList(growable: true)
      ..insert(0, clearedDecision);
    final state = ReplaySimulationLabRuntimeState(
      environmentId: normalizedEnvironmentId,
      updatedAt: _nowProvider().toUtc(),
      activeVariantId: existingState.activeVariantId,
      activeVariantLabel: existingState.activeVariantLabel,
      targetActionDecisions: updatedDecisions,
    );
    final root = await _registeredEnvironmentDirectory(normalizedEnvironmentId);
    await _writePrettyJson(
      File(path.join(root.path, 'world_simulation_lab_state.json')),
      state.toJson(),
    );
    return state;
  }

  Future<ReplaySimulationLabRuntimeState> unsnoozeLabTargetAlert({
    required String environmentId,
    String? variantId,
  }) async {
    final normalizedEnvironmentId = environmentId.trim();
    final normalizedVariantId = variantId?.trim();
    final existingState =
        await getLabRuntimeState(environmentId: normalizedEnvironmentId);
    ReplaySimulationLabTargetActionDecision? existingDecision;
    for (final entry in existingState.targetActionDecisions) {
      if (_sameSimulationLabTarget(entry.variantId, normalizedVariantId)) {
        existingDecision = entry;
        break;
      }
    }
    if (existingDecision == null) {
      throw StateError(
        'No world simulation lab target action exists for `${normalizedVariantId ?? 'base_run'}` in `$normalizedEnvironmentId`.',
      );
    }
    final clearedDecision = ReplaySimulationLabTargetActionDecision(
      environmentId: existingDecision.environmentId,
      updatedAt: existingDecision.updatedAt,
      suggestedAction: existingDecision.suggestedAction,
      suggestedReason: existingDecision.suggestedReason,
      selectedAction: existingDecision.selectedAction,
      acceptedSuggestion: existingDecision.acceptedSuggestion,
      alertAcknowledgedAt: existingDecision.alertAcknowledgedAt,
      alertAcknowledgedSeverityCode:
          existingDecision.alertAcknowledgedSeverityCode,
      alertEscalatedAt: existingDecision.alertEscalatedAt,
      alertEscalatedSeverityCode: existingDecision.alertEscalatedSeverityCode,
      alertSnoozedUntil: null,
      alertSnoozedSeverityCode: null,
      variantId: existingDecision.variantId,
      variantLabel: existingDecision.variantLabel,
    );
    final updatedDecisions = existingState.targetActionDecisions
        .where(
          (entry) =>
              !_sameSimulationLabTarget(entry.variantId, normalizedVariantId),
        )
        .toList(growable: true)
      ..insert(0, clearedDecision);
    final state = ReplaySimulationLabRuntimeState(
      environmentId: normalizedEnvironmentId,
      updatedAt: _nowProvider().toUtc(),
      activeVariantId: existingState.activeVariantId,
      activeVariantLabel: existingState.activeVariantLabel,
      targetActionDecisions: updatedDecisions,
    );
    final root = await _registeredEnvironmentDirectory(normalizedEnvironmentId);
    await _writePrettyJson(
      File(path.join(root.path, 'world_simulation_lab_state.json')),
      state.toJson(),
    );
    return state;
  }

  Future<ReplaySimulationLabRerunRequest> createLabRerunRequest({
    required String environmentId,
    String? variantId,
    List<String> requestNotes = const <String>[],
  }) async {
    final normalizedEnvironmentId = environmentId.trim();
    final snapshot = await getSnapshot(environmentId: normalizedEnvironmentId);
    final runtimeState =
        await getLabRuntimeState(environmentId: snapshot.environmentId);
    final effectiveVariantId = variantId == null || variantId.trim().isEmpty
        ? runtimeState.activeVariantId
        : variantId.trim();
    String? effectiveVariantLabel = runtimeState.activeVariantLabel;
    if (effectiveVariantId != null && effectiveVariantId.isNotEmpty) {
      final variants =
          await listLabVariants(environmentId: normalizedEnvironmentId);
      final matching = variants.where(
        (entry) => entry.variantId == effectiveVariantId,
      );
      if (matching.isEmpty) {
        throw StateError(
          'Unknown simulation variant `$effectiveVariantId` for environment `${snapshot.environmentId}`.',
        );
      }
      effectiveVariantLabel = matching.first.label;
    }
    ReplaySimulationLabTargetActionDecision? targetActionDecision;
    for (final decision in runtimeState.targetActionDecisions) {
      if (_sameSimulationLabTarget(decision.variantId, effectiveVariantId)) {
        targetActionDecision = decision;
        break;
      }
    }

    final history = await listLabOutcomes(
      environmentId: snapshot.environmentId,
      limit: 0,
    );
    ReplaySimulationLabOutcomeRecord? lineage;
    for (final entry in history) {
      final entryVariantId = entry.variantId?.trim();
      if ((effectiveVariantId == null || effectiveVariantId.isEmpty) &&
          (entryVariantId == null || entryVariantId.isEmpty)) {
        lineage = entry;
        break;
      }
      if (entryVariantId == effectiveVariantId) {
        lineage = entry;
        break;
      }
    }

    final documentsDirectory = await _documentsDirectoryProvider();
    final requestedAt = _nowProvider().toUtc();
    final stamp = requestedAt.toIso8601String().replaceAll(':', '-');
    final requestId =
        '${_normalizeToken(snapshot.environmentId, separator: '-')}-rerun-$stamp';
    final requestRoot = Directory(
      path.join(
        documentsDirectory.path,
        'AVRAI',
        'world_simulation_lab',
        snapshot.environmentId,
        'rerun_requests',
        requestId,
      ),
    )..createSync(recursive: true);
    final normalizedNotes = requestNotes
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
    final request = ReplaySimulationLabRerunRequest(
      requestId: requestId,
      environmentId: snapshot.environmentId,
      cityCode: snapshot.cityCode,
      replayYear: snapshot.replayYear,
      requestedAt: requestedAt,
      requestStatus: 'queued',
      requestRoot: requestRoot.path,
      requestJsonPath: path.join(
          requestRoot.path, 'world_simulation_lab_rerun_request.json'),
      readmePath: path.join(requestRoot.path, 'WORLD_SIMULATION_LAB_RERUN.md'),
      requestNotes: normalizedNotes,
      sidecarRefs: snapshot.foundation.sidecarRefs,
      cityPackStructuralRef:
          snapshot.foundation.metadata['cityPackStructuralRef']?.toString(),
      variantId: effectiveVariantId,
      variantLabel: effectiveVariantLabel,
      lineageOutcomeJsonPath: lineage?.outcomeJsonPath,
      lineageDisposition: lineage?.disposition.toWireValue(),
      lineageRecordedAt: lineage?.recordedAt,
      targetActionSuggested: targetActionDecision?.suggestedAction,
      targetActionSuggestedReason: targetActionDecision?.suggestedReason,
      targetActionSelected: targetActionDecision?.selectedAction,
      targetActionAcceptedSuggestion: targetActionDecision?.acceptedSuggestion,
      targetActionUpdatedAt: targetActionDecision?.updatedAt,
    );
    await _persistLabRerunRequest(snapshot: snapshot, request: request);
    return request;
  }

  Future<ReplaySimulationLabRerunRequest> startLabRerunRequest({
    required String environmentId,
    required String requestId,
  }) {
    return _updateLabRerunRequestStatus(
      environmentId: environmentId,
      requestId: requestId,
      nextStatus: 'running',
    );
  }

  Future<ReplaySimulationLabRerunRequest> completeLabRerunRequest({
    required String environmentId,
    required String requestId,
  }) {
    return _updateLabRerunRequestStatus(
      environmentId: environmentId,
      requestId: requestId,
      nextStatus: 'completed',
    );
  }

  Future<List<ReplaySimulationLabRerunRequest>> listLabRerunRequests({
    String? environmentId,
    int limit = 12,
  }) async {
    final documentsDirectory = await _documentsDirectoryProvider();
    final rootPath = path.join(
      documentsDirectory.path,
      'AVRAI',
      'world_simulation_lab',
    );
    final targetRoot = environmentId == null
        ? Directory(rootPath)
        : Directory(path.join(rootPath, environmentId));
    if (!targetRoot.existsSync()) {
      return const <ReplaySimulationLabRerunRequest>[];
    }
    final requestFiles = targetRoot
        .listSync(recursive: true)
        .whereType<File>()
        .where(
          (file) =>
              path.basename(file.path) ==
              'world_simulation_lab_rerun_request.json',
        )
        .toList(growable: false);
    final requests = <ReplaySimulationLabRerunRequest>[];
    for (final file in requestFiles) {
      try {
        final raw = file.readAsStringSync().trim();
        if (raw.isEmpty) {
          continue;
        }
        requests.add(
          ReplaySimulationLabRerunRequest.fromJson(
            Map<String, dynamic>.from(
              jsonDecode(raw) as Map<String, dynamic>,
            ),
          ),
        );
      } on FormatException {
        continue;
      }
    }
    requests
        .sort((left, right) => right.requestedAt.compareTo(left.requestedAt));
    if (limit <= 0 || requests.length <= limit) {
      return requests;
    }
    return requests.take(limit).toList(growable: false);
  }

  Future<ReplaySimulationLabRerunJob> executeLabRerunRequest({
    required String environmentId,
    required String requestId,
  }) async {
    final normalizedEnvironmentId = environmentId.trim();
    final normalizedRequestId = requestId.trim();
    final request = await _requireLabRerunRequest(
      environmentId: normalizedEnvironmentId,
      requestId: normalizedRequestId,
    );
    if (request.requestStatus != 'queued') {
      throw StateError(
        'Only queued world simulation lab rerun requests can be executed. `${request.requestId}` is `${request.requestStatus}`.',
      );
    }
    final snapshot = await getSnapshot(environmentId: normalizedEnvironmentId);
    final startedAt = _nowProvider().toUtc();
    final jobId =
        '${request.requestId}-job-${startedAt.toIso8601String().replaceAll(':', '-')}';
    final jobRoot = Directory(
      path.join(request.requestRoot, 'runtime_jobs', jobId),
    )..createSync(recursive: true);
    final baseJob = ReplaySimulationLabRerunJob(
      jobId: jobId,
      requestId: request.requestId,
      environmentId: request.environmentId,
      cityCode: request.cityCode,
      replayYear: request.replayYear,
      jobStatus: 'running',
      jobRoot: jobRoot.path,
      jobJsonPath:
          path.join(jobRoot.path, 'world_simulation_lab_rerun_job.json'),
      readmePath: path.join(jobRoot.path, 'WORLD_SIMULATION_LAB_RERUN_JOB.md'),
      startedAt: startedAt,
      variantId: request.variantId,
      variantLabel: request.variantLabel,
      cityPackStructuralRef: request.cityPackStructuralRef,
      syntheticHumanKernelEntries:
          snapshot.syntheticHumanKernelExplorer.entries,
      localityHierarchyNodes: snapshot.localityHierarchyHealth.nodes,
      higherAgentHandoffItems: snapshot.higherAgentHandoffView.items,
      realismProvenance: snapshot.realismProvenance,
    );
    await _persistLabRerunJob(snapshot: snapshot, job: baseJob);
    final runningRequest = request.copyWith(
      requestStatus: 'running',
      startedAt: startedAt,
      completedAt: null,
      latestJobId: baseJob.jobId,
      latestJobJsonPath: baseJob.jobJsonPath,
      latestJobStatus: baseJob.jobStatus,
      latestJobStartedAt: baseJob.startedAt,
      latestJobCompletedAt: null,
      latestJobSnapshotJsonPath: null,
    );
    await _persistLabRerunRequest(snapshot: snapshot, request: runningRequest);

    try {
      final bundleFiles = await _writeLearningBundleArtifacts(
        snapshot: snapshot,
        bundleRoot: jobRoot,
        operatorIntent:
            'Runtime-executed world simulation lab rerun job anchored to a queued rerun request with preserved lineage.',
        readmeFileName: 'SIMULATION_LAB_RERUN_BUNDLE_README.md',
      );
      final completedAt = _nowProvider().toUtc();
      final completedJob = baseJob.copyWith(
        jobStatus: 'completed',
        snapshotJsonPath: bundleFiles.snapshotJsonPath,
        learningBundleJsonPath: bundleFiles.learningBundleJsonPath,
        realityModelRequestJsonPath: bundleFiles.realityModelRequestJsonPath,
        completedAt: completedAt,
        scenarioCount: snapshot.scenarios.length,
        comparisonCount: snapshot.comparisons.length,
        receiptCount: snapshot.receipts.length,
        contradictionCount: snapshot.contradictions.length,
        overlayCount: snapshot.localityOverlays.length,
        requestPreviewCount: snapshot.learningReadiness.requestPreviews.length,
      );
      await _persistLabRerunJob(snapshot: snapshot, job: completedJob);
      await _persistLabRerunRequest(
        snapshot: snapshot,
        request: runningRequest.copyWith(
          requestStatus: 'completed',
          completedAt: completedAt,
          latestJobStatus: completedJob.jobStatus,
          latestJobCompletedAt: completedJob.completedAt,
          latestJobSnapshotJsonPath: completedJob.snapshotJsonPath,
        ),
      );
      return completedJob;
    } catch (error) {
      final failedAt = _nowProvider().toUtc();
      final failedJob = baseJob.copyWith(
        jobStatus: 'failed',
        completedAt: failedAt,
        failureSummary: error.toString(),
      );
      await _persistLabRerunJob(snapshot: snapshot, job: failedJob);
      await _persistLabRerunRequest(
        snapshot: snapshot,
        request: request.copyWith(
          requestStatus: 'queued',
          startedAt: null,
          completedAt: null,
          latestJobId: failedJob.jobId,
          latestJobJsonPath: failedJob.jobJsonPath,
          latestJobStatus: failedJob.jobStatus,
          latestJobStartedAt: failedJob.startedAt,
          latestJobCompletedAt: failedJob.completedAt,
          latestJobSnapshotJsonPath: failedJob.snapshotJsonPath,
        ),
      );
      rethrow;
    }
  }

  Future<List<ReplaySimulationLabRerunJob>> listLabRerunJobs({
    required String environmentId,
    String? requestId,
    int limit = 12,
  }) async {
    final requests = await listLabRerunRequests(
      environmentId: environmentId,
      limit: 0,
    );
    final requestRoots = requests
        .where((entry) => requestId == null || entry.requestId == requestId)
        .map((entry) => path.join(entry.requestRoot, 'runtime_jobs'))
        .toList(growable: false);
    if (requestRoots.isEmpty) {
      return const <ReplaySimulationLabRerunJob>[];
    }
    final jobs = <ReplaySimulationLabRerunJob>[];
    for (final rootPath in requestRoots) {
      final root = Directory(rootPath);
      if (!root.existsSync()) {
        continue;
      }
      for (final entry in root.listSync(recursive: true)) {
        if (entry is! File ||
            path.basename(entry.path) !=
                'world_simulation_lab_rerun_job.json') {
          continue;
        }
        try {
          final raw = entry.readAsStringSync().trim();
          if (raw.isEmpty) {
            continue;
          }
          jobs.add(
            ReplaySimulationLabRerunJob.fromJson(
              Map<String, dynamic>.from(
                jsonDecode(raw) as Map<String, dynamic>,
              ),
            ),
          );
        } on FormatException {
          continue;
        }
      }
    }
    jobs.sort((left, right) => right.startedAt.compareTo(left.startedAt));
    if (limit <= 0 || jobs.length <= limit) {
      return jobs;
    }
    return jobs.take(limit).toList(growable: false);
  }

  Future<ReplaySimulationLabRerunRequest> _updateLabRerunRequestStatus({
    required String environmentId,
    required String requestId,
    required String nextStatus,
  }) async {
    final normalizedEnvironmentId = environmentId.trim();
    final normalizedRequestId = requestId.trim();
    if (normalizedEnvironmentId.isEmpty || normalizedRequestId.isEmpty) {
      throw StateError('Environment id and request id are required.');
    }
    final requests = await listLabRerunRequests(
      environmentId: normalizedEnvironmentId,
      limit: 0,
    );
    final matching =
        requests.where((entry) => entry.requestId == normalizedRequestId);
    if (matching.isEmpty) {
      throw StateError(
        'Unknown world simulation lab rerun request `$normalizedRequestId` for environment `$normalizedEnvironmentId`.',
      );
    }
    final existing = matching.first;
    final normalizedNextStatus = _normalizeLabRerunRequestStatus(nextStatus);
    final now = _nowProvider().toUtc();
    final updated = switch (normalizedNextStatus) {
      'running' when existing.requestStatus == 'queued' => existing.copyWith(
          requestStatus: 'running',
          startedAt: existing.startedAt ?? now,
        ),
      'completed' when existing.requestStatus == 'running' => existing.copyWith(
          requestStatus: 'completed',
          startedAt: existing.startedAt ?? now,
          completedAt: now,
        ),
      _ => throw StateError(
          'Cannot move world simulation lab rerun request `${existing.requestId}` from `${existing.requestStatus}` to `$normalizedNextStatus`.',
        ),
    };
    await _writePrettyJson(
      File(updated.requestJsonPath),
      updated.toJson(),
    );
    final snapshot = await getSnapshot(environmentId: normalizedEnvironmentId);
    await File(updated.readmePath).writeAsString(
      _buildSimulationLabRerunRequestReadme(
        snapshot: snapshot,
        request: updated,
      ),
      flush: true,
    );
    return updated;
  }

  Future<ReplaySimulationLabRerunRequest> _requireLabRerunRequest({
    required String environmentId,
    required String requestId,
  }) async {
    final requests = await listLabRerunRequests(
      environmentId: environmentId,
      limit: 0,
    );
    final matching = requests.where((entry) => entry.requestId == requestId);
    if (matching.isEmpty) {
      throw StateError(
        'Unknown world simulation lab rerun request `$requestId` for environment `$environmentId`.',
      );
    }
    return matching.first;
  }

  Future<void> _persistLabRerunRequest({
    required ReplaySimulationAdminSnapshot snapshot,
    required ReplaySimulationLabRerunRequest request,
  }) async {
    await _writePrettyJson(File(request.requestJsonPath), request.toJson());
    await File(request.readmePath).writeAsString(
      _buildSimulationLabRerunRequestReadme(
        snapshot: snapshot,
        request: request,
      ),
      flush: true,
    );
  }

  Future<void> _persistLabRerunJob({
    required ReplaySimulationAdminSnapshot snapshot,
    required ReplaySimulationLabRerunJob job,
  }) async {
    await _writePrettyJson(File(job.jobJsonPath), job.toJson());
    await File(job.readmePath).writeAsString(
      _buildSimulationLabRerunJobReadme(
        snapshot: snapshot,
        job: job,
      ),
      flush: true,
    );
  }

  Future<ReplaySimulationAdminSnapshot> getSnapshot({
    String? environmentId,
  }) async {
    final adapter = await _resolveEnvironmentAdapter(environmentId);
    final snapshot = await adapter.buildSnapshot(generatedAt: _nowProvider());
    final servedBasisState = await getServedBasisState(
      environmentId: snapshot.environmentId,
    );
    if (servedBasisState == null) {
      return snapshot;
    }
    final familyRestageReviewItems = await listLabFamilyRestageReviewItems(
      environmentId: snapshot.environmentId,
      limit: 0,
    );
    final foundation = snapshot.foundation;
    return ReplaySimulationAdminSnapshot(
      generatedAt: snapshot.generatedAt,
      environmentId: snapshot.environmentId,
      cityCode: snapshot.cityCode,
      replayYear: snapshot.replayYear,
      scenarios: snapshot.scenarios,
      comparisons: snapshot.comparisons,
      receipts: snapshot.receipts,
      contradictions: snapshot.contradictions,
      localityOverlays: snapshot.localityOverlays,
      foundation: ReplaySimulationAdminFoundationSummary(
        simulationMode: foundation.simulationMode,
        intakeFlowRefs: foundation.intakeFlowRefs,
        sidecarRefs: foundation.sidecarRefs,
        trainingArtifactFamilies: foundation.trainingArtifactFamilies,
        kernelStates: foundation.kernelStates,
        notes: <String>[
          ...foundation.notes,
          if (servedBasisState.priorServedBasisRef != null)
            'Prior served basis lineage is preserved at ${servedBasisState.priorServedBasisRef}.',
        ],
        metadata: <String, dynamic>{
          ...foundation.metadata,
          'supportedPlaceRef': servedBasisState.supportedPlaceRef,
          'cityPackStructuralRef': servedBasisState.cityPackStructuralRef ??
              foundation.metadata['cityPackStructuralRef'],
          'cityPackRefreshMode': 'versioned_living_city_pack',
          'currentBasisStatus': servedBasisState.currentBasisStatus,
          'latestStateHydrationStatus':
              servedBasisState.latestStateHydrationStatus,
          'latestStatePromotionReadiness':
              servedBasisState.latestStatePromotionReadiness,
          'latestStatePromotionBlockedReasons':
              servedBasisState.latestStatePromotionBlockedReasons,
          'latestStateDecisionStatus':
              servedBasisState.latestStateDecisionStatus,
          'latestStatePromotionReceiptRef':
              servedBasisState.latestStatePromotionReceiptRef,
          'latestStateDecisionArtifactRef':
              servedBasisState.latestStateDecisionArtifactRef,
          'latestStateDecisionRationale':
              servedBasisState.latestStateDecisionRationale,
          'latestStateDecisionRecordedAt': servedBasisState
              .latestStateDecisionRecordedAt
              ?.toUtc()
              .toIso8601String(),
          'latestStateRevalidationStatus':
              servedBasisState.latestStateRevalidationStatus,
          'latestStateRevalidationReceiptRef':
              servedBasisState.latestStateRevalidationReceiptRef,
          'latestStateRevalidationArtifactRef':
              servedBasisState.latestStateRevalidationArtifactRef,
          'latestStateRevalidatedAt': servedBasisState.latestStateRevalidatedAt
              ?.toUtc()
              .toIso8601String(),
          'latestStateRecoveryDecisionStatus':
              servedBasisState.latestStateRecoveryDecisionStatus,
          'latestStateRecoveryDecisionArtifactRef':
              servedBasisState.latestStateRecoveryDecisionArtifactRef,
          'latestStateRecoveryDecisionRationale':
              servedBasisState.latestStateRecoveryDecisionRationale,
          'latestStateRecoveryDecisionRecordedAt': servedBasisState
              .latestStateRecoveryDecisionRecordedAt
              ?.toUtc()
              .toIso8601String(),
          'hydrationEvidenceFamilies': servedBasisState
              .latestStateEvidenceRefsByFamily.keys
              .toList(growable: false),
          'hydrationFreshnessPosture':
              servedBasisState.hydrationFreshnessPosture,
          'latestStateRefreshCadenceHours':
              servedBasisState.latestStateRefreshCadenceHours,
          'latestStateRefreshCadenceStatus':
              servedBasisState.latestStateRefreshCadenceStatus,
          'latestStateRefreshReferenceAt': servedBasisState
              .latestStateRefreshReferenceAt
              ?.toUtc()
              .toIso8601String(),
          'latestStateRefreshPolicySummaries':
              servedBasisState.latestStateRefreshPolicySummaries,
          'latestStateRefreshExecutionStatus':
              servedBasisState.latestStateRefreshExecutionStatus,
          'latestStateRefreshExecutionReceiptRef':
              servedBasisState.latestStateRefreshExecutionReceiptRef,
          'latestStateRefreshExecutionCheckedAt': servedBasisState
              .latestStateRefreshExecutionCheckedAt
              ?.toUtc()
              .toIso8601String(),
          'latestStateDeploymentReceiptRef':
              servedBasisState.latestStateDeploymentReceiptRef,
          'latestStateEvidenceRefs': servedBasisState.latestStateEvidenceRefs,
          'latestStateEvidenceSelectionSummaries':
              servedBasisState.latestStateEvidenceSelectionSummaries,
          'latestStateEvidenceAgingSummaries':
              servedBasisState.latestStateEvidenceAgingSummaries,
          'latestStateEvidenceAgingTrendSummaries':
              servedBasisState.latestStateEvidenceAgingTrendSummaries,
          'latestStateEvidencePolicyActionSummaries':
              servedBasisState.latestStateEvidencePolicyActionSummaries,
          'latestStateEvidenceRestageTargetSummaries':
              servedBasisState.latestStateEvidenceRestageTargetSummaries,
          'latestStateEvidenceRestageReviewQueueSummaries':
              familyRestageReviewItems
                  .map(
                    (entry) =>
                        '${_describeHydrationEvidenceFamily(entry.evidenceFamily)}: ${_describeLivingCityPackMetadata(entry.queueStatus)}. ${entry.restageTargetSummary}',
                  )
                  .where((entry) => entry.trim().isNotEmpty)
                  .toList(growable: false),
          'latestStateEvidenceRestageReviewQueueRefs': familyRestageReviewItems
              .map((entry) => entry.itemJsonPath)
              .where((entry) => entry.trim().isNotEmpty)
              .toList(growable: false),
          'latestStateEvidenceRestageReviewQueueCount':
              familyRestageReviewItems.length,
          'latestStateRefreshReceiptRef':
              servedBasisState.latestStateRefreshReceiptRef,
          'servedBasisRef': servedBasisState.servedBasisRef,
          'priorServedBasisRef': servedBasisState.priorServedBasisRef,
          'basisRefreshLineageRef': servedBasisState.basisRefreshLineageRef,
        },
      ),
      learningReadiness: snapshot.learningReadiness,
      syntheticHumanKernelExplorer: snapshot.syntheticHumanKernelExplorer,
      localityHierarchyHealth: snapshot.localityHierarchyHealth,
      higherAgentHandoffView: snapshot.higherAgentHandoffView,
      realismProvenance: snapshot.realismProvenance,
      weakSpots: snapshot.weakSpots,
    );
  }

  Stream<ReplaySimulationAdminSnapshot> watchSnapshot({
    Duration refreshInterval = const Duration(seconds: 20),
    String? environmentId,
  }) {
    late final StreamController<ReplaySimulationAdminSnapshot> controller;
    Timer? timer;

    Future<void> emit() async {
      controller.add(await getSnapshot(environmentId: environmentId));
    }

    controller = StreamController<ReplaySimulationAdminSnapshot>.broadcast(
      onListen: () async {
        await emit();
        timer = Timer.periodic(refreshInterval, (_) {
          unawaited(emit());
        });
      },
      onCancel: () {
        timer?.cancel();
      },
    );

    return controller.stream;
  }

  Future<ReplaySimulationLearningBundleExport> exportLearningBundle({
    String? environmentId,
  }) async {
    final snapshot = await getSnapshot(environmentId: environmentId);
    final documentsDirectory = await _documentsDirectoryProvider();
    final exportStamp =
        snapshot.generatedAt.toUtc().toIso8601String().replaceAll(':', '-');
    final bundleRoot = Directory(
      path.join(
        documentsDirectory.path,
        'AVRAI',
        'simulation_learning_bundles',
        snapshot.environmentId,
        exportStamp,
      ),
    )..createSync(recursive: true);
    final bundleFiles = await _writeLearningBundleArtifacts(
      snapshot: snapshot,
      bundleRoot: bundleRoot,
      operatorIntent:
          'Local admin simulation bundle for review, deeper training consideration, and bounded reality-model evidence packaging.',
      readmeFileName: 'README.md',
    );
    return ReplaySimulationLearningBundleExport(
      environmentId: snapshot.environmentId,
      bundleRoot: bundleRoot.path,
      snapshotJsonPath: bundleFiles.snapshotJsonPath,
      learningBundleJsonPath: bundleFiles.learningBundleJsonPath,
      realityModelRequestJsonPath: bundleFiles.realityModelRequestJsonPath,
      readmePath: bundleFiles.readmePath,
      exportedAt: DateTime.now().toUtc(),
      shareWithRealityModelAllowed:
          snapshot.learningReadiness.shareWithRealityModelAllowed,
    );
  }

  Future<ReplaySimulationLabOutcomeRecord> recordLabOutcome({
    String? environmentId,
    required ReplaySimulationLabDisposition disposition,
    String operatorRationale = '',
    List<String> operatorNotes = const <String>[],
    String? variantId,
    String? variantLabel,
  }) async {
    final snapshot = await getSnapshot(environmentId: environmentId);
    final runtimeState =
        await getLabRuntimeState(environmentId: snapshot.environmentId);
    final effectiveVariantId = variantId == null || variantId.trim().isEmpty
        ? runtimeState.activeVariantId
        : variantId.trim();
    final effectiveVariantLabel =
        variantLabel == null || variantLabel.trim().isEmpty
            ? runtimeState.activeVariantLabel
            : variantLabel.trim();
    final documentsDirectory = await _documentsDirectoryProvider();
    final recordedAt = _nowProvider().toUtc();
    final stamp = recordedAt.toIso8601String().replaceAll(':', '-');
    final labRoot = Directory(
      path.join(
        documentsDirectory.path,
        'AVRAI',
        'world_simulation_lab',
        snapshot.environmentId,
        stamp,
      ),
    )..createSync(recursive: true);
    final bundleFiles = await _writeLearningBundleArtifacts(
      snapshot: snapshot,
      bundleRoot: labRoot,
      operatorIntent:
          'World Simulation Lab run for pre-training iteration, comparison, and supervisor feedback learning.',
      readmeFileName: 'SIMULATION_LAB_BUNDLE_README.md',
    );
    final notes = operatorNotes
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
    final outcome = ReplaySimulationLabOutcomeRecord(
      environmentId: snapshot.environmentId,
      cityCode: snapshot.cityCode,
      replayYear: snapshot.replayYear,
      labRoot: labRoot.path,
      snapshotJsonPath: bundleFiles.snapshotJsonPath,
      learningBundleJsonPath: bundleFiles.learningBundleJsonPath,
      realityModelRequestJsonPath: bundleFiles.realityModelRequestJsonPath,
      outcomeJsonPath:
          path.join(labRoot.path, 'world_simulation_lab_outcome.json'),
      readmePath: path.join(labRoot.path, 'WORLD_SIMULATION_LAB_README.md'),
      recordedAt: recordedAt,
      disposition: disposition,
      operatorRationale: operatorRationale.trim(),
      operatorNotes: notes,
      trainingGrade: snapshot.learningReadiness.trainingGrade,
      suggestedTrainingUse: snapshot.learningReadiness.suggestedTrainingUse,
      shareWithRealityModelAllowed:
          snapshot.learningReadiness.shareWithRealityModelAllowed,
      scenarioCount: snapshot.scenarios.length,
      comparisonCount: snapshot.comparisons.length,
      receiptCount: snapshot.receipts.length,
      contradictionCount: snapshot.contradictions.length,
      overlayCount: snapshot.localityOverlays.length,
      requestPreviewCount: snapshot.learningReadiness.requestPreviews.length,
      simulationMode: snapshot.foundation.simulationMode,
      syntheticHumanKernelEntries:
          snapshot.syntheticHumanKernelExplorer.entries,
      localityHierarchyNodes: snapshot.localityHierarchyHealth.nodes,
      higherAgentHandoffItems: snapshot.higherAgentHandoffView.items,
      realismProvenance: snapshot.realismProvenance,
      intakeFlowRefs: snapshot.foundation.intakeFlowRefs,
      sidecarRefs: snapshot.foundation.sidecarRefs,
      cityPackStructuralRef:
          snapshot.foundation.metadata['cityPackStructuralRef']?.toString(),
      trainingArtifactFamilies: snapshot.foundation.trainingArtifactFamilies,
      variantId: effectiveVariantId,
      variantLabel: effectiveVariantLabel,
    );

    await File(outcome.outcomeJsonPath).writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(outcome.toJson())}\n',
      flush: true,
    );
    await File(outcome.readmePath).writeAsString(
      _buildSimulationLabOutcomeReadme(
        snapshot: snapshot,
        outcome: outcome,
      ),
      flush: true,
    );
    await _stageReplaySupervisorObservation(
      environmentId: snapshot.environmentId,
      cityCode: snapshot.cityCode,
      occurredAtUtc: recordedAt,
      observationKind: 'replay_simulation_lab_outcome',
      summary:
          'Replay simulation lab outcome `${disposition.toWireValue()}` was recorded for `${snapshot.environmentId}` with training grade `${snapshot.learningReadiness.trainingGrade}`.',
      upwardDomainHints: <String>[
        'simulation',
        'replay',
        if (snapshot.learningReadiness.shareWithRealityModelAllowed)
          'reality_model',
        if (snapshot.localityOverlays.isNotEmpty) 'locality',
      ],
      upwardReferencedEntities: <String>[
        'environment:${snapshot.environmentId}',
        if ((effectiveVariantId ?? '').isNotEmpty)
          'variant:$effectiveVariantId',
      ],
      upwardQuestions: snapshot.learningReadiness.shareWithRealityModelAllowed
          ? const <String>[
              'Should this accepted simulation posture refine bounded review heuristics for similar environments?',
            ]
          : const <String>[
              'Which readiness blocker should be reduced before this environment is promoted toward bounded review again?',
            ],
      upwardSignalTags: <String>[
        'origin:replay_simulation_admin_service',
        'phase:world_simulation_lab_outcome',
        'disposition:${disposition.toWireValue()}',
        'training_grade:${snapshot.learningReadiness.trainingGrade}',
      ],
      boundedMetadata: <String, dynamic>{
        'environmentId': snapshot.environmentId,
        'cityCode': snapshot.cityCode,
        'disposition': disposition.toWireValue(),
        'trainingGrade': snapshot.learningReadiness.trainingGrade,
        'suggestedTrainingUse': snapshot.learningReadiness.suggestedTrainingUse,
        'shareWithRealityModelAllowed':
            snapshot.learningReadiness.shareWithRealityModelAllowed,
        'outcomeJsonPath': outcome.outcomeJsonPath,
        'learningBundleJsonPath': outcome.learningBundleJsonPath,
        'requestPreviewCount':
            snapshot.learningReadiness.requestPreviews.length,
        if ((effectiveVariantId ?? '').isNotEmpty)
          'variantId': effectiveVariantId,
        if ((effectiveVariantLabel ?? '').isNotEmpty)
          'variantLabel': effectiveVariantLabel,
      },
    );
    return outcome;
  }

  Future<List<ReplaySimulationLabOutcomeRecord>> listLabOutcomes({
    String? environmentId,
    int limit = 12,
  }) async {
    final documentsDirectory = await _documentsDirectoryProvider();
    final rootPath = path.join(
      documentsDirectory.path,
      'AVRAI',
      'world_simulation_lab',
    );
    final targetRoot = environmentId == null
        ? Directory(rootPath)
        : Directory(path.join(rootPath, environmentId));
    if (!targetRoot.existsSync()) {
      return const <ReplaySimulationLabOutcomeRecord>[];
    }

    final outcomeFiles = targetRoot
        .listSync(recursive: true)
        .whereType<File>()
        .where(
          (file) =>
              path.basename(file.path) == 'world_simulation_lab_outcome.json',
        )
        .toList(growable: false);

    final records = <ReplaySimulationLabOutcomeRecord>[];
    for (final file in outcomeFiles) {
      try {
        final raw = file.readAsStringSync().trim();
        if (raw.isEmpty) {
          continue;
        }
        final json = Map<String, dynamic>.from(
          jsonDecode(raw) as Map<String, dynamic>,
        );
        records.add(ReplaySimulationLabOutcomeRecord.fromJson(json));
      } on FormatException {
        continue;
      }
    }

    records.sort((left, right) => right.recordedAt.compareTo(left.recordedAt));
    if (limit <= 0 || records.length <= limit) {
      return records;
    }
    return records.take(limit).toList(growable: false);
  }

  Future<ReplaySimulationRealityModelShareReport>
      shareLearningBundleWithRealityModel({
    String? environmentId,
  }) async {
    final snapshot = await getSnapshot(environmentId: environmentId);
    final readiness = snapshot.learningReadiness;
    if (!readiness.shareWithRealityModelAllowed) {
      throw StateError(
        'Simulation ${snapshot.environmentId} is not ready for reality-model sharing.',
      );
    }
    if (readiness.requestPreviews.isEmpty) {
      throw StateError(
        'Simulation ${snapshot.environmentId} has no bounded reality-model request previews to share.',
      );
    }

    final export =
        await exportLearningBundle(environmentId: snapshot.environmentId);
    final contract = await _realityModelPort.getActiveContract();
    final rendererKind = contract.rendererKinds.isEmpty
        ? RealityExplanationRendererKind.template
        : contract.rendererKinds.first;
    final sharedAt = _nowProvider().toUtc();
    final outcomes = <ReplaySimulationRealityModelShareOutcome>[];

    for (final preview in readiness.requestPreviews) {
      final request = preview.request.normalized();
      final evaluation = await _realityModelPort.evaluate(request);
      final disposition = _resolveShareDisposition(
        contract: contract,
        evaluation: evaluation,
      );
      final trace = await _realityModelPort.traceDecision(
        request: request,
        evaluation: evaluation,
        disposition: disposition,
        evidenceRefs: evaluation.supportingEvidenceRefs,
        localityCode: evaluation.localityCode,
        metadata: <String, dynamic>{
          'surface': 'admin_replay_simulation_learning_share',
          'environmentId': snapshot.environmentId,
          'trainingGrade': readiness.trainingGrade,
          'simulationMode': snapshot.foundation.simulationMode,
          'previewRationale': preview.rationale,
        },
      );
      final explanation = await _realityModelPort.buildExplanation(
        trace: trace,
        evaluation: evaluation,
        rendererKind: rendererKind,
      );
      outcomes.add(
        ReplaySimulationRealityModelShareOutcome(
          request: request,
          rationale: preview.rationale,
          evaluation: evaluation,
          trace: trace,
          explanation: explanation,
        ),
      );
    }

    final recommendationCount = outcomes
        .where(
          (entry) =>
              entry.trace.disposition == RealityDecisionDisposition.recommend,
        )
        .length;
    final reviewJsonPath =
        path.join(export.bundleRoot, 'reality_model_share_review.json');
    final reviewFile = File(reviewJsonPath);
    final encoder = const JsonEncoder.withIndent('  ');
    await reviewFile.writeAsString(
      encoder.convert(
        <String, dynamic>{
          'environmentId': snapshot.environmentId,
          'cityCode': snapshot.cityCode,
          'replayYear': snapshot.replayYear,
          'sharedAt': sharedAt.toIso8601String(),
          'contract': contract.toJson(),
          'bundleExport': export.toJson(),
          'foundation': snapshot.foundation.toJson(),
          'learningReadiness': readiness.toJson(),
          'requestCount': outcomes.length,
          'recommendationCount': recommendationCount,
          'outcomes': outcomes.map((entry) => entry.toJson()).toList(),
        },
      ),
      flush: true,
    );

    return ReplaySimulationRealityModelShareReport(
      environmentId: snapshot.environmentId,
      bundleRoot: export.bundleRoot,
      reviewJsonPath: reviewJsonPath,
      sharedAt: sharedAt,
      contractId: contract.contractId,
      contractVersion: contract.version,
      requestCount: outcomes.length,
      recommendationCount: recommendationCount,
      outcomes: outcomes,
    );
  }

  Future<ReplaySimulationTrainingCandidateExport> stageDeeperTrainingCandidate({
    String? environmentId,
  }) async {
    final snapshot = await getSnapshot(environmentId: environmentId);
    final readiness = snapshot.learningReadiness;
    if (!readiness.shareWithRealityModelAllowed) {
      throw StateError(
        'Simulation ${snapshot.environmentId} is not ready for deeper training staging.',
      );
    }

    final shareReport = await shareLearningBundleWithRealityModel(
        environmentId: snapshot.environmentId);
    final stagedAt = _nowProvider().toUtc();
    final manifest = ReplayTrainingExportManifest(
      environmentId: snapshot.environmentId,
      replayYear: snapshot.replayYear,
      status: 'simulation_candidate_ready_for_deeper_training_review',
      artifactRefs: <String>[
        path.join(shareReport.bundleRoot, 'simulation_snapshot.json'),
        path.join(shareReport.bundleRoot, 'simulation_learning_bundle.json'),
        path.join(
            shareReport.bundleRoot, 'reality_model_request_previews.json'),
        shareReport.reviewJsonPath,
      ],
      metrics: <String, dynamic>{
        'scenarioCount': snapshot.scenarios.length,
        'comparisonCount': snapshot.comparisons.length,
        'receiptCount': snapshot.receipts.length,
        'contradictionCount': snapshot.contradictions.length,
        'overlayCount': snapshot.localityOverlays.length,
        'activeKernelCount': snapshot.foundation.activeKernelCount,
        'requestCount': shareReport.requestCount,
        'recommendationCount': shareReport.recommendationCount,
      },
      trainingTables: const <String>[
        'simulation_learning_bundle',
        'reality_model_share_review',
      ],
      notes: <String>[
        'Simulation candidate staged locally for deeper training review after bounded reality-model evaluation.',
        'Suggested training use: ${readiness.suggestedTrainingUse}.',
        ...readiness.reasons,
      ],
      metadata: <String, dynamic>{
        'cityCode': snapshot.cityCode,
        'bundleRoot': shareReport.bundleRoot,
        'simulationMode': snapshot.foundation.simulationMode,
        'trainingGrade': readiness.trainingGrade,
        'shareReviewJsonPath': shareReport.reviewJsonPath,
        'contractId': shareReport.contractId,
        'contractVersion': shareReport.contractVersion,
        'localOnly': true,
        'source': 'admin_replay_simulation_candidate',
        'intakeFlowRefs': snapshot.foundation.intakeFlowRefs,
        'sidecarRefs': snapshot.foundation.sidecarRefs,
        'trainingArtifactFamilies':
            snapshot.foundation.trainingArtifactFamilies,
        'kernelStates': snapshot.foundation.kernelStates
            .map((entry) => entry.toJson())
            .toList(growable: false),
        ...snapshot.foundation.metadata,
      },
    );

    final manifestPath = path.join(
      shareReport.bundleRoot,
      'simulation_training_candidate_manifest.json',
    );
    final manifestFile = File(manifestPath);
    await manifestFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
      flush: true,
    );

    final readmePath = path.join(
      shareReport.bundleRoot,
      'SIMULATION_TRAINING_CANDIDATE_README.md',
    );
    final readmeFile = File(readmePath);
    await readmeFile.writeAsString(
      _buildTrainingCandidateReadme(
        snapshot: snapshot,
        shareReport: shareReport,
        manifest: manifest,
      ),
      flush: true,
    );

    return ReplaySimulationTrainingCandidateExport(
      environmentId: snapshot.environmentId,
      bundleRoot: shareReport.bundleRoot,
      trainingManifestJsonPath: manifestPath,
      readmePath: readmePath,
      stagedAt: stagedAt,
      shareReviewJsonPath: shareReport.reviewJsonPath,
      status: manifest.status,
    );
  }

  Future<ReplaySimulationTrainingIntakeQueueExport> queueDeeperTrainingIntake({
    String? environmentId,
    String ownerUserId = 'admin_operator',
  }) async {
    final snapshot = await getSnapshot(environmentId: environmentId);
    final readiness = snapshot.learningReadiness;
    if (!readiness.shareWithRealityModelAllowed) {
      throw StateError(
        'Simulation ${snapshot.environmentId} is not ready for deeper training intake.',
      );
    }

    final candidate = await stageDeeperTrainingCandidate(
      environmentId: snapshot.environmentId,
    );
    final queuedAt = _nowProvider().toUtc();
    final queueStatus = 'queued_for_deeper_training_intake_review';
    final stamp = queuedAt.toIso8601String().replaceAll(':', '-');
    final sourceId =
        'simulation_training_source_${snapshot.environmentId}_$stamp';
    final jobId = 'simulation_training_job_${snapshot.environmentId}_$stamp';
    final reviewItemId =
        'simulation_training_review_${snapshot.environmentId}_$stamp';

    ExternalSourceDescriptor? sourceDescriptor;
    ExternalSyncJob? job;
    OrganizerReviewItem? reviewItem;

    final intakeRepository = _intakeRepository;
    if (intakeRepository != null) {
      sourceDescriptor = ExternalSourceDescriptor(
        id: sourceId,
        ownerUserId: ownerUserId,
        sourceProvider: 'replay_simulation_training_candidate',
        sourceUrl: candidate.trainingManifestJsonPath,
        connectionMode: ExternalConnectionMode.manual,
        entityHint: IntakeEntityType.review,
        sourceLabel:
            '${snapshot.environmentId} simulation deeper-training candidate',
        cityCode: snapshot.cityCode,
        isOneWaySync: true,
        isClaimable: false,
        createdAt: queuedAt,
        updatedAt: queuedAt,
        lastSyncedAt: queuedAt,
        syncState: ExternalSyncState.needsReview,
        metadata: <String, dynamic>{
          'bundleRoot': candidate.bundleRoot,
          'trainingManifestJsonPath': candidate.trainingManifestJsonPath,
          'shareReviewJsonPath': candidate.shareReviewJsonPath,
          'trainingGrade': readiness.trainingGrade,
          'suggestedTrainingUse': readiness.suggestedTrainingUse,
          'simulationMode': snapshot.foundation.simulationMode,
          'cityPackStructuralRef':
              snapshot.foundation.metadata['cityPackStructuralRef'],
          'intakeFlowRefs': snapshot.foundation.intakeFlowRefs,
          'sidecarRefs': snapshot.foundation.sidecarRefs,
          'trainingArtifactFamilies':
              snapshot.foundation.trainingArtifactFamilies,
          'status': queueStatus,
          'localOnly': true,
        },
      );
      await intakeRepository.upsertSource(sourceDescriptor);

      job = ExternalSyncJob(
        id: jobId,
        sourceId: sourceId,
        startedAt: queuedAt,
        updatedAt: queuedAt,
        state: ExternalSyncState.needsReview,
        importedCount: 1,
        reviewCount: 1,
      );
      await intakeRepository.upsertJob(job);

      reviewItem = OrganizerReviewItem(
        id: reviewItemId,
        sourceId: sourceId,
        ownerUserId: ownerUserId,
        targetType: IntakeEntityType.review,
        title: 'Deeper training intake review for ${snapshot.environmentId}',
        summary:
            'Strong simulation candidate is queued for governed deeper-training intake review.',
        missingFields: const <String>[],
        createdAt: queuedAt,
        payload: <String, dynamic>{
          'environmentId': snapshot.environmentId,
          'cityCode': snapshot.cityCode,
          'replayYear': snapshot.replayYear,
          'trainingManifestJsonPath': candidate.trainingManifestJsonPath,
          'shareReviewJsonPath': candidate.shareReviewJsonPath,
          'bundleRoot': candidate.bundleRoot,
          'trainingGrade': readiness.trainingGrade,
          'suggestedTrainingUse': readiness.suggestedTrainingUse,
          'reasons': readiness.reasons,
          'requestPreviewCount': readiness.requestPreviews.length,
          'simulationMode': snapshot.foundation.simulationMode,
          'cityPackStructuralRef':
              snapshot.foundation.metadata['cityPackStructuralRef'],
          'intakeFlowRefs': snapshot.foundation.intakeFlowRefs,
          'sidecarRefs': snapshot.foundation.sidecarRefs,
          'trainingArtifactFamilies':
              snapshot.foundation.trainingArtifactFamilies,
          'kernelStates': snapshot.foundation.kernelStates
              .map((entry) => entry.toJson())
              .toList(growable: false),
          'status': queueStatus,
          'localOnly': true,
        },
      );
      await intakeRepository.upsertReviewItem(reviewItem);
    }

    final queueJsonPath = path.join(
      candidate.bundleRoot,
      'simulation_training_intake_queue.json',
    );
    final queueReadmePath = path.join(
      candidate.bundleRoot,
      'SIMULATION_TRAINING_INTAKE_QUEUE_README.md',
    );
    final queuePayload = <String, dynamic>{
      'environmentId': snapshot.environmentId,
      'cityCode': snapshot.cityCode,
      'replayYear': snapshot.replayYear,
      'queuedAt': queuedAt.toIso8601String(),
      'status': queueStatus,
      'ownerUserId': ownerUserId,
      'cityPackStructuralRef':
          snapshot.foundation.metadata['cityPackStructuralRef'],
      'candidate': candidate.toJson(),
      'learningReadiness': readiness.toJson(),
      'foundation': snapshot.foundation.toJson(),
      'sourceDescriptor': sourceDescriptor?.toJson(),
      'job': job?.toJson(),
      'reviewItem': reviewItem?.toJson(),
      'notes': <String>[
        'This local queue artifact advances a strong simulation candidate into governed deeper-training intake review.',
        'The simulation remains local-first and reviewable from admin surfaces before any broader training action is taken.',
      ],
    };
    await File(queueJsonPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(queuePayload),
      flush: true,
    );
    await File(queueReadmePath).writeAsString(
      _buildTrainingIntakeQueueReadme(
        snapshot: snapshot,
        candidate: candidate,
        queueJsonPath: queueJsonPath,
        ownerUserId: ownerUserId,
        sourceId: sourceDescriptor?.id,
        jobId: job?.id,
        reviewItemId: reviewItem?.id,
      ),
      flush: true,
    );

    return ReplaySimulationTrainingIntakeQueueExport(
      environmentId: snapshot.environmentId,
      bundleRoot: candidate.bundleRoot,
      queueJsonPath: queueJsonPath,
      readmePath: queueReadmePath,
      trainingManifestJsonPath: candidate.trainingManifestJsonPath,
      shareReviewJsonPath: candidate.shareReviewJsonPath,
      queuedAt: queuedAt,
      status: queueStatus,
      sourceId: sourceDescriptor?.id,
      jobId: job?.id,
      reviewItemId: reviewItem?.id,
    );
  }

  Future<ReplaySimulationAdminEnvironmentAdapter> _resolveEnvironmentAdapter(
    String? environmentId,
  ) async {
    var resolvedEnvironmentId = environmentId ?? _defaultEnvironmentId;
    if (resolvedEnvironmentId == null) {
      if (_environmentAdapters.isNotEmpty) {
        final sortedEnvironmentIds = _environmentAdapters.keys.toList()..sort();
        resolvedEnvironmentId = sortedEnvironmentIds.first;
      } else {
        final available = await listAvailableEnvironments();
        if (available.isNotEmpty) {
          resolvedEnvironmentId = available.first.environmentId;
        }
      }
    }
    if (resolvedEnvironmentId == null) {
      throw StateError('No simulation environments are registered.');
    }
    final adapter = _environmentAdapters[resolvedEnvironmentId];
    if (adapter != null) {
      return adapter;
    }
    final registrations = await listRegisteredLabEnvironments();
    for (final registration in registrations) {
      if (registration.environmentId == resolvedEnvironmentId) {
        return registration.toAdapter();
      }
    }
    throw StateError(
      'Unknown simulation environment: $resolvedEnvironmentId',
    );
  }

  static Map<String, ReplaySimulationAdminEnvironmentAdapter>
      _buildEnvironmentAdapterMap(
    Iterable<ReplaySimulationAdminEnvironmentAdapter> adapters,
  ) {
    final adapterMap = <String, ReplaySimulationAdminEnvironmentAdapter>{};
    for (final adapter in adapters) {
      final environmentId = adapter.descriptor.environmentId.trim();
      if (environmentId.isEmpty) {
        throw StateError('Simulation environment ids may not be empty.');
      }
      if (adapterMap.containsKey(environmentId)) {
        throw StateError(
          'Duplicate simulation environment id: $environmentId',
        );
      }
      adapterMap[environmentId] = adapter;
    }
    return adapterMap;
  }

  Future<Directory> _worldSimulationLabRootDirectory() async {
    final documentsDirectory = await _documentsDirectoryProvider();
    return Directory(
      path.join(documentsDirectory.path, 'AVRAI', 'world_simulation_lab'),
    )..createSync(recursive: true);
  }

  Future<Directory> _registeredEnvironmentParentDirectory() async {
    final root = await _worldSimulationLabRootDirectory();
    return Directory(path.join(root.path, 'registered_environments'))
      ..createSync(recursive: true);
  }

  Future<Directory> _registeredEnvironmentDirectory(
      String environmentId) async {
    final parent = await _registeredEnvironmentParentDirectory();
    return Directory(path.join(parent.path, environmentId));
  }

  String _worldSimulationLabRelativePath(String a, String b, [String? c]) {
    return c == null
        ? path.join('world_simulation_lab', a, b)
        : path.join('world_simulation_lab', a, b, c);
  }

  Future<void> _writePrettyJson(
    File file,
    Map<String, dynamic> value,
  ) async {
    await file.create(recursive: true);
    await file.writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(value)}\n',
      flush: true,
    );
  }

  Future<_ReplaySimulationBundleFiles> _writeLearningBundleArtifacts({
    required ReplaySimulationAdminSnapshot snapshot,
    required Directory bundleRoot,
    required String operatorIntent,
    required String readmeFileName,
  }) async {
    final encoder = const JsonEncoder.withIndent('  ');

    final snapshotFile =
        File(path.join(bundleRoot.path, 'simulation_snapshot.json'));
    await snapshotFile.writeAsString(
      encoder.convert(snapshot.toJson()),
      flush: true,
    );

    final learningBundle = <String, dynamic>{
      'environmentId': snapshot.environmentId,
      'cityCode': snapshot.cityCode,
      'replayYear': snapshot.replayYear,
      'generatedAt': snapshot.generatedAt.toUtc().toIso8601String(),
      'foundation': snapshot.foundation.toJson(),
      'learningReadiness': snapshot.learningReadiness.toJson(),
      'scenarioSummaries': snapshot.scenarios
          .map(
            (entry) => <String, dynamic>{
              'scenarioId': entry.scenarioId,
              'name': entry.name,
              'description': entry.description,
              'scope': entry.scope.name,
              'scenarioKind': entry.scenarioKind.name,
              'seedEntityRefs': entry.seedEntityRefs,
              'seedLocalityCodes': entry.seedLocalityCodes,
              'expectedQuestions': entry.expectedQuestions,
            },
          )
          .toList(growable: false),
      'receiptIds': snapshot.receipts.map((entry) => entry.receiptId).toList(),
      'contradictionIds':
          snapshot.contradictions.map((entry) => entry.snapshotId).toList(),
      'overlayLocalities':
          snapshot.localityOverlays.map((entry) => entry.localityCode).toList(),
      'operatorIntent': operatorIntent,
    };
    final learningBundleFile =
        File(path.join(bundleRoot.path, 'simulation_learning_bundle.json'));
    await learningBundleFile.writeAsString(
      encoder.convert(learningBundle),
      flush: true,
    );

    final requestPreviewFile =
        File(path.join(bundleRoot.path, 'reality_model_request_previews.json'));
    await requestPreviewFile.writeAsString(
      encoder.convert(
        snapshot.learningReadiness.requestPreviews
            .map((entry) => entry.toJson())
            .toList(growable: false),
      ),
      flush: true,
    );

    final readmeFile = File(path.join(bundleRoot.path, readmeFileName));
    await readmeFile.writeAsString(
      _buildLearningBundleReadme(snapshot, bundleRoot.path),
      flush: true,
    );

    return _ReplaySimulationBundleFiles(
      snapshotJsonPath: snapshotFile.path,
      learningBundleJsonPath: learningBundleFile.path,
      realityModelRequestJsonPath: requestPreviewFile.path,
      readmePath: readmeFile.path,
    );
  }

  List<String> _foundationHydrationBasisLines(
    ReplaySimulationAdminFoundationSummary foundation,
  ) {
    final metadata = foundation.metadata;
    final supportedPlaceRef = metadata['supportedPlaceRef']?.toString().trim();
    final refreshMode = metadata['cityPackRefreshMode']?.toString().trim();
    final currentBasisStatus =
        metadata['currentBasisStatus']?.toString().trim();
    final hydrationStatus =
        metadata['latestStateHydrationStatus']?.toString().trim();
    final promotionReadiness =
        metadata['latestStatePromotionReadiness']?.toString().trim();
    final decisionStatus =
        metadata['latestStateDecisionStatus']?.toString().trim();
    final revalidationStatus =
        metadata['latestStateRevalidationStatus']?.toString().trim();
    final recoveryDecisionStatus =
        metadata['latestStateRecoveryDecisionStatus']?.toString().trim();
    final freshnessPosture =
        metadata['hydrationFreshnessPosture']?.toString().trim();
    final refreshCadenceHours =
        (metadata['latestStateRefreshCadenceHours'] as num?)?.toInt();
    final refreshCadenceStatus =
        metadata['latestStateRefreshCadenceStatus']?.toString().trim();
    final refreshReferenceAt =
        metadata['latestStateRefreshReferenceAt']?.toString().trim();
    final refreshExecutionStatus =
        metadata['latestStateRefreshExecutionStatus']?.toString().trim();
    final refreshExecutionReceiptRef =
        metadata['latestStateRefreshExecutionReceiptRef']?.toString().trim();
    final refreshExecutionCheckedAt =
        metadata['latestStateRefreshExecutionCheckedAt']?.toString().trim();
    final refreshReceiptRef =
        metadata['latestStateRefreshReceiptRef']?.toString().trim();
    final revalidationReceiptRef =
        metadata['latestStateRevalidationReceiptRef']?.toString().trim();
    final servedBasisRef = metadata['servedBasisRef']?.toString().trim();
    final priorServedBasisRef =
        metadata['priorServedBasisRef']?.toString().trim();
    final basisRefreshLineageRef =
        metadata['basisRefreshLineageRef']?.toString().trim();
    final evidenceFamilies =
        (metadata['hydrationEvidenceFamilies'] as List<dynamic>? ?? const [])
            .map((entry) => _describeHydrationEvidenceFamily(entry.toString()))
            .where((entry) => entry.isNotEmpty)
            .toList(growable: false);
    final latestStateEvidenceRefs =
        (metadata['latestStateEvidenceRefs'] as List<dynamic>? ?? const [])
            .map((entry) => entry.toString().trim())
            .where((entry) => entry.isNotEmpty)
            .toList(growable: false);
    final latestStateEvidenceSelectionSummaries =
        (metadata['latestStateEvidenceSelectionSummaries'] as List<dynamic>? ??
                const [])
            .map((entry) => entry.toString().trim())
            .where((entry) => entry.isNotEmpty)
            .toList(growable: false);
    final latestStateEvidenceAgingSummaries =
        (metadata['latestStateEvidenceAgingSummaries'] as List<dynamic>? ??
                const [])
            .map((entry) => entry.toString().trim())
            .where((entry) => entry.isNotEmpty)
            .toList(growable: false);
    final latestStateEvidenceAgingTrendSummaries =
        (metadata['latestStateEvidenceAgingTrendSummaries'] as List<dynamic>? ??
                const [])
            .map((entry) => entry.toString().trim())
            .where((entry) => entry.isNotEmpty)
            .toList(growable: false);
    final latestStateEvidencePolicyActionSummaries =
        (metadata['latestStateEvidencePolicyActionSummaries']
                    as List<dynamic>? ??
                const [])
            .map((entry) => entry.toString().trim())
            .where((entry) => entry.isNotEmpty)
            .toList(growable: false);
    final latestStateEvidenceRestageTargetSummaries =
        (metadata['latestStateEvidenceRestageTargetSummaries']
                    as List<dynamic>? ??
                const [])
            .map((entry) => entry.toString().trim())
            .where((entry) => entry.isNotEmpty)
            .toList(growable: false);
    final latestStateEvidenceRestageReviewQueueSummaries =
        (metadata['latestStateEvidenceRestageReviewQueueSummaries']
                    as List<dynamic>? ??
                const [])
            .map((entry) => entry.toString().trim())
            .where((entry) => entry.isNotEmpty)
            .toList(growable: false);
    final refreshPolicySummaries =
        (metadata['latestStateRefreshPolicySummaries'] as List<dynamic>? ??
                const [])
            .map((entry) => entry.toString().trim())
            .where((entry) => entry.isNotEmpty)
            .toList(growable: false);
    final promotionBlockedReasons =
        (metadata['latestStatePromotionBlockedReasons'] as List<dynamic>? ??
                const [])
            .map((entry) => entry.toString().trim())
            .where((entry) => entry.isNotEmpty)
            .toList(growable: false);
    final decisionArtifactRef =
        metadata['latestStateDecisionArtifactRef']?.toString().trim();
    final revalidationArtifactRef =
        metadata['latestStateRevalidationArtifactRef']?.toString().trim();
    final recoveryDecisionArtifactRef =
        metadata['latestStateRecoveryDecisionArtifactRef']?.toString().trim();
    final decisionRationale =
        metadata['latestStateDecisionRationale']?.toString().trim();
    final recoveryDecisionRationale =
        metadata['latestStateRecoveryDecisionRationale']?.toString().trim();
    return <String>[
      if ((supportedPlaceRef ?? '').isNotEmpty)
        'Supported place: `$supportedPlaceRef`',
      if ((refreshMode ?? '').isNotEmpty)
        'Refresh mode: `${_describeLivingCityPackMetadata(refreshMode!)}`',
      if ((currentBasisStatus ?? '').isNotEmpty)
        'Current basis: `${_describeLivingCityPackMetadata(currentBasisStatus!)}`',
      if ((hydrationStatus ?? '').isNotEmpty)
        'Hydration status: `${_describeLivingCityPackMetadata(hydrationStatus!)}`',
      if ((promotionReadiness ?? '').isNotEmpty)
        'Promotion readiness: `${_describeLivingCityPackMetadata(promotionReadiness!)}`',
      if ((decisionStatus ?? '').isNotEmpty)
        'Decision status: `${_describeLivingCityPackMetadata(decisionStatus!)}`',
      if ((revalidationStatus ?? '').isNotEmpty)
        'Revalidation status: `${_describeLivingCityPackMetadata(revalidationStatus!)}`',
      if ((recoveryDecisionStatus ?? '').isNotEmpty)
        'Recovery decision: `${_describeLivingCityPackMetadata(recoveryDecisionStatus!)}`',
      if (evidenceFamilies.isNotEmpty)
        'Latest-state evidence families: ${evidenceFamilies.join(', ')}',
      if (latestStateEvidenceRefs.isNotEmpty)
        'Latest-state evidence refs: ${latestStateEvidenceRefs.join(', ')}',
      if (latestStateEvidenceSelectionSummaries.isNotEmpty)
        'Evidence selection: ${latestStateEvidenceSelectionSummaries.join(' | ')}',
      if (latestStateEvidenceAgingSummaries.isNotEmpty)
        'Evidence aging: ${latestStateEvidenceAgingSummaries.join(' | ')}',
      if (latestStateEvidenceAgingTrendSummaries.isNotEmpty)
        'Evidence aging trend: ${latestStateEvidenceAgingTrendSummaries.join(' | ')}',
      if (latestStateEvidencePolicyActionSummaries.isNotEmpty)
        'Evidence policy action: ${latestStateEvidencePolicyActionSummaries.join(' | ')}',
      if (latestStateEvidenceRestageTargetSummaries.isNotEmpty)
        'Evidence restage target: ${latestStateEvidenceRestageTargetSummaries.join(' | ')}',
      if (latestStateEvidenceRestageReviewQueueSummaries.isNotEmpty)
        'Family restage review queue: ${latestStateEvidenceRestageReviewQueueSummaries.join(' | ')}',
      if (refreshPolicySummaries.isNotEmpty)
        'Refresh policy: ${refreshPolicySummaries.join(' | ')}',
      if ((freshnessPosture ?? '').isNotEmpty)
        'Freshness posture: `${_describeLivingCityPackMetadata(freshnessPosture!)}`',
      if (refreshCadenceHours != null)
        'Refresh cadence: `${refreshCadenceHours}h`',
      if ((refreshCadenceStatus ?? '').isNotEmpty)
        'Refresh cadence status: `${_describeLivingCityPackMetadata(refreshCadenceStatus!)}`',
      if ((refreshReferenceAt ?? '').isNotEmpty)
        'Refresh reference: `$refreshReferenceAt`',
      if ((refreshExecutionStatus ?? '').isNotEmpty)
        'Refresh execution: `${_describeLivingCityPackMetadata(refreshExecutionStatus!)}`',
      if ((refreshExecutionCheckedAt ?? '').isNotEmpty)
        'Refresh execution checked at: `$refreshExecutionCheckedAt`',
      if ((refreshExecutionReceiptRef ?? '').isNotEmpty)
        'Refresh execution receipt artifact: `$refreshExecutionReceiptRef`',
      if ((refreshReceiptRef ?? '').isNotEmpty)
        'Refresh receipt artifact: `$refreshReceiptRef`',
      if ((revalidationReceiptRef ?? '').isNotEmpty)
        'Revalidation receipt artifact: `$revalidationReceiptRef`',
      if (promotionBlockedReasons.isNotEmpty)
        'Promotion blockers: ${promotionBlockedReasons.join(' | ')}',
      if ((decisionArtifactRef ?? '').isNotEmpty)
        'Decision artifact: `$decisionArtifactRef`',
      if ((revalidationArtifactRef ?? '').isNotEmpty)
        'Revalidation artifact: `$revalidationArtifactRef`',
      if ((recoveryDecisionArtifactRef ?? '').isNotEmpty)
        'Recovery decision artifact: `$recoveryDecisionArtifactRef`',
      if ((decisionRationale ?? '').isNotEmpty)
        'Decision rationale: $decisionRationale',
      if ((recoveryDecisionRationale ?? '').isNotEmpty)
        'Recovery rationale: $recoveryDecisionRationale',
      if ((servedBasisRef ?? '').isNotEmpty)
        'Served basis artifact: `$servedBasisRef`',
      if ((priorServedBasisRef ?? '').isNotEmpty)
        'Prior served basis: `$priorServedBasisRef`',
      if ((basisRefreshLineageRef ?? '').isNotEmpty)
        'Basis refresh lineage: `$basisRefreshLineageRef`',
    ];
  }

  String _buildFamilyRestageReviewItemReadme(
    ReplaySimulationLabFamilyRestageReviewItem item,
  ) {
    final buffer = StringBuffer()
      ..writeln('# Family Restage Review Item')
      ..writeln()
      ..writeln('- Environment: `${item.environmentId}`')
      ..writeln('- Supported place: `${item.supportedPlaceRef}`')
      ..writeln(
        '- Evidence family: `${_describeHydrationEvidenceFamily(item.evidenceFamily)}`',
      )
      ..writeln(
          '- Queue status: `${_describeLivingCityPackMetadata(item.queueStatus)}`')
      ..writeln('- Queued at: `${item.queuedAt.toUtc().toIso8601String()}`')
      ..writeln(
          '- Current basis: `${_describeLivingCityPackMetadata(item.currentBasisStatus)}`')
      ..writeln()
      ..writeln('## Why This Family Is Queued')
      ..writeln()
      ..writeln(item.policyActionSummary.isEmpty
          ? 'No policy-action summary was preserved.'
          : '- ${item.policyActionSummary}')
      ..writeln(item.restageTargetSummary.isEmpty
          ? '- No explicit restage-target summary was preserved.'
          : '- ${item.restageTargetSummary}')
      ..writeln()
      ..writeln('## Lineage')
      ..writeln()
      ..writeln('- Served basis artifact: `${item.servedBasisRef}`');
    if ((item.latestStateRefreshReceiptRef ?? '').isNotEmpty) {
      buffer.writeln(
        '- Latest-state refresh receipt: `${item.latestStateRefreshReceiptRef}`',
      );
    }
    if ((item.latestStateRevalidationReceiptRef ?? '').isNotEmpty) {
      buffer.writeln(
        '- Latest-state revalidation receipt: `${item.latestStateRevalidationReceiptRef}`',
      );
    }
    if ((item.basisRefreshLineageRef ?? '').isNotEmpty) {
      buffer
          .writeln('- Basis refresh lineage: `${item.basisRefreshLineageRef}`');
    }
    if ((item.cityPackStructuralRef ?? '').isNotEmpty) {
      buffer.writeln(
          '- City-pack structural ref: `${item.cityPackStructuralRef}`');
    }
    if ((item.queueDecisionArtifactRef ?? '').isNotEmpty) {
      buffer.writeln(
        '- Queue decision artifact: `${item.queueDecisionArtifactRef}`',
      );
    }
    if ((item.queueDecisionRecordedAt?.toUtc().toIso8601String() ?? '')
        .isNotEmpty) {
      buffer.writeln(
        '- Queue decision recorded at: `${item.queueDecisionRecordedAt!.toUtc().toIso8601String()}`',
      );
    }
    if ((item.queueDecisionRationale ?? '').isNotEmpty) {
      buffer.writeln(
          '- Queue decision rationale: ${item.queueDecisionRationale}');
    }
    if ((item.restageIntakeQueueJsonPath ?? '').isNotEmpty) {
      buffer.writeln(
        '- Restage intake queue artifact: `${item.restageIntakeQueueJsonPath}`',
      );
    }
    if ((item.restageIntakeReadmePath ?? '').isNotEmpty) {
      buffer.writeln(
        '- Restage intake README: `${item.restageIntakeReadmePath}`',
      );
    }
    if ((item.restageIntakeSourceId ?? '').isNotEmpty) {
      buffer.writeln('- Intake source id: `${item.restageIntakeSourceId}`');
    }
    if ((item.restageIntakeJobId ?? '').isNotEmpty) {
      buffer.writeln('- Intake job id: `${item.restageIntakeJobId}`');
    }
    if ((item.restageIntakeReviewItemId ?? '').isNotEmpty) {
      buffer.writeln(
        '- Intake review item id: `${item.restageIntakeReviewItemId}`',
      );
    }
    if ((item.restageIntakeResolutionStatus ?? '').isNotEmpty) {
      buffer.writeln(
        '- Intake resolution status: `${_describeLivingCityPackMetadata(item.restageIntakeResolutionStatus!)}`',
      );
    }
    if ((item.restageIntakeResolutionArtifactRef ?? '').isNotEmpty) {
      buffer.writeln(
        '- Intake resolution artifact: `${item.restageIntakeResolutionArtifactRef}`',
      );
    }
    if ((item.restageIntakeResolutionRecordedAt?.toUtc().toIso8601String() ??
            '')
        .isNotEmpty) {
      buffer.writeln(
        '- Intake resolution recorded at: `${item.restageIntakeResolutionRecordedAt!.toUtc().toIso8601String()}`',
      );
    }
    if ((item.restageIntakeResolutionRationale ?? '').isNotEmpty) {
      buffer.writeln(
        '- Intake resolution rationale: ${item.restageIntakeResolutionRationale}',
      );
    }
    if ((item.followUpQueueStatus ?? '').isNotEmpty) {
      buffer.writeln(
        '- Follow-up queue status: `${_describeLivingCityPackMetadata(item.followUpQueueStatus!)}`',
      );
    }
    if ((item.followUpQueueJsonPath ?? '').isNotEmpty) {
      buffer.writeln(
        '- Follow-up queue artifact: `${item.followUpQueueJsonPath}`',
      );
    }
    if ((item.followUpReadmePath ?? '').isNotEmpty) {
      buffer.writeln('- Follow-up README: `${item.followUpReadmePath}`');
    }
    if ((item.followUpSourceId ?? '').isNotEmpty) {
      buffer.writeln('- Follow-up source id: `${item.followUpSourceId}`');
    }
    if ((item.followUpJobId ?? '').isNotEmpty) {
      buffer.writeln('- Follow-up job id: `${item.followUpJobId}`');
    }
    if ((item.followUpReviewItemId ?? '').isNotEmpty) {
      buffer.writeln(
        '- Follow-up review item id: `${item.followUpReviewItemId}`',
      );
    }
    if ((item.followUpResolutionStatus ?? '').isNotEmpty) {
      buffer.writeln(
        '- Follow-up resolution status: `${_describeLivingCityPackMetadata(item.followUpResolutionStatus!)}`',
      );
    }
    if ((item.followUpResolutionArtifactRef ?? '').isNotEmpty) {
      buffer.writeln(
        '- Follow-up resolution artifact: `${item.followUpResolutionArtifactRef}`',
      );
    }
    if ((item.followUpResolutionRecordedAt?.toUtc().toIso8601String() ?? '')
        .isNotEmpty) {
      buffer.writeln(
        '- Follow-up resolution recorded at: `${item.followUpResolutionRecordedAt!.toUtc().toIso8601String()}`',
      );
    }
    if ((item.followUpResolutionRationale ?? '').isNotEmpty) {
      buffer.writeln(
        '- Follow-up resolution rationale: ${item.followUpResolutionRationale}',
      );
    }
    if ((item.restageResolutionQueueStatus ?? '').isNotEmpty) {
      buffer.writeln(
        '- Resolution queue status: `${_describeLivingCityPackMetadata(item.restageResolutionQueueStatus!)}`',
      );
    }
    if ((item.restageResolutionQueueJsonPath ?? '').isNotEmpty) {
      buffer.writeln(
        '- Resolution queue artifact: `${item.restageResolutionQueueJsonPath}`',
      );
    }
    if ((item.restageResolutionReadmePath ?? '').isNotEmpty) {
      buffer.writeln(
        '- Resolution README: `${item.restageResolutionReadmePath}`',
      );
    }
    if ((item.restageResolutionSourceId ?? '').isNotEmpty) {
      buffer.writeln(
        '- Resolution source id: `${item.restageResolutionSourceId}`',
      );
    }
    if ((item.restageResolutionJobId ?? '').isNotEmpty) {
      buffer.writeln('- Resolution job id: `${item.restageResolutionJobId}`');
    }
    if ((item.restageResolutionReviewItemId ?? '').isNotEmpty) {
      buffer.writeln(
        '- Resolution review item id: `${item.restageResolutionReviewItemId}`',
      );
    }
    if ((item.restageResolutionResolutionStatus ?? '').isNotEmpty) {
      buffer.writeln(
        '- Resolution outcome: `${_describeLivingCityPackMetadata(item.restageResolutionResolutionStatus!)}`',
      );
    }
    if ((item.restageResolutionResolutionArtifactRef ?? '').isNotEmpty) {
      buffer.writeln(
        '- Resolution outcome artifact: `${item.restageResolutionResolutionArtifactRef}`',
      );
    }
    if ((item.restageResolutionResolutionRecordedAt
                ?.toUtc()
                .toIso8601String() ??
            '')
        .isNotEmpty) {
      buffer.writeln(
        '- Resolution outcome recorded at: `${item.restageResolutionResolutionRecordedAt!.toUtc().toIso8601String()}`',
      );
    }
    if ((item.restageResolutionResolutionRationale ?? '').isNotEmpty) {
      buffer.writeln(
        '- Resolution outcome rationale: ${item.restageResolutionResolutionRationale}',
      );
    }
    if ((item.restageExecutionQueueStatus ?? '').isNotEmpty) {
      buffer.writeln(
        '- Execution queue: `${_describeLivingCityPackMetadata(item.restageExecutionQueueStatus!)}`',
      );
    }
    if ((item.restageExecutionQueueJsonPath ?? '').isNotEmpty) {
      buffer.writeln(
        '- Execution queue artifact: `${item.restageExecutionQueueJsonPath}`',
      );
    }
    if ((item.restageExecutionSourceId ?? '').isNotEmpty) {
      buffer
          .writeln('- Execution source id: `${item.restageExecutionSourceId}`');
    }
    if ((item.restageExecutionJobId ?? '').isNotEmpty) {
      buffer.writeln('- Execution job id: `${item.restageExecutionJobId}`');
    }
    if ((item.restageExecutionReviewItemId ?? '').isNotEmpty) {
      buffer.writeln(
        '- Execution review item id: `${item.restageExecutionReviewItemId}`',
      );
    }
    if ((item.restageExecutionResolutionStatus ?? '').isNotEmpty) {
      buffer.writeln(
        '- Execution outcome: `${_describeLivingCityPackMetadata(item.restageExecutionResolutionStatus!)}`',
      );
    }
    if ((item.restageExecutionResolutionArtifactRef ?? '').isNotEmpty) {
      buffer.writeln(
        '- Execution outcome artifact: `${item.restageExecutionResolutionArtifactRef}`',
      );
    }
    if ((item.restageExecutionResolutionRecordedAt?.toUtc().toIso8601String() ??
            '')
        .isNotEmpty) {
      buffer.writeln(
        '- Execution outcome recorded at: `${item.restageExecutionResolutionRecordedAt!.toUtc().toIso8601String()}`',
      );
    }
    if ((item.restageExecutionResolutionRationale ?? '').isNotEmpty) {
      buffer.writeln(
        '- Execution outcome rationale: ${item.restageExecutionResolutionRationale}',
      );
    }
    if ((item.restageApplicationQueueStatus ?? '').isNotEmpty) {
      buffer.writeln(
        '- Application queue: `${_describeLivingCityPackMetadata(item.restageApplicationQueueStatus!)}`',
      );
    }
    if ((item.restageApplicationQueueJsonPath ?? '').isNotEmpty) {
      buffer.writeln(
        '- Application queue artifact: `${item.restageApplicationQueueJsonPath}`',
      );
    }
    if ((item.restageApplicationSourceId ?? '').isNotEmpty) {
      buffer.writeln(
        '- Application source id: `${item.restageApplicationSourceId}`',
      );
    }
    if ((item.restageApplicationJobId ?? '').isNotEmpty) {
      buffer.writeln('- Application job id: `${item.restageApplicationJobId}`');
    }
    if ((item.restageApplicationReviewItemId ?? '').isNotEmpty) {
      buffer.writeln(
        '- Application review item id: `${item.restageApplicationReviewItemId}`',
      );
    }
    if ((item.restageApplicationResolutionStatus ?? '').isNotEmpty) {
      buffer.writeln(
        '- Application outcome: `${_describeLivingCityPackMetadata(item.restageApplicationResolutionStatus!)}`',
      );
    }
    if ((item.restageApplicationResolutionArtifactRef ?? '').isNotEmpty) {
      buffer.writeln(
        '- Application outcome artifact: `${item.restageApplicationResolutionArtifactRef}`',
      );
    }
    if ((item.restageApplicationResolutionRecordedAt
                ?.toUtc()
                .toIso8601String() ??
            '')
        .isNotEmpty) {
      buffer.writeln(
        '- Application outcome recorded at: `${item.restageApplicationResolutionRecordedAt!.toUtc().toIso8601String()}`',
      );
    }
    if ((item.restageApplicationResolutionRationale ?? '').isNotEmpty) {
      buffer.writeln(
        '- Application outcome rationale: ${item.restageApplicationResolutionRationale}',
      );
    }
    if ((item.restageApplyQueueStatus ?? '').isNotEmpty) {
      buffer.writeln(
        '- Apply queue: `${_describeLivingCityPackMetadata(item.restageApplyQueueStatus!)}`',
      );
    }
    if ((item.restageApplyQueueJsonPath ?? '').isNotEmpty) {
      buffer.writeln(
        '- Apply queue artifact: `${item.restageApplyQueueJsonPath}`',
      );
    }
    if ((item.restageApplySourceId ?? '').isNotEmpty) {
      buffer.writeln('- Apply source id: `${item.restageApplySourceId}`');
    }
    if ((item.restageApplyJobId ?? '').isNotEmpty) {
      buffer.writeln('- Apply job id: `${item.restageApplyJobId}`');
    }
    if ((item.restageApplyReviewItemId ?? '').isNotEmpty) {
      buffer.writeln(
          '- Apply review item id: `${item.restageApplyReviewItemId}`');
    }
    if ((item.restageApplyResolutionStatus ?? '').isNotEmpty) {
      buffer.writeln(
        '- Apply outcome: `${_describeLivingCityPackMetadata(item.restageApplyResolutionStatus!)}`',
      );
    }
    if ((item.restageApplyResolutionArtifactRef ?? '').isNotEmpty) {
      buffer.writeln(
        '- Apply outcome artifact: `${item.restageApplyResolutionArtifactRef}`',
      );
    }
    if ((item.restageApplyResolutionRecordedAt?.toUtc().toIso8601String() ?? '')
        .isNotEmpty) {
      buffer.writeln(
        '- Apply outcome recorded at: `${item.restageApplyResolutionRecordedAt!.toUtc().toIso8601String()}`',
      );
    }
    if ((item.restageApplyResolutionRationale ?? '').isNotEmpty) {
      buffer.writeln(
        '- Apply outcome rationale: ${item.restageApplyResolutionRationale}',
      );
    }
    if ((item.restageServedBasisUpdateQueueStatus ?? '').isNotEmpty) {
      buffer.writeln(
        '- Served-basis update queue: `${_describeLivingCityPackMetadata(item.restageServedBasisUpdateQueueStatus!)}`',
      );
    }
    if ((item.restageServedBasisUpdateQueueJsonPath ?? '').isNotEmpty) {
      buffer.writeln(
        '- Served-basis update queue artifact: `${item.restageServedBasisUpdateQueueJsonPath}`',
      );
    }
    if ((item.restageServedBasisUpdateSourceId ?? '').isNotEmpty) {
      buffer.writeln(
        '- Served-basis update source id: `${item.restageServedBasisUpdateSourceId}`',
      );
    }
    if ((item.restageServedBasisUpdateJobId ?? '').isNotEmpty) {
      buffer.writeln(
        '- Served-basis update job id: `${item.restageServedBasisUpdateJobId}`',
      );
    }
    if ((item.restageServedBasisUpdateReviewItemId ?? '').isNotEmpty) {
      buffer.writeln(
        '- Served-basis update review item id: `${item.restageServedBasisUpdateReviewItemId}`',
      );
    }
    if ((item.restageServedBasisUpdateResolutionStatus ?? '').isNotEmpty) {
      buffer.writeln(
        '- Served-basis update outcome: `${_describeLivingCityPackMetadata(item.restageServedBasisUpdateResolutionStatus!)}`',
      );
    }
    if ((item.restageServedBasisUpdateResolutionArtifactRef ?? '').isNotEmpty) {
      buffer.writeln(
        '- Served-basis update outcome artifact: `${item.restageServedBasisUpdateResolutionArtifactRef}`',
      );
    }
    if ((item.restageServedBasisUpdateResolutionRecordedAt
                ?.toUtc()
                .toIso8601String() ??
            '')
        .isNotEmpty) {
      buffer.writeln(
        '- Served-basis update outcome recorded at: `${item.restageServedBasisUpdateResolutionRecordedAt!.toUtc().toIso8601String()}`',
      );
    }
    if ((item.restageServedBasisUpdateResolutionRationale ?? '').isNotEmpty) {
      buffer.writeln(
        '- Served-basis update outcome rationale: ${item.restageServedBasisUpdateResolutionRationale}',
      );
    }
    return buffer.toString();
  }

  String _buildFamilyRestageIntakeQueueReadme({
    required ReplaySimulationLabFamilyRestageReviewItem item,
    required ReplaySimulationFamilyRestageIntakeQueueExport export,
  }) {
    final buffer = StringBuffer()
      ..writeln('# Family Restage Intake Review')
      ..writeln()
      ..writeln('- Environment: `${item.environmentId}`')
      ..writeln(
          '- Evidence family: `${_describeHydrationEvidenceFamily(item.evidenceFamily)}`')
      ..writeln('- Status: `${_describeLivingCityPackMetadata(export.status)}`')
      ..writeln('- Queued at: `${export.queuedAt.toUtc().toIso8601String()}`')
      ..writeln()
      ..writeln('## Why This Intake Exists')
      ..writeln()
      ..writeln('- ${item.policyActionSummary}')
      ..writeln('- ${item.restageTargetSummary}')
      ..writeln()
      ..writeln('## Lineage')
      ..writeln()
      ..writeln('- Served basis artifact: `${item.servedBasisRef}`');
    if ((item.latestStateRefreshReceiptRef ?? '').isNotEmpty) {
      buffer.writeln(
        '- Latest-state refresh receipt: `${item.latestStateRefreshReceiptRef}`',
      );
    }
    if ((item.latestStateRevalidationReceiptRef ?? '').isNotEmpty) {
      buffer.writeln(
        '- Latest-state revalidation receipt: `${item.latestStateRevalidationReceiptRef}`',
      );
    }
    if ((item.basisRefreshLineageRef ?? '').isNotEmpty) {
      buffer
          .writeln('- Basis refresh lineage: `${item.basisRefreshLineageRef}`');
    }
    if ((export.sourceId ?? '').isNotEmpty) {
      buffer.writeln('- Intake source id: `${export.sourceId}`');
    }
    if ((export.jobId ?? '').isNotEmpty) {
      buffer.writeln('- Intake job id: `${export.jobId}`');
    }
    if ((export.reviewItemId ?? '').isNotEmpty) {
      buffer.writeln('- Intake review item id: `${export.reviewItemId}`');
    }
    return buffer.toString();
  }

  String _buildFamilyRestageFollowUpQueueReadme({
    required ReplaySimulationLabFamilyRestageReviewItem item,
    required ReplaySimulationFamilyRestageFollowUpQueueExport export,
    required String intakeResolutionArtifactRef,
  }) {
    final buffer = StringBuffer()
      ..writeln('# Family Restage Follow-up Review')
      ..writeln()
      ..writeln('- Environment: `${item.environmentId}`')
      ..writeln(
          '- Evidence family: `${_describeHydrationEvidenceFamily(item.evidenceFamily)}`')
      ..writeln('- Status: `${_describeLivingCityPackMetadata(export.status)}`')
      ..writeln('- Queued at: `${export.queuedAt.toUtc().toIso8601String()}`')
      ..writeln()
      ..writeln('## Why This Follow-up Exists')
      ..writeln()
      ..writeln('- ${item.policyActionSummary}')
      ..writeln('- ${item.restageTargetSummary}')
      ..writeln(
        '- Intake resolution artifact: `$intakeResolutionArtifactRef`',
      )
      ..writeln()
      ..writeln('## Lineage')
      ..writeln()
      ..writeln('- Served basis artifact: `${item.servedBasisRef}`');
    if ((item.latestStateRefreshReceiptRef ?? '').isNotEmpty) {
      buffer.writeln(
        '- Latest-state refresh receipt: `${item.latestStateRefreshReceiptRef}`',
      );
    }
    if ((item.latestStateRevalidationReceiptRef ?? '').isNotEmpty) {
      buffer.writeln(
        '- Latest-state revalidation receipt: `${item.latestStateRevalidationReceiptRef}`',
      );
    }
    if ((item.basisRefreshLineageRef ?? '').isNotEmpty) {
      buffer
          .writeln('- Basis refresh lineage: `${item.basisRefreshLineageRef}`');
    }
    if ((export.sourceId ?? '').isNotEmpty) {
      buffer.writeln('- Follow-up source id: `${export.sourceId}`');
    }
    if ((export.jobId ?? '').isNotEmpty) {
      buffer.writeln('- Follow-up job id: `${export.jobId}`');
    }
    if ((export.reviewItemId ?? '').isNotEmpty) {
      buffer.writeln('- Follow-up review item id: `${export.reviewItemId}`');
    }
    return buffer.toString();
  }

  String _buildFamilyRestageResolutionQueueReadme({
    required ReplaySimulationLabFamilyRestageReviewItem item,
    required ReplaySimulationFamilyRestageResolutionQueueExport export,
    required String followUpResolutionArtifactRef,
  }) {
    final buffer = StringBuffer()
      ..writeln('# Family Restage Resolution Review')
      ..writeln()
      ..writeln('- Environment: `${item.environmentId}`')
      ..writeln(
          '- Evidence family: `${_describeHydrationEvidenceFamily(item.evidenceFamily)}`')
      ..writeln('- Status: `${_describeLivingCityPackMetadata(export.status)}`')
      ..writeln('- Queued at: `${export.queuedAt.toUtc().toIso8601String()}`')
      ..writeln()
      ..writeln('## Why This Resolution Review Exists')
      ..writeln()
      ..writeln('- ${item.policyActionSummary}')
      ..writeln('- ${item.restageTargetSummary}')
      ..writeln(
        '- Follow-up resolution artifact: `$followUpResolutionArtifactRef`',
      )
      ..writeln()
      ..writeln('## Lineage')
      ..writeln()
      ..writeln('- Served basis artifact: `${item.servedBasisRef}`');
    if ((item.latestStateRefreshReceiptRef ?? '').isNotEmpty) {
      buffer.writeln(
        '- Latest-state refresh receipt: `${item.latestStateRefreshReceiptRef}`',
      );
    }
    if ((item.latestStateRevalidationReceiptRef ?? '').isNotEmpty) {
      buffer.writeln(
        '- Latest-state revalidation receipt: `${item.latestStateRevalidationReceiptRef}`',
      );
    }
    if ((item.basisRefreshLineageRef ?? '').isNotEmpty) {
      buffer
          .writeln('- Basis refresh lineage: `${item.basisRefreshLineageRef}`');
    }
    if ((export.sourceId ?? '').isNotEmpty) {
      buffer.writeln('- Resolution source id: `${export.sourceId}`');
    }
    if ((export.jobId ?? '').isNotEmpty) {
      buffer.writeln('- Resolution job id: `${export.jobId}`');
    }
    if ((export.reviewItemId ?? '').isNotEmpty) {
      buffer.writeln('- Resolution review item id: `${export.reviewItemId}`');
    }
    return buffer.toString();
  }

  String _buildFamilyRestageExecutionQueueReadme({
    required ReplaySimulationLabFamilyRestageReviewItem item,
    required ReplaySimulationFamilyRestageExecutionQueueExport export,
    required String resolutionReviewOutcomeArtifactRef,
  }) {
    final buffer = StringBuffer()
      ..writeln('# Family Restage Execution Review')
      ..writeln()
      ..writeln('- Environment: `${item.environmentId}`')
      ..writeln(
          '- Evidence family: `${_describeHydrationEvidenceFamily(item.evidenceFamily)}`')
      ..writeln('- Status: `${_describeLivingCityPackMetadata(export.status)}`')
      ..writeln('- Queued at: `${export.queuedAt.toUtc().toIso8601String()}`')
      ..writeln()
      ..writeln('## Why This Execution Review Exists')
      ..writeln()
      ..writeln('- ${item.policyActionSummary}')
      ..writeln('- ${item.restageTargetSummary}')
      ..writeln(
        '- Resolution-review outcome artifact: `$resolutionReviewOutcomeArtifactRef`',
      )
      ..writeln()
      ..writeln('## Lineage')
      ..writeln()
      ..writeln('- Served basis artifact: `${item.servedBasisRef}`');
    if ((item.latestStateRefreshReceiptRef ?? '').isNotEmpty) {
      buffer.writeln(
        '- Latest-state refresh receipt: `${item.latestStateRefreshReceiptRef}`',
      );
    }
    if ((item.latestStateRevalidationReceiptRef ?? '').isNotEmpty) {
      buffer.writeln(
        '- Latest-state revalidation receipt: `${item.latestStateRevalidationReceiptRef}`',
      );
    }
    if ((item.basisRefreshLineageRef ?? '').isNotEmpty) {
      buffer
          .writeln('- Basis refresh lineage: `${item.basisRefreshLineageRef}`');
    }
    if ((export.sourceId ?? '').isNotEmpty) {
      buffer.writeln('- Execution source id: `${export.sourceId}`');
    }
    if ((export.jobId ?? '').isNotEmpty) {
      buffer.writeln('- Execution job id: `${export.jobId}`');
    }
    if ((export.reviewItemId ?? '').isNotEmpty) {
      buffer.writeln('- Execution review item id: `${export.reviewItemId}`');
    }
    return buffer.toString();
  }

  String _buildFamilyRestageApplicationQueueReadme({
    required ReplaySimulationLabFamilyRestageReviewItem item,
    required ReplaySimulationFamilyRestageApplicationQueueExport export,
    required String executionReviewOutcomeArtifactRef,
  }) {
    final buffer = StringBuffer()
      ..writeln('# Family Restage Application Review')
      ..writeln()
      ..writeln('- Environment: `${item.environmentId}`')
      ..writeln(
          '- Evidence family: `${_describeHydrationEvidenceFamily(item.evidenceFamily)}`')
      ..writeln('- Status: `${_describeLivingCityPackMetadata(export.status)}`')
      ..writeln('- Queued at: `${export.queuedAt.toUtc().toIso8601String()}`')
      ..writeln()
      ..writeln('## Why This Application Review Exists')
      ..writeln()
      ..writeln('- ${item.policyActionSummary}')
      ..writeln('- ${item.restageTargetSummary}')
      ..writeln(
        '- Execution-review outcome artifact: `$executionReviewOutcomeArtifactRef`',
      )
      ..writeln()
      ..writeln('## Lineage')
      ..writeln()
      ..writeln('- Served basis artifact: `${item.servedBasisRef}`');
    if ((item.latestStateRefreshReceiptRef ?? '').isNotEmpty) {
      buffer.writeln(
        '- Latest-state refresh receipt: `${item.latestStateRefreshReceiptRef}`',
      );
    }
    if ((item.latestStateRevalidationReceiptRef ?? '').isNotEmpty) {
      buffer.writeln(
        '- Latest-state revalidation receipt: `${item.latestStateRevalidationReceiptRef}`',
      );
    }
    if ((item.basisRefreshLineageRef ?? '').isNotEmpty) {
      buffer
          .writeln('- Basis refresh lineage: `${item.basisRefreshLineageRef}`');
    }
    if ((export.sourceId ?? '').isNotEmpty) {
      buffer.writeln('- Application source id: `${export.sourceId}`');
    }
    if ((export.jobId ?? '').isNotEmpty) {
      buffer.writeln('- Application job id: `${export.jobId}`');
    }
    if ((export.reviewItemId ?? '').isNotEmpty) {
      buffer.writeln('- Application review item id: `${export.reviewItemId}`');
    }
    return buffer.toString();
  }

  String _buildFamilyRestageApplyQueueReadme({
    required ReplaySimulationLabFamilyRestageReviewItem item,
    required ReplaySimulationFamilyRestageApplyQueueExport export,
    required String applicationReviewOutcomeArtifactRef,
  }) {
    final buffer = StringBuffer()
      ..writeln('# Family Restage Apply Review')
      ..writeln()
      ..writeln('- Environment: `${item.environmentId}`')
      ..writeln(
          '- Evidence family: `${_describeHydrationEvidenceFamily(item.evidenceFamily)}`')
      ..writeln('- Status: `${_describeLivingCityPackMetadata(export.status)}`')
      ..writeln('- Queued at: `${export.queuedAt.toUtc().toIso8601String()}`')
      ..writeln()
      ..writeln('## Why This Apply Review Exists')
      ..writeln()
      ..writeln('- ${item.policyActionSummary}')
      ..writeln('- ${item.restageTargetSummary}')
      ..writeln(
        '- Application-review outcome artifact: `$applicationReviewOutcomeArtifactRef`',
      )
      ..writeln()
      ..writeln('## Lineage')
      ..writeln()
      ..writeln('- Served basis artifact: `${item.servedBasisRef}`');
    if ((item.latestStateRefreshReceiptRef ?? '').isNotEmpty) {
      buffer.writeln(
        '- Latest-state refresh receipt: `${item.latestStateRefreshReceiptRef}`',
      );
    }
    if ((item.latestStateRevalidationReceiptRef ?? '').isNotEmpty) {
      buffer.writeln(
        '- Latest-state revalidation receipt: `${item.latestStateRevalidationReceiptRef}`',
      );
    }
    if ((item.basisRefreshLineageRef ?? '').isNotEmpty) {
      buffer
          .writeln('- Basis refresh lineage: `${item.basisRefreshLineageRef}`');
    }
    if ((export.sourceId ?? '').isNotEmpty) {
      buffer.writeln('- Apply source id: `${export.sourceId}`');
    }
    if ((export.jobId ?? '').isNotEmpty) {
      buffer.writeln('- Apply job id: `${export.jobId}`');
    }
    if ((export.reviewItemId ?? '').isNotEmpty) {
      buffer.writeln('- Apply review item id: `${export.reviewItemId}`');
    }
    return buffer.toString();
  }

  String _buildFamilyRestageServedBasisUpdateQueueReadme({
    required ReplaySimulationLabFamilyRestageReviewItem item,
    required ReplaySimulationFamilyRestageServedBasisUpdateQueueExport export,
    required String applyReviewOutcomeArtifactRef,
  }) {
    final buffer = StringBuffer()
      ..writeln('# Family Restage Served-Basis Update Review')
      ..writeln()
      ..writeln('- Environment: `${item.environmentId}`')
      ..writeln(
          '- Evidence family: `${_describeHydrationEvidenceFamily(item.evidenceFamily)}`')
      ..writeln('- Status: `${_describeLivingCityPackMetadata(export.status)}`')
      ..writeln('- Queued at: `${export.queuedAt.toUtc().toIso8601String()}`')
      ..writeln()
      ..writeln('## Why This Served-Basis Update Review Exists')
      ..writeln()
      ..writeln('- ${item.policyActionSummary}')
      ..writeln('- ${item.restageTargetSummary}')
      ..writeln(
        '- Apply-review outcome artifact: `$applyReviewOutcomeArtifactRef`',
      )
      ..writeln()
      ..writeln('## Lineage')
      ..writeln()
      ..writeln('- Served basis artifact: `${item.servedBasisRef}`');
    if ((item.latestStateRefreshReceiptRef ?? '').isNotEmpty) {
      buffer.writeln(
        '- Latest-state refresh receipt: `${item.latestStateRefreshReceiptRef}`',
      );
    }
    if ((item.latestStateRevalidationReceiptRef ?? '').isNotEmpty) {
      buffer.writeln(
        '- Latest-state revalidation receipt: `${item.latestStateRevalidationReceiptRef}`',
      );
    }
    if ((item.basisRefreshLineageRef ?? '').isNotEmpty) {
      buffer
          .writeln('- Basis refresh lineage: `${item.basisRefreshLineageRef}`');
    }
    if ((export.sourceId ?? '').isNotEmpty) {
      buffer.writeln(
        '- Served-basis update source id: `${export.sourceId}`',
      );
    }
    if ((export.jobId ?? '').isNotEmpty) {
      buffer.writeln('- Served-basis update job id: `${export.jobId}`');
    }
    if ((export.reviewItemId ?? '').isNotEmpty) {
      buffer.writeln(
        '- Served-basis update review item id: `${export.reviewItemId}`',
      );
    }
    return buffer.toString();
  }

  String _buildLearningBundleReadme(
    ReplaySimulationAdminSnapshot snapshot,
    String bundleRoot,
  ) {
    final foundation = snapshot.foundation;
    final readiness = snapshot.learningReadiness;
    final buffer = StringBuffer()
      ..writeln('# Simulation Learning Bundle')
      ..writeln()
      ..writeln('- Environment: `${snapshot.environmentId}`')
      ..writeln('- City: `${snapshot.cityCode.toUpperCase()}`')
      ..writeln('- Replay year: `${snapshot.replayYear}`')
      ..writeln(
          '- Generated at: `${snapshot.generatedAt.toUtc().toIso8601String()}`')
      ..writeln('- Bundle root: `$bundleRoot`')
      ..writeln('- Simulation mode: `${foundation.simulationMode}`')
      ..writeln('- Training grade: `${readiness.trainingGrade}`')
      ..writeln(
        '- Share with reality model: `${readiness.shareWithRealityModelAllowed ? 'allowed' : 'not_allowed'}`',
      )
      ..writeln('- Suggested training use: `${readiness.suggestedTrainingUse}`')
      ..writeln()
      ..writeln('## Basis')
      ..writeln()
      ..writeln(
        '- Intake flows: ${foundation.intakeFlowRefs.isEmpty ? 'none recorded' : foundation.intakeFlowRefs.join(', ')}',
      )
      ..writeln(
        '- Sidecars: ${foundation.sidecarRefs.isEmpty ? 'none recorded' : foundation.sidecarRefs.join(', ')}',
      )
      ..writeln(
        '- Training artifact families: ${foundation.trainingArtifactFamilies.join(', ')}',
      )
      ..writeln();
    for (final line in _foundationHydrationBasisLines(foundation)) {
      buffer.writeln('- $line');
    }
    buffer
      ..writeln()
      ..writeln('## Kernel States')
      ..writeln();
    for (final state in foundation.kernelStates) {
      buffer.writeln(
        '- `${state.kernelId}` `${state.status}`: ${state.reason}',
      );
    }
    buffer
      ..writeln()
      ..writeln('## Why This Bundle Exists')
      ..writeln();
    for (final reason in readiness.reasons) {
      buffer.writeln('- $reason');
    }
    buffer
      ..writeln()
      ..writeln('## Files')
      ..writeln()
      ..writeln('- `simulation_snapshot.json`: full admin simulation snapshot')
      ..writeln(
        '- `simulation_learning_bundle.json`: training/share summary grounded in current simulation outputs',
      )
      ..writeln(
        '- `reality_model_request_previews.json`: bounded request previews the operator can review before any reality-model sharing',
      );
    return buffer.toString();
  }

  String _buildSimulationLabOutcomeReadme({
    required ReplaySimulationAdminSnapshot snapshot,
    required ReplaySimulationLabOutcomeRecord outcome,
  }) {
    final foundation = snapshot.foundation;
    final readiness = snapshot.learningReadiness;
    final buffer = StringBuffer()
      ..writeln('# World Simulation Lab Outcome')
      ..writeln()
      ..writeln('- Environment: `${snapshot.environmentId}`')
      ..writeln('- City: `${snapshot.cityCode.toUpperCase()}`')
      ..writeln('- Replay year: `${snapshot.replayYear}`')
      ..writeln(
          '- Recorded at: `${outcome.recordedAt.toUtc().toIso8601String()}`')
      ..writeln('- Disposition: `${outcome.disposition.displayLabel}`')
      ..writeln(
        '- Variant: `${outcome.variantLabel ?? 'base_run'}`',
      )
      ..writeln('- Simulation mode: `${foundation.simulationMode}`')
      ..writeln('- Training grade: `${readiness.trainingGrade}`')
      ..writeln('- Suggested training use: `${readiness.suggestedTrainingUse}`')
      ..writeln(
        '- Share with reality model: `${readiness.shareWithRealityModelAllowed ? 'allowed' : 'not_allowed'}`',
      )
      ..writeln()
      ..writeln('## Why This Run Was Marked')
      ..writeln();

    if (outcome.operatorRationale.isEmpty) {
      buffer.writeln('- No operator rationale recorded.');
    } else {
      buffer.writeln('- ${outcome.operatorRationale}');
    }

    if (outcome.operatorNotes.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('## Operator Notes')
        ..writeln();
      for (final note in outcome.operatorNotes) {
        buffer.writeln('- $note');
      }
    }

    buffer
      ..writeln()
      ..writeln('## Simulation Basis')
      ..writeln()
      ..writeln(
          '- City-pack structural ref: `${outcome.cityPackStructuralRef ?? 'not_recorded'}`')
      ..writeln(
          '- Intake flows: ${foundation.intakeFlowRefs.isEmpty ? 'none recorded' : foundation.intakeFlowRefs.join(', ')}')
      ..writeln(
          '- Sidecars: ${foundation.sidecarRefs.isEmpty ? 'none recorded' : foundation.sidecarRefs.join(', ')}')
      ..writeln(
          '- Training artifact families: ${foundation.trainingArtifactFamilies.isEmpty ? 'none recorded' : foundation.trainingArtifactFamilies.join(', ')}')
      ..writeln(
        _foundationHydrationBasisLines(foundation)
            .map((line) => '- $line')
            .join('\n'),
      )
      ..writeln('- Scenario count: `${snapshot.scenarios.length}`')
      ..writeln('- Comparison count: `${snapshot.comparisons.length}`')
      ..writeln('- Receipt count: `${snapshot.receipts.length}`')
      ..writeln('- Contradiction count: `${snapshot.contradictions.length}`')
      ..writeln('- Overlay count: `${snapshot.localityOverlays.length}`')
      ..writeln(
          '- Request preview count: `${snapshot.learningReadiness.requestPreviews.length}`')
      ..writeln()
      ..writeln('## Supervisor Learning Rule')
      ..writeln()
      ..writeln(
        'The supervisor daemon should learn from this outcome regardless of disposition, but only accepted outcomes may become explicit reality-model learning candidates or downstream propagation inputs.',
      )
      ..writeln()
      ..writeln('## Files')
      ..writeln()
      ..writeln('- `simulation_snapshot.json`')
      ..writeln('- `simulation_learning_bundle.json`')
      ..writeln('- `reality_model_request_previews.json`')
      ..writeln('- `world_simulation_lab_outcome.json`')
      ..writeln('- `WORLD_SIMULATION_LAB_README.md`');

    return buffer.toString();
  }

  String _buildSimulationLabRerunRequestReadme({
    required ReplaySimulationAdminSnapshot snapshot,
    required ReplaySimulationLabRerunRequest request,
  }) {
    final buffer = StringBuffer()
      ..writeln('# World Simulation Lab Rerun Request')
      ..writeln()
      ..writeln('- Request: `${request.requestId}`')
      ..writeln('- Environment: `${snapshot.environmentId}`')
      ..writeln('- City: `${snapshot.cityCode.toUpperCase()}`')
      ..writeln('- Replay year: `${snapshot.replayYear}`')
      ..writeln('- Target: `${request.variantLabel ?? 'Base run'}`')
      ..writeln(
        '- Requested at: `${request.requestedAt.toUtc().toIso8601String()}`',
      )
      ..writeln('- Status: `${request.requestStatus}`');
    if (request.startedAt != null) {
      buffer.writeln(
        '- Started at: `${request.startedAt!.toUtc().toIso8601String()}`',
      );
    }
    if (request.completedAt != null) {
      buffer.writeln(
        '- Completed at: `${request.completedAt!.toUtc().toIso8601String()}`',
      );
    }
    if (request.cityPackStructuralRef != null &&
        request.cityPackStructuralRef!.trim().isNotEmpty) {
      buffer.writeln(
        '- City-pack structural ref: `${request.cityPackStructuralRef}`',
      );
    }
    if (request.latestJobId != null && request.latestJobStatus != null) {
      buffer.writeln(
        '- Latest runtime job: `${request.latestJobId}` `${request.latestJobStatus}`',
      );
      if (request.latestJobStartedAt != null) {
        buffer.writeln(
          '- Latest runtime job started at: `${request.latestJobStartedAt!.toUtc().toIso8601String()}`',
        );
      }
      if (request.latestJobCompletedAt != null) {
        buffer.writeln(
          '- Latest runtime job completed at: `${request.latestJobCompletedAt!.toUtc().toIso8601String()}`',
        );
      }
      if (request.latestJobJsonPath != null &&
          request.latestJobJsonPath!.trim().isNotEmpty) {
        buffer.writeln(
          '- Latest runtime job artifact: `${request.latestJobJsonPath}`',
        );
      }
    }
    buffer
      ..writeln()
      ..writeln('## Lineage')
      ..writeln();
    if (request.lineageOutcomeJsonPath == null) {
      buffer
          .writeln('- No previous labeled outcome exists yet for this target.');
    } else {
      buffer
        ..writeln(
          '- Previous outcome disposition: `${request.lineageDisposition ?? 'unknown'}`',
        )
        ..writeln(
          '- Previous outcome recorded at: `${request.lineageRecordedAt?.toUtc().toIso8601String() ?? 'unknown'}`',
        )
        ..writeln(
          '- Previous outcome artifact: `${request.lineageOutcomeJsonPath}`',
        );
    }
    if ((request.targetActionSelected?.trim() ?? '').isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('## Target Action Routing')
        ..writeln()
        ..writeln(
          '- Selected action: `${request.targetActionSelected}`',
        )
        ..writeln(
          '- Suggested action: `${request.targetActionSuggested ?? 'unknown'}`',
        )
        ..writeln(
          '- Accepted suggestion: `${request.targetActionAcceptedSuggestion == true}`',
        )
        ..writeln(
          '- Decision updated at: `${request.targetActionUpdatedAt?.toUtc().toIso8601String() ?? 'unknown'}`',
        );
      if ((request.targetActionSuggestedReason?.trim() ?? '').isNotEmpty) {
        buffer.writeln(
          '- Decision basis: `${request.targetActionSuggestedReason}`',
        );
      }
    }
    if (request.requestNotes.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('## Operator Notes')
        ..writeln();
      for (final note in request.requestNotes) {
        buffer.writeln('- $note');
      }
    }
    if (request.sidecarRefs.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('## Sidecars')
        ..writeln();
      for (final sidecar in request.sidecarRefs) {
        buffer.writeln('- `$sidecar`');
      }
    }
    buffer
      ..writeln()
      ..writeln('## Boundaries')
      ..writeln()
      ..writeln(
        'This request only queues the next simulation rerun target and preserves lineage. It does not self-promote training or bypass governed reality-model review.',
      );
    return buffer.toString();
  }

  String _buildSimulationLabRerunJobReadme({
    required ReplaySimulationAdminSnapshot snapshot,
    required ReplaySimulationLabRerunJob job,
  }) {
    final buffer = StringBuffer()
      ..writeln('# World Simulation Lab Rerun Job')
      ..writeln()
      ..writeln('- Job: `${job.jobId}`')
      ..writeln('- Request: `${job.requestId}`')
      ..writeln('- Environment: `${snapshot.environmentId}`')
      ..writeln('- City: `${snapshot.cityCode.toUpperCase()}`')
      ..writeln('- Replay year: `${snapshot.replayYear}`')
      ..writeln('- Target: `${job.variantLabel ?? 'Base run'}`')
      ..writeln('- Status: `${job.jobStatus}`')
      ..writeln('- Started at: `${job.startedAt.toUtc().toIso8601String()}`');
    if (job.completedAt != null) {
      buffer.writeln(
        '- Completed at: `${job.completedAt!.toUtc().toIso8601String()}`',
      );
    }
    if (job.cityPackStructuralRef != null &&
        job.cityPackStructuralRef!.trim().isNotEmpty) {
      buffer.writeln(
        '- City-pack structural ref: `${job.cityPackStructuralRef}`',
      );
    }
    if (job.failureSummary != null && job.failureSummary!.trim().isNotEmpty) {
      buffer.writeln('- Failure summary: `${job.failureSummary}`');
    }
    buffer
      ..writeln()
      ..writeln('## Runtime Job Output')
      ..writeln()
      ..writeln('- Scenario count: `${job.scenarioCount}`')
      ..writeln('- Comparison count: `${job.comparisonCount}`')
      ..writeln('- Receipt count: `${job.receiptCount}`')
      ..writeln('- Contradiction count: `${job.contradictionCount}`')
      ..writeln('- Overlay count: `${job.overlayCount}`')
      ..writeln('- Request preview count: `${job.requestPreviewCount}`');
    if (job.snapshotJsonPath != null) {
      buffer.writeln('- Snapshot artifact: `${job.snapshotJsonPath}`');
    }
    if (job.learningBundleJsonPath != null) {
      buffer.writeln(
          '- Learning bundle artifact: `${job.learningBundleJsonPath}`');
    }
    if (job.realityModelRequestJsonPath != null) {
      buffer.writeln(
        '- Reality-model request preview artifact: `${job.realityModelRequestJsonPath}`',
      );
    }
    buffer
      ..writeln()
      ..writeln('## Boundary')
      ..writeln()
      ..writeln(
        'This runtime job executes a concrete world-simulation rerun bundle for review and comparison only. It does not self-promote training or bypass governed reality-model review.',
      );
    return buffer.toString();
  }

  static String _normalizeLabRerunRequestStatus(String raw) {
    switch (raw.trim()) {
      case 'queued_for_operator_rerun':
      case 'queued':
        return 'queued';
      case 'running_operator_rerun':
      case 'running':
        return 'running';
      case 'completed_operator_rerun':
      case 'completed':
        return 'completed';
      default:
        return raw.trim().isEmpty ? 'queued' : raw.trim();
    }
  }

  static String _normalizeLabRerunJobStatus(String raw) {
    switch (raw.trim()) {
      case 'queued':
        return 'queued';
      case 'running':
        return 'running';
      case 'completed':
        return 'completed';
      case 'failed':
        return 'failed';
      default:
        return raw.trim().isEmpty ? 'queued' : raw.trim();
    }
  }

  static String _normalizeLabTargetAction(String raw) {
    switch (raw.trim()) {
      case 'keep_iterating':
        return 'keep_iterating';
      case 'watch_closely':
        return 'watch_closely';
      case 'candidate_for_bounded_review':
        return 'candidate_for_bounded_review';
      default:
        if (raw.trim().isEmpty) {
          return 'watch_closely';
        }
        throw StateError('Unknown lab target action `$raw`.');
    }
  }

  String _buildTrainingCandidateReadme({
    required ReplaySimulationAdminSnapshot snapshot,
    required ReplaySimulationRealityModelShareReport shareReport,
    required ReplayTrainingExportManifest manifest,
  }) {
    final buffer = StringBuffer()
      ..writeln('# Simulation Training Candidate')
      ..writeln()
      ..writeln('- Environment: `${snapshot.environmentId}`')
      ..writeln('- City: `${snapshot.cityCode.toUpperCase()}`')
      ..writeln('- Replay year: `${snapshot.replayYear}`')
      ..writeln('- Bundle root: `${shareReport.bundleRoot}`')
      ..writeln('- Status: `${manifest.status}`')
      ..writeln(
          '- Suggested training use: `${snapshot.learningReadiness.suggestedTrainingUse}`')
      ..writeln('- Reality-model review: `${shareReport.reviewJsonPath}`')
      ..writeln()
      ..writeln('## Why This Candidate Exists')
      ..writeln()
      ..writeln(
        'This local candidate packages a strong simulation, its basis, and a bounded reality-model review so an operator can decide whether it should enter a deeper training regimen.',
      )
      ..writeln()
      ..writeln('## Simulation Basis')
      ..writeln()
      ..writeln(
        '- Simulation mode: `${snapshot.foundation.simulationMode}`',
      )
      ..writeln(
        '- Intake flows: ${snapshot.foundation.intakeFlowRefs.isEmpty ? 'none recorded' : snapshot.foundation.intakeFlowRefs.join(', ')}',
      )
      ..writeln(
        '- Sidecars: ${snapshot.foundation.sidecarRefs.isEmpty ? 'none recorded' : snapshot.foundation.sidecarRefs.join(', ')}',
      )
      ..writeln(
        '- Active kernels: `${snapshot.foundation.activeKernelCount}/${snapshot.foundation.kernelStates.length}`',
      );
    for (final line in _foundationHydrationBasisLines(snapshot.foundation)) {
      buffer.writeln('- $line');
    }
    buffer
      ..writeln()
      ..writeln('## Reality-Model Review')
      ..writeln()
      ..writeln(
        '- Requests reviewed: `${shareReport.requestCount}`',
      )
      ..writeln(
        '- Recommendation count: `${shareReport.recommendationCount}`',
      )
      ..writeln(
        '- Contract: `${shareReport.contractId}` `${shareReport.contractVersion}`',
      )
      ..writeln()
      ..writeln('## Files')
      ..writeln()
      ..writeln('- `simulation_snapshot.json`')
      ..writeln('- `simulation_learning_bundle.json`')
      ..writeln('- `reality_model_request_previews.json`')
      ..writeln('- `reality_model_share_review.json`')
      ..writeln('- `simulation_training_candidate_manifest.json`');
    return buffer.toString();
  }

  String _buildTrainingIntakeQueueReadme({
    required ReplaySimulationAdminSnapshot snapshot,
    required ReplaySimulationTrainingCandidateExport candidate,
    required String queueJsonPath,
    required String ownerUserId,
    String? sourceId,
    String? jobId,
    String? reviewItemId,
  }) {
    final foundation = snapshot.foundation;
    final readiness = snapshot.learningReadiness;
    final buffer = StringBuffer()
      ..writeln('# Simulation Training Intake Queue')
      ..writeln()
      ..writeln(
        'This local-first queue artifact advances a strong simulation candidate into governed deeper-training intake review.',
      )
      ..writeln()
      ..writeln('- Environment: `${snapshot.environmentId}`')
      ..writeln('- City: `${snapshot.cityCode.toUpperCase()}`')
      ..writeln('- Replay year: `${snapshot.replayYear}`')
      ..writeln('- Simulation mode: `${foundation.simulationMode}`')
      ..writeln('- Training grade: `${readiness.trainingGrade}`')
      ..writeln('- Suggested training use: `${readiness.suggestedTrainingUse}`')
      ..writeln('- Candidate manifest: `${candidate.trainingManifestJsonPath}`')
      ..writeln('- Reality-model review: `${candidate.shareReviewJsonPath}`')
      ..writeln('- Queue artifact: `$queueJsonPath`')
      ..writeln('- Owner: `$ownerUserId`');
    if (sourceId != null) {
      buffer.writeln('- Intake source id: `$sourceId`');
    }
    if (jobId != null) {
      buffer.writeln('- Intake job id: `$jobId`');
    }
    if (reviewItemId != null) {
      buffer.writeln('- Intake review item id: `$reviewItemId`');
    }
    buffer
      ..writeln()
      ..writeln('## Basis')
      ..writeln()
      ..writeln(
        '- Intake flows: ${foundation.intakeFlowRefs.isEmpty ? 'none recorded' : foundation.intakeFlowRefs.join(', ')}',
      )
      ..writeln(
        '- Sidecars: ${foundation.sidecarRefs.isEmpty ? 'none recorded' : foundation.sidecarRefs.join(', ')}',
      )
      ..writeln(
        '- Training artifact families: ${foundation.trainingArtifactFamilies.isEmpty ? 'none recorded' : foundation.trainingArtifactFamilies.join(', ')}',
      );
    for (final line in _foundationHydrationBasisLines(foundation)) {
      buffer.writeln('- $line');
    }
    buffer
      ..writeln()
      ..writeln('## Why this was queued')
      ..writeln();
    for (final reason in readiness.reasons) {
      buffer.writeln('- $reason');
    }
    buffer
      ..writeln()
      ..writeln('## Kernel state coverage')
      ..writeln();
    for (final state in foundation.kernelStates) {
      buffer
          .writeln('- `${state.kernelId}` `${state.status}`: ${state.reason}');
    }
    buffer
      ..writeln()
      ..writeln('## Next step')
      ..writeln()
      ..writeln(
        'Use the queued candidate, bounded share review, and simulation basis together when deciding whether this simulation should become a deeper reality-model training regime.',
      );
    return buffer.toString();
  }

  RealityDecisionDisposition _resolveShareDisposition({
    required RealityModelContract contract,
    required RealityModelEvaluation evaluation,
  }) {
    if (evaluation.score >= 0.70 && evaluation.confidence >= 0.60) {
      return RealityDecisionDisposition.recommend;
    }
    if (contract.followUpQuestionsAllowed) {
      return RealityDecisionDisposition.askFollowUp;
    }
    return RealityDecisionDisposition.observe;
  }
}

String _normalizeToken(
  String value, {
  required String separator,
}) {
  final lower = value.trim().toLowerCase();
  if (lower.isEmpty) {
    return '';
  }
  final normalized = lower.replaceAll(RegExp(r'[^a-z0-9]+'), separator);
  final collapsed =
      normalized.replaceAll(RegExp('${RegExp.escape(separator)}+'), separator);
  return collapsed
      .replaceAll(RegExp('^${RegExp.escape(separator)}+'), '')
      .replaceAll(RegExp('${RegExp.escape(separator)}+\$'), '');
}

bool _sameSimulationLabTarget(String? leftVariantId, String? rightVariantId) {
  final left = leftVariantId?.trim();
  final right = rightVariantId?.trim();
  final leftIsBase = left == null || left.isEmpty;
  final rightIsBase = right == null || right.isEmpty;
  if (leftIsBase && rightIsBase) {
    return true;
  }
  return left == right;
}

String? _deriveReplaySimulationCityPackStructuralRef({
  required String cityCode,
  required int replayYear,
}) {
  final normalizedCityCode = _normalizeToken(cityCode, separator: '_');
  if (normalizedCityCode.isEmpty || replayYear <= 0) {
    return null;
  }
  return 'city_pack:${normalizedCityCode}_core_$replayYear';
}

class _ReplaySimulationBundleFiles {
  const _ReplaySimulationBundleFiles({
    required this.snapshotJsonPath,
    required this.learningBundleJsonPath,
    required this.realityModelRequestJsonPath,
    required this.readmePath,
  });

  final String snapshotJsonPath;
  final String learningBundleJsonPath;
  final String realityModelRequestJsonPath;
  final String readmePath;
}
