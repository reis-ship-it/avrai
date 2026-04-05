import 'package:avrai_core/models/discovery/discovery_models.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/services/messaging/bham_messaging_models.dart';

class AdminIdentityRedactionPolicy {
  const AdminIdentityRedactionPolicy({
    this.labelPrefix = 'AG',
    this.allowRuntimeIds = true,
    this.allowedIdentityFields = const <String>[
      'agent_id',
      'user_id',
      'ai_signature',
      'runtime_id',
      'tuple_ref',
      'locality_label',
      'operational_status',
    ],
  });

  final String labelPrefix;
  final bool allowRuntimeIds;
  final List<String> allowedIdentityFields;
}

class AdminRedactedView {
  const AdminRedactedView({
    required this.subjectId,
    required this.displayLabel,
    required this.initials,
    this.pseudonymous = true,
    this.metadata = const <String, dynamic>{},
  });

  final String subjectId;
  final String displayLabel;
  final String initials;
  final bool pseudonymous;
  final Map<String, dynamic> metadata;
}

class BreakGlassScope {
  const BreakGlassScope({
    required this.targetIds,
    required this.identityFields,
    required this.expiresAtUtc,
  });

  final List<String> targetIds;
  final List<String> identityFields;
  final DateTime expiresAtUtc;
}

class BreakGlassRequest {
  const BreakGlassRequest({
    required this.requestId,
    required this.actorId,
    required this.reasonCode,
    required this.justification,
    required this.createdAtUtc,
    required this.scope,
  });

  final String requestId;
  final String actorId;
  final String reasonCode;
  final String justification;
  final DateTime createdAtUtc;
  final BreakGlassScope scope;
}

class BreakGlassGrant {
  const BreakGlassGrant({
    required this.grantId,
    required this.request,
    required this.approverId,
    required this.startedAtUtc,
    required this.expiresAtUtc,
    this.active = true,
  });

  final String grantId;
  final BreakGlassRequest request;
  final String approverId;
  final DateTime startedAtUtc;
  final DateTime expiresAtUtc;
  final bool active;
}

enum BreakGlassAuditEventType {
  requested,
  approved,
  revealed,
  closed,
}

class BreakGlassAuditEvent {
  const BreakGlassAuditEvent({
    required this.auditId,
    required this.grantId,
    required this.eventType,
    required this.actorId,
    required this.recordedAtUtc,
    this.details = const <String, dynamic>{},
  });

  final String auditId;
  final String grantId;
  final BreakGlassAuditEventType eventType;
  final String actorId;
  final DateTime recordedAtUtc;
  final Map<String, dynamic> details;
}

enum QuarantineReason {
  maliciousPayload,
  impossibleContradiction,
  outOfLocalityUnsupported,
  duplicatedSpammy,
  safetyRisk,
  directHumanReport,
  lowEvidenceConviction,
}

enum QuarantineState {
  none,
  active,
  released,
  rolledBack,
  reset,
}

enum ResetDecision {
  none,
  rollback,
  resetAgent,
}

enum ModerationTargetType {
  user,
  agent,
  spot,
  list,
  club,
  community,
  event,
}

enum ModerationAction {
  flag,
  pause,
  quarantine,
  remove,
  restore,
  rollback,
  reset,
}

enum CreationModerationState {
  active,
  flagged,
  paused,
  quarantined,
  removed,
}

class ModerationTargetRef {
  const ModerationTargetRef({
    required this.type,
    required this.id,
    required this.title,
    this.localityLabel,
    this.ownerRef,
  });

  final ModerationTargetType type;
  final String id;
  final String title;
  final String? localityLabel;
  final String? ownerRef;
}

class GovernanceEvidence {
  const GovernanceEvidence({
    required this.evidenceId,
    required this.target,
    required this.reason,
    required this.summary,
    required this.recordedAtUtc,
    required this.source,
    this.confidence = 0.5,
    this.metadata = const <String, dynamic>{},
  });

