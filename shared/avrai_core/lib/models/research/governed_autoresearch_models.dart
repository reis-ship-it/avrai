import 'dart:async';

enum ResearchHumanAccess { adminOnly }

enum ResearchVisibilityScope {
  adminOnly,
  runtimeInternalProjection,
}

enum ResearchLayer { reality, universe, world, crossLayer }

enum ResearchRunLane { sandboxReplay }

enum ResearchRunLifecycleState {
  draft,
  approved,
  queued,
  running,
  pausing,
  paused,
  review,
  stopped,
  completed,
  failed,
  redirectPending,
  archived,
}

enum ResearchApprovalKind {
  charter,
  egressOpenWeb,
  reviewDisposition,
}

enum ResearchApprovalStatus {
  notRequired,
  pending,
  approved,
  rejected,
  revoked,
  expired,
}

enum ResearchControlActionType {
  approveCharter,
  queueRun,
  pauseRun,
  resumeRun,
  stopRun,
  redirectRun,
  requestExplanation,
  reviewCandidate,
  requestEgressApproval,
  revokeEgressApproval,
  appendNote,
  checkpointRun,
  triggerKillSwitch,
}

enum ResearchEgressMode {
  internalOnly,
  brokeredOpenWeb,
}

enum ResearchAlertSeverity { info, warning, critical }

enum ResearchArtifactKind {
  charter,
  checkpoint,
  explanation,
  evidenceBundle,
  sandboxProjection,
  auditLedger,
  approvalReceipt,
  signedEvidencePack,
}

class ResearchCharter {
  const ResearchCharter({
    required this.id,
    required this.title,
    required this.objective,
    required this.hypothesis,
    required this.allowedExperimentSurfaces,
    required this.successMetrics,
    required this.stopConditions,
    required this.hardBans,
    required this.createdAt,
    required this.updatedAt,
    this.approvedBy,
    this.approvedAt,
  });

  final String id;
  final String title;
  final String objective;
  final String hypothesis;
  final List<String> allowedExperimentSurfaces;
  final List<String> successMetrics;
  final List<String> stopConditions;
  final List<String> hardBans;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? approvedBy;
  final DateTime? approvedAt;

  bool get isApproved => approvedBy != null && approvedAt != null;

  ResearchCharter copyWith({
    String? title,
    String? objective,
    String? hypothesis,
    List<String>? allowedExperimentSurfaces,
    List<String>? successMetrics,
    List<String>? stopConditions,
    List<String>? hardBans,
    DateTime? updatedAt,
    String? approvedBy,
    DateTime? approvedAt,
  }) {
    return ResearchCharter(
      id: id,
      title: title ?? this.title,
      objective: objective ?? this.objective,
      hypothesis: hypothesis ?? this.hypothesis,
      allowedExperimentSurfaces:
          allowedExperimentSurfaces ?? this.allowedExperimentSurfaces,
      successMetrics: successMetrics ?? this.successMetrics,
      stopConditions: stopConditions ?? this.stopConditions,
      hardBans: hardBans ?? this.hardBans,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'objective': objective,
        'hypothesis': hypothesis,
        'allowedExperimentSurfaces': allowedExperimentSurfaces,
        'successMetrics': successMetrics,
        'stopConditions': stopConditions,
        'hardBans': hardBans,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'approvedBy': approvedBy,
        'approvedAt': approvedAt?.toIso8601String(),
      };

  factory ResearchCharter.fromJson(Map<String, dynamic> json) {
    return ResearchCharter(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled charter',
      objective: json['objective']?.toString() ?? '',
      hypothesis: json['hypothesis']?.toString() ?? '',
      allowedExperimentSurfaces: _stringList(json['allowedExperimentSurfaces']),
      successMetrics: _stringList(json['successMetrics']),
      stopConditions: _stringList(json['stopConditions']),
      hardBans: _stringList(json['hardBans']),
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
      approvedBy: json['approvedBy']?.toString(),
      approvedAt: _parseNullableDateTime(json['approvedAt']),
    );
  }
}

class ResearchCheckpoint {
  const ResearchCheckpoint({
    required this.id,
    required this.runId,
    required this.summary,
    required this.state,
    required this.createdAt,
    required this.metricSnapshot,
    required this.artifactIds,
    required this.requiresHumanReview,
    required this.contradictionDetected,
  });

