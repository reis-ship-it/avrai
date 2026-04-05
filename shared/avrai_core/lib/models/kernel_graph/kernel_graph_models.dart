enum KernelGraphKind {
  learningIntake,
  governedRun,
  securityCampaign,
  autoresearch,
  adminProjection,
}

enum KernelGraphExecutionEnvironment {
  runtime,
  replay,
  shadow,
  canary,
  productionControlled,
}

enum KernelGraphDiagnosticSeverity {
  info,
  warning,
  error,
}

enum KernelGraphRunStatus {
  queued,
  running,
  completed,
  failed,
}

enum KernelGraphNodeStatus {
  pending,
  running,
  completed,
  failed,
}

class KernelGraphExecutionPolicy {
  const KernelGraphExecutionPolicy({
    required this.environment,
    this.simulationFirst = false,
    this.requiresHumanReview = false,
    this.maxStepCount,
    this.allowedMutableSurfaces = const <String>[],
    this.metadata = const <String, dynamic>{},
  });

  final KernelGraphExecutionEnvironment environment;
  final bool simulationFirst;
  final bool requiresHumanReview;
  final int? maxStepCount;
  final List<String> allowedMutableSurfaces;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'environment': environment.name,
        'simulationFirst': simulationFirst,
        'requiresHumanReview': requiresHumanReview,
        'maxStepCount': maxStepCount,
        'allowedMutableSurfaces': allowedMutableSurfaces,
        'metadata': metadata,
      };

  factory KernelGraphExecutionPolicy.fromJson(Map<String, dynamic> json) {
    return KernelGraphExecutionPolicy(
      environment: KernelGraphExecutionEnvironment.values.firstWhere(
        (value) => value.name == json['environment'],
        orElse: () => KernelGraphExecutionEnvironment.runtime,
      ),
      simulationFirst: json['simulationFirst'] as bool? ?? false,
      requiresHumanReview: json['requiresHumanReview'] as bool? ?? false,
      maxStepCount: (json['maxStepCount'] as num?)?.toInt(),
      allowedMutableSurfaces: _stringList(json['allowedMutableSurfaces']),
      metadata: _map(json['metadata']),
    );
  }
}

class KernelGraphNodeSpec {
  const KernelGraphNodeSpec({
    required this.id,
    required this.primitiveId,
    required this.label,
    this.config = const <String, dynamic>{},
    this.metadata = const <String, dynamic>{},
    this.required = true,
  });

  final String id;
  final String primitiveId;
  final String label;
  final Map<String, dynamic> config;
  final Map<String, dynamic> metadata;
  final bool required;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'primitiveId': primitiveId,
        'label': label,
        'config': config,
        'metadata': metadata,
        'required': required,
      };

  factory KernelGraphNodeSpec.fromJson(Map<String, dynamic> json) {
    return KernelGraphNodeSpec(
      id: json['id']?.toString() ?? '',
      primitiveId: json['primitiveId']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      config: _map(json['config']),
      metadata: _map(json['metadata']),
      required: json['required'] as bool? ?? true,
    );
  }
}

class KernelGraphEdgeSpec {
  const KernelGraphEdgeSpec({
    required this.fromNodeId,
    required this.toNodeId,
    this.label,
    this.metadata = const <String, dynamic>{},
  });

  final String fromNodeId;
  final String toNodeId;
  final String? label;
  final Map<String, dynamic> metadata;

  String get ref => '$fromNodeId->$toNodeId';

  Map<String, dynamic> toJson() => <String, dynamic>{
        'fromNodeId': fromNodeId,
        'toNodeId': toNodeId,
        'label': label,
        'metadata': metadata,
      };

  factory KernelGraphEdgeSpec.fromJson(Map<String, dynamic> json) {
    return KernelGraphEdgeSpec(
      fromNodeId: json['fromNodeId']?.toString() ?? '',
      toNodeId: json['toNodeId']?.toString() ?? '',
      label: json['label']?.toString(),
      metadata: _map(json['metadata']),
    );
  }
}

class KernelGraphSpec {
  const KernelGraphSpec({
    required this.id,
    required this.title,
    required this.kind,
    required this.version,
    required this.nodes,
    required this.edges,
    required this.executionPolicy,
    this.metadata = const <String, dynamic>{},
  });

