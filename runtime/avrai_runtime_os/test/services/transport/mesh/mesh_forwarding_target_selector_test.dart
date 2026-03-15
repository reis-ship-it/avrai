// ignore_for_file: deprecated_member_use

import 'dart:typed_data';

import 'package:avrai_network/avra_network.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_announce_ledger.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_custody_outbox.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_forwarding_context.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_forwarding_target_selector.dart';
import 'package:avrai_runtime_os/services/transport/mesh/governed_mesh_packet_codec.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_interface_registry.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_route_ledger.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_runtime_state_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MeshForwardingTargetSelector', () {
    test('ranks replayed historical announces alongside fresh direct announces',
        () async {
      final routeLedger = MeshRouteLedger(
        store: InMemoryMeshRuntimeStateStore(),
        nowUtc: () => DateTime.utc(2026, 3, 12, 18),
      );
      await routeLedger.recordForwardOutcome(
        destinationId: 'dest-alpha',
        channel: 'mesh_ble_forward',
        payloadKind: 'learning_insight_gossip',
        attemptedRoutes: const <TransportRouteCandidate>[
          TransportRouteCandidate(
            routeId: 'ble:peer-a:node-a',
            mode: TransportMode.ble,
            confidence: 0.9,
            estimatedLatencyMs: 120,
            metadata: <String, dynamic>{'peer_id': 'peer-a'},
          ),
        ],
        winningRoute: const TransportRouteCandidate(
          routeId: 'ble:peer-a:node-a',
          mode: TransportMode.ble,
          confidence: 0.9,
          estimatedLatencyMs: 120,
          metadata: <String, dynamic>{'peer_id': 'peer-a'},
        ),
        occurredAtUtc: DateTime.utc(2026, 3, 12, 17, 45),
      );

      final announceLedger = MeshAnnounceLedger(
        store: InMemoryMeshRuntimeStateStore(),
        nowUtc: () => DateTime.utc(2026, 3, 12, 18),
      );
      await announceLedger.observe(
        observation: const MeshAnnounceObservation(
          destinationId: 'dest-alpha',
          nextHopPeerId: 'peer-b',
          nextHopNodeId: 'node-b',
          interfaceId: 'ble',
          hopCount: 1,
          geographicScope: 'locality',
          confidence: 0.88,
          supportsCustody: true,
          sourceType: MeshAnnounceSourceType.directDiscovery,
        ),
        interfaceProfile: MeshInterfaceRegistry().resolveByInterfaceId(
          'ble',
          privacyMode: MeshTransportPrivacyMode.privateMesh,
        ),
      );

      final selection = await MeshForwardingTargetSelector.selectWithContext(
        context: MeshForwardingContext(
          packetCodec: GovernedMeshPacketCodec(
            encryptionService: _PassthroughEncryptionService(),
          ),
          discovery: _FakeDiscoveryService(
            <String, DiscoveredDevice>{
              'peer-a': _device('peer-a', -89),
              'peer-b': _device('peer-b', -46),
            },
          ),
          routeLedger: routeLedger,
          custodyOutbox: MeshCustodyOutbox(
            store: InMemoryMeshRuntimeStateStore(),
          ),
          announceLedger: announceLedger,
          interfaceRegistry: MeshInterfaceRegistry(),
          privacyMode: MeshTransportPrivacyMode.privateMesh,
          reticulumTransportControlPlaneEnabled: true,
        ),
        discoveredNodeIds: const <String>['peer-a', 'peer-b'],
        destinationId: 'dest-alpha',
      );

      expect(selection.routeResolutionMode, 'announce');
      expect(selection.peerIds.first, 'peer-a');
      expect(selection.peerIds, contains('peer-b'));
    });

    test(
        'rejects cloud interfaces in private mesh and allows cloud custody in federated mode',
        () async {
      final announceLedger = MeshAnnounceLedger(
        store: InMemoryMeshRuntimeStateStore(),
        nowUtc: () => DateTime.utc(2026, 3, 12, 18),
      );
      final cloudRegistry =
          MeshInterfaceRegistry(cloudInterfaceAvailable: true);
      await announceLedger.observe(
        observation: const MeshAnnounceObservation(
          destinationId: 'dest-cloud',
          nextHopPeerId: 'federated_cloud',
          nextHopNodeId: 'federated_cloud',
          interfaceId: 'federated_cloud',
          hopCount: 1,
          geographicScope: 'global',
          confidence: 0.78,
          supportsCustody: true,
          sourceType: MeshAnnounceSourceType.cloudAvailable,
        ),
        interfaceProfile: cloudRegistry.cloudProfile(
          privacyMode: MeshTransportPrivacyMode.federatedCloud,
        ),
      );

      final privateSelection =
          await MeshForwardingTargetSelector.selectWithContext(
        context: MeshForwardingContext(
          packetCodec: GovernedMeshPacketCodec(
            encryptionService: _PassthroughEncryptionService(),
          ),
          discovery: _FakeDiscoveryService(const <String, DiscoveredDevice>{}),
          routeLedger: MeshRouteLedger(store: InMemoryMeshRuntimeStateStore()),
          custodyOutbox:
              MeshCustodyOutbox(store: InMemoryMeshRuntimeStateStore()),
          announceLedger: announceLedger,
          interfaceRegistry: cloudRegistry,
          privacyMode: MeshTransportPrivacyMode.privateMesh,
          reticulumTransportControlPlaneEnabled: true,
        ),
        discoveredNodeIds: const <String>[],
        destinationId: 'dest-cloud',
      );
      expect(privateSelection.routeResolutionMode, 'historical_fallback_none');

      final federatedSelection =
          await MeshForwardingTargetSelector.selectWithContext(
        context: MeshForwardingContext(
          packetCodec: GovernedMeshPacketCodec(
            encryptionService: _PassthroughEncryptionService(),
          ),
          discovery: _FakeDiscoveryService(const <String, DiscoveredDevice>{}),
          routeLedger: MeshRouteLedger(store: InMemoryMeshRuntimeStateStore()),
          custodyOutbox:
              MeshCustodyOutbox(store: InMemoryMeshRuntimeStateStore()),
          announceLedger: announceLedger,
          interfaceRegistry: cloudRegistry,
          privacyMode: MeshTransportPrivacyMode.federatedCloud,
          reticulumTransportControlPlaneEnabled: true,
        ),
        discoveredNodeIds: const <String>[],
        destinationId: 'dest-cloud',
      );
      expect(federatedSelection.routeResolutionMode, 'cloud_custody');
      expect(federatedSelection.cloudCustodyAnnounce, isNotNull);
    });
  });
}

DiscoveredDevice _device(String deviceId, int signalStrength) {
  return DiscoveredDevice(
    deviceId: deviceId,
    deviceName: deviceId,
    type: DeviceType.bluetooth,
    isSpotsEnabled: true,
    signalStrength: signalStrength,
    discoveredAt: DateTime.utc(2026, 3, 12, 18),
  );
}

class _FakeDiscoveryService extends DeviceDiscoveryService {
  _FakeDiscoveryService(this._devices);

  final Map<String, DiscoveredDevice> _devices;

  @override
  DiscoveredDevice? getDevice(String deviceId) => _devices[deviceId];
}

class _PassthroughEncryptionService implements MessageEncryptionService {
  @override
  EncryptionType get encryptionType => EncryptionType.aes256gcm;

  @override
  Future<String> decrypt(EncryptedMessage encrypted, String senderId) async {
    return String.fromCharCodes(encrypted.encryptedContent);
  }

  @override
  Future<EncryptedMessage> encrypt(String plaintext, String recipientId) async {
    return EncryptedMessage(
      encryptedContent: Uint8List.fromList(plaintext.codeUnits),
      encryptionType: EncryptionType.aes256gcm,
    );
  }
}