  final String id;
  final String runId;
  final String summary;
  final ResearchRunLifecycleState state;
  final DateTime createdAt;
  final Map<String, double> metricSnapshot;
  final List<String> artifactIds;
  final bool requiresHumanReview;
  final bool contradictionDetected;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'runId': runId,
        'summary': summary,
        'state': state.name,
        'createdAt': createdAt.toIso8601String(),
        'metricSnapshot': metricSnapshot,
        'artifactIds': artifactIds,
        'requiresHumanReview': requiresHumanReview,
        'contradictionDetected': contradictionDetected,
      };

  factory ResearchCheckpoint.fromJson(Map<String, dynamic> json) {
    return ResearchCheckpoint(
      id: json['id']?.toString() ?? '',
      runId: json['runId']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      state: _parseLifecycleState(json['state']?.toString()),
      createdAt: _parseDateTime(json['createdAt']),
      metricSnapshot: _doubleMap(json['metricSnapshot']),
      artifactIds: _stringList(json['artifactIds']),
      requiresHumanReview: json['requiresHumanReview'] as bool? ?? false,
      contradictionDetected: json['contradictionDetected'] as bool? ?? false,
    );
  }
}

class ResearchControlAction {
  const ResearchControlAction({
    required this.id,
    required this.runId,
    required this.actionType,
    required this.actorAlias,
    required this.rationale,
    required this.createdAt,
    required this.modelVersion,
    required this.policyVersion,
    required this.details,
    this.checkpointId,
  });

  final String id;
  final String runId;
  final ResearchControlActionType actionType;
  final String actorAlias;
  final String rationale;
  final DateTime createdAt;
  final String modelVersion;
  final String policyVersion;
  final Map<String, dynamic> details;
  final String? checkpointId;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'runId': runId,
        'actionType': actionType.name,
        'actorAlias': actorAlias,
        'rationale': rationale,
        'createdAt': createdAt.toIso8601String(),
        'modelVersion': modelVersion,
        'policyVersion': policyVersion,
        'details': details,
        'checkpointId': checkpointId,
      };

  factory ResearchControlAction.fromJson(Map<String, dynamic> json) {
    return ResearchControlAction(
      id: json['id']?.toString() ?? '',
      runId: json['runId']?.toString() ?? '',
      actionType: _parseControlActionType(json['actionType']?.toString()),
      actorAlias: json['actorAlias']?.toString() ?? 'unknown_actor',
      rationale: json['rationale']?.toString() ?? '',
      createdAt: _parseDateTime(json['createdAt']),
      modelVersion: json['modelVersion']?.toString() ?? 'unknown',
      policyVersion: json['policyVersion']?.toString() ?? 'unknown',
      details: _map(json['details']),
      checkpointId: json['checkpointId']?.toString(),
    );
  }
}

class ResearchExplanation {
  const ResearchExplanation({
    required this.id,
    required this.runId,
    required this.summary,
    required this.currentStep,
    required this.rationale,
    required this.nextStep,
    required this.evidenceSummary,
    required this.createdAt,
    this.checkpointId,
  });

  final String id;
  final String runId;
  final String summary;
  final String currentStep;
  final String rationale;
  final String nextStep;
  final String evidenceSummary;
  final DateTime createdAt;
  final String? checkpointId;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'runId': runId,
        'summary': summary,
        'currentStep': currentStep,
        'rationale': rationale,
        'nextStep': nextStep,
        'evidenceSummary': evidenceSummary,
        'createdAt': createdAt.toIso8601String(),
        'checkpointId': checkpointId,
      };

  factory ResearchExplanation.fromJson(Map<String, dynamic> json) {
    return ResearchExplanation(
      id: json['id']?.toString() ?? '',
      runId: json['runId']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      currentStep: json['currentStep']?.toString() ?? '',
      rationale: json['rationale']?.toString() ?? '',
      nextStep: json['nextStep']?.toString() ?? '',
      evidenceSummary: json['evidenceSummary']?.toString() ?? '',
      createdAt: _parseDateTime(json['createdAt']),
      checkpointId: json['checkpointId']?.toString(),
    );
  }
}

