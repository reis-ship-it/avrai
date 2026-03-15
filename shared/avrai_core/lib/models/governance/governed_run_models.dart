import 'package:avrai_core/models/research/governed_autoresearch_models.dart';
import 'package:avrai_core/models/truth/truth_scope_descriptor.dart';

enum GovernedRunKind {
  autoresearch,
  securityRedteam,
  selfHeal,
}

enum GovernedRunEnvironment {
  sandbox,
  replay,
  shadow,
  canary,
  productionControlled,
}

enum GovernedRunDisposition {
  observe,
  boundedDegrade,
  hardStop,
}

enum GovernedRunDirectiveKind {
  approveCharter,
  queueRun,
  startRun,
  pauseRun,
  resumeRun,
  stopRun,
  redirectRun,
  checkpointRun,
  triggerKillSwitch,
  boundedDegrade,
  hardStop,
  observe,
}

enum GovernedRunLifecycleState {
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

class GovernedRunBudget {
  const GovernedRunBudget({
    required this.maxRuntime,
    required this.maxStepCount,
    required this.maxToolInvocations,
    required this.maxEgressRequests,
    required this.maxParallelWorkers,
    this.metadata = const <String, dynamic>{},
  });

  final Duration maxRuntime;
  final int maxStepCount;
  final int maxToolInvocations;
  final int maxEgressRequests;
  final int maxParallelWorkers;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'maxRuntimeMs': maxRuntime.inMilliseconds,
        'maxStepCount': maxStepCount,
        'maxToolInvocations': maxToolInvocations,
        'maxEgressRequests': maxEgressRequests,
        'maxParallelWorkers': maxParallelWorkers,
        'metadata': metadata,
      };

  factory GovernedRunBudget.fromJson(Map<String, dynamic> json) {
    return GovernedRunBudget(
      maxRuntime: Duration(
        milliseconds: (json['maxRuntimeMs'] as num?)?.toInt() ?? 0,
      ),
      maxStepCount: (json['maxStepCount'] as num?)?.toInt() ?? 0,
      maxToolInvocations: (json['maxToolInvocations'] as num?)?.toInt() ?? 0,
      maxEgressRequests: (json['maxEgressRequests'] as num?)?.toInt() ?? 0,
      maxParallelWorkers: (json['maxParallelWorkers'] as num?)?.toInt() ?? 1,
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}

class GovernedRunCharter {
  const GovernedRunCharter({
    required this.id,
    required this.runKind,
    required this.title,
    required this.objective,
    required this.hypothesis,
    required this.truthScope,
    required this.authorityToken,
    required this.environment,
    required this.allowedExperimentSurfaces,
    required this.successMetrics,
    required this.stopConditions,
    required this.hardBans,
    required this.killConditions,
    required this.rollbackRefs,
    required this.createdAt,
    required this.updatedAt,
    this.budget,
    this.approvedBy,
    this.approvedAt,
  });

  final String id;
  final GovernedRunKind runKind;
  final String title;
  final String objective;
  final String hypothesis;
  final TruthScopeDescriptor truthScope;
  final String authorityToken;
  final GovernedRunEnvironment environment;
  final List<String> allowedExperimentSurfaces;
  final List<String> successMetrics;
  final List<String> stopConditions;
  final List<String> hardBans;
  final List<String> killConditions;
  final List<String> rollbackRefs;
  final GovernedRunBudget? budget;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? approvedBy;
  final DateTime? approvedAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'runKind': runKind.name,
        'title': title,
        'objective': objective,
        'hypothesis': hypothesis,
        'truthScope': truthScope.toJson(),
        'authorityToken': authorityToken,
        'environment': environment.name,
        'allowedExperimentSurfaces': allowedExperimentSurfaces,
        'successMetrics': successMetrics,
        'stopConditions': stopConditions,
        'hardBans': hardBans,
        'killConditions': killConditions,
        'rollbackRefs': rollbackRefs,
        'budget': budget?.toJson(),
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
        'approvedBy': approvedBy,
        'approvedAt': approvedAt?.toUtc().toIso8601String(),
      };

  factory GovernedRunCharter.fromJson(Map<String, dynamic> json) {
    return GovernedRunCharter(
      id: json['id']?.toString() ?? '',
      runKind: GovernedRunKind.values.firstWhere(
        (value) => value.name == json['runKind'],
        orElse: () => GovernedRunKind.autoresearch,
      ),
      title: json['title']?.toString() ?? '',
      objective: json['objective']?.toString() ?? '',
      hypothesis: json['hypothesis']?.toString() ?? '',
      truthScope: TruthScopeDescriptor.fromJson(
        Map<String, dynamic>.from(
          json['truthScope'] as Map? ?? const <String, dynamic>{},
        ),
      ),
      authorityToken: json['authorityToken']?.toString() ?? 'unknown',
      environment: GovernedRunEnvironment.values.firstWhere(
        (value) => value.name == json['environment'],
        orElse: () => GovernedRunEnvironment.sandbox,
      ),
      allowedExperimentSurfaces: _stringList(
        json['allowedExperimentSurfaces'],
      ),
      successMetrics: _stringList(json['successMetrics']),
      stopConditions: _stringList(json['stopConditions']),
      hardBans: _stringList(json['hardBans']),
      killConditions: _stringList(json['killConditions']),
      rollbackRefs: _stringList(json['rollbackRefs']),
      budget: json['budget'] is Map
          ? GovernedRunBudget.fromJson(
              Map<String, dynamic>.from(json['budget'] as Map),
            )
          : null,
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
      approvedBy: json['approvedBy']?.toString(),
      approvedAt: _parseNullableDateTime(json['approvedAt']),
    );
  }
}

class GovernedRunCheckpoint {
  const GovernedRunCheckpoint({
    required this.id,
    required this.runId,
    required this.summary,
    required this.state,
    required this.createdAt,
    required this.metricSnapshot,
    required this.artifactIds,
    required this.requiresHumanReview,
    required this.contradictionDetected,
    required this.disposition,
  });

