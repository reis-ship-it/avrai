import 'package:avrai_runtime_os/cloud/production_readiness_manager.dart';
import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/security/security_trigger_ingress_service.dart';

import 'functional_kernel_models.dart';
import 'functional_kernel_os.dart';

abstract class KernelIncidentRecorder {
  Future<KernelBundleRecord> recordProductionRecovery({
    required ProductionHealthReport healthReport,
    required RecoveryActionResult recoveryResult,
  });
}

class DefaultKernelIncidentRecorder implements KernelIncidentRecorder {
  const DefaultKernelIncidentRecorder({
    required FunctionalKernelOs functionalKernelOs,
    SecurityTriggerIngressService? securityTriggerIngressService,
  })  : _functionalKernelOs = functionalKernelOs,
        _securityTriggerIngressService = securityTriggerIngressService;

  final FunctionalKernelOs _functionalKernelOs;
  final SecurityTriggerIngressService? _securityTriggerIngressService;

  @override
  Future<KernelBundleRecord> recordProductionRecovery({
    required ProductionHealthReport healthReport,
    required RecoveryActionResult recoveryResult,
  }) async {
    final occurredAtUtc = recoveryResult.timestamp.toUtc();
    final record = await _functionalKernelOs.resolveAndExplain(
      envelope: KernelEventEnvelope(
        eventId:
            'incident:production_recovery:${occurredAtUtc.microsecondsSinceEpoch}',
        agentId: 'production_readiness_manager',
        occurredAtUtc: occurredAtUtc,
        sourceSystem: 'production_readiness',
        eventType: 'incident_recovery',
        actionType: 'perform_automated_recovery',
        entityId: 'production_runtime',
        entityType: 'runtime_cluster',
        context: <String, dynamic>{
          'critical_issue_count': healthReport.criticalIssues.length,
          'recovery_actions': recoveryResult.recoveryActions.keys.toList(),
          'overall_health_before': healthReport.overallHealth,
          'overall_health_after': recoveryResult.postRecoveryHealth,
          'deployment_health_score':
              healthReport.deploymentHealth.overallHealth,
        },
        runtimeContext: <String, dynamic>{
          'uptime_seconds': healthReport.uptime.inSeconds,
          'sla_compliant': healthReport.slaCompliance.compliant,
        },
      ),
      whyRequest: KernelWhyRequest(
        bundle: const KernelContextBundleWithoutWhy(),
        goal: 'perform_automated_recovery',
        actualOutcome: recoveryResult.overallSuccess
            ? 'recovery_succeeded'
            : 'recovery_degraded',
        actualOutcomeScore: recoveryResult.postRecoveryHealth,
        coreSignals: <WhySignal>[
          WhySignal(
            label: 'critical_issue_count',
            weight:
                -(healthReport.criticalIssues.length / 10.0).clamp(0.0, 1.0),
            source: 'what',
          ),
          WhySignal(
            label: 'health_improvement',
            weight: recoveryResult.healthImprovement.clamp(-1.0, 1.0),
            source: 'how',
          ),
        ],
        pheromoneSignals: recoveryResult.recoveryActions.entries
            .map(
              (entry) => WhySignal(
                label: entry.key,
                weight: entry.value ? 0.35 : -0.35,
                source: 'how',
                durable: false,
              ),
            )
            .toList(),
        memoryContext: <String, dynamic>{
          'recommendations': healthReport.recommendations,
          'critical_issue_ids': healthReport.criticalIssues
              .map((issue) => issue.issueId)
              .toList(),
        },
        severity: recoveryResult.overallSuccess ? 'high' : 'critical',
      ),
    );
    await _notifySecurityIncidentReplay(
      occurredAtUtc: occurredAtUtc,
      healthReport: healthReport,
      recoveryResult: recoveryResult,
    );
    return record;
  }

