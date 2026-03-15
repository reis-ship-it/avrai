import 'package:avrai_network/avra_network.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_route_ledger.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_runtime_state_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MeshRouteLedger', () {
    test('ranks candidates using destination path memory', () async {
      final ledger = MeshRouteLedger(
        store: InMemoryMeshRuntimeStateStore(),
        nowUtc: () => DateTime.utc(2026, 3, 12, 18),
      );

      const attemptedRoutes = <TransportRouteCandidate>[
        TransportRouteCandidate(
          routeId: 'ble:peer-a:node-peer-a',
          mode: TransportMode.ble,
          confidence: 0.62,
          estimatedLatencyMs: 110,
          metadata: <String, dynamic>{
            'peer_id': 'peer-a',
            'peer_node_id': 'node-peer-a',
            'signal_strength_dbm': -51,
          },
        ),
        TransportRouteCandidate(
          routeId: 'ble:peer-b:node-peer-b',
          mode: TransportMode.ble,
          confidence: 0.54,
          estimatedLatencyMs: 170,
          metadata: <String, dynamic>{
            'peer_id': 'peer-b',
            'peer_node_id': 'node-peer-b',
            'signal_strength_dbm': -67,
          },
        ),
      ];

      await ledger.recordForwardOutcome(
        destinationId: 'dest-alpha',
        channel: 'mesh_ble_forward',
        payloadKind: 'learning_insight_gossip',
        attemptedRoutes: attemptedRoutes,
        winningRoute: attemptedRoutes[1],
        occurredAtUtc: DateTime.utc(2026, 3, 12, 17, 58),
        geographicScope: 'locality',
      );

      final ranked = ledger.rankCandidates(
        destinationId: 'dest-alpha',
        candidatePeerIds: const <String>['peer-a', 'peer-b'],
        discovery: _FakeDiscoveryService(
          <String, DiscoveredDevice>{
            'peer-a': _device(
              deviceId: 'peer-a',
              name: 'Peer A',
              signalStrength: -49,
            ),
            'peer-b': _device(
              deviceId: 'peer-b',
              name: 'Peer B',
              signalStrength: -66,
            ),
          },
        ),
        geographicScope: 'locality',
        maxCandidates: 2,
      );

      expect(ranked, orderedEquals(const <String>['peer-b', 'peer-a']));
      expect(
        ledger
            .entryForPeer(destinationId: 'dest-alpha', peerId: 'peer-b')
            ?.successCount,
        1,
      );
      expect(
        ledger
            .entryForPeer(destinationId: 'dest-alpha', peerId: 'peer-a')
            ?.failureCount,
        1,
      );
    });
  });
}

DiscoveredDevice _device({
  required String deviceId,
  required String name,
  required int signalStrength,
}) {
  return DiscoveredDevice(
    deviceId: deviceId,
    deviceName: name,
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
