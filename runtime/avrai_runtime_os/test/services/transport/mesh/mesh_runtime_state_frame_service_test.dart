import 'package:avrai_core/models/signatures/entity_signature.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_announce_ledger.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_announce_validator.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_custody_outbox.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_interface_registry.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_route_ledger.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_runtime_state_frame_service.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_runtime_state_store.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_segment_credential_refresh_service.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_segment_models.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_segment_revocation_policy.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_segment_revocation_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MeshRuntimeStateFrameService', () {
    test('builds a deterministic frame from route memory and custody state',
        () async {
      final routeLedger = MeshRouteLedger(
        store: InMemoryMeshRuntimeStateStore(),
        nowUtc: () => DateTime.utc(2026, 3, 12, 23),
      );
      final custodyOutbox = MeshCustodyOutbox(
        store: InMemoryMeshRuntimeStateStore(),
        nowUtc: () => DateTime.utc(2026, 3, 12, 23),
      );
      final announceLedger = MeshAnnounceLedger(
        store: InMemoryMeshRuntimeStateStore(),
        nowUtc: () => DateTime.utc(2026, 3, 12, 23),
      );

      final winningRoute = TransportRouteCandidate(
        routeId: 'route-peer-a',
        mode: TransportMode.nearbyRelay,
        confidence: 0.91,
        estimatedLatencyMs: 420,
        metadata: const <String, dynamic>{
          'peer_id': 'peer-a',
          'peer_node_id': 'node-a',
        },
      );
      final failedRoute = TransportRouteCandidate(
        routeId: 'route-peer-b',
        mode: TransportMode.nearbyRelay,
        confidence: 0.62,
        estimatedLatencyMs: 580,
        metadata: const <String, dynamic>{
          'peer_id': 'peer-b',
          'peer_node_id': 'node-b',
        },
      );
      await routeLedger.recordForwardOutcome(
        destinationId: 'dest-alpha',
        channel: 'mesh_ble_forward',
        payloadKind: 'organic_spot_discovery',
        attemptedRoutes: <TransportRouteCandidate>[winningRoute, failedRoute],
        winningRoute: winningRoute,
        occurredAtUtc: DateTime.utc(2026, 3, 12, 22, 30),
        geographicScope: 'locality',
      );
      await custodyOutbox.enqueue(
        receiptId: 'receipt-queued-1',
        destinationId: 'dest-alpha',
        payloadKind: 'organic_spot_discovery',
        channel: 'mesh_ble_forward',
        payload: const <String, dynamic>{
          'geohash': '9q4xy',
          'private': 'queued-secret',
        },
        payloadContext: const <String, dynamic>{
          'origin_id': 'node-local',
        },
        geographicScope: 'locality',
        retryBackoff: Duration.zero,
      );
      await custodyOutbox.enqueue(
        receiptId: 'receipt-queued-2',
        destinationId: 'dest-beta',
        payloadKind: 'learning_insight_gossip',
        channel: 'mesh_ble_forward',
        payload: const <String, dynamic>{
          'topic': 'music',
        },
        payloadContext: const <String, dynamic>{
          'origin_id': 'node-local',
        },
        geographicScope: 'city',
        retryBackoff: const Duration(minutes: 5),
      );
      await announceLedger.observe(
        observation: const MeshAnnounceObservation(
          destinationId: 'dest-alpha',
          nextHopPeerId: 'peer-a',
          nextHopNodeId: 'node-a',
          interfaceId: 'ble',
          hopCount: 1,
          geographicScope: 'locality',
          confidence: 0.88,
          supportsCustody: true,
          sourceType: MeshAnnounceSourceType.forwardSuccess,
        ),
        interfaceProfile: MeshInterfaceRegistry().resolveByInterfaceId(
          'ble',
          privacyMode: MeshTransportPrivacyMode.privateMesh,
        ),
      );

      final frame = const MeshRuntimeStateFrameService().buildFrame(
        routeLedger: routeLedger,
        custodyOutbox: custodyOutbox,
        announceLedger: announceLedger,
        interfaceRegistry: MeshInterfaceRegistry(cloudInterfaceAvailable: true),
        privacyMode: MeshTransportPrivacyMode.privateMesh,
        capturedAtUtc: DateTime.utc(2026, 3, 12, 23),
      );

      expect(frame.routeDestinationCount, 1);
      expect(frame.routeEntryCount, 2);
      expect(frame.interfaceEnabledCounts['ble'], 1);
      expect(frame.activeAnnounceCount, 1);
      expect(frame.trustedActiveAnnounceCount, 0);
      expect(frame.pendingCustodyCount, 2);
      expect(frame.dueCustodyCount, 1);
      expect(frame.encryptedAtRest, isTrue);
      expect(frame.queuedPayloadKindCounts['organic_spot_discovery'], 1);
      expect(frame.destinations.first.destinationId, 'dest-alpha');
      expect(frame.destinations.first.pendingCustodyCount, 1);
      expect(frame.destinations.first.knownRouteCount, 2);
      expect(frame.destinations.first.activeAnnounceCount, 1);
      expect(frame.destinations.first.bestSuccessRate, 1.0);

      final decoded = MeshRuntimeStateFrame.fromJson(frame.toJson());
      expect(decoded.pendingCustodyCount, frame.pendingCustodyCount);
      expect(decoded.destinations.first.destinationId, 'dest-alpha');
    });

    test('tracks trusted and rejected announce diagnostics', () async {
      final ledger = MeshAnnounceLedger(
        store: InMemoryMeshRuntimeStateStore(),
        announceValidator: const MeshAnnounceValidator(),
        nowUtc: () => DateTime.utc(2026, 3, 12, 23),
      );
      final privateMeshProfile = MeshInterfaceRegistry().resolveByInterfaceId(
        'ble',
        privacyMode: MeshTransportPrivacyMode.privateMesh,
      );

      await ledger.observe(
        observation: MeshAnnounceObservation(
          destinationId: 'peer-trusted',
          nextHopPeerId: 'peer-trusted',
          interfaceId: 'ble',
          hopCount: 1,
          geographicScope: 'local',
          confidence: 0.9,
          supportsCustody: true,
          sourceType: MeshAnnounceSourceType.directDiscovery,
          segmentProfile: MeshSegmentProfile(
            segmentProfileId: 'segment-1',
            privacyMode: MeshTransportPrivacyMode.privateMesh,
            allowedInterfaceIds: <String>{'ble'},
            requiresAuthenticatedAnnounces: true,
          ),
          segmentCredential: MeshSegmentCredential(
            credentialId: 'cred-1',
            segmentProfileId: 'segment-1',
            principalId: 'peer-trusted',
            principalKind: SignatureEntityKind.user,
            issuedAtUtc: DateTime.utc(2026, 3, 12, 22),
            expiresAtUtc: DateTime.utc(2026, 3, 13, 22),
          ),
          attestation: MeshAnnounceAttestation(
            attestationId: 'attest-1',
            segmentProfileId: 'segment-1',
            credentialId: 'cred-1',
            signerEntityId: 'peer-trusted',
            signerEntityKind: SignatureEntityKind.user,
            signedAtUtc: DateTime.utc(2026, 3, 12, 22),
            expiresAtUtc: DateTime.utc(2026, 3, 13, 22),
          ),
        ),
        interfaceProfile: privateMeshProfile,
        privacyMode: MeshTransportPrivacyMode.privateMesh,
      );
      await ledger.observe(
        observation: const MeshAnnounceObservation(
          destinationId: 'peer-rejected',
          nextHopPeerId: 'peer-rejected',
          interfaceId: 'ble',
          hopCount: 1,
          geographicScope: 'local',
          confidence: 0.9,
          supportsCustody: true,
          sourceType: MeshAnnounceSourceType.directDiscovery,
        ),
        interfaceProfile: privateMeshProfile,
        privacyMode: MeshTransportPrivacyMode.privateMesh,
      );
      await ledger.recordReplayTrigger(
        'announce_arrival',
        trusted: true,
        sourceKey: 'direct_discovery',
      );

      final frame = const MeshRuntimeStateFrameService().buildFrame(
        routeLedger: MeshRouteLedger(store: InMemoryMeshRuntimeStateStore()),
        announceLedger: ledger,
        interfaceRegistry: MeshInterfaceRegistry(),
        privacyMode: MeshTransportPrivacyMode.privateMesh,
        capturedAtUtc: DateTime.utc(2026, 3, 12, 23),
      );

      expect(frame.trustedActiveAnnounceCount, 1);
      expect(frame.rejectedAnnounceCount, 1);
      expect(frame.rejectionReasonCounts['authenticated_segment_required'], 1);
      expect(frame.trustedReplayTriggerCount, 1);
      expect(frame.trustedReplayTriggerSourceCounts['direct_discovery'], 1);
      expect(frame.activeAnnounceSourceCounts['direct_discovery'], 1);
      expect(frame.rejectedAnnounceSourceCounts['direct_discovery'], 1);
    });

    test('includes segment lifecycle counts in runtime frame', () async {
      final now = DateTime.utc(2026, 3, 12, 23);
      final revocationStore = MeshSegmentRevocationStore();
      final refreshService = MeshSegmentCredentialRefreshService(
        revocationPolicy: MeshSegmentRevocationPolicy(
          revocationStore: revocationStore,
        ),
        nowUtc: () => now,
      );
      final activeCredential = MeshSegmentCredential(
        credentialId: 'cred-active',
        segmentProfileId: 'segment-1',
        principalId: 'peer-active',
        principalKind: SignatureEntityKind.user,
        issuedAtUtc: now.subtract(const Duration(minutes: 5)),
        expiresAtUtc: now.add(const Duration(hours: 2)),
      );
      final expiringCredential = MeshSegmentCredential(
        credentialId: 'cred-expiring',
        segmentProfileId: 'segment-1',
        principalId: 'peer-expiring',
        principalKind: SignatureEntityKind.user,
        issuedAtUtc: now.subtract(const Duration(minutes: 5)),
        expiresAtUtc: now.add(const Duration(minutes: 10)),
      );
      final revokedCredential = MeshSegmentCredential(
        credentialId: 'cred-revoked',
        segmentProfileId: 'segment-1',
        principalId: 'peer-revoked',
        principalKind: SignatureEntityKind.user,
        issuedAtUtc: now.subtract(const Duration(minutes: 5)),
        expiresAtUtc: now.add(const Duration(hours: 1)),
      );
      refreshService.recordIssued(credential: activeCredential);
      refreshService.recordIssued(credential: expiringCredential);
      refreshService.recordIssued(credential: revokedCredential);
      revocationStore.revokeCredential('cred-revoked', reason: 'compromised');

      final frame = const MeshRuntimeStateFrameService().buildFrame(
        routeLedger: MeshRouteLedger(store: InMemoryMeshRuntimeStateStore()),
        custodyOutbox:
            MeshCustodyOutbox(store: InMemoryMeshRuntimeStateStore()),
        announceLedger:
            MeshAnnounceLedger(store: InMemoryMeshRuntimeStateStore()),
        interfaceRegistry: MeshInterfaceRegistry(),
        privacyMode: MeshTransportPrivacyMode.privateMesh,
        capturedAtUtc: now,
        credentialRefreshService: refreshService,
        revocationStore: revocationStore,
      );

      expect(frame.activeCredentialCount, 2);
      expect(frame.expiringSoonCredentialCount, 1);
      expect(frame.revokedCredentialCount, 1);
    });
  });
}