  final String id;
  final String title;
  final KernelGraphKind kind;
  final String version;
  final List<KernelGraphNodeSpec> nodes;
  final List<KernelGraphEdgeSpec> edges;
  final KernelGraphExecutionPolicy executionPolicy;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'kind': kind.name,
        'version': version,
        'nodes': nodes.map((entry) => entry.toJson()).toList(growable: false),
        'edges': edges.map((entry) => entry.toJson()).toList(growable: false),
        'executionPolicy': executionPolicy.toJson(),
        'metadata': metadata,
      };

  factory KernelGraphSpec.fromJson(Map<String, dynamic> json) {
    return KernelGraphSpec(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      kind: KernelGraphKind.values.firstWhere(
        (value) => value.name == json['kind'],
        orElse: () => KernelGraphKind.learningIntake,
      ),
      version: json['version']?.toString() ?? '0.1',
      nodes: _list(json['nodes'])
          .map(KernelGraphNodeSpec.fromJson)
          .toList(growable: false),
      edges: _list(json['edges'])
          .map(KernelGraphEdgeSpec.fromJson)
          .toList(growable: false),
      executionPolicy: KernelGraphExecutionPolicy.fromJson(
        _map(json['executionPolicy']),
      ),
      metadata: _map(json['metadata']),
    );
  }
}

class KernelGraphCompilationDiagnostic {
  const KernelGraphCompilationDiagnostic({
    required this.severity,
    required this.code,
    required this.message,
    this.nodeId,
    this.edgeRef,
  });

  final KernelGraphDiagnosticSeverity severity;
  final String code;
  final String message;
  final String? nodeId;
  final String? edgeRef;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'severity': severity.name,
        'code': code,
        'message': message,
        'nodeId': nodeId,
        'edgeRef': edgeRef,
      };

  factory KernelGraphCompilationDiagnostic.fromJson(
    Map<String, dynamic> json,
  ) {
    return KernelGraphCompilationDiagnostic(
      severity: KernelGraphDiagnosticSeverity.values.firstWhere(
        (value) => value.name == json['severity'],
        orElse: () => KernelGraphDiagnosticSeverity.error,
      ),
      code: json['code']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      nodeId: json['nodeId']?.toString(),
      edgeRef: json['edgeRef']?.toString(),
    );
  }
}

class KernelGraphCompiledStep {
  const KernelGraphCompiledStep({
    required this.nodeId,
    required this.primitiveId,
    required this.label,
    required this.order,
    this.config = const <String, dynamic>{},
    this.metadata = const <String, dynamic>{},
  });

  final String nodeId;
  final String primitiveId;
  final String label;
  final int order;
  final Map<String, dynamic> config;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'nodeId': nodeId,
        'primitiveId': primitiveId,
        'label': label,
        'order': order,
        'config': config,
        'metadata': metadata,
      };

  factory KernelGraphCompiledStep.fromJson(Map<String, dynamic> json) {
    return KernelGraphCompiledStep(
      nodeId: json['nodeId']?.toString() ?? '',
      primitiveId: json['primitiveId']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      order: (json['order'] as num?)?.toInt() ?? 0,
      config: _map(json['config']),
      metadata: _map(json['metadata']),
    );
  }
}

class KernelGraphCompiledPlan {
  const KernelGraphCompiledPlan({
    required this.specId,
    required this.title,
    required this.kind,
    required this.version,
    required this.steps,
    required this.executionPolicy,
    this.metadata = const <String, dynamic>{},
  });

