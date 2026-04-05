import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/admin/governed_run_kernel_service.dart';
import 'package:avrai_runtime_os/services/security/immune_memory_ledger.dart';
import 'package:avrai_runtime_os/services/security/sandbox_orchestrator_service.dart';
import 'package:avrai_runtime_os/services/security/security_campaign_registry.dart';
import 'package:avrai_runtime_os/services/security/security_campaign_scheduler.dart';
import 'package:avrai_runtime_os/services/security/security_promotion_gate_target.dart';
import 'package:avrai_runtime_os/services/security/security_trigger_ingress_service.dart';

class SecurityKernelReleaseGateSnapshot {
  const SecurityKernelReleaseGateSnapshot({
    required this.generatedAt,
    required this.servingAllowed,
    required this.degradedReleaseAllowed,
    required this.reasonCodes,
    required this.blockingCampaignIds,
    required this.hardStopRunIds,
    required this.blockingBundleIds,
  });

  final DateTime generatedAt;
  final bool servingAllowed;
  final bool degradedReleaseAllowed;
  final List<String> reasonCodes;
  final List<String> blockingCampaignIds;
  final List<String> hardStopRunIds;
  final List<String> blockingBundleIds;
}

class SecurityKernelReleaseGateService {
  SecurityKernelReleaseGateService({
    required SecurityCampaignScheduler campaignScheduler,
    required SecurityCampaignRegistry campaignRegistry,
    required SandboxOrchestratorService sandboxOrchestrator,
    required ImmuneMemoryLedger immuneMemoryLedger,
    required GovernedRunKernelService governedRunKernel,
    required SecurityTriggerIngressService triggerIngressService,
    DateTime Function()? nowProvider,
  })  : _campaignScheduler = campaignScheduler,
        _campaignRegistry = campaignRegistry,
        _sandboxOrchestrator = sandboxOrchestrator,
        _immuneMemoryLedger = immuneMemoryLedger,
        _governedRunKernel = governedRunKernel,
        _triggerIngressService = triggerIngressService,
        _nowProvider = nowProvider ?? (() => DateTime.now().toUtc());

  final SecurityCampaignScheduler _campaignScheduler;
  final SecurityCampaignRegistry _campaignRegistry;
  final SandboxOrchestratorService _sandboxOrchestrator;
  final ImmuneMemoryLedger _immuneMemoryLedger;
  final GovernedRunKernelService _governedRunKernel;
  final SecurityTriggerIngressService _triggerIngressService;
  final DateTime Function() _nowProvider;