  final String evidenceId;
  final ModerationTargetRef target;
  final QuarantineReason reason;
  final String summary;
  final DateTime recordedAtUtc;
  final String source;
  final double confidence;
  final Map<String, dynamic> metadata;
}

class GovernanceDecision {
  const GovernanceDecision({
    required this.decisionId,
    required this.target,
    required this.action,
    required this.quarantineState,
    required this.decidedAtUtc,
    required this.actorId,
    this.reason,
    this.evidenceIds = const <String>[],
    this.resetDecision = ResetDecision.none,
  });

  final String decisionId;
  final ModerationTargetRef target;
  final ModerationAction action;
  final QuarantineState quarantineState;
  final DateTime decidedAtUtc;
  final String actorId;
  final String? reason;
  final List<String> evidenceIds;
  final ResetDecision resetDecision;
}

class AdminModerationRecord {
  const AdminModerationRecord({
    required this.recordId,
    required this.target,
    required this.state,
    required this.lastAction,
    required this.updatedAtUtc,
    this.reason,
    this.evidence = const <GovernanceEvidence>[],
    this.pendingCreatorExplanation = false,
  });

  final String recordId;
  final ModerationTargetRef target;
  final CreationModerationState state;
  final ModerationAction lastAction;
  final DateTime updatedAtUtc;
  final String? reason;
  final List<GovernanceEvidence> evidence;
  final bool pendingCreatorExplanation;
}

class AdminCommunicationReadModel {
  const AdminCommunicationReadModel({
    required this.threadId,
    required this.threadKind,
    required this.displayTitle,
    required this.messageCount,
    required this.lastActivityAtUtc,
    this.lastMessagePreview,
    this.participants = const <AdminRedactedView>[],
    this.routeReceipt,
    this.quarantined = false,
  });

  final String threadId;
  final ChatThreadKind threadKind;
  final String displayTitle;
  final int messageCount;
  final DateTime lastActivityAtUtc;
  final String? lastMessagePreview;
  final List<AdminRedactedView> participants;
  final TransportRouteReceipt? routeReceipt;
  final bool quarantined;
}

class AdminDeliveryFailureReadModel {
  const AdminDeliveryFailureReadModel({
    required this.messageId,
    required this.threadId,
    required this.reason,
    required this.recordedAtUtc,
    this.routeReceipt,
  });

  final String messageId;
  final String threadId;
  final String reason;
  final DateTime recordedAtUtc;
  final TransportRouteReceipt? routeReceipt;
}

class RouteDeliverySummary {
  const RouteDeliverySummary({
    required this.mode,
    required this.attempts,
    required this.successes,
    this.averageLatencyMs,
  });

  final TransportMode mode;
  final int attempts;
  final int successes;
  final int? averageLatencyMs;

  double get successRate => attempts == 0 ? 0.0 : successes / attempts;
}

class DirectMatchOutcomeView {
  const DirectMatchOutcomeView({
    required this.invitationId,
    required this.participantA,
    required this.participantB,
    required this.compatibilityScore,
    required this.createdAtUtc,
    required this.chatOpened,
    this.declineMessage,
  });

  final String invitationId;
  final AdminRedactedView participantA;
  final AdminRedactedView participantB;
  final double compatibilityScore;
  final DateTime createdAtUtc;
  final bool chatOpened;
  final String? declineMessage;
}

class AdminFeedbackInboxItem {
  const AdminFeedbackInboxItem({
    required this.id,
    required this.kind,
    required this.content,
    required this.status,
    required this.createdAtUtc,
    required this.user,
  });

  final String id;
  final String kind;
  final String content;
  final String status;
  final DateTime createdAtUtc;
  final AdminRedactedView user;
}

class AdminExplorerItem {
  const AdminExplorerItem({
    required this.entity,
    required this.title,
    required this.subtitle,
    required this.createdAtUtc,
    this.moderationState = CreationModerationState.active,
  });

