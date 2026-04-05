import 'package:avrai_runtime_os/services/transport/mesh/mesh_announce_ledger.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_interface_registry.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_runtime_state_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MeshAnnounceLedger', () {
    test('stores, expires, refreshes, and prunes announce records', () async {
      var nowUtc = DateTime.utc(2026, 3, 12, 12);
      final ledger = MeshAnnounceLedger(
        store: InMemoryMeshRuntimeStateStore(),
        nowUtc: () => nowUtc,
      );
      final bleProfile = MeshInterfaceRegistry().resolveByInterfaceId(
        'ble',
        privacyMode: MeshTransportPrivacyMode.privateMesh,
      );

      final created = await ledger.observe(
        observation: const MeshAnnounceObservation(
          destinationId: 'dest-alpha',
          nextHopPeerId: 'peer-a',
          nextHopNodeId: 'node-a',
          interfaceId: 'ble',
          hopCount: 1,
          geographicScope: 'locality',
          confidence: 0.82,
          supportsCustody: true,
          sourceType: MeshAnnounceSourceType.directDiscovery,
        ),
        interfaceProfile: bleProfile,
      );
      expect(created.triggerReason, 'announce_arrival');
      expect(ledger.activeRecords(destinationId: 'dest-alpha'), hasLength(1));

      nowUtc = DateTime.utc(2026, 3, 12, 12, 6);
      expect(ledger.activeRecords(destinationId: 'dest-alpha'), isEmpty);
      expect(ledger.expiredRecords(), hasLength(1));

      final refreshed = await ledger.observe(
        observation: const MeshAnnounceObservation(
          destinationId: 'dest-alpha',
          nextHopPeerId: 'peer-a',
          nextHopNodeId: 'node-a',
          interfaceId: 'ble',
          hopCount: 1,
          geographicScope: 'locality',
          confidence: 0.91,
          supportsCustody: true,
          sourceType: MeshAnnounceSourceType.directDiscovery,
        ),
        interfaceProfile: bleProfile,
      );
      expect(refreshed.triggerReason, 'interface_recovered');
      expect(ledger.activeRecords(destinationId: 'dest-alpha'), hasLength(1));

      nowUtc = DateTime.utc(2026, 3, 13, 13);
      await ledger.pruneExpiredHistory();
      expect(ledger.allRecords(), isEmpty);
    });
  });
}
