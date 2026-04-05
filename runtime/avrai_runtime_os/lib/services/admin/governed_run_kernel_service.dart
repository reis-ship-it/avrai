import 'dart:async';
import 'dart:convert';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/admin/research_activity_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;

class GovernedRunKernelService {
  GovernedRunKernelService({
    GovernedAutoresearchSupervisor? autoresearchSupervisor,
    Future<GovernedAutoresearchSupervisor?> Function()?
        autoresearchSupervisorResolver,
    SharedPreferencesCompat? prefs,
    TruthScopeRegistry? truthScopeRegistry,
  })  : _autoresearchSupervisor = autoresearchSupervisor,
        _autoresearchSupervisorResolver = autoresearchSupervisorResolver,
        _prefs = prefs,
        _truthScopeRegistry = truthScopeRegistry ?? const TruthScopeRegistry();

  static const String _securityRunsKey = 'security.governed_runs.v1';
  static const String _selfHealRunsKey = 'self_heal.governed_runs.v1';

  GovernedAutoresearchSupervisor? _autoresearchSupervisor;
  final Future<GovernedAutoresearchSupervisor?> Function()?
      _autoresearchSupervisorResolver;
  final SharedPreferencesCompat? _prefs;
  final TruthScopeRegistry _truthScopeRegistry;

  final StreamController<List<GovernedRunRecord>> _controller =
      StreamController<List<GovernedRunRecord>>.broadcast();

  StreamSubscription<List<ResearchRunState>>? _autoresearchSubscription;
  List<GovernedRunRecord> _cachedAutoresearchRuns = const <GovernedRunRecord>[];
  bool _autoresearchResolveAttempted = false;

  Stream<List<GovernedRunRecord>> watchRuns({
    GovernedRunKind? kind,
  }) async* {
    await _ensureAutoresearchSubscription();
    yield await listRuns(kind: kind);
    yield* _controller.stream.map((runs) => _filterRuns(runs, kind: kind));
  }

  Future<List<GovernedRunRecord>> listRuns({
    GovernedRunKind? kind,
  }) async {
    await _ensureAutoresearchSubscription();
    final runs = <GovernedRunRecord>[
      ..._cachedAutoresearchRuns,
      ..._readLocalRuns(_securityRunsKey),
      ..._readLocalRuns(_selfHealRunsKey),
    ]..sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
    return _filterRuns(runs, kind: kind);
  }

  Future<GovernedRunRecord?> getRun(String runId) async {
    final runs = await listRuns();
    for (final run in runs) {
      if (run.id == runId) {
        return run;
      }
    }
    return null;
  }

  Future<GovernedRunRecord> upsertSecurityRun(GovernedRunRecord run) async {
    final normalized = run.copyWith(
      runKind: GovernedRunKind.securityRedteam,
      truthScope: _truthScopeRegistry.normalizeSecurityScope(
        scope: run.truthScope,
        metadata: run.metadata,
      ),
    );
    await _writeLocalRun(_securityRunsKey, normalized);
    await _emitSnapshot();
    return normalized;
  }

  Future<GovernedRunRecord> upsertSelfHealRun(GovernedRunRecord run) async {
    final normalized = run.copyWith(
      runKind: GovernedRunKind.selfHeal,
      truthScope: _truthScopeRegistry.normalizeHealingScope(
        scope: run.truthScope,
        metadata: run.metadata,
      ),
    );
    await _writeLocalRun(_selfHealRunsKey, normalized);
    await _emitSnapshot();
    return normalized;
  }