  final String specId;
  final String title;
  final KernelGraphKind kind;
  final String version;
  final List<KernelGraphCompiledStep> steps;
  final KernelGraphExecutionPolicy executionPolicy;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'specId': specId,
        'title': title,
        'kind': kind.name,
        'version': version,
        'steps': steps.map((entry) => entry.toJson()).toList(growable: false),
        'executionPolicy': executionPolicy.toJson(),
        'metadata': metadata,
      };

  factory KernelGraphCompiledPlan.fromJson(Map<String, dynamic> json) {
    return KernelGraphCompiledPlan(
      specId: json['specId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      kind: KernelGraphKind.values.firstWhere(
        (value) => value.name == json['kind'],
        orElse: () => KernelGraphKind.learningIntake,
      ),
      version: json['version']?.toString() ?? '0.1',
      steps: _list(json['steps'])
          .map(KernelGraphCompiledStep.fromJson)
          .toList(growable: false),
      executionPolicy: KernelGraphExecutionPolicy.fromJson(
        _map(json['executionPolicy']),
      ),
      metadata: _map(json['metadata']),
    );
  }
}

class KernelGraphCompilationResult {
  const KernelGraphCompilationResult({
    required this.isValid,
    required this.diagnostics,
    this.compiledPlan,
  });

  final bool isValid;
  final List<KernelGraphCompilationDiagnostic> diagnostics;
  final KernelGraphCompiledPlan? compiledPlan;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'isValid': isValid,
        'diagnostics':
            diagnostics.map((entry) => entry.toJson()).toList(growable: false),
        'compiledPlan': compiledPlan?.toJson(),
      };

  factory KernelGraphCompilationResult.fromJson(Map<String, dynamic> json) {
    return KernelGraphCompilationResult(
      isValid: json['isValid'] as bool? ?? false,
      diagnostics: _list(json['diagnostics'])
          .map(KernelGraphCompilationDiagnostic.fromJson)
          .toList(growable: false),
      compiledPlan: json['compiledPlan'] is Map
          ? KernelGraphCompiledPlan.fromJson(
              Map<String, dynamic>.from(json['compiledPlan'] as Map),
            )
          : null,
    );
  }
}

class KernelGraphRollbackDescriptor {
  const KernelGraphRollbackDescriptor({
    required this.id,
    required this.strategy,
    this.refs = const <String>[],
    this.metadata = const <String, dynamic>{},
  });

  final String id;
  final String strategy;
  final List<String> refs;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'strategy': strategy,
        'refs': refs,
        'metadata': metadata,
      };

  factory KernelGraphRollbackDescriptor.fromJson(Map<String, dynamic> json) {
    return KernelGraphRollbackDescriptor(
      id: json['id']?.toString() ?? '',
      strategy: json['strategy']?.toString() ?? '',
      refs: _stringList(json['refs']),
      metadata: _map(json['metadata']),
    );
  }
}

class KernelGraphNodeReceipt {
  const KernelGraphNodeReceipt({
    required this.nodeId,
    required this.primitiveId,
    required this.status,
    required this.startedAt,
    required this.completedAt,
    required this.summary,
    this.outputRefs = const <String>[],
    this.metadata = const <String, dynamic>{},
  });

  final String nodeId;
  final String primitiveId;
  final KernelGraphNodeStatus status;
  final DateTime startedAt;
  final DateTime completedAt;
  final String summary;
  final List<String> outputRefs;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'nodeId': nodeId,
        'primitiveId': primitiveId,
        'status': status.name,
        'startedAt': startedAt.toUtc().toIso8601String(),
        'completedAt': completedAt.toUtc().toIso8601String(),
        'summary': summary,
        'outputRefs': outputRefs,
        'metadata': metadata,
      };

  factory KernelGraphNodeReceipt.fromJson(Map<String, dynamic> json) {
    return KernelGraphNodeReceipt(
      nodeId: json['nodeId']?.toString() ?? '',
      primitiveId: json['primitiveId']?.toString() ?? '',
      status: KernelGraphNodeStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => KernelGraphNodeStatus.failed,
      ),
      startedAt: _parseDateTime(json['startedAt']),
      completedAt: _parseDateTime(json['completedAt']),
      summary: json['summary']?.toString() ?? '',
      outputRefs: _stringList(json['outputRefs']),
      metadata: _map(json['metadata']),
    );
  }
}

class KernelGraphExecutionReceipt {
  const KernelGraphExecutionReceipt({
    required this.runId,
    required this.specId,
    required this.title,
    required this.kind,
    required this.status,
    required this.startedAt,
    this.completedAt,
    this.nodeReceipts = const <KernelGraphNodeReceipt>[],
    this.rollbackDescriptor,
    this.metadata = const <String, dynamic>{},
  });

