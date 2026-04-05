import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/admin/governed_run_kernel_service.dart';
import 'package:avrai_runtime_os/services/security/security_autonomy_impact_policy.dart';
import 'package:avrai_runtime_os/services/security/security_learning_moment_bridge.dart';

class SelfHealGovernanceAdapterService {
  SelfHealGovernanceAdapterService({
    required GovernedRunKernelService governedRunKernel,
    SecurityAutonomyImpactPolicy? impactPolicy,
    SecurityLearningMomentBridge? learningMomentBridge,
    DateTime Function()? nowProvider,
  })  : _governedRunKernel = governedRunKernel,
        _impactPolicy = impactPolicy ?? const SecurityAutonomyImpactPolicy(),
        _learningMomentBridge = learningMomentBridge,
        _nowProvider = nowProvider ?? (() => DateTime.now().toUtc());

  final GovernedRunKernelService _governedRunKernel;
  final SecurityAutonomyImpactPolicy _impactPolicy;
  final SecurityLearningMomentBridge? _learningMomentBridge;
  final DateTime Function() _nowProvider;

  Future<GovernedRunRecord> startRecoveryRun({
    required TruthScopeDescriptor truthScope,
    required String title,
    required String objective,
    String actorAlias = 'self_heal',
    GovernedRunEnvironment environment = GovernedRunEnvironment.shadow,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) async {
    final now = _nowProvider();
    final budgetMultiplier =
        _learningMomentBridge?.budgetMultiplierForScope(truthScope) ?? 1.0;
    final budget = GovernedRunBudget(
      maxRuntime: Duration(
        minutes: (10 * budgetMultiplier.clamp(0.25, 1.0)).round(),
      ),
      maxStepCount: (48 * budgetMultiplier.clamp(0.25, 1.0)).round(),
      maxToolInvocations: (16 * budgetMultiplier.clamp(0.25, 1.0)).round(),
      maxEgressRequests: 0,
      maxParallelWorkers: 1,
    );
    final runId = 'self_heal_${now.microsecondsSinceEpoch}';
    final run = GovernedRunRecord(
      id: runId,
      title: title,
      hypothesis: objective,
      runKind: GovernedRunKind.selfHeal,
      ownerAgentAlias: actorAlias,
      lifecycleState: GovernedRunLifecycleState.running,
      environment: environment,
      disposition: GovernedRunDisposition.observe,
      truthScope: truthScope,
      authorityToken: 'self_heal.bounded',
      charter: GovernedRunCharter(
        id: '${runId}_charter',
        runKind: GovernedRunKind.selfHeal,
        title: title,
        objective: objective,
        hypothesis:
            'Self-heal should recover the scoped lane without widening authority.',
        truthScope: truthScope,
        authorityToken: 'self_heal.bounded',
        environment: environment,
        allowedExperimentSurfaces: <String>[
          truthScope.sphereId,
          truthScope.familyId,
        ],
        successMetrics: const <String>[
          'recovery_stable',
          'scope_preserved',
        ],
        stopConditions: const <String>[
          'security_hard_stop',
          'scope_expansion_attempt',
        ],
        hardBans: const <String>[
          'tenant_widening',
          'production_mutation_without_approval',
        ],
        killConditions: const <String>[
          'invariant_breach',
        ],
        rollbackRefs: const <String>[],
        budget: budget,
        createdAt: now,
        updatedAt: now,
        approvedBy: actorAlias,
        approvedAt: now,
      ),
      requiresAdminApproval: false,
      sandboxOnly: environment != GovernedRunEnvironment.productionControlled,
      modelVersion: 'self-heal-v1',
      policyVersion: 'immune-policy-v1',
      metrics: <String, double>{
        'budget_multiplier': budgetMultiplier,
      },
      tags: const <String>['self_heal'],
      directives: <GovernedRunDirective>[
        GovernedRunDirective(
          id: '${runId}_start',
          runId: runId,
          kind: GovernedRunDirectiveKind.startRun,
          actorAlias: actorAlias,
          rationale: 'Self-heal recovery started.',
          createdAt: now,
          modelVersion: 'self-heal-v1',
          policyVersion: 'immune-policy-v1',
          details: metadata,
        ),
      ],
      checkpoints: const <GovernedRunCheckpoint>[],
      createdAt: now,
      updatedAt: now,
      latestSummary: 'Scoped self-heal recovery running.',
      metadata: metadata,
    );
    return _governedRunKernel.upsertSelfHealRun(run);
  }

  Future<GovernedRunRecord> applySecurityDisposition({
    required String runId,
    required SecurityInterventionDisposition disposition,
    required GovernedRunEnvironment currentEnvironment,
    String actorAlias = 'security_kernel',
    String rationale = '',
  }) async {
    final impact = _impactPolicy.evaluate(
      disposition: disposition,
      currentEnvironment: currentEnvironment,
    );
    final directiveKind = switch (disposition) {
      SecurityInterventionDisposition.observe =>
        GovernedRunDirectiveKind.observe,
      SecurityInterventionDisposition.boundedDegrade =>
        GovernedRunDirectiveKind.redirectRun,
      SecurityInterventionDisposition.hardStop =>
        GovernedRunDirectiveKind.triggerKillSwitch,
    };
    final lifecycleState = switch (disposition) {
      SecurityInterventionDisposition.observe =>
        GovernedRunLifecycleState.running,
      SecurityInterventionDisposition.boundedDegrade =>
        GovernedRunLifecycleState.review,
      SecurityInterventionDisposition.hardStop =>
        GovernedRunLifecycleState.failed,
    };
    final governedDisposition = switch (disposition) {
      SecurityInterventionDisposition.observe => GovernedRunDisposition.observe,
      SecurityInterventionDisposition.boundedDegrade =>
        GovernedRunDisposition.boundedDegrade,
      SecurityInterventionDisposition.hardStop =>
        GovernedRunDisposition.hardStop,
    };
    return _governedRunKernel.appendDirective(
      runId: runId,
      directive: GovernedRunDirective(
        id: '${runId}_${disposition.name}_${_nowProvider().microsecondsSinceEpoch}',
        runId: runId,
        kind: directiveKind,
        actorAlias: actorAlias,
        rationale: rationale.isEmpty ? impact.rationale : rationale,
        createdAt: _nowProvider(),
        modelVersion: 'self-heal-v1',
        policyVersion: 'immune-policy-v1',
        details: <String, dynamic>{
          'budget_multiplier': impact.budgetMultiplier,
          'freeze_promotion': impact.freezePromotion,
          if (impact.redirectEnvironment != null)
            'redirect_environment': impact.redirectEnvironment!.name,
        },
      ),
      disposition: governedDisposition,
      lifecycleState: lifecycleState,
      latestSummary: rationale.isEmpty ? impact.rationale : rationale,
    );
  }
}