  final String id;
  final String runId;
  final String summary;
  final GovernedRunLifecycleState state;
  final DateTime createdAt;
  final Map<String, double> metricSnapshot;
  final List<String> artifactIds;
  final bool requiresHumanReview;
  final bool contradictionDetected;
  final GovernedRunDisposition disposition;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'runId': runId,
        'summary': summary,
        'state': state.name,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'metricSnapshot': metricSnapshot,
        'artifactIds': artifactIds,
        'requiresHumanReview': requiresHumanReview,
        'contradictionDetected': contradictionDetected,
        'disposition': disposition.name,
      };

  factory GovernedRunCheckpoint.fromJson(Map<String, dynamic> json) {
    return GovernedRunCheckpoint(
      id: json['id']?.toString() ?? '',
      runId: json['runId']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      state: GovernedRunLifecycleState.values.firstWhere(
        (value) => value.name == json['state'],
        orElse: () => GovernedRunLifecycleState.draft,
      ),
      createdAt: _parseDateTime(json['createdAt']),
      metricSnapshot: _doubleMap(json['metricSnapshot']),
      artifactIds: _stringList(json['artifactIds']),
      requiresHumanReview: json['requiresHumanReview'] as bool? ?? false,
      contradictionDetected: json['contradictionDetected'] as bool? ?? false,
      disposition: GovernedRunDisposition.values.firstWhere(
        (value) => value.name == json['disposition'],
        orElse: () => GovernedRunDisposition.observe,
      ),
    );
  }
}

class GovernedRunDirective {
  const GovernedRunDirective({
    required this.id,
    required this.runId,
    required this.kind,
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
  final GovernedRunDirectiveKind kind;
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
        'kind': kind.name,
        'actorAlias': actorAlias,
        'rationale': rationale,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'modelVersion': modelVersion,
        'policyVersion': policyVersion,
        'details': details,
        'checkpointId': checkpointId,
      };

  factory GovernedRunDirective.fromJson(Map<String, dynamic> json) {
    return GovernedRunDirective(
      id: json['id']?.toString() ?? '',
      runId: json['runId']?.toString() ?? '',
      kind: GovernedRunDirectiveKind.values.firstWhere(
        (value) => value.name == json['kind'],
        orElse: () => GovernedRunDirectiveKind.observe,
      ),
      actorAlias: json['actorAlias']?.toString() ?? 'unknown_actor',
      rationale: json['rationale']?.toString() ?? '',
      createdAt: _parseDateTime(json['createdAt']),
      modelVersion: json['modelVersion']?.toString() ?? 'unknown',
      policyVersion: json['policyVersion']?.toString() ?? 'unknown',
      details: Map<String, dynamic>.from(
        json['details'] as Map? ?? const <String, dynamic>{},
      ),
      checkpointId: json['checkpointId']?.toString(),
    );
  }
}

class GovernedRunEvidence {
  const GovernedRunEvidence({
    required this.id,
    required this.runId,
    required this.truthScope,
    required this.evidenceClass,
    required this.summary,
    required this.createdAt,
    required this.artifactRefs,
    required this.isRedacted,
    this.metadata = const <String, dynamic>{},
  });

