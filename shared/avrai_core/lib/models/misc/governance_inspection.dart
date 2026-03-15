import '../atomic_timestamp.dart';

enum GovernanceStratum {
  personal,
  locality,
  world,
  universal,
}

enum GovernanceVisibilityTier {
  summary,
  triggeredDetail,
  breakGlassDetail,
}

class GovernanceWhoKernelAgentMatch {
  const GovernanceWhoKernelAgentMatch({
    required this.userId,
    required this.aiSignature,
    required this.isOnline,
    this.extra = const <String, dynamic>{},
  });

  final String userId;
  final String aiSignature;
  final bool isOnline;
  final Map<String, dynamic> extra;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'userId': userId,
        'aiSignature': aiSignature,
        'isOnline': isOnline,
        ...extra,
      };

  factory GovernanceWhoKernelAgentMatch.fromJson(Map<String, dynamic> json) {
    return GovernanceWhoKernelAgentMatch(
      userId: json['userId'] as String? ?? '',
      aiSignature: json['aiSignature'] as String? ?? '',
      isOnline: json['isOnline'] as bool? ?? false,
      extra: Map<String, dynamic>.from(json)
        ..remove('userId')
        ..remove('aiSignature')
        ..remove('isOnline'),
    );
  }
}

class GovernanceWhatKernelAgentState {
  const GovernanceWhatKernelAgentState({
    this.aiStatus,
    this.currentStage,
    this.aiConnections,
    this.topPredictedAction,
    this.extra = const <String, dynamic>{},
  });

  final String? aiStatus;
  final String? currentStage;
  final int? aiConnections;
  final String? topPredictedAction;
  final Map<String, dynamic> extra;

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (aiStatus != null) 'aiStatus': aiStatus,
        if (currentStage != null) 'currentStage': currentStage,
        if (aiConnections != null) 'aiConnections': aiConnections,
        if (topPredictedAction != null)
          'topPredictedAction': topPredictedAction,
        ...extra,
      };

  factory GovernanceWhatKernelAgentState.fromJson(Map<String, dynamic> json) {
    return GovernanceWhatKernelAgentState(
      aiStatus: json['aiStatus'] as String?,
      currentStage: json['currentStage'] as String?,
      aiConnections: (json['aiConnections'] as num?)?.toInt(),
      topPredictedAction: json['topPredictedAction'] as String?,
      extra: Map<String, dynamic>.from(json)
        ..remove('aiStatus')
        ..remove('currentStage')
        ..remove('aiConnections')
        ..remove('topPredictedAction'),
    );
  }
}

class GovernanceWhoKernelPayload {
  const GovernanceWhoKernelPayload({
    required this.inspectionActorId,
    required this.isHumanActor,
    required this.targetRuntimeId,
    required this.targetStratum,
    this.matchedAgentCount,
    this.matchedAgents = const <GovernanceWhoKernelAgentMatch>[],
    this.bindingSource,
    this.actorLabel,
    this.extra = const <String, dynamic>{},
  });

  final String inspectionActorId;
  final bool isHumanActor;
  final String targetRuntimeId;
  final String targetStratum;
  final int? matchedAgentCount;
  final List<GovernanceWhoKernelAgentMatch> matchedAgents;
  final String? bindingSource;
  final String? actorLabel;
  final Map<String, dynamic> extra;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'inspectionActorId': inspectionActorId,
        'isHumanActor': isHumanActor,
        'targetRuntimeId': targetRuntimeId,
        'targetStratum': targetStratum,
        if (matchedAgentCount != null) 'matchedAgentCount': matchedAgentCount,
        'matchedAgents': matchedAgents
            .map((agent) => agent.toJson())
            .toList(growable: false),
        if (bindingSource != null) 'bindingSource': bindingSource,
        if (actorLabel != null) 'actorLabel': actorLabel,
        ...extra,
      };

  factory GovernanceWhoKernelPayload.fromJson(Map<String, dynamic> json) {
    return GovernanceWhoKernelPayload(
      inspectionActorId: json['inspectionActorId'] as String? ?? '',
      isHumanActor: json['isHumanActor'] as bool? ?? false,
      targetRuntimeId: json['targetRuntimeId'] as String? ?? '',
      targetStratum: json['targetStratum'] as String? ?? '',
      matchedAgentCount: (json['matchedAgentCount'] as num?)?.toInt(),
      matchedAgents: ((json['matchedAgents'] as List?) ?? const <dynamic>[])
          .whereType<Map>()
          .map((entry) => GovernanceWhoKernelAgentMatch.fromJson(
                Map<String, dynamic>.from(entry),
              ))
          .toList(growable: false),
      bindingSource: json['bindingSource'] as String?,
      actorLabel: json['actorLabel'] as String?,
      extra: Map<String, dynamic>.from(json)
        ..remove('inspectionActorId')
        ..remove('isHumanActor')
        ..remove('targetRuntimeId')
        ..remove('targetStratum')
        ..remove('matchedAgentCount')
        ..remove('matchedAgents')
        ..remove('bindingSource')
        ..remove('actorLabel'),
    );
  }
}