  final DiscoveryEntityReference entity;
  final String title;
  final String subtitle;
  final DateTime createdAtUtc;
  final CreationModerationState moderationState;
}

class AdminHealthSnapshot {
  const AdminHealthSnapshot({
    required this.adminAvailable,
    required this.sessionValid,
    required this.deviceApproved,
    required this.internalUseAgreementVerified,
    required this.openBreakGlassCount,
    required this.moderationQueueCount,
    required this.quarantinedCount,
    required this.failedDeliveryCount,
    required this.pendingFeedbackCount,
    required this.routeDeliveryHealth,
    required this.platformHealth,
    this.deviceStatusLabel,
  });

  final bool adminAvailable;
  final bool sessionValid;
  final bool deviceApproved;
  final bool internalUseAgreementVerified;
  final int openBreakGlassCount;
  final int moderationQueueCount;
  final int quarantinedCount;
  final int failedDeliveryCount;
  final int pendingFeedbackCount;
  final double routeDeliveryHealth;
  final Map<String, int> platformHealth;
  final String? deviceStatusLabel;
}

class LaunchGateAdminMetrics {
  const LaunchGateAdminMetrics({
    required this.availability,
    required this.moderationQueueHealth,
    required this.quarantineCount,
    required this.falsityResetCount,
    required this.breakGlassCount,
    required this.routeDeliveryHealth,
    required this.platformHealth,
  });

  final bool availability;
  final int moderationQueueHealth;
  final int quarantineCount;
  final int falsityResetCount;
  final int breakGlassCount;
  final double routeDeliveryHealth;
  final Map<String, int> platformHealth;
}

enum BhamLaunchGateStatus {
  pass,
  passWithPause,
  blocked,
  manualReviewRequired,
}

enum BhamFlowCheckStatus {
  pass,
  blocked,
  manualReviewRequired,
}

enum BhamManualEvidenceStatus {
  provided,
  missing,
  stale,
}

enum BhamFallbackArea {
  onDeviceSlm,
  ai2aiLocalExchange,
  backgroundSensing,
  offlineRecommendationQuality,
  adminObservability,
  publicCreation,
  localityLearning,
  directUserCompatibility,
}

enum BhamFallbackStatus {
  healthy,
  degraded,
  paused,
  blocked,
  manualReviewRequired,
}

enum BhamPauseReason {
  slmUnavailable,
  ai2aiSystemFailure,
  backgroundSensingUnreliable,
  offlineRecommendationWeak,
  adminObservabilityDegraded,
  publicCreationAbuse,
  localityLearningUnstable,
  directUserCompatibilityRisk,
  manualEvidenceMissing,
  launchValidationMissing,
}

class BhamManualEvidenceSlot {
  const BhamManualEvidenceSlot({
    required this.slotId,
    required this.label,
    required this.status,
    this.summary,
    this.updatedAtUtc,
    this.providedBy,
    this.value,
    this.unit,
    this.requiredForLaunch = false,
    this.requiredForExpansion = false,
    this.metadata = const <String, dynamic>{},
  });

