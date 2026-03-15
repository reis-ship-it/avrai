import 'dart:convert';
import 'dart:io';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_network/avra_network.dart';
import 'package:avrai_runtime_os/kernel/ai2ai/ai2ai_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/mesh/mesh_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/os/domain_execution_conformance_service.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/monitoring/connection_monitor.dart';
import 'package:avrai_runtime_os/ml/predictive_analytics.dart';
import 'package:avrai_runtime_os/services/admin/admin_auth_service.dart';
import 'package:avrai_runtime_os/services/admin/admin_communication_service.dart';
import 'package:avrai_runtime_os/services/admin/admin_runtime_governance_service.dart';
import 'package:avrai_runtime_os/services/business/business_account_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai_runtime_os/services/passive_collection/passive_dwell_reality_learning_service.dart';
import 'package:avrai_runtime_os/services/transport/compatibility/transport_route_receipt_compatibility_translator.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_interface_registry.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_runtime_state_frame_service.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_runtime_state_frame_service.dart';
import 'package:avrai_runtime_os/services/validation/domain_execution_field_scenario_proof_store.dart';
import 'package:avrai_runtime_os/services/validation/domain_execution_field_scenario_runner.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory storageRoot;

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getApplicationDocumentsDirectory') {
          return '.';
        }
        return null;
      },
    );
    storageRoot =
        await Directory.systemTemp.createTemp('admin_runtime_governance_');
    await GetStorage('admin_runtime_governance', storageRoot.path).initStorage;
  });

  tearDownAll(() async {
    try {
      if (storageRoot.existsSync()) {
        await storageRoot.delete(recursive: true);
      }
    } on FileSystemException {
      // Ignore cleanup failures in temporary storage.
    }
  });

  group('AdminRuntimeGovernanceService', () {
    late SharedPreferencesCompat prefs;
    late DomainExecutionFieldScenarioProofStore proofStore;
    late _StubFieldScenarioRunner runner;
    late AdminRuntimeGovernanceService service;

    setUp(() async {
      final storage = GetStorage('admin_runtime_governance');
      await storage.erase();
      prefs = await SharedPreferencesCompat.getInstance(storage: storage);
      await _authorizeAdmin(prefs);
      proofStore = DomainExecutionFieldScenarioProofStore(
        nowUtc: () => DateTime.utc(2026, 3, 13, 12),
      );
      runner = _StubFieldScenarioRunner(proofStore: proofStore);
      service = AdminRuntimeGovernanceService(
        authService: AdminAuthService(prefs),
        communicationService: AdminCommunicationService(
          connectionMonitor: ConnectionMonitor(prefs: prefs),
        ),
        businessService: BusinessAccountService(),
        predictiveAnalytics: PredictiveAnalytics(),
        connectionMonitor: ConnectionMonitor(prefs: prefs),
        fieldScenarioProofStore: proofStore,
        fieldScenarioRunner: runner,
      );
    });

    test(
        'runs controlled private-mesh trust scenarios and exports recorded proofs',
        () async {
      final proofs = await service.runControlledPrivateMeshTrustValidation();

      expect(
        proofs.map((entry) => entry.scenario).toList(growable: false),
        const <DomainExecutionFieldScenario>[
          DomainExecutionFieldScenario.trustedDirectAnnounceRecovery,
          DomainExecutionFieldScenario.untrustedAnnounceRejected,
          DomainExecutionFieldScenario
              .deferredRendezvousBlockedByTrustedRouteUnavailable,
        ],
      );
      expect(
        runner.runs,
        const <DomainExecutionFieldScenario>[
          DomainExecutionFieldScenario.trustedDirectAnnounceRecovery,
          DomainExecutionFieldScenario.untrustedAnnounceRejected,
          DomainExecutionFieldScenario
              .deferredRendezvousBlockedByTrustedRouteUnavailable,
        ],
      );

      final exported = jsonDecode(
        service.exportRecentFieldValidationProofs(limit: 3),
      ) as Map<String, dynamic>;
      final scenarios = ((exported['proofs'] as List<dynamic>)
              .cast<Map<String, dynamic>>())
          .map((entry) => entry['scenario'] as String)
          .toList(growable: false);
      expect(
        scenarios,
        const <String>[
          'deferredRendezvousBlockedByTrustedRouteUnavailable',
          'untrustedAnnounceRejected',
          'trustedDirectAnnounceRecovery',
        ],
      );
    });

    test('runs multi-hop and AI2AI peer-truth validation batches', () async {
      final multiHopProofs =
          await service.runControlledPrivateMeshMultiHopValidation();
      final ai2aiProofs = await service.runControlledAi2AiPeerTruthValidation();
      final ambientProofs =
          await service.runControlledAmbientSocialValidation();

      expect(
        multiHopProofs.map((entry) => entry.scenario).toList(growable: false),
        const <DomainExecutionFieldScenario>[
          DomainExecutionFieldScenario.trustedHeardForwardRoutable,
          DomainExecutionFieldScenario.trustedRelayRefreshRoutable,
        ],
      );
      expect(
        ai2aiProofs.single.scenario,
        DomainExecutionFieldScenario.deferredExchangePeerTruthAfterRelease,
      );
      expect(
        ambientProofs.map((entry) => entry.scenario).toList(growable: false),
        const <DomainExecutionFieldScenario>[
          DomainExecutionFieldScenario.ambientPassiveNearbyCandidateOnly,
          DomainExecutionFieldScenario
              .ambientTrustedInteractionPromotesConfirmedPresence,
          DomainExecutionFieldScenario.ambientDuplicateEvidenceMerged,
          DomainExecutionFieldScenario.ambientUntrustedInteractionNotPromoted,
        ],
      );
      expect(
        proofStore.recentProofs(limit: 3)
            .map((entry) => entry.scenario)
            .toList(growable: false),
        const <DomainExecutionFieldScenario>[
          DomainExecutionFieldScenario.ambientUntrustedInteractionNotPromoted,
          DomainExecutionFieldScenario.ambientDuplicateEvidenceMerged,
          DomainExecutionFieldScenario
              .ambientTrustedInteractionPromotesConfirmedPresence,
        ],
      );
    });

    test('runs private-mesh field acceptance validation as one batch', () async {
      final proofs =
          await service.runControlledPrivateMeshFieldAcceptanceValidation();

      expect(
        proofs.map((entry) => entry.scenario).toList(growable: false),
        const <DomainExecutionFieldScenario>[
          DomainExecutionFieldScenario.trustedDirectAnnounceRecovery,
          DomainExecutionFieldScenario.untrustedAnnounceRejected,
          DomainExecutionFieldScenario
              .deferredRendezvousBlockedByTrustedRouteUnavailable,
          DomainExecutionFieldScenario.trustedHeardForwardRoutable,
          DomainExecutionFieldScenario.trustedRelayRefreshRoutable,
          DomainExecutionFieldScenario.deferredExchangePeerTruthAfterRelease,
          DomainExecutionFieldScenario.ambientPassiveNearbyCandidateOnly,
          DomainExecutionFieldScenario
              .ambientTrustedInteractionPromotesConfirmedPresence,
          DomainExecutionFieldScenario.ambientDuplicateEvidenceMerged,
          DomainExecutionFieldScenario.ambientUntrustedInteractionNotPromoted,
        ],
      );
      expect(
        runner.runs,
        const <DomainExecutionFieldScenario>[
          DomainExecutionFieldScenario.trustedDirectAnnounceRecovery,
          DomainExecutionFieldScenario.untrustedAnnounceRejected,
          DomainExecutionFieldScenario
              .deferredRendezvousBlockedByTrustedRouteUnavailable,
          DomainExecutionFieldScenario.trustedHeardForwardRoutable,
          DomainExecutionFieldScenario.trustedRelayRefreshRoutable,
          DomainExecutionFieldScenario.deferredExchangePeerTruthAfterRelease,
          DomainExecutionFieldScenario.ambientPassiveNearbyCandidateOnly,
          DomainExecutionFieldScenario
              .ambientTrustedInteractionPromotesConfirmedPresence,
          DomainExecutionFieldScenario.ambientDuplicateEvidenceMerged,
          DomainExecutionFieldScenario.ambientUntrustedInteractionNotPromoted,
        ],
      );
    });

    test('reads ambient social diagnostics through the admin runtime surface',
        () async {
      final ambientService = AmbientSocialRealityLearningService(
        nowUtc: () => DateTime.utc(2026, 3, 14, 3),
      );
      await ambientService.applyObservation(
        observation: AmbientSocialLearningObservation(
          source: AmbientSocialLearningObservationSource.passiveDwell,
          observedAtUtc: DateTime.utc(2026, 3, 14, 2, 30),
          localityBinding: GeographicVibeBinding(
            localityRef: VibeSubjectRef.locality('bham-downtown'),
            stableKey: 'bham-downtown',
          ),
          discoveredPeerIds: const <String>['peer-a', 'peer-b'],
          confidence: 0.73,
        ),
        personalAgentId: 'agent-local',
      );
      service = AdminRuntimeGovernanceService(
        authService: AdminAuthService(prefs),
        communicationService: AdminCommunicationService(
          connectionMonitor: ConnectionMonitor(prefs: prefs),
        ),
        businessService: BusinessAccountService(),
        predictiveAnalytics: PredictiveAnalytics(),
        connectionMonitor: ConnectionMonitor(prefs: prefs),
        ambientSocialRealityLearningService: ambientService,
        fieldScenarioProofStore: proofStore,
        fieldScenarioRunner: runner,
      );

      final snapshot = await service.getAmbientSocialLearningDiagnosticsSnapshot();

      expect(snapshot.normalizedObservationCount, 1);
      expect(snapshot.candidateCoPresenceObservationCount, 1);
      expect(snapshot.latestLocalityStableKey, 'bham-downtown');
      expect(snapshot.latestNearbyPeerCount, 2);
    });
  });
}