  final String runId;
  final String specId;
  final String title;
  final KernelGraphKind kind;
  final KernelGraphRunStatus status;
  final DateTime startedAt;
  final DateTime? completedAt;
  final List<KernelGraphNodeReceipt> nodeReceipts;
  final KernelGraphRollbackDescriptor? rollbackDescriptor;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'runId': runId,
        'specId': specId,
        'title': title,
        'kind': kind.name,
        'status': status.name,
        'startedAt': startedAt.toUtc().toIso8601String(),
        'completedAt': completedAt?.toUtc().toIso8601String(),
        'nodeReceipts':
            nodeReceipts.map((entry) => entry.toJson()).toList(growable: false),
        'rollbackDescriptor': rollbackDescriptor?.toJson(),
        'metadata': metadata,
      };

  factory KernelGraphExecutionReceipt.fromJson(Map<String, dynamic> json) {
    return KernelGraphExecutionReceipt(
      runId: json['runId']?.toString() ?? '',
      specId: json['specId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      kind: KernelGraphKind.values.firstWhere(
        (value) => value.name == json['kind'],
        orElse: () => KernelGraphKind.learningIntake,
      ),
      status: KernelGraphRunStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => KernelGraphRunStatus.failed,
      ),
      startedAt: _parseDateTime(json['startedAt']),
      completedAt: _parseNullableDateTime(json['completedAt']),
      nodeReceipts: _list(json['nodeReceipts'])
          .map(KernelGraphNodeReceipt.fromJson)
          .toList(growable: false),
      rollbackDescriptor: json['rollbackDescriptor'] is Map
          ? KernelGraphRollbackDescriptor.fromJson(
              Map<String, dynamic>.from(json['rollbackDescriptor'] as Map),
            )
          : null,
      metadata: _map(json['metadata']),
    );
  }
}

class KernelGraphAdminDigest {
  const KernelGraphAdminDigest({
    required this.runId,
    required this.specId,
    required this.graphTitle,
    required this.kind,
    required this.status,
    required this.summary,
    required this.requiresHumanReview,
    required this.completedNodeCount,
    required this.totalNodeCount,
    this.activeNodeId,
    this.lineageRefs = const <String>[],
    this.rollbackRefs = const <String>[],
    this.metadata = const <String, dynamic>{},
  });

  final String runId;
  final String specId;
  final String graphTitle;
  final KernelGraphKind kind;
  final KernelGraphRunStatus status;
  final String summary;
  final bool requiresHumanReview;
  final int completedNodeCount;
  final int totalNodeCount;
  final String? activeNodeId;
  final List<String> lineageRefs;
  final List<String> rollbackRefs;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'runId': runId,
        'specId': specId,
        'graphTitle': graphTitle,
        'kind': kind.name,
        'status': status.name,
        'summary': summary,
        'requiresHumanReview': requiresHumanReview,
        'completedNodeCount': completedNodeCount,
        'totalNodeCount': totalNodeCount,
        'activeNodeId': activeNodeId,
        'lineageRefs': lineageRefs,
        'rollbackRefs': rollbackRefs,
        'metadata': metadata,
      };

  factory KernelGraphAdminDigest.fromJson(Map<String, dynamic> json) {
    return KernelGraphAdminDigest(
      runId: json['runId']?.toString() ?? '',
      specId: json['specId']?.toString() ?? '',
      graphTitle: json['graphTitle']?.toString() ?? '',
      kind: KernelGraphKind.values.firstWhere(
        (value) => value.name == json['kind'],
        orElse: () => KernelGraphKind.learningIntake,
      ),
      status: KernelGraphRunStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => KernelGraphRunStatus.failed,
      ),
      summary: json['summary']?.toString() ?? '',
      requiresHumanReview: json['requiresHumanReview'] as bool? ?? false,
      completedNodeCount: (json['completedNodeCount'] as num?)?.toInt() ?? 0,
      totalNodeCount: (json['totalNodeCount'] as num?)?.toInt() ?? 0,
      activeNodeId: json['activeNodeId']?.toString(),
      lineageRefs: _stringList(json['lineageRefs']),
      rollbackRefs: _stringList(json['rollbackRefs']),
      metadata: _map(json['metadata']),
    );
  }
}