  Future<GovernedRunRecord> appendDirective({
    required String runId,
    required GovernedRunDirective directive,
    GovernedRunDisposition? disposition,
    GovernedRunLifecycleState? lifecycleState,
    String? latestSummary,
  }) async {
    final securityRuns = _readLocalRuns(_securityRunsKey);
    final securityIndex = securityRuns.indexWhere((run) => run.id == runId);
    if (securityIndex != -1) {
      final updated = _mutateRun(
        securityRuns[securityIndex],
        directive: directive,
        disposition: disposition,
        lifecycleState: lifecycleState,
        latestSummary: latestSummary,
      );
      securityRuns[securityIndex] = updated;
      await _persistRuns(_securityRunsKey, securityRuns);
      await _emitSnapshot();
      return updated;
    }
    final selfHealRuns = _readLocalRuns(_selfHealRunsKey);
    final selfHealIndex = selfHealRuns.indexWhere((run) => run.id == runId);
    if (selfHealIndex != -1) {
      final updated = _mutateRun(
        selfHealRuns[selfHealIndex],
        directive: directive,
        disposition: disposition,
        lifecycleState: lifecycleState,
        latestSummary: latestSummary,
      );
      selfHealRuns[selfHealIndex] = updated;
      await _persistRuns(_selfHealRunsKey, selfHealRuns);
      await _emitSnapshot();
      return updated;
    }
    throw StateError('No governed security/self-heal run exists for $runId');
  }

  Future<void> dispose() async {
    await _autoresearchSubscription?.cancel();
    await _controller.close();
  }

  Future<void> _ensureAutoresearchSubscription() async {
    if (_autoresearchSubscription != null) {
      return;
    }
    var supervisor = _autoresearchSupervisor;
    if (supervisor == null &&
        !_autoresearchResolveAttempted &&
        _autoresearchSupervisorResolver != null) {
      _autoresearchResolveAttempted = true;
      try {
        supervisor = await _autoresearchSupervisorResolver.call();
      } catch (_) {
        supervisor = null;
      }
      _autoresearchSupervisor = supervisor;
    }
    if (supervisor == null) {
      return;
    }
    _cachedAutoresearchRuns = (await supervisor.listRuns())
        .map(_mapAutoresearchRun)
        .toList(growable: false);
    _autoresearchSubscription = supervisor.watchRuns().listen((runs) async {
      _cachedAutoresearchRuns =
          runs.map(_mapAutoresearchRun).toList(growable: false);
      await _emitSnapshot();
    });
  }

  GovernedRunRecord _mapAutoresearchRun(ResearchRunState run) {
    final metadata = <String, dynamic>{
      'research_layer': run.layer.name,
      'research_lane': run.lane.name,
      'agent_class': 'system',
      'research_sphere_id': 'autoresearch_${run.layer.name}',
      'research_family_id': 'sandbox_${run.lane.name}',
    };
    final scope = _truthScopeRegistry.normalizeResearchScope(
      metadata: metadata,
    );
    final environment = switch (run.lane) {
      ResearchRunLane.sandboxReplay => GovernedRunEnvironment.replay,
    };
    final disposition = run.killSwitchActive
        ? GovernedRunDisposition.hardStop
        : (run.contradictionDetected
            ? GovernedRunDisposition.boundedDegrade
            : GovernedRunDisposition.observe);
    return run.toGovernedRunRecord(
      truthScope: scope,
      authorityToken: 'autoresearch.supervised',
      environment: environment,
      disposition: disposition,
    );
  }

  GovernedRunRecord _mutateRun(
    GovernedRunRecord run, {
    required GovernedRunDirective directive,
    GovernedRunDisposition? disposition,
    GovernedRunLifecycleState? lifecycleState,
    String? latestSummary,
  }) {
    return run.copyWith(
      disposition: disposition ?? run.disposition,
      lifecycleState: lifecycleState ?? run.lifecycleState,
      latestSummary: latestSummary ?? directive.rationale,
      directives: <GovernedRunDirective>[...run.directives, directive],
      updatedAt: directive.createdAt,
      killSwitchActive:
          directive.kind == GovernedRunDirectiveKind.triggerKillSwitch
              ? true
              : run.killSwitchActive,
      redirectDirective: directive.kind == GovernedRunDirectiveKind.redirectRun
          ? directive.details['directive']?.toString() ?? directive.rationale
          : run.redirectDirective,
    );
  }

