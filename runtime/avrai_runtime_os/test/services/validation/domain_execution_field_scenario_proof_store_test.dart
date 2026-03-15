import 'dart:convert';
import 'dart:io';

import 'package:avrai_network/avra_network.dart';
import 'package:avrai_runtime_os/kernel/ai2ai/ai2ai_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/mesh/mesh_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/os/domain_execution_conformance_service.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_runtime_state_frame_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai_runtime_os/services/transport/compatibility/transport_route_receipt_compatibility_translator.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_interface_registry.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_runtime_state_frame_service.dart';
import 'package:avrai_runtime_os/services/validation/domain_execution_field_scenario_proof_store.dart';
import 'package:avrai_runtime_os/services/validation/domain_execution_field_scenario_runner.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory storageRoot;
  late GetStorage defaultStorage;
  late GetStorage userStorage;
  late GetStorage aiStorage;
  late GetStorage analyticsStorage;

  setUpAll(() async {
    storageRoot = await Directory.systemTemp.createTemp(
      'domain_execution_field_scenario_proof_store_test_',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getApplicationDocumentsDirectory') {
          return storageRoot.path;
        }
        return null;
      },
    );
    await GetStorage('proof_store_default', storageRoot.path).initStorage;
    await GetStorage('proof_store_user', storageRoot.path).initStorage;
    await GetStorage('proof_store_ai', storageRoot.path).initStorage;
    await GetStorage('proof_store_analytics', storageRoot.path).initStorage;
    defaultStorage = GetStorage('proof_store_default', storageRoot.path);
    userStorage = GetStorage('proof_store_user', storageRoot.path);
    aiStorage = GetStorage('proof_store_ai', storageRoot.path);
    analyticsStorage = GetStorage('proof_store_analytics', storageRoot.path);
    await StorageService.instance.initForTesting(
      defaultStorage: defaultStorage,
      userStorage: userStorage,
      aiStorage: aiStorage,
      analyticsStorage: analyticsStorage,
    );
  });

  tearDown(() async {
    await defaultStorage.erase();
    await userStorage.erase();
    await aiStorage.erase();
    await analyticsStorage.erase();
  });

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
    await _deleteDirectoryWithRetry(storageRoot);
  });

  group('DomainExecutionFieldScenarioProofStore', () {
    test('records and exports recent proofs in reverse chronological order',
        () async {
      final store = DomainExecutionFieldScenarioProofStore();
      final older = _proof(
        scenario: DomainExecutionFieldScenario.trustedDirectAnnounceRecovery,
        capturedAtUtc: DateTime.utc(2026, 3, 12, 20),
        summary: 'older proof',
      );
      final newer = _proof(
        scenario: DomainExecutionFieldScenario.untrustedAnnounceRejected,
        capturedAtUtc: DateTime.utc(2026, 3, 12, 21),
        summary: 'newer proof',
      );

      await store.record(older);
      await store.record(newer);

      final recent = store.recentProofs();
      expect(recent, hasLength(2));
      expect(recent.first.summary, 'newer proof');
      expect(
          store
              .latestForScenario(
                DomainExecutionFieldScenario.untrustedAnnounceRejected,
              )
              ?.summary,
          'newer proof');

      final exported = jsonDecode(store.exportRecentProofBundles(limit: 2))
          as Map<String, dynamic>;
      final proofs =
          (exported['proofs'] as List<dynamic>).cast<Map<String, dynamic>>();
      expect(proofs, hasLength(2));
      expect(proofs.first['summary'], 'newer proof');
      expect(
        (jsonDecode(store.exportProofBundle(older))
            as Map<String, dynamic>)['summary'],
        'older proof',
      );
    });

    test('persists proof bundles across store instances', () async {
      final store = DomainExecutionFieldScenarioProofStore(
        storageService: StorageService.instance,
      );
      final proof = _proof(
        scenario: DomainExecutionFieldScenario
            .deferredRendezvousBlockedByTrustedRouteUnavailable,
        capturedAtUtc: DateTime.utc(2026, 3, 12, 22, 45),
        summary: 'persisted trust proof',
      );

      await store.record(proof);

      final reloaded = DomainExecutionFieldScenarioProofStore(
        storageService: StorageService.instance,
      );
      expect(reloaded.recentProofs(), hasLength(1));
      expect(reloaded.recentProofs().single.summary, 'persisted trust proof');
      expect(
        reloaded
            .latestForScenario(
              DomainExecutionFieldScenario
                  .deferredRendezvousBlockedByTrustedRouteUnavailable,
            )
            ?.summary,
        'persisted trust proof',
      );
    });
  });
}

Future<void> _deleteDirectoryWithRetry(Directory directory) async {
  if (!directory.existsSync()) {
    return;
  }

  for (var attempt = 0; attempt < 5; attempt++) {
    try {
      await directory.delete(recursive: true);
      return;
    } on FileSystemException {
      final entities = directory.listSync(recursive: true).reversed.toList();
      for (final entity in entities) {
        try {
          await entity.delete(recursive: true);
        } on FileSystemException {
          // Retry outer directory deletion after other handles settle.
        }
      }
      await Future<void>.delayed(
        Duration(milliseconds: 40 * (attempt + 1)),
      );
    }
  }

  if (directory.existsSync()) {
    await directory.delete(recursive: true);
  }
}

DomainExecutionFieldScenarioProof _proof({
  required DomainExecutionFieldScenario scenario,
  required DateTime capturedAtUtc,
  required String summary,
}) {
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
      encryptionFailureCount: 0,
      anomalyCount: 0,
      eventTypeCounts: const <String, int>{},
      peers: const <Ai2AiRuntimePeerState>[],
    ),
  );
}