  Future<void> _notifySecurityIncidentReplay({
    required DateTime occurredAtUtc,
    required ProductionHealthReport healthReport,
    required RecoveryActionResult recoveryResult,
  }) async {
    final ingress = _securityTriggerIngressService;
    if (ingress == null) {
      return;
    }
    final tags = <String>{
      'incident',
      'recovery',
      'production',
      if (!recoveryResult.overallSuccess) 'degraded',
      if (healthReport.deploymentHealth.overallHealth < 0.98) 'rollout',
      if (healthReport.deploymentHealth.overallHealth < 0.95) 'autonomy',
      ...healthReport.criticalIssues
          .map((issue) => issue.issueId.toLowerCase())
          .expand(_tokenizeTagSource),
      ...recoveryResult.recoveryActions.keys.expand(_tokenizeTagSource),
    };
    final truthScope = _scopeForTags(tags);
    try {
      await ingress.notifyReplayedIncident(
        incidentId:
            'production_recovery_${occurredAtUtc.microsecondsSinceEpoch}',
        tags: tags.toList(growable: false),
        truthScope: truthScope,
        actorAlias: 'production_readiness_manager',
        metadata: <String, dynamic>{
          'critical_issue_ids': healthReport.criticalIssues
              .map((issue) => issue.issueId)
              .toList(),
          'recovery_actions': recoveryResult.recoveryActions.keys.toList(),
          'overall_health_before': healthReport.overallHealth,
          'overall_health_after': recoveryResult.postRecoveryHealth,
        },
      );
    } catch (_) {
      // Non-fatal. Incident recording should not fail if the security trigger
      // ingress path is temporarily unavailable.
    }
  }

  Iterable<String> _tokenizeTagSource(String raw) sync* {
    for (final token in raw.split(RegExp(r'[^a-zA-Z0-9]+'))) {
      final normalized = token.trim().toLowerCase();
      if (normalized.isNotEmpty) {
        yield normalized;
      }
    }
  }

  TruthScopeDescriptor _scopeForTags(Set<String> tags) {
    bool hasAny(Set<String> values) => values.any(tags.contains);
    if (hasAny(<String>{'mesh', 'announce', 'route', 'signal'})) {
      return const TruthScopeDescriptor.defaultSecurity(
        governanceStratum: GovernanceStratum.world,
        sphereId: 'security_transport',
        familyId: 'signal_lifecycle_downgrade',
      );
    }
    if (hasAny(<String>{'auth', 'session', 'login'})) {
      return const TruthScopeDescriptor.defaultSecurity(
        governanceStratum: GovernanceStratum.world,
        sphereId: 'security_auth',
        familyId: 'auth_session_takeover',
      );
    }
    if (hasAny(<String>{'export', 'privacy', 'reidentification'})) {
      return const TruthScopeDescriptor.defaultSecurity(
        governanceStratum: GovernanceStratum.universal,
        sphereId: 'security_exports',
        familyId: 'reidentification_simulation',
      );
    }
    if (hasAny(<String>{'secret', 'artifact', 'provenance', 'ci'})) {
      return const TruthScopeDescriptor.defaultSecurity(
        governanceStratum: GovernanceStratum.universal,
        sphereId: 'security_supply_chain',
        familyId: 'secrets_ci_compromise',
      );
    }
    if (hasAny(<String>{'admin', 'operator', 'break', 'glass', 'governance'})) {
      return const TruthScopeDescriptor.defaultSecurity(
        governanceStratum: GovernanceStratum.universal,
        sphereId: 'security_admin',
        familyId: 'admin_operator_abuse',
      );
    }
    if (hasAny(<String>{'learning', 'model', 'federated', 'poison'})) {
      return const TruthScopeDescriptor.defaultSecurity(
        governanceStratum: GovernanceStratum.world,
        sphereId: 'security_learning',
        familyId: 'federated_update_poisoning',
      );
    }
    return const TruthScopeDescriptor.defaultSecurity(
      governanceStratum: GovernanceStratum.universal,
      sphereId: 'security_autonomy',
      familyId: 'autonomy_hijack',
    );
  }
}
