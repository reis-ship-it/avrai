// ignore_for_file: deprecated_member_use

import 'dart:typed_data';

import 'package:avrai_network/avra_network.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_announce_ledger.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_custody_outbox.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_custody_replay_lane.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_forwarding_context.dart';
import 'package:avrai_runtime_os/services/transport/mesh/governed_mesh_packet_codec.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_interface_registry.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_route_ledger.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_runtime_state_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MeshCustodyReplayLane', () {
    test(
        'keeps deferred entries queued and increments retry state when no route exists',
        () async {
      var nowUtc = DateTime.utc(2026, 3, 12, 22);
      final outbox = MeshCustodyOutbox(
        store: InMemoryMeshRuntimeStateStore(),
        nowUtc: () => nowUtc,
        defaultRetryBackoff: const Duration(minutes: 3),
      );
      final context = MeshForwardingContext(
        packetCodec: GovernedMeshPacketCodec(
          encryptionService: _PassthroughEncryptionService(),
        ),
        discovery: _FakeDiscoveryService(const <String, DiscoveredDevice>{}),
        routeLedger: MeshRouteLedger(store: InMemoryMeshRuntimeStateStore()),
        custodyOutbox: outbox,
      );

      final entry = await outbox.enqueue(
        receiptId: 'receipt-replay-1',
        destinationId: '9q4xy',
        payloadKind: 'organic_spot_discovery',
        channel: 'mesh_ble_forward',
        payload: const <String, dynamic>{
          'geohash': '9q4xy',
          'geographic_scope': 'locality',
          'origin_id': 'node-local',
        },
        payloadContext: const <String, dynamic>{'geohash': '9q4xy'},
        geographicScope: 'locality',
        retryBackoff: Duration.zero,
      );

      final released = await MeshCustodyReplayLane.replayDueEntries(
        context: context,
        discoveredNodeIds: const <String>[],
        localNodeId: 'node-local',
        peerNodeIdByDeviceId: const <String, String>{},
        logger: const AppLogger(defaultTag: 'test'),
        logName: 'MeshCustodyReplayLaneTest',
      );

      expect(released, 0);
      expect(outbox.pendingCount(destinationId: '9q4xy'), 1);

      nowUtc = DateTime.utc(2026, 3, 12, 22, 4);
      final retriedEntries = outbox.dueEntries(destinationId: '9q4xy');
      expect(retriedEntries, hasLength(1));
      expect(retriedEntries.single.entryId, entry.entryId);
      expect(retriedEntries.single.attemptCount, 1);
      expect(retriedEntries.single.lastFailureReason,
          'no_mesh_candidates_available');
    });

    test('replays queued custody on announce arrival without waiting for due time',
        () async {
      final nowUtc = DateTime.utc(2026, 3, 12, 22);
      final routeLedger = MeshRouteLedger(
        store: InMemoryMeshRuntimeStateStore(),
        nowUtc: () => nowUtc,
      );
      await routeLedger.recordForwardOutcome(
        destinationId: 'dest-alpha',
        channel: 'mesh_ble_forward',
        payloadKind: 'organic_spot_discovery',
        attemptedRoutes: const <TransportRouteCandidate>[
          TransportRouteCandidate(
            routeId: 'ble:peer-a:node-peer-a',
            mode: TransportMode.ble,
            confidence: 0.82,
            estimatedLatencyMs: 110,
            metadata: <String, dynamic>{
              'peer_id': 'peer-a',
              'peer_node_id': 'node-peer-a',
            },
          ),
        ],
        winningRoute: const TransportRouteCandidate(
          routeId: 'ble:peer-a:node-peer-a',
          mode: TransportMode.ble,
          confidence: 0.82,
          estimatedLatencyMs: 110,
          metadata: <String, dynamic>{
            'peer_id': 'peer-a',
            'peer_node_id': 'node-peer-a',
          },
        ),
        occurredAtUtc: DateTime.utc(2026, 3, 12, 21, 50),
      );
      final outbox = MeshCustodyOutbox(
        store: InMemoryMeshRuntimeStateStore(),
        nowUtc: () => nowUtc,
        defaultRetryBackoff: const Duration(minutes: 3),
      );
      final context = MeshForwardingContext(
        packetCodec: GovernedMeshPacketCodec(
          encryptionService: _PassthroughEncryptionService(),
        ),
        discovery: _FakeDiscoveryService(
          <String, DiscoveredDevice>{
            'peer-a': DiscoveredDevice(
              deviceId: 'peer-a',
              deviceName: 'Peer A',
              type: DeviceType.bluetooth,
              isSpotsEnabled: true,
              signalStrength: -55,
              discoveredAt: nowUtc,
            ),
          },
        ),
        routeLedger: routeLedger,
        custodyOutbox: outbox,
        announceLedger: MeshAnnounceLedger(
          store: InMemoryMeshRuntimeStateStore(),
          nowUtc: () => nowUtc,
        ),
        interfaceRegistry: MeshInterfaceRegistry(),
        privacyMode: MeshTransportPrivacyMode.privateMesh,
        reticulumTransportControlPlaneEnabled: true,
      );

      await outbox.enqueue(
        receiptId: 'receipt-replay-2',
        destinationId: 'dest-alpha',
        payloadKind: 'organic_spot_discovery',
        channel: 'mesh_ble_forward',
        payload: const <String, dynamic>{
          'geohash': '9q4xy',
          'geographic_scope': 'locality',
          'origin_id': 'node-local',
        },
        payloadContext: const <String, dynamic>{'geohash': '9q4xy'},
        geographicScope: 'locality',
        retryBackoff: const Duration(hours: 1),
      );

      final released = await MeshCustodyReplayLane.replayForRecoveredReachability(
        context: context,
        discoveredNodeIds: const <String>['peer-a'],
        localNodeId: 'node-local',
        peerNodeIdByDeviceId: const <String, String>{'peer-a': 'node-peer-a'},
        logger: const AppLogger(defaultTag: 'test'),
        logName: 'MeshCustodyReplayLaneTest',
      );

      expect(released, 0);
      final retriedEntries = outbox.allEntries();
      expect(retriedEntries, hasLength(1));
      expect(retriedEntries.single.attemptCount, 1);
      expect(
        retriedEntries.single.lastFailureReason,
        anyOf('all_mesh_candidates_failed', 'no_mesh_candidates_available'),
      );
      expect(
        context.announceLedger?.replayTelemetry().announceTriggeredReplayCount,
        1,
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
