import 'dart:convert';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/admin/governed_run_kernel_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_runtime_os/services/security/immune_memory_ledger.dart';
import 'package:avrai_runtime_os/services/security/security_campaign_registry.dart';
import 'package:avrai_runtime_os/services/security/security_learning_moment_bridge.dart';
import 'package:avrai_runtime_os/services/security/security_replay_harness.dart';

class SandboxOrchestratorService {
  SandboxOrchestratorService({
    required GovernedRunKernelService governedRunKernel,
    required SecurityCampaignRegistry campaignRegistry,
    required ImmuneMemoryLedger immuneMemoryLedger,
    required SecurityReplayHarness replayHarness,
    SecurityLearningMomentBridge? learningMomentBridge,
    SharedPreferencesCompat? prefs,
    DateTime Function()? nowProvider,
  })  : _governedRunKernel = governedRunKernel,
        _campaignRegistry = campaignRegistry,
        _immuneMemoryLedger = immuneMemoryLedger,
        _replayHarness = replayHarness,
        _learningMomentBridge = learningMomentBridge,
        _prefs = prefs,
        _nowProvider = nowProvider ?? (() => DateTime.now().toUtc());

  static const String _campaignRunsKey = 'security.campaign_runs.v1';
  static const int _maxStoredRuns = 96;

  final GovernedRunKernelService _governedRunKernel;
  final SecurityCampaignRegistry _campaignRegistry;
  final ImmuneMemoryLedger _immuneMemoryLedger;
  final SecurityReplayHarness _replayHarness;
  final SecurityLearningMomentBridge? _learningMomentBridge;
  final SharedPreferencesCompat? _prefs;
  final DateTime Function() _nowProvider;

  List<SecurityCampaignRun> recentCampaignRuns({int limit = 20}) {
    final runs = _readRuns();
    final normalizedLimit = limit.clamp(0, runs.length);
    if (normalizedLimit == 0) {
      return const <SecurityCampaignRun>[];
    }
    return runs.take(normalizedLimit).toList(growable: false);
  }

