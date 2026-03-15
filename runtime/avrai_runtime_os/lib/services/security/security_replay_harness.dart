import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/validation/domain_execution_field_scenario_runner.dart';
import 'package:avrai_runtime_os/services/validation/domain_execution_field_scenario_proof_store.dart';

class SecurityReplayHarness {
  const SecurityReplayHarness({
    DomainExecutionFieldScenarioRunner? scenarioRunner,
    DomainExecutionFieldScenarioProofStore? proofStore,
  })  : _scenarioRunner = scenarioRunner,
        _proofStore = proofStore;

  final DomainExecutionFieldScenarioRunner? _scenarioRunner;
  final DomainExecutionFieldScenarioProofStore? _proofStore;

  bool get isAvailable => _scenarioRunner != null;

  Future<SecurityReplayPackSummary> runReplayPack(
    SecurityCampaignDefinition definition,
  ) async {
    final executedScenarioIds = <String>[];
    final passedScenarioIds = <String>[];
    final failedScenarioIds = <String>[];
    final missingScenarioIds = <String>[];
    final coveredProofKinds = <SecurityProofKind>{};
    final proofRefs = <String>[];

    for (final scenarioId in definition.mappedScenarioIds) {
      final proof = await runMappedScenario(scenarioId);
      if (proof == null) {
        missingScenarioIds.add(scenarioId);
        continue;
      }
      executedScenarioIds.add(scenarioId);
      proofRefs.add('${proof.scenario.name}:${proof.summary}');
      coveredProofKinds.addAll(_proofKindsForScenario(proof.scenario));
      if (proof.passed) {
        passedScenarioIds.add(scenarioId);
      } else {
        failedScenarioIds.add(scenarioId);
      }
    }

    final scenarioCoverage = definition.mappedScenarioIds.isEmpty
        ? 0.0
        : executedScenarioIds.length / definition.mappedScenarioIds.length;
    final proofCoverage = definition.requiredProofKinds.isEmpty
        ? 1.0
        : coveredProofKinds
                .where(definition.requiredProofKinds.contains)
                .length /
            definition.requiredProofKinds.length;
    final coverageScore =
        ((scenarioCoverage + proofCoverage) / 2).clamp(0.0, 1.0);

    return SecurityReplayPackSummary(
      executedScenarioIds: executedScenarioIds,
      passedScenarioIds: passedScenarioIds,
      failedScenarioIds: failedScenarioIds,
      missingScenarioIds: missingScenarioIds,
      requiredProofKinds: definition.requiredProofKinds,
      coveredProofKinds: definition.requiredProofKinds
          .where(coveredProofKinds.contains)
          .toList(growable: false),
      proofRefs: proofRefs,
      coverageScore: coverageScore,
    );
  }

  Future<DomainExecutionFieldScenarioProof?> runMappedScenario(
    String? mappedScenarioId,
  ) async {
    final runner = _scenarioRunner;
    if (runner == null ||
        mappedScenarioId == null ||
        mappedScenarioId.isEmpty) {
      return null;
    }
    final scenario = DomainExecutionFieldScenario.values.where(
      (value) => value.name == mappedScenarioId,
    );
    if (scenario.isEmpty) {
      return null;
    }
    return runner.run(scenario.first);
  }

  DomainExecutionFieldScenarioProof? latestProofForMappedScenario(
    String? mappedScenarioId,
  ) {
    final proofStore = _proofStore;
    if (proofStore == null ||
        mappedScenarioId == null ||
        mappedScenarioId.isEmpty) {
      return null;
    }
    final scenario = DomainExecutionFieldScenario.values.where(
      (value) => value.name == mappedScenarioId,
    );
    if (scenario.isEmpty) {
      return null;
    }
    return proofStore.latestForScenario(scenario.first);
  }

  List<SecurityProofKind> _proofKindsForScenario(
    DomainExecutionFieldScenario scenario,
  ) {
    switch (scenario) {
      case DomainExecutionFieldScenario.directNearbyDeliveryWithReadReceipt:
      case DomainExecutionFieldScenario.custodyQueuedPeerReturns:
      case DomainExecutionFieldScenario.hybridCloudFallback:
      case DomainExecutionFieldScenario.threeDeviceRelaySelection:
      case DomainExecutionFieldScenario.deferredExchangePeerTruthAfterRelease:
        return const <SecurityProofKind>[
          SecurityProofKind.transportConformance,
        ];
      case DomainExecutionFieldScenario.privateMeshRejectsCloudRescue:
      case DomainExecutionFieldScenario
            .deferredRendezvousBlockedByTrustedRouteUnavailable:
        return const <SecurityProofKind>[
          SecurityProofKind.governanceBoundary,
        ];
      case DomainExecutionFieldScenario.learningAppliedAfterGovernedIntake:
        return const <SecurityProofKind>[
          SecurityProofKind.learningPath,
          SecurityProofKind.governanceBoundary,
        ];
      case DomainExecutionFieldScenario.trustedDirectAnnounceRecovery:
      case DomainExecutionFieldScenario.trustedCloudAnnounceAccepted:
      case DomainExecutionFieldScenario.untrustedAnnounceRejected:
      case DomainExecutionFieldScenario.trustedHeardForwardRoutable:
      case DomainExecutionFieldScenario.trustedRelayRefreshRoutable:
        return const <SecurityProofKind>[
          SecurityProofKind.announceTrust,
        ];
      case DomainExecutionFieldScenario.ambientPassiveNearbyCandidateOnly:
      case DomainExecutionFieldScenario
            .ambientTrustedInteractionPromotesConfirmedPresence:
      case DomainExecutionFieldScenario.ambientDuplicateEvidenceMerged:
      case DomainExecutionFieldScenario.ambientUntrustedInteractionNotPromoted:
        return const <SecurityProofKind>[
          SecurityProofKind.ambientPromotion,
          SecurityProofKind.exportPrivacy,
        ];
    }
  }
}