class GovernanceWhatKernelPayload {
  const GovernanceWhatKernelPayload({
    this.inspectionCountForRuntime,
    this.breakGlassCountForRuntime,
    this.dashboardActiveConnections,
    this.dashboardTotalCommunications,
    this.operationalScore,
    this.matchedAgentStates = const <GovernanceWhatKernelAgentState>[],
    this.extra = const <String, dynamic>{},
  });

  final int? inspectionCountForRuntime;
  final int? breakGlassCountForRuntime;
  final int? dashboardActiveConnections;
  final int? dashboardTotalCommunications;
  final double? operationalScore;
  final List<GovernanceWhatKernelAgentState> matchedAgentStates;
  final Map<String, dynamic> extra;

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (inspectionCountForRuntime != null)
          'inspectionCountForRuntime': inspectionCountForRuntime,
        if (breakGlassCountForRuntime != null)
          'breakGlassCountForRuntime': breakGlassCountForRuntime,
        if (dashboardActiveConnections != null)
          'dashboardActiveConnections': dashboardActiveConnections,
        if (dashboardTotalCommunications != null)
          'dashboardTotalCommunications': dashboardTotalCommunications,
        if (operationalScore != null) 'operationalScore': operationalScore,
        'matchedAgentStates': matchedAgentStates
            .map((state) => state.toJson())
            .toList(growable: false),
        ...extra,
      };

  factory GovernanceWhatKernelPayload.fromJson(Map<String, dynamic> json) {
    return GovernanceWhatKernelPayload(
      inspectionCountForRuntime:
          (json['inspectionCountForRuntime'] as num?)?.toInt(),
      breakGlassCountForRuntime:
          (json['breakGlassCountForRuntime'] as num?)?.toInt(),
      dashboardActiveConnections:
          (json['dashboardActiveConnections'] as num?)?.toInt(),
      dashboardTotalCommunications:
          (json['dashboardTotalCommunications'] as num?)?.toInt(),
      operationalScore: (json['operationalScore'] as num?)?.toDouble(),
      matchedAgentStates:
          ((json['matchedAgentStates'] as List?) ?? const <dynamic>[])
              .whereType<Map>()
              .map((entry) => GovernanceWhatKernelAgentState.fromJson(
                    Map<String, dynamic>.from(entry),
                  ))
              .toList(growable: false),
      extra: Map<String, dynamic>.from(json)
        ..remove('inspectionCountForRuntime')
        ..remove('breakGlassCountForRuntime')
        ..remove('dashboardActiveConnections')
        ..remove('dashboardTotalCommunications')
        ..remove('operationalScore')
        ..remove('matchedAgentStates'),
    );
  }
}

class GovernanceWhenKernelPayload {
  const GovernanceWhenKernelPayload({
    required this.requestedAt,
    required this.requestedAtSynchronized,
    required this.quantumAtomicTimeRequired,
    this.bindingRegisteredAt,
    this.clockState,
    this.extra = const <String, dynamic>{},
  });

