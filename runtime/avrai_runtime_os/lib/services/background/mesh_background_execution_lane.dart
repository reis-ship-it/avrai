import 'package:avrai_network/avra_network.dart';
import 'package:avrai_runtime_os/kernel/os/ai2ai_mesh_governance_binding_service.dart';
import 'package:avrai_runtime_os/services/background/background_execution_models.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_runtime_os/services/transport/mesh/governed_mesh_packet_codec.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_announce_attestation_factory.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_announce_ledger.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_custody_outbox.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_custody_replay_lane.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_forwarding_context.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_interface_registry.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_route_ledger.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_segment_credential_factory.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_segment_credential_refresh_service.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_segment_profile_resolver.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_segment_revocation_store.dart';
import 'package:avrai_network/network/device_discovery.dart';

typedef MeshReplayDueEntries = Future<int> Function({
  required MeshForwardingContext context,
  required Iterable<String> discoveredNodeIds,
  required String localNodeId,
  required Map<String, String> peerNodeIdByDeviceId,
  required AppLogger logger,
  required String logName,
  int maxEntries,
  int maxCandidates,
});

typedef MeshReplayRecoveredReachability = Future<int> Function({
  required MeshForwardingContext context,
  required Iterable<String> discoveredNodeIds,
  required String localNodeId,
  required Map<String, String> peerNodeIdByDeviceId,
  required AppLogger logger,
  required String logName,
  int maxEntriesPerDestination,
  int maxEntriesPerCycle,
  int maxCandidates,
});

class MeshBackgroundExecutionResult {
  const MeshBackgroundExecutionResult({
    required this.dueReplayCount,
    required this.recoveredReachabilityReplayCount,
    required this.discoveredPeerCount,
  });

  final int dueReplayCount;
  final int recoveredReachabilityReplayCount;
  final int discoveredPeerCount;
}

class MeshBackgroundExecutionLane {
  MeshBackgroundExecutionLane({
    required DeviceDiscoveryService discovery,
    required GovernedMeshPacketCodec packetCodec,
    required MeshRouteLedger routeLedger,
    required MeshCustodyOutbox custodyOutbox,
    required MeshInterfaceRegistry interfaceRegistry,
    required MeshAnnounceLedger announceLedger,
    String? localUserId,
    String? localAgentId,
    Ai2AiMeshGovernanceBindingService? governanceBindingService,
    MeshSegmentProfileResolver? segmentProfileResolver,
    MeshSegmentCredentialFactory? segmentCredentialFactory,
    MeshSegmentCredentialRefreshService? segmentCredentialRefreshService,
    MeshSegmentRevocationStore? segmentRevocationStore,
    MeshAnnounceAttestationFactory? announceAttestationFactory,
    AppLogger? logger,
    MeshReplayDueEntries? replayDueEntries,
    MeshReplayRecoveredReachability? replayRecoveredReachability,
  })  : _discovery = discovery,
        _packetCodec = packetCodec,
        _routeLedger = routeLedger,
        _custodyOutbox = custodyOutbox,
        _interfaceRegistry = interfaceRegistry,
        _announceLedger = announceLedger,
        _localUserId = localUserId,
        _localAgentId = localAgentId,
        _governanceBindingService = governanceBindingService,
        _segmentProfileResolver = segmentProfileResolver,
        _segmentCredentialFactory = segmentCredentialFactory,
        _segmentCredentialRefreshService = segmentCredentialRefreshService,
        _segmentRevocationStore = segmentRevocationStore,
        _announceAttestationFactory = announceAttestationFactory,
        _logger = logger ??
            const AppLogger(
              defaultTag: 'MeshBackgroundExecution',
              minimumLevel: LogLevel.debug,
            ),
        _replayDueEntries =
            replayDueEntries ?? MeshCustodyReplayLane.replayDueEntries,
        _replayRecoveredReachability = replayRecoveredReachability ??
            MeshCustodyReplayLane.replayForRecoveredReachability;

  final DeviceDiscoveryService _discovery;
  final GovernedMeshPacketCodec _packetCodec;
  final MeshRouteLedger _routeLedger;
  final MeshCustodyOutbox _custodyOutbox;
  final MeshInterfaceRegistry _interfaceRegistry;
  final MeshAnnounceLedger _announceLedger;
  final String? _localUserId;
  final String? _localAgentId;
  final Ai2AiMeshGovernanceBindingService? _governanceBindingService;
  final MeshSegmentProfileResolver? _segmentProfileResolver;
  final MeshSegmentCredentialFactory? _segmentCredentialFactory;
  final MeshSegmentCredentialRefreshService? _segmentCredentialRefreshService;
  final MeshSegmentRevocationStore? _segmentRevocationStore;
  final MeshAnnounceAttestationFactory? _announceAttestationFactory;
  final AppLogger _logger;
  final MeshReplayDueEntries _replayDueEntries;
  final MeshReplayRecoveredReachability _replayRecoveredReachability;