  final String slotId;
  final String label;
  final BhamManualEvidenceStatus status;
  final String? summary;
  final DateTime? updatedAtUtc;
  final String? providedBy;
  final double? value;
  final String? unit;
  final bool requiredForLaunch;
  final bool requiredForExpansion;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'slot_id': slotId,
        'label': label,
        'status': status.name,
        if (summary != null) 'summary': summary,
        if (updatedAtUtc != null)
          'updated_at_utc': updatedAtUtc!.toUtc().toIso8601String(),
        if (providedBy != null) 'provided_by': providedBy,
        if (value != null) 'value': value,
        if (unit != null) 'unit': unit,
        'required_for_launch': requiredForLaunch,
        'required_for_expansion': requiredForExpansion,
        'metadata': metadata,
      };

  factory BhamManualEvidenceSlot.fromJson(Map<String, dynamic> json) {
    return BhamManualEvidenceSlot(
      slotId: json['slot_id'] as String? ?? 'unknown_slot',
      label: json['label'] as String? ?? 'Unknown evidence slot',
      status: BhamManualEvidenceStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => BhamManualEvidenceStatus.missing,
      ),
      summary: json['summary'] as String?,
      updatedAtUtc:
          DateTime.tryParse(json['updated_at_utc'] as String? ?? '')?.toUtc(),
      providedBy: json['provided_by'] as String?,
      value: (json['value'] as num?)?.toDouble(),
      unit: json['unit'] as String?,
      requiredForLaunch: json['required_for_launch'] as bool? ?? false,
      requiredForExpansion: json['required_for_expansion'] as bool? ?? false,
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}

class BhamFallbackState {
  const BhamFallbackState({
    required this.area,
    required this.status,
    required this.summary,
    required this.updatedAtUtc,
    this.reason,
    this.blocking = false,
    this.source = 'automatic',
    this.details = const <String, dynamic>{},
  });

  final BhamFallbackArea area;
  final BhamFallbackStatus status;
  final String summary;
  final DateTime updatedAtUtc;
  final BhamPauseReason? reason;
  final bool blocking;
  final String source;
  final Map<String, dynamic> details;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'area': area.name,
        'status': status.name,
        'summary': summary,
        'updated_at_utc': updatedAtUtc.toUtc().toIso8601String(),
        if (reason != null) 'reason': reason!.name,
        'blocking': blocking,
        'source': source,
        'details': details,
      };

  factory BhamFallbackState.fromJson(Map<String, dynamic> json) {
    return BhamFallbackState(
      area: BhamFallbackArea.values.firstWhere(
        (value) => value.name == json['area'],
        orElse: () => BhamFallbackArea.adminObservability,
      ),
      status: BhamFallbackStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => BhamFallbackStatus.manualReviewRequired,
      ),
      summary: json['summary'] as String? ?? 'Unknown fallback state',
      updatedAtUtc:
          DateTime.tryParse(json['updated_at_utc'] as String? ?? '')?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      reason: json['reason'] == null
          ? null
          : BhamPauseReason.values.firstWhere(
              (value) => value.name == json['reason'],
              orElse: () => BhamPauseReason.launchValidationMissing,
            ),
      blocking: json['blocking'] as bool? ?? false,
      source: json['source'] as String? ?? 'automatic',
      details: Map<String, dynamic>.from(
        json['details'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}

class BhamCriticalFlowCheckResult {
  const BhamCriticalFlowCheckResult({
    required this.flowId,
    required this.label,
    required this.status,
    required this.evidenceSummary,
    required this.blocking,
    this.lastValidatedAtUtc,
    this.source = 'manual',
  });

  final String flowId;
  final String label;
  final BhamFlowCheckStatus status;
  final String evidenceSummary;
  final bool blocking;
  final DateTime? lastValidatedAtUtc;
  final String source;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'flow_id': flowId,
        'label': label,
        'status': status.name,
        'evidence_summary': evidenceSummary,
        'blocking': blocking,
        if (lastValidatedAtUtc != null)
          'last_validated_at_utc':
              lastValidatedAtUtc!.toUtc().toIso8601String(),
        'source': source,
      };

  factory BhamCriticalFlowCheckResult.fromJson(Map<String, dynamic> json) {
    return BhamCriticalFlowCheckResult(
      flowId: json['flow_id'] as String? ?? 'unknown_flow',
      label: json['label'] as String? ?? 'Unknown flow',
      status: BhamFlowCheckStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => BhamFlowCheckStatus.manualReviewRequired,
      ),
      evidenceSummary: json['evidence_summary'] as String? ??
          'No evidence summary recorded.',
      blocking: json['blocking'] as bool? ?? true,
      lastValidatedAtUtc:
          DateTime.tryParse(json['last_validated_at_utc'] as String? ?? '')
              ?.toUtc(),
      source: json['source'] as String? ?? 'manual',
    );
  }
}