  final String requestedAt;
  final bool requestedAtSynchronized;
  final bool quantumAtomicTimeRequired;
  final String? bindingRegisteredAt;
  final String? clockState;
  final Map<String, dynamic> extra;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'requestedAt': requestedAt,
        'requestedAtSynchronized': requestedAtSynchronized,
        'quantumAtomicTimeRequired': quantumAtomicTimeRequired,
        if (bindingRegisteredAt != null)
          'bindingRegisteredAt': bindingRegisteredAt,
        if (clockState != null) 'clockState': clockState,
        ...extra,
      };

  factory GovernanceWhenKernelPayload.fromJson(Map<String, dynamic> json) {
    return GovernanceWhenKernelPayload(
      requestedAt: json['requestedAt'] as String? ?? '',
      requestedAtSynchronized:
          json['requestedAtSynchronized'] as bool? ?? false,
      quantumAtomicTimeRequired:
          json['quantumAtomicTimeRequired'] as bool? ?? false,
      bindingRegisteredAt: json['bindingRegisteredAt'] as String?,
      clockState: json['clockState'] as String?,
      extra: Map<String, dynamic>.from(json)
        ..remove('requestedAt')
        ..remove('requestedAtSynchronized')
        ..remove('quantumAtomicTimeRequired')
        ..remove('bindingRegisteredAt')
        ..remove('clockState'),
    );
  }
}

class GovernanceWhereKernelPayload {
  const GovernanceWhereKernelPayload({
    required this.runtimeId,
    required this.governanceStratum,
    required this.resolutionMode,
    this.bindingRuntimeId,
    this.scope,
    this.extra = const <String, dynamic>{},
  });

  final String runtimeId;
  final String governanceStratum;
  final String resolutionMode;
  final String? bindingRuntimeId;
  final String? scope;
  final Map<String, dynamic> extra;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'runtimeId': runtimeId,
        'governanceStratum': governanceStratum,
        'resolutionMode': resolutionMode,
        if (bindingRuntimeId != null) 'bindingRuntimeId': bindingRuntimeId,
        if (scope != null) 'scope': scope,
        ...extra,
      };

  factory GovernanceWhereKernelPayload.fromJson(Map<String, dynamic> json) {
    return GovernanceWhereKernelPayload(
      runtimeId: json['runtimeId'] as String? ?? '',
      governanceStratum: json['governanceStratum'] as String? ?? '',
      resolutionMode: json['resolutionMode'] as String? ?? '',
      bindingRuntimeId: json['bindingRuntimeId'] as String?,
      scope: json['scope'] as String?,
      extra: Map<String, dynamic>.from(json)
        ..remove('runtimeId')
        ..remove('governanceStratum')
        ..remove('resolutionMode')
        ..remove('bindingRuntimeId')
        ..remove('scope'),
    );
  }
}

class GovernanceWhyKernelPayload {
  const GovernanceWhyKernelPayload({
    required this.justification,
    this.summaryVisibilityCoveragePct,
    this.governanceCoveragePct,
    this.breakGlassAuditCoveragePct,
    this.requiredSummaryVisibilityCoveragePct,
    this.requiredGovernanceCoveragePct,
    this.convictionTier,
    this.extra = const <String, dynamic>{},
  });

  final String justification;
  final double? summaryVisibilityCoveragePct;
  final double? governanceCoveragePct;
  final double? breakGlassAuditCoveragePct;
  final double? requiredSummaryVisibilityCoveragePct;
  final double? requiredGovernanceCoveragePct;
  final String? convictionTier;
  final Map<String, dynamic> extra;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'justification': justification,
        if (summaryVisibilityCoveragePct != null)
          'summaryVisibilityCoveragePct': summaryVisibilityCoveragePct,
        if (governanceCoveragePct != null)
          'governanceCoveragePct': governanceCoveragePct,
        if (breakGlassAuditCoveragePct != null)
          'breakGlassAuditCoveragePct': breakGlassAuditCoveragePct,
        if (requiredSummaryVisibilityCoveragePct != null)
          'requiredSummaryVisibilityCoveragePct':
              requiredSummaryVisibilityCoveragePct,
        if (requiredGovernanceCoveragePct != null)
          'requiredGovernanceCoveragePct': requiredGovernanceCoveragePct,
        if (convictionTier != null) 'convictionTier': convictionTier,
        ...extra,
      };

  factory GovernanceWhyKernelPayload.fromJson(Map<String, dynamic> json) {
    return GovernanceWhyKernelPayload(
      justification: json['justification'] as String? ?? '',
      summaryVisibilityCoveragePct:
          (json['summaryVisibilityCoveragePct'] as num?)?.toDouble(),
      governanceCoveragePct:
          (json['governanceCoveragePct'] as num?)?.toDouble(),
      breakGlassAuditCoveragePct:
          (json['breakGlassAuditCoveragePct'] as num?)?.toDouble(),
      requiredSummaryVisibilityCoveragePct:
          (json['requiredSummaryVisibilityCoveragePct'] as num?)?.toDouble(),
      requiredGovernanceCoveragePct:
          (json['requiredGovernanceCoveragePct'] as num?)?.toDouble(),
      convictionTier: json['convictionTier'] as String?,
      extra: Map<String, dynamic>.from(json)
        ..remove('justification')
        ..remove('summaryVisibilityCoveragePct')
        ..remove('governanceCoveragePct')
        ..remove('breakGlassAuditCoveragePct')
        ..remove('requiredSummaryVisibilityCoveragePct')
        ..remove('requiredGovernanceCoveragePct')
        ..remove('convictionTier'),
    );
  }
}