class ResearchApproval {
  const ResearchApproval({
    required this.id,
    required this.runId,
    required this.kind,
    required this.status,
    required this.createdAt,
    this.actorAlias,
    this.reason,
    this.decidedAt,
    this.expiresAt,
  });

  final String id;
  final String runId;
  final ResearchApprovalKind kind;
  final ResearchApprovalStatus status;
  final DateTime createdAt;
  final String? actorAlias;
  final String? reason;
  final DateTime? decidedAt;
  final DateTime? expiresAt;

  bool get isActiveApproved =>
      status == ResearchApprovalStatus.approved &&
      (expiresAt == null || expiresAt!.isAfter(DateTime.now().toUtc()));

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'runId': runId,
        'kind': kind.name,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'actorAlias': actorAlias,
        'reason': reason,
        'decidedAt': decidedAt?.toIso8601String(),
        'expiresAt': expiresAt?.toIso8601String(),
      };

  factory ResearchApproval.fromJson(Map<String, dynamic> json) {
    return ResearchApproval(
      id: json['id']?.toString() ?? '',
      runId: json['runId']?.toString() ?? '',
      kind: _parseApprovalKind(json['kind']?.toString()),
      status: _parseApprovalStatus(json['status']?.toString()),
      createdAt: _parseDateTime(json['createdAt']),
      actorAlias: json['actorAlias']?.toString(),
      reason: json['reason']?.toString(),
      decidedAt: _parseNullableDateTime(json['decidedAt']),
      expiresAt: _parseNullableDateTime(json['expiresAt']),
    );
  }
}

class ResearchArtifactRef {
  const ResearchArtifactRef({
    required this.id,
    required this.runId,
    required this.kind,
    required this.storageKey,
    required this.summary,
    required this.createdAt,
    required this.isRedacted,
    this.checksum,
    this.expiresAt,
  });

  final String id;
  final String runId;
  final ResearchArtifactKind kind;
  final String storageKey;
  final String summary;
  final DateTime createdAt;
  final bool isRedacted;
  final String? checksum;
  final DateTime? expiresAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'runId': runId,
        'kind': kind.name,
        'storageKey': storageKey,
        'summary': summary,
        'createdAt': createdAt.toIso8601String(),
        'isRedacted': isRedacted,
        'checksum': checksum,
        'expiresAt': expiresAt?.toIso8601String(),
      };

  factory ResearchArtifactRef.fromJson(Map<String, dynamic> json) {
    return ResearchArtifactRef(
      id: json['id']?.toString() ?? '',
      runId: json['runId']?.toString() ?? '',
      kind: _parseArtifactKind(json['kind']?.toString()),
      storageKey: json['storageKey']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      createdAt: _parseDateTime(json['createdAt']),
      isRedacted: json['isRedacted'] as bool? ?? true,
      checksum: json['checksum']?.toString(),
      expiresAt: _parseNullableDateTime(json['expiresAt']),
    );
  }
}

class ResearchSandboxResultProjection {
  const ResearchSandboxResultProjection({
    required this.runId,
    required this.checkpointId,
    required this.summary,
    required this.metrics,
    required this.createdAt,
    required this.promotionCandidate,
    required this.safeForModelConsumption,
    required this.violationCount,
  });

  final String runId;
  final String checkpointId;
  final String summary;
  final Map<String, double> metrics;
  final DateTime createdAt;
  final bool promotionCandidate;
  final bool safeForModelConsumption;
  final int violationCount;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'runId': runId,
        'checkpointId': checkpointId,
        'summary': summary,
        'metrics': metrics,
        'createdAt': createdAt.toIso8601String(),
        'promotionCandidate': promotionCandidate,
        'safeForModelConsumption': safeForModelConsumption,
        'violationCount': violationCount,
      };

  factory ResearchSandboxResultProjection.fromJson(
    Map<String, dynamic> json,
  ) {
    return ResearchSandboxResultProjection(
      runId: json['runId']?.toString() ?? '',
      checkpointId: json['checkpointId']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      metrics: _doubleMap(json['metrics']),
      createdAt: _parseDateTime(json['createdAt']),
      promotionCandidate: json['promotionCandidate'] as bool? ?? false,
      safeForModelConsumption: json['safeForModelConsumption'] as bool? ?? true,
      violationCount: json['violationCount'] as int? ?? 0,
    );
  }
}