class BhamLaunchEvidenceSnapshot {
  const BhamLaunchEvidenceSnapshot({
    required this.generatedAtUtc,
    required this.adminAvailability,
    required this.routeDeliveryHealth,
    required this.moderationQueueHealth,
    required this.quarantineCount,
    required this.breakGlassCount,
    required this.platformHealth,
    this.offlineFirstCompletionRate,
    this.ai2aiSuccessTimePercent,
    this.recommendationActionRate,
    this.directMatchSafe,
    this.localityStability,
    this.quarantineReasons = const <String, int>{},
    this.manualEvidenceSlots = const <BhamManualEvidenceSlot>[],
  });

  final DateTime generatedAtUtc;
  final bool adminAvailability;
  final double? offlineFirstCompletionRate;
  final double? ai2aiSuccessTimePercent;
  final double routeDeliveryHealth;
  final double? recommendationActionRate;
  final bool? directMatchSafe;
  final double? localityStability;
  final int moderationQueueHealth;
  final int quarantineCount;
  final int breakGlassCount;
  final Map<String, int> platformHealth;
  final Map<String, int> quarantineReasons;
  final List<BhamManualEvidenceSlot> manualEvidenceSlots;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'generated_at_utc': generatedAtUtc.toUtc().toIso8601String(),
        'admin_availability': adminAvailability,
        if (offlineFirstCompletionRate != null)
          'offline_first_completion_rate': offlineFirstCompletionRate,
        if (ai2aiSuccessTimePercent != null)
          'ai2ai_success_time_percent': ai2aiSuccessTimePercent,
        'route_delivery_health': routeDeliveryHealth,
        if (recommendationActionRate != null)
          'recommendation_action_rate': recommendationActionRate,
        if (directMatchSafe != null) 'direct_match_safe': directMatchSafe,
        if (localityStability != null) 'locality_stability': localityStability,
        'moderation_queue_health': moderationQueueHealth,
        'quarantine_count': quarantineCount,
        'break_glass_count': breakGlassCount,
        'platform_health': platformHealth,
        'quarantine_reasons': quarantineReasons,
        'manual_evidence_slots':
            manualEvidenceSlots.map((slot) => slot.toJson()).toList(),
      };

  factory BhamLaunchEvidenceSnapshot.fromJson(Map<String, dynamic> json) {
    return BhamLaunchEvidenceSnapshot(
      generatedAtUtc:
          DateTime.tryParse(json['generated_at_utc'] as String? ?? '')
                  ?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      adminAvailability: json['admin_availability'] as bool? ?? false,
      offlineFirstCompletionRate:
          (json['offline_first_completion_rate'] as num?)?.toDouble(),
      ai2aiSuccessTimePercent:
          (json['ai2ai_success_time_percent'] as num?)?.toDouble(),
      routeDeliveryHealth:
          (json['route_delivery_health'] as num?)?.toDouble() ?? 0.0,
      recommendationActionRate:
          (json['recommendation_action_rate'] as num?)?.toDouble(),
      directMatchSafe: json['direct_match_safe'] as bool?,
      localityStability: (json['locality_stability'] as num?)?.toDouble(),
      moderationQueueHealth:
          (json['moderation_queue_health'] as num?)?.toInt() ?? 0,
      quarantineCount: (json['quarantine_count'] as num?)?.toInt() ?? 0,
      breakGlassCount: (json['break_glass_count'] as num?)?.toInt() ?? 0,
      platformHealth: Map<String, int>.from(
        json['platform_health'] as Map? ?? const <String, int>{},
      ),
      quarantineReasons: Map<String, int>.from(
        json['quarantine_reasons'] as Map? ?? const <String, int>{},
      ),
      manualEvidenceSlots:
          (json['manual_evidence_slots'] as List<dynamic>? ?? const [])
              .map(
                (slot) => BhamManualEvidenceSlot.fromJson(
                  Map<String, dynamic>.from(slot as Map),
                ),
              )
              .toList(),
    );
  }
}