class GovernanceHowKernelPayload {
  const GovernanceHowKernelPayload({
    required this.visibilityTier,
    required this.inspectionPath,
    required this.auditMode,
    required this.resolutionMode,
    required this.failClosedOnPolicyViolation,
    this.governanceChannel,
    this.extra = const <String, dynamic>{},
  });

  final String visibilityTier;
  final String inspectionPath;
  final String auditMode;
  final String resolutionMode;
  final bool failClosedOnPolicyViolation;
  final String? governanceChannel;
  final Map<String, dynamic> extra;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'visibilityTier': visibilityTier,
        'inspectionPath': inspectionPath,
        'auditMode': auditMode,
        'resolutionMode': resolutionMode,
        'failClosedOnPolicyViolation': failClosedOnPolicyViolation,
        if (governanceChannel != null) 'governanceChannel': governanceChannel,
        ...extra,
      };

  factory GovernanceHowKernelPayload.fromJson(Map<String, dynamic> json) {
    return GovernanceHowKernelPayload(
      visibilityTier: json['visibilityTier'] as String? ?? '',
      inspectionPath: json['inspectionPath'] as String? ?? '',
      auditMode: json['auditMode'] as String? ?? '',
      resolutionMode: json['resolutionMode'] as String? ?? '',
      failClosedOnPolicyViolation:
          json['failClosedOnPolicyViolation'] as bool? ?? false,
      governanceChannel: json['governanceChannel'] as String?,
      extra: Map<String, dynamic>.from(json)
        ..remove('visibilityTier')
        ..remove('inspectionPath')
        ..remove('auditMode')
        ..remove('resolutionMode')
        ..remove('failClosedOnPolicyViolation')
        ..remove('governanceChannel'),
    );
  }
}

class GovernanceInspectionPolicyState {
  const GovernanceInspectionPolicyState({
    this.maxUnauditedBreakGlassInspections,
    this.maxHiddenInspectionPaths,
    this.observedUnauditedBreakGlassInspections,
    this.observedHiddenInspectionPaths,
    this.mode,
    this.extra = const <String, dynamic>{},
  });

