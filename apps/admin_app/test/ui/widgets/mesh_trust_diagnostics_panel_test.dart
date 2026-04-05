import 'package:avrai_admin_app/ui/widgets/mesh_trust_diagnostics_panel.dart';
import 'package:avrai_network/avra_network.dart';
import 'package:avrai_runtime_os/kernel/ai2ai/ai2ai_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/mesh/mesh_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/os/domain_execution_conformance_service.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/services/admin/admin_runtime_governance_service.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_transport_retention_telemetry_store.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_runtime_state_frame_service.dart';
import 'package:avrai_runtime_os/services/passive_collection/passive_dwell_reality_learning_service.dart';
import 'package:avrai_runtime_os/services/transport/compatibility/transport_route_receipt_compatibility_translator.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_interface_registry.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_runtime_state_frame_service.dart';
import 'package:avrai_runtime_os/services/validation/domain_execution_field_scenario_runner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MeshTrustDiagnosticsPanel', () {
    testWidgets('renders trust metrics and rejection reasons',
        (WidgetTester tester) async {
      var fieldAcceptanceTriggered = false;
      var runTriggered = false;
      var ambientTriggered = false;
      var exportTriggered = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MeshTrustDiagnosticsPanel(
                meshSnapshot: MeshTrustDiagnosticsSnapshot(
                  capturedAtUtc: DateTime.utc(2026, 3, 12, 23),
                  trustedActiveAnnounceCount: 3,
                  rejectedAnnounceCount: 2,
                  rejectionReasonCounts: const <String, int>{
                    'authenticated_segment_required': 2,
                  },
                  trustedReplayTriggerCount: 4,
                  trustedReplayTriggerSourceCounts: const <String, int>{
                    'direct_discovery': 2,
                    'heard_forward': 2,
                  },
                  activeCredentialCount: 5,
                  expiringSoonCredentialCount: 1,
                  revokedCredentialCount: 1,
                  activeAnnounceSourceCounts: const <String, int>{
                    'direct_discovery': 2,
                    'heard_forward': 1,
                  },
                  rejectedAnnounceSourceCounts: const <String, int>{
                    'cloud_available': 1,
                  },
                  recentProofs: <DomainExecutionFieldScenarioProof>[
                    _proof(
                      scenario: DomainExecutionFieldScenario
                          .trustedDirectAnnounceRecovery,
                      summary: 'trusted recovery passed',
                    ),
                  ],
                ),
                rendezvousSnapshot: Ai2AiRendezvousDiagnosticsSnapshot(
                  capturedAtUtc: DateTime.utc(2026, 3, 12, 23),
                  activeRendezvousCount: 2,
                  releasedTicketCount: 1,
                  blockedByConditionCount: 1,
                  trustedRouteUnavailableBlockCount: 1,
                  peerReceivedCount: 1,
                  peerValidatedCount: 1,
                  peerConsumedCount: 1,
                  peerAppliedCount: 1,
                  recentProofs: <DomainExecutionFieldScenarioProof>[
                    _proof(
                      scenario: DomainExecutionFieldScenario
                          .deferredRendezvousBlockedByTrustedRouteUnavailable,
                      summary: 'rendezvous blocked by trust',
                    ),
                  ],
                ),
                ambientSocialSnapshot: AmbientSocialLearningDiagnosticsSnapshot(
                  capturedAtUtc: DateTime.utc(2026, 3, 12, 23),
                  normalizedObservationCount: 3,
                  candidateCoPresenceObservationCount: 2,
                  confirmedInteractionPromotionCount: 1,
                  duplicateMergeCount: 1,
                  rejectedInteractionPromotionCount: 1,
                  crowdUpgradeCount: 1,
                  whatIngestionCount: 2,
                  localityVibeUpdateCount: 2,
                  personalDnaAuthorizedCount: 1,
                  personalDnaAppliedCount: 1,
                  latestNearbyPeerCount: 3,
                  latestConfirmedInteractivePeerCount: 1,
                  latestSocialContext: 'small_group',
                  latestPlaceVibeLabel: 'intimate_social',
                  latestLocalityStableKey: 'bham-downtown',
                  sourceCounts: const <String, int>{
                    'passive_dwell': 2,
                    'ai2ai_completed_interaction': 1,
                  },
                  lastPromotionTrace: AmbientSocialPromotionTrace(
                    localityStableKey: 'bham-downtown',
                    sourceKinds: const <String>[
                      'passive_dwell',
                      'ai2ai_completed_interaction',
                    ],
                    discoveredPeerIds: const <String>[
                      'peer-a',
                      'peer-b',
                      'peer-c',
                    ],
                    confirmedInteractivePeerIds: const <String>['peer-a'],
                    socialContext: 'small_group',
                    placeVibeLabel: 'intimate_social',
                    lineageRefs: const <String>['ambient:ai2ai:peer-a'],
                    promotedAtUtc: DateTime.utc(2026, 3, 12, 22, 55),
                  ),
                  recentPromotionTraces: <AmbientSocialPromotionTrace>[
                    AmbientSocialPromotionTrace(
                      localityStableKey: 'bham-downtown',
                      sourceKinds: const <String>[
                        'passive_dwell',
                        'ai2ai_completed_interaction',
                      ],
                      discoveredPeerIds: const <String>[
                        'peer-a',
                        'peer-b',
                        'peer-c',
                      ],
                      confirmedInteractivePeerIds: const <String>['peer-a'],
                      socialContext: 'small_group',
                      placeVibeLabel: 'intimate_social',
                      lineageRefs: const <String>['ambient:ai2ai:peer-a'],
                      promotedAtUtc: DateTime.utc(2026, 3, 12, 22, 55),
                    ),
                  ],
                ),
                transportRetentionSnapshot: Ai2AiTransportRetentionSnapshot(
                  capturedAtUtc: DateTime.utc(2026, 3, 12, 23),
                  dmConsumedCount: 2,
                  dmFailureCount: 1,
                  communityConsumedCount: 3,
                  communityFailureCount: 0,
                  latestFailureSummary: 'dm_consume_failed',
                  recentEvents: <Ai2AiTransportRetentionEvent>[
                    Ai2AiTransportRetentionEvent(
                      channel: Ai2AiTransportRetentionChannel.dm,
                      outcome: Ai2AiTransportRetentionOutcome.consumed,
                      messageId: 'dm-1',
                      recipientUserId: 'user-b',
                      recipientDeviceId: '7',
                      occurredAtUtc: DateTime.utc(2026, 3, 12, 22, 59),
                      deletedTransportCount: 2,
                      remainingTransportCount: 0,
                    ),
                  ],
                ),
                lifecycleVisibilitySnapshot:
                    ArtifactLifecycleVisibilitySnapshot(
                  capturedAtUtc: DateTime.utc(2026, 3, 12, 23),
                  replayUsesDedicatedProject: false,
                  replaySharesProjectWithApp: true,
                  entries: <ArtifactLifecycleVisibilityEntry>[
                    ArtifactLifecycleVisibilityEntry(
                      label: 'Governed upward review',
                      familyId: 'governed_upward_learning_review',
                      artifactClass: 'canonical',
                      artifactState: 'candidate',
                      retentionMode: 'keep_forever',
                      deleteWhenSuperseded: false,
                      cleanupAfterSuccessfulUpload: false,
                      containsRawPersonalPayload: true,
                      containsMessageContent: true,
                      trainingEligible: false,
                      sourceScope: 'hierarchy_entry_scope',
                      summary: 'Review/source descriptors remain durable.',
                    ),
                    ArtifactLifecycleVisibilityEntry(
                      label: 'Replay staging export',
                      familyId: 'replay_storage_export_manifest',
                      artifactClass: 'staging',
                      artifactState: 'accepted',
                      retentionMode: 'ttl_delete',
                      ttlSeconds: Duration(days: 30).inSeconds,
                      deleteWhenSuperseded: false,
                      cleanupAfterSuccessfulUpload: true,
                      containsRawPersonalPayload: false,
                      containsMessageContent: false,
                      trainingEligible: false,
                      sourceScope: 'simulation_world',
                      summary:
                          'Managed local staging root expires and is deleted.',
                    ),
                    ArtifactLifecycleVisibilityEntry(
                      label: 'DM transport blob',
                      familyId: 'ai2ai_dm_transport_blob',
                      artifactClass: 'temporary',
                      artifactState: 'accepted',
                      retentionMode: 'user_controlled',
                      deleteWhenSuperseded: false,
                      deleteOnConsume: true,
                      cleanupAfterSuccessfulUpload: false,
                      containsRawPersonalPayload: false,
                      containsMessageContent: true,
                      trainingEligible: false,
                      sourceScope: 'ai2ai_runtime',
                      summary:
                          'Persist local-first, then consume the transport blob.',
                    ),
                  ],
                ),
                onRunFieldAcceptanceValidation: () async {
                  fieldAcceptanceTriggered = true;
                  return <DomainExecutionFieldScenarioProof>[
                    _proof(
                      scenario: DomainExecutionFieldScenario
                          .trustedHeardForwardRoutable,
                      summary: 'field acceptance passed',
                    ),
                  ];
                },
                onRunControlledValidation: () async {
                  runTriggered = true;
                  return <DomainExecutionFieldScenarioProof>[
                    _proof(
                      scenario: DomainExecutionFieldScenario
                          .trustedDirectAnnounceRecovery,
                      summary: 'trusted recovery passed',
                    ),
                  ];
                },
                onExportRecentProofBundles: () async {
                  exportTriggered = true;
                  return '{"proofs": []}';
                },
                onRunAmbientSocialValidation: () async {
                  ambientTriggered = true;
                  return <DomainExecutionFieldScenarioProof>[
                    _proof(
                      scenario: DomainExecutionFieldScenario
                          .ambientDuplicateEvidenceMerged,
                      summary: 'ambient validation passed',
                    ),
                  ];
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('Trust And Segment Diagnostics'), findsOneWidget);
      expect(find.text('Trusted announces'), findsOneWidget);
      expect(find.text('Rejected announces'), findsOneWidget);
      expect(find.text('Trusted replay triggers'), findsOneWidget);
      expect(find.text('Peer received'), findsOneWidget);
      expect(find.text('Peer applied'), findsOneWidget);
      expect(find.text('Trusted-route blocks'), findsOneWidget);
      expect(find.text('Ambient observations'), findsOneWidget);
      expect(find.text('Confirmed interactions'), findsOneWidget);
      expect(find.text('Duplicate merges'), findsOneWidget);
      expect(find.text('Rejected promotions'), findsOneWidget);
      expect(find.text('Ambient social learning'), findsOneWidget);
      expect(
        find.text('bham-downtown | intimate_social | small_group'),
        findsOneWidget,
      );
      expect(find.text('Ambient promotion lineage'), findsOneWidget);
      expect(find.text('source passive_dwell'), findsOneWidget);
      expect(find.text('confirmed peer-a'), findsOneWidget);
      expect(find.text('ambient:ai2ai:peer-a'), findsOneWidget);
      expect(find.text('authenticated_segment_required: 2'), findsOneWidget);
      expect(find.text('active direct_discovery: 2'), findsOneWidget);
      expect(find.text('active heard_forward: 1'), findsOneWidget);
      expect(find.text('rejected cloud_available: 1'), findsOneWidget);
      expect(find.text('trusted replay direct_discovery: 2'), findsOneWidget);
      expect(find.text('trustedDirectAnnounceRecovery'), findsOneWidget);
      expect(find.text('deferredRendezvousBlockedByTrustedRouteUnavailable'),
          findsOneWidget);
      expect(find.text('Lifecycle governance'), findsOneWidget);
      expect(find.text('Governed upward review'), findsOneWidget);
      expect(find.textContaining('replay_storage_export_manifest'),
          findsOneWidget);
      expect(find.textContaining('cleanup-on-upload'), findsOneWidget);
      expect(find.textContaining('consume-delete'), findsOneWidget);

      await tester.ensureVisible(find.text('Run Field Acceptance'));
      await tester.tap(find.text('Run Field Acceptance'));
      await tester.pumpAndSettle();
      expect(fieldAcceptanceTriggered, isTrue);

      await tester.ensureVisible(find.text('Run Private-Mesh Validation'));
      await tester.tap(find.text('Run Private-Mesh Validation'));
      await tester.pumpAndSettle();
      expect(runTriggered, isTrue);

      await tester.ensureVisible(find.text('Export Proof Bundles'));
      await tester.tap(find.text('Export Proof Bundles'));
      await tester.pumpAndSettle();
      expect(exportTriggered, isTrue);

      await tester.ensureVisible(find.text('Run Ambient Social'));
      await tester.tap(find.text('Run Ambient Social'));
      await tester.pumpAndSettle();
      expect(ambientTriggered, isTrue);
    });
  });
}

DomainExecutionFieldScenarioProof _proof({
  required DomainExecutionFieldScenario scenario,
  required String summary,
}) {
  final capturedAtUtc = DateTime.utc(2026, 3, 12, 23);
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
