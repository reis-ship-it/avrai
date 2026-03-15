// TODO(Phase 0.5.0): Remove this suppression after AI2AIProtocol callers migrate to DNAEncoderService.
// ignore_for_file: deprecated_member_use

// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'dart:async';

import 'package:avrai_network/avra_network.dart';
import 'package:avrai_runtime_os/services/transport/mesh/governed_mesh_packet_codec.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_bearer_adapter.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_transport_execution_lane.dart';

class MeshPacketForwarder {
  const MeshPacketForwarder._();

  static Future<void> forwardToCandidates({
    required List<String> candidatePeerIds,
    required DeviceDiscoveryService discovery,
    required GovernedMeshPacketCodec packetCodec,
    required String senderNodeId,
    required Map<String, String> peerNodeIdByDeviceId,
    required MeshPacketType messageType,
    required Map<String, dynamic> payload,
    String? geographicScope,
    bool fireAndForgetSend = false,
    void Function(String peerId, String recipientId)? onForwarded,
    void Function(String peerId, String recipientId, Object error)?
        onForwardFailed,
  }) async {
    final executionLane = MeshTransportExecutionLane(
      adapters: <MeshBearerAdapter>[
        BleMeshBearerAdapter(
          discovery: discovery,
          packetCodec: packetCodec,
        ),
      ],
    );
    final result = await executionLane.dispatch(
      MeshBearerDispatchRequest(
        candidatePeerIds: candidatePeerIds,
        senderNodeId: senderNodeId,
        peerNodeIdByDeviceId: peerNodeIdByDeviceId,
        messageType: messageType,
        payload: payload,
        geographicScope: geographicScope,
        fireAndForgetSend: fireAndForgetSend,
      ),
    );
    for (final forwarded in result.forwardedRecipients.entries) {
      onForwarded?.call(forwarded.key, forwarded.value);
    }
    for (final failure in result.failedPeers.entries) {
      final device = discovery.getDevice(failure.key);
      final recipientId = device == null
          ? failure.key
          : peerNodeIdByDeviceId[device.deviceId] ?? device.deviceId;
      onForwardFailed?.call(failure.key, recipientId, failure.value);
    }
  }
}