class BhamExpansionGateResult {
  const BhamExpansionGateResult({
    required this.gateId,
    required this.description,
    required this.status,
    required this.summary,
  });

  final String gateId;
  final String description;
  final BhamLaunchGateStatus status;
  final String summary;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'gate_id': gateId,
        'description': description,
        'status': status.name,
        'summary': summary,
      };

  factory BhamExpansionGateResult.fromJson(Map<String, dynamic> json) {
    return BhamExpansionGateResult(
      gateId: json['gate_id'] as String? ?? 'unknown_gate',
      description: json['description'] as String? ?? 'Unknown gate',
      status: BhamLaunchGateStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => BhamLaunchGateStatus.manualReviewRequired,
      ),
      summary: json['summary'] as String? ?? 'No summary recorded.',
    );
  }
}

class BhamLaunchGateReport {
  const BhamLaunchGateReport({
    required this.generatedAtUtc,
    required this.status,
    required this.evidenceSnapshot,
    required this.fallbackStates,
    required this.criticalFlowChecks,
    required this.expansionGates,
    this.unresolvedBlockers = const <String>[],
    this.signoffInputs = const <BhamManualEvidenceSlot>[],
  });

  final DateTime generatedAtUtc;
  final BhamLaunchGateStatus status;
  final BhamLaunchEvidenceSnapshot evidenceSnapshot;
  final List<BhamFallbackState> fallbackStates;
  final List<BhamCriticalFlowCheckResult> criticalFlowChecks;
  final List<BhamExpansionGateResult> expansionGates;
  final List<String> unresolvedBlockers;
  final List<BhamManualEvidenceSlot> signoffInputs;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'generated_at_utc': generatedAtUtc.toUtc().toIso8601String(),
        'status': status.name,
        'evidence_snapshot': evidenceSnapshot.toJson(),
        'fallback_states': fallbackStates.map((item) => item.toJson()).toList(),
        'critical_flow_checks':
            criticalFlowChecks.map((item) => item.toJson()).toList(),
        'expansion_gates': expansionGates.map((item) => item.toJson()).toList(),
        'unresolved_blockers': unresolvedBlockers,
        'signoff_inputs': signoffInputs.map((item) => item.toJson()).toList(),
      };

  factory BhamLaunchGateReport.fromJson(Map<String, dynamic> json) {
    return BhamLaunchGateReport(
      generatedAtUtc:
          DateTime.tryParse(json['generated_at_utc'] as String? ?? '')
                  ?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      status: BhamLaunchGateStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => BhamLaunchGateStatus.manualReviewRequired,
      ),
      evidenceSnapshot: BhamLaunchEvidenceSnapshot.fromJson(
        Map<String, dynamic>.from(
          json['evidence_snapshot'] as Map? ?? const <String, dynamic>{},
        ),
      ),
      fallbackStates: (json['fallback_states'] as List<dynamic>? ?? const [])
          .map(
            (item) => BhamFallbackState.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      criticalFlowChecks:
          (json['critical_flow_checks'] as List<dynamic>? ?? const [])
              .map(
                (item) => BhamCriticalFlowCheckResult.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList(),
      expansionGates: (json['expansion_gates'] as List<dynamic>? ?? const [])
          .map(
            (item) => BhamExpansionGateResult.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      unresolvedBlockers: List<String>.from(
        json['unresolved_blockers'] as List? ?? const <String>[],
      ),
      signoffInputs: (json['signoff_inputs'] as List<dynamic>? ?? const [])
          .map(
            (item) => BhamManualEvidenceSlot.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }
}