  final int? maxUnauditedBreakGlassInspections;
  final int? maxHiddenInspectionPaths;
  final int? observedUnauditedBreakGlassInspections;
  final int? observedHiddenInspectionPaths;
  final String? mode;
  final Map<String, dynamic> extra;

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (maxUnauditedBreakGlassInspections != null)
          'maxUnauditedBreakGlassInspections':
              maxUnauditedBreakGlassInspections,
        if (maxHiddenInspectionPaths != null)
          'maxHiddenInspectionPaths': maxHiddenInspectionPaths,
        if (observedUnauditedBreakGlassInspections != null)
          'observedUnauditedBreakGlassInspections':
              observedUnauditedBreakGlassInspections,
        if (observedHiddenInspectionPaths != null)
          'observedHiddenInspectionPaths': observedHiddenInspectionPaths,
        if (mode != null) 'mode': mode,
        ...extra,
      };

  factory GovernanceInspectionPolicyState.fromJson(Map<String, dynamic> json) {
    return GovernanceInspectionPolicyState(
      maxUnauditedBreakGlassInspections:
          (json['maxUnauditedBreakGlassInspections'] as num?)?.toInt(),
      maxHiddenInspectionPaths:
          (json['maxHiddenInspectionPaths'] as num?)?.toInt(),
      observedUnauditedBreakGlassInspections:
          (json['observedUnauditedBreakGlassInspections'] as num?)?.toInt(),
      observedHiddenInspectionPaths:
          (json['observedHiddenInspectionPaths'] as num?)?.toInt(),
      mode: json['mode'] as String?,
      extra: Map<String, dynamic>.from(json)
        ..remove('maxUnauditedBreakGlassInspections')
        ..remove('maxHiddenInspectionPaths')
        ..remove('observedUnauditedBreakGlassInspections')
        ..remove('observedHiddenInspectionPaths')
        ..remove('mode'),
    );
  }

  GovernanceInspectionPolicyState merge(
    GovernanceInspectionPolicyState override,
  ) {
    return GovernanceInspectionPolicyState(
      maxUnauditedBreakGlassInspections:
          override.maxUnauditedBreakGlassInspections ??
              maxUnauditedBreakGlassInspections,
      maxHiddenInspectionPaths:
          override.maxHiddenInspectionPaths ?? maxHiddenInspectionPaths,
      observedUnauditedBreakGlassInspections:
          override.observedUnauditedBreakGlassInspections ??
              observedUnauditedBreakGlassInspections,
      observedHiddenInspectionPaths: override.observedHiddenInspectionPaths ??
          observedHiddenInspectionPaths,
      mode: override.mode ?? mode,
      extra: <String, dynamic>{
        ...extra,
        ...override.extra,
      },
    );
  }
}

class GovernanceInspectionProvenanceEntry {
  const GovernanceInspectionProvenanceEntry({
    required this.kind,
    required this.reference,
    this.subject,
    this.extra = const <String, dynamic>{},
  });

  final String kind;
  final String reference;
  final String? subject;
  final Map<String, dynamic> extra;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'kind': kind,
        'reference': reference,
        if (subject != null) 'subject': subject,
        ...extra,
      };

  factory GovernanceInspectionProvenanceEntry.fromJson(
    Map<String, dynamic> json,
  ) {
    return GovernanceInspectionProvenanceEntry(
      kind: json['kind'] as String? ?? '',
      reference: json['reference'] as String? ?? '',
      subject: json['subject'] as String?,
      extra: Map<String, dynamic>.from(json)
        ..remove('kind')
        ..remove('reference')
        ..remove('subject'),
    );
  }
}

class GovernanceInspectionRequest {
  GovernanceInspectionRequest({
    required this.requestId,
    required this.actorId,
    required this.targetRuntimeId,
    required this.targetStratum,
    required this.visibilityTier,
    required this.justification,
    required this.requestedAt,
    required this.isHumanActor,
  });

  final String requestId;
  final String actorId;
  final String targetRuntimeId;
  final GovernanceStratum targetStratum;
  final GovernanceVisibilityTier visibilityTier;
  final String justification;
  final AtomicTimestamp requestedAt;
  final bool isHumanActor;

  Map<String, dynamic> toJson() {
    return {
      'requestId': requestId,
      'actorId': actorId,
      'targetRuntimeId': targetRuntimeId,
      'targetStratum': targetStratum.name,
      'visibilityTier': visibilityTier.name,
      'justification': justification,
      'requestedAt': requestedAt.toJson(),
      'isHumanActor': isHumanActor,
    };
  }

  factory GovernanceInspectionRequest.fromJson(Map<String, dynamic> json) {
    return GovernanceInspectionRequest(
      requestId: json['requestId'] as String,
      actorId: json['actorId'] as String,
      targetRuntimeId: json['targetRuntimeId'] as String,
      targetStratum: GovernanceStratum.values.firstWhere(
        (value) => value.name == json['targetStratum'],
      ),
      visibilityTier: GovernanceVisibilityTier.values.firstWhere(
        (value) => value.name == json['visibilityTier'],
      ),
      justification: json['justification'] as String,
      requestedAt:
          AtomicTimestamp.fromJson(json['requestedAt'] as Map<String, dynamic>),
      isHumanActor: json['isHumanActor'] as bool,
    );
  }
}

class GovernanceInspectionPayload {
  GovernanceInspectionPayload({
    this.contractVersion = currentContractVersion,
    required this.whoKernel,
    required this.whatKernel,
    required this.whenKernel,
    required this.whereKernel,
    required this.whyKernel,
    required this.howKernel,
    required this.policyState,
    required this.provenance,
  });