  List<GovernedRunRecord> _readLocalRuns(String key) {
    final prefs = _prefs;
    if (prefs == null) {
      return const <GovernedRunRecord>[];
    }
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) {
      return const <GovernedRunRecord>[];
    }
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const <GovernedRunRecord>[];
    }
    return decoded
        .whereType<Map>()
        .map(
          (entry) => GovernedRunRecord.fromJson(
            Map<String, dynamic>.from(entry),
          ),
        )
        .toList(growable: false);
  }

  Future<void> _writeLocalRun(String key, GovernedRunRecord run) async {
    final runs = _readLocalRuns(key).toList(growable: true);
    final index = runs.indexWhere((entry) => entry.id == run.id);
    if (index == -1) {
      runs.insert(0, run);
    } else {
      runs[index] = run;
    }
    await _persistRuns(key, runs);
  }

  Future<void> _persistRuns(String key, List<GovernedRunRecord> runs) async {
    final prefs = _prefs;
    if (prefs == null) {
      return;
    }
    await prefs.setString(
      key,
      jsonEncode(
        runs.map((entry) => entry.toJson()).toList(growable: false),
      ),
    );
  }

  Future<void> _emitSnapshot() async {
    if (_controller.isClosed) {
      return;
    }
    _controller.add(await listRuns());
  }

  List<GovernedRunRecord> _filterRuns(
    List<GovernedRunRecord> runs, {
    GovernedRunKind? kind,
  }) {
    if (kind == null) {
      return List<GovernedRunRecord>.unmodifiable(runs);
    }
    return List<GovernedRunRecord>.unmodifiable(
      runs.where((entry) => entry.runKind == kind),
    );
  }
}

extension on GovernedRunRecord {
  GovernedRunRecord copyWith({
    String? title,
    String? hypothesis,
    GovernedRunKind? runKind,
    String? ownerAgentAlias,
    GovernedRunLifecycleState? lifecycleState,
    GovernedRunEnvironment? environment,
    GovernedRunDisposition? disposition,
    TruthScopeDescriptor? truthScope,
    String? authorityToken,
    GovernedRunCharter? charter,
    bool? requiresAdminApproval,
    bool? sandboxOnly,
    String? modelVersion,
    String? policyVersion,
    Map<String, double>? metrics,
    List<String>? tags,
    List<GovernedRunDirective>? directives,
    List<GovernedRunCheckpoint>? checkpoints,
    DateTime? updatedAt,
    DateTime? lastHeartbeatAt,
    String? latestSummary,
    String? redirectDirective,
    bool? killSwitchActive,
    bool? contradictionDetected,
    int? pendingApprovalCount,
    int? approvedApprovalCount,
    int? alertCount,
    int? artifactCount,
    Map<String, dynamic>? metadata,
  }) {
    return GovernedRunRecord(
      id: id,
      title: title ?? this.title,
      hypothesis: hypothesis ?? this.hypothesis,
      runKind: runKind ?? this.runKind,
      ownerAgentAlias: ownerAgentAlias ?? this.ownerAgentAlias,
      lifecycleState: lifecycleState ?? this.lifecycleState,
      environment: environment ?? this.environment,
      disposition: disposition ?? this.disposition,
      truthScope: truthScope ?? this.truthScope,
      authorityToken: authorityToken ?? this.authorityToken,
      charter: charter ?? this.charter,
      requiresAdminApproval:
          requiresAdminApproval ?? this.requiresAdminApproval,
      sandboxOnly: sandboxOnly ?? this.sandboxOnly,
      modelVersion: modelVersion ?? this.modelVersion,
      policyVersion: policyVersion ?? this.policyVersion,
      metrics: metrics ?? this.metrics,
      tags: tags ?? this.tags,
      directives: directives ?? this.directives,
      checkpoints: checkpoints ?? this.checkpoints,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastHeartbeatAt: lastHeartbeatAt ?? this.lastHeartbeatAt,
      latestSummary: latestSummary ?? this.latestSummary,
      redirectDirective: redirectDirective ?? this.redirectDirective,
      killSwitchActive: killSwitchActive ?? this.killSwitchActive,
      contradictionDetected:
          contradictionDetected ?? this.contradictionDetected,
      pendingApprovalCount: pendingApprovalCount ?? this.pendingApprovalCount,
      approvedApprovalCount:
          approvedApprovalCount ?? this.approvedApprovalCount,
      alertCount: alertCount ?? this.alertCount,
      artifactCount: artifactCount ?? this.artifactCount,
      metadata: metadata ?? this.metadata,
    );
  }
}