  Future<SecurityKernelReleaseGateSnapshot> evaluateModelPromotion({
    required String surfaceId,
    required String version,
    String actorAlias = 'security_kernel',
    bool operatorApproved = false,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) async {
    await _queueModelPromotion(
      surfaceId: surfaceId,
      version: version,
      actorAlias: actorAlias,
      metadata: <String, dynamic>{
        'promotion_target': SecurityPromotionGateTarget.model.name,
        ...metadata,
      },
    );
    return _flushAndSnapshot(operatorApproved: operatorApproved);
  }

  Future<SecurityKernelReleaseGateSnapshot> evaluatePolicyPromotion({
    required String policyId,
    required TruthScopeDescriptor scope,
    String actorAlias = 'security_kernel',
    bool operatorApproved = false,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) async {
    await _queuePolicyPromotion(
      policyId: policyId,
      scope: scope,
      actorAlias: actorAlias,
      metadata: <String, dynamic>{
        'promotion_target': SecurityPromotionGateTarget.policy.name,
        ...metadata,
      },
    );
    return _flushAndSnapshot(operatorApproved: operatorApproved);
  }

  Future<SecurityKernelReleaseGateSnapshot> evaluateReleaseManifestPromotion({
    required String manifestId,
    required TruthScopeDescriptor scope,
    String actorAlias = 'security_kernel',
    bool operatorApproved = false,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) async {
    await _queuePolicyPromotion(
      policyId: manifestId,
      scope: scope,
      actorAlias: actorAlias,
      metadata: <String, dynamic>{
        'promotion_target': SecurityPromotionGateTarget.releaseManifest.name,
        ...metadata,
      },
    );
    return _flushAndSnapshot(operatorApproved: operatorApproved);
  }

  Future<SecurityKernelReleaseGateSnapshot> evaluateRuntimeBundleActivation({
    required String bundleId,
    required TruthScopeDescriptor scope,
    String actorAlias = 'security_kernel',
    bool operatorApproved = false,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) async {
    await _queuePolicyPromotion(
      policyId: bundleId,
      scope: scope,
      actorAlias: actorAlias,
      metadata: <String, dynamic>{
        'promotion_target': SecurityPromotionGateTarget.runtimeBundle.name,
        ...metadata,
      },
    );
    return _flushAndSnapshot(
      operatorApproved: operatorApproved,
      ignoreBundleIds: <String>{bundleId},
    );
  }

  Future<SecurityKernelReleaseGateSnapshot> getSnapshot({
    bool operatorApproved = false,
  }) async {
    return _buildSnapshot(
      operatorApproved: operatorApproved,
      ignoreBundleIds: const <String>{},
    );
  }

  Future<SecurityKernelReleaseGateSnapshot> _buildSnapshot({
    required bool operatorApproved,
    required Set<String> ignoreBundleIds,
  }) async {
    final recentRuns = _sandboxOrchestrator.recentCampaignRuns(limit: 64);
    final governedRuns = await _governedRunKernel.listRuns();
    final reasons = <String>[];
    final blockingCampaignIds = <String>[];
    final blockingBundleIds = <String>[];
    final hardStopRunIds = governedRuns
        .where((entry) => entry.disposition == GovernedRunDisposition.hardStop)
        .map((entry) => entry.id)
        .toList(growable: false);

    final blockingRuns = recentRuns.where((run) {
      final definition = _campaignRegistry.definitionById(run.definitionId);
      if (definition?.releaseBlocking != true) {
        return false;
      }
      return run.disposition != SecurityInterventionDisposition.observe ||
          !run.autoClearEligible ||
          run.missingScenarioIds.isNotEmpty ||
          run.missingProofKinds.isNotEmpty;
    }).toList(growable: false);
    if (blockingRuns.isNotEmpty) {
      reasons.add('release_blocking_campaigns_red');
      blockingCampaignIds.addAll(
        blockingRuns.map((entry) => entry.definitionId).toSet(),
      );
    }

    final requiredBundles = _immuneMemoryLedger
        .bundleCandidates(limit: 64)
        .where(
          (entry) =>
              !ignoreBundleIds.contains(entry.bundle.bundleId) &&
              (entry.bundle.metadata['required_for_promotion'] == true ||
                  entry.metadata['required_for_promotion'] == true),
        )
        .toList(growable: false);
    for (final bundle in requiredBundles) {
      if ((bundle.bundle.signature ?? '').isEmpty ||
          bundle.bundle.signedAt == null ||
          (bundle.bundle.expiresAt != null &&
              _nowProvider().isAfter(bundle.bundle.expiresAt!))) {
        blockingBundleIds.add(bundle.bundle.bundleId);
        continue;
      }
      final receipts = _immuneMemoryLedger.propagationReceiptsForBundle(
        bundle.bundle.bundleId,
      );
      if (receipts.any(
        (entry) =>
            entry.staleNode ||
            entry.rolledBack ||
            entry.activationStage != 'active',
      )) {
        blockingBundleIds.add(bundle.bundle.bundleId);
      }
    }
    if (blockingBundleIds.isNotEmpty) {
      reasons.add('required_bundles_not_active');
    }
    if (hardStopRunIds.isNotEmpty) {
      reasons.add('critical_governed_run_hard_stop');
    }

    final onlyBoundedDegrade = blockingRuns.isNotEmpty &&
        blockingRuns.every(
          (entry) =>
              entry.disposition ==
              SecurityInterventionDisposition.boundedDegrade,
        ) &&
        blockingBundleIds.isEmpty &&
        hardStopRunIds.isEmpty;
    final degradedReleaseAllowed = onlyBoundedDegrade && operatorApproved;
    final servingAllowed = reasons.isEmpty || degradedReleaseAllowed;

    if (onlyBoundedDegrade && !operatorApproved) {
      reasons.add('operator_approval_required_for_degraded_release');
    }

    return SecurityKernelReleaseGateSnapshot(
      generatedAt: _nowProvider(),
      servingAllowed: servingAllowed,
      degradedReleaseAllowed: degradedReleaseAllowed,
      reasonCodes: reasons.toSet().toList(growable: false),
      blockingCampaignIds: blockingCampaignIds,
      hardStopRunIds: hardStopRunIds,
      blockingBundleIds: blockingBundleIds,
    );
  }

  Future<void> _queueModelPromotion({
    required String surfaceId,
    required String version,
    required String actorAlias,
    required Map<String, dynamic> metadata,
  }) {
    return _triggerIngressService.notifyModelPromotion(
      surfaceId: surfaceId,
      version: version,
      actorAlias: actorAlias,
      metadata: metadata,
    );
  }

  Future<void> _queuePolicyPromotion({
    required String policyId,
    required TruthScopeDescriptor scope,
    required String actorAlias,
    required Map<String, dynamic> metadata,
  }) {
    return _triggerIngressService.notifyPolicyPromotion(
      policyId: policyId,
      scope: scope,
      actorAlias: actorAlias,
      metadata: metadata,
    );
  }

  Future<SecurityKernelReleaseGateSnapshot> _flushAndSnapshot({
    required bool operatorApproved,
    Set<String> ignoreBundleIds = const <String>{},
  }) async {
    await _campaignScheduler.flushPendingTriggers();
    return _buildSnapshot(
      operatorApproved: operatorApproved,
      ignoreBundleIds: ignoreBundleIds,
    );
  }
}