class _StubFieldScenarioRunner implements DomainExecutionFieldScenarioRunner {
  _StubFieldScenarioRunner({required this.proofStore});

  final DomainExecutionFieldScenarioProofStore proofStore;
  final List<DomainExecutionFieldScenario> runs =
      <DomainExecutionFieldScenario>[];

  @override
  Future<DomainExecutionFieldScenarioProof> run(
    DomainExecutionFieldScenario scenario,
  ) async {
    runs.add(scenario);
    final proof = _proof(
      scenario: scenario,
      summary: 'proof-${scenario.name}',
    );
    await proofStore.record(proof);
    return proof;
  }
}

Future<void> _authorizeAdmin(SharedPreferencesCompat prefs) {
  final session = AdminSession(
    username: 'admin',
    loginTime: DateTime.utc(2026, 3, 13, 11),
    expiresAt: DateTime.utc(2030, 3, 13, 20),
    accessLevel: AdminAccessLevel.godMode,
    permissions: AdminPermissions.all(),
  );
  return prefs.setString('admin_session', jsonEncode(session.toJson()));
}

DomainExecutionFieldScenarioProof _proof({
  required DomainExecutionFieldScenario scenario,
  required String summary,
}) {
  final capturedAtUtc = DateTime.utc(2026, 3, 13, 12);
  return DomainExecutionFieldScenarioProof(
    scenario: scenario,
    passed: true,
    summary: summary,
    privacyMode: MeshTransportPrivacyMode.privateMesh,
    routeReceipts: <TransportRouteReceipt>[
      TransportRouteReceiptCompatibilityTranslator.buildFieldValidation(
        receiptId: 'receipt-${scenario.name}',
        privacyMode: MeshTransportPrivacyMode.privateMesh,
        status: 'queued',
        recordedAtUtc: capturedAtUtc,
        routeId: 'route-${scenario.name}',
        peerId: 'peer-1',
        peerNodeId: 'node-1',
        hopCount: 1,
      ),
    ],
    meshHealth: const MeshKernelHealthSnapshot(
      kernelId: 'mesh-kernel',
      status: MeshHealthStatus.healthy,
      nativeBacked: true,
      headlessReady: true,
      summary: 'healthy',
    ),
    ai2aiHealth: const Ai2AiKernelHealthSnapshot(
      kernelId: 'ai2ai-kernel',
      status: Ai2AiHealthStatus.healthy,
      nativeBacked: true,
      headlessReady: true,
      summary: 'healthy',
    ),
    conformanceReport: DomainExecutionConformanceReport(
      checkedAtUtc: capturedAtUtc,
      runtimeReady: true,
      fieldPilotReady: true,
      rolloutFlagEnabled: true,
      signalRequiredSatisfied: true,
      encryptionType: EncryptionType.signalProtocol,
      reports: const <DomainExecutionKernelHealthReport>[],
    ),
    meshRuntimeStateFrame: MeshRuntimeStateFrame(
      capturedAtUtc: capturedAtUtc,
      routeDestinationCount: 1,
      routeEntryCount: 1,
      interfaceEnabledCounts: const <String, int>{'ble': 1},
      interfaceTotalCounts: const <String, int>{'ble': 1},
      activeAnnounceCount: 1,
      trustedActiveAnnounceCount: 1,
      expiredAnnounceCount: 0,
      rejectedAnnounceCount: 0,
      pendingCustodyCount: 0,
      dueCustodyCount: 0,
      encryptedAtRest: true,
      announceTriggeredReplayCount: 0,
      announceRefreshReplayCount: 0,
      interfaceRecoveredReplayCount: 0,
      trustedReplayTriggerCount: 0,
      trustedReplayTriggerSourceCounts: const <String, int>{},
      rejectionReasonCounts: const <String, int>{},
      queuedPayloadKindCounts: const <String, int>{},
      activeAnnounceSourceCounts: const <String, int>{},
      rejectedAnnounceSourceCounts: const <String, int>{},
      activeCredentialCount: 1,
      expiringSoonCredentialCount: 0,
      revokedCredentialCount: 0,
      destinations: const <MeshRuntimeDestinationState>[],
    ),
    ai2aiRuntimeStateFrame: Ai2AiRuntimeStateFrame(
      capturedAtUtc: capturedAtUtc,
      recentEventCount: 0,
      activeConnectionCount: 0,
      distinctConnectionCount: 0,
      distinctRemoteNodeCount: 0,
      routingAttemptCount: 0,
      custodyAcceptedCount: 0,
      deliverySuccessCount: 0,
      deliveryFailureCount: 0,
      readConfirmedCount: 0,
      learningAppliedCount: 0,
      learningBufferedCount: 0,
      peerReceivedCount: 0,
      peerValidatedCount: 0,
      peerConsumedCount: 0,
      peerAppliedCount: 0,
      encryptionFailureCount: 0,
      anomalyCount: 0,
      eventTypeCounts: const <String, int>{},
      peers: const <Ai2AiRuntimePeerState>[],
    ),
  );
}