  static const int currentContractVersion = 1;

  final int contractVersion;
  final GovernanceWhoKernelPayload whoKernel;
  final GovernanceWhatKernelPayload whatKernel;
  final GovernanceWhenKernelPayload whenKernel;
  final GovernanceWhereKernelPayload whereKernel;
  final GovernanceWhyKernelPayload whyKernel;
  final GovernanceHowKernelPayload howKernel;
  final GovernanceInspectionPolicyState policyState;
  final List<GovernanceInspectionProvenanceEntry> provenance;

  Map<String, dynamic> toJson() {
    return {
      'contractVersion': contractVersion,
      'whoKernel': whoKernel.toJson(),
      'whatKernel': whatKernel.toJson(),
      'whenKernel': whenKernel.toJson(),
      'whereKernel': whereKernel.toJson(),
      'whyKernel': whyKernel.toJson(),
      'howKernel': howKernel.toJson(),
      'policyState': policyState.toJson(),
      'provenance':
          provenance.map((entry) => entry.toJson()).toList(growable: false),
    };
  }

  factory GovernanceInspectionPayload.fromJson(Map<String, dynamic> json) {
    return GovernanceInspectionPayload(
      contractVersion:
          (json['contractVersion'] as num?)?.toInt() ?? currentContractVersion,
      whoKernel: GovernanceWhoKernelPayload.fromJson(
        Map<String, dynamic>.from(json['whoKernel'] as Map? ?? const {}),
      ),
      whatKernel: GovernanceWhatKernelPayload.fromJson(
        Map<String, dynamic>.from(json['whatKernel'] as Map? ?? const {}),
      ),
      whenKernel: GovernanceWhenKernelPayload.fromJson(
        Map<String, dynamic>.from(json['whenKernel'] as Map? ?? const {}),
      ),
      whereKernel: GovernanceWhereKernelPayload.fromJson(
        Map<String, dynamic>.from(json['whereKernel'] as Map? ?? const {}),
      ),
      whyKernel: GovernanceWhyKernelPayload.fromJson(
        Map<String, dynamic>.from(json['whyKernel'] as Map? ?? const {}),
      ),
      howKernel: GovernanceHowKernelPayload.fromJson(
        Map<String, dynamic>.from(json['howKernel'] as Map? ?? const {}),
      ),
      policyState: GovernanceInspectionPolicyState.fromJson(
        Map<String, dynamic>.from(json['policyState'] as Map? ?? const {}),
      ),
      provenance: ((json['provenance'] as List?) ?? const <dynamic>[])
          .whereType<Map>()
          .map((entry) => GovernanceInspectionProvenanceEntry.fromJson(
                Map<String, dynamic>.from(entry),
              ))
          .toList(growable: false),
    );
  }
}

class GovernanceInspectionResponse {
  GovernanceInspectionResponse({
    required this.request,
    required this.approved,
    required this.auditRef,
    required this.respondedAt,
    required this.failureCodes,
    this.payload,
  });

  final GovernanceInspectionRequest request;
  final bool approved;
  final String auditRef;
  final AtomicTimestamp respondedAt;
  final List<String> failureCodes;
  final GovernanceInspectionPayload? payload;

  Map<String, dynamic> toJson() {
    return {
      'request': request.toJson(),
      'approved': approved,
      'auditRef': auditRef,
      'respondedAt': respondedAt.toJson(),
      'failureCodes': failureCodes,
      'payload': payload?.toJson(),
    };
  }

  factory GovernanceInspectionResponse.fromJson(Map<String, dynamic> json) {
    return GovernanceInspectionResponse(
      request: GovernanceInspectionRequest.fromJson(
        json['request'] as Map<String, dynamic>,
      ),
      approved: json['approved'] as bool,
      auditRef: json['auditRef'] as String,
      respondedAt:
          AtomicTimestamp.fromJson(json['respondedAt'] as Map<String, dynamic>),
      failureCodes: List<String>.from(json['failureCodes'] as List<dynamic>),
      payload: json['payload'] == null
          ? null
          : GovernanceInspectionPayload.fromJson(
              json['payload'] as Map<String, dynamic>,
            ),
    );
  }
}
