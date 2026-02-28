import 'dart:async';
import 'dart:convert';

import 'package:avrai/core/services/infrastructure/supabase_service.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;

enum ResearchLayer { reality, universe, world, crossLayer }

enum ResearchStatus { proposed, running, humanReview, completed, paused }

enum ResearchVisibilityScope {
  adminOnly,
  adminAndRealityModel,
  adminAndModelOps,
}

enum ResearchApprovalStatus { notRequired, pending, approved, rejected }

enum ResearchAlertSeverity { info, warning, critical }

class ResearchLogEntry {
  const ResearchLogEntry({
    required this.actorId,
    required this.message,
    required this.createdAt,
  });

  final String actorId;
  final String message;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'actorId': actorId,
        'message': message,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ResearchLogEntry.fromJson(Map<String, dynamic> json) {
    return ResearchLogEntry(
      actorId: json['actorId'] as String? ?? 'unknown',
      message: json['message'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class ResearchImpactLink {
  const ResearchImpactLink({
    required this.entityType,
    required this.entityId,
    required this.beforeMetric,
    required this.afterMetric,
    required this.rollbackCheckpointId,
    required this.recordedAt,
  });

  final String entityType;
  final String entityId;
  final double beforeMetric;
  final double afterMetric;
  final String rollbackCheckpointId;
  final DateTime recordedAt;

  double get delta => afterMetric - beforeMetric;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'entityType': entityType,
        'entityId': entityId,
        'beforeMetric': beforeMetric,
        'afterMetric': afterMetric,
        'rollbackCheckpointId': rollbackCheckpointId,
        'recordedAt': recordedAt.toIso8601String(),
      };

  factory ResearchImpactLink.fromJson(Map<String, dynamic> json) {
    return ResearchImpactLink(
      entityType: json['entityType'] as String? ?? 'unknown',
      entityId: json['entityId'] as String? ?? 'unknown',
      beforeMetric: (json['beforeMetric'] as num?)?.toDouble() ?? 0.0,
      afterMetric: (json['afterMetric'] as num?)?.toDouble() ?? 0.0,
      rollbackCheckpointId: json['rollbackCheckpointId'] as String? ?? '',
      recordedAt: DateTime.tryParse(json['recordedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class ResearchAlert {
  const ResearchAlert({
    required this.id,
    required this.projectId,
    required this.severity,
    required this.title,
    required this.message,
    required this.createdAt,
  });

  final String id;
  final String projectId;
  final ResearchAlertSeverity severity;
  final String title;
  final String message;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'projectId': projectId,
        'severity': severity.name,
        'title': title,
        'message': message,
        'createdAt': createdAt.toIso8601String(),
      };
}

class ResearchProject {
  const ResearchProject({
    required this.id,
    required this.title,
    required this.hypothesis,
    required this.layer,
    required this.status,
    required this.ownerAgentId,
    required this.realityModelCanView,
    required this.requiresHumanApproval,
    required this.tags,
    required this.metrics,
    required this.createdAt,
    required this.updatedAt,
    required this.log,
    required this.visibilityScope,
    required this.allowedRoles,
    required this.approvalStatus,
    required this.approvedBy,
    required this.approvedAt,
    required this.rejectedReason,
    required this.impacts,
  });

  final String id;
  final String title;
  final String hypothesis;
  final ResearchLayer layer;
  final ResearchStatus status;
  final String ownerAgentId;
  final bool realityModelCanView;
  final bool requiresHumanApproval;
  final List<String> tags;
  final Map<String, double> metrics;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ResearchLogEntry> log;
  final ResearchVisibilityScope visibilityScope;
  final List<String> allowedRoles;
  final ResearchApprovalStatus approvalStatus;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectedReason;
  final List<ResearchImpactLink> impacts;

  bool canRoleView(String roleId) => allowedRoles.contains(roleId);

  ResearchProject copyWith({
    ResearchStatus? status,
    DateTime? updatedAt,
    List<ResearchLogEntry>? log,
    ResearchApprovalStatus? approvalStatus,
    String? approvedBy,
    DateTime? approvedAt,
    String? rejectedReason,
    List<ResearchImpactLink>? impacts,
  }) {
    return ResearchProject(
      id: id,
      title: title,
      hypothesis: hypothesis,
      layer: layer,
      status: status ?? this.status,
      ownerAgentId: ownerAgentId,
      realityModelCanView: realityModelCanView,
      requiresHumanApproval: requiresHumanApproval,
      tags: tags,
      metrics: metrics,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      log: log ?? this.log,
      visibilityScope: visibilityScope,
      allowedRoles: allowedRoles,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectedReason: rejectedReason ?? this.rejectedReason,
      impacts: impacts ?? this.impacts,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'hypothesis': hypothesis,
        'layer': layer.name,
        'status': status.name,
        'ownerAgentId': ownerAgentId,
        'realityModelCanView': realityModelCanView,
        'requiresHumanApproval': requiresHumanApproval,
        'tags': tags,
        'metrics': metrics,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'log': log.map((entry) => entry.toJson()).toList(growable: false),
        'visibilityScope': visibilityScope.name,
        'allowedRoles': allowedRoles,
        'approvalStatus': approvalStatus.name,
        'approvedBy': approvedBy,
        'approvedAt': approvedAt?.toIso8601String(),
        'rejectedReason': rejectedReason,
        'impacts': impacts.map((i) => i.toJson()).toList(growable: false),
      };

  factory ResearchProject.fromJson(Map<String, dynamic> json) {
    final metrics = <String, double>{};
    final rawMetrics = json['metrics'];
    if (rawMetrics is Map<String, dynamic>) {
      for (final entry in rawMetrics.entries) {
        if (entry.value is num) {
          metrics[entry.key] = (entry.value as num).toDouble();
        }
      }
    }

    final parsedLog = (json['log'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(ResearchLogEntry.fromJson)
        .toList(growable: false);
    final impacts = (json['impacts'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(ResearchImpactLink.fromJson)
        .toList(growable: false);

    return ResearchProject(
      id: json['id'] as String? ?? 'unknown',
      title: json['title'] as String? ?? 'Untitled project',
      hypothesis: json['hypothesis'] as String? ?? '',
      layer: _parseLayer(json['layer'] as String?),
      status: _parseStatus(json['status'] as String?),
      ownerAgentId: json['ownerAgentId'] as String? ?? 'agent_unknown',
      realityModelCanView: json['realityModelCanView'] as bool? ?? true,
      requiresHumanApproval: json['requiresHumanApproval'] as bool? ?? true,
      tags: (json['tags'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) => item.toString())
          .toList(growable: false),
      metrics: metrics,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      log: parsedLog,
      visibilityScope:
          _parseVisibilityScope(json['visibilityScope'] as String?),
      allowedRoles:
          (json['allowedRoles'] as List<dynamic>? ?? const <dynamic>[])
              .map((item) => item.toString())
              .toList(growable: false),
      approvalStatus: _parseApprovalStatus(json['approvalStatus'] as String?),
      approvedBy: json['approvedBy'] as String?,
      approvedAt: DateTime.tryParse(json['approvedAt'] as String? ?? ''),
      rejectedReason: json['rejectedReason'] as String?,
      impacts: impacts,
    );
  }

  factory ResearchProject.fromBackendRow(
    Map<String, dynamic> row, {
    required List<ResearchLogEntry> log,
    required List<ResearchImpactLink> impacts,
  }) {
    final tags = (row['tags'] is List)
        ? (row['tags'] as List<dynamic>)
            .map((item) => item.toString())
            .toList(growable: false)
        : const <String>[];
    final allowedRoles = (row['allowed_roles'] is List)
        ? (row['allowed_roles'] as List<dynamic>)
            .map((item) => item.toString())
            .toList(growable: false)
        : const <String>['admin_operator', 'reality_model_primary'];

    final metrics = <String, double>{};
    final rawMetrics = row['metrics'];
    if (rawMetrics is Map) {
      for (final entry in rawMetrics.entries) {
        if (entry.value is num) {
          metrics[entry.key.toString()] = (entry.value as num).toDouble();
        }
      }
    }

    return ResearchProject(
      id: row['id']?.toString() ?? 'unknown',
      title: row['title']?.toString() ?? 'Untitled project',
      hypothesis: row['hypothesis']?.toString() ?? '',
      layer: _parseLayer(row['layer']?.toString()),
      status: _parseStatus(row['status']?.toString()),
      ownerAgentId: row['owner_agent_id']?.toString() ?? 'agent_unknown',
      realityModelCanView: row['reality_model_can_view'] as bool? ?? true,
      requiresHumanApproval: row['requires_human_approval'] as bool? ?? true,
      tags: tags,
      metrics: metrics,
      createdAt: DateTime.tryParse(row['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(row['updated_at']?.toString() ?? '') ??
          DateTime.now(),
      log: log,
      visibilityScope:
          _parseVisibilityScope(row['visibility_scope']?.toString()),
      allowedRoles: allowedRoles,
      approvalStatus: _parseApprovalStatus(row['approval_status']?.toString()),
      approvedBy: row['approved_by']?.toString(),
      approvedAt: DateTime.tryParse(row['approved_at']?.toString() ?? ''),
      rejectedReason: row['rejected_reason']?.toString(),
      impacts: impacts,
    );
  }

  Map<String, dynamic> toBackendInsertRow() => <String, dynamic>{
        'id': id,
        'title': title,
        'hypothesis': hypothesis,
        'layer': layer.name,
        'status': status.name,
        'owner_agent_id': ownerAgentId,
        'reality_model_can_view': realityModelCanView,
        'requires_human_approval': requiresHumanApproval,
        'tags': tags,
        'metrics': metrics,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'visibility_scope': visibilityScope.name,
        'allowed_roles': allowedRoles,
        'approval_status': approvalStatus.name,
        'approved_by': approvedBy,
        'approved_at': approvedAt?.toIso8601String(),
        'rejected_reason': rejectedReason,
      };

  static ResearchLayer _parseLayer(String? raw) {
    return ResearchLayer.values.firstWhere(
      (layer) => layer.name == raw,
      orElse: () => ResearchLayer.crossLayer,
    );
  }

  static ResearchStatus _parseStatus(String? raw) {
    return ResearchStatus.values.firstWhere(
      (status) => status.name == raw,
      orElse: () => ResearchStatus.proposed,
    );
  }

  static ResearchVisibilityScope _parseVisibilityScope(String? raw) {
    return ResearchVisibilityScope.values.firstWhere(
      (scope) => scope.name == raw,
      orElse: () => ResearchVisibilityScope.adminAndRealityModel,
    );
  }

  static ResearchApprovalStatus _parseApprovalStatus(String? raw) {
    return ResearchApprovalStatus.values.firstWhere(
      (status) => status.name == raw,
      orElse: () => ResearchApprovalStatus.pending,
    );
  }
}

class ResearchActionBlockedException implements Exception {
  ResearchActionBlockedException(this.message);
  final String message;
  @override
  String toString() => 'ResearchActionBlockedException: $message';
}

abstract class ResearchActivityService {
  Stream<List<ResearchProject>> watchProjects();
  Future<List<ResearchProject>> getProjects();
  Future<void> updateProjectStatus({
    required String projectId,
    required ResearchStatus status,
    required String actorId,
  });
  Future<void> appendProjectLog({
    required String projectId,
    required String actorId,
    required String message,
  });
  Future<void> resolveApproval({
    required String projectId,
    required String actorId,
    required bool approved,
    String? reason,
  });
  Future<void> addImpactLink({
    required String projectId,
    required ResearchImpactLink link,
    required String actorId,
  });
  Future<List<ResearchAlert>> getAlerts();
  Future<void> recordControlAction({
    required String action,
    required String actorId,
    String? projectId,
    Map<String, dynamic>? details,
  });
}

enum ResearchActivitySource { localMock, internalBackend }

class ResearchActivityServiceResolution {
  const ResearchActivityServiceResolution({
    required this.service,
    required this.source,
    required this.sourceLabel,
    required this.isBackendConnected,
  });
  final ResearchActivityService service;
  final ResearchActivitySource source;
  final String sourceLabel;
  final bool isBackendConnected;
}

class ResearchActivityServiceFactory {
  static const String _sourceEnvKey = 'ADMIN_RESEARCH_SOURCE';

  static Future<ResearchActivityServiceResolution> createDefault({
    required SharedPreferencesCompat prefs,
  }) async {
    const requested = String.fromEnvironment(_sourceEnvKey, defaultValue: '');
    final source = requested.trim().toLowerCase() == 'internal_backend'
        ? ResearchActivitySource.internalBackend
        : ResearchActivitySource.localMock;
    return create(prefs: prefs, preferredSource: source);
  }

  static Future<ResearchActivityServiceResolution> create({
    required SharedPreferencesCompat prefs,
    required ResearchActivitySource preferredSource,
  }) async {
    switch (preferredSource) {
      case ResearchActivitySource.localMock:
        return ResearchActivityServiceResolution(
          service: LocalResearchActivityService(prefs: prefs),
          source: ResearchActivitySource.localMock,
          sourceLabel: 'local mock (v1)',
          isBackendConnected: false,
        );
      case ResearchActivitySource.internalBackend:
        final backend = InternalBackendResearchActivityService(
          supabaseService: SupabaseService(),
        );
        final connected = await backend.canConnect();
        if (connected) {
          await backend.bootstrapFromLocalIfEmpty(prefs: prefs);
          return ResearchActivityServiceResolution(
            service: backend,
            source: ResearchActivitySource.internalBackend,
            sourceLabel: 'internal backend',
            isBackendConnected: true,
          );
        }
        return ResearchActivityServiceResolution(
          service: LocalResearchActivityService(prefs: prefs),
          source: ResearchActivitySource.internalBackend,
          sourceLabel: 'internal backend (pending, local fallback active)',
          isBackendConnected: false,
        );
    }
  }
}

class LocalResearchActivityService implements ResearchActivityService {
  LocalResearchActivityService({required SharedPreferencesCompat prefs})
      : _prefs = prefs;

  static const String _storageKey = 'admin.research.projects.v1';
  final SharedPreferencesCompat _prefs;
  final StreamController<List<ResearchProject>> _controller =
      StreamController<List<ResearchProject>>.broadcast();
  List<ResearchProject> _projects = <ResearchProject>[];
  bool _initialized = false;

  @override
  Stream<List<ResearchProject>> watchProjects() async* {
    await _ensureInitialized();
    yield List<ResearchProject>.unmodifiable(_projects);
    yield* _controller.stream;
  }

  @override
  Future<List<ResearchProject>> getProjects() async {
    await _ensureInitialized();
    return List<ResearchProject>.unmodifiable(_projects);
  }

  @override
  Future<void> updateProjectStatus({
    required String projectId,
    required ResearchStatus status,
    required String actorId,
  }) async {
    await _ensureInitialized();
    final now = DateTime.now();
    _projects = _projects.map((project) {
      if (project.id != projectId) return project;
      if (status == ResearchStatus.running &&
          project.requiresHumanApproval &&
          project.approvalStatus != ResearchApprovalStatus.approved) {
        throw ResearchActionBlockedException(
          'Project requires human approval before running.',
        );
      }
      return project.copyWith(
        status: status,
        updatedAt: now,
        log: <ResearchLogEntry>[
          ...project.log,
          ResearchLogEntry(
            actorId: actorId,
            message: 'Status updated to ${status.name}',
            createdAt: now,
          ),
        ],
      );
    }).toList(growable: false);
    await _persistAndEmit();
  }

  @override
  Future<void> appendProjectLog({
    required String projectId,
    required String actorId,
    required String message,
  }) async {
    await _ensureInitialized();
    final now = DateTime.now();
    _projects = _projects.map((project) {
      if (project.id != projectId) return project;
      return project.copyWith(
        updatedAt: now,
        log: <ResearchLogEntry>[
          ...project.log,
          ResearchLogEntry(actorId: actorId, message: message, createdAt: now),
        ],
      );
    }).toList(growable: false);
    await _persistAndEmit();
  }

  @override
  Future<void> resolveApproval({
    required String projectId,
    required String actorId,
    required bool approved,
    String? reason,
  }) async {
    await _ensureInitialized();
    final now = DateTime.now();
    _projects = _projects.map((project) {
      if (project.id != projectId) return project;
      final status = approved
          ? ResearchApprovalStatus.approved
          : ResearchApprovalStatus.rejected;
      return project.copyWith(
        updatedAt: now,
        approvalStatus: status,
        approvedBy: approved ? actorId : null,
        approvedAt: approved ? now : null,
        rejectedReason: approved ? null : (reason ?? 'No reason provided'),
        log: <ResearchLogEntry>[
          ...project.log,
          ResearchLogEntry(
            actorId: actorId,
            message: approved
                ? 'Approval granted'
                : 'Approval rejected: ${reason ?? 'No reason provided'}',
            createdAt: now,
          ),
        ],
      );
    }).toList(growable: false);
    await _persistAndEmit();
  }

  @override
  Future<void> addImpactLink({
    required String projectId,
    required ResearchImpactLink link,
    required String actorId,
  }) async {
    await _ensureInitialized();
    final now = DateTime.now();
    _projects = _projects.map((project) {
      if (project.id != projectId) return project;
      return project.copyWith(
        updatedAt: now,
        impacts: <ResearchImpactLink>[...project.impacts, link],
        log: <ResearchLogEntry>[
          ...project.log,
          ResearchLogEntry(
            actorId: actorId,
            message:
                'Impact linked: ${link.entityType}/${link.entityId} delta=${link.delta.toStringAsFixed(3)}',
            createdAt: now,
          ),
        ],
      );
    }).toList(growable: false);
    await _persistAndEmit();
  }

  @override
  Future<List<ResearchAlert>> getAlerts() async {
    await _ensureInitialized();
    return _deriveAlerts(_projects);
  }

  @override
  Future<void> recordControlAction({
    required String action,
    required String actorId,
    String? projectId,
    Map<String, dynamic>? details,
  }) async {
    // Local mode keeps this as an in-log note.
    if (projectId == null) return;
    await appendProjectLog(
      projectId: projectId,
      actorId: actorId,
      message: 'CONTROL_ACTION[$action]: ${jsonEncode(details ?? const {})}',
    );
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;
    final raw = _prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      _projects = _seedProjects();
      await _persistAndEmit();
      return;
    }
    try {
      final parsed = jsonDecode(raw) as List<dynamic>;
      _projects = parsed
          .whereType<Map<String, dynamic>>()
          .map(ResearchProject.fromJson)
          .toList(growable: false);
      _controller.add(List<ResearchProject>.unmodifiable(_projects));
    } catch (_) {
      _projects = _seedProjects();
      await _persistAndEmit();
    }
  }

  Future<void> _persistAndEmit() async {
    await _prefs.setString(
      _storageKey,
      jsonEncode(_projects.map((p) => p.toJson()).toList(growable: false)),
    );
    _controller.add(List<ResearchProject>.unmodifiable(_projects));
  }

  List<ResearchProject> _seedProjects() {
    final now = DateTime.now();
    return <ResearchProject>[
      ResearchProject(
        id: 'rsh_reality_01',
        title: 'Reality Grouping Drift Monitor',
        hypothesis:
            'Grouping proposals become clearer when we include human-approved rationale examples.',
        layer: ResearchLayer.reality,
        status: ResearchStatus.running,
        ownerAgentId: 'reality_model_primary',
        realityModelCanView: true,
        requiresHumanApproval: true,
        tags: const <String>['groupings', 'explainability', 'oversight'],
        metrics: const <String, double>{
          'clarityScore': 0.74,
          'humanApprovalRate': 0.68,
          'driftScore': 0.32,
          'policyViolationCount': 0,
        },
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(hours: 2)),
        log: <ResearchLogEntry>[
          ResearchLogEntry(
            actorId: 'admin_operator',
            message: 'Baseline approved and running under human oversight.',
            createdAt: now.subtract(const Duration(days: 2)),
          ),
        ],
        visibilityScope: ResearchVisibilityScope.adminAndRealityModel,
        allowedRoles: const <String>['admin_operator', 'reality_model_primary'],
        approvalStatus: ResearchApprovalStatus.approved,
        approvedBy: 'admin_operator',
        approvedAt: now.subtract(const Duration(days: 2)),
        rejectedReason: null,
        impacts: const <ResearchImpactLink>[],
      ),
      ResearchProject(
        id: 'rsh_universe_01',
        title: 'Universe Type Taxonomy Expansion',
        hypothesis:
            'Cross-club feature embeddings can generate more useful universe families.',
        layer: ResearchLayer.universe,
        status: ResearchStatus.humanReview,
        ownerAgentId: 'universe_model_primary',
        realityModelCanView: true,
        requiresHumanApproval: true,
        tags: const <String>['taxonomy', 'universe', 'learning'],
        metrics: const <String, double>{
          'novelGroupingLift': 0.31,
          'operatorAgreement': 0.79,
          'driftScore': 0.19,
          'policyViolationCount': 1,
        },
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(hours: 6)),
        log: <ResearchLogEntry>[
          ResearchLogEntry(
            actorId: 'universe_model_primary',
            message: 'Submitted new grouping candidates for review.',
            createdAt: now.subtract(const Duration(hours: 6)),
          ),
        ],
        visibilityScope: ResearchVisibilityScope.adminAndRealityModel,
        allowedRoles: const <String>['admin_operator', 'reality_model_primary'],
        approvalStatus: ResearchApprovalStatus.pending,
        approvedBy: null,
        approvedAt: null,
        rejectedReason: null,
        impacts: const <ResearchImpactLink>[],
      ),
      ResearchProject(
        id: 'rsh_world_01',
        title: 'World Agent Placement Stability',
        hypothesis:
            'Agent placement accuracy improves when temporal phase weighting is applied.',
        layer: ResearchLayer.world,
        status: ResearchStatus.proposed,
        ownerAgentId: 'world_model_primary',
        realityModelCanView: true,
        requiresHumanApproval: true,
        tags: const <String>['world', 'placement', 'temporal-phase'],
        metrics: const <String, double>{
          'placementAccuracy': 0.62,
          'driftScore': 0.58,
          'policyViolationCount': 0,
        },
        createdAt: now.subtract(const Duration(hours: 20)),
        updatedAt: now.subtract(const Duration(hours: 20)),
        log: <ResearchLogEntry>[
          ResearchLogEntry(
            actorId: 'world_model_primary',
            message: 'Proposal drafted, awaiting operator start decision.',
            createdAt: now.subtract(const Duration(hours: 20)),
          ),
        ],
        visibilityScope: ResearchVisibilityScope.adminAndRealityModel,
        allowedRoles: const <String>['admin_operator', 'reality_model_primary'],
        approvalStatus: ResearchApprovalStatus.pending,
        approvedBy: null,
        approvedAt: null,
        rejectedReason: null,
        impacts: const <ResearchImpactLink>[],
      ),
    ];
  }
}

List<ResearchAlert> _deriveAlerts(List<ResearchProject> projects) {
  final alerts = <ResearchAlert>[];
  final now = DateTime.now();
  for (final project in projects) {
    if (project.status == ResearchStatus.running &&
        now.difference(project.updatedAt) > const Duration(hours: 24)) {
      alerts.add(
        ResearchAlert(
          id: '${project.id}_stalled',
          projectId: project.id,
          severity: ResearchAlertSeverity.warning,
          title: 'Stalled project',
          message: 'Running project has not updated in over 24 hours.',
          createdAt: now,
        ),
      );
    }
    final approvalRate = project.metrics['humanApprovalRate'];
    if (approvalRate != null && approvalRate < 0.6) {
      alerts.add(
        ResearchAlert(
          id: '${project.id}_approval_rate',
          projectId: project.id,
          severity: ResearchAlertSeverity.warning,
          title: 'Low approval rate',
          message: 'Human approval rate dropped below 60%.',
          createdAt: now,
        ),
      );
    }
    final drift = project.metrics['driftScore'];
    if (drift != null && drift > 0.65) {
      alerts.add(
        ResearchAlert(
          id: '${project.id}_drift',
          projectId: project.id,
          severity: ResearchAlertSeverity.critical,
          title: 'Drift spike',
          message: 'Model drift score exceeded threshold.',
          createdAt: now,
        ),
      );
    }
    final violations = project.metrics['policyViolationCount'];
    if (violations != null && violations >= 3) {
      alerts.add(
        ResearchAlert(
          id: '${project.id}_policy_violations',
          projectId: project.id,
          severity: ResearchAlertSeverity.critical,
          title: 'Policy violations',
          message: 'Repeated policy violations detected.',
          createdAt: now,
        ),
      );
    }
  }
  return alerts;
}

class InternalBackendResearchActivityService
    implements ResearchActivityService {
  InternalBackendResearchActivityService(
      {required SupabaseService supabaseService})
      : _supabaseService = supabaseService;

  static const String _projectsTable = 'admin_research_projects';
  static const String _logsTable = 'admin_research_project_logs';
  static const String _impactsTable = 'admin_research_project_impacts';
  static const String _alertsTable = 'admin_research_alerts';
  static const String _controlActionsTable = 'admin_research_control_actions';
  static const String _localKey = 'admin.research.projects.v1';

  final SupabaseService _supabaseService;

  Future<bool> canConnect() async {
    try {
      if (!_supabaseService.isAvailable) return false;
      await _supabaseService.client.from(_projectsTable).select('id').limit(1);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> bootstrapFromLocalIfEmpty({
    required SharedPreferencesCompat prefs,
  }) async {
    final client = _supabaseService.client;
    final existing = await client.from(_projectsTable).select('id').limit(1);
    if ((existing as List<dynamic>).isNotEmpty) return;

    final raw = prefs.getString(_localKey);
    if (raw == null || raw.isEmpty) return;
    final decoded = jsonDecode(raw) as List<dynamic>;
    final projects = decoded
        .whereType<Map<String, dynamic>>()
        .map(ResearchProject.fromJson)
        .toList(growable: false);

    for (final project in projects) {
      await client.from(_projectsTable).insert(project.toBackendInsertRow());
      for (final log in project.log) {
        await client.from(_logsTable).insert(<String, dynamic>{
          'project_id': project.id,
          'actor_id': log.actorId,
          'message': log.message,
          'created_at': log.createdAt.toIso8601String(),
        });
      }
      for (final impact in project.impacts) {
        await client.from(_impactsTable).insert(<String, dynamic>{
          'project_id': project.id,
          'entity_type': impact.entityType,
          'entity_id': impact.entityId,
          'before_metric': impact.beforeMetric,
          'after_metric': impact.afterMetric,
          'rollback_checkpoint_id': impact.rollbackCheckpointId,
          'recorded_at': impact.recordedAt.toIso8601String(),
        });
      }
    }
  }

  @override
  Stream<List<ResearchProject>> watchProjects() async* {
    yield await getProjects();
    final client = _supabaseService.tryGetClient();
    if (client == null) return;

    final controller = StreamController<List<ResearchProject>>();
    Future<void> emit() async {
      try {
        controller.add(await getProjects());
      } catch (e, st) {
        controller.addError(e, st);
      }
    }

    final projectSub =
        client.from(_projectsTable).stream(primaryKey: ['id']).listen((_) {
      emit();
    });
    final logSub =
        client.from(_logsTable).stream(primaryKey: ['id']).listen((_) {
      emit();
    });
    final impactSub =
        client.from(_impactsTable).stream(primaryKey: ['id']).listen((_) {
      emit();
    });

    controller.onCancel = () async {
      await projectSub.cancel();
      await logSub.cancel();
      await impactSub.cancel();
    };

    yield* controller.stream;
  }

  @override
  Future<List<ResearchProject>> getProjects() async {
    final client = _supabaseService.client;
    final projectRows = await client
        .from(_projectsTable)
        .select('*')
        .order('updated_at', ascending: false);
    final projects = (projectRows as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
    if (projects.isEmpty) return const <ResearchProject>[];

    final ids = projects
        .map((row) => row['id']?.toString())
        .whereType<String>()
        .toList(growable: false);
    final idSet = ids.toSet();

    final rawLogs = await client
        .from(_logsTable)
        .select('*')
        .order('created_at', ascending: true);
    final rawImpacts = await client
        .from(_impactsTable)
        .select('*')
        .order('recorded_at', ascending: true);

    final logsByProject = <String, List<ResearchLogEntry>>{};
    for (final dynamic row in (rawLogs as List<dynamic>)) {
      if (row is! Map<String, dynamic>) continue;
      final projectId = row['project_id']?.toString() ?? '';
      if (!idSet.contains(projectId)) continue;
      logsByProject.putIfAbsent(projectId, () => <ResearchLogEntry>[]).add(
            ResearchLogEntry(
              actorId: row['actor_id']?.toString() ?? 'unknown',
              message: row['message']?.toString() ?? '',
              createdAt:
                  DateTime.tryParse(row['created_at']?.toString() ?? '') ??
                      DateTime.now(),
            ),
          );
    }

    final impactsByProject = <String, List<ResearchImpactLink>>{};
    for (final dynamic row in (rawImpacts as List<dynamic>)) {
      if (row is! Map<String, dynamic>) continue;
      final projectId = row['project_id']?.toString() ?? '';
      if (!idSet.contains(projectId)) continue;
      impactsByProject.putIfAbsent(projectId, () => <ResearchImpactLink>[]).add(
            ResearchImpactLink(
              entityType: row['entity_type']?.toString() ?? 'unknown',
              entityId: row['entity_id']?.toString() ?? 'unknown',
              beforeMetric: (row['before_metric'] as num?)?.toDouble() ?? 0.0,
              afterMetric: (row['after_metric'] as num?)?.toDouble() ?? 0.0,
              rollbackCheckpointId:
                  row['rollback_checkpoint_id']?.toString() ?? '',
              recordedAt:
                  DateTime.tryParse(row['recorded_at']?.toString() ?? '') ??
                      DateTime.now(),
            ),
          );
    }

    return projects
        .map((row) => ResearchProject.fromBackendRow(
              row,
              log: logsByProject[row['id']?.toString() ?? ''] ??
                  const <ResearchLogEntry>[],
              impacts: impactsByProject[row['id']?.toString() ?? ''] ??
                  const <ResearchImpactLink>[],
            ))
        .toList(growable: false);
  }

  @override
  Future<void> updateProjectStatus({
    required String projectId,
    required ResearchStatus status,
    required String actorId,
  }) async {
    final projects = await getProjects();
    final project = projects.firstWhere((p) => p.id == projectId);
    if (status == ResearchStatus.running &&
        project.requiresHumanApproval &&
        project.approvalStatus != ResearchApprovalStatus.approved) {
      throw ResearchActionBlockedException(
        'Project requires approval before status can move to running.',
      );
    }

    final now = DateTime.now().toIso8601String();
    final client = _supabaseService.client;
    await client.from(_projectsTable).update(<String, dynamic>{
      'status': status.name,
      'updated_at': now,
    }).eq('id', projectId);
    await client.from(_logsTable).insert(<String, dynamic>{
      'project_id': projectId,
      'actor_id': actorId,
      'message': 'Status updated to ${status.name}',
      'created_at': now,
    });
    await recordControlAction(
      action: 'update_status',
      actorId: actorId,
      projectId: projectId,
      details: <String, dynamic>{'status': status.name},
    );
  }

  @override
  Future<void> appendProjectLog({
    required String projectId,
    required String actorId,
    required String message,
  }) async {
    final now = DateTime.now().toIso8601String();
    final client = _supabaseService.client;
    await client.from(_logsTable).insert(<String, dynamic>{
      'project_id': projectId,
      'actor_id': actorId,
      'message': message,
      'created_at': now,
    });
    await client.from(_projectsTable).update(<String, dynamic>{
      'updated_at': now,
    }).eq('id', projectId);
  }

  @override
  Future<void> resolveApproval({
    required String projectId,
    required String actorId,
    required bool approved,
    String? reason,
  }) async {
    final now = DateTime.now().toIso8601String();
    final client = _supabaseService.client;
    await client.from(_projectsTable).update(<String, dynamic>{
      'approval_status': approved
          ? ResearchApprovalStatus.approved.name
          : ResearchApprovalStatus.rejected.name,
      'approved_by': approved ? actorId : null,
      'approved_at': approved ? now : null,
      'rejected_reason': approved ? null : (reason ?? 'No reason provided'),
      'updated_at': now,
    }).eq('id', projectId);
    await client.from(_logsTable).insert(<String, dynamic>{
      'project_id': projectId,
      'actor_id': actorId,
      'message': approved
          ? 'Approval granted'
          : 'Approval rejected: ${reason ?? 'No reason provided'}',
      'created_at': now,
    });
    await recordControlAction(
      action: approved ? 'approve_project' : 'reject_project',
      actorId: actorId,
      projectId: projectId,
      details: <String, dynamic>{'reason': reason},
    );
  }

  @override
  Future<void> addImpactLink({
    required String projectId,
    required ResearchImpactLink link,
    required String actorId,
  }) async {
    final now = DateTime.now().toIso8601String();
    final client = _supabaseService.client;
    await client.from(_impactsTable).insert(<String, dynamic>{
      'project_id': projectId,
      'entity_type': link.entityType,
      'entity_id': link.entityId,
      'before_metric': link.beforeMetric,
      'after_metric': link.afterMetric,
      'rollback_checkpoint_id': link.rollbackCheckpointId,
      'recorded_at': link.recordedAt.toIso8601String(),
      'recorded_by': actorId,
    });
    await client.from(_projectsTable).update(<String, dynamic>{
      'updated_at': now,
    }).eq('id', projectId);
    await appendProjectLog(
      projectId: projectId,
      actorId: actorId,
      message:
          'Impact linked: ${link.entityType}/${link.entityId} delta=${link.delta.toStringAsFixed(3)}',
    );
  }

  @override
  Future<List<ResearchAlert>> getAlerts() async {
    try {
      final rows = await _supabaseService.client
          .from(_alertsTable)
          .select('*')
          .order('created_at', ascending: false);
      return (rows as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map((row) {
        final severity = ResearchAlertSeverity.values.firstWhere(
          (s) => s.name == row['severity']?.toString(),
          orElse: () => ResearchAlertSeverity.info,
        );
        return ResearchAlert(
          id: row['id']?.toString() ?? '',
          projectId: row['project_id']?.toString() ?? '',
          severity: severity,
          title: row['title']?.toString() ?? 'Alert',
          message: row['message']?.toString() ?? '',
          createdAt: DateTime.tryParse(row['created_at']?.toString() ?? '') ??
              DateTime.now(),
        );
      }).toList(growable: false);
    } catch (_) {
      final projects = await getProjects();
      return _deriveAlerts(projects);
    }
  }

  @override
  Future<void> recordControlAction({
    required String action,
    required String actorId,
    String? projectId,
    Map<String, dynamic>? details,
  }) async {
    await _supabaseService.client
        .from(_controlActionsTable)
        .insert(<String, dynamic>{
      'action': action,
      'actor_id': actorId,
      'project_id': projectId,
      'details': details ?? <String, dynamic>{},
      'created_at': DateTime.now().toIso8601String(),
      'source': 'admin_app',
    });
  }
}