class ResearchAlert {
  const ResearchAlert({
    required this.id,
    required this.runId,
    required this.severity,
    required this.title,
    required this.message,
    required this.createdAt,
  });

  final String id;
  final String runId;
  final ResearchAlertSeverity severity;
  final String title;
  final String message;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'runId': runId,
        'severity': severity.name,
        'title': title,
        'message': message,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ResearchAlert.fromJson(Map<String, dynamic> json) {
    return ResearchAlert(
      id: json['id']?.toString() ?? '',
      runId: json['runId']?.toString() ?? '',
      severity: _parseAlertSeverity(json['severity']?.toString()),
      title: json['title']?.toString() ?? 'Alert',
      message: json['message']?.toString() ?? '',
      createdAt: _parseDateTime(json['createdAt']),
    );
  }
}

class ResearchRunState {
  const ResearchRunState({
    required this.id,
    required this.title,
    required this.hypothesis,
    required this.layer,
    required this.ownerAgentAlias,
    required this.lifecycleState,
    required this.humanAccess,
    required this.visibilityScope,
    required this.lane,
    required this.charter,
    required this.egressMode,
    required this.requiresAdminApproval,
    required this.sandboxOnly,
    required this.modelVersion,
    required this.policyVersion,
    required this.metrics,
    required this.tags,
    required this.controlActions,
    required this.checkpoints,
    required this.approvals,
    required this.artifacts,
    required this.alerts,
    required this.createdAt,
    required this.updatedAt,
    this.latestExplanation,
    this.latestSandboxProjection,
    this.lastHeartbeatAt,
    this.activeCheckpointId,
    this.redirectDirective,
    this.contradictionDetected = false,
    this.killSwitchActive = false,
  });

  final String id;
  final String title;
  final String hypothesis;
  final ResearchLayer layer;
  final String ownerAgentAlias;
  final ResearchRunLifecycleState lifecycleState;
  final ResearchHumanAccess humanAccess;
  final ResearchVisibilityScope visibilityScope;
  final ResearchRunLane lane;
  final ResearchCharter charter;
  final ResearchEgressMode egressMode;
  final bool requiresAdminApproval;
  final bool sandboxOnly;
  final String modelVersion;
  final String policyVersion;
  final Map<String, double> metrics;
  final List<String> tags;
  final List<ResearchControlAction> controlActions;
  final List<ResearchCheckpoint> checkpoints;
  final List<ResearchApproval> approvals;
  final List<ResearchArtifactRef> artifacts;
  final List<ResearchAlert> alerts;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ResearchExplanation? latestExplanation;
  final ResearchSandboxResultProjection? latestSandboxProjection;
  final DateTime? lastHeartbeatAt;
  final String? activeCheckpointId;
  final String? redirectDirective;
  final bool contradictionDetected;
  final bool killSwitchActive;

  bool get isAdminOnly => humanAccess == ResearchHumanAccess.adminOnly;

  bool get hasApprovedCharter => approvals.any(
        (approval) =>
            approval.kind == ResearchApprovalKind.charter &&
            approval.status == ResearchApprovalStatus.approved,
      );

  bool get hasApprovedOpenWebAccess => approvals.any(
        (approval) =>
            approval.kind == ResearchApprovalKind.egressOpenWeb &&
            approval.isActiveApproved,
      );

