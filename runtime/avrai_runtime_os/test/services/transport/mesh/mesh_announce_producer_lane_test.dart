import 'package:avrai_core/models/signatures/entity_signature.dart';
import 'package:avrai_network/avra_network.dart';
import 'package:avrai_runtime_os/services/signatures/signature_repository.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_announce_attestation_factory.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_announce_ledger.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_announce_producer_lane.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_announce_validator.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_interface_registry.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_runtime_state_store.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_segment_credential_refresh_service.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_segment_credential_factory.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_segment_profile_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MeshAnnounceProducerLane', () {
    test(
        'direct discovery producer remains accepted when trust enforcement is off',
        () async {
      final now = DateTime.now().toUtc();
      final ledger = MeshAnnounceLedger(
        store: InMemoryMeshRuntimeStateStore(),
      );

      final updates = await MeshAnnounceProducerLane.syncReachablePeers(
        announceLedger: ledger,
        reachablePeerIds: const <String>{'peer-a'},
        discovery: _FakeDiscoveryService(
          <String, DiscoveredDevice>{
            'peer-a': _device('peer-a'),
          },
        ),
        interfaceRegistry: MeshInterfaceRegistry(),
        privacyMode: MeshTransportPrivacyMode.privateMesh,
        observedAtUtc: now,
      );

      expect(updates.single.accepted, isTrue);
      expect(
        ledger.activeRecords(
          destinationId: 'peer-a',
          nowUtc: now.add(const Duration(minutes: 1)),
        ),
        hasLength(1),
      );
    });

    test(
        'direct discovery producer attaches trust material before observe when trust enforcement is on',
        () async {
      final now = DateTime.now().toUtc();
      final repository = _FakeSignatureRepository();
      final ledger = MeshAnnounceLedger(
        store: InMemoryMeshRuntimeStateStore(),
        announceValidator: MeshAnnounceValidator(
          signatureRepository: repository,
        ),
      );

      final updates = await MeshAnnounceProducerLane.syncReachablePeers(
        announceLedger: ledger,
        reachablePeerIds: const <String>{'peer-a'},
        discovery: _FakeDiscoveryService(
          <String, DiscoveredDevice>{
            'peer-a': _device('peer-a'),
          },
        ),
        interfaceRegistry: MeshInterfaceRegistry(),
        privacyMode: MeshTransportPrivacyMode.privateMesh,
        segmentProfileResolver: const MeshSegmentProfileResolver(),
        segmentCredentialFactory: MeshSegmentCredentialFactory(
          signatureRepository: repository,
        ),
        announceAttestationFactory: MeshAnnounceAttestationFactory(
          signatureRepository: repository,
        ),
        observedAtUtc: now,
      );

      expect(updates.single.accepted, isTrue);
      final active = ledger
          .activeRecords(
            destinationId: 'peer-a',
            nowUtc: now.add(const Duration(minutes: 1)),
          )
          .single;
      expect(active.segmentProfileId, isNotNull);
      expect(active.segmentCredentialId, isNotNull);
      expect(active.attestationId, isNotNull);
      expect(active.attestationAccepted, isTrue);
    });

    test(
        'direct discovery producer is rejected when trust enforcement is on and no trust material is attached',
        () async {
      final now = DateTime.now().toUtc();
      final ledger = MeshAnnounceLedger(
        store: InMemoryMeshRuntimeStateStore(),
        announceValidator: const MeshAnnounceValidator(),
      );

      final updates = await MeshAnnounceProducerLane.syncReachablePeers(
        announceLedger: ledger,
        reachablePeerIds: const <String>{'peer-b'},
        discovery: _FakeDiscoveryService(
          <String, DiscoveredDevice>{
            'peer-b': _device('peer-b'),
          },
        ),
        interfaceRegistry: MeshInterfaceRegistry(),
        privacyMode: MeshTransportPrivacyMode.privateMesh,
        observedAtUtc: now,
      );

      expect(updates.single.accepted, isFalse);
      expect(
        ledger.activeRecords(
          destinationId: 'peer-b',
          nowUtc: now.add(const Duration(minutes: 1)),
        ),
        isEmpty,
      );
      expect(ledger.rejectedRecords(destinationId: 'peer-b'), hasLength(1));
    });

    test(
        'cloud availability producer attaches trust material before observe when trust enforcement is on',
        () async {
      final now = DateTime.now().toUtc();
      final repository = _FakeSignatureRepository();
      final ledger = MeshAnnounceLedger(
        store: InMemoryMeshRuntimeStateStore(),
        announceValidator: MeshAnnounceValidator(
          signatureRepository: repository,
        ),
      );

      final updates = await MeshAnnounceProducerLane.seedCloudAvailability(
        announceLedger: ledger,
        destinationIds: const <String>{'peer-cloud'},
        interfaceRegistry: MeshInterfaceRegistry(cloudInterfaceAvailable: true),
        privacyMode: MeshTransportPrivacyMode.federatedCloud,
        segmentProfileResolver: const MeshSegmentProfileResolver(),
        segmentCredentialFactory: MeshSegmentCredentialFactory(
          signatureRepository: repository,
        ),
        announceAttestationFactory: MeshAnnounceAttestationFactory(
          signatureRepository: repository,
        ),
        observedAtUtc: now,
      );

      expect(updates.single.accepted, isTrue);
      final active = ledger
          .activeRecords(
            destinationId: 'peer-cloud',
            nowUtc: now.add(const Duration(minutes: 1)),
          )
          .single;
      expect(active.nextHopPeerId, 'federated_cloud');
      expect(active.segmentCredentialId, isNotNull);
      expect(active.attestationId, isNotNull);
    });

    test(
        'trusted heard-forward announce becomes active and records credentials',
        () async {
      final now = DateTime.now().toUtc();
      final repository = _FakeSignatureRepository();
      final refreshService = MeshSegmentCredentialRefreshService(
        nowUtc: () => now,
      );
      final ledger = MeshAnnounceLedger(
        store: InMemoryMeshRuntimeStateStore(),
        announceValidator: MeshAnnounceValidator(
          signatureRepository: repository,
        ),
      );
      final interfaceProfile = MeshInterfaceRegistry().resolveByInterfaceId(
        'ble',
        privacyMode: MeshTransportPrivacyMode.privateMesh,
      );

      final update = await MeshAnnounceProducerLane.observeHeardForward(
        announceLedger: ledger,
        interfaceProfile: interfaceProfile,
        privacyMode: MeshTransportPrivacyMode.privateMesh,
        destinationId: 'peer-destination',
        nextHopPeerId: 'peer-heard',
        nextHopNodeId: 'node-heard',
        geographicScope: 'local',
        confidence: 0.82,
        supportsCustody: true,
        hopCount: 2,
        segmentProfileResolver: const MeshSegmentProfileResolver(),
        segmentCredentialFactory: MeshSegmentCredentialFactory(
          signatureRepository: repository,
        ),
        announceAttestationFactory: MeshAnnounceAttestationFactory(
          signatureRepository: repository,
        ),
        credentialRefreshService: refreshService,
        observedAtUtc: now,
      );

      expect(update.accepted, isTrue);
      expect(
        ledger.activeRecords(
          destinationId: 'peer-destination',
          nowUtc: now.add(const Duration(minutes: 1)),
        ),
        hasLength(1),
      );
      expect(refreshService.activeCredentialCount(nowUtc: now), 1);
    });

    test('untrusted relay refresh is persisted but not active', () async {
      final now = DateTime.now().toUtc();
      final ledger = MeshAnnounceLedger(
        store: InMemoryMeshRuntimeStateStore(),
        announceValidator: const MeshAnnounceValidator(),
      );
      final interfaceProfile = MeshInterfaceRegistry().resolveByInterfaceId(
        'ble',
        privacyMode: MeshTransportPrivacyMode.privateMesh,
      );

      final update = await MeshAnnounceProducerLane.observeRelayRefresh(
        announceLedger: ledger,
        interfaceProfile: interfaceProfile,
        privacyMode: MeshTransportPrivacyMode.privateMesh,
        destinationId: 'peer-relay-target',
        nextHopPeerId: 'peer-relay',
        nextHopNodeId: 'node-relay',
        geographicScope: 'mesh',
        confidence: 0.8,
        supportsCustody: true,
        hopCount: 2,
        observedAtUtc: now,
      );

      expect(update.accepted, isFalse);
      expect(
        ledger.activeRecords(
          destinationId: 'peer-relay-target',
          nowUtc: now.add(const Duration(minutes: 1)),
        ),
        isEmpty,
      );
      expect(
        ledger.rejectedRecords(destinationId: 'peer-relay-target'),
        hasLength(1),
      );
    });
  });
}

class _FakeDiscoveryService extends DeviceDiscoveryService {
  _FakeDiscoveryService(this._devices);

  final Map<String, DiscoveredDevice> _devices;

  @override
  DiscoveredDevice? getDevice(String deviceId) => _devices[deviceId];
}

class _FakeSignatureRepository extends SignatureRepository {
  @override
  EntitySignature? get({
    required SignatureEntityKind entityKind,
    required String entityId,
  }) {
    return EntitySignature(
      signatureId: 'sig-$entityId',
      entityId: entityId,
      entityKind: entityKind,
      dna: const <String, double>{'trust': 0.9},
      pheromones: const <String, double>{'fresh': 0.9},
      confidence: 0.95,
      freshness: 0.95,
      updatedAt: DateTime.utc(2026, 3, 12, 22),
      summary: 'Test signature',
    );
  }
}

DiscoveredDevice _device(String deviceId) {
  return DiscoveredDevice(
    deviceId: deviceId,
    deviceName: deviceId,
    type: DeviceType.bluetooth,
    isSpotsEnabled: true,
    signalStrength: -42,
    discoveredAt: DateTime.utc(2026, 3, 12, 23),
    metadata: <String, dynamic>{'node_id': '$deviceId-node'},
  );
}