  final String id;
  final String runId;
  final TruthScopeDescriptor truthScope;
  final String evidenceClass;
  final String summary;
  final DateTime createdAt;
  final List<String> artifactRefs;
  final bool isRedacted;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'runId': runId,
        'truthScope': truthScope.toJson(),
        'evidenceClass': evidenceClass,
        'summary': summary,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'artifactRefs': artifactRefs,
        'isRedacted': isRedacted,
        'metadata': metadata,
      };

  factory GovernedRunEvidence.fromJson(Map<String, dynamic> json) {
    return GovernedRunEvidence(
      id: json['id']?.toString() ?? '',
      runId: json['runId']?.toString() ?? '',
      truthScope: TruthScopeDescriptor.fromJson(
        Map<String, dynamic>.from(
          json['truthScope'] as Map? ?? const <String, dynamic>{},
        ),
      ),
      evidenceClass: json['evidenceClass']?.toString() ?? 'evidence',
      summary: json['summary']?.toString() ?? '',
      createdAt: _parseDateTime(json['createdAt']),
      artifactRefs: _stringList(json['artifactRefs']),
      isRedacted: json['isRedacted'] as bool? ?? true,
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}

class GovernedRunRecord {
  const GovernedRunRecord({
    required this.id,
    required this.title,
    required this.hypothesis,
    required this.runKind,
    required this.ownerAgentAlias,
    required this.lifecycleState,
    required this.environment,
    required this.disposition,
    required this.truthScope,
    required this.authorityToken,
    required this.charter,
    required this.requiresAdminApproval,
    required this.sandboxOnly,
    required this.modelVersion,
    required this.policyVersion,
    required this.metrics,
    required this.tags,
    required this.directives,
    required this.checkpoints,
    required this.createdAt,
    required this.updatedAt,
    this.lastHeartbeatAt,
    this.latestSummary,
    this.redirectDirective,
    this.killSwitchActive = false,
    this.contradictionDetected = false,
    this.pendingApprovalCount = 0,
    this.approvedApprovalCount = 0,
    this.alertCount = 0,
    this.artifactCount = 0,
    this.metadata = const <String, dynamic>{},
  });

  final String id;
  final String title;
  final String hypothesis;
  final GovernedRunKind runKind;
  final String ownerAgentAlias;
  final GovernedRunLifecycleState lifecycleState;
  final GovernedRunEnvironment environment;
  final GovernedRunDisposition disposition;
  final TruthScopeDescriptor truthScope;
  final String authorityToken;
  final GovernedRunCharter charter;
  final bool requiresAdminApproval;
  final bool sandboxOnly;
  final String modelVersion;
  final String policyVersion;
  final Map<String, double> metrics;
  final List<String> tags;
  final List<GovernedRunDirective> directives;
  final List<GovernedRunCheckpoint> checkpoints;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastHeartbeatAt;
  final String? latestSummary;
  final String? redirectDirective;
  final bool killSwitchActive;
  final bool contradictionDetected;
  final int pendingApprovalCount;
  final int approvedApprovalCount;
  final int alertCount;
  final int artifactCount;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'hypothesis': hypothesis,
        'runKind': runKind.name,
        'ownerAgentAlias': ownerAgentAlias,
        'lifecycleState': lifecycleState.name,
        'environment': environment.name,
        'disposition': disposition.name,
        'truthScope': truthScope.toJson(),
        'authorityToken': authorityToken,
        'charter': charter.toJson(),
        'requiresAdminApproval': requiresAdminApproval,
        'sandboxOnly': sandboxOnly,
        'modelVersion': modelVersion,
        'policyVersion': policyVersion,
        'metrics': metrics,
        'tags': tags,
        'directives': directives.map((entry) => entry.toJson()).toList(),
        'checkpoints': checkpoints.map((entry) => entry.toJson()).toList(),
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
        'lastHeartbeatAt': lastHeartbeatAt?.toUtc().toIso8601String(),
        'latestSummary': latestSummary,
        'redirectDirective': redirectDirective,
        'killSwitchActive': killSwitchActive,
        'contradictionDetected': contradictionDetected,
        'pendingApprovalCount': pendingApprovalCount,
        'approvedApprovalCount': approvedApprovalCount,
        'alertCount': alertCount,
        'artifactCount': artifactCount,
        'metadata': metadata,
      };

  factory GovernedRunRecord.fromJson(Map<String, dynamic> json) {
    return GovernedRunRecord(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      hypothesis: json['hypothesis']?.toString() ?? '',
      runKind: GovernedRunKind.values.firstWhere(
        (value) => value.name == json['runKind'],
        orElse: () => GovernedRunKind.autoresearch,
      ),
      ownerAgentAlias: json['ownerAgentAlias']?.toString() ?? 'unknown_agent',
      lifecycleState: GovernedRunLifecycleState.values.firstWhere(
        (value) => value.name == json['lifecycleState'],
        orElse: () => GovernedRunLifecycleState.draft,
      ),
      environment: GovernedRunEnvironment.values.firstWhere(
        (value) => value.name == json['environment'],
        orElse: () => GovernedRunEnvironment.sandbox,
      ),
      disposition: GovernedRunDisposition.values.firstWhere(
        (value) => value.name == json['disposition'],
        orElse: () => GovernedRunDisposition.observe,
      ),
      truthScope: TruthScopeDescriptor.fromJson(
        Map<String, dynamic>.from(
          json['truthScope'] as Map? ?? const <String, dynamic>{},
        ),
      ),
      authorityToken: json['authorityToken']?.toString() ?? 'unknown',
      charter: GovernedRunCharter.fromJson(
        Map<String, dynamic>.from(
          json['charter'] as Map? ?? const <String, dynamic>{},
        ),
      ),
      requiresAdminApproval: json['requiresAdminApproval'] as bool? ?? true,
      sandboxOnly: json['sandboxOnly'] as bool? ?? true,
      modelVersion: json['modelVersion']?.toString() ?? 'unknown',
      policyVersion: json['policyVersion']?.toString() ?? 'unknown',
      metrics: _doubleMap(json['metrics']),
      tags: _stringList(json['tags']),
      directives: _listOfMaps(json['directives'])
          .map(GovernedRunDirective.fromJson)
          .toList(growable: false),
      checkpoints: _listOfMaps(json['checkpoints'])
          .map(GovernedRunCheckpoint.fromJson)
          .toList(growable: false),
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
      lastHeartbeatAt: _parseNullableDateTime(json['lastHeartbeatAt']),
      latestSummary: json['latestSummary']?.toString(),
      redirectDirective: json['redirectDirective']?.toString(),
      killSwitchActive: json['killSwitchActive'] as bool? ?? false,
      contradictionDetected: json['contradictionDetected'] as bool? ?? false,
      pendingApprovalCount:
          (json['pendingApprovalCount'] as num?)?.toInt() ?? 0,
      approvedApprovalCount:
          (json['approvedApprovalCount'] as num?)?.toInt() ?? 0,
      alertCount: (json['alertCount'] as num?)?.toInt() ?? 0,
      artifactCount: (json['artifactCount'] as num?)?.toInt() ?? 0,
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}

extension GovernedRunRecordFromResearch on ResearchRunState {
  GovernedRunRecord toGovernedRunRecord({
    TruthScopeDescriptor? truthScope,
    String authorityToken = 'autoresearch.supervised',
    GovernedRunEnvironment environment = GovernedRunEnvironment.sandbox,
    GovernedRunDisposition disposition = GovernedRunDisposition.observe,
  }) {
    final resolvedScope =
        truthScope ?? const TruthScopeDescriptor.defaultResearch();
    return GovernedRunRecord(
      id: id,
      title: title,
      hypothesis: hypothesis,
      runKind: GovernedRunKind.autoresearch,
      ownerAgentAlias: ownerAgentAlias,
      lifecycleState: _lifecycleFromResearch(lifecycleState),
      environment: environment,
      disposition: disposition,
      truthScope: resolvedScope,
      authorityToken: authorityToken,
      charter: GovernedRunCharter(
        id: charter.id,
        runKind: GovernedRunKind.autoresearch,
        title: charter.title,
        objective: charter.objective,
        hypothesis: charter.hypothesis,
        truthScope: resolvedScope,
        authorityToken: authorityToken,
        environment: environment,
        allowedExperimentSurfaces: charter.allowedExperimentSurfaces,
        successMetrics: charter.successMetrics,
        stopConditions: charter.stopConditions,
        hardBans: charter.hardBans,
        killConditions: charter.stopConditions,
        rollbackRefs: const <String>[],
        createdAt: charter.createdAt,
        updatedAt: charter.updatedAt,
        approvedBy: charter.approvedBy,
        approvedAt: charter.approvedAt,
      ),
      requiresAdminApproval: requiresAdminApproval,
      sandboxOnly: sandboxOnly,
      modelVersion: modelVersion,
      policyVersion: policyVersion,
      metrics: metrics,
      tags: tags,
      directives: controlActions
          .map(
            (action) => GovernedRunDirective(
              id: action.id,
              runId: action.runId,
              kind: _directiveFromResearch(action.actionType),
              actorAlias: action.actorAlias,
              rationale: action.rationale,
              createdAt: action.createdAt,
              modelVersion: action.modelVersion,
              policyVersion: action.policyVersion,
              details: action.details,
              checkpointId: action.checkpointId,
            ),
          )
          .toList(growable: false),
      checkpoints: checkpoints
          .map(
            (checkpoint) => GovernedRunCheckpoint(
              id: checkpoint.id,
              runId: checkpoint.runId,
              summary: checkpoint.summary,
              state: _lifecycleFromResearch(checkpoint.state),
              createdAt: checkpoint.createdAt,
              metricSnapshot: checkpoint.metricSnapshot,
              artifactIds: checkpoint.artifactIds,
              requiresHumanReview: checkpoint.requiresHumanReview,
              contradictionDetected: checkpoint.contradictionDetected,
              disposition: checkpoint.requiresHumanReview
                  ? GovernedRunDisposition.boundedDegrade
                  : disposition,
            ),
          )
          .toList(growable: false),
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastHeartbeatAt: lastHeartbeatAt,
      latestSummary:
          latestExplanation?.summary ?? latestSandboxProjection?.summary,
      redirectDirective: redirectDirective,
      killSwitchActive: killSwitchActive,
      contradictionDetected: contradictionDetected,
      pendingApprovalCount: approvals
          .where((entry) => entry.status == ResearchApprovalStatus.pending)
          .length,
      approvedApprovalCount: approvals
          .where((entry) => entry.status == ResearchApprovalStatus.approved)
          .length,
      alertCount: alerts.length,
      artifactCount: artifacts.length,
      metadata: <String, dynamic>{
        'researchLayer': layer.name,
        'visibilityScope': visibilityScope.name,
        'lane': lane.name,
        'egressMode': egressMode.name,
      },
    );
  }
}

List<String> _stringList(dynamic value) {
  if (value is List<dynamic>) {
    return value.map((item) => item.toString()).toList(growable: false);
  }
  return const <String>[];
}

List<Map<String, dynamic>> _listOfMaps(dynamic value) {
  if (value is List<dynamic>) {
    return value
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList(growable: false);
  }
  return const <Map<String, dynamic>>[];
}

Map<String, double> _doubleMap(dynamic value) {
  final parsed = <String, double>{};
  if (value is Map) {
    for (final entry in value.entries) {
      final numericValue = entry.value;
      if (numericValue is num) {
        parsed[entry.key.toString()] = numericValue.toDouble();
      }
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

GovernedRunLifecycleState _lifecycleFromResearch(
  ResearchRunLifecycleState state,
) {
  return GovernedRunLifecycleState.values.firstWhere(
    (value) => value.name == state.name,
    orElse: () => GovernedRunLifecycleState.draft,
  );
}

GovernedRunDirectiveKind _directiveFromResearch(
  ResearchControlActionType actionType,
) {
  return switch (actionType) {
    ResearchControlActionType.approveCharter =>
      GovernedRunDirectiveKind.approveCharter,
    ResearchControlActionType.queueRun => GovernedRunDirectiveKind.queueRun,
    ResearchControlActionType.pauseRun => GovernedRunDirectiveKind.pauseRun,
    ResearchControlActionType.resumeRun => GovernedRunDirectiveKind.resumeRun,
    ResearchControlActionType.stopRun => GovernedRunDirectiveKind.stopRun,
    ResearchControlActionType.redirectRun =>
      GovernedRunDirectiveKind.redirectRun,
    ResearchControlActionType.checkpointRun =>
      GovernedRunDirectiveKind.checkpointRun,
    ResearchControlActionType.triggerKillSwitch =>
      GovernedRunDirectiveKind.triggerKillSwitch,
    _ => GovernedRunDirectiveKind.observe,
  };
}
