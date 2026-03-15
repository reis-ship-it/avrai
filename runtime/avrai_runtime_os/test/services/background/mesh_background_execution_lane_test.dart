import 'package:avrai_network/avra_network.dart';
import 'package:avrai_runtime_os/services/background/background_execution_models.dart';
import 'package:avrai_runtime_os/services/background/mesh_background_execution_lane.dart';
import 'package:avrai_runtime_os/services/transport/mesh/governed_mesh_packet_codec.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_announce_ledger.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_custody_outbox.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_forwarding_context.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_interface_registry.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_route_ledger.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_runtime_state_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MeshBackgroundExecutionLane', () {
    test('replays due and recovered routes from trusted wake events', () async {
      Iterable<String>? capturedDiscoveredNodeIds;
      Map<String, String>? capturedPeerNodeIdByDeviceId;
      final lane = MeshBackgroundExecutionLane(
        discovery: _FakeDiscoveryService(
          <DiscoveredDevice>[
            DiscoveredDevice(
              deviceId: 'peer-a',
              deviceName: 'Peer A',
              type: DeviceType.bluetooth,
              isSpotsEnabled: true,
              discoveredAt: DateTime.utc(2026, 3, 13, 12),
              metadata: <String, dynamic>{'node_id': 'node-a'},
            ),
          ],
        ),
        packetCodec: GovernedMeshPacketCodec(
          encryptionService: AES256GCMEncryptionService(),
        ),
        routeLedger: MeshRouteLedger(
          store: InMemoryMeshRuntimeStateStore(),
        ),
        custodyOutbox: MeshCustodyOutbox(
          store: InMemoryMeshRuntimeStateStore(),
        ),
        interfaceRegistry: MeshInterfaceRegistry(),
        announceLedger: MeshAnnounceLedger(
          store: InMemoryMeshRuntimeStateStore(),
        ),
        replayDueEntries: ({
          required MeshForwardingContext context,
          required Iterable<String> discoveredNodeIds,
          required String localNodeId,
          required Map<String, String> peerNodeIdByDeviceId,
          required logger,
          required String logName,
          int maxEntries = 4,
          int maxCandidates = 2,
        }) async {
          return 2;
        },
        replayRecoveredReachability: ({
          required MeshForwardingContext context,
          required Iterable<String> discoveredNodeIds,
          required String localNodeId,
          required Map<String, String> peerNodeIdByDeviceId,
          required logger,
          required String logName,
          int maxEntriesPerDestination = 3,
          int maxEntriesPerCycle = 8,
          int maxCandidates = 2,
        }) async {
          capturedDiscoveredNodeIds = discoveredNodeIds;
          capturedPeerNodeIdByDeviceId = peerNodeIdByDeviceId;
          return 3;
        },
      );

      final result = await lane.handleWake(
        reason: BackgroundWakeReason.trustedAnnounceRefresh,
        capabilities: BackgroundCapabilitySnapshot(
          observedAtUtc: DateTime.utc(2026, 3, 13, 12),
          wakeReason: BackgroundWakeReason.trustedAnnounceRefresh,
          privacyMode: MeshTransportPrivacyMode.privateMesh,
          isWifiAvailable: false,
          isIdle: true,
          reticulumTransportControlPlaneEnabled: true,
          trustedMeshAnnounceEnforcementEnabled: true,
        ),
      );

      expect(result.dueReplayCount, 2);
      expect(result.recoveredReachabilityReplayCount, 3);
      expect(result.discoveredPeerCount, 1);
      expect(capturedDiscoveredNodeIds, contains('peer-a'));
      expect(
        capturedPeerNodeIdByDeviceId,
        <String, String>{'peer-a': 'node-a'},
      );
    });

    test('skips replay for non-routing wake reasons', () async {
      final lane = MeshBackgroundExecutionLane(
        discovery: _FakeDiscoveryService(const <DiscoveredDevice>[]),
        packetCodec: GovernedMeshPacketCodec(
          encryptionService: AES256GCMEncryptionService(),
        ),
        routeLedger: MeshRouteLedger(
          store: InMemoryMeshRuntimeStateStore(),
        ),
        custodyOutbox: MeshCustodyOutbox(
          store: InMemoryMeshRuntimeStateStore(),
        ),
        interfaceRegistry: MeshInterfaceRegistry(),
        announceLedger: MeshAnnounceLedger(
          store: InMemoryMeshRuntimeStateStore(),
        ),
      );

      final result = await lane.handleWake(
        reason: BackgroundWakeReason.significantLocation,
        capabilities: BackgroundCapabilitySnapshot(
          observedAtUtc: DateTime.utc(2026, 3, 13, 12),
          wakeReason: BackgroundWakeReason.significantLocation,
          privacyMode: MeshTransportPrivacyMode.privateMesh,
          isWifiAvailable: false,
          isIdle: true,
          reticulumTransportControlPlaneEnabled: true,
          trustedMeshAnnounceEnforcementEnabled: true,
        ),
      );

      expect(result.dueReplayCount, 0);
      expect(result.recoveredReachabilityReplayCount, 0);
    });
  });
}

class _FakeDiscoveryService extends DeviceDiscoveryService {
  _FakeDiscoveryService(this._devices)
      : super(platform: _NoopDiscoveryPlatform());

  final List<DiscoveredDevice> _devices;

  @override
  List<DiscoveredDevice> getDiscoveredDevices() =>
      List<DiscoveredDevice>.from(_devices);

  @override
  DiscoveredDevice? getDevice(String deviceId) {
    for (final device in _devices) {
      if (device.deviceId == deviceId) {
        return device;
      }
    }
    return null;
  }
}

class _NoopDiscoveryPlatform implements DeviceDiscoveryPlatform {
  @override
  bool isSupported() => true;

  @override
  Future<Map<String, dynamic>> getDeviceInfo() async =>
      const <String, dynamic>{};

  @override
  Future<bool> requestPermissions() async => true;

  @override
  Future<List<DiscoveredDevice>> scanForDevices({
    Duration scanWindow = const Duration(seconds: 4),
  }) async =>
      const <DiscoveredDevice>[];
}