class KernelGraphRunRecord {
  const KernelGraphRunRecord({
    required this.runId,
    required this.specId,
    required this.graphTitle,
    required this.kind,
    required this.status,
    required this.startedAt,
    required this.adminDigest,
    required this.receipt,
    this.completedAt,
    this.ownerUserId,
    this.sourceId,
    this.reviewItemId,
    this.jobId,
    this.sourceKind,
    this.spec,
    this.compiledPlan,
    this.metadata = const <String, dynamic>{},
  });

  final String runId;
  final String specId;
  final String graphTitle;
  final KernelGraphKind kind;
  final KernelGraphRunStatus status;
  final DateTime startedAt;
  final DateTime? completedAt;
  final String? ownerUserId;
  final String? sourceId;
  final String? reviewItemId;
  final String? jobId;
  final String? sourceKind;
  final KernelGraphSpec? spec;
  final KernelGraphCompiledPlan? compiledPlan;
  final KernelGraphAdminDigest adminDigest;
  final KernelGraphExecutionReceipt receipt;
  final Map<String, dynamic> metadata;

  DateTime get updatedAt => completedAt ?? startedAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'runId': runId,
        'specId': specId,
        'graphTitle': graphTitle,
        'kind': kind.name,
        'status': status.name,
        'startedAt': startedAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'ownerUserId': ownerUserId,
        'sourceId': sourceId,
        'reviewItemId': reviewItemId,
        'jobId': jobId,
        'sourceKind': sourceKind,
        'spec': spec?.toJson(),
        'compiledPlan': compiledPlan?.toJson(),
        'adminDigest': adminDigest.toJson(),
        'receipt': receipt.toJson(),
        'metadata': metadata,
      };

  factory KernelGraphRunRecord.fromJson(Map<String, dynamic> json) {
    return KernelGraphRunRecord(
      runId: json['runId']?.toString() ?? '',
      specId: json['specId']?.toString() ?? '',
      graphTitle: json['graphTitle']?.toString() ?? '',
      kind: KernelGraphKind.values.firstWhere(
        (value) => value.name == json['kind'],
        orElse: () => KernelGraphKind.learningIntake,
      ),
      status: KernelGraphRunStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => KernelGraphRunStatus.failed,
      ),
      startedAt: _parseDateTime(json['startedAt']),
      completedAt: _parseNullableDateTime(json['completedAt']),
      ownerUserId: json['ownerUserId']?.toString(),
      sourceId: json['sourceId']?.toString(),
      reviewItemId: json['reviewItemId']?.toString(),
      jobId: json['jobId']?.toString(),
      sourceKind: json['sourceKind']?.toString(),
      spec: json['spec'] is Map
          ? KernelGraphSpec.fromJson(
              Map<String, dynamic>.from(json['spec'] as Map),
            )
          : null,
      compiledPlan: json['compiledPlan'] is Map
          ? KernelGraphCompiledPlan.fromJson(
              Map<String, dynamic>.from(json['compiledPlan'] as Map),
            )
          : null,
      adminDigest: KernelGraphAdminDigest.fromJson(
        _map(json['adminDigest']),
      ),
      receipt: KernelGraphExecutionReceipt.fromJson(
        _map(json['receipt']),
      ),
      metadata: _map(json['metadata']),
    );
  }
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return const <String, dynamic>{};
}

List<Map<String, dynamic>> _list(Object? value) {
  if (value is List) {
    return value
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList(growable: false);
  }
  return const <Map<String, dynamic>>[];
}

List<String> _stringList(Object? value) {
  if (value is List) {
    return value.map((entry) => entry.toString()).toList(growable: false);
  }
  return const <String>[];
}

DateTime _parseDateTime(Object? value) {
  return DateTime.tryParse(value?.toString() ?? '')?.toUtc() ??
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
}

DateTime? _parseNullableDateTime(Object? value) {
  final raw = value?.toString();
  if (raw == null || raw.isEmpty) {
    return null;
  }
  return DateTime.tryParse(raw)?.toUtc();
}