  Future<MeshBackgroundExecutionResult> handleWake({
    required BackgroundWakeReason reason,
    required BackgroundCapabilitySnapshot capabilities,
  }) async {
    final context = MeshForwardingContext.tryCreate(
      discovery: _discovery,
      governanceBindingService: _governanceBindingService,
      packetCodec: _packetCodec,
      routeLedger: _routeLedger,
      custodyOutbox: _custodyOutbox,
      interfaceRegistry: _interfaceRegistry,
      announceLedger: _announceLedger,
      segmentProfileResolver: _segmentProfileResolver,
      segmentCredentialFactory: _segmentCredentialFactory,
      segmentCredentialRefreshService: _segmentCredentialRefreshService,
      segmentRevocationStore: _segmentRevocationStore,
      announceAttestationFactory: _announceAttestationFactory,
      localUserId: _localUserId,
      localAgentId: _localAgentId,
      privacyMode: capabilities.privacyMode,
      reticulumTransportControlPlaneEnabled:
          capabilities.reticulumTransportControlPlaneEnabled,
      trustedAnnounceEnforcementEnabled:
          capabilities.trustedMeshAnnounceEnforcementEnabled,
    );
    if (context == null) {
      return const MeshBackgroundExecutionResult(
        dueReplayCount: 0,
        recoveredReachabilityReplayCount: 0,
        discoveredPeerCount: 0,
      );
    }

    final discoveredDevices = _discovery.getDiscoveredDevices();
    final discoveredPeerIds = discoveredDevices
        .map((entry) => entry.deviceId)
        .toList(growable: false);
    final peerNodeIdByDeviceId = <String, String>{
      for (final device in discoveredDevices)
        if (device.metadata['node_id'] != null)
          device.deviceId: device.metadata['node_id'].toString(),
    };
    final localNodeId =
        _localAgentId ?? _localUserId ?? 'headless_background_runtime';

    var dueReplayCount = 0;
    if (_shouldReplayDue(reason)) {
      dueReplayCount = await _replayDueEntries(
        context: context,
        discoveredNodeIds: discoveredPeerIds,
        localNodeId: localNodeId,
        peerNodeIdByDeviceId: peerNodeIdByDeviceId,
        logger: _logger,
        logName: 'MeshBackgroundExecutionLane',
      );
    }

    var recoveredReachabilityReplayCount = 0;
    if (capabilities.reticulumTransportControlPlaneEnabled &&
        _shouldReplayRecoveredReachability(reason)) {
      recoveredReachabilityReplayCount = await _replayRecoveredReachability(
        context: context,
        discoveredNodeIds: discoveredPeerIds,
        localNodeId: localNodeId,
        peerNodeIdByDeviceId: peerNodeIdByDeviceId,
        logger: _logger,
        logName: 'MeshBackgroundExecutionLane',
      );
    }

    return MeshBackgroundExecutionResult(
      dueReplayCount: dueReplayCount,
      recoveredReachabilityReplayCount: recoveredReachabilityReplayCount,
      discoveredPeerCount: discoveredPeerIds.length,
    );
  }

  bool _shouldReplayDue(BackgroundWakeReason reason) {
    switch (reason) {
      case BackgroundWakeReason.bootCompleted:
      case BackgroundWakeReason.backgroundTaskWindow:
      case BackgroundWakeReason.connectivityWifi:
      case BackgroundWakeReason.bleEncounter:
      case BackgroundWakeReason.trustedAnnounceRefresh:
      case BackgroundWakeReason.segmentRefreshWindow:
        return true;
      case BackgroundWakeReason.significantLocation:
        return false;
    }
  }

  bool _shouldReplayRecoveredReachability(BackgroundWakeReason reason) {
    switch (reason) {
      case BackgroundWakeReason.bootCompleted:
      case BackgroundWakeReason.backgroundTaskWindow:
      case BackgroundWakeReason.connectivityWifi:
      case BackgroundWakeReason.bleEncounter:
      case BackgroundWakeReason.trustedAnnounceRefresh:
        return true;
      case BackgroundWakeReason.significantLocation:
      case BackgroundWakeReason.segmentRefreshWindow:
        return false;
    }
  }
}
