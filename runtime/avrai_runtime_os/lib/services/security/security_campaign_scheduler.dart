import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/security/sandbox_orchestrator_service.dart';
import 'package:avrai_runtime_os/services/security/security_campaign_registry.dart';
import 'package:avrai_runtime_os/services/security/security_trigger_ingress_service.dart';

class SecurityCampaignScheduler {
  SecurityCampaignScheduler({
    required SecurityCampaignRegistry campaignRegistry,
    required SandboxOrchestratorService sandboxOrchestrator,
    SecurityTriggerIngressService? triggerIngressService,
    DateTime Function()? nowProvider,
  })  : _campaignRegistry = campaignRegistry,
        _sandboxOrchestrator = sandboxOrchestrator,
        _triggerIngressService = triggerIngressService,
        _nowProvider = nowProvider ?? (() => DateTime.now().toUtc());

  final SecurityCampaignRegistry _campaignRegistry;
  final SandboxOrchestratorService _sandboxOrchestrator;
  final SecurityTriggerIngressService? _triggerIngressService;
  final DateTime Function() _nowProvider;

  List<SecurityCampaignDefinition> dueCampaigns() {
    final now = _nowProvider();
    final recentRuns = _sandboxOrchestrator.recentCampaignRuns(limit: 96);
    return _campaignRegistry.definitions().where((definition) {
      final matchingRun = recentRuns.where(
        (entry) => entry.definitionId == definition.id,
      );
      if (matchingRun.isEmpty) {
        return true;
      }
      final lastRun = matchingRun.first;
      final dueAfter = switch (definition.cadence) {
        SecurityCampaignCadence.onDemand => const Duration(days: 3650),
        SecurityCampaignCadence.hourly => const Duration(hours: 1),
        SecurityCampaignCadence.daily => const Duration(days: 1),
        SecurityCampaignCadence.weekly => const Duration(days: 7),
        SecurityCampaignCadence.releaseBlocking => const Duration(hours: 12),
      };
      return now.difference(lastRun.startedAt) >= dueAfter;
    }).toList(growable: false);
  }

  Future<List<SecurityCampaignRun>> triggerScheduledCampaigns() async {
    final results = <SecurityCampaignRun>[];
    for (final definition in dueCampaigns()) {
      results.add(
        await _sandboxOrchestrator.runCampaign(
          campaignId: definition.id,
          trigger: SecurityCampaignTrigger.schedule,
        ),
      );
    }
    return results;
  }

  Future<List<SecurityCampaignRun>> flushPendingTriggers() async {
    final ingress = _triggerIngressService;
    if (ingress == null) {
      return const <SecurityCampaignRun>[];
    }
    final pending = await ingress.flushPendingTriggers();
    final results = <SecurityCampaignRun>[];
    for (final entry in pending) {
      results.add(
        await _sandboxOrchestrator.runCampaign(
          campaignId: entry.campaignId,
          trigger: entry.trigger,
          actorAlias: entry.actorAlias,
          metadata: entry.metadata,
        ),
      );
    }
    return results;
  }

  Future<List<SecurityCampaignRun>> runPendingAndDueCampaigns() async {
    final pending = await flushPendingTriggers();
    final scheduled = await triggerScheduledCampaigns();
    return <SecurityCampaignRun>[
      ...pending,
      ...scheduled,
    ];
  }

  Future<List<SecurityCampaignRun>> triggerReleaseBlockingCampaigns({
    SecurityCampaignTrigger trigger = SecurityCampaignTrigger.policyPromotion,
  }) async {
    final results = <SecurityCampaignRun>[];
    for (final definition in _campaignRegistry.releaseBlockingDefinitions()) {
      if (!definition.triggers.contains(trigger)) {
        continue;
      }
      results.add(
        await _sandboxOrchestrator.runCampaign(
          campaignId: definition.id,
          trigger: trigger,
        ),
      );
    }
    return results;
  }

  bool hasBlockingFailures() {
    return _sandboxOrchestrator.recentCampaignRuns(limit: 32).any(
          (run) =>
              ((run.status == SecurityCampaignStatus.review &&
                      run.disposition !=
                          SecurityInterventionDisposition.observe) ||
                  !run.autoClearEligible ||
                  run.missingScenarioIds.isNotEmpty ||
                  run.missingProofKinds.isNotEmpty) &&
              _campaignRegistry
                      .definitionById(run.definitionId)
                      ?.releaseBlocking ==
                  true,
        );
  }
}