  Future<SecurityCampaignRun> runCampaign({
    required String campaignId,
    required SecurityCampaignTrigger trigger,
    String actorAlias = 'security_kernel',
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) async {
    final definition = _campaignRegistry.definitionById(campaignId);
    if (definition == null) {
      throw StateError('Unknown security campaign: $campaignId');
    }
    final now = _nowProvider();
    final runId =
        'sec_${definition.laneId.toLowerCase()}_${now.millisecondsSinceEpoch}';
    final governedRunId = 'governed_$runId';
    final charter = GovernedRunCharter(
      id: '${runId}_charter',
      runKind: GovernedRunKind.securityRedteam,
      title: definition.name,
      objective: definition.description,
      hypothesis:
          'Continuous sandbox red-team should surface attack paths before production.',
      truthScope: definition.truthScope,
      authorityToken: 'security.redteam.bounded',
      environment: definition.environment,
      allowedExperimentSurfaces: <String>[
        definition.truthScope.sphereId,
        definition.truthScope.familyId,
      ],
      successMetrics: const <String>[
        'deterministic_evidence_captured',
        'findings_scoped',
        'learning_moment_recorded',
      ],
      stopConditions: const <String>[
        'air_gap_violation_attempt',
        'scope_escalation_without_approval',
      ],
      hardBans: const <String>[
        'production_mutation',
        'surveillance_scope_expansion',
      ],
      killConditions: const <String>[
        'invariant_breach',
        'repeated_failed_containment_within_ttl',
      ],
      rollbackRefs: const <String>[],
      budget: const GovernedRunBudget(
        maxRuntime: Duration(minutes: 5),
        maxStepCount: 64,
        maxToolInvocations: 24,
        maxEgressRequests: 0,
        maxParallelWorkers: 1,
      ),
      createdAt: now,
      updatedAt: now,
      approvedBy: actorAlias,
      approvedAt: now,
    );

    final governedRun = GovernedRunRecord(
      id: governedRunId,
      title: definition.name,
      hypothesis:
          'Security campaign ${definition.laneId} should stay bounded and evidence-rich.',
      runKind: GovernedRunKind.securityRedteam,
      ownerAgentAlias: actorAlias,
      lifecycleState: GovernedRunLifecycleState.running,
      environment: definition.environment,
      disposition: GovernedRunDisposition.observe,
      truthScope: definition.truthScope,
      authorityToken: 'security.redteam.bounded',
      charter: charter,
      requiresAdminApproval: definition.releaseBlocking,
      sandboxOnly:
          definition.environment != GovernedRunEnvironment.productionControlled,
      modelVersion: 'security-kernel-v1',
      policyVersion: 'immune-policy-v1',
      metrics: const <String, double>{},
      tags: <String>[definition.laneId, definition.cadence.name],
      directives: <GovernedRunDirective>[
        GovernedRunDirective(
          id: '${runId}_start',
          runId: governedRunId,
          kind: GovernedRunDirectiveKind.startRun,
          actorAlias: actorAlias,
          rationale: 'Security red-team campaign started.',
          createdAt: now,
          modelVersion: 'security-kernel-v1',
          policyVersion: 'immune-policy-v1',
          details: <String, dynamic>{
            'trigger': trigger.name,
            'campaign_id': definition.id,
          },
        ),
      ],
      checkpoints: const <GovernedRunCheckpoint>[],
      createdAt: now,
      updatedAt: now,
      latestSummary: 'Campaign queued for governed sandbox execution.',
      metadata: <String, dynamic>{
        'campaign_id': definition.id,
        'lane_id': definition.laneId,
        ...definition.metadata,
        ...metadata,
      },
    );
    await _governedRunKernel.upsertSecurityRun(governedRun);

    final replayPack = await _replayHarness.runReplayPack(definition);
    final findings = await _deriveFindings(
      definition: definition,
      runId: runId,
      replayPack: replayPack,
    );
    final disposition = _resolveDisposition(findings);
    for (final finding in findings) {
      await _immuneMemoryLedger.recordFinding(finding);
      final moment = await _immuneMemoryLedger.recordLearningMomentForFinding(
        finding: finding,
        kind: SecurityLearningMomentKind.finding,
      );
      await _learningMomentBridge?.recordMoment(moment);
      if (finding.severity == SecurityFindingSeverity.high ||
          finding.severity == SecurityFindingSeverity.critical) {
        await _immuneMemoryLedger.captureFindingAsImmuneMemory(finding);
      }
    }

    final completedAt = _nowProvider();
    final finalRun = SecurityCampaignRun(
      runId: runId,
      definitionId: definition.id,
      governedRunId: governedRunId,
      truthScope: definition.truthScope,
      status: findings.isEmpty && replayPack.autoClearEligible
          ? SecurityCampaignStatus.completed
          : SecurityCampaignStatus.review,
      trigger: trigger,
      disposition: disposition,
      startedAt: now,
      completedAt: completedAt,
      findingCount: findings.length,
      highestSeverity: findings.isEmpty
          ? SecurityFindingSeverity.info
          : findings.map((entry) => entry.severity).reduce(_maxSeverity),
      proofCoverageScore: replayPack.coverageScore,
      autoClearEligible: replayPack.autoClearEligible && findings.isEmpty,
      proofBundle: jsonEncode(replayPack.toJson()),
      missingScenarioIds: replayPack.missingScenarioIds,
      missingProofKinds: replayPack.missingProofKinds,
      metadata: <String, dynamic>{
        'release_blocking': definition.releaseBlocking,
        'mapped_scenario_ids': definition.mappedScenarioIds,
        'finding_ids': findings.map((entry) => entry.id).toList(),
        'proof_refs': replayPack.proofRefs,
      },
    );
    await _persistRun(finalRun);

    final directiveKind = switch (disposition) {
      SecurityInterventionDisposition.observe =>
        GovernedRunDirectiveKind.observe,
      SecurityInterventionDisposition.boundedDegrade =>
        GovernedRunDirectiveKind.boundedDegrade,
      SecurityInterventionDisposition.hardStop =>
        GovernedRunDirectiveKind.hardStop,
    };
    final lifecycleState = switch (disposition) {
      SecurityInterventionDisposition.observe => findings.isEmpty
          ? GovernedRunLifecycleState.completed
          : GovernedRunLifecycleState.review,
      SecurityInterventionDisposition.boundedDegrade =>
        GovernedRunLifecycleState.review,
      SecurityInterventionDisposition.hardStop =>
        GovernedRunLifecycleState.failed,
    };
    await _governedRunKernel.appendDirective(
      runId: governedRunId,
      directive: GovernedRunDirective(
        id: '${runId}_final',
        runId: governedRunId,
        kind: directiveKind,
        actorAlias: actorAlias,
        rationale: findings.isEmpty
            ? 'Campaign completed without findings.'
            : findings.first.summary,
        createdAt: completedAt,
        modelVersion: 'security-kernel-v1',
        policyVersion: 'immune-policy-v1',
        details: <String, dynamic>{
          'campaign_run_id': runId,
          'finding_count': findings.length,
          'proof_coverage_score': replayPack.coverageScore,
          'auto_clear_eligible': replayPack.autoClearEligible,
        },
      ),
      disposition: _governedDisposition(disposition),
      lifecycleState: lifecycleState,
      latestSummary: findings.isEmpty
          ? 'Campaign completed cleanly.'
          : 'Campaign produced ${findings.length} finding(s).',
    );
    return finalRun;
  }

  Future<List<SecurityFinding>> _deriveFindings({
    required SecurityCampaignDefinition definition,
    required String runId,
    required SecurityReplayPackSummary replayPack,
  }) async {
    final now = _nowProvider();
    final findings = <SecurityFinding>[];
    if (replayPack.missingScenarioIds.isNotEmpty ||
        replayPack.missingProofKinds.isNotEmpty) {
      findings.add(
        SecurityFinding(
          id: '${runId}_finding_harness',
          campaignRunId: runId,
          truthScope: definition.truthScope,
          severity: SecurityFindingSeverity.warning,
          title: 'Harness coverage incomplete',
          summary:
              'Campaign executed without complete deterministic replay coverage for ${definition.laneId}.',
          disposition: SecurityInterventionDisposition.observe,
          confidence: 0.42,
          createdAt: now,
          recurrenceCount: 0,
          invariantBreach: false,
          evidenceTraceIds: <String>[runId, definition.laneId],
          blockedControls: const <String>[],
          metadata: <String, dynamic>{
            'missing_scenarios': replayPack.missingScenarioIds,
            'missing_proof_kinds': replayPack.missingProofKinds
                .map((entry) => entry.name)
                .toList(),
            'release_blocking': definition.releaseBlocking,
          },
        ),
      );
    }
    if (replayPack.failedScenarioIds.isNotEmpty) {
      findings.add(
        SecurityFinding(
          id: '${runId}_finding_failure',
          campaignRunId: runId,
          truthScope: definition.truthScope,
          severity: definition.releaseBlocking
              ? SecurityFindingSeverity.high
              : SecurityFindingSeverity.warning,
          title: '${definition.name} surfaced a bounded failure',
          summary:
              'Replay failures detected in ${replayPack.failedScenarioIds.join(", ")}.',
          disposition: SecurityInterventionDisposition.boundedDegrade,
          confidence: 0.82,
          createdAt: now,
          recurrenceCount: replayPack.failedScenarioIds.length,
          invariantBreach: false,
          evidenceTraceIds: <String>[runId, definition.laneId],
          blockedControls: <String>[
            if (definition.releaseBlocking) 'autonomous_scope_expansion',
          ],
          metadata: <String, dynamic>{
            'failed_scenarios': replayPack.failedScenarioIds,
            'coverage_score': replayPack.coverageScore,
            'proof_refs': replayPack.proofRefs,
            'release_blocking': definition.releaseBlocking,
          },
        ),
      );
    }
    return findings;
  }

  SecurityInterventionDisposition _resolveDisposition(
    List<SecurityFinding> findings,
  ) {
    if (findings.any((entry) => entry.invariantBreach)) {
      return SecurityInterventionDisposition.hardStop;
    }
    if (findings.any(
      (entry) => entry.disposition == SecurityInterventionDisposition.hardStop,
    )) {
      return SecurityInterventionDisposition.hardStop;
    }
    if (findings.any(
      (entry) =>
          entry.disposition == SecurityInterventionDisposition.boundedDegrade,
    )) {
      return SecurityInterventionDisposition.boundedDegrade;
    }
    return SecurityInterventionDisposition.observe;
  }

  Future<void> _persistRun(SecurityCampaignRun run) async {
    final prefs = _prefs;
    if (prefs == null) {
      return;
    }
    final runs = _readRuns().toList(growable: true);
    runs.removeWhere((entry) => entry.runId == run.runId);
    runs.insert(0, run);
    if (runs.length > _maxStoredRuns) {
      runs.removeRange(_maxStoredRuns, runs.length);
    }
    await prefs.setString(
      _campaignRunsKey,
      jsonEncode(
        runs.map((entry) => entry.toJson()).toList(growable: false),
      ),
    );
  }

  List<SecurityCampaignRun> _readRuns() {
    final prefs = _prefs;
    if (prefs == null) {
      return const <SecurityCampaignRun>[];
    }
    final raw = prefs.getString(_campaignRunsKey);
    if (raw == null || raw.isEmpty) {
      return const <SecurityCampaignRun>[];
    }
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const <SecurityCampaignRun>[];
    }
    return decoded
        .whereType<Map>()
        .map(
          (entry) => SecurityCampaignRun.fromJson(
            Map<String, dynamic>.from(entry),
          ),
        )
        .toList(growable: false);
  }

  SecurityFindingSeverity _maxSeverity(
    SecurityFindingSeverity left,
    SecurityFindingSeverity right,
  ) {
    return left.index >= right.index ? left : right;
  }

  GovernedRunDisposition _governedDisposition(
    SecurityInterventionDisposition disposition,
  ) {
    return switch (disposition) {
      SecurityInterventionDisposition.observe => GovernedRunDisposition.observe,
      SecurityInterventionDisposition.boundedDegrade =>
        GovernedRunDisposition.boundedDegrade,
      SecurityInterventionDisposition.hardStop =>
        GovernedRunDisposition.hardStop,
    };
  }
}