  ResearchRunState copyWith({
    String? title,
    String? hypothesis,
    ResearchLayer? layer,
    String? ownerAgentAlias,
    ResearchRunLifecycleState? lifecycleState,
    ResearchHumanAccess? humanAccess,
    ResearchVisibilityScope? visibilityScope,
    ResearchRunLane? lane,
    ResearchCharter? charter,
    ResearchEgressMode? egressMode,
    bool? requiresAdminApproval,
    bool? sandboxOnly,
    String? modelVersion,
    String? policyVersion,
    Map<String, double>? metrics,
    List<String>? tags,
    List<ResearchControlAction>? controlActions,
    List<ResearchCheckpoint>? checkpoints,
    List<ResearchApproval>? approvals,
    List<ResearchArtifactRef>? artifacts,
    List<ResearchAlert>? alerts,
    DateTime? updatedAt,
    ResearchExplanation? latestExplanation,
    ResearchSandboxResultProjection? latestSandboxProjection,
    DateTime? lastHeartbeatAt,
    String? activeCheckpointId,
    String? redirectDirective,
    bool? contradictionDetected,
    bool? killSwitchActive,
  }) {
    return ResearchRunState(
      id: id,
      title: title ?? this.title,
      hypothesis: hypothesis ?? this.hypothesis,
      layer: layer ?? this.layer,
      ownerAgentAlias: ownerAgentAlias ?? this.ownerAgentAlias,
      lifecycleState: lifecycleState ?? this.lifecycleState,
      humanAccess: humanAccess ?? this.humanAccess,
      visibilityScope: visibilityScope ?? this.visibilityScope,
      lane: lane ?? this.lane,
      charter: charter ?? this.charter,
      egressMode: egressMode ?? this.egressMode,
      requiresAdminApproval:
          requiresAdminApproval ?? this.requiresAdminApproval,
      sandboxOnly: sandboxOnly ?? this.sandboxOnly,
      modelVersion: modelVersion ?? this.modelVersion,
      policyVersion: policyVersion ?? this.policyVersion,
      metrics: metrics ?? this.metrics,
      tags: tags ?? this.tags,
      controlActions: controlActions ?? this.controlActions,
      checkpoints: checkpoints ?? this.checkpoints,
      approvals: approvals ?? this.approvals,
      artifacts: artifacts ?? this.artifacts,
      alerts: alerts ?? this.alerts,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      latestExplanation: latestExplanation ?? this.latestExplanation,
      latestSandboxProjection:
          latestSandboxProjection ?? this.latestSandboxProjection,
      lastHeartbeatAt: lastHeartbeatAt ?? this.lastHeartbeatAt,
      activeCheckpointId: activeCheckpointId ?? this.activeCheckpointId,
      redirectDirective: redirectDirective ?? this.redirectDirective,
      contradictionDetected:
          contradictionDetected ?? this.contradictionDetected,
      killSwitchActive: killSwitchActive ?? this.killSwitchActive,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'hypothesis': hypothesis,
        'layer': layer.name,
        'ownerAgentAlias': ownerAgentAlias,
        'lifecycleState': lifecycleState.name,
        'humanAccess': humanAccess.name,
        'visibilityScope': visibilityScope.name,
        'lane': lane.name,
        'charter': charter.toJson(),
        'egressMode': egressMode.name,
        'requiresAdminApproval': requiresAdminApproval,
        'sandboxOnly': sandboxOnly,
        'modelVersion': modelVersion,
        'policyVersion': policyVersion,
        'metrics': metrics,
        'tags': tags,
        'controlActions':
            controlActions.map((action) => action.toJson()).toList(),
        'checkpoints':
            checkpoints.map((checkpoint) => checkpoint.toJson()).toList(),
        'approvals': approvals.map((approval) => approval.toJson()).toList(),
        'artifacts': artifacts.map((artifact) => artifact.toJson()).toList(),
        'alerts': alerts.map((alert) => alert.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'latestExplanation': latestExplanation?.toJson(),
        'latestSandboxProjection': latestSandboxProjection?.toJson(),
        'lastHeartbeatAt': lastHeartbeatAt?.toIso8601String(),
        'activeCheckpointId': activeCheckpointId,
        'redirectDirective': redirectDirective,
        'contradictionDetected': contradictionDetected,
        'killSwitchActive': killSwitchActive,
      };

  factory ResearchRunState.fromJson(Map<String, dynamic> json) {
    return ResearchRunState(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled research run',
      hypothesis: json['hypothesis']?.toString() ?? '',
      layer: _parseLayer(json['layer']?.toString()),
      ownerAgentAlias: json['ownerAgentAlias']?.toString() ?? 'unknown_agent',
      lifecycleState: _parseLifecycleState(json['lifecycleState']?.toString()),
      humanAccess: _parseHumanAccess(json['humanAccess']?.toString()),
      visibilityScope:
          _parseVisibilityScope(json['visibilityScope']?.toString()),
      lane: _parseRunLane(json['lane']?.toString()),
      charter: json['charter'] is Map<String, dynamic>
          ? ResearchCharter.fromJson(json['charter'] as Map<String, dynamic>)
          : ResearchCharter.fromJson(const <String, dynamic>{}),
      egressMode: _parseEgressMode(json['egressMode']?.toString()),
      requiresAdminApproval: json['requiresAdminApproval'] as bool? ?? true,
      sandboxOnly: json['sandboxOnly'] as bool? ?? true,
      modelVersion: json['modelVersion']?.toString() ?? 'unknown',
      policyVersion: json['policyVersion']?.toString() ?? 'unknown',
      metrics: _doubleMap(json['metrics']),
      tags: _stringList(json['tags']),
      controlActions: _listOfMaps(json['controlActions'])
          .map(ResearchControlAction.fromJson)
          .toList(growable: false),
      checkpoints: _listOfMaps(json['checkpoints'])
          .map(ResearchCheckpoint.fromJson)
          .toList(growable: false),
      approvals: _listOfMaps(json['approvals'])
          .map(ResearchApproval.fromJson)
          .toList(growable: false),
      artifacts: _listOfMaps(json['artifacts'])
          .map(ResearchArtifactRef.fromJson)
          .toList(growable: false),
      alerts: _listOfMaps(json['alerts'])
          .map(ResearchAlert.fromJson)
          .toList(growable: false),
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
      latestExplanation: json['latestExplanation'] is Map<String, dynamic>
          ? ResearchExplanation.fromJson(
              json['latestExplanation'] as Map<String, dynamic>,
            )
          : null,
      latestSandboxProjection:
          json['latestSandboxProjection'] is Map<String, dynamic>
              ? ResearchSandboxResultProjection.fromJson(
                  json['latestSandboxProjection'] as Map<String, dynamic>,
                )
              : null,
      lastHeartbeatAt: _parseNullableDateTime(json['lastHeartbeatAt']),
      activeCheckpointId: json['activeCheckpointId']?.toString(),
      redirectDirective: json['redirectDirective']?.toString(),
      contradictionDetected: json['contradictionDetected'] as bool? ?? false,
      killSwitchActive: json['killSwitchActive'] as bool? ?? false,
    );
  }
}

abstract class AdminResearchControlContract {
  Stream<List<ResearchRunState>> watchRuns();
  Future<List<ResearchRunState>> listRuns();
  Future<ResearchRunState> approveCharter({
    required String runId,
    required String actorAlias,
    String rationale = '',
  });
  Future<ResearchRunState> queueRun({
    required String runId,
    required String actorAlias,
  });
  Future<ResearchRunState> pauseRun({
    required String runId,
    required String actorAlias,
    String rationale = '',
  });
  Future<ResearchRunState> resumeRun({
    required String runId,
    required String actorAlias,
  });
  Future<ResearchRunState> stopRun({
    required String runId,
    required String actorAlias,
    String rationale = '',
  });
  Future<ResearchRunState> redirectRun({
    required String runId,
    required String actorAlias,
    required String directive,
  });
  Future<ResearchExplanation> getExplanation({
    required String runId,
    required String actorAlias,
  });
  Future<ResearchRunState> reviewCandidate({
    required String runId,
    required String actorAlias,
    required bool approved,
    String rationale = '',
  });
  Future<ResearchRunState?> watchRun(String runId);
}

abstract class ResearchSupervisorContract {
  Future<ResearchRunState> startSandboxRun({
    required String runId,
    required String actorAlias,
  });
  Future<ResearchCheckpoint> checkpointRun({
    required String runId,
    required String actorAlias,
    required String summary,
    Map<String, double> metricSnapshot = const <String, double>{},
    bool requiresHumanReview = false,
    bool contradictionDetected = false,
  });
  Future<ResearchArtifactRef> appendArtifact({
    required String runId,
    required String actorAlias,
    required ResearchArtifactKind kind,
    required String storageKey,
    required String summary,
    bool isRedacted = true,
    String? checksum,
  });
  Future<void> emitAlert(ResearchAlert alert);
  Future<ResearchApproval> requestEgressApproval({
    required String runId,
    required String actorAlias,
    required Duration ttl,
    String rationale = '',
  });
  Future<ResearchApproval> recordDisposition({
    required String runId,
    required String actorAlias,
    required bool approved,
    String rationale = '',
  });
}

abstract class ResearchEgressBrokerContract {
  Future<ResearchApproval> requestOpenWebAccess({
    required String runId,
    required String actorAlias,
    required Duration ttl,
    String rationale = '',
  });
  Future<ResearchArtifactRef> fetchEvidence({
    required String runId,
    required String actorAlias,
    required Uri sourceUri,
  });
  Future<void> revokeAccess({
    required String runId,
    required String actorAlias,
    String rationale = '',
  });
}

List<String> _stringList(dynamic value) {
  if (value is List<dynamic>) {
    return value.map((item) => item.toString()).toList(growable: false);
  }
  return const <String>[];
}

List<Map<String, dynamic>> _listOfMaps(dynamic value) {
  if (value is List<dynamic>) {
    return value.whereType<Map<String, dynamic>>().toList(growable: false);
  }
  return const <Map<String, dynamic>>[];
}

Map<String, dynamic> _map(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map(
      (key, mapValue) => MapEntry(key.toString(), mapValue),
    );
  }
  return const <String, dynamic>{};
}

Map<String, double> _doubleMap(dynamic value) {
  final parsed = <String, double>{};
  final raw = _map(value);
  for (final MapEntry<String, dynamic> entry in raw.entries) {
    final dynamic numericValue = entry.value;
    if (numericValue is num) {
      parsed[entry.key] = numericValue.toDouble();
    }
  }
  return parsed;
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

ResearchHumanAccess _parseHumanAccess(String? raw) {
  return ResearchHumanAccess.values.firstWhere(
    (value) => value.name == raw,
    orElse: () => ResearchHumanAccess.adminOnly,
  );
}

ResearchVisibilityScope _parseVisibilityScope(String? raw) {
  return ResearchVisibilityScope.values.firstWhere(
    (value) => value.name == raw,
    orElse: () => ResearchVisibilityScope.adminOnly,
  );
}

ResearchLayer _parseLayer(String? raw) {
  return ResearchLayer.values.firstWhere(
    (value) => value.name == raw,
    orElse: () => ResearchLayer.crossLayer,
  );
}

ResearchRunLane _parseRunLane(String? raw) {
  return ResearchRunLane.values.firstWhere(
    (value) => value.name == raw,
    orElse: () => ResearchRunLane.sandboxReplay,
  );
}

ResearchRunLifecycleState _parseLifecycleState(String? raw) {
  return ResearchRunLifecycleState.values.firstWhere(
    (value) => value.name == raw,
    orElse: () => ResearchRunLifecycleState.draft,
  );
}

ResearchApprovalKind _parseApprovalKind(String? raw) {
  return ResearchApprovalKind.values.firstWhere(
    (value) => value.name == raw,
    orElse: () => ResearchApprovalKind.charter,
  );
}

ResearchApprovalStatus _parseApprovalStatus(String? raw) {
  return ResearchApprovalStatus.values.firstWhere(
    (value) => value.name == raw,
    orElse: () => ResearchApprovalStatus.pending,
  );
}

ResearchControlActionType _parseControlActionType(String? raw) {
  return ResearchControlActionType.values.firstWhere(
    (value) => value.name == raw,
    orElse: () => ResearchControlActionType.appendNote,
  );
}

ResearchEgressMode _parseEgressMode(String? raw) {
  return ResearchEgressMode.values.firstWhere(
    (value) => value.name == raw,
    orElse: () => ResearchEgressMode.internalOnly,
  );
}

ResearchAlertSeverity _parseAlertSeverity(String? raw) {
  return ResearchAlertSeverity.values.firstWhere(
    (value) => value.name == raw,
    orElse: () => ResearchAlertSeverity.info,
  );
}

ResearchArtifactKind _parseArtifactKind(String? raw) {
  return ResearchArtifactKind.values.firstWhere(
    (value) => value.name == raw,
    orElse: () => ResearchArtifactKind.auditLedger,
  );
}
